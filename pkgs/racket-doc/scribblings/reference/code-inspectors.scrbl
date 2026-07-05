#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "modprotect"]{Code Inspector}

与 inspector 控制对结构字段的访问方式相同（参见 @secref["inspectors"]），inspector 还控制对 @tech{模块绑定}的访问。以这种方式使用的 inspector 称为 @deftech{code inspector}。@tech{模块绑定}的默认 code inspector 由 @racket[current-code-inspector] 参数确定，而不是由 @racket[current-inspector] 参数确定。

当 @racket[module] 声明被求值时，@racket[current-code-inspector] 参数的值与该模块声明相关联。当通过 @racket[require] 或 @racket[dynamic-require] 调用模块时，会创建一个模块的声明时 inspector 的子 inspector，且此子 inspector 与该模块调用相关联。任何控制该子 inspector 的 inspector（包括声明时 inspector 及其上级）控制模块调用。特别是，如果 @racket[current-code-inspector] 的值从不改变，则对于任何模块调用，都不会失去控制，因为模块的调用与 @racket[current-code-inspector] 的子 inspector 相关联。

当控制模块调用的 inspector 安装到 @racket[current-code-inspector] 上时，它允许对模块使用 @racket[module->namespace]，并且允许通过 @racket[dynamic-require] 访问模块的 @deftech{受保护的}导出（即，那些使用 @racket[protect-out] 从模块导出的标识符）。一个模块不能 @racket[require] 一个具有较弱声明时 code inspector 的模块。

当展开 @racket[module] 形式或创建 @tech{namespace} 时，@racket[current-code-inspector] 的值与该模块或 namespace 的顶层 @tech{词法信息}相关联。具有该 @tech{词法信息}的 syntax object 获得对 inspector 控制的任何模块的受保护和未导出绑定的访问。对于 @racket[module] 的情况，即使语法对象用于在较低权限上下文中展开代码，inspector 也与这些语法对象保持关联；此外，如果语法对象是编译为变量引用的标识符，则即使它出现在求值（即声明）时使用较弱 inspector 的模块形式中，inspector 也与该变量引用保持关联。当语法对象或变量引用在打印的编译代码中（参见 @secref["print-compiled"]）时，关联的 inspector 不会被保留。

当打印形式的编译代码被 @racket[read] 读回时，没有 inspector 与代码关联。当代码被 @racket[eval] 求值时，实例化的 syntax object 字面量和模块变量引用获取 @racket[current-code-inspector] 的值作为其 inspector。

当模块附加到多个 @tech{namespace}，每个都有自己的 @tech{模块注册表}时，模块调用的 inspector 可以特定于注册表。在特定模块注册表中的调用 inspector 可以通过 @racket[namespace-unprotect-module] 更改（但更改 inspector 需要控制旧的 inspector）。

@history[#:changed "8.1.0.8" @elem{增加了对 @racket[require] 具有较弱 code inspector 的模块的约束。}]

@defparam[current-code-inspector insp inspector?]{

一个 @tech{参数}，确定用于控制对模块绑定和重新定义的访问的 inspector。

如果 code inspector 从其原始值更改，则由默认 @tech{已编译加载处理器} 加载的字节码被标记为不可运行。}
