#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/undefined))

@title[#:tag "undefined"]{未定义}

@note-lib-only[racket/undefined]

常量 @racket[undefined] 可以用作占位符值，表示值将在稍后安装，
特别是对于提前访问该值难以或不可能检测或防止的情况。

@racket[undefined] 值始终与自身 @racket[eq?]。

@history[#:added "6.0.0.6"]

@defthing[undefined any/c]{"undefined" 常量。}
