#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "thread-local-storage" #:style 'toc]{Thread-Local Storage}

@tech{Thread cells} 提供了对线程局部存储的原始支持。
@tech{Parameters} 结合了 thread cells 和 continuation marks，
以支持特定于线程和特定于 continuation 的绑定。

@local-table-of-contents[]

@include-section["thread-cells.scrbl"]
@include-section["parameters.scrbl"]
