#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "values"]{Multiple Values}

关于多结果值的一般信息，见 @secref["values-model"]。除了 @racket[call-with-values]（在本节中描述）之外，@racket[let-values]、@racket[let*-values]、@racket[letrec-values] 和 @racket[define-values] 等形式（以及其他）创建接收多个值的 continuations。

@defproc[(values [v any/c] ...) any]{

返回给定的 @racket[v]。即，@racket[values] 返回其提供的参数。

@examples[
(values 1)
(values 1 2 3)
(values)
]}

@defproc[(call-with-values [generator (-> any)] [receiver procedure?]) any]{

调用 @racket[generator]，并将 @racket[generator] 生成的值作为参数传递给 @racket[receiver]。因此，@racket[call-with-values] 创建一个 continuation，接受 @racket[receiver] 可接受的任意数量的值。@racket[receiver] procedure 在 @racket[call-with-values] 调用的尾位置被调用。

@examples[
(call-with-values (lambda () (values 1 2)) +)
(eval:error (call-with-values (lambda () 1) (lambda (x y) (+ x y))))
]}
