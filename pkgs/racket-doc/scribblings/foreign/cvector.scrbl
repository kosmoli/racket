#lang scribble/doc
@(require "utils.rkt")

@title[#:tag "foreign:cvector"]{安全的 C 向量}

@defmodule*[(ffi/cvector ffi/unsafe/cvector) 
            #:use-sources (ffi/unsafe/cvector)]{@racketmodname[ffi/unsafe/cvector] 库导出本节中的绑定。@racketmodname[ffi/cvector] 库导出相同的绑定，但不包括不安全的 @racket[make-cvector*] 操作。}

@racket[cvector] 形式可以用作 C 向量类型（即指向内存块的指针）。

@defform*[(_cvector mode type maybe-len)
           _cvector]{

与 @racket[_bytes] 类似，@racket[_cvector] 可以用作简单类型，对应于在 Racket 端作为安全 C 向量管理的指针。较长形式的行为类似于 @racket[_list] 和 @racket[_vector] 自定义类型，但 @racket[_cvector] 更高效；不需要 Racket list 或 vector。}

@defproc[(make-cvector [type ctype?] [length exact-nonnegative-integer?]) cvector?]{

使用给定的 @racket[type] 和 @racket[length] 分配一个 C 向量。结果向量不保证包含任何特定值。}


@defproc[(cvector [type ctype?] [val any/c] ...) cvector?]{

创建给定 @racket[type] 的 C 向量，用 @racket[val] 列表进行初始化。}


@defproc[(cvector? [v any/c]) boolean?]{

如果 @racket[v] 是 C 向量则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(cvector-length [cvec cvector?]) exact-nonnegative-integer?]{

返回 C 向量的长度。}


@defproc[(cvector-type [cvec cvector?]) ctype?]{

返回 C 向量的 C 类型对象。}


@defproc[(cvector-ptr [cvec cvector?]) cpointer?]{

返回指向给定 C 向量起始内存块的指针。}


@defproc[(cvector-ref [cvec cvector?] [k exact-nonnegative-integer?]) any]{

引用 @racket[cvec] C 向量的第 @racket[k] 个元素。结果具有 C 向量所使用的类型。}


@defproc[(cvector-set! [cvec cvector?] [k exact-nonnegative-integer?] [val any]) void?]{

将 @racket[cvec] C 向量的第 @racket[k] 个元素设置为 @racket[val]。@racket[val] 参数应该是可用于 C 向量类型的值。}


@defproc[(cvector->list [cvec cvector?]) list?]{

将 @racket[cvec] C 向量对象转换为值列表。}


@defproc[(list->cvector [lst list?] [type ctype?]) cvector?]{

将列表 @racket[lst] 转换为给定 @racket[type] 的 C 向量。}


@defproc[(make-cvector* [cptr any/c] [type ctype?]
                        [length exact-nonnegative-integer?])
                        cvector?]{

使用现有指针对象构造一个 C 向量。此操作不安全，因此仅在已知 @racket[type] 和 @racket[length] 的特定情况下使用。}

