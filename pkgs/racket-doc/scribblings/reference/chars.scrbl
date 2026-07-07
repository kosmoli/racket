#lang scribble/doc
@(require "mz.rkt")

@(define (UCat x) x)

@title[#:tag "characters"]{Characters}

@guideintro["characters"]{characters}

@deftech{Characters} 涵盖 Unicode @index['("scalar value")] 标量值，包括值范围从 @racketvalfont{#x0} 到 @racketvalfont{#x10FFFF} 的字符，但不包括 @racketvalfont{#xD800} 到 @racketvalfont{#xDFFF}。标量值是 Unicode @index['("code point")] code points 的子集。

两个字符是 @racket[equal?]、@racket[eqv?] 和 @racket[eq?]，当且仅当它们对应于相同的标量值。

@see-read-print["character"]{characters}

@history[#:changed "9.0.0.10" @elem{保证 @racket[equal?] 的字符也是 @racket[eq?]。}]

@; ----------------------------------------
@section{Characters and Scalar Values}

@defproc[(char? [v any/c]) boolean?]{

如果 @racket[v] 是字符，返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(char->integer [char char?]) exact-integer?]{

返回字符的 code-point 编号。

@mz-examples[(char->integer #\A)]}


@defproc[(integer->char [k (and/c exact-integer?
                                  (or/c (integer-in 0 @#,racketvalfont{#xD7FF})
                                        (integer-in @#,racketvalfont{#xE000} @#,racketvalfont{#x10FFFF})))])
         char?]{

返回 code-point 编号为 @racket[k] 的字符。对于小于 @racket[256] 的 @racket[k]，相同 @racket[k] 的结果是相同对象。

@mz-examples[(integer->char 65)]}


@defproc[(char-utf-8-length [char char?]) (integer-in 1 6)]{

产生与 @racket[(bytes-length (string->bytes/utf-8 (string char)))] 相同的结果。}


@; ----------------------------------------
@section{Character Comparisons}

@defproc[(char=? [char1 char?] [char2 char?] ...) boolean?]{

如果所有参数都是 @racket[eqv?]，返回 @racket[#t]。

@mz-examples[(char=? #\a #\a)
          (char=? #\a #\A #\a)]

@history/arity[]}

@(define (char-sort direction folded?)
   (if folded?
     @elem{类似于 @racket[char-ci<?]，但检查参数在 case-folding 后是否为 @direction 顺序。}
     @elem{类似于 @racket[char<?]，但检查参数是否为 @|direction| 顺序。}))

@defproc[(char<? [char1 char?] [char2 char?] ...) boolean?]{

如果参数按标量值升序排列，返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(char<? #\A #\a)
             (char<? #\a #\A)
             (char<? #\a #\b #\c)]

@history/arity[]}

@defproc[(char<=? [char1 char?] [char2 char?] ...) boolean?]{
 @char-sort["nondecreasing" #f]

@mz-examples[(char<=? #\A #\a)
             (char<=? #\a #\A)
             (char<=? #\a #\b #\b)]

@history/arity[]}

@defproc[(char>? [char1 char?] [char2 char?] ...) boolean?]{
 @char-sort["decreasing" #f]

@mz-examples[(char>? #\A #\a)
             (char>? #\a #\A)
             (char>? #\c #\b #\a)]

@history/arity[]}

@defproc[(char>=? [char1 char?] [char2 char?] ...) boolean?]{
 @char-sort["nonincreasing" #f]

@mz-examples[(char>=? #\A #\a)
             (char>=? #\a #\A)
             (char>=? #\c #\b #\b)]

@history/arity[]}


@defproc[(char-ci=? [char1 char?] [char2 char?] ...) boolean?]{
 如果所有参数在通过 @racket[char-foldcase] 进行 locale-insensitive case-folding 后是 @racket[eqv?]，返回 @racket[#t]。

@mz-examples[(char-ci=? #\A #\a)
             (char-ci=? #\a #\a #\a)]

@history/arity[]}

@defproc[(char-ci<? [char1 char?] [char2 char?] ...) boolean?]{
 类似于 @racket[char<?]，但检查每个参数在使用 @racket[char-foldcase]（locale-insensitive）case-folding 后是否为升序。

@mz-examples[(char-ci<? #\A #\a)
             (char-ci<? #\a #\b)
             (char-ci<? #\a #\b #\c)]

@history/arity[]}

@defproc[(char-ci<=? [char1 char?] [char2 char?] ...) boolean?]{
 @char-sort["nondecreasing" #t]

@mz-examples[(char-ci<=? #\A #\a)
             (char-ci<=? #\a #\A)
             (char-ci<=? #\a #\b #\b)]

@history/arity[]}

@defproc[(char-ci>? [char1 char?] [char2 char?] ...) boolean?]{
 @char-sort["decreasing" #t]

@mz-examples[(char-ci>? #\A #\a)
             (char-ci>? #\b #\A)
             (char-ci>? #\c #\b #\a)]

@history/arity[]}

@defproc[(char-ci>=? [char1 char?] [char2 char?] ...) boolean?]{
 @char-sort["nonincreasing" #t]

@mz-examples[(char-ci>=? #\A #\a)
             (char-ci>=? #\a #\A)
             (char-ci>=? #\c #\b #\b)]

@history/arity[]}

@; ----------------------------------------
@section{Classifications}

@defproc[(char-alphabetic? [char char?]) boolean?]{

如果 @racket[char] 具有 Unicode "Alphabetic" 属性，返回 @racket[#t]。}

@defproc[(char-lower-case? [char char?]) boolean?]{

如果 @racket[char] 具有 Unicode "Lowercase" 属性，返回 @racket[#t]。}


@defproc[(char-upper-case? [char char?]) boolean?]{

如果 @racket[char] 具有 Unicode "Uppercase" 属性，返回 @racket[#t]。}

@defproc[(char-title-case? [char char?]) boolean?]{

如果 @racket[char] 的 Unicode 通用类别是 @UCat{Lt}，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(char-numeric? [char char?]) boolean?]{

如果 @racket[char] 具有不是 @litchar{None} 的 Unicode "Numeric_Type" 属性值，返回 @racket[#t]。}

@defproc[(char-symbolic? [char char?]) boolean?]{

如果 @racket[char] 的 Unicode 通用类别是 @UCat{Sm}、@UCat{Sc}、@UCat{Sk} 或 @UCat{So}，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(char-punctuation? [char char?]) boolean?]{

如果 @racket[char] 的 Unicode 通用类别是 @UCat{Pc}、@UCat{Pd}、@UCat{Ps}、@UCat{Pe}、@UCat{Pi}、@UCat{Pf} 或 @UCat{Po}，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(char-graphic? [char char?]) boolean?]{

如果 @racket[char] 的 Unicode 通用类别是 @UCat{Ll}、@UCat{Lm}、@UCat{Lo}、@UCat{Lt}、@UCat{Lu}、@UCat{Nd}、@UCat{Nl}、@UCat{No}、@UCat{Mn}、@UCat{Mc} 或 @UCat{Me}，或者以下任一过程应用于 @racket[char] 产生 @racket[#t]：@racket[char-alphabetic?]、@racket[char-numeric?]、@racket[char-symbolic?] 或 @racket[char-punctuation?]，则返回 @racket[#t]。}

@defproc[(char-whitespace? [char char?]) boolean?]{

如果 @racket[char] 具有 Unicode "White_Space" 属性，返回 @racket[#t]。}

@defproc[(char-blank? [char char?]) boolean?]{

如果 @racket[char] 的 Unicode 通用类别是 @UCat{Zs} 或 @racket[char] 是 @racket[#\tab]，返回 @racket[#t]。（这些对应于水平空白字符。）}

@defproc[(char-iso-control? [char char?]) boolean?]{

如果 @racket[char] 在 @racket[#\u0000] 和 @racket[#\u001F] 之间（含）或 @racket[#\u007F] 和 @racket[#\u009F] 之间（含），返回 @racket[#t]。}

@defproc[(char-extended-pictographic? [char char?]) boolean?]{

如果 @racket[char] 具有 Unicode "Extended_Pictographic" 属性，返回 @racket[#t]。

@history[#:added "8.6.0.1"]}

@defproc[(char-general-category [char char?]) symbol?]{

返回一个符号，表示字符的 Unicode 通用类别，即 @indexed-racket['lu]、@indexed-racket['ll]、@indexed-racket['lt]、@indexed-racket['lm]、@indexed-racket['lo]、@indexed-racket['mn]、@indexed-racket['mc]、@indexed-racket['me]、@indexed-racket['nd]、@indexed-racket['nl]、@indexed-racket['no]、@indexed-racket['ps]、@indexed-racket['pe]、@indexed-racket['pi]、@indexed-racket['pf]、@indexed-racket['pd]、@indexed-racket['pc]、@indexed-racket['po]、@indexed-racket['sc]、@indexed-racket['sm]、@indexed-racket['sk]、@indexed-racket['so]、@indexed-racket['zs]、@indexed-racket['zp]、@indexed-racket['zl]、@indexed-racket['cc]、@indexed-racket['cf]、@indexed-racket['cs]、@indexed-racket['co] 或 @indexed-racket['cn]。}

@defproc[(char-grapheme-break-property [char char?]) ?]{

返回 @racket[char] 的 Unicode grapheme-break 属性，即 @indexed-racket['Other]、@indexed-racket['CR]、@indexed-racket['LF]、@indexed-racket['Control]、@indexed-racket['Extend]、@indexed-racket['ZWJ]、@indexed-racket['Regional_Indicator]、@indexed-racket['Prepend]、@indexed-racket['SpacingMark]、@indexed-racket['L]、@indexed-racket['V]、@indexed-racket['T]、@indexed-racket['LV] 或 @indexed-racket['LVT]。

@history[#:added "8.6.0.1"]}

@defproc[(make-known-char-range-list) 
         (listof (list/c exact-nonnegative-integer?
                         exact-nonnegative-integer?
                         boolean?))]{

生成一个三元素列表的列表，其中每个三元素列表表示 Unicode 标准指定了字符属性的一组连续 code points。每个三元素列表包含两个整数和一个布尔值；第一个整数是起始 code-point 值（含），第二个整数是结束 code-point 值（含），布尔值在 code-point 范围内所有字符对所有上述字符谓词具有相同结果、具有类似转换（在 code-point 空间中移位相同数量（如果有的话））用于 @racket[char-downcase]、@racket[char-upcase] 和 @racket[char-titlecase]，并且具有相同的 decomposition-normalization 行为时为 @racket[#t]。
三元素列表在整体结果列表中排序，使得后面的列表表示更大的 code-point 值，并且所有三元素列表之间至少有一个未被 Unicode 指定的 code-point 值分隔。}


@; ----------------------------------------
@section{Character Conversions}

@defproc[(char-upcase [char char?]) char?]{

根据 Unicode 定义的 1 对 1 code point 映射产生一个字符。如果 @racket[char] 没有 upcase 映射，@racket[char-upcase] 产生 @racket[char]。

@margin-note{String 过程（如 @racket[string-upcase]）处理 Unicode 定义了从 code point 到 code-point 序列的 locale-independent 映射（除了标量值上的 1-1 映射）的情况。}

@mz-examples[
(char-upcase #\a)
(char-upcase #\u03BB)
(char-upcase #\space)
]}


@defproc[(char-downcase [char char?]) char?]{

类似于 @racket[char-upcase]，但用于 Unicode downcase 映射。

@mz-examples[
(char-downcase #\A)
(char-downcase #\u039B)
(char-downcase #\space)
]}

@defproc[(char-titlecase [char char?]) char?]{

类似于 @racket[char-upcase]，但用于 Unicode titlecase 映射。

@mz-examples[
(char-upcase #\a)
(char-upcase #\u03BB)
(char-upcase #\space)
]}

@defproc[(char-foldcase [char char?]) char?]{

类似于 @racket[char-upcase]，但用于 Unicode case-folding 映射。

@mz-examples[
(char-foldcase #\A)
(char-foldcase #\u03A3)
(char-foldcase #\u03c2)
(char-foldcase #\space)
]}

@; ----------------------------------------
@section{Character Grapheme-Cluster Streaming}

@defproc[(char-grapheme-step [char char?]
                             [state fixnum?])
         (values boolean? fixnum?)]{

为 Unicode 的 grapheme-cluster 规范在 code point 序列上编码一个状态机。它接受序列中下一个 code point 对应的字符，并返回两个值：自最近报告的终止（或流的开始）以来，是否有一个（单个）grapheme cluster 已终止，以及一个与 @racket[char-grapheme-step] 和下一个字符一起使用的新状态。

@racket[state] 值为 @racket[0] 表示初始状态或没有字符等待新边界的状态。因此，如果字符序列已耗尽且累积的 @racket[state] 不是 @racket[0]，则流的最后一个字符创建最后一个 grapheme-cluster 边界。当 @racket[char-grapheme-step] 的第一个结果为真值且第二个结果为非 @racket[0] 值时，给定的 @racket[char] 必须是唯一等待下一个 grapheme cluster 的字符（根据 Unicode grapheme clustering 的规则）。

@racket[char-grapheme-step] 过程对任何 fixnum @scheme[state] 都会产生结果，但非 @racket[0] @scheme[state] 的含义仅在于：提供这样一个由 @racket[char-grapheme-step] 在另一次调用中产生的状态，会继续检测序列中的 grapheme-cluster 边界。

另请参见 @racket[string-grapheme-span] 和 @racket[string-grapheme-count]。

@mz-examples[
(char-grapheme-step #\a 0)
(let*-values ([(consumed? state) (char-grapheme-step #\a 0)]
              [(consumed? state) (char-grapheme-step #\b state)])
  (values consumed? state))
(let*-values ([(consumed? state) (char-grapheme-step #\return 0)]
              [(consumed? state) (char-grapheme-step #\newline state)])
  (values consumed? state))
(eval:alts
 (let*-values ([(consumed? state) (char-grapheme-step #\a 0)]
               [(consumed? state) (char-grapheme-step @#,racketvalfont{#\u300} state)])
   (values consumed? state))
 (let*-values ([(consumed? state) (char-grapheme-step #\a 0)]
               [(consumed? state) (char-grapheme-step #\u300 state)])
   (values consumed? state)))
]

@history[#:added "8.6.0.2"]}

