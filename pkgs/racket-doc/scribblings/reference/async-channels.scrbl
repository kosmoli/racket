#lang scribble/doc
@(require "mz.rkt" (for-label racket/async-channel))

@(define async-eval
   (lambda ()
     (let ([the-eval (make-base-eval)])
       (the-eval '(require racket/async-channel))
       the-eval)))

@title[#:tag "async-channel"]{Buffered Asynchronous Channels}

@note-lib-only[racket/async-channel]

@section[#:tag "async-channels-s1"]{Creating and Using Asynchronous Channels}

@margin-note/ref{参见 @secref["threadmbox"]。}

@deftech{异步通道} 类似于 @tech{channel}，但它会缓冲值，
使得发送操作不必等待接收操作。

除了与异步通道特定的过程一起使用外，异步通道也可用作
@tech{synchronizable event}（参见 @secref["sync"]）。当 @racket[async-channel-get]
不会阻塞时，异步通道为 @tech{ready for synchronization}；异步通道的
@tech{synchronization result} 与 @racket[async-channel-get] 结果相同。

@defproc[(async-channel? [v any/c]) boolean?]{

如果 @racket[v] 是异步通道，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-async-channel [limit (or/c exact-positive-integer? #f) #f]) 
         async-channel?]{

返回缓冲限制为 @racket[limit] 个元素的异步通道。当通道为空时，get 操作阻塞；当通道中已有 @racket[limit] 个元素时，put 操作阻塞。如果 @racket[limit] 为 @racket[#f]，则通道缓冲无限制（因此 put 永远不会阻塞）。}


@defproc[(async-channel-get [ach async-channel?]) any/c]{

阻塞，直到 @racket[ach] 中至少有一个值可用，然后将放入 @racket[async-channel] 中的值中的第一个返回。}


@defproc[(async-channel-try-get [ach async-channel?]) any/c]{

如果 @racket[ach] 中立即至少有一个值可用，则返回放入 @racket[ach] 中的值中的第一个。如果 @racket[async-channel] 为空，则结果为 @racket[#f]。}


@defproc[(async-channel-put [ach async-channel?] [v any/c]) void?]{

将 @racket[v] 放入 @racket[ach] 中，如果 @racket[ach] 缓冲区已满，则阻塞直到空间可用。}


@defproc[(async-channel-put-evt [ach async-channel?] [v any/c]) 
         evt?]{

返回一个 @tech{synchronizable event}，当 @racket[(async-channel-put ach v)] 会返回一个值（即通道中已持有的值少于限制）时为 @tech{ready for synchronization}；@resultItself{asynchronous channel-put event}。}

@examples[#:eval (async-eval) #:once
(eval:no-prompt
 (define (server input-channel output-channel)
   (thread (lambda ()
             (define (get)
               (async-channel-get input-channel))
             (define (put x)
               (async-channel-put output-channel x))
             (define (do-large-computation)
               (sqrt 9))
             (let loop ([data (get)])
               (case data
                 [(quit) (void)]
                 [(add) (begin
                          (put (+ 1 (get)))
                          (loop (get)))]
                 [(long) (begin
                           (put (do-large-computation))
                           (loop (get)))])))))
  (define to-server (make-async-channel))
  (define from-server (make-async-channel)))

(server to-server from-server)

(async-channel? to-server)
(printf "Adding 1 to 4\n")
(async-channel-put to-server 'add)
(async-channel-put to-server 4)
(printf "Result is ~a\n" (async-channel-get from-server))
(printf "Ask server to do a long computation\n")
(async-channel-put to-server 'long)
(printf "I can do other stuff\n")
(printf "Ok, computation from server is ~a\n" 
        (async-channel-get from-server))
(async-channel-put to-server 'quit)
]

@section[#:tag "async-channels-s2"]{Contracts and Impersonators on Asynchronous Channels}

@defproc[(async-channel/c [c contract?]) contract?]{

返回一个识别异步通道的契约。放入通道或从通道检索的值必须与 @racket[c] 匹配。

如果 @racket[c] 参数是 flat contract 或 chaperone contract，则结果将是 chaperone contract。否则，结果将是 impersonator contract。

当 @racket[async-channel/c] 契约应用于异步通道时，结果与输入不是 @racket[eq?] 的。结果将取决于契约类型是输入的 @tech{chaperone} 还是 @tech{impersonator}。}

@defproc[(impersonate-async-channel [channel async-channel?]
                                    [get-proc (any/c . -> . any/c)]
                                    [put-proc (any/c . -> . any/c)]
                                    [prop impersonator-property?]
                                    [prop-val any] ...
                                    ...)
         (and/c async-channel? impersonator?)]{

返回 @racket[channel] 的 impersonator，它重定向
@racket[async-channel-get] 和 @racket[async-channel-put] 操作。

@racket[get-proc] 必须接受 @racket[async-channel-get] 在 @racket[channel] 上产生的值；必须产生替代值，作为 impersonator 上 get 操作的结果。

@racket[put-proc] 必须接受传递给在 @racket[channel] 上 @racket[async-channel-put] 的值；必须产生替代值，作为传递给原始通道 put 过程的值。

@racket[get-proc] 和 @racket[put-proc] 过程在从通道获取或放入值的所有操作中被调用，而不仅是在 @racket[async-channel-get] 和 @racket[async-channel-put] 中。

@racket[prop] 和 @racket[prop-val] 对的数量（@racket[impersonate-async-channel] 的参数数量必须为奇数）添加 @tech{impersonator properties} 或覆盖 @racket[channel] 的 @tech{impersonator property} 值。}

@defproc[(chaperone-async-channel [channel async-channel?]
                                  [get-proc (any/c . -> . any/c)]
                                  [put-proc (any/c . -> . any/c)]
                                  [prop impersonator-property?]
                                  [prop-val any] ...
                                  ...)
         (and/c async-channel? chaperone?)]{

类似于 @racket[impersonate-async-channel]，但 @racket[get-proc] 过程必须产生相同值或原始值的 chaperone，而 @racket[put-proc] 必须产生相同值或原始值的 chaperone。}
