#lang scribble/doc
@(require scribble/manual scribblings/private/docname)

@title{入门}

要开始使用 Racket，请从网页 @hyperlink["http://racket-lang.org/download/"]{下载}并安装它。如果你是初学者或想使用图形环境来运行程序，请运行 @exec{DrRacket} 可执行文件。@margin-note*{如果你喜欢，也可以使用你喜欢的文本编辑器工作（参见 @secref["other-editors" #:doc '(lib "scribblings/guide/guide.scrbl")]）。}否则，@exec{racket} 可执行文件将运行一个命令行 Read-Eval-Print-Loop (@tech[#:doc '(lib "scribblings/guide/guide.scrbl")]{REPL})。

在 Windows 上，你可以从开始菜单中的 @onscreen{Racket} 条目启动 DrRacket。在 Windows Vista 或更高版本中，你可以直接键入 @exec{DrRacket}。你也可以从它的文件夹中运行它，你可以在 @onscreen{Program Files} → @onscreen{Racket} → @onscreen{DrRacket} 中找到它。

在 Mac OS 上，双击 @onscreen{DrRacket} 图标。它可能在你拖入的 @onscreen{Racket} 文件夹中的 @onscreen{Applications} 文件夹。如果你想使用命令行工具，相反，Racket 可执行文件在 @onscreen{Racket} 文件夹的 @filepath{bin} 目录中（参见 @hyperlink["https://github.com/racket/racket/wiki/Configure-Command-Line-for-Racket"]{配置 Racket 命令行} 以设置你的 @envvar{PATH} 环境变量）。

在 Unix（包括 Linux）上，如果你的分发版本创建了一个 @onscreen{DrRacket} 图标（许多环境都这样做），请双击它。如果你的 @exec{drracket} 可执行文件在你的路径中（如果你选择了 Unix 风格的分发版，可能就是这种情况），也可以直接从命令行运行它。否则，导航到安装 Racket 分发版的目录，@exec{drracket} 可执行文件将在 @filepath{bin} 子目录中。

如果你不熟悉编程，或者有耐心学习一本教科书：

@itemize[

 @item{@italic{@link["https://htdp.org/"]{How to Design Programs, Second Edition}}
       是最好的起点。}

 @item{@Continue[Continue-title] 教程向你介绍模块和构建
       网络应用程序。}

 @item{@other-manual['(lib "scribblings/guide/guide.scrbl")] 描述了
       Racket 语言的其余部分，比教科书的学习导向语言要大得多。由于你从教科书学习了函数式编程，你将能够浏览
       指南的第 1 和第 2 章。}

]


如果你已经是一名程序员并且更着急：

@itemize[

 @item{@Quick[Quick-title] 给你一种 Racket 的体验。}

 @item{@other-manual['(lib "scribblings/more/more.scrbl")] 深入得
       多且更快。如果太多，只需跳到指南。}

 @item{@other-manual['(lib "scribblings/guide/guide.scrbl")] 从
       Racket 基础的教程开始，然后描述了 Racket
       语言的其余部分。}

]


当然，你可以随意混合搭配上述两条轨道，因为每个轨道中都有一些其他轨道没有的信息。
