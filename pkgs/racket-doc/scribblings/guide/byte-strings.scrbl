#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "bytestring"]{字节和字节串}

@deftech{字节}是在 @racket[0] 和 @racket[255]（含）之间的一个精确整数。@racket[byte?] 谓词识别表示字节的数字。

@examples[
(byte? 0)
(byte? 256)
]

@deftech{字节串}类似于字符串——见 @secref["strings"]——但其内容是一系列字符而不是字符。字节串可用于处理纯 ASCII 而非 Unicode 文本的应用程序。字节串的打印形式特别支持此类用途，因为字节串的打印形式类似于字节串的 ASCII 解码，但前缀为 @litchar{#}。字节串中不可打印的 ASCII 字符或非 ASCII 字节以八进制表示法书写。

@refdetails/gory["parse-string"]{字节串的语法}

@examples[
#"Apple"
(bytes-ref #"Apple" 0)
(make-bytes 3 65)
(define b (make-bytes 2 0))
b
(bytes-set! b 0 1)
(bytes-set! b 1 255)
b
]

@racket[display] 的字节串形式将其原始字节写入当前输出端口（见 @secref["i/o"]）。从技术上讲，普通（即字符）字符串的 @racket[display] 将字符串的 UTF-8 编码打印到当前输出端口，因为输出最终是用字节来定义的；而字节串的 @racket[display] 在不编码的情况下写入原始字节。同理，当本文档显示输出时，技术上显示的是输出的 UTF-8 解码形式。

@examples[
(display #"Apple")
(eval:alts (code:line (display @#,racketvalfont{"\\316\\273"})  (code:comment @#,t{与 @racket["\\316\\273"] 相同}))
           (display "\\316\\273"))
(code:line (display #"\\316\\273") (code:comment @#,t{@elem["\\u03BB"] 的 UTF-8 编码}))
]

为了在字符串和字节串之间进行显式转换，Racket 直接支持三种编码：UTF-8、Latin-1 和当前区域设置的编码。用于字节到字节转换（特别是与 UTF-8 之间的转换）的通用设施填补了支持任意字符串编码的空白。

@examples[
(bytes->string/utf-8 #"\\316\\273")
(bytes->string/latin-1 #"\\316\\273")
(code:line
 (parameterize ([current-locale "C"])  (code:comment @#,elem{C 区域设置支持 ASCII，})
   (bytes->string/locale #"\\316\\273")) (code:comment @#,elem{仅此而已，所以...}))
(let ([cvt (bytes-open-converter "cp1253" (code:comment @#,elem{希腊代码页})
                                 "UTF-8")]
      [dest (make-bytes 2)])
  (bytes-convert cvt #"\\353" 0 1 dest)
  (bytes-close-converter cvt)
  (bytes->string/utf-8 dest))
]

@refdetails["bytestrings"]{字节串和字节串过程}
