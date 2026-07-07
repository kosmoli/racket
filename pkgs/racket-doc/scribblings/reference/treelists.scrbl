#lang scribble/manual
@(require "mz.rkt"
          (for-syntax racket/base)
          (for-label racket/treelist
                     racket/mutable-treelist))

@(define the-eval (make-base-eval))
@(the-eval '(require racket/treelist racket/mutable-treelist racket/stream))

@title[#:tag "treelist"]{Treelists}

@deftech{树列表}（treelist）以支持许多 @math{O(log N)} 时间操作的方式表示元素序列：按索引访问列表元素、添加到列表前端、添加到列表末尾、按索引删除元素、按索引替换元素、追加列表、从列表开头或末尾移除元素以及提取子列表。更一般地说，除非另有说明，长度为 @math{N} 的树列表上的操作需要 @math{O(log N)} 时间。@math{O(log N)} 中 @math{log} 的底数足够大，以至于在许多用途上它实际上是常数时间。树列表目前以 RRB 树的形式实现 @cite["Stucki15"]。

树列表主要通过 @racketmodname[racket/treelist] 以不可变形式使用，其中诸如向树列表添加元素等操作会生成新的树列表，而旧列表保持不变。树列表的可变变体由 @racketmodname[racket/mutable-treelist] 提供，其中可变树列表可以是将不可变树列表放入 @tech{box} 的便捷替代方案。除非另有说明，可变树列表操作与不可变树列表操作耗时相同。当术语"树列表"单独使用时，它指的是不可变树列表。

不可变或可变树列表可用作单值序列（参见 @secref["sequences"]）。列表的元素作为序列的元素。另请参见 @racket[in-treelist] 和 @racket[in-mutable-treelist]。不可变树列表还可用作 @tech{stream}。

@history[#:changed "8.15.0.3" @elem{使树列表可序列化。}]

@section[#:tag "treelists-s1"]{Immutable Treelists}

@note-lib-only[racket/treelist]

@history[#:added "8.12.0.7"]


@defproc[(treelist? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{树列表}，则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(treelist [v any/c] ...) treelist?]{

返回以 @racket[v] 为元素按顺序排列的 @tech{树列表}。

此操作构造包含 @math{N} 个元素的树列表需要 @math{O(N log N)} 时间。

@examples[
#:eval the-eval
(treelist 1 "a" 'apple)
]}

@defproc[(make-treelist [size exact-nonnegative-integer?] [v any/c]) treelist?]{

 返回大小为 @racket[size] 的 @tech{树列表}，其中每个元素均为 @racket[v]。
 此操作构造包含 @math{N} 个元素的树列表需要 @math{O(log N)} 时间。

 @examples[
 #:eval the-eval
 (make-treelist 0 'pear)
 (make-treelist 3 'pear)
 ]

@history[#:added "8.12.0.11"]}

@deftogether[(
@defproc[(treelist-empty? [tl treelist?]) boolean?]
@defthing[empty-treelist (and/c treelist? treelist-empty?)]
)]{

长度为 0 的 @tech{树列表}的谓词和常量。

虽然每个空树列表都与 @racket[empty-treelist] @racket[equal?]，但由于树列表可以通过 @racket[chaperone-treelist] 进行监护，并非每个空树列表都与 @racket[empty-treelist] @racket[eq?]。}


@defproc[(treelist-length [tl treelist?]) exact-nonnegative-integer?]{

返回 @racket[tl] 中的元素数量。此操作需要 @math{O(1)} 时间。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-length items)
]}

@defproc[(treelist-ref [tl treelist?] [pos exact-nonnegative-integer?]) any/c]{

返回 @racket[tl] 的第 @racket[pos] 个元素。第一个元素位于位置 @racket[0]，最后一个位置为 @racket[(treelist-length tl)] 减一。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-ref items 0)
(treelist-ref items 2)
(eval:error (treelist-ref items 3))
]}


@deftogether[(
@defproc[(treelist-first [tl treelist?]) any/c]
@defproc[(treelist-last [tl treelist?]) any/c]
)]{

使用 @racket[treelist-ref] 访问 @tech{树列表}的第一个或最后一个元素的简写形式。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-first items)
(treelist-last items)
]}


@defproc[(treelist-insert [tl treelist?] [pos exact-nonnegative-integer?] [v any/c]) treelist?]{

生成一个类似 @racket[tl] 的树列表，区别在于 @racket[v] 作为元素插入到 @racket[pos] 处的元素之前。如果 @racket[pos] 为 @racket[(treelist-length tl)]，则 @racket[v] 被添加到树列表的末尾。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-insert items 1 "alpha")
(treelist-insert items 3 "alpha")
]}


@deftogether[(
@defproc[(treelist-add [tl treelist?] [v any/c]) treelist?]
@defproc[(treelist-cons [tl treelist?] [v any/c]) treelist?]
)]{

使用 @racket[treelist-insert] 在 @tech{树列表}的末尾或开头插入的简写形式。

虽然扩展 pair @tech{list} 的主要操作是向前端添加的 @racket[cons]，但树列表的设计意图是通过 @racket[treelist-add] 向末尾添加来扩展，且 @racket[treelist-add] 通常比 @racket[treelist-cons] 更快。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-add items "alpha")
(treelist-cons items "alpha")
]}


@defproc[(treelist-delete [tl treelist?] [pos exact-nonnegative-integer?]) treelist?]{

生成一个类似 @racket[tl] 的树列表，区别在于位置 @racket[pos] 处的元素被移除。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-delete items 1)
(eval:error (treelist-delete items 3))
]}


@defproc[(treelist-set [tl treelist?] [pos exact-nonnegative-integer?] [v any/c]) treelist?]{

生成一个类似 @racket[tl] 的树列表，区别在于位置 @racket[pos] 处的元素被替换为 @racket[v]。结果等价于 @racket[(treelist-insert (treelist-delete tl pos) pos v)]。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-set items 1 "b")
]}

@defproc[(treelist-append [tl treelist?] ...) treelist?]{

将给定 @racket[tl] 的元素追加到单个 @tech{树列表}中。如果给出 @math{M} 个树列表且结果树列表的长度为 @math{N}，则追加操作需要 @math{O(M log N)} 时间。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-append items items)
(treelist-append items (treelist "middle") items)
]}

@deftogether[(
@defproc[(treelist-take [tl treelist?] [n exact-nonnegative-integer?]) treelist?]
@defproc[(treelist-drop [tl treelist?] [n exact-nonnegative-integer?]) treelist?]
@defproc[(treelist-take-right [tl treelist?] [n exact-nonnegative-integer?]) treelist?]
@defproc[(treelist-drop-right [tl treelist?] [n exact-nonnegative-integer?]) treelist?]
)]{

生成一个类似 @racket[tl] 的 @tech{树列表}，但分别仅保留前 @racket[n] 个元素、去除前 @racket[n] 个元素、仅保留后 @racket[n] 个元素或去除后 @racket[n] 个元素。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-take items 2)
(treelist-drop items 2)
(treelist-take-right items 2)
(treelist-drop-right items 2)
]}

@defproc[(treelist-sublist [tl treelist?] [n exact-nonnegative-integer?] [m exact-nonnegative-integer?]) treelist?]{

生成一个类似 @racket[tl] 的 @tech{树列表}，但仅包含位置 @racket[n]（含）到位置 @racket[m]（不含）的元素。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-sublist items 1 3)
]}


@defproc[(treelist-reverse  [tl treelist?]) treelist?]{

生成一个类似 @racket[tl] 的 @tech{树列表}，但其元素顺序反转，等价于使用 @racket[treelist-take] 保留 @racket[0] 个元素（同时保留树列表上的任何监护），然后按逆序重新添加每个元素。反转操作需要 @math{O(N log N)} 时间。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-reverse items)
]}


@defproc[(treelist-rest [tl treelist?]) treelist?]{

使用 @racket[treelist-drop] 删除 @tech{树列表}第一个元素的简写形式。

@racket[treelist-rest] 操作是高效的，但不如 @racket[rest] 或 @racket[cdr] 快。要遍历树列表，请考虑改用 @racket[treelist-ref] 或配合 @racket[in-treelist] 使用 @racket[for] 形式。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-rest items)
]}


@deftogether[(
@defproc[(treelist->vector [tl treelist?]) vector?]
@defproc[(treelist->list [tl treelist?]) list?]
@defproc[(vector->treelist [vec vector?]) treelist?]
@defproc[(list->treelist [lst list?]) treelist?]
)]{

在 @tech{树列表}、@tech{lists} 和 @tech{vectors} 之间转换的便捷函数。每次转换需要 @math{O(N)} 时间。

@examples[
#:eval the-eval
(define items (list->treelist '(1 "a" 'apple)))
(treelist->vector items)
]}


@defproc[(treelist-map [tl treelist?] [proc (any/c . -> . any/c)]) treelist?]{

通过对 @racket[tl] 的每个元素应用 @racket[proc] 并将结果收集到新树列表中来生成 @tech{树列表}。对于常数时间的 @racket[proc]，此操作需要 @math{O(N)} 时间。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-map items box)
]}


@defproc[(treelist-for-each [tl treelist?] [proc (any/c . -> . any)]) void?]{

对 @racket[tl] 的每个元素应用 @racket[proc]，忽略结果。对于常数时间的 @racket[proc]，此操作需要 @math{O(N)} 时间。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-for-each items println)
]}

@defproc[(treelist-filter [keep (any/c . -> . any/c)] [tl treelist?])
         treelist?]{

生成仅包含 @racket[tl] 中满足 @racket[keep] 的成员的树列表。

@examples[
#:eval the-eval
(treelist-filter even? (treelist 1 2 3 2 4 5 2))
(treelist-filter odd? (treelist 1 2 3 2 4 5 2))
(treelist-filter (λ (x) (not (even? x))) (treelist 1 2 3 2 4 5 2))
(treelist-filter (λ (x) (not (odd? x))) (treelist 1 2 3 2 4 5 2))
]

@history[#:added "8.15.0.6"]}

@defproc[(treelist-member? [tl treelist?] [v any/c] [eql? (any/c any/c . -> . any/c) equal?]) boolean?]{

使用 @racket[eql?] 和 @racket[v]（以 @racket[v] 作为第二个参数）检查 @racket[tl] 的每个元素，直到结果为真值，然后返回 @racket[#t]。如果未找到此类元素，则结果为 @racket[#f]。对于常数时间的 @racket[eql?]，此操作需要 @math{O(N)} 时间。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-member? items "a")
(treelist-member? items 1.0 =)
(eval:error (treelist-member? items 2.0 =))
]}

@defproc[(treelist-find [tl treelist?] [pred (any/c . -> . any/c)]) any/c]{

使用 @racket[pred] 检查 @racket[tl] 的每个元素，直到结果为真值，然后返回该元素。如果未找到此类元素，则结果为 @racket[#f]。对于常数时间的 @racket[pred]，此操作需要 @math{O(N)} 时间。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-find items string?)
(treelist-find items symbol?)
(treelist-find items number->string)
]}

@defproc[(treelist-index-of [tl treelist?]
                            [v any/c]
                            [eql? (any/c any/c . -> . any/c) equal?])
         (or/c exact-nonnegative-integer? #f)]{

返回 @racket[tl] 中第一个与 @racket[v] @racket[eql?] 相等的元素的索引。如果未找到此类元素，则结果为 @racket[#f]。

@examples[
#:eval the-eval
(define items (treelist 1 "a" 'apple))
(treelist-index-of items 1)
(treelist-index-of items "a")
(treelist-index-of items 'apple)
(treelist-index-of items 'unicorn)
]

@history[#:added "8.15.0.6"]}

@defproc[(treelist-flatten [v any/c]) treelist?]{

将嵌套树列表的树展平为单个树列表。

@examples[
#:eval the-eval
(treelist-flatten
 (treelist (treelist "a") "b" (treelist "c" (treelist "d") "e") (treelist)))
(treelist-flatten "a")
]

@history[#:added "8.15.0.6"]}

@defproc[(treelist-append* [tlotl (treelist/c treelist?)]) treelist?]{

将树列表的树列表的元素追加到一个树列表中，保持任何更深层嵌套的树列表不变。

@examples[
#:eval the-eval
(treelist-append*
 (treelist (treelist "a" "b") (treelist "c" (treelist "d") "e") (treelist)))
]

@history[#:added "8.15.0.6"]}

@defproc[(treelist-sort [tl treelist?]
                        [less-than? (any/c any/c . -> . any/c)]
                        [#:key key (or/c #f (any/c . -> . any/c)) #f]
                        [#:cache-keys? cache-keys? boolean? #f])
         treelist?]{

类似 @racket[sort]，但操作于 @tech{树列表}以生成排序后的树列表。排序需要 @math{O(N log N)} 时间。

@examples[
#:eval the-eval
(define items (treelist "x" "a" "q"))
(treelist-sort items string<?)
]}

@defproc[(in-treelist [tl treelist?]) sequence?]{

返回一个等价于 @racket[tl] 的 @tech{sequence}。
@speed[in-treelist "treelist"]

@examples[
#:eval the-eval
(define items (treelist "x" "a" "q"))
(for/list ([e (in-treelist items)])
  (string-append e "!"))
]}

@defproc[(sequence->treelist [s sequence?]) treelist?]{

返回一个树列表，其元素为 @racket[s] 的元素，其中每个元素必须是单个值。如果 @racket[s] 是无限的，此函数不会终止。

@examples[
#:eval the-eval
(sequence->treelist (list 1 "a" 'apple))
(sequence->treelist (vector 1 "a" 'apple))
(sequence->treelist (stream 1 "a" 'apple))
(sequence->treelist (open-input-bytes (bytes 1 2 3 4 5)))
(sequence->treelist (in-range 0 10))
]

@history[#:added "8.15.0.6"]}

@deftogether[(
@defform[(for/treelist (for-clause ...) body-or-break ... body)]
@defform[(for*/treelist (for-clause ...) body-or-break ... body)]
)]{

类似 @racket[for/list] 和 @racket[for*/list]，但生成 @tech{树列表}。

@examples[
#:eval the-eval
(for/treelist ([i (in-range 10)])
  i)
]}

@defproc[(chaperone-treelist [tl treelist?]
                             [#:state state any/c]
                             [#:state-key state-key any/c (list 'fresh)]
                             [#:ref ref-proc (treelist? exact-nonnegative-integer? any/c any/c
                                              . -> . any/c)]
                             [#:set set-proc (treelist? exact-nonnegative-integer? any/c any/c
                                              . -> . (values any/c any/c))]
                             [#:insert insert-proc (treelist? exact-nonnegative-integer? any/c any/c
                                                    . -> . (values any/c any/c))]
                             [#:delete delete-proc (treelist? exact-nonnegative-integer? any/c
                                                    . -> . any/c)]
                             [#:take take-proc (treelist? exact-nonnegative-integer? any/c
                                                . -> . any/c)]
                             [#:drop drop-proc (treelist? exact-nonnegative-integer? any/c
                                                . -> . any/c)]
                             [#:append append-proc (treelist? treelist? any/c
                                                    . -> . (values treelist? any/c))]
                             [#:prepend prepend-proc (treelist? treelist? any/c
                                                      . -> . (values treelist? any/c))]
                             [#:append2 append2-proc (or/c #f (treelist? treelist? any/c any/c
                                                               . -> . (values treelist? any/c any/c))) #f]
                             [prop impersonator-property?]
                             [prop-val any/c] ... ...)
          (and/c treelist? chaperone?)]{

类似 @racket[chaperone-vector]，返回 @racket[tl] 的一个 @tech{监护}（chaperone），它重定向 @racket[treelist-ref]、@racket[treelist-set]、@racket[treelist-insert]、@racket[treelist-append]、@racket[treelist-delete]、@racket[treelist-take] 和 @racket[treelist-drop] 操作，以及由这些操作派生的操作。@racket[state] 参数是初始状态，状态值会传递给每个重定向操作的过程，除 @racket[ref-proc] 外（它对应于不更新树列表的唯一操作），新状态会被返回以与更新后的树列表关联。当提供 @racket[state-key] 时，可结合 @racket[treelist-chaperone-state] 从原始树列表或更新后的树列表中提取状态。

@racket[ref-proc] 过程必须接受 @racket[tl]、传递给 @racket[treelist-ref] 的索引、对 @racket[tl] 调用 @racket[treelist-ref] 在给定索引处产生的值以及当前监护状态；它必须产生该值的监护替换值，作为在监护对象上调用 @racket[treelist-ref] 的结果。

@racket[set-proc] 过程必须接受 @racket[tl]、传递给 @racket[treelist-set] 的索引、提供给 @racket[treelist-set] 的值以及当前监护状态；它必须产生两个值：该值的监护替换值（用于在监护对象上调用 @racket[treelist-set] 的结果）和更新后的状态。@racket[treelist-set] 的结果使用与 @racket[tl] 相同的过程和属性进行监护，但使用更新后的状态。

@racket[insert-proc] 过程类似 @racket[set-proc]，但用于通过 @racket[treelist-insert] 进行插入。

@racket[delete-proc]、@racket[take-proc] 和 @racket[drop-proc] 过程必须接受 @racket[tl]、用于删除、保留或丢弃的索引或数量以及当前监护状态；它们必须产生更新后的状态。@racket[treelist-delete]、@racket[treelist-take] 或 @racket[treelist-drop] 的结果使用与 @racket[tl] 相同的过程和属性进行监护，但使用更新后的状态。

@racket[append-proc] 过程必须接受 @racket[tl]、要追加到 @racket[tl] 的树列表以及当前监护状态；它必须产生第二个树列表的监护替换值（该值被追加到监护对象上 @racket[treelist-append] 的结果中）和更新后的状态。@racket[treelist-append] 的结果使用与 @racket[tl] 相同的过程和属性进行监护，但使用更新后的状态。

@racket[prepend-proc] 过程必须接受正在与 @racket[tl] 追加的树列表、@racket[tl] 以及当前监护状态；它必须产生第一个树列表的监护替换值（该值被前置到监护对象上 @racket[treelist-append] 的结果中）和更新后的状态。@racket[treelist-append] 的结果使用与 @racket[tl] 相同的过程和属性进行监护，但使用更新后的状态。

@racket[append2-proc] 过程是可选的，类似于 @racket[append-proc]，但当其为非 @racket[#f] 时，如果 @racket[treelist-append] 的第二个参数使用相同的 @racket[state-key] 进行监护，则使用 @racket[append2-proc] 而非 @racket[append-proc]。在这种情况下，传递给 @racket[append2-proc] 的第二个参数是移除了 @racket[state-key] 监护包装的第二个参数，并将该监护的状态作为 @racket[append2-proc] 的最后一个参数。

当两个受监护的树列表被传递给 @racket[treelist-append] 且未使用 @racket[append2-proc] 时，将使用第一个树列表的 @racket[append-proc]，且 @racket[append-proc] 的结果仍将是一个监护对象，其 @racket[prepend-proc] 会被使用。如果 @racket[prepend-proc] 的结果是监护对象，则使用该监护对象的 @racket[append-proc]，以此类推。如果 @racket[prepend-proc] 和 @racket[append-proc] 持续返回监护对象，则可能无法取得进展。

@examples[
#:eval the-eval
(chaperone-treelist
 (treelist 1 "a" 'apple)
 #:state 'ignored-state
 #:ref (λ (tl _pos _v state)
         _v)
 #:set (λ (tl _pos _v state)
         (values _v state))
 #:insert (λ (tl _pos _v state)
            (values _v state))
 #:delete (λ (tl _pos state)
            state)
 #:take (λ (tl _pos state)
          state)
 #:drop (λ (tl _pos state)
          state)
 #:append2 (λ (tl _other state _other-state) (code:comment @#,elem{or @racket[#f]})
             (values _other state))
 #:append (λ (tl _other state)
            (values _other state))
 #:prepend (λ (_other tl state)
             (values _other state)))
 ]}

@defproc[(treelist-chaperone-state [tl treelist?]
                                   [state-key any/c]
                                   [fail-k (procedure-arity-includes/c 0) _key-error]) any/c]{

提取与树列表监护关联的状态，其中 @racket[state-key]（使用 @racket[eq?] 比较）随初始状态一起提供给 @racket[chaperone-treelist]。如果 @racket[tl] 不是以 @racket[state-key] 为键的状态的监护对象，则调用 @racket[fail-k]，默认的 @racket[fail-k] 会引发 @racket[exn:fail:contract]。

}



@section[#:tag "treelists-s2"]{Mutable Treelists}

@note-lib-only[racket/mutable-treelist]

@deftech{可变树列表}类似于放在盒子中的不可变 @tech{树列表}，其中改变可变树列表的操作会替换盒子中的树列表。作为一种特殊情况，在未拟人化的可变树列表上调用 @racket[mutable-treelist-set!] 会修改盒子值内的树列表表示。这种可变树列表模型解释了其在并发修改情况下的行为：对不同位置的并发 @racket[mutable-treelist-set!] 操作不会互相干扰，但与其他操作的竞争或在拟人化可变树列表上的竞争有时会否定其中一项修改。因此，并发修改在某种程度上不可预测，但仍然是安全的，且不由锁管理。

可变树列表不是 @racket[treelist?] 意义上的树列表，后者仅识别不可变树列表。除非另有说明，可变树列表上的操作与不可变树列表上对应操作具有相同的时间复杂度。

@history[#:added "8.12.0.7"]

@defproc[(mutable-treelist? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{可变树列表}，则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(mutable-treelist [v any/c] ...) mutable-treelist?]{

返回以 @racket[v] 为元素按顺序排列的 @tech{可变树列表}。

@examples[
#:eval the-eval
(mutable-treelist 1 "a" 'apple)
]}

@defproc[(make-mutable-treelist [n exact-nonnegative-integer?] [v any/c #f]) mutable-treelist?]{

创建一个包含 @racket[n] 个元素的 @tech{可变树列表}，每个元素初始化为 @racket[v]。创建包含 @math{N} 个元素的可变树列表需要 @math{O(N)} 时间。

@examples[
#:eval the-eval
(make-mutable-treelist 3 "a")
]}


@deftogether[(
@defproc[(treelist-copy [tl treelist?]) mutable-treelist?]
@defproc[(mutable-treelist-copy [tl mutable-treelist?]) mutable-treelist?]
)]{

创建一个包含与 @racket[tl] 相同元素的 @tech{可变树列表}。创建包含 @math{N} 个元素的可变树列表需要 @math{O(N)} 时间。

@examples[
#:eval the-eval
(treelist-copy (treelist 3 "a"))
(mutable-treelist-copy (mutable-treelist 3 "a"))
]}

@defproc[(mutable-treelist-snapshot [tl mutable-treelist?]
                                    [n exact-nonnegative-integer? 0]
                                    [m (or/c #f exact-nonnegative-integer?) #f])
         treelist?]{

生成一个不可变 @tech{树列表}，其元素与 @racket[tl] 在位置 @racket[n]（含）到位置 @racket[m]（不含）的元素相同。如果 @racket[m] 为 @racket[#f]，则改用 @racket[tl] 的长度。创建包含结果树列表中 @math{N} 个元素的不可变树列表需要 @math{O(N)} 时间，如果结果是子列表，还需加上 @racket[treelist-sublist] 的开销。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(define snap (mutable-treelist-snapshot items))
snap
(mutable-treelist-snapshot items 1)
(mutable-treelist-snapshot items 1 2)
(mutable-treelist-drop! items 2)
items
snap
]}


@defproc[(mutable-treelist-empty? [tl mutable-treelist?]) boolean?]{

对于当前长度为 0 的 @tech{可变树列表}返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(mutable-treelist-length [tl mutable-treelist?]) exact-nonnegative-integer?]{

返回 @racket[tl] 中当前的元素数量。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-length items)
(mutable-treelist-add! items 'extra)
(mutable-treelist-length items)
]}

@defproc[(mutable-treelist-ref [tl mutable-treelist?] [pos exact-nonnegative-integer?]) any/c]{

返回 @racket[tl] 的第 @racket[pos] 个元素。第一个元素位于位置 @racket[0]，最后一个位置为 @racket[(mutable-treelist-length tl)] 减一。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-ref items 0)
(mutable-treelist-ref items 2)
(eval:error (mutable-treelist-ref items 3))
]}


@deftogether[(
@defproc[(mutable-treelist-first [tl mutable-treelist?]) any/c]
@defproc[(mutable-treelist-last [tl mutable-treelist?]) any/c]
)]{

使用 @racket[mutable-treelist-ref] 访问 @tech{树列表}的第一个或最后一个元素的简写形式。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-first items)
(mutable-treelist-last items)
]}


@defproc[(mutable-treelist-insert! [tl mutable-treelist?] [pos exact-nonnegative-integer?] [v any/c]) void?]{

修改 @racket[tl]，在位置 @racket[pos] 之前将 @racket[v] 插入列表中。如果 @racket[pos] 为 @racket[(mutable-treelist-length tl)]，则 @racket[v] 被添加到树列表的末尾。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-insert! items 1 "alpha")
items
]}


@deftogether[(
@defproc[(mutable-treelist-cons! [tl mutable-treelist?] [v any/c]) void?]
@defproc[(mutable-treelist-add! [tl mutable-treelist?] [v any/c]) void?]
)]{

使用 @racket[mutable-treelist-insert!] 在 @tech{树列表}的开头或末尾插入的简写形式。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-cons! items "before")
(mutable-treelist-add! items "after")
items
]}


@defproc[(mutable-treelist-delete! [tl mutable-treelist?] [pos exact-nonnegative-integer?]) void?]{

修改 @racket[tl]，移除位置 @racket[pos] 处的元素。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-delete! items 1)
items
]}


@defproc[(mutable-treelist-set! [tl mutable-treelist?] [pos exact-nonnegative-integer?] [v any/c]) void?]{

修改 @racket[tl]，将位置 @racket[pos] 处的元素改为 @racket[v]。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-set! items 1 "b")
items
]}

@deftogether[(
@defproc[(mutable-treelist-append! [tl mutable-treelist?] [other-tl (or/c treelist? mutable-treelist?)]) void?]
@defproc[(mutable-treelist-prepend! [tl mutable-treelist?] [other-tl (or/c treelist? mutable-treelist?)]) void?]
)]{

Modifies @racket[tl] by appending or prepending all of the elements of
@racket[other-tl], which takes @math{O(N)} time
if @racket[other-tl] has @math{N} elements.

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-append! items (treelist 'more 'things))
items
(mutable-treelist-prepend! items (treelist 0 "b" 'banana))
items
(mutable-treelist-append! items items)
items
]

@history[#:changed "8.15.0.11" @elem{Added @racket[mutable-treelist-prepend!].}
         #:changed "9.2.0.2" @elem{Repair to implementation implies @math{O(N)} time always.}]}

@deftogether[(
@defproc[(mutable-treelist-take! [tl mutable-treelist?] [n exact-nonnegative-integer?]) void?]
@defproc[(mutable-treelist-drop! [tl mutable-treelist?] [n exact-nonnegative-integer?]) void?]
@defproc[(mutable-treelist-take-right! [tl mutable-treelist?] [n exact-nonnegative-integer?]) void?]
@defproc[(mutable-treelist-drop-right! [tl mutable-treelist?] [n exact-nonnegative-integer?]) void?]
)]{

修改 @racket[tl]，分别仅保留前 @racket[n] 个元素、移除前 @racket[n] 个元素、仅保留后 @racket[n] 个元素或移除后 @racket[n] 个元素。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-take! items 2)
items
(mutable-treelist-drop-right! items 1)
items
]}

@defproc[(mutable-treelist-sublist! [tl mutable-treelist?] [n exact-nonnegative-integer?] [m exact-nonnegative-integer?]) void?]{

修改 @racket[tl]，移除位置 @racket[n]（含）到位置 @racket[m]（不含）之外的元素。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple 'pie))
(mutable-treelist-sublist! items 1 3)
items
]}

@defproc[(mutable-treelist-reverse! [tl mutable-treelist?]) void?]{

修改 @racket[tl]，反转其所有元素。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple 'pie))
(mutable-treelist-reverse! items)
items
]}

@deftogether[(
@defproc[(mutable-treelist->vector [tl mutable-treelist?]) vector?]
@defproc[(mutable-treelist->list [tl mutable-treelist?]) list?]
@defproc[(vector->mutable-treelist [vec vector?]) mutable-treelist?]
@defproc[(list->mutable-treelist [lst list?]) mutable-treelist?]
)]{

在 @tech{可变树列表}、@tech{lists} 和 @tech{vectors} 之间转换的便捷函数。每次转换需要 @math{O(N)} 时间。

@examples[
#:eval the-eval
(define items (list->mutable-treelist '(1 "a" 'apple)))
(mutable-treelist->vector items)
]}


@defproc[(mutable-treelist-map! [tl mutable-treelist?] [proc (any/c . -> . any/c)]) void?]{

修改 @racket[tl]，通过对 @racket[tl] 的每个元素应用 @racket[proc] 并将结果就地替换该元素。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-map! items box)
items
]}


@defproc[(mutable-treelist-for-each [tl mutable-treelist?] [proc (any/c . -> . any)]) void?]{

类似 @racket[treelist-for-each]，但用于 @tech{可变树列表}。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-for-each items println)
]}

@defproc[(mutable-treelist-member? [tl mutable-treelist?] [v any/c] [eql? (any/c any/c . -> . any/c) equal?]) boolean?]{

类似 @racket[treelist-member?]，但用于 @tech{可变树列表}。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-member? items "a")
(mutable-treelist-member? items 1.0 =)
]}

@defproc[(mutable-treelist-find [tl mutable-treelist?] [pred (any/c . -> . any/c)]) any/c]{

类似 @racket[treelist-find]，但用于 @tech{可变树列表}。

@examples[
#:eval the-eval
(define items (mutable-treelist 1 "a" 'apple))
(mutable-treelist-find items string?)
(mutable-treelist-find items symbol?)
]}

@defproc[(mutable-treelist-sort! [tl mutable-treelist?]
                                 [less-than? (any/c any/c . -> . any/c)]
                                 [#:key key (or/c #f (any/c . -> . any/c)) #f]
                                 [#:cache-keys? cache-keys? boolean? #f])
         void?]{

类似 @racket[vector-sort!]，但操作于 @tech{可变树列表}。

@examples[
#:eval the-eval
(define items (mutable-treelist "x" "a" "q"))
(mutable-treelist-sort! items string<?)
items
]}

@defproc[(in-mutable-treelist [tl mutable-treelist?]) sequence?]{

返回一个等价于 @racket[tl] 的 @tech{sequence}。
@speed[in-mutable-treelist "mutable treelist"]

@examples[
#:eval the-eval
(define items (mutable-treelist "x" "a" "q"))
(for/list ([e (in-mutable-treelist items)])
  (string-append e "!"))
]}

@deftogether[(
@defform[(for/mutable-treelist maybe-length (for-clause ...) body-or-break ... body)]
@defform[(for*/mutable-treelist maybe-length (for-clause ...) body-or-break ... body)]
)]{

类似 @racket[for/vector] 和 @racket[for*/vector]，但生成 @tech{可变树列表}。

@examples[
#:eval the-eval
(for/mutable-treelist ([i (in-range 10)]) i)
(for/mutable-treelist #:length 15 ([i (in-range 10)]) i)
(for/mutable-treelist #:length 15 #:fill 'a ([i (in-range 10)]) i)
]}

@defproc[(chaperone-mutable-treelist [tl mutable-treelist?]
                                     [#:ref ref-proc (mutable-treelist? exact-nonnegative-integer? any/c
                                                      . -> . any/c)]
                                     [#:set set-proc (mutable-treelist? exact-nonnegative-integer? any/c
                                                      . -> . any/c)]
                                     [#:insert insert-proc (mutable-treelist? exact-nonnegative-integer? any/c
                                                            . -> . any/c)]
                                     [#:append append-proc (mutable-treelist? treelist?
                                                            . -> . treelist?)]
                                     [#:prepend prepend-proc (treelist? mutable-treelist?
                                                              . -> . treelist?)
                                      (λ (o t) (append-proc t o))]
                                     [prop impersonator-property?]
                                     [prop-val any/c] ... ...)
          (and/c mutable-treelist? chaperone?)]{

类似 @racket[chaperone-treelist]，但用于 @tech{可变树列表}。例如，给定的 @racket[set-proc] 用于 @racket[mutable-treelist-set!]，其结果值被安装到可变树列表中，而非提供给 @racket[set-proc] 的值。可变树列表监护不具有独立于树列表本身的状态，像 @racket[set-proc] 这样的过程不消耗也不返回状态。}

@defproc[(impersonate-mutable-treelist [tl mutable-treelist?]
                                       [#:ref ref-proc (mutable-treelist? exact-nonnegative-integer? any/c
                                                        . -> . any/c)]
                                       [#:set set-proc (mutable-treelist? exact-nonnegative-integer? any/c
                                                        . -> . any/c)]
                                       [#:insert insert-proc (mutable-treelist? exact-nonnegative-integer? any/c
                                                              . -> . any/c)]
                                       [#:append append-proc (mutable-treelist? treelist?
                                                              . -> . treelist?)]
                                       [#:prepend prepend-proc (treelist? mutable-treelist?
                                                                . -> . treelist?)
                                        (λ (o t) (append-proc t o))]
                                       [prop impersonator-property?]
                                       [prop-val any/c] ... ...)
          (and/c mutable-treelist? impersonator?)]{

类似 @racket[chaperone-mutable-treelist]，但 @racket[ref-proc]、@racket[set-proc]、@racket[insert-proc] 和 @racket[append-proc] 不必产生监护对象。}


@(close-eval the-eval)
