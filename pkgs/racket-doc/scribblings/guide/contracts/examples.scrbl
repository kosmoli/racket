#lang scribble/doc
@(require scribble/manual scribble/eval "utils.rkt"
          (for-label racket/contract racket/gui))

@title[#:tag "contracts-examples"]{更多示例}

本节通过 @italic{Design by Contract, by Example} @cite["Mitchell02"] 中的一系列示例来说明 Racket contract 实现的现状。

Mitchell 和 McKim 的 design by contract DbC 原则源自 1970 年代风格的代数规范。DbC 的总体目标是依据代数构造函数的观测器来指定它们。虽然我们重新表述了 Mitchell 和 McKim 的术语并主要使用应用式方法，但我们保留了他们的"类"和"对象"术语：

@itemize[
@item{@bold{将查询与命令分开。}

    @italic{查询}返回结果但不改变对象的可观察属性。@italic{命令}改变对象的可观察属性但不返回结果。在应用式实现中，命令通常返回同一 class 的新对象。}

@item{@bold{将基本查询与派生查询分开。}

    @italic{派生查询}返回可根据基本查询计算的结果。}

@item{@bold{为每个派生查询编写一个 post-condition contract，根据基本查询指定其结果。}}

@item{@bold{为每个命令编写一个 post-condition contract，根据基本查询指定可观察属性的更改。}}

@item{@bold{为每个查询和 command 决定适当的 pre-condition contract。}}]

以下各节对应 Mitchell 和 McKim 书中的章节（但并非所有章节都会出现）。建议您先阅读 contract（靠近第一个 module 的末尾），然后阅读实现（在第一个 module 中），最后阅读测试 module（在每个部分的末尾）。

Mitchell 和 McKim 使用 Eiffel 作为底层编程语言，采用传统的 imperative 编程风格。我们的长期目标是将它们的示例移植为应用式的 Racket、面向结构的 imperative Racket，以及 Racket 的 class 系统。

注意：为了模仿 Mitchell 和 McKim 对 parametericity（参数多态）的非正式概念，我们使用 first-class contract。在多个地方，使用 first-class contract 改进了 Mitchell 和 McKim 的设计（参见接口中的注释）。

@section{客户-管理器组件}

第一个 module 包含一些 struct 定义，位于单独的 module 中，以便更好地追踪错误。

@external-file[1]

此 module 包含使用上述内容的程序。

@external-file[1b]

测试：

@external-file[1-test]

@section{参数化（简单）堆栈}
@external-file[2]

测试：

@external-file[2-test]

@section{字典}
@external-file[3]

测试：

@external-file[3-test]

@section{队列}
@external-file[5]

测试：

@external-file[5-test]
