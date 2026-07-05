#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/vm))

@cs-title[#:tag "cs-eval"]{求值和运行模块}

@cppi{racket_apply} 函数提供基本的求值支持，
但 @cppi{racket_eval}、@cppi{racket_dynamic_require} 和
@cppi{racket_namespace_require} 为初始化 Racket 实例时的
最常见求值任务提供了更高级的支持。

@function[(ptr racket_eval [ptr s_expr])]{

在初始 Racket 线程中使用其当前的 @tech[#:doc reference-doc]{namespace} 对 @var{s_expr} 进行求值，
与调用 @racket[eval] 相同。@var{s_expr} 可以是通过 pair、symbol 等
构建的 S-expression，也可以是一个 @tech[#:doc
reference-doc]{syntax object}。

使用 @cppi{racket_namespace_require} 来初始化 namespace，或使用
@cppi{racket_dynamic_require} 来访问功能而无需进入顶层 namespace。
尽管这些函数与使用 @racket[namespace-require] 和 @racket[dynamic-require] 相同，
但它们在 namespace 中未预先绑定这些标识符的情况下也能工作。

本节中的函数并非旨在从 Racket 调用的 C 代码中调用。
另请参阅 @secref["cs-procs"] 中关于 @emph{入口}点 与 @emph{重入口}点的讨论。}

@function[(ptr racket_dynamic_require [ptr module_path] [ptr sym_or_false])]{

与在初始 Racket 线程中调用 @racket[dynamic-require] 相同，使用其当前 namespace。
另请参阅 @cppi{racket_eval}。}


@function[(ptr racket_namespace_require [ptr module_path])]{

与在初始 Racket 线程中调用 @racket[namespace-require] 相同，使用其当前 namespace。
另请参阅 @cppi{racket_eval}。}

@function[(ptr racket_primitive [const-char* name])]{

以与 @racket[vm-primitive] 相同的方式访问 primitive function。}
