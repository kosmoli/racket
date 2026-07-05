#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "semaphore"]{信号量}

@deftech{semaphore} 有一个内部计数器；当这个计数器为零时，信号量可以通过 @racket[semaphore-wait] 阻塞线程的执行，直到另一个线程使用 @racket[semaphore-post] 增加计数器。信号量内部计数器的最大值为平台特定的，但始终至少为 @racket[10000]。

信号量的计数器以单线程方式更新，因此信号量可用于可靠的同步。信号量等待是 @defterm{公平的}：如果线程在信号量上阻塞，并且信号量的内部值无限次非零，则线程最终将被解除阻塞。

除了与信号量特定过程一起使用外，信号量还可以用作 @tech{synchronizable event}（参见 @secref["sync"]）。信号量在 @racket[semaphore-wait] 不会阻塞时为 @tech{ready for synchronization}。同步时，信号量的计数器递减，@resultItself{semaphore}。

@defproc[(semaphore? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{semaphore} 返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-semaphore [init exact-nonnegative-integer? 0]) semaphore?]{

创建并返回一个新信号量，计数器初始设置为 @racket[init]。如果 @racket[init] 大于信号量的最大内部计数器值，则触发 @exnraise[exn:fail]。}


@defproc[(semaphore-post [sema semaphore?]) void?]{递增信号量的内部计数器并返回 @|void-const|。如果信号量的内部计数器已达到其最大值，则触发 @exnraise[exn:fail]。}

@defproc[(semaphore-wait [sema semaphore?]) void?]{阻塞，直到信号量 @racket[sema] 的内部计数器非零。当计数器为非零时，它递减，@racket[semaphore-wait] 返回 @|void-const|。}

@defproc[(semaphore-try-wait? [sema semaphore?]) boolean?]{与 @racket[semaphore-wait] 类似，但 @racket[semaphore-try-wait?] 从不阻塞执行。如果 @racket[sema] 的内部计数器为零，则立即返回 @racket[#f] 而不递减计数器。如果 @racket[sema] 的计数器为正，则它递减并返回 @racket[#t]。}

@defproc[(semaphore-wait/enable-break [sema semaphore?]) void?]{与 @racket[semaphore-wait] 类似，但在等待 @racket[sema] 时启用中断（参见 @secref["breakhandler"]）。如果调用 @racket[semaphore-wait/enable-break] 时禁用中断，则递减信号量的计数器或引发 @racket[exn:break] 异常，但不会两者都发生。}

@defproc[(semaphore-peek-evt [sema semaphore?]) semaphore-peek-evt?]{创建一个返回一个新的 @tech{synchronizable event}（例如用于 @racket[sync]），当 @racket[sema] 准备好时该事件为同步就绪，但该事件的同步不减少 @racket[sema] 的内部计数。@resultItself{semaphore-peek event}。}

@defproc[(semaphore-peek-evt? [v any/c]) boolean?]{

如果 @racket[v] 是 @racket[semaphore-peek-evt] 产生的信号量包装则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(call-with-semaphore [sema semaphore?]
                              [proc procedure?]
                              [try-fail-thunk (or/c (-> any) #f) #f]
                              [arg any/c] ...) any]{

使用 @racket[semaphore-wait] 等待 @racket[sema]，然后用所有 @racket[arg] 调用 @racket[proc]，然后传递给 @racket[sema]。@tech{continuation barrier} 阻止完整 continuation 进出 @racket[proc]（参见 @secref["prompt-model"]），但允许跳转，并且在跳转时发布 @racket[sema]。如果提供了 @racket[try-fail-thunk] 且不为 @racket[#f]，则在 @racket[sema] 上使用 @racket[semaphore-try-wait?] 而不是 @racket[semaphore-wait]，如果等待失败则调用 @racket[try-fail-thunk]。}

@defproc[(call-with-semaphore/enable-break [sema semaphore?]
                              [proc procedure?]
                              [try-fail-thunk (or/c (-> any) #f) #f]
                              [arg any/c] ...) any]{

与 @racket[call-with-semaphore] 类似，只是在非 try 模式下使用 @racket[semaphore-wait/enable-break] 和 @racket[sema]。当提供 @racket[try-fail-thunk] 且不为 @racket[#f] 时，在 @racket[sema] 周围使用 @racket[semaphore-try-wait?] 启用中断。}
