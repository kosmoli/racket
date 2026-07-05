#lang scribble/doc
@(require "utils.rkt"
          (for-label (only-in '#%foreign
                              ffi-obj ffi-obj? ffi-obj-lib ffi-obj-name
                              ctype-basetype ctype-scheme->c ctype-c->scheme
                              ffi-call ffi-callback ffi-callback?)))

@title[#:tag "foreign:c-only"]{未导出的 Primitive Functions}

@declare-exporting['#%foreign]

@racketmodname[ffi/unsafe] 库的部分功能由 Racket 内置的
@racketmodname['#%foreign] 模块实现。@racketmodname['#%foreign]
模块不供直接使用，但它导出了以下 procedures（除此之外还有其他）。

@defproc[(ffi-obj [objname bytes?]
                  [lib (or/c ffi-lib? path-string? #f)])
         ffi-obj?]{

从 library 中提取一个 foreign object，返回一个可用作 C pointer 的值。
如果 @racket[lib] 是一个 path 或 string，则使用 @racket[ffi-lib]
来创建一个 library object。}


@defproc*[([(ffi-obj? [x any/c]) boolean?]
           [(ffi-obj-lib [obj ffi-obj?]) ffi-lib?]
           [(ffi-obj-name [obj ffi-obj?]) bytes?])]{

@racket[ffi-obj] 返回的对象的 predicate，以及返回其对应
library object 和 name 的 accessor functions。
这些值也可以用作 C pointer objects。}


@defproc*[([(ctype-basetype [type ctype?]) (or/c ctype? #f)]
           [(ctype-scheme->c [type ctype?]) procedure?]
           [(ctype-c->scheme [type ctype?]) procedure?])]{

由 @racket[make-ctype] 创建的 C type object 的组件的 accessors。
@racket[ctype-basetype] selector 返回一个 symbol，用于命名 primitive
type 的名字、cstructs 的 ctype 列表，以及用户定义的 ctypes 的另一个 ctype。}


@defproc[(ffi-call [ptr cpointer?] [in-types (listof ctype?)] [out-type ctype?]
                   [abi (or/c #f 'default 'stdio 'sysv) #f]
                   [save-errno? any/c #f]
                   [orig-place? any/c #f]
                   [lock-name (or/c #f string?) #f]
                   [blocking? any/c #f]
                   [varargs-after (or/c #f positive-exact-integer?) #f])
         procedure?]{

为 @racket[_cprocedure] 创建 Racket @tech{callout} values 的
primitive mechanism。给定的 @racket[ptr] 被包装在一个
Racket-callable primitive function 中，该 function 使用 types 来指定
如何 marshal values。}

@defproc[(ffi-call-maker [in-types (listof ctype?)] [out-type ctype?]
                   [abi (or/c #f 'stdio 'sysv) #f]
                   [save-errno? any/c #f]
                   [orig-place? any/c #f]
                   [lock-name (or/c #f string?) #f]
                   [blocking? any/c #f]
                   [varargs-after (or/c #f positive-exact-integer?) #f])
         (cpointer . -> . procedure?)]{

@racket[ffi-call] 的一个 curried variant，它分别接受 foreign-procedure pointer。}


@defproc[(ffi-callback [proc procedure?] [in-types any/c] [out-type any/c]
                       [abi (or/c #f 'stdio 'sysv) #f]
                       [atomic? any/c #f]
                       [async-apply (or/c #f ((-> any) . -> . any) box?) #f]
                       [varargs-after (or/c #f positive-exact-integer?) #f])
         ffi-callback?]{

@racket[ffi-call] 的对称对应物。它接收一个 Racket procedure
并创建一个 @tech{callback} object，该 object 也可用作 C pointer。}

@defproc[(ffi-callback-maker [in-types any/c] [out-type any/c]
                       [abi (or/c #f 'stdio 'sysv) #f]
                       [atomic? any/c #f]
                       [async-apply (or/c #f ((-> any) . -> . any) box?) #f]
                       [varargs-after (or/c #f positive-exact-integer?) #f])
         (procedure? . -> . ffi-callback?)]{

@racket[ffi-callback] 的一个 curried variant，它分别接受 callback procedure。}


@defproc[(ffi-callback? [v any/c]) boolean?]{

由 @racket[ffi-callback] 创建的 callback values 的 predicate。}


@defproc[(make-late-will-executor) will-executor?]{

创建一个"late" will executor，它仅为那些没有 normal will executor
为其注册了 will 的值 @scheme[_v] 准备 will。此外，对于 Racket 的 @BC[]
实现，normal will executor 为 @racket[_v] 准备 will 之前，会清除对
@scheme[_v] 的 normal weak references；但由 @racket[make-late-weak-box]
和 @racket[make-late-weak-hasheq] 创建的 late weak references 不会被清除。
对于 Racket 的 @CS[] 实现，只有当 @racket[_v] 从任何具有 late will 的
值都不可达时，才会为 @racket[_v] 准备 will；如果值 @racket[_v] 从自身可达
（即，通过 @racket[_v] 的任何字段，而不是直接值本身），那么
@racket[_v] 的"late" will 永远不会变为 ready。

与 normal will executor 不同，如果 late will executor 变得不可达，
那么它拥有 pending wills 的值会在 late will executor 的 place 内被保留。

late will executor 用于 @racket[register-finalizer] 的实现中。}
