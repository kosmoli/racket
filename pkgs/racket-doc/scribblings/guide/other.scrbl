#lang scribble/doc
@(require scribble/manual "guide-utils.rkt" scribblings/private/docname)

@title{More Libraries}

本指南仅涵盖了 Racket 语言以及在 @|Racket| 中记录的库。Racket 分发版中包含许多其他库。

@include-section["graphics.scrbl"]

@section{The Web Server}

@Web[] 描述了 Racket web 服务器，该服务器支持在 Racket 中实现的 servlet。

@section{Using Foreign Libraries}

@other-manual['(lib "scribblings/foreign/foreign.scrbl")] 描述了使用 Racket 访问通常被 C 程序使用的库的工具。

@section{And More}

@link["../index.html"]{Racket 文档} 列出了其他库的文档，包括作为包安装的库。运行 @exec{raco docs} 可查找在您系统上安装的且特定于您用户账户的库的文档。

@link["http://pkgs.racket-lang.org/"]{Racket 包目录}
@url{https://pkgs.racket-lang.org} 提供更多由 Racket 编程者贡献的可下载的包。@link["https://docs.racket-lang.org"]{在线 Racket 文档} 包含该目录中包的文档，每日更新。有关包的更多信息，请参见 @other-manual['(lib
"pkg/scribblings/pkg.scrbl")]。

@link["https://planet.racket-lang.org/"]{@|PLaneT|} 服务于使用旧包系统开发的包。Racket 包应使用较新的系统。
