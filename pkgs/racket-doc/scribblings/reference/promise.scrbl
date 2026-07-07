#lang scribble/doc
@(require "mz.rkt" (for-label racket/promise))

@title{Delayed Evaluation}

@note-lib[racket/promise]

一个 @deftech{promise} 封装了一个表达式，通过 @racket[force] 按需求值。在一个 promise 被 @racket[force] 后，对该 promise 的后续每次 @racket[force] 都会产生相同的结果。


@defproc[(promise? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a promise, @racket[#f]
otherwise.}


@defform[(delay body ...+)]{

创建一个 promise，当被 @racket[force] 时，求值 @racket[body]s 以产生其值。结果会被缓存，因此后续的 @racket[force] 调用会立即返回缓存的值。这包括多值和异常。

}


@defform[(lazy body ...+)]{

Like @racket[delay]，如果最后一个 @racket[body] 被强制求值时产生一个 promise，则此 promise 也会被 @racket[force]，以获取一个值。换句话说，此形式创建一个可组合的 promise，其 body 的计算“附加”到下一个 promise 的计算上，单个 @racket[force] 遍历整个链，尾调用每一步。

注意，此形式的最后一个 @racket[body] 必须产生单个值，但该值本身可以是一个返回多个值的 @racket[delay] promise。

@racket[lazy] form 用于实现惰性库和语言很有用，其中可以用 promise 包装尾调用。

}


@defproc[(force [v any/c]) any]{

如果 @racket[v] 是一个 promise，则该 promise 被强制求值以获取一个值。如果 promise 之前未被强制求值，则结果会被记录在 promise 中，以便未来对该 promise 的 @racket[force] 产生相同（或多个）值。如果强制求值 promise 引发异常，则异常同样被记录，使得对该 promise 的每次强制求值都会引发相同的异常。

如果 @racket[v] 在原始的 @racket[force] 调用返回之前再次被 @racket[force]，则 @exnraise[exn:fail]。

如果 @racket[v] 不是 promise，则它被作为结果返回。}


@defproc[(promise-forced? [promise promise?]) boolean?]{

Returns @racket[#t] if @racket[promise] has been forced.}


@defproc[(promise-running? [promise promise?]) boolean?]{

Returns @racket[#t] if @racket[promise] is currently being forced.
(Note that a promise can be either running or forced but not both.)}


@section[#:tag "promise-s1"]{Additional Promise Kinds}

@defform[(delay/name body ...+)]{

创建一个 ``call-by-name'' promise，类似于 @racket[delay]-promise，但结果不会被缓存。这种 promise 本质上是一个 thunk，被包装成 @racket[force] 可识别的形式。

如果 @racket[delay/name] promise 强制求值自身，不会引发异常，该 promise 永远不会被视为 @racket[promise-running?] 和 @racket[promise-forced?] 意义上的 ``running'' 或 ``forced''。}

@defproc[(promise/name? [promise any/c]) boolean?]{

Returns @racket[#t] if @racket[promise] is a promise created with @racket[delay/name].
@history[#:added "6.3"]
}

@defform[(delay/strict body ...+)]{

创建一个 ``strict'' promise：它立即被求值，结果被包装在 promise 值中。注意，body 可以求值为多个值，强制求值结果的 promise 会返回这些值。

}

@defform[(delay/sync body ...+)]{

产生一个 promise，非当前运行 promise 的线程尝试 @racket[force] 它会导致 @racket[force] 阻塞直到有结果可用。这种 promise 也是一个 @tech{synchronizable event}，用于 @racket[sync]；在 promise 上 @racket[sync] 不会 @racket[force] it，而仅等待另一个 thread 强制求值。@tech{synchronization result} 是 @|void-const|。

如果 @racket[delay/sync] 创建的 promise 在一个已经在运行该 promise 的 thread 上被强制求值，则会像 @racket[delay] 创建的 promise 一样引发异常。}

@defform/subs[(delay/thread body/option ...+)
              ([body/option body
                            (code:line #:group thread-group-expr)])]{

Like @racket[delay/sync]，但会立即在新创建的 thread 上开始计算。Thread 在 @racket[thread-group-expr] 指定的 @tech{thread group} 下创建，默认为 @racket[(make-thread-group)]。@racket[#:group] 指定最多出现一次。

@racket[body]s 引发的异常如往常一样被捕获，仅在 promise 被 @racket[force] 时引发。与 @racket[delay/sync] 不同，如果运行 @racket[body] 的 thread 终止而未产生结果或异常，对 promise 的 @racket[force] 会引发异常（而非阻塞）。}

@defform/subs[(delay/idle body/option ...+)
              ([body/option body
                            (code:line #:wait-for wait-evt-expr)
                            (code:line #:work-while while-evt-expr)
                            (code:line #:tick tick-secs-expr)
                            (code:line #:use use-ratio-expr)])]{

Like @racket[delay/thread]，但有以下区别：

@itemlist[

 @item{计算直到 @racket[wait-evt-expr] 产生的事件就绪后才开始，默认为 @racket[(system-idle-evt)]；}

 @item{计算 thread 仅在进程根据 @racket[while-evt-expr] 确定为空闲时运行，默认为 @racket[(system-idle-evt)]；}

 @item{thread 仅被允许周期性运行：在每 @racket[tick-secs-expr] 秒（默认为 @racket[0.2]）中，thread 被允许按比例运行 @racket[use-ratio-expr]（默认为 @racket[0.12]）的时间；即 thread 运行 @racket[(* tick-secs-expr use-ratio-expr)] 秒。}

]

如果 promise 在完成计算之前被 @racket[force]，它会立即运行剩余的计算部分，不等待事件或周期性限制。

@racket[#:wait-for]、@racket[#:work-while]、@racket[#:tick] 或 @racket[#:use] 指定最多出现一次。

@;{
TODO: Say something on:
* `use' = 0 --> similar to a plain `delay' which is evaluated only when
  forced (or delay/sync, since it's still sync-able), except that the
  evaluation is still happening on a new thread.
* `use' = 1 --> given cpu time as usual, but still polls the idle event
  every `tick' seconds
* `use' = 1 and both `wait-for' and `work-while' are `always-evt' -->
  similar to `delay/thread'.
* can use `wait-for' to delay evaluation start until some event is
  ready.  Specifically, this can be done to chain a few of these
  promises sequentially.
* same goes for `work-while'.  For example, you can use that with a
  `semaphore-peek-evt' to be able to pause/resume the computation on
  demand.
;}}

@(define promise-eval
   (let ([eval (make-base-eval)])
     (eval '(require racket/promise))
     eval))

@defform[
  (for/list/concurrent maybe-group (for-clause ...)
    body-or-break ... body)
  #:grammar
  [(maybe-group (code:line)
                (code:line #:group thread-group-expr))]
  #:contracts ([thread-group-expr thread-group?])]{

  遍历如 @racket[for/list]，但每个 body（在任何 @racket[#:break] 或 @racket[#:final] 子句之后）被包装在 @racket[delay/thread] 中。每个 @tech{promise} 在结果列表返回之前被强制求值。

  Thread 在 @racket[thread-group-expr] 下创建，默认为 @racket[(make-thread-group)]。可提供可选的 @racket[#:group] 子句，此时 thread 将在该 thread group 下创建。

  此形式不支持返回多个值。

  @examples[
    #:eval promise-eval
    (time
     (for/list/concurrent ([i (in-range 5)])
       (define duration (/ 1.0 (random 50 100)))
       (sleep duration)
       (printf "thread ~a slept for ~a milliseconds~n" i (truncate (* duration 1000)))
       i))
  ]

  @history[#:added "8.6.0.4"]
}

@defform[(for*/list/concurrent maybe-group (for-clause ...)
           body-or-break ... body)]{
  Like @racket[for/list/concurrent]，但有 @racket[for*/list] 的隐式嵌套。

  @history[#:added "8.6.0.4"]
}
