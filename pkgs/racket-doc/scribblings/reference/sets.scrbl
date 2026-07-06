#lang scribble/doc
@(require "mz.rkt" (for-label racket/set))

@title[#:tag "sets"]{集合}
@(define set-eval (make-base-eval))
@examples[#:hidden #:eval set-eval (require racket/set)]

@(define (hash-set-caveats)
   @elem{对于 @tech{hash sets}，另请参见 @concurrency-caveat[] 中适用于 hash sets 的
         hash table 说明。})

一个 @deftech{set} 表示一组不同元素的集合。以下数据类型都是集合：

@itemize[

  @item{@techlink{hash sets};}

  @item{@techlink{lists} using @racket[equal?] to compare elements; and}

  @item{@techlink{structures} whose types implement the @racket[gen:set]
        @tech{generic interface}.}

]

@note-lib[racket/set]

@section{Hash Sets}

一个 @deftech{hash set} 是一个集合，其元素通过 @racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?] 进行比较，并通过 @racket[equal-hash-code]、@racket[equal-always-hash-code]、@racket[eqv-hash-code] 或 @racket[eq-hash-code] 进行分区。hash set 可以是不可变或可变的；可变 hash set 要么强保留要么弱保留其元素。

@margin-note{Like operations on immutable hash tables, ``constant time'' hash
集合操作实际上对于大小为
@math{N}.}

hash set 可以用作 @tech{stream}（参见 @secref["streams"]），因此也可以用作单值的 @tech{sequence}（参见 @secref["sequences"]）。集合的元素作为 stream 或 sequence 的元素。如果在迭代过程中向 hash set 添加或删除元素，则迭代步骤可能因 @racket[exn:fail:contract] 失败，或者迭代可能跳过或重复元素。另请参见 @racket[in-set]。

当两个 hash set 使用相同的元素比较过程（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）、都以强或弱方式持有元素、具有相同的可变性且具有等价元素时，它们是 @racket[equal?] 的。不可变 hash set 支持有效的常数时间访问和更新，与可变 hash set 一样；不可变操作的常数通常更大，但不可变 hash set 的函数性质在某些算法中可以获得优势。

所有 hash set 都 @impl{实现} @racket[set->stream]、
@racket[set-empty?], @racket[set-member?], @racket[set-count],
@racket[subset?], @racket[proper-subset?], @racket[set-map],
@racket[set-for-each], @racket[set-copy], @racket[set-copy-clear],
@racket[set->list], and @racket[set-first].  Immutable hash sets in
额外 @impl{实现} @racket[set-add]、@racket[set-remove]、
@racket[set-clear], @racket[set-union], @racket[set-intersect],
@racket[set-subtract], and @racket[set-symmetric-difference].  Mutable
hash set 额外 @impl{实现} @racket[set-add!]、
@racket[set-remove!], @racket[set-clear!], @racket[set-union!],
@racket[set-intersect!], @racket[set-subtract!], and
@racket[set-symmetric-difference!].

对包含被修改元素的集合的操作是不可预测的，与 @tech{hash table} 操作在键被修改时不可预测的方式非常相似。

@deftogether[(
@defproc[(set-equal? [x any/c]) boolean?]
@defproc[(set-equal-always? [x any/c]) boolean?]
@defproc[(set-eqv? [x any/c]) boolean?]
@defproc[(set-eq? [x any/c]) boolean?]
)]{

如果 @racket[x] 是分别使用 @racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?] 比较元素的 @tech{hash set}，则返回 @racket[#t]；否则返回 @racket[#f]。

@history[#:changed "8.5.0.3" @elem{Added @racket[set-equal-always?].}]}

@deftogether[(
@defproc[(set? [x any/c]) boolean?]
@defproc[(set-mutable? [x any/c]) boolean?]
@defproc[(set-weak? [x any/c]) boolean?]
)]{

如果 @racket[x] 是分别是不可变的、强保留键的可变、或弱保留键的可变 @tech{hash set}，则返回 @racket[#t]；否则返回 @racket[#f]。

}

@deftogether[(
@defproc[(set [v any/c] ...) (and/c generic-set? set-equal? set?)]
@defproc[(setalw [v any/c] ...)
         (and/c generic-set? set-equal-always? set?)]
@defproc[(seteqv [v any/c] ...) (and/c generic-set? set-eqv? set?)]
@defproc[(seteq [v any/c] ...) (and/c generic-set? set-eq? set?)]
@defproc[(mutable-set [v any/c] ...) (and/c generic-set? set-equal? set-mutable?)]
@defproc[(mutable-setalw [v any/c] ...)
         (and/c generic-set? set-equal-always? set-mutable?)]
@defproc[(mutable-seteqv [v any/c] ...) (and/c generic-set? set-eqv? set-mutable?)]
@defproc[(mutable-seteq [v any/c] ...) (and/c generic-set? set-eq? set-mutable?)]
@defproc[(weak-set [v any/c] ...) (and/c generic-set? set-equal? set-weak?)]
@defproc[(weak-setalw [v any/c] ...)
         (and/c generic-set? set-equal-always? set-weak?)]
@defproc[(weak-seteqv [v any/c] ...) (and/c generic-set? set-eqv? set-weak?)]
@defproc[(weak-seteq [v any/c] ...) (and/c generic-set? set-eq? set-weak?)]
)]{

创建一个以给定 @racket[v] 为元素的 @tech{hash set}。元素按参数出现的顺序添加，因此对于使用 @racket[equal?]、@racket[equal-always?] 或 @racket[eqv?] 的集合，较早的元素可能被 @racket[equal?]、@racket[equal-always?] 或 @racket[eqv?]（但不是 @racket[eq?]）的较晚元素替换。

@history[#:changed "8.5.0.3" @elem{Added @racket[setalw],
                                   @racket[mutable-setalw], and @racket[weak-setalw].}]}

@deftogether[(
@defproc[(list->set [lst list?]) (and/c generic-set? set-equal? set?)]
@defproc[(list->setalw [lst list?])
         (and/c generic-set? set-equal-always? set?)]
@defproc[(list->seteqv [lst list?]) (and/c generic-set? set-eqv? set?)]
@defproc[(list->seteq [lst list?]) (and/c generic-set? set-eq? set?)]
@defproc[(list->mutable-set [lst list?]) (and/c generic-set? set-equal? set-mutable?)]
@defproc[(list->mutable-setalw [lst list?])
         (and/c generic-set? set-equal-always? set-mutable?)]
@defproc[(list->mutable-seteqv [lst list?]) (and/c generic-set? set-eqv? set-mutable?)]
@defproc[(list->mutable-seteq [lst list?]) (and/c generic-set? set-eq? set-mutable?)]
@defproc[(list->weak-set [lst list?]) (and/c generic-set? set-equal? set-weak?)]
@defproc[(list->weak-setalw [lst list?])
         (and/c generic-set? set-equal-always? set-weak?)]
@defproc[(list->weak-seteqv [lst list?]) (and/c generic-set? set-eqv? set-weak?)]
@defproc[(list->weak-seteq [lst list?]) (and/c generic-set? set-eq? set-weak?)]
)]{

创建一个以给定 @racket[lst] 的元素为集合元素的 @tech{hash set}。分别等价于 @racket[(apply set lst)]、@racket[(apply setalw lst)]、@racket[(apply seteqv lst)]、@racket[(apply seteq lst)] 等。

@history[#:changed "8.5.0.3" @elem{Added @racket[list->setalw],
                                   @racket[list->mutable-setalw], and @racket[list->weak-setalw].}]}

@deftogether[(
@defform[(for/set (for-clause ...) body ...+)]
@defform[(for/seteq (for-clause ...) body ...+)]
@defform[(for/seteqv (for-clause ...) body ...+)]
@defform[(for/setalw (for-clause ...) body ...+)]
@defform[(for*/set (for-clause ...) body ...+)]
@defform[(for*/seteq (for-clause ...) body ...+)]
@defform[(for*/seteqv (for-clause ...) body ...+)]
@defform[(for*/setalw (for-clause ...) body ...+)]
@defform[(for/mutable-set (for-clause ...) body ...+)]
@defform[(for/mutable-seteq (for-clause ...) body ...+)]
@defform[(for/mutable-seteqv (for-clause ...) body ...+)]
@defform[(for/mutable-setalw (for-clause ...) body ...+)]
@defform[(for*/mutable-set (for-clause ...) body ...+)]
@defform[(for*/mutable-seteq (for-clause ...) body ...+)]
@defform[(for*/mutable-seteqv (for-clause ...) body ...+)]
@defform[(for*/mutable-setalw (for-clause ...) body ...+)]
@defform[(for/weak-set (for-clause ...) body ...+)]
@defform[(for/weak-seteq (for-clause ...) body ...+)]
@defform[(for/weak-seteqv (for-clause ...) body ...+)]
@defform[(for/weak-setalw (for-clause ...) body ...+)]
@defform[(for*/weak-set (for-clause ...) body ...+)]
@defform[(for*/weak-seteq (for-clause ...) body ...+)]
@defform[(for*/weak-seteqv (for-clause ...) body ...+)]
@defform[(for*/weak-setalw (for-clause ...) body ...+)]
)]{

类似于 @racket[for/list] 和 @racket[for*/list]，但用于构造 @tech{hash set} 而不是 list。

@history[#:changed "8.5.0.3" @elem{Added @racket[for/setalw],
                                   @racket[for/mutable-setalw], and @racket[for/weak-setalw].}]}


@deftogether[(
@defproc[(in-immutable-set [st set?]) sequence?]
@defproc[(in-mutable-set [st set-mutable?]) sequence?]
@defproc[(in-weak-set [st set-weak?]) sequence?]
)]{

显式将特定类型的 @tech{hash set} 转换为 sequence 以用于 @racket[for] 形式。

与 @racket[in-list] 和其他一些 sequence 构造函数一样，@racket[in-immutable-set] 直接出现在 @racket[for] 子句中时表现更好。

这些 sequence 构造函数与 @secref["Custom_Hash_Sets" #:doc '(lib "scribblings/reference/reference.scrbl")] 兼容。

@history[#:added "6.4.0.7"]
}

@section{Set Predicates and Contracts}

@defproc[(generic-set? [v any/c]) boolean?]{

如果 @racket[v] 是一个 @tech{set}，则返回 @racket[#t]；否则返回 @racket[#f]。

@examples[
#:eval set-eval
(generic-set? (list 1 2 3))
(generic-set? (set 1 2 3))
(generic-set? (mutable-seteq 1 2 3))
(generic-set? (vector 1 2 3))
]

}

@defproc[(set-implements? [st generic-set?] [sym symbol?] ...) boolean?]{

如果 @racket[st] 实现了所有由 @racket[sym] 命名的 @racket[gen:set] 方法，则返回 @racket[#t]；否则返回 @racket[#f]。fallback 实现不影响结果；@racket[st] 可能通过 fallback 实现支持给定方法但仍然产生 @racket[#f]。

@examples[
#:eval set-eval
(set-implements? (list 1 2 3) 'set-add)
(set-implements? (list 1 2 3) 'set-add!)
(set-implements? (set 1 2 3) 'set-add)
(set-implements? (set 1 2 3) 'set-add!)
(set-implements? (mutable-seteq 1 2 3) 'set-add)
(set-implements? (mutable-seteq 1 2 3) 'set-add!)
(set-implements? (weak-seteqv 1 2 3) 'set-remove 'set-remove!)
]

}

@defproc[(set-implements/c [sym symbol?] ...) flat-contract?]{

识别支持由 @racket[sym] 命名的所有 @racket[gen:set] 方法的集合。

}

@defproc[(set/c [elem/c chaperone-contract?]
                [#:cmp cmp
                 (or/c 'dont-care 'equal 'equal-always 'eqv 'eq)
                 'dont-care]
                [#:kind kind 
                 (or/c 'dont-care 'immutable 'mutable 'weak 'mutable-or-weak)
                 'immutable]
                [#:lazy? lazy? any/c
                 (not (and (equal? kind 'immutable)
                           (flat-contract? elem/c)))]
                [#:equal-key/c equal-key/c contract? any/c])
         contract?]{

  构造一个 contract，其识别的集合的元素匹配 @racket[elem/c]。

  如果 @racket[kind] 是 @racket['immutable]、@racket['mutable] 或 @racket['weak]，则生成的 contract 仅接受分别是不可变的、强保留键的可变、或弱保留键的可变 @tech{hash sets}。如果 @racket[kind] 是 @racket['mutable-or-weak]，则生成的 contract 接受任何可变 @tech{hash sets}，无论键保留强度如何。

  如果 @racket[cmp] 是 @racket['equal]、@racket['equal-always]、@racket['eqv] 或 @racket['eq]，则生成的 contract 仅接受分别使用 @racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?] 比较元素的 @tech{hash sets}。

  如果 @racket[cmp] 是 @racket['eqv] 或 @racket['eq]，则 @racket[elem/c] 必须是 @tech{flat contract}。

  如果 @racket[cmp] 和 @racket[kind] 都是 @racket['dont-care]，则生成的 contract 将接受任何类型的集合，而不仅仅是 @tech{hash sets}。

 如果 @racket[lazy?] 不是 @racket[#f]，则集合的元素不会立即被 contract 检查，只检查集合本身（根据 @racket[cmp] 和 @racket[kind] 参数）。如果 @racket[lazy?] 是 @racket[#f]，则元素立即被 contract 检查。当集合 contract 接受泛型集合（即 @racket[cmp] 和 @racket[kind] 都是 @racket['dont-care]）时，@racket[lazy?] 参数被忽略；在这种情况下，如果被检查的值是 @racket[list?]，则 contract 不是惰性的，否则 contract 是惰性的。
 
 如果 @racket[kind] 允许可变集合（即 @racket['dont-care]、@racket['mutable]、@racket['weak] 或 @racket['mutable-or-weak]）且 @racket[lazy?] 是 @racket[#f]，则元素在立即检查的同时，在从集合访问时也会被检查。

 @racket[equal-key/c] contract 在值传递给内部使用的比较和 hash 函数时使用。
 
 当 @racket[elem/c] 和 @racket[equal-key/c] 都是 @tech{flat contracts}、@racket[lazy?] 是 @racket[#f] 且 @racket[kind] 是 @racket['immutable] 时，结果 contract 将是 @tech{flat contract}。当 @racket[elem/c] 是 @tech{chaperone contract} 时，结果将是 @tech{chaperone contract}。

 @history[#:changed "8.3.0.9" @elem{Added support for random generation.}
          #:changed "8.5.0.3" @elem{Added @racket['equal-always] support for @racket[cmp].}]
}

@section{Generic Set Interface}


@defidform[gen:set]{

一个 @tech{generic interface}（参见 @secref["struct-generics"]），通过 @racket[struct] 定义的 @racket[#:methods] 选项为 structure type 提供集合方法实现。此接口可用于实现任何记录在 @secref["set-methods"] 中的方法。

集合也应当是一个 @tech{sequence}，但 @racket[gen:set] 本身并不隐含 @racket[prop:sequence]。使用 @racket[gen:set] 通常应当结合 @racket[prop:sequence] 与 @racket[in-set] 或更具体的 sequence 构造函数一起使用。注意 @racket[in-set] 需要 @supp{支持} @racket[set->stream]（例如通过实现 @racket[set->stream] 或其他支持组合，如 @racket[set-first]、@racket[set-remove] 和 @racket[set-empty?]）。

@examples[
#:eval set-eval
(struct binary-set [integer]
  #:transparent
  #:methods gen:set
  [(define (set-member? st i)
     (bitwise-bit-set? (binary-set-integer st) i))
   (define (set-add st i)
     (binary-set (bitwise-ior (binary-set-integer st)
                              (arithmetic-shift 1 i))))
   (define (set-remove st i)
     (binary-set (bitwise-and (binary-set-integer st)
                              (bitwise-not (arithmetic-shift 1 i)))))
   (define (set-first st)
     (sub1 (integer-length (binary-set-integer st))))
   (define (set-empty? st)
     (= (binary-set-integer st) 0))]
  #:property prop:sequence in-set)
(define bset (binary-set 5))
bset
(generic-set? bset)
(set-member? bset 0)
(set-member? bset 1)
(set-member? bset 2)
(set-add bset 4)
(set-remove bset 2)
(set-first bset)
(require racket/sequence)
(sequence->list bset)
]

}

@subsection[#:tag "set-methods"]{Set Methods}

@(define (supp . args) (apply tech #:key "supported generic method" args))
@(define (impl . args) (apply tech #:key "implemented generic method" args))

@racket[gen:set] 的方法可以分为三类，由其 fallback 实现决定：

@itemlist[#:style 'ordered
          @item{没有 fallback 的方法，}
          @item{其 fallback 依赖于其他非 fallback 方法的方法，}
          @item{以及其 fallback 可以依赖于 fallback 或非 fallback 方法的方法。}]

例如，实现以下方法将保证 @racket[gen:set] 中的所有方法至少有一个 fallback 方法：

@itemlist[@item{@racket[set-member?]}
          @item{@racket[set-add]}
          @item{@racket[set-add!]}
          @item{@racket[set-remove]}
          @item{@racket[set-remove!]}
          @item{@racket[set-first]}
          @item{@racket[set-empty?]}
          @item{@racket[set-copy-clear]}]

可能还有其他这样的方法子集，可以保证每个方法至少有一个 fallback。

@defproc[(set-member? [st generic-set?] [v any/c]) boolean?]{

如果 @racket[v] 在 @racket[st] 中则返回 @racket[#t]，否则返回 @racket[#f]。没有 fallback。

}

@defproc[(set-add [st generic-set?] [v any/c]) generic-set?]{

生成一个包含 @racket[v] 及 @racket[st] 所有元素的集合。此操作对于 @tech{hash sets} 以常数时间运行。没有 fallback。

}

@defproc[(set-add! [st generic-set?] [v any/c]) void?]{

将元素 @racket[v] 添加到 @racket[st] 中。此操作对于 @tech{hash sets} 以常数时间运行。没有 fallback。

@hash-set-caveats[]}


@defproc[(set-remove [st generic-set?] [v any/c]) generic-set?]{

生成一个包含 @racket[st] 所有元素但不含 @racket[v] 的集合。此操作对于 @tech{hash sets} 以常数时间运行。没有 fallback。

}

@defproc[(set-remove! [st generic-set?] [v any/c]) void?]{

从 @racket[st] 中移除元素 @racket[v]。此操作对于 @tech{hash sets} 以常数时间运行。没有 fallback。

@hash-set-caveats[]}


@defproc[(set-empty? [st generic-set?]) boolean?]{

如果 @racket[st] 没有成员则返回 @racket[#t]；否则返回 @racket[#f]。

对于任何 @impl{实现} @racket[set->stream] 或 @racket[set-count] 的 @racket[st] 提供支持。

}

@defproc[(set-count [st generic-set?]) exact-nonnegative-integer?]{

返回 @racket[st] 中的元素数量。

对于任何 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

}

@defproc[(set-first [st (and/c generic-set? (not/c set-empty?))]) any/c]{

生成 @racket[st] 的一个未指定元素。在 @racket[st] 上多次使用 @racket[set-first] 会生成相同的结果。

对于任何 @impl{实现} @racket[set->stream] 的 @racket[st] 提供支持。

}


@defproc[(set-rest [st (and/c generic-set? (not/c set-empty?))]) generic-set?]{

生成一个包含 @racket[st] 所有元素但不含 @racket[(set-first st)] 的集合。

对于任何 @impl{实现} @racket[set-remove] 以及 @racket[set-first] 或 @racket[set->stream] 的 @racket[st] 提供支持。

}

@defproc[(set->stream [st generic-set?]) stream?]{

生成包含 @racket[st] 元素的 stream。

对于任何 @impl{实现} 以下内容的 @racket[st] 提供支持：
@itemlist[@item{@racket[set->list]}
          @item{@racket[in-set]}
          @item{@racket[set-empty?]、@racket[set-first]、@racket[set-rest]}
          @item{@racket[set-empty?]、@racket[set-first]、@racket[set-remove]}
          @item{@racket[set-count]、@racket[set-first]、@racket[set-rest]}
          @item{@racket[set-count]、@racket[set-first]、@racket[set-remove]}]
}

@defproc[(set-copy [st generic-set?]) generic-set?]{

生成一个与 @racket[st] 同类型且具有相同元素的新可变集合。

对于任何 @supp{支持} @racket[set->stream] 且 @impl{实现} @racket[set-copy-clear] 和 @racket[set-add!] 的 @racket[st] 提供支持。

}

@defproc[(set-copy-clear [st generic-set?]) (and/c generic-set? set-empty?)]{

生成一个与 @racket[st] 同类型、相同可变性和键强度的新的空集合。

@racket[set-copy-clear] 和 @racket[set-clear] 之间的区别在于后者概念上在给定集合上迭代 @racket[set-remove]，因此它保留给定集合上的任何 contract。@racket[set-copy-clear] 函数生成一个没有任何 contract 的新集合。

@racket[set-copy-clear] 函数必须调用具体的集合构造函数，因此没有泛型 fallback。
}

@defproc[(set-clear [st generic-set?]) (and/c generic-set? set-empty?)]{

生成一个类似 @racket[st] 但移除了所有元素的集合。

对于任何 @impl{实现} @racket[set-remove] 且 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

}

@defproc[(set-clear! [st generic-set?]) void?]{

移除 @racket[st] 中的所有元素。

对于任何 @impl{实现} @racket[set-remove!] 且 @supp{支持} @racket[set->stream]，或 @impl{实现} @racket[set-first] 以及 @racket[set-count] 或 @racket[set-empty?] 的 @racket[st] 提供支持。

@hash-set-caveats[]}


@defproc[(set-union [st0 generic-set?] [st generic-set?] ...) generic-set?]{

生成一个与 @racket[st0] 同类型的集合，包含来自 @racket[st0] 和所有 @racket[st] 的元素。

如果 @racket[st0] 是 list，每个 @racket[st] 也必须是 list。此操作在 list 上的运行时间与 @racket[st] 的总大小乘以结果大小成正比。

如果 @racket[st0] 是 @tech{hash set}，每个 @racket[st] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与除最大不可变集合外的所有集合的总大小成正比。

必须至少向 @racket[set-union] 提供一个集合以确定结果集合的类型（list、hash set 等）。如果存在 @racket[set-union] 可能被应用于零个参数的情况，则改为将预期类型的空集合作为第一个参数传入。

对于任何 @impl{实现} @racket[set-add] 且 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

@examples[#:eval set-eval
(set-union (set))
(set-union (seteq))
(set-union (set 1 2) (set 2 3))
(set-union (list 1 2) (list 2 3))
(eval:error (set-union (set 1 2) (seteq 2 3))) (code:comment "Sets of different types cannot be unioned")
]}

@defproc[(set-union! [st0 generic-set?] [st generic-set?] ...) void?]{

将所有 @racket[st] 中的元素添加到 @racket[st0] 中。

如果 @racket[st0] 是 @tech{hash set}，每个 @racket[st] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与 @racket[st] 的总大小成正比。

对于任何 @impl{实现} @racket[set-add!] 且 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

@hash-set-caveats[]}

@defproc[(set-intersect [st0 generic-set?] [st generic-set?] ...) generic-set?]{

生成一个与 @racket[st0] 同类型的集合，包含 @racket[st0] 中同时也被所有 @racket[st] 包含的元素。

如果 @racket[st0] 是 list，每个 @racket[st] 也必须是 list。此操作在 list 上的运行时间与 @racket[st] 的总大小乘以 @racket[st0] 的大小成正比。

如果 @racket[st0] 是 @tech{hash set}，每个 @racket[st] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与最小不可变集合的大小成正比。

对于任何 @impl{实现} @racket[set-remove] 或同时 @racket[set-clear] 和 @racket[set-add]，且 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

}

@defproc[(set-intersect! [st0 generic-set?] [st generic-set?] ...) void?]{

从 @racket[st0] 中移除所有未被所有 @racket[st] 包含的元素。

如果 @racket[st0] 是 @tech{hash set}，每个 @racket[st] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与 @racket[st0] 的大小成正比。

对于任何 @impl{实现} @racket[set-remove!] 且 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

@hash-set-caveats[]}


@defproc[(set-subtract [st0 generic-set?] [st generic-set?] ...) generic-set?]{

生成一个与 @racket[st0] 同类型的集合，包含 @racket[st0] 中未被任何 @racket[st] 包含的元素。

如果 @racket[st0] 是 list，每个 @racket[st] 也必须是 list。此操作在 list 上的运行时间与 @racket[st] 的总大小乘以 @racket[st0] 的大小成正比。

如果 @racket[st0] 是 @tech{hash set}，每个 @racket[st] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与 @racket[st0] 的大小成正比。

对于任何 @impl{实现} @racket[set-remove] 或同时 @racket[set-clear] 和 @racket[set-add]，且 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

}

@defproc[(set-subtract! [st0 generic-set?] [st generic-set?] ...) void?]{

从 @racket[st0] 中移除所有被任何 @racket[st] 包含的元素。

如果 @racket[st0] 是 @tech{hash set}，每个 @racket[st] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与 @racket[st0] 的大小成正比。

对于任何 @impl{实现} @racket[set-remove!] 且 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

@hash-set-caveats[]}


@defproc[(set-symmetric-difference [st0 generic-set?] [st generic-set?] ...) generic-set?]{

生成一个与 @racket[st0] 同类型的集合，包含在 @racket[st0] 和 @racket[st] 中出现奇数次的所有元素。

如果 @racket[st0] 是 list，每个 @racket[st] 也必须是 list。此操作在 list 上的运行时间与 @racket[st] 的总大小乘以 @racket[st0] 的大小成正比。

如果 @racket[st0] 是 @tech{hash set}，每个 @racket[st] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与除最大不可变集合外的所有集合的总大小成正比。

对于任何 @impl{实现} @racket[set-remove] 或同时 @racket[set-clear] 和 @racket[set-add], and @supp{supports} @racket[set->stream].

@examples[#:eval set-eval
(set-symmetric-difference (set 1) (set 1 2) (set 1 2 3))
]

}

@defproc[(set-symmetric-difference! [st0 generic-set?] [st generic-set?] ...) void?]{

添加和移除 @racket[st0] 的元素，使其包含在 @racket[st] 和 @racket[st0] 的原始内容中出现奇数次的所有元素。

如果 @racket[st0] 是 @tech{hash set}，每个 @racket[st] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与 @racket[st] 的总大小成正比。

对于任何 @impl{实现} @racket[set-remove!] 且 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

@hash-set-caveats[]}


@defproc[(set=? [st generic-set?] [st2 generic-set?]) boolean?]{

如果 @racket[st] 和 @racket[st2] 包含相同的成员则返回 @racket[#t]；否则返回 @racket[#f]。

如果 @racket[st] 是 list，则 @racket[st2] 也必须是 list。此操作在 list 上的运行时间与 @racket[st] 的大小乘以 @racket[st2] 的大小成正比。

如果 @racket[st] 是 @tech{hash set}，则 @racket[st2] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与 @racket[st] 的大小加 @racket[st2] 的大小成正比。

对于同时 @supp{支持} @racket[subset?] 的任何 @racket[st] 和 @racket[st2] 提供支持；对于任何 @impl{实现} @racket[set=?] 的 @racket[st2] 也提供支持，而无论 @racket[st] 如何。

@examples[#:eval set-eval
(set=? (list 1 2) (list 2 1))
(set=? (set 1) (set 1 2 3))
(set=? (set 1 2 3) (set 1))
(set=? (set 1 2 3) (set 1 2 3))
(set=? (seteq 1 2) (mutable-seteq 2 1))
(eval:error (set=? (seteq 1 2) (seteqv 1 2))) (code:comment "Sets of different types cannot be compared")
]

}

@defproc[(subset? [st generic-set?] [st2 generic-set?]) boolean?]{

@index["set-subset?"]{返回} 如果 @racket[st2] 包含 @racket[st] 的每个成员则返回 @racket[#t]；否则返回 @racket[#f]。

如果 @racket[st] 是 list，则 @racket[st2] 也必须是 list。此操作在 list 上的运行时间与 @racket[st] 的大小乘以 @racket[st2] 的大小成正比。

如果 @racket[st] 是 @tech{hash set}，则 @racket[st2] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与 @racket[st] 的大小成正比。

对于任何 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

@examples[#:eval set-eval
(subset? (set 1) (set 1 2 3))
(subset? (set 1 2 3) (set 1))
(subset? (set 1 2 3) (set 1 2 3))
]

}

@defproc[(proper-subset? [st generic-set?] [st2 generic-set?]) boolean?]{

如果 @racket[st2] 包含 @racket[st] 的每个成员并且至少有一个额外元素，则返回 @racket[#t]；否则返回 @racket[#f]。

如果 @racket[st] 是 list，则 @racket[st2] 也必须是 list。此操作在 list 上的运行时间与 @racket[st] 的大小乘以 @racket[st2] 的大小成正比。

如果 @racket[st] 是 @tech{hash set}，则 @racket[st2] 也必须是使用相同比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）的 @tech{hash set}。hash set 的可变性和键强度可以不同。此操作在 hash set 上的运行时间与 @racket[st] 的大小加 @racket[st2] 的大小成正比。

对于同时 @supp{支持} @racket[subset?] 的任何 @racket[st] 和 @racket[st2] 提供支持。

@examples[#:eval set-eval
(proper-subset? (set 1) (set 1 2 3))
(proper-subset? (set 1 2 3) (set 1))
(proper-subset? (set 1 2 3) (set 1 2 3))
]

}

@defproc[(set->list [st generic-set?]) list?]{

生成包含 @racket[st] 元素的 list。

对于任何 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

}

@defproc[(set-map [st generic-set?]
                  [proc (any/c . -> . any/c)])
         (listof any/c)]{

以未指定的顺序将过程 @racket[proc] 应用于 @racket[st] 中的每个元素，将结果累积到一个 list 中。

对于任何 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

}


@defproc[(set-for-each [st generic-set?]
                       [proc (any/c . -> . any)])
         void?]{

以未指定的顺序将 @racket[proc] 应用于 @racket[st] 中的每个元素（用于 @racket[proc] 的副作用）。

对于任何 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

}

@defproc[(in-set [st generic-set?]) sequence?]{

显式将集合转换为 sequence 以用于 @racket[for] 和其他形式。

对于任何 @supp{支持} @racket[set->stream] 的 @racket[st] 提供支持。

}

@defproc[(impersonate-hash-set [st (or/c set-mutable? set-weak?)]
                               [inject-proc (or/c #f (-> set? any/c any/c))]
                               [add-proc (or/c #f (-> set? any/c any/c))]
                               [shrink-proc (or/c #f (-> set? any/c any/c))]
                               [extract-proc (or/c #f (-> set? any/c any/c))]
                               [clear-proc (or/c #f (-> set? any)) #f]
                               [equal-key-proc (or/c #f (-> set? any/c any/c)) #f]
                               [prop impersonator-property?]
                               [prop-val any/c] ... ...)
         (and/c (or/c set-mutable? set-weak?) impersonator?)]{
 模拟 @racket[st]，通过给定的过程重定向各种集合操作。

 @racket[inject-proc] 过程在元素被临时放入集合以便与集合中可能已存在的其他元素进行比较时被调用。例如，在求值 @racket[(set-member? s e)] 时，@racket[e] 将在与 @racket[s] 的其他元素比较之前传递给 @racket[inject-proc]。

 @racket[add-proc] 过程在向集合添加元素时被调用，例如通过 @racket[set-add] 或 @racket[set-add!]。@racket[add-proc] 的结果被存储在集合中。

 @racket[shrink-proc] 过程在构建一个少一个元素的新集合时被调用。例如，在求值 @racket[(set-remove s e)] 或 @racket[(set-remove! s e)] 时，一个元素从集合中被移除，例如通过 @racket[set-remove] 或 @racket[set-remove!]。@racket[shrink-proc] 的结果是实际从集合中移除的元素。
 
 @racket[extract-proc] 过程在元素从集合中被取出时被调用，例如通过 @racket[set-first]。@racket[extract-proc] 的结果是从集合中实际产生的元素。

 @racket[clear-proc] 由 @racket[set-clear] 和 @racket[set-clear!] 调用，如果它返回（而不是转义，也许通过引发异常），则允许清除操作。其结果被忽略。如果 @racket[clear-proc] 是 @racket[#f]，则清除是逐个元素进行的（通过调用其他提供的过程）。

 @racket[equal-key-proc] 在需要元素的 hash code 时或元素被提供给集合中底层相等比较时被调用。@racket[equal-key-proc] 的结果在计算 hash 或比较相等性时使用。
 
 如果 @racket[inject-proc]、@racket[add-proc]、@racket[shrink-proc] 或 @racket[extract-proc] 参数中的任何一个是 @racket[#f]，则它们都必须为 @racket[#f]，@racket[clear-proc] 和 @racket[equal-key-proc] 也必须为 @racket[#f]，并且必须至少提供一个属性。
 
 成对的 @racket[prop] 和 @racket[prop-val]（@racket[impersonate-hash-set] 的参数数量必须是奇数）添加 @tech{impersonator properties} 或覆盖 @racket[st] 的 impersonator property 值。
}

@defproc[(chaperone-hash-set [st (or/c set? set-mutable? set-weak?)]
                             [inject-proc (or/c #f (-> set? any/c any/c))]
                             [add-proc (or/c #f (-> set? any/c any/c))]
                             [shrink-proc (or/c #f (-> set? any/c any/c))]
                             [extract-proc (or/c #f (-> set? any/c any/c))]
                             [clear-proc (or/c #f (-> set? any)) #f]
                             [equal-key-proc (or/c #f (-> set? any/c any/c)) #f]
                             [prop impersonator-property?]
                             [prop-val any/c] ... ...)
         (and/c (or/c set? set-mutable? set-weak?) chaperone?)]{
 对 @racket[st] 施加 chaperone。类似于 @racket[impersonate-hash-set]，但有以下约束：@racket[inject-proc]、@racket[add-proc]、@racket[shrink-proc]、@racket[extract-proc] 和 @racket[equal-key-proc] 的结果必须是其第二个参数的 @racket[chaperone-of?]。此外，输入可以是 @racket[immutable?] 集合。
}

@section{Custom Hash Sets}

@defform[(define-custom-set-types name 
                                  optional-predicate
                                  comparison-expr
                                  optional-hash-functions)
         #:grammar ([optional-predicate
                     (code:line)
                     (code:line #:elem? predicate-expr)]
                    [optional-hash-functions
                     (code:line)
                     (code:line hash1-expr)
                     (code:line hash1-expr hash2-expr)])]{

基于给定的比较 @racket[comparison-expr]、hash 函数 @racket[hash1-expr] 和 @racket[hash2-expr] 以及元素谓词 @racket[predicate-expr] 创建一个新的 hash set 类型；这些函数的接口与
@racket[make-custom-set-types] 中的相同。新的集合类型有三种变体：不可变、强保留元素的可变、以及弱保留元素的可变。

定义七个名称：

@itemize[
@item{@racket[name]@racketidfont{?} 识别新类型的实例，}
@item{@racketidfont{immutable-}@racket[name]@racketidfont{?} 识别新类型的不可变实例，}
@item{@racketidfont{mutable-}@racket[name]@racketidfont{?} 识别具有强保留元素的新类型的可变实例，}
@item{@racketidfont{weak-}@racket[name]@racketidfont{?} 识别具有弱保留元素的新类型的可变实例，}
@item{@racketidfont{make-immutable-}@racket[name] 构造新类型的不可变实例，}
@item{@racketidfont{make-mutable-}@racket[name] 构造具有强保留元素的新类型的可变实例，以及}
@item{@racketidfont{make-weak-}@racket[name] 构造具有弱保留元素的新类型的可变实例。}
]

所有构造函数都接受一个 stream 作为可选参数，提供初始元素。

@examples[
#:eval set-eval
(define-custom-set-types string-set
                         #:elem? string?
                         string=?
                         string-length)
(define imm
  (make-immutable-string-set '("apple" "banana")))
(define mut
  (make-mutable-string-set '("apple" "banana")))
(generic-set? imm)
(generic-set? mut)
(set? imm)
(generic-set? imm)
(string-set? imm)
(string-set? mut)
(immutable-string-set? imm)
(immutable-string-set? mut)
(set-member? imm "apple")
(set-member? mut "banana")
(equal? imm mut)
(set=? imm mut)
(set-remove! mut "banana")
(set-member? mut "banana")
(equal? (set-remove (set-remove imm "apple") "banana")
        (make-immutable-string-set))
]

}

@defproc[(make-custom-set-types
          [eql?
           (or/c (any/c any/c . -> . any/c)
                 (any/c any/c (any/c any/c . -> . any/c) . -> . any/c))]
          [hash1
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [hash2
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [#:elem? elem? (any/c . -> . boolean?) (const #true)]
          [#:name name symbol? 'custom-set]
          [#:for who symbol? 'make-custom-set-types])
         (values (any/c . -> . boolean?)
                 (any/c . -> . boolean?)
                 (any/c . -> . boolean?)
                 (any/c . -> . boolean?)
                 (->* [] [stream?] generic-set?)
                 (->* [] [stream?] generic-set?)
                 (->* [] [stream?] generic-set?))]{

基于给定的比较函数 @racket[eql?]、hash 函数 @racket[hash1] 和 @racket[hash2] 以及谓词 @racket[elem?] 创建一个新的集合类型。新的集合类型有不可变、强保留元素的可变以及弱保留元素的可变这三种变体。给定的 @racket[name] 在打印新集合类型的实例时使用，符号 @racket[who] 用于报告错误。

比较函数 @racket[eql?] 可以接受 2 或 3 个参数。如果它接受 2 个参数，则给它两个元素进行比较。如果它接受 3 个参数且不接受 2 个参数，则还会给它一个递归比较函数，用于在比较元素的子部分时处理数据循环。

hash 函数 @racket[hash1] 和 @racket[hash2] 可以接受 1 或 2 个参数。如果任一 hash 函数接受 1 个参数，则将其应用于元素以计算相应的 hash value。如果任一 hash 函数接受 2 个参数且不接受 1 个参数，则还会给它一个递归 hash 函数，用于在计算元素子部分的 hash values 时处理数据循环。

谓词 @racket[elem?] 必须接受 1 个参数，用于识别新集合类型的有效元素。

生成七个值：

@itemize[
@item{一个识别新集合类型所有实例的谓词，}
@item{一个识别弱实例的谓词，}
@item{一个识别可变实例的谓词，}
@item{一个识别不可变实例的谓词，}
@item{一个弱实例的构造函数，}
@item{一个可变实例的构造函数，以及}
@item{一个不可变实例的构造函数。}
]

示例参见 @racket[define-custom-set-types]。

}

@close-eval[set-eval]
