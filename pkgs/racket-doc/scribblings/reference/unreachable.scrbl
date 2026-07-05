#lang scribble/doc
@(require "mz.rkt" (for-label racket/unreachable racket/unsafe/ops))

@title[#:tag "unreachable"]{不可达表达式}

@defproc[(assert-unreachable) none/c]{

通过引发 @racket[exn:fail:contract] 报告断言失败，作为 @racket[unsafe-assert-unreachable] 的安全对应。

@history[#:added "8.0.0.11"]}


@section[#:tag "with-unreachable"]{自定义不可达报告}

@note-lib-only[racket/unreachable]

@history[#:added "8.0.0.11"]

@defform[(with-assert-unreachable
           body ...+)]{

类似 @racket[(assert-unreachable)]，断言不应到达 @racket[body] 形式。

除非表达式是包含 @racket[(#%declare #:unsafe)] 的 module 的一部分，否则它等同于 @racket[(let-values () body ...+)]。意图是 @racket[body] 形式将引发 @racket[exn:fail:contract]。

当 @racket[with-assert-unreachable] 表达式是具有 @racket[(#%declare #:unsafe)] 的 module 的一部分时，它等同于 @racket[(unsafe-assert-unreachable)]。}
