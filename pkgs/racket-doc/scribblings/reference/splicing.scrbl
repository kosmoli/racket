#lang scribble/doc
@(require "mz.rkt" (for-label racket/splicing racket/stxparam racket/local))

@(define splice-eval (make-base-eval))
@examples[#:hidden #:eval splice-eval (require racket/splicing 
                                               racket/stxparam
                                               (for-syntax racket/base))]

@title[#:tag "splicing"]{使用 Splicing Body 的局部绑定}

@note-lib-only[racket/splicing]

@deftogether[(
@defidform[splicing-let]
@defidform[splicing-letrec]
@defidform[splicing-let-values]
@defidform[splicing-letrec-values]
@defidform[splicing-let-syntax]
@defidform[splicing-letrec-syntax]
@defidform[splicing-let-syntaxes]
@defidform[splicing-letrec-syntaxes]
@defidform[splicing-letrec-syntaxes+values]
@defidform[splicing-local]
@defidform[splicing-parameterize]
)]{

与 @racket[let]（不是 @tech{named @racket[let]}）、@racket[letrec]、@racket[let-values]、@racket[letrec-values]、@racket[let-syntax]、@racket[letrec-syntax]、@racket[let-syntaxes]、@racket[letrec-syntaxes]、@racket[letrec-syntaxes+values]、@racket[local] 和 @racket[parameterize] 类似，不同之处在于，在定义上下文中，body 形式被拼接到封闭的定义上下文中（与 @racket[begin] 相同）。

@examples[
#:eval splice-eval
(splicing-let-syntax ([one (lambda (stx) #'1)])
  (define o one))
o
(eval:error one)
]

当拼接绑定形式出现在 @tech{top-level context} 或 @tech{module context} 中时，其局部绑定被视为类似定义。特别是，语法绑定在每次 @tech{visit} 模块时求值，而不是像 @racket[let-syntax] 等仅在编译期间求值一次。

@examples[
#:eval splice-eval
(eval:error
 (splicing-letrec ([x bad]
                   [bad 1])
   x))]

如果拼接形式中的定义旨在成为拼接 body 的局部，则标识符应具有 @indexed-racket['definition-intended-as-local] @tech{syntax property} 的真值。例如，@racket[splicing-let] 本身在展开为定义序列时会将属性添加到局部绑定的标识符中，以便将 @racket[splicing-let] 嵌套在拼接形式中按预期工作（没有任何歧义的绑定）。

@history[
 #:changed "6.12.0.2" @elem{添加 @racket[splicing-parameterize]。}]}


@defidform[splicing-syntax-parameterize]{

与 @racket[syntax-parameterize] 类似，不同之处在于，在定义上下文中，body 形式被拼接到封闭的定义上下文中（与 @racket[begin] 相同）。在定义上下文中，@racket[splicing-syntax-parameterize] 的 body 可以为空。

注意 @tech{require transformers} 和 @tech{provide transformers} 不受语法参数化的影响。虽然所有 @racket[require] 和 @racket[provide] 的使用将被拼接到封闭的上下文中，但派生的导入或导出规范将展开，就像它们不在 @racket[splicing-syntax-parameterize] 内一样。

此外，使用 @racket[module*] 定义的 @tech{submodules} 在 @tech{module path} 位置指定 @racket[#f] 时会受语法参数化的影响，但其他 submodule（那些使用 @racket[module] 或具有 @tech{module path} 的 @racket[module*] 定义的）不受影响。

@examples[
#:eval splice-eval
(define-syntax-parameter place (lambda (stx) #'"Kansas"))
(define-syntax-rule (where) `(at ,(place)))
(where)
(splicing-syntax-parameterize ([place (lambda (stx) #'"Oz")])
  (define here (where)))
here
]

@history[
 #:changed "6.11.0.1"
 @elem{修改为语法参数化 @racket[module*] submodule，这些 submodule 在 @tech{module path} 位置指定 @racket[#f]。}]}

@; ----------------------------------------------------------------------

@close-eval[splice-eval]
