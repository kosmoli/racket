#lang scribble/doc
@(require "mz.rkt" (for-label racket/port))

@title[#:tag "port-lib"]{更多端口构造器、过程和事件}

@note-lib[racket/port]

@; ----------------------------------------------------------------------

@section{端口字符串和列表转换}
@(define port-eval (make-base-eval))
@examples[#:hidden #:eval port-eval (require racket/port)]

@defproc[(port->list [r (input-port? . -> . any/c) read] [in input-port? (current-input-port)])
         (listof any/c)]{
返回一个列表，其元素通过调用 @racket[r] 到 @racket[in] 上产生，直到它产生 @racket[eof]。

@examples[#:eval port-eval
(define (read-number input-port)
  (define char (read-char input-port))
  (if (eof-object? char)
   char
   (string->number (string char))))
(port->list read-number (open-input-string "12345"))
]}

@defproc[(port->string [in input-port? (current-input-port)]
                       [#:close? close? any/c #f])
         string?]{

从 @racket[in] 读取所有字符并将它们作为字符串返回。
除非 @racket[close?] 为 @racket[#f]，否则输入端口会被关闭。

@examples[#:eval port-eval
(port->string (open-input-string "hello world"))
    ]

@history[#:changed "6.8.0.2" @elem{Added the @racket[#:close?] argument.}]}

@defproc[(port->bytes [in input-port? (current-input-port)]
                      [#:close? close? any/c #f])
         bytes?]{

从 @racket[in] 读取所有字节并将它们作为 @tech{byte string} 返回。
除非 @racket[close?] 为 @racket[#f]，否则输入端口会被关闭。

@examples[#:eval port-eval
(port->bytes (open-input-string "hello world"))
]

@history[#:changed "6.8.0.2" @elem{Added the @racket[#:close?] argument.}]}

@defproc[(port->lines [in input-port? (current-input-port)]
                      [#:line-mode line-mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'any]
                      [#:close? close? any/c #f])
         (listof string?)]{

从 @racket[in] 读取所有字符，将它们分解为行。@racket[line-mode] 参数与 @racket[read-line] 的第二个参数相同，但默认值是 @racket['any] 而不是 @racket['linefeed]。
除非 @racket[close?] 为 @racket[#f]，否则输入端口会被关闭。

@examples[#:eval port-eval
(port->lines
 (open-input-string "line 1\nline 2\n  line 3\nline 4"))
]

@history[#:changed "6.8.0.2" @elem{Added the @racket[#:close?] argument.}]}

@defproc[(port->bytes-lines [in input-port? (current-input-port)]
                            [#:line-mode line-mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'any]
                            [#:close? close? any/c #f])
         (listof bytes?)]{

类似于 @racket[port->lines]，但读取字节并将它们收集为行，类似 @racket[read-bytes-line]。
除非 @racket[close?] 为 @racket[#f]，否则输入端口会被关闭。

@examples[#:eval port-eval
(port->bytes-lines 
 (open-input-string "line 1\nline 2\n  line 3\nline 4"))
]

@history[#:changed "6.8.0.2" @elem{Added the @racket[#:close?] argument.}]}

@defproc[(display-lines [lst list?]
                        [out output-port? (current-output-port)]
                        [#:separator separator any/c #"\n"])
         void?]{

对 @racket[lst] 的每个元素使用 @racket[display] 输出到 @racket[out]，在每个元素后添加 @racket[separator]。}

@defproc[(call-with-output-string [proc (output-port? . -> . any)]) string?]{

使用一个将所有输出累积到字符串中的输出端口调用 @racket[proc]，并返回该字符串。

传递给 @racket[proc] 的端口类似于由 @racket[open-output-string] 创建的端口，除了它通过 @racket[dup-output-port] 进行了包装，使得 @racket[proc] 无法使用 @racket[get-output-string] 访问端口的内容。如果控制跳回 @racket[proc]，端口继续累积新数据，而 @racket[call-with-output-string] 返回旧数据和新累积的数据。}

@defproc[(call-with-output-bytes [proc (output-port? . -> . any)]) bytes?]{

类似于 @racket[call-with-output-string]，但将累积结果作为 @tech{byte string} 而非字符串返回。此外，当 @racket[call-with-output-bytes] 返回时端口的内容会被清空，因此如果控制跳回 @racket[proc] 并第二次返回，则只返回新累积的字节。}

@defproc[(with-output-to-string [proc (-> any)]) string?]{

等价于

@racketblock[(call-with-output-string
              (lambda (p) (parameterize ([current-output-port p])
                            (proc))))]}

@defproc[(with-output-to-bytes [proc (-> any)]) bytes?]{

等价于

@racketblock[(call-with-output-bytes
              (lambda (p) (parameterize ([current-output-port p])
                            (proc))))]}

@defproc[(call-with-input-string [str string?] [proc (input-port? . -> . any)]) any]{

等价于 @racket[(proc (open-input-string str))].}

@defproc[(call-with-input-bytes [bstr bytes?] [proc (input-port? . -> . any)]) any]{

等价于 @racket[(proc (open-input-bytes bstr))].}

@defproc[(with-input-from-string [str string?] [proc (-> any)]) any]{

等价于

@racketblock[(parameterize ([current-input-port (open-input-string str)])
               (proc))]}

@defproc[(with-input-from-bytes [bstr bytes?] [proc (-> any)]) any]{

等价于

@racketblock[(parameterize ([current-input-port (open-input-bytes str)])
               (proc))]}


@; ----------------------------------------------------------------------

@section{创建端口}

@defproc[(input-port-append [close-at-eof? any/c]
                            [in input-port?] ...
                            [#:name name any/c (map object-name in)])
         input-port?]{

接受任意数量的输入端口并返回一个输入端口。从输入端口读取会按顺序从给定的输入端口获取字节（和特殊的非字节值）。如果 @racket[close-at-eof?] 为真，则当从端口遇到文件结束或当结果输入端口关闭时，每个端口都会被关闭。否则，未从返回的输入端口读取的数据在其原始输入端口中仍然可读。

@racket[name] 参数确定返回的输入端口的 @racket[object-name] 报告的名称。

另见 @racket[merge-input]，它在数据可用时交错来自多个输入端口的数据。

@history[#:changed "6.90.0.19" @elem{Added the @racket[name] argument.}]}


@defproc[(make-input-port/read-to-peek 
          [name any/c]
          [read-in (bytes? 
                    . -> . (or/c exact-nonnegative-integer?
                                 eof-object?
                                 procedure?
                                 evt?))]
          [fast-peek (or/c #f
                           (bytes? exact-nonnegative-integer?
                            (bytes? exact-nonnegative-integer?
                             . -> . (or/c exact-nonnegative-integer?
                                          eof-object?
                                          procedure?
                                          evt?
                                          #f))
                            . -> . (or/c exact-nonnegative-integer?
                                         eof-object?
                                         procedure?
                                         evt?
                                         #f)))]
          [close (-> any)]
          [get-location (or/c 
                         (->
                          (values
                           (or/c exact-positive-integer? #f)
                           (or/c exact-nonnegative-integer? #f)
                           (or/c exact-positive-integer? #f)))
                         #f)
                        #f]
          [count-lines! (-> any) void]
          [init-position exact-positive-integer? 1]
          [buffer-mode (or/c (case-> ((or/c 'block 'none) . -> . any)
                                     (-> (or/c 'block 'none #f)))
                             #f)
                       #f]
          [buffering? any/c #f]
          [on-consumed (or/c ((or/c exact-nonnegative-integer? eof-object? 
                                    procedure? evt?) 
                              . -> . any)
                             #f)
                       #f])
         input-port?]{

Similar to @racket[make-input-port], but if the given @racket[read-in]
returns an event, the event's value must be @racket[0].  The resulting
port's peek operation is implemented automatically (in terms of
@racket[read-in]) in a way that can handle special non-byte
values. The progress-event and commit operations are also implemented
automatically. The resulting port is thread-safe, but not kill-safe
(i.e., if a thread is terminated or suspended while using the port,
the port may become damaged).

The @racket[read-in], @racket[close], @racket[get-location],
@racket[count-lines!], @racket[init-position], and
@racket[buffer-mode] procedures are the same as for
@racket[make-input-port].

The @racket[fast-peek] argument can be either @racket[#f] or a
procedure of three arguments: a byte string to receive a peek, a skip
count, and a procedure of two arguments. The @racket[fast-peek]
procedure can either implement the requested peek, or it can dispatch
to its third argument to implement the peek. The @racket[fast-peek] is
not used when a peek request has an associated progress event.

The @racket[buffering?] argument determines whether @racket[read-in]
can be called to read more characters than are immediately demanded by
the user of the new port. If @racket[buffer-mode] is not @racket[#f],
then @racket[buffering?] determines the initial buffer mode, and
@racket[buffering?] is enabled after a buffering change only if the
new mode is @racket['block].

If @racket[on-consumed] is not @racket[#f], it is called when data is
read (or committed) from the port, as opposed to merely peeked. The argument to
@racket[on-consumed] is the result value of the port's reading
procedure, so it can be an integer or any result from
@racket[read-in].}


@defproc[(make-limited-input-port [in input-port?]
                                  [limit exact-nonnegative-integer?]
                                  [close-orig? any/c #t])
         input-port?]{

返回一个端口，其内容从 @racket[in] 获取，但在读取了 @racket[limit] 个字节（和非字节特殊值）后报告文件结束。如果 @racket[close-orig?] 为真，则当返回的端口关闭时原始端口也会被关闭。

字节仅在从返回的端口消费时才从 @racket[in] 消费。特别是，窥视返回的端口会窥视原始端口。

如果在使用结果端口的同时直接使用 @racket[in]，则端口提供的 @racket[limit] 字节不必是原始端口流的连续部分。}



@defproc[(make-pipe-with-specials [limit exact-nonnegative-integer? #f]
                                  [in-name any/c 'pipe]
                                  [out-name any/c 'pipe]) 
         (values input-port? output-port?)]{

返回两个端口：一个输入端口和一个输出端口。这些端口的行为类似于 @racket[make-pipe] 返回的端口，除了它们支持使用 @racket[write-special] 等过程写入和使用 @racket[get-byte-or-special] 等过程读取的非字节值。

@racket[limit] 参数确定管道的最大容量（以字节为单位），但如果在达到 @racket[limit] 之前向管道写入了特殊值，则此限制被禁用。从管道读取特殊值后，限制被重新启用。

可选的 @racket[in-name] 和 @racket[out-name] 参数确定结果端口的名称。}


@defproc[(combine-output [a-out output-port?]
                         [b-out output-port?])
         output-port?]{

接受两个输出端口并返回一个组合了原始端口的新输出端口。写入时，组合端口首先向 @racket[a-out] 写入尽可能多的字节，然后尝试向 @racket[b-out] 写入相同数量的字节。如果不成功，剩余的内容会被缓冲，直到端口平衡后才能进行进一步写入。当每个端口报告就绪时，端口（对于同步目的）就绪。然而，第一个端口在等待第二个端口同步时可能停止就绪，因此无法保证两个端口同时就绪。关闭组合端口是在将所有剩余字节写入 @racket[b-out] 之后完成的。

@history[#:added "7.7.0.10"]}

@defproc[(merge-input [a-in input-port?]
                      [b-in input-port?]
                      [buffer-limit (or/c exact-nonnegative-integer? #f) 4096])
         input-port?]{

接受两个输入端口并返回一个新的输入端口。新端口合并来自两个原始端口的数据，因此当数据可从任一原始端口获得时，就可以从新端口读取。来自原始端口的数据被交错。当从原始端口读取到文件结束时，它不再向新端口贡献字符。在从两个原始端口都读取到文件结束后，新端口返回文件结束。关闭合并的端口不会关闭原始端口。

可选的 @racket[buffer-limit] 参数限制从 @racket[a-in] 和 @racket[b-in] 缓冲的字节数，以便合并过程不会任意超出合并数据的消费速率。@racket[#f] 值禁用限制。与 @racket[make-pipe-with-specials] 一样，当某个输入端口在达到限制之前产生特殊值时，@racket[buffer-limit] 不适用。

另见 @racket[input-port-append]，它连接输入流而不是交错它们。}


@defproc[(open-output-nowhere [name any/c 'nowhere] [special-ok? any/c #t])
         output-port?]{
@index*['("discard-output" "null-output" "null-output-port" "dev-null"
          "/dev/null")
	'("Opening a null output port")]{
	
创建} 并返回一个丢弃所有发送给它的输出（不阻塞）的输出端口。@racket[name] 参数用作端口的名称。如果 @racket[special-ok?] 参数为真，则结果端口支持 @racket[write-special]，否则不支持。}


@defproc[(open-input-nowhere [name any/c 'nowhere])
         input-port?]{
@index*['("null-input" "null-input-port" "dev-null"
          "/dev/null")
	'("Opening a null input port")]{

创建} 并返回一个始终返回 @racket[eof]（不阻塞）的输入端口。@racket[name] 参数用作端口的名称。

@history[#:added "8.15.0.2"]}


@defproc[(peeking-input-port [in input-port?]
                             [name any/c (object-name in)]
                             [skip exact-nonnegative-integer? 0]
                             [#:init-position init-position exact-positive-integer? 1])
         input-port?]{

返回一个输入端口，其内容通过窥视 @racket[in] 来确定。换句话说，结果端口包含一个内部跳过计数，端口的每次读取使用内部跳过计数窥视 @racket[in]，然后根据成功窥视的数据量递增跳过计数。

可选的 @racket[name] 参数是结果端口的名称。@racket[skip] 参数是端口的初始跳过计数，默认为 @racket[0]。

结果端口的初始位置（由 @racket[file-position] 报告）是 @racket[(- init-position 1)]，无论 @racket[in] 的位置如何。

结果端口支持缓冲，@racket['block] 缓冲模式允许端口窥视 @racket[in] 的内容超出请求的范围。结果端口的初始缓冲模式是 @racket['block]，除非 @racket[in] 支持缓冲模式且其模式初始为 @racket['none]（即，当 @racket[in] 支持缓冲时，初始缓冲模式取自 @racket[in]）。如果 @racket[in] 支持缓冲，通过 @racket[file-stream-buffer-mode] 调整结果端口的缓冲模式也会调整 @racket[in] 的缓冲模式。

例如，当你从窥视端口读取时，你看到的结果与从原始端口读取时相同：

@examples[#:eval port-eval
(define an-original-port (open-input-string "123456789"))
(define a-peeking-port (peeking-input-port an-original-port))
(file-stream-buffer-mode a-peeking-port 'none)
(read-string 3 a-peeking-port)
(read-string 3 an-original-port)]

注意，从原始端口的读取对窥视端口是不可见的，窥视端口维护自己独立的内部计数器，因此在两个端口上交错读取可能会产生令人困惑的结果。继续前面的例子，如果我们从窥视端口再读取三个字符，我们最终会跳过端口中的 @litchar{456}（但这仅仅是因为我们在上面禁用了缓冲）：

@examples[#:eval port-eval
(read-string 3 a-peeking-port)
]

如果我们没有改变 @racket[a-peeking-port] 的缓冲模式，最后一次 @racket[read-string] 很可能会因为之前缓冲了 @racket[an-original-port] 的字节而产生 @racket["456"]。


@history[#:changed "6.1.0.3" @elem{Enabled buffering and buffer-mode
                                   adjustments via @racket[file-stream-buffer-mode],
                                   and set the port's initial buffer mode to that of
                                   @racket[in].}]}



@defproc[(reencode-input-port [in input-port?]
                              [encoding string?]
                              [error-bytes (or/c #f bytes?) #f]
                              [close? any/c #f]
                              [name any/c (object-name in)]
                              [convert-newlines? any/c #f]
                              [enc-error (string? input-port? . -> . any) 
                                         (lambda (msg port) (error ...))])
         input-port?]{

产生一个输入端口，从 @racket[in] 获取字节，但使用 @racket[(bytes-open-converter encoding-str
"UTF-8")] 转换字节流。此外，如果 @racket[convert-newlines?] 为真，则解码后对应于 @racket["\r\n"]、@racket["\r\x85"]、@racket["\r"]、@racket["\x85"] 和 @racket["\u2028"] 的 UTF-8 编码的序列都会转换为 @racket["\n"] 的 UTF-8 编码。
 
如果提供了 @racket[error-bytes] 且不为 @racket[#f]，则给定的字节序列用于替代 @racket[in] 中触发转换错误的字节。否则，如果遇到转换错误，则调用 @racket[enc-error]，它必须引发异常。

如果 @racket[close?] 为真，则关闭结果输入端口也会关闭 @racket[in]。@racket[name] 参数用作结果输入端口的名称。

在非缓冲模式下，结果输入端口仅在满足请求所需时才尝试从 @racket[in] 获取字节。为此，输入端口假设至少需要读取 @math{n} 个字节才能满足对 @math{n} 个字节的请求。（即使端口已经获取了一些字节，只要这些字节形成不完整的编码序列，这也是成立的。）}


@defproc[(reencode-output-port [out output-port?]
                               [encoding string?]
                               [error-bytes (or/c #f bytes?) #f]
                               [close? any/c #f]
                               [name any/c (object-name out)]
                               [newline-bytes (or/c #f bytes?) #f]
                               [enc-error (string? output-port? . -> . any) 
                                          (lambda (msg port) (error ...))])
         output-port?]{

产生一个输出端口，将字节导向 @racket[out]，但使用 @racket[(bytes-open-converter "UTF-8"
encoding-str)] 转换其字节流。此外，如果 @racket[newline-bytes] 不为 @racket[#f]，则写入端口的是 @racket["\n"] 的 UTF-8 编码的字节首先会被转换为 @racket[newline-bytes]（在应用从 UTF-8 到 @racket[encoding-str] 的转换之前）。
 
如果提供了 @racket[error-bytes] 且不为 @racket[#f]，则给定的字节序列用于替代已发送到输出端口并触发转换错误的字节。否则，调用 @racket[enc-error]，它必须引发异常。

如果 @racket[close?] 为真，则关闭结果输出端口也会关闭 @racket[out]。@racket[name] 参数用作结果输出端口的名称。

结果端口支持缓冲，初始缓冲模式是 @racket[(or (file-stream-buffer-mode out) 'block)]。在 @racket['block] 模式下，端口的缓冲区仅在满时或显式请求刷新时才刷新。在 @racket['line] 模式下，每当换行或回车字节写入端口时缓冲区被刷新。在 @racket['none] 模式下，端口的缓冲区在每次写入后刷新。对于 @racket['line] 或 @racket['none] 的隐式刷新，当字节是不完整编码序列的一部分时，它们会留在缓冲区中。

结果输出端口不支持原子写入。如果最近写入的字节形成不完整的编码序列，对输出端口的显式刷新或特殊写入可能会挂起。

当端口被缓冲时，会向 @tech{current plumber} 注册一个 @tech{flush callback} 来刷新缓冲区。}


@defproc[(dup-input-port [in input-port?]
                         [close? any/c #f])
         input-port?]{

返回一个直接从 @racket[in] 获取数据的输入端口。仅当 @racket[close?] 为 @racket[#t] 时，关闭结果端口才会关闭 @racket[in]。

新端口使用 @racket[in] 的 @tech{port read handler} 初始化，但在结果端口上设置 handler 不会影响直接从 @racket[in] 读取。}


@defproc[(dup-output-port [out output-port?]
                          [close? any/c #f])
         output-port?]{

返回一个将数据直接传播到 @racket[out] 的输出端口。仅当 @racket[close?] 为 @racket[#t] 时，关闭结果端口才会关闭 @racket[out]。

新端口使用 @racket[out] 的 @tech{port display handler} 和 @tech{port write handler} 初始化，但在结果端口上设置 handler 不会影响直接写入 @racket[out]。}



@defproc[(relocate-input-port [in input-port?]
                              [line (or/c exact-positive-integer? #f)]
                              [column (or/c exact-nonnegative-integer? #f)]
                              [position exact-positive-integer?]
                              [close? any/c #t]
                              [#:name name (object-name in)])
         input-port?]{

产生一个等效于 @racket[in] 的输入端口，除了它报告位置信息的方式（可能还有其名称）。结果端口的内容从 @racket[in] 的剩余内容开始，并从给定的行、列和位置开始。行或列为 @racket[#f] 意味着行和列将始终报告为 @racket[#f]。

@racket[line] 和 @racket[column] 值仅在为 @racket[in] 和结果端口启用了行计数时才使用，通常通过 @racket[port-count-lines!] 实现。@racket[column] 值确定第一行（即编号为 @racket[line] 的行）的列，后续行从第 @racket[0] 列开始。即使未启用行计数，给定的 @racket[position] 也会被使用。

当结果端口启用行计数时，从 @racket[in] 而不是结果端口读取会增加结果端口的位置报告。否则，当从 @racket[in] 读取数据时，结果端口的位置不会递增。

如果 @racket[close?] 为真，则关闭结果端口也会关闭 @racket[in]。如果 @racket[close?] 为 @racket[#f]，则关闭结果端口不会关闭 @racket[in]。

@racket[name] 参数用作结果端口的名称；默认值保持与 @racket[in] 相同的名称。
}


@defproc[(relocate-output-port [out output-port?]
                               [line (or/c exact-positive-integer? #f)]
                               [column (or/c exact-nonnegative-integer? #f)]
                               [position exact-positive-integer?]
                               [close? any/c #t]
                               [#:name name (object-name out)])
         output-port?]{

类似于 @racket[relocate-input-port]，但用于输出端口。}


@defproc[(transplant-input-port [in input-port?]
                                [get-location (or/c 
                                               (->
                                                (values
                                                 (or/c exact-positive-integer? #f)
                                                 (or/c exact-nonnegative-integer? #f)
                                                 (or/c exact-positive-integer? #f)))
                                               #f)]
                                [init-pos exact-positive-integer?]
                                [close? any/c #t]
                                [count-lines! (-> any) void]
                                [#:name name (object-name in)])
          input-port?]{

类似于 @racket[relocate-input-port]，但可以通过 @racket[get-location] 产生任意位置信息（当启用行计数时），其使用方式与 @racket[make-input-port] 相同。如果 @racket[get-location] 为 @racket[#f]，则端口以通常方式从 @racket[init-pos] 开始计算行数，与 @racket[in] 报告的位置无关。

如果提供了 @racket[count-lines!]，当结果端口启用行计数时它会被调用。默认为 @racket[void]。}

@defproc[(transplant-output-port [out output-port?]
                                 [get-location (or/c 
                                                (->
                                                 (values
                                                  (or/c exact-positive-integer? #f)
                                                  (or/c exact-nonnegative-integer? #f)
                                                  (or/c exact-positive-integer? #f)))
                                                #f)]
                                 [init-pos exact-positive-integer?]
                                 [close? any/c #t]
                                 [count-lines! (-> any) void]
                                 [#:name name (object-name out)])
          output-port?]{

类似于 @racket[transplant-input-port]，但用于输出端口。}


@defproc[(filter-read-input-port [in input-port?]
                                 [read-wrap (bytes? (or/c exact-nonnegative-integer?
                                                          eof-object?
                                                          procedure?
                                                          evt?)
                                                    . -> .
                                                    (or/c exact-nonnegative-integer?
                                                          eof-object?
                                                          procedure?
                                                          evt?))]
                                 [peek-wrap (bytes? exact-nonnegative-integer? (or/c evt? #f)
                                                    (or/c exact-nonnegative-integer?
                                                     eof-object?
                                                     procedure?
                                                     evt?
                                                     #f)
                                             . -> . (or/c exact-nonnegative-integer?
                                                     eof-object?
                                                     procedure?
                                                     evt?
                                                     #f))]
                                 [close? any/c #t])
         input-port?]{

创建一个从 @racket[in] 获取数据的端口，但端口的读取和窥视过程（在 @racket[make-input-port] 的意义上）的每个结果都经过 @racket[read-wrap] 和 @racket[peek-wrap] 的过滤。过滤过程在每次调用时接收 @racket[in] 上读取和窥视过程的参数和结果。

如果 @racket[close?] 为真，则关闭结果端口也会关闭 @racket[in]。}


@defproc[(special-filter-input-port [in input-port?]
                                    [proc (procedure? bytes? . -> . (or/c exact-nonnegative-integer? 
                                                                          eof-object?
                                                                          procedure? 
                                                                          evt?))]
                                    [close? any/c #t])
          input-port?]{

产生一个等效于 @racket[in] 的输入端口，除了当 @racket[in] 产生一个访问特殊值的过程时，@racket[proc] 被应用于该过程，以允许将特殊值替换为替代值。@racket[proc] 被调用时传入特殊值过程和传递给端口读取或窥视函数的字节串（参见 @racket[make-input-port]），结果用作读取或窥视函数的结果。@racket[proc] 可以修改字节串以用字节替换特殊值，但字节串仅保证至少包含一个字节。

如果 @racket[close?] 为真，则关闭结果输入端口也会关闭 @racket[in]。}

@; ----------------------------------------------------------------------

@section{端口事件}


@defproc[(eof-evt [in input-port?]) evt?]{

返回一个 @tech{synchronizable event}，当 @racket[in] 产生 @racket[eof] 时它准备就绪。如果 @racket[in] 产生一个流中间的 @racket[eof]，则该 @racket[eof] 仅在同步中选择了该事件时才会被消费。

如果在同步尝试期间尝试从 @racket[in] 读取引发了异常，则该异常可能在同步尝试期间被报告，但如果同一同步中的另一个事件被选中或另一个事件首先引发异常，则该异常将被静默丢弃。

@history[#:changed "7.5.0.3" @elem{Changed handling of read errors so
                                   they are propagated to a synchronization attempt,
                                   instead of treated as unhandled errors in a
                                   background thread.}]}


@defproc[(read-bytes-evt [k exact-nonnegative-integer?] [in input-port?]) 
         evt?]{

返回一个 @tech{synchronizable event}，当可以从 @racket[in] 读取 @racket[k] 个字节或 @racket[in] 中遇到文件结束时它准备就绪。如果 @racket[k] 为 @racket[0]，则事件立即就绪，结果为 @racket[""]。对于非零 @racket[k]，如果在文件结束之前没有字节可用，则事件的结果为 @racket[eof]。否则，事件的结果是一个最多 @racket[k] 个字节的字节串，其中包含文件结束之前可用的尽可能多的字节（最多 @racket[k]）。（仅当遇到文件结束时，结果才是少于 @racket[k] 个字节的字节串。）

字节从端口读取当且仅当事件在同步中被选中，并且返回的字节始终表示端口流中连续的字节。

该事件可以被同步多次——甚至并发地——并且每次同步对应一个不同的读取请求。

@racket[in] 必须支持进度事件，并且在读取尝试期间不能产生特殊的非字节值。

尝试从 @racket[in] 读取时的异常以与 @racket[eof-evt] 相同的方式处理。}


@defproc[(read-bytes!-evt [bstr (and/c bytes? (not/c immutable?))]
                          [in input-port?])
         evt?]{

类似于 @racket[read-bytes-evt]，但读取的字节被放入 @racket[bstr] 中，要读取的字节数对应于 @racket[(bytes-length bstr)]。事件的结果是 @racket[eof] 或读取的字节数。

The @racket[bstr] may be mutated any time after the first
synchronization attempt on the event and until either the event is
selected, a non-@racket[#f] @racket[progress-evt] is ready, or the
current @tech{custodian} (at the time of synchronization) is shut
down. Note that there is no time bound otherwise on when @racket[bstr]
might be mutated if the event is not selected by a synchronzation;
nevertheless, multiple synchronization attempts can use the same
result from @racket[read-bytes!-evt] as long as there is no
intervening read on @racket[in] until one of the synchronization
attempts selects the event.

尝试从 @racket[in] 读取时的异常以与 @racket[eof-evt] 相同的方式处理。}


@defproc[(read-bytes-avail!-evt [bstr (and/c bytes? (not/c immutable?))] [in input-port?]) 
         evt?]{

Like @racket[read-bytes!-evt], except that the event reads only as
many bytes as are immediately available, after at least one byte or
one @racket[eof] becomes available.}


@defproc[(read-string-evt [k exact-nonnegative-integer?] [in input-port?]) 
         evt?]{

类似于 @racket[read-bytes-evt]，但用于字符串而非字节串。}


@defproc[(read-string!-evt [str (and/c string? (not/c immutable?))]
                           [in input-port?]) 
         evt?]{

类似于 @racket[read-bytes!-evt]，但用于字符串而非字节串。}


@defproc[(read-line-evt [in input-port?]
                        [mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'linefeed])
         evt?]{

返回一个 @tech{synchronizable event}，当可以从 @racket[in] 读取一行字符或文件结束时它准备就绪。@racket[mode] 的含义与 @racket[read-line] 相同。事件结果是读取的字符行（不包括行分隔符）。

一行从端口读取当且仅当事件在同步中被选中，并且返回的行始终表示端口流中连续的字节。

尝试从 @racket[in] 读取时的异常以与 @racket[eof-evt] 相同的方式处理。}


@defproc[(read-bytes-line-evt [in input-port?]
                              [mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'linefeed])
         evt?]{
 
类似于 @racket[read-line-evt]，但返回字节串而非字符串。}

@defproc*[([(peek-bytes-evt [k exact-nonnegative-integer?] [skip exact-nonnegative-integer?]
                            [progress-evt (or/c progress-evt? #f)] [in input-port?]) evt?]
           [(peek-bytes!-evt [bstr (and/c bytes? (not/c immutable?))] [skip exact-nonnegative-integer?]
                             [progress-evt (or/c progress-evt? #f)] [in input-port?]) evt?]
           [(peek-bytes-avail!-evt [bstr (and/c bytes? (not/c immutable?))] [skip exact-nonnegative-integer?]
                                   [progress-evt (or/c progress-evt? #f)] [in input-port?]) evt?]
           [(peek-string-evt [k exact-nonnegative-integer?] [skip exact-nonnegative-integer?]
                             [progress-evt (or/c progress-evt? #f)] [in input-port?]) evt?]
           [(peek-string!-evt [str (and/c string? (not/c immutable?))] [skip exact-nonnegative-integer?]
                              [progress-evt (or/c progress-evt? #f)] [in input-port?]) evt?])]{

类似于 @racket[read-bytes-evt] 等函数，但用于窥视。@racket[skip] 参数表示要跳过的字节数，@racket[progress-evt] 表示一个有效取消窥视的事件（使得该事件永远不会就绪）。@racket[progress-evt] 参数可以是 @racket[#f]，此时事件永远不会被取消。}


@defproc[(regexp-match-evt [pattern (or/c string? bytes? regexp? byte-regexp?)]
                           [in input-port?]) any]{

返回一个 @tech{synchronizable event}，当 @racket[pattern] 匹配来自 @racket[in] 的字节/字符流时它准备就绪；另见 @racket[regexp-match]。事件的值是匹配的结果，形式与 @racket[regexp-match] 的结果相同。

如果 @racket[pattern] 不要求流起始匹配，则在同步中选择了事件时，为完成匹配而跳过的字节会被读取并丢弃。

字节从端口读取当且仅当事件在同步中被选中，并且返回的匹配始终表示端口流中连续的字节。如果端口尚未可用的字节可能对匹配有贡献，事件就不会就绪。类似地，如果 @racket[pattern] 以流起始 @litchar{^} 开头且 @racket[pattern] 最初不匹配，则直到从端口读取了字节，事件才能就绪。

该事件可以被同步多次——甚至并发地——并且每次同步对应一个不同的匹配请求。

@racket[in] 端口必须支持进度事件。如果 @racket[in] 在匹配尝试期间返回特殊的非字节值，则它被视为 @racket[eof]。

尝试从 @racket[in] 读取时的异常以与 @racket[eof-evt] 相同的方式处理。}

@; ----------------------------------------------------------------------

@section{复制流}

@defproc[(convert-stream [from-encoding string?]
                         [in input-port?]
                         [to-encoding string?]
                         [out output-port?])
         void?]{

从 @racket[in] 读取数据，使用 @racket[(bytes-open-converter from-encoding
to-encoding)] 转换它，并将转换后的字节写入 @racket[out]。@racket[convert-stream] 过程在 @racket[in] 中达到 @racket[eof] 后返回。

如果打开转换器失败，则 @exnraise[exn:fail]。同样，如果在从 @racket[in] 读取时的任何时间点发生转换错误，则 @exnraise[exn:fail]。}


@defproc[(copy-port [in input-port?] [out output-port?] ...+) void?]{

从 @racket[in] 读取数据并将其写回到 @racket[out]，当 @racket[in] 产生 @racket[eof] 时返回。复制是高效的，且没有显著的缓冲延迟（即，@racket[in] 上可用的字节会立即传输到 @racket[out]，即使将来对 @racket[in] 的读取必须阻塞）。如果 @racket[in] 产生特殊的非字节值，它使用 @racket[write-special] 传输到 @racket[out]。

此函数通常从"后台"线程调用，以连续地将数据从一个流泵送到另一个流。

如果提供了多个 @racket[out]，来自 @racket[in] 的数据会写入每个 @racket[out]。不同的 @racket[out] 会相互阻塞输出，因为从 @racket[in] 读取的每个数据块在移动到下一个 @racket[out] 之前会完全写入一个 @racket[out]。@racket[out] 按提供的顺序写入，因此非阻塞端口（例如文件输出端口）应放在参数列表的前面。}

@close-eval[port-eval]
