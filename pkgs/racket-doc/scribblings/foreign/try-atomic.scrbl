#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/try-atomic ffi/unsafe/atomic))

@title{推测性原子执行}

@defmodule[ffi/unsafe/try-atomic]{@racketmodname[ffi/unsafe/try-atomic] 库支持原子执行，
可在运行时间过长或某些外部事件导致尝试被放弃时挂起并在非原子模式下继续执行。}

@defproc[(call-as-nonatomic-retry-point [thunk (-> any)]) any]{

以 @tech{atomic mode}（见 @racket[start-atomic] 和 @racket[end-atomic]）
调用 @racket[thunk]，同时允许 @racket[thunk] 使用 @racket[try-atomic]。
任何以 @racket[try-atomic] 开始但未完成的计算在 @racket[thunk] 返回后，
以非原子方式运行。@racket[thunk] 的结果作为 @racket[call-as-nonatomic-retry-point] 的结果。}


@defproc[(try-atomic
          [thunk (-> any)]
          [default-val any/c]
          [#:should-give-up? give-up-proc (-> any/c) _run-200-milliseconds]
          [#:keep-in-order? keep-in-order? any/c #t])
         any]{

在 @racket[call-as-nonatomic-retry-point] 调用的动态范围内，
试图在现有的 @tech{atomic mode} 中运行 @racket[thunk]。
@racket[give-up-proc] 过程被定期调用，以确定是否应放弃原子模式；
默认的 @racket[give-up-proc] 在 200 毫秒后返回 true。
如果放弃原子模式，计算会被挂起，并改为返回 @racket[default-val]。
计算后由外层 @racket[call-as-nonatomic-retry-point] 调用恢复。

如果 @racket[keep-in-order?] 为 true，那么在同一个
@racket[call-as-nonatomic-retry-point] 调用中，
若先前计算已被挂起，随后调用 @racket[try-atomic] 时，
@racket[thunk] 会立即被入队等待完成（由 @racket[call-as-nonatomic-retry-point]），
并返回 @racket[default-val]。

@racket[give-up-proc] 回调仅在原子模式嵌套层级（见 @racket[start-atomic]、
@racket[start-breakable-atomic] 和 @racket[call-as-atomic]）
与调用 @racket[try-atomic] 时相同的位置被轮询。

如果 @racket[thunk] 使用 @racket[(default-continuation-prompt-tag)]
中止当前 continuation，该中止会被挂起，由外层
@racket[call-as-nonatomic-retry-point] 恢复。使用任何其他
prompt tag 或 continuation 逃逸到 @racket[thunk] 的上下文
会被阻止（通过 @racket[dynamic-wind]），并从 @racket[thunk] 简单返回 @racket[(void)]。}
