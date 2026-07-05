#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "macros" #:style 'toc]{宏}

一个 @deftech{macro} 是一个语法形式，具有相关联的 @deftech{transformer}，它将原始形式展开为已有的形式。换句话说，宏是 Racket 编译器的扩展。@racketmodname[racket/base] 和 @racketmodname[racket] 的大多数语法形式实际上都是 macro，它们展开为一小部分核心结构。

像许多语言一样，Racket 提供了基于模式的宏，使得简单的转换易于实现且可靠使用。Racket还支持任意宏 transformer，它们用 Racket（或用宏扩展的 Racket 变体）实现。

本章提供了 Racket 宏的入门知识，但另请参见 @hyperlink["https://www.greghendershott.com/fear-of-macros/"]{@italic{Fear of Macros}}，它从一个不同的视角提供了介绍。

Racket 还包含对宏开发的额外支持：一个 @hyperlink["https://docs.racket-lang.org/macro-debugger/index.html"]{@italic{宏调试器}}，便于经验丰富的程序员调试其宏以及供新手研究其行为，以及 @hyperlink["https://docs.racket-lang.org/syntax/index.html"]{@italic{syntax/parse 库}}，用于编写宏和指定语法，可自动验证宏的使用并报告语法错误。

@local-table-of-contents[]

@;------------------------------------------------------------------------

@include-section["pattern-macros.scrbl"]
@include-section["proc-macros.scrbl"]
@include-section["macro-module.scrbl"]


