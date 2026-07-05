#lang scribble/doc
@(require "mz.rkt")

@title{字节与字符串输出}

@defproc[(write-char [char char?] [out output-port? (current-output-port)])
         void?]{

向 @racket[out] 写入单个字符；更准确地说，是将 @racket[char] 的 UTF-8 编码字节写入
@racket[out]。}

@defproc[(write-byte [byte byte?] [out output-port? (current-output-port)])
         void?]{

向 @racket[out] 写入单个字节。}

@defproc[(newline [out output-port? (current-output-port)])
         void?]{

与 @racket[(write-char #\newline out)] 相同。}

@defproc[(write-string [str string?]
                       [out output-port? (current-output-port)]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos exact-nonnegative-integer? (string-length str)])
         exact-nonnegative-integer?]{

将 @racket[str] 中的字符写入 @racket[out]，从索引 @racket[start-pos]（包含）开始，
到 @racket[end-pos]（不包含）结束。与 @racket[substring] 类似，如果 @racket[start-pos]
或 @racket[end-pos] 超出 @racket[str] 的范围，则 @exnraise[exn:fail:contract]。

结果是写入 @racket[out] 的字符数，始终为 @racket[(- end-pos start-pos)]。

如果 @racket[str] 是可变的，在 @racket[write-string] 返回后发生的突变不会影响已写入
@racket[out] 的字符。（这种对突变的独立性不是 @racket[write-string] 的特殊属性，
而是 output function 普遍具备的特性。）}


@defproc[(write-bytes [bstr bytes?]
                      [out output-port? (current-output-port)]
                      [start-pos exact-nonnegative-integer? 0]
                      [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         exact-nonnegative-integer?]{

类似于 @racket[write-string]，但写入的是字节而不是字符。}

@defproc[(write-bytes-avail [bstr bytes?]
                            [out output-port? (current-output-port)]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         exact-nonnegative-integer?]{

类似于 @racket[write-bytes]，但在能够立即刷新的字节写入完成后即返回，而不阻塞。
仅在没有字节可以立即刷新时才会阻塞。结果是写入并刷新到 @racket[out] 的字节数；
如果 @racket[start-pos] 与 @racket[end-pos] 相同，则结果可能为 @racket[0]（表示
成功刷新了任何缓冲数据），否则结果在 @racket[1] 到 @racket[(- end-pos
start-pos)] 之间（包含两端）。

@racket[write-bytes-avail] procedure 永远不会丢弃字节；如果 @racket[write-bytes-avail]
成功写入了一些字节然后遇到错误，它会抑制错误并返回已写入的字节数。（错误将在未来的写入中被触发。）如果在写入任何字节之前遇到错误，则会引发异常。}

@defproc[(write-bytes-avail* [bstr bytes?]
                             [out output-port? (current-output-port)]
                             [start-pos exact-nonnegative-integer? 0]
                             [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? #f)]{

类似于 @racket[write-bytes-avail]，但从不阻塞。如果 port 包含无法立即写入的缓冲数据，
则返回 @racket[#f]；如果 port 的内部缓冲区（如有）已刷新但没有额外的字节可以立即写入，
则返回 @racket[0]。}

@defproc[(write-bytes-avail/enable-break [bstr bytes?]
                                         [out output-port? (current-output-port)]
                                         [start-pos exact-nonnegative-integer? 0]
                                         [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         exact-nonnegative-integer?]{

类似于 @racket[write-bytes-avail]，但在写入期间启用了 break。此 procedure
提供了关于写入与 break 交互的保证：如果在调用 @racket[write-bytes-avail/enable-break]
时 break 是禁用的，并且如果由于调用而引发了 @racket[exn:break] 异常，那么不会有
任何字节被写入 @racket[out]。另见 @secref["breakhandler"]。}

@defproc[(write-special [v any/c] [out output-port? (current-output-port)]) boolean?]{

如果 port 支持特殊写入，则直接将 @racket[v] 写入 @racket[out]；如果 port 不支持
特殊写入，则引发 @racket[exn:fail:contract]。结果始终为 @racket[#t]，表示写入成功。}

@defproc[(write-special-avail* [v any/c] [out output-port? (current-output-port)]) boolean?]{

类似于 @racket[write-special]，但不会阻塞。如果 @racket[v] 无法立即写入，
则返回 @racket[#f] 且不写入 @racket[v]；否则返回 @racket[#t] 并写入 @racket[v]。}

@defproc[(write-bytes-avail-evt [bstr bytes?]
                                [out output-port? (current-output-port)]
                                [start-pos exact-nonnegative-integer? 0]
                                [end-pos exact-nonnegative-integer? (bytes-length bstr)]) 
         evt?]{

类似于 @racket[write-bytes-avail]，但不是立即写入字节，而是返回一个 synchronizable
event（见 @racket{secref["sync"]}）。@racket[out] 必须支持原子写入，由
@racket[port-writes-atomic?] 指示。

对该对象的同步操作会启动从 @racket[bstr] 的写入，当字节被（无缓冲地）写入 port 时，
event 变为就绪状态。如果 @racket[start-pos] 和 @racket[end-pos] 相同，则当 port
的内部缓冲区（如有）被刷新时，同步结果为 @racket[0]；否则结果为正 exact integer。
如果在同步中未选择该 event，则不会有字节被写入 @racket[out]。}

@defproc[(write-special-evt [v any/c] [out output-port? (current-output-port)]) evt?]{

类似于 @racket[write-special]，但不是立即写入特殊值，而是返回一个 synchronizable
event（见 @secref["sync"]）。@racket[out] 必须支持原子写入，由
@racket[port-writes-atomic?] 指示。

对该对象的同步操作会启动特殊值的写入，当值被（无缓冲地）写入 port 时，event
变为就绪状态。如果在同步中未选择该 event，则不会有值被写入 @racket[out]。}

@defproc[(port-writes-atomic? [out output-port?]) boolean?]{

如果 @racket[write-bytes-avail/enable-break] 可以为 @racket[out] 提供异或保证
（写入或 break，但不会同时发生），并且该 port 可以与 @racket[write-bytes-avail-evt]
等 procedure 一起使用，则返回 @racket[#t]。Racket 的 file-stream port、pipe、
string port 和 TCP port 都支持原子写入；使用 @racket[make-output-port] 创建的 port
（见 @secref["customport"]）可能支持原子写入。}

@defproc[(port-writes-special? [out output-port?]) boolean?]{

如果 @racket[write-special] 等 procedure 可以将任意值写入 port，则返回 @racket[#t]。
Racket 的 file-stream port、pipe、string port 和 TCP port 都会拒绝特殊值，但使用
@racket[make-output-port] 创建的 port（见 @secref["customport"]）可能支持它们。}
