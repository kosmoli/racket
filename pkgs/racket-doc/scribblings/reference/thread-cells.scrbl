#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "threadcells"]{线程细胞}

@defterm{@tech{thread cell}} 包含一个特定于线程的值；即它为每个线程包含特定值，但可能为不同线程包含不同值。thread cell 用默认值创建，该默认值用于所有现有线程。当 cell 的内容使用 @racket[thread-cell-set!] 更改时，cell 的值仅为当前线程更改。同样，@racket[thread-cell-ref] 获取当前线程的特定 cell 值。

thread cell 的值可以是 @defterm{@tech{preserved}}，这意味着当创建新线程时，cell 对新线程的初始值与创建线程的当前值相同。如果 thread cell 未保留，则对于新创建的线程，cell 的初始值是默认值（在创建 cell 时提供的）。

在当前线程中，所有 preserved thread cell 的当前值可以通过 @racket[current-preserved-thread-cell-values] 捕获。捕获的值集可以通过对 @racket[current-preserved-thread-cell-values] 的另一个调用强制安装到当前线程中。捕获和恢复线程可以不同。

@defproc[(thread-cell? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{thread cell} 返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-thread-cell [v any/c] [preserved? any/c #f]) thread-cell?]{

创建并返回一个新的 thread cell。最初，@racket[v] 是 cell 在所有线程中的值。如果 @racket[preserved?] 为真，则对于新创建的线程，cell 的初始值为创建线程的 cell 值，否则 cell 在所有未来线程中的值最初为 @racket[v]。}


@defproc[(thread-cell-ref [cell thread-cell?]) any]{返回当前线程的 @racket[cell] 当前值。}

@defproc[(thread-cell-set! [cell thread-cell?] [v any/c]) any]{为当前线程设置 @racket[cell] 中的值为 @racket[v]。}

 @examples[
(define cnp (make-thread-cell '(nerve) #f))
(define cp (make-thread-cell '(cancer) #t))

(thread-cell-ref cnp)
(thread-cell-ref cp)

(thread-cell-set! cnp '(nerve nerve))
(thread-cell-set! cp '(cancer cancer))

(thread-cell-ref cnp)
(thread-cell-ref cp)

(define ch (make-channel))
(thread (lambda ()
          (channel-put ch (thread-cell-ref cnp))
          (channel-put ch (thread-cell-ref cp))
          (channel-get ch) ; 等待
          (channel-put ch (thread-cell-ref cp))))

(channel-get ch)
(channel-get ch)

(thread-cell-set! cp '(cancer cancer cancer))

(thread-cell-ref cp)
(channel-put ch 'ok)
(channel-get ch)
]

@defproc*[([(current-preserved-thread-cell-values) thread-cell-values?]
           [(current-preserved-thread-cell-values [thread-cell-vals thread-cell-values?]) void?])]{

当不带参数调用时，此 procedure 生成一个 @racket[thread-cell-vals]，表示所有 preserved thread cell 的当前值（在当前线程中）。

当使用先前对 @racket[current-preserved-thread-cell-values] 的调用生成的 @racket[thread-cell-vals] 调用时，所有 preserved thread cell 的值（在当前线程中）设置为 @racket[thread-cell-vals] 中捕获的值；如果在生成 @racket[thread-cell-vals] 后创建了 preserved thread cell，则该线程 cell 对当前线程的值恢复到其初始值。}

@defproc[(thread-cell-values? [v any/c]) boolean?]{

如果 @racket[v] 是 @racket[current-preserved-thread-cell-values] 生成的 thread cell 值集，则返回 @racket[#t]，否则返回 @racket[#f]。}
