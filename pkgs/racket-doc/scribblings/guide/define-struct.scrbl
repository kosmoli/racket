#lang scribble/doc
@(require scribble/manual scribble/eval scribble/bnf "guide-utils.rkt"
          (for-label racket/dict racket/serialize))

@(define posn-eval (make-base-eval))

@title[#:tag "define-struct"]{Programmer-Defined Datatypes}

@refalso["structures"]{structure types}

新的数据类型通常使用 @racket[struct] 形式创建，这是本章的主题。基于类的对象系统
（我们推迟到 @secref["classes"] 讨论）提供了创建新数据类型的另一种机制，
但即使是类和对象也是基于结构类型来实现的。

@; ------------------------------------------------------------
@section{Simple Structure Types: @racket[struct]}

@refalso["define-struct"]{@racket[struct]}

粗略地看，@racket[struct] 的语法是

@specform[
(struct struct-id (field-id ...))
]{}

@as-examples[@racketblock+eval[
#:eval posn-eval
(struct posn (x y))
]]

@racket[struct] 形式绑定 @racket[_struct-id] 以及从 @racket[_struct-id] 和
@racket[_field-id] 构建的多个标识符：

@itemize[

 @item{@racket[_struct-id] : 一个 @deftech{constructor} 函数，
       接受与 @racket[_field-id] 数量相同的参数，
       并返回结构类型的一个实例。

       @examples[#:eval posn-eval (posn 1 2)]}

 @item{@racket[_struct-id]@racketidfont{?} : 一个 @deftech{predicate}
       函数，接受单个参数，如果它是结构类型的实例则返回 @racket[#t]，
       否则返回 @racket[#f]。

       @examples[#:eval posn-eval (posn? 3) (posn? (posn 1 2))]}

 @item{@racket[_struct-id]@racketidfont{-}@racket[_field-id] : 对于
       每个 @racket[_field-id]，一个 @deftech{accessor}，用于从结构类型的实例中
       提取对应字段的值。

       @examples[#:eval posn-eval 
                 (posn-x (posn 1 2)) (posn-y (posn 1 2))]}

 @item{@racketidfont{struct:}@racket[_struct-id] : 一个
       @deftech{structure type descriptor}，它是一个将结构类型表示为一等值的值
       （通过 @racket[#:super]，稍后在 @secref["struct-options"] 中讨论）。}

]

@racket[struct] 形式对结构类型实例中字段可以出现的值的种类不施加任何约束。
例如，@racket[(posn "apple" #f)] 会产生 @racket[posn] 的一个实例，
即使 @racket["apple"] 和 @racket[#f] 对于 @racket[posn] 实例的明显用途来说
不是有效的坐标。对字段值实施约束（例如要求它们是数字）通常是 contract 的工作，
如稍后在 @secref["contracts"] 中讨论的那样。

@; ------------------------------------------------------------
@section[#:tag "struct-copy"]{Copying and Update}

@racket[struct-copy] 形式克隆一个结构并可选地更新克隆中的指定字段。
这个过程有时称为 @deftech{functional update}，因为结果是一个具有更新字段值的结构，
但原始结构不会被修改。

@specform[
(struct-copy struct-id struct-expr [field-id expr] ...)
]

出现在 @racket[struct-copy] 之后的 @racket[_struct-id] 必须是由 @racket[struct] 绑定的结构类型名称。
@racket[_struct-expr] 必须产生结构类型的一个实例。结果是结构类型的一个新实例，
与旧实例类似，只是每个 @racket[_field-id] 指示的字段获得对应 @racket[_expr] 的值。

@examples[
#:eval posn-eval 
(define p1 (posn 1 2))
(define p2 (struct-copy posn p1 [x 3]))
(list (posn-x p2) (posn-y p2))
(list (posn-x p1) (posn-y p1))
]


@; ------------------------------------------------------------
@section[#:tag "struct-subtypes"]{Structure Subtypes}

@racket[struct] 的扩展形式可用于定义 @defterm{structure subtype}，
即扩展现有结构类型的结构类型：

@specform[
(struct struct-id super-id (field-id ...))
]

@racket[_super-id] 必须是由 @racket[struct] 绑定的结构类型名称（即不能直接用作表达式的名称）。

@as-examples[@racketblock+eval[
#:eval posn-eval 
(struct posn (x y))
(struct 3d-posn posn (z))
]]

结构子类型继承其父类型的字段，子类型的 constructor 在父类型字段的值之后接受子类型字段的值。
结构子类型的实例可以与父类型的 predicate 和 accessor 一起使用。

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
@section[#:tag "trans-struct"]{Opaque versus Transparent Structure Types}

使用如下结构类型定义

@racketblock[
(struct posn (x y))
]

结构类型的实例以不显示任何字段值信息的方式打印。也就是说，结构类型默认是 @deftech{opaque}。
如果结构类型的 accessor 和 mutator 对模块保持私有，则其他模块无法依赖该类型实例的表示。

要使结构类型 @deftech{transparent}，请在字段名序列之后使用 @racket[#:transparent] 关键字：

@def+int[
#:eval posn-eval
(struct posn (x y)
        #:transparent)
(posn 1 2)
]

transparent 结构类型的实例打印得像对 constructor 的调用，因此它显示结构的字段值。
transparent 结构类型还允许对其实例使用反射操作，例如 @racket[struct?] 和 @racket[struct-info]
（参见 @secref["reflection"]）。

结构类型默认是 opaque 的，因为 opaque 的结构实例提供更多的封装保证。
也就是说，库可以使用 opaque 结构来封装数据，库的客户端不能按照库允许之外的方式操作结构中的数据。

@; ------------------------------------------------------------
@section[#:tag "struct-equal"]{Structure Comparisons}

通用的 @racket[equal?] 比较会自动递归到 transparent 结构类型的字段上，
但对于 opaque 结构类型，@racket[equal?] 默认仅检查实例的同一性：

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

要支持通过 @racket[equal?] 进行实例比较而不使结构类型变为 transparent，
你可以使用 @racket[#:methods] 关键字、@racket[gen:equal+hash]，并实现三个方法：

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

列表中的第一个函数对两个 @racket[lead] 实现 @racket[equal?] 测试；
函数的第三个参数用于替代 @racket[equal?] 进行递归相等性测试，
以便正确处理数据循环。另外两个函数计算主 hash 码和
副 hash 码，用于 @tech{hash tables}：

@interaction[
#:eval posn-eval
(define h (make-hash))
(hash-set! h (lead 1 2) 3)
(hash-ref h (lead 1 2))
(hash-ref h (lead 2 1))
]

@racket[gen:equal+hash] 提供的第一个函数不要求
递归比较结构的字段。例如，表示集合的结构类型可能通过
检查集合成员是否相同来实现相等性，而不依赖于内部表示中
元素的顺序。只需注意 hash 函数对任何两个
应被视为等价的结构类型产生相同的值。

@; ------------------------------------------------------------
@section{Structure Type Generativity}

每当 @racket[struct] 形式被求值时，它都会生成一个
与所有现有结构类型不同的结构类型，即使某个其他结构类型
具有相同的名称和字段。

这种生成性对于强制抽象和实现诸如解释器之类的程序很有用，
但要注意不要将 @racket[struct] 形式放在会被多次
求值的位置。

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

虽然 @tech{transparent} 结构类型以显示其内容的方式打印，
但结构的打印形式不能像数字、字符串、symbol 或列表的打印形式那样
在表达式中使用来取回结构。

@deftech{prefab}（"previously fabricated"，预先制造的）结构类型是一种
内建类型，Racket 打印器和表达式读取器都认识它。存在无限多个这样的类型，
它们按名称、字段数量、父类型和其他此类细节进行索引。prefab 结构的打印形式
类似于 vector，但它以 @litchar{#s} 而不是 @litchar{#} 开头，
并且打印形式中的第一个元素是 prefab 结构类型的名称。

以下示例显示了具有一个字段的 @racketidfont{sprout}
prefab 结构类型的实例。第一个实例的字段值为
@racket['bean]，第二个实例的字段值为 @racket['alfalfa]：

@interaction[
'#s(sprout bean)
'#s(sprout alfalfa)
]

像数字和字符串一样，prefab 结构是"自引用"的，
所以上面的引号是可选的：

@interaction[
#s(sprout bean)
]

当您将 @racket[#:prefab] 关键字与
@racket[struct] 一起使用时，您获得的绑定可以与
现有的 prefab 结构类型配合工作，而不是生成新的结构类型：

@interaction[
#:eval posn-eval
(define lunch '#s(sprout bean))
(struct sprout (kind) #:prefab)
(sprout? lunch)
(sprout-kind lunch)
(sprout 'garlic)
]

上面的字段名 @racketidfont{kind} 对于查找 prefab 结构类型并不重要；
只有名称 @racketidfont{sprout} 和字段数量才重要。同时，
具有三个字段的 prefab 结构类型 @racketidfont{sprout} 与
只有一个字段的结构类型是不同的：

@interaction[
#:eval posn-eval
(sprout? #s(sprout bean #f 17))
(code:line (struct sprout (kind yummy? count) #:prefab) (code:comment @#,t{redefine}))
(sprout? #s(sprout bean #f 17))
(sprout? lunch)
]

prefab 结构类型可以有另一个 prefab 结构类型作为其父类型，
它可以有可变字段，也可以有自动字段。
这些维度上的任何变化都对应于不同的 prefab 结构类型，
结构类型名称的打印形式编码了所有相关细节。

@interaction[
(struct building (rooms [location #:mutable]) #:prefab)
(struct house building ([occupied #:auto]) #:prefab
  #:auto-value 'no)
(house 5 'factory)
]

每个 @tech{prefab} 结构类型都是 @tech{transparent} 的——但比
@tech{transparent} 类型更不抽象，因为实例可以在不访问
特定结构类型声明或现有示例的情况下创建。总体而言，
结构类型的不同选项提供了从更抽象到更方便的一系列可能性：

@itemize[

 @item{@tech{Opaque}（默认）：实例无法在不访问结构类型声明的情况下
       被检查或伪造。如下一节所讨论的，@tech{constructor guards} 和
       @tech{properties} 可以附加到结构类型上，以进一步保护或
       特化其实例的行为。}

 @item{@tech{Transparent}：任何人都可以在不访问结构类型声明的情况下
       检查或创建实例，这意味着值打印器可以显示实例的内容。然而，
       所有实例创建都通过 @tech{constructor guard}，以便控制实例的内容，
       并且可以通过 @tech{properties} 特化实例的行为。
       由于结构类型是由其定义生成的，实例不能仅通过结构类型的名称
       来制造，因此不能由表达式读取器自动生成。}

 @item{@tech{Prefab}：任何人都可以在任何时候检查或创建实例，
       无需事先访问结构类型声明或示例实例。因此，
       表达式读取器可以直接制造实例。实例不能有
       @tech{constructor guard} 或 @tech{properties}。}

]

由于表达式读取器可以生成 @tech{prefab} 实例，当方便的
@tech{serialization} 比抽象更重要时它们很有用。不过，
@tech{Opaque} 和 @tech{transparent} 结构也可以被序列化，
如果它们是用 @racket[serializable-struct] 定义的，
如 @secref["serialization"] 中所述。

@; ------------------------------------------------------------
@section[#:tag "struct-options"]{More Structure Type Options}

@racket[struct] 的完整语法支持许多选项，
既包括结构类型级别的选项，也包括单个字段级别的选项：

@specform/subs[(struct struct-id maybe-super (field ...)
                       struct-option ...)
               ([maybe-super code:blank
                             super-id]
                [field field-id
                       [field-id field-option ...]])]

@racket[_struct-option] 总是以关键字开头：

 @specspecsubform[#:mutable]{

    使结构的所有字段变为可变的，并为每个 @racket[_field-id] 引入一个
    @deftech{mutator}
     @racketidfont{set-}@racket[_struct-id]@racketidfont{-}@racket[_field-id]@racketidfont{!}
    用于设置结构类型实例中对应字段的值。

     @defexamples[(struct dot (x y) #:mutable)
                  (define d (dot 1 2))
                  (dot-x d)
                  (set-dot-x! d 10)
                  (dot-x d)]

   @racket[#:mutable] 选项也可以用作
   @racket[_field-option]，此时它使单个字段变为可变的。
       
   @defexamples[
   (struct person (name [age #:mutable]))
   (define friend (person "Barney" 5))
   (set-person-age! friend 6)
   (set-person-name! friend "Mary")]}

 @specspecsubform[(code:line #:transparent)]{
  控制对结构实例的反射访问，如前一节
  @secref["trans-struct"] 中所讨论的。}

 @specspecsubform[(code:line #:inspector inspector-expr)]{
  泛化 @racket[#:transparent] 以支持对反射操作的更受控访问。}

 @specspecsubform[(code:line #:prefab)]{
  访问内建结构类型，如前一节
  @secref["prefab-struct"] 中所讨论的。}

 @specspecsubform[(code:line #:auto-value auto-expr)]{

  指定用于结构类型中所有自动字段的值，其中自动字段由
  @racket[#:auto] 字段选项指示。constructor 过程不
  接受自动字段的参数。自动字段隐式可变（通过反射操作），
  但只有在同时指定了 @racket[#:mutable] 时才会绑定 mutator 函数。

  @defexamples[
    (struct posn (x y [z #:auto])
                 #:transparent
                 #:auto-value 0)
    (posn 1 2)
  ]}

@;-- FIXME:
@;-- Explain when to use guards instead of contracts, and vice versa

 @specspecsubform[(code:line #:guard guard-expr)]{ 指定一个
  @deftech{constructor guard} 过程，每当创建结构类型的实例时都会调用它。
  该 guard 接受与结构类型中非自动字段数量相同的参数，
  再加上一个用于被实例化类型名称的参数（以防实例化子类型，
  此时最好使用子类型的名称报告错误）。guard 应返回与给定值
  相同数量的值（减去名称参数）。如果给定参数中有不可接受的，
  guard 可以引发异常，或者它可以转换参数。

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

  即使创建子类型的实例时也会调用 guard。在这种情况下，
  只有 constructor 接受的字段会提供给 guard
  （但子类型的 guard 会同时获得原始字段和子类型添加的字段）。

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
  为结构类型关联与 @defterm{generic interface}（泛型接口）对应的方法定义。
  例如，为 @racket[gen:dict] 实现方法允许结构类型的实例
  用作字典。为 @racket[gen:custom-write] 实现方法
  允许自定义结构类型实例的 @racket[display] 方式。

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
   将 @deftech{property} 和值与结构类型关联。
   例如，@racket[prop:procedure] property 允许结构实例
   用作函数；property 值决定了将结构用作函数时
   调用是如何实现的。

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

  在 @racket[struct-id] 旁边提供 @racket[super-id] 的替代方式。
  @racket[super-expr] 应该产生一个 @tech{structure type descriptor} 值，
  而不是结构类型的名称（结构类型名称不是表达式）。@racket[#:super] 的一个
  优势是结构类型描述符是值，因此可以传递给过程。

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

@refdetails["structures"]{结构类型}

@close-eval[posn-eval]
