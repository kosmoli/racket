#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "hashtables"]{哈希表}

@(define (see-also-caveats)
   @t{See also the @concurrency-caveat[] and the @mutable-key-caveat[] above.})
@(define (see-also-concurrency-caveat)
   @t{See also the @concurrency-caveat[] above.})
@(define (see-also-mutable-key-caveat)
   @t{See also the @mutable-key-caveat[] above.})

@guideintro["hash-tables"]{hash tables}

一个 @deftech{hash table}（或简称为 @deftech{hash}）将其中的每个键映射到单个值。对于给定的 hash table，键通过 @racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?] 等价，键可以强保留、弱保留（参见 @secref["weakbox"]）或像 @tech{ephemerons} 一样保留。hash table 也可以是可变的或不可变的。不可变 hash table 支持有效的常数时间访问和更新，就像可变 hash table 一样；不可变操作的常数通常更大，但不可变 hash table 的函数性质在某些算法中可以获得优势。使用 @racket[immutable?] 来检查一个 hash table 是否不可变。

@margin-note{不可变 hash table 实际上提供 @math{O(log N)} 的访问和更新。由于 @math{N} 受地址空间限制，因此 @math{log N} 被限制在小于 30 或 62 的范围内（取决于平台），@math{log N} 可以合理地视为常数。}

对于基于 @racket[equal?] 的哈希，对 @tech{strings}、@tech{pairs}、@tech{lists}、@tech{vectors}、@tech{prefab} 或透明 @tech{structures} 等内置 hash 函数所需时间与值的大小成正比。复合数据结构（如 list 或 vector）的 hash code 取决于对容器中每个项的哈希计算，但这种递归哈希的深度受到限制（以避免循环数据的潜在问题）。对于非 @tech{list} 的 @tech{pair}，@racket[car] 和 @racket[cdr] 的哈希都被视为更深一层的哈希，但 @tech{list} 的 @racket[cdr] 被视为与 list 具有相同的哈希深度。

hash table 可以用作双值 @tech{sequence}（参见 @secref["sequences"]）。hash table 的键和值作为 sequence 的元素（即每个元素是一个键及其关联的值）。如果在迭代过程中向可变 hash table 添加或删除映射，则迭代步骤可能因 @racket[exn:fail:contract] 失败，或者迭代可能跳过或重复键和值。另请参见 @racket[in-hash]、@racket[in-hash-keys]、@racket[in-hash-values] 和 @racket[in-hash-pairs]。

两个 hash table 不能是 @racket[equal?] 的，除非它们具有相同的可变性、使用相同的键比较过程（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）、都以强、弱或像 @tech{ephemerons} 的方式持有键。空的不可变 hash table 在 @racket[equal?] 时是 @racket[eq?] 的。

@history[#:changed "7.2.0.9" @elem{Made empty immutable hash tables
                                   @racket[eq?] when they are
                                   @racket[equal?].}]

@elemtag['(caveat "concurrency")]{@bold{关于并发修改的注意事项：}} 可变 hash table 可以由多个线程通过 @racket[hash-ref]、@racket[hash-set!] 和 @racket[hash-remove!] 并发操作，并且这些操作根据需要由表特定的 semaphore 保护。然而，有几点注意事项：

 @itemize[

  @item{如果线程在对使用 @racket[equal?]、@racket[equal-always?] 或 @racket[eqv?] 键比较的 hash table 应用 @racket[hash-ref]、@racket[hash-ref-key]、@racket[hash-set!]、@racket[hash-remove!]、@racket[hash-ref!]、@racket[hash-update!] 或 @racket[hash-clear!] 时终止，则该 hash table 上所有当前和未来的操作可能无限期阻塞。}

  @item{@racket[hash-map]、@racket[hash-for-each] 和 @racket[hash-clear!] 过程不使用表的 semaphore 来保护整个遍历（在 @racket[hash-clear!] 需要遍历的情况下）。一个线程对 hash table 的更改可能影响另一个线程在遍历同一 hash table 时中途看到的键和值。}

 @item{@racket[hash-update!] 和 @racket[hash-ref!] 函数在其功能的 @racket[hash-ref] 和 @racket[hash-set!] 部分独立使用表的 semaphore，这意味着更新作为一个整体不是``原子的''。}

 @item{将可变 hash table 作为自身的键添加是麻烦的，因为键正在被修改（参见下面的注意事项），但这也是对 hash table 的一种并发使用：计算 hash table 的 hash code 可能需要等待表的 semaphore，但 semaphore 已经被持有以修改 hash table，因此 hash-table 添加操作可能无限期阻塞。}

 ]

@elemtag['(caveat "mutable-keys")]{@bold{关于可变键的注意事项：}} 如果基于 @racket[equal?] 的 hash table 中的键被修改（例如，键字符串用 @racket[string-set!] 修改），则 hash table 对插入和查找操作的行为变得不可预测。

字面量或打印的 hash table 以 @litchar{#hash}、@litchar{#hashalw}、@litchar{#hasheqv} 或 @litchar{#hasheq} 开头。@see-read-print["hashtable"]{hash tables}

@defproc[(hash? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{hash table}，则返回 @racket[#t]，否则返回 @racket[#f]。

另请参见 @racket[immutable-hash?] 和 @racket[mutable-hash?]。}

@defproc[(hash-equal? [ht hash?]) boolean?]{

如果 @racket[ht] 使用 @racket[equal?] 比较键则返回 @racket[#t]，如果使用 @racket[eq?]、@racket[eqv?] 或 @racket[equal-always?] 比较则返回 @racket[#f]。}

@defproc[(hash-equal-always? [ht hash?]) boolean?]{

如果 @racket[ht] 使用 @racket[equal-always?] 比较键则返回 @racket[#t]，如果使用 @racket[eq?]、@racket[eqv?] 或 @racket[equal?] 比较则返回 @racket[#f]。

@history[#:added "8.5.0.3"]}

@defproc[(hash-eqv? [ht hash?]) boolean?]{

如果 @racket[ht] 使用 @racket[eqv?] 比较键则返回 @racket[#t]，如果使用 @racket[equal?]、@racket[equal-always?] 或 @racket[eq?] 比较则返回 @racket[#f]。}

@defproc[(hash-eq? [ht hash?]) boolean?]{

如果 @racket[ht] 使用 @racket[eq?] 比较键则返回 @racket[#t]，如果使用 @racket[equal?]、@racket[equal-always?] 或 @racket[eqv?] 比较则返回 @racket[#f]。}


@defproc[(hash-strong? [ht hash?]) boolean?]{

如果 @racket[ht] 强保留其键则返回 @racket[#t]，如果弱保留或像 @tech{ephemerons} 一样保留则返回 @racket[#f]。

@history[#:added "8.0.0.10"]}


@defproc[(hash-weak? [ht hash?]) boolean?]{

如果 @racket[ht] 弱保留其键则返回 @racket[#t]，如果强保留或像 @tech{ephemerons} 一样保留则返回 @racket[#f]。}


@defproc[(hash-ephemeron? [ht hash?]) boolean?]{

如果 @racket[ht] 像 @tech{ephemerons} 一样保留其键则返回 @racket[#t]，如果强保留或仅弱保留则返回 @racket[#f]。

@history[#:added "8.0.0.10"]}


@deftogether[(
@defproc[(hash [key any/c] [val any/c] ... ...) (and/c hash? hash-equal? immutable? hash-strong?)]
@defproc[(hashalw [key any/c] [val any/c] ... ...)
         (and/c hash? hash-equal-always? immutable? hash-strong?)]
@defproc[(hasheq [key any/c] [val any/c] ... ...) (and/c hash? hash-eq? immutable? hash-strong?)]
@defproc[(hasheqv [key any/c] [val any/c] ... ...) (and/c hash? hash-eqv? immutable? hash-strong?)]
)]{

创建一个不可变 hash table，将每个给定的 @racket[key] 映射到其后的 @racket[val]；每个 @racket[key] 必须有一个 @racket[val]，因此 @racket[hash] 的参数总数必须是偶数。

@racket[hash] 过程创建一个键通过 @racket[equal?] 比较的表，@racket[hashalw] 创建一个键通过 @racket[equal-always?] 比较的表，@racket[hasheq] 过程创建一个键通过 @racket[eq?] 比较的表，@racket[hasheqv] 过程创建一个键通过 @racket[eqv?] 比较的表。

@racket[key] 到 @racket[val] 的映射按参数列表中的出现顺序添加到表中，因此后续映射可能隐藏较早的映射（如果 @racket[key] 相等的话）。

@history[#:changed "8.5.0.3" @elem{Added @racket[hashalw].}]}

@deftogether[(
@defproc[(make-hash [assocs (listof pair?) null]) (and/c hash? hash-equal? (not/c immutable?) hash-strong?)]
@defproc[(make-hashalw [assocs (listof pair?) null])
         (and/c hash? hash-equal-always? (not/c immutable?) hash-strong?)]
@defproc[(make-hasheqv [assocs (listof pair?) null]) (and/c hash? hash-eqv? (not/c immutable?) hash-strong?)]
@defproc[(make-hasheq [assocs (listof pair?) null]) (and/c hash? hash-eq? (not/c immutable?) hash-strong?)]
)]{

创建一个强保留键的可变 hash table。 

@racket[make-hash] 过程创建一个键通过 @racket[equal?] 比较的表，@racket[make-hasheq] 过程创建一个键通过 @racket[eq?] 比较的表，@racket[make-hasheqv] 过程创建一个键通过 @racket[eqv?] 比较的表，@racket[make-hashalw] 创建一个键通过 @racket[equal-always?] 比较的表。

该表用 @racket[assocs] 的内容初始化。在 @racket[assocs] 的每个元素中，@racket[car] 是键，@racket[cdr] 是对应的值。映射按 @racket[assocs] 中的出现顺序添加到表中，因此后续映射可能隐藏较早的映射。

另请参见 @racket[make-custom-hash]。

@examples[
#:eval the-eval
(make-hash)
(make-hash '([0 . 1] [42 . "meaning of life"] [2 . 3]))
(make-hash '([0 . 1] [1 . 2] [0 . 3]))
(make-hash (list (cons 0 1) (cons 'apple 'orange) (cons #t #f)))
(make-hash '((0 1) (1 2) (2 3)))
(make-hash (list (cons + -)))
]

@history[#:changed "8.5.0.3" @elem{Added @racket[make-hashalw].}]}

@deftogether[(
@defproc[(make-weak-hash [assocs (listof pair?) null]) (and/c hash? hash-equal? (not/c immutable?) hash-weak?)]
@defproc[(make-weak-hashalw [assocs (listof pair?) null])
         (and/c hash? hash-equal-always? (not/c immutable?) hash-weak?)]
@defproc[(make-weak-hasheqv [assocs (listof pair?) null]) (and/c hash? hash-eqv? (not/c immutable?) hash-weak?)]
@defproc[(make-weak-hasheq [assocs (listof pair?) null]) (and/c hash? hash-eq? (not/c immutable?) hash-weak?)]
)]{

类似于 @racket[make-hash]、@racket[make-hasheq]、@racket[make-hasheqv] 和 @racket[make-hashalw]，但创建一个弱保留键的可变 hash table。

注意，弱 hash table 中的值是正常保留的。如果表中的值引用回其键，则该表将保留该值，从而保留该键；即使键变得无法访问，该映射也永远不会从表中移除。为避免该问题，请使用由 @racket[make-ephemeron-hash]、@racket[make-ephemeron-hashalw]、@racket[make-ephemeron-hasheqv] 或 @racket[make-ephemeron-hasheq] 创建的 ephemeron hash table。对于不引用键的值，使用 ephemeron hash table 而非 weak hash table 有适度的额外成本，但在不确定时请优先使用 ephemeron hash table。

@history[#:changed "8.5.0.3" @elem{Added @racket[make-weak-hashalw].}]}


@deftogether[(
@defproc[(make-ephemeron-hash [assocs (listof pair?) null]) (and/c hash? hash-equal? (not/c immutable?) hash-ephemeron?)]
@defproc[(make-ephemeron-hashalw [assocs (listof pair?) null])
         (and/c hash? hash-equal-always? (not/c immutable?) hash-ephemeron?)]
@defproc[(make-ephemeron-hasheqv [assocs (listof pair?) null]) (and/c hash? hash-eqv? (not/c immutable?) hash-ephemeron?)]
@defproc[(make-ephemeron-hasheq [assocs (listof pair?) null]) (and/c hash? hash-eq? (not/c immutable?) hash-ephemeron?)]
)]{

类似于 @racket[make-hash]、@racket[make-hasheq]、@racket[make-hasheqv] 和 @racket[make-hashalw]，但创建一个以与 @tech{ephemeron} 相同的方式持有键值组合的可变 hash table。

使用 ephemeron hash table 就像使用 weak hash table 并将每个键映射到一个将键和值配对的 @tech{ephemeron}。ephemeron hash table 的一个优势是，值不需要通过 @racket[ephemeron-value] 从 @racket[hash-ref] 等函数的结果中提取。ephemeron hash table 也可能比带有显式 @tech{ephemeron} 值的 weak hash table 更紧凑地表示。

@history[#:added "8.0.0.10"
         #:changed "8.5.0.3" @elem{Added @racket[make-ephemeron-hashalw].}]}

@deftogether[(
@defproc[(make-immutable-hash [assocs (listof pair?) null])
         (and/c hash? hash-equal? immutable? hash-strong?)]
@defproc[(make-immutable-hashalw [assocs (listof pair?) null])
         (and/c hash? hash-equal-always? immutable? hash-strong?)]
@defproc[(make-immutable-hasheqv [assocs (listof pair?) null])
         (and/c hash? hash-eqv? immutable? hash-strong?)]
@defproc[(make-immutable-hasheq [assocs (listof pair?) null])
         (and/c hash? hash-eq? immutable? hash-strong?)]
)]{

类似于 @racket[hash]、@racket[hashalw]、@racket[hasheq] 和 @racket[hasheqv]，但像 @racket[make-hash]、@racket[make-hashalw]、@racket[make-hasheq] 和 @racket[make-hasheqv] 一样以 association-list 形式接受键值映射。

@history[#:changed "8.5.0.3" @elem{Added @racket[make-immutable-hashalw].}]}


@defproc[(hash-set! [ht (and/c hash? (not/c immutable?))]
                    [key any/c]
                    [v any/c]) void?]{

在 @racket[ht] 中将 @racket[key] 映射到 @racket[v]，覆盖 @racket[key] 的任何现有映射。

@see-also-caveats[]}

@defproc[(hash-set*! [ht (and/c hash? (not/c immutable?))]
                     [key any/c]
                     [v any/c]
                     ...
                     ...) void?]{

在 @racket[ht] 中将每个 @racket[key] 映射到每个 @racket[v]，覆盖每个 @racket[key] 的任何现有映射。映射从左边添加，因此后续映射覆盖较早的映射。

@see-also-caveats[]}


@defproc[(hash-set [ht (and/c hash? immutable?)]
                   [key any/c]
                   [v any/c])
          (and/c hash? immutable?)]{

通过将 @racket[key] 映射到 @racket[v] 函数式地扩展 @racket[ht]，覆盖 @racket[key] 的任何现有映射，并返回扩展后的 hash table。

@see-also-mutable-key-caveat[]}

@defproc[(hash-set* [ht (and/c hash? immutable?)]
                    [key any/c]
                    [v any/c]
                    ...
                    ...)
          (and/c hash? immutable?)]{

通过将每个 @racket[key] 映射到 @racket[v] 函数式地扩展 @racket[ht]，覆盖每个 @racket[key] 的任何现有映射，并返回扩展后的 hash table。映射从左边添加，因此后续映射覆盖较早的映射。

@see-also-mutable-key-caveat[]}

@defproc[(hash-ref [ht hash?]
                   [key any/c]
                   [failure-result failure-result/c
                                   (lambda ()
                                     (raise (make-exn:fail:contract ....)))])
         any]{

返回 @racket[ht] 中 @racket[key] 的值。如果没有找到 @racket[key] 的值，则 @racket[failure-result] 确定结果： 

@itemize[

 @item{如果 @racket[failure-result] 是一个过程，则通过尾调用无参数地调用它以生成结果。}

 @item{否则，@racket[failure-result] 作为结果返回。}

]

@examples[
#:eval the-eval
(eval:error (hash-ref (hash) "hi"))
(hash-ref (hash) "hi" 5)
(hash-ref (hash) "hi" (lambda () "flab"))
(hash-ref (hash "hi" "bye") "hi")
(eval:error (hash-ref (hash "hi" "bye") "no"))
]

@see-also-caveats[]}

@defproc[(hash-ref-key [ht hash?]
                       [key any/c]
                       [failure-result failure-result/c
                                       (lambda ()
                                         (raise (make-exn:fail:contract ....)))])
         any]{

返回 @racket[ht] 中持有的、根据 @racket[ht] 的键比较函数与 @racket[key] 等价的键。如果未找到键，则 @racket[failure-result] 像 @racket[hash-ref] 中那样用于确定结果。

如果 @racket[ht] 不是 @tech{impersonator}，那么返回的键（假设找到了）将与 @racket[ht] 实际保留的键 @racket[eq?] 等价：

@examples[
#:eval the-eval
(define original-key "hello")
(define key-copy (string-copy original-key))

(equal? original-key key-copy)
(eq? original-key key-copy)

(define table (make-hash))
(hash-set! table original-key 'value)

(eq? (hash-ref-key table "hello") original-key)
(eq? (hash-ref-key table "hello") key-copy)
]

如果可变 hash 使用不 @racket[eq?] 等价但根据 hash 的键比较过程等价的键多次更新，hash 保留第一个：

@examples[
#:eval the-eval
(define original-key "hello")
(define key-copy (string-copy original-key))

(define table (make-hash))
(hash-set! table original-key 'one)
(hash-set! table key-copy 'two)

(eq? (hash-ref-key table "hello") original-key)
(eq? (hash-ref-key table "hello") key-copy)
]

反之，不可变 hash 保留最近用于更新它的键：
@examples[
#:eval the-eval
(define original-key "hello")
(define key-copy (string-copy original-key))

(define table0 (hash))
(define table1 (hash-set table0 original-key 'one))
(define table2 (hash-set table1 key-copy 'two))

(eq? (hash-ref-key table2 "hello") original-key)
(eq? (hash-ref-key table2 "hello") key-copy)
]

如果 @racket[ht] 是 @tech{impersonator}，则返回的键将如 @racket[impersonate-hash] 文档所述地确定。

@see-also-caveats[]

@history[#:added "7.4.0.3"]}

@defproc[(hash-ref! [ht hash?] [key any/c] [to-set failure-result/c])
         any]{

返回 @racket[ht] 中 @racket[key] 的值。如果没有找到 @racket[key] 的值，则 @racket[to-set] 像 @racket[hash-ref] 中那样确定结果（即要么是计算值的 thunk，要么是普通值），并将此结果存储在 @racket[ht] 中以备 @racket[key]。（注意，如果 @racket[to-set] 是 thunk，它不在尾位置被调用。）

@see-also-caveats[]}


@defproc[(hash-has-key? [ht hash?] [key any/c])
         boolean?]{

如果 @racket[ht] 包含给定 @racket[key] 的值则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(hash-update! [ht (and/c hash? (not/c immutable?))]
                       [key any/c]
                       [updater (any/c . -> . any/c)]
                       [failure-result failure-result/c
                        (lambda ()
                          (raise (make-exn:fail:contract ....)))])
         void?]{

 通过将 @racket[updater] 应用于值来更新 @racket[ht] 中 @racket[key] 映射的值。@racket[updater] 返回的值成为 @racket[key] 的新映射，覆盖 @racket[ht] 中的原始值。

 @(examples
   #:eval the-eval
   (eval:no-prompt
    (define h (make-hash))
    (hash-set! h 'a 5))

   (hash-update! h 'a add1)
   h)

 可选的 @racket[failure-result] 参数在 @racket[key] 尚不存在映射时使用，方式与 @racket[hash-ref] 中相同。

 @(examples
   #:eval the-eval
   (eval:no-prompt
    (define h (make-hash)))
 
   (eval:error (hash-update! h 'b add1))
   (hash-update! h 'b add1 0)
   h)

 @see-also-caveats[]}


@defproc[(hash-update [ht (and/c hash? immutable?)]
                      [key any/c]
                      [updater (any/c . -> . any/c)]
                      [failure-result failure-result/c
                       (lambda ()
                         (raise (make-exn:fail:contract ....)))])
         (and/c hash? immutable?)]{

 通过将 @racket[updater] 应用于值并返回一个新的 hash table 来函数式地更新 @racket[ht] 中 @racket[key] 映射的值。@racket[updater] 返回的值成为返回的 hash table 中 @racket[key] 的新映射。

 @(examples
   #:eval the-eval
   (eval:no-prompt
    (define h (hash 'a 5)))
   
   (hash-update h 'a add1))

 可选的 @racket[failure-result] 参数在 @racket[key] 尚不存在映射时使用，方式与 @racket[hash-ref] 中相同。

 @(examples
   #:eval the-eval
   (eval:no-prompt
    (define h (hash)))
   
   (eval:error (hash-update h 'b add1))
   (hash-update h 'b add1 0))

 @see-also-mutable-key-caveat[]}


@defproc[(hash-remove! [ht (and/c hash? (not/c immutable?))]
                       [key any/c])
         void?]{

移除 @racket[ht] 中 @racket[key] 的任何现有映射。

@see-also-caveats[]}


@defproc[(hash-remove [ht (and/c hash? immutable?)]
                      [key any/c])
         (and/c hash? immutable?)]{

函数式地移除 @racket[ht] 中 @racket[key] 的任何现有映射，如果 @racket[key] 不在 @racket[ht] 中则返回 @racket[ht]（即与 @racket[ht] @racket[eq?] 的结果）。

@see-also-mutable-key-caveat[]}


@defproc[(hash-clear! [ht (and/c hash? (not/c immutable?))])
         void?]{

移除 @racket[ht] 中的所有映射。

如果 @racket[ht] 不是 @tech{impersonator}，则所有映射在常数时间内移除。如果 @racket[ht] 是 @tech{impersonator}，则每个键使用 @racket[hash-remove!] 逐个移除。

@see-also-caveats[]}


@defproc[(hash-clear [ht (and/c hash? immutable?)])
         (and/c hash? immutable?)]{

函数式地移除 @racket[ht] 中的所有映射。

如果 @racket[ht] 不是 @tech{chaperone}，则清除等价于创建一个新的 @tech{hash table}，操作在常数时间内执行。如果 @racket[ht] 是 @tech{chaperone}，则每个键使用 @racket[hash-remove] 逐个移除。}


@defproc[(hash-copy-clear
          [ht hash?]
          [#:kind kind (or/c #f 'immutable 'mutable 'weak 'ephemeron) #f])
         hash?]{

生成一个与 @racket[ht] 具有相同键比较过程的空 @tech{hash table}，使用给定的 @racket[kind] 或与给定 @racket[ht] 相同的种类。

如果未提供 @racket[kind] 或为 @racket[#f]，则生成与给定 @racket[ht] 相同种类和可变性的 hash table。如果 @racket[kind] 是 @racket['immutable]、@racket['mutable]、@racket['weak] 或 @racket['ephemeron]，则分别生成不可变的、强保留键的可变、弱保留键的可变或 ephemeron 保留键的可变表。

@history[#:changed "8.5.0.2" @elem{Added the @racket[kind] argument.}]}



@defproc[(hash-map [ht hash?]
                   [proc (any/c any/c . -> . any/c)]
                   [try-order? any/c #f])
         (listof any/c)]{

以未指定的顺序将过程 @racket[proc] 应用于 @racket[ht] 中的每个元素，将结果累积到一个 list 中。过程 @racket[proc] 每次调用时传入一个键及其值，过程的各个结果按顺序出现在结果 list 中。

如果在 @racket[hash-map] 或 @racket[hash-for-each] 遍历进行过程中使用新键扩展 hash table（通过 @racket[proc] 或由另一个线程），则在遍历中可能会丢弃或重复任意键值对。键映射可以被删除或重新映射（由任何线程）而不会产生不利影响；如果键已经被看到，则更改不影响遍历，否则遍历跳过已删除的键或使用重新映射键的新值。

@see-also-concurrency-caveat[]

如果 @racket[try-order?] 为 true，则在某些情况下传递给 @racket[proc] 的键和值的顺序会被规范化——包括当每个键是以下之一并遵循以下顺序时（前面的条目先于后面的条目）：

@itemlist[
 @item{@tech{booleans} sorted @racket[#f] before @racket[#t];}
 @item{@tech{characters} sorted by @racket[char<?];}
 @item{@tech{real numbers} sorted by @racket[<];}
 @item{@tech{symbols} sorted with @tech{uninterned} symbols before
       @tech{unreadable symbols} before @tech{interned} symbols,
       然后按 @racket[symbol<?] 排序；}
 @item{@tech{keywords} sorted by @racket[keyword<?];}
 @item{@tech{strings} sorted by @racket[string<?];}
 @item{@tech{byte strings} sorted by @racket[bytes<?];}
 @item{@racket[null];}
 @item{@|void-const|; and}
 @item{@racket[eof].}
]

@history[#:changed "6.3" @elem{Added the @racket[try-order?] argument.}
         #:changed "7.1.0.7" @elem{Added guarantees for @racket[try-order?].}]}

@examples[
#:eval the-eval
(hash-map (make-hash '([0 . 1] [1 . 2] [2 . 3])) (λ (k v) k))
(hash-map (make-hash '([0 . 1] [1 . 2] [2 . 3])) (λ (k v) v))
]

@defproc[(hash-map/copy
          [ht hash?]
          [proc (any/c any/c . -> . (values any/c any/c))]
          [#:kind kind (or/c #f 'immutable 'mutable 'weak 'ephemeron) #f])
         hash?]{

以未指定的顺序将过程 @racket[proc] 应用于 @racket[ht] 中的每个元素，将结果累积到一个与 @racket[ht] 具有相同键比较过程的新 hash 中，使用给定的 @racket[kind] 或与给定 @racket[ht] 相同的种类。

如果未提供 @racket[kind] 或为 @racket[#f]，则生成与给定 @racket[ht] 相同种类和可变性的 hash table。如果 @racket[kind] 是 @racket['immutable]、@racket['mutable]、@racket['weak] 或 @racket['ephemeron]，则分别生成不可变的、强保留键的可变、弱保留键的可变或 ephemeron 保留键的可变表。

@examples[
#:eval the-eval
(hash-map/copy #hash((a . "apple") (b . "banana"))
               (lambda (k v) (values k (string-upcase v))))
(define frozen-capital
  (hash-map/copy (make-hash '((a . "apple") (b . "banana")))
                 (lambda (k v) (values k (string-upcase v)))
                 #:kind 'immutable))
frozen-capital
(immutable? frozen-capital)
]

@history[#:added "8.5.0.2"]}

@defproc[(hash-keys [ht hash?] [try-order? any/c #f])
         (listof any/c)]{
以未指定的顺序返回 @racket[ht] 的键的 list。

如果 @racket[try-order?] 为 true，则在某些情况下键的顺序会被规范化。关于 @racket[try-order?] 以及在 @racket[hash-keys] 期间修改 @racket[ht] 的信息，请参见 @racket[hash-map]。@see-also-concurrency-caveat[]

@history[#:changed "8.3.0.11" @elem{Added the @racket[_try-order?] argument.}]}

@defproc[(hash-values [ht hash?] [try-order? any/c #f])
         (listof any/c)]{
以未指定的顺序返回 @racket[ht] 的值的 list。

如果 @racket[try-order?] 为 true，则在某些情况下值的顺序会根据关联键的顺序被规范化。关于 @racket[try-order?] 以及在 @racket[hash-values] 期间修改 @racket[ht] 的信息，请参见 @racket[hash-map]。@see-also-concurrency-caveat[]

@history[#:changed "8.3.0.11" @elem{Added the @racket[_try-order?] argument.}]}

@defproc[(hash->list [ht hash?] [try-order? any/c #f])
         (listof (cons/c any/c any/c))]{
以未指定的顺序返回 @racket[ht] 的键值对的 list。

如果 @racket[try-order?] 为 true，则在某些情况下键和值的顺序会被规范化。关于 @racket[try-order?] 以及在 @racket[hash->list] 期间修改 @racket[ht] 的信息，请参见 @racket[hash-map]。@see-also-concurrency-caveat[]

@history[#:changed "8.3.0.11" @elem{Added the @racket[_try-order?] argument.}]}

@defproc[(hash-keys-subset? [ht1 hash?] [ht2 hash?])
         boolean?]{
如果 @racket[ht1] 的键是 @racket[ht2] 的键的子集或相同，则返回 @racket[#t]。两个 hash table 必须使用相同的键比较函数（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]），否则 @exnraise[exn:fail:contract]。

在不可变 hash table 上使用 @racket[hash-keys-subset?] 比遍历 @racket[ht1] 的键以确保每个都在 @racket[ht2] 中要快得多。

@history[#:added "6.5.0.8"]}

@defproc[(hash-for-each [ht hash?]
                        [proc (any/c any/c . -> . any)]
                        [try-order? any/c #f])
         void?]{

以未指定的顺序将 @racket[proc] 应用于 @racket[ht] 中的每个元素（用于 @racket[proc] 的副作用）。过程 @racket[proc] 每次调用时传入一个键及其值。

关于 @racket[try-order?] 以及在 @racket[proc] 中修改 @racket[ht] 的信息，请参见 @racket[hash-map]。@see-also-concurrency-caveat[]

@history[#:changed "6.3" @elem{Added the @racket[try-order?] argument.}
         #:changed "7.1.0.7" @elem{Added guarantees for @racket[try-order?].}]}


@defproc[(hash-count [ht hash?])
         exact-nonnegative-integer?]{

返回 @racket[ht] 映射的键的数量。

对于 Racket 的 @tech{CS} 实现，结果始终以常数时间和原子方式计算。对于 Racket 的 @tech{BC} 实现，只有当 @racket[ht] 不弱保留键或不像 @tech{ephemeron} 那样保留键时，结果才以常数时间和原子方式计算；否则需要遍历来计数键。}


@defproc[(hash-empty? [ht hash?]) boolean?]{

等价于 @racket[(zero? (hash-count ht))]。}


@defproc[(hash-iterate-first [ht hash?])
         (or/c #f exact-nonnegative-integer?)]{

如果 @racket[ht] 不包含元素则返回 @racket[#f]，否则返回一个整数，该整数是 hash table 中第一个元素的索引；``first 指的是表元素的一个未指定排序，索引值不一定是连续的整数。

对于可变的 @racket[ht]，该索引只保证在没有任何项目添加到 @racket[ht] 或从中移除时引用第一个项目。更一般地，索引只有当它来自 @racket[hash-iterate-first] 或 @racket[hash-iterate-next]，且 hash table 未被修改时，才保证是给定 hash table 的 @deftech{valid hash index}。对于具有弱保留键或像 @tech{ephemerons} 一样保留键的 hash table，当垃圾收集器（参见 @secref["gc-model"]）发现键不可达时，hash table 可能被隐式修改。}


@defproc[(hash-iterate-next [ht hash?]
                            [pos exact-nonnegative-integer?])
         (or/c #f exact-nonnegative-integer?)]{

返回一个整数，该整数是 @racket[ht] 中 @racket[pos] 索引的元素后面的元素的索引（不一定是 @racket[pos] 加一），或者如果 @racket[pos] 引用 @racket[ht] 中的最后一个元素则返回 @racket[#f]。

如果 @racket[pos] 不是 @racket[ht] 的 @tech{valid hash index}，则结果可能是 @racket[#f]，或者可能是下一个仍然有效的较晚索引。如果 hash table 仅通过删除键而被修改，则保证后一种结果。

@history[#:changed "7.0.0.10" @elem{Handle an invalid index by returning @scheme[#f]
                                    instead of raising @racket[exn:fail:contract].}]}


@deftogether[(
@defproc[(hash-iterate-key [ht hash?]
                           [pos exact-nonnegative-integer?])
         any/c]
@defproc[#:link-target? #f
         (hash-iterate-key [ht hash?]
                           [pos exact-nonnegative-integer?]
                           [bad-index-v any/c])
         any/c]
)]{
         
返回 @racket[ht] 中索引为 @racket[pos] 的元素的键。

如果 @racket[pos] 不是 @racket[ht] 的 @tech{valid hash index}，若提供了 @racket[bad-index-v] 则结果为该值，否则 @exnraise[exn:fail:contract]。

@history[#:changed "7.0.0.10" @elem{Added the optional @racket[bad-index-v] argument.}]}


@deftogether[(
@defproc[(hash-iterate-value [ht hash?]
                             [pos exact-nonnegative-integer?])
         any/c]
@defproc[#:link-target? #f
         (hash-iterate-value [ht hash?]
                             [pos exact-nonnegative-integer?]
                             [bad-index-v any/c])
         any/c]
)]{

返回 @racket[ht] 中索引为 @racket[pos] 的元素的值。

如果 @racket[pos] 不是 @racket[ht] 的 @tech{valid hash index}，若提供了 @racket[bad-index-v] 则结果为该值，否则 @exnraise[exn:fail:contract]。

@history[#:changed "7.0.0.10" @elem{Added the optional @racket[bad-index-v] argument.}]}



@deftogether[(
@defproc[(hash-iterate-pair [ht hash?]
                            [pos exact-nonnegative-integer?])
         (cons/c any/c any/c)]
@defproc[#:link-target? #f
         (hash-iterate-pair [ht hash?]
                            [pos exact-nonnegative-integer?]
                            [bad-index-v any/c])
         (cons/c any/c any/c)]
)]{

返回一个 pair，其中包含 @racket[ht] 中索引为 @racket[pos] 的元素的键和值。

如果 @racket[pos] 不是 @racket[ht] 的 @tech{valid hash index}，若提供了 @racket[bad-index-v] 则结果为 @racket[(cons bad-index-v bad-index-v)]，否则 @exnraise[exn:fail:contract]。

@history[#:added "6.4.0.5"
         #:changed "7.0.0.10" @elem{Added the optional @racket[bad-index-v] argument.}]}


@deftogether[(
@defproc[(hash-iterate-key+value [ht hash?]
                                 [pos exact-nonnegative-integer?])
         (values any/c any/c)]
@defproc[#:link-target? #f
         (hash-iterate-key+value [ht hash?]
                                 [pos exact-nonnegative-integer?]
                                 [bad-index-v any/c])
         (values any/c any/c)]
)]{

返回 @racket[ht] 中索引为 @racket[pos] 的元素的键和值。

如果 @racket[pos] 不是 @racket[ht] 的 @tech{valid hash index}，若提供了 @racket[bad-index-v] 则结果为 @racket[(values bad-index-v bad-index-v)]，否则 @exnraise[exn:fail:contract]。

@history[#:added "6.4.0.5"
         #:changed "7.0.0.10" @elem{Added the optional @racket[bad-index-v] argument.}]}


@defproc[(hash-copy [ht hash?])
         (and/c hash? (not/c immutable?))]{

返回一个与 @racket[ht] 具有相同映射、相同键比较模式和相同键保留强度的可变 hash table。}

@;------------------------------------------------------------------------
@section{Additional Hash Table Functions}

@note-lib-only[racket/hash]

@(require (for-label racket/hash))

@(define the-eval (make-base-eval))
@(the-eval '(require racket/hash))

@defproc[(hash-union [ht0 (and/c hash? immutable?)]
                     [ht hash?] ...
                     [#:combine combine
                                (-> any/c any/c any/c)
                                (lambda _ (error 'hash-union ....))]
                     [#:combine/key combine/key
                                    (-> any/c any/c any/c any/c)
                                    (lambda (k a b) (combine a b))])
         (and/c hash? immutable?)]{

通过函数式更新计算 @racket[ht0] 与每个 hash table @racket[ht] 的并集，依次将每个 @racket[ht] 的每个元素添加到 @racket[ht0]。对于每个键 @racket[_k] 和值 @racket[_v]，如果从 @racket[_k] 到某个值 @racket[_v0] 的映射已经存在，则将其替换为从 @racket[_k] 到 @racket[(combine/key _k _v0 _v)] 的映射。

@examples[
#:eval the-eval
(hash-union (make-immutable-hash '([1 . one]))
            (make-immutable-hash '([2 . two]))
            (make-immutable-hash '([3 . three])))
(hash-union (make-immutable-hash '([1 . (one uno)] [2 . (two dos)]))
            (make-immutable-hash '([1 . (eins un)] [2 . (zwei deux)]))
            #:combine/key (lambda (k v1 v2) (append v1 v2)))
]

}

@defproc[(hash-union! [ht0 (and/c hash? (not/c immutable?))]
                      [ht hash?] ...
                      [#:combine combine
                                 (-> any/c any/c any/c)
                                 (lambda _ (error 'hash-union ....))]
                      [#:combine/key combine/key
                                     (-> any/c any/c any/c any/c)
                                     (lambda (k a b) (combine a b))])
         void?]{

通过可变更新计算 @racket[ht0] 与每个 hash table @racket[ht] 的并集，依次将每个 @racket[ht] 的每个元素添加到 @racket[ht0]。对于每个键 @racket[_k] 和值 @racket[_v]，如果从 @racket[_k] 到某个值 @racket[_v0] 的映射已经存在，则将其替换为从 @racket[_k] 到 @racket[(combine/key _k _v0 _v)] 的映射。

@examples[
#:eval the-eval
(define h (make-hash))
h
(hash-union! h (make-immutable-hash '([1 . (one uno)] [2 . (two dos)])))
h
(hash-union! h
             (make-immutable-hash '([1 . (eins un)] [2 . (zwei deux)]))
             #:combine/key (lambda (k v1 v2) (append v1 v2)))
h
]

}

@defproc[(hash-intersect [ht0 (and/c hash? immutable?)]
			             [ht hash?] ...
                         [#:combine combine
                                    (-> any/c any/c any/c)
                                    (lambda _ (error 'hash-intersect ...))]
                         [#:combine/key combine/key
                                     	(-> any/c any/c any/c any/c)
                                     	(lambda (k a b) (combine a b))])
	 (and/c hash? immutable?)]{

构造一个 hash table，它是 @racket[ht0] 与每个 hash table @racket[ht] 的交集。在结果 hash table 中，键 @racket[_k] 被映射到 @racket[_k] 在每个 hash table 中映射的值的组合。最终值通过逐步组合每个 hash table 中出现的值来计算，应用 @racket[(combine/key _k _v _vi)]，其中 @racket[_vi] 是 @racket[_k] 在第 @math{i} 个 hash table @racket[ht] 中映射的值，@racket[_v] 是前几步值的累积。第一个参数的比较谓词（@racket[eq?]、@racket[eqv?]、@racket[equal-always?]、@racket[equal?]）决定结果的比较谓词。

@examples[
#:eval the-eval
(hash-intersect (make-immutable-hash '((a . 1) (b . 2) (c . 3)))
		(make-immutable-hash '((a . 4) (b . 5)))
		#:combine +)
(hash-intersect (make-immutable-hash '((a . 1) (b . 2) (c . 3)))
		(make-immutable-hash '((a . 4) (b . 5)))
		#:combine/key
		(lambda (k v1 v2) (if (eq? k 'a) (+ v1 v2) (- v1 v2))))
]


@history[#:added "7.9.0.1"]}

@defproc[(hash-filter [ht hash?] [pred (-> any/c any/c boolean?)])
         hash?]{

基于同时应用于键和值的谓词 @racket[pred] 过滤 @racket[hash?] @racket[ht]。此函数构造一个新的 hash table，仅包含输入 @racket[ht] 中谓词 @racket[pred] 同时应用于 @racket[ht] 的键和值时返回 true 的那些键值对。输出 hash table 保留输入 hash table @racket[ht] 的可变性和键比较谓词（例如 @racket[eqv?]、@racket[equal-always?]、@racket[equal?]），确保原始 hash 的结构和操作属性在输出中被保留。

@examples[
  #:eval the-eval
  ;; Filtering key-value pairs where the key is less than 3 and value is even
  (hash-filter (for/hash ([num '(1 2 3 4 5)]) (values num (* num 2)))
               (λ (k v) (and (< k 3) (even? v))))

  ;; Filtering key-value pairs from an empty hash table
  (hash-filter (make-hash) (λ (k v) (< k 3)))

  ;; Filtering with eq? hash table based on specific key-value conditions
  (hash-filter (make-hasheq '([#f . "false"] [#t . "true"]))
               (λ (k v) (and (eq? k #t) (string=? v "true"))))

  ;; Filtering key-value pairs where the key is a list and the value is a symbol
  (hash-filter (hash (list 1 2) 'pair (vector 3 4) 'vector)
               (λ (k v) (and (list? k) (symbol? v))))

  ;; Filtering key-value pairs of mixed types based on custom logic
  (hash-filter (hash "one" 1 2 "two" "three" 3)
               (λ (k v) (and (not (number? k)) (number? v) (> v 1))))
]

@history[#:added "8.13.0.4"]
}

@defproc[(hash-filter-keys [ht hash?] [pred procedure?])
         hash?]{

基于应用于键的谓词 @racket[pred] 过滤 @racket[hash?] @racket[ht]。此函数构造一个新的 hash table，仅包含输入 @racket[ht] 中谓词 @racket[pred] 应用于键时返回 true 的那些键值对。与 @racket[hash-filter-values] 类似，输出 hash table 保持输入 hash table 的可变性和键比较器，确保原始 hash 的结构和操作属性被保留。

@examples[
  #:eval the-eval
  ;; Filtering keys less than 3 from a hash table
  (hash-filter-keys (for/hash ([num '(1 2 3 4 5)]) (values num 0)) (λ (k) (< k 3)))

  ;; Filtering keys from an empty hash table
  (hash-filter-keys (make-hash) (λ (k) (< k 3)))

  ;; Filtering with eq? hash table
  (hash-filter-keys (make-hasheq '([#f . "false"] [#t . "true"])) (λ (k) (eq? k #t)))

  ;; Filtering lists as keys
  (hash-filter-keys (hash (list 1 2) 'pair (vector 3 4) 'vector) list?)

  ;; Filtering keys of mixed types: numbers and strings
  (hash-filter-keys (hash "one" 1 2 "two" "three" 3) (lambda (k) (number? k)))

  ;; Filtering keys that are symbols
  (hash-filter-keys (hash 'apple "fruit" 'carrot "vegetable" "banana" "fruit")
                    (lambda (k) (symbol? k)))
]

@history[#:added "8.12.0.9"]
}


@defproc[(hash-filter-values [ht hash?] [pred procedure?])
         hash?]{

基于应用于值的谓词 @racket[pred] 过滤 @racket[hash?] @racket[ht]。此函数返回一个新的 hash table，仅包含谓词 @racket[pred] 应用于 @racket[ht] 的值时返回 true 的那些键值对。结果 hash table 保留输入 hash table @racket[ht] 的可变性和键比较谓词（例如 @racket[eq?]、@racket[eqv?]、@racket[equal-always?]、@racket[equal?]）。

@examples[
   #:eval the-eval
   ;; Filtering values less than 3
   (hash-filter-values (for/hash ([num '(1 2 3 4 5)]) (values num num)) (λ (v) (< v 3)))

   ;; Filtering values from an empty hash table
   (hash-filter-values (make-hash) (λ (v) (< v 3)))

   ;; Filtering with eqv? hash table
   (hash-filter-values (make-hasheqv '([1 . "one"] [2 . "two"])) (λ (v) (eqv? v "two")))

   ;; Filtering values of mixed types: strings and numbers
   (hash-filter-values (hash 'one "1" 'two 2 'three "3") (lambda (v) (string? v)))

   ;; Filtering values to include only vectors
   (hash-filter-values (hash 'list (list 1 2 3) 'vector #(4 5 6) 'string "hello")
                       (lambda (v) (vector? v)))

   ;; Filtering based on complex values (hash tables and lists)
   (hash-filter-values (hash 'nested-hash (hash 'a 1 'b 2) 'nested-list (list 'x 'y 'z))
                       (lambda (v) (hash? v)))
 ]

@history[#:added "8.12.0.9"]
}

@(close-eval the-eval)
