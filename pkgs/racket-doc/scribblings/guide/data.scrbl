#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "datatypes" #:style 'toc]{内建数据类型}

前一章介绍了 Racket 的一些内建数据类型：数字、布尔值、字符串、列表和 procedure。本节对简单形式的内建数据类型提供更完整的覆盖。

@local-table-of-contents[]

@include-section["booleans.scrbl"]
@include-section["numbers.scrbl"]
@include-section["chars.scrbl"]
@include-section["char-strings.scrbl"]
@include-section["byte-strings.scrbl"]
@include-section["symbols.scrbl"]
@include-section["keywords.scrbl"]
@include-section["pairs.scrbl"]
@include-section["vectors.scrbl"]
@include-section["hash-tables.scrbl"]
@include-section["boxes.scrbl"]
@include-section["void-and-undef.scrbl"]

@; @include-section["paths.scrbl"]
@; @include-section["regexps-data.scrbl"]
