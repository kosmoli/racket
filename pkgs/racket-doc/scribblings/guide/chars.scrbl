#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "characters"]{字符}

Racket @deftech{字符}对应于 Unicode @defterm{标量值}。粗略地说，标量值是一个无符号整数，其表示适合21位，并且映射到某种自然语言字符或字符片段的概念。从技术上讲，标量值是一个比 Unicode 标准中称为``字符''的概念更简单的概念，但对于许多目的来说是一个很好的近似值。例如，任何带重音的罗马字母都可以表示为标量值，任何常见的中文字符也是如此。

尽管每个 Racket 字符对应于一个整数，但字符数据类型与数字是分开的。@racket[char->integer] 和 @racket[integer->char] 过程在标量值数字和相应字符之间转换。

可打印字符通常打印为 @litchar{#\} 后跟所表示的字符。不可打印字符通常打印为 @litchar{#\u} 后跟标量值作为十六进制数字。少数字符被特殊打印；例如，空格和换行字符分别打印为 @racket[#\space] 和 @racket[#\newline]。

@refdetails/gory["parse-character"]{字符的语法}

@examples[
(integer->char 65)
(char->integer #\A)
#\u03BB
(eval:alts @#,racketvalfont["#\\\\u03BB"] #\u03BB)
(integer->char 17)
(char->integer #\space)
]

@racket[display] 过程直接将字符写入当前输出端口（见 @secref["i/o"]），与用于打印字符结果的字符常量语法不同。

@examples[
#\A
(display #\A)
]

Racket 提供了几个关于字符的分类和转换过程。但请注意，对一些 Unicode 字符的转换只在它们位于字符串中时才按人类预期工作（例如，将``@elem["\\uDF"]''大写或``@elem["\\u03A3"]''小写）。

@examples[
(char-alphabetic? #\A)
(char-numeric? #\0)
(char-whitespace? #\newline)
(char-downcase #\A)
(char-upcase #\uDF)
]

@racket[char=?] 过程比较两个或多个字符，@racket[char-ci=?] 忽略大小写比较字符。@racket[eqv?] 和 @racket[equal?] 过程在字符上的行为与 @racket[char=?] 相同；当你想更具体地声明所比较的值是字符时，请使用 @racket[char=?]。

@examples[
(char=? #\a #\A)
(char-ci=? #\a #\A)
(eqv? #\a #\A)
]

@refdetails["characters"]{字符和字符过程}
