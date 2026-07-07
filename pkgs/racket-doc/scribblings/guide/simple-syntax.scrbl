#lang scribble/doc
@(require scribble/manual scribble/eval scribble/bnf "guide-utils.rkt"
          (for-label racket/string))

@(define ex-eval (make-base-eval))
@(ex-eval '(require racket/string))

@title[#:tag "syntax-overview"]{Simple Definitions and Expressions}

程序模块写作

@racketblock[
@#,BNF-seq[@litchar{#lang} @nonterm{langname} @kleenestar{@nonterm{topform}}]
]

其中 @nonterm{topform} 是 @nonterm{definition} 或 @nonterm{expr}。@tech{REPL} 也会对 @nonterm{topform} 求值。

在语法规范中，带灰色背景的文本（如 @litchar{#lang}）表示字面文本。此类字面量与像 @nonterm{id} 这样的非终结符之间必须有空白，但 @litchar{(}、@litchar{)}、@litchar{[} 或 @litchar{]} 前后不需要空白。以 @litchar{;} 开头直到行末的@index["注释"]与空白的处理方式相同。

@refdetails["parse-comment"]{different forms of comments}

按照通常的约定，语法中的 @kleenestar{} 表示前面的元素重复零次或多次，@kleeneplus{} 表示重复一次或多次，@BNF-group{} 将序列作为元素分组以便重复。

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
@section{Definitions}

形式为

@moreguide["define"]{definitions}

@racketblock[@#,val-defn-stx]

的定义将 @nonterm{id} 绑定到 @nonterm{expr} 的结果，而

@racketblock[@#,fun-defn-stx]

的定义将第一个 @nonterm{id} 绑定到一个函数（也称为@defterm{过程}），该函数接受由其余 @nonterm{id} 命名的参数。在函数的情况下，@nonterm{expr} 是函数的主体。当函数被调用时，它返回最后一个 @nonterm{expr} 的结果。

@defexamples[
#:eval ex-eval
(code:line (define pie 3)             (code:comment @#,t{defines @racket[pie] to be @racket[3]}))
(code:line (define (piece str)        (code:comment @#,t{defines @racket[piece] as a function})
             (substring str 0 pie))   (code:comment @#,t{ of one argument}))
pie
(piece "key lime")
]

在底层，函数定义实际上与非函数定义相同，函数名不一定要在函数调用中使用。函数只是另一种值，尽管其打印形式必然不如数字或字符串的打印形式完整。

@examples[
#:eval ex-eval
piece
substring
]

函数定义可以包含多个表达式作为函数主体。在这种情况下，函数被调用时只返回最后一个表达式的值。其他表达式仅为了某些副作用（如打印）而被求值。

@defexamples[
#:eval ex-eval
(define (bake flavor)
  (printf "preheating oven...\n")
  (string-append flavor " pie"))
(bake "apple")
]

Racket 程序员倾向于避免副作用，因此定义通常只有一个表达式作为主体。然而，理解定义主体中允许多个表达式是很重要的，因为它解释了为什么下面的 @racket[nobake] 函数未能将其参数包含在结果中：

@def+int[
#:eval ex-eval
(define (nobake flavor)
  string-append flavor "jello")
(nobake "green")
]

在 @racket[nobake] 中，@racket[string-append flavor "jello"] 周围没有括号，因此它们是三个独立的表达式而不是一个函数调用表达式。表达式 @racket[string-append] 和 @racket[flavor] 被求值，但结果从未被使用。函数的结果只是最终表达式 @racket["jello"] 的结果。

@; ----------------------------------------------------------------------
@section[#:tag "indentation"]{An Aside on Indenting Code}

换行和缩进对于解析 Racket 程序并不重要，但大多数 Racket 程序员使用一套标准约定来使代码更易读。例如，定义的主体通常缩进在定义的第一行之下。标识符紧跟在左括号后面，没有额外的空格，右括号永远不会单独出现在一行。

当你在程序或 @tech{REPL} 表达式中按 Enter 时，DrRacket 会自动按标准样式缩进。例如，如果你在输入 @litchar{(define (greet name)} 后按 Enter，DrRacket 会自动为下一行插入两个空格。如果你更改了代码区域，可以在 DrRacket 中选中它并按 Tab，DrRacket 会重新缩进代码（不插入任何换行）。像 Emacs 这样的编辑器提供具有类似缩进支持的 Racket 或 Scheme 模式。

重新缩进不仅使代码更易读，还给你额外的反馈，确认括号按你预期的方式匹配。例如，如果你在函数的最后一个参数后面遗漏了右括号，自动缩进会使下一行从第一个参数下方开始，而不是从 @racket[define] 关键字下方开始：

@racketblock[
(define (halfbake flavor
                  (string-append flavor " creme brulee")))
]

在这种情况下，缩进有助于突出错误。在其他情况下，当缩进可能正常但左括号没有匹配的右括号时，@exec{racket} 和 DrRacket 都会使用源代码的缩进来建议可能缺少括号的位置。

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{Identifiers}

Racket 的标识符语法特别宽松。排除特殊字符

@moreguide["binding"]{identifiers}

@t{
  @hspace[2] @litchar{(} @litchar{)} @litchar{[} @litchar{]}
  @litchar["{"] @litchar["}"]
  @litchar{"} @litchar{,} @litchar{'} @litchar{`}
  @litchar{;} @litchar{#} @litchar{|} @litchar{\}
}

以及构成数字常量的字符序列外，几乎任何非空白字符序列都构成 @nonterm{id}。例如 @racketid[substring] 是一个标识符。同样，@racketid[string-append] 和 @racketid[a+b] 是标识符，而不是算术表达式。以下是更多示例：

@racketblock[
@#,racketid[+]
@#,racketid[integer?]
@#,racketid[pass/fail]
@#,racketid[Hfuhruhurr&Uumellmahaye]
@#,racketid[john-jacob-jingleheimer-schmidt]
@#,racketid[a-b-c+1-2-3]
]

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{Definitions}

我们已经见过许多函数调用，在更传统的术语中称为@defterm{过程应用}。函数调用的语法是

@moreguide["application"]{function calls}

@racketblock[
#,app-expr-stx
]

其中 @nonterm{expr} 的数量决定了提供给 @nonterm{id} 命名的函数的参数数量。

@racketmodname[racket] 语言预定义了许多函数标识符，如 @racket[substring] 和 @racket[string-append]。更多示例如下。

在文档中的示例 Racket 代码中，预定义名称的使用都链接到参考手册。因此，你可以点击标识符来获取其使用的完整详细信息。

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
@section{Conditionals with @racket[if], @racket[and], @racket[or], and @racket[cond]}

下一种最简单的表达式是 @racket[if] 条件表达式：

@racketblock[
#,if-expr-stx
]

@moreguide["conditionals"]{conditionals}

第一个 @nonterm{expr} 总是被求值。如果它产生非 @racket[#f] 的值，则对第二个 @nonterm{expr} 求值作为整个 @racket[if] 表达式的结果，否则对第三个 @nonterm{expr} 求值作为结果。

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

可以通过嵌套 @racket[if] 表达式来形成复杂的条件。例如，在前面的 @racket[reply] 示例中，输入必须是字符串，因为 @racket[string-prefix?] 在给定非字符串时会报错。你可以通过添加另一个 @racket[if] 来首先检查输入是否为字符串来消除此限制：

@racketblock[
(define (reply-non-string s)
  (if (string? s)
      (if (string-prefix? s "hello ")
          "hi!"
          "huh?")
      "huh?"))
]

与其重复 @racket["huh?"] 的情况，这个函数最好写成

@racketblock[
(define (reply-non-string s)
  (if (if (string? s)
          (string-prefix? s "hello ")
          #f)
      "hi!"
      "huh?"))
]

但这些嵌套的 @racket[if] 难以阅读。Racket 通过 @racket[and] 和 @racket[or] 形式提供了更易读的快捷方式：

@moreguide["and+or"]{@racket[and] and @racket[or]}

@racketblock[
#,and-expr-stx
#,or-expr-stx
]

@racket[and] 形式会短路求值：当某个表达式产生 @racket[#f] 时它停止并返回 @racket[#f]，否则继续执行。@racket[or] 形式类似地在遇到真值时短路求值。

@defexamples[
#:eval ex-eval
(define (reply-non-string s)
  (if (and (string? s) (string-prefix? s "hello "))
      "hi!"
      "huh?"))
(reply-non-string "hello racket")
(reply-non-string 17)
]

请注意，在上面的语法中，@racket[and] 和 @racket[or] 形式可以处理任意数量的表达式。

@defexamples[
#:eval ex-eval
(define (reply-only-enthusiastic s)
  (if (and (string? s)
           (string-prefix? s "hello ")
           (string-suffix? s "!"))
      "hi!"
      "huh?"))
(reply-only-enthusiastic "hello racket!")
(reply-only-enthusiastic "hello racket")
]

另一种常见的嵌套 @racket[if] 模式涉及一系列测试，每个测试有自己的结果：

@racketblock[
(define (reply-more s)
  (if (string-prefix? s "hello ")
      "hi!"
      (if (string-prefix? s "goodbye ")
          "bye!"
          (if (string-suffix? s "?")
              "I don't know"
              "huh?"))))
]

一系列测试的简写是 @racket[cond] 形式：

@moreguide["cond"]{@racket[cond]}

@racketblock[
#,cond-expr-stx
]

@racket[cond] 形式在方括号之间包含一系列子句。在每个子句中，第一个 @nonterm{expr} 是测试表达式。如果它产生真值，则对子句的其余 @nonterm{expr} 求值，子句中的最后一个为整个 @racket[cond] 表达式提供答案；其余子句被忽略。如果测试 @nonterm{expr} 产生 @racket[#f]，则子句的其余 @nonterm{expr} 被忽略，继续对下一个子句求值。最后一个子句可以使用 @racket[else] 作为 @racket[#t] 测试表达式的同义词。

使用 @racket[cond]，@racket[reply-more] 函数可以更清晰地写成：

@def+int[
#:eval ex-eval
(define (reply-more s)
  (cond
   [(string-prefix? s "hello ")
    "hi!"]
   [(string-prefix? s "goodbye ")
    "bye!"]
   [(string-suffix? s "?")
    "I don't know"]
   [else "huh?"]))
(reply-more "hello racket")
(reply-more "goodbye cruel world")
(reply-more "what is your favorite color?")
(reply-more "mine is lime green")
]

使用方括号作为 @racket[cond] 子句是一种约定。在 Racket 中，圆括号和方括号实际上是可互换的，只要 @litchar{(} 与 @litchar{)} 匹配，@litchar{[} 与 @litchar{]} 匹配。在几个关键位置使用方括号使 Racket 代码更加易读。

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{Function Calls, Again}

在我们之前关于函数调用的语法中，我们做了过度简化。函数调用的实际语法允许函数使用任意表达式，而不仅仅是 @nonterm{id}：

@moreguide["application"]{function calls}

@racketblock[
#,app2-expr-stx
]

第一个 @nonterm{expr} 通常是 @nonterm{id}，如 @racket[string-append] 或 @racket[+]，但它可以是任何求值为函数的东西。例如，它可以是一个条件表达式：

@def+int[
(define (double v)
  ((if (string? v) string-append +) v v))
(double "mnah")
(double 5)
]

在语法上，函数调用中的第一个表达式甚至可以是数字——但这会导致错误，因为数字不是函数。

@interaction[(1 2 3 4)]

当你意外省略函数名或在表达式周围使用额外的括号时，你最常会得到像这样的"expected a procedure"错误。

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{Anonymous Functions with @racket[lambda]}

如果必须给所有数字命名，在 Racket 中编程会很乏味。与其写 @racket[(+ 1 2)]，你不得不写

@moreguide["lambda"]{@racket[lambda]}

@interaction[
(define a 1)
(define b 2)
(+ a b)
]

事实证明，给所有函数命名也会很乏味。例如，你可能有一个函数 @racket[twice] 接受一个函数和一个参数。如果你已经有了函数的名称（如 @racket[sqrt]），使用 @racket[twice] 很方便：

@def+int[
#:eval ex-eval
(define (twice f v)
  (f (f v)))
(twice sqrt 16)
]

如果你想调用一个尚未定义的函数，可以先定义它，然后将其传递给 @racket[twice]：

@def+int[
#:eval ex-eval
(define (louder s)
  (string-append s "!"))
(twice louder "hello")
]

但如果对 @racket[twice] 的调用是使用 @racket[louder] 的唯一地方，写一个完整的定义就太可惜了。在 Racket 中，你可以使用 @racket[lambda] 表达式直接产生一个函数。@racket[lambda] 形式后面跟着函数参数的标识符，然后是函数的主体表达式：

@racketblock[
#,lambda-expr-stx
]

单独对 @racket[lambda] 形式求值会产生一个函数：

@interaction[(lambda (s) (string-append s "!"))]

使用 @racket[lambda]，上面的 @racket[twice] 调用可以重写为

@interaction[
#:eval ex-eval
(twice (lambda (s) (string-append s "!"))
       "hello")
(twice (lambda (s) (string-append s "?!"))
       "hello")
]

@racket[lambda] 的另一个用途是作为生成函数的函数的结果：

@def+int[
#:eval ex-eval
(define (make-add-suffix s2)
  (lambda (s) (string-append s s2)))
(twice (make-add-suffix "!") "hello")
(twice (make-add-suffix "?!") "hello")
(twice (make-add-suffix "...") "hello")
]

Racket 是一种@defterm{词法作用域}语言，这意味着 @racket[make-add-suffix] 返回的函数中的 @racket[s2] 始终引用创建该函数的调用的参数。换句话说，@racket[lambda] 生成的函数"记住"了正确的 @racket[s2]：

@interaction[
#:eval ex-eval
(define louder (make-add-suffix "!"))
(define less-sure (make-add-suffix "?"))
(twice less-sure "really")
(twice louder "really")
]

到目前为止，我们将形式为 @racket[(define @#,nonterm{id} @#,nonterm{expr})] 的定义称为"非函数定义"。这种描述是有误导性的，因为 @nonterm{expr} 可能是 @racket[lambda] 形式，在这种情况下，定义等价于使用"函数"定义形式。例如，以下两个 @racket[louder] 的定义是等价的：

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

请注意，第二种情况下 @racket[louder] 的表达式是用 @racket[lambda] 编写的"匿名"函数，但如果可能，编译器会推断一个名称，以使打印和错误报告尽可能提供信息。

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section[#:tag "local-binding-intro"]{Local Binding with
         @racket[define], @racket[let], and @racket[let*]}

是时候撤回我们在 Racket 语法中的另一个简化了。在函数主体中，定义可以出现在主体表达式之前：

@moreguide["intdefs"]{local (internal) definitions}

@racketblock[
#,fun-defn2-stx
#,lambda2-expr-stx
]

函数主体开头的定义对函数主体是局部的。

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

创建局部绑定的另一种方式是 @racket[let] 形式。@racket[let] 的一个优点是它可以在任何表达式位置使用。此外，@racket[let] 可以同时绑定多个标识符，而不需要为每个标识符单独写一个 @racket[define]。

@moreguide["intdefs"]{@racket[let] and @racket[let*]}

@racketblock[
#,let-expr-stx
]

每个绑定子句是一个 @nonterm{id} 和一个用方括号包围的 @nonterm{expr}，子句之后的表达式是 @racket[let] 的主体。在每个子句中，@nonterm{id} 绑定到 @nonterm{expr} 的结果以供主体使用。

@interaction[
(let ([x (random 4)]
      [o (random 4)])
  (cond
    [(> x o) "X wins"]
    [(> o x) "O wins"]
    [else "cat's game"]))
]

@racket[let] 形式的绑定仅在 @racket[let] 的主体中可用，因此绑定子句不能相互引用。相比之下，@racket[let*] 形式允许后续子句使用之前的绑定：

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
