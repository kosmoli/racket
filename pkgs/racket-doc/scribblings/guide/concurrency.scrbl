#lang scribble/doc
@(require scribble/manual
          scribble/examples
          "guide-utils.rkt"
          (for-label racket racket/async-channel))

@(define concurrency-eval (make-base-eval))
@(concurrency-eval '(require racket/contract racket/math))

@(define reference-doc '(lib "scribblings/reference/reference.scrbl"))

@title[#:tag "concurrency"]{并发与同步}

Racket 以 @deftech{threads} 的形式提供 @deftech{concurrency}，
同时提供通用的 @racket[sync] 函数，该函数可用于同步 thread 以及其他隐式的
并发形式，如 @tech{ports}。

Threads 在以下意义上并发运行：一个 thread 可以在没有另一个 thread 配合的情况下抢占它，
但默认情况下，threads 并不并行运行，也无法利用多个硬件处理器。
该默认的 thread 类型称为 @deftech{coroutine thread}。有关 Racket 中
并行的信息请参见 @secref["parallelism"]。

@section{Threads}

要并发地执行一个 procedure，可使用 @racket[thread]。
下面的示例从主 thread 创建两个新 thread：

@racketblock[
(displayln "This is the original thread")
(thread (lambda () (displayln "This is a new thread.")))
(thread (lambda () (displayln "This is another new thread.")))
]

下一个示例创建了一个会无限循环的新 thread，主 thread 使用 @racket[sleep]
使自己暂停 2.5 秒，然后使用 @racket[kill-thread] 终止工作 thread：

@racketblock[
(define worker (thread (lambda ()
                         (let loop ()
                           (displayln "Working...")
                           (sleep 0.2)
                           (loop)))))
(sleep 2.5)
(kill-thread worker)
]

@margin-note{In DrRacket, the main thread keeps going until the Stop button is
clicked, so in DrRacket the @racket[thread-wait] is not necessary.}

如果主 thread 结束或被杀死，应用程序会退出，即使其他 thread 仍在运行。
thread 可以使用 @racket[thread-wait] 等待另一个 thread 结束。这里，主 thread
使用 @racket[thread-wait] 确保工作 thread 在主 thread 退出之前完成：

@racketblock[
(define worker (thread
                 (lambda ()
                   (for ([i 100])
                     (printf "Working hard... ~a~n" i)))))
(thread-wait worker)
(displayln "Worker finished")
]

要从 thread 接收返回结果，请在创建 thread 时使用 @racket[#:keep 'results]，
然后 @racket[thread-wait] 可以返回 thread 的 procedure 所返回的值：

@racketblock[
(define worker (thread (lambda () (+ 1 2))
                       #:keep 'results))
(thread-wait worker)
]


@section{Thread Mailboxes}

每个 thread 都有一个用于接收消息的 mailbox。@racket[thread-send] 函数会
异步地将消息发送到另一个 thread 的 mailbox，而 @racket[thread-receive]
返回当前 thread 的 mailbox 中最旧的消息，如有必要会阻塞等待消息。
在下面的示例中，主 thread 将数据发送给工作 thread 进行处理，
然后在没有更多数据时发送 @racket['done] 消息并等待工作 thread 结束。

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

在下一个示例中，主 thread 将工作委托给多个算术 thread，然后等待接收结果。
算术 thread 处理工作项然后将结果发送给主 thread。

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

信号量便于对任意共享资源进行同步访问。当多个 thread 必须对单个资源执行非原子操作时使用信号量。

在下面的示例中，多个 thread 并发地向标准输出打印内容。
没有同步机制的情况下，一个 thread 打印的一行可能会出现在另一个 thread 打印的一行中间。
通过使用初始计数为 @racket[1] 的信号量，确保同一时间只有一个 thread 打印。
@racket[semaphore-wait] 函数会阻塞直到信号量的内部计数器非零，然后递减计数器并返回。
@racket[semaphore-post] 函数递增计数器以使另一个 thread 解除阻塞并打印。

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

等待信号量工作模式还可以用更简洁的方式表达：
使用 @racket[call-with-semaphore]，其优势在于即使控制流逃逸（例如因为异常）也能确保信号量被释放：

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

信号量是一种底层技术。通常更好的解决方案是将资源访问限制到单个 thread。
例如，让一个专用 thread 负责打印输出来同步对标准输出的访问可能是更好的方式。

@section{Channels}

Channels 在值从一个 thread 传递到另一个 thread 时对两个 thread 进行同步。
与 thread mailbox 不同，多个 thread 可以从同一个 channel 获取项目，因此当多个 thread
需要从单个工作队列消费项目时应使用 channels。

在下面的示例中，主 thread 使用 @racket[channel-put] 向 channel 添加项目，
多个工作线程则使用 @racket[channel-get] 消费这些项目。
对任一过程的调用都会阻塞，直到另一个 thread 用相同 channel 调用另一个过程。
worker 处理完项目后，再通过 @racket[result-channel] 将结果传给结果 thread。

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

Buffered 异步 channels 与上述 channels 类似，但异步 channels 的 'put' 操作不会阻塞 —— 除非给定的 channel 创建时指定了缓冲限制且已达上限。因此异步 put 操作类似于 @racket[thread-send]，但与 thread mailboxes 不同，异步 channels 允许单个 channel 被多个 thread 消费。

在下面的示例中，主 thread 向工作 channel 添加项目，该 channel 一次最多保存三个项目。
工作 thread 从该 channel 处理项目，然后将结果发送给打印 thread。

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

注意上面的示例缺少任何同步机制来验证所有项目是否都被处理。
如果主 thread 在没有这种同步的情况下退出，可能会出现工作 thread 未能处理完某些项目、
或打印 thread 未能打印所有项目的情况。

@section{Synchronizable Events 和 @racket[sync]}

还有其他同步 thread 的方式。@racket[sync] 函数允许 thread 通过 @tech[#:doc reference-doc]{synchronizable events}
进行协调。许多值同时充当事件，允许以统一的方式使用不同类型同步 thread。
事件的例子包括 channels、ports、threads 和 alarms。本节构建了一系列示例，
展示如何将 events、threads 和 @racket[sync]（以及递归函数）结合使用，
以实现任意复杂的通信协议，从而协调程序的各个并发部分。

在下一个示例中，channel 和 alarm 被用作 synchronizable events。
workers 对两者调用 @racket[sync]，以便它们可以处理 channel 中的项目直到 alarm 被激活。
channel 项目被处理后再将结果发送回主 thread。

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

下一个示例展示了一个可用于简单 TCP echo server 的函数。
该函数使用 @racket[sync/timeout] 同步来自给定 port 的输入或 thread mailbox 中的消息。
@racket[sync/timeout] 的第一个参数指定了应在给定事件上等待的最大秒数。
@racket[read-line-evt] 函数返回一个当给定输入 port 中有输入行可用时就绪的事件。
@racket[thread-receive-evt] 的结果在 @racket[thread-receive] 不会阻塞时就已就绪。
在实际应用中，thread 邮箱中接收到的消息可用于控制消息等用途。

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

@racket[serve] 函数用在下面的示例中，该示例启动了一个 server thread 和一个通过 TCP 通信的 client thread。
client 向 server 打印三行，server 将其回显回来。client 的 @racket[copy-port] 调用会阻塞直到收到 EOF。
server 在超时（2 秒后）关闭 ports，这使得 @racket[copy-port] 可以完成并且 client 退出。
主 thread 使用 @racket[thread-wait] 等待 client thread 退出（因为如果没有 @racket[thread-wait]，
主 thread 可能在其他 thread 尚未完成前就退出）。

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

有时你希望将结果行为直接附加到传递给 @racket[sync] 的事件上。
在下面的示例中，工作 thread 对三个 channels 进行同步，但每个 channel 必须以不同方式处理。
使用 @racket[handle-evt] 可将回调与给定事件关联。
当 @racket[sync] 选择给定事件时，它调用回调来生成同步结果，而不是使用事件正常的同步结果。
由于事件在回调中处理，因此无需对 @racket[sync] 返回值进行分发。

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

@racket[handle-evt] 的结果相对于 @racket[sync] 在尾位置调用其回调，
因此如下例所示使用递归是安全的。

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

@racket[wrap-evt] 函数类似于 @racket[handle-evt]，不同之处在于
其 handler 不会相对于 @racket[sync] 在尾位置被调用。
同时，@racket[wrap-evt] 在其 handler 调用期间禁用 break 异常。

@section{构建你自己的同步模式}

Events 还允许你在程序的多个并发部分之间编码许多不同的通信模式。
其中一个常见的模式是 producer-consumer。上面的思路提供了一种实现变体的方式。
总的来说，这些通信模式通过一个 server loop 实现，该 loop 使用 @racket[sync]
等待任意数量的不同可能性发生，然后对它们做出反应，更新某个本地状态。

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

可以构建更复杂的同步模式。这里有一个简单的示例，我们在 producer-consumer 基础上
增加了一个操作：等待直到至少产生了指定数量的项目。

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
