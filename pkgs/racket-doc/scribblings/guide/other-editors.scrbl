#lang scribble/manual
@(require "guide-utils.rkt")

@title[#:tag "other-editors" #:style 'toc]{命令行工具及你选择的编辑器}
@; author["Vincent St-Amour" "Asumu Takikawa" "Jon Rafkind"]

尽管 DrRacket 是大多数人入门 Racket 的最简便方式，许多 Racketeers 更喜欢命令行工具和其他文本编辑器。Racket 发行版包含多个命令行工具，流行的编辑器也包含或支持使其与 Racket 良好配合的 package。

@local-table-of-contents[]

@; ------------------------------------------------------------
@include-section["cmdline.scrbl"]

@; ------------------------------------------------------------
@section{Emacs}

Emacs 长期以来一直是 Lispers 和 Schemers 的最爱，在 Racketeers 中也很受欢迎。

@subsection{主要模式}

@itemlist[

 @item{@hyperlink["https://github.com/greghendershott/racket-mode"]{Racket mode}
       为 Emacs 提供全面的语法高亮和 DrRacket 风格的 REPL 及 buffer 执行支持。

       Racket mode 可通过 @hyperlink["https://melpa.org/"]{MELPA} 安装，也可从 Github 仓库手动安装。}

 @item{@hyperlink["http://www.neilvandyke.org/quack/"]{Quack} 是 Emacs
       @tt{scheme-mode} 的扩展，为 Racket 提供增强支持，包括 Racket 特有形式的语法高亮和缩进，以及文档集成。

       Quack 作为 @tt{emacs-goodies-el} package 的一部分包含在 Debian 和 Ubuntu 仓库中。还提供有 Gentoo port（名称为 @tt{app-emacs/quack}）。}

 @item{@hyperlink["http://www.nongnu.org/geiser/"]{Geiser} 提供一个编程环境，其中编辑器与 Racket REPL 紧密集成。习惯于 Slime 或 Squeak 等环境的程序员使用 Geiser 会感到得心应手。Geiser 需要 GNU Emacs 23.2 或更高版本。

       Quack 和 Geiser 可以一起使用，相互补充。更多信息请参见 @hyperlink["http://www.nongnu.org/geiser/"]{Geiser 手册}。

       Debian 和 Ubuntu 的 Geiser package 名称为 @tt{geiser}。还提供有 Gentoo port（名称为 @tt{app-emacs/geiser}）。}

 @item{Emacs 附带了用于 Scheme 的主要模式 @tt{scheme-mode}，虽然功能不如上述选项丰富，但用于编辑 Racket 代码效果尚可。但是，此模式不支持 Racket 特有的形式。}

 @item{没有文档的 Racket 程序是不完整的。Neil Van Dyke 的
       @hyperlink["http://www.neilvandyke.org/scribble-emacs/"]{Scribble
       Mode} 为 Emacs 提供 Scribble 支持。

       此外，@tt{texinfo-mode}（GNU Emacs 附带）和普通文本模式在编辑 Scribble 文档时效果很好。鉴于 Scribble 的语法与 Racket 的语法差异很大，上述 Racket 主要模式并不真正适合此任务。}

]

@subsection{次要模式}

@itemlist[

 @item{@hyperlink["http://mumble.net/~campbell/emacs/paredit.el"]{Paredit}
       是一种用于伪结构化编辑 Lisp 类语言程序的次要模式。除了提供高级 S-expression 编辑命令外，它还能防止你意外破坏括号平衡。

       Debian 和 Ubuntu 的 Paredit package 名称为 @tt{paredit-el}。}

 @item{@hyperlink["https://github.com/Fuco1/smartparens"]{Smartparens}
       是一种用于编辑 s-expression 的次要模式，保持括号平衡等。与 Paredit 类似。}

 @item{@hyperlink["https://github.com/drym-org/symex.el"]{Symex} 是一种
       使用最少按键编辑代码的直观 modal（类 Vim）方式，构建在提供高级结构化编辑功能的 DSL 之上，并与 Racket Mode 运行时集成。}

 @item{Alex Shinn 的
       @hyperlink["http://synthcode.com/wiki/scheme-complete"]{scheme-complete}
       提供智能、上下文敏感的代码补全。它还与 Emacs 的 @tt{eldoc} 模式集成，在 minibuffer 中提供实时文档。

       虽然此模式是为 @seclink["r5rs"]{@|r5rs|} 设计的，但它对 Racket 开发仍然有用。该工具不了解 Racket 标准库的大部分内容，在 Scheme 和 Racket 有差异的情况下，实时文档可能存在一些差异。}

 @item{@hyperlink["http://www.emacswiki.org/emacs/RainbowDelimiters"]{RainbowDelimiters}
       模式根据嵌套深度为括号和其他定界符着色。按嵌套深度着色使你可以一目了然地看出哪些括号匹配。}

 @item{@hyperlink["http://www.emacswiki.org/emacs/ParenFace"]{ParenFace}
       允许你选择括号应以哪种 face（字体、颜色等）显示。选择替代 face 可以使括号"弱化"显示。}

 @item{@hyperlink["https://github.com/countvajhula/mindstream"]{Mindstream}
       允许你随时进入交互式编程会话（类似于 DrRacket 的 Definitions 和 Interactions 工作流），从你提供的模板开始。会话隐式版本化，让你可以自由实验而不用担心丢失工作，从临时 scratch buffer 有机地成长为完整项目。}

]
@subsection{Evil Mode 专用 Package}

@itemlist[

 @item{@hyperlink["https://github.com/willghatch/emacs-on-parens"]{on-parens}
       是一个包装器，使 smartparens 动作更好地与 evil-mode 的 normal state 配合工作。}

 @item{@hyperlink["https://github.com/timcharper/evil-surround"]{evil-surround}
       提供添加、删除和更改括号及其他定界符的命令。}

 @item{@hyperlink["https://github.com/noctuid/evil-textobj-anyblock"]{evil-textobj-anyblock}
       添加一个 text-object，匹配任意括号或其他定界符对中最近的一个。}

]

@; ------------------------------------------------------------

@section{Vim}

许多 Vim 发行版附带了对 Scheme 的支持，这些支持大多适用于 Racket。Vim 还附带了一些对 Racket 的特殊支持。

@tt{racket} filetype 包含
@itemlist[
  @item{语法高亮}
  @item{为 Racket 形式自定义缩进}
  @item{以及其他支持，包括注释和 @tt{raco fmt}}
]

还有以内置 @tt{compiler} 插件形式提供的对多个 @seclink["top" #:doc '(lib "scribblings/raco/raco.scrbl")]{raco 命令} 的支持；详见 @tt{:help compiler}。

关于旧版 Vim 的信息，请参见 @secref{vim-versions}。

@subsection[#:tag "vim-racket"]{增强的 Racket 支持}

Vim 开箱即用会将 Racket 文件检测为 Scheme。要获取 Racket filetype 的附加功能，请考虑安装来自 @hyperlink["https://github.com/benknoble/vim-racket"]{benknoble/vim-racket} 的 @tt{vim-racket} 插件。它在增强的缩进和语法高亮之上启用 Racket 文件的自动检测。Vim 的默认支持来自此插件的一个子集；自行安装可提供附加功能。

@tt{vim-racket} 插件基于 @(hash-lang) 行检测 @tt{filetype} 选项。例如：@itemlist[
    @item{以 @code{#lang racket} 或 @code{#lang racket/base} 开头的文件，其 @tt{filetype} 等于 @tt{racket}。}
    @item{以 @code{#lang scribble/base} 或 @code{#lang scribble/manual} 开头的文件，其 @tt{filetype} 等于 @tt{scribble}。}
]

@tt{vim-racket} 插件附带 Racket 和其他一些标准 Racket 语言的配置。

许多 Racket 语言仍然需要语法和缩进支持。如果你为其他 Racket 语言创建 Vim 支持，请考虑将其贡献给 @hyperlink["https://github.com/benknoble/vim-racket"]{benknoble/vim-racket}，以便其他 Vim 用户受益。

@subsection{缩进}

如果你使用 @secref{vim-racket} 且 Vim 版本为 9 或更高，开箱即用即为 @tt{racket} filetype 配置了改进的缩进。

否则，你可以通过在 Vim 中设置 @tt{lisp} 和 @tt{autoindent} 选项来手动启用 Racket 的缩进。你可能需要自定义 buffer-local 的 @tt{lispwords} 选项来控制特殊形式的缩进方式。参见 @tt{:help 'lispwords'}。但是，使用 @tt{lispwords} 进行缩进可能有限，可能不如在 Emacs 中获得的完整。你也可以使用 Dorai Sitaram 的 @hyperlink["https://github.com/ds26gte/scmindent"]{scmindent} 来获得更好的 Racket 代码缩进。有关如何使用缩进器的说明可在网站上找到。

@subsection{高亮}

许多平台上 Vim 附带了 Scheme 和 Racket 的语法高亮。要获得最佳的语法体验，请使用 @tt{racket} filetype；有关 Racket 语言的增强语法高亮，请参见 @secref{vim-racket}。

Vim 的 @hyperlink["http://www.vim.org/scripts/script.php?script_id=1230"]{Rainbow Parenthesis} 脚本可用于更明显的括号匹配。

@subsection{结构化编辑}

@hyperlink["http://www.vim.org/scripts/script.php?script_id=2531"]{Slimv} 插件有一个 paredit 模式，其工作方式类似于 Emacs 中的 paredit。但是，该插件不了解 Racket。你可以将 Vim 设置为将 Racket 视为 Scheme 文件，也可以修改 paredit 脚本以在 @filepath{.rkt} 文件上加载。

对于更像 Vim 的键映射组合，将以下任一 @itemlist[
    @item{@hyperlink["https://github.com/guns/vim-sexp"]{guns/vim-sexp}}
    @item{@hyperlink["https://github.com/benknoble/vim-sexp"]{benknoble/vim-sexp}}
]@margin-note{@tt{benknoble/vim-sexp} fork 使用了稍微更现代的 vimscript。}
与 @hyperlink["https://github.com/tpope/vim-sexp-mappings-for-regular-people"]{tpope/vim-sexp-mappings-for-regular-people} 配对。
体验与 paredit 相当，但对手指更舒适。

@subsection{REPL}

有许多通用的 Vim + REPL 插件。以下是几个开箱即用支持 Racket 的：@itemlist[
    @item{@hyperlink["https://github.com/rhysd/reply.vim"]{rhysd/reply.vim}}
    @item{@hyperlink["https://github.com/kovisoft/slimv"]{kovisoft/slimv}，如果你使用的是 @tt{scheme} filetype}
    @item{@hyperlink["https://github.com/benknoble/vim-simpl"]{benknoble/vim-simpl}}
]

@subsection{Scribble}

用于编写 scribble 文档的 Vim 支持由 @hyperlink["https://github.com/benknoble/scribble.vim"]{benknoble/scribble.vim} 提供。

@subsection{杂项}

如果你要安装许多 Vim 插件（不一定特定于 Racket），我们推荐使用一个使加载其他插件更轻松的插件。有许多插件管理器。

@hyperlink["https://github.com/tpope/vim-pathogen"]{Pathogen} 就是这样一个插件；使用它，你可以通过将新插件解压到个人 Vim 文件的 @filepath{bundle} 文件夹的子目录中来安装新插件（Unix 上为 @filepath{~/.vim}，MS-Windows 上为 @filepath{$HOME/vimfiles}）。

对于较新的 Vim 版本，你可以使用 package 系统（@tt{:help packages}）。

关于各种管理器的一个相对最新的参考资料是 @hyperlink["https://vi.stackexchange.com/q/388/10604"]{vim plugin managers 之间有什么区别？}。同一站点 @hyperlink["https://vi.stackexchange.com"]{Vi & Vim} 是获得 Vimmers 帮助的好地方。

@subsection[#:tag "vim-versions"]{旧版 Vim}

截至 @hyperlink["https://github.com/vim/vim/commit/9b03d3e75b4274493bbe76772d7b92238791964c"]{Version 9.0.0336}，Vim 附带了来自 @secref{vim-racket} 的运行时文件，但这些文件排除了 @tt{racket} filetype 的 filetype 检测。如果你使用的是此版本或更新的版本，你可能需要调整本文档中的建议以使用 @tt{racket} filetype 而不是 @tt{scheme}。你还应该考虑自行安装插件以获取最新更改，因为 Ben 同步更改到 Vim 上游的速度较慢，并且插件包含改进的 filetype 检测。

截至 @hyperlink["https://github.com/vim/vim/commit/1aeaf8c0e0421f34e51ef674f0c9a182debe77ae"]{version 7.3.518}，Vim 将扩展名为 @tt{.rkt} 的文件检测为具有 @tt{scheme} filetype。@hyperlink["https://github.com/vim/vim/commit/9cd91a1e8816d727fbdbf0b3062288e15abc5f4d"]{Version 8.2.3368} 添加了对 @tt{.rktd} 和 @tt{.rktl} 的支持。

在旧版本中，你可以使用以下命令启用 Racket 文件作为 Scheme 的 filetype 检测：

@verbatim[#:indent 2]|{
if has("autocmd")
  autocmd filetypedetect BufReadPost *.rkt,*.rktl,*.rktd set filetype=scheme
endif
}|

如果你的 Vim 支持 ftdetect 系统，在这种情况下它可能已经足够新以支持 Racket，你仍然可以将以下内容放在 @filepath{~/.vim/ftdetect/racket.vim} 中（MS-Windows 上为 @filepath{$HOME/vimfiles/ftdetect/racket.vim}；参见 @tt{:help runtimepath}）。

@verbatim[#:indent 2]|{
" :help ftdetect
" 如果只想在尚未设置 filetype 时更改
autocmd BufRead,BufNewFile *.rkt,*.rktl,*.rktd setfiletype scheme
" 如果始终要设置此 filetype
autocmd BufRead,BufNewFile *.rkt,*.rktl,*.rktd set filetype=scheme
}|

@; ------------------------------------------------------------

@section{Sublime Text}

@hyperlink["https://sublime.wbond.net/packages/Racket"]{Racket package} 为 Sublime Text 提供语法高亮和构建支持。
@; ------------------------------------------------------------

@section{Visual Studio Code}

@hyperlink["https://marketplace.visualstudio.com/items?itemName=evzen-wybitul.magic-racket"]{Magic Racket} 扩展在 Visual Studio Code 中提供包括 REPL 集成和语法高亮在内的 Racket 支持。
