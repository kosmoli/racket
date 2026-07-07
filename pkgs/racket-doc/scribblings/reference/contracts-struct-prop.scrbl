#lang scribble/manual
@(require scribble/struct scribble/decode scribble/eval
          (for-label racket/base racket/contract))

@(define the-eval (make-base-eval))
@(the-eval '(require racket/contract))

@title{Structure Type Property Contracts}

@defproc[(struct-type-property/c [value-contract contract?])
         contract?]{

产生一个用于 @tech{structure type property} 的 contract。当契约应用于一个 struct type 属性时，它会产生一个包装后的 struct type property，在用于创建新 struct 类型时（通过 @racket[struct]、@racket[make-struct-type] 等）将 @racket[value-contract] 应用于与该属性关联的值。

该 struct type property 的 accessor function 不受影响；如果它被导出，必须单独保护。

作为示例，考虑以下模块。它创建了一个 structure type property @racket[prop]，其值应是一个将 structure 实例映射到 numeric predicate 的函数。该模块还导出 @racket[app-prop]，它从 structure 实例中提取 predicate 并将其应用于给定值。

@interaction[#:eval the-eval
(module propmod racket
  (require racket/contract)
  (define-values (prop prop? prop-ref)
    (make-struct-type-property 'prop))
  (define (app-prop x v)
    (((prop-ref x) x) v))
  (provide/contract
   [prop? (-> any/c boolean?)]
   [prop (struct-type-property/c
          (-> prop? (-> integer? boolean?)))]
   [app-prop (-> prop? integer? boolean?)])
  (provide prop-ref))
]

@racket[structmod] 模块创建了一个名为 @racket[s] 的 structure type，带有一个单字段；@racket[prop] 的值是一个从实例中提取字段值的函数。因此该字段本应是 integer predicate，但请注意 @racket[structmod] 没有对 @racket[s] 放置任何 contract 来执行该约束。

@interaction[#:eval the-eval
(module structmod racket
  (require 'propmod)
  (struct s (f) #:property prop (lambda (s) (s-f s)))
  (provide (struct-out s)))
(require 'propmod 'structmod)
]

首先我们创建一个带有 integer predicate 的 @racket[s] 实例，因此实际上满足了对 @racket[prop] 的约束。对 @racket[app-prop] 的第一次调用是正确的；第二次调用只是违反了 @racket[app-prop] 的 contract。

@interaction[#:eval the-eval
(define s1 (s even?))
(app-prop s1 5)
(app-prop s1 'apple)
]

我们可以创建值不是 integer predicate 的 @racket[s] 实例，但对它们应用 @racket[app-prop] 会 blame @racket[structmod]，因为与 @racket[prop] 关联的函数——即 @racket[(lambda (s) (s-f s))]——并不总是产生满足 @racket[(-> integer? boolean?)] 的值。

@interaction[#:eval the-eval
(define s2 (s "not a fun"))
(app-prop s2 5)

(define s3 (s list))
(app-prop s3 5)
]

修复方法是将从 @racket[prop] 继承的 obligation 传播到 @racket[s]：

@racketblock[
(provide (contract-out
           [struct s ([f (-> integer? boolean?)])]))
]

最后，如果我们直接应用 property accessor @racket[prop-ref]，然后误用结果函数，则会 blame @racket[propmod] 模块：

@interaction[#:eval the-eval
((prop-ref s3) 'apple)
]

@racket[propmod] 模块有义务确保与 @racket[prop] 关联的函数仅应用于满足 @racket[prop?] 的值。通过直接提供 @racket[prop-ref]，它使该约束可以被违反（因此被 blame），即使实际的不良应用发生在别处。

通常完全没有必要提供 structure type property accessor；它通常只被模块内部的其它函数使用。但如果必须提供，应按如下方式保护：

@racketblock[
(provide (contract-out
           [prop-ref (-> prop? (-> prop? (-> integer? boolean?)))]))
]
}

@close-eval[the-eval]
