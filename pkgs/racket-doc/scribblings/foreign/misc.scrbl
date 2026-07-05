#lang scribble/doc
@(require "utils.rkt")

@title{杂项支持}

@defproc[(list->cblock [lst list?]
                       [type ctype?]
                       [expect-length (or/c exact-nonnegative-integer? #f) #f]
                       [#:malloc-mode malloc-mode (or/c #f symbol?) #f])
         cpointer?]{

为适当大小的内存块分配空间——使用 @racket[malloc] 配合 @racket[type] 和
@racket[(length lst)]——并用 @racket[lst] 中的值进行初始化。
@racket[lst] 必须包含都可以根据给定的 @racket[type] 转换为 C 值的元素。

如果 @racket[expect-length] 不是 @racket[#f] 且不等于 @racket[(length lst)]，
则不会分配内存，而是引发异常。

如果 @racket[malloc-mode] 不是 @racket[#f]，它将作为额外的参数传递给 @racket[malloc]。

@history[#:changed "7.7.0.2" @elem{添加了 @racket[#:malloc-mode] 参数。}]}


@defproc[(vector->cblock [vec vector?]
                         [type ctype?]
                         [expect-length (or/c exact-nonnegative-integer? #f) #f]
                         [#:malloc-mode malloc-mode (or/c #f symbol?) #f])
         cpointer?]{

类似于 @racket[list->cblock]，但使用 vector 而非 list 中的值。

@history[#:changed "7.7.0.2" @elem{添加了 @racket[#:malloc-mode] 参数。}]}


@defproc[(vector->cpointer [vec vector?]) cpointer?]{

返回指向一个 @racket[_scheme] 值数组的指针，即 @racket[vec] 的内部表示。}

@defproc[(flvector->cpointer [flvec flvector?]) cpointer?]{

返回指向一个 @racket[_double] 值数组的指针，即 @racket[flvec] 的内部表示。}

@defproc*[([(saved-errno) exact-integer?]
           [(saved-errno [new-value exact-integer?]) void?])]{

返回或设置当前 Racket 线程的保存错误码。保存的错误码是在 foreign 调用
时通过非 @racket[#f] 的 @racket[#:save-errno] 选项（参见 @racket[_fun] 和
@racket[_cprocedure]）设置的，但也可以显式设置（例如，用于创建测试用的 mock
foreign 函数）。

@history[#:changed "6.4.0.9"]{添加了一个参数的变体。}}

@defproc[(lookup-errno [sym symbol?])
         (or/c exact-integer? #f)]{

返回对应于 POSIX @tt{errno} 码的特定于平台的正整数，或如果该码未知则返回
@racket[#f]。一个码的值是已知的，当且仅当它是下面描述的已识别的 symbols 之一，
并且该码是由编译 Racket 时使用的 @tt{"errno.h"} 头文件定义的。注意，
@tt{"errno.h"} 的内容因平台和编译器而异。

当前识别的 symbols 包括
@hyperlink["http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/errno.h.html"]{IEEE
Std 1003.1, 2013 Edition}（又称 POSIX.1）中定义的 81 个码，
包括 @racket['EINTR]、@racket['EEXIST] 和 @racket['EAGAIN]。

另参见 @racket[exn-classify-errno]。

@history[#:changed "6.6.0.5" @elem{放宽了 contract 并添加了对更多 symbols 的支持。}]}


@defproc[(cast [v any/c] [from-type ctype?] [to-type ctype?]) any/c]{

将 @racket[v] 从匹配 @racket[from-type] 的值转换为匹配 @racket[to-type] 的值，
其中 @racket[(ctype-sizeof from-type)] 与 @racket[(ctype-sizeof to-type)] 相匹配。

转换大致等同于

@racketblock[
  (let ([p (malloc from-type)])
    (ptr-set! p from-type v)
    (ptr-ref p to-type))
]

如果 @racket[v] 是一个 cpointer，@racket[(cpointer-gcable?  v)] 为 true，
并且 @racket[from-type] 和 @racket[to-type] 都基于 @racket[_pointer] 或
@racket[_gcpointer]，则 @racket[from-type] 会通过 @racket[_gcable]
隐式转换，以确保结果的 cpointer 被视为指向由垃圾收集器管理的内存。

如果 @racket[v] 是具有 offset 分量的 pointer（例如，来自
@racket[ptr-add]），@racket[(cpointer-gcable? v)] 为 true，结果是 cpointer，
则结果 pointer 与 @racket[v] 具有相同的 offset 分量。如果
@racket[(cpointer-gcable? v)] 为 false，则任何 offset 都会被合并到结果的 pointer
base 中。}


@defproc[(cblock->list [cblock any/c] [type ctype?] [length exact-nonnegative-integer?])
         list?]{

将 C @racket[cblock]（一个 @racket[type]s 的 vector）转换为 Racket list。
参数与 @racket[list->cblock] 中的相同。必须指定 @racket[length]，因为
无法知道 block 的末尾在哪里。}


@defproc[(cblock->vector [cblock any/c] [type ctype?] [length exact-nonnegative-integer?])
         vector?]{

类似 @racket[cblock->list]，但用于 Racket vectors。}
