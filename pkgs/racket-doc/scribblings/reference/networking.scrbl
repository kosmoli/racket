#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "networking" #:style 'toc]{Networking}

@local-table-of-contents[]

@;------------------------------------------------------------------------
@section[#:tag "tcp"]{TCP}

@note-lib[racket/tcp]

关于 TCP 的一般信息，参见 W. Richard Stevens 所著的 @italic{TCP/IP Illustrated, Volume 1}。

@defproc[(tcp-listen [port-no listen-port-number?]
                     [max-allow-wait exact-nonnegative-integer? 4]
                     [reuse? any/c #f]
                     [hostname (or/c string? #f) #f]) 
         tcp-listener?]{

Creates a ``listening'' server on the local machine at the port number
specified by @racket[port-no]. If @racket[port-no] is 0 the socket binds
to an ephemeral port, which can be determined by calling 
@racket[tcp-addresses].  The @racket[max-allow-wait] argument
determines the maximum number of client connections that can be
waiting for acceptance. (When @racket[max-allow-wait] clients are
awaiting acceptance, no new client connections can be made.)

如果 @racket[reuse?] 参数为真，@racket[tcp-listen]
会在端口处于 @tt{TIME_WAIT} 状态时也创建监听器。这种对 @racket[reuse?]
的使用会破坏 TCP 协议的某些保证，详见 Stevens 的著作。此外，在许多
现代平台上，只有当监听器之前也是以真的 @racket[reuse?] 值创建的，
@racket[reuse?] 的真值才会覆盖 @tt{TIME_WAIT} 状态。

如果 @racket[hostname] 为 @racket[#f]（默认值），则监听器接受
连接到监听机器所有地址的连接。否则，监听器仅接受与给定 hostname
关联的接口上的连接。例如，将 @racket["127.0.0.1"] 作为 @racket[hostname]
提供一个监听器，它只接受来自本地机器到 @racket["127.0.0.1"]
（回环接口）的连接。

如有必要，Racket 会用多个 socket 实现监听器，以容纳具有不同
protocol family 的多个地址。在 Linux 上，如果 @racket[hostname] 同时
映射到 IPv4 和 IPv6 地址，则其行为取决于是否支持 IPv6 以及 IPv6
socket 是否可以配置为只监听 IPv6 连接：如果 IPv6 不受支持或 IPv6
socket 无法配置，则 IPv6 地址会被忽略；否则，每个 IPv6 监听器
只接受 IPv6 连接。

在支持 @tt{FD_CLOEXEC} 的 Unix 和 MacOS 变体上，listener socket
会被标记该标志，从而不会与 @racket[subprocess] 创建的子进程共享。

@racket[tcp-listen] 的返回值是一个 @deftech{TCP listener}。
该值可用于后续调用 @racket[tcp-accept]、@racket[tcp-accept-ready?]
和 @racket[tcp-close]。每个新的 TCP listener 值都会被置于当前
custodian 的管理之下（见 @secref["custodians"]）。

如果 @racket[tcp-listen] 无法启动服务器，
则 @exnraise[exn:fail:network]。

TCP listener 可以用作 @tech{synchronizable event}（见 @secref["sync"]）。
当 @racket[tcp-accept] 不会阻塞时，TCP listener 即 @tech{ready for synchronization}；
@resultItself{TCP listener}。

@history[#:changed "8.11.1.6" @elem{改为在操作系统支持时使用 @tt{FD_CLOEXEC}。}]}


@defproc[(tcp-connect [hostname string?]
                      [port-no port-number?]
                      [local-hostname (or/c string? #f) #f]
                      [local-port-no (or/c port-number? #f)
                                     #f])
          (values input-port? output-port?)]{

尝试作为客户端连接到监听服务器。@racket[hostname] 参数是服务器主机的
Internet 地址名称，@racket[port-no] 是服务器正在监听的端口号。

（如果 @racket[hostname] 关联多个地址，它们会逐个尝试直到连接成功。
名称 @racket["localhost"] 通常指定本地机器。）

可选的 @racket[local-hostname] 和 @racket[local-port-no] 指定客户端
的地址和端口。如果两者都为 @racket[#f]（默认值），则自动选择
客户端的地址和端口。如果 @racket[local-hostname] 不为 @racket[#f]，
则 @racket[local-port-no] 必须为非 @racket[#f] 值。
如果 @racket[local-port-no] 为非 @racket[#f] 且 @racket[local-hostname]
为 @racket[#f]，则使用给定的端口但地址会自动选择。

@racket[tcp-connect] 返回两个值：一个 input port 和一个 output port。
数据可以通过 input port 从服务器接收，通过 output port 发送到服务器。
如果服务器是 Racket 程序，它可以通过 @racket[tcp-accept] 获取与客户端
通信的端口。这些端口会被置于当前 custodian 的管理之下
（见 @secref["custodians"]）。

最初，返回的 input port 和 output port 都是 block-buffered。
使用 @racket[file-stream-buffer-mode] 更改缓冲模式。
当 TCP output port 是 block-buffered 时，Nagle 算法会被禁用，
这对应于设置 @as-index{@tt{TCP_NODELAY}} socket 选项。

两个返回的端口都必须关闭才能终止 TCP 连接。当两个端口仍打开时，
使用 @racket[close-output-port] 关闭 output port 会向服务器发送
TCP close（如果服务器通过端口读取连接，则被视为 end-of-file）。
相反，@racket[tcp-abandon-port]（见下文）关闭 output port，
但直到 input port 也关闭后才发送 TCP close。

注意，TCP 协议不支持一端愿意发送但不读取的状态，也不包含
当连接一端完全关闭时的自动消息。相反，连接的另一端只有在
作为发送数据的响应时才会发现一端已经完全关闭；特别是，
仍在打开的一端的某些写入操作可能看起来会成功，尽管最终这些
写入会产生错误。

On variants of Unix and MacOS that support @tt{FD_CLOEXEC}, a
connection socket is given that flag so that it is not shared with a
subprocess created by @racket[subprocess].

如果 @racket[tcp-connect] 无法建立连接，
则 @exnraise[exn:fail:network]。

@history[#:changed "8.8.0.8" @elem{改为使 block buffering 隐含
                                   @tt{TCP_NODELAY}。}
         #:changed "8.11.1.6" @elem{改为在操作系统支持时使用 @tt{FD_CLOEXEC}。}]}

@defproc[(tcp-connect/enable-break [hostname string?]
                      [port-no port-number?]
                      [local-hostname (or/c string? #f) #f]
                      [local-port-no (or/c port-number? #f)])
          (values input-port? output-port?)]{

类似于 @racket[tcp-connect]，但在尝试连接时启用
breaking（见 @secref["breakhandler"]）。如果在调用
@racket[tcp-connect/enable-break] 时 breaking 被禁用，
则要么返回端口，要么引发 @racket[exn:break] 异常，
二者不会同时发生。}

@defproc[(tcp-accept [listener tcp-listener?])
         (values input-port? output-port?)]{

接受与 @racket[listener] 关联的服务器的客户端连接。
如果没有客户端连接等待在监听端口上，@racket[tcp-accept] 调用
将会阻塞。（另见 @racket[tcp-accept-ready?]。）

@racket[tcp-accept] 返回两个值：一个 input port 和一个 output port。
数据可以通过 input port 从客户端接收，通过 output port 发送到客户端。
这些端口会被置于当前 custodian 的管理之下
（见 @secref["custodians"]）。

在缓冲和连接状态方面，这些端口与来自 @racket[tcp-connect]
的端口行为相同。

On variants of Unix and MacOS that support @tt{FD_CLOEXEC}, an
accepted socket is given that flag so that it is not shared with a
subprocess created by @racket[subprocess].

如果 @racket[tcp-accept] 无法接受连接，或者 listener 已经关闭，
则 @exnraise[exn:fail:network]。

@history[#:changed "8.11.1.6" @elem{改为在操作系统支持时使用 @tt{FD_CLOEXEC}。}]}


@defproc[(tcp-accept/enable-break [listener tcp-listener?])
         (values input-port? output-port?)]{

类似于 @racket[tcp-accept]，但在尝试接受连接时启用
breaking（见 @secref["breakhandler"]）。如果在调用
@racket[tcp-accept/enable-break] 时 breaking 被禁用，
则要么返回端口，要么引发 @racket[exn:break] 异常，
二者不会同时发生。}


@defproc[(tcp-accept-ready? [listener tcp-listener?]) boolean?]{

测试是否有未被接受的客户端已连接到与 @racket[listener] 关联的
服务器。如果有客户端在等待，则返回值为 @racket[#t]，否则为
@racket[#f]。使用 @racket[tcp-accept] 过程接受客户端，
该过程返回用于与客户端通信的端口并将客户端从待接受客户端列表中移除。

如果 listener 已经关闭，则 @exnraise[exn:fail:network]。}


@defproc[(tcp-close [listener tcp-listener?]) void?]{

关闭与 @racket[listener] 关联的服务器。所有未被接受的客户端
会从服务器收到 end-of-file；到已接受客户端的连接不受影响。

如果 listener 已经关闭，则 @exnraise[exn:fail:network]。

listener 的端口号可能无法立即用于新的 listener
（使用 @racket[tcp-listen] 的默认 @racket[_reuse?] 参数）。
更多信息请参见 Stevens 对 @tt{TIME_WAIT} TCP 状态的解释。}


@defproc[(tcp-listener? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[tcp-listen] 创建的
@tech{TCP listener} 则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(tcp-accept-evt [listener tcp-listener?]) evt?]{

返回一个 @tech{synchronizable event}（见 @secref["sync"]），
当 @racket[tcp-accept] 在 @racket[listener] 上不会阻塞时，
它 @tech{ready for synchronization}。
@tech{synchronization result} 是包含两项的列表，对应
@racket[tcp-accept] 的两个返回值。（如果该事件在 @racket[sync]
中未被选择，则不接受任何连接。）端口会被置于调用
@racket[tcp-accept-evt] 时那个 current custodian 的管理之下
（见 @secref["custodians"]）。}


@defproc[(tcp-abandon-port [tcp-port tcp-port?]) void?]{

类似于 @racket[close-output-port] 或 @racket[close-input-port]
（取决于 @racket[tcp-port] 是 input port 还是 output port），
但如果 @racket[tcp-port] 是 output port 且其关联的 input port
尚未关闭，则 TCP 连接的另一端直到 input port 也关闭后才会
收到 TCP close 消息。

TCP 协议不包含连接上的"不再读取"状态，因此
@racket[tcp-abandon-port] 在 input @tech{TCP ports} 上
等同于 @racket[close-input-port]。}


@defproc[(tcp-addresses [tcp-port (or/c tcp-port? tcp-listener? udp?)]
                        [port-numbers? any/c #f]) 
         (or/c (values string? string?)
               (values string? port-number?
                       string? listen-port-number?))]{

当 @racket[port-numbers?] 为 @racket[#f]（默认值）时返回两个字符串。
第一个字符串是给定 @tech{TCP port} 连接（或 TCP listener 或 UDP socket）
所看到的本地机器的 Internet 地址。（当机器服务多个地址时——如果计算
回环设备，通常就是如此——结果是 connection-specific 或
listener-specific。）如果提供的 listener 或 UDP socket 没有具体的
host，则第一个字符串结果为 @racket["0.0.0.0"]。第二个字符串是
连接另一端的 Internet 地址，对于 listener 或未连接的 UDP socket
则始终为 @racket["0.0.0.0"]。

如果 @racket[port-numbers?] 为真，则返回四个值：本地机器地址的字符串、
本地机器端口号在 @racket[1] 到 @racket[65535] 之间的精确整数、
远程机器地址的字符串、以及远程机器端口号在 @racket[1] 到 @racket[65535]
之间的精确整数（对于 listener 则为 @racket[0]）。

如果提供的 port、listener 或 socket 已被关闭，
则 @exnraise[exn:fail:network]。}


@defproc[(tcp-port? [v any/c]) boolean?]{

如果 @racket[v] 是 @deftech{TCP port}——即由 @racket[tcp-accept]、
@racket[tcp-connect]、@racket[tcp-accept/enable-break] 或
@racket[tcp-connect/enable-break] 返回的端口——则返回 @racket[#t]，
否则返回 @racket[#f]。}

@defthing[port-number? contract?]{
等同于 @racket[(integer-in 1 65535)]。

@history[#:added "6.3"]{}
}

@defthing[listen-port-number? contract?]{
等同于 @racket[(integer-in 0 65535)]。

@history[#:added "6.3"]{}
}

@;------------------------------------------------------------------------
@section[#:tag "udp"]{UDP}

@note-lib[racket/udp]

关于 UDP 的一般信息，参见 W. Richard Stevens 所著的 @italic{TCP/IP Illustrated, Volume 1}。

@defproc[(udp-open-socket [family-hostname (or/c string? #f) #f]
                          [family-port-no (or/c port-number? #f) #f])
         udp?]{

创建并返回一个 @deftech{UDP socket}，用于发送和接收 datagram
（允许 broadcasting）。最初，该 socket 未绑定或连接到任何地址或端口。

如果 @racket[family-hostname] 或 @racket[family-port-no]
不为 @racket[#f]，则 socket 的 protocol family 由这些参数确定。
该 socket @italic{不会}绑定到 hostname 或端口号。例如，
这些参数可能是通过该 socket 将发送消息的目标 hostname 和 port，
从而确保 socket 的 protocol family 与目标一致。或者，
这些参数可能与将来调用 @racket[udp-bind!] 时的参数相同，
从而确保 socket 的 protocol family 与绑定一致。如果
@racket[family-hostname] 和 @racket[family-port-no] 都不是
非 @racket[#f] 值，则 socket 的 protocol family 为 IPv4。

在支持 @tt{FD_CLOEXEC} 的 Unix 和 MacOS 变体上，socket 会被标记
该标志，从而不会与 @racket[subprocess] 创建的子进程共享。

@history[#:changed "8.11.1.6" @elem{改为在操作系统支持时使用 @tt{FD_CLOEXEC}。}]}

@defproc[(udp-bind! [udp-socket udp?]
                    [hostname-string (or/c string? #f)]
                    [port-no listen-port-number?]
		    [reuse? any/c #f])
         void?]{

将一个未绑定的 @racket[udp-socket] 绑定到本地端口号
@racket[port-no]。如果 @racket[port-no] 为 0，则 @racket[udp-socket]
会被绑定到一个临时端口，可以通过调用 @racket[udp-addresses] 来确定。

如果 @racket[hostname-string] 为 @racket[#f]，则 socket 接受
在 @racket[port-no] 上连接到监听机器所有 IP 地址的连接。
否则，socket 仅接受与给定名称关联的 IP 地址上的连接。
例如，提供 @racket["127.0.0.1"] 作为 @racket[hostname-string]
通常会创建一个只接受来自本地机器到 @racket["127.0.0.1"]
连接的监听器。

Socket 必须绑定到本地地址和端口才能接收 datagram。
如果 socket 在使用发送过程（如 @racket[udp-send]、
@racket[udp-send-to] 等）之前未被绑定，则发送过程会将 socket
绑定到一个随机本地端口。类似地，如果来自 @racket[udp-send-evt]
或 @racket[udp-send-to-evt] 的事件被用于同步（见 @secref["sync"]），
则 socket 会被绑定；如果该事件未被选择，则 socket 可能被绑定也可能不被绑定。 

已绑定 socket 的绑定无法更改，但有一个例外：在某些系统上，
如果 socket 在发送时自动绑定，如果通过 @racket[udp-connect!]
断开了 socket 的连接，如果之后 socket 再次用于发送，
则后来的发送可能会更改 socket 的自动绑定。

如果 @racket[udp-socket] 已经绑定或已关闭，
则 @exnraise[exn:fail:network]。

如果 @racket[reuse?] 参数为真，则 @racket[udp-bind!] 会在绑定前
设置 @tt{SO_REUSEADDR} socket 选项，从而在使用 UDP multicast
时允许多个进程共享对单个机器上 UDP 端口的访问。}

@defproc[(udp-connect! [udp-socket udp?]
                       [hostname-string (or/c string? #f)]
                       [port-no (or/c port-number? #f)])
         void?]{

如果 @racket[hostname-string] 是字符串且 @racket[port-no]
是精确整数，则将 socket 连接到指定的远程地址和端口。

如果 @racket[hostname-string] 为 @racket[#f]，则 @racket[port-no]
也必须为 @racket[#f]，并且端口断开连接（如果之前已连接）。
如果 @racket[hostname-string] 或 @racket[port-no] 中有一个为
@racket[#f] 而另一个不是，则 @exnraise[exn:fail:contract]。

已连接的 socket 可以与 @racket[udp-send]（不是
@racket[udp-send-to]）一起使用，并且它只接受来自已连接地址和
端口的 datagram。Socket 不必连接就能接收 datagram。
Socket 可以多次连接、重新连接和断开连接。

如果 @racket[udp-socket] 已关闭，则 @exnraise[exn:fail:network]。}


@defproc[(udp-send-to [udp-socket udp?]
                      [hostname string?]
                      [port-no port-number?]
                      [bstr bytes?]
                      [start-pos exact-nonnegative-integer? 0]
                      [end-pos exact-nonnegative-integer? (bytes-length bstr)]) 
         void?]{

将 @racket[(subbytes bytes start-pos end-pos)] 作为 datagram
从未连接的 @racket[udp-socket] 发送到远程机器 @racket[hostname-address]
上端口 @racket[port-no] 处的 socket。@racket[udp-socket]
不必绑定或连接；如果未绑定，@racket[udp-send-to] 会将其绑定到随机本地端口。
如果 socket 的 outgoing datagram 队列太满无法支持发送，
则 @racket[udp-send-to] 会阻塞直到该 datagram 可以被队列化。

如果 @racket[start-pos] 大于 @racket[bstr] 的长度，
或者 @racket[end-pos] 小于 @racket[start-pos] 或大于 @racket[bstr] 的长度，
则 @exnraise[exn:fail:contract]。

如果 @racket[udp-socket] 已关闭或已连接，
则 @exnraise[exn:fail:network]。}

@defproc[(udp-send [udp-socket udp?]
                   [bstr bytes?]
                   [start-pos exact-nonnegative-integer? 0]
                   [end-pos exact-nonnegative-integer? (bytes-length bstr)]) 
         void?]{

类似于 @racket[udp-send-to]，但 @racket[udp-socket] 必须已连接，
并且 datagram 发送到连接目标。如果 @racket[udp-socket]
已关闭或未连接，则 @exnraise[exn:fail:network]。}

@defproc[(udp-send-to* [udp-socket udp?]
                       [hostname string?]
                       [port-no port-number?]
                       [bstr bytes?]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos exact-nonnegative-integer? (bytes-length bstr)]) 
         boolean?]{

类似于 @racket[udp-send-to]，但从不阻塞；如果 socket 的 outgoing
队列太满无法支持发送，则返回 @racket[#f]，否则 datagram
被队列化且结果为 @racket[#t]。}

@defproc[(udp-send* [udp-socket udp?]
                    [bstr bytes?]
                    [start-pos exact-nonnegative-integer? 0]
                    [end-pos exact-nonnegative-integer? (bytes-length bstr)]) 
         boolean?]{

类似于 @racket[udp-send]，但（像 @racket[udp-send-to*]）
它从不阻塞，并返回 @racket[#f] 或 @racket[#t]。}

@defproc[(udp-send-to/enable-break [udp-socket udp?]
                      [hostname string?]
                      [port-no port-number?]
                      [bstr bytes?]
                      [start-pos exact-nonnegative-integer? 0]
                      [end-pos exact-nonnegative-integer? (bytes-length bstr)]) 
         void?]{

类似于 @racket[udp-send-to]，但在尝试发送 datagram 时启用
breaking（见 @secref["breakhandler"]）。如果在调用
@racket[udp-send-to/enable-break] 时 breaking 被禁用，
则要么 datagram 被发送，要么引发 @racket[exn:break] 异常，
二者不会同时发生。}


@defproc[(udp-send/enable-break [udp-socket udp?]
                   [bstr bytes?]
                   [start-pos exact-nonnegative-integer? 0]
                   [end-pos exact-nonnegative-integer? (bytes-length bstr)]) 
         void?]{

类似于 @racket[udp-send]，但启用 breaks 的方式
类似于 @racket[udp-send-to/enable-break]。}


@defproc[(udp-receive! [udp-socket udp?]
                       [bstr (and/c bytes? (not immutable?))]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (values exact-nonnegative-integer?
                 string?
                 port-number?)]{

接受 @racket[udp-socket] 的下一个 incoming datagram 中最多
@math{@racket[end-pos]-@racket[start-pos]} 字节到 @racket[bstr] 中，
将 datagram 字节写入 @racket[bstr] 中起始位置为 @racket[start-pos]
的地方。@racket[udp-socket] 必须绑定到本地地址和端口
（但不需要连接）。如果没有立即可用的 incoming datagram，
则 @racket[udp-receive!] 会阻塞直到有一个可用。

返回三个值：接收到的字节数（在 @racket[0] 到
@math{@racket[end-pos]-@racket[start-pos]} 之间）、
指示 datagram 源地址的 hostname 字符串、以及指示 datagram 源端口的整数。
如果接收到的 datagram 长于 @math{@racket[end-pos]-@racket[start-pos]} 字节，
则多余部分被丢弃。

如果 @racket[start-pos] 大于 @racket[bstr] 的长度，
或者 @racket[end-pos] 小于 @racket[start-pos] 或大于 @racket[bstr] 的长度，
则 @exnraise[exn:fail:contract]。}

@defproc[(udp-receive!* [udp-socket udp?]
                       [bstr (and/c bytes? (not immutable?))]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (values (or/c exact-nonnegative-integer? #f)
                 (or/c string? #f)
                 (or/c port-number? #f))]{

类似于 @racket[udp-receive!]，但从不阻塞。如果没有 datagram
可用，则三个返回值都为 @racket[#f]。}

@defproc[(udp-receive!/enable-break [udp-socket udp?]
                       [bstr (and/c bytes? (not immutable?))]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (values exact-nonnegative-integer?
                 string?
                 port-number?)]{

类似于 @racket[udp-receive!]，但在尝试接收 datagram 时启用
breaking（见 @secref["breakhandler"]）。如果在调用
@racket[udp-receive!/enable-break] 时 breaking 被禁用，
则要么 datagram 被接收，要么引发 @racket[exn:break] 异常，
二者不会同时发生。}


@defproc[(udp-set-receive-buffer-size! [udp-socket udp?]
                                       [size exact-positive-integer?])
                                       void?]{

设置 @racket[udp-socket] 的 receive buffer size (@tt{SO_RCVBUF})。
使用更大的缓冲区可以最小化由于轮询连接缓慢而可能发生的
packet loss，包括在进行 major garbage collection 期间。

如果 @racket[size] 大于系统允许的最大值，
则 @exnraise[exn:fail:network]。

@history[#:added "7.1.0.11"]}


@defproc[(udp-close [udp-socket udp?]) void?]{

关闭 @racket[udp-socket]，丢弃未接收的 datagram。
如果 socket 已经关闭，则 @exnraise[exn:fail:network]。}


@defproc[(udp? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[udp-open-socket] 创建的 socket
则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(udp-bound? [udp-socket udp?]) boolean?]{

如果 @racket[udp-socket] 已绑定到本地地址和端口
则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(udp-connected? [udp-socket udp?]) boolean?]{

如果 @racket[udp-socket] 已连接到远程地址和端口
则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(udp-send-ready-evt [udp-socket udp?]) evt?]{

返回一个 @tech{synchronizable event}（见 @secref["sync"]），
当 @racket[udp-send-to] 在 @racket[udp-socket] 上会阻塞时，
该事件处于阻塞状态。@tech{synchronization result} 是事件本身。
}


@defproc[(udp-receive-ready-evt [udp-socket udp?]) evt?]{

返回一个 @tech{synchronizable event}（见 @secref["sync"]），
当 @racket[udp-receive!] 在 @racket[udp-socket] 上会阻塞时，
该事件处于阻塞状态。@tech{synchronization result} 是事件本身。
}

@defproc[(udp-send-to-evt [udp-socket udp?]
                      [hostname string?]
                      [port-no port-number?]
                      [bstr bytes?]
                      [start-pos exact-nonnegative-integer? 0]
                      [end-pos exact-nonnegative-integer? (bytes-length bstr)]) 
         evt?]{

返回一个 @tech{synchronizable event}。当 @racket[udp-send-to]
在 @racket[udp-socket] 上会阻塞时，该事件处于阻塞状态。
否则，如果在同步中选择了该事件，数据将按
@racket[(udp-send-to udp-socket hostname-address port-no
bstr start-pos end-pos)] 的方式发送，且 synchronization result 为
@|void-const|。（如果未选择该事件，则不发送任何字节。）}


@defproc[(udp-send-evt [udp-socket udp?]
                      [bstr bytes?]
                      [start-pos exact-nonnegative-integer? 0]
                      [end-pos exact-nonnegative-integer? (bytes-length bstr)]) 
         evt?]{

返回一个 @tech{synchronizable event}。当 @racket[udp-send]
在 @racket[udp-socket] 上不会阻塞时，该事件 @tech{ready for synchronization}。
否则，如果在同步中选择了该事件，数据将按
@racket[(udp-send-to udp-socket bstr start-pos end-pos)] 的方式发送，
且 @tech{synchronization result} 为 @|void-const|。
（如果未选择该事件，则不发送任何字节。）如果 @racket[udp-socket]
已关闭或未连接，则在同步尝试期间 @exnraise[exn:fail:network]。}

@defproc[(udp-receive!-evt [udp-socket udp?]
                       [bstr (and/c bytes? (not immutable?))]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         evt?]{

返回一个 @tech{synchronizable event}。当 @racket[udp-receive]
在 @racket[udp-socket] 上不会阻塞时，该事件 @tech{ready for synchronization}。
否则，如果在同步中选择了该事件，数据将按
@racket[(udp-receive! udp-socket bytes start-pos end-pos)] 的方式
接收到 @racket[bstr] 中，且 @tech{synchronization result} 是包含
三个值的列表，对应 @racket[udp-receive!] 的三个返回值。
（如果未选择该事件，则不接收任何字节，@racket[bstr]
的内容不会被修改。）}

@defproc[(udp-addresses [udp-port udp?]
                        [port-numbers? any/c #f]) 
         (or/c (values string? string?)
               (values string? listen-port-number?
                       string? listen-port-number?))]{

当 @racket[port-numbers?] 为 @racket[#f]（默认值）时返回两个字符串。
第一个字符串是给定 @tech{UDP socket} 连接所看到的本地机器的
Internet 地址。（对于大多数机器，答案对应于当前机器唯一的
Internet 地址，但当机器服务多个地址时，结果是 connection-specific。）
第二个字符串是连接另一端的 Internet 地址。

如果 @racket[port-numbers?] 为真，则返回四个值：本地机器地址的字符串、
本地机器端口号在 @racket[1] 到 @racket[65535] 之间的精确整数
（如果 socket 未绑定则为 @racket[0]）、远程机器地址的字符串、
以及远程机器端口号在 @racket[1] 到 @racket[65535] 之间的精确整数
（如果 socket 未连接则为 @racket[0]）。

如果提供的 port 已被关闭，则 @exnraise[exn:fail:network]。}


@deftogether[(
@defproc[(udp-set-ttl! [udp-socket udp?] [ttl byte?]) void?]
@defproc[(udp-ttl [udp-socket udp?]) byte?]
)]{

@margin-note{Time-to-live 设置对应于该 socket 的
@as-index{@tt{IP_TTL}} 设置。}

设置或获取 @racket[udp-socket] 的当前 time-to-live 设置。

@history[#:added "7.5.0.5"]}


@deftogether[(
@defproc[(udp-multicast-join-group! [udp-socket udp?]
				    [multicast-addr string?]
				    [hostname (or/c string? #f)]) void?]
@defproc[(udp-multicast-leave-group! [udp-socket udp?]
				     [multicast-addr string?]
				     [hostname (or/c string? #f)]) void?]
)]{
将 @racket[udp-socket] 添加或移除到命名的 multicast group。

@racket[multicast-addr] 参数必须是有效的 IPv4 multicast IP 地址；
例如，@racket["224.0.0.251"] 是 mDNS protocol 的合适地址。
@racket[hostname] 参数选择 socket 用于接收（不是发送）multicast datagram 的接口；
如果 @racket[hostname] 为 @racket[#f] 或 @racket["0.0.0.0"]，
则 kernel 会自动选择一个接口。

离开 group 需要使用与加入 group 时相同的
@racket[multicast-addr] 和 @racket[hostname] 参数。}



@deftogether[(
@defproc[(udp-multicast-interface [udp-socket udp?]) string?]
@defproc[(udp-multicast-set-interface! [udp-socket udp?]
				       [hostname (or/c string? #f)])
	void?]
)]{

获取或设置 @racket[udp-socket] 用于发送（不是接收）
multicast datagram 的接口。如果结果或 @racket[hostname] 为
@racket[#f] 或 @racket["0.0.0.0"]，则当发送 multicast datagram
时 kernel 会自动选择一个接口。}


@deftogether[(
@defproc[(udp-multicast-set-loopback! [udp-socket udp?] [loopback? any/c]) void?]
@defproc[(udp-multicast-loopback? [udp-socket udp?]) boolean?]
)]{

@margin-note{Loopback 设置对应于该 socket 的
@as-index{@tt{IP_MULTICAST_LOOP}} 设置。}

设置或检查 @racket[udp-socket] 是否接收自己的 multicast datagram：
@racket[#t] 结果或 @racket[loopback?] 的真值表示自接收已启用，
@racket[#f] 表示自接收已禁用。}


@deftogether[(
@defproc[(udp-multicast-set-ttl! [udp-socket udp?] [ttl byte?]) void?]
@defproc[(udp-multicast-ttl [udp-socket udp?]) byte?]
)]{

@margin-note{Time-to-live 设置对应于该 socket 的
@as-index{@tt{IP_MULTICAST_TTL}} 设置。}

设置或获取 @racket[udp-socket] 的当前 time-to-live 设置。

time-to-live 设置应几乎始终为 1，且重要的是此数字应尽可能低。
事实上，这些函数几乎不应该被使用。
请参见您平台 IP stack 的文档。}
