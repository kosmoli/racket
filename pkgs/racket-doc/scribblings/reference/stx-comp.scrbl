#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/phase+space))

@(define stx-eval (make-base-eval))
@examples[#:hidden #:eval stx-eval (require (for-syntax racket/base))]

@title[#:tag "stxcmp"]{Syntax Object Bindings}

@defproc[(bound-identifier=? [a-id syntax?] [b-id syntax?]
                             [phase-level (or/c exact-integer? #f)
                                          (syntax-local-phase-level)])
         boolean?]{

如果标识符 @racket[a-id] 在由 @racket[phase-level] 指示的 @tech{phase level} 的合适表达式上下文中替换时会绑定 @racket[b-id]（或反之），返回 @racket[#t]，否则返回 @racket[#f]。@racket[phase-level] 的 @racket[#f] 值对应于 @tech{label phase level}。

@examples[
#:eval stx-eval
(define-syntax (check stx)
  (syntax-case stx ()
    [(_ x y)
     (if (bound-identifier=? #'x #'y)
         #'(let ([y 'wrong]) (let ([x 'binds]) y))
         #'(let ([y 'no-binds]) (let ([x 'wrong]) y)))]))
(check a a)
(check a b)
(define-syntax-rule (check-a x) (check a x))
(check-a a)
]}


@defproc[(free-identifier=? [a-id identifier?] [b-id identifier?]
                            [a-phase-level (or/c exact-integer? #f)
                                           (syntax-local-phase-level)]
                            [b-phase-level (or/c exact-integer? #f)
                                           a-phase-level])
         boolean?]{

如果 @racket[a-id] 和 @racket[b-id] 在 @racket[a-phase-level] 和 @racket[b-phase-level] 指示的 @tech{phase levels} 上访问相同的 @tech{local binding}、@tech{module binding} 或 @tech{top-level binding}（可能通过 @tech{rename transformers}），返回 @racket[#t]。@racket[a-phase-level] 或 @racket[b-phase-level] 的 @racket[#f] 值对应于 @tech{label phase level}。

"相同的 module binding" 标识符指的是相同的原始定义位置，而不一定是相同的 @racket[require] 或 @racket[provide] 位置。由于在 @racket[require] 和 @racket[provide] 中的重命名，或者由于绑定到 @tech{rename transformer} 的 transformer binding，标识符可能通过 @racket[syntax-e] 返回不同的结果。

@examples[
#:eval stx-eval
(define-syntax (check stx)
  (syntax-case stx ()
    [(_ x)
     (if (free-identifier=? #'car #'x)
         #'(list 'same: x)
         #'(list 'different: x))]))
(check car)
(check mcar)
(let ([car list])
  (check car))
(require (rename-in racket/base [car kar]))
(check kar)
]}

@defproc[(free-transformer-identifier=? [a-id identifier?] [b-id identifier?]) boolean?]{

与 @racket[(free-identifier=? a-id b-id (add1 (syntax-local-phase-level)))] 相同。}

@defproc[(free-template-identifier=? [a-id identifier?] [b-id identifier?]) boolean?]{

与 @racket[(free-identifier=? a-id b-id (sub1 (syntax-local-phase-level)))] 相同。}

@defproc[(free-label-identifier=? [a-id identifier?] [b-id identifier?]) boolean?]{

与 @racket[(free-identifier=? a-id b-id #f)] 相同。}


@defproc[(check-duplicate-identifier [ids (listof identifier?)])
         (or/c identifier? #f)]{

使用 @racket[bound-identifier=?] 将 @racket[ids] 中的每个标识符与列表中的其他每个标识符进行比较。如果任何比较返回 @racket[#t]，则返回其中一个重复的标识符（@racket[ids] 中第一个重复的），否则结果为 @racket[#f]。}


@defproc[(identifier-binding [id-stx identifier?]
                             [phase-level (or/c exact-integer? #f)
                                          (syntax-local-phase-level)]
                             [top-level-symbol? any/c #f]
                             [exact-scopes? any/c #f])
         (or/c 'lexical
               #f
               (list/c module-path-index?
                       symbol?
                       module-path-index?
                       symbol?
                       exact-nonnegative-integer?
                       phase+space-shift?
                       phase+space?)
               (list/c symbol?))]{

根据 @racket[id-stx] 在 @racket[phase-level] 指示的 @tech{phase level}（其中 @racket[phase-level] 的 @racket[#f] 值对应于 @tech{label phase level}）的绑定，返回三种（如果 @racket[top-level-symbol?] 为 @racket[#f]）或四种（如果 @racket[top-level-symbol?] 为真）值：

@itemize[ 

      @item{如果 @racket[id-stx] 有 @tech{local binding}，结果为 @indexed-racket['lexical]。}

      @item{如果 @racket[id-stx] 有 @tech{module binding}，结果是一个七项列表：@racket[(list _from-mod _from-sym _nominal-from-mod _nominal-from-sym _from-phase _import-phase+space-shift _nominal-export-phase)]。

        @itemize[

        @item{@racket[_from-mod] 是一个 module path index（参见 @secref["modpathidx"]），指示定义模块。如果绑定指向 @racket[id-stx] 的封闭模块中的定义，则为 "self" module path index。}

        @item{@racket[_from-sym] 是一个符号，表示标识符在源模块定义位置的名称。由于以下原因，这可能与 @racket[syntax->datum] 返回的本地名称不同：标识符在 import 时被重命名，在 export 时被重命名，或者因为绑定位置由 macro invocation 生成而隐式重命名。最后一种情况下，它可能是 @tech{unreadable symbol}，并且可能与在原始 source definition 上调用 @racket[syntax->datum] 的结果不同。}

        @item{@racket[_nominal-from-mod] 是一个 module path index（参见 @secref["modpathidx"]），指示绑定模块在 @racket[id-stx] 周围的 source 中本地显示的方式：它指示被 @racket[require] 到 @racket[id-stx] 的上下文中以提供其绑定的模块，或者对于指向 @racket[id-stx] 的封闭模块中定义的绑定，指示与 @racket[_from-mod] 相同。它可能与 @racket[_from-mod] 不同，因为 @racket[_nominal-from-mod] 重新导入了某些标识符。如果同一绑定以多种方式导入，则选择一个代表性绑定。}

        @item{@racket[_nominal-from-sym] 是一个符号，表示绑定的标识符在 @racket[id-stx] 周围的 source 中本地显示的方式：它是 @racket[_nominal-from-mod] 导出的标识符的名称，或者对于 @racket[id-stx] 的封闭模块内的定义，它是源标识符的 symbol。它可能与 @racket[_from-sym] 不同，因为 @racket[provide] 重命名，即使 @racket[_from-mod] 和 @racket[_nominal-from-mod] 相同，或者因为定义是由 macro expansion 引入的。}

        @item{@racket[_from-phase] 是一个精确的表示起始 phase 的非负整数。例如，如果定义是 for-syntax，则为 @racket[1]。}

        @item{@racket[_import-phase+space-shift] 在 @racket[_nominal-from-mode] 的定义或 plain @racket[require] 导入绑定时为 @racket[0]，在 @racket[for-syntax] 导入时为 @racket[1]，在带有 phase 和 space 的 @racket[for-space] 导入时为 phase 与 space 的组合，等等。}

        @item{@racket[_nominal-export-phase+space] 是从导入绑定的 @racket[_nominal-from-mod] 导出的 @tech{phase level} 和 @tech{binding space}，或者是 @racket[id-stx] 封闭模块中定义的 phase level。}

        ]}

      @item{如果 @racket[id-stx] 有 @tech{top-level binding} 且 @racket[top-level-symbol?] 为真，结果为 @racket[(list _top-sym)]。当绑定定义由 macro invocation 生成时，@racket[_top-sym] 可能与 @racket[syntax->datum] 返回的名称不同。}

      @item{如果 @racket[id-stx] 有 @tech{top-level binding} 且 @racket[top-level-symbol?] 为 @racket[#f]，或者 @racket[id-stx] 是 @tech{unbound}，结果为 @racket[#f]。未绑定的标识符通常被视为顶级绑定为变量的标识符。}

      ]

如果 @racket[id-stx] 绑定到 @tech{rename-transformer}，@racket[identifier-binding] 的结果是关于 transformer 中的标识符的，以便 @racket[identifier-binding] 与 @racket[free-identifier=?] 一致。

如果 @racket[exact-scopes?] 为真值，则除非 @racket[id-stx] 的绑定具有与 @racket[id-stx] 完全相同的 @tech{scopes}，否则结果为 @racket[#f]。exact-scopes 检查可用于检测标识符是否已在特定定义上下文中绑定。

@history[#:changed "6.6.0.4" @elem{添加了 @racket[top-level-symbol?] 参数以报告 top-level bindings 的信息。}
        #:changed "8.2.0.3" @elem{将 phase 结果推广为 phase--space 组合。}
        #:changed "8.6.0.9" @elem{添加了 @racket[exact-scopes?] 参数。}]}


@defproc[(identifier-transformer-binding [id-stx identifier?]
                                         [rt-phase-level (or/c exact-integer? #f)
                                                         (syntax-local-phase-level)])
         (or/c 'lexical
               #f
               (listof module-path-index?
                       symbol?
                       module-path-index?
                       symbol?
                       exact-nonnegative-integer?
                       phase+space-shift?
                       phase+space?))]{

与 @racket[(identifier-binding id-stx (and rt-phase-level (add1 rt-phase-level)))] 相同。

@history[#:changed "8.2.0.3" @elem{将 phase 结果推广为 phase--space 组合。}]}


@defproc[(identifier-template-binding [id-stx identifier?])
         (or/c 'lexical
               #f
               (listof module-path-index?
                       symbol?
                       module-path-index?
                       symbol?
                       phase+space?
                       phase+space-shift?
                       phase+space?))]{

与 @racket[(identifier-binding id-stx (sub1 (syntax-local-phase-level)))] 相同。

@history[#:changed "8.2.0.3" @elem{将 phase 结果推广为 phase--space 组合。}]}


@defproc[(identifier-label-binding [id-stx identifier?])
         (or/c 'lexical
               #f
               (listof module-path-index?
                       symbol?
                       module-path-index?
                       symbol?
                       exact-nonnegative-integer?
                       phase+space-shift?
                       phase+space?))]{

与 @racket[(identifier-binding id-stx #f)] 相同。

@history[#:changed "8.2.0.3" @elem{将 phase 结果推广为 phase--space 组合。}]}


@defproc[(identifier-distinct-binding [id-stx identifier?]
                                      [wrt-id-stx identifier?]
                                      [phase-level (or/c exact-integer? #f)
                                                   (syntax-local-phase-level)]
                                      [top-level-symbol? any/c #f])
         (or/c 'lexical
               #f
               (list/c module-path-index?
                       symbol?
                       module-path-index?
                       symbol?
                       exact-nonnegative-integer?
                       phase+space-shift?
                       phase+space?)
               (list/c symbol?))]{

类似于 @racket[(identifier-binding id-stx phase-level top-level-symbol?)]，但如果 @racket[id-stx] 的绑定具有的作用域是 @racket[wrt-id-stx] 作用域的子集，则结果为 @racket[#f]。即，如果 @racket[id-stx] 和 @racket[wrt-id-stx] 具有相同的符号名称，则仅当该绑定不适用于 @racket[wrt-id-stx] 时，才返回 @racket[id-stx] 的绑定。

@history[#:added "8.3.0.8"
         #:changed "8.8.0.2" @elem{添加了 @racket[top-level-symbol?] 参数。}]}


@defproc[(identifier-binding-symbol [id-stx identifier?]
                                    [phase-level (or/c exact-integer? #f)
                                                 (syntax-local-phase-level)])
         symbol?]{

类似于 @racket[identifier-binding]，但产生一个对应于绑定的 symbol。symbol 结果对任何 @racket[free-identifier=?] 的标识符都相同，但对于非 @racket[free-identifier=?] 的标识符也可能相同（即，不同的 symbol 意味着不同的绑定，但相同的 symbol 并不意味着相同的绑定）。

当 @racket[identifier-binding] 产生一个列表时，该列表的第二个元素就是 @racket[identifier-binding-symbol] 产生的结果。}


@defproc[(identifier-binding-portal-syntax [id-stx identifier?]
                                           [phase-level (or/c exact-integer? #f)
                                                        (syntax-local-phase-level)])
         (or/c #f syntax?)]{

如果 @racket[id-stx] 在 @racket[phase-level] 绑定到 @tech{portal syntax}（无论是通过 @racket[define-syntax] 还是 @racket[#%require]），则返回 portal syntax 的内容。绑定 @racket[id-stx] 的模块必须被声明，但不需要在相关 phase 实例化，@racket[identifier-binding-portal-syntax] 不会实例化模块。

@history[#:added "8.3.0.8"]}

@defproc[(syntax-bound-symbols [stx syntax?]
                               [phase-level (or/c exact-integer? #f)
                                            (syntax-local-phase-level)]
                               [exact-scopes? any/c #f])
         (listof symbol?)]{

返回所有 @tech{interned} symbols 的列表，对于这些 symbols，@racket[(identifier-binding (datum->syntax stx _sym) phase-level #f exact-scopes?)] 会产生一个非 @racket[#f] 值。此过程所花的时间与 @racket[stx] 的 scopes 数量加上结果列表的长度成正比。

@history[#:added "8.6.0.6"
         #:changed "8.6.0.9" @elem{添加了 @racket[exact-scopes?] 参数。}]}


@defproc[(syntax-bound-interned-scope-symbols [stx syntax?]
                                              [phase-level (or/c exact-integer? #f)
                                                           (syntax-local-phase-level)]
                                              [exact-scopes? any/c #f])
         (listof symbol?)]{

返回所有 @tech{interned scopes} 的 @racket[_sym] 名称的列表，对于这些名称，@racket[(identifier-binding ((make-interned-syntax-introducer _sym) stx) phase-level #f exact-scopes?)] 可能会产生一个非 @racket[#f] 值。此过程所花的时间与 @racket[stx] 的 scopes 数量加上结果列表的长度成正比。

@history[#:added "8.13.0.8"]}


@defproc[(syntax-bound-phases [stx syntax?])
         (listof (or/c exact-integer? #f))]{

返回一个列表，包含所有 @racket[_phase-level]s，对于这些 levels，@racket[(syntax-bound-symbols stx _phase-level)] 可能会产生非空列表。

@examples[
#:eval stx-eval
(syntax-bound-phases #'anything)
(require (for-meta 8 racket/base))
(syntax-bound-phases #'anything)
]

@history[#:added "8.6.0.8"]}

@close-eval[stx-eval]
