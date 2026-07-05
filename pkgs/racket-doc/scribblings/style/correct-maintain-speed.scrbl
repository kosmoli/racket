#lang scribble/base

@(require "shared.rkt")

@title[#:tag "correct-maintain-speed"]{基本生活法则}

@nested[#:style 'inset]{ @italic{优先考虑读者而非写者。}
 --- Yaron Minsky, JaneStreet, 2010 于 NEU/CCS}

@margin-note*{这个排序偶尔会有错误。例如，我们几乎可以避免使用 IEEE 浮点数。为了做到这一点，Racket 的 @scheme[sqrt] function 可以返回一个接近 IEEE float 结果的有理数。然而，我们没有做这种傻事，因为我们在这个上下文中决定以精度换取速度。}
努力写出正确、可维护且快速的代码。这些形容词的顺序至关重要：正确比可维护更重要；可维护比快速更重要；快速也很重要，因为没有人想忍受慢速程序。

本部分解释了这三点对 Racket 代码库的影响。本指南的其余部分是要详细阐述的建议，以帮助你对 Racket 代码库做出正确、可维护且快速的贡献。

@; -----------------------------------------------------------------------------
@section[#:tag "correctness"]{正确性和测试}

@nested[#:style 'inset]{@italic{我有 bug 报告，故我在。} --- Matthias,观看 Matthew、Robby、Shriram 等人创建原始代码库}

@nested[#:style 'inset]{@italic{选择如何对抗 bug 决定了我们的性格，而非它们存在或不存在。} --- Robby,在回应中}

PLT 的目标是发布好代码并尽快消除错误。所有软件都有错误；完全正确性是 perfectionist 目标。如果错误未知，软件就没有被使用。然而，目标是在功能发布前确保某种基本的正确性水平，并确保同样的错误不再引入。

我们通过大型测试套件确保这个基本的正确性。我们的测试套件包含各级测试。除了 unit test 外，你还会发现使用 "random testing" 策略工具和工具的测试套件，其它使用 fuzz testing，还有端到端 "systems level" 测试，DrRacket 附带一个自动 GUI player 来探索其功能。

有关 Racket 代码库上下文中测试的详细信息，请参见 @secref{testing}。

@; -----------------------------------------------------------------------------
@section{维护}

如果我们想创建可维护的代码，必须确保代码是可理解的。当你可以理解其外部目标时，代码是可理解的；当你能从外部目标猜测其组织时；当组织和代码符合一致的 style 标准时；偶尔复杂部分配有内部文档。

已发布的代码必须有文档。相反，代码外部行为的更改必须引起其文档的同时更改。这里 "同时" 的意思是两个更改在同一个 push 到代码库中，不一定在同一个 commit。另见 @secref{branch-and-commit} 了解 Git 操作。

关于记录代码的 style rule，参考 @hyperlink["http://docs.racket-lang.org/scribble/how-to-doc.html#%28part._reference-style%29"]{Scribble 手册中的 style guide}。理想情况下文档分为两部分，可能在同一文档中：一个 "Guide" 部分解释目标并建议使用案例，一个传统的 "Reference" 部分呈现细节。HtDP/2e teachpack 的文档是两部分共址的一个例子。还为 "Reference" 部分考虑为每个 function 和 construct 添加示例。最后，确保你有所有正确的 @tt{for-label} @tt{require}s 并利用其它有用的交叉引用。

话虽如此，像 Racket 这样的系统的生产偶尔需要实验。一旦我们理解了新功能部分，就必须放弃实验的 "failure branches" 并将成功部分转变为可维护的包。你甚至可以考虑最终将代码转换为 Typed Racket。

没有遵循 style 的基本要素，代码理解变得不可能。本文档的其余部分大多是关于这些 style 元素，包括一些关于内部文档的建议。

@; -----------------------------------------------------------------------------
@section{速度}

使代码快速是一项无止境的任务。目标是让 code 合理地快速。

与正确性一样，性能需要一些 "测试"。最低限度地，在一些相当真实的输入和一些较大的输入上测试你的代码。向测试套件添加一个定期运行大输入的文件。例如，Universe display 的常规测试套件处理 50 x 50 的显示窗口；其 stress test 检查 Universe event handler 和绘图 routine 是否能处理笔记本大小甚至 30 英寸的显示。或者，如果你要编写一个队列数据结构的库，常规测试套件确保它正确处理小队列的 enqueue 和 dequeue（包括空队列）；同库的 stress test 在各种队列大小上运行队列操作，包括说数万个元素的大队列。

Stress test 通常没有预期输出，因此它们永远不会通过。编写 stress test 的实践暴露实现缺陷或提供在选择两个 API 时使用的比较数据。仅仅编写并保留它们就可以提醒我们事情可能会出错，并且我们可以通过某个其它门检测性能何时退化。最重要的是，stress test 可能揭示你的代码没有实现预期的 @math{O(.)} 运行时间。仅发现这些就很有帮助。如果你无法想到改进，只需在外部库中记录弱点并继续。

当你继续阅读时，记住我们不是 perfectionist。我们生产合理的软件。
