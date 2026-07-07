#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "port-buffers"]{Port Buffers and Positions}

某些端口——尤其是读写文件的端口——内部是缓冲的：

@itemize[

 @item{输入端口默认情况下通常是 block-buffered 的，这意味着在每次读取时，
       缓冲区会被立即可用的 bytes 填充，以加速未来的读取。因此，
       如果文件在一对读取之间被修改，第二次读取可能产生过期数据。
       调用 @racket[file-position] 来设置输入端口的文件位置会刷新其缓冲。}

 @item{输出端口默认情况下通常是 block-buffered 的，但终端输出端口是 line-buffered 的，
       初始错误输出端口是 unbuffered 的。输出缓冲区填充有一系列写入的 bytes，
       它们作为一个组提交，可以在缓冲区满时（block 模式）、写入换行符时（line 模式）、
       通过 @racket[close-output-port] 关闭端口时，或通过类似 @racket[flush-output]
       的过程显式请求刷新时。}

]

如果端口支持缓冲，其缓冲模式可以通过 @racket[file-stream-buffer-mode] 进行更改
（即使端口不是 @tech{file-stream port}）。

对于输入端口，peek 始终将取出的字节放入端口的缓冲中，
即使端口的缓冲模式是 @racket['none]；此外，在某些平台上，
通过 @racket[char-ready?] 或 @racket[sync] 测试端口的输入可能会使用 peek 来实现。
如果输入端口的缓冲模式为 @racket['none]，则 @racket[read-bytes-avail!*]、
@racket[read-bytes-avail!]、@racket[peek-bytes-avail!*] 或 @racket[peek-bytes-avail!]
最多只会读取一个 byte；如果端口中有任何缓冲的 bytes（例如，为了满足之前的 peek），
这些过程可能会访问多个缓冲的 bytes，但不会进一步读取 bytes。

此外，当它们是终端端口（参见 @racket[terminal-port?]）时，
并且在初始标准输入端口上执行了 @racket[read]、@racket[read-line]、
@racket[read-bytes]、@racket[read-string] 等操作时，
初始当前输出和错误端口会自动被刷新。（更准确地说，
不是由 @racket[read] 执行刷新，而是由默认的端口读取处理器执行；
参见 @racket[port-read-handler]。）

@defproc[(flush-output [out output-port? (current-output-port)]) void?]{

@index['("ports" "flushing")]{强制} 将给定输出端口中的所有缓冲数据
进行物理写入。只有 @tech{file-stream ports}、TCP 端口和自定义端口
（参见 @racket["customport"]）使用缓冲；
当对没有缓冲的端口调用时，@racket[flush-output] 无效。

如果刷新 @tech{file-stream port} 或 @racket[TCP port] 时遇到写入错误，
则端口中的所有缓冲 bytes 将被丢弃。因此，进一步尝试刷新或关闭端口不会失败。

@history[#:changed "7.4.0.10" @elem{在错误时一致地丢弃缓冲的 bytes，包括在 TCP 输出端口中。}]}

@defproc*[([(file-stream-buffer-mode [port port?]) (or/c 'none 'line 'block #f)]
           [(file-stream-buffer-mode [port port?] [mode (or/c 'none 'line 'block)]) void?])]{

获取或设置 @racket[port] 的缓冲模式，如果可能。@tech{File-stream ports}
支持设置缓冲模式，TCP 端口（参见 @secref["networking"]）支持设置和获取缓冲模式，
自定义端口（参见 @secref["customport"]）可能支持获取和设置缓冲模式。

如果提供了 @racket[mode]，它必须是 @indexed-racket['none]、@indexed-racket['line]（仅输出）
或 @indexed-racket['block] 之一，端口的缓冲将相应设置。
如果端口不支持设置模式，则 @exnraise[exn:fail]。

如果未提供 @racket[mode]，则返回当前模式，如果无法确定模式则返回 @racket[#f]。
如果 @racket[port] 是输入端口且 @racket[mode] 是 @racket['line]，
则 @exnraise[exn:fail:contract]。}

@defproc*[([(file-position [port port?]) exact-nonnegative-integer?]
           [(file-position [port port?] [pos (or/c exact-nonnegative-integer? eof-object?)]) void?])]{

返回或设置 @racket[port] 的当前读/写位置。

对除 @tech{file-stream port} 或 @tech{string port} 以外的端口调用
@racket[file-position] 而不带位置参数，如果已知位置（参见 @secref["linecol"]），
则返回已从该端口读取的 bytes 数量，否则 @exnraise[exn:fail:filesystem]。

对于 @tech{file-stream ports} 和 @tech{string ports}，位置设置变体
将读/写位置设置为相对于文件开头的位置（如果 @racket[pos] 是数字），
或设置为相对于文件末尾的位置（如果 @racket[pos] 是 @racket[eof]）。
在位置设置模式下，@racket[file-position] 对除
@tech{file-stream ports} 和 @tech{string ports} 以外的端口类型
引发 @racket[exn:fail:contract] 异常。此外，并非所有 @tech{file-stream ports}
都支持设置位置；如果在不支持位置设置的 @tech{file-stream port}
上调用带位置参数的 @racket[file-position]，则 @exnraise[exn:fail:filesystem]。

当 @racket[file-position] 设置的位置超出输出文件或 (byte) string 的当前大小时，
文件/string 将被扩展到大小 @racket[pos]，新区域用 @racket[0] bytes 填充；
在文件的情况下。在文件输出端口的情况下，文件可能在写入更多数据之前不会被扩展；
在这种情况下，请注意在 Unix 和 Mac OS 上以 @racket['append] 模式打开的文件写入
会在每次写入 @emph{之前} 将文件指针重置到文件末尾，
这阻止了通过 @racket[file-position] 进行的文件扩展。
如果 @racket[pos] 超出了输入文件或 (byte) string 的末尾，
则其后的读取将返回 @racket[eof] 而不改变端口位置。

当更改输出端口的文件位置时，如果其缓冲区非空，则首先刷新端口。
类似地，设置输入端口的位置会清除端口的缓冲区
（即使新位置与旧位置相同）。然而，尽管 @racket[open-input-output-file]
产生的输入和输出端口共享文件位置，通过一个端口设置位置不会刷新另一个端口的缓冲。}

@defproc[(file-position* [port port?]) (or/c exact-nonnegative-integer? #f)]{

类似于 @racket[file-position] 的单参数形式，但如果位置未知则返回 @racket[#f]。}

@defproc[(file-truncate [port (and/c output-port? file-stream-port?)]
                        [size exact-nonnegative-integer?]) 
         void?]{

将 @racket[port] 写入的文件大小设置为 @racket[size]，
假设端口关联到可以设置大小的文件。

新文件大小可以比当前大小更大或更小，但此函数名称中的 "truncate"
反映了它通常用于减小文件大小，因为写入文件或使用 @racket[file-position]
可以扩展文件大小。}

@defproc[(terminal-file-position) exact-nonnegative-integer?]{

报告已写入连接到终端的端口（如原始输出和错误端口）的 bytes 数量。
即使是由 Racket 进程启动的 subprocess 写入同一终端的 bytes，
也不会包括在此计数中。

@history[#:added "9.1.0.5"]}
