#lang scribble/manual
@(require scribble/manual
          scribble/examples
          "guide-utils.rkt")

@(define visit-eval (make-base-eval))

@examples[
#:hidden
#:eval visit-eval
(current-pseudo-random-generator (make-pseudo-random-generator))
;; Make the output deterministic:
(random-seed 11)
]

@title[#:tag "macro-module"]{模块的实例化与访问}

模块通常只包含函数和结构体类型定义，此时模块本身以纯函数方式运行，
函数的创建时间不可观测。然而，如果模块的顶层表达式包含副作用，
那么副作用的时机就很重要。模块声明与 @tech{instantiation} 之间的
区别提供了一种控制该时机的手段。模块 @tech{visits} 的概念则进一步
解释了副作用与宏实现之间的交互。

@; ----------------------------------------
@section{Declaration versus Instantiation}

声明模块并不会立即求值模块体中的表达式。例如，求值

@examples[
#:label #f
#:eval visit-eval
(module number-n racket/base
  (provide n)
  (define n (random 10))
  (printf "picked ~a\n" n))
]

声明了模块 @racket[number-n]，但并不会立即为 @racket[n] 选取随机数
或显示该数。@racket[require] @racket[number-n] 会导致模块被 @deftech{instantiated}
（即触发 @deftech{instantiation}），这意味着模块体中的表达式会被求值：

@examples[
#:label #f
#:eval visit-eval
(require 'number-n)
n
]

在特定 @tech{namespace} 中实例化模块后，后续对该模块的 @racket[require]
会使用同一实例，而非再次实例化：

@examples[
#:label #f
#:eval visit-eval
(require 'number-n)
n
(module use-n racket/base
  (require 'number-n)
  (printf "still ~a\n" n))
(require 'use-n)
]

@racket[dynamic-require] 函数与 @racket[require] 类似，当模块尚未实例化时
会触发其实例化，因此将 @racket[#f] 作为第二个参数传给 @racket[dynamic-require]
可用于仅触发模块的实例化副作用：

@examples[
#:label #f
#:eval visit-eval
(module use-n-again racket/base
  (require 'number-n)
  (printf "also still ~a\n" n))
(dynamic-require ''use-n-again #f)
]

Instantiation of modules by @racket[require] is transitive. That is,
if @racket[require] of a module instantiates it, then any module
@racket[require]d by that one is also instantiated (if it's not
instantiated already):

@examples[
#:label #f
#:eval visit-eval
(module number-m racket/base
  (provide m)
  (define m (random 10))
  (printf "picked ~a\n" m))
(module use-m racket/base
  (require 'number-m)
  (printf "still ~a\n" m))
(require 'use-m)
]

@; ----------------------------------------
@section[#:tag "compile-time-instantiation"]{Compile-Time Instantiation}

正如声明模块本身不会实例化模块一样，声明一个 @racket[require] 了其他模块的
模块本身也不会实例化被 @racket[require] 的模块，如前面的例子所示。然而，
声明模块 @emph{会} 展开并编译该模块。如果模块通过 @racket[(require (for-syntax ....))]
导入另一个模块，那么被 @racket[for-syntax] 导入的模块必须在展开期间被实例化：

@examples[
#:label #f
#:eval visit-eval
#:escape UNSYNTAX
(module number-p racket/base
  (provide p)
  (define p (random 10))
  (printf "picked ~a\n" p))
(module use-p-at-compile-time racket/base
  (require (for-syntax racket/base
                       'number-p))
  (define-syntax (pm stx)
    #`#,p)
  (printf "was ~a at compile time\n" (pm)))
]

与命名空间中的运行时实例化不同，当模块在同一个命名空间中被
@racket[for-syntax] 用于另一个模块的展开时，被 @racket[for-syntax] 的模块
会针对每次展开分别实例化。继续前面的例子，如果 @racket[number-p] 第二次被
@racket[for-syntax] 使用，那么会为新的 @racket[p] 选取第二个随机数：

@examples[
#:label #f
#:eval visit-eval
#:escape UNSYNTAX
(module use-p-again-at-compile-time racket/base
  (require (for-syntax racket/base
                       'number-p))
  (define-syntax (pm stx)
    #`#,p)
  (printf "was ~a at second compile time\n" (pm)))
]

@racket[number-p] 的分别编译时实例化有助于防止副作用从一个模块的编译
意外传播到另一个模块的编译。阻止这些效果使得编译可靠地分离且更具确定性。

@racket[use-p-at-compile-time] 和 @racket[use-p-again-at-compile-time] 的展开形式
记录了每次选取的数，因此当模块被实例化时，这两个不同的数会被打印出来：

@examples[
#:label #f
#:eval visit-eval
(dynamic-require ''use-p-at-compile-time #f)
(dynamic-require ''use-p-again-at-compile-time #f)
]

命名空间的顶层行为类似于一个单独的模块，顶层中的多次交互在概念上扩展了
模块的单一展开。因此，在顶层两次使用 @racket[(require (for-syntax ....))] 时，
第二次使用不会触发新的编译时实例：

@examples[
#:label #f
#:eval visit-eval
(begin (require (for-syntax 'number-p)) 'done)
(begin (require (for-syntax 'number-p)) 'done-again)
]

然而，模块的运行时实例与所有编译时实例保持分离（包括顶层），因此
非 @racket[for-syntax] 使用 @racket[number-p] 会选取另一个随机数：

@examples[
#:label #f
#:eval visit-eval
(require 'number-p)
]

@; ----------------------------------------
@section{Visiting Modules}

当模块 @racket[provide] 一个宏供其他模块使用时，其他模块通过直接
@racket[require] 宏提供者来使用该模块——即不使用 @racket[for-syntax]。
这是因为宏被导入用于运行时位置（即使宏的实现存在于编译时），而
@racket[for-syntax] 会导入一个绑定用于编译时位置。

同时，实现宏的模块可能会 @racket[require] 另一个模块 @racket[for-syntax]
来实现该宏。@racket[for-syntax] 模块在任何可能使用该宏的模块展开期间
需要编译时实例化。这一要求通过 @racket[require] 建立了一种传递性，
类似于实例化传递性，但在链中 @racket[for-syntax] 转换发生的点处"错开一位"。

以下是一个使该场景具体化的例子：

@examples[
#:label #f
#:eval visit-eval
#:escape UNSYNTAX
(module number-q racket/base
  (provide q)
  (define q (random 10))
  (printf "picked ~a\n" q))
(module use-q-at-compile-time racket/base
  (require (for-syntax racket/base
                       'number-q))
  (provide qm)
  (define-syntax (qm stx)
    #`#,q)
  (printf "was ~a at compile time\n" (qm)))
(module use-qm racket/base
  (require 'use-q-at-compile-time)
  (printf "was ~a at second compile time\n" (qm)))
(dynamic-require ''use-qm #f)
]

在此例中，当 @racket[use-q-at-compile-time] 被展开和编译时，
@racket[number-q] 被实例化一次。在这种情况下，该实例化是为了展开
@racket[(qm)] 宏，但即使 @racket[qm] 宏最终未被使用，模块系统也会
主动创建 @racket[number-q] 的编译时实例。

然后，当 @racket[use-qm] 被展开和编译时，@racket[number-q] 的第二个
编译时实例被创建。该编译时实例是为了展开 @racket[use-qm] 中的
@racket[(qm)] 形式。

实例化 @racket[use-qm] 正确报告了在第二个模块编译期间选取的数。不过，
首先 @racket[use-qm] 中对 @racket[use-q-at-compile-time] 的 @racket[require]
触发了 @racket[use-q-at-compile-time] 的传递实例化，后者正确报告了
在其编译期间选取的数。

总体而言，该例子说明了我们之前已经见过的 @racket[require] 的传递效果：

@itemlist[

 @item{当模块被 @tech{instantiated} 时，其体中的运行时表达式被求值。}

 @item{当模块被 @tech{instantiated} 时，它 @racket[require] 的任何模块
            （不使用 @racket[for-syntax]）也会被 @tech{instantiated}。}

]

然而，该规则无法解释 @racket[number-q] 的编译时实例化。为了解释这一点，
我们需要一个词——@deftech{visit}——来表示我们在 @secref["compile-time-instantiation"]
中看到的概念：

@itemlist[

@item{当模块被 @tech{visit} 时，其体中的编译时表达式（如宏定义）被求值。}

@item{当模块被展开时，它被 @tech{visit}。}

@item{当模块被 @tech{visit} 时，它 @racket[require] 的任何模块
            （不使用 @racket[for-syntax]）也会被 @tech{visit}。}

@item{当模块被 @tech{visit} 时，它 @racket[require] @racket[for-syntax]
           的任何模块在编译时被 @tech{instantiated}。}

]

注意，当一个模块的访问导致另一个模块的编译时实例化时，@tech{instantiation}
通过普通 @racket[require] 的传递性可能触发更多编译时实例化。然而，
实例化本身不会触发进一步的访问，因为任何已实例化的模块都已被展开和编译。

模块中通过 @tech{visit} 求值的编译时表达式包括 @racket[define-syntax] 形式的
右侧以及 @racket[begin-for-syntax] 形式的体。这就是为什么在以下例子中
随机选取的数会立即被打印出来：

@examples[
#:label #f
#:eval visit-eval
(module compile-time-number racket/base
  (require (for-syntax racket/base))
  (begin-for-syntax
    (printf "picked ~a\n" (random)))
  (printf "running\n"))
]

实例化模块仅求值运行时表达式，这会打印"running"但不会打印新的随机数：

@examples[
#:label #f
#:eval visit-eval
(dynamic-require ''compile-time-number #f)
]

The description of @tech{instantiates} and @tech{visit} above is
phrased in terms of normal @racket[require]s and @racket[for-syntax]
@racket[require]s, but a more precise specification is in terms of
module phases. For example, if module @racket[_A] has @racket[(require
(for-syntax _B))] and module @racket[_B] has @racket[(require
(for-template _C))], then module @racket[_C] is @tech{instantiated}
when module @racket[_A] is instantiated, because the
@racket[for-syntax] and @racket[for-template] shifts cancel. We have
not yet specified what happens with @racket[for-meta 2] for when
@racket[for-syntax]es combine; we leave that to the next section,
@secref["stx-available-module"].

If you think of the top-level as a kind of module that is continuously
expanded, the above rules imply that @racket[require] of another
module at the top level both instantiates and visits the other module
(if it is not already instantiated and visited). That's roughly true,
but the visit is made lazy in a way that is also explained in the next
section, @secref["stx-available-module"].

同时，@racket[dynamic-require] 仅实例化模块；它不会访问模块。这一简化
是前面一些例子使用 @racket[dynamic-require] 而非 @racket[require] 的原因。
顶层 @racket[require] 的额外访问会使前面的例子不够清晰。

@; ----------------------------------------
@section[#:tag "stx-available-module"]{Lazy Visits via Available Modules}

顶层 @racket[require] 一个模块实际上并不会 @tech{visit} 该模块。相反，
它使模块 @deftech{available}。@tech{available} 模块将在同一上下文中需要
展开未来表达式时被 @tech{visit}。下一个表达式可能涉及也可能不涉及需要
通过 @tech{visit} 求值其编译时辅助工具的导入宏，但模块系统会主动
@tech{visit} 该模块，以防万一。

在以下例子中，当模块正在展开时，访问模块自身的体导致选取一个随机数。
@racket[require] 该模块会实例化它，打印"running"，同时使模块
@tech{available}。求值任何其他表达式意味着展开该表达式，而该展开会
触发 @tech{available} 模块的 @tech{visit}——从而选取另一个随机数：

@examples[
#:label #f
#:eval visit-eval
(module another-compile-time-number racket/base
  (require (for-syntax racket/base))
  (begin-for-syntax
    (printf "picked ~a\n" (random)))
  (printf "running\n"))
(require 'another-compile-time-number)
'next
'another
]

@margin-note[#:footnote? #t]{Beware that the expander flattens the content of a
top-level @racket[begin] into the top level as soon as the
@racket[begin] is discovered. So, @racket[(begin (require
'another-compile-time-number) 'next)] would still have printed
``picked'' before ``next``.}

对 @racket['another] 的最终求值也会访问任何可用模块，但仅求值
@racket['next] 并不会使任何模块变为新可用。

当模块使用 @racket[for-meta _n]（其中 @racket[_n] 大于 1）@racket[require]
另一个模块时，被 @racket[require] 的模块在阶段 @racket[_n] 被设为
@tech{available}。在阶段 @racket[_n] @tech{available} 的模块会在阶段
@math{@racket[_n]-1} 的某个表达式被展开时被 @tech{visit}。

为了便于说明，以下例子使用
@racket[(variable-reference->module-base-phase
(#%variable-reference))]，它返回一个表示封闭模块被实例化时的阶段的数：


@examples[
#:label #f
#:eval visit-eval
(module show-phase racket/base
  (printf "running at ~a\n"
          (variable-reference->module-base-phase (#%variable-reference))))
(require 'show-phase)
(module use-at-phase-1 racket/base
  (require (for-syntax 'show-phase)))
(module unused-at-phase-2 racket/base
  (require (for-meta 2 'show-phase)))
]

对于上面的最后一个模块，@racket[show-phase] 在阶段 2 被设为 @tech{available}，
但模块内的任何表达式都不会在阶段 1 被展开，因此没有阶段 2 的打印输出。
以下模块在阶段 2 @racket[require] 之后包含一个阶段 1 的表达式，
因此有打印输出：

@examples[
#:label #f
#:eval visit-eval
(module use-at-phase-2 racket/base
  (require (for-meta 2 'show-phase)
           (for-syntax racket/base))
  (define-syntax x 'ok))
]

如果我们在顶层 @racket[require] 模块 @racket[use-at-phase-1]，那么
@racket[show-phase] 在阶段 1 被设为 @tech{available}。求值另一个表达式
会导致 @racket[use-at-phase-1] 被 @tech{visit}，从而实例化 @racket[show-phase]：

@examples[
#:label #f
#:eval visit-eval
(require 'use-at-phase-1)
'next
]

@racket[require] @racket[use-at-phase-2] 的情况类似，不同之处在于
@racket[show-phase] 在阶段 2 被设为 @tech{available}，因此直到某个表达式
在阶段 1 被展开时才会被实例化：

@examples[
#:label #f
#:eval visit-eval
(require 'use-at-phase-2)
'next
(require (for-syntax racket/base))
(begin-for-syntax 'compile-time-next)
]

@; ----------------------------------------------------------------------

@close-eval[visit-eval]
