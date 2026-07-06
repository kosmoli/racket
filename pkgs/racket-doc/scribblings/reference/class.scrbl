#lang scribble/doc
@(require "mz.rkt"
          racket/class
          (for-syntax racket/base racket/serialize racket/trait)
          (for-label racket/serialize
                     racket/trait))

@(begin

(define-syntax sees
  (syntax-rules ()
    [(_) ""]
    [(_ s) (elem " and " (secref s))]
    [(_ s ... s0) (elem (elem ", " (secref s)) ... ", and " (secref s0))]))

(define-syntax (defclassforms stx)
  (syntax-case stx (*)
    [(_ [* (form ...) (also ...) more ...])
     #'(defform* (form  ...)
         "See " @racket[class*] (sees also ...) "; use"
         " outside the body of a " @racket[class*] " form is a syntax error."
         more ...)]
    [(_ [form (also ...) more ...])
     #'(defclassforms [* (form) (also ...) more ...])]
    [(_ form ...)
     #'(begin (defclassforms form) ...)]))

(define-syntax (defstarshorthands stx)
  (syntax-case stx ()
    [(_ form)
     (with-syntax ([name (string->symbol
                           (let ([s (symbol->string (syntax-e #'form))])
                             (substring s 0 (sub1 (string-length s)))))]
                   [tmpl (let ([s #'(... (thing (id expr) ...))])
                           (datum->syntax s
                                          (cons (datum->syntax
                                                 #'form
                                                 (syntax-e #'form)
                                                 (car (syntax-e s)))
                                                (cdr (syntax-e s)))
                                          s))])
       #'(...
          (defform tmpl
            "Shorthand for " (racket (begin (#,(racket name) id) ... (define id _expr) ...)) ".")))]
     [(_ form ...)
      #'(begin (defstarshorthands form) ...)]))

(define-syntax (defdefshorthands stx)
  (syntax-case stx ()
    [(_ form)
     (with-syntax ([name (string->symbol
                          (let ([s (symbol->string (syntax-e #'form))])
                            (string-append "define/" s)))])
       (with-syntax ([tmpl1 (let ([s #'(define id expr)])
                              (datum->syntax s
                                             (cons (datum->syntax
                                                    #'form
                                                    (syntax-e #'name)
                                                    (car (syntax-e s)))
                                                   (cdr (syntax-e s)))
                                             s))])
         #'(...
            (defform* [tmpl1 (#,(racket name) (id . formals) body ...+)]
              "Shorthand for "
              (racket (begin (#,(racket form) id) (define id expr)))
              " or "
              (racket (begin (#,(racket form) id) (define (id . formals) body ...+)))))))]
     [(_ form ...)
      #'(begin (defdefshorthands form) ...)]))

(define class-eval (make-base-eval))
(define class-ctc-eval (make-base-eval))

)

@examples[#:hidden #:eval class-eval
          (require racket/class racket/contract)]
@examples[#:hidden #:eval class-ctc-eval
          (require racket/class racket/contract)]

@title[#:tag "mzlib:class" #:style 'toc]{类与对象}

@guideintro["classes"]{类与对象}

@note-lib[racket/class #:use-sources (racket/private/class-internal)]

一个 @deftech{class} 指定以下内容：

@itemize[
 
 @item{一组 field；}

 @item{一组 method；}

 @item{field 的初始值表达式；以及}

 @item{绑定到初始化参数的初始化变量。}

]

在 class 系统的上下文中，@defterm{object} 是根据 class 描述实例化的 field 绑定集合。

class 系统允许程序使用继承、覆盖和增强，基于已有 class(@deftech{superclass})来定义新的 class(@deftech{derived class})：

@itemize[

 @item{@deftech{inheritance}：派生 class 的 object 支持派生 class 的 superclass 声明的 method 和实例化 field，以及派生 class 表达式中声明的 method 和 field。}

 @item{@deftech{overriding}：superclass 中声明的某些 method 可以在派生 class 中被替换。superclass 中对被覆盖 method 的引用使用派生 class 中的实现。}

 @item{@deftech{augmenting}：superclass 中声明的某些 method 可以仅在派生 class 中被扩展。superclass method 显式地委托给派生 class 中的增强 method。}

]

@deftech{interface} 是一组需要由 class 实现的 method 名称，可能带有某些 method 的默认实现，并附带一个 @deftech{derivation requirement}。 A
class @deftech{implements} an interface when it

@itemize[

 @item{为 interface 中的每个 method(在 interface 中没有实现的那些)声明(或继承)一个 public method；}

 @item{派生自该 interface 所要求的 class(如果有)；并且}

 @item{显式声明其实现该 interface 的意图。}

]

一个 class 可以实现任意数量的 interface。派生 class 自动实现其 superclass 所实现的任何 interface。每个 class 还实现一个与 class 关联的隐式定义的 interface。该隐式定义的 interface 包含该 class 的所有 public method 名称，并要求该 interface 的所有其他实现都派生自该 class。当某个 class 实现了一个 interface，但没有显式声明对在 interface 中有默认实现的 method 的实现时，则使用该默认实现。

一个新的 interface 可以 @deftech{extend} 一个或多个 interface 并添加额外的 method 名称；每个实现扩展后 interface 的 class 也实现原始 interface。原始 interface 的 derivation requirement 必须是一致的，扩展后的 interface 继承原始 interface 中最具体的 derivation requirement。

class、object 和 interface 都是值。然而，class 或 interface 不是 object(即不存在"元类"或"元接口")。

@local-table-of-contents[]

@; ------------------------------------------------------------------------

@section[#:tag "createinterface"]{创建 Interface}

@guideintro["classes"]{class、object 与 interface}

@defform/subs[(interface (super-interface-expr ...) name-clause ...)
              ([name-clause
                id
                (id contract-expr)
                (id #:public default-expr)
                (id #:override default-expr)
                (id contract-expr #:public impl-expr)
                (id contract-expr #:override impl-expr)])]{

创建一个 interface。@racket[id] 必须互不相同。

当 @racket[interface] 表达式被求值时，每个 @racket[super-interface-expr](按顺序)被求值。每个 @racket[super-interface-expr] 的结果必须是 interface 值，否则 @exnraise[exn:fail:object]。@racket[super-interface-expr] 返回的 interface 是新 interface 的 superinterface，它们全部被新的 interface 扩展。任何实现新 interface 的 class 也实现所有 superinterface。

@racket[interface] 表达式的结果是一个 interface，包含所有指定的 @racket[id] 以及所有 superinterface 中的标识符。给定的 @racket[id] 可以配有一个对应的 @racket[contract-expr]，也可以有一个 @racket[impl-expr]，后者提供 @racket[id] 的实现，供实现类继承或覆盖。每个 @racket[impl-expr] 必须是 @racket[_method-procedure]；参见 @secref["clmethoddefs"]。superinterface 之间的重复标识符名称将被忽略，只要对源自不同 interface 的每个标识符，其中不超过一个提供默认实现。

如果没有任何 superinterface 有某个 method 的实现，interface 可以使用 @racket[#:public] 提供该 method 的实现，否则使用 @racket[#:override]。如果多个 superinterface 对源自不同祖先 interface 的 method 提供了实现，则该 method 必须被覆盖。在 interface method 实现中不支持 @racket[super] 形式。

如果没有提供 @racket[super-interface-expr]，则结果 interface 的 @tech{derivation requirement} 是平凡的：实现该 interface 的任何 class 必须派生自 @racket[object%]。否则，结果 interface 的实现要求是其 superinterface 中最具体的要求。如果 superinterface 指定了不一致的 @tech{derivation requirements}，则引发 @exnraise[exn:fail:object]。

@examples[
#:eval class-ctc-eval
#:no-prompt
(define file-interface<%>
  (interface ()
    open close read-byte write-byte
    [append-line
     #:public
     (λ (bts)
       (send this open 'append)
       (for ([b (in-bytes bts)])
         (send this write-byte b))
       (send this close))]))
(define directory-interface<%>
  (interface (file-interface<%>)
    [file-list (->m (listof (is-a?/c file-interface<%>)))]
    parent-directory))
]

@history[#:changed "8.17.0.4" @elem{Added support for @racket[#:public]
                                    and @racket[#:override] method
                                    implementations.}]}

@defform/subs[(interface* (super-interface-expr ...)
                          ([property-expr val-expr] ...)
                name-clause ...)
              ([name-clause
                id
                (id contract-expr)
                (id #:public default-expr)
                (id #:override default-expr)
                (id contract-expr #:public default-expr)
                (id contract-expr #:override default-expr)])]{

类似于 @racket[interface]，但还将 @racket[property-expr] 生成的 structure-type property 与对应的 @racket[val-expr] 关联到该 interface。

每当生成的 interface(或派生自它的子 interface)通过 @racket[class*] 形式被 class 显式实现时，每个 property 及其值会附加到一个 structure type 上，该 structure type 由 class 的实例来实例化。具体来说，property 附加到一个具有零个直接 field 的 structure type 上，该 structure type 被扩展以生成 class 实例的内部 structure type(这样一来 structure type property 的 guard(如果有)就无法访问关于 field 的信息)。

@examples[
#:eval class-eval
#:no-prompt
(define i<%> (interface* () ([prop:custom-write
                              (lambda (obj port mode) (void))])
               method1 method2 method3))
]

@history[#:changed "8.17.0.4" @elem{Added support for @racket[#:public] and
                                    @racket[#:override] method
                                    implementations.}]}

@; ------------------------------------------------------------------------

@section[#:tag "createclass"]{创建 Class}

@guideintro["classes"]{类与对象}

@defthing[object% class?]{

一个内置 class，没有 method 或 field，只实现其自身的 interface @racket[(class->interface object%)]，并且是透明的(即其 inspector 为 @racket[#f]，因此所有直接实例都是 @racket[equal?])。所有其他 class 都派生自 @racket[object%]。}


@defform/subs[
#:literals (inspect init init-field field inherit-field init-rest init-rest
            public pubment public-final override override-final overment augment augride
            augment-final private abstract inherit inherit/super inherit/inner
            rename-super rename-inner begin lambda case-lambda let-values letrec-values
            define-values #%plain-lambda chaperone-procedure)
(class* superclass-expr (interface-expr ...)
  class-clause
  ...)
([class-clause
  (inspect inspector-expr)
  (init init-decl ...)
  (init-field init-decl ...)
  (field field-decl ...)
  (inherit-field maybe-renamed ...)
  (init-rest id)
  (init-rest)
  (public maybe-renamed ...)
  (pubment maybe-renamed ...)
  (public-final maybe-renamed ...)
  (override maybe-renamed ...)
  (overment maybe-renamed ...)
  (override-final maybe-renamed ...)
  (augment maybe-renamed ...)
  (augride maybe-renamed ...)
  (augment-final maybe-renamed ...)
  (private id ...)
  (abstract id ...)
  (inherit maybe-renamed ...)
  (inherit/super maybe-renamed ...)
  (inherit/inner maybe-renamed ...)
  (rename-super renamed ...)
  (rename-inner renamed ...)
  method-definition
  definition
  expr
  (begin class-clause ...)]

[init-decl
  id
  (renamed)
  (maybe-renamed default-value-expr)]

[field-decl
  (maybe-renamed default-value-expr)]

[maybe-renamed
  id
  renamed]

[renamed
  (internal-id external-id)]

[method-definition
  (define-values (id) method-procedure)]

[method-procedure
  (lambda kw-formals expr ...+)
  (case-lambda (formals expr ...+) ...)
  (#%plain-lambda formals expr ...+)
  (let-values ([(id) method-procedure] ...)
    method-procedure)
  (letrec-values ([(id) method-procedure] ...)
    method-procedure)
  (let-values ([(id) method-procedure] ...+) 
    id)
  (letrec-values ([(id) method-procedure] ...+) 
    id)
  (chaperone-procedure method-procedure wrapper-proc
                       other-arg-expr ...)])]{

创建一个 class 值。

@racket[superclass-expr] 表达式在 @racket[class*] 表达式被求值时求值。结果必须是 class 值(可能是 @racket[object%])，否则 @exnraise[exn:fail:object]。@racket[superclass-expr] 表达式的结果是新 class 的 superclass。

@racket[interface-expr] 表达式也在 @racket[class*] 表达式被求值时求值，在 @racket[superclass-expr] 求值之后。每个 @racket[interface-expr] 的结果必须是 interface 值，否则 @exnraise[exn:fail:object]。@racket[interface-expr] 返回的 interface 全部被 class 实现。对于每个 interface 中的每个标识符，class(或其祖先之一)必须声明一个同名的 public method，否则 @exnraise[exn:fail:object]。class 的 superclass 必须满足每个 interface 的实现要求，否则 @exnraise[exn:fail:object]。

@racket[inspect] 子句为 class 扩展选择一个 inspector(参见 @secref["inspectors"])。当 @racket[class*] 形式被求值时，@racket[inspector-expr] 必须求值为一个 inspector 或 @racket[#f]。与 structure type 一样，inspector 控制对 class field(包括 private field)的访问，也会影响使用 @racket[equal?] 的比较。如果没有提供 @racket[inspect] 子句，对 class 的访问由当前 inspector 的父级控制(参见 @secref["inspectors"])。如果指定了多个 @racket[inspect] 子句，则报告语法错误。

其他 @racket[class-clause] 定义初始化参数、public 和 private field，以及 public 和 private method。对于 @racket[public]、@racket[override]、@racket[augment]、@racket[pubment]、@racket[overment]、@racket[augride]、@racket[public-final]、@racket[override-final]、@racket[augment-final] 或 @racket[private] 子句中的每个 @racket[id] 或 @racket[maybe-renamed]，必须有一个 @racket[method-definition]。所有其他定义性 @racket[class-clause] 创建 private field。所有剩余的 @racket[expr] 是初始化表达式，在 class 被实例化时求值(参见 @secref["objcreation"])。

@racket[class*] 表达式的结果是一个新的 class，派生自指定的 superclass 并实现指定的 interface。class 的实例使用 @racket[instantiate] 形式或 @racket[make-object] 过程创建，如 @secref["objcreation"] 中所述。

每个 @racket[class-clause] 会被(部分)macro 展开以揭示其形状。如果 @racket[class-clause] 是 @racket[begin] 表达式，其子表达式会从 @racket[begin] 中提升出来并作为 @racket[class-clause] 处理，就像 @racket[begin] 对顶层定义和嵌套定义进行扁平化处理一样。每个 @racket[class-clause] 在展开前，其 @tech{syntax property} @racket['class-body] 被设置为 true。

在新 class 实例的 @racket[class*] 形式中，@racket[this] 绑定到 object 本身；@racket[this%] 绑定到该 object 的 class；@racket[super-instantiate]、@racket[super-make-object] 和 @racket[super-new] 绑定到用于初始化 superclass 中 field 的形式(参见 @secref["objcreation"])；@racket[super] 可用于调用 superclass method(参见 @secref["clmethoddefs"])；@racket[inner] 可用于调用 subclass 对 method 的增强(参见 @secref["clmethoddefs"])。}

@history[#:changed "8.8.0.10"
         @elem{Added the @racket['class-body] syntax property
          to class body forms.}]

@defform[(class superclass-expr class-clause ...)]{

类似于 @racket[class*]，但省略 @racket[_interface-expr]，适用于不需要 interface 的情况。

@examples[
#:eval class-eval
#:no-prompt
(define book-class%
  (class object%
    (field (pages 5))
    (define/public (letters)
      (* pages 500))
    (super-new)))
]}

@defidform[this]{

@index['("self")]{在} @racket[class*] 形式中，@racket[this] 引用当前 object(即正在初始化的 object 或其 method 被调用的 object)。在 @racket[class*] 形式外部使用会导致语法错误。

@examples[
#:eval class-eval
(eval:no-prompt
 (define (describe obj)
   (printf "Hello ~a\n" obj))
 (define table%
   (class object%
     (define/public (describe-self)
       (describe this))
     (super-new))))
(send (new table%) describe-self)
]}

@defidform[this%]{
                  
在 @racket[class*] 形式中，@racket[this%] 引用当前 object 的 class(即正在初始化的 object 或其 method 被调用的 object 的 class)。在 @racket[class*] 形式外部使用会导致语法错误。

@examples[
#:eval class-eval
(eval:no-prompt
 (define account%
   (class object% 
     (super-new)
     (init-field balance)
     (define/public (add n)
       (new this% [balance (+ n balance)]))))
 (define savings%
   (class account%
     (super-new)
     (inherit-field balance)
     (define interest 0.04)
     (define/public (add-interest)
       (send this add (* interest balance))))))
(let* ([acct (new savings% [balance 500])]
       [acct (send acct add 500)]
       [acct (send acct add-interest)])
  (printf "Current balance: ~a\n" (get-field balance acct)))
]}

@defclassforms[
  [(inspect inspector-expr) ()]
  [(init init-decl ...) ("clinitvars")
   @examples[#:eval class-eval
     (class object%
       (super-new)
       (init turnip
             [(internal-potato potato)]
             [carrot 'good]
             [(internal-rutabaga rutabaga) 'okay]))]]
  [(init-field init-decl ...) ("clinitvars" "clfields")
   @examples[#:eval class-eval
     (class object%
       (super-new)
       (init-field turkey
                   [(internal-ostrich ostrich)]
                   [chicken 7]
                   [(internal-emu emu) 13]))]]
  [(field field-decl ...) ("clfields")
   @examples[#:eval class-eval
     (class object%
       (super-new)
       (field [minestrone 'ready]
              [(internal-coq-au-vin coq-au-vin) 'stewing]))]]
  [(inherit-field maybe-renamed ...) ("clfields")
   @examples[#:eval class-eval
     (eval:no-prompt
      (define cookbook%
        (class object%
          (super-new)
          (field [recipes '(caldo-verde oyakodon eggs-benedict)]
                 [pages 389]))))
     (class cookbook%
       (super-new)
       (inherit-field recipes
                      [internal-pages pages]))]]
  [* ((init-rest id) (init-rest)) ("clinitvars")
   @examples[#:eval class-eval
     (eval:no-prompt
      (define fruit-basket%
        (class object%
          (super-new)
          (init-rest fruits)
          (displayln fruits))))
     (make-object fruit-basket% 'kiwi 'lychee 'melon)]]
  [(public maybe-renamed ...) ("clmethoddefs")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define jumper%
         (class object%
           (super-new)
           (define (skip) 'skip)
           (define (hop) 'hop)
           (public skip [hop jump]))))
      (send (new jumper%) skip)
      (send (new jumper%) jump)]]
  [(pubment maybe-renamed ...) ("clmethoddefs")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define runner%
         (class object%
           (super-new)
           (define (run) 'run)
           (define (trot) 'trot)
           (pubment run [trot jog]))))
      (send (new runner%) run)
      (send (new runner%) jog)]]
  [(public-final maybe-renamed ...) ("clmethoddefs")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define point%
         (class object%
           (super-new)
           (init-field [x 0] [y 0])
            (define (get-x) x)
           (define (do-get-y) y)
           (public-final get-x [do-get-y get-y]))))
      (send (new point% [x 1] [y 3]) get-y)
      (eval:error
       (class point%
         (super-new)
         (define (get-x) 3.14)
         (override get-x)))]]
  [(override maybe-renamed ...) ("clmethoddefs")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define sheep%
         (class object%
           (super-new)
           (define/public (bleat)
             (displayln "baaaaaaaaah")))))
      (eval:no-prompt
       (define confused-sheep%
         (class sheep%
           (super-new)
           (define (bleat)
             (super bleat)
             (displayln "???"))
           (override bleat))))
      (send (new sheep%) bleat)
      (send (new confused-sheep%) bleat)]]
  [(overment maybe-renamed ...) ("clmethoddefs")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define turkey%
         (class object%
           (super-new)
           (define/public (gobble)
             (displayln "gobble gobble")))))
      (eval:no-prompt
       (define extra-turkey%
         (class turkey%
           (super-new)
           (define (gobble)
             (super gobble)
             (displayln "gobble gobble gobble")
             (inner (void) gobble))
           (overment gobble))))
      (eval:no-prompt
       (define cyborg-turkey%
         (class extra-turkey%
           (super-new)
           (define/augment (gobble)
             (displayln "110011111011111100010110001011011001100101")))))
      (send (new extra-turkey%) gobble)
      (send (new cyborg-turkey%) gobble)]]
  [(override-final maybe-renamed ...) ("clmethoddefs")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define meeper%
         (class object%
           (super-new)
           (define/public (meep)
             (displayln "meep")))))
      (eval:no-prompt
       (define final-meeper%
         (class meeper%
           (super-new)
           (define (meep)
             (super meep)
             (displayln "This meeping ends with me"))
           (override-final meep))))
      (send (new meeper%) meep)
      (send (new final-meeper%) meep)]]
  [(augment maybe-renamed ...) ("clmethoddefs")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define buzzer%
         (class object%
           (super-new)
           (define/pubment (buzz)
             (displayln "bzzzt")
             (inner (void) buzz)))))
      (eval:no-prompt
       (define loud-buzzer%
         (class buzzer%
           (super-new)
           (define (buzz)
             (displayln "BZZZZZZZZZT"))
           (augment buzz))))
      (send (new buzzer%) buzz)
      (send (new loud-buzzer%) buzz)]]
  [(augride maybe-renamed ...) ("clmethoddefs")]
  [(augment-final maybe-renamed ...) ("clmethoddefs")]
  [(private id ...) ("clmethoddefs")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define light%
         (class object%
           (super-new)
           (define on? #t)
           (define (toggle) (set! on? (not on?)))
           (private toggle)
           (define (flick) (toggle))
           (public flick))))
      (eval:error (send (new light%) toggle))
      (send (new light%) flick)]]
  [(abstract id ...) ("clmethoddefs")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define train%
         (class object%
           (super-new)
           (abstract get-speed)
           (init-field [position 0])
           (define/public (move)
             (new this% [position (+ position (get-speed))])))))
      (eval:no-prompt
       (define acela%
         (class train%
           (super-new)
           (define/override (get-speed) 241))))
      (eval:no-prompt
       (define talgo-350%
         (class train%
           (super-new)
           (define/override (get-speed) 330))))
      (eval:error (new train%))
      (send (new acela%) move)]]
  [(inherit maybe-renamed ...) ("classinherit")
    @examples[#:eval class-eval
      (eval:no-prompt
       (define alarm%
         (class object%
           (super-new)
           (define/public (alarm)
             (displayln "beeeeeeeep")))))
      (eval:no-prompt
       (define car-alarm%
         (class alarm%
           (super-new)
           (init-field proximity)
           (inherit alarm)
           (when (< proximity 10)
             (alarm)))))
      (new car-alarm% [proximity 5])]]
  [(inherit/super maybe-renamed ...)  ("classinherit")]
  [(inherit/inner maybe-renamed ...) ("classinherit")]
  [(rename-super renamed ...) ("classinherit")]
  [(rename-inner renamed ...) ("classinherit")]
]

@defstarshorthands[
 public* 
 pubment*
 public-final*
 override*
 overment*
 override-final*
 augment*
 augride*
 augment-final*
 private*
]

@defdefshorthands[
 public pubment public-final override
 overment override-final augment augride
 augment-final private
]


@defform[
(class/derived original-datum
  (name-id super-expr (interface-expr ...) deserialize-id-expr)
  class-clause
  ...)
]{

类似于 @racket[class*]，但包含一个子表达式，用作 class 定义中所有语法错误的来源。例如，@racket[define-serializable-class] 展开为 @racket[class/derived]，这样 class 体中的错误会以 @racket[define-serializable-class] 而非 @racket[class] 的形式报告。

@racket[original-datum] 是用于报告错误的原始表达式。

@racket[name-id] 用于命名结果 class；如果为 @racket[#f]，class 名称会被推断。

@racket[super-expr]、@racket[interface-expr] 和 @racket[class-clause] 与 @racket[class*] 的相同。

如果 @racket[deserialize-id-expr] 不是字面的 @racket[#f]，则生成一个可序列化的 class，结果是两个值而不是一个：class 和由 @racket[make-deserialize-info] 生成的 deserialize-info structure。@racket[deserialize-id-expr] 应产生一个适合作为 @racket[make-serialize-info] 第二个参数的值，并且它应引用一个其值为 deserialize-info structure 的导出。

未来可选的 form 可能被添加到当前以 @racket[deserialize-id-expr] 结尾的序列中。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsection[#:tag "clinitvars"]{初始化变量}

class 的初始化变量通过 @racket[init]、@racket[init-field] 和 @racket[init-rest] 声明，为 class 的每个 object 实例化。初始化变量可以在 field 的初始值表达式、初始化参数的默认值表达式以及初始化表达式中使用。只有用 @racket[init-field] 声明的初始化变量才能从 method 中访问；从 method 中访问任何其他初始化变量是语法错误。

绑定到初始化变量的值是：

@itemize[

 @item{使用 @racket[instantiate] 提供的参数或传递给 @racket[make-object] 的参数，如果 object 作为 class 的直接实例创建；或者，}

 @item{传递给 superclass 初始化 form 或过程的参数，如果 object 作为派生 class 的实例创建。}

]

如果某个初始化变量有关联的 @racket[_default-value-expr] 但没有提供初始化参数，则求值 @racket[_default-value-expr] 表达式以获取该变量的值。@racket[_default-value-expr] 仅在其变量没有提供参数时求值。@racket[_default-value-expr] 的环境包括所有初始化变量、所有 field 以及 class 的所有 method。如果求值多个 @racket[_default-value-expr]，它们从左到右求值。object 创建和 field 初始化在 @secref["objcreation"] 中详细描述。

如果某个初始化变量没有 @racket[_default-value-expr]，则 object 创建或 superclass 初始化调用必须为该变量提供参数，否则 @exnraise[exn:fail:object]。

初始化参数可以按名称或按位置提供。初始化变量的外部名称可以用于 @racket[instantiate] 或 superclass 初始化 form。这些 form 也接受按位置参数。@racket[make-object] 过程和 superclass 初始化过程仅接受按位置参数。

按位置提供的参数使用 @racket[init] 和 @racket[init-field] 子句的顺序以及每个子句内变量的顺序转换为按名称参数。当 @racket[instantiate] 形式同时提供按位置和按名称参数时，转换后的参数放在按名称参数之前。(顺序可能很重要；另请参见 @secref["objcreation"]。)

除非 class 包含 @racket[init-rest] 子句，否则当按位置参数的数量超过声明的初始化变量数量时，superclass(以及沿 superclass 链向上)中变量的顺序决定按名称转换。

如果 class 表达式包含 @racket[init-rest] 子句，则必须只有一个，且必须是最后一个。如果它声明了一个变量，则该变量以 list 形式接收额外的按位置初始化参数(类似于过程中的"rest argument")。@racket[init-rest] 变量可以接收派生 class 的按名称转换中剩余的按位置初始化参数。当派生 class 的 superclass 初始化提供更多按位置参数时，它们会被添加到迄今为止累积的按位置参数之前。

如果向 object 创建或 superclass 初始化提供了过少或过多的按位置初始化参数，则 @exnraise[exn:fail:object]。类似地，如果向具有 @racket[init-rest] 子句的 class 提供了额外的按位置参数，则 @exnraise[exn:fail:object]。

未使用的(按名称)参数将被传播到 superclass，如 @secref["objcreation"] 中所述。如果 class 派生中包含多个(在不同 class 中)具有相同名称的初始化变量声明，则多个初始化参数可以使用相同的名称。更多细节请参见 @secref["objcreation"]。

关于内部和外部名称的信息，另请参见 @secref["extnames"]。

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsection[#:tag "clfields"]{Field}

class 中的每个 @racket[field]、@racket[init-field] 和非 method 的 @racket[define-values] 子句为 class 声明一个或多个新的 field。使用 @racket[field] 或 @racket[init-field] 声明的 field 是 public 的。public field 可以由 subclass 使用 @racket[inherit-field] 访问和修改。public field 也可以通过 @racket[class-field-accessor] 在 class 外部访问，通过 @racket[class-field-mutator] 修改(参见 @secref["ivaraccess"])。使用 @racket[define-values] 声明的 field 只能在 class 内部访问。

使用 @racket[init-field] 声明的 field 既是 public field 也是初始化变量。关于初始化变量的信息，请参见 @secref["clinitvars"]。

@racket[inherit-field] 声明使 superclass 定义的 public field 在 class 表达式中可以直接访问。如果指定的 field 没有在 superclass 中定义，求值 class 表达式时 @exnraise[exn:fail:object]。superclass 中的每个 field 都存在于派生 class 中，即使它没有在派生 class 中用 @racket[inherit-field] 声明。@racket[inherit-field] 子句不控制继承，仅控制 class 表达式内的词法作用域。

当 object 初次创建时，其所有 field 都具有 @|undefined-const| 值(参见 @secref["void"])。class 的 field 在与 class 的初始化表达式求值的同一时间被初始化；更多信息请参见 @secref["objcreation"]。

关于内部和外部名称的信息，另请参见 @secref["extnames"]。

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsection[#:tag "clmethods"]{Method}

@subsubsection[#:tag "clmethoddefs"]{Method 定义}

class 中的每个 @racket[public]、@racket[override]、@racket[augment]、@racket[pubment]、@racket[overment]、@racket[augride]、@racket[public-final]、@racket[override-final]、@racket[augment-final] 和 @racket[private] 子句声明一个或多个 method 名称。每个 method 名称必须有对应的 @racket[_method-definition]。@racket[public]、@|etc| 子句及其对应定义的顺序(在它们之间，以及相对于 class 中的其他子句)不重要。

如 @racket[class*] 的语法所示，method 定义在语法上限于某些 procedure form，如 @racket[_method-procedure] 的语法所定义；在 @racket[_method-procedure] 的最后两种形式中，body @racket[id] 必须是由 @racket[let-values] 或 @racket[letrec-values] 绑定的 @racket[id] 之一。@racket[_method-procedure] 表达式不会直接被求值。相反，对于每个 method，会创建一个特定于 class 的 method procedure；它接受一个初始 object 参数，此外还接受如果直接求值 @racket[_method-procedure] 表达式该 procedure 将接受的参数。procedure 的 body 会被转换，以通过 object 参数访问 method 和 field。

使用 @racket[public]、@racket[pubment] 或 @racket[public-final] 声明的 method 向 class 中引入一个新 method。该 method 必须尚未存在于 superclass 中，也不应在任何 superinterface 中有实现，否则求值 class 表达式时 @exnraise[exn:fail:object]。使用 @racket[public] 声明的 method 可以在使用 @racket[override]、@racket[overment] 或 @racket[override-final] 的 subclass 中被覆盖。使用 @racket[pubment] 声明的 method 可以在使用 @racket[augment]、@racket[augride] 或 @racket[augment-final] 的 subclass 中被增强。使用 @racket[public-final] 声明的 method 不能在 subclass 中被覆盖或增强。

使用 @racket[override]、@racket[overment] 或 @racket[override-final] 声明的 method 覆盖 superclass 或 superinterface 中已经存在的定义。如果该 method 尚不存在，求值 class 表达式时 @exnraise[exn:fail:object]。使用 @racket[override] 声明的 method 可以在使用 @racket[override]、@racket[overment] 或 @racket[override-final] 的 subclass 中再次被覆盖。使用 @racket[overment] 声明的 method 可以在使用 @racket[augment]、@racket[augride] 或 @racket[augment-final] 的 subclass 中被增强。使用 @racket[override-final] 声明的 method 不能在 subclass 中进一步被覆盖或增强。

使用 @racket[augment]、@racket[augride] 或 @racket[augment-final] 声明的 method 增强 superclass 中已经存在的定义。如果该 method 尚不存在，求值 class 表达式时 @exnraise[exn:fail:object]。使用 @racket[augment] 声明的 method 可以在使用 @racket[augment]、@racket[augride] 或 @racket[augment-final] 的 subclass 中进一步被增强。使用 @racket[augride] 声明的 method 可以在使用 @racket[override]、@racket[overment] 或 @racket[override-final] 的 subclass 中被覆盖。(这种覆盖仅替换增强，而不是被增强的 method。)使用 @racket[augment-final] 声明的 method 不能在 subclass 中进一步被覆盖或增强。

使用 @racket[private] 声明的 method 在 class 表达式外部不可访问，不能被覆盖，也永远不会覆盖 superclass 中的 method。

当 method 使用 @racket[override]、@racket[overment] 或 @racket[override-final] 声明时，可以使用 @racket[super] 形式调用该 method 的 superclass 或 superinterface 实现。如果多个 superinterface 提供了被覆盖 method 的实现，则在求值时 @racket[super] 会引发 @racket[exn:fail:object]。

当 method 使用 @racket[pubment]、@racket[augment] 或 @racket[overment] 声明时，可以使用 @racket[inner] 形式调用 subclass 增强 method。@racket[public-final] 和没有对应 @racket[inner] 的 @racket[pubment] 之间的唯一区别是，@racket[public-final] 阻止声明会被忽略的增强 method。

使用 @racket[abstract] 声明的 method 必须在没有实现的情况下声明。subclass 可以通过 @racket[override]、@racket[overment] 或 @racket[override-final] 形式实现 abstract method。任何包含或继承任何 abstract method 的 class 被视为 abstract，不能被实例化。

@defform*[[(super id arg ...)
           (super id arg ... . arg-list-expr)]]{

始终访问 superclass method 或 superinterface method，无论该方法是否在 subclass 中再次被覆盖。在 @racket[class*] 外部使用 @racket[super] 形式是语法错误。每个 @racket[arg] 与 @racket[#%app] 的相同：@racket[_arg-expr] 或 @racket[_keyword _arg-expr]。

第二种形式类似于在 procedure 上使用 @racket[apply]；@racket[arg-list-expr] 不能是带括号的表达式。}

@defform*[[(inner default-expr id arg ...)
           (inner default-expr id arg ... . arg-list-expr)]]{

如果 object 的 class 不提供增强 method，则求值 @racket[default-expr]，而 @racket[arg] 表达式不求值。否则，以 @racket[arg] 的结果作为参数调用增强 method，而 @racket[default-expr] 不求值。如果特定 method 没有求值任何 @racket[inner] 调用，则 subclass 提供的增强 method 永远不会被使用。在 @racket[class*] 外部使用 @racket[inner] 形式是语法错误。

第二种形式类似于在 procedure 上使用 @racket[apply]；@racket[arg-list-expr] 不能是带括号的表达式。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsubsection[#:tag "classinherit"]{继承和 Superclass Method}

每个 @racket[inherit]、@racket[inherit/super]、@racket[inherit/inner]、@racket[rename-super] 和 @racket[rename-inner] 子句声明一个或多个在 class 中定义但必须存在于 superclass 中的 method。@racket[rename-super] 和 @racket[rename-inner] 声明很少使用，因为 @racket[inherit/super] 和 @racket[inherit/inner] 提供相同的访问。此外，superclass 和增强 method 通常通过 @racket[super] 和 @racket[inner] 在同时声明这些 method 的 class 中访问，而不是通过 @racket[inherit/super]、@racket[inherit/inner]、@racket[rename-super] 或 @racket[rename-inner]。

使用 @racket[inherit]、@racket[inherit/super] 或 @racket[inherit/inner] 声明的 method 名称在运行时访问覆盖声明(如果有)。使用 @racket[inherit/super] 声明的 method 名称也可以与 @racket[super] 形式一起使用以访问 superclass 实现，使用 @racket[inherit/inner] 声明的 method 名称也可以与 @racket[inner] 形式一起使用以访问增强 method(如果有)。
 
使用 @racket[rename-super] 声明的 method 名称在运行时始终访问 superclass 的实现。使用 @racket[rename-inner] 声明的 method 访问 subclass 的增强 method(如果有)，并且必须使用以下形式调用

@racketblock[
(_id (lambda () _default-expr) _arg ...)
]

这样当没有增强 method 可用时，@racket[default-expr] 可供求值。在这种形式中，@racket[lambda] 是一个字面标识符，用于将 @racket[default-expr] 与 @racket[arg] 分开。当增强 method 可用时，它接收 @racket[arg] 表达式的结果作为参数。

superclass 中存在但未使用 @racket[inherit]、@racket[inherit/super]、@racket[inherit/inner] 或 @racket[rename-super] 声明的 method 在 class 中不能直接访问(尽管它们可以通过 @racket[send] 调用)。superclass 中的每个 public method 都存在于派生 class 中，即使它没有在派生 class 中用 @racket[inherit] 声明；@racket[inherit] 子句不控制继承，仅控制 class 表达式内的词法作用域。

如果使用 @racket[inherit]、@racket[inherit/super]、@racket[inherit/inner]、@racket[rename-super] 或 @racket[rename-inner] 声明的 method 不存在于 superclass 中，求值 class 表达式时 @exnraise[exn:fail:object]。

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsubsection[#:tag "extnames"]{内部和外部名称}

使用 @racket[public]、@racket[override]、@racket[augment]、@racket[pubment]、@racket[overment]、@racket[augride]、@racket[public-final]、@racket[override-final]、@racket[augment-final]、@racket[inherit]、@racket[inherit/super]、@racket[inherit/inner]、@racket[rename-super] 和 @racket[rename-inner] 声明的每个 method 在声明方法时可以使用 @racket[(internal-id external-id)] 来设置单独的内部和外部名称。内部名称用于在 class 表达式内直接访问 method(包括在 @racket[super] 或 @racket[inner] 形式中)，而外部名称与 @racket[send] 和 @racket[generic] 一起使用(参见 @secref["ivaraccess"])。如果为 method 声明提供了单个 @racket[id]，则该标识符同时用于内部和外部名称。

method 的继承、覆盖和增强仅基于外部名称。@racket[rename-super] 和 @racket[rename-inner] 需要单独的内部和外部名称(主要是历史原因)。

每个 @racket[init]、@racket[init-field]、@racket[field] 或 @racket[inherit-field] 变量同样具有内部和外部名称。内部名称在 class 内部用于访问变量，而外部名称在 class 外部用于提供初始化参数(例如传递给 @racket[instantiate])、继承 field 或外部访问 field(例如使用 @racket[class-field-accessor])。与 method 一样，当使用 @racket[inherit-field] 继承 field 时，外部名称与 superclass 中的外部 field 名称匹配，而内部名称在 @racket[class] 表达式中绑定。

单个标识符可以同时用作内部标识符和外部标识符，也可以将同一标识符用作不同绑定的内部和外部标识符。此外，在单个 class 中，单个名称可以用作外部 method 名称、外部 field 名称和外部初始化参数名称。总体而言，每个内部标识符必须与所有其他内部标识符不同，每个外部 method 名称必须与所有其他 method 名称不同，每个外部 field 名称必须与所有其他 field 名称不同，每个初始化参数名称必须与所有其他初始化参数名称不同。

默认情况下，外部名称没有词法作用域，这意味着，例如，外部 method 名称在 @racket[send] 的所有使用中匹配相同的语法符号。@racket[define-local-member-name] 和 @racket[define-member-name] 形式引入了有作用域的外部名称。

当 @racket[class] 表达式被编译时，用于替代外部名称的标识符在符号上必须不同(当相应的外部名称要求不同时)，否则报告语法错误。当没有外部名称被 @racket[define-member-name] 绑定时，实际外部名称在 @racket[class] 表达式求值时保证是不同的。当任何外部名称被 @racket[define-member-name] 绑定时，如果实际外部名称不相同，则 @racket[class] 会 @exnraise[exn:fail:object]。


@defform[(define-local-member-name id ...)]{

除非作为顶层定义出现，否则绑定每个 @racket[id]，使得在定义的范围内，每个 @racket[id] 作为外部名称的每次使用都被解析为由 @racket[define-local-member-name] 声明生成的隐藏名称。因此，使用这样的外部名称 @racket[id] 声明的 method、field 和初始化参数只能在 @racket[define-local-member-name] 声明的范围内访问。作为顶层定义，@racket[define-local-member-name] 将 @racket[id] 绑定到其符号形式。

@racket[define-local-member-name] 引入的绑定是一个 syntax binding，可以通过 @racket[module] 导出和导入。每次求值 @racket[define-local-member-name] 声明都会生成一个不同的隐藏名称(作为顶层定义时除外)。@racket[interface->method-names] 过程不暴露隐藏名称。

@examples[
#:eval class-eval
(eval:no-prompt
 (define-values (r o)
   (let ()
     (define-local-member-name m)
     (define c% (class object%
                  (define/public (m) 10)
                  (super-new)))
     (define o (new c%))
    
     (values (send o m)
             o))))

r
(eval:error (send o m))
]}


@defform[(define-member-name id key-expr)]{

将单个外部名称映射到由表达式确定的外部名称。@racket[key-expr] 的值必须是 @racket[member-name-key] 表达式或 @racket[generate-member-key] 调用的结果。}


@defform[(member-name-key identifier)]{

在 @racket[member-name-key] 表达式的环境中生成 @racket[id] 的外部名称表示。}

@defproc[(generate-member-key) member-name-key?]{

生成一个隐藏名称，就像 @racket[define-local-member-name] 的绑定一样。}

@defproc[(member-name-key? [v any/c]) boolean?]{

对于由 @racket[member-name-key] 和 @racket[generate-member-key] 生成的值返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(member-name-key=? [a-key member-name-key?] [b-key member-name-key?]) boolean?]{

如果 member-name key @racket[a-key] 和 @racket[b-key] 表示相同的外部名称，则生成 @racket[#t]，否则为 @racket[#f]。}


@defproc[(member-name-key-hash-code [a-key member-name-key?]) integer?]{

生成一个与 @racket[member-name-key=?] 比较一致的整数哈希码，类似于 @racket[equal-hash-code]。}

@examples[
#:eval class-eval
(eval:no-prompt
 (define (make-c% key)
   (define-member-name m key)
   (class object% 
     (define/public (m) 10)
     (super-new))))

(send (new (make-c% (member-name-key m))) m)
(eval:error (send (new (make-c% (member-name-key p))) m))
(send (new (make-c% (member-name-key p))) p)

(eval:no-prompt
 (define (fresh-c%)
   (let ([key (generate-member-key)])
     (values (make-c% key) key)))

 (define-values (fc% key) (fresh-c%)))

(eval:error (send (new fc%) m))
(let ()
  (define-member-name p key)
  (send (new fc%) p))
]


@; ------------------------------------------------------------------------

@section[#:tag "objcreation"]{创建 Object}

@racket[make-object] 过程使用按位置初始化参数创建新的 object，@racket[new] 形式使用按名称初始化参数创建新的 object，@racket[instantiate] 形式使用按位置和按名称初始化参数创建新的 object。


新创建的 object 中的所有 field 最初被绑定到特殊的 @|undefined-const| 值(参见 @secref["void"])。具有默认值表达式(且没有提供值)的初始化变量也被初始化为 @|undefined-const|。在参数值被赋值给初始化变量之后，@racket[field] 子句中的表达式、没有提供参数的 @racket[init-field] 子句、没有提供参数的 @racket[init] 子句、private field 定义以及其他表达式被求值。这些表达式按照它们在 class 表达式中出现的顺序从左到右求值。

在表达式求值期间的某个时刻，必须使用 @racket[super-make-object] 过程、@racket[super-new] 形式或 @racket[super-instantiate] 形式对 superclass 声明的初始化进行一次求值。

没有匹配的初始化变量的按名称初始化参数会被隐式地作为按名称参数添加到 @racket[super-make-object]、@racket[super-new] 或 @racket[super-instantiate] 调用中，位于显式参数之后。如果为同一名称提供了多个初始化参数，则使用第一个(如果有)，未使用的参数被传播到 superclass。(请注意，转换后的按位置参数始终放在显式按名称参数之前。)@racket[object%] class 的初始化过程接受零个初始化参数；如果它接收到任何按名称初始化参数，则 @exnraise[exn:fail:object]。

如果层次结构中的任何 class 在未调用 superclass 初始化的情况下到达了初始化的末尾，则 @exnraise[exn:fail:object]。此外，如果 superclass 初始化被调用超过一次，则 @exnraise[exn:fail:object]。

从 superclass 继承的 field 在 superclass 的初始化过程被调用之前不会被初始化。相比之下，所有 method 在 object 创建后立即可用；method 的覆盖不受初始化影响(与 C++ 中的 object 不同)。



@defproc[(make-object [class class?] [init-v any/c] ...) object?]{

创建 @racket[class] 的一个实例。@racket[init-v] 被作为初始化参数传递，绑定到 @racket[class] 的初始化变量，如 @secref["clinitvars"] 中所述。如果 @racket[class] 不是 class，则 @exnraise[exn:fail:contract]。}

@defform[(new class-expr (id by-name-expr) ...)]{

创建 @racket[class-expr] 值的一个实例(该值必须是 class)，每个 @racket[by-name-expr] 的值作为对应 @racket[id] 的按名称参数提供。}

@defform[(instantiate class-expr (by-pos-expr ...) (id by-name-expr) ...)]{

创建 @racket[class-expr] 值的一个实例(该值必须是 class)，@racket[by-pos-expr] 的值作为按位置初始化参数提供。此外，每个 @racket[by-name-expr] 的值作为对应 @racket[id] 的按名称参数提供。}

@defproc[(dynamic-instantiate [cls class?]
                              [pos-vs list?]
                              [named-vs (listof (cons/c symbol? any/c))])
         object?]{

类似于 @racket[(apply make-object cls pos-vs)]，但 @racket[named-vs] 除了 @racket[pos-vs] 提供的按位置参数外，还提供命名参数。

@(examples
  #:eval class-eval
  (define point% (class object%
                   (super-new)
                   (init-field x y)))
  (define p (dynamic-instantiate point% '(1) '([y . 2])))
  (eval:check (get-field x p) 1)
  (eval:check (get-field y p) 2))

@history[#:added "8.8.0.1"]}

@defidform[super-make-object]{

生成一个接受按位置参数并调用 superclass 初始化的 procedure。更多信息请参见 @secref["objcreation"]。}


@defform[(super-instantiate (by-pos-expr ...) (id by-expr ...) ...)]{


使用指定的按位置和按名称参数调用 superclass 初始化。更多信息请参见 @secref["objcreation"]。}


@defform[(super-new (id by-name-expr ...) ...)]{

使用指定的按名称参数调用 superclass 初始化。更多信息请参见 @secref["objcreation"]。}

@; ------------------------------------------------------------------------

@section[#:tag "ivaraccess"]{Field 和 Method 访问}

在 class 定义的表达式中，class 的初始化变量、field 和 method 都是环境的一部分。在 method 体内，只能引用 class 的 field 和其他 method；对任何其他 class 引入的标识符的引用是语法错误。在 class 内的其他地方，所有 class 引入的标识符都可用，field 和初始化变量可以使用 @racket[set!] 进行修改。

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@subsection[#:tag "methodcalls"]{Method}

class 内部使用的 method 名称只能用于应用程序表达式的 procedure 位置；任何其他使用都是语法错误。

为了允许 method 应用于参数列表，method 应用可以具有以下形式：

@specsubform[
(method-id arg ... . arg-list-expr)
]

这种形式以类似于 @racket[(apply _method-id _arg ... _arg-list-expr)] 的方式调用 method。@racket[arg-list-expr] 不能是带括号的表达式。

在 class 外部使用 @racket[send]、@racket[send/apply] 和 @racket[send/keyword-apply] 形式调用 method。

@defform*[[(send obj-expr method-id arg ...)
           (send obj-expr method-id arg ... . arg-list-expr)]]{

求值 @racket[obj-expr] 获取一个 object，并在该 object 上调用具有(外部)名称 @racket[method-id] 的 method，将 @racket[arg] 的结果作为参数提供。每个 @racket[arg] 与 @racket[#%app] 的相同：@racket[_arg-expr] 或 @racket[_keyword _arg-expr]。在第二种形式中，@racket[arg-list-expr] 不能是带括号的表达式。

如果 @racket[obj-expr] 没有产生 object，则 @exnraise[exn:fail:contract]。如果 object 没有名为 @racket[method-id] 的 public method，则 @exnraise[exn:fail:object]。}

@defform[(send/apply obj-expr method-id arg ... arg-list-expr)]{

类似于 @racket[send] 的 dotted 形式，但 @racket[arg-list-expr] 可以是任何表达式。}

@defform[(send/keyword-apply obj-expr method-id 
                             keyword-list-expr value-list-expr 
                             arg ... arg-list-expr)]{

类似于 @racket[send/apply]，但使用类似于 @racket[keyword-apply] 的关键字和参数列表表达式。}

@defproc[(dynamic-send [obj object?] 
                       [method-name symbol?]
                       [v any/c] ...
                       [#:<kw> kw-arg any/c] ...) any]{

在 @racket[obj] 上调用名称匹配 @racket[method-name] 的 method，传递所有给定的 @racket[v] 和 @racket[kw-arg]。}


@defform/subs[(send* obj-expr msg ...+)
              ([msg (method-id arg ...)
                    (method-id arg ... . arg-list-expr)])]{

按顺序调用同一 object 的多个 method。每个 @racket[msg] 对应于 @racket[send] 的一次使用。

例如，

@racketblock[
(send* edit (begin-edit-sequence)
            (insert "Hello")
            (insert #\newline)
            (end-edit-sequence))
]

等同于

@racketblock[
(let ([o edit])
  (send o begin-edit-sequence)
  (send o insert "Hello")
  (send o insert #\newline)
  (send o end-edit-sequence))
]}

@defform/subs[(send+ obj-expr msg ...)
              ([msg (method-id arg ...)
                    (method-id arg ... . arg-list-expr)])]{

按顺序调用 method，从 @racket[obj-expr] 产生的 object 开始。每个 method 调用将在上一个 method 调用的结果上调用，该结果预期是 object。每个 @racket[msg] 对应于 @racket[send] 的一次使用。

这是 @racket[send*] 的函数式对应。

@examples[#:eval class-eval
(eval:no-prompt
 (define point%
   (class object%
     (super-new)
     (init-field [x 0] [y 0])
     (define/public (move-x dx)
       (new this% [x (+ x dx)] [y y]))
     (define/public (move-y dy)
       (new this% [y (+ y dy)] [x x]))
     (define/public (get-pair)
       (cons x y)))))

(send+ (new point%)
       (move-x 5)
       (move-y 7)
       (move-x 12)
       (get-pair))
]}

@defform[(with-method ([id (obj-expr method-id)] ...)
           body ...+)]{

从 object 中提取 method，并为每个 method 绑定一个可以直接应用的本地名称(与 class 内部声明的 method 相同)。每个 @racket[obj-expr] 必须产生一个 object，该 object 必须有由相应 @racket[method-id] 命名的 public method。相应的 @racket[id] 被绑定以便可以直接应用(参见 @secref["methodcalls"])。

示例：

@racketblock[
(let ([s (new stack%)])
  (with-method ([push (s push!)]
                [pop (s pop!)])
    (push 10)
    (push 9)
    (pop)))
]

等同于

@racketblock[
(let ([s (new stack%)])
  (send s push! 10)
  (send s push! 9)
  (send s pop!))
]}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@subsection{Field}

@defform[(get-field id obj-expr)]{

从 @racket[obj-expr] 的值中提取具有(外部)名称 @racket[id] 的 field。

如果 @racket[obj-expr] 没有产生 object，则 @exnraise[exn:fail:contract]。 If the object has no @racket[id] field,
the @exnraise[exn:fail:object].}

@defproc[(dynamic-get-field [field-name symbol?] [obj object?]) any/c]{

从 @racket[obj] 中提取(外部)名称匹配 @racket[field-name] 的 field。如果 object 没有匹配 @racket[field-name] 的 field，则 @exnraise[exn:fail:object]。}

@defform[(set-field! id obj-expr expr)]{

将 @racket[obj-expr] 的值中具有(外部)名称 @racket[id] 的 field 设置为 @racket[expr] 的值。

如果 @racket[obj-expr] 没有产生 object，则 @exnraise[exn:fail:contract]。如果 object 没有 @racket[id] field，则 @exnraise[exn:fail:object]。}

@defproc[(dynamic-set-field! [field-name symbol?] [obj object?] [v any/c]) void?]{

将 @racket[obj] 中(外部)名称匹配 @racket[field-name] 的 field 设置为 @racket[v]。如果 object 没有匹配 @racket[field-name] 的 field，则 @exnraise[exn:fail:object]。}

@defform[(field-bound? id obj-expr)]{

如果 @racket[obj-expr] 的 object 结果具有(外部)名称 @racket[id] 的 field，则生成 @racket[#t]，否则为 @racket[#f]。

如果 @racket[obj-expr] 没有产生 object，则 @exnraise[exn:fail:contract]。}

@defform[(class-field-accessor class-expr field-id)]{

返回一个 accessor procedure，该 procedure 接受由 @racket[class-expr] 生成的 class 的实例，并返回该 object 中具有(外部)名称 @racket[field-id] 的 field 的值。

如果 @racket[class-expr] 没有产生 class，则 @exnraise[exn:fail:contract]。如果 class 没有 @racket[field-id] field，则 @exnraise[exn:fail:object]。}

@defform[(class-field-mutator class-expr field-id)]{

返回一个 mutator procedure，该 procedure 接受由 @racket[class-expr] 生成的 class 的实例和一个值，并将该 object 中具有(外部)名称 @racket[field-id] 的 field 的值设置为给定的值。结果为 @|void-const|。

如果 @racket[class-expr] 没有产生 class，则 @exnraise[exn:fail:contract]。如果 class 没有 @racket[field-id] field，则 @exnraise[exn:fail:object]。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@subsection[#:tag "sec:generics"]{Generic}

@deftech{generic} 可以用来代替 method 名称，以避免在 class 内按名称重定位 method 的开销，使 method 调用更高效。

@examples[
 #:eval class-eval
 (eval:no-prompt
  (define woody%
    (class object%
      (define/public (draw who)
        (format "reach for the sky, ~a" who))
      (super-new))))
 
 (eval:no-prompt
  (define gen-draw (generic woody% draw)))

 (eval:no-prompt
  (define (call-draw o)
    (send-generic o gen-draw "partner")))

 (call-draw (new woody%))

 (eval:no-prompt
  (define woody2%
    (class woody%
      (define/override (draw who)
        (string-append (super draw who)
                       "–there's a snake in my boot!"))
      (super-new))))
 (call-draw (new woody2%))]

@defform[(generic class-or-interface-expr id)]{

生成一个 generic，该 generic 作用于由 @racket[class-or-interface-expr] 生成的 class 或 interface 的实例(或派生自 @racket[class-or-interface] 的 class/interface 的实例)，以调用具有(外部)名称 @racket[id] 的 method。

如果 @racket[class-or-interface-expr] 没有产生 class 或 interface，则 @exnraise[exn:fail:contract]。如果结果 class 或 interface 不包含名为 @racket[id] 的 method，则 @exnraise[exn:fail:object]。

一些示例请参见 @secref["sec:generics"] 的介绍。
}

@defform*[[(send-generic obj-expr generic-expr arg ...)
           (send-generic obj-expr generic-expr arg ... . arg-list-expr)]]{

如 @racket[generic-expr] 生成的 generic 所示，调用 @racket[obj-expr] 生成的 object 的 method。每个 @racket[arg] 与 @racket[#%app] 的相同：@racket[_arg-expr] 或 @racket[_keyword _arg-expr]。第二种形式类似于使用 @racket[apply] 调用 procedure，其中 @racket[arg-list-expr] 不是带括号的表达式。

如果 @racket[obj-expr] 没有产生 object，或者 @racket[generic-expr] 没有产生 generic，则 @exnraise[exn:fail:contract]。如果 @racket[obj-expr] 的结果不是 @racket[generic-expr] 结果所封装的 class 或 interface 的实例，则 @exnraise[exn:fail:object]。

一些示例请参见 @secref["sec:generics"] 的介绍。
}

@defproc[(make-generic [type (or/c class? interface?)]
                       [method-name symbol?])
         generic?]{

类似于 @racket[generic] 形式，但作为接受符号化 method 名称的 procedure。}

@; ------------------------------------------------------------------------

@section[#:tag "mixins"]{Mixin}

@defform[(mixin (interface-expr ...) (interface-expr ...)
           class-clause ...)]{

生成一个 @deftech{mixin}，这是一个封装了 class 扩展的 procedure，superclass 保持未指定。每次将 mixin 应用于特定 superclass 时，它使用封装的扩展生成一个新的派生 class。

给定的 class 必须实现第一组 @racket[interface-expr] 生成的 interface。该 procedure 的结果是给定 class 的 subclass，该 subclass 实现第二组 @racket[interface-expr] 生成的 interface。@racket[class-clause] 与 @racket[class*] 的相同，用于定义 mixin 封装的 class 扩展。

@racket[mixin] 形式的求值会检查 @racket[class-clause] 是否与两组 @racket[interface-expr] 一致。}

@; ------------------------------------------------------------------------

@section[#:tag "trait"]{Trait}

@note-lib-only[racket/trait]

@deftech{trait} 是一组 method 的集合，可以转换为 @tech{mixin}，然后应用于 @tech{class}。在 trait 转换为 mixin 之前，trait 的 method 可以单独重命名，多个 trait 可以合并形成新的 trait。

@defform/subs[#:literals (public pubment public-final override override-final overment augment augride
                          augment-final private inherit inherit/super inherit/inner rename-super
                          field inherit-field)

              (trait trait-clause ...)
              ([trait-clause (public maybe-renamed ...)
                             (pubment maybe-renamed ...)
                             (public-final maybe-renamed ...)
                             (override maybe-renamed ...)
                             (overment maybe-renamed ...)
                             (override-final maybe-renamed ...)
                             (augment maybe-renamed ...)
                             (augride maybe-renamed ...)
                             (augment-final maybe-renamed ...)
                             (inherit maybe-renamed ...)
                             (inherit/super maybe-renamed ...)
                             (inherit/inner maybe-renamed ...)
                             method-definition
                             (field field-declaration ...)
                             (inherit-field maybe-renamed ...)])]{

创建一个 @tech{trait}。@racket[trait] 形式的 body 类似于 @racket[class*] 形式的 body，但限于非 private 的 method 定义。特别地，@racket[maybe-renamed]、@racket[method-definition] 和 @racket[field-declaration] 的语法与 @racket[class*] 的相同，每个 @racket[method-definition] 必须有对应的声明(@racket[public]、@racket[override] 等之一)。与 @racket[class] 一样，在直接调用、@racket[super] 调用和 @racket[inner] 调用中使用 method 名称依赖于通过 @racket[inherit]、@racket[inherit/super]、@racket[inherit/inner] 以及同一 trait 中的其他 method 声明将 method 名称引入作用域；与 @racket[class] 相比，一个例外是 @racket[overment] 仅在对应的 method 中绑定 method 名称，而不在同一 trait 的其他 method 中。最后，@racket[public*] 和 @racket[define/public] 等 macro 在 @racket[trait] 中的工作方式与 @racket[class] 中一样。

@racket[trait]、@racket[trait-exclude]、@racket[trait-exclude-field]、@racket[trait-alias]、@racket[trait-rename] 和 @racket[trait-rename-field] 形式中的外部标识符可以通过 @racket[define-member-name] 和 @racket[define-local-member-name] 进行绑定。虽然 @racket[private] method 或 field 不允许出现在 @racket[trait] 形式中，但可以通过使用 @racket[public] 或 @racket[field] 声明以及作用域限于 @racket[trait] 形式的名称来模拟。}


@defproc[(trait? [v any/c]) boolean?]{

如果 @racket[v] 是 trait，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(trait->mixin [tr trait?]) (class? . -> . class?)]{

将 @tech{trait} 转换为 @tech{mixin}，后者可应用于 @tech{class} 以生成新的 @tech{class}。以下形式的表达式

@racketblock[
(trait->mixin
 (trait
   _trait-clause ...))
]

等价于

@racketblock[
(lambda (%)
  (class %
    _trait-clause ...
    (super-new)))
]

然而，通常在转换为 mixin 之前，trait 的 method 会被修改并与其他 trait 组合。}


@defproc[(trait-sum [tr trait?] ...+) trait?]{

Produces a @tech{trait} that combines all of the methods of the given
@racket[tr]s. 例如，

@racketblock[
(define t1
  (trait
    (define/public (m1) 1)))
(define t2
  (trait
    (define/public (m2) 2)))
(define t3 (trait-sum t1 t2))
]

creates a trait @racket[t3] that 等价于

@racketblock[
(trait
  (define/public (m1) 1)
  (define/public (m2) 2))
]

但 @racket[t1] 和 @racket[t2] 仍然可以单独使用或与其他 trait 组合。

当 trait 使用 @racket[trait-sum] 组合时，如果另一个 trait 为相同的 method 或 field 名称提供了定义，则组合会丢弃 @racket[inherit]、@racket[inherit/super]、@racket[inherit/inner] 和 @racket[inherit-field] 声明。如果要组合的任何 trait 定义了同名的 method 或 field，或者要丢弃的 @racket[inherit/super] 或 @racket[inherit/inner] 声明与提供的定义不一致，则 @racket[trait-sum] 操作会失败(@exnraise[exn:fail:contract])。换句话说，使用 @racket[inherit]、@racket[inherit/super] 或 @racket[inherit/inner] 声明 method 不算作定义 method；同时，例如，包含 method @racket[m] 的 @racket[inherit/super] 声明的 trait 不能与将 @racket[m] 定义为 @racket[augment] 的 trait 组合，因为当 trait 稍后转换为 mixin 并应用于 class 时，没有 class 能同时满足 @racket[augment] 和 @racket[inherit/super] 的要求。}


@defform[(trait-exclude trait-expr id)]{

生成一个新的 @tech{trait}，类似于 @racket[trait-expr] 的 @tech{trait} 结果，但移除了由 @racket[id] 命名的 method 定义；当 method 定义被移除时，会添加一个 @racket[inherit]、@racket[inherit/super] 或 @racket[inherit/inner] 声明：

@itemize[

 @item{A method declared with @racket[public], @racket[pubment], or
  @racket[public-final] is replaced with an @racket[inherit]
  declaration.}

 @item{A method declared with @racket[override] or @racket[override-final]
 is replaced with an @racket[inherit/super] declaration.}

  @item{A method declared with @racket[augment], @racket[augride], or
  @racket[augment-final] is replaced with an @racket[inherit/inner] declaration.}

 @item{A method declared with @racket[overment] is not replaced
  with any @racket[inherit] declaration.}

]

如果 @racket[trait-expr] 生成的 trait 没有 @racket[id] 的 method 定义，则 @exnraise[exn:fail:contract]。}


@defform[(trait-exclude-field trait-expr id)]{

生成一个新的 @tech{trait}，类似于 @racket[trait-expr] 的 @tech{trait} 结果，但移除了由 @racket[id] 命名的 field 定义；当 field 定义被移除时，会添加一个 @racket[inherit-field] 声明。}


@defform[(trait-alias trait-expr id new-id)]{

生成一个新的 @tech{trait}，类似于 @racket[trait-expr] 的 @tech{trait} 结果，但由 @racket[id] 命名的 method 的定义和声明被复制为名称 @racket[new-id]。结果 trait 的一致性要求与 @racket[trait-sum] 相同，否则 @exnraise[exn:fail:contract]。此操作不会重命名 @racket[id] 的任何其他使用，例如 method 调用(甚至是 @racket[new-id] 克隆定义中的 @racket[identifier] method 调用)。}


@defform[(trait-rename trait-expr id new-id)]{

生成一个新的 @tech{trait}，类似于 @racket[trait-expr] 的 @tech{trait} 结果，但所有名为 @racket[id] 的 method 的定义和引用被替换为名为 @racket[new-id] 的 method 的定义和引用。结果 trait 的一致性要求与 @racket[trait-sum] 相同，否则 @exnraise[exn:fail:contract]。}


@defform[(trait-rename-field trait-expr id new-id)]{

生成一个新的 @tech{trait}，类似于 @racket[trait-expr] 的 @tech{trait} 结果，但所有名为 @racket[id] 的 field 的定义和引用被替换为名为 @racket[new-id] 的 field 的定义和引用。结果 trait 的一致性要求与 @racket[trait-sum] 相同，否则 @exnraise[exn:fail:contract]。}

@; ------------------------------------------------------------------------

@section{Object 和 Class Contract}

@defform/subs[
#:literals (field init init-field inherit inherit-field super inner override augment augride absent)

(class/c maybe-opaque member-spec ...)

([maybe-opaque
  (code:line)
  (code:line #:opaque)
  (code:line #:opaque #:ignore-local-member-names)]

 [member-spec
  method-spec
  (field field-spec ...)
  (init field-spec ...)
  (init-field field-spec ...)
  (inherit method-spec ...)
  (inherit-field field-spec ...)
  (super method-spec ...)
  (inner method-spec ...)
  (override method-spec ...)
  (augment method-spec ...)
  (augride method-spec ...)
  (absent absent-spec ...)]
 
 [method-spec
  method-id
  (method-id method-contract-expr)]
 [field-spec
  field-id
  (field-id contract-expr)]
 [absent-spec
  method-id
  (field field-id ...)])]{
生成 class 的 contract。

@racket[class/c] 形式中列出了两大类 contract：外部和内部 contract。外部 contract 控制从 class 实例化 object 时或通过该 class 的 object 访问 method 或 field 时的行为。内部 contract 控制 class 层次结构内部访问 method 或 field 时的行为。这种分离允许对 class 客户端使用更强的 contract，对 subclass 使用更弱的 contract。

method contract 必须包含一个额外的初始参数，该参数对应于 method 的隐式 @racket[this] 参数。这允许 contract 讨论 method 被调用时 object 的状态(或者对于依赖 contract，在 contract 的其他部分)。提供了替代的 contract 形式，例如 @racket[->m]，作为编写 method contract 的简写。

在 @racket[absent] 子句中列出的 method 和 field @emph{不得} 存在于 class 中。

class contract 可以使用 @racket[#:opaque] 关键字指定为 @emph{opaque}。opaque class contract 只接受精确定义了 contract 指定的外部 method 和 field 的 class。如果受约束的 class 包含任何未指定的 method 或 field，则会引发 contract 错误。具有本地成员名称的 method 或 field(即使用 @racket[define-local-member-name] 定义的)在提供了 @racket[#:ignore-local-member-names] 时会在此检查中被忽略。

外部 contract 如下：

@itemize[
 @item{An external method contract without a tag describes the behavior
   of the implementation of @racket[method-id] on method sends to an
   object of the contracted class.  This contract will continue to be
   checked in subclasses until the contracted class's implementation is
   no longer the entry point for dynamic dispatch.
   
   If only the field name is present, this 等价于 insisting only
   that the method is present in the class.
   
   @examples[#:eval class-eval
                (eval:no-prompt
                 (define woody%
                   (class object%
                     (define/public (draw who)
                       (format "reach for the sky, ~a" who))
                     (super-new)))
                
                 (define/contract woody+c%
                   (class/c [draw (->m symbol? string?)])
                   woody%))
                
                (send (new woody%) draw #f)
                (send (new woody+c%) draw 'zurg)
                (eval:error (send (new woody+c%) draw #f))]
   }
 @item{An external field contract, tagged with @racket[field], describes the
   behavior of the value contained in that field when accessed from outside
   the class.  Since fields may be mutated, these contracts
   are checked on any external access (via @racket[get-field])
   and external mutations (via @racket[set-field!]) of the field.

   If only the field name is present, this 等价于 using the 
   contract @racket[any/c] (but it is checked more efficiently).
   
   @examples[#:eval class-eval
                (eval:no-prompt
                 (define woody/hat%
                   (class woody%
                     (field [hat-location 'uninitialized])
                     (define/public (lose-hat) (set! hat-location 'lost))
                     (define/public (find-hat) (set! hat-location 'on-head))
                     (super-new)))
                 (define/contract woody/hat+c%
                   (class/c [draw (->m symbol? string?)]
                            [lose-hat (->m void?)]
                            [find-hat (->m void?)]
                            (field [hat-location (or/c 'on-head 'lost)]))
                   woody/hat%))
                
                (get-field hat-location (new woody/hat%))
                (let ([woody (new woody/hat+c%)])
                  (send woody lose-hat)
                  (get-field hat-location woody))
                (eval:error (get-field hat-location (new woody/hat+c%)))
                (eval:error
                 (let ([woody (new woody/hat+c%)])
                   (set-field! hat-location woody 'under-the-dresser)))]
   
   }
 @item{An initialization argument contract, tagged with @racket[init],
   describes the expected behavior of the value paired with that name
   during class instantiation.  The same name can be provided more than
   once, in which case the first such contract in the @racket[class/c]
   form is applied to the first value tagged with that name in the list
   of initialization arguments, and so on.
   
   If only the initialization argument name is present, this 等价于 using the 
   contract @racket[any/c] (but it is checked more efficiently).
   
   @examples[#:eval class-eval
                (eval:no-prompt
                 (define woody/init-hat%
                   (class woody%
                     (init init-hat-location)
                     (field [hat-location init-hat-location])
                     (define/public (lose-hat) (set! hat-location 'lost))
                     (define/public (find-hat) (set! hat-location 'on-head))
                     (super-new)))
                 (define/contract woody/init-hat+c%
                   (class/c [draw (->m symbol? string?)]
                            [lose-hat (->m void?)]
                            [find-hat (->m void?)]
                            (init [init-hat-location (or/c 'on-head 'lost)])
                            (field [hat-location (or/c 'on-head 'lost)]))
                   woody/init-hat%))
                (get-field hat-location
                           (new woody/init-hat+c%
                                [init-hat-location 'lost]))
                (eval:error
                 (get-field hat-location
                            (new woody/init-hat+c%
                                 [init-hat-location 'slinkys-mouth])))]
   
   }
 @item{@racket[init-field] 部分中列出的 contract 被视为每个 contract 同时出现在 @racket[init] 部分和 @racket[field] 部分中。}
]

内部 contract 限制 class 与其 subclass 之间的 method 调用行为；此类调用不受上述 class contract 的控制。 

与外部 contract 一样，当指定了 method 或 field 名称但没有出现 contract 时，仅凭相应 field 或 method 的存在就满足 contract。

@itemize[
 @item{带有 @racket[inherit] 标签的 method contract 描述了在受约束 class 的任何 subclass 中直接调用 method 时的行为(即通过 @racket[inherit])。这个 contract 与外部 method contract 一样，在受约束 class 的 method 实现不再是动态分派的入口点之前一直适用。
   
   @examples[#:eval class-eval
                (new (class woody+c%
                       (inherit draw)
                       (super-new)
                       (printf "woody sez: “~a”\n" (draw "evil dr porkchop"))))
                (eval:no-prompt
                 (define/contract woody+c-inherit%
                   (class/c (inherit [draw (->m symbol? string?)]))
                   woody+c%))
                (eval:error
                 (new (class woody+c-inherit%
                        (inherit draw)
                        (printf "woody sez: ~a\n" (draw "evil dr porkchop")))))]
   
   }
  @item{带有 @racket[super] 标签的 method contract 描述了 @racket[method-id] 在 subclass 中被 @racket[super] 形式调用时的行为。此 contract 仅影响调用受约束 class 的 @racket[method-id] 实现的 subclass 中的 @racket[super] 调用。
   
   这个例子展示了如何扩展 @racket[draw] method，使得如果传递了两个参数，它会合并对原始 @racket[draw] method 的两次调用，但带有一个控制 @racket[super] method 如何被调用的 contract。
   
   @examples[#:eval class-eval
                (eval:no-prompt

  (define/contract woody%+s
    (class/c (super [draw (->m symbol? string?)]))
    (class object%
      (define/public (draw who)
        (format "reach for the sky, ~a" who))
      (super-new)))

  (define woody2+c%
    (class woody%+s
      (define/override draw
        (case-lambda
          [(a) (super draw a)]
          [(a b) (string-append (super draw a)
                                " and "
                                (super draw b))]))
      (super-new))))
                 
                (send (new woody2+c%) draw 'evil-dr-porkchop  'zurg)
                (eval:error (send (new woody2+c%) draw "evil dr porkchop" "zurg"))]
   
   The last call signals an error blaming @racket[woody2%+c] because
   there is no contract checking the initial @racket[draw] call and
   the super-call violates its contract. 
   }
 @item{带有 @racket[inner] 标签的 method contract 描述了 class 对 subclass 中增强 method 的期望行为。此 contract 影响 subclass 中 @racket[method-id] 的任何实现，这些实现可以通过受约束 class 中的 @racket[inner] 调用。这意味着通过 @racket[augment] 或 @racket[overment] 实现 @racket[method-id] 的 subclass 会使未来的 subclass 不再受此 contract 影响，因为进一步的扩展无法通过受约束 class 到达。}
 @item{带有 @racket[override] 标签的 method contract 描述了受约束 class 对 @racket[method-id] 在直接调用时期望的行为(即通过应用程序 @racket[(method-id ...)])。此形式只能在 subclass 中覆盖 method 会改变动态分派链的入口点时使用(即 method 从未可增强)。
   
   这一次，我们不是覆盖 @racket[draw] 来支持两个参数，而是创建一个新的 method @racket[draw2]，它接受两个参数并调用 @racket[draw]。我们还添加了一个 contract 来确保覆盖 @racket[draw] 不会破坏 @racket[draw2]。   
   
   @examples[#:eval class-eval
                (eval:no-prompt
                 (define/contract woody2+override/c%
                   (class/c (override [draw (->m symbol? string?)]))
                   (class woody+c%
                     (inherit draw)
                     (define/public (draw2 a b)
                       (string-append (draw a)
                                      " and "
                                      (draw b)))
                     (super-new)))
                
                 (define woody2+broken-draw
                   (class woody2+override/c%
                     (define/override (draw x)
                       'not-a-string)
                     (super-new))))

                (eval:error
                 (send (new woody2+broken-draw) draw2 
                       'evil-dr-porkchop
                       'zurg))]
   
   
   }
 @item{带有 @racket[augment] 或 @racket[augride] 标签的 method contract 描述了受约束 class 为 @racket[method-id] 提供的、在 subclass 中直接调用时的行为。这些形式只能在 method 此前是可增强的情况下使用，这意味着任何增强或覆盖实现都不会改变动态分派链的入口点。@racket[augment] 用于 subclass 可以增强 method 的情况，@racket[augride] 用于 subclass 可以覆盖当前增强的情况。}
 @item{带有 @racket[inherit-field] 标签的 field contract 描述了该 field 中包含的值在受约束 class 的任何 subclass 中直接访问时(即通过 @racket[inherit-field])的行为。由于 field 可能被修改，这些 contract 在此类 subclass 中的任何 field 访问和/或修改时都会被检查。}

@history[#:changed "6.1.1.8"
         @string-append{Opaque class/c now optionally ignores local
                        member names if an additional keyword is supplied.}]
]}

@defform[(absent absent-spec ...)]{
参见 @racket[class/c]；在 @racket[class/c] 形式外部使用是语法错误。
}

@defform[(->m dom ... range)]{
类似于 @racket[->]，但结果 contract 的 domain 比声明的 domain 多一个元素，其中第一个(隐式)参数使用 @racket[any/c] 进行约束。当不需要检查 @racket[this] 的任何属性时，此 contract 可用于编写更简单的 method contract。}

@defform[(->*m (mandatory-dom ...) (optional-dom ...) rest range)]{
类似于 @racket[->*]，但结果 contract 的 mandatory domain 比声明的 domain 多一个元素，其中第一个(隐式)参数使用 @racket[any/c] 进行约束。当不需要检查 @racket[this] 的任何属性时，此 contract 可用于编写更简单的 method contract。}

@defform[(case->m (-> dom ... rest range) ...)]{
类似于 @racket[case->]，但结果 contract 每种情况的 mandatory domain 比声明的 domain 多一个元素，其中第一个(隐式)参数使用 @racket[any/c] 进行约束。当不需要检查 @racket[this] 的任何属性时，此 contract 可用于编写更简单的 method contract。}

@defform[(->dm (mandatory-dependent-dom ...)
               (optional-dependent-dom ...)
               dependent-rest
               pre-cond
               dep-range)]{
类似于 @racket[->d]，但结果 contract 的 mandatory domain 比声明的 domain 多一个元素，其中第一个(隐式)参数使用 @racket[any/c] 进行约束。此外，@racket[this] 在 contract body 中被正确绑定。当不需要检查 @racket[this] 的任何属性时，此 contract 可用于编写更简单的 method contract。}

@defform/subs[
#:literals (field)

(object/c member-spec ...)

([member-spec
  method-spec
  (field field-spec ...)
  (code:line #:opaque opaque-expr)
  (code:line #:opaque-except opaque-expr)
  (code:line #:opaque-fields opaque-fields-expr)
  #:do-not-check-class-field-accessor-or-mutator-access]
 
 [method-spec
  method-id
  (method-id method-contract)]
 [field-spec
  field-id
  (field-id contract-expr)])]{
为 object 生成 contract。 Each field and method is checked
against the supplied contract. Note that each method contract should
be written to accept an extra, “this” argument; consider using @racket[->m]
or @racket[->*m] contract combinators.

 如果存在，@racket[opaque-expr] 控制如何处理 object 中存在但未在 contract 中列出的 method：
 @itemlist[
 @item{如果 @racket[opaque-expr] 跟随关键字 @racket[#:opaque] 且求值为 @racket[#f]，则始终允许调用此类 method。}
 @item{如果它跟随 @racket[#:opaque] 且求值为 @racket[#t]，则永远不允许此类 method。}
 @item{如果它跟随 @racket[#:opaque] 且求值为由 @racket[make-impersonator-property] 生成的谓词 procedure，则允许设置了该 property 的 method procedure。}
 @item{如果 @racket[opaque-expr] 跟随关键字 @racket[#:opaque-except]，则它必须求值为由 @racket[make-impersonator-property] 生成的谓词 procedure。在这种情况下，具有该 property 的 method 被禁止，其他 method 被允许。}
 @item{ 如果没有 @racket[opaque-expr]，则始终允许调用未在 contract 中列出的 method。}]

 以类似于 @racket[opaque-expr] 但针对 field 的方式，@racket[opaque-fields-expr] 控制如何处理 object 中存在但未在 contract 中列出的 field：
 @itemlist[
 @item{如果 @racket[opaque-fields-expr] 存在且求值为 @racket[#true]，则不允许访问未在 contract 中列出的 field。}
 @item{如果 @racket[opaque-fields-expr] 存在且求值为 @racket[#false]，则允许访问此类 field。}
 @item{ 如果 @racket[opaque-fields-expr] 不存在且 @racket[opaque-expr] 求值为由 @racket[make-impersonator-property] 生成的谓词 procedure，则在 @racket[#:opaque] 存在时禁止 field，在 @racket[#:opaque-except] 存在时允许。 }
 @item{如果 @racket[opaque-fields-expr] 不存在但 @racket[opaque-expr] 存在，则 @racket[opaque-fields-expr] 基于 @racket[opaque-expr] 的值默认：如果 @racket[opaque-expr] 禁止 method，则禁止 field；如果不禁止则允许。 }]

 如果 @racket[opaque-fields-expr] 和 @racket[opaque-expr] 都不存在，则允许访问所有未列出的 field 和 method。

 如果存在 @racket[#:do-not-check-class-field-accessor-or-mutator-access]，则始终允许通过 @racket[class-field-mutator] 和 @racket[class-field-accessor] 返回的 procedure 进行 field 访问，即使它们本来会被禁止(要么因为不允许 field 访问，要么因为 field 违反了 contract)。这种行为是有疑问的，但对应于在以前版本的 @racket[object/c] 中存在了十多年的一个 bug，因此此选项在这里是为了在过渡到正确检查的 contract 的时间安排上提供灵活性。

}
@defproc[(instanceof/c [class-contract contract?]) contract?]{
为 object 生成 contract，该 object 是符合 @racket[class-contract] 的 class 的实例。
}

@defproc[(dynamic-object/c [method-names (listof symbol?)]
                           [method-contracts (listof contract?)]
                           [field-names (listof symbol?)]
                           [field-contracts (listof contract?)])
         contract?]{
为 object 生成 contract，类似于 @racket[object/c]，但 method 和 field 的名称和 contract 都可以动态计算。method 和 field 的名称和 contract 列表必须分别具有相同的长度。
}

@defform/subs[
#:literals (field -> ->* ->d)

(object-contract member-spec ...)

([member-spec
  (method-id method-contract)
  (field field-id contract-expr)]

 [method-contract
  (-> dom ... range)
  (->* (mandatory-dom ...)
       (optional-dom ...)
       rest
       range)
  (->d (mandatory-dependent-dom ...) 
       (optional-dependent-dom ...) 
       dependent-rest
       pre-cond
       dep-range)]

 [dom dom-expr (code:line keyword dom-expr)]
 [range range-expr (values range-expr ...) any]
 [mandatory-dom dom-expr (code:line keyword dom-expr)]
 [optional-dom dom-expr (code:line keyword dom-expr)]
 [rest (code:line) (code:line #:rest rest-expr)]
 [mandatory-dependent-dom [id dom-expr] (code:line keyword [id dom-expr])]
 [optional-dependent-dom [id dom-expr] (code:line keyword [id dom-expr])]
 [dependent-rest (code:line) (code:line #:rest id rest-expr)]
 [pre-cond (code:line) (code:line #:pre-cond boolean-expr)]
 [dep-range any
            (code:line [id range-expr] post-cond)
            (code:line (values [id range-expr] ...) post-cond)]
 [post-cond (code:line) (code:line #:post-cond boolean-expr)]
)]{

为 object 生成 contract。

每个 method 的 contract 具有与相应 function contract 相同的语义，但 method contract 的语法必须直接写在 object-contract 的 body 中——就像 class 定义中的 method 使用与常规 function 定义相同的语法，但不能是任意 procedure。与 @racket[class/c] 的 method contract 不同，隐式的 @racket[this] 参数不是 contract 的一部分。为了允许在依赖 contract 中使用 @racket[this]，@racket[->d] contract 隐式地将 @racket[this] 绑定到 object 本身。}


@defthing[mixin-contract contract?]{

一个识别 mixin 的 @tech{function contract}。它保证 function 的输入是 class，function 的结果是输入的 subclass。}

@defproc[(make-mixin-contract [type (or/c class? interface?)] ...) contract?]{

生成一个 @tech{function contract}，保证 function 的输入是实现/子类化每个 @racket[type] 的 class，并且 function 的结果是输入的 subclass。}

@defproc[(is-a?/c [type (or/c class? interface?)]) flat-contract?]{

接受 class 或 interface，返回一个 flat contract，该 contract 识别实例化该 class/interface 的 object。

参见 @racket[is-a?]。}

@defproc[(implementation?/c [interface interface?]) flat-contract?]{

返回一个 flat contract，该 contract 识别实现 @racket[interface] 的 class。

参见 @racket[implementation?]。}

@defproc[(subclass?/c [class class?]) flat-contract?]{

返回一个 flat contract，该 contract 识别是 @racket[class] 的 subclass 的 class。

参见 @racket[subclass?]。}

@; ------------------------------------------------------------------------

@section[#:tag "objectequality"]{Object 相等和哈希}

默认情况下，不同 class 实例的 object 或非透明 class 实例的 object 仅在它们是 @racket[eq?] 时才是 @racket[equal?] 的。与透明 structure 一样，如果两个 object 是同一透明 class 的实例(即该 class 的每个 superclass 都以 @racket[#f] 作为其 inspector)，当它们的 field 值 @racket[equal?] 时，它们就是 @racket[equal?] 的。

要自定义 class 实例通过 @racket[equal?] 与其他实例比较的方式，实现 @racket[equal<%>] interface。

@definterface[equal<%> ()]{

@racket[equal<%>] interface 包含三个 method，类似于为具有 @racket[prop:equal+hash] 的 structure type 提供的函数：

@itemize[

 @item{@racket[equal-to?] --- Takes two arguments. The first argument
 is an object that is an instance of the same class (or a subclass
 that does not re-declare its implementation of @racket[equal<%>])
 and that is being compared to the target object. The second argument
 is an @racket[equal?]-like procedure of two arguments that should be
 used for recursive equality testing. The result should be a true
 value if the object and the first argument of the method are equal,
 @racket[#f] otherwise.}

 @item{@racket[equal-hash-code-of] --- Takes one argument, which is a
 procedure of one argument that should be used for recursive hash-code
 computation. The result should be an exact integer representing the
 target object's hash code.}

 @item{@racket[equal-secondary-hash-code-of] --- Takes one argument,
 which is a procedure of one argument that should be used for
 recursive hash-code computation. The result should be an exact
 integer representing the target object's secondary hash code.}

]

@racket[equal<%>] interface 的不寻常之处在于，声明 interface 的实现与继承该 interface 是不同的。只有当两个 object 是其最具体的显式实现 @racket[equal<%>] 的祖先为同一祖先的 class 的实例时，它们才能相等。

关于相等性比较和哈希码的更多信息，请参见 @racket[prop:equal+hash]。@racket[equal<%>] interface 使用 @racket[interface*] 和 @racket[prop:equal+hash] 实现。}

示例：
@codeblock|{
#lang racket

;; Case insensitive words:
(define ci-word% 
  (class* object% (equal<%>)
    
    ;; Initialization
    (init-field word)
    (super-new)
        
    ;; We define equality to ignore case:
    (define/public (equal-to? other recur)
      (string-ci=? word (get-field word other)))

    ;; The hash codes need to be insensitive to casing as well.
    ;; We'll just downcase the word and get its hash code.
    (define/public (equal-hash-code-of hash-code)
      (hash-code (string-downcase word)))
    
    (define/public (equal-secondary-hash-code-of hash-code)
      (hash-code (string-downcase word)))))

;; We can create a hash with a single word:
(define h (make-hash))
(hash-set! h (new ci-word% [word "inconceivable!"]) 'value)

;; Lookup into the hash should be case-insensitive, so that
;; both of these should return 'value.
(hash-ref h (new ci-word% [word "inconceivable!"]))
(hash-ref h (new ci-word% [word "INCONCEIVABLE!"]))

;; Comparison fails if we use a non-ci-word%:
(hash-ref h "inconceivable!" 'i-dont-think-it-means-what-you-think-it-means)
}|

@; ------------------------------------------------------------------------

@section[#:tag "objectserialize"]{Object 序列化}

@defform[
(define-serializable-class* class-id superclass-expr 
                                     (interface-expr ...)
  class-clause ...)
]{

将 @racket[class-id] 绑定到一个 class，其中 @racket[superclass-expr]、@racket[interface-expr] 和 @racket[class-clause] 与 @racket[class*] 中的相同。

此形式只能在顶层使用，无论是在 module 内部还是外部。@racket[class-id] 标识符绑定到新的 class，并且 @racketidfont{deserialize-info:}@racket[class-id] 也被定义；如果定义在 module 内部，则后者通过 @racket[module+] 从 @racket[deserialize-info] submodule 提供。

class 的序列化以两种方式之一工作：

@itemize[

 @item{如果 class 实现了内置 interface @racket[externalizable<%>]，则 object 通过调用其 @racket[externalize] method 进行序列化；结果可以是任何可序列化的内容(但显然不应该是 object 本身)。反序列化创建 class 的一个没有初始化参数的实例，然后使用 @racket[externalize] 的结果(或者更精确地说，是先前调用的序列化结果的反序列化版本)调用 object 的 @racket[internalize] method。

       要支持这种序列化形式，class 必须可以在没有初始化参数的情况下实例化。此外，仅涉及 class(及其他此类 class)实例的循环不能被序列化。}

 @item{如果 class 没有实现 @racket[externalizable<%>]，则该 class 的每个 superclass 必须是可序列化的或透明的(即以 @racket[#f] 作为其 inspector)。序列化和反序列化完全自动，可能涉及实例循环。

       为了支持实例循环，反序列化可能创建一个所有 field 均为 undefined 值的实例，然后修改 object 以设置 field 值。序列化支持不会以其他方式使 object 的 field 变为可变的。}

]

在第二种情况下，可序列化的 subclass 可以实现 @racket[externalizable<%>]，在这种情况下，@racket[externalize] method 负责所有序列化(即 subclass 的实例失去了自动序列化)。在第一种情况下，所有可序列化的 subclass 都实现 @racket[externalizable<%>]，因为 subclass 实现其父 class 的所有 interface。

在任何一种情况下，如果 object 是 subclass(该 subclass 本身不可序列化)的直接实例，则该 object 像可序列化 class 的直接实例一样被序列化。特别地，对于不可序列化 subclass 的实例，@racket[externalize] method 的覆盖声明被忽略。}


@defform[
(define-serializable-class class-id superclass-expr
  class-clause ...)
]{

类似于 @racket[define-serializable-class*]，但没有 interface 表达式(类似于 @racket[class])。}


@definterface[externalizable<%> ()]{

@racket[externalizable<%>] interface 仅包含 @racket[externalize] 和 @racket[internalize] method。更多信息请参见 @racket[define-serializable-class*]。}

@; ------------------------------------------------------------------------

@section[#:tag "objectprinting"]{Object 打印}

要自定义 class 实例通过 @racket[print]、@racket[write] 和 @racket[display] 打印的方式，实现 @racket[printable<%>] interface。

@defthing[printable<%> interface?]{

@racket[printable<%>] interface 仅包含 @racket[custom-print]、@racket[custom-write] 和 @racket[custom-display] method。@racket[custom-print] method 接受两个参数：目标 port 和当前 @racket[quasiquote] 深度(作为精确非负整数)。@racket[custom-write] 和 @racket[custom-display] method 各接受一个参数，即要将 object @racket[write] 或 @racket[display] 到的目标 port。

调用 @racket[custom-print]、@racket[custom-write] 或 @racket[custom-display] method 就像调用通过 @racket[prop:custom-write] property 附加到 structure type 的 procedure。特别地，递归打印可能触发从调用中逃逸。

更多信息请参见 @racket[prop:custom-write]。@racket[printable<%>] interface 使用 @racket[interface*] 和 @racket[prop:custom-write] 实现。}

@defthing[writable<%> interface?]{

类似于 @racket[printable<%>]，但仅包含 @racket[custom-write] 和 @racket[custom-display] method。@racket[print] 请求被定向到 @racket[custom-write]。}

@; ------------------------------------------------------------------------

@section[#:tag "objectutils"]{Object、Class 和 Interface 工具}

@defproc[(object? [v any/c]) boolean?]{

如果 @racket[v] 是 object，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
  (object? (new object%))
  (object? object%)
  (object? "clam chowder")
]}


@defproc[(class? [v any/c]) boolean?]{

如果 @racket[v] 是 class，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
  (class? object%)
  (class? (class object% (super-new)))
  (class? (new object%))
  (class? "corn chowder")
]}


@defproc[(interface? [v any/c]) boolean?]{

如果 @racket[v] 是 interface，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
  (interface? (interface () empty cons first rest))
  (interface? object%)
  (interface? "gazpacho")
]}


@defproc[(generic? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{generic}，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
  (define c%
    (class object%
      (super-new)
      (define/public (m x)
        (+ 3.14 x))))

  (generic? (generic c% m))
  (generic? c%)
  (generic? "borscht")
]}


@defproc[(object=? [a object?] [b object?]) boolean?]{

确定 @racket[a] 和 @racket[b] 是否由同一次 @racket[new] 调用返回。如果两个 object 具有 field，此 procedure 确定修改一个的 field 是否会改变另一个中对应的 field。

此 procedure 在精神上类似于 @racket[eq?]，但与 contract 一起使用时也能正确工作(并且有更强的保证)。

@examples[#:eval class-ctc-eval
  (define obj-1 (new object%))
  (define obj-2 (new object%))
  (define/contract obj-3 (object/c) obj-1)
  
  (object=? obj-1 obj-1)
  (object=? obj-1 obj-2)
  (object=? obj-1 obj-3)
  
  (eq? obj-1 obj-1)
  (eq? obj-1 obj-2)
  (eq? obj-1 obj-3)
]}


@defproc[(object-or-false=? [a (or/c object? #f)] [b (or/c object? #f)]) boolean?]{

类似于 @racket[object=?]，但接受任一参数为 @racket[#f]，如果两个参数都是 @racket[#f] 则返回 @racket[#t]。

@examples[#:eval class-ctc-eval
   (object-or-false=? #f (new object%))
   (object-or-false=? (new object%) #f)
   (object-or-false=? #f #f)
   ]

@history[#:added "6.1.1.8"]}

@defproc[(object=-hash-code [o object?]) fixnum?]{
 返回 @racket[o] 的哈希码，该哈希码对应相等关系 @racket[object=?]。

@history[#:added "7.1.0.6"]}

@defproc[(object->vector [object object?] [opaque-v any/c #f]) vector?]{

返回表示 @racket[object] 的 vector，显示其可检查的 field，类似于 @racket[struct->vector]。

@examples[#:eval class-eval
  (object->vector (new object%))
  (object->vector (new (class object%
                         (super-new)
                         (field [x 5] [y 10]))))
]}


@defproc[(class->interface [class class?]) interface?]{

返回由 @racket[class] 隐式定义的 interface。

@examples[#:eval class-eval
  (class->interface object%)
]}


@defproc[(object-interface [object object?]) interface?]{

返回由 @racket[object] 的 class 隐式定义的 interface。

@examples[#:eval class-eval
  (object-interface (new object%))
]}

 
@defproc[(is-a? [v any/c] [type (or/c interface? class?)]) boolean?]{

如果 @racket[v] 是 class @racket[type] 的实例或实现 interface @racket[type] 的 class 的实例，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
  (define point<%> (interface () get-x get-y))
  (define 2d-point%
    (class* object% (point<%>)
      (super-new)
      (field [x 0] [y 0])
      (define/public (get-x) x)
      (define/public (get-y) y)))

  (is-a? (new 2d-point%) 2d-point%)
  (is-a? (new 2d-point%) point<%>)
  (is-a? (new object%) 2d-point%)
  (is-a? (new object%) point<%>)
]}


@defproc[(subclass? [v any/c] [cls class?]) boolean?]{

如果 @racket[v] 是派生自 @racket[cls](或等于 @racket[cls])的 class，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
  (subclass? (class object% (super-new)) object%)
  (subclass? object% (class object% (super-new)))
  (subclass? object% object%)
]}


@defproc[(implementation? [v any/c] [intf interface?]) boolean?]{

如果 @racket[v] 是实现 @racket[intf] 的 class，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
  (define i<%> (interface () go))
  (define c%
    (class* object% (i<%>)
      (super-new)
      (define/public (go) 'go)))

  (implementation? c% i<%>)
  (implementation? object% i<%>)
]}


@defproc[(interface-extension? [v any/c] [intf interface?]) boolean?]{

如果 @racket[v] 是扩展 @racket[intf] 的 interface，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
  (define point<%> (interface () get-x get-y))
  (define colored-point<%> (interface (point<%>) color))

  (interface-extension? colored-point<%> point<%>)
  (interface-extension? point<%> colored-point<%>)
  (interface-extension? (interface () get-x get-y get-z) point<%>)
]}


@defproc[(method-in-interface? [sym symbol?] [intf interface?]) boolean?]{

如果 @racket[intf](或其任何祖先 interface)包含名称为 @racket[sym] 的成员，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
  (define i<%> (interface () get-x get-y))
  (method-in-interface? 'get-x i<%>)
  (method-in-interface? 'get-z i<%>)
]}


@defproc[(interface->method-names [intf interface?]) (listof symbol?)]{

返回 @racket[intf] 中 method 名称的 symbol 列表，包括从 superinterface 继承的 method，但不包括名称是本地的 method(即使用 @racket[define-local-member-name] 声明的)。

@examples[#:eval class-eval
  (define i<%> (interface () get-x get-y))
  (interface->method-names i<%>)
]}


@defproc[(object-method-arity-includes? [object object?] [sym symbol?] [cnt exact-nonnegative-integer?])
         boolean?]{

如果 @racket[object] 具有名为 @racket[sym] 且接受 @racket[cnt] 个参数的 method，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval class-eval
(define c%
  (class object%
    (super-new)
    (define/public (m x [y 0])
      (+ x y))))

(object-method-arity-includes? (new c%) 'm 1)
(object-method-arity-includes? (new c%) 'm 2)
(object-method-arity-includes? (new c%) 'm 3)
(object-method-arity-includes? (new c%) 'n 1)
]}


@defproc[(field-names [object object?]) (listof symbol?)]{

返回 @racket[object] 中所有 field 名称的列表，包括从 superinterface 继承的 field，但不包括名称是本地的 field(即使用 @racket[define-local-member-name] 声明的)。

@examples[#:eval class-eval
  (field-names (new object%))
  (field-names (new (class object% (super-new) (field [x 0] [y 0]))))
]}


@defproc[(object-info [object object?]) (values (or/c class? #f) boolean?)]{

返回两个值，类似于 @racket[struct-info] 的返回值：
@itemize[

  @item{@racket[_class]: a class or @racket[#f]; the result is
  @racket[#f] if the current inspector does not control any class for
  which the @racket[object] is an instance.}

  @item{@racket[_skipped?]: @racket[#f] if the first result corresponds
  to the most specific class of @racket[object], @racket[#t]
  otherwise.}

]}


@defproc[(class-info [class class?])
         (values symbol?
                 exact-nonnegative-integer?
                 (listof symbol?)
                 (any/c exact-nonnegative-integer? . -> . any/c)
                 (any/c exact-nonnegative-integer? any/c . -> . any/c)
                 (or/c class? #f)
                 boolean?)]{

返回七个值，类似于 @racket[struct-type-info] 的返回值：

@itemize[

  @item{@racket[_name]: the class's name as a symbol;}

  @item{@racket[_field-cnt]: the number of fields (public and private)
   defined by the class;}

  @item{@racket[_field-name-list]: a list of symbols corresponding to the
  class's public fields; this list can be larger than @racket[_field-cnt]
  because it includes inherited fields;}

  @item{@racket[_field-accessor]: an accessor procedure for obtaining
  field values in instances of the class; the accessor takes an
  instance and a field index between @racket[0] (inclusive)
  and @racket[_field-cnt] (exclusive);}

  @item{@racket[_field-mutator]: a mutator procedure for modifying
  field values in instances of the class; the mutator takes an
  instance, a field index between @racket[0] (inclusive)
  and @racket[_field-cnt] (exclusive), and a new field value;}

  @item{@racket[_super-class]: a class for the most specific ancestor of
   the given class that is controlled by the current inspector,
   or @racket[#f] if no ancestor is controlled by the current
   inspector;}

  @item{@racket[_skipped?]: @racket[#f] if the sixth result is the most
   specific ancestor class, @racket[#t] otherwise.}

]}

@defstruct[(exn:fail:object exn:fail) ()]{

针对 @racket[class] 相关失败引发，例如尝试调用 object 不提供的 method。

}

@defproc[(class-seal [class class?]
                     [key symbol?]
                     [unsealed-inits (listof symbol?)]
                     [unsealed-fields (listof symbol?)]
                     [unsealed-methods (listof symbol?)]
                     [inst-proc (-> class? any)]
                     [member-proc (-> class? (listof symbol?) any)])
         class?]{

向给定 class 添加一个由 symbol @racket[key] 标识的 seal。给定的 @racket[unsealed-inits]、@racket[unsealed-fields] 和 @racket[unsealed-methods] 列出不受 sealing 影响的相应 class 成员。

当 class 有任何 seal 时，@racket[inst-proc] procedure 在实例化时被调用(通常用于在实例化时引发错误)，当 subclass 尝试添加未在 unsealed 列表中列出的 class 成员时，@racket[member-proc] 函数被调用(同样，通常用于引发错误)。

@racket[inst-proc] 被调用时传入尝试实例化的 class 值。@racket[member-proc] 被调用时传入 class 值以及初始化参数、field 或 method 名称的列表。
}

@defproc[(class-unseal [class class?]
                       [key symbol?]
                       [wrong-key-proc (-> class? any)])
         class?]{

移除先前使用 @racket[class-seal] 函数和给定 @racket[key] 密封的 class 上的 seal。

如果 unseal 移除了 class 中的所有 seal，class 值可以自由地实例化或子类化。如果给定的 class 值不包含任何 seal 或不包含具有给定 key 的任何 seal，则使用 class 值调用 @racket[wrong-key-proc] 函数。
}

@; ----------------------------------------------------------------------

@include-section["surrogate.scrbl"]

@close-eval[class-eval]
