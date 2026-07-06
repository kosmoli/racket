#lang scribble/doc

@(require scribble/manual
          scribble/bnf
          "common.rkt"
         (for-label racket
                    setup/dirs
                    setup/getinfo
                    setup/main-collects
                    setup/collection-name
                    setup/matching-platform
                    setup/language-family
                    scribble/core
                    scribble/base
                    scribble/decode
                    (only-in scribble/manual-struct
                             index-desc)
                    (only-in scribble/html-properties
                             body-id
                             document-source)
                    ;; info -- no bindings from this are used
                    (only-in info)
                    (only-in ffi/unsafe ffi-lib)
                    racket/path
                    setup/collects
                    compiler/compiler
                    launcher/launcher
                    racket/runtime-path
                    pkg/path
                    scribblings/main/contents))

@title[#:tag "setup-info"]{使用 @filepath{info.rkt} 文件控制 @exec{raco setup}}

为了将集合的文件编译为字节码，@exec{raco setup} 使用
@racket[compile-collection-zos] 过程。该过程反过来
会查阅集合的 @filepath{info.rkt} 文件（如果存在），以获取
编译该集合的具体指令。参见
@racket[compile-collection-zos] 了解它使用的
@filepath{info.rkt} 字段的更多信息，参见 @secref["info.rkt"]
了解 @filepath{info.rkt} 文件格式的信息。

Additional fields are used by the
@seclink["top" #:doc '(lib "pkg/scribblings/pkg.scrbl") "Racket package manager"]
and are documented in @secref["metadata" #:doc '(lib "pkg/scribblings/pkg.scrbl")].
The @exec{raco test} command also recognizes additional fields, which are
documented in @secref["test-config-info" #:doc '(lib "scribblings/raco/raco.scrbl")].

可选的 @filepath{info.rkt} 字段触发 @exec{raco setup} 的其他操作：

@itemize[

 @item{@as-index{@racketidfont{scribblings}} : @racket[(listof (cons/c string? list?))] ---
   要构建的文档列表。列表中的每个文档本身
   表示为一个列表，其中每个文档的列表以字符串开头，
   该字符串是文档源文件的集合相对路径。
   文档名称（默认从源模块的名称派生）旨在与
   包名或模块名一样全局唯一。参见 @secref["doc-info"]
   了解 @racketidfont{scribblings} 值的更多信息。
   在 @exec{raco setup} 渲染文档之前，文档的
   主 @racket[part] 会以多种方式进行调整；
   参见 @secref["doc-adjust"]。}

 @item{@as-index{@racketidfont{release-note-files}} : @racket[(listof (cons/c string? (cons/c string? list?)))] ---
   要从主文档页面链接的发布说明文本文件列表。
   每个说明本身表示为一个列表，该列表可以指定与主说明
   分组的辅助说明。

   @racketidfont{release-note-files} 条目必须是一个
   可以从匹配以下 @racket[_entry] 语法的表达式生成的值：

   @racketgrammar*[
     #:literals (list)
     [entry (list note ...)]
     [doc (list label-string note-path)
          (list label-string note-path order-integer)
          (list label-string note-path order-integer
                (list sub-note ...))]
     [sub-note (list label-string note-path)]
   ]

   The @racket[_order-integer] is used to order notes and defaults to @racket[0].}

 @item{@indexed-racket[racket-launcher-names] : @racket[(listof string?)]
   --- @elemtag["racket-launcher-names"] 要在安装的可执行文件目录中生成的可执行文件名列表，
   用于运行该集合实现的基于 Racket 的程序。必须通过
   @racket[racket-launcher-libraries] 或
   @racket[racket-launcher-flags] 提供并行的库名列表。

   对于每个名称，使用 @racket[make-racket-launcher] 设置
   一个启动可执行文件。参数为 @Flag{l-} 和
   @tt{@nonterm{colls}/.../@nonterm{file}}，其中 @nonterm{file} 是
   @racket[racket-launcher-libraries] 命名的文件，
   @tt{@nonterm{colls}/...} 是 @filepath{info.rkt} 文件的集合
   （和子集合）。

   In addition,

   @racketblock[
    (build-aux-from-path
     (build-path (collection-path #,(nonterm "colls") _...) #,(nonterm "suffixless-file")))
   ]

   被提供给 @racket[make-racket-launcher] 的可选 @racket[_aux] 参数
   （用于图标等），其中
   @nonterm{suffixless-file} 是去掉后缀的 @nonterm{file}。

   如果提供了 @racket[racket-launcher-flags]，它将作为
   传递给 @exec{racket} 的命令行参数列表，取代
   上述默认值，允许任意命令行参数。如果
   @racket[racket-launcher-flags] 与
   @racket[racket-launcher-libraries] 一起指定，则 flags 将覆盖
   libraries，但 libraries 仍可用于为
   @racket[build-aux-from-path] 指定名称
   （以查找如图标文件等相关信息）。}

 @item{@indexed-racket[racket-launcher-libraries] : @racket[(listof
   path-string?)] --- 与 @elemref["racket-launcher-names"]{@racket[racket-launcher-names]} 并行的库名列表。}

 @item{@indexed-racket[racket-launcher-flags] : @racket[(listof string?)]
   --- 与 @elemref["racket-launcher-names"]{@racket[racket-launcher-names]} 并行的命令行标志列表。}

 @item{@indexed-racket[mzscheme-launcher-names],
   @racket[mzscheme-launcher-libraries] 和
   @racket[mzscheme-launcher-flags] --- @racket[racket-launcher-names] 等的向后兼容变体。}

 @item{@indexed-racket[gracket-launcher-names] : @racket[(listof string?)]  ---
   @elemtag["gracket-launcher-names"] 类似于
   @elemref["racket-launcher-names"]{@racket[racket-launcher-names]}，
   但用于基于 GRacket 的可执行文件。启动器名称列表与
   @racket[gracket-launcher-libraries] 和
   @racket[gracket-launcher-flags] 并行处理。}

 @item{@indexed-racket[gracket-launcher-libraries] : @racket[(listof path-string?)]
   --- 与 @elemref["gracket-launcher-names"]{@racket[gracket-launcher-names]} 并行的库名列表。}

 @item{@indexed-racket[gracket-launcher-flags] : @racket[(listof string?)] --- A
   list of command-line flag lists, in parallel to
   @elemref["gracket-launcher-names"]{@racket[gracket-launcher-names]}.}

 @item{@indexed-racket[mred-launcher-names],
   @racket[mred-launcher-libraries] 和
   @racket[mred-launcher-flags] --- @racket[gracket-launcher-names] 等的向后兼容变体。}

 @item{@indexed-racket[copy-foreign-libs] : @racket[(listof (and/c
   path-string? relative-path?))] --- 要复制到 @racket[ffi-lib] 查找外部库的
   目录中的文件。如果定义了 @racket[install-platform]，
   则仅当当前平台匹配该定义时才复制文件。

   在 Mac OS 上，当复制 Mach-O 文件时，如果复制的文件
   包含以 @litchar{@"@"loader_path/} 开头的库引用，
   并且引用的库在 @racket[(get-lib-search-dirs)] 列出的路径中
   的不同位置存在，则库引用会被更新为绝对路径。

   在 Unix 上，当复制 ELF 文件时，如果复制的文件包含
   @litchar{$ORIGIN} 的 RPATH 设置，并且文件被安装到
   用户特定位置，则文件的 RPATH 会调整为
   @litchar{$ORIGIN:} 后跟 @racket[(find-lib-dir)] 报告的
   主安装库目录的路径。

   在 Windows 上，如果外部库正在使用中，文件锁可能会使删除
   先前安装的外部库变得复杂。作为补偿，
   @exec{raco setup} 通过首先将文件重命名为带
   @filepath{raco-setup-delete-} 前缀来删除外部库文件；然后
   尝试删除重命名后的文件，如果删除失败则仅发出警告。
   同时，在 @exec{raco setup} 移除未安装库的模式中，
   它会尝试删除外部库目录中名称以
   @filepath{raco-setup-delete-} 开头的任何文件
   （以尝试清理之前失败的残留）。}

 @item{@indexed-racket[move-foreign-libs] : @racket[(listof (and/c
   path-string? relative-path?))] --- 类似于 @racket[copy-foreign-libs]，
   但原始文件在复制后被移除（这对于预编译包有意义）。}

 @item{@indexed-racket[copy-shared-files] : @racket[(listof (and/c
   path-string? relative-path?))] --- 要复制到共享文件所在目录的文件。
   如果定义了 @racket[install-platform]，
   则仅当当前平台匹配该定义时才复制文件。

   在 Windows 上，未安装的文件以与
   @racket[copy-foreign-libs] 相同的方式删除，名称前缀
   @filepath{raco-setup-delete-} 同样具有特殊含义。}

 @item{@indexed-racket[move-shared-files] : @racket[(listof (and/c
   path-string? relative-path?))] --- 类似于 @racket[copy-shared-files]，
   但原始文件在复制后被移除（这对于预编译包有意义）。}

 @item{@indexed-racket[copy-man-pages] : @racket[(listof (and/c
   path-string? relative-path? filename-extension))] --- 要复制到 @tt{man} 目录的文件。
   文件后缀决定其类别；例如，@litchar{.1}
   应用于描述可执行文件的 @tt{man} 页面。

   在 Windows 上，未安装的文件以与
   @racket[copy-foreign-libs] 相同的方式删除，名称前缀
   @filepath{raco-setup-delete-} 同样具有特殊含义。}

 @item{@indexed-racket[move-man-pages] : @racket[(listof (and/c
   path-string? relative-path? filename-extension))] --- 类似于 @racket[copy-man-pages]，但原始文件
   在复制后被移除（这对于预编译包有意义）。}

 @item{@indexed-racket[install-platform] : @racket[platform-spec?]
   如果此规范匹配当前平台，则与此包关联的外部
   库将被复制或移动到有用位置。参见
   @racket[copy-foreign-libs]、@racket[move-foreign-libs]、
   @racket[copy-shared-files] 和 @racket[move-shared-files]。
   另请参见 @racket[matching-platform?] 了解规范如何与
   @racket[(system-type)] 和 @racket[(system-library-subpath #f)] 进行比较的信息。}

 @item{@indexed-racket[install-collection] : @racket[path-string?] ---
   一个相对于集合的库模块，提供
   @racket[installer]。@racket[installer] 过程必须接受
   一个、两个、三个或四个参数：

   @itemlist[

   @item{第一个参数是 Racket 安装的 @filepath{collects} 目录父目录
   的目录路径。}

   @item{第二个参数（如果接受）是集合自身目录的路径。}

   @item{第三个参数（如果接受）是一个布尔值，指示
   集合是作为用户特定 (@racket[#t])
   还是安装范围 (@racket[#f]) 安装。}

   @item{第四个参数（如果接受）是一个布尔值，指示
   集合是否作为安装范围安装但仍应避免修改安装；
   不接受此参数的 @racket[installer] 过程在参数为
   @racket[#t] 时永远不会被调用。接受此参数的 installer
   会在 @racket[#t] 时被调用，以便它可以执行用户特定的工作，
   即使集合已安装为安装范围。}

   ]}

 @item{@indexed-racket[pre-install-collection] : @racket[path-string?] ---
   类似于 @racket[install-collection]，但相应的
   installer 过程在正常 @filepath{.zo} 构建 @emph{之前} 调用，
   而非之后。提供的过程是
   @racket[pre-installer]，因此它可以由
   提供 @racket[installer] 过程的同一文件提供。}

 @item{@indexed-racket[post-install-collection] : @racket[path-string?]  ---
   类似于 @racket[install-collection]，用于在 @racket[install-collection]
   过程执行之后立即调用的过程。
   @DFlag{no-install} 标志可以提供给 @exec{raco setup}
   以禁用 @racket[install-collection] 和 @racket[pre-install-collection]，
   但不能禁用 @racket[post-install-collection]。因此，
   @racket[post-install-collection] 函数应执行始终需要的操作，
   即使在包含预编译文件的安装之后也是如此。
   提供的过程是 @racket[post-installer]，因此它可以由
   提供 @racket[installer] 过程的同一文件提供。}

 @item{@indexed-racket[assume-virtual-sources] : @racket[any/c] ---
   真值表示没有相应源文件的字节码文件不应从
   @filepath{compiled} 目录中删除，并且在向
   @exec{raco setup} 传递 @DFlag{clean} 或 @Flag{c} 标志时，
   不应删除任何文件。}

 @item{@indexed-racket[clean] : @racket[(listof path-string?)] ---
   @elemtag["clean"] 当 @DFlag{clean} 或 @Flag{c} 标志传递给 @exec{raco setup} 时要删除的路径名列表。
   路径名必须相对于集合。如果任何路径命名了
   目录，则目录中的每个文件都会被删除，但不会检查
   目录的任何子目录。如果路径命名了文件，
   则删除该文件。如果未指定此标志，则默认删除
   @filepath{compiled} 子目录中的所有文件，
   以及当前平台的 compiled 目录中
   平台特定子目录中的所有文件。

   正如编译 @filepath{.zo} 文件会编译已编译模块使用的每个模块，
   删除模块的编译镜像也会删除该模块使用的每个模块的
   @filepath{.zo}。更具体地说，在删除
   @filepath{.dep} 文件时确定使用的模块，该文件是在
   @filepath{.zo} 由 @exec{raco setup} 或 @exec{raco make} 构建时
   创建的，伴随 @filepath{.zo} 文件
   （参见 @secref["Dependency\x20Files"]）。如果 @filepath{.dep} 文件
   指示了另一个模块，则仅当该模块也有伴随的
   @filepath{.dep} 文件时才删除其 @filepath{.zo}。在这种情况下，
   @filepath{.dep} 文件被删除，并根据已使用模块的
   @filepath{.dep} 文件删除其他使用的模块，以此类推。
   向 @exec{raco setup} 提供特定的集合列表会禁用此基于依赖的
   已编译文件删除。}

 @item{@racket[compile-omit-paths], @racket[compile-omit-files], and
   @racket[compile-include-files] --- 通过 @racket[compile-collection-zos] 间接使用。}

 @item{@racket[module-suffixes] and @racket[doc-module-suffixes] ---
   通过 @racket[get-module-suffixes] 间接使用。}

 @item{@indexed-racket[language-family] --- 一个哈希表列表，
   其中每个哈希表描述一个 @tech{语言系列}。参见
   @secref["lang-fam"] 了解每个哈希表内容的信息。

   @history[#:added "9.0.0.11"]}

 @item{@indexed-racket[main-doc-index] --- 一个集合名称（在 @racket[collection-name?] 的意义上）或
   集合名称列表，当在未指定 @DFlag{avoid-main} 的情况下
   指定了 @DFlag{doc-index} 时，将添加到
   @exec{raco setup} 请求中。

   @history[#:added "9.0.0.11"]}

 @item{@indexed-racket[user-doc-index] --- 一个集合名称（在 @racket[collection-name?] 的意义上）或
   集合名称列表，当在未指定 @DFlag{no-user} 的情况下
   指定了 @DFlag{doc-index} 时，将添加到
   @exec{raco setup} 请求中。

   @history[#:added "9.0.0.11"]}

]

@; ----------------------------------------
@section[#:tag "doc-info"]{@filepath{info.rkt} 文件中的文档描述}

@racketidfont{scribblings} 条目在 @secref["setup-info"] 中介绍时
形式为 @racket[(listof (cons/c string? list?))]，但更精确地说，它必须是
可以从匹配以下 @racket[_entry] 语法的表达式生成的值：

@racketgrammar*[
  #:literals (list)
  [entry (list doc ...)]
  [doc (list src-string)
       (list src-string flags)
       (list src-string flags category)
       (list src-string flags category name)
       (list src-string flags category name out-k)
       (list src-string flags category name out-k order-n)]
  [flags (list mode-symbol ...)]
  [category (list category-name)
            (list category-name sort-number)
            (list category-name sort-number lang-fam)]
  [category-name symbol
                 string
                 (box string)]
  [lang-fam (list string ...)]
  [name string
        #f]
]

文档条目 @racket[_doc] 必须至少有一个 @racket[_src-string]，
并可选地包含关于如何构建文档的信息。
如果文档列表包含第二个条目 @racket[_flags]，
它必须是一个模式符号列表（下面描述）。
如果文档列表包含第三个条目 @racket[_category]，
它必须是一个对文档进行分类的列表（下面进一步描述）。
如果文档列表包含第四个条目 @racket[_name]，
它是要用于生成文档的名称，取代默认的源文件名
（不含扩展名），其中 @racket[#f] 表示使用默认值；
@racket[_name] 的非 @racket[#f] 值必须符合由
@racket[collection-name-element?] 检查的集合名称元素语法。
如果文档列表包含第五个条目 @racket[_out-k]，它用作
文档交叉引用信息使用的文件数量的提示；见下文。
如果文档列表包含第四个条目 @racket[_order-n]，
它用作渲染顺序的提示；见下文。

@racket[_flags] 中的每个模式符号可以是以下之一，
其中只有 @racket['multi-page] 是常用的：

@itemize[

  @item{@racket['multi-page] : 生成多页 HTML 输出，
        而非默认的单页格式。}

  @item{@racket['main-doc] : 表示生成的
        文档应写入主安装目录，而非用户特定目录。
        对于自身位于主安装中的集合，此模式是默认值。}

  @item{@racket['user-doc] : 表示生成的
        文档应写入用户特定目录。
        对于自身不在主安装中的集合，此模式是默认值。}

  @item{@racket['depends-all] : 表示如果任何其他文档被重建，
        该文档也应被重建---除了具有 @racket['no-depend-on] 标志的文档。}

  @item{@racket['depends-all-main] : 表示如果安装到主安装中的
        任何其他文档被重建，该文档也应被重建---
        除了具有 @racket['no-depend-on] 标志的文档。}

  @item{@racket['depends-all-user] : 表示如果安装到用户空间中的
        任何其他文档被重建，该文档也应被重建---
        除了具有 @racket['no-depend-on] 标志的文档。}

  @item{@racket['depend-family] : 表示如果注册的语言系列集合发生变化，
        文档应被重建。此标志通常应与
        @racket['depends-all]、@racket['depends-all-main] 或
        @racket['depends-all-user] 结合使用；如果与
        @racket['depends-all-main] 结合，则仅依赖于主安装中的
        语言系列。 }

  @item{@racket['always-run] : 每次运行 @exec{raco setup} 时都构建文档，
        即使其依赖项没有任何变化。}

  @item{@racket['no-depend-on] : 将该文档从其他依赖项的
        考虑中移除。此外，从该文档到其他文档的引用始终是
        直接的，而非潜在的间接引用（即在文档查看时解析，
        并可能重定向到远程站点）。}

  @item{@racket['main-doc-root] : 指定主安装的根文档。
        当前具有此模式的文档应该是唯一具有此模式的文档。}

  @item{@racket['user-doc-root] : 指定用户特定文档目录的根文档。
        当前具有此模式的文档应该是唯一具有此模式的文档。}

  @item{@racket['keep-style] : 保持文档样式不变，
        而非强制使用手册文档样式。}

  @item{@racket['no-search] : 构建文档时不包含搜索框。}

  @item{@racket['every-main-layer] : 与 @racket['main-doc] 一起使用时，
        表示文档应在每个安装层单独渲染
        (see @secref["layered-install"])。}

]

@racket[_category] 列表指定如何在根目录中显示文档，
以及对于 @racket[_lang-fam] 部分，如何对文档内容进行分类以用于搜索。 这些信息可以通过文档主 @racket[part] 的 @racket[tag-prefix]
中的 @racket['doc-properties] 表进行扩展或覆盖，
但首先考虑 @racket[_category] 本身：

@itemlist[

   @item{@racket[_category] 列表必须以 @racket[_category-name] 开头，
   它决定手册在文档列表（如根文档页面）中出现的位置。
   类别是符号、字符串或盒装字符串。如果是字符串或盒装字符串，
   则字符串是根页面上的类别标签
   （当文档的 @tech{语言系列} 包含用于列表的语言系列时，
   根文档页面使用 @racket["Racket"]）。如果是符号，则它应该是
   下列类别之一：

   @itemize[

     @item{@racket['getting-started] : 高级入门文档，以与其他类别标题
        相同的级别排版。}

     @item{@racket['core] : 语言系列的核心参考或库，可通过
        @racket[_lang-fam] 指定。}

     @item{@racket['racket-core] : Racket 的核心参考或库。此类别通常应由
        主 Racket 发行版中的特定包使用。当为
        @racket["Racket"] 以外的 @tech{语言系列} 渲染列表时，
        这些文档出现在 @racket['library] 之后而不是
        @racket['core] 之后。}

     @item{@racket['teaching] : 教学语言或库的文档。如果
        @racket['racket-core] 被移到后面，此类别中的文档
        出现在 @racket['language] 之后。}

     @item{@racket['language] : 知名编程语言的文档。如果
        @racket['racket-core] 被移到后面，此类别中的文档
        紧接在 @racket['racket-core] 之后、
        @racket['teaching] 之前出现。}

     @item{@racket['tool] : 可执行程序的文档。}

     @item{@racket['gui-library] : GUI 和图形库的文档。}

     @item{@racket['net-library] : 网络库的文档。}

     @item{@racket['parsing-library] : 解析库的文档。}

     @item{@racket['tool-library] : 编程工具库的文档（即对于更突出的
           @racket['tool] 类别来说不够重要）。}

     @item{@racket['interop] : 互操作性工具和库的文档。}

     @item{@racket['drracket-plugin] : DrRacket 插件的文档。}

     @item{所有按 @racket[string<=?] 排序的字符串和盒装字符串类别
        在这一点上相对于其他类别出现。}

     @item{@racket['library] : 杂项库的文档。}

     @item{所有其 @tech{语言系列} 不包含当前语言系列的文档
        在这一点上出现，至少对于大多数类别是这样。 Documents are ordered by @racket[string<=?]
        on the first family name; within a language family, they are
        ordered as in a documentation listing for that language
        family. A document whose category is @racket['language],
        @racket['teaching], @racket['experimental], @racket['legacy],
        or @racket['racket-core] is always listed independent of its
        language family, however.

        Unless a document's category is a boxed string, the label used
        for the category in this section is prefixed by the first
        family name in the document's families. A boxed string avoid
        this prefixing.}

     @item{@racket['legacy] : 已弃用的库、语言和工具的文档。}

     @item{@racket['experimental] : 实验性语言或库的文档。}

     @item{@racket['other] : 其他文档。}

     @item{@racket['omit] : 不应在根页面列出或为搜索建立索引的文档。}

     @item{@racket['omit-start] : 不应在根页面列出但应为搜索建立索引的文档。}

   ]

   如果未提供 @racket[_category] 列表，或者类别符号无法识别，
   则文档被添加到 (@racket['library]) 类别。}

   @item{如果类别列表有第二个元素 @racket[_sort-number]，它必须是一个实数，
   指定手册在类别中的排序位置；具有相同排序位置的手册
   按字母顺序排列。对于排序编号为 @racket[_n] 和 @racket[_m]
   的两个手册，如果 @racket[(truncate (/ _n 10))]
   和 @racket[(truncate (/ _m 10))] 不同，
   则手册组之间用空格分隔。}

   @item{如果类别列表有第三个元素 @racket[_lang-fam]，则它
   必须是一个字符串列表，其中每个字符串命名一个语言系列。
   @racket[_lang-fam] 的默认值为 @racket[(list "Racket")]。
   此 @tech{语言系列} 列表用于组织所有文档的列表，
   也用于从文档中提取并用于搜索的索引条目。
   对于索引条目，文档、文档内的部分或单个索引条目
   可以指定自己的语言系列，@racket[_lang-fam]
   仅为未另行指定语言系列的条目提供默认值。}

   @item{如果文档的主 @racket[part] 有一个 @racket[tag-prefix]
   哈希表将 @racket['doc-properties] 映射到另一个哈希表，
   则内部哈希表可以覆盖和泛化 @racket[_category] 列表：

   @itemlist[

    @item{如果 @racket['language-family] 被映射到一个字符串列表，
    它为 @racket[_lang-fam] 提供替换。}

    @item{如果 @racket['category] 被映射到一个哈希表
    @racket[_cat-ht]，它用于获取特定于某个 @tech{语言系列} 的
    @racket[_category] 替换。如果 @racket[_cat-ht]
    将列表的语言系列名映射到一个列表，则该列表用于
    @racket[_category]。否则，如果 @racket[_cat-ht] 将
    @racket['default] 映射到一个列表，则该列表用于替换
    @racket[_category]。在任何情况下，替换列表不能
    包含 @racket[_lang-fam] 组件；
    @racket['language-family] mapping (as described in the previous
    bullet) is the only way to replace a @racket[_lang-fam] component.}

   ]}

]

@racket[_out-k] 规范是一个提示，指示是否将
文档的交叉引用信息分成多个部分，这可以减少
解析文档中交叉引用的时间和内存使用。
它必须是一个正的精确整数，默认值为 @racket[1]。

@racket[_order-n] 规范是文档构建顺序的提示，
因为文档引用可以是相互递归的。
顺序提示可以是任何实数。值为 @racket[-10] 或更小
会禁用与其他文档并行运行该文档。
主 Racket 参考被赋予 @racket[-11] 的值，
搜索页面被赋予 @racket[10] 的值，默认值为 @racket[0]。

预渲染文档的目录从源文件名计算，
从 @filepath{info.rkt} 文件的目录开始，
添加 @filepath{doc}，然后使用文档名称
（通常是源文件名去掉后缀）；
如果这样的目录存在且没有 @filepath{synced.rktd} 文件，
则将其视为预渲染文档并移到适当位置，
在这种情况下文档源文件不需要存在。
将文档移到适当位置可能根本不需要移动，
这取决于外围集合的安装方式，
但移动包括添加 @filepath{synced.rktd} 文件来表示安装。

渲染文档的目标位置取决于外围集合是 Racket 安装的一部分，
还是作为用户 @tech[#:doc '(lib "pkg/scribblings/pkg.scrbl")]{package scope} 中的包安装。
当文档在用户范围内时，它在包内的相同位置渲染，
与预渲染文档的位置相同。例外情况是当文档
在 @racketidfont{scribblings} 中声明了
@racket['depends-all]、@racket['depends-all-main] 或
@racket['depends-all-user] 且没有 @racket['every-main-layer] 时；
在这种情况下，它在更中心的位置渲染
（且不以预渲染形式包含），作为
@secref["doc-listing"] 中描述的策略的一部分。

如果文档主 @racket[part]'s 有一个作为哈希表的 @racket[tag-prefix]，
如果该哈希表将 @racket['doc-properties] 映射到另一个哈希表，
并且内部表将 @racket['supplant] 映射到一个字符串，
则 @exec{raco setup} 将渲染后的 @filepath{index.html}
复制到由 @racket['supplant] 字符串命名的兄弟目录。
此步骤在 @exec{raco setup} 文档渲染阶段结束时执行，
旨在支持 @secref["doc-listing"] 中描述的文档列表。

@history[#:changed "6.4" @elem{Allow a category to be a string
                              instead of a symbol.}
         #:changed "8.9.0.6" @elem{Add the @racket['drracket-plugin]
                                   category symbol.}
         #:changed "8.14.0.5" @elem{Added optional @racket[_lang-fam]
                                    within @racket[_category].}
         #:changed "9.0.0.11" @elem{Added support for @racket['depend-family]
                                    and for @racket['doc-properties]
                                    in a document's main @racket[part] and for
                                    boxed-string category names.}]

@section[#:tag "doc-adjust"]{文档设置调整}

在 @exec{raco setup} 渲染文档之前，其主 @racket[part]
会以多种方式进行调整：

@itemlist[

  @item{@racket[part] 的 @racket[tag-prefix] 字段被调整为
  以命名文档的模块路径作为其 @racket['tag-prefix]，
  这意味着其他文档可以通过 @racket[secref] 或
  @racket[other-doc] 引用渲染后的文档。}

  @item{如果 @racket[part] 的 @racket[tag] 字段中尚不存在
  @racket['(part "top")] 标签，则添加它。}

  @item{如果尚不存在 @racket[document-version] 样式属性，
  则使用 @racket[(version)] 添加它。}

  @item{如果尚不存在 @racket[body-id] 样式属性，
  则使用 @racket["doc-racket-lang-org"] 添加它。}

  @item{使用文档的模块路径添加 @racket[document-source] 样式属性。}

  @item{添加 @racket['show-language-family] 样式属性。}

  @item{默认的 @tech{语言系列} 被确定为
  @racket[scribblings] 条目中 @racket[_category] 的 @racket[_lang-fam]，
  或者（如果不存在）@racket[part] 的 @racket[tag-prefix]
  作为哈希表中 @racket['default-language-family] 键的值
  （可能最初提供给 @racket[title]）。 That list of strings, if either, is added as
  @racket['language-family] to a new table that is paired with
  @racket['index-extras] (if any) already in the table. That way,
  @racket[_category] or the main @racket[part] of a document can
  supply the default language family for all index entries
  generated from the document.}

  @item{When the @racket[part]'s @racket[tag-prefix] is a hash table with
  @racket['doc-properties] mapped to a hash table value, the value
  is recorded for cross references using the tag
  @racket[`(doc-properties "top")] combined with the document's
  module path. This addition allows a @racket['doc-properties]
  table to configure the document's listing in more general ways
  than a @racket[_category] specification within
  @racketidfont{scribblings} as described in @secref["doc-info"].}

]

文档的渲染可以在渲染器级别进一步调整
（参见 @secref["renderer" #:doc '(lib
"scribblings/scribble/scribble.scrbl")]），
包括 CSS 或 LaTeX 级别的配置。


@section[#:tag "lang-fam"]{文档语言系列}

@defmodule[setup/language-family]

@history[#:added "9.0.0.11"]

@deftech{语言系列} 是文档中使用的一种分类，
影响搜索结果的显示和过滤方式，
也影响文档在所有文档列表中的分类和显示方式。
语言系列不仅仅是基于模块的语言，
而是代表共享模块命名约定的一组语言。
根据经验，一个语言系列足够独特，
可能有自己的可下载发行版。

语言系列以多种方式和位置声明和使用：

@itemlist[

 @item{Racket 安装配置了一个默认语言系列，
 默认为 @racket["Racket"]；参见 @racket[get-main-language-family]。
 此默认值用于主文档列表，
 也用于文档搜索页面作为默认语言系列。}

 @item{集合中 @filepath{info.rkt} 文件中的
 @racketidfont{language-family} 定义可以声明一个语言系列。
 此声明用于渲染文档中列出导航用的语言系列，
 并由 @seclink["docs"]{@exec{raco docs}} 用于将语言系列名称
 映射到文档入口点和导航配置。

 A @racketidfont{language-family} definition's value is a list of hash
 tables, where each table can have the following keys:

 @itemlist[

  @item{@racket['family]: 作为字符串的语言系列名称---技术上可选，但实际上必需。}

  @item{@racket['describe-doc]: 描述语言系列或其代表语言的文档源的模块路径。 If @racket['describe-doc] is not mapped, then
  @racket['doc] (if mapped) is used for the description document, or
  else no description link is provided for the language family.}

  @item{@racket['start-doc]: 语言系列或其代表语言的起始文档的模块路径。 If
  @racket['start-doc] is not mapped, then @racket['doc] (if mapped) is
  used for the starting document. If neither @racket['start-doc] nor
  @racket['doc] is mapped, but @racket['family-root] is present, then
  @racket['family-root] determines the starting page. If none of those
  keys are mapped, a default starting page is used.}

  @item{@racket['doc]: 当 @racket['describe-doc] 和/或 @racket['start-doc]
  未映射时使用的文档模块路径。}

  @item{@racket['order]: 一个实数，用于将系列相对于其他系列排序
  （数值越高在列表中越靠前，Racket 语言为 @racket[100]，
  默认为 @racket[0]）。}

  @item{@racket['family-root]: The name of the document (if any) that
  should be considered the starting listing for the language family,
  so that ``top'' and ``up'' navigations arrive at this document. It
  must be a document with the @racket['main-doc] style and also a
  @racket['user-doc] plus @racket['supplant] in the
  @racket['doc-properties] table in @racket[tag-prefix] for the
  document's main @racket[part].}

 ]}

 @item{通过 @exec{raco setup} 渲染的每个常规文档声明一个语言系列列表。
 文档在每个该系列中都被考虑，
 用于生成列表、优先排序搜索结果或过滤搜索结果。 A document's language
 family can be declared by the @racket[_lang-fam] part of the
 document's @racketidfont{scribblings} entry in an @filepath{info.rkt}
 file (see @secref["doc-info"]), or it can be declared with the
 document source via the document's main @racket[part], and
 specifically within the @racket[tag-prefix] of the part. The default
 is normally @racket[(list "Racket")], but the analog of
 @racket[title] for Rhombus's Scribble dialect injects @racket[(list
 "Rhombus")] by default, for example. Individual index entries in a
 document, which correspond to different results that can be shown by
 a search, can specify their own language families, so a document that
 bridges languages can declare different language families for
 different parts of the document; per-entry information is in a
 @racket[index-desc], where a function like @racket[index] picks up
 configuration via @tech[#:doc '(lib
 "scribblings/scribble/scribble.scrbl")]{part context}.}

 @item{通过 @hash-lang[] 使用的基于模块的语言可以指定一个语言系列，
 用于从编程环境导航到文档。 See @racket[’documentation-language-family] in
 @seclink["sec:documentation-language-family"
          #:doc '(lib "scribblings/tools/tools.scrbl")
          #:indirect? #t]{DrRacket's documentation} for more information.}

]

HTML 的导航和搜索可以在查看时（而非渲染时）通过查询参数适应语言系列：

@itemlist[

  @item{@tt{fam}: 一个语言系列，通常是大写名称如
  @litchar{Racket} 或 @litchar{Rhombus}。此查询参数调整
  搜索结果的优先排序和打印，但不过滤这些结果。}

  @item{@tt{famroot}: A document name, normally a case-folded name
  like @litchar{rhombus}, representing an entry point for a language
  family. This query parameter adjust the document to be reached by
  following ``up'' or ``top'' links while navigating documents, and it
  is used only when a @tt{fam} query is also present.}
  
]

@defproc[(get-language-families [#:user? user? any/c #t]
                                [#:namespace namespace (or/c #f namespace?) #f])
         (listof hash?)]{

 在 @filepath{info.rkt} 文件中查找 @racketidfont{language-family} 声明，
 并返回格式良好的条目的哈希表。@racket[user?] 参数决定是否包含
 用户范围的声明以及安装范围的声明。
 @racket[namespace] 参数被传递给 @racket[get-info/full]。

}

@section[#:tag "doc-listing"]{渲染文档列表}

@defmodule[scribblings/main/contents]

@history[#:added "9.0.0.11"]

@defproc[(build-contents [#:user? user? any/c #f]
                         [#:supplant supplant (or/c #f string?) #f]
                         [#:style style (or/c style? #f string? symbol? (listof symbol?)) #f]
                         [#:main-language-family language-family string? (get-main-language-family)]
                         [#:title-content title-content content? (list language-family
                                                                       (element (style #f '(aux)) " Documentation"))]
                         [#:self-path self-path (or/c #f path-string?) #f]
                         [#:bug-url bug-url (or/c #f string?) #f]
                         [#:default-category default-category list? '(language)]
                         [#:doc-properties doc-properties hash? (make-default-doc-properties
                                                                 main-family
                                                                 default-category
                                                                 supplant)]
                         [#:default-language-family default-language-family (or/c #f (nonempty-listof string?)) #f]
                         [#:version doc-version (or/c #f string?) #f]
                         [#:date doc-date (or/c #f string?) #f])
           pre-part?]{

创建一个文档的内容，从 @racket[main-family] 的角度列出所有已安装的文档。

@racket[language-family] 参数选择用于渲染文档的语言系列
（即与列出文档的语言系列进行比较），
而 @racket[default-language-family] 参数指定
文档列表为自身声明的语言系列。

按如下方式使用此函数：

@itemlist[

 @item{创建一个子集合（例如
  @filepath{my-language/scribblings/main}），其中包含一个 @filepath{info.rkt}
  文件，以及该子集合的一个子集合（例如
  @filepath{my-language/scribblings/main/user}），
  带有自己的 @filepath{info.rkt} 文件。每层将有一个文档。}

 @item{In the outer subcollection, create a document (say,
   @filepath{my-language.scrbl}) that renders on the assumption that
   it's in installation scope (i.e., the @racket[user?] argument to
   @racket[build-contents] should be @racket[#f]). This is the
   document that @racket[secref] might reasonably refer to, in case
   that's useful. Make sure that the document is listed in
   @racketidfont{scribblings} for the subcollection's
   @filepath{info.rkt}, and include the @racket['depends-all] or
   @racket['depends-all-main] flag and the @racket['no-depend-on]
   flag.}

 @item{In the nested collection, create another document (say,
   @filepath{user-my-language.scrbl}) that also has the flags
   @racket['user-doc], @racket['depends-all-user], and
   @racket['no-depend-on] in the nested subcollection's
   @filepath{info.rkt} as @racketidfont{scribblings}. Use the category
   @racket['(omit)]. The document should render as in user scope
   (i.e., the @racket[user?] argument to @racket[build-contents]
   should be @racket[#t]). If the containing package is in
   installation scope, this document will be rendered only when there
   are some other user-scope documents installed. This documentation
   generally should @emph{not} be the target of a cross-reference,
   because it won't always get rendered.}

 @item{In the latter document (perhaps
   @filepath{user-my-language.scrbl}), include the @racket['supplant]
   key in a @racket['doc-properties] table in @racket[tag-prefix] for
   the document's main @racket[part]. The value of @racket['supplant]
   should be the name of the destination for the former document
   (perhaps @filepath{my-language}). A @exec{raco setup} that builds
   documentation will arrange for the @filepath{index.html} of the
   supplanting document to be added or to overrwite
   @filepath{index.html} for the supplanted document. That way, when
   user-scope documentation exists at all, there will be a user-scope
   document using the name of the main document, whether or not the
   main document would render into user scope. It's also important
   that a @racket['depends-all] flag puts a document in the user-scope
   root documentation directory, instead of keeping it in the
   installed package's directory.}

 @item{In the outer subcollection's @filepath{info.rkt}, include a
   @racketidfont{main-doc-index} entry with the subcollection's own
   name. That entry cases the document to be rerendered when packages
   are installed. Putting the document in a fresh subcollection
   minimize the work that this rebuild triggers.}

 @item{In the nested subcollection's @filepath{info.rkt}, include a
   @racketidfont{user-doc-index} entry with the subcollection's own
   name.}

]

}

@defproc[(make-default-doc-properties [#:language-family language-family string? (get-main-language-family)]
                                      [#:default-category default-category list? '(language)]
                                      [#:supplant supplant (or/c #f string?) #f])
         hash?]{

构造一个适用于 @racket[build-contents]
@racket[#:doc-properties] 参数的哈希表。

}
