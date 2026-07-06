#lang scribble/manual
@(require scribble/manual
          scribble/eval
          "guide-utils.rkt"
          (for-label syntax/parse))

@title[#:tag "phases"]{通用阶段层级}

@deftech{Phase}（阶段）可以看作是在处理流水线中分离计算的一种方式，
其中前一个阶段生成的代码被后一个阶段使用。（例如，由预处理器、
编译器、汇编器组成的流水线。）

想象为了这个目的启动两个 Racket 进程。如果忽略 socket 和文件等
进程间通信通道，这两个进程除了将一个进程的标准输出通过管道送入
另一个进程的标准输入之外，没有任何其他共享方式。类似地，Racket 允
许多个 module 的 invocation 存在于同一个进程中，但是通过 phase 相互
分离。Racket 强制对这些 phase 进行 @emph{separation}（分离）：不同
阶段之间除 macro expansion 协议外无法以任何方式通信，即一个阶段的
输出被用作下一阶段的代码。

@section{Phase 与 Binding}

每个 binding 都存在于一个特定的 phase。binding 与 phase 之间的关联由一个整数 @deftech{phase level} 来表示。Phase level 0 是用于 ``平面''（或 ``运行时''）definition 的 phase，因此

@racketblock[
(define age 5)
]

将 @racket[age] 的 binding 添加到 phase level 0 中。
identifier @racket[age] 可以通过 @racket[begin-for-syntax] 在更高的 phase level 上定义：

@racketblock[
(begin-for-syntax
  (define age 5))
]

通过对单个 @racket[begin-for-syntax] 的包裹，@racket[age] 在 phase level 1 上被定义。
我们可以在同一个 module 中或顶层 namespace 中自由混合这两种定义，
并且不同 phase level 上定义的两个 @racket[age] 之间不会产生冲突：

@(define age-eval (make-base-eval))
@(interaction-eval #:eval age-eval (require (for-syntax racket/base)))

@interaction[#:eval age-eval
(define age 3)
(begin-for-syntax
  (define age 9))
]

Phase level 0 上的 @racket[age] binding 的值是 3，phase level 1 上的 @racket[age] binding 的值是 9。

Syntax object 将 binding 信息作为 first-class value 捕获。
因此，

@racketblock[#'age]

是一个代表 @racket[age] binding 的 syntax object —— 但是因为有两个
@racket[age]（一个在 phase level 0，一个在 phase level 1），它捕获的是哪一个？
实际上，Racket 为 @racket[#'age] 注入了所有 phase level 的 lexical 信息，
所以答案就是：@racket[#'age] 同时捕获了两个。

@racket[#'age] 捕获的 @racket[age] 相关 binding 是在 @racket[#'age]
最终被使用时确定的。例如，我们将 @racket[#'age] 绑定到一个 pattern variable，
以便在 template 中使用它，然后 @racket[eval]uate 该 template：
@margin-note*{我们这里使用 @racket[eval] 是为了演示 phase，但是关于 @racket[eval] 的注意事项请参考 @secref["reflection"]。}

@interaction[#:eval age-eval
(eval (with-syntax ([age #'age])
        #'(displayln age)))
]

结果是 @racket[3]，因为 @racket[age] 在 phase 0 level 被使用。
我们可以在 @racket[begin-for-syntax] 内部再次尝试使用 @racket[age]：

@interaction[#:eval age-eval
(eval (with-syntax ([age #'age])
        #'(begin-for-syntax
            (displayln age))))
]

在这种情况下，结果是 @racket[9]，因为我们在 phase level 1 使用
@racket[age] 而不是 phase level 0（即 @racket[begin-for-syntax]
在 phase level 1 上对其 expression 求值）。所以可以看到，我们从同一个
syntax object @racket[#'age] 开始，却能够在两种不同的方式下使用它：
在 phase level 0 和在 phase level 1。

Syntax object 从它首次存在时就具有 lexical context。从一个 module
提供的 syntax object 保留其 lexical context，因此它引用的是其源 module
上下文中的 binding，而不是使用它的上下文中的 binding。下面的例子在
phase level 0 上定义 @racket[button] 并将其绑定到 @racket[0]，而
@racket[see-button] 绑定的是 module @racket[a] 中 @racket[button]
的 syntax object：

@interaction[
(module a racket
  (define button 0)
  (provide (for-syntax see-button))
  @code:comment[@#,t{Why not @racket[(define see-button #'button)]? We explain later.}]
  (define-for-syntax see-button #'button))

(module b racket
  (require 'a)
  (define button 8)
  (define-syntax (m stx)
    see-button)
  (m))

(require 'b)
]

@racket[m] macro 的结果是 @racket[see-button] 的值，也就是带有
@racket[a] module 的 lexical context 的 @racket[#'button]。即使在
@racket[b] 中有另一个 @racket[button]，第二个 @racket[button]
也不会让 Racket 困惑，因为 @racket[#'button]（绑定到
@racket[see-button] 的值）的 lexical context 是 @racket[a]。

注意 @racket[see-button] 通过 @racket[define-for-syntax] 定义，
因此绑定在 phase level 1 上。需要 phase level 1 是因为 @racket[m]
是一个 macro，所以它的 body 比它的定义 context 高一 phase 执行。
既然 @racket[m] 在 phase level 0 上定义，它的 body 就在 phase level 1
上，因此 body 引用的任何 binding 都必须在 phase level 1 上。

@; ======================================================================

@section{Phase 与 Module}

@tech{Phase level} 是一个相对 module 的概念。当通过 @racket[require]
从另一个 module 导入时，Racket 允许我们将导入的 binding 平移到与原始
phase level 不同的 phase level：

@racketblock[
(require "a.rkt")                @code:comment{import with no phase shift}
(require (for-syntax "a.rkt"))   @code:comment{shift phase by +1}
(require (for-template "a.rkt")) @code:comment{shift phase by -1}
(require (for-meta 5 "a.rkt" ))  @code:comment{shift phase by +5}
]

也就是说，在 @racket[require] 中使用 @racket[for-syntax] 意味着
该 module 中所有 binding 的 phase level 都会增加一。在 phase level 0 上
@racket[define]d 并在 @racket[for-syntax] 导入下，binding 变为 phase level
1 的 binding：

@interaction[
(module c racket
  (define x 0) @code:comment{defined at phase level 0}
  (provide x))

(module d racket
  (require (for-syntax 'c))
  @code:comment{has a binding at phase level 1, not 0:}
  #'x)
]

现在来看看如果我们在 phase level 0 尝试为 @racket[#'button] syntax object
创建 binding 会发生什么：

@(define button-eval (make-base-eval))
@(interaction-eval #:eval button-eval
                   (require (for-syntax racket/base)))
@interaction[#:eval button-eval
(define button 0)
(define see-button #'button)
]

@racket[button] 和 @racket[see-button] 现在都在 phase 0 上定义。
@racket[#'button] 的 lexical context 会知道 phase 0 上有 @racket[button]
的 binding。事实上，如果我们 @racket[eval] @racket[see-button]，看起来
一切正常：

@interaction[#:eval button-eval
(eval see-button)
]

现在，让我们在 macro 中使用 @racket[see-button]：

@interaction[#:eval button-eval
(define-syntax (m stx)
  see-button)
(m)
]

显然，@racket[see-button] 没有在 phase level 1 定义，因此我们
不能在 macro body 内部引用它。让我们尝试在另一个 module 中
使用 @racket[see-button]，将 button definition 放在 module 中，
以 phase level 1 导入它。然后我们将得到 phase level 1 上的
@racket[see-button]：

@interaction[
(module a racket
  (define button 0)
  (define see-button #'button)
  (provide see-button))

(module b racket
  (require (for-syntax 'a)) @code:comment[@#,t{gets @racket[see-button] at phase level 1}]
  (define-syntax (m stx)
    see-button)
  (m))
]

Racket 说现在 @racket[button] 没有绑定！当 @racket[a] 以 phase level 1
导入时，我们有以下 binding：

@racketblock[
button     @#,elem{at phase level 1}
see-button @#,elem{at phase level 1}
]

所以 macro @racket[m] 能看到 phase level 1 上 @racket[see-button] 的
binding 并返回 @racket[#'button] syntax object，而它引用的是 phase level 1
上的 @racket[button] binding。但是 @racket[m] 的使用处是 phase level 0，
而 @racket[b] 中 phase level 0 上没有 @racket[button]。这就是为什么
@racket[see-button] 需要像在原始 @racket[a] 中那样绑定在 phase level 1 上。
在原始的 @racket[b] 中，我们有以下 binding：

@racketblock[
button     @#,elem{at phase level 0}
see-button @#,elem{at phase level 1}
]

在这个场景中，我们可以在 macro 中使用 @racket[see-button]，因为
@racket[see-button] 绑定在 phase level 1 上。当 macro 展开时，
它将引用 phase level 0 上的 @racket[button] binding。

用 @racket[(define see-button #'button)] 定义 @racket[see-button]
本身并没有错；这取决于我们打算如何使用 @racket[see-button]。例如，
我们可以安排 @racket[m] 合理地使用 @racket[see-button]，因为它通过
@racket[begin-for-syntax] 将其放在 phase level 1 的 context 中：

@interaction[
(module a racket
  (define button 0)
  (define see-button #'button)
  (provide see-button))

(module b racket
  (require (for-syntax 'a))
  (define-syntax (m stx)
    (with-syntax ([x see-button])
      #'(begin-for-syntax
          (displayln x))))
  (m))
]

在这种情况下，module @racket[b] 中 @racket[button] 和
@racket[see-button] 都绑定在 phase level 1 上。macro 的展开是

@racketblock[
(begin-for-syntax
  (displayln button))
]

这能工作，因为 @racket[button] 绑定在 phase level 1 上。

现在，你可能会试图通过在 phase level 0 和 phase level 1 同时导入
@racket[a] 来绕过 phase 系统。然后你会有以下 binding

@racketblock[
button     @#,elem{at phase level 0}
see-button @#,elem{at phase level 0}
button     @#,elem{at phase level 1}
see-button @#,elem{at phase level 1}
]

你可能现在会期望 macro 中的 @racket[see-button] 能工作，但它不能：

@interaction[
(module a racket
  (define button 0)
  (define see-button #'button)
  (provide see-button))

(module b racket
  (require 'a
           (for-syntax 'a))
  (define-syntax (m stx)
    see-button)
  (m))
]

在 module @racket[a] 的定义中，变量 @racket[see-button] 在 phase 0 上，
它的值是 @racket[button] 的 syntax object，显示唯一可见的 @racket[button]
binding 在同一个 phase 上。（这是关键细节。）如前所述，@racket[for-syntax]
导入将 @emph{两者} 的 phase level 都向上移动一，所以在 module @racket[b]
中使用的 @racket[see-button] 的 phase 1 binding 是来自 module @racket[a]
被平移到 phase 1 的 binding，它引用的是 @racket[a] 中 phase 1 上的
@racket[button]。在 module @racket[b] 中还有来自 module @racket[a] 不同
instantiation 的 phase 0 变量 @racket[button] 这一事实并不重要，因为
无法从 @racket[a] 的（已平移的）@racket[see-button] 到达它。

这种 instantiation 之间的 phase level mismatch 可以通过
@racket[syntax-shift-phase-level] 来修复。回想一下，像 @racket[#'button]
这样的 syntax object 在 @emph{所有} phase level 上捕获 lexical 信息。
这里的问题是 @racket[see-button] 在 phase 1 被调用，但需要返回一个
能在 phase 0 上求值的 syntax object。默认情况下，@racket[see-button]
绑定到同一 phase level 上的 @racket[#'button]。但通过
@racket[syntax-shift-phase-level]，我们可以让 @racket[see-button]
引用不同相对 phase level 上的 @racket[#'button]。在这种情况下，
我们使用 @racket[-1] 的 phase shift 让 phase 1 上的 @racket[see-button]
引用 phase 0 上的 @racket[#'button]。（因为 phase shift 发生在每个
level 上，它也会让 phase 0 上的 @racket[see-button] 引用 phase -1
上的 @racket[#'button]。）

注意 @racket[syntax-shift-phase-level] 只是创建一个跨 phase 的
reference。要让这个 reference 能工作，我们仍然需要在两个 phase 上
instantiate 我们的 module，使得 reference 和它的 target 都有可用的
binding。因此，在 module @racket['b] 中，我们仍然在 phase 0 和
phase 1 上导入 module @racket['a]——使用 @racket[(require 'a (for-syntax 'a))]——
这样我们就有 phase 1 上 @racket[see-button] 的 binding 和 phase 0 上
@racket[button] 的 binding。现在 macro @racket[m] 就能工作了。

@interaction[
(module a racket
  (define button 0)
  (define see-button (syntax-shift-phase-level #'button -1))
  (provide see-button))

(module b racket
  (require 'a (for-syntax 'a))
  (define-syntax (m stx)
    see-button)
  (m))

(require 'b)
]

顺便说一下，绑定在 phase 0 上的 @racket[see-button] 会怎样？它的
@racket[#'button] binding 同样被平移了，但移到了 phase -1。由于
@racket[button] 本身在 phase -1 上没有绑定，如果我们尝试在 phase 0
上求值 @racket[see-button]，就会得到一个 error。换句话说，我们并没有
永久修复我们的 mismatch 问题——只是把它移到了一个不那么烦人的位置。

@interaction[
(module a racket
  (define button 0)
  (define see-button (syntax-shift-phase-level #'button -1))
  (provide see-button))

(module b racket
  (require 'a (for-syntax 'a))
  (define-syntax (m stx)
    see-button)
  (m))

(module b2 racket
  (require 'a)
  (eval see-button))

(require 'b2)
]

类似上面的 mismatch 也会在 macro 尝试匹配 literal binding 时出现——
使用 @racket[syntax-case] 或 @racket[syntax-parse]。

@interaction[
(module x racket
  (require (for-syntax syntax/parse)
           (for-template racket/base))

  (provide (all-defined-out))

  (define button 0)
  (define (make) #'button)
  (define-syntax (process stx)
    (define-literal-set locals (button))
    (syntax-parse stx
      [(_ (n (~literal button))) #'#''ok])))

(module y racket
  (require (for-meta 1 'x)
           (for-meta 2 'x racket/base))

  (begin-for-syntax
    (define-syntax (m stx)
      (with-syntax ([out (make)])
        #'(process (0 out)))))

  (define-syntax (p stx)
    (m))

  (p))
]

在这个例子中，@racket[make] 在 @racket[y] 中的 phase level 2 被使用，
它返回 @racket[#'button] syntax object——引用的是 @racket[x] 内部 phase
level 0 上绑定的 @racket[button]，以及 @racket[y] 中来自
@racket[(for-meta 2 'x)] 的 phase level 2 上绑定的 @racket[button]。
@racket[process] macro 从 @racket[(for-meta 1 'x)] 在 phase level 1
被导入，它知道 @racket[button] 应该在 phase level 1 上绑定。当
@racket[syntax-parse] 在 @racket[process] 内部执行时，它在寻找 phase
level 1 上绑定的 @racket[button]，但只看到 phase level 2 的 binding，
所以不匹配。

为了修复这个例子，我们可以在相对于 @racket[x] 的 phase level 1 上
提供 @racket[make]，然后在 @racket[y] 中在 phase level 1 上导入它：

@interaction[
(module x racket
  (require (for-syntax syntax/parse)
           (for-template racket/base))

  (provide (all-defined-out))

  (define button 0)

  (provide (for-syntax make))
  (define-for-syntax (make) #'button)
  (define-syntax (process stx)
    (define-literal-set locals (button))
    (syntax-parse stx
      [(_ (n (~literal button))) #'#''ok])))

(module y racket
  (require (for-meta 1 'x)
           (for-meta 2 racket/base))

  (begin-for-syntax
    (define-syntax (m stx)
      (with-syntax ([out (make)])
        #'(process (0 out)))))

  (define-syntax (p stx)
    (m))

  (p))

(require 'y)
]

@(close-eval age-eval)
@(close-eval button-eval)
