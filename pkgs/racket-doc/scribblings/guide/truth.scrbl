#lang scribble/doc
@(require scribble/manual scribble/eval racket/list "guide-utils.rkt"

          (for-label racket/list
                     (only-in racket/class is-a?)))

@(define list-eval (make-base-eval))
@(interaction-eval #:eval list-eval (require racket/list))

@title{Pairs, Lists, and Racket Syntax}

@racket[cons] 函数实际上接受任意两个值，而不仅仅是列表作为第二个参数。当第二个参数不是 @racket[empty] 且不是由 @racket[cons] 本身产生的时候，结果会以特殊的方式打印。用 @racket[cons] 连接的两个值打印在括号之间，中间用一个点（即被空白包围的句号）分隔：

@interaction[(cons 1 2) (cons "banana" "split")]

因此，由 @racket[cons] 产生的值并不总是列表。一般来说，@racket[cons] 的结果是一个@defterm{pair}。@racket[cons?] 函数更传统的名称是 @racket[pair?]，从现在起我们将使用传统名称。

对于非列表 pair，@racket[rest] 这个名称也不太有意义；@racket[first] 和 @racket[rest] 更传统的名称分别是 @racket[car] 和 @racket[cdr]。（当然，传统名称也是无意义的。只需记住 ``a'' 在 ``d'' 之前，@racket[cdr] 发音为 ``could-er''。）

@examples[
#:eval list-eval
(car (cons 1 2))
(cdr (cons 1 2))
(pair? empty)
(pair? (cons 1 2))
(pair? (list 1 2 3))
]

@close-eval[list-eval]

Racket 的 pair 数据类型及其与列表的关系本质上是一种历史遗留，包括用于打印的点记法和奇怪的名称 @racket[car] 和 @racket[cdr]。然而，pair 深深嵌入了 Racket 的文化、规范和实现中，因此它们在语言中得以保留。

你最可能在犯错误时遇到非列表 pair，比如意外地反转了 @racket[cons] 的参数：

@interaction[(cons (list 2 3) 1) (cons 1 (list 2 3))]

非列表 pair 有时会被有意使用。例如，@racket[make-hash] 函数接受一个 pair 列表，其中每个 pair 的 @racket[car] 是键，@racket[cdr] 是任意值。

对新手来说，比非列表 pair 更令人困惑的是第二个元素@italic{是} pair 但@italic{不是}列表的 pair 的打印约定：

@interaction[(cons 0 (cons 1 2))]

一般来说，pair 的打印规则如下：使用点记法，除非点后面紧跟一个左括号。在这种情况下，删除点、左括号和匹配的右括号。因此，@racketresultfont[#:decode? #f]{'(0 . (1 . 2))} 变成 @racketresult['(0 1 . 2)]，@racketresultfont[#:decode? #f]{'(1 . (2 . (3 . ())))} 变成 @racketresult['(1 2 3)]。

@;------------------------------------------------------------------------
@section[#:tag "quoting-lists"]{Quoting Pairs and Symbols with @racket[quote]}

列表打印时前面有一个引号，但如果列表的元素本身是列表，则内层列表不会打印引号：

@interaction[
(list (list 1) (list 2 3) (list 4))
]

特别是对于嵌套列表，@racket[quote] 形式让你可以按照列表打印的方式将列表写成表达式：

@interaction[
(eval:alts (@#,racket[quote] ("red" "green" "blue")) '("red" "green" "blue"))
(eval:alts (@#,racket[quote] ((1) (2 3) (4))) '((1) (2 3) (4)))
(eval:alts (@#,racket[quote] ()) '())
]

@racket[quote] 形式也适用于点记法，无论引用的形式是否经过点-括号消除规则的规范化：

@interaction[
(eval:alts (@#,racket[quote] (1 . 2)) '(1 . 2))
(eval:alts (@#,racket[quote] (0 @#,racketparenfont{.} (1 . 2))) '(0 . (1 . 2)))
]

当然，任何类型的列表都可以嵌套：

@interaction[
(list (list 1 2 3) 5 (list "a" "b" "c"))
(eval:alts (@#,racket[quote] ((1 2 3) 5 ("a" "b" "c"))) '((1 2 3) 5 ("a" "b" "c")))
]

如果你用 @racket[quote] 包装一个标识符，你会得到看起来像标识符但带有 @litchar{'} 前缀的输出：

@interaction[
(eval:alts (@#,racket[quote] jane-doe) 'jane-doe)
]

打印出来像引用标识符的值是一个@defterm{符号}。就像带括号的输出不应与表达式混淆一样，打印的符号也不应与标识符混淆。特别是，符号 @racket[(@#,racket[quote] @#,racketidfont{map})] 与 @racketidfont{map} 标识符或绑定到 @racket[map] 的预定义函数无关，只是符号和标识符恰好由相同的字母组成。

实际上，符号的内在价值不过是其字符内容。在这个意义上，符号和字符串几乎是同一种东西，主要区别在于它们的打印方式。函数 @racket[symbol->string] 和 @racket[string->symbol] 在它们之间进行转换。

@examples[
map
(eval:alts (@#,racket[quote] @#,racketidfont{map}) 'map)
(eval:alts (symbol? (@#,racket[quote] @#,racketidfont{map})) (symbol? 'map))
(symbol? map)
(procedure? map)
(string->symbol "map")
(eval:alts (symbol->string (@#,racket[quote] @#,racketidfont{map})) (symbol->string 'map))
]

正如列表的 @racket[quote] 会自动应用于嵌套列表一样，对括号包围的标识符序列使用 @racket[quote] 会自动应用于标识符以创建符号列表：

@interaction[
(eval:alts (car (@#,racket[quote] (@#,racketidfont{road} @#,racketidfont{map}))) (car '(road map)))
(eval:alts (symbol? (car (@#,racket[quote] (@#,racketidfont{road} @#,racketidfont{map})))) (symbol? (car '(road map))))
]

当符号在用 @litchar{'} 打印的列表内部时，符号上的 @litchar{'} 被省略，因为 @litchar{'} 已经完成了这项工作：

@interaction[
(eval:alts (@#,racket[quote] (@#,racketidfont{road} @#,racketidfont{map})) '(road map))
]

@racket[quote] 形式对字面表达式（如数字或字符串）没有影响：

@interaction[
(eval:alts (@#,racket[quote] 42) 42)
(eval:alts (@#,racket[quote] "on the record") "on the record")
]

@;------------------------------------------------------------------------
@section{Abbreviating @racket[quote] with @racketvalfont{@literal{'}}}

你可能已经猜到，你可以在要引用的形式前面放 @litchar{'} 来缩写 @racket[quote] 的使用：

@interaction[
'(1 2 3)
'road
'((1 2 3) road ("a" "b" "c"))
]

在文档中，表达式内的 @litchar{'} 与其后面的形式一起以绿色打印，因为该组合是一个常量表达式。在 DrRacket 中，只有 @litchar{'} 被着色为绿色。DrRacket 更加精确，因为 @racket[quote] 的含义可能因表达式的上下文而异。然而在文档中，我们通常假设标准绑定在作用域内，因此我们将引用的形式涂成绿色以增加清晰度。

@litchar{'} 以非常字面的方式展开为 @racket[quote] 形式。你可以在一个已经有 @litchar{'} 的形式前面放 @litchar{'} 来验证这一点：

@interaction[
(car ''road)
(eval:alts (car '(@#,racketvalfont{quote} @#,racketvalfont{road})) 'quote)
]

@litchar{'} 简写在输出和输入中都有效。@tech{REPL} 的打印器在打印输出时识别符号 @racket['quote] 作为双元素列表的第一个元素，在这种情况下使用 @racketidfont{'} 来打印输出：

@interaction[
(eval:alts (@#,racket[quote] (@#,racketvalfont{quote} @#,racketvalfont{road})) ''road)
(eval:alts '(@#,racketvalfont{quote} @#,racketvalfont{road}) ''road)
''road
]

@; FIXME:
@; warning about how "quote" creates constant data, which is subtly
@; different than what "list" creates

@;------------------------------------------------------------------------
@section[#:tag "lists-and-syntax"]{Lists and Racket Syntax}

既然你已经了解了 pair 和列表的真相，并且已经见过了 @racket[quote]，你已经准备好理解我们一直在简化 Racket 真正语法的主要方式。

Racket 的语法不是直接根据字符流定义的。相反，语法由两层决定：

@itemize[

 @item{@deftech{读取器}层，它将字符序列转换为列表、符号和其他常量；}

 @item{@deftech{展开器}层，它处理列表、符号和其他常量以将其解析为表达式。}

]

打印和读取的规则是相辅相成的。例如，列表用括号打印，读取一对括号会产生列表。类似地，非列表 pair 用点记法打印，输入中的点有效地反向执行点记法规则以获得 pair。

读取层对表达式的一个后果是你可以在非引用形式的表达式中使用点记法：

@interaction[
(eval:alts (+ 1 . @#,racket[(2)]) (+ 1 2))
]

这之所以有效，是因为 @racket[(+ 1 . @#,racket[(2)])] 只是 @racket[(+ 1 2)] 的另一种写法。使用这种点记法来编写应用表达式实际上从来不是好主意；这只是 Racket 语法定义方式的结果。

通常，读取器只允许在括号序列中使用 @litchar{.}，且只在序列的最后一个元素之前。然而，一对 @litchar{.} 也可以出现在括号序列中的单个元素周围，只要该元素不是第一个或最后一个。这样的配对会触发读取器转换，将 @litchar{.} 之间的元素移到列表的前面。这种转换启用了一种通用的中缀记法：

@interaction[
(1 . < . 2)
'(1 . < . 2)
]

这种两点约定是非传统的，与非列表 pair 的点记法基本上没有关系。Racket 程序员很少使用中缀约定——主要用于不对称的二元运算符，如 @racket[<] 和 @racket[is-a?]。
