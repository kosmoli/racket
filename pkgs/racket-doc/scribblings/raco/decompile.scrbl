#lang scribble/doc
@(require scribble/manual
          scribble/bnf
          scribble/core
          "common.rkt"
          (for-label racket/base
                     racket/contract/base
                     compiler/decompile
                     (only-in compiler/zo-parse linkl-directory? linkl-bundle? linkl?)
                     compiler/zo-marshal
                     compiler/faslable-correlated
                     racket/linklet))

@title[#:tag "decompile"]{@exec{raco decompile}: Decompiling Bytecode}

@exec{raco decompile} 命令接收字节码文件路径（通常扩展名为 @filepath{.zo}）
或带有关联字节码文件的源文件（通常使用 @exec{raco make} 创建），
并将字节码内容转换回近似的 Racket 代码。
如果 ``字节码'' 文件包含机器码（如 Racket 的 @tech[#:doc guide-doc]{CS} 变体），
则无法转换回近似 Racket，但安装 @filepath{disassemble} 包可以启用机器码反汇编。
反编译主要用于检查编译器对源程序的转换和优化。

@exec{raco decompile} 命令接受以下命令行标志：

@itemlist[
  @item{@DFlag{force} --- 跳过给定文件路径与关联 @filepath{.zo} 文件（如有）的修改日期比较}
  @item{@Flag{n} @nonterm{n} 或 @DFlag{columns} @nonterm{n} --- 格式化输出来适配 @nonterm{n} 列宽}
  @item{@DFlag{linklet} --- 仅反编译到 @tech[#:doc reference-doc]{linklets}，而不是将 linklets 解码为近似的 Racket @racket[module] 形式}
  @item{@DFlag{no-disassemble} --- 按原样以字节字符串显示机器码，而不是尝试反汇编}
  @item{@DFlag{no-syntax} --- 避免反编译 syntax-object 字面值}
  @item{@DFlag{partial-fasl} --- 保留更多字节码文件的原始结构，而不是只关注过程体}
]

@history[#:changed "1.8" @elem{Added @DFlag{no-disassemble}.}
         #:changed "1.9" @elem{Added @DFlag{partial-fasl}.}
         #:changed "1.17" @elem{Added @DFlag{no-syntax}.}]

@section{Racket CS Decompilation}

Racket CS 字节码的反编译主要显示围绕机器码实现过程的模块结构。

@itemize[

@item{@racketidfont{#%machine-code} 形式对应未反汇编的机器码，其中机器码在字节字符串中。}

@item{@racketidfont{#%assembly-code} 形式对应已反汇编的机器码，其中汇编代码显示为字符串序列。}

@item{@racketidfont{#%interpret} 形式对应大型过程的编译形式，其中只有较小的嵌套过程被编译为机器码。}

]

@section{Racket BC Decompilation}

Racket @BC 字节码的结构与 Racket 核心语言足够接近，因此通常可以更频繁地转换回近似 Racket 代码。就其能被转换的程度而言，反编译代码中的许多形式具有与通常相同的含义，如 @racket[module]、@racket[define] 和 @racket[lambda]。其他特定于字节码渲染的形式和转换反映了特定的执行模型：

@itemize[

@item{顶层变量、模块内定义的变量以及从其他模块导入的变量都以 @litchar{_} 为前缀，有助于暴露使用局部变量与使用其他变量之间的区别。此外，从其他模块导入的变量有一个以 @litchar["@"] 开头的后缀，指示源模块。最后，具有常量性的导入变量有一个中缀：@litchar{:c} 表示所有实例化中的常量形状，@litchar{:f} 表示初始化后的固定值，@litchar{:p} 表示一个过程，@litchar{:P} 表示返回时保留 continuation marks 的过程，@litchar{:t} 表示一个结构类型，@litchar{:mk} 表示一个构造函数，@litchar{:?} 表示一个结构谓词，@litchar{:ref} 表示一个结构访问器，或 @litchar{:set!} 表示一个结构修改器。

非局部变量始终通过隐式的 @racketidfont{#%globals} 或 @racketidfont{#%modvars} 变量间接访问，该变量驻留在值栈上（否则值栈包含局部变量）。当编译器无法证明变量将在访问之前被定义时，变量访问会被 @racketidfont{#%checked} 进一步包装。

 Core primitives 的用法显示时没有前导 @litchar{_}，并且永远不会被 @racketidfont{#%checked} 包装。}

@item{局部变量访问可能被 @racketidfont{#%sfs-clear} 包装，这表示保存该变量的变量栈位置将被清除，以阻止垃圾收集器保留该变量的值。名称 @racketidfont{unused} 开头的变量永远不会真正存储在堆栈上，因此它们永远不会具有 @racketidfont{#%sfs-clear} 注释。（字节码编译器通常会消除此类绑定，但有时无法做到——要么因为它无法证明右侧产生正确数量的值，要么发现该变量为 unused 时已经为时已晚。）

 Mutable variables 被转换为显式的装箱值，使用 @racketidfont{#%box}、@racketidfont{#%unbox} 和 @racketidfont{#%set-boxes!}（可同时对多个 box 进行操作）。@racketidfont{set!-rec-values} 操作构造相互递归的闭包，并同时更新绑定这些闭包的对应变量栈位置。@racketidfont{set!}、@racketidfont{set!-values} 或 @racketidfont{set!-rec-values} 形式总是在局部变量被闭包捕获之前使用；该顺序反映了闭包如何捕获变量栈位置中的值，而不是栈位置。}

@item{在 @racket[lambda] 形式中，如果由 @racket[lambda] 产生的过程具有名称（可通过 @racket[object-name] 访问）和/或源位置信息，则它被显示为在过程体开头的引用常量。随后，如果 @racket[lambda] 形式从其上下文中捕获了任何绑定，则这些绑定也显示在引用常量中。当调用闭包时，这两个常量都不对应计算，但捕获的绑定列表对应于评估 @racket[lambda] 形式本身的闭包分配。

 不捕获任何绑定的 @racket[lambda] 形式用 @racketidfont{#%closed} 加上一个绑定到闭包的标识符包装。绑定的作用域覆盖整个反编译输出，并且可以直接在程序的其他部分中引用；该绑定对应于共享的常量闭包值，它甚至可能包含对自身或其他常量闭包的循环引用。}

@item{形式 @racket[(#%apply-values _proc _expr)] 等价于 @racket[(call-with-values (lambda () _expr) _proc)]，但运行时为 @racket[_expr] 避免闭包分配。类似地，@racket[#%call-with-immediate-continuation-mark] 调用等价于 @racket[call-with-immediate-continuation-mark] 调用，但避免闭包分配。}

@item{@racket[define-values] 形式可能有 @racket[(begin '%%inline-variant%% _expr1 _expr2)] 作为其表达式，在这种情况下，@racket[_expr2] 是正常结果，但 @racket[_expr1] 可用于从其他模块调用时的内联。没有 @racket['%%inline-variant%%] 的函数定义绝不会被跨模块内联。}

@item{已知具有特定类型的函数参数和局部绑定的名称嵌入了已知类型。例如，参数可能有一个以 @racketidfont{argflonum} 开头的名称，或者局部绑定可能有一个以 @racketidfont{flonum} 开头的名称，以指示一个 flonum 值。}

]

@; ------------------------------------------------------------

@section{API for Decompiling}
@defmodule[compiler/decompile]

@defproc[(decompile [top (or/c linkl-directory? linkl-bundle? linkl?
                               linklet? faslable-correlated-linklet?)]
                    [#:to-linklets? to-linklets? any/c #f]
                    [#:skip-syntax-literals? skip-syntax-literals? any/c #f])
         any/c]{

如果 @racket[top] 是 @racket[linkl-directory?]，@racket[linkl-bundle?]，
@racket[linkl?]，@racket[linklet?] 或 @racket[faslable-correlated-linklet?]，
接收字节码解析结果并返回表示编译代码的 S-表达式。

如果 @racket[to-linklets?] 为真，则结果 S-表达式在 @racket[top] 中显示原始的
@racket[linklet] 形式，而不是重构 @racket[module] 形式。

如果 @racket[skip-syntax-literals?] 为真，则结果 S-表达式省略 syntax-object
字面值的反编译。

@history[#:changed "1.17" @elem{Added @racket[#:skip-syntax-literals?] argument.}]}

@; ------------------------------------------------------------

@include-section["zo-parse.scrbl"]

@; ------------------------------------------------------------

@section{API for Marshaling Bytecode}

@defmodule[compiler/zo-marshal]

@defproc[(zo-marshal-to [top (or/c linkl-directory? linkl-bundle?)] [out output-port?]) void?]{

接收字节码表示并将其写入 @racket[out]。}

@defproc[(zo-marshal [top (or/c linkl-directory? linkl-bundle?)]) bytes?]{

接收字节码表示并为封送的字节码生成字节字符串。}

@; ------------------------------------------------------------

@include-section["zo-struct.scrbl"]

@; ------------------------------------------------------------

@section{Machine-Independent Linklets}

@defmodule[compiler/faslable-correlated]

@nested[#:style 'inset]{
@elem[#:style (style #f (list (background-color-property "yellow")))]{@bold{Warning:}}
      @racketmodname[compiler/faslable-correlated] 库暴露了 Racket 字节码抽象的内部。与其他 Racket 库不同，@racketmodname[compiler/faslable-correlated] 可能会在不同 Racket 版本间发生不兼容更改。}

@history[#:added "1.3"]

@defstruct[faslable-correlated-linklet ([expr any/c]
                                        [symbol? name])
           #:prefab]{

@racket[faslable-correlated-linklet] 结构表示已 ``编译'' 为机器无关形式的 @tech[#:doc reference-doc]{linklet}，其中包含表示 @racket[linklet] 形式的 S-表达式。该 S-表达式通过用 @racket[faslable-correlated] 结构包装一些嵌套的 S-表达式来丰富源位置信息。

由于 @racket[faslable-correlated-linklet] 是 @tech[#:doc reference-doc]{prefab} 结构类型，上面文档化的字段合同不会被执行。}

@defstruct[faslable-correlated ([e any/c]
                                [source any/c]
                                [position exact-positive-integer?]
                                [line exact-positive-integer?]
                                [column exact-nonnegative-integer?]
                                [span exact-nonnegative-integer?]
                                [props (hash/c symbol? any/c)])
           #:prefab]{

包装一个 S-表达式 @racket[e] 以给它一个 @tech[#:doc reference-doc]{源位置}。S-表达式 @racket[e] 可能包含嵌套的 @racket[faslable-correlated] 结构，但预期嵌套仅在点对内。

由于 @racket[faslable-correlated] 是 @tech[#:doc reference-doc]{prefab} 结构类型，上面文档化的字段合同不会被执行。}

@defproc[(strip-correlated [e any/c]) any/c]{

递归通过 @racket[e] 以剥离可通过点对到达的任何 @racket[faslable-correlated] 结构。给定的 @racket[e] 不能包含可通过点对到达的任何循环。}
