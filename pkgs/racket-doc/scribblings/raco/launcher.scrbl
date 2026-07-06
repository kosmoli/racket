#lang scribble/doc
@(require scribble/manual
          "common.rkt"
          (for-label racket/base racket/unit racket/contract
                     launcher/launcher
                     launcher/launcher-sig
                     launcher/launcher-unit
                     compiler/embed
                     racket/gui/base
                     setup/dirs))

@title[#:tag "launcher"]{特定于安装的启动器}

一个 @deftech{launcher} 类似于独立可执行文件，但 launcher 通常较小且创建更快，因为
它永远依赖于本地 Racket 安装以及程序的源文件。对于 Unix，launcher 就是一个运行
@exec{racket} 或 @exec{gracket} 的 shell 脚本。Launcher @emph{不能}通过
@exec{raco distribute} 打包到分发中。@exec{raco exe} 命令会在指定 @Flag{l}
或 @DFlag{launcher} 标志时创建一个 launcher。

@defmodule[launcher/launcher]

@racketmodname[launcher/launcher] 库提供了用于创建 @tech{launcher} 的函数。

@section{Creating Launchers}

@defproc[(make-gracket-launcher [args (listof string?)]
                                [dest path-string?]
                                [aux (listof (cons/c symbol? any/c)) null]
                                [#:tether-mode tether-mode (or/c 'addon 'config #f) 'addon])
         void?]{

创建 launcher @racket[dest]，它使用 @racket[args] 中作为字符串指定的命令行
参数启动 GRacket。在运行时传递给 launcher 的额外参数（减去特殊的 Unix/X 标志处理，
见下文描述）会被附加到此 list 中并传递给 GRacket。如果 @racket[dest] 已存在
（作为文件或目录），则会被替换。

可选的 @racket[aux] 参数是一个用于平台特定选项的 association list（即，
一个 pair 的 list，其中第一个元素是 key symbol，第二个元素是相应的值）。
另请参见 @racket[build-aux-from-path]。关于同时适用于 Windows 和 Mac OS
GRacket 上的独立可执行文件和 launcher 的 list，参见
@racket[create-embedding-executable]；以下内容是适用于 launcher 的
附加 association：

@itemize[

 @item{@racket['independent?] (Windows) --- boolean；@racket[#t]
       创建一个旧式 launcher，可与任何 Racket 或 GRacket 二进制文件
       一起使用，如 @exec{raco.exe}。对于旧式 launcher，不会使用
       其他 @racket[aux] association。}

 @item{@racket['exe-name] (Mac OS，@racket['script-3m]、
       @racket['script-cgc] 或 @racket['script-cs] 变体) --- 为
       @racket['3m]-/@racket['cgc]-/@racket['cs]-变体 launcher 提供基本名称，
       script 将忽略 @racket[args] 调用它。如果未提供此名称，
       script 将像往常一样通过 GRacket 可执行文件运行。}

 @item{@racket['exe-is-gracket]（当使用 @racket['exe-name] 时）---
       表明 @racket['exe-name] 指的是 GRacket 可执行文件，它可能在
       @filepath{lib} 子目录中，而不是在其他 GUI 应用程序中。}

 @item{@racket['relative?]（所有平台）--- boolean，其中
        @racket[#t] 表示生成的 launcher 应通过相对路径找到
        基础 GRacket 可执行文件。}

 @item{@racket['install-mode]（Windows、Unix）---
       @racket['main]、@racket['user]、@racket['config-tethered] 或
       @racket['addon-tethered]，表明 launcher 被安装到
       安装范围内、用户特定位置、嵌入配置路径的安装范围位置或
       嵌入 addon 目录路径的特定位置；安装模式又决定是否在何处
       记录 @racket['start-menu]、@racket['extension-registry]
       和/或 @racket['desktop] 信息。}

 @item{@racket['start-menu]（Windows）--- boolean 或实数；
       @racket[#t] 表示 launcher 应包含在安装程序的
       @onscreen{Start} 菜单中。数值被当作 @racket[#t] 处理，
       但还请求installer自动启动应用程序，其中数字确定相对于其他
       可能请求启动的 launcher 的优先级。
       @racket['start-menu] 值仅在同时指定了
       @racket['install-mode] 时使用。}

 @item{@racket['extension-register] (Windows) --- a list of document
       types for file-extension registrations to be performed by an
       installer. Each document type is described by a list of six
       items:

         @itemlist[

            @item{a human-readable string describing the document
                  type, such as @racket["Racket Document"];}

            @item{a string to use as a key for the document type,
                  such as @racket["Racket.Document"];}

            @item{a list of strings, where each string is a file
                  extension without the dot, such as @racket['("rkt"
                  "rktl" "rktd")];}

            @item{a path to a file that supplies the icon, such as
                  @racket["doc.ico"];}

            @item{a string to represent the command line to handle a
                  document with a matching extension, such as
                  @racket["\"%1\""], where the string will be prefixed
                  with a path to the launcher, and where @litchar{%1}
                  will be replaced with the document path}
          ]

       An @racket['extension-registry] value is used only when
       @racket['install-mode] is also specified.}

 @item{@racket['desktop]（Unix）--- 一个字符串，包含 launcher 的
       @filepath{.desktop} 文件的内容，其中 @tt{Exec} 和 @tt{Icon}
       条目会被自动添加。如果字符串中存在 @tt{Exec} 条目，并且其值以
       一个非空的字母数字 ASCII 字符序列后跟一个空格开头，则该空格和
       值的剩余部分会被附加到自动生成的值上。
       @filepath{.desktop} 文件会写入由 @racket[(find-apps-dir)]
       或 @racket[(find-user-apps-dir)] 产生的目录中。
       @racket['desktop] 值仅在同时指定了 @racket['install-mode] 时使用。}

  @item{@racket['png]（Unix）：图标文件路径（后缀
        @filepath{.png}），供 @filepath{.desktop} 文件（如果有）
        引用；@racket['png] 值优先于 @racket['ico] 值，
        但除非同时存在 @racket['desktop] 值，否则两者都不会被使用。}

  @item{@racket['ico]（Unix，此外也供更通用的 Windows 使用）
        ：图标文件路径（后缀 @filepath{.ico}），在没有
        @racket['png] 值时以与 @racket['png] 相同的方式使用。}

]

对于 Unix/X，@racket[make-mred-launcher] 创建的 script 会检测并特别处理
X Windows 标志，前提是它们作为 script 的初始参数出现。这些参数不会被附加到
@racket[args] 的末尾，而是拼接在 @racket[args] 中已列出的任何 X Windows
标志之后。剩余的参数（即最后一个 X Windows 标志或参数之后的所有
script 标志和参数）然后再被附加到拼接后的 @racket[args] 之后。

@racket[tether-mode] 参数指示了基于 @racket[(find-addon-tether-console-bin-dir)]
和 @racket[(find-config-tether-console-bin-dir)] 保留当前安装对一个配置目录和/或
addon 目录的绑定程度。@racket['addon] 模式允许完全绑定，
@racket['config] 模式仅允许配置目录绑定，@racket[#f] 模式则禁用绑定。

@history[#:changed "6.5.0.2" @elem{添加了 @racket[#:tether-mode] 参数。}]}


@defproc[(make-racket-launcher [args (listof string?)]
                               [dest path-string?]
                               [aux (listof (cons/c symbol? any/c)) null])
         void?]{

类似于 @racket[make-gracket-launcher]，但用于启动 Racket。
在 Mac OS 上，@racket['exe-name] @racket[aux] association 会被忽略。}


@defproc[(make-gracket-program-launcher [file string?]
                                        [collection string?]
                                        [dest path-string?])
         void?]{

调用 @racket[make-gracket-launcher]，使用在 @racket[collection]
中启动 @racket[file] 实现的 GRacket 程序的参数：
@racket[(list "-l-" (string-append collection "/" file))]。
传递给 @racket[make-gracket-launcher] 的 @racket[_aux] 参数是
通过从 @racket[file] 中剥离后缀（如果有），添加到 @racket[collection]
的路径，然后将结果传递给 @racket[build-aux-from-path] 生成的。}


@defproc[(make-racket-program-launcher [file string?]
                                       [collection string?]
                                       [dest path-string?])
        void?]{

类似于 @racket[make-gracket-program-launcher]，但用于
@racket[make-racket-launcher]。}


@defproc[(install-gracket-program-launcher [file string?]
                                          [collection string?]
                                          [name string?])
         void?]{

等同于

@racketblock[
(make-gracket-program-launcher 
 file collection
 (gracket-program-launcher-path name))
]}

@defproc[(install-racket-program-launcher [file string?]
                                          [collection string?]
                                          [name string?])
         void?]{

等同于

@racketblock[
(make-racket-program-launcher 
 file collection
 (racket-program-launcher-path name))
]}


@deftogether[(
@defproc[(make-mred-launcher [args (listof string?)]
                             [dest path-string?]
                             [aux (listof (cons/c symbol? any/c)) null])
         void?]
@defproc[(make-mred-program-launcher [file string?]
                                     [collection string?]
                                     [dest path-string?])
         void?]
@defproc[(install-mred-program-launcher [file string?]
                                        [collection string?]
                                        [name string?])
         void?]
)]{

@racket[make-gracket-launcher] 等的向后兼容版本，会在命令行参数开头
添加 @racket["-I" "scheme/gui/init"]。}

@deftogether[(
@defproc[(make-mzscheme-launcher [args (listof string?)]
                                 [dest path-string?]
                                 [aux (listof (cons/c symbol? any/c)) null])
         void?]
@defproc[(make-mzscheme-program-launcher [file string?]
                                         [collection string?]
                                         [dest path-string?])
        void?]
@defproc[(install-mzscheme-program-launcher [file string?]
                                            [collection string?]
                                            [name string?])
         void?]
)]{

@racket[make-racket-launcher] 等的向后兼容版本，会在命令行参数开头
添加 @racket["-I" "scheme/init"]。}

@; ----------------------------------------------------------------------

@section{Launcher Path and Platform Conventions}

@defproc[(gracket-program-launcher-path [name string?]
                                        [#:user? user? any/c #f]
                                        [#:tethered? tethered? any/c #f]
                                        [#:console? console? any/c #f])
         path?]{

返回一个可执行文件的路径名，其名称类似于 @racket[name]，
位于

@itemlist[

 @item{Racket 安装中 --- 当 @racket[user?] 是 @racket[#f]
       且 @racket[tethered?] 是 @racket[#f]；}

 @item{用户的 Racket 可执行文件目录 --- 当 @racket[user?]
       是 @racket[#t] 且 @racket[tethered?] 是 @racket[#f]；}

 @item{绑定到特定配置目录的可执行文件的附加可执行文件目录
       --- 当 @racket[user?] 是 @racket[#f]
       且 @racket[tethered?] 是 @racket[#t]；或者}

 @item{绑定到特定 addon 和配置目录的可执行文件的附加可执行文件目录
       --- 当 @racket[user?] 是 @racket[#t]
       且 @racket[tethered?] 是 @racket[#t]。}

]

对于 Windows，@filepath{.exe} 后缀会自动附加到 @racket[name]。
对于 Unix，@racket[name] 会改为小写，空白会更改为
@litchar{-}，路径包含 Racket 安装的 @filepath{bin} 子目录。
对于 Mac OS，@filepath{.app} 后缀会被附加到 @racket[name]。

如果 @racket[console?] 为 true，则路径在 console 可执行文件目录
中，如 @racket[(find-console-bin-dir)] 所报告的那样，而不是 GUI
可执行文件目录，如 @racket[(find-gui-bin-dir)] 所报告的那样。

@history[#:changed "6.5.0.2" @elem{Added the @racket[#:tethered?] argument.}
         #:changed "6.8.0.2"  @elem{Added the @racket[#:console?] argument.}]}


@defproc[(racket-program-launcher-path [name string?]
                                       [#:user? user? any/c #f]
                                       [#:tethered? tethered? any/c #f]
                                        [#:console? console? any/c #f])
         path?]{

返回与 @racket[(gracket-program-launcher-path name #:user? user? #:tethered tethered? #:console? console?)] 相同的路径。

@history[#:changed "6.5.0.2" @elem{Added the @racket[#:tethered?] argument.}
         #:changed "6.8.0.2"  @elem{Added the @racket[#:console?] argument.}]}


@defproc[(gracket-launcher-is-directory?) boolean?]{

如果从用户的角度来看当前平台的 GRacket launcher 是目录，
则返回 @racket[#t]。对于所有当前支持的平台，结果都是 @racket[#f]。}


@defproc[(racket-launcher-is-directory?) boolean?]{

类似于 @racket[gracket-launcher-is-directory?]，但用于 Racket
launcher。}


@defproc[(gracket-launcher-is-actually-directory?) boolean?]{

如果从文件系统角度来看当前平台的 GRacket launcher
实现为目录，则返回 @racket[#t]。结果为 @racket[#t]
表示是 Mac OS，@racket[#f] 表示是其他平台。}


@defproc[(racket-launcher-is-actually-directory?) boolean?]{

类似于 @racket[gracket-launcher-is-actually-directory?]，但用于 Racket
launcher。结果对所有平台都是 @racket[#f]。}


@defproc[(gracket-launcher-add-suffix [path-string? path]) path?]{

返回添加了合适可执行文件后缀的路径（如果尚未存在）。}

@defproc[(racket-launcher-add-suffix [path-string? path]) path?]{

类似于 @racket[gracket-launcher-add-suffix]，但用于 Racket launcher。}


@defproc[(gracket-launcher-put-file-extension+style+filters)
         (values (or/c string? #f)
                 (listof (or/c 'packages 'enter-packages))
                 (listof (list/c string? string?)))]{

返回三个值，分别适合用作 @racket[put-file] 的 @racket[extension]、
@racket[style] 和 @racket[filters] 参数。

如果当前平台的 GRacket launcher 从用户的角度来看是目录，那么
@racket[style] 结果适合与 @racket[get-directory] 一起使用，
而 @racket[extension] 结果可能是一个字符串，指示目录名所需
的扩展名。}


@defproc[(racket-launcher-put-file-extension+style+filters)
         (values (or/c string? #f)
                 (listof (or/c 'packages 'enter-packages))
                 (listof (list/c string? string?)))]{

类似于 @racket[gracket-launcher-put-file-extension+style+filters]，但用于
Racket launcher。}

@deftogether[(
@defproc[(mred-program-launcher-path [name string?] [#:user? user? any/c #f] [#:tethered? tethered? any/c #f]) path?]
@defproc[(mred-launcher-is-directory?) boolean?]
@defproc[(mred-launcher-is-actually-directory?) boolean?]
@defproc[(mred-launcher-add-suffix [path-string? path]) path?]
@defproc[(mred-launcher-put-file-extension+style+filters)
         (values (or/c string? #f)
                 (listof (or/c 'packages 'enter-packages))
                 (listof (list/c string? string?)))]
)]{

@racket[gracket-program-launcher-path] 等的向后兼容别名。

@history[#:changed "6.5.0.2" @elem{Added the @racket[#:tethered?] argument.}]}

@deftogether[(
@defproc[(mzscheme-program-launcher-path [name string?] [#:user? user? any/c #f] [#:tethered? tethered? any/c #f]) path?]
@defproc[(mzscheme-launcher-is-directory?) boolean?]
@defproc[(mzscheme-launcher-is-actually-directory?) boolean?]
@defproc[(mzscheme-launcher-add-suffix [path-string? path]) path?]
@defproc[(mzscheme-launcher-put-file-extension+style+filters)
         (values (or/c string? #f)
                 (listof (or/c 'packages 'enter-packages))
                 (listof (list/c string? string?)))]
)]{

@racket[racket-program-launcher-path] 等的向后兼容别名。

@history[#:changed "6.5.0.2" @elem{Added the @racket[#:tethered?] argument.}]}


@defproc[(installed-executable-path->desktop-path [exec-path path-string?] [user? any/c] [tethered? any/c])
         (or/c (and/c path? complete-path?) #f)]{

返回一个 @filepath{.desktop} 文件的路径，用于描述安装在 @racket[exec-path]
的可执行文件。只使用 @racket[exec-path] 的文件名部分。如果 @racket[exec-path]
安装在用户特定位置，@racket[user?] 参数应为 true（在这种情况下，
返回的路径也将是用户特定的）。对于 @tech{tethered} 安装，
@racket[tethered?] 参数应为 true。只有当 @racket[tethered?] 为 true
且 @racket[find-addon-tethered-apps-dir]（当 @racket[user?] 为 true 时）
或 @racket[find-config-tethered-apps-dir]（当 @racket[user?] 为 @racket[#f] 时）
返回 @racket[#f] 时，结果才可能为 @racket[#f]。

@history[#:changed "8.3.0.11" @elem{Added the @racket[tethered?] argument.}]}


@defproc[(installed-desktop-path->icon-path [desktop-path path-string?]
                                            [user? any/c]
                                            [suffix bytes?])
         (and/c path? complete-path?)]{

返回一个图标文件的路径，供 @racket[desktop-path] 处的 @filepath{desktop}
文件引用。只使用 @racket[desktop-path] 的文件名部分。如果 @racket[desktop-path]
安装在用户特定位置，@racket[user?] 参数应为 true（在这种情况下，
返回的路径也将是用户特定的）。@racket[suffix] 参数提供图标文件后缀，
通常为 @racket[#"png"] 或 @racket[#"ico"]。}

@; ----------------------------------------------------------------------

@section{Launcher Configuration}

@defproc[(gracket-launcher-up-to-date? [dest path-string?]
                                    [aux (listof (cons/c symbol? any/c))])
         boolean?]{

假设 @racket[dest] 是一个 launcher 且其参数未更改，
如果 @racket[dest] 处的 GRacket launcher 不需要更新，
则返回 @racket[#t]。}

@defproc[(racket-launcher-up-to-date? [dest path-string?]
                                        [aux (listof (cons/c symbol? any/c))])
         boolean?]{

类似于 @racket[gracket-launcher-up-to-date?]，但用于 Racket launcher。}

@defproc[(build-aux-from-path [path path-string?])
         (listof (cons/c symbol? any/c))]{

创建一个适合与 @racket[make-gracket-launcher] 或
@racket[create-embedding-executable] 一起使用的 association list。
它通过向 @racket[path] 添加后缀（如 @filepath{.icns}），
检查此类文件是否存在，如果存在则调用 @racket[extract-aux-from-path]
来构建 association。所有已识别后缀的结果会被附加在一起。}


@defproc[(extract-aux-from-path [path path-string?])
         (listof (cons/c symbol? any/c))]{

创建一个适合与 @racket[make-gracket-launcher] 或
@racket[create-embedding-executable] 一起使用的 association list。
它通过识别 @racket[path] 的后缀来构建 association，
已识别的后缀如下：

@itemize[

 @item{@filepath{.icns} @'rarr @racket['icns] file for use on Mac
       OS}

 @item{@filepath{.ico} @'rarr @racket['ico] file for use on
       Windows or Unix}

 @item{@filepath{.png} @'rarr @racket['png] file for use on
       Unix}

 @item{@filepath{.lch} @'rarr @racket['independent?] as @racket[#t]
       (the file content is ignored) for use on Windows}

 @item{@filepath{.creator} @'rarr @racket['creator] as the initial
       four characters in the file for use on Mac OS}

 @item{@filepath{.filetypes} @'rarr @racket['file-types] as
       @racket[read] content (a single S-expression), and
       @racket['resource-files] as a list constructed by finding
       @racket["CFBundleTypeIconFile"] entries in @racket['file-types]
       (and filtering duplicates); for use on Mac OS}

 @item{@filepath{.utiexports} @'rarr @racket['uti-exports] as
       @racket[read] content (a single S-expression); for use on
       Mac OS}

 @item{@filepath{.wmclass} @'rarr @racket['wm-class] as the literal
       content, removing a trailing newline if any; for use on Unix}

 @item{@filepath{.desktop} @'rarr @racket['desktop] as the literal
       content; for use on Unix}

 @item{@filepath{.startmenu} @'rarr @racket['start-menu] as the file
       content if it @racket[read]s as a real number, @racket[#t]
       otherwise, for use on Windows}

 @item{@filepath{.extreg} @'rarr @racket['extension-register] as
       @racket[read] content (a single S-expression), but with
       relative (to the @filepath{.extreg} file) paths converted
       to absolute paths; for use on Windows}

]}

@defparam[current-launcher-variant variant symbol?]{

一个参数，指示用于 launcher 创建和生成 launcher 名称的 Racket 或 GRacket
的变体。默认值是 @racket[(system-type 'gc)] 的结果。在 Unix 和 Windows
上，可以使用的值有 @racket['cgc]、@racket['3m] 和 @racket['cs]。
在 Mac OS 上，@racket['script-cgc]、@racket['script-3m] 和
@racket['script-cs] 变体也可用于 GRacket launcher。}

@defproc[(available-gracket-variants) (listof symbol?)]{

返回一个 symbol 的 list，对应于当前 Racket 安装中可用的 GRacket 变体。
该 list 通常至少包含 @racket['3m]、@racket['cgc] 或 @racket['cs] 中的一个
（即 @racket[(system-type 'gc)] 的结果），也可能包含其他项，
在 Mac OS 上还有 @racket['script-3m]、@racket['script-cgc]
和/或 @racket['script-cs]。}

@defproc[(available-racket-variants) (listof symbol?)]{

返回一个 symbol 的 list，对应于当前 Racket 安装中可用的 Racket 变体。
该 list 通常至少包含 @racket['3m]、@racket['cgc] 或 @racket['cs] 中的一个
（即 @racket[(system-type 'gc)] 的结果），也可能包含其他项。}

@deftogether[(
@defproc[(mred-launcher-up-to-date? [dest path-string?]
                                    [aux (listof (cons/c symbol? any/c))])
         boolean?]
@defproc[(mzscheme-launcher-up-to-date? [dest path-string?]
                                        [aux (listof (cons/c symbol? any/c))])
         boolean?]
@defproc[(available-mred-variants) (listof symbol?)]
@defproc[(available-mzscheme-variants) (listof symbol?)]
)]{
@racket[gracket-launcher-up-to-date?] 等的向后兼容别名。}


@; ----------------------------------------

@section{Launcher Creation Signature}

@defmodule[launcher/launcher-sig]

@defsignature/splice[launcher^ ()]{

包含 @racketmodname[launcher/launcher] 提供的 identifier。}

@; ----------------------------------------

@section{Launcher Creation Unit}

@defmodule[launcher/launcher-unit]

@defthing[launcher@ unit?]{

不导入任何内容，只导出 @racket[launcher^] 的 unit。}
