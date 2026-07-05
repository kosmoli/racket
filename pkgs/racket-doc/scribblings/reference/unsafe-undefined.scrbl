#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/unsafe/undefined))

@title[#:tag "unsafe-undefined"]{Unsafe Undefined}

@note-lib-only[racket/unsafe/undefined]

常量 @racket[unsafe-undefined] 在内部被用作占位值。例如，它被 @racket[letrec] 用作尚未赋值的 variable 的值。然而，与 @racketmodname[racket/undefined] 导出的 @racket[undefined] 值不同，@racket[unsafe-undefined] 值不应泄露为某个安全表达式的结果，也不应作为可选参数传给 procedure（因为可能被视作"未提供值"）。
可能产生 @racket[unsafe-undefined] 的表达式结果可以由 @racket[check-not-unsafe-undefined] 保护，以便在产生 @racket[undefined] 值之前引发异常。

@racket[unsafe-undefined] 值始终与自身是 @racket[eq?] 的。

@history[#:added "6.0.1.2"
         #:changed "6.90.0.29" @elem{带有可选参数的 Procedure 有时会在内部使用
                                     @racket[unsafe-undefined] 来表示"未提供参数"。}]

@defthing[unsafe-undefined any/c]{

不安全的"undefined"常量。

参见上面了解 @racket[unsafe-undefined] 使用的重要约束条件。}


@defproc[(check-not-unsafe-undefined [v any/c] [sym symbol?])
         any/c]{

检查 @racket[v] 是否为 @racket[unsafe-undefined]，如果是则引发 @racket[exn:fail:contract:variable] 异常，其错误消息形如“@racket[sym]：undefined；在初始化前使用”。如果 @racket[v] 不是 @racket[unsafe-undefined]，则返回 @racket[v]。}

@defproc[(check-not-unsafe-undefined/assign [v any/c] [sym symbol?])
         any/c]{

与 @racket[check-not-unsafe-undefined] 相同，不过其错误消息（如果有）形如"@racket[sym]：undefined；在初始化前赋值"。}


@defproc[(chaperone-struct-unsafe-undefined [v any/c]) any/c]{

如果 @racket[v] 是一个通过某 @tech{inspector} 看到的结构，则 chaperone 它。对结构中每个字段的访问都会进行检查，防止返回 @racket[unsafe-undefined]。同样，对结构中每个字段的赋值也会进行检查（除非检查已被如下方式禁用），防止将字段的当前值为 @racket[unsafe-undefined] 的字段赋值。

当某个字段访问可能产生 @racket[unsafe-undefined] 或某个字段赋值可能替换 @racket[unsafe-undefined] 时，会引发 @racket[exn:fail:contract] 异常。

当 @racket[(continuation-mark-set-first #f prop:chaperone-unsafe-undefined)] 返回 @racket[unsafe-undefined] 时，chaperone 的字段赋值检查被禁用。因此，字段初始化赋值——旨在替换字段 @racket[unsafe-undefined] 值的赋值——应包裹在 @racket[(with-continuation-mark prop:chaperone-unsafe-undefined unsafe-undefined ....)] 中。}


@defthing[prop:chaperone-unsafe-undefined struct-type-property?]{

一个 @tech{结构类型属性}，使结构类型的构造函数以与 @racket[chaperone-struct-unsafe-undefined] 相同的方式 chaperone 实例。

属性值应为一个用作字段名称的 symbol 列表，但顺序应与结构字段顺序相反。当某个字段访问或赋值会产生或替换 @racket[unsafe-undefined] 时，如果字段名称由结构属性的值提供，则引发 @racket[exn:fail:contract:variable] 异常，否则引发 @racket[exn:fail:contract] 异常。}
