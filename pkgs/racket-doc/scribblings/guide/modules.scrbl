#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "modules" #:style 'toc]{模块}


模块让你能够将 Racket 代码组织成多个文件和可重用的库。

@local-table-of-contents[]

@include-section["module-basics.scrbl"]
@include-section["module-syntax.scrbl"]
@include-section["module-paths.scrbl"]
@include-section["module-require.scrbl"]
@include-section["module-provide.scrbl"]
@include-section["module-set.scrbl"]
@include-section["module-macro.scrbl"]
@include-section["module-protect.scrbl"]
