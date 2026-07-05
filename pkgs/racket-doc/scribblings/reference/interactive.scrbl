#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "interactive"]{交互式模块加载}

@racketmodname[racket/rerequire] 和 @racketmodname[racket/enter]
库提供对加载、重载和使用模块的支持。

@include-section["enter.scrbl"]

@include-section["rerequire.scrbl"]
