#lang scribble/doc
@(require scribble/manual "common.rkt")

@title[#:tag "ctool" #:style 'toc]{@exec{raco ctool}: 处理 C 代码}

@exec{raco ctool} 命令以各种模式工作（由命令行标志决定），
以支持涉及 C 代码的各种任务。

@local-table-of-contents[]

@; ----------------------------------------------------------------------

@include-section["cc.scrbl"]
@include-section["c-mods.scrbl"]
