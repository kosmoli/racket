#lang scribble/base

@(require "shared.rkt")

@title{如何进行 Racket 编程：一份风格指南}
@author{Matthias Felleisen, Matthew Flatt, Robby Findler, Jay McCarthy}

@section-index{风格指南}

@; -----------------------------------------------------------------------------

自1995年以来，"仓库贡献者"的数量已从少数人增长到三十人以上。这一增长意味着大量学习，也引入了编程风格的不一致性。本文档试图利用前者并开始减少后者。这样做将帮助我们这些开发者，以及使用我们开源代码作为 Racket 编程隐性指南的用户。

为了管理代码的增长并展示良好的 Racket 风格，我们需要塑造代码库贡献的指导方针。这些指导方针应在代码库的不同部分之间达成某种程度的一致性，以便每个打开文件的人都能轻松找到方向。

本文档详细说明了指导方针和最佳实践。它们涵盖了从基本工作（提交）习惯到缩进和命名等小型语法思想的广泛主题。

代码库的许多部分尚未达到指导方针的要求。以下是我们的入门方法。当你创建一个新文件时，请遵循指导方针。如果你需要编辑一个文件，你将需要一些时间来了解其工作原理。如果由于与指导方针的不一致而花费了相当长的时间，请花时间修复（部分）文件。毕竟，如果这些不一致让你困扰那么长时间，其他人可能会遇到同样的问题。如果你帮助修复它，你就减少了未来的维护时间。无论谁接下来接触这个文件都会感激你。@emph{请}运行测试套件，并且请@emph{不要}更改文件的行为。

另外，请检查提交消息。如果你发现代码增量有问题，请让贡献者知道。如果你发现没有文档和测试的 bug 修复，请让贡献者知道。代码应该由不止一个人审查，因为第二个人很可能抓住逻辑错误、性能问题和意外效果。

@bold{请求} 本文档并不完整也不完美。请将此视为对改进和建议的呼吁。如果你有任何想法，请联系第一作者通过电子邮件。如果你的请求被忽略，请向所有四位作者上诉。

@bold{注意} 本风格指南中的建议可能与你从小习惯的方式不一致。（它们与主要作者关于风格的一些想法冲突。）但如果你写的代码最终进入 Racket 代码库，请遵循这里的建议。如果其他人处理你的代码，如果不符合风格指南，此人可能会"修复"你的代码。

@; -----------------------------------------------------------------------------

@include-section["correct-maintain-speed.scrbl"]
@include-section["testing.scrbl"]
@include-section["unit.scrbl"]
@include-section["constructs.scrbl"]
@include-section["scribble.scrbl"]
@include-section["textual.scrbl"]
@include-section["some-performance.scrbl"]
@include-section["branch-and-commit.scrbl"]
@include-section["acknowledgment.scrbl"]

@include-section{todo.scrbl}
