#lang scribble/doc
@(require scribble/manual
          "com-common.rkt"
          scribble/racket
          (for-syntax racket/base)
          (for-label racket/base
                     (except-in racket/contract ->)
                     ffi/unsafe
                     ffi/unsafe/com
                     ffi/unsafe/alloc
                     ffi/winapi))

@title[#:tag "com-intf"]{COM Classes and Interfaces}

@defmodule[ffi/unsafe/com]{The @racketmodname[ffi/unsafe/com] library
exports all of @racketmodname[ffi/com], and it also supports direct,
FFI-based calls to COM object methods.}

@; ----------------------------------------

@section{Describing COM Interfaces}

@defform/subs[(define-com-interface (_id _super-id)
                ([method-id ctype-expr maybe-alloc-spec] ...))
              ([maybe-alloc-spec code:blank
                                 (code:line #:release-with-function function-id)
                                 (code:line #:release-with-method method-id)
                                 #:releases)]{

定义 @racket[_id] 为一个扩展 @racket[_super-id] 的接口，其中 @racket[_super-id] 通常为 @racket[_IUnknown]，并包含由 @racket[method-id] 命名的方法。@racket[_id] 和 @racket[_super-id] 标识符必须以下划线开头。@racket[@#,racket[_super-id]@#,racketidfont{_vt}] 也必须已定义，以生成虚方法表类型。

@racket[method-id]s 的顺序必须与 @tech{COM interface} 规范匹配，但不包括从 @racket[_super-id] 继承的方法。由 @racket[ctype-expr] 生成的每个方法类型（非 @racket[_fpointer]）必须是一个函数类型，其第一个参数是 "self" 指针，通常使用 @racket[_mfun] 或 @racket[_hmfun] 构建。

@racket[define-com-interface] 形式绑定 @racket[_id]、@racket[@#,racketvarfont{id}?]、@racket[@#,racket[_id]-pointer]、@racket[@#,racket[_id]@#,racketidfont{_vt}]（虚方法表）、@racket[@#,racket[_id]@#,racketidfont{_vt-pointer]}，以及每个方法（@racket[ctype-expr] 非 @racket[_fpointer] 的）对应的 @racket[method-id]。（换句话说，对不需要调用的接口方法，使用 @racket[_fpointer] 作为占位符。）接口的实例类型为 @racket[@#,racket[_id]-pointer]。每个已定义的 @racket[method-id] 绑定到类函数宏，期望第一个参数为 @racket[@#,racket[_id]-pointer]，其余参数为方法参数。

@racket[maybe-alloc-spec] 描述方法的分配和终结化处理信息，类似于 @racketmodname[ffi/unsafe/alloc]。若 @racket[maybe-alloc-spec] 为 @racket[#:release-with-function function-id]，则使用 @racket[function-id] 来释放方法产生的结果，除非在该结果超出作用域之前已显式释放；例如，@racket[#:release-with-function Release] 适用于返回必须最终释放的 COM 接口引用的方法。@racket[#:release-with-method method-id] 形式类似，但释放器是同一对象上的一个方法（即其他 @racket[method-id] 或继承方法）。@racket[#:releases] 注解表明方法是释放器（因此，若值已显式通过方法释放，则不会自动释放）。

关于使用 @racket[define-com-interface] 的示例，参见 @secref["com-intf-example"]。}

@; ----------------------------------------

@section{Obtaining COM Interface References}

@defproc[(QueryInterface [iunknown com-iunknown?] [iid iid?] [intf-pointer-type ctype?]) 
         (or/c cpointer? #f)]{

尝试提取给定 @tech{COM object} 的指定 @tech{COM interface} 指针。若对象不支持请求的接口，结果为 @racket[#f]，否则转换为 @racket[intf-pointer-type] 类型。

具体的 @tech{IID} 和 @racket[intf-pointer-type] 是成对的，例如 @racket[IID_IUnknown] 对应 @racket[_IUnknown-pointer]。

对于非 @racket[#f] 的结果，@racket[Release] 函数是指针的自动释放器。指针在转换到 @racket[intf-pointer-type] 后注册释放器，这就是 @racket[QueryInterface] 接受 @racket[intf-pointer-type] 参数的原因（因为转换会生成一个新引用）。}

@deftogether[(
@defproc[(AddRef [iunknown com-iunknown?]) exact-positive-integer?]
@defproc[(Release [iunknown com-iunknown?]) exact-nonnegative-integer?)
)]{

增加或减少 @racket[iunknown] 上的引用计数，返回新的引用计数；若计数降为零，则释放接口引用。}


@defproc[(make-com-object [iunknown com-iunknown?] [clsid (or/c clsid? #f)]
                          [#:manage? manage? any/c #t])
         com-object?]{

将 @tech{COM object} 转换为 COM 自动化函数（如 @racket[com-invoke]）可用的对象。

若 @racket[manage?] 为真，则所得对象注册到当前 custodian，并设置终结器在 custodian 关闭或对象不可达时调用 @racket[com-release]。}

@; ----------------------------------------

@section{COM FFI Helpers}


@defform[(_wfun fun-option ... maybe-args type-spec ... -> type-spec
            maybe-wrapper)]{

类似 @racket[_fun]，但添加 @racket[#:abi winapi]。}


@defform[(_mfun fun-option ... maybe-args type-spec ... -> type-spec
            maybe-wrapper)]{

类似 @racket[_wfun]，但在第一个参数位置添加 @racket[_pointer] 类型（作为方法的 "self" 参数）。}


@defform[(_hfun fun-option ... type-spec ... -> id maybe-allow output-expr)
         #:grammar
         ([maybe-allow code:blank
                       (code:line #:allow [result-id allow?-expr])])]{

类似 @racket[_wfun]，但用于返回 @racket[_HRESULT] 的函数。若指定了 @racket[#:allow]，则结果绑定到 @racket[result-id]，否则结果不可直接访问。

@racket[_hfun] 形式对外部调用的 @racket[_HRESULT] 值处理如下：

@itemlist[

 @item{若结果为零，或已指定 @racket[#:allow] 且 @racket[allow?-expr] 返回 @racket[#t]，则 @racket[output-expr]（类似 @racket[_fun] 中 @racket[_maybe-wrapper]）决定返回结果。}

 @item{若结果为 @cpp{RPC_E_CALL_REJECTED} 或 @cpp{RPC_E_SERVERCALL_RETRYLATER}，则自动重试最多 @racket[(current-hfun-retry-count)] 次，每次尝试间隔 @racket[(current-hfun-retry-delay)] 秒。}

 @item{否则，使用 @racket[windows-error] 报错，以 @racket[id] 作为失败函数的名称。}

]

@history[#:changed "6.2" @elem{Added @racket[#:allow] and automatic retries.}]}


@defform[(_hmfun fun-option ... type-spec ... -> id output-expr)]{

类似 @racket[_hfun]，但与 @racket[_mfun] 类似，第一个参数位置添加 @racket[_pointer]。}

@deftogether[(
@defparam[current-hfun-retry-count exact-nonnegative-integer? count]
@defparam[current-hfun-retry-delay secs (>=/c 0.0))]
)]{

决定 @racket[_hfun] 自动重试行为的参数。

@history[#:added "6.2"]}


@defproc[(HRESULT-retry? [r exact-nonnegative-integer?]) boolean?]{

若 @racket[r] 是 @cpp{RPC_E_CALL_REJECTED} 或 @cpp{RPC_E_SERVERCALL_RETRYLATER} 则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.2"]}


@deftogether[(
@defthing[_GUID ctype?]
@defthing[_GUID-pointer ctype?]
@defthing[_HRESULT ctype?]
@defthing[_LCID ctype?]
)]{

COM 接口规范中常用的一些 @tech{C types}。}


@defthing[LOCALE_SYSTEM_DEFAULT exact-integer?]{

@racket[_LCID] 参数的常用值。}


@deftogether[(
@defproc[(SysFreeString [str _pointer]) void?]
@defproc[(SysAllocStringLen [content _pointer] [len integer?]) cpointer?]
)]{

COM 接口通常需要或返回必须作为系统字符串分配或释放的字符串。

接收字符串值时，将其 @racket[cast] 为 @racket[_string/utf-16] 以提取副本，然后用 @racket[SysFreeString] 释放原始指针。}


@deftogether[(
@defthing[IID_NULL iid?]
@defthing[IID_IUnknown iid?]
)]{

常用的 @tech{IIDs}。}

@deftogether[(
@defthing[_IUnknown ctype?]
@defthing[_IUnknown-pointer ctype?]
@defthing[_IUnknown_vt ctype?]
)]{

@cpp{IUnknown} @tech{COM interface} 的类型。}


@defproc[(windows-error [msg string?] [hresult exact-integer?])
         any]{

抛出异常。@racket[msg] 字符串提供基本错误消息，同时附加 @racket[hresult] 及其可读解释（若有）。}

@; ----------------------------------------

@section[#:tag "com-intf-example"]{COM Interface Example}

这里有一个示例，使用 Standard Component Categories Manager 枚举系统中不同预定义类别中已安装的 COM 类。该示例说明如何通过 @tech{CLSID} 实例化 COM 类、使用 @racket[define-com-interface] 描述 COM 接口，以及使用分配规范确保即便发生错误或中断也能回收资源。

@(define-syntax-rule (define-literals id ...) (begin (define-literal id) ...))
@(define-syntax-rule (define-literal id)
   (define-syntax id (make-element-id-transformer 
                      (lambda (stx) #'@racketidfont[(symbol->string 'id)]))))
@define-literals[_ULONG _CATID _REFCATID
                 _CATEGORYINFO _CATEGORYINFO-pointer
                 _IEnumGUID _IEnumGUID-pointer
                 _IEnumCATEGORYINFO _IEnumCATEGORYINFO-pointer
                 _ICatInformation _ICatInformation-pointer]

@racketmod[
racket/base
(require ffi/unsafe
         ffi/unsafe/com)

(provide show-all-classes)

(code:comment @#,t{使用下面定义的 COM 接口的函数:})

(define (show-all-classes)
  (define ccm 
    (com-create-instance CLSID_StdComponentCategoriesMgr))
  (define icat (QueryInterface (com-object-get-iunknown ccm) 
                               IID_ICatInformation 
                               _ICatInformation-pointer))
  (define eci (EnumCategories icat LOCALE_SYSTEM_DEFAULT))
  (for ([catinfo (in-producer (lambda () (Next/ci eci)) #f)])
    (printf "~a:\n"
            (cast (array-ptr (CATEGORYINFO-szDescription catinfo)) 
                  _pointer 
                  _string/utf-16))
    (define eg 
      (EnumClassesOfCategories icat (CATEGORYINFO-catid catinfo)))
    (for ([guid (in-producer (lambda () (Next/g eg)) #f)])
      (printf " ~a\n" (or (clsid->progid guid)
                          (guid->string guid))))
    (Release eg))
  (Release eci)
  (Release icat))

(code:comment @#,t{要实例化的类:})

(define CLSID_StdComponentCategoriesMgr
  (string->clsid "{0002E005-0000-0000-C000-000000000046}"))

(code:comment @#,t{与规范匹配的类型和变体:})

(define _ULONG _ulong)
(define _CATID _GUID)
(define _REFCATID _GUID-pointer)
(define-cstruct _CATEGORYINFO ([catid _CATID]
                               [lcid _LCID]
                               [szDescription (_array _short 128)]))

(code:comment @#,t{------ IEnumGUID -------})

(define IID_IEnumGUID
  (string->iid "{0002E000-0000-0000-C000-000000000046}"))

(define-com-interface (_IEnumGUID _IUnknown)
  ([Next/g (_mfun (_ULONG = 1) (code:comment @#,t{简化为仅返回一个})
                  (guid : (_ptr o _GUID))
                  (got : (_ptr o _ULONG))
                  -> (r : _HRESULT)
                  -> (cond
                       [(zero? r) guid]
                       [(= r 1) #f] ; 结束
                       [else (windows-error "Next/g failed" r)]))]
   [Skip _fpointer]
   [Reset _fpointer]
   [Clone _fpointer]))

(code:comment @#,t{------ IEnumCATEGORYINFO -------})

(define IID_IEnumCATEGORYINFO
  (string->iid "{0002E011-0000-0000-C000-000000000046}"))

(define-com-interface (_IEnumCATEGORYINFO _IUnknown)
  ([Next/ci (_mfun (_ULONG = 1) (code:comment @#,t{简化为仅返回一个})
                   (catinfo : (_ptr o _CATEGORYINFO))
                   (got : (_ptr o _ULONG))
                   -> (r : _HRESULT)
                   -> (cond
                       [(zero? r) catinfo]
                       [(= r 1) #f] ; 结束
                       [else (windows-error "Next/ci failed" r)]))]
   [Skip _fpointer]
   [Reset _fpointer]
   [Clone _fpointer]))

(code:comment @#,t{------ ICatInformation -------})

(define IID_ICatInformation
  (string->iid "{0002E013-0000-0000-C000-000000000046}"))

(define-com-interface (_ICatInformation _IUnknown)
  ([EnumCategories (_hmfun _LCID
                           (p : (_ptr o _IEnumCATEGORYINFO-pointer))
                           -> EnumCategories p)]
   [GetCategoryDesc (_hmfun _REFCATID _LCID
                            (p : (_ptr o _pointer))
                            -> GetCategoryDesc 
                            (begin0
                             (cast p _pointer _string/utf-16)
                             (SysFreeString p)))]
   [EnumClassesOfCategories (_hmfun (_ULONG = 1) (code:comment @#,t{简化版})
                                    _REFCATID
                                    (_ULONG = 0) (code:comment @#,t{简化版})
                                    (_pointer = #f)
                                    (p : (_ptr o 
                                               _IEnumGUID-pointer))
                                    -> EnumClassesOfCategories p)
                            #:release-with-function Release]
   [IsClassOfCategories _fpointer]
   [EnumImplCategoriesOfClass _fpointer]
   [EnumReqCategoriesOfClass _fpointer]))

]
