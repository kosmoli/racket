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

@title[#:tag "mzlib:class" #:style 'toc]{Classes and Objects}

@guideintro["classes"]{classes and objects}

@note-lib[racket/class #:use-sources (racket/private/class-internal)]

A @deftech{class} specifies

@itemize[
 
 @item{a collection of fields;}

 @item{a collection of methods;}

 @item{initial value expressions for the fields;  and}

 @item{initialization variables that are bound to initialization
 arguments.}

]

In the context of the class system, an @defterm{object} is a
collection of bindings for fields that are instantiated according to a
class description.

The class system allows a program to define a new class (a
@deftech{derived class}) in terms of an existing class (the
@deftech{superclass}) using inheritance, overriding, and augmenting:

@itemize[

 @item{@deftech{inheritance}: An object of a derived class supports
 methods and instantiates fields declared by the derived class's
 superclass, as well as methods and fields declared in the derived
 class expression.}

 @item{@deftech{overriding}: Some methods declared in a superclass can
 be replaced in the derived class. References to the overridden method
 in the superclass use the implementation in the derived class.}

 @item{@deftech{augmenting}: Some methods declared in a superclass can
 be merely extended in the derived class. The superclass method
 specifically delegates to the augmenting method in the derived class.}

]

An @deftech{interface} is a collection of method names to be
implemented by a class, potentially with default implementations
some methods, combined with a @deftech{derivation requirement}. A
class @deftech{implements} an interface when it

@itemize[

 @item{declares (or inherits) a public method for each method in the
 interface (that does not have an implementation in the interface);}

 @item{is derived from the class required by the interface, if any; and}

 @item{specifically declares its intention to implement the interface.}

]

A class can implement any number of interfaces. A derived class
automatically implements any interface that its superclass
implements. Each class also implements an implicitly-defined interface
that is associated with the class. The implicitly-defined interface
contains all of the class's public method names, and it requires that
all other implementations of the interface are derived from the class.
When a class implements an interface but does not explicitly
declare an implementation of a method that has a default implementation
in the interface, then the default implementation is used for the class.

A new interface can @deftech{extend} one or more interfaces with
additional method names; each class that implements the extended
interface also implements the original interfaces. The derivation
requirements of the original interface must be consistent, and the
extended interface inherits the most specific derivation requirement
from the original interfaces.

Classes, objects, and interfaces are all values. However, a class or
interface is not an object (i.e., there are no ``meta-classes'' or
``meta-interfaces'').

@local-table-of-contents[]

@; ------------------------------------------------------------------------

@section[#:tag "createinterface"]{Creating Interfaces}

@guideintro["classes"]{classes, objects, and interfaces}

@defform/subs[(interface (super-interface-expr ...) name-clause ...)
              ([name-clause
                id
                (id contract-expr)
                (id #:public default-expr)
                (id #:override default-expr)
                (id contract-expr #:public impl-expr)
                (id contract-expr #:override impl-expr)])]{

Produces an interface. The @racket[id]s must be mutually distinct.

Each @racket[super-interface-expr] is evaluated (in order) when the
@racket[interface] expression is evaluated. The result of each
@racket[super-interface-expr] must be an interface value, otherwise
the @exnraise[exn:fail:object].  The interfaces returned by the
@racket[super-interface-expr]s are the new interface's
superinterfaces, which are all extended by the new interface. Any
class that implements the new interface also implements all of the
superinterfaces.

The result of an @racket[interface] expression is an interface that
includes all of the specified @racket[id]s, plus all identifiers from
the superinterfaces. A given @racket[id] may be paired with
a corresponding @racket[contract-expr], and it may have a @racket[impl-expr],
which supplies an implementation of @racket[id] to be inherited or overridden
in an implementing class. Each @racket[impl-expr] must
be a @racket[_method-procedure]; see @secref["clmethoddefs"].
Duplicate identifier names among the
superinterfaces are ignored, as long as no more than one of them provides
a default implementation for each identifier that originated in a
different interface.

An interface can provide an implementation of a method using
@racket[#:public] if no superinterface has an implementation of the
method, or using @racket[#:override] otherwise. If multiple superinterfaces
provide implementations of a method that originate from different ancestor
interfaces, then the method must be overridden. The @racket[super]
form is not supported within an interface method implementation.

If no @racket[super-interface-expr]s are provided, then the @tech{derivation
requirement} of the resulting interface is trivial: any class that
implements the interface must be derived from @racket[object%].
Otherwise, the implementation requirement of the resulting interface
is the most specific requirement from its superinterfaces. If the
superinterfaces specify inconsistent @tech{derivation requirements}, then
@exnraise[exn:fail:object] is raised.

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

Like @racket[interface], but also associates to the interface the
structure-type properties produced by the @racket[property-expr]s with
the corresponding @racket[val-expr]s.

Whenever the resulting interface (or a sub-interface derived from it)
is explicitly implemented by a class through the @racket[class*] form,
each property is attached with its value to a structure type that
instantiated by instances of the class. Specifically, the property is
attached to a structure type with zero immediate fields, which is
extended to produce the internal structure type for instances of the
class (so that no information about fields is accessible to the
structure type property's guard, if any).

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

@section[#:tag "createclass"]{Creating Classes}

@guideintro["classes"]{classes and objects}

@defthing[object% class?]{

A built-in class that has no methods fields, implements only its own
interface @racket[(class->interface object%)], and is transparent
(i.e,. its inspector is @racket[#f], so all immediate instances are
@racket[equal?]). All other classes are derived from @racket[object%].}


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

Produces a class value.

The @racket[superclass-expr] expression is evaluated when the
@racket[class*] expression is evaluated. The result must be a class
value (possibly @racket[object%]), otherwise the
@exnraise[exn:fail:object].  The result of the
@racket[superclass-expr] expression is the new class's superclass.

The @racket[interface-expr] expressions are also evaluated when the
@racket[class*] expression is evaluated, after
@racket[superclass-expr] is evaluated. The result of each
@racket[interface-expr] must be an interface value, otherwise the
@exnraise[exn:fail:object].  The interfaces returned by the
@racket[interface-expr]s are all implemented by the class. For each
identifier in each interface, the class (or one of its ancestors) must
declare a public method with the same name, otherwise the
@exnraise[exn:fail:object]. The class's superclass must satisfy the
implementation requirement of each interface, otherwise the
@exnraise[exn:fail:object].

An @racket[inspect] @racket[class-clause] selects an inspector (see
@secref["inspectors"]) for the class extension. The
@racket[inspector-expr] must evaluate to an inspector or @racket[#f]
when the @racket[class*] form is evaluated. Just as for structure
types, an inspector controls access to the class's fields, including
private fields, and also affects comparisons using @racket[equal?]. If
no @racket[inspect] clause is provided, access to the class is
controlled by the parent of the current inspector (see
@secref["inspectors"]). A syntax error is reported if more than one
@racket[inspect] clause is specified.

The other @racket[class-clause]s define initialization arguments,
public and private fields, and public and private methods. For each
@racket[id] or @racket[maybe-renamed] in a @racket[public],
@racket[override], @racket[augment], @racket[pubment],
@racket[overment], @racket[augride], @racket[public-final],
@racket[override-final], @racket[augment-final], or @racket[private]
clause, there must be one @racket[method-definition]. All other
definition @racket[class-clause]s create private fields. All remaining
@racket[expr]s are initialization expressions to be evaluated when the
class is instantiated (see @secref["objcreation"]).

The result of a @racket[class*] expression is a new class, derived
from the specified superclass and implementing the specified
interfaces. Instances of the class are created with the
@racket[instantiate] form or @racket[make-object] procedure, as
described in @secref["objcreation"].

Each @racket[class-clause] is (partially) macro-expanded to reveal its
shapes. If a @racket[class-clause] is a @racket[begin] expression, its
sub-expressions are lifted out of the @racket[begin] and treated as
@racket[class-clause]s, in the same way that @racket[begin] is
flattened for top-level and embedded definitions. Each @racket[class-clause]
has the @tech{syntax property} @racket['class-body] set to true before
expansion.

Within a @racket[class*] form for instances of the new class,
@racket[this] is bound to the object itself;
@racket[this%] is bound to the class of the object;
@racket[super-instantiate], @racket[super-make-object], and
@racket[super-new] are bound to forms to initialize fields in the
superclass (see @secref["objcreation"]); @racket[super] is
available for calling superclass methods (see
@secref["clmethoddefs"]); and @racket[inner] is available for
calling subclass augmentations of methods (see
@secref["clmethoddefs"]).}

@history[#:changed "8.8.0.10"
         @elem{Added the @racket['class-body] syntax property
          to class body forms.}]

@defform[(class superclass-expr class-clause ...)]{

Like @racket[class*], but omits the @racket[_interface-expr]s, for the case that none are needed.

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

@index['("self")]{Within} a @racket[class*] form, @racket[this] refers
to the current object (i.e., the object being initialized or whose
method was called). Use outside the body of a @racket[class*] form is
a syntax error.

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
                  
Within a @racket[class*] form, @racket[this%] refers to the class
of the current object (i.e., the object being initialized or whose
method was called).  Use outside the body of a @racket[class*] form is
a syntax error.

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

Like @racket[class*], but includes a sub-expression to be used as the
source for all syntax errors within the class definition. For example,
@racket[define-serializable-class] expands to @racket[class/derived]
so that errors in the body of the class are reported in terms of
@racket[define-serializable-class] instead of @racket[class].

The @racket[original-datum] is the original expression to use for
reporting errors.

The @racket[name-id] is used to name the resulting class; if it
is @racket[#f], the class name is inferred.

The @racket[super-expr], @racket[interface-expr]s, and
@racket[class-clause]s are as for @racket[class*].

If the @racket[deserialize-id-expr] is not literally @racket[#f], then
a serializable class is generated, and the result is two values
instead of one: the class and a deserialize-info structure produced by
@racket[make-deserialize-info]. The @racket[deserialize-id-expr]
should produce a value suitable as the second argument to
@racket[make-serialize-info], and it should refer to an export whose
value is the deserialize-info structure.

Future optional forms may be added to the sequence that currently ends
with @racket[deserialize-id-expr].}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsection[#:tag "clinitvars"]{Initialization Variables}

A class's initialization variables, declared with @racket[init],
@racket[init-field], and @racket[init-rest], are instantiated
for each object of a class. Initialization variables can be used in
the initial value expressions of fields, default value expressions
for initialization arguments, and in initialization expressions.  Only
initialization variables declared with @racket[init-field] can be
accessed from methods; accessing any other initialization variable
from a method is a syntax error.

The values bound to initialization variables are

@itemize[

 @item{the arguments provided with @racket[instantiate] or passed to
 @racket[make-object], if the object is created as a direct instance
 of the class; or,}

 @item{the arguments passed to the superclass initialization form or
 procedure, if the object is created as an instance of a derived
 class.}

]

If an initialization argument is not provided for an initialization
variable that has an associated @racket[_default-value-expr], then the
@racket[_default-value-expr] expression is evaluated to obtain a value
for the variable. A @racket[_default-value-expr] is only evaluated when
an argument is not provided for its variable. The environment of
@racket[_default-value-expr] includes all of the initialization
variables, all of the fields, and all of the methods of the class. If
multiple @racket[_default-value-expr]s are evaluated, they are
evaluated from left to right. Object creation and field initialization
are described in detail in @secref["objcreation"].

If an initialization variable has no @racket[_default-value-expr], then
the object creation or superclass initialization call must supply an
argument for the variable, otherwise the @exnraise[exn:fail:object].

Initialization arguments can be provided by name or by position.  The
external name of an initialization variable can be used with
@racket[instantiate] or with the superclass initialization form. Those
forms also accept by-position arguments. The @racket[make-object]
procedure and the superclass initialization procedure accept only
by-position arguments.

Arguments provided by position are converted into by-name arguments
using the order of @racket[init] and @racket[init-field] clauses and
the order of variables within each clause. When an @racket[instantiate]
form provides both by-position and by-name arguments, the converted
arguments are placed before by-name arguments. (The order can be
significant; see also @secref["objcreation"].)

Unless a class contains an @racket[init-rest] clause, when the number
of by-position arguments exceeds the number of declared initialization
variables, the order of variables in the superclass (and so on, up the
superclass chain) determines the by-name conversion.

If a class expression contains an @racket[init-rest] clause, there
must be only one, and it must be last. If it declares a variable, then
the variable receives extra by-position initialization arguments as a
list (similar to a dotted ``rest argument'' in a procedure).  An
@racket[init-rest] variable can receive by-position initialization
arguments that are left over from a by-name conversion for a derived
class. When a derived class's superclass initialization provides even
more by-position arguments, they are prefixed onto the by-position
arguments accumulated so far.

If too few or too many by-position initialization arguments are
provided to an object creation or superclass initialization, then the
@exnraise[exn:fail:object]. Similarly, if extra by-position arguments
are provided to a class with an @racket[init-rest] clause, the
@exnraise[exn:fail:object].

Unused (by-name) arguments are to be propagated to the superclass, as
described in @secref["objcreation"].  Multiple initialization
arguments can use the same name if the class derivation contains
multiple declarations (in different classes) of initialization
variables with the name. See @secref["objcreation"] for further
details.

See also @secref["extnames"] for information about internal and
external names.

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsection[#:tag "clfields"]{Fields}

Each @racket[field], @racket[init-field], and non-method
@racket[define-values] clause in a class declares one or more new
fields for the class. Fields declared with @racket[field] or
@racket[init-field] are public. Public fields can be accessed and
mutated by subclasses using @racket[inherit-field]. Public fields are
also accessible outside the class via @racket[class-field-accessor]
and mutable via @racket[class-field-mutator] (see
@secref["ivaraccess"]). Fields declared with @racket[define-values]
are accessible only within the class.

A field declared with @racket[init-field] is both a public field and
an initialization variable. See @secref["clinitvars"] for
information about initialization variables.

An @racket[inherit-field] declaration makes a public field defined by
a superclass directly accessible in the class expression. If the
indicated field is not defined in the superclass, the
@exnraise[exn:fail:object] when the class expression is evaluated.
Every field in a superclass is present in a derived class, even if it
is not declared with @racket[inherit-field] in the derived class. The
@racket[inherit-field] clause does not control inheritance, but merely
controls lexical scope within a class expression.

When an object is first created, all of its fields have the
@|undefined-const| value (see @secref["void"]). The fields of a
class are initialized at the same time that the class's initialization
expressions are evaluated; see @secref["objcreation"] for more
information.

See also @secref["extnames"] for information about internal and
external names.

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsection[#:tag "clmethods"]{Methods}

@subsubsection[#:tag "clmethoddefs"]{Method Definitions}

Each @racket[public], @racket[override], @racket[augment],
@racket[pubment], @racket[overment], @racket[augride],
@racket[public-final], @racket[override-final],
@racket[augment-final], and @racket[private]
clause in a class declares one or more method names. Each method name
must have a corresponding @racket[_method-definition]. The order of
@racket[public], @|etc|, clauses and their corresponding definitions
(among themselves, and with respect to other clauses in the class)
does not matter.

As shown in the grammar for @racket[class*], a method definition is
syntactically restricted to certain procedure forms, as defined by the
grammar for @racket[_method-procedure]; in the last two forms of
@racket[_method-procedure], the body @racket[id] must be one of the
@racket[id]s bound by @racket[let-values] or @racket[letrec-values]. A
@racket[_method-procedure] expression is not evaluated
directly. Instead, for each method, a class-specific method procedure
is created; it takes an initial object argument, in addition to the
arguments the procedure would accept if the @racket[_method-procedure]
expression were evaluated directly. The body of the procedure is
transformed to access methods and fields through the object argument.

A method declared with @racket[public], @racket[pubment], or
@racket[public-final] introduces a new method into a class. The method
must not be present already in the superclass or have an implementation
in any superinterface, otherwise the
@exnraise[exn:fail:object] when the class expression is evaluated. A
method declared with @racket[public] can be overridden in a subclass
that uses @racket[override], @racket[overment], or
@racket[override-final].  A method declared with @racket[pubment] can
be augmented in a subclass that uses @racket[augment],
@racket[augride], or @racket[augment-final]. A method declared with
@racket[public-final] cannot be overridden or augmented in a subclass.

A method declared with @racket[override], @racket[overment], or
@racket[override-final] overrides a definition already present in the
superclass or a superinterface. If the method is not already present, the
@exnraise[exn:fail:object] when the class expression is evaluated.  A
method declared with @racket[override] can be overridden again in a
subclass that uses @racket[override], @racket[overment], or
@racket[override-final].  A method declared with @racket[overment] can
be augmented in a subclass that uses @racket[augment],
@racket[augride], or @racket[augment-final]. A method declared with
@racket[override-final] cannot be overridden further or augmented in a
subclass.

A method declared with @racket[augment], @racket[augride], or
@racket[augment-final] augments a definition already present in the
superclass. If the method is not already present, the
@exnraise[exn:fail:object] when the class expression is evaluated.  A
method declared with @racket[augment] can be augmented further in a
subclass that uses @racket[augment], @racket[augride], or
@racket[augment-final]. A method declared with @racket[augride] can be
overridden in a subclass that uses @racket[override],
@racket[overment], or @racket[override-final]. (Such an override
merely replaces the augmentation, not the method that is augmented.)
A method declared with @racket[augment-final] cannot be overridden or
augmented further in a subclass.

A method declared with @racket[private] is not accessible outside the
class expression, cannot be overridden, and never overrides a method
in the superclass.

When a method is declared with @racket[override], @racket[overment],
or @racket[override-final], then the superclass or superinterface implementation of the
method can be called using @racket[super] form. If multiple superinterfaces
provide an implementation of the overridden method, then @racket[super]
raises @racket[exn:fail:object] when it is evaluated.

When a method is declared with @racket[pubment], @racket[augment], or
@racket[overment], then a subclass augmenting method can be called
using the @racket[inner] form. The only difference between
@racket[public-final] and @racket[pubment] without a corresponding
@racket[inner] is that @racket[public-final] prevents the declaration
of augmenting methods that would be ignored.

A method declared with @racket[abstract] must be declared without
an implementation. Subclasses may implement abstract methods via the
@racket[override], @racket[overment], or @racket[override-final]
forms. Any class that contains or inherits any abstract methods is
considered abstract and cannot be instantiated.

@defform*[[(super id arg ...)
           (super id arg ... . arg-list-expr)]]{

Always accesses the superclass method or a superinterface method, independent of whether the
method is overridden again in subclasses. Using the @racket[super]
form outside of @racket[class*] is a syntax error. Each @racket[arg]
is as for @racket[#%app]: either @racket[_arg-expr] or
@racket[_keyword _arg-expr].

The second form is analogous to using @racket[apply] with a procedure;
the @racket[arg-list-expr] must not be a parenthesized expression.}

@defform*[[(inner default-expr id arg ...)
           (inner default-expr id arg ... . arg-list-expr)]]{

If the object's class does not supply an augmenting method, then
@racket[default-expr] is evaluated, and the @racket[arg] expressions
are not evaluated. Otherwise, the augmenting method is called with the
@racket[arg] results as arguments, and @racket[default-expr] is not
evaluated. If no @racket[inner] call is evaluated for a particular
method, then augmenting methods supplied by subclasses are never
used. Using the @racket[inner] form outside of @racket[class*] is an
syntax error.

The second form is analogous to using @racket[apply] with a procedure;
the @racket[arg-list-expr] must not be a parenthesized expression.}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsubsection[#:tag "classinherit"]{Inherited and Superclass Methods}

Each @racket[inherit], @racket[inherit/super], @racket[inherit/inner],
@racket[rename-super], and @racket[rename-inner] clause declares one
or more methods that are defined in the class, but must be present in
the superclass. The @racket[rename-super] and @racket[rename-inner]
declarations are rarely used, since @racket[inherit/super] and
@racket[inherit/inner] provide the same access. Also, superclass and
augmenting methods are typically accessed through @racket[super] and
@racket[inner] in a class that also declares the methods, instead of
through @racket[inherit/super], @racket[inherit/inner],
@racket[rename-super], or @racket[rename-inner].

Method names declared with @racket[inherit], @racket[inherit/super],
or @racket[inherit/inner] access overriding declarations, if any, at
run time. Method names declared with @racket[inherit/super] can also
be used with the @racket[super] form to access the superclass
implementation, and method names declared with @racket[inherit/inner]
can also be used with the @racket[inner] form to access an augmenting
method, if any.
 
Method names declared with @racket[rename-super] always access the
superclass's implementation at run-time. Methods declared with
@racket[rename-inner] access a subclass's augmenting method, if any,
and must be called with the form

@racketblock[
(_id (lambda () _default-expr) _arg ...)
]

so that a @racket[default-expr] is available to evaluate when no
augmenting method is available. In such a form, @racket[lambda] is a
literal identifier to separate the @racket[default-expr] from the
@racket[arg]. When an augmenting method is available, it receives the
results of the @racket[arg] expressions as arguments.

Methods that are present in the superclass but not declared with
@racket[inherit], @racket[inherit/super], or @racket[inherit/inner] or
@racket[rename-super] are not directly accessible in the class
(though they can be called with @racket[send]).  Every public method
in a superclass is present in a derived class, even if it is not
declared with @racket[inherit] in the derived class; the
@racket[inherit] clause does not control inheritance, but merely
controls lexical scope within a class expression.

If a method declared with @racket[inherit], @racket[inherit/super],
@racket[inherit/inner], @racket[rename-super], or
@racket[rename-inner] is not present in the superclass, the
@exnraise[exn:fail:object] when the class expression is evaluated.

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

@subsubsection[#:tag "extnames"]{Internal and External Names}

Each method declared with @racket[public], @racket[override],
@racket[augment], @racket[pubment], @racket[overment],
@racket[augride], @racket[public-final], @racket[override-final],
@racket[augment-final], @racket[inherit], @racket[inherit/super],
@racket[inherit/inner], @racket[rename-super], and
@racket[rename-inner] can have separate internal and external names
when @racket[(internal-id external-id)] is used for declaring the
method. The internal name is used to access the method directly within
the class expression (including within @racket[super] or
@racket[inner] forms), while the external name is used with
@racket[send] and @racket[generic] (see @secref["ivaraccess"]).  If
a single @racket[id] is provided for a method declaration, the
identifier is used for both the internal and external names.

Method inheritance, overriding, and augmentation are based on external
names only.  Separate internal and external names are required for
@racket[rename-super] and @racket[rename-inner] (for historical
reasons, mainly).

Each @racket[init], @racket[init-field], @racket[field], or
@racket[inherit-field] variable similarly has an internal and an
external name. The internal name is used within the class to access
the variable, while the external name is used outside the class when
providing initialization arguments (e.g., to @racket[instantiate]),
inheriting a field, or accessing a field externally (e.g., with
@racket[class-field-accessor]). As for methods, when inheriting a
field with @racket[inherit-field], the external name is matched to an
external field name in the superclass, while the internal name is
bound in the @racket[class] expression.

A single identifier can be used as an internal identifier and an
external identifier, and it is possible to use the same identifier as
internal and external identifiers for different bindings. Furthermore,
within a single class, a single name can be used as an external method
name, an external field name, and an external initialization argument
name. Overall, each internal identifier must be distinct from all
other internal identifiers, each external method name must be distinct
from all other method names, each external field name must be distinct
from all other field names, and each initialization argument name must
be distinct from all other initialization argument names.

By default, external names have no lexical scope, which means, for
example, that an external method name matches the same syntactic
symbol in all uses of @racket[send]. The
@racket[define-local-member-name] and @racket[define-member-name] forms
introduce scoped external names.

When a @racket[class] expression is compiled, identifiers used in
place of external names must be symbolically distinct (when the
corresponding external names are required to be distinct), otherwise a
syntax error is reported. When no external name is bound by
@racket[define-member-name], then the actual external names are
guaranteed to be distinct when @racket[class] expression is evaluated.
When any external name is bound by @racket[define-member-name], the
@exnraise[exn:fail:object] by @racket[class] if the actual external
names are not distinct.


@defform[(define-local-member-name id ...)]{

Unless it appears as the top-level definition, binds each @racket[id]
so that, within the scope of the definition, each use of each
@racket[id] as an external name is resolved to a hidden name generated
by the @racket[define-local-member-name] declaration. Thus, methods,
fields, and initialization arguments declared with such external-name
@racket[id]s are accessible only in the scope of the
@racket[define-local-member-name] declaration.  As a top-level
definition, @racket[define-local-member-name] binds @racket[id] to its
symbolic form.

The binding introduced by @racket[define-local-member-name] is a
syntax binding that can be exported and imported with
@racket[module]s. Each evaluation of a
@racket[define-local-member-name] declaration generates a distinct
hidden name (except as a top-level definition). The
@racket[interface->method-names] procedure does not expose hidden
names.

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

Maps a single external name to an external name that is determined by
an expression. The value of @racket[key-expr] must be the result of either a
@racket[member-name-key] expression or a @racket[generate-member-key] call.}


@defform[(member-name-key identifier)]{

Produces a representation of the external name for @racket[id] in the
environment of the @racket[member-name-key] expression.}

@defproc[(generate-member-key) member-name-key?]{

Produces a hidden name, just like the binding for
@racket[define-local-member-name].}

@defproc[(member-name-key? [v any/c]) boolean?]{

Returns @racket[#t] for values produced by @racket[member-name-key]
and @racket[generate-member-key], @racket[#f]
otherwise.}

@defproc[(member-name-key=? [a-key member-name-key?] [b-key member-name-key?]) boolean?]{

Produces @racket[#t] if member-name keys @racket[a-key] and
@racket[b-key] represent the same external name, @racket[#f]
otherwise.}


@defproc[(member-name-key-hash-code [a-key member-name-key?]) integer?]{

Produces an integer hash code consistent with
@racket[member-name-key=?]  comparisons, analogous to
@racket[equal-hash-code].}

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

@section[#:tag "objcreation"]{Creating Objects}

The @racket[make-object] procedure creates a new object with
by-position initialization arguments, the @racket[new] form
creates a new object with by-name initialization arguments, and
the @racket[instantiate] form creates a new object with both
by-position and by-name initialization arguments.


All fields in the newly created object are initially bound to the
special @|undefined-const| value (see
@secref["void"]). Initialization variables with default value
expressions (and no provided value) are also initialized to
@|undefined-const|. After argument values are assigned to
initialization variables, expressions in @racket[field] clauses,
@racket[init-field] clauses with no provided argument,
@racket[init] clauses with no provided argument, private field
definitions, and other expressions are evaluated. Those
expressions are evaluated as they appear in the class expression,
from left to right.

Sometime during the evaluation of the expressions,
superclass-declared initializations must be evaluated once by
using the @racket[super-make-object] procedure,
@racket[super-new] form, or @racket[super-instantiate] form.

By-name initialization arguments to a class that have no matching
initialization variable are implicitly added as by-name arguments
to a @racket[super-make-object], @racket[super-new], or
@racket[super-instantiate] invocation, after the explicit
arguments.  If multiple initialization arguments are provided for
the same name, the first (if any) is used, and the unused
arguments are propagated to the superclass. (Note that converted
by-position arguments are always placed before explicit by-name
arguments.)  The initialization procedure for the
@racket[object%] class accepts zero initialization arguments; if
it receives any by-name initialization arguments, then
@exnraise[exn:fail:object].

If the end of initialization is reached for any class in the
hierarchy without invoking the superclass's initialization, the
@exnraise[exn:fail:object]. Also, if superclass initialization is
invoked more than once, the @exnraise[exn:fail:object].

Fields inherited from a superclass are not initialized until the
superclass's initialization procedure is invoked. In contrast,
all methods are available for an object as soon as the object is
created; the overriding of methods is not affected by
initialization (unlike objects in C++).



@defproc[(make-object [class class?] [init-v any/c] ...) object?]{

Creates an instance of @racket[class]. The @racket[init-v]s are
passed as initialization arguments, bound to the initialization
variables of @racket[class] for the newly created object as
described in @secref["clinitvars"]. If @racket[class] is not a
class, the @exnraise[exn:fail:contract].}

@defform[(new class-expr (id by-name-expr) ...)]{

Creates an instance of the value of @racket[class-expr] (which
must be a class), and the value of each @racket[by-name-expr] is
provided as a by-name argument for the corresponding
@racket[id].}

@defform[(instantiate class-expr (by-pos-expr ...) (id by-name-expr) ...)]{

Creates an instance of the value of @racket[class-expr] (which
must be a class), and the values of the @racket[by-pos-expr]s are
provided as by-position initialization arguments. In addition,
the value of each @racket[by-name-expr] is provided as a by-name
argument for the corresponding @racket[id].}

@defproc[(dynamic-instantiate [cls class?]
                              [pos-vs list?]
                              [named-vs (listof (cons/c symbol? any/c))])
         object?]{

Like @racket[(apply make-object cls pos-vs)], but @racket[named-vs]
supplies named arguments in addition to the by-position arguments
supplied by @racket[pos-vs].

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

Produces a procedure that takes by-position arguments an invokes
superclass initialization. See @secref["objcreation"] for more
information.}


@defform[(super-instantiate (by-pos-expr ...) (id by-expr ...) ...)]{


Invokes superclass initialization with the specified by-position and
by-name arguments. See @secref["objcreation"] for more
information.}


@defform[(super-new (id by-name-expr ...) ...)]{

Invokes superclass initialization with the specified by-name
arguments. See @secref["objcreation"] for more information.}

@; ------------------------------------------------------------------------

@section[#:tag "ivaraccess"]{Field and Method Access}

In expressions within a class definition, the initialization
variables, fields, and methods of the class are all part of the
environment. Within a method body, only the fields and other methods
of the class can be referenced; a reference to any other
class-introduced identifier is a syntax error.  Elsewhere within the
class, all class-introduced identifiers are available, and fields and
initialization variables can be mutated with @racket[set!].

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@subsection[#:tag "methodcalls"]{Methods}

Method names used within a class can only be used in the procedure position
of an application expression; any other use is a syntax error.

To allow methods to be applied to lists of arguments, a method
application can have the following form:

@specsubform[
(method-id arg ... . arg-list-expr)
]

This form calls the method in a way analogous to @racket[(apply
_method-id _arg ... _arg-list-expr)]. The @racket[arg-list-expr]
must not be a parenthesized expression.

Methods are called from outside a class with the @racket[send],
@racket[send/apply], and @racket[send/keyword-apply] forms.

@defform*[[(send obj-expr method-id arg ...)
           (send obj-expr method-id arg ... . arg-list-expr)]]{

Evaluates @racket[obj-expr] to obtain an object, and calls the method
with (external) name @racket[method-id] on the object, providing the
@racket[arg] results as arguments. Each @racket[arg] is as for
@racket[#%app]: either @racket[_arg-expr] or @racket[_keyword
_arg-expr]. In the second form, @racket[arg-list-expr] cannot be a
parenthesized expression.

If @racket[obj-expr] does not produce an object, the
@exnraise[exn:fail:contract]. If the object has no public method named
@racket[method-id], the @exnraise[exn:fail:object].}

@defform[(send/apply obj-expr method-id arg ... arg-list-expr)]{

Like the dotted form of @racket[send], but @racket[arg-list-expr] can
be any expression.}

@defform[(send/keyword-apply obj-expr method-id 
                             keyword-list-expr value-list-expr 
                             arg ... arg-list-expr)]{

Like @racket[send/apply], but with expressions for keyword and
argument lists like @racket[keyword-apply].}

@defproc[(dynamic-send [obj object?] 
                       [method-name symbol?]
                       [v any/c] ...
                       [#:<kw> kw-arg any/c] ...) any]{

Calls the method on @racket[obj] whose name matches
@racket[method-name], passing along all given @racket[v]s and
@racket[kw-arg]s.}


@defform/subs[(send* obj-expr msg ...+)
              ([msg (method-id arg ...)
                    (method-id arg ... . arg-list-expr)])]{

Calls multiple methods (in order) of the same object. Each
@racket[msg] corresponds to a use of @racket[send].

For example,

@racketblock[
(send* edit (begin-edit-sequence)
            (insert "Hello")
            (insert #\newline)
            (end-edit-sequence))
]

is the same as

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

Calls methods (in order) starting with the object produced by
@racket[obj-expr]. Each method call will be invoked on the result of
the last method call, which is expected to be an object. Each
@racket[msg] corresponds to a use of @racket[send].

This is the functional analogue of @racket[send*].

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

Extracts methods from an object and binds a local name that can be
applied directly (in the same way as declared methods within a class)
for each method. Each @racket[obj-expr] must produce an object,
which must have a public method named by the corresponding
@racket[method-id]. The corresponding @racket[id] is bound so that it
can be applied directly (see @secref["methodcalls"]).

Example:

@racketblock[
(let ([s (new stack%)])
  (with-method ([push (s push!)]
                [pop (s pop!)])
    (push 10)
    (push 9)
    (pop)))
]

is the same as

@racketblock[
(let ([s (new stack%)])
  (send s push! 10)
  (send s push! 9)
  (send s pop!))
]}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@subsection{Fields}

@defform[(get-field id obj-expr)]{

Extracts the field with (external) name @racket[id] from the value of
@racket[obj-expr].

If @racket[obj-expr] does not produce an object, the
@exnraise[exn:fail:contract]. If the object has no @racket[id] field,
the @exnraise[exn:fail:object].}

@defproc[(dynamic-get-field [field-name symbol?] [obj object?]) any/c]{

Extracts the field from @racket[obj] with the (external) name that
matches @racket[field-name]. If the object has no field matching @racket[field-name],
the @exnraise[exn:fail:object].}

@defform[(set-field! id obj-expr expr)]{

Sets the field with (external) name @racket[id] from the value of
@racket[obj-expr] to the value of @racket[expr].

If @racket[obj-expr] does not produce an object, the
@exnraise[exn:fail:contract].  If the object has no @racket[id] field,
the @exnraise[exn:fail:object].}

@defproc[(dynamic-set-field! [field-name symbol?] [obj object?] [v any/c]) void?]{

Sets the field from @racket[obj] with the (external) name that
matches @racket[field-name] to @racket[v]. If the object has no field matching @racket[field-name],
the @exnraise[exn:fail:object].}

@defform[(field-bound? id obj-expr)]{

Produces @racket[#t] if the object result of @racket[obj-expr] has a
field with (external) name @racket[id], @racket[#f] otherwise.

If @racket[obj-expr] does not produce an object, the
@exnraise[exn:fail:contract].}

@defform[(class-field-accessor class-expr field-id)]{

Returns an accessor procedure that takes an instance of the class
produced by @racket[class-expr] and returns the value of the object's
field with (external) name @racket[field-id].

If @racket[class-expr] does not produce a class, the
@exnraise[exn:fail:contract]. If the class has no @racket[field-id]
field, the @exnraise[exn:fail:object].}

@defform[(class-field-mutator class-expr field-id)]{

Returns a mutator procedure that takes an instance of the class
produced by @racket[class-expr] and a value, and sets the value of the
object's field with (external) name @racket[field-id] to the given
value. The result is @|void-const|.

If @racket[class-expr] does not produce a class, the
@exnraise[exn:fail:contract]. If the class has no @racket[field-id]
field, the @exnraise[exn:fail:object].}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

@subsection[#:tag "sec:generics"]{Generics}

A @deftech{generic} can be used instead of a method name to avoid the
cost of relocating a method by name within a class, making method
invocation more efficient.

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

Produces a generic that works on instances of the class or interface
produced by @racket[class-or-interface-expr] (or an instance of a
class/interface derived from @racket[class-or-interface]) to call the
method with (external) name @racket[id].

If @racket[class-or-interface-expr] does not produce a class or
interface, the @exnraise[exn:fail:contract]. If the resulting class or
interface does not contain a method named @racket[id], the
@exnraise[exn:fail:object].

See the introduction to @secref["sec:generics"] for some examples.
}

@defform*[[(send-generic obj-expr generic-expr arg ...)
           (send-generic obj-expr generic-expr arg ... . arg-list-expr)]]{

Calls a method of the object produced by @racket[obj-expr] as
indicated by the generic produced by @racket[generic-expr]. Each
@racket[arg] is as for @racket[#%app]: either @racket[_arg-expr] or
@racket[_keyword _arg-expr]. The second form is analogous to calling a
procedure with @racket[apply], where @racket[arg-list-expr] is not a
parenthesized expression.

If @racket[obj-expr] does not produce an object, or if
@racket[generic-expr] does not produce a generic, the
@exnraise[exn:fail:contract]. If the result of @racket[obj-expr] is
not an instance of the class or interface encapsulated by the result
of @racket[generic-expr], the @exnraise[exn:fail:object].

See the introduction to @secref["sec:generics"] for some examples.
}

@defproc[(make-generic [type (or/c class? interface?)]
                       [method-name symbol?])
         generic?]{

Like the @racket[generic] form, but as a procedure that accepts a
symbolic method name.}

@; ------------------------------------------------------------------------

@section[#:tag "mixins"]{Mixins}

@defform[(mixin (interface-expr ...) (interface-expr ...)
           class-clause ...)]{

Produces a @deftech{mixin}, which is a procedure that encapsulates a
class extension, leaving the superclass unspecified.  Each time that a
mixin is applied to a specific superclass, it produces a new derived
class using the encapsulated extension.

The given class must implement interfaces produced by the first set of
@racket[interface-expr]s.  The result of the procedure is a subclass
of the given class that implements the interfaces produced by the
second set of @racket[interface-expr]s. The @racket[class-clause]s are
as for @racket[class*], to define the class extension encapsulated by
the mixin.

Evaluation of a @racket[mixin] form checks that the
@racket[class-clause]s are consistent with both sets of
@racket[interface-expr]s.}

@; ------------------------------------------------------------------------

@section[#:tag "trait"]{Traits}

@note-lib-only[racket/trait]

A @deftech{trait} is a collection of methods that can be converted to
a @tech{mixin} and then applied to a @tech{class}. Before a trait is
converted to a mixin, the methods of a trait can be individually
renamed, and multiple traits can be merged to form a new trait.

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

Creates a @tech{trait}.  The body of a @racket[trait] form is similar to the
body of a @racket[class*] form, but restricted to non-private method
definitions.  In particular, the grammar of
@racket[maybe-renamed], @racket[method-definition], and
@racket[field-declaration] are the same as for @racket[class*], and
every @racket[method-definition] must have a corresponding declaration
(one of @racket[public], @racket[override], etc.).  As in
@racket[class], uses of method names in direct calls, @racket[super]
calls, and @racket[inner] calls depend on bringing method names into
scope via @racket[inherit], @racket[inherit/super],
@racket[inherit/inner], and other method declarations in the same
trait; an exception, compared to @racket[class] is that
@racket[overment] binds a method name only in the corresponding
method, and not in other methods of the same trait. Finally, macros
such as @racket[public*] and @racket[define/public] work in
@racket[trait] as in @racket[class].

External identifiers in @racket[trait], @racket[trait-exclude],
@racket[trait-exclude-field], @racket[trait-alias],
@racket[trait-rename], and @racket[trait-rename-field] forms are
subject to binding via @racket[define-member-name] and
@racket[define-local-member-name]. Although @racket[private] methods
or fields are not allowed in a @racket[trait] form, they can be
simulated by using a @racket[public] or @racket[field] declaration and
a name whose scope is limited to the @racket[trait] form.}


@defproc[(trait? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a trait, @racket[#f] otherwise.}


@defproc[(trait->mixin [tr trait?]) (class? . -> . class?)]{

Converts a @tech{trait} to a @tech{mixin}, which can be applied to a
@tech{class} to produce a new @tech{class}. An expression of the form

@racketblock[
(trait->mixin
 (trait
   _trait-clause ...))
]

is equivalent to

@racketblock[
(lambda (%)
  (class %
    _trait-clause ...
    (super-new)))
]

Normally, however, a trait's methods are changed and combined with
other traits before converting to a mixin.}


@defproc[(trait-sum [tr trait?] ...+) trait?]{

Produces a @tech{trait} that combines all of the methods of the given
@racket[tr]s. For example,

@racketblock[
(define t1
  (trait
    (define/public (m1) 1)))
(define t2
  (trait
    (define/public (m2) 2)))
(define t3 (trait-sum t1 t2))
]

creates a trait @racket[t3] that is equivalent to

@racketblock[
(trait
  (define/public (m1) 1)
  (define/public (m2) 2))
]

but @racket[t1] and @racket[t2] can still be used individually or
combined with other traits.

When traits are combined with @racket[trait-sum], the combination
drops @racket[inherit], @racket[inherit/super],
@racket[inherit/inner], and @racket[inherit-field] declarations when a
definition is supplied for the same method or field name by another
trait. The @racket[trait-sum] operation fails (the
@exnraise[exn:fail:contract]) if any of the traits to combine define a
method or field with the same name, or if an @racket[inherit/super] or
@racket[inherit/inner] declaration to be dropped is inconsistent with
the supplied definition. In other words, declaring a method with
@racket[inherit], @racket[inherit/super], or @racket[inherit/inner],
does not count as defining the method; at the same time, for example,
a trait that contains an @racket[inherit/super] declaration for a
method @racket[m] cannot be combined with a trait that defines
@racket[m] as @racket[augment], since no class could satisfy the
requirements of both @racket[augment] and @racket[inherit/super] when
the trait is later converted to a mixin and applied to a class.}


@defform[(trait-exclude trait-expr id)]{

Produces a new @tech{trait} that is like the @tech{trait} result of
@racket[trait-expr], but with the definition of a method named by
@racket[id] removed; as the method definition is removed, either an
@racket[inherit], @racket[inherit/super], or @racket[inherit/inner]
declaration is added:

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

If the trait produced by @racket[trait-expr] has no method definition for
@racket[id], the @exnraise[exn:fail:contract].}


@defform[(trait-exclude-field trait-expr id)]{

Produces a new @tech{trait} that is like the @tech{trait} result of
@racket[trait-expr], but with the definition of a field named by
@racket[id] removed; as the field definition is removed, an
@racket[inherit-field] declaration is added.}


@defform[(trait-alias trait-expr id new-id)]{

Produces a new @tech{trait} that is like the @tech{trait} result of
@racket[trait-expr], but the definition and declaration of the method
named by @racket[id] is duplicated with the name @racket[new-id]. The
consistency requirements for the resulting trait are the same as for
@racket[trait-sum], otherwise the @exnraise[exn:fail:contract]. This
operation does not rename any other use of @racket[id], such as in
method calls (even method calls to @racket[identifier] in the cloned
definition for @racket[new-id]).}


@defform[(trait-rename trait-expr id new-id)]{

Produces a new @tech{trait} that is like the @tech{trait} result of
@racket[trait-expr], but all definitions and references to methods
named @racket[id] are replaced by definitions and references to
methods named by @racket[new-id]. The consistency requirements for the
resulting trait are the same as for @racket[trait-sum], otherwise the
@exnraise[exn:fail:contract].}


@defform[(trait-rename-field trait-expr id new-id)]{

Produces a new @tech{trait} that is like the @tech{trait} result of
@racket[trait-expr], but all definitions and references to fields
named @racket[id] are replaced by definitions and references to fields
named by @racket[new-id]. The consistency requirements for the
resulting trait are the same as for @racket[trait-sum], otherwise the
@exnraise[exn:fail:contract].}

@; ------------------------------------------------------------------------

@section{Object and Class Contracts}

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
为类生成合约。

有两种主要类别的合同列在 @racket[class/c]
form: external and internal contracts. External contracts govern behavior
when an object is instantiated from a class or when methods or fields are
accessed via an object of that class. Internal contracts govern behavior
when method or fields are accessed within the class hierarchy. This
separation allows for stronger contracts for class clients and weaker
contracts for subclasses. Method contracts must contain an additional initial argument which corresponds
to the implicit @racket[this] parameter of the method.  This allows for
contracts which discuss the state of the object when the method is called
(or, for dependent contracts, in other parts of the contract).  Alternative
contract forms, such as @racket[->m], are provided as a shorthand
for writing method contracts.

Methods and fields listed in an @racket[absent] clause must @emph{not} be present in the class.

A class contract can be specified to be @emph{opaque} with the @racket[#:opaque]
keyword. An opaque class contract will only accept a class that defines
exactly the external methods and fields specified by the contract. A contract error
is raised if the contracted class contains any methods or fields that are
not specified. Methods or fields with local member names (i.e., defined with
@racket[define-local-member-name]) are ignored for this check if
@racket[#:ignore-local-member-names] is provided.

The external contracts are as follows:

@itemize[
 @item{An external method contract without a tag describes the behavior
   of the implementation of @racket[method-id] on method sends to an
   object of the contracted class.  This contract will continue to be
   checked in subclasses until the contracted class's implementation is
   no longer the entry point for dynamic dispatch.
   
   If only the field name is present, this is equivalent to insisting only
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

   If only the field name is present, this is equivalent to using the 
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
   
   If only the initialization argument name is present, this is equivalent to using the 
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
 @item{The contracts listed in an @racket[init-field] section are
   treated as if each contract appeared in an @racket[init] section and
   a @racket[field] section.}
]

The internal contracts restrict the behavior of method calls
made between classes and their subclasses; such calls are not
controlled by the class contracts described above. 

As with the external contracts, when a method or field name is specified
 but no contract appears, the contract is satisfied merely with the
 presence of the corresponding field or method.

@itemize[
 @item{A method contract tagged with @racket[inherit] describes the
   behavior of the method when invoked directly (i.e., via
   @racket[inherit]) in any subclass of the contracted class.  This
   contract, like external method contracts, applies until the
   contracted class's method implementation is no longer the entry point
   for dynamic dispatch.
   
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
  @item{A method contract tagged with @racket[super] describes the behavior of
   @racket[method-id] when called by the @racket[super] form in a
   subclass.  This contract only affects @racket[super] calls in
   subclasses which call the contract class's implementation of
   @racket[method-id].
   
   This example shows how to extend the @racket[draw] method
   so that if it is passed two arguments, it combines two
   calls to the original @racket[draw] method, but with a 
   contract the controls how the @racket[super] methods must
   be invoked.
   
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
 @item{A method contract tagged with @racket[inner] describes the
   behavior the class expects of an augmenting method in a subclass.
   This contract affects any implementations of @racket[method-id] in
   subclasses which can be called via @racket[inner] from the contracted
   class.  This means a subclass which implements @racket[method-id] via
   @racket[augment] or @racket[overment] stop future subclasses from
   being affected by the contract, since further extension cannot be
   reached via the contracted class.}
 @item{A method contract tagged with @racket[override] describes the
   behavior expected by the contracted class for @racket[method-id] when
   called directly (i.e. by the application @racket[(method-id ...)]).
   This form can only be used if overriding the method in subclasses
   will change the entry point to the dynamic dispatch chain (i.e., the
   method has never been augmentable).
   
   This time, instead of overriding @racket[draw] to support
   two arguments, we can make a new method, @racket[draw2] that
   takes the two arguments and calls @racket[draw]. We also
   add a contract to make sure that overriding @racket[draw]
   doesn't break @racket[draw2].   
   
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
 @item{A method contract tagged with either @racket[augment] or
   @racket[augride] describes the behavior provided by the contracted
   class for @racket[method-id] when called directly from subclasses.
   These forms can only be used if the method has previously been
   augmentable, which means that no augmenting or overriding
   implementation will change the entry point to the dynamic dispatch
   chain.  @racket[augment] is used when subclasses can augment the
   method, and @racket[augride] is used when subclasses can override the
   current augmentation.}
 @item{A field contract tagged with @racket[inherit-field] describes
   the behavior of the value contained in that field when accessed
   directly (i.e., via @racket[inherit-field]) in any subclass of the
   contracted class.  Since fields may be mutated, these contracts are
   checked on any access and/or mutation of the field that occurs in
   such subclasses.}

@history[#:changed "6.1.1.8"
         @string-append{Opaque class/c now optionally ignores local
                        member names if an additional keyword is supplied.}]
]}

@defform[(absent absent-spec ...)]{
See @racket[class/c];在 @racket[class/c] 表单是语法错误。
}

@defform[(->m dom ... range)]{
类似于 @racket[->]，但由此产生的合同的域名
包含比所述域多一个元素，其中第一个
（隐式）参数收缩于 @racket[any/c]。本合同为
当没有属性时，对于编写更简单的方法合约非常有用
@racket[this] 待完善。}

@defform[(->*m (mandatory-dom ...) (optional-dom ...) rest range)]{
类似于 @racket[->*]，除了的强制性域
生成的合约比指定的域多包含一个元素，
其中第一个（隐式）参数收缩于
@racket[any/c]。此合约对于编写更简单的方法很有用
合同，当没有任何属性 @racket[this] 待完善。}

@defform[(case->m (-> dom ... rest range) ...)]{
类似于 @racket[case->]，除了每个的强制性域
产生的合同的案例包含比所述元素多一个元素
域，其中第一个（隐式）参数与
@racket[any/c]。此合约对于编写更简单的方法很有用
合同，当没有任何属性 @racket[this] 待完善。}

@defform[(->dm (mandatory-dependent-dom ...)
               (optional-dependent-dom ...)
               dependent-rest
               pre-cond
               dep-range)]{
类似于 @racket[->d]，但由此产生的合同的强制性域名
包含比所述域多一个元素，其中第一个（隐式）参数收缩
与 @racket[any/c]此外， @racket[this] 在合同正文中得到适当约束。
当没有属性时，此合约对于编写更简单的方法合约非常有用
的 @racket[this] 待完善。}

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
生成对象的合约。 检查每个字段和方法
根据所提供的合同。 请注意，每个方法合约都应
被写入以接受额外的“this”参数；考虑使用 @racket[->m]
or @racket[->*m] 合约组合器。

 如果存在， @racket[opaque-expr] 控制方法如何
 存在于对象中，但未列在
 合同的处理：
 @itemlist[
 @item{If the @racket[opaque-expr] follows the keyword
   @racket[#:opaque] and it evaluates to @racket[#f], then
   calls to such methods are always allowed.}
 @item{If it follows @racket[#:opaque] and it evaluates to
   @racket[#t], then such methods are never allowed.}
 @item{If it follows @racket[#:opaque] and it
   evaluates to a predicate procedure produced by
   @racket[make-impersonator-property], then method procedures
   that have that property set are allowed.}
 @item{If the @racket[opaque-expr]
   follows the keyword @racket[#:opaque-except] then
   it must evaluate to a predicate procedure produced by
   @racket[make-impersonator-property]. In that case, methods that have
   that property are disallowed and others are allowed.}
 @item{ If no @racket[opaque-expr] is not present, then
   method methods calls to methods not listed in the contract
   are always allowed.}]

 方式类似于 @racket[opaque-expr] 但对于字段，
 @racket[opaque-fields-expr] 控制字段是如何
 存在于对象中，但未在合同中列出，
 已处理：
 @itemlist[
 @item{If @racket[opaque-fields-expr] is present and
   evaluates to @racket[#true], fields not listed in the
   contract are not allowed to be accessed.}
 @item{If @racket[opaque-fields-expr] is present and
   evaluates to @racket[#false], such fields are allowed to be
   accessed.}
 @item{ If @racket[opaque-fields-expr] is not present and
   @racket[opaque-expr] evaluates to a predicate procedure
   produced by @racket[make-impersonator-property] then the
   fields are disallowed if @racket[#:opaque] is present and
   allowed if @racket[#:opaque-except] is present. }
 @item{If @racket[opaque-fields-expr] is not present but
   @racket[opaque-expr] is, then @racket[opaque-fields-expr]
   defaults based on the value of @racket[opaque-expr],
   disallowing fields if @racket[opaque-expr] disallowed
   methods and allowing them if it does not. }]

 如果两者都不是 @racket[opaque-fields-expr] nor
 @racket[opaque-expr] 存在，所有未列出的字段和
 方法。

 如果
 @racket[#:do-not-check-class-field-accessor-or-mutator-access]
 存在，然后字段通过过程访问访问
 返回自 @racket[class-field-mutator] and
 @racket[class-field-accessor] 始终允许，即使
 否则它们将被拨号（要么是因为字段
 不允许访问或因为该字段违反了
 合同）。这种行为是可疑的，但对应于
 早期版本中存在的漏洞 @racket[object/c]
 十多年来，此选项旨在提供
 在向过渡的时机上具有灵活性，
 经过适当检查的合同。

}
@defproc[(instanceof/c [class-contract contract?]) contract?]{
为对象生成合约，其中对象是
符合以下条件的类实例： @racket[class-contract].
}

@defproc[(dynamic-object/c [method-names (listof symbol?)]
                           [method-contracts (listof contract?)]
                           [field-names (listof symbol?)]
                           [field-contracts (listof contract?)])
         contract?]{
为对象生成合约，类似于 @racket[object/c] 但是
其中方法和字段的名称和合约可以
动态计算。两者的名称和合约列表
方法和字段必须具有相同的长度。
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

生成对象的合约。

方法的每个合约的语义都与
对应的函数契约，但语法
方法合约必须直接写在
object-contract---非常类似于类中的方法
定义使用与常规函数相同的语法
定义，但不能是任意过程。与
方法合约，用于 @racket[class/c]，隐式 @racket[this]
参数不是合同的一部分。允许使用
@racket[this] 在从属合同中， @racket[->d] 合同
隐式绑定 @racket[this] 到对象本身。}


@defthing[mixin-contract contract?]{

A @tech{function contract} 识别混音。它保证
函数的输入是一个类，函数的结果是
输入的子类。}

@defproc[(make-mixin-contract [type (or/c class? interface?)] ...) contract?]{

产生 @tech{function contract} 这保证了输入到
function是一个类，它实现/子类每个 @racket[type]，和
函数的结果是输入的子类。}

@defproc[(is-a?/c [type (or/c class? interface?)]) flat-contract?]{

接受类或接口，并返回
识别实例化类/接口的对象。

查看 @racket[is-a?].}

@defproc[(implementation?/c [interface interface?]) flat-contract?]{

返回一个平面合约，该合约识别实现
@racket[interface].

See @racket[implementation?].}

@defproc[(subclass?/c [class class?]) flat-contract?]{

返回一个固定合约，该合约识别
是的子类 @racket[class].

See @racket[subclass?].}

@; ------------------------------------------------------------------------

@section[#:tag "objectequality"]{对象相等和哈希}

By default, objects that are instances of different classes or that
are instances of a non-transparent class are @racket[equal?] only if
they are @racket[eq?]. Like transparent structures, two objects that
are instances of the same transparent class (i.e., every superclass of
the class has @racket[#f] as its inspector) are @racket[equal?] when
their field values are @racket[equal?].

To customize the way that a class instance is compared to other
instances by @racket[equal?], implement the @racket[equal<%>]
interface.

@definterface[equal<%> ()]{

The @racket[equal<%>] 接口包括三个方法，它们是
类似于为结构类型提供的功能，
@racket[prop:equal+hash]:

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

The @racket[equal<%>] 接口是不寻常的，因为声明
接口的实现不同于继承
接口。只有当两个对象是
类，其最具体的祖先要显式实现
@racket[equal<%>] 是同一个祖先。

查看 @racket[prop:equal+hash] 了解有关平等的更多信息
比较和哈希代码。 @racket[equal<%>] 接口是
通过以下方式实现： @racket[interface*] and @racket[prop:equal+hash].}

Example:
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

@section[#:tag "objectserialize"]{Object Serialization}

@defform[
(define-serializable-class* class-id superclass-expr 
                                     (interface-expr ...)
  class-clause ...)
]{

Binds @racket[class-id] 到一个类，其中 @racket[superclass-expr],
the @racket[interface-expr]s和 @racket[class-clause]s如
@racket[class*].

此表单只能在顶层使用，无论是在模块中
或户外。该 @racket[class-id] 标识符绑定到新的
类，以及 @racketidfont{deserialize-info:}@racket[class-id] 也是
定义；如果定义在模块内，则后者是
由a提供 @racket[deserialize-info] 子模块通过 @racket[module+].

类的序列化可通过以下两种方式之一进行：

@itemize[

 @item{If the class implements the built-in interface
       @racket[externalizable<%>], then an object is serialized by
       calling its @racket[externalize] method; the result can be
       anything that is serializable (but, obviously, should not be
       the object itself). Deserialization creates an instance of the
       class with no initialization arguments, and then calls the
       object's @racket[internalize] method with the result of
       @racket[externalize] (or, more precisely, a deserialized
       version of the serialized result of a previous call).

       To support this form of serialization, the class must be
       instantiable with no initialization arguments. Furthermore,
       cycles involving only instances of the class (and other such
       classes) cannot be serialized.}

 @item{If the class does not implement @racket[externalizable<%>],
       then every superclass of the class must be either serializable
       or transparent (i.e,. have @racket[#f] as its
       inspector). Serialization and deserialization are fully
       automatic, and may involve cycles of instances.

       To support cycles of instances, deserialization may create an
       instance of the call with all fields as the undefined value,
       and then mutate the object to set the field
       values. Serialization support does not otherwise make an
       object's fields mutable.}

]

在第二种情况下，可序列化的子类可以实现
@racket[externalizable<%>]，在这种情况下， @racket[externalize]
方法负责所有序列化（即自动
子类的实例的序列化丢失）。在第一个
案例中，所有可序列化的子类都实现了
@racket[externalizable<%>]，因为子类实现了所有
其父类的接口。

在任何一种情况下，如果对象是子类的直接实例，
（它本身不可序列化） ，对象被序列化，就好像它
是可序列化类的直接实例。特别是，
覆盖声明 @racket[externalize] 方法被忽略
用于不可序列化子类的实例。}


@defform[
(define-serializable-class class-id superclass-expr
  class-clause ...)
]{

Like @racket[define-serializable-class*]，但没有接口
表达式（类似于 @racket[class]).}


@definterface[externalizable<%> ()]{

The @racket[externalizable<%>] 接口仅包括
@racket[externalize] and @racket[internalize] 方法。请参阅
@racket[define-serializable-class*] 想要查询更多的信息。}

@; ------------------------------------------------------------------------

@section[#:tag "objectprinting"]{Object Printing}

To customize the way that a class instance is printed by
@racket[print], @racket[write] and @racket[display], implement the
@racket[printable<%>] interface.

@defthing[printable<%> interface?]{

The @racket[printable<%>] 接口仅包括
@racket[custom-print], @racket[custom-write], and
@racket[custom-display] 方法。该 @racket[custom-print] 方法
接受两个参数：目的端口和当前端口
@racket[quasiquote] 深度作为精确的非负整数。
@racket[custom-write] and @racket[custom-display] 方法，每个接受
单个参数，即目的端口 @racket[write] or
@racket[display] 对象。

致电 @racket[custom-print], @racket[custom-write], or
@racket[custom-display] 方法类似于对附加过程的调用，
到结构类型，通过 @racket[prop:custom-write]
属性。特别是，递归打印可以触发从
通话。

查看 @racket[prop:custom-write] 欲了解更多详情，
@racket[printable<%>] 接口通过以下方式实现：
@racket[interface*] and @racket[prop:custom-write].}

@defthing[writable<%> interface?]{

Like @racket[printable<%>]，但仅包括
@racket[custom-write] and @racket[custom-display] 方法。
A @racket[print] 请求被定向到 @racket[custom-write].}

@; ------------------------------------------------------------------------

@section[#:tag "objectutils"]{对象、类和接口实用程序}

@defproc[(object? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] 什么是 “对象” @racket[#f] 否则

@examples[#:eval class-eval
  (object? (new object%))
  (object? object%)
  (object? "clam chowder")
]}


@defproc[(class? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] 什么是 “类” @racket[#f] 否则

@examples[#:eval class-eval
  (class? object%)
  (class? (class object% (super-new)))
  (class? (new object%))
  (class? "corn chowder")
]}


@defproc[(interface? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] 是一个接口， @racket[#f] 否则

@examples[#:eval class-eval
  (interface? (interface () empty cons first rest))
  (interface? object%)
  (interface? "gazpacho")
]}


@defproc[(generic? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{generic}, @racket[#f] 否则

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

确定是否 @racket[a] and @racket[b] 已从以下位置退回：
相同的呼叫 @racket[new] 或者不是。如果两个对象
有字段，此过程确定是否改变字段
其中一个会改变另一个的字段。

该程序在精神上类似于
@racket[eq?] 但也能与合同正常配合
（并有更强的保证）。

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

Like @racket[object=?]，但接受 @racket[#f] 对于任一参数和
returns @racket[#t] 如果两个参数都是 @racket[#f].

@examples[#:eval class-ctc-eval
   (object-or-false=? #f (new object%))
   (object-or-false=? (new object%) #f)
   (object-or-false=? #f #f)
   ]

@history[#:added "6.1.1.8"]}

@defproc[(object=-hash-code [o object?]) fixnum?]{
 返回的哈希代码 @racket[o] 对应于
 平等关系 @racket[object=?].

@history[#:added "7.1.0.6"]}

@defproc[(object->vector [object object?] [opaque-v any/c #f]) vector?]{

返回一个矢量，表示 @racket[object] 显示其
可检查字段，类似于 @racket[struct->vector].

@examples[#:eval class-eval
  (object->vector (new object%))
  (object->vector (new (class object%
                         (super-new)
                         (field [x 5] [y 10]))))
]}


@defproc[(class->interface [class class?]) interface?]{

返回隐式定义的接口 @racket[class].

@examples[#:eval class-eval
  (class->interface object%)
]}


@defproc[(object-interface [object object?]) interface?]{

返回由类隐式定义的接口
@racket[object].

@examples[#:eval class-eval
  (object-interface (new object%))
]}

 
@defproc[(is-a? [v any/c] [type (or/c interface? class?)]) boolean?]{

Returns @racket[#t] if @racket[v] 是类的实例
@racket[type] 或实现接口的类 @racket[type],
@racket[#f] 否则

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

Returns @racket[#t] if @racket[v] 是派生自（或等于）的类
至） @racket[cls], @racket[#f] 否则

@examples[#:eval class-eval
  (subclass? (class object% (super-new)) object%)
  (subclass? object% (class object% (super-new)))
  (subclass? object% object%)
]}


@defproc[(implementation? [v any/c] [intf interface?]) boolean?]{

Returns @racket[#t] if @racket[v] 是一个实现
@racket[intf], @racket[#f] 否则

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

Returns @racket[#t] if @racket[v] 是一个可扩展的接口，
@racket[intf], @racket[#f] 否则

@examples[#:eval class-eval
  (define point<%> (interface () get-x get-y))
  (define colored-point<%> (interface (point<%>) color))

  (interface-extension? colored-point<%> point<%>)
  (interface-extension? point<%> colored-point<%>)
  (interface-extension? (interface () get-x get-y get-z) point<%>)
]}


@defproc[(method-in-interface? [sym symbol?] [intf interface?]) boolean?]{

Returns @racket[#t] if @racket[intf] （或其任何祖先
接口）包括具有以下名称的成员 @racket[sym], @racket[#f]
否则

@examples[#:eval class-eval
  (define i<%> (interface () get-x get-y))
  (method-in-interface? 'get-x i<%>)
  (method-in-interface? 'get-z i<%>)
]}


@defproc[(interface->method-names [intf interface?]) (listof symbol?)]{

返回中的方法名称的符号列表 @racket[intf],
包括从超接口继承的方法，但不包括
名称为本地的方法（即，用
@racket[define-local-member-name]).

@examples[#:eval class-eval
  (define i<%> (interface () get-x get-y))
  (interface->method-names i<%>)
]}


@defproc[(object-method-arity-includes? [object object?] [sym symbol?] [cnt exact-nonnegative-integer?])
         boolean?]{

Returns @racket[#t] if @racket[object] 有一个方法名为 @racket[sym]
接受 @racket[cnt] 论证（arguments） @racket[#f] 否则

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

返回绑定在其中的所有字段名称的列表
@racket[object]，包括从超级接口继承的字段，但
不包括名称是本地的字段（即，用
@racket[define-local-member-name]).

@examples[#:eval class-eval
  (field-names (new object%))
  (field-names (new (class object% (super-new) (field [x 0] [y 0]))))
]}


@defproc[(object-info [object object?]) (values (or/c class? #f) boolean?)]{

返回两个值，类似于返回值
的值 @racket[struct-info]:
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

返回七个值，类似于返回值
的值 @racket[struct-type-info]:

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

需要创建违规记录的情况： @racket[class]-相关故障，例如试图致电
不是由对象提供的方法。

}

@defproc[(class-seal [class class?]
                     [key symbol?]
                     [unsealed-inits (listof symbol?)]
                     [unsealed-fields (listof symbol?)]
                     [unsealed-methods (listof symbol?)]
                     [inst-proc (-> class? any)]
                     [member-proc (-> class? (listof symbol?) any)])
         class?]{

向使用符号键的给定类添加印章 @racket[key]。该
given @racket[unsealed-inits], @racket[unsealed-fields], and
@racket[unsealed-methods] 列出对应的类成员
不受密封的影响。

当一个班级有任何印章时， @racket[inst-proc] 过程被调用
实例化时（通常，这用于在
实例化）和 @racket[member-proc] 函数被调用
（同样，这通常用于引发错误）当子类
尝试添加未在未密封列表中列出的类成员。

这 @racket[inst-proc] 使用类值调用，在该类值上
已尝试实例化。 @racket[member-proc] 通过以下方式调用
类值和初始化参数列表、字段或
方法名称。
}

@defproc[(class-unseal [class class?]
                       [key symbol?]
                       [wrong-key-proc (-> class? any)])
         class?]{

移除先前已用密封件密封的类别上的密封件
@racket[class-seal] 函数和给定的 @racket[key].

如果开封拆除了班级中的所有封条，班级
值可以自由实例化或子类化。如果给定
类值不包含或任何密封或不包含
任何带有给定密钥的密封件， @racket[wrong-key-proc] 函数
使用类值调用。
}

@; ----------------------------------------------------------------------

@include-section["surrogate.scrbl"]

@close-eval[class-eval]
