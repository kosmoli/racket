#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "Procedure"]{Procedures}

@defterm{primitive procedure} 是一个可在 Racket 中调用的 procedure，
用 C 语言实现。primitive procedure 在 Racket 中通过
@cppi{scheme_make_prim_w_arity} 函数创建，该函数接收一个 C 函数指针、
primitive 的名称以及关于它接收多少个 Racket argument 的信息；
它返回一个 Racket procedure value。

实现该 procedure 的 C 函数必须接收两个参数：一个指定传递给 procedure 的
argument 数量的整数，以及一个 @cpp{Scheme_Object*} argument 数组。
传递给函数的 argument 数量将使用 arity 信息进行检查。
（提供给 @cpp{scheme_make_prim_w_arity} 的 arity 信息也用于 Racket 的
@racket[arity] procedure。）procedure 实现不允许修改输入的 argument 数组；
例外情况是，如果该数组与 @cpp{scheme_current_argument_stack} 的结果相同，
procedure 可以修改该数组。procedure 在适当时可以修改 argument 本身
（例如，填充一个 vector argument）。

@cppi{scheme_make_prim_closure_w_arity} 函数类似于
@cpp{scheme_make_prim_w_arity}，但它额外接收一个计数和一个将被复制到所创建
procedure 中的 @cpp{Scheme_Object*} 数组；当 closure 被调用时，该 procedure
会被传回给 C 函数。通过这种方式，可以将来自 C 世界的 closure-like 数据
与 primitive procedure 关联起来。

@cppi{scheme_make_closed_prim_w_arity} 函数类似于
@cpp{scheme_make_prim_closure_w_arity}，但它使用较旧的调用约定来传递
closure 数据。

为了与 Scheme 线程良好协作，执行大量或无限工作的 C 函数应偶尔调用
@cpp{SCHEME_USE_FUEL}；详见 @secref["usefuel"]。

@; ----------------------------------------------------------------------

@function[(Scheme_Object* scheme_make_prim_w_arity
           [Scheme_Prim* prim]
           [char* name]
           [int mina]
           [int maxa])]{

创建一个 primitive procedure value，给定 C 函数指针 @var{prim}。
@var{prim} 的形式由以下类型定义：

@verbatim[#:indent 2]{
   typedef Scheme_Object *(Scheme_Prim)(int argc, 
                                        Scheme_Object **argv);
}

@var{mina} 值应是必须提供给 procedure 的最小 argument 数量。@var{maxa} 值
应是可提供给 procedure 的最大 argument 数量，如果 procedure 可以接受任意多
个 argument 则为 -1。@var{mina} 和 @var{maxa} 值用于在调用 primitive 之前
自动检查 argument 数量，也用于 Racket 的 @indexed-racket[arity] procedure。
@var{name} 参数用于在运行时报告 application arity 错误。}

@function[(Scheme_Object* scheme_make_folding_prim
           [Scheme_Prim* prim]
           [char* name]
           [int mina]
           [int maxa]
           [short folding])]{

类似于 @cpp{scheme_make_prim_w_arity}，但如果 @var{folding} 非零，
编译器会假设该 procedure 对常量值的应用可以被折叠为常量。例如，
@racket[+]、@racket[zero?] 和 @racket[string-length] 是 folding primitive，
而 @racket[display] 和 @racket[cons] 不是。}

@function[(Scheme_Object* scheme_make_prim
           [Scheme_Prim* prim])]{

与 @cppi{scheme_make_prim_w_arity} 相同，但 arity 为 (0, -1) 且假定名称为
"UNKNOWN"。此函数仅为向后兼容而提供。}

@function[(Scheme_Object* scheme_make_prim_closure_w_arity
           [Scheme_Prim_Closure_Proc* prim]
           [int c]
           [Scheme_Object** vals]
           [char* name]
           [int mina]
           [int maxa])]{

创建一个包含 @var{c} 个 @var{vals} 值的 primitive procedure value；当 C 函数
@var{prim} 被调用时，生成的 primitive 会作为最后一个参数传入。@var{prim}
的形式由以下类型定义：

@verbatim[#:indent 2]{
   typedef
   Scheme_Object *(Scheme_Prim_Closure_Proc)(int argc, 
                                             Scheme_Object **argv, 
                                             Scheme_Object *prim);
}

宏 @cppdef{SCHEME_PRIM_CLOSURE_ELS} 接受一个 primitive-closure 对象，
返回一个与 @var{vals} 长度和内容相同的数组。（3m：关于
@cppi{SCHEME_PRIM_CLOSURE_ELS} 的警告请参见 @secref["im:3m"]。）}

@function[(Scheme_Object* scheme_make_closed_prim_w_arity
           [Scheme_Closed_Prim* prim]
           [void* data]
           [char* name]
           [int mina]
           [int maxa])]{

创建一个旧式 primitive procedure value；当 C 函数 @var{prim} 被调用时，
@var{data} 会作为第一个参数传入。@var{prim} 的形式由以下类型定义：

@verbatim[#:indent 2]{
   typedef
   Scheme_Object *(Scheme_Closed_Prim)(void *data, int argc, 
                                       Scheme_Object **argv);
}}

@function[(Scheme_Object* scheme_make_closed_prim
           [Scheme_Closed_Prim* prim]
           [void* data])]{

创建一个没有 arity 信息的闭包式 primitive procedure value。
此函数仅为向后兼容而提供。}

@function[(Scheme_Object** scheme_current_argument_stack)]{

返回指向一个用于 argument 传递的内部栈的指针。当传给 procedure 的
argument 数组与当前 argument 栈地址对应时，procedure 可以修改该数组。
具体来说，它可以清空 argument 数组中的指针，以便 argument 可以被内存管理器
回收（如果它们已不再可访问）。}
