#lang scribble/doc
@(require "mz.rkt" (for-label racket/extflonum
                              racket/fixnum ; for fl->fx and fx->fl
                              racket/flonum))

@title[#:tag "extflonums"]{Extflonums}

@defmodule[racket/extflonum]

一个 @deftech{extflonum} 是扩展精度（80-bit）浮点数。Extflonum 算术在具有扩展精度的硬件平台上受支持，前提是 extflonum 实现不与普通的双精度算术冲突（即，在 x86 和 x86_64 平台上，当 Racket 编译为使用 SSE 指令进行浮点操作时，以及在 Windows 上 @as-index{@filepath{longdouble.dll}} 可用时）。

Extflonum 不是 @racket[number?] 意义上的 @tech{number}。只有 extflonum 特定的操作（如 @racket[extfl+]）执行 extflonum 算术。

字面 extflonum 的书写方式类似于 @tech{inexact number}，但使用显式的 @litchar{t} 或 @litchar{T} 指数标记（参见 @secref["parse-extflonum"]）。例如，@racket[3.5t0] 是一个 extflonum。无穷大的 extflonum 值是 @as-index{@racket[+inf.t]} 和 @as-index{@racket[-inf.t]}。非数值的 extflonum 值是 @as-index{@racket[+nan.t]} 或 @as-index{@racket[-nan.t]}。

如果 @racket[(extflonum-available?)] 产生 @racket[#f]，则 @racketmodname[racket/extflonum] 导出的所有操作都会引发 @racket[exn:fail:unsupported]，除了 @racket[extflonum?]、@racket[extflonum-available?] 和 @racket[extflvector?]（它们始终可用）。Reader（见 @secref["reader"]）始终接受 extflonum 输入；当 extflonum 操作不受支持时，从 reader 打印 extflonum 使用其源表示法（而非规范化格式）。

两个 extflonum 的 @racket[equal?] 行为与 @tech{flonum} 相同：当它们 @racket[extfl=] 且具有相同的符号（对 @racket[-0.0t0] 和 @racket[+0.0t0] 有影响），或当它们都是 @racket[+nan.t]。如果 extflonum 在平台上不受支持，则仅当它们 @racket[eq?] 时被视为相等。

@defproc[(extflonum? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is an extflonum, @racket[#f]
otherwise.}

@defproc[(extflonum-available?) boolean?]{

Returns @racket[#t] if @tech{extflonum} operations are supported on the
current platform, @racket[#f] otherwise.}

@; ------------------------------------------------------------------------

@section{Extflonum 算术}

@deftogether[(
@defproc[(extfl+ [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(extfl- [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(extfl* [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(extfl/ [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(extflabs [a extflonum?]) extflonum?]
)]{

Like @racket[fl+], @racket[fl-], @racket[fl*], @racket[fl/], and @racket[flabs],
but for @tech{extflonums}.}

@deftogether[(
@defproc[(extfl=   [a extflonum?] [b extflonum?]) boolean?]
@defproc[(extfl<   [a extflonum?] [b extflonum?]) boolean?]
@defproc[(extfl>   [a extflonum?] [b extflonum?]) boolean?]
@defproc[(extfl<=  [a extflonum?] [b extflonum?]) boolean?]
@defproc[(extfl>=  [a extflonum?] [b extflonum?]) boolean?]
@defproc[(extflmin [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(extflmax [a extflonum?] [b extflonum?]) extflonum?]
)]{

Like @racket[fl=], @racket[fl<], @racket[fl>], @racket[fl<=], @racket[fl>=],
@racket[flmin], and @racket[flmax], but for @tech{extflonums}.}

@deftogether[(
@defproc[(extflround    [a extflonum?]) extflonum?]
@defproc[(extflfloor    [a extflonum?]) extflonum?]
@defproc[(extflceiling  [a extflonum?]) extflonum?]
@defproc[(extfltruncate [a extflonum?]) extflonum?]
)]{

Like @racket[flround], @racket[flfloor], @racket[flceiling], and
@racket[fltruncate], but for @tech{extflonums}.}

@deftogether[(
@defproc[(extflsin  [a extflonum?]) extflonum?]
@defproc[(extflcos  [a extflonum?]) extflonum?]
@defproc[(extfltan  [a extflonum?]) extflonum?]
@defproc[(extflasin [a extflonum?]) extflonum?]
@defproc[(extflacos [a extflonum?]) extflonum?]
@defproc[(extflatan [a extflonum?]) extflonum?]
@defproc[(extfllog  [a extflonum?]) extflonum?]
@defproc[(extflexp  [a extflonum?]) extflonum?]
@defproc[(extflsqrt [a extflonum?]) extflonum?]
@defproc[(extflexpt  [a extflonum?] [b extflonum?]) extflonum?]
)]{

Like @racket[flsin], @racket[flcos], @racket[fltan], @racket[flasin],
@racket[flacos], @racket[flatan], @racket[fllog], @racket[flexp], and
@racket[flsqrt], and @racket[flexpt], but for @tech{extflonums}.}

@deftogether[(
@defproc[(->extfl [a exact-integer?]) extflonum?]
@defproc[(extfl->exact-integer [a extflonum?]) exact-integer?]
@defproc[(real->extfl [a real?]) extflonum?]
@defproc[(extfl->exact [a extflonum?]) (and/c real? exact?)]
@defproc[(extfl->fx [a extflonum?]) fixnum?]
@defproc[(fx->extfl [a fixnum?]) extflonum?]
@defproc[(extfl->inexact [a extflonum?]) flonum?]
)]{

The first six are like @racket[->fl], @racket[fl->exact-integer],
@racket[real->double-flonum], @racket[inexact->exact], @racket[fl->fx],
and @racket[fx->fl], but for @tech{extflonums}.
@racket[extfl->inexact] function 将 @tech{extflonum} 转换为其最接近的 @tech{flonum} 近似值。

@history[#:changed "7.7.0.8" @elem{Changed @racket[extfl->fx] to truncate.}]}

@; ------------------------------------------------------------------------

@section{Extflonum 常量}

@defthing[pi.t extflonum?]{
Like @racket[pi], but with 80 bits precision.}

@; ------------------------------------------------------------------------

@section[#:tag "extflvectors"]{Extflonum Vector}

一个 @deftech{extflvector} 类似于 @tech{flvector}，但仅存储 @tech{extflonum}。另见 @secref["unsafeextfl"]。

两个 @tech{extflvector} 如果长度相同，且对应槽位的 @tech{extflonum} 值 @racket[equal?]，则视为相等。

@deftogether[(
@defproc[(extflvector? [v any/c]) boolean?]
@defproc[(extflvector [x extflonum?] ...) extflvector?]
@defproc[(make-extflvector [size exact-nonnegative-integer?]
                           [x extflonum? 0.0t0])
         extflvector?]
@defproc[(extflvector-length [vec extflvector?]) exact-nonnegative-integer?]
@defproc[(extflvector-ref [vec extflvector?] [pos exact-nonnegative-integer?])
         extflonum?]
@defproc[(extflvector-set! [vec extflvector?] [pos exact-nonnegative-integer?]
                           [x extflonum?])
         extflonum?]
@defproc[(extflvector-copy [vec extflvector?]
                           [start exact-nonnegative-integer? 0]
                           [end exact-nonnegative-integer? (vector-length v)])
         extflvector?]
)]{

Like @racket[flvector?], @racket[flvector], @racket[make-flvector],
@racket[flvector-length], @racket[flvector-ref], @racket[flvector-set],
and @racket[flvector-copy], but for @tech{extflvectors}.}

@deftogether[(
@defproc[(in-extflvector [vec extflvector?]
                         [start exact-nonnegative-integer? 0]
                         [stop (or/c exact-integer? #f) #f]
                         [step (and/c exact-integer? (not/c zero?)) 1])
         sequence?]
@defform[(for/extflvector maybe-length (for-clause ...) body ...)]
@defform/subs[(for*/extflvector maybe-length (for-clause ...) body ...)
              ([maybe-length (code:line)
                             (code:line #:length length-expr)
                             (code:line #:length length-expr #:fill fill-expr)])
              #:contracts ([length-expr exact-nonnegative-integer?]
                           [fill-expr extflonum?])]
)]{

Like @racket[in-flvector], @racket[for/flvector], and @racket[for*/flvector],
but for @tech{extflvectors}.}

@deftogether[(
@defproc[(shared-extflvector [x extflonum?] ...) extflvector?]
@defproc[(make-shared-extflvector [size exact-nonnegative-integer?]
                                  [x extflonum? 0.0t0])
         extflvector?]
)]{

Like @racket[shared-flvector] and @racket[make-shared-flvector],
but for @tech{extflvectors}.}

@; ------------------------------------------------------------

@section[#:tag "extflutils"]{Extflonum 字节串}

@defproc[(floating-point-bytes->extfl [bstr bytes?]
                                      [big-endian? any/c (system-big-endian?)]
                                      [start exact-nonnegative-integer? 0]
                                      [end exact-nonnegative-integer? (bytes-length bstr)])
         extflonum?]{

Like @racket[floating-point-bytes->real], but for @tech{extflonums}:
将 @racket[bstr] 中从 @racket[start]（包含）到 @racket[end]（不包含）位置的扩展精度浮点数编码转换为 @tech{extflonum}。@racket[start] 与 @racket[end] 的差必须为 10 字节。}


@defproc[(extfl->floating-point-bytes [x extflonum?]
                                      [big-endian? any/c (system-big-endian?)]
                                      [dest-bstr (and/c bytes? (not/c immutable?))
                                                 (make-bytes 10)]
                                      [start exact-nonnegative-integer? 0])
          bytes?]{

Like @racket[real->floating-point-bytes], but for @tech{extflonums}:
将 @racket[x] 转换为长度为 10 的字节串表示。}
