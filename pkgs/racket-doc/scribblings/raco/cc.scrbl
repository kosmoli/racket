#lang scribble/manual
@(require scribble/manual "common.rkt"
          (for-label scheme/base compiler/xform dynext/compile))

@(define (xflag str) (as-index (DFlag str)))
@(define (pxflag str) (as-index (DPFlag str)))

@title[#:tag "cc"]{编译和链接 C 扩展}

一个 @deftech{动态扩展}（dynamic extension）是一个共享库（即 DLL），它使用 C API 来扩展 Racket。扩展可以通过 @racket[load-extension] 显式加载，或者在替代源 @racket[_file] 位置处，当扩展被放置于以下路径时通过 @racket[require] 或 @racket[load/use-compiled] 隐式加载：

@racketblock[(build-path "compiled" "native" (system-library-subpath)
                        (path-add-suffix _file (system-type 'so-suffix)))]

相对于 @racket[_file]。

有关编写扩展的信息，请参见 @other-manual[inside-doc]。

@margin-note{@exec{raco ctool} 由 @filepath{cext-lib} 包提供。}

三种 @exec{raco ctool} 模式有助于构建扩展：

@itemize[

 @item{@DFlag{cc}：运行宿主系统的 C 编译器，自动提供标志以定位 Racket 头文件并编译为可在共享库中使用的目标文件。}

 @item{@DFlag{ld}：运行宿主系统的 C 链接器，自动提供标志以定位并链接 Racket 库，并生成共享库。}

 @item{@DFlag{xform}：将未显式编写 GC 协作钩子的 C 代码转换为可与 Racket 的 3m garbage collector 协作的代码；参见 @other-manual[inside-doc] 中的 @secref["overview"]。}

]

构建扩展基于 @racketmodname[dynext/compile] 和 @racketmodname[dynext/link] 库。以下 @exec{raco ctool} 标志对应于设置或访问这些库的参数：@xflag{tool}、@xflag{compiler}、@xflag{ccf}、@xflag{ccf-clear}、@xflag{ccf-show}、@xflag{linker}、@pxflag{ldf}、@xflag{ldf-clear}、@xflag{ldf-show}、@pxflag{ldl}、@xflag{ldl-show}、@pxflag{cppf}、@pxflag{cppf-clear} 和 @xflag{cppf-show}。

@as-index{@DFlag{3m}} 标志指定扩展要加载到 Racket 的 3m 变体中。@as-index{@DFlag{cgc}} 标志指定扩展要与 CGC 一起使用。默认值取决于 @exec{raco} 自身运行的变体：如果 @exec{raco} 在 3m 中运行，则默认为 @DFlag{3m}；如果在 CGC 中运行，则为 @DFlag{cgc}。

@section[#:tag "xform-api"]{API for 3m Transformation}

@defmodule[compiler/xform]

@defproc[(xform [quiet? any/c]
                [input-file path-string?]
                [output-file path-string?]
                [include-dirs (listof path-string?)]
                [#:keep-lines? keep-lines? boolean? #f])
         any/c]{

将未显式编写 GC 协作钩子的 C 代码转换为可与 Racket 的 3m garbage collector 协作的代码；参见 @other-manual['(lib "scribblings/inside/inside.scrbl")] 中的 @secref["overview"]。

参数与 @racket[compile-extension] 相同；此外，@racket[keep-lines?] 可以取 @racket[#t] 来生成 GCC 风格的注释，将生成的 C 代码与原始源位置连接起来。

由 @racket[xform] 生成的文件可以通过 @racket[compile-extension] 编译。}
