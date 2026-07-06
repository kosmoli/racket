#lang scribble/base

@(require "shared.rkt")

@(define-syntax-rule
  (good form code ...)
  (racketmod #:file (tt "good") racket form code ...))

@title{文本规范}

简单的文本约定有助于快速定位代码片段。以下是一些易于检查的约定——部分可自动检查，部分需手动检查。如果你发现自己正在编辑的文件违反了以下某些约束，请将其修改为正确的
格式。@margin-note{@bold{警告}：极少数情况下，单元测试可能依赖于文件的缩进。这种情况极为罕见，必须在文件顶部注明，以免读者意外重新缩进该文件。}

@; -----------------------------------------------------------------------------
@section{括号的位置}

Racket 不是 C。将所有右括号放在同一行，即代码的最后一行。

@compare0[#:right "really bad"
 @racketmod0[
 racket
@;%
 (define (conversion f)
   (* 5/9 (- f 32)))
]
 @codeblock0{#lang racket
 (define (conversion f)
   (* 5/9 (- f 32)
     )
   )
 }
]

允许将全部右括号单独放在一行，位于长序列（无论是定义还是数据）的末尾。

@compare0[#:left "acceptable" #:right "also acceptable"
 @racketmod0[
 racket
 (define modes
   '(edit
     help
     debug
     test
     trace
     step
     ))
 ]
 @codeblock0{#lang racket
 (define turn%
   (class object%
     (init-field state)

     (super-new)

     (define/public (place where tile)
       (send state where tile))

     (define/public (is-placable? place)
       (send state legal? place))
     ))
 }
]
 这样做在你预期会添加、删除或交换序列中的项时最为有用。

@; -----------------------------------------------------------------------------
@section{Indentation}

DrRacket 会对代码进行缩进，它是 PLT 中所有人都认同的唯一工具。因此要使用 DrRacket 的缩进风格。其含义如下。
 @nested[#:style 'inset]{
 对于仓库中的每个文件，DrRacket 的"indent all"功能不会动该文件。}

如果你偏好使用其他编辑器（emacs、vi/m 等），请将其配置为遵循 DrRacket 的缩进风格。

示例：

@compare0[
 @racketmod0[
 racket

 (code:comment2 #, @t{drracket style})
 (if (positive? (rocket-x r))
     (launch r)
     (redirect (- x)))
 ]

 @racketmod0[
 racket

 (code:comment2 #, @t{.el emacs-file if})
 (if (positive? (rocket-x r))
     (launch r)
   (redirect (- x)))
 ]
]

@bold{注意事项 1}：直到语言规范自带固定的缩进规则之前，我们需要使用 DrRacket 缩进的 @emph{默认}设置，这条规则才有意义。如果你添加了新构造，比如 for 循环，请联系 Robby 获取如何为缩进功能添加默认设置的建议。如果你添加了完整的语言，比如 Typed Racket，参见
@seclink[#:indirect? #t #:doc '(lib "scribblings/tools/tools.scrbl") "lang-languages-customization"]{@elem{DrRacket 对 @tt{#lang}-based Languages 的支持}}
了解如何实现 tab 缩进。

@bold{注意事项 2}：此规则不适用于 scribble 代码。

@; -----------------------------------------------------------------------------
@section{制表符}

不要在代码中使用制表符。制表符会使 Git 或 diff 等文本难以有效使用。要禁用制表符：
@itemlist[
@item{在 DrRacket 中：已默认关闭，不会插入制表符。}
@item{在 Emacs 中：在初始化文件中添加 @tt{(setq indent-tabs-mode nil)}。}
@item{在 vi 中：@tt{:set expandtab}}
]

@; -----------------------------------------------------------------------------
@section{行宽}

Racket 文件中每行最多 @LINEWIDTH[] 个字符宽。

如果你希望宽度小于 @LINEWIDTH[]，并且会"严格遵守"这一宽度，请在文件顶部——紧接在目的说明之后——添加一条注释，说明不要违反你的文件本地规则。

这个数字是一个折中方案。过去人们推荐 80 或 72 列的宽度。该数字是历史遗迹。出于多种不同原因它也是一个好数字：在文本模式下打印代码、在合理字体大小下显示代码、在监视器上比较多个不同代码片段等等。因此年代久远不代表它不正确。我们经常在接近 250 列的监视器上阅读代码，有时甚至更宽。现在可以在有意义的标识符方面允许稍多一些宽度。

因此，创建文件时，添加一个包含 @litchar{;; } 的行后跟 ctrl-U 99 和 @litchar{-}。@margin-note*{在 Vi 中，命令为 99a- 后跟 Esc。}当你在文件中分隔代码"段"时，插入同样的行。这些行帮助写作者和读者在文件中定位。在 Scribble 中使用 @litchar|{@; }| 作为前缀。

@; -----------------------------------------------------------------------------
@section{换行}

除了缩进之外，正确的换行至关重要。

对于 @scheme[if] 表达式，将每个分支放在单独一行。

@compare0[
@racketmod0[
racket

(if (positive? x)
    (launch r)
    (redirect (- x)))
]

@racketmod0[
racket

(if (positive? x) (launch r)
    (redirect (- x)))
]
]

如果整个 @racket[if] 表达式能容纳在指定的行宽 (@LINEWIDTH[]) 内，则可以将其放在一行：
@codebox0[#:label "also good"
@racketmod0[
racket

(if (positive? x) x (- x))
]
]

每个定义和每个局部定义都应独占一行。

@compare0[
@racketmod0[
racket

(define (launch x)
  (define w 9)
  (define h 33)
  ...)
]

@racketmod0[
racket

(define (launch x)
  (define w 9) (define h 33)
  ...)
]
]

函数的所有参数应在同一行，除非该行太长，此时应将每个参数表达式单独放在一行：

@compare0[
@racketmod0[
racket

(place-image img 10 10 background)

(code:comment2 #, @t{and})

(above img
       (- width  hdelta)
       (- height vdelta)
       bg)
]

@racketmod0[
racket

(above ufo
       10 v-delta bg)

]]

这是一个例外：
@codebox0[
@racketmod0[
racket

(overlay/offset (rectangle 100 10 "solid" "blue")
                10 10
                (rectangle 10 100 "solid" "red"))
]]
 在这种情况下，第 2 行的两个参数概念上相关且较短。


@; -----------------------------------------------------------------------------
@section[#:tag "names"]{命名}

使用有意义的名称。Lisp 约定是用完整的英文单词以连字符分隔。Racket 代码同样遵循此约定。

@compare0[
@;%
(racketmod0
racket

render-game-state

send-message-to-client

traverse-forest)

@; -----------------------------------------------------------------------------
@;%
(racketmod0
racket

rndr-st

sendMessageToClient

traverse_forest)
]
@;
 注意，_（下划线）在命名中被视为不良风格。在 syntax pattern、match pattern 和不重要的参数中，它是可接受的占位符。

另一种广泛使用的约定是在函数名 @emph{前缀}中使用主参数的数据类型。这种约定是 @racket[struct] 选择器式命名方案的推广。
@codebox0[
(racketmod0
racket

board-free-spaces      board-closed-spaces    board-serialize)]
 相反，variables 使用 @emph{后缀}来表示其类型：
@codebox0[
(racketmod0
racket

(define (win-or-lose? game-state)
  (define position-nat-nat (game-state-position game-state))
  (define health-level-nat (game-state-health game-state))
  (define name-string      (game-state-name game-state))
  (define name-symbol      (string->symbol name-string))
  ...))]
 当同一份数据以不同形式出现时（如 symbols 和 strings），这种约定特别有帮助。

当名称严重依赖于代码的上下文知识时，就是不好的命名。它会阻止读者在近似级别理解某块功能，同时还需要阅读大量周围的代码。

最后，除了常规的字母数字字符外，Racketeers 还按约定使用少数特殊字符，这些字符传达名称的某些含义：

@row-table[
 @row[字符 类型 示例]
 @row[?    "predicates 和 boolean 值函数" boolean?]
 @row[!    "setters 和字段 mutators"              set!]
 @row[%    "classes"                                 game-state%]
 @row[<%>  "interfaces"                              dc<%>]
 @row[^    "unit signatures"                         game-context^]
 @row["@"  "units"                                   testing-context@]
 @row["#%""kernel identifiers"                      #%app]
 @row["/"  "\"with\"（介词）"               call/cc]
]
 @margin-note*{带 @litchar{#%} 前缀的标识符主要用于定义新语言的模块中。}
 使用 @litchar{#%} 作为 kernel 语言的名称前缀警告读者这些标识符极为特殊，需要注意细微之处。没有其他标识符以 @litchar{#} 开头，特别地，所有以 @litchar{#:} 开头的 token 都是 keywords。

@; -----------------------------------------------------------------------------
@section{Graphical Syntax}

不要使用图形化语法（注释框、XML 框等）。

使用图形化语法使得无法在替代编辑器中读取文件。它还会干扰某些版本控制系统。当我们找到以编辑器兼容方式保存此类文件的方法时，可能会放宽此限制。

@section{空格}

不要用行尾空格污染代码。

如果发现自己用空行来分隔长代码块以提高可读性，可以考虑重构程序并引入辅助函数，以缩短这些长代码块。如果没有其他帮助，可以考虑使用（可能为空的）注释行。

另外，一行上的每对表达式之间应至少有一个空格，即使它们之间隔了括号。

@compare0[
 @racketmod0[
 racket

 (define (f x g)
   (cond [(< x 3) (g (g 3))]))
]
 @racketmod0[
 racket

 (define(f x g)
   (cond[(< x 3)(g(g 3))]))
 ]
]


@; -----------------------------------------------------------------------------
@section{文件末尾}

文件以换行结尾。
