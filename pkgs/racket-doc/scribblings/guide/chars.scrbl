#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "characters"]{Characters}

Racket @deftech{字符} 对应一个 Unicode @defterm{标量值}。
大致上说，标量值是一个无符号整数，其表示可以放入 21 位中，
并映射到某种自然语言字符或字符片段的概念。从技术上讲，标量值
是比 Unicode 标准中称为"字符"的概念更简单的概念，但这是一个
在许多用途中效果很好的近似。例如，任何带重音的罗马字母以及
任何常见的中文字符都可以表示为标量值。

尽管每个 Racket 字符对应一个整数，但字符数据类型与数字是分开的。
@racket[char->integer] 和 @racket[integer->char] 过程在标量值数字
与对应字符之间进行转换。

可打印字符通常打印为 @litchar{#\\} 后跟所表示的字符。
不可打印字符通常打印为 @litchar{#\\u} 后跟以十六进制数字表示的
标量值。少数字符有特殊打印方式；例如，空格和换行符分别打印为
@racket[#\\space] 和 @racket[#\\newline]。

@refdetails/gory["parse-character"]{字符的语法}

@examples[
(integer->char 65)
(char->integer #\\A)
#\\u03BB
(eval:alts @#,racketvalfont["#\\\\u03BB"] #\\u03BB)
(integer->char 17)
(char->integer #\\space)
]

@racket[display] 过程直接将字符写入当前输出端口（参见
@secref["i/o"]），这与用于打印字符结果的字符常量语法形成对比。

@examples[
#\\A
(display #\\A)
]

Racket 提供了一些关于字符的分类和转换过程。但请注意，某些
Unicode 字符的转换只有在它们位于字符串中时才能按人类预期工作
（例如，将 ``@elem["\\uDF"]'' 转为大写或将 ``@elem["\\u03A3"]'' 转为小写）。

@examples[
(char-alphabetic? #\\A)
(char-numeric? #\\0)
(char-whitespace? #\\newline)
(char-downcase #\\A)
(char-upcase #\\uDF)
]

@racket[char=?] 过程比较两个或多个字符，@racket[char-ci=?] 在比较
字符时忽略大小写。@racket[eqv?] 和 @racket[equal?] 过程在字符上的
行为与 @racket[char=?] 相同；当你想更明确地声明被比较的值是字符时，
请使用 @racket[char=?]。

@examples[
(char=? #\\a #\\A)
(char-ci=? #\\a #\\A)
(eqv? #\\a #\\A)
]

@refdetails["characters"]{字符及字符过程}
