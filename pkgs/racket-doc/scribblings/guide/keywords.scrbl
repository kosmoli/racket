#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "keywords"]{Keywords}

@deftech{keyword} 值与 symbol 类似（参见 @secref["symbols"]），
但其打印形式前缀为 @litchar{#:}。

@refdetails/gory["parse-keyword"]{the syntax of keywords}

@examples[
(string->keyword "apple")
'#:apple
(eq? '#:apple (string->keyword "apple"))
]

更准确地说，keyword 类似于 identifier；与 identifier 可以被 quote 以产生 symbol 类似，
keyword 可以被 quote 以产生一个值。在两种情况下都使用相同的术语 "keyword"，
但有时我们使用 @defterm{keyword value} 来更特指 quote-keyword 表达式的结果
或 @racket[string->keyword] 的结果。未 quote 的 keyword 不是表达式，
就像未 quote 的 identifier 不产生 symbol 一样：

@examples[
not-a-symbol-expression
#:not-a-keyword-expression
]

尽管理相似，keyword 的使用方式与 identifier 或 symbol 不同。Keyword 旨在
（未 quote 时）在参数列表和某些特殊形式中用作特殊标记。对于运行时标志和枚举，
使用 symbol 而不是 keyword。下面的例子说明了 keyword 和 symbol 的不同角色。

@examples[
(code:line (define dir (find-system-path 'temp-dir)) (code:comment @#,t{不是 @racket['#:temp-dir]}))
(with-output-to-file (build-path dir "stuff.txt")
  (lambda () (printf "example\n"))
  (code:comment @#,t{可选的 @racket[#:mode] 参数可以是 @racket['text] 或 @racket['binary]})
  #:mode 'text
  (code:comment @#,t{可选的 @racket[#:exists] 参数可以是 @racket['replace], @racket['truncate], ...})
  #:exists 'truncate)
]

@interaction-eval[(delete-file (build-path (find-system-path 'temp-dir) "stuff.txt"))]