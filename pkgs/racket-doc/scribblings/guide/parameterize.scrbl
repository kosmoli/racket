#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define param-eval (make-base-eval))

@title[#:tag "parameterize"]{动态绑定：@racket[parameterize]}

@refalso["parameters"]{@racket[parameterize]}

@racket[parameterize] 形式在 @racket[_body] 表达式求值期间将一个新值与
@deftech{parameter} 关联：

@specform[(parameterize ([parameter-expr value-expr] ...)
            body ...+)]

@margin-note{术语 "parameter" 有时用于指代 function 的参数，
             但在 Racket 中 "parameter" 具有此处描述的更具体的含义。}

例如，@racket[error-print-width] parameter 控制错误消息中打印值的字符数：

@interaction[
(parameterize ([error-print-width 5])
  (car (expt 10 1024)))
(parameterize ([error-print-width 10])
  (car (expt 10 1024)))
]

更一般地说，parameter 实现了一种动态绑定。
@racket[make-parameter] function 接受任意值并返回一个初始化为给定值的新
parameter。将 parameter 作为 function 调用会返回其当前值：

@interaction[
#:eval param-eval
(define location (make-parameter "here"))
(location)
]

在 @racket[parameterize] 形式中，每个 @racket[_parameter-expr] 必须产生一个
parameter。在 @racket[body] 求值期间，每个指定的 parameter 被赋予相应
@racket[_value-expr] 的求值结果。当控制离开 @racket[parameterize]
形式时——无论是通过正常返回、异常还是其他逃逸——parameter 会恢复为之前的值：

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

@racket[parameterize] 形式不是像 @racket[let] 那样的绑定形式；上面每次使用
@racket[location] 都直接引用原始定义。@racket[parameterize] 形式在整个
@racket[parameterize] body 被求值期间调整 parameter 的值，即使对 parameter
的使用在文本层面位于 @racket[parameterize] body 之外也是如此：

@interaction[
#:eval param-eval
(define (would-you-could-you?)
  (and (not (equal? (location) "here"))
       (not (equal? (location) "there"))))

(would-you-could-you?)
(parameterize ([location "on a bus"])
  (would-you-could-you?))
]

如果对 parameter 的使用在文本层面位于 @racket[parameterize] body 内部，但在
@racket[parameterize] 形式产生值之前未被求值，那么该使用看不到
@racket[parameterize] 形式设置的值：

@interaction[
#:eval param-eval
(let ([get (parameterize ([location "with a fox"])
             (lambda () (location)))])
  (get))
]

parameter 的当前绑定可以通过将 parameter 作为 function 传入一个值来命令式地调整。如果
@racket[parameterize] 已经调整了 parameter 的值，那么直接调用 parameter
procedure 仅影响与活动 @racket[parameterize] 关联的值：

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

通常使用 @racket[parameterize] 优于命令式更新 parameter
值——原因与使用 @racket[let] 绑定新 variable 优于使用 @racket[set!]
大致相同（见 @secref["set!"]）。

看起来 variables 和 @racket[set!] 可以解决 parameter 所能解决的许多相同问题。例如，
@racket[lokation] 可以定义为 string，并可以使用 @racket[set!] 来调整其值：

@interaction[
#:eval param-eval
(define lokation "here")

(define (would-ya-could-ya?)
  (and (not (equal? lokation "here"))
       (not (equal? lokation "there"))))

(set! lokation "on a bus")
(would-ya-could-ya?)
]

然而，parameter 提供了几个优于 @racket[set!] 的关键优势：

@itemlist[

 @item{@racket[parameterize] 形式有助于在控制因异常逃逸时自动重置 parameter
       的值。添加 exception handler 和其他形式来回退 @racket[set!] 相对繁琐。}

 @item{Parameter 与 tail call（见 @secref["tail-recursion"]）很好地配合工作。
       @racket[parameterize] 形式中的最后一个 @racket[_body] 相对于
       @racket[parameterize] 形式处于 @tech{tail position}。}

 @item{Parameter 与 threads（见 @refsecref["threads"]）正确配合工作。
       @racket[parameterize] 形式仅为当前线程中的求值调整 parameter
       的值，这避免了与其他线程的 race condition。}

]

@; ----------------------------------------

@close-eval[param-eval]
