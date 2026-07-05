#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "concurrency" #:style 'toc]{并发和并行}

Racket 支持程序内的多个控制线程、线程本地存储、一些原始的同步机制
以及组合同步抽象的框架。此外，@racket[racket/future] 和
@racket[racket/place] 库提供支持并行性以提高性能。

@local-table-of-contents[]

@;------------------------------------------------------------------------

@include-section["threads.scrbl"]
@include-section["sync.scrbl"]
@include-section["thread-local.scrbl"]
@include-section["futures.scrbl"]
@include-section["places.scrbl"]
@include-section["engine.scrbl"]
@include-section["memory-order.scrbl"]
