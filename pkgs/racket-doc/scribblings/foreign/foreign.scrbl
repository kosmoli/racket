#lang scribble/doc
@(require "utils.rkt")

@title{Racket 外部接口}

@author["Eli Barzilay"]

@defmodule[ffi/unsafe #:use-sources ('#%foreign)]

@racketmodname[ffi/unsafe] 库使 Racket 程序可以直接使用基于 C 的 API——无需编写任何新的 C 代码。从 Racket 的角度看，拥有基于 C 的 API 的 function 和 data 被称为 @idefterm{foreign}，因此该术语为 @defterm{foreign interface}。此外，由于大多数 API 主要由 function 构成，外部接口有时也被称为 @defterm{foreign function interface}，缩写为 @deftech{FFI}。

@;------------------------------------------------------------------------

@table-of-contents[]

@include-section["intro.scrbl"]
@include-section["libs.scrbl"]
@include-section["types.scrbl"]
@include-section["pointers.scrbl"]
@include-section["derived.scrbl"]
@include-section["misc.scrbl"]
@include-section["unexported.scrbl"]

@(bibliography
  (bib-entry #:key "Barzilay04"
             #:author "Eli Barzilay and Dmitry Orlovsky"
             #:title "Foreign Interface for PLT Scheme"
             #:location "Workshop on Scheme and Functional Programming"
             #:date "2004"))

@index-section[]
