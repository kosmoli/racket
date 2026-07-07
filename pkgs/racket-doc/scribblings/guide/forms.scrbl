#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "scheme-forms" #:style 'toc]{Expressions and Definitions}

@secref["to-scheme"] 章介绍了一些 Racket 的语法形式：定义、procedure 应用、条件表达式等。本节提供了这些形式的更多基本信息，以及一些附加的基本形式。

@local-table-of-contents[]

@section[#:tag "syntax-notation"]{Notation}

本章（以及文档其余部分）使用的符号约定与 @secref["to-scheme"] 章基于字符的语法略有不同。语法形式 @racketkeywordfont{something} 的语法如下所示：

@specform[(#,(racketkeywordfont "something") [id ...+] an-expr ...)]

此规范中的斜体 meta 变量（如 @racket[_id] 和 @racket[_an-expr]）使用 Racket 标识符的语法，因此 @racket[_an-expr] 是一个 meta 变量。命名约定隐式定义了许多 meta 变量的含义：

@itemize[

 @item{以 @racket[_id] 结尾的 meta 变量代表标识符，如 @racketidfont{x} 或 @racketidfont{my-favorite-martian}。}

 @item{以 @racket[_keyword] 结尾的 meta 标识符代表关键字，如 @racket[#:tag]。}

 @item{以 @racket[_expr] 结尾的 meta 标识符代表任意子形式，将被解析为表达式。}

 @item{以 @racket[_body] 结尾的 meta 标识符代表任意子形式；将被解析为局部定义或表达式。最后一个 @racket[_body] 必须是表达式；另见 @secref["intdefs"]。}

]

语法中的方括号表示括号包围的形式序列，其中通常使用方括号（按照约定）。也就是说，方括号 @italic{不} 表示语法形式的可选部分。

@racketmetafont{...} 表示前一个形式的零次或多次重复，@racketmetafont{...+} 表示前一个数据的一次或多次重复。否则，非斜体标识符代表它们自身。

基于上述语法，以下是 @racketkeywordfont{something} 的一些合格用法：

@racketblock[
(#,(racketkeywordfont "something") [x])
(#,(racketkeywordfont "something") [x] (+ 1 2))
(#,(racketkeywordfont "something") [x my-favorite-martian x] (+ 1 2) #f)
]

某些语法形式规范引用了未隐式定义且未先前定义的 meta 变量。此类 meta 变量在主形式之后使用类似 BNF 的格式定义：

@specform/subs[(#,(racketkeywordfont "something-else") [thing ...+] an-expr ...)
               ([thing thing-id
                       thing-keyword])]

上述示例表示，在 @racketkeywordfont{something-else} 形式中，@racket[_thing] 是标识符或关键字。

@;------------------------------------------------------------------------

@include-section["binding.scrbl"]
@include-section["apply.scrbl"]
@include-section["lambda.scrbl"]
@include-section["define.scrbl"]
@include-section["let.scrbl"]
@include-section["cond.scrbl"]
@include-section["begin.scrbl"]
@include-section["set.scrbl"]
@include-section["quote.scrbl"]
@include-section["qq.scrbl"]
@include-section["case.scrbl"]
@include-section["parameterize.scrbl"]
