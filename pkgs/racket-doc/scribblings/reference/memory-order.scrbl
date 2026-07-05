#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/unsafe/ops))

@title[#:tag "memory-order"]{机器内存顺序}

@tech{Parallel thread}、@tech{futures} 和 @tech{places} 可以暴露底层机器的内存模型，包括弱内存顺序。
例如，当一个并行线程向一个可变 vector 的多个槽位写入时，在某些平台上可能出现另一个并行线程以不同的顺序观察到写入，或者根本观察不到，除非显式地同步线程。
类似地，共享的 byte string 或 @tech{fxvectors} 可能会跨 place 暴露机器的内存模型。

Racket 确保不会以不安全暴露原始 datatype 实现的方式来观察机器的内存模型。
例如，不能让一个线程通过读取被另一个线程修改的 vector 而看到一个部分构造的原始值。

@racket[box-cas!]、@racket[vector-cas!]、
@racket[unsafe-box*-cas!]、@racket[unsafe-vector*-cas!] 和
@racket[unsafe-struct*-cas!] 操作都提供机器级的 compare-and-set，
因此可以用于机器内存模型明确支持的特定方式。
@racket[(memory-order-acquire)] 和 @racket[(memory-order-release)]
操作同样约束机器级的 store 和 load。
同步操作如 semaphore、@racket[sync]、place 消息、future
@racket[touch] 和 @tech{future semaphore} 都隐含着适当的
机器级 acquire 和 release 顺序。

@deftogether[(
@defproc[(memory-order-acquire) void?]
@defproc[(memory-order-release) void?]
)]{

这些操作在需要同步来实现机器级内存屏障的平台上提供内存屏障。
@racket[memory-order-acquire] 操作确保至少有 load--load 和 load--store 屏障在机器级上，
@racket[memory-order-release] 操作确保至少有 store--store 和 store--load 屏障在机器级上。

@history[#:added "7.7.0.11"]}