#lang scribble/doc
@(require "mz.rkt" (for-label racket/flonum))

@(define fl-eval (make-base-eval))
@examples[#:hidden #:eval fl-eval (require racket/flonum)]

@title[#:tag "flonums"]{Flonum}

@defmodule[racket/flonum]

@racketmodname[racket/flonum] 库提供仅消耗和产生 @tech{flonums} 的操作，如 @racket[fl+]。flonum 专用操作在一致使用时可提供更好性能，并且与 @racket[+] 等通用操作一样安全。

@guidealso["fixnums+flonums"]

@; ------------------------------------------------------------------------

@section{Flonum 算术}

@deftogether[(
@defproc[(fl+ [a flonum?] ...) flonum?]
@defproc[(fl- [a flonum?] [b flonum?] ...) flonum?]
@defproc[(fl* [a flonum?] ...) flonum?]
@defproc[(fl/ [a flonum?] [b flonum?] ...) flonum?]
@defproc[(flabs [a flonum?]) flonum?]
)]{

类似 @racket[+]、@racket[-]、@racket[*]、@racket[/] 和 @racket[abs]，但仅限于消耗 @tech{flonums}。结果始终是 @tech{flonum}。

@history[#:changed "7.0.0.13" @elem{Allow zero or more arguments for @racket[fl+] and @racket[fl*]
                                    and one or more arguments for @racket[fl-] and @racket[fl/].}]}

@deftogether[(
@defproc[(fl=   [a flonum?] [b flonum?] ...) boolean?]
@defproc[(fl<   [a flonum?] [b flonum?] ...) boolean?]
@defproc[(fl>   [a flonum?] [b flonum?] ...) boolean?]
@defproc[(fl<=  [a flonum?] [b flonum?] ...) boolean?]
@defproc[(fl>=  [a flonum?] [b flonum?] ...) boolean?]
@defproc[(flmin [a flonum?] [b flonum?] ...) flonum?]
@defproc[(flmax [a flonum?] [b flonum?] ...) flonum?]
)]{

类似于 @racket[=]、@racket[<]、@racket[>]、@racket[<=]、@racket[>=]、@racket[min] 和 @racket[max]，但仅限于消耗 @tech{flonums}。

@history/arity[]}

@deftogether[(
@defproc[(flround    [a flonum?]) flonum?]
@defproc[(flfloor    [a flonum?]) flonum?]
@defproc[(flceiling  [a flonum?]) flonum?]
@defproc[(fltruncate [a flonum?]) flonum?]
)]{

类似于 @racket[round]、@racket[floor]、@racket[ceiling] 和 @racket[truncate]，但仅限于消耗 @tech{flonums}。}


@defproc[(flsingle    [a flonum?]) flonum?]{

返回类似于 @racket[a] 的值，但可能丢弃精度和范围，使结果可表示为单精度 IEEE 浮点数（即使不支持 @tech{single-flonums}）。

对 @racket[fl+]、@racket[fl-]、@racket[fl*]、@racket[fl/] 和 @racket[flsqrt] 的参数和结果使用 @racket[flsingle]——即对可表示为单精度的值执行双精度运算，然后将结果舍入为单精度——始终等同于执行对应的单精度运算 @cite{Roux14}。（对于其他操作，IEEE 浮点规范未提供足够保证来说明与 @racket[flsingle] 的交互。）


@history[#:added "7.8.0.7"]}


@defproc[(flbit-field [a flonum?] [start (integer-in 0 64)] [end (integer-in 0 64)])
         exact-nonnegative-integer?]{

从 @racket[a] 的 64 位 IEEE 表示中提取一个位范围，返回在其（半无限）二进制补码表示中具有相同位置位的非负整数。

@mz-examples[
  #:eval fl-eval
  (flbit-field -0.0 63 64)
  (format "~x" (flbit-field 3.141579e132 16 48))
]

@history[#:added "8.15.0.3"]}


@deftogether[(
@defproc[(flsin  [a flonum?]) flonum?]
@defproc[(flcos  [a flonum?]) flonum?]
@defproc[(fltan  [a flonum?]) flonum?]
@defproc[(flasin [a flonum?]) flonum?]
@defproc[(flacos [a flonum?]) flonum?]
@defproc[(flatan [a flonum?]) flonum?]
@defproc[(fllog  [a flonum?]) flonum?]
@defproc[(flexp  [a flonum?]) flonum?]
@defproc[(flsqrt [a flonum?]) flonum?]
)]{

类似于 @racket[sin]、@racket[cos]、@racket[tan]、@racket[asin]、@racket[acos]、@racket[atan]、@racket[log]、@racket[exp] 和 @racket[sqrt]，但仅限于消耗和产生 @tech{flonums}。当 @racket[flasin] 或 @racket[flacos] 接收到 @racket[-1.0] 到 @racket[1.0] 范围之外的数时，或当 @racket[fllog] 或 @racket[flsqrt] 接收到负数时，结果为 @racket[+nan.0]。}

@defproc[(flexpt  [a flonum?] [b flonum?])
         flonum?]{

类似于 @racket[expt]，但仅限于消耗和产生 @tech{flonums}。

由于结果约束，与 @racket[expt] 的结果在以下情况下有所不同：
@margin-note*{这些特殊情况对应于 C99 中的 @tt{pow} @cite["C99"]。}
@;
@itemlist[#:style 'compact

 @item{@racket[(flexpt -1.0 +inf.0)] --- @racket[1.0]}

 @item{@racket[(flexpt a +inf.0)] 其中 @racket[a] 为负数 --- @racket[(expt (abs a) +inf.0)]}

 @item{@racket[(flexpt a -inf.0)] 其中 @racket[a] 为负数 --- @racket[(expt (abs a) -inf.0)]}

 @item{@racket[(expt -inf.0 b)] 其中 @racket[b] 为非整数：
       @itemlist[#:style 'compact
         @item{@racket[b] 为负数 --- @racket[+0.0]}
         @item{@racket[b] 为正数 --- @racket[+inf.0]}]}

 @item{@racket[(flexpt a b)] 其中 @racket[a] 为负数且 @racket[b] 不是整数 --- @racket[+nan.0]}

]}


@defproc[(->fl [a exact-integer?]) flonum?]{

类似于 @racket[exact->inexact]，但仅限于消耗精确整数，因此结果始终是 @tech{flonum}。}


@defproc[(fl->exact-integer [a flonum?]) exact-integer?]{

类似于 @racket[inexact->exact]，但仅限于消耗 @tech{integer} @tech{flonum}，因此结果始终是精确整数。}


@deftogether[(
@defproc[(make-flrectangular [a flonum?] [b flonum?])
         (and/c complex?
                (lambda (c) (flonum? (real-part c)))
                (lambda (c) (flonum? (imag-part c))))]
@defproc[(flreal-part [a (and/c complex?
                                (lambda (c) (flonum? (real-part c)))
                                (lambda (c) (flonum? (imag-part c))))])
         flonum?]
@defproc[(flimag-part [a (and/c complex?
                                (lambda (c) (flonum? (real-part c)))
                                (lambda (c) (flonum? (imag-part c))))])
         flonum?]
)]{

类似于 @racket[make-rectangular]、@racket[real-part] 和 @racket[imag-part]，但复数的两个部分都必须是不精确的。}

@defproc[(flrandom [rand-gen pseudo-random-generator?]) (and flonum? (>/c 0) (</c 1))]{

等同于 @racket[(random rand-gen)]。}

@; ------------------------------------------------------------------------

@section[#:tag "flvectors"]{Flonum Vector}

@deftech{flvector} 类似于 @tech{vector}，但仅保存不精确的实数。这种表示形式可以更紧凑，并且对 @tech{flvector} 的 unsafe 操作（参见 @racketmodname[racket/unsafe/ops]）比在不精确实数的 @tech{vector} 上的 unsafe 操作更高效。

@racketmodname[ffi/vector] 提供的 f64vector 存储与 @tech{flvector} 相同类型的值，但具有额外的间接层，使 f64vector 更便于与 foreign library 一起使用。缺少间接层使得对 @tech{flvector} 的 unsafe 访问更高效。

两个 @tech{flvectors} 是 @racket[equal?] 的，当它们具有相同长度，并且 @tech{flvectors} 对应槽中的值是 @racket[equal?] 的。

打印的 @tech{flvector} 以 @litchar{#fl(} 开头，可选地在 @litchar{#fl} 和 @litchar{(} 之间有一个数字。@see-read-print["vector" #:print "vectors"]{flvectors}

@defproc[(flvector? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{flvector} 则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(flvector [x flonum?] ...) flvector?]{

创建包含给定不精确实数的 @tech{flvector}。

@mz-examples[#:eval fl-eval (flvector 2.0 3.0 4.0 5.0)]}

@defproc[(make-flvector [size exact-nonnegative-integer?]
                        [x flonum? 0.0]) 
         flvector?]{

创建具有 @racket[size] 个元素的 @tech{flvector}，其中 @tech{flvector} 的每个槽都填充 @racket[x]。

@mz-examples[#:eval fl-eval (make-flvector 4 3.0)]}

@defproc[(flvector-length [vec flvector?]) exact-nonnegative-integer?]{

返回 @racket[vec] 的长度（即 @tech{flvector} 中的槽数）。}


@defproc[(flvector-ref [vec flvector?] [pos exact-nonnegative-integer?])
         flonum?]{

返回 @racket[vec] 的槽 @racket[pos] 中的不精确实数。第一个槽位于位置 @racket[0]，最后一个槽比 @racket[(flvector-length vec)] 小一。}

@defproc[(flvector-set! [vec flvector?] [pos exact-nonnegative-integer?]
                        [x flonum?])
         flonum?]{

设置 @racket[vec] 的槽 @racket[pos] 中的不精确实数。第一个槽位于位置 @racket[0]，最后一个槽比 @racket[(flvector-length vec)] 小一。}

@defproc[(flvector-copy [vec flvector?]
                        [start exact-nonnegative-integer? 0]
                        [end exact-nonnegative-integer? (vector-length v)]) 
         flvector?]{

创建大小为 @racket[(- end start)] 的新 @tech{flvector}，包含 @racket[vec] 中从 @racket[start]（包含）到 @racket[end]（不包含）的所有元素。}


@defproc[(in-flvector [vec flvector?]
                      [start exact-nonnegative-integer? 0]
                      [stop (or/c exact-integer? #f) #f]
                      [step (and/c exact-integer? (not/c zero?)) 1])
         sequence?]{
  当不提供可选参数时，返回等同于 @racket[vec] 的序列。

  可选参数 @racket[start]、@racket[stop] 和 @racket[step] 与 @racket[in-vector] 中相同。

  当 @racket[in-flvector] 直接出现在 @racket[for] 子句中时，可为 @tech{flvector} 迭代提供更好性能。
}

@deftogether[(
@defform[(for/flvector maybe-length (for-clause ...) body ...)]
@defform/subs[(for*/flvector maybe-length (for-clause ...) body ...)
              ([maybe-length (code:line)
                             (code:line #:length length-expr)
                             (code:line #:length length-expr #:fill fill-expr)])
              #:contracts ([length-expr exact-nonnegative-integer?]
                           [fill-expr flonum?])]
)]{

类似于 @racket[for/vector] 或 @racket[for*/vector]，但用于 @tech{flvector}s。默认的 @racket[fill-expr] 产生 @racket[0.0]。}

@defproc[(shared-flvector [x flonum?] ...) flvector?]{

创建包含给定不精确实数的 @tech{flvector}。为了在 @tech{places} 之间通信，新的 @tech{flvector} 分配在 @tech{shared memory space} 中。

@mz-examples[#:eval fl-eval (shared-flvector 2.0 3.0 4.0 5.0)]}


@defproc[(make-shared-flvector [size exact-nonnegative-integer?]
                        [x flonum? 0.0]) 
         flvector?]{

创建具有 @racket[size] 个元素的 @tech{flvector}，其中 @tech{flvector} 的每个槽都填充 @racket[x]。为了在 @tech{places} 之间通信，新的 @tech{flvector} 分配在 @tech{shared memory space} 中。

@mz-examples[#:eval fl-eval (make-shared-flvector 4 3.0)]}

@; ------------------------------------------------------------

@close-eval[fl-eval]
