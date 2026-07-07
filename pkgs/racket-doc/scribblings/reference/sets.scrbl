#lang scribble/doc
@(require "mz.rkt" (for-label racket/set))

@title[#:tag "sets"]{Sets}
@(define set-eval (make-base-eval))
@examples[#:hidden #:eval set-eval (require racket/set)]

@(define (hash-set-caveats)
   @elem{对于 @tech{hash set}，另请参阅 hash table 的 @concurrency-caveat[]，
         该注意事项同样适用于 hash set。})

@deftech{set} 表示一个由不同元素组成的集合。以下数据类型都是 set：

@itemize[

  @item{@techlink{hash set}；}

  @item{使用 @racket[equal?] 比较元素的 @techlink{list}；以及}

  @item{实现了 @racket[gen:set] @tech{generic interface} 的
        @techlink{struct} 类型。}

]

@note-lib[racket/set]

@section{Hash Sets}

@deftech{hash set} 是一种通过 @racket[equal?]、@racket[equal-always?]、
@racket[eqv?] 或 @racket[eq?] 比较元素，并通过 @racket[equal-hash-code]、
@racket[equal-always-hash-code]、@racket[eqv-hash-code] 或 @racket[eq-hash-code]
进行分区的 set。hash set 可以是不可变的或可变的；可变 hash set 可以强引用或弱引用
其元素。

@margin-note{与不可变 hash table 上的操作类似，``常数时间'' hash set 操作实际上
对于大小为 @math{N} 的 set 需要 @math{O(log N)} 的时间。}

hash set 可以用作 @tech{stream}（参见 @secref["streams"]），因此也可以用作
单值 @tech{sequence}（参见 @secref["sequences"]）。set 的元素用作 stream 或
sequence 的元素。如果在迭代期间向 hash set 添加或移除元素，则迭代步骤可能会因
@racket[exn:fail:contract] 而失败，或者迭代可能会跳过或重复元素。另请参阅
@racket[in-set]。

当两个 hash set 使用相同的元素比较过程（@racket[equal?]、@racket[equal-always?]、
@racket[eqv?] 或 @racket[eq?]）、都强引用或弱引用元素、具有相同的可变性、
并且具有等价的元素时，它们是 @racket[equal?] 的。
不可变 hash set 支持有效的常数时间访问和更新，就像可变 hash set 一样；不可变操作的
常数因子通常更大，但不可变 hash set 的函数式特性在某些算法中可以发挥作用。

所有 hash set @impl{实现} @racket[set->stream]、@racket[set-empty?]、
@racket[set-member?]、@racket[set-count]、@racket[subset?]、
@racket[proper-subset?]、@racket[set-map]、@racket[set-for-each]、
@racket[set-copy]、@racket[set-copy-clear]、@racket[set->list] 和
@racket[set-first]。不可变 hash set 还 @impl{实现} @racket[set-add]、
@racket[set-remove]、@racket[set-clear]、@racket[set-union]、
@racket[set-intersect]、@racket[set-subtract] 和
@racket[set-symmetric-difference]。可变 hash set 还 @impl{实现}
@racket[set-add!]、@racket[set-remove!]、@racket[set-clear!]、
@racket[set-union!]、@racket[set-intersect!]、@racket[set-subtract!] 和
@racket[set-symmetric-difference!]。

对包含被变异元素的 set 的操作是不可预测的，这与当 key 被变异时 @tech{hash table}
操作不可预测的方式大致相同。

@deftogether[(
@defproc[(set-equal? [x any/c]) boolean?]
@defproc[(set-equal-always? [x any/c]) boolean?]
@defproc[(set-eqv? [x any/c]) boolean?]
@defproc[(set-eq? [x any/c]) boolean?]
)]{

如果 @racket[x] 是分别使用 @racket[equal?]、@racket[equal-always?]、
@racket[eqv?] 或 @racket[eq?] 比较元素的 @tech{hash set}，则返回 @racket[#t]；
否则返回 @racket[#f]。

@history[#:changed "8.5.0.3" @elem{添加了 @racket[set-equal-always?]。}]}

@deftogether[(
@defproc[(set? [x any/c]) boolean?]
@defproc[(set-mutable? [x any/c]) boolean?]
@defproc[(set-weak? [x any/c]) boolean?]
)]{

如果 @racket[x] 分别是不可变的、具有强引用 key 的可变 hash set、或具有弱引用 key
的可变 @tech{hash set}，则返回 @racket[#t]；否则返回 @racket[#f]。

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

创建一个以给定 @racket[v] 为元素的 @tech{hash set}。元素按其作为参数出现的顺序
添加，因此对于使用 @racket[equal?]、@racket[equal-always?] 或 @racket[eqv?] 的 set，
一个较早的元素可能会被一个在 @racket[equal?]、@racket[equal-always?] 或
@racket[eqv?] 下等价但不在 @racket[eq?] 下等价的较晚元素替换。

@history[#:changed "8.5.0.3" @elem{添加了 @racket[setalw]、
                                   @racket[mutable-setalw] 和 @racket[weak-setalw]。}]}

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

以给定 @racket[lst] 的元素作为 set 的元素创建一个 @tech{hash set}。分别等价于
@racket[(apply set lst)]、@racket[(apply setalw lst)]、
@racket[(apply seteqv lst)]、@racket[(apply seteq lst)] 等。

@history[#:changed "8.5.0.3" @elem{添加了 @racket[list->setalw]、
                                   @racket[list->mutable-setalw] 和
                                   @racket[list->weak-setalw]。}]}

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

类似于 @racket[for/list] 和 @racket[for*/list]，但用于构造 @tech{hash set}
而非 list。

@history[#:changed "8.5.0.3" @elem{添加了 @racket[for/setalw]、
                                   @racket[for/mutable-setalw] 和
                                   @racket[for/weak-setalw]。}]}


@deftogether[(
@defproc[(in-immutable-set [st set?]) sequence?]
@defproc[(in-mutable-set [st set-mutable?]) sequence?]
@defproc[(in-weak-set [st set-weak?]) sequence?]
)]{

显式地将特定类型的 @tech{hash set} 转换为 sequence，以用于 @racket[for] 形式。

与 @racket[in-list] 和其他一些 sequence 构造器类似，当 @racket[in-immutable-set]
直接出现在 @racket[for] 子句中时性能更好。

这些 sequence 构造器与 @secref["Custom_Hash_Sets" #:doc '(lib "scribblings/reference/reference.scrbl")] 兼容。

@history[#:added "6.4.0.7"]
}

@section{Set Predicates and Contracts}

@defproc[(generic-set? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{set}，则返回 @racket[#t]；否则返回 @racket[#f]。

@examples[
#:eval set-eval
(generic-set? (list 1 2 3))
(generic-set? (set 1 2 3))
(generic-set? (mutable-seteq 1 2 3))
(generic-set? (vector 1 2 3))
]

}

@defproc[(set-implements? [st generic-set?] [sym symbol?] ...) boolean?]{

如果 @racket[st] 实现了 @racket[gen:set] 中由 @racket[sym] 命名的所有方法，
则返回 @racket[#t]；否则返回 @racket[#f]。回退实现不影响结果；@racket[st]
可能通过回退实现支持给定方法但仍产生 @racket[#f]。

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

识别支持 @racket[gen:set] 中由 @racket[sym] 命名的所有方法的 set。

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

  构造一个识别元素匹配 @racket[elem/c] 的 set 的 contract。

  如果 @racket[kind] 为 @racket['immutable]、@racket['mutable] 或
  @racket['weak]，则生成的 contract 分别只接受不可变的、具有强引用 key 的可变、
  或具有弱引用 key 的可变 @tech{hash set}。如果 @racket[kind] 为
  @racket['mutable-or-weak]，则生成的 contract 接受任何可变 @tech{hash set}，
  不考虑 key 的持有强度。

  如果 @racket[cmp] 为 @racket['equal]、@racket['equal-always]、
  @racket['eqv] 或 @racket['eq]，则生成的 contract 分别只接受使用
  @racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]
  比较元素的 @tech{hash set}。

  如果 @racket[cmp] 为 @racket['eqv] 或 @racket['eq]，则 @racket[elem/c]
  必须是 @tech{flat contract}。

  如果 @racket[cmp] 和 @racket[kind] 都为 @racket['dont-care]，则生成的
  contract 将接受任何类型的 set，而不仅仅是 @tech{hash set}。

 如果 @racket[lazy?] 不为 @racket[#f]，则 set 的元素不会被 contract 立即检查，
 只有 set 本身被检查（根据 @racket[cmp] 和 @racket[kind] 参数）。如果
 @racket[lazy?] 为 @racket[#f]，则元素会被 contract 立即检查。
 当 set contract 接受通用 set 时（即 @racket[cmp] 和 @racket[kind] 都为
 @racket['dont-care]），@racket[lazy?] 参数被忽略；在那种情况下，被检查的值如果是
 @racket[list?]，则 contract 不是惰性的，否则 contract 是惰性的。
 
 如果 @racket[kind] 允许可变 set（即为 @racket['dont-care]、@racket['mutable]、
 @racket['weak] 或 @racket['mutable-or-weak]）且 @racket[lazy?] 为
 @racket[#f]，则元素会在立即检查时和从 set 中访问时都被检查。

 @racket[equal-key/c] contract 用于值被传递给内部使用的比较和哈希函数时。
 
 结果 contract 在 @racket[elem/c] 和 @racket[equal-key/c] 都是 @tech{flat contract}、
 @racket[lazy?] 为 @racket[#f]、且 @racket[kind] 为 @racket['immutable] 时
 将是 @tech{flat contract}。当 @racket[elem/c] 是 @tech{chaperone contract}
 时，结果将是 @tech{chaperone contract}。

 @history[#:changed "8.3.0.9" @elem{添加了对随机生成的支持。}
          #:changed "8.5.0.3" @elem{为 @racket[cmp] 添加了 @racket['equal-always] 支持。}]
}

@section{Generic Set Interface}


@defidform[gen:set]{

一个 @tech{generic interface}（参见 @secref["struct-generics"]），通过
@racket[struct] 定义的 @racket[#:methods] 选项为结构类型提供 set 方法实现。
此接口可用于实现 @secref["set-methods"] 中记录的任何方法。

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
                              (bitwise-not (arithmetic-shift 1 i)))))])
(define bset (binary-set 5))
bset
(generic-set? bset)
(set-member? bset 0)
(set-member? bset 1)
(set-member? bset 2)
(set-add bset 4)
(set-remove bset 2)
]

}

@subsection[#:tag "set-methods"]{Set Methods}

@(define (supp . args) (apply tech #:key "supported generic method" args))
@(define (impl . args) (apply tech #:key "implemented generic method" args))

@racket[gen:set] 的方法可以按其回退实现分为三类：

@itemlist[#:style 'ordered
          @item{没有回退的方法，}
          @item{回退依赖于其他非回退方法的方法，}
          @item{以及回退可以依赖于回退或非回退方法的方法。}]

例如，实现以下方法将保证 @racket[gen:set] 中的所有方法至少有一个回退方法：

@itemlist[@item{@racket[set-member?]}
          @item{@racket[set-add]}
          @item{@racket[set-add!]}
          @item{@racket[set-remove]}
          @item{@racket[set-remove!]}
          @item{@racket[set-first]}
          @item{@racket[set-empty?]}
          @item{@racket[set-copy-clear]}]

可能还有其他类似的方法子集可以保证每个方法至少有一个回退。

@defproc[(set-member? [st generic-set?] [v any/c]) boolean?]{

如果 @racket[v] 在 @racket[st] 中，返回 @racket[#t]，否则返回 @racket[#f]。
没有回退。

}

@defproc[(set-add [st generic-set?] [v any/c]) generic-set?]{

产生一个包含 @racket[v] 加上 @racket[st] 所有元素的 set。对于 @tech{hash set}
此操作在常数时间内运行。没有回退。

}

@defproc[(set-add! [st generic-set?] [v any/c]) void?]{

将元素 @racket[v] 添加到 @racket[st]。对于 @tech{hash set} 此操作在常数时间
内运行。没有回退。

@hash-set-caveats[]}


@defproc[(set-remove [st generic-set?] [v any/c]) generic-set?]{

产生一个包含 @racket[st] 中除 @racket[v] 以外所有元素的 set。对于
@tech{hash set} 此操作在常数时间内运行。没有回退。

}

@defproc[(set-remove! [st generic-set?] [v any/c]) void?]{

从 @racket[st] 中移除元素 @racket[v]。对于 @tech{hash set} 此操作在常数时间
内运行。没有回退。

@hash-set-caveats[]}


@defproc[(set-empty? [st generic-set?]) boolean?]{

如果 @racket[st] 没有成员，返回 @racket[#t]；否则返回 @racket[#f]。

支持任何 @impl{实现} @racket[set->stream] 或 @racket[set-count] 的 @racket[st]。

}

@defproc[(set-count [st generic-set?]) exact-nonnegative-integer?]{

返回 @racket[st] 中的元素数量。

支持任何 @supp{支持} @racket[set->stream] 的 @racket[st]。

}

@defproc[(set-first [st (and/c generic-set? (not/c set-empty?))]) any/c]{

产生 @racket[st] 的一个未指定元素。对 @racket[st] 的多次 @racket[set-first]
使用产生相同的结果。

支持任何 @impl{实现} @racket[set->stream] 的 @racket[st]。

}


@defproc[(set-rest [st (and/c generic-set? (not/c set-empty?))]) generic-set?]{

产生一个包含 @racket[st] 中除 @racket[(set-first st)] 以外所有元素的 set。

支持任何 @impl{实现} @racket[set-remove] 且 @impl{实现} @racket[set-first]
或 @racket[set->stream] 的 @racket[st]。

}

@defproc[(set->stream [st generic-set?]) stream?]{

产生一个包含 @racket[st] 元素的 stream。

支持任何 @impl{实现}以下方法之一的 @racket[st]：
@itemlist[@item{@racket[set->list]}
          @item{@racket[in-set]}
          @item{@racket[set-empty?]、@racket[set-first]、@racket[set-rest]}
          @item{@racket[set-empty?]、@racket[set-first]、@racket[set-remove]}
          @item{@racket[set-count]、@racket[set-first]、@racket[set-rest]}
          @item{@racket[set-count]、@racket[set-first]、@racket[set-remove]}]
}

@defproc[(set-copy [st generic-set?]) generic-set?]{

产生一个与 @racket[st] 类型相同、元素相同的新可变 set。

支持任何 @supp{支持} @racket[set->stream] 且 @impl{实现} @racket[set-copy-clear]
和 @racket[set-add!] 的 @racket[st]。

}

@defproc[(set-copy-clear [st generic-set?]) (and/c generic-set? set-empty?)]{

产生一个与 @racket[st] 类型、可变性和 key 强度相同的新空 set。

@racket[set-copy-clear] 和 @racket[set-clear] 的一个区别是，后者在概念上对
给定的 set 迭代执行 @racket[set-remove]，因此它保留给定 set 上的任何 contract。
@racket[set-copy-clear] 函数产生一个没有任何 contract 的新 set。

@racket[set-copy-clear] 函数必须调用具体的 set 构造器，因此没有通用回退。
}

@defproc[(set-clear [st generic-set?]) (and/c generic-set? set-empty?)]{

产生一个与 @racket[st] 类似但已移除所有元素的 set。

支持任何 @impl{实现} @racket[set-remove] 且 @supp{支持} @racket[set->stream]
的 @racket[st]。

}

@defproc[(set-clear! [st generic-set?]) void?]{

从 @racket[st] 中移除所有元素。

支持任何 @impl{实现} @racket[set-remove!] 且 @supp{支持} @racket[set->stream]
或 @impl{实现} @racket[set-first] 和 @racket[set-count] 或 @racket[set-empty?]
的 @racket[st]。

@hash-set-caveats[]}


@defproc[(set-union [st0 generic-set?] [st generic-set?] ...) generic-set?]{

产生一个与 @racket[st0] 类型相同的 set，包含 @racket[st0] 和所有 @racket[st]
中的元素。

如果 @racket[st0] 是 list，则每个 @racket[st] 也必须是 list。此操作在 list 上
的运行时间与 @racket[st] 的总大小乘以结果的大小成比例。

如果 @racket[st0] 是 @tech{hash set}，则每个 @racket[st] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与除最大不可变 set 外所有 set 的总大小成比例。

至少必须向 @racket[set-union] 提供一个 set 以确定结果 set 的类型（list、
hash set 等）。如果有 @racket[set-union] 可能被应用于零个参数的情况，
请改为将预期类型的空 set 作为第一个参数传递。

支持任何 @impl{实现} @racket[set-add] 且 @supp{支持} @racket[set->stream]
的 @racket[st]。

@examples[#:eval set-eval
(set-union (set))
(set-union (seteq))
(set-union (set 1 2) (set 2 3))
(set-union (list 1 2) (list 2 3))
(eval:error (set-union (set 1 2) (seteq 2 3))) (code:comment "不同类型 set 无法进行并集运算")
]}

@defproc[(set-union! [st0 generic-set?] [st generic-set?] ...) void?]{

将所有 @racket[st] 的元素添加到 @racket[st0] 中。

如果 @racket[st0] 是 @tech{hash set}，则每个 @racket[st] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与 @racket[st] 的总大小成比例。

支持任何 @impl{实现} @racket[set-add!] 且 @supp{支持} @racket[set->stream]
的 @racket[st]。

@hash-set-caveats[]

}

@defproc[(set-intersect [st0 generic-set?] [st generic-set?] ...) generic-set?]{

产生一个与 @racket[st0] 类型相同的 set，包含 @racket[st0] 中同时也被所有
@racket[st] 包含的元素。

如果 @racket[st0] 是 list，则每个 @racket[st] 也必须是 list。此操作在 list
上的运行时间与 @racket[st] 的总大小乘以 @racket[st0] 的大小成比例。

如果 @racket[st0] 是 @tech{hash set}，则每个 @racket[st] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与最小不可变 set 的大小成比例。

支持任何 @impl{实现} @racket[set-remove] 或同时 @impl{实现} @racket[set-clear]
和 @racket[set-add]，且 @supp{支持} @racket[set->stream] 的 @racket[st]。

}

@defproc[(set-intersect! [st0 generic-set?] [st generic-set?] ...) void?]{

从 @racket[st0] 中移除不被所有 @racket[st] 包含的每个元素。

如果 @racket[st0] 是 @tech{hash set}，则每个 @racket[st] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与 @racket[st0] 的大小成比例。

支持任何 @impl{实现} @racket[set-remove!] 且 @supp{支持} @racket[set->stream]
的 @racket[st]。

@hash-set-caveats[]

}


@defproc[(set-subtract [st0 generic-set?] [st generic-set?] ...) generic-set?]{

产生一个与 @racket[st0] 类型相同的 set，包含 @racket[st0] 中不被任何
@racket[st] 包含的元素。

如果 @racket[st0] 是 list，则每个 @racket[st] 也必须是 list。此操作在 list
上的运行时间与 @racket[st] 的总大小乘以 @racket[st0] 的大小成比例。

如果 @racket[st0] 是 @tech{hash set}，则每个 @racket[st] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与 @racket[st0] 的大小成比例。

支持任何 @impl{实现} @racket[set-remove] 或同时 @impl{实现} @racket[set-clear]
和 @racket[set-add]，且 @supp{支持} @racket[set->stream] 的 @racket[st]。

}

@defproc[(set-subtract! [st0 generic-set?] [st generic-set?] ...) void?]{

从 @racket[st0] 中移除被任何 @racket[st] 包含的每个元素。

如果 @racket[st0] 是 @tech{hash set}，则每个 @racket[st] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与 @racket[st0] 的大小成比例。

支持任何 @impl{实现} @racket[set-remove!] 且 @supp{支持} @racket[set->stream]
的 @racket[st]。

@hash-set-caveats[]

}


@defproc[(set-symmetric-difference [st0 generic-set?] [st generic-set?] ...) generic-set?]{

产生一个与 @racket[st0] 类型相同的 set，包含在 @racket[st0] 和 @racket[st]
中出现奇数次的所有元素。

如果 @racket[st0] 是 list，则每个 @racket[st] 也必须是 list。此操作在 list
上的运行时间与 @racket[st] 的总大小乘以 @racket[st0] 的大小成比例。

如果 @racket[st0] 是 @tech{hash set}，则每个 @racket[st] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与除最大不可变 set 外所有 set 的总大小成比例。

支持任何 @impl{实现} @racket[set-remove] 或同时 @impl{实现} @racket[set-clear]
和 @racket[set-add]，且 @supp{支持} @racket[set->stream] 的 @racket[st]。

@examples[#:eval set-eval
(set-symmetric-difference (set 1) (set 1 2) (set 1 2 3))
]

}

@defproc[(set-symmetric-difference! [st0 generic-set?] [st generic-set?] ...) void?]{

添加和移除 @racket[st0] 的元素，使其包含在 @racket[st] 和 @racket[st0]
原始内容中出现奇数次的所有元素。

如果 @racket[st0] 是 @tech{hash set}，则每个 @racket[st] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与 @racket[st] 的总大小成比例。

支持任何 @impl{实现} @racket[set-remove!] 且 @supp{支持} @racket[set->stream]
的 @racket[st]。

@hash-set-caveats[]

}


@defproc[(set=? [st generic-set?] [st2 generic-set?]) boolean?]{

如果 @racket[st] 和 @racket[st2] 包含相同的成员，返回 @racket[#t]；否则返回
@racket[#f]。

如果 @racket[st0] 是 list，则每个 @racket[st] 也必须是 list。此操作在 list
上的运行时间与 @racket[st] 的大小乘以 @racket[st2] 的大小成比例。

如果 @racket[st0] 是 @tech{hash set}，则每个 @racket[st] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与 @racket[st] 的大小加上 @racket[st2] 的大小
成比例。

支持任何同时 @supp{支持} @racket[subset?] 的 @racket[st] 和 @racket[st2]；
也支持任何 @impl{实现} @racket[set=?] 的 @racket[st2]，不论 @racket[st] 如何。

@examples[#:eval set-eval
(set=? (list 1 2) (list 2 1))
(set=? (set 1) (set 1 2 3))
(set=? (set 1 2 3) (set 1))
(set=? (set 1 2 3) (set 1 2 3))
(set=? (seteq 1 2) (mutable-seteq 2 1))
(eval:error (set=? (seteq 1 2) (seteqv 1 2))) (code:comment "不同类型 set 无法比较")
]

}

@defproc[(subset? [st generic-set?] [st2 generic-set?]) boolean?]{

@index["set-subset?"]{如果} @racket[st2] 包含 @racket[st] 的每个成员，返回
@racket[#t]；否则返回 @racket[#f]。

如果 @racket[st] 是 list，则 @racket[st2] 也必须是 list。此操作在 list 上的
运行时间与 @racket[st] 的大小乘以 @racket[st2] 的大小成比例。

如果 @racket[st] 是 @tech{hash set}，则 @racket[st2] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与 @racket[st] 的大小成比例。

支持任何 @supp{支持} @racket[set->stream] 的 @racket[st]。

@examples[#:eval set-eval
(subset? (set 1) (set 1 2 3))
(subset? (set 1 2 3) (set 1))
(subset? (set 1 2 3) (set 1 2 3))
]

}

@defproc[(proper-subset? [st generic-set?] [st2 generic-set?]) boolean?]{

如果 @racket[st2] 包含 @racket[st] 的每个成员且至少多一个元素，返回
@racket[#t]；否则返回 @racket[#f]。

如果 @racket[st] 是 list，则 @racket[st2] 也必须是 list。此操作在 list 上的
运行时间与 @racket[st] 的大小乘以 @racket[st2] 的大小成比例。

如果 @racket[st] 是 @tech{hash set}，则 @racket[st2] 也必须是使用相同
比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或
@racket[eq?]）的 @tech{hash set}。hash set 的可变性和 key 强度可能不同。
此操作在 hash set 上的运行时间与 @racket[st] 的大小加上 @racket[st2] 的大小
成比例。

支持任何同时 @supp{支持} @racket[subset?] 的 @racket[st] 和 @racket[st2]。

@examples[#:eval set-eval
(proper-subset? (set 1) (set 1 2 3))
(proper-subset? (set 1 2 3) (set 1))
(proper-subset? (set 1 2 3) (set 1 2 3))
]

}

@defproc[(set->list [st generic-set?]) list?]{

产生一个包含 @racket[st] 元素的 list。

支持任何 @supp{支持} @racket[set->stream] 的 @racket[st]。

}

@defproc[(set-map [st generic-set?]
                  [proc (any/c . -> . any/c)])
         (listof any/c)]{

以未指定的顺序对 @racket[st] 中的每个元素应用过程 @racket[proc]，
将结果累积到一个 list 中。

支持任何 @supp{支持} @racket[set->stream] 的 @racket[st]。

}


@defproc[(set-for-each [st generic-set?]
                       [proc (any/c . -> . any)])
         void?]{

以未指定的顺序对 @racket[st] 中的每个元素应用 @racket[proc]
（为了 @racket[proc] 的副作用）。

支持任何 @supp{支持} @racket[set->stream] 的 @racket[st]。

}

@defproc[(in-set [st generic-set?]) sequence?]{

显式地将 set 转换为 sequence，以用于 @racket[for] 和其他形式。

支持任何 @supp{支持} @racket[set->stream] 的 @racket[st]。

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
 对 @racket[st] 进行 impersonate，通过给定的过程重定向各种 set 操作。

 当元素临时放入 set 以与可能已在 set 中的其他元素进行比较时，会调用
 @racket[inject-proc] 过程。例如，在求值 @racket[(set-member? s e)] 时，
 @racket[e] 会在与 @racket[s] 的其他元素比较之前传递给 @racket[inject-proc]。

 @racket[add-proc] 过程在向 set 添加元素时被调用，例如通过 @racket[set-add]
 或 @racket[set-add!]。@racket[add-proc] 的结果存储在 set 中。

 @racket[shrink-proc] 过程在构建少一个元素的新 set 时被调用。例如，在求值
 @racket[(set-remove s e)] 或 @racket[(set-remove! s e)] 时，从 set 中移除
 一个元素。@racket[shrink-proc] 的结果是从 set 中实际移除的元素。
 
 @racket[extract-proc] 过程在从 set 中取出元素时被调用，例如通过
 @racket[set-first]。@racket[extract-proc] 的结果是从 set 中实际产生的元素。

 @racket[clear-proc] 由 @racket[set-clear] 和 @racket[set-clear!] 调用，
 如果它返回（而非跳出，例如通过引发异常），则允许清除操作。其结果被忽略。
 如果 @racket[clear-proc] 为 @racket[#f]，则清除是逐元素进行的
 （通过调用其他提供的过程）。

 当需要元素的哈希码或将元素提供给 set 底层的相等性时，会调用
 @racket[equal-key-proc]。@racket[equal-key-proc] 的结果用于计算哈希值或
 进行相等性比较。
 
 如果 @racket[inject-proc]、@racket[add-proc]、@racket[shrink-proc] 或
 @racket[extract-proc] 参数中有任何一个为 @racket[#f]，则它们必须全部为
 @racket[#f]，@racket[clear-proc] 和 @racket[equal-key-proc] 也必须为
 @racket[#f]，并且必须至少提供一个属性。
 
 @racket[prop] 和 @racket[prop-val] 的配对（@racket[impersonate-hash-set]
 的参数个数必须为奇数）添加 @tech{impersonator properties} 或覆盖
 @racket[st] 的 impersonator 属性值。
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
 对 @racket[st] 进行 chaperone。类似于 @racket[impersonate-hash-set]，但
 @racket[inject-proc]、@racket[add-proc]、@racket[shrink-proc]、
 @racket[extract-proc] 和 @racket[equal-key-proc] 的结果必须是其第二个参数的
 @racket[chaperone-of?]。此外，输入可以是 @racket[immutable?] set。
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

基于给定的比较 @racket[comparison-expr]、哈希函数 @racket[hash1-expr] 和
@racket[hash2-expr]、以及元素谓词 @racket[predicate-expr] 创建新的 hash set 类型；
这些函数的接口与 @racket[make-custom-set-types] 中的相同。新的 set 类型有三种变体：
不可变的、具有强引用元素的可变的、以及具有弱引用元素的可变的。

定义七个名称：

@itemize[
@item{@racket[name]@racketidfont{?} 识别新类型的实例，}
@item{@racketidfont{immutable-}@racket[name]@racketidfont{?} 识别新类型的不可变实例，}
@item{@racketidfont{mutable-}@racket[name]@racketidfont{?} 识别具有强引用元素的新类型的可变实例，}
@item{@racketidfont{weak-}@racket[name]@racketidfont{?} 识别具有弱引用元素的新类型的可变实例，}
@item{@racketidfont{make-immutable-}@racket[name] 构造新类型的不可变实例，}
@item{@racketidfont{make-mutable-}@racket[name] 构造具有强引用元素的新类型的可变实例，以及}
@item{@racketidfont{make-weak-}@racket[name] 构造具有弱引用元素的新类型的可变实例。}
]

构造器都接受一个 stream 作为可选参数，提供初始元素。

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

基于给定的比较函数 @racket[eql?]、哈希函数 @racket[hash1] 和 @racket[hash2]、
以及谓词 @racket[elem?] 创建新的 set 类型。新的 set 类型具有不可变的、具有强引用
元素的可变的、以及具有弱引用元素的可变的变体。给定的 @racket[name] 用于打印新
set 类型的实例，符号 @racket[who] 用于报告错误。

比较函数 @racket[eql?] 可以接受 2 个或 3 个参数。如果接受 2 个参数，则给定两个
元素来比较它们。如果接受 3 个参数且不接受 2 个参数，则还会给定一个递归比较函数，
用于在比较元素子部分时处理数据循环。

哈希函数 @racket[hash1] 和 @racket[hash2] 可以接受 1 个或 2 个参数。如果任一
哈希函数接受 1 个参数，则将其应用于元素以计算相应的哈希值。如果任一哈希函数接受
2 个参数且不接受 1 个参数，则还会给定一个递归哈希函数，用于在计算元素子部分的
哈希值时处理数据循环。

谓词 @racket[elem?] 必须接受 1 个参数，用于识别新 set 类型的有效元素。

产生七个值：

@itemize[
@item{识别新 set 类型所有实例的谓词，}
@item{识别弱实例的谓词，}
@item{识别可变实例的谓词，}
@item{识别不可变实例的谓词，}
@item{弱实例的构造器，}
@item{可变实例的构造器，以及}
@item{不可变实例的构造器。}
]

参见 @racket[define-custom-set-types] 中的示例。

}

