#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "all-sync" #:style 'toc]{同步}

Racket 的同步工具箱跨越四层：

@itemize[

@item{@tech{synchronizable events} --- 同步的一般框架；}

@item{@tech{channels} --- 原则上可用于构建大多数其他类型的 synchronizable events（组成事件的那些除外）的原语；以及}

@item{@tech{semaphores} --- 用于同步的简单且特别廉价的原语。}

@item{@tech{future semaphores} --- 用于 @tech{futures} 的简单同步原语。}

]


@local-table-of-contents[]

@include-section["evts.scrbl"]
@include-section["channels.scrbl"]
@include-section["semaphores.scrbl"]
@include-section["async-channels.scrbl"]
