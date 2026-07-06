#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "procedures"]{过程}

@defproc[(procedure? [v any/c]) boolean?]{ 如果 @racket[v] 是过程则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(apply [proc procedure?]
                [v any/c] ... [lst list?]
                [#:<kw> kw-arg any/c] ...) any]{

@guideintro["apply"]{@racket[apply]}

使用 @racket[(list* v ... lst)] 的内容作为（按位置的）参数来应用 @racket[proc]。@racket[#:<kw> kw-arg] 序列也作为关键字参数提供给 @racket[proc]，其中 @racket[#:<kw>] 代表任意关键字。

给定的 @racket[proc] 必须接受与 @racket[v] 的数量加上 @racket[lst] 长度相同数量的参数，它必须接受提供的关键字参数，并且不能要求任何其他关键字参数；否则 @exnraise[exn:fail:contract]。给定的 @racket[proc] 在相对于 @racket[apply] 调用的尾部位置被调用。

@mz-examples[
(apply + '(1 2 3))
(apply + 1 2 '(3))
(apply + '())
(apply sort (list (list '(2) '(1)) <) #:key car)
]}

@deftogether[(@defproc[(compose  [proc procedure?] ...) procedure?]
              @defproc[(compose1 [proc procedure?] ...) procedure?])]{

返回一个组合给定函数的过程，最先应用最后一个 @racket[proc]，最后应用第一个 @racket[proc]。@racket[compose] 函数允许给定函数消费和产生任意数量的值，只要每个函数产生的值的数量与前一个函数消费的数量相同，而 @racket[compose1] 将内部值传递限制为单个值。在这两种情况下，最后一个函数的输入元数和第一个函数的输出元数不受限制，它们成为结果组合的相应元数（包括输入端的关键字参数）。

当没有给出 @racket[proc] 参数时，结果是 @racket[values]。当恰好给出一个时，它被返回。

@mz-examples[
((compose1 - sqrt) 10)
((compose1 sqrt -) 10)
((compose list split-path) (bytes->path #"/a" 'unix))
]

注意，在许多情况下，@racket[compose1] 更受推荐。例如，在两个库函数上使用 @racket[compose] 可能在一个函数被扩展为返回两个值而前一个函数具有不同语义的可选输入时导致问题。此外，@racket[compose1] 可能创建更快的组合。

}

@defproc[(procedure-rename [proc procedure?]
                           [name symbol?]
                           [realm symbol? 'racket])
         procedure?]{

返回一个类似于 @racket[proc] 的过程，除了它的名称（由 @racket[object-name] 返回，并用于调试打印）是 @racket[name]，并且它的 @tech{realm}（可能用于调整错误消息）是 @racket[realm]。

给定的 @racket[name] 和 @racket[realm] 用于在结果过程被应用于错误数量的参数时打印和调整错误消息。此外，如果 @racket[proc] 是由 @racket[struct]、@racket[make-struct-field-accessor] 或 @racket[make-struct-field-mutator] 产生的 @tech{accessor} 或 @tech{mutator}，则结果过程在其（第一个）参数类型错误时也使用 @racket[name]。不过更典型的是，@racket[name] 不用于报告错误，因为过程名称通常被硬编码到内部检查中。

@history[#:changed "8.4.0.2" @elem{Added the @racket[realm] argument.}]}


@defproc[(procedure-realm [proc procedure?])
         symbol?]{

报告过程的 @tech{realm}，这可能取决于创建过程的模块、过程代码编译时的 @racket[current-compile-realm] 值，或通过 @racket[procedure-rename] 等函数显式分配的 realm。

@history[#:added "8.4.0.2"]}


@defproc[(procedure->method [proc procedure?]) procedure?]{

返回一个类似于 @racket[proc] 的过程，除了当应用于错误数量的参数时，产生的错误会隐藏第一个参数，就好像该过程是使用 @indexed-racket['method-arity-error] syntax property 编译的一样。}

@defproc[(procedure-closure-contents-eq? [proc1 procedure?]
                                         [proc2 procedure?]) boolean?]{
通过使用 @racket[eq?] 逐点比较闭包元素来比较 @racket[proc1] 和 @racket[proc2] 的闭包内容是否相等}

@; ----------------------------------------
@section{关键字与元数}

@defproc[(keyword-apply [proc procedure?]
                        [kw-lst (listof keyword?)]
                        [kw-val-lst list?]
                        [v any/c] ...
                        [lst list?]
                        [#:<kw> kw-arg any/c] ...)
         any]{

@guideintro["apply"]{@racket[keyword-apply]}

类似于 @racket[apply]，但 @racket[kw-lst] 和 @racket[kw-val-lst] 除了 @racket[v] 和 @racket[lst] 的按位置参数以及直接提供在 @racket[#:<kw> kw-arg] 序列中的关键字参数之外，还提供按关键字的参数，其中 @racket[#:<kw>] 代表任意关键字。

给定的 @racket[kw-lst] 必须使用 @racket[keyword<?] 排序。没有关键字可以在 @racket[kw-lst] 中出现两次，或者同时在 @racket[kw-lst] 中和作为 @racket[#:<kw>] 出现，否则 @exnraise[exn:fail:contract]。给定的 @racket[kw-val-lst] 必须与 @racket[kw-lst] 具有相同的长度，否则 @exnraise[exn:fail:contract]。给定的 @racket[proc] 必须接受 @racket[kw-lst] 中的所有关键字加上 @racket[#:<kw>]，它不能要求任何其他关键字，并且它必须接受与通过 @racket[v] 和 @racket[lst] 提供的数量相同的按位置参数；否则 @exnraise[exn:fail:contract]。

@examples[
(eval:no-prompt
 (define (f x #:y y #:z [z 10])
   (list x y z)))
(keyword-apply f '(#:y) '(2) '(1))
(keyword-apply f '(#:y #:z) '(2 3) '(1))
(keyword-apply f #:z 7 '(#:y) '(2) '(1))
]}

@defproc[(procedure-arity [proc procedure?]) normalized-arity?]{

返回关于 @racket[proc] 接受的按位置参数数量的信息。另见 @racket[procedure-arity?]、@racket[normalized-arity?] 和 @racket[procedure-arity-mask]。}

@defproc[(procedure-arity? [v any/c]) boolean?]{

有效的元数 @racket[_a] 是以下之一：

@itemize[

  @item{一个精确的非负整数，这意味着该过程仅接受 @racket[_a] 个参数。}

 @item{一个 @racket[arity-at-least] 实例，这意味着该过程接受 @racket[(arity-at-least-value _a)] 或更多个参数。}

 @item{一个包含整数和 @racket[arity-at-least] 实例的列表，这意味着该过程接受可以匹配 @racket[_a] 中某个元素的任意数量的参数。}

]

@racket[procedure-arity] 的结果始终按照 @racket[normalized-arity?] 的意义进行规范化。

@mz-examples[
(procedure-arity cons)
(procedure-arity list)
(arity-at-least? (procedure-arity list))
(arity-at-least-value (procedure-arity list))
(arity-at-least-value (procedure-arity (lambda (x . y) x)))
(procedure-arity (case-lambda [(x) 0] [(x y) 1]))
]}

@defproc[(procedure-arity-mask [proc procedure?]) exact-integer?]{

返回与 @racket[procedure-arity] 相同的信息，但编码方式不同。元数被编码为一个精确整数 @racket[_mask]，如果 @racket[proc] 接受 @racket[_n] 个参数，则 @racket[(bitwise-bit-set? _mask _n)] 返回 true。

元数的掩码编码通常更容易测试和操作，并且 @racket[procedure-arity-mask] 有时比 @racket[procedure-arity] 更快，同时至少一样快。

@history[#:added "7.0.0.11"]}

@defproc[(procedure-arity-includes? [proc procedure?]
                                    [k exact-nonnegative-integer?]
                                    [kws-ok? any/c #f])
         boolean?]{

如果过程可以接受 @racket[k] 个按位置参数则返回 @racket[#t]，否则返回 @racket[#f]。如果 @racket[kws-ok?] 为 @racket[#f]，则仅当 @racket[proc] 没有必需的关键字参数时结果才为 @racket[#t]。

@mz-examples[
(procedure-arity-includes? cons 2)
(procedure-arity-includes? display 3)
(procedure-arity-includes? (lambda (x #:y y) x) 1)
(procedure-arity-includes? (lambda (x #:y y) x) 1 #t)
]}

@defproc[(procedure-reduce-arity [proc procedure?]
                                 [arity procedure-arity?]
                                 [name (or/c symbol? #f) #f]
                                 [realm symbol? 'racket])
         procedure?]{

返回一个与 @racket[proc] 相同的过程（包括 @racket[object-name] 返回的相同名称），但只接受与 @racket[arity] 一致的参数。特别是，当对生成的过程应用 @racket[procedure-arity] 时，它返回一个与 @racket[arity] 的规范化形式 @racket[equal?] 的值。

如果 @racket[arity] 规范允许不在 @racket[(procedure-arity proc)] 中的参数，则 @exnraise[exn:fail:contract]。如果 @racket[proc] 接受关键字参数，则关键字参数必须全部是可选的（并且它们在元数缩减后的过程中不被接受）或者 @racket[arity] 必须是空列表（这将产生一个无法调用的过程）；否则 @exnraise[exn:fail:contract]。

如果 @racket[name] 不是 @racket[#f]，则结果过程的 @racket[object-name] 产生 @racket[name]，结果过程的 @racket[procedure-realm] 产生 @racket[realm]。否则，结果过程的 @racket[object-name] 和 @racket[procedure-realm] 产生与 @racket[proc] 相同的结果。

@examples[
(define my+ (procedure-reduce-arity + 2 ))
(my+ 1 2)
(eval:error (my+ 1 2 3))
(define also-my+ (procedure-reduce-arity + 2 'also-my+))
(eval:error (also-my+ 1 2 3))
]

@history[#:changed "7.0.0.11" @elem{Added the optional @racket[name]
                                    argument.}
         #:changed "8.4.0.2" @elem{Added the @racket[realm] argument.}]}

@defproc[(procedure-reduce-arity-mask [proc procedure?]
                                      [mask exact-integer?]
                                      [name (or/c symbol? #f) #f]
                                      [realm symbol? 'racket])
         procedure?]{

与 @racket[procedure-reduce-arity] 相同，但使用 @racket[procedure-arity-mask] 描述的元数表示。

元数的掩码编码通常更容易测试和操作，并且 @racket[procedure-reduce-arity-mask] 有时比 @racket[procedure-reduce-arity] 更快，同时至少一样快。

@history[#:added "7.0.0.11"
         #:changed "8.4.0.2" @elem{Added the @racket[realm] argument.}]}

@defproc[(procedure-keywords [proc procedure?])
         (values
          (listof keyword?)
          (or/c (listof keyword?) #f))]{

返回关于过程所需和接受的关键字参数的信息。第一个结果是一个列表，包含应用 @racket[proc] 时所需的不同关键字（按 @racket[keyword<?] 排序）。第二个结果是一个列表，包含被接受的不同关键字（按 @racket[keyword<?] 排序），或者为 @racket[#f] 表示接受任何关键字。当第二个结果是一个列表时，第一个列表中的每个元素也在第二个列表中。

@mz-examples[
(procedure-keywords +)
(procedure-keywords (lambda (#:tag t #:mode m) t))
(procedure-keywords (lambda (#:tag t #:mode [m #f]) t))
]}

@defproc[(procedure-result-arity [proc procedure?]) (or/c #f procedure-arity?)]{
 返回过程 @racket[proc] 结果的元数，如果结果数量未知（可能由于 @racket[procedure-result-arity] 的实现不足或 @racket[proc] 的行为不够简单），则返回 @racket[#f]。

 @mz-examples[(procedure-result-arity car)
              (procedure-result-arity values)
              (procedure-result-arity
               (λ (x)
                 (apply
                  values
                  (let loop ()
                    (cond
                      [(zero? (random 10)) '()]
                      [else (cons 1 (loop))])))))]

 @history[#:added "6.4.0.3"]
}

@defproc[(make-keyword-procedure
          [proc ((listof keyword?) list? any/c ... . -> . any)]
          [plain-proc procedure? (lambda args (apply proc null null args))])
         procedure?]{

返回一个接受所有关键字参数（不要求任何关键字参数）的过程。

当 @racket[make-keyword-procedure] 返回的过程被使用关键字参数调用时，则调用 @racket[proc]；第一个参数是按 @racket[keyword<?] 排序的不同关键字列表，第二个参数是包含每个关键字对应值的并行列表，其余参数是按位置参数。

当 @racket[make-keyword-procedure] 返回的过程被不带关键字参数调用时，则调用 @racket[plain-proc]——可能比通过 @racket[proc] 分派更高效。通常，@racket[plain-proc] 应该具有与使用空列表作为前两个参数调用 @racket[proc] 相同的行为，但这种对应关系并不被强制执行。

如果提供了 @racket[plain-proc]，则对新过程应用 @racket[procedure-arity] 和 @racket[object-name] 的结果与 @racket[plain-proc] 相同。否则，@racket[object-name] 的结果与 @racket[proc] 相同，但 @racket[procedure-arity] 的结果是通过将 @racket[proc] 的元数减少 2 来推导的（即，去掉处理关键字参数的两个前缀参数）。另见 @racket[procedure-reduce-keyword-arity] 和 @racket[procedure-rename]。

@examples[
(eval:no-prompt
 (define show
   (make-keyword-procedure (lambda (kws kw-args . rest)
                             (list kws kw-args rest)))))

(show 1)
(show #:init 0 1 2 3 #:extra 4)

(eval:no-prompt
 (define show2
   (make-keyword-procedure (lambda (kws kw-args . rest)
                             (list kws kw-args rest))
                           (lambda args
                             (list->vector args)))))
(show2 1)
(show2 #:init 0 1 2 3 #:extra 4)
]}

@defproc[(procedure-reduce-keyword-arity [proc procedure?]
                                         [arity procedure-arity?]
                                         [required-kws (listof keyword?)]
                                         [allowed-kws (or/c (listof keyword?)
                                                            #f)]
                                         [name (or/c symbol? #f) #f]
                                         [realm symbol? 'racket])
         procedure?]{

类似于 @racket[procedure-reduce-arity]，但根据 @racket[required-kws] 和 @racket[allowed-kws] 约束关键字参数，它们必须使用 @racket[keyword<?] 排序且不包含重复。如果 @racket[allowed-kws] 是 @racket[#f]，则结果过程仍然接受任何关键字，否则 @racket[required-kws] 中的关键字必须是 @racket[allowed-kws] 中关键字的子集。原始 @racket[proc] 不能要求比 @racket[required-kws] 中列出的更多的关键字，并且它必须至少允许 @racket[allowed-kws] 中的关键字（如果 @racket[allowed-kws] 是 @racket[#f]，则必须允许所有关键字）。

@examples[
(eval:no-prompt
 (define orig-show
   (make-keyword-procedure (lambda (kws kw-args . rest)
                             (list kws kw-args rest))))
 (define show (procedure-reduce-keyword-arity
               orig-show 3 '(#:init) '(#:extra #:init))))
(show #:init 0 1 2 3 #:extra 4)
(eval:error (show 1))
(eval:error (show #:init 0 1 2 3 #:extra 4 #:more 7))
]

@history[#:changed "8.4.0.2" @elem{Added the @racket[realm] argument.}]}


@defproc[(procedure-reduce-keyword-arity-mask [proc procedure?]
                                              [mask exact-integer?]
                                              [required-kws (listof keyword?)]
                                              [allowed-kws (or/c (listof keyword?)
                                                                  #f)]
                                              [name (or/c symbol? #f) #f]
                                              [realm symbol? 'racket])
         procedure?]{

与 @racket[procedure-reduce-keyword-arity] 相同，但使用 @racket[procedure-arity-mask] 描述的元数表示。

@history[#:added "7.0.0.11"
         #:changed "8.4.0.2" @elem{Added the @racket[realm] argument.}]}


@defstruct[arity-at-least ([value exact-nonnegative-integer?])]{

用于 @racket[procedure-arity] 结果的结构类型。另见 @racket[procedure-arity?]。}


@defthing[prop:procedure struct-type-property?]{

一个 @tech{structure type property}，用于标识其实例可以作为过程应用的结构类型。特别是，当对实例应用 @racket[procedure?] 时，结果将是 @racket[#t]，并且当实例用在应用表达式的函数位置时，会从实例中提取一个过程并用于完成过程调用。

如果 @racket[prop:procedure] 属性值是一个精确的非负整数，它指定结构中应包含过程的字段。该整数必须在 @racket[0]（含）和结构类型中非自动字段的数量（不含，不计入超类型字段）之间。指定字段还必须被指定为不可变的，以便在创建结构实例后，其过程不能被更改。（否则，实例的元数和名称可能会改变，而过程通常不允许此类修改。）当实例在应用表达式中用作过程时，实例中指定字段的值用于完成过程调用。（此过程可以是另一个充当过程的结构；过程字段的不可变性禁止过程图中的循环，因此过程调用最终将使用非结构过程继续。）该过程接收应用表达式中的所有参数。过程的名称（见 @racket[object-name]）、元数（见 @racket[procedure-arity]）和关键字协议（见 @racket[procedure-keywords]）也用于结构的名称、元数和关键字协议。如果指定字段中的值不是过程，则实例的行为类似于 @racket[(case-lambda)]（即，不接受任何数量参数的过程）。另见 @racket[procedure-extract-target]。

向 @racket[make-struct-type] 提供整数 @racket[proc-spec] 参数等同于同时使用 @racket[prop:procedure] 属性提供值并将该字段指定为不可变（因此属性的绑定或不可变指定是冗余的且不被允许）。

@examples[
(struct annotated-proc (base note)
  #:property prop:procedure
             (struct-field-index base))
(define plus1 (annotated-proc
                (lambda (x) (+ x 1))
                "adds 1 to its argument"))
(procedure? plus1)
(annotated-proc? plus1)
(plus1 10)
(annotated-proc-note plus1)
]

当 @racket[prop:procedure] 值是一个过程时，它应该接受至少一个非关键字参数。当结构的实例在应用表达式中使用时，属性值过程会被调用，实例作为第一个参数。属性值过程的其余参数是应用表达式中的参数（包括关键字参数）。因此，如果应用表达式提供五个非关键字参数，则属性值过程会被调用六个非关键字参数。实例的名称（见 @racket[object-name]）和关键字协议（见 @racket[procedure-keywords]）不受属性值过程的影响，但实例的元数是通过从属性值过程的每个可能的非关键字参数计数中减去一来确定的。如果属性值过程不能接受至少一个参数，则实例的行为类似于 @racket[(case-lambda)]。

向 @racket[make-struct-type] 提供过程 @racket[proc-spec] 参数等同于使用 @racket[prop:procedure] 属性提供值（因此特定的属性绑定不被允许）。

@mz-examples[
(struct fish (weight color)
  #:mutable
  #:property
  prop:procedure
  (lambda (f n)
    (let ([w (fish-weight f)])
      (set-fish-weight! f (+ n w)))))
(define wanda (fish 12 'red))
(fish? wanda)
(procedure? wanda)
(fish-weight wanda)
(for-each wanda '(1 2 3))
(fish-weight wanda)
]

如果为 @racket[prop:procedure] 属性提供的值不是精确的非负整数或过程，则 @exnraise[exn:fail:contract]。}

@defproc[(procedure-struct-type? [type struct-type?]) boolean?]{

如果 @racket[type] 表示的结构类型的实例是过程（根据 @racket[procedure?]）则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(procedure-extract-target [proc procedure?]) (or/c #f procedure?)]{

如果 @racket[proc] 是具有 @racket[prop:procedure] 属性的结构类型的实例，并且属性值指示结构的一个字段，并且该字段值是一个过程，则 @racket[procedure-extract-target] 返回该字段值。否则，结果为 @racket[#f]。

当 @racket[prop:procedure] 属性值是一个过程时，该过程@emph{不会}被 @racket[procedure-extract-target] 返回。这样的过程与通过结构字段访问的过程不同，因为它消费一个额外的参数，该参数始终是被应用为过程的结构。保持过程的私有性确保它始终以合适的第一个参数被调用。}

@defthing[prop:arity-string struct-type-property?]{

一个 @tech{structure type property}，用于在具有 @racket[prop:procedure] 属性的结构类型被应用于错误数量的参数时报告元数不匹配错误。@racket[prop:arity-string] 属性的值必须是一个接受单个参数（即被误用的结构）并返回字符串的过程。结果字符串用于单词 "expects" 之后，并且在错误消息中后跟实际参数的数量。

当 @racket[prop:arity-string] 属性不与过程结构类型关联时，元数不匹配报告会自动使用 @racket[procedure-extract-target]。

@examples[
(struct evens (proc)
  #:property prop:procedure (struct-field-index proc)
  #:property prop:arity-string
  (lambda (p)
    "an even number of arguments"))

(define pairs
  (evens
   (case-lambda
    [() null]
    [(a b . more)
     (cons (cons a b)
           (apply pairs more))])))

(pairs 1 2 3 4)
(eval:error (pairs 5))]}


@defthing[prop:checked-procedure struct-type-property?]{

一个与 @racket[checked-procedure-check-and-extract] 一起使用的 @tech{structure type property}，它是一个钩子，允许编译器提高关键字参数的性能。该属性只能附加到没有超类型且至少有两个字段的 @tech{structure type}。}


@defproc[(checked-procedure-check-and-extract [type struct-type?]
                                              [v any/c]
                                              [proc (any/c any/c any/c . -> . any/c)]
                                              [v1 any/c]
                                              [v2 any/c]) any/c]{

如果 @racket[v] 是 @racket[type] 的实例，则从中提取一个值，@racket[type] 必须具有 @racket[prop:checked-procedure] 属性。如果 @racket[v] 是这样的实例，则提取 @racket[v] 的第一个字段并将其应用于 @racket[v1] 和 @racket[v2]；如果结果为真值，则结果是 @racket[v] 的第二个字段的值。

如果 @racket[v] 不是 @racket[type] 的实例，或者 @racket[v] 的第一个字段应用于 @racket[v1] 和 @racket[v2] 产生 @racket[#f]，则将 @racket[proc] 应用于 @racket[v]、@racket[v1] 和 @racket[v2]，其结果由 @racket[checked-procedure-check-and-extract] 返回。}


@defproc[(procedure-specialize [proc procedure?])
         procedure?]{

返回 @racket[proc] 或其等价物，但向运行时系统提供一个提示，表示它应该花费额外的时间和内存来专门化 @racket[proc] 的实现。

该提示当前在 @racket[proc] 是 @racket[lambda] 或 @racket[case-lambda] 形式的值（该形式引用了在 @racket[lambda] 或 @racket[case-lambda] 之外绑定的变量），并且 @racket[proc] 之前没有被应用过时使用。

@history[#:added "6.3.0.10"]}

@; ----------------------------------------------------------------------

@section{反射原语}

@deftech{primitive procedure} 是一个内置过程，可能在较低级语言中实现。并非 @racketmodname[racket/base] 的所有过程都是原语，但很多是。原语与其他过程之间的区别可能对其他低级代码有用。

@defproc[(primitive? [v any/c]) boolean?]{

如果 @racket[v] 是原语过程则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(primitive-closure? [v any/c]) boolean?]{

如果 @racket[v] 内部实现为原语闭包而非简单原语过程则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(primitive-result-arity [prim primitive?]) procedure-arity?]{

返回原语过程 @racket[prim] 的结果的元数（与 @racket[procedure-arity] 返回的过程输入元数相对）。对于大多数原语，此过程返回 @racket[1]，因为大多数原语在应用时返回单个值。}

@; ----------------------------------------
@section{额外的高阶函数}

@note-lib[racket/function]
@(define fun-eval (make-base-eval))
@examples[#:hidden #:eval fun-eval (require racket/function)]

@defproc[(identity [v any/c]) any/c]{
返回 @racket[v]。
}

@defproc[(const [v any/c]) procedure?]{

返回一个接受任意参数（包括关键字参数）并返回 @racket[v] 的过程。

@mz-examples[#:eval fun-eval
((const 'foo))
((const 'foo) 1 2 3)
((const 'foo) 'a 'b #:c 'c)
]}

@defproc[(const* [v any/c] ...) procedure?]{

类似于 @racket[const]，但返回多个 @racket[v]。

@mz-examples[#:eval fun-eval
((const*))
((const*) 1 2 3)
((const*) 'a 'b #:c 'c)
((const* 'foo))
((const* 'foo) 1 2 3)
((const* 'foo) 'a 'b #:c 'c)
((const* 'foo 'foo))
((const* 'foo 'foo) 1 2 3)
((const* 'foo 'foo) 'a 'b #:c 'c)
]

@history[#:added "8.7.0.5"]}

@deftogether[(@defform[(thunk  body ...+)]
              @defform[(thunk* body ...+)])]{

@racket[thunk] 形式创建一个对给定 body 进行求值的零元函数。@racket[thunk*] 形式类似，除了结果函数接受任意参数（包括关键字参数）。

@examples[
#:eval fun-eval
(eval:no-prompt
 (define th1 (thunk (define x 1) (printf "~a\n" x))))
(th1)
(eval:error (th1 'x))
(eval:error (th1 #:y 'z))
(eval:no-prompt
 (define th2 (thunk* (define x 1) (printf "~a\n" x))))
(th2)
(th2 'x)
(th2 #:y 'z)
]}

@defproc[(negate [proc procedure?]) procedure?]{

返回一个与 @racket[proc] 类似的过程，除了它返回 @racket[proc] 结果的 @racket[not]。

@mz-examples[#:eval fun-eval
(filter (negate symbol?) '(1 a 2 b 3 c))
(map (negate =) '(1 2 3) '(1 1 1))
]}

@defproc[((conjoin [f procedure?] ...) [x any/c] ...) any]{

使用 @racket[and] 组合对每个函数的调用。等价于 @racket[(and (f x ...) ...)]

@examples[
#:eval fun-eval
(eval:no-prompt
 (define f (conjoin exact? integer?)))
(f 1)
(f 1.0)
(f 1/2)
(f 0.5)
((conjoin (λ (x) (values 1 2))) 0)
]

}

@defproc[((disjoin [f procedure?] ...) [x any/c] ...) any]{

使用 @racket[or] 组合对每个函数的调用。等价于 @racket[(or (f x ...) ...)]

@examples[
#:eval fun-eval
(eval:no-prompt
 (define f (disjoin exact? integer?)))
(f 1)
(f 1.0)
(f 1/2)
(f 0.5)
((disjoin (λ (x) (values 1 2))) 0)
]

}

@defproc*[([(curry [proc procedure?]) procedure?]
           [(curry [proc procedure?] [v any/c] ...+) any])]{

@racket[(curry proc)] 的结果是一个过程，它是 @racket[proc] 的柯里化版本。当结果过程首次被应用时，除非它被给定了根据 @racket[(procedure-arity proc)] 可以接受的最大数量的参数，否则结果是一个接受额外参数的过程。

@mz-examples[#:eval fun-eval
((curry list) 1 2)
((curry cons) 1)
((curry cons) 1 2)
]

在首次应用 @racket[(curry proc)] 的结果之后，每次进一步的应用都会累积参数，直到累积了根据 @racket[(procedure-arity proc)] 可接受的参数数量，此时原始的 @racket[proc] 被调用。

@mz-examples[#:eval fun-eval
(((curry list) 1 2) 3)
(((curry list) 1) 3)
((((curry foldl) +) 0) '(1 2 3))
(define foo (curry (lambda (x y z) (list x y z))))
(foo 1 2 3)
(((((foo) 1) 2)) 3)
]

函数调用 @racket[(curry proc v ...)] 等价于 @racket[((curry proc) v ...)]。换句话说，@racket[curry] 本身是柯里化的。

@mz-examples[#:eval fun-eval
  (map ((curry +) 10) '(1 2 3))
  (map (curry + 10) '(1 2 3))
  (map (compose (curry * 2) (curry + 10)) '(1 2 3))
]

@racket[curry] 函数也支持带关键字参数的函数：关键字参数将以与位置参数相同的方式累积，直到根据 @racket[(procedure-keywords proc)] 的所有必需关键字参数都已提供。

@mz-examples[#:eval fun-eval
  (eval:no-prompt
   (define (f #:a a #:b b #:c c)
     (list a b c)))
  (eval:check ((((curry f) #:a 1) #:b 2) #:c 3) (list 1 2 3))
  (eval:check ((((curry f) #:b 1) #:c 2) #:a 3) (list 3 1 2))
  (eval:check ((curry f #:a 1 #:c 2) #:b 3) (list 1 3 2))
]

@history[#:changed "7.0.0.7" @elem{Added support for keyword arguments.}]}

@defproc*[([(curryr [proc procedure?]) procedure?]
           [(curryr [proc procedure?] [v any/c] ...+) any])]{

类似于 @racket[curry]，但参数以相反方向收集：第一步收集最右边的一组参数，后续步骤将参数添加到这些参数的左侧。

@mz-examples[#:eval fun-eval
  (map (curryr list 'foo) '(1 2 3))
]}

@defproc[(normalized-arity? [arity any/c]) boolean?]{

规范化的元数具有以下形式之一：
@itemize[
@item{空列表；}
@item{一个精确的非负整数；}
@item{一个 @racket[arity-at-least] 实例；}
@item{一个包含两个或更多严格递增的精确非负整数的列表；或}
@item{一个包含一个或多个严格递增的精确非负整数，后跟一个 @racket[arity-at-least] 实例的列表，该实例的值比前一个整数至少大 2。}
]
每个规范化的元数都是有效的过程元数并满足 @racket[procedure-arity?]。任何两个 @racket[arity=?] 的规范化元数值也必须 @racket[equal?]。

@mz-examples[#:eval fun-eval
(normalized-arity? (arity-at-least 1))
(normalized-arity? (list (arity-at-least 1)))
(normalized-arity? (list 0 (arity-at-least 2)))
(normalized-arity? (list (arity-at-least 2) 0))
(normalized-arity? (list 0 2 (arity-at-least 3)))
]

}

@defproc[(normalize-arity [arity procedure-arity?])
         (and/c normalized-arity? (lambda (x) (arity=? x arity)))]{

产生 @racket[arity] 的规范化形式。另见 @racket[normalized-arity?] 和 @racket[arity=?]。

@mz-examples[#:eval fun-eval
(normalize-arity 1)
(normalize-arity (list 1))
(normalize-arity (arity-at-least 2))
(normalize-arity (list (arity-at-least 2)))
(normalize-arity (list 1 (arity-at-least 2)))
(normalize-arity (list (arity-at-least 2) 1))
(normalize-arity (list (arity-at-least 2) 3))
(normalize-arity (list 3 (arity-at-least 2)))
(normalize-arity (list (arity-at-least 6) 0 2 (arity-at-least 4)))
]

}

@defproc[(arity=? [a procedure-arity?] [b procedure-arity?]) boolean?]{

如果具有元数 @racket[a] 和 @racket[b] 的过程接受相同数量的参数则返回 @racket[#true]，否则返回 @racket[#false]。等价于 @racket[(and (arity-includes? a b) (arity-includes? b a))] 和 @racket[(equal? (normalize-arity a) (normalize-arity b))]。

@mz-examples[#:eval fun-eval
(arity=? 1 1)
(arity=? (list 1) 1)
(arity=? 1 (list 1))
(arity=? 1 (arity-at-least 1))
(arity=? (arity-at-least 1) 1)
(arity=? (arity-at-least 1) (list 1 (arity-at-least 2)))
(arity=? (list 1 (arity-at-least 2)) (arity-at-least 1))
(arity=? (arity-at-least 1) (list 1 (arity-at-least 3)))
(arity=? (list 1 (arity-at-least 3)) (arity-at-least 1))
(arity=? (list 0 1 2 (arity-at-least 3)) (list (arity-at-least 0)))
(arity=? (list (arity-at-least 0)) (list 0 1 2 (arity-at-least 3)))
(arity=? (list 0 2 (arity-at-least 3)) (list (arity-at-least 0)))
(arity=? (list (arity-at-least 0)) (list 0 2 (arity-at-least 3)))
]

}

@defproc[(arity-includes? [a procedure-arity?] [b procedure-arity?]) boolean?]{

如果具有元数 @racket[a] 的过程接受具有元数 @racket[b] 的过程所接受的任意数量的参数则返回 @racket[#true]。

@mz-examples[#:eval fun-eval
(arity-includes? 1 1)
(arity-includes? (list 1) 1)
(arity-includes? 1 (list 1))
(arity-includes? 1 (arity-at-least 1))
(arity-includes? (arity-at-least 1) 1)
(arity-includes? (arity-at-least 1) (list 1 (arity-at-least 2)))
(arity-includes? (list 1 (arity-at-least 2)) (arity-at-least 1))
(arity-includes? (arity-at-least 1) (list 1 (arity-at-least 3)))
(arity-includes? (list 1 (arity-at-least 3)) (arity-at-least 1))
(arity-includes? (list 0 1 2 (arity-at-least 3)) (list (arity-at-least 0)))
(arity-includes? (list (arity-at-least 0)) (list 0 1 2 (arity-at-least 3)))
(arity-includes? (list 0 2 (arity-at-least 3)) (list (arity-at-least 0)))
(arity-includes? (list (arity-at-least 0)) (list 0 2 (arity-at-least 3)))
]

}


@close-eval[fun-eval]
