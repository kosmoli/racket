#lang scribble/doc
@(require "mz.rkt" (for-label racket/future))

@(define future-eval (make-base-eval))
@examples[#:hidden #:eval future-eval (require racket/future)]

@(define time-id @racketidfont{time})

@title[#:tag "futures"]{Futures}

@guideintro["effective-futures"]{futures}

@note-lib[racket/future]

@margin-note{
  通过 @racket[future] 实现的并行支持在 @tech{CS} 实现中通常对所有平台启用。
  在 @tech{BC} 实现中，并行支持默认在 Windows、Linux x86/x86_64 和 Mac OS x86/x86_64 上启用。要为其他平台启用 Racket @tech{BC} 的并行支持，
  在 @exec{configure} 时使用 @DFlag{enable-futures}。}

@racketmodname[racket/future] 中的 @racket[future] 和 @racket[touch] function 提供对硬件和操作系统支持的并行性的访问。与 @racket[thread] 为任意计算提供并发而不提供并行不同，@racket[future] 提供并行性。一个 @deftech{future} 并行执行其工作（在并行支持可用的情况下），直到它检测到尝试执行无法安全并行运行的操作。类似地，future 的工作如果以某种方式依赖于当前 continuation（例如引发异常），就会被暂停。会暂停 future 的操作称为 @deftech{blocking} 操作。Future 的暂停计算会在 @racket[touch] 应用于该 future 时恢复。

Future 的“安全”并行执行意味着系统提供的所有操作都能强制执行 contract 并按照文档所述产生结果。“安全”并不排除对程序中可见的 mutable 数据的并发访问。例如，future 中的计算可能使用 @racket[set!] 修改共享变量，在这种情况下，对该变量的并发赋值在其他 future 和 thread 中可见。此外，关于效应可见性和顺序的保证由操作系统和硬件决定——它们很少支持，例如为基于 @racket[thread] 的并发提供的顺序一致性保证；另见 @secref["memory-order"]。显然安全的系统操作可能在内部实现上无法并行运行；见 @|Guide| 中的 @guidesecref["effective-futures"] 以了解更多讨论和 @racketmodname[future-visualizer #:indirect] 的介绍，用于理解系统操作的行为。

如果允许创建 thread 运行的所有 @tech{custodian} 都被关闭，future 就永远不会并行运行。但这样的 future 仍然可以通过 @racket[touch] 调用执行。

@section{创建与 Touching Futures}

@deftogether[(
  @defproc[(future [thunk (-> any)]) future?]
  @defproc[(touch [f future?]) any]
)]{

  @racket[future] function 返回一个封装了 @racket[thunk] 的 future 值。@racket[touch] function 强制求值给定 future 内的 @racket[thunk]，返回 @racket[thunk] 产生的值。在 @racket[touch] 强制求值一个 @racket[thunk] 后，结果值会被 future 保留以替代 @racket[thunk]，对该 future 的后续 @racket[touch] 调用返回这些值。

  在对给定 future 的 @racket[future] 调用和 @racket[touch] 之间，给定的 @racket[thunk] 可能会与其他计算一起被推测性地并行执行，如上所述。

  @examples[
    #:eval future-eval
    (let ([f (future (lambda () (+ 1 2)))])
      (list (+ 3 4) (touch f)))]}

@defproc[(futures-enabled?) boolean?]{
  返回当前 Racket 配置中是否启用了对 future 的并行支持。
}

@defproc[(current-future) (or/c #f future?)]{

  返回其 thunk 执行是当前 continuation 的 future 描述符；也就是说，如果返回了 future 描述符 @racket[f]，@racket[(touch f)] 将产生当前 continuation 的结果。如果 future thunk 本身使用 @racket[touch]，future-thunk 的执行可以是嵌套的，在这种情况下返回正在立即执行的 future 的描述符。如果当前 continuation 不返回到任何 future 的 @racket[touch]，结果为 @racket[#f]。

}

@defproc[(future? [v any/c]) boolean?]{

  Returns @racket[#t] if @racket[v] is a future value, @racket[#f]
  otherwise.

}

@defproc[(would-be-future [thunk (-> any)]) future?]{
  返回一个永远不会并行运行的 future，但在执行 future thunk 期间会一致地记录所有潜在的“不安全”操作（即干扰并行执行的操作）。

  对于普通 future，某些情况可能阻止记录不安全操作。例如，当使用 debug 级别日志执行时，

  @racketblock[
    (touch (future (lambda () 
                     (printf "hello1") 
                     (printf "hello2") 
                     (printf "hello3"))))] 

  可能会为每次 @racket[printf] 调用记录一条消息，共三条。然而，如果 @racket[touch] 在 future 有机会开始并行运行之前执行，future thunk 会以与普通 thunk 相同的方式求值，不会记录任何不安全操作。用 @racket[would-be-future] 替换 @racket[future] 可确保所有三个 @racket[printf] 调用都被记录。
}

@defproc[(processor-count) exact-positive-integer?]{

  返回当前机器上可用的并行计算单元数量（例如处理器或核心）。

  这与 @racketmodname[racket/place] 中可用的 binding 相同。
}

@deftogether[[@defform[(for/async (for-clause ...) body-or-break ... body)]
@defform[(for*/async (for-clause ...) body-or-break ... body)]]]{

Like @racket[for] 和 @racket[for*]，但 @racket[body] 的每次迭代在单独的 @racket[future] 中执行，future 可以按任意顺序被 @racket[touch]。}


@; ----------------------------------------

@section{Future Semaphore}

@defproc[(make-fsemaphore [init exact-nonnegative-integer?]) fsemaphore?]{

  创建并返回一个新的 @deftech{future semaphore}，计数器初始设置为 @racket[init]。

  Future semaphore 类似于普通的 @tech{semaphore}，但 future-semaphore 操作可以安全地并行执行（用于同步并行计算）。相比之下，普通 @tech{semaphore} 上的操作执行不安全，它们因此阻止计算继续并行执行。

  警惕尝试使用 fsemaphore 来实现 lock。Future 可能与其他 future 并发并行运行，但未被 Racket thread 需求的 future 可以随时被暂停——比如在它获取 lock 之后和释放 lock 之前。如果必须在 future 之间共享 mutable 数据，无锁数据结构通常是更好的选择。

}

@defproc[(fsemaphore? [v any/c]) boolean?]{

  Returns @racket[#t] if @racket[v] is an @tech{future semaphore}
  value, @racket[#f] otherwise.

}

@defproc[(fsemaphore-post [fsema fsemaphore?]) void?]{

  递增 @tech{future semaphore} 的内部计数器并返回 @|void-const|。

}

@defproc[(fsemaphore-wait [fsema fsemaphore?]) void?]{

  阻塞直到 @racket[fsema] 的内部计数器非零。当计数器非零时，它会被递减，@racket[fsemaphore-wait] 返回 @|void-const|。

}

@defproc[(fsemaphore-try-wait? [fsema fsemaphore?]) boolean?]{

  Like @racket[fsemaphore-wait]，但 @racket[fsemaphore-try-wait?] 不会阻塞执行。如果 @racket[fsema] 的内部计数器为零，@racket[fsemaphore-try-wait?] 立即返回 @racket[#f] 而不递减计数器。如果 @racket[fsema] 的计数器为正，它会被递减并返回 @racket[#t]。

}

@defproc[(fsemaphore-count [fsema fsemaphore?]) exact-nonnegative-integer?]{

  返回 @racket[fsema] 的当前内部计数器值。

}


@; ----------------------------------------

@include-section["futures-logging.scrbl"]

@close-eval[future-eval]
