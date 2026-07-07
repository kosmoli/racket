#lang scribble/manual
@(require scribble/manual
          scribble/eval
          "guide-utils.rkt"
          (for-label syntax/parse))

@title[#:tag "phases"]{General Phase Levels}

@deftech{phase}（阶段）可以被理解为在进程管道中分离计算的一种方式，其中一个进程产生由下一个进程使用的代码。（例如，由预处理器进程、编译器和汇编器组成的管道。）

想象一下为此目的启动两个 Racket 进程。如果忽略套接字和文件等进程间通信通道，这些进程将无法共享任何内容，除了从一个进程的标准输出通过管道传输到另一个进程标准输入的文本。类似地，Racket 实际上允许模块的多个调用存在于同一进程中但由阶段分隔。Racket 强制执行这些阶段的 @emph{分离}，不同阶段之间除了通过宏展开的协议外不能以任何方式通信，其中一个阶段的输出是下一个阶段使用的代码。

@section{Phases and Bindings}

标识符的每个绑定都存在于特定的阶段中。绑定与其阶段之间的联系由一个整数 @deftech{phase level}（阶段级别）表示。阶段级别 0 是用于"普通"（或"运行时"）定义的阶段，因此

@racketblock[
(define age 5)
]

将 @racket[age] 的绑定添加到阶段级别 0。标识符 @racket[age] 可以使用 @racket[begin-for-syntax] 在更高的阶段级别定义：

@racketblock[
(begin-for-syntax
  (define age 5))
]

使用单个 @racket[begin-for-syntax] 包装器，@racket[age] 被定义在阶段级别 1。我们可以轻松地在同一个模块或顶层命名空间中混合这两个定义，两个在不同阶段级别定义的 @racket[age] 之间不会冲突：

@(define age-eval (make-base-eval))
@(interaction-eval #:eval age-eval (require (for-syntax racket/base)))

@interaction[#:eval age-eval
(define age 3)
(begin-for-syntax
  (define age 9))
]

阶段级别 0 的 @racket[age] 绑定的值为 3，阶段级别 1 的 @racket[age] 绑定的值为 9。

语法对象将绑定信息捕获为一等值。因此，

@racketblock[#'age]

是一个表示 @racket[age] 绑定的语法对象——但因为有两个 @racket[age]（一个在阶段级别 0，一个在阶段级别 1），它捕获的是哪一个？实际上，Racket 为 @racket[#'age] 注入了所有阶段级别的词法信息，所以答案是 @racket[#'age] 两者都捕获了。

@racket[#'age] 捕获的 @racket[age] 的相关绑定在 @racket[#'age] 最终被使用时确定。例如，我们将 @racket[#'age] 绑定到一个模式变量以便在模板中使用，然后对模板进行 @racket[eval] 求值：@margin-note*{我们在这里使用 @racket[eval] 来演示阶段，但关于 @racket[eval] 的注意事项请参见 @secref["reflection"]。}

@interaction[#:eval age-eval
(eval (with-syntax ([age #'age])
        #'(displayln age)))
]

结果是 @racket[3]，因为 @racket[age] 在阶段级别 0 使用。我们可以再次尝试在 @racket[begin-for-syntax] 内使用 @racket[age]：

@interaction[#:eval age-eval
(eval (with-syntax ([age #'age])
        #'(begin-for-syntax
            (displayln age))))
]

在这种情况下，答案是 @racket[9]，因为我们在阶段级别 1 而非 0 使用 @racket[age]（即 @racket[begin-for-syntax] 在阶段级别 1 对其表达式求值）。所以，你可以看到我们从同一个语法对象 @racket[#'age] 开始，并且能够以两种不同的方式使用它：在阶段级别 0 和阶段级别 1。

语法对象从它首次存在时就具有词法上下文。从模块中 provide 的语法对象保留其词法上下文，因此它引用的是其源模块上下文中的绑定，而非使用它的上下文。以下示例在阶段级别 0 定义 @racket[button] 并将其绑定到 @racket[0]，而 @racket[see-button] 在模块 @racket[a] 中绑定 @racket[button] 的语法对象：

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

@racket[m] 宏的结果是 @racket[see-button] 的值，即带有 @racket[a] 模块词法上下文的 @racket[#'button]。尽管 @racket[b] 中有另一个 @racket[button]，第二个 @racket[button] 不会混淆 Racket，因为 @racket[#'button]（绑定到 @racket[see-button] 的值）的词法上下文是 @racket[a]。

注意 @racket[see-button] 由于使用 @racket[define-for-syntax] 定义而绑定在阶段级别 1。需要阶段级别 1 是因为 @racket[m] 是一个宏，所以它的主体在其定义上下文的高一个阶段执行。由于 @racket[m] 在阶段级别 0 定义，它的主体在阶段级别 1，因此主体引用的任何绑定都必须在阶段级别 1。

@; ======================================================================

@section{Phases and Modules}

@tech{phase level} 是一个相对于模块的概念。当通过 @racket[require] 从另一个模块导入时，Racket 允许我们将导入的绑定移动到与原始不同的阶段级别：

@racketblock[
(require "a.rkt")                @code:comment{import with no phase shift}
(require (for-syntax "a.rkt"))   @code:comment{shift phase by +1}
(require (for-template "a.rkt")) @code:comment{shift phase by -1}
(require (for-meta 5 "a.rkt" ))  @code:comment{shift phase by +5}
]

也就是说，在 @racket[require] 中使用 @racket[for-syntax] 意味着该模块的所有绑定的阶段级别将增加 1。在阶段级别 0 @racket[define] 的绑定通过 @racket[for-syntax] 导入后成为阶段级别 1 的绑定：

@interaction[
(module c racket
  (define x 0) @code:comment{defined at phase level 0}
  (provide x))

(module d racket
  (require (for-syntax 'c))
  @code:comment{has a binding at phase level 1, not 0:}
  #'x)
]

让我们看看如果尝试在阶段级别 0 为 @racket[#'button] 语法对象创建绑定会发生什么：

@(define button-eval (make-base-eval))
@(interaction-eval #:eval button-eval
                   (require (for-syntax racket/base)))
@interaction[#:eval button-eval
(define button 0)
(define see-button #'button)
]

现在 @racket[button] 和 @racket[see-button] 都在阶段 0 定义。@racket[#'button] 的词法上下文会知道在阶段 0 有 @racket[button] 的绑定。实际上，如果我们尝试 @racket[eval] @racket[see-button]，看起来一切正常：

@interaction[#:eval button-eval
(eval see-button)
]

现在，让我们在宏中使用 @racket[see-button]：

@interaction[#:eval button-eval
(define-syntax (m stx)
  see-button)
(m)
]

显然，@racket[see-button] 没有在阶段级别 1 定义，所以我们不能在宏主体中引用它。让我们尝试通过将 button 定义放在一个模块中并在阶段级别 1 导入它来在另一个模块中使用 @racket[see-button]。这样我们将在阶段级别 1 获得 @racket[see-button]：

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

Racket 说 @racket[button] 现在未绑定！当 @racket[a] 在阶段级别 1 导入时，我们有以下绑定：

@racketblock[
button     @#,elem{at phase level 1}
see-button @#,elem{at phase level 1}
]

所以宏 @racket[m] 可以看到阶段级别 1 的 @racket[see-button] 绑定，并将返回 @racket[#'button] 语法对象，该对象引用阶段级别 1 的 @racket[button] 绑定。但 @racket[m] 的使用在阶段级别 0，而 @racket[b] 中在阶段级别 0 没有 @racket[button]。这就是为什么 @racket[see-button] 需要在阶段级别 1 绑定，就像原始的 @racket[a] 中那样。在原始的 @racket[b] 中，我们有以下绑定：

@racketblock[
button     @#,elem{at phase level 0}
see-button @#,elem{at phase level 1}
]

在这种情况下，我们可以在宏中使用 @racket[see-button]，因为 @racket[see-button] 在阶段级别 1 绑定。当宏展开时，它将引用阶段级别 0 的 @racket[button] 绑定。

使用 @racket[(define see-button #'button)] 定义 @racket[see-button] 本身并没有错；这取决于我们打算如何使用 @racket[see-button]。例如，我们可以安排 @racket[m] 合理地使用 @racket[see-button]，因为它使用 @racket[begin-for-syntax] 将其放在阶段级别 1 的上下文中：

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

在这种情况下，模块 @racket[b] 在阶段级别 1 同时绑定了 @racket[button] 和 @racket[see-button]。宏的展开结果为

@racketblock[
(begin-for-syntax
  (displayln button))
]

这可以工作，因为 @racket[button] 在阶段级别 1 绑定。

现在，你可能试图通过同时在阶段级别 0 和阶段级别 1 导入 @racket[a] 来欺骗阶段系统。这样你将有以下绑定

@racketblock[
button     @#,elem{at phase level 0}
see-button @#,elem{at phase level 0}
button     @#,elem{at phase level 1}
see-button @#,elem{at phase level 1}
]

你可能期望现在宏中的 @racket[see-button] 能工作，但实际上不行：

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

在模块 @racket[a] 的定义中，变量 @racket[see-button] 在阶段 0，它的值是 @racket[button] 的语法对象，这表明唯一可见的 @racket[button] 绑定在同一阶段。（这是关键细节。）如前所述，@racket[for-syntax] 导入将 @emph{两者的}阶段级别都上移了一，因此模块 @racket[b] 中使用的 @racket[see-button] 的阶段 1 绑定是从模块 @racket[a] 移入阶段 1 的绑定，它引用 @racket[a] 中阶段 1 的 @racket[button]。在模块 @racket[b] 中还有一个来自模块 @racket[a] 不同实例化的阶段 0 变量 @racket[button]，但这无关紧要，因为无法从（移动后的）@racket[a] 的 @racket[see-button] 到达它。

这种实例化之间的阶段级别不匹配可以通过 @racket[syntax-shift-phase-level] 修复。回想一下，像 @racket[#'button] 这样的语法对象在 @emph{所有}阶段级别捕获词法信息。这里的问题是 @racket[see-button] 在阶段 1 被调用，但需要返回一个可以在阶段 0 求值的语法对象。默认情况下，@racket[see-button] 在同一阶段级别绑定到 @racket[#'button]。但使用 @racket[syntax-shift-phase-level]，我们可以使 @racket[see-button] 引用不同相对阶段级别的 @racket[#'button]。在这种情况下，我们使用 @racket[-1] 的阶段移动使阶段 1 的 @racket[see-button] 引用阶段 0 的 @racket[#'button]。（因为阶段移动发生在每个级别，它也会使阶段 0 的 @racket[see-button] 引用阶段 -1 的 @racket[#'button]。）

注意 @racket[syntax-shift-phase-level] 仅创建跨阶段的引用。要使该引用工作，我们仍然需要在两个阶段实例化我们的模块，以便引用和目标的绑定都可用。因此，在模块 @racket['b] 中，我们仍然在阶段 0 和阶段 1 都导入模块 @racket['a]——使用 @racket[(require 'a (for-syntax 'a))]——这样我们有 @racket[see-button] 的阶段 1 绑定和 @racket[button] 的阶段 0 绑定。现在宏 @racket[m] 将工作。

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

顺便说一下，绑定在阶段 0 的 @racket[see-button] 会怎样？它的 @racket[#'button] 绑定同样被移动了，但移动到了阶段 -1。由于 @racket[button] 本身在阶段 -1 没有绑定，如果我们在阶段 0 尝试对 @racket[see-button] 求值，会得到一个错误。换句话说，我们并没有永久修复不匹配问题——只是将其移到了一个不那么麻烦的位置。

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

像上面这样的不匹配也可能在宏尝试匹配字面绑定时出现——使用 @racket[syntax-case] 或 @racket[syntax-parse]。

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

在此示例中，@racket[make] 在 @racket[y] 中在阶段级别 2 使用，它返回 @racket[#'button] 语法对象——该对象引用在 @racket[x] 内部阶段级别 0 绑定的 @racket[button] 以及在 @racket[y] 中来自 @racket[(for-meta 2 'x)] 的阶段级别 2 的 @racket[button]。@racket[process] 宏从 @racket[(for-meta 1 'x)] 在阶段级别 1 导入，它知道 @racket[button] 应该在阶段级别 1 绑定。当 @racket[syntax-parse] 在 @racket[process] 内执行时，它寻找阶段级别 1 绑定的 @racket[button]，但只看到阶段级别 2 的绑定，因此不匹配。

要修复此示例，我们可以在相对于 @racket[x] 的阶段级别 1 提供 @racket[make]，然后在 @racket[y] 中在阶段级别 1 导入它：

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
