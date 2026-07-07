#lang scribble/doc
@(require scribble/manual
          scribble/example
          "guide-utils.rkt")

@(define noisy-eval (make-base-eval))

@title[#:tag "module-macro"]{Modules and Macros}

Racket 的 module 系统与 @tech{macro} 系统密切协作，从而为 Racket 引入新的 syntax 形式。举例来说，@racketmodname[racket/base] 的导出为 @racket[require] 和 @racket[lambda] 提供 syntax 的方式一样，导入其他其它模块也可以引入新的 syntax 形式（除了更传统的导入，如函数或常量之外）。

我们后面会在 @secref["macros"] 中详细介绍 macros，这里先提供一个基于模式匹配的宏的简单示例：

@examples[
#:eval noisy-eval
#:no-result
(module noisy racket
  (provide define-noisy)

  (define-syntax-rule (define-noisy (id arg ...) body)
    (define (id arg ...)
      (show-arguments (quote id) (list arg ...))
      body))

  (define (show-arguments name args)
    (printf "calling ~s with arguments ~e" name args)))
]

该模块提供的 @racket[define-noisy] 绑定是一个 @tech{macro}，它的行为类似于函数定义的 @racket[define]，不过会使得每次调用函数时打印出传给该函数的参数：

@examples[
#:label #f
#:eval noisy-eval
(require 'noisy)
(define-noisy (f x y)
  (+ x y))
(f 1 2)
]

粗略地说，@racket[define-noisy] 形式通过将

@racketblock[(define-noisy (f x y)
               (+ x y))]

替换为

@racketblock[(define (f x y)
               (show-arguments 'f (list x y))
               (+ x y))]

来完成展开。但由于 @racket[show-arguments] 并未由 @racket[noisy] 模块所在处提供，因此这种纯文本替换并不完全正确。实际的替换会正确地追踪像 @racket[show-arguments] 这类 identifier 的来源，使它们能引用宏定义位置的其它定义——即使那些 identifier 在宏使用处还不可见。

module 与宏的交互还不仅限于 identifier 绑定。@racket[define-syntax-rule] 形式本身也是一个宏，它展开为在编译期执行从 @racket[define-noisy] 到 @racket[define] 转换的代码。module 跟踪哪些代码需要在编译期执行、哪些需要正常执行，正如 @secref["stx-phases"] 和 @secref["macro-module"] 中进一步解释的那样。

@; ----------------------------------------------------------------------

@close-eval[noisy-eval]
