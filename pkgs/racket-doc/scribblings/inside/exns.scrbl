#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "exceptions"]{异常与逃逸 Continuation}

当 Racket 遇到错误时，它会引发异常。默认的异常 handler 会调用错误显示 handler，
然后调用错误逃逸 handler。默认的错误逃逸 handler 通过
@defterm{primitive error escape} 进行逃逸，该机制通过调用
@cpp{scheme_longjmp(*scheme_current_thread->error_buf)} 实现。

嵌入程序应在任何顶层进入 Racket 求值之前，
将新缓冲区安装到 @cpp{scheme_current_thread->error_buf} 中并调用
@cpp{scheme_setjmp(*scheme_current_thread->error_buf)}，以捕获 primitive error escape。
当新缓冲区离开作用域时，恢复 @cpp{scheme_current_thread->error_buf} 中
的原始值。宏 @cppi{scheme_error_buf} 是
@cpp{*scheme_current_thread->error_buf} 的简写。

@verbatim[#:indent 2]{
  mz_jmp_buf * volatile save, fresh;
  ...
  save = scheme_current_thread->error_buf;
  scheme_current_thread->error_buf = &fresh;
  if (scheme_setjmp(scheme_error_buf)) {
    /* 发生了错误 */
    ...
  } else {
    v = scheme_eval_string(s, env);
  }
  scheme_current_thread->error_buf = save;
  ...
}

3m：当使用 @cpp{scheme_setjmp} 时，外围上下文必须
通过 @cpp{MZ_GC_DECL_REG} 提供局部变量注册记录。
如果上下文没有需要注册的局部变量，使用 @cpp{MZ_GC_DECL_REG(0)}。
不幸的是，当使用 @DFlag{xform} 和 @|mzc| 而不是
@cpp{MZ_GC_DECL_REG} 等时，你可能需要声明一个虚拟指针
并在 @cpp{scheme_setjmp} 之后使用它，以确保生成局部变量
注册。

新的 primitive procedure 可以通过调用
@cppi{scheme_signal_error} 来引发通用异常。
@cpp{scheme_signal_error} 的参数与标准 C 函数
@cpp{printf} 大致相同。可以通过调用
@cppi{scheme_raise_exn} 来引发特定的 primitive exception。

完整的 @as-index{continuations} 在 Racket 中通过复制
C 栈并使用 @cppi{scheme_setjmp} 和 @cppi{scheme_longjmp} 来实现。
只要 C/C++ 应用程序通过顶层求值函数（@cpp{scheme_eval}、@cpp{scheme_apply}
等，而非 @cpp{_scheme_apply}、@cpp{_scheme_eval_compiled}
等）调用 Racket 求值，代码就能免受 Racket
求值的任何异常行为（例如从函数返回两次），因为
continuation 调用被限制在单个
顶层求值内的跳转中。然而，escape continuation 跳转仍然
允许；如下一小节所述，对逃逸敏感的扩展必须
特别小心。

@; ----------------------------------------------------------------------

@section[#:tag "imz:tempcatch"]{临时捕获错误逃逸}

在实现新的 primitive procedure 时，有时需要
捕获并处理在求值子表达式时发生的错误。一种
方法是：将
@cppi{scheme_current_thread->error_buf} 保存到临时变量中，将
@cppi{scheme_current_thread->error_buf} 设置为栈分配的
@cpp{mz_jmp_buf} 的地址，调用
@cpp{scheme_setjmp(scheme_error_buf)}，执行函数的工作，
然后在返回值之前恢复 @cpp{scheme_current_thread->error_buf}。
（3m：栈分配的 @cpp{mz_jmp_buf} 实例无需注册到垃圾回收器，
堆分配的 @cpp{mz_jmp_buf} 应作为 atomic 分配。）

然而，请注意 prompt abort 或逃逸 continuation 的调用看起来像
primitive error escape。在这种情况下，
特殊指示标志 @cppi{scheme_jumping_to_continuation}
为非零值（而非正常的零值）；这种情况仅在
实现新的 primitive procedure 时才可见。当
@cppi{scheme_jumping_to_continuation} 为非零时，通过
链接到先前保存的错误缓冲区来响应逃逸请求；否则，
调用 @cppi{scheme_clear_escape}。

@verbatim[#:indent 2]{
  mz_jmp_buf * volatile save, fresh;
  save = scheme_current_thread->error_buf;
  scheme_current_thread->error_buf = &fresh;
  if (scheme_setjmp(scheme_error_buf)) {
    /* 发生了错误或 continuation 调用 */
    if (scheme_jumping_to_continuation) {
      /* 这是一次 continuation 跳转 */
      scheme_longjmp(*save, 1);
      /* 要阻止跳转，改为：scheme_clear_escape(); */
    } else {
      /* 这是一次 primitive error escape */
    }
  } else {
    scheme_eval_string("x", scheme_env);
  }
  scheme_current_thread->error_buf = save;
}

只要 procedure 的实现仅
调用顶层求值函数（@cpp{scheme_eval}、
@cpp{scheme_apply} 等，而非 @cpp{_scheme_apply}、
@cpp{_scheme_eval_compiled} 等），此解决方案就能正常工作。否则，
使用 @cppi{scheme_dynamic_wind} 保护你的代码免受完整的
continuation 跳转的影响，就像在 Racket 中使用 @racket[dynamic-wind]
一样。

上述解决方案只是捕获了逃逸，并未报告
逃逸发生的原因。要捕获异常并获取
异常信息，最简单的方法是将 Racket
代码与 C 实现的 thunk 混合使用。下面的代码可用于在各种情况下
捕获异常。它实现了函数
@cpp{_apply_catch_exceptions}，该函数在应用 thunk 期间捕获异常。
（此代码位于发行版中的
@filepath{collects/mzscheme/examples/catch.c}。）

@verbatim[#:indent 2]{
  static Scheme_Object *exn_catching_apply, *exn_p, *exn_message;

  static void init_exn_catching_apply()
  {
    if (!exn_catching_apply) {
      char *e = 
        "(lambda (thunk) "
          "(with-handlers ([void (lambda (exn) (cons #f exn))]) "
            "(cons #t (thunk))))";
      /* 确保我们有一个带有标准绑定的命名空间： */
      Scheme_Env *env = (Scheme_Env *)scheme_make_namespace(0, NULL);

      scheme_register_extension_global(&exn_catching_apply, 
                                       sizeof(Scheme_Object *));
      scheme_register_extension_global(&exn_p, 
                                       sizeof(Scheme_Object *));
      scheme_register_extension_global(&exn_message, 
                                       sizeof(Scheme_Object *));

      exn_catching_apply = scheme_eval_string(e, env);
      exn_p = scheme_lookup_global(scheme_intern_symbol("exn?"), env);
      exn_message 
        = scheme_lookup_global(scheme_intern_symbol("exn-message"), 
                               env);
    }
  }

  /* This function applies a thunk, returning the Racket value if 
     there's no exception, otherwise returning NULL and setting *exn 
     to the raised value (usually an exn structure). */
  Scheme_Object *_apply_thunk_catch_exceptions(Scheme_Object *f, 
                                               Scheme_Object **exn)
  {
    Scheme_Object *v;

    init_exn_catching_apply();

    v = _scheme_apply(exn_catching_apply, 1, &f);
    /* v is a pair: (cons #t value) or (cons #f exn) */

    if (SCHEME_TRUEP(SCHEME_CAR(v)))
      return SCHEME_CDR(v);
    else {
      *exn = SCHEME_CDR(v);
      return NULL;
    }
  }

  Scheme_Object *extract_exn_message(Scheme_Object *v)
  {
    init_exn_catching_apply();

    if (SCHEME_TRUEP(_scheme_apply(exn_p, 1, &v)))
      return _scheme_apply(exn_message, 1, &v);
    else
      return NULL; /* Not an exn structure */
  }
}

在下面的示例中，上述代码用于捕获在从字符串求值源代码时
发生的异常。

@verbatim[#:indent 2]{
  static Scheme_Object *do_eval(void *s, int noargc, 
                                Scheme_Object **noargv)
  {
    return scheme_eval_string((char *)s, 
                              scheme_get_env(scheme_config));
  }

  static Scheme_Object *eval_string_or_get_exn_message(char *s)
  {
    Scheme_Object *v, *exn;

    v = scheme_make_closed_prim(do_eval, s);
    v = _apply_thunk_catch_exceptions(v, &exn);
    /* Got a value? */
    if (v)
      return v;

    v = extract_exn_message(exn);
    /* Got an exn? */
    if (v)
      return v;

    /* `raise' was called on some arbitrary value */
    return exn;
  }
}

@; ----------------------------------------------------------------------

@section{启用和禁用中断}

在嵌入 Racket 时，异步 break 异常默认是禁用的。
调用 @cpp{scheme_set_can_break}（与调用
Racket 函数 @racket[break-enabled] 相同）来启用或禁用
break。要在另一个求值的动态范围内
启用或禁用 break（在 Racket 中你会使用
@racket[call-with-break-parameterization]），改为
在此之前使用 @cppi{scheme_push_break_enable}，
之后使用 @cppi{scheme_pop_break_enable}。

@section{异常函数}

@function[(void scheme_signal_error
           [char* msg]
           [... ...])]{

引发一个通用的 primitive exception。参数大致与
@cpp{printf} 相同，但使用以下格式指令：

@itemize[

 @item{@FormatD{c}：一个 Unicode 字符（类型为 @cpp{mzchar}）}

 @item{@FormatD{d}：一个 @cpp{int}}

 @item{@FormatD{o}：一个 @cpp{int}，以八进制格式化}

 @item{@FormatD{gd}：一个 @cpp{long} 整数}

 @item{@FormatD{gx}：一个 @cpp{long} 整数，以十六进制格式化}

 @item{@FormatD{ld}：一个 @cpp{intptr_t} 整数}

 @item{@FormatD{lx}：一个 @cpp{intptr_t} 整数，以十六进制格式化}

 @item{@FormatD{f}：一个浮点 @cpp{double}}

 @item{@FormatD{s}：一个以 nul 结尾的 @cpp{char} 字符串}

 @item{@FormatD{5}：一个以 nul 结尾的 @cpp{mzchar} 字符串}

 @item{@FormatD{S}：一个 Racket symbol（@cpp{Scheme_Object*}）}

 @item{@FormatD{t} : 带 @cpp{intptr_t} 大小的 @cpp{char} 字符串（两个参数），
可能包含非结尾的 nul 字节，也可能没有 nul 结尾符}

 @item{@FormatD{u} : 带 @cpp{intptr_t} 大小的 @cpp{mzchar} 字符串（两个参数），
可能包含非结尾的 nul 字符，也可能没有 nul 结尾符}

 @item{@FormatD{T}：一个 Racket 字符串（@cpp{Scheme_Object*}）}

 @item{@FormatD{q} : 一个字符串，截断至 253 个字符，截断时打印省略号}

 @item{@FormatD{Q} : 一个 Racket 字符串（即 @cpp{Scheme_Object*}），
截断至 253 个字符，截断时打印省略号}

 @item{@FormatD{V} : 一个 Racket 值（即 @cpp{Scheme_Object*}），
根据当前错误打印宽度截断。}

 @item{@FormatD{D} : 一个 Racket 值（即 @cpp{Scheme_Object*}），
传递给 @racket[display]。}

 @item{@FormatD["@"] : 一个 Racket 值（即 @cpp{Scheme_Object*}），
其打印的元素将被拼接到结果中。}

 @item{@FormatD{e}：一个 @cpp{errno} 值，将作为文本消息
打印。}

 @item{@FormatD{E} : 一个平台相关的错误值，将作为文本消息打印。}

 @item{@FormatD{Z} : 一个潜在的平台相关错误值和一个 @cpp{char} 字符串；
若字符串非 @cpp{NULL}，则忽略该错误值，否则按 @FormatD{E} 的方式使用该错误值。}

 @item{@FormatD{%}：百分号}

 @item{@FormatD{_}：要忽略的指针}

 @item{@FormatD{-}：要忽略的 @cpp{int}}

]

格式字符串之后的参数不得超过 25 个
字符串和 Racket 值、25 个整数和 25 个浮点数。
（此限制简化了在 precise garbage collection 下的实现。）}

@function[(void scheme_raise_exn
           [int exnid]
           [... ...])]{

引发一个特定的 primitive exception。@var{exnid} 参数
指定要引发的异常。如果该异常实例
有 @math{n} 个字段，则接下来的 @math{n-2} 个参数是这些字段的
值（跳过 @racket[message] 和 @racket[debug-info]
字段）。其余参数以错误字符串开头，
大致与 @cpp{printf} 类似；更多细节参见上文的 @cpp{scheme_signal_error}。

异常 id 使用与 Racket 中相同的名称进行 @cpp{#define}，
但前缀为 ``MZ''，所有字母大写，所有 ``:'、
``-' 和 ``/' 替换为下划线。例如，
@cpp{MZEXN_FAIL_FILESYSTEM} 是 filesystem
exception 的异常 id。}


@function[(void scheme_wrong_count
           [char* name]
           [int minc]
           [int maxc]
           [int argc]
           [Scheme_Object** argv])]{

当 primitive procedure 接收到错误数量的参数时，
此函数会自动调用。它发出接收到错误数量参数
的信号并逃逸（类似于
@cpp{scheme_signal_error}）。@var{name} 参数是
接收到错误数量参数的过程的名称；@var{minc}
是预期参数的最小数量；@var{maxc} 是预期参数的
最大数量，如果没有上限则为 -1；@var{argc}
和 @var{argv} 包含所有接收到的参数。}


@function[(void scheme_wrong_contract
           [char* name]
           [char* contract]
           [int which]
           [int argc]
           [Scheme_Object** argv])]{

发出接收到不满足 contract 的参数的信号
并逃逸（类似于 @cpp{scheme_signal_error}）。
@var{name} 参数是接收到错误参数的过程的名称；
@var{expected} 是 contract；@var{which} 是
@var{argv} 数组中出错的参数；@var{argc} 和 @var{argv}
包含所有接收到的参数。如果原始的 @var{argc} 和
@var{argv} 不可用，则为 @var{which} 提供 -1，并在 @var{argv} 中提供
指向错误值的指针，此时 @var{argc} 的大小（但不包括
符号）被忽略。如果异常对
应的是 result contract 而非 argument contract，则将 @var{argc} 取反。}


@function[(void scheme_wrong_type
           [char* name]
           [char* expected]
           [int which]
           [int argc]
           [Scheme_Object** argv])]{

发出接收到错误类型参数的信号并
逃逸。请改用 @cpp{scheme_wrong_contract}。

参数与 @cpp{scheme_wrong_contract} 相同，
区别在于 @var{expected} 是预期类型的名称。}


@function[(void scheme_wrong_return_arity
           [char* name]
           [int expected]
           [int got]
           [Scheme_Object** argv]
           [const-char* detail])]{

发出返回错误数量的值到多值上下文的信号。
@var{expected} 参数表示预期有多少个值，
@var{got} 表示实际接收到的数量，
@var{argv} 是接收到的值。@var{detail} 字符串可以是
@cpp{NULL}，也可以包含 @cpp{printf} 风格的字符串（带
附加参数）来描述错误的上下文；关于
@cpp{printf} 风格字符串的更多细节，参见上文的
@cpp{scheme_signal_error}。}


@function[(void scheme_unbound_global
           [char* name])]{

发出未绑定变量错误信号，其中 @var{name} 是
变量的名称。}


@function[(void scheme_contract_error
           [const-char* name]
           [const-char* msg]
           [... ...])]{

引发一个 contract-violation 异常。@var{msg} 字符串是静态的，
而非格式字符串。在 @var{msg} 之后，可以提供任意数量的三元组
来向错误消息添加字段（每个字段占一行）；
每个三元组包含一个字段名称字符串、一个 @cpp{0} 或 @cpp{1}
表示字段值是字面字符串还是 Racket
值，以及一个字面字符串或 Racket 值。
字段三元组序列必须以 @cpp{NULL} 终止。}


@function[(char* scheme_make_provided_string
           [Scheme_Object* o]
           [int count]
           [int* len])]{

将 Racket 值转换为字符串，用于报告
错误消息。@var{count} 参数指定错误消息中总共会出现多少个 Racket
值（这样可以适当地缩放此值的字符串表示）。
如果 @var{len} 不为 @cpp{NULL}，则
用返回字符串的长度填充它。}


@function[(char* scheme_make_arg_lines_string
           [char* s]
           [int which]
           [int argc]
           [Scheme_Object** argv]
           [intptr_t* len])]{

将 Racket 值数组转换为字节字符串，如果 @var{which} 不为 -1，
则跳过 @var{which} 指示的数组元素。此函数用于
在某个参数出错时格式化函数的``其他''参数
（从而向用户提供更多关于错误发生时
程序状态的信息）。如果 @var{len} 不为
@cpp{NULL}，则用返回字符串的长度填充它。

如果参数以多行显示，则结果字符串
以换行符开头，每行缩进三个空格。
否则，结果字符串以空格开头。如果
结果不包含任何参数，则包含 @litchar{[none]}。}


@function[(char* scheme_make_args_string
           [char* s]
           [int which]
           [int argc]
           [Scheme_Object** argv]
           [intptr_t* len])]{

类似于 @cpp{scheme_make_arg_lines_string}，但用于旧式消息，
其中参数始终在单行内显示。结果
不包含前导空格。}


@function[(void scheme_check_proc_arity
           [char* where]
           [int a]
           [int which]
           [int argc]
           [Scheme_Object** argv])]{

检查 @var{argv} 中的第 @var{which} 个参数，确保它是一个
可以接受 @var{a} 个参数的过程。如果有错误，
@var{where}、@var{which}、@var{argc} 和 @var{argv} 参数会
传递给 @cpp{scheme_wrong_type}。与 @cpp{scheme_wrong_type} 一样，
@var{which} 可以为 -1，此时检查 @cpp{*}@var{argv}。}


@function[(Scheme_Object* scheme_dynamic_wind
           [Pre_Post_Proc pre]
           [Action_Proc action]
           [Pre_Post_Proc post]
           [Action_Proc jmp_handler]
           [void* data])]{

调用函数 @var{action} 进行求值，为
@cpp{scheme_dynamic_wind} 调用获取一个值。
@cpp{Pre_Post_Proc} 和 @cpp{Action_Proc} 类型并未真正定义；而是
这些类型以内联方式使用，就好像它们按如下方式定义：

@verbatim[#:indent 2]{
typedef void (*Pre_Post_Proc)(void *data);
typedef Scheme_Object* (*Action_Proc)(void *data);
}

函数 @var{pre} 和 @var{post} 分别在跳入
和跳出 @var{action} 时调用。

当在 @var{action} 调用期间发生错误信号（或
调用了 escaping continuation）时，会调用函数 @var{jmp_handler}；
如果 @var{jmp_handler} 返回 @cpp{NULL}，则错误传递给
下一个错误 handler，否则返回值将用作
@cpp{scheme_dynamic_wind} 调用的返回值。

指针 @var{data} 可以是任何值；它会在对
@var{action}、@var{pre}、@var{post} 和 @var{jmp_handler} 的调用中传递。}


@function[(void scheme_clear_escape)]{

清除与线程关联的``jumping to escape continuation''标志。
在阻止 escape continuation 跳转时调用此函数（参见
@secref["imz:tempcatch"] 中的第一个示例）。}


@function[(void scheme_set_can_break
           [int on])]{

以与调用 @racket[break-enabled] 相同的方式
启用或禁用 break。}


@function[(void scheme_push_break_enable
           [Scheme_Cont_Frame_Data* cframe]
           [int on]
           [int pre_check])]{

将此函数与 @cpp{scheme_pop_break_enable} 一起使用，以与
@racket[call-with-break-parameterization] 相同的方式启用或
禁用 break；此函数写入
@var{cframe} 以初始化它，@cpp{scheme_pop_break_enable} 从
@var{cframe} 读取。如果 @var{pre_check} 非零且 break
当前已启用，则引发任何挂起的 break 异常。}


@function[(void scheme_pop_break_enable
           [Scheme_Cont_Frame_Data* cframe]
           [int post_check])]{

将此函数与 @cpp{scheme_push_break_enable} 一起使用。如果
@var{post_check} 非零且在恢复之前的
状态后 break 已启用，则引发任何挂起的 break 异常。}


@function[(Scheme_Object* scheme_current_continuation_marks
           [Scheme_Object* prompt_tag])]{

类似于 @racket[current-continuation-marks]。将 @cpp{NULL} 作为
@var{prompt_tag} 传递等同于提供默认的 continuation
prompt tag。}


@function[(void scheme_warning
           [char* msg]
           [... ...])]{

写出警告消息。参数大致与
@cpp{printf} 相同；更多细节参见上文的 @cpp{scheme_signal_error}。

通常，应使用 Racket 的 logging 设施而不是此
函数。}
