#lang scribble/doc
@(require scribble/manual
          scribble/eval
          (for-label racket/base
                     racket/contract
                     ffi/unsafe/objc
                     (except-in ffi/unsafe ->)
                     (only-in ffi/objc objc-unsafe!)
                     (only-in scheme/foreign unsafe!)))

@(define objc-eval (make-base-eval))
@(interaction-eval #:eval objc-eval (define-struct cpointer:id ()))

@(define seeCtype
   @elem{参见 @secref["ctype"]})

@title{Objective-C FFI}

@defmodule[ffi/unsafe/objc]{@racketmodname[ffi/unsafe/objc] 库构建于 @racketmodname[ffi/unsafe] 之上，用于支持与 @link["http://developer.apple.com/documentation/Cocoa/Conceptual/ObjectiveC/"]{Objective-C} 的交互。}

本库以两层方式支持 Objective-C 交互。上层提供消息发送和派生子类的语法形式。下层是 @link["https://developer.apple.com/documentation/objectivec"]{Objective-C 运行时库} 函数的薄包装层。即便与常规 Racket 库相比，上层也是不安全的且处于相对较低的级别，因为参数和返回值类型必须用 FFI C 类型来声明（@seeCtype）。

@; ----------------------------------------------------------------------

@section{FFI 类型与常量}

@defthing[_id ctype?]{Objective-C 对象的类型，一个不透明指针。}

@defthing[_Class ctype?]{Objective-C 类的类型，同样是一个 @racket[_id]。}

@defthing[_Protocol ctype?]{Objective-C 协议的类型，同样是一个 @racket[_id]。}

@defthing[_SEL ctype?]{Objective-C 选择子的类型，一个不透明指针。}

@defthing[_BOOL ctype?]{Objective-C 布尔类型。Racket 值按照常规方式为 C 进行转换：@racket[#f] 表示假，其他任意值表示真。C 值会被转换为 Racket 布尔值。}

@defthing[YES boolean?]{@racket[#t] 的同义词}

@defthing[NO boolean?]{@racket[#f] 的同义词}

@; ----------------------------------------------------------------------

@section{语法形式与过程}

@defform*/subs[[(tell result-type obj-expr method-id)
                (tell result-type obj-expr arg ...)]
               ([result-type code:blank
                             (code:line #:type ctype-expr)]
                [arg (code:line method-id arg-expr)
                     (code:line method-id #:type ctype-expr arg-expr)])]{

向 @racket[obj-expr] 产生的 Objective-C 对象发送一条消息。当返回值或参数的类型被省略时，类型被假定为 @racket[_id]；否则必须指定为 FFI C 类型（@seeCtype）。

若只提供一个不带参数的 @racket[method-id]，则 @racket[method-id] 必须不以 @litchar{:} 结尾；否则每个 @racket[method-id] 都必须以 @litchar{:} 结尾。

@examples[
#:eval objc-eval
(eval:alts (tell NSString alloc) (make-cpointer:id))
(eval:alts (tell (tell NSString alloc)
                 initWithUTF8String: #:type _string "Hello")
           (make-cpointer:id))
]}

@defform*[[(tellv obj-expr method-id)
           (tellv obj-expr arg ...)]]{

类似 @racket[tell]，但返回类型为 @racket[_void]。}

@defform[(import-class class-id ...)]{

将每个 @racket[class-id] 定义为以 @racket[class-id] 的字符串形式注册的类（一个 FFI 类型为 @racket[_Class] 的值）。注册的类通过 @racket[objc_lookUpClass] 获取。

@examples[
#:eval objc-eval
(eval:alts (import-class NSString) (void))
]

通过 @racket[import-class] 访问的类通常作为加载外部库的副作用而声明。例如，若要在 Mac OS 上导入 @tt{NSString} 类，必须首先加载 @filepath{Foundation} 框架。注意：若在 DrRacket 或 @racket[require] 了 @racketmodname[racket/gui/base] 的模块中使用 @racket[import-class]，则 @filepath{Foundation} 已经被加载到 Racket 进程中。为避免依赖其他库加载 @filepath{Foundation}，应显式使用 @racket[ffi-lib] 加载它：

@interaction[
#:eval objc-eval
(eval:alts (ffi-lib
            "/System/Library/Frameworks/Foundation.framework/Foundation") (void))
(eval:alts (import-class NSString) (void))
]}

@defform[(import-protocol protocol-id ...)]{

将每个 @racket[protocol-id] 定义为以 @racket[protocol-id] 的字符串形式注册的协议（一个 FFI 类型为 @racket[_Protocol] 的值）。注册的协议通过 @racket[objc_getProtocol] 获取。

@examples[
#:eval objc-eval
(eval:alts (import-protocol NSCoding) (void))
]}

@defform/subs[#:literals (+ - +a -a)
              (define-objc-class class-id superclass-expr
                maybe-mixins
                maybe-protocols
                [field-id ...]
                method ...)
              ([maybe-mixins code:blank
                             (code:line #:mixins (mixin-expr ...))]
               [maybe-protocols code:blank
                                (code:line #:protocols (protocol-expr ...))]
               [method (mode maybe-async result-ctype-expr (method-id) body ...+)
                       (mode maybe-async result-ctype-expr (arg ...+) body ...+)]
               [mode + - +a -a]
               [maybe-async code:blank
                            (code:line #:async-apply async-apply-expr)]
               [arg (code:line method-id [ctype-expr arg-id])])]{

将 @racket[class-id] 定义为一个新的、已注册的 Objective-C 类（FFI 类型为 @racket[_Class]）。@racket[superclass-expr] 应产生一个 Objective-C 类或 @racket[#f]（表示无超类）。可选的 @racket[#:mixins] 子句可指定由 @racket[define-objc-mixin] 定义的 mixin。可选的 @racket[#:protocols] 子句可指定该类实现的 Objective-C 协议，其中 @racket[protocol-expr] 的 @racket[#f] 结果会被忽略。

每个 @racket[field-id] 是一个保存 Racket 值的实例字段，在对象分配时初始化为 @racket[#f]。@racket[field-id] 在方法 @racket[body] 内部可以直接引用和 @racket[set!]。在对象外部，可以通过 @racket[get-ivar] 和 @racket[set-ivar!] 引用和设置它们。

每个 @racket[method] 会向类添加或覆写一个方法（当 @racket[mode] 为 @racket[-] 或 @racket[-a] 时）供实例调用，或向元类添加一个方法（当 @racket[mode] 为 @racket[+] 或 @racket[+a] 时）供类本身调用。所有返回值类型和参数类型必须使用 FFI C 类型来声明（@seeCtype）。当 @racket[mode] 为 @racket[+a] 或 @racket[-a] 时，方法以原子模式调用（参见 @racket[_cprocedure]）。可选的 @racket[#:async-apply] 规范确定该方法在外线程调用时的工作方式，与 @racket[_cprocedure] 的方式相同。

若 @racket[method] 以单个不带参数的 @racket[method-id] 声明，则 @racket[method-id] 必须不以 @litchar{:} 结尾。否则每个 @racket[method-id] 都必须以 @litchar{:} 结尾。

若为 @racket[-] 模式声明了特殊方法 @racket[dealloc]，则不得调用超类方法，因为 @racket[(super-tell dealloc)] 会被自动添加到方法末尾。此外，在 @racket[(super-tell dealloc)] 之前，会为实例中每个 @racket[field-id] 释放空间。

@examples[
#:eval objc-eval
(eval:alts
 (define-objc-class MyView NSView
   [bm] (code:comment @#,elem{<- one field})
   (- _racket (swapBitwmap: [_racket new-bm])
      (begin0 bm (set! bm new-bm)))
   (- _void (drawRect: [@#,racketidfont{_NSRect} exposed-rect])
      (super-tell drawRect: exposed-rect)
      (draw-bitmap-region bm exposed-rect))
   (- _void (dealloc)
      (when bm (done-with-bm bm))))
 (void))
]

@history[#:changed "6.90.0.26" @elem{更改了 @racket[#:protocols] 的处理方式以忽略 @racket[#f] 表达式结果。}]}

@defform[(define-objc-mixin (class-id superclass-id)
           maybe-mixins
           maybe-protocols
           [field-id ...]
           method ...)]{

类似 @racket[define-objc-class]，但定义一个要通过 @racket[define-objc-class] 或 @racket[define-objc-mixin] 与其他方法定义组合的 mixin。mixin 指定的 @racket[field-id] 不会由 mixin 添加，而必须是待添加方法的类中声明的 @racket[field-id] 的子集。}


@defidform[self]{

在 @racket[define-objc-class] 或 @racket[define-objc-mixin] 方法体中使用时，指代被调用方法的对象。此形式不能在 @racket[define-objc-class] 或 @racket[define-objc-mixin] 方法之外使用。}

@defform*[[(super-tell result-type method-id)
           (super-tell result-type arg ...)]]{

在 @racket[define-objc-class] 或 @racket[define-objc-mixin] 方法体中使用时，调用超类方法。@racket[result-type] 和 @racket[arg] 子形式的语法与 @racket[tell] 中相同。此形式不能在 @racket[define-objc-class] 或 @racket[define-objc-mixin] 方法之外使用。}


@defform[(get-ivar obj-expr field-id)]{

提取由 @racket[define-objc-class] 创建的类中字段的 Racket 值。}

@defform[(set-ivar! obj-expr field-id value-expr)]{

设置由 @racket[define-objc-class] 创建的类中字段的 Racket 值。}

@defform[(selector method-id)]{

返回 @racket[method-id] 字符串形式对应的选择子（FFI 类型为 @racket[_SEL]）。

@examples[
(eval:alts (tellv button setAction: #:type _SEL (selector terminate:)) (void))
]}

@defproc[(objc-is-a? [obj _id] [cls _Class]) boolean?]{

检查 @racket[obj] 是否为 Objective-C 类 @racket[cls] 或其子类的实例。

@history[#:changed "6.1.0.5" @elem{识别子类，而非要求精确类匹配。}]}

@defproc[(objc-subclass? [subcls _Class] [cls _Class]) boolean?]{

检查 @racket[subcls] 是否为 @racket[cls] 或其子类。

@history[#:added "6.1.0.5"]}


@defproc[(objc-get-class [obj _id]) _Class]{

提取 @racket[obj] 的类。

@history[#:added "6.3"]}


@defproc[(objc-set-class! [obj _id] [cls _Class]) void?]{

将 @racket[obj] 的类更改为 @racket[cls]。对象的现有表示必须与新类兼容。

@history[#:added "6.3"]}


@defproc[(objc-get-superclass [cls _Class]) _Class]{

返回 @racket[cls] 的超类。

@history[#:added "6.3"]}


@defproc[(objc-class-has-instance-method? [cls _Class] [sel _SEL]) boolean?]{

报告 @racket[cls] 是否提供实例方法 @racket[sel]。

@history[#:added "9.0.0.6"]}


@defproc[(objc-dispose-class [cls _Class]) void?]{

销毁 @racket[cls]，它不得有任何现有实例或子类。

@history[#:added "6.3"]}


@defproc[(objc-block [function-type? ctype]
                     [proc procedure?]
                     [#:keep keep (box/c list?)])
         cpointer?]{

将 Racket 函数 @racket[proc] 包装为 Objective-C 块。该过程必须接受一个初始指针参数作为块的 "self" 参数，且该额外参数必须包含在给定的 @racket[function-type] 中。

为实现块而分配的额外记录会被添加到 @racket[keep] 中的列表，该列表也可能通过 @racket[_fun] 的 @racket[#:keep] 选项包含在 @racket[function-type] 中。@racket[keep] 中注册的指针必须保留，只要块仍在使用期间。

@history[#:added "6.3"]}


@defproc[(objc-block-function-pointer [block cpointer?]) fpointer?]{

提取 Objective-C 块的函数指针。将此函数指针转换为适当的函数类型来调用它，其中块本身必须作为第一个参数传递给函数。

@history[#:added "8.13.0.1"]}


@defform[(with-blocking-tell form ...+)]{

使 @racket[form] 中语法上出现的任何 @racket[tell]、@racket[tellv] 或 @racket[super-tell] 表达式以阻塞方式运行，参见 @racket[_cprocedure] 的 @racket[#:blocking?] 参数。否则 @racket[(with-blocking-tell form ...+)] 等价于 @racket[(let () form ...+)]。

@history[#:added "7.0.0.19"]}

@; ----------------------------------------------------------------------

@section{原始运行时函数}

@defproc[(objc_lookUpClass [s string?]) (or/c _Class #f)]{

按名称查找已注册的类。}

@defproc[(objc_getProtocol [s string?]) (or/c _Protocol #f)]{

按名称查找已注册的协议。}

@defproc[(sel_registerName [s string?]) _SEL]{

给定选择子名称的字符串形式，将其驻留（intern）。}

@defproc[(objc_allocateClassPair [cls _Class] [s string?] [extra integer?])
         _Class]{

分配一个新的 Objective-C 类。}

@defproc[(objc_registerClassPair [cls _Class]) void?]{

注册一个 Objective-C 类。}

@defproc[(object_getClass [obj _id]) _Class]{

返回对象的类（或类的元类）。}

@defproc[(class_getSuperclass [cls _Class])
         _Class]{

返回 @racket[cls] 的超类，若 @racket[cls] 无超类则返回 @racket[#f]。

@history[#:added "6.1.0.5"]}

@defproc[(class_addMethod [cls _Class] [sel _SEL] 
                          [imp procedure?]
                          [type ctype?]
                          [type-encoding string?])
         boolean?]{

向类添加方法。@racket[type] 参数必须是一个 FFI C 类型（@seeCtype），与 @racket[imp] 和非 Objective-C 类型字符串 @racket[type-encoding] 都匹配。}

@defproc[(class_addIvar [cls _Class] [name string?] [size exact-nonnegative-integer?]
                        [log-alignment exact-nonnegative-integer?] [type-encoding string?])
         boolean?]{

向 Objective-C 类添加实例变量。}

@defproc[(object_getInstanceVariable [obj _id]
                                     [name string?])
         (values _Ivar any/c)]{

获取类型为 @racket[_pointer] 的实例变量的值。}

@defproc[(object_setInstanceVariable [obj _id]
                                     [name string?]
                                     [val any/c])
         _Ivar]{

设置类型为 @racket[_pointer] 的实例变量的值。}

@defthing[_Ivar ctype?]{Objective-C 实例变量的类型，一个不透明指针。}

@defproc[((objc_msgSend/typed [types (vector/c result-ctype arg-ctype ...)])
          [obj _id]
          [sel _SEL]
          [arg any/c])
         any/c]{

调用 @racket[_id] 上名为 @racket[sel] 的 Objective-C 方法。@racket[types] 向量的元素个数必须比提供的 @racket[arg] 数量多一个；@racket[type] 中的第一个 FFI C 类型用作返回类型。}

@defproc[((objc_msgSendSuper/typed [types (vector/c result-ctype arg-ctype ...)])
          [super _objc_super]
          [sel _SEL]
          [arg any/c])
         any/c]{

类似 @racket[objc_msgSend/typed]，但用于超级调用。}

@deftogether[(
@defproc[(make-objc_super [id _id] [super _Class]) _objc_super]
@defthing[_objc_super ctype?]
)]{

用于超级调用的构造器和 FFI C 类型。}

@deftogether[(
@defproc[((objc_msgSend/typed/blocking [types (vector/c result-ctype arg-ctype ...)])
          [obj _id]
          [sel _SEL]
          [arg any/c])
         any/c]
@defproc[((objc_msgSendSuper/typed/blocking [types (vector/c result-ctype arg-ctype ...)])
          [super _objc_super]
          [sel _SEL]
          [arg any/c])
         any/c]
)]{

与 @racket[objc_msgSend/typed] 和 @racket[objc_msgSendSuper/typed] 相同，但指定发送应以阻塞方式进行，参见 @racket[_cprocedure] 的 @racket[#:blocking?] 参数。

@history[#:added "7.0.0.19"]}

@; ----------------------------------------------------------------------

@section{传统库}

@defmodule[ffi/objc]{@racketmodname[ffi/objc] 库是 @racketmodname[ffi/unsafe/objc] 的已弃用入口点。它仅直接导出安全操作，不安全操作通过 @racket[objc-unsafe!] 导入，类似于 @racketmodname[scheme/foreign #:indirect]。}

@defform[(objc-unsafe!)]{

在导入模块中使 @racketmodname[ffi/unsafe/objc] 的不安全绑定可用。}


@close-eval[objc-eval]
