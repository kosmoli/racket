#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/engine))

@title[#:tag "engine"]{Engines}

@note-lib-only[racket/engine]

@deftech{Engine} 是一种抽象，用于建模可被 timer 或其它外部触发器抢占（preempted）的进程。它们受到 Haynes 和 Friedman @cite["Haynes84"] 工作的启发。

Engines 通过名为 @racket['racket/engine] 的 logger 记录其行为。该 logger 在模块实例化时创建，以 @racket[(current-logger)] 的结果为其父级。库在 @racket['debug] 级别记录以下消息：调用 @racket[engine-run] 时、engien 超时时以及 engine 被停止时（因为终止或已到达安全停止点）。每条日志消息承载以下 struct 的值：

@racketblock[(struct engine-info (msec name) #:prefab)]

其中，@racket[_msec] 是在记录时刻 @racket[(current-inexact-milliseconds)] 的返回值，而 @racket[_name] 是传给 @racket[engine] 的过程的名称。

@defproc[(engine [proc ((any/c . -> . void?) . -> . any/c)])
         engine?]{

返回一个 engine 对象，用于封装一个线程——该线程只在被允许时才执行。过程 @racket[proc] 应接受一个参数；当 @racket[engine-run] 被调用时，@racket[proc] 在 engine 线程中运行。如果 @racket[engine-run] 因超时返回，那么 engine 线程会被挂起，直到下次调用 @racket[engine-run]。因此 @racket[proc] 仅在 @racket[engine-run] 调用的动态范围（dynamic extent）内被执行。

传给 @racket[proc] 的参数是一个接受布尔值的过程，它可以用于禁用挂起（以防 @racket[proc] 有一些不应被挂起的关键区）。向该过程传入真值可启用挂起，@racket[#f] 则禁用挂起。初始状态下挂起是被允许的。}


@defproc[(engine? [v any/c]) any]{

如果 @racket[v] 是由 @racket[engine] 产生的 engine，返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(engine-run [until (or/c evt? real?)][engine engine?])
         boolean?]{

允许与 @racket[engine] 关联的线程最多执行直到 @racket[until] 毫秒（如果 @racket[until] 为实数），或直到 @racket[until] 就绪（如果 @racket[until] 为 event）。如果 @racket[engine] 的过程禁用了挂起，那么 engine 可以任意长地运行，直到它重新启用挂起。

如果 @racket[engine] 的过程完成（或早于之前完成），@racket[engine-run] 返回 @racket[#t]，其结果可通过 @racket[engine-result] 获取。如果 @racket[engine] 的过程尚未完成即被挂起，@racket[engine-run] 返回 @racket[#f]。如果 @racket[engine] 的过程引发异常，该异常会被 @racket[engine-run] 再次引发。}


@defproc[(engine-result [engine engine?]) any]{

如果 @racket[engine] 以一个值（而非异常）完成，则返回它的结果，否则返回 @racket[#f]。}


@defproc[(engine-kill [engine engine?]) void?]{

如果与 @racket[engine] 关联的线程仍在运行，则强制终止它，同时保持 engine 的结果不变。}
