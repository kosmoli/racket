#lang scribble/doc

@(require scribble/manual
          scribble/bnf
          "common.rkt"
          (for-label racket/gui
                     compiler/compiler
                     compiler/sig
                     compiler/compiler-unit
                     compiler/option-unit
                     compiler/distribute
                     compiler/bundle-dist
                     compiler/embed
                     compiler/embed-sig
                     compiler/embed-unit
                     racket/runtime-path
                     launcher/launcher
                     compiler/find-exe
                     setup/dirs))

@title{API 用于创建可执行文件}

@defmodule[compiler/embed]{

@racketmodname[compiler/embed] 库提供一个函数，用于将 Racket 代码嵌入到 Racket 或 GRacket 的副本中，从而创建一个独立的 Racket 可执行文件。要将可执行文件打包成独立于您 Racket 安装的发布版，请使用 @racketmodname[compiler/distribute] 中的 @racket[assemble-distribution]。}

嵌入操作会遍历模块依赖图，找到某些初始顶级模块所需的所有模块，必要时对其进行编译，并将它们组合成一个“模块包”。除了模块代码外，包还扩展了模块名称解析器，使得模块可以用其原始名称被 @racket[require] 调用，而且将从包而非文件系统中获取这些模块。

@racket[create-embedding-executable] 函数将包与可执行文件（Racket 或 GRacket）组合在一起。而 @racket[write-module-bundle] 函数将包输出到当前输出端口；只要 @racket[read-accept-compiled] 参数为 true，这个流就可以直接被运行中的程序 @racket[load] 加载。

@defproc[(create-embedding-executable [dest path-string?]
                               [#:modules mod-list 
                                         (listof (or/c (list/c (or/c symbol? #f #t)
                                                               (or/c module-path? path?))
                                                       (list/c (or/c symbol? #f #t)
                                                               (or/c module-path? path?)
                                                               (listof symbol?))))]
                               [#:early-literal-expressions early-literal-sexps
                                                            list?
                                                            null]
                               [#:configure-via-first-module? config-via-first? 
                                                              any/c 
                                                              #f]
                               [#:literal-files literal-files
                                                (listof path-string?)
                                                null]
                               [#:literal-expression literal-sexp
                                                     any/c
                                                     #f]
                               [#:literal-expressions literal-sexps
                                                      list?
                                                      (if literal-sexp
                                                          (list literal-sexp)
                                                          null)]
                               [#:cmdline cmdline (listof string?)
                                                  null]
                               [#:gracket? gracket? any/c #f]
                               [#:mred? mred? any/c #f]
                               [#:variant variant (or/c 'cgc '3m 'cs)
                                                  (system-type 'gc)]
                               [#:aux aux (listof (cons/c symbol? any/c)) null]
                               [#:collects-path collects-path
                                                (or/c #f
                                                      path-string? 
                                                      (listof path-string?))
                                                #f]
                               [#:collects-dest collects-dest
                                                (or/c #f path-string?)
                                                #f]
                               [#:launcher? launcher? any/c #f]
                               [#:verbose? verbose? any/c #f]
                               [#:expand-namespace expand-namespace namespace? (current-namespace)]
                               [#:compiler compile-proc (any/c . -> . compiled-expression?) 
                                           (lambda (e)
                                             (parameterize ([current-namespace 
                                                             expand-namespace])
                                               (compile e)))]
                               [#:src-filter src-filter (path? . -> . any) (lambda (p) #t)]
                               [#:on-extension ext-proc
                                               (or/c #f (path-string? boolean? . -> . any))
                                               #f]
                               [#:get-extra-imports extras-proc 
                                                    (path? compiled-module-expression? 
                                                     . -> . (listof module-path?))
                                                    (lambda (p m) null)])
         void?]{

复制 Racket（如果 @racket[gracket?] 和 @racket[mred?] 均为 @racket[#f]）或 GRacket（否则）二进制文件，将代码嵌入复制的可执行文件中以在启动时加载。在 Unix 上，二进制文件实际是一个包装可执行文件，它会 @tt{exec} 原始文件；参见 @racket[aux] 的 @racket['original-exe?] 标签。

嵌入式可执行文件将写入 @racket[dest]，如果它已经存在（作为文件或目录）则会被覆盖。

嵌入的代码由模块声明和额外的（任意的）代码组成。当一个模块被嵌入时，它导入的所有模块也会被嵌入。库模块被嵌入后，在初始名称空间中可通过其 @racket[lib] 路径访问。

@racket[#:modules] 参数 @racket[mod-list] 指定要嵌入的模块（如下所述）。@racket[#:early-literal-expressions]、@racket[#:literal-files] 和 @racket[#:literal-expressions] 参数指定要复制到可执行文件中的字面代码：@racket[early-literal-sexps] 的每个元素按顺序复制，接着是 @racket[literal-files] 中每个文件的内容（不带间隔空格），最后是 @racket[literal-sexps] 的每个元素。@racket[literal-files] 文件或 @racket[early-literal-sexps] 或 @racket[literal-sexps] 列表可包含编译后的字节码，并且 @racket[literal-files] 文件的内容可能只有在连接成字符串时才能解析；这些文件和表达式在嵌入过程中不会被编译或检查。请注意，初始名称空间中不包含任何绑定，请使用编译后的表达式来引导名称空间。
The @racket[#:literal-expression]
(singular) argument is for backward compatibility.

如果 @racket[#:configure-via-first-module?] 参数指定为 true，那么 @racket[mod-list] 中第一个模块的语言專用于在计算 @racket[#:literal-files] 和 @racket[#:literal-expressions] 添加的表达式之前配置运行时环境，但在计算 @racket[#:early-literal-expressions] 之后。参见 @secref[#:doc '(lib "scribblings/reference/reference.scrbl") "configure-runtime"]。

@racket[#:cmdline] 参数 @racket[cmdline] 包含命令行字符串，它们会被添加到传递给嵌入式可执行文件的任何实际命令行参数之前。计算表达式或加载文件的命令行参数将在嵌入代码加载完毕后执行。

@racket[#:modules] 参数 @racket[mod-list] 的每个元素是一个包含两或三个项的列表，其中第一项是模块名称的前缀，第二项是模块路径数据（格式为默认模块名称解析器能理解的），第三项是可用是师包含的子模块名称列表。前缀可以是 symbol、@racket[#f]（表示无前缀）或 @racket[#t]（表示自动生成前缀）。例如：

@racketblock['((#f "m.rkt"))]

embeds the module @racket[m] from the file @filepath{m.rkt}, without
prefixing the name of the module; the @racket[literal-sexpr] argument
to go with the above might be @racket['(require m)]. When submodules
are available and included, the submodule is given a name by
symbol-appending the @racket[write] form of the submodule path to the
enclosing module's name.

当一个嵌入的模块未在 @racket[#:modules] 参数中列出或在那里未给定前缀时，系统会自动为嵌入的模块生成一个符号名称。这些名称以确定但未指定的方式生成，因此无法方便地访问。生成的名称可能依赖于 @racket[mod-list] 第一个元素的路径。通过基于 collection 的路径包含的模块在运行时仍可通过其基于 collection 的路径访问（通过为嵌入式可执行文件安装的模块名称解析器）。

模块通常在嵌入目标可执行文件之前被编译；参见下面的 @racket[#:compiler] 和 @racket[#:src-filter]。当一个模块通过 @racket[define-runtime-path] 声明运行时路径时，生成的可执行文件会记录该路径（以供立即执行和创建包含该可执行文件的发布版使用）。

如果 @racket[collects-dest] 是一个路径而非 @racket[#f]，那么不将基于 collection 的模块嵌入可执行文件，而是将这些模块（仅编译形式）复制到 @racket[collects-dest] 目录的 collection 中。

可选的 @racket[#:aux] 参数是一个用于平台特定选项的关联列表（即它是一个组对列表，每个组对的第一个元素是键 symbol，第二个元素是对应的值）。参见 @racket[build-aux-from-path]。当前支持的键如下：

@itemize[

  @item{@racket['icns] (Mac OS) ：用于可执行文件桌面图标的图标文件路径（后缀 @filepath{.icns}）。}

  @item{@racket['ico] (Windows) ：用于可执行文件桌面图标的图标文件路径（后缀 @filepath{.ico}）。

        @history[#:changed "6.3" @elem{All icons in the
        executable are replaced with icons from the file,
        instead of setting only certain sizes and depths.}]}

  @item{@racket['creator] (Mac OS) ：提供一个 4 字符字符串作为应用签名。}

  @item{@racket['file-types] (Mac OS) ：提供一个关联列表的列表，应用处理的每种文件类型对应一个关联列表；每个关联是一个两元素列表，第一个（键）元素是 Finder 识别的字符串，第二个元素是 plist 值（参见 @racketmodname[xml/plist]）。参见 @filepath{drracket} collection 中的 @filepath{drracket.filetypes} 获取示例。}

  @item{@racket['uti-exports] (Mac OS) ：提供一个关联列表的列表，可执行文件导出的每个 @as-index{Uniform Type Identifier} (UTI) 对应一个关联列表；每个关联是一个两元素列表，第一个（键）元素是 UTI 声明中识别的字符串，第二个元素是 plist 值（参见 @racketmodname[xml/plist]）。参见 @filepath{drracket} collection 中的 @filepath{drracket.utiexports} 获取示例。}

  @item{@racket['resource-files] (Mac OS) ：要复制到生成的可执行文件的 @filepath{Resources} 目录的额外文件。}

  @item{@racket['config-dir] ：包含配置信息的目录的字符串/路径，例如 @filepath{config.rtkd}（参见 @secref["config-file"]）。如果未提供值，路径保留原样，并在需要时转换为绝对形式。如果提供 @racket[#f]，路径保留原样（可能是相对形式）。请注意，如果 @racket[collects-path] 作为空列表提供，配置目录路径将不被 Racket 的启动过程使用（与普通 Racket 启动相反，后者会查询配置目录以获取 collection 链接文件的信息）。}

  @item{@racket['framework-root] (Mac OS) : A string to prefix the
        executable's path to the Racket and GRacket frameworks
        (including a separating slash); note that when the prefix
        start @filepath{@"@"executable_path/} works for a
        Racket-based application, the corresponding prefix start for
        a GRacket-based application is
        @filepath{@"@"executable_path/../../../}; if @racket[#f] is
        supplied, the executable's framework path is left as-is,
        otherwise the original executable's path to a framework is
        converted to an absolute path if it was relative.}

  @item{@racket['dll-dir] (Windows) ：包含可执行文件所需 Racket DLL 的目录的字符串/路径，例如 @filepath{racket@nonterm{version}.dll}，或一个布尔值；路径可以是相对于可执行文件的；如果提供 @racket[#f]，路径保留原样；如果提供 @racket[#t]，路径会被丢弃（因此 DLL 必须在系统目录或用户的 @envvar{PATH} 中）；如果未提供值，原始可执行文件到 DLL 的路径如果是相对的则会被转换为绝对路径。}

  @item{@racket['embed-dlls?] (Windows) ：一个布尔值，指示是否将 DLL 复制到可执行文件中，默认值为 @racket[#f]。嵌入式 DLL 通过内部链接步骤实例化，该步骤绕过了一些操作系统功能，因步对了所有 Windows DLL 都不起作用，但典型的 DLL 作为嵌入式是可用的。}

  @item{@racket['subsystem] (Windows) ：一个 symbol，@racket['console] 表示控制台应用，@racket['windows] 表示无控制台应用；对于基于 Racket 的应用默认为 @racket['console]，对于基于 GRacket 的应用默认为 @racket['windows]；参见下面的 @racket['single-instance?]。}

  @item{@racket['single-instance?] (Windows) ：用于基于 GRacket 的应用的布尔值；默认为 @racket[#t]，表示应用在启动时查找自身的其他实例并仅将其带到前台；@racket[#f] 表示预期多个实例。}

  @item{@racket['forget-exe?] (Unix, Windows, Mac OS) ：一个布尔值；对于 launcher（参见下面的 @racket[launcher?]），@racket[#t] 表示不保留 @racket[(find-system-path 'exec-file)] 的原始可执行文件名称；一个后果是库 collection 将相对于 launcher 而非原始可执行文件被找到。}

  @item{@racket['original-exe?] (Unix) ：一个布尔值；@racket[#t] 表示嵌入使用原始的 Racket 或 GRacket 可执行文件，而不是 @tt{exec} 原始文件的包装二进制文件；默认为 @racket[#f]。}

  @item{@racket['relative?] (Unix, Windows, Mac OS) ：一个布尔值；@racket[#t] 表示在生成的可执行文件必须引用另一个可执行文件的范围内，可以使用相对路径（因此可执行文件可以一起移动，但不能单独移动），并且意味着 @racket['config-dir]、@racket['framework-dir] 和 @racket['dll-dir] 都被视为 @racket[#f]，除非这些选项被显式提供；@racket[#f] 值（默认）意味着应使用绝对路径（以便生成的可执行文件可以移动）。}

  @item{@racket['wm-class] (Unix) ：一个字符串；用作程序窗口的默认 @tt{WM_CLASS} 程序类。}

]

如果 @racket[#:collects-path] 参数为 @racket[#f]，那么创建的可执行文件会保留其内置的（相对的）到主要 @filepath{collects} 目录的路径——当可执行文件运行时，这会是 @racket[(find-system-path 'collects-dir)] 的结果——加上一个用于查找库 collection 的其他目录的列表——这些目录与 @envvar{PLTCOLLECTS} 环境变量组合使用，用于初始化 @racket[current-library-collection-paths] 列表。否则，该参数指定一个替代值；它必须是一个路径、字符串或路径和字符串的列表。在最后一种情况下，第一个路径或字符串指定主要的 collection 目录，其余的是 collection 搜索路径的附加目录（按顺序放置在用户特定的 @filepath{collects} 目录之后，但在主要的 @filepath{collects} 目录之前；然后搜索列表与 @envvar{PLTCOLLECTS} 组合，如果后者已定义）。如果列表为空，那么 @racket[(find-system-path 'collects-dir)] 将返回可执行文件的目录，但 @racket[current-library-collection-paths] 会被初始化为空列表，并且 @racket[use-collection-link-paths] 会被设置为 false 以禁用 @tech[#:doc reference-doc]{collection links files}。

如果 @racket[#:launcher?] 参数为 @racket[#t]，那么 @racket[mod-list] 应为 null，@racket[literal-files] 应为 null，@racket[literal-sexp] 应为 @racket[#f]。嵌入式可执行文件会以这样的方式创建：@racket[(find-system-path 'exec-file)] 产生源 Racket 或 GRacket 的路径而不是嵌入式可执行文件的路径（但 @racket[(find-system-path 'run-file)] 的结果仍然是嵌入式可执行文件），除非 @racket[aux] 中 @racket['forget-exe?] 关联了一个真值。

@racket[#:variant] 参数指示使用原始二进制文件的哪个变体进行嵌入。默认为 @racket[(system-type 'gc)]；参见 @racket[current-launcher-variant]。

@racket[#:compiler] 参数用于编译要包含在可执行文件中的模块的源码（当编译形式尚未可用时）。它应接受一个单一参数，即一个 @racket[module] 形式的 syntax object。默认过程使用 @racket[compile]，并通过参数化将当前名称空间设置为 @racket[expand-namespace]。

@racket[#:expand-namespace] 参数选择一个名称空间用于扩展额外模块（以及使用默认 @racket[compile-proc] 进行编译）。需要对额外模块进行扩展以检测包含的模块中的运行时路径声明，以便将路径解析引向当前位置（并最终重方向到发布版中的副本）。

@racket[#:src-filter] 参数 @racket[src-filter] 接受一个路径并返回 true，如果对应的文件源应以源形式（而非编译形式）包含在嵌入式可执行文件中，否则返回 @racket[#f]。默认对所有路径都返回 @racket[#f]。请注意，在调用过滤器过程时，当前输出端口可能会被重方向到结果可执行文件。传递给 @racket[src-filter] 的每个路径对应于实际文件名（例如，已按需应用 @filepath{.ss}/@filepath{.rkt} 转换以引用现有文件）。

如果 @racket[#:on-extension] 参数是一个过程，那么当遍历模块依赖关系到达一个扩展（即 DLL 或共享对象）时，就会调用该过程。默认值 @racket[#f] 会导致将单模块扩展的引用（在其当前位置）嵌入到可执行文件中。该过程会被传入两个参数：扩展的路径和一个 @racket[#f]（出于历史原因）。
  
@racket[#:get-extra-imports] 参数 @racket[extras-proc] 接受每个要包含在可执行文件中的模块的源路径名称和编译后的模块。它返回一个引用模块路径的列表（绝对路径，而非相对于模块），表示除源模块 @racket[require] 的模块外还要包含的额外模块。例如，这些模块可能对应于解析将作为源包含的模块所需的 reader 扩展，只要通过绝对模块路径引用 reader 即可。传递给 @racket[extras-proc] 的每个路径对应于实际文件名（例如，已按需应用 @filepath{.ss}/@filepath{.rkt} 转换以引用现有文件）。

@history[#:changed "6.90.0.23" @elem{Added @racket[embed-dlls?] as an
                                     @racket[#:aux] key.}
         #:changed "7.3.0.6" @elem{Changed generation of symbolic names for embedded
                                   modules to make it deterministic.}]}


@defproc[(make-embedding-executable [dest path-string?]
                               [mred? any/c]
                               [verbose? any/c]
                               [mod-list (listof (or/c (list/c (or/c symbol? #f #t)
                                                               (or/c module-path? path?))
                                                       (list/c (or/c symbol? #f #t)
                                                               (or/c module-path? path?)
                                                               (listof symbol?))))]
                               [literal-files (listof path-string?)]
                               [literal-sexp any/c]
                               [cmdline (listof string?)]
                               [aux (listof (cons/c symbol? any/c)) null]
                               [launcher? any/c #f]
                               [variant (or/c 'cgc '3m 'cs) (system-type 'gc)]
                               [collects-path (or/c #f
                                                    path-string? 
                                                    (listof path-string?))
                                              #f])
         void?]{

@racket[create-embedding-executable] 的旧版（无关键字）接口。}


@defproc[(write-module-bundle [verbose? any/c]
                               [mod-list (listof (or/c (list/c (or/c symbol? #f #t)
                                                               (or/c module-path? path?))
                                                       (list/c (or/c symbol? #f #t)
                                                               (or/c module-path? path?)
                                                               (listof symbol?))))]
                              [literal-files (listof path-string?)]
                              [literal-sexp any/c])
         void?]{

类似于 @racket[make-embedding-executable]，但模块包被写入当前输出端口而非嵌入到可执行文件中。该函数的输出可以通过 @racket[read] 加载并实例化 @racket[mod-list] 及其依赖项，调整模块名称解析器以找到新加载的模块，计算从 @racket[literal-files] 包含的表单，最终计算 @racket[literal-sexpr]。@racket[read-accept-compiled] 参数必须为 true 才能读取该流。}


@defproc[(embedding-executable-is-directory? [mred? any/c]) boolean]{

指示当前平台的 Racket/GRacket 可执行文件是否从用户视角看是目录。结果当前对所有平台均为 @racket[#f]。}


@defproc[(embedding-executable-is-actually-directory? [mred? any/c])
         boolean?]{

指示当前平台的 Racket/GRacket 可执行文件是否实际上是目录。当 @racket[mred?] 为 @racket[#t] 时，在 Mac OS 上结果为 @racket[#t]，否则为 @racket[#f]。}


@defproc[(embedding-executable-put-file-extension+style+filters [mred? any/c])
         (values (or/c string? #f)
                 (listof (or/c 'packages 'enter-packages))
                 (listof (list/c string? string?)))]{

返回三个值，分别适用于作为 @racket[put-file] 的 @racket[extension]、@racket[style] 和 @racket[filters] 参数。

如果当前平台的 Racket/GRacket 启动器从用户视角看是目录，那么 @racket[style] 结果适用于 @racket[get-directory]，而 @racket[extension] 结果可能是一个指示目录名称所需后缀的字符串。}


@defproc[(embedding-executable-add-suffix [path path-string?] [mred? any/c])
         path-string?]{

如果尚未包含适当的可执行文件后缀，则添加之。

@history[#:changed "8.1.0.7" @elem{Changed to actually add a suffix, instead of
                                   replacing an existing suffix.}]}


@; ----------------------------------------

@section{可执行文件创建签名}

@defmodule[compiler/embed-sig]

@defsignature/splice[compiler:embed^ ()]{

包含 @racketmodname[compiler/embed] 提供的标识符。}

@; ----------------------------------------

@section{可执行文件创建单元}

@defmodule[compiler/embed-unit]

@defthing[compiler:embed@ unit?]{

一个不导入任何内容、导出 @racket[compiler:embed^] 的单元。}

@section{查找 Racket 可执行文件}

@defmodule[compiler/find-exe]

@defproc[(find-exe [#:cross? cross? any/c #f]
                   [#:untethered? untethered? any/c #f]
                   [gracket? any/c #f]
                   [variant (or/c 'cgc '3m 'cs) (if cross?
                                                    (cross-system-type 'gc)
                                                    (system-type 'gc))])
         path?]{

  查找 @exec{racket} 或 @exec{gracket}（当 @racket[gracket?] 为 true 时）可执行文件的路径。

  如果 @racket[cross?] 为 true，则在 @seclink["cross-system"]{cross-installation mode} 中为目标平台查找可执行文件。

  如果 @racket[untethered?] 为 true，则查找原始可执行文件，而非通过 @racket[(find-addon-tethered-console-bin-dir)] 及相关函数绑定到配置或 addon 目录的可执行文件。

  @history[#:changed "6.3" @elem{Added the @racket[#:cross?] argument.}
           #:changed "6.2.0.5" @elem{Added the @racket[#:untethered?] argument.}]}
