#lang scribble/doc
@(require scribble/manual scribble/eval scribble/bnf "guide-utils.rkt"
          (only-in scribble/core link-element)
          (for-label racket/enter))

@(define piece-eval (make-base-eval))

@title[#:tag "intro"]{Welcome to Racket}

从不同角度看，@bold{Racket} 是

@itemize[

 @item{一种 @defterm{programming language}——Lisp 的一种方言和 Scheme 的后裔；

       @margin-note{关于 Lisp 的其他方言及其与 Racket 的关系，详见 @secref["dialects"]。}}

 @item{一组编程@defterm{family}——Racket 的变体，或更广泛家族；或}

 @item{一组 @defterm{tools}——用于使用一组编程@defterm{family}的工具集。}

]

在没有歧义的情况下，我们简称为 @defterm{Racket}。

Racket 的主要工具有

@itemize[

 @tool[@exec{racket}]{the core compiler, interpreter, and run-time system;}

 @tool["DrRacket"]{the programming environment; and}

 @tool[@exec{raco}]{a command-line tool for executing @bold{Ra}cket
 @bold{co}mmands that install packages, build libraries, and more.}

]

最有可能的是，你会想用 DrRacket 来探索 Racket 语言，
特别是在刚开始的时候。如果你愿意，也可以使用命令行
@exec{racket} 解释器（见 @secref["racket"]）和你最喜欢的文本编辑器
（见 @secref["other-editors"]）。本指南的其余部分在介绍语言时
与你选择的编辑器基本无关。

如果你使用 DrRacket，你需要选择合适的语言，因为
DrRacket 支持多种不同的 Racket 变体以及其他语言。假设你
之前从未使用过 DrRacket，启动它，在 DrRacket 的顶部文本区域
输入以下行

@racketmod[racket]

然后点击文本区域上方的 @onscreen{Run} 按钮。
DrRacket 就会理解你打算使用标准 Racket 变体（而不是更小的
@racketmodname[racket/base] 或许多其他可能性）。

@margin-note{@secref["more-hash-lang"] 介绍了其他一些可能性。}

如果你之前使用 DrRacket 时没有使用以 @hash-lang[] 开头的程序，
DrRacket 会记住你上次使用的语言，而不是从 @hash-lang[] 行推断语言。
在这种情况下，使用 @menuitem["Language" "Choose Language..."] 菜单项。
在出现的对话框中，选择第一项，它告诉 DrRacket 使用通过
@hash-lang[] 在源程序中声明的语言。仍然将 @hash-lang[] 行放在
顶部文本区域中。

@; ----------------------------------------------------------------------
@section{Interacting with Racket}

DrRacket 的底部文本区域和 @exec{racket} 命令行程序（不带选项启动时）
都充当一种计算器。你输入一个 Racket 表达式，按 Return 键，答案就会
被打印出来。用 Racket 的术语来说，这种计算器被称为
@idefterm{读取-求值-打印循环}或 @deftech{REPL}。

一个数字本身就是一个表达式，答案就是该数字：

@interaction[5]

字符串也是一种求值为自身的表达式。字符串用双引号
写在开头和结尾：

@interaction["Hello, world!"]

Racket 使用括号来包裹较大的表达式——除了简单常量之外的几乎任何
类型的表达式。例如，函数调用写作：左括号、函数名、参数表达式
和右括号。以下表达式调用内置函数 @racket[substring]，参数为
@racket["the boy out of the country"]、@racket[4] 和 @racket[7]：

@interaction[(substring "the boy out of the country" 4 7)]

@; ----------------------------------------------------------------------
@section{Definitions and Interactions}

你可以通过 @racket[define] 形式定义自己的函数，使其像
@racket[substring] 一样工作，如下所示：

@def+int[
#:eval piece-eval
(define (extract str)
  (substring str 4 7))
(extract "the boy out of the country")
(extract "the country out of the boy")
]

尽管你可以在 @tech{REPL} 中对 @racket[define] 形式求值，但
定义通常是你希望保留并稍后使用的程序的一部分。因此，在
DrRacket 中，你通常会将定义放在顶部文本区域——称为
@deftech{定义区}——以及 @hash-lang[] 前缀：

@racketmod[
racket
code:blank
(define (extract str)
  (substring str 4 7))
]

如果调用 @racket[(extract "the boy")] 是程序主要操作的一部分，那么
它也应该放在 @tech{定义区} 中。但如果它只是你用来探索
@racket[extract] 的一个示例表达式，那么你更可能保留上述的
@deftech{定义区}，点击 @onscreen{Run}，然后在 @tech{REPL} 中
对 @racket[(extract "the boy")] 求值。

当使用命令行 @exec{racket} 而非 DrRacket 时，你会用你喜欢的编辑器将
上述文本保存到文件中。如果你将其保存为
@filepath{extract.rkt}，然后在同一目录中启动 @exec{racket}，
你可以对以下序列求值：

@margin-note{如果你使用 @racketmodname[xrepl]，可以使用
  @(link-element "plainlink" (litchar ",enter extract.rkt") `(xrepl "enter"))。}

@interaction[
#:eval piece-eval
(eval:alts (enter! "extract.rkt") (void))
(extract "the gal out of the city")
]

@racket[enter!] 形式既加载代码，又将求值上下文切换到模块内部，
就像 DrRacket 的 @onscreen{Run} 按钮一样。

@; ----------------------------------------------------------------------
@section{Creating Executables}

如果你的文件（或 DrRacket 中的 @tech{定义区}）包含

@racketmod[
racket

(define (extract str)
  (substring str 4 7))

(extract "the cat out of the bag")
]

那么它就是一个完整的程序，运行时打印 ``cat''。你可以在
DrRacket 中运行该程序，也可以在 @exec{racket} 中使用
@racket[enter!] 运行，但如果程序保存在 @nonterm{src-filename} 中，
你还可以通过命令行运行它：

@commandline{racket @nonterm{src-filename}}

要将程序打包为可执行文件，你有以下几个选项：

@itemize[

 @item{在 DrRacket 中，你可以选择 @menuitem["Racket" "Create
       Executable..."] 菜单项。}

 @item{在命令行提示符下，运行 @exec{raco exe
       @nonterm{src-filename}}，其中 @nonterm{src-filename} 包含
       该程序。更多信息见 @secref[#:doc '(lib
       "scribblings/raco/raco.scrbl") "exe"]。}

 @item{在 Unix 或 Mac OS 上，你可以通过在文件最开头插入以下行
       将程序文件转换为可执行脚本：

       @margin-note{关于脚本文件的更多信息见 @secref["scripts"]。}

        @verbatim[#:indent 2]{#! /usr/bin/env racket}

       同时，在命令行上使用 @exec{chmod +x
       @nonterm{filename}} 将文件权限改为可执行。

       只要 @exec{racket} 在用户的可执行搜索路径中，脚本就能工作。
       或者，可以在 @tt{#!} 之后使用 @exec{racket} 的完整路径
       （在 @tt{#!} 和路径之间留一个空格），这样用户的
       可执行搜索路径就不重要了。}

]

@; ----------------------------------------------------------------------
@section[#:tag "use-module"]{A Note to Readers with Lisp/Scheme Experience}

如果你已经了解一些 Scheme 或 Lisp 的知识，你可能会想直接把

@racketblock[
(define (extract str)
  (substring str 4 7))
]

放入 @filepath{extract.rktl}，然后用以下方式运行 @exec{racket}：

@interaction[
#:eval piece-eval
(eval:alts (load "extract.rktl") (void))
(extract "the dog out")
]

这确实可以工作，因为 @exec{racket} 愿意模拟传统的
Lisp 环境，但我们强烈反对使用
@racket[load] 或在模块之外编写程序。

在模块之外编写定义会导致糟糕的错误消息、
糟糕的性能以及笨拙的脚本来组合和运行程序。这些问题
并非 @exec{racket} 特有；它们是传统顶层环境的根本限制，
Scheme 和 Lisp 实现历史上一直通过临时的命令行标志、编译器指令和
构建工具来应对。模块系统旨在避免这些问题，所以从
@hash-lang[] 开始，长期来看你会对 Racket 更加满意。

@; ----------------------------------------------------------------------

@close-eval[piece-eval]
