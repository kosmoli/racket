#lang scribble/doc
@(require "mz.rkt" (for-label racket/struct racket/struct-info))

@(define struct-eval (make-base-eval))
@(define struct-copy-eval (make-base-eval))

@title[#:tag "structures" #:style 'toc]{Structures}

@guideintro["define-struct"]{structure types via @racket[struct]}

@deftech{结构类型}是一种记录数据类型，由若干
@idefterm{字段}组成。@deftech{结构}是结构类型的一个实例，
是一等值，其中包含结构类型每个字段的值。结构实例通过特定于类型的
@tech{构造函数}过程创建，其字段值通过特定于类型的 @tech{访问器}和
@tech{修改器}过程进行读取和更改。此外，每个结构类型都有一个
@tech{谓词}过程，对于该结构类型的实例返回 @racket[#t]，对于任何
其他值则返回 @racket[#f]。

结构类型的字段本质上是无名称的，尽管为了方便错误报告而支持名称。
构造函数过程为结构类型的每个字段接受一个值，但结构类型中的某些
字段可以是 @deftech{自动字段}；@tech{自动字段}被初始化为与
该结构类型关联的常量，相应的参数从构造函数过程中省略。
结构类型中的所有自动字段都排在非自动字段之后。

一个结构类型可以作为现有基础结构类型的
@deftech{结构子类型}来创建。结构子类型的实例始终可以作为
基础结构类型的实例使用，但子类型有自己的谓词过程，
并且除了基类型的字段之外，还可以有自己的字段。

结构子类型会“继承”其基类型的字段。如果基类型有 @math{m} 个字段，
并且为新结构子类型指定了 @math{n} 个字段，那么生成的结构类型
有 @math{m+n} 个字段。子类型中自动字段的值可以与其基类型不同。

如果原始 @math{m} 个字段中有 @math{m'} 个是非自动的（其中
@math{m'<m}），且新字段中有 @math{n'} 个是非自动的（其中
@math{n'<n}），那么必须向子类型的构造函数过程提供
@math{m'+n'} 个字段值。子类型实例的前 @math{m} 个字段的值
通过原始基类型（或其超类型）的选择器过程访问，后 @math{n} 个
字段通过子类型特定的选择器访问。前 @math{m} 个字段的子类型特定
@tech{访问器}和 @tech{修改器}不存在。

@racket[struct] 形式和 @racket[make-struct-type] 过程
通常创建一个新的结构类型，但它们也可以访问 @deftech{prefab}
（即预制）结构类型，这些类型是全局共享的，其实例可以被默认的
读取器（参见 @secref["reader"]）和打印器（参见
@secref["printing"]）解析和写出。Prefab 结构类型只能从
其他 prefab 结构类型继承，不能有守卫（参见
@secref["creatingmorestructs"]）或属性（参见
@secref["structprops"]）。对于名称、超类型、字段数、自动
字段数、自动字段值（当至少有一个自动字段时）以及字段可变性的每种组合，
恰好存在一个 prefab 结构类型。

@refalso["serialization"]{读写结构}

@index['("structures" "equality")]{两个}结构值
当且仅当它们是 @racket[eq?] 时才是 @racket[eqv?]。两个结构值
当且仅当它们是 @racket[eq?] 时才是 @racket[equal?]。默认情况下，
如果两个结构值是同一结构类型的实例、没有字段是不透明的、且对结构应用
@racket[struct->vector] 的结果是 @racket[equal?]，那么它们也是
@racket[equal?]。（因此，结构的 @racket[equal?] 测试可能依赖于
当前的 inspector。）结构类型可以通过
@racket[gen:equal+hash] 或 @racket[gen:equal-mode+hash] @tech{泛型接口}
覆盖默认的 @racket[equal?] 定义。

@local-table-of-contents[]

@;------------------------------------------------------------------------
@include-section["define-struct.scrbl"]

@;------------------------------------------------------------------------
@section[#:tag "creatingmorestructs"]{Creating Structure Types}

@defproc[(make-struct-type [name symbol?]
                           [super-type (or/c struct-type? #f)]
                           [init-field-cnt exact-nonnegative-integer?]
                           [auto-field-cnt exact-nonnegative-integer?]
                           [auto-v any/c #f]
                           [props (listof (cons/c struct-type-property?
                                                  any/c))
                                  null]
                           [inspector (or/c inspector? #f 'current 'prefab)
                                      'current]
                           [proc-spec (or/c procedure?
                                            exact-nonnegative-integer?
                                            #f)
                                      #f]
                           [immutables (listof exact-nonnegative-integer?)
                                       null]
                           [guard (or/c procedure? #f) #f]
                           [constructor-name (or/c symbol? #f) #f])
          (values struct-type?
                  struct-constructor-procedure?
                  struct-predicate-procedure?
                  struct-accessor-procedure?
                  struct-mutator-procedure?)]{

创建一个新的结构类型，除非 @racket[inspector] 是
@racket['prefab]，此时 @racket[make-struct-type] 访问一个
@techlink{prefab} 结构类型。@racket[name] 参数用作类型名称。
如果 @racket[super-type] 不是 @racket[#f]，则生成的类型是对应
结构类型的子类型。

生成的结构类型有
@math{@racket[init-field-cnt]+@racket[auto-field-cnt]} 个字段
（加上来自 @racket[super-type] 的任何字段），但只有
@racket[init-field-cnt] 个构造函数参数（加上来自
@racket[super-type] 的任何构造函数参数）。其余字段用
@racket[auto-v] 初始化。总字段数（包括 @racket[super-type] 字段）
不得超过 32768。

@racket[props] 参数是一个配对列表，其中每个配对的 @racket[car]
是一个结构类型属性描述符，@racket[cdr] 是一个任意值。只有在
关联的值是 @racket[eq?] 时，才能在 @racket[props] 中多次指定
同一属性（包括由 @racket[props] 中直接包含的属性自动添加的属性），
否则 @exnraise[exn:fail:contract]。有关属性的更多信息，
请参见 @secref["structprops"]。当 @racket[inspector] 是
@racket['prefab] 时，@racket[props] 必须是 @racket[null]。

@racket[inspector] 参数通常控制对结构类型及其实例的反射信息
的访问；有关更多信息，请参见 @secref["inspectors"]。如果
@racket[inspector] 是 @racket['prefab]，则生成的 @tech{prefab}
结构类型及其实例始终是透明的。如果 @racket[inspector] 是
@racket[#f]，则结构类型的实例是透明的。如果
@racket[inspector] 是 @racket['current]（默认值），则使用
@racket[(current-inspector)]。

如果 @racket[proc-spec] 是一个整数或过程，则该结构类型的实例
可以作为过程使用。更多信息请参见 @racket[prop:procedure]。为
@racket[proc-spec] 提供非 @racket[#f] 值等同于在
@racket[props] 末尾将该值与 @racket[prop:procedure] 配对，
并在 @racket[proc-spec] 是整数时将其包含在
@racket[immutables] 中。

@racket[immutables] 参数提供一个字段位置列表。列表中的每个
元素必须是唯一的，否则 @exnraise[exn:fail:contract]。每个
元素还必须在 @racket[0]（包含）到 @racket[init-field-cnt]
（不包含）的范围内，否则 @exnraise[exn:fail:contract]。

@racket[guard] 参数要么是一个接受 @math{n+1} 个参数的过程，
要么是 @racket[#f]，其中 @math{n} 是新结构类型构造函数的参数个数
（即 @racket[init-field-cnt] 加上 @racket[super-type] 隐含的
构造函数参数，如果有的话）。如果 @racket[guard] 是一个过程，
那么每当构造该类型的实例或创建子类型的实例时，都会调用该过程。
@racket[guard] 的参数是结构前 @math{n} 个字段的值，
后跟被实例化的结构类型的名称（即 @racket[name]，除非实例化的是
子类型）。@racket[guard] 的结果必须是 @math{n} 个值，这些值
将成为结构字段的实际值。@racket[guard] 可以引发异常以阻止
创建具有给定字段值的结构。如果结构子类型有自己的 guard，则先
应用子类型的 guard，子类型 guard 过程生成的前 @math{n} 个值
成为 @racket[guard] 的前 @math{n} 个参数。当 @racket[inspector]
为 @racket['prefab] 时，@racket[guard] 必须为 @racket[#f]。

如果 @racket[constructor-name] 不是 @racket[#f]，则它被用作
生成的 @tech{constructor} 过程的名称，由 @racket[object-name]
返回或在构造函数的打印形式中使用。

@racket[make-struct-type] 的结果是五个值：

@itemize[

 @item{一个 @tech{结构类型描述符},}

 @item{一个 @tech{构造函数}过程,}

 @item{一个 @tech{谓词}过程,}

 @item{一个 @tech{访问器}过程，接受一个结构和一个
 介于 @math{0}（包含）和
 @math{@racket[init-field-cnt]+@racket[auto-field-cnt]}（不包含）
 之间的字段索引，以及}

 @item{一个 @tech{修改器}过程，接受一个结构、一个字段
 索引和一个字段值。}

]

@examples[
#:eval struct-eval

(eval:no-prompt
 (define-values (struct:a make-a a? a-ref a-set!)
   (make-struct-type 'a #f 2 1 'uninitialized))
 (define an-a (make-a 'x 'y)))

(a-ref an-a 1)
(a-ref an-a 2)
(define a-first (make-struct-field-accessor a-ref 0))
(a-first an-a)

(eval:no-prompt
 (define-values (struct:b make-b b? b-ref b-set!)
   (make-struct-type 'b struct:a 1 2 'b-uninitialized))
 (define a-b (make-b 'x 'y 'z)))

(a-ref a-b 1)
(a-ref a-b 2)
(b-ref a-b 0)
(b-ref a-b 1)
(b-ref a-b 2)

(eval:no-prompt
 (define-values (struct:c make-c c? c-ref c-set!)
   (make-struct-type
    'c struct:b 0 0 #f null (make-inspector) #f null
    (code:comment #,(t "guard checks for a number, and makes it inexact"))
    (lambda (a1 a2 b1 name)
      (unless (number? a2)
        (error (string->symbol (format "make-~a" name))
               "second field must be a number"))
      (values a1 (exact->inexact a2) b1)))))

(eval:error (make-c 'x 'y 'z))
(define a-c (make-c 'x 2 'z))
(a-ref a-c 1)

(eval:no-prompt
 (define p1 #s(p a b c))
 (define-values (struct:p make-p p? p-ref p-set!)
   (make-struct-type 'p #f 3 0 #f null 'prefab #f '(0 1 2))))

(p? p1)
(p-ref p1 0)
(make-p 'x 'y 'z)
]

@history[#:changed "9.0.0.6" @elem{Added @racket['current] as an allowed value for @racket[inspector].}]}

@defproc[(make-struct-field-accessor [accessor-proc struct-accessor-procedure?]
                                     [field-pos exact-nonnegative-integer?]
                                     [field/proc-name (or/c symbol? #f) 
                                                      (symbol->string (format "field~a" field-pos))]
                                     [arg-contract-str (or/c string? symbol? #f) #f]
                                     [realm symbol? 'racket])
         procedure?]{

返回一个字段访问器，等价于 @racket[(lambda (s)
(accessor-proc s field-pos))]。@racket[accessor-proc] 必须是
@racket[make-struct-type] 返回的 @tech{访问器}。

@racket[field/proc-name] 参数确定生成过程的名称，用于错误报告
和调试。如果 @racket[field/proc-name] 是一个符号且
@racket[arg-contract-str] 不为 @racket[#f]，则
@racket[field/proc-name] 被用作过程名称。如果
@racket[field/proc-name] 是一个符号且
@racket[arg-contract-str] 为 @racket[#f]，则
@racket[field/proc-name] 与 @racket[accessor-proc] 的结构类型
名称组合构成过程名称。如果 @racket[field/proc-name] 为
@racket[#f]，则使用 @racket['accessor] 作为过程名称。

@racket[arg-contract-str] 参数决定访问器过程在应用于不是
@racket[accessor-proc] 的结构类型实例的值时如何报告错误。
如果是字符串或符号，则字符串或符号的文本被用作错误报告的
contract。否则，contract 文本由 @racket[accessor-proc] 的
结构类型名称合成。

@racket[realm] 参数也用于错误报告。它指定一个 @tech{realm}，
错误消息调整器可以使用它来决定如何调整错误消息。
@racket[realm] 参数还决定访问器过程的
@racket[procedure-realm] 的结果。

示例请参见 @racket[make-struct-type]。

@history[#:changed "8.4.0.2" @elem{Added the @racket[arg-contract-str]
                                    and @racket[realm] arguments.}]}

@defproc[(make-struct-field-mutator [mutator-proc struct-mutator-procedure?]
                                    [field-pos exact-nonnegative-integer?]
                                    [field/proc-name (or/c symbol? #f)
                                                     (symbol->string (format "field~a" field-pos))]
                                    [arg-contract-str (or/c string? symbol? #f) #f]
                                    [realm symbol? 'racket])
         procedure?]{

返回一个字段修改器，等价于 @racket[(lambda (s v)
(mutator-proc s field-pos v))]。@racket[mutator-proc] 必须是
@racket[make-struct-type] 返回的 @tech{修改器}。

@racket[field-name]、@racket[arg-contract-str] 和 @racket[realm]
参数用于错误和调试目的，与 @racket[make-struct-field-accessor]
中的同名参数类似。

示例请参见 @racket[make-struct-type]。

@history[#:changed "8.4.0.2" @elem{Added the @racket[arg-contract-str]
                                    and @racket[realm] arguments.}]}


@defthing[prop:sealed struct-type-property?]{

一个 @tech{结构类型属性}，用于将结构类型声明为
@deftech{密封}。与该属性关联的值被忽略；属性本身的存在
就使结构类型成为密封的。

一个 @tech{密封}的结构类型不能用作另一个结构类型的超类型。
将结构类型声明为 @tech{密封}通常只是一个性能提示，因为检查
封闭结构类型的实例可能比检查可能有子类型的结构类型的实例稍快。

@history[#:added "8.0.0.7"]}


@;------------------------------------------------------------------------
@section[#:tag "structprops"]{Structure Type Properties}

@margin-note{@secref{struct-generics} 在结构类型属性的基础上
提供了高级 API。}

@deftech{结构类型属性}允许将每个类型的信息与结构类型关联
（与结构值的每个实例信息相对）。属性值通过
 @racket[make-struct-type] 过程（参见
 @secref["creatingmorestructs"]）或 @racket[struct] 的
 @racket[#:property] 选项与结构类型关联起来。子类型继承其
 父类型的属性值，并且子类型可以用新值覆盖继承的属性值。

@defproc[(make-struct-type-property [name symbol?]
                                    [guard (or/c procedure? #f 'can-impersonate) #f]
                                    [supers (listof (cons/c struct-type-property?
                                                            (any/c . -> . any/c)))
                                            null]
                                    [can-impersonate? any/c #f]
                                    [accessor-name (or/c symbol? #f) #f]
                                    [contract-str (or/c string? symbol? #f) #f]
                                    [realm symbol? 'racket])
         (values struct-type-property?
                 (any/c . -> . boolean?)
                 procedure?)]{

创建一个新的结构类型属性并返回三个值：

@itemize[

 @item{一个 @deftech{结构类型属性描述符}，用于
       @racket[make-struct-type] 和 @racket[struct]；}

 @item{一个 @deftech{属性谓词}过程，接受任意值，如果该值是
       具有该属性值的结构类型的描述符或实例，则返回
       @racket[#t]，否则返回 @racket[#f]；}

 @item{一个 @deftech{属性访问器}过程，给定结构类型的描述符
       或其实例，返回与该结构类型关联的值；如果结构类型没有
       该属性的值，或提供了任何其他类型的值，则
       @exnraise[exn:fail:contract]，除非向该过程提供了第二个
       参数 @racket[_failure-result]。在这种情况下，如果
       @racket[_failure-result] 是一个过程，则不带参数调用它
       （通过尾调用）以生成属性访问器过程的结果；否则，
       @racket[_failure-result] 本身作为结果返回。}

]

如果可选的 @racket[guard] 以过程形式提供，则
@racket[make-struct-type] 在将属性附加到新结构类型之前
调用它。@racket[guard] 必须接受两个参数：提供给
@racket[make-struct-type] 的属性值，以及一个包含新结构类型
信息的列表。该列表包含 @racket[struct-type-info] 如果跳过
current-inspector 控制检查时将为新结构类型返回的值。

调用 @racket[guard] 的结果与目标结构类型中的属性关联，
而不是提供给 @racket[make-struct-type] 的值。要拒绝属性关联
（例如，因为提供给 @racket[make-struct-type] 的值不适合该属性），
@racket[guard] 可以引发异常。这种异常会阻止
@racket[make-struct-type] 返回结构类型描述符。

如果 @racket[guard] 是 @racket['can-impersonate]，则该属性
的访问器可以通过 @racket[impersonate-struct] 重定向。此选项
等同于将 @racket[#t] 作为 @racket[can-impersonate?] 参数提供，
是为向后兼容而提供的。

可选的 @racket[supers] 参数是一个属性列表，当新创建的属性
关联到某个结构类型时，这些属性会自动与该结构类型关联。
@racket[supers] 中的每个属性都与一个过程配对，该过程接收
为新属性提供的值（由 @racket[guard] 处理后），并返回关联属性
的值（然后发送给该属性的 guard，如果有的话）。

可选的 @racket[can-impersonate?] 参数决定结构类型属性是否
可以通过 @racket[impersonate-struct] 重定向。如果该参数为
@racket[#f]，则不允许重定向。否则，属性访问器可以被结构
impersonator 重定向。

可选的 @racket[accessor-name] 参数为返回的访问器函数提供
一个名称（在 @racket[object-name] 的意义上）。如果
@racket[accessor-name] 为 @racket[#f]，则通过在
@racket[name] 末尾添加 @racketidfont{-accessor} 来创建名称。

可选的 @racket[contract-str] 参数提供一个 contract，当返回的
访问器应用于不是该属性实例的值时（且没有向访问器提供
@racket[_failure-result] 参数），该 contract 会包含在错误
消息中。如果 @racket[contract-str] 为 @racket[#f]，则通过在
@racket[name] 末尾添加 @racketidfont{?} 来创建 contract。

可选的 @racket[realm] 参数提供一个 @tech{realm}（在
@racket[procedure-realm] 的意义上）与返回的访问器关联。

@examples[
#:eval struct-eval
(define-values (prop:p p? p-ref) (make-struct-type-property 'p))

(define-values (struct:a make-a a? a-ref a-set!)
  (make-struct-type 'a #f 2 1 'uninitialized
                    (list (cons prop:p 8))))
(p? struct:a)
(p? 13)
(define an-a (make-a 'x 'y))
(p? an-a)
(p-ref an-a)

(define-values (struct:b make-b b? b-ref b-set!)
  (make-struct-type 'b #f 0 0 #f))
(p? struct:b)

(define-values (prop:q q? q-ref) (make-struct-type-property 
                                  'q (lambda (v si) (add1 v))
                                  (list (cons prop:p sqrt))))
(define-values (struct:c make-c c? c-ref c-set!)
  (make-struct-type 'c #f 0 0 'uninit
                    (list (cons prop:q 8))))
(q-ref struct:c)
(p-ref struct:c)
]

@history[#:changed "7.0" @elem{The @tech{CS} implementation of Racket
                               skips the inspector check
                               for exposing an ancestor structure
                               type, if any, in information provided to a guard procedure.}
         #:changed "8.4.0.2" @elem{Added the @racket[accessor-name],
                                    @racket[contract-str], and
                                    @racket[realm] arguments.}
         #:changed "8.5.0.2" @elem{Changed the @tech{BC} implementation of Racket
                                   to skip the inspector check, the same as the @tech{CS} implementation,
                                   for ancestor information provided to a guard procedure.}]}


@defproc[(struct-type-property? [v any/c]) boolean?]{

如果 @racket[v] 是一个 @tech{结构类型属性描述符}值，
则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(struct-type-property-accessor-procedure? [v any/c]) boolean?]{

如果 @racket[v] 是 @racket[make-struct-type-property] 产生的
访问器过程，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(struct-type-property-predicate-procedure? [v any/c]
                                                    [prop (or/c struct-type-property? #f) #f])
         boolean?]{

如果 @racket[v] 是 @racket[make-struct-type-property] 产生的
谓词过程，并且 @racket[prop] 为 @racket[#f] 或者是由同一次
@racket[make-struct-type-property] 调用产生的，则返回
@racket[#t]，否则返回 @racket[#f]。

@history[#:added "7.5.0.11"]}

@;------------------------------------------------------------------------
@include-section["generic.scrbl"]

@;------------------------------------------------------------------------
@section[#:tag "struct-copy"]{Copying and Updating Structures}

@defform/subs[(struct-copy id struct-expr fld-id ...)
              ((fld-id [field-id expr]
                       [field-id #:parent parent-id expr]))]{

创建结构类型 @racket[id]（通过
@seclink["define-struct"]{结构类型定义形式}如 @racket[struct] 定义）
的一个新实例，其字段值与 @racket[struct-expr] 产生的结构相同，
只是每个提供的 @racket[field-id] 的值改为由相应的
@racket[expr] 确定。如果指定了 @racket[#:parent]，
则 @racket[parent-id] 必须绑定到 @racket[id] 的父结构类型。

@racket[id] 必须有一个 @tech{transformer} 绑定，其中封装了
结构类型的信息（即类似于 @racket[struct] 绑定的初始标识符），
并且该绑定必须提供构造函数、谓词和所有字段访问器。

每个 @racket[field-id] 必须对应于
@racket[id]（如果存在则为 @racket[parent-id]）的
@seclink["define-struct"]{结构类型定义形式}中的一个
@racket[field-id]。同一 @racket[id]（如果存在则为
@racket[parent-id]）下不同 @racket[field-id] 确定的访问器
绑定必须是不同的。@racket[field-id] 的顺序不必与结构类型中
相应字段的顺序匹配。

首先求值 @racket[struct-expr]。结果必须是 @racket[id] 结构
类型的实例，否则 @exnraise[exn:fail:contract]。接下来，
按顺序求值字段 @racket[expr]（即使与 @racket[field-id]
对应的字段顺序不同）。最后，创建新的结构实例。

@racket[struct-expr] 的结果可以是 @racket[id] 子类型的实例，
但生成的副本是 @racket[id] 的直接实例（而不是子类型）。

@examples[
#:eval struct-copy-eval
(struct fish (color weight) #:transparent)
(define marlin (fish 'orange-and-white 11))
(define dory (struct-copy fish marlin
                          [color 'blue]))
dory
             
(struct shark fish (weeks-since-eating-fish) #:transparent)
(define bruce (shark 'grey 110 3))
(define chum (struct-copy shark bruce
                          [weight #:parent fish 90]
                          [weeks-since-eating-fish 0]))
chum

(code:comment "subtypes can be copied as if they were supertypes,")
(code:comment "but the result is an instance of the supertype")
(define not-really-chum
  (struct-copy fish bruce
               [weight 90]))
not-really-chum
]

}

@;------------------------------------------------------------------------
@section[#:tag "structutils"]{Structure Utilities}

@defproc[(struct->vector [v any/c] [opaque-v any/c '...]) vector?]{

创建一个表示 @racket[v] 的向量。结果向量的第一个槽包含一个
符号，其打印名称的形式为
@racketidfont{struct:}@racket[_id]。其余每个槽包含
@racket[v] 中字段的值（如果可以通过当前 inspector 访问），
或者对于不可访问的字段包含 @racket[opaque-v]。连续不可访问
的字段在向量中使用单个 @racket[opaque-v] 值。（因此，如果
有多个字段不可访问，向量的大小与 @racket[struct] 的大小不匹配。）}

@defproc[(struct? [v any/c]) any]{如果 @racket[struct-info] 通过当前 inspector 暴露了
@racket[v] 的任何结构类型则返回 @racket[#t]，否则返回
@racket[#f]。

通常，当 @racket[(struct? v)] 为真时，
@racket[(struct->vector v)] 至少暴露一个字段值。但是，
有可能 @racket[v] 的唯一可见类型贡献零个字段。}

@defproc[(struct-type? [v any/c]) boolean?]{如果 @racket[v] 是结构类型描述符值则返回 @racket[#t]，
否则返回 @racket[#f]。}

@defproc[(struct-constructor-procedure? [v any/c]) boolean?]{如果 @racket[v] 是由 @racket[struct] 或
@racket[make-struct-type] 生成的构造函数过程则返回
@racket[#t]，否则返回 @racket[#f]。}

@defproc[(struct-predicate-procedure? [v any/c]) boolean?]{如果 @racket[v] 是由 @racket[struct] 或
@racket[make-struct-type] 生成的谓词过程则返回
@racket[#t]，否则返回 @racket[#f]。}

@defproc[(struct-accessor-procedure? [v any/c]) boolean?]{如果 @racket[v] 是由 @racket[struct]、
@racket[make-struct-type] 或
@racket[make-struct-field-accessor] 生成的访问器过程则返回
@racket[#t]，否则返回 @racket[#f]。}

@defproc[(struct-mutator-procedure? [v any/c]) boolean?]{如果 @racket[v] 是由 @racket[struct]、
@racket[make-struct-type] 或
@racket[make-struct-field-mutator] 生成的修改器过程则返回
@racket[#t]，否则返回 @racket[#f]。}

@defproc[(prefab-struct-key [v any/c]) (or/c #f symbol? list?)]{

如果 @racket[v] 不是 @tech{prefab} 结构类型的实例，则返回
@racket[#f]。否则，结果是可与
@racket[make-prefab-struct] 一起用于创建该结构类型实例的
缩短 key。

@examples[
(prefab-struct-key #s(cat "Garfield"))
(struct cat (name) #:prefab)
(struct cute-cat cat (shipping-dest) #:prefab)
(cute-cat "Nermel" "Abu Dhabi")
(prefab-struct-key (cute-cat "Nermel" "Abu Dhabi"))
]}


@defproc[(make-prefab-struct [key prefab-key?] [v any/c] ...) struct?]{

使用 @racket[v] 作为字段值创建 @tech{prefab} 结构类型的实例。
@racket[key] 和 @racket[v] 的数量决定了 @tech{prefab} 结构类型。

@racket[key] 基于包含以下项目的列表标识一个结构类型：

@itemize[

 @item{结构类型名称的符号。}

 @item{一个精确非负整数，表示结构类型中非自动字段的数量，
       不包括来自超类型（如果有的话）的字段。}

 @item{一个包含两个项目的列表，其中第一个是精确非负整数，
       表示结构类型中非来自超类型（如果有的话）的自动字段数量，
       第二个元素是任意值，作为自动字段的值。}

 @item{一个精确非负整数向量，指示结构类型中的可变非自动字段，
       从 @racket[0] 开始计数，不包括来自超类型
       （如果有的话）的字段。}

 @item{如果结构类型没有超类型，则无其他内容。
       否则，列表的其余部分是超类型的 key。}

]

空向量和以 @racket[0] 开头的自动字段列表可以省略。此外，
第一个整数（指示非自动字段的数量）可以省略，因为它可以从
提供的 @racket[v] 的数量推断出来。最后，可以使用单个符号
代替只包含一个符号的列表（在结构类型没有超类型、没有自动字段、
没有可变字段的情况下）。

总字段数不得超过 32768。如果 @racket[key] 指示的字段数
与提供的 @racket[v] 的数量不一致，则
@exnraise[exn:fail:contract]。

@examples[
(make-prefab-struct 'clown "Binky" "pie")
(make-prefab-struct '(clown 2) "Binky" "pie")
(make-prefab-struct '(clown 2 (0 #f) #()) "Binky" "pie")
(make-prefab-struct '(clown 1 (1 #f) #()) "Binky" "pie")
(make-prefab-struct '(clown 1 (1 #f) #(0)) "Binky" "pie")
]}


@defproc[(prefab-struct-type-key+field-count [type struct-type?])
         (or/c #f (cons/c prefab-key? (integer-in 0 32768)))]{

如果 @tech{结构类型描述符} @racket[type] 表示一个 prefab
结构类型，则返回一个包含 @tech{prefab} key 和字段数的 pair，
否则返回 @racket[#f]。

@history[#:added "8.5.0.8"]}


@defproc[(prefab-key->struct-type [key prefab-key?]
                                  [field-count (integer-in 0 32768)])
         struct-type?]{

返回由 @racket[key] 和 @racket[field-count] 组合指定的
@tech{prefab} 结构类型的 @tech{结构类型描述符}。

如果 @racket[key] 指示的字段数与 @racket[field-count]
不一致，则 @exnraise[exn:fail:contract]。}


@defproc[(prefab-key? [v any/c]) boolean?]{

如果 @racket[v] 可以是 @tech{prefab} 结构类型 key
则返回 @racket[#t]，否则返回 @racket[#f]。

有效 key 形状的描述请参见 @racket[make-prefab-struct]。}

@subsection{Additional Structure Utilities}

@note-lib-only[racket/struct]

@defproc[(make-constructor-style-printer
            [get-constructor (-> any/c (or/c symbol? string?))]
            [get-contents    (-> any/c sequence?)])
         (-> any/c output-port? (or/c #t #f 0 1) void?)]{

生成一个适合作为
 @racket[gen:custom-write] 或 @racket[prop:custom-write] 值
 的函数。该函数以“构造函数风格”打印值。当值作为表达式
 @racket[print] 时，它显示为构造函数
 （由 @racket[get-constructor] 返回）对内容
 （由 @racket[get-contents] 返回）的应用。当交给
 @racket[write] 时，它显示为不可读的值，构造函数
 与内容之间用冒号分隔。

@(struct-eval '(require racket/struct racket/pretty))

@examples[#:eval struct-eval
          (struct point (x y)
            #:methods gen:custom-write
            [(define write-proc
               (make-constructor-style-printer
                (lambda (obj) 'point)
                (lambda (obj) (list (point-x obj) (point-y obj)))))])
          (print (point 1 2))
          (write (point 1 2))]

该函数还与 @racket[pretty-print] 配合使用：

@examples[#:eval struct-eval #:label #f
(parameterize ((pretty-print-columns 10))
  (pretty-print (point #e3e6 #e4e6)))
(parameterize ((pretty-print-columns 10))
  (pretty-write (point #e3e6 #e4e6)))
]

请注意，打印机使用单独的属性
@racket[prop:custom-print-quotable] 来确定结构实例是否可引用。
如果是，打印机可能在某些上下文（如在列表中）中
以 @racket[write] 模式打印它。例如：
@examples[#:eval struct-eval #:label #f
(print (list (point 1 2) (point 3 4)))
]
使用 @racket[#:property prop:custom-print-quotable 'never]
来防止结构实例被视为可引用。例如：
@examples[#:eval struct-eval #:label #f
(struct point2 (x y)
  #:property prop:custom-print-quotable 'never
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (lambda (obj) 'point)
      (lambda (obj) (list (point2-x obj) (point2-y obj)))))])
(print (list (point2 1 2) (point2 3 4)))
]

关键字参数可以用 @racket[unquoted-printing-string] 模拟：

@examples[#:eval struct-eval #:label #f
(code:comment "Private implementation")
(struct kwpoint-impl (x y)
  #:methods gen:custom-write
  [(define write-proc
     (make-constructor-style-printer
      (lambda (obj) 'kwpoint)
      (lambda (obj)
        (list (unquoted-printing-string "#:x")
              (kwpoint-impl-x obj)
              (unquoted-printing-string "#:y")
              (kwpoint-impl-y obj)))))])
(code:comment "Public ``constructor''")
(define (kwpoint #:x x #:y y)
  (kwpoint-impl x y))
(code:comment "Example use")
(print (kwpoint #:x 1 #:y 2))
(write (kwpoint #:x 3 #:y 4))
]

@history[#:added "6.3"]{}
}

@defproc[(struct->list [v any/c]
                       [#:on-opaque on-opaque (or/c 'error 'return-false 'skip) 'error])
         (or/c list? #f)]{

返回一个包含结构实例 @racket[v] 的字段的列表。与
@racket[struct->vector] 不同，结构名称本身不包含在内。

如果 @racket[v] 的任何字段通过当前 inspector 不可访问，
则 @racket[struct->list] 的行为由 @racket[on-opaque]
决定。如果 @racket[on-opaque] 是 @racket['error]（默认），
则引发错误。如果是 @racket['return-false]，
@racket[struct->list] 返回 @racket[#f]。如果是
@racket['skip]，不可访问的字段从列表中省略。

@examples[#:eval struct-eval
(struct open (u v) #:transparent)
(struct->list (open 'a 'b))
(struct->list #s(pre 1 2 3))
(struct secret open (x y))
(eval:error (struct->list (secret 0 1 17 22)))
(struct->list (secret 0 1 17 22) #:on-opaque 'return-false)
(struct->list (secret 0 1 17 22) #:on-opaque 'skip)
(struct->list 'not-a-struct #:on-opaque 'return-false)
(struct->list 'not-a-struct #:on-opaque 'skip)
]

@history[#:added "6.3"]{}
}

@;------------------------------------------------------------------------
@section[#:tag "structinfo"]{Structure Type Transformer Binding}

@racket[struct] 形式将结构类型的名称绑定为一个
@tech{transformer} 绑定，该绑定记录了绑定到结构类型、构造函数
过程、谓词过程以及字段访问器和修改器过程的其他标识符。
这些信息可以在其他表达式的展开过程中通过
@racket[syntax-local-value] 使用。

例如，子类型的 @racket[struct] 变体使用基类型名称
@racket[_t] 来查找包含基类型描述符的变量
@racketidfont{struct:}@racket[_t]；它还
将基类型的字段访问器和修改器信息合并到子类型的信息中。
作为另一个例子，@racket[match] 形式使用
类型名称来查找结构类型的谓词和字段访问器。
@racket[unit] 的导入签名中的 @racket[struct] 形式会导致
@racket[unit] transformer 生成关于导入的结构类型的信息，
使得 @racket[match] 和子类型化的 @racket[struct] 形式
能够在 unit 内正常工作。

结构类型的展开期信息可以直接表示为一个包含六个元素的列表
（与封装的 procedure 必须返回的类型相同）：

@itemize[

 @item{绑定到结构类型描述符的标识符，如果没有已知的则
 为 @racket[#f]；}

 @item{绑定到结构类型构造函数的标识符，如果没有已知的则
 为 @racket[#f]；}

 @item{绑定到结构类型谓词的标识符，如果没有已知的则
 为 @racket[#f]；}

 @item{绑定到结构类型字段访问器的标识符列表，可选的以
 @racket[#f] 作为列表的最后一个元素。最后一个元素为
 @racket[#f] 表示结构类型可能有额外的字段，否则列表是对
 结构类型中字段数量的可靠指示。此外，访问器以与相应构造函数
 参数相反的顺序列出。（反向顺序使得子类型及其基类型的列表
 能够共享。）}

 @item{绑定到结构类型字段修改器的标识符列表，对于没有已知
 修改器的每个字段为 @racket[#f]，可选的以额外的
 @racket[#f] 作为列表的最后一个元素（如果访问器列表有
 这样的 @racket[#f]）。列表的顺序和末尾 @racket[#f] 的
 含义与访问器标识符相同，修改器列表的长度与访问器列表
 的长度相同。}

 @item{确定结构类型超类型的标识符，如果超类型（如果有）
 未知则为 @racket[#f]，如果没有超类型则为 @racket[#t]。
 如果指定了超类型，则该标识符也绑定到结构类型的展开期信息。}

]

除了这种直接表示之外，表示可以是由
@racket[make-struct-info] 创建的结构（或者是
@racket[struct:struct-info] 子类型的实例），它封装了一个
不带参数并返回六个元素的列表的过程。另外，表示可以是其类型
具有 @racket[prop:struct-info] @tech{结构类型属性}的结构。
最后，表示可以是源自 @racket[struct:struct-info] 或具有
@racket[prop:struct-info] 属性的结构类型的实例，该实例还
实现了 @racket[prop:procedure]，并且该实例进一步被
@racket[make-set!-transformer] 包装。此外，表示可以实现
@racket[prop:struct-auto-info] 和
@racket[prop:struct-field-info] 属性。

使用 @racket[struct-info?] 来识别所有允许的信息形式，
使用 @racket[extract-struct-info] 从任何表示中获取列表。

语法形式的实现者可以预期该形式的使用者知道关于结构类型
有哪些可用信息。例如，@racket[match] 的实现使用包含不完整
访问器绑定集的结构信息，因为假设使用者知道在
@racket[match] 表达式上下文中哪些信息可用。特别是，
@racket[match] 表达式可以出现在带有导入结构类型的
@racket[unit] 形式中，在这种情况下，预期使用者知道在
结构类型的签名中列出的字段集。

@note-lib-only[racket/struct-info]

@defproc[(struct-info? [v any/c]) boolean?]{

如果 @racket[v] 是具有表示结构类型信息的正确形状的六元素列表、
由 @racket[make-struct-info] 封装的过程、具有
@racket[prop:struct-info] 属性的结构、或源自
@racket[struct:struct-info] 或具有 @racket[prop:struct-info]
并由 @racket[make-set!-transformer] 包装的结构类型，
则返回 @racket[#t]。}

@defproc[(checked-struct-info? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[make-struct-info] 封装并且
由 @racket[struct] 产生的过程，但仅当没有指定父类型或者
父类型也通过绑定到这种值的 transformer 绑定时指定，
则返回 @racket[#t]。}

@defproc[(make-struct-info [thunk (-> (and/c struct-info? list?))])
         struct-info?]{

Encapsulates a thunk that returns structure-type information in list
form. Note that accessors are listed in reverse order, as mentioned in @secref{structinfo}.}
Note that the field names are not well-defined for struct-type informations
that are created with this method, so it is likely not going to work well
with forms like @racket[struct-copy] and @racket[struct*].
      
@(struct-eval '(require (for-syntax racket/base)))
@(struct-eval '(require racket/match))
@(struct-eval '(require (for-syntax racket/struct-info)))
@examples[
#:eval struct-eval
(define (new-pair? x) (displayln "new pair?") (pair? x))
(define (new-car x) (displayln "new car") (car x))
(define (new-cdr x) (displayln "new cdr") (cdr x))
(define-syntax new-list 
  (make-struct-info 
   (λ () (list #f 
               #'cons 
               #'new-pair? 
               (list #'new-cdr #'new-car) 
               (list #f #f)
               #t))))
(match (list 1 2 3)
  [(new-list hd tl) (append tl (list hd))])
]

@examples[
#:eval struct-eval
(struct A (x y))
(define (new-A-x a) (displayln "A-x") (A-x a))
(define (new-A-y a) (displayln "A-y") (A-y a))
(define (new-A? a) (displayln "A?") (A? a))
(define-syntax A-info
  (make-struct-info
   (λ () (list #'A
               #'A
               #'new-A?
               (list #'new-A-y #'new-A-x)
               (list #f #f)
               #t))))
(define-match-expander B
  (syntax-rules () [(_ x ...) (A-info x ...)]))
(match (A 10 20)
  [(B x y) (list y x)])
]

@defproc[(extract-struct-info [v struct-info?])
         (and/c struct-info? list?)]{

提取由 @racket[v] 表示的结构类型信息的列表形式。}

@defthing[struct:struct-info struct-type?]{

由 @racket[make-struct-info] 返回的结构类型的
@tech{结构类型描述符}。此 @tech{结构类型描述符}主要用于
创建结构子类型。该结构类型包含一个 guard，它以与
@racket[make-struct-info] 相同的方式检查实例的第一个字段。}

@defthing[prop:struct-info struct-type-property?]{

用于创建类似 @racket[struct:struct-info] 的新结构类型的
@tech{结构类型属性}。属性值必须是一个接受一个参数的过程，
该参数接受一个实例结构并以列表形式返回结构类型信息。}

@deftogether[(
@defthing[prop:struct-auto-info struct-type-property?]
@defproc[(struct-auto-info? [v any/c]) boolean?]
@defproc[(struct-auto-info-lists [sai struct-auto-info?]) 
         (list/c (listof identifier?) (listof identifier?))]
)]{

@racket[prop:struct-auto-info] 属性的实现是为了提供关于
结构类型的哪些访问器和修改器标识符对应于 @racket[#:auto]
字段的静态信息（以便它们在构造函数中没有相应的参数）。
属性值必须是一个过程，该过程接受一个被赋予该属性的实例结构，
结果必须是两个标识符列表，适合作为
@racket[struct-auto-info-lists] 的结果。

@racket[struct-auto-info?] 谓词识别实现了
@racket[prop:struct-auto-info] 属性的值。

@racket[struct-auto-info-lists] 函数从实现了
@racket[prop:struct-auto-info] 属性的值中提取两个标识符
列表。第一个列表应该是 @racket[sai] 描述的结构类型的访问器
标识符的子集，第二个列表应该是修改器标识符的子集。这两个
子集对应于 @racket[#:auto] 字段。}

@deftogether[(
@defthing[prop:struct-field-info struct-type-property?]
@defproc[(struct-field-info? [v any/c]) boolean?]
@defproc[(struct-field-info-list [sfi struct-field-info?]) (listof symbol?)])]{

@racket[prop:struct-field-info] 属性的实现是为了提供关于
结构类型中字段名称的静态信息。属性值必须是一个过程，该过程
接受一个被赋予该属性的实例结构，结果必须是一个符号列表，
适合作为 @racket[struct-field-info-list] 的结果。

@racket[struct-field-info?] 谓词识别实现了
@racket[prop:struct-field-info] 属性的值。

@racket[struct-field-info-list] 函数从实现了
@racket[prop:struct-field-info] 属性的值中提取一个符号列表。
该列表应该以相反的顺序包含每个直接字段名称
（即不包括来自其超结构类型的字段）。

@examples[#:escape no-escape
#:eval struct-eval
(struct foo (x))
(struct bar foo (y z))
(define-syntax (get-bar-field-names stx)
  #`'#,(struct-field-info-list (syntax-local-value #'bar)))
(get-bar-field-names)
]

@history[#:added "7.7.0.9"]}

@; ----------------------------------------------------------------------

@close-eval[struct-eval]
@close-eval[struct-copy-eval]
