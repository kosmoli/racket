#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/os))

@title[#:tag "os-lib"]{Additional Operating System Functions}

@defmodule[racket/os]{@racketmodname[racket/os] 库提供查询操作系统的额外函数。}

@history[#:added "6.3"]

@defproc[(gethostname) string?]{
  返回当前机器的 hostname 字符串（包括域）。
}

@defproc[(getpid) exact-integer?]{
  返回标识操作系统内当前进程的整数。
}
