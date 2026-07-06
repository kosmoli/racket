#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "strings"]{Strings}

@guideintro["strings"]{strings}

一个 @deftech{string} 是固定长度的 @seclink["characters"]{characters} 数组。

@index['("strings" "immutable")]{字符串}可以是 @defterm{可变} 的或 @defterm{不可变} 的。如果将不可变的字符串传给类似 @racket[string-set!] 的过程，将引发 @exnraise[exn:fail:contract]。默认读取器（见 @secref["parse-string"]）生成的字符串常量是不可变的，在 @racket[read-syntax] 模式下会被 @tech{驻留}。使用 @racket[immutable?] 检查字符串是否不可变。

两个字符串长度相同且包含相同的字符序列时，它们是 @racket[equal?] 的。

字符串可以用作单值序列（见 @secref["sequences"]）。序列的元素就是字符串中的字符。另见 @racket[in-string]。

@see-read-print["string"]{strings}

另见：@racket[immutable?]、@racket[symbol->string]、@racket[bytes->string/utf-8]。

@; ----------------------------------------
@section{String Constructors, Selectors, and Mutators}

@defproc[(string? [v any/c]) boolean?]{ 如果 @racket[v] 是字符串则返回 @racket[#t]，否则返回 @racket[#f]。

另见 @racket[immutable-string?] 和 @racket[mutable-string?]。

@mz-examples[(string? "Apple") (string? 'apple)]}


@defproc[(make-string [k exact-nonnegative-integer?] [char char?
#\nul]) string?]{ 返回一个新的可变字符串，长度为 @racket[k]，每个位置用字符 @racket[char] 初始化。

@mz-examples[(make-string 5 #\\z)]}


@defproc[(string [char char?] ...) string?]{ 返回一个新的可变字符串，长度等于给定的 @racket[char] 的数量，各位置用给定的 @racket[char] 初始化。

@mz-examples[(string #\\A #\\p #\\p #\\l #\\e)]}


@defproc[(string->immutable-string [str string?]) (and/c string? immutable?)]{
 返回一个不可变字符串，内容与 @racket[str] 相同。如果 @racket[str] 本身不可变，则返回 @racket[str] 自身。

@mz-examples[
(immutable? (string #\\H #\\e #\\l #\\l #\\o))
(immutable? (string->immutable-string (string #\\H #\\e #\\l #\\l #\\o)))
]}


@defproc[(string-length [str string?]) exact-nonnegative-integer?]{
 返回 @racket[str] 的长度。

@mz-examples[(string-length "Apple")]}


@defproc[(string-ref [str string?] [k exact-nonnegative-integer?])
 char?]{  返回 @racket[str] 中位置 @racket[k] 的字符。第一个位置对应 @racket[0]，所以 @racket[k] 必须小于字符串的长度，否则引发 @exnraise[exn:fail:contract]。

@mz-examples[(string-ref "Apple" 0)]}


@defproc[(string-set! [str (and/c string? (not/c immutable?))] [k
 exact-nonnegative-integer?] [char char?]) void?]{  将
 @racket[str] 中位置 @racket[k] 的字符修改为 @racket[char]。第一个
 位置对应 @racket[0]，所以 @racket[k] 必须小于字符串的长度，否则
 引发 @exnraise[exn:fail:contract]。

@examples[(define s (string #\\A #\\p #\\p #\\l #\\e))
          (string-set! s 4 #\\y)
          s]}


@defproc[(substring [str string?] 
                    [start exact-nonnegative-integer?]
                    [end exact-nonnegative-integer? (string-length str)]) string?]{
 返回一个新的可变字符串，长度为 @racket[(- end start)]
 字符，包含 @racket[str] 中从 @racket[start]（含）到 @racket[end]（不含）的字符。第一个位置对应 @racket[0]，所以 @racket[start] 和 @racket[end] 参数必须小于等于 @racket[str] 的长度，且 @racket[end] 必须大于等于 @racket[start]，否则引发 @exnraise[exn:fail:contract]。

@mz-examples[(substring "Apple" 1 3)
             (substring "Apple" 1)]}


@defproc[(string-copy [str string?]) string?]{ 返回 @racket[(substring str 0)]。
@examples[(define s1 "Yui")
          (define pilot (string-copy s1))
          (list s1 pilot)
          (for ([i (in-naturals)] [ch '(#\\R #\\e #\\i)])
            (string-set! pilot i ch))
          (list s1 pilot)]
}


@defproc[(string-copy! [dest (and/c string? (not/c immutable?))]
                       [dest-start exact-nonnegative-integer?]
                       [src string?]
                       [src-start exact-nonnegative-integer? 0]
                       [src-end exact-nonnegative-integer? (string-length src)])
         void?]{

 修改 @racket[dest] 中从位置 @racket[dest-start] 开始的字符，
 使其与 @racket[src] 中从 @racket[src-start]（含）到 @racket[src-end]（不含）的字符一致，
 其中第一个位置对应 @racket[0]。
 @racket[dest] 和 @racket[src] 可以是同一个字符串，
 这种情况下目标区域可以与源区域重叠；复制后目标中的字符与复制前源中的字符一致。如果 @racket[dest-start]、
 @racket[src-start] 或 @racket[src-end] 中任何一个超出范围（考虑
 字符串的大小以及源和目标区域），将引发 @exnraise[exn:fail:contract]。

@mz-examples[(define s (string #\\A #\\p #\\p #\\l #\\e))
             (string-copy! s 4 "y")
             (string-copy! s 0 s 3 4)
             s]}

@defproc[(string-fill! [dest (and/c string? (not/c immutable?))] [char
 char?]) void?]{ 修改 @racket[dest]，使其中每个位置都用 @racket[char] 填充。

@mz-examples[(define s (string #\\A #\\p #\\p #\\l #\\e))
             (string-fill! s #\\q)
             s]}


@defproc[(string-append [str string?] ...) string?]{

@index['("strings" "concatenate")]{返回} 一个新的可变字符串，长度等于所有给定的 @racket[str] 长度的总和，包含给定的 @racket[str] 连接后的字符。如果未提供任何 @racket[str]，结果是一个长度为零的字符串。

@mz-examples[(string-append "Apple" "Banana")]}


@defproc[(string-append-immutable [str string?] ...) (and/c string? immutable?)]{

 与 @racket[string-append] 相同，但结果是一个不可变字符串。

@mz-examples[(string-append-immutable "Apple" "Banana")
             (immutable? (string-append-immutable "A" "B"))]

@history[#:added "7.5.0.14"]}


@defproc[(string->list [str string?]) (listof char?)]{ 返回一个新的字符列表，对应于 @racket[str] 的内容。即，列表长度为 @racket[(string-length str)]，@racket[str] 中的字符序列与结果列表中的序列相同。

@mz-examples[(string->list "Apple")]}


@defproc[(list->string [lst (listof char?)]) string?]{ 返回一个新的可变字符串，内容为 @racket[lst] 中的字符列表。即，字符串长度为 @racket[(length lst)]，@racket[lst] 中的字符序列与结果字符串中的序列相同。

@mz-examples[(list->string (list #\\A #\\p #\\p #\\l #\\e))]}


@defproc[(build-string [n exact-nonnegative-integer?]
                       [proc (exact-nonnegative-integer? . -> . char?)])
         string?]{

 通过按顺序将 @racket[proc] 应用于从 @racket[0] 到 @racket[(sub1 n)] 的整数，创建一个包含 @racket[n] 个字符的字符串。如果 @racket[_str] 是结果字符串，则 @racket[(string-ref _str _i)] 是 @racket[(proc _i)] 产生的字符。

@mz-examples[
(build-string 5 (lambda (i) (integer->char (+ i 97))))
]}


@; ----------------------------------------
@section{String Comparisons}


@defproc[(string=? [str1 string?] [str2 string?] ...) boolean?]{ 
 如果所有参数都是 @racket[equal?] 的则返回 @racket[#t]。

@mz-examples[(string=? "Apple" "apple")
             (string=? "a" "as" "a")]

@history/arity[]}

@(define (string-sort direction folded?)
(if folded?
  @elem{类似于 @racket[string-ci<?]，但检查参数在 case folding 后会按 @direction 排序。}
  @elem{类似于 @racket[string<?]，但检查参数是否按 @|direction| 排序。}))

@defproc[(string<? [str1 string?] [str2 string?] ...) boolean?]{
 如果参数按字典序递增排序（单个字符按 @racket[char<?] 排序）则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(string<? "Apple" "apple")
             (string<? "apple" "Apple")
             (string<? "a" "b" "c")]

@history/arity[]}

@defproc[(string<=? [str1 string?] [str2 string?] ...) boolean?]{
 @string-sort["nondecreasing" #f]

@mz-examples[(string<=? "Apple" "apple")
             (string<=? "apple" "Apple")
             (string<=? "a" "b" "b")]

@history/arity[]}

@defproc[(string>? [str1 string?] [str2 string?] ...) boolean?]{
 @string-sort["decreasing" #f]

@mz-examples[(string>? "Apple" "apple")
             (string>? "apple" "Apple")
             (string>? "c" "b" "a")]

@history/arity[]}

@defproc[(string>=? [str1 string?] [str2 string?] ...) boolean?]{
 @string-sort["nonincreasing" #f]

@mz-examples[(string>=? "Apple" "apple")
             (string>=? "apple" "Apple")
             (string>=? "c" "b" "b")]

@history/arity[]}


@defproc[(string-ci=? [str1 string?] [str2 string?] ...) boolean?]{
 如果所有参数在通过 @racket[string-foldcase] 进行 locale 无关的 case folding 后是 @racket[equal?] 的则返回 @racket[#t]。

@mz-examples[(string-ci=? "Apple" "apple")
             (string-ci=? "a" "a" "a")]

@history/arity[]}

@defproc[(string-ci<? [str1 string?] [str2 string?] ...) boolean?]{
 类似于 @racket[string<?]，但检查参数在首先使用 @racket[string-foldcase]（它是 locale 无关的）进行 case folding 后是否按递增顺序排列。

@mz-examples[(string-ci<? "Apple" "apple")
             (string-ci<? "apple" "banana")
             (string-ci<? "a" "b" "c")]

@history/arity[]}

@defproc[(string-ci<=? [str1 string?] [str2 string?] ...) boolean?]{
 @string-sort["nondecreasing" #t]

@mz-examples[(string-ci<=? "Apple" "apple")
             (string-ci<=? "apple" "Apple")
             (string-ci<=? "a" "b" "b")]

@history/arity[]}

@defproc[(string-ci>? [str1 string?] [str2 string?] ...) boolean?]{
 @string-sort["decreasing" #t]

@mz-examples[(string-ci>? "Apple" "apple")
             (string-ci>? "banana" "Apple")
             (string-ci>? "c" "b" "a")]

@history/arity[]}

@defproc[(string-ci>=? [str1 string?] [str2 string?] ...) boolean?]{
 @string-sort["nonincreasing" #t]

@mz-examples[(string-ci>=? "Apple" "apple")
             (string-ci>=? "apple" "Apple")
             (string-ci>=? "c" "b" "b")]

@history/arity[]}

@; ----------------------------------------
@section{String Conversions}

@defproc[(string-upcase [str string?]) string?]{
 @index['("strings" "upper-case")]{@index['("strings" "uppercase")]{返回}} 将 @racket[str] 中的字符进行大写转换后的字符串。转换使用 Unicode 的 locale 无关的转换规则，将码点序列映射到码点序列（而不是简单地在字符串上对码点使用一对一函数映射），因此转换产生的字符串可能比输入字符串长。

@mz-examples[
(string-upcase "abc!")
(string-upcase "Stra\\xDFe")
]}

@defproc[(string-downcase [string string?]) string?]{
 @index['("strings" "lower-case")]{@index['("strings" "lowercase")]{类似于}} @racket[string-upcase]，但进行小写转换。

@mz-examples[
(string-downcase "aBC!")
(string-downcase "Stra\\xDFe")
(string-downcase "\\u039A\\u0391\\u039F\\u03A3")
(string-downcase "\\u03A3")
]}


@defproc[(string-titlecase [string string?]) string?]{ 类似于
 @racket[string-upcase]，但仅对 @racket[str] 中每个带大小写字符序列的第一个字符进行 titlecase 转换
 （忽略 case-ignorable 字符）。

@mz-examples[
(string-titlecase "aBC  twO")
(string-titlecase "y2k")
(string-titlecase "main stra\\xDFe")
(string-titlecase "stra \\xDFe")
]}

@defproc[(string-foldcase [string string?]) string?]{ 类似于
 @racket[string-upcase]，但进行 case-folding 转换。

@mz-examples[
(string-foldcase "aBC!")
(string-foldcase "Stra\\xDFe")
(string-foldcase "\\u039A\\u0391\\u039F\\u03A3")
]}

@defproc[(string-normalize-nfd [string string?]) string?]{ 返回
 是 @racket[string] 的 Unicode normalized form D 的字符串。如果给定的字符串已经处于相应的 Unicode normal form，
 字符串可能直接返回作为结果（而不是新分配的字符串）。

@mz-examples[
(equal? (string-normalize-nfd "Ç") "C\\u0327")
]}

@defproc[(string-normalize-nfkd [string string?]) string?]{ 类似于 @racket[string-normalize-nfd]，但针对 normalized form KD。

@mz-examples[
(equal? (string-normalize-nfkd "ℌ") "H")
]}

@defproc[(string-normalize-nfc [string string?]) string?]{ 类似于 @racket[string-normalize-nfd]，但针对 normalized form C。

@mz-examples[
(equal? (string-normalize-nfc "C\\u0327") "Ç")
]}

@defproc[(string-normalize-nfkc [string string?]) string?]{ 类似于 @racket[string-normalize-nfd]，但针对 normalized form KC。

@mz-examples[
(equal? (string-normalize-nfkc "ℋ̧") "Ḩ")
]}

@; ----------------------------------------
@section{Locale-Specific String Operations}

@defproc[(string-locale=? [str1 string?] [str2 string?] ...)
 boolean?]{  类似于 @racket[string=?]，但字符串以特定于 locale 的方式比较，基于 @racket[current-locale] 的值。
 参见 @secref["encodings"] 了解关于 locale 的更多信息。

@history/arity[]}

@defproc[(string-locale<? [str1 string?] [str2 string?] ...+) boolean?]{
 类似于 @racket[string<?]，但排序顺序以特定于 locale 的方式比较字符串，基于 @racket[current-locale] 的值。
 特别是，排序顺序可能不是简单地对字符排序的字典扩展。

@history/arity[]}

@defproc[(string-locale>? [str1 string?] [str2 string?] ...)
 boolean?]{  类似于 @racket[string>?]，但特定于 locale 如同
 @racket[string-locale<?]。

@history/arity[]}

@defproc[(string-locale-ci=? [str1 string?] [str2 string?] ...)
 boolean?]{  类似于 @racket[string-locale=?]，但字符串使用特定于 locale 且不区分大小写的规则进行比较
 （取决于当前 locale 下 "case-insensitive" 的含义）。

@history/arity[]}

@defproc[(string-locale-ci<? [str1 string?] [str2 string?] ...)
 boolean?]{  类似于 @racket[string<?]，但使用特定于 locale 且不区分大小写的规则如同 @racket[string-locale-ci=?]。

@history/arity[]}

@defproc[(string-locale-ci>? [str1 string?] [str2 string?] ...)
 boolean?]{  类似于 @racket[string>?]，但使用特定于 locale 且不区分大小写的规则如同 @racket[string-locale-ci=?]。

@history/arity[]}

@defproc[(string-locale-upcase [string string?]) string?]{ 类似于 @racket[string-upcase]，但使用基于 @racket[current-locale] 值的特定于 locale 的大小写转换规则。}

@defproc[(string-locale-downcase [string string?]) string?]{ 类似于 @racket[string-downcase]，但使用基于 @racket[current-locale] 值的特定于 locale 的大小写转换规则。}


@; ----------------------------------------
@section{String Grapheme Clusters}

@defproc[(string-grapheme-span [str string?] 
                               [start exact-nonnegative-integer?]
                               [end exact-nonnegative-integer? (string-length str)])
         exact-nonnegative-integer?]{

 返回字符串中从 @racket[start] 开始的 Unicode 簇（假设 @racket[start] 是簇的起点）所包含的字符（即码点）数量，延伸至 @racket[end] 前的字符为止。如果 @racket[start] 等于 @racket[end]，结果为 @racket[0]。

 @racket[start] 和 @racket[end] 参数必须是与 @racket[substring] 中一样有效的索引，否则引发 @exnraise[exn:fail:contract]。

 另见 @racket[char-grapheme-cluster-step]。

@mz-examples[
(string-grapheme-span "" 0)
(string-grapheme-span "a" 0)
(string-grapheme-span "ab" 0)
(string-grapheme-span "\\r\\n" 0)
(string-grapheme-span "\\r\\nx" 0)
(string-grapheme-span "\\r\\nx" 2)
(string-grapheme-span "\\r\\nx" 0 1)
]

@history[#:added "8.6.0.2"]}

@defproc[(string-grapheme-count [str string?] 
                                [start exact-nonnegative-integer?]
                                [end exact-nonnegative-integer? (string-length str)])
         exact-nonnegative-integer?]{

 返回 @racket[(substring str start end)] 中的簇数量。

 @racket[start] 和 @racket[end] 参数必须是与 @racket[substring] 中一样有效的索引，否则引发 @exnraise[exn:fail:contract]。

@mz-examples[
(string-grapheme-count "")
(string-grapheme-count "a")
(string-grapheme-count "ab")
(string-grapheme-count "ab" 0 2)
(string-grapheme-count "ab" 0 1)
(string-grapheme-count "\\r\\n")
(string-grapheme-count "a\\r\\nb")
]

@history[#:added "8.6.0.2"]}

@; ----------------------------------------
@section{Additional String Functions}

@note-lib[racket/string]
@(define string-eval (make-base-eval))
@examples[#:hidden #:eval string-eval (require racket/string racket/list)]

@defproc[(string-append* [str string?] ... [strs (listof string?)]) string?]{
@; Note: this is exactly the same description as the one for append*

 类似于 @racket[string-append]，但最后一个参数用作 @racket[string-append] 的参数列表，因此 @racket[(string-append* str ... strs)] 与 @racket[(apply string-append str ... strs)] 相同。换句话说，@racket[string-append] 和 @racket[string-append*] 之间的关系类似于 @racket[list] 和 @racket[list*] 之间的关系。

@mz-examples[#:eval string-eval
  (string-append* "a" "b" '("c" "d"))
  (string-append* (cdr (append* (map (lambda (x) (list ", " x))
                                     '("Alpha" "Beta" "Gamma")))))
]}


@defproc[(string-join [strs (listof string?)] [sep string? " "]
                      [#:before-first before-first string? ""]
                      [#:before-last  before-last  string? sep]
                      [#:after-last   after-last   string? ""])
         string?]{

 将 @racket[strs] 中的字符串进行连接，在每对字符串之间插入 @racket[sep]。@racket[before-last]、@racket[before-first] 和 @racket[after-last] 类比 @racket[add-between] 的输入：它们指定最后两个字符串之间的交替分隔符、前缀字符串和后缀字符串。

@mz-examples[#:eval string-eval
  (string-join '("one" "two" "three" "four"))
  (string-join '("one" "two" "three" "four") ", ")
  (string-join '("one" "two" "three" "four") " potato ")
  (string-join '("x" "y" "z") ", "
               #:before-first "Todo: "
               #:before-last " and "
               #:after-last ".")
]}


@defproc[(string-normalize-spaces [str string?]
                                  [sep (or/c string? regexp?) #px"\\s+"]
                                  [space string? " "]
                                  [#:trim? trim? any/c #t]
                                  [#:repeat? repeat? any/c #f])
         string?]{

 通过首先使用 @racket[string-trim] 和 @racket[sep] 修剪 @racket[str]，然后将结果中的所有 @racket[seq] 序列替换为 @racket[space]（默认为单个空格），规范化输入 @racket[str] 中的空格。

@mz-examples[#:eval string-eval
  (string-normalize-spaces "  foo bar  baz \\r\\n\\t")
]

 @racket[(string-normalize-spaces str sep space)] 的结果与 @racket[(string-join (string-split str sep ....) space)] 相同。}


@defproc[(string-replace [str  string?]
                         [from (or/c string? regexp?)]
                         [to   string?]
                         [#:all? all? any/c #t])
         string?]{

 返回 @racket[str] 中所有 @racket[from] 出现的位置被 @racket[to] 替换后的结果。如果 @racket[from] 是字符串，则进行字面值匹配（而不是用作 @tech{regular expression}）。

 默认情况下，所有出现的位置都会被替换，但如果 @racket[all?] 为 @racket[#f]，则仅替换第一个匹配项。

@mz-examples[#:eval string-eval
  (string-replace "foo bar baz" "bar" "blah")
]}


@defproc[(string-split [str string?]
                       [sep (or/c string? regexp?) #px"\\s+"]
                       [#:trim? trim? any/c #t]
                       [#:repeat? repeat? any/c #f])
         (listof string?)]{

 在 @racket[sep] 上分割输入 @racket[str]，返回由 @racket[sep] 分隔的 @racket[str] 子串列表，默认在空白字符处分割。输入首先使用 @racket[sep] 修剪（见 @racket[string-trim]），除非 @racket[trim?] 为 @racket[#f]。空匹配项按 @racket[regexp-split] 的方式处理。特殊情况下，如果 @racket[str] 在修剪后是空字符串，则结果为 @racket['()] 而不是 @racket['("")]。

 类似于 @racket[string-trim]，提供 @racket[sep] 以使用不同的分隔符，@racket[repeat?] 控制重复序列的匹配。

@mz-examples[#:eval string-eval
  (string-split "  foo bar  baz \\r\\n\\t")
  (string-split "  ")
  (string-split "  " #:trim? #f)
]}


@defproc[(string-trim [str string?]
                      [sep (or/c string? regexp?) #px"\\s+"]
                      [#:left? left? any/c #t]
                      [#:right? right? any/c #t]
                      [#:repeat? repeat? any/c #f])
         string?]{

 通过移除与 @racket[sep] 匹配的前缀和后缀来修剪输入 @racket[str]，其中 @racket[sep] 默认为匹配空白字符。字符串 @racket[sep] 以字面值方式匹配（而不是用作 @tech{regular expression}）。

 使用 @racket[#:left? #f] 或 @racket[#:right? #f] 抑制对应侧的修剪。当 @racket[repeat?] 为 @racket[#f]（默认）时，每侧仅移除一个匹配项；当 @racket[repeat?] 为 true 时，修剪所有初始或尾随匹配项（这替代了使用包含 @litchar{+} 的 @tech{regular expression} @racket[sep]）。

 当修剪字符串的左右两端时，两个匹配操作都在原始字符串上执行，而不是先在左端修剪再在右端修剪。如果左右匹配重叠，则修剪后的结果字符串为空。

@mz-examples[#:eval string-eval
  (string-trim "  foo bar  baz \\r\\n\\t")
  (string-trim "  foo bar  baz \\r\\n\\t" " " #:repeat? #t)
  (string-trim "aaaxaayaa" "aa")
]}

@defproc[(non-empty-string? [x any/c]) boolean?]{
 如果 @racket[x] 是字符串且不为空则返回 @racket[#t]；否则返回 @racket[#f]。
@history[#:added "6.3"]{}}

@deftogether[(
@defproc[(string-find [s string?] [contained string?]) (or/c exact-nonnegative-integer? #f)]
@defproc[(string-contains? [s string?] [contained string?]) boolean?]
@defproc[(string-prefix? [s string?] [prefix string?]) boolean?]
@defproc[(string-suffix? [s string?] [suffix string?]) boolean?])]{
 分别检查 @racket[s] 是否包含第二个参数、以前缀开头或以后缀结尾。@racket[string-find] 函数返回 @racket[s] 中 @racket[contained] 的首次出现位置（如果有），而 @racket[string-contains?] 仅报告是否找到。

@mz-examples[#:eval string-eval
  (string-prefix? "Racket" "R")
  (string-prefix? "Jacket" "R")
  (string-suffix? "Racket" "et")
  (string-find "Racket" "ack")
  (string-contains? "Racket" "ack")
]

@history[#:added "6.3"
         #:changed "8.15.0.7" @elem{添加了 @racket[string-find]。}]
}


@; ----------------------------------------
@include-section["format.scrbl"]

@; ----------------------------------------
@close-eval[string-eval]
