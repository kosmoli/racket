#lang scribble/doc
@(require scribble/manual scribble/bnf scribble/eval
          "guide-utils.rkt" "modfile.rkt"
          (for-label racket/match syntax/readerr))

@title[#:tag "hash-reader"]{读取器扩展}

@refdetails["parse-reader"]{reader extensions}

Racket 语言的 @tech{reader} 层可以通过 @racketmetafont{#reader} 形式进行扩展。一个 reader extension 实现为一个以 @racketmetafont{#reader} 命名的模块。该模块导出将原始字符解析为供 @tech{expander} 层消费的 form 的函数。

@racketmetafont{#reader} 的语法是

@racketblock[@#,(BNF-seq @litchar{#reader} @nonterm{module-path} @nonterm{reader-specific})]

其中 @nonterm{module-path} 命名一个提供 @racketidfont{read} 和 @racketidfont{read-syntax} 函数的模块。@nonterm{reader-specific} 部分是由 @nonterm{module-path} 中的 @racketidfont{read} 和 @racketidfont{read-syntax} 函数决定如何解析的字符序列。

例如，假设文件 @filepath{five.rkt} 包含

@racketmodfile["five.rkt"]

那么程序

@racketmod[
racket/base

'(1 @#,(elem @racketmetafont{#reader} @racket["five.rkt"] @tt{23456} @racket[7]) 8)
]

等价于

@racketmod[
racket/base

'(1 ("23456") 7 8)
]

因为 @filepath{five.rkt} 的 @racketidfont{read} 和 @racketidfont{read-syntax} 函数都从输入流中读取五个字符并将它们放入一个 string 和一个 list。来自 @filepath{five.rkt} 的 reader function 不需要遵循 Racket 的词法约定并将连续序列 @litchar{234567} 视为单个数字。由于只有 @litchar{23456} 部分被 @racketidfont{read} 或 @racketidfont{read-syntax} 消费，@litchar{7} 仍然以通常的 Racket 方式被解析。类似地，来自 @filepath{five.rkt} 的 reader function 不需要忽略 whitespace，

@racketmod[
racket/base

'(1 @#,(elem @racketmetafont{#reader} @racket["five.rkt"] @hspace[1] @tt{2345} @racket[67]) 8)
]

等价于

@racketmod[
racket/base

'(1 (" 2345") 67 8)
]

因为 @racket["five.rkt"] 之后的第一个字符是空格。

@racketmetafont{#reader} 形式也可以在 @tech{REPL} 中使用：

@interaction[
(eval:alts '@#,(elem @racketmetafont{#reader}@racket["five.rkt"]@tt{abcde}) '#reader"five.rkt"abcde)
]

@; ----------------------------------------------------------------------

@section{Source Locations}

@racketidfont{read} 和 @racketidfont{read-syntax} 的区别在于 @racketidfont{read} 用于数据，而 @racketidfont{read-syntax} 用于解析程序。更精确地说，当外围流正由 Racket @racket[read] 解析时使用 @racketidfont{read}，当外围流正由 Racket @racket[read-syntax] 函数解析时使用 @racketidfont{read-syntax}。不需要 @racketidfont{read} 和 @racketidfont{read-syntax} 以相同方式解析输入，但使它们不同会让程序员和工具感到困惑。

@racketidfont{read-syntax} 函数可以返回与 @racketidfont{read} 相同类型的值，但它通常应该返回一个将解析后的表达式与 source location 关联起来的 @tech{syntax object}。与 @filepath{five.rkt} 示例不同，@racketidfont{read-syntax} 函数通常直接实现以生成 @tech{syntax objects}，然后 @racketidfont{read} 可以使用 @racketidfont{read-syntax} 并剥离 @tech{syntax object} 包装以产生原始结果。

以下 @filepath{arith.rkt} 模块实现了一个 reader，将简单的中缀算术表达式解析为 Racket form。例如，@litchar{1*2+3} 解析为 Racket form @racket[(+ (* 1 2) 3)]。支持的运算符是 @litchar{+}、@litchar{-}、@litchar{*} 和 @litchar{/}，而 operand 可以是 unsigned integer 或单字母 variable。该实现使用 @racket[port-next-location] 获取当前 source location，并使用 @racket[datum->syntax] 将原始值转换为 @tech{syntax object}。

@racketmodfile["arith.rkt"]

如果 @filepath{arith.rkt} reader 在表达式位置使用，则其解析结果将被视为 Racket 表达式。但如果在 quoted form 中使用，则它只产生一个 number 或 list：

@interaction[
(eval:alts @#,(elem @racketmetafont{#reader}@racket["arith.rkt"]@hspace[1]@tt{1*2+3}) #reader"arith.rkt" 1*2+3 )
(eval:alts '@#,(elem @racketmetafont{#reader}@racket["arith.rkt"]@hspace[1]@tt{1*2+3}) '#reader"arith.rkt" 1*2+3 )
]

@filepath{arith.rkt} reader 也可以在不合理的位置使用。由于 @racketidfont{read-syntax} 实现追踪了 source location，syntax error 至少可以根据原始位置引用输入的部分（在错误消息的开头）：

@interaction[
(eval:alts (let @#,(elem @racketmetafont{#reader}@racket["arith.rkt"]@hspace[1]@tt{1*2+3}) 8)
           (eval (parameterize ([read-accept-reader #t])
                   (read-syntax 'repl (let ([p @open-input-string{(let #reader"arith.rkt" 1*2+3 8)}])
                                        (port-count-lines! p)
                                        p)))))
]

@; ----------------------------------------------------------------------

@section[#:tag "readtable"]{Readtables}

一个 reader extension 以任意方式解析输入字符的能力很强大，但许多 lexical extension 的场景需要一种不那么通用但更 composable 的方法。就像 Racket 语法的 @tech{expander} 层可以通过 @tech{macros} 扩展一样，Racket 语法的 @tech{reader} 层可以通过 @deftech{readtable} 进行 composable 扩展。

Racket reader 是一个 recursive-descent parser，而 @tech{readtable} 将字符映射到解析 handler。例如，默认的 readtable 将 @litchar{(} 映射到一个 handler，该 handler 递归解析 subform 直到找到 @litchar{)}。@racket[current-readtable] @tech{parameter} 决定由 @racket[read] 或 @racket[read-syntax] 使用的 @tech{readtable}。与其直接解析原始字符，一个 reader extension 可以安装一个扩展的 @tech{readtable} 然后链式调用 @racket[read] 或 @racket[read-syntax].

@guideother{See @secref["parameterize"] for an introduction to
@tech{parameters}.}

@racket[make-readtable] 函数构造一个新的 @tech{readtable} 作为现有 readtable 的扩展。它接受一系列规范，包括字符、字符的映射类型以及（对某些映射类型）解析 procedure。例如，要扩展 readtable 使 @litchar{$} 可用于开始和结束中缀表达式，实现一个 @racket[read-dollar] 函数并使用：

@racketblock[
(make-readtable (current-readtable)
                #\$ 'terminating-macro read-dollar)
]

@racket[read-dollar] 的协议要求函数接受不同数量的参数，取决于它是在 @racket[read] 还是 @racket[read-syntax] 模式下使用。在 @racket[read] 模式下，解析函数接收两个参数：触发解析函数的字符和正在读取的 input port。在 @racket[read-syntax] 模式下，函数必须接受四个提供字符 source location 的附加参数。

以下 @filepath{dollar.rkt} 模块定义了一个基于 @filepath{arith.rkt} 提供的 @racketidfont{read} 和 @racketidfont{read-syntax} 函数的 @racket[read-dollar] 函数，并将 @racket[read-dollar] 与安装 readtable 并链式调用 Racket 的 @racket[read] 或 @racket[read-syntax] 的新 @racketidfont{read} 和 @racketidfont{read-syntax} 函数组合。

@racketmodfile["dollar.rkt"]

使用此 reader extension，可以在表达式开头使用单个 @racketmetafont{#reader} 来开启 @litchar{$} 多次进行中缀算术运算：

@interaction[
(eval:alts @#,(elem @racketmetafont{#reader}@racket["dollar.rkt"]@hspace[1]
                    @racket[(let ([a @#,tt{$1*2+3$}] [b @#,tt{$5/6$}]) $a+b$)])
           #reader"dollar.rkt" (let ([a $1*2+3$] [b $5/6$]) $a+b$))
]
