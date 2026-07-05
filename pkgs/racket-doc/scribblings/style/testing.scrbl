#lang scribble/base

@(require "shared.rkt")

@title[#:tag "testing"]{测试}

@; -----------------------------------------------------------------------------
@section[#:tag "test-suite"]{测试套件}

本节专门面向向 Racket 代码库提交代码的开发者。

我们的绝大多数 collection 都附带测试套件。这些测试套件通常存放在 PLT 仓库的 @tt{collects/tests/} 目录下，不过由于历史原因，少数 collection 拥有自己的本地测试套件。如果你新增了某个 collection，请在 @tt{tests} collection 中创建对应的测试套件。

在提交代码之前运行这些测试套件。为了方便测试，我们建议你在自己的 collection 中添加一个 @tt{TESTME.txt} 文件。理想情况下，你也可以放一份文件在此目录，来运行基础测试。请参见 @hyperlink["https://github.com/racket/htdp/tree/master/htdp-test/2htdp"]{2htdp} 这个拥有自己独特测试风格的 collection。该文件应当说明测试的位置、运行方式以及成功与失败的评判标准。这些各个不同文件之所以必要，是因为不同的集合有不同的需求，且测试以在我们历史上以多种方式演化。

提交代码后，请注意 @hyperlink["http://drdr.racket-lang.org/"]{DrDr} 发出的邮件并务必阅读！不要忽视它们。如果你有已知存在缺陷的测试且修复工作繁重，可以考虑将测试目录拆分为 @tt{success} 与 @tt{failure} 两个部分：前者是现在理应成功的测试，后者是当下预期会失败的测试。参见 @hyperlink["https://github.com/racket/typed-racket/tree/master/typed-racket-test"]{Typed Racket 测试形成} 了解一个示例。如果你创建了这样的 @tt{failure} 测试，可以按如下方式禁用 DrDr 的检查：

@verbatim[#:indent 2]{
  git prop set drdr:command-line "" <file> ...
}

这是 Racket 特有的 @tt{git} 命令。

@; -----------------------------------------------------------------------------
@section[#:tag "test-bang"]{始终测试！}

当你调试现有代码时，首先编写一个测试用例。将其放入对应组件的测试套件中，使得该错误不会被无意间重新引入，并附上一个指向问题报告的说明。其次，修改代码来修复该错误。这样做是为了确保你没有在测试中引入错误；往往容易认为自己修复了问题，而实际上你的新测试只是没有正确暴露出原来的错误。第三，重新运行测试套件以确保错误已被修复且没有现有测试失败。

如果没有测试套件而你也不确定如何搭建，请在开发者邮件列表中咨询。或许有人会向你解释为什么不存在，或者草拟搭建的方案。请不要忽视这个问题。如果你无法搭建测试套件，可以选择以下几种方式：

@itemlist[#:style 'ordered

  @item{向库中添加可测试的功能。当然，添加功能意味着添加外部文档。Robby 和 Matthew 已为 GUI 库做过此事，于是现在有了一套大型自动化的 DrRacket 测试套件。因此，即便是 GUI 程序也可以附带扩展的测试套件。}

  @item{添加需要人工验证的端到端测试。例如，可能很难测试 Slideshow，那么你可以创建一组幻灯片并描述其应有的外观，以便未来的维护者在你做出改动后再次确认。不过，请将这作为@emph{最后且最不可取}的手段。}

]
@;
 某些 collection 缺乏测试的问题不会一夜之间消失。但只要都贡献一点力量，我们终将把测试套件扩展到覆盖整个代码库，未来的维护者会为此感激我们。
