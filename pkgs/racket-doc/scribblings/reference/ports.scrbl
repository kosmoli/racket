#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "ports" #:style 'toc]{Ports}

@deftech{端口}产生和/或消费字节。@deftech{输入端口}产生字节，而@deftech{输出端口}消费字节（有些端口同时是输入端口和输出端口）。当向一个基于字符的操作提供输入端口时，字节被解码为字符，且基于字符的输出操作类似地将字符编码为字节；参见 @secref["encodings"]。除了字节和编码为字节的字符之外，一些端口还可以产生和/或消费任意值作为 @deftech{特殊} 结果。

当端口对应于文件、网络连接或某些其他系统资源时，必须通过 @racket[close-input-port] 或 @racket[close-output-port]（或通过 @racket[custodian-shutdown-all] 间接）显式关闭，以释放与端口相关的底层资源。对于任何类型的端口，在关闭后，尝试从端口读取或写入端口将引发 @racket[exn:fail]。

由 @tech{输入端口} 产生的数据可以被读取或 @deftech[#:key "窥视"]{窥视}。当数据被读取时，它被视为已消费并从端口的流中移除。当数据被 @tech{窥视} 时，它保留在端口的流中，以便在下一次读取或 @tech{窥视} 时再次返回。先前窥视的数据可以被 @deftech[#:key "提交"]{提交}，这会使数据从端口中移除，类似于读取，但与 @tech{可同步事件} 同步其他 @tech{窥视} 或读取尝试的方式不同。读取和 @tech{窥视} 操作通常都是阻塞的，即读取或 @tech{窥视} 操作要到端口有数据可用时才完成；读取和 @tech{窥视} 操作的非阻塞变体也可用。

全局变量 @racket[eof] 被绑定到文件末尾值，且 @racket[eof-object?] 仅在应用于此值时返回 @racket[#t]。当端口不再有数据时，从端口读取会产生文件末尾结果，但某些端口也可能在流中间返回文件末尾。例如，连接到 Unix 终端的端口在用户键入 control-D 时返回文件末尾；如果用户提供更多输入，端口在文件末尾之后返回附加字节。

每个端口都有一个名称，由 @racket[object-name] 报告。名称可以是任意值，主要用于错误报告目的。@racket[read-syntax] 过程使用输入端口的名称作为其生成的 @tech{syntax object} 的默认源位置。

端口可以用作 @tech{可同步事件}。当 @racket[read-byte] 不会被阻塞时，输入端口 @tech{准备好进行同步}，当 @racket[write-bytes-avail] 不会被阻塞或当端口包含缓冲字符且 @racket[write-bytes-avail*] 可以刷新部分缓冲区时，输出端口 @tech{准备好进行同步}（尽管 @racket[write-bytes-avail] 可能会阻塞）。可以同时作为输入端口和输出端口的值，对于 @tech{可同步事件} 用作输入端口。@ResultItself{port}。

@;------------------------------------------------------------------------

@local-table-of-contents[]

@include-section["encodings.scrbl"]
@include-section["port-procs.scrbl"]
@include-section["port-buffers.scrbl"]
@include-section["port-line-counting.scrbl"]
@include-section["file-ports.scrbl"]
@include-section["string-ports.scrbl"]
@include-section["pipes.scrbl"]
@include-section["prop-port.scrbl"]
@include-section["custom-ports.scrbl"]
@include-section["port-lib.scrbl"]
