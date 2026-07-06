#lang scribble/base

@(require "shared.rkt"
          (for-label syntax/parse
                     racket/fixnum
                     racket/unsafe/ops))

@; -----------------------------------------------------------------------------

@title{语言与性能}

When you write a module, you first pick a language. In Racket you can
 choose a lot of languages. The most important choice concerns @rkt/base[]
 vs @rkt[].

For scripts, use @rkt/base[]. The @rkt/base[] language loads significantly
 faster than the @rkt[] language because it is much smaller than the
 @rkt[].

If your module is intended as a library, stick to @rkt/base[]. That way
 script writers can use it without incurring the overhead of loading all of
 @rkt[] unknowingly.

Conversely, you should use @rkt[] (or even @rkt/gui[]) when you just want a
 convenient language to write some program. The @rkt[] language comes with
 almost all the batteries, and @rkt/gui[] adds the rest of the GUI base.

@; -----------------------------------------------------------------------------
@section{Library Interfaces}

想象你正在开发一个库。你从一个模块开始，但在不知不觉中模块集合
已增长到相当大的规模。客户端程序不太可能使用你库的所有导出和模块。
如果默认情况下你的库包含所有特性，可能会造成不必要的心理负担和
客户端实际上并不使用的运行时代价。

在构建 Racket 语言的过程中，我们发现将库分解为不同层次是有用的，
这样客户端程序可以从这些包中有选择地导入。Racket 的具体做法是：
使用最显眼的名字作为包含所有特性的模块的默认名称。对于语言而言，
这 @rkt[] 的角色。希望依赖语言一小部分的程序员会选择 @rkt/base[]；
这个名称指代语言的基本基础。最后，有些 Racket 构造甚至不包含在
@rkt[] 中——例如 @racketmodname[racket/require]——必须在程序中
显式地 require。

其他 Racket 库选择使用小核心的默认名称。特殊名称则指代完整的库。

我们鼓励库开发者批判性地思考这些决定，并选择适合其品味以及对
库用户理解的做法。我们鼓励开发者在"大小"层次结构中使用以下名称：

@itemlist[

@item{@racket[library/kernel]，库可用的最低限度；}

@item{@racket[library/base]，基本功能集。}

@item{@racket[library]，对应于 @racket[library/base] 或 @racket[library/full]
的适当的"默认"功能集。}

@item{@racket[library/full], the full library functionality.}  
] 
在决定库的哪些部分应该包含在哪些文件中时，请记住两个考虑因素：
依赖关系和逻辑顺序。较小的文件应该依赖较少的依赖项。
尝试组织各层，以便原则上较大库可以根据较小库的公共接口来实现。

最后，关于在构建库时使用 @rkt/base[] 的建议可推广到其他库：
通过在依赖关系上更加明确，你就是一个负责任的贡献者，
并使他人的（传递）依赖集保持较小。

@; -----------------------------------------------------------------------------
@section{Macros: Space and Performance}

Macros copy code. Also, Racket is really a tower of macro-implemented
 languages. Hence, a single line of source code may expand into a rather
 large core expression. As you and others keep adding macros, even the
 smallest functions generate huge expressions and consume a lot of space.
 This kind of space consumption may affect the performance of your project
 and is therefore to be avoided.

When you design your own macro with a large expansion, try to factor it
 into a function call that consumes small thunks or procedures.

@compare0[
@racketmod0[
racket
...
(define-syntax (search s)
  (syntax-parse s
    [(_ x (e:expr ...)
        (~datum in)
        b:expr)
     #'(sar/λ (list e ...)
              (λ (x) b))]))

(define (sar/λ l p)
  (for/fold ([a '()]) ([y l])
    (unless (bad? y)
      (cons (p y) a))))

(define (bad? x)
  ... many lines ...)
]
@; -----------------------------------------------------------------------------
[racketmod0
racket
...
(define-syntax (search s)
  (syntax-parse s
    [(_ x (e:expr ...)
        (~datum in)
        b:expr)
     #'(begin
         (define (bad? x)
           ... many lines ...)
         (define l
           (list e ...))
         (for/fold ([a '()]) ([x l])
           (unless (bad? x)
             (cons b a))))]))
]
]

如你所见，左侧宏调用一个函数，参数是可搜索值的列表和封装了体的函数。
每次展开都是单个函数调用。相反，右侧宏每次使用时都会展开为许多
嵌套的定义和表达式。

@; -----------------------------------------------------------------------------
@section{No Contracts}

向库添加 contract 是有益的。

在某些情况下，contract 会带来显著的性能损失。
对于这种情况，建议将模块组织为一个常规模块和一个
@tt{no-contract} 子模块，使得
@itemlist[

@item{@tt{no-contract} 子模块 @racket[provide] @emph{无} contract 的功能，}
@item{主模块 @racket[provide] @emph{带} contract 的功能。}
]
本节解释针对三种不同情况和实现复杂度的三种策略。

@margin-note*{We will soon supply a Reference section in the Evaluation Model chapter that
explains the basics of our understanding of ``safety'' and link to it.}
@; 
@bold{警告} 将带 contract 的功能以这种方式拆分为两个模块会使
@tt{no-contract} 模块中的代码变得 @bold{unsafe}。
原始代码的作者可能假设了对某些函数参数的约束，而 contract 会检查这些约束。
虽然 @tt{no-contract} 子模块的文档可能会说明这些约束，但检查它们的责任
留给了客户端。如果客户端代码不检查这些约束，且参数不满足它们，
@tt{no-contract} 子模块中的代码可能会以各种方式出错。

创建 @tt{no-contract} 子模块的第一种最简单的方法是使用
@racket[contract-out] 的 @racket[#:unprotected-submodule] 功能。

@compare0[#:right "fast"
@;%
(racketmod0
 racket

 (define state? zero?)
 (define action? odd?)
 (define strategy/c
   (-> state? action?))

 (provide
  (contract-out
   [human strategy/c]
   [ai strategy/c]))


 (code:comment2 #, @1/2-line[])
 (code:comment2 #, @t{implementation})

 (define (general p)
   (lambda (_) pi))

 (define (human x)
   ((general 'gui) x))

 (define (ai x)
   ((general 'tra) x)))

(racketmod0
 racket

 (define state? zero?)
 (define action? odd?)
 (define strategy/c
   (-> state? action?))

 (provide
  (contract-out (code:hilite (code:line
   #:unprotected-submodule no-contract))
   [human strategy/c]
   [ai strategy/c]))

 (code:comment2 #, @1/2-line[])
 (code:comment2 #, @t{implementation})

 (define (general s)
   (lambda (_) pi))

 (define (human x)
   ((general 'gui) x))

 (define (ai x)
   ((general 'tra) x)))
]

名为 @tt{good} 的模块说明了代码最初的样子。每个导出的函数都附带 contract，
这些函数的定义可以在模块体中 @racket[provide] 规范的下方找到。
右侧的 @tt{fast} 模块请求创建一个名为 @tt{no-contract} 的子模块，
该子模块导出与原始模块相同的标识符但没有 contract。

子模块一旦存在，带或不带 contract 使用该库就很简单了：
@compare0[#:left "needs-goodness" #:right "needs-speed"
@;%
(racketmod0
 racket

 (require "fast.rkt")

 human
 (code:comment2 #, @elem{comes with contracts})
 (code:comment2 #, @elem{as if we had required })
 (code:comment2 #, @elem{"good.rkt" itself})

 (define state1 0)
 (define state2 
   (human state1)))

@(begin
#reader scribble/comment-reader
(racketmod0
 racket

 (require (submod "fast.rkt" no-contract))

 human
 (code:comment2 #, @elem{comes without})
 (code:comment2 #, @elem{a contract})

 (define state* 
   (build-list 0 1))
 (define action*
   (map human state*))))
]
两个模块都 @racket[require] @tt{fast} 模块，但左侧的 @tt{needs-goodness}
通过带 contract 的 @racket[provide]，而右侧的 @tt{needs-speed} 使用
@tt{no-contract} 子模块。从技术上讲，左侧模块带 contract 导入 @racket[human]；
右侧不带 contract 导入同一函数，因此不必付出性能代价。

然而请注意，当你运行这两个客户端模块时——假设你将它们以
正确的名称保存在某个文件夹中——左侧模块会引发 contract 错误，
而右侧模块将 @racket[action*] 绑定到

@;%
@(begin
#reader scribble/comment-reader
(racketresult
'(3.141592653589793 3.141592653589793)
))
@;%

通过这种第一种简单方法生成的 @tt{no-contract} 子模块在编译和运行时都保留
对 @racketmodname[#, 'racket/contract] 的依赖。
Here is a variant of the above module that demonstrates this point: 
@;%
@(racketmod0 #:file
 @tt{problems-with-unprotected-submodule}
 racket

(define state? zero?)
(define action? odd?)
(define strategy/c (-> state? action?))

(provide
 (contract-out
  #:unprotected-submodule no-contract
  [human strategy/c]
  [ai strategy/c]))

(define (general p) pi)

(define human (general 'gui))

(define ai (general 'tra)))
@;%
即使 @racket[contract-out] 规范似乎移除了 contract，require @tt{no-contract}
仍然引发 contract 错误：
@;%
@(racketblock
(require (submod "." server no-contract))
)
@;%
@bold{解释} @tt{no-contract} 子模块依赖于主模块，因此 require 运行主模块的体，
这样做会检查导出值的一阶属性。由于 @racket[human] 不是函数，该求值引发 contract 错误。

创建 @tt{no-contract} 子模块的第二种方法需要开发者系统性的工作，
并消除了对 @racketmodname[#, 'racket/contract] 的运行依赖。 Here are the two modules from
above, with the right one derived manually from the one on the left: 
@compare0[#:left "good2" #:right "fast2"
@;%
(racketmod0
 racket

 (define state? zero?)
 (define action? odd?)
 (define strategy/c
   (-> state? action?))

 (provide
  (contract-out
   [human strategy/c]
   [ai strategy/c]))

 (code:comment2 #, @1/2-line[])
 (code:comment2 #, @t{implementation})

 (define (general p)
   (lambda (_) pi))

 (define (human x)
   ((general 'gui) x))

 (define (ai x)
   ((general 'tra) x)))

(racketmod0
 racket 

 (define state? zero?)
 (define action? odd?)
 (define strategy/c
   (-> state? action?))

 (provide
  (contract-out
   [human strategy/c]
   [ai strategy/c]))

 (code:comment2 #, @1/2-line[])
 (code:comment2 #, @t{implementation})

 (module no-contract racket 
   (provide 
    human
    ai)

   (define (general s)
     (lambda (_) pi))

   (define (human x)
     ((general 'gui) x))

   (define (ai x)
     ((general 'tra) x)))

 (require 'no-contract)
)
]
右侧的 @tt{fast2} 模块将定义封装在名为 @tt{no-contract} 的子模块中；
该子模块中的 @racket[provide] 导出与左侧 @tt{good2} 模块完全相同的标识符。
主模块立即 @racket[require] 该子模块，使标识符在外层作用域中可用，
以便带 contract 的 @code{provide} 可以重新导出它们。

虽然这种创建 @tt{no-contract} 子模块的第二种方法消除了
对 @racketmodname[#, 'racket/contract] 的运行依赖，但它的编译——
作为外部模块的一部分——仍然依赖于该库，这在少数剩余情况下是有问题的。

创建 @tt{no-contract} 子模块的第三种也是最后一种方法在 contract 阻止
模块在完全没有任何 contract 的环境中编译和运行时很有用——既没有编译时
也没有运行时。一个例子是 @rkt/base[]；另一个例子是 contract 库本身。
同样，你可能希望不带 contract。对于这些情况，我们推荐基于文件的策略。
假设库位于 @tt{a/b/c}，我们推荐

@itemlist[#:style 'ordered

@item{创建一个包含 @tt{no-contract.rkt} 文件的 @tt{c/} 子目录，}

@item{将功能放入 @tt{no-contract.rkt}，}

@item{将 @racket[(require "c/no-contract.rkt")] 添加到 @tt{c.rkt}，}

@item{从那里导出并为其添加 contract。}

]

一旦这种安排就位，在特殊环境 @rkt/base[] 中或用于
@racketmodname[#, 'racket/contract] 的客户端模块可以使用
@racket[(require a/b/c/no-contract)]。不过，在普通模块中只需编写
@racket[(require a/b/c)]，这样做会导入带 contract 的标识符。

@; -----------------------------------------------------------------------------
@section{Unsafe: Beware}

Racket 提供许多 unsafe 操作，它们的行为类似于相关的安全变体，
但仅在给定有效输入时。它们的不同之处在于，由于性能原因省略了检查，
因此在无效输入上的行为不可预测。

举一个例子，考虑 @racket[fx+] 和 @racket[unsafe-fx+]。
当 @racket[fx+] 应用于非 @racket[fixnum?] 时，它引发一个错误。
相反，当 @racket[unsafe-fx+] 应用于非 @racket[fixnum?] 时，它不会引发错误。
相反，它要么返回一个可能违反运行时系统不变量的奇怪结果，
可能导致后续操作（如输出该值）使 Racket 崩溃。

不要在你的程序中使用 unsafe 操作，除非你在编写证明 unsafe 操作
只接收有效输入的软件（如 Typed Racket 这样的类型系统），或者
你在构建一个总是在紧靠 unsafe 操作的位置插入正确检查的抽象
（如 @racket[for] 这样的宏）。即使在这些情况下，除非你已做了仔细的
性能分析来确保性能提升超过使用 unsafe 操作的风险，否则也要避免
使用 unsafe 操作。
