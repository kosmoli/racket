#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "parallel-threads"]{Parallel Threads}

使用 @deftech{并行线程池}创建的 @tech{线程}可以使用与其他线程不同的硬件处理器，从而在并发之外提供并行性。当硬件可用时，使用这些 @deftech{并行线程}可以减少计算的延迟。

@margin-note{并行线程的一个权衡是，由于创建和管理并行任务的开销，计算可能变慢而不是变快。}

@margin-note{Racket 的 @tech{BC} 实现将所有线程视为 @tech{协程线程}，并且不并行运行它们。}

使用 @racket[thread] 的 @racket[#:pool] 参数创建并行线程，其中 @racket['own] 表示该线程拥有自己的单线程池。

@racketblock[
(define (fib n)
  (cond
   [(= n 0) 1]
   [(= n 1) 1]
   [else (+ (fib (- n 1)) (fib (- n 2)))]))   
(define n1 (thread (lambda () (fib 35))
                   #:pool 'own
                   #:keep 'results))
(define n2 (thread (lambda () (fib 35))
                   #:pool 'own
                   #:keep 'results))
(time (= (thread-wait n1)
         (thread-wait n2)))
]

并行线程是否能提高性能取决于计算的性质。可以高效并行运行的计算类型大多与可以在 @tech{future} 中运行的类型相同，@secref["effective-futures"] 提供了更多信息并描述了 @tech{future 可视化器}如何帮助解释程序的性能。与并行线程的区别在于，当 future 会阻塞时，并行线程反而与其他线程同步以继续——希望很快达到一个没有阻塞动作的清晰点。此外，并行线程可以自由使用 @tech{参数}和异常处理器，这些在 future 中受限，直到 @racket[touch] 为 future 提供完整的动态上下文。最后，并行线程实现了与 @tech{协程线程}相同的同步接口，包括 @racket[thread-wait]、@racket[thread-send] 和 @racket[kill-thread]。

Racket 的预定义构造（如输入和输出端口或可变哈希表）是线程安全的，并在内部按需要使用锁。线程可以并行执行一些输入和输出操作，特别是从不会阻塞的常规文件。同时，阻塞的输入和输出操作不仅干扰并行性，而且对于并行线程来说，它们比协程线程更昂贵得多，因为需要额外的调度。与线程调度交互的操作（如 @racket[sleep]、@racket[sync]、@racket[thread]、@racket[thread-wait]、@racket[kill-thread] 和 @racket[custodian-shutdown-all]）都需要调度，当从并行线程触发时，这些调度可能更昂贵。

@racket[semaphore-post] 和 @racket[semaphore-wait] 操作在并行线程中可以很便宜，只要没有线程最终阻塞在信号量上。当线程阻塞在信号量上时，对信号量操作与线程调度相互作用，因此在并行线程中更慢。在某些情况下，使用 @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{future 信号量}（比普通信号量更有限）可以为并行线程提供更好的性能。
