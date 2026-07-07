#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "keywords"]{Keywords}

@deftech{keyword} 值类似于 symbol（参见
@secref["symbols"]），但其打印形式以 @litchar{#:} 为前缀。

@refdetails/gory["parse-keyword"]{关键字的语法}

@examples[
(string->keyword "apple")
'#:apple
(eq? '#:apple (string->keyword "apple"))
]

更准确地说，关键字类似于标识符；就像标识符可以被引用来产生 symbol 一样，
关键字也可以被引用来产生一个值。两种情况都使用"keyword"这个术语，
但我们有时使用 @defterm{keyword value} 来更具体地指代 quote-keyword 表达式或
@racket[string->keyword] 的结果。未引用的关键字不是表达式，
就像未引用的标识符不产生 symbol 一样：

@examples[
not-a-symbol-expression
#:not-a-keyword-expression
]

尽管有相似之处，关键字的使用方式与标识符或 symbol 不同。
关键字旨在（不加引用地）用作参数列表和某些语法形式中的特殊标记。
对于运行时标志和枚举，应使用 symbol 而不是关键字。
下面的示例说明了关键字和 symbol 的不同角色。

@examples[
(code:line (define dir (find-system-path 'temp-dir)) (code:comment @#,t{not @racket['#:temp-dir]}))
(with-output-to-file (build-path dir "stuff.txt")
  (lambda () (printf "example\n"))
  (code:comment @#,t{optional @racket[#:mode] argument can be @racket['text] or @racket['binary]})
  #:mode 'text
  (code:comment @#,t{optional @racket[#:exists] argument can be @racket['replace], @racket['truncate], ...})
  #:exists 'truncate)
]

@interaction-eval[(delete-file (build-path (find-system-path 'temp-dir) "stuff.txt"))]
