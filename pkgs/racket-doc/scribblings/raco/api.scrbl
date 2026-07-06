#lang scribble/doc

@(require scribble/manual
          scribble/bnf
          "common.rkt"
          (for-label scheme/gui
                     compiler/compiler
                     compiler/sig
                     compiler/compiler-unit
                     compiler/option
                     compiler/option-unit
                     compiler/cm
                     dynext/compile-sig
                     dynext/link-sig
                     dynext/file-sig
                     launcher/launcher
                     compiler/module-suffix
                     setup/getinfo))

@title{原始编译 API}

@defmodule[compiler/compiler]{

@racketmodname[compiler/compiler] 库通过 Racket API 提供 @exec{raco make} 用于编译到字节码的功能。

@; ----------------------------------------------------------------------

@section[#:tag "api:zo"]{字节码编译}

@defproc[((compile-zos [expr any/c] [#:module? module? any/c #f] [#:verbose? verbose? any/c #f]) 
          [racket-files (listof path-string?)]
          [dest-dir (or/c path-string? #f 'auto)])
         void?]{

仅提供 @racket[expr] 时，返回一个用表达式 @racket[expr] 初始化的编译器，如下所述。

编译器接受一个 Racket 文件列表并将每个文件编译为字节码，将生成的字节码放置在 @racket[dest-dir] 指定的目录内的 @filepath{.zo} 文件中。如果 @racket[dest-dir] 为 @racket[#f]，则每个字节码结果放置在其源文件所在的同一目录中。如果 @racket[dest-dir] 为 @racket['auto]，则每个字节码文件放置在相对于源的 @filepath{compiled} 子目录中；必要时创建该目录。

如果 @racket[expr] 不是 @racket[#f]，则为编译后续提供的文件创建一个命名空间，并评估 @racket[expr] 以初始化创建的命名空间。例如，@racket[expr] 可能加载一组宏。此外，后续编译的每个表达式的展开时部分在编译前在命名空间中评估，以便在编译后续表达式时效果可见。

如果 @racket[expr] 为 @racket[#f]，则不创建编译命名空间（使用当前命名空间），并假设文件中的表达式独立编译（因此无需评估表达式的展开时部分来编译）。

通常，对于编译 @racket[module] 文件，@racket[expr] 为 @racket[#f]；对于编译包含顶层定义和表达式的文件，@racket[expr] 为 @racket[(void)]。

如果 @racket[module?] 为 @racket[#t]，则给定文件作为模块读取和编译（因此不依赖于当前命名空间的顶层环境）。

如果 @racket[verbose?] 为 @racket[#t]，则通过当前输出端口报告每个给定文件的输出文件。}


@defproc[(compile-collection-zos [collection string?] ...+
                                 [#:skip-path skip-path (or/c path-string? #f) #f]
                                 [#:skip-paths skip-paths (listof path-string?) null]
                                 [#:skip-doc-sources? skip-docs? any/c #f]
                                 [#:managed-compile-zo managed-compile-zo 
                                                       (path-string? . -> . void?)
                                                       (make-caching-managed-compile-zo)])
         void?]{

通过使用 @racket[managed-compile-zo] 将指定集合的文件编译为 @filepath{.zo} 文件。@filepath{.zo} 文件放置在集合的 @filepath{compiled} 目录中。

默认情况下，集合中所有扩展名为 @filepath{.rkt}、@filepath{.ss} 或 @filepath{.scm} 的文件都会被编译，子目录中所有此类文件也是如此；此类后缀的集合可全局扩展，如 @racket[get-module-suffixes] 中所述，@racket[compile-collection-zos] 识别 @racket['libs] 组中的后缀。但是，路径以 @racket[skip-path] 或 @racket[skip-paths] 中任一元素开头的任何文件或目录都会被跳过。("开头" 意味着简化后的完整路径 @racket[_p] 在 @racket[(simplify-path _p #f)] 之后的字节串形式以 @racket[(simplify-path skip-path #f)] 的字节串形式开头；并非每个 @racket[skip-path] 通常都应是完整路径。）

集合编译器读取集合的 @filepath{info.rkt} 文件（参见 @secref["info.rkt"]）以获取编译集合的进一步指令。使用以下字段：

@itemize[

 @item{@indexed-racket[name] : 集合作为字符串的名称，仅用于状态和错误报告。}

 @item{@indexed-racket[compile-omit-paths] : 路径和 @tech[#:doc reference-doc]{regexp values} 的列表，或 @racket['all]。在列表中，路径被视为不应编译的文件或不应编译其文件的目录，且其 @filepath{info.rkt} 文件应被 @exec{raco setup} 忽略；路径相对于集合（即包含 @filepath{info.rkt} 文件的目录）并且可以指代为子集合表示的子目录中的文件和目录。列表中的 regexp 相对于集合的文件和目录路径进行匹配（因此，例如，以 @litchar{^} 开头 regexp 以仅匹配直接集合中的路径，而非子集合中的路径）以将这些文件和目录排除在编译和 @exec{raco setup} 之外。值 @racket['all] 等效于指定集合中的所有文件和目录（以有效地忽略集合进行编译）。自动省略的文件和目录是 @filepath{compiled}、@filepath{doc} 以及名称以 @litchar{.} 开头的文件和目录。

       被其他文件所需的文件在编译需求文件的过程中始终被编译——即使所需文件列出在此字段中或字段的值为 @racket['all]。}

 @item{@indexed-racket[compile-omit-files] : 不编译的文件名（不含目录路径）列表，除了 @racket[compile-omit-paths] 的内容。不要使用此字段；它用于向后兼容。}

 @item{@indexed-racket[scribblings] : 列表的列表，每个列表以文档源的路径开头。参见 @secref["setup-info"] 了解更多信息。源（及其所需的文件）以与其他模块文件相同的方式编译，除非 @racket[skip-docs?] 为真值。}

 @item{@indexed-racket[compile-include-files] : 要编译的文件名（不含目录路径）列表，除了基于文件扩展名、在 @racket[scribblings] 中或被其他已编译文件 @racket[require] 而编译的文件。}

 @item{@racket[module-suffixes] 和 @racket[doc-module-suffixes] : 通过 @racket[get-module-suffixes] 间接使用。}

]

@history[#:changed "6.3" @elem{添加了对 @racket[compile-include-files] 的支持。}
         #:changed "7.8.0.8" @elem{将 @racket[skip-path] 的"开头"更改为包含精确匹配。}
         #:changed "8.1.0.5" @elem{添加了对 @racket[compile-omit-paths] 中正则表达式的支持。}]}


@defproc[(compile-directory-zos [path path-string?]
                                [info procedure?]
                                [#:verbose verbose? any/c #f]
                                [#:skip-path skip-path (or/c path-string? #f) #f]
                                [#:skip-paths skip-paths (listof path-string?) null]
                                [#:skip-doc-sources? skip-docs? any/c #f]
                                [#:managed-compile-zo managed-compile-zo 
                                                      (path-string? . -> . void?)
                                                      (make-caching-managed-compile-zo)])
         void?]{

类似于 @racket[compile-collection-zos]，但编译给定目录而非集合。@racket[info] 函数的行为类似于 @racket[get-info] 的结果以提供 @filepath{info.rkt} 字段，而不是使用目录中的 @filepath{info.rkt} 文件（如果有）。

@history[#:changed "7.8.0.8" @elem{将 @racket[info] 处理更改为对 @racket['compile-omit-paths] 使用 @racket[info]，忽略父目录和子目录中的任何 @filepath{info.rkt} 文件。}]}


@; ----------------------------------------------------------------------

@section[#:tag "module-suffix"]{识别模块后缀}

@defmodule[compiler/module-suffix]{@racketmodname[compiler/module-suffix] 库提供用于识别对应于 Racket 模块的文件后缀的函数，用于编译目录中的文件、运行目录中文件的测试等。后缀集合始终包括 @filepath{.rkt}、@filepath{.ss} 和 @filepath{.scm}，但它可以通过集合中的 @filepath{info.rkt} 配置全局扩展。}

@history[#:added "6.3"]

@defproc[(get-module-suffixes [#:group group (or/c 'all 'libs 'docs) 'all]
                              [#:mode mode (or/c 'preferred 'all-available 'no-planet 'no-user) 'preferred]
                              [#:namespace namespace (or/c #f namespace?) #f])
         (listof bytes?)]{

检查已安装集合的 @filepath{info.rkt} 文件（参见 @secref["info.rkt"]）以产生应识别为 Racket 模块的文件后缀列表。每个后缀报告为不包含后缀前 @litchar{.} 的字节串。

@racket[mode] 和 @racket[namespace] 参数传播到 @racket[find-relevant-directories] 以确定哪些集合目录可能配置后缀集合。因此，仅当运行 @exec{raco setup}（或触发 @exec{raco setup} 的软件包安装或更新）时才能可靠地找到后缀注册。

@racket[group] 参数确定结果是否包括所有注册的后缀、仅注册为通用库后缀的后缀或仅注册为文档后缀的后缀。通用库后缀集合始终包括 @filepath{.rkt}、@filepath{.ss} 和 @filepath{.scm}。文档后缀集合始终包括 @filepath{.scrbl}。

@filepath{info.rkt} 文件中的以下字段扩展后缀集合：

@itemize[

 @item{@indexed-racket[module-suffixes] : 对应于通用库模块后缀的字节串列表（不含必须出现在后缀前的 @litchar{.}）。列表中的非列表或非字节串元素被忽略。}

 @item{@indexed-racket[doc-module-suffixes] : 字节串列表，类似于 @racket[module-suffixes]，但用于文档模块。}

]}

@defproc[(get-module-suffix-regexp [#:group group (or/c 'all 'libs 'docs) 'all]
                                   [#:mode mode (or/c 'preferred 'all-available 'no-planet 'no-user) 'preferred]
                                   [#:namespace namespace (or/c #f namespace?) #f])
         byte-regexp?]{

返回一个 @tech[#:doc reference-doc]{regexp value}，匹配以 @racket[get-module-suffixes] 报告的后缀结尾的路径。该模式包含一个用于后缀的子模式（不含前导 @litchar{.}）。}


@; ----------------------------------------------------------------------

@section[#:tag "api:loading"]{加载编译器支持}

编译器单元通过 @racket[dynamic-require] 和 @racket[get-info] 按需加载某些工具。如果编译期间使用的命名空间与用于加载编译器的命名空间不同，或者设置了其他加载相关参数，则可以使用以下参数来恢复 @racket[dynamic-require] 的设置。

@defparam[current-compiler-dynamic-require-wrapper
          proc 
          ((-> any) . -> . any)]{

一个参数，其值是一个接受 thunk 以应用的过程。默认包装器在调用 thunk 之前设置当前命名空间（通过 @racket[parameterize]），使用最初实例化 @racket[compiler/compiler] 库的命名空间。}

@; ----------------------------------------------------------------------

@section[#:tag "api:options"]{编译器选项}

@defmodule[compiler/option]{

@racketmodname[compiler/option] 模块提供控制编译器行为的选项（参数形式）。

更多选项由 @racketmodname[dynext/compile] 和 @racketmodname[dynext/link] 库定义，它们控制用于通过 C 编译的实际 C 编译器和链接器。

@defboolparam[somewhat-verbose on?]{

参数的 @racket[#t] 值导致编译器打印其编译和生成的文件。默认值为 @racket[#f]。}

@defboolparam[verbose on?]{

参数的 @racket[#t] 值导致编译器打印有关其操作的详细消息。默认值为 @racket[#f]。}

@defboolparam[compile-subcollections on?]{

指定子集合是否由 @racket[compile-collection-zos] 编译的参数。默认值为 @racket[#t]。}


@; ----------------------------------------------------------------------

@section[#:tag "api:unit"]{编译器作为单元}

@; ----------------------------------------

@subsection{签名}

@defmodule[compiler/sig]

@defsignature/splice[compiler^ ()]{

包括 @racketmodname[compiler/compiler] 导出的所有名称。}

@defsignature/splice[compiler:option^ ()]{

包括 @racketmodname[compiler/option] 导出的所有名称。}


@; ----------------------------------------

@subsection{主编译器单元}

@defmodule[compiler/compiler-unit]

@defthing[compiler@ unit?]{

以单元形式提供 @racketmodname[compiler/compiler] 的导出，其中 C 编译器操作是单元的导入，尽管它们未被使用。

该单元导入 @racket[compiler:option^]、@racket[dynext:compile^]、@racket[dynext:link^] 和 @racket[dynext:file^]。它导出 @racket[compiler^]。}

@; ----------------------------------------

@subsection{选项单元}

@defmodule[compiler/option-unit]

@defthing[compiler:option@ unit?]{

以单元形式提供 @racketmodname[compiler/option] 的导出。它不导入任何签名，导出 @racket[compiler:option^]。}
