#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "module-require"]{Imports: @racket[require]}

@racket[require] 形式从另一个模块导入。@racket[require] 形式可以出现在模块内部，在这种情况下，它将指定模块的绑定引入到导入模块中。@racket[require] 形式也可以出现在顶层，在这种情况下，它既导入绑定，又 @deftech{instantiates}（实例化）指定的模块；也就是说，它对指定模块的主体定义和表达式进行求值（如果尚未求值的话）。

一个 @racket[require] 可以同时指定多个导入：

@specform[(require require-spec ...)]{}

在单个 @racket[require] 中指定多个 @racket[_require-spec] 基本上等同于使用多个 @racket[require]，每个包含一个 @racket[_require-spec]。区别很小，且仅限于顶层：单个 @racket[require] 最多只能导入一个给定标识符一次，而单独的 @racket[require] 可以替换先前 @racket[require] 的绑定（两者都仅在模块外部的顶层有效）。

@racket[_require-spec] 的允许形式是递归定义的：

@;------------------------------------------------------------------------
@specspecsubform[module-path]{

在其最简单的形式中，@racket[_require-spec] 是一个 @racket[module-path]（如前一节 @secref["module-paths"] 中所定义）。在这种情况下，@racket[require] 引入的绑定由每个 @racket[module-path] 引用的模块中的 @racket[provide] 声明决定。

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

@racket[only-in] 形式限制了基础 @racket[require-spec] 将引入的绑定集。此外，@racket[only-in] 可选择性地重命名每个保留的绑定：在 @racket[[orig-id bind-id]] 形式中，@racket[orig-id] 指向 @racket[require-spec] 隐含的绑定，@racket[bind-id] 是在导入上下文中替代 @racket[orig-id] 进行绑定的名称。

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

此形式是 @racket[only-in] 的补充：它从 @racket[require-spec] 指定的集合中排除特定的绑定。

}

@;------------------------------------------------------------------------
@specspecsubform[#:literals (rename-in)
                 (rename-in require-spec [orig-id bind-id] ...)]{

此形式支持像 @racket[only-in] 一样的重命名，但不修改未作为 @racket[orig-id] 提及的 @racket[require-spec] 中的标识符。  }

@;------------------------------------------------------------------------
@specspecsubform[#:literals (prefix-in)
                 (prefix-in prefix-id require-spec)]{

这是重命名的简写形式，其中 @racket[prefix-id] 被添加到 @racket[require-spec] 指定的每个标识符的前面。

}

@racket[only-in]、@racket[except-in]、@racket[rename-in] 和 @racket[prefix-in] 形式可以嵌套使用，以实现对导入绑定的更复杂操作。例如，

@racketblock[(require (prefix-in m: (except-in 'm ghost)))]

导入 @racket[m] 导出的所有绑定，除了 @racket[ghost] 绑定，并且本地名称带有 @racket[m:] 前缀。

等效地，@racket[prefix-in] 可以在 @racket[except-in] 之前应用，只要 @racket[except-in] 的省略使用 @racket[m:] 前缀指定：

@racketblock[(require (except-in (prefix-in m: 'm) m:ghost))]
