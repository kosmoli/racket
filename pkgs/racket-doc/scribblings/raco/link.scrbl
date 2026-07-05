#lang scribble/doc
@(require scribble/manual
          scribble/bnf 
          "common.rkt"
          (for-label racket/base
                     racket/contract
                     setup/link
                     setup/dirs))

@title[#:tag "link"]{@exec{raco link}: 库集合链接}

@exec{raco link} 命令检查和修改 @tech[#:doc reference-doc]{集合链接文件}，用于显示、添加或删除从集合名称到文件系统目录的映射。

通常不建议直接管理链接。相反，请使用包管理器（参见 @other-manual['(lib "pkg/scribblings/pkg.scrbl")]），它安装和管理链接（即建立在 @exec{raco link} 之上），能够更好地支持与他人共享集合。尽管如此，仍可直接使用 @exec{raco link}。

例如，以下命令

@commandline{raco link maze}

为 @racket["maze"] 集合安装一个用户特定且版本特定的链接，将当前目录的 @filepath{maze} 子目录映射到该集合。提供多个目录路径可一次创建多个链接，特别适合使用命令行 shell 通配符：

@commandline{raco link *}

默认情况下，链接后的集合名称与每个目录的名称相同，但可通过 @DFlag{name} 标志为单个目录单独设置集合名称。

要删除上面第一个示例创建的链接，可使用

@commandline{raco link --remove maze}

或

@commandline{raco link -r maze}

与添加链接模式类似，删除模式也接受多个目录路径以删除多个链接，并且所有与任一目录匹配的链接都会被删除。如果 @DFlag{name} 与 @DFlag{remove} 一起使用，则只会删除同时匹配集合名称和目录的链接。

完整的命令行选项：

@itemlist[

 @item{@Flag{l} 或 @DFlag{list} --- 显示当前链接表。如果提供了其他修改链接表的命令行参数，修改完成后将显示该表。如果未提供目录参数，并且未指定 @Flag{u}、@DFlag{user}、@Flag{i}、@DFlag{installation}、@Flag{f} 或 @DFlag{file}，则显示所有用户范围和安装范围的 @tech[#:doc reference-doc]{集合链接文件}的链接表。}

 @item{@Flag{n} @nonterm{name} 或 @DFlag{name} @nonterm{name} --- 设置添加单个链接或删除匹配链接的集合名称。默认情况下，添加链接的集合名称从目录名派生。当同时使用 @Flag{r} 或 @DFlag{remove} 标志时，只会删除集合名称匹配 @nonterm{name} 的链接；如果未提供目录参数，则删除所有与 @nonterm{name} 匹配的链接。此标志与 @Flag{d} 和 @DFlag{root} 互斥。}

 @item{@Flag{d} 或 @DFlag{root} --- 将每个目录视为包含集合目录的集合根目录，而不是用于特定集合的目录。当同时使用 @Flag{r} 或 @DFlag{remove} 标志时，只会删除与目录匹配的集合根链接。此标志与 @Flag{n} 和 @DFlag{name} 互斥。}

 @item{@Flag{D} 或 @DFlag{static-root} --- 类似于 @Flag{d} 或 @DFlag{root}，但假设每个目录具有一组固定的子目录（以改进集合搜索缓存的使用），只要链接文件自身不发生变化。}

 @item{@Flag{x} @nonterm{regexp} 或 @DFlag{version-regexp} @nonterm{regexp} --- 设置版本正则表达式，将链接限定为仅由与 @nonterm{regexp} 匹配的 Racket 版本（如 @racket[version] 所报告）使用。此标志通常与 @Flag{u} 或 @DFlag{user} 一起用于具有不同版本但相同安装名称的安装。当同时使用 @Flag{r} 或 @DFlag{remove} 标志时，只会删除版本正则表达式匹配 @nonterm{regexp} 的链接。}

 @item{@Flag{r} 或 @DFlag{remove} --- 选择删除模式而非添加模式。}

 @item{@Flag{u} 或 @DFlag{user} --- 将链接的显示和删除限制为用户特定的 @tech[#:doc reference-doc]{集合链接文件}，而非安装范围的 @tech[#:doc reference-doc]{集合链接文件}。此标志与 @Flag{i}、@DFlag{installation}、@Flag{f} 和 @DFlag{file} 互斥。}

 @item{@Flag{i} 或 @DFlag{installation} --- 在安装范围的 @tech[#:doc reference-doc]{集合链接文件} 中读取和写入链接，而非用户特定的 @tech[#:doc reference-doc]{集合链接文件}。此标志与 @Flag{u}、@DFlag{user}、@Flag{f} 和 @DFlag{file} 互斥。}

 @item{@Flag{f} @nonterm{file} 或 @DFlag{file} @nonterm{file} --- 在 @nonterm{file} 中读取和写入链接，而非用户特定的 @tech[#:doc reference-doc]{集合链接文件}。此标志与 @Flag{u}、@DFlag{user}、@Flag{s}、@DFlag{shared}、@Flag{i} 和 @DFlag{installation} 互斥。}

 @item{@Flag{v} @nonterm{vers} 或 @DFlag{version} @nonterm{vers} --- 选择 @nonterm{vers} 作为对用户特定 @tech[#:doc reference-doc]{集合链接文件} 进行操作的相关安装名称。}

 @item{@DFlag{repair} --- 当文件内容出错时，允许修复现有文件内容。通过尽可能单独删除链接来修复文件。}

]

@; ----------------------------------------

@section{集合链接 API}

@defmodule[setup/link]

@defproc[(links [dir path?] ...
                [#:user? user? any/c #t]
                [#:user-version user-version string? (get-installation-name)]
                [#:file file (or/c path-string? #f) #f]
                [#:name name (or/c string? #f) #f]
                [#:root? root? any/c #f]
                [#:static-root? static-root? any/c #f]
                [#:version-regexp version-regexp (or/c regexp? #f) #f]
                [#:error error-proc (symbol? string? any/c ... . -> . any) error]
                [#:remove? remove? any/c #f]
                [#:show? show? any/c #f]
                [#:repair? repair? any/c #f]
                [#:with-path? with-path? any/c #f])
          list?]{

@exec{raco link} 命令的函数版本，始终在单个文件上操作——如果 @racket[file] 是路径字符串则为该文件，如果 @racket[user?] 为真则为用户特定的 @tech[#:doc reference-doc]{集合链接文件}，否则为安装范围的 @tech[#:doc reference-doc]{集合链接文件}。如果 @racket[user?] 为真，则 @racket[user-version] 决定相关的安装名称（默认为当前安装的名称）。

除非 @racket[root?] 为真且 @racket[remove?] 为假，否则 @racket[static-root?] 标志值将被忽略；在这种情况下，如果 @racket[static-root?] 为真，则给定的每个 @racket[dir] 将被添加为静态根目录。

调用 @racket[error-proc] 参数来引发原本会使 @exec{raco link} 命令致命的异常。

如果 @racket[remove?] 为真，结果是已从文件中删除的条目列表。如果 @racket[remove?] 为 @racket[#f] 但 @racket[root?] 为真，结果是集合根的路径列表。如果 @racket[remove?] 和 @racket[root?] 均为 @racket[#f]，结果是顶层集合的列表，这些集合由 @racket[file] 映射且适用于当前运行的 Racket 版本；如果 @racket[with-path?] 为 @racket[#f]，该列表为集合名称字符串的列表，如果 @racket[with-path?] 为真，则为集合名称字符串和完整路径的对对列表。}
