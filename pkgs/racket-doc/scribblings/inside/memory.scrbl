#lang scribble/doc
@(require "utils.rkt" (for-label ffi/unsafe
                                 ffi/unsafe/collect-callback))

@bc-title[#:tag "im:memoryalloc"]{内存分配}

@section-index{memory}
@section-index{garbage collection}

Racket 同时使用 @cppi{malloc} 和垃圾收集器提供的分配函数。外部函数和嵌入/扩展 C 代码可以使用任一分配方法，但需注意垃圾可收集块的指针存储在 @cpp{malloc} 分配的内存中对收集器是不可见的 (即此类指针不会阻止该块被垃圾收集)。

Racket CGC 使用保守垃圾收集器。此垃圾收集器通常只识别指向已分配对象开头的指针。因此，指向 GC 分配字符串中间的指针通常不会阻止该字符串被收集。此规则的例外是保存在栈上或寄存器中的指针可以指向可收集对象的中间。因此，通过递增局部指针变量来循环遍历数组是安全的。

Racket 3m 使用精确垃圾收集器，在收集期间移动对象，这种情况下 C 代码必须被工具化以向收集器暴露局部指针绑定，并为包含指针的 (带标签的) 记录提供遍历过程。此工具化在 @secref["im:3m"] 中有进一步描述。

基本的收集器分配函数包括：

@itemize[

 @item{@cppi{scheme_malloc} --- 分配可能包含指向可收集对象指针的可收集内存；对于 3m，内存必须是 (但不一定指向可收集对象的) 指针数组。新分配的内存最初被清零。}

 @item{@cppi{scheme_malloc_atomic} --- 分配不包含指向可收集对象指针的可收集内存。如果内存确实包含指针，它们对收集器不可见，不会阻止对象被收集。新分配的原子内存不一定被清零。

 原子内存用于字符串或不包含指针的其他内存块。原子内存也可用于存储有意隐藏的指针。}

 @item{@cppi{scheme_malloc_tagged} --- 分配包含指针和原子数据混合的可收集内存。对于保守收集器，此函数与 @cppi{scheme_malloc} 相同，但在 3m 上，存储在块开头的类型标签用于确定未来垃圾收集时对象的大小和形状 (如 @secref["im:3m"] 中所述)。}

 @item{@cppi{scheme_malloc_allow_interior} --- 分配一个指针数组，在 3m 中进行特殊处理：该数组永远不会被垃圾收集器移动，允许引用指向块中间，指向块中间的偶数值指针可防止该块被收集。(注意，内存管理器将任何奇数值指针视为 fixnum，即使它指向允许内部指针的块中间。) 请谨慎使用此过程，因为小型不可移动对象在 3m 收集器中的处理效率低于可移动对象。对于保守收集器，此过程与 @cppi{scheme_malloc} 相同，但在这种情况下，仅具有指向内部的指针不会阻止数组被收集。}

 @item{@cppi{scheme_malloc_atomic_allow_interior} --- 类似于 @cpp{scheme_malloc_allow_interior}，用于不包含指针的内存。}

 @item{@cppi{scheme_malloc_uncollectable} --- 分配可能包含指向可收集对象指针的不可收集内存。无法释放此内存。新分配的内存最初被清零。此函数在 3m 中不可用。}

]

@index['("globals" "in extension code")]{如果} Racket 扩展将 Racket 指针存储在全局变量或静态变量中，则该变量必须通过 @cppi{scheme_register_extension_global} 注册；这使指针对垃圾收集器可见。已注册的变量不必始终包含可收集指针（即使在 3m 中也是如此，但变量必须始终包含某个指针，可能是不可收集的）。注意，非线程特定（OS 意义上的"线程"）的静态或全局变量通常不能与多个 @|tech-place| 一起使用。

在大多数平台上，嵌入程序的全局变量和静态变量需要注册；如果程序使用非零的第一个或第二个参数（分别）调用 @cpp{scheme_main_setup} 或 @cppi{scheme_set_stack_base}，则在所有平台上都需要注册。包含可收集指针的全局变量和静态变量必须通过 @cppi{scheme_register_static} 注册。@cppi{MZ_REGISTER_STATIC} 宏接受任何变量名并通过 @cppi{scheme_register_static} 注册它。@cppi{scheme_register_static} 函数即使不需要也可以安全调用，但不能对同一内存地址多次调用。当使用 @cppi{scheme_set_stack_base} 且启用 @|tech-place| 时，@cppi{scheme_register_static} 或 @cppi{MZ_REGISTER_STATIC} 通常应仅在 @cpp{scheme_basic_env} 之后使用，因为 @cpp{scheme_basic_env} 会更改分配空间，如 @secref["im:3m:places"] 中所述。

可收集内存可以通过使用引用计数函数 @cppi{scheme_dont_gc_ptr} 暂时锁定以防止收集。在 3m 上，这种锁定不会阻止对象被移动。

垃圾收集可以在任何对 Racket 或其分配器的调用期间发生，在 Racket 拥有控制权的任何时候，但文档说明不会触发收集的函数除外。@secref["im:stdtypes"] 中列出的谓词和访问器宏从不触发收集。

如 @secref["im:3m:places"] 中所述，不同的 @|tech-place| 分别管理分配。可移动内存不应从一个 place 传递到另一个 place，因为源 place 可能在目标 place 使用该内存之前移动它。此外，包含指针的已分配内存不能在分配它的 @|tech-place| 之外的 place 中写入，这是由于分代垃圾收集的写屏障是特定于 place 的实现。对于通过 @cppi{scheme_malloc_atomic_allow_interior} 分配的不包含指针的内存，不使用写屏障。

@; ----------------------------------------------------------------------

@section[#:tag "im:3m"]{与 3m 协作}

为了让 3m 的精确收集器在垃圾收集期间检测和更新指针，所有指针值必须在可能发生收集的时间段内注册到收集器。注册为指针的字的内容必须包含以下之一：@cpp{NULL}、指向可收集对象开头的指针、指向由 @cpp{scheme_malloc_allow_interior} 分配的对象的指针、指向当前由另一个内存管理器分配的对象的指针（因此不在收集器当前管理的块中），或者指向奇数地址的指针（例如 Racket fixnum）。

指针通过三种不同的方式注册：

@itemize[

 @item{静态变量中的指针应通过 @cppi{scheme_register_static} 或 @cpp{MZ_REGISTER_STATIC} 注册。}

 @item{已分配内存中的指针在位于通过 @cpp{scheme_malloc} 等分配的数组中时自动注册。当指针驻留在通过 @cpp{scheme_malloc_tagged} 等分配的对象中时，对象开头的标签标识对象的大小和形状。标签的处理在 @secref["im:3m:tagged"] 中描述。}

 @item{局部指针（即栈上或寄存器中的指针）必须通过 @secref["im:3m:stack"] 中描述的 @cpp{MZ_GC_DECL_REG}、@|etc| 宏来注册。}

]

指针绝不能引用已分配对象的内部（当可能发生垃圾收集时），除非该对象是通过 @cppi{scheme_malloc_allow_interior} 分配的。因此，通常必须避免指针算术，除非在收集之前将保存生成的指针的变量设为 @cpp{NULL}。

@bold{重要：} @cppi{SCHEME_SYM_VAL}、@cppi{SCHEME_KEYWORD_VAL}、@cppi{SCHEME_VEC_ELS} 和 @cppi{SCHEME_PRIM_CLOSURE_ELS} 宏产生的指针指向各自对象的中间，因此这些宏的结果在可能发生收集期间不能被持有。错误地保留此类指针可能导致崩溃。

@; - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - - 

@subsection[#:tag "im:3m:tagged"]{带标签的对象}

如 @secref["im:values+types"] 中所述，@cpp{scheme_make_type} 函数可用于为新类型的对象获取新标签。这些新类型在 3m 中相对稀缺；最大标签为 512，Racket 自身使用近 300 个。

在 3m 中分配新标签后（且在创建该标签的实例之前），必须使用 @cppi{GC_register_traversers} 为该标签安装 @defterm{大小过程}、@defterm{标记过程} 和 @defterm{修正过程}。类型标签及其关联的 GC 过程适用于所有 @|tech-place|，即使特定的已分配对象仅限于某个特定的 @|tech-place|。

大小过程接受指向带有该标签的对象的指针，并返回其大小（以字为单位，而非字节）。@cppi{gcBYTES_TO_WORDS} 宏将字节数转换为字数。

标记过程用于追踪对象之间的引用。该过程接受指向对象的指针，并应对对象内的每个指针应用 @cppi{gcMARK} 宏。标记过程应返回与大小过程相同的结果。

修正过程可能用于更新对已移动对象的引用，尽管标记过程可能已经移动对象并更新了引用。修正过程接受指向对象的指针，并应对对象内的每个指针应用 @cppi{gcFIXUP} 宏。修正过程应返回与大小过程相同的结果。

根据收集器的实现，@cpp{gcMARK} 和/或 @cpp{gcFIXUP} 宏可能需要取其参数的地址，且修正过程可能不被使用。例如，收集器可能只使用标记过程而不实际移动对象。或者它可能同时使用标记来移动对象。要在标记或修正过程中解引用对象指针，使用 @cppi{GC_resolve} 将可能已旧的地址转换为对象已移动到的位置。要在修正过程中解引用对象指针，使用 @cppi{GC_fixup_self} 将传递给过程的地址转换为引用可能已移动的对象。

在 3m 中分配带标签的对象时，标签必须在对象分配后立即安装——或者至少在下次可能的收集之前安装。

@; - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - - 

@subsection[#:tag "im:3m:stack"]{局部指针}

3m 收集器需要知道函数调用内每个局部或临时指针的地址，在可能触发收集的任何时刻。注意，嵌套函数调用可能隐藏临时指针；例如，在

@verbatim[#:indent 2]{
  scheme_make_pair(scheme_make_pair(scheme_true, scheme_false),
                   scheme_make_pair(scheme_false, scheme_true))
}

一个 @cpp{scheme_make_pair} 调用的结果在另一个 @cpp{scheme_make_pair} 调用期间位于栈上或寄存器中；此指针必须暴露给垃圾收集并使其可被更新。简单地将代码更改为

@verbatim[#:indent 2]{
  tmp = scheme_make_pair(scheme_true, scheme_false);
  scheme_make_pair(tmp,
                   scheme_make_pair(scheme_false, scheme_true))
}

不会暴露所有指针，因为 @cpp{tmp} 必须在第二次调用 @cpp{scheme_make_pair} 之前求值。通常，上述代码必须转换为以下形式

@verbatim[#:indent 2]{
  tmp1 = scheme_make_pair(scheme_true, scheme_false);
  tmp2 = scheme_make_pair(scheme_true, scheme_false);
  scheme_make_pair(tmp1, tmp2);
}

并且此转换后的形式必须进行工具化以注册 @cpp{tmp1} 和 @cpp{tmp2}。最终结果可能是

@verbatim[#:indent 2]{
  {
    Scheme_Object *tmp1 = NULL, *tmp2 = NULL, *result;
    MZ_GC_DECL_REG(2);

    MZ_GC_VAR_IN_REG(0, tmp1);
    MZ_GC_VAR_IN_REG(1, tmp2);
    MZ_GC_REG();

    tmp1 = scheme_make_pair(scheme_true, scheme_false);
    tmp2 = scheme_make_pair(scheme_true, scheme_false);
    result = scheme_make_pair(tmp1, tmp2);

    MZ_GC_UNREG();

    return result;
  }
}

注意，上面的 @cpp{result} 未被注册。@cppdef{MZ_GC_UNREG} 宏不能触发垃圾收集，因此 @cpp{result} 变量在可能的收集期间从未存活。另请注意，@cpp{tmp1} 和 @cpp{tmp2} 用 @cpp{NULL} 初始化，因此每当可能发生收集时，它们始终包含一个指针。

@cppdef{MZ_GC_DECL_REG} 宏展开为一个局部变量声明，用于保存垃圾收集器的信息。参数是要提供的注册槽位数。注册简单指针需要一个槽位，而注册指针数组需要三个槽位。例如，要注册指针 @cpp{tmp} 和一个包含 10 个 @cpp{char*} 的数组：

@verbatim[#:indent 2]{
  {
    Scheme_Object *tmp1 = NULL;
    char *a[10];
    int i;
    MZ_GC_DECL_REG(4);

    MZ_GC_ARRAY_VAR_IN_REG(0, a, 10);
    MZ_GC_VAR_IN_REG(3, tmp1);
    /* Clear a before a potential GC: */
    for (i = 0; i < 10; i++) a[i] = NULL;
    ...
    f(a);
    ...
  }
}

@cppdef{MZ_GC_ARRAY_VAR_IN_REG} 宏注册一个局部数组，需要提供起始槽位、数组变量和数组大小。@cppdef{MZ_GC_VAR_IN_REG} 宏接受一个槽位和简单指针变量。局部变量或数组不能多次注册。

在上面的示例中，@cppi{MZ_GC_VAR_IN_REG} 的第一个参数是 @cpp{3}，因为 @cpp{a} 的信息使用前三个槽位。即使 @cpp{a} 在调用 @cpp{f} 之后不再使用，@cpp{a} 也必须在调用 @cpp{f} 的整个过程中向收集器注册，因为 @cpp{f} 可能在返回之前使用 @cpp{a}。

变量使用的名称不必是直接的。结构体成员也可以提供：

@verbatim[#:indent 2]{
  {
    struct { void *s; int v; void *t; } x = {NULL, 0, NULL};
    MZ_GC_DECL_REG(2);

    MZ_GC_VAR_IN_REG(0, x.s);
    MZ_GC_VAR_IN_REG(0, x.t);
    ...
  }
}

通常，对 @cppi{MZ_GC_VAR_IN_REG} 或 @cppi{MZ_GC_ARRAY_VAR_IN_REG} 的第二个参数的唯一约束是 @cpp{&} 必须产生相关地址，且该地址必须在栈上。

指针信息实际上在使用 @cppdef{MZ_GC_REG} 宏之前不会向收集器注册。@cppi{MZ_GC_UNREG} 宏取消注册该信息。每次调用 @cpp{MZ_GC_REG} 必须由一次 @cpp{MZ_GC_UNREG} 调用来平衡。

指针信息无需在调用 @cpp{MZ_GC_REG} 之前用 @cppi{MZ_GC_VAR_IN_REG} 和 @cppi{MZ_GC_ARRAY_VAR_IN_REG} 初始化，且已注册指针的集合可以随时更改——只要在可能发生收集时所有相关指针都已注册。以下示例回收槽位并在没有指针相关时完全取消注册信息。示例还说明了当控制从函数中逃逸时（例如 @cpp{scheme_signal_error} 逃逸），不需要 @cpp{MZ_GC_UNREG}。

@verbatim[#:indent 2]{
  {
    Scheme_Object *tmp1 = NULL, *tmp2 = NULL;
    mzchar *a, *b;
    MZ_GC_DECL_REG(2);

    MZ_GC_VAR_IN_REG(0, tmp1);
    MZ_GC_VAR_IN_REG(1, tmp2);
    
    tmp1 = scheme_make_utf8_string("foo");
    MZ_GC_REG();
    tmp2 = scheme_make_utf8_string("bar");
    tmp1 = scheme_append_char_string(tmp1, tmp2);

    if (SCHEME_FALSEP(tmp1))
      scheme_signal_error("shouldn't happen!");

    a = SCHEME_CHAR_VAL(tmp1);

    MZ_GC_VAR_IN_REG(0, a);

    tmp2 = scheme_make_pair(scheme_read_bignum(a, 0, 10), tmp2);

    MZ_GC_UNREG();

    if (SCHEME_INTP(tmp2)) {
      return 0;
    }

    MZ_GC_REG();
    tmp1 = scheme_make_pair(scheme_read_bignum(a, 0, 8), tmp2);
    MZ_GC_UNREG();

    return tmp1;
  }
}

@cpp{MZ_GC_DECL_REG} 可用于嵌套块中，以保存该块变量的声明。在这种情况下，嵌套的 @cpp{MZ_GC_DECL_REG} 必须有其自己的 @cpp{MZ_GC_REG} 和 @cpp{MZ_GC_UNREG} 调用。

@verbatim[#:indent 2]{
  {
    Scheme_Object *accum = NULL;
    MZ_GC_DECL_REG(1);
    MZ_GC_VAR_IN_REG(0, accum);
    MZ_GC_REG();

    accum = scheme_make_pair(scheme_true, scheme_null);
    {
      Scheme_Object *tmp = NULL;
      MZ_GC_DECL_REG(1);
      MZ_GC_VAR_IN_REG(0, tmp);
      MZ_GC_REG();

      tmp = scheme_make_pair(scheme_true, scheme_false);
      accum = scheme_make_pair(tmp, accum);

      MZ_GC_UNREG();
    }
    accum = scheme_make_pair(scheme_true, accum);

    MZ_GC_UNREG();
    return accum;
  }
}

在局部块中声明的变量也可以与外部块的变量一起注册，但局部块变量必须在超出作用域之前取消注册。@cppdef{MZ_GC_NO_VAR_IN_REG} 宏可用于取消注册变量或将槽位初始化为没有变量。

@verbatim[#:indent 2]{
  {
    Scheme_Object *accum = NULL;
    MZ_GC_DECL_REG(2);
    MZ_GC_VAR_IN_REG(0, accum);
    MZ_GC_NO_VAR_IN_REG(1);
    MZ_GC_REG();

    accum = scheme_make_pair(scheme_true, scheme_null);
    {
      Scheme_Object *tmp = NULL;
      MZ_GC_VAR_IN_REG(1, tmp);

      tmp = scheme_make_pair(scheme_true, scheme_false);
      accum = scheme_make_pair(tmp, accum);

      MZ_GC_NO_VAR_IN_REG(1);
    }
    accum = scheme_make_pair(scheme_true, accum);

    MZ_GC_UNREG();
    return accum;
  }
}

当未定义 @cpp{MZ_PRECISE_GC} 时，@cpp{MZ_GC_} 宏全部展开为空，因此这些宏可以放置在代码中，以便为保守收集和精确收集两者进行编译。

@cpp{MZ_GC_REG} 和 @cpp{MZ_GC_UNREG} 宏绝不能用于 Racket 线程以外的 OS 线程中。

@; - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - - 

@subsection[#:tag "im:3m:mzc"]{局部指针与 @|mzc| @DFlag{xform}}

当使用 @DFlag{xform} 标志和源 C 程序运行 @|mzc| 时，它会生成一个以前一节所述方式进行工具化的 C 程序（但使用稍有不同的宏集）。对于每个输入文件 @filepath{@italic{name}.c}，转换后的输出为 @filepath{@italic{name}.3m.c}。

@|mzc| 的 @DFlag{xform} 模式不会更改分配调用，也不会生成大小、标记或修正过程。它仅转换代码以注册局部指针。

此外，@|mzc| 的 @DFlag{xform} 模式不处理所有 C 语言特性。其重新排列复合表达式的能力尤其有限，因为 @DFlag{xform} 仅基于启发式方法转换表达式文本，而不是解析 C。该工具的未来版本将纠正此类问题。目前，@|mzc| 在 @DFlag{xform} 模式下尝试在无法转换程序时提供合理的错误消息，但请注意它可能会遗漏某些情况。在更有限的程度上，@DFlag{xform} 可以处理 C++ 代码。检查 @DFlag{xform} 模式的输出以确保代码已正确工具化。

一些具体的限制：

@itemize[

 @item{@cpp{for}、@cpp{while} 或 @cpp{do} 循环的主体必须用花括号括起来。（否则通常会报告转换错误。）}

 @item{函数调用不能出现在声明块内赋值的右侧。（如果发现此类赋值，通常会报告转换错误。）}

 @item{@cpp{... ? ... : ...} 中的多个函数调用无法提升。（否则通常会报告转换错误。）}

 @item{在赋值中，左侧必须是局部变量或静态变量，而不是字段选择、指针解引用等。（否则通常会报告转换错误。）}

 @item{转换假定所有函数调用使用函数的直接名称，而不是像 @cpp{s->f()} 这样的复合表达式。函数名不必是顶级函数名，但必须作为参数或局部变量以 @cpp{@var{type} @var{id}} 的形式绑定；语法 @cpp{@var{ret_type} (*@var{id})(...)} 无法识别，因此首先使用 @cpp{typedef} 将函数类型绑定到简单名称：@cpp{typedef @var{ret_type} (*@var{type})(...); .... @var{type} @var{id}}。}

 @item{数组和结构体必须通过地址传递。}

 @item{触发 GC 的代码不能出现在系统头文件中。}

 @item{当比较表达式中任一包含函数调用时，指针比较表达式无法正确处理。例如，当 @cpp{a} 和 @cpp{b} 产生指针值时，@cpp{a() == b()} 无法正确转换。}

 @item{将局部指针的地址传递给函数仅在指针变量在函数调用后仍然存活时才有效。}

 @item{@cpp{return;} 形式可能会被转换为 @cpp["{ " @var{stmt} "; return; };"]，这可能破坏 @cpp{if (...) return; else ...} 模式。}

 @item{union 类型的局部实例通常不受支持。}

 @item{指针算术无法转换，而是报告为错误。}

] 

@; - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - - 

@subsection[#:tag "im:3m:macros"]{引导 @|mzc| @DFlag{xform}}

以下宏可以（小心地！）用于引导 @DFlag{xform} 绕过它无法处理的代码：

@itemize[

@item{@cppdef{XFORM_START_SKIP} and @cppdef{XFORM_END_SKIP}: code
  between these two statements is ignored by the transform tool,
  except to tokenize it.

 Example:

@verbatim[#:indent 2]{
  int foo(int c, ...) {
    int r = 0;
    XFORM_START_SKIP;
    {
      /* va plays strange tricks that confuse xform */
      va_list args;
      va_start(args, c);
      while (c--) {
        r += va_arg(args, int);
      }
    }
    XFORM_END_SKIP;
    return r;
  }
}

 这些宏也可以在顶层使用，即在任何函数之外。但是，由于它们必须以分号结尾，顶层使用通常必须用 @cpp{#ifdef MZ_PRECISE_GC} 和 @cpp{#endif} 包裹；单独的分号在 C 的顶层是不合法的。}

@item{@cppdef{XFORM_SKIP_PROC}：注解一个函数，使其函数体以与用 @cpp{XFORM_START_SKIP} 和 @cpp{XFORM_END_SKIP} 括起来相同的方式被跳过。

    Example:

  @verbatim[#:indent 2]{
    int foo(int c, ...) XFORM_SKIP_PROC {
    }
  }}

@item{@cppdef{XFORM_HIDE_EXPR}：一个宏，用于包装表达式以禁用对该表达式的处理。

  Example:

  @verbatim[#:indent 2]{
    int foo(int c, ...) {
      int r = 0;
      {
        /* va plays strange tricks that confuse xform */
        XFORM_CAN_IGNORE va_list args; /* See below */
        XFORM_HIDE_EXPR(va_start(args, c));
        while (c--) {
          r += XFORM_HIDE_EXPR(va_arg(args, int));
        }
      }
      return r;
    }
  }}

@item{@cppdef{XFORM_CAN_IGNORE}：一个宏，作用类似于类型修饰符（必须首先出现），指示声明的变量可以被视为原子的。参见上方的示例。}

@item{@cppdef{XFORM_START_SUSPEND} 和 @cppdef{XFORM_END_SUSPEND}：用于顶层（在任何函数定义之外），与 @cpp{XFORM_START_SKIP} 和 @cpp{XFORM_END_SKIP} 类似，函数和类体不会被转换。但是，类型和原型信息仍会被收集，以供后续转换使用。这些形式必须以分号结尾。}

@item{@cppdef{XFORM_START_TRUST_ARITH} 和 @cppdef{XFORM_END_TRUST_ARITH}：用于顶层（在任何函数定义之外），以禁用关于指针算术的警告。仅在您绝对确定垃圾收集器不会有指针偏移到可收集对象中间时使用。这些形式必须以分号结尾。}

@item{@cppdef{XFORM_TRUST_PLUS}：@cpp{+} 的替代品，不会触发指针算术警告。小心使用。}

@item{@cppdef{XFORM_TRUST_MINUS}：@cpp{-} 的替代品，不会触发指针算术警告。小心使用。}

]

@; - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - -  - - 

@subsection[#:tag "im:3m:places"]{Places 与垃圾收集器实例}

当启用 @|tech-place| 时，单个进程可以在同一进程中拥有多个垃圾收集器实例。每个 @|tech-place| 使用自己的收集器进行分配，不允许任何 place 持有对另一个 place 分配的内存的引用。此外，一个 @deftech{master} 垃圾收集器实例保存着在 place 之间共享的值；不同的 place 可以引用由 @tech{master} 垃圾收集器分配的内存，但 @tech{master} 仍然不能引用由特定 place 的垃圾收集器分配的内存。

调用 @cpp{scheme_main_stack_setup} 会创建 @tech{master} 垃圾收集器，分配使用该收集器直到 @cpp{scheme_basic_env} 返回，此时初始 place 的垃圾收集器生效。在调用 @cpp{scheme_basic_env} 之前使用 @cppi{scheme_register_static} 或 @cppi{MZ_REGISTER_STATIC} 会注册一个地址，该地址应仅用于保存在调用 @cpp{scheme_basic_env} 之前分配的值。更典型地，@cpp{scheme_register_static} 和 @cppi{MZ_REGISTER_STATIC} 仅在 @cpp{scheme_basic_env} 返回之后使用。使用 @cpp{scheme_main_setup} 会自动调用 @cpp{scheme_basic_env}，在这种情况下没有机会过早使用 @cpp{scheme_register_static} 或 @cppi{MZ_REGISTER_STATIC}。

@; --------------------------------------------------

@section{内存函数}

@function[(void* scheme_malloc
           [size_t n])]{

分配 @var{n} 字节的可收集内存，初始填充为零。分配的对象被视为指针数组。}

@function[(void* scheme_malloc_atomic
           [size_t n])]{

分配 @var{n} 字节的可收集内存，其中不包含垃圾收集器可见的指针。该对象@italic{不}初始化为零。}

@function[(void* scheme_malloc_uncollectable
           [size_t n])]{

仅限非 3m。分配 @var{n} 字节的不可收集内存。}

@function[(void* scheme_malloc_eternal
           [size_t n])]{

分配不可收集的原子内存。此函数等效于 @cpp{malloc}，但内存无法释放。}

@function[(void* scheme_calloc
           [size_t num]
           [size_t size])]{

使用 @cpp{scheme_malloc} 分配 @var{num} * @var{size} 字节的内存。}

@function[(void* scheme_malloc_tagged
           [size_t n])]{

类似于 @cpp{scheme_malloc}，但在 3m 中，类型标签决定垃圾收集器如何遍历对象；参见 @secref["im:memoryalloc"]。}

@function[(void* scheme_malloc_allow_interior
           [size_t n])]{

类似于 @cpp{scheme_malloc}，但在 3m 中，对象永不移动，且允许指针引用对象中间；参见 @secref["im:memoryalloc"]。}

@function[(void* scheme_malloc_atomic_allow_interior
           [size_t n])]{

类似于 @cpp{scheme_malloc_atomic}，但在 3m 中，对象永不移动，且允许指针引用对象中间；参见 @secref["im:memoryalloc"]。}

@function[(void* scheme_malloc_stubborn
           [size_t n])]{

@cpp{scheme_malloc} 的过时变体，其中当不再对分配的内存进行更改时，可以对已分配的指针调用 @cpp{scheme_end_stubborn_change}。顽固分配作为分代收集的提示可能有用，但该提示通常被忽略，且在未来的版本中不太可能更多使用。}

@function[(void* scheme_end_stubborn_change
           [void* p])]{

声明通过 @cpp{scheme_malloc_stubborn} 分配的内存 @var{p} 的更改结束。}

@function[(char* scheme_strdup
           [char* str])]{

复制以 null 结尾的字符串 @var{str}；副本是可收集的。}

@function[(char* scheme_strdup_eternal
           [char* str])]{

复制以 null 结尾的字符串 @var{str}；副本永不被释放。}

@function[(void* scheme_malloc_fail_ok
           [|void *(*)(size_t)| mallocf]
           [size_t size])]{

尝试使用 @var{mallocf} 分配 @var{size} 字节。如果分配失败，则引发 @racket[exn:fail:out-of-memory] 异常。}

@function[(void** scheme_malloc_immobile_box
           [void* p])]{

分配不被垃圾收集且不移动的内存（即使在 3m 中），但其第一个字包含指向可收集对象的指针。该 box 用 @var{p} 初始化，但值可以随时更改。不可移动的 box 必须使用 @cpp{scheme_free_immobile_box} 显式释放。}

@function[(void scheme_free_immobile_box
           [void** b])]{

释放通过 @cpp{scheme_malloc_immobile_box} 分配的不可移动 box。}

@function[(void* scheme_malloc_code [intptr_t size])]{

分配不可收集的内存以保存可执行机器代码。使用此函数而不是 @cpp{malloc}，以确保分配的内存具有"执行"权限。使用 @cpp{scheme_free_code} 释放此函数分配的内存。}

@function[(void scheme_free_code [void* p])]{

释放通过 @cpp{scheme_malloc_code} 分配的内存。}

@function[(void scheme_register_extension_global
           [void* ptr]
           [intptr_t size])]{

注册可以包含 Racket 指针的扩展全局变量（针对当前 @|tech-place|）。全局变量的地址在 @var{ptr} 中给出，其大小（以字节为单位）在 @var{size} 中给出。

除了全局变量外，此函数还可用于注册收集器原本会视为原子的任何永久内存。注册期间可能发生垃圾收集。}


@function[(int scheme_main_setup
           [int no_auto_statics]
           [Scheme_Env_Main main]
           [int argc]
           [char** argv])]{

初始化 GC 栈基址，通过调用 @cpp{scheme_basic_env} 创建初始命名空间，然后使用命名空间、@var{argc} 和 @var{argv} 调用 @var{main}。（@var{argc} 和 @var{argv} 只是传递给 @var{main}，不会以任何方式检查。）

@cpp{Scheme_Env_Main} 类型定义如下：

@verbatim[#:indent 4]{
typedef int (*Scheme_Env_Main)(Scheme_Env *env, 
                               int argc, char **argv);
}

@var{main} 的结果就是 @cpp{scheme_main_setup} 的结果。

如果 @var{no_auto_statics} 非零，则必须将静态变量显式注册到垃圾收集器；参见 @secref["im:memoryalloc"] 了解更多信息。}


@function[(int scheme_main_stack_setup
           [int no_auto_statics]
           [Scheme_Nested_Main main]
           [void* data])]{

@cpp{scheme_main_setup} 的更原始变体，初始化 GC 栈基址但不创建初始命名空间（因此嵌入应用程序可以在创建命名空间之前执行涉及垃圾收集数据的其他操作）。

@var{data} 参数传递给 @var{main}，其中 @cpp{Scheme_Nested_Main} 类型定义如下：

@verbatim[#:indent 4]{
typedef int (*Scheme_Nested_Main)(void *data);
}}


@function[(void scheme_set_stack_base
           [void* stack_addr]
           [int no_auto_statics])]{

覆盖 GC 自动确定的栈基址，和/或禁用 GC 对全局变量和静态变量的自动遍历。如果 @var{stack_addr} 为 @cpp{NULL}，则使用 GC 确定的栈基址。否则，它应该是栈上可能存储可收集指针的"最深"内存地址。此函数应仅调用一次，且在任何其他 @cpp{scheme_} 函数调用之前，但仅适用于 CGC 且 future 和 places 被禁用的情况。此函数从不触发垃圾收集。

示例：

@verbatim[#:indent 4]{
    int main(int argc, char **argv) {
       int dummy;
       scheme_set_stack_base(&dummy, 0);
       real_main(argc, argv); /* calls scheme_basic_env(), etc. */
    }
}

在 3m 上，上述代码不完全正确，因为 @var{stack_addr} 必须是局部帧注册的开始或结束。更糟的是，在 CGC 或 3m 中，如果 @cpp{real_main} 声明为 @cpp{static}，编译器可能将其内联并将包含可收集值的变量放在比 @cpp{dummy} 更深的栈位置。为避免这些问题，请改用 @cpp{scheme_main_setup} 或 @cpp{scheme_main_stack_setup}。

上述代码在 Racket 中启用 future 和/或 places 时也可能无法工作，因为 @cpp{scheme_set_stack_base} 不初始化 Racket 的线程局部变量。同样，使用 @cpp{scheme_main_setup} 或 @cpp{scheme_main_stack_setup} 来避免此问题。}

@function[(void scheme_set_stack_bounds
           [void* stack_addr]
           [void* stack_end]
           [int no_auto_statics])]{

类似于 @cpp{scheme_set_stack_base}，但多了额外的 @var{stack_end} 参数。如果 @var{stack_end} 非 @cpp{NULL}，则它对应于 C 栈增长的一个点，超过该点 Racket 应尝试处理栈溢出。@var{stack_end} 参数不应与实际栈尾对应，因为检测栈溢出可能需要几帧，且处理栈溢出也需要几帧。

如果 @var{stack_end} 为 @cpp{NULL}，则栈尾自动计算：在 Unix 和 Mac OS 上，栈大小假定为 @cpp{getrlimit} 报告的限制；在 Windows 上，假定为可执行文件的栈保留（如果解析可执行文件失败则为 1 MB）；如果此大小大于 8 MB，则假定为 8 MB；大小减去 50000 字节（64 位 Windows：100000 字节）以覆盖较大的误差范围；最后，从 @var{stack_addr} 或自动计算的栈基址中减去（对于向下增长的栈）或加上（对于向上增长的栈）该大小。注意，假定 50000 字节的误差范围覆盖了实际栈起始和报告的栈基址之间的差异，以及检测和处理栈溢出所需的余量。}

@function[(void scheme_register_tls_space
           [void* ptr]
           [int   tls_index])]{

对于 Windows，将 @var{ptr} 注册为在主可执行文件中声明的线程局部指针变量的地址。该变量的存储将用于在 Racket 运行时内实现线程局部存储。参见 @secref["embedding"]。

@var{tls_index} 参数必须为 @cpp{0}。它目前被忽略，但未来版本可能使用该参数允许在动态链接的 DLL 中声明线程局部变量。

@history[#:changed "6.3" @elem{从仅 32 位 Windows 可用变更为所有 Windows 变体可用。}]}

@function[(void scheme_register_static
           [void* ptr]
           [intptr_t size])]{

类似于 @cpp{scheme_register_extension_global}，用于在收集器不会自动查找静态变量的情况下嵌入应用程序（即当 @cpp{scheme_set_stack_base} 被调用且第二个参数非零时）。

@cppi{MZ_REGISTER_STATIC} 宏可以直接用于静态变量。如果不需要注册静态变量，它展开为注释，否则展开为对 @cpp{scheme_register_static} 的调用（带有静态变量的地址）。}

@function[(void scheme_weak_reference
           [void** p])]{

将指针 @var{*p} 注册为弱指针；当没有其他（非弱）指针引用与 @var{*p} 引用相同的内存时，@var{*p} 将被垃圾收集器设置为 @cpp{NULL}。@var{*p} 中的值可以更改，但指针对注册时 @var{*p} 的值保持弱引用。

此函数在 3m 中不可用。}

@function[(void scheme_weak_reference_indirect
           [void** p]
           [void* v])]{

类似于 @cppi{scheme_weak_reference}，但当没有对 @var{v} 的引用时，@var{*p} 被设置为 @cpp{NULL}（无论其先前的值如何）。

此函数在 3m 中不可用。}

@function[(void scheme_register_finalizer
           [void* p]
           [fnl_proc f]
           [void* data]
           [fnl_proc* oldf]
           [void** olddata])]{

注册一个回调函数，当内存 @var{p} 本来会被垃圾收集，且没有为 @var{p} 注册"will"式终结器时调用。

@cpp{fnl_proc} 类型实际上并未定义，但它等效于

@verbatim[#:indent 2]{typedef void (*fnl_proc)(void *p, void *data)}

@var{f} 参数是回调函数；当它被调用时，将传递值 @var{p} 和数据指针 @var{data}；@var{data} 可以是任何内容——它仅传递给回调函数。如果 @var{oldf} 和 @var{olddata} 非 @cpp{NULL}，则 @var{*oldf} 和 @var{*olddata} 将填充旧的回调信息（@var{f} 和 @var{data} 将覆盖此旧回调）。

要移除已注册的终结器，为 @var{f} 和 @var{data} 传递 @cpp{NULL}。

注意：注册回调不仅阻止 @var{p} 被收集直到回调被调用，还使 @var{data} 保持可达直到回调被调用。}

@function[(void scheme_add_finalizer
           [void* p]
           [fnl_proc f]
           [void* data])]{

将终结器添加到原始终结器链中。此链与通过 @cpp{scheme_register_finalizer} 安装的单个终结器是分开的；链中的所有终结器在通过 @cpp{scheme_register_finalizer} 安装的终结器之后立即调用。

有关参数的信息，参见上方的 @cpp{scheme_register_finalizer}。

要移除已添加的终结器，使用 @cpp{scheme_subtract_finalizer}。}

@function[(void scheme_add_scheme_finalizer
           [void* p]
           [fnl_proc f]
           [void* data])]{

安装"will"式终结器，类似于 @racket[will-register]。Will 式终结器逐个调用，要求收集器在调用下一个 will 式终结器之前证明某个值已再次变得不可访问。通过 @cpp{scheme_register_finalizer} 或 @cpp{scheme_add_finalizer} 注册的终结器在所有 will 式终结器用尽之前不会被调用。

有关参数的信息，参见上方的 @cpp{scheme_register_finalizer}。

目前没有设施来移除 will 式终结器。}

@function[(void scheme_add_finalizer_once
           [void* p]
           [fnl_proc f]
           [void* data])]{

类似于 @cpp{scheme_add_finalizer}，但如果 @var{f} 和 @var{data} 的组合已经作为 @var{p} 的（非"will"式）终结器注册，则不会再次添加。}

@function[(void scheme_add_scheme_finalizer_once
           [void* p]
           [fnl_proc f]
           [void* data])]{

类似于 @cpp{scheme_add_scheme_finalizer}，但如果 @var{f} 和 @var{data} 的组合已经作为 @var{p} 的"will"式终结器注册，则不会再次添加。}

@function[(void scheme_subtract_finalizer
           [void* p]
           [fnl_proc f]
           [void* data])]{

移除通过 @cpp{scheme_add_finalizer} 安装的终结器。}

@function[(void scheme_remove_all_finalization
           [void* p])]{

移除 @var{p} 的所有终结（"will"式或非"will"式），包括在 Scheme 中使用 @racket[will-register] 添加的 wills 以及 custodian 使用的终结器。}

@function[(void scheme_dont_gc_ptr
           [void* p])]{

阻止可收集块 @var{p} 被垃圾收集。当对 @var{p} 的引用存储在收集器无法访问的某处时，使用此过程。一旦该引用不再从不可访问区域使用，使用 @cpp{scheme_gc_ptr_ok} 取消注册该锁。注册期间可能发生垃圾收集。

此函数对其注册的指针维护引用计数，因此对同一 @var{p} 的两次 @cppi{scheme_dont_gc_ptr} 调用应与两次 @cpp{scheme_gc_ptr_ok} 调用平衡。}

@function[(void scheme_gc_ptr_ok
           [void* p])]{

参见 @cpp{scheme_dont_gc_ptr}。}


@function[(void scheme_collect_garbage)]{

强制执行立即垃圾收集。}

@function[(void scheme_enable_garbage_collection [int on])]{

仅当内部计数器为 @cpp{0} 时才启用垃圾收集。使用 false 值调用 @cpp{scheme_enable_garbage_collection} 会增加计数器，使用 true 值调用 @cpp{scheme_enable_garbage_collection} 会减少计数器。

当设置 @envvar{PLTDISABLEGC} 环境变量时，@exec{racket} 将内部计数器初始化为 @cpp{1} 以初始禁用垃圾收集。}


@function[(void GC_register_traversers
           [short tag]
           [Size_Proc s]
           [Mark_Proc m]
           [Fixup_Proc f]
           [int is_const_size]
           [int is_atomic])]{

仅限 3m。为给定类型标签注册大小、标记和修正过程；参见 @secref["im:3m:tagged"] 了解更多信息。

这三个过程中的每一个都接受一个指针并返回一个整数：

@verbatim[#:indent 2]{
  typedef int (*Size_Proc)(void *obj);
  typedef int (*Mark_Proc)(void *obj);
  typedef int (*Fixup_Proc)(void *obj);
}

如果大小过程的结果是常量，则为 @var{is_const_size} 传递非零值。如果标记和修正过程是空操作，则为 @var{is_atomic} 传递非零值。}


@function[(void* GC_resolve [void* p])]{

仅限 3m。可由通过 @cpp{GC_register_traversers} 注册的大小、标记或修正过程调用。它返回可能已经移动的对象 @var{p} 的当前地址。例如，如果对象的大小或结构取决于其引用的对象的内容，则此转换是必要的。例如，类实例的大小通常取决于存储在类中的字段计数。修正过程应在修正引用@emph{之前}对该引用调用此函数。}


@function[(void* GC_fixup_self [void* p])]{

仅限 3m。可由通过 @cpp{GC_register_traversers} 注册的修正过程调用。它返回 @var{p} 的最终地址，该地址必须是传递给修正过程的指针。@cpp{GC_resolve} 函数会产生相同的结果，但 @cpp{GC_fixup_self} 可能更高效。对于内存管理器的某些实现，结果与 @var{p} 相同，这要么是因为对象未被移动，要么是因为对象在修正之前已被移动。对于其他实现，对象可能在修正过程之后被移动，结果是在垃圾收集完成后对象将位于的位置。}


@function[(void scheme_register_type_gc_shape [short type]
                                              [intptr_t* shape])]{

类似于 @cpp{GC_register_traversers}，但使用一组预定义函数来解释 @var{shape} 以遍历值。@var{shape} 数组是以 @cpp{SCHEME_GC_SHAPE_TERM} 结尾的命令序列，每个命令有一个参数。

命令：

@itemlist[

 @item{@tt{#define @cppdef{SCHEME_GC_SHAPE_TERM} 0} --- 终止命令，没有参数。}

 @item{@tt{#define @cppdef{SCHEME_GC_SHAPE_PTR_OFFSET} 1} --- 指定带有 @var{type} 标签的对象有一个指针需要对垃圾收集器可见，其中命令参数是从对象开头的偏移量。}

 @item{@tt{#define @cppdef{SCHEME_GC_SHAPE_ADD_SIZE} 2} --- 指定带有 @var{type} 标签的对象的分配大小，其中命令参数是要添加到累积大小的量；目前，大小信息未被使用，但在未来的垃圾收集器实现中可能需要。}

]

为了提高向前兼容性，任何其他命令都被假定为接受单个参数并被忽略。

GC 形状注册是特定于 place 的，即使 @cpp{scheme_make_type} 创建的类型标签跨越 places。如果当前 place 中已为 @cpp{type} 安装了遍历器，则旧的遍历规范将被替换。@cpp{scheme_register_type_gc_shape} 函数保留数组 @var{shape} 的自己的副本，因此无需保留该数组。

@history[#:added "6.4.0.10"]}


@function[(Scheme_Object* scheme_add_gc_callback [Scheme_Object* pre_desc]
                                                 [Scheme_Object* post_desc])]{

与 @racketmodname[ffi/unsafe/collect-callback] 中的 @racket[unsafe-add-collect-callbacks] 相同。}

@function[(void scheme_remove_gc_callback [Scheme_Object* key])]{

与 @racket[unsafe-remove-collect-callbacks] 相同，移除通过 @cpp{scheme_add_gc_callback} 安装的垃圾收集回调。}
