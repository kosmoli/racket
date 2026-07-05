#lang scribble/doc
@(require "utils.rkt")

@title[#:tag-prefix '(lib "scribblings/inside/inside.scrbl") 
       #:tag "top"]{内部：Racket C API}

@author["Matthew Flatt"]

Racket 运行时系统负责以下实现：原始数据类型（如数字和字符串）、从源文件中进行 Racket 宏展开和编译、求值过程中使用的内存分配与回收，以及并发线程和并行任务的调度。

本手册描述了 Racket 运行时系统的 C 接口，该接口根据 Racket 的实现（参见
@secref[#:doc '(lib "scribblings/guide/guide.scrbl")
"virtual-machines"]）而有所不同：Racket 的 CS 实现有一个接口，而 Racket 的 BC（3m 和 CGC）实现则有另一个接口。

当与外部库交互时，C 接口在一定程度上是相关的，如 @other-manual['(lib
"scribblings/foreign/foreign.scrbl")] 所述。尽管与外部代码的交互在纯 Racket 中使用 @racketmodname[ffi/unsafe] 模块构造，但关于表示、内存管理和并发的许多细节都在这里描述。本手册还描述了将 Racket运行时系统嵌入更大的程序中以及直接用 C 实现的库扩展 Racket 的方法。

@table-of-contents[]

@; ------------------------------------------------------------------------

@include-section["cs.scrbl"]
@include-section["bc.scrbl"]
@include-section["appendix.scrbl"]

@; ------------------------------------------------------------------------

@index-section[]
