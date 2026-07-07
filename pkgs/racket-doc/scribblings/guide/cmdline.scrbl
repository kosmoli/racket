#lang scribble/manual
@(require (only-in xrepl/doc-utils [cmd xreplcmd])
          "guide-utils.rkt")

@(define xrepl-doc '(lib "xrepl/xrepl.scrbl"))

@title[#:tag "cmdline-tools"]{Command-Line Tools}

Racket 作为其标准分发的一部分，提供了一些命令行工具，可以让 Racket 编程更加舒适。

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@include-section["compile.scrbl"] @; raco

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{Interactive evaluation}

Racket REPL 提供了现代交互式环境所期望的一切。例如，它提供 @xreplcmd{enter} 命令以便在指定模块上下文中运行 REPL，以及 @xreplcmd{edit} 命令可将编辑器（由 @envvar{EDITOR} 环境变量指定）调用来编辑所输入的文件。@xreplcmd{drracket} 命令可方便地使用您喜爱的编辑器编写代码，同时使用 DrRacket 来尝试运行。

更多信息请参见 @other-doc[xrepl-doc]。

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@section{Shell completion}

@exec{bash} 和 @exec{zsh} 的 Shell 自动补全分别在
@filepath{share/pkgs/shell-completion/racket-completion.bash} 和
@filepath{share/pkgs/shell-completion/racket-completion.zsh} 中可用。
要启用它，请在您的 @tt{.bashrc} 或 @tt{.zshrc} 中运行相应文件即可。

@filepath{shell-completion} 集合仅在 Racket Full 分发中可用。补全脚本也
@hyperlink["https://github.com/racket/shell-completion"]{在线可用}。
