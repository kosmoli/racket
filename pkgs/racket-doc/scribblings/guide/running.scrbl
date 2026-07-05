#lang scribble/doc
@(require scribble/manual "guide-utils.rkt" (for-syntax racket/pretty))

@title[#:tag "running" #:style 'toc]{运行和创建可执行文件}

在开发程序时，许多 Racket 程序员使用
@seclink["top" #:doc '(lib "scribblings/drracket/drracket.scrbl")
#:indirect? #t]{DrRacket} 编程环境。要在没有开发环境的情况下运行程序，
请使用 @exec{racket}（用于控制台程序）或 @exec{gracket}（用于 GUI 程序）。本章主要
解释如何运行 @exec{racket} 和 @exec{gracket}。

@local-table-of-contents[]

@; ----------------------------------------------------------------------

@section[#:tag "racket"]{运行 @exec{racket} 和 @exec{gracket}}

@exec{gracket} 可执行文件与 @exec{racket} 相同，但进行了
使其作为 GUI 应用程序而不是控制台应用程序运行的小型调整。
例如，@exec{gracket} 默认在 GUI 窗口中以 interactive mode 运行，
而不是控制台提示符。不过，GUI 应用程序也可以使用普通的 @exec{racket} 运行。

根据命令行参数的不同，@exec{racket} 或 @exec{gracket}
可在 @seclink["start-interactive-mode"]{interactive mode}、
@seclink["start-module-mode"]{module mode} 或
@seclink["start-load-mode"]{load mode} 下运行。

@subsection[#:tag "start-interactive-mode"]{Interactive Mode}

当 @exec{racket} 在没有命令行参数的情况下运行时（除了
配置选项，如 @Flag{j}），它会启动一个带有 @litchar{> } 提示符的 @tech{REPL}：

@verbatim[#:indent 2]{
  @(regexp-replace #rx"\\n+" (banner) "")
  > 
}

@margin-note{要增强您的 @tech{REPL} 体验，请参见
  @racketmodname[xrepl]；有关 GNU Readline 支持的信息，请参见
  @racketmodname[readline]。}

为了初始化 @tech{REPL} 的环境，@exec{racket} 首先
requires @racketmodname[racket/init] module，它提供了
@racket[racket] 的所有 binding，并且还安装了 @racket[pretty-print] 用于显示
结果。最后，@exec{racket} 在启动 @tech{REPL} 之前加载由
@racket[(find-system-path 'init-file)] 报告的文件（如果存在）。

如果提供了任何命令行参数（除了配置
选项），添加 @Flag{i} 或 @DFlag{repl} 以重新启用
@tech{REPL}。例如，

@commandline{racket -e '(display "hi\\n")' -i}

在启动时显示 "hi"，但仍呈现 @tech{REPL}。

如果 module-requiring flags 出现在 @Flag{i}/@DFlag{repl} 之前，
它们会取消自动 require @racketmodname[racket/init]。此
行为可用于以不同的语言初始化 @tech{REPL} 的环境。例如，

@commandline{racket -l racket/base -i}

使用一个更小的初始语言来启动 @tech{REPL}（加载
速度更快）。请注意，大多数 module 不提供 Racket 的基本语法，
包括 function-call 语法和 @racket[require]。例如，

@commandline{racket -l racket/date -i}

会产生一个对所有表达式都会失败的 @tech{REPL}，
因为 @racketmodname[racket/date] 仅提供少量函数，不提供
需要在 @tech{REPL} 中求值顶层函数调用所必需的
@racket[#%top-interaction] 和 @racket[#%app] bindings。

如果 module-requiring flag 出现在 @Flag{i}/@DFlag{repl} 之后
而不是之前，则会在 @racketmodname[racket/init] 之后 require 该 module 以增强初始环境。例如，

@commandline{racket -i -l racket/date}

启动一个有用的 @tech{REPL}，除了 @racketmodname[racket] 的 exports 之外还可用 @racketmodname[racket/date]。

@; ----------------------------------------

@subsection[#:tag "start-module-mode"]{Module Mode}

如果在任何命令行 switch 之前向 @exec{racket} 提供了文件参数
（除了配置选项），则该文件会被作为 module 被 require，
并且（除非指定了 @Flag{i}/@DFlag{repl}），不会启动 @tech{REPL}。例如，

@commandline{racket hello.rkt}

require @filepath{hello.rkt} module 然后退出。文件名之后的任何参数
（无论是 flag 还是其他）都会作为命令行参数被保留，
供被 require 的 module 通过 @racket[current-command-line-arguments] 使用。

如果使用命令行 flags，则 @Flag{u} 或 @DFlag{require-script} flag 可用于显式地 require 文件
作为 module。@Flag{t} 或 @DFlag{require} flag 类似，区别在于
额外的命令行 flags 是由 @exec{racket} 处理的，
而不是保留给被 require 的 module。例如，

@commandline{racket -t hello.rkt -t goodbye.rkt}

require @filepath{hello.rkt} module，然后 require
@filepath{goodbye.rkt} module，然后退出。

@Flag{l} 或 @DFlag{lib} flag 类似于 @Flag{t}/@DFlag{require}，
但它使用 @racket[lib] module path 而不是文件路径来 require module。例如，

@commandline{racket -l raco}

与在没有参数的情况下运行 @exec{raco} 可执行文件相同，
因为 @racket[raco] module 是该可执行文件的主 module。

注意，如果您想要将命令行 flags 传递给
上面的 @racket[raco]，您需要使用 @Flag{-} 来保护 flags，
这样 @exec{racket} 就不会尝试自行解析它们：

@commandline{racket -l raco -- --help}

@; ----------------------------------------

@subsection[#:tag "start-load-mode"]{Load Mode}

@Flag{f} 或 @DFlag{load} flag 支持直接对文件中的顶层 expressions
进行 @racket[load]，与 module 文件中的 expressions 相对。
这种求值类似于启动一个 @tech{REPL} 并直接输入 expressions，
除了结果不会被打印。例如，

@commandline{racket -f hi.rkts}

@racket[load] @filepath{hi.rkts} 并退出。注意，load mode
通常是一个糟糕的选择，原因在 @secref["use-module"] 中有解释；
使用 module mode 通常更好。

@Flag{e} 或 @DFlag{eval} flag 接受要直接求值的 expression。
与文件加载不同，expression 的结果会被打印，
就像在 @tech{REPL} 中一样。例如，

@commandline{racket -e '(current-seconds)'}

打印自 1970 年 1 月 1 日以来的秒数。

对于文件加载和 expression 求值，顶层环境的创建方式与
@seclink["start-interactive-mode"]{interactive mode} 中的相同：
除非先指定了其他 module，否则 require @racketmodname[racket/init]。例如，

@commandline{racket -l racket/base -e '(current-seconds)'}

可能运行更快，因为它使用更小的 @racketmodname[racket/base] 语言来初始化用于求值的环境，
而不是 @racketmodname[racket/init]。

@; ----------------------------------------------------------------------

@include-section["scripts.scrbl"]

@; ----------------------------------------------------------------------

@section[#:tag "exe"]{创建独立可执行文件}

@(define raco-doc '(lib "scribblings/raco/raco.scrbl"))

有关创建和分发可执行文件的信息，请参见 @other-manual[raco-doc] 中的
@secref[#:doc raco-doc "exe"] 和 @secref[#:doc raco-doc "exe-dist"]。
