#lang scribble/doc
@(require "mz.rkt")

@title[#:style 'toc #:tag "data"]{数据类型}

@guideintro["datatypes"]{数据类型}

每种预定义数据类型都有一组用于操作该数据类型实例的 procedure。

@local-table-of-contents[#:style 'immediate-only]

@; ------------------------------------------------------------
@include-section["equality.scrbl"]

@; ------------------------------------------------------------
@include-section["booleans.scrbl"]

@; ------------------------------------------------------------
@include-section["numbers.scrbl"]

@; ------------------------------------------------------------
@include-section["strings.scrbl"]

@; ------------------------------------------------------------
@include-section["bytes.scrbl"]

@; ------------------------------------------------------------
@include-section["chars.scrbl"]

@; ------------------------------------------------------------
@include-section["symbols.scrbl"]

@; ------------------------------------------------------------
@include-section["regexps.scrbl"]

@; ------------------------------------------------------------
@include-section["keywords.scrbl"]

@; ----------------------------------------------------------------------
@include-section["pairs.scrbl"]

@; ----------------------------------------------------------------------
@include-section["mpairs.scrbl"]

@; ----------------------------------------------------------------------
@include-section["vectors.scrbl"]

@; ----------------------------------------------------------------------
@include-section["stencil-vectors.scrbl"]

@; ------------------------------------------------------------
@section[#:tag "boxes"]{Box}

@guideintro["boxes"]{box}

@deftech{box} 类似于单元素 vector，通常用作最小可变存储。

box 可以是 @defterm{可变的} 或 @defterm{不可变的}。当将不可变 box 提供给
@racket[set-box!] 等 procedure 时，@exnraise[exn:fail:contract]。
默认 reader 生成的 box 常量（参见 @secref["parse-string"]）是不可变的。
使用 @racket[immutable?] 检查 box 是否不可变。

字面量或打印的 box 以 @litchar{#&} 开头。@see-read-print["box"]{box}

@defproc[(box? [v any/c]) boolean?]{

如果 @racket[v] 是 box，则返回 @racket[#t]，否则返回 @racket[#f]。

另见 @racket[immutable-box?] 和 @racket[mutable-box?]。}


@defproc[(box [v any/c]) box?]{

返回一个包含 @racket[v] 的新可变 box。}


@defproc[(box-immutable [v any/c]) (and/c box? immutable?)]{

返回一个包含 @racket[v] 的新不可变 box。}


@defproc[(unbox [box box?]) any/c]{

返回 @racket[box] 的内容。}


对于任意 @racket[v]，@racket[(unbox (box v))] 和 @racket[(unbox (box-immutable v))] 返回 @racket[v]。


@defproc[(set-box! [box (and/c box? (not/c immutable?))]
                   [v any/c]) void?]{

将 @racket[box] 的内容设置为 @racket[v]。}


@deftogether[(
@defproc[(unbox* [box (and box? (not/c impersonator?))]) any/c]
@defproc[(set-box*! [box (and/c box? (not/c immutable?) (not/c impersonator?))]
                    [v any/c]) void?]
)]{

类似于 @racket[unbox] 和 @racket[set-box!]，但限制为操作不是
@tech{impersonator} 的 box。

@history[#:added "6.90.0.15"]}


@defproc[(box-cas! [box (and/c box? (not/c immutable?) (not/c impersonator?))]
                   [old any/c] 
                   [new any/c]) 
         boolean?]{
  原子地将 @racket[box] 的内容更新为 @racket[new]，前提是
  @racket[box] 当前包含的值与 @racket[old] 是 @racket[eq?] 的，
  并在这种情况下返回 @racket[#t]。如果 @racket[box]
  不包含 @racket[old]，则结果为 @racket[#f]。

  如果没有其他 @tech{thread} 或 @tech{future} 尝试访问
  @racket[box]，则该操作等价于

  @racketblock[
  (and (eq? old (unbox box)) (set-box! box new) #t)]

  不同的是 @racket[box-cas!] 在某些平台上可能会虚假失败。
  也就是说，即使 @racket[box] 包含 @racket[old]，
  结果也可能以低概率为 @racket[#f] 且 @racket[box] 中的值保持不变。

  当 Racket 编译时支持 @tech{future}，
  @racket[box-cas!] 保证使用硬件 @emph{compare and set} 操作。
  @racket[box-cas!] 的使用可以在 @tech{future} 中安全执行
  （即允许 future thunk 并行继续）。另见 @secref["memory-order"]。}

@; ----------------------------------------------------------------------
@include-section["hashes.scrbl"]

@; ----------------------------------------------------------------------
@include-section["treelists.scrbl"]

@; ----------------------------------------------------------------------
@include-section["sequences.scrbl"]

@; ----------------------------------------------------------------------
@include-section["dicts.scrbl"]

@; ----------------------------------------------------------------------
@include-section["sets.scrbl"]

@; ----------------------------------------------------------------------
@include-section["procedures.scrbl"]

@; ----------------------------------------------------------------------
@section[#:tag "void"]{Void}

常量 @|void-const| 由大多数有副作用但无有用结果的 form 和 procedure 返回。

@|void-const| 值始终与自身是 @racket[eq?] 的。

@defproc[(void? [v any/c]) boolean?]{如果 @racket[v] 是
 常量 @|void-const|，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(void [v any/c] ...) void?]{返回常量 @|void-const|。每个
 @racket[v] 参数被忽略。}

@; ----------------------------------------------------------------------
@include-section["undefined.scrbl"]
