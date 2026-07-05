#lang scribble/doc
@(require scribble/manual "guide-utils.rkt")

@title[#:tag "languages" #:style 'toc]{创建语言}

前一章定义的 @tech{macro} 工具允许程序员为某种语言定义语法扩展，但宏有两个局限性：

@itemlist[

 @item{宏不能限制其上下文中可用的语法，也不能改变周围 form 的含义；且}

 @item{宏只能在语言词法约定的范围内扩展语言的语法，例如使用括号将宏名称与其子 form 分组，以及使用标识符、关键字和字面量的核心语法。}

]

@guideother{@secref["lists-and-syntax"] 中介绍了 @tech{reader} 和 @tech{expander} 层之间的区别。}

也就是说，宏只能在 @tech{expander} 层扩展语言。Racket 还提供了额外的工具，用于定义 @tech{expander} 层的起点、扩展 @tech{reader} 层以及定义 @tech{reader} 层的起点，并且可以将 @tech{reader} 和 @tech{expander} 起点打包成便捷命名的语言。

@local-table-of-contents[]

@;------------------------------------------------------------------------

@include-section["module-languages.scrbl"]
@include-section["reader-extension.scrbl"]
@include-section["hash-languages.scrbl"]
