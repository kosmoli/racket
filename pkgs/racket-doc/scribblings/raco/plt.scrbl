#lang scribble/doc
@(require scribble/manual 
          "common.rkt" 
          (for-label racket/base
                     setup/pack
                     racket/contract/base))

@title[#:tag "plt"]{@exec{raco pack}: 打包库 Collection}

@exec{raco pack} 命令创建文件和目录的归档。以前，这些归档直接用于向 Racket 用户分发库文件，但包管理器（参见 @other-manual['(lib "pkg/scribblings/pkg.scrbl")]）现在是首选的分发机制。

打包归档通常以 @filepath{.plt} 为后缀。@exec{raco pkg} 命令识别 @filepath{.plt} 归档作为包安装。@exec{raco setup} 命令（参见 @secref["setup"]）在使用 @Flag{A} 标志时也支持 @filepath{.plt} 解包和安装，但此类安装不能享受 @exec{raco pkg} 更通用的管理功能，而 @exec{raco unpack} 命令（参见 @secref["unpack"]）则本地解包归档而不尝试安装。DrRacket 识别 @filepath{.plt}，目前以与 @exec{raco setup -A} 相同的方式处理此类归档。

归档包含以下元素：

@itemize[

 @item{要解包的一组文件和目录，以及指示它们是相对于 Racket add-on 目录（用户特定）、Racket 安装目录还是用户选定目录解包的标志。

  归档的文件和目录在命令行上提供给 @exec{raco pack}，无论直接提供还是在使用 @DFlag{collect} 标志时以 collection 名称的形式提供。

  @as-index{@DFlag{at-plt}} 标志指示文件和目录应相对于用户的 add-on 目录解包，除非用户在解包时指定 Racket 安装目录。@as-index{@DFlag{collection-plt}} 标志隐含 @DFlag{at-plt}。@as-index{@DFlag{all-users}} 标志覆盖 @DFlag{at-plt}}，指示文件和目录应始终相对于 Racket 安装目录解包。}

 @item{每个文件的一个标志，指示归档解包时是否覆盖现有文件；默认是保留旧文件，但 @as-index{@DFlag{replace}} 标志为归档中的所有文件启用替换。}

 @item{归档解包后要设置（通过 @exec{raco setup}）的 collection 列表；@as-index{@DFlag{setup}} 标志将 collection 名称添加到归档列表中，但 @DFlag{collection-plt} 会自动添加每个 collection。}

 @item{归档的名称，由解包界面向用户报告；@as-index{@DFlag{plt-name}} 标志设置归档名称，但在使用 @DFlag{collect} 时会自动确定默认名称。}

 @item{所需 collection 列表（带关联版本号）和冲突 collection 列表；@exec{raco pack} 命令总是在所需列表中命名 @filepath{racket} collection（使用 collection 的打包时版本），@exec{raco pack} 将每个打包的 collection 命名在冲突列表中（以便 collection 不会解压到不同版本的相同 collection 之上），并且 @exec{raco pack} 在使用 @DFlag{collect} 时从 collection 的 @filepath{info.rkt} 文件中提取其它需求和冲突。}

]

不使用 @DFlag{collect} 时为归档指定单个目录和文件。每个文件和目录必须使用相对路径指定。默认情况下，如果归档使用 DrRacket 解包，将提示用户输入目标目录，而如果 @exec{raco setup} 用于解包归档，文件和目录将相对于当前目录解包。如果提供了 @DFlag{at-plt} 标志，文件和目录将改为相对于用户的 Racket add-on 目录解包。最后，如果提供了 @DFlag{all-users} 标志，文件和目录将改为相对于 Racket 安装目录解包。

使用 @DFlag{collect} 标志打包一个或多个 collection；子 collection 可以在所有平台上使用 @litchar{/} 作为路径分隔符来指定。在此模式下，@exec{raco pack} 自动使用相对于 Racket 安装或 add-on 目录的路径来归档文件，并且 collection 将在解包后设置。此外，@exec{raco pack} 会查询每个 collection 的 @filepath{info.rkt} 文件（如下所述）以确定所需和冲突的 collection 集合。最后，@exec{raco pack} 查询第一个 collection 的 @filepath{info.rkt} 文件以获取归档的默认名称。例如，以下命令创建 @filepath{sirmail.plt} 归档用于分发 @filepath{sirmail} collection：

@commandline{raco pack --collect sirmail.plt sirmail}

打包 collection 时，@exec{raco pack} 检查每个 collection 的 @filepath{info.rkt} 文件的以下字段（参见 @secref["info.rkt"]）：

@itemize[

 @item{@racket[requires] --- 形式为 @racket[(list (list _coll _vers) ...)] 的列表，其中每个 @racket[_coll] 是非空的相对路径字符串列表，每个 @racket[_vers] 是（可能为空的）精确整数列表。所指示的 collection 必须在解包时安装，且版本序列与对应 @racket[_vers] 中指定的版本序列尽可能匹配。

  collection 的版本由其 @filepath{info.rkt} 文件中的 @racket[version] 字段指示，默认版本是空列表。版本序列推广了主要和次要版本号。例如，collection 的 @racket['(2 5 4 7)] 版本可以在需要 @racket['()]、@racket['(2)]、@racket['(2 5)]、@racket['(2 5 4)] 或 @racket['(2 5 4 7)] 时使用。}

 @item{@racket[conflicts] --- 形式为 @racket[(list _coll ...)] 的列表，其中每个 @racket[_coll] 是非空的相对路径字符串列表。所指示的 collection 在解包时@emph{不能}安装。}

]

例如，@sirmail collection 中的 @filepath{info.rkt} 文件可能包含以下 @racket[info] 声明：

@racketmod[
info
(define name "SirMail")
(define mred-launcher-libraries (list "sirmail.rkt"))
(define mred-launcher-names (list "SirMail"))
(define requires (list (list "mred")))
]

然后，@filepath{sirmail.plt} 文件（由上面的命令行示例创建）将包含名称 "SirMail"。归档解包时，解包器将检查 @filepath{mred} collection 是否已安装，以及 @filepath{mred} 是否与 @filepath{sirmail.plt} 创建时具有相同的版本。

@; ------------------------------------------------------------------------

@section[#:tag "format-of-.plt-archives"]{Format of @filepath{.plt} Archives}

@filepath{.plt} 扩展名不是分发归档所必需的，但 @filepath{.plt}-扩展名约定有助于用户识别分发文件的用途。

分发文件的原始格式如下所述。此格式是未压缩的，并且对通信模式（文本与二进制）敏感，因此分发格式通过首先使用 @exec{gzip} 压缩文件，然后使用 MIME base64 标准（仅依赖字符 @litchar{A}-@litchar{Z}、@litchar{a}-@litchar{z}、@litchar{0}-@litchar{9}、@litchar{+}、@litchar{/} 和 @litchar{=}；解码 base64 编码文件时忽略所有其它字符）编码压缩后的文件而从原始格式派生。

原始格式为

@itemize[
  @item{
    @litchar{PLT} 是前三个字符。}

  @item{
    匹配以下模式的 S-expression：

    @racketblock[
                            (lambda (request failure)
                              (case request
                                [(name) _name]
                                [(unpacker) (@#,racket[quote] mzscheme)]
                                [(requires) (@#,racket[quote] _requires)]
                                [(conflicts) (@#,racket[quote] _conflicts)]
                                [(plt-relative?) _plt-relative?]
                                [(plt-home-relative?) _plt-home-relative?]
                                [(test-plt-dirs) _test-dirs]
                                [else (failure)]))
     ]

    其中 @racket[_name]、@racket[_requires] 等元变量表示如下 S-expression：
    
    @itemize[
      @item{
        @racket[_name] --- 描述归档内容的人类可读字符串。此名称仅用于在解包期间向用户打印消息。}

      @item{
        @racket[_requires] --- 解包归档之前必须安装的 collection 列表，带有关联版本；有关详细信息，请参阅 @racket[pack] 的文档。}

     @item{
        @racket[_conflicts] --- 解包归档之前@emph{不能}安装的 collection 列表。}

     @item{
        @racket[_plt-relative?] --- 布尔值；如果为真，则归档内容应相对于 plt add-on 目录解包。}

     @item{
        @racket[_plt-home-relative?] --- 布尔值；如果为真且 @racket['plt-relative?] 为真，则归档内容应相对于 Racket 安装目录解包。}

     @item{
        @racket[_test-plt-dirs] --- @racket[#f] 或 @racket['_paths]，其中 @racket[_paths] 是路径字符串列表；在后一种情况下，如果列表中任何目录（相对于 Racket 安装目录）对用户不可写，则 @racket[_plt-home-relative?] 的真值将被取消。}
   ]

    使用 @racket[read] 从归档中提取 S-expression（结果@emph{不}进行 @racket[eval]）。}

 @item{
   匹配以下模式的 S-expression：

                @racketblock[
                         (unit (import main-collects-parent-dir mzuntar) 
                               (export)
                               (mzuntar void)
                               (@#,racket[quote] _collections))
                 ]

    其中 @racket[_collections] 是 collection 路径列表（每个 collection path 是字符串列表）；归档解包后，@exec{raco setup} 将编译和设置指定的 collection。

     使用 @racket[read] 从归档中提取 S-expression（结果@emph{不}进行 @racket[eval]）。}

]

归档继续包含 @tech{unpackables}。它们被提取直到找到文件结束（由 base64 编码的输入归档中的 @litchar{=} 指示）。

@deftech{unpackable} 是以下之一：

@itemize[
   @item{
     符号 @racket['dir] 后跟一个列表 S-expression。@racket[build-path] 过程将应用于该列表以获取目录的相对路径（相对路径与目标目录路径组合以获取完整路径）。

     使用 @racket[read] 从归档中提取 @racket['dir] 符号和列表（结果@emph{不}进行 @racket[eval]）。}

   @item{
     符号 @racket['file]、一个列表、一个数字、一个星号和文件数据。列表指定文件的相对路径，与目录相同。数字指示要解包的文件大小（以字节为单位）。星号指示文件数据的开始；接下来的 n 个字节写入文件，其中 n 是指定的文件大小。

     使用 @racket[read] 从归档中提取符号、列表和数字（结果@emph{不}进行 @racket[eval]）。读取数字后，输入字符被丢弃直到找到星号。文件数据必须紧跟在此星号之后。}
   
   @item{
     符号 @racket['file-replace] 的处理方式类似于 @racket['file]，但如果文件已存在于磁盘上，则归档中的文件替换磁盘上的文件。}
]

@; ----------------------------------------

@section{打包 API}

@defmodule[setup/pack]{虽然 @exec{raco pack} 命令可用于创建大多数 @filepath{.plt} 文件，但 @racketmodname[setup/pack] 库提供了更通用的 API 用于创建 @filepath{.plt} 归档。}

@defproc[(pack-collections-plt
          (dest path-string?)
          (name string?)
          (collections (listof (listof path-string?)))
          [#:replace? replace? boolean? #f]
          [#:at-plt-home? at-home? boolean? #f]
          [#:test-plt-collects? test? boolean? #t]
          [#:extra-setup-collections collection-list (listof path-string?) null] 
          [#:file-filter filter-proc (path-string? . -> . boolean?) std-filter]) void?]{

  创建由路径名 @racket[dest] 指定的 @filepath{.plt} 文件，使用 @racket[name] 作为报告给 @exec{raco setup} 的归档描述名称。

  归档包含 @racket[collections] 中列出的 collection，该列表应是 collection 路径列表；每个 collection path 又是相对路径字符串列表。

  如果 @racket[#:replace?] 参数为 @racket[#f]，则当任何 collection 已存在时，尝试解包归档将报告错误，否则解包归档将覆盖现有 collection。

  如果 @racket[#:at-plt-home?] 参数为 @racket[#t]，则当主 @filepath{collects} 目录对用户可写时，归档的 collection 将安装到 Racket 安装目录而不是用户的目录。如果 @racket[#:test-plt-collects?] 参数为 @racket[#f]（默认值为 @racket[#t]），且 @racket[#:at-plt-home?] 参数为 @racket[#t]，则当主 @filepath{collects} 目录不可写时安装失败。

  可选的 @racket[#:extra-setup-collections] 参数是不包含但在归档解包时设置的 collection 路径列表。

  可选的 @racket[#:file-filter] 参数与 @racket[pack-plt] 的相同。}

@defproc[(pack-collections
          (dest path-string?)
          (name string?)
          (collections (listof (listof path-string?)))
          (replace? boolean?)
          (extra-setup-collections (listof path-string?))
          [filter (path-string? . -> . boolean?) std-filter]
          [at-plt-home? boolean? #f]) void?]{
@racket[pack-collections-plt] 的旧式无关键字变体，用于向后兼容。

@defproc[(pack-plt
            (dest path-string?)
            (name string?)
            (paths (listof path-string?))
            [#:as-paths as-paths (listof path-string?) paths]
            [#:file-filter filter-proc
                           (path-string? . -> . boolean?) std-filter]
            [#:encode? encode? boolean? #t]
            [#:file-mode file-mode-sym symbol? 'file]
            [#:unpack-unit unpack-spec any/c #f]
            [#:collections collection-list (listof path-string?) null]
            [#:plt-relative? plt-relative? any/c #f]
            [#:at-plt-home? at-plt-home? any/c #f]
            [#:test-plt-dirs dirs (or/c (listof path-string?) #f) #f]
            [#:requires mod-and-version-list
                        (listof (listof path-string?)
                                (listof exact-integer?))
                        null]
            [#:conflicts mod-list
                         (listof (listof path-string?)) null])
         void?]{

  创建由路径名 @racket[dest] 指定的 @filepath{.plt} 文件，使用字符串 @racket[name] 作为报告给 @exec{raco setup} 的归档描述名称。@racket[paths] 参数必须是目录和文件的相对路径列表；这些文件和目录的内容将被打包到归档中。可选的 @racket[as-paths] 列表提供要为 @racket[paths] 的每个元素记录在归档中的路径（以便解包路径可以与打包路径不同）。

  @racket[#:file-filter] 过程被调用每个要打包的候选的相对路径。如果对某些路径返回 @racket[#f]，则该文件或目录从归档中省略。如果对文件返回 @racket['file] 或 @racket['file-replace]，则文件以该模式打包，而非默认模式。默认值是 @racket[std-filter]。
  
  如果 @racket[#:encode?] 参数为 @racket[#f]，则输出归档为原始形式，仍需按顺序进行 gzip 和 mime 编码。默认值为 @racket[#t]。

  @racket[#:file-mode] 参数必须是 @racket['file] 或 @racket['file-replace]，指示归档中文件的默认模式。默认值是 @racket['file]。

  @racket[#:unpack-unit] 参数通常为 @racket[#f]。否则，它必须是描述解包的 S-expression 的 S-expression；有关 unit 的更多信息，请参阅 @secref["format-of-.plt-archives"]。如果 @racket[#:unpack-unit] 参数为 @racket[#f]，则生成适当的 S-expression。

  @racket[#:collections] 参数是归档解包后要编译的 collection 路径列表。默认值为 @racket[null]。

  如果 @racket[#:plt-relative?] 参数为真（默认值为 @racket[#f]），则归档的文件和目录将相对于用户的 add-on 目录或 Racket 安装目录解包，取决于 @racket[#:at-plt-home?] 参数是否为真以及 @racket[#:test-plt-dirs] 指定的目录是否对用户可写。

  如果 @racket[#:at-plt-home?] 参数为真（默认值为 @racket[#f]），则 @racket[#:plt-relative?] 必须为真，且归档相对于 Racket 安装目录解包。在这种情况下，以 @filepath{collects} 开头的相对路径映射到安装的主 @filepath{collects} 目录，以下初始目录名称依此类推：

  @itemize[
     @item{@filepath{collects}}
     @item{@filepath{doc}}
     @item{@filepath{lib}}
     @item{@filepath{include}}
   ]

  如果 @racket[#:test-plt-dirs] 是 @racket[list]，则 @racket[#:at-plt-home?] 必须为 @racket[#t]。在这种情况下，当归档解包时，如果 @racket[#:test-plt-dirs] 列表中的任何相对目录对当前用户不可写，则归档最终在用户的 add-on 目录中解包。

  @racket[#:requires] 参数应具有 @racket[(list (list _coll-path _version) _...)] 的形式，其中每个 @racket[_coll-path] 是非空的相对路径字符串列表，每个 @@racket[_version] 是（可能为空的）精确整数列表。所指示的 collection 必须在解包时安装，且版本序列与对应 @@racket[_version] 中指定的版本序列尽可能匹配。collection 的版本由其 @filepath{info.rkt} 文件的 @racketidfont{version} 字段指示。

  @racket[#:conflicts] 参数应具有 @racket[(list _coll-path _...)] 的形式，其中每个 @racket[_coll-path] 是非空的相对路径字符串列表。所指示的 collection 在解包时@emph{不能}安装。}

@defproc[(pack
          (dest path-string?)
          (name string?)
          (paths (listof path-string?))
          (collections (listof path-string?))
          [filter (path-string? . -> . boolean?) std-filter]
          [encode? boolean? #t]
          [file-mode symbol? 'file]
          [unpack-unit any/c #f]
          [plt-relative? boolean? #t]
          [requires (listof (listof path-string?)
                            (listof exact-integer?)) null]
          [conflicts (listof (listof path-string?)) null]
          [at-plt-home? boolean? #f]) void?]{
@racket[pack-plt] 的旧式无关键字变体，用于向后兼容。

@defproc[(std-filter (p path-string?)) boolean?]{
除非 @racket[p] 在去除目录路径并转换为字节字符串后匹配以下正则表达式之一：@litchar{^[.]git}、@litchar{^[.]svn$}、@litchar{^CVS$}、@litchar{^[.]cvsignore}、@litchar{^compiled$}、@litchar{^doc}、@litchar{~$}、@litchar{^#.*#$}、@litchar{^[.]#} 或 @litchar{[.]plt$}，否则返回 @racket[#t]。

@defproc[(mztar (path path-string?)
                [#:as-path as-path path-string? path]
                (output output-port?)
                (filter (path-string? . -> . boolean?))
                (file-mode (or/c 'file 'file-replace))) void?]{
   Called by @racket[pack] to write one directory/file @racket[path] to the
   output port @racket[output] using the filter procedure @racket[filter]
   (see @racket[pack] for a description of @racket[filter]). The @racket[path]
   is recorded in the output as @racket[as-path], in case the unpacked
   path should be different from the original path. The
   @racket[file-mode] argument specifies the default mode for packing a file,
   either @racket['file] or @racket['file-replace].}
