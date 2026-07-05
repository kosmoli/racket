#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "load-lang"]{@racketmodname[racket/load] 语言}

@defmodulelang[racket/load]

@racketmodname[racket/load] 语言支持按如下方式求值：
模块体中每个顶层形式单独传递给 @racket[eval]，如同 @racket[load] 一般。

求值使用的命名空间与 @racketmodname[racket/load] 模块实例共享 @tech{module registry}，
但它有独立顶层环境，并以 @racketmodname[racket] 的绑定初始化。每个
@racketmodname[racket/load] 模块实例创建一个单独的命名空间
（即多个使用 @racketmodname[racket/load] 语言的模块共享一个命名空间）。
@racket[racket/load] 库仅导出 @racketidfont{#%module-begin} 和 @racketidfont{#%top-interaction}
形式，有效交换求值命名空间并调用 @racket[eval]。

例如，使用 @racket[racket/load] 的模块体可以包含 @racket[module] 形式，
使得运行以下模块打印 @racketresultfont{5}：

@racketmod[
racket/load

(module m racket/base
  (provide x)
  (define x 5))

(module n racket/base
  (require 'm)
  (display x))

(require 'n)
]

在 @racket[racket/load] 模块中的定义在当前命名空间中求值，
这意味着 @racket[load] 和 @racket[eval] 可以看到这些定义。例如，
运行以下模块打印 @racketresultfont{6}：

@racketmod[
racket/load

(define x 6)
(display (eval 'x))
]

由于 @racketmodname[racket/load] 模块内的所有形式都在顶层求值，
因此绑定无法通过 @racket[provide] 从模块中导出。同样，由于
模块体形式的求值本质上是动态的，编译模块基本没有收益。
因此，@racketmodname[racket/load] 应仅用于交互式探索顶层形式，
而不应用于构建更大的程序。
