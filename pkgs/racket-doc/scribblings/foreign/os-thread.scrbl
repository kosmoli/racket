#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/os-thread
                     ffi/unsafe/os-async-channel))

@title{操作系统线程}

@defmodule[ffi/unsafe/os-thread]{@racketmodname[ffi/unsafe/os-thread] 库
提供了用于在操作系统级单独线程中运行受限 Racket 代码的函数。除
@racket[os-thread-enabled?] 之外，@racketmodname[ffi/unsafe/os-thread]
的函数仅在满足以下条件时才受支持：当 @racket[(system-type 'vm)] 返回
@racket['chez-scheme]，甚至仅在特定的构建模式下。当不受支持时，
这些函数会引发 @racket[exn:fail:unsupported]。}

@history[#:added "6.90.0.9"]


@defproc[(os-thread-enabled?) boolean?]{

如果 @racketmodname[ffi/unsafe/os-thread] 中的其他函数在不引发
@racket[exn:fail:unsupported] 的情况下工作，则返回 @racket[#t]，
否则返回 @racket[#f]。}


@defproc[(call-in-os-thread [thunk (-> any)]) void?]{

在单独的操作系统的线程中运行 @racket[thunk]，该线程与所有 Racket 线程
并发运行。

@racket[thunk] 在 @tech{atomic mode} 中运行，并且不得检查其
continuation 或使用任何 Racket 线程函数（如 @racket[thread] 或
@racket[current-thread]）、任何 Racket 同步函数（如 @racket[semaphore-post] 或
@racket[sync]）或任何 parameters（如 @racket[current-output-port]）。
变量可以安全地通过 @racket[set!] 修改，并且 vectors、mutable pairs、boxes、
mutable structure fields 和基于 @racket[eq?]- 和 @racket[eqv?]-based hash tables
可以被修改，但修改对其他线程的可见性是未指定的，除非通过
@racket[os-semaphore-wait] 和 @racket[os-semaphore-post] 进行同步。}


@defproc[(make-os-semaphore) any]{

创建一个可以与 @racket[os-semaphore-wait] 和 @racket[os-semaphore-post]
一起使用以同步操作系统线程与 Racket 线程以及其他操作系统线程的 semaphore。}


@defproc[(os-semaphore-post [sema any/c]) void?]{

类似于 @racket[semaphore-post]，但作用于由 @racket[make-os-semaphore]
创建的 semaphore。}


@defproc[(os-semaphore-wait [sema any/c]) void?]{

类似于 @racket[semaphore-wait]，但在由 @racket[make-os-semaphore]
创建的 semaphore 上等待。等待会阻止当前线程；如果当前线程是一个 Racket 
@tech[#:doc reference.scrbl]{coroutine threads}，那么等待也会阻止同一
@tech[#:doc reference.scrbl]{place} 中的所有其他 coroutine 线程。从一个
@tech[#:doc reference.scrbl]{parallel thread} 等待，不一定会阻止其他 Racket 线程，
但它会消耗线程池的处理器资源，并且如果 coroutine 线程或其他线程
试图与阻塞的 parallel thread 同步，则可能会阻塞它们。}

@; ----------------------------------------

@section{操作系统异步通道}

@defmodule[ffi/unsafe/os-async-channel]{@racketmodname[ffi/unsafe/os-async-channel]
库提供了一个可与操作系统线程配合使用的异步通道，而正常的 Racket channels 或
place channels 是不允许的。这些通道通常与
@racketmodname[ffi/unsafe/os-thread] 组合使用。}

一个异步的操作系统的通道是一个 @tech[#:doc reference.scrbl]{synchronizable event}，
因此可以通过 @racket[sync] 在 Racket 线程中使用以接收值。其他线程必须使用
@racket[os-async-channel-try-get] 或 @racket[os-async-channel-get]。

当线程在由 @racket[make-os-async-channel] 产生的不可达的异步通道上阻塞时，
该线程对于垃圾收集是**不可用**的。这与线程在正常 Racket 通道或 place 通道上
阻塞时不同。

@history[#:added "8.0.0.4"]

@defproc[(make-os-async-channel) os-async-channel?]{

创建一个新的、空的用于操作系统线程的异步通道。}


@defproc[(os-async-channel? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[make-os-async-channel] 产生的异步通道，
则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(os-async-channel-put [ch os-async-channel?] [v any/c]) void?]{

将 @racket[v] 入队到异步通道 @racket[ch] 中。此函数可以从 Racket 线程
或任何操作系统线程中调用。}

@defproc[(os-async-channel-try-get [ch os-async-channel?] [default-v any/c #f]) any/c]{

从异步通道 @racket[ch] 中出队一个值并返回它，如果可用的话。如果通道中
没有立即可用的值，则返回 @racket[default-v]。此函数可以从 Racket 线程
或任何操作系统线程中调用。}

@defproc[(os-async-channel-get [ch os-async-channel?]) any/c]{

从异步通道 @racket[ch] 中出队一个值并返回它，阻塞直到值可用。此函数
可以从任何非 Racket 操作的系统的线程中调用。此函数**不应**从 Racket 线程中调用，
因为它会以一种阻止一个 place 中所有 Racket 线程的方式进行阻塞；
在 Racket 线程中应该使用 @racket[sync]。}
