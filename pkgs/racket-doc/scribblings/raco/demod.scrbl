#lang scribble/doc
@(require scribble/manual scribble/bnf "common.rkt"
          (for-label (except-in racket/base #%module-begin)
                     compiler/demod
                     racket/include
                     syntax/parse))

@title[#:tag "demod"]{@exec{raco demod}: 反模块化程序}

@declare-exporting[compiler/demodularizer/main]

@exec{raco demodularize} 命令（通常使用简写形式
@exec{raco demod}）接受一个 Racket 模块，并将其依赖项
扁平化为单个编译模块，可能包含子模块。文件
@filepath{@nonterm{name}.rkt} 被反模块化为
@filepath{@nonterm{name}_rkt_merged.zo}。

参见 @racketmodname[compiler/demod] 了解使用反模块化器的
另一种方式。使用 @racket[@#,hash-lang[] @#,racketmodname[compiler/demod]]
可以与 @seclink["make"]{@exec{raco make}} 和
@seclink["setup"]{@exec{raco setup}} 等工具协作，
这对库模块（相对于最终用户程序）尤为重要。

在默认配置下，@exec{raco demod} 支持扁平化表示最终用户程序的
模块，因此会丢弃该模块及其依赖项中的所有语法和编译时
支持。子模块会被保留，但其语法和编译时支持同样会被
丢弃。反模块化后的 @filepath{.zo} 文件可以作为参数传递给
@exec{racket} 命令行程序来运行，也可以通过
@seclink["exe"]{@exec{raco exe}} 转换为可执行文件。

提供 @Flag{s} 或 @DFlag{syntax} 标志可以保留模块的
语法和编译时组件，使其能够像原始模块一样被
@racket[require]。在这种情况下，其实例需要与其他库共享的
模块应使用 @Flag{x} 或 @DFlag{exclude-library} 从反模块化中
排除。例如，通常需要 @exec{-x racket/base}。

反模块化器生成的大型单模块在编译时如同指定了
@racket[(#%declare #:unlimited-compile)] 一样，因此
@envvar{PLT_CS_COMPILE_LIMIT} 环境变量的值不会限制
该模块的编译。

@exec{raco demod} 命令接受以下标志：

@itemlist[

 @item{@Flag{o} @nonterm{file} --- 将扁平化模块写入
       @nonterm{file}，而非
       @filepath{@nonterm{name}_@nonterm{ext}_merged.zo}，
       其中输入文件为 @filepath{@nonterm{name}.@nonterm{ext}}。}

 @item{@Flag{x} @nonterm{module-path} 或 @DFlag{exclude-library} @nonterm{module-path} ---
       将 @nonterm{module-path} 中的模块及其所有依赖项从
       扁平化中排除。如果 @nonterm{module-path} 不是输入模块的
       依赖项，且其没有任何子模块是依赖项，则报告错误。}

 @item{@Flag{e} @nonterm{path} 或 @DFlag{exclude-module} @nonterm{path} ---
       将相对文件 @nonterm{path} 中的模块及其所有依赖项从
       扁平化中排除。如果 @nonterm{path} 不是输入模块的
       依赖项，且其没有任何子模块是依赖项，则报告错误。
       为向后兼容，@DFlag{exclude-modules} 是 @DFlag{exclude-module}
       的别名。}

 @item{@Flag{s} 或 @DFlag{syntax} --- 在扁平化结果中保留语法对象
       和大于运行时的相位级别。否则，仅保留运行时相位，
       未使用（或仅导出）的定义将被裁剪，因为它们无法通过
       语法引用。}

 @item{@Flag{M} 或 @DFlag{compile-any} --- 将模块扁平化为
       机器无关形式，而非将扁平化模块重新编译为当前平台
       和 Racket 虚拟机；使用 @Flag{M} 生成的输出比机器特定
       形式加载更慢，但 @seclink["decompile"]{@exec{raco
       decompile}} 可以以更接近源码的格式显示扁平化模块。
       另参见 @DFlag{dump-mi}。}

 @item{@Flag{r} 或 @DFlag{recompile} --- 在扁平化后将模块
        （重新）编译为机器相关形式；此模式为默认模式。}

 @item{@DFlag{work} @nonterm{dir} --- 使用 @nonterm{dir} 以中间形式
       缓存编译后的模块以供扁平化使用；在多次使用
       @exec{raco demod} 时使用相同的 @nonterm{dir} 作为
       @DFlag{work} 参数可以极大加速反模块化，并且由于缓存基于
       @exec{raco make}，即使输入文件不同或待扁平化模块自
       上次缓存使用以来已更改，缓存仍然有效。}

 @item{@Flag{g} 或 @DFlag{prune-definitions} --- 增加对未引用定义的
       裁剪，其不健全假设是定义的右侧没有副作用。
       当保留语法时，只要没有任何语法字面量包含绑定到该定义
       的标识符，就可以裁剪该定义。由于这些假设未经检查，
       转换可能无法保留输入模块的行为。为向后兼容，
       @DFlag{garbage-collect} 是 @DFlag{prune-definitions} 的
       别名。}

 @item{@DFlag{dump} @nonterm{file} --- 将模块内容的 S-表达式表示
       写入 @nonterm{file}，这有助于理解编译后扁平化模块
       中的内容。}

 @item{@DFlag{dump-mi} @nonterm{file} --- 将扁平化模块的机器无关形式
       写入 @nonterm{file}，与 @Flag{M} 写入的内容相同，
       但在未使用 @Flag{M} 时很有用。}

]

除了保留源模块的子模块外，反模块化可能会引入新的子模块
来容纳扁平化内容的部分。引入的子模块名称以
@racketidfont{demod-pane-} 为前缀，后跟一个整数。

@history[#:changed "1.10" @elem{Added @Flag{M}/@DFlag{compile-any},
                                @DFlag{work}, and support for Racket CS.}
         #:changed "1.15" @elem{Added @Flag{x}/@DFlag{exclude-library},
                                @Flag{s}/@DFlag{syntax}, @DFlag{dump},
                                @DFlag{dump-mi}, @DFlag{prune-definitions}
                                (as a new name for @DFlag{garbage-collect}),
                                and preservation of submodules.}
         #:changed "1.16" @elem{Changed to reporting an error when a module
                                named by @Flag{x} or @Flag{e} is not a
                                dependency of the input module.}]

@section[#:tag "lib-demod"]{反模块化库}

使用 @racketmodname[compiler/demod] 对库模块进行反模块化
可能会创建一个含义与原始模块不同的模块，因为未被指定为
排除的传递依赖项会被复制到扁平化模块中。这种复制可能会
破坏生成的结构类型或绑定所需的共享。作为具体示例，
@racketmodname[racket/base] 的独立副本将具有互不兼容的
过程关键字参数实现。

为避免问题，一个好的通用扁平化策略是

@itemlist[

 @item{将所有待扁平化模块放入 @filepath{private/amalgam}
         子集合中，其中 @filepath{private/amalgam} 内的模块可以
         自由相互引用；}

 @item{创建模块 @filepath{private/amalgam-src.rkt}，它
        需要从 @filepath{private/amalgam} 中引入需要从外部
        访问的模块，其中 @filepath{private/amalgam-src.rkt}
        中的子模块可以提供 @filepath{private/amalgam} 中绑定
        的不同子集；}

 @item{create a module @filepath{mine/private/amalgam.rkt} as

       @racketmod[
         @#,racketmodname[compiler/demod]
         "amalgam-src.rkt"
         #:include (#:dir "amalgam")
       ]

       and}

 @item{从 @filepath{private/amalgam} 外部，仅使用
       @filepath{private/amalgam.rkt}，可能通过从
       @filepath{private/amalgam.rkt} 重新提供的公共模块。}

]

@section[#:tag "lang-demod"]{反模块化语言}

@defmodulelang[compiler/demod]

使用 @racketmodname[compiler/demod] 语言的模块会编译为源模块
扁平化（与 @seclink["demod"]{@exec{raco demod}} 相同意义上的）
版本。另参见 @secref["lib-demod"]。

@racket[@#,hash-lang[] @#,racketmodname[compiler/demod]] 模块体
以要扁平化的 @racket[_module-path] 开头，后跟选项：

@defsubform[#:link-target? #f
            #:id module-begin
            (code:line module-path
                       option
                       ...)
            #:grammar ([option mode
                               (code:line #:include (mod-spec ...))
                               (code:line #:exclude (mod-spec ...))
                               (code:line #:submodule-include (submod-spec ...))
                               (code:line #:submodule-exclude (submod-spec ...))
                               #:prune-definitions
                               (code:line #:dump file)
                               (code:line #:dump-mi file)
                               #:no-demod]
                       [mode #:exe
                             #:dynamic
                             #:static]
                       [mod-spec (code:line #:module module-path)
                                 (code:line #:dir dir-path)
                                 (code:line #:collect collect-name)]
                       [submod-spec identifier
                                    (identifier ...)])]

默认 @racket[_mode] 为 @racket[#:dynamic]，它保留语法对象和
编译时支持（如宏），但不强制将所有模块复制到扁平化模块中。
例如，如果一个模块被 @racket[_module-path] 内子模块的某种
组合引用，且没有其他模块被同一组合到达，则将该模块复制到
子模块中的益处有限。@racket[#:static] 模式类似于
@racket[#:dynamic]，但它确保所有模块都被包含，除非被指定为
排除。@racket[#:exe] 模式丢弃语法和编译时支持，因此可能
适合扁平化实现最终用户程序的模块。

当指定 @racket[#:include] 选项时，只有 @racket[_mod-spec]
覆盖的模块才会被包含在扁平化形式中；否则，所有模块都是
候选包含项。当指定 @racket[#:exclude] 选项时，
@racket[_mod-spec] 覆盖的模块将被排除，即使它们根据
@racket[#:include] 规范本应被包含。换句话说，
@racket[#:exclude] 在 @racket[#:include] 之后应用。
每个 @racket[_mod-spec] 必须通过文件系统或基于集合的路径
命名模块，且不能命名子模块；被命名模块的任何子模块都会被
隐式包含或排除。如果 @racket[#:include] 或 @racket[#:exclude]
列表中的 @racket[_mod-spec] 不是 @racket[module-path] 的
依赖项（且没有任何子模块是依赖项），则会引发异常。

@racket[#:submodule-include] 和 @racket[#:submodule-exclude]
规范类似于 @racket[#:include] 和 @racket[#:exclude]，
但针对的是 @racket[_module-path] 的直接子模块。如果
@racket[_mode] 为 @racket[#:exe]，则包含列表默认为
@racketidfont{main} 和 @racketidfont{configure-runtime}，
否则默认没有特定包含项。

@racket[_mod-spec] 可以通过 @racket[#:module] 指定特定模块，
或通过 @racket[#:collect] 指定给定集合（及其子集合）中的所有
模块。@racket[_collect-name] 始终是一个由 @litchar{/} 分隔
组件构成的字符串。

如果指定了 @racket[#:prune-definitions] 选项，则原始模块及其
依赖项中未使用的定义会被更积极地裁剪，但这是不健全的。当为
@racket[#:dynamic] 或 @racket[#:static] 模式保留语法时，
原始模块中的所有定义通常都会被保留，因为它们可能通过
@racket[datum->syntax] 可达；当指定 @racket[#:prune-definitions]
时，如果没有任何语法对象字面量包含绑定到该定义的标识符，
则可以裁剪该定义。同时，在包括 @racket[#:exe] 在内的所有
模式中，如果定义的右侧可能有副作用，则该定义通常会被保留，
但 @racket[#:prune-definitions] 允许基于定义无副作用的未经检查
假设进行裁剪。由于其假设未经检查，@racket[#:prune-definitions]
可能无法保留输入模块的行为。@margin-note*{作为
@racket[#:prune-definitions] 可能出错的示例，模块可能导出一个
展开为 @racket[syntax-parse] 用法的宏，该用法可能包含
@litchar{:} 简写形式，将模式变量和语法类（也在模块中定义）
组合为一个标识符。该标识符仅在使用宏时才会被拆分为变量和
语法类组件，因此该简写形式不计为绑定到语法类的字面量。在
该特定情况下，使用 @racket[~var] 代替简写形式，然后语法类
通过其自身标识符被引用。同时，未导出的宏（直接或间接通过
另一个宏导出）可以安全使用 @litchar{:} 简写形式，因为其
展开是模块实现的一部分。}

如果指定了 @racket[#:no-demod] 选项，则 @racket[_mod-spec]
最终不会被扁平化。相反，新模块会 @racket[require] 并重新
@racket[provide] @racket[_mod-spec] 及其每个子模块。当
@racketmodname[compiler/demod] 模块被展开时，始终使用此模式，
因为展开必须产生语法而非编译后的模块。此模式在开发期间
也可能有用，可避免扁平化带来的更长编译时间，或检查为
扁平化而复制模块是否会产生任何问题。

使用 @racketmodname[compiler/demod] 的扁平化模块对原始模块
具有构建依赖，因此 @seclink["make"]{@exec{raco make}} 或
@seclink["setup"]{@exec{raco setup}} 等工具在源模块更改时会
触发重新扁平化，但扁平化模块对原始模块没有运行时或展开时
依赖。通过 @racket[#:include] 和 @racket[#:exclude] 从扁平化中
排除的模块仍作为扁平化模块的运行时和展开时依赖。在默认的
@racket[#:dynamic] 模式下，可能会为无法有效合并的模块保留
额外的依赖，但 @racket[#:static] 或 @racket[#:exe] 模式会将
这些模块也复制到新的子模块中。

@racketmodname[compiler/demod] 模块的编译和展开会在与模块
相同的目录中创建 @filepath{compiled/ephemeral/demod} 子目录。
该子目录以适合反模块化的形式保存扁平化模块所有依赖项的
新编译版本。此额外编译使用 @racketmodname[compiler/cm] 管理，
因此依赖项的更改可以增量处理，但仍与依赖项的正常编译
分离。检测 @racketmodname[compiler/demod] 模块的编译是否为
最新不依赖于 @filepath{compiled/ephemeral/demod} 子目录，
因此编译后可以安全丢弃。

@history[#:added "1.15"
         #:changed "1.16" @elem{Changed to raising an exception when a module
                                listed in @racket[#:include] or @racket[#:iexclude] is not a
                                dependency of @racket[module-path].}]
