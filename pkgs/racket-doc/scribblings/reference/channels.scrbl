#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "channel"]{Channels}

@deftech{通道} 既同步一对线程，又在线程之间传递一个值。通道是同步的：发送方和接收方都必须阻塞，直到（原子）事务完成。多个发送方和接收方可以同时访问一个通道，但每次事务中只选择一个发送方和一个接收方。

通道同步是 @defterm{公平的}：如果一个线程在某个通道上阻塞，而该通道的事务机会无限频繁地出现，则该线程最终会参与一次的事务。

除了与通道特定过程一起使用外，通道还可以用作 @tech{可同步事件}（见 @secref["sync"]）。当 @racket[channel-get] 不会被阻塞时，通道就 @tech{准备好进行同步}，通道的 @tech{同步结果}与 @racket[channel-get] 结果相同。

对于缓冲的异步通道，请参见 @secref["async-channel"]。

@defproc[(channel? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{通道}，则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(make-channel) channel?]{

创建并返回一个新的通道。该通道可用于 @racket[channel-get]、@racket[channel-try-get]，或用作 @tech{可同步事件}（见 @secref["sync"]）通过通道接收值。该通道也可用于 @racket[channel-put]，或用于 @racket[channel-put-evt] 的结果，通过通道发送值。}

@defproc[(channel-get [ch channel?]) any]{

阻塞直到某个准备就绪的发送方通过 @racket[ch] 提供一个值。结果即为所发送的值。}

@defproc[(channel-try-get [ch channel?]) any]{

如果有发送方立即可用，则接收并返回来自 @racket[ch] 的值，否则返回 @racket[#f]。}

@defproc[(channel-put [ch channel?] [v any/c]) void?]{

阻塞直到某个准备就绪的接收方通过 @racket[ch] 接受值 @racket[v]。}


@defproc[(channel-put-evt [ch channel?] [v any/c]) channel-put-evt?]{

返回一个用于 @racket[sync] 的新的 @tech{可同步事件}。当 @racket[(channel-put ch v)] 不会被阻塞时，该事件 @tech{准备好进行同步}，且其 @tech{同步结果}是事件本身。}


@defproc[(channel-put-evt? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[channel-put-evt] 产生的通道-put 事件，则返回 @racket[#t]，否则返回 @racket[#f]。}
