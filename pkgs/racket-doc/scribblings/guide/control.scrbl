#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define cc-eval (make-base-eval))

@title[#:tag "control" #:style 'toc]{Exceptions and Control}

Racket 提供了一套特别丰富的控制操作——不仅包括引发和捕获异常的操作，还包括抓取和恢复计算片段的操作。

@local-table-of-contents[]

@; ----------------------------------------

@section[#:tag "exns"]{Exceptions}

每当运行时错误发生时，就会引发一个 @deftech{异常}。除非该异常被捕获，否则它会被处理：打印与异常相关的消息，然后逃逸出当前计算。

@interaction[
(/ 1 0)
(car 17)
]

要捕获异常，请使用 @racket[with-handlers] 形式：

@specform[
(with-handlers ([predicate-expr handler-expr] ...)
  body ...+)
]{}

@racket[with-handlers] 中每个 handler 的 @racket[_predicate-expr] 确定要捕获的异常种类，异常值被传递给由 @racket[_handler-expr] 产生的 handler 过程。@racket[_handler-expr] 的结果是 @racket[with-handlers] 表达式的结果。

例如，除以零错误会引发 @racket[exn:fail:contract:divide-by-zero] 结构类型的实例：

@interaction[
(with-handlers ([exn:fail:contract:divide-by-zero?
                 (lambda (exn) +inf.0)])
  (/ 1 0))
(with-handlers ([exn:fail:contract:divide-by-zero?
                 (lambda (exn) +inf.0)])
  (car 17))
]

@racket[error] 函数是引发自定义异常的一种方式。它将错误消息和其他信息打包到 @racket[exn:fail] 结构中：

@interaction[
(error "crash!")
(with-handlers ([exn:fail? (lambda (exn) 'air-bag)])
  (error "crash!"))
]

@racket[exn:fail:contract:divide-by-zero] 和 @racket[exn:fail] 结构类型是 @racket[exn] 结构类型的子类型。核心形式和函数引发的异常总是 @racket[exn] 或其子类型的实例，但异常不一定由结构表示。@racket[raise] 函数允许你将任意值作为异常引发：

@interaction[
(raise 2)
(with-handlers ([(lambda (v) (equal? v 2)) (lambda (v) 'two)])
  (raise 2))
(with-handlers ([(lambda (v) (equal? v 2)) (lambda (v) 'two)])
  (/ 1 0))
]

@racket[with-handlers] 中的多个 @racket[_predicate-expr] 允许你以不同方式处理不同种类的异常。谓词按顺序尝试，如果没有匹配的，则异常传播到外层上下文。

@interaction[
(define (always-fail n)
  (with-handlers ([even? (lambda (v) 'even)]
                  [positive? (lambda (v) 'positive)])
    (raise n)))
(always-fail 2)
(always-fail 3)
(always-fail -3)
(with-handlers ([negative? (lambda (v) 'negative)])
 (always-fail -3))
]

使用 @racket[(lambda (v) #t)] 作为谓词当然会捕获所有异常：

@interaction[
(with-handlers ([(lambda (v) #t) (lambda (v) 'oops)])
  (car 17))
]

然而，捕获所有异常通常是个坏主意。如果用户在终端窗口中键入 Ctl-C 或在 DrRacket 中点击 @onscreen{Stop} 按钮来中断计算，那么正常情况下 @racket[exn:break] 异常不应被捕获。要仅捕获表示错误的异常，请使用 @racket[exn:fail?] 作为谓词：

@interaction[
(with-handlers ([exn:fail? (lambda (v) 'oops)])
  (car 17))
(eval:alts ; `examples' doesn't catch break exceptions!
 (with-handlers ([exn:fail? (lambda (v) 'oops)])
   (break-thread (current-thread)) (code:comment @#,t{simulate Ctl-C})
   (car 17))
 (error "user break"))
]

异常携带有关发生错误的信息。@racket[exn-message] accessor 为异常提供描述性消息。@racket[exn-continuation-marks] accessor 提供有关异常引发点的信息。
@margin-note[#:footnote? #t]{@racket[continuation-mark-set->context] 过程提供尽力而为的结构化回溯信息。}

@interaction[
(with-handlers ([exn:fail?
                 (lambda (v)
                   ((error-display-handler) (exn-message v) v))])
  (car 17))
]


@; ----------------------------------------

@section[#:tag "prompt"]{Prompts and Aborts}

当异常被引发时，控制从任意深的评估上下文逃逸到异常被捕获的点——或者如果异常从未被捕获，则一直向外逃逸：

@interaction[
(+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (/ 1 0)))))))
]

但如果控制"一直向外逃逸"，为什么在打印错误消息后 @tech{REPL} 还在继续？你可能会认为这是因为 @tech{REPL} 将每次交互包装在捕获所有异常的 @racket[with-handlers] 形式中，但这并不是真正的原因。

实际原因是 @tech{REPL} 用 @deftech{prompt} 包装交互，这有效地用逃逸点标记了评估上下文。如果异常未被捕获，则打印异常信息，然后评估 @deftech{abort} 到最近的封闭 prompt。更精确地说，每个 prompt 都有一个 @deftech{prompt tag}，并且有一个指定的 @deftech{默认 prompt tag}，未捕获异常处理器使用它来 @tech{abort}。

@racket[call-with-continuation-prompt] 函数使用给定的 @tech{prompt tag} 安装 prompt，然后在 prompt 下评估给定的 thunk。@racket[default-continuation-prompt-tag] 函数返回 @tech{默认 prompt tag}。@racket[abort-current-continuation] 函数逃逸到具有给定 @tech{prompt tag} 的最近封闭 prompt。

@interaction[
(define (escape v)
  (abort-current-continuation
   (default-continuation-prompt-tag)
   (lambda () v)))
(+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (escape 0)))))))
(+ 1
   (call-with-continuation-prompt
    (lambda ()
      (+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (+ 1 (escape 0))))))))
    (default-continuation-prompt-tag)))
]

在上面的 @racket[escape] 中，值 @racket[v] 被包装在一个过程中，该过程在逃逸到封闭 prompt 后被调用。

@tech{Prompt} 和 @tech{abort} 看起来非常像异常处理和引发。事实上，prompt 和 abort 本质上是更原始的异常形式，而 @racket[with-handlers] 和 @racket[raise] 是基于 prompt 和 abort 实现的。更原始形式的力量与操作符名称中的"continuation"一词相关，我们将在下一节讨论。

@; ----------------------------------------------------------------------

@section[#:tag "conts"]{Continuations}


A @deftech{continuation} 是一个封装了表达式评估上下文片段的值。@racket[call-with-composable-continuation] 函数捕获从当前函数调用外部开始、运行到最近封闭 prompt 的 @deftech{当前 continuation}。（请记住，每个 @tech{REPL} 交互都隐式地包装在一个 prompt 中。）

例如，在

@racketblock[
(+ 1 (+ 1 (+ 1 0)))
]

在评估 @racket[0] 时，表达式上下文包括三个嵌套的加法表达式。我们可以通过将 @racket[0] 改为在返回 0 之前抓取 continuation 来获取该上下文：

@interaction[
#:eval cc-eval
(define saved-k #f)
(define (save-comp!)
  (call-with-composable-continuation
   (lambda (k) (code:comment @#,t{@racket[k] is the captured continuation})
     (set! saved-k k)
     0)))
(+ 1 (+ 1 (+ 1 (save-comp!))))
]

存储在 @racket[saved-k] 中的 @tech{continuation} 封装了程序上下文 @racket[(+ 1 (+ 1 (+ 1 _?)))]，其中 @racket[_?] 表示一个插入结果值的位置——因为那是调用 @racket[save-comp!] 时的表达式上下文。@tech{continuation} 被封装后，其行为类似于函数 @racket[(lambda (v) (+ 1 (+ 1 (+ 1 v))))]：

@interaction[
#:eval cc-eval
(saved-k 0)
(saved-k 10)
(saved-k (saved-k 0))
]

@racket[call-with-composable-continuation] 捕获的 continuation 是动态确定的，而不是语法确定的。例如，

@interaction[
#:eval cc-eval
(define (sum n)
  (if (zero? n)
      (save-comp!)
      (+ n (sum (sub1 n)))))
(sum 5)
]

@racket[saved-k] 中的 continuation 变为 @racket[(lambda (x) (+ 5 (+ 4 (+ 3 (+ 2 (+ 1 x))))))]：

@interaction[
#:eval cc-eval
(saved-k 0)
(saved-k 10)
]

Racket（或 Scheme）中更传统的 continuation 操作符是 @racket[call-with-current-continuation]，通常缩写为 @racket[call/cc]。它类似于 @racket[call-with-composable-continuation]，但应用捕获的 continuation 会首先 @tech{abort}（到当前 @tech{prompt}），然后恢复保存的 continuation。

@interaction[
#:eval cc-eval
(+ 1 (+ 1 (+ 1 (save-comp!))))
(+ 1 (saved-k 0))
(define (save-cc!)
  (call-with-current-continuation
   (lambda (k) (code:comment @#,t{@racket[k] is the captured continuation})
     (set! saved-k k)
     0)))
(+ 1 (+ 1 (+ 1 (save-cc!))))
(+ 1 (saved-k 0))
]

其他 Scheme 系统在程序开始时传统上支持单个 prompt，而不是允许通过 @racket[call-with-continuation-prompt] 引入新 prompt。

如 Racket 中的 continuation 有时被称为 @deftech{有界 continuation}，因为程序可以引入新的边界 prompt，而 @racket[call-with-composable-continuation] 捕获的 continuation 有时被称为 @deftech{可组合 continuation}，因为它们没有内置的 @tech{abort}。

有关 @tech{continuation} 如何有用的示例，请参见 @other-manual['(lib "scribblings/more/more.scrbl")]。对于比此处描述的原始操作符更方便命名的特定控制操作符，请参见 @racketmodname[racket/control]。

@; ----------------------------------------------------------------------

@close-eval[cc-eval]
