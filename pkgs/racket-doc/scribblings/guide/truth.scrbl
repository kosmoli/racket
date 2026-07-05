#lang scribble/doc
@(require scribble/manual scribble/eval racket/list "guide-utils.rkt"

          (for-label racket/list
                     (only-in racket/class is-a?)))

@(define list-eval (make-base-eval))
@(interaction-eval #:eval list-eval (require racket/list))

@title{点对、列表和 Racket 语法}

The @racket[cons] function actually accepts any two values, not just
a list for the second argument. When the second argument is not
@racket[empty] and not itself produced by @racket[cons], the result prints
in a special way. The two values joined with @racket[cons] are printed
between parentheses, but with a dot (i.e., a period surrounded by
whitespace) in between:

@interaction[(cons 1 2) (cons "banana" "split")]

因此，@racket[cons] 产生的值不一定是 list。通常，@racket[cons] 的结果是 @defterm{pair}。
@racket[cons?] 函数更传统的名称是 @racket[pair?]，我们将从现在开始使用这个传统名称。

The name @racket[rest] also makes less sense for non-list pairs; the
more traditional names for @racket[first] and @racket[rest] are
@racket[car] and @racket[cdr], respectively. (Granted, the traditional
names are also nonsense. Just remember that ``a'' comes before ``d,''
and @racket[cdr] is pronounced ``could-er.'')

@examples[
#:eval list-eval
(car (cons 1 2))
(cdr (cons 1 2))
(pair? empty)
(pair? (cons 1 2))
(pair? (list 1 2 3))
]

@close-eval[list-eval]

Racket 的 pair 数据类型及其与 list 的关系本质上是一种历史遗留问题，
与打印的点符号以及 @racket[car] 和 @racket[cdr] 等有趣名称一样。
但 pair 深深植根于 Racket 的文化、规范和实现中，因此它们仍在语言中保留。

最可能遇到非 list pair 的情况通常是犯错时，例如不小心颠倒了 @racket[cons] 的参数：

@interaction[(cons (list 2 3) 1) (cons 1 (list 2 3))]

非 list pair 有时也是有意使用的。例如，@racket[make-hash] 函数接受一个 pair 列表，
其中每个 pair 的 @racket[car] 是键，@racket[cdr] 是任意值。

对新 Racketeers 来说，唯一比非 list pair 更令人困惑的是第二个元素 @italic{是}
pair 但 @italic{不是} list 的 pair 的打印约定：

@interaction[(cons 0 (cons 1 2))]

一般来说，打印 pair 的规则如下：使用点符号，除非点后面紧跟一个左括号。
在这种情况下，移除点、左括号以及匹配的右括号。 Thus, @racketresultfont[#:decode? #f]{'(0 . (1 . 2))}
becomes @racketresult['(0 1 . 2)], and
@racketresultfont[#:decode? #f]{'(1 . (2 . (3 . ())))} becomes @racketresult['(1 2 3)].

@;------------------------------------------------------------------------
@section[#:tag "quoting-lists"]{使用 @racket[quote] 引用 pair 和 symbol}

list 打印时前面有一个引号标记，但如果 list 的元素本身也是 list，
则内部 list 不打印引号：

@interaction[
(list (list 1) (list 2 3) (list 4))
]

特别是对于嵌套 list，@racket[quote] 形式让你可以以与 list 打印方式
本质相同的方式将 list 写成表达式：

@interaction[
(eval:alts (@#,racket[quote] ("red" "green" "blue")) '("red" "green" "blue"))
(eval:alts (@#,racket[quote] ((1) (2 3) (4))) '((1) (2 3) (4)))
(eval:alts (@#,racket[quote] ()) '())
]

@racket[quote] 形式也与点符号配合使用，无论引用形式是否通过点括号消除规则进行规范化：

@interaction[
(eval:alts (@#,racket[quote] (1 . 2)) '(1 . 2))
(eval:alts (@#,racket[quote] (0 @#,racketparenfont{.} (1 . 2))) '(0 . (1 . 2)))
]

自然地，任何类型的 list 都可以嵌套：

@interaction[
(list (list 1 2 3) 5 (list "a" "b" "c"))
(eval:alts (@#,racket[quote] ((1 2 3) 5 ("a" "b" "c"))) '((1 2 3) 5 ("a" "b" "c")))
]

如果用 @racket[quote] 包装一个标识符，会得到看起来像标识符的输出，
但带有 @litchar{'} 前缀：

@interaction[
(eval:alts (@#,racket[quote] jane-doe) 'jane-doe)
]

A value that prints like a quoted identifier is a @defterm{symbol}. In the
same way that parenthesized output should not be confused with
expressions, a printed symbol should not be confused with an
identifier. In particular, the symbol @racket[(@#,racket[quote]
@#,racketidfont{map})] has nothing to do with the @racketidfont{map}
identifier or the predefined function that is bound to
@racket[map], except that the symbol and the identifier happen
to be made up of the same letters.

实际上，symbol 的内在价值不过是其字符内容。在这个意义上，
symbol和 string 几乎相同，主要区别在于它们的打印方式。
@racket[symbol->string] 和 @racket[string->symbol] 在它们之间转换。

@examples[
map
(eval:alts (@#,racket[quote] @#,racketidfont{map}) 'map)
(eval:alts (symbol? (@#,racket[quote] @#,racketidfont{map})) (symbol? 'map))
(symbol? map)
(procedure? map)
(string->symbol "map")
(eval:alts (symbol->string (@#,racket[quote] @#,racketidfont{map})) (symbol->string 'map))
]

正如 @racket[quote] 对 list 自动应用于嵌套 list 一样，
@racket[quote] 对括号内的标识符序列自动应用于这些标识符来创建 symbol 列表：

@interaction[
(eval:alts (car (@#,racket[quote] (@#,racketidfont{road} @#,racketidfont{map}))) (car '(road map)))
(eval:alts (symbol? (car (@#,racket[quote] (@#,racketidfont{road} @#,racketidfont{map})))) (symbol? (car '(road map))))
]

当 symbol 在用 @litchar{'} 打印的 list 内部时，symbol 上的 @litchar{'} 会被省略，
因为 @litchar{'} 已经在起作用：

@interaction[
(eval:alts (@#,racket[quote] (@#,racketidfont{road} @#,racketidfont{map})) '(road map))
]

@racket[quote] 形式对字面值表达式（如数字或字符串）没有影响：

@interaction[
(eval:alts (@#,racket[quote] 42) 42)
(eval:alts (@#,racket[quote] "on the record") "on the record")
]

@;------------------------------------------------------------------------
@section{Abbreviating @racket[quote] with @racketvalfont{@literal{'}}}

正如你可能已经猜到的，你可以通过将 @litchar{'} 放在要引用的形式前面
来缩写 @racket[quote]:

@interaction[
'(1 2 3)
'road
'((1 2 3) road ("a" "b" "c"))
]

In the documentation, @litchar{'} within an expression is printed in green along with the
form after it, since the combination is an expression that is a
constant. In DrRacket, only the @litchar{'} is colored green. DrRacket
is more precisely correct, because the meaning of @racket[quote] can
vary depending on the context of an expression. In the documentation,
however, we routinely assume that standard bindings are in scope, and
so we paint quoted forms in green for extra clarity.

@litchar{'} 以非常字面的方式展开为 @racket[quote] 形式。
如果在已经包含 @litchar{'} 的形式前再加一个 @litchar{'}, 你会发现这一点：

@interaction[
(car ''road)
(eval:alts (car '(@#,racketvalfont{quote} @#,racketvalfont{road})) 'quote)
]

@litchar{'} 缩写在输出和输入中都有效。@tech{REPL} 的打印器在打印输出时
将 symbol @racket['quote] 识别为两元素 list 的第一个元素，
此时它使用 @racketidfont{'} 来打印输出：

@interaction[
(eval:alts (@#,racket[quote] (@#,racketvalfont{quote} @#,racketvalfont{road})) ''road)
(eval:alts '(@#,racketvalfont{quote} @#,racketvalfont{road}) ''road)
''road
]

@; FIXME:
@; warning about how "quote" creates constant data, which is subtly
@; different than what "list" creates

@;------------------------------------------------------------------------
@section[#:tag "lists-and-syntax"]{List 与 Racket 语法}

既然你已经了解了 pair 和 list 的真相，也看过 @racket[quote]，
你已经准备好理解我们一直在简化 Racket 真实语法的主要方式。

Racket 的语法不是直接按字符流定义的。相反，语法由两层决定：

@itemize[

 @item{a @deftech{reader} layer, which turns a sequence of characters
       into lists, symbols, and other constants; and}

 @item{an @deftech{expander} layer, which processes the lists, symbols,
       and other constants to parse them as an expression.}

]

打印和读取的规则相辅相成。例如，list 用括号打印，读取一对括号会产生一个 list。
类似地，非 list pair 用点符号打印，而输入上的 dot 会反向运行点符号规则以获得 pair。

读取层对表达式的一个后果是，你可以在非引用形式的表达式中使用点符号：

@interaction[
(eval:alts (+ 1 . @#,racket[(2)]) (+ 1 2))
]

这可行是因为 @racket[(+ 1 . @#,racket[(2)])] 只是 @racket[(+ 1 2)] 的另一种写法。
实际上，使用这种点符号编写应用表达式从来都不是好主意；这只是 Racket 语法定义方式的后果。

通常，读取器仅在括号内的序列中，且仅在序列最后一个元素之前允许 @litchar{.}。
然而，一对 @litchar{.} 也可以出现在括号序列中的单个元素周围，
只要该元素不是第一个或最后一个。这样的一对会触发读取器转换，
将 @litchar{.} 之间的元素移到 list 的前面。这种转换启用了一种通用的中缀符号：

@interaction[
(1 . < . 2)
'(1 . < . 2)
]

这种双点约定是非传统的，与非 list pair 的点符号本质上无关。
Racket 程序员谨慎使用中缀约定——主要用于非对称二元运算符，如 @racket[<] 和 @racket[is-a?]。
