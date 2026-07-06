#lang scribble/doc
@(require "mz.rkt"
          (for-label setup/dirs
                     setup/collection-search))

@title[#:tag "collects"]{库与集合}

@deftech{库}是为多个程序提供服务的 @racket[module] 声明。Racket 进一步将库组合成 @deftech{集合}。集合通常通过 @deftech{包}添加（参见 @other-doc['(lib "pkg/scribblings/pkg.scrbl")]）；包管理器在 Racket 核心之外运行，但通过 @tech{集合链接文件}配置核心运行时系统。

集合中的库通过 @racket[lib] 路径（参见 @racket[require]）或符号简写引用。例如，以下模块使用 @filepath{setup} 集合中的库模块 @filepath{getinfo.rkt}，以及 @filepath{games} 集合的 @filepath{cards} 子集合中的库模块 @filepath{cards.rkt}：

@racketmod[
racket
(require (lib "setup/getinfo.rkt")
         (lib "games/cards/cards.rkt"))
....
]

此示例使用符号简写可以更简洁、更常见地书写：

@racketmod[
racket
(require setup/getinfo
         games/cards/cards)
....
]

当在 @racket[require] 形式中使用标识符 @racket[_id] 时，它会被转换为 @racket[(lib _rel-string)]，其中 @racket[_rel-string] 是 @racket[_id] 的字符串形式。

@racket[(lib _rel-string)] 中的 @racket[_rel-string] 由一个或多个命名集合的路径元素组成，然后是命名库文件的最终路径元素；路径元素之间用 @litchar{/} 分隔。如果 @racket[_rel-string] 不包含任何 @litchar{/}，则隐式地在路径末尾添加 @litchar{/main.rkt}。如果 @racket[_rel-string] 包含 @litchar{/} 但没有以文件后缀结尾，则隐式地在路径末尾添加 @litchar{.rkt}。

库也可以通过 @|PLaneT| 包分发。这类库通过 @racket[planet] 模块路径引用（参见 @racket[require]），由 Racket 按需下载，而不是通过 @tech{集合}引用。

@racket[planet] 或 @racket[lib] 路径到 @racket[module] 声明的转换由 @tech{模块名解析器}决定，正如 @racket[current-module-name-resolver] 参数所指定的。

@; ----------------------------------------------------------------------

@section[#:tag "collects-search"]{集合搜索配置}

对于默认的 @tech{模块名解析器}，集合的搜索路径由 @racket[current-library-collection-links] 参数和 @racket[current-library-collection-paths] 参数决定：

@itemlist[

 @item{最原始的基于 @tech{集合}的模块位于相对于 Racket 可执行文件的 @filepath{collects} 目录中。集合的库分组在名称与集合名称匹配的目录内。@filepath{collects} 目录的路径通常包含在 @racket[current-library-collection-paths] 中。}

 @item{基于集合的库也可以安装在其他目录中，可能是用户特定的目录，其结构与 @filepath{collects} 目录相同。这些额外目录可以通过命令行参数传递给 @exec{racket} 动态地包含在 @racket[current-library-collection-paths] 参数中，或通过设置 @envvar{PLTCOLLECTS} 环境变量；参见 @racket[find-library-collection-paths]。}

 @item{@tech{集合链接文件}提供从顶级集合名称到目录的映射，加上额外的 @filepath{collects} 类目录（这些子目录名称与集合名称匹配）。要搜索的每个 @tech{集合链接文件}由 @racket[current-library-collection-links] 参数引用；该参数引用文件本身而非文件内容，以便文件的更改可以被检测并影响后续的模块解析。另请参见 @racket[find-library-collection-links]。}

 @item{@racket[current-library-collection-links] 参数的值还可以包含哈希表，这些哈希表提供与 @tech{集合链接文件}相同的内容：从符号形式的集合名称到集合路径列表的映射，或从 @racket[#f] 到 @filepath{collects} 类路径列表的映射。}

 @item{最后，@racket[current-library-collection-links] 参数的值包含 @racket[#f] 来表示搜索过程中的一个检查点，在该点 @tech{模块名解析器} 应该检查 @racket[current-library-collection-paths] 相对于 @racket[current-library-collection-links] 中的文件和哈希表。}

]

为了解析模块引用 @racket[_rel-string]，默认的 @tech{模块名解析器} 按从先到后的顺序搜索 @racket[current-library-collection-links] 中的集合链接，以定位包含 @racket[_rel-string] 的第一个目录，在 @racket[current-library-collection-links] 包含 @racket[#f] 的位置拼接对 @racket[current-library-collection-paths] 的搜索。链接表和搜索路径中每个元素的文件系统树实际上与对应同一集合的其他路径元素的文件系统树 @deftech[#:key "collection splicing"]{拼接}在一起。一些 Racket 工具依赖于模块路径名的唯一解析，因此安装和配置不应允许多个文件匹配同一集合和文件的组合。

@racket[current-library-collection-links] 参数的值由 @exec{racket} 可执行文件初始化为 @racket[(find-library-collection-links)] 的结果，@racket[current-library-collection-paths] 参数的值初始化为 @racket[(find-library-collection-paths)] 的结果。

@; ----------------------------------------------------------------------

@section[#:tag "links-file"]{集合链接}

@tech{集合链接文件}被 @racket[collection-file-path]、@racket[collection-path] 和默认的 @tech{模块名解析器} 用来在尝试 @racket[(current-library-collection-paths)] 搜索路径之前定位集合。要使用的 @tech{集合链接文件}由 @racket[current-library-collection-links] 参数决定，该参数被初始化为 @racket[find-library-collection-links] 的结果。

@tech{集合链接文件}使用默认的读取器参数设置被 @racket[read] 以获得一个列表。列表的每个元素必须是一个具有以下形式之一的链接规范：@racket[(list _string _encoded-path)]、@racket[(list _string _encoded-path _regexp)]、@racket[(list 'root _encoded-path)]、@racket[(list 'root _encoded-path _regexp)]、@racket[(list 'static-root _encoded-path)]、@racket[(list 'static-root _encoded-path _regexp)]。

@racket[_string] 命名一个顶级 @tech{集合}，在此情况下 @racket[_encoded-path] 描述一个可以用作集合路径的路径（直接作为路径，而非由 @racket[_string] 命名的 @racket[_encoded-path] 的子目录）。相比之下，@racket['root] 条目就像 @racket[(current-library-collection-paths)] 中的路径一样运作。@racket['static-root] 条目类似于 @racket['root] 条目，但假设目录的即时内容不会改变，除非 @tech{集合链接文件}发生变化。

每个 @racket[_encoded-path] 要么是一个字符串，要么是一个通过 @racket[bytes->path] 转换为路径的字节字符串，要么是一个由相对路径元素字节字符串、@racket['up] 和 @racket['same] 指示符组成的列表，这些与 @racket[build-path] 组合，其中字节字符串通过 @racket[bytes->path-element] 转换。

如果 @racket[_encoded-path] 描述的是相对路径，则它相对于包含 @tech{集合链接文件} 的目录。如果链接中指定了 @racket[_regexp]，则该链接仅在 @racket[(regexp-match? _regexp (version))] 产生真值结果时被使用。

单个顶级集合在 @tech{集合链接文件} 中可以有多个链接，并且可以出现任意数量的 @racket['root] 条目。对应的路径有效地被拼接在一起，因为路径是按顺序尝试以定位文件或子集合的。

@exec{raco link} 命令行工具可以显示、安装和删除 @tech{集合链接文件} 中的链接。更多信息参见 @other-manual[raco-doc] 中的 @secref[#:doc raco-doc "link"]。

@history[#:changed "8.1.0.6" @elem{允许 @racket[_encoded-path] 使用字节字符串和列表。}]

@; ----------------------------------------

@section[#:tag "collects-api"]{集合路径与参数}

@defproc[(find-library-collection-paths [pre-extras (listof path-string?) null]
                                        [post-extras (listof path-string?) null]
                                        [config hash? (read-installation-configuration-table)]
                                        [name (get-installation-name config)])
         (listof path?)]{

生成一个路径列表，通常用于初始化 @racket[current-library-collection-paths]，如下所示：

@itemize[

@item{@racket[(build-path (find-system-path 'addon-dir) name "collects")] 生成的路径是默认集合路径列表的第一个元素，除非 @racket[use-user-specific-search-paths] 参数的值为 @racket[#f]。}

 @item{在 @racket[pre-extras] 中提供的额外目录接下来被包含在默认集合路径列表中，转换为相对于可执行文件的完整路径。}

 @item{如果 @racket[(find-system-path 'collects-dir)] 指定的目录是绝对路径，或者它是相对的（相对于可执行文件）且存在，则它被添加到默认集合路径列表的末尾。}

 @item{在 @racket[post-extras] 中提供的额外目录最后被包含在默认集合路径列表中，转换为相对于可执行文件的完整路径。}

 @item{如果 @racket[config] 有 @racket['collects-search-dirs] 的值，则它用来代替默认集合路径列表（由前三个要点构建），并且默认值被拼接在 @racket['collects-search-dirs] 列表中的任何 @racket[#f] 位置。如果 @racket[config] 没有 @racket['collects-search-dirs] 值，则使用默认集合路径列表。}

 @item{如果定义了 @indexed-envvar{PLTCOLLECTS} 环境变量，则使用 @racket[path-list-string->path-list] 将其与默认列表组合，只要 @racket[use-user-specific-search-paths] 的值为真。如果未定义或 @racket[use-user-specific-search-paths] 的值为 @racket[#f]，则直接使用由前四个要点构建的集合路径列表。

 注意在 @|AllUnix| 上，路径用 @litchar{:} 分隔，在 Windows 上用 @litchar{;} 分隔。此外，@racket[path-list-string->path-list] 在空路径处拼接默认路径，例如，在许多 Unix shell 中，可以将 @envvar{PLTCOLLECTS} 设置为 @tt{":`pwd`"}、@tt{"`pwd`":"} 或 @tt{"`pwd`"} 来分别指定在默认路径之后、之前或替代默认当前目录。}

]

@history[#:changed "8.4.0.3" @elem{添加了 @racket[config] 和 @racket[name] 参数。}]}

@defproc[(find-library-collection-links [config hash? (read-installation-configuration-table)]
                                        [name (get-installation-name config)])
         (listof (or/c #f (and/c path? complete-path?)))]{

生成一个路径和 @racket[#f] 的列表，通常用于初始化 @racket[current-library-collection-links]，如下所示：

@itemlist[

 @item{列表以 @racket[#f] 开头，使得默认的 @tech{模块名解析器}、@racket[collection-file-path] 和 @racket[collection-path] 在 @tech{集合链接文件}之前尝试 @racket[current-library-collection-paths] 中的路径。}

 @item{只要 @racket[use-user-specific-search-paths] 和 @racket[use-collection-link-paths] 的值为真，结果列表中的第二个元素就是用户特定的 @tech{集合链接文件} 路径，默认为 @racket[(build-path (find-system-path 'addon-dir) name "links.rktd")]，但可以被 @racket[config] 中的 @racket['links-file] 值替换。}

 @item{只要 @racket[use-collection-link-paths] 的值为真，列表的其余部分包含类似于 @racket[get-links-search-files] 的结果，但如果提供 @racket[config] 则使用它而不是读取安装的 @filepath{config.rktd} 文件。通常，该结果是包含单个路径 @racket[(build-path (find-config-dir) "links.rktd")] 的列表。}

]

@history[#:changed "8.4.0.3" @elem{添加了 @racket[config] 和 @racket[name] 参数。}]}


@defproc*[([(collection-file-path [file path-string?] [collection path-string?] ...+
                                  [#:check-compiled? check-compiled? any/c
                                                     (regexp-match? #rx"[.]rkt$" file)])
            path?]
           [(collection-file-path [file path-string?] [collection path-string?] ...+
                                  [#:fail fail-proc (string? . -> . any)]
                                  [#:check-compiled? check-compiled? any/c
                                                     (regexp-match? #rx"[.]rkt$" file)])
            any])]{

返回由 @racket[collection]s 指定的集合中 @racket[file] 指示的文件的路径，其中第二个 @racket[collection]（如果有的话）命名一个子集合，依此类推。搜索使用 @racket[current-library-collection-links] 和 @racket[current-library-collection-paths] 的值。

@margin-note{另请参见 @racketmodname[setup/collection-search] 中的 @racket[collection-search]。}

如果未找到 @racket[file]，但 @racket[file] 以 @filepath{.rkt} 结尾且存在后缀为 @filepath{.ss} 的文件，则使用 @filepath{.ss} 文件的目录。如果未找到 @racket[file] 且 @filepath{.rkt}/@filepath{.ss} 转换不适用，但找到了对应于 @racket[collection]s 的目录，则使用第一个这样的目录返回路径。

如果 @racket[check-compiled?] 为真，则搜索还取决于 @racket[use-compiled-file-paths] 和 @racket[current-compiled-file-roots]；如果未找到 @racket[file]，则按默认 @tech{编译加载处理器} 的方式检查后缀为 @filepath{.zo} 的 @racket[file] 的编译形式。如果找到编译文件，@racket[collection-file-path] 的结果报告找到的编译文件对应的 @racket[file] 本身应占据的位置（如果存在的话）。

最后，如果未找到集合，并且提供了 @racket[fail-proc]，则将 @racket[fail-proc] 应用于错误消息（不以 @scheme["collection-file-path:"] 开头或声称来源），并且其结果作为 @racket[collection-file-path] 的结果。如果未提供 @racket[fail-proc] 且未找到集合，则 @exnraise[exn:fail:filesystem]。

@examples[(eval:alts (collection-file-path "main.rkt" "racket" "base")
                     (build-path "path" "to" "collects" "racket" "base" "main.rkt"))
          (eval:error (collection-file-path "sandwich.rkt" "bologna"))]

@history[#:changed "6.0.1.12" @elem{添加了 @racket[check-compiled?] 参数。}]}


@defproc*[([(collection-path [collection path-string?] ...+)
            path?]
           [(collection-path [collection path-string?] ...+
                             [#:fail fail-proc (string? . -> . any)])
            any])]{

  @deprecated[#:what "function" @racket[collection-file-path]]{
  @tech{集合拼接}意味着给定的集合可以有多个路径，例如当多个 @tech[#:doc '(lib "scribblings/guide/guide.scrbl")]{包}为集合提供模块时。

类似于 @racket[collection-file-path]，但没有指定文件名，因此返回由 @racket[collection]s 指示的目录。

当多个目录对应于该集合时，返回搜索序列中找到的第一个（参见 @secref["collects-search"]）。}


@defparam*[current-library-collection-paths paths
                                            (listof (and/c path-string? complete-path?))
                                            (listof (and/c path? complete-path?))]{

一个参数，用于确定一个完整目录路径列表，以通过默认的 @tech{模块名解析器}查找库（例如在 @racket[require] 中引用的库），以及通过 @racket[collection-path] 和 @racket[collection-file-path] 查找路径。更多信息参见 @secref["collects-search"]。}


@defparam*[current-library-collection-links paths
                                            (listof (or/c #f
                                                          (and/c path-string? complete-path?)
                                                          (hash/c (or/c (and/c symbol? module-path?) #f)
                                                                  (listof (and/c path-string? complete-path?)))))
                                            (listof (or/c #f
                                                          (and/c path? complete-path?)
                                                          (hash/c (or/c (and/c symbol? module-path?) #f)
                                                                  (listof (and/c path? complete-path?)))))]{


一个参数，用于确定 @tech{集合链接文件}、额外路径以及 @racket[current-library-collection-paths] 的相对搜索顺序，以通过默认的 @tech{模块名解析器}查找库（例如在 @racket[require] 中引用的库），以及通过 @racket[collection-path] 和 @racket[collection-file-path] 查找路径。更多信息参见 @secref["collects-search"]。}


@defboolparam[use-user-specific-search-paths on?]{

一个参数，用于确定是否将用户特定路径包含进搜索路径中，这些路径位于 @racket[(find-system-path 'addon-dir)] 生成的目录中，用于搜索集合和其他文件。例如，当此参数的值为 @racket[#f] 时，@racket[find-library-collection-paths] 的初始值会省略用户特定的集合目录。

如果 @exec{racket} 有 @Flag{U} 或 @DFlag{no-user-path} 参数，则 @racket[use-user-specific-search-paths] 被初始化为 @racket[#f]。}


@defboolparam[use-collection-link-paths on?]{

一个参数，用于确定 @tech{集合链接文件}是否包含在 @racket[find-library-collection-links] 的结果中。

如果此参数在启动时的值为 @racket[#f]，则 @tech{集合链接文件}对该 Racket 进程永久禁用。特别是，如果将空字符串作为 @Flag{X} 或 @DFlag{collects} 参数提供给 @exec{racket}，则不仅 @racket[current-library-collection-paths] 被初始化为空列表，而且 @racket[use-collection-link-paths] 也被初始化为 @racket[#f]。}


@defproc[(read-installation-configuration-table) (and/c hash? immutable?)]{

返回安装的 @filepath{config.rktd} 文件的内容（参见 @secref["config-file" #:doc raco-doc]），只要该内容是 @tech{哈希表}，否则返回空哈希表。

@history[#:added "8.4.0.3"]}
