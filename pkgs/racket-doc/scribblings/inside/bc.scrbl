#lang scribble/base

@title[#:style '(toc grouper) #:tag "bc"]{Racket BC 内部机制（3m 和 CGC）}

Racket BC API 最初设计用于与 C 代码紧密集成。因此，BC API 比 Racket CS API 大得多。

@local-table-of-contents[]

@include-section["overview.scrbl"]
@include-section["embedding.scrbl"]
@include-section["extensions.scrbl"]
@include-section["values.scrbl"]
@include-section["memory.scrbl"]
@include-section["namespaces.scrbl"]
@include-section["procedures.scrbl"]
@include-section["eval.scrbl"]
@include-section["exns.scrbl"]
@include-section["threads.scrbl"]
@include-section["params.scrbl"]
@include-section["contmarks.scrbl"]
@include-section["strings.scrbl"]
@include-section["numbers.scrbl"]
@include-section["ports.scrbl"]
@include-section["structures.scrbl"]
@include-section["security.scrbl"]
@include-section["custodians.scrbl"]
@include-section["subprocesses.scrbl"]
@include-section["misc.scrbl"]
