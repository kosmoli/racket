#lang scribble/doc
@(require scribble/manual scribble/eval scribble/racket
          "guide-utils.rkt" "modfile.rkt"
          (for-syntax racket/base)
          (for-label setup/dirs
                     syntax/strip-context
                     syntax-color/default-lexer))

@(define-syntax ! (make-element-id-transformer (lambda (v) #'@tt{|})))
@(define-syntax !- (make-element-id-transformer (lambda (v) #'@tt{|-})))


@title[#:tag "hash-languages" #:style 'toc]{定义新的 @hash-lang[] 语言}

当将文件作为源程序加载，其开头为

@racketmod[
@#,racket[_language]
]

@racket[_language] 决定了在 @tech{reader} 级别解析该模块中其余部分的方式。@tech{reader} 级别的解析必须产生一个 @racket[module] 形式，作为一个 @tech{syntax object}。与往常一样，在 @racket[module] 之后第二个子形式指定 @tech{module language}，它控制模块体形式的含义。因此，在 @hash-lang[] 指定的 @racket[_language] 同时控制一个模块的 @tech{reader} 级别和 @tech{expander} 级别的解析。

@local-table-of-contents[]

@; ----------------------------------------
@section[#:tag "hash-lang syntax"]{指定 @hash-lang[] 语言}

@racket[_language] 的语法有意与在 @racket[require] 中使用的模块路径语法或作为 @tech{module language} 的模块路径语法重叠，以便 @racketmodname[racket]、@racketmodname[racket/base]、@racketmodname[slideshow #:indirect] 或 @racketmodname[scribble/manual] 等名称可以同时作为 @hash-lang[] 语言和模块路径使用。

同时，@racket[_language] 的语法远比模块路径受限，因为在 @racket[_language] 名称中仅允许使用 @litchar{a}-@litchar{z}、@litchar{A}-@litchar{Z}、@litchar{0}-@litchar{9}、@litchar{/}（不在首位或末位）、@litchar{_}、@litchar{-} 和 @litchar{+}。这些限制使 @hash-lang[] 的语法尽可能简单。反过来，保持 @hash-lang[] 语法简单很重要，因为该语法本身是不可变且不可扩展的；@hash-lang[] 协议允许 @racket[_language] 以几乎不受限制的方式细化和定义语法，但 @hash-lang[] 协议本身必须保持固定，以便各种不同工具可以"引导"（boot）进入扩展的世界。

幸而，@hash-lang[] 协议提供了一种自然的方式来引用语言，而不仅仅是以严格的 @racket[_language] 语法：通过实现一个实现自己嵌套协议的 @racket[_language]。我们已经看到了一个例子（在 @secref["s-exp"] 中）：@racketmodname[s-exp] @racket[_language] 允许程序员使用通用 @tech{module path} 语法指定 @tech{module language}。同时，@racketmodname[s-exp] 负责 @hash-lang[] 语言的 @tech{reader} 级别职责。

不能将 @racketmodname[racket] 用作 @racket[require] 的模块路径。尽管用于 @hash-lang[] 的 @racket[_language] 语法与模块路径的语法重叠，但 @racket[_language] 不会直接被用作模块路径。相反，@racket[_language] 通过尝试两个位置来获得模块路径：首先，它查找 @racket[_language] 主模块的 @racketidfont{reader} 子模块。如果这不是有效的模块路径，则 @racket[_language] 会被添加 @racketidfont{/lang/reader} 后缀。（如果两者都不是有效模块路径，则会引发异常。）由此产生的模块使用类似于 @racketmetafont{#reader} 使用的协议提供 @racketidfont{read} 和 @racketidfont{read-syntax} 函数。

@guideother{@secref["hash-reader"] 介绍了 @racketmetafont{#reader}。}

@hash-lang[] @racket[_language] 转换为模块路径的方式的一个后果是，该语言必须安装在 @tech{collection} 中，类似于随 Racket 分发的 @filepath{racket} 或 @filepath{slideshow} 作为集合。然而，同样地，有一种方式可以摆脱此限制：@racketmodname[reader] 语言允许使用通用 @tech{module path} 指定语言的 @tech{reader} 级别实现。

@; ----------------------------------------
@section[#:tag "hash-lang reader"]{使用 @racket[@#,hash-lang[] @#,racketmodname[reader]]}

@racket[@#,hash-lang[] @#,racketmodname[reader]] 语言的用途类似于 @racketmodname[s-exp]，因为它充当一种元语言。
而 @racketmodname[s-exp] 让程序员在解析的 @tech{expander} 层指定 @tech{module language}，
@racketmodname[reader] 让程序员在 @tech{reader} 层指定语言。

@racket[@#,hash-lang[] @#,racketmodname[reader]] 之后必须跟一个模块路径，且指定的模块必须提供两个函数：@racketidfont{read} 和 @racketidfont{read-syntax}。协议与 @racketmetafont{#reader} 实现相同，但对于 @hash-lang[]，@racketidfont{read} 和 @racketidfont{read-syntax} 函数必须产生基于模块其余输入文件的 @racket[module] 形式。

以下 @filepath{literal.rkt} 模块实现了一种将整个体部视为纯文本并将文本作为 @racketidfont{data} 字符串导出的语言：

@racketmodfile["literal.rkt"]

@filepath{literal.rkt} 语言在生成的 @racket[module] 表达式上使用 @racket[strip-context]，
因为 @racketidfont{read-syntax} 函数应返回一个无词法上下文的语法对象。此外，
@filepath{literal.rkt} 语言创建一个名为 @racketidfont{anything} 的模块，这是一个任意选择；
该语言旨在文件中使用，当出现在 @racket[require]d 文件中时，长格式模块名称会被忽略。

@filepath{literal.rkt} 语言可以在一个模块 @filepath{tuvalu.rkt} 中使用：

@racketmodfile["tuvalu.rkt"]

导入 @filepath{tuvalu.rkt} 会将 @racketidfont{data} 绑定为模块内容的字符串版本：

@interaction[
(require "tuvalu.rkt")
data
]

@; ----------------------------------------
@section[#:tag "syntax/module-reader"]{使用 @racket[@#,hash-lang[] @#,racketmodname[s-exp] @#,racketmodname[syntax/module-reader]]}

解析模块体通常不像在 @filepath{literal.rkt} 中那么简单。更典型的模块解析器必须迭代以解析模块体的多个形式。一种语言也更可能扩展 Racket 语法——可能通过 @tech{readtable}——而不是完全替换 Racket 语法。

@racketmodname[syntax/module-reader] @tech{module language}
抽象了语言实现的常见部分，以简化新语言的创建。在最基本的形式中，一个使用 @racketmodname[syntax/module-reader] 实现的语言仅指定该语言所用的 @tech{module language}，在此情况下，该语言的 @tech{reader} 层与 Racket 相同。例如，使用

@racketmod[
#:file "raquet-mlang.rkt"
racket
(provide (except-out (all-from-out racket) lambda)
         (rename-out [lambda function]))
]

和

@racketmod[
#:file "raquet.rkt"
s-exp syntax/module-reader
"raquet-mlang.rkt"
]

则

@racketmod[
reader "raquet.rkt"
(define identity (function (x) x))
(provide identity)
]

实现并导出了 @racket[identity] 函数，因为 @filepath{raquet-mlang.rkt} 将 @racket[lambda] 导出为 @racket[function]。

@racketmodname[syntax/module-reader] 语言接受许多可选规范来调整语言的其他特性。例如，可以用 @racket[#:read] 和 @racket[#:read-syntax] 分别指定用于解析语言的可选 @racketidfont{read} 和 @racketidfont{read-syntax}。以下 @filepath{dollar-racket.rkt} 语言使用 @filepath{dollar.rkt}（参见 @secref["readtable"]）构建一种像 @racketmodname[racket] 但带有 @litchar{$} 转义进行简单中缀运算的语言：

@racketmodfile["dollar-racket.rkt"]

@racket[require] 形式出现在模块末尾，因为所有用于 @racketmodname[syntax/module-reader] 的带关键字的可选规范必须出现在任何辅助导入或定义之前。

以下模块使用 @filepath{dollar-racket.rkt} 实现了一个使用 @litchar{$} 转义的 @racket[cost] 函数：

@racketmodfile["store.rkt"]

@; ----------------------------------------
@section[#:tag "language-collection"]{安装语言}

到目前为止，我们一直使用 @racketmodname[reader] 元语言来访问像 @filepath{literal.rkt} 和 @filepath{dollar-racket.rkt} 这样的语言。如果希望直接使用类似 @racket[@#,hash-lang[] literal] 的形式，则必须将 @filepath{literal.rkt} 移动到名为 @filepath{literal} 的 Racket @tech{collection} 中（另请参见 @secref["link-collection"]）。具体地，将 @filepath{literal.rkt} 移动到任何目录名 @filepath{literal} 的 @racketidfont{reader} 子模块中，如下所示：

@racketmodfile["literal-main.rkt" "literal/main.rkt"]

然后，将 @filepath{literal} 目录安装为包：

@commandline{cd /path/to/literal ; raco pkg install}

移动文件并安装包后，可以直接在 @hash-lang[] 之后使用 @racket[literal]：

@racketmod[
@#,racket[literal]
Technology!
System!
Perfect!
]

@margin-note{参见 @other-manual['(lib "scribblings/raco/raco.scrbl")]
了解更多使用 @exec{raco} 的信息。}

你还可以通过使用 Racket 包管理器（参见 @other-doc['(lib
"pkg/scribblings/pkg.scrbl")]）使你的语言可供他人安装。创建 @filepath{literal} 包并将其注册到 Racket 包目录后（参见
@secref["concept:catalog" #:doc '(lib "pkg/scribblings/pkg.scrbl")]），
其他人可以使用 @exec{raco pkg} 安装它：

@commandline{raco pkg install literal}

安装后，其他人可以相同方式使用该语言：在源文件顶部使用 @racket[@#,hash-lang[] literal]。

如果使用公共源码仓库（例如 GitHub），可以将你的包链接到源码。在你改进包的同时，其他人可以使用 @exec{raco pkg} 更新其版本：

@commandline{raco pkg update literal}

@margin-note{参见 @other-doc['(lib "pkg/scribblings/pkg.scrbl")] 了解更多关于 Racket 包管理器的信息。}

@; ----------------------------------------
@section[#:tag "language-get-info"]{源处理配置}

Racket 发行版包含一个用于编写散文式文档的 Scribble 语言，其中 Scribble 扩展了正常的 Racket 以更好地支持文本。以下是一个 Scribble 文档示例：

@verbatim[#:indent 2]|{
#lang scribble/base

@(define (get-name) "Self-Describing Document")

@title[(get-name)]

The title of this document is ``@(get-name).''
}|

如果将该程序放入 DrRacket 的 @tech{definitions area} 中并
点击 @onscreen{Run}，则似乎没有任何事情发生。
@racketmodname[scribble/base] 语言只是绑定并导出
@racketidfont{doc} 作为文档描述，类似于 @filepath{literal.rkt} 导出
字符串作为 @racketidfont{data}。

然而，仅仅在 DrRacket 中用语言 @racketmodname[scribble/base] 打开一个模块，
就会使 @onscreen{Scribble HTML} 按钮出现。此外，DrRacket 知道如何通过对那些
对应于纯文本的文档部分显示绿色来着色 Scribble 语法。语言名称
@racketmodname[scribble/base] 不是硬连线的。相反，
@racketmodname[scribble/base] 语言的实现会根据 DrRacket 的查询提供按钮和语法着色信息。

如果你已按照 @secref["language-collection"] 中的描述安装了 @racket[literal] 语言，
则可以调整 @filepath{literal/main.rkt}，使 DrRacket 将 @racket[literal]
语言模块的内容视为纯文本而不是（错误地）视为 Racket 语法：

@racketmodfile["literal-main-get-info.rkt" "literal/main.rkt"]

这个改进的 @racket[literal] 实现提供了一个 @racketidfont{get-info} 函数。该 @racketidfont{get-info} 函数被 @racket[read-language]（由 DrRacket 调用）调用，输入源流和位置信息，以防查询结果应取决于模块在语言名之后的内容（对于 @racket[literal] 而言并非如此）。@racketidfont{get-info} 的结果是一个双参函数。第一个参数始终是一个符号，表示工具从语言请求的信息类型；第二个参数是默认结果，若语言无法识别查询或没有相关信息则返回该值。

DrRacket 在为语言获取 @racketidfont{get-info} 的结果后，会以 @racket['color-lexer] 查询调用该函数；结果应该是一个实现语法着色解析的输入流函数。对于 @racket[literal]，@racketmodname[syntax-color/default-lexer] 模块提供了一个适合纯文本的 @racket[default-lexer] 语法着色解析器，因此 @racket[literal] 加载并返回该解析器以响应 @racket['color-lexer] 查询。

编程语言工具使用的符号集合完全由工具和选择与之合作的语言决定。例如，除了 @racket['color-lexer] 之外，DrRacket 还使用 @racket['drracket:toolbar-buttons] 查询来确定工具栏中哪些按钮可用于操作使用该语言的模块。

@racketmodname[syntax/module-reader] 语言允许您通过 @racket[#:info] 可选规范指定 @racketidfont{get-info} 处理。@racket[#:info] 函数的协议与原始 @racketidfont{get-info} 协议略有不同；改进后的协议允许 @racketmodname[syntax/module-reader] 自动处理未来的语言信息查询。

@; ----------------------------------------
@section[#:tag "module-runtime-config"]{模块处理配置}

假设文件 @filepath{death-list-5.rkt} 包含

@racketmodfile["death-list-5.rkt"]

如果直接 @racket[require] @filepath{death-list-5.rkt}，则它会以通常的 Racket 结果格式打印列表：

@interaction[
(require "death-list-5.rkt")
]

然而，如果 @filepath{death-list-5.rkt} 被一个用 @racketmodname[scheme #:indirect] 而不是 @racketmodname[racket] 实现的 @filepath{kiddo.rkt} 所需：

@racketmod[#:file "kiddo.rkt" #,(racketmodname scheme #:indirect)
           (require "death-list-5.rkt")]

那么，如果你在 DrRacket 中运行 @filepath{kiddo.rkt} 文件或用 @exec{racket} 直接运行，@filepath{kiddo.rkt} 会导致 @filepath{death-list-5.rkt} 以传统 Scheme 格式打印其列表，不带头引号：

@racketblock[
@#,racketoutput{("O-Ren Ishii" "Vernita Green" "Budd" "Elle Driver" "Bill")}
]

@filepath{kiddo.rkt} 示例说明了结果值的打印格式如何依赖于程序的主模块而不是用于实现它的语言。

更广义地说，某些语言特性仅在用该语言编写的模块被直接用 @exec{racket} 运行时（而不是导入到另一个模块时）才会被调用。一个例子是结果打印样式（如上文所示）。另一个例子是 REPL 行为。这些特性被称为语言的 @deftech{run-time configuration} 的一部分。

与语言的语法着色特性（如 @secref["language-get-info"] 中描述的那样）不同，run-time configuration 是 @emph{模块} 本身的特性，而不是 @emph{源文本} 的特性。因此，模块的 run-time configuration 必须在模块被编译为字节码形式且源不可用时仍然可用。因此，run-time configuration 不能由语言解析器模块导出的 @racketidfont{get-info} 函数处理。

相反，它将被一个新的 @racket[configure-runtime] 子模块处理，我们将在解析后的 @racket[module] 形式内添加该模块。当模块直接用 @exec{racket} 运行时，@exec{racket} 会查找 @racket[configure-runtime] 子模块。如果存在，@exec{racket} 会运行它。但如果模块被导入到另一个模块中，@racket['configure-runtime] 子模块会被忽略。（并且如果 @racket[configure-runtime] 子模块不存在，@exec{racket} 只会按通常方式评估模块。）这意味着 @racket[configure-runtime] 子模块可用于任何需要在模块直接运行时发生的特殊设置任务。

回到 @racket[literal] 语言（参见 @secref["language-get-info"]），我们可以调整该语言，使其在直接运行 @racket[literal] 模块时打印其字符串，而在更大的程序中使用 @racket[literal] 模块时，仅提供 @racketidfont{data} 而不进行打印。为了实现这一点，我们需要一个额外的模块。（为清晰起见，这里我们会将此模块实现为单独的文件。但它同样也可以作为现有文件的子模块。）

@racketblock[
.... @#,elem{(主安装或用户空间)}
!- @#,filepath{literal}
   !- @#,filepath{main.rkt}            @#,elem{(带 reader 子模块)}
   !- @#,filepath{show.rkt}            @#,elem{(新增)}
]

@itemlist[

 @item{@filepath{literal/show.rkt} 模块将提供一个 @racketidfont{show} 函数，应用于 @racket[literal] 模块的字符串内容，并提供一个 @racketidfont{show-enabled} 参数，控制 @racketidfont{show} 是否实际打印结果。}

 @item{@filepath{literal/main.rkt} 中新的 @racket[configure-runtime] 子模块会将 @racketidfont{show-enabled} 参数设置为 @racket[#t]。净效果是 @racketidfont{show} 将打印其给定的字符串，但仅在使用 @racket[literal] 语言的模块被直接运行时（因为只有在这种情况下 @racket[configure-runtime] 子模块才会被调用）。}

]


这些更改在以下改进的 @filepath{literal/main.rkt} 中实现：

@racketmodfile["literal-main-language-info.rkt" "literal/main.rkt"]

然后 @filepath{literal/show.rkt} 模块必须提供 @racketidfont{show-enabled} 参数和 @racketidfont{show} 函数：

@racketmod[
#:file "literal/show.rkt"
racket

(provide show show-enabled)

(define show-enabled (make-parameter #f))

(define (show v)
  (when (show-enabled)
    (display v)))
]

@racket[literal] 的所有部件就位后，尝试直接运行以下变体
@filepath{tuvalu.rkt} 并通过另一个模块 @racket[require] 调用它：

@racketmod[
#:file "tuvalu.rkt"
@#,racket[literal]
Technology!
System!
Perfect!
]

当直接运行时，我们会看到结果像这样被打印，因为我们
的 @racket[configure-runtime] 子模块会将 @racketidfont{show-enabled} 参数设置为 @racket[#t]：

@racketblock[
@#,racketoutput{Technology!
@(linebreak)System!
@(linebreak)Perfect!}
]

但当导入到另一个模块时，打印将被抑制，
因为 @racket[configure-runtime] 子模块不会被调用，
因此 @racketidfont{show-enabled} 参数将保持其默认值 @racket[#f]。
