#lang scribble/doc
@(require (except racket/contract any)
          (for-label ffi/unsafe/runtime-lib))

@title[#:tag "runtime-lib"]{声明运行时所需的外部库}

@defmodule[ffi/unsafe/runtime-lib]{@racketmodname[ffi/unsafe/runtime-lib] 库类似于 @racketmodname[racket/runtime-path]（并在其基础上构建），但为平台相关的库选择提供了更多支持。}

@history[#:added "9.2.0.6"]

@defform[#:literals(else so or and)
         (define-runtime-lib id
            maybe-ffi-lib-args
            [platform-spec lib-spec ...]
            ...
            [else else-body ...+])
         #:grammar ([platform-spec os-id
                                   os*-id
                                   arch-id
                                   platform-string
                                   32
                                   64
                                   (or platform-spec ...)
                                   (and platform-spec ...)]
                    [lib-spec (so lib-string)
                              (so lib-string (vers ...))]
                    [vers string
                          #f]
                    [maybe-ffi-lib-args code:blank
                                        (code:line #:ffi-lib-args (arg ...))])]{

与 @racket[define-runtime-path] 类似，但 @racket[id] 被绑定到指定平台的 @racket[ffi-lib] 调用结果——其中 @racket[platform-spec] 按顺序逐一尝试，直到找到一个匹配的平台——否则回退到求值 @racket[else-body] 的结果。

一个 @racket[platform-spec] 对应一组要按顺序加载的库，由随附的 @racket[lib-spec] 逐一列举：每个 @racket[lib-spec] 中的 @racket[lib-string] 作为 @racket[ffi-lib] 的第一个参数，而 @racket[vers] 序列（如果存在）则以字面量形式作为第二个参数。@racket[id] 被绑定到匹配子句中最后一个 @racket[lib-spec] 所对应的 @racket[ffi-lib] 结果；如果匹配子句没有 @racket[lib-spec]，则绑定到 @racket[#f]。除了在为每个 @racket[lib-spec] 运行时加载库之外，还会在编译时声明这些库供 @exec{raco exe} 和 @exec{raco dist} 等工具使用。交叉编译会被自动处理：编译时会列出目标平台所需的库，而运行时则会加载适合宿主平台的库。

如果没有 @racket[platform-spec] 匹配，@racket[id] 会被绑定到 @racket[else-body] 序列的结果——该结果不必是 @racket[ffi-lib] 的结果，但通常情况下如此。@racket[else-body] 序列仅在运行时求值，编译时也不会声明任何库。

每个 @racket[platform-spec] 会与以下调用的结果进行比较：@racket[(system-type 'os)]、@racket[(system-type 'os*)]、@racket[(system-type 'arch)]、@racket[(system-type 'platform)] 和/或 @racket[(system-type 'word)]。在 @racket[and] 形式中，所有 @racket[platform-spec] 必须匹配；在 @racket[or] 形式中，只需其中之一匹配即可。

可以通过可选的 @racket[#:ffi-lib-args] 声明，为匹配的 @racket[platform-spec] 在运行时 @racket[ffi-lib] 调用中附加关键字数参数。只有一个 @racket[package-spec] 匹配时才会使用同一条 @racket[#:ffi-lib-args] 声明，因为这条声明需要独立于最终匹配的 @racket[platform-spec]。运行时调用要么接收基于 @racket[lib-spec] 解析后的绝对路径，要么只接收 @racket[lib-spec] 内最初的 @racket[lib-string]（受 @racket[define-runtime-path] 的限制），因此 @racket[#:fail] 是最可能用得上的额外参数。

}
