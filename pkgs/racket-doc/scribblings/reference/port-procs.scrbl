#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "port-ops"]{Managing Ports}

@defproc[(input-port? [v any/c]) boolean?]{
如果 @racket[v] 是一个 @tech{input port}，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(output-port? [v any/c]) boolean?]{
如果 @racket[v] 是一个 @tech{output port}，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(port? [v any/c]) boolean?]{
如果 @racket[(input-port? v)] 或 @racket[(output-port? v)] 为 @racket[#t]，则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(close-input-port [in input-port?]) void?]{
关闭输入端口 @racket[in]。对于某些类型的端口，关闭端口会释放较低层的资源，例如文件句柄。如果端口已经被关闭，@racket[close-input-port] 没有效果。}

@defproc[(close-output-port [out output-port?]) void?]{
关闭输出端口 @racket[out]。对于某些类型的端口，关闭端口会释放较低层的资源，例如文件句柄。此外，如果端口有缓冲，关闭可能首先刷新端口再关闭，此刷新过程可能会阻塞。如果端口已经被关闭，@racket[close-output-port] 没有效果。}

@defproc[(port-closed? [port port?]) boolean?]{
如果输入或输出端口 @racket[port] 已关闭，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(port-closed-evt [port port?]) evt?]{
返回一个 @tech{synchronizable event}，当 @racket[port] 关闭时它变为 @tech{ready for synchronization}。@ResultItself{port-closed event}。}

@defparam[current-input-port in input-port?]{一个 @tech{parameter}，决定了 @racket[read] 等许多操作的默认输入端口。}

@defparam[current-output-port out output-port?]{一个 @tech{parameter}，决定了 @racket[write] 等许多操作的默认输出端口。}

@defparam[current-error-port out output-port?]{一个 @tech{parameter}，决定通常用于错误和日志的输出端口。例如，默认的错误显示处理器会向此端口写入。}

@defproc[(file-stream-port? [v any/c]) boolean?]{
如果 @racket[v] 是一个 @tech{file-stream port}（参见 @secref["file-ports"]），返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(terminal-port? [v any/c]) boolean?]{
如果 @racket[v] 是一个连接了交互式终端的端口，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(port-waiting-peer? [port port?]) boolean?]{
如果 @racket[port] 因为在对等进程完成 stream 构造之前而无法读取或写入，则返回 @racket[#t]，否则返回 @racket[#f]。

在 Unix 和 Mac OS 上，如果同一 fifo 没有 reader 已经打开，为输出打开 fifo 会创建一个 peer-waiting port。在这种情况下，输出端口直到 reader 打开后才能写入；即写入操作会阻塞。如果必须等待写入将不会阻塞——即直到 fifo 的读端打开——可使用 @racket[sync]。

@history[#:added "7.4.0.5"]}


@defthing[eof eof-object?]{一个不同于所有其他值的值，表示文件末尾。}

@defproc[(eof-object? [v any/c]) boolean?]{如果 @racket[v] 是 @racket[eof]，返回 @racket[#t]，否则返回 @racket[#f]。}
