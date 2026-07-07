#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title{Simple Values}

Racket 值包括数字、布尔值、string 和 byte string。在 DrRacket 和文档示例中
（当你阅读彩色文档时），值表达式显示为绿色。

@defterm{数字} 以通常的方式书写，包括分数和虚数：

@moreguide["numbers"]{numbers}

@racketblock[
1       3.14
1/2     6.02e+23
1+2i    9999999999999999999999
]

@defterm{布尔值} 为 @racket[#t] 表示真，@racket[#f] 表示假。
然而，在条件表达式中，所有非 @racket[#f] 的值都被视为真。

@moreguide["booleans"]{booleans}

@defterm{Strings} 在双引号之间书写。在 string 内，反斜杠是转义字符；
例如，反斜杠后跟双引号包含字面的双引号。除了未转义的双引号或反斜杠外，
任何 Unicode 字符都可以出现在 string 常量中。

@moreguide["strings"]{strings}

@racketblock[
"Hello, world!"
"Benjamin \"Bugsy\" Siegel"
"λx:(μα.α→α).xx"
]

当常量在 @tech{REPL} 中求值时，通常打印形式与输入语法相同。
在某些情况下，打印形式是输入语法的规范化版本。在文档和 DrRacket 的 @tech{REPL} 中，
结果以蓝色打印而不是绿色，以突出输入表达式与打印结果之间的区别。

@examples[
(eval:alts (unsyntax (racketvalfont "1.0000")) 1.0000)
(eval:alts (unsyntax (racketvalfont "\"Bugs \\u0022Figaro\\u0022 Bunny\"")) "Bugs \u0022Figaro\u0022 Bunny")
]