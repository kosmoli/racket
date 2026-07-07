#lang scribble/doc
@(require "mz.rkt")

@(define-syntax op
  (syntax-rules ()
    [(_ (x ...)) (x ...)]
    [(_ id) @racket[id]]))
@(define-syntax-rule (operations i ...)
   (itemlist #:style 'compact @item{@op[i]} ...))

@title[#:tag "chaperones"]{Impersonators and Chaperones}

@deftech{impersonator} 是对某个值的包装器，该包装器会重定向该值的某些操作。impersonator 仅适用于 procedure、具有可用 accessor 或 mutator 的 @tech{structure}、@tech{structure type}、@tech{hash table}、@tech{vector}、@tech{box}、@tech{channel} 和 @tech{prompt tag}。
impersonator 与原始值之间是 @racket[equal?] 的关系，但不是 @racket[eq?] 的关系。

@deftech{chaperone} 是一种 impersonator，其对值的操作的细化仅限于副作用（特别是引发异常）或对操作提供或产生的值进行 chaperone。例如，vector chaperone 可以重定向 @racket[vector-ref]使其在访问的 vector 槽包含字符串时引发异常，或者可以使 @racket[vector-ref] 的结果成为访问的 vector 槽中值的 chaperoned 变体，但它不能重定向 @racket[vector-ref] 以产生与 vector 槽中值任意不同的值。

相比之下，非 @tech{chaperone} 的 @tech{impersonator} 可以细化操作以将一个值替换为任意其他值。impersonator 不能应用于 immutable 值，也不能细化对 @tech{structure type} 实例中 immutable 字段的访问，因为对操作的任意重定向等同于对 impersonated 值的 mutation。

请注意，以下每个操作都可以通过在操作的参数上的 impersonator 被重定向到任意 procedure——假设该操作对 impersonator 的创建者可用：

@operations[@t{a structure-field accessor}
            @t{a structure-field mutator}
            @t{a structure type property accessor}
            @t{application of a procedure}
            unbox set-box!
            vector-ref vector-set!
            hash-ref hash-set hash-set! hash-remove hash-remove!
            channel-get channel-put
            call-with-continuation-prompt
            abort-current-continuation]

派生操作（如打印值）可以通过 impersonator 被重定向，因为它们底层使用了 accessor 函数。相比之下，@racket[equal?]、@racket[equal-hash-code] 和 @racket[equal-secondary-hash-code] 操作可能会绕过 impersonator（但它们没有义务这样做）。

除了重定向作用于值的操作外，impersonator 还可以为 impersonated 值包含 @deftech{impersonator property}。@tech{impersonator property} 类似于 @tech{structure type property}，但它适用于 impersonator 而非 structure type 及其实例。


@defproc[(impersonator? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[impersonate-procedure] 或 @racket[impersonate-struct] 等 procedure 创建的 @tech{impersonator}，则返回 @racket[#t]，否则返回 @racket[#f]。

程序和库通常应避免使用 @racket[impersonator?]，将 impersonator 与非 impersonator 值同等对待。在极少数情况下，可能需要 @racket[impersonator?] 来防止 impersonator 将操作重定向到任意 procedure。

@racket[impersonator?] 的一个局限是它@emph{不}识别通过实例化具有 @racket[prop:impersonator-of] property 的 structure type 创建的 @tech{impersonator}。这一局限反映了这些 impersonator 无法将 structure 访问和 mutation 操作重定向到任意 procedure。}


@defproc[(chaperone? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{chaperone}，则返回 @racket[#t]，否则返回 @racket[#f]。

出于与应避免使用 @racket[impersonator?] 相同的原因，程序和库通常应避免使用 @racket[chaperone?]。@racket[chaperone?] 返回真值意味着 @racket[impersonator?] 也返回真值。}


@defproc[(impersonator-of? [v1 any/c] [v2 any/c]) boolean?]{

指示 @racket[v1] 是否可以被认为在模除 impersonator 后与 @racket[v2] 等价。

任何两个 @racket[eq?] 的值也是 @racket[impersonator-of?] 的。
对于不包含 impersonator 的值，如果 @racket[v1] 和 @racket[v2] 是 @racket[equal?] 的，则认为它们互为对方的 impersonator。

如果 @racket[v1] 或 @racket[v2] 中至少有一个是 impersonator：
@itemlist[
          @item{If @racket[v1] impersonates @racket[_v1*] then @racket[(impersonator-of? v1 v2)]
                   is @racket[#t] if and only if @racket[(impersonator-of? _v1* v2)] is @racket[#t].}
          @item{If @racket[v2] is a non-interposing impersonator that impersonates @racket[_v2*], i.e.,
                   all of its interposition procedures are @racket[#f], then @racket[(impersonator-of? v1 v2)]
                   is @racket[#t] if and only if @racket[(impersonator-of? v1 _v2*)] is @racket[#t].}
          @item{When @racket[v2] is an impersonator constructed with at least one non-@racket[#f] interposition procedure,
                     but @racket[v1] is not an impersonator then @racket[(impersonator-of? v1 v2)] is @racket[#f].}]}

否则，如果 @racket[_v1] 和 @racket[_v2] 都不是 impersonator，但它们中任何一个包含 impersonator 作为子部分（例如 @racket[_v1] 是一个列表，其中一个元素是 impersonator），则 @racket[(impersonator-of? _v1 _v2)] 通过递归比较 @racket[_v1] 和 @racket[_v2]（类似 @racket[equal?]），在所有子部分都是 @racket[impersonator-of?] 时返回真。

@examples[
(impersonator-of? (impersonate-procedure add1 (λ (x) x))
                  add1)
(impersonator-of? (impersonate-procedure add1 (λ (x) x))
                  sub1)
(impersonator-of? (impersonate-procedure
                    (impersonate-procedure add1 (λ (x) x)) (λ (x) x))
                  add1)
(impersonator-of? (impersonate-procedure add1 (λ (x) x))
                  (impersonate-procedure add1 #f))
(impersonator-of? (impersonate-procedure add1 (λ (x) x))
                  (impersonate-procedure add1 (λ (x) x)))
(impersonator-of? (list 1 2)
                  (list 1 2))
(impersonator-of? (list (impersonate-procedure add1 (λ (x) x)) sub1)
                  (list add1 sub1))
]

@defproc[(chaperone-of? [v1 any/c] [v2 any/c]) boolean?]{

指示 @racket[v1] 是否可以被认为在模除 chaperone 后与 @racket[v2] 等价。

对于不包含 chaperone 或其他 impersonator 的值，如果 @racket[v1] 和 @racket[v2] 是 @racket[equal-always?] 的，则可以认为它们互为对方的 chaperone。这要求它们是 @racket[equal?] 的，但 @racket[v1] 和 @racket[v2] 中对应的 mutable vector、box、hash table、string、byte string、@tech{mutable pair} 和 mutable structure 必须是 @racket[eq?] 的。

否则，@racket[v2] 中的 chaperone 和其他 impersonator 必须完整保留在 @racket[v1] 中，类似于 @racket[impersonator-of?] 要求保留 impersonator 的方式。此外，@racket[v1] 不得包含任何非 chaperone 的 impersonator，其在 @racket[v2] 中的对应值不是同一个 impersonator。请注意 @racket[chaperone-of?] 蕴含 @racket[impersonator-of?]，但反之不然。}


@defproc[(impersonator-ephemeron [v any/c]) ephemeron?]{

生成一个 @tech{ephemeron}，用于将 @racket[v] 的可达性（在垃圾回收的意义上；参见 @secref["gc-model"]）与 @racket[v] 是其 @tech{impersonator} 的任何值的可达性关联起来。也就是说，只要结果 ephemeron 以及 @racket[v] 所 impersonate 的任何值（包括自身）是可达的，值 @racket[v] 就被认为是可达的。

在 @tech{ephemeron} 的术语中，@racket[v] 是 ephemeron 的 value，而 @racket[v] 所 impersonate 的所有值都是 key。
}

@defproc[(procedure-impersonator*? [v any/c]) boolean?]{

对于由 @racket[impersonate-procedure*] 或 @racket[chaperone-procedure*] 产生的 procedure impersonator，或者是使用 @racket[impersonate-procedure*] 或 @racket[chaperone-procedure*] 创建的值的 impersonator/chaperone（可能通过传递性），返回 @racket[#t]。}

@; ------------------------------------------------------------
@section[#:tag "chaperones-s1"]{Impersonator Constructors}

@defproc[(impersonate-procedure [proc procedure?]
                                [wrapper-proc (or/c procedure? #f)]
                                [prop impersonator-property?]
                                [prop-val any/c] ... ...)
         (and/c procedure? impersonator?)]{

返回一个 impersonator procedure，其 arity、名称和其他属性与 @racket[proc] 相同。当 impersonator procedure 被应用时，参数首先传递给 @racket[wrapper-proc]（当它不是 @racket[#f] 时），然后 @racket[wrapper-proc] 的结果传递给 @racket[proc]。@racket[wrapper-proc] 还可以提供一个处理 @racket[proc] 结果的 procedure。

@racket[wrapper-proc] 的 arity 必须包含 @racket[proc] 的 arity。@racket[wrapper-proc] 的允许关键字参数必须是 @racket[proc] 允许关键字的超集。@racket[wrapper-proc] 的必需关键字参数必须是 @racket[proc] 必需关键字的子集。

对于不含关键字的应用，@racket[wrapper-proc] 的结果必须至少与提供给它的参数数量相同。可以按以下模式提供额外的结果——在对应于所提供值的值之前：

@itemlist[

 @item{An optional procedure, @racket[_result-wrapper-proc], which
       will be applied to the results of @racket[proc]; followed by}

 @item{any number of repetitions of @racket['mark _key _val] (i.e.,
       three values), where the call @racket[_proc] is wrapped to
       install a @tech{continuation mark} @racket[_key] and @racket[_val].}

]

如果提供了 @racket[_result-wrapper-proc]，它必须是一个 procedure，接受与 @racket[proc] 产生的结果数量相同的参数；它必须返回相同数量的结果。如果没有提供 @racket[_result-wrapper-proc]，则 @racket[proc] 在相对于 impersonator 调用的 @tech{tail position} 中被调用。

对于包含关键字参数的应用，@racket[wrapper-proc] 必须在其他值之前、但在 @racket[_result-wrapper-proc] 和 @racket['mark _key _val] 序列（如果有的话）之后，返回一个额外的值。该额外值必须是一个列表，其中包含提供给 impersonator 的关键字参数的替换值（即不计入未提供的可选参数）。参数必须按照所提供参数关键字的排序顺序排列。

如果 @racket[wrapper-proc] 为 @racket[#f]，则应用结果 impersonator 与应用 @racket[proc] 相同。如果 @racket[wrapper-proc] 为 @racket[#f] 且未提供 @racket[prop]，则返回 @racket[proc] 且不进行 impersonate。

@racket[prop] 和 @racket[prop-val] 的配对（传递给 @racket[impersonate-procedure] 的参数数量必须为偶数）添加 impersonator property 或覆盖 @racket[proc] 的 impersonator-property 值。

如果任何 @racket[prop] 是 @racket[impersonator-prop:application-mark]，且关联的 @racket[prop-val] 是一个 pair，则对 @racket[proc] 的调用被包装在 @racket[with-continuation-mark] 中，使用 @racket[(car prop-val)] 作为 mark key，@racket[(cdr prop-val)] 作为 mark value。此外，如果对 impersonated procedure 调用的直接 continuation 帧包含 @racket[(car prop-val)] 的值——即如果 @racket[call-with-immediate-continuation-mark] 会在调用的 continuation 中为 @racket[(car prop-val)] 产生一个值——则该值也会在调用 @racket[wrapper-proc] 期间作为 @racket[(car prop-val)] 的直接 mark 值安装（这使得可以在 @racket[wrapper-proc] 内检测到相对于包装 impersonator 的 impersonator 尾调用）。

@history[#:changed "6.3.0.5" @elem{Added support for @racket['mark
                                   _key _val] results from
                                   @racket[wrapper-proc].}]

 @examples[

 (define (add15 x) (+ x 15))
 (define add15+print
   (impersonate-procedure add15
                          (λ (x)
                            (printf "called with ~s\n" x)
                            (values (λ (res)
                                      (printf "returned ~s\n" res)
                                      res)
                                    x))))
 (add15 27)
 (add15+print 27)
           
 (define-values (imp-prop:p1 imp-prop:p1? imp-prop:p1-get)
   (make-impersonator-property 'imp-prop:p1))
 (define-values (imp-prop:p2 imp-prop:p2? imp-prop:p2-get)
   (make-impersonator-property 'imp-prop:p2))
  
 (define add15.2 (impersonate-procedure add15 #f imp-prop:p1 11))
 (add15.2 2)
 (imp-prop:p1? add15.2)
 (imp-prop:p1-get add15.2)
 (imp-prop:p2? add15.2)
 
 (define add15.3 (impersonate-procedure add15.2 #f imp-prop:p2 13))
 (add15.3 3)
 (imp-prop:p1? add15.3)
 (imp-prop:p1-get add15.3)
 (imp-prop:p2? add15.3)
 (imp-prop:p2-get add15.3)
 
 (define add15.4 (impersonate-procedure add15.3 #f imp-prop:p1 101))
 (add15.4 4)
 (imp-prop:p1? add15.4)
 (imp-prop:p1-get add15.4)
 (imp-prop:p2? add15.4)
 (imp-prop:p2-get add15.4)]
}

@defproc[(impersonate-procedure* [proc procedure?]
                                 [wrapper-proc (or/c procedure? #f)]
                                 [prop impersonator-property?]
                                 [prop-val any/c] ... ...)
         (and/c procedure? impersonator?)]{

类似于 @racket[impersonate-procedure]，区别在于 @racket[wrapper-proc] 在所有其他参数之前接收一个额外参数。该额外参数是最初被应用的 procedure @racket[_orig-proc]。

如果 @racket[impersonate-procedure*] 的结果被直接应用，则 @racket[_orig-proc] 就是该结果。然而，如果该结果在被应用之前被进一步 impersonate，则 @racket[_orig-proc] 是进一步的 impersonator。

@racket[_orig-proc] 参数可能有用，例如使 @racket[wrapper-proc] 能够提取被进一步 impersonator 覆盖的 @tech{impersonator property}。

@history[#:added "6.1.1.5"]}


@defproc[(impersonate-struct [v any/c]
                             [struct-type struct-type? _unspecified]
                             [orig-proc (or/c struct-accessor-procedure?
                                              struct-mutator-procedure?
                                              struct-type-property-accessor-procedure?)]
                             [redirect-proc (or/c procedure? #f)] ... ...
                             [prop impersonator-property?]
                             [prop-val any/c] ... ...)
          any/c]{

返回 @racket[v] 的 impersonator，它会重定向 impersonated 值上的某些操作。@racket[orig-proc] 指定要重定向的操作，相应的 @racket[redirect-proc] 提供重定向。可选的 @racket[struct-type] 参数（如果提供）作为 @racket[v] 表示的见证，@racket[v] 必须是 @racket[struct-type] 的实例。

@racket[redirect-proc] 的协议取决于相应的 @racket[orig-proc]，其中 @racket[_self] 表示 @racket[orig-proc] 最初应用于的值：

@itemlist[

 @item{A structure-field accessor: @racket[redirect-proc]
      must accept two arguments, @racket[_self] and the value
      @racket[_field-v] that @racket[orig-proc] produces for
      @racket[v]; it must return a replacement for
      @racket[_field-v]. The corresponding field must not be
      immutable, and either the field's structure type must be
      accessible via the current @tech{inspector} or one of the other
      @racket[orig-proc]s must be a structure-field mutator for the
      same field.}

 @item{A structure-field mutator: @racket[redirect-proc] must accept
      two arguments, @racket[_self] and the value @racket[_field-v]
      supplied to the mutator; it must return a replacement for
      @racket[_field-v] to be propagated to @racket[orig-proc] and
      @racket[v].}

 @item{A property accessor: @racket[redirect-proc] uses the same
       protocol as for a structure-field accessor. The accessor's
       property must have been created with @racket['can-impersonate]
       as the second argument to @racket[make-struct-type-property].}

]

当 @racket[redirect-proc] 为 @racket[#f] 时，相应的 @racket[orig-proc] 不受影响。为 @racket[redirect-proc] 提供 @racket[#f] 有助于让它的 @racket[orig-proc] 作为 @racket[v] 表示的"见证"并允许添加 @racket[prop]。

@racket[prop] 和 @racket[prop-val] 的配对（如果提供了 @racket[struct-type]，传递给 @racket[impersonate-struct] 的参数数量必须为偶数，否则为奇数）添加 impersonator property 或覆盖 @racket[v] 的 impersonator-property 值。

每个 @racket[orig-proc] 必须指示一个不同的操作。 If no
@racket[struct-type] and no @racket[orig-proc]s are supplied, then no @racket[prop]s must be
supplied. If @racket[orig-proc]s are supplied only with @racket[#f]
@racket[redirect-proc]s and no @racket[prop]s are supplied, then
@racket[v] is returned and is not impersonated.

如果任何 @racket[orig-proc] 本身是一个 impersonator，则使用 @racket[orig-proc] 所 impersonate 的 accessor 或 mutator 对于结果 impersonated structure 会被重定向，在 @racket[redirect-proc] 之前（对于 accessor）或之后（对于 mutator）对 @racket[v] 使用 @racket[orig-proc]。

@history[#:changed "6.1.1.2" @elem{Changed first argument to an
                                   accessor or mutator
                                   @racket[redirect-proc] from
                                   @racket[v] to @racket[_self].}
         #:changed "6.1.1.8" @elem{Added optional @racket[struct-type]
                                   argument.}]}


@defproc[(impersonate-vector [vec (and/c vector? (not/c immutable?))]
                             [ref-proc (or/c (vector? exact-nonnegative-integer? any/c . -> . any/c) #f)]
                             [set-proc (or/c (vector? exact-nonnegative-integer? any/c . -> . any/c) #f)]
                             [prop impersonator-property?]
                             [prop-val any/c] ... ...)
          (and/c vector? impersonator?)]{

返回 @racket[vec] 的 impersonator，它会重定向 @racket[vector-ref] 和 @racket[vector-set!] 操作。

@racket[ref-proc] 和 @racket[set-proc] 参数必须要么都是 procedure，要么都是 @racket[#f]。如果它们都是 @racket[#f]，则 @racket[impersonate-vector] 不会拦截 @racket[vec]，但仍允许附加 impersonator property。

如果 @racket[ref-proc] 是 procedure，它必须接受 @racket[vec]、传递给 @racket[vector-ref] 的索引以及 @racket[vector-ref] 在 @racket[vec] 上为该索引产生的值；它必须产生该值的替换值，该替换值是 impersonator 上 @racket[vector-ref] 的结果。

如果 @racket[set-proc] 是 procedure，它必须接受 @racket[vec]、传递给 @racket[vector-set!] 的索引以及传递给 @racket[vector-set!] 的值；它必须产生该值的替换值，该值用于原始 @racket[vec] 上的 @racket[vector-set!] 来安装该值。

@racket[prop] 和 @racket[prop-val] 的配对（传递给 @racket[impersonate-vector] 的参数数量必须为奇数）添加 impersonator property 或覆盖 @racket[vec] 的 impersonator-property 值。

@history[#:changed "6.9.0.2"]{Added non-interposing vector impersonators.}
}

@defproc[(impersonate-vector* [vec (and/c vector? (not/c immutable?))]
                              [ref-proc (or/c (vector? vector? exact-nonnegative-integer? any/c . -> . any/c) #f)]
                              [set-proc (or/c (vector? vector? exact-nonnegative-integer? any/c . -> . any/c) #f)]
                              [prop impersonator-property?]
                              [prop-val any/c] ... ...)
          (and/c vector? impersonator?)]{
 类似于 @racket[impersonate-vector]，区别在于 @racket[ref-proc] 和 @racket[set-proc] 各接收
 一个额外的向量作为参数，在其它参数之前。该额外参数是最初触发拦截的原始 impersonated vector。

 额外的 vector 参数可能有用，例如使 @racket[ref-proc] 或 @racket[set-proc] 能够提取被进一步
 impersonator 覆盖的 impersonator property。

 @history[#:added "6.9.0.2"]
}

@defproc[(impersonate-box [box (and/c box? (not/c immutable?))]
                          [unbox-proc (box? any/c . -> . any/c)]
                          [set-proc (box? any/c . -> . any/c)]
                          [prop impersonator-property?]
                          [prop-val any/c] ... ...)
          (and/c box? impersonator?)]{

返回 @racket[box] 的 impersonator，它会重定向 @racket[unbox] 和 @racket[set-box!] 操作。

@racket[unbox-proc] 必须接受 @racket[box] 以及 @racket[unbox] 在 @racket[box] 上产生的值；它必须产生一个替换值，该值是 impersonator 上 @racket[unbox] 的结果。

@racket[set-proc] 必须接受 @racket[box] 以及传递给 @racket[set-box!] 的值；它必须产生一个替换值，该值用于原始 @racket[box] 上的 @racket[set-box!] 来安装该值。

@racket[prop] 和 @racket[prop-val] 的配对（传递给 @racket[impersonate-box] 的参数数量必须为奇数）添加 impersonator property 或覆盖 @racket[box] 的 impersonator-property 值。}


@defproc[(impersonate-hash [hash (and/c hash? (not/c immutable?))]
                           [ref-proc (hash? any/c . -> . (values 
                                                          any/c 
                                                          (hash? any/c any/c . -> . any/c)))]
                           [set-proc (hash? any/c any/c . -> . (values any/c any/c))]
                           [remove-proc (hash? any/c . -> . any/c)]
                           [key-proc (hash? any/c . -> . any/c)]
                           [clear-proc (or/c #f (hash? . -> . any)) #f]
                           [equal-key-proc (or/c #f (hash? any/c . -> . any/c)) #f]
                           [prop impersonator-property?]
                           [prop-val any/c] ... ...)
          (and/c hash? impersonator?)]{

返回 @racket[hash] 的 impersonator，它会重定向 @racket[hash-ref]、@racket[hash-set!] 或 @racket[hash-set]（视情况适用）、@racket[hash-remove] 或 @racket[hash-remove!]（视情况适用）、@racket[hash-clear] 或 @racket[hash-clear!]（视情况适用且当 @racket[clear-proc] 不是 @racket[#f] 时）操作。当对 hash table 的 impersonator 使用 @racket[hash-set]、@racket[hash-remove] 或 @racket[hash-clear] 时，结果是一个具有相同重定向 procedure 的 impersonator。
此外，像 @racket[hash-iterate-key] 或 @racket[hash-map] 这样从表中提取 key 的操作，使用 @racket[key-proc] 来替换从表中提取的 key。像 @racket[hash-iterate-value] 或 @racket[hash-values] 这样的操作隐式使用 @racket[hash-ref]，因此通过 @racket[ref-proc] 重定向。@racket[hash-ref-key] 操作同时使用 @racket[ref-proc] 和 @racket[key-proc]，前者查找请求的 key，后者提取它。

@racket[ref-proc] 必须接受 @racket[hash] 和传递给 @racket[hash-ref] 的 key。它必须返回一个替换 key 以及一个 procedure。仅当返回的 key 通过 @racket[hash-ref] 在 @racket[hash] 中找到时，才会调用返回的 procedure，此时该 procedure 被调用时带有 @racket[hash]、先前返回的 key 和找到的值。返回的 procedure 本身必须返回找到值的替换值。返回的 procedure 被 @racket[hash-ref-key] 忽略。

@racket[set-proc] 必须接受 @racket[hash]、传递给 @racket[hash-set!] 或 @racket[hash-set] 的 key，以及传递给 @racket[hash-set!] 或 @racket[hash-set] 的值；它必须产生两个值：key 的替换值和值的替换值。返回的 key 和值用于原始 @racket[hash] 上的 @racket[hash-set!] 或 @racket[hash-set] 来安装该值。

@racket[remove-proc] 必须接受 @racket[hash] 和传递给 @racket[hash-remove!] 或 @racket[hash-remove] 的 key；它必须产生该 key 的替换 key，该替换 key 用于原始 @racket[hash] 上的 @racket[hash-remove!] 或 @racket[hash-remove] 来删除使用（已由 impersonator 替换的）key 的任何映射。

@racket[key-proc] 必须接受 @racket[hash] 和已从 @racket[hash] 中提取的 key（通过 @racket[hash-ref-key]、@racket[hash-iterate-key] 或内部使用 @racket[hash-iterate-key] 的其他操作）；它必须产生该 key 的替换 key，然后作为从表中提取的 key 报告。

如果 @racket[clear-proc] 不是 @racket[#f]，它必须接受 @racket[hash] 作为参数，其结果被忽略。@racket[clear-proc] 返回（而非引发异常或以其他方式转义）这一事实授予了从 @racket[hash] 中移除所有 key 的能力。如果 @racket[clear-proc] 是 @racket[#f]，则 impersonator 上的 @racket[hash-clear] 或 @racket[hash-clear!] 使用 @racket[hash-iterate-key] 和 @racket[hash-remove] 或 @racket[hash-remove!] 实现。

如果 @racket[equal-key-proc] 不是 @racket[#f]，它有效地拦截对 @racket[equal?]、@racket[equal-hash-code] 和 @racket[equal-secondary-hash-code] 的调用，用于 @racket[hash] 的 key。@racket[equal-key-proc] 必须接受 @racket[hash] 和一个 key（该 key 要么被 @racket[hash] 映射，要么被传递给 @racket[hash-ref] 等，后者可能已被相应的 @racket[ref-proc] 等调整@|.__|）作为其参数。结果是一个值，根据需要传递给 @racket[equal?]、@racket[equal-hash-code] 和 @racket[equal-secondary-hash-code] 以便对 key 进行哈希和比较。对于 @racket[hash-set!] 或 @racket[hash-set]，传递给 @racket[equal-key-proc] 的 key 是存储在 hash table 中供将来查找的那个 key。

@racket[hash-iterate-value]、@racket[hash-map] 或 @racket[hash-for-each] 函数结合使用 @racket[hash-iterate-key] 和 @racket[hash-ref]。如果 @racket[key-proc] 产生的 key 没有通过 @racket[hash-ref] 找到值，则 @exnraise[exn:fail:contract]。

@racket[prop] 和 @racket[prop-val] 的配对添加 impersonator property 或覆盖 @racket[hash] 的 impersonator-property 值。

对于 immutable hash table，当两个 impersonated hash table 的重定向 procedure 最初是通过同一个 @racket[impersonate-hash] 或 @racket[chaperone-hash] 调用附加到 hash table 的（并可能通过 @racket[hash-set]、@racket[hash-remove] 或 @racket[hash-clear] 传播），只要第一个 hash table 的内容是第二个 hash table 的 @racket[impersonator-of?]，则它们被视为"相同的值"（出于 @racket[impersonator-of?] 的目的）。

@history[#:changed "6.3.0.11" @elem{Added the @racket[equal-key-proc]
                                    argument.}]}


@defproc[(impersonate-channel [channel channel?]
                              [get-proc (channel? . -> . (values channel? (any/c . -> . any/c)))]
                              [put-proc (channel? any/c . -> . any/c)]
                              [prop impersonator-property?]
                              [prop-val any/c] ... ...)
          (and/c channel? impersonator?)]{

返回 @racket[channel] 的 impersonator，它会重定向 @racket[channel-get] 和 @racket[channel-put] 操作。

@racket[get-proc] generator 在 @racket[channel-get] 或任何其他从 channel 获取结果的操作（如对 channel 的 @racket[sync]）上被调用。@racket[get-proc] 必须返回两个值：一个是 @racket[channel] 的 impersonator 的 @tech{channel}，另一个是用于检查 channel 内容的 procedure。

@racket[put-proc] 必须接受 @racket[channel] 以及传递给 @racket[channel-put] 的值；它必须产生一个替换值，该值用于原始 @racket[channel] 上的 @racket[channel-put] 以通过 channel 发送该值。

@racket[prop] 和 @racket[prop-val] 的配对（传递给 @racket[impersonate-channel] 的参数数量必须为奇数）添加 impersonator property 或覆盖 @racket[channel] 的 impersonator-property 值。}


@defproc[(impersonate-prompt-tag [prompt-tag continuation-prompt-tag?]
                                 [handle-proc procedure?]
                                 [abort-proc procedure?]
                                 [cc-guard-proc procedure? values]
                                 [callcc-impersonate-proc (procedure? . -> . procedure?) (lambda (p) p)]
                                 [comp-guard-proc procedure? values]
                                 [prop impersonator-property?]
                                 [prop-val any/c] ... ...)
          (and/c continuation-prompt-tag? impersonator?)]{

返回 @racket[prompt-tag] 的 impersonator，它会重定向 @racket[call-with-continuation-prompt] 和 @racket[abort-current-continuation] 操作。

@racket[handle-proc] 必须接受 continuation prompt 的 handler 将接受的值，并且必须产生替换值，这些值将被传递给 handler。

@racket[abort-proc] 必须接受传递给 @racket[abort-current-continuation] 的值；它必须产生替换值，这些值将被 abort 到适当的 prompt。

当非组合的 continuation 被应用以替换由 prompt 定界的 continuation 时，@racket[cc-guard-proc] 必须接受 @racket[call-with-continuation-prompt] 产生的值，但仅当 @racket[abort-current-continuation] 后来没有被用于 abort 由 prompt 定界的 continuation 时（此时使用 @racket[abort-proc]）。

@racket[callcc-impersonate-proc] 必须接受一个 procedure，该 procedure 保护由 @racket[call-with-current-continuation] 捕获的、带有 impersonated prompt tag 的 continuation 的结果。当捕获的 continuation 被应用以细化特定于定界 prompt 的 guard 函数（初始为 @racket[values]）时，@racket[callcc-impersonate-proc] 被应用（在 @tech{continuation barrier} 下）；这个特定于 prompt 的 guard 最终与在定界 prompt 处生效的任何 @racket[cc-guard-proc] 组合，并且在不使用 @racket[cc-guard-proc] 的相同情况下也不使用它（即当 @racket[abort-current-continuation] 被用于 abort 到该 prompt 时）。在应用时定界 prompt 是线程的内置初始 prompt 的特殊情况下，@racket[callcc-impersonate-proc] 被忽略（部分原因是初始 prompt 的结果被忽略）。

@racket[comp-guard-proc] procedure 类似于 @racket[cc-guard-proc]，但它应用于使用 impersonated prompt 捕获的可组合 continuation 的结果。如果 @racket[comp-guard-proc] 是不同于 @racket[values] 的 procedure，则使用 impersonated prompt 捕获的可组合 continuation 将不会相对于其调用位置在 tail position 中应用，因为 continuation 的结果将被传递给 @racket[comp-guard-proc]。

@racket[prop] 和 @racket[prop-val] 的配对（传递给 @racket[impersonate-prompt-tag] 的参数数量必须为奇数）添加 impersonator property 或覆盖 @racket[prompt-tag] 的 impersonator-property 值。

@examples[
  (define tag
    (impersonate-prompt-tag
     (make-continuation-prompt-tag)
     (lambda (n) (* n 2))
     (lambda (n) (+ n 1))))

  (call-with-continuation-prompt
    (lambda ()
      (abort-current-continuation tag 5))
    tag
    (lambda (n) n))
]

@history[#:changed "9.2.0.6" @elem{Added the @racket[comp-guard-proc] argument.}]}


@defproc[(impersonate-continuation-mark-key
          [key continuation-mark-key?]
          [get-proc procedure?]
          [set-proc procedure?]
          [prop impersonator-property?]
          [prop-val any/c] ... ...)
         (and/c continuation-mark? impersonator?)]{

返回 @racket[key] 的 impersonator，它会重定向 @racket[with-continuation-mark] 和诸如 @racket[continuation-mark-set->list] 之类的 continuation mark accessor。

@racket[get-proc] 必须接受附加到 continuation mark 的值，并且必须产生一个替换值，该值将被 continuation mark accessor 返回。

@racket[set-proc] 必须接受传递给 @racket[with-continuation-mark] 的值；它必须产生一个替换值，该值被附加到 continuation 帧。

@racket[prop] 和 @racket[prop-val] 的配对（传递给 @racket[impersonate-continuation-mark-key] 的参数数量必须为奇数）添加 impersonator property 或覆盖 @racket[key] 的 impersonator-property 值。

@examples[
  (define mark-key
    (impersonate-continuation-mark-key
     (make-continuation-mark-key)
     (lambda (l) (map char-upcase l))
     (lambda (s) (string->list s))))

  (with-continuation-mark mark-key "quiche"
    (continuation-mark-set-first
     (current-continuation-marks)
     mark-key))
]
}


@defthing[prop:impersonator-of struct-type-property?]{

一个 @tech{structure type property}（参见 @secref["structprops"]），它提供一个 procedure 用于从表示 impersonator 的 structure 中提取 impersonated 值。该 property 用于 @racket[impersonator-of?] 以及 @racket[equal?]。

property 值必须是一个接受一个参数的 procedure，该参数是一个 structure，其 structure type 具有该 property。结果可以是 @racket[#f] 表示该 structure 不表示 impersonator，否则结果是一个值，原始 structure 是该值的 impersonator（因此原始 structure 与结果值是 @racket[impersonator-of?] 和 @racket[equal?] 的关系）。结果值必须与原始 structure 具有相同的 @racket[prop:impersonator-of] 和 @racket[prop:equal+hash] property 值（如果有的话），并且 property 值必须从相同的 structure type 继承（这确保了 @racket[impersonator-of?] 和 @racket[equal?] 之间的一定一致性）。

应用于具有 @racket[prop:impersonator-of] property 的 structure 的 @tech{impersonator property} predicate 和 accessor 首先检查直接 structure 上的 property，如果未找到，则（递归地）检查 @racket[prop:impersonator-of] procedure 产生的值。

@history[#:changed "6.1.1.8" @elem{Made @tech{impersonator property}
                                   predicates and accessors sensitive
                                   to @racket[prop:impersonator-of].}]}


@defthing[prop:authentic struct-type-property?]{

一个 @tech{structure type property}，它将 structure type 声明为 @deftech{authentic}。与该 property 关联的值被忽略；property 本身的存在使 structure type 成为 authentic。

@tech{authentic} structure type 的实例不能通过 @racket[impersonate-struct] 被 impersonate，也不能通过 @racket[chaperone-struct] 被 chaperone。因此，@tech{authentic} structure type 的实例只能在它是 @tech{flat contract} 的情况下才能被赋予 contract（参见 @racket[struct/c]）。

将 structure type 声明为 @tech{authentic} 可以防止不需要的 structure impersonation，但暴露的 structure type 通常应支持 impersonator 或 chaperone 以方便 contract。将 structure type 声明为 @tech{authentic} 还可以略微提高 structure predicate、selector 和 mutator 的性能，这对于在库内部私有且频繁使用的数据结构可能是合适的。

@history[#:added "6.9.0.4"]}

@; ------------------------------------------------------------
@section[#:tag "chaperones-s2"]{Chaperone Constructors}

@defproc[(chaperone-procedure [proc procedure?]
                              [wrapper-proc (or/c procedure? #f)]
                              [prop impersonator-property?]
                              [prop-val any/c] ... ...)
         (and/c procedure? chaperone?)]{

类似于 @racket[impersonate-procedure]，但对于提供给 @racket[wrapper-proc] 的每个值，相应的结果必须与提供的值相同或是其 chaperone（在 @racket[chaperone-of?] 的意义上）。如果有额外的结果位于 chaperoned 值之前，则必须是一个 procedure，接受与 @racket[proc] 产生的结果数量相同的参数；它必须返回相同数量的结果，每个结果与相应的原始结果相同或是其 chaperone。

对于包含关键字参数的应用，@racket[wrapper-proc] 必须在其他值之前、但在result-chaperoning procedure（如果有的话）之后返回一个额外的值。该额外值必须是一个列表，其中包含提供给 chaperone procedure 的关键字参数的 chaperone（即不计入未提供的可选参数）。参数必须按照所提供参数关键字的排序顺序排列。}


@defproc[(chaperone-procedure* [proc procedure?]
                               [wrapper-proc (or/c procedure? #f)]
                               [prop impersonator-property?]
                               [prop-val any/c] ... ...)
         (and/c procedure? chaperone?)]{

类似于 @racket[chaperone-procedure]，但 @racket[wrapper-proc] 接收一个额外的参数，与 @racket[impersonate-procedure*] 类似。

@history[#:added "6.1.1.5"]}


@defproc[(chaperone-struct [v any/c]
                           [struct-type struct-type? _unspecified]
                           [orig-proc (or/c struct-accessor-procedure?
                                            struct-mutator-procedure?
                                            struct-type-property-accessor-procedure?
                                            (lambda (proc)
                                              (eq? proc struct-info)))]
                           [redirect-proc (or/c procedure? #f)] ... ...
                           [prop impersonator-property?]
                           [prop-val any/c] ... ...)
          any/c]{

类似于 @racket[impersonate-struct]，但有以下改进，其中 @racket[_self] 表示 @racket[orig-proc] 最初应用于的值：

@itemlist[

 @item{With a structure-field accessor as @racket[orig-proc],
      @racket[redirect-proc] must accept two arguments, @racket[_self] and
      the value @racket[_field-v] that @racket[orig-proc] produces for
      @racket[v]; it must return a chaperone of @racket[_field-v]. The
      corresponding field may be immutable.}

 @item{With structure-field mutator as @racket[orig-proc],
      @racket[redirect-proc] must accept two arguments, @racket[_self] and
      the value @racket[_field-v] supplied to the mutator; it must
      return a chaperone of @racket[_field-v] to be propagated to
      @racket[orig-proc] and @racket[v].}

 @item{A property accessor can be supplied as @racket[orig-proc], and
       the property need not have been created with
       @racket['can-impersonate].  The corresponding
       @racket[redirect-proc] uses the same protocol as for a
       structure-field accessor.}

 @item{With @racket[struct-info] as @racket[orig-proc], the
       corresponding @racket[redirect-proc] must accept two values,
       which are the results of @racket[struct-info] on @racket[v]; it
       must return each values or a chaperone of each value. The
       @racket[redirect-proc] is not called if @racket[struct-info]
       would return @racket[#f] as its first argument. An
       @racket[orig-proc] can be @racket[struct-info] only if
       @racket[struct-type] or some other @racket[orig-proc] is supplied.}

 @item{Any accessor or mutator @racket[orig-proc] that is an
       @tech{impersonator} must be specifically a @tech{chaperone}.}

]

为 @racket[orig-proc] 提供 property accessor 可以启用 @racket[prop] 参数，与提供 accessor、mutator 或 structure type 相同。

@history[#:changed "6.1.1.2" @elem{Changed first argument to an
                                   accessor or mutator
                                   @racket[redirect-proc] from
                                   @racket[v] to @racket[_self].}
         #:changed "6.1.1.8" @elem{Added optional @racket[struct-type]
                                   argument.}]}

@defproc[(chaperone-vector [vec vector?]
                           [ref-proc (or/c (vector? exact-nonnegative-integer? any/c . -> . any/c) #f)]
                           [set-proc (or/c (vector? exact-nonnegative-integer? any/c . -> . any/c) #f)]
                           [prop impersonator-property?]
                           [prop-val any/c] ... ...)
          (and/c vector? chaperone?)]{

类似于 @racket[impersonate-vector]，但支持 immutable vector。 The
@racket[ref-proc] procedure must produce the same value or a chaperone
of the original value, and @racket[set-proc] must produce the value
that is given or a chaperone of the value. The @racket[set-proc] will
not be used if @racket[vec] is immutable.}

@defproc[(chaperone-vector* [vec vector?]
                            [ref-proc (or/c (vector? vector? exact-nonnegative-integer? any/c . -> . any/c) #f)]
                            [set-proc (or/c (vector? vector? exact-nonnegative-integer? any/c . -> . any/c) #f)]
                            [prop impersonator-property?]
                            [prop-val any/c] ... ...)
         (and/c vector? chaperone?)]{
 类似于 @racket[chaperone-vector]，但 @racket[ref-proc] 和 @racket[set-proc] 接收
 一个额外的参数，与 @racket[impersonate-vector*] 类似。

 @history[#:added "6.9.0.2"]
}

@defproc[(chaperone-box [box box?]
                        [unbox-proc (box? any/c . -> . any/c)]
                        [set-proc (box? any/c . -> . any/c)]
                        [prop impersonator-property?]
                        [prop-val any/c] ... ...)
          (and/c box? chaperone?)]{

类似于 @racket[impersonate-box]，但支持 immutable box。 The
@racket[unbox-proc] procedure must produce the same value or a
chaperone of the original value, and @racket[set-proc] must produce
the same value or a chaperone of the value that it is given.  The
@racket[set-proc] will not be used if @racket[box] is immutable.}


@defproc[(chaperone-hash [hash hash?]
                         [ref-proc (hash? any/c . -> . (values 
                                                        any/c 
                                                        (hash? any/c any/c . -> . any/c)))]
                         [set-proc (hash? any/c any/c . -> . (values any/c any/c))]
                         [remove-proc (hash? any/c . -> . any/c)]
                         [key-proc (hash? any/c . -> . any/c)]
                         [clear-proc (or/c #f (hash? . -> . any)) #f]
                         [equal-key-proc (or/c #f (hash? any/c . -> . any/c)) #f]
                         [prop impersonator-property?]
                         [prop-val any/c] ... ...)
          (and/c hash? chaperone?)]{

类似于 @racket[impersonate-hash]，但对给定的函数有约束并支持 immutable hash。@racket[ref-proc] procedure 必须返回找到的值或该值的 chaperone。@racket[set-proc] procedure 必须产生两个值：提供给它的 key 或该 key 的 chaperone，以及提供给它的值或该值的 chaperone。@racket[remove-proc]、@racket[key-proc] 和 @racket[equal-key-proc] procedure 必须产生给定的 key 或该 key 的 chaperone。

@history[#:changed "6.3.0.11" @elem{Added the @racket[equal-key-proc]
                                    argument.}]}

@defproc[(chaperone-struct-type [struct-type struct-type?]
                                [struct-info-proc procedure?]
                                [make-constructor-proc (procedure? . -> . procedure?)]
                                [guard-proc procedure?]
                                [prop impersonator-property?]
                                [prop-val any/c] ... ...)
          (and/c struct-type? chaperone?)]{

返回一个类似 @racket[struct-type] 的 chaperoned 值，但对 chaperoned structure type 上的 @racket[struct-type-info] 和 @racket[struct-type-make-constructor] 操作进行了重定向。此外，当一个新的 structure type 作为 chaperoned structure type 的子类型被创建时，@racket[guard-proc] 被插入为对子类型实例创建的额外 guard。

@racket[struct-info-proc] 必须接受 8 个参数——即 @racket[struct-type-info] 在 @racket[struct-type] 上的结果。它必须返回 8 个值，每个值与相应的参数相同或是其 chaperone。这 8 个值用作 chaperoned structure type 上 @racket[struct-type-info] 的结果。

@racket[make-constructor-proc] 必须接受单个 procedure 参数，该参数是由 @racket[struct-type-make-constructor] 在 @racket[struct-type] 上产生的 constructor。它必须返回相同的 procedure 或其 chaperone，该值用作 chaperoned structure type 上 @racket[struct-type-make-constructor] 的结果。

@racket[guard-proc] 类似于 @racket[make-struct-type] 的 @racket[guard] 参数：它必须接受比 @racket[struct-type] 的 constructor 多一个的参数，其中最后一个参数是实例化 structure type 的名称。它必须返回 constructor 所需的值数量（即每个参数一个值，最后一个除外），并且每个返回值必须与相应的参数相同或是其 chaperone。当创建 chaperoned structure type 的子类型时，@racket[guard-proc] 被添加为 constructor guard。

@racket[prop] 和 @racket[prop-val] 的配对（传递给 @racket[chaperone-struct-type] 的参数数量必须为偶数）添加 impersonator property 或覆盖 @racket[struct-type] 的 impersonator-property 值。}

@defproc[(chaperone-evt [evt evt?]
                        [proc (evt? . -> . (values evt? (any/c . -> . any/c)))]
                        [prop impersonator-property?]
                        [prop-val any/c] ... ...)
          (and/c evt? chaperone?)]{

返回一个类似 @racket[evt] 的 chaperoned 值，但当结果与 @racket[sync] 等函数同步时，使用 @racket[proc] 作为事件生成器。

@racket[proc] generator 在同步时被调用，类似于传递给 @racket[guard-evt] 的 procedure，区别在于 @racket[proc] 被传递了 @racket[evt]。@racket[proc] 必须返回两个值：一个作为 @racket[evt] 的 chaperone 的 @tech{synchronizable event}，以及一个 procedure，用于在选择中选中事件时检查其结果。后一个 procedure 接受 @racket[evt] 的结果，并且必须返回该值的 chaperone。

@racket[prop] 和 @racket[prop-val] 的配对（传递给 @racket[chaperone-evt] 的参数数量必须为偶数）添加 impersonator property 或覆盖 @racket[evt] 的 impersonator-property 值。

结果是参数 @racket[evt] 的 @racket[chaperone-of?]。
However, if @racket[evt] is a @tech{thread}, @tech{semaphore},
@tech{input port}, @tech{output port}, or @tech{will executor}, the
result is not recognized as such. For example, @racket[thread?]
applied to the result of @racket[chaperone-evt] will always produce
@racket[#f].}


@defproc[(chaperone-channel [channel channel?]
                            [get-proc (channel? . -> . (values channel? (any/c . -> . any/c)))]
                            [put-proc (channel? any/c . -> . any/c)]
                            [prop impersonator-property?]
                            [prop-val any/c] ... ...)
          (and/c channel? chaperone?)]{

类似于 @racket[impersonate-channel]，但对 @racket[get-proc] 和 @racket[put-proc] procedure 有限制。

@racket[get-proc] 必须返回两个值：一个作为 @racket[channel] 的 chaperone 的 @tech{channel}，以及一个用于检查 channel 内容的 procedure。后一个 procedure 必须返回原始值或该值的 chaperone。

@racket[put-proc] 必须产生一个替换值，该替换值要么是通过 channel 通信的原始值，要么是该值的 chaperone。

@racket[prop] 和 @racket[prop-val] 的配对（传递给 @racket[chaperone-channel] 的参数数量必须为奇数）添加 impersonator property 或覆盖 @racket[channel] 的 impersonator-property 值。}


@defproc[(chaperone-prompt-tag [prompt-tag continuation-prompt-tag?]
                               [handle-proc procedure?]
                               [abort-proc procedure?]
                               [cc-guard-proc procedure? values]
                               [callcc-chaperone-proc (procedure? . -> . procedure?) (lambda (p) p)]
                               [comp-guard-proc procedure? values]
                               [prop impersonator-property?]
                               [prop-val any/c] ... ...)
          (and/c continuation-prompt-tag? chaperone?)]{

类似于 @racket[impersonate-prompt-tag]，但产生一个 chaperoned 值。
@racket[handle-proc] procedure 必须产生与原始值相同的值或原始值的 chaperone，@racket[abort-proc] 必须产生与给定值相同的值或给定值的 chaperone，@racket[cc-guard-proc] 必须产生与原始结果值相同的值或原始结果值的 chaperone，@racket[callcc-chaperone-proc] 必须产生一个 procedure，该 procedure 是给定 procedure 的 chaperone 或与给定 procedure 相同，@racket[comp-guard-proc] 必须产生与原始结果值相同的值或原始结果值的 chaperone。

@examples[
  (define bad-chaperone
    (chaperone-prompt-tag
     (make-continuation-prompt-tag)
     (lambda (n) (* n 2))
     (lambda (n) (+ n 1))))

  (eval:error
   (call-with-continuation-prompt
     (lambda ()
       (abort-current-continuation bad-chaperone 5))
     bad-chaperone
     (lambda (n) n)))

  (define good-chaperone
    (chaperone-prompt-tag
     (make-continuation-prompt-tag)
     (lambda (n) (if (even? n) n (error "not even")))
     (lambda (n) (if (even? n) n (error "not even")))))

  (call-with-continuation-prompt
    (lambda ()
      (abort-current-continuation good-chaperone 2))
    good-chaperone
    (lambda (n) n))
]

@history[#:changed "9.2.0.6" @elem{Added the @racket[comp-guard-proc] argument.}]}


@defproc[(chaperone-continuation-mark-key
          [key continuation-mark-key?]
          [get-proc procedure?]
          [set-proc procedure?]
          [prop impersonator-property?]
          [prop-val any/c] ... ...)
         (and/c continuation-mark-key? chaperone?)]{

类似于 @racket[impersonate-continuation-mark-key]，但产生 chaperoned 值。@racket[get-proc] procedure 必须产生与原始值相同的值或原始值的 chaperone，@racket[set-proc] 必须产生与给定值相同的值或给定值的 chaperone。

@examples[
  (define bad-chaperone
    (chaperone-continuation-mark-key
     (make-continuation-mark-key)
     (lambda (l) (map char-upcase l))
     string->list))

  (eval:error
   (with-continuation-mark bad-chaperone "timballo"
     (continuation-mark-set-first
      (current-continuation-marks)
      bad-chaperone)))

  (define (checker s)
    (if (> (string-length s) 5)
        s
        (error "expected string of length at least 5")))

  (define good-chaperone
    (chaperone-continuation-mark-key
     (make-continuation-mark-key)
     checker
     checker))

  (with-continuation-mark good-chaperone "zabaione"
    (continuation-mark-set-first
     (current-continuation-marks)
     good-chaperone))
]
}

@; ------------------------------------------------------------
@section{Impersonator Property}

@defproc[(make-impersonator-property [name symbol?])
         (values impersonator-property?
                 (-> any/c boolean?)
                 (->* (impersonator?) (any/c) any))]{

创建一个新的 @tech{impersonator property} 并返回三个值：

@itemize[

 @item{一个 @deftech{impersonator property descriptor}，用于 @racket[impersonate-procedure]、@racket[chaperone-procedure] 和其他 impersonator 构造器；}

 @item{一个 @deftech{impersonator property predicate} procedure，它接受任意值，如果该值是一个具有该 property 值的 impersonator 则返回 @racket[#t]，否则返回 @racket[#f]；}

 @item{一个 @deftech{impersonator property accessor} procedure，它返回与 impersonator 关联的 property 值；如果传递给 accessor 的值不是 impersonator 或者不具有该 property 的值（即如果相应的 impersonator property predicate 返回 @racket[#f]），则传递给 selector 的第二个可选参数决定其响应：如果未提供第二个参数则 @exnraise[exn:fail:contract]，如果第二个参数是 procedure 则不带参数尾调用它，否则返回第二个参数。}

]}

@defproc[(impersonator-property? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{impersonator property descriptor} 值则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(impersonator-property-predicate-procedure? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[make-impersonator-property] 产生的 predicate procedure 则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "9.1.0.6"]}

@defproc[(impersonator-property-accessor-procedure? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[make-impersonator-property] 产生的 accessor procedure 则返回 @racket[#t]，否则返回 @racket[#f]。}


@defthing[impersonator-prop:application-mark impersonator-property?]{

一个 @tech{impersonator property}，被 @racket[impersonate-procedure] 和 @racket[chaperone-procedure] 识别。}

