#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/async-channel))

@(define eventspaces @tech[#:doc '(lib "scribblings/gui/gui.scrbl")]{eventspaces})

@title[#:tag "custodians"]{Custodian}

参见 @secref["custodian-model"] 了解 Racket custodian 模型的基本信息。

@defproc[(custodian? [v any/c]) boolean?]{

当 @racket[v] 是 @tech{custodian} 值时返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-custodian [cust (and/c custodian? (not/c custodian-shut-down?))
                               (current-custodian)])
         custodian?]{

创建一个隶属于 @racket[cust] 的新 custodian。当 @racket[cust] 被指示（通过
@racket[custodian-shutdown-all]）关闭所有托管值时，新的隶属 custodian 也被自动指示关闭其托管值。}


@defproc[(custodian-shutdown-all [cust custodian?]) void?]{

@margin-note{在 @racketmodname[racket/gui/base] 中，由 @racket[cust] 管理的 @|eventspaces| 也会被关闭。}

关闭由 @racket[cust] 管理（包括隶属 custodian）的所有 @tech{file-stream port}、@tech{TCP port}、@tech{TCP listener} 和 @tech{UDP socket}，并清空与 @racket[cust]关联的所有 @tech{custodian box}。它还将 @racket[cust] 及其隶属 custodian 作为 thread 的管理者移除；当一个 thread 没有管理者时，它会被 kill（或挂起，见 @racket[thread/suspend-to-kill]）。如果当前 thread 被 kill，所有其他关闭动作在 kill 该 thread 之前执行。

如果 @racket[cust] 已被关闭，@racket[custodian-shutdown-all] 无效。当一个 custodian 被关闭时，如果它有隶属 custodian，隶属 custodian 不仅被关闭，也不再被计为隶属 custodian。}


@defproc[(custodian-shut-down? [cust custodian?]) boolean?]{

当 @racket[cust] 已通过 @racket[custodian-shutdown-all] 被关闭、或是被关闭 custodian 的隶属 custodian 时，返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.11.0.5"]}


@defparam[current-custodian cust custodian?]{

@margin-note{Custodian 还管理来自 @racketmodname[racket/gui/base] 的 @|eventspaces|。}

一个 @tech{parameter}，确定承担新创建的 thread、@tech{file-stream port}、TCP port、@tech{TCP listener}、@tech{UDP socket} 和 @tech{byte converter} 责任的 custodian。}


@defproc[(custodian-managed-list [cust custodian?] [super custodian?]) list?]{

返回 @racket[cust] 的直属托管对象列表（不包括 @tech{custodian box}）及其隶属 custodian，其中 @racket[cust] 本身隶属于 @racket[super]（直接或间接）。如果 @racket[cust] 不是 @racket[super] 的严格隶属 custodian，则以 @exnraise[exn:fail:contract] 抛错。

如果 @racket[cust] 已被关闭，返回值为 @racket['()]。如果 @racket[cust] 是已关闭 custodian 的隶属，则它不可能是 @racket[super] 的隶属 custodian。}


@defproc[(custodian-memory-accounting-available?) boolean?]{

@margin-note{Memory accounting 通常可用，但在 @tech{CGC} 实现中不可用。}

当 Racket 编译时支持基于 custodian 的 memory accounting 时返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(custodian-require-memory [limit-cust custodian?]
                                   [need-amt exact-nonnegative-integer?]
                                   [stop-cust custodian?]) void?]{

注册 memory requirement 检查（仅当 Racket 编译时支持 custodian memory accounting），否则 @exnraise[exn:fail:unsupported]。

注册检查后，若 Racket 在 garbage collection 后（参见 @secref["gc-model"]）达到一种状态——向 @racket[limit-cust] 分配 @racket[need-amt] 字节会失败或触发某种关闭——则 @racket[stop-cust] 被关闭。

@racket[stop-cust] 必须是 @racket[limit-cust] 的隶属 custodian。}


@defproc[(custodian-limit-memory [limit-cust custodian?]
                                 [limit-amt exact-nonnegative-integer?]
                                 [stop-cust custodian? limit-cust]) void?]{

注册 memory limit 检查（仅当 Racket 编译时支持 custodian memory accounting），否则 @exnraise[exn:fail:unsupported]。

注册检查后，若 Racket 在 garbage collection 后（参见 @secref["gc-model"]）达到一种状态——@racket[limit-cust] 拥有超过 @racket[limit-amt] 字节——则 @racket[stop-cust] 被关闭。

@margin-note{A custodian's limit is checked only after a garbage
             collection, except that it may also be checked during
             certain large allocations that are individually larger
             than the custodian's limit. A single garbage collection
             may shut down multiple custodians, even if shutting down
             only one of the custodians would have reduced memory use
             for other custodians.}

对于可靠的关闭，@racket[custodian-limit-memory] 的 @racket[limit-amt] 必须远低于可用内存总量（减去可能已使用但未计入 @racket[limit-cust] 的内存大小）。此外，如果初始分配给 @racket[limit-cust] 的单独分配可以任意大，则 @racket[stop-cust] 必须与@racket[limit-cust] 相同，这样过大的即时分配会被 @racket[exn:fail:out-of-memory] exception 拒绝。

@margin-note{New memory allocation will be accounted to the running
 @seclink["threads"]{thread}'s managing custodian. In other words, a custodian's limit applies
 only to the allocation made by the threads that it manages.
 See also @racket[call-in-nested-thread] for a simpler setup.}

@examples[
 (require racket/async-channel)
 (define ch (make-async-channel))
 (eval:alts
  (parameterize ([current-custodian (make-custodian)])
    (thread-wait
     (thread
      (λ ()
        (with-handlers ([exn:fail:out-of-memory?
                         (λ (e) (async-channel-put ch e))])
          (custodian-limit-memory (current-custodian) (* 1024 1024))
          (make-bytes (* 4 1024 1024))
          (async-channel-put ch "Not OK"))))
    (async-channel-get ch))
   (exn:fail:out-of-memory "out of memory" (current-continuation-marks)))
 (define cust (make-custodian))
 (eval:alts
   (with-handlers ([exn:fail:out-of-memory?
                    (λ (e) (error "Caught OOM exn"))])
     (call-in-nested-thread
      (λ ()
        (custodian-limit-memory cust (* 1024 1024))
        (make-bytes (* 4 1024 1024))
        "Not OK")
      cust))
   (eval:error
    (error "Caught OOM exn")))
 ]

@examples[
 #:label "Non-examples:"
 (eval:alts
  (parameterize ([current-custodian (make-custodian)])
    (custodian-limit-memory (current-custodian) (* 1024 1024))
    (code:comment @#,elem{@racket[make-bytes] 的分配被记入当前 thread 的})
    (code:comment @#,elem{管理 custodian，而不是新建 custodian。})
    (make-bytes (* 4 1024 1024))
    "Not OK")
   "Not OK")
 ]
}

@defproc[(make-custodian-box [cust custodian?] [v any/c]) custodian-box?]{

返回一个 @tech{custodian box}，只要 @racket[cust] 尚未关闭即包含 @racket[v]。
如果 @racket[cust] 已经关闭，custodian box 的值会立即被移除。

@tech{Custodian box} 是一个 @tech{synchronizable event}（参见 @secref["sync"]）。
当其 custodian 关闭时，@tech{custodian box} 变为 ready；
@resultItself{@tech{custodian box}}。}


@defproc[(custodian-box? [v any/c]) boolean?]{

当 @racket[v] 是 @racket[make-custodian-box] 产生的 @tech{custodian box} 时返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(custodian-box-value [cb custodian-box?]) any]{

返回给定 @tech{custodian box} 的值，如果值已被移除则返回 @racket[#f]。}
