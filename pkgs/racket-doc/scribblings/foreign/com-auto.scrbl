#lang scribble/doc
@(require scribble/manual
          scribble/bnf
          "com-common.rkt"
          (for-label racket/base
                     (except-in racket/contract ->)
                     ffi/unsafe/com
                     ffi/com-registry))

@title[#:tag "com-auto"]{COM Automation}

@defmodule[ffi/com #:use-sources (ffi/unsafe/com)]{The
@racketmodname[ffi/com] library builds on COM automation to provide a
safe use of COM objects that support the @as-index{@cpp{IDispatch}}
interface.}

@margin-note{The @racketmodname[ffi/com] library is based on the
@deftech{MysterX} library by Paul Steckler. MysterX is included with
Racket but deprecated, and it will be replaced in the next version
with a partial compatibility library that redirects to this one.}

@; ----------------------------------------

@section{GUIDs, CLSIDs, IIDs, and ProgIDs}

@deftogether[(
@defproc[(guid? [v any/c]) boolean?]
@defproc[(clsid? [v any/c]) boolean?]
@defproc[(iid? [v any/c]) boolean?]
)]{

如果 @racket[v] 是表示 @tech{GUID} 的结构体，则返回 @racket[#t]，否则返回 @racket[#f]。@racket[clsid?] 和 @racket[iid?] 函数与 @racket[guid?] 相同。

@tech{GUID} 对应于底层的不安全层 @racket[_GUID] 结构体。}

@deftogether[(
@defproc[(string->guid [str string?]) guid?]
@defproc[(string->clsid [str string?]) clsid?]
@defproc[(string->iid [str string?]) iid?]
)]{

将形如 @racket["{00000000-0000-0000-0000-0000000000}"] 的字符串（其中每个 @tt{0} 可为十六进制数字）转换为 @tech{GUID}。若 @racket[str] 格式不符，则抛出 @racket[exn:fail] 异常。

@racket[string->clsid] 和 @racket[string->iid] 函数与 @racket[string->guid] 等价。}

@defproc[(guid->string [g guid?]) string?]{

将 @tech{GUID} 转换为其字符串形式。}

@defproc[(guid=? [g1 guid?] [g2 guid?]) boolean?]{

判断 @racket[g1] 和 @racket[g2] 是否表示相同的 @tech{GUID}。}

@deftogether[(
@defproc[(progid->clsid [progid string?]) clsid?]
@defproc[(clsid->progid [clsid clsid?]) (or/c string? #f)]
)]{

将 @tech{ProgID} 转换为 @tech{CLSID} 或反之。并非每个 @tech{COM class} 都有 @tech{ProgID}，因此 @racket[clsid->progid] 的结果可能为 @racket[#f]。

@racket[progid->clsid] 接受无版本信息的 @tech{ProgID}，此时它生成最新可用版本的 @tech{CLSID}。@racket[clsid->progid] 始终生成带版本信息的 @tech{ProgID}。}

@; ----------------------------------------

@section{COM Objects}

@defproc[(com-object? [obj com-object?]) boolean?]{

  若参数表示一个 @tech{COM object}，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(com-create-instance [clsid-or-progid (or/c clsid? string?)]
                              [where (or/c 'local 'remote string?) 'local])
         com-object?]{

  返回 @racket[clsid-or-progid] 指定的 @tech{COM class} 的实例，其中 @racket[clsid-or-progid] 可为 @tech{CLSID} 或 @tech{ProgID}。

  可选参数 @racket[where] 指示实例的运行位置，可为 @racket['local]、@racket['remote] 或表示机器名称的字符串。详见 @secref["remote"]。

  任何 COM 类均可通过此方式创建对象，但 @racket[com-invoke] 等函数仅在对象支持 @cpp{IDispatch} COM 自动化接口时才能正常工作。

 所得对象会注册到当前 custodian，后者保留对该对象的引用，直到通过 @racket[com-release] 释放或 custodian 关闭为止。}


@defproc[(com-release [obj com-object?]) void?]{

释放指定的 @tech{COM object}。释放后 @racket[obj] 不可再使用，且底层 COM 对象将被销毁（除非其引用计数已通过 COM 方法或不安全操作增加）。

若 @racket[obj] 已被释放，则 @racket[com-release] 无效果。}


@defproc[(com-get-active-object [clsid-or-progid (or/c clsid? string?)])
         com-object?]{

  类似 @racket[com-create-instance]，但获取已有的活动对象（始终为本地对象）而非创建新对象。}


@defproc[(com-object-clsid [obj com-object?]) clsid?]{

  返回实例化 @racket[obj] 的 COM 类的 @racket{CLSID}，若 COM 类未知则报错。}


@defproc[(com-object-set-clsid! [obj com-object?] [clsid clsid?]) void?]{

  设置 @racket[obj] 的 COM @tech{CLSID}。当 COM 事件处理过程只能获取对象 COM 类的模糊信息时，此函数很有用。}


@defproc[(com-object-eq? [obj1 com-object?] [obj2 com-object?])
         boolean?]{

  若 @racket[obj1] 和 @racket[obj2] 指向同一个 @tech{COM object}，则返回 @racket[#t]，否则返回 @racket[#f]。

  若两个 COM 对象引用根据 @racket[com-object-eq?] 判断为相同，则它们在 @racket[equal?] 意义上也相同。但两个 @racket[com-object-eq?] 判断为相同的引用不一定是 @racket[eq?] 的。}


@defproc[(com-type? [v any/c]) boolean?]{

若 @racket[v] 表示某个 COM 对象类型的反射信息，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(com-object-type [obj com-object?]) com-type?]{

返回独立于对象本身的 COM 对象类型表示。}


@defproc[(com-type=? [t1 com-type?] [t2 com-type?]) boolean?]{

若 @racket[t1] 和 @racket[t2] 表示相同类型信息，则返回 @racket[#t]，否则返回 @racket[#f]。}


@; ----------------------------------------

@section{COM Methods}

@defproc[(com-methods [obj/type (or/c com-object? com-type?)]) 
         (listof string?)]{

   返回指示 @racket[obj/type] 中方法名称的字符串列表。}


@defproc[(com-method-type [obj/type (or/c com-object? com-type?)]
                          [method-name string?])
         (list/c '-> (listof type-description?) 
                     type-description?)]{

  返回指示 @racket[obj/type] 中指定方法类型的列表。@racket['->] 之后的列表表示参数类型，最后一个值表示返回值类型。详见 @secref["com-types"]。}


@defproc[(com-invoke [obj com-object?] [method-name string?] [v any/c] ...)
         any/c]{

  以 @racket[v]s 为参数，在 @racket[obj] 上调用 @racket[method-name]。特殊值 @racket[com-omit] 可用于省略可选参数，在为省略参数之后的参数提供值时很有好。

  参数类型尽可能通过 @racket[com-method-type] 确定，@racket[v] 中的 @racket[type-describe] 包装器将被替换为其包装的值。若无法从 @racket[com-method-type] 获得类型，则根据 @racket[v] 中任何 @racket[type-describe] 包装器的描述推断每个 @racket[v] 的类型。}


@defthing[com-omit any/c]{

与 @racket[com-invoke] 配合使用的常量，用于替代可选参数。}


@defproc[(com-omit? [v any/c]) boolean?]{

若 @racket[v] 为 @racket[com-omit]，则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.3.0.3"]}


@; ----------------------------------------

@section{COM Properties}

@defproc[(com-get-properties [obj/type (or/c com-object? com-type?)])
         (listof string?)]{

  返回指示 @racket[obj/type] 中可读属性名称的字符串列表。}


@defproc[(com-get-property-type [obj/type (or/c com-object? com-type?)]
                                [property-name string?])
         (list/c '-> '() type-description?)]{

  返回 @racket[property-name] 的类型，类似于 @racket[com-method] 的结果，其中结果类型对应于属性值类型。关于符号含义，见 @secref["com-types"]。}


@defproc[(com-get-property [obj com-object?] 
                           [property (or/c string?
                                           (cons/c string? list?))] 
                           ...+)
         any/c]{

  通过 @racket[property] 路径返回最终属性的值，其中每个中间属性必须为 COM 对象。

  每个 @racket[property] 是一个属性名字符串或以属性名字符串开头并包含参数化属性参数的列表。}


@defproc[(com-get-property* [obj com-object?] [property string?] [v any/c] ...)
         any/c]{

  返回一个参数化属性的值，其行为类似方法，接受 @racket[v]s 作为参数（类似 @racket[com-invoke]）。若未提供 @racket[v]s，则 @racket[com-get-property*] 等同于 @racket[com-get-property]。}

@defproc[(com-set-properties [obj/type (or/c com-object? com-type?)]) 
         (listof string?)]{

  返回指示 @racket[obj/type] 中可写属性名称的字符串列表。}


@defproc[(com-set-property-type [obj/type (or/c com-object? com-type?)] 
                                [property-name string?])
         (list/c '-> (list/c type-description?) 'void)]{

  返回 @racket[property-name] 的类型，类似于 @racket[com-method] 的结果，其中唯一参数类型对应于属性值类型。关于符号含义，见 @secref["com-types"]。}


@defproc[(com-set-property! [obj com-object?]
                            [property (or/c string?
                                            (cons/c string? list?))] ...+
                            [v any/c])
         void?]{

  通过 @racket[property] 链将 @racket[obj] 的最终属性值设置为 @racket[v]，其中每个中间属性的值必须为 COM 对象。@racket[property] 可为列表而非字符串，以表示参数化属性及其参数。

  属性类型尽可能通过 @racket[com-property-type] 确定，@racket[v] 中的 @racket[type-describe] 包装器随后被替换为其包装的值。若无法从 @racket[com-property-type] 获得类型，则根据 @racket[v] 中任何 @racket[type-describe] 包装器的描述推断 @racket[v] 的类型。}

@; ----------------------------------------

@section{COM Events}

@defproc[(com-events [obj/type (or/c com-object? com-type?)]) 
         (listof string?)]{

   返回指示 @racket[obj/type] 中事件名称的字符串列表。}


@defproc[(com-event-type [obj/type (or/c com-object? com-type?)]
                         [event-name string?])
         (list/c '-> (listof type-description?) 'void)]{

  返回指示 @racket[obj/type] 中指定事件类型的列表。@racket['->] 之后的列表表示参数类型。详见 @secref["com-types"]。}


@defproc[(com-event-executor? [v any/c]) boolean?]{

若 @racket[v] 是一个 @deftech{COM event executor}（用于排队事件回调），则返回 @racket[#t]。@tech{COM event executor} @racket[_com-ev-ex] 在 @racket[sync] 意义下是可同步事件，@racket[(sync _com-ev-ex)] 返回一个准备回调的 thunk。}


@defproc[(com-make-event-executor) com-event-executor?]{

创建一个新的 @tech{COM event executor}，供 @racket[com-register-event-callback] 使用。}


@defproc[(com-register-event-callback [obj com-object?]
                                      [name string?]
                                      [proc procedure?]
                                      [com-ev-ex com-event-executor?])
         void?]{

为 @racket[obj] 中名为 @racket[name] 的事件注册回调。当事件触发时，将一次以事件参数调用 @racket[proc]（取决于 @racket[obj] 和 @racket[name]）的操作排队到 @racket[com-ev-ex] 中。对 @racket[com-ev-ex] 进行同步将产生一个将 @racket[proc] 应用于事件参数并返回结果的 thunk。

每个 @racket[obj] 和 @racket[name] 组合只能注册一个回调。

事件回调的注册依赖于随 Racket 分发的 @filepath{myssink.dll} 所实现的 COM 类的预先注册。（所有 Racket 版本的 DLL 相同。）}


@defproc[(com-unregister-event-callback [obj com-object?]
                                        [name string?])
         void?]{

移除 @racket[obj] 中 @racket[name] 的任何已有回调。}


@; ----------------------------------------

@section{COM Enumerations}

@defproc[(com-enumerate-to-list [obj com-object?]) list?]{

生成 @racket[obj] 作为 Visual Basic 或 PowerShell 中 for-each 循环驱动程序时会产生的元素。

调用 @racket[(com-enumerate-to-list obj)] 等价于 @racket[(com-enumeration-to-list (com-get-property obj "_NewEnum"))]。

@history[#:added "6.2"]}


@defproc[(com-enumeration-to-list [obj com-object?]) list?]{

给定一个实现 @cpp{IEnumVARIANT} 的 COM 对象，将枚举值提取到列表中。

@history[#:added "6.2"]}


@; ----------------------------------------

@section{Interface Pointers}

@deftogether[(
@defproc[(com-object-get-iunknown [obj com-object?]) com-iunkown?]
@defproc[(com-object-get-idispatch [obj com-object?]) com-idispatch?]
)]{

从 @racket[obj] 提取 @cpp{IUnknown} 或 @cpp{IDispatch} 指针。前者对任何未通过 @racket[com-release] 释放的 @tech{COM object} 都可成功；后者仅在 @tech{COM object} 支持 @cpp{IDispatch} 时成功，否则抛出 @racket[exn:fail]。}


@defproc[(com-iunknown? [v any/c]) boolean?]{

若 @racket[v] 对应于不安全的 @racket[_IUnknown-pointer]，则返回 @racket[#t]，否则返回 @racket[#f]。每个 @tech{COM interface} 都扩展自 @cpp{IUnknown}，因此对所有接口指针，@racket[com-iunknown?] 都返回 @racket[#t]。}


@defproc[(com-idispatch? [v any/c]) boolean?]{

若 @racket[v] 对应于不安全的 @cpp{IDispatch}，则返回 @racket[#t]，否则返回 @racket[#f]。}

@; ----------------------------------------

@section[#:tag "remote"]{Remote COM servers (DCOM)}

@racket[com-create-instance] 的可选 @racket[_where] 参数可以是 @racket['remote]。此时，服务器实例在由注册表项

@centerline{@tt{HKEY_CLASSES_ROOT\AppID\@nonterm{CLSID}\RemoteServerName}}

指定的位置运行，其中 @nonterm{CLSID} 是应用程序的 CLSID。此键可使用 @exec{dcomcnfg} 工具设置。在 @exec{dcomcnfg} 中，在 @onscreen{Applications} 选项卡上选择要在的应用程序，然后点击 @onscreen{Properties} 按钮。在 @onscreen{Location} 选项卡上，选择 @onscreen{Run application on the following computer}，并输入机器名。

要运行 COM 远程服务器，客户端机器的注册表必须包含以下项：

@centerline{@tt{HKEY_CLASSES_ROOT\CLSID\@nonterm{CLSID}}}

其中 @nonterm{CLSID} 是服务器的 CLSID。服务器应用程序本身无需安装在客户端机器上。

DCOM 有许多配置问题。有关如何设置 DCOM 客户端和服务器的更多信息，参见

@centerline{@link["https://web.archive.org/web/20061013184653/www.distribucon.com/dcom95.html"]{http://www.distribucon.com/dcom95.html}}

@; ----------------------------------------

@section[#:tag "com-types"]{COM Types}

在 @racket[com-method-type] 等函数的结果中，符号用于表示各种原子类型：

@itemlist[

 @item{@racket['int] --- 32 位有符号整数}

 @item{@racket['unsigned-int] --- 32 位无符号整数}

 @item{@racket['short-int] --- 16 位有符号整数}

 @item{@racket['unsigned-short] --- 16 位无符号整数}

 @item{@racket['signed-char] --- 8 位有符号整数}

 @item{@racket['char] --- 8 位无符号整数}

 @item{@racket['long-long] --- 64 位有符号整数}

 @item{@racket['unsigned-long-long] --- 64 位无符号整数}

 @item{@racket['float] --- 32 位浮点数}

 @item{@racket['double] --- 64 位浮点数}

 @item{@racket['currency] --- 精确数，乘以 10,000 后为 64 位有符号整数}

 @item{@racket['boolean] --- 布尔值}

 @item{@racket['string] --- 字符串}

 @item{@racket['date] --- @racket[date] 或 @racket[date*]；转换为 @racket[date*] 时，时区报告为 @racket["UTC"]，@racket[year-day] 字段为 @racket[0]}

 @item{@racket['com-object] --- @racket[com-object?] 所描述的 @tech{COM object}}

 @item{@racket['iunknown] --- 类似 @racket['com-object]，但也接受 @racket[com-iunknown?] 所描述的 @cpp{IUnknown} 指针}

 @item{@racket['com-enumeration] --- 32 位有符号整数}

 @item{@racket['any] --- 上述任何类型，或数组（当不嵌套在数组类型中时）}

 @item{@racket['...] --- 类似 @racket['any]，但当出现在参数类型序列末尾时，允许前面的类型出现 0 次或多次}

 @item{@racket['void] --- 无值}

]

A type symbol wrapped in a list with @racket['box], such as
@racket['(box int)], is a call-by-reference argument. A box supplied
for the argument is updated with a new value when the method returns.

A type wrapped in a list with @racket['opt], such as @racket['(opt
(box int))], is an optional argument. The argument can be omitted or
replaced with @racket[com-omit].

A type wrapped in a list with @racket['array] and a positive exact
integer, such as @racket['(array 7 int)], represents a vector of
values to be used as a COM array. A @racket['?] can be used in place
of the length integer to support a vector of any length.  Array types
with non-@racket['?] lengths can be nested to specify a
multidimensional array as represented by nested vectors.

A type wrapped in a list with @racket['variant], such as
@racket['(variant (array 7 int))], is the same as the wrapped type,
but a @racket['variant] wrapper within an @racket['array] type prevents
construction of another array dimension. For example, @racket['(array 2 (array 3
int))] is a two-dimensional array of integers, but @racket['(array 2
(variant (array 3 int)))] is a one-dimensional array whose elements
are one-dimensional arrays of integers.

When type information is not available, functions like @racket[com-invoke]
infer type descriptions from arguments. Inference chooses @racket['boolean]
for booleans; the first of @racket['int], @racket['unsigned-int], 
@racket['long-long], @racket['unsigned-long-long] that fits for an exact integer;
@racket['double] for inexact real numbers; @racket['string] for a string;
@racket['com-object] and @racket['iunknown] for corresponding COM object references;
and an @racket['array] type for a vector, where the element type is inferred
from vector values, resorting to @racket['any] if any two elements have different
inferred types.


@defproc[(type-description? [v any/c]) boolean?]{

Return @racket[#t] if @racket[v] is a COM argument or result type
description as above, @racket[#f] otherwise.}


@deftogether[(
@defproc[(type-described? [v any/c]) boolean?]
@defproc[(type-describe [v any/c] [desc type-description?])
         type-described?]
@defproc[(type-described-value [td type-described?]) any/c]
@defproc[(type-described-description [td type-described?])
         type-description?]
)]{

@racket[type-described?] 谓词识别由 @racket[type-describe] 生成的包装器，@racket[type-described-value] 和 @racket[type-described-description] 用于提取 @racket[type-describe] 值的值和描述部分。

@racket[type-describe] 包装器将基础值与类型描述组合。当 COM 自动化中 @racket[com-invoke] 的方法或 @racket[com-set-property!] 的属性无法获得类型信息时，使用该描述代替自动推断的 COM 参数类型。包装器可直接用于值，也可用于 box 或 vector 内的值。}

@; ----------------------------------------

@section{Class Display Names}

@defmodule[ffi/com-registry]{@racketmodname[ffi/com-registry]
库提供了 @tech{coclass} 名称到 @tech{CLSIDs} 的映射，以兼容旧的 @tech{MysterX} 接口。}

@deftech{coclass} 名称对应于 COM 类的显示名称；显示名称与 COM 类并非一一映射，某些 COM 类没有显示名称。


@defproc[(com-all-coclasses) (listof string?)]{

返回系统上注册的所有 @tech{COM class} 的 @tech{coclass} 字符串列表。}


@defproc[(com-all-controls) (listof string?)]{

返回系统注册表中具有 @racket["Control"] 子键的所有 COM 类的 @tech{coclass} 字符串列表。}


@deftogether[(
@defproc[(coclass->clsid [coclass string?]) clsid?]
@defproc[(clsid->coclass [clsid clsid?]) string?]
)]{

将 @tech{coclass} 字符串转换为 @tech{CLSID} 或反之。此转换通过枚举系统注册表中的 @tech{COM class} 实现。}
