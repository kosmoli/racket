#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "compiler"]{控制和检查编译}

Racket 程序和表达式会自动且即时地编译。@exec{raco make} 工具
（参见 @secref[#:doc raco-doc "make"]）可以将 Racket 模块编译为编译后的
@filepath{.zo} 文件，但那种 ahead-to-time 编译只是让程序启动更快，
并不影响 Racket 程序的性能。

@; ------------------------------------------------------------

@section[#:tag "compiler-modes"]{编译模式}

所有 Racket 变体都支持一种与机器无关的编译模式，该模式生成适用于所有平台上
所有 Racket 变体的编译后 @filepath{.zo} 文件。要选择与机器无关的编译模式，
将 @racket[current-compile-target-machine] parameter 设置为 @racket[#f]，
或在启动时提供 @DFlag{compile-any}/@Flag{M} 标志。
参见 @racket[current-compile-target-machine] 了解更多信息。

其他编译模式取决于 Racket 实现（参见 @secref["implementations"]）。


@subsection[#:tag "3m-compiler-modes"]{BC 编译模式}

Racket 的 @tech{BC} 实现支持两种编译模式：bytecode 和 machine-independent。
bytecode 格式也是机器无关的，因为它在所有操作系统上对 Racket 的 BC 实现
工作方式相同，但它不适用于 Racket 的 CS 实现。除非禁用 JIT 编译器，
否则 bytecode 会在运行时被进一步编译为机器码。参见 @racket[eval-jit-enabled]。


@subsection[#:tag "cs-compiler-modes"]{CS 编译模式}

Racket 的 @tech{CS} 实现支持几种编译模式：machine code、machine-independent、
interpreted 和 JIT。Machine code 是主要模式，machine-independent 模式与 BC 的
相同。Interpreted 模式在核心 @tech{linklet} 形式层面使用解释器而不进行编译。
JIT 模式触发对各个函数形式的按需编译。

默认模式是 machine-code 和 interpreter 模式的混合，其中 interpreter 模式
仅用于特别大的 linklet 的外层轮廓，而 machine-code 模式用于该外层轮廓内足够小的函数。
"足够小" 由 @envvar-indexed{PLT_CS_COMPILE_LIMIT} 环境变量决定，
其默认值 10000 意味着大多数 Racket 模块没有 interpreted 组件。
@racket[#:unlimited-compile] 选项（用于 @racket[#%declare]）可禁用
enclosing module 的 interpreted 模式。在 @racket['linklet] 主题下设置
@racket['info] 日志记录（例如，将 @envvar{PLTSTDERR} 设置为 @tt["info@linklet"]），
以了解何时因 @envvar{PLT_CS_COMPILE_LIMIT} 而将编译限制为较小的函数。

JIT 编译模式仅在启动时设置了 @envvar-indexed{PLT_CS_JIT} 环境变量时使用，
否则仅当设置了 @envvar-indexed{PLT_CS_INTERP} 环境变量时使用纯 interpreter 模式，
当设置了 @envvar-indexed{PLT_CS_MACH} 且未设置 @envvar{PLT_CS_JIT} 时使用
machine code 和 interpreter 混合模式，或者未设置任何环境变量时。
任何模式下编译的模块都可以加载到 Racket 的 CS 变体中，
与当前编译模式无关。

@envvar{PLT_CS_DEBUG} 环境变量（如 @secref["debugging"] 中所述）
仅影响 machine-code 模式的编译。当启用 @envvar{PLT_CS_DEBUG} 时，
生成的 machine code 会大得多，但性能不受其他影响。

@; ------------------------------------------------------------

@section[#:tag "compiler-inspect"]{检查编译器阶段}

当在启动时设置了 @envvar-indexed{PLT_LINKLET_SHOW} 环境变量时，
Racket process 的标准错误会在 Racket 形式编译时显示中间编译形式。
对于所有 Racket 变体，输出显示从原始 Racket 形式生成的一个或多个 @tech{linklets}。

对于 Racket 的 @tech{CS} 实现，还会显示 linklet 的"schemified"版本，
作为 @racket[linklet] 形式到 Chez Scheme procedure 形式的转换。
输出还会显示编译器正在处理哪些模块和 linklets。

以下环境变量隐含 @envvar{PLT_LINKLET_SHOW} 并显示额外的中间编译形式
或调整形式的显示方式：

@itemlist[

  @item{@envvar-indexed{PLT_LINKLET_SHOW_GENSYM} --- 打印完整的生成名称
        而不是缩写；默认行为对应于 Chez Scheme 的 @tt{'pretty/suffix} 模式
        （用于 @tt{print-gensym}）}

   @item{@envvar-indexed{PLT_LINKLET_SHOW_PRE_JIT} --- 在转换为 JIT 模式之前的
         schemified 形式，仅在设置了 @envvar{PLT_CS_JIT} 时适用}

   @item{@envvar-indexed{PLT_LINKLET_SHOW_LAMBDA} --- 显示在具有 interpreted 外层轮廓的
         较大形式中编译的各个 schemified 形式}

   @item{@envvar-indexed{PLT_LINKLET_SHOW_POST_LAMBDA} --- 在编译内部各个形式后显示
         外部形式}

   @item{@envvar-indexed{PLT_LINKLET_SHOW_POST_INTERP} --- 在转换为可解释形式后显示
         外部形式}

   @item{@envvar-indexed{PLT_LINKLET_SHOW_JIT_DEMAND} --- 显示由设置了 @envvar{PLT_CS_JIT} 的编译
         预先准备的形式的 JIT 编译}

   @item{@envvar-indexed{PLT_LINKLET_SHOW_KNOWN} --- 在 schemified 形式旁边显示
         记录的 known-binding 信息}

   @item{@envvar-indexed{PLT_LINKLET_SHOW_CP0} --- 在转换为由 Chez Scheme 的 front-end optimizer
         处理后的 schemified 形式}

   @item{@envvar-indexed{PLT_LINKLET_SHOW_PASSES} --- 显示 schemified linklet
         在 Chez Scheme 的内部表示中经过指定阶段（以空格分隔列出）后的中间形式；
         使用特殊名称 @tt{all} 将在所有 Chez Scheme 阶段后的中间形式}

   @item{@envvar-indexed{PLT_LINKLET_SHOW_ASSEMBLY} --- 以 Chez Scheme 的机器指令抽象
         显示 schemified linklet 的编译形式}

]

当在启动时设置了 @envvar-indexed{PLT_LINKLET_TIMES} 环境变量时，
Racket 会在退出时打印编译和求值时间的累计时间信息。
当设置了 @envvar-indexed{PLT_EXPANDER_TIMES} 环境变量时，
会在退出时打印关于 macro-expansion 时间的信息。

@history[#:changed "8.8.0.10" @elem{为 @envvar{PLT_LINKLET_SHOW_PASSES} 添加了特殊阶段名称 @tt{all}。}
         #:changed "8.11.1.2" @elem{在输出中添加了模块和 linklet 信息。}]
