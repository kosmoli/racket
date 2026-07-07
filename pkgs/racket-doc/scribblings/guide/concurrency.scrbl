#lang scribble/doc
@(require scribble/manual
          scribble/examples
          "guide-utils.rkt"
          (for-label racket racket/async-channel))

@(define concurrency-eval (make-base-eval))
@(concurrency-eval '(require racket/contract racket/math))

@(define reference-doc '(lib "scribblings/reference/reference.scrbl"))

@title[#:tag "concurrency"]{Concurrency and Synchronization}

Racket 以 @deftech{thread} 的形式提供 @deftech{concurrency}，并提供一个通用的 @racket[sync] 函数，
可用于同步 thread 以及其他隐式的并发形式，例如 @tech{port}。

Thread 以并发方式运行，即一个 thread 可以在另一个 thread 无协作的情况下抢占它，
但默认情况下，thread 不会以使用多个硬件处理器的方式并行运行。这种默认类型的
thread 称为 @deftech{coroutine thread}。有关 Racket 中并行性的信息，请参见
@secref["parallelism"]。

@section{Threads}

要并发执行一个过程，请使用 @racket[thread]。以下示例从主线程创建两个新 thread：

@racketblock[
(displayln "This is the original thread")
(thread (lambda () (displayln "This is a new thread.")))
(thread (lambda () (displayln "This is another new thread.")))
]

下一个示例创建一个新 thread，该 thread 本应无限循环，但主线程使用 @racket[sleep] 暂停自身 2.5 秒，
然后使用 @racket[kill-thread] 终止工作 thread：

@racketblock[
(define worker (thread (lambda ()
                         (let loop ()
                           (displayln "Working...")
                           (sleep 0.2)
                           (loop)))))
(sleep 2.5)
(kill-thread worker)
]

@margin-note{在 DrRacket 中，主线程会一直运行直到点击 Stop 按钮，因此在 DrRacket 中不需要 @racket[thread-wait]。}

如果主线程完成或被终止，应用程序将退出，即使其他 thread 仍在运行。
一个 thread 可以使用 @racket[thread-wait] 等待另一个 thread 完成。
这里，主线程使用 @racket[thread-wait] 确保工作 thread 在主线程退出之前完成：

@racketblock[
(define worker (thread
                 (lambda ()
                   (for ([i 100])
                     (printf "Working hard... ~a~n" i)))))
(thread-wait worker)
(displayln "Worker finished")
]

要从一个 thread 接收结果，请在创建该 thread 时使用 @racket[#:keep 'results]，
然后 @racket[thread-wait] 可以返回该 thread 的过程所返回的值：

@racketblock[
(define worker (thread (lambda () (+ 1 2))
                       #:keep 'results))
(thread-wait worker)
]


@section{Thread Mailboxes}

每个 thread 都有一个用于接收消息的邮箱。@racket[thread-send] 函数异步地向另一个 thread 的邮箱发送消息，
而 @racket[thread-receive] 则从当前 thread 的邮箱中返回最早的消息，必要时会阻塞等待消息。
在以下示例中，主线程向工作 thread 发送数据进行处理，然后在没有更多数据时发送 @racket['done] 消息，
并等待工作 thread 完成。

@racketblock[
(define worker-thread (thread
                       (lambda ()
                         (let loop ()
                           (match (thread-receive)
                             [(? number? num)
                              (printf "Processing ~a~n" num)
                              (loop)]
                             ['done
                              (printf "Done~n")])))))
(for ([i 20])
  (thread-send worker-thread i))
(thread-send worker-thread 'done)
(thread-wait worker-thread)
]

在下一个示例中，主线程将工作委托给多个算术 thread，然后等待接收结果。
算术 thread 处理工作项，然后将结果发送回主线程。

@racketblock[
(define (make-arithmetic-thread operation)
  (thread (lambda ()
            (let loop ()
              (match (thread-receive)
                [(list oper1 oper2 result-thread)
                 (thread-send result-thread
                              (format "~a ~a ~a = ~a"
                                      oper1
                                      (object-name operation)
                                      oper2
                                      (operation oper1 oper2)))
                 (loop)])))))

(define addition-thread (make-arithmetic-thread +))
(define subtraction-thread (make-arithmetic-thread -))

(define worklist '((+ 1 1) (+ 2 2) (- 3 2) (- 4 1)))
(for ([item worklist])
  (match item
    [(list '+ o1 o2)
     (thread-send addition-thread
                  (list o1 o2 (current-thread)))]
    [(list '- o1 o2)
     (thread-send subtraction-thread
                  (list o1 o2 (current-thread)))]))

(for ([i (length worklist)])
  (displayln (thread-receive)))
]

@section{Semaphores}

Semaphore 有助于对任意共享资源进行同步访问。
当多个 thread 必须对单个资源执行非原子操作时，请使用 semaphore。

在以下示例中，多个 thread 并发地向标准输出打印。如果没有同步，一个 thread 打印的行
可能会出现在另一个 thread 打印的行的中间。通过使用一个以 @racket[1] 初始化的 semaphore，
同一时间只有一个 thread 会打印。@racket[semaphore-wait] 函数会阻塞直到 semaphore 的内部计数器
非零，然后递减计数器并返回。@racket[semaphore-post] 函数递增计数器，
以便另一个 thread 可以解除阻塞并打印。

@racketblock[
(define output-semaphore (make-semaphore 1))
(define (make-thread name)
  (thread (lambda ()
            (for [(i 10)]
              (semaphore-wait output-semaphore)
              (printf "thread ~a: ~a~n" name i)
              (semaphore-post output-semaphore)))))
(define threads
  (map make-thread '(A B C)))
(for-each thread-wait threads)
]

等待 semaphore、执行工作、然后向 semaphore 发送信号的模式也可以使用
@racket[call-with-semaphore] 来表达，其优势在于当控制逃离时（例如由于异常）
会自动向 semaphore 发送信号：

@racketblock[
(define output-semaphore (make-semaphore 1))
(define (make-thread name)
  (thread (lambda ()
            (for [(i 10)]
              (call-with-semaphore
               output-semaphore
               (lambda ()
                (printf "thread ~a: ~a~n" name i)))))))
(define threads
  (map make-thread '(A B C)))
(for-each thread-wait threads)
]

Semaphore 是一种低级技术。通常，更好的解决方案是将资源访问限制在单个 thread 中。
例如，对标准输出的同步访问可以通过使用一个专门用于打印输出的 thread 来更好地实现。

@section{Channels}

Channel 在两个 thread 之间同步，同时将一个值从一个 thread 传递到另一个 thread。
与 thread 邮箱不同，多个 thread 可以从单个 channel 获取项，
因此当多个 thread 需要从单个工作队列中消费项时，应使用 channel。

在以下示例中，主线程使用 @racket[channel-put] 将项添加到 channel，
而多个工作 thread 使用 @racket[channel-get] 消费这些项。
对任一过程的每次调用都会阻塞，直到另一个 thread 使用相同的 channel 调用另一个过程。
工作 thread 处理这些项，然后通过 @racket[result-channel] 将结果传递给结果 thread。

@racketblock[
(define result-channel (make-channel))
(define result-thread
        (thread (lambda ()
                  (let loop ()
                    (display (channel-get result-channel))
                    (loop)))))

(define work-channel (make-channel))
(define (make-worker thread-id)
  (thread
   (lambda ()
     (let loop ()
       (define item (channel-get work-channel))
       (case item
         [(DONE)
          (channel-put result-channel
                       (format "Thread ~a done\n" thread-id))]
         [else
          (channel-put result-channel
                       (format "Thread ~a processed ~a\n"
                               thread-id
                               item))
          (loop)])))))
(define work-threads (map make-worker '(1 2)))
(for ([item '(A B C D E F G H DONE DONE)])
  (channel-put work-channel item))
(for-each thread-wait work-threads)
(channel-put result-channel "") (code:comment "waits until result-thread has printed all other output")
]

@section{Buffered Asynchronous Channels}

缓冲异步 channel 与上面描述的 channel 类似，但异步 channel 的 ``put'' 操作不会阻塞——
除非该 channel 创建时设置了缓冲区限制且已达到限制。
异步 put 操作因此与 @racket[thread-send] 类似，但与 thread 邮箱不同，
异步 channel 允许多个 thread 从单个 channel 中消费项。

在以下示例中，主线程向工作 channel 添加项，该 channel 最多同时容纳三个项。
工作 thread 从这个 channel 中处理项，然后将结果发送给打印 thread。

@racketblock[
(require racket/async-channel)

(define print-thread
  (thread (lambda ()
            (let loop ()
              (displayln (thread-receive))
              (loop)))))
(define (safer-printf . items)
  (thread-send print-thread
               (apply format items)))

(define work-channel (make-async-channel 3))
(define (make-worker-thread thread-id)
  (thread
   (lambda ()
     (let loop ()
       (define item (async-channel-get work-channel))
       (safer-printf "Thread ~a processing item: ~a" thread-id item)
       (loop)))))

(for-each make-worker-thread '(1 2 3))
(for ([item '(a b c d e f g h i j k l m)])
  (async-channel-put work-channel item))
]

注意上面的示例缺少任何同步来验证所有项都已被处理。如果主线程在没有这种同步的情况下退出，
工作 thread 可能不会完成处理某些项，或者打印 thread 不会打印所有项。

@section{Synchronizable Events and @racket[sync]}

还有其他同步 thread 的方式。@racket[sync] 函数允许 thread 通过
@tech[#:doc reference-doc]{synchronizable event} 进行协调。
许多值同时充当 event，允许以统一的方式使用不同类型来同步 thread。
event 的示例包括 channel、port、thread 和 alarm。本节通过多个示例展示
event、thread 和 @racket[sync]（以及递归函数）的组合如何允许你实现
任意复杂的通信协议来协调程序的并发部分。

在下一个示例中，channel 和 alarm 被用作 synchronizable event。
工作 thread 对两者进行 @racket[sync]，以便它们可以处理 channel 项直到 alarm 被激活。
Channel 项被处理后，结果被发送回主线程。

@racketblock[
(define main-thread (current-thread))
(define alarm (alarm-evt (+ 3000 (current-inexact-milliseconds))))
(define channel (make-channel))
(define (make-worker-thread thread-id)
  (thread
   (lambda ()
     (define evt (sync channel alarm))
     (cond
       [(equal? evt alarm)
        (thread-send main-thread 'alarm)]
       [else
        (thread-send main-thread
                     (format "Thread ~a received ~a"
                             thread-id
                             evt))]))))
(make-worker-thread 1)
(make-worker-thread 2)
(make-worker-thread 3)
(channel-put channel 'A)
(channel-put channel 'B)
(let loop ()
  (match (thread-receive)
    ['alarm
     (displayln "Done")]
    [result
     (displayln result)
     (loop)]))
]

下一个示例展示了一个用于简单 TCP echo 服务器的函数。该函数使用 @racket[sync/timeout]
对来自给定 port 的输入或 thread 邮箱中的消息进行同步。@racket[sync/timeout] 的第一个参数
指定应在给定 event 上等待的最大秒数。@racket[read-line-evt] 函数返回一个 event，
当给定输入 port 中有可用的行输入时该 event 就绪。@racket[thread-receive-evt] 的结果在
@racket[thread-receive] 不会阻塞时就绪。在实际应用中，thread 邮箱中接收的消息
可用于控制消息等。

@racketblock[
(define (serve in-port out-port)
  (let loop []
    (define evt (sync/timeout 2
                              (read-line-evt in-port 'any)
                              (thread-receive-evt)))
    (cond
      [(not evt)
       (displayln "Timed out, exiting")
       (tcp-abandon-port in-port)
       (tcp-abandon-port out-port)]
      [(string? evt)
       (fprintf out-port "~a~n" evt)
       (flush-output out-port)
       (loop)]
      [else
       (printf "Received a message in mailbox: ~a~n"
               (thread-receive))
       (loop)])))
]

@racket[serve] 函数用于以下示例中，该示例启动一个服务器 thread 和一个客户端 thread，
它们通过 TCP 通信。客户端向服务器打印三行，服务器将其回显。
客户端的 @racket[copy-port] 调用会阻塞直到收到 EOF。服务器在两秒后超时，
关闭 port，这使得 @racket[copy-port] 可以完成，客户端可以退出。
主线程使用 @racket[thread-wait] 等待客户端 thread 退出
（因为如果没有 @racket[thread-wait]，主线程可能在其他 thread 完成之前退出）。

@racketblock[
(define port-num 4321)
(define (start-server)
  (define listener (tcp-listen port-num))
  (thread
    (lambda ()
      (define-values [in-port out-port] (tcp-accept listener))
      (serve in-port out-port))))

(start-server)

(define client-thread
  (thread
   (lambda ()
     (define-values [in-port out-port] (tcp-connect "localhost" port-num))
     (display "first\nsecond\nthird\n" out-port)
     (flush-output out-port)
     (code:comment "copy-port will block until EOF is read from in-port")
     (copy-port in-port (current-output-port)))))

(thread-wait client-thread)
]

有时，你希望将结果行为直接附加到传递给 @racket[sync] 的 event 上。
在以下示例中，工作 thread 对三个 channel 进行同步，但每个 channel 必须以不同方式处理。
使用 @racket[handle-evt] 可以为给定 event 关联一个回调。
当 @racket[sync] 选择给定 event 时，它会调用回调来生成同步结果，
而不是使用 event 的正常同步结果。由于 event 在回调中处理，
因此不需要对 @racket[sync] 的返回值进行分派。

@racketblock[
(define add-channel (make-channel))
(define multiply-channel (make-channel))
(define append-channel (make-channel))

(define (work)
  (let loop ()
    (sync (handle-evt add-channel
                      (lambda (list-of-numbers)
                        (printf "Sum of ~a is ~a~n"
                                list-of-numbers
                                (apply + list-of-numbers))))
          (handle-evt multiply-channel
                      (lambda (list-of-numbers)
                        (printf "Product of ~a is ~a~n"
                                list-of-numbers
                                (apply * list-of-numbers))))
          (handle-evt append-channel
                      (lambda (list-of-strings)
                        (printf "Concatenation of ~s is ~s~n"
                                list-of-strings
                                (apply string-append list-of-strings)))))
    (loop)))

(define worker (thread work))
(channel-put add-channel '(1 2))
(channel-put multiply-channel '(3 4))
(channel-put multiply-channel '(5 6))
(channel-put add-channel '(7 8))
(channel-put append-channel '("a" "b"))
]

@racket[handle-evt] 的结果在 @racket[sync] 的尾部位置调用其回调，
因此可以安全地使用如以下示例中的递归。

@racketblock[
(define control-channel (make-channel))
(define add-channel (make-channel))
(define subtract-channel (make-channel))
(define (work state)
  (printf "Current state: ~a~n" state)
  (sync (handle-evt add-channel
                    (lambda (number)
                      (printf "Adding: ~a~n" number)
                      (work (+ state number))))
        (handle-evt subtract-channel
                    (lambda (number)
                      (printf "Subtracting: ~a~n" number)
                      (work (- state number))))
        (handle-evt control-channel
                    (lambda (kill-message)
                      (printf "Done~n")))))

(define worker (thread (lambda () (work 0))))
(channel-put add-channel 2)
(channel-put subtract-channel 3)
(channel-put add-channel 4)
(channel-put add-channel 5)
(channel-put subtract-channel 1)
(channel-put control-channel 'done)
(thread-wait worker)
]

@racket[wrap-evt] 函数类似于 @racket[handle-evt]，但其 handler 不在 @racket[sync] 的尾部位置被调用。
同时，@racket[wrap-evt] 在其 handler 调用期间禁用 break 异常。

@section{Building Your Own Synchronization Patterns}

Event 还允许你编码程序的多个并发部分之间的不同通信模式。
一种常见的模式是生产者-消费者模式。以下是使用上述思想实现其变体的一种方式。
一般来说，这些通信模式通过一个服务器循环来实现，该循环使用 @racket[sync]
等待任意数量的不同可能性发生，然后对其做出反应，更新一些本地状态。

@examples[
 #:eval concurrency-eval
 #:label #f
 (eval:no-prompt
  (define/contract (produce x)
    (-> any/c void?)
    (channel-put producer-chan x)))

 (eval:no-prompt
  (define/contract (consume)
    (-> any/c)
    (channel-get consumer-chan)))

 (code:comment "private state and server loop")
(eval:no-prompt
  (define producer-chan (make-channel))
  (define consumer-chan (make-channel))
  (void
   (thread
    (λ ()
      (code:comment "the items variable holds the items that")
      (code:comment "have been produced but not yet consumed")
      (let loop ([items '()])
        (sync

         (code:comment "wait for production")
         (handle-evt
          producer-chan
          (λ (i)
            (code:comment "if that event was chosen,")
            (code:comment "we add an item to our list")
            (code:comment "and go back around the loop")
            (loop (cons i items))))

         (code:comment "wait for consumption, but only")
         (code:comment "if we have something to produce")
         (handle-evt
          (if (null? items)
              never-evt
              (channel-put-evt consumer-chan (car items)))
          (λ (_)
            (code:comment "if that event was chosen,")
            (code:comment "we know that the first item item")
            (code:comment "has been consumed; drop it and")
            (code:comment "and go back around the loop")
            (loop (cdr items))))))))))

 (code:comment "an example (non-deterministic) interaction")
 (void
  (thread (λ () (sleep (/ (random 10) 100)) (produce 1)))
  (thread (λ () (sleep (/ (random 10) 100)) (produce 2))))
 (list (consume) (consume))
 ]

可以构建更复杂的同步模式。这是一个简单的示例，
我们在生产者-消费者的基础上扩展了一个等待至少生产了特定数量项的操作。

@examples[
 #:eval concurrency-eval
 #:label #f

 (eval:no-prompt
  (define/contract (produce x)
    (-> any/c void?)
    (channel-put producer-chan x))

  (define/contract (consume)
    (-> any/c)
    (channel-get consumer-chan))

  (define/contract (wait-at-least n)
    (-> natural? void?)
    (define c (make-channel))
    (code:comment "we send a new channel over to the")
    (code:comment "main loop so that we can wait here")
    (channel-put wait-at-least-chan (cons n c))
    (channel-get c)))

 (eval:no-prompt
  (define producer-chan (make-channel))
  (define consumer-chan (make-channel))
  (define wait-at-least-chan (make-channel))
  (void
   (thread
    (λ ()
      (let loop ([items '()]
                 [total-items-seen 0]
                 [waiters '()])
        (code:comment "instead of waiting on just production/")
        (code:comment "consumption now we wait to learn about")
        (code:comment "threads that want to wait for a certain")
        (code:comment "number of elements to be reached")
        (apply
         sync
         (handle-evt
          producer-chan
          (λ (i) (loop (cons i items)
                       (+ total-items-seen 1)
                       waiters)))
         (handle-evt
          (if (null? items)
              never-evt
              (channel-put-evt consumer-chan (car items)))
          (λ (_) (loop (cdr items) total-items-seen waiters)))

         (code:comment "wait for threads that are interested")
         (code:comment "the number of items produced")
         (handle-evt
          wait-at-least-chan
          (λ (waiter) (loop items total-items-seen (cons waiter waiters))))

         (code:comment "for each thread that wants to wait,")
         (for/list ([waiter (in-list waiters)])
           (code:comment "we check to see if there has been enough")
           (code:comment "production")
           (cond
             [(<= (car waiter) total-items-seen)
              (code:comment "if so, we send a message back on the channel")
              (code:comment "and continue the loop without that item")
              (handle-evt
               (channel-put-evt
                (cdr waiter)
                (void))
               (λ (_) (loop items total-items-seen (remove waiter waiters))))]
             [else
              (code:comment "otherwise, we just ignore that one")
              never-evt]))))))))

 (code:comment "an example (non-deterministic) interaction")
 (define thds
   (for/list ([i (in-range 10)])
     (thread (λ ()
               (produce i)
               (wait-at-least 10)
               (display (format "~a -> ~a\n" i (consume)))))))
 (for ([thd (in-list thds)])
   (thread-wait thd))
 ]
