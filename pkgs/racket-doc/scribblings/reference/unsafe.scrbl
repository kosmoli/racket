#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/unsafe/ops
                     racket/unsafe/struct-type-property
                     racket/flonum
                     racket/fixnum
                     racket/extflonum
                     (only-in ffi/vector
                              f64vector?
                              f64vector-ref
                              f64vector-set!
                              u16vector?
                              u16vector-ref
                              u16vector-set!
                              s16vector?
                              s16vector-ref
                              s16vector-set!)))

@title[#:tag "unsafe"]{不安全操作}

@defmodule[racket/unsafe/ops]

@racketmodname[racket/base] 和 @racketmodname[racket] 提供的所有函数和形式都会检查其参数，以确保参数符合合约和其他约束。例如，@racket[vector-ref] 检查其参数以确保第一个参数是 vector，第二个参数是精确整数，且第二个参数在 @racket[0] 到 vector 长度减一之间（含）。

@racketmodname[racket/unsafe/ops] 提供的函数是 @deftech{不安全}（unsafe）的。它们有特定的约束，但这些约束不会被检查，这使得系统能够生成和执行更快的代码。如果参数违反了不安全函数的约束，该函数的行为和结果是不可预测的，整个系统可能会崩溃或损坏。

@racketmodname[racket/unsafe/ops] 的所有导出绑定都受 @racket[protect-out] 意义上的保护，因此可以通过调整代码检查器来阻止对不安全操作的访问（参见 @secref["modprotect"]）。

@section{不安全数值操作}

@deftogether[(
@defproc[(unsafe-fx+ [a fixnum?] ...) fixnum?]
@defproc[(unsafe-fx- [a fixnum?] [b fixnum?] ...) fixnum?]
@defproc[(unsafe-fx* [a fixnum?] ...) fixnum?]
@defproc[(unsafe-fxquotient  [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(unsafe-fxremainder [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(unsafe-fxmodulo    [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(unsafe-fxabs       [a fixnum?]) fixnum?]
)]{

针对 @tech{fixnums}：@racket[fx+]、@racket[fx-]、@racket[fx*]、@racket[fxquotient]、@racket[fxremainder]、@racket[fxmodulo] 和 @racket[fxabs] 的未检查版本。

@history[#:changed "7.0.0.13" @elem{允许 @racket[unsafe-fx+] 和 @racket[unsafe-fx*] 接受零个或多个参数，并允许 @racket[unsafe-fx-] 接受一个或多个参数。}]}


@deftogether[(
@defproc[(unsafe-fxand [a fixnum?] ...) fixnum?]
@defproc[(unsafe-fxior [a fixnum?] ...) fixnum?]
@defproc[(unsafe-fxxor [a fixnum?] ...) fixnum?]
@defproc[(unsafe-fxnot [a fixnum?]) fixnum?]
@defproc[(unsafe-fxlshift [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(unsafe-fxrshift [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(unsafe-fxrshift/logical [a fixnum?] [b fixnum?]) fixnum?]
)]{

针对 @tech{fixnums}：@racket[fxand]、@racket[fxior]、@racket[fxxor]、@racket[fxnot]、@racket[fxlshift]、@racket[fxrshift] 和 @racket[fxrshift/logical] 的未检查版本。

@history[#:changed "7.0.0.13" @elem{允许 @racket[unsafe-fxand]、@racket[unsafe-fxior] 和 @racket[unsafe-fxxor] 接受零个或多个参数。}
        #:changed "8.8.0.5" @elem{添加了 @racket[unsafe-fxrshift/logical]。}]}

@deftogether[(
@defproc[(unsafe-fxpopcount [a (and/c fixnum? (not/c negative?))]) fixnum?]
@defproc[(unsafe-fxpopcount32 [a (and/c fixnum? (integer-in 0 @#,racketvalfont{#xFFFFFFFF}))]) fixnum?]
@defproc[(unsafe-fxpopcount16 [a (and/c fixnum? (integer-in 0 @#,racketvalfont{#xFFFF})) ]) fixnum?]
)]{

针对 @tech{fixnums}：@racket[fxpopcount]、@racket[fxpopcount32] 和 @racket[fxpopcount16] 的未检查版本。

@history[#:added "8.5.0.6"]}


@deftogether[(
@defproc[(unsafe-fx+/wraparound [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(unsafe-fx-/wraparound [a fixnum? 0] [b fixnum?]) fixnum?]
@defproc[(unsafe-fx*/wraparound [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(unsafe-fxlshift/wraparound [a fixnum?] [b fixnum?]) fixnum?]
)]{

针对 @tech{fixnums}：@racket[fx+/wraparound]、@racket[fx-/wraparound]、@racket[fx*/wraparound] 和 @racket[fxlshift/wraparound] 的未检查版本。

@history[#:added "7.9.0.6"
         #:changed "8.15.0.12" @elem{将 @racket[unsafe-fx-/wraparound] 改为接受单个参数。}]}


@deftogether[(
@defproc[(unsafe-fx=   [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(unsafe-fx<   [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(unsafe-fx>   [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(unsafe-fx<=  [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(unsafe-fx>=  [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(unsafe-fxmin [a fixnum?] [b fixnum?] ...) fixnum?]
@defproc[(unsafe-fxmax [a fixnum?] [b fixnum?] ...) fixnum?]
)]{

针对 @tech{fixnums}：@racket[fx=]、@racket[fx<]、@racket[fx>]、@racket[fx<=]、@racket[fx>=]、@racket[fxmin] 和 @racket[fxmax] 的未检查版本。

@history[#:changed "7.0.0.13" @elem{允许一个或多个参数，而非仅允许两个。}]}


@deftogether[(
@defproc[(unsafe-fl+   [a flonum?] ...) flonum?]
@defproc[(unsafe-fl-   [a flonum?] [b flonum?] ...) flonum?]
@defproc[(unsafe-fl*   [a flonum?] ...) flonum?]
@defproc[(unsafe-fl/   [a flonum?] [b flonum?] ...) flonum?]
@defproc[(unsafe-flabs [a flonum?]) flonum?]
)]{

针对 @tech{flonums}：@racket[fl+]、@racket[fl-]、@racket[fl*]、@racket[fl/] 和 @racket[flabs] 的未检查版本。

@history[#:changed "7.0.0.13" @elem{允许 @racket[unsafe-fl+] 和 @racket[unsafe-fl*] 接受零个或多个参数，并允许 @racket[unsafe-fl-] 和 @racket[unsafe-fl/] 接受一个或多个参数。}]}


@deftogether[(
@defproc[(unsafe-fl=   [a flonum?] [b flonum?] ...) boolean?]
@defproc[(unsafe-fl<   [a flonum?] [b flonum?] ...) boolean?]
@defproc[(unsafe-fl>   [a flonum?] [b flonum?] ...) boolean?]
@defproc[(unsafe-fl<=  [a flonum?] [b flonum?] ...) boolean?]
@defproc[(unsafe-fl>=  [a flonum?] [b flonum?] ...) boolean?]
@defproc[(unsafe-flmin [a flonum?] [b flonum?] ...) flonum?]
@defproc[(unsafe-flmax [a flonum?] [b flonum?] ...) flonum?]
)]{

针对 @tech{flonums}：@racket[fl=]、@racket[fl<]、@racket[fl>]、@racket[fl<=]、@racket[fl>=]、@racket[flmin] 和 @racket[flmax] 的未检查版本。

@history[#:changed "7.0.0.13" @elem{允许一个或多个参数，而非仅允许两个。}]}


@deftogether[(
@defproc[(unsafe-flround [a flonum?]) flonum?]
@defproc[(unsafe-flfloor [a flonum?]) flonum?]
@defproc[(unsafe-flceiling [a flonum?]) flonum?]
@defproc[(unsafe-fltruncate [a flonum?]) flonum?]
)]{

针对 @tech{flonums}：@racket[flround]、@racket[flfloor]、@racket[flceiling] 和 @racket[fltruncate] 的（潜在）未检查版本。目前，这些绑定只是相应安全绑定的别名。}


@defproc[(unsafe-flsingle [a flonum?]) flonum?]{

针对 @tech{flonums}：@racket[flsingle] 的（潜在）未检查版本。

@history[#:added "7.8.0.7"]}

@defproc[(unsafe-flbit-field [a flonum?] [start (integer-in 0 64)] [end (integer-in 0 64)])
         exact-nonnegative-integer?]{

针对 @tech{flonums}：@racket[flbit-field] 的未检查版本。

@history[#:added "8.15.0.3"]}


@deftogether[(
@defproc[(unsafe-flsin [a flonum?]) flonum?]
@defproc[(unsafe-flcos [a flonum?]) flonum?]
@defproc[(unsafe-fltan [a flonum?]) flonum?]
@defproc[(unsafe-flasin [a flonum?]) flonum?]
@defproc[(unsafe-flacos [a flonum?]) flonum?]
@defproc[(unsafe-flatan [a flonum?]) flonum?]
@defproc[(unsafe-fllog [a flonum?]) flonum?]
@defproc[(unsafe-flexp [a flonum?]) flonum?]
@defproc[(unsafe-flsqrt [a flonum?]) flonum?]
@defproc[(unsafe-flexpt [a flonum?] [b flonum?]) flonum?]
)]{

针对 @tech{flonums}：@racket[flsin]、@racket[flcos]、@racket[fltan]、@racket[flasin]、@racket[flacos]、@racket[flatan]、@racket[fllog]、@racket[flexp]、@racket[flsqrt] 和 @racket[flexpt] 的（潜在）未检查版本。目前，其中一些绑定只是相应安全绑定的别名。}


@deftogether[(
@defproc[(unsafe-make-flrectangular [a flonum?] [b flonum?])
         (and/c complex?
                (lambda (c) (flonum? (real-part c)))
                (lambda (c) (flonum? (imag-part c))))]
@defproc[(unsafe-flreal-part [a (and/c complex?
                                       (lambda (c) (flonum? (real-part c)))
                                       (lambda (c) (flonum? (imag-part c))))])
         flonum?]
@defproc[(unsafe-flimag-part [a (and/c complex?
                                       (lambda (c) (flonum? (real-part c)))
                                       (lambda (c) (flonum? (imag-part c))))])
         flonum?]
)]{

针对 @tech{flonums}：@racket[make-flrectangular]、@racket[flreal-part] 和 @racket[flimag-part] 的未检查版本。}


@deftogether[(
@defproc[(unsafe-fx->fl [a fixnum?]) flonum?]
@defproc[(unsafe-fl->fx [a flonum?]) fixnum?]
)]{
@racket[fx->fl] 和 @racket[fl->fx] 的未检查版本。

@history[#:changed "7.7.0.8" @elem{将 @racket[unsafe-fl->fx] 改为截断。}]}


@defproc[(unsafe-flrandom [rand-gen pseudo-random-generator?]) (and flonum? (>/c 0) (</c 1))]{

@racket[flrandom] 的未检查版本。
}


@section{不安全字符操作}

@deftogether[(
@defproc[(unsafe-char=?   [a char?] [b char?] ...) boolean?]
@defproc[(unsafe-char<?   [a char?] [b char?] ...) boolean?]
@defproc[(unsafe-char>?   [a char?] [b char?] ...) boolean?]
@defproc[(unsafe-char<=?  [a char?] [b char?] ...) boolean?]
@defproc[(unsafe-char>=?  [a char?] [b char?] ...) boolean?]
@defproc[(unsafe-char->integer [a char?]) fixnum?]
)]{

@racket[char=?]、@racket[char<?]、@racket[char>?]、@racket[char<=?]、@racket[char>=?] 和 @racket[char->integer] 的未检查版本。

@history[#:added "7.0.0.14"]}



@section[#:tag "Unsafe Data Extraction"]{不安全复合数据操作}

@deftogether[(
@defproc[(unsafe-car [p pair?]) any/c]
@defproc[(unsafe-cdr [p pair?]) any/c]
@defproc[(unsafe-mcar [p mpair?]) any/c]
@defproc[(unsafe-mcdr [p mpair?]) any/c]
@defproc[(unsafe-set-mcar! [p mpair?] [v any/c]) void?]
@defproc[(unsafe-set-mcdr! [p mpair?] [v any/c]) void?]
)]{

@racket[car]、@racket[cdr]、@racket[mcar]、@racket[mcdr]、@racket[set-mcar!] 和 @racket[set-mcdr!] 的不安全变体。}


@defproc[(unsafe-cons-list [v any/c] [rest list?]) (and/c pair? list?)]{

@racket[cons] 的不安全变体，生成一个声称是列表的 pair---而不检查 @racket[rest] 是否是列表。}


@deftogether[(
@defproc[(unsafe-list-ref [lst pair?] [pos (and/c exact-nonnegative-integer? fixnum?)]) any/c]
@defproc[(unsafe-list-tail [lst any/c] [pos (and/c exact-nonnegative-integer? fixnum?)]) any/c]
)]{

@racket[list-ref] 和 @racket[list-tail] 的不安全变体，其中 @racket[pos] 必须是 @tech{fixnum}，且 @racket[lst] 必须至少以 @racket[(add1 pos)]（对于 @racket[unsafe-list-ref]）或 @racket[pos]（对于 @racket[unsafe-list-tail]）个 pair 开头。}


@deftogether[(
@defproc[(unsafe-set-immutable-car! [p pair?] [v any/c]) void?]
@defproc[(unsafe-set-immutable-cdr! [p pair?] [v any/c]) void?]
)]{

正如它们矛盾修辞的名称所示，使用这些函数 @emph{没有普遍正确的方式}。尽管如此，它们可能作为最后的手段有用，在 pair 以受限方式使用且对 Racket 的实现做出正确假设（包括对编译器优化限制的假设）的情况下。

使用 @racket[unsafe-set-immutable-car!] 和 @racket[unsafe-set-immutable-cdr!] 的一些陷阱：

@itemlist[

 @item{消费 pair 的函数可能会利用不可变性，例如计算列表的长度一次并期望列表保持该长度，或根据合约检查列表并期望合约此后保持。}

 @item{对 pair 调用 @racket[list?] 的结果可能在内部缓存，因此将 pair 的 @racket[cdr] 从列表改为非列表或反之可能会导致 @racket[list?] 产生错误的值---对于被修改的 pair 或到达被修改 pair 的其他 pair。}

 @item{编译器可能基于 pair 是不可变的理由，重新排序甚至优化掉对 @racket[car] 或 @racket[cdr] 的调用，在这种情况下，@racket[unsafe-set-immutable-car!] 或 @racket[unsafe-set-immutable-cdr!] 可能不会对 @racket[car] 或 @racket[cdr] 的使用产生影响。}

]

@history[#:added "7.9.0.18"]}

@deftogether[(
@defproc[(unsafe-unbox [b box?]) any/c]
@defproc[(unsafe-set-box! [b box?] [k any/c]) void?]
@defproc[(unsafe-unbox* [v (and/c box? (not/c impersonator?))]) any/c]
@defproc[(unsafe-set-box*! [v (and/c box? (not/c impersonator?))] [val any/c]) void?])]{

@racket[unbox] 和 @racket[set-box!] 的不安全版本，其中 @schemeidfont{box*} 变体可以更快，但不能用于 @tech{拟人化对象}（impersonator）。}

@defproc[(unsafe-box*-cas! [loc box?] [old any/c] [new any/c]) boolean?]{
  @racket[box-cas!] 的不安全版本。与 @racket[unsafe-set-box*!] 一样，它不能用于 @tech{拟人化对象}。
}

@deftogether[(
@defproc[(unsafe-vector-length [v vector?]) fixnum?]
@defproc[(unsafe-vector-ref [v vector?] [k fixnum?]) any/c]
@defproc[(unsafe-vector-set! [v vector?] [k fixnum?] [val any/c]) void?]
@defproc[(unsafe-vector-copy [v vector?] [start fixnum? 0] [end fixnum? (vector-length v)]) vector?]
@defproc[(unsafe-vector-set/copy [v vector?] [pos fixnum? 0] [val any/c]) vector?]
@defproc[(unsafe-vector-append [v vector?] ...) vector?]
@defproc[(unsafe-vector*-length [v (and/c vector? (not/c impersonator?))]) fixnum?]
@defproc[(unsafe-vector*-ref [v (and/c vector? (not/c impersonator?))] [k fixnum?]) any/c]
@defproc[(unsafe-vector*-set! [v (and/c vector? (not/c impersonator?))] [k fixnum?] [val any/c]) void?]
@defproc[(unsafe-vector*-cas! [v (and/c vector? (not/c impersonator?))] [k fixnum?] [old-val any/c] [new-val any/c]) boolean?]
@defproc[(unsafe-vector*-copy [v vector?] [start fixnum? 0] [end fixnum? (vector-length v)]) vector?]
@defproc[(unsafe-vector*-set/copy [v vector?] [pos fixnum?] [val any/c]) vector?]
@defproc[(unsafe-vector*-append [v vector?] ...) vector?]
)]{

@racket[vector-length]、@racket[vector-ref]、@racket[vector-set!]、@racket[vector-cas!]、@racket[vector-copy]、@racket[vector-set/copy] 和 @racket[vector-append] 的不安全版本，其中 @schemeidfont{vector*} 变体可以更快，但不能用于 @tech{拟人化对象}。

vector 的大小永远不能大于 @tech{fixnum}，因此即使是 @racket[vector-length] 也总是返回 fixnum。

@history[#:changed "6.11.0.2" @elem{添加了 @racket[unsafe-vector*-cas!]。}
         #:changed "8.11.1.9" @elem{添加了 @racket[unsafe-vector-copy]、@racket[unsafe-vector*-copy]、@racket[unsafe-vector-set/copy]、@racket[unsafe-vector*-set/copy]、@racket[unsafe-vector-append] 和 @racket[unsafe-vector*-append]。}]}


@defproc[(unsafe-vector*->immutable-vector! [v (and/c vector? (not/c impersonator?))]) (and/c vector? immutable?)]{

类似 @racket[vector->immutable-vector]，但可能会销毁 @racket[v] 并重用其空间，因此在调用 @racket[unsafe-vector*->immutable-vector!] 后不得使用 @racket[v]。

@history[#:added "7.7.0.6"]}


@deftogether[(
@defproc[(unsafe-string-length [str string?]) fixnum?]
@defproc[(unsafe-string-ref [str string?] [k fixnum?])
         (and/c char? (lambda (ch) (<= 0 (char->integer ch) 255)))]
@defproc[(unsafe-string-set! [str (and/c string? (not/c immutable?))] [k fixnum?] [ch char?]) void?]
)]{

@racket[string-length]、@racket[string-ref] 和 @racket[string-set!] 的不安全版本。@racket[unsafe-string-ref] 过程只能在结果为 Latin-1 字符时使用。字符串的大小永远不能大于 @tech{fixnum}（因此即使是 @racket[string-length] 也总是返回 fixnum）。}

@defproc[(unsafe-string->immutable-string! [str string?]) (and/c string? immutable?)]{

类似 @racket[string->immutable-string]，但可能会销毁 @racket[str] 并重用其空间，因此在调用 @racket[unsafe-string->immutable-string!] 后不得使用 @racket[str]。

@history[#:added "7.7.0.6"]}


@deftogether[(
@defproc[(unsafe-bytes-length [bstr bytes?]) fixnum?]
@defproc[(unsafe-bytes-ref [bstr bytes?] [k fixnum?]) byte?]
@defproc[(unsafe-bytes-set! [bstr (and/c bytes? (not/c immutable?))] [k fixnum?] [b byte?]) void?]
@defproc[(unsafe-bytes-copy! [dest (and/c bytes? (not/c immutable?))]
                             [dest-start fixnum?]
                             [src bytes?]
                             [src-start fixnum? 0]
                             [src-end fixnum? (bytes-length src)])
         void?]
)]{

@racket[bytes-length]、@racket[bytes-ref]、@racket[bytes-set!] 和 @racket[bytes-copy!] 的不安全版本。bytes 的大小永远不能大于 @tech{fixnum}（因此即使是 @racket[bytes-length] 也总是返回 fixnum）。

@history[#:changed "7.5.0.15" @elem{添加了 @racket[unsafe-bytes-copy!]。}]}


@defproc[(unsafe-bytes->immutable-bytes! [bstr bytes?]) (and/c bytes? immutable?)]{

类似 @racket[bytes->immutable-bytes]，但可能会销毁 @racket[bstr] 并重用其空间，因此在调用 @racket[unsafe-bytes->immutable-bytes!] 后不得使用 @racket[bstr]。

@history[#:added "7.7.0.6"]}


@deftogether[(
@defproc[(unsafe-fxvector-length [v fxvector?]) fixnum?]
@defproc[(unsafe-fxvector-ref [v fxvector?] [k fixnum?]) fixnum?]
@defproc[(unsafe-fxvector-set! [v fxvector?] [k fixnum?] [x fixnum?]) void?]
)]{

@racket[fxvector-length]、@racket[fxvector-ref] 和 @racket[fxvector-set!] 的不安全版本。@tech{fxvector} 的大小永远不能大于 @tech{fixnum}（因此即使是 @racket[fxvector-length] 也总是返回 fixnum）。}


@deftogether[(
@defproc[(unsafe-flvector-length [v flvector?]) fixnum?]
@defproc[(unsafe-flvector-ref [v flvector?] [k fixnum?]) flonum?]
@defproc[(unsafe-flvector-set! [v flvector?] [k fixnum?] [x flonum?]) void?]
)]{

@racket[flvector-length]、@racket[flvector-ref] 和 @racket[flvector-set!] 的不安全版本。@tech{flvector} 的大小永远不能大于 @tech{fixnum}（因此即使是 @racket[flvector-length] 也总是返回 fixnum）。}


@deftogether[(
@defproc[(unsafe-f64vector-ref [vec f64vector?] [k fixnum?]) flonum?]
@defproc[(unsafe-f64vector-set! [vec f64vector?] [k fixnum?] [n flonum?]) void?]
)]{

@racket[f64vector-ref] 和 @racket[f64vector-set!] 的不安全版本。}


@deftogether[(
@defproc[(unsafe-s16vector-ref [vec s16vector?] [k fixnum?]) (integer-in -32768 32767)]
@defproc[(unsafe-s16vector-set! [vec s16vector?] [k fixnum?] [n (integer-in -32768 32767)]) void?]
)]{

@racket[s16vector-ref] 和 @racket[s16vector-set!] 的不安全版本。}


@deftogether[(
@defproc[(unsafe-u16vector-ref [vec u16vector?] [k fixnum?]) (integer-in 0 65535)]
@defproc[(unsafe-u16vector-set! [vec u16vector?] [k fixnum?] [n (integer-in 0 65535)]) void?]
)]{

@racket[u16vector-ref] 和 @racket[u16vector-set!] 的不安全版本。}


@deftogether[(
@defproc[(unsafe-stencil-vector [mask (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]
                                [v any/c]
                                ...)
         stencil-vector?]
@defproc[(unsafe-stencil-vector-mask [vec stencil-vector?])
         (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]
@defproc[(unsafe-stencil-vector-length [vec stencil-vector?])
         (integer-in 0 (sub1 (stencil-vector-mask-width)))]
@defproc[(unsafe-stencil-vector-ref [vec stencil-vector?]
                                    [pos exact-nonnegative-integer?])
         any/c]
@defproc[(unsafe-stencil-vector-set! [vec stencil-vector?]
                                     [pos exact-nonnegative-integer?]
                                     [v any/c])
         void?]
@defproc[(unsafe-stencil-vector-update [vec stencil-vector?]
                                       [remove-mask (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]
                                       [add-mask (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]
                                       [v any/c]
                                       ...)
         stencil-vector?]
)]{

@racket[stencil-vector]、@racket[stencil-vector-mask]、@racket[stencil-vector-length]、@racket[stencil-vector-ref]、@racket[stencil-vector-set!] 和 @racket[stencil-vector-update] 的不安全变体。

@history[#:added "8.5.0.7"]}


@deftogether[(
@defproc[(unsafe-struct-ref [v any/c] [k fixnum?]) any/c]
@defproc[(unsafe-struct-set! [v any/c] [k fixnum?] [val any/c]) void?]
@defproc[(unsafe-struct*-ref [v (not/c impersonator?)] [k fixnum?]) any/c]
@defproc[(unsafe-struct*-set! [v (not/c impersonator?)] [k fixnum?] [val any/c]) void?]
@defproc[(unsafe-struct*-cas! [v (not/c impersonator?)] [k fixnum?] [old-val any/c] [new-val any/c]) boolean?]
)]{

用于结构类型实例的不安全字段访问和更新，其中 @schemeidfont{struct*} 变体可以更快，但不能用于 @tech{拟人化对象}。索引 @racket[k] 必须在 @racket[0]（含）到结构中字段的数量（不含）之间。对于 @racket[unsafe-struct-set!]、@racket[unsafe-struct*-set!] 和 @racket[unsafe-struct*-cas!]，字段必须是可变的。@racket[unsafe-struct*-cas!] 操作类似于 @racket[box-cas!]，执行原子比较并设置。

@history[#:changed "6.11.0.2" @elem{添加了 @racket[unsafe-struct*-cas!]。}]}


@defproc[(unsafe-struct*-type [v any/c]) struct-type?]{

类似 @racket[struct-info]，但不进行检查器检查，仅返回第一个结果，且不支持 @tech{拟人化对象}。

@history[#:added "8.8.0.3"]}


@deftogether[(
@defproc[(unsafe-mutable-hash-iterate-first
          [hash (and/c hash? (not/c immutable?) hash-strong?)])
	  (or/c #f any/c)]
@defproc[(unsafe-mutable-hash-iterate-next
          [hash (and/c hash? (not/c immutable?) hash-strong?)]
	  [pos any/c])
	  (or/c #f any/c)]
@defproc[(unsafe-mutable-hash-iterate-key
          [hash (and/c hash? (not/c immutable?) hash-strong?)]
	  [pos any/c]) 
	  any/c]
@defproc[#:link-target? #f
         (unsafe-mutable-hash-iterate-key
          [hash (and/c hash? (not/c immutable?) hash-strong?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  any/c]
@defproc[(unsafe-mutable-hash-iterate-value
          [hash (and/c hash? (not/c immutable?) hash-strong?)]
	  [pos any/c]) 
	  any/c]
@defproc[#:link-target? #f
         (unsafe-mutable-hash-iterate-value
          [hash (and/c hash? (not/c immutable?) hash-strong?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  any/c]
@defproc[(unsafe-mutable-hash-iterate-key+value
          [hash (and/c hash? (not/c immutable?) hash-strong?)]
	  [pos any/c]) 
	  (values any/c any/c)]
@defproc[#:link-target? #f
         (unsafe-mutable-hash-iterate-key+value
          [hash (and/c hash? (not/c immutable?) hash-strong?)]
	  [pos any/c]
          [bad-index-v any/c])
	  (values any/c any/c)]
@defproc[(unsafe-mutable-hash-iterate-pair
          [hash (and/c hash? (not/c immutable?) hash-strong?)]
	  [pos any/c]) 
	  pair?]
@defproc[#:link-target? #f
         (unsafe-mutable-hash-iterate-pair
          [hash (and/c hash? (not/c immutable?) hash-strong?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  pair?]
@defproc[(unsafe-immutable-hash-iterate-first
          [hash (and/c hash? immutable?)])
	  (or/c #f any/c)]
@defproc[(unsafe-immutable-hash-iterate-next
          [hash (and/c hash? immutable?)]
	  [pos any/c])
	  (or/c #f any/c)]
@defproc[(unsafe-immutable-hash-iterate-key
          [hash (and/c hash? immutable?)]
	  [pos any/c]) 
	  any/c]
@defproc[#:link-target? #f
         (unsafe-immutable-hash-iterate-key
          [hash (and/c hash? immutable?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  any/c]
@defproc[(unsafe-immutable-hash-iterate-value
          [hash (and/c hash? immutable?)]
	  [pos any/c])
	  any/c]
@defproc[#:link-target? #f
         (unsafe-immutable-hash-iterate-value
          [hash (and/c hash? immutable?)]
	  [pos any/c]
          [bad-index-v any/c])
	  any/c]
@defproc[(unsafe-immutable-hash-iterate-key+value
          [hash (and/c hash? immutable?)]
	  [pos any/c])
	  (values any/c any/c)]
@defproc[#:link-target? #f
         (unsafe-immutable-hash-iterate-key+value
          [hash (and/c hash? immutable?)]
	  [pos any/c]
          [bad-index-v any/c])
	  (values any/c any/c)]
@defproc[(unsafe-immutable-hash-iterate-pair
          [hash (and/c hash? immutable?)]
	  [pos any/c])
	  pair?]
@defproc[#:link-target? #f
         (unsafe-immutable-hash-iterate-pair
          [hash (and/c hash? immutable?)]
	  [pos any/c]
          [bad-index-v any/c])
	  pair?]
@defproc[(unsafe-weak-hash-iterate-first
          [hash (and/c hash? hash-weak?)])
	  (or/c #f any/c)]
@defproc[(unsafe-weak-hash-iterate-next
          [hash (and/c hash? hash-weak?)]
	  [pos any/c])
	  (or/c #f any/c)]
@defproc[(unsafe-weak-hash-iterate-key
          [hash (and/c hash? hash-weak?)]
	  [pos any/c]) 
	  any/c]
@defproc[#:link-target? #f
         (unsafe-weak-hash-iterate-key
          [hash (and/c hash? hash-weak?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  any/c]
@defproc[(unsafe-weak-hash-iterate-value
          [hash (and/c hash? hash-weak?)]
	  [pos any/c]) 
	  any/c]
@defproc[#:link-target? #f
         (unsafe-weak-hash-iterate-value
          [hash (and/c hash? hash-weak?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  any/c]
@defproc[(unsafe-weak-hash-iterate-key+value
          [hash (and/c hash? hash-weak?)]
	  [pos any/c]) 
	  (values any/c any/c)]
@defproc[#:link-target? #f
         (unsafe-weak-hash-iterate-key+value
          [hash (and/c hash? hash-weak?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  (values any/c any/c)]
@defproc[(unsafe-weak-hash-iterate-pair
          [hash (and/c hash? hash-weak?)]
	  [pos any/c]) 
	  pair?]
@defproc[#:link-target? #f
         (unsafe-weak-hash-iterate-pair
          [hash (and/c hash? hash-weak?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  pair?]
@defproc[(unsafe-ephemeron-hash-iterate-first
          [hash (and/c hash? hash-ephemeron?)])
	  (or/c #f any/c)]
@defproc[(unsafe-ephemeron-hash-iterate-next
          [hash (and/c hash? hash-ephemeron?)]
	  [pos any/c])
	  (or/c #f any/c)]
@defproc[(unsafe-ephemeron-hash-iterate-key
          [hash (and/c hash? hash-ephemeron?)]
	  [pos any/c]) 
	  any/c]
@defproc[#:link-target? #f
         (unsafe-ephemeron-hash-iterate-key
          [hash (and/c hash? hash-ephemeron?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  any/c]
@defproc[(unsafe-ephemeron-hash-iterate-value
          [hash (and/c hash? hash-ephemeron?)]
	  [pos any/c]) 
	  any/c]
@defproc[#:link-target? #f
         (unsafe-ephemeron-hash-iterate-value
          [hash (and/c hash? hash-ephemeron?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  any/c]
@defproc[(unsafe-ephemeron-hash-iterate-key+value
          [hash (and/c hash? hash-ephemeron?)]
	  [pos any/c]) 
	  (values any/c any/c)]
@defproc[#:link-target? #f
         (unsafe-ephemeron-hash-iterate-key+value
          [hash (and/c hash? hash-ephemeron?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  (values any/c any/c)]
@defproc[(unsafe-ephemeron-hash-iterate-pair
          [hash (and/c hash? hash-ephemeron?)]
	  [pos any/c]) 
	  pair?]
@defproc[#:link-target? #f
         (unsafe-ephemeron-hash-iterate-pair
          [hash (and/c hash? hash-ephemeron?)]
	  [pos any/c]
          [bad-index-v any/c]) 
	  pair?]
)]{
@racket[hash-iterate-key] 及类似过程的不安全版本。这些操作支持 @tech{监护}（chaperone）和 @tech{拟人化对象}（impersonator）。

每个不安全的 ...@code{-first} 和 ...@code{-next} 过程可能返回哈希结构视图的内部表示而非数字索引，从而实现更快的迭代。这些 ...@code{-first} 和 ...@code{-next} 函数的结果应作为 @racket[pos] 传递给相应的不安全访问器函数。

如果提供给可变 @racket[hash] 访问器函数的 @racket[pos] 之前是 @tech{有效哈希索引}，但不再是 @racket[hash] 的 @tech{有效哈希索引}，且未提供 @racket[bad-index-v]，则 @exnraise[exn:fail:contract]。对于从未是 @racket[hash] 的 @tech{有效哈希索引}的 @racket[pos]，未指定行为。注意，@racket[bad-index-v] 参数在技术上对 @code{unsafe-immutable-hash-iterate-} 函数无用，因为对于不可变 @racket[hash]，索引不会变为无效。

@history[#:added "6.4.0.6"
         #:changed "7.0.0.10" @elem{添加了可选的 @racket[bad-index-v] 参数。}
         #:changed "8.0.0.10" @elem{添加了 @schemeidfont{ephemeron} 变体。}]}

@defproc[(unsafe-make-srcloc [source any/c]
                             [line (or/c exact-positive-integer? #f)]
                             [column (or/c exact-nonnegative-integer? #f)]
                             [position (or/c exact-positive-integer? #f)]
                             [span (or/c exact-nonnegative-integer? #f)])
         srcloc?]{

@racket[srcloc] 的不安全版本。

@history[#:added "7.2.0.10"]}

@; ------------------------------------------------------------------------

@section[#:tag "unsafeextfl"]{不安全 Extflonum 操作}

@deftogether[(
@defproc[(unsafe-extfl+   [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(unsafe-extfl-   [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(unsafe-extfl*   [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(unsafe-extfl/   [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(unsafe-extflabs [a extflonum?]) extflonum?]
)]{

@racket[extfl+]、@racket[extfl-]、@racket[extfl*]、@racket[extfl/] 和 @racket[extflabs] 的未检查版本。}


@deftogether[(
@defproc[(unsafe-extfl=   [a extflonum?] [b extflonum?]) boolean?]
@defproc[(unsafe-extfl<   [a extflonum?] [b extflonum?]) boolean?]
@defproc[(unsafe-extfl>   [a extflonum?] [b extflonum?]) boolean?]
@defproc[(unsafe-extfl<=  [a extflonum?] [b extflonum?]) boolean?]
@defproc[(unsafe-extfl>=  [a extflonum?] [b extflonum?]) boolean?]
@defproc[(unsafe-extflmin [a extflonum?] [b extflonum?]) extflonum?]
@defproc[(unsafe-extflmax [a extflonum?] [b extflonum?]) extflonum?]
)]{

@racket[extfl=]、@racket[extfl<]、@racket[extfl>]、@racket[extfl<=]、@racket[extfl>=]、@racket[extflmin] 和 @racket[extflmax] 的未检查版本。}


@deftogether[(
@defproc[(unsafe-extflround [a extflonum?]) extflonum?]
@defproc[(unsafe-extflfloor [a extflonum?]) extflonum?]
@defproc[(unsafe-extflceiling [a extflonum?]) extflonum?]
@defproc[(unsafe-extfltruncate [a extflonum?]) extflonum?]
)]{

@racket[extflround]、@racket[extflfloor]、@racket[extflceiling] 和 @racket[extfltruncate] 的（潜在）未检查版本。目前，这些绑定只是相应安全绑定的别名。}


@deftogether[(
@defproc[(unsafe-extflsin [a extflonum?]) extflonum?]
@defproc[(unsafe-extflcos [a extflonum?]) extflonum?]
@defproc[(unsafe-extfltan [a extflonum?]) extflonum?]
@defproc[(unsafe-extflasin [a extflonum?]) extflonum?]
@defproc[(unsafe-extflacos [a extflonum?]) extflonum?]
@defproc[(unsafe-extflatan [a extflonum?]) extflonum?]
@defproc[(unsafe-extfllog [a extflonum?]) extflonum?]
@defproc[(unsafe-extflexp [a extflonum?]) extflonum?]
@defproc[(unsafe-extflsqrt [a extflonum?]) extflonum?]
@defproc[(unsafe-extflexpt [a extflonum?] [b extflonum?]) extflonum?]
)]{

@racket[extflsin]、@racket[extflcos]、@racket[extfltan]、@racket[extflasin]、@racket[extflacos]、@racket[extflatan]、@racket[extfllog]、@racket[extflexp]、@racket[extflsqrt] 和 @racket[extflexpt] 的（潜在）未检查版本。目前，其中一些绑定只是相应安全绑定的别名。}


@deftogether[(
@defproc[(unsafe-fx->extfl [a fixnum?]) extflonum?]
@defproc[(unsafe-extfl->fx [a extflonum?]) fixnum?]
)]{
@racket[fx->extfl] 和 @racket[extfl->fx] 的（潜在）未检查版本。

@history[#:changed "7.7.0.8" @elem{将 @racket[unsafe-fl->fx] 改为截断。}]}

@deftogether[(
@defproc[(unsafe-extflvector-length [v extflvector?]) fixnum?]
@defproc[(unsafe-extflvector-ref [v extflvector?] [k fixnum?]) extflonum?]
@defproc[(unsafe-extflvector-set! [v extflvector?] [k fixnum?] [x extflonum?]) void?]
)]{

@racket[extflvector-length]、@racket[extflvector-ref] 和 @racket[extflvector-set!] 的未检查版本。@tech{extflvector} 的大小永远不能大于 @tech{fixnum}（因此即使是 @racket[extflvector-length] 也总是返回 fixnum）。}

@; ------------------------------------------------------------------------

@section{不安全拟人化对象与监护}

@defproc[(unsafe-impersonate-procedure [proc procedure?]
                                       [replacement-proc procedure?]
                                       [prop impersonator-property?]
                                       [prop-val any] ... ...)
         (and/c procedure? impersonator?)]{

 类似 @racket[impersonate-procedure]，但假定 @racket[replacement-proc] 自身调用 @racket[proc]。当 @racket[unsafe-impersonate-procedure] 的结果应用于参数时，参数直接传递给 @racket[replacement-proc]，忽略 @racket[proc]。同时，@racket[impersonator-of?] 在给定 @racket[unsafe-impersonate-procedure] 的结果和 @racket[proc] 时报告 @racket[#t]。

 如果 @racket[proc] 本身是从 @racket[impersonate-procedure*] 或 @racket[chaperone-procedure*] 派生的拟人化对象，注意 @racket[replacement-proc] 将无法正确调用它。具体来说，由 @racket[unsafe-impersonate-procedure] 生成的拟人化对象不会传递给提供给 @racket[impersonate-procedure*] 或 @racket[chaperone-procedure*] 以生成 @racket[proc] 的包装过程。

 最后，与 @racket[impersonate-procedure] 不同，@racket[unsafe-impersonate-procedure] 不会将 @racket[impersonator-prop:application-mark] 作为 @racket[prop] 特殊处理。

 @racket[unsafe-impersonate-procedure] 的不安全性仅限于上述与 @racket[impersonate-procedure] 的区别。@racket[unsafe-impersonate-procedure] 的参数合约在提供参数时进行检查。

 作为一个示例，假设 @racket[f] 接受单个参数且非从 @racket[impersonate-procedure*] 或 @racket[chaperone-procedure*] 派生，则
 @racketblock[(λ (f)
                (unsafe-impersonate-procedure
                 f
                 (λ (x)
                   (if (number? x)
                       (error 'no-numbers!)
                       (f x)))))]
 等价于
 @racketblock[(λ (f)
                (impersonate-procedure
                 f
                 (λ (x)
                   (if (number? x)
                       (error 'no-numbers!)
                       x))))]
 
 类似地，在同样关于 @racket[f] 的假设下，以下两个过程 @racket[_wrap-f1] 和 @racket[_wrap-f2] 几乎等价；它们仅在参数是返回多值的函数时产生的错误消息不同（且它们更新不同的全局变量）。使用 @racket[unsafe-impersonate-procedure] 的版本将在 @racket[let] 表达式中发出关于多个返回值的错误，而使用 @racket[impersonate-procedure] 的版本从 @racket[impersonate-procedure] 发出关于多个返回值的错误。
 @racketblock[(define log1-args '())
              (define log1-results '())
              (define wrap-f1
                (λ (f)
                  (impersonate-procedure
                   f
                   (λ (arg)
                     (set! log1-args (cons arg log1-args))
                     (values (λ (res)
                               (set! log1-results (cons res log1-results))
                               res)
                             arg)))))
              
              (define log2-args '())
              (define log2-results '())
              (define wrap-f2
                (λ (f)
                  (unsafe-impersonate-procedure
                   f
                   (λ (arg)
                     (set! log2-args (cons arg log2-args))
                     (let ([res (f arg)])
                       (set! log2-results (cons res log2-results))
                       res)))))]

 @history[#:added "6.4.0.4"]
}


@defproc[(unsafe-chaperone-procedure [proc procedure?]
                                     [wrapper-proc procedure?]
                                     [prop impersonator-property?]
                                     [prop-val any] ... ...)
         (and/c procedure? chaperone?)]{
 类似 @racket[unsafe-impersonate-procedure]，但创建 @tech{监护}（chaperone）。由于 @racket[wrapper-proc] 将代替 @racket[proc] 被调用，假定 @racket[wrapper-proc] 返回 @racket[proc] 将返回的值的监护。

 @history[#:added "6.4.0.4"]
}

@defproc[(unsafe-impersonate-vector [vec vector?]
                                    [replacement-vec (and/c vector? (not/c impersonator?))]
                                    [prop impersonator-property?]
                                    [prop-val any/c] ... ...)
         (and/c vector? impersonator?)]{
 类似 @racket[impersonate-vector]，但不通过插入过程，所有对拟人化对象的访问都分发到 @racket[replacement-vec]。

 @racket[unsafe-impersonate-vector] 的结果是 @racket[vec] 的拟人化对象。

 @history[#:added "6.9.0.2"]
}
@defproc[(unsafe-chaperone-vector [vec vector?]
                                  [replacement-vec (and/c vector? (not/c impersonator?))]
                                  [prop impersonator-property?]
                                  [prop-val any/c] ... ...)
         (and/c vector? chaperone?)]{
 类似 @racket[unsafe-impersonate-vector]，但 @racket[unsafe-chaperone-vector] 的结果是 @racket[vec] 的监护。

 @history[#:added "6.9.0.2"]
}

@; ------------------------------------------------------------------------

@section[#:tag "unsafeassert"]{不安全断言}

@defproc[(unsafe-assert-unreachable) none/c]{

类似 @racket[assert-unreachable]，但 @racket[unsafe-assert-unreachable] 的合约永远不会被满足，"不安全"的含义是，如果到达对 @racket[unsafe-assert-unreachable] 的调用，任何事情都可能发生。

编译器可以利用其自由，选择便捷或高效的行为来代替对 @racket[unsafe-assert-unreachable] 的调用。例如，表达式

@racketblock[
(lambda (x)
  (if (pair? x)
      (car x)
      (unsafe-assert-unreachable)))
]

可能被编译为等价于以下代码

@racketblock[
(lambda (x) (unsafe-car x))
]

因为选择让 @racket[(unsafe-assert-unreachable)] 的行为与 @racket[(unsafe-car x)] 相同，使得 @racket[if] 的两个分支相同，从而可以消除 @racket[pair?] 测试。

@history[#:added "8.0.0.11"]}

@; ------------------------------------------------------------------------

@section[#:tag "unsafe-struct-type-prop"]{不安全结构类型属性}

@note-lib-only[racket/unsafe/struct-type-property]

@defproc[(unsafe-make-struct-type-property/guard-calls-no-arguments
          [name symbol?]
          [guard (or/c procedure? #f 'can-impersonate) #f]
          [supers (listof (cons/c struct-type-property?
                                  (any/c . -> . any/c)))
                  null]
          [can-impersonate? any/c #f]
          [accessor-name (or/c symbol? #f) #f]
          [contract-str (or/c string? symbol? #f) #f]
          [realm symbol? 'racket])
         (values struct-type-property?
                 (any/c . -> . boolean?)
                 procedure?)]{

与 @racket[make-struct-type-property] 相同，但断言 @racket[guard] 不调用包含在其属性值参数中的任何过程。类似地，@racket[supers] 中没有过程调用被包含的过程，且 @racket[supers] 中的属性没有调用被包含过程的 guard 或转换。

断言给定过程不会被属性的 guard 调用，可以减少检查并改进对使用该属性的结构类型操作的优化。具体来说，当由 @racket[unsafe-make-struct-type-property/guard-calls-no-arguments] 创建的属性用于结构类型声明时，并且当为该属性提供的值包含引用回结构类型声明绑定的过程（这是方法类属性的常见模式）时，编译器可以更容易地得出结论：在属性值中引用的已定义名称不会被过早引用。

@history[#:added "8.18.0.18"]}


@; ------------------------------------------------------------------------

@include-section["unsafe-undefined.scrbl"]

