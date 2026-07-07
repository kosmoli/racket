#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "bytestrings"]{Byte Strings}

@guideintro["bytestrings"]{byte strings}

@deftech{byte string}（字节字符串）是 byte 的定长数组。
@pidefterm{byte}（字节）是 @racket[0] 到 @racket[255] 之间（含两端）的精确整数。

@index['("byte strings" "immutable")]{A} byte string 可以是
@defterm{mutable}（可变的）或 @defterm{immutable}（不可变的）。当不可变的 byte string
被传给像 @racket[bytes-set!] 这样的过程时，会触发
@exnraise[exn:fail:contract]。默认 reader（参见 @secref["parse-string"]）生成的
byte string 常量是不可变的，并且在 @racket[read-syntax] 模式下它们是 @tech{interned} 的。
使用 @racket[immutable?] 来检查 byte string 是否不可变。

当两个 byte string 长度相同且包含相同的 byte 序列时，它们是 @racket[equal?] 的。

byte string 可以作为单值序列使用（参见
@secref["sequences"]）。byte string 中的 byte 作为序列的元素。
另见 @racket[in-bytes]。

@see-read-print["string"]{byte strings}

另见：@racket[immutable?]。

@; ----------------------------------------
@section{Byte String Constructors, Selectors, and Mutators}

@defproc[(bytes? [v any/c]) boolean?]{ 如果 @racket[v]
是 byte string 则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(bytes? #"Apple") (bytes? "Apple")]}


@defproc[(make-bytes [k exact-nonnegative-integer?] [b byte? 0])
bytes?]{ 返回一个新的长度为 @racket[k] 的可变 byte string，其中每个
位置都用 byte @racket[b] 初始化。

@mz-examples[(make-bytes 5 65)]}


@defproc[(bytes [b byte?] ...) bytes?]{ 返回一个新的可变 byte string，其长度为
提供的 @racket[b] 的个数，各位置用给定的 @racket[b] 初始化。

@mz-examples[(bytes 65 112 112 108 101)]}


@defproc[(bytes->immutable-bytes [bstr bytes?])
         (and/c bytes? immutable?)]{
 返回一个与 @racket[bstr] 内容相同的不可变 byte string，如果 @racket[bstr]
 本身已是不可变的，则直接返回 @racket[bstr] 自身。

@examples[
(bytes->immutable-bytes (bytes 65 65 65))
(define b (bytes->immutable-bytes (make-bytes 5 65)))
(bytes->immutable-bytes b)
(eq? (bytes->immutable-bytes b) b)
]}

@defproc[(byte? [v any/c]) boolean?]{ 如果 @racket[v] 是 byte
（即 @racket[0] 到 @racket[255] 之间含两端的精确整数）则返回 @racket[#t]，
否则返回 @racket[#f]。

@mz-examples[(byte? 65) (byte? 0) (byte? 256) (byte? -1)]}


@defproc[(bytes-length [bstr bytes?]) exact-nonnegative-integer?]{
 返回 @racket[bstr] 的长度。

@mz-examples[(bytes-length #"Apple")]}


@defproc[(bytes-ref [bstr bytes?] [k exact-nonnegative-integer?])
 byte?]{  返回 @racket[bstr] 中位置 @racket[k] 处的字节。
byte string 的第一个位置对应 @racket[0]，因此位置
@racket[k] 必须小于 byte string 的长度，否则将触发
@exnraise[exn:fail:contract]。

@mz-examples[(bytes-ref #"Apple" 0)]}


@defproc[(bytes-set! [bstr (and/c bytes? (not/c immutable?))] [k
 exact-nonnegative-integer?] [b byte?]) void?]{  将
@racket[bstr] 中位置 @racket[k] 处的字节更改为 @racket[b]。byte string 的第一个
位置对应 @racket[0]，因此位置 @racket[k] 必须小于 byte string 的长度，否则将触发
@exnraise[exn:fail:contract]。

@mz-examples[(define s (bytes 65 112 112 108 101))
             (bytes-set! s 4 121)
             s]}


@defproc[(subbytes [bstr bytes?] [start exact-nonnegative-integer?]
 [end exact-nonnegative-integer? (bytes-length str)]) bytes?]{ 返回
一个新的长度为 @racket[(- end start)] 的可变 byte string，包含 @racket[bstr]
中从 @racket[start]（含）到 @racket[end]（不含）的相同字节。
@racket[start] 和 @racket[end] 参数必须小于或等于 @racket[bstr] 的长度，
且 @racket[end] 必须大于或等于 @racket[start]，否则将触发
@exnraise[exn:fail:contract]。

@mz-examples[(subbytes #"Apple" 1 3)
             (subbytes #"Apple" 1)]}


@defproc[(bytes-copy [bstr bytes?]) bytes?]{ 返回
@racket[(subbytes str 0)]。}


@defproc[(bytes-copy! [dest (and/c bytes? (not/c immutable?))]
                      [dest-start exact-nonnegative-integer?]
                      [src bytes?]
                      [src-start exact-nonnegative-integer? 0]
                      [src-end exact-nonnegative-integer? (bytes-length src)])
         void?]{

将 @racket[dest] 中从位置 @racket[dest-start] 开始的字节更改为
@racket[src] 中从 @racket[src-start]（含）到 @racket[src-end]（不含）的字节。
byte string @racket[dest] 和 @racket[src] 可以是同一个 byte string，
在这种情况下目标区域可以与源区域重叠；复制后的目标字节匹配
复制前的源字节。如果 @racket[dest-start]、@racket[src-start]
或 @racket[src-end] 中任何一个超出范围（考虑 byte string 的大小
以及源和目标区域），将触发 @exnraise[exn:fail:contract]。

@mz-examples[(define s (bytes 65 112 112 108 101))
             (bytes-copy! s 4 #"y")
             (bytes-copy! s 0 s 3 4)
             s]}

@defproc[(bytes-fill! [dest (and/c bytes? (not/c immutable?))] [b
 byte?]) void?]{ 将 @racket[dest] 中每个位置都填充为 @racket[b]。

@mz-examples[(define s (bytes 65 112 112 108 101))
             (bytes-fill! s 113)
             s]}


@defproc[(bytes-append [bstr bytes?] ...) bytes?]{ 

@index['("byte strings" "concatenate")]{Returns} 一个新的可变 byte string，
其长度为所有给定 @racket[bstr] 长度之和，包含所有给定 @racket[bstr]
的连接字节。如果没有提供 @racket[bstr]，则结果为零长度的 byte string。

@mz-examples[(bytes-append #"Apple" #"Banana")]}


@defproc[(bytes->list [bstr bytes?]) (listof byte?)]{ 返回一个与
@racket[bstr] 内容对应的新的 byte 列表。即列表的长度为
@racket[(bytes-length bstr)]，@racket[bstr] 中的 byte 序列与
结果列表中的序列相同。

@mz-examples[(bytes->list #"Apple")]}


@defproc[(list->bytes [lst (listof byte?)]) bytes?]{ 返回一个新的
可变 byte string，其内容为 @racket[lst] 中的 byte 列表。
即 byte string 的长度为 @racket[(length lst)]，@racket[lst] 中的 byte 序列
与结果 byte string 中的序列相同。

@mz-examples[(list->bytes (list 65 112 112 108 101))]}

@defproc[(make-shared-bytes [k exact-nonnegative-integer?] [b byte? 0])
bytes?]{ 返回一个新的长度为 @racket[k] 的可变 byte string，其中每个
位置都用 byte @racket[b] 初始化。
为了在 @tech{places} 之间通信，新的 byte string 被分配在
@tech{shared memory space} 中。

@mz-examples[(make-shared-bytes 5 65)]}


@defproc[(shared-bytes [b byte?] ...) bytes?]{ 返回一个新的可变 byte string，
其长度为提供的 @racket[b] 的个数，各位置用给定的 @racket[b] 初始化。
为了在 @tech{places} 之间通信，新的 byte string 被分配在
@tech{shared memory space} 中。

@mz-examples[(shared-bytes 65 112 112 108 101)]}


@; ----------------------------------------
@section{Byte String Comparisons}

@defproc[(bytes=? [bstr1 bytes?] [bstr2 bytes?] ...) boolean?]{ 如果
所有参数都是 @racket[eqv?] 则返回 @racket[#t]。

@mz-examples[(bytes=? #"Apple" #"apple")
             (bytes=? #"a" #"as" #"a")]

@history/arity[]}

@(define (bytes-sort direction)
   @elem{Like @racket[bytes<?], but checks whether the arguments are @|direction|.})

@defproc[(bytes<? [bstr1 bytes?] [bstr2 bytes?] ...) boolean?]{
 如果参数按字典序递增排列（其中单个 byte 按 @racket[<] 排序），
 则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(bytes<? #"Apple" #"apple")
             (bytes<? #"apple" #"Apple")
             (bytes<? #"a" #"b" #"c")]

@history/arity[]}

@defproc[(bytes>? [bstr1 bytes?] [bstr2 bytes?] ...) boolean?]{
 @bytes-sort["decreasing"]

@mz-examples[(bytes>? #"Apple" #"apple")
             (bytes>? #"apple" #"Apple")
             (bytes>? #"c" #"b" #"a")]

@history/arity[]}

@; ----------------------------------------
@section{Bytes to/from Characters, Decoding and Encoding}

@defproc[(bytes->string/utf-8 [bstr bytes?]
                              [err-char (or/c #f char?) #f]
                              [start exact-nonnegative-integer? 0]
                              [end exact-nonnegative-integer? (bytes-length bstr)])
         string?]{
通过将 @racket[bstr] 的 @racket[start] 到 @racket[end] 子串解码为
Unicode 码点的 UTF-8 编码来生成一个字符串。如果 @racket[err-char]
不是 @racket[#f]，则用于处理范围在 @racket[#o200] 到 @racket[#o377]
之间但不属于有效编码序列的字节。（此规则与从端口读取字符一致；
详见 @secref["encodings"]。）如果 @racket[err-char] 是 @racket[#f]，
且 @racket[bstr] 的 @racket[start] 到 @racket[end] 子串整体上不是
有效的 UTF-8 编码，则触发 @exnraise[exn:fail:contract]。
 
@examples[
(bytes->string/utf-8 (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3))
]}

@defproc[(bytes->string/locale [bstr bytes?]
                               [err-char (or/c #f char?) #f]
                               [start exact-nonnegative-integer? 0]
                               [end exact-nonnegative-integer? (bytes-length bstr)])
         string?]{
通过使用当前 locale 的编码（另见 @secref["encodings"]）对 @racket[bstr]
的 @racket[start] 到 @racket[end] 子串进行解码来生成字符串。
如果 @racket[err-char] 不是 @racket[#f]，则用于处理 @racket[bstr] 中
不属于有效编码的每个字节；如果 @racket[err-char] 是 @racket[#f]，
且 @racket[bstr] 的 @racket[start] 到 @racket[end] 子串整体上不是
有效编码，则触发 @exnraise[exn:fail:contract]。}

@defproc[(bytes->string/latin-1 [bstr bytes?]
                                [err-char (or/c #f char?) #f]
                                [start exact-nonnegative-integer? 0]
                                [end exact-nonnegative-integer? (bytes-length bstr)])
         string?]{
通过将 @racket[bstr] 的 @racket[start] 到 @racket[end] 子串解码为
Unicode 码点的 Latin-1 编码来生成字符串；即每个字节直接通过
@racket[integer->char] 转换为字符，因此解码总是成功的。
@racket[err-char] 参数被忽略，但为了与其他操作保持一致而保留。
 
@examples[
(bytes->string/latin-1 (bytes #xfe #xd3 #xd1 #xa5))
]}

@defproc[(string->bytes/utf-8 [str string?]
                              [err-byte (or/c #f byte?) #f]
                              [start exact-nonnegative-integer? 0]
                              [end exact-nonnegative-integer? (string-length str)])
         bytes?]{
通过 UTF-8 编码 @racket[str] 的 @racket[start] 到 @racket[end] 子串来生成
byte string（总是成功的）。@racket[err-byte] 参数被忽略，但为了与其他操作
保持一致而包含。
@examples[
(define b
  (bytes->string/utf-8
   (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3)))

(string->bytes/utf-8 b)
(bytes->string/utf-8 (string->bytes/utf-8 b))
]}

@defproc[(string->bytes/locale [str string?]
                               [err-byte (or/c #f byte?) #f]
                               [start exact-nonnegative-integer? 0]
                               [end exact-nonnegative-integer? (string-length str)])
         bytes?]{
通过使用当前 locale 的编码（另见 @secref["encodings"]）对 @racket[str]
的 @racket[start] 到 @racket[end] 子串进行编码来生成字符串。
如果 @racket[err-byte] 不是 @racket[#f]，则用于处理 @racket[str] 中
无法用当前 locale 编码的每个字符；如果 @racket[err-byte] 是 @racket[#f]，
且 @racket[str] 的 @racket[start] 到 @racket[end] 子串无法编码，
则触发 @exnraise[exn:fail:contract]。}

@defproc[(string->bytes/latin-1 [str string?]
                                [err-byte (or/c #f byte?) #f]
                                [start exact-nonnegative-integer? 0]
                                [end exact-nonnegative-integer? (string-length str)])
         bytes?]{
通过使用 Latin-1 对 @racket[str] 的 @racket[start] 到 @racket[end] 子串进行编码
来生成字符串；即每个字符直接通过 @racket[char->integer] 转换为字节。
如果 @racket[err-byte] 不是 @racket[#f]，则用于处理 @racket[str] 中
值大于 @racket[255] 的每个字符。
如果 @racket[err-byte] 是 @racket[#f]，且 @racket[str] 的
@racket[start] 到 @racket[end] 子串中存在值大于 @racket[255] 的字符，
则触发 @exnraise[exn:fail:contract]。
 
@examples[
(define b
  (bytes->string/latin-1 (bytes #xfe #xd3 #xd1 #xa5)))

(string->bytes/latin-1 b)
(bytes->string/latin-1 (string->bytes/latin-1 b))
]}

@defproc[(string-utf-8-length [str string?]
                              [start exact-nonnegative-integer? 0]
                              [end exact-nonnegative-integer? (string-length str)])
         exact-nonnegative-integer?]{
返回 @racket[str] 的 @racket[start] 到 @racket[end] 子串的 UTF-8 编码的
字节长度，但不实际生成编码后的字节。
 
@examples[
(string-utf-8-length 
  (bytes->string/utf-8 (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3)))
(string-utf-8-length "hello")
]}

@defproc[(bytes-utf-8-length [bstr bytes?]
                             [err-char (or/c #f char?) #f]
                             [start exact-nonnegative-integer? 0]
                             [end exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? #f)]{
返回 @racket[bstr] 的 @racket[start] 到 @racket[end] 子串的 UTF-8 解码的
字符长度，但不实际生成解码后的字符。如果 @racket[err-char] 是
@racket[#f] 且子串整体上不是 UTF-8 编码，则结果为 @racket[#f]。
否则，@racket[err-char] 用于按 @racket[bytes->string/utf-8] 中的方式
解决解码错误。
 
@examples[
(bytes-utf-8-length (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3))
(bytes-utf-8-length (make-bytes 5 65))
]}

@defproc[(bytes-utf-8-ref [bstr bytes?]
                          [skip exact-nonnegative-integer? 0]
                          [err-char (or/c #f char?) #f]
                          [start exact-nonnegative-integer? 0]
                          [end exact-nonnegative-integer? (bytes-length bstr)])
         (or/c char? #f)]{
返回 @racket[bstr] 的 @racket[start] 到 @racket[end] 子串的 UTF-8 解码中
第 @racket[skip] 个字符，但不实际生成其他解码后的字符。如果子串在
第 @racket[skip] 个字符之前不是有效的 UTF-8 编码（当 @racket[err-char]
是 @racket[#f] 时），或者子串解码产生的字符少于 @racket[skip] 个，
则结果为 @racket[#f]。如果 @racket[err-char] 不是 @racket[#f]，
则按 @racket[bytes->string/utf-8] 中的方式解决解码错误。
 
@examples[
(bytes-utf-8-ref (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3) 0)
(bytes-utf-8-ref (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3) 1)
(bytes-utf-8-ref (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3) 2)
(bytes-utf-8-ref (bytes 65 66 67 68) 0)
(bytes-utf-8-ref (bytes 65 66 67 68) 1)
(bytes-utf-8-ref (bytes 65 66 67 68) 2)
]}

@defproc[(bytes-utf-8-index [bstr bytes?]
                            [skip exact-nonnegative-integer?]
                            [err-char (or/c #f char?) #f]
                            [start exact-nonnegative-integer? 0]
                            [end exact-nonnegative-integer? (bytes-length bstr)])
         (or/c exact-nonnegative-integer? #f)]{
返回 @racket[bstr] 中第 @racket[skip] 个字符的编码在 @racket[bstr] 的
@racket[start] 到 @racket[end] 子串的 UTF-8 解码中开始处的字节偏移量
（但不实际生成其他解码后的字符）。结果是相对于 @racket[bstr] 开头的，
而不是相对于 @racket[start] 的。如果子串在第 @racket[skip] 个字符之前
不是有效的 UTF-8 编码（当 @racket[err-char] 是 @racket[#f] 时），
或者子串解码产生的字符少于 @racket[skip] 个，则结果为 @racket[#f]。
如果 @racket[err-char] 不是 @racket[#f]，则按 @racket[bytes->string/utf-8]
中的方式解决解码错误。

@examples[
(bytes-utf-8-index (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3) 0)
(bytes-utf-8-index (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3) 1)
(bytes-utf-8-index (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3) 2)
(bytes-utf-8-index (bytes 65 66 67 68) 0)
(bytes-utf-8-index (bytes 65 66 67 68) 1)
(bytes-utf-8-index (bytes 65 66 67 68) 2)
]}

@; ----------------------------------------
@section{Bytes to Bytes Encoding Conversion}

@defproc[(bytes-open-converter [from-name string?] [to-name string?])
         (or/c bytes-converter? #f)]{

生成一个 @deftech{byte converter}（字节转换器），用于从 @racket[from-name]
命名的编码转换到 @racket[to-name] 命名的编码。如果请求的转换组合不可用，
则返回 @racket[#f] 而非转换器。

某些编码组合始终可用：

 @itemize[

 @item{@racket[(bytes-open-converter "UTF-8" "UTF-8")] --- 恒等转换，
   但输入中的编码错误会导致解码失败。}

 @item{@racket[(bytes-open-converter "UTF-8-permissive" "UTF-8")] ---
   @index['("UTF-8-permissive")]{the} 恒等转换，但任何不属于有效编码序列的
   输入字节都会被替换为 @racketvalfont{#\uFFFD} 的 UTF-8 编码序列。
   （这种对无效序列的处理与端口字节流到字符的解释一致；
   参见 @secref["ports"]。）}

 @item{@racket[(bytes-open-converter "" "UTF-8")] --- 从当前 locale 的
   默认编码（参见 @secref["encodings"]）转换为 UTF-8。}

 @item{@racket[(bytes-open-converter "UTF-8" "")] --- 从 UTF-8 转换为
   当前 locale 的默认编码（参见 @secref["encodings"]）。}

 @item{@racket[(bytes-open-converter "platform-UTF-8" "platform-UTF-16")]
   --- 在 @|AllUnix| 上将 UTF-8 转换为 UTF-16，其中每个 UTF-16
   码单元是由当前平台字节序排列的两个字节组成的序列。在 Windows 上，
   转换等同于 @racket[(bytes-open-converter "WTF-8" "WTF-16")] 以支持
   未配对的代理码单元。}

 @item{@racket[(bytes-open-converter "platform-UTF-8-permissive" "platform-UTF-16")]
   --- 类似于 @racket[(bytes-open-converter "platform-UTF-8" "platform-UTF-16")]，
   但不属于有效 UTF-8 编码序列（或在 Windows 上对未配对代理扩展无效）的
   输入字节会被替换为 @racketvalfont{#\uFFFD}。}

 @item{@racket[(bytes-open-converter "platform-UTF-16" "platform-UTF-8")]
   --- 在 @|AllUnix| 上将 UTF-16（按当前平台字节序排列的字节）转换为 UTF-8。
   在 Windows 上，转换等同于 @racket[(bytes-open-converter "WTF-16" "WTF-8")]
   以支持未配对代理。在 @|AllUnix| 上，假定代理是配对的：以 @code{#xD800}
   位开始的一对字节构成代理对，使用该对和后续对的 @code{#x03FF} 位
   （与 @code{#xDC00} 位的值无关）。在所有平台上，从输入 byte string 中
   奇数偏移量处解码时性能可能较差。}

 @item{@racket[(bytes-open-converter "WTF-8" "WTF-16")]
   --- 将 WTF-8 @cite["Sapin18"]（UTF-8 的超集）转换为 UTF-16 的超集
   以支持未配对的代理码单元，其中每个 UTF-16 码单元是由当前平台字节序
   排列的两个字节组成的序列。}

 @item{@racket[(bytes-open-converter "WTF-8-permissive" "WTF-16")]
   --- 类似于 @racket[(bytes-open-converter "WTF-8" "WTF-16")]，
   但不属于有效 WTF-8 编码序列的输入字节会被替换为 @racketvalfont{#\uFFFD}。}

 @item{@racket[(bytes-open-converter "WTF-16" "WTF-8")]
   --- 将 WTF-16 @cite["Sapin18"]（UTF-16 的超集）转换为 WTF-8
   （UTF-8 的超集）。输入可以包含未配对代理的 UTF-16 码单元，
   相应的输出包含以 UTF-8 的自然扩展编码每个代理。}

 ]

新打开的 byte converter 会注册到当前 custodian（参见 @secref["custodians"]），
以便在 custodian 关闭时关闭该转换器。如果转换器是 Unix 上不涉及 @racket[""]
的保证组合之一，或者在 Windows 和 Mac OS 上是任何保证组合
（包括 @racket[""]），则不会注册到 custodian（也不需要关闭）。

@margin-note{在 Windows 的 Racket 软件发行版中，合适的
@filepath{iconv.dll} 包含在 @filepath{libmzsch@italic{VERS}.dll} 中。}

可用的编码和组合因平台而异，取决于安装的 @exec{iconv} 库；
@racket[from-name] 和 @racket[to-name] 参数会传递给 @tt{iconv_open}。
在 Windows 上，@filepath{iconv.dll} 或 @filepath{libiconv.dll} 必须与
@filepath{libmzsch@italic{VERS}.dll}（其中 @italic{VERS} 是版本号）在同一目录下，
或者在用户的 PATH 中、系统目录中、或运行时当前可执行文件的目录中，
并且 DLL 必须提供 @tt{_errno} 或链接到 @filepath{msvcrt.dll} 以获取 @tt{_errno}；
否则，只有保证的组合可用。

使用 @racket[bytes-convert] 和结果来转换 byte string。

@history[#:changed "7.9.0.17" @elem{Added built-in converters for
                                    @racket["WTF-8"],
                                    @racket["WTF-8-permissive"], and
                                    @racket["WTF-16"].}]}


@defproc[(bytes-close-converter [converter bytes-converter?]) void]{

关闭给定的转换器，使其不再能用于
@racket[bytes-convert] 或 @racket[bytes-convert-end]。}


@defproc[(bytes-convert [converter bytes-converter?]
                        [src-bstr bytes?]
                        [src-start-pos exact-nonnegative-integer? 0]
                        [src-end-pos exact-nonnegative-integer? (bytes-length src-bstr)]
                        [dest-bstr (or/c bytes? #f) #f]
                        [dest-start-pos exact-nonnegative-integer? 0]
                        [dest-end-pos (or/c exact-nonnegative-integer? #f)
                                      (and dest-bstr
                                           (bytes-length dest-bstr))])
          (values (or/c bytes? exact-nonnegative-integer?)
                  exact-nonnegative-integer?
                  (or/c 'complete 'continues 'aborts 'error))]{

转换 @racket[src-bstr] 中从 @racket[src-start-pos] 到 @racket[src-end-pos] 的字节。

如果 @racket[dest-bstr] 不是 @racket[#f]，则将转换后的字节写入
@racket[dest-bstr] 中从 @racket[dest-start-pos] 到 @racket[dest-end-pos] 的位置。
如果 @racket[dest-bstr] 是 @racket[#f]，则分配一个新的 byte string
来保存转换结果，如果 @racket[dest-end-pos] 不是 @racket[#f]，
则结果 byte string 的大小不超过 @racket[(- dest-end-pos dest-start-pos)]。

@racket[bytes-convert] 的结果为三个值：

 @itemize[

 @item{@racket[_result-bstr] 或 @racket[_dest-wrote-amt] --- 如果
 @racket[dest-bstr] 是 @racket[#f] 或未提供，则为 byte string；
 否则为写入 @racket[dest-bstr] 的字节数。}

 @item{@racket[_src-read-amt] --- 从 @racket[src-bstr] 成功转换的字节数。}

 @item{@indexed-racket['complete]、@indexed-racket['continues]、
 @indexed-racket['aborts] 或 @indexed-racket['error] --- 表示
 转换如何终止：

  @itemize[

   @item{@racket['complete]：整个输入已处理，@racket[_src-read-amt]
    等于 @racket[(- src-end-pos src-start-pos)]。}

   @item{@racket['continues]：由于结果大小限制或 @racket[dest-bstr]
   中空间不足而停止转换；在这种情况下，如果处理 @racket[src-bstr]
   中下一个完整编码序列需要更多空间，可能返回少于
   @racket[(- dest-end-pos dest-start-pos)] 字节。}

   @item{@racket['aborts]：输入在编码序列中间停止，需要更多输入字节
   才能继续。例如，如果对于 @racket["UTF-8-permissive"] 解码，
   输入的最后一个字节是 @racket[#o303]，则结果为 @racket['aborts]，
   因为需要另一个字节来确定如何使用 @racket[#o303] 字节。}

   @item{@racket['error]：@racket[src-bstr] 中从 @racket[(+
   src-start-pos _src-read-amt)] 开始的字节不构成合法的编码序列。
   对于某些编码，此结果永远不会产生，因为所有字节序列都是有效的编码。
   例如，由于 @racket["UTF-8-permissive"] 通过丢弃字符或生成 ``?'' 来处理
   无效的 UTF-8 序列，因此每个字节序列实际上都是有效的。}

  ]}
 ]

应用转换器会在转换器中累积状态（即使 @racket[bytes-convert] 的第三个结果是
@racket['complete]）。此状态可能影响后续的输入处理和输出生成，
但仅涉及流中用于切换模式的 ``shift sequences'' 的转换。要终止输入序列
并重置转换器，请使用 @racket[bytes-convert-end]。

@examples[
(define convert (bytes-open-converter "UTF-8" "UTF-16"))
(bytes-convert convert (bytes 65 66 67 68))
(bytes 195 167 195 176 195 182 194 163)
(bytes-convert convert (bytes 195 167 195 176 195 182 194 163))
(bytes-close-converter convert)
]}


@defproc[(bytes-convert-end [converter bytes-converter?]
                            [dest-bstr (or/c bytes? #f) #f]
                            [dest-start-pos exact-nonnegative-integer? 0]
                            [dest-end-pos (or/c exact-nonnegative-integer? #f)
                                          (and dest-bstr
                                               (bytes-length dest-bstr))])
          (values (or/c bytes? exact-nonnegative-integer?)
                  (or/c 'complete 'continues))]{

类似于 @racket[bytes-convert]，但此过程不是转换字节，而是生成转换的
结束序列（有时称为 ``shift sequence''），如果有的话。很少有编码使用
shift sequence，因此对于大多数编码此函数将在无输出的情况下成功。
在任何情况下，成功输出一个（可能为空的）shift sequence 会将转换器
重置为初始状态。

@racket[bytes-convert-end] 的结果为两个值：

  @itemize[

  @item{@racket[_result-bstr] 或 @racket[_dest-wrote-amt] --- 如果
  @racket[dest-bstr] 是 @racket[#f] 或未提供，则为 byte string；
  否则为写入 @racket[dest-bstr] 的字节数。}

  @item{@indexed-racket['complete] 或 @indexed-racket['continues] ---
  表示转换是否完成。如果是 @racket['complete]，则已生成完整的结束序列。
  如果是 @racket['continues]，则由于结果大小限制或 @racket[dest-bstr]
  中空间不足而无法完成转换，第一个结果为空 byte string 或 @racket[0]。}

  ]
}

@defproc[(bytes-converter? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[bytes-open-converter] 生成的 @tech{byte converter}
则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[
(bytes-converter? (bytes-open-converter "UTF-8" "UTF-16"))
(bytes-converter? (bytes-open-converter "whacky" "not likely"))
(define b (bytes-open-converter "UTF-8" "UTF-16"))
(bytes-close-converter b)
(bytes-converter? b)
]}

@defproc[(locale-string-encoding) any]{

返回当前 locale 编码的字符串（即通常用 @racket[""] 标识的编码）。另见
@racket[system-language+country]。}

@section{Additional Byte String Functions}
@note-lib[racket/bytes]
@(define string-eval (make-base-eval))
@@examples[#:hidden #:eval string-eval (require racket/bytes racket/list)]

@defproc[(bytes-append* [str bytes?] ... [strs (listof bytes?)]) bytes?]{
@; Note: this is exactly the same description as the one for append*

类似于 @racket[bytes-append]，但最后一个参数被用作 @racket[bytes-append]
的参数列表，因此 @racket[(bytes-append*
str ... strs)] 等同于 @racket[(apply bytes-append str
... strs)]。换言之，@racket[bytes-append] 和 @racket[bytes-append*] 之间的关系
类似于 @racket[list] 和 @racket[list*] 之间的关系。

@mz-examples[#:eval string-eval
  (bytes-append* #"a" #"b" '(#"c" #"d"))
  (bytes-append* (cdr (append* (map (lambda (x) (list #", " x))
                                     '(#"Alpha" #"Beta" #"Gamma")))))
]}

@defproc[(bytes-join [strs (listof bytes?)] [sep bytes?]) bytes?]{

连接 @racket[strs] 中的 byte string，在 @racket[strs] 中每对 byte string
之间插入 @racket[sep]。

@mz-examples[#:eval string-eval
 (bytes-join '(#"one" #"two" #"three" #"four") #" potato ")
]}

@close-eval[string-eval]
