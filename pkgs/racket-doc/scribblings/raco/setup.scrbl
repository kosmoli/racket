#lang scribble/doc

@(require scribble/manual
          scribble/bnf
          "common.rkt"
         (for-label racket
                    setup/setup-unit
                    setup/option-unit
                    setup/option-sig
                    setup/dirs
                    setup/getinfo
                    setup/main-collects
                    setup/collection-name
                    setup/collection-search
                    setup/matching-platform
                    setup/cross-system
                    setup/path-to-relative
                    setup/xref scribble/xref
                    ;; info -- no bindings from this are used
                    (only-in info)
                    setup/link
                    compiler/compiler
                    compiler/module-suffix
                    compiler/find-exe
                    launcher/launcher
                    compiler/sig
                    launcher/launcher-sig
                    dynext/file-sig
                    racket/gui/base
                    racket/path
                    setup/collects
                    syntax/modcollapse
                    racket/runtime-path
                    pkg/path
                    setup/doc-to-destdir))

@(define-syntax-rule (local-module mod . body)
   (begin
     (define-syntax-rule (go)
       (begin
         (require (for-label mod))
         . body))
     (go)))

@(define ref-src
   '(lib "scribblings/reference/reference.scrbl"))

@(define (defaults v) 
   @elem{The default is @|v|.})

@(define pkg-doc '(lib "pkg/scribblings/pkg.scrbl"))

@(define raco-pkg-install
   @seclink["raco-pkg-install" #:doc '(lib "pkg/scribblings/pkg.scrbl")]{@exec{raco pkg install}})

@title[#:tag "setup" #:style 'toc]{@exec{raco setup}：安装管理}

@exec{raco setup} 命令为所有已安装的集合构建字节码、文档、可执行文件和元数据索引。

由 @exec{raco setup} 构建的集合可以来自原始 Racket 发行版、通过包管理器安装（参见 @other-manual[pkg-doc]）、通过 @|PLaneT| 安装（参见 @other-manual['(lib "planet/planet.scrbl")]）、通过 @exec{raco link} 链接、位于 @envvar{PLTCOLLECTS} 环境变量列出的目录中，或放置在默认集合目录中。

@exec{raco setup} 工具本身不直接支持集合的安装，除非通过现在已不推荐的 @Flag{A} 标志（参见 @secref["raco-setup-A"]）。@exec{raco setup} 命令由安装工具（如包管理器或 @|PLaneT|）使用。修改已安装集合的程序员可能会发现运行 @exec{raco setup} 作为卸载和重新安装一组集合的替代方案很有用。

@local-table-of-contents[]

@; ------------------------------------------------------------------------

@section[#:tag "running"]{运行 @exec{raco setup}}

在没有命令行参数的情况下，@exec{raco setup} 查找所有当前集合——参见 @secref[#:doc ref-src]{collects}——并编译每个集合中的库。（名为 @filepath{.git} 或 @filepath{.svn} 的目录不被视为集合。）

要将 @exec{raco setup} 限制在一组集合中，请将集合名称作为参数提供。例如，@exec{raco setup scribblings/raco} 将仅编译和渲染 @exec{raco} 的文档，该文档实现在 @filepath{scribblings/raco} 集合中。

集合中的可选 @filepath{info.rkt} 可以具体指示如何编译集合的文件以及在设置集合时要执行的其他操作，例如创建可执行文件或构建文档。更多信息请参见 @secref["setup-info"]。

@exec{raco setup} 命令接受以下命令行标志：

@itemize[

@item{限制到指定的集合或 @|PLaneT| 包：
@itemize[

 @item{@DFlag{only} --- 将 setup 限制到指定的集合和 @|PLaneT| 包，即使未指定任何内容。如果任何集合通过命令行参数或 @Flag{l}、@DFlag{pkgs} 或 @Flag{P} 标志指定，则此模式为默认模式。}

 @item{@Flag{l} @nonterm{collection} @racket[...] --- 将 setup 操作限制到指定的 @nonterm{collection}（即与不通过标志提供 @nonterm{collections} 相同，但不会有 @nonterm{collection} 被解释为标志的可能性）。}

 @item{@DFlag{pkgs} @nonterm{pkg} @racket[...] --- 将 setup 操作限制到位于（或部分位于）指定 @nonterm{pkg} 中的集合。}

 @item{@Flag{P} @nonterm{owner} @nonterm{package-name} @nonterm{maj} @nonterm{min} --- 将 setup 操作限制到指定的 @|PLaneT| 包，以及任何其他指定的 @|PLaneT| 包或集合。}

 @item{@DFlag{doc-index} --- 构建实现文档索引的集合（当启用文档构建时），除了指定的集合。}

 @item{@DFlag{tidy} --- 删除不存在集合的元数据缓存信息和文档以清理移除后的残留，即使 setup 操作已经限制到指定集合。虽然整理不限于指定集合，但可以通过 @DFlag{avoid-main} 或 @DFlag{no-user} 进行约束。}

]}
@item{限制到特定任务：
@itemize[

 @item{@DFlag{clean} 或 @Flag{c} --- 删除现有的 @filepath{.zo} 文件，从而确保从源文件进行干净的构建。要删除的确切文件集可以通过 @filepath{info.rkt} 控制；更多信息请参见 @elemref["clean"]{@racket[clean]}。除非同时指定 @DFlag{no-info-domain} 或 @Flag{d}，否则 @filepath{info.rkt} 缓存会被清除。除非同时指定 @DFlag{no-docs} 或 @Flag{D}，否则文档索引数据库会被重置。}

 @item{@DFlag{fast-clean} --- 类似于 @DFlag{clean}，但不会强制从源码引导 @exec{raco setup}（这意味着 @DFlag{fast-clean} 无法清理影响 @exec{raco setup} 本身的损坏）。}

 @item{@DFlag{no-zo} 或 @Flag{n} --- 不将源文件编译为 @filepath{.zo} 文件。}

 @item{@DFlag{trust-zos} --- 基于 @filepath{.zo} 文件已是最新的假设来修复其时间戳（除非 @envvar{PLT_COMPILED_FILE_CHECK} 环境变量设置为 @litchar{exists}，此时时间戳将被忽略）。}

 @item{@DFlag{recompile-only} --- 禁止从源码重新编译模块，强制要求每个 @filepath{.zo} 文件是最新的、仅需时间戳调整，或可以从现有的机器无关格式的 @filepath{.zo} 重新编译（当编译为机器相关格式时）。}

 @item{@DFlag{recompile-cache} @nonterm{dir} --- 在 @nonterm{dir} 中缓存模块重新编译（从机器无关格式到机器相关格式）。}

 @item{@DFlag{sync-docs-only} --- 同步或移动文档到适当位置以“构建”它，但不运行或渲染文档源。}

 @item{@DFlag{no-launcher} 或 @Flag{x} --- 不创建可执行文件或安装 @tt{man} 页面（如 @filepath{info.rkt} 中指定的；参见 @secref["setup-info"]）。}

 @item{@DFlag{no-foreign-libs} 或 @Flag{F} --- 不安装外部库（如 @filepath{info.rkt} 中指定的；参见 @secref["setup-info"]）。}

 @item{@DFlag{only-foreign-libs} --- 禁用除安装外部库之外的操作；等效于 @Flag{nxiIdD}，但 @DFlag{only-foreign-libs} 不会拒绝（冗余的）这些单独标志的指定。}

 @item{@DFlag{no-install} 或 @Flag{i} --- 不运行预安装操作（如 @filepath{info.rkt} 文件中指定的；参见 @secref["setup-info"]）。}

 @item{@DFlag{no-post-install} 或 @Flag{I} --- 不运行安装后操作（如 @filepath{info.rkt} 文件中指定的；参见 @secref["setup-info"]）。}

 @item{@DFlag{no-info-domain} 或 @Flag{d} --- 不从 @filepath{info.rkt} 文件构建元数据信息缓存。其他工具需要此缓存。例如，@exec{raco} 本身使用该缓存来定位插件工具。}

 @item{@DFlag{no-docs} 或 @Flag{D} --- 不构建文档。}

 @item{@DFlag{only-extra-docs} --- 禁用在 @DFlag{doc-pdf} 或 @DFlag{doc-markdown} 渲染之外的操作。}

 @item{@DFlag{doc-pdf} @nonterm{dir} --- 除了构建 HTML 文档外，还将文档渲染为 PDF 并将文件放置在 @nonterm{dir} 中。}

 @item{@DFlag{doc-markdown} @nonterm{dir} --- 除了构建 HTML 文档外，还将文档渲染为 Markdown（使用 Scribble 的 Markdown 后端）并将文件放置在 @nonterm{dir} 中。}

 @item{@DFlag{no-pkg-deps} 或 @Flag{K} --- 不检查库之间的依赖关系是否正确地由包级依赖声明反映，模块是否由多个包声明，以及包版本依赖是否满足。更多信息请参见 @secref["setup-check-deps"]。}

 @item{@DFlag{check-pkg-deps} --- 即使向 @exec{raco setup} 提供了特定集合，也检查包依赖关系（除非显式禁用），即使对于没有依赖声明的包也是如此。更多信息请参见 @secref["setup-check-deps"]。}

 @item{@DFlag{fix-pkg-deps} --- 尝试通过调整包的 @filepath{info.rkt} 文件来纠正依赖不匹配（仅对作为链接安装的包有意义）。更多信息请参见 @secref["setup-check-deps"]。}

 @item{@DFlag{unused-pkg-deps} --- 尝试报告已声明但未使用的依赖关系。请注意，某些包依赖可能是有意未使用的（例如，为了方便而声明以强制安装其他包），并且请注意，包依赖可能仅因为相关模块的编译被抑制而被报告为未使用。更多信息请参见 @secref["setup-check-deps"]。}

]}
@item{限制用户与安装设置：
@itemize[

 @item{@DFlag{no-user} 或 @Flag{U} --- 不执行任何用户特定的（相对于安装特定的）setup 操作。}

 @item{@DFlag{no-planet} --- 不执行任何 @|PLaneT| 的 setup 操作；此标志由 @DFlag{no-user} 隐含。}

 @item{@DFlag{avoid-main} --- 不执行任何影响安装的 setup 操作，相对于用户特定操作。}

 @item{@DFlag{force-user-docs} --- 构建文档时，创建用户特定的文档入口点，即使其内容与主安装相同。}

]}
@item{选择并行性和其他构建模式：
@itemize[

 @item{@DFlag{jobs} @nonterm{n}、@DFlag{workers} @nonterm{n} 或 @Flag{j} @nonterm{n} --- 使用最多 @nonterm{n} 个并行进程。默认情况下，@exec{raco setup} 使用 @racket[(processor-count)] 个作业，这通常会使用机器的所有处理核心。}

 @item{@DFlag{places} --- 对并行作业使用 Racket place；如果 Racket place 可以并行运行，则此模式为默认模式。}

 @item{@DFlag{processes} --- 对并行作业使用单独的进程；如果 Racket place 不能并行运行，则此模式为默认模式。}

 @item{@DFlag{verbose} 或 @Flag{v} --- 对 @exec{raco setup} 操作输出更详细的信息。}

 @item{@DFlag{make-verbose} 或 @Flag{m} --- 对依赖检查输出更详细的信息。}

 @item{@DFlag{compiler-verbose} 或 @Flag{r} --- 对依赖检查和编译输出更详细的信息。}

 @item{@DFlag{mode} @nonterm{mode} --- 使用非默认的 @filepath{.zo} 编译器，并将生成的 @filepath{.zo} 文件放在以 @nonterm{mode} 命名的子目录（相对于通常位置）中。编译器通过将 @nonterm{mode} 用作集合名称、在该集合中查找 @filepath{zo-compile.rkt} 模块并提取其 @racket[zo-compile] 导出获得。@racket[zo-compile] 导出应该是一个类似于 @racket[compile] 的函数；示例请参见 @filepath{errortrace} 集合。}

 @item{@DFlag{fail-fast} --- 一旦发现任何错误，尝试立即中断。}

 @item{@DFlag{error-out} @nonterm{file} --- 通过写入 @nonterm{file} 并作为成功退出来处理可生存的错误，这有助于结合 @DFlag{error-in} 链接多个 @exec{raco setup} 调用。如果没有错误且 @nonterm{file} 已存在，则删除它。}

 @item{@DFlag{error-in} @nonterm{file} --- 将 @nonterm{file} 的存在视为“前一个进程报告了错误”错误。通常，@nonterm{file} 是由前一个使用 @DFlag{error-out} 运行的 @exec{raco setup} 创建的。在通过 @DFlag{error-out} 创建文件之前检测到 @DFlag{error-in} 的文件，因此同一文件可用于链接一系列 @exec{raco setup} 步骤。}

 @item{@DFlag{pause} 或 @Flag{p} --- 如果报告了任何错误，暂停等待用户输入（以便用户有时间检查可能在 @exec{raco setup} 进程结束时消失的输出）。}

]}
@item{解包 @filepath{.plt} 归档文件：
@itemize[

 @item{@Flag{A} @nonterm{archive} @racket[...] --- 安装每个 @nonterm{archive}；参见 @secref["raco-setup-A"]。}

 @item{@DFlag{force} --- 与 @Flag{A} 一起使用，将归档文件的版本不匹配视为警告。}

 @item{@DFlag{all-users} 或 @Flag{a} --- 与 @Flag{A} 一起使用，将归档文件安装到安装位置而非用户特定位置。}

]}
@item{引导启动：
@itemize[

 @item{@DFlag{boot} @nonterm{module-file} @nonterm{build-dir} --- 供直接运行 @racketmodname[setup] 而非通过 @exec{raco setup} 时使用，以与 @exec{raco setup} 通常加载自身相同的方式加载 @nonterm{module-file}，自动检测需要从源码启动并重建编译文件——甚至包括编译管理器本身。@nonterm{build-dir} 路径被安装为 @racket[current-compiled-file-roots] 中的唯一路径，因此所有编译文件都放在那里。}

 @item{@DFlag{chain} @nonterm{module-file} @nonterm{build-dir} --- 类似于 @DFlag{boot}，但将 @nonterm{build-dir} 添加到 @racket[current-compiled-file-roots] 的开头而不是替换当前值，这意味着已在正常位置构建的库（包括编译管理器本身）将被使用而非重建。此模式适用于交叉编译。}

]}

]

构建 @exec{racket} 时，可以通过设置 @as-index{@envvar{PLT_SETUP_OPTIONS}} Makefile 变量将标志传递给由 @exec{make install} 运行的 @exec{raco setup}。例如，以下命令行在安装期间使用单个进程构建集合：

   @commandline{make install PLT_SETUP_OPTIONS="-j 1"}

运行 @exec{raco setup} 对 @envvar{PLT_COMPILED_FILE_CHECK} 环境变量敏感，方式与 @exec{raco make} 相同。具体来说，如果 @envvar{PLT_COMPILED_FILE_CHECK} 设置为 @litchar{exists}，则 @exec{raco make} 不会尝试更新未重新编译的编译文件的时间戳。

一些额外的环境变量对性能调试很有用：

@itemlist[

 @item{@indexed-envvar{PLT_SETUP_DMS_ARGS} 在每个集合编译后触发对 @racket[dump-memory-stats] 的调用，其中环境变量的值通过 @racket[read] 解析以获得传递给 @racket[dump-memory-stats] 的参数列表。}

 @item{@indexed-envvar{PLT_SETUP_LIMIT_CACHE}（设置为任何值）避免跨不同集合缓存编译文件信息，这在查找内存泄漏时有助于减少噪音。}

 @item{@indexed-envvar{PLT_SETUP_NO_FORCE_GC}（设置为任何值）抑制对 @racket[collect-garbage] 的调用，该调用默认在非并行构建中对每个集合编译后和每个文档运行或渲染后发出。}

 @item{@indexed-envvar{PLT_SETUP_SHOW_TIMESTAMPS}（设置为任何值）在 @exec{raco setup} 打印的每个状态消息后附加上当前进程时间，格式为 @litchar[" @ "]。}

]

@history[#:changed "6.1" @elem{Added the @DFlag{pkgs},
                               @DFlag{check-pkg-deps}, and
                               @DFlag{fail-fast} flags.}
         #:changed "6.1.1" @elem{Added the @DFlag{force-user-docs} flag.}
         #:changed "6.1.1.6" @elem{Added the @DFlag{only-foreign-libs} flag.}
         #:changed "6.6.0.3" @elem{Added support for @envvar{PLT_COMPILED_FILE_CHECK}.}
         #:changed "7.0.0.19" @elem{Added @DFlag{places} and  @DFlag{processes}.}
         #:changed "7.2.0.7" @elem{Added @DFlag{error-in} and  @DFlag{error-out}.}
         #:changed "7.2.0.8" @elem{Added @DFlag{recompile-only}.}
         #:changed "7.9.0.3" @elem{Added @envvar{PLT_SETUP_NO_FORCE_GC},
                                   @envvar{PLT_SETUP_SHOW_TIMESTAMPS},
                                   and @DFlag{sync-docs-only}.}
         #:changed "8.17.0.2" @elem{Added the @DFlag{recompile-cache} flag.}
         #:changed "9.2.0.4" @elem{Added the @DFlag{doc-markdown} and
                                   @DFlag{only-extra-docs} flags.}]

@; ------------------------------------------------------------------------

@section[#:tag "raco-setup-A"]{安装 @filepath{.plt} 归档文件}

@filepath{.plt} 文件是基于 Racket 的软件的平台无关分发归档。典型的 @filepath{.plt} 文件可以使用 @exec{raco pkg} 作为包安装（参见 @other-manual['(lib "pkg/scribblings/pkg.scrbl")]），在这种情况下 @exec{raco pkg} 提供卸载包和管理依赖关系的功能。

一种较旧的方法是将 @filepath{.plt} 文件提供给 @exec{raco setup} 并使用 @Flag{A} 标志；@filepath{.plt} 归档中包含的文件被解包（根据 @filepath{.plt} 文件中嵌入的规范），并且仅编译和设置 @filepath{.plt} 文件指定的集合。以这种方式处理的归档可以包含在安装时执行的任意代码，以及 @exec{raco setup} 正常集合设置部分触发的任何操作。

最后，@exec{raco unpack}（参见 @secref["unpack"]）命令可以列出 @filepath{.plt} 归档的内容或解包归档而不将其安装为包或集合。

@; ------------------------------------------------------------------------

@include-section["setup-info.scrbl"]

@; ------------------------------------------------------------------------

@include-section["info.scrbl"]

@; ------------------------------------------------------------------------

@section[#:tag "setup-check-deps"]{包依赖检查}

当 @exec{raco setup} 在没有参数的情况下运行时，@margin-note*{除非指定了 @DFlag{check-pkg-deps}，否则如果为 @exec{raco setup} 指定了任何集合，依赖检查将被禁用。}在构建所有集合和文档之后，@exec{raco setup} 检查包依赖关系。具体来说，它检查编译文件和文档，以验证跨包边界的引用是否由每个包级 @filepath{info.rkt} 文件中的依赖声明反映（参见 @secref[#:doc pkg-doc "metadata"]）。

@exec{raco setup} 中的依赖检查旨在帮助包开发者正确声明依赖关系。@exec{raco setup} 进程本身不依赖于包依赖声明。同样，缺少依赖声明的包可能对其他用户成功安装，只要他们恰好已经安装了依赖项。缺失的依赖会给那些在没有安装依赖项的情况下安装包的用户带来麻烦。

几乎每个包都依赖 @filepath{base} 包，它包含 Racket 最小变体中的集合。在 @filepath{base} 上声明依赖可能看起来不必要，因为它的集合总是被安装。然而，在未来的 Racket 版本中，最小集合可能会变化，新的最小集合将有一个包名称，例如 @filepath{base2}。声明对 @filepath{base} 的依赖可确保向前兼容性，如果缺少该声明，@exec{raco setup} 会发出警告。

为了适应包开发的早期阶段，对于没有依赖声明的包，缺失的依赖不被视为错误。

@subsection{声明构建时依赖}

构建时依赖是指在包转换为 @tech[#:doc pkg-doc]{二进制包}（参见 @secref[#:doc pkg-doc "strip"]）时不存在的依赖。例如，@filepath{tests} 和 @filepath{scribblings} 目录在二进制包中默认被剥离，因此来自具有这些名称的目录的跨包引用被视为构建依赖。类似地，@racketidfont{test} 和 @racketidfont{doc} 子模块被剥离，因此这些子模块中的引用产生构建依赖。

仅构建时的依赖可以在包的 @filepath{info.rkt} 文件中列为 @racket[build-deps] 而非 @racket[deps]。同时，@racket[deps] 中列出的依赖被视为运行时和构建时依赖。使用 @racket[build-deps] 而非将所有依赖列在 @racket[deps] 中的优点在于，包的二进制版本可以用更少的依赖进行安装。

@subsection{依赖检查的工作原理}

依赖检查使用 @filepath{.zo} 文件、关联的 @filepath{.dep} 文件（参见 @secref["Dependency Files"]）和文档索引。动态引用（例如通过 @racket[dynamic-require]）对依赖检查器不可见；只有通过 @racket[require]、@racket[define-runtime-module-path-index] 以及与 @racket[raco make] 协作的其他形式的依赖才对依赖检查可见。

依赖检查对依赖是否仅作为构建时依赖敏感。如果 @exec{raco setup} 检测到缺失的依赖可以添加为构建时依赖，它会建议添加，但 @exec{raco setup} 不会建议将普通依赖转换为构建时依赖（因为每个普通依赖也算作构建时依赖）。

@; ------------------------------------------------------------------------

@section[#:tag "setup-plt-plt"]{Setup API}

@defmodule[setup/setup]

@defproc[(setup [#:file file (or/c #f path-string?) #f]
                [#:collections collections (or/c #f (listof (listof path-string?))) #f]
                [#:pkgs pkgs (or/c #f (listof string?)) #f]
                [#:planet-specs planet-specs (or/c #f 
                                                   (listof (list/c string?
                                                                   string?
                                                                   exact-nonnegative-integer?
                                                                   exact-nonnegative-integer?)))
                                             #f]
                [#:make-user? make-user? any/c #t]
                [#:avoid-main? avoid-main? any/c #f]
                [#:make-docs? make-docs? any/c #t]
                [#:make-doc-index? make-doc-index? any/c #f]
                [#:force-user-docs? force-user-docs? any/c #f]
                [#:check-pkg-deps? check-pkg-deps? any/c #f]
                [#:fix-pkg-deps? fix-pkg-deps? any/c #f]
                [#:unused-pkg-deps? unused-pkg-deps? any/c #f]
                [#:clean? clean? any/c #f]
                [#:tidy? tidy? any/c #f]
                [#:recompile-only? recompile-only? any/c #f]
                [#:recompile-cache recompile-cache (or/c path-string? #f) #f]
                [#:jobs jobs exact-nonnegative-integer? #f]
                [#:fail-fast? fail-fast? any/c #f]
                [#:get-target-dir get-target-dir (or/c #f (-> path-string?)) #f])
          boolean?]{
使用各种选项运行 @exec{raco setup}：

@itemlist[

 @item{@racket[file] --- 如果不为 @racket[#f]，则将 @racket[file] 作为 @filepath{.plt} 归档安装。}

 @item{@racket[collections] --- 如果不为 @racket[#f]，则将 setup 限制到命名的集合（以及 @racket[pkgs] 和 @racket[planet-specs]，如果有的话）}

 @item{@racket[pkgs] --- 如果不为 @racket[#f]，则将 setup 限制到命名的包（以及 @racket[collections] 和 @racket[planet-specs]，如果有的话）}

 @item{@racket[planet-spec] --- 如果不为 @racket[#f]，则将 setup 限制到命名的 @|PLaneT| 包（以及 @racket[collections] 和 @racket[pkgs]，如果有的话）}

 @item{@racket[make-user?] --- 如果为 @racket[#f]，则禁用任何用户特定的 setup 操作}

 @item{@racket[avoid-main?] --- 如果为 true，则避免影响主安装的 setup 操作，相对于用户目录}

 @item{@racket[make-docs?] --- 如果为 @racket[#f]，则禁用任何文档特定的 setup 操作}

 @item{@racket[make-doc-index?] --- 如果为 true，则除了 @racket[collections] 之外还构建文档索引集合，假设文档正在构建}

 @item{@racket[force-user-docs?] --- 如果为 true，则在构建文档时创建用户特定的文档入口点，即使其内容与安装相同}

 @item{@racket[check-pkg-deps?] --- 如果为 true，则即使 @racket[collections]、@racket[pkgs] 或 @racket[planet-specs] 为非 @racket[#f]，也启用包依赖检查。}

 @item{@racket[fix-pkg-deps?] --- 如果为 true，则隐含 @racket[check-pkg-deps?] 并尝试自动纠正发现的包依赖问题}
 
 @item{@racket[unused-pkg-deps?] --- 如果为 true，则隐含 @racket[check-pkg-deps?] 并报告看起来未使用的依赖}

 @item{@racket[clean?] --- 如果为 true，则启用清理模式而非 setup 模式}

 @item{@racket[tidy?] --- 如果为 true，则即使 @racket[collections] 或 @racket[planet-specs] 为非 @racket[#f]，也启用全局文档和元数据索引清理}

 @item{@racket[recompile-only?] --- 如果为 true，则禁止从源码编译，仅允许时间戳调整和从机器无关格式重新编译}

 @item{@racket[recompile-cache] --- 如果不为 @racket[#f]，则为缓存从机器无关格式到机器相关格式的重新编译的目录}

 @item{@racket[jobs] --- 如果不为 @racket[#f]，则确定用于 setup 的最大并行任务数}

 @item{@racket[fail-fast?] --- 如果为 true，则一旦发现错误就中断当前线程}

 @item{@racket[get-target-dir] --- 如果不为 @racket[#f]，则被视为 @sigelem[setup-option^ current-target-directory-getter] 的值}

]

如果 @exec{raco setup} 无错误完成，则结果为 @racket[#t]，否则为 @racket[#f]。

@racket[setup] 不对 @envvar{PLT_COMPILED_FILE_CHECK} 敏感，而是对 @racket[use-compiled-file-check] 参数敏感。

@history[#:changed "6.1" @elem{Added the @racket[fail-fast?] argument.}
         #:changed "6.1.1" @elem{Added the @racket[force-user-docs?] argument.}
         #:changed "7.2.0.7" @elem{Added the @racket[check-pkg-deps?],
                                   @racket[fix-pkg-deps?] , and @racket[unused-pkg-deps?]
                                   arguments.}
         #:changed "7.2.0.8" @elem{Added the @racket[recompile-only?] argument.}
         #:changed "8.17.0.2" @elem{Added the @racket[recompile-cache] argument.}]}


@subsection{@exec{raco setup} 单元}

@defmodule[setup/setup-unit]

@racketmodname[setup/setup-unit] 库以 unit 形式提供 @exec{raco setup}。关联的 @racket[setup/option-sig] 和 @racket[setup/option-unit] 库提供为运行 @exec{raco setup} 设置选项的接口。

例如，要解包单个 @filepath{.plt} 归档 @filepath{x.plt}，将 @sigelem[setup-option^ archives] 参数设置为 @racket[(list "x.plt")] 并保持 @sigelem[setup-option^ specific-collections] 为 @racket[null]。

将选项单元和 setup 单元链接起来，使选项设置代码在它们之间初始化，例如：

@racketblock[
(compound-unit
  _...
  (link _...
    [((OPTIONS : setup-option^)) setup:option@]
    [() my-init-options@ OPTIONS]
    [() setup@ OPTIONS _...])
  _...)
]

@defthing[setup@ unit?]{

Imports

  @itemize[#:style "compact"]{
    @item{@racket[setup-option^]}
    @item{@racket[compiler^]}
    @item{@racket[compiler:option^]}
    @item{@racket[launcher^]}
    @item{@racket[dynext:file^]}
  }

并且不导出任何内容。调用 @racket[setup@] 启动 setup 过程。}

@; ----------------------------------------

@subsection[#:tag "setup-plt-options"]{选项单元}

@defmodule[setup/option-unit]

@defthing[setup:option@ unit?]{

不导入任何内容，导出 @racket[setup-option^]。}

@; ----------------------------------------

@subsection{选项签名}

@defmodule[setup/option-sig]

@defsignature[setup-option^ ()]{

@signature-desc{提供用于以 unit 形式控制 @exec{raco setup} 的参数。}

  @defparam[setup-program-name name string?]{
    打印状态消息时使用的前缀。
    @defaults[@racket["raco setup"]]
  }

@defparam[setup-compiled-file-paths paths (or/c #f (listof (and/c path? relative-path?)))]{
 如果不为 @racket[#f]，则提供类似于 @racket[use-compiled-file-paths] 的值来控制清理等操作，因为 @racket[use-compiled-file-paths] 可能已被设置为 @racket[null] 以避免加载字节码。

 @history[#:added "1.7"]}

@defboolparam[verbose on?]{
  如果开启，则从 @exec{make} 向 @envvar{stderr} 打印消息。
  @defaults[@racket[#f]]}

@defboolparam[make-verbose on?]{
  如果开启，则详细输出 @exec{make}。@defaults[@racket[#f]]}

@defboolparam[compiler-verbose on?]{
  如果开启，则详细输出 @exec{compiler}。@defaults[@racket[#f]]}

@defboolparam[clean on?]{
 如果开启，则删除指定集合中的 @filepath{.zo} 和
 @filepath{.so}/@filepath{.dll}/@filepath{.dylib} 文件。@defaults[@racket[#f]]}

@defparam[compile-mode path (or/c path? #f)]{
  如果提供了 @racket[path]，则使用非普通 @exec{compile} 的 @filepath{.zo} 编译器，并构建到 @racket[(build-path "compiled" (compile-mode))]。
  @defaults[@racket[#f]]}

@defboolparam[make-zo on?]{
  如果开启，则编译 @filepath{.zo}。@defaults[@racket[#t]]}

@defboolparam[make-info-domain on?]{
  如果开启，则为每个集合路径更新 @filepath{info-domain/compiled/cache.rkt}。@defaults[@racket[#t]]}

@defboolparam[make-launchers on?]{
  如果开启，则创建集合 @filepath{info.rkt} 指定的启动器和 @tt{man} 页面。@defaults[@racket[#t]]}

@defboolparam[make-foreign-lib on?]{
  如果开启，则安装集合 @filepath{info.rkt} 指定的库。@defaults[@racket[#t]]}

  @defboolparam[make-docs on?]{
    如果开启，则构建文档。
    @defaults[@racket[#t]]
  }
  
  @defboolparam[make-user on?]{
    如果开启，则构建用户特定的集合树。
    @defaults[@racket[#t]]
  }
  
  @defboolparam[make-planet on?]{
    如果开启，则构建 planet 缓存。
    @defaults[@racket[#t]]
  }
  
@defboolparam[avoid-main-installation on?]{
 如果开启，则在构建其他字节码（例如在用户特定集合中）时避免在主安装树中构建字节码。@defaults[@racket[#f]]}

@defboolparam[make-tidy on?]{
 如果开启，则即使 @racket[specific-collections] 或 @racket[specific-planet-dirs] 为非 @racket['()] 或 @racket[make-only] 为 true，也删除不存在集合的元数据缓存信息和文档（以清理移除后的残留）。@defaults[@racket[#f]]}

@defboolparam[call-install on?]{
  如果开启，则调用集合 @filepath{info.rkt} 指定的 setup 代码。
  @defaults[@racket[#t]]}

@defboolparam[call-post-install on?]{
  如果开启，则调用集合 @filepath{info.rkt} 指定的安装后代码。
  @defaults[@racket[#t]]}

@defboolparam[pause-on-errors on?]{
  如果开启，则在发生错误时打印摘要错误并等待 @envvar{stdin} 输入后再终止。@defaults[@racket[#f]]}

  @defparam[parallel-workers num exact-nonnegative-integer?]{
    确定用于编译字节码和构建文档的 place 数量。
    @defaults[@racket[(min (processor-count) 8)]]
  }

@defboolparam[fail-fast on?]{
  如果开启，则一旦发现错误就中断原始线程。
  @defaults[@racket[#f]]

  @history[#:added "1.2"]}
  
@defboolparam[force-unpacks on?]{
  如果开启，则在解包 @filepath{.plt} 归档时忽略版本和已安装错误。@defaults[@racket[#f]]}
  
@defparam[specific-collections colls (listof (listof path-string?))]{
  要设置的集合列表；空列表意味着如果归档列表和 @racket[specific-planet-dirs] 也为 @racket['()]，则设置所有集合。@defaults[@racket['()]]}

  @defparam[specific-planet-dirs dir (listof (list/c string?
                                                     string?
                                                     exact-nonnegative-integer?
                                                     exact-nonnegative-integer?))]{
    要设置的 planet 包版本规格列表；空列表意味着如果归档列表和 @racket[specific-collections] 也为 @racket['()]，则设置所有 planet 集合。@defaults[@racket['()]]
  }

@defboolparam[make-only on?]{
 如果为 true，则如果 @racket[specific-collections] 和 @racket[specific-planet-dirs] 均为 @racket['()]，不设置任何集合。}
  
@defparam[archives arch (listof path-string?)]{
  要解包的 @filepath{.plt} 归档列表；归档指定的任何集合除了 @racket[specific-collections] 中列出的集合外也被设置。@defaults[@racket[null]]}

@defboolparam[archive-implies-reindex on?]{
  如果开启，当 @racket[archives] 具有非空包列表时，如果构建了任何文档，则重新构建合适的文档起始页、搜索页和主索引页。@defaults[@racket[#t]]}

@defparam[current-target-directory-getter thunk (-> path-string?)]{
  一个返回解包相对 @filepath{.plt} 归档的目标目录的 thunk；解包归档时，将调用此过程或 @racket[current-target-plt-directory-getter] 中的过程。@defaults[@racket[current-directory]]}

@defparam[current-target-plt-directory-getter
          proc (path-string?
                path-string?
                (listof path-string?) . -> . path-string?)]{
  一个过程，接受首选路径、主 @filepath{collects} 目录的父目录路径以及路径选择列表；它返回用于“plt 相对”安装的路径；解包归档时，将调用此过程或 @racket[current-target-directory-getter] 中的过程，在前一种情况下，此过程可能被多次调用。@defaults[@racket[(lambda (preferred main-parent-dir choices) preferred)]]}

}

@; ----------------------------------------

@subsection{Setup 启动模块}

@defmodule[setup]{@racketmodname[setup] 库实现 @exec{raco setup}，包括在 @exec{raco setup} 自身实现需要编译时引导它的部分。}

当通过 @exec{racket} 运行 @racketmodname[setup] 时，提供 @exec{@Flag{N} raco} 以确保命令行参数解析方式与 @exec{raco setup} 相同，而非使用旧版命令行模式。

@; ------------------------------------------------------------------------

@section[#:tag ".plt-archives"]{安装 @filepath{.plt} 归档文件的 API}

@racketmodname[setup/plt-single-installer] 模块提供了一个用于安装单个 @filepath{.plt} 文件的函数。

@subsection{非 GUI 安装器}

@local-module[setup/plt-single-installer]{

@defmodule[setup/plt-single-installer]

@defproc[(run-single-installer
          (file path-string?)
          (get-dir-proc (-> (or/c path-string? #f)))
          [#:show-beginning-of-file? show-beginning-of-file? any/c #f])
         void?]{
   创建一个单独的线程和命名空间，在新命名空间的线程中运行安装器，并在线程完成或终止时返回。它还创建一个 custodian（参见 @secref[#:doc ref-src]{custodians}）来管理创建的线程，设置线程的退出处理程序以关闭 custodian，并在创建的线程终止或消亡时显式关闭 custodian。

   如果安装器需要安装的目标目录，则调用 @racket[get-dir-proc] 过程，@racket[#f] 结果表示用户取消了安装。通常，@racket[get-dir-proc] 是 @racket[current-directory]。
   
   如果 @racket[show-beginning-of-file?] 为真值且安装失败，则 @racket[run-single-installer] 打印文件的前 1,000 个字符（以帮助调试失败原因）。
}

@defproc[(install-planet-package [file path-string?] 
                                 [directory path-string?] 
                                 [spec (list/c string? string? 
                                               (listof string?) 
                                               exact-nonnegative-integer?
                                               exact-nonnegative-integer?)])
         void?]{

 类似于 @racket[run-single-installer]，但运行 setup 过程以将归档 @racket[file] 安装到 @racket[directory] 作为 @racket[spec] 描述的 @|PLaneT| 包。用户特定的文档索引不会被重建，因此在一组 @|PLaneT| 包安装后应运行 @racket[reindex-user-documentation]。}

@defproc[(reindex-user-documentation) void?]{
  类似于 @racket[run-single-installer]，但仅运行 setup 过程中重建用户特定文档起始页、搜索页和主索引的部分。}

@defproc[(clean-planet-package [directory path-string?] 
                               [spec (list/c string? string? 
                                             (listof string?) 
                                             exact-nonnegative-integer?
                                             exact-nonnegative-integer?)])
         void?]{
  撤销 @racket[install-planet-package] 的工作。用户特定的文档索引不会被重建，因此在一组 @|PLaneT| 包移除后应运行 @racket[reindex-user-documentation]。}}


@; ----------------------------------------------------------

@section[#:tag "dirs"]{查找安装目录的 API}

@defmodule[setup/dirs]{@racketmodname[setup/dirs] 库提供了几个用于定位安装目录的过程。其中许多路径可以通过 @tech{配置目录}（参见 @secref["config-file"]）进行配置。}

在跨平台构建模式下（参见 @secref["cross-system"]），@racketmodname[setup/dirs] 提供的函数通常报告目标系统路径而非当前系统路径。例外是 @racket[get-lib-search-dirs] 和 @racket[find-dll-dir]，它们报告当前系统路径，而 @racket[get-cross-lib-search-dirs] 和 @racket[find-cross-dll-dir] 报告目标系统路径。

@(define-syntax-rule (see-config id)
   @elem{See also @racket['id] in @secref["config-file"].})

@defproc[(find-collects-dir) (or/c path? #f)]{
  返回安装的主 @filepath{collects} 目录的路径，如果找不到则返回 @racket[#f]。@racket[#f] 结果可能仅出现在不带有库分发的独立可执行文件中。}

@(define-syntax user-path
   (syntax-rules ()
     [(_ dir vers)
      @list{The user-specific path depends on at least
            @racket[(find-system-path 'addon-dir)] and
            @racket[vers].}]
     [(_ dir)
      (user-path dir (get-installation-name))]))

@defproc[(find-user-collects-dir) path?]{
  返回用户特定 @filepath{collects} 目录的路径；返回路径指示的目录可能存在也可能不存在。

  @user-path["collects"]}

@defproc[(get-collects-search-dirs) (listof path?)]{
  返回与 @racket[(current-library-collection-paths)] 相同的结果，这意味着此结果不对 @racket[use-user-specific-search-paths] 参数的值敏感。}

@defproc[(get-main-collects-search-dirs) (listof path?)]{
  返回安装 @filepath{collects} 目录的路径列表，通常包括 @racket[find-collects-dir] 的结果。这些目录通常包含在 @racket[(current-library-collection-paths)] 的结果中，但 @envvar{PLTCOLLECTS} 设置或对该参数的更改可能导致它们被忽略。@racket[(current-library-collection-paths)] 中的任何其他路径被视为用户特定的。返回路径指示的目录可能存在也可能不存在。

  主集合搜索路径可以通过 @filepath{config.rktd} 中的 @racket['collects-search-dirs] 配置（参见 @secref["config-file"]）。}

@defproc[(find-config-dir) (or/c path? #f)]{
  返回安装的 @filepath{etc} 目录的路径，该目录包含配置和包信息——包括其他一些目录的配置（参见 @secref["config-file"]）。@racket[#f] 结果表示没有可用的配置目录。}

@defproc[(find-links-file) (or/c path? #f)]{
  返回安装的 @tech[#:doc reference-doc]{集合链接文件}的路径。返回路径指示的文件可能存在也可能不存在。@racket[#f] 结果表示没有可用的链接文件。

  @see-config[links-file]}

@defproc[(find-user-links-file [vers string? (get-installation-name)]) path?]{
  返回用户的 @tech[#:doc reference-doc]{集合链接文件}的路径。返回路径指示的文件可能存在也可能不存在。

  @user-path["links.rktd" vers]}

@defproc[(get-links-search-files) (listof path?)]{
  返回安装的 @tech[#:doc reference-doc]{集合链接文件}的路径列表，按顺序搜索。（通常，结果包括 @racket[(find-links-file)] 的结果，@exec{raco link} 或 @racket[links] 将新安装范围的链接安装到该位置。）@racket[find-user-links-file] 的结果 @emph{不}添加到返回的列表中。返回路径指示的文件可能存在也可能不存在。

  @see-config[links-search-files]}

@defproc[(find-pkgs-dir) (or/c path? #f)]{
  返回包含安装范围的包的目录路径；返回路径指示的目录可能存在也可能不存在。@racket[#f] 结果表示没有可用的包安装目录。

  @see-config[pkgs-dir]}

@defproc[(find-user-pkgs-dir [vers string? (get-installation-name)]) path?]{
  返回包含安装名称为 @racket[vers] 的用户特定范围的包的目录路径；返回路径指示的目录可能存在也可能不存在。

  @user-path["pkgs" vers]}

@defproc[(get-pkgs-search-dirs) (listof path?)]{
  返回包含安装范围的包的目录路径列表。（通常，结果包括 @racket[(find-pkgs-dir)] 的结果，@|raco-pkg-install| 将新包安装到该位置。）@racket[find-user-pkgs-dir] 的结果 @emph{不}添加到返回的列表中。返回路径指示的目录可能存在也可能不存在。

  @see-config[pkgs-search-dirs]}

@defproc[(find-doc-dir) (or/c path? #f)]{
  返回安装的 @filepath{doc} 目录的路径。如果没有这样的目录可用，则结果为 @racket[#f]。

  @see-config[doc-dir]}

@defproc[(find-user-doc-dir) path?]{
  返回用户特定的 @filepath{doc} 目录的路径。返回路径指示的目录可能存在也可能不存在。

  @user-path["doc"]}

@defproc[(get-doc-search-dirs) (listof path?)]{
  返回搜索文档的路径列表，不包括存储在各个集合中的文档。除非另有配置，结果包括 @racket[(find-doc-dir)] 和 @racket[(find-user-doc-dir)] 的任何非 @racket[#f] 结果——但后者仅在 @racket[use-user-specific-search-paths] 参数的值为 @racket[#t] 时包含。

  @see-config[doc-search-dirs]}

@defproc[(get-doc-extra-search-dirs) (listof path?)]{
  类似于 @racket[get-doc-search-dirs]，但不将 @racket[(find-doc-dir)] 和 @racket[(find-user-doc-dir)] 添加到底层 @racket['doc-search-dirs] 配置中。

  @history[#:added "8.1.0.6"]}

@defproc[(find-lib-dir) (or/c path? #f)]{
  返回安装的 @filepath{lib} 目录的路径，该目录包含库和其他构建信息。如果没有这样的目录可用，则结果为 @racket[#f]。

  @see-config[lib-dir]}

@defproc[(find-user-lib-dir) path?]{
  返回用户特定的 @filepath{lib} 目录的路径；返回路径指示的目录可能存在也可能不存在。

  @user-path["lib"]}

@defproc[(get-lib-search-dirs) (listof path?)]{
  返回搜索外部库的路径列表。

  除非另有配置，且除跨平台构建模式外，结果包括 @racket[(find-lib-dir)] 和 @racket[(find-user-lib-dir)] 的任何非 @racket[#f] 结果——但后者仅在 @racket[use-user-specific-search-paths] 参数的值为 @racket[#t] 时包含。

  在跨平台构建模式下（参见 @secref["cross-system"]），@racket[get-lib-search-dirs] 报告适合当前系统而非目标系统的结果。另请参见 @racket[get-cross-lib-search-dirs]。

  @see-config[lib-search-dirs]

  @history[#:changed "6.1.1.4" @elem{从默认显式包含的路径集中移除了 @racket[(find-dll-dir)]。}
           #:changed "6.9.0.1" @elem{更改了跨平台构建模式下的行为。}]}

@defproc[(get-cross-lib-search-dirs) (listof path?)]{
  类似于 @racket[get-lib-search-dirs]，但在跨平台构建模式下，报告目标系统而非当前系统的目录（包括 @racket[(find-lib-dir)] 等的任何非 @racket[#f] 结果）。

  @history[#:added "6.9.0.1"]}

@defproc[(get-cross-lib-extra-search-dirs) (listof path?)]{
  类似于 @racket[get-cross-lib-search-dirs]，但不将 @racket[(find-lib-dir)] 和 @racket[(find-user-lib-dir)] 添加到底层 @racket['lib-search-dirs] 配置中。

  @history[#:added "8.1.0.6"]}

@defproc[(find-dll-dir) (or/c path? #f)]{
  返回包含供当前可执行文件使用的 DLL 的目录路径（例如，Windows 上的 @filepath{libracket.dll}）。如果没有这样的目录可用，或没有特定目录可用（即，除平台正常搜索路径外），则结果为 @racket[#f]。

  在跨平台构建模式下（参见 @secref["cross-system"]），@racket[find-dll-dir] 报告适合当前系统而非目标系统的结果。另请参见 @racket[find-cross-dll-dir]。

  @history[#:changed "6.9.0.1" @elem{更改了跨平台构建模式下的行为。}]}

@defproc[(find-cross-dll-dir) (or/c path? #f)]{
  类似于 @racket[find-dll-dir]，但在跨平台构建模式下，报告目标系统而非当前系统的目录。

  @history[#:added "6.9.0.1"]}

@defproc[(find-share-dir) (or/c path? #f)]{ 返回安装的 @filepath{share} 目录的路径，该目录包含已安装的包和其他平台无关文件。如果没有这样的目录可用，则结果为 @racket[#f]。

  @see-config[share-dir]}

@defproc[(find-user-share-dir) path?]{
  返回用户特定的 @filepath{share} 目录的路径；返回路径指示的目录可能存在也可能不存在。

  @user-path["share"]}

@defproc[(get-share-search-dirs) (listof path?)]{
  返回搜索通常位于 @filepath{share} 目录中的文件的路径列表。

  除非另有配置，结果包括 @racket[(find-share-dir)] 和 @racket[(find-user-share-dir)] 的任何非 @racket[#f] 结果——但后者仅在 @racket[use-user-specific-search-paths] 参数的值为 @racket[#t] 时包含。

  @see-config[share-search-dirs]

  @history[#:added "8.1.0.6"]}

@defproc[(get-share-extra-search-dirs) (listof path?)]{
  类似于 @racket[get-share-search-dirs]，但不将 @racket[(find-share-dir)] 和 @racket[(find-user-share-dir)] 添加到底层 @racket['share-search-dirs] 配置中。

  @history[#:added "8.1.0.6"]}

@defproc[(find-include-dir) (or/c path? #f)]{
  返回安装的 @filepath{include} 目录的路径，该目录包含用于构建 Racket 扩展和嵌入程序的 @filepath{.h} 文件。如果没有这样的目录可用，则结果为 @racket[#f]。

  @see-config[include-dir]}

@defproc[(find-user-include-dir) path?]{
  返回用户特定的 @filepath{include} 目录的路径；返回路径指示的目录可能存在也可能不存在。

  @user-path["include"]}

@defproc[(get-include-search-dirs) (listof path?)]{
  返回搜索 @filepath{.h} 文件的路径列表。除非另有配置，结果包括 @racket[(find-include-dir)] 和 @racket[(find-user-include-dir)] 的任何非 @racket[#f] 结果——但后者仅在 @racket[use-user-specific-search-paths] 参数的值为 @racket[#t] 时包含。

  @see-config[include-search-dirs]}

@defproc[(find-console-bin-dir) (or/c path? #f)]{
  返回安装的可执行文件目录的路径，独立 Racket 可执行文件位于该目录。如果没有这样的目录可用，则结果为 @racket[#f]。

  @see-config[bin-dir]}

@defproc[(find-gui-bin-dir) (or/c path? #f)]{
  返回安装的可执行文件目录的路径，独立 GRacket 可执行文件位于该目录。如果没有这样的目录可用，则结果为 @racket[#f]。

  @see-config[gui-bin-dir]}

@defproc[(find-user-console-bin-dir) path?]{
  返回用户可执行文件目录的路径；返回路径指示的目录可能存在也可能不存在。

  @user-path[#f]}

@defproc[(find-user-gui-bin-dir) path?]{
  返回用户图形程序可执行文件目录的路径；返回路径指示的目录可能存在也可能不存在。

  @user-path[#f]}

@defproc[(get-console-bin-search-dirs) (listof path?)]{
  类似于 @racket[get-share-search-dirs]，但用于搜索可执行文件（如 @exec{racket}）的路径。

  @see-config[bin-search-dirs]

  @history[#:added "8.1.0.6"]}

@defproc[(get-console-bin-extra-search-dirs) (listof path?)]{
  类似于 @racket[get-share-extra-search-dirs]，针对底层 @racket['bin-search-dirs] 配置。

  @history[#:added "8.1.0.6"]}

@defproc[(get-gui-bin-search-dirs) (listof path?)]{
  类似于 @racket[get-share-search-dirs]，但用于搜索可执行文件（如 @exec{gracket}）的路径。

  @see-config[gui-bin-search-dirs]

  @history[#:added "8.1.0.6"]}

@defproc[(get-gui-bin-extra-search-dirs) (listof path?)]{
  类似于 @racket[get-share-extra-search-dirs]，针对底层 @racket['gui-bin-search-dirs] 配置。

  @history[#:added "8.1.0.6"]}

@defproc[(find-apps-dir) (or/c path? #f)]{
  返回安装的 @filepath{.desktop} 文件目录的路径（用于 Unix）。如果不存在这样的目录，则结果为 @racket[#f]。

  @see-config[apps-dir]}

@defproc[(find-user-apps-dir) path?]{
  返回用户 @filepath{.desktop} 文件目录的路径（用于 Unix）；返回路径指示的目录可能存在也可能不存在。

  @user-path[#f]}

@defproc[(find-man-dir) (or/c path? #f)]{
  返回安装的 man 页面目录的路径。如果不存在这样的目录，则结果为 @racket[#f]。@see-config[man-dir]}

@defproc[(find-user-man-dir) path?]{
  返回用户 man 页面目录的路径；返回路径指示的目录可能存在也可能不存在。

  @user-path["man"]}

@defproc[(get-man-search-dirs) (listof path?)]{
  类似于 @racket[get-share-search-dirs]，但用于搜索 man 页面的路径。

  @see-config[man-search-dirs]

  @history[#:added "8.1.0.6"]}

@defproc[(get-man-extra-search-dirs) (listof path?)]{
  类似于 @racket[get-share-extra-search-dirs]，针对底层 @racket['man-search-dirs] 配置。

  @history[#:added "8.1.0.6"]}

@defproc[(get-info-domain-root) (or/c #false path?)]{
  返回 @racket[#f] 或一个用作前缀的路径，用于重定向通过 @racket[find-relevant-directories] 记录和查找 @filepath{info.rkt} 信息的路径。

  @history[#:added "8.10.0.4"]}

@defproc[(get-doc-search-url) string?]{
  返回一个字符串，文档系统使用该字符串并附加版本和搜索关键词查询，用于远程文档链接。

  @see-config[doc-search-url]}

@defproc[(get-doc-open-url) (or/c string? #f)]{
  返回 @racket[#f] 或一个根 URL 字符串，用作打开本地文档文件的替代方案。非 @racket[#f] 配置意味着例如 DrRacket 通过指定的 URL 而非本地安装的文档执行文档关键词搜索。

  @see-config[doc-open-url]

  @history[#:added "6.0.1.6"]}

@defproc[(get-installation-name [config (read-installation-configuration-table)]) string?]{

 返回当前安装的名称，通常是 @racket[(version)]，但安装名称可以通过 @racket[config] 中的 @racket['installation-name] 值加上用户特定的目录状态来设置（如果 @racket[(use-user-specific-search-paths)] 为 @racket[#t]）。

 用户特定的结果取决于 @racket[(find-system-path 'addon-dir)] 中是否存在 @as-index{@filepath{other-version}} 目录。如果该目录存在，且不存在具有安装配置名称的目录，则使用 @racket["other-version"] 作为安装名称。因此，通过创建 @filepath{other-version} 目录，用户可以选择跨安装/版本共享包和集合，同时通过创建具有该安装名称的目录来选择退出特定安装/版本。

 @history[#:changed "8.4.0.3" @elem{Added the @racket[config] argument and support for a
                                    user-specific installation name.}]}

@defproc[(get-build-stamp) (or/c #f string?)]{ 返回一个标识安装构建的字符串，可用于增强 Racket 版本号以更具体地标识构建。发布构建通常产生空字符串。如果没有可用的构建戳记，则结果为 @racket[#f]。

   @see-config[build-stamp]}

@defproc[(get-main-language-family) string?]{

  返回命名安装主 @tech{语言家族}的字符串。默认值为 @racket["Racket"]。

  @see-config[main-language-family]

  @history[#:added "8.14.0.5"]
}

@deftogether[(
@defproc[(get-base-documentation-packages) (listof string?)]
@defproc[(get-distribution-documentation-packages) (listof string?)]
)]{

   返回分别表示发行版基础语言文档和发行版所有文档的包名称列表。这些列表用于对文档搜索结果进行分类和排序。如果包是基础文档的一部分，则该分类优先于发行版文档。

   另请参见 @secref["config-file"] 中的 @racket['base-documentation-packages] 和 @racket['distribution-documentation-packages]。

   @history[#:added "8.14.0.5"]}

@defproc[(get-absolute-installation?) boolean?]{
  如果此安装对可执行文件和库引用使用绝对路径名，则返回 @racket[#t]，否则返回 @racket[#f]。}

@deftogether[(
@defproc[(find-addon-tethered-console-bin-dir) (or/c #f path?)]
@defproc[(find-addon-tethered-gui-bin-dir) (or/c #f path?)]
@defproc[(find-addon-tethered-apps-dir) (or/c #f path?)]
)]{
  返回一个用户特定目录的路径，用于存放每个已安装可执行文件和 @filepath{.desktop} 文件（用于 Unix）的额外副本，其中额外副本由 @exec{raco setup} 创建并绑定到 @racket[(find-system-path 'addon-dir)] 和 @racket[(find-config-dir)] 的特定结果。

  与其他通过 @racket[(find-config-dir)] 目录中的 @filepath{config.rktd} 配置的目录不同（参见 @secref["config-file"]），这些路径通过 @racket[(build-path (find-system-path 'addon-dir) "etc")] 中 @filepath{config.rktd} 的 @racket['addon-tethered-console-bin-dir]、@racket['addon-tethered-gui-bin-dir] 和 @racket['addon-tethered-apps-dir] 条目配置。如果不存在配置，则相应函数 @racket[find-addon-tethered-console-bin-dir]、@racket[find-addon-tethered-gui-bin-dir] 或 @racket[find-addon-tethered-apps-dir] 的结果为 @racket[#f] 而非路径。

  更多信息请参见 @secref["tethered-install"]。

  @history[#:added "6.5.0.2"
           #:changed "8.3.0.11" @elem{Added @racket[find-addon-tethered-apps-dir].}]]}


@deftogether[(
@defproc[(find-config-tethered-console-bin-dir) (or/c #f path?)]
@defproc[(find-config-tethered-gui-bin-dir) (or/c #f path?)]
@defproc[(find-config-tethered-apps-dir) (or/c #f path?)]
)]{
  类似于 @racket[find-addon-tethered-console-bin-dir]、@racket[find-addon-tethered-gui-bin-dir] 和 @racket[find-addon-tethered-apps-dir]，但通过 @racket[(find-config-dir)] 目录中的 @filepath{config.rktd} 配置（参见 @secref["config-file"]），并触发仅绑定到 @racket[(find-config-dir)] 特定值的可执行文件。

  更多信息请参见 @secref["tethered-install"]。

  @history[#:added "6.5.0.2"
           #:changed "8.3.0.11" @elem{Added @racket[find-addon-tethered-apps-dir].}]}
 
@; ------------------------------------------------------------------------

@section[#:tag "getinfo"]{读取 @filepath{info.rkt} 文件的 API}

@defmodule[setup/getinfo]{@racketmodname[setup/getinfo] 库提供了访问 @filepath{info.rkt} 文件中字段的函数。@filepath{info.rkt} 文件的格式文档见 @secref["info.rkt" #:doc '(lib "scribblings/raco/raco.scrbl")]。
}

@defproc[(get-info [collection-names (listof string?)]
                   [#:namespace namespace (or/c namespace? #f) #f]
                   [#:bootstrap? bootstrap? any/c #f])
         (or/c
          ((symbol?) ((-> any)) . ->* . any)
          #f)]{
   接受一个命名集合或子集合的字符串列表，并使用与命名集合对应的完整路径和 @racket[namespace] 参数调用 @racket[get-info/full]。}

@defproc[(get-info/full [path path-string?]
                        [#:namespace namespace (or/c namespace? #f) #f]
                        [#:bootstrap? bootstrap? any/c #f])
         (or/c
          ((symbol?) ((-> any)) . ->* . any)
          #f)]{

   接受一个目录路径。如果它找到格式正确的 @filepath{info.rkt} 文件或 @filepath{info.ss} 文件（优先使用 @filepath{info.rkt} 文件），则返回一个接受一个或两个参数的 info 过程。info 过程的第一个参数始终是符号名称，结果是 @filepath{info.rkt} 文件中该名称的值（如果该名称已定义）。可选的第二个参数 @racket[_thunk] 是一个不接受参数的过程，在名称未定义时调用；在这种情况下，info 过程的结果是 @racket[_thunk] 的结果。如果名称未定义且未提供 @racket[_thunk]，则引发异常。

   如果目录中没有 @filepath{info.rkt}（或 @filepath{info.ss}）文件，@racket[get-info/full] 函数返回 @racket[#f]。如果存在格式不正确的 @filepath{info.rkt}（或 @filepath{info.ss}）文件（即，不是使用 @racketmodname[info] 或 @racketmodname[setup/infotab] 的模块），或者 @filepath{info.rkt} 文件加载失败，则引发异常。如果 @filepath{info.rkt} 文件已加载，@racket[get-info/full] 返回 info 过程。如果 @filepath{info.rkt} 文件不存在，则 @racket[get-info/full] 对 @filepath{info.ss} 文件执行相同的检查，要么引发异常，要么返回 @filepath{info.ss} 文件的 info 过程。

   @filepath{info.rkt}（或 @filepath{info.ss}）模块被加载到 @racket[namespace] 中（如果它不为 @racket[#f]），否则加载到一个私有的弱持有命名空间中。

   如果 @racket[bootstrap?] 为 true，则在读取 @filepath{info.rkt}（或 @filepath{info.ss}）时将 @racket[use-compiled-file-paths] 设置为 @racket['()]，以防现有的编译文件损坏。此外，在尝试加载 @filepath{info.rkt}（或 @filepath{info.ss}）之前，@racketmodname[info] 和 @racketmodname[setup/infotab] 模块会从 @racket[get-info/full] 的命名空间附加到 @racket[namespace]。

   加载模块时，@tech[#:doc reference-doc]{环境变量集}被修剪为仅包含 @envvar{PLT_INFO_ALLOW_VARS} 环境变量中列出的环境变量，该变量包含以 @litchar{;} 分隔的名称列表。默认情况下，允许的变量名称列表为空。

   @history[#:changed "6.5.0.2" @elem{添加了环境变量修剪和 @envvar{PLT_INFO_ALLOW_VARS} 支持。}]}

@defproc[(find-relevant-directories
          (syms (listof symbol?))
          (mode (or/c 'preferred 'all-available 'no-planet 'no-user) 'preferred)) 
         (listof path?)]{

   返回一个路径列表，标识其 @filepath{info.rkt} 文件定义了一个或多个给定符号的集合和已安装的 @|PLaneT| 包。结果基于由 @exec{raco setup} 计算的缓存。

   请注意，在调用 @racket[get-info/full] 时缓存可能已过时，因此不要假设每个返回目录的 @filepath{info.rkt} 文件都会提供所请求的符号之一。

   结果按规范顺序排列（按目录名字典序排序），返回的路径适用于提供给 @racket[get-info/full]。

   如果指定了 @racket[mode]，它必须是 @racket['preferred]（默认值）、@racket['all-available]、@racket['no-planet] 或 @racket['no-user] 之一。如果 @racket[mode] 为 @racket['all-available]，@racket[find-relevant-directories] 返回所有已安装的、info 文件包含指定符号的目录——例如，如果指定了 @racket['all-available]，将搜索所有已安装 @|PLaneT| 包的所有版本。如果 @racket[mode] 为 @racket['preferred]，则仅搜索“首选”包的子集：仅返回包含任何 @|PLaneT| 包最新版本的目录。如果 @racket[mode] 为 @racket['no-planet]，则 @|PLaneT| 包不包含在搜索中。如果 @racket[mode] 为 @racket['no-user]，则仅搜索安装范围的目录，这意味着省略 @|PLaneT| 包目录。

   无论 @racket[mode] 如何，请注意 @racket[find-relevant-directories] 不会考虑 @tech[#:doc pkg-doc]{多集合包}的包级 @filepath{info.rkt} 文件，因为这些文件不属于任何集合或 @|PLaneT| 包。相反，@tech[#:doc pkg-doc]{单集合包}的 @filepath{info.rkt} 文件是集合的一部分，因此会被考虑。

   来自安装范围的 @tech[#:doc reference-doc]{集合链接文件}或具有安装范围的包的集合链接与安装的主 @filepath{lib} 目录一起缓存，来自用户特定的 @tech[#:doc reference-doc]{集合链接文件}和包的链接与用户特定目录 @racket[(build-path (find-system-path 'addon-dir) "collects")]（适用于所有版本情况）和 @racket[(build-path (find-system-path 'addon-dir) (version) "collects")]（适用于特定于版本的情况）一起缓存。这些缓存路径可以通过 @filepath{config.rktd} 中的 @racket['info-domain-root] 条目重定向（参见 @secref["config-file"]）。}

@defproc[(find-relevant-directory-records
          [syms (listof symbol?)]
          [key (or/c 'preferred 'all-available 'no-planet 'no-user)])
         (listof directory-record?)]{
  类似于 @racket[find-relevant-directories]，但返回 @racket[directory-record] 结构体而不是 @racket[path?]。
}

@defstruct[directory-record ([maj integer?]
                             [min integer?]
                             [spec any/c]
                             [path path?]
                             [syms (listof symbol?)])]{
  记录已安装集合或 @PLaneT 包信息的结构体。集合的主版本为 @racket[1]，次版本为 @racket[0]。@racket[spec] 字段是带引号的模块规格；@racket[path] 字段是此集合或 @PLaneT 包的 @tt{info.rkt} 文件在文件系统中的位置；@racket[syms] 字段包含该文件中定义的标识符。
}

@defproc[(reset-relevant-directories-state!) void?]{
   重置 @racket[find-relevant-directories] 使用的缓存。}

@; ------------------------------------------------------------------------

@section[#:tag "relative-paths"]{相对路径 API}

Racket 安装树通常可以在文件系统中移动。为了支持这一点，必须注意避免使用绝对路径。以下两个 API 涵盖了两个方面的内容：将路径转换为相对于 @filepath{collects} 树的值的办法，以及显示此类路径的办法（例如在错误消息中）。

@subsection{基于集合的路径表示}

@defmodule[setup/collects]

@defproc[(path->collects-relative [path path-string?]
                                  [#:cache cache (or/c #f (and/c hash? (not/c immutable?))) #f])
         (or/c path-string?
               (cons/c 'collects
                       (cons/c bytes? (non-empty-listof bytes?))))]{

检查 @racket[path]（通过 @racket[path->complete-path] 和 @racket[simplify-path] 归一化，第二个参数为 @racket[#f]）是否匹配 @racket[collection-file-path] 的结果。如果是，结果是一个以 @racket['collects] 开头并包含相关路径元素作为字节字符串的列表。如果不是，则原样返回路径。

如果需要，@racket[cache] 参数与 @racket[path->pkg] 一起使用。}

@defproc[(collects-relative->path
          [rel (or/c path-string?
                     (cons/c 'collects
                             (cons/c bytes? (non-empty-listof bytes?))))])
         path-string?]{

@racket[path->collects-relative] 的逆操作：如果 @racket[rel] 是一个以 @racket['collects] 开头的 pair，则使用 @racket[collection-file-path] 将其转换回路径。}

@defproc[(path->module-path [path path-string?]
                            [#:cache cache (or/c #f (and/c hash? (not/c immutable?))) #f])
         (or/c path-string? normalized-lib-module-path?)]{

类似于 @racket[path->collects-relative]，但结果要么是 @racket[path]，要么是归一化（在 @racket[collapse-module-path] 的意义上）的模块路径。}

@subsection{相对于 @filepath{collects} 的路径表示}

@defmodule[setup/main-collects]

@defproc[(path->main-collects-relative [path (or/c bytes? path-string?)])
         (or/c path? (cons/c 'collects (non-empty-listof bytes?)))]{

检查 @racket[path] 是否具有匹配由 @racket[(find-collects-dir)] 确定的主 @filepath{collects} 目录前缀的前缀。如果是，结果是一个以 @racket['collects] 开头并包含剩余路径元素作为字节字符串的列表。如果不是，则原样返回路径。

@racket[path] 参数应该是一个完整路径。在 @racket[path->main-collects-relative] 之前应用 @racket[simplify-path] 通常是个好主意。

由于历史原因，@racket[path] 可以是字节字符串，使用 @racket[bytes->path] 转换为路径。

另请参见 @racket[collects-relative->path]。}

@defproc[(main-collects-relative->path
          [rel (or/c bytes?
                     path-string?
                     (cons/c 'collects (non-empty-listof bytes?)))])
         path?]{

@racket[path->main-collects-relative] 的逆操作：如果 @racket[rel] 是一个以 @racket['collects] 开头的 pair，则将其转换回相对于 @racket[(find-collects-dir)] 的路径。}

@subsection{相对于文档的路径表示}

@defmodule[setup/main-doc]

@defproc[(path->main-doc-relative [path (or/c bytes? path-string?)])
         (or/c path? (cons/c 'doc (non-empty-listof bytes?)))]{
 类似于 @racket[path->main-collects-relative]，但它检查相对于 @racket[(find-doc-dir)] 的前缀，如果是则返回以 @racket['doc] 开头的列表。
}

@defproc[(main-doc-relative->path
          [rel (or/c bytes?
                     path-string?
                     (cons/c 'doc (non-empty-listof bytes?)))])
         path>]{

 类似于 @racket[path->main-collects-relative]，但它是 @racket[path->main-doc-relative] 的逆操作。
}


@subsection{相对于公共根目录显示路径}

@defmodule[setup/path-to-relative]

@defproc[(path->relative-string/library
          [path path-string?]
          [default (or/c (-> path-string? any/c) any/c)
                   (lambda (x) (if (path? x) (path->string x) x))]
          [#:cache cache (or/c #f (and/c hash? (not/c immutable?))) #f])
         any/c]{
  生成适合在错误消息中显示的字符串。如果路径是包内的绝对路径，结果是以 @racket["<pkgs>/"] 开头的字符串。如果路径是 @filepath{collects} 树内的绝对路径，结果是以 @racket["<collects>/"] 开头的字符串。类似地，用户特定 collects 中的路径结果前缀为 @racket["<user-collects>/"]，@PLaneT 路径结果为 @racket["<planet>/"]，进入文档的路径结果为 @racket["<doc>/"] 或 @racket["<user-doc>/"].

  如果 @racket[cache] 不为 @racket[#f]，它被用作 @racket[path->pkg] 的缓存参数，以加速包路径的检测和转换。

  如果路径不是绝对路径，或者不在以上任何类别中，则原样返回（如果需要则转换为字符串）。如果提供了 @racket[default]，则指定返回值：它可以是一个应用于路径以获取结果的过程，或结果本身。

  注意，此函数只有在提供了 @racket[default] 且它不返回字符串时才可能返回非字符串。
}

@defproc[(path->relative-string/setup
          [path path-string?]
          [default (or/c (-> path-string? any/c) any/c)
                   (lambda (x) (if (path? x) (path->string x) x))]
          [#:cache cache (or/c #f (and/c hash? (not/c immutable?))) #f])
         any/c]{

与 @racket[path->relative-string/library] 相同，用于向后兼容。}


@defproc[(make-path->relative-string
          [dirs (listof (cons (-> path?) string?))]
          [default (or/c (-> path-string? any/c) any/c)
                   (lambda (x) (if (path? x) (path->string x) x))])
         (path-string? any/c . -> . any)]{
  此函数生成类似于 @racket[path->relative-string/library] 和 @racket[path->relative-string/setup] 的函数。

  @racket[dirs] 参数确定前缀替换。它必须是一个关联列表，将路径生成 thunk 映射到指定路径中路径的前缀字符串。

  @racket[default] 确定结果函数的默认值（始终可以通过此函数的附加参数覆盖）。
}

@; ------------------------------------------------------------------------

@section[#:tag "collection-names"]{集合名称 API}

@defmodule[setup/collection-name]

@defproc[(collection-name? [v any/c]) boolean?]{

如果 @racket[v] 是一个在语法上作为集合名称有效的字符串，则返回 @racket[#t]，这意味着它是一个或多个以 @litchar{/} 分隔的字符串，每个字符串都使 @racket[collection-name-element?] 返回 true。}


@defproc[(collection-name-element? [v any/c]) boolean?]{

如果 @racket[v] 是一个在语法上作为顶级集合名称或集合名称一部分有效的字符串，则返回 @racket[#t]，这意味着它是非空的且仅包含 ASCII 字母、ASCII 数字、@litchar{-}、@litchar{+}、@litchar{_} 和 @litchar{%}，其中 @litchar{%} 仅在后面跟随两个小写十六进制数字时允许，且这些数字必须形成不是字母、数字、@litchar{-}、@litchar{+} 或 @litchar{_} 的 ASCII 值的数字。}


@; ------------------------------------------------------------------------

@section[#:tag "collection-search"]{集合搜索 API}

@defmodule[setup/collection-search]

@history[#:added "6.3"]

@defproc[(collection-search [mod-path normalized-lib-module-path?]
                            [#:init result any/c #f]
                            [#:combine combine (any/c (and/c path? complete-path?) . -> . any/c) (lambda (r v) v)]
                            [#:break? break? (any/c . -> . any/c) (lambda (r) #f)]
                            [#:all-possible-roots? all-possible-roots? any/c #f])
         any/c]{

泛化 @racket[collection-file-path] 以支持在当前配置中折叠基于集合文件的所有可能位置。与 @racket[collection-file-path] 不同，@racket[collection-search] 以模块路径形式接受文件位置，但始终作为 @racket['lib] 路径。

文件的每个可能路径（不包括 @filepath{.ss} 与 @filepath{.rkt} 之间的转换）作为第二个参数提供给 @racket[combine] 函数，其中第一个参数是当前结果，@racket[combine] 产生的值成为新结果。@racket[#:init] 参数提供初始结果。

@racket[break?] 函数基于当前值短路搜索。例如，它可以用于在找到合适路径后短路搜索。

如果 @racket[all-possible-roots?] 为 @racket[#f]，则仅在类 @filepath{collects} 目录（针对当前配置）中至少存在匹配集合目录的路径上调用 @racket[combine]。}


@defproc[(normalized-lib-module-path? [v any/c]) boolean?]{

如果 @racket[v] 是形式为 @racket['(lib @#,racket[_str])] 的模块路径（在 @racket[module-path?] 的意义上），其中 @racket[_str] 至少包含一个斜杠，则返回 @racket[#t]。@racket[collapse-module-path] 函数为基于集合的模块引用生成此类模块路径。}

@; ------------------------------------------------------------------------

@section[#:tag "matching-platform"]{平台规格 API}

@defmodule[setup/matching-platform]

@history[#:added "6.0.1.13"]

@defproc[(platform-spec? [v any/c]) boolean?]{

如果 @racket[v] 是符号、字符串或正则表达式值（在 @racket[regexp?] 的意义上），则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(matching-platform? [spec platform-spec?]
                             [#:cross? cross? any/c #f]
                             [#:system-type sys-type (or/c #f symbol?) (if cross?
                                                                           (cross-system-type)
                                                                           (system-type))]
                             [#:system-library-subpath sys-lib-subpath (or/c #f path-for-some-system?)
                                                       (if cross?
                                                           (cross-system-library-subpath #f)
                                                           (system-library-subpath #f))])
         boolean?]{

报告 @racket[spec] 是否匹配 @racket[sys-type] 或 @racket[sys-lib-subpath]，其中后者的 @racket[#f] 值被替换为默认值。

如果 @racket[spec] 是符号，则如果 @racket[sys-type] 是相同的符号，结果为 @racket[#t]，否则为 @racket[#f]。

如果 @racket[spec] 是字符串，则如果 @racket[(path->string sys-lib-subpath)] 是相同的字符串，结果为 @racket[#t]，否则为 @racket[#f]。

如果 @racket[spec] 是正则表达式值，则如果正则表达式匹配 @racket[(path->string sys-lib-subpath)]，结果为 @racket[#t]，否则为 @racket[#f]。

@history[#:changed "6.3" @elem{Added @racket[#:cross?] argument and
                                      changed the contract on @racket[sys-lib-subpath]
                                      to accept @racket[path-for-some-system?]
                                      instead of just @racket[path?].}]}

@; ------------------------------------------------------------------------

@section[#:tag "cross-system"]{跨平台配置 API}

有关 @exec{raco cross} 的信息，请参见 @other-doc[#:indirect @exec{raco cross} '(lib "raco/private/cross/raco-cross.scrbl")]，这是 @filepath{raco-cross} 包提供的工具，作为 Racket 交叉编译的便捷接口。此处记录的底层 API 支持 @exec{raco cross} 及其他工具。

@defmodule[setup/cross-system]{@racketmodname[setup/cross-system] 库提供了查询目标平台系统属性的函数，在交叉安装模式下目标平台可能与当前平台不同。}

Racket 安装在 @racket[(find-lib-dir)] 报告的目录中包含一个 @filepath{system.rktd} 文件。当该文件中的信息与运行的 Racket 信息不匹配时，@racketmodname[setup/cross-system] 模块推断 Racket 正在交叉安装模式下运行。

例如，如果针对不同平台的原位 Racket @BC 安装位于 @nonterm{cross-dir}，则运行 Racket BC 如下：

@commandline{racket -C -G @nonterm{cross-dir}/etc -X @nonterm{cross-dir}/collects -l- raco pkg}

使用当前平台的 @exec{racket} 可执行文件运行 @exec{raco pkg}，但使用 @nonterm{cross-dir} 的集合和其他配置信息，并修改 @nonterm{cross-dir} 的包。只要不需要运行平台特定库来执行请求的 @exec{raco pkg} 操作（例如安装已构建的包时），或者只要当前平台安装已包含这些库，这就可以工作。

对于 Racket @CS，交叉编译更加复杂，因为 Racket CS 的 @filepath{.zo} 文件是平台特定的：

@itemlist[

 @item{需要目标安装 @nonterm{cross-dir}，其中包含主机平台的交叉编译支持，作为安装在 @filepath{@nonterm{cross-dir}/lib} 目录中的插件。该安装可能通过在主机平台上从源码编译创建。只有 Racket CS 可以使用 CS 交叉编译插件。

       在交叉模式下运行 @exec{racket} 时，使用 @DFlag{cross-compiler} 标志指定目标机器和 @filepath{@nonterm{cross-dir}/lib} 目录的路径。}

 @item{需要标志组合 @Flag{MCR} 带有参数 @filepath{@nonterm{absolute-zo-dir}:} 来启用主机平台（使用 @litchar{:} 前的目录）和目标平台（当 @litchar{:} 后的路径为空时使用正常的编译文件子目录）的 @filepath{.zo} 文件创建。

       @nonterm{absolute-zo-dir} 可以是任何绝对路径。通常应该在执行 @exec{raco pkg} 等命令之前通过在交叉模式下运行 @exec{raco setup} 来填充它。}

]

例如，Racket CS 的 @exec{raco pkg} 示例如下：

@verbatim[#:indent 2]{
  racket --cross-compiler @nonterm{target-machine} @nonterm{cross-dir}/lib \
    -MCR @nonterm{absolute-zo-dir}: \
    -G @nonterm{cross-dir}/etc -X @nonterm{cross-dir}/collects -l- raco pkg
}

提供给 @DFlag{cross-compiler} 的 @nonterm{target-machine} 应该与 @filepath{@nonterm{cross-dir}/lib/systemd.rktd} 中的 @racketidfont{target-machine} 条目相同。

@Flag{C} 标志是 @DFlag{cross} 的简写，@Flag{M} 是 @DFlag{compile-any} 的简写，@Flag{R} 是 @DFlag{compiled} 的简写，@Flag{G} 是 @DFlag{config} 的简写，@Flag{X} 是 @DFlag{collects} 的简写，@Flag{MCR} 是 @exec{@Flag{M} @Flag{C} @Flag{R}} 的简写。

@history[#:added "6.3"]

@defproc[(cross-system-type [mode (or/c 'os 'os* 'arch 'word 'so-find 'platform
                                        'gc 'vm 'link 'machine 'target-machine
                                        'so-suffix 'so-mode 'fs-change)
                            'os])
         (or/c symbol? string? bytes? exact-positive-integer? vector?)]{

类似于 @racket[system-type]，但在交叉安装模式下用于目标平台而非当前平台。当不在交叉安装模式下时，结果与 @racket[system-type] 相同。

另请参见 @racket[system-type] 的 @racket['cross] 模式。}


@defproc[(cross-system-library-subpath [mode (or/c 'cgc '3m 'cs #f)
                                             (system-type 'gc)])
         path-for-some-system?]{

类似于 @racket[system-library-subpath]，但在交叉安装模式下用于目标平台而非当前平台。当不在交叉安装模式下时，结果与 @racket[system-library-subpath] 相同。

在交叉安装模式下，目标平台可能具有与当前平台不同的路径约定，因此结果是 @racket[path-for-some-system?] 而非 @racket[path?]。}


@defproc[(cross-installation?) boolean?]{

如果检测到交叉安装模式则返回 @racket[#t]，否则返回 @racket[#f]。}


@; ------------------------------------------------------------------------

@section[#:tag "xref"]{已安装手册的交叉引用 API}

@defmodule[setup/xref]

@defproc[(load-collections-xref [on-load (-> any/c) (lambda () (void))])
         xref?]{

要么创建并缓存，要么返回用 @racket[make-collections-xref] 创建的已缓存交叉引用记录。@racket[on-load] 函数仅在未返回先前缓存的记录时调用。}


@defproc[(make-collections-xref [#:no-user? no-user? any/c #f]
                                [#:no-main? no-main? any/c #f]
                                [#:doc-db db-path (or/c #f path?) #f]
                                [#:quiet-fail? quiet-fail? any/c #f]
                                [#:register-shutdown! register-shutdown! ((-> any) . -> . any) void])
         xref?]{

类似于 @racket[load-xref]，但自动查找使用 @exec{raco setup} 安装的所有手册的交叉引用文件。生成的交叉引用记录利用交叉引用数据库 @racket[db-path]（当支持可用时），将交叉引用详细信息的加载延迟到需要时。

如果 @racket[no-main?] 或 @racket[no-user?] 为 @racket[#t]，则分别跳过安装在主安装或用户特定位置的交叉引用信息。

如果 @racket[quiet-fail?] 为 true，则在加载交叉引用信息时抑制错误。

可以调用 @racket[register-shutdown!] 回调来注册一个函数，在不再需要 @racket[make-collections-xref] 的结果时关闭数据库连接。如果未提供 @racket[register-shutdown!] 或发送给 @racket[register-shutdown!] 的函数从未被调用，数据库连接将仅通过 @tech[#:doc reference-doc]{custodian} 关闭。}


@defproc[(get-rendered-doc-directories [no-user? any/c]
                                       [no-main? any/c]
                                       [#:keep-omit? keep-omit? any/c #f])
         (listof path?)]{

返回所有已安装集合的所有文档的目录列表，如果 @racket[no-main?] 或 @racket[no-user?] 为 @racket[#t]，则分别省略安装在主安装或用户特定位置的文档。

如果 @racket[keep-omit?] 为 true，则结果包含具有 @racket['omit] 类别的文档。

@history[#:changed "1.5" @elem{Added the @racket[#:keep-omit?] argument.}]}


@defproc[(get-current-doc-state) doc-state?]{
 记录文档更改时被修改的文件的时间戳。
 
 @history[#:added "1.2"]
}

@defproc[(doc-state-changed? [doc-state doc-state?]) boolean?]{
 当 @racket[doc-state] 中文件的时间戳发生变化（或出现新文件）时返回 @racket[#t]，否则返回 @racket[#f]。

 如果结果为 @racket[#t]，则此 Racket 安装中的文档已更改，否则未更改。

 @history[#:added "1.2"]
}
@defproc[(doc-state? [v any/c]) boolean?]{
 识别 @racket[get-current-doc-state] 结果的谓词。
 
 @history[#:added "1.2"]
}

@; ------------------------------------------------------------------------

@section[#:tag "materialize-user-docs"]{物化用户特定文档的 API}

@defmodule[setup/materialize-user-docs]

@history[#:added "1.1"]

@defproc[(materialize-user-docs [on-setup ((-> boolean?) . -> . any) (lambda (setup) (setup))]
                                [#:skip-user-doc-check? skip-user-doc-check? any/c #f])
         void?]{

检查 @racket[(find-user-doc-dir)] 中是否已存在用户特定的文档入口点，如果不存在，则以创建入口点的模式运行 @exec{raco setup}（使其内容与安装的文档入口点相同）。如果 @racket[skip-user-doc-check?] 不为 @racket[#f]，则跳过对用户特定文档入口点的检查。

@exec{raco setup} 的运行被包装在一个提供给 @racket[on-setup] 的 thunk 中，它可以适当地调整当前输出和错误端口并检查 thunk 的结果是否成功。

如果文档入口点已存在于 @racket[(find-user-doc-dir)] 中，则不调用 @racket[on-setup] 参数。

@history[#:changed "1.1" @list{Added the @racket[skip-user-doc-check?] argument.}]
}

@; ------------------------------------------------------------------------

@section[#:tag "doc-to-destdir"]{文档安装暂存 API}

@defmodule[setup/doc-to-destdir]{@racketmodname[setup/doc-to-destdir] 模块提供了暂存已渲染文档的支持，以更好地匹配包安装的文件系统布局。}

当直接运行 @racketmodname[setup/doc-to-destdir] 模块时（例如使用 @exec{racket -l}），它期望传递命令行参数给 @racket[move-rendered-docs-to-destdir]。提供 @DFlag{help} 标志可获取更多信息。

@history[#:added "9.2.0.6"]

@defproc[(move-rendered-docs-to-destdir [dir path-string?]
                                        [doc-destdir path-string?])
         void?]{

扫描 @racket[dir] 中通过 @filepath{info.rkt} 模块指定文档的集合（通常在包实现中），且指定的文档已被渲染到本地 @filepath{doc} 子目录中。已渲染的文档从 @filepath{doc} 移出并移入 @racket[doc-destdir]。此移动模拟了 @exec{raco setup} 的步骤，将已在集合中渲染的文档移入安装范围包的集中目录中。

@racket[move-rendered-docs-to-destdir] 函数旨在与 @exec{@|raco-pkg-install| @DFlag{destdir}} 结合使用，其中 @racket[dir] 与 @DFlag{destdir} 后提供的目录相同，@racket[doc-destdir] 是随附的目录，将被移入作为已渲染文档而非包实现。

}

@; ------------------------------------------------------------------------

@section[#:tag "layered-install"]{分层安装}

典型的 Racket 配置包括两层：@defterm{安装}层和 @defterm{用户}层。目的是 @defterm{安装}层对系统的所有用户是只读的，而 @defterm{用户}层允许每个用户安装额外的包来扩展 @defterm{安装}层。@defterm{安装}层不仅旨在是只读的，而且在用户开始在自己的层中安装后不应更改。

在 Racket 本身正在开发的环境中，@defterm{安装}层会发生变化。在这种情况下，如果使用 @defterm{用户}层，则在修改安装层时必须注意不要为 @defterm{用户}层创建冲突——否则用户层有时必须被修复。

默认情况下，@exec{raco setup} 每次运行时都会更新两个层；如果用户没有安装的写权限，不带参数的 @exec{raco setup} 几乎肯定会报告权限错误。通过提供 @DFlag{avoid-main} 参数，可以将 @exec{raco setup} 的操作限制在 @defterm{用户}层，或者通过使用 @DFlag{no-user} 参数限制在 @defterm{安装}层。当 @exec{raco pkg} 执行 setup 操作时，它根据包的范围有效地提供其中之一（并且 @exec{raco pkg} 拒绝同时操作两个范围/层）。

@defterm{用户}层始终既是用户特定的又是版本特定的。更准确地说，它特定于用户和安装名称，其中安装名称通常是其版本号。但是，安装名称可以通过 @filepath{config.rktd} 中的 @racket['installation] 设置更改（参见 @secref["config-file"]）。设置安装名称会更改包和可执行文件在 @racket[(find-system-path 'addon-dir)] 中的驻留目录。@racket[(find-system-path 'addon-dir)] 本身的结果可以通过 @filepath{config.rktd} 中的 @racket['addon-dir] 更改。

@defterm{安装}和 @defterm{用户}配置层可以通过在 @filepath{config.rktd} 中设置搜索路径来推广为多个层。这些搜索路径基本上将最接近 @defterm{用户}的层视为可能由 @exec{raco setup} 和 @exec{raco pkg} 调整的 @defterm{安装}层，但搜索路径可以以与 @defterm{用户}链接到 @defterm{安装}大致相同的方式链接到现有的（不变的）实现。要构建新层，创建新的 @filepath{config.rktd}，类似于底层层的 @filepath{config.rktd}，但
@;
@itemlist[

 @item{@racket['lib-dir]、@racket['share-dir]、@racket['links-file]、@racket['pkgs-dir]、@racket['bin-dir]、@racket['gui-bin-dir]、@racket['apps-dir]、@racket['doc-dir] 和 @racket['man-dir] 中的每一个都是新目录或文件；}

 @item{相应的搜索列表 @racket['lib-search-dirs]、@racket['share-search-dirs]、@racket['links-search-files]、@racket['pkgs-search-dirs]、@racket['bin-search-dirs]、@racket['gui-bin-search-dirs]（不需要 @racket['apps-dir] 搜索）、@racket['doc-search-dirs] 和 @racket['man-search-dirs] 各自将旧的目录或文件添加到搜索列表中紧接 @racket[#f] 之后；请注意每个搜索列表的默认值是 @racket[(list #f)]。}

]
@;
@exec{raco setup} 没有类似于 @DFlag{avoid-main} 的参数来避免修改嵌套层；相反，嵌套层应被完全设置，以便 @exec{raco setup} 无需更改它们。当 @exec{raco setup} 本来会将可执行文件安装到配置为 @racket['bin-dir] 的目录时，它会查询 @racket['bin-search-dirs] 列表以检查该可执行文件是否已安装在其中一个目录中，如果是，则不会在新层中创建副本。相同的搜索列表检查也适用于原生库、共享文件和 man 页面，但还附加检查要安装的文件是否与已安装的匹配。

@filepath{config.rktd} 的默认路径硬编码在 @exec{racket} 可执行文件中。在某些情况下，最内层的配置指向另一层可能是合理的，可能是因为文件系统提供了一层间接引用。例如，在 Unix 上，@filepath{/usr} 中的 Racket 安装可以合理地将 @defterm{安装}层的目录配置为位于 @filepath{/usr/local}，并将 @filepath{/usr} 目录包含在搜索列表中。

要使用带有新 @filepath{config.rktd} 的 @exec{racket}，可以向 @exec{racket} 提供 @DFlag{config} 或 @DFlag{G} 标志，或将 @envvar{PLTCONFIGDIR} 环境变量设置为指向包含 @filepath{config.rktd} 的目录。或者，可以创建一个 @tech{绑定}层，该层创建类似于 @exec{racket} 的替换可执行文件，这些可执行文件硬编码到层的配置目录。

@; ------------------------------------------------------------------------

@section[#:tag "tethered-install"]{绑定安装}

Racket 的 @deftech{绑定}安装是一个层（参见 @secref["layered-install"]），它为安装各层中的每个可执行文件包含一个包装器可执行文件。每个包装器可执行文件指回新层的 @filepath{config.rktd}（参见 @secref["config-file"]），而不使用 @envvar{PLTCONFIGDIR} 环境变量或 @DFlag{config} 标志。换句话说，绑定安装提供了诸如 @exec{racket}、@exec{raco} 和 @exec{drracket} 等与该层绑定的可执行文件。因此，绑定有助于创建一个行为更加自包含的安装层，同时最小化底层层的重复。

绑定既可以在 @defterm{用户}层也可以在 @defterm{安装}层工作：

@itemlist[

 @item{带绑定的 @defterm{用户}层由一个新鲜目录 @nonterm{addon-dir} 和一个 @filepath{@nonterm{addon-dir}/etc/config.rktd} 文件表示，该文件将 @racket['addon-tethered-console-bin-dir] 映射到 @nonterm{tethered-bin-dir}，将 @racket['addon-tethered-gui-bin-dir] 映射到 @nonterm{tethered-gui-bin-dir}，并（可选）将 @racket['addon-tethered-apps-dir] 映射到 @nonterm{tethered-apps-dir}。使用以下命令初始化绑定层：

       @commandline{racket -A @nonterm{addon-dir} -l- raco setup --avoid-main}}

 @item{带绑定的 @defterm{安装}层类似于没有绑定的层（参见 @secref["layered-install"]），但该层的 @filepath{@nonterm{layer-dir}/etc/config.rktd} 文件将 @racket['config-tethered-console-bin-dir] 映射到 @nonterm{tethered-bin-dir}，将 @racket['config-tethered-gui-bin-dir] 映射到 @nonterm{tethered-gui-bin-dir}，并（可选）将 @racket['config-tethered-apps-dir] 映射到 @nonterm{tethered-apps-dir}。@racket['bin-dir] 和 @racket['gui-bin-dir] 配置可以指向相同的目录，但 @exec{raco setup} 不会专门在那里创建可执行文件。使用以下命令初始化绑定层：

       @commandline{racket -G @nonterm{layer-dir}/etc -l- raco setup}}

]

无论哪种情况，初始化都会在 @nonterm{tethered-bin-dir} 和 @nonterm{tethered-gui-bin-dir} 目录中创建绑定可执行文件，并在 @nonterm{tethered-apps-dir} 中（如果指定）写入 @filepath{.desktop} 文件（用于 Unix）。此后，可以使用绑定可执行文件（如 @exec{@nonterm{tethered-bin-dir}/racket} 和 @exec{@nonterm{tethered-bin-dir}/raco}）来操作绑定层。
