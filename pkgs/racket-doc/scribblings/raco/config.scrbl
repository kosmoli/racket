#lang scribble/doc
@(require scribble/manual
          "common.rkt"
          (for-label racket/base
                     racket/contract
                     setup/dirs
                     setup/getinfo))

@title[#:tag "config-file"]{安装配置与搜索路径}

@deftech{配置目录}路径在构建 Racket 可执行文件时被内置，由安装时选择决定，其位置可通过 @envvar{PLTCONFIGDIR} 环境变量或 @DFlag{config}/@Flag{G} 命令行标志修改。使用 @racket[find-config-dir] 来定位配置目录。

修改 @tech{配置目录}中的 @as-index{@filepath{config.rktd}} 文件，如下所述配置其他目录。使用 @racketmodname[setup/dirs] 库（它综合了配置文件和其他来源的信息）来定位已配置的目录，而不是直接读取 @filepath{config.rktd}。@filepath{config.rktd} 文件也可能出现在目录 @racket[(build-path (find-system-path 'addon-dir) "etc")] 中，但它仅控制 @racket[find-addon-tethered-console-bin-dir] 和 @racket[find-addon-tethered-gui-bin-dir] 的结果。

@deftech{主集合目录}路径被内置到 Racket 可执行文件中，它可以通过 @DFlag{collects}/@Flag{X} 标志修改，因此它在 @filepath{config.rktd} 中没有条目。@filepath{config.rktd} 中指定的大多数路径都有相对于主集合目录的默认值。@tech{配置目录}和@tech{主集合目录}的路径因此共同决定了 Racket 的配置。

配置目录中的 @filepath{config.rktd} 文件应包含一个 @racket[read] 可读的哈希表，带有以下任意符号键，其中相对路径是相对于@tech{主集合目录}的：

@itemlist[

 @item{@indexed-racket['installation-name] --- 安装名称的字符串，用于确定用户特定和版本特定的路径，例如 @racket[find-library-collection-paths] 产生的初始路径，以及安装在 @exec{user} @tech[#:doc '(lib "pkg/scribblings/pkg.scrbl")]{package scope} 中的包的位置。默认值是 @racket[(version)]。}

 @item{@indexed-racket['collects-search-dirs] --- 路径、字符串、字节字符串或 @racket[#f] 的列表，表示集合的搜索路径。列表中的每个 @racket[#f]（如果有）被替换为@tech{主集合目录}。}

 @item{@indexed-racket['lib-dir] --- @deftech{主库目录}的路径、字符串或字节字符串。它默认是@tech{主集合目录}的 @filepath{lib} 同级目录。}

 @item{@indexed-racket['lib-search-dirs] --- 路径、字符串、字节字符串或 @racket[#f] 的列表，表示包含 foreign library 的目录的搜索路径。列表中的每个 @racket[#f]（如果有）被替换为默认搜索路径，即用户特定和版本特定的 @filepath{lib} 目录，后跟@tech{主库目录}。}

 @item{@indexed-racket['dll-dir] --- 包含主可执行文件共享库的目录的路径、字符串或字节字符串。它默认是@tech{主库目录}。}

 @item{@indexed-racket['share-dir] --- @deftech{主共享文件目录}的路径、字符串或字节字符串，通常包含已安装的包。它默认是主集合目录的 @filepath{share} 同级目录。}

 @item{@indexed-racket['share-search-dirs] --- 类似于 @racket['lib-search-dirs]，其中 @racket[#f] 被替换为默认搜索路径，即用户特定和版本特定的目录，后跟可能通过 @scheme['share-dir] 配置的目录。

       @history[#:added "8.1.0.6"]}
       
 @item{@indexed-racket['links-file] --- @tech[#:doc reference-doc]{集合链接文件}的路径、字符串或字节字符串。它默认是@tech{主共享文件目录}中的 @filepath{links.rktd} 文件。}

 @item{@indexed-racket['links-search-files] --- 类似于 @racket['lib-search-dirs]，但用于 @tech[#:doc reference-doc]{集合链接文件}。@racket[#f] 被替换为默认搜索路径，其中包含可能通过 @scheme['links-file] 配置的链接文件。用户特定和版本特定的链接文件总是添加到搜索的开头。}

 @item{@indexed-racket['pkgs-dir] --- 具有 @exec{installation} @tech[#:doc '(lib "pkg/scribblings/pkg.scrbl")]{package scope} 的包的路径、字符串或字节字符串。它默认是主共享文件目录中的 @filepath{pkgs}。}

 @item{@indexed-racket['pkgs-search-dirs] --- 类似于 @racket['lib-search-dirs]，但用于大致处于 @exec{installation} @tech[#:doc '(lib "pkg/scribblings/pkg.scrbl")]{package scope} 中的包。更精确地说，列表中的 @racket[#f] 值被替换为由 @racket['pkgs-dir] 指定的目录，并且搜索列表中的该点对应于 @exec{installation} scope。列表中在 @racket[#f] 值之前或之后的路径可以被选择为从该路径的列表点开始搜索的 scope。@racket['pkgs-search-dirs] 中列出的目录通常要求在 @racket['links-search-files] 中有对应的条目，其中对应条目是目录内的 @filepath{links.rktd}。

       @history[#:changed "7.0.0.19" @elem{以通用方式调整包搜索路径以适应目录 scope。}]}

 @item{@indexed-racket['compiled-file-roots] --- 路径和 @racket['same] 的列表，用于初始化 @racket[current-compiled-file-roots]。路径可以是相对路径或绝对路径，可以指定为通过 @racket[string->path] 或 @racket[bytes->path] 转换为路径的字符串或字节字符串。

       @history[#:added "8.0.0.9"]}

 @item{@indexed-racket['bin-dir] --- 安装目录中包含可执行文件的目录的路径、字符串或字节字符串。它默认是@tech{主集合目录}的 @filepath{bin} 同级目录。}

 @item{@indexed-racket['gui-bin-dir] --- 安装目录中包含 GUI 可执行文件的目录的路径、字符串或字节字符串。如果配置了，它默认是 @racket['bin-dir] 的值，否则以平台特定的方式默认：在 Unix 上是 @tech{主集合目录}的 @filepath{bin} 同级目录，在 Windows 和 Mac OS 上是 @tech{主集合目录}的父目录。

       @history[#:added "6.8.0.2"]}

 @item{@indexed-racket['bin-search-dirs] --- 类似于 @racket['lib-search-dirs]，但用于查找可执行文件，例如 @exec{racket}。@racket[#f] 被替换为默认搜索路径，即用户特定和版本特定的目录，后跟可能通过 @scheme['bin-dir] 配置的控制台可执行文件目录。

       @history[#:added "8.1.0.6"]}

 @item{@indexed-racket['gui-bin-search-dirs] --- 类似于 @racket['bin-search-dirs]，但用于 GUI 可执行文件，默认值是 @racket['bin-search-dirs] 的值。

       @history[#:added "8.1.0.6"]}

 @item{@indexed-racket['apps-dir] --- 安装目录中用于 @filepath{.desktop} 文件的目录的路径、字符串或字节字符串。它默认是@tech{主共享文件目录}的 @filepath{applications} 子目录。}

 @item{@indexed-racket['man-dir] --- 安装目录的 man-page 目录的路径、字符串或字节字符串。它默认是@tech{主共享文件目录}的 @filepath{man} 同级目录。}

 @item{@indexed-racket['man-search-dirs] --- 类似于 @racket['lib-search-dirs]，其中 @racket[#f] 被替换为默认搜索路径，即用户特定和版本特定的目录，后跟可能通过 @scheme['man-dir] 配置的目录。

       @history[#:added "8.1.0.6"]}

 @item{@indexed-racket['doc-dir] --- 主文档目录的路径、字符串或字节字符串。它默认是@tech{主集合目录}的 @filepath{doc} 同级目录。}

 @item{@indexed-racket['doc-search-dirs] --- 类似于 @racket['lib-search-dirs]，其中 @racket[#f] 被替换为默认搜索路径，即用户特定和版本特定的目录，后跟可能通过 @scheme['doc-dir] 配置的目录。}

 @item{@indexed-racket['doc-search-url] --- 一个 URL 字符串，附带版本和 search-tag 查询以形成远程文档引用。}

 @item{@indexed-racket['doc-open-url] --- 一个 URL 字符串或 @racket[#f]；字符串提供一个 URL，用于代替本地路径来搜索和可能打开文档页面（这通常只在无法打开本地 HTML 文件的环境中有意义）。}

 @item{@indexed-racket['include-dir] --- 包含 C 头文件的主目录的路径、字符串或字节字符串。它默认是@tech{主集合目录}的 @filepath{include} 同级目录。}

 @item{@indexed-racket['include-search-dirs] --- 类似于 @racket[doc-search-dirs]，但用于包含 C 头文件的目录。}

 @item{@indexed-racket['info-domain-root] --- 路径、字符串、字节字符串或 @racket[#f]；用作前缀以重定向用于通过 @racket[find-relevant-directories] 记录和查找 @filepath{info.rkt} 信息的路径。它默认是 @racket[#f]，即按原样使用路径。

       @history[#:added "8.10.0.4"]}

 @item{@indexed-racket['catalogs] --- URL 字符串的列表，用作解析包名的搜索路径。列表中的 @racket[#f] 被替换为默认搜索路径。不以字母字符后跟 @litchar{://} 开头的字符串被视为路径，其中相对路径是相对于配置目录的。}

 @item{@indexed-racket['default-scope] --- @racket["user"] 或 @racket["installation"] 之一，确定包管理操作的默认 @tech[#:doc '(lib "pkg/scribblings/pkg.scrbl")]{package scope}。}

 @item{@indexed-racket['download-cache-dir] --- 用作存储已下载包归档的位置的路径字符串。未指定时，包缓存在用户缓存目录中的 @filepath{download-cache} 目录中，由 @racket[(find-system-path 'cache-dir)] 报告。}

 @item{@indexed-racket['download-cache-max-files] 和 @indexed-racket['download-cache-max-bytes] --- 确定下载缓存限制的实数。未指定时，缓存允许最多容纳 1024 个文件，总计达 64@|~|MB。}

 @item{@indexed-racket['build-stamp] --- 标识构建的字符串，可用于补充 Racket 版本号以更具体地标识构建。空字符串通常适用于发布构建。默认 @racket{banner} 也显示非空的 build stamp。

       @history[#:changed "8.11.1.7" @elem{将 build stamp 添加到 @racket{banner}。}]}

 @item{@indexed-racket['main-language-family] --- 命名主 @tech{语言族}的字符串。默认值是 @racket["Racket"]。

       @history[#:added "8.14.0.5"]}

 @item{@indexed-racket['base-documentation-packages] --- 字符串列表，每个字符串命名一个包。包及其依赖项提供的任何文档都被视为分发基础语言的一部分。此分类影响文档搜索结果的排序和报告方式。默认值是 @racket['("racket-doc")]。

       @history[#:added "8.14.0.5"]}

 @item{@indexed-racket['distribution-documentation-packages] --- 类似于 @racket['base-documentation-packages]，但标识被视为分发一部分的更大文档集（超出但通常包括基础语言）。默认值是 @racket['("main-distribution")]。

       @history[#:added "8.14.0.5"]}

 @item{@indexed-racket['absolute-installation?] --- 布尔值，如果安装使用绝对路径名则为 @racket[#t]，否则为 @racket[#f]。}

 @item{@indexed-racket['cgc-suffix] --- 用作 CGC 可执行文件后缀（在实际后缀之前，如 @filepath{.exe}）的字符串。使用 Windows 风格的大小写，字符串将酌情转为小写（例如用于 Unix 二进制名称）。@racket[#f] 值表示如果 @exec{racket} 二进制标识自身为 CGC，则后缀为 @racket[""]，否则为 @racket["CGC"]。}

 @item{@indexed-racket['3m-suffix] --- 类似于 @racket['cgc-suffix]，但用于 3m。@racket[#f] 值表示如果 @exec{racket} 二进制标识自身为 3m，则后缀为 @racket[""]，否则为 @racket["BC"]。}

 @item{@indexed-racket['cs-suffix] --- 类似于 @racket['cgc-suffix]，但用于 CS。@racket[#f] 值表示如果 @exec{racket} 二进制标识自身为 CS，则后缀为 @racket[""]，否则为 @racket["CS"]。}

 @item{@indexed-racket['config-tethered-console-bin-dir] 和 @indexed-racket['config-tethered-gui-bin-dir] --- 用于保存额外可执行文件副本的目录路径，这些副本绑定到创建可执行文件时活动的配置目录（由 @racket[find-config-dir] 报告）。另请参见 @secref["tethered-install"]、@racket[find-config-tethered-console-bin-dir] 和 @racket[find-config-tethered-gui-bin-dir]。}

  @item{@indexed-racket['interactive-file] 和 @indexed-racket['gui-interactive-file] --- 交互式模块的模块路径，在 REPL 启动时运行，除非提供了 @Flag{q}/@DFlag{no-init-file}。默认值分别为 @racket['racket/interactive] 和 @racket['racket/gui/interactive]。}

  ]
