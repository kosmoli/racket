#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/port
                     racket/tcp))

@title{端口}

@defmodule[ffi/unsafe/port]{该
@racketmodname[ffi/unsafe/port] 库提供了用于操作端口、文件描述符和套接字的函数。该库的操作为不安全操作，因为不会对文件描述符和套接字进行任何检查，因此误用文件描述符和套接字可能破坏其他对象。}

@history[#:added "6.11.0.4"]

@deftogether[(
@defproc[(unsafe-file-descriptor->port [fd exact-integer?]
                                       [name any/c]
                                       [mode (listof (or/c 'read 'write 'text 'regular-file))])
         (or/c port? (values input-port? output-port?))]
@defproc[(unsafe-socket->port [socket exact-integer?]
                              [name bytes?]
                              [mode (listof (or/c 'no-close))])
         (values input-port? output-port?)]){
         
根据给定的文件描述符或套接字，返回一个输入端口和/或输出端口。在 Windows 上，"文件描述符"对应文件 @tt{HANDLE}，而套接字对应 @tt{SOCKET}。在 Unix 上，套接字也是文件描述符，但使用套接字专用的 @racket[unsafe-socket->port] 可能会启用特定于套接字的功能，例如通过 @racket[tcp-addresses] 报告地址。

@racket[name] 参数决定如 @racket[object-name] 所报告的端口名称。@racket[name] 必须是 UTF-8 编码，该编码将被转换为套接字名称的符号。

对于文件描述符，@racket[mode] 列表必须至少包含 @racket['read] 或 @racket['write] 之一；如果 @racket[mode] 同时包含两者，则返回两个端口。@racket['text] 模式仅影响 Windows 端口。@racket['regular-file] 模式表示文件描述符对应的是一个普通文件（例如，该属性意味着读取永远不会阻塞）。关闭所有返回的文件描述符端口将关闭该文件描述符。

对于套接字，@racket[mode] 列表可以包含 @racket['no-close]，在这种情况下关闭两个返回的端口不会关闭该套接字。

对于任何类型的结果端口，关闭这些端口将就绪并注销任何先前用 @racket[unsafe-file-descriptor->semaphore] 或 @racket[unsafe-socket->semaphore] 为文件描述符或套接字创建的信号量。}


@deftogether[(
@defproc[(unsafe-port->file-descriptor [p port?])
         (or/c exact-integer? #f)]
@defproc[(unsafe-port->socket [p port?])
         (or/c exact-integer? #f)]
)]{

返回 @racket[port] 的文件描述符（在 Windows 上为 @tt{HANDLE} 值）或套接字（如果有的话）；否则返回 @racket[#f]。

在 Unix 和 Mac OS 上，如果 @racket[unsafe-port->file-descriptor] 对应于一个等待其对等端的端口（如 @racket[port-waiting-peer?] 所报告的），例如没有读取者连接的 fifo 写入端，则结果可能为 @racket[#f]。可通过 @racket[sync] 等待直至就绪。

@history[#:changed "7.4.0.5" @elem{为适应 fifo 写入端阻塞在读取者上的情况，
                                   返回 @racket[#f]。}]}


@deftogether[(
@defproc[(unsafe-file-descriptor->semaphore [fd exact-integer?]
                                            [mode (or/c 'read 'write 'check-read 'check-write 'remove)])
         (or/c semaphore? #f)]
@defproc[(unsafe-socket->semaphore [socket exact-integer?]
                                   [mode (or/c 'read 'write 'check-read 'check-write 'remove)])
         (or/c semaphore? #f)]
)]{         

返回一个信号量，当 @racket[fd] 或 @racket[socket] 就绪可供读写时（由 @racket[mode] 选择），该信号量即就绪。具体而言，这些函数提供的是单次、@emph{边沿触发}的指示器；信号量在以下情况中@emph{首次}出现时被提交：

@itemlist[

@item{@racket[fd] 或 @racket[socket] 就绪可供读写（取决于 @racket[mode]），}

@item{使用 @racket[unsafe-file-descriptor->port] 或 @racket[unsafe-socket->port] 为 @racket[fd] 或 @racket[socket] 创建了端口，并且这些端口已被关闭，或者}

@item{之后使用相同的 @racket[fd] 或 @racket[socket] 以及 @racket['remove] 作为 @racket[mode] 进行调用。}

]

如果当前平台或给定的文件描述符、套接字不支持转换为信号量，则结果为 @racket[#f]。

@racket['check-read] 和 @racket['check-write] 模式类似于 @racket['read] 和 @racket['write]，但如果针对指定模式尚未为指定的文件描述符或套接字生成信号量，则返回 @racket[#f]。

@racket['remove] 模式就绪并注销任何先前为给定文件描述符或套接字创建的信号量。必须在文件描述符或套接字关闭之前注销这些信号量。注意，从 @racket[unsafe-file-descriptor->port] 或 @racket[unsafe-socket->port] 返回的端口关闭时，也会就绪并注销信号量。但在这些所有情况下，信号量都是异步就绪的，因此可能存在可检测的延迟。}


@defproc[(unsafe-fd->evt [fd exact-integer?]
                         [mode (or/c 'read 'write 'check-read 'check-write 'remove)]
                         [socket? any/c #t])
         (or/c evt? #f)]{

返回一个事件，当 @racket[fd] 就绪可供读写时（由 @racket[mode] 选择），该事件即就绪。具体而言，它返回的是多用的、@emph{电平触发}的指示器；事件在以下情况@emph{持续}就绪时：

@itemlist[

@item{@racket[fd] 就绪可供读写（取决于 @racket[mode]），}

@item{之后使用相同的 @racket[fd] 以及 @racket['remove] 作为 @racket[mode] 进行调用（一旦移除，事件将永久就绪）。}

]

该事件的同步结果即为事件本身。

@racket['check-read] 和 @racket['check-write] 模式类似于 @racket['read] 和 @racket['write]，但如果针对指定模式尚未为指定的文件描述符或套接字生成事件，则返回 @racket[#f]。

@racket['remove] 模式就绪并注销任何先前为给定文件描述符或套接字创建的事件。必须在文件描述符或套接字关闭之前注销这些事件。与 @racket[unsafe-file-descriptor->semaphore] 和 @racket[unsafe-socket->semaphore] 的信号量结果不同，@racket[unsafe-fd->evt] 的事件结果不会被端口的关闭所触发或注销——即使该端口来自 @racket[unsafe-file-descriptor->port] 或 @racket[unsafe-socket->port]。

@history[#:added "7.2.0.6"]}
