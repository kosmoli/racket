#lang scribble/doc
@(require scribble/manual
          "com-common.rkt"
          (for-label racket/base
                     ffi/unsafe/com))

@title[#:style 'toc #:tag "com"]{COM（通用对象模型）}

@racketmodname[ffi/com] 和 @racketmodname[ffi/unsafe/com]
库以两层支持 COM 交互。安全的上层提供创建 COM 对象以及
基于 COM 自动化（即对象提供的反射信息）动态构造方法调用的函数。
不安全的下层提供更直接操作 COM 对象和接口的语法形式和函数。

@deftech{COM object} 实例化一个特定的 @deftech{COM class}。
@tech{COM class} 可以通过以下两种方式之一指定：

@itemlist[

 @item{@deftech{CLSID}（类 ID），表示为 @tech{GUID}。
 @deftech{GUID}（全局唯一标识符）是一个 16 字节结构。GUID 通常以字符串形式编写，
 如 @racket["{A3B0AF9E-2AB0-11D4-B6D2-0060089002FE}"]。
 @racket[string->guid] 和 @racket[guid->string] 在字符串和 @tech{GUID} 形式之间转换。
 @racket[string->clsid] 与 @racket[string->guid] 相同，但其用途暗示生成的
 @tech{GUID} 将用作 @tech{CLSID}。}

 @item{@deftech{ProgID} 是一个人类可读的名称，如
 @racket["MzCom.MzObj.5.2.0.7"]，包含版本号。
 版本号可从 @tech{ProgID} 中省略，此时使用最新版本。
 操作系统提供 @tech{ProgID} 和 @tech{CLSID} 之间的映射，
 可通过 @racket[progid->clsid] 和 @racket[clsid->progid] 获取。}

]

@tech{COM object} 可在本地机器上或远程机器上实例化。后者依赖于操作系统的
@deftech{DCOM}（分布式 COM）支持。

每个 @tech{COM object} 支持若干 @deftech{COM interface}。
@tech{COM interface} 有一个编程名称，如 @cpp{IDispatch}，对应于 C 层协议。
每个接口还有一个表示为 @tech{GUID} 的 @deftech{IID}（接口 ID），
例如 @racket["{00020400-0000-0000-C000-000000000046}"]。
直接调用 COM 方法需要先使用 @racket[QueryInterface] 和所需的 @tech{IID}
从对象中提取合适的接口指针；结果实际上被强制转换为指向指针的指针，
其中分发表具有静态已知的大小和 foreign-function 内容。
@racket[define-com-interface] 形式简化了接口指针的描述和使用。
COM 自动化层在内部使用固定数量的反射接口，特别是 @cpp{IDispatch}，
通过名称调用方法并进行安全的参数列集。

@local-table-of-contents[]

@include-section["com-auto.scrbl"]
@include-section["com-intf.scrbl"]
@include-section["active-x.scrbl"]
