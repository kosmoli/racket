#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/custodian))

@title{Custodian Shutdown Registration}

@defmodule[ffi/unsafe/custodian]{@racketmodname[ffi/unsafe/custodian]
库提供了用于向 custodians 注册 shutdown callbacks 的工具。}

@defproc[(register-custodian-shutdown [v any/c]
                                      [callback (any/c . -> . any)]
                                      [custodian custodian? (current-custodian)]
                                      [#:at-exit? at-exit? any/c #f]
                                      [#:weak? weak? any/c #f]
                                      [#:ordered? ordered? any/c #f])
          cpointer?]{

注册 @racket[callback] 以在 @racket[custodian] 被 shutdown 时应用于 @racket[v]
（在 @tech{atomic mode} 和一个 @elemref["unspecified thread"]{未指定的 Racket 线程} 中）。
如果 @racket[custodian] 已经 shutdown，则结果为 @racket[#f] 并且 @racket[v] 未被注册。
否则，结果是一个 pointer，可以传递给 @racket[unregister-custodian-shutdown] 以移除注册。

如果 @racket[at-exit?] 为 true，则即使 custodian 未被显式 shutdown，也
会在 Racket 退出时将 @racket[callback] 应用于 @racket[v]。

如果 @racket[weak?] 为 true，则在垃圾回收期间 @racket[v] 被判断为不可达时，
@racket[callback] 可能不会被调用。该值 @racket[v] 最初由 custodian weak 持有，
即使 @racket[weak?] 为 @racket[#f]。因此，与 custodian 关联的值可以通过 will 
executors 被 finalize（至少在调用 @racket[register-custodian-shutdown] 之后
的 will registrations 和 @racket[register-finalizer] 使用范围内），但当没有
其他 strong references 并且没有后续注册的 finalizers 或 wills 时，该值会变为
strong 持有。

如果 @racket[ordered?] 在 @racket[weak] 为 @racket[#f] 时为 true，则
@racket[v] 的保留方式允许通过 @racket[register-finalizer] 继续对
@racket[v] 进行 finalization。对于 Racket 的 @CS[] 实现，@racket[v]
不得引用自身或引用可以引用回到 @racket[v] 的值。

通常，@racket[weak?] 应该为 false。要基于 finalization 或 custodian shutdown
触发动作——无论哪个先发生——请将 @racket[weak?] 设为 @racket[#f]，并让一个
finalizer 在 atomic mode 中运行以检查 custodian shutdown 尚未发生，然后通过
@racket[unregister-custodian-shutdown] 取消 shutdown 动作。如果
@racket[weak?] 为 true，或者 finalizer 不在 atomic mode 中运行，那么
在 custodian shutdown 完成时，custodian 或 finalizer callbacks 都已完成是
没有保证的；@racket[v] 可能已经不再在 custodian 中注册，而
@racket[v] 的 finalizer 可能仍在运行或仅排队等待运行。此外，如果
finalization 是通过 @racket[register-finalizer]（而不是一个 @tech[#:doc
reference.scrbl]{will executor}）进行的，则应该将 @racket[ordered?] 设为
true；如果 @racket[ordered?] 为 false 且 @racket[weak?] 为 false，
则 @racket[custodian] 可能以不允许触发 finalization 的方式保留
@racket[v]（当 @racket[v] 在其他方面不可达时）。另请参见
@racket[register-finalizer-and-custodian-shutdown]。

@history[#:changed "7.8.0.8" @elem{添加了 @racket[#:ordered?] 参数。}]}


@defproc[(unregister-custodian-shutdown [v any/c]
                                        [registration cpointer?])
         void?]{

取消一个 custodian-shutdown registration，其中 @racket[registration] 是
应用于 @racket[v] 的 @racket[register-custodian-shutdown] 的先前结果。
如果 @racket[registration] 是 @racket[#f]，则不采取任何动作。}

@defproc[(register-finalizer-and-custodian-shutdown
                 [v any/c]
                 [callback (any/c . -> . any)]
                 [custodian custodian? (current-custodian)]
                 [#:at-exit? at-exit? any/c #f]
                 [#:custodian-available available-callback ((any/c . -> . void?) . -> . any) (lambda (_unreg) (void))]
                 [#:custodian-unavailable unavailable-callback ((-> void?) . -> . any) (lambda (_reg-fnl) (_reg-fnl))])
         any]{

注册 @racket[callback] 以在 @racket[custodian] 被 shutdown 或 @racket[v] 将要
被垃圾收集器回收时——无论哪个先发生——应用于 @racket[v]（在 @tech{atomic mode}
和一个 @elemref["unspecified thread"]{未指定的 Racket 线程} 中）。
@racket[callback] 只应用于 @racket[v] 一次。对象 @racket[v] 受
@racket[register-finalizer] 的约束——特别是 @racket[v] 自身可达性约束。

当 @racket[v] 成功注册在 @racket[custodian] 中并注册了一个 finalizer 后，
可用回调函数 @racket[available-callback] 会被调用，给定一个函数
@racket[_unreg]，该函数注销 @racket[v] 并禁止其它通过 custodian 或
finalizer 回调使用 @racket[callback] 的方式。必须将值 @racket[v] 提供给
@racket[_unreg]（否则它已经在 @racket[_unreg] 的闭包中，可能阻止该值被
finalized）。@racket[available-callback] 函数在 tail position 中被调用，
因此它的结果就是 @racket[register-finalizer-and-custodian-shutdown] 的结果。

如果 @racket[custodian] 已经 shutdown，则 @racket[unavailable-callback] 在
tail position 中被调用，给定一个 function @racket[reg-fnl]，它注册一个
finalizer。默认情况下，无论怎样 finalizer 都会被注册，但更好的选择通常
是报告一个错误的历史。

@history[#:added "6.1.1.6"
         #:changed "8.1.0.6" @elem{添加了 @racket[#:custodian-available] 参数。}]}


@defproc[(make-custodian-at-root) custodian?]{

创建一个作为 root custodian 子级的 custodian，绕过 @racket[current-custodian] 设置。

创建 root custodian 的子级对于注册只在当前 place 终止时才被触发的
shutdown function 很有用。

@history[#:added "6.9.0.5"]}
