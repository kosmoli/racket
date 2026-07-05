#lang scribble/doc
@(require "mz.rkt" (for-label racket/block))

@(define ev (make-base-eval))
@(ev '(require racket/block))

@title[#:tag "block"]{块：@racket[block]}

@note-lib-only[racket/block]

@defform[(block defn-or-expr ...)]{

支持表达式和相互递归定义的混合，如同在 @racket[module] 主体中一样。与 @tech{internal-definition context} 不同，最后一个 @racket[defn-or-expr] 不必是表达式。

@racket[block] 形式的结果是最后一个 @racket[defn-or-expr] 的结果（如果它是表达式），否则为 @|void-const|。如果未提供 @racket[defn-or-expr]（在展平 @racket[begin] 形式之后），则结果为 @|void-const|。

最终的 @racket[defn-or-expr] 在尾位置执行（如果它是表达式）。


@examples[#:eval ev
(define (f x)
  (block
    (define y (add1 x))
    (displayln y)
    (define z (* 2 y))
    (+ 3 z)))
(f 12)
]}

@close-eval[ev]
