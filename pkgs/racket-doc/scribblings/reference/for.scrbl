#lang scribble/doc
@(require "mz.rkt"
          (for-label syntax/for-body
                     syntax/parse
                     syntax/parse/define
                     racket/for-clause))

@title[#:tag "for"]{Iterations and Comprehensions: @racket[for], @racket[for/list], ...}

@guideintro["for"]{迭代与推导式}

@(define for-eval (make-base-eval))
@(for-eval '(require (for-syntax racket/base)))

@racket[for] 迭代形式基于 SRFI-42 @cite["SRFI-42"]。

@section[#:tag "for-s1"]{Iteration and Comprehension Forms}

@defform/subs[(for (for-clause ...) body-or-break ... body)
              ([for-clause [id seq-expr]
                           [(id ...) seq-expr]
                           (code:line #:when guard-expr)
                           (code:line #:unless guard-expr)
                           (code:line #:do [do-body ...])
                           break-clause
                           (code:line #:splice (splicing-id . form))
                           (code:line #:on-length-mismatch mismatch-expr)]
               [break-clause (code:line #:break guard-expr)
                             (code:line #:final guard-expr)]
               [body-or-break body
                              break-clause])
              #:contracts ([seq-expr sequence?])]{

迭代地求值 @racket[body]。@racket[for-clause] 引入绑定，其作用域包括 @racket[body]，并确定 @racket[body] 被求值的次数。
位于 @racket[for-clause] 或 @racket[body] 中的 @racket[break-clause] 会停止进一步迭代。

在简单情况下，每个 @racket[for-clause] 采用其前两种形式之一，其中 @racket[[id seq-expr]] 是 @racket[[(id)
seq-expr]] 的简写。在这种简单情况下，@racket[seq-expr] 从左到右求值，每个都必须产生一个序列值（参见 @secref["sequences"]）。

@racket[for] 形式通过从每个序列中取出一个元素来迭代；如果任何序列为空，则迭代停止
（但参见下文的 @racket[#:on-length-mismatch]），并且
@|void-const| 是 @racket[for] 表达式的结果。否则，为每个 @racket[id] 创建一个位置来保存每个元素的值；@racket[seq-expr] 产生的序列必须为每次迭代返回与对应 @racket[id] 数量相同的值。

然后 @racket[id] 在 @racket[body] 中被绑定，@racket[body] 被求值，其结果被忽略。迭代继续使用每个序列中的下一个元素，并为每个 @racket[id] 分配新的位置。

带有零个 @racket[for-clause] 的 @racket[for] 形式等价于单个 @racket[for-clause]，它将一个未被引用的 @racket[id] 绑定到包含单个元素的序列。所有 @racket[id] 必须根据 @racket[bound-identifier=?] 是互不相同的。

如果任何 @racket[for-clause] 具有 @racket[#:when guard-expr] 形式，则仅前面的子句（不包含 @racket[#:when]、@racket[#:unless] 或 @racket[#:do]）如上所述确定迭代，而 @racket[body] 有效地被包裹为

@racketblock[
(when guard-expr
  (for (for-clause ...) body ...+))
]

使用剩余的 @racket[for-clause]。@racket[#:unless guard-expr] 形式的 @racket[for-clause] 对应相同的转换，
只是将 @racket[when] 替换为 @racket[unless]。@racket[#:do [do-body ...]] 形式的 @racket[for-clause] 同样创建嵌套并对应于

@racketblock[
(let ()
  do-body ...
  (for (for-clause ...) body ...+))
]

其中 @racket[do-body] 形式可以引入在其余 @racket[for-clause] 中可见的定义。

@racket[#:break guard-expr] 子句类似于 @racket[#:unless guard-expr] 子句，但当 @racket[#:break] 避免了 @racket[body] 的求值时，它也有效地结束 @racket[for] 形式中的所有序列。@racket[#:final guard-expr] 子句类似于 @racket[#:break guard-expr]，但不是立即结束序列并跳过 @racket[body]，而是允许每个后续序列最多再提供一个元素，并允许后续 @racket[body] 最多再求值一次。在 @racket[body] 中，除了停止迭代并阻止后续 @racket[body] 求值之外，@racket[#:break guard-expr] 或 @racket[#:final guard-expr] 子句还会启动一个新的内部定义上下文。

@racket[#:splice (splicing-id . form)] 子句被替换为展开 @racket[(splicing-id . form)] 所产生的形式序列，其中 @racket[splicing-id] 使用 @racket[define-splicing-for-clause-syntax] 绑定。该展开的绑定上下文包括来自 @racket[#:splice] 形式之前且同时在 @racket[#:when]、@racket[#:unless]、@racket[#:do]、@racket[#:break] 或 @racket[#:final] 形式之前的任何子句的先前绑定。@racket[#:splice] 展开的结果可以包含更多 @racket[#:splice] 形式，以进一步交错子句绑定和展开。对 @racket[#:splice] 子句的支持更多用于构建展开为 @racket[for] 的新形式，而非直接在源码 @racket[for] 形式中使用。

@racket[#:on-length-mismatch mismatch-expr] 子句类似于 @racket[#:when #t]，但如果在紧接着的前面子句中，某个序列在另一个序列之前结束，则对 @racket[mismatch-expr] 进行求值以产生效果（例如抛出异常）。如果 @racket[mismatch-expr] 产生值，则该值被忽略，并且迭代层终止。当 @racket[#:on-length-mismatch] 存在时，组中的所有序列在一次潜在的迭代中都会被检查终止情况，即使更早发现了不匹配。

对于 @tech{list} 和 @tech{stream} 序列，@racket[for] 形式本身不会保持每个元素可达。如果某个 @racket[seq-expr] 产生的列表或流在其他地方不可达，并且 @racket[for] 的 body 不再引用某个列表元素的 @racket[id]，则该元素可以被 @tech{garbage collection} 回收。@racket[make-do-sequence] 序列构造函数支持在此方面行为类似于列表和流的其他序列。

如果 @racket[seq-expr] 是引用的字面量列表、向量、精确整数、字符串、字节字符串、不可变哈希表，或者展开为此类字面量，则它可能被视为使用了诸如 @racket[in-list] 之类的序列转换器，除非 @racket[seq-expr] 对于 @indexed-racket['for:no-implicit-optimization] 语法属性具有真值；在大多数情况下，这可以提高性能。

@examples[
(for ([i '(1 2 3)]
      [j "abc"]
      #:when (odd? i)
      [k #2(#t #f)])
  (display (list i j k)))
(for ([i '(1 2 3)]
      #:do [(define neg-i (* i -1))]
      [j (list neg-i 0 i)])
  (display (list j)))
(for ([(i j) #hash(("a" . 1) ("b" . 20))])
  (display (list i j)))
(for ([i '(1 2 3)]
      [j "abc"]
      #:break (not (odd? i))
      [k #2(#t #f)])
  (display (list i j k)))
(for ([i '(1 2 3)]
      [j "abc"]
      #:final (not (odd? i))
      [k #2(#t #f)])
  (display (list i j k)))
(for ([i '(1 2 3)]
      [j "abc"]
      [k #2(#t #f)])
  #:break (not (or (odd? i) k))
  (display (list i j k)))
(for ()
  (display "here"))
(for ([i '()])
  (error "doesn't get here"))
(for ([i (in-range 2)]
      [j (in-range 3)])
  (display i))
(eval:error
 (for ([i (in-range 2)]
       [j (in-range 3)]
       #:on-length-mismatch (error "different"))
   (display i)))
]

@history[#:changed "6.7.0.4" @elem{Added support for the optional second result.}
         #:changed "7.8.0.11" @elem{Added support for implicit optimization.}
         #:changed "8.4.0.2" @elem{Added @racket[#:do].}
         #:changed "8.4.0.3" @elem{Added @racket[#:splice].}
         #:changed "9.0.0.2" @elem{Added @racket[#:on-length-mismatch].}]}

@defform[(for/list (for-clause ...) body-or-break ... body)]{ 像 @racket[for] 一样迭代，但 @racket[body] 中的最后一个表达式必须产生单个值，而 @racket[for/list] 表达式的结果是按顺序排列的结果列表。
当由于 @racket[#:when] 或 @racket[#:unless] 子句而跳过 @racket[body] 的求值时，结果列表中不包含对应的元素。

@examples[
(for/list ([i '(1 2 3)]
           [j "abc"]
           #:when (odd? i)
           [k #2(#t #f)])
  (list i j k))
(for/list ([i '(1 2 3)]
           [j "abc"]
           #:break (not (odd? i))
           [k #2(#t #f)])
  (list i j k))
(for/list () 'any)
(for/list ([i '()])
  (error "doesn't get here"))
]}

@defform/subs[(for/vector maybe-length (for-clause ...) body-or-break ... body)
              ([maybe-length (code:line)
                             (code:line #:length length-expr)
                             (code:line #:length length-expr #:fill fill-expr)])
              #:contracts ([length-expr exact-nonnegative-integer?])]{

像 @racket[for/list] 一样迭代，但结果累积到向量而非列表中。

如果指定了可选的 @racket[#:length] 子句，则 @racket[length-expr] 的结果确定结果向量的长度。在这种情况下，迭代可以更高效地执行，并且当向量填满或已执行所请求的迭代次数时终止（以先到者为准）。如果 @racket[length-expr] 指定的长度大于迭代次数，则向量的剩余位置被初始化为 @racket[fill-expr] 的值，默认为 @racket[0]（即 @racket[make-vector] 的默认参数）。

@examples[
(for/vector ([i '(1 2 3)]) (number->string i))
(for/vector #:length 2 ([i '(1 2 3)]) (number->string i))
(for/vector #:length 4 ([i '(1 2 3)]) (number->string i))
(for/vector #:length 4 #:fill "?" ([i '(1 2 3)]) (number->string i))
]

@racket[for/vector] 形式可能会在每次 @racket[body] 迭代之后分配一个向量并在其上执行变更操作，这意味着在 @racket[body] 期间捕获 continuation 并多次应用它可能会修改一个共享的向量。}


@deftogether[(
@defform[(for/hash (for-clause ...) body-or-break ... body)]
@defform[(for/hasheq (for-clause ...) body-or-break ... body)]
@defform[(for/hasheqv (for-clause ...) body-or-break ... body)]
@defform[(for/hashalw (for-clause ...) body-or-break ... body)]
)]{

类似于 @racket[for/list]，但结果是一个不可变的 @tech{hash table}；@racket[for/hash] 使用 @racket[equal?] 来区分 key，@racket[for/hasheq] 使用 @racket[eq?] 产生表，@racket[for/hasheqv] 使用 @racket[eqv?] 产生表，@racket[for/hashalw] 使用 @racket[equal-always?] 产生表。
@racket[body] 中的最后一个表达式必须返回两个值：一个 key 和一个值，用以扩展迭代累积的 hash table。

@examples[
(for/hash ([i '(1 2 3)])
  (values i (number->string i)))
]

@history[#:changed "8.5.0.3" @elem{Added the @racket[for/hashalw] form.}]}


@defform[(for/and (for-clause ...) body-or-break ... body)]{ 像 @racket[for] 一样迭代，但当 @racket[body] 的最后一个表达式产生 @racket[#f] 时，迭代终止，@racket[for/and] 表达式的结果为 @racket[#f]。如果 @racket[body] 从未被求值，则 @racket[for/and] 表达式的结果为 @racket[#t]。否则，结果是 @racket[body] 最后一次求值的（单个）结果。

@examples[
(for/and ([i '(1 2 3 "x")])
  (i . < . 3))
(for/and ([i '(1 2 3 4)])
  i)
(for/and ([i '(1 2 3 4)])
  #:break (= i 3)
  i)
(for/and ([i '()])
  (error "doesn't get here"))
]}

@defform[(for/or (for-clause ...) body-or-break ... body)]{ 像 @racket[for] 一样迭代，但当 @racket[body] 的最后一个表达式产生除 @racket[#f] 以外的值时，迭代终止，@racket[for/or] 表达式的结果是相同的（单个）值。如果 @racket[body] 从未被求值，则 @racket[for/or] 表达式的结果为 @racket[#f]。否则，结果为 @racket[#f]。

@examples[
(for/or ([i '(1 2 3 "x")])
  (i . < . 3))
(for/or ([i '(1 2 3 4)])
  i)
(for/or ([i '()])
  (error "doesn't get here"))
]}

@deftogether[(
@defform[(for/sum (for-clause ...) body-or-break ... body)]
)]{

像 @racket[for] 一样迭代，但 @racket[body] 最后一个表达式的每个结果通过 @racket[+] 累积到结果中。

@examples[
(for/sum ([i '(1 2 3 4)]) i)
]}


@deftogether[(
@defform[(for/product (for-clause ...) body-or-break ... body)]
)]{

像 @racket[for] 一样迭代，但 @racket[body] 最后一个表达式的每个结果通过 @racket[*] 累积到结果中。

@examples[
(for/product ([i '(1 2 3 4)]) i)
]}


@defform[(for/lists (id ... maybe-result)
                    (for-clause ...)
           body-or-break ... body)
         #:grammar
         ([maybe-result (code:line) (code:line #:result result-expr)])]{

类似于 @racket[for/list]，但最后一个 @racket[body] 表达式应该产生与给定 @racket[id] 数量相同的值。
@racket[id] 被绑定到在 @racket[for-clause] 和 @racket[body] 中截至目前累积的反向列表。

如果提供了 @racket[result-expr]，当迭代终止时它会像 @racket[for/fold] 一样被使用；
否则，结果是数量与提供的 @racket[id] 相同的列表。

@racket[id] 绑定的作用域与 @racket[for/fold] 中累加器标识符的作用域相同。修改 @racket[id] 会影响累积的列表，以产生非列表的方式修改它可能导致每个 @racket[id] 的最终 @racket[reverse] 失败。

@examples[
(for/lists (l1 l2 l3)
           ([i '(1 2 3)]
            [j "abc"]
            #:when (odd? i)
            [k #(#t #f)])
  (values i j k))
(for/lists (acc)
           ([x '(tvp tofu seitan tvp tofu)]
            #:unless (member x acc))
  x)
(for/lists (firsts seconds #:result (list firsts seconds))
           ([pr '((1 . 2) (3 . 4) (5 . 6))])
  (values (car pr) (cdr pr)))
]

@history[
 #:changed "7.1.0.2" @elem{Added the @racket[#:result] form.}
 ]}


@defform[(for/first (for-clause ...) body-or-break ... body)]{ 像 @racket[for] 一样迭代，但在 @racket[body] 第一次被求值后，迭代终止，@racket[for/first] 的结果是 @racket[body] 的（单个）结果。如果 @racket[body] 从未被求值，则 @racket[for/first] 表达式的结果为 @racket[#f]。

@examples[
(for/first ([i '(1 2 3 "x")]
            #:when (even? i))
   (number->string i))
(for/first ([i '()])
  (error "doesn't get here"))
]}

@defform[(for/last (for-clause ...) body-or-break ... body)]{ 像 @racket[for] 一样迭代，但 @racket[for/last] 的结果是 @racket[body] 最后一次求值的（单个）结果。如果 @racket[body] 从未被求值，则 @racket[for/last] 表达式的结果为 @racket[#f]。

@examples[
(for/last ([i '(1 2 3 4 5)]
            #:when (even? i))
   (number->string i))
(for/last ([i '()])
  (error "doesn't get here"))
]}

@defform/subs[(for/fold ([accum-id init-expr] ... maybe-result) (for-clause ...)
                body-or-break ... body)
              ([maybe-result (code:line)
                             (code:line #:result result-expr)])]{

像 @racket[for] 一样迭代。在迭代开始之前，@racket[init-expr] 被求值以产生初始累加器值。在每次迭代开始时，为每个 @racket[accum-id] 生成一个位置，并将对应的当前累加器值放入该位置。@racket[body] 中的最后一个表达式必须产生与 @racket[accum-id] 数量相同的值，这些值成为当前累加器值。当迭代终止时，如果提供了 @racket[result-expr]，则 @racket[for/fold] 的结果是求值 @racket[result-expr] 的结果（@racket[accum-id] 在作用域内并绑定到其最终值），否则 @racket[for/fold] 表达式的结果是累加器值。

@examples[
(for/fold ([sum 0]
           [rev-roots null])
          ([i '(1 2 3 4)])
  (values (+ sum i) (cons (sqrt i) rev-roots)))

(for/fold ([acc '()]
           [seen (hash)]
           #:result (reverse acc))
          ([x (in-list '(0 1 1 2 3 4 4 4))])
  (cond
    [(hash-ref seen x #f)
     (values acc seen)]
    [else (values (cons x acc)
                  (hash-set seen x #t))]))
]

@racket[accum-id] 和 @racket[init-expr] 的绑定和求值顺序遵循相对于 @racket[for-clause] 的文本从左到右的顺序，但（由于历史原因）在最外层迭代中 @racket[accum-id] 在 @racket[for-clause] 中不可用。然而，变量的生命周期并不完全等同于词法嵌套：@racket[accum-id] 引用的变量在每次迭代中有一个新的位置。

@history[#:changed "6.11.0.1" @elem{Added the @racket[#:result] form.}
         #:changed "8.11.1.3" @elem{Changed evaluation order to match textual left-to-right order,
                                    including evaluating @racket[init-expr]s before the first
                                    @racket[for-clause]'s right-hand side and fixing shadowing of
                                    @racket[accum-id].}]
}

@(define for/foldr-eval ((make-eval-factory '(racket/promise racket/sequence racket/stream))))
@defform[(for/foldr ([accum-id init-expr] ... accum-option ...)
                    (for-clause ...)
           body-or-break ... body)
         #:grammar ([accum-option (code:line #:result result-expr)
                                  #:delay
                                  (code:line #:delay-as delayed-id)
                                  (code:line #:delay-with delayer-id)])]{

类似于 @racket[for/fold]，但类比于 @racket[foldr] 而非 @racket[foldl]：给定的序列仍然按相同顺序迭代，但循环体按反向顺序求值。@racket[for/foldr] 表达式的求值使用与其执行的迭代次数成正比的空间，并且给定序列产生的所有元素在循环体反向求值开始之前会被保留（假设该元素确实在 body 中被引用）。

@(examples
  #:eval for/foldr-eval
  (define (in-printing seq)
    (sequence-map (lambda (v) (println v) v) seq))
  (eval:check (for/foldr ([acc '()])
                         ([v (in-printing (in-range 1 4))])
                (println v)
                (cons v acc))
              '(1 2 3)))

此外，与 @racket[for/fold] 不同，@racket[accum-id] 不会在 @racket[_break-clause] 之前出现的 @racket[_guard-expr] 或 @racket[_body-or-break] 形式中被绑定。

虽然上述限制使 @racket[for/foldr] 的通用性不如 @racket[for/fold]，但 @racket[for/foldr] 通过 @racket[#:delay]、@racket[#:delay-as] 和 @racket[#:delay-with] 选项提供了额外的惰性迭代能力，这可以缓解 @racket[for/foldr] 的许多缺点。如果至少指定了一个这样的选项，循环体将获得对迭代何时继续的显式控制：默认情况下，每个 @racket[accum-id] 被绑定到一个 @tech{promise}，当被 force 时，它产生 @racket[accum-id] 的当前值。

在此模式下，迭代直到某个 promise 被 force 时才会继续，这会触发产生值所需的任何额外迭代。如果循环体对其 @racket[accum-id] 是惰性的——也就是说，它在不 force 任何 promise 的情况下返回一个值——那么循环（或其任何迭代）将在迭代完全完成之前产生一个值。如果保留了对至少一个此类 promise 的引用，那么 force 它将从挂起点恢复迭代，即使控制已经离开了循环体的动态范围。

@(examples
  #:eval for/foldr-eval
  (eval:check (for/foldr ([acc '()] #:delay)
                         ([v (in-range 1 4)])
                (printf "--> ~v\n" v)
                (begin0
                  (cons v (force acc))
                  (printf "<-- ~v\n" v)))
              '(1 2 3))
  (define resume
    (for/foldr ([acc '()] #:delay)
               ([v (in-range 1 5)])
      (printf "--> ~v\n" v)
      (begin0
        (cond
          [(= v 1) (force acc)]
          [(= v 2) acc]
          [else    (cons v (force acc))])
        (printf "<-- ~v\n" v))))
  (eval:check (force resume) '(3 4)))

这种对迭代顺序的额外控制允许 @racket[for/foldr] 既能消费又能构造无限序列，只要它至少有时对其累加器是惰性的。

@margin-note/ref{
 另请参见 @racket[for/stream]，这是一个更便捷（尽管灵活性稍逊）的方式来惰性转换无限序列。（在内部，@racket[for/stream] 是基于 @racket[for/foldr] 定义的。）}

@(examples
  #:eval for/foldr-eval
  (define squares (for/foldr ([s empty-stream] #:delay)
                             ([n (in-naturals)])
                    (stream-cons (* n n) (force s))))
  (stream->list (stream-take squares 10)))

@racket[#:delay] 选项引入的暂停通常不会影响循环的最终返回值，但如果将 @racket[#:delay] 和 @racket[#:result] 结合使用，@racket[accum-id] 在 @racket[result-expr] 的作用域中将以与循环体内相同的方式被延迟。这可以用于在需要时在整个循环的求值周围引入一层额外的暂停。

@(examples
  #:eval for/foldr-eval
  (define evaluated-yet? #f)
  (for/foldr ([acc (set! evaluated-yet? #t)] #:delay) ()
    (force acc))
  (eval:check evaluated-yet? #t))
@(examples
  #:eval for/foldr-eval
  #:label #f
  (define evaluated-yet? #f)
  (define start
    (for/foldr ([acc (set! evaluated-yet? #t)] #:delay #:result acc) ()
      (force acc)))
  (eval:check evaluated-yet? #f)
  (force start)
  (eval:check evaluated-yet? #t))

如果提供了 @racket[#:delay-as] 选项，则 @racket[delayed-id] 被绑定到一个额外的 promise，该 promise 一次性返回所有 @racket[accum-id] 的值。当提供了多个 @racket[accum-id] 时，强制这个 promise 可能比分别强制绑定到各 @racket[accum-id] 的 promise 稍高效。

如果提供了 @racket[#:delay-with] 选项，则使用给定的 @racket[delayer-id] 来暂停嵌套迭代（替代默认的 @racket[delay]）。一个形式为 @racket[(delayer-id _recur-expr)] 的表达式被构造并放置在表达式位置，其中 @racket[_recur-expr] 是一个在被求值时将执行下一次迭代并返回其结果（或多个结果）的表达式。合适的 @racket[delayer-id] 选择包括 @racket[lazy]、@racket[delay/sync]、@racket[delay/thread] 或者来自 @racketmodname[racket/promise] 的任何其他 promise 构造函数，以及来自 @racketmodname[racket/function] 的 @racket[thunk]。然而，请注意诸如 @racket[thunk] 或 @racket[delay/name] 等选择可能会多次求值其子表达式，这对于有状态的序列可能导致荒谬的结果，因为状态将在 @racket[_recur-expr] 的所有求值之间共享。

如果给出了多个 @racket[accum-id]，提供了 @racket[#:delay-with] 选项，且 @racket[delayer-id] 未绑定到 @racket[delay]、@racket[lazy]、@racket[delay/strict]、@racket[delay/sync]、@racket[delay/thread] 或 @racket[delay/idle] 之一，则 @racket[accum-id] 根本不会被绑定，即使在循环体内也是如此。此时必须指定 @racket[#:delay-as] 选项来通过 @racket[delayed-id] 访问累加器值。

@history[#:added "7.3.0.3"]}
@(close-eval for/foldr-eval)

@defform[(for* (for-clause ...) body-or-break ... body)]{
类似于 @racket[for]，但在每对 @racket[for-clause] 之间隐含有 @racket[#:when #t]，以便所有序列迭代都是嵌套的。

@examples[
(for* ([i '(1 2)]
       [j "ab"])
  (display (list i j)))
]}

@deftogether[(
@defform[(for*/list (for-clause ...) body-or-break ... body)]
@defform[(for*/lists (id ... maybe-result) (for-clause ...) 
           body-or-break ... body)]
@defform[(for*/vector maybe-length (for-clause ...) body-or-break ... body)]
@defform[(for*/hash (for-clause ...) body-or-break ... body)]
@defform[(for*/hasheq (for-clause ...) body-or-break ... body)]
@defform[(for*/hasheqv (for-clause ...) body-or-break ... body)]
@defform[(for*/hashalw (for-clause ...) body-or-break ... body)]
@defform[(for*/and (for-clause ...) body-or-break ... body)]
@defform[(for*/or (for-clause ...) body-or-break ... body)]
@defform[(for*/sum (for-clause ...) body-or-break ... body)]
@defform[(for*/product (for-clause ...) body-or-break ... body)]
@defform[(for*/first (for-clause ...) body-or-break ... body)]
@defform[(for*/last (for-clause ...) body-or-break ... body)]
@defform[(for*/fold ([accum-id init-expr] ... maybe-result) (for-clause ...)
           body-or-break ... body)]
@defform[(for*/foldr ([accum-id init-expr] ... accum-option ...)
                     (for-clause ...)
           body-or-break ... body)]
)]{

类似于 @racket[for/list] 等，但具有 @racket[for*] 的隐式嵌套。

@examples[
(for*/list ([i '(1 2)]
            [j "ab"])
  (list i j))
]

@history[#:changed "7.3.0.3" @elem{Added the @racket[for*/foldr] form.}
         #:changed "8.5.0.3" @elem{Added the @racket[for*/hashalw] form.}]}

@;------------------------------------------------------------------------
@section[#:tag "for-s2"]{Deriving New Iteration Forms}

@defform[(for/fold/derived orig-datum
           ([accum-id init-expr] ... maybe-result) (for-clause ...)
           body-or-break ... body)]{

类似于 @racket[for/fold]，但额外的 @racket[orig-datum] 被用作所有语法错误的源信息。

展开为 @racket[for/fold/derived] 的 macro 通常应使用 @racket[split-for-body] 来处理 macro 和其他定义与 @racket[#:break] 等关键字混合的可能性。

@mz-examples[#:eval for-eval
(require (for-syntax syntax/for-body)
         syntax/parse/define)

(define-syntax-parse-rule (for/digits clauses body ... tail-expr)
  #:with original this-syntax
  #:with ((pre-body ...) (post-body ...)) (split-for-body this-syntax #'(body ... tail-expr))
  (for/fold/derived original ([n 0] [k 1] #:result n)
    clauses
    pre-body ...
    (values (+ n (* (let () post-body ...) k)) (* k 10))))

@code:comment{If we misuse for/digits, we can get good error reporting}
@code:comment{because the use of orig-datum allows for source correlation:}
(eval:error
 (for/digits
     [a (in-list '(1 2 3))]
     [b (in-list '(4 5 6))]
   (+ a b)))

(for/digits
    ([a (in-list '(1 2 3))]
     [b (in-list '(2 4 6))])
  (+ a b))


@code:comment{Another example: compute the max during iteration:}
(define-syntax-parse-rule (for/max clauses body ... tail-expr)
  #:with original this-syntax
  #:with ((pre-body ...) (post-body ...)) (split-for-body this-syntax #'(body ... tail-expr))
  (for/fold/derived original
    ([current-max -inf.0])
    clauses
    pre-body ...
    (define maybe-new-max (let () post-body ...))
    (if (> maybe-new-max current-max)
        maybe-new-max
        current-max)))

(for/max ([n '(3.14159 2.71828 1.61803)]
          [s '(-1      1       1)])
  (* n s))
]

@history[#:changed "6.11.0.1" @elem{Added the @racket[#:result] form.}]}

@defform[(for*/fold/derived orig-datum
           ([accum-id init-expr] ... maybe-result) (for-clause ...)
           body-or-break ... body)]{
类似于 @racket[for*/fold]，但额外的 @racket[orig-datum] 被用作所有语法错误的源信息。

@mz-examples[#:eval for-eval
(require (for-syntax syntax/for-body)
         syntax/parse/define)

(define-syntax-parse-rule (for*/digits clauses body ... tail-expr)
  #:with original this-syntax
  #:with ((pre-body ...) (post-body ...)) (split-for-body this-syntax #'(body ... tail-expr))
  (for*/fold/derived original ([n 0] [k 1] #:result n)
    clauses
    pre-body ...
    (values (+ n (* (let () post-body ...) k)) (* k 10))))

(eval:error
 (for*/digits
     [ds (in-list '((8 3) (1 1)))]
     [d (in-list ds)]
   d))

(for*/digits
    ([ds (in-list '((8 3) (1 1)))]
     [d (in-list ds)])
  d)
]

@history[#:changed "6.11.0.1" @elem{Added the @racket[#:result] form.}]}

@deftogether[(
@defform[(for/foldr/derived orig-datum
           ([accum-id init-expr] ... accum-option ...) (for-clause ...)
           body-or-break ... body)]
@defform[(for*/foldr/derived orig-datum
           ([accum-id init-expr] ... accum-option ...) (for-clause ...)
           body-or-break ... body)]
)]{

类似于 @racket[for/foldr] 和 @racket[for*/foldr]，但额外的 @racket[orig-datum] 被用作所有语法错误的源信息，与 @racket[for/fold/derived] 和 @racket[for*/fold/derived] 一样。

@history[#:added "7.3.0.3"]}

@defform[(define-sequence-syntax id
           expr-transform-expr
           clause-transform-expr)
         #:contracts
         ([expr-transform-expr (or/c (-> identifier?)
                                     (syntax? . -> . syntax?))]
          [clause-transform-expr (syntax? . -> . syntax?)])]{

将 @racket[id] 定义为语法。当 @racket[(id . _rest)] 形式在 @racket[for]（或其变体）的 @racket[_for-clause] 中用于生成序列时，它会被特殊处理。在这种情况下，@racket[clause-transform-expr] 的过程结果会被调用来转换该子句。

当 @racket[id] 在任何其他表达式位置使用时，则使用 @racket[expr-transform-expr] 的结果。如果它是一个零参数的过程，则结果必须是一个标识符 @racket[_other-id]，并且任何对 @racket[id] 的使用都被转换为对 @racket[_other-id] 的使用。否则，@racket[expr-transform-expr] 必须产生一个（单参数的）过程，用作 macro transformer。

当使用 @racket[clause-transform-expr] transformer 时，它接收一个 @racket[_for-clause] 作为参数，其中该子句的形式被规范化为左侧是带括号的标识符序列。右侧的形式为 @racket[(id . _rest)]。结果可以是 @racket[#f]，表示这些形式不应被特殊处理（可能是因为绑定标识符的数量与 @racket[(id . _rest)] 形式不一致），或者是一个新的 @racket[_for-clause] 来替换给定的子句。新子句可能使用 @racket[:do-in]。要保护 @racket[clause-transform-expr] 结果中的标识符，请使用 @racket[for-clause-syntax-protect] 而非 @racket[syntax-protect]。

@mz-examples[#:eval for-eval
(define (check-nat n)
  (unless (exact-nonnegative-integer? n)
    (raise-argument-error 'in-digits "exact-nonnegative-integer?" n)))
(define-sequence-syntax in-digits
  (lambda () #'in-digits/proc)
  (lambda (stx)
    (syntax-case stx ()
      [[(d) (_ nat)]
       #'[(d)
          (:do-in
            ([(n) nat])
            (check-nat n)
            ([i n])
            (not (zero? i))
            ([(j d) (quotient/remainder i 10)])
            #t
            #t
            [j])]]
      [_ #f])))

(define (in-digits/proc n)
  (for/list ([d (in-digits n)]) d))

(for/list ([d (in-digits 1138)]) d)

(map in-digits (list 137 216))
]}

@defform[(:do-in ([(outer-id ...) outer-expr] ...)
                 outer-defn-or-expr
                 ([loop-id loop-expr] ...)
                 pos-guard
                 ([(inner-id ...) inner-expr] ...)
                 maybe-inner-defn-or-expr
                 pre-guard
                 post-guard
                 (loop-arg ...))
         #:grammar
         ([maybe-inner-defn/expr (code:line) (code:line inner-defn-or-expr)])]{

一种只能在 @racket[for]（或其变体）的 @racket[_for-clause] 中作为 @racket[_seq-expr] 使用的形式。

在 @racket[for] 内部，@racket[:do-in] 形式的各个部分基本上如下拆分到迭代中：

@racketblock[
(let-values ([(outer-id ...) outer-expr] ...)
  outer-defn-or-expr
  (let loop ([loop-id loop-expr] ...)
    (if pos-guard
        (let-values ([(inner-id ...) inner-expr] ...)
          inner-defn-or-expr
          (if pre-guard
              (let _body-bindings
                   (if post-guard
                       (loop loop-arg ...)
                       _done-expr))
              _done-expr))
         _done-expr)))
]

其中 @racket[_body-bindings] 和 @racket[_done-expr] 来自使用 @racket[:do-in] 的上下文。@racket[for] 子句绑定的标识符通常是 @racket[([(inner-id ...)
inner-expr] ...)] 部分的一部分。当未提供 @racket[inner-defn-or-expr] 时，在其位置使用 @racket[(begin)]。

注意，@racket[_body-bindings] 和 @racket[_done-expr] 可以包含任意表达式，可能包括对 @racket[outer-id] 或 @racket[inner-id] 标识符的 @racket[set!]，如果它们在原始 @racket[for] 形式中可见的话。因此，在 @racket[post-guard] 和 @racket[loop-arg] 中依赖此类标识符时需要格外小心。

实际的 @racket[loop] 绑定和调用具有额外的循环参数，以支持与 @racket[:do-in] 形式并行的迭代，并且其他部分也类似地伴随着并行迭代的部分。

有关 @racket[:do-in] 的示例，请参见 @racket[define-sequence-syntax]。

@history[#:changed "8.10.0.3" @elem{Added support for non-empty
                                    @racket[maybe-inner-defn-or-expr].}]}

@defproc[(for-clause-syntax-protect [stx syntax?]) syntax?]{

由 @racket[for-syntax] 提供：类似于 @racket[syntax-protect]，仅仅返回其参数。

@history[#:changed "8.2.0.4" @elem{Changed to just return @racket[stx] instead
                                   of returning ``armed'' syntax.}]}

@defform[(define-splicing-for-clause-syntax id proc-expr)]{

绑定 @racket[id] 以供 @racket[for] 形式中的 @racket[#:splice] 子句引用。@racket[proc-expr] 表达式在 @tech{phase level} 1 中求值，它必须产生一个接受 syntax object 并返回 syntax object 的过程。

该过程的输入是出现在 @racket[#:splice] 之后的 syntax object。结果 syntax object 必须是一个带括号的形式序列，这些形式会被插入到包含 @racket[for] 形式中 @racket[#:splice] 子句的位置。

@mz-examples[#:eval for-eval
(define-splicing-for-clause-syntax cross3
  (lambda (stx)
    (syntax-case stx ()
      [(_ n m) #'([n (in-range 3)]
                  #:when #t
                  [m (in-range 3)])])))

(for (#:splice (cross3 n m))
  (println (list n m)))
]

@history[#:added "8.4.0.3"]}

@;------------------------------------------------------------------------
@section[#:tag "for-s3"]{Iteration Expansion}

@note-lib-only[racket/for-clause]

@defproc[(syntax-local-splicing-for-clause-introduce [stx syntax?]) syntax?]{

等价于 @racket[syntax-local-introduce]，用于在通过 @racket[define-splicing-for-clause-syntax] 绑定的 expander 中使用。

@history[#:added "8.11.1.4"
         #:changed "9.0.0.2" @elem{Changed to be equivalent to
                                   @racket[syntax-local-introduce].}]}

@;------------------------------------------------------------------------
@section[#:tag "for-s4"]{Do Loops}

@defform/subs[(do ([id init-expr step-expr-maybe] ...)
                  (stop?-expr finish-expr ...)
                expr ...)
              ([step-expr-maybe code:blank
                                step-expr])]{

只要 @racket[stop?-expr] 返回 @racket[#f]，就迭代地求值 @racket[expr]。

要初始化循环，@racket[init-expr] 按顺序求值并绑定到对应的 @racket[id]。@racket[id] 在表单中除 @racket[init-expr] 之外的所有表达式中被绑定。

在 @racket[id] 被绑定之后，@racket[stop?-expr] 被求值。如果它产生 @racket[#f]，则每个 @racket[expr] 被求值以产生副作用。然后 @racket[id] 有效地被更新为 @racket[step-expr] 的值，其中 @racket[id] 的默认 @racket[step-expr] 就是 @racket[id]；更精确地说，迭代继续使用新的位置来保存 @racket[id]，这些位置被初始化为对应 @racket[step-expr] 的值。

当 @racket[stop?-expr] 产生一个真值时，@racket[finish-expr] 按顺序求值，最后一个在尾部位置求值以产生 @racket[do] 形式的总体值。如果没有提供 @racket[finish-expr]，@racket[do] 形式的值是 @|void-const|。}

@close-eval[for-eval]
