#lang scribble/doc
@(require "utils.rkt")

@title[#:tag "foreign:tagged-pointers"]{Tagged C Pointer 类型}

不安全的 @racket[cpointer-has-tag?] 和 @racket[cpointer-push-tag!] 操作管理 tag 以区分 pointer 类型。

@defproc*[((_cpointer [tag any/c]
                       [ptr-type (or/c ctype? #f) _pointer]
                       [racket-to-c (or/c (any/c . -> . any/c) #f) values]
                       [c-to-racket (or/c (any/c . -> . any/c) #f) values])
            ctype?]
           [(_cpointer/null [tag any/c]
                            [ptr-type (or/c ctype? #f) _pointer]
                            [racket-to-c (or/c (any/c . -> . any/c) #f) values]
                            [c-to-racket (or/c (any/c . -> . any/c) #f) values])
            ctype?])]{

构造一个 C pointer 类型 @racket[__tag]，当转换为 Racket 时获得特定 tag，并且在传入 C 时只接受此类带 tag 的 pointer。任何可选参数中，@racket[#f] 被视为等同于参数的默认值。

@racket[ptr-type] 用作 @racket[__tag] 的基础 pointer 类型。@racket[ptr-type] 的值必须表示为 pointer。

尽管任何值都可以用作 @racket[tag]，按照惯例它是类型名的 symbol 形式——不带前导下划线。例如，pointer 类型 @racketidfont{_animal} 通常使用 @racket['animal] 作为 tag。

Pointer tag 通过 @racket[cpointer-has-tag?] 检查并通过 @racket[cpointer-push-tag!] 更改，这意味着其他 tag 在现有 pointer 值上被保留。特别地，如果给定一个基础 @racket[ptr-type] 且它本身由 @racket[_cpointer] 产生，则新类型将处理具有新 tag 以及 @racket[ptr-type] 的 tag 的 pointer。当 tag 是一个 pair 时，其第一个值用于打印，因此最近推送的 tag（对应于继承类型）会被显示。

要用作 @racket[__tag] 值的 Racket 值首先传递给 @racket[racket-to-c]，结果必须是带有 @racket[tag] tag 的指针。类似地，要作为 @racket[__tag] 返回的 C 值最初表示为带 @racket[tag] tag 的指针，然后传递给 @racket[c-to-racket] 以获得 Racket 表示。因此，@racket[__tag] 值在 C 层面由 pointer 表示（但与给定的 @racket[ptr-type] 不同），它在 Racket 层面可以有任何表示，由 @racket[racket-to-c] 和 @racket[c-to-racket] 实现。

@racket[_cpointer/null] 函数类似于 @racket[_cpointer]，除了传入 C 和返回时都容忍 @cpp{NULL} pointer。注意 @cpp{NULL} pointer 在 Racket 中表示为 @racket[#f]，因此不被 tag。

@defform*[[(define-cpointer-type _id)
           (define-cpointer-type _id #:tag tag-expr)
           (define-cpointer-type _id ptr-type-expr)
           (define-cpointer-type _id ptr-type-expr #:tag tag-expr)
           (define-cpointer-type _id ptr-type-expr 
                                 racket-to-c-expr c-to-racket-expr)
           (define-cpointer-type _id ptr-type-expr 
                                 racket-to-c-expr c-to-racket-expr
                                 #:tag tag-expr)]]{

@racket[_cpointer] 和 @racket[_cpointer/null] 的宏版本，使用定义的名称作为 tag symbol，并同时定义 predicate。@racket[_id] 必须以 @litchar{_} 开头。

可选表达式产生 @racket[_cpointer] 的可选参数。

除了将 @racket[_id] 定义为 @racket[_cpointer] 生成的类型外，@racket[_id]@racketidfont{/null} 绑定到 @racket[_cpointer/null] 产生的类型。最后，@racketvarfont{id}@racketidfont{?} 定义为 predicate，@racketvarfont{id}@racketidfont{-tag} 定义为获取 tag 的 accessor。如果提供了 tag，则为 @racket[tag-expr]，否则为 @racketvarfont{id} 的 symbol 形式。}

@defproc[(cpointer-predicate-procedure? [v any/c]) boolean?]{如果 @racket[v] 是由 @racket[define-cpointer-type] 或 @racket[define-cstruct] 生成的 predicate procedure 则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.6.0.1"]

@defproc*[([(cpointer-has-tag? [cptr cpointer?] [tag any/c]) boolean?]
           [(cpointer-push-tag! [cptr cpointer?] [tag any/c]) void?])]{

这两个函数将 pointer tag 视为 tag 的列表。如 @secref["foreign:pointer-funcs"] 中所述，pointer tag 没有任何作用，除了 Racket 用它来区分 pointer；这些函数将 tag 值视为 tag 的列表，这使得构造可以被视为其他 pointer 类型的 pointer 类型成为可能，主要用于实现通过向上转型的继承（当 struct 包含 super struct 作为其第一个元素时）。

@racket[cpointer-has-tag?] 函数检查给定的 @racket[cptr] 是否有 @racket[tag]。当 pointer 的 tag 是 @racket[eq?] 到 @racket[tag] 或包含（在 @racket[memq] 意义上）@racket[tag] 的列表时，pointer 有 tag @racket[tag]。

@racket[cpointer-push-tag!] 函数将给定的 @racket[tag] 值推送到 @racket[cptr] 的 tag 上。此操作的主要特性是：(a) 推送任何 tag 都将使后续对 @racket[cpointer-has-tag?] 的调用在此 tag 上成功，(b) 推送的 tag 将在打印 pointer 时使用（直到推送新值）。技术上，推送 tag 将简单地设置它（如果没有 tag 设置），否则推送到现有列表或现有值（被视为单元素列表）。}
