#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "breakhandler"]{Breaks}

@section-index["threads" "breaking"]

@deftech{break} 是一种异步异常，通常由用户控制的外部源触发，或通过 @racket[break-thread] 过程触发。
例如，用户可以在终端中输入 Ctl-C 来触发 break。在某些平台上，Racket process 可能接收 @as-index{@tt{SIGINT}}、
@as-index{@tt{SIGHUP}} 或 @as-index{@tt{SIGTERM}}；后两者对应于挂断和终止 break，分别反映在
@racket[exn:break:hang-up] 和 @racket[exn:break:terminate] 中。多个 break 可能合并为一个异常，
且多种类型的 break 可能合并为一个"最强"的 break，其中终止 break 强于挂断 break，
挂断 break 强于中断 break。

break 异常只能发生在启用了 break 的 thread 中。当检测到 break 且 break 已启用时，
@racket[exn:break]（或 @racket[exn:break:hang-up] 或 @racket[exn:break:terminate]）
异常会在该 thread 中的稍后时刻被引发；
如果当 break 被禁用时调用 @racket[break-thread]，则 break 被挂起，直到 thread 重新启用 break。
当 thread 有挂起的 break 时，额外的 break 将被忽略。

break 通过 @racket[break-enabled] parameter-like 过程以及 @racket[parameterize-break] 形式启用，
该形式类似于 @racket[parameterize]。@racket[break-enabled] 过程不是要通过 @racket[parameterize]
使用的 parameter，因为更改 thread 的 break 启用的状态需要对 break 进行显式检查，
且此检查与 @racket[parameterize] 表达式主体的尾部求值不兼容。

某些过程（如 @racket[semaphore-wait/enable-break]）在执行阻塞操作时临时启用 break。
如果 thread 启用了 break，且为该 thread 触发了 break 但尚未作为 @racket[exn:break] 异常传递，
则保证在 thread 中 break 可以被禁用之前传递此 break。@racket[exn:break] 异常的时间
不保证任何其他方式。

在调用 @racket[with-handlers] 谓词或处理器之前，或异常处理器、错误显示处理器、
错误转义处理器、错误值转换处理器之前，或 @racket[dynamic-wind] 的 @racket[pre-thunk]
或 @racket[post-thunk]，调用会通过 @racket[parameterize-break] 来禁用 break。此外，
在与异常相关的 handler 转换期间，在 @racket[dynamic-wind] 的 @racket[pre-thunk] 和
@racket[post-thunk] 之间的转换期间，以及在 continuation 跳跃的其他转换期间禁用 break。
例如，如果当 continuation 被调用时禁用了 break，且目标 continuation 也禁用了 break，
则从调用时刻起直到目标 continuation 执行前将保持禁用 break，除非相关
@racket[dynamic-wind] 的 @racket[pre-thunk] 或 @racket[post-thunk] 显式启用 break。

如果为阻塞在嵌套 thread 上的 thread 触发了 break
（参见 @racket[call-in-nested-thread]），且嵌套 thread 中启用了 break，
则 break 会通过将其转移到嵌套 thread 来隐式处理。

当 break 被启用时，它们可以发生在执行期间的任何时刻，这使得某些实现任务变得微妙。
例如，假设执行以下代码时启用了 break，

@racketblock[
(with-handlers ([exn:break? (lambda (x) (void))])
  (semaphore-wait s))
]

那么 @italic{并非} @|void-const| 结果专指信号量已被递减或接收到 break。
可能 @italic{两者} 都发生：break 可能发生在信号量成功递减之后但在返回
@|void-const| 结果之前。break 异常永远不会损害信号量或任何内建构造，
但许多内建过程（包括 @racket[semaphore-wait]）包含可被 break 中断的内部子表达式。

一般而言，仅使用 @racket[semaphore-wait] 无法实现以下保证：
要么信号量被递减，要么引发异常，两者不会同时发生。
因此 Racket 提供了 @racket[semaphore-wait/enable-break]（参见 @secref["semaphore"]），
它确实实现了这种排他性保证：

@racketblock[
(parameterize-break #f
  (with-handlers ([exn:break? (lambda (x) (void))])
    (semaphore-wait/enable-break s)))
]

在上述表达式中，break 可以发生在禁用 break 之前的任何时刻，
此时 break 异常会传播到外部异常处理器。否则，break 只能发生在
@racket[semaphore-wait/enable-break] 内部，它保证如果引发 break 异常，
信号量不会被递减。

为了允许在阻塞端口操作上类似的实现模式，
Racket 提供了 @racket[read-bytes-avail!/enable-break]、
@racket[write-bytes-avail/enable-break] 和其他过程。


@;------------------------------------------------------------------------

@defproc*[([(break-enabled) boolean?]
           [(break-enabled [on? any/c]) void?])]{

获取或设置当前 thread 的 break 启用状态。如果未提供 @racket[on?]，
且当前启用了 break，则结果为 @racket[#t]，否则为 @racket[#f]。
如果提供了 @racket[on?] 且为 @racket[#f]，则禁用 break；如果 @racket[on?] 为真值，则启用 break。}

@defform[(parameterize-break boolean-expr body ...+)]{对
@racket[boolean-expr] 求值以确定在顺序求值 @racket[body] 时 break 最初是否启用。
@racket[parameterize-break] 表达式的结果是最后一个 @racket[expr] 的结果。

与 @racket[parameterize] 类似，分配一个新的 @tech{thread cell} 来保存该 continuation 的
break 启用状态，在 continuation 内对 @racket[break-enabled] 的调用访问或修改新 cell。
与 parameter 不同，通过 @racket[break-enabled] 对 break 设置的修改不会
被新 thread 继承（即 thread cell 不是 @tech{preserved}）。}
 
@defproc[(current-break-parameterization) break-parameterization?]{
类似于 @racket[(current-parameterization)]（参见
@secref["parameters"]）；它返回一个 break parameterization
（实际上是一个 thread cell），保存当前 continuation 的
break 启用状态。}

@defproc[(call-with-break-parameterization 
                [break-param break-parameterization?]
                [thunk (-> any)]) 
               any]{
类似于 @racket[(call-with-parameterization parameterization
thunk)]（参见 @racket["parameters"]），在 break 启用状态位于
@racket[break-param] 中的 continuation 内调用 @racket[thunk]。
@racket[thunk] 的调用 @italic{不是} 相对于 @racket[call-with-break-parameterization]
调用的尾部位置。}

@defproc[(break-parameterization? [v any/c]) boolean?]{
如果 @racket[v] 是由 @racket[current-break-parameterization] 产生的
break parameterization，则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.1.1.8"]}
