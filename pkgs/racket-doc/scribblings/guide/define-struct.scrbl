#lang scribble/doc
@(require scribble/manual scribble/eval scribble/bnf "guide-utils.rkt"
          (for-label racket/dict racket/serialize))

@(define posn-eval (make-base-eval))

@title[#:tag "define-struct"]{程序员定义的数据类型}

@refalso["structures"]{structure types}

新的数据类型通常使用 @racket[struct] 形式创建，这是本章的主题。基于 class 的对象系统将在 @secref["classes"] 中介绍，它提供了另一种创建数据类型的机制，但即使是 classes 和 objects 也是基于 structure types 实现的。

@; ------------------------------------------------------------
@section{Simple Structure Types: @racket[struct]}

@refalso["define-struct"]{@racket[struct]}

粗略来说，@racket[struct] 的语法是

@specform[
(struct struct-id (field-id ...))
]{}

@as-examples[@racketblock+eval[
#:eval posn-eval
(struct posn (x y))
]]

@racket[struct] 形式绑定 @racket[_struct-id] 以及由 @racket[_struct-id] 和 @racket[_field-id] 构建出的一些标识符：

@itemize[

 @item{@racket[_struct-id] : 一个 @deftech{constructor} 函数，
       接受与 @racket[_field-id] 数量相同的参数，
       并返回该 structure type 的一个实例。

       @examples[#:eval posn-eval (posn 1 2)]}

 @item{@racket[_struct-id]@racketidfont{?} : 一个 @deftech{predicate}
       函数，接受单个参数，如果是该 structure type 的实例则返回 @racket[#t]，
       否则返回 @racket[#f]。

       @examples[#:eval posn-eval (posn? 3) (posn? (posn 1 2))]}

 @item{对每个 @racket[_field-id]，@racket[_struct-id]@racketidfont{-}@racket[_field-id] :
       一个从结构类型实例中提取对应字段值的 @deftech{accessor}。

       @examples[#:eval posn-eval 
                 (posn-x (posn 1 2)) (posn-y (posn 1 2))]}

 @item{@racketidfont{struct:}@racket[_struct-id] :
       一个 @deftech{structure type descriptor}，即代表该 structure type 的一等值
       （配合 @racket[#:super] 使用，详见 @secref["struct-options"]）。}

]

@racket[struct] 形式对实例中字段可取的值种类没有任何限制。例如，@racket[(posn "apple" #f)] 会生成 @racket[posn] 的一个实例，即使 @racket["apple"] 和 @racket[#f] 对 @racket[posn] 的常见用法来说并非有效的坐标值。强制执行字段值限制（例如要求字段值必须是数值）通常是 contract 的工作，详见 @secref["contracts"]。

@; ------------------------------------------------------------
@section[#:tag "struct-copy"]{复制与更新}

@racket[struct-copy] 形式会为结构创建一个副本，并可以选择性地更新其中的
指定字段。该过程有时被称为 @deftech{functional update}，因为结果是字段值被更新后的新结构，
但原始结构不会被修改。

@specform[
(struct-copy struct-id struct-expr [field-id expr] ...)
]

@racket[struct-copy] 后的 @racket[_struct-id] 必须是由 @racket[struct] 绑定的 structure type 名称。
@racket[_struct-expr] 必须生成一个该 structure type 的实例。结果是一个新的 structure type 实例，
与原始实例相同，但每个 @racket[_field-id] 指示的字段会被更新为对应 @racket[_expr] 的值。

@examples[
#:eval posn-eval 
(define p1 (posn 1 2))
(define p2 (struct-copy posn p1 [x 3]))
(list (posn-x p2) (posn-y p2))
(list (posn-x p1) (posn-y p1))
]


@; ------------------------------------------------------------
@section[#:tag "struct-subtypes"]{结构子类型}

@racket[struct] 的扩展形式可用于定义 @defterm{structure subtype}，即扩展已有 structure type 的 structure type：

@specform[
(struct struct-id super-id (field-id ...))
]

@racket[_super-id] 必须是由 @racket[struct] 绑定的 structure type 名称（即不能直接作为表达式使用的名称）。

@as-examples[@racketblock+eval[
#:eval posn-eval 
(struct posn (x y))
(struct 3d-posn posn (z))
]]

structure subtype 会继承其 supertype 的字段，子类型构造函数在接收 supertype 字段值之后接收子类型字段值。
structure subtype 的实例可以使用 supertype 的 predicate 和 accessors。

@examples[
#:eval posn-eval 
(define p (3d-posn 1 2 3))
p
(posn? p)
(3d-posn-z p)
(code:comment "a 3d-posn has an x field, but there is no 3d-posn-x selector:")
(3d-posn-x p)
(code:comment "use the supertype's posn-x selector to access the x field:")
(posn-x p)
]

@; ------------------------------------------------------------
@section[#:tag "trans-struct"]{Opaque 与 Transparent Structure Types}

有这样的结构类型定义：

@racketblock[
(struct posn (x y))
]

structure type 的实例在打印时不会显示任何关于字段值的信息。
也就是说，structure types 默认是 @deftech{opaque}。如果 structure type 的 accessors 和 mutators
被保持在模块私有，其他模块就无法依赖该类型实例的内部表示。

要使 structure type 变为 @deftech{transparent}，请在字段名序列后使用 @racket[#:transparent] 关键字：

@def+int[
#:eval posn-eval
(struct posn (x y)
        #:transparent)
(posn 1 2)
]

transparent structure type 的实例打印形式就像对构造函数的调用一样，以便显示结构的字段值。
transparent structure type 还允许对其实例使用反射操作，例如 @racket[struct?] 和 @racket[struct-info]
（参见 @secref["reflection"]）。

structure types 默认是 opaque 的，因为 opaque 的 structure 实例提供了更强的封装保证。
也就是说，一个库可以使用 opaque structure 来封装数据，库的客户端除了允许的方式之外无法操作结构中的数据。

@; ------------------------------------------------------------
@section[#:tag "struct-equal"]{结构类型比较}

泛型的 @racket[equal?] 比较会自动递归地比较 transparent structure type 的字段，
但对于 opaque structure types，@racket[equal?] 默认仅比较实例的同一性：

@def+int[
#:eval posn-eval
(struct glass (width height) #:transparent)
(equal? (glass 1 2) (glass 1 2))
]
@def+int[
#:eval posn-eval
(struct lead (width height))
(define slab (lead 1 2))
(equal? slab slab)
(equal? slab (lead 1 2))
]

要在不将 structure type 变为 transparent 的情况下支持通过 @racket[equal?] 进行实例比较，
可以使用 @racket[#:methods] 关键字、@racket[gen:equal+hash]，并实现三个方法：

@def+int[
#:eval posn-eval
(struct lead (width height)
  #:methods
  gen:equal+hash
  [(define (equal-proc a b equal?-recur)
     (code:comment @#,t{compare @racket[a] and @racket[b]})
     (and (equal?-recur (lead-width a) (lead-width b))
          (equal?-recur (lead-height a) (lead-height b))))
   (define (hash-proc a hash-recur)
     (code:comment @#,t{compute primary hash code of @racket[a]})
     (+ (hash-recur (lead-width a))
        (* 3 (hash-recur (lead-height a)))))
   (define (hash2-proc a hash2-recur)
     (code:comment @#,t{compute secondary hash code of @racket[a]})
     (+ (hash2-recur (lead-width a))
             (hash2-recur (lead-height a))))])
(equal? (lead 1 2) (lead 1 2))
]

列表中的第一个函数实现对两个 @racket[lead] 的 @racket[equal?] 测试；
该函数的第三个参数替代 @racket[equal?] 进行递归相等性测试，以便正确处理数据循环。
另外两个函数分别计算用于 @tech{hash tables} 的主哈希值和次哈希值：

@interaction[
#:eval posn-eval
(define h (make-hash))
(hash-set! h (lead 1 2) 3)
(hash-ref h (lead 1 2))
(hash-ref h (lead 2 1))
]

@racket[gen:equal+hash] 中的第一个函数并不要求递归比较结构的字段。
例如，表示集合的 structure type 可以通过检查集合成员是否相同来实现相等性，
而不依赖于内部表示中元素的顺序。只需注意，对任何两个被视为等价的 structure types，
哈希函数都必须产生相同的值。

@; ------------------------------------------------------------
@section{Structure Type 的生成性}

每次对 @racket[struct] 形式求值时，它都会生成一个与所有现有 structure types
不同的新 structure types，即使其他 structure type 具有相同的名称和字段也是如此。

这种生成性对于强制抽象和实现 interpreter 等程序很有用，
但需注意不要将 @racket[struct] 形式放在会被多次求值的位置。

@defexamples[
(define (add-bigger-fish lst)
  (struct fish (size) #:transparent) (code:comment #,(t "new every time"))
  (cond
   [(null? lst) (list (fish 1))]
   [else (cons (fish (* 2 (fish-size (car lst))))
               lst)]))

(add-bigger-fish null)
(add-bigger-fish (add-bigger-fish null))
]
@defs+int[
[(struct fish (size) #:transparent)
 (define (add-bigger-fish lst)
   (cond
    [(null? lst) (list (fish 1))]
    [else (cons (fish (* 2 (fish-size (car lst))))
                lst)]))]
(add-bigger-fish (add-bigger-fish null))
]

@; ------------------------------------------------------------
@section[#:tag "prefab-struct"]{Prefab Structure Types}

虽然 @tech{transparent} structure type 打印时会显示其内容，但无法在表达式中
使用其打印形式来重建该结构，这与数值、string、symbol 或 list 的打印形式不同。

@deftech{prefab}（"预先 fabricated"）structure type 是一种内建类型，被 Racket 的
printer 和表达式 reader 所知晓。存在无限多种此类类型，它们按名称、字段数量、超
类型及其他细节索引。prefab 结构的打印形式类似于 vector，但以 @litchar{#s} 开头
而非仅仅是 @litchar{#}，且打印形式的第一个元素是 prefab structure type 的名称。

下面的示例展示了一个字段的 @racketidfont{sprout} prefab structure type 的实例。
第一个实例的字段值为 @racket['bean]，第二个的字段值为 @racket['alfalfa]：

@interaction[
'#s(sprout bean)
'#s(sprout alfalfa)
]

与数值和 strings 一样，prefab 结构是 "self-quoting" 的，因此上面的引号是可选的：

@interaction[
#s(sprout bean)
]

将 @racket[#:prefab] 关键字与 @racket[struct] 一起使用时，
你不是在生成新的 structure type，而是获得与现有 prefab structure type 配合工作的 bindings：

@interaction[
#:eval posn-eval
(define lunch '#s(sprout bean))
(struct sprout (kind) #:prefab)
(sprout? lunch)
(sprout-kind lunch)
(sprout 'garlic)
]

上面的字段名 @racketidfont{kind} 并不影响查找 prefab structure type；
只有名称 @racketidfont{sprout} 和字段数量才重要。同时，具有三个字段的
@racketidfont{sprout} prefab structure type 与仅有一个字段的 @racketidfont{sprout} 是不同的 structure types：

@interaction[
#:eval posn-eval
(sprout? #s(sprout bean #f 17))
(code:line (struct sprout (kind yummy? count) #:prefab) (code:comment @#,t{redefine}))
(sprout? #s(sprout bean #f 17))
(sprout? lunch)
]

一个 prefab structure type 可以将另一个 prefab structure type 作为其 supertype，
它可以有 mutable 字段，也可以有 auto 字段。这些维度上的任何变化都对应着不同的
prefab structure types，structure type 名称的打印形式编码了所有相关细节。

@interaction[
(struct building (rooms [location #:mutable]) #:prefab)
(struct house building ([occupied #:auto]) #:prefab
  #:auto-value 'no)
(house 5 'factory)
]

每个 @tech{prefab} structure type 都是 @tech{transparent} 的 — 但甚至比 @tech{transparent}
类型更不抽象，因为实例可以在无需访问特定 structure-type 声明或现有示例的情况下创建。
总体而言，structure types 的不同选项提供了一个从更抽象到更便捷的可能性光谱：

@itemize[

 @item{@tech{Opaque}（默认）: 无法在无法访问结构类型声明的情况下检查或伪造实例。
       正如下一节所讨论的，可以将 @tech{constructor guards} 和
       @tech{properties} 附加到 structure type 上，以进一步保护或特化实例的行为。}

 @item{@tech{Transparent} : 任何人都可以在无需访问 structure-type 声明的情况下检查或创建实例，
       这意味着值 printer 可以显示实例的内容。不过，所有实例创建都经过 @tech{constructor guard}，
       因此可以控制实例的内容，并通过 @tech{properties} 特化实例的行为。
       由于 structure type 由其定义生成，不能仅通过 structure type 的名称来制造实例，
       因此表达式 reader 无法自动生成实例。}

 @item{@tech{Prefab} : 任何人都可以在任意时刻检查或创建实例，
       无需预先访问 structure-type 声明或示例实例。因此，表达式 reader 可以直接制造实例。
       实例不能具有 @tech{constructor guard} 或 @tech{properties}。}

]

由于表达式 reader 可以生成 @tech{prefab} 实例，当便捷的 @tech{serialization}
比抽象更重要时，它们十分有用。不过，如果如 @secref["serialization"] 中所述，
用 @racket[serializable-struct] 定义，@tech{Opaque} 和 @tech{transparent} 结构也可以被序列化。

@; ------------------------------------------------------------
@section[#:tag "struct-options"]{更多 Structure Type Options}

@racket[struct] 的完整语法支持多个选项，既可以在 structure-type 级别，也可以在单个字段级别设置：

@specform/subs[(struct struct-id maybe-super (field ...)
                       struct-option ...)
               ([maybe-super code:blank
                             super-id]
                [field field-id
                       [field-id field-option ...]])]

@racket[_struct-option] 总是以关键字开头：

 @specspecsubform[#:mutable]{

    使结构的所有字段变为 mutable，并为每个 @racket[_field-id] 引入一个
    @deftech{mutator} @racketidfont{set-}@racket[_struct-id]@racketidfont{-}@racket[_field-id]@racketidfont{!}，
    用于设置 structure type 实例中对应字段的值。

     @defexamples[(struct dot (x y) #:mutable)
                  (define d (dot 1 2))
                  (dot-x d)
                  (set-dot-x! d 10)
                  (dot-x d)]

   @racket[#:mutable] 选项也可以作为 @racket[_field-option] 使用，
此时它使单个字段变为 mutable。
       
   @defexamples[
   (struct person (name [age #:mutable]))
   (define friend (person "Barney" 5))
   (set-person-age! friend 6)
   (set-person-name! friend "Mary")]}

 @specspecsubform[(code:line #:transparent)]{
  Controls reflective access to structure instances, as discussed
  in a previous section, @secref["trans-struct"].}

 @specspecsubform[(code:line #:inspector inspector-expr)]{
  Generalizes @racket[#:transparent] to support more controlled access
  to reflective operations.}

 @specspecsubform[(code:line #:prefab)]{
  Accesses a built-in structure type, as discussed
  in a previous section, @secref["prefab-struct"].}

 @specspecsubform[(code:line #:auto-value auto-expr)]{

  Specifies a value to be used for all automatic fields in the
  structure type, where an automatic field is indicated by the
  @racket[#:auto] field option. The constructor procedure does not
  accept arguments for automatic fields. Automatic fields are
  implicitly mutable (via reflective operations), but mutator
  functions are bound only if @racket[#:mutable] is also specified.

  @defexamples[
    (struct posn (x y [z #:auto])
                 #:transparent
                 #:auto-value 0)
    (posn 1 2)
  ]}

@;-- FIXME:
@;-- Explain when to use guards instead of contracts, and vice versa

 @specspecsubform[(code:line #:guard guard-expr)]{ Specifies a
  @deftech{constructor guard} procedure to be called whenever an
  instance of the structure type is created. The guard takes as many
  arguments as non-automatic fields in the structure type, plus one
  more for the name of the instantiated type (in case a sub-type is
  instantiated, in which case it's best to report an error using the
  sub-type's name). The guard should return the same number of values
  as given, minus the name argument. The guard can raise an exception
  if one of the given arguments is unacceptable, or it can convert an
  argument.

 @defexamples[
   #:eval posn-eval
   (struct thing (name)
           #:transparent
           #:guard (lambda (name type-name)
                     (cond
                       [(string? name) name]
                       [(symbol? name) (symbol->string name)]
                       [else (error type-name 
                                    "bad name: ~e" 
                                    name)])))
   (thing "apple")
   (thing 'apple)
   (thing 1/2)
  ]

  The guard is called even when subtype instances are created. In that
  case, only the fields accepted by the constructor are provided to
  the guard (but the subtype's guard gets both the original fields and
  fields added by the subtype).

 @defexamples[
  #:eval posn-eval
  (struct person thing (age)
          #:transparent
          #:guard (lambda (name age type-name)
                    (if (negative? age)
                        (error type-name "bad age: ~e" age)
                        (values name age))))
  (person "John" 10)
  (person "Mary" -1)
  (person 10 10)]}

 @specspecsubform[(code:line #:methods interface-expr [body ...])]{
  关联与 structure type 对应的、针对 @defterm{generic interface} 的方法定义。
  例如，实现 @racket[gen:dict] 的方法允许 structure type 的实例被当作字典使用。
  实现 @racket[gen:custom-write] 的方法允许自定义 structure type 实例的 @racket[display] 方式。

  @defexamples[
    (struct cake (candles)
            #:methods gen:custom-write
            [(define (write-proc cake port mode)
               (define n (cake-candles cake))
               (show "   ~a   ~n" n #\. port)
               (show " .-~a-. ~n" n #\| port)
               (show " | ~a | ~n" n #\space port)
               (show "---~a---~n" n #\- port))
             (define (show fmt n ch port)
               (fprintf port fmt (make-string n ch)))])
    (display (cake 5))]}

 @specspecsubform[(code:line #:property prop-expr val-expr)]{
   关联一个 @deftech{property} 及其值到 structure type 上。
  例如，@racket[prop:procedure] property 允许 structure 实例被当作函数使用；
  property 值决定了当 structure 作为函数时调用的实现方式。

 @defexamples[
   (struct greeter (name)
           #:property prop:procedure
                      (lambda (self other)
                        (string-append
                         "Hi " other
                         ", I'm " (greeter-name self))))
   (define joe-greet (greeter "Joe"))
   (greeter-name joe-greet)
   (joe-greet "Mary")
   (joe-greet "John")]}

 @specspecsubform[(code:line #:super super-expr)]{

  替代在 @racket[_struct-id] 旁边提供 @racket[_super-id] 的方式。
  由于 structure type 的名称不是表达式，@racket[_super-expr] 应该生成一个
  @tech{structure type descriptor} 值。@racket[#:super] 的一个优势是
  structure type descriptors 是值，因此可以传递给 procedures。

  @defexamples[
    #:eval posn-eval
    (define (raven-constructor super-type)
      (struct raven ()
              #:super super-type
              #:transparent
              #:property prop:procedure (lambda (self)
                                          'nevermore))
      raven)
    (let ([r ((raven-constructor struct:posn) 1 2)])
      (list r (r)))
    (let ([r ((raven-constructor struct:thing) "apple")])
      (list r (r)))]}

@; ----------------------------------------

@refdetails["structures"]{structure types}

@close-eval[posn-eval]
