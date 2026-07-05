#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/define
                     ffi/unsafe/alloc
                     ffi/unsafe/define/conventions))

@title{定义 Binding}

@defmodule[ffi/unsafe/define]

@defform/subs[(define-ffi-definer define-id ffi-lib-expr
                option ...)
              ([option (code:line #:provide provide-id)
                       (code:line #:define core-define-id)
                       (code:line #:default-make-fail default-make-fail-expr)
                       (code:line #:make-c-id make-c-id)])]{

将 @racket[define-id] 绑定为一个定义形式，用于从 @racket[ffi-lib-expr] 产生的库中提取 binding。@racket[define-id] 的语法为

@specform/subs[#:literals (unquote)
               (define-id id type-expr
                 bind-option ...)
               ([bind-option (code:line #:c-id c-id)
                             (code:line #:c-id (@#,(racket unquote) c-id-expr))
                             (code:line #:wrap wrap-expr)
                             (code:line #:make-fail make-fail-expr)
                             (code:line #:fail fail-expr)
                             (code:line #:variable)])]

@racket[define-id] 通过从 @racket[ffi-lib-expr] 产生的库中提取名称为 @racket[_c-id] 的 binding 来绑定 @racket[id]（其中 @racket[_c-id] 默认为 @racket[_id]）。其他选项支持进一步的包装与配置：

@itemize[

 @item{在被绑定为 @racket[_id] 之前，提取的结果会被传递给 @racket[_wrap-expr] 的结果，默认为 @racket[values]。诸如 @racket[(allocator _delete)] 或 @racket[(deallocator)] 之类的表达式适合作为 @racket[_wrap-expr] 使用。}

 @item{@racket[#:make-fail] 和 @racket[#:fail] 选项是互斥的；如果提供了 @racket[_make-fail-expr]，则会将其应用于 @racket['@#,racket[_id]] 以获取 @racket[get-ffi-obj] 的最后一个参数；如果提供了 @racket[_fail-expr]，则直接将其作为 @racket[get-ffi-obj] 的最后一个参数。@racket[make-not-available] function 适合作为 @racket[_make-fail-expr]，用于使 @racket[_id] 的每次使用（如果 @racket[_c-id] 在外部库中未找到）报告错误。}

 @item{如果 @racket[#:c-id] 选项与一个 identifier 参数 @racket[_c-id] 一起提供，则 @racket[_c-id] 被用做外部名称。如果参数具有形式 @racket[(@#,(racket unquote) _c-id-expr)]，则外部名称是 @racket[_c-id-expr] 求值的结果。无论哪种情况，@racket[#:make-c-id] 参数都会被忽略。}

 @item{如果没有提供 @racket[#:c-id] 选项，则外部名称基于 @racket[_id]。如果 @racket[define-id] 是与 @racket[#:make-c-id] 选项一起定义的，则会使用 @tech{ffi identifier convention} 计算外部名称，例如将连字符转换为下划线或驼峰式大小写。@racketmodname[ffi/unsafe/define/conventions] 提供了多种 convention。如果 @racket[#:make-c-id] 未提供，则 @racket[_id] 被直接使用为外部名称。}

 @item{如果 @racket[#:variable] 关键字已提供，则会使用 @racket[make-c-parameter] 而非 @racket[get-ffi-obj] 来获取外部值。}

]

如果向 @racket[define-ffi-definer] 提供了 @racket[provide-id]，则 @racket[define-id] 也会使用 @racket[provide-id] 提供它的 binding。@racket[provide-protected] 形式通常是 @racket[provide-id] 的一个好选择。

如果向 @racket[define-ffi-definer] 提供了 @racket[core-define-id]，则 @racket[core-define-id] 会在每个 binding 的 @racket[define-id] 展开中替代 @racket[define]。

如果向 @racket[define-ffi-definer] 提供了 @racket[default-make-fail-expr]，它会作为 @racket[define-id] 的 @racket[#:make-fail] 默认值。

例如，

@racketblock[
  (define-ffi-definer define-gtk gtk-lib)
]

将 @racket[define-gtk] 绑定为从 @racket[gtk-lib] 提取 FFI binding 的形式，因此 @racket[gtk_rc_parse] 可以被绑定为

@racketblock[
  (define-gtk gtk_rc_parse (_fun _path -> _void))
]

如果 @tt{gtk_rc_parse} 未被找到，则 @racket[define-gtk] 立即报告错误。如果改为

@racketblock[
  (define-ffi-definer define-gtk gtk-lib
     #:default-make-fail make-not-available)
]

那么如果 @tt{gtk_rc_parse} 在 @racket[gtk-lib] 中未找到，错误仅在 @racket[gtk_rc_parse] 被调用时报告。

@history[#:changed "6.9.0.5" @elem{添加了 @racket[#:make-c-id] 参数。}
         #:changed "8.4.0.5" @elem{添加了 @racket[#:variable] 选项。
                                   添加了 @racket[#:c-id] 参数的 @racket[unquote] 变体。}]}


@defproc[(make-not-available [name symbol?]) procedure?]{

返回一个接受任意数量参数（包括 keyword 参数）的 function，从 @racket[name] 引发 @racket[exn:fail:unsupported] 异常。该 function 专门用于配合 @racket[#:make-fail] 或 @racket[#:default-make-fail] 在 @racket[define-ffi-definer] 中使用。

@history[#:changed "8.3.0.5" @elem{添加了对 keyword 参数的支持。}
         #:changed "9.2.0.2" @elem{改为引发 @racket[exn:fail:unsupported]。}]}

@defform[(provide-protected provide-spec ...)]{

等价于 @racket[(provide (protect-out provide-spec ...))]。@racket[provide-protected] identifier 在 @racket[define-ffi-definer] 中与 @racket[#:provide] 配合使用时很有用。}

@section{FFI Identifier Convention}

@defmodule[ffi/unsafe/define/conventions]

本模块提供多种 @deftech{FFI identifier convention}，与 @racket[define-ffi-definer] 中的 @racket[#:make-c-id] 配合使用。一个 @tech{FFI identifier convention} 是任意将一个 identifier 转换为另一个 identifier 的 @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{syntax transformer}。

@history[#:added "6.9.0.5"]

@defidform[convention:hyphen->underscore]{

 将 identifier 中的连字符转换为下划线的 convention。例如，identifier @racket[underscore-variable] 会转换为 @racket[underscore_variable]。

@racketblock[
  (define-ffi-definer define-unlib underscore-lib
    #:make-c-id convention:hyphen->underscore)
  (define-unlib underscore-variable (_fun -> _void))
]

}

@defidform[convention:hyphen->camelCase]{

 类似于 @racket[convention:hyphen->underscore]，但将 identifier 转换为 ``camelCase''，遵循 @racket[string-downcase] 和 @racket[string-titlecase] function。例如，identifier @racket[camel-case-variable]（甚至 @racket[cAmeL-CAsE-vaRiaBlE]）会转换为 @racket[camelCaseVariable]。

@racketblock[
  (define-ffi-definer define-calib camel-lib
    #:make-c-id convention:hyphen->camelCase)
  (define-calib camel-case-variable (_fun -> _void))
]

@history[#:added "8.11.1.8"]
}

@defidform[convention:hyphen->PascalCase]{

 像 @racket[convention:hyphen->camelCase]，但将 identifier 转换为 ``PascalCase''，遵循 @racket[string-titlecase] function。例如，identifier @racket[pascal-case-variable]（甚至 @racket[paSCaL-CAsE-vaRiaBlE]）会转换为 @racket[PascalCaseVariable]。

@racketblock[
  (define-ffi-definer define-palib pascal-lib
    #:make-c-id convention:hyphen->PascalCase)
  (define-palib pascal-case-variable (_fun -> _void))
]

@history[#:added "8.11.1.8"]
}

@defidform[convention:hyphen->camelcase]{

 @deprecated[#:what "convention"
             @racket[convention:hyphen->PascalCase]]{
  不幸的是，这个 convention 会转换成 ``PascalCase''，而非其名称所暗示的 ``camelcase''。
 }

@history[#:changed "8.11.1.8" @elem{因行为错误而废弃。}]
}
