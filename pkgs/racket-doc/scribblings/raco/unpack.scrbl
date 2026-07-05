#lang scribble/doc
@(require scribble/manual 
          "common.rkt" 
          (for-label racket/base
                     setup/unpack
                     setup/dirs))

@title[#:tag "unpack"]{@exec{raco unpack}: 解包库集合}

@exec{raco unpack} 命令将 @filepath{.plt} 归档解包到当前目录，
而不尝试安装任何集合。使用 @exec{raco pkg}（参见 @other-manual['(lib
"pkg/scribblings/pkg.scrbl")]）将 @filepath{.plt} 归档作为包安装，
或使用 @exec{raco setup -A}（参见 @secref["setup"]）解包并安装
@filepath{.plt} 归档中的集合。

命令行标志：

@itemlist[

 @item{@Flag{l} 或 @DFlag{list} --- 列出归档内容而不解包。}

 @item{@Flag{c} 或 @DFlag{config} --- 在解包或列出归档内容之前显示归档配置。}

 @item{@Flag{f} 或 @DFlag{force} --- 替换已存在的文件；档案表明应替换的文件，
       没有此标志也会被替换。}

]

@; ------------------------------------------------------------------------

@section[#:tag "unpacking-.plt-archives"]{解包 API}

@defmodule[setup/unpack]{@racketmodname[setup/unpack] 库
提供对 @filepath{.plt} 文件解包的底层支持。}

@defproc[(unpack [archive path-string?]
                 [main-collects-parent-dir path-string? (current-directory)]
                 [print-status (string? . -> . any) (lambda (x) (printf "~a\n" x))]
                 [get-target-directory (-> path-string?) (lambda () (current-directory))]
                 [force? any/c #f]
                 [get-target-plt-directory
                  (path-string? 
                   path-string? 
                   (listof path-string?) 
                   . -> . path-string?)
                  (lambda (_preferred-dir _main-dir _options)
                    _preferred-dir)])
         void?]{

解包 @racket[archive]。

@racket[main-collects-parent-dir] 参数被传递给 @racket[get-target-plt-directory]。

@racket[print-status] 参数用于报告解包进度。

@racket[get-target-directory] 参数用于获取归档内容相对于任意目录时解包的目标目录。

如果 @racket[force?] 为真，则版本和所需集合的不匹配（将归档中的信息
与当前安装进行比较）将被忽略。

@racket[get-target-plt-directory] 函数被调用来选择归档（相对于安装）的安装目标。
该函数通常返回其前两个参数之一；第三个参数仅包含前两个参数，
但如果前两个参数相同，则只有一项。如果归档不请求对所有用途进行安装，
则前两个参数将不同，前者将是特定用户位置，而后者将引用主安装。}

@defproc[(fold-plt-archive [archive path-string?]
                           [on-config-fn (any/c any/c . -> . any/c)]
                           [on-setup-unit (any/c input-port? any/c . -> . any/c)]
                           [on-directory ((or/c path-string?
                                                (list/c (or/c 'collects 'doc 'lib 'include)
                                                        path-string?))
                                          any/c 
                                          . -> . any/c)]
                           [on-file (or/c ((or/c path-string?
                                                 (list/c (or/c 'collects 'doc 'lib 'include)
                                                         path-string?))   
                                           input-port? 
                                           any/c 
                                           . -> . any/c)
                                          ((or/c path-string?
                                                 (list/c (or/c 'collects 'doc 'lib 'include)
                                                         path-string?))
                                           input-port? 
                                           (or/c 'file 'file-replace)
                                           any/c 
                                           . -> . any/c))]
                           [initial-value any/c])
         any/c]{

遍历 @racket[archive] 的内容，该归档必须是使用默认解包单元和配置表达式创建的
@filepath{.plt} 归档。不会对配置表达式求值，不会调用解包单元，也不会将文件解包到文件系统。
相反，归档中的信息将通过 @racket[on-config]、@racket[on-setup-unit]、
@racket[on-directory] 和 @racket[on-file] 报告回来，每个函数都可以基于累积值进行构建，
累积值从 @racket[initial-value] 开始，最终值被返回。

@racket[on-config-fn] 函数被调用一次，使用一个 S-expression，
该表达式表示实现配置信息的函数。
@racket[on-config] 的第二个参数是 @racket[initial-value]，
函数的结果被作为最后一个参数传递给 @racket[on-setup-unit]。

@racket[on-setup-unit] 函数被调用时接收安装单元的 S-expression 表示、
指向文件其余部分的 input port 和累积值。此 input port 将与其余处理中使用的端口相同，
因此，如果 @racket[on-setup-unit] 从端口消费了任何数据，
则该数据将不会被其余函数消费。（这意味着 @racket[on-setup-unit] 可能使处理处于不一致的状态，
不被任何内容检查，因此可能导致错误。）@racket[on-setup-unit] 的结果成为新的累积值。

对于在正常解包时将由归档创建的每个目录，@racket[on-directory] 被调用，
参数为目录路径（详见下文）和到该点的累积值，其结果是新的累积值。

对于在正常解包时将由归档创建的每个文件，@racket[on-file] 被调用，
参数为文件路径（详见下文）、包含文件内容的 input port、一个可选的模式符号
（指示文件是否应被替换）以及到该点的累积值；其结果是新的累积值。
input port 可以使用或忽略，解析文件的其余部分无论哪种方式都会相同。
然而，在 @racket[on-file] 返回控制权后，input port 的内容将被排空。

目录或文件路径可以是普通路径，也可以是包含 @racket['collects]、@racket['doc]、
@racket['lib] 或 @racket['include] 和相对路径的列表。
后一种情况对应于相对于目标安装集合目录（@racket[find-collects-dir] 意义下）、
文档目录（@racket[find-doc-dir] 意义下）、库目录（@racket[find-lib-dir] 意义下）
或"include"目录（@racket[find-include-dir] 意义下）的目录或文件。}
