#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "customport"]{Custom Ports}

@racket[make-input-port] 和 @racket[make-output-port] 过程创建具有任意控制过程的 @deftech{custom ports}（很像实现设备驱动程序）。自定义端口主要用于精细控制提交字节作为读取或写入的操作。

@defproc[(make-input-port [name any/c]
                          [read-in (or/c
                                    (bytes? 
                                     . -> . (or/c exact-nonnegative-integer?
                                                  eof-object?
                                                  procedure?
                                                  evt?))
                                    input-port?)]
                          [peek (or/c
                                 (bytes? exact-nonnegative-integer? (or/c evt? #f)
                                         . -> . (or/c exact-nonnegative-integer?
                                                      eof-object?
                                                      procedure?
                                                      evt?
                                                      #f))
                                 input-port?
                                 #f)]
                          [close (-> any)]
                          [get-progress-evt (or/c (-> evt?) #f) #f]
                          [commit (or/c (exact-positive-integer? evt? evt? . -> . any)
                                        #f) 
                                  #f]
                          [get-location (or/c 
                                         (->
                                          (values (or/c exact-positive-integer? #f)
                                                  (or/c exact-nonnegative-integer? #f)
                                                  (or/c exact-positive-integer? #f)))
                                         #f)
                                        #f]
                          [count-lines! (-> any) void]
                          [init-position (or/c exact-positive-integer?
                                               port?
                                               #f
                                               (-> (or/c exact-positive-integer? #f)))
                                         1]
                          [buffer-mode (or/c (case-> ((or/c 'block 'none) . -> . any)
                                                     (-> (or/c 'block 'none #f)))
                                             #f)
                                       #f])
         input-port?]{

创建一个输入端口，该端口立即可用于读取。如果 @racket[close] 过程没有副作用，则端口无需显式关闭。另请参见 @racket[make-input-port/read-to-peek]。

参数实现端口的方式如下：

@itemize[

  @item{@racket[name] —— 输入端口的名称。}

  @item{@racket[read-in] —— 要么是一个输入端口（此时读取被重定向到给定端口），要么是一个接受单个参数的过程：一个可变的 byte string 用于接收读取的字节。该过程的结果是以下之一：
    @itemize[

      @item{读取的字节数，为一个 exact、非负整数；}

      @item{@racket[eof]；}

      @item{a procedure of arity four (representing a ``special''
      结果，如下文 @elemref["special"]{进一步讨论} 所述），但过程结果仅在 @racket[peek] 不是 @racket[#f] 时才允许；}

      @item{一个 @techlink{pipe} 输入端口，只要 pipe 有内容就提供字节（参见 @racket[pipe-content-length]），或直到 @racket[read-in] 或 @racket[peek] 再次被调用；或}

      @item{一个 @tech{synchronizable event}（参见 @secref["sync"]），不是 pipe 输入端口或四元数过程；当读取完成时（大致上）事件变为就绪：事件的值可以是以上四种结果之一，或另一个像自身一样的事件；在最后一种情况下，读取过程用 @racket[sync] 循环直到获得非事件结果。}

    ]

    @racket[read-in] 过程不得无限期阻塞。如果没有立即可供读取的字节，@racket[read-in] 必须返回 @racket[0] 或一个事件，最好是事件（以避免忙等待）。当端口中有可用数据时，@racket[read-in] 不应返回 @racket[0]（或其值为 @racket[0] 的事件），否则轮询端口将表现不正确。事件产生的事件结果也可能破坏轮询。

    如果 @racket[read-in] 调用的结果不是上述值之一，则 @exnraise[exn:fail:contract]。如果返回的整数大于提供的 byte string 的长度，则 @exnraise[exn:fail:contract]。如果 @racket[peek] 是 @racket[#f] 且返回了 @elemref["special"]{special} 结果的过程，则 @exnraise[exn:fail:contract]。

    @racket[read-in] 过程可以通过引发异常来报告错误，但仅在未读取任何字节的情况下。类似地，如果返回了 @racket[eof]、事件或过程，则不应读取任何字节。换句话说，不应因虚假异常或非字节数据而丢失字节。

    端口的读取过程可能同时在多个线程中被调用（如果端口在多个线程中可访问），端口负责自己的内部同步。注意，此类同步机制的不正确实现可能导致非阻塞读取过程无限期阻塞。

    如果结果是 pipe 输入端口，则之前 @racket[get-progress-evt] 调用的事件尚未就绪的必须是 pipe 输入端口本身。此外，只要 pipe 包含数据，@racket[get-progress-evt] 必须继续返回该 pipe，或直到 @racket[read-in] 或 @racket[peek-in] 过程再次被调用（因任何原因而不使用 pipe 时）。如果调用了 @racket[read-in] 或 @racket[peek-in]，任何先前关联的 pipe（由之前的调用返回）将与端口解除关联，且不会因先前的关联而被任何其他线程使用。

    如果 @racket[peek]、@racket[get-progress-evt] 和 @racket[commit] 都提供了且非 @racket[#f]，则以下是 @racket[read-in] 的一个可接受实现：

@racketblock[
(code:line
   (lambda (bstr)
     (let* ([progress-evt (get-progress-evt)]
            [v (peek bstr 0 progress-evt)])
       (cond
        [(sync/timeout 0 progress-evt) 0] (code:comment #,(t "try again"))
        [(evt? v) (wrap-evt v (lambda (x) 0))] (code:comment #,(t "sync, try again"))
        [(and (number? v) (zero? v)) 0] (code:comment #,(t "try again"))
        [else
         (if (commit (if (number? v) v 1)
                         progress-evt
                         always-evt)
             v      (code:comment #,(t "got a result"))
             0)]))) (code:comment #,(t "try again"))
)]

    然而，实现者可以选择不实现 @racket[peek]、@racket[get-progress-evt] 和 @racket[commit] 过程，即使提供了这些过程的实现者也可以提供使用快速路径进行非阻塞读取的不同 @racket[read-in]。

    如果为 @racket[read-in] 提供了输入端口，则也必须为 @racket[peek] 提供输入端口。}


  @item{@racket[peek] —— 要么是 @racket[#f]，要么是输入端口（此时 peek 被重定向到给定端口），要么是接受三个参数的过程：

     @itemize[

     @item{一个可变的 byte string 用于接收 peek 的字节；}

     @item{peek 前要跳过的非负字节数（或 @elemref["special"]{specials}）；以及}

     @item{要么是 @racket[#f]，要么是由 @racket[get-progress-evt] 生成的 progress event。}

     ]

    @racket[peek] 的结果和约定与 @racket[read-in] 大致相同。主要区别在于 progress event 的处理（如果它不是 @racket[#f]）。如果给定的 progress event 变为就绪，@racket[peek] 必须中止任何跳过尝试且不 peek 任何值。特别是，如果 progress event 初始时就绪，@racket[peek] 不得 peek 任何值。如果端口已被关闭，progress event 应该就绪，此时 @racket[peek] 应该完成（而不是因为端口关闭而失败）。
    
    与 @racket[read-in] 不同，如果因为 progress event 变为就绪而没有 peek 到字节，@racket[peek] 应产生 @racket[#f]（或其值为 @racket[#f] 的事件）。与 @racket[read-in] 一样，@racket[0] 结果表示另一次尝试可能成功，因此当 progress event 就绪时 @racket[0] 是不合适的。也与 @racket[read-in] 一样，@racket[peek] 不得无限期阻塞。@racket[peek] 产生的事件由 @racket[byte-ready?] 或 @racket[peek-bytes-avail*!] 等选项轮询（在 @racket[poll-guard-evt] 的意义上）。

    提供给 @racket[peek] 的跳过计数是在报告 peek 结果时必须保留在端口中的字节数（或 @elemref["special"]{specials}）——除了 peek 结果之外。如果跳过计数请求读取超出 eof 的数据，则不应这样做，而应产生 @racket[eof]（直到 eof 被消费）。

    如果提供了 progress event，则当另一个过程在给定数量可以被跳过之前读取数据时，peek 实际上被取消。如果未提供 progress event 且数据被读取，则 peek 必须有效地以原始跳过计数重新开始。

    系统不检查多次 peek 是否返回一致的结果，或 peek 和读取是否产生一致的结果，尽管它们必须如此。

    如果 @racket[peek] 是 @racket[#f]，则端口的 peek 根据读取自动实现，但有几个限制。首先，自动实现不是线程安全的。其次，自动实现无法处理 @elemref["special"]{special} 结果（非字节和非 eof），因此当 @racket[peek] 是 @racket[#f] 时，@racket[read-in] 不能为 @elemref["special"]{special} 返回过程。最后，自动 peek 实现与 progress events 不兼容，因此如果 @racket[peek] 是 @racket[#f]，则 @racket[get-progress-evt] 和 @racket[commit] 必须是 @racket[#f]。另请参见 @racket[make-input-port/read-to-peek]，它根据 @racket[read-in] 实现 peeking 而没有这些约束。

    如果为 @racket[peek] 提供了输入端口，则也必须为 @racket[read-in] 提供输入端口。}

  @item{@racket[close] —— 一个零参数的过程，被调用以关闭端口。在关闭过程返回之前，端口不被视为已关闭。端口关闭后，其过程将永远不会再通过该端口被使用。然而，关闭过程可以同时在多个线程中被调用（如果端口在多个线程中可访问），并且它可能在另一个线程调用其他过程期间被调用；在后一种情况下，任何未完成的读取和 peek 应该以错误终止。}

  @item{@racket[get-progress-evt] —— 要么是 @racket[#f]（默认值），要么是接受零个参数并返回事件的过程。事件必须仅在下次从端口读取数据或端口关闭之后才变为就绪。如果端口已经关闭，事件必须就绪。事件变为就绪后，必须保持就绪。关于当 @racket[read-in] 返回 pipe 输入端口时此函数允许的结果，请参见 @racket[read-in] 的描述。另请参见 @racket[semaphore-peek-evt]，它有时对实现 @racket[get-progress-evt] 有用。

    如果 @racket[get-progress-evt] 是 @racket[#f]，则对端口应用 @racket[port-provides-progress-evts?] 将产生 @racket[#f]，并且端口将不是 @racket[port-progress-evt] 的有效参数。

    结果事件不会直接由 @racket[port-progress-evt] 暴露。相反，它将被包装在一个 @racket[progress-evt?] 返回 true 的事件中。}

  @item{@racket[commit] —— 要么是 @racket[#f]（默认值），要么是接受三个参数的过程： 

     @itemize[

     @item{一个 exact 的正整数 @math{k_r}；}

     @item{由 @racket[get-progress-evt] 生成的 progress event；}

     @item{一个事件 @racket[_done]，它是 channel-put 事件、channel、semaphore、semaphore-peek 事件、always 事件或 never 事件之一。}

     ]

     @defterm{commit} 对应于从流中移除先前 peek 的数据，但仅当没有其他过程先移除数据时。（被移除的数据不需要报告，因为它已经被 peek 了。）更准确地说，假设 @math{k_p} 字节、@elemref["special"]{specials} 和流中间的 @racket[eof] 先前已在端口流的开头被 peek 或跳过，@racket[commit] 必须满足以下约束：

     @itemize[

     @item{它必须仅在 commit 完成或给定 progress event 变为就绪时返回。}

     @item{它必须仅在 @math{k_p} 为正时 commit。}

     @item{如果它 commit，则必须 commit @math{k_r} 项或 @math{k_p} 项中较小的那个，且仅当 @math{k_p} 为正时。}

     @item{在给定 progress event 就绪后，或在 @racket[_done] 已被同步一次后，它不得在同步中选择 @racket[_done]。}

     @item{除非在同步中选择了 @racket[_done]，否则它不得将任何数据视为从端口读取。}

     @item{如果 @racket[_done] 就绪，它不得无限期阻塞；它必须在读取完成后或给定 progress event 就绪后尽快返回，以先到者为准。}

     @item{它可以通过引发异常来报告错误，但仅当没有数据被 commit 时。换句话说，不应因异常（包括 break 异常）而丢失数据。}

     @item{如果数据已被 commit，它必须返回 true 值，否则返回 @racket[#f]。当它返回一个值时，给定的 progress event 必须就绪（可能是因为数据刚刚被 commit）。}

     @item{当启用行计数且 @racket[get-location] 是 @racket[#f] 时（以便以默认方式实现行计数），它应返回一个 byte string 作为 true 结果；结果 byte string 表示为了字符和行计数目的而 commit 的数据。如果在期望 byte string 时返回了任何其他 true 结果，它被当作一个 byte string 处理，其中每个字节对应一个非换行字符。}

     @item{如果没有数据（包括 @racket[eof]）从端口流的开头被 peek，或者它必须无限期阻塞以等待给定 progress event 变为就绪，则它必须引发异常。}

     ]

    对 @racket[commit] 的调用被 @racket[parameterize-break] 以禁用 break。}

  @item{@racket[get-location] —— 要么是 @racket[#f]（默认值），要么是接受零个参数并返回三个值的过程：端口流中下一项的行号（正数或 @racket[#f]）、端口流中下一项的列号（非负数或 @racket[#f]）以及端口流中下一项的位置（正数或 @racket[#f]）。另请参见 @secref["linecol"]。  

    此过程被调用来实现 @racket[port-next-location]，但仅在通过 @racket[port-count-lines!] 为端口启用了行计数时才调用（此时 @racket[count-lines!] 被调用）。@racket[read] 和 @racket[read-syntax] 过程假设读取非空白字符会使列和位置增加一。}

  @item{@racket[count-lines!] —— 一个零参数的过程，在端口启用行计数时被调用。默认过程是 @racket[void]。}

  @item{@racket[init-position] —— 通常是一个 exact 的正整数，确定端口第一个项目的位置，由 @racket[file-position] 使用，或在端口未启用行计数时使用。默认值为 @racket[1]。如果 @racket[init-position] 是 @racket[#f]，则端口被视为具有未知位置。如果 @racket[init-position] 是一个端口，则始终使用给定端口的位置作为新端口的位置。如果 @racket[init-position] 是一个过程，则在需要时调用它以获取端口的位置。}

  @item{@racket[buffer-mode] —— 要么是 @racket[#f]（默认值），要么是接受零个或一个参数的过程。如果 @racket[buffer-mode] 是 @racket[#f]，则生成的端口不支持 buffer-mode 设置。否则，该过程以一个符号参数（@racket['block] 或 @racket['none]）调用以设置 buffer mode，并以零个参数调用以获取当前 buffer mode。在后一种情况下，结果必须是 @racket['block]、@racket['none] 或 @racket[#f]（未知）。关于 buffer modes 的更多信息，请参见 @secref["port-buffers"]。}

 ]

 @elemtag["special"]{@bold{``Special'' results:}} When
 @racket[read-in] or @racket[peek] (or an event produced by one of
 these) returns a procedure, the procedure is used to obtain a
 非字节结果。（此非字节结果 @italic{不是} 用于返回字符或 @racket[eof]；特别是，如果 @racket[read-char] 遇到特殊结果过程，即使该过程产生字节，它也会引发异常。）特殊结果过程必须接受四个表示源位置的参数。当特殊读取由 @racket[read] 或 @racket[read/recursive] 触发时，第一个参数为 @racket[#f]。

 特殊值过程可以返回任意值，它将被调用零次或一次（不一定在下一次从端口读取或 peek 之前）。关于该过程结果的更多细节，请参见 @secref["reader-procs"]。

 如果 @racket[read-in] 或 @racket[peek] 在被除 @racket[read]、@racket[read-syntax]、@racket[read-char-or-special]、@racket[peek-char-or-special]、@racket[read-byte-or-special] 或
 @racket[peek-byte-or-special] 之外的任何读取过程调用时返回特殊过程，则 @exnraise[exn:fail:contract]。}

@(begin
#reader scribble/comment-reader
[examples
;; A port with no input...
;; Easy: @racket[(open-input-bytes #"")]
;; Hard:
(define /dev/null-in 
  (make-input-port 'null
                   (lambda (s) eof)
                   (lambda (skip s progress-evt) eof)
                   void
                   (lambda () never-evt)
                   (lambda (k progress-evt done-evt)
                     (error "no successful peeks!"))))
(read-char /dev/null-in)
(peek-char /dev/null-in)
(read-byte-or-special /dev/null-in)
(peek-byte-or-special /dev/null-in 100)

;; A port that produces a stream of 1s:
(define infinite-ones 
  (make-input-port
   'ones
   (lambda (s) 
     (bytes-set! s 0 (char->integer #\1)) 1)
   #f
   void))
(read-string 5 infinite-ones)

;; But we can't peek ahead arbitrarily far, because the
;; automatic peek must record the skipped bytes, so
;; we'd run out of memory.

;; An infinite stream of 1s with a specific peek procedure:
(define infinite-ones 
  (let ([one! (lambda (s) 
                (bytes-set! s 0 (char->integer #\1)) 1)])
    (make-input-port
     'ones
     one!
     (lambda (s skip progress-evt) (one! s))
     void)))
(read-string 5 infinite-ones)

;; Now we can peek ahead arbitrarily far:
(peek-string 5 (expt 2 5000) infinite-ones)

;; The port doesn't supply procedures to implement progress events:
(port-provides-progress-evts? infinite-ones)
(eval:error (port-progress-evt infinite-ones))

;; Non-byte port results:
(define infinite-voids
  (make-input-port
   'voids
   (lambda (s) (lambda args 'void))
   (lambda (skip s evt) (lambda args 'void))
   void))
(eval:error (read-char infinite-voids))
(read-char-or-special infinite-voids)

;; This port produces 0, 1, 2, 0, 1, 2, etc., but it is not
;; thread-safe, because multiple threads might read and change @racket[n].
(define mod3-cycle/one-thread
  (let* ([n 2]
         [mod! (lambda (s delta)
                 (bytes-set! s 0 (+ 48 (modulo (+ n delta) 3)))
                 1)])
    (make-input-port
     'mod3-cycle/not-thread-safe
     (lambda (s) 
       (set! n (modulo (add1 n) 3))
       (mod! s 0))
     (lambda (s skip evt) 
       (mod! s skip))
     void)))
(read-string 5 mod3-cycle/one-thread)
(peek-string 5 (expt 2 5000) mod3-cycle/one-thread)

;; Same thing, but thread-safe and kill-safe, and with progress
;; events. Only the server thread touches the stateful part
;; directly. (See the output port examples for a simpler thread-safe
;; example, but this one is more general.)
(define (make-mod3-cycle)
  (define read-req-ch (make-channel))
  (define peek-req-ch (make-channel))
  (define progress-req-ch (make-channel))
  (define commit-req-ch (make-channel))
  (define close-req-ch (make-channel))
  (define closed? #f)
  (define n 0)
  (define progress-sema #f)
  (define (mod! s delta)
    (bytes-set! s 0 (+ 48 (modulo (+ n delta) 3)))
    1)
  ;; ----------------------------------------
  ;; The server has a list of outstanding commit requests,
  ;;  and it also must service each port operation (read, 
  ;;  progress-evt, etc.)
  (define (serve commit-reqs response-evts)
    (apply
     sync
     (handle-evt read-req-ch
                 (handle-read commit-reqs response-evts))
     (handle-evt progress-req-ch
                 (handle-progress commit-reqs response-evts))
     (handle-evt commit-req-ch
                 (add-commit commit-reqs response-evts))
     (handle-evt close-req-ch
                 (handle-close commit-reqs response-evts))
     (append
      (map (make-handle-response commit-reqs response-evts)
           response-evts)
      (map (make-handle-commit commit-reqs response-evts)
           commit-reqs))))
  ;; Read/peek request: fill in the string and commit
  (define ((handle-read commit-reqs response-evts) r)
    (let ([s (car r)]
          [skip (cadr r)]
          [ch (caddr r)]
          [nack (cadddr r)]
          [evt (car (cddddr r))]
          [peek? (cdr (cddddr r))])
      (let ([fail? (and evt
                        (sync/timeout 0 evt))])
        (unless (or closed? fail?)
          (mod! s skip)
          (unless peek?
            (commit! 1)))
        ;; Add an event to respond:
        (serve commit-reqs
               (cons (choice-evt 
                      nack
                      (channel-put-evt ch (if closed? 
                                              0 
                                              (if fail? #f 1))))
                     response-evts)))))
  ;; Progress request: send a peek evt for the current 
  ;;  progress-sema
  (define ((handle-progress commit-reqs response-evts) r)
    (let ([ch (car r)]
          [nack (cdr r)])
      (unless progress-sema
        (set! progress-sema (make-semaphore (if closed? 1 0))))
      ;; Add an event to respond:
      (serve commit-reqs
             (cons (choice-evt 
                    nack
                    (channel-put-evt
                     ch
                     (semaphore-peek-evt progress-sema)))
                   response-evts))))
  ;; Commit request: add the request to the list
  (define ((add-commit commit-reqs response-evts) r)
    (serve (cons r commit-reqs) response-evts))
  ;; Commit handling: watch out for progress, in which case
  ;;  the response is a commit failure; otherwise, try
  ;;  to sync for a commit. In either event, remove the
  ;;  request from the list
  (define ((make-handle-commit commit-reqs response-evts) r)
    (let ([k (car r)]
          [progress-evt (cadr r)]
          [done-evt (caddr r)]
          [ch (cadddr r)]
          [nack (cddddr r)])
      ;; Note: we don't check that k is @racket[<=] the sum of
      ;;  previous peeks, because the entire stream is actually
      ;;  known, but we could send an exception in that case.
      (choice-evt
       (handle-evt progress-evt
                   (lambda (x) 
                     (sync nack (channel-put-evt ch #f))
                     (serve (remq r commit-reqs) response-evts)))
       ;; Only create an event to satisfy done-evt if progress-evt
       ;;  isn't already ready.
       ;; Afterward, if progress-evt becomes ready, then this
       ;;  event-making function will be called again, because
       ;;  the server controls all posts to progress-evt.
       (if (sync/timeout 0 progress-evt)
           never-evt
           (handle-evt done-evt
                       (lambda (v)
                         (commit! k)
                         (sync nack (channel-put-evt ch #t))
                         (serve (remq r commit-reqs)
                                response-evts)))))))
  ;; Response handling: as soon as the respondee listens,
  ;;  remove the response
  (define ((make-handle-response commit-reqs response-evts) evt)
    (handle-evt evt
                (lambda (x)
                  (serve commit-reqs
                         (remq evt response-evts)))))
  ;; Close handling: post the progress sema, if any, and set
  ;;   the @racket[closed?] flag
  (define ((handle-close commit-reqs response-evts) r)
    (let ([ch (car r)]
          [nack (cdr r)])
      (set! closed? #t)
      (when progress-sema
        (semaphore-post progress-sema))
      (serve commit-reqs
             (cons (choice-evt nack
                               (channel-put-evt ch (void)))
                   response-evts))))
  ;; Helper for reads and post-peek commits:
  (define (commit! k)
    (when progress-sema
      (semaphore-post progress-sema)
      (set! progress-sema #f))
    (set! n (+ n k)))
  ;; Start the server thread:
  (define server-thread (thread (lambda () (serve null null))))
  ;; ----------------------------------------
  ;; Client-side helpers:
  (define (req-evt f)
    (nack-guard-evt
     (lambda (nack)
       ;; Be sure that the server thread is running:
       (thread-resume server-thread (current-thread))
       ;; Create a channel to hold the reply:
       (let ([ch (make-channel)])
         (f ch nack)
         ch))))
  (define (read-or-peek-evt s skip evt peek?)
    (req-evt (lambda (ch nack)
               (channel-put read-req-ch
                            (list* s skip ch nack evt peek?)))))
  ;; Make the port:
  (make-input-port 'mod3-cycle
                   ;; Each handler for the port just sends
                   ;;  a request to the server
                   (lambda (s) (read-or-peek-evt s 0 #f #f))
                   (lambda (s skip evt) 
                     (read-or-peek-evt s skip evt #t))
                   (lambda () ; close
                     (sync (req-evt
                            (lambda (ch nack)
                              (channel-put progress-req-ch
                                           (list* ch nack))))))
                   (lambda () ; progress-evt
                     (sync (req-evt
                            (lambda (ch nack)
                              (channel-put progress-req-ch
                                           (list* ch nack))))))
                   (lambda (k progress-evt done-evt)  ; commit
                     (sync (req-evt
                            (lambda (ch nack)
                              (channel-put 
                               commit-req-ch
                               (list* k progress-evt done-evt ch 
                                      nack))))))))

(define mod3-cycle (make-mod3-cycle))
(let ([result1 #f]
      [result2 #f])
  (let ([t1 (thread 
             (lambda ()
               (set! result1 (read-string 5 mod3-cycle))))]
        [t2 (thread
             (lambda ()
               (set! result2 (read-string 5 mod3-cycle))))])
    (thread-wait t1)
    (thread-wait t2)
    (string-append result1 "," result2)))

(define s (make-bytes 1))
(define progress-evt (port-progress-evt mod3-cycle))
(peek-bytes-avail! s 0 progress-evt mod3-cycle)
s
(port-commit-peeked 1 progress-evt (make-semaphore 1)
                    mod3-cycle)
(sync/timeout 0 progress-evt)
(peek-bytes-avail! s 0 progress-evt mod3-cycle)
(port-commit-peeked 1 progress-evt (make-semaphore 1) 
                    mod3-cycle)
(close-input-port mod3-cycle)
])

@;------------------------------------------------------------------------
@;------------------------------------------------------------------------

@defproc[(make-output-port [name any/c]
                           [evt evt?]
                           [write-out (or/c
                                       (bytes? exact-nonnegative-integer?
                                               exact-nonnegative-integer?
                                               boolean?
                                               boolean?
                                               . -> .
                                               (or/c exact-nonnegative-integer?
                                                     #f
                                                     evt?))
                                       output-port?)]
                           [close (-> any)]
                           [write-out-special (or/c (any/c boolean? boolean?
                                                           . -> .
                                                           (or/c any/c
                                                                 #f
                                                                 evt?))
                                                    output-port?
                                                    #f)
                                              #f]
                           [get-write-evt (or/c
                                           (bytes? exact-nonnegative-integer?
                                                   exact-nonnegative-integer?
                                                   . -> .
                                                   evt?)
                                           #f)
                                          #f]
                           [get-write-special-evt (or/c 
                                                   (any/c . -> . evt?)
                                                   #f)
                                                  #f]
                           [get-location (or/c 
                                          (->
                                           (values (or/c exact-positive-integer? #f)
                                                   (or/c exact-nonnegative-integer? #f)
                                                   (or/c exact-positive-integer? #f)))
                                          #f)
                                         #f]
                           [count-lines! (-> any) void]
                           [init-position (or/c exact-positive-integer?
                                                port?
                                                #f
                                                (-> (or/c exact-positive-integer? #f)))
                                          1]
                           [buffer-mode (or/c (case-> 
                                               ((or/c 'block 'line 'none) . -> . any)
                                               (-> (or/c 'block 'line 'none #f)))
                                              #f)
                                        #f])
          output-port?]{

创建一个输出端口，该端口立即可用于写入。如果 @racket[close] 过程没有副作用，则端口无需显式关闭。端口可以在其 @racket[write-out] 和 @racket[write-out-special] 过程中缓冲数据。

 @itemize[

   @item{@racket[name] --- the name for the output port.}

   @item{@racket[evt] —— 一个同步事件（参见 @secref["sync"]；例如，semaphore 或另一个端口）。当端口被提供给像 @racket[sync] 这样的同步过程时，此事件代替输出端口使用。因此，当端口已准备好无阻塞地写入至少一个字节，或准备好无阻塞地在刷新内部缓冲区方面取得进展时，事件应该解除阻塞。除非端口已准备好写入，否则事件不得解除阻塞；否则，@racket[sync] 的保证将对输出端口被破坏。如果对端口的写入总是无阻塞地成功，请使用 @racket[always-evt]。}

   @item{@racket[write-out] —— 要么是一个输出端口（表示写入应被重定向到给定端口），要么是一个五个参数的过程：

     @itemize[

     @item{一个包含要写入字节的不可变 byte string；}

     @item{byte string 中的起始偏移量（包含）的非负 exact 整数；}

     @item{byte string 中的结束偏移量（不包含）的非负 exact 整数；}

     @item{一个 boolean；@racket[#f] 表示允许端口将写入的字节保留在缓冲区中，并且允许无限期阻塞；@racket[#t] 表示写入不应该阻塞，且端口应尝试刷新其缓冲区并完全写入新字节，而不是缓冲它们；}

     @item{一个 boolean；@racket[#t] 表示如果端口因写入而阻塞，则应在阻塞时启用 break（例如使用 @racket[sync/enable-break]）；如果第四个参数是 @racket[#t]，则此参数始终为 @racket[#f]。}

     ]

    该过程返回以下之一：

     @itemize[

     @item{表示已写入或缓冲的字节数的非负 exact 整数；}

     @item{如果没有字节可以写入（可能是因为内部缓冲区无法完全刷新），则为 @racket[#f]；}

     @item{一个 @techlink{pipe} 输出端口（当允许缓冲时，而不是在刷新时），用于缓冲字节，只要 pipe 未满且直到 @racket[write-out] 或 @racket[write-out-special] 被调用；或}

     @item{一个同步事件（参见 @secref["sync"]），不是 pipe 输出端口，其行为类似于 @racket[write-bytes-avail-evt] 的结果以完成写入。}

     ]

    由于 @racket[write-out] 可以产生事件，@racket[write-out] 的一个可接受实现是将其前三个参数传递给端口的 @racket[get-write-evt]。然而，一些端口实现者可能选择不提供 @racket[get-write-evt]（可能是因为写入不能做成原子的），或可能实现 @racket[write-out] 以启用非阻塞写入的快速路径或启用缓冲。

    从用户的角度来看，缓冲数据与完全写入数据之间的区别是：(1) 缓冲数据可能在将来因写入失败而丢失，(2) @racket[flush-output] 强制所有缓冲数据被完全写入。在任何情况下都不需要缓冲。
    
    如果起始和结束索引相同，则 @racket[write-out] 的第四个参数将是 @racket[#f]，写入请求实际上是端口缓冲区的刷新请求（如果有的话），成功刷新（或如果没有缓冲区）的结果应为 @racket[0]。

    如果起始和结束索引不同，结果永远不应是 @racket[0]，否则 @exnraise[exn:fail:contract]。类似地，如果 @racket[write-out] 在禁止缓冲或为刷新而调用时返回 pipe 输出端口，则 @exnraise[exn:fail:contract]。如果返回的整数大于提供的 byte-string 范围，则 @exnraise[exn:fail:contract]。

    应避免 @racket[#f] 结果，除非下一次写入尝试可能成功。否则，如果数据无法写入，改为返回事件。

    @racket[write-out] 返回的事件可以返回 @racket[#f] 或另一个像自身一样的事件，与 @racket[write-bytes-avail-evt] 或 @racket[get-write-evt] 产生的事件形成对比。写入过程用 @racket[sync] 循环直到获得非事件结果。

    @racket[write-out] 过程总是在禁用 break 的情况下被调用，无论端口的客户端请求写入时是否启用了 break。如果阻塞操作启用了 break，则 @racket[write-out] 的第五个参数将是 @racket[#t]，这表示 @racket[write-out] 应在阻塞时重新启用 break。

    如果写入过程因写入或 commit 操作而引发异常，它不得 commit 任何字节（尽管它可能已 commit 先前缓冲的字节）。

    端口的写入过程可能同时在多个线程中被调用（如果端口在多个线程中可访问）。端口负责自己的内部同步。注意，此类同步机制的不正确实现可能导致非阻塞写入过程阻塞。}

  @item{@racket[close] —— 一个零参数的过程，被调用以关闭端口。在关闭过程返回之前，端口不被视为已关闭。端口关闭后，其过程将永远不会再通过该端口被使用。然而，关闭过程可以同时在多个线程中被调用（如果端口在多个线程中可访问），并且它可能在另一个线程调用其他过程期间被调用；在后一种情况下，任何未完成的写入或刷新应立即以错误终止。}

  @item{@racket[write-out-special] —— 要么是 @racket[#f]（默认值），要么是输出端口（表示特殊写入应被重定向到给定端口），要么是处理端口 @racket[write-special] 调用的过程。如果是 @racket[#f]，则端口不支持特殊输出，对端口应用 @racket[port-writes-special?] 将返回 @racket[#f]。

    如果提供了过程，它接受三个参数：要写入的特殊值；一个 boolean，如果过程可以缓冲特殊值并无期限阻塞则为 @racket[#f]；一个 boolean，如果过程应在阻塞时启用 break 则为 @racket[#t]。结果是以下之一：

     @itemize[

     @item{一个非事件的 true 值，表示特殊值已写入；}

     @item{如果特殊值无法写入（可能是因为内部缓冲区无法完全刷新），则为 @racket[#f]；}

     @item{一个同步事件（参见 @secref["sync"]），其行为类似于 @racket[get-write-special-evt] 的结果以完成写入。}

     ]

    由于 @racket[write-out-special] 可以返回事件，将第一个参数传递给 @racket[get-write-special-evt] 的实现作为 @racket[write-out-special] 是可接受的。

    与 @racket[write-out] 一样，@racket[#f] 结果是不鼓励的，因为它可能导致忙等待。也与 @racket[write-out] 一样，@racket[write-out-special] 产生的事件允许产生 @racket[#f] 或另一个像自身一样的事件。@racket[write-out-special] 过程总是在禁用 break 的情况下被调用，无论端口的客户端请求写入时是否启用了 break。}

   @item{@racket[get-write-evt] —— 要么是 @racket[#f]（默认值），要么是一个三个参数的过程：

     @itemize[

     @item{一个包含要写入字节的不可变 byte string；}

     @item{byte string 中的起始偏移量（包含）的非负 exact 整数；以及}

     @item{byte string 中的结束偏移量（不包含）的非负 exact 整数。}

     ]

    结果是一个同步事件（参见 @secref["sync"]），作为端口的 @racket[write-bytes-avail-evt] 的结果（即完成写入或刷新），仅在数据被 commit 到端口的底层设备时才变为可用，其结果值是写入的字节数。

    如果 @racket[get-write-evt] 是 @racket[#f]，则对端口应用 @racket[port-writes-atomic?] 将产生 @racket[#f]，并且端口将不是 @racket[write-bytes-avail-evt] 等过程的有效参数。否则，@racket[get-write-evt] 返回的事件不得导致数据写入端口，除非事件在同步中被选择，并且如果事件被选择，它必须写入端口（即写入必须在同步方面看起来是原子的）。

    如果事件的结果整数大于提供的 byte-string 范围，则通过事件上的包装器 @exnraise[exn:fail:contract]。如果起始和结束索引相同（即没有字节要写入），则当缓冲区完全刷新时事件应产生 @racket[0]。（如果端口没有缓冲区，则它实际上始终是已刷新的。）

    如果事件因写入或 commit 操作而引发异常，它不得 commit 任何新字节（尽管它可能已 commit 先前缓冲的字节）。

    自然地，端口的事件可能同时在多个线程中使用（如果端口在多个线程中可访问）。端口负责自己的内部同步。}

  @item{@racket[get-write-special-evt] —— 要么是 @racket[#f]（默认值），要么是处理端口 @racket[write-special-evt] 调用的过程。如果 @racket[write-out-special] 或 @racket[get-write-evt] 是 @racket[#f]，则此参数必须为 @racket[#f]；如果这两个参数都是过程，则此参数必须是一个过程。

    如果它是一个过程，它接受一个参数：要写入的特殊值。结果事件（及其约束）类似于 @racket[get-write-evt] 的结果。

    如果事件因写入或 commit 操作而引发异常，它不得 commit 特殊值（尽管它可能已 commit 先前缓冲的字节和值）。}



  @item{@racket[get-location] —— 要么是 @racket[#f]（默认值），要么是接受零个参数并返回三个值的过程：写入端口流中下一项的行号（正数或 @racket[#f]）、写入端口流中下一项的列号（非负数或 @racket[#f]）以及写入端口流中下一项的位置（正数或 @racket[#f]）。另请参见 @secref["linecol"]。

    此过程被调用来为端口实现 @racket[port-next-location]，但仅在通过 @racket[port-count-lines!] 为端口启用了行计数时才调用（此时 @racket[count-lines!] 被调用）。}

  @item{@racket[count-lines!] —— 一个零参数的过程，在端口启用行计数时被调用。默认过程是 @racket[void]。}

  @item{@racket[init-position] —— 通常是一个 exact 的正整数，确定端口第一个项目的位置，由 @racket[file-position] 使用，或在端口未启用行计数时使用。默认值为 @racket[1]。如果 @racket[init-position] 是 @racket[#f]，则端口被视为具有未知位置。如果 @racket[init-position] 是一个端口，则始终使用给定端口的位置作为新端口的位置。如果 @racket[init-position] 是一个过程，则在需要时调用它以获取端口的位置。}

  @item{@racket[buffer-mode] —— 要么是 @racket[#f]（默认值），要么是接受零个或一个参数的过程。如果 @racket[buffer-mode] 是 @racket[#f]，则生成的端口不支持 buffer-mode 设置。否则，该过程以一个符号参数（@racket['block]、@racket['line] 或 @racket['none]）调用以设置 buffer mode，并以零个参数调用以获取当前 buffer mode。在后一种情况下，结果必须是 @racket['block]、@racket['line]、@racket['none] 或 @racket[#f]（未知）。关于 buffer modes 的更多信息，请参见 @secref["port-buffers"]。}

 ]
}

@(begin
#reader scribble/comment-reader
[examples
;; A port that writes anything to nowhere:
(define /dev/null-out
  (make-output-port 
   'null
   always-evt
   (lambda (s start end non-block? breakable?) (- end start))
   void
   (lambda (special non-block? breakable?) #t)
   (lambda (s start end) (wrap-evt
                          always-evt
                          (lambda (x)
                            (- end start))))
   (lambda (special) always-evt)))
(display "hello" /dev/null-out)
(write-bytes-avail #"hello" /dev/null-out)
(write-special 'hello /dev/null-out)
(sync (write-bytes-avail-evt #"hello" /dev/null-out))

;; A port that accumulates bytes as characters in a list,
;;  but not in a thread-safe way:
(define accum-list null)
(define accumulator/not-thread-safe
  (make-output-port 
   'accum/not-thread-safe
   always-evt
   (lambda (s start end non-block? breakable?)
     (set! accum-list
           (append accum-list
                   (map integer->char
                        (bytes->list (subbytes s start end)))))
     (- end start))
   void))
(display "hello" accumulator/not-thread-safe)
accum-list

;; Same as before, but with simple thread-safety:
(define accum-list null)
(define accumulator 
  (let* ([lock (make-semaphore 1)]
         [lock-peek-evt (semaphore-peek-evt lock)])
    (make-output-port
     'accum
     lock-peek-evt
     (lambda (s start end non-block? breakable?)
       (if (semaphore-try-wait? lock)
           (begin
             (set! accum-list
                   (append accum-list
                           (map integer->char
                                (bytes->list
                                 (subbytes s start end)))))
             (semaphore-post lock)
             (- end start))
           ;; Cheap strategy: block until the list is unlocked,
           ;;   then return 0, so we get called again
           (wrap-evt
            lock-peek-evt
            (lambda (x) 0))))
     void)))
(display "hello" accumulator)
accum-list

;; A port that transforms data before sending it on
;;  to another port. Atomic writes exploit the
;;  underlying port's ability for atomic writes.
(define (make-latin-1-capitalize port)
  (define (byte-upcase s start end)
    (list->bytes
     (map (lambda (b) (char->integer
                       (char-upcase
                        (integer->char b))))
          (bytes->list (subbytes s start end)))))
  (make-output-port
   'byte-upcase
   ;; This port is ready when the original is ready:
   port
   ;; Writing procedure:
   (lambda (s start end non-block? breakable?)
     (let ([s (byte-upcase s start end)])
       (if non-block?
           (write-bytes-avail* s port)
           (begin
             (display s port)
             (bytes-length s)))))
   ;; Close procedure --- close original port:
   (lambda () (close-output-port port))
   #f
   ;; Write event:
   (and (port-writes-atomic? port)
        (lambda (s start end)
          (write-bytes-avail-evt
           (byte-upcase s start end) 
           port)))))
(define orig-port (open-output-string))
(define cap-port (make-latin-1-capitalize orig-port))
(display "Hello" cap-port)
(get-output-string orig-port)
(sync (write-bytes-avail-evt #"Bye" cap-port))
(get-output-string orig-port)
])
