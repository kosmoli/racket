#lang scribble/doc
@(require "mz.rkt" (for-syntax racket/base) (for-label racket/serialize
                                                       racket/generic
                                                       racket/keyword-transform))

@(define posn-eval (make-base-eval))
@examples[#:hidden #:eval posn-eval
  (require racket/match racket/stream (for-syntax racket/base))]

@title[#:tag "define-struct"]{Defining Structure Types: @racket[struct]}

@guideintro["define-struct"]{@racket[struct]}

@defform/subs[(struct id maybe-super (field ...)
                      struct-option ...)
              ([maybe-super code:blank
                            super-id]
               [field field-id
                      [field-id field-option ...]]
               [struct-option #:mutable
                              (code:line #:super super-expr)
                              (code:line #:inspector inspector-expr)
                              (code:line #:auto-value auto-expr)
                              (code:line #:guard guard-expr)
                              (code:line #:property prop-expr val-expr)
                              (code:line #:properties prop-list-expr)
                              (code:line #:transparent)
                              (code:line #:prefab)
                              (code:line #:sealed)
                              (code:line #:authentic)
                              (code:line #:name name-id)
                              (code:line #:extra-name name-id)
                              (code:line #:constructor-name constructor-id)
                              (code:line #:extra-constructor-name constructor-id)
                              (code:line #:reflection-name symbol-expr)
                              (code:line #:methods gen:name-id method-defs)
                              #:omit-define-syntaxes
                              #:omit-define-values]
               [field-option #:mutable
                             #:auto]
               [method-defs (definition ...)])]{

创建一个新的 @techlink{structure type}（如果指定了 @racket[#:prefab] 则使用已有的结构体类型），
并绑定与 @tech{structure type} 相关的 transformer 和变量。

包含 @math{n} 个 @racket[field] 的 @racket[struct] 形式最多定义 @math{4+2n} 个名称：

@itemize[

 @item{@racketidfont{struct:}@racket[id]，表示 @tech{structure type} 的
       @deftech{structure type descriptor} 值。}

 @item{@racket[constructor-id]（默认为 @racket[id]），
       一个接受 @math{m} 个参数并返回 @tech{structure type} 新实例的
       @deftech{constructor} 过程，其中 @math{m} 是不包含 @racket[#:auto] 选项的
       @racket[field] 的数量。}

 @item{@racket[name-id]（默认为 @racket[id]），
       一个封装结构体类型声明信息的 @tech{transformer} 绑定。
       此绑定用于定义子类型，也可与 @racket[shared] 和 @racket[match] 形式配合使用。
       关于 @racket[name-id] 绑定的详细信息，参见 @secref["structinfo"]。
       
       @racket[constructor-id] 和 @racket[name-id] 可以相同，
       此时 @racket[name-id] 同时扮演两种角色。在这种情况下，
       @racket[name-id] 作为表达式展开会产生一个原本不可访问的标识符，
       该标识符绑定到 constructor 过程；展开后的标识符具有
       @racket['constructor-for] 属性，其值是一个与 @racket[name-id]
       @racket[free-identifier=?] 的标识符，
       以及一个可通过 @racket[syntax-procedure-alias-property] 访问的 syntax 属性，
       该属性的标识符与 @racket[name-id] @racket[free-identifier=?]。}

 @item{@racket[id]@racketidfont{?}，一个 @deftech{predicate} 过程，
       对于 @tech{structure type} 的实例（由 @racket[constructor-id] 或子类型的
       @tech{constructor} 构造）返回 @racket[#t]，对于其他任何值返回 @racket[#f]。}

 @item{对于每个 @racket[field]，@racket[id]@racketidfont{-}@racket[field-id]；
       一个 @deftech{accessor} 过程，接受 @tech{structure type} 的实例并提取对应字段的值。}

 @item{对于包含 @racket[#:mutable] 选项的每个 @racket[field]，
       或当 @racket[#:mutable] 选项作为 @racket[struct-option] 指定时，
       @racketidfont{set-}@racket[id]@racketidfont{-}@racket[field-id]@racketidfont{!}；
       一个 @deftech{mutator} 过程，接受 @tech{structure type} 的实例和新字段值。
       结构体被破坏性地更新为新值，并返回 @|void-const|。}

]

如果提供了 @racket[super-id]，它必须具有绑定到 @racket[name-id] 的同类 transformer 绑定
（参见 @secref["structinfo"]），并且它为结构体类型指定超类型。
或者，可以使用 @racket[#:super] 选项来指定必须产生 @tech{structure type descriptor} 的表达式。
关于结构体子类型和超类型的更多信息，参见 @secref["structures"]。
如果同时提供了 @racket[super-id] 和 @racket[#:super]，将报告语法错误。

@examples[#:eval posn-eval
  (struct document (author title content))
  (struct book document (publisher))
  (struct paper (journal) #:super struct:document)
]

如果为单个字段指定了 @racket[#:mutable] 选项，
则该字段可以在结构体类型的实例中被修改，并且会绑定一个 @tech{mutator} 过程。
将 @racket[#:mutable] 作为 @racket[struct-option] 提供，
等同于为所有 @racket[field] 提供该选项。
如果同时作为 @racket[field-option] 和 @racket[struct-option] 指定了 @racket[#:mutable]，
将报告语法错误。

@examples[#:eval posn-eval
  (struct cell ([content #:mutable]) #:transparent)
  (define a-cell (cell 0))
  (set-cell-content! a-cell 1)
]

@racket[#:inspector]、@racket[#:auto-value] 和 @racket[#:guard] 选项
分别指定 inspector、自动字段的值和 guard 过程。
关于结构体类型这些属性的更多信息，参见 @racket[make-struct-type]。
@racket[#:property] 选项可以多次提供，用于向结构体类型附加属性值；
关于属性的更多信息，参见 @secref["structprops"]。
@racket[#:properties] 选项可以多次提供，接受多个属性及其值作为关联列表。
@racket[#:transparent] 选项是 @racket[#:inspector #f] 的简写。

@examples[#:eval posn-eval
  (struct point (x y) #:inspector #f)
  (point 3 5)
  (struct celsius (temp)
    #:guard (λ (temp name)
              (unless (and (real? temp) (>= temp -273.15))
                (error "not a valid temperature"))
              temp))
  (eval:error (celsius -275))
]

@margin-note{使用 @racket[prop:procedure] 属性来实现 @as-index{applicable structure}，
使用 @racket[prop:evt] 来创建其实例为 @tech{synchronizable event} 的结构体类型，等等。
按照惯例，属性名称以 @racketidfont{prop:} 开头。}

@racket[#:prefab] 选项获取 @techlink{prefab}（预定义、全局共享）结构体类型，
而不是创建新的结构体类型。这种结构体类型本质上是透明且非密封的，
不能具有 guard 或属性，因此将 @racket[#:prefab] 与
@racket[#:transparent]、@racket[#:inspector]、@racket[#:guard]、
@racket[#:property]、@racket[#:sealed]、@racket[#:authentic] 或
@racket[#:methods] 一起使用是语法错误。
如果指定了超类型，它也必须是 @tech{prefab} 结构体类型。

@examples[#:eval posn-eval
  (struct prefab-point (x y) #:prefab)
  (prefab-point 1 2)
  (prefab-point? #s(prefab-point 1 2))
]

@racket[#:sealed] 选项是 @racket[#:property prop:sealed #t] 的简写，
防止结构体类型被用作另一个结构体类型的超类型。
更多信息参见 @racket[prop:sealed]。

@racket[#:authentic] 选项是 @racket[#:property prop:authentic #t] 的简写，
防止结构体类型的实例被 impersonate（参见 @racket[impersonate-struct]）、
chaperone（参见 @racket[chaperone-struct]）或获取非 @tech{flat contract}
（参见 @racket[struct/c]）。更多信息参见 @racket[prop:authentic]。
如果指定了超类型，它也必须具有 @racket[prop:authentic] 属性。

如果通过 @racket[#:extra-name] 提供了 @racket[name-id] 且它不是 @racket[id]，
则 @racket[name-id] 和 @racket[id] 都绑定到结构体类型的信息。
在 @racket[struct] 形式中只能提供 @racket[#:extra-name] 和 @racket[#:name] 中的一个，
且 @racket[#:extra-name] 不能与 @racket[#:omit-define-syntaxes] 组合使用。

@examples[#:eval posn-eval
  (struct ghost (color name) #:prefab #:extra-name GHOST)
  (match (ghost 'red 'blinky)
    [(GHOST c n) c])
]

如果提供了 @racket[constructor-id]，则 @racket[name-id] 的 @tech{transformer} 绑定
会将 @racket[constructor-id] 记录为 constructor 绑定；因此，例如，
@racket[struct-out] 会将 @racket[constructor-id] 作为导出包含。
如果通过 @racket[#:extra-constructor-name] 提供了 @racket[constructor-id] 且它不是 @racket[id]，
则对 constructor 应用 @racket[object-name] 会产生 @racket[id] 的符号形式，
而不是 @racket[constructor-id] 的。
如果通过 @racket[#:constructor-name] 提供了 @racket[constructor-id] 且它与 @racket[name-id] 不同，
则 @racket[name-id] 不充当 constructor，
对 constructor 应用 @racket[object-name] 会产生 @racket[constructor-id] 的符号形式。
在 @racket[struct] 形式中只能提供 @racket[#:extra-constructor-name] 和
@racket[#:constructor-name] 中的一个。

@examples[#:eval posn-eval
  (struct color (r g b) #:constructor-name -color)
  (struct rectangle (w h color) #:extra-constructor-name rect)
  (rectangle 13 50 (-color 192 157 235))
  (rect 50 37 (-color 35 183 252))
]

如果提供了 @racket[#:reflection-name symbol-expr]，
则 @racket[symbol-expr] 必须产生一个 symbol，
用于在 @racket[struct-type-info] 等反射操作中标识结构体类型。
它对应于 @racket[make-struct-type] 的第一个参数。
结构体打印使用反射名称，@racket[struct] 绑定的各种过程也使用反射名称。

@examples[#:eval posn-eval
  (struct circle (radius) #:reflection-name '<circle>)
  (circle 15)
  (eval:error (circle-radius "bad"))
]

如果提供了 @racket[#:methods gen:name-id method-defs]（可能多次），
则 @racket[gen:name-id] 必须是由 @racket[define-generics] 产生的
关于 generic interface 的静态信息的 transformer 绑定。
@racket[method-defs] 定义 @racket[gen:name-id] 接口的方法。
@racket[method-defs] 中也可以出现 @racket[define/generic] 形式或辅助定义和表达式。

@examples[#:eval posn-eval
  (struct constant-stream (val)
    #:methods gen:stream
    [(define (stream-empty? stream) #f)
     (define (stream-first stream)
       (constant-stream-val stream))
     (define (stream-rest stream) stream)])
  (stream-ref (constant-stream 'forever) 0)
  (stream-ref (constant-stream 'forever) 50)
]

如果提供了 @racket[#:omit-define-syntaxes] 选项，
则 @racket[name-id]（以及 @racket[id]，如果指定了 @racket[#:extra-name]）
不作为 transformer 绑定。
如果提供了 @racket[#:omit-define-values] 选项，
则不绑定任何常规变量，但绑定 @racket[id]。
如果两者都提供，则 @racket[struct] 形式等价于 @racket[(begin)]。

@examples[#:eval posn-eval
  (struct square (side) #:omit-define-syntaxes)
  (eval:error
   (match (square 5)
     (code:comment "fails to match because syntax is omitted")
     [(struct square x) x]))
  (struct ellipse (width height) #:omit-define-values)
  (eval:error ellipse-width)
]

@margin-note{
  提供给 @racket[#:auto-value] 的表达式只求值一次，
  并在结构体类型的所有实例之间共享。
  特别地，对可变 @racket[#:auto-value] 的更新会影响所有当前和未来的实例。
}
如果提供了 @racket[#:auto] 作为 @racket[field-option]，
则结构体类型的 @tech{constructor} 过程不接受对应于该字段的参数。
相反，使用结构体类型的自动值作为该字段的值，
如 @racket[#:auto-value] 选项所指定的，
或者当未提供 @racket[#:auto-value] 时默认为 @racket[#f]。
该字段是可变的（例如，通过反射操作），但仅在指定了 @racket[#:mutable] 时才绑定 mutator 过程。

如果 @racket[field] 包含 @racket[#:auto] 选项，
则其后的所有字段也必须包含 @racket[#:auto]，否则将报告语法错误。
如果除 @racket[#:property] 之外的任何 @racket[field-option] 或
@racket[struct-option] 关键字被重复，将报告语法错误。

@examples[
#:eval posn-eval
(eval:no-prompt
 (struct posn (x y [z #:auto #:mutable])
   #:auto-value 0
   #:transparent))
(posn 1 2)
(posn? (posn 1 2))
(posn-y (posn 1 2))
(posn-z (posn 1 2))

(eval:no-prompt
 (struct color-posn posn (hue) #:mutable)
 (define cp (color-posn 1 2 "blue")))
(color-posn-hue cp)
cp
(set-posn-z! cp 3)
]

关于序列化，参见 @racket[define-serializable-struct]。

@history[#:changed "6.9.0.4" @elem{Added @racket[#:authentic].}
         #:changed "8.0.0.7" @elem{Added @racket[#:sealed].}
         #:changed "8.17.0.4" @elem{Added @racket[#:properties].}]}


@defform[(struct-field-index field-id)]{

此形式只能作为表达式出现在 @racket[struct] 形式内；
通常与 @racket[#:property] 一起使用，特别是用于 @racket[prop:procedure] 等属性。
@racket[struct-field-index] 表达式的结果是一个精确的非负整数，
对应于 @racket[field-id] 命名的字段在结构体声明中的位置。

@examples[
#:eval posn-eval
(eval:no-prompt
 (struct mood-procedure (base rating)
   #:property prop:procedure (struct-field-index base))
 (define happy+ (mood-procedure add1 10)))
(happy+ 2)
(mood-procedure-rating happy+)
]}


@defform/subs[(define-struct id-maybe-super (field ...)
                             struct-option ...)
              ([id-maybe-super id
                               (id super-id)])]{

类似于 @racket[struct]，但提供 @racket[super-id] 的语法不同，
并且如果既未提供 @racket[#:extra-constructor-name] 也未提供 @racket[#:constructor-name]，
则会通过 @racket[#:extra-constructor-name] 隐式提供
在 @racket[id] 前添加 @racketidfont{make-} 前缀的 @racket[_constructor-id]。

此形式为了向后兼容而提供；推荐使用 @racket[struct]。

@examples[
#:eval posn-eval
(eval:no-prompt
 (define-struct posn (x y [z #:auto])
    #:auto-value 0
    #:transparent))
(make-posn 1 2)
(posn? (make-posn 1 2))
(posn-y (make-posn 1 2))
]}

@defform*[((struct/derived (id . rest-form) 
           id (field ...) struct-option ...)
           (struct/derived (id . rest-form)
           id super-id (field ...) struct-option ...))]{

The same as @racket[struct], but with an extra @racket[(id
. rest-form)] sub-form that is treated as the overall form for
syntax-error reporting and otherwise ignored.  The only constraint on
the sub-form for error reporting is that it starts with @racket[id].
The @racket[struct/derived] form is intended for use by macros
that expand to @racket[struct].

@examples[
#:eval posn-eval
(eval:no-prompt
 (define-syntax (fruit-struct stx)
   (syntax-case stx ()
    [(ds name . rest) 
     (with-syntax ([orig stx])
       #'(struct/derived orig name (seeds color) . rest))])))

(fruit-struct apple)
(apple-seeds (apple 12 "red"))
(fruit-struct apple #:mutable)
(set-apple-seeds! (apple 12 "red") 8)
(code:comment "this next line will cause an error due to a bad keyword")
(eval:error (fruit-struct apple #:bad-option))
]
@history[#:added "7.5.0.16"]}

@defform[(define-struct/derived (id . rest-form) 
           id-maybe-super (field ...) struct-option ...)]{

类似于 @racket[struct/derived]，但提供 @racket[super-id] 的语法不同，
并且如果既未提供 @racket[#:extra-constructor-name] 也未提供 @racket[#:constructor-name]，
则会通过 @racket[#:extra-constructor-name] 隐式提供
在 @racket[id] 前添加 @racketidfont{make-} 前缀的 @racket[_constructor-id]。
@racket[define-struct/derived] 形式旨在供展开为 @racket[define-struct] 的宏使用。

@examples[
#:eval posn-eval
(eval:no-prompt
 (define-syntax (define-xy-struct stx)
   (syntax-case stx ()
    [(ds name . rest) 
     (with-syntax ([orig stx])
       #'(define-struct/derived orig name (x y) . rest))])))

(define-xy-struct posn)
(posn-x (make-posn 1 2))
(define-xy-struct posn #:mutable)
(set-posn-x! (make-posn 1 2) 0)
(code:comment "this next line will cause an error due to a bad keyword")
(eval:error (define-xy-struct posn #:bad-option))
]
@history[#:changed "7.5.0.16" @elem{Moved main description to @racket[struct/derived]
                                    and replaced with differences.}]}

@; ----------------------------------------

@close-eval[posn-eval]
