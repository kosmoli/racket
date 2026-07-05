#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "repl-module"]{@racketmodname[racket/repl] 库}

@defmodule[racket/repl]

@racketmodname[racket/repl] 提供了与 @racketmodname[racket/base] 相同的
@racket[read-eval-print-loop] 绑定，但内部依赖比 @racketmodname[racket/base] 更少。
它会在某些情况下在启动时载入，如
@secref["init-actions"] 中所述。
