#lang scribble/base

@title[#:style '(grouper toc) #:tag "cs"]{Racket CS 内部}

Racket CS API 是 Chez Scheme C API 的一个小型扩展，
如 @italic{The Chez Scheme User's Guide} 中所述。

@local-table-of-contents[]

@include-section["cs-overview.scrbl"]
@include-section["cs-embedding.scrbl"]
@include-section["cs-values.scrbl"]
@include-section["cs-procs.scrbl"]
@include-section["cs-start.scrbl"]
@include-section["cs-eval.scrbl"]
@include-section["cs-thread.scrbl"]
