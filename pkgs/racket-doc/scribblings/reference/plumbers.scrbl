#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "plumbers"]{Plumber}

@deftech{plumber} 支持 @deftech{flush callback}，通常在 Racket 进程或 @tech{place} 退出前被触发。例如，@tech{flush callback} 可能会刷新 output port 的缓冲区。@margin-note{@tech{Flush callback} 大致类似于标准 C 库中的 @as-index{@tt{atexit}}，但 flush callback 也可以在其它类似场景中使用。}

不能保证 flush callback 在进程终止前一定会被调用——可能是因为 plumber 不是被默认 @tech{exit handler} 刷新的那个原始 plumber，也可能是因为进程被强制终止（例如通过 custodian shutdown）。

@defproc[(plumber? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{plumber} 值则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.0.1.8"]}

@defproc[(make-plumber) plumber?]{

创建一个新的 @tech{plumber}。

Plumber 没有层次结构（不同于 @tech{custodian} 或 @tech{inspector}），但可以在一个 plumber 中注册 @tech{flush callback} 来调用另一个 plumber 的 @racket[plumber-flush-all]。

@history[#:added "6.0.1.8"]}

@defparam[current-plumber plumber plumber?]{

一个 @tech{parameter}，用于确定 @tech{flush callback} 的 @deftech{current plumber}。例如，创建 output @tech{file stream port} 时会向 @tech{current plumber} 注册一个 @tech{flush callback}，以便在 port 打开时刷新该 port。

@history[#:added "6.0.1.8"]}

@defproc[(plumber-flush-all [plumber plumber?]) void?]{

调用所有注册在 @racket[plumber] 上的 @tech{flush callback}。

要调用的 @tech{flush callback} 是在调用第一个 callback 之前从 @racket[plumber] 收集的。如果某个 @tech{flush callback} 注册了新的 @tech{flush callback}，新的那个将 @emph{不会} 被调用。如果某个 @tech{flush callback} 抛出异常或逃逸，则剩余的 @tech{flush callback} 不会被调用。

@history[#:added "6.0.1.8"]}

@defproc[(plumber-flush-handle? [v any/c]) boolean?]{

如果 @racket[v] 是表示 @tech{flush callback} 注册的 @deftech{flush handle} 则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.0.1.8"]}

@defproc[(plumber-add-flush! [plumber plumber?]
                             [proc (plumber-flush-handle? . -> . any)]
                             [weak? any/c #f])
         plumber-flush-handle?]{

将 @racket[proc] 注册为 @racket[plumber] 的 @tech{flush callback}，使得当 @racket[plumber-flush-all] 应用于 @racket[plumber] 时调用 @racket[proc]。

返回的 @tech{flush handle} 表示 callback 的注册，可与 @racket[plumber-flush-handle-remove!] 一起使用来取消注册 callback。

给定的 @racket[proc] 从 @tech{flush handle} 可达，但如果 @racket[weak?] 为真，则 @racket[plumber] 只保留对返回的 @tech{flush handle} 的 @tech{weak reference}（从而也只保留对 @racket[proc] 的弱引用）。

当 @racket[proc] 作为 @tech{flush callback} 被调用时，它会接收到与 @racket[plumber-add-flush!] 返回值的相同值，以便 @racket[proc] 可以方便地取消自身的注册。@racket[proc] 的调用处于 @tech{continuation barrier} 内。

@history[#:added "6.0.1.8"]}

@defproc[(plumber-flush-handle-remove! [handle plumber-flush-handle?]) void?]{

取消注册由 @racket[plumber-add-flush!] 调用产生的 @racket[handle] 对应的 @tech{flush callback}。

如果 @racket[handle] 所表示的注册已经被移除，则 @racket[plumber-flush-handle-remove!] 无效。

@history[#:added "6.0.1.8"]}
