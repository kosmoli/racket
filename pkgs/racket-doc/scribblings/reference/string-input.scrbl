#lang scribble/doc
@(require "mz.rkt")

@(define si-eval (make-base-eval))


@title{Byte and String Input}

@defproc[(read-char [in input-port? (current-input-port)]) 
         (or/c char? eof-object?)]{

从 @racket[in] 读取单个字符——可能涉及读取若干字节以进行 UTF-8 解码（参见
@secref["ports"]）；读取/回看最少数量的字节以完成解码。如果在文件结束前无可用的字节，
则返回 @racket[eof]。}

@examples[#:eval si-eval
(let ([ip (open-input-string "S2")])
  (print (read-char ip)) 
  (newline)
  (print (read-char ip))
  (newline)
  (print (read-char ip)))

(let ([ip (open-input-bytes #"\316\273")])
  @code:comment{The byte string contains UTF-8-encoded content:}
  (print (read-char ip)))
]


@defproc[(read-byte [in input-port? (current-input-port)]) 
         (or/c byte? eof-object?)]{

从 @racket[in] 读取单个字节。如果在文件结束前无可用的字节，则返回 @racket[eof]。}


@examples[#:eval si-eval
(let ([ip (open-input-string "a")])
  @code:comment{The two values in the following list should be the same.}
  (list (read-byte ip) (char->integer #\a)))

(let ([ip (open-input-string (string #\u03bb))])
  @code:comment{This string has a two byte-encoding.}
  (list (read-byte ip) (read-byte ip) (read-byte ip)))
]


@defproc[(read-line [in input-port? (current-input-port)]
                    [mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'linefeed])
         (or/c string? eof-object?)]{

返回包含 @racket[in] 中下一行字节的字符串。

从 @racket[in] 持续读取字符直到遇到行分隔符或文件结束。行分隔符不包含在结果
字符串中（但会从端口流中移除）。如果在遇到文件结束前未读取任何字符，则返回 @racket[eof]。

@racket[mode] 参数决定行分隔符。必须是以下符号之一：

 @itemize[

  @item{@indexed-racket['linefeed] 在换行字符（linefeed）处换行。}

  @item{@indexed-racket['return] 在回车字符（return）处换行。}

  @item{@indexed-racket['return-linefeed] 在回车-换行组合处换行。
  若回车字符后未紧跟换行字符，则回车字符会包含在结果字符串中；
  类似地，前面没有回车的换行字符也会被包含在结果字符串中。}

  @item{@indexed-racket['any] 在回车字符、换行字符或回车-换行组合处均可换行。
  若回车字符后紧跟换行字符，则两者被视为一个组合。}

  @item{@indexed-racket['any-one] 在回车字符或换行字符处换行，但不识别
  回车-换行组合。}

]

回车和换行字符的检测是在以文本模式读取文件时自动执行的转换之后进行的。
例如，在 Windows 上以文本模式读取文件时会自动将回车-换行组合转换为换行字符。
因此，当文件以文本模式打开时，@racket['linefeed] 通常是 @racket[read-line] 的合适模式。}

@examples[#:eval si-eval
(let ([ip (open-input-string "x\ny\n")])
  (read-line ip))

(let ([ip (open-input-string "x\ny\n")])
  (read-line ip 'return))

(let ([ip (open-input-string "x\ry\r")])
  (read-line ip 'return))

(let ([ip (open-input-string "x\r\ny\r\n")])
  (read-line ip 'return-linefeed))

(let ([ip (open-input-string "x\r\ny\nz")])
  (list (read-line ip 'any) (read-line ip 'any)))

(let ([ip (open-input-string "x\r\ny\nz")])
  (list (read-line ip 'any-one) (read-line ip 'any-one)))
]


@defproc[(read-bytes-line [in input-port? (current-input-port)] 
                    [mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'linefeed])
         (or/c bytes? eof-object?)]{
类似于 @racket[read-line]，但读取的是字节，返回字节字符串。}

@defproc[(read-string [amt exact-nonnegative-integer?]
                      [in input-port? (current-input-port)])
         (or/c string? eof-object?)]{

@margin-note{若想将整个端口读取为字符串，请使用 @racket[port->string]。}

返回包含 @racket[in] 中接下来 @racket[amt] 个字符的字符串。

若 @racket[amt] 为 @racket[0]，则返回空字符串。否则，若在遇到文件结束前可用的字符数
少于 @racket[amt]，则返回的字符串仅包含文件结束前的那些字符；
也就是说，返回字符串的长度将小于 @racket[amt]。（读取输入时会分配一个大小为 @racket[amt] 的
临时字符串，即使结果的字符数少于 @racket[amt]。）若在文件结束前无可用的字符，
则返回 @racket[eof]。

若读取过程中发生错误，部分字符可能丢失；也就是说，若 @racket[read-string]
在遇到错误前成功读取了一些字符，这些字符将被丢弃。}

@examples[#:eval si-eval
(let ([ip (open-input-string "supercalifragilisticexpialidocious")])
  (read-string 5 ip))
]

@defproc[(read-bytes [amt exact-nonnegative-integer?]
                     [in input-port? (current-input-port)])
         (or/c bytes? eof-object?)]{
@margin-note{若想将整个端口读取为字节，请使用 @racket[port->bytes]。}
类似于 @racket[read-string]，但读取的是字节，返回字节字符串。}

@examples[#:eval si-eval
(let ([ip (open-input-bytes 
                  (bytes 6 
                         115 101 99 114 101
                         116))])
  (define length (read-byte ip))
  (bytes->string/utf-8 (read-bytes length ip)))
]

@defproc[(read-string! [str (and/c string? (not/c immutable?))]
                       [in input-port? (current-input-port)]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos exact-nonnegative-integer? (string-length str)])
         (or/c exact-nonnegative-integer? eof-object?)]{

像 @racket[read-string] 一样从 @racket[in] 读取字符，但将字符放入 @racket[str] 中，
从索引 @racket[start-pos]（包含）开始到 @racket[end-pos]（不包含）。与 @racket[substring] 类似，
若 @racket[start-pos] 或 @racket[end-pos] 超出 @racket[str] 的范围，则 @exnraise[exn:fail:contract]。

若 @racket[start-pos] 与 @racket[end-pos] 之差为 @racket[0]，则返回 @racket[0]，
@racket[str] 不被修改。 若在文件结束前无可用的字节，则返回 @racket[eof]。 否则，返回值为读取的字符数。 If @math{m} characters are read and
@math{m<@racket[end-pos]-@racket[start-pos]}, then @racket[str] is
not modified at indices @math{@racket[start-pos]+m} through
@racket[end-pos].}

@examples[#:eval si-eval
(let ([buffer (make-string 10 #\_)]
      [ip (open-input-string "cketRa")])
  (printf "~s\n" buffer)
  (read-string! buffer ip 2 6)
  (printf "~s\n" buffer)
  (read-string! buffer ip 0 2)
  (printf "~s\n" buffer))
]

@defproc[(read-bytes! [bstr bytes?]
                      [in input-port? (current-input-port)]
                      [start-pos exact-nonnegative-integer? 0]
                      [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? eof-object?)]{
类似于 @racket[read-string!]，但读取字节，放入字节字符串中，并返回读取的字节数。

@examples[
(let ([buffer (make-bytes 10 (char->integer #\_))]
      [ip (open-input-string "cketRa")])
  (printf "~s\n" buffer)
  (read-bytes! buffer ip 2 6)
  (printf "~s\n" buffer)
  (read-bytes! buffer ip 0 2)
  (printf "~s\n" buffer))
]
}

@defproc[(read-bytes-avail! [bstr bytes?]
                            [in input-port? (current-input-port)]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? eof-object? procedure?)]{

类似于 @racket[read-bytes!]，但在读取立即可用的字节后不阻塞而直接返回，并且可能
为了「special」结果返回一个过程。@racket[read-bytes-avail!] 过程仅在尚无可用字节（或特殊值）时才会阻塞。
与 @racket[read-bytes!] 不同，@racket[read-bytes-avail!] 从不丢弃字节；
若 @racket[read-bytes-avail!] 成功读取了若干字节后遇到错误，则会抑制该错误
（大致将其视为文件结束处理）并返回已读取的字节。（该错误将在后续读取时触发。）
若在读取任何字节之前遇到错误，则引发异常。

当 @racket[in] 产生特殊值时（如 @secref["customport"] 中所述），结果是一个接受四个参数的过程。
这四个参数对应于端口内特殊值的位置（如 @secref["customport"] 中所述）。
若该过程被以有效参数调用超过一次，则 @exnraise[exn:fail:contract]。
若 @racket[read-bytes-avail!] 返回一个产生特殊值的过程，则它不会向 @racket[bstr] 中放入字符。
同样地，@racket[read-bytes-avail!] 仅将端口流中特殊值出现之前可用的字节放入 @racket[bstr] 中。}

@defproc[(read-bytes-avail!* [bstr bytes?]
                             [in input-port? (current-input-port)]
                             [start-pos exact-nonnegative-integer? 0]
                             [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? eof-object? procedure?)]{

类似于 @racket[read-bytes-avail!]，但在无可读取的字节（或特殊值）且未到达文件结束时，
立即返回 @racket[0]。}

@defproc[(read-bytes-avail!/enable-break [bstr bytes?]
                                         [in input-port? (current-input-port)]
                                         [start-pos exact-nonnegative-integer? 0]
                                         [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? eof-object? procedure?)]{

类似于 @racket[read-bytes-avail!]，但在读取期间允许中断（另请参见 @secref["breakhandler"]）。
若调用 @racket[read-bytes-avail!/enable-break] 时中断功能被禁用，且因调用导致
@racket[exn:break] 异常被引发，则不会从 @racket[in] 读取任何字节。}


@defproc[(peek-string [amt exact-nonnegative-integer?]
                      [skip-bytes-amt exact-nonnegative-integer?]
                      [in input-port? (current-input-port)])
         (or/c string? eof-object?)]{

与 @racket[read-string] 类似，但返回的字符是 @tech{peek} 操作：保留在端口中供将来
读取和回看。（更准确地说，未解码的字节被留下供将来读取和回看。）
@racket[skip-bytes-amt] 参数指定在输入流中需要跳过的字节数（@italic{不是}字符数），
然后再收集要返回的字符；因此，总共会检查接下来的 @racket[skip-bytes-amt] 个字节加上
@racket[amt] 个字符。

对于大多数类型的端口，检查 @racket[skip-bytes-amt] 个字节和 @racket[amt] 个字符
至少需要 @math{@racket[skip-bytes-amt]+@racket[amt]} 字节的内存开销（与端口关联），
至少在读取这些字节/字符之前如此。对字符串端口（参见 @secref["stringport"]）、
管道端口（参见 @secref["pipeports"]）或具有特定 peek 过程的自定义端口进行回看时，
不需要这样的开销（取决于 peek 过程的实现方式；参见 @secref["customport"]）。

若端口在流中途产生 @racket[eof]，则对于 @tech{peek} 操作，试图跳过超过 @racket[eof]
的位置总是会返回 @racket[eof]，直到该 @racket[eof] 被读取。}

@defproc[(peek-bytes [amt exact-nonnegative-integer?]
                     [skip-bytes-amt exact-nonnegative-integer?]
                     [in input-port? (current-input-port)])
         (or/c bytes? eof-object?)]{
类似于 @racket[peek-string]，但 @tech{peek} 的是字节，返回字节字符串。}

@defproc[(peek-string! [str (and/c string? (not/c immutable?))]
                       [skip-bytes-amt exact-nonnegative-integer?]
                       [in input-port? (current-input-port)]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos exact-nonnegative-integer? (string-length str)])
         (or/c exact-nonnegative-integer? eof-object?)]{
类似于 @racket[read-string!]，但用于 @tech{peek} 操作，并接受一个
@racket[skip-bytes-amt] 参数（如 @racket[peek-string] 中所示）。}

@defproc[(peek-bytes! [bstr (and/c bytes? (not/c immutable?))]
                      [skip-bytes-amt exact-nonnegative-integer?]
                      [in input-port? (current-input-port)]
                      [start-pos exact-nonnegative-integer? 0]
                      [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? eof-object?)]{
类似于 @racket[peek-string!]，但 @tech{peek} 的是字节，放入字节字符串中，
并返回读取的字节数。}

@defproc[(peek-bytes-avail! [bstr (and/c bytes? (not/c immutable?))]
                            [skip-bytes-amt exact-nonnegative-integer?]
                            [progress (or/c progress-evt? #f) #f]
                            [in input-port? (current-input-port)]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? eof-object? procedure?)]{

类似于 @racket[read-bytes-avail!]，但用于 @tech{peek} 操作，并额外接受两个参数。
@racket[skip-bytes-amt] 参数与 @racket[peek-bytes] 中相同。@racket[progress] 参数
必须是 @racket[#f] 或由 @racket[port-progress-evt] 为 @racket[in] 生成的事件。

为了进行 @tech{peek}，@racket[peek-bytes-avail!] 会阻塞直到找到文件结束、
跳过的字节之后至少一个字节（或特殊值），或者直到非 @racket[#f] 的 @racket[progress]
变为就绪状态。此外，若 @racket[progress] 在 peek 字节之前就绪，则不会 peek 或跳过任何字节，
并且如果 @racket[progress] 在 peek 尝试期间变得可用，则可能缩短跳过过程。此外，
@racket[progress] 甚至在确定端口是否仍处于打开状态之前就被检查。

@racket[peek-bytes-avail!] 的结果为 @racket[0] 仅发生在以下情况：

@itemlist[
  @item{当 @racket[start-pos] 等于 @racket[end-pos] 时，或}
  @item{当 bytes 被 peek 之前 @racket[progress] 已就绪。}
]}

@defproc[(peek-bytes-avail!* [bstr (and/c bytes? (not/c immutable?))]
                             [skip-bytes-amt exact-nonnegative-integer?]
                             [progress (or/c progress-evt? #f) #f]
                             [in input-port? (current-input-port)]
                             [start-pos exact-nonnegative-integer? 0]
                             [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? eof-object? procedure?)]{

类似于 @racket[read-bytes-avail!*]，但用于 @tech{peek} 操作，并接受
@racket[skip-bytes-amt] 和 @racket[progress] 参数（如 @racket[peek-bytes-avail!] 中所示）。
由于此过程从不阻塞，它可能在连 @racket[skip-bytes-amt] 个字节尚未从端口可用时就返回了。}

@defproc[(peek-bytes-avail!/enable-break [bstr (and/c bytes? (not/c immutable?))]
                                         [skip-bytes-amt exact-nonnegative-integer?]
                                         [progress (or/c progress-evt? #f) #f]
                                         [in input-port? (current-input-port)]
                                         [start-pos exact-nonnegative-integer? 0]
                                         [end-pos exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? eof-object? procedure?)]{
类似于 @racket[read-bytes-avail!/enable-break]，但用于 @tech{peek} 操作，
并接受 @racket[skip-bytes-amt] 和 @racket[progress] 参数
（如 @racket[peek-bytes-avail!] 中所示）。}


@defproc[(read-char-or-special [in input-port? (current-input-port)]
                               [special-wrap (or/c (any/c . -> . any/c) #f) #f]
                               [source-name any/c #f])
         (or/c char? eof-object? any/c)]{

类似于 @racket[read-char]，但若输入端口返回一个 @tech{special} 值
（通过自定义端口中的值生成过程，其中 @racket[source-name] 被提供给该过程；
详见 @secref["customport"] 和 @secref["special-comments"]），
则返回将 @racket[special-wrap] 应用于该 @tech{special} 值的结果。
@racket[#f] 作为 @racket[special-wrap] 的值时，与恒等函数同样处理。

@history[#:changed "6.8.0.2" @elem{添加了 @racket[special-wrap] 和
                                   @racket[source-name] 参数。}]}

@defproc[(read-byte-or-special [in input-port? (current-input-port)]
                               [special-wrap (or/c (any/c . -> . any/c) #f) #f]
                               [source-name any/c #f])
         (or/c byte? eof-object? any/c)]{

类似于 @racket[read-char-or-special]，但读取并返回字节而非字符。

@history[#:changed "6.8.0.2" @elem{添加了 @racket[special-wrap] 和
                                   @racket[source-name] 参数。}]}

@defproc[(peek-char [in input-port? (current-input-port)]
                    [skip-bytes-amt exact-nonnegative-integer? 0])
         (or/c char? eof-object?)]{

类似于 @racket[read-char]，但进行 @tech{peek} 而非读取，并在端口开头跳过
@racket[skip-bytes-amt] 个字节（不是字符）。}

@defproc[(peek-byte [in input-port? (current-input-port)]
                    [skip-bytes-amt exact-nonnegative-integer? 0])
         (or/c byte? eof-object?)]{

Like @racket[peek-char], but @tech{peeks} and returns a byte instead of a
character.}

@defproc[(peek-char-or-special [in input-port? (current-input-port)]
                               [skip-bytes-amt exact-nonnegative-integer? 0]
                               [special-wrap (or/c (any/c . -> . any/c) #f 'special) #f]
                               [source-name any/c #f])
         (or/c char? eof-object? any/c)]{

类似于 @racket[peek-char]，但若输入端口在 @racket[skip-bytes-amt] 个字节位置之后返回
非字节值，则结果取决于 @racket[special-wrap]：

@itemlist[

 @item{若 @racket[special-wrap] 为 @racket[#f]，则返回该特殊值
       （如 @racket[read-char-or-special] 中所示）。}

@item{若 @racket[special-wrap] 是一个过程，则将其应用于该特殊值以产生结果
       （如 @racket[read-char-or-special] 中所示）。}

 @item{若 @racket[special-wrap] 为 @racket['special]，则返回 @racket['special]
       代替该特殊值——而不调用输入端口实现所返回的特殊值生产过程。}

]

@history[#:changed "6.8.0.2" @elem{添加了 @racket[special-wrap] 和
                                   @racket[source-name] 参数。}
         #:changed "6.90.0.16" @elem{添加了 @racket['special] 作为 @racket[special-wrap] 的一个选项。}]}

@defproc[(peek-byte-or-special [in input-port? (current-input-port)]
                               [skip-bytes-amt exact-nonnegative-integer? 0]
                               [progress (or/c progress-evt? #f) #f]
                               [special-wrap (or/c (any/c . -> . any/c) #f 'special) #f]
                               [source-name any/c #f])
         (or/c byte? eof-object? any/c)]{

类似于 @racket[peek-char-or-special]，但 @tech{peek} 并返回字节而非字符，
并支持类似 @racket[peek-bytes-avail!] 中的 @racket[progress] 参数。

@history[#:changed "6.8.0.2" @elem{添加了 @racket[special-wrap] 和
                                   @racket[source-name] 参数。}
         #:changed "6.90.0.16" @elem{添加了 @racket['special] 作为 @racket[special-wrap] 的一个选项。}]}


@defproc[(port-progress-evt [in (and/c input-port? port-provides-progress-evts?)
                                (current-input-port)])
         progress-evt?]{

返回一个 @tech{synchronizable event}（参见 @secref["sync"]），该事件在 @racket[in]
的任意后续读取之后或 @racket[in] 关闭之后变为 @tech{ready for synchronization}。
事件就绪后将一直保持就绪状态。@ResultItself{progress event}。}


@defproc[(port-provides-progress-evts? [in input-port?]) boolean]{

若 @racket[port-progress-evt] 可以为 @racket[in] 返回一个事件，则返回 @racket[#t]。
所有内置类型的端口都支持 progress event，但通过 @racket[make-input-port]
创建的端口（参见 @secref["customport"]）可能不支持。}

 
@defproc[(port-commit-peeked [amt exact-nonnegative-integer?]
                             [progress progress-evt?]
                             [evt evt?]
                             [in input-port? (current-input-port)])
         boolean?]{

尝试将 @racket[in] 中先前 @tech{peek} 的前 @racket[amt] 个字节、非字节特殊值和
@racket[eof] 中第一个提交为已读取，或者将 @racket[in] 中第一个已 @tech{peek} 的
@racket[eof] 或特殊值提交为已读取。流中途的 @racket[eof] 可以被提交，
但当端口耗尽时的 @racket[eof] 不一定被提交，因为它不对应于流中的数据。

仅当 @racket[progress] 未首先就绪（即没有其他进程先从 @racket[in] 读取），
且 @racket[evt] 在 @racket[port-commit-peeked] 内部被 @racket[sync] 选中时
（此时事件结果被忽略），读取才会被提交；@racket[evt] 必须是 channel-put event、
channel、semaphore、semaphore-peek event、always event 或 never event 之一。
挂起调用 @racket[port-commit-peeked] 的线程可能阻止也可能不阻止提交的进行。

若数据已被提交，@racket[port-commit-peeked] 的结果为 @racket[#t]，否则为 @racket[#f]。

若尚未从 @racket[in] @tech{peek} 任何数据且 @racket[progress] 未就绪，
则 @exnraise[exn:fail:contract]。若在 @racket[in] 的流当前位置 @tech{peek} 的项目少于
@racket[amt] 个，则仅将已 @tech{peek} 的项目提交为已读取。
若 @racket[in] 的流当前从 @racket[eof] 或非字节特殊值开始，
则仅将该 @racket[eof] 或特殊值提交为已读取。
 
若 @racket[progress] 不是将 @racket[port-progress-evt] 应用于 @racket[in] 的结果，
则 @exnraise[exn:fail:contract]。}


@defproc[(byte-ready? [in input-port? (current-input-port)])
         boolean?]{

Returns @racket[#t] if @racket[(read-byte in)] would not block (at the
time that @racket[byte-ready?] was called, at least).  Equivalent to
@racket[(and (sync/timeout 0 in) #t)].

对于相对较少的应用来说，@racket[byte-ready?] 和 @racket[char-ready?] 函数之所以合适，
是因为端口本意是为了支持并发生产者和消费者之间的流数据传输；
某一时刻某个字节或字符未就绪，并不一定意味着生产者已完成数据供应。
（此外，如果一个端口有多个消费者，数据可能在给定进程使用 @racket[byte-ready?]
轮询端口和它实际从端口读取数据之间的时间段内被消耗。）
实现自己的调度器时，或当端口的实现和使用受到特别限制时，使用 @racket[byte-ready?] 才有意义。}


@defproc[(char-ready? [in input-port? (current-input-port)])
         boolean?]{

若 @racket[(read-char in)] 不会阻塞（至少在调用 @racket[char-ready?] 的时刻如此），
则返回 @racket[#t]。根据流的初始字节，可能需要多个字节才能构成 UTF-8 编码。

关于 @racket[byte-ready?] 和 @racket[char-ready?] 很少是正确选择的说明，请参见
@racket[byte-ready?]。}


@defproc*[([(progress-evt? [v any/c]) boolean?]
           [(progress-evt? [evt progress-evt?] [in input-port?]) boolean?])]{

单参数形式下，若 @racket[v] 是某个输入端口的 progress evt，则返回 @racket[#t]，
否则返回 @racket[#f]。

双参数形式下，若 @racket[evt] 是 @racket[in] 的 progress event，则返回 @racket[#t]，
否则返回 @racket[#f]。}


@close-eval[si-eval]
