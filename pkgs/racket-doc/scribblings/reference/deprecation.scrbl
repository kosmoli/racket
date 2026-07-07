#lang scribble/doc

@(require (for-label racket/deprecation
                     racket/deprecation/transformer
                     syntax/parse/define)
          "mz.rkt")


@title{Deprecation}


@note-lib-only[racket/deprecation]


一个 @deftech{deprecated} 的 function、macro 或其他 API 元素是已被正式声明为过时的元素，通常具有用户应迁移到的预期替换。
@racketmodname[racket/deprecation] 库提供了一种标准化机制，用于以机器可处理的方式声明弃用。这些声明可以允许诸如 @racketmodname[resyntax #:indirect] 等工具自动迁移代码，使其不再使用已弃用的 API。请注意，
依赖 @racketmodname[racket/deprecation] 库并不暗示依赖于任何此类工具。


@section[#:tag "deprecation-s1"]{Deprecated Aliases}


@defform[(define-deprecated-alias alias-id target-id)]{

 将 @racket[alias-id] 绑定为 @racket[target-id] 的别名，意图是让 @racket[alias-id] 的用户优先使用 @racket[target-id]。给定的 @racket[alias-id] 绑定为 @tech{deprecated alias transformer}，一种 @tech{rename transformer}。给定的 @racket[target-id] 可以绑定到 function、macro 或任何其他类型的绑定。

 注意，虽然 @racket[alias-id] 是 @racket[target-id] 的别名，但它 @emph{不} 被视为与 @racket[target-id] 相同的绑定，并且 @emph{不} @racket[free-identifier=?]。这是因为别名绑定必须在编译时可以通过 @racket[deprecated-alias?] 和 @racket[deprecated-alias-target]，甚至在别名由模块 @racket[provide] 后仍可检查。这要求提供别名和目标的模块将它们作为两个不同的绑定提供：一个绑定到 @tech{deprecated alias transformer}，另一个则不是。

 @(examples
   (require racket/deprecation)
   (define a 42)
   (define-deprecated-alias legacy-a a)
   legacy-a)}


@section[#:tag "deprecation-s2"]{Deprecated Alias Transformers}
@defmodule[racket/deprecation/transformer]


@racketmodname[racket/deprecation/transformer] 模块提供 @racketmodname[racket/deprecation] 库的编译时支持代码，主要用于希望反映弃用代码的工具。

@deftech{deprecated alias transformer} 是一种 @tech{rename transformer}，它信号表示转换器绑定是目标标识符的 @tech{deprecated} 别名。此信号旨在由诸如编辑器（在希望使用弃用时希望显示警告时）和自动重构系统（可能希望自动将弃用别名替换为其目标标识符）等工具使用。


@defproc[(deprecated-alias? [v any/c]) boolean?]{

 如果 @racket[v] 是 @tech{deprecated alias transformer} 则返回真，否则返回假。
 暗示 @racket[rename-transformer?]。要确定标识符是 @emph{绑定} 到弃用别名转换器，请使用 @racket[syntax-local-value/immediate] 然后对转换器值使用 @racket[deprecated-alias?]。

@(examples
  #:escape UNSYNTAX
  (require (for-syntax racket/base
                       racket/deprecation/transformer)
           racket/deprecation
           syntax/parse/define)

  (define-syntax-parse-rule (is-deprecated? id:id)
    #:do [(define-values (transformer _)
            (syntax-local-value/immediate #'id (λ () (values #false #false))))]
    #:with result (deprecated-alias? transformer)
    'result)

  (define-deprecated-alias bad-list list)
  (is-deprecated? list)
  (is-deprecated? bad-list))}


@defproc[(deprecated-alias [target identifier?]) deprecated-alias?]{

 构造一个 @tech{deprecated alias transformer}，在使用时展开为 @racket[target]。
 返回的别名是一个 @tech{rename transformer}，因此适合与 @racket[define-syntax] 使用。展开时，@racket[target] 的使用会使用 @racket['not-free-identifier=?] 语法属性进行注释，以确保别名和目标被视为不同的绑定，即使在模块 @racket[provide] 时也是如此。

 此构造函数不适合直接供仅想声明弃用别名的用户使用。
 这些用户应优先使用 @racket[define-deprecated-alias] 形式。}


@defproc[(deprecated-alias-target [alias deprecated-alias?]) identifier?]{

 返回 @racket[alias] 展开到的目标标识符。}
