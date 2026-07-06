#lang scribble/base

@(require "shared.rkt" (for-label rackunit))

@title{代码单元}

@; -----------------------------------------------------------------------------
@section{组织结构至关重要}

我们往往以自下而上的方式开发代码单元，同时采取一些自上而下的规划。这种策略并不令人惊奇，因为我们在现有库之上构建代码，这需要一些实验，而这些实验在 REPL 中进行。我们还希望尽快获得可测试的代码，意味着我们往往会先为那些可以开发和运行测试的代码碎片做出记录。但是，读者并不希望跟随我们的开发过程，他们希望理解代码计算了什么，而不必理解所有细节。

因此，请花时间以自上而下的方式呈现每个代码单元。这从模块的实现部分开始。将重要函数放在靠近顶部的位置，下方就是任何说明我们使用何种数据的代码和注释。这条规则也适用于类，其䉮我们希望在处理 @racket[private] 方法之前先暴露 @racket[public] 方法。这条规则也适用于单元。

@; -----------------------------------------------------------------------------
@section{规模至关重要}

保持代码单元小巧。保持模块、类、函数和方法小巧。

一个 10,000 行代码的模块太大了。一个 1,000 行的模块可以接受。一个 500 行代码的模块就有正确的规模。

一个模块通常应包含一个类及其辅助助函数，这反而确定了一个良好大小类的长度。

一个大约 66 行的函数/方法/syntax-case 通常是可以接受的。66 基于小字体屏幕的长度。它真的意思是“一个屏幕长度”。确实有例外，有些函数长超过 1,000 行且极其易读。嵌套层次和嵌套循环在你编写代码时可能看起来不错，但读者不会喜欢在心中保留隐含和复杂的依赖关系。将函数分离（你可能称之为手动 lambda 提升）为适当平滑的单元组织并且适合在（笔记本）屏幕上显示是很有帮助的。

多年来，我们有一种受限的 syntax 转换语言，迫使人们创建@emph{5de85927}的函数。现在已不再是这种情况，所以我们应尽可能坚持这条规则。

如果一个代码单兄看起来不可理解，那它可能太大了。将它拆分。为了讨论这些碎片计算了什么、实现了什么或提供了什么，请使用有意义的名称；参见 @secref{names}。如果您无法为这样的碎片想出一个好名称，那您可能正在查看错误类型的拆分；考虑其他替代方案。

@; -----------------------------------------------------------------------------
@(define line
   @t{---------------------------------------------------------------------------------------------------})
@section{模块及其接口}

模块的目的是提供一些服务：
@;
@centerline{Equip a module with a short purpose statement.}
@;
Often ``short'' means one line; occasionally you may need several lines.

为了理解一个模块的服务，请在目皎说明下方将模块组织为三个部分：其导出、其导入和其实现：
@;%
@codebox0[
 (racketmod0
racket/base

(code:comment2 #, @elem{the module implements a tv server})

(provide
 (code:comment2 #, @elem{launch the tv server function})
 tv-launch
 (code:comment2 #, @elem{set up a tv client to receive messages from the tv server})
 tv-client)

(code:comment2 #, @line)
(code:comment2 #, @t{import and implementation section})

(require 2htdp/universe htdp/image)

(define (tv-launch)
  (universe ...))

(define (tv-client)
  (big-bang ...))
)]
@;%

如果您选择将 @racket[provide] 与 @racket[contract-out] 一起使用，可能希望有两个 @racket[require] 部分：
@itemlist[
@item{第一个，放置在 @racket[provide] 部分，导入制定 contract 所需的值；}
@item{第二个，放置在 @racket[provide] 部分下方，导入实现服务所需的值。}
]
 如果您的 contract 需要更多概念，请在 @racket[provide] 规格下方定义它们：
@;%
@codebox0[
 (racketmod0
racket/base

(code:comment2 #, @elem{the module implements a tv server})

(require racket/contract) ;; needed for contract-out

(provide
 (contract-out
  (code:comment2 #, @elem{initialize the board for the given number of players})
  [board-init        (-> player#/c plain-board/c)]
  (code:comment2 #, @elem{initialize a board and place the tiles})
  [create-board      (-> player#/c (listof placement/c)
                         (or/c plain-board/c string?))]
  (code:comment2 #, @elem{create a board from an X-expression representation})
  [board-deserialize (-> xexpr? plain-board/c)]))

(require xml)

(define player# 3)
(define plain-board/c
  (instanceof/c (and/c admin-board%/c board%-contracts/c)))

(define placement/c
  (flat-named-contract "placement" ...))

(code:comment2 #, @line)
(code:comment2 #, @t{import and implementation section})

(require 2htdp/universe htdp/image)

(code:comment2 #, @t{implementation:})
(define (board-init n)
  (new board% ...))

(define (create-board n lop)
  (define board (board-init n))
  ...)

(define board%
  (class ... some 900 lines ...))
)]
@;%
 在上述代码片段中，@xml[] 导入 @racket[xexpr?] 谓词。由于后者是表述 @racket[board-deserialize] 的 contract 所必需，因此 @xml[] 的 @racket[require] 行是 @racket[provide] 部分的一部分。相反，以下的 @racket[require] 行导入了事件处理机制和简单的图像处理库，而这云工具仅用于已提供服务的实现。

优先考虑使用明确的导出规格而非 @racket[(provide (all-defined-out))]。

测试套件部分——如果位于模块内——应在最后，包含其特定的依赖项，即 @racket[require] 规格。

@; -----------------------------------------------------------------------------
@subsection{Require}

在实现部分的顶部放置 @racket[require] 规格，让所有读者都知道要理解该模块需要什么。

@; -----------------------------------------------------------------------------
@subsection{Provide}

模块的接口描述其提供的服务；其体来实现这些服务。如果外部文档不足，其他人必须阅读接口：

@centerline{Place the interface at the top of the module.}
@;
This helps people find the relevant information quickly.

@compare0[
@;%
(racketmod0
 racket

 (code:comment2 #, @elem{This module implements})
 (code:comment2 #, @elem{several strategies.})

 (provide
  (code:comment2 #, @elem{Stgy = State -> Action})

  (code:comment2 #, @elem{Stgy})
  (code:comment2 #, @elem{people's strategy})
  human-strategy

  (code:comment2 #, @elem{Stgy})
  (code:comment2 #, @elem{tree traversal})
  ai-strategy)

 (code:comment2 #, @1/2-line[])
 (code:comment2 #, @t{implementation})

 (require "basics.rkt")

 (define (general p)
   ... )

 ... some 100 lines ...
 (define human-strategy
   (general create-gui))

 ... some 100 lines ...
 (define ai-strategy
   (general traversal)))

(racketmod0
 racket

 (code:comment2 #, @elem{This module implements})
 (code:comment2 #, @elem{several strategies.})

 (code:comment2 #, @1/2-line[])
 (code:comment2 #, @t{implementation})

 (require "basics.rkt")

 (code:comment2 #, @elem{Stgy = State -> Action})

 (define (general p)
   ... )
 ... some 100 lines ...

 (provide
  (code:comment2 #, @elem{Stgy})
  (code:comment2 #, @elem{a person's strategy})
  human-strategy)

 (define human-strategy
   (general create-gui))
 ... some 100 lines ...

 (provide
  (code:comment2 #, @elem{Stgy})
  (code:comment2 #, @elem{a tree traversal})
  ai-strategy)

 (define ai-strategy
   (general traversal))
 ... some 100 lines ...
)
]

从这个对比中可以看出，一个接口不应仅仅是一个名称列表的 @scheme[provide]。每个标识符都应带有目皎说明。数据的类型说明也可能出现在 @scheme[provide] 规格中，以便读者了解您的公共函数处理何种数据。

对于一个函数，通常一行目皎说明就够了，但 syntax 应带有其引入的语法子句的描述以及其含义。

@codebox0[
(racketmod0
racket

(provide
 (code:comment# #, @elem{(define-strategy (s:id a:id b:id c:id d:id)
   action:definition-or-expression)})
 
 (code:comment2 #, @elem{(define-strategy (s board tiles available score) ...)})
 (code:comment2 #, @elem{defines a function from an instance of player to a})
 (code:comment2 #, @elem{placement. The four identifiers denote the state of})
 (code:comment2 #, @elem{the board, the player's hand, the places where a})
 (code:comment2 #, @elem{tile can be placed, and the player's current score.})
 define-strategy)
)]

使用 @scheme[provide] 与 @racket[contract-out] 用于模块接口。Contract 通常为首次阅读者提供正确的规格级别。

在最低限度，您应使用类型似的 contract，即检查数据构造函数的谓词。它们几乎不付价，尤其是因为导出的函数往往会在内部检查这些约束，且 contract 往往使这些检查无效。

如果您发现 contract 导致性能瓶颈，请向 Racket 开发者邮件列表报告该问题。

@subsection{接口的统一性}

为函数、类和方法的命名挑选一致的规则并坚持下去。例如，您可能希望所有导出的名称都以它们处理的数据类型名称作为前缀，比如 @racket[syntax-local]。

为函数和方法的参数的命名和顺序挑选一致的规则并坚持下去。例如，如果您的模块实现了抽象数据类型（ADT），所有作用于该 ADT 的函数都应先或末接收该 ADT 参数。

最后，在一个模块中所有指代同类数据的函数/方法参数使用相同的名称——不管该模块是否实现了通用的数据结构。例如，在 @hyperlink["https://github.com/racket/racket/blob/master/pkgs/racket-index/setup/scribble.rkt"]{@filepath{pkgs/racket-index/setup/scribble.rkt}} 中，所有函数都使用 @racket[latex-dest] 来指代同类数据，即使未导出的函数也用。

@subsection{节和子模块}

最后，一个模块由节组成。用注释行分隔节是良好的做法。您可能想为每个节写下目皎说明，以便读者可以轻松理解模块的哪一部分实现了哪种服务。或者，考虑在 DrRacket 中使用大字母章节标题来标注模块的各个节。

通过 @racketmodname[rackunit]，可以使用 @racket[define/provide-test-suite] 在模块内定义测试套件。如果这样做，请将测试部分放置在模块末尾并且且对于测试套件专门需要的定义使用 @racket[require] 导入。

从版本 5.3 开始，Racket 支持子模块。使用子模块来表述节，尤其是测试节。通过子模块，现在可以将节拆分为不同的部分（用相同的名称标注）并交给语言将其缝合在一起。

@;%
@codebox0[#:label "fahrenheit.rkt"
 (racketmod0
 racket

 (provide
  (contract-out
   (code:comment2 #, @t{convert a fahrenheit temperature to a celsius})
   [fahrenheit->celsius (-> number? number?)]))

 (define (fahrenheit->celsius f)
   (/ (* 5 (- f 32)) 9))

 (module+ test
   (require rackunit)
   (check-equal? (fahrenheit->celsius -40) -40)
   (check-equal? (fahrenheit->celsius 32) 0)
   (check-equal? (fahrenheit->celsius 212) 100))
)]
@;%
 If you develop your code in DrRacket, it will run the test sub-module
 every time you click ``run'' unless you explicitly disable this
 functionality in the language selection menu. If you have a file and you
 just wish to run the tests, use @tt{raco} to do so:
@verbatim[#:indent 2]{
$ raco test fahrenheit.rkt
}
 在 shell 中运行此命令将从 @tt{fahrenheit.rkt} 加载并计算测试子模块。

@; -----------------------------------------------------------------------------
@section{类和单元}

（我会在某个时候在这里写些内容。）

@; -----------------------------------------------------------------------------
@section{函数和方法}

If your function or method consumes more than two parameters, consider
keyword arguments so that call sites can easily be understood.  In
addition, keyword arguments also ``thin'' out calls because function calls
don't need to refer to default values of arguments that are considered
optional.

类似地，如果您的函数或方法消耗两个（或更多）@emph{53ef选}参数，关键字参数是必需的。

为您的函数写下目皎说明。如果可以，添加非正式类型和/或 contract 声明。

@; -----------------------------------------------------------------------------
@section{Contracts}

Contract 在服务提供者和服务消费者（即 @defterm{server} 和 @defterm{client}）之间建立边界。由于历史原因，我们往往将此边界称为 @defterm{module boundary}，但这个词汇中的“module”并@emph{4e0d}仅仅指基于文件的或物理的 Racket 模块。显然，@defterm{contract boundary} 比 module boundary 更好，因为它将这两个概念分开了。

当您在模块级别使用 @racket[provide] 与 @racket[contract-out] 时，物理模块的边界与 contract 边界重合。

当一个模块变得太大而无法管理但您不想将源码分散到多个文件时，您可能希望使用以下两个构造之一来在物理模块内部建立 contract 边界：
@itemlist[
@item{@racket[define/contract]}
@item{@racket[module], as in submodule.}
]

使用第一个 @racket[define/contract] 类似于使用 @racket[define]，区别在于它还可以在定义的标题和体之间添加一个 contract。下面的代码显示了一个建立三个内部 contract 边界的文件：两个用于简单常量，一个用于函数。

@;%
@codebox0[#:label "celsius.rkt"
 (racketmod0
racket

(define/contract AbsoluteC real? -273.15)
(define/contract AbsoluteF real? -459.67)

(define/contract (celsius->fahrenheit c)
  (code:comment2 #, @t{convert a celsius temperature to a fahrenheit temperature})
  (-> (and/c real? (>=/c AbsoluteC))
      (and/c real? (>=/c AbsoluteF)))
  (code:comment2 #, @elem{-- IN --})
  (+ (* 9/5 c) 32))

(module+ test
  (require rackunit)
  (check-equal? (celsius->fahrenheit -40) -40)
  (check-equal? (celsius->fahrenheit 0) 32)
  (check-equal? (celsius->fahrenheit 100) 212))
)]
@;%

为了了解这些 contract 边界的工作方式，您可能想要进行一些实验：
@itemlist[#:style 'ordered
@item{将以下行添加到文件的底部：
@;%
@(begin
#reader scribble/comment-reader
(racketblock
(celsius->fahrenheit -300)
))
@;%
保存到文件并观察 contract 系统如何将违反归于这行以及 blame 报告告诉了你什么。}

@item{将 @racket[celsius->fahrenheit] 函数的体替换为 @racketblock[(sqrt c)]，再次运行程序并研究 contract 异常，尤其注意观察哪个方被归于 blame。}

@item{将 @racket[AbsoluteC] 的右侧替换为 @racket[-273.15i]，即复数。这次一个不同的 contract 方被归于 blame。}
]
下面的屏幕截图显示 @racket[define/contract] 适用于模块中的互相递归函数。这个功能是 @racket[define/contract] 独有的。

@image["mut-rec-contracts.png" #:scale .8]{Mutually recursive functions with contracts}

相反，在 contract 边界方面，子模块的行为与普通模块完全相同。像 @racket[define/contract] 一样，子模块在其自身和模块的其余部分之间建立一个 contract 边界。client 模块和子模块之间的任何值流动由 contract 管理。子模块内部的任何值流动都无受任何约束。

@codebox0[#:label "graph-traversal.rkt"
 (racketmod0
 racket
 ...
 (module traversal racket
   (provide
    (contract-out
     (find-path (-> graph? node? node? (option/c path?)))))

   (require (submod ".." graph) (submod ".." contract))

   (define (find-path G s d (visited history0))
     (cond
       [(node=? s d) '()]
       [(been-here? s visited) #f]
       [else (define neighbors (node-neighbors G s))
             (define there (record s visited))
             (define path (find-path* G neighbors d there))
             (if path (cons s path) #f)]))

   (define (find-path* G s* d visited)
     (cond
       [(empty? s*) #f]
       [else (or (find-path G (first s*) d visited)
                 (find-path* G (rest s*) d visited))]))

   (define (node-neighbors G n)
     (rest (assq n G))))

 (module+ test
   (require (submod ".." traversal) (submod ".." graph))
   (find-path G 'a 'd))
)]
@;%

由于模块和子模块不能互相递归地引用彼此，因此子模块 contract 边界不能对互相递归函数强制执行约束。因此，无法将上述代码显示中的 @racket[find-path] 和 @racket[find-path*] 函数分散到两个不同的子模块中。

