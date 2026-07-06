#lang scribble/doc
@(require (except-in "mz.rkt" import export)
          (for-syntax racket/base)
          (for-label racket/require-transform
                     racket/require-syntax
                     racket/provide-transform
                     racket/provide-syntax
                     racket/keyword-transform
                     racket/stxparam
                     racket/phase+space
                     syntax/intdef))

@(define stx-eval (make-base-eval))
@examples[#:hidden #:eval stx-eval (require (for-syntax racket/base))]

@(define (transform-time) @t{This procedure must be called during the
dynamic extent of a @tech{syntax transformer} application by the
expander or while a module is @tech{visit}ed (see
@racket[syntax-transforming?]), otherwise the
@exnraise[exn:fail:contract].})

@(define (provided-as-protected) @t{This procedure's binding is provided as
  @tech{protected} in the sense of @racket[protect-out].})


@title[#:tag "stxtrans"]{语法变换器}

@defproc[(set!-transformer? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[make-set!-transformer] 创建的值，或者是具有
@racket[prop:set!-transformer] 属性的结构类型实例，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-set!-transformer [proc (syntax? . -> . syntax?)])
         set!-transformer?]{

创建一个与 @racket[set!] 协作的 @tech{赋值变换器}。如果将 @racket[make-set!-transformer] 的结果
作为 @tech{变换器} 绑定到 @racket[_id]，那么当 @racket[_id] 在表达式位置使用，或者作为 @racket[set!] 赋值的目标（如 @racket[(set! _id _expr)]）使用时，
@racket[proc] 将作为变换器被应用。当标识符作为 @racket[set!] 目标出现时，整个 @racket[set!]
表达式会被传递给变换器。

@examples[
#:eval stx-eval
(let ([x 1]
      [y 2])
  (let-syntax ([x (make-set!-transformer
                    (lambda (stx)
                      (syntax-case stx (set!)
                        (code:comment @#,t{Redirect mutation of x to y})
                        [(set! id v) (syntax (set! y v))]
                        (code:comment @#,t{Normal use of @racket[x] really gets @racket[x]})
                        [id (identifier? (syntax id)) (syntax x)])))])
    (begin
      (set! x 3)
      (list x y))))
]}


@defproc[(set!-transformer-procedure [transformer set!-transformer?])
         (syntax? . -> . syntax?)]{

返回传递给 @racket[make-set!-transformer] 用于创建 @racket[transformer] 的过程，
或者由 @racket[transformer] 的 @racket[prop:set!-transformer] 属性标识的过程。}


@defthing[prop:set!-transformer struct-type-property?]{

一个 @tech{结构类型属性}，用于标识充当 @tech{赋值变换器}（类似于 @racket[make-set!-transformer] 创建的变换器）的结构类型。

属性值必须是一个精确整数，或者是一个接受一个或两个参数的过程。对于前一种情况，该整数指定结构内应包含一个过程的字段；该整数必须在 @racket[0]（含）到结构类型中非自动字段的数量（不含，不计算超类型字段）之间，并且指定的字段也必须被声明为不可变。

如果属性值是一个接受一个参数的过程，那么该过程作为 @tech{语法变换器}，并用于 @racket[set!] 变换。如果属性值是一个接受两个参数的过程，那么第一个参数是具有 @racket[prop:set!-transformer] 属性的结构，第二个参数是一个语法对象，类似于 @tech{语法变换器} 和 @racket[set!] 变换；应用到该结构的 @racket[set!-transformer-procedure] 会生成一个新函数，该函数仅接受语法对象并调用通过该属性关联的过程。最后，如果属性值是一个整数，则从结构实例中提取目标标识符；如果该字段值不是一个接受一个参数的过程，则使用一个总是调用 @racket[raise-syntax-error] 的过程来替代。

如果一个值同时具有 @racket[prop:set!-transformer] 和 @racket[prop:rename-transformer] 属性，则后者优先。如果一个结构类型同时具有 @racket[prop:set!-transformer] 和 @racket[prop:procedure] 属性，则在宏展开时前者优先。}


@defproc[(rename-transformer? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[make-rename-transformer] 创建的值，或者是具有 @racket[prop:rename-transformer] 属性的结构类型实例，则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval stx-eval
  (rename-transformer? (make-rename-transformer #'values))
  (rename-transformer? 'not-a-rename-transformer)
]}


@defproc[(make-rename-transformer [id-stx syntax?])
         rename-transformer?]{

创建一个 @tech{重命名变换器}，当作为 @tech{变换器} 绑定时，它充当一个变换器，将标识符 @racket[id-stx] 插入到绑定该变换器的任何标识符的位置，包括在非应用位置和 @racket[set!] 表达式中。

这样的变换器可以手动编写，但是由 @racket[make-rename-transformer] 创建的变换器在与解析器和其他语法形式协作时会触发特殊行为，当 @racket[_id] 绑定到该重命名变换器时：

@itemlist[

 @item{The parser installs a @racket[free-identifier=?] and
       @racket[identifier-binding] equivalence between @racket[_id]
       and @racket[_id-stx], as long as @racket[id-stx] does not have
       a true value for the @indexed-racket['not-free-identifier=?]
       @tech{syntax property}.}

 @item{A @racket[provide] of @racket[_id] provides the binding
       indicated by @racket[id-stx] instead of @racket[_id], as long
       as @racket[id-stx] does not have a true value for the
       @racket['not-free-identifier=?] @tech{syntax property}
       and as long as @racket[id-stx] has a binding.}

 @item{If @racket[provide] exports @racket[_id], it uses a
       symbol-valued @indexed-racket['nominal-id] property of
       @racket[id-stx] to specify the ``nominal source identifier'' of
       the binding as reported by @racket[identifier-binding].}

 @item{If @racket[id-stx] has a true value for the
       @indexed-racket['not-provide-all-defined] @tech{syntax
       property}, then @racket[_id] (or its target) is not exported by
       @racket[all-defined-out].}

 @item{The @racket[syntax-local-value] function recognizes
       rename-transformer bindings and consult their targets.}

]

@examples[#:eval stx-eval
  (define-syntax my-or (make-rename-transformer #'or))
  (my-or #f #t)
  (free-identifier=? #'my-or #'or)
]

@history[#:changed "6.3" @elem{Removed an optional second argument.}
         #:changed "7.4.0.10" @elem{Adjusted rename-transformer expansion
                                    to add a macro-introduction scope, the
                                    same as regular macro expansion.}]}


@defproc[(rename-transformer-target [transformer rename-transformer?])
         identifier?]{

返回传递给 @racket[make-rename-transformer] 用于创建 @racket[transformer] 的标识符，
或者由 @racket[transformer] 上的 @racket[prop:rename-transformer] 属性所指示的标识符。

@examples[#:eval stx-eval
  (rename-transformer-target (make-rename-transformer #'or))
]}


@defthing[prop:rename-transformer struct-type-property?]{

一个 @tech{结构类型属性}，用于标识充当 @tech{重命名变换器}（类似于 @racket[make-rename-transformer] 创建的变换器）的结构类型。

属性值必须是一个精确整数、一个标识符 @tech{语法对象}，或者一个接受一个参数的过程。
对于前一种情况，该整数指定结构内应包含一个标识符的字段；该整数必须在 @racket[0]（含）到结构类型中非自动字段的数量（不含，不计算超类型字段）之间，并且指定的字段也必须被声明为不可变。

如果属性值是一个标识符，则该标识符作为重命名的目标，就像 @racket[make-rename-transformer] 的第一个参数一样。如果属性值是一个整数，则从结构实例中提取目标标识符；如果该字段值不是一个标识符，则使用一个带有空上下文的 @racketidfont{?} 标识符来替代。

如果属性值是一个接受一个参数的过程，则调用该过程来获取重命名变换器将用作目标标识符的标识符。返回的标识符可能应该具有 @racket['not-free-identifier=?] 语法属性。如果该过程返回任何不是标识符的值，则引发 @racket[exn:fail:contract] 异常。

@examples[#:eval stx-eval #:escape UNSYNTAX
  (code:comment "Example of a procedure argument for prop:rename-transformer")
  (define-syntax slv-1 'first-transformer-binding)
  (define-syntax slv-2 'second-transformer-binding)
  (begin-for-syntax
    (struct slv-cooperator (redirect-to-first?)
      #:property prop:rename-transformer
      (λ (inst)
        (if (slv-cooperator-redirect-to-first? inst)
            #'slv-1
            #'slv-2))))
  (define-syntax (slv-lookup stx)
    (syntax-case stx ()
      [(_ id)
       #`(quote #,(syntax-local-value #'id))]))
  (define-syntax slv-inst-1 (slv-cooperator #t))
  (define-syntax slv-inst-2 (slv-cooperator #f))
  (slv-lookup slv-inst-1)
  (slv-lookup slv-inst-2)
]

@history[#:changed "6.3" "the property now accepts a procedure of one argument."]}


@defproc[(local-expand [stx any/c]
                       [context-v (or/c 'expression 'top-level 'module 'module-begin list?)]
                       [stop-ids (or/c (listof identifier?) empty #f)]
                       [intdef-ctx (or/c internal-definition-context?
                                         #f
                                         (listof internal-definition-context?))
                                   #f])
         syntax?]{

在当前正在展开的表达式的词法上下文中展开 @racket[stx]。@racket[context-v] 参数用作即时展开时 @racket[syntax-local-context] 的结果；列表表示一个 @tech{内部定义上下文}，关于列表形式的更多信息见下文。如果 @racket[stx] 还不是一个 @tech{语法对象}，则在展开前使用 @racket[(datum->syntax #f stx)] 进行强制转换。

@racket[stop-ids] 参数控制 @racket[local-expand] 对 @racket[stx] 的展开深度：

@itemlist[
 @item{If @racket[stop-ids] is an empty list, then @racket[stx] is recursively expanded (i.e.
       expansion proceeds to sub-expressions). The result is guaranteed to be a fully-expanded form,
       which can include the bindings listed in @secref["fully-expanded"], plus @racket[#%expression]
       in any expression position.}

 @item{If @racket[stop-ids] is a list containing just @racket[module*], then expansion proceeds as if
       @racket[stop-ids] were an empty list, except that expansion does not recur to @tech{submodules}
       defined with @racket[module*] (which are left unexpanded in the result).}

 @item{If @racket[stop-ids] is any other list, then @racket[begin], @racket[quote], @racket[set!],
       @racket[#%plain-lambda], @racket[case-lambda], @racket[let-values], @racket[letrec-values],
       @racket[if], @racket[begin0], @racket[with-continuation-mark], @racket[letrec-syntaxes+values],
       @racket[#%plain-app], @racket[#%expression], @racket[#%top], and @racket[#%variable-reference]
       are implicitly added to @racket[stop-ids]. Expansion proceeds recursively, stopping when the
       expander encounters any of the forms in @racket[stop-ids], and the result is the
       partially-expanded form.

       When the expander would normally implicitly introduce a @racketid[#%app], @racketid[#%datum],
       or @racketid[#%top] identifier as described in @secref["expand-steps"], it checks to see if an
       identifier with the same @tech{binding} as the one to be introduced appears in
       @racket[stop-ids]. If so, the identifier is @emph{not} introduced; the result of expansion is
       the bare application, literal data expression, or unbound identifier rather than one wrapped in
       the respective explicit form.

       When @racket[#%plain-module-begin] is not in @racket[stop-ids], the
       @racket[#%plain-module-begin] transformer detects and expands sub-forms (such as
       @racket[define-values]) regardless of the identifiers presence in @racket[stop-ids].

       Expansion does not replace the scopes in a local-variable
       reference to match the binding identifier.}

 @item{If @racket[stop-ids] is @racket[#f] instead of a list, then @racket[stx] is expanded only as
       long as the outermost form of @racket[stx] is a macro (i.e. expansion does @emph{not} proceed
       to sub-expressions, and it does not replace the scopes in a local-variable reference to match the
       binding identifier). The @racketid[#%app], @racketid[#%datum], and @racketid[#%top] identifiers are
       never introduced.}]

与 @racket[stop-ids] 无关，当 @racket[local-expand] 遇到一个具有局部绑定但在当前展开上下文中没有绑定的标识符时，该变量保持原样（而不是触发"上下文之外"的语法错误）。

当 @racket[context-v] 为 @racket['module-begin] 且展开结果是一个 @racket[#%plain-module-begin] 形式时，
会以与 @racket[module] 展开相同的方式为每个内嵌的 @racket[module] 形式（但不包括 @racket[module*] 形式）添加
@racket['submodule] @tech{语法属性}。

如果 @racket[intdef-ctx] 参数是一个内部定义上下文，则在调用 @racket[local-expand] 的动态范围内，其 @tech{绑定} 和所有 @tech{父内部定义上下文} 的 @tech{绑定} 将被添加到 @tech{局部绑定上下文} 中。
此外，除非在创建内部定义上下文时为 @racket[syntax-local-make-definition-context] 的 @racket[_add-scope?] 参数提供了 @racket[#f]，
否则其 @tech{内边缘作用域}（但 @emph{不} 包括任何 @tech{父内部定义上下文} 的作用域）将被添加到 @racket[stx] 展开前和展开结果的
@tech{词法信息} 中（因为展开可能会引入对内部定义绑定的绑定或引用）。

为了向后兼容，当 @racket[intdef-ctx] 是一个列表时，所有提供的内部定义上下文及其父上下文的所有 @tech{绑定} 都将添加到 @tech{局部绑定上下文} 中，
并且每个上下文中 @racket[_add-scope?] 不是 @racket[#f] 的 @tech{内边缘作用域} 以相同方式添加。

展开记录 @tech{使用点作用域} 以便从定义绑定中移除。当 @racket[intdef-ctx] 参数是一个内部定义上下文时，使用点作用域与该上下文一起记录。
当 @racket[intdef-ctx] 是 @racket[#f] 或（为了向后兼容）一个列表时，使用点作用域与当前展开上下文一起记录。

对于特定的 @tech{内部定义上下文}，生成一个唯一值并将其放入 @racket[context-v] 的列表中。为了允许 @racket[define] 形式的 @tech{自由展开}，
生成的值应该是一个对 @racket[prop:liberal-define-context] 具有真值的结构实例。如果内部定义上下文是自包含的，
则 @racket[context-v] 的列表应仅包含生成的值；如果内部定义上下文要拼接到直接包围的上下文中，
则当 @racket[syntax-local-context] 产生一个列表时，将生成的值 @racket[cons] 到该列表上。

当通过 @racket[local-expand] 使用内部定义上下文 @racket[intdef-ctx] 展开表达式，并且将展开后的表达式整合到整体形式 @racket[_new-stx] 中时，
通常应对 @racket[intdef-ctx] 和 @racket[_new-stx] 应用 @racket[internal-definition-context-track]，
以便向外部工具提供展开历史。

@transform-time[]

@examples[#:eval stx-eval
(define-syntax-rule (do-print x ...)
  (printf x ...))

(define-syntax-rule (hello x)
  (do-print "hello ~a" x))

(define-syntax (show stx)
  (syntax-case stx ()
    [(_ x)
     (let ([partly (local-expand #'(hello x)
                                 'expression
                                 (list #'do-print))]
           [fully (local-expand #'(hello x)
                                'expression
                                #f)])
       (printf "partly expanded: ~s\n" (syntax->datum partly))
       (printf "fully expanded: ~s\n" (syntax->datum fully))
       fully)]))

(show 1)
]

@provided-as-protected[]

@history[#:changed "6.0.1.3" @elem{Changed treatment of @racket[#%top]
                                   so that it is never introduced as
                                   an explicit wrapper.}
         #:changed "6.0.90.27" @elem{Loosened the contract on the @racket[intdef-ctx] argument to
                                     allow an empty list.}
         #:changed "8.2.0.4" @elem{Changed binding to @tech{protected}.}]}


@defproc[(syntax-local-expand-expression [stx any/c] [opaque-only? any/c #f])
         (values (if opaque-only? #f syntax?) syntax?)]{

类似于给定 @racket['expression] 和一个空停止列表的 @racket[local-expand]，但返回两个结果：一个完全展开的表达式语法对象，以及一个内容不透明的语法对象。

后者可以替代前者使用（可能用于宏变换器产生的更大表达式中），当宏展开器遇到不透明对象时，它直接替换完全展开的表达式而无需重新展开；
如果展开上下文包含原始展开时不存在 @tech{作用域}，则 @exnraise[exn:fail:syntax]，因为重新展开可能产生不同的结果。
持续使用 @racket[syntax-local-expand-expression] 和不透明对象可以避免嵌套局部展开时的二次展开时间。

如果 @racket[opaque-only?] 为真，则第一个结果为 @racket[#f] 而非展开后的表达式。仅获取第二个不透明结果在某些展开上下文中可能更高效。

与 @racket[local-expand] 不同，@racket[syntax-local-expand-expression] 通常产生不含 @racket[#%expression] 形式的展开表达式。
但是，如果在由外围 @racket[local-expand] 调用触发的展开中使用 @racket[syntax-local-expand-expression]，
则 @racket[syntax-local-expand-expression] 的结果可能包含 @racket[#%expression] 形式。

@transform-time[] @provided-as-protected[]

@history[#:changed "6.90.0.13" @elem{Added the @racket[opaque-only?] argument.}
         #:changed "8.2.0.4" @elem{Changed binding to @tech{protected}.}]}


@defproc[(local-transformer-expand [stx any/c]
                                   [context-v (or/c 'expression 'top-level list?)]
                                   [stop-ids (or/c (listof identifier?) #f)]
                                   [intdef-ctx (or/c internal-definition-context?
                                                     #f
                                                     (listof internal-definition-context?))
                                    #f])
         syntax?]{

类似于 @racket[local-expand]，但 @racket[stx] 作为变换器表达式展开，而非运行时表达式。

展开 @racket[stx] 期间通过调用 @racket[syntax-local-lift-expression] 产生的任何提升表达式都会被捕获到结果中。
如果 @racket[context-v] 是 @racket['top-level]，则提升内容被捕获在 @racket[begin] 形式中，
否则提升内容被捕获在 @racket[let-values] 形式中。如果展开期间没有表达式被提升，则不会添加 @racket[begin] 或 @racket[let-values] 包装。

@provided-as-protected[]

@history[#:changed "6.5.0.3" @elem{Allowed and captured lifts in a
                                   @racket['top-level] context.}
         #:changed "8.2.0.4" @elem{Changed binding to @tech{protected}.}]}


@defproc[(local-expand/capture-lifts
          [stx any/c]
          [context-v (or/c 'expression 'top-level 'module 'module-begin list?)]
          [stop-ids (or/c (listof identifier?) #f)]
          [intdef-ctx (or/c internal-definition-context?
                            #f
                            (listof internal-definition-context?))
           #f]
          [lift-ctx any/c (gensym 'lifts)])
         syntax?]{

类似于 @racket[local-expand]，但结果是一个表示 @racket[begin] 表达式的语法对象。
展开 @racket[stx] 期间通过调用 @racket[syntax-local-lift-expression] 产生的提升表达式以 @racket[define-values] 形式出现，
其中包含它们的标识符，而 @racket[stx] 的展开结果是 @racket[begin] 中的最后一个表达式。
@racket[lift-ctx] 值由 @racket[syntax-local-lift-context] 在局部展开期间报告。
提升的表达式不会被展开，而是保持原样出现在 @racket[begin] 形式中。

如果 @racket[context-v] 是 @racket['top-level] 或 @racket['module]，则可以通过 @racket[syntax-local-lift-module] 添加的 @racket[module] 形式
出现在结果中。如果 @racket[context-v] 是 @racket['module]，则 @racket[module*] 形式也可以出现。

@provided-as-protected[]

@history[#:changed "8.2.0.4" @elem{Changed binding to @tech{protected}.}]}


@defproc[(local-transformer-expand/capture-lifts
          [stx any/c]
          [context-v (or/c 'expression 'top-level list?)]
          [stop-ids (or/c (listof identifier?) #f)]
          [intdef-ctx (or/c internal-definition-context?
                            #f
                            (listof internal-definition-context?))
           #f]
          [lift-ctx any/c (gensym 'lifts)])
         syntax?]{

类似于 @racket[local-expand/capture-lifts]，但 @racket[stx] 作为变换器表达式展开，而非运行时表达式。
提升的表达式报告为 @racket[define-values] 形式（在变换器环境中）。

@provided-as-protected[]

@history[#:changed "8.2.0.4" @elem{Changed binding to @tech{protected}.}]}


@defproc[(syntax-local-apply-transformer
          [transformer procedure?]
          [binding-id/insp (or/c #f identifier? inspector?
                                 (list identifier? inspector?))]
          [context-v (or/c 'expression 'top-level 'module 'module-begin list?)]
          [intdef-ctx (or/c internal-definition-context? #f)]
          [v any/c] ...)
         any]{

在新的展开 @tech{上下文} 和 @tech{局部绑定上下文} 中将过程 @racket[transformer] 应用于 @racket[v]。
以与 @tech{语法变换器} 应用相同的方式对参数和返回值添加和翻转 @tech{宏引入作用域} 和 @tech{使用点作用域}。
参数和返回值可以是任何值；仅对语法对象操纵作用域。

@racket[context-v] 参数与 @racket[local-expand] 中的相同，@racket[intdef-ctx] 是一个 @tech{内部定义上下文} 值或 @racket[#f]。

@racket[binding-id/insp] 参数编码最多两个额外参数：作为标识符的 @racket[_biding-id] 和作为 @tech{检查器} 的 @racket[_expander-insp]。
@racket[_binding-id] 部分（如果提供了的话）指定与 @racket[transformer] 关联的 @tech{绑定}，展开器用它来确定是否添加 @tech{使用点作用域} 以及
展开期间使用哪个 @tech{代码检查器}。@racket[_expander-insp] 部分指定展开器本身的 @tech{代码检查器}，默认为与当前进行中的变换器的绑定关联的代码检查器。
相关的检查器是 @racket[_binding-id] 和 @racket[_expander-insp] 所暗示的检查器的下级（在 @racket[inspector-superior?] 的意义上），前提是这些检查器是可比较的，否则没有检查器。

@transform-time[]

@history[#:added "8.2.0.7"
         #:changed "8.18.0.15" @elem{Changed the @racket[binding-id/insp] to allow
                                     an @racket[_expander-insp] component.}]}


@defproc[(internal-definition-context? [v any/c]) boolean?]{

如果 @racket[v] 是一个 @tech{内部定义上下文}，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(syntax-local-make-definition-context
          [parent-ctx (or/c internal-definition-context? #f) #f]
          [add-scope? any/c #t])
         internal-definition-context?]{

创建一个不透明的 @tech{内部定义上下文} 值，用于 @racket[local-expand] 和其他函数。变换器应为要展开的每组内部定义创建一个上下文。

在展开其词法上下文应包含这些定义的形式之前，变换器应使用 @racket[internal-definition-context-add-scopes] 将上下文的作用域应用到语法。
调用 @racket[local-expand] 等过程展开这些形式时，应将 @tech{内部定义上下文} 值作为参数提供。

发现内部 @racket[define-values] 或 @racket[define-syntaxes] 形式后，使用 @racket[syntax-local-bind-syntaxes] 向上下文添加 @tech{绑定}。

@tech{内部定义上下文} 内部创建 @tech{外边缘作用域} 和 @tech{内边缘作用域} 来表示该上下文。@tech{内边缘作用域} 被添加到在该上下文中展开的任何形式，
或者作为该上下文中（部分）展开结果出现的任何形式。为了向后兼容，为 @racket[add-scope?] 提供 @racket[#f] 会禁用此行为。

如果 @racket[parent-ctx] 不是 @racket[#f]，则 @racket[parent-ctx] 成为新内部定义上下文的 @deftech{父内部定义上下文}。 每当新上下文的 @tech{绑定} 被添加到 @tech{局部绑定上下文} 时（例如通过将上下文提供给 @racket[local-expand]、
@racket[syntax-local-bind-syntaxes] 或 @racket[syntax-local-value]），来自 @racket[parent-ctx] 的绑定也会被添加。
如果 @racket[parent-ctx] 也是通过 @tech{父内部定义上下文} 创建的，则其父级的 @tech{绑定} 也会被添加，以此递归进行。
请注意，父上下文的 @tech{作用域} @emph{不会} 隐式添加，仅添加 @tech{绑定}，即使子上下文的 @tech{内边缘作用域} 会被隐式添加。 If the
@tech{scopes} of parent definition contexts should be added, the parent contexts must be provided
explicitly.

Additionally, if the created definition context is intended to be spliced into a surrounding
definition context, the surrounding context should always be provided for the @racket[parent-ctx]
argument to ensure the necessary @tech{use-site scopes} are added to macros expanded in the context.
Otherwise, expansion of nested definitions can be inconsistent with the expansion of definitions in
the surrounding context.

An @tech{internal-definition context} also tracks @tech{use-site scopes} created during expansion
within the definition context, so that they can be removed from bindings created in the context,
at @racket[syntax-local-identifier-as-binding], and at @racket[internal-definition-context-splice-binding-identifier].

仅当在 @tech{语法变换器} 应用的动态范围内创建新的定义上下文，或者在正在展开的模块中的 @racket[begin-for-syntax] 形式（可能嵌套）中创建时，
与该新定义上下文关联的作用域才会从 @racket[quote-syntax] 形式中被修剪。

@transform-time[]

@history[#:changed "6.3" @elem{Added the @racket[add-scope?] argument,
                               and made calling
                               @racket[internal-definition-context-seal]
                               no longer necessary.}
         #:changed "8.2.0.7" @elem{Added the @tech{outside-edge scope} and @tech{use-site scope}
                                   tracking behaviors.}]}

@defproc[(syntax-local-make-definition-context-introducer
          [name (and/c symbol? (not/c 'macro)) 'intdef])
         ((syntax?) ((or/c 'flip 'add 'remove)) . ->* . syntax?)]{

类似于 @racket[make-syntax-introducer]，但封装在其中的 @tech{作用域} 会从 @racket[quote-syntax] 形式中被修剪，
很像与新定义上下文关联的作用域（参见 @racket[syntax-local-make-definition-context]）。@racket[name] 参数用作符号名，作为调试辅助。

通常优先使用 @racket[internal-definition-context-add-scopes] 和 @racket[internal-definition-context-splice-binding-identifier]，
但当你确定需要一个应从 @racket[quote-syntax] 形式中修剪的单一作用域时，此函数可能有用。

@transform-time[]

@history[#:added "8.12.0.8"]}


@defproc[(internal-definition-context-add-scopes [intdef-ctx internal-definition-context?]
                                                 [stx syntax?])
         syntax?]{

将 @racket[intdef-ctx] 的 @tech{外边缘作用域} 和 @tech{内边缘作用域} 添加到 @racket[stx]。

使用此函数在展开前将定义上下文作用域应用到源自该定义上下文内的语法。

@history[#:added "8.2.0.7"]}


@defproc[(internal-definition-context-splice-binding-identifier
          [intdef-ctx internal-definition-context?]
          [id identifier?])
         syntax?]{

从 @racket[id] 中移除与 @racket[intdef-ctx] 关联的作用域：@tech{外边缘作用域}、@tech{内边缘作用域} 以及
在定义上下文内的展开所创建的 @tech{使用点作用域}。

当将源自 @racket[intdef-ctx] 内的绑定拼接到外围上下文中时使用。

@history[#:added "8.2.0.7"]}


@defproc[(syntax-local-bind-syntaxes [id-list (listof identifier?)]
                                     [expr (or/c syntax? #f)]
                                     [intdef-ctx internal-definition-context?]
                                     [extra-intdef-ctxs (or/c internal-definition-context?
                                                              (listof internal-definition-context?))
                                      '()])
         (listof identifier?)]{

在由 @racket[intdef-ctx] 表示的 @tech{内部定义上下文} 中绑定 @racket[id-list] 中的每个标识符，
其中 @racket[intdef-ctx] 是 @racket[syntax-local-make-definition-context] 的结果。
返回具有与新绑定匹配的 @tech{词法信息} 的标识符。

为了向后兼容，在绑定之前，@racket[extra-intdef-ctxs] 中每个元素的 @tech{词法信息} 也会添加到 @racket[id-list] 中的每个标识符。

当标识符对应 @racket[define-values] 绑定时，为 @racket[expr] 提供 @racket[#f]；
当标识符对应 @racket[define-syntaxes] 绑定时，提供一个编译时表达式。
在后一种情况下，表达式产生的值的数量应与标识符的数量匹配，否则 @exnraise[exn:fail:contract:arity]。

当 @racket[expr] 不是 @racket[#f] 时，它在 @tech{表达式上下文} 中展开并在当前 @tech{变换器环境} 中求值。 In this case, the @tech{bindings} and @tech{lexical
information} from both @racket[intdef-ctx] and @racket[extra-intdef-ctxs] are used to enrich
@racket[expr]’s @tech{lexical information} and extend the @tech{local binding context} in the same way
as the fourth argument to @racket[local-expand]. If @racket[expr] is @racket[#f], the value provided
for @racket[extra-intdef-ctxs] is ignored.

@transform-time[]

@history[#:changed "6.90.0.27" @elem{Added the @racket[extra-intdef-ctxs] argument.}
         #:changed "8.2.0.7" @elem{Changed the return value from @void-const to the list of bound identifiers.}]}


@defproc[(internal-definition-context-binding-identifiers
          [intdef-ctx internal-definition-context?])
         (listof identifier?)]{

返回通过 @racket[syntax-local-bind-syntaxes] 为 @racket[intdef-ctx] 注册的所有绑定标识符的列表。
返回列表中的每个标识符都包含 @tech{内部定义上下文} 的 @tech{作用域}。

@history[#:added "6.3.0.4"]}


@defproc[(internal-definition-context-introduce [intdef-ctx internal-definition-context?]
                                                [stx syntax?]
                                                [mode (or/c 'flip 'add 'remove) 'flip])
         syntax?]{

对 @racket[stx] 的所有部分翻转、添加或移除（取决于 @racket[mode]）@racket[intdef-ctx] 的 @tech{作用域}。

提供此函数是为了向后兼容；推荐使用 @racket[internal-definition-context-add-scopes] 和
@racket[internal-definition-context-splice-binding-identifier]。
另请参阅 @racket[syntax-local-make-definition-context-introducer]，用于封装应从 @racket[quote-syntax] 形式中修剪的单一作用域。

@history[#:added "6.3"]}



@defproc[(internal-definition-context-seal [intdef-ctx internal-definition-context?])
         void?]{

仅为向后兼容而提供；无实际作用。}


@defproc[(identifier-remove-from-definition-context [id-stx identifier?]
                                                    [intdef-ctx (or/c internal-definition-context?
                                                                      (listof internal-definition-context?))])
         identifier?]{

从 @racket[id-stx] 中移除 @racket[intdef-ctx] 的所有 @tech{作用域}（或列表 @racket[intdef-ctx] 中每个元素的作用域）。

提供 @racket[identifier-remove-from-definition-context] 函数是为了向后兼容；
推荐使用 @racket[internal-definition-context-splice-binding-identifier] 函数。

@history[#:changed "6.3" @elem{Simplified the operation to @tech{scope} removal.}]}




@defthing[prop:expansion-contexts struct-type-property?]{

一个 @tech{结构类型属性}，用于约束宏 @tech{变换器} 和 @tech{重命名变换器} 的使用。属性值
必须是一个符号列表，允许的符号有 @racket['expression]、@racket['top-level]、@racket['module]、
@racket['module-begin] 和 @racket['definition-context]。每个符号对应一个展开上下文，与
@racket[local-expand] 或 @racket[syntax-local-context] 报告的方式相同，不同之处在于 @racket['definition-context]（而不是列表）用于表示
@tech{内部定义上下文}。

如果标识符绑定到的变换器的列表不包含该标识符特定用途的符号，则按以下方式调整用法：
@;
@itemlist[

 @item{In a @racket['module-begin] context, then the use is wrapped in
       a @racket[begin] form.}

 @item{In a @racket['module], @racket['top-level],
       @racket['internal-definition] or context, if
       @racket['expression] is present in the list, then the use is
       wrapped in an @racket[#%expression] form.}

 @item{否则，报告语法错误。}

]

@racket[prop:expansion-contexts] 属性在与 @racket[prop:rename-transformer] 结合使用时最为有用，
因为一般的 @tech{变换器} 过程可以使用 @racket[syntax-local-context]。
此外，当 @tech{重命名变换器} 的标识符具有 @racket['not-free-identifier=?] 属性时，
@racket[prop:expansion-contexts] 属性最具意义，否则绑定的定义会创建一个绑定别名，
实际上绕过了 @racket[prop:expansion-contexts] 属性。

@history[#:added "6.3"]}


@defproc[(syntax-local-value [id-stx identifier?]
                             [failure-thunk (or/c (-> any) #f)
                                            #f]
                             [intdef-ctx (or/c internal-definition-context?
                                               #f
                                               (listof internal-definition-context?))
                              #f])
         any]{

在当前展开上下文中返回标识符 @racket[id-stx] 的 @tech{变换器} 绑定值。如果 @racket[intdef-ctx] 不是 @racket[#f]，
则还会考虑所有提供的定义上下文中的绑定。与 @racket[local-expand] 的第四个参数不同，
提供的定义上下文关联的 @tech{作用域} @emph{不} 用于丰富 @racket[id-stx] 的 @tech{词法信息}。

如果 @racket[id-stx] 绑定到由 @racket[make-rename-transformer] 创建的 @tech{重命名变换器}，
则 @racket[syntax-local-value] 实际上会使用重命名的目标调用自身，并返回该结果而不是 @tech{重命名变换器}。

如果 @racket[id-stx] 在该环境中没有 @tech{变换器} 绑定（通过 @racket[define-syntax]、@racket[let-syntax] 等），
则如果 @racket[failure-thunk] 不是 @racket[#f]，则通过应用它来获取结果。如果 @racket[failure-thunk] 是 @racket[false]，
则 @exnraise[exn:fail:contract]。

@transform-time[]

@examples[#:eval stx-eval
  (define-syntax swiss-cheeses? #t)
  (define-syntax (transformer stx)
    (if (syntax-local-value #'swiss-cheeses?)
        #''(gruyère emmental raclette)
        #''(roquefort camembert boursin)))
  (transformer)
]
@examples[#:eval stx-eval
  (define-syntax (transformer-2 stx)
    (syntax-local-value #'something-else (λ () (error "no binding"))))
  (eval:error (transformer-2))
]
@examples[#:eval stx-eval
  (define-syntax nachos #'(printf "nachos~n"))
  (define-syntax chips (make-rename-transformer #'nachos))
  (define-syntax (transformer-3 stx)
    (syntax-local-value #'chips))
  (transformer-3)
]

@provided-as-protected[]

@history[
 #:changed "6.90.0.27" @elem{Changed @racket[intdef-ctx] to accept a list of internal-definition
                             contexts in addition to a single internal-definition context or
                             @racket[#f].}
 #:changed "8.2.0.4" @elem{Changed binding to @tech{protected}.}]}


@defproc[(syntax-local-value/immediate [id-stx syntax?]
                                       [failure-thunk (or/c (-> any) #f)
                                                      #f]
                                       [intdef-ctx (or/c internal-definition-context?
                                                         #f
                                                         (listof internal-definition-context?))
                                        #f])
         any]{

类似于 @racket[syntax-local-value]，但结果通常是两个值。如果 @racket[id-stx] 绑定到一个 @tech{重命名变换器}，
则结果是该重命名变换器和变换器中的标识符。 @margin-note*{请注意，对绑定到 @tech{重命名变换器} 的 @racket[_id] 执行 @racket[provide] 可能会导出重命名的目标而非 @racket[_id]。
更多信息请参见 @racket[make-rename-transformer]。} If
@racket[id-stx] is not bound to a @tech{rename transformer}, then the
results are the value that @racket[syntax-local-value] would produce
and @racket[#f].

如果 @racket[id-stx] 没有变换器绑定，则调用 @racket[failure-thunk]（它可以返回任意数量的值），
或者如果 @racket[failure-thunk] 是 @racket[#f]，则引发异常。

@examples[#:eval (make-base-eval '(require (for-syntax racket/base syntax/parse)))
          #:escape unsyntax-splicing
  (define-syntax agent-007 (make-rename-transformer #'james-bond))
  (define-syntax (show-secret-identity stx)
    (syntax-parse stx
      [(_ name:id)
       (define-values [_ orig-name] (syntax-local-value/immediate #'name))
       #`'(name #,orig-name)]))
  (show-secret-identity agent-007)]

@provided-as-protected[]

@history[#:changed "8.2.0.4" @elem{Changed binding to @tech{protected}.}]}


@defproc[(syntax-local-lift-expression [stx syntax?])
         identifier?]{

返回一个新的标识符，并与 @racket[module]、@racket[letrec-syntaxes+values]、@racket[define-syntaxes]、
@racket[begin-for-syntax] 和顶层展开器协作，将生成的标识符绑定到表达式 @racket[stx]。

模块内的运行时表达式提升到模块顶层，位于请求提升的表达式之前。类似地，模块外的运行时表达式提升为顶层定义。
@racket[letrec-syntaxes+values] 或 @racket[define-syntaxes] 绑定中的编译时表达式提升为相应绑定右侧的 @racket[let] 包装。
@racket[begin-for-syntax] 内的编译时表达式提升为 @racket[define] 声明，位于请求表达式之前。

其他语法形式可以通过使用 @racket[local-expand/capture-lifts] 或 @racket[local-transformer-expand/capture-lifts] 来捕获提升。

@transform-time[] In addition, this procedure can be called only when
a lift target is available, as indicated by
@racket[syntax-transforming-with-lifts?].}

@defproc[(syntax-local-lift-values-expression [n exact-nonnegative-integer?] [stx syntax?])
         (listof identifier?)]{

类似于 @racket[syntax-local-lift-expression]，但将结果绑定到 @racket[n] 个标识符，并返回这 @racket[n] 个标识符的列表。

@transform-time[]}


@defproc[(syntax-local-lift-context)
         any/c]{

返回一个表示通过 @racket[syntax-local-lift-expression] 提升的表达式目标的值。也就是说，
对于此过程返回相同值（由 @racket[eq?] 确定）的不同变换器调用，两个变换器的提升表达式会被移到相同的位置。
因此，该结果对于缓存提升信息以避免冗余提升很有用。

@transform-time[]}


@defproc[(syntax-local-lift-module [stx syntax?])
         void?]{

与 @racket[module] 形式或顶层展开协作，将 @racket[stx] 作为模块声明添加到外围模块或顶层。
@racket[stx] 形式必须以 @racket[module] 或 @racket[module*] 开头，其中后者仅在模块展开内允许。

当 @racket[syntax-local-lift-module] 返回时，模块并不会立即声明。相反，模块声明被记录下来，
当展开返回到外围模块体或顶层序列时再进行处理。

@transform-time[] 如果当前正在变换的表达式不在 @racket[module] 形式内或顶层展开内，则 @exnraise[exn:fail:contract]。
如果 @racket[stx] 形式不以 @racket[module] 或 @racket[module*] 开头，或者如果在顶层上下文中以 @racket[module*] 开头，
则 @exnraise[exn:fail:contract]。

@history[#:added "6.3"]}


@defproc[(syntax-local-lift-module-end-declaration [stx syntax?])
         void?]{

与 @racket[module] 形式协作，将 @racket[stx] 作为顶层声明插入到当前正在展开的模块末尾。 如果当前正在变换的表达式处于 @tech{阶段级别} 0 且不在模块顶层中，则 @racket[stx] 最终在表达式上下文中展开。
如果当前正在变换的表达式处于更高的 @tech{阶段级别}（即嵌套在模块顶层的若干 @racket[begin-for-syntax]es 内），
则提升的声明被放置在模块的最末尾（在适当数量的 @racket[begin-for-syntax]es 之下），而不仅仅是在外围 @racket[begin-for-syntax] 的末尾。

@transform-time[] 如果当前正在变换的表达式不在 @racket[module] 形式内（参见 @racket[syntax-transforming-module-expression?]），
则 @exnraise[exn:fail:contract]。}


@defproc[(syntax-local-lift-require [raw-require-spec any/c] [stx syntax?] [new-scope? any/c #t])
         syntax?]{

将对应于 @racket[raw-require-spec]（作为 @tech{语法对象} 或数据）的 @racket[#%require] 形式提升到
顶层或当前正在展开的模块的顶部，或者提升到外围 @racket[begin-for-syntax] 中。

生成的语法对象与 @racket[stx] 相同，不同之处在于如果 @racket[new-scope?] 为真则添加一个新的 @tech{作用域}。
相同的 @tech{作用域} 被添加到提升的 @racket[#%require] 形式中，以便 @racket[#%require] 形式可以绑定结果语法对象中导入标识符的使用
（假设 @racket[stx] 的词法信息包含了 @racket[#%require] 被提升到的绑定环境）。
如果 @racket[new-scope?] 是 @racket[#f]，则结果恰好是 @racket[stx]，并且不会向提升的 @racket[#%require] 形式添加作用域；
在这种情况下，请注意确保提升的 require 不会改变模块中已展开标识符的含义，否则外围模块的重新展开将不会产生与已展开模块相同的结果。

如果 @racket[raw-require-spec] 是变换器输入的一部分，则通常应在传递给 @racket[syntax-local-lift-require] 之前应用 @racket[syntax-local-introduce]。
否则，宏展开器添加的标记可能会阻止访问新的导入。

@transform-time[]

@history[#:changed "6.90.0.27" @elem{Changed the @tech{scope} added to inputs from a
                                     macro-introduction scope to one that does not affect whether or
                                     not the resulting syntax is considered original as reported by
                                     @racket[syntax-original?].}
         #:changed "8.6.0.4" @elem{Added the @racket[new-scope?] optional argument.}]}

@defproc[(syntax-local-lift-provide [raw-provide-spec-stx syntax?])
         void?]{

将对应于 @racket[raw-provide-spec-stx] 的 @racket[#%provide] 形式提升到
当前正在展开的模块的顶部，或者提升到外围 @racket[begin-for-syntax] 中。

@transform-time[] 如果当前正在变换的表达式不在 @racket[module] 形式内（参见 @racket[syntax-transforming-module-expression?]），
则 @exnraise[exn:fail:contract]。}

@defproc[(syntax-local-name) any/c]{

返回正在变换的表达式位置的推断名称，如果没有此类名称，则返回 @racket[#f]。名称通常是符号或标识符。另请参见 @secref["infernames"]。

@transform-time[]}


@defproc[(syntax-local-context)
         (or/c 'expression 'top-level 'module 'module-begin list?)]{

返回触发 @tech{语法变换器} 调用的展开上下文的指示。有关上下文的更多信息，请参见 @secref["expand-context-model"]。

符号结果表示表达式正在针对 @tech{表达式上下文}、@tech{顶层上下文}、@tech{模块上下文} 或 @tech{模块开始上下文} 展开。

列表结果表示在 @tech{内部定义上下文} 中展开。列表第一个元素的标识（即其 @racket[eq?] 性）反映了内部定义上下文的标识；
特别地，当且仅当针对相同的 @tech{内部定义上下文} 调用两个变换器展开时，它们才会收到相同的第一个值。
列表中后续值类似地标识仍在展开且需要展开嵌套内部定义上下文的 @tech{内部定义上下文}。

@transform-time[]}


@defproc[(syntax-local-phase-level) exact-integer?]{

在展开器应用 @tech{语法变换器} 的动态范围内，结果是正在展开的形式的 @tech{阶段级别}。否则，结果是 @racket[0]。

@examples[#:eval stx-eval
  (code:comment "a macro bound at phase 0")
  (define-syntax (print-phase-level stx)
    (printf "phase level: ~a~n" (syntax-local-phase-level))
    #'(void))
  (require (for-meta 2 racket/base))
  (begin-for-syntax
    (code:comment "a macro bound at phase 1")
    (define-syntax (print-phase-level stx)
      (printf "phase level: ~a~n" (syntax-local-phase-level))
      #'(void)))
  (print-phase-level)
  (begin-for-syntax (print-phase-level))
]
}


@defproc[(syntax-local-module-exports [mod-path (or/c module-path?
                                                      (syntax/c module-path?))])
         (listof (cons/c phase+space? (listof symbol?)))]{

返回一个从 @tech{阶段级别} 和 @tech{绑定空间} 组合到符号列表的关联列表，
其中符号是在相应的 @tech{阶段级别} 上从 @racket[mod-path] 中 @racket[provide]d 的绑定名称。

@transform-time[]

@history[#:changed "8.2.0.3" @elem{Generalized result to phase--space combinations.}]}


@defproc[(syntax-local-submodules) (listof symbol?)]{

返回当前展开上下文中通过 @racket[module]（而非 @racket[module*]）声明的子模块名称列表。

@transform-time[]}


@defproc[(syntax-local-module-interned-scope-symbols)
         (listof symbol?)]{

返回一个不同的 @tech{interned} 符号列表，这些符号对应于目前为止在当前展开上下文的模块或顶层命名空间中用于绑定的 @tech{绑定空间}。
结果在某种意义上是保守的，即它可能包含当前模块或命名空间中尚未使用的额外符号。

当前实现返回所有 @tech{可达} 的内部作用域的所有符号，但该行为将来可能会改变为返回不那么保守的符号列表。

@transform-time[]

@history[#:added "8.2.0.7"]}

@defproc[(syntax-local-get-shadower [id-stx identifier?]
                                    [only-generated? any/c #f])
         identifier?]{

向 @racket[id-stx] 添加 @tech{作用域}，使其引用当前展开上下文中的绑定，
或者可以绑定在更深嵌套上下文中通过 @racket[(syntax-local-get-shadower id-stx)] 获取的任何标识符。
如果 @racket[only-generated?] 为真，则外围模块或命名空间的跨阶段 @tech{作用域} 会从添加的作用域中省略，
但这限制了可以引用的绑定（因此避免了某些歧义引用）。

此函数旨在用于 @racket[syntax-parameterize] 和 @racket[local-require] 的实现。

@transform-time[]

@history[#:changed "6.3" @elem{Simplified to the minimal functionality
                               needed for @racket[syntax-parameterize]
                               and @racket[local-require].}]}


@defproc[(syntax-local-make-delta-introducer [id-stx identifier?]) procedure?]{

仅为（有限的）向后兼容而提供；引发 @racket[exn:fail:unsupported]。

@history[#:changed "6.3" @elem{changed to raise @racket[exn:fail:supported].}]}



@defproc[(syntax-local-certifier [active? boolean? #f])
         ((syntax?) (any/c (or/c procedure? #f))
          . ->* . syntax?)]{

仅为向后兼容而提供；返回一个返回其第一个参数的过程。}

@defproc[(syntax-transforming?) boolean?]{

在展开器应用 @tech{语法变换器} 的动态范围内以及在模块被 @tech{visit} 期间返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(syntax-transforming-with-lifts?) boolean?]{

如果 @racket[(syntax-transforming?)] 产生 @racket[#t] 且存在用于提升表达式（通过 @racket[syntax-local-lift-expression]）的目标上下文，则返回 @racket[#t]，否则返回 @racket[#f]。

目前，@racket[(syntax-transforming?)] 蕴含 @racket[(syntax-transforming-with-lifts?)]。

@history[#:added "6.3.0.9"]}


@defproc[(syntax-transforming-module-expression?) boolean?]{

在展开器对 @racket[module] 形式内的表达式应用 @tech{语法变换器} 的动态范围内返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(syntax-local-compiling-module?) boolean?]{

在展开器在 @tech{module-begin context} 中应用 @tech{语法变换器} 的动态范围内，
且展开是可返回编译模块的编译过程的一部分时，返回 @racket[#t]。另请参见 @racket[module]。

@history[#:added "8.13.0.7"]}


@defproc[(syntax-local-identifier-as-binding [id-stx identifier?]
                                             [intdef-ctx (or/c internal-definition-context? #f) #f])
         identifier?]{

返回类似 @racket[id-stx] 的标识符，但移除了之前作为宏展开的一部分添加到标识符的 @tech{使用点作用域}。
当 @racket[intdef-ctx] 是一个内部定义上下文时，该函数移除了在该上下文中展开期间创建的使用点作用域。
当它为 @racket[#f]（默认值）时，它移除了在当前展开上下文中展开期间创建的使用点作用域。

在非表达式上下文中运行并强制使用 @racket[local-expand] 展开子形式的 @tech{语法变换器} 中，
在将来自展开的标识符移动到绑定位置或与 @racket[bound-identifier=?] 比较之前，
使用 @racket[syntax-local-identifier-as-binding] 处理该标识符。否则，结果可能与 @racket[define] 在同一
定义上下文中的工作方式不一致。

@transform-time[]

@history[#:added "6.3"
         #:changed "8.2.0.7" @elem{Added the optional
                               @racket[intdef-ctx] argument.}]}

@defproc[(syntax-local-introduce [stx syntax?]) syntax?]{

生成一个类似 @racket[stx] 的语法对象，不同之处在于当前展开的 @tech{作用域}——@tech{宏引入作用域} 和 @tech{使用点作用域}（如果有）——在语法对象的所有部分上被翻转。
有关宏引入和使用点 @tech{作用域} 的信息，请参见 @secref["transformer-model"]。

@transform-time[]

@examples[#:eval (make-base-eval)
  (module example racket
    (define-syntax (require-math stx)
      (syntax-local-introduce #'(require racket/math)))
    (require-math)
    pi)]}


@defproc[(make-syntax-introducer [as-use-site? any/c #f])
         ((syntax?) ((or/c 'flip 'add 'remove)) . ->* . syntax?)]{

生成一个封装了新的 @tech{作用域} 的过程，并在给定的语法对象中翻转、添加或移除它。默认情况下，
新的作用域是 @tech{宏引入作用域}，但为 @racket[as-use-site?] 提供真值会创建一个类似于 @tech{使用点作用域} 的作用域；
区别在于 @racket[syntax-original?] 如何处理这些作用域。

生成的过程的操作可以是 @racket['flip]（默认值），用于翻转给定语法对象各部分中作用域的存在性；
@racket['add] 用于将作用域添加到每个部分，无论其是否已存在；
或 @racket['remove] 用于在当前任何部分中存在作用域时将其移除。

多次应用相同的 @racket[make-syntax-introducer] 结果过程使用相同的作用域，不同的结果过程使用不同的作用域。

@history[#:changed "6.3" @elem{Added the optional
                               @racket[as-use-site?] argument, and
                               added the optional operation argument
                               in the result procedure.}]}

@defproc[(make-interned-syntax-introducer [key (and/c symbol? symbol-interned?)])
         ((syntax?) ((or/c 'flip 'add 'remove)) . ->* . syntax?)]{

类似于 @racket[make-syntax-introducer]，但封装在其中的 @tech{作用域} 是一个 @deftech{interned scope}。
使用相同 @racket[key] 多次调用 @racket[make-interned-syntax-introducer] 会产生翻转、添加或移除相同作用域的过程，
即使是跨 @tech{phases} 和模块 @tech{instantiations}。此外，该作用域即使嵌入在 @tech{compiled} 代码中也保持一致，
因此使用 @racket[make-interned-syntax-introducer] 创建的作用域在从编译代码加载的语法对象中会保持其标识。
（在这个意义上，@racket[make-syntax-introducer] 和 @racket[make-interned-syntax-introducer] 之间的关系类似于
@racket[gensym] 和 @racket[quote] 之间的关系。）

此函数旨在用于在单个阶段内实现独立的 @tech{binding spaces}，为此每个环境关联的作用域必须在模块之间相同。

与 @racket[make-syntax-introducer] 不同，由 @racket[make-interned-syntax-introducer] 创建的过程所添加的作用域
始终被视为 @tech{use-site scope} 而不是 @tech{macro-introduction scope}，因此它不会影响 @racket[syntax-original?] 报告的原始性。

@history[#:added "6.90.0.28"
         #:changed "8.2.0.4" @elem{Added the constraint that @racket[key] is @tech{interned}.}]}

@defproc[(make-syntax-delta-introducer [ext-stx identifier?]
                                       [base-stx (or/c syntax? #f)]
                                       [phase-level (or/c #f exact-integer?)
                                                    (syntax-local-phase-level)])
         ((syntax?) ((or/c 'flip 'add 'remove)) . ->* . syntax?)]{

生成一个行为类似于 @racket[make-syntax-introducer] 的结果的过程，但使用来自 @racket[ext-stx] 的一组 @tech{作用域}，且默认操作为 @racket['add]。

@itemlist[

 @item{If the scopes of @racket[base-stx] are a subset of the scopes
       of @racket[ext-stx], then the result of
       @racket[make-syntax-delta-introducer] adds, removes, or flips
       scopes that are in the set for @racket[ext-stx] and not in the
       set for @racket[base-stx].}

 @item{If the scopes of @racket[base-stx] are not a subset of the
       scopes of @racket[ext-stx], but if it has a binding, then the
       set of scopes associated with the binding id subtracted from
       the set of scopes for @racket[ext-stx], and the result of
       @racket[make-syntax-delta-introducer] adds, removes, or flips
       that difference.}

]

@racket[base-stx] 的 @racket[#f] 值等同于没有 @tech{作用域} 的语法对象。

此过程在某些情况下可能有用：当某个 @racket[_m-id] 具有记录某个 @racket[_orig-id] 的变换器绑定，
且使用 @racket[_m-id] 会引入一个 @racket[_orig-id] 的绑定。在这种情况下，自 @racket[_m-id] 绑定以来添加到 @racket[_m-id] 使用上的 @tech{作用域}
应转移到 @racket[_orig-id] 的绑定实例上，以便它捕获与 @racket[_m-id] 使用具有相同词法上下文的用法。

如果 @racket[ext-stx] 是 @tech{tainted}，则从创建的过程返回的标识符结果是 @tech{tainted}。}


@defproc[(syntax-local-transforming-module-provides?) boolean?]{

当 @tech{provide transformer} 正在运行时返回 @racket[#t]（参见 @racket[make-provide-transformer]），
或者当 @racket[#%provide] 的 @racketidfont{expand} 子形式正在展开时返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(syntax-local-module-defined-identifiers) (and/c hash? immutable?)]{

只能在 @racket[syntax-local-transforming-module-provides?] 返回 @racket[#t] 时调用。

它返回一个哈希表，将 @tech{phase-level} 数字（如 @racket[0]）映射到正在展开的模块内该 @tech{phase level} 上所有定义的列表。
此信息用于实现 @racket[provide] 子形式，如 @racket[all-defined-out]。

请注意，@tech{phase-level} 键是相对于外围模块的绝对级别，而不是相对于 @racket[syntax-local-phase-level] 报告的当前变换器阶段级别。}


@defproc[(syntax-local-module-required-identifiers
          [mod-path (or/c module-path? #f)]
          [shift (or/c #t phase+space-shift?)])
         (or/c (listof (cons/c phase+space?
                               (listof identifier?)))
               #f)]{

只能在 @racket[syntax-local-transforming-module-provides?] 返回 @racket[#t] 时调用。

它返回一个关联列表，将 @tech{phase level} 和 @tech{binding space} 组合映射到标识符列表。
每个标识符列表包括使用模块路径 @racket[mod-path] 导入（到正在展开的模块）的所有绑定，
如果 @racket[mod-path] 是 @racket[#f]，则包括所有模块。关联列表包括以 @racket[shift] 表示的阶段级别和绑定空间偏移导入的所有标识符，
如果 @racket[shift] 是 @racket[#t]，则包括所有偏移。如果 @racket[shift] 不是 @racket[#t]，
且在该偏移下没有导入标识符，则结果可以是 @racket[#f]。

当标识符在导入时被重命名时，结果关联列表通过其内部名称包含该标识符。
使用 @racket[identifier-binding] 获取有关该标识符的更多信息。

请注意，@tech{phase-level} 偏移是相对于外围模块的绝对级别，而不是相对于 @racket[syntax-local-phase-level] 报告的当前变换器阶段级别。

@history[#:changed "8.2.0.3" @elem{Generalized @racket[shift] and result
                                   to phase--space combinations.}]}

@deftogether[(
@defthing[prop:liberal-define-context struct-type-property?]
@defproc[(liberal-define-context? [v any/c]) boolean?]
)]{

一个具有 @racket[prop:liberal-define-context] 属性真值的结构类型实例可以用作 @racket[syntax-local-context] 结果或 @racket[local-expand] 的第二个参数中
@tech{internal-definition context} 表示的元素。
此值表示该上下文支持 @deftech{liberal expansion}，即将 @racket[define] 形式展开为可能多个 @racket[define-values]
和 @racket[define-syntaxes] 形式。@racket['module] 和 @racket['module-body] 上下文隐式允许 @tech{liberal expansion}。

@racket[liberal-define-context?] 谓词在 @racket[v] 是 @racket[prop:liberal-define-context] 属性为真值的结构实例时返回 @racket[#t]，否则返回 @racket[#f]。}

@; ----------------------------------------------------------------------

@section[#:tag "require-trans"]{@racket[require] 变换器}

@note-lib-only[racket/require-transform]

一个 @tech{transformer} 绑定，如果其值是一个具有 @racket[prop:require-transformer] 属性的结构，则实现了 @racket[require] 的派生 @racket[_require-spec]，
作为一个 @deftech{require transformer}。

@tech{require transformer} 会接收到一个表示其在 @racket[require] 形式中作为 @racket[_require-spec] 的用法的语法对象，
结果必须是两个列表：一个 @racket[import] 列表和一个 @racket[import-source] 列表。

如果派生形式包含一个子形式是 @racket[_require-spec]，则可以调用 @racket[expand-import] 将该子 @racket[_require-spec] 转换
为 import 和 import-source 列表。

另请参见 @racket[define-require-syntax]，它支持宏风格的 @racket[require] 变换器。

@defproc[(expand-import [require-spec syntax?])
         (values (listof import?)
                 (listof import-source?))]{

将给定的 @racket[_require-spec] 展开为 import 和 import-source 列表。后者指定要 @tech{instantiate} 或 @tech{visit} 的模块，
因此它所代表的模块应是前一个列表所代表的模块的超集（这样即使所有 import 最终都从前一个列表中被过滤掉，
模块仍会被 @tech{instantiate} 或 @tech{visit}）。}


@defproc[(make-require-transformer [proc (syntax? . -> . (values
                                                          (listof import?)
                                                          (listof import-source?)))])
         require-transformer?]{

使用给定的过程作为变换器创建一个 @tech{require transformer}。
通常与 @racket[expand-import] 结合使用。

@examples[
#:eval stx-eval
(require (for-syntax racket/require-transform))

(define-syntax printing
  (make-require-transformer
   (lambda (stx)
     (syntax-case stx ()
       [(_ path)
        (begin
          (printf "Importing: ~a~n" #'path)
          (expand-import #'path))]))))

(require (printing racket/match))
]}


@defthing[prop:require-transformer struct-type-property?]{

用于标识 @tech{require transformers} 的属性。属性值必须是一个过程，该过程接受结构并返回一个变换器过程；
返回的变换器过程接受一个语法对象并返回 import 和 import-source 列表。}


@defproc[(require-transformer? [v any/c]) boolean?]{

如果 @racket[v] 具有 @racket[prop:require-transformer] 属性，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defstruct[import ([local-id identifier?]
                   [src-sym symbol?]
                   [src-mod-path (or/c module-path?
                                       (syntax/c module-path?))]
                   [mode phase+space?]
                   [req-mode phase+space-shift?]
                   [orig-mode phase+space?]
                   [orig-stx syntax?])]{

表示单个导入标识符的结构：

@itemize[

 @item{@racket[local-id] --- the identifier to be bound within the
       importing module, but @emph{without} any space-specific scope
       implied by @racket[mode].}

 @item{@racket[src-sym] --- the external name of the binding as
       exported from its source module.}

 @item{@racket[src-mod-path] --- a @tech{module path} (relative to the
       importing module) for the source of the imported binding.}

 @item{@racket[mode] --- the @tech{phase level} and @tech{binding
       space} of the binding in the importing module, which must be the
       same as @racket[(phase+space+ orig-mode req-mode)].}

 @item{@racket[req-mode] --- the @tech{phase level} shift and
       @tech{binding space} shift of the import relative to the
       exporting module.}

 @item{@racket[orig-mode] --- the @tech{phase level} and @tech{binding
       space} of the binding as exported by the exporting module.}

 @item{@racket[orig-stx] --- a @tech{syntax object} for the source of
       the import, used for error reporting.}

]

@history[#:changed "8.2.0.3" @elem{Generalized modes to phase--space combinations.}]}


@defstruct[import-source ([mod-path-stx (syntax/c module-path?)]
                          [mode phase+space-shift?])]{

表示导入模块的结构，即使没有绑定导入到模块中，也必须对其进行 @tech{instantiate} 或 @tech{visit}。

@itemize[

 @item{@racket[mod-path-stx] --- a @tech{module path} (relative
       to the importing module) for the source of the imported binding.}

 @item{@racket[mode] --- the @tech{phase level} shift and
       @tech{binding space} shift of the import.}

]

@history[#:changed "8.2.0.3" @elem{Generalized @racket[mode] to phase--space combinations.}]}


@defparam[current-require-module-path module-path (or/c #f module-path-index?)]{

一个 @tech{parameter}，决定了 @racket[convert-relative-module-path] 如何将相对 @racket[require] 级模块路径展开为 @racket[#%require] 级模块路径
（所有内置 @racket[require] 子形式均隐式使用 @racket[convert-relative-module-path]）。

当 @racket[current-require-module-path] 的值是 @racket[#f] 时，相对模块路径保持原样，这意味着 @racket[require] 上下文决定模块路径的解析。

@racket[require] 形式在调用子形式变换器时将 @racket[current-require-module-path] 以 @racket[parameterize] 设置为 @racket[#f]，
而 @racket[relative-in] 则以 @racket[parameterize] 设置为给定的模块路径。}


@defproc[(convert-relative-module-path [module-path
                                        (or/c module-path?
                                              (syntax/c module-path?))])
          (or/c module-path?
                (syntax/c module-path?))]{

根据 @racket[current-require-module-path] 转换 @racket[module-path]。

如果 @racket[module-path] 不是相对路径，或者 @racket[current-require-module-path] 的值是 @racket[#f]，
则返回 @racket[module-path]。否则，@racket[module-path] 被转换为一个绝对模块路径，该路径等价于
相对于 @racket[current-require-module-path] 的值的 @racket[module-path]。}

@defproc[(syntax-local-lift-require-top-level-form [top-level-stx syntax?])
         void?]{
 将 @racket[top-level-stx] 提升到外围模块的顶层，紧跟在正在展开的 @racket[require] 之后。

 @transform-time[] 此外，此过程只能在展开 @tech{require transformer} 时调用。

 @history[#:added "8.12.0.13"]
}

@defproc[(syntax-local-require-certifier)
         ((syntax?) (or/c #f (syntax? . -> . syntax?))
          . ->* . syntax?)]{

仅为向后兼容而提供；返回一个返回其第一个参数的过程。}

@; ----------------------------------------------------------------------

@section[#:tag "provide-trans"]{@racket[provide] 变换器}

@note-lib-only[racket/provide-transform]

一个 @tech{transformer} 绑定，如果其值是一个具有 @racket[prop:provide-transformer] 属性的结构，则实现了 @racket[provide] 的派生 @racket[_provide-spec]，
作为一个 @deftech{provide transformer}。@tech{provide transformer} 作为模块展开的最后阶段的一部分被应用，
在模块内所有其他声明和表达式展开之后。

一个 @tech{transformer} 绑定，如果其值是一个具有 @racket[prop:provide-pre-transformer] 属性的结构，则实现了 @racket[provide] 的派生 @racket[_provide-spec]，
作为一个 @deftech{provide pre-transformer}。@tech{provide pre-transformer} 作为模块展开的第一阶段的一部分被应用。
由于它在第一阶段使用，@tech{provide pre-transformer} 可以使用 @racket[syntax-local-lift-expression] 等函数在外围模块中引入表达式和定义。

一个标识符可以有一个 @tech{transformer} 绑定到一个同时充当 @tech{provide transformer} 和 @tech{provide pre-transformer} 的值。
@tech{provide pre-transformer} 的结果 @emph{不} 会自动重新展开，因此在这种情况下，@tech{provide pre-transformer} 可以有用地展开为自身。

变换器会接收到表示其在 @racket[provide] 形式中作为 @racket[_provide-spec] 的用法的语法对象，
以及一个表示外围 @racket[_provide-spec] 所指定的导出模式的符号列表。
@tech{provide transformer} 的结果必须是 @racket[export] 列表，
而 @tech{provide pre-transformer} 的结果是一个将在模块展开的最后阶段用作 @racket[_provide-spec] 的语法对象。

如果派生形式包含一个子形式是 @racket[_provide-spec]，则可以调用 @racket[expand-export] 或 @racket[pre-expand-export] 来转换该子 @racket[_provide-spec] 子形式。

另请参见 @racket[define-provide-syntax]，它支持宏风格的 @tech{provide transformers}。


@defproc[(expand-export [provide-spec syntax?] [modes (listof phase+space?)])
         (listof export?)]{

将给定的 @racket[_provide-spec] 展开为导出列表。@racket[modes] 列表控制子 @racket[_provide-specs] 的展开；
例如，一个标识符引用外围 @racket[provide] 形式的 @tech{phase level} 中的绑定，除非 @racket[modes] 列表另有指定。
通常，@racket[modes] 为空或包含单个元素。

@history[#:changed "8.2.0.3" @elem{Generalized @racket[modes] to phase--space combinations.}]}


@defproc[(pre-expand-export [provide-spec syntax?] [modes (listof phase+space?)])
         syntax?]{

在 @tech{provide pre-transformers} 的级别上展开给定的 @racket[_provide-spec]。@racket[modes] 参数与 @racket[expand-export] 的相同。

@history[#:changed "8.2.0.3" @elem{Generalized @racket[modes] to phase--space combinations.}]}


@defproc*[([(make-provide-transformer [proc (syntax? (listof phase+space?)
                                             . -> . (listof export?))])
            provide-transformer?]
           [(make-provide-transformer [proc (syntax? (listof phase+space?)
                                             . -> . (listof export?))]
                                      [pre-proc (syntax? (listof phase+space?)
                                                 . -> . syntax?)])
            (and/c provide-transformer? provide-pre-transformer?)])]{

使用给定的过程作为变换器创建一个 @tech{provide transformer}（即具有 @racket[prop:provide-transformer] 属性的结构）。
如果提供了 @racket[pre-proc]，则结果也是一个 @tech{provide pre-transformer}。
通常与 @racket[expand-export] 和/或 @racket[pre-expand-export] 结合使用。}


@defproc[(make-provide-pre-transformer [pre-proc (syntax? (listof phase+space?)
                                                  . -> . syntax?)])
         provide-pre-transformer?]{

类似于 @racket[make-provide-transformer]，但仅用于 @tech{provide pre-transformer} 的值。
通常与 @racket[pre-expand-export] 结合使用。

@examples[
#:eval stx-eval
(module m racket
  (require
    (for-syntax racket/provide-transform syntax/parse syntax/stx))

  (define-syntax wrapped-out
    (make-provide-pre-transformer
     (lambda (stx modes)
       (syntax-parse stx
         [(_ f ...)
          #:with (wrapped-f ...)
                 (stx-map
                  syntax-local-lift-expression
                  #'((lambda args
                       (printf "applying ~a, args: ~a\n" 'f args)
                       (apply f args)) ...))
          (pre-expand-export
           #'(rename-out [wrapped-f f] ...) modes)]))))

  (provide (wrapped-out + -)))
(require 'm)
(- 1 (+ 2 3))
]}


@defthing[prop:provide-transformer struct-type-property?]{

用于标识 @tech{provide transformers} 的属性。属性值必须是一个过程，该过程接受结构并返回一个变换器过程；
返回的变换器过程接受一个语法对象和模式列表，并返回一个导出列表。}


@defthing[prop:provide-pre-transformer struct-type-property?]{

用于标识 @tech{provide pre-transformers} 的属性。属性值必须是一个过程，该过程接受结构并返回一个变换器过程；
返回的变换器过程接受一个语法对象和模式列表，并返回一个语法对象。}


@defproc[(provide-transformer? [v any/c]) boolean?]{

如果 @racket[v] 具有 @racket[prop:provide-transformer] 属性，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(provide-pre-transformer? [v any/c]) boolean?]{

如果 @racket[v] 具有 @racket[prop:provide-pre-transformer] 属性，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defstruct[export ([local-id identifier?]
                   [out-id identifier?]
                   [mode phase+space?]
                   [protect? any/c]
                   [orig-stx syntax?])]{

表示单个导出标识符的结构：

@itemize[

 @item{@racket[local-id] --- the identifier that is bound within the
       exporting module.}

 @item{@racket[out-id] --- 绑定的外部名称。}

 @item{@racket[mode] --- the @tech{phase level} and @tech{binding
       space} of the export (which affects how it is imported).}

 @item{@racket[protect?] --- indicates whether the identifier should
       be protected (see @secref["modprotect"]).}

 @item{@racket[orig-stx] --- a @tech{syntax object} for the source of
       the export, used for error reporting.}

]

@history[#:changed "8.2.0.3" @elem{Generalized @racket[mode] to phase--space combinations.}]

@history[#:changed "8.9.0.5" @elem{Changed the @racket[out-sym] field
        to @racket[out-id]. For backward compatibility, the
        @racket[make-export] constructor also accepts a symbol, and a
        @racket[export-out-sym] function returns the @racket[syntax-e]
        value of the @racket[out-id].}]

}

@defproc[(export-out-sym [ex export?]) symbol?]{

将 @racket[syntax-e] 与 @racket[export-out-id] 组合。

此函数旨在向后兼容。请直接使用 @racket[export-out-id]。

@history[#:added "8.9.0.5"]
}

@defproc[(syntax-local-provide-certifier)
         ((syntax?) (or/c #f (syntax? . -> . syntax?))
          . ->* . syntax?)]{

仅为向后兼容而提供；返回一个返回其第一个参数的过程。}

@; ----------------------------------------------------------------------

@section[#:tag "keyword-trans"]{关键字参数转换内省}

@note-lib-only[racket/keyword-transform]

@deftogether[(
@defproc[(syntax-procedure-alias-property [stx syntax?])
         (or/c #f
               (letrec ([val? (recursive-contract
                               (or/c (cons/c identifier? identifier?)
                                     (cons/c val? val?)))])
                 val?))]
@defproc[(syntax-procedure-converted-arguments-property [stx syntax?])
         (or/c #f
               (letrec ([val? (recursive-contract
                               (or/c (cons/c identifier? identifier?)
                                     (cons/c val? val?)))])
                 val?))]
)]{

报告一个语法属性的值，该属性可以通过关键字应用形式的展开附加到标识符上。
有关该属性的更多信息，请参见 @racket[lambda]。

属性值通常是一个由原始标识符和出现在展开中的标识符组成的 pair。
通过 @racket[syntax-track-origin] 的属性值合并可以使该值成为这种值的 pair，依此类推。}


@; ----------------------------------------------------------------------

@section[#:tag "portal-syntax"]{入口语法绑定}

绑定到由 @racket[make-portal-syntax] 创建的 @deftech{portal syntax} 值的标识符不充当变换器，
但它封装了一个语法对象，即使不实例化外围模块也可以访问和检查该对象。
入口语法也可以使用 @racket[#%require] 的 @racketidfont{portal} 形式来绑定。

@defproc[(portal-syntax? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[make-portal-syntax] 创建的值，则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "8.3.0.8"]}

@defproc[(make-portal-syntax [stx syntax?])
         portal-syntax?]{

创建内容为 @racket[stx] 的 @tech{portal syntax}。

当 @racket[define-syntax] 或 @racket[define-syntaxes] 在模块体中直接将标识符绑定到入口语法时，
除了在展开时通过 @racket[syntax-local-value] 可访问外，还可以通过 @racket[identifier-binding-portal-syntax] 访问入口语法内容。

@history[#:added "8.3.0.8"]}

@defproc[(portal-syntax-content [portal portal-syntax?])
         syntax?]{

返回使用 @racket[make-portal-syntax] 创建的 @tech{portal syntax} 的内容。

@history[#:added "8.3.0.8"]}

@close-eval[stx-eval]
