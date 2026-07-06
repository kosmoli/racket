#lang scribble/doc
@(require scribble/manual
          scribble/bnf
          "common.rkt" 
          (for-label racket/base
                     racket/runtime-path
                     compiler/embed
                     launcher/launcher))

@(define (gtech s) (tech #:doc guide-doc s))

@title[#:tag "exe"]{@exec{raco exe}：创建独立可执行文件}

@margin-note{为实现更快的启动时间，不要尝试 @exec{raco exe}，
而是使用更小的基础语言——例如用 @racketmodfont{#lang} @racketmodname[racket/base] 替代
@racketmodfont{#lang} @racketmodname[racket]。同时，确保通过使用 @seclink["make"]{@exec{raco make}} 来编译 bytecode 文件。
要进一步改进，请尝试使用 @seclink["demod"]{@exec{raco demod}}。}

@exec{raco make} 生成的编译代码依赖 Racket 可执行文件来为编译代码提供运行时支持。
然而，@exec{raco exe} 可以将代码与其运行时支持打包在一起形成可执行文件，
并且 @seclink["exe-dist"]{@exec{raco distribute}} 可以将可执行文件打包成
可在其他机器上运行的发行版。运行 @exec{raco exe} 生成的可执行文件
相比 @exec{raco make} 不会提高性能。

@exec{raco exe} 命令将模块（从源码或字节码）嵌入到 @exec{racket} 可执行文件的副本中。
（在 Unix 上，嵌入的可执行文件实际上是 wrapper 可执行文件的副本。）
创建的可执行文件在启动时调用嵌入的模块。
@DFlag{gui} 标志使程序嵌入到 @exec{gracket} 可执行文件的副本中。
如果嵌入的模块通过 @racket[require] 引用其他模块，则其他模块也会被包含在嵌入的可执行文件中。

例如，命令

@commandline{raco exe --gui hello.rkt}

生成 @filepath{hello.exe}（Windows）、@filepath{hello.app}
（Mac OS）或 @filepath{hello}（Unix），其运行效果与在 @exec{gracket} 中运行
@filepath{hello.rkt} 模块相同。

被动态引用的库模块或其他文件——通过 @racket[eval]、@racket[load] 或
@racket[dynamic-require]——不会自动嵌入到创建的可执行文件中。
此类模块可以使用 @exec{raco exe} 的 @DPFlag{lib} 标志显式包含。
或者，使用 @racket[define-runtime-path] 在可执行文件中嵌入对运行时文件的引用；
然后在创建发行版时，这些文件会被复制并与可执行文件打包在一起
（如 @secref["exe-dist"] 中所述）。如果封闭模块被包含且子模块包含名为
@racketidfont{declare-preserve-for-embedding} 的子子模块
（子子模块的实现被忽略），则该子模块会被包含。

仅通过 @hash-lang[] 使用的语言读取器模块也不会自动嵌入。
为了支持 @hash-lang[] 与语言规范的动态使用，请向 @exec{raco exe} 提供 @DPFlag{lang} 标志。
@DPFlag{lang} 之后的参数可以是语言名称，但更一般地，它可以是紧跟在 @hash-lang[] 之后的文本。
例如，@litchar{at-exp racket/base} 作为 @DPFlag{lang} 的参数是合理的，
以支持将 @racketmodname[at-exp] 与 @racketmodname[racket/base] 组合用作动态加载模块的语言。

由扩展直接实现的模块——即从 @racket[(build-path "compiled"
"native" (system-library-subpath))] 自动加载以满足 @racket[require] 的扩展——
被视为其他运行时文件：生成的可执行文件从它们的原始位置使用它们，
并且在创建发行版时它们会被复制并打包在一起。

当模块嵌入到可执行文件中时，它会获得一个符号名称而不是其原始基于文件系统的名称。
模块名称解析器在嵌入的可执行文件中被配置为将基于 collection 的模块路径映射到嵌入的符号名称，
但不会为文件系统路径创建此类映射。默认情况下，模块的符号名称以未指定但确定性的方式生成，
名称以 @as-index{@litchar{#%embedded:}} 开头，除了主模块以 @litchar{#%mzc:} 为前缀。
模块名称缺乏明确规范可能对对模块名称敏感的语言构造造成问题，例如序列化。
要更好地控制模块的符号名称，请使用 @DPFlag{named-lib} 或 @DPFlag{named-file} 参数
来指定在模块基本名称之前附加的前缀，以生成符号名称。

@exec{raco exe} 命令仅适用于基于模块的程序。
@racketmodname[compiler/embed] 库提供了对嵌入机制的更通用接口。

独立可执行文件在以下意义上是"独立"的：你可以运行它而无需启动 @exec{racket}、@exec{gracket} 或 DrRacket。
然而，可执行文件可能依赖于 Racket 共享库以及可能通过 @racket[define-runtime-path] 声明的其他运行时文件。
在 Windows 上使用 @DFlag{embed-dlls} 或在 Unix 上使用 @DFlag{orig-exe} 可能会生成比其他方式更独立的可执行文件。
构建 Racket 本身时使用的选项会影响可执行文件的独立程度。
@margin-note*{标准发行版使用使可执行文件尽可能独立的选项。
对于 Unix 构建，使用 @DFlag{enable-shared} 进行配置会使可执行文件独立性降低。
对于 Mac OS 构建，不使用 @DFlag{enable-embedfw} 进行配置会使非 GUI 可执行文件独立性降低。}
无论如何，可执行文件可以与支持库打包在一起，使用 @exec{raco distribute} 创建自包含的发行版，
如 @secref["exe-dist"] 中所述。

@exec{raco exe} 命令接受以下命令行标志：

@itemlist[

 @item{@Flag{o} @nonterm{file} —— 将可执行文件创建为 @nonterm{file}，
   根据平台和可执行文件类型适当地为 @nonterm{file} 添加后缀。
   在 Mac OS 上的 @DFlag{gui} 模式下，@nonterm{file} 实际上是一个 bundle 目录，
   但在 Finder 中显示为文件。}

 @item{@DFlag{gui} —— 基于 @exec{gracket} 而不是 @exec{racket} 创建图形可执行文件。}

 @item{@Flag{l} 或 @DFlag{launcher} —— 创建 @tech{launcher}（参见
   @secref["launcher"]），而不是独立可执行文件。诸如 @DFlag{config-path}、
   @DFlag{collects-path} 和 @DFlag{lib} 等标志对 launcher 没有影响。
   注意，构建到 launcher 中的默认命令行标志会阻止访问在用户 scope 中安装的包；
   使用 @exec{--exf -U} 来启用从 launcher 访问用户 scope 的包。}

 @item{@DFlag{embed-dlls} —— 在 Windows 上，对于独立可执行文件，
   将任何需要的 DLL 复制到可执行文件中。嵌入 DLL 使生成的可执行文件真正独立，
   如果它不依赖于其他外部文件的话。并非所有 DLL 都支持嵌入，
   限制主要与线程本地存储和资源有关，但主 Racket 发行版中的所有 DLL
   都支持 @DFlag{embed-dlls}。}

 @item{@DFlag{config-path} @nonterm{path} —— 在可执行文件内设置 @nonterm{path}
   作为 @tech{配置目录}的路径；如果路径是相对的，则视为相对于可执行文件。
   默认路径是 @filepath{etc}，预期在运行时不会存在这样的目录。}

 @item{@DFlag{collects-path} @nonterm{path} —— 在可执行文件内设置 @nonterm{path}
   作为 @tech{主 collection 目录}的路径；如果路径是相对的，则视为相对于可执行文件。
   默认是没有路径，这意味着 @racket[current-library-collection-paths] 和
   @racket[current-library-collection-links] 参数在可执行文件启动时
   被初始化为 @racket[null]。注意，默认情况下各种其他目录位于相对于
   @tech{主 collection 目录}的位置（参见 @secref["config-file"]），
   因此安装 @nonterm{path} 可能允许找到其他目录——无论是有意还是无意的。}

 @item{@DFlag{collects-dest} @nonterm{path} —— 将要与可执行文件一起包含的模块
   写入 @nonterm{path}（相对于当前目录），而不是嵌入到可执行文件内。
   @DFlag{collects-dest} 标志通常仅在与 @DFlag{collects-path} 组合使用时才有意义。
   此模式当前不修剪未引用的子模块（并且它会拉入子模块的任何依赖项）。}

 @item{@DFlag{ico} @nonterm{.ico-path} —— 在 Windows 上，将生成的可执行文件的图标
   设置为从 @nonterm{.ico-path} 提取的图标；有关预期图标大小和转换的更多信息，
   请参见 @racket[create-embedding-executable] 对 @racket['ico] 辅助关联的使用。}

 @item{@DFlag{icns} @nonterm{.icns-path} —— 在 Mac OS 上，将生成的可执行文件的图标
   设置为 @nonterm{.icns-path} 的内容。}

 @item{@DFlag{orig-exe} —— 在 Unix 上，基于原始 @exec{racket} 或 @exec{gracket}
   可执行文件生成可执行文件，而不是重定向到原始文件的 wrapper 可执行文件。
   如果原始可执行文件静态链接到 Racket 运行时库，则生成的可执行文件同样独立。
   注意，如果原始可执行文件将 Racket 作为共享库链接，则 @exec{raco distribute}
   无法处理使用 @DFlag{orig-exe} 创建的可执行文件（因为 wrapper 可执行文件
   通常在将可执行文件分发到不同机器时负责查找共享库）。}

 @item{@DFlag{cs} —— 基于 Racket 的 @gtech{CS} 实现生成可执行文件，
   这是默认设置，除非运行基于 @gtech{BC} 实现的 @exec{raco exe}。}

 @item{@DFlag{3m} —— 基于 Racket 的 @gtech{3m} 变体生成可执行文件，
   仅当运行基于 @gtech{BC} 实现的 @gtech{3m} 变体的 @exec{raco exe} 时才是默认设置。}

 @item{@DFlag{cgc} —— 基于 Racket 的 @gtech{CGC} 变体生成可执行文件，
   仅当运行基于 @gtech{BC} 实现的 @gtech{CGC} 变体的 @exec{raco exe} 时才是默认设置。}

 @item{@DPFlag{aux} @nonterm{file} —— 基于 @nonterm{file} 的后缀将信息附加到可执行文件；
   有关已识别后缀和含义的列表，请参见 @racket[extract-aux-from-path]，
   有关每种文件如何使用的更具体信息，请参见 @racket[create-embedding-executable]
   对辅助关联的使用。}

 @item{@DPFlag{lib} @nonterm{module-path} —— 将 @nonterm{module-path} 包含在可执行文件中，
   即使它未被主程序引用，以便它可以通过 @racket[dynamic-require] 使用。}

 @item{@DPFlag{lang} @nonterm{lang} —— 包含加载以 @racket[@#,hash-lang[] @#,nonterm{lang}]
   开头的模块所需的模块。@nonterm{lang} 不必是纯语言或模块名称；
   它可以是更一般的文本序列，例如 @litchar{at-exp racket/base} 以支持
   像 @racketmodname[at-exp] 这样的语言构造器。
   以 @nonterm{lang} 读取的 @racket[module] 的初始 @racket[require]
   必须通过语言读取器的 @racketidfont{get-info} 函数和 @racket['module-language]
   键可用；使用 @racketmodname[syntax/module-reader] 实现的语言自动支持该键。}

 @item{@DPFlag{named-lib} @nonterm{prefix} @nonterm{module-path} ——
   类似于 @DPFlag{lib}，但嵌入模块的符号名称被指定为 @nonterm{prefix}
   附加在库文件基本名称之前。指定模块的符号名称对于依赖模块名称的语言构造很有用，
   例如序列化格式（其中模块名称被记录以便稍后可以找到函数进行反序列化）。}

 @item{@DPFlag{named-file} @nonterm{prefix} @nonterm{file-path} ——
   将 @nonterm{file-path} 包含在可执行文件中，即使它未被主程序引用，
   并使用 @nonterm{prefix} 附加在文件基本名称之前作为嵌入模块的符号名称。
   由于嵌入模块的符号名称是可预测的，该模块可能在运行时通过 @racket[dynamic-require] 访问。
   可预测的模块名称也可以以与 @DPFlag{named-lib} 相同的方式帮助处理序列化数据。}

 @item{@DPFlag{exf} @nonterm{flag} —— 在启动时将 @nonterm{flag} 命令行参数
   提供给嵌入的 @exec{racket} 或 @exec{gracket}。}

 @item{@DFlag{exf} @nonterm{flag} —— 从要提供给嵌入的 @exec{racket} 或 @exec{gracket}
   的启动命令行参数中移除 @nonterm{flag}。}

 @item{@DFlag{exf-clear} —— 移除所有要提供给嵌入的 @exec{racket} 或 @exec{gracket}
   的启动命令行参数。}

 @item{@DFlag{exf-show} —— 显示（不更改）要提供给嵌入的 @exec{racket} 或 @exec{gracket}
   的启动命令行参数。}

 @item{@Flag{v} —— 详细报告进度。}

 @item{@DFlag{vv} —— 比 @Flag{v} 更详细地报告进度。}

]

@history[#:changed "6.3.0.11" @elem{添加了对 @racketidfont{declare-preserve-for-embedding} 的支持。}
         #:changed "6.90.0.23" @elem{添加了 @DFlag{embed-dlls}。}
         #:changed "7.0.0.17" @elem{添加了 @DPFlag{lang}。}
         #:changed "7.3.0.6" @elem{添加了 @DPFlag{named-lib} 和 @DPFlag{named-file}，
                                   并更改了嵌入模块的符号名称生成方式以使其确定性。}]

@; ----------------------------------------------------------------------

@include-section["exe-api.scrbl"]
@include-section["launcher.scrbl"]
@include-section["exe-dylib-path.scrbl"]
