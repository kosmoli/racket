#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "booleans"]{Booleans}

Racket 有两个不同的常量来表示布尔值：@racket[#t] 表示真，@racket[#f] 表示假。
大写的 @racketvalfont{#T} 和 @racketvalfont{#F} 被解析为相同的值，
但小写形式更受推荐。

@racket[boolean?] 过程识别这两个布尔常量。然而，对于 @racket[if]、
@racket[cond]、@racket[and]、@racket[or] 等的测试表达式结果，
除 @racket[#f] 以外的任何值都算作真。

@examples[
(= 2 (+ 1 1))
(boolean? #t)
(boolean? #f)
(boolean? "no")
(if "no" 1 0)
]
