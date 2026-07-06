#lang scribble/doc
@(require scribble/struct
          "mz.rkt"
          (for-label racket/async-channel
                     (only-in ffi/unsafe/schedule unsafe-poller)))

@(define evt-eval (make-base-eval))

@title[#:tag "sync"]{Events}

@section-index["select"]
@section-index["poll"]

A @deftech{可同步事件}（或简称为 @defterm{事件}）与 @racket[sync] 过程配合，用于协调线程之间的同步。某些类型的对象同时充当事件，包括 port 和 thread。其他类型的对象仅作为事件存在。Racket 的事件系统基于 Concurrent ML @cite{Reppy99}。

在任何时刻，事件要么是 @deftech{就绪可同步}，要么不是；根据事件的种类以及它被其他线程使用的方式，事件可以在任何时候从非就绪切换到就绪（或反过来）。如果线程在事件就绪时对其进行同步，那么事件会产生一个特定的 @deftech{同步结果}。

同步事件可能会影响事件的状态。例如，当同步一个信号量时，其内部计数会递减，与 @racket[semaphore-wait] 一样。然而对于大多数类型的事件（如 port），同步不会修改事件的状态。

用作 @tech{可同步事件} 的 Racket 值包括
@tech{asynchronous channels},
@tech{channels},
@tech{custodian box}es,
@tech{log receivers},
@tech{place channels},
@tech{ports},
@tech{semaphores},
@tech{subprocess}es,
@tech{TCP listeners},
@tech{threads}, and
@tech{will executors}.
库可以通过 @racket[prop:evt] 定义新的可同步事件。

@;------------------------------------------------------------------------

@defproc[(evt? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] 是 @tech{可同步事件}，否则返回 @racket[#f]。

@examples[#:eval evt-eval
  (evt? never-evt)
  (evt? (make-channel))
  (evt? 5)
]}


@defproc[(sync [evt evt?] ...) any]{

阻塞直到至少有一个 @tech{可同步事件} @racket[evt] 就绪为止。

当至少有一个 @racket[evt] 就绪时，返回其 @tech{同步结果}（通常是 @racket[evt] 本身）。如果有多个 @racket[evt] 就绪，则伪随机选择其中一个作为结果；控制此选择的随机数生成器由 @racket[current-evt-pseudo-random-generator] 参数设置。

@examples[#:eval evt-eval
  (define ch (make-channel))
  (thread (λ () (displayln (sync ch))))
  (channel-put ch 'hellooooo)
]

@history[#:changed "6.1.0.3" @elem{Allow 0 arguments instead of 1 or more.}]}


@defproc[(sync/timeout [timeout (or/c #f (and/c real? (not/c negative?)) (-> any))]
                       [evt evt?] ...)
          any]{

如果 @racket[timeout] 是 @racket[#f]，则与 @racket[sync] 相同。如果
如果 @racket[timeout] 是实数，则当 @racket[timeout] 秒过去后仍无成功同步时，结果为 @racket[#f]。如果 @racket[timeout] 是一个过程，则在轮询 @racket[evt] 发现无就绪事件时，以尾位置调用该过程。

@racket[timeout] 的零值等价于 @racket[(lambda () #f)]。无论哪种情况，在返回 @racket[#f] 或调用 @racket[timeout] 之前，每个 @racket[evt] 至少被检查一次。

另参见 @racket[alarm-evt]，了解另一种超时机制。

@examples[#:eval evt-eval
  (code:comment "times out before waking up")
  (sync/timeout
   0.5
   (thread (λ () (sleep 1) (displayln "woke up!"))))
  (sync/timeout
   (λ () (displayln "no ready events"))
   never-evt)
]

@history[#:changed "6.1.0.3" @elem{Allow 1 argument instead of 2 or more.}]}


@defproc[(sync/enable-break [evt evt?] ...) any]{

类似于 @racket[sync]，但在等待 @racket[evt] 时启用 break（参见 @secref["breakhandler"]）。如果在调用 @racket[sync/enable-break] 时 break 被禁用，那么要么所有 @racket[evt] 都保持未选择状态，要么引发 @racket[exn:break] 异常，但不会同时发生。


@defproc[(sync/timeout/enable-break [timeout (or/c #f (and/c real? (not/c negative?)) (-> any))]
                                    [evt evt?] ...)
         any]{

类似于 @racket[sync/enable-break]，但带有 @racket[sync/timeout] 的超时参数。

创建一个组合多个 @racket[evt] 的单一事件。将结果传递给 @racket[sync] 与将每个 @racket[evt] 传递给同一调用相同。

也就是说，当传递给 @racket[choice-evt] 的一个或多个 @racket[_evt] 是 @tech{就绪可同步} 时，@racket[choice-evt] 返回的事件也是 @tech{就绪可同步} 的。如果选择了该 choice 事件，则伪随机选择其中一个就绪的 @racket[_evt]，其 @tech{同步结果} 即为所选 @racket[_evt] 的 @tech{同步结果}。

@examples[#:eval evt-eval
  (define ch1 (make-channel))
  (define ch2 (make-channel))
  (define either-channel (choice-evt ch1 ch2))
  (thread (λ () (displayln (sync either-channel))))
  (channel-put
   (if (> (random) 0.5) ch1 ch2)
   'tuturuu)
]}


@defproc[(wrap-evt [evt evt?]
                   [wrap (any/c ... . -> . any)]) 
         evt?]{

创建一个事件，当 @racket[evt] 是 @tech{就绪可同步} 时它也是 @tech{就绪可同步} 的，但其 @tech{同步结果} 由将 @racket[wrap] 应用于 @racket[evt] 的 @tech{同步结果} 来确定。@racket[wrap] 接受的参数数量必须与 @racket[evt] 的同步结果值的数量匹配。

对 @racket[wrap] 的调用通过 @racket[parameterize-break] 在初始时禁用 break。

@examples[#:eval evt-eval
  (define ch (make-channel))
  (define evt (wrap-evt ch (λ (v) (format "you've got mail: ~a" v))))
  (thread (λ () (displayln (sync evt))))
  (channel-put ch "Dear Alice ...")
]}


@defproc[(handle-evt [evt evt?]
                     [handle (any/c ... . -> . any)]) 
         handle-evt?]{

类似于 @racket[wrap-evt]，但当它不被 @racket[wrap-evt]、@racket[chaperone-evt] 或另一个 @racket[handle-evt] 包裹时，@racket[handle] 会在同步请求的 @tech{尾位置} 被调用——且不在显式禁用 break 的情况下调用。

@examples[#:eval evt-eval
  (define msg-ch (make-channel))
  (define exit-ch (make-channel))
  (thread
   (λ ()
     (let loop ([val 0])
       (printf "val = ~a~n" val)
       (sync (handle-evt
              msg-ch
              (λ (val) (loop val)))
             (handle-evt
              exit-ch
              (λ (val) (displayln val)))))))
  (channel-put msg-ch 5)
  (channel-put msg-ch 7)
  (channel-put exit-ch 'done)
]}


@defproc[(guard-evt [maker (-> (or/c evt? any/c))]) evt?]{

创建一个表现为事件但实际上是一个事件生成器的值。

@racket[guard-evt] 返回的事件 @racket[_guard] 在 @racket[_guard] 与 @racket[sync] 一起使用时生成一个事件（或者当它是与 @racket[sync] 一起使用的 choice 事件的一部分时等），其中生成的事件是调用 @racket[maker] 的结果。对于给定的 @racket[sync] 调用，@racket[maker] 最多被调用一次，但如果在此之前已选择了就绪事件，则 @racket[_guard] 甚至不会被考虑，@racket[maker] 也不会被调用。

如果 @racket[maker] 返回非事件值，则 @racket[maker] 的结果被替换为一个 @tech{就绪可同步} 的事件，其 @tech{同步结果} 为 @racket[_guard]。


@defproc[(nack-guard-evt [maker (evt? . -> . (or/c evt? any/c))]) evt?]{

类似于 @racket[guard-evt]，但当 @racket[maker] 被调用时，会传入一个 NACK（"否定确认"）事件。在开始调用 @racket[maker] 之后，如果 @racket[maker] 产生的事件最终没有被选为就绪事件，那么提供给 @racket[maker] 的 NACK 事件将变为 @tech{就绪可同步}，其值为 @|void-const|。

当事件因以下原因被放弃时，NACK 事件变为 @tech{就绪可同步}：其他事件被选中、同步线程死亡、或控制从 @racket[sync] 调用中逃逸（即使 @racket[_nack-guard] 的 @racket[maker] 尚未返回值）。如果 @racket[maker] 返回的事件被选中，则 NACK 事件永远不会变为 @tech{就绪可同步}。

类似于 @racket[guard-evt]，但当 @racket[maker] 被调用时，会提供一个布尔值指示该事件将用于轮询（@racket[#t]）还是用于阻塞同步（@racket[#f]）。

如果向 @racket[maker] 提供了 @racket[#t]，且 break 被禁用，且轮询线程未被终止，且对结果事件的轮询产生了 @tech{同步结果}，则该事件肯定会被选中用于其结果。

类似于 @racket[guard-evt]，但 @racket[maker] 仅在 @racket[evt] 变为 @tech{就绪可同步} 之后才被调用，并且 @racket[evt] 的 @tech{同步结果} 被传递给 @racket[maker]。

尝试同步 @racket[evt] 与尝试同步 @racket[replace-evt] 的结果 @racket[_guard] 并发进行；尽管存在这种并发，但如果 @racket[maker] 被调用，它会在同步 @racket[_guard] 的线程中被调用。@racket[evt] 和另一个与 @racket[_guard] 同步的事件可以同时成功同步；同步的单选保证仅适用于 @racket[maker] 的结果和与 @racket[_guard] 同步的其他事件。

如果 @racket[maker] 返回非事件值，则 @racket[maker] 的结果被替换为一个 @tech{就绪可同步} 的事件，其 @tech{同步结果} 为 @racket[_guard]。

@history[#:added "6.1.0.3"]}


@defthing[always-evt evt?]{一个常量事件，始终 @tech{就绪可同步}，其 @tech{同步结果} 是它自身。

@examples[#:eval evt-eval
  (sync always-evt)
]}


@defthing[never-evt evt?]{一个常量事件，永远不会 @tech{就绪可同步}。}

@defproc[(system-idle-evt) evt?]{

返回一个当系统否则空闲时处于 @tech{就绪可同步} 的事件：如果结果事件被 @racket[never-evt] 替代，系统中没有任何线程可以运行。换句话说，所有线程必须已被挂起或仅在尚未超时的事件上阻塞。system-idle 事件的 @tech{同步结果} 是 @|void-const|。@racket[system-idle-evt] 过程的结果始终是同一事件。

@examples[#:eval evt-eval
  (define th (thread (λ () (let loop () (loop)))))
  (sync/timeout 0.1 (system-idle-evt))
  (kill-thread th)
  (eval:alts (sync (system-idle-evt)) (void))
]}


@defproc[(alarm-evt [msecs real?] [monotonic? any/c #f]) evt?]{

返回一个 @tech{可同步事件}：当 @racket[(_milliseconds)] 返回的值小于 @racket[msecs] 时不是 @tech{就绪可同步} 的；当 @racket[(_milliseconds)] 返回的值大于 @racket[msecs] 时是 @tech{就绪可同步} 的。


@examples[#:eval evt-eval
  (define alarm (alarm-evt (+ (current-inexact-milliseconds) 100)))
  (sync alarm)
]

@history[#:changed "8.3.0.9" @elem{Added the @racket[monotonic?] argument.}]}


@defproc[(handle-evt? [evt evt?]) boolean?]{

如果 @racket[evt] 是由 @racket[handle-evt] 创建的，或者是通过对 @racket[handle-evt?] 产生 @racket[#t] 的另一个事件应用 @racket[choice-evt] 创建的，则返回 @racket[#t]。对于任何其他事件，@racket[handle-evt?] 产生 @racket[#f]。

@examples[#:eval evt-eval
  (handle-evt? never-evt)
  (handle-evt? (handle-evt always-evt values))
]}

@;------------------------------------------------------------------------
@defthing[prop:evt struct-type-property?]{

一个 @tech{结构类型属性}，用于标识其实例可作为 @tech{可同步事件} 的结构类型。属性值可以是以下之一：

@itemize[
 
 @item{事件 @racket[_evt]：此时，使用该结构作为事件等价于使用 @racket[_evt]。}

 @item{单参数过程 @racket[_proc]：此时，该结构类似于 @racket[guard-evt] 生成的事件，但准 guard 过程 @racket[_proc] 接收该结构作为参数，而不是无参数；此外，@racket[_proc] 的非事件结果被替换为一个已经 @tech{就绪可同步} 且其 @tech{同步结果} 为该结构的事件。}

 @item{@racket[0]（包含）到结构类型中非自动字段数量（不包含，不计算 supertype 字段）之间的精确非负整数：该整数标识结构中的一个字段，且该字段必须被指定为不可变。如果该字段包含一个对象或一个单参数的事件生成过程，则按上述方式使用该事件或过程。否则，该结构充当一个永不可用的事件。}

]

@margin-note{对于使用外部库，@racket[prop:evt] 的值也可以是 @racket[unsafe-poller] 的结果，尽管该可能性被从 @racket[prop:evt] 的安全契约中省略。}

具有 @racket[prop:input-port] 或 @racket[prop:output-port] 属性的结构类型实例也因是 port 而充当 @tech{可同步事件}。如果结构类型具有 @racket[prop:evt]、@racket[prop:input-port] 和 @racket[prop:output-port] 中的多个，则 @racket[prop:evt] 值（如有）优先决定实例作为事件的行为，且 @racket[prop:input-port] 属性优先于 @racket[prop:output-port] 用于同步。

@examples[
(struct wt (base val)
  #:property prop:evt (struct-field-index base))

(define sema (make-semaphore))
(sync/timeout 0 (wt sema #f))
(semaphore-post sema)
(sync/timeout 0 (wt sema #f))
(semaphore-post sema)
(sync/timeout 0 (wt (lambda (self) (wt-val self)) sema))
(semaphore-post sema)
(define my-wt (wt (lambda (self)
                    (wrap-evt
                     (wt-val self)
                     (lambda (x) self)))
                  sema))
(sync/timeout 0 my-wt)
(sync/timeout 0 my-wt)
]}


@defparam[current-evt-pseudo-random-generator generator pseudo-random-generator?]{

一个 @tech{parameter}，决定 @racket[sync] 为 @racket[choice-evt] 创建的事件使用的伪随机数生成器。}

@close-eval[evt-eval]

