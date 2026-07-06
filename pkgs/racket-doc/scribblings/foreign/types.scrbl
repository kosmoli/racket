#lang scribble/doc
@(require "utils.rkt" 
          (for-label scheme/match)
          (for-syntax racket/base)
          scribble/eval
          scribble/racket)

@(define-syntax _float*
   (make-element-id-transformer
     (lambda (stx)
       #'@racketidfont{_float*})))

@(define-syntax-rule (defform-arrow . content)
   (begin
     (require (only-in (for-label ffi/unsafe) ->))
     (defidform -> . content)))

@(define ffi-eval (make-base-eval))
@(ffi-eval '(require ffi/unsafe))

@(begin
   (define-syntax-rule (define-static_fun id)
      (begin
       (require (for-label ffi/unsafe/static))
       (define id @racket[_fun])))
    (define-static_fun static_fun))

@title[#:tag "types" #:style 'toc]{C Types}

@deftech{C types} 是 @tech{FFI} 的核心概念，包括原始类型和用户自定义类型。
@tech{FFI} 在内部处理原始类型，在 C 类型之间进行转换。
用户类型基于已有的原始类型和用户类型来定义，
并附带与已有类型之间的转换函数。

@local-table-of-contents[]

@; ----------------------------------------------------------------------

@section[#:tag "ctype"]{类型构造函数}

@defproc[(make-ctype [type ctype?]
                     [racket-to-c (or/c #f (any/c . -> . any))]
                     [c-to-racket (or/c #f (any/c . -> . any))])
         ctype?]{

创建一个新的 @tech{C type} 值，其对外部代码的表示与 @racket[type] 相同。

给定的转换函数用于在新类型的 Racket 表示之间进行转换。任一转换函数可以为
@racket[#f]，表示对应方向的转换是恒等函数。如果两个函数都是
@racket[#f]，则直接返回 @racket[type]。

@racket[racket-to-c] 函数接受任意值，如果该值是新类型的有效表示，则将其转换为
@racket[type] 的表示。@racket[c-to-racket] 函数接受
@racket[type] 的表示并产生新类型的表示。

当结果类型用于外部调用的参数时，请注意只有原始参数值会为调用专门保留，
而非 @racket[racket-to-c] 的结果。如果外部调用导致 Racket callback，
callback 期间的 garbage collection 可能会移动或回收原本未被引用的参数值。
考虑在 ephemeron hash table 中注册从参数到 @racket[racket-to-c] 结果的映射，
使得只要参数可达，结果也保持可达。}


@defproc[(ctype? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{C type} 则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval ffi-eval
  (ctype? _int)
  (ctype? (_fun _int -> _int))
  (ctype? #f)
  (ctype? "foo")
]}


@defproc*[([(ctype-sizeof [type ctype?]) exact-nonnegative-integer?]
           [(ctype-alignof [type ctype?]) exact-nonnegative-integer?])]{

返回给定 @racket[type] 在当前平台上的大小或对齐值。

@examples[#:eval ffi-eval
  (ctype-sizeof _int)
  (ctype-sizeof (_fun _int -> _int))
  (ctype-alignof _int)
  (ctype-alignof (_fun _int -> _int))
]}


@defproc[(ctype->layout [type ctype?])
         (flat-rec-contract rep symbol? (listof rep))]{

返回一个值来描述该类型最终在 C 中的表示。它可以是以下任何一种 symbol：

@racketblock[
  'int8 'uint8 'int16 'uint16 'int32 'uint32 'int64 'uint64
  'float 'double 'bool 'void 'pointer 'fpointer 
  'bytes 'string/ucs-4 'string/utf-16
]

结果也可以是一个 list，描述一个 C struct，其中的元素表示按顺序在 list 中给出。
最后，结果还可以是一个大小为 2 的 vector，包含一个元素表示及其后的 exact-integer 计数。

@examples[#:eval ffi-eval
  (ctype->layout _int)
  (ctype->layout _void)
  (ctype->layout (_fun _int -> _int))
]}


@defproc[(compiler-sizeof [sym (or/c symbol? (listof symbol?))]) exact-nonnegative-integer?]{

@racket[sym] 的可能取值包括 @racket['int]、@racket['char]、@racket['wchar]、
@racket['short]、@racket['long]、@racket['*]、@racket['void]、
@racket['float]、@racket['double]，或 symbol 的 list，如
@racket['(long long)]。结果是根据当前平台的 C @cpp{sizeof} 运算符得出的
相应类型的大小。@racket[compiler-sizeof] 操作应用于收集当前平台的信息，
例如将别名类型 @racket[_int] 定义为已知类型如 @racket[_int32]。

@examples[#:eval ffi-eval
  (compiler-sizeof 'int)
  (compiler-sizeof '(long long))
]}

@; ----------------------------------------------------------------------

@section{数值类型}

@defthing*[([_int8 ctype?]
            [_sint8 ctype?]
            [_uint8 ctype?]
            [_int16 ctype?]
            [_sint16 ctype?]
            [_uint16 ctype?]
            [_int32 ctype?]
            [_sint32 ctype?]
            [_uint32 ctype?]
            [_int64 ctype?]
            [_sint64 ctype?]
            [_uint64 ctype?])]{

各种大小的基本整数类型。@racketidfont{s} 或 @racketidfont{u} 前缀分别指定有符号或无符号整数；
不带前缀的为有符号整数。}


@defthing*[([_byte ctype?]
            [_sbyte ctype?]
            [_ubyte ctype?])]{

@racket[_sbyte] 和 @racket[_ubyte] 类型分别是 @racket[_sint8] 和 @racket[_uint8] 的别名。
@racket[_byte] 类型类似于 @racket[_ubyte]，但会为原本可作为 @racket[_sbyte] 的
负 Racket 值加上 256（即将有符号字节转换为无符号字节）。}


@defthing*[([_wchar ctype?])]{

@racket[_wchar] 类型是无符号整数类型的别名，如 @racket[_uint16] 或 @racket[_uint32]，
对应于平台的 @as-index{@tt{wchar_t}} 类型。

@history[#:added "7.0.0.3"]}


@defthing*[([_word ctype?]
            [_sword ctype?]
            [_uword ctype?]
            )]{

@racket[_sword] 和 @racket[_uword] 类型分别是 @racket[_sint16] 和 @racket[_uint16] 的别名。
@racket[_word] 类型类似于 @racket[_uword]，但以与 @racket[_byte] 相同的方式
强制转换负值。}


@defthing*[([_short ctype?]
            [_sshort ctype?]
            [_ushort ctype?]
            [_int ctype?]
            [_sint ctype?]
            [_uint ctype?]
            [_long ctype?]
            [_slong ctype?]
            [_ulong ctype?]
            [_llong ctype?]
            [_sllong ctype?]
            [_ullong ctype?]
            [_intptr ctype?]
            [_sintptr ctype?]
            [_uintptr ctype?])]{

基本整数类型的别名。@racket[_short] 别名对应于 @racket[_int16]。@racket[_int] 别名对应于
@racket[_int32]。@racket[_long] 别名对应于 @racket[_int32] 或 @racket[_int64]，
取决于平台。类似地，@racket[_intptr] 别名对应于 @racket[_int32] 或 @racket[_int64]，
也取决于平台。}

@defthing*[([_size ctype?]
            [_ssize ctype?]
            [_ptrdiff ctype?]
            [_intmax ctype?]
            [_uintmax ctype?])]{

基本整数类型的更多别名。@racket[_size] 和 @racket[_uintmax] 类型是 @racket[_uintptr] 的别名，
其余的是 @racket[_intptr] 的别名。}

@defthing*[([_fixnum ctype?]
            [_ufixnum ctype?])]{

对于速度很关键且已知整数足够小的情况，类型 @racket[_fixnum] 和 @racket[_ufixnum]
类似于 @racket[_intptr] 和 @racket[_uintptr]，但假定值适合 Racket 的立即整数
（即不是 bignum）。}

@defthing*[([_fixint ctype?]
            [_ufixint ctype?])]{

类似于 @racket[_fixnum]/@racket[_ufixnum]，但基于 @racket[_int]/@racket[_uint]
而非 @racket[_intptr]/@racket[_uintptr]，并且会检查从 C 的强制转换是否在范围内。}

@defthing*[([_float ctype?]
            [_double ctype?]
            [_double* ctype?])]{

@racket[_float] 和 @racket[_double] 类型表示相应的 C 类型。单精度和双精度的 Racket
数字均可通过 @racket[_float] 和 @racket[_double] 进行转换，
而 @racket[_float] 和 @racket[_double] 都将 C 值强制转换为双精度 Racket 数字。
类型 @racket[_double*] 将任意 Racket 实数强制转换为 C @cpp{double}。}

@defthing[_longdouble ctype?]{

在支持 @cpp{long double} 类型的平台上表示该类型，此时 Racket
@tech[#:doc reference.scrbl]{extflonum} 与 @cpp{long double} 值之间相互转换。}

@; ------------------------------------------------------------

@section{其他原子类型}

@defthing[_stdbool ctype?]{

@racket[_stdbool] 类型表示来自 @cpp{<stdbool.h>} 的 C99 @cpp{bool} 类型。
从 Racket 到 C，@racket[_stdbool] 将 @racket[#f] 翻译为 @racket[0] @cpp{bool}，
将任何其他值翻译为 @racket[1] @cpp{bool}。从 C 到 Racket，@racket[_stdbool]
将 @racket[0] 翻译为 @racket[#f]，将任何其他值翻译为 @racket[#t]。

@history[#:added "6.0.0.6"]}

@defthing[_bool ctype?]{

类似于 @racket[_stdbool]，但在 C 端使用 @cpp{int} 表示，反映了布尔值
的多种传统编码之一（即 C99 之前的编码）。}

@defthing[_void ctype?]{

表示 Racket @|void-const| 返回值，不能用于将值翻译到 C。此类型不能用于函数输入。}

@; ------------------------------------------------------------

@section{字符串类型}

@subsection{原始字符串类型}

另请参见 @racket[_bytes/nul-terminated] 和 @racket[_bytes]，用于在字节字符串和 C 的 @cpp{char*} 类型之间转换。

@deftogether[(
@defthing[_string/ucs-4 ctype?]
)]{

用于包含 nul 终止符的 UCS-4 格式字符串的类型。与通常一样，
该类型将 @racket[#f] 视为 @cpp{NULL}，反之亦然。

对于 Racket 的 @CS[] 实现，将 Racket 字符串转换为外部端使用的是 Racket 表示的一个副本，
该副本由 garbage collector 管理。

对于 Racket 的 @BC[] 实现，将 Racket 字符串转换为外部端时与 Racket 字符串表示共享内存，
因为 UCS-4 是这些变体的原生表示格式。外部指针对应于 Racket C API 中的
@cpp{mzchar*} 类型。}


@deftogether[(
@defthing[_string/utf-16 ctype?]
)]{

UTF-16 格式的 Unicode 字符串，包含 nul 终止符。与通常一样，
该类型将 @racket[#f] 视为 @cpp{NULL}，反之亦然。

将 Racket 字符串转换为外部端是 Racket 表示的一个副本（重新编码），
该副本由 garbage collector 管理。}


@defthing[_path ctype?]{

简单的 nul 终止 @cpp{char*} 字符串，对应于 Racket 的 @tech[#:doc reference.scrbl]{path or string}。
与通常一样，该类型将 @racket[#f] 视为 @cpp{NULL}，反之亦然。

对于 Racket 的 @BC[] 实现，将 Racket path 转换为外部端时与 Racket path 表示共享内存。
否则（对于 @CS[] 实现或对于 Racket 字符串），转换为外部端会创建一个
由 garbage collector 管理的副本。

请注意，通过 @racket[current-directory] 更改当前目录不会<改变外部库函数看到的
OS 级当前目录。Path 通常应在传递给外部函数之前
使用 @racket[path->complete-path]（它使用 @racket[current-directory] 参数）
转换为绝对形式。}

@defthing[_symbol ctype?]{

简单的 @cpp{char*} 字符串作为 Racket symbol（以 UTF-8 编码并以 nul 终止），
旨在作为外部端的只读值。使用此类型的返回值会被 intern 为 symbol。

对于 Racket 的 @CS[] 实现，将 Racket symbol 转换为外部端的是 Racket 表示的一个副本，
该副本由 garbage collector 管理。

对于 Racket 的 @BC[] 实现，将 Racket symbol 转换为外部端时与 Racket symbol
表示共享内存，但指向 symbol 已分配内存的中间位置——因此字符串指针
不能在 garbage collection 期间使用。}


@subsection{固定自动转换字符串类型}

@defthing*[([_string/utf-8 ctype?]
            [_string/latin-1 ctype?]
            [_string/locale ctype?])]{

对应于 Racket 端的（字符）字符串和 C 端的 @cpp{char*} 字符串的类型。
两者之间的桥梁需要对字符串内容进行转换。与通常一样，
这些类型将 @racket[#f] 视为 @cpp{NULL}，反之亦然。}

@defthing*[([_string*/utf-8 ctype?]
            [_string*/latin-1 ctype?]
            [_string*/locale ctype?])]{

类似于 @racket[_string/utf-8] 等，但接受更广泛的值范围：允许 Racket 字节字符串并按原样传递，
Racket path 使用 @racket[path->bytes] 进行转换。}


@subsection{可变自动转换字符串类型}

@racket[_string/ucs-4] 类型在与外部代码交互时很少有用，而使用 @racket[_bytes/nul-terminated]
则有些不太自然，因为它迫使 Racket 程序员使用字节字符串。使用
@racket[_string/utf-8] 等可能会过早地承诺某种特定的字符串到字节的编码。
@racket[_string] 类型支持在 Racket 字符串和 @cpp{char*} 字符串之间使用
由参数决定的转换。

@defthing[_string ctype?]{

展开为对 @racket[default-_string-type] 参数的使用。当 @racket[_string] 被求值时，
会查询该参数的值，因此该参数应在任何使用 @racket[_string] 的接口定义之前设置。

在应该使用 @racket[_path] 的地方不要使用 @racket[_string]。
虽然 C API 通常将路径表示为字符串，虽然默认的 @racket[_string]（通过 @racket[default-_string-type]）
甚至可以隐式地将 Racket path 转换为字符串，但使用 @racket[_path] 可以确保
字符串作为路径的正确编码，这不总是 UTF-8。另请参见 @racket[_path] 中关于相对路径的注意事项。}

@defparam[default-_string-type type ctype?]{

一个参数，决定 @racket[_string] 的当前含义。初始设置为 @racket[_string*/utf-8]。
如果你要更改它，请在定义接口@italic{之前}进行。}


@subsection{其他字符串类型}

@defthing[_file ctype?]{

类似于 @racket[_path]，但当值从 Racket 转到 C 时，会对给定值使用 @racket[cleanse-path]。
作为输出值，它与 @racket[_path] 完全相同。}

@defthing[_bytes/eof ctype?]{

类似于 @racket[_bytes] 类型，只是将 @cpp{NULL} 的外部返回值翻译为 Racket @racket[eof] 值。}

@defthing[_string/eof ctype?]{

类似于 @racket[_string] 类型，只是将 @cpp{NULL} 的外部返回值翻译为 Racket @racket[eof] 值。}

@; ------------------------------------------------------------

@section{指针类型}

@defthing[_pointer ctype?]{

对应于 Racket @deftech{C pointer} 值。这些指针可以附加一个任意的 Racket 对象
作为类型标签。该标签被内置功能忽略；它旨在供接口使用。
请参见 @secref["foreign:tagged-pointers"] 了解如何创建使用这些标签
以确保安全的指针类型。@racket[#f] 值被转换为 @cpp{NULL}，反之亦然。

作为结果类型，@racket[_pointer] 值引用的地址不得指向由 garbage collector 管理的内存
（除非该地址对应于支持 interior pointer 的值，并且该值以其他方式被引用
以防止被 garbage collection 回收）。该引用不会被 garbage collector 追踪或更新。
作为参数类型，@racket[_pointer] 适用于对 GC 管理或非 GC 管理的内存的引用。

@racket[equal?] 谓词在 C pointer 引用相同地址时将它们视为相等
（包括 @racket[_gcpointer] 的指针和可能包含偏移量的指针）——但对于具有
@racket[prop:cpointer] 属性的结构类型的实例，适用相关结构类型的相等规则。}


@defthing[_gcpointer ctype?]{

作为参数类型与 @racket[_pointer] 相同，但作为结果类型，
@racket[_gcpointer] 对应于指向由 garbage collector 管理的内存的 C pointer 值。

在 Racket 的 @BC[] 实现中，@racket[_gcpointer] 结果指针可以引用不由 garbage collector
管理的内存，但要小心使用可能最终变为由 garbage collector 管理的地址。例如，
如果引用是通过 @racket[malloc] 用 @racket['raw] 创建的，并通过 @racket[free] 释放，
那么 @racket[free] 可能允许先前由该引用占用的内存后来被 garbage collector 使用。

对于通过 @racket[_gcpointer] 结果类型生成的 cpointer，@racket[cpointer-gcable?] 函数返回 @racket[#t]。
更多信息请参见 @racket[cpointer-gcable?]。}


@deftogether[(
@defthing[_racket ctype?]
@defthing[_scheme ctype?]
)]{

可用于任何 Racket 对象的类型；它对应于 Racket C API 的 @cpp{Scheme_Object*} 类型
（参见 @|InsideRacket|）。@racket[_racket] 或 @racket[_scheme] 类型仅对
了解 Racket C API 的库有用。

作为函数类型的结果类型，@racket[_racket] 或 @racket[_scheme] 允许多值，
但多值不能与 @racket[_cprocedure] 或 @racket[_fun] 中
@racket[#:in-original-place?] 或 @racket[#:async-apply] 的真值
组合使用。}


@defthing[_fpointer ctype?]{

类似于 @racket[_pointer]，但当 @racket[_fpointer] 用作 @racket[get-ffi-obj] 或
@racket[ffi-obj-ref] 的类型时，会跳过一个间接层。此外，对于使用
@racket[_fpointer] 的 @racket[get-ffi-obj] 或 @racket[ffi-obj-ref] 返回的 C pointer 值，
对该指针作为 @racket[_fpointer] 调用 @racket[ptr-ref] 时，只是返回该指针而不进行解引用。
与 @racket[_pointer] 一样，@racket[_fpointer] 将 @racket[#f] 视为 @cpp{NULL}，反之亦然。

@racket[_cprocedure] 或 @racket[_fun] 生成的类型构建在 @racket[_fpointer] 之上，
通常应该使用 @racket[_cprocedure] 或 @racket[_fun] 而非 @racket[_fpointer]。}


@defproc[(_or-null [ctype ctype?]) ctype?]{

创建一个类似于 @racket[ctype] 的类型，但 @racket[#f] 被转换为 @cpp{NULL}，反之亦然。
给定的 @racket[ctype] 必须与 @racket[_pointer]、@racket[_gcpointer] 或 @racket[_fpointer]
具有相同的 C 表示。}


@defproc[(_gcable [ctype ctype?]) ctype?]{

创建一个类似于 @racket[ctype] 的类型，但其基础表示类似于 @racket[_gcpointer]
而非 @racket[_pointer]。给定的 @racket[ctype] 必须具有类似于 @racket[_pointer]
或 @racket[_gcpointer] 的基础表示（在后一种情况下，结果就是 @racket[ctype]）。}


@; ------------------------------------------------------------

@section[#:tag "foreign:procedures"]{函数类型}

@defproc[(_cprocedure [input-types (list ctype?)]
                      [output-type ctype?]
                      [#:abi abi (or/c #f 'default 'stdcall 'sysv) #f]
                      [#:varargs-after varargs-after (or/c #f positive-exact-integer?) #f]
                      [#:atomic? atomic? any/c #f]
                      [#:async-apply async-apply (or/c #f ((-> any/c) . -> . any/c) box?) #f]
                      [#:lock-name lock-name (or/c string? #f) #f]
                      [#:in-original-place? in-original-place? any/c #f]
                      [#:blocking? blocking? any/c #f]
                      [#:callback-exns? callback-exns? any/c #f]
                      [#:save-errno save-errno (or/c #f 'posix 'windows) #f]
                      [#:wrapper wrapper (or/c #f (procedure? . -> . procedure?))
                                         #f]
                      [#:keep keep (or/c boolean? box? (any/c . -> . any/c))
                                   #t])
         any]{

一个类型构造函数，创建由给定 @racket[input-types] list 和 @racket[output-type] 指定的新函数类型。
通常应该使用 @racket[_fun] 语法（下文描述），因为它可以处理各种复杂情况，
并可能启用静态代码生成。

结果类型可用于引用外部函数（通常是 @racket[ffi-obj]，但任何 pointer 对象都可以用此类型引用），
生成匹配的外部 @deftech{callout} 对象。这些对象是新的原始 procedure 对象，
可以像任何其他 Racket procedure 一样使用。与其他 pointer 类型一样，
@racket[#f] 被视为 @cpp{NULL} 函数指针，反之亦然。

使用 @racket[_cprocedure] 创建的类型也可用于将 Racket procedure 传递给外部函数，
这将生成一个外部函数指针，调用给定的 Racket @deftech{callback} procedure。
对 Racket procedure 的表示没有限制；特别是，该 procedure 可以有引用其环境中绑定的
自由变量。然而，callback 受运行时约束，例如在 atomic mode 下运行或不能
引发异常；请参见下面的 @elemref["callbacks"]{callback 的更多信息}。

可选的 @racket[abi] 关键字参数决定使用的外部 ABI。提供 @racket[#f] 或 @racket['default]
表示平台相关的默认值。其他可能的值——@racket['stdcall] 和 @racket['sysv]
（即 ``cdecl''）——目前仅在 32 位 Windows 上受支持；
在其他平台上使用它们会引发异常。另请参见 @racketmodname[ffi/winapi]。

可选的 @racket[varargs-after] 参数指示某些函数类型参数是否应被视为 ``varargs''，
即在 C 声明中由省略号 @litchar{...} 表示的参数
（但在 @racket[input-types] 中由显式参数表示）。@racket[#f] 值表示
C 函数类型没有 varargs。如果 @racket[varargs-after] 是一个数字，
则 @racket[input-types] 中前 @racket[varargs-after] 个参数之后的参数是 varargs。
注意，在某些平台上 @racket[#f] 与 @racket[(length input-types)] 不同；
函数可能存在 varargs 可能意味着即使对非 vararg 参数也有不同的调用约定。
还要注意，非 @racket[#f] 的 @racket[varargs-after] @emph{不}意味着你可以向
@tech{callout} 提供任意数量的参数，或使用该 procedure 类型在 @tech{callback}
中接收任意数量的参数；要处理不同的参数数量和参数类型，
请为每种组合分别使用 @racket[_cprocedure]（或 @racket[_fun]）。

对于使用生成的类型调用外部函数的 @tech{callout}：

@itemize[

 @item{如果 @racket[save-errno] 是 @racket['posix]，则在外部函数 @tech{callout}
       返回后立即保存 @as-index{@tt{errno}} 的值（特定于当前线程）。
       保存的值可以通过 @racket[saved-errno] 访问。如果 @racket[save-errno]
       是 @racket['windows]，则保存 @as-index{@tt{GetLastError}}@tt{()} 的值，
       以便后续通过 @racket[saved-errno] 使用；@racket['windows] 选项
       仅在 Windows 上可用（在其他平台上 @racket[saved-errno] 将返回 0）。
       如果 @racket[save-errno] 是 @racket[#f]，则不会自动保存错误值。

       @racket[save-errno] 提供的错误记录支持是必要的，
       因为 Racket 运行时系统可能会抢占当前 Racket thread 并自身调用设置错误值的函数。}

 @item{如果 @racket[wrapper] 不是 @racket[#f]，它接收本应生成的 @tech{callout} 并返回一个
       替代 procedure。因此，@racket[wrapper] 充当一个 hook，
       在真正的 @tech{callout} 被调用之前执行各种参数操作，
       它可以返回不同的结果（例如，获取存储在 ``output'' pointer 中的值
       并返回多值）。}

 @item{如果 @racket[lock-name] 不是 @racket[#f]，则在外部调用期间持有具有给定名称的
       进程范围锁。在支持并行 place 的构建中，@racket[lock-name]
       通过 @cpp{scheme_register_process_global} 注册，因此请选择适当区分的名称。}

 @item{如果 @racket[in-original-place?] 为真，则当使用生成的类型的
       外部 @tech{callout} procedure 在非原始 Racket place 或
       Racket @tech[#:doc reference.scrbl]{parallel thread} 中被调用时，
       该 procedure 会在原始 Racket place 的
       @elemref["unspecified thread"]{unspecified coroutine thread} 中被调用。
       对在 C 级别不是 thread-safe 的外部函数使用此模式，
       这意味着它在 Racket 级别既不是 place-safe 也不是 parallel-thread-safe。
       从非 place-safe 代码在非原始 place 回到 Racket 的 @tech{callback}
       通常不会工作，因为 Racket 代码的 place 可能具有与原始 place 不同的分配器。}

 @item{如果 @racket[blocking?] 为真，则外部 @tech{callout} 在外部调用期间
       停用对调用 OS 线程的追踪——在 Racket 变体支持的范围内。
       @racket[blocking?] 的值仅影响 Racket 的 @CS[] 实现，
       它允许在 @tech{callout} 阻塞时在其他 OS 线程中进行诸如 garbage collection
       之类的活动。由于 garbage collection 可能在外部调用期间发生，
       传递给外部调用的对象如果由 garbage collector 管理，则需要是不可移动的；
       特别是，任何 @racket[_ptr] 参数通常应指定 @racket['atomic-interior]
       分配模式。如果阻塞 @tech{callout} 可以调用任何回到 Racket 的
       @tech{callback}，则这些 @tech{callback} 必须使用非 @racket[#f]
       的 @racket[async-apply] 值构造，即使它们总是在用于运行 Racket
       的 OS 线程中被应用。}

 @item{如果 @racket[callback-exns?] 为真，则外部 @tech{callout} 允许在
       外部调用期间的 atomic @tech{callback} 引发异常，该异常会从外部调用中转义出来。
       从外部库的角度来看，异常通过 @tt{longjmp} 转义。异常转义通过捕获并
       重新引发异常的异常 handler 实现。

       引发异常的 callback 在 Racket 的 @BC[] 实现中必须是 atomic callback
       （在 @CS[] 实现中 callback 始终是 atomic 的）。在具有 @racket[async-apply]
       的 callback 中不允许引发异常，因为 callback 将在未指定的上下文中运行。
       如果导致 callback 的 callout 是用 @racket[in-original-place?] 为真创建
       并在非原始 place 中调用的，也不允许引发异常。}

 @item{提供给 @tech{callout} 的值（即底层 callout，而非 @racket[wrapper] 产生的替代品，如果有的话）
       在调用的外部函数返回之前始终被 garbage collector 视为可达。然而，
       如果外部函数调用 Racket callback，请注意由 Racket garbage collector 管理的值
       可能会在内存中被 garbage collector 移动。另外，请注意每个参数仅以提供的形式保留，
       而不是基于参数类型可能转换成的不同表示（通过 @racket[make-ctype] 的
       @racket[_racket-to-c] procedure 层）；与类型关联的转换器 procedure 可能需要
       使用 ephemeron hash table 在原始值和转换后的值之间创建引用连接。}

 @item{@tech{callout} 对象在内部被 finalize。请注意不要尝试使用仅从已 finalize 的对象
        可达的 @tech{callout} 对象，因为这两个对象的 finalize 顺序是不确定的。}

]

对于使用生成的类型回到 Racket 函数的 @elemtag["callbacks"]{@tech{callback}}：

@itemize[

@item{@racket[keep] 参数提供了对外部代码视为普通 C 函数的底层值的
      garbage collector 可达性控制。如果外部代码可能保留 callback 函数，
      则需要格外小心，因为在这种情况下 callback 值必须保持可达，
      否则持有的 callback 将变为无效。@racket[keep] 的可能值如下：

   @itemize[

    @item{@racket[#t] --- 只要转换后的 Racket 函数可达，@tech{callback} 就保留在内存中。
      此模式是默认模式，在大多数情况下都适用。请注意，每个 Racket 函数
      通过此模式只能持有一个 callback 值，因此不适用于多次用作被保留 callback 的函数。}

   @item{@racket[#f] --- @tech{callback} 值不被持有。此模式可能适用于仅在
      外部调用期间使用的 callback；例如，标准 C 库 @tt{qsort} 函数的
      比较函数参数仅在 @tt{qsort} 工作时使用，并且不会保留对比较函数的额外引用。
      仅在此类情况下使用此选项，即不需要持有时，以 避免额外开销。}

   @item{一个持有 @racket[#f] 或任何其他非 list 值的 box --- callback 值存储在 box 中，
      覆盖 box 中的任何非 list 值（这对于持有单个 callback 值很有用）。
      当你知道不再需要 callback 时，可以通过更改 box 内容或让 box 本身变得不可达
      来 ``释放'' callback 值。如果 box 被保持在对应于 callback 需要时的动态范围内，
      此模式可能很有用；例如，你可以将某些外部功能封装在 Racket class 或 unit 中，
      并将 callback box 作为新实例或 unit 实例化中的字段。}

   @item{一个持有 @racket[null]（或任何 list）的 box --- 类似于持有非 list 值的 box，
      只是新的 callback 值会被 @racket[cons] 到 box 的内容上。因此，
      此模式在 Racket 函数用于多个 callback（即发送到外部代码多次持有）
      并且所有 callback 应一起保留的情况下很有用。}

   @item{一个单参数函数 --- 在生成时用 callback 值调用该函数。此模式允许你明确管理
      生成的 callback closure 的可达性。}

   ]}

 @item{如果 @racket[wrapper] 不是 @racket[#f]，它接收要转换为 @tech{callback} 的 procedure
       并返回一个替代 procedure 作为 callback 调用。因此，@racket[wrapper] 充当一个 hook，
       在 Racket callback 函数被调用之前执行各种参数操作，并可以向外部调用者返回不同的结果。

       callback 值的可达性（及其与 @racket[keep] 的交互）基于 callback 的原始函数，
       而非 @racket[wrapper] 的结果。}

 @item{如果 @racket[atomic?] 为真，或者在使用 Racket 的 @CS[] 实现时，
       则当 Racket procedure 被赋予此类型并作为 @tech{callback}
       从外部代码调用时，Racket 进程在求值 Racket procedure body 期间
       被置于 @tech{atomic mode}。

       在 atomic mode 下，其他 Racket thread 不会运行，因此 Racket 代码不得调用
       任何可能在与其他线程同步时阻塞的函数，否则可能导致死锁。此外，
       Racket 代码不得执行任何可能阻塞的操作（如 I/O），不得引发未捕获的异常，
       除非通过支持异常的 @tech{callout}（@racket[#:callback-exns? #t]）调用，
       不得执行任何 escaping continuation 跳转，并且（至少对于 @BC[] 实现）
       其非尾递归必须最少以避免 C 级栈溢出；否则，进程可能崩溃
       或行为异常。

       在 Racket 的 @CS[] 实现中，callback 始终是 atomic 的。即使在 Racket 的
       @BC[] 实现上，atomic mode 通常也是 callback 所需要的，
       因为通过复制 C 栈的一部分进行捕获通常与 C 库不兼容。

       如果 atomic mode 下的 callback 向当前线程发送 break，
       则不仅 break 会像 @tech{atomic mode} 通常那样被延迟，
       其传递可能比从导致 callback 的外部调用返回还要延迟得更久。}

 @item{如果 @racket[async-apply] 作为 procedure 或 box 提供，则具有生成的 procedure 类型的
       Racket @tech{callback} procedure 可以在外部线程中应用
       （即除用于运行 Racket 的 OS 级线程之外的其他 OS 级线程）。

       如果 @racket[async-apply] 是一个 procedure，则在外部线程中的调用
       被转移到运行 Racket @tech[#:doc reference.scrbl]{coroutine thread} 的 OS 级线程
       和一个 @elemref["unspecified thread"]{unspecified coroutine thread}；
       提供的 @racket[async-apply] procedure 的工作是安排 callback procedure
       在合适的 Racket thread 中运行。

       给定的 @racket[async-apply] procedure 被应用于封装了特定 callback 调用的 thunk，
       外部 OS 级线程阻塞直到该 thunk 被调用并完成；该 thunk 必须恰好被调用一次，
       并且 callback 调用必须正常返回。给定的 @racket[async-apply] procedure 本身
       在 @tech{atomic mode} 中被调用。

       如果已知 callback 能快速完成，不需要同步，并且与其运行的 Racket thread 无关，
       则给定的 @racket[async-apply] procedure 可以直接应用该 thunk。
       否则，给定的 @racket[async-apply] procedure 必须安排在给定的
       @racket[async-apply] procedure 自身返回后的某个时间，在合适的 Racket thread 中应用该 thunk；
       如果 thunk 引发异常或在不适用的 Racket 级线程中同步，它可能死锁
       或以其他方式损坏 Racket 进程。

       如果 @racket[async-apply] 是一个 box，则在外部线程中调用 callback 时，
       box 中包含的值被用作 callback 的结果；@racket[async-apply] 值在调用
       @racket[_cprocedure] 时被转换为外部值。对 @racket[async-apply]
       使用 box 常量值避免了与运行 Racket 的 OS 级线程同步的需要，
       但它实际上忽略了在外部线程中应用 @tech{callback} 时被包装为
       @tech{callback} 的 Racket procedure。

       触发 @racket[async-apply] 的外部线程检测仅在 Racket 编译时启用 OS 级线程支持
       时工作，这是许多平台的默认设置。如果具有 @racket[async-apply] 的 callback
       是从与运行 Racket 相同的 OS 级线程中的外部代码调用的，则不会使用
       @racket[async-apply]。}

 @item{callback 通常不应通过引发异常或调用 continuation 来转义。atomic callback 可能会引发异常，
       但仅限于在调用使用 @racket[callback-exns?] 为真创建的 @tech{callout} 期间。
       非 atomic callback 必须永远不引发异常。}

]

@history[#:changed "6.3" @elem{Added the @racket[#:lock-name] argument.}
         #:changed "6.12.0.2" @elem{Added the @racket[#:blocking?] argument.}
         #:changed "7.9.0.16" @elem{Added the @racket[#:varargs-after] argument.}
         #:changed "8.0.0.8" @elem{Added the @racket[#:callback-exns?] argument.}]}

@defform/subs[#:literals (->> :: :)
              (_fun fun-option ... maybe-args type-spec ... ->> type-spec
                    maybe-wrapper)
              ([fun-option (code:line #:abi abi-expr)
                           (code:line #:varargs-after varargs-after-expr)
                           (code:line #:save-errno save-errno-expr)
                           (code:line #:keep keep-expr)
                           (code:line #:atomic? atomic?-expr)
                           (code:line #:async-apply async-apply-expr)
                           (code:line #:lock-name lock-name-expr)
                           (code:line #:in-original-place? in-original-place?-expr)
                           (code:line #:blocking? blocking?-expr)
                           (code:line #:callback-exns? callback-exns?-expr)
                           (code:line #:retry (retry-id [arg-id init-expr]))]
               [maybe-args code:blank
                           (code:line formals ::)]
               [type-spec type-expr
                          (id : type-expr)
                          (type-expr = value-expr)
                          (id : type-expr = value-expr)]
               [maybe-wrapper code:blank
                              (code:line ->> output-expr)])]{

创建一个新的函数类型。@racket[_fun] 形式是 @racket[_cprocedure] 类型构造函数的便捷语法，
它可以启用更多 @tech{callout} 和 @tech{callback} 代码的静态生成；
更多信息请参见 @racketmodname[ffi/unsafe/static] 中的 @static_fun。

在 @racket[_fun] 的最简单形式中，仅指定了输入的 @racket[type-expr]
和输出的 @racket[type-expr]，每个类型都是一个简单表达式，
创建一个直接的函数类型。例如，

@racketblock[
(_fun _string _int ->> _int)
]

指定一个函数，接收一个字符串和一个整数并返回一个整数。

关于 @racket[#:abi]、@racket[#:varargs-after]、@racket[#:save-errno]、
@racket[#:keep]、@racket[#:atomic?]、@racket[#:async-apply]、
@racket[#:in-original-place?]、@racket[#:blocking] 和 @racket[#:callback-exns?]
选项的信息，请参见 @racket[_cprocedure]。

在其完整形式中，@racket[_fun] 语法提供了一种类似 IDL 的语言，
当类型用于 @tech{callout} 时，在原始外部函数周围创建一个 wrapper 函数。
这些 wrapper 可以通过简单的规范实现复杂的接口：
@;
@itemlist[

 @item{每个参数 @racket[type-spec] 的完整形式可以包含一个可选的标签和一个表达式。
       标签 @racket[id :] 使得参数值可以在后续表达式中通过 @racket[id] 访问。
       @racket[= value-expr] 表达式使得 wrapper 函数使用 @racket[value-expr]
       计算该位置的参数，这意味着 wrapper 不期望被提供该位置的参数。

       例如，

       @racketblock[
        (_fun (s : _string) (_int = (string-length s)) ->> _int)
       ]

       产生一个 wrapper，接受单个字符串参数并调用一个接受字符串和整数的外部函数；
       字符串的长度作为整数参数提供。}

 @item{如果指定了可选的 @racket[output-expr]，或者为输出类型提供了一个表达式，
       则该表达式指定一个将用作函数调用返回值的表达式，替换外部函数的结果。
       @racket[output-expr] 可以使用任何先前的标签，包括为输出指定的标签
       以访问外部函数的返回值。

       例如，

       @racketblock[
        (_fun _string (len : _int) ->> (r : _int) ->> (min r len))
       ]

       产生一个 wrapper，返回外部函数结果与给定整数参数中的较小值。}

 @item{@racket[#:retry (retry-id [arg-id init-expr] ...)] 规范将 @racket[retry-id]
       绑定为在 @racket[output-expr] 中使用，用于重试外部调用（通常在尾位置）。
       绑定到 @racket[retry-id] 的函数接受每个 @racket[arg-id] 作为参数，
       每个 @racket[arg-id] 可用于 @racket[= value-expr]，
       每个 @racket[init-expr] 给出对应的 @racket[arg-id] 的初始值。

       例如，

       @racketblock[
        (_fun #:retry (again [count 0])
              _string _int ->> (r : _int)
              ->> (if (and (= r ERR_BUSY)
                           (< count 5))
                     (again (add1 count))
                     r))
       ]

       产生一个 wrapper，如果外部函数持续产生等于 @racket[ERR_BUSY] 的数字，
       则最多调用五次。}

 @item{在需要对输入参数进行完全控制的罕见情况下，wrapper 的参数列表可以指定为
       @racket[maybe-args]，带有像 @racket[lambda] 那样的 @racket[formals]
       （包括关键字参数和/或 ``rest'' 参数）。当某个参数 @racket[type-spec]
       包含与 @racket[formals] 中的绑定标识符匹配的标签时，
       该标识符用作参数的默认值。所有参数 @racket[type-spec] 必须包含
       显式的 @racket[= value-expr] 标注或通过匹配标签的隐式标注。

       例如，

       @racketblock[
         (_fun (n s) :: (s : _string) (n : _int) ->> _int)
       ]

       产生一个 wrapper，接收一个整数和一个字符串，但外部函数先接收字符串。}

]

@history[#:changed "6.2" @elem{Added the @racket[#:retry] option.}
         #:changed "6.3" @elem{Added the @racket[#:lock-name] option.}
         #:changed "6.12.0.2" @elem{Added the @racket[#:blocking?] option.}
         #:changed "7.9.0.16" @elem{Added the @racket[#:varargs-after] option.}
         #:changed "8.0.0.8" @elem{Added the @racket[#:callback-exns?] option.}]}

@defproc[(function-ptr [ptr-or-proc (or cpointer? procedure?)]
                       [fun-type ctype?])
         cpointer?]{

将 @racket[ptr-or-proc] 转换为类型为 @racket[fun-type] 的函数指针。}

@defform-arrow{

在 @racket[_fun] 形式中使用的字面量。（不幸的是，这个字面量与 @racketmodname[racket/contract]
中的 @racket[->] 同名，但它是不同的绑定。）}

@; ----------------------------------------------------------------------

@subsection[#:tag "foreign:custom-types"]{自定义函数类型}

@racket[_fun] 类型的行为可以通过 @deftech{custom function type} 自定义，
它们是可以表现为 C 类型和 C 类型构造函数的语法片段，
但可以通过多种其他方式不可能实现的方式与函数调用进行交互。
在 @racket[_fun] 形式展开时，它尝试展开每个给定的类型表达式，
展开为某些关键字-值 list 的表达式会与外部函数 wrapper 的生成进行交互。
这种展开使得构建单个 wrapper 函数成为可能，避免了高阶函数组合的成本。

custom function type 是展开为 @racket[(_key: _val ...)] 序列的 macro，
其中每个 @racket[_key:] 来自已知 key 的一个简短列表。每个 key 以不同的方式
与生成的 wrapper 函数交互，从而影响其对应参数的处理方式：

@itemize[

 @item{@racket[type:] 指定应使用的外部类型，如果是 @racket[#f] 则该参数不参与外部调用。}

 @item{@racket[expr:] 指定用于此类型参数的表达式，将其从 wrapper 参数中移除。}

 @item{@racket[bind:] 指定一个名称，如果稍后需要原始参数，则将其绑定到原始参数
   （例如，@racket[_box] 将其关联值转换为 C pointer，稍后需要引用回原始 box）。}

 @item{@racket[1st-arg:] 指定一个可用于引用外部调用第一个参数的名称
   （适用于第一个参数具有特殊含义的常见情况，例如方法调用）。}

 @item{@racket[prev-arg:] 类似于 @racket[1st-arg:]，但引用前一个参数。}

 @item{@racket[pre:] 一个预外部代码块，用于更改参数的值。}

 @item{@racket[post:] 类似的 post-foreign 代码块。}

 @item{@racket[keywords:] 指定将与周围的 @racket[_fun] 形式一起使用的 keyword/value 表达式。
   （注意：keyword/value 序列跟在 @racket[keywords:] 之后，不加括号。）}
]

@racket[pre:] 和 @racket[post:] 绑定可以采用 @racket[(_id => _expr)] 的形式
以使用现有值。注意，如果 @racket[pre:] 表达式不是 @racket[(_id => _expr)]，
则意味着对于 @racket[_fun] 生成的 procedure，此参数没有输入。
还要注意，如果 custom type 用作函数的输出类型，则仅使用 @racket[post:] 代码。

大多数 custom type 仅在 @racket[_fun] 上下文中有意义，如果在其他地方使用会引发语法错误。
有少数这样的类型可以在非 @racket[_fun] 上下文中使用：仅使用 @racket[type:]、
@racket[pre:]、@racket[post:] 而不使用其他关键字的类型。
这种 custom type 可以通过展开为 @racket[make-ctype] 的使用在 @racket[_fun] 之外使用，
使用其他关键字则不可能做到，因为这意味着该类型与函数调用有特定的交互。


@defform[(define-fun-syntax id transformer-expr)]{

将 @racket[id] 绑定为 @tech{custom function type} 以及 syntax transformer（即 macro）。
该类型通过将 @racket[transformer-expr] 产生的 procedure 应用于 @tech{custom function type}
的使用来展开。

例如，以下定义了一个新类型，自动将输入数字强制转换为与 @racket[_float] 类型兼容的 inexact 形式。

@racketblock[
(define-fun-syntax _float*
  (syntax-id-rules (_float*)
    [_float* (type: _float pre: (x => (+ 0.0 x)))]))

(_fun _float* ->> _bool)]}

@defidform[_?]{

一个 @tech{custom function type}，作为不应发送到外部函数的表达式的标记。
使用它来在属于 FFI wrapper 接口的计算中绑定局部值，或指定不发送到外部函数的
wrapper 参数（例如，用于处理外部输出的参数）。

示例：

@racketblock[
(_fun _? (code:comment "not sent to foreign function")
      _int -> _int)
(_fun [init : _?] (code:comment "init is used for pre-processing")
      [boxed : (_box _int) = (box init)]
      -> _void)
(_fun [offset : _?] (code:comment "offset is used for post-processing")
      -> [res : _int]
      -> (+ res offset))
]
}


@defform/subs[#:literals (i o io
                          atomic raw atomic nonatomic tagged
                          atomic-interior interior
                          zeroed-atomic zeroed-atomic-interior
                          stubborn uncollectable eternal)
              (_ptr mode type-expr maybe-malloc-mode)
              ([mode i o io]
               [maybe-malloc-mode (code:line) #f raw atomic nonatomic tagged
                                  atomic-interior interior
                                  zeroed-atomic zeroed-atomic-interior
                                  stubborn uncollectable eternal])]{

创建一个 C pointer 类型，其中 @racket[mode] 指示输入指针或输出指针（或两者）。
@racket[mode] 可以是以下之一（作为独立于绑定的 symbol 匹配）：

@itemize[

 @item{@racket[i] --- 表示@italic{输入}指针参数：wrapper 安排函数调用接收一个可与 @racket[type]
  一起使用的值，并向外部函数发送指向此值的指针。调用后，该值被丢弃。}

 @item{@racket[o] --- 表示@italic{输出}指针参数：外部函数期望一个指向某个位置的指针，
  它将在该位置保存某个值，调用后该值可访问，由额外的返回表达式使用。
  如果 @racket[_ptr] 以此模式使用，则生成的 wrapper 不期望参数，
  因为在调用之前将新分配一个。}

 @item{@racket[io] --- 将上述两者组合为@italic{输入/输出}指针参数：wrapper 获取 Racket 值，
  分配并使用此值设置指针，然后在调用后引用该值。``@racket[_ptr]'' 名称在这里
  可能容易混淆：它意味着外部函数期望一个指针，但生成的 wrapper 使用实际值。
  （注意，如果与 struct 一起使用，在调用函数时会创建一个 struct，
  并且返回值也会创建一个副本——这样效率不高，但确保了 struct 不会被 C 代码修改。）}

]

例如，@racket[_ptr] 类型可以在输出模式下使用，创建一个返回多个参数的外部函数 wrapper。
以下类型：

@racketblock[
(_fun (i : (_ptr o _int))
      ->> (d : _double)
      ->> (values d i))
]

创建一个函数，使用一个新的整数指针调用外部函数，并将放置在那里的值用作第二个返回值。

如果未指定 @racket[maybe-malloc-mode] 或者为 @racket[#f]，则 @racket[_ptr] 创建的指针参数
使用 @racket[(malloc type-expr)] 分配，否则使用
@racket[(malloc type-expr '@#,racket[maybe-malloc-mode])] 分配。

@history[#:changed "7.7.0.6" @elem{The modes @racket[i], @racket[o],
                                   and @racket[io] match as symbols
                                   instead of free identifiers.}
         #:changed "8.0.0.13" @elem{Added @racket[maybe-malloc-mode].}
         #:changed "8.14.0.4" @elem{Added the @racket[zeroed-atomic] and
                                    @racket[zeroed-atomic-interior] allocation modes.}]}


@defform[(_box type maybe-malloc-mode)]{

一个 @tech{custom function type}，类似于 @racket[(_ptr io _type)] 参数，
其中输入期望是一个持有适当值的 box，在入口时 unbox，在出口时相应修改。
可选的 @racket[maybe-malloc-mode] 与 @racket[_ptr] 相同。

示例：

@racketblock[
(_fun (_box _int) -> _void)
(_fun [boxed : (_box _int) = (box 0)]
      -> [res : _int]
      -> (values res (unbox boxed)))
]}

@defform/subs[#:literals (atomic raw atomic nonatomic tagged
                          atomic-interior interior
                          zeroed-atomic zeroed-atomic-interior
                          stubborn uncollectable eternal)
              (_list mode type maybe-len maybe-mode)
              ([mode i o io]
               [maybe-len code:blank
                          len-expr]
               [maybe-mode code:blank
                           atomic
                           raw atomic nonatomic tagged
                           atomic-interior interior
                           zeroed-atomic zeroed-atomic-interior
                           stubborn uncollectable eternal])]{

一个 @tech{custom function type}，类似于 @racket[_ptr]，但用于在 list 和 C vector
之间进行转换。可选的 @racket[maybe-len] 参数对于在 post 代码中使用的输出值
以及输出模式的 pre 代码中用于分配块来说是必需的。
（如果长度为 0，则传入 NULL 并返回空 list。）
无论哪种情况，它都可以引用 C 函数最可能需要的 list 长度的先前绑定。
如果提供 @racket[maybe-mode]，则会被 quote 并传递给 @racket[malloc]
以分配 C 表示。

例如，以下类型对应于一个函数，该函数接受类型为 @tt{*float} 的 vector 参数
（来自 Racket list 输入）和一个类型为 @tt{int} 的 vector 长度参数：

@racketblock[
(_fun [vec : (_list i _float)]
      (code:comment "this argument is implicitly provided")
      [_int = (length vec)]
      -> _void)
]

在下一个示例中，该类型指定了一个函数，通过给定的输出 vector
（在 Racket 端表示为 list）和布尔返回值提供输出。FFI 绑定的
函数将接受一个整数参数并返回两个值，vector 和布尔值。

@racketblock[
(_fun [len : _int]
      [vec : (_list o _float len)]
      -> [res : _bool]
      -> (values vec res))
]

@history[#:changed "7.7.0.2" @elem{Added @racket[maybe-mode].}
         #:changed "7.7.0.6" @elem{The modes @racket[i], @racket[o],
                                   and @racket[io] match as symbols
                                   instead of free identifiers.}
         #:changed "8.14.0.4" @elem{Added the @racket[zeroed-atomic]
                                    @racket[zeroed-atomic-interior] allocation modes.}]}

@defform[(_vector mode type maybe-len maybe-mode)]{

一个 @tech{custom function type}，类似于 @racket[_list]，但使用 Racket vector 而非 list。

示例：

@racketblock[
(_fun [vec : (_vector i _float)]
      [_int = (length vec)]
      -> _void)
(_fun [len : _int]
      [vec : (_vector o _float len)]
      -> [res : _bool]
      -> (values vec res))
]

关于示例的更多说明，请参见 @racket[_list]。

@history[#:changed "7.7.0.2" @elem{Added @racket[maybe-mode].}
         #:changed "7.7.0.6" @elem{The modes @racket[i], @racket[o],
                                   and @racket[io] match as symbols
                                   instead of free identifiers.}]}


@defform*[#:id _bytes
          #:literals (o)
          [_bytes
           (_bytes o len-expr)]]{

@racket[_bytes] 形式本身对应于 C 的 @cpp{char*} 类型；字节字符串作为 @racket[_bytes] 传递而不进行任何复制。
请注意，Racket 字节字符串不一定是 nul 终止的；另请参见 @racket[_bytes/nul-terminated]。

在 Racket 的 @BC[] 实现中，C 非 NULL 结果值被转换为 Racket 字节字符串而不进行复制；
该指针被视为可能由 garbage collector 管理（注意事项见 @racket[_gcpointer]）。
在 Racket 的 @CS[] 实现中，转换需要复制以将 C @cpp{char*} 结果
表示为 Racket 字节字符串，并且原始指针@emph{不}被视为由 garbage collector 管理。
在这两种情况下，C 结果必须具有 nul 终止符以确定 Racket 字节字符串的长度。

@racket[(_bytes o len-expr)] 形式是一个 @tech{custom function type}。
作为参数，字节字符串使用给定长度分配；在 @BC[] 实现中，
该字节字符串包含一个额外的字节用于 nul 终止符，
并且 @racket[(_bytes o len-expr)] 作为结果类型将 C 非 NULL @cpp{char*} 指针包装为
给定长度的字节字符串。对于 @CS[] 实现，分配的参数不包括
nul 终止符，并且会为结果字符串创建一个副本。

与通常一样，@racket[_bytes] 将 @racket[#f] 视为 @cpp{NULL}，反之亦然。
作为结果类型，@racket[(_bytes o len-expr)] 仅适用于非 NULL 结果。}


@defform*[#:id _bytes/nul-terminated
          #:literals (o)
          [_bytes/nul-terminated
           (_bytes/nul-terminated o len-expr)]]{

@racket[_bytes/nul-terminated] 类型类似于 @racket[_bytes]，但会显式地向
字节字符串参数添加一个 nul 终止字节，这意味着需要复制。作为结果类型，
@cpp{char*} 被复制到一个新的字节字符串（不包含显式的 nul 终止符）。

当 @racket[(_bytes/nul-terminated o len-expr)] 用作参数类型时，
会分配一个长度为 @racket[len-expr] 的字节字符串。类似地，
当 @racket[(_bytes/nul-terminated o len-expr)] 用作结果类型时，
@cpp{char*} 结果被复制到一个长度为 @racket[len-expr] 的新字节字符串中。

与通常一样，@racket[_bytes/nul-terminated] 将 @racket[#f] 视为 @cpp{NULL}，反之亦然。
作为结果类型，@racket[(_bytes/nul-terminated o len-expr)] 仅适用于非 NULL 结果。

@history[#:added "6.12.0.2"]}


@; ------------------------------------------------------------

@section{C 结构体类型}

@defproc[(make-cstruct-type [types (non-empty-listof ctype?)]
                            [abi (or/c #f 'default 'stdcall 'sysv) #f]
                            [alignment (or/c #f 1 2 4 8 16) #f]
                            [malloc-mode (or/c 'raw 'atomic 'nonatomic 'tagged
                                               'atomic-interior 'interior
                                               'zeroed-atomic 'zeroed-atomic-interior
                                               'stubborn 'uncollectable 'eternal)
                                         'atomic])
         ctype?]{

创建新 C struct 类型的原始类型构造函数。这些类型实际上是新的原始类型；
没有关联的转换函数。用于 struct 的相应 Racket 对象是 pointer，
但当这些类型被使用时，使用的是指针@italic{所指}的值，而非指针本身。
该值基本上由根据给定 @racket[types] list 已知的一定数量的字节组成。

如果 @racket[alignment] 是 @racket[#f]，则使用 @racket[types] 中每个类型的
自然对齐作为其在 struct 类型内的对齐。否则，@racket[alignment]
用于所有 struct 类型成员。

当分配类型的实例以表示函数调用的结果时，使用 @racket[malloc-mode] 参数。
此分配模式@emph{不}用于 @tech{callback} 的参数，
因为在这种情况下使用的是 C 栈上分配的临时空间（可能由调用约定分配）。

@history[#:changed "7.3.0.8" @elem{Added the @racket[malloc-mode] argument.}
         #:changed "8.14.0.4" @elem{Added the @racket['zeroed-atomic]
                                    @racket['zeroed-atomic-interior] allocation modes.}]}


@defproc[(_list-struct [#:alignment alignment (or/c #f 1 2 4 8 16) #f] 
                       [#:malloc-mode malloc-mode
                                      (or/c 'raw 'atomic 'nonatomic 'tagged
                                            'atomic-interior 'interior
                                            'zeroed-atomic 'zeroed-atomic-interior
                                            'stubborn 'uncollectable 'eternal)
                                      'atomic]
                       [type ctype?] ...+)
         ctype?]{

一个类型构造函数，使用 @racket[make-cstruct-type] 函数构建 struct 类型，
并将其包装在一个将 struct 编排为其组件 list 的类型中。
注意，struct 的空间必须使用 @racket[malloc] 和 @racket[malloc-mode] 分配；
@racket[_list-struct] 类型的转换器会立即从分配的空间中分配并使用一个 list，
因此效率不高。请使用下面的 @racket[define-cstruct] 获得更高效的方法。

@history[#:changed "6.0.0.6" @elem{Added @racket[#:malloc-mode].}]
         #:changed "8.14.0.4" @elem{Added the @racket['zeroed-atomic]
                                    @racket['zeroed-atomic-interior] allocation modes.}}


@defform[(define-cstruct id/sup ([field-id type-expr field-option ...] ...)
           property ...)
         #:grammar [(id/sup _id
                            (_id _super-id))
                    (field-option (code:line #:offset offset-expr))
                    (property (code:line #:alignment alignment-expr)
                              (code:line #:malloc-mode malloc-mode-expr)
                              (code:line #:property prop-expr val-expr)
                              #:no-equal
                              #:define-unsafe)]
         #:contracts ([offset-expr exact-integer?]
                      [alignment-expr (or/c #f 1 2 4 8 16)]
                      [malloc-mode-expr (or/c 'raw 'atomic 'nonatomic 'tagged
                                              'atomic-interior 'interior
                                              'zeroed-atomic 'zeroed-atomic-interior
                                              'stubborn 'uncollectable 'eternal)]
                      [prop-expr struct-type-property?])]{

定义一个新的 C struct 类型，但与 @racket[_list-struct] 不同，
结果类型以二进制形式处理 C struct，而非将其编排为 Racket 值。
语法类似于 @racket[define-struct]，为原始 struct 值（即 pointer 对象）提供访问器函数；
@racket[_id] 必须以 @litchar{_} 开头，每个 field 最多可以提供一个
@racket[#:offset]，并且最多可以提供一个 @racket[#:alignment]
或 @racket[#:malloc-mode]。如果不提供 @racket[_super-id]，
则必须指定至少一个 field。

生成的绑定如下：

@itemize[

 @item{@racket[_id]：此 struct 的新 C 类型。}

 @item{@racket[_id]@racketidfont{-pointer}：当使用指向此 struct 值的指针时应使用的 pointer 类型。}

 @item{@racket[_id]@racketidfont{-pointer/null}：类似于 @racket[_id]@racketidfont{-pointer}，
  但允许 NULL 指针（在 Racket 端由 @racket[#f] 表示）。}

 @item{@racketvarfont{id}@racketidfont{?}：新类型的谓词。}

 @item{@racketvarfont{id}@racketidfont{-tag}：与实例一起使用的 tag 对象。tag 对象可以是
  @racketvarfont{id} 的 symbol 形式，或包含 @racketvarfont{id} symbol 和其他 symbol
  （如 @racketvarfont{super-id} symbol）的 symbol list。}

 @item{@racketidfont{make-}@racketvarfont{id}：一个构造函数，期望每个 field 一个参数。}

 @item{@racketvarfont{id}@racketidfont{-}@racket[field-id]：每个 @racket[field-id] 的访问器函数；
  如果 field 具有 C struct 类型，则访问器的结果是
  指向封闭结构中该 field 的指针，而非该 field 的副本。}

 @item{@racketidfont{set-}@racketvarfont{id}@racketidfont{-}@racket[field-id]@racketidfont{!}
  ：每个 @racket[field-id] 的修改器函数。}

 @item{@racketvarfont{id}@racketidfont{-}@racket[field-id]@racketidfont{-offset}
  ：每个 @racket[field-id] 的绝对偏移量（以字节为单位），如果存在 @racket[#:define-unsafe] 的话。}

 @item{@racketidfont{unsafe-}@racketvarfont{id}@racketidfont{-}@racket[field-id]
  ：每个 @racket[field-id] 的 unsafe 访问器函数，如果存在 @racket[#:define-unsafe] 的话。}

 @item{@racketidfont{unsafe-set-}@racketvarfont{id}@racketidfont{-}@racket[field-id]@racketidfont{!}
  ：每个 @racket[field-id] 的 unsafe 修改器函数，如果存在 @racket[#:define-unsafe] 的话。}

@item{@racketvarfont{id}：与 @racket[struct-out] 或 @racket[match] 兼容的 structure-type 信息
  （但不兼容 @racket[struct] 或 @racket[define-struct]）；
  目前，只有在没有指定 @racket[super-id] 时此信息才是正确的。}

 @item{@racketvarfont{id}@racketidfont{->list}、@racketidfont{list->}@racketvarfont{id}：
  将 struct 转换为 field 值 list 及反向转换的函数。}

 @item{@racketvarfont{id}@racketidfont{->list*}、@racketidfont{list*->}@racketvarfont{id}：类似于
  @racketvarfont{id}@racketidfont{->list}、@racketidfont{list->}@racketvarfont{id}，
  但 struct 类型的 field 会递归地展开为 list 或从 list 打包。}

 @item{@racketidfont{struct:cpointer:}@racketvarfont{id}：
  仅当指定了 @racket[#:property] 时——对应于反映属性的 wrapper 的结构类型（见下文）。}

 @item{@racketidfont{make-wrap-}@racketvarfont{id}：仅当指定了 @racket[#:property] 时——
  一个接受 cpointer 并返回持有该 cpointer 的 wrapper 结构的函数。}

]

新类型的对象实际上是 C pointer，带有作为 @racketvarfont{id} 的 symbol 形式
或包含 @racketvarfont{id} 的 symbol 形式的 list 的类型标签。
由于 struct 被实现为 pointer，它们可以用作外部函数的 @racket[_pointer] 输入：
将使用它们的地址。为了使其更安全一些，相应的 cpointer 类型定义为
@racket[_id]@racketidfont{-pointer}。当期望指针时不应使用 @racket[_id] 类型，
因为这会导致 struct 被复制而非使用指针值，从而导致内存损坏。

结构内的 field 偏移通常自动计算，但可以使用 @racket[#:offset] 指定 field 的偏移量。
为某个 field 指定 @racket[#:offset] 会影响所有剩余 field 的默认偏移量计算。

新类型的实例通常不是 Racket 结构实例。然而，如果指定了至少一个 @racket[#:property] 修饰符，
则 struct 创建和从 @racket[_id] 变体的强制转换会将非 NULL C pointer 表示包装在
具有指定属性的 Racket 结构中。wrapper Racket 结构还具有 @racket[prop:cpointer] 属性，
因此包装的 C pointer 可以与未包装的 C pointer 一样处理。如果需要 @racket[super-id]
并且它对应于具有 wrapper 结构类型的 C struct 类型，则 wrapper 结构类型是
@racket[super-id] 的 wrapper 结构类型的子类型。如果指定了 @racket[#:property] 修饰符，
未指定 @racket[#:no-equal]，并且 @racket[prop:equal+hash] 未被指定为任何
@racket[#:property]，则 wrapper 结构类型会自动实现
@racket[prop:equal+hash] 属性以使用 @racket[ptr-equal?]。

如果第一个 field 本身是 C struct 类型，则其标签将与新标签一起使用。
此功能支持对象继承的常见情况，其中子 struct 通过将第一个 field 作为其
父 struct 来创建。子 struct 的实例可以被视为父 struct 的实例，
因为它们共享相同的初始布局。使用初始 C struct field 的标签意味着
在 Racket 中实现了相同的行为；例如，父 struct 的访问器和修改器可以用于新的子 struct。
参见下面的示例。

提供 @racket[super-id] 是使用名为 @racket[super-id] 的初始 field 并
以 @racketidfont{_}@racket[super-id] 作为其类型的简写。因此，新 struct 将使用
@racketidfont{_}@racket[super-id] 的标签以及自己的标签，
这意味着 @racket[_id] 的实例可以用作 @racketidfont{_}@racket[super-id] 的实例。
除了语法糖之外，使用此语法时构造函数也不同：
构造函数不会期望第一个参数是 @racketidfont{_}@racket[super-id] 的实例，
而是期望 @racketidfont{_}@racket[super-id] 的每个 field 的参数，
以及新 field 的参数。构造函数的这种调整再次类似于在 @racket[define-struct] 中使用超类型。

Struct 使用 @racket[malloc] 分配，使用 @racket[malloc-mode-expr] 的结果，
默认为 @racket['atomic]。（此分配模式不适用于 @tech{callback} 的参数；
另请参见 @racket[define-cstruct-type]。）
默认的 @racket['atomic] 分配意味着 garbage collector 会忽略 struct 的内容；
因此，struct field 只能持有非指针值、指向 GC 控制之外的内存的指针，
以及指向不可移动的 GC 管理值的其他可达指针
（如通过 @racket[malloc] 和 @racket['internal] 或 @racket['internal-atomic] 分配的值）。

作为示例，考虑以下 C 代码：

@verbatim[#:indent 2]{
 typedef struct { int x; char y; } A;
 typedef struct { A a; int z; } B;

 A* makeA() {
   A *p = malloc(sizeof(A));
   p->x = 1;
   p->y = 2;
   return p;
 }

 B* makeB() {
   B *p = malloc(sizeof(B));
   p->a.x = 1;
   p->a.y = 2;
   p->z   = 3;
   return p;
 }

 char gety(A* a) {
   return a->y;
 }
}

使用简单的 @racket[_list-struct]，你可能会期望以下代码可以工作：

@racketblock[
(define makeB
  (get-ffi-obj 'makeB "foo.so"
    (_fun ->> (_list-struct (_list-struct _int _byte) _int))))
(makeB) (code:comment @#,t{should return @racket['((1 2) 3)]})
]

这里的问题是 @cpp{makeB} 返回的是指向 struct 的指针，而非 struct 本身。
以下代码按预期工作：

@racketblock[
(define makeB
  (get-ffi-obj 'makeB "foo.so" (_fun ->> _pointer)))
(ptr-ref (makeB) (_list-struct (_list-struct _int _byte) _int))
]

如上所述，@racket[_list-struct] 应在效率不成问题的情况下使用。
我们继续使用 @racket[define-cstruct]，首先为 @cpp{A} 定义一个类型，使其可以使用 @cpp{makeA}：

@racketblock[
(define-cstruct #,(racketidfont "_A") ([x _int] [y _byte]))
(define makeA
  (get-ffi-obj 'makeA "foo.so"
    (_fun ->> #,(racketidfont "_A-pointer")))) (code:comment @#,t{using @racketidfont{_A} is a memory-corrupting bug!})
(define a (makeA))
(list a (A-x a) (A-y a))
(code:comment @#,t{produces an @racket[A] containing @racket[1] and @racket[2]})
]

使用 @cpp{gety} 也很简单：

@racketblock[
(define gety
  (get-ffi-obj 'gety "foo.so"
    (_fun #,(racketidfont "_A-pointer") ->> _byte)))
(gety a) (code:comment @#,t{produces @racket[2]})
]

现在我们为 @cpp{B} 定义另一个 C struct，并使用它暴露 @cpp{makeB}：

@racketblock[
(define-cstruct #,(racketidfont "_B") ([a #,(racketidfont "_A")] [z _int]))
(define makeB
  (get-ffi-obj 'makeB "foo.so"
    (_fun ->> #,(racketidfont "_B-pointer"))))
(define b (makeB))
]

我们可以用简单的方法访问 @racket[b] 的所有值：

@racketblock[
(list (A-x (B-a b)) (A-y (B-a b)) (B-z b))
]

但这效率不高，因为每次访问都会分配并复制 @cpp{A} 的实例。
检查标签 @racket[(cpointer-tag b)] 我们可以看到包含了 @cpp{A} 的标签，
因此我们可以直接使用其访问器和修改器，以及任何定义为接受 @cpp{A} 指针的函数：

@racketblock[
(list (A-x b) (A-y b) (B-z b))
(gety b)
]

在 Racket 中构造 @cpp{B} 实例需要分配一个临时的 @cpp{A} struct：

@racketblock[
(define b (make-B (make-A 1 2) 3))
]

为了使其更高效，我们切换到另一种 @racket[define-cstruct] 语法，
它创建的构造函数期望同时接受父 field 和新 field 的参数：

@racketblock[
 (define-cstruct (#,(racketidfont "_B") #,(racketidfont "_A")) ([z _int]))
 (define b (make-B 1 2 3))
]

@history[#:changed "6.0.0.6" @elem{Added @racket[#:malloc-mode].}
#:changed "6.1.1.8" @elem{Added @racket[#:offset] for fields.}
#:changed "6.3.0.13" @elem{Added @racket[#:define-unsafe].}
#:changed "8.14.0.4" @elem{Added the @racket['zeroed-atomic]
                           @racket['zeroed-atomic-interior] allocation modes.}]}

@defproc[(compute-offsets [types (listof ctype?)]
                          [alignment (or/c #f 1 2 4 8 16) #f]
                          [declare (listof (or/c #f exact-integer?)) '()])
         (listof exact-integer?)]{
                                  
 给定 C struct 类型中的类型列表，返回这些类型的偏移量。

 @racket[types] list 描述了一个 C struct 类型，与 @racket[make-cstruct-type] 中的 list 相同。

 C struct 的对齐通过 @racket[alignment] 设置。行为与 @racket[make-cstruct-type] 相同。

 显式位置可以通过 @racket[declare] 设置。如果提供，它是与 @racket[types]
 长度相同的 list。在每个索引处，如果提供了一个数字，则该类型位于该偏移量处。
 否则，类型位于该偏移量之后 @racket[alignment] 字节处。

 @examples[#:eval ffi-eval
           (compute-offsets (list _int _bool _short))
           (compute-offsets (list _int _bool _short) 1)
           (compute-offsets (list _int _int _int) #f (list #f 5 #f))]

 @history[#:added "6.10.1.2"]}

@; ------------------------------------------------------------

@section{C 数组类型}

@defproc[(make-array-type [type ctype?]
                          [count exact-nonnegative-integer?])
         ctype?]{

创建新 C array 类型的原始类型构造函数。与 C struct 类型一样，
array 类型是没有关联转换函数的新的原始类型。当用作函数参数或返回类型时，
array 类型的行为类似 pointer 类型；否则，array 类型的行为类似 struct 类型
（即与 array 具有相同数量元素的 struct），特别是在用于 struct 类型内的 field 时。

由于 array 被视为 struct，将 pointer 类型 @racket[cast] 为 array 类型不起作用。
相反，使用 @racket[ptr-ref] 配合 pointer、用 @racket[_array] 构造的 array 类型
和索引 @racket[0] 将 pointer 转换为可与 @racket[array-ref] 和
@racket[array-set!] 配合使用的 Racket 表示。}


@defproc[(_array [type ctype?] [count exact-nonnegative-integer?] ...+)
         ctype?]{

创建一个 array 类型，其 Racket 表示是一个可与 @racket[array-ref] 和 @racket[array-set!]
配合使用的 array。array 不会被复制；Racket 表示由底层 C 表示支持。

对多维 array 提供多个 @racket[count]。由于 C 使用行优先顺序排列 array，
@racket[(_array _t _n _m)] 等价于 @racket[(_array (_array _t _m) _n)]，
这与指向 array 的指针的 array 不同。

当值用作 array 类型的实例时（例如传递到外部函数），检查确保给定的值是一个
长度至少为预期的 array，并且其元素根据 @racket[ctype->layout] 具有相同的表示；
array 可以具有额外的元素，并且可以具有不同的元素类型，
只要该类型与预期类型的布局匹配即可。}


@defproc[(array? [v any/c]) boolean?]{

如果 @racket[v] 是通过 @racket[_array] 的 C 值的 Racket 表示，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(array-ref [a array?] [i exact-nonnegative-integer?] ...+)
         any/c]{

从 array 中提取元素。对多维 array 访问使用多个 @racket[i] 索引；
使用少于 array 维数的索引会产生子 array。}


@defproc[(array-set! [a array?] 
                     [i exact-nonnegative-integer?] ...+
                     [v any/c])
         void?]{

设置 array 中的元素。对多维 array 更新使用多个 @racket[i] 索引；
使用少于 array 维数的索引会设置子 array（即 @racket[v] 必须是与子 array
大小相同的 array，并且 @racket[v] 被复制到子 array 中）。}


@defproc[(array-ptr [a array?]) cpointer?]{

提取 array 存储的指针。}


@defproc[(array-length [a array?]) exact-nonnegative-integer?]{

提取 array 的长度。对于多维 array，结果仍然是一个数字；
提取一个元素以获取子 array 从而获得下一维的长度，以此类推。}

@defproc[(array-type [a array?]) ctype?]{

提取 array 的类型。对于多维 array，结果是嵌套 array 的 ctype。}

@defproc[(in-array [a array?]
                  [start exact-nonnegative-integer? 0]
                  [stop (or/c exact-integer? #f) #f]
                  [step (and/c exact-integer? (not/c zero?)) 1])
         sequence?]{
  当不提供可选参数时，返回等价于 @racket[a] 的 sequence。

  可选参数 @racket[start]、@racket[stop] 和 @racket[step] 与 @racket[in-vector] 中的相同。}

@defproc[(_array/list [type ctype?] [count exact-nonnegative-integer?] ...+)
         ctype?]{

类似于 @racket[_array]，但 Racket 表示是元素的 list（或对多维 array 是 list 的 list），
在底层 C array 之间进行复制。}


@defproc[(_array/vector [type ctype?] [count exact-nonnegative-integer?] ...+)
         ctype?]{

类似于 @racket[_array]，但 Racket 表示是元素的 vector（或对多维 array 是 vector 的 vector），
在底层 C array 之间进行复制。}


@; ------------------------------------------------------------

@section{C 联合体类型}

@defproc[(make-union-type [type ctype?] ...+)
         ctype?]{

创建新 C union 类型的原始类型构造函数。与 C struct 类型一样，
union 类型是没有关联转换函数的新的原始类型。Unions 始终被视为使用
@racket['atomic] 分配模式的 struct。

@examples[#:eval ffi-eval
(make-union-type (_list-struct _int _int)
                 (_list-struct _double _double))
]}


@defproc[(_union [type ctype?] ...+)
         ctype?]{

创建一个 union 类型，其 Racket 表示是一个可与 @racket[union-ref] 和 @racket[union-set!]
配合使用的 union。union 不会被复制；Racket 表示由底层 C 表示支持。

@examples[#:eval ffi-eval
(_union (_list-struct _int _int)
        (_list-struct _double _double))
]}


@defproc[(union? [v any/c]) boolean?]{

如果 @racket[v] 是通过 @racket[_union] 的 C 值的 Racket 表示，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval ffi-eval
(define a-union-type
  (_union (_list-struct _int _int)
          (_list-struct _double _double)))
(define a-union-val
  (cast (list 3.14 2.71)
        (_list-struct _double _double)
        a-union-type))
(union? a-union-val)
(union? 3)
]}


@defproc[(union-ref [u union?] [i exact-nonnegative-integer?])
         any/c]{

从 union 中提取一个 variant。variant 的索引从 @racket[0] 开始。

@examples[#:eval ffi-eval
(code:comment "see examples for union? for definitions")
(union-ref a-union-val 1)
]}


@defproc[(union-set! [u union?] 
                     [i exact-nonnegative-integer?]
                     [v any/c])
         void?]{

设置 union 中的 variant。

@examples[#:eval ffi-eval
(code:comment "see examples for union? for definitions")
(union-set! a-union-val 0 (list 4 5))
a-union-val
(union-ref a-union-val 0)
]}


@defproc[(union-ptr [u union?]) cpointer?]{

提取 union 存储的指针。

@examples[#:eval ffi-eval
(union-ptr a-union-val)
]}


@; ------------------------------------------------------------

@section{枚举与位掩码}

虽然下面的构造函数被描述为 procedure，但它们以语法形式实现，
以便错误消息可以在语法上下文暗示时报告类型名称。

@defproc[(_enum [symbols list?]
                [basetype ctype? _ufixint]
                [#:unknown unknown any/c (lambda (x) (error ....))])
         ctype?]{

接受一个 symbol list 并生成一个枚举类型。枚举在给定 @racket[symbols] list 中的 symbol
与从 @racket[0] 开始计数的相应整数之间映射。

要调用以 enum 作为参数的外部函数，只需提供所需 enum 的 symbol 作为参数。

@racketblock[
 (code:comment "example sdl call")
 (sdl-create-window "title" ... 'SDL_WINDOW_OPENGL)]

list @racket[symbols] 也可以通过在每个 symbol 后面放置 @racket['=] 和 exact integer
来设置 symbol 的值。例如，list @racket['(x y = 10 z)] 将 @racket['x] 映射为
@racket[0]，@racket['y] 映射为 @racket[10]，@racket['z] 映射为 @racket[11]。

@racket[basetype] 参数指定要使用的基础类型。

@racket[unknown] 参数指定从外部端转换未知整数的结果：它可以是一个单参数函数，
应用于该整数，或者是一个返回的值。默认为抛出异常。

@examples[#:eval ffi-eval
  (code:comment "example from snappy-c.h")
  (define @#,racketidfont{_snappy_status}
    (_enum '(ok = 0
             invalid_input
             buffer_too_small)))
]

注意，默认的 basetype 是 @racket[_ufixint]。这与可以使用 @racket[_fixint] 中
任何值的 C 枚举不同。任何使用负值的 @racket[_enum] 应使用 @racket[_fixint] 作为基础类型。

@examples[#:eval ffi-eval
  (define @#,racketidfont{_negative_enum}
    (_enum '(unkown = -1
             error = 0
             ok = 1)
           _fixint))]}

@defproc[(_bitmask [symbols (or symbol? list?)] [basetype ctype? _uint])
         ctype?]{

类似于 @racket[_enum]，但结果映射使用 @racket[bitwise-ior] 对各个 symbol 的值
进行按位或运算，将 symbol list 转换为数字并反向转换，
单个 symbol 等价于仅包含该 symbol 的 list。

换句话说，要调用使用位掩码参数的外部函数，只需使用所需标志的 list 调用 procedure。

@racketblock[
 (code:comment "example call from curl_global_init in curl.h")
 (curl-global-init '(CURL_GLOBAL_SSL CURL_GLOBAL_WIN32))]


当 symbol 没有给定值（即在 @racket[symbols] 中的 symbol 后没有 @racket['=]），
其值是比前一个 symbol 的赋值大的下一个 2 的幂（对第一个 symbol 则为 @racket[1]）。

默认的 @racket[basetype] 是 @racket[_uint]，因为高位常用于标志。

@examples[#:eval ffi-eval
  (code:comment "example from curl.h")
  (define @#,racketidfont{_curl_global_flag}
    (_bitmask `(CURL_GLOBAL_SSL = 1
                CURL_GLOBAL_WIN32 = 2
                CURL_GLOBAL_ALL = 3
                CURL_GLOBAL_NOTHING = 0
                CURL_GLOBAL_DEFAULT = 3
                CURL_GLOBAL_ACK_EINTR = 4)))
  (code:comment "example from XOrg")
  (define @#,racketidfont{_Modifiers}
    (_bitmask '(ShiftMask = #b0000000000001
                LockMask = #b0000000000010
                ControlMask = #b0000000000100
                Mod1Mask = #b0000000001000
                Mod2Mask = #b0000000010000
                Mod3Mask = #b0000000100000
                Mod4Mask = #b0000001000000
                Mod5Mask = #b0000010000000
                Button1Mask = #b0000100000000
                Button2Mask = #b0001000000000
                Button3Mask = #b0010000000000
                Button4Mask = #b0100000000000
                Button5Mask = #b1000000000000
                Any = #x8000)))
]}

@close-eval[ffi-eval]

