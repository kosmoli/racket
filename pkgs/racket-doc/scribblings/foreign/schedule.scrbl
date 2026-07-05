#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/schedule))

@title{线程调度}

@defmodule[ffi/unsafe/schedule]{@racketmodname[ffi/unsafe/schedule]
库提供了与 thread scheduler 协作并对其进行操作的函数。该库的操作为
@tech[#:doc reference.scrbl]{unsafe}，因为 callback 在 @tech{atomic mode}
下运行，并且在 @elemref["unspecified thread"]{unspecified thread} 中运行。}

在 @elemtag["unspecified thread"]{unspecified thread} 中运行某个操作，
意味着 Racket scheduler 为 @tech[#:doc reference.scrbl]{coroutine threads}
选择一个方便的 coroutine thread，并将该 thread 的求值临时切换到该操作。
该 thread 本身并不处于 @tech{atomic mode}，但使用该 thread 的操作始终在
atomic mode 下运行。在 unspecified thread 中运行的操作可以使用
@racket[(current-thread)] 检查 parameter 值，并检查 continuation，但这样做
是 unsafe 的：当前 thread 及其 continuation 未被指定，误用 thread 或
continuation 可能泄漏信息或改变 thread 的行为。

@history[#:added "6.11.0.1"]

@defproc[(unsafe-poller [poll (evt? (or/c #f any/c) . -> . (values (or/c #f list?) evt?))])
         any/c]{

生成一个 @deftech{poller} 值，该值可以作为 @racket[prop:evt] 值使用，
即使它不是 procedure 或 @racket[evt?]。@racket[poll] callback 在
@tech{atomic mode} 下、在 @elemref["unspecified thread"]{unspecified thread} 中
被调用，以检查事件是否已就绪，或允许其注册一个 wakeup 触发器。

@racket[poll] 的第一个参数始终是用作 @tech[#:doc reference.scrbl]{synchronizable
event} 的对象，其中 @tech{poller} 作为其 @racket[prop:evt] 值。
称该值为 @racket[_evt]。

@racket[poll] 的第二个参数在调用 @racket[poll] 检查事件是否就绪时为
@racket[#f]。结果必须为两个值。第一个结果值是当 @racket[_evt] 就绪时的结果列表，
或当 @racket[_evt] 未就绪时为 @racket[#f]。第二个结果值是当 @racket[_evt]
就绪时为 @racket[#f]，或当 @racket[_evt] 未就绪时为替换 @racket[_evt]
的事件（通常就是 @racket[_evt] 本身）。

当 thread scheduler 确定 Racket process 应休眠直到外部事件或超时时，
则 @racket[poll] 以一个非 @racket[#f] 的第二个参数 @racket[_wakeups] 被调用。
在这种情况下，如果第一个结果值是列表，则休眠将被取消，但该列表不会被记录为结果
（而 @racket[poll] 很可能再次被调用）。除了返回一个 @racket[#f] 初始值外，
@racket[poll] 还可以对 @racket[_wakeups] 调用 @racket[unsafe-poll-ctx-fd-wakeup]、
@racket[unsafe-poll-ctx-eventmask-wakeup] 和/或
@racket[unsafe-poll-ctx-milliseconds-wakeup] 来注册 wakeup 触发器。}


@defproc[(unsafe-poll-fd [fd exact-integer?]
                         [mode '(read write)]
                         [socket? any/c #t])
         boolean?]{

检查给定的 file descriptor 或 socket 当前是否已准备好进行读或写，
由 @racket[mode] 选择。

@history[#:added "7.2.0.6"]}


@defproc[(unsafe-poll-ctx-fd-wakeup [wakeups any/c]
                                    [fd fixnum?]
                                    [mode '(read write error)])
         void?]{

注册一个 file descriptor（Unix 和 Mac OS）或 socket（所有平台），
使得当 file descriptor 或 socket 变为可读写或错误报告时（由 @racket[mode] 选择），
Racket process 将被唤醒并恢复 polling。@racket[wakeups] 参数
必须是由 scheduler 传递给 @racket[unsafe-poller] 包装过程的一个非 @racket[#f] 值。}


@defproc[(unsafe-poll-ctx-eventmask-wakeup [wakeups any/c]
                                           [mask fixnum?])
         void?]{

在 Windows 上，注册一个 eventmask，使得当 mask 选择的某事件可用时，
Racket  process 将被唤醒并恢复 polling。}


@defproc[(unsafe-poll-ctx-milliseconds-wakeup [wakeups any/c]
                                              [msecs flonum?])
         void?]{

使得 Racket process 在 @racket[(current-inexact-monotonic-milliseconds)]
开始返回大于等于 @racket[msecs] 的值时被唤醒并恢复 polling。

@history[#:changed "8.3.0.9" @elem{@racket[unsafe-poll-ctx-milliseconds-wakeup] 以前使用 @racket[current-inexact-milliseconds]。}]
                                   @racket[current-inexact-milliseconds]。}]}

@defproc[(unsafe-set-sleep-in-thread! [foreground-sleep (-> any/c)]
                                      [fd fixnum?])
         void?]{

注册 @racket[foreground-sleep] 作为当 thread scheduler 确定 process 将休眠时
实现 Racket process 休眠的过程。同时，在调用 @racket[foreground-sleep] 期间，
scheduler 的默认休眠函数将在单独的 OS 级 thread 中运行。当该默认休眠函数唤醒时，
一个 byte 将被写入 @racket[fd]，作为通知 @racket[foreground-sleep]
应立即返回的方式。

此函数在 Racket 实现支持 OS 级 thread 时可用。它在 Mac OS 上始终可用。}

@defproc[(unsafe-signal-received) void?]{

供 @racket[unsafe-set-sleep-in-thread!] 由 @racket[_foreground-sleep]
或其触发的某些功能使用，使得默认休眠函数请求 @racket[_foreground-sleep]
返回。}

@defproc[(unsafe-make-signal-received) (-> void?)]

返回一个类似于 @racket[unsafe-signal-received] 的函数，但它可以在任意
@tech[#:doc reference.scrbl]{place} 中调用，或在
@racketmodname[ffi/unsafe/os-thread] 支持的任意 OS thread 中调用，
以确保调用 @racket[unsafe-make-signal-received] 的
@tech[#:doc reference.scrbl]{place} 中由 thread scheduler 执行后续轮次的 polling。

@racket[unsafe-make-signal-received] 的返回值与 scheduler 之间的同步
将确保在调用 @racket[unsafe-make-signal-received] 生成的函数之前执行
@racket[(memory-order-release)] 的等价操作，并在 scheduler 调用 pollers 之前
执行 @racket[(memory-order-acquire)] 的等价操作。

@history[#:added "8.0.0.4"]}
