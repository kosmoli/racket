#lang scribble/doc
@(require "mz.rkt" racket/math scribble/extract
          (for-label racket/math
                     racket/flonum
                     racket/fixnum
                     racket/unsafe/ops
                     racket/require))

@(define flfx-eval (make-base-eval))
@examples[#:hidden #:eval flfx-eval (require racket/fixnum)]


@title[#:tag "fixnums"]{Fixnum}

@defmodule[racket/fixnum]

@racketmodname[racket/fixnum] 库提供了类似 @racket[fx+] 的操作，
仅消耗和产生 @tech{fixnum}。本库中的操作旨在作为不安全操作
（如 @racket[unsafe-fx+]）的安全版本。这些安全操作通常不会比
使用 @racket[+] 等通用原语更快。

@racketmodname[racket/fixnum] 库的预期用途是替换代码中对
@racketmodname[racket/fixnum] 的 @racket[require]，替换为

@margin-note{参见 @racket[filtered-in] 的文档，了解如何与 @racket[@#,(hash-lang) @#,racketmodname[racket/base]] 配合使用。}

@racketblock[(require (filtered-in
                       (λ (name)
                         (and (regexp-match #rx"^unsafe-fx" name)
                              (regexp-replace #rx"unsafe-" name "")))
                       racket/unsafe/ops)]

以替换为库的不安全版本。或者，当遇到使用不安全 fixnum 操作的
代码崩溃时，可使用 @racketmodname[racket/fixnum] 库来帮助调试问题。

@; ------------------------------------------------------------

@section{Fixnum 算术}

@deftogether[(
@defproc[(fx+ [a fixnum?] ...) fixnum?]
@defproc[(fx- [a fixnum?] [b fixnum?] ...) fixnum?]
@defproc[(fx* [a fixnum?] ...) fixnum?]
@defproc[(fxquotient  [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(fxremainder [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(fxmodulo    [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(fxabs       [a fixnum?]) fixnum?]
)]{

@racket[unsafe-fx+]、@racket[unsafe-fx-]、
@racket[unsafe-fx*]、@racket[unsafe-fxquotient]、
@racket[unsafe-fxremainder]、@racket[unsafe-fxmodulo] 和
@racket[unsafe-fxabs] 的安全版本。如果算术结果不是 fixnum，
则 @exnraise[exn:fail:contract:non-fixnum-result]。

@history[#:changed "7.0.0.13" @elem{允许 @racket[fx+] 和 @racket[fx*] 接受零个或更多参数，
                                    以及 @racket[fx-] 接受一个或更多参数。}]}


@deftogether[(
@defproc[(fxand [a fixnum?] ...) fixnum?]
@defproc[(fxior [a fixnum?] ...) fixnum?]
@defproc[(fxxor [a fixnum?] ...) fixnum?]
@defproc[(fxnot [a fixnum?]) fixnum?]
@defproc[(fxlshift [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(fxrshift [a fixnum?] [b fixnum?]) fixnum?]
)]{

类似于 @racket[bitwise-and]、@racket[bitwise-ior]、
@racket[bitwise-xor]、@racket[bitwise-not] 和
@racket[arithmetic-shift]，但仅限于消耗 @tech{fixnum}；
结果始终为 @tech{fixnum}。@racket[unsafe-fxlshift] 和
@racket[unsafe-fxrshift] 操作对应于 @racket[arithmetic-shift]，
但要求参数非负；@racket[unsafe-fxlshift] 是正（即左）移，
@racket[unsafe-fxrshift] 是负（即右）移，其中移动的位数
不得超过用于表示 @tech{fixnum} 的位数。如果算术结果不是
fixnum，则 @exnraise[exn:fail:contract:non-fixnum-result]。

@history[#:changed "7.0.0.13" @elem{允许 @racket[fxand]、@racket[fxior]
                                    和 @racket[fxxor] 接受任意数量的参数。}]}


@deftogether[(
@defproc[(fxpopcount [a (and/c fixnum? (not/c negative?))]) fixnum?]
@defproc[(fxpopcount32 [a (and/c fixnum? (integer-in 0 @#,racketvalfont{#xFFFFFFFF}))]) fixnum?]
@defproc[(fxpopcount16 [a (and/c fixnum? (integer-in 0 @#,racketvalfont{#xFFFF})) ]) fixnum?]
)]{

计算 @racket[a] 的二进制补码表示中的位数。根据平台不同，
当结果已知不超过 32 或 16 时，@racket[fxpopcount32] 和
@racket[fxpopcount16] 操作可以更快。

@history[#:added "8.5.0.7"]}

@deftogether[(
@defproc[(fx+/wraparound [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(fx-/wraparound [a fixnum? 0] [b fixnum?]) fixnum?]
@defproc[(fx*/wraparound [a fixnum?] [b fixnum?]) fixnum?]
@defproc[(fxlshift/wraparound [a fixnum?] [b fixnum?]) fixnum?]
)]{

类似于 @racket[fx+]、@racket[fx-]、@racket[fx*] 和 @racket[fxlshift]，
但对任何允许的参数（即任何 fixnum 参数，除了第二个
@racket[fxlshift/wraparound] 参数必须在 0 到 fixnum 位数之间（含））
都会产生一个 fixnum 结果。结果通过简单丢弃不适合 fixnum 表示的位来生成。
如果保留的最高位被设置，则结果为负——例如，即使该值是通过两个正 fixnum 相加产生的。

@history[#:added "7.9.0.6"
         #:changed "8.15.0.12" @elem{更改 @racket[fx-/wraparound] 以接受单个参数。}]}

@defproc[(fxrshift/logical [a fixnum?] [b fixnum?]) fixnum?]{

将 @racket[a] 中的位向右移动 @racket[b] 位，用零填充。
将符号位视为普通位时，负数 fixnum 的逻辑右移可以产生
一个大的正数 fixnum。例如，@racket[(fxrshift/logical -1 1)] 产生
@racket[(most-positive-fixnum)]，说明逻辑右移结果是平台相关的。

@mz-examples[
  #:eval flfx-eval
  (fxrshift/logical 128 2)
  (fxrshift/logical 255 4)
  (= (fxrshift/logical -1 1) (most-positive-fixnum))
]

@history[#:added "8.8.0.5"]}


@deftogether[(
@defproc[(fx=   [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(fx<   [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(fx>   [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(fx<=  [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(fx>=  [a fixnum?] [b fixnum?] ...) boolean?]
@defproc[(fxmin [a fixnum?] [b fixnum?] ...) fixnum?]
@defproc[(fxmax [a fixnum?] [b fixnum?] ...) fixnum?]
)]{

类似于 @racket[=]、@racket[<]、@racket[>]、
@racket[<=]、@racket[>=]、@racket[min] 和 @racket[max]，
但仅限于消耗 @tech{fixnum}。

@history/arity[]}

@deftogether[(
@defproc[(fx->fl [a fixnum?]) flonum?]
@defproc[(fl->fx [fl flonum?]) fixnum?]
)]{

@tech{fixnum} 和 @tech{flonum} 之间的转换，在将 @tech{flonum}
转换为 @tech{fixnum} 时进行截断。

@racket[fx->fl] 函数与 @racket[exact->inexact] 或 @racket[->fl]
相同，但限制为 fixnum 参数。

@racket[fl->fx] 函数与 @racket[truncate] 后跟 @racket[inexact->exact]
或 @racket[fl->exact-integer] 相同，但限制为返回 fixnum。
如果截断后的 flonum 无法放入 fixnum，则 @exnraise[exn:fail:contract]。

@history[#:changed "7.7.0.8" @elem{Changed @racket[fl->fx] to truncate.}]}


@defproc[(fixnum-for-every-system? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{fixnum} and is
represented by fixnum by every Racket implementation, @racket[#f]
otherwise.

@history[#:added "7.3.0.11"]}


@; ------------------------------------------------------------

@section[#:tag "fxvectors"]{Fixnum Vectors}

A @deftech{fxvector} is like a @tech{vector}, but it holds only
@tech{fixnums}. The only advantage of a @tech{fxvector} over a
@tech{vector} is that a shared version can be created with functions
like @racket[shared-fxvector].

Two @tech{fxvectors} are @racket[equal?] if they have the same length,
and if the values in corresponding slots of the @tech{fxvectors} are
@racket[equal?].

A printed @tech{fxvector} starts with @litchar{#fx(}, optionally with
a number between the @litchar{#fx} and
@litchar{(}. @see-read-print["vector" #:print "vectors"]{fxvectors}

@defproc[(fxvector? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{fxvector}, @racket[#f] otherwise.}

@defproc[(fxvector [x fixnum?] ...) fxvector?]{

Creates a @tech{fxvector} containing the given @tech{fixnums}.

@mz-examples[#:eval flfx-eval (fxvector 2 3 4 5)]}

@defproc[(make-fxvector [size exact-nonnegative-integer?]
                        [x fixnum? 0]) 
         fxvector?]{

Creates a @tech{fxvector} with @racket[size] elements, where every
slot in the @tech{fxvector} is filled with @racket[x].

@mz-examples[#:eval flfx-eval (make-fxvector 4 3)]}

@defproc[(fxvector-length [vec fxvector?]) exact-nonnegative-integer?]{

Returns the length of @racket[vec] (i.e., the number of slots in the
@tech{fxvector}).}


@defproc[(fxvector-ref [vec fxvector?] [pos exact-nonnegative-integer?])
         fixnum?]{

Returns the @tech{fixnum} in slot @racket[pos] of
@racket[vec]. The first slot is position @racket[0], and the last slot
is one less than @racket[(fxvector-length vec)].}

@defproc[(fxvector-set! [vec fxvector?] [pos exact-nonnegative-integer?]
                        [x fixnum?])
         fixnum?]{

Sets the @tech{fixnum} in slot @racket[pos] of @racket[vec]. The
first slot is position @racket[0], and the last slot is one less than
@racket[(fxvector-length vec)].}

@defproc[(fxvector-copy [vec fxvector?]
                        [start exact-nonnegative-integer? 0]
                        [end exact-nonnegative-integer? (vector-length v)]) 
         fxvector?]{

Creates a fresh @tech{fxvector} of size @racket[(- end start)], with all of the
elements of @racket[vec] from @racket[start] (inclusive) to
@racket[end] (exclusive).}

@defproc[(in-fxvector [vec fxvector?]
                    [start exact-nonnegative-integer? 0]
                    [stop (or/c exact-integer? #f) #f]
                    [step (and/c exact-integer? (not/c zero?)) 1])
         sequence?]{
  Returns a sequence equivalent to @racket[vec] when no optional
  arguments are supplied.

  The optional arguments @racket[start], @racket[stop], and
  @racket[step] are as in @racket[in-vector].

  An @racket[in-fxvector] application can provide better
  performance for @tech{fxvector} iteration when it appears directly in a @racket[for] clause.
}

@deftogether[(
@defform[(for/fxvector maybe-length (for-clause ...) body ...)]
@defform/subs[(for*/fxvector maybe-length (for-clause ...) body ...)
              ([maybe-length (code:line)
                             (code:line #:length length-expr)
                             (code:line #:length length-expr #:fill fill-expr)])
              #:contracts ([length-expr exact-nonnegative-integer?]
                           [fill-expr fixnum?])]
)]{

Like @racket[for/vector] or @racket[for*/vector], but for
@tech{fxvector}s. The default @racket[fill-expr] produces @racket[0].}

@defproc[(shared-fxvector [x fixnum?] ...) fxvector?]{

Creates a @tech{fxvector} containing the given @tech{fixnums}.
For communication among @tech{places}, the new @tech{fxvector} is 
allocated in the @tech{shared memory space}.

@mz-examples[#:eval flfx-eval (shared-fxvector 2 3 4 5)]}


@defproc[(make-shared-fxvector [size exact-nonnegative-integer?]
                               [x fixnum? 0]) 
         fxvector?]{

Creates a @tech{fxvector} with @racket[size] elements, where every
slot in the @tech{fxvector} is filled with @racket[x].
For communication among @tech{places}, the new @tech{fxvector} is 
allocated in the @tech{shared memory space}.

@mz-examples[#:eval flfx-eval (make-shared-fxvector 4 3)]}

@; ------------------------------------------------------------

@section[#:tag "fxrange"]{Fixnum Range}

@deftogether[(
@defproc[(most-positive-fixnum) fixnum?]
@defproc[(most-negative-fixnum) fixnum?]
)]{

Returns the largest-magnitude positive and negative @tech{fixnums}.
The values of @racket[(most-positive-fixnum)] and
@racket[(most-negative-fixnum)] depend on the platform and virtual
machine, but all fixnums are in the range
@racket[(most-negative-fixnum)] to @racket[(most-positive-fixnum)]
inclusive, and all exact integers in that range are fixnums.

@history[#:added "8.1.0.7"]}


@close-eval[flfx-eval]
