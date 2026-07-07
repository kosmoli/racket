#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/fixnum
                     racket/fasl
                     racket/serialize)
          (for-syntax racket/base))

@(define-syntax (sv-example stx)
   (syntax-case stx ()
     [(_ . strs)
      (with-syntax ([(form ...) (for/list ([str (in-list (syntax->datum #'strs))]
                                           #:unless (equal? "\n" str))
                                  (with-syntax ([str str]
                                                [e (read (open-input-string str))])
                                    #'(eval:alts #,(code str) e)))])
         #'@mz-examples[form ...])]))

@title[#:tag "stencil vectors"]{Stencil Vectors}

@deftech{stencil vector}（stencil 向量）类似于 @tech{vector}，但它带有一个关联的
掩码 @tech{fixnum}，掩码中置位的位数决定了向量的长度。stencil 向量可用于实现某些数据
结构 @cite["Torosyan21"]，例如哈希数组映射前缀树（HAMT）。

从概念上讲，stencil 向量的掩码指示了完整大小的 stencil 向量中哪些虚拟元素是存在的，
但掩码位对通过 @racket[stencil-vector-ref] 和 @racket[stencil-vector-set!] 进行的
访问或修改没有影响。例如，这样一个 stencil 向量的掩码为 @racket[25]，也可以写作
@racketvalfont{#b11001}；从低位到高位读取，该掩码表示第一个、第四个和第五个虚拟
位置存在值。如果该 stencil 向量的元素为 @racket['a]、@racket['b] 和 @racket['c]，
那么 @racket['a] 位于虚拟位置 0，使用索引 @racket[0] 访问；@racket['b] 位于虚拟位置 3，
使用索引 @racket[1] 访问；@racket['c] 位于虚拟位置 4，使用索引 @racket[2] 访问。

掩码中位的相对顺序对于使用 @racket[stencil-vector-update] 进行的功能性更新操作
@emph{是}相关的。要移除的元素通过移除掩码指定，要添加的元素通过添加掩码相对于
剩余元素来确定顺序。例如，从掩码为 @racketvalfont{#b11001}、元素为 @racket['a]、
@racket['b] 和 @racket['c] 的 stencil 向量开始，使用添加掩码
@racketvalfont{#b100100} 添加新元素 @racket['d] 和 @racket['e]，将产生一个掩码为
@racketvalfont{#b111101}、元素依次为 @racket['a]、@racket['b]、@racket['d]、
@racket['c] 和 @racket['e] 的 stencil 向量。

stencil 向量的最大大小在 64 位平台上为 58 个元素，在 32 位平台上为 26 个元素。
这种有限的大小使得内部表示更加紧凑，并确保更新操作相对简单。stencil 向量是可变的，
但主要设计用于在不变异的情况下实现持久化数据结构。

当两个 stencil 向量具有相同的掩码，且对应位置的值满足 @racket[equal?] 时，它们是
@racket[equal?] 的。

打印的向量以 @litchar{#<stencil ...>} 开头，且该打印形式不能被 @racket[read] 解析。
@racket[s-exp->fasl] 和 @racket[serialize] 函数不支持 stencil 向量，部分原因是
64 位平台上的 stencil 向量可能无法在 32 位平台上表示。stencil 向量的用途是作为
数据类型实现的内存中表示。

@history[#:added "8.5.0.7"]


@defproc[(stencil-vector? [v any/c]) boolean?]{

当 @racket[v] 是 @tech{stencil vector} 时返回 @racket[#t]，否则返回 @racket[#f]。

@sv-example{
(stencil-vector #b10010 'a 'b)
(stencil-vector #b111 'a 'b 'c)
}

@history[#:added "8.5.0.7"]}

@defproc[(stencil-vector-mask-width) exact-nonnegative-integer?]{

返回当前平台上 stencil 向量允许的最大元素数量。在 64 位平台上结果为 @racket[58]，
在 32 位平台上结果为 @racket[26]。}


@defproc[(stencil-vector [mask (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]
                         [v any/c]
                         ...)
         stencil-vector?]{

返回一个将 @racket[mask] 与元素 @racket[v] 组合在一起的 stencil 向量。
提供的 @racket[v] 的数量必须与 @racket[mask] 的二进制补码表示中置位的位数相匹配。

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-mask [vec stencil-vector?])
         (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]{

返回 @racket[vec] 的掩码。注意，stencil 向量的掩码在创建时确定，之后无法更改。

@sv-example{
(stencil-vector-mask (stencil-vector #b10010 'a 'b))
}

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-length [vec stencil-vector?])
         (integer-in 0 (sub1 (stencil-vector-mask-width)))]{

返回 @racket[vec] 的长度（即向量中的槽数）。结果与
@racket[(fxpopcount (stencil-vector-mask vec))] 相同。

@sv-example{
(stencil-vector-length (stencil-vector #b10010 'a 'b))
}

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-ref [vec stencil-vector?]
                             [pos exact-nonnegative-integer?])
         any/c]{

返回 @racket[vec] 中位置 @racket[pos] 的元素。第一个位置为 @racket[0]，
最后一个位置为 @racket[(stencil-vector-length vec)] 减一。

@sv-example{
(stencil-vector-ref (stencil-vector #b10010 'a 'b) 1)
(stencil-vector-ref (stencil-vector #b111 'a 'b 'c) 1)
}

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-set! [vec stencil-vector?]
                              [pos exact-nonnegative-integer?]
                              [v any/c])
         avoid?]{

将 @racket[vec] 中位置 @racket[pos] 的内容更新为 @racket[v]。

@sv-example{
(define st-vec (stencil-vector #b101 'a 'b))
st-vec
(stencil-vector-set! st-vec 1 'c)
st-vec}

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-update [vec stencil-vector?]
                                [remove-mask (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]
                                [add-mask (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]
                                [v any/c]
                                ...)
         stencil-vector?]{

返回一个类似于 @racket[vec] 的 stencil 向量，但移除了与 @racket[remove-mask] 对应的
元素，并根据 @racket[add-mask] 在相对于现有（未移除的）元素的位置添加给定的 @racket[v]。

@sv-example{
(define st-vec (stencil-vector #b101 'a 'b))
(stencil-vector-update st-vec #b0 #b10 'c)
(stencil-vector-update st-vec #b0 #b1000 'c)
st-vec ; 不因更新而改变
(stencil-vector-update st-vec #b1 #b1 'c)
(stencil-vector-update st-vec #b100 #b100 'c)
(stencil-vector-update st-vec #b100 #b0)
}

@history[#:added "8.5.0.7"]}
