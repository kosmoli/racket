#lang scribble/doc
@(require "mz.rkt"
          scribble/core
          (for-label framework/preferences
                     racket/runtime-path
                     launcher/launcher
                     setup/dirs
                     setup/cross-system))

@(define file-eval (make-base-eval))
@examples[#:hidden #:eval file-eval
          (require racket/file)
          (define filename (make-temporary-file))]


@title{文件系统}

@;------------------------------------------------------------------------
@section[#:tag "findpaths"]{定位路径}

@defproc[(find-system-path [kind symbol?]) path?]{

返回由 @racket[kind] 指定的标准类型路径的机器特定路径，
@racket[kind] 必须是以下之一：

@itemize[

 @item{@indexed-racket['home-dir] --- 当前 @deftech{用户主目录}。

 在所有平台上，如果 @indexed-envvar{PLTUSERHOME} 环境变量被定义为 @tech{完整} 路径，
 则该路径被用作用户主目录。

 在 Unix 和 Mac OS 上，当 @envvar{PLTUSERHOME} 不适用时，
 用户主目录通过展开路径 @filepath{~} 来确定，
 展开时首先检查 @indexed-envvar{HOME} 环境变量。如果未定义，
 则按顺序查询 @indexed-envvar{USER} 和 @indexed-envvar{LOGNAME} 环境变量以找到用户名，
 然后查询系统文件以定位用户主目录。

 在 Windows 上，当 @envvar{PLTUSERHOME} 不适用时，
 用户主目录是由 Windows 注册表确定的用户特定配置文件目录。
 如果注册表由于某种原因无法提供目录，则使用 @indexed-envvar{USERPROFILE} 环境变量的值，
 只要它引用存在的目录。如果 @envvar{USERPROFILE} 也失败，
 则目录由 @indexed-envvar{HOMEDRIVE} 和 @indexed-envvar{HOMEPATH} 环境变量指定。
 如果这些环境变量未定义，或者指示的目录仍不存在，
 则使用包含当前可执行文件的目录作为主目录。}

 @item{@indexed-racket['pref-dir] --- 用于存储当前用户偏好的标准目录。
 偏好目录可能不存在。

 在 Unix 上，偏好目录通常是指定路径的 @filepath{racket} 子目录，
 该路径由 @indexed-envvar{XDG_CONFIG_HOME} 指定，或者如果 @envvar{XDG_CONFIG_HOME}
 未设置为绝对路径或设置了 @envvar{PLTUSERHOME}，则为 @tech{用户主目录} 中的
 @filepath{.config/racket}。无论哪种方式，如果该目录不存在但 @tech{用户主目录} 中存在
 @filepath{.racket} 目录，则该目录是偏好目录。

 在 Windows 上，如果由 @envvar{PLTUSERHOME} 确定，则偏好目录是 @tech{用户主目录} 中的
 @filepath{Racket}，否则是 Windows 注册表指定的用户应用程序数据文件夹；
 应用程序数据文件夹通常是用户配置文件目录中的 @filepath{Application Data}。

 在 Mac OS 上，偏好目录是 @tech{用户主目录} 中的 @filepath{Library/Preferences}。}

 @item{@indexed-racket['pref-file] --- 包含以符号为键的偏好值关联列表的文件。
 文件的目录路径始终与为 @racket['pref-dir] 返回的结果匹配。
 在 Unix 和 Windows 上，文件名为 @filepath{racket-prefs.rktd}，
 在 Mac OS 上为 @filepath{org.racket-lang.prefs.rktd}。
 文件的目录可能不存在。另参见 @racket[get-preference]。}

 @item{@indexed-racket['temp-dir] --- 用于存储临时文件的标准目录。
 在 @|AllUnix| 上，这是由 @indexed-envvar{TMPDIR} 环境变量指定的目录（如果已定义），
 否则是 @filepath{/var/tmp}、@filepath{/usr/tmp} 和 @filepath{/tmp} 中第一个存在的路径。
 在 Windows 上，结果是由 @indexed-envvar{TMP} 或 @indexed-envvar{TEMP} 环境变量指定的目录
 （如果已定义），否则是当前目录。}

 @item{@indexed-racket['init-dir] --- 包含 Racket 可执行文件使用的初始化文件的目录。

 在 Unix 上，初始化目录与为 @racket['pref-dir] 返回的结果相同——
 除非该目录不存在且 @tech{用户主目录} 中存在 @filepath{.racketrc} 文件，
 在这种情况下主目录是初始化目录。

 在 Windows 上，初始化目录与 @tech{用户主目录} 相同。

 在 Mac OS 上，初始化目录是 @tech{用户主目录} 中的 @filepath{Library/Racket}——
 除非那里不存在 @filepath{racketrc.rktl} 且主目录中确实存在 @filepath{.racketrc} 文件，
 在这种情况下主目录是初始化目录。}

 @item{@indexed-racket['init-file] --- Racket 可执行文件在启动时加载的文件。
 路径的目录部分与为 @racket['init-dir] 返回的路径相同。

 在 Windows 上，名称的文件部分是 @indexed-file{racketrc.rktl}。

 在 Unix 和 Mac OS 上，名称的文件部分是 @indexed-file{racketrc.rktl}——
 除非为 @racket['init-dir] 返回的路径是 @tech{用户主目录}，
 在这种情况下名称的文件部分是 @indexed-file{.racketrc}。}

 @item{@indexed-racket['config-dir] --- 安装配置的目录。
 此目录由 @indexed-envvar{PLTCONFIGDIR} 环境变量指定，
 可以通过 @DFlag{config} 或 @Flag{G} 命令行标志覆盖。
 如果未指定环境变量或标志，或者值不是合法的路径名，
 则此目录默认为相对于当前可执行文件的 @filepath{etc} 目录。
 如果 @racket[(find-system-path 'config-dir)] 的结果是相对路径，
 则它相对于当前可执行文件。
 该目录可能不存在。}

 @item{@indexed-racket['host-config-dir] --- 类似于
 @racket['config-dir]，但在选择跨平台构建模式时
 （通过 @exec{racket} 的 @Flag{C} 或 @DFlag{cross} 参数；参见 @secref["mz-cmdline"]），
 结果引用当前系统安装的目录，而不是目标系统的目录。}
 
 @item{@indexed-racket['addon-dir] --- 用于用户特定 Racket 配置、包和扩展的目录。
 此目录由 @indexed-envvar{PLTADDONDIR} 环境变量指定，
 可以通过 @DFlag{addon} 或 @Flag{A} 命令行标志覆盖。
 如果未指定环境变量或标志，或者值不是合法的路径名，
 则此目录默认为平台特定的位置。该目录可能不存在。

 在 Unix 上，默认值通常是指定路径的 @filepath{racket} 子目录，
 该路径由 @indexed-envvar{XDG_DATA_HOME} 指定，或者如果 @envvar{XDG_CONFIG_HOME}
 未设置为绝对路径或设置了 @envvar{PLTUSERHOME}，则为 @tech{用户主目录} 中的
 @filepath{.local/share/racket}。如果该目录不存在但用户主目录中存在 @filepath{.racket} 目录，
 则 @filepath{.racket} 目录路径是默认值。

 在 Windows 上，默认值与 @racket['pref-dir] 目录相同。

 在 Mac OS 上，默认值是 @tech{用户主目录} 中的 @filepath{Library/Racket}。}

 @item{@indexed-racket['host-addon-dir] --- 类似于
 @racket['addon-dir]，但在选择跨平台构建模式时
 （通过 @exec{racket} 的 @Flag{C} 或 @DFlag{cross} 参数；参见 @secref["mz-cmdline"]），
 结果引用当前系统安装的目录，而不是目标系统的目录。

 @history[#:added "8.17.0.2"]}

 @item{@indexed-racket['cache-dir] --- 用于存储用户特定缓存的目录。
 该目录可能不存在。

 在 Unix 上，缓存目录通常是指定路径的 @filepath{racket} 子目录，
 该路径由 @indexed-envvar{XDG_CACHE_HOME} 指定，或者如果 @envvar{XDG_CACHE_HOME}
 未设置为绝对路径或设置了 @envvar{PLTUSERHOME}，则为 @tech{用户主目录} 中的
 @filepath{.cache/racket}。如果该目录不存在但主目录中存在 @filepath{.racket} 目录，
 则 @filepath{.racket} 目录是缓存目录。

 在 Windows 上，缓存目录与为 @racket['addon-dir] 返回的结果相同。

 在 Mac OS 上，缓存目录是 @tech{用户主目录} 中的 @filepath{Library/Caches/Racket}。}

 @item{@indexed-racket['doc-dir] --- 用于存储当前用户文档的标准目录。
 在 Unix 上，它是 @tech{用户主目录}。在 Windows 上，如果由 @envvar{PLTUSERHOME} 确定，
 则它是 @tech{用户主目录}，否则是 Windows 注册表指定的用户文档文件夹；
 文档文件夹通常是用户主目录中的 @filepath{My Documents}。
 在 Mac OS 上，它是 @tech{用户主目录} 中的 @filepath{Documents} 目录。}

 @item{@indexed-racket['desk-dir] --- 当前用户桌面的目录。
 在 Unix 上，它是 @tech{用户主目录}。在 Windows 上，如果由 @envvar{PLTUSERHOME} 确定，
 则它是 @tech{用户主目录}，否则是 Windows 注册表指定的用户桌面文件夹；
 桌面文件夹通常是用户主目录中的 @filepath{Desktop}。在 Mac OS 上，
 它是 @tech{用户主目录} 中的 @filepath{Desktop}。}

 @item{@indexed-racket['sys-dir] --- 包含 Windows 操作系统的目录。
 在 @|AllUnix| 上，结果是 @racket["/"]。}

 @item{@indexed-racket['exec-file] --- 操作系统为当前调用提供的 Racket 可执行文件路径。
 对于某些操作系统，路径可以是相对的。

 @margin-note{对于 GRacket，可执行文件路径是 GRacket 可执行文件的名称。}}

 @item{@indexed-racket['run-file] --- 当前可执行文件的路径；
  这可能与 @racket['exec-file] 的结果不同，因为通过 @DFlag{name} 或 @Flag{N}
  命令行标志向 Racket（或 GRacket）可执行文件提供了备用路径，
  或者因为嵌入的可执行文件安装了备用路径。特别是由 @racket[make-racket-launcher]
  创建的``启动器''脚本将此路径设置为脚本的路径。}

 @item{@indexed-racket['collects-dir] --- 主库集合的路径（参见 @secref["collects"]）。
 如果此路径是相对的，则它相对于 @racket[(find-system-path 'exec-file)] 报告的可执行文件——
 尽管后者可能是软链接或相对于用户的可执行文件搜索路径，
 因此两个结果应与 @racket[find-executable-path] 结合使用。
 @racket['collects-dir] 路径通常嵌入在 Racket 可执行文件中，
 但可以通过 @DFlag{collects} 或 @Flag{X} 命令行标志覆盖。}

 @item{@indexed-racket['host-collects-dir] --- 类似于
 @racket['collects-dir]，但在选择跨平台构建模式时
 （通过 @exec{racket} 的 @Flag{C} 或 @DFlag{cross} 参数；参见 @secref["mz-cmdline"]），
 结果引用当前系统安装的目录，而不是目标系统的目录。
 在跨平台构建模式下，集合文件通常从目标系统的安装中读取，
 但某些任务需要相对于主库集合路径配置的当前系统目录
 （例如保存外部库的目录）。}
 
 @item{@indexed-racket['orig-dir] --- 启动时的当前目录，
 在将 @racket[(find-system-path 'exec-file)] 或
 @racket[(find-system-path 'run-file)] 的相对路径结果转换为完整路径时有用。}

 ]

@history[#:changed "6.0.0.3" @elem{添加了 @envvar{PLTUSERHOME}。}
         #:changed "6.9.0.1" @elem{添加了 @racket['host-config-dir]
                                   和 @racket['host-collects-dir]。}
         #:changed "7.8.0.9" @elem{添加了 @racket['cache-dir]，并更改
                                   为在 Unix 上优先使用 XDG 目录，
                                   以前的路径作为回退，
                                   并对 Mac OS 进行类似调整。}]}

@defproc[(path-list-string->path-list [str (or/c string? bytes?)]
                                      [default-path-list (listof (or/c path? 'same))])
         (listof (or/c path? 'same))]{

解析包含路径列表的字符串或字节字符串，并返回路径列表。
在 @|AllUnix| 上，路径列表字符串中的路径由 @litchar{:} 分隔；
在 Windows 上，路径由 @litchar{;} 分隔，并且字符串中的所有 @litchar{"} 被丢弃。
每当路径列表包含空路径时，列表 @racket[default-path-list] 被拼接到返回的路径列表中。
@racket[str] 中不形成有效路径的部分不包含在返回的列表中。
给定的 @racket[str] 不得包含 nul 字符或 nul 字节。

@history[#:changed "8.0.0.10" @elem{更改为允许 @racket[default-path-list] 中使用 @racket['same]。}]}


@defproc[(find-executable-path [program path-string?]
                               [related (or/c path-string? #f) #f]
                               [deepest? any/c #f]) 
         (or/c path? #f)]{

查找可执行文件 @racket[program] 的路径，如果找不到路径则返回 @racket[#f]。

在 Windows 上，如果未找到 @racket[program] 且它没有文件扩展名，
则搜索重新开始，将 @filepath{.exe} 添加到 @racket[program]，
仅当带有 @filepath{.exe} 的路径也找不到时结果才为 @racket[#f]。
如果仅找到带扩展名的 @racket[program]，则结果包含扩展名 @filepath{.exe}。

如果 @racket[related] 不是 @racket[#f]，则它必须是相对路径字符串，
并且为 @racket[program] 找到的路径必须使得文件或目录 @racket[related]
存在于与可执行文件相同的目录中。然后结果是找到的 @racket[related] 的完整路径，
而不是可执行文件的路径。
 
此过程由 Racket 可执行文件用于查找标准库集合目录（参见 @secref["collects"]）。
在这种情况下，@racket[program] 是用于启动 Racket 的名称，
@racket[related] 是 @racket["collects"]。使用 @racket[related] 参数是因为，
在 @|AllUnix| 上，@racket[program] 可能涉及一系列软链接；
在这种情况下，@racket[related] 确定链中哪个链接是相关的。

如果 @racket[related] 不是 @racket[#f]，则当 @racket[find-executable-path]
未找到是另一个文件路径链接的 @racket[program] 时，
搜索可以继续沿着链接的目标进行。进一步检查链接，直到找到 @racket[related]
或到达链接链的末尾。如果 @racket[deepest?] 是 @racket[#f]（默认值），
则结果对应于找到 @racket[related] 的链接链中的第一个路径
（实际上不探索进一步的链接）；否则，结果对应于找到 @racket[related] 的链中的最后一个链接。

如果 @racket[program] 是无路径的名称，
@racket[find-executable-path] 获取 @indexed-envvar{PATH} 环境变量的值；
如果此环境变量已定义，@racket[find-executable-path] 尝试 @envvar{PATH} 中的每个路径
作为 @racket[program] 的前缀，使用上述用于包含路径的 @racket[program] 的搜索算法。
如果 @envvar{PATH} 环境变量未定义，@racket[program] 将与当前目录前缀
并用于上述搜索算法。（在 Windows 上，当前目录始终是 @envvar{PATH} 中的第一个隐式项，
因此 @racket[find-executable-path] 在 Windows 上首先检查当前目录。）

@history[#:changed "8.1.0.7" @elem{在 Windows 上添加了使用 @filepath{.exe} 的搜索。}]}

@;------------------------------------------------------------------------
@section[#:tag "fileutils"]{文件}

@defproc[(file-exists? [path path-string?]) boolean?]{

如果文件（不是目录）@racket[path] 存在则返回 @racket[#t]，
否则返回 @racket[#f]。

在 Windows 上，@racket[file-exists?] 对所有特殊文件名变体报告 @racket[#t]
（例如 @racket["LPT1"]、@racket["x:/baddir/LPT1"]）。}


@defproc[(link-exists? [path path-string?]) boolean?]{

如果链接 @racket[path] 存在则返回 @racket[#t]，
否则返回 @racket[#f]。

谓词 @racket[file-exists?] 或 @racket[directory-exists?]
在链接或一系列链接的最终目标上工作，而 @racket[link-exists?]
仅跟随链接以解析 @racket[path] 的基本部分（即路径中除最后一个名称外的所有内容）。

此过程从不引发 @racket[exn:fail:filesystem] 异常。

在 Windows 上，@racket[link-exists?] 对符号链接和结点都报告 @racket[#t]。

@history[#:changed "6.0.1.12" @elem{在 Windows 上添加了对链接的支持。}]}


@defproc[(file-or-directory-type [path path-string?] [must-exist? any/c #f])
         (or/c 'file 'directory 'link 'directory-link #f)]{

报告 @racket[path] 是指文件、目录、链接还是目录链接（在 Windows 的情况下；
另参见 @racket[make-file-or-directory-link]），假设 @racket[path] 可以被访问。

如果 @racket[path] 无法被访问，当 @racket[must-exist?] 为 @racket[#f] 时结果为 @racket[#f]，
否则 @exnraise[exn:fail:filesystem]。

@history[#:added "7.8.0.5"]}


@defproc[(delete-file [path path-string?]) void?]{

删除路径为 @racket[path] 的文件（如果存在），否则 @exnraise[exn:fail:filesystem]。
如果 @racket[path] 是链接，则删除链接而不是链接的目标。

在 Windows 上，如果初始删除文件的尝试因权限错误而失败，
且 @racket[current-force-delete-permissions] 的值为真，
则 @racket[delete-file] 尝试更改文件的权限（以允许写入）然后删除文件；
权限更改后跟删除是非原子序列，如果删除失败则不尝试恢复权限更改。

在 Windows 上，@racket[delete-file] 可以删除符号链接，但不能删除结点。
使用 @racket[delete-directory] 删除结点。

在 Windows 上，请注意，如果文件在仍被某个进程使用时（例如，后台搜索索引器）被删除，
则文件的内容最终会消失，但文件的名称仍被占用，直到文件不再被使用。
只要名称仍被占用，尝试打开、删除或替换文件将触发权限错误（而不是文件存在错误）。
避免此陷阱的常见技巧是在删除文件之前将其移动到生成的临时名称。
另参见 @racket[delete-directory/files]。

@history[#:changed "6.1.1.7" @elem{更改 Windows 行为以使用
                                   @racket[current-force-delete-permissions]。}]}


@defproc[(rename-file-or-directory [old path-string?]
                                   [new path-string?]
                                   [exists-ok? any/c #f]) 
         void?]{

将路径为 @racket[old] 的文件或目录（如果存在）重命名为路径 @racket[new]。
如果文件或目录未成功重命名，则 @exnraise[exn:fail:filesystem]。

此过程可用于将文件/目录移动到不同的目录（在同一文件系统上），
以及在目录内重命名文件/目录。除非 @racket[exists-ok?] 作为真值提供，
@racket[new] 不能引用现有的文件或目录，但在 Unix 和 Mac OS 上，
检查与重命名操作不是原子的。即使 @racket[exists-ok?] 为真，
当 @racket[old] 是目录时，@racket[new] 不能引用现有文件，反之亦然。

如果 @racket[new] 存在并被替换，在 Unix 和 Mac OS 上替换是原子的，
但在 Windows 上不保证是原子的。此外，如果 @racket[new] 存在并被任何进程打开进行读取或写入，
则尝试替换它通常在 Windows 上会失败。另参见 @racket[call-with-atomic-output-file]。

如果 @racket[old] 是链接，则重命名链接而不是链接的目标，
并且对于替换任何现有 @racket[new] 都算作文件。

在 Windows 上，请注意，如果目录中有任何文件处于打开状态，则目录无法重命名。
如果搜索索引器在后台运行（如在默认 Windows 配置中），此约束特别成问题。
可能的解决方法是组合 @racket[copy-directory/files] 和 @racket[delete-directory/files]，
因为后者可以处理打开的文件，尽管该序列显然不是原子的并且会临时复制文件。}


@defproc*[([(file-or-directory-modify-seconds [path path-string?]
                                              [secs-n #f #f])
            exact-integer?]
           [(file-or-directory-modify-seconds [path path-string?]
                                              [secs-n exact-integer?])
            void?]
           [(file-or-directory-modify-seconds [path path-string?]
                                              [secs-n (or/c exact-integer? #f) #f]
                                              [fail-thunk (-> any) (lambda () (raise (make-exn:fail:filesystem ....)))])
            any])]{

@index['("file modification date and time")]{返回}
文件或目录的最后修改日期，以 @tech{纪元} 以来的秒数表示
（另参见 @secref["time"]），当 @racket[secs-n] 未提供或为 @racket[#f] 时。

对于 Windows 上的 FAT 文件系统，目录没有修改日期。
因此，为目录返回创建日期，为文件返回修改日期。

如果提供了 @racket[secs-n] 且不为 @racket[#f]，则将 @racket[path] 的访问和修改时间设置为给定时间。

出错时（例如，如果文件不存在），则调用 @racket[fail-thunk]（通过尾部调用）
以产生 @racket[file-or-directory-modify-seconds] 调用的结果。
如果未提供 @racket[fail-thunk]，则引发 @racket[exn:fail:filesystem] 错误。}


@defproc*[([(file-or-directory-permissions [path path-string?] [mode #f #f]) (listof (or/c 'read 'write 'execute))]
           [(file-or-directory-permissions [path path-string?] [mode 'bits]) (integer-in 0 #xFFFF)]
           [(file-or-directory-permissions [path path-string?] [mode (integer-in 0 #xFFFF)]) void])]{

@index["chmod"]{当}给定一个参数或 @racket[#f] 作为第二个参数时，
返回包含 @indexed-racket['read]、@indexed-racket['write] 和/或 @indexed-racket['execute]
的列表，以指示当前用户和组对给定文件或目录路径的权限。
在 @|AllUnix| 上，检查的是当前有效用户而不是实际用户的权限。

如果提供 @racket['bits] 作为第二个参数，则结果是文件或目录属性
（主要是权限）的平台特定整数编码，结果独立于当前用户和组。
编码的最低九位是可移植的，反映文件或目录所有者、
文件目录组成员或其他用户的权限：

@itemlist[
 @item{@racketvalfont{#o400} : 所有者具有读权限}
 @item{@racketvalfont{#o200} : 所有者具有写权限}
 @item{@racketvalfont{#o100} : 所有者具有执行权限}
 @item{@racketvalfont{#o040} : 组具有读权限}
 @item{@racketvalfont{#o020} : 组具有写权限}
 @item{@racketvalfont{#o010} : 组具有执行权限}
 @item{@racketvalfont{#o004} : 其他用户具有读权限}
 @item{@racketvalfont{#o002} : 其他用户具有写权限}
 @item{@racketvalfont{#o001} : 其他用户具有执行权限}
]

另参见 @racket[user-read-bit] 等。在 Windows 上，所有三种（所有者、组和其他）的权限始终相同，
读取和执行权限始终可用。在 @|AllUnix| 上，高位具有平台特定的含义。

如果提供整数作为第二个参数，则将其用作属性（主要是权限）的编码以安装给文件。

在所有模式下，出错时（例如，如果文件不存在）@exnraise[exn:fail:filesystem]。}


@defproc[(file-or-directory-stat [path path-string?]
                                 [as-link? boolean? #f])
         (and/c (hash/c symbol? any/c) hash-eq?)]{

@index['("inode")]{返回}一个具有以下键和值的哈希表，
其中每个值当前都是非负精确整数：

@itemlist[
 @item{@indexed-racket['device-id] : 设备 ID}
 @item{@indexed-racket['inode] : inode 号}
 @item{@indexed-racket['mode] : 模式位（见下文）}
 @item{@indexed-racket['hardlink-count] : 硬链接数}
 @item{@indexed-racket['user-id] : 所有者的数字用户 ID}
 @item{@indexed-racket['group-id] : 所有者的数字组 ID}
 @item{@indexed-racket['device-id-for-special-file] : 设备 ID（如果是特殊文件）}
 @item{@indexed-racket['size] : 文件或符号链接的大小（字节）}
 @item{@indexed-racket['block-size] : 文件系统块大小}
 @item{@indexed-racket['block-count] : 已用文件系统块数}
 @item{@indexed-racket['access-time-seconds] : 最后访问时间（秒，自 @tech{纪元} 以来）}
 @item{@indexed-racket['modify-time-seconds] : 最后修改时间（秒，自 @tech{纪元} 以来）}
 @item{@indexed-racket['change-time-seconds] : 最后状态更改时间（秒，自 @tech{纪元} 以来）}
 @item{@indexed-racket['creation-time-seconds] : 创建时间（秒，自 @tech{纪元} 以来）}
 @item{@indexed-racket['access-time-nanoseconds] : 最后访问时间（纳秒，自 @tech{纪元} 以来）}
 @item{@indexed-racket['modify-time-nanoseconds] : 最后修改时间（纳秒，自 @tech{纪元} 以来）}
 @item{@indexed-racket['change-time-nanoseconds] : 最后状态更改时间（纳秒，自 @tech{纪元} 以来）}
 @item{@indexed-racket['creation-time-nanoseconds] : 创建时间（纳秒，自 @tech{纪元} 以来）}
]

如果 @racket[as-link?] 为真值，则当 @racket[path] 引用符号链接时，
返回链接的 stat 信息而不是引用的文件系统项的 stat 信息。

模式位是用于权限和其他数据的位，
分别来自 Posix @tt{stat}/@tt{lstat} 函数或 Windows @tt{_wstat64} 函数。
要选择位模式的部分，请使用常量 @indexed-racket[user-read-bit] 等。

根据操作系统和文件系统，``纳秒''时间戳可能具有小于纳秒的精度。
例如，在一个环境中时间戳可能是 @racket[1234567891234567891]（纳秒精度），
在另一个环境中可能是 @racket[1234567891000000000]（秒精度）。

对于平台/文件系统组合不可用的值可能设置为 @racket[0]。
例如，这适用于 Windows 上的 @racket['user-id] 和 @racket['group-id] 键。
此外，Posix 平台提供状态更改时间戳，但不提供创建时间戳；
对于 Windows 则相反。

如果 @racket[as-link?] 是 @racket[#f] 且 @racket[path] 不可访问，
则 @exnraise[exn:fail:filesystem]。如果 @racket[as-link?] 为真值且 @racket[path]
无法解析（即悬空链接），也会引发此异常。

@history[#:added "8.3.0.7"]}


@defproc[(file-or-directory-identity [path path-string?]
                                     [as-link? any/c #f])
         exact-positive-integer?]{

@index['("inode")]{返回}一个数字，表示 @racket[path] 在设备和它访问的文件或目录方面的身份。
此函数可用于检查两个路径在路径的实体选择不改变的假设下是否对应于同一文件系统实体。

如果 @racket[as-link?] 为真值，则当 @racket[path] 引用文件系统链接时，
返回链接的身份而不是引用的文件或目录（如果有）的身份。}


@defproc[(file-size [path path-string?]) exact-nonnegative-integer?]{

返回指定文件的（逻辑）大小（字节）。在 Mac OS 上，
此大小不包括资源分支大小。出错时（例如，如果文件不存在），
@exnraise[exn:fail:filesystem]。}


@defproc[(copy-file [src path-string?] 
                    [dest path-string?]
                    [exists-ok?/pos any/c #f]
                    [#:exists-ok? exists-ok? any/c exists-ok?/pos]
                    [#:permissions permissions (or/c #f (integer-in 0 65535)) #f]
                    [#:replace-permissions? replace-permissions? any/c #t])
         void?]{

创建文件 @racket[dest] 作为 @racket[src] 的副本，如果 @racket[dest] 不存在。
如果 @racket[dest] 已存在且 @racket[exists-ok?] 为 @racket[#f]，
则复制失败并 @exnraise[exn:fail:filesystem:exists?]；否则，如果 @racket[dest] 存在，
其内容将被 @racket[src] 的内容替换。

如果 @racket[src] 引用链接，则复制链接的目标而不是链接本身。
如果 @racket[dest] 引用链接且 @racket[exists-ok?] 为真，则更新链接的目标。

文件权限从 @racket[src] 传输到 @racket[dest]，
除非在 Unix 和 Mac OS 上 @racket[permissions] 作为非 @racket[#f] 提供，
在这种情况下 @racket[permissions] 用于 @racket[dest]。
请注意，权限在默认情况下传输时不考虑进程的 umask 设置，
但见下文 @racket[replace-permissions?]。在 Windows 上，
@racket[src] 的修改时间也传输到 @racket[dest]；
如果 @racket[permissions] 作为非 @racket[#f] 提供，则复制后，
@racket[dest] 根据 @racket[permissions] 中是否存在 @racketvalfont{#o2} 位设置为只读或非只读。

@racket[replace-permissions?] 参数仅在 Unix 和 Mac OS 上使用。
当创建 @racket[dest] 时，使用 @racket[permissions] 或 @racket[src] 的权限创建；
但是，进程的 umask 可能会清除请求权限中的位。
当 @racket[dest] 已存在（且 @racket[exists-ok?] 为真）时，
@racket[dest] 的权限最初保持不变。最后，
当 @racket[replace-permissions?] 为真值时，
@racket[dest] 的权限在文件内容复制到 @racket[permissions] 或 @racket[src] 的权限后设置，
不受 umask 修改。

@racket[exists-ok?/pos] 位置参数用于向后兼容。
可以提供该位置参数，也可以提供 @racket[exists-ok?] 关键字参数，
但如果两者都提供，则 @exnraise[exn:fail:contract]。

@history[#:changed "8.7.0.9" @elem{添加了 @racket[#:exists-ok?]、
                                   @racket[#:permissions] 和
                                   @racket[#:replace-permissions?]
                                   参数。}]}


@defproc[(make-file-or-directory-link [to path-string?] [path path-string?]) 
         void?]{

创建指向 @racket[to] 的链接 @racket[path]。
如果 @racket[path] 已存在，创建将失败。@racket[to] 不必引用现有文件或目录，
并且在写入链接之前 @racket[to] 不会被展开。如果链接未成功创建，
则 @exnraise[exn:fail:filesystem]。

在 Windows XP 及更早版本上，@exnraise[exn:fail:unsupported]。
在 Windows 的较新版本上，链接的创建通常被安全策略禁止。
Windows 区分文件和目录链接，仅当 @racket[to] 在语法上解析为目录时才创建目录链接（参见
@racket[path->directory-path]）。此外，相对路径链接被操作系统特殊解析；
参见 @secref["windowspaths"] 了解更多信息。当 @racket[make-file-or-directory-link]
成功时，它创建的是符号链接而不是结点或硬链接。
请注意，目录链接必须使用 @racket[delete-directory] 而不是 @racket[delete-file] 删除。

@history[#:changed "6.0.1.12" @elem{在 Windows 上添加了对链接的支持。}]}


@defboolparam[current-force-delete-permissions force? #:value #t]{

一个 @tech{parameter}，确定在 Windows 上 @racket[delete-file] 和 @racket[delete-directory]
是否尝试更改文件或目录的权限以删除它。默认值为 @racket[#t]。}

@;------------------------------------------------------------------------
@section[#:tag "directories"]{目录}

另参见：@racket[rename-file-or-directory]、
@racket[file-or-directory-modify-seconds]、
@racket[file-or-directory-permissions]。

@defparam*[current-directory path path-string? (and/c path? complete-path?)]{

一个 @tech{parameter}，确定用于解析相对路径的当前目录。

当调用参数过程设置当前目录时，
路径参数使用 @racket[cleanse-path] 进行 @tech{清理}，
使用 @racket[simplify-path] 进行简化，然后使用 @racket[path->directory-path] 转换为目录路径；
如果路径格式错误，清理和简化会引发异常。因此，
@racket[current-directory] 的当前值始终是清理过的、简化的、完整的目录路径。

设置参数时不检查路径是否存在。

在 Unix 和 Mac OS 上，Racket 进程的参数初始值取自 @indexed-envvar{PWD} 环境变量——
如果环境变量的值标识的目录与操作系统报告的当前目录相同。}

@defparam*[current-directory-for-user path path-string? (and/c path? complete-path?)]{

类似于 @racket[current-directory]，但仅由 @racket[srcloc->string] 用于报告相对于目录的路径。

通常，@racket[current-directory-for-user] 应保持其初始值，
反映用户启动进程的目录。然而，诸如 DrRacket 之类的工具会隐式地让用户选择目录
（针对正在编辑的文件），在这种情况下更新 @racket[current-directory-for-user] 是合理的。}


@defproc[(current-drive) path?]{

返回 Windows 的当前驱动器名称。对于其他平台，
@exnraise[exn:fail:unsupported]。当前驱动器始终是当前目录的驱动器。}


@defproc[(directory-exists? [path path-string?]) boolean?]{

如果 @racket[path] 引用目录则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(make-directory [path path-string?]
                         [permissions (integer-in 0 65535) @#,racketvalfont{#o777}])
         void?]{

创建路径为 @racket[path] 的新目录。如果目录未成功创建，
则 @exnraise[exn:fail:filesystem]。

@racket[permissions] 参数指定所创建目录的权限，
其中整数权限表示与 @racket[file-or-directory-permissions] 中的处理方式相同。
在 Unix 和 Mac OS 上，这些权限位与进程的 umask 组合。
在 Windows 上，不使用 @racket[permissions]。

@history[#:changed "8.3.0.5" @elem{添加了 @racket[permissions] 参数。}]}


@defproc[(delete-directory [path path-string?]) void?]{

删除路径为 @racket[path] 的现有目录。如果目录未成功删除，
则 @exnraise[exn:fail:filesystem]。

在 Windows 上，如果初始删除目录的尝试因权限错误而失败，
且 @racket[current-force-delete-permissions] 的值为真，
则 @racket[delete-file] 尝试更改目录的权限（以允许写入）然后删除目录；
权限更改后跟删除是非原子序列，如果删除失败则不尝试恢复权限更改。

@history[#:changed "6.1.1.7" @elem{更改 Windows 行为以使用
                                   @racket[current-force-delete-permissions]。}]}


@defproc[(directory-list [path path-string? (current-directory)]
                         [#:build? build? any/c #f])
         (listof path?)]{

@margin-note{另参见 @racket[in-directory] 序列构造器。}

返回由 @racket[path] 指定的目录中所有文件和目录的列表。
如果 @racket[build?] 为 @racket[#f]，则结果路径都是 @tech{路径元素}；
否则，各个结果使用 @racket[build-path] 与 @racket[path] 组合。
在 Windows 上，结果列表的元素可能以 @litchar{\\?\\REL\\} 开头。

结果路径始终使用 @racket[path<?] 排序。}


@defproc[(filesystem-root-list) (listof path?)]{

返回所有当前根目录的列表。在 Windows 上获取此列表可能特别慢。}

@;------------------------------------------------------------------------
@section[#:tag "filesystem-change"]{检测文件系统更改}

许多操作系统提供文件系统更改通知，
这些通知在 Racket 中通过 @tech{文件系统更改事件} 反映。

@defproc[(filesystem-change-evt? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{文件系统更改事件} 则返回 @racket[#t]，
否则返回 @racket[#f]。}


@defproc[(filesystem-change-evt [path path-string?]
                                [failure-thunk (or/c (-> any) #f) #f])
         (or/c filesystem-change-evt? any)]{

创建一个 @deftech{文件系统更改事件}，它是一个 @tech{可同步事件}，
在 @racket[path] 更改后变为 @tech{准备好同步}：

@itemlist[

 @item{如果 @racket[path] 引用文件，当文件的内容或属性更改或文件被删除时，
       事件变为 @tech{准备好同步}。}

 @item{如果 @racket[path] 引用目录，当目录中添加、重命名或删除文件或子目录时，
       事件变为 @tech{准备好同步}。}

 ]

如果事件传递给 @racket[filesystem-change-evt-cancel]，
事件也会变为 @tech{准备好同步}。

最后，取决于操作系统可用信息的精度，
事件可能在其他情况下变为 @tech{准备好同步}。
例如，在 Windows 上，当文件所在目录中的任何文件更改时，
文件的事件变为就绪。

@tech{文件系统更改事件} 变为 @tech{准备好同步} 后，
它将保持 @tech{准备好同步} 状态。事件的 @tech{同步结果} 是事件本身。

如果当前平台不支持文件系统更改通知，
则当 @racket[failure-thunk] 未提供为过程时 @exnraise[exn:fail:unsupported]，
或者如果提供了 @racket[failure-thunk]，则在尾部位置调用它。
同样，如果创建事件时出现任何操作系统错误（例如不存在的文件），
则 @exnraise[exn:fail:filesystem] 或调用 @racket[failure-thunk]。

创建文件系统更改事件会在操作系统级别分配资源。
资源最迟在事件同步且 @tech{准备好同步} 时释放，
当事件通过 @racket[filesystem-change-evt-cancel] 取消时释放，
或者当垃圾收集器确定文件系统更改事件不可达时释放。
另参见 @racket[system-type] 的 @racket['fs-change] 模式。

文件系统更改事件在创建时置于 @tech{当前监管者} 的管理之下。
如果 @tech{监管者} 关闭，@racket[filesystem-change-evt-cancel] 将应用于事件。

@history[#:changed "7.3.0.8" @elem{允许 @racket[failure-thunk] 为 @racket[#f]。}]}


@defproc[(filesystem-change-evt-ready? [evt filesystem-change-evt?])
         boolean?]{

等价于 @racket[(and (sync/timeout 0 evt) #t)]。

@history[#:added "8.18.0.6"]}


@defproc[(filesystem-change-evt-cancel [evt filesystem-change-evt?])
         void?]{

使 @racket[evt] 立即变为 @tech{准备好同步}，
无论之前是否就绪，并释放（操作系统级别的）用于跟踪文件系统更改的资源。}


@;------------------------------------------------------------------------
@section[#:tag "runtime-path"]{声明运行时需要的路径}

@note-lib-only[racket/runtime-path]

@racketmodname[racket/runtime-path] 库提供了用于在运行时访问文件和目录的形式，
使用通常相对于封闭源文件的路径。与使用 @racket[collection-path] 不同，
@racket[define-runtime-path] 将每个运行时路径暴露给可执行文件和分发创建器等工具，
以便运行时需要的文件和目录随分发一起携带。

除了下面描述的绑定之外，@racketmodname[racket/runtime-path] 在 @tech{阶段级别} 1
提供 @racket[#%datum]，因为字符串常量通常用作 @racket[define-runtime-path] 的编译时表达式。

@defform[(define-runtime-path id maybe-runtime?-id expr)
         #:grammar ([maybe-runtime?-id code:blank
                                       (code:line #:runtime?-id runtime?-id)])]{

将 @racket[expr] 同时用作编译时（即 @tech{阶段} 1）表达式和运行时（即 @tech{阶段} 0）表达式。
在任一上下文中，@racket[expr] 应产生路径、表示路径的字符串、
形式为 @racket[(list 'lib _str ...+)] 的列表，或形式为 @racket[(list 'so _str)] 或
@racket[(list 'so _str _vers)] 的列表。
如果提供了 @racket[runtime?-id]，则它在 @racket[expr] 的上下文中绑定，
对于 @racket[expr] 的编译时实例为 @racket[#f]，对于运行时为 @racket[#t]。

对于运行时，@racket[id] 绑定到基于 @racket[expr] 结果的路径。
路径通常通过取 @racket[expr] 的相对路径结果并将其添加到封闭文件的路径来计算
（计算方式如下所述）。然而，可执行文件创建器等工具也可以安排
（通过与 @racketmodname[racket/runtime-path] 协作）在生成的可执行文件中替换不同的基本路径。
如果 @racket[expr] 产生绝对路径，通常直接返回，
但同样可能被可执行文件创建器替换。在所有情况下，
可执行文件创建器保留给定 @tech{包} 内所有路径的相对位置
（将任何包外的路径视为在一起）。
当 @racket[expr] 产生相对或绝对路径时，绑定到 @racket[id] 的路径始终是绝对路径。

如果 @racket[expr] 产生形式为 @racket[(list 'lib _str ...+)] 的列表，
绑定到 @racket[id] 的值是绝对路径。该路径引用类似于将值用作 @tech{模块路径} 的基于集合的文件。

如果 @racket[expr] 产生形式为 @racket[(list 'so _str)] 或 @racket[(list 'so _str _vers)] 的列表，
绑定到 @racket[id] 的值可以是 @racket[_str] 或绝对路径；
当在 Racket 特定的共享对象库目录（由 @racket[get-lib-search-dirs] 确定）中搜索定位路径时，
它是绝对路径。通过这种方式，专门为 Racket 安装的共享对象库随分发一起携带。
搜索按顺序尝试每个目录；在目录内，搜索首先尝试直接使用 @racket[_str]，
然后尝试添加 @racket[_vers] 指定的每个版本——默认为 @racket['(#f)]——
以及平台特定的共享库扩展——由 @racket[(system-type 'so-suffix)] 产生。
@racket[_vers] 可以是字符串，也可以是字符串和 @racket[#f] 的列表。

如果 @racket[expr] 产生形式为 @racket[(list 'share _str)] 的列表，
绑定到 @racket[id] 的值可以是 @racket[_str] 或绝对路径；
当在 @racket[find-user-share-dir] 和 @racket[find-share-dir] 报告的目录中
（按该顺序）搜索定位路径时，它是绝对路径。
通过这种方式，安装在 Racket 的 @filepath{share} 目录中的文件随分发一起携带。

如果 @racket[expr] 产生形式为 @racket[(list 'module _module-path _var-ref)] 或
@racket[(list 'so _str (list _str-or-false ...))] 的列表，
绑定到 @racket[id] 的值是 @tech{模块路径索引}，
其中 @racket[_module-path] 被视为相对于作为 @tech{变量引用} @racket[_var-ref] 的家的模块
（如果是相对的），其中如果 @racket[_module-path] 是绝对的，
@racket[_var-ref] 可以是 @racket[#f]。在可执行文件中，
相应的模块随其所有依赖项一起携带。

对于编译时，@racket[expr] 结果由可执行文件创建器使用——
而不是包含模块编译时的结果。相反，@racket[expr] 作为编译时表达式
（在 @racket[begin-for-syntax] 的意义上）保留在模块中。
后来，在创建可执行文件时，模块的编译时部分再次执行，
@racket[expr] 的结果是要与可执行文件包含的文件或目录。
额外编译时执行的原因是 @racket[expr] 的结果可能是平台相关的，
因此结果不应存储在模块的（平台无关的）字节码形式中；
然而，创建可执行文件时的平台与运行时的平台相同。
请注意，@racket[expr] 在运行时仍然被求值；因此，
避免使用像 @racket[collection-path] 这样依赖于源安装的过程，
而使用相对路径和像 @racket[(list 'lib _str ...+)] 这样的形式。

如果某些路径仅在某些平台而非其他平台上需要，
请使用 @racket[define-runtime-path-list] 并在不需要路径的平台上让 @racket[expr] 产生空列表。

请注意，如果 @racket[expr] 在创建可执行文件时产生目录的路径，
目录的完整内容（包括任何子目录）将与可执行文件或最终分发一起包含。

还要注意，@racket[define-runtime-path] 在 @tech{阶段级别} 0 以外的阶段中
不能正确与可执行文件创建器协作。为了解决该限制，
将 @racket[define-runtime-path] 放在单独的模块中——
也许是由 @racket[module] 创建的 @tech{子模块}——然后导出定义，
然后可以在任何阶段级别 @racket[require] 包含该定义的模块。
在 @tech{阶段级别} 0 以外的阶段使用 @racket[define-runtime-path] 会在展开时记录警告。

@racket[define-runtime-path] 的封闭路径按以下方式从 @racket[define-runtime-path] 语法形式确定：

@itemize[

 @item{如果形式根据 @racket[syntax-source-module] 具有源模块，
       则源位置通过将原始表达式保留为语法对象来确定，
       在运行时（再次使用 @racket[syntax-source-module]）提取其源模块路径，
       然后解析生成的模块路径索引。请注意，@racket[syntax-source-module]
       基于语法对象的 @tech{词法信息}，而不是其源位置。}

 @item{如果表达式没有源模块，
       则使用与形式关联的 @racket[syntax-source] 位置，
       如果是字符串或路径。}

 @item{如果没有源模块可用，且 @racket[syntax-source] 不产生路径，
       则使用 @racket[current-load-relative-directory]（如果不是 @racket[#f]）。
       最后，如果所有其他方法都失败，则使用 @racket[current-directory]。}

 ]

在后两种情况下，路径通常以（平台特定的）字节形式保留，
但如果封闭路径对应于 @racket[collection-file-path] 的结果，
则路径记录为相对于相应模块路径。

@history[#:changed "6.0.1.6" @elem{仅在包内保留相对路径。}
         #:changed "7.5.0.7" @elem{添加了对 @racket[expr] 中 @racket['share] 的支持。}]

示例：

@racketblock[
(code:comment @#,t{在运行时访问最初位于模块源文件同目录下的文件 @filepath{data.txt}})
(define-runtime-path data-file "data.txt")
(define (read-data) 
  (with-input-from-file data-file 
    (lambda () 
      (read-bytes (file-size data-file)))))

(code:comment @#,t{加载平台特定的共享对象（使用 @racket[ffi-lib]）})
(code:comment @#,t{该对象位于模块源目录的平台特定子目录中：})
(define-runtime-path libfit-path
  (build-path "compiled" "native" (system-library-subpath #f)
              (path-replace-suffix "libfit" 
                                   (system-type 'so-suffix))))
(define libfit (ffi-lib libfit-path))

(code:comment @#,t{加载可能作为操作系统一部分安装的})
(code:comment @#,t{或专门为 Racket 安装的共享对象：})
(define-runtime-path libssl-so
  (case (system-type)
    [(windows) '(so "ssleay32")]
    [else '(so "libssl")]))
(define libssl (ffi-lib libssl-so))
]

@history[#:changed "6.4" @elem{添加了 @racket[#:runtime?-id]。}]}


@defform[(define-runtime-paths (id ...) maybe-runtime?-id expr)]{

类似于 @racket[define-runtime-path]，但一次声明和绑定多个路径。
@racket[expr] 应产生与 @racket[id] 数量相同的值。}


@defform[(define-runtime-path-list id maybe-runtime?-id expr)]{

类似于 @racket[define-runtime-path]，但 @racket[expr] 应产生路径列表。}


@defform[(define-runtime-module-path-index id maybe-runtime?-id module-path-expr)]{

类似于 @racket[define-runtime-path]，但 @racket[id] 绑定到
@tech{模块路径索引}，该索引封装了相对于封闭模块的 @racket[module-path-expr] 的结果。

使用 @racket[define-runtime-module-path-index] 绑定传递给 @racket[dynamic-require]
等反射函数的模块路径，同时为构建和分发可执行文件创建模块依赖。}


@defform[(runtime-require module-path)]{

类似于 @racket[define-runtime-module-path-index]，但不绑定模块路径索引而创建分发依赖。
当 @racket[runtime-require] 在模块内多次使用相同的 @racket[module-path] 时，
除第一次使用外，所有使用都展开为空的 @racket[begin]。}


@defform[(define-runtime-module-path id module-path)]{

类似于 @racket[define-runtime-path]，但 @racket[id] 绑定到
@tech{已解析模块路径}。@racket[id] 的 @tech{已解析模块路径}
对应于 @racket[module-path]（语法与 @racket[require] 的模块路径相同），
可以相对于封闭模块。

通常首选 @racket[define-runtime-module-path-index] 形式，
因为它创建到引用模块的较弱链接。
与 @racket[define-runtime-module-path-index] 不同，
@racket[define-runtime-module-path] 形式从封闭模块到 @racket[module-path]
创建 @racket[for-label] 依赖。由于依赖仅是 @racket[for-label]，
当封闭模块被 @tech{实例化} 或 @tech{访问} 时，
@racket[module-path] 不会被 @tech{实例化} 或 @tech{访问}
（除非由其他 @racket[require] 创建这样的依赖），
但当封闭模块被加载时，引用模块的代码会被加载。}


@defform[(runtime-paths module-path)]{

此形式主要供可执行文件构建器等工具使用。
它展开为包含由 @racket[module-path] 声明的运行时路径的引用列表，
返回声明 @racket[expr] 的编译时结果，
但路径被转换为字节字符串。封闭模块必须（直接或间接）
require 由 @racket[module-path] 指定的模块，该模块是未引用的模块路径。
结果列表@emph{不}包括通过 @racket[define-runtime-module-path] 绑定的模块路径。}

@;------------------------------------------------------------------------
@section[#:tag "file-lib"]{更多文件和目录工具}

@note-lib[racket/file]

@defproc[(file->string [path path-string?]
                       [#:mode mode-flag (or/c 'binary 'text) 'binary])
         string?]{

从 @racket[path] 读取所有字符并将它们作为字符串返回。
@racket[mode-flag] 参数与 @racket[open-input-file] 中的相同。}

@defproc[(file->bytes [path path-string?]
                      [#:mode mode-flag (or/c 'binary 'text) 'binary])
         bytes?]{

从 @racket[path] 读取所有字符并将它们作为 @tech{字节字符串} 返回。
@racket[mode-flag] 参数与 @racket[open-input-file] 中的相同。}

@defproc[(file->value [path path-string?]
                      [#:mode mode-flag (or/c 'binary 'text) 'binary])
         any]{

使用 @racket[read] 从 @racket[path] 读取单个 S-表达式。
@racket[mode-flag] 参数与 @racket[open-input-file] 中的相同。}

@defproc[(file->list [path path-string?]
                     [proc (input-port? . -> . any/c) read]
                     [#:mode mode-flag (or/c 'binary 'text) 'binary])
         (listof any/c)]{

重复调用 @racket[proc] 以消耗 @racket[path] 的内容，
直到产生 @racket[eof]。@racket[mode-flag] 参数与 @racket[open-input-file] 中的相同。}

@defproc[(file->lines [path path-string?]
                      [#:mode mode-flag (or/c 'binary 'text) 'binary]
                      [#:line-mode line-mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'any])
         (listof string?)]{

从 @racket[path] 读取所有字符，将它们分成行。
@racket[line-mode] 参数与 @racket[read-line] 的第二个参数相同，
但默认值是 @racket['any] 而不是 @racket['linefeed]。
@racket[mode-flag] 参数与 @racket[open-input-file] 中的相同。}

@defproc[(file->bytes-lines [path path-string?]
                            [#:mode mode-flag (or/c 'binary 'text) 'binary]
                            [#:line-mode line-mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'any])
         (listof bytes?)]{

像 @racket[file->lines]，但读取字节并像 @racket[read-bytes-line] 一样将它们收集成行。}

@defproc[(display-to-file [v any/c]
                          [path path-string?]
                      [#:mode mode-flag (or/c 'binary 'text) 'binary]
                      [#:exists exists-flag (or/c 'error 'append 'update
                                                  'replace 'truncate 'truncate/replace) 'error])
         void?]{

使用 @racket[display] 将 @racket[v] 打印到 @racket[path]。
@racket[mode-flag] 和 @racket[exists-flag] 参数与 @racket[open-output-file] 中的相同。}

@defproc[(write-to-file [v any/c]
                        [path path-string?]
                      [#:mode mode-flag (or/c 'binary 'text) 'binary]
                      [#:exists exists-flag (or/c 'error 'append 'update
                                                  'replace 'truncate 'truncate/replace) 'error])
         void?]{

像 @racket[display-to-file]，但使用 @racket[write] 而不是 @racket[display]。}

@defproc[(display-lines-to-file [lst list?]
                                [path path-string?]
                       [#:separator separator any/c #"\n"]
                       [#:mode mode-flag (or/c 'binary 'text) 'binary]
                       [#:exists exists-flag (or/c 'error 'append 'update
                                                   'replace 'truncate 'truncate/replace) 'error])
         void?]{

将 @racket[lst] 的每个元素显示到 @racket[path]，每个元素后添加 @racket[separator]。
@racket[mode-flag] 和 @racket[exists-flag] 参数与 @racket[open-output-file] 中的相同。}

@defproc[(copy-directory/files [src path-string?] [dest path-string?]
                               [#:keep-modify-seconds? keep-modify-seconds? any/c #f]
                               [#:preserve-links? preserve-links? any/c #f])
         void?]{

将文件或目录 @racket[src] 复制到 @racket[dest]，
如果文件或目录无法复制（可能因为 @racket[dest] 已存在）则引发 @racket[exn:fail:filesystem]。
如果 @racket[src] 是目录，则复制递归应用于目录的内容。
如果源是链接且 @racket[preserve-links?] 为 @racket[#f]，
则复制链接的目标而不是链接本身；如果 @racket[preserve-links?] 为 @racket[#t]，则复制链接。

如果 @racket[keep-modify-seconds?] 为 @racket[#f]，则文件副本仅保留 @racket[copy-file] 保留的属性。
如果 @racket[keep-modify-seconds?] 为真，则每个文件副本还保留原件的修改日期。

@history[#:changed "6.3" @elem{添加了 @racket[#:preserve-links?] 参数。}]}


@defproc[(delete-directory/files [path path-string?]
                                 [#:must-exist? must-exist? any/c #t])
         void?]{

删除由 @racket[path] 指定的文件或目录，
如果文件或目录无法删除则引发 @racket[exn:fail:filesystem]。
如果 @racket[path] 是目录，则在删除目录之前，
首先对 @racket[path] 中的每个文件和目录应用 @racket[delete-directory/files]。

如果 @racket[must-exist?] 为真，则当 @racket[path] 不存在时引发 @racket[exn:fail:filesystem]。
如果 @racket[must-exist?] 为假，则当 @racket[path] 不存在时 @racket[delete-directory/files] 成功
（但如果 @racket[path] 最初存在并被另一个线程或进程在 @racket[delete-directory/files] 删除它之前移除，则可能失败）。

在 Windows 上，@racket[delete-directory/files] 尝试在删除文件之前将其移动到临时文件目录，
这避免了在删除当前打开的文件时引起的问题（例如，由作为后台进程运行的搜索索引器打开）。
如果移动尝试失败（例如，因为临时目录与文件在不同的驱动器上），
则直接使用 @racket[delete-file] 删除文件。

@history[#:changed "7.0" @elem{添加了 Windows 特定的文件删除。}]}


@defproc[(find-files [predicate (path? . -> . any/c)]
                     [start-path (or/c path-string? #f) #f]
                     [#:skip-filtered-directory? skip-filtered-directory? any/c #f]
                     [#:follow-links? follow-links? any/c #f])
         (listof path?)]{

从 @racket[start-path] 开始遍历文件系统，
并创建 @racket[predicate] 返回真的所有文件和目录的列表。
如果 @racket[start-path] 是 @racket[#f]，则遍历从 @racket[(current-directory)] 开始。
在结果列表中，每个目录都位于其内容之前。

@racket[predicate] 过程对每个文件或目录使用单个参数调用。
如果 @racket[start-path] 是 @racket[#f]，则参数是相对于当前目录的路径名字符串。
否则，它是基于 @racket[start-path] 的路径。因此，
为 @racket[start-path] 提供 @racket[(current-directory)] 与提供 @racket[#f] 不同，
因为在后一种情况下 @racket[predicate] 接收相对路径，而在前一种情况下接收完整路径。
另一个区别是当 @racket[start-path] 是 @racket[#f] 时，
@racket[predicate] 不会为当前目录调用。

如果 @racket[skip-filtered-directory?] 为真，则当 @racket[predicate] 对目录返回 @racket[#f] 时，
不会遍历该目录的内容。

如果 @racket[follow-links?] 为真，@racket[find-files] 遍历跟随链接，
并且链接不包含在结果中。如果 @racket[follow-links?] 为 @racket[#f]，
则不跟随链接，并且链接包含在结果中。

如果 @racket[start-path] 不引用现有文件或目录，
则 @racket[predicate] 将恰好调用一次，以 @racket[start-path] 作为参数。

@racket[find-files] 过程在遇到 @racket[directory-list] 失败的目录时引发异常。

@history[#:changed "6.3.0.11" @elem{添加了
                                    @racket[#:skip-filtered-directory?]
                                    参数。}]}

@defproc[(pathlist-closure [path-list (listof path-string?)]
                           [#:path-filter path-filter (or/c #f (path? . -> . any/c)) #f]
                           [#:follow-links? follow-links? any/c #f])
         (listof path?)]{

给定一个路径列表（绝对或相对于当前目录），返回一个列表，使得

@itemize[

 @item{如果给定嵌套路径，其所有祖先也包含在结果中
       （但同一祖先不会添加两次）；}

 @item{如果路径引用目录，其所有后代也包含在结果中，
       除非被 @racket[path-filter] 省略；}

 @item{祖先目录在结果列表中出现在其后代之前，
       只要它们在给定的 @racket[path-list] 中没有被错误排序。}

 ]

如果 @racket[path-filter] 是过程，则它应用于目录的每个后代。
如果 @racket[path-filter] 返回 @racket[#f]，则该后代（及其任何后代，
如果是子目录）从结果中省略。

如果 @racket[follow-links?] 为真，则目录和文件的遍历跟随链接，
并且链接路径不包含在结果中。如果 @racket[follow-links?] 为 @racket[#f]，
则结果列表包含链接的路径并且不跟随链接。

@history[#:changed "6.3.0.11" @elem{添加了 @racket[#:path-filter] 参数。}]}


@defproc[(fold-files [proc (or/c (path? (or/c 'file 'dir 'link) any/c 
                                   . -> . any/c)
                                 (path? (or/c 'file 'dir 'link) any/c 
                                   . -> . (values any/c any/c)))]
                     [init-val any/c]
                     [start-path (or/c path-string? #f) #f]
                     [follow-links? any/c #t])
         any]{

从 @racket[start-path] 开始遍历文件系统，
对每个发现的文件、目录和链接调用 @racket[proc]。
如果 @racket[start-path] 是 @racket[#f]，则遍历从 @racket[(current-directory)] 开始。

@racket[proc] 过程对每个文件、目录或链接使用三个参数调用：

@itemize[

 @item{如果 @racket[start-path] 是 @racket[#f]，则第一个参数是相对于当前目录的路径名字符串。
 否则，第一个参数是以 @racket[start-path] 开头的路径名。因此，
 为 @racket[start-path] 提供 @racket[(current-directory)] 与提供 @racket[#f] 不同，
 因为在后一种情况下 @racket[proc] 接收相对路径，而在前一种情况下接收完整路径。
 另一个区别是当 @racket[start-path] 是 @racket[#f] 时，
 @racket[proc] 不会为当前目录调用。}

 @item{第二个参数是符号，@racket['file]、@racket['dir] 或 @racket['link]。
 当 @racket[follow-links?] 为 @racket[#f] 时，第二个参数可以是 @racket['link]，
 在这种情况下文件系统遍历不跟随链接。如果 @racket[follow-links?] 为 @racket[#t]，
 则 @racket[proc] 仅在遇到悬空符号链接（不解析为现有文件或目录的链接）时
 才会将 @racket['link] 作为第二个参数接收。}

 @item{第三个参数是累积结果。对于 @racket[proc] 的第一次调用，
 第三个参数是 @racket[init-val]。对于 @racket[proc] 的第二次调用（如果有），
 第三次调用的第三个参数是第一次调用的结果，依此类推。
 @racket[proc] 的最后一次调用的结果是 @racket[fold-files] 的结果。}

 ]

@racket[proc] 参数的使用方式类似于 @racket[foldl] 的过程参数，
其结果用作新的累积结果。对于目录的情况（当第二个参数是 @racket['dir] 时）有一个例外：
在这种情况下，过程可以返回两个值，第二个值指示是否应包含给定目录的递归扫描。
如果返回单个值，则扫描目录。对于文件或链接的情况
（当第二个参数是 @racket['file] 或 @racket['link] 时），允许第二个值但被忽略。

如果提供了 @racket[start-path] 但这样的路径不存在，或者路径在扫描过程中消失，
则引发异常。}


@defproc[(make-directory* [path path-string?]) void?]{

创建由 @racket[path] 指定的目录，必要时创建中间目录，
如果 @racket[path] 已存在则永不失败。

如果 @racket[path] 是相对路径且当前目录不存在，
则 @racket[make-directory*] 不会创建当前目录，
因为它仅考虑 @racket[path] 的显式元素。}


@defproc[(make-parent-directory* [path path-string?]) void?]{

创建由 @racket[path] 指定的路径的父目录，
必要时创建中间目录，如果 @racket[path] 的祖先已存在则永不失败。

如果 @racket[path] 是文件系统根目录或具有单个路径元素的相对路径，
则不创建目录。像 @racket[make-directory*]，
如果 @racket[path] 是相对路径且当前目录不存在，
则 @racket[make-parent-directory*] 不会创建它。

@history[#:added "6.1.1.3"]}


@defproc[(make-temporary-file [template string? "rkttmp~a"]
                              [#:copy-from copy-from (or/c path-string? #f 'directory) #f]
                              [#:base-dir base-dir (or/c path-string? #f) #f]
                              [compat-copy-from (or/c path-string? #f 'directory) copy-from]
                              [compat-base-dir (or/c path-string? #f) base-dir])
         (and/c path? complete-path?)]{

创建一个新的临时文件并返回其路径。
不仅仅是生成一个新的文件名，文件实际上被创建；
这防止了其他线程或进程选择相同的临时名称。

@racket[template] 参数必须是适合与 @racket[format] 一起使用的格式字符串，
带有一个额外的字符串参数（将仅包含数字）。默认情况下，
如果 @racket[template] 产生相对路径，则它与 @racket[(find-system-path 'temp-dir)] 的结果
使用 @racket[build-path] 组合；或者，@racket[template] 可以产生绝对路径，
在这种情况下不参考 @racket[(find-system-path 'temp-dir)]。
如果提供了 @racket[base-dir] 且非 @racket[#false]，
则 @racket[template] 不得产生 @tech{完整} 路径，
并且 @racket[base-dir] 将代替 @racket[(find-system-path 'temp-dir)] 使用。
使用 @racket[base-dir] 通常比在 @racket[template] 中包含目录组件更可靠：
它避免了操作路径作为字符串产生的微妙错误，并消除了清理 @racket[format] 转义序列的需要。

在 Windows 上，当 @racket[base-dir] 不存在或为 @racket[#f] 时，
@racket[template] 可能产生不是完整路径的绝对路径（参见 @secref["windowspaths"]），
在这种情况下它将相对于 @racket[(current-directory)] 解析，
或者如果 @racket[base-dir] 是驱动器规格，则将与 @racket[build-path] 一起使用。
如果 @racket[base-dir] 是任何其他类型的路径，则 @racket[template] 产生绝对路径是错误的。

当未提供 @racket[template] 参数时，
如果 @racket[make-temporary-file] 的调用位置有源位置信息，
则基于源位置生成模板字符串：默认值 @racket["rkttmp~a"] 仅在无源位置信息时可用
（例如，当 @racket[make-temporary-file] 在高阶位置使用时）。

如果 @racket[copy-from] 作为路径提供，则临时文件创建为命名文件的副本
（使用 @racket[copy-file]）。如果 @racket[copy-from] 是 @racket[#f]，
则临时文件创建为空。作为特殊情况，为了向后兼容，
如果 @racket[copy-from] 是 @racket['directory]，则临时``文件''创建为目录：
为清晰起见，创建临时目录首选 @racket[make-temporary-directory]。

创建临时文件时，在返回路径时不会为读取或写入打开它。
调用 @racket[make-temporary-file] 的客户端程序应使用所需的访问权限和标志打开文件
（可能使用 @racket['truncate] 标志；参见 @racket[open-output-file]），
并在不再需要时删除它。

位置参数 @racket[compat-copy-from] 和 @racket[compat-base-dir] 用于向后兼容：
如果提供，它们优先于 @racket[#:copy-from] 和 @racket[#:base-dir] 关键字变体。
提供位置参数会阻止 @racket[make-temporary-file] 使用源位置生成 @racket[template]。

@history[
 #:changed "8.4.0.3"
 @elem{添加了 @racket[#:copy-from] 和 @racket[#:base-dir] 参数。}
 ]}

@defproc[(make-temporary-directory [template string? "rkttmp~a"]
                                   [#:base-dir base-dir (or/c path-string? #f) #f])
         (and/c path? complete-path?)]{

 像 @racket[make-temporary-file]，但创建目录而不是常规文件。

 与 @racket[make-temporary-file] 一样，如果未提供 @racket[template] 参数，
 当可能时，从调用 @racket[make-temporary-directory] 的源位置生成模板字符串：
 默认值 @racket["rkttmp~a"] 仅在无源位置信息时可用。

@history[
 #:added "8.4.0.3"
 ]}

@deftogether[
 (@defproc[(make-temporary-file* [prefix bytes?]
                                 [suffix bytes?]
                                 [#:copy-from copy-from (or/c path-string? #f) #f]
                                 [#:base-dir base-dir (or/c path-string? #f) #f])
           (and/c path? complete-path?)]
   @defproc[(make-temporary-directory* [prefix bytes?]
                                       [suffix bytes?]
                                       [#:base-dir base-dir (or/c path-string? #f) #f])
            (and/c path? complete-path?)])]{

 像 @racket[make-temporary-file] 和 @racket[make-temporary-directory]，
 但相对于用于 @racket[format] 的模板，路径基于
 @racket[(bytes-append prefix generated suffix)]，
 其中 @racket[generated] 是实现选择的字节字符串，用于产生唯一路径。
 如果 @racket[make-temporary-file*] 或 @racket[make-temporary-directory*]
 的调用位置有源位置信息，@racket[generated] 将包含该信息。
 结果路径与 @racket[base-dir] 组合，如 @racket[make-temporary-file] 中一样。

 @history[
 #:added "8.4.0.3"
 ]}

@defproc[(call-with-atomic-output-file [file path-string?] 
                                       [proc (output-port? path? . -> . any)]
                                       [#:security-guard security-guard (or/c #f security-guard?) #f]
                                       [#:rename-fail-handler rename-fail-handler (or/c #f (exn:fail:filesystem? path? . -> . any)) #f])
         any]{

在与 @racket[file] 相同的目录中打开一个临时文件进行写入，
调用 @racket[proc] 写入临时文件，然后原子性地（Windows 除外）将临时文件移动到 @racket[file] 的位置。
在 Unix 和 Mac OS 上，移动仅使用 @racket[rename-file-or-directory]，
在 Windows 上，如果提供了 @racket[rename-fail-handler]，则使用 @racket[rename-file-or-directory]；
否则，在 Windows 上使用额外的重命名步骤（见下文）以避免 @racket[file] 的并发读取者引起的问题。

@racket[proc] 函数使用临时文件的输出端口以及临时文件的路径调用。
@racket[proc] 的结果是 @racket[call-with-atomic-output-file] 的结果。

@racket[call-with-atomic-output-file] 函数安排在异常时删除临时文件。

Windows 阻止程序删除或替换打开的文件，但允许重命名打开的文件。
因此，在 Windows 上，@racket[call-with-atomic-output-file] 默认创建第二个临时文件
@racket[_extra-tmp-file]，将 @racket[file] 重命名为 @racket[_extra-tmp-file]，
将由 @racket[proc] 写入的临时文件重命名为 @racket[file]，最后删除 @racket[_extra-tmp-file]。
然而，由于该过程不是原子的，如果提供了 @racket[rename-fail-handler]，
则使用 @racket[rename-file-or-directory]，
因为移动的源和目标将在同一目录中，@racket[rename-file-or-directory] 有原子的机会；
尝试重命名文件时的任何文件系统异常都会发送到 @racket[rename-fail-handler]，
它可以重新 @racket[raise] 异常或仅返回以重试，可能在延迟之后。
除了文件系统异常，@racket[rename-fail-handler] 过程还接收要移动到 @racket[path] 的临时文件路径。
@racket[rename-fail-handler] 参数仅在 Windows 上使用。

@history[#:changed "7.1.0.6" @elem{添加了 @racket[#:rename-fail-handler] 参数。}]}


@defproc[(get-preference [name symbol?]
                         [failure-thunk (-> any) (lambda () #f)]
                         [flush-mode any/c 'timestamp]
                         [filename (or/c path-string? #f) #f]
                         [#:use-lock? use-lock? any/c #t]
                         [#:timeout-lock-there timeout-lock-there
                                               (or/c (path? . -> . any) #f)
                                               #f]
                         [#:lock-there
                          lock-there
                          (or/c (path? . -> . any) #f)
                          (make-handle-get-preference-locked
                           0.01 name failure-thunk flush-mode filename
                           #:lock-there timeout-lock-there)])
         any]{

从 @racket[(find-system-path 'pref-file)] 指定的文件中提取偏好值，
或者如果提供了 @racket[filename] 且不为 @racket[#f]，则从 @racket[filename] 中提取。
在前一种情况下，如果偏好文件不存在，@racket[get-preferences] 尝试读取
@elemref["old-prefs"]{旧偏好文件}，然后读取配置目录中的 @filepath{racket-prefs.rktd} 文件
（由 @racket[find-config-dir] 报告）。如果这些文件都不存在，偏好集为空。

偏好文件应包含使用默认参数设置写入的符号-值列表的列表。
以 @racket[racket:]、@racket[mzscheme:]、@racket[mred:] 和 @racket[plt:] 开头的键
（任何字母大小写）保留给 Racket 实现者使用。
如果偏好文件不包含符号-值列表的列表，则通过 @racket[log-error] 记录错误并调用 @racket[failure-thunk]。

@racket[get-preference] 的结果是如果 @racket[name] 存在于关联列表中则返回关联的值，
否则返回调用 @racket[failure-thunk] 的结果。

偏好设置在 @racket[get-preference] 调用之间（弱）缓存，
使用 @racket[(path->complete-path filename)] 作为缓存键。
如果 @racket[flush-mode] 作为 @racket[#f] 提供，则使用缓存而不是重新查询偏好文件。
如果 @racket[flush-mode] 作为 @racket['timestamp]（默认值）提供，
则仅当文件的时间戳与上次读取文件的时间相同时才使用缓存。否则，重新查询文件。

在 @racket[preferences-lock-file-mode] 返回 @racket['file-lock] 的平台上，
当 @racket[use-lock?] 为真时，偏好文件读取由锁保护；多个读取者可以共享锁，但写入者独占获取锁。
如果偏好文件因锁不可用而无法读取，则在锁文件的路径上调用 @racket[lock-there]；
如果 @racket[lock-there] 是 @racket[#f]，则引发异常。
默认的 @racket[lock-there] 处理程序重试约 5 次（每次尝试之间的延迟增加），
然后尝试 @racket[timeout-lock-there]，默认的 @racket[timeout-lock-there] 触发异常。

另参见 @racket[put-preferences]。对于更精细的偏好系统，参见 @racket[preferences:get]。

@elemtag["old-prefs"]{@bold{旧偏好文件}}：当未提供 @racket[filename]
且 @racket[(find-system-path 'pref-file)] 指示的文件不存在时，
检查以下路径以兼容旧版本的 Racket：

@itemlist[

 @item{Windows：@racket[(build-path (find-system-path 'pref-dir) 'up "PLT Scheme" "plt-prefs.ss")]}

 @item{Mac OS：@racket[(build-path (find-system-path 'pref-dir) "org.plt-scheme.prefs.ss")]}

 @item{Unix：@racket[(expand-user-path "~/.plt-scheme/plt-prefs.ss")]}

 ]

@defproc[(put-preferences [names (listof symbol?)]
                          [vals list?]
                          [locked-proc (or/c #f (path? . -> . any)) #f]
                          [filename (or/c #f path-string?) #f])
         void?]{

安装一组偏好值并将所有当前值写入由 @racket[(find-system-path 'pref-file)] 指定的偏好文件，
或者如果提供了 @racket[filename] 且不为 @racket[#f]，则写入 @racket[filename]。

@racket[names] 参数提供偏好名称，@racket[vals] 必须与 @racket[names] 长度相同。
@racket[vals] 的每个元素必须是内置数据类型的实例，
其 @racket[write] 输出是 @racket[read] 可读的（即在写入偏好时将 @racket[print-unreadable] 参数设置为 @racket[#f]）。

更新前从偏好文件读取当前偏好值，并在文件读取之前开始持有写锁，直到偏好文件更新后释放。
锁通过在与偏好文件相同的目录中存在文件来实现；
参见 @racket[preferences-lock-file-mode] 了解更多信息。
如果偏好文件的目录不存在，则创建它。

如果写锁已被持有，则 @racket[locked-proc] 使用单个参数调用：锁文件的路径。
默认的 @racket[locked-proc]（当 @racket[locked-proc] 参数为 @racket[#f] 时使用）报告错误；
替代的 thunk 可能等待一段时间然后重试，或者让用户选择删除锁文件
（如果先前的更新尝试遇到灾难并且锁是通过锁文件的存在实现的）。

如果 @racket[filename] 是 @racket[#f] 或未提供，且偏好文件不存在，
则从 @filepath{defaults} 集合（如果有）读取的值将写入未在 @racket[names] 中提及的偏好。}


@defproc[(preferences-lock-file-mode) (or/c 'exists 'file-lock)]{

报告当前平台上用于实现偏好文件锁定的锁文件使用方式。

@racket['exists] 模式目前用于除 Windows 外的所有平台。
在 @racket['exists] 模式下，锁文件的存在表示持有写锁，读取者不需要锁
（因为偏好文件通过 @racket[rename-file-or-directory] 原子更新）。

@racket['file-lock] 模式目前用于 Windows。在 @racket['file-lock] 模式下，
锁文件上的共享和独占锁（在 @racket[port-try-file-lock?] 的意义上）
反映偏好文件内容的读取者和写入者锁。
（偏好文件本身未锁定，因为锁定会干扰通过 @racket[rename-file-or-directory] 替换文件。）}


@defproc[(make-handle-get-preference-locked
          [delay real?]
          [name symbol?]
          [failure-thunk (-> any) (lambda () #f)]
          [flush-mode any/c 'timestamp]
          [filename (or/c path-string? #f) #f]
          [#:lock-there lock-there (or/c (path? . -> . any) #f) #f]
          [#:max-delay max-delay real? 0.2])
         (path-string? . -> . any)]{

创建一个适合用作 @racket[get-preference] 的 @racket[#:lock-there] 参数的过程，
其中 @racket[name]、@racket[failure-thunk]、@racket[flush-mode] 和 @racket[filename]
都传递给 @racket[get-preference] 由结果过程重试偏好查找。

在调用 @racket[get-preference] 之前，结果过程使用 @racket[(sleep delay)] 暂停。
然后，如果 @racket[(* 2 delay)] 小于 @racket[max-delay]，
结果过程调用 @racket[make-handle-get-preference-locked] 生成新的重试过程
传递给 @racket[get-preference]，但 @racket[delay] 为 @racket[(* 2 delay)]。
如果 @racket[(* 2 delay)] 不小于 @racket[max-delay]，
则使用给定的 @racket[lock-there] 调用 @racket[get-preference]。}

@defproc[(call-with-file-lock/timeout
          [filename (or/c path-string? #f)]
          [kind (or/c 'shared 'exclusive)]
          [thunk (-> any)]
          [failure-thunk (-> any)]
          [#:lock-file lock-file (or/c #f path-string?) #f]
          [#:delay delay (and/c real? (not/c negative?)) 0.01]
          [#:max-delay max-delay (and/c real? (not/c negative?)) 0.2])
         any]{

获取文件名 @racket[lock-file] 的锁，然后调用 @racket[thunk]。
@racket[filename] 参数指定仅当 @racket[lock-file] 为 @racket[#f] 时用于生成锁文件名的文件路径前缀。
具体来说，当 @racket[lock-file] 为 @racket[#f] 时，
@racket[call-with-file-lock/timeout] 使用 @racket[make-lock-file-name] 构建锁文件名。
如果锁文件尚不存在，则创建它；请注意，锁文件@emph{不会}被
@racket[call-with-file-lock/timeout] 删除。

当 @racket[thunk] 返回时，
@racket[call-with-file-lock/timeout] 释放锁，返回 @racket[thunk] 的结果。
@racket[call-with-file-lock/timeout] 函数将在 @racket[delay] 秒后重试，
并以指数退避继续重试，直到延迟达到 @racket[max-delay]。
如果 @racket[call-with-file-lock/timeout] 无法获取锁，
则在尾部位置调用 @racket[failure-thunk]。@racket[kind] 参数指定锁是
@racket['shared] 还是 @racket['exclusive]，在 @racket[port-try-file-lock?] 的意义上。

}


@examples[
  #:eval file-eval
  (call-with-file-lock/timeout filename 'exclusive
    (lambda () (printf "File is locked\n"))
    (lambda () (printf "Failed to obtain lock for file\n")))

  (call-with-file-lock/timeout #f 'exclusive
    (lambda () 
      (call-with-file-lock/timeout filename 'shared
        (lambda () (printf "Shouldn't get here\n"))
        (lambda () (printf "Failed to obtain lock for file\n"))))
    (lambda () (printf "Shouldn't get here either\n"))
    #:lock-file (make-lock-file-name filename))]


@defproc*[([(make-lock-file-name [path (or/c path-string? path-for-some-system?)])
            path?]
           [(make-lock-file-name [dir (or/c path-string? path-for-some-system?)]
                                 [name path-element?]) 
            path?])]{

通过在 Windows 上（即当 @racket[cross-system-type] 报告 @racket['windows] 时）
在文件路径的文件部分前添加 @racket["_LOCK"] 或在其他平台上添加 @racket[".LOCK"] 来创建锁文件名。

@examples[
  #:eval file-eval
  (make-lock-file-name "/home/george/project/important-file")]}

@deftogether[(
; See https://en.wikibooks.org/wiki/C_Programming/POSIX_Reference/sys/stat.h
@defthing[file-type-bits             @#,racketvalfont{#o170000}]
@defthing[socket-type-bits           @#,racketvalfont{#o140000}]
@defthing[symbolic-link-type-bits    @#,racketvalfont{#o120000}]
@defthing[regular-file-type-bits     @#,racketvalfont{#o100000}]
@defthing[block-device-type-bits     @#,racketvalfont{#o060000}]
@defthing[directory-type-bits        @#,racketvalfont{#o040000}]
@defthing[character-device-type-bits @#,racketvalfont{#o020000}]
@defthing[fifo-type-bits             @#,racketvalfont{#o010000}]
@defthing[set-user-id-bit            @#,racketvalfont{#o004000}]
@defthing[set-group-id-bit           @#,racketvalfont{#o002000}]
@defthing[sticky-bit                 @#,racketvalfont{#o001000}]
@defthing[user-permission-bits       @#,racketvalfont{#o000700}]
@defthing[user-read-bit              @#,racketvalfont{#o000400}]
@defthing[user-write-bit             @#,racketvalfont{#o000200}]
@defthing[user-execute-bit           @#,racketvalfont{#o000100}]
@defthing[group-permission-bits      @#,racketvalfont{#o000070}]
@defthing[group-read-bit             @#,racketvalfont{#o000040}]
@defthing[group-write-bit            @#,racketvalfont{#o000020}]
@defthing[group-execute-bit          @#,racketvalfont{#o000010}]
@defthing[other-permission-bits      @#,racketvalfont{#o000007}]
@defthing[other-read-bit             @#,racketvalfont{#o000004}]
@defthing[other-write-bit            @#,racketvalfont{#o000002}]
@defthing[other-execute-bit          @#,racketvalfont{#o000001}]
)]{

与 @racket[file-or-directory-permissions]、@racket[file-or-directory-stat]
以及位运算（如 @racket[bitwise-ior] 和 @racket[bitwise-and]）一起使用的常量。}


@examples[#:hidden #:eval file-eval
          (delete-file filename)
          (delete-file (make-lock-file-name filename))]
@(close-eval file-eval)
