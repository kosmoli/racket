#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "bytestrings"]{Byte Strings}

@guideintro["bytestrings"]{byte strings}

A @deftech{byte string} is a fixed-length array of bytes. 一个
 @pidefterm{byte} 是介于 @racket[0] 和 @racket[255] 之间（含）的精确整数。

@index['("byte strings" "immutable")]{一个}字节串可以是 @defterm{可变} 或 @defterm{不可变} 的。如果将不可变的字节串传给类似 @racket[bytes-set!] 的过程，将引发 @exnraise[exn:fail:contract]。默认读取器（见 @secref["parse-string"]）生成的字节串常量是不可变的，在 @racket[read-syntax] 模式下会被 @tech{驻留}。使用 @racket[immutable?] 检查字节串是否不可变。

两个字节串长度相同且包含相同的字节序列时，它们是 @racket[equal?] 的。

字节串可以用作单值序列（见 @secref["sequences"]）。序列的元素就是字节串中的字节。另见 @racket[in-bytes]。

@see-read-print["string"]{byte strings}

另见：@racket[immutable?]。

@; ----------------------------------------
@section{Byte String Constructors, Selectors, and Mutators}

@defproc[(bytes? [v any/c]) boolean?]{ 如果 @racket[v] 是字节串则返回 @racket[#t]，否则返回 @racket[#f]。

另见 @racket[immutable-bytes?] 和 @racket[mutable-bytes?]。

@mz-examples[(bytes? #\"Apple\") (bytes? "Apple")]}


@defproc[(make-bytes [k exact-nonnegative-integer?] [b byte? 0])
bytes?]{ 返回一个新的可变字节串，长度为 @racket[k]，每个位置用字节 @racket[b] 初始化。

@mz-examples[(make-bytes 5 65)]}


@defproc[(bytes [b byte?] ...) bytes?]{ 返回一个新的可变字节串，长度等于给定的 @racket[b] 的数量，各位置用给定的 @racket[b] 初始化。

@mz-examples[(bytes 65 112 112 108 101)]}


@defproc[(bytes->immutable-bytes [bstr bytes?])
         (and/c bytes? immutable?)]{
 返回一个不可变字节串，内容与 @racket[bstr] 相同。如果 @racket[bstr] 本身不可变，则返回 @racket[bstr] 自身。

@examples[
(bytes->immutable-bytes (bytes 65 65 65))
(define b (bytes->immutable-bytes (make-bytes 5 65)))
(bytes->immutable-bytes b)
(eq? (bytes->immutable-bytes b) b)
]}

@defproc[(byte? [v any/c]) boolean?]{ 如果 @racket[v] 是字节（即介于 @racket[0] 和 @racket[255] 之间（含）的精确整数）则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(byte? 65) (byte? 0) (byte? 256) (byte? -1)]}


@defproc[(bytes-length [bstr bytes?]) exact-nonnegative-integer?]{
 返回 @racket[bstr] 的长度。

@mz-examples[(bytes-length #\"Apple\")]}


@defproc[(bytes-ref [bstr bytes?] [k exact-nonnegative-integer?])
 byte?]{  返回 @racket[bstr] 中位置 @racket[k] 的字节。第一个位置对应 @racket[0]，所以 @racket[k] 必须小于字节串的长度，否则引发 @exnraise[exn:fail:contract]。

@mz-examples[(bytes-ref #\"Apple\" 0)]}


@defproc[(bytes-set! [bstr (and/c bytes? (not/c immutable?))] [k
 exact-nonnegative-integer?] [b byte?]) void?]{  将
 @racket[bstr] 中位置 @racket[k] 的字节修改为 @racket[b]。第一个
 位置对应 @racket[0]，所以 @racket[k] 必须小于字节串的长度，否则
 引发 @exnraise[exn:fail:contract]。

@mz-examples[(define s (bytes 65 112 112 108 101))
             (bytes-set! s 4 121)
             s]}


@defproc[(subbytes [bstr bytes?] [start exact-nonnegative-integer?]
 [end exact-nonnegative-integer? (bytes-length str)]) bytes?]{ 返回一个新的可变字节串，
 长度为 @racket[(- end start)] 字节，包含 @racket[bstr] 中从 @racket[start]（含）到 @racket[end]（不含）的字节。@racket[start] 和 @racket[end] 参数必须小于等于 @racket[bstr] 的长度，且 @racket[end] 必须大于等于 @racket[start]，否则引发 @exnraise[exn:fail:contract]。

@mz-examples[(subbytes #\"Apple\" 1 3)
             (subbytes #\"Apple\" 1)]}


@defproc[(bytes-copy [bstr bytes?]) bytes?]{ 返回 @racket[(subbytes bstr 0)]。}


@defproc[(bytes-copy! [dest (and/c bytes? (not/c immutable?))]
                      [dest-start exact-nonnegative-integer?]
                      [src bytes?]
                      [src-start exact-nonnegative-integer? 0]
                      [src-end exact-nonnegative-integer? (bytes-length src)])
         void?]{

 修改 @racket[dest] 中从位置 @racket[dest-start] 开始的字节，
 使其与 @racket[src] 中从 @racket[src-start]（含）到 @racket[src-end]（不含）的字节一致。
 @racket[dest] 和 @racket[src] 可以是同一个字节串，
 这种情况下目标区域可以与源区域重叠；复制后目标中的字节与复制前源中的字节一致。如果 @racket[dest-start]、
 @racket[src-start] 或 @racket[src-end] 中任何一个超出范围（考虑
 字节串的大小以及源和目标区域），将引发 @exnraise[exn:fail:contract]。

@mz-examples[(define s (bytes 65 112 112 108 101))
             (bytes-copy! s 4 #\"y\")
             (bytes-copy! s 0 s 3 4)
             s]}

@defproc[(bytes-fill! [dest (and/c bytes? (not/c immutable?))] [b
 byte?]) void?]{ 修改 @racket[dest]，使其中每个位置都用 @racket[b] 填充。

@mz-examples[(define s (bytes 65 112 112 108 101))
             (bytes-fill! s 113)
             s]}


@defproc[(bytes-append [bstr bytes?] ...) bytes?]{ 

@index['("byte strings" "concatenate")]{返回} 一个新的可变字节串，
长度等于所有给定的 @racket[bstr] 长度的总和，
包含给定的 @racket[bstr] 连接后的字节。如果
未提供任何 @racket[bstr]，结果是一个长度为零的字节串。

@mz-examples[(bytes-append #\"Apple\" #\"Banana\")]}


@defproc[(bytes->list [bstr bytes?]) (listof byte?)]{ 返回一个新的
 字节列表，对应于 @racket[bstr] 的内容。即，
 列表长度为 @racket[(bytes-length bstr)]，@racket[bstr] 中的
 字节序列与结果列表中的序列相同。

@mz-examples[(bytes->list #\"Apple\")]}


@defproc[(list->bytes [lst (listof byte?)]) bytes?]{ 返回一个新的
 可变字节串，内容为 @racket[lst] 中的字节列表。
 即，字节串长度为 @racket[(length lst)]，@racket[lst] 中的字节序列与结果字节串中的序列相同。

@mz-examples[(list->bytes (list 65 112 112 108 101))]}

@defproc[(make-shared-bytes [k exact-nonnegative-integer?] [b byte? 0])
bytes?]{ 返回一个新的可变字节串，长度为 @racket[k]，每个位置用字节 @racket[b] 初始化。
为了 @tech{place} 之间的通信，新字节串分配在 @tech{共享内存空间} 中。

@mz-examples[(make-shared-bytes 5 65)]}


@defproc[(shared-bytes [b byte?] ...) bytes?]{ 返回一个新的可变字节串，
长度等于给定的 @racket[b] 的数量，各位置用给定的 @racket[b] 初始化。
为了 @tech{place} 之间的通信，新字节串分配在 @tech{共享内存空间} 中。

@mz-examples[(shared-bytes 65 112 112 108 101)]}


@; ----------------------------------------
@section{Byte String Comparisons}

@defproc[(bytes=? [bstr1 bytes?] [bstr2 bytes?] ...) boolean?]{ 
 如果所有参数都是 @racket[eqv?] 的则返回 @racket[#t]。

@mz-examples[(bytes=? #\"Apple\" #\"apple\")
             (bytes=? #\"a\" #\"as\" #\"a\")]

@history/arity[]}

@(define (bytes-sort direction)
   @elem{类似于 @racket[bytes<?]，但检查参数是否按 @|direction| 排序。})

@defproc[(bytes<? [bstr1 bytes?] [bstr2 bytes?] ...) boolean?]{
 如果参数按字典序递增排序（单个字节按 @racket[<] 排序）则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(bytes<? #\"Apple\" #\"apple\")
             (bytes<? #\"apple\" #\"Apple\")
             (bytes<? #\"a\" #\"b\" #\"c\")]

@history/arity[]}

@defproc[(bytes>? [bstr1 bytes?] [bstr2 bytes?] ...) boolean?]{
 @bytes-sort["decreasing"]

@mz-examples[(bytes>? #\"Apple\" #\"apple\")
             (bytes>? #\"apple\" #\"Apple\")
             (bytes>? #\"c\" #\"b\" #\"a\")]

@history/arity[]}

@; ----------------------------------------
@section{Bytes to/from Characters, Decoding and Encoding}

@defproc[(bytes->string/utf-8 [bstr bytes?]
                              [err-char (or/c #f char?) #f]
                              [start exact-nonnegative-integer? 0]
                              [end exact-nonnegative-integer? (bytes-length bstr)])
         string?]{
 通过将 @racket[bstr] 中从 @racket[start] 到 @racket[end] 的子串作为 Unicode 码点的 UTF-8 编码进行解码，生成一个字符串。如果 @racket[err-char] 不为 @racket[#f]，则用于落在 @racket[#o200] 到 @racket[#o377] 范围内但不是有效编码序列一部分的字节。（此规则与从端口读取字符一致；详见 @secref["encodings"]。）如果 @racket[err-char] 为 @racket[#f]，且 @racket[bstr] 中从 @racket[start] 到 @racket[end] 的子串整体不是有效的 UTF-8 编码，则引发 @exnraise[exn:fail:contract]。
 
@examples[
(bytes->string/utf-8 (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3))
]}

@defproc[(bytes->string/locale [bstr bytes?]
                               [err-char (or/c #f char?) #f]
                               [start exact-nonnegative-integer? 0]
                               [end exact-nonnegative-integer? (bytes-length bstr)])
         string?]{
 使用当前 locale 的编码（另见 @secref["encodings"]）解码 @racket[bstr] 中从 @racket[start] 到 @racket[end] 的子串，生成一个字符串。如果 @racket[err-char] 不为 @racket[#f]，则用于 @racket[bstr] 中每个不是有效编码一部分的字节；如果 @racket[err-char] 为 @racket[#f]，且 @racket[bstr] 中从 @racket[start] 到 @racket[end] 的子串整体不是有效的编码，则引发 @exnraise[exn:fail:contract]。}

@defproc[(bytes->string/latin-1 [bstr bytes?]
                                [err-char (or/c #f char?) #f]
                                [start exact-nonnegative-integer? 0]
                                [end exact-nonnegative-integer? (bytes-length bstr)])
         string?]{
 通过将 @racket[bstr] 中从 @racket[start] 到 @racket[end] 的子串作为 Unicode 码点的 Latin-1 编码进行解码，生成一个字符串；即，每个字节使用 @racket[integer->char] 直接转换为字符，因此解码总是成功的。@racket[err-char] 参数被忽略，但为了与其他操作保持一致而存在。
 
@examples[
(bytes->string/latin-1 (bytes #xfe #xd3 #xd1 #xa5))
]}

@defproc[(string->bytes/utf-8 [str string?]
                              [err-byte (or/c #f byte?) #f]
                              [start exact-nonnegative-integer? 0]
                              [end exact-nonnegative-integer? (string-length str)])
         bytes?]{
 通过 UTF-8 编码 @racket[str] 中从 @racket[start] 到 @racket[end] 的子串（总是成功），生成一个字节串。@racket[err-byte] 参数被忽略，但为了与其他操作保持一致而包含。
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
 使用当前 locale 的编码（另见 @secref["encodings"]）编码 @racket[str] 中从 @racket[start] 到 @racket[end] 的子串，生成一个字节串。如果 @racket[err-byte] 不为 @racket[#f]，则用于 @racket[str] 中每个无法为当前 locale 编码的字符；如果 @racket[err-byte] 为 @racket[#f]，且 @racket[str] 中从 @racket[start] 到 @racket[end] 的子串无法编码，则引发 @exnraise[exn:fail:contract]。}

@defproc[(string->bytes/latin-1 [str string?]
                                [err-byte (or/c #f byte?) #f]
                                [start exact-nonnegative-integer? 0]
                                [end exact-nonnegative-integer? (string-length str)])
         bytes?]{
 使用 Latin-1 编码 @racket[str] 中从 @racket[start] 到 @racket[end] 的子串，生成一个字节串；即，每个字符使用 @racket[char->integer] 直接转换为字节。如果 @racket[err-byte] 不为 @racket[#f]，则用于 @racket[str] 中每个值大于 @racket[255] 的字符。如果 @racket[err-byte] 为 @racket[#f]，且 @racket[str] 中从 @racket[start] 到 @racket[end] 的子串含有值大于 @racket[255] 的字符，则引发 @exnraise[exn:fail:contract]。
 
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
 返回 @racket[str] 中从 @racket[start] 到 @racket[end] 子串的 UTF-8 编码的字节长度，但不实际生成编码后的字节。
 
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
 返回 @racket[bstr] 中从 @racket[start] 到 @racket[end] 子串的 UTF-8 解码的字符长度，但不实际生成解码后的字符。如果 @racket[err-char] 为 @racket[#f] 且子串整体不是 UTF-8 编码，结果为 @racket[#f]。否则，@racket[err-char] 用于解决解码错误，如同 @racket[bytes->string/utf-8] 中一样。
 
@examples[
(bytes-utf-8-length (bytes #xc3 #xa7 #xc3 #xb0 #xc3 #xb6 #xc2 #xa3))
(bytes-utf-8-length (make-bytes 5 65))
]}

@defproc[(bytes-utf-8-ref [bstr bytes?]
                          [skip exact-nonnegative-integer?]
                          [err-char (or/c #f char?) #f]
                          [start exact-nonnegative-integer? 0]
                          [end exact-nonnegative-integer? (bytes-length bstr)])
         (or/c char? #f)]{
 返回 @racket[bstr] 中从 @racket[start] 到 @racket[end] 子串的 UTF-8 解码中第 @racket[skip] 个字符，但不实际生成其他已解码的字符。如果子串在 UTF-8 编码中只到第 @racket[skip] 个字符（当 @racket[err-char] 为 @racket[#f] 时），或者子串解码产生的字符少于 @racket[skip] 个，结果为 @racket[#f]。如果 @racket[err-char] 不为 @racket[#f]，则用于解决解码错误，如同 @racket[bytes->string/utf-8] 中一样。
 
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
 返回在 @racket[bstr] 中第 @racket[skip] 个字符的 UTF-8 编码起始位置的字节偏移量，作用于 @racket[bstr] 中从 @racket[start] 到 @racket[end] 的子串（但不实际生成其他已解码的字符）。结果相对于 @racket[bstr] 的起始位置，而非 @racket[start]。如果子串在 UTF-8 编码中只到第 @racket[skip] 个字符（当 @racket[err-char] 为 @racket[#f] 时），或者子串解码产生的字符少于 @racket[skip] 个，结果为 @racket[#f]。如果 @racket[err-char] 不为 @racket[#f]，则用于解决解码错误，如同 @racket[bytes->string/utf-8] 中一样。

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

 生成一个 @deftech{字节转换器}，用于从 @racket[from-name] 命名的编码转换到 @racket[to-name] 命名的编码。如果请求的编码转换不可用，则返回 @racket[#f] 而不是转换器。

 某些编码组合始终可用：

 @itemize[

 @item{@racket[(bytes-open-converter "UTF-8" "UTF-8")] --- 恒等转换，但输入中的编码错误会导致解码失败。}

 @item{@racket[(bytes-open-converter "UTF-8-permissive" "UTF-8")] ---
   @index['("UTF-8-permissive")]{恒等}转换，但任何不是有效编码序列一部分的输入字节都会被有效地替换为 @racketvalfont{#\\uFFFD} 的 UTF-8 编码序列。（这种无效序列的处理方式与将端口字节流解释为字符一致；见 @secref["ports"]。）}

 @item{@racket[(bytes-open-converter "" "UTF-8")] --- 从当前 locale 的默认编码（见 @secref["encodings"]）转换为 UTF-8。}

 @item{@racket[(bytes-open-converter "UTF-8" "")] --- 从 UTF-8 转换为当前 locale 的默认编码（见 @secref["encodings"]）。}

 @item{@racket[(bytes-open-converter "platform-UTF-8" "platform-UTF-16")]
   --- 在 @|AllUnix| 上将 UTF-8 转换为 UTF-16，其中每个 UTF-16 代码单元是由当前平台字节序排序的两个字节组成的序列。在 Windows 上，转换与 @racket[(bytes-open-converter "WTF-8" "WTF-16")] 相同，以支持不成对的代理代码单元。}

 @item{@racket[(bytes-open-converter "platform-UTF-8-permissive" "platform-UTF-16")]
   --- 类似于 @racket[(bytes-open-converter "platform-UTF-8" "platform-UTF-16")]，但任何不是有效 UTF-8 编码序列（或在 Windows 上对不成对代理扩展有效）的输入字节都会被有效地替换为 @racketvalfont{#\\uFFFD}。}

 @item{@racket[(bytes-open-converter "platform-UTF-16" "platform-UTF-8")]
   --- 在 @|AllUnix| 上将 UTF-16（由当前平台字节序排序的字节）转换为 UTF-8。在 Windows 上，转换与 @racket[(bytes-open-converter "WTF-16" "WTF-8")] 相同，以支持不成对的代理。在 @|AllUnix| 上，代理对被假定为配对的：具有 @code{#xD800} 位的字节对开始一个代理对，@code{#x03FF} 位用于该对和后续对（与 @code{#xDC00} 位的值无关）。在从输入字节串中的奇数偏移量解码时，所有平台的性能可能都较差。}

 @item{@racket[(bytes-open-converter "WTF-8" "WTF-16")]
   --- 将 WTF-8 @cite["Sapin18"] 的 UTF-8 超集转换为 UTF-16 的超集，以支持不成对的代理代码单元，其中每个 UTF-16 代码单元是由当前平台字节序排序的两个字节组成的序列。}

 @item{@racket[(bytes-open-converter "WTF-8-permissive" "WTF-16")]
   --- 类似于 @racket[(bytes-open-converter "WTF-8" "WTF-16")]，但任何不是有效 WTF-8 编码序列的输入字节都会被有效地替换为 @racketvalfont{#\\uFFFD}。}

 @item{@racket[(bytes-open-converter "WTF-16" "WTF-8")]
   --- 将 WTF-16 @cite["Sapin18"] 的 UTF-16 超集转换为 WTF-8 超集。输入可以包含作为不成对代理的 UTF-16 代码单元，相应的输出包含每个代理在 UTF-8 的自然扩展中的编码。}

 ]

 新打开的字节转换器会注册到当前的管理器（见 @secref["custodians"]），以便在管理器关闭时关闭转换器。如果转换器是不涉及 @racket[""] 的保证组合之一（在 Unix 上），或者是在 Windows 和 Mac OS 上的任何保证组合（包括 @racket[""]），则转换器不会注册到管理器（且不需要关闭）。

@margin-note{在 Windows 的 Racket 软件发行版中，@filepath{iconv.dll} 与 @filepath{libmzsch@italic{VERS}.dll} 一同提供。}

 可用的编码和组合集因平台而异，取决于已安装的 @exec{iconv} 库；@racket[from-name] 和 @racket[to-name] 参数被传递给 @tt{iconv_open}。在 Windows 上，@filepath{iconv.dll} 或 @filepath{libiconv.dll} 必须与 @filepath{libmzsch@italic{VERS}.dll} 在同一目录中（其中 @italic{VERS} 是版本号），或在用户的路径中，或在系统目录中，或在运行时可执行文件的目录中，并且 DLL 必须提供 @tt{_errno} 或链接到 @filepath{msvcrt.dll} 以获取 @tt{_errno}；否则，只有保证的组合可用。

 使用 @racket[bytes-convert] 传入转换结果来转换字节串。

@history[#:changed "7.9.0.17" @elem{内置添加了 @racket["WTF-8"]、@racket["WTF-8-permissive"] 和 @racket["WTF-16"] 的转换器。}]}


@defproc[(bytes-close-converter [converter bytes-converter?]) void]{

 关闭给定的转换器，使其不能再用于 @racket[bytes-convert] 或 @racket[bytes-convert-end]。}


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

 如果 @racket[dest-bstr] 不为 @racket[#f]，转换后的字节将写入 @racket[dest-bstr] 中从 @racket[dest-start-pos] 到 @racket[dest-end-pos] 的位置。如果 @racket[dest-bstr] 为 @racket[#f]，则新分配的字节串保存转换结果，如果 @racket[dest-end-pos] 不为 @racket[#f]，结果字节串的大小不超过 @racket[(- dest-end-pos dest-start-pos)]。

 @racket[bytes-convert] 的结果是三个值：

 @itemize[

 @item{@racket[_result-bstr] 或 @racket[_dest-wrote-amt] --- 如果 @racket[dest-bstr] 是 @racket[#f] 或未提供的则为字节串，否则为写入 @racket[dest-bstr] 的字节数。}

 @item{@racket[_src-read-amt] --- 从 @racket[src-bstr] 成功转换的字节数。}

 @item{@indexed-racket['complete]、@indexed-racket['continues]、@indexed-racket['aborts] 或 @indexed-racket['error] --- 表示转换如何终止：

  @itemize[

   @item{@racket['complete]: 整个输入已被处理，@racket[_src-read-amt] 将等于 @racket[(- src-end-pos src-start-pos)]。}

   @item{@racket['continues]: 由于结果大小限制或 @racket[dest-bstr] 中的空间不足，转换停止；在这种情况下，如果需要更多空间来处理 @racket[src-bstr] 中的下一个完整编码序列，返回的字节可能少于 @racket[(- dest-end-pos dest-start-pos)] 个。}

   @item{@racket['aborts]: 输入在编码序列中间停止，需要更多输入字节才能继续。例如，如果输入的最后一个字节是 @racket[#o303] 用于 @racket["UTF-8-permissive"] 解码，则结果为 @racket['aborts]，因为需要另一个字节来确定如何使用 @racket[#o303] 字节。}

   @item{@racket['error]: 在 @racket[src-bstr] 中从 @racket[(+ src-start-pos _src-read-amt)] 字节开始的字节不构成合法的编码序列。对于某些编码，永远不会产生此结果，其中所有字节序列都是有效的编码。例如，由于 @racket["UTF-8-permissive"] 通过丢弃字符或生成 ``?,'' 来处理无效的 UTF-8 序列，因此每个字节序列都是有效编码。}

  ]}
 ]

 应用转换器会在转换器中积累状态（即使 @racket[bytes-convert] 的第三个结果是 @racket['complete]）。此状态可以影响输入的进一步处理和输出的进一步生成，但仅适用于涉及 ``shift sequences'' 以在流内改变模式的转换。要终止输入序列并重置转换器，使用 @racket[bytes-convert-end]。

@; Using `eval:alts` in case iconv is not available
@examples[
(define convert (bytes-open-converter "UTF-8" "UTF-16"))
(eval:alts (bytes-convert convert (bytes 65 66 67 68))
           (values #\"\\376\\377\\0A\\0B\\0C\\0D\"
                   4
                   'complete))
(bytes 195 167 195 176 195 182 194 163)
(eval:alts (bytes-convert convert (bytes 195 167 195 176 195 182 194 163))
           (values #\"\\0\\347\\0\\360\\0\\366\\0\\243\"
                   8
                   'complete))
(eval:alts (bytes-close-converter convert) (void))
]}


@defproc[(bytes-convert-end [converter bytes-converter?]
                            [dest-bstr (or/c bytes? #f) #f]
                            [dest-start-pos exact-nonnegative-integer? 0]
                            [dest-end-pos (or/c exact-nonnegative-integer? #f)
                                          (and dest-bstr
                                               (bytes-length dest-bstr))])
          (values (or/c bytes? exact-nonnegative-integer?)
                  (or/c 'complete 'continues))]{

 类似于 @racket[bytes-convert]，但不是转换字节，此过程为转换生成结束序列（有时称为 ``shift sequence''），如果有的话。少数编码使用移位序列，因此对于大多数编码，此函数将成功输出为空。在任何情况下，输出（可能为空的）移位序列都会成功地将转换器重置为初始状态。

 @racket[bytes-convert-end] 的结果是两个值：

  @itemize[

  @item{@racket[_result-bstr] 或 @racket[_dest-wrote-amt] --- 如果 @racket[dest-bstr] 是 @racket[#f] 或未提供则为字节串，否则为写入 @racket[dest-bstr] 的字节数。}

  @item{@indexed-racket['complete] 或 @indexed-racket['continues] --- 表示转换是否完成。如果是 @racket['complete]，则已生成完整的结束序列。如果是 @racket['continues]，则由于结果大小限制或 @racket[dest-bstr] 中的空间不足，转换无法完成，第一个结果要么是空字节串，要么是 @racket[0]。}

  ]}


@defproc[(bytes-converter? [v any/c]) boolean?]{

 如果 @racket[v] 是由 @racket[bytes-open-converter] 生成的 @tech{字节转换器} 则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[
(eval:alts (bytes-converter? (bytes-open-converter "UTF-8" "UTF-16"))
           #t)
(bytes-converter? (bytes-open-converter "whacky" "not likely"))
(define b (bytes-open-converter "UTF-8" "UTF-16"))
(eval:alts (bytes-close-converter b) (void))
(eval:alts (bytes-converter? b) #t)
]}

@defproc[(locale-string-encoding) any]{

 返回当前 locale 编码的字符串（即通常由 @racket[""] 标识的编码）。另见 @racket[system-language+country]。}

@section{Additional Byte String Functions}
@note-lib[racket/bytes]
@(define string-eval (make-base-eval))
@@examples[#:hidden #:eval string-eval (require racket/bytes racket/list)]

@defproc[(bytes-append* [str bytes?] ... [strs (listof bytes?)]) bytes?]{
@; Note: this is exactly the same description as the one for append*

 类似于 @racket[bytes-append]，但最后一个参数用作 @racket[bytes-append] 的参数列表，因此 @racket[(bytes-append* str ... strs)] 与 @racket[(apply bytes-append str ... strs)] 相同。换句话说，@racket[bytes-append] 和 @racket[bytes-append*] 之间的关系类似于 @racket[list] 和 @racket[list*] 之间的关系。

@mz-examples[#:eval string-eval
  (bytes-append* #\"a\" #\"b\" '(#\"c\" #\"d\"))
  (bytes-append* (cdr (append* (map (lambda (x) (list #", " x))
                                     '(#\"Alpha\" #\"Beta\" #\"Gamma\")))))
]}


@defproc[(bytes-join [strs (listof bytes?)] [sep bytes?]) bytes?]{

 将 @racket[strs] 中的字节串进行连接，在每对字节串之间插入 @racket[sep]。返回一个新的可变字节串。

@mz-examples[#:eval string-eval
 (bytes-join '(#\"one\" #\"two\" #\"three\" #\"four\") #\" potato ")
]}


@close-eval[string-eval]
