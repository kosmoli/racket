#lang scribble/doc
@(require "mz.rkt" scribble/racket (for-label racket/mpair))

@title[#:tag "mpairs"]{Mutable Pairs and Lists}

@deftech{mutable pair} 类似由 @racket[cons] 创建的对，但它支持
@racket[set-mcar!] 和 @racket[set-mcdr!] 突变操作，以改变可变对的部分（如同传统 Lisp 和 Scheme 中的对）。

@deftech{mutable list} 与用对创建的列表相似，但改由 @tech{mutable pair} 创建。

@tech{mutable pair} 不是 @tech{pair}；它们是完全独立的数据类型。
同样，@tech{mutable list} 不是 @tech{list}，空列表同时是空的可变列表除外。
与其直接使用可变对和可变列表编程，不如选择 pair、list、hash table 等数据结构——它们在实践中几乎总是更好的选择。

@tech{mutable list} 可用作单值序列（见
@secref["sequences"]）。@tech{mutable list} 的元素作为序列的元素。
另见 @racket[in-mlist]。

@; ----------------------------------------
@section[#:tag "mpairs-s1"]{Mutable Pair Constructors and Selectors}

@defproc[(mpair? [v any/c]) boolean?]{当 @racket[v] 是
@tech{mutable pair} 时返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(mcons [a any/c] [d any/c]) mpair?]{返回一个新分配的
@tech{mutable pair}，其第一个元素为 @racket[a]，第二个元素为 @racket[d]。}

@defproc[(mcar [p mpair?]) any/c]{返回 @tech{mutable pair} @racket[p] 的第一个元素。}

@defproc[(mcdr [p mpair?]) any/c]{返回 @tech{mutable pair} @racket[p] 的第二个元素。}


@defproc[(set-mcar! [p mpair?] [v any/c]) 
         void?]{

将 @tech{mutable pair} @racket[p] 更改为以 @racket[v] 作为其第一个元素。}

@defproc[(set-mcdr! [p mpair?] [v any/c]) 
         void?]{

将 @tech{mutable pair} @racket[p] 更改为以 @racket[v] 作为其第二个元素。}
