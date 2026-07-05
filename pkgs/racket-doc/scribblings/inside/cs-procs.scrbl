#lang scribble/doc
@(require "utils.rkt")

@cs-title[#:tag "cs-procs"]{调用过程}

作为 Racket 的入口点，C 程序通常应使用 @cppi{racket_apply} 来调用 Racket 过程，该函数在主 Racket 场所的初始 Racket 线程中调用该过程。Chez Scheme 入口点（如 @cppi{Scall0} 和 @cppi{Scall}）直接在任何 Racket 线程之外调用过程，这在使用 Racket 设施（如线程、参数、continuation 或 continuation mark）时无法正确工作。

本节中的函数旨在用作 Racket 的入口点，但不用作 @emph{重新入口}点。当 Racket 调用一个 C 函数，而该 C 函数又回调到 Racket 时，最佳方法是使用 FFI（见 @other-doc['(lib
"scribblings/foreign/foreign.scrbl")]），以便 C 调用接收一个被包装为普通 C 回调的 Racket 回调。这样，FFI 可以处理 Racket 和 C 之间边界交叉的细节。

@; ----------------------------------------------------------------------

@function[(ptr racket_apply [ptr proc] [ptr arg_list])]{

将 Racket 过程 @var{proc} 应用于参数列表 @var{arg_list}。该过程在主 Racket 场所的原始 Racket 线程中调用。应用 @var{proc} 不得引发异常或以其他方式从对 @var{proc} 的调用中逃逸。

结果是一个结果值列表，其中来自 @var{proc} 的单个结果使 @cpp{racket_apply} 返回长度为 1 的列表。

其他 Racket 线程可以在对 @var{proc} 的调用期间运行。在 @var{proc} 产生结果时，主 Racket 场所中的所有 Racket 线程调度都被挂起。不会发生垃圾回收，因此其他 Racket 场所可以阻塞等待垃圾回收。}

@together[(
@function[(ptr Scall0 [ptr proc])]
@function[(ptr Scall1 [ptr proc] [ptr arg1])]
@function[(ptr Scall2 [ptr proc] [ptr arg1] [ptr arg2])]
@function[(ptr Scall3 [ptr proc] [ptr arg1] [ptr arg2] [ptr arg3])]
)]{

将 Chez Scheme 过程 @var{proc} 应用于零个、一个、两个或三个参数。请注意，并非所有 Racket 过程都是 Chez Scheme 过程。（例如，具有 @racket[prop:procedure] 的结构类型实例不是 Chez Scheme 过程。）

该过程在任何 Racket 线程之外调用，并且在对 @var{proc} 的调用期间不会调度其他 Racket 线程。可能会发生垃圾回收。}

@together[(
@function[(void Sinitframe [iptr num_args])]
@function[(void Sput_arg [iptr i] [ptr arg])]
@function[(ptr Scall [ptr proc] [iptr num_args])]
)]{

类似于 @cppi{Scall0}，但这些函数按顺序使用，以将 Chez Scheme 过程应用于任意数量的参数。首先，使用参数数量调用 @cppi{Sinitframe}。然后，使用 @cppi{Sput_arg} 安装每个参数，其中 @var{i} 参数指示参数位置，@var{arg} 是参数值。最后，使用过程和参数数量调用 @cppi{Scall}（该数量必须与提供给 @cppi{Sinitframe} 的数量匹配）。}
