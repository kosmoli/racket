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

Many distributions of Vim ship with support for Scheme, which will mostly work
for Racket. Vim also ships with some special support for Racket.

The @tt{racket} filetype comes with
@itemlist[
  @item{syntax highlighting}
  @item{custom indentation for Racket forms}
  @item{and other support including comments and @tt{raco fmt}}
]

There is also support for several @seclink["top" #:doc '(lib "scribblings/raco/raco.scrbl")]{raco commands}
in the form of builtin @tt{compiler} plugins; see @tt{:help compiler} for more
information.

For information about older Vim versions, see @secref{vim-versions}.

@subsection[#:tag "vim-racket"]{Enhanced Racket Support}

Vim will detect your Racket files as Scheme out of the box. To get the
additional features of the Racket filetype, consider installing the
@tt{vim-racket} plugin from
@hyperlink["https://github.com/benknoble/vim-racket"]{benknoble/vim-racket}. It
enables auto-detection of Racket files on top of enhanced indentation and syntax
highlighting. Vim's default support comes from a subset of this plugin;
installing it yourself provides additional features.

The @tt{vim-racket} plugin detects the @tt{filetype} option based on the @(hash-lang)
line. For example:@itemlist[
    @item{A file starting with @code{#lang racket} or @code{#lang racket/base} has @tt{filetype} equal to @tt{racket}.}
    @item{A file starting with @code{#lang scribble/base} or @code{#lang scribble/manual} has @tt{filetype} equal to @tt{scribble}.}
]

The @tt{vim-racket} plugin comes with configuration for Racket and some other
standard Racket languages.

Many Racket languages still need syntax and indent support. If you create Vim
support for other Racket languages, please consider contributing them to
@hyperlink["https://github.com/benknoble/vim-racket"]{benknoble/vim-racket} so
other Vim users will benefit.

@subsection{Indentation}

If you use @secref{vim-racket} and Vim version 9 or greater, improved
indentation for the @tt{racket} filetype is configured out of the box.

Otherwise, you can manually enable indentation for Racket by setting both the
@tt{lisp} and @tt{autoindent} options in Vim. You will want to customize the
buffer-local @tt{lispwords} option to control how special forms are indented.
See @tt{:help 'lispwords'}. However, using @tt{lispwords} for indentation can be
limited and may not be as complete as what you can get in Emacs. You can also
use Dorai Sitaram's
@hyperlink["https://github.com/ds26gte/scmindent"]{scmindent} for better
indentation of Racket code. The instructions on how to use the indenter are
available on the website.

@subsection{Highlighting}

Syntax highlighting for Scheme and Racket is shipped with Vim on many platforms.
You will want to use the @tt{racket} filetype for the best syntax experience;
see @secref{vim-racket} for enhanced syntax highlighting for Racket languages.

The @hyperlink["http://www.vim.org/scripts/script.php?script_id=1230"]{Rainbow
Parenthesis} script for Vim can be useful for more visible parenthesis
matching.

@subsection{Structured Editing}

The @hyperlink["http://www.vim.org/scripts/script.php?script_id=2531"]{Slimv}
plugin has a paredit mode that works like paredit in Emacs. However, the plugin
is not aware of Racket. You can either set Vim to treat Racket as Scheme files
or you can modify the paredit script to load on @filepath{.rkt} files.

For a more Vim-like set of key-mappings, pair either of @itemlist[
    @item{@hyperlink["https://github.com/guns/vim-sexp"]{guns/vim-sexp}}
    @item{@hyperlink["https://github.com/benknoble/vim-sexp"]{benknoble/vim-sexp}}
]@margin-note{The @tt{benknoble/vim-sexp} fork is slightly more modern vimscript.}
with @hyperlink["https://github.com/tpope/vim-sexp-mappings-for-regular-people"]{tpope/vim-sexp-mappings-for-regular-people}.
The experience is on par with paredit, but more comfortable for the fingers.

@subsection{REPLs}

There are many general-purpose Vim + REPL plugins out there. Here are a few that
support Racket out of the box: @itemlist[
    @item{@hyperlink["https://github.com/rhysd/reply.vim"]{rhysd/reply.vim}}
    @item{@hyperlink["https://github.com/kovisoft/slimv"]{kovisoft/slimv}, if you are using the @tt{scheme} filetype}
    @item{@hyperlink["https://github.com/benknoble/vim-simpl"]{benknoble/vim-simpl}}
]

@subsection{Scribble}

Vim support for writing scribble documents is provided by
@hyperlink["https://github.com/benknoble/scribble.vim"]{benknoble/scribble.vim}.

@subsection{Miscellaneous}

If you are installing many Vim plugins (not necessary specific to Racket), we
recommend using a plugin that will make loading other plugins easier. There are
many plugin managers.

@hyperlink["https://github.com/tpope/vim-pathogen"]{Pathogen} is one plugin that
does this; using it, you can install new plugins by extracting them to
subdirectories in the @filepath{bundle} folder of your personal Vim files
(@filepath{~/.vim} on Unix, @filepath{$HOME/vimfiles} on MS-Windows).

With newer Vim versions, you can use the package system (@tt{:help packages}).

One relatively up-to-date reference on the various managers is
@hyperlink["https://vi.stackexchange.com/q/388/10604"]{What are the differences between the vim plugin managers?}.
The same site, @hyperlink["https://vi.stackexchange.com"]{Vi & Vim} is a great
place to get help from Vimmers.

@subsection[#:tag "vim-versions"]{Older Versions of Vim}

As of
@hyperlink["https://github.com/vim/vim/commit/9b03d3e75b4274493bbe76772d7b92238791964c"]{Version 9.0.0336},
Vim ships with runtime files from @secref{vim-racket}, but these exclude
filetype detection for the @tt{racket} filetype. If you are using this version
or versions newer than this you probably want to tweak the suggestions in this
document to use the @tt{racket} filetype instead of @tt{scheme}. You should also
consider installing the plugin yourself to get the latest changes, since Ben is
slow to sync changes upstream to Vim and since the plugin contains improved
filetype detection.

As of @hyperlink["https://github.com/vim/vim/commit/1aeaf8c0e0421f34e51ef674f0c9a182debe77ae"]{version 7.3.518},
Vim detects files with the extension @tt{.rkt} as having the
@tt{scheme} filetype. @hyperlink["https://github.com/vim/vim/commit/9cd91a1e8816d727fbdbf0b3062288e15abc5f4d"]{Version 8.2.3368}
added support for @tt{.rktd} and @tt{.rktl}.

In older versions, you can enable filetype detection of Racket
files as Scheme with the following:

@verbatim[#:indent 2]|{
if has("autocmd")
  autocmd filetypedetect BufReadPost *.rkt,*.rktl,*.rktd set filetype=scheme
endif
}|

If your Vim supports the ftdetect system, in which case it's likely new enough
to support Racket already, you can nevertheless put the following in
@filepath{~/.vim/ftdetect/racket.vim}
(@filepath{$HOME/vimfiles/ftdetect/racket.vim} on MS-Windows; see @tt{:help runtimepath}).

@verbatim[#:indent 2]|{
" :help ftdetect
" If you want to change the filetype only if one has not been set
autocmd BufRead,BufNewFile *.rkt,*.rktl,*.rktd setfiletype scheme
" If you always want to set this filetype
autocmd BufRead,BufNewFile *.rkt,*.rktl,*.rktd set filetype=scheme
}|

@; ------------------------------------------------------------

@section{Sublime Text}

The @hyperlink["https://sublime.wbond.net/packages/Racket"]{Racket package}
provides support for syntax highlighting and building for Sublime Text.
@; ------------------------------------------------------------

@section{Visual Studio Code}

The @hyperlink["https://marketplace.visualstudio.com/items?itemName=evzen-wybitul.magic-racket"]{Magic Racket}
extension provides Racket support including REPL integration and syntax highlighting in Visual Studio Code.
