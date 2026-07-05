#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/fixnum
                     racket/fasl
                     racket/serialize)
          (for-syntax racket/base))

@(define-syntax (sv-example stx)
   (syntax-case stx ()
     [(_ . strs)
      (with-syntax ([(form ...) (for/list ([str (in-list (syntax->datum #'strs))])
                                           #:unless (equal? "\n" str))
                                  (with-syntax ([str str]
                                                [e (read (open-input-string str))])
                                    #'(eval:alts #,(code str) e)))])
         (syntax-local-introduce #'@mz-examples[form ...]))]))

@title[#:tag "stencil vectors"]{模板向量}

@deftech{模板向量}类似于 @tech{vector}，但它有一个关联的掩码 @tech{fixnum}，其中掩码中设置的位数决定了向量的长度。模板向量对于实现某些数据结构很有用 @cite["Torosyan21"]，例如哈希数组映射 trie（HAMT）。

从概念上讲，模板向量的掩码指示完整大小的模板向量中哪些虚拟元素存在，但掩码位对通过 @racket[stencil-vector-ref] 和 @racket[stencil-vector-set!] 的访问或突变没有影响。例如，这样的模板向量有一个掩码 @racket[25]，也可以写作 @racketvalfont{#b11001}；从低位到高位读取，该掩码表示虚拟槽位 0、3 和 4 处存在值。如果该模板向量的元素是 @racket['a]、@racket['b] 和 @racket['c]，则 @racket['a] 在虚拟槽位 0 并通过索引 @racket[0] 访问，@racket['b] 在虚拟槽位 3 并通过索引 @racket[1] 访问，@racket['c] 在虚拟槽位 4 并通过索引 @racket[2] 访问。

掩码中位的相对顺序对于使用 @racket[stencil-vector-update] 的函数式更新操作 @emph{是} 相关的。要删除的元素通过删除掩码指定，要添加的元素通过添加掩码相对于剩余元素排序。例如，从掩码为 @racketvalfont{#b11001}、元素为 @racket['a]、@racket['b] 和 @racket['c] 的模板向量开始，使用添加掩码 @racketvalfont{#b100100} 添加新元素 @racket['d] 和 @racket['e] 会产生一个掩码为 @racketvalfont{#b111101} 的模板向量，其元素依次为 @racket['a]、@racket['d]、@racket['b]、@racket['c] 和 @racket['e]。

模板向量在 64 位平台上的最大大小为 58 个元素，在 32 位平台上为 26 个元素。此有限大小支持紧凑的内部表示，并确保更新操作相对简单。模板向量是可变的，尽管它们主要用于无突变以实现持久化数据结构。

如果两个模板向量具有相同的掩码，并且对应槽位的值是 @racket[equal?] 的，则它们是 @racket[equal?] 的。

打印的向量以 @litchar{#<stencil ...>} 开头，这种打印形式不能被 @racket[read] 解析。@racket[s-exp->fasl] 和 @racket[serialize] 函数不支持模板向量，部分原因是 64 位平台上的模板向量可能无法在 32 位平台上表示。模板向量的目的是用作数据类型实现的内存表示。

@history[#:added "8.5.0.7"]


@defproc[(stencil-vector? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{模板向量}，则返回 @racket[#t]，否则返回 @racket[#f]。

@sv-example{
(stencil-vector #b10010 'a 'b)
(stencil-vector #b111 'a 'b 'c)
}

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-mask-width) exact-nonnegative-integer?]{

返回当前平台上模板向量中允许的最大元素数。在 64 位平台上结果为 @racket[58]，在 32 位平台上为 @racket[26]。}


@defproc[(stencil-vector [mask (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]
                         [v any/c]
                         ...)
         stencil-vector?]{

返回一个将 @racket[mask] 与元素 @racket[v] 组合的模板向量。提供的 @racket[v] 的数量必须与 @racket[mask] 的二进制补码表示中设置的位数匹配。

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-mask [vec stencil-vector?])
         (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]{

返回 @racket[vec] 的掩码。请注意，模板向量的掩码在创建时间确定，之后无法更改。

@sv-example{
(stencil-vector-mask (stencil-vector #b10010 'a 'b))
}

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-length [vec stencil-vector?])
         (integer-in 0 (sub1 (expt 2 (stencil-vector-mask-width))))]{

返回 @racket[vec] 的长度（即向量中的槽位数）。结果与 @racket[(fxpopcount (stencil-vector-mask vec))] 相同。

@sv-example{
(stencil-vector-length (stencil-vector #b10010 'a 'b))
}

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-ref [vec stencil-vector?]
                             [pos exact-nonnegative-integer?])
         any/c]{

返回 @racket[vec] 中槽位 @racket[pos] 处的元素。第一个槽位是位置 @racket[0]，最后一个槽位比 @racket[(stencil-vector-length vec)] 少一。

@sv-example{
(stencil-vector-ref (stencil-vector #b10010 'a 'b) 1)
(stencil-vector-ref (stencil-vector #b111 'a 'b 'c) 1)
}

@history[#:added "8.5.0.7"]}


@defproc[(stencil-vector-set! [vec stencil-vector?]
                              [pos exact-nonnegative-integer?]
                              [v any/c])
         void?]{

更新 @racket[vec] 的槽位 @racket[pos] 以包含 @racket[v]。

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

返回一个类似于 @racket[vec] 的模板向量，但移除了与 @racket[remove-mask] 对应的元素，并根据 @racket[add-mask] 添加给定的 @racket[v]s，位置相对于现有（未移除的）元素。

@sv-example{
(define st-vec (stencil-vector #b101 'a 'b))
(stencil-vector-update st-vec #b0 #b10 'c)
(stencil-vector-update st-vec #b0 #b1000 'c)
st-vec ; 更新不变
(stencil-vector-update st-vec #b1 #b1 'c)
(stencil-vector-update st-vec #b100 #b100 'c)
(stencil-vector-update st-vec #b100 #b0)
}

@history[#:added "8.5.0.7"]}
