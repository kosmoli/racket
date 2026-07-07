#lang scribble/doc
@(require scribble/manual "guide-utils.rkt")

@title[#:tag "compile"]{Compilation and Configuration: @exec{raco}}

@exec{raco}（「@bold{Ra}cket @bold{co}mmand」的缩写）程序为编译 Racket 程序和维护 Racket 安装提供了命令行接口，支持多种附加工具。

@itemize[

 @item{@exec{raco make} 将 Racket 源代码编译为字节码。

 例如，如果你有一个名为 @filepath{take-over-world.rkt} 的程序，
 并希望将其及其所有依赖项编译为字节码，以便更快加载，则运行

   @commandline{raco make take-over-the-world.rkt}

 字节码文件写入 @filepath{compiled} 子目录下的
 @filepath{take-over-the-world_rkt.zo}；@filepath{.zo} 是字节码文件的后缀。}


 @item{@exec{raco setup} 管理 Racket 安装，包括手动安装的包。

 例如，如果你创建了自己的名为 @filepath{take-over} 的 @techlink{collection}，
 并希望为该 collection 构建所有字节码和文档，则运行

   @commandline{raco setup take-over}}


 @item{@exec{raco pkg} 管理可通过 Racket 包管理器安装的 @tech{package}。

 例如，查看已安装包的列表运行：

    @commandline{raco pkg show}

 安装名为 @tt{<package-name>} 的新包运行：

    @commandline{raco pkg install <package-name>}

 有关包管理的更多详情见 @other-doc['(lib "pkg/scribblings/pkg.scrbl")]。}
]

有关 @exec{raco} 的更多信息，见 @other-manual['(lib
"scribblings/raco/raco.scrbl")]。
