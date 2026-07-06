#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "threads"]{线程}

@guideintro["concurrency"]{线程}

关于 Racket 线程模型的基本信息，参见 @secref["thread-model"]。另请参见 @secref["futures"] 和 @secref["places"]。

线程被创建时，它会被交由 @tech{current custodian} 管理，并被添加到当前的 @tech{thread group}。一个线程可以通过 @racket[thread-resume] 添加任意数量的 custodian 管理器。
线程的内存分配会被计入该线程的 custodian 管理器。
参见 @racket[custodian-limit-memory] 了解示例。

尚未终止的线程可以被垃圾回收 (参见 @secref["gc-model"])，如果它是不可达的且已挂起的，或者如果它是不可达的且仅通过 @racket[semaphore-wait]、@racket[semaphore-wait/enable-break]、@racket[channel-put]、@racket[channel-get]、@racket[sync]、@racket[sync/enable-break] 或 @racket[thread-wait] 等函数被阻塞在不可达的事件上。但请注意 @tech{place-channel} 阻塞的限制；参见 @secref["places"] 中的 @elemref['(caveat "place-channel-gc")]{警告}。

@margin-note{在 GRacket 中，eventspace 的 handler 线程在其事件队列为空时会被阻塞在一个内部 semaphore 上。因此，当 eventspace 不可达且不包含可见窗口或运行中的定时器时，handler 线程是可被回收的。}

线程可以用作 @tech{synchronizable event} (参见 @secref["sync"])。当 @racket[thread-wait] 不会阻塞时，线程处于 @tech{ready for synchronization} 状态；@resultItself{thread}。

@;------------------------------------------------------------------------
@section{Creating Threads}

@defproc[(thread [thunk (-> any)]
                 [#:pool pool (or/c #f 'own parallel-thread-pool?) #f]
                 [#:keep keep (or/c #f 'results) #f])
         thread?]{

在新的控制线程中调用 @racket[thunk]（无参数）。@racket[thread] 过程立即返回一个 @deftech{thread descriptor} 值。当 @racket[thunk] 的调用返回时，为调用 @racket[thunk] 而创建的线程终止。

如果 @racket[pool] 为 @racket[#f]，则生成的线程是 @tech{coroutine thread}。如果 @racket[pool] 为 @racket['own]，则创建一个新的 @tech{parallel thread pool}，线程被添加到该池中，并且该池被关闭（在 @racket[parallel-thread-pool-close] 的意义上）以阻止添加其他线程。如果 @racket[pool] 是一个 parallel thread pool，则新线程在该池中创建，这意味着它与同一池中的其他线程共享处理器资源。
@;
@margin-note*{关于 parallel threads 和性能的信息，参见 @guidesecref["parallel-threads"]。Parallel threads 在 Racket 的 @tech{BC} 变体上或当 Racket 构建时未启用并行支持时不会并行运行。更多信息，参见 @tech{parallel thread pool} 的描述。}

如果 @racket[keep] 为 @racket['results]，则结果会与线程一起记录，以便可以通过 @racket[thread-wait] 报告。
否则，@racket[thunk] 的结果将被忽略。

@history[#:changed "8.18.0.2" @elem{添加了 @racket[#:pool] 和 @racket[#:keep] 参数。}]}

@defproc[(thread? [v any/c]) thread?]{如果 @racket[v] 是 @tech{thread descriptor}，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(current-thread) thread?]{返回当前正在执行的线程的 @tech{thread descriptor}。}

@defproc[(thread/suspend-to-kill [thunk (-> any)]) thread?]{

类似于 @racket[thread]，但通过 @racket[kill-thread] 或 @racket[custodian-shutdown-all] "杀死" 线程只会挂起该线程，而不是终止它。}

@defproc[(call-in-nested-thread [thunk (-> any)]
                                [cust custodian? (current-custodian)]) 
          any]{

创建一个由 @racket[cust] 管理的嵌套线程来执行 @racket[thunk]。（嵌套线程的当前 custodian 从创建线程继承，与 @racket[cust] 参数无关。）
当前线程阻塞直到 @racket[thunk] 返回，@racket[call-in-nested-thread] 调用的结果就是 @racket[thunk] 返回的结果。

嵌套线程的 exception handler 被初始化为一个过程，该过程跳转到线程开始处并将异常转移到原始线程。因此，handler 终止嵌套线程并在原始线程中重新引发异常。

如果 @racket[call-in-nested-thread] 创建的线程在 @racket[thunk] 返回之前死亡，则在原始线程中 @exnraise[exn:fail]。如果原始线程在 @racket[thunk] 返回之前被杀死，则向嵌套线程排队一个 break。

如果原始线程（通过 @racket[break-thread]）在嵌套线程运行时有一个 break 排队，则该 break 被重定向到嵌套线程。如果嵌套线程创建时原始线程已有一个 break 排队，则该 break 被移动到嵌套线程。如果嵌套线程完成时仍有一个 break 排队在嵌套线程上，则该 break 被移动到原始线程。

如果 @racket[call-in-nested-thread] 创建的线程在其自身调用 @racket[call-in-nested-thread] 时死亡，则外部 @racket[call-in-nested-thread] 调用等待最内层的嵌套线程完成，并且内层线程上任何待处理的 break 都被移动到原始线程。}

@;------------------------------------------------------------------------
@section[#:tag "threadkill"]{挂起、恢复和终止线程}

@defproc[(thread-suspend [thd  thread?]) void?]{

如果 @racket[thd] 正在运行，则立即暂停其执行。如果线程已终止或已挂起，@racket[thread-suspend] 无效。线程保持暂停状态（即不执行），直到通过 @racket[thread-resume] 恢复。如果 @tech{current custodian} 不单独管理 @racket[thd]（即 @racket[thd] 的某个 custodian 不是当前 custodian 或下属），则 @exnraise[exn:fail:contract]，且线程不会被挂起。}

@defproc[(thread-resume [thd thread?] [benefactor (or/c thread? custodian? #f) #f]) void?]{

如果 @racket[thd] 已挂起且至少有一个 custodian（可能通过 @racket[benefactor] 添加，如下所述），则恢复其执行。如果线程已终止，或线程已在运行且未提供 @racket[benefactor]，或线程没有 custodian 且未提供 @racket[benefactor]，则 @racket[thread-resume] 无效。否则，如果提供了 @racket[benefactor]，它会触发最多三个额外操作：

@itemize[

   @item{如果 @racket[benefactor] 是一个线程，则每当它将来从挂起状态恢复时，@racket[thd] 也会被恢复。（恢复 @racket[thd] 可能触发先前通过 @racket[thread-resume] 附加到 @racket[thd] 的其他线程的恢复。）}

   @item{新的 custodians 可能会被添加到 @racket[thd] 的管理器集合中。如果 @racket[benefactor] 是一个线程，则该线程的所有 custodians 都会被添加到 @racket[thd]。否则，@racket[benefactor] 是一个 custodian，它会被添加到 @racket[thd]（除非该 custodian 已关闭）。如果 @racket[thd] 变得同时由一个 custodian 及其一个或多个下属管理，则多余的下属会从 @racket[thd] 中移除。如果 @racket[thd] 被挂起并添加了 custodian，则 @racket[thd] 仅在添加之后才被恢复。}

   @item{如果 @racket[benefactor] 是一个线程，则每当它在将来获得新的管理 custodian 时，@racket[thd] 也会获得该 custodian。（向 @racket[thd] 添加 custodians 可能触发将 custodians 添加到先前通过 @racket[thread-resume] 附加到 @racket[thd] 的其他线程。）}

]}


@defproc[(kill-thread [thd thread?]) void?]{

立即终止指定的线程，或者如果 @racket[thd] 是通过 @racket[thread/suspend-to-kill] 创建的，则暂停该线程。终止主线程会退出应用程序。如果 @racket[thd] 已终止，@racket[kill-thread] 不执行任何操作。如果 @tech{current custodian} 不单独管理 @racket[thd]（即 @racket[thd] 的某个 custodian 不是当前 custodian 或下属），则 @exnraise[exn:fail:contract]，且线程不会被终止或挂起。

除非另有说明，Racket（和 GRacket）提供的过程都是 kill-safe 和 suspend-safe 的；即杀死或挂起一个线程永远不会干扰其他线程中过程的应用。例如，如果一个线程在从 input port 提取字符时被杀死，则该字符要么被完全消耗，要么不被消耗，其他线程可以安全地使用该 port。}

@defproc[(break-thread [thd thread?]
                       [kind (or/c #f 'hang-up 'terminate) #f])
         void?]{

@index['("threads" "breaking")]{注册}一个与指定线程的 break。可选的 @racket[kind] 值指示要注册的 break 类型，其中 @racket[#f]、@racket['hang-up] 和 @racket['terminate] 分别对应 interrupt、hang-up 和 terminate break。
如果 @racket[thd] 中禁用了 breaking，则该 break 将被忽略，直到重新启用 breaking。
详见 @secref["breakhandler"]。}

@defproc[(sleep [secs (>=/c 0) 0]) void?]{

使当前线程休眠，直到至少 @racket[secs] 秒已过。@racket[secs] 的零值仅作为允许其他线程执行的提示。@racket[secs] 的值可以是非整数，以请求任意精度的休眠时间；实际睡眠时间的精度未指定。}

@defproc[(thread-running? [thd  thread?]) any]{

@index['("threads" "run state")]{返回} @racket[#t] 如果 @racket[thd] 未终止且未挂起，否则返回 @racket[#f]。}

@defproc[(thread-dead? [thd  thread?]) any]{

返回 @racket[#t] 如果 @racket[thd] 已终止，否则返回 @racket[#f]。}

@;------------------------------------------------------------------------
@section[#:tag "threadsync"]{同步线程状态}

@defproc[(thread-wait [thd thread?]
                      [fail-k (procedure-arity-includes/c 0) void])
         any]{

阻塞当前线程的执行，直到 @racket[thd] 终止。如果线程的过程引发了异常，或者线程被中止到其初始 @tech{prompt}，或者线程被杀死，则调用 @racket[fail-k] 来生成 @racket[thread-wait] 的结果。否则，如果线程记录了其结果（参见 @racket[thread] 中的 @racket[#:keep]），则返回这些结果；如果线程不保留其结果，则返回 @|void-const|。

注意 @racket[(thread-wait (current-thread))] 会使当前线程死锁，但如果 breaking 已启用且线程是主线程或可访问的，则 break 可以结束死锁；参见 @secref["breakhandler"]。

除非 @racket[thd] 是用 @racket[thread/suspend-to-kill] 创建的，否则 @racket[(thread-wait thd)] 即使 @racket[thd] 以其他方式不可访问也可能继续，因为 @tech{custodian} 关闭可能会终止线程。因此，使用 @racket[thread-wait] 阻塞的线程通常不能被垃圾回收（参见 @secref["gc-model"]）。但作为特殊情况，如果 @racket[thd] 是当前线程，则 @racket[(thread-wait thd)] 阻塞而不阻止线程的垃圾回收，因为线程只有在 break 从等待中逃逸时才能继续。

@history[#:changed "8.18.0.2" @elem{添加了对带值线程和 @racket[fail-k] 参数的支持。}]}

@defproc[(thread-dead-evt [thd thread?]) evt?]{

返回一个 @tech{synchronizable event}（参见 @secref["sync"]），当且仅当 @racket[thd] 已终止时，该事件处于 @tech{ready for synchronization} 状态。但与直接使用 @racket[thd] 不同，保留对事件的引用不会阻止 @racket[thd] 被垃圾回收（参见 @secref["gc-model"]）。@ResultItself{thread-dead event}。

等待 @racket[(thread-dead-evt thd)] 结果的线程通常本身不能被垃圾回收，除非 @racket[thd] 是用 @racket[thread/suspend-to-kill] 创建的，这与通过 @racket[thread-wait] 等待的情况类似。但是，对于等待 @racket[(thread-dead-evt thd)] 结果且 @racket[thd] 是当前线程的情况，没有特殊情况。

对于给定的 @racket[thd]，@racket[thread-dead-evt] 总是返回相同的（即 @racket[eq?]）结果。}


@defproc[(thread-resume-evt [thd thread?]) evt?]{

返回一个 @tech{synchronizable event}（参见 @secref["sync"]），当 @racket[thd] 运行时，该事件变为 @tech{ready for synchronization} 状态。（如果 @racket[thd] 已终止，事件永远不会变为 ready。）如果 @racket[thd] 运行后在 @racket[thread-resume-evt] 调用之后被挂起，结果事件保持 ready；在 @racket[thd] 每次挂起后，会生成一个新事件由 @racket[thread-resume-evt] 返回。事件的结果是 @racket[thd]，但如果 @racket[thd] 从未恢复，则对事件的引用不会阻止 @racket[thd] 被垃圾回收（参见 @secref["gc-model"]）。}

@defproc[(thread-suspend-evt [thd thread?]) evt?]{

返回一个 @tech{synchronizable event}（参见 @secref["sync"]），当 @racket[thd] 被挂起时，该事件变为 @tech{ready for synchronization} 状态。（如果 @racket[thd] 已终止，事件永远不会解除阻塞。）如果 @racket[thd] 被挂起后在 @racket[thread-suspend-evt] 调用之后恢复，结果事件保持 ready；@racket[thd] 每次恢复都会生成一个新事件由 @racket[thread-suspend-evt] 返回。事件的结果是 @racket[thd]，但如果 @racket[thd] 是用 @racket[thread]（而非 @racket[thread/suspend-to-kill]）创建的且从未恢复，则对事件的引用不会阻止 @racket[thd] 被垃圾回收（参见 @secref["gc-model"]）。

如果 @racket[thd] 是用 @racket[thread/suspend-to-kill] 创建的，则等待 @racket[(thread-suspend-evt thd)] 会阻止等待线程的垃圾回收，方式与 @racket[(thread-dead-evt _another-thd)] 对通过 @racket[thread] 创建的 @racket[_another-thd] 相同。此外，由于事件结果是 @racket[thd]，等待 @racket[(thread-suspend-evt thd)] 会阻止 @racket[thd] 的垃圾回收。

}

@;------------------------------------------------------------------------
@section[#:tag "threadmbox"]{线程邮箱}

每个线程都有一个 @defterm{邮箱}，通过它可以接收任意消息。换句话说，每个线程都有一个内置的异步 channel。

@margin-note/ref{另请参见 @secref["async-channel"]。}

@defproc[(thread-send [thd thread?] [v any/c] 
                      [fail-thunk (or/c (-> any) #f)
                                  (lambda () (raise-mismatch-error ....))]) 
         any]{

将 @racket[v] 作为消息排队到 @racket[thd]，不阻塞。如果消息已排队，结果为 @|void-const|。如果 @racket[thd] 在消息排队之前停止运行（如 @racket[thread-running?] 所示），则如果 @racket[fail-thunk] 是过程，调用它（通过尾调用）产生结果，或者如果 @racket[fail-thunk] 是 @racket[#f]，返回 @racket[#f]。}

@defproc[(thread-receive) any/c]{

接收并出队当前线程排队的消息（如果有）。如果没有可用消息，@racket[thread-receive] 阻塞直到有消息可用。}

@defproc[(thread-try-receive) any/c]{

接收并出队当前线程排队的消息（如果有），或者如果没有可用消息，立即返回 @racket[#f]。}

@defproc[(thread-receive-evt) evt?]{

返回一个常量 @tech{synchronizable event}（参见 @secref["sync"]），当同步线程有消息可接收时，该事件变为 @tech{ready for synchronization} 状态。@ResultItself{thread-receive event}。}

@defproc[(thread-rewind-receive [lst list?]) void?]{

将 @racket[lst] 的元素推回到当前线程队列的前端。元素逐个推入，因此第一个可用的消息是 @racket[lst] 的最后一个元素。}

@;------------------------------------------------------------------------
@section[#:tag "threadpool"]{并行线程池}

@defproc[(parallel-thread-pool? [v any/c]) thread?]{如果 @racket[v] 是 @tech{parallel thread pool}，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(make-parallel-thread-pool [n exact-positive-integer? (processor-count)])
         parallel-thread-pool?]{

创建一个 @deftech{parallel thread pool}，可用于将 @tech{parallel thread} 与其他 parallel threads 分组。池中的线程最多可以使用 @racket[n] 个处理器运行。如果池中有多于 @racket[n] 个线程，则并非所有线程都会并行运行，但它们仍会并发运行。

新的线程池被交由当前 @tech{custodian} 管理。如果 custodian 被关闭，则池以与 @racket[parallel-thread-pool-close] 相同的方式关闭。
池中任何已有的线程可以继续使用池的资源（除非它们也被同一 custodian 关闭）。

在 Racket 的 @tech{BC} 变体上或当 Racket 构建时未启用并行支持时，parallel thread pool 无法并行运行线程。在这种情况下，parallel threads 的行为与 @tech{coroutine threads} 相同。对于 Racket 的 @tech{CS} 变体，@racket[futures-enabled?] 谓词可用于检测 parallel threads 何时与 coroutine threads 行为不同。}

@defproc[(parallel-thread-pool-close [p parallel-thread-pool?])
         void?]{

关闭 @tech{parallel thread pool}，使线程无法添加到池中。池中任何已有的线程被允许继续运行，它们继续共享池的处理器资源。

当关闭的线程池中不再有运行的线程，或者由于池的 @tech{custodian} 已关闭而不允许任何线程取得进展时，分配给池的处理器资源可以返回给操作系统（即，分配给池的操作系统线程被终止）。

@history[#:added "8.18.0.2"]}
