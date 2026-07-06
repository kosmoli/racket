#lang scribble/manual
@(require (for-label racket/base racket/generic racket/contract/base))

@title[#:tag "struct-generics"]{泛型接口}

@defmodule[racket/generic]


@deftech{泛型接口}允许将每个类型的方法与泛型函数关联。泛型函数使用 @racket[define-generics] 形式定义。结构类型的方法实现使用 @racket[#:methods] 关键字定义（参见 @secref["define-struct"]）。

@defform/subs[(define-generics id
                generics-opt ...
                [method-id . kw-formals*] ...
                generics-opt ...)
              ([generics-opt
                (code:line #:defaults ([default-pred? default-impl ...] ...))
                (code:line #:fast-defaults ([fast-pred? fast-impl ...] ...))
                (code:line #:fallbacks [fallback-impl ...])
                (code:line #:defined-predicate defined-pred-id)
                (code:line #:defined-table defined-table-id)
                (code:line #:derive-property prop-expr prop-value-expr)
                (code:line #:requires [required-method-id ...])]
               [kw-formals* (arg* ...)
                            (arg* ...+ . rest-id)
                            rest-id]
               [arg* arg-id
                     [arg-id]
                     (code:line keyword arg-id)
                     (code:line keyword [arg-id])])]{

定义以下名称，以及由关键字选项指定的任何名称。

@itemlist[

 @item{@racketidfont{gen:}@racket[id] 作为 transformer binding，用于新泛型接口的静态信息；}

 @item{@racket[id]@racketidfont{?} 作为谓词，用于识别实现此泛型组的结构类型的实例；以及}

 @item{每个 @racket[method-id] 作为 @deftech{泛型方法}，在 @racket[id]@racketidfont{?} 为真的值上调用对应的方法。
       每个 @racket[method-id] 的 @racket[kw-formals*] 必须包含一个必需的按位置参数，该参数与 @racket[id] @racket[free-identifier=?]。该参数用于在泛型定义中定位特化实现。}

 @item{@racket[id]@racketidfont{/c} 作为 contract 组合子，用于识别实现 @racketidfont{gen:}@racket[id] 泛型接口的结构类型的实例。该组合子接受 @racket[method-id] 和 contract 的对。contract 将应用于每个对应的方法实现。
       @racket[id]@racketidfont{/c} 组合子旨在用于对实现泛型接口的 struct 类型的构造过程的结果域进行 contract 约束。}

]

@racket[#:defaults] 选项最多可提供一次。
提供时，每个泛型函数在分派到泛型方法表失败时使用 @racket[default-pred?]s 分派到给定的 @deftech{默认方法}实现 @racket[default-impl]s。
@racket[default-impl]s 的语法与为 @racket[struct] 的 @racket[#:methods] 关键字提供的方法相同。

@racket[#:fast-defaults] 选项最多可提供一次。
其工作方式与 @racket[#:defaults] 相同，但 @racket[fast-pred?]s 在分派到泛型方法表之前检查。此选项旨在为分派到内置数据类型（如 list 和 vector）提供快速路径，这些数据类型与实现 @racketidfont{gen:}@racket[id] 的结构不重叠。

@racket[#:fallbacks] 选项最多可提供一次。
提供时，@racket[fallback-impl]s 定义 @deftech{回退方法}实现，用于泛型接口的任何不提供特定实现的实例。@racket[fallback-impl]s 的语法与为 @racket[struct] 的 @racket[#:methods] 关键字提供的方法相同。

@racket[#:defined-predicate] 选项最多可提供一次。
提供时，@racket[defined-pred-id] 被定义为一个过程，用于报告泛型接口的特定实例是否实现了一组给定的方法。
具体来说，如果 @racket[v] 对每个方法 @racket[name] 都有实现（不包括 @racket[#:fallbacks] 实现），则 @racket[(defined-pred-id v 'name ...)] 产生 @racket[#t]，否则产生 @racket[#f]。
此过程旨在供更高级别的 API 使用，以根据方法可用性调整其行为。

@racket[#:defined-table] 选项最多可提供一次。
提供时，@racket[defined-table-id] 被定义为一个过程，用于获取泛型接口的实例并返回一个不可变的 @tech{hash table}，该表将对应方法名的符号映射到表示该方法是否由实例实现的布尔值。此选项已弃用；请改用 @racket[#:defined-predicate]。

@racket[#:derive-property] 选项可提供任意次。
每次提供时，它通过 @racket[prop-expr] 和属性值 @racket[prop-value-expr] 指定一个 @tech{结构类型属性}。所有通过 @racket[#:methods] 实现泛型接口的结构自动使用此提供的值实现此结构类型属性。当执行 @racket[prop-value-expr] 时，每个 @racket[method-id] 都绑定到其针对该 @tech{结构类型}的特定实现。

@racket[#:requires] 选项最多可提供一次。
提供时，泛型接口的任何实例 @emph{必须}提供指定的 @racket[required-method-id]s 的实现。否则会引发 compile-time 错误。

如果值 @racket[v] 满足 @racket[id]@racketidfont{?}，则 @racket[v] 是 @racketidfont{gen:}@racket[id] 的 @deftech{泛型实例}。

如果泛型实例 @racket[v] 对在 @racket[struct] 中通过 @racket[#:methods] 提供的某个 @racket[method-id] 有对应实现，或在 @racket[define-generics] 中通过 @racket[#:defaults] 或 @racket[#:fast-defaults] 提供，
则 @racket[method-id] 是 @racket[v] 的 @deftech{已实现的泛型方法}。

如果 @racket[method-id] 不是泛型实例 @racket[v] 的已实现的泛型方法，且 @racket[method-id] 有一个回退实现，当应用于 @racket[v] 时不会引发 @racket[exn:fail:support] 异常，
则 @racket[method-id] 是 @racket[v] 的 @deftech{受支持的泛型方法}。

@history[#:changed "8.7.0.5"
         @elem{添加了 @racket[#:requires] 选项。}]

}

@defproc[(raise-support-error [name symbol?] [v any/c]) none/c]{

引发 @techlink{泛型方法}的 @racket[exn:fail:support] 异常，该方法不支持给定的 @techlink{泛型实例} @racket[v]，方法名为 @racket[name]。

@examples[#:eval evaluator
(eval:error (raise-support-error 'some-method-name '("arbitrary" "instance" "value")))
]

}

@defstruct*[(exn:fail:support exn:fail) () #:transparent]{

为不支持给定 @techlink{泛型实例}的 @techlink{泛型方法}引发。

}

@defform[(define/generic local-id method-id)]{

在与 @racket[#:methods]、@racket[#:fallbacks]、@racket[#:defaults] 或 @racket[#:fast-defaults] 关键字关联的方法定义内部使用时，将 @racket[local-id] 绑定到 @racket[method-id] 的泛型形式。此形式允许方法特化对其他值使用泛型方法（而不是局部特化）。

@racket[define/generic] 形式仅允许在以下位置使用：
@itemlist[
 @item{@racket[struct]（或 @racket[define-struct]）中的 @racket[#:methods] 规范}

 @item{@racket[define-generics] 中 @racket[#:fallbacks]、@racket[#:defaults] 或 @racket[#:fast-defaults] 的规范}
]

在其他位置使用 @racket[define/generic] 是语法错误。
}


@; Examples
@(require scribble/eval)
@(define (new-evaluator)
   (let* ([e (make-base-eval)])
     (e '(require (for-syntax racket/base)
                  racket/contract
                  racket/generic))
     e))

@(define evaluator (new-evaluator))

@examples[#:eval evaluator
(define-generics printable
  (gen-print printable [port])
  (gen-port-print port printable)
  (gen-print* printable [port] #:width width #:height [height])
  #:defaults ([string?
               (define/generic super-print gen-print)
               (define (gen-print s [port (current-output-port)])
                 (fprintf port "String: ~a" s))
               (define (gen-port-print port s)
                 @code:comment{we can call gen-print alternatively}
                 (super-print s port))
               (define (gen-print* s [port (current-output-port)]
                                   #:width w #:height [h 0])
                 (fprintf port "String (~ax~a): ~a" w h s))]))

(struct num (v)
  #:methods gen:printable
  [(define (gen-print n [port (current-output-port)])
     (fprintf port "Num: ~a" (num-v n)))
   (define (gen-port-print port n)
     (gen-print n port))
   (define (gen-print* n [port (current-output-port)]
                       #:width w #:height [h 0])
     (fprintf port "Num (~ax~a): ~a" w h (num-v n)))])

(struct string+num (v n)
  #:methods gen:printable
  [(define/generic super-print gen-print)
   (define/generic super-print* gen-print*)
   (define (gen-print b [port (current-output-port)])
     (super-print (string+num-v b) port)
     (fprintf port " ")
     (super-print (string+num-n b) port))
   (define (gen-port-print port b)
     (gen-print b port))
   (define (gen-print* b [port (current-output-port)]
                       #:width w #:height [h 0])
     (super-print* (string+num-v b) #:width w #:height h)
     (fprintf port " ")
     (super-print* (string+num-n b) #:width w #:height h))])

(define x (num 10))
(gen-print x)
(gen-port-print (current-output-port) x)
(gen-print* x #:width 100 #:height 90)

(define str "Strings are printable too!")
(gen-print str)

(define y (string+num str x))
(gen-print y)
(gen-port-print (current-output-port) y)
(gen-print* y #:width 100 #:height 90)

(define/contract make-num-contracted
  (-> number?
      (printable/c
        [gen-print (->* (printable?) (output-port?) void?)]
        [gen-port-print (-> output-port? printable? void?)]
        [gen-print* (->* (printable? #:width exact-nonnegative-integer?)
                         (output-port? #:height exact-nonnegative-integer?)
                         void?)]))
   num)

(define z (make-num-contracted 10))
(eval:error (gen-print* z #:width "not a number" #:height 5))
]

@defform[(generic-instance/c gen-id [method-id method-ctc] ...)
         #:contracts ([method-ctc contract?])]{

创建一个 contract，用于识别实现 @tech{泛型接口} @racket[gen-id] 的结构，并通过对应的 @racket[method-ctc]s 约束其指定的 @racket[method-id]s 的实现。

}

@defform[(impersonate-generics gen-id val-expr
           [method-id method-proc-expr] ...
           maybe-properties)
         #:grammar ([maybe-properties code:blank
                                      (code:line #:properties props-expr)])
         #:contracts ([method-proc-expr (any/c . -> . any/c)]
                      [props-expr (list/c impersonator-property? any/c ... ...)])]{

创建 @racket[val-expr] 的 @tech{impersonator}，其必须是实现 @tech{泛型接口} @racket[gen-id] 的结构。impersonator 将 @racket[method-proc-expr]s 的结果应用于结构对相应 @racket[method-id]s 的实现，并用结果替换方法实现。

@racket[props-expr] 可提供要附加到 impersonator 的属性。@racket[props-expr] 的结果必须是一个元素个数为偶数的列表，其中第一个元素是 impersonator 属性，第二个元素是其值，依此类推。

@history[#:changed "6.1.1.8" @elem{添加了 @racket[#:properties]。}]}


@defform[(chaperone-generics gen-id val-expr
           [method-id method-proc-expr] ...
           maybe-properties)]{

类似于 @racket[impersonate-generics]，但创建 @racket[val-expr] 的 @tech{chaperone}，其必须是实现 @tech{泛型接口} @racket[gen-id] 的结构。chaperone 将指定的 @racket[method-proc]s 应用于结构对相应 @racket[method-id]s 的实现，并用结果（必须是原实现的 chaperone）替换方法实现。

}

@defform[(redirect-generics mode gen-id val-expr
            [method-id method-proc-expr] ...
            maybe-properties)]{

类似于 @racket[impersonate-generics]，但如果 @racket[mode] 求值为 @racket[#f]，则创建 @racket[val-expr] 的 @tech{impersonator}，否则创建 @racket[val-expr] 的 @tech{chaperone}。

}

@defform[(make-struct-type-property/generic
           name-expr
           maybe-guard-expr
           maybe-supers-expr
           maybe-can-impersonate?-expr
           property-option
           ...)
  #:grammar
  ([maybe-guard-expr (code:line) guard-expr]
   [maybe-supers-expr (code:line) supers-expr]
   [maybe-can-impersonate?-expr (code:line) can-impersonate?-expr]
   [property-option (code:line #:property prop-expr val-expr)
                    (code:line #:methods gen:name-id method-defs)]
   [method-defs (definition ...)])
  #:contracts
  ([name-expr symbol?]
   [guard-expr (or/c procedure? #f 'can-impersonate)]
   [supers-expr (listof (cons/c struct-type-property? (-> any/c any/c)))]
   [can-impersonate?-expr any/c]
   [prop-expr struct-type-property?]
   [val-expr any/c])]{
创建一个新的结构类型属性并返回三个值，就像 @racket[make-struct-type-property] 一样：

@itemize[
 @item{一个 @tech{结构类型属性描述符}}
 @item{一个 @tech{属性谓词}过程}
 @item{一个 @tech{属性访问器}过程}
]

任何实现此属性的 struct 也将实现 @racket[#:property] 和 @racket[#:methods] 声明中给定的属性和 @tech{泛型接口}。属性 @racket[val-expr]s 和 @racket[method-def]s 在属性创建时立即求值，而不是在附加到结构类型时。
}

@defform[(make-generic-struct-type-property
            gen:name-id
            method-def
            ...)]{
创建一个新的结构类型属性并返回 @tech{结构类型属性描述符}。

任何实现此属性的 struct 也将通过给定的 @racket[method-def]s 实现 @racket[gen:name-id] 给定的 @tech{泛型接口}。@racket[method-def]s 在属性创建时立即求值，而不是在附加到结构类型时。
}

@close-eval[evaluator]
