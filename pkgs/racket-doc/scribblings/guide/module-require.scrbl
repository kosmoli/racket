#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "module-require"]{导入：@racket[require]}

The @racket[require] form 从另一个模块导入。@racket[require] form 可以出现在模块内，在这种情况下它将指定模块中的绑定引入到导入模块。@racket[require] form 也可以出现在顶层，在这种情况下它既导入绑定又 @deftech{instantiate} 指定的模块；即，它评估指定模块的 body definition 和表达式（如果它们尚未被评估）。

单个 @racket[require] 可以一次性指定多个导入：

@specform[(require require-spec ...)]{}

在单个 @racket[require] 中指定多个 @racket[_require-spec] 与分别使用多个 @racket[require]（每个带单个 @racket[_require-spec]）实质上是相同的。区别很小，且仅限于顶层：单个 @racket[require] 最多只能导入给定的标识符一次，而单独的 @racket[require] 可以替换先前 @racket[require] 的绑定（两者都仅在顶层，模块外部）。

@racket[_require-spec] 允许的形状递归定义如下：

@;------------------------------------------------------------------------
@specspecsubform[module-path]{

在其最简单的形式中，@racket[_require-spec] 是一个 @racket[module-path]（如前一节中定义）。在这种情况下，@racket[require] 引入的绑定由每个 @racket[module-path] 引用模块内的 @racket[provide] 声明确定。

@examples[
(module m racket
  (provide color)
  (define color "blue"))
(module n racket
  (provide size)
  (define size 17))
(require 'm 'n)
(eval:alts (list color size) (eval '(list color size)))
]

}

@;------------------------------------------------------------------------
@specspecsubform/subs[#:literals (only-in)
                      (only-in require-spec id-maybe-renamed ...)
                      ([id-maybe-renamed id
                                         [orig-id bind-id]])]{

@racket[only-in] form 限制了基础 @racket[require-spec] 会引入的绑定集合。此外，@racket[only-in] 可选择性地重命名每个保留的绑定：在 @racket[[orig-id bind-id]] form 中，@racket[orig-id] 引用 @racket[require-spec] 暗示的绑定，@racket[bind-id] 是导入上下文中将被绑定的名称，而不是 @racket[orig-id]。

@examples[
(module m (lib "racket")
  (provide tastes-great?
           less-filling?)
  (define tastes-great? #t)
  (define less-filling? #t))
(require (only-in 'm tastes-great?))
(eval:alts tastes-great? (eval 'tastes-great?))
less-filling?
(require (only-in 'm [less-filling? lite?]))
(eval:alts lite? (eval 'lite?))
]}

@;------------------------------------------------------------------------
@specspecsubform[#:literals (except-in)
                 (except-in require-spec id ...)]{

此 form 是 @racket[only-in] 的补集：它从 @racket[require-spec] 指定的集合中排除特定绑定。

}

@;------------------------------------------------------------------------
@specspecsubform[#:literals (rename-in)
                 (rename-in require-spec [orig-id bind-id] ...)]{

此 form 支持像 @racket[only-in] 一样的重命名，但不影响 @racket[require-spec] 中未提及作为 @racket[orig-id] 的标识符。}

@;------------------------------------------------------------------------
@specspecsubform[#:literals (prefix-in)
                 (prefix-in prefix-id require-spec)]{

这是重命名的简写形式，其中 @racket[prefix-id] 被添加到每个 @racket[require-spec] 指定的标识符前面。

}

@racket[only-in]、@racket[except-in]、@racket[rename-in] 和 @racket[prefix-in] form 可以嵌套以实现更复杂的导入绑定操纵。例如，

@racketblock[(require (prefix-in m: (except-in 'm ghost)))]

导入 @racket[m] 导出的所有绑定，除了 @racket[ghost] 绑定，并且本地名称都添加 @racket[m:] 前缀。

等效地，@racket[prefix-in] 可以在 @racket[except-in] 之前应用，只要 @racket[except-in] 中指定的省略使用 @racket[m:] 前缀：

@racketblock[(require (except-in (prefix-in m: 'm) m:ghost))]
