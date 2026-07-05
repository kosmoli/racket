#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/atomic
                     racket/future
                     ffi/unsafe/try-atomic))

@title{原子执行}

@defmodule[ffi/unsafe/atomic]

@deftech{原子模式} 计算 Racket 表达式时不切换到其他 Racket 线程，对事件的支持有限。从这个意义上讲，原子计算对其他的 @tech[#:doc reference.scrbl]{places}、@tech[#:doc reference.scrbl]{futures} 和 @tech[#:doc reference.scrbl]{parallel threads} 并不是原子的，只对同一 place 内的 @tech[#:doc reference.scrbl]{coroutine threads} 是原子的。在原子模式下，异步 break 异常（@racket[break-thread] 意义上的）也会被禁用，但由 @racket[start-breakable-atomic] 启动的除外。

@elemtag["atomic-unsafe"]{原子模式} 是 @tech[#:doc reference.scrbl]{unsafe} 的，因为 Racket 调度器在原子模式下无法正常执行：(1) 调度器不能切换 coroutine threads 或轮询某些类型的事件，这可能导致死锁或其他线程的饥饿；(2) 在原子模式下调用调度器相关函数的行为是未定义的，误用不一定会被检查捕获。直接与调度器相关的函数包括 @racket[thread]、@racket[sleep]、@racket[semaphore-wait]、@racket[semaphore-post]、@racket[channel-put]、@racket[channel-get] 和 @racket[sync]。注意其他操作也可能涉及这种同步，比如写入输出端口或使用 @racket[equal?]-based 哈希表。即使输出目标已知没有同步，也需要注意值可能通过 @racket[prop:custom-write] 附加了任意的打印过程。成功使用原子模式需要对可能在原子模式下到达的任何实现有详细的了解，以确保它终止且不涉及同步。

@tech{不可中断模式} 与 @tech{原子模式} 相关。它也是 @tech[#:doc reference.scrbl]{unsafe} 的，在 @tech[#:doc reference.scrbl]{coroutine thread} 中实际上与原子模式相同，但不可中断模式不会强制 @tech[#:doc reference.scrbl]{parallel thread} 与所有 coroutine threads 同步。不可中断模式还允许使用 @emph{未竞争} 的 semaphores 和 @racket[equal?]-based 哈希表。

@deftogether[(
@defproc[(start-atomic) void?]
@defproc[(end-atomic) void?]
)]{

通过禁用/恢复与同一 place 内任何 Racket @tech[#:doc reference.scrbl]{coroutine threads} 的并发性，来启动和结束 @tech{原子模式}，同时也暂停/恢复 break 异常的传递（独立于 @racket[break-enabled] 的结果）。@racket[start-atomic] 和 @racket[end-atomic] 的调用可以嵌套。

注意，将 @racket[start-atomic] 和 @racket[end-atomic] 与 @racket[dynamic-wind] 配对仅在以下情况下有用：

@itemlist[

 @item{当前的 @tech[#:doc reference.scrbl]{exception handler} 已知可以安全地退出原子模式，或者所有可能的退出方式都是通过已知的 continuation jump 或 abort（因为 break 已禁用且不可能有其他异常发生）来安全退出；并且}

 @item{异常构造,如果有的话,避免在异常消息中打印值,或者总是使用 @tech[#:doc reference.scrbl]{error value conversion handler} 且已知对原子模式是安全的。}

]

使用 @racket[call-as-atomic] 比使用 @racket[start-atomic] 和 @racket[end-atomic] 更安全一些，因为 @racket[call-as-atomic] 会捕获异常并在退出原子模式后重新引发它，并且它将任何对错误值转换处理器的调用用 @racket[call-as-nonatomic] 包装。然而，后者对于特定的原子区域只有在能够被非原子异常构造安全中断时才是安全的。另见 @racket[call-as-nonatomic-retry-point]。

与 @racket[call-as-atomic] 不同，@racket[start-atomic] 和 @racket[end-atomic] 可以由 @racketmodname[ffi/unsafe/os-thread] 支持的任何 OS 线程调用，虽然这些调用在 Racket 线程之外没有效果。在非 Racket 线程的 @tech[#:doc reference.scrbl]{future} 中使用 @racket[start-atomic] 会阻塞该 future，直到它被 @racket[touch] 在 Racket 线程中恢复。在 @tech[#:doc reference.scrbl]{parallel thread} 中使用 @racket[start-atomic] 会与同一 @tech[#:doc reference.scrbl]{place} 中的所有 @tech[#:doc reference.scrbl]{coroutine threads} 同步，但不会与其他 parallel threads 或 futures 同步。

另见 @elemref["atomic-unsafe"]{原子模式是 unsafe} 的警告。}


@deftogether[(
@defproc[(start-breakable-atomic) void?]
@defproc[(end-breakable-atomic) void?]
)]{

类似 @racket[start-atomic] 和 @racket[end-atomic]，但 break 异常的传递不会被暂停。

这些函数不比 @racket[start-atomic] 和 @racket[end-atomic] 快多少，所以在 break 被禁用的上下文环境中没有提供任何好处。}


@defproc[(call-as-atomic [thunk (-> any)]) any]{

在 @tech{原子模式} 中调用 @racket[thunk]，其中 @racket[call-as-nonatomic] 可在调用的动态期间内用于恢复到非原子模式以进行嵌套计算。

当 @racket[call-as-atomic] 在 @racket[call-as-atomic] 的动态期间内使用时，@racket[thunk] 被直接调用为非尾调用。

如果 @racket[thunk] 引发异常，该异常会被捕获并在退出原子模式后重新引发。对当前的 @tech[#:doc reference.scrbl]{error value conversion handler} 的任何调用都有效地被 @racket[call-as-nonatomic] 包装。

另见 @elemref["atomic-unsafe"]{原子模式是 unsafe} 的警告。}


@defproc[(call-as-nonatomic [thunk (-> any)]) any]{

在 @racket[call-as-atomic] 调用的动态期间内，以非原子模式调用 @racket[thunk]。注意在执行 @racket[thunk] 期间当前线程可能被其他线程暂停或终止。

当不在 @racket[call-as-atomic] 调用的动态期间内使用时，@racket[call-as-nonatomic] 会 raise @racket[exn:fail:contract]。}


@defproc[(in-atomic-mode?) boolean?]{

当在 @tech{原子模式} 或 @tech{不可中断模式} 中时（在当前 @tech[#:doc reference.scrbl]{place} 中）返回 @racket[#t]，否则返回 @racket[#f]。}


@deftogether[(
@defproc[(start-uninterruptible) void?]
@defproc[(end-uninterruptible) void?]
)]{

类似 @racket[start-atomic] 和 @racket[end-atomic]，但 @racket[start-uninterruptible] 之后和 @racket[end-uninterruptible] 之前的 continuation 可以与其他 Racket threads（包括 @tech[#:doc reference.scrbl]{coroutine threads} 和 @tech[#:doc reference.scrbl]{parallel threads}）并发执行，但处于 @deftech{不可中断模式}：该 continuation 将在不受其他线程中断的情况下到达 @racket[end-uninterruptible]。不可中断模式是 unsafe 的，就像 @elemref["atomic-unsafe"]{atomic mode is unsafe} 一样。

与 @racket[start-atomic] 不同，@racket[start-uninterruptible] 在 @CS[] 实现中不会阻塞与 Racket 线程并发运行的 future，也不会导致 parallel thread 与 coroutine threads 同步。同时，这样的 future 或 parallel thread 不能执行任何会阻塞 future 或需要与 coroutine threads 同步的动作；因此，在 future 或 parallel thread 中成功使用不可中断模式需要对 Racket 内部工作原理的了解。

作为一个特例，通过 @racket[make-hash] 等方式创建的、基于 @racket[equal?] 的可变哈希表，或 semaphore（通过 @racket[make-semaphore] 创建）可以在不可中断模式下使用，如果它 @emph{仅} 在不可中断模式下使用，从不并发使用；在 semaphore 的情况下，semaphore 的内部计数器在等待 semaphore 时必须是非零的。在不可中断模式中直接使用 semaphore 是没有意义的，但这个特例允许不可中断模式使用通常依赖 semaphore 进行锁定的数据结构，只要它们始终以这种方式使用即可。另见 @racket[make-uninterruptible-lock]。

@racket[start-uninterruptible] 和 @racket[end-uninterruptible] 可以嵌套调用，也可以在 coroutine thread 中与 @racket[start-atomic] 和 @racket[end-atomic] 相互嵌套。由于 @racket[start-atomic] 会阻塞 future 并需要与 parallel thread 同步，因此不能在 future 或 parallel thread 的 不可中断模式 中使用。

@history[#:added "8.17.0.7"
         #:changed "8.18.0.2" @elem{限制在 future 和 parallel 线程中使用不可中断模式。}]}


@defproc[(call-as-uninterruptible [thunk (-> any)]) any]{

类似 @racket[call-as-atomic]，但用于 @tech{不可中断模式}。

@history[#:added "8.17.0.7"]}



@deftogether[(
@defproc[(make-uninterruptible-lock) any/c]
@defproc[(uninterruptible-lock-acquire [lock any/c]) void?]
@defproc[(uninterruptible-lock-release [lock any/c]) void?]
)]{

一个 @deftech{不可中断锁} 提供低级同步，它与 @tech{不可中断模式} 跨 parallel threads 和 futures 协同工作。特别是，由于哈希表或 semaphore 可以@tech{不可中断模式}下使用但不能并发使用，不可中断锁可以用于保护对哈希表或 semaphore 的访问。

不可中断锁不与 coroutine thread 调度协作。@racket[uninterruptible-lock-acquire] 函数在进入不可中断模式之前立即进入，然后等待锁，而 @racket[uninterruptible-lock-release] 则在释放锁之后才退出不可中断模式。不可中断锁因此只适用于保护可预测的短动作，从 Racket 线程的角度来看，这些动作合理地被认为是原子的。

@history[#:added "8.18.0.5"]}
