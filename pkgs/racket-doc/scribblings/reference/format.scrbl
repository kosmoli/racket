#lang scribble/doc
@(require scribble/manual
          scribble/struct
          "mz.rkt"
          (for-label racket/contract
                     racket/math
                     racket/format
                     racket/string))

@(begin
  (define the-eval (make-base-eval))
  (the-eval '(require racket/math racket/format)))

@title[#:tag "format"]{将值转换为字符串}

@note-lib[racket/format]

@racketmodname[racket/format] 库提供将 Racket 值转换为字符串的函数。除了填充和数字格式化等特性外，这些函数的优点在于比 @racket[format]（带格式字符串）、@racket[number->string] 或 @racket[string-append] 更简短。

@defproc[(~a [v any/c] ...
             [#:separator separator string? ""]
             [#:width width (or/c exact-nonnegative-integer? #f) #f]
             [#:max-width max-width (or/c exact-nonnegative-integer? +inf.0) (or width +inf.0)]
             [#:min-width min-width exact-nonnegative-integer? (or width 0)]
             [#:limit-marker limit-marker string? ""]
             [#:limit-prefix? limit-prefix? boolean? #f]
             [#:align align (or/c 'left 'center 'right) 'left]
             [#:pad-string pad-string non-empty-string? " "]
             [#:left-pad-string left-pad-string non-empty-string? pad-string]
             [#:right-pad-string right-pad-string non-empty-string? pad-string])
         string?]{

将每个 @racket[v] 以 @racket[display] 模式转换为字符串——即类似于 @racket[(format "~a" v)]——然后用 @racket[separator] 连接连续项的结果，最后将字符串填充或截断为至少 @racket[min-width] 个字符、至多 @racket[max-width] 个字符。

@examples[#:eval the-eval
(~a "north")
(~a 'south)
(~a #"east")
(~a #\w "e" 'st)
(~a (list "red" 'green #"blue"))
(~a 17)
(eval:alts (~a @#,(racketvalfont "#e1e20")) (~a #e1e20))
(~a pi)
(~a (expt 6.1 87))
]

@racket[~a] 函数主要适用于字符串、数字和其他原子数据。@racket[~v] 和 @racket[~s] 函数更适合复合数据。

设 @racket[_s] 为各 @racket[v] 加上分隔符后的连接字符串形式。若 @racket[_s] 长于 @racket[max-width] 个字符，则它被精确截断为 @racket[max-width] 个字符。若 @racket[_s] 短于 @racket[min-width] 个字符，则它被精确填充为 @racket[min-width] 个字符。否则原样返回 @racket[_s]。若 @racket[min-width] 大于 @racket[max-width]，则引发异常。

若 @racket[_s] 长于 @racket[max-width] 个字符，它会被截断，字符串末尾被替换为 @racket[limit-marker]。若 @racket[limit-marker] 长于 @racket[max-width]，则引发异常。若 @racket[limit-prefix?] 为 @racket[#t]，则截断字符串开头而非末尾。

@examples[#:eval the-eval
(~a "abcde" #:max-width 5)
(~a "abcde" #:max-width 4)
(~a "abcde" #:max-width 4 #:limit-marker "*")
(~a "abcde" #:max-width 4 #:limit-marker "...")
(~a "The quick brown fox" #:max-width 15 #:limit-marker "")
(~a "The quick brown fox" #:max-width 15 #:limit-marker "...")
(~a "The quick brown fox" #:max-width 15 #:limit-marker "..." #:limit-prefix? #f)
]

若 @racket[_s] 短于 @racket[min-width]，则将其填充为至少 @racket[min-width] 个字符。若 @racket[align] 为 @racket['left]，则只添加右填充；若 @racket[align] 为 @racket['right]，则只添加左填充；若 @racket[align] 为 @racket['center]，则添加大致等量的左填充和右填充。

填充指定为非空字符串。左填充由 @racket[left-pad-string] 的完整重复组成，后跟 @racket[left-pad-string] 的一个 @emph{前缀} 来填充剩余空间。相反，右填充由一个 @racket[right-pad-string] 的 @emph{后缀} 组成，后跟若干完整的 @racket[right-pad-string] 副本。因此左填充以 @racket[left-pad-string] 开头，右填充以 @racket[right-pad-string] 结尾。

@examples[#:eval the-eval
(~a "apple" #:min-width 20 #:align 'left)
(~a "pear" #:min-width 20 #:align 'left #:right-pad-string " .")
(~a "plum" #:min-width 20 #:align 'right #:left-pad-string ". ")
(~a "orange" #:min-width 20 #:align 'center
              #:left-pad-string "- " #:right-pad-string " -")
]

用 @racket[width] 同时设置 @racket[max-width] 和 @racket[min-width]，确保结果字符串精确为 @racket[width] 个字符长：

@examples[#:label #f #:eval the-eval
(~a "terse" #:width 6)
(~a "loquacious" #:width 6)
]}

@;{----------------------------------------}

@defproc[(~v [v any/c] ...
             [#:separator separator string? " "]
             [#:width width (or/c exact-nonnegative-integer? #f) #f]
             [#:max-width max-width (or/c exact-nonnegative-integer? +inf.0) (or width +inf.0)]
             [#:min-width min-width exact-nonnegative-integer? (or width 0)]
             [#:limit-marker limit-marker string? "..."]
             [#:limit-prefix? limit-prefix? boolean? #f]
             [#:align align (or/c 'left 'center 'right) 'left]
             [#:pad-string pad-string non-empty-string? " "]
             [#:left-pad-string left-pad-string non-empty-string? pad-string]
             [#:right-pad-string right-pad-string non-empty-string? pad-string])
         string?]{

类似 @racket[~a]，但每个值像 @racket[(format "~v" v)] 一样转换，默认分隔符为 @racket[" "]，默认定界标记为 @racket["..."]。

@examples[#:eval the-eval
(~v "north")
(~v 'south)
(~v #"east")
(~v #\w)
(~v (list "red" 'green #"blue"))
]

用 @racket[~v] 产生讨论文本中的 Racket 的值。

@examples[#:eval the-eval
(let ([nums (for/list ([i 10]) i)])
  (~a "The even numbers in " (~v nums)
      " are " (~v (filter even? nums)) "."))
]}

@;{----------------------------------------}

@defproc[(~s [v any/c] ...
             [#:separator separator string? " "]
             [#:width width (or/c exact-nonnegative-integer? #f) #f]
             [#:max-width max-width (or/c exact-nonnegative-integer? +inf.0) (or width +inf.0)]
             [#:min-width min-width exact-nonnegative-integer? (or width 0)]
             [#:limit-marker limit-marker string? "..."]
             [#:limit-prefix? limit-prefix? boolean? #f]
             [#:align align (or/c 'left 'center 'right) 'left]
             [#:pad-string pad-string non-empty-string? " "]
             [#:left-pad-string left-pad-string non-empty-string? pad-string]
             [#:right-pad-string right-pad-string non-empty-string? pad-string])
         string?]{

类似 @racket[~a]，但每个值像 @racket[(format "~s" v)] 一样转换，默认分隔符为 @racket[" "]，默认定界标记为 @racket["..."]。

@examples[#:eval the-eval
(~s "north")
(~s 'south)
(~s #"east")
(~s #\w)
(~s (list "red" 'green #"blue"))
]}

@;{----------------------------------------}

@defproc[(~e [v any/c] ...
             [#:separator separator string? " "]
             [#:width width (or/c exact-nonnegative-integer? #f) #f]
             [#:max-width max-width (or/c exact-nonnegative-integer? +inf.0) (or width +inf.0)]
             [#:min-width min-width exact-nonnegative-integer? (or width 0)]
             [#:limit-marker limit-marker string? "..."]
             [#:limit-prefix? limit-prefix? boolean? #f]
             [#:align align (or/c 'left 'center 'right) 'left]
             [#:pad-string pad-string non-empty-string? " "]
             [#:left-pad-string left-pad-string non-empty-string? pad-string]
             [#:right-pad-string right-pad-string non-empty-string? pad-string])
         string?]{

类似 @racket[~a]，但每个值像 @racket[(format "~e" v)] 一样转换，默认分隔符为 @racket[" "]，默认定界标记为 @racket["..."]。

@examples[#:eval the-eval
(~e "north")
(~e 'south)
(~e #"east")
(~e #\w)
(~e (list "red" 'green #"blue"))
]

}

@;{----------------------------------------}

@defproc[(~r   [x rational?]
               [#:sign sign
                       (or/c #f '+ '++ 'parens
                             (let ([ind (or/c string? (list/c string? string?))])
                               (list/c ind ind ind)))
                       #f]
               [#:base base
                       (or/c (integer-in 2 36) (list/c 'up (integer-in 2 36)))
                       10]
               [#:precision precision
                            (or/c exact-nonnegative-integer?
                                  (list/c '= exact-nonnegative-integer?))
                            6]
               [#:notation notation
                           (or/c 'positional 'exponential
                                 (-> rational? (or/c 'positional 'exponential)))
                           'positional]
               [#:format-exponent format-exponent
                (or/c #f string? (-> exact-integer? string?))
                #f]
               [#:min-width min-width exact-positive-integer? 1]
               [#:pad-string pad-string non-empty-string? " "]
               [#:groups groups (non-empty-listof exact-positive-integer?) '(3)]
               [#:group-sep group-sep string? ""]
               [#:decimal-sep decimal-sep string? ".")
         string?]{

将理数 @racket[x] 转换为位置记数法或指数记数法的字符串，具体取决于 @racket[notation]。@racket[x] 的确切性或不确性不影响其格式。

可选参数控制数字格式化：

@itemize[

@item{@racket[notation] —— 确定数字以位置记数法还是指数记数法打印。若 @racket[notation] 是函数，则将其应用于 @racket[x] 以获取使用的记数法。

@examples[#:eval the-eval
(~r 12345)
(~r 12345 #:notation 'exponential)
(let ([pick-notation
       (lambda (x)
         (if (or (< (abs x) 0.001) (> (abs x) 1000))
             'exponential
             'positional))])
  (for/list ([i (in-range 1 5)])
    (~r (expt 17 i) #:notation pick-notation)))
]}

@item{@racket[precision] —— 控制小数点后的位数（或更准确地说，@hyperlink["http://en.wikipedia.org/wiki/Radix_point"]{十进制小数点} 后的位数）。当 @racket[x] 以指数形式格式化时，@racket[precision] 应用于有效数字。

若 @racket[precision] 是自然数，则最多显示 @racket[precision] 位数字，但末尾的零会被丢弃；若小数点后的所有数字都被丢弃，则小数点也会被丢弃。若 @racket[precision] 为 @racket[(list '= _digits)]，则精确使用 @racket[_digits] 位小数，且小数点从不被丢弃。

@examples[#:eval the-eval
(~r pi)
(~r pi #:precision 4)
(~r pi #:precision 0)
(~r 1.5 #:precision 4)
(~r 1.5 #:precision '(= 4))
(~r 50 #:precision 2)
(~r 50 #:precision '(= 2))
(~r 50 #:precision '(= 0))
]}

@item{@racket[decimal-sep] 指定打印什么十进制分隔符。

@examples[#:eval the-eval
(~r 123.456)
(~r 123.456 #:decimal-sep ",")
]}

@item{@racket[groups] 控制数字整数部分的数位如何分组。
   @racket[groups] 中最右边的数字用于分组整数部分最右边的数位。
   @racket[groups] 中最左边的数字被重复用于分组最左边的数位。
   @racket[group-sep] 参数指定数位组之间使用的分隔符。


   @examples[#:eval the-eval
(~r 1234567890 #:groups '(3) #:group-sep ",")
(~r 1234567890 #:groups '(3 2) #:group-sep ",")
(~r 1234567890 #:groups '(1 3 2) #:group-sep "_")
]}

@item{@racket[min-width] —— 若 @racket[x] 的打印位数（包括小数点但不包括符号指示符）通常少于 @racket[min-width] 位，则使用 @racket[pad-string] 对数字进行左填充。

@examples[#:eval the-eval
(~r 17)
(~r 17 #:min-width 4)
(~r -42 #:min-width 4)
(~r 1.5 #:min-width 4)
(~r 1.5 #:precision 4 #:min-width 10)
(~r 1.5 #:precision '(= 4) #:min-width 10)
(eval:alts (~r @#,(racketvalfont "#e1e10") #:min-width 6)
           (~r #e1e10 #:min-width 6))
]}

@item{@racket[pad-string] —— 指定用于填充数字到至少 @racket[min-width] 个字符的字符串（不包括符号指示符）。填充被放置在符号和 @racket[x] 的正常数字之间。

@examples[#:eval the-eval
(~r 17 #:min-width 4 #:pad-string "0")
(~r -42 #:min-width 4 #:pad-string "0")
]}

@item{@racket[sign] —— 控制数字符号的表示方式：
  @itemlist[

  @item{若 @racket[sign] 为 @racket[#f]（默认值），当 @racket[x] 为正数或零时不生成符号输出，当 @racket[x] 为负数时前缀加负号。

  @examples[#:eval the-eval
  (for/list ([x '(17 0 -42)]) (~r x))
  ]}

  @item{若 @racket[sign] 为 @racket['+]，当 @racket[x] 为零时不生成符号输出，当 @racket[x] 为正数时前缀加加号，当 @racket[x] 为负数时前缀加负号。

  @examples[#:eval the-eval
  (for/list ([x '(17 0 -42)]) (~r x #:sign '+))
  ]}

  @item{若 @racket[sign] 为 @racket['++]，当 @racket[x] 为零或正数时前缀加加号，当 @racket[x] 为负数时前缀加负号。

  @examples[#:eval the-eval
  (for/list ([x '(17 0 -42)]) (~r x #:sign '++))
  ]}

  @item{若 @racket[sign] 为 @racket['parens]，当 @racket[x] 为零或正数时不生成符号输出，当 @racket[x] 为负数时将数字用括号括起来。

  @examples[#:eval the-eval
  (for/list ([x '(17 0 -42)]) (~r x #:sign 'parens))
  ]}

  @item{若 @racket[sign] 为 @racket[(list _pos-ind _zero-ind _neg-ind)]，则 @racket[_pos-ind]、@racket[_zero-ind] 和 @racket[_neg-ind] 分别用于指示正数、零和负数。每个指示符要么是用作前缀的字符串，要么是包含两个字符串的列表：一个前缀和一个后缀。

  @examples[#:eval the-eval
  (let ([sign-table '(("" " up") "an even " (""" down"))])
    (for/list ([x '(17 0 -42)]) (~r x #:sign sign-table)))
  ]

  默认行为等价于 @racket['("" "" "-")]；@racket['parens] 模式等价于 @racket['("" "" ("(" ")"))]。
  }
]}

@item{@racket[base] —— 控制 @racket[x] 格式化所使用的进制。若 @racket[base] 是大于 @racket[10] 的数字，则使用小写字母。若 @racket[base] 为 @racket[(list 'up _base*)] 且 @racket[_base*] 大于 @racket[10]，则使用大写字母。

@examples[#:eval the-eval
(~r 100 #:base 7)
(~r 4.5 #:base 2)
(~r 3735928559 #:base 16)
(~r 3735928559 #:base '(up 16))
(~r 3735928559 #:base '(up 16) #:notation 'exponential)
]}

@item{@racket[format-exponent] —— 确定指数的显示方式。

若 @racket[format-exponent] 是字符串，则指数以显式符号（如 @racket[sign] 为 @racket['++] 时）和至少两位数字显示，通过 "指数标记" @racket[format-exponent] 与有效数字分隔：

@examples[#:label #f #:eval the-eval
(~r 1234 #:notation 'exponential #:format-exponent "E")
]

若 @racket[format-exponent] 为 @racket[#f]，则 "指数标记" 为 @racket["e"]（当 @racket[base] 为 @racket[10] 时）或一个涉及 @racket[base] 的字符串：

@examples[#:label #f #:eval the-eval
(~r 1234 #:notation 'exponential)
(~r 1234 #:notation 'exponential #:base 8)
]

若 @racket[format-exponent] 是过程，则将其应用于指数并将结果字符串附加到有效数字：

@examples[#:label #f #:eval the-eval
(~r 1234 #:notation 'exponential
         #:format-exponent (lambda (e) (format "E~a" e)))
]

]
@history[#:changed "8.5.0.5"
         @elem{添加了 @racket[#:groups]、@racket[#:group-sep] 和 @racket[#:decimal-sep]。}]
}

@; ----------------------------------------

@deftogether[(
@defproc[(~.a [v any/c] ...
              [#:separator separator string? ""]
              [#:width width (or/c exact-nonnegative-integer? #f) #f]
              [#:max-width max-width (or/c exact-nonnegative-integer? +inf.0) (or width +inf.0)]
              [#:min-width min-width exact-nonnegative-integer? (or width 0)]
              [#:limit-marker limit-marker string? ""]
              [#:limit-prefix? limit-prefix? boolean? #f]
              [#:align align (or/c 'left 'center 'right) 'left]
              [#:pad-string pad-string non-empty-string? " "]
              [#:left-pad-string left-pad-string non-empty-string? pad-string]
              [#:right-pad-string right-pad-string non-empty-string? pad-string])
         string?]
@defproc[(~.v [v any/c] ...
              [#:separator separator string? " "]
              [#:width width (or/c exact-nonnegative-integer? #f) #f]
              [#:max-width max-width (or/c exact-nonnegative-integer? +inf.0) (or width +inf.0)]
              [#:min-width min-width exact-nonnegative-integer? (or width 0)]
              [#:limit-marker limit-marker string? "..."]
              [#:limit-prefix? limit-prefix? boolean? #f]
              [#:align align (or/c 'left 'center 'right) 'left]
              [#:pad-string pad-string non-empty-string? " "]
              [#:left-pad-string left-pad-string non-empty-string? pad-string]
              [#:right-pad-string right-pad-string non-empty-string? pad-string])
         string?]
@defproc[(~.s [v any/c] ...
              [#:separator separator string? " "]
              [#:width width (or/c exact-nonnegative-integer? #f) #f]
              [#:max-width max-width (or/c exact-nonnegative-integer? +inf.0) (or width +inf.0)]
              [#:min-width min-width exact-nonnegative-integer? (or width 0)]
              [#:limit-marker limit-marker string? "..."]
              [#:limit-prefix? limit-prefix? boolean? #f]
              [#:align align (or/c 'left 'center 'right) 'left]
              [#:pad-string pad-string non-empty-string? " "]
              [#:left-pad-string left-pad-string non-empty-string? pad-string]
              [#:right-pad-string right-pad-string non-empty-string? pad-string])
         string?]
)]{

类似 @racket[~a]、@racket[~v] 和 @racket[~s]，但每个 @racket[v] 分别像 @racket[(format "~.a" v)]、@racket[(format "~.v" v)] 和 @racket[(format "~.s" v)] 一样格式化。}


@; ----------------------------------------

@(close-eval the-eval)
