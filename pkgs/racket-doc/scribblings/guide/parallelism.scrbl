#lang scribble/doc
@(require scribble/manual "guide-utils.rkt"
          (for-label racket/flonum
                     racket/unsafe/ops
                     racket/performance-hint))

@title[#:tag "parallelism"]{并行}

Racket 提供三种 @deftech{parallelism} 形式：@tech{parallel threads}、
@tech{futures} 和 @tech{places}。在提供多处理器的平台上，
并行性可以提高程序的运行时性能。

另见 @secref["performance"] 了解 Racket 中顺序性能的信息。
Racket 还为 @tech{concurrency} 提供线程，但用于并发的
@tech{coroutine threads} 不提供并行性；更多信息见
@secref["concurrency"]。

@include-section["parallel-threads.scrbl"]
@include-section["futures.scrbl"]
@include-section["places.scrbl"]
@include-section["distributed.scrbl"]
