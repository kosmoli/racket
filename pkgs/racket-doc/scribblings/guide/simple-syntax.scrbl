#lang scribble/doc
@(require scribble/manual scribble/eval scribble/bnf "guide-utils.rkt"
          (for-label racket/string))

@(define ex-eval (make-base-eval))
@(ex-eval '(require racket/string))

@title[#:tag "syntax-overview"]{简单定义与表达式}

程序模块的书写形式为

@racketblock[
@#,BNF-seq[@litchar{#lang} @nonterm{langname} @kleenestar{@nonterm{topform}}]
]

其中 @nonterm{topform} 要么是一个 @nonterm{definition}，要么是一个
@nonterm{expr}。@tech{REPL} 也会对 @nonterm{topform} 求值。

在语法规范中，灰色背景的文本（如
@litchar{#lang}）表示字面文本。此类字面量与非终结符（如 @nonterm{id}）之间必须出现
空白字符，但在 @litchar{(}、
@litchar{)}、@litchar{[} 或 @litchar{]} 之前或之后则不要求空白。
@index['("comments")]{注释}以 @litchar{;} 开头，直到行末结束，其处理方式
与空白字符相同。

@refdetails["parse-comment"]{注释的不同形式}

按照通常的约定，文法中的 @kleenestar{} 表示对前一元素的零次或多次重复，
@kleeneplus{} 表示对前一元素的一次或多次重复，@BNF-group{} 则将序列分组
作为一个可重复的元素。

@(define val-defn-stx
   @BNF-seq[@litchar{(}@litchar{define} @nonterm{id} @nonterm{expr} @litchar{)}])
@(define fun-defn-stx
   @BNF-seq[@litchar{(}@litchar{define} @litchar{(} @nonterm{id} @kleenestar{@nonterm{id}} @litchar{)}
                  @kleeneplus{@nonterm{expr}} @litchar{)}])
@(define fun-defn2-stx
   @BNF-seq[@litchar{(}@litchar{define} @litchar{(} @nonterm{id} @kleenestar{@nonterm{id}} @litchar{)}
            @kleenestar{@nonterm{definition}} @kleeneplus{@nonterm{expr}} @litchar{)}])
@(define app-expr-stx @BNF-seq[@litchar{(} @nonterm{id} @kleenestar{@nonterm{expr}} @litchar{)}])
@(define app2-expr-stx @BNF-seq[@litchar{(} @nonterm{expr} @kleenestar{@nonterm{expr}} @litchar{)}])
@(define if-expr-stx @BNF-seq[@litchar{(} @litchar{if} @nonterm{expr} @nonterm{expr} @nonterm{expr} @litchar{)}])

@(define lambda-expr-stx @BNF-seq[@litchar{(} @litchar{lambda} @litchar{(} @kleenestar{@nonterm{id}} @litchar{)}
                                              @kleeneplus{@nonterm{expr}} @litchar{)}])
@(define lambda2-expr-stx
   @BNF-seq[@litchar{(} @litchar{lambda} @litchar{(} @kleenestar{@nonterm{id}} @litchar{)}
            @kleenestar{@nonterm{definition}} @kleeneplus{@nonterm{expr}} @litchar{)}])
@(define and-expr-stx @BNF-seq[@litchar{(} @litchar{and} @kleenestar{@nonterm{expr}} @litchar{)}])
@(define or-expr-stx @BNF-seq[@litchar{(} @litchar{or} @kleenestar{@nonterm{expr}} @litchar{)}])
@(define cond-expr-stx @BNF-seq[@litchar{(} @litchar{cond}
                                @kleenestar{@BNF-group[@litchar{[} @nonterm{expr} @kleenestar{@nonterm{expr}} @litchar{]}]}
                                @litchar{)}])
@(define (make-let-expr-stx kw)
   @BNF-seq[@litchar{(} kw @litchar{(}
            @kleenestar{@BNF-group[@litchar{[} @nonterm{id} @nonterm{expr} @litchar{]}]}
            @litchar{)}
            @kleeneplus{@nonterm{expr}} @litchar{)}])
@(define let-expr-stx (make-let-expr-stx @litchar{let}))
@(define let*-expr-stx (make-let-expr-stx @litchar{let*}))

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{定义}

形式为

@moreguide["define"]{定义}

@racketblock[@#,val-defn-stx]

的定义将 @nonterm{id} 与 @nonterm{expr} 的求值结果绑定，而

@racketblock[@#,fun-defn-stx]

则将第一个 @nonterm{id} 绑定到一个函数（也称为
@defterm{procedure}），其参数由其余的 @nonterm{id} 命名。在函数定义中，
@nonterm{expr} 构成了函数体。当调用函数时，返回的结果是最后一个
@nonterm{expr} 的求值结果。

@defexamples[
#:eval ex-eval
(code:line (define pie 3)             (code:comment @#,t{defines @racket[pie] to be @racket[3]}))
(code:line (define (piece str)        (code:comment @#,t{defines @racket[piece] as a function})
             (substring str 0 pie))   (code:comment @#,t{ of one argument}))
pie
(piece "key lime")
]

在实际实现中，函数定义与非函数定义本质上是相同的，函数名也不一定
要在函数调用中使用。函数只是另一种类型的值，
只不过其打印形式必然不如数字或字符串的打印形式完整。

@examples[
#:eval ex-eval
piece
substring
]

函数定义可以为函数体包含多个表达式。在这种情况下，调用函数时
仅返回最后一个表达式的值。其他表达式仅因某些副作用（如打印）而被求值。

@defexamples[
#:eval ex-eval
(define (bake flavor)
  (printf "preheating oven...\n")
  (string-append flavor " pie"))
(bake "apple")
]

Racket 程序员倾向于避免副作用，因此定义通常
在函数体内只有一个表达式。然而，重要的是要理解
定义体内允许多个表达式，因为这解释了为什么以下
@racket[nobake] 函数未能将其参数包含在结果中：

@def+int[
#:eval ex-eval
(define (nobake flavor)
  string-append flavor "jello")
(nobake "green")
]

在 @racket[nobake] 内部，没有括号围绕
@racket[string-append flavor "jello"]，因此它们是三个独立的
表达式，而不是一个函数调用表达式。表达式
@racket[string-append] 和 @racket[flavor] 会被求值，但其
结果从未被使用。相反，最终函数的结果只是
最后一个表达式 @racket["jello"] 的结果。

@; ----------------------------------------------------------------------
@section[#:tag "indentation"]{关于代码缩进的附带说明}

换行和缩进对于解析 Racket 程序并不重要，但大多数 Racket
程序员使用一套标准约定使代码更具可读性。例如，定义的函数体
通常在定义的第一行下方缩进标识符紧接在左括号后书写，
不带额外空格，且右括号永远不会单独占一行。

当你在程序或 @tech{REPL} 表达式中按下回车键时，DrRacket 会根据标准样式
自动缩进。例如，如果你在输入 @litchar{(define (greet name)} 后按下回车，
DrRacket 会自动插入两个空格以缩进下一行。如果你更改了一段代码，
可以在 DrRacket 中选择它并按下 Tab 键，DrRacket 将重新缩进代码
（不插入任何换行符）。Emacs 等编辑器提供具有类似缩进支持的 Racket
或 Scheme 模式

重新缩进不仅使代码更易阅读，还提供了额外的反馈，
表明括号是否按预期匹配。例如，如果在函数的最后一个参数后遗漏了右括号，
自动缩进会将下一行缩进到第一个参数下方，而不是 @racket[define] 关键字下方：

@racketblock[
(define (halfbake flavor
                  (string-append flavor " creme brulee")))
]

在这种情况下，缩进有助于突出错误。在其他情况下，
当缩进可能正常但左括号没有匹配的右括号时，
@exec{racket} 和 DrRacket 都会利用源代码的缩进
来提示可能缺少括号的位置。

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{标识符}

Racket 的标识符语法特别自由。除特殊字符外，

@moreguide["binding"]{标识符}

@t{
  @hspace[2] @litchar{(} @litchar{)} @litchar{[} @litchar{]}
  @litchar["{"] @litchar["}"]
  @litchar{"} @litchar{,} @litchar{'} @litchar{`}
  @litchar{;} @litchar{#} @litchar{|} @litchar{\}
}

以及构成数字常量的字符序列外，
几乎任何非空白字符序列都构成一个 @nonterm{id}。例如 @racketid[substring] 是一个
标识符。同样，@racketid[string-append] 和 @racketid[a+b] 也是
标识符，而非算术表达式。以下是更多示例：

@racketblock[
@#,racketid[+]
@#,racketid[integer?]
@#,racketid[pass/fail]
@#,racketid[Hfuhruhurr&Uumellmahaye]
@#,racketid[john-jacob-jingleheimer-schmidt]
@#,racketid[a-b-c+1-2-3]
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{函数调用@aux-elem{ (Procedure Applications)}}

我们已经看到了很多函数调用，在更传统的术语中
称为 @defterm{procedure applications}。函数调用的语法是

@moreguide["application"]{函数调用}

@racketblock[
#,app-expr-stx
]

其中 @nonterm{expr} 的数量决定了提供给由 @nonterm{id} 命名的函数的参数数量。

@racketmodname[racket] 语言预定义了许多函数标识符，
如 @racket[substring] 和 @racket[string-append]。更多示例见下文。

在文档中的示例 Racket 代码中，预定义的名称使用
会超链接到参考手册。因此，您可以点击标识符以获取有关其使用的完整详细信息。

@interaction[
#:eval ex-eval
(code:line (string-append "rope" "twine" "yarn")  (code:comment @#,t{append strings}))
(code:line (substring "corduroys" 0 4)            (code:comment @#,t{extract a substring}))
(code:line (string-prefix? "shoelace" "shoe")     (code:comment @#,t{recognize string prefix/suffix}))
(string-suffix? "shoelace" "shoe")
(code:line (string? "Ceci n'est pas une string.") (code:comment @#,t{recognize strings}))
(string? 1)
(code:line (sqrt 16)                              (code:comment @#,t{find a square root}))
(sqrt -16)
(code:line (+ 1 2)                                (code:comment @#,t{add numbers}))
(code:line (- 2 1)                                (code:comment @#,t{subtract numbers}))
(code:line (< 2 1)                                (code:comment @#,t{compare numbers}))
(>= 2 1)
(code:line (number? "c'est une number")           (code:comment @#,t{recognize numbers}))
(number? 1)
(code:line (equal? 6 "half dozen")                (code:comment @#,t{compare anything}))
(equal? 6 6)
(equal? "half dozen" "half dozen")
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{使用 @racket[if]、@racket[and]、@racket[or] 和 @racket[cond] 的条件表达式}

下一种最简单的表达式是 @racket[if] 条件表达式：

@racketblock[
#,if-expr-stx
]

@moreguide["conditionals"]{条件表达式}

总是对第一个 @nonterm{expr} 求值。如果它产生一个
非 @racket[#f] 的值，则对第二个 @nonterm{expr} 求值以作为整个
@racket[if] 表达式的结果，否则对第三个 @nonterm{expr} 求值

@examples[
(if (> 2 3)
    "2 is bigger than 3"
    "2 is smaller than 3")
]

@def+int[
#:eval ex-eval
(define (reply s)
  (if (string-prefix? s "hello ")
      "hi!"
      "huh?"))
(reply "hello racket")
(reply "\u03BBx:(\u03BC\u03B1.\u03B1\u2192\u03B1).xx")
]

通过嵌套 @racket[if] 表达式可以构成复杂的条件表达式。例如，在前面的 @racket[reply]
示例中，输入必须是一个字符串，因为 @racket[string-prefix?]
在非字符串输入时会出错。你可以通过添加另一个 @racket[if] 来首先检查输入是否为字符串来移除此限制：

@racketblock[
(define (reply-non-string s)
  (if (string? s)
      (if (string-prefix? s "hello ")
          "hi!"
          "huh?")
      "huh?"))
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{标识符}

Racket 的标识符语法特别自由。除特殊字符外，

@moreguide["binding"]{标识符}

@t{
  @hspace[2] @litchar{(} @litchar{)} @litchar{[} @litchar{]}
  @litchar["{"] @litchar["}"]
  @litchar{"} @litchar{,} @litchar{'} @litchar{`}
  @litchar{;} @litchar{#} @litchar{|} @litchar{\}
}

以及构成数字常量的字符序列外，
几乎任何非空白字符序列都构成一个 @nonterm{id}。例如 @racketid[substring] 是一个
标识符。同样，@racketid[string-append] 和 @racketid[a+b] 也是
标识符，而非算术表达式。以下是更多示例：

@racketblock[
@#,racketid[+]
@#,racketid[integer?]
@#,racketid[pass/fail]
@#,racketid[Hfuhruhurr&Uumellmahaye]
@#,racketid[john-jacob-jingleheimer-schmidt]
@#,racketid[a-b-c+1-2-3]
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{函数调用@aux-elem{ (Procedure Applications)}}

我们已经看到了很多函数调用，在更传统的术语中
称为 @defterm{procedure applications}。函数调用的语法是

@moreguide["application"]{函数调用}

@racketblock[
#,app-expr-stx
]

其中 @nonterm{expr} 的数量决定了提供给由 @nonterm{id} 命名的函数的参数数量。

@racketmodname[racket] 语言预定义了许多函数标识符，
如 @racket[substring] 和 @racket[string-append]。更多示例见下文。

在文档中的示例 Racket 代码中，预定义的名称使用
会超链接到参考手册。因此，您可以点击标识符以获取有关其使用的完整详细信息。

@interaction[
#:eval ex-eval
(code:line (string-append "rope" "twine" "yarn")  (code:comment @#,t{append strings}))
(code:line (substring "corduroys" 0 4)            (code:comment @#,t{extract a substring}))
(code:line (string-prefix? "shoelace" "shoe")     (code:comment @#,t{recognize string prefix/suffix}))
(string-suffix? "shoelace" "shoe")
(code:line (string? "Ceci n'est pas une string.") (code:comment @#,t{recognize strings}))
(string? 1)
(code:line (sqrt 16)                              (code:comment @#,t{find a square root}))
(sqrt -16)
(code:line (+ 1 2)                                (code:comment @#,t{add numbers}))
(code:line (- 2 1)                                (code:comment @#,t{subtract numbers}))
(code:line (< 2 1)                                (code:comment @#,t{compare numbers}))
(>= 2 1)
(code:line (number? "c'est une number")           (code:comment @#,t{recognize numbers}))
(number? 1)
(code:line (equal? 6 "half dozen")                (code:comment @#,t{compare anything}))
(equal? 6 6)
(equal? "half dozen" "half dozen")
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{使用 @racket[if]、@racket[and]、@racket[or] 和 @racket[cond] 的条件表达式}

下一种最简单的表达式是 @racket[if] 条件表达式：

@racketblock[
#,if-expr-stx
]

@moreguide["conditionals"]{条件表达式}

总是对第一个 @nonterm{expr} 求值。如果它产生一个
非 @racket[#f] 的值，则对第二个 @nonterm{expr} 求值以作为整个
@racket[if] 表达式的结果，否则对第三个 @nonterm{expr} 求值

@examples[
(if (> 2 3)
    "2 is bigger than 3"
    "2 is smaller than 3")
]

@def+int[
#:eval ex-eval
(define (reply s)
  (if (string-prefix? s "hello ")
      "hi!"
      "huh?"))
(reply "hello racket")
(reply "\u03BBx:(\u03BC\u03B1.\u03B1\u2192\u03B1).xx")
]

通过嵌套 @racket[if] 表达式可以构成复杂的条件表达式。例如，在前面的 @racket[reply]
示例中，输入必须是一个字符串，因为 @racket[string-prefix?]
在非字符串输入时会出错。你可以通过添加另一个 @racket[if] 来首先检查输入是否为字符串来移除此限制：

@racketblock[
(define (reply-non-string s)
  (if (string? s)
      (if (string-prefix? s "hello ")
          "hi!"
          "huh?")
      "huh?"))
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{标识符}

Racket 的标识符语法特别自由。除特殊字符外，

@moreguide["binding"]{标识符}

@t{
  @hspace[2] @litchar{(} @litchar{)} @litchar{[} @litchar{]}
  @litchar["{"] @litchar["}"]
  @litchar{"} @litchar{,} @litchar{'} @litchar{`}
  @litchar{;} @litchar{#} @litchar{|} @litchar{\}
}

以及构成数字常量的字符序列外，
几乎任何非空白字符序列都构成一个 @nonterm{id}。例如 @racketid[substring] 是一个
标识符。同样，@racketid[string-append] 和 @racketid[a+b] 也是
标识符，而非算术表达式。以下是更多示例：

@racketblock[
@#,racketid[+]
@#,racketid[integer?]
@#,racketid[pass/fail]
@#,racketid[Hfuhruhurr&Uumellmahaye]
@#,racketid[john-jacob-jingleheimer-schmidt]
@#,racketid[a-b-c+1-2-3]
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{函数调用@aux-elem{ (Procedure Applications)}}

我们已经看到了很多函数调用，在更传统的术语中
称为 @defterm{procedure applications}。函数调用的语法是

@moreguide["application"]{函数调用}

@racketblock[
#,app-expr-stx
]

其中 @nonterm{expr} 的数量决定了提供给由 @nonterm{id} 命名的函数的参数数量。

@racketmodname[racket] 语言预定义了许多函数标识符，
如 @racket[substring] 和 @racket[string-append]。更多示例见下文。

在文档中的示例 Racket 代码中，预定义的名称使用
会超链接到参考手册。因此，您可以点击标识符以获取有关其使用的完整详细信息。

@interaction[
#:eval ex-eval
(code:line (string-append "rope" "twine" "yarn")  (code:comment @#,t{append strings}))
(code:line (substring "corduroys" 0 4)            (code:comment @#,t{extract a substring}))
(code:line (string-prefix? "shoelace" "shoe")     (code:comment @#,t{recognize string prefix/suffix}))
(string-suffix? "shoelace" "shoe")
(code:line (string? "Ceci n'est pas une string.") (code:comment @#,t{recognize strings}))
(string? 1)
(code:line (sqrt 16)                              (code:comment @#,t{find a square root}))
(sqrt -16)
(code:line (+ 1 2)                                (code:comment @#,t{add numbers}))
(code:line (- 2 1)                                (code:comment @#,t{subtract numbers}))
(code:line (< 2 1)                                (code:comment @#,t{compare numbers}))
(>= 2 1)
(code:line (number? "c'est une number")           (code:comment @#,t{recognize numbers}))
(number? 1)
(code:line (equal? 6 "half dozen")                (code:comment @#,t{compare anything}))
(equal? 6 6)
(equal? "half dozen" "half dozen")
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{使用 @racket[if]、@racket[and]、@racket[or] 和 @racket[cond] 的条件表达式}

下一种最简单的表达式是 @racket[if] 条件表达式：

@racketblock[
#,if-expr-stx
]

@moreguide["conditionals"]{条件表达式}

总是对第一个 @nonterm{expr} 求值。如果它产生一个
非 @racket[#f] 的值，则对第二个 @nonterm{expr} 求值以作为整个
@racket[if] 表达式的结果，否则对第三个 @nonterm{expr} 求值

@examples[
(if (> 2 3)
    "2 is bigger than 3"
    "2 is smaller than 3")
]

@def+int[
#:eval ex-eval
(define (reply s)
  (if (string-prefix? s "hello ")
      "hi!"
      "huh?"))
(reply "hello racket")
(reply "\u03BBx:(\u03BC\u03B1.\u03B1\u2192\u03B1).xx")
]

通过嵌套 @racket[if] 表达式可以构成复杂的条件表达式。例如，在前面的 @racket[reply]
示例中，输入必须是一个字符串，因为 @racket[string-prefix?]
在非字符串输入时会出错。你可以通过添加另一个 @racket[if] 来首先检查输入是否为字符串来移除此限制：

@racketblock[
(define (reply-non-string s)
  (if (string? s)
      (if (string-prefix? s "hello ")
          "hi!"
          "huh?")
      "huh?"))
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{匿名函数与 @racket[lambda]}

如果必须为所有数字命名，编程将会很繁琐。
你将不得不写

@moreguide["lambda"]{@racket[lambda]}

@interaction[
(define a 1)
(define b 2)
(+ a b)
]

如果必须为所有函数命名，同样会很繁琐
例如，你可能有一个 @racket[twice] 函数，它接受
一个函数和一个参数。如果已经有一个命名的函数（如
@racket[sqrt]），使用 @racket[twice] 是方便的：

@def+int[
#:eval ex-eval
(define (twice f v)
  (f (f v)))
(twice sqrt 16)
]

如果你想调用一个尚未定义的函数，你可以
先定义它，然后传给 @racket[twice]：

@def+int[
#:eval ex-eval
(define (louder s)
  (string-append s "!"))
(twice louder "hello")
]

但是，如果对 @racket[twice] 的调用是 @racket[louder] 唯一被使用的地方，
那么必须写一个完整的定义就很可惜了。在 Racket 中，你可以使用
@racket[lambda] 表达式来直接生成函数。@racket[lambda] 的形式后跟
函数参数的标识符，然后是函数体的表达式：

@racketblock[
#,lambda-expr-stx
]

对 @racket[lambda] 形式本身求值就会产生一个函数：

@interaction[(lambda (s) (string-append s "!"))]

使用 @racket[lambda]，上述对 @racket[twice] 的调用可以
重写为

@interaction[
#:eval ex-eval
(twice (lambda (s) (string-append s "!"))
       "hello")
(twice (lambda (s) (string-append s "?!"))
       "hello")
]

@racket[lambda] 的另一个用途是作为生成函数的函数的
结果：

@def+int[
#:eval ex-eval
(define (make-add-suffix s2)
  (lambda (s) (string-append s s2)))
(twice (make-add-suffix "!") "hello")
(twice (make-add-suffix "?!") "hello")
(twice (make-add-suffix "...") "hello")
]

Racket 是一种 @defterm{lexically scoped} 语言，这意味着
由 @racket[make-add-suffix] 返回的函数中的 @racket[s2]
始终指向创建该函数的调用所用的参数。换句话说，
@racket[lambda] 生成的函数"记住"了正确的 @racket[s2]：

@interaction[
#:eval ex-eval
(define louder (make-add-suffix "!"))
(define less-sure (make-add-suffix "?"))
(twice less-sure "really")
(twice louder "really")
]

到目前为止，我们一直将形式为 @racket[(define
@#,nonterm{id} @#,nonterm{expr})] 的定义称为"非函数
定义"。这种描述具有误导性，因为 @nonterm{expr} 可以是一个
@racket[lambda] 形式，此时该定义等价于使用"函数"
定义形式。例如，以下 @racket[louder] 的两个定义是
等价的：

@defs+int[
#:eval ex-eval
[(define (louder s)
   (string-append s "!"))
 code:blank
 (define louder
   (lambda (s)
     (string-append s "!")))]
louder
]

请注意，在第二种情况下，@racket[louder] 的表达式是一个用 @racket[lambda] 
书写的"匿名"函数，但如果可能的话，编译器会推断出一个名称，以使打印和错误报告尽可能信息丰富。

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section[#:tag "local-binding-intro"]{使用 @racket[define]、@racket[let] 和 @racket[let*] 的局部绑定}

是时候收回我们 Racket 文法中的另一个简化了。在函数体中，
定义可以出现在函数体表达式之前：

@moreguide["intdefs"]{局部（内部）定义}

@racketblock[
#,fun-defn2-stx
#,lambda2-expr-stx
]

出现在函数体开头的定义是局部的，仅限于该
函数体。

@defexamples[
#:eval ex-eval
(define (converse s)
  (define (starts? s2) (code:comment @#,t{local to @racket[converse]})
    (define spaced-s2 (string-append s2 " ")) (code:comment @#,t{local to @racket[starts?]})
    (string-prefix? s spaced-s2))
  (cond
    [(starts? "hello") "hi!"]
    [(starts? "goodbye") "bye!"]
    [else "huh?"]))
(converse "hello world")
(converse "hellonearth")
(converse "goodbye friends")
(converse "urp")
(eval:alts (code:line starts? (code:comment @#,t{outside of @racket[converse], so...}))
           (parameterize ([current-namespace (make-base-namespace)]) (eval 'starts?)))
]

创建局部绑定的另一种方式是 @racket[let] 形式。
@racket[let] 的优点是它可以在任何表达式位置使用。此外，
@racket[let] 一次性绑定多个标识符，而不需要为每个标识符单独使用 @racket[define]。

@moreguide["intdefs"]{@racket[let] and @racket[let*]}

@racketblock[
#,let-expr-stx
]

每个绑定子句是一个由方括号包围的 @nonterm{id} 和
@nonterm{expr}，子句后的表达式是 @racket[let] 的函数体。在
每个子句中，@nonterm{id} 被绑定到 @nonterm{expr} 的结果，
以供函数体使用。

@interaction[
(let ([x (random 4)]
      [o (random 4)])
  (cond
    [(> x o) "X wins"]
    [(> o x) "O wins"]
    [else "cat's game"]))
]

@racket[let] 形式的绑定仅在 @racket[let] 的函数体内可用，
因此绑定子句不能相互引用。相比之下，
@racket[let*] 形式允许后面的子句使用前面的绑定：

@interaction[
(let* ([x (random 4)]
       [o (random 4)]
       [diff (number->string (abs (- x o)))])
  (cond
    [(> x o) (string-append "X wins by " diff)]
    [(> o x) (string-append "O wins by " diff)]
    [else "cat's game"]))
]

@; ----------------------------------------------------------------------

@close-eval[ex-eval]
