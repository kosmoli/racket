#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/keyword))

@title[#:tag "keywords"]{关键字}

@guideintro["keywords"]{关键字}

@deftech{Keyword} 类似于一个 @tech{interned} symbol，但其打印形式以 @litchar{#:} 开头，并且关键字不能被用作 identifier。此外，单独的关键字并不是有效的表达式，不过可以通过 @racket[quote] 来生成一个进而产生 symbol 的表达式。

两个关键字是 @racket[eq?] 的，当且仅当它们打印形式相同（即，关键字总是 @tech{interned} 的）。

与 symbol 类似，关键字仅被内部关键字表弱持有（weakly held）；参见 @secref["symbols"] 了解更多信息。

@see-read-print["keyword"]{关键字}

@defproc[(keyword? [v any/c]) boolean?]{

如果 @racket[v] 是关键字，返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(keyword? '#:apple)
             (keyword? 'define)
             (keyword? '#:define)]}


@defproc[(keyword->string [keyword keyword?]) string?]{

返回 @racket[keyword] 的 @racket[display] 形式所对应的字符串，不包括开头的 @litchar{#:}。

另请参见 @racket[keyword->immutable-string] from @racketmodname[racket/keyword]。

@mz-examples[(keyword->string '#:apple)]}


@defproc[(string->keyword [str string?]) keyword?]{

返回一个关键字，其 @racket[display] 形式与 @racket[str] 相同，但带有前导 @litchar{#:}。

@mz-examples[(string->keyword "apple")]}


@defproc[(keyword<? [a-keyword keyword?] [b-keyword keyword?] ...) boolean?]{

如果参数已排序，则返回 @racket[#t]，其中每对关键字之间的比较使用 @racket[keyword->string]、@racket[string->bytes/utf-8] 和 @racket[bytes<?] 进行。

@mz-examples[(keyword<? '#:apple '#:banana)]

@history/arity[]}


@; ----------------------------------------
@section{其他关键字函数}

@note-lib-only[racket/keyword]
@(define keyword-eval (make-base-eval))
@examples[#:hidden #:eval keyword-eval (require racket/keyword)]

@history[#:added "7.6"]

@defproc[(keyword->immutable-string [sym keyword?]) (and/c string? immutable?)]{

与 @racket[keyword->string] 类似，但其结果是一个不可变字符串，不一定是新分配的。

@examples[#:eval keyword-eval
          (keyword->immutable-string '#:apple)
          (immutable? (keyword->immutable-string '#:apple))]

@history[#:added "7.6"]}

@; ----------------------------------------
@close-eval[keyword-eval]
