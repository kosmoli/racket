#lang scribble/doc
@(require "mz.rkt")

@(define bool-eval (make-base-eval))
@(bool-eval '(require racket/bool))

@title[#:tag "booleans"]{布尔值}

真和假 @deftech{booleans} 分别由值 @racket[#t] 和 @racket[#f] 表示，不过依赖于布尔值的操作通常将 @racket[#f] 以外的任何值视为真。@racket[#t] 值总是 @racket[eq?] 于自身，@racket[#f] 也总是 @racket[eq?] 于自身。

@see-read-print["boolean" #:print "booleans"]{布尔值}

另请参见 @racket[and]、@racket[or]、@racket[andmap] 和 @racket[ormap]。


@defproc[(boolean? [v any/c]) boolean?]{

如果 @racket[v] 是 @racket[#t] 或 @racket[#f]，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[
(boolean? #f)
(boolean? #t)
(boolean? 'true)
]}


@defproc[(not [v any/c]) boolean?]{

如果 @racket[v] 是 @racket[#f]，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[
(not #f)
(not #t)
(not 'we-have-no-bananas)
]}


@defproc[(immutable? [v any/c]) boolean?]{

如果 @racket[v] 是不可变的 @tech{string}、@tech{byte string}、@tech{vector}、@tech{hash table} 或 @tech{box}，则返回 @racket[#t]，否则返回 @racket[#f]。

注意，@racket[immutable?] 不是不可变性的通用谓词（尽管它的名字暗示如此）。它只对少数几种 datatype 有效，这些 datatype 由单个谓词（@racket[string?]、@racket[vector?]、@|etc|）识别其可变和不可变变体。特别是，@racket[immutable?] 对 @tech{pair} 返回 @racket[#f]，尽管 pair 是不可变的，因为 @racket[pair?] 意味着不可变性。

另请参见 @racket[immutable-string?]、@racket[mutable-string?]，等等。

@examples[
(immutable? 'hello)
(immutable? "a string")
(immutable? (box 5))
(immutable? #(0 1 2 3))
(immutable? (make-hash))
(immutable? (make-immutable-hash '([a b])))
(immutable? #t)
]}

@section{布尔别名}

@note-lib[racket/bool]

@defthing[true boolean?]{@racket[#t] 的别名。}

@defthing[false boolean?]{@racket[#f] 的别名。}

@defproc[(symbol=? [a symbol?] [b symbol?]) boolean?]{

返回 @racket[(equal? a b)]（当 @racket[a] 和 @racket[b] 都是 symbol 时）。}

@defproc[(boolean=? [a boolean?] [b boolean?]) boolean?]{

返回 @racket[(equal? a b)]（当 @racket[a] 和 @racket[b] 都是 boolean 时）。}

@defproc[(false? [v any/c]) boolean?]{

返回 @racket[(not v)]。}

@defform[(nand expr ...)]{
  等同于 @racket[(not (and expr ...))]。

  @examples[#:eval
            bool-eval
            (nand #f #t)
            (nand #f (error 'ack "we don't get here"))]
}

@defform[(nor expr ...)]{
  等同于 @racket[(not (or expr ...))]。

  在两个参数的情况下，如果两个参数都不是真值，则返回 @racket[#t]。

  @examples[#:eval
            bool-eval
            (nor #f #t)
            (nor #t (error 'ack "we don't get here"))]


}

@defform[(implies expr1 expr2)]{
  检查以确保第一个 expression 蕴含第二个 expression。

  等同于 @racket[(if expr1 expr2 #t)]。

  @examples[#:eval
            bool-eval
            (implies #f #t)
            (implies #f #f)
            (implies #t #f)
            (implies #f (error 'ack "we don't get here"))]

}

@defproc[(xor [b1 any/c] [b2 any/c]) any]{
  返回 @racket[b1] 和 @racket[b2] 的异或值。

  如果 @racket[b1] 和 @racket[b2] 中恰好有一个不是 @racket[#f]，则返回该值。否则返回 @racket[#f]。

  @examples[#:eval
            bool-eval
            (xor 11 #f)
            (xor #f 22)
            (xor 11 22)
            (xor #f #f)]

}


@section{可变性谓词}

@note-lib-only[racket/mutability]

@history[#:added "8.9.0.3"]

@deftogether[(
@defproc[(mutable-string? [v any/c]) boolean?]
@defproc[(immutable-string? [v any/c]) boolean?]
@defproc[(mutable-bytes? [v any/c]) boolean?]
@defproc[(immutable-bytes? [v any/c]) boolean?]
@defproc[(mutable-vector? [v any/c]) boolean?]
@defproc[(immutable-vector? [v any/c]) boolean?]
@defproc[(mutable-box? [v any/c]) boolean?]
@defproc[(immutable-box? [v any/c]) boolean?]
@defproc[(mutable-hash? [v any/c]) boolean?]
@defproc[(immutable-hash? [v any/c]) boolean?]
)]{

将 @racket[string?]、@racket[bytes?]、@racket[vector?]、@racket[box?] 和 @racket[hash?] 与 @racket[immutable?] 或其反义组合的谓词。这些谓词可能比分别使用 @racket[immutable?] 和其他谓词更快。

}

@close-eval[bool-eval]
