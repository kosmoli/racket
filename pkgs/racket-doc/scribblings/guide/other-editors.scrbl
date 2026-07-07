#lang scribble/manual
@(require "guide-utils.rkt")

@title[#:tag "other-editors" #:style 'toc]{命令行工具与你选择的编辑器}
@; author["Vincent St-Amour" "Asumu Takikawa" "Jon Rafkind"]

虽然 DrRacket 是大多数人开始使用 Racket 的最简单方式，但许多 Racket 开发者更喜欢命令行工具和其他文本编辑器。Racket 发行版包含多个命令行工具，而流行的编辑器也包含或支持软件包以使其与 Racket 良好配合。

@local-table-of-contents[]

@; ------------------------------------------------------------
@include-section["cmdline.scrbl"]

@; ------------------------------------------------------------
@section{Emacs 编辑器}

Emacs 一直是 Lisp 和 Scheme 程序员的最爱，在 Racket 开发者中也很受欢迎。

@subsection{主要模式}

@itemlist[

 @item{@hyperlink["https://github.com/greghendershott/racket-mode"]{Racket mode} 为 Emacs 提供全面的语法高亮和 DrRacket 风格的 REPL 及缓冲区执行支持。

       Racket mode 可以通过 @hyperlink["https://melpa.org/"]{MELPA} 安装，也可以从 Github 仓库手动安装。}

 @item{@hyperlink["http://www.neilvandyke.org/quack/"]{Quack} 是 Emacs 的 @tt{scheme-mode} 的扩展，为 Racket 提供增强支持，包括 Racket 特有形式的高亮和缩进，以及文档集成。

       Quack 包含在 Debian 和 Ubuntu 仓库中，作为 @tt{emacs-goodies-el} 软件包的一部分。Gentoo 移植版也可用（名称为 @tt{app-emacs/quack}）。}

 @item{@hyperlink["http://www.nongnu.org/geiser/"]{Geiser} 提供一个编辑器与 Racket REPL 紧密集成的编程环境。习惯于 Slime 或 Squeak 等环境的程序员应该对 Geiser 感到熟悉。Geiser 需要 GNU Emacs 23.2 或更高版本。

       Quack 和 Geiser 可以一起使用，且能很好地互补。更多信息请参见 @hyperlink["http://www.nongnu.org/geiser/"]{Geiser 手册}。

       Debian 和 Ubuntu 的 Geiser 软件包名称为 @tt{geiser}。Gentoo 移植版也可用（名称为 @tt{app-emacs/geiser}）。}

 @item{Emacs 自带一个 Scheme 主要模式 @tt{scheme-mode}，虽然不如上述选项功能丰富，但编辑 Racket 代码的效果还算不错。但是，此模式不支持 Racket 特有形式。}

 @item{没有文档的 Racket 程序是不完整的。Neil Van Dyke 的 @hyperlink["http://www.neilvandyke.org/scribble-emacs/"]{Scribble Mode} 为 Emacs 提供 Scribble 支持。

       此外，@tt{texinfo-mode}（GNU Emacs 自带）和纯文本模式在编辑 Scribble 文档时效果良好。由于 Scribble 的语法与 Racket 差异较大，上述 Racket 主要模式不太适合此任务。}

]

@subsection{次要模式}

@itemlist[

 @item{@hyperlink["http://mumble.net/~campbell/emacs/paredit.el"]{Paredit} 是一个用于伪结构化编辑类 Lisp 语言程序的次要模式。除了提供高级 S-expression 编辑命令外，它还能防止你意外地使括号不匹配。

       Debian 和 Ubuntu 的 Paredit 软件包名称为 @tt{paredit-el}。}

 @item{@hyperlink["https://github.com/Fuco1/smartparens"]{Smartparens} 是一个用于编辑 s-expression、保持括号平衡等的次要模式。类似于 Paredit。}

 @item{@hyperlink["https://github.com/drym-org/symex.el"]{Symex} 是一种直观的模态（类似 Vim 的）代码编辑方式，以最少的按键操作完成编辑，构建在提供高级结构编辑功能的 DSL 之上，并与 Racket Mode 进行运行时集成。}

 @item{Alex Shinn 的 @hyperlink["http://synthcode.com/wiki/scheme-complete"]{scheme-complete} 提供智能的、上下文感知的代码补全。它还与 Emacs 的 @tt{eldoc} 模式集成，在 minibuffer 中提供实时文档。

       虽然此模式是为 @seclink["r5rs"]{@|r5rs|} 设计的，但它仍然对 Racket 开发有用。该工具不了解 Racket 标准库的大部分内容，在 Scheme 和 Racket 出现分歧的情况下，实时文档可能会有一些差异。}

 @item{@hyperlink["http://www.emacswiki.org/emacs/RainbowDelimiters"]{RainbowDelimiters} 模式根据括号和其他分隔符的嵌套深度为其着色。按嵌套深度着色使你更容易一眼看出哪些括号是匹配的。}

 @item{@hyperlink["http://www.emacswiki.org/emacs/ParenFace"]{ParenFace} 让你选择括号应以哪种字体面（字体、颜色等）显示。选择替代字体面可以使括号"淡化"。}

 @item{@hyperlink["https://github.com/countvajhula/mindstream"]{Mindstream} 让你随时进入交互式编程会话（类似于 DrRacket 的定义和交互工作流），从你提供的模板开始。会话具有隐式版本控制，让你可以自由实验而不必担心丢失工作，从临时的草稿缓冲区有机地成长为完整项目。}
]

@subsection{Evil Mode 专用包}

@itemlist[

 @item{@hyperlink["https://github.com/willghatch/emacs-on-parens"]{on-parens} 是 smartparens 动作的包装器，使其更好地与 evil-mode 的正常状态配合工作。}

 @item{@hyperlink["https://github.com/timcharper/evil-surround"]{evil-surround} 提供添加、删除和更改括号及其他分隔符的命令。}

 @item{@hyperlink["https://github.com/noctuid/evil-textobj-anyblock"]{evil-textobj-anyblock} 添加了一个文本对象，匹配最近的括号或其他分隔符对。}

]

@; ------------------------------------------------------------

@section{Vim 编辑器}

许多 Vim 发行版自带对 Scheme 的支持，大部分可以用于 Racket。Vim 还自带一些对 Racket 的特殊支持。

@tt{racket} 文件类型提供
@itemlist[
  @item{语法高亮}
  @item{Racket 形式的自定义缩进}
  @item{以及其他支持，包括注释和 @tt{raco fmt}}
]

还以内置 @tt{compiler} 插件的形式支持多个 @seclink["top" #:doc '(lib "scribblings/raco/raco.scrbl")]{raco 命令}；更多信息请参见 @tt{:help compiler}。

有关旧版 Vim 的信息，请参见 @secref{vim-versions}。

@subsection[#:tag "vim-racket"]{增强的 Racket 支持}

Vim 默认会将你的 Racket 文件检测为 Scheme。要获得 Racket 文件类型的额外功能，可以考虑从 @hyperlink["https://github.com/benknoble/vim-racket"]{benknoble/vim-racket} 安装 @tt{vim-racket} 插件。它在增强的缩进和语法高亮基础上启用了 Racket 文件的自动检测。Vim 的默认支持来自此插件的子集；自行安装可获得更多功能。

@tt{vim-racket} 插件根据 @(hash-lang) 行检测 @tt{filetype} 选项。例如：@itemlist[
    @item{以 @code{#lang racket} 或 @code{#lang racket/base} 开头的文件的 @tt{filetype} 为 @tt{racket}。}
    @item{以 @code{#lang scribble/base} 或 @code{#lang scribble/manual} 开头的文件的 @tt{filetype} 为 @tt{scribble}。}
]

@tt{vim-racket} 插件为 Racket 和其他一些标准 Racket 语言提供了配置。

许多 Racket 语言仍然需要语法和缩进支持。如果你为其他 Racket 语言创建了 Vim 支持，请考虑将其贡献给 @hyperlink["https://github.com/benknoble/vim-racket"]{benknoble/vim-racket}，以便其他 Vim 用户受益。

@subsection{缩进}

如果你使用 @secref{vim-racket} 且 Vim 版本为 9 或更高，@tt{racket} 文件类型的改进缩进已开箱即用。

否则，你可以通过在 Vim 中设置 @tt{lisp} 和 @tt{autoindent} 选项来手动启用 Racket 的缩进。你需要自定义 buffer-local 的 @tt{lispwords} 选项来控制特殊形式的缩进方式。参见 @tt{:help 'lispwords'}。然而，使用 @tt{lispwords} 进行缩进可能有限制，可能不如 Emacs 中那么完善。你也可以使用 Dorai Sitaram 的 @hyperlink["https://github.com/ds26gte/scmindent"]{scmindent} 来获得更好的 Racket 代码缩进。有关如何使用该缩进器的说明可在其网站上找到。

@subsection{高亮}

在许多平台上，Vim 自带 Scheme 和 Racket 的语法高亮。你会想要使用 @tt{racket} 文件类型以获得最佳语法体验；有关 Racket 语言的增强语法高亮，请参见 @secref{vim-racket}。

Vim 的 @hyperlink["http://www.vim.org/scripts/script.php?script_id=1230"]{Rainbow Parenthesis} 脚本有助于更明显地匹配括号。

@subsection{结构化编辑}

@hyperlink["http://www.vim.org/scripts/script.php?script_id=2531"]{Slimv} 插件有一个类似 Emacs 中 paredit 的 paredit 模式。但该插件不识别 Racket。你可以将 Vim 设置为将 Racket 视为 Scheme 文件，或者修改 paredit 脚本使其在 @filepath{.rkt} 文件上加载。

要获得更 Vim 风格的按键映射，将以下任一项与 @hyperlink["https://github.com/tpope/vim-sexp-mappings-for-regular-people"]{tpope/vim-sexp-mappings-for-regular-people} 搭配使用：@itemlist[
    @item{@hyperlink["https://github.com/guns/vim-sexp"]{guns/vim-sexp}}
    @item{@hyperlink["https://github.com/benknoble/vim-sexp"]{benknoble/vim-sexp}}
]@margin-note{@tt{benknoble/vim-sexp} 分支是稍微更现代的 vimscript。}
使用体验与 paredit 相当，但对手指更友好。

@subsection{REPL}

有很多通用的 Vim + REPL 插件。以下是几个开箱即用支持 Racket 的插件：@itemlist[
    @item{@hyperlink["https://github.com/rhysd/reply.vim"]{rhysd/reply.vim}}
    @item{@hyperlink["https://github.com/kovisoft/slimv"]{kovisoft/slimv}，如果你使用 @tt{scheme} 文件类型}
    @item{@hyperlink["https://github.com/benknoble/vim-simpl"]{benknoble/vim-simpl}}
]

@subsection{Scribble 支持}

Vim 编写 Scribble 文档的支持由 @hyperlink["https://github.com/benknoble/scribble.vim"]{benknoble/scribble.vim} 提供。

@subsection{杂项}

如果你要安装许多 Vim 插件（不一定是 Racket 专用的），我们建议使用一个能更方便加载其他插件的插件。有很多插件管理器可供选择。

@hyperlink["https://github.com/tpope/vim-pathogen"]{Pathogen} 就是这样一个插件；使用它，你可以通过将插件解压到个人 Vim 文件的 @filepath{bundle} 文件夹的子目录中来安装新插件（Unix 上为 @filepath{~/.vim}，MS-Windows 上为 @filepath{$HOME/vimfiles}）。

对于较新的 Vim 版本，你可以使用包管理系统（@tt{:help packages}）。

一个关于各种管理器的较新参考是 @hyperlink["https://vi.stackexchange.com/q/388/10604"]{What are the differences between the vim plugin managers?}。同一网站 @hyperlink["https://vi.stackexchange.com"]{Vi & Vim} 是向 Vim 用户寻求帮助的好地方。

@subsection[#:tag "vim-versions"]{旧版 Vim}

从 @hyperlink["https://github.com/vim/vim/commit/9b03d3e75b4274493bbe76772d7b92238791964c"]{Version 9.0.0336} 开始，Vim 自带来自 @secref{vim-racket} 的运行时文件，但这些文件不包含 @tt{racket} 文件类型的检测。如果你使用的是此版本或更新版本，你可能需要调整本文档中的建议，使用 @tt{racket} 文件类型代替 @tt{scheme}。你还应该考虑自行安装该插件以获取最新更改，因为 Ben 向上游 Vim 同步更改的速度较慢，且插件包含改进的文件类型检测。

从 @hyperlink["https://github.com/vim/vim/commit/1aeaf8c0e0421f34e51ef674f0c9a182debe77ae"]{version 7.3.518} 开始，Vim 将扩展名为 @tt{.rkt} 的文件检测为 @tt{scheme} 文件类型。@hyperlink["https://github.com/vim/vim/commit/9cd91a1e8816d727fbdbf0b3062288e15abc5f4d"]{Version 8.2.3368} 添加了对 @tt{.rktd} 和 @tt{.rktl} 的支持。

在较旧的版本中，你可以使用以下方式启用将 Racket 文件检测为 Scheme 的文件类型检测：

@verbatim[#:indent 2]|{
if has("autocmd")
  autocmd filetypedetect BufReadPost *.rkt,*.rktl,*.rktd set filetype=scheme
endif
}|

如果你的 Vim 支持 ftdetect 系统（这种情况下它可能已经足够新以支持 Racket），你仍然可以将以下内容放入 @filepath{~/.vim/ftdetect/racket.vim}（MS-Windows 上为 @filepath{$HOME/vimfiles/ftdetect/racket.vim}；参见 @tt{:help runtimepath}）。

@verbatim[#:indent 2]|{
" :help ftdetect
" If you want to change the filetype only if one has not been set
autocmd BufRead,BufNewFile *.rkt,*.rktl,*.rktd setfiletype scheme
" If you always want to set this filetype
autocmd BufRead,BufNewFile *.rkt,*.rktl,*.rktd set filetype=scheme
}|

@; ------------------------------------------------------------

@section{Sublime Text 编辑器}

@hyperlink["https://sublime.wbond.net/packages/Racket"]{Racket package} 为 Sublime Text 提供语法高亮和构建支持。
@; ------------------------------------------------------------

@section{Visual Studio Code 编辑器}

@hyperlink["https://marketplace.visualstudio.com/items?itemName=evzen-wybitul.magic-racket"]{Magic Racket} 扩展在 Visual Studio Code 中提供 Racket 支持，包括 REPL 集成和语法高亮。
