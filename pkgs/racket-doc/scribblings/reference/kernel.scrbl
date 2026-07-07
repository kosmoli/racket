#lang scribble/manual
@(require (for-label (except-in racket/base
                                lambda λ #%app #%module-begin)
                     (only-in racket/base
                              [#%plain-lambda lambda]
                              [#%plain-lambda λ]
                              [#%plain-app #%app]
                              [#%plain-module-begin #%module-begin])))

@title{Kernel Forms and Functions}

@defmodulelang[racket/kernel]{@racketmodname[racket/kernel] 库是一个
@tech{跨阶段持久}模块，提供最小的 syntactic form 和函数集。}

"最小"意味着 @racketmodname[racket/kernel] 仅包含内置于 Racket 编译器中的
form 和内置于运行时系统中的函数。目前，binding 集并不是特别小，也不是定义特别明确，
因为 built-in 函数集可能会频繁更改。谨慎使用 @racketmodname[racket/kernel]，
并注意其使用可能产生兼容性问题。

@racketmodname[racket/kernel] 模块导出 fully expanded 程序语法中的所有 binding
（参见 @secref["fully-expanded"]），但它将 @racket[#%plain-lambda] 作为
@racket[lambda] 和 @racket[λ] 提供，@racket[#%plain-app] 作为 @racket[#%app]，
以及 @racket[#%plain-module-begin] 作为 @racket[#%module-begin]。除了
@racket[#%datum]（其展开为 @racket[quote]），@racketmodname[racket/kernel]
不提供其他 syntactic binding。

@racketmodname[racket/kernel] 模块还导出 @racketmodname[racket/base] 中的许多
function binding，并且导出一些未由 @racketmodname[racket/base] 导出的其他函数，
因为 @racketmodname[racket/base] 导出了改进的变体。由
@racket[racket/kernel] 导出的 function binding 的确切集未指定，可能会在不同版本间变化。


@section[#:style '(hidden toc-hidden)]{}

@defmodule[racket/kernel/init]{@racketmodname[racket/kernel/init]
库重新提供所有 @racketmodname[racket/kernel] 的内容。它还提供
@racket[#%top-interaction]，这使得 @racketmodname[racket/kernel/init]
在 @exec{racket} 的 @Flag{I} 命令行标志下很有用。}