#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define param-eval (make-base-eval))

@title[#:tag "parameterize"]{Dynamic Binding: @racket[parameterize]}

@refalso["parameters"]{@racket[parameterize]}

@racket[parameterize] 形式在 @racket[_body] 表达式求值期间将一个新值与一个 @deftech{parameter}（参数）关联：

@specform[(parameterize ([parameter-expr value-expr] ...)
            body ...+)]

@margin-note{术语 ``parameter'' 有时用来指函数的参数，但 Racket 中的 ``parameter''（参数）具有此处描述的更具体的含义。}

例如，@racket[error-print-width] 参数控制在错误消息中打印一个值的多少个字符：

@interaction[
(parameterize ([error-print-width 5])
  (car (expt 10 1024)))
(parameterize ([error-print-width 10])
  (car (expt 10 1024)))
]

更一般地说，参数实现了一种动态绑定。@racket[make-parameter] 函数接受任意值并返回一个以给定值初始化的新参数。将参数作为函数应用时返回其当前值：

@interaction[
#:eval param-eval
(define location (make-parameter "here"))
(location)
]

在 @racket[parameterize] 形式中，每个 @racket[_parameter-expr] 必须产生一个参数。在 @racket[body] 求值期间，每个指定的参数被赋予相应 @racket[_value-expr] 的结果。当控制流离开 @racket[parameterize] 形式时——无论是通过正常返回、异常还是其他逃逸方式——参数都会恢复到之前的值：

@interaction[
#:eval param-eval
(parameterize ([location "there"])
  (location))
(location)
(parameterize ([location "in a house"])
  (list (location)
        (parameterize ([location "with a mouse"])
          (location))
        (location)))
(parameterize ([location "in a box"])
  (car (location)))
(location)
]

@racket[parameterize] 形式不像 @racket[let] 那样是绑定形式；上面每次使用 @racket[location] 都直接引用原始定义。@racket[parameterize] 形式在整个 @racket[parameterize] 主体求值期间调整参数的值，即使对于在 @racket[parameterize] 主体文本范围之外的参数使用也是如此：

@interaction[
#:eval param-eval
(define (would-you-could-you?)
  (and (not (equal? (location) "here"))
       (not (equal? (location) "there"))))

(would-you-could-you?)
(parameterize ([location "on a bus"])
  (would-you-could-you?))
]

如果一个参数的使用在文本上位于 @racket[parameterize] 主体内部，但在 @racket[parameterize] 形式产生值之前没有被求值，则该使用看不到 @racket[parameterize] 形式安装的值：

@interaction[
#:eval param-eval
(let ([get (parameterize ([location "with a fox"])
             (lambda () (location)))])
  (get))
]

参数的当前绑定可以通过将参数作为函数并传入一个值来命令式地调整。如果 @racket[parameterize] 已经调整了参数的值，则直接应用参数过程只会影响与活动 @racket[parameterize] 关联的值：

@interaction[
#:eval param-eval
(define (try-again! where)
  (location where))

(location)
(parameterize ([location "on a train"])
  (list (location)
        (begin (try-again! "in a boat")
               (location))))
(location)
]

通常优先使用 @racket[parameterize] 而不是命令式地更新参数值——原因与使用 @racket[let] 绑定新变量优先于使用 @racket[set!] 大致相同（参见 @secref["set!"]）。

变量和 @racket[set!] 似乎可以解决参数解决的许多相同问题。例如，@racket[lokation] 可以定义为字符串，并且可以使用 @racket[set!] 来调整其值：

@interaction[
#:eval param-eval
(define lokation "here")

(define (would-ya-could-ya?)
  (and (not (equal? lokation "here"))
       (not (equal? lokation "there"))))

(set! lokation "on a bus")
(would-ya-could-ya?)
]

然而，参数相对于 @racket[set!] 提供了几个关键优势：

@itemlist[

 @item{@racket[parameterize] 形式有助于在因异常而逃逸时自动重置参数的值。添加异常处理程序和其他形式来撤回 @racket[set!] 相对来说很繁琐。}

 @item{参数与尾调用配合良好（参见 @secref["tail-recursion"]）。@racket[parameterize] 形式中的最后一个 @racket[_body] 处于相对于 @racket[parameterize] 形式的 @tech{tail position}（尾位置）。}

 @item{参数与线程配合正确（参见 @refsecref["threads"]）。@racket[parameterize] 形式仅在当前线程的求值中调整参数的值，从而避免了与其他线程的竞态条件。}

]

@; ----------------------------------------

@close-eval[param-eval]
