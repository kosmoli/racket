#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "strings"]{字符串（Unicode）}

@deftech{字符串}是 @seclink["characters"]{字符}的固定长度数组。它使用双引号打印，其中字符串内部的双引号和反斜杠字符使用反斜杠转义。支持其他常见的字符串转义，包括用于换行的 @litchar{\n}、用于回车的 @litchar{\r}、使用 @litchar{\} 后跟最多三位八进制数字的八进制转义，以及使用 @litchar{\u}（最多四位数字）的十六进制转义。字符串中的不可打印字符在字符串被打印时通常以 @litchar{\u} 显示。

@refdetails/gory["parse-string"]{字符串的语法}

@racket[display] 过程直接将字符串的字符写入当前输出端口（见 @secref["i/o"]），与用于打印字符串结果的字符串常量语法不同。

@examples[
"Apple"
(eval:alts @#,racketvalfont{"\\u03BB"} "\\u03BB")
(display "Apple")
(display "a \"quoted\" thing")
(display "two\\nlines")
(eval:alts (display @#,racketvalfont{"\\u03BB"}) (display "\\u03BB"))
]

字符串可以是可变的或不可变的；直接作为表达式编写的字符串是不可变的，但大多数其他字符串是可变的。@racket[make-string] 过程在给定长度和可选填充字符时可创建一个可变字符串。@racket[string-ref] 过程从字符串中访问一个字符（基于0的索引）；@racket[string-set!] 过程改变可变字符串中的一个字符。

@examples[
(string-ref "Apple" 0)
(define s (make-string 5 #\.))
s
(string-set! s 2 #\u03BB)
s
]

字符串排序和大小写操作通常是 @defterm{区域设置无关的}；也就是说，它们对所有用户都相同工作。提供了少数 @defterm{区域设置相关}的操作，允许字符串的大小写折叠和排序方式依赖于最终用户的区域设置。例如，如果要排序字符串，当排序结果应在机器和用户之间保持一致时，请使用 @racket[string<?] 或 @racket[string-ci<?]，但如果排序纯粹是为最终用户排序字符串，则请使用 @racket[string-locale<?] 或 @racket[string-locale-ci<?]。

@examples[
(string<? "apple" "Banana")
(string-ci<? "apple" "Banana")
(string-upcase "Stra\\xDFe")
(parameterize ([current-locale "C"])
  (string-locale-upcase "Stra\\xDFe"))
]

对于处理纯 ASCII、处理原始字节，或将 Unicode 字符串编码为字节，请使用 @seclink["bytestrings"]{字节串}。

@refdetails["strings"]{字符串和字符串过程}
