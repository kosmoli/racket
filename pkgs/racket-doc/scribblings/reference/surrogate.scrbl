#lang scribble/doc
@(require "mz.rkt" (for-label racket/surrogate racket/class))

@title{Surrogate}

@note-lib-only[racket/surrogate]

The @racketmodname[racket/surrogate] 库提供了一种用于构建 @deftech{proxy 设计模式} 实例的抽象。该模式由两个对象组成：@defterm{host}（宿主机）和 @defterm{surrogate}（代理）对象。宿主对象将其 method 调用委托给其 surrogate 对象。每个 host 都有一个动态分配的 surrogate，因此对象只需改变 surrogate 即可完全改变其行为。

@defform/subs[#:literals (augment override override-final)
              (surrogate use-wrapper-proc method-spec ...)
              ([use-wrapper-proc #:use-wrapper-proc (code:line)]
               [method-spec (augment default-expr method-id arg-spec ...)
                            (override method-id arg-spec ...)]
               [arg-spec (id ...)
                         id]]){

@racket[surrogate] form 产生四个值：一个 host @tech{mixin}（接受并返回 class 的 procedure）、一个 host @tech{interface}、一个 surrogate @tech{class} 和一个 surrogate @tech{interface}。

如果 @racket[#:use-wrapper-proc] 不出现，host mixin 为其参数添加一个单独的私有字段。它还会添加 getter 和 setter method @racket[get-surrogate] 和 @racket[set-surrogate] 来获取和设置字段的值。@racket[set-surrogate] 方法接受由 @racket[surrogate] form 返回的 class 的实例或 @racket[#f]，并用其参数更新字段；然后，@racket[set-surrogate] 调用前一个字段值的 @racket[on-disable-surrogate] 和新字段值的 @racket[on-enable-surrogate]。@racket[get-surrogate] 方法返回字段的当前值。

如果 @racket[#:use-wrapper-proc] 出现，host mixin 添加第二个私有字段及其 getter 和 setter method @racket[get-surrogate-wrapper-proc] 和 @racket[set-surrogate-wrapper-proc]。附加字段保存一个 wrapper procedure，其 contract 是 @racket[(-> (-> any) (-> any) any)]，因此该 procedure 用两个 thunk 调用。第一个 thunk 是回退，它跳过 surrogate 调用原始对象的 method。第二个 thunk 调用 surrogate。默认 wrapper procedure 是
 @racketblock[(λ (fallback-thunk surrogate-thunk)
                (surrogate-thunk))]
也就是说，它简单地委托给在 surrogate 上调用的 method。注意，wrapper procedure 可以通过例如改变 parameter 的值来调整调用 surrogate 的 dynamic extent。在调用 surrogate 的 @racket[on-disable-surrogate] 和 @racket[on-enable-surrogate] method 时也会调用 wrapper procedure。

Host mixin 为 @racket[surrogate] form 中的每个 @racket[method-id] 都有一个单一的覆盖 method（包括那些用 @racket[augment] 指定的 method）。这些 method 每个都用 @racket[case-lambda] 定义，每个 @racket[arg-spec] 对应一个分支。每个分支有 @racket[arg-spec] 中的变量作为参数。每个 method 的 body 测试私有 surrogate 字段。如果字段值为 @racket[#f]，method 只返回调用 super 或 inner method 的结果。如果字段值不是 @racket[#f]，则调用字段中对象的相应 method。该 method 接收与原 method 相同的参数，外加两个额外参数。额外参数出现在参数列表的开头。第一个是原始对象。第二个是调用 super 或 inner method（即传递给 mixin 或扩展的 class 的 method，或覆盖 class 中的 method）的 procedure，带有 procedure 接收的参数。

例如，针对此 surrogate 的 host-mixin：
@racketblock[(surrogate (override m (x y z)))]
将覆盖 @racket[m] method 并像这样调用 surrogate：
@racketblock[(define/override (m x y z)
               (if _surrogate
                   (send _surrogate m 
                         this 
                         (λ (x y z) (super m x y z))
                         x y z)
                   (super m x y z))]
其中 @racket[_surrogate] 绑定到最近传递给 host mixin 的 @racket[set-surrogate] 方法的值。

Host interface 有名称 @racket[set-surrogate]、@racket[get-surrogate] 以及原始 form 中所有的 @racket[method-id]。

Surrogate class 为 @racket[surrogate] form 中的每个 @racket[method-id] 有一个单一的 public method。这些 method 被 mixin 构造的 class 调用。每个 method 有对应的 method 签名，如上一段所述。每个 method 只是将其参数传递给它接收的 super procedure。

在上面的示例中，这是 surrogate class 中的 @racket[_m] method：
@racketblock[(define/public (m original-object original-super x y z)
               (original-super x y z))]

如果你从 surrogate class 派生 class，不要同时调用 @racket[super] 参数和 surrogate class 自身的 super method。只调用其中一个即可，因为默认 method 会调用 @racket[super] 参数。

最后，interface 包含 @racket[surrogate] 参数中指定的所有名称加上 @racket[on-enable-surrogate] 和 @racket[on-disable-surrogate]。由 @racket[surrogate] 返回的 class 实现此 interface。
}
