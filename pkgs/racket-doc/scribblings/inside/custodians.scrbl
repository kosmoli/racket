#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/custodian))

@bc-title[#:tag "Custodians"]{Custodians}

当扩展分配必须显式释放的资源时（与必须显式关闭的 port 一样），
应在当前 custodian 的管理下放置一个与该资源关联的 Racket 对象，
调用 @cppi{scheme_add_managed}。

在分配资源之前，应调用 @cppi{scheme_custodian_check_available}
以确保相关 custodian 尚未关闭。如果已关闭，
@cpp{scheme_custodian_check_available} 将引发异常。
如果在调用 @cpp{scheme_add_managed} 时 custodian 已关闭，
则提供给 @cpp{scheme_add_managed} 的 close function 将被立即调用，
并且不会报告任何异常。

@; ----------------------------------------------------------------------

@function[(Scheme_Custodian* scheme_make_custodian
           [Scheme_Custodian* m])]{

创建一个作为 @var{m} 下级的新 custodian。如果 @var{m} 为 @cpp{NULL}，
则使用 main custodian 作为新 custodian 的 supervisor。
除非你打算创建一个特别受信任的 custodian，否则不要对 @var{m} 使用 @cpp{NULL}。}

@function[(Scheme_Custodian_Reference* scheme_add_managed
           [Scheme_Custodian* m]
           [Scheme_Object* o]
           [Scheme_Close_Custodian_Client* f]
           [void* data]
           [int strong])]{

将值 @var{o} 放入 custodian @var{m} 的管理之下。如果 @var{m} 为 @cpp{NULL}，
则使用当前 custodian。

@var{f} 函数由 custodian 调用，当其被要求"shutdown"其值时；
@var{o} 和 @var{data} 将被传递给 @var{f}，它的类型为

@verbatim{
typedef void (*Scheme_Close_Custodian_Client)(Scheme_Object *o, 
                                              void *data);
}

如果 @var{strong} 非零，则新托管值将一直保留，直到 custodian 将其关闭
或调用 @cpp{scheme_remove_managed}。如果 @var{strong} 为零，
该值允许被垃圾收集（并自动从 custodian 中移除）。

无论 @var{strong} 是否为零，值 @var{o} 最初被弱引用持有，
并在垃圾收集器尝试收集它时变为强引用持有。因此，
与 custodian 关联的值可以通过 will executors 进行终结。

@cpp{scheme_add_managed} 的返回值可用于在后续调用
@cpp{scheme_remove_managed} 中引用该值的 custodian。
一个值最多只能在一个 custodian 中注册。

如果 @var{m}（或当前 custodian，当 @var{m} 为 @cpp{NULL} 时）已关闭，
则 @var{f} 会立即被调用，结果为 @cpp{NULL}。

另请参见 @racket[register-custodian-shutdown]（来自
@racketmodname[ffi/unsafe/custodian]）。}

@function[(Scheme_Custodian_Reference* scheme_add_managed_close_on_exit
           [Scheme_Custodian* m]
           [Scheme_Object* o]
           [Scheme_Close_Custodian_Client* f]
           [void* data])]{

类似于以 @cpp{1} 作为最终参数调用 @cpp{scheme_add_managed}，
但也会在 Racket 退出时（无需显式 custodian shutdown）导致 @var{f} 被调用。}

@function[(void scheme_custodian_check_available
           [Scheme_Custodian* m]
           [const-char* name]
           [const-char* resname])]{

检查 @var{m} 是否已关闭，如果是则引发错误。
如果 @var{m} 为 @cpp{NULL}，则使用当前 custodian。
@var{name} 参数用于错误报告。@var{resname} 参数将来可能
用于检查预设限制；预设限制将具有符号名称，
@var{resname} 字符串将与这些符号进行比较。}

@function[(void scheme_remove_managed
           [Scheme_Custodian_Reference* mref]
           [Scheme_Object* o])]{

从其 custodian 的管理中移除 @var{o}。@var{mref} 参数必须是
@cpp{scheme_add_managed} 返回的值或 @cpp{NULL}。

另请参见 @racket[unregister-custodian-shutdown]（来自
@racketmodname[ffi/unsafe/custodian]）。}

@function[(void scheme_close_managed
           [Scheme_Custodian* m])]{

指示 custodian @var{m} 关闭其所有托管值。}

@function[(void scheme_add_atexit_closer
           [Scheme_Exit_Closer_Func f])]{

安装一个函数，在 Racket 即将退出时对每个 custodian 注册的项目及其 closer 调用。
注册的函数具有类型

@verbatim[#:indent 2]{
  typedef
  void (*Scheme_Exit_Closer_Func)(Scheme_Object *o,
                                  Scheme_Close_Custodian_Client *f, 
                                  void *d);
}

其中 @var{d} 是 @var{f} 的第二个参数。

退出函数按添加顺序的反序运行。一个初始注册的退出函数
（因此最后运行）会刷新每个 file-stream output port 并调用每个使用
@cpp{scheme_add_managed_close_on_exit} 注册的函数。

退出函数不应为每个给定的对象都应用 closer function。
特别是，关闭 file-stream output port 将会禁用最终退出函数的刷新操作。
通常，退出函数会忽略大多数对象，而处理需要特定清理操作的
特定类型对象，在 OS 级 process 终止之前。}

@function[(int scheme_atexit
               [Exit_Func func])]{

等同于调用系统的 @cpp{atexit} 函数。
提供此函数是为了给程序一个公共接口，不同系统以不同方式链接到 @cpp{atexit}。
@var{func} 的类型必须是：

 @verbatim[#:indent 2]{
  typedef void (*func)(void);
}}
