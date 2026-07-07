#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "hashtables"]{Hash Tables}

@(define (see-also-caveats)
   @t{另请参见上面的 @concurrency-caveat[] 和 @mutable-key-caveat[]。})
@(define (see-also-concurrency-caveat)
   @t{另请参见上面的 @concurrency-caveat[]。})
@(define (see-also-mutable-key-caveat)
   @t{另请参见上面的 @mutable-key-caveat[]。})

@guideintro["hash-tables"]{hash tables}

@deftech{hash table}（或简称为 @deftech{hash}）将每个键映射到一个值。对于给定的 hash table，键通过 @racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?] 进行等价比较，键的保留方式可以是强引用、弱引用（参见 @secref["weakbox"]）或类似 @tech{ephemerons} 的方式。
hash table 也可以是可变的或不可变的。
不可变 hash table 支持等效的常数时间访问和更新，就像可变 hash table 一样；不可变操作的常数因子通常更大，但不可变 hash table 的函数式特性在某些算法中可以带来收益。使用 @racket[immutable?] 来检查 hash table 是否不可变。

@margin-note{不可变 hash table 实际上提供 @math{O(log N)} 的访问和更新。由于 @math{N} 受地址空间限制，因此 @math{log N} 被限制在小于 30 或 62（取决于平台），@math{log N} 可以合理地被视为常数。}

对于基于 @racket[equal?] 的哈希，内建的 hash 函数作用于
@tech{strings}、@tech{pairs}、@tech{lists}、@tech{vectors}、
@tech{prefab} 或透明的 @tech{structures}、@|etc| 等时，其耗时与值的大小成正比。复合数据结构（如 list 或 vector）的哈希码取决于对容器中每个元素进行哈希，但这种递归哈希的深度是有限的（以避免循环数据的潜在问题）。对于非 @tech{list} 的 @tech{pair}，@racket[car] 和 @racket[cdr] 的哈希都被视为更深一层的哈希，但 @tech{list} 的 @racket[cdr] 被视为与该 list 具有相同的哈希深度。

hash table 可以作为双值 @tech{sequence} 使用（参见 @secref["sequences"]）。hash table 的键和值作为序列的元素（即每个元素是一个键及其关联的值）。如果在迭代期间向 hash table 添加或移除映射，则迭代步骤可能会因 @racket[exn:fail:contract] 而失败，或者迭代可能会跳过或重复键和值。另请参见 @racket[in-hash]、@racket[in-hash-keys]、@racket[in-hash-values] 和 @racket[in-hash-pairs]。

两个 hash table 除非具有相同的可变性、使用相同的键比较过程（@racket[equal?]、@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]）、且都以强引用、弱引用或类似 @tech{ephemerons} 的方式持有键，否则它们不可能 @racket[equal?]。
空的不可变 hash table 在 @racket[equal?] 时也是 @racket[eq?] 的。

@history[#:changed "7.2.0.9" @elem{使空的不可变 hash table
                                   在 @racket[equal?] 时也是
                                   @racket[eq?] 的。}]

@elemtag['(caveat "concurrency")]{@bold{关于并发修改的注意事项：}} 可变 hash table 可以被多个线程通过 @racket[hash-ref]、@racket[hash-set!] 和 @racket[hash-remove!] 并发操作，并且这些操作在需要时受到表特定信号量的保护。然而，有一些注意事项：

 @itemize[

  @item{如果线程在对使用 @racket[equal?]、@racket[equal-always?] 或 @racket[eqv?] 键比较的 hash table 执行 @racket[hash-ref]、
  @racket[hash-ref-key]、@racket[hash-set!]、@racket[hash-remove!]、
  @racket[hash-ref!]、@racket[hash-update!] 或 @racket[hash-clear!] 时被终止，则当前和将来对该 hash table 的所有操作可能会无限期阻塞。}

  @item{@racket[hash-map]、@racket[hash-for-each] 和 @racket[hash-clear!] 过程不会使用表的信号量来保护整个遍历过程（如果需要遍历的话，如 @racket[hash-clear!] 的情况）。
  一个线程对 hash table 的更改可能影响另一个线程在遍历同一 hash table 过程中看到的键和值。}

 @item{@racket[hash-update!] 和 @racket[hash-ref!] 函数
 分别对 @racket[hash-ref] 和 @racket[hash-set!] 部分独立使用表的信号量，这意味着整个更新操作不是"原子的"。}

 @item{将可变 hash table 自身作为键添加到自身是有问题的，因为键正在被修改（参见下面的注意事项），而且这也是一种对 hash table 的并发使用：计算 hash table 的哈希码可能需要等待表的信号量，但信号量已被修改 hash table 的操作持有，因此 hash table 的添加操作可能会无限期阻塞。}

 ]

@elemtag['(caveat "mutable-keys")]{@bold{关于可变键的注意事项：}} 如果基于 @racket[equal?] 的 hash table 中的键被修改（例如，使用 @racket[string-set!] 修改键字符串），则 hash table 的插入和查找操作将变得不可预测。

字面量或打印的 hash table 以 @litchar{#hash}、
@litchar{#hashalw}、@litchar{#hasheqv} 或
@litchar{#hasheq} 开头。@see-read-print["hashtable"]{hash tables}

@defproc[(hash? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{hash table} 则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(hash-equal? [hash hash?]) boolean?]{

如果 @racket[hash] 使用 @racket[equal?] 比较键则返回 @racket[#t]，
如果使用 @racket[eq?]、@racket[eqv?] 或
@racket[equal-always?] 比较则返回 @racket[#f]。}

@defproc[(hash-equal-always? [hash hash?]) boolean?]{

如果 @racket[hash] 使用
@racket[equal-always?] 比较键则返回 @racket[#t]，如果使用 @racket[eq?]、
@racket[eqv?] 或 @racket[equal?] 比较则返回 @racket[#f]。

@history[#:added "8.5.0.3"]}

@defproc[(hash-eqv? [hash hash?]) boolean?]{

如果 @racket[hash] 使用 @racket[eqv?] 比较键则返回 @racket[#t]，
如果使用 @racket[equal?]、
@racket[equal-always?] 或 @racket[eq?] 比较则返回 @racket[#f]。}

@defproc[(hash-eq? [hash hash?]) boolean?]{

如果 @racket[hash] 使用 @racket[eq?] 比较键则返回 @racket[#t]，
如果使用 @racket[equal?]、
@racket[equal-always?] 或 @racket[eqv?] 比较则返回 @racket[#f]。}


@defproc[(hash-strong? [hash hash?]) boolean?]{

如果 @racket[hash] 以强引用方式保留键则返回 @racket[#t]，
如果以弱引用或类似 @tech{ephemerons} 的方式保留键则返回 @racket[#f]。

@history[#:added "8.0.0.10"]}


@defproc[(hash-weak? [hash hash?]) boolean?]{

如果 @racket[hash] 以弱引用方式保留键则返回 @racket[#t]，
如果以强引用或类似 @tech{ephemerons} 的方式保留键则返回 @racket[#f]。}


@defproc[(hash-ephemeron? [hash hash?]) boolean?]{

如果 @racket[hash] 以类似 @tech{ephemerons} 的方式保留键则返回 @racket[#t]，
如果以强引用或仅仅弱引用方式保留键则返回 @racket[#f]。

@history[#:added "8.0.0.10"]}


@deftogether[(
@defproc[(hash [key any/c] [val any/c] ... ...) (and/c hash? hash-equal? immutable? hash-strong?)]
@defproc[(hashalw [key any/c] [val any/c] ... ...)
         (and/c hash? hash-equal-always? immutable? hash-strong?)]
@defproc[(hasheq [key any/c] [val any/c] ... ...) (and/c hash? hash-eq? immutable? hash-strong?)]
@defproc[(hasheqv [key any/c] [val any/c] ... ...) (and/c hash? hash-eqv? immutable? hash-strong?)]
)]{

创建一个不可变 hash table，其中每个给定的 @racket[key] 映射到
后面的 @racket[val]；每个 @racket[key] 必须有一个 @racket[val]，
因此 @racket[hash] 的参数总数必须是偶数。

@racket[hash] 过程创建一个键使用 @racket[equal?] 比较的表，
@racket[hashalw] 创建一个键使用
@racket[equal-always?] 比较的表，@racket[hasheq] 过程创建一个键使用
@racket[eq?] 比较的表，@racket[hasheqv] 过程
创建一个键使用 @racket[eqv?] 比较的表。

键到值的映射按参数列表中的出现顺序添加到表中，因此如果 @racket[key] 相等，后面的映射可以覆盖前面的映射。

@history[#:changed "8.5.0.3" @elem{添加了 @racket[hashalw]。}]}

@deftogether[(
@defproc[(make-hash [assocs (listof pair?) null]) (and/c hash? hash-equal? (not/c immutable?) hash-strong?)]
@defproc[(make-hashalw [assocs (listof pair?) null])
         (and/c hash? hash-equal-always? (not/c immutable?) hash-strong?)]
@defproc[(make-hasheqv [assocs (listof pair?) null]) (and/c hash? hash-eqv? (not/c immutable?) hash-strong?)]
@defproc[(make-hasheq [assocs (listof pair?) null]) (and/c hash? hash-eq? (not/c immutable?) hash-strong?)]
)]{

创建一个以强引用方式持有键的可变 hash table。

@racket[make-hash] 过程创建一个键使用
@racket[equal?] 比较的表，@racket[make-hasheq] 过程创建一个键使用
@racket[eq?] 比较的表，
@racket[make-hasheqv] 过程创建一个键使用
@racket[eqv?] 比较的表，@racket[make-hashalw] 创建一个键使用
@racket[equal-always?] 比较的表。

该表使用 @racket[assocs] 的内容进行初始化。在 @racket[assocs] 的每个元素中，@racket[car] 是键，@racket[cdr] 是对应的值。映射按 @racket[assocs] 中的出现顺序添加到表中，因此后面的映射可以覆盖前面的映射。

另请参见 @racket[make-custom-hash]。

@history[#:changed "8.5.0.3" @elem{添加了 @racket[make-hashalw]。}]}

@deftogether[(
@defproc[(make-weak-hash [assocs (listof pair?) null]) (and/c hash? hash-equal? (not/c immutable?) hash-weak?)]
@defproc[(make-weak-hashalw [assocs (listof pair?) null])
         (and/c hash? hash-equal-always? (not/c immutable?) hash-weak?)]
@defproc[(make-weak-hasheqv [assocs (listof pair?) null]) (and/c hash? hash-eqv? (not/c immutable?) hash-weak?)]
@defproc[(make-weak-hasheq [assocs (listof pair?) null]) (and/c hash? hash-eq? (not/c immutable?) hash-weak?)]
)]{

类似于 @racket[make-hash]、@racket[make-hasheq]、
@racket[make-hasheqv] 和 @racket[make-hashalw]，但创建一个
以弱引用方式持有键的可变 hash table。

请注意，弱 hash table 中的值是正常保留的。如果表中的某个值
反向引用了它的键，则该表将保留该值以及该键；即使该键在其他地方
变得不可达，该映射也永远不会从表中移除。要避免这个问题，
请使用由 @racket[make-ephemeron-hash]、@racket[make-ephemeron-hashalw]、
@racket[make-ephemeron-hasheqv] 或 @racket[make-ephemeron-hasheq] 创建的
ephemeron hash table。对于不引用键的值，使用 ephemeron hash table 而非
弱 hash table 只有适度的额外开销，但在有疑问时优先选择 ephemeron hash table。

@history[#:changed "8.5.0.3" @elem{添加了 @racket[make-weak-hashalw]。}]}


@deftogether[(
@defproc[(make-ephemeron-hash [assocs (listof pair?) null]) (and/c hash? hash-equal? (not/c immutable?) hash-ephemeron?)]
@defproc[(make-ephemeron-hashalw [assocs (listof pair?) null])
         (and/c hash? hash-equal-always? (not/c immutable?) hash-ephemeron?)]
@defproc[(make-ephemeron-hasheqv [assocs (listof pair?) null]) (and/c hash? hash-eqv? (not/c immutable?) hash-ephemeron?)]
@defproc[(make-ephemeron-hasheq [assocs (listof pair?) null]) (and/c hash? hash-eq? (not/c immutable?) hash-ephemeron?)]
)]{

类似于 @racket[make-hash]、@racket[make-hasheq]、
@racket[make-hasheqv] 和 @racket[make-hashalw]，
但创建一个以与 @tech{ephemeron} 相同的方式持有键值组合的可变 hash table。

使用 ephemeron hash table 类似于使用弱 hash table 并将每个键映射到
一个配对键和值的 @tech{ephemeron}。ephemeron hash table 的一个优点是
不需要从 @racket[hash-ref] 等函数的结果中通过 @racket[ephemeron-value] 来
提取值。ephemeron hash table 的表示也可能比具有显式 @tech{ephemeron} 值的
弱 hash table 更紧凑。

@history[#:added "8.0.0.10"
         #:changed "8.5.0.3" @elem{添加了 @racket[make-ephemeron-hashalw]。}]}

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

类似于 @racket[hash]、@racket[hashalw]、@racket[hasheq] 和
@racket[hasheqv]，但接受
关联列表形式的键值映射，就像
@racket[make-hash]、@racket[make-hashalw]、@racket[make-hasheq] 和
@racket[make-hasheqv] 一样。

@history[#:changed "8.5.0.3" @elem{添加了 @racket[make-immutable-hashalw]。}]}


@defproc[(hash-set! [hash (and/c hash? (not/c immutable?))]
                    [key any/c]
                    [v any/c]) void?]{

在 @racket[hash] 中将 @racket[key] 映射到 @racket[v]，覆盖
@racket[key] 的任何现有映射。

@see-also-caveats[]}

@defproc[(hash-set*! [hash (and/c hash? (not/c immutable?))]
                     [key any/c]
                     [v any/c]
                     ...
                     ...) void?]{

在 @racket[hash] 中将每个 @racket[key] 映射到每个 @racket[v]，覆盖
每个 @racket[key] 的任何现有映射。映射从左到右添加，因此
后面的映射覆盖前面的映射。

@see-also-caveats[]}


@defproc[(hash-set [hash (and/c hash? immutable?)]
                   [key any/c]
                   [v any/c])
          (and/c hash? immutable?)]{

通过将 @racket[key] 映射到
@racket[v] 来函数式扩展 @racket[hash]，覆盖 @racket[key] 的任何现有映射，并
返回扩展后的 hash table。

@see-also-mutable-key-caveat[]}

@defproc[(hash-set* [hash (and/c hash? immutable?)]
                    [key any/c]
                    [v any/c]
                    ...
                    ...)
          (and/c hash? immutable?)]{

通过将每个 @racket[key] 映射到
@racket[v] 来函数式扩展 @racket[hash]，覆盖每个 @racket[key] 的任何现有映射，并
返回扩展后的 hash table。映射从左到右添加，因此
后面的映射覆盖前面的映射。

@see-also-mutable-key-caveat[]}

@defproc[(hash-ref [hash hash?]
                   [key any/c]
                   [failure-result failure-result/c
                                   (lambda ()
                                     (raise (make-exn:fail:contract ....)))])
         any]{

返回 @racket[hash] 中 @racket[key] 对应的值。如果未找到
@racket[key] 的值，则 @racket[failure-result] 决定结果：

@itemize[

 @item{如果 @racket[failure-result] 是一个过程，则通过尾调用
       不带参数调用它来产生结果。}

 @item{否则，@racket[failure-result] 作为结果返回。}

]

@see-also-caveats[]}

@defproc[(hash-ref-key [hash hash?]
                       [key any/c]
                       [failure-result failure-result/c
                                       (lambda ()
                                         (raise (make-exn:fail:contract ....)))])
         any]{

返回 @racket[hash] 持有的与 @racket[key] 根据 @racket[hash] 的键比较函数等价的键。如果未找到键，
则按 @racket[hash-ref] 中的方式使用 @racket[failure-result] 来确定结果。

如果 @racket[hash] 不是 @tech{impersonator}，则返回的键
（假设找到的话）将与 @racket[hash] 实际持有的键是 @racket[eq?] 等价的：

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

如果可变 hash 使用不是 @racket[eq?] 等价但根据
hash 的键比较过程等价的键多次更新，hash 保留第一个键：

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

相反，不可变 hash 保留最近用于更新它的键：
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

如果 @racket[hash] 是 @tech{impersonator}，则返回的键
将按 @racket[impersonate-hash] 文档中描述的方式确定。

@see-also-caveats[]

@history[#:added "7.4.0.3"]}

@defproc[(hash-ref! [hash hash?] [key any/c] [to-set failure-result/c])
         any]{

返回 @racket[hash] 中 @racket[key] 对应的值。如果未找到
@racket[key] 的值，则 @racket[to-set] 按 @racket[hash-ref] 中的方式
确定结果（即它是一个计算值的 thunk 或一个普通值），并且该结果
被存储在 @racket[hash] 中对应 @racket[key] 的位置。（注意如果
@racket[to-set] 是 thunk，它不是在尾部位置调用的。）

@see-also-caveats[]}


@defproc[(hash-has-key? [hash hash?] [key any/c])
         boolean?]{

如果 @racket[hash] 包含给定 @racket[key] 的值则返回 @racket[#t]，
否则返回 @racket[#f]。}


@defproc[(hash-update! [hash (and/c hash? (not/c immutable?))]
                       [key any/c]
                       [updater (any/c . -> . any/c)]
                       [failure-result failure-result/c
                        (lambda ()
                          (raise (make-exn:fail:contract ....)))])
         void?]{

 通过将 @racket[updater] 应用于值来更新 @racket[hash] 中 @racket[key] 映射的值。
 @racket[updater] 返回的值成为 @racket[key] 的新映射，覆盖
 @racket[hash] 中的原始值。

 @(examples
   #:eval the-eval
   (eval:no-prompt
    (define h (make-hash))
    (hash-set! h 'a 5))

   (hash-update! h 'a add1)
   h)

 可选参数 @racket[failure-result] 在 @racket[key] 尚无映射时使用，
 方式与 @racket[hash-ref] 中相同。

 @(examples
   #:eval the-eval
   (eval:no-prompt
    (define h (make-hash)))
 
   (eval:error (hash-update! h 'b add1))
   (hash-update! h 'b add1 0)
   h)

 @see-also-caveats[]}


@defproc[(hash-update [hash (and/c hash? immutable?)]
                      [key any/c]
                      [updater (any/c . -> . any/c)]
                      [failure-result failure-result/c
                       (lambda ()
                         (raise (make-exn:fail:contract ....)))])
         (and/c hash? immutable?)]{

 通过将 @racket[updater] 应用于值来函数式更新 @racket[hash] 中 @racket[key] 映射的值，
 并返回新的 hash table。@racket[updater] 返回的值成为返回的 hash table 中
 @racket[key] 的新映射。

 @(examples
   #:eval the-eval
   (eval:no-prompt
    (define h (hash 'a 5)))
   
   (hash-update h 'a add1))

 可选参数 @racket[failure-result] 在 @racket[key] 尚无映射时使用，
 方式与 @racket[hash-ref] 中相同。

 @(examples
   #:eval the-eval
   (eval:no-prompt
    (define h (hash)))
   
   (eval:error (hash-update h 'b add1))
   (hash-update h 'b add1 0))

 @see-also-mutable-key-caveat[]}


@defproc[(hash-remove! [hash (and/c hash? (not/c immutable?))]
                       [key any/c])
         void?]{

移除 @racket[hash] 中 @racket[key] 的任何现有映射。

@see-also-caveats[]}


@defproc[(hash-remove [hash (and/c hash? immutable?)]
                      [key any/c])
         (and/c hash? immutable?)]{

函数式地移除 @racket[hash] 中 @racket[key] 的任何现有映射，
返回新的 hash table。

@see-also-mutable-key-caveat[]}


@defproc[(hash-clear! [hash (and/c hash? (not/c immutable?))])
         void?]{

移除 @racket[hash] 中的所有映射。

如果 @racket[hash] 不是 @tech{impersonator}，则所有映射在常数时间内移除。如果 @racket[hash] 是 @tech{impersonator}，
则每个键通过 @racket[hash-remove!] 逐一移除。

@see-also-caveats[]}


@defproc[(hash-clear [hash (and/c hash? immutable?)])
         (and/c hash? immutable?)]{

函数式地移除 @racket[hash] 中的所有映射。

如果 @racket[hash] 不是 @tech{chaperone}，则清除操作
等价于创建一个新的 @tech{hash table}，该操作在常数时间内执行。如果 @racket[hash] 是 @tech{chaperone}，
则每个键通过 @racket[hash-remove] 逐一移除。}


@defproc[(hash-copy-clear
          [hash hash?]
          [#:kind kind (or/c #f 'immutable 'mutable 'weak 'ephemeron) #f])
         hash?]{

生成一个与 @racket[hash] 具有相同键比较过程的空 @tech{hash table}，
使用给定的 @racket[kind] 或与给定 @racket[hash] 相同的类型。

如果未提供 @racket[kind] 或 @racket[#f]，则生成与给定 @racket[hash]
相同类型和可变性的 hash table。
如果 @racket[kind] 是 @racket['immutable]、@racket['mutable]、
@racket['weak] 或 @racket['ephemeron]，则分别生成
不可变的、以强引用方式持有键的可变的、
以弱引用方式持有键的可变的、或以 ephemeron 方式持有键的可变的表。

@history[#:changed "8.5.0.2" @elem{添加了 @racket[kind] 参数。}]}



@defproc[(hash-map [hash hash?]
                   [proc (any/c any/c . -> . any/c)]
                   [try-order? any/c #f])
         (listof any/c)]{

以未指定的顺序将过程 @racket[proc] 应用于
@racket[hash] 中的每个元素，将结果累积到列表中。过程 @racket[proc] 每次被调用时
接收一个键和它的值，过程的各个结果按顺序出现在结果列表中。

如果在 @racket[hash-map] 或
@racket[hash-for-each] 遍历进行期间，hash table 被扩展了新键（通过
@racket[proc] 或由另一个线程），遍历中可能会丢弃或重复任意键值对。键映射可以
被删除或重新映射（由任何线程）而不会产生不良影响；如果键已经被看到，
更改不会影响遍历，否则遍历会跳过已删除的键或使用重新映射的键的新值。

@see-also-concurrency-caveat[]

如果 @racket[try-order?] 为真，则传递给 @racket[proc] 的键和值的顺序在某些情况下
会被规范化——包括当每个键是以下类型之一时，按以下顺序（前面的项目排在后面的项目之前）：

@itemlist[
 @item{@tech{booleans} 按 @racket[#f] 排在 @racket[#t] 之前排序；}
 @item{@tech{characters} 按 @racket[char<?] 排序；}
 @item{@tech{real numbers} 按 @racket[<] 排序；}
 @item{@tech{symbols} 按 @tech{uninterned} symbols 排在
       @tech{unreadable symbols} 之前，再排在 @tech{interned} symbols 之前，
       然后按 @racket[symbol<?] 排序；}
 @item{@tech{keywords} 按 @racket[keyword<?] 排序；}
 @item{@tech{strings} 按 @racket[string<?] 排序；}
 @item{@tech{byte strings} 按 @racket[bytes<?] 排序；}
 @item{@racket[null]；}
 @item{@|void-const|；以及}
 @item{@racket[eof]。}
]

@history[#:changed "6.3" @elem{添加了 @racket[try-order?] 参数。}
         #:changed "7.1.0.7" @elem{添加了对 @racket[try-order?] 的保证。}]}

@defproc[(hash-map/copy
          [hash hash?]
          [proc (any/c any/c . -> . (values any/c any/c))]
          [#:kind kind (or/c #f 'immutable 'mutable 'weak 'ephemeron) #f])
         hash?]{

以未指定的顺序将过程 @racket[proc] 应用于
@racket[hash] 中的每个元素，将结果累积到一个与 @racket[hash]
具有相同键比较过程的新 hash 中，使用给定的 @racket[kind] 或与给定
@racket[hash] 相同的类型。

如果未提供 @racket[kind] 或 @racket[#f]，则生成与给定 @racket[hash]
相同类型和可变性的 hash table。
如果 @racket[kind] 是 @racket['immutable]、@racket['mutable]、
@racket['weak] 或 @racket['ephemeron]，则分别生成
不可变的、以强引用方式持有键的可变的、
以弱引用方式持有键的可变的、或以 ephemeron 方式持有键的可变的表。

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

@defproc[(hash-keys [hash hash?] [try-order? any/c #f])
         (listof any/c)]{
以未指定的顺序返回 @racket[hash] 的键列表。

如果 @racket[try-order?] 为真，则键的顺序在某些情况下会被规范化。关于
@racket[try-order?] 的进一步说明以及在 @racket[hash-keys] 期间修改 @racket[hash] 的信息，
请参见 @racket[hash-map]。@see-also-concurrency-caveat[]

@history[#:changed "8.3.0.11" @elem{添加了 @racket[_try-order?] 参数。}]}

@defproc[(hash-values [hash hash?] [try-order? any/c #f])
         (listof any/c)]{
以未指定的顺序返回 @racket[hash] 的值列表。

如果 @racket[try-order?] 为真，则值的顺序在某些情况下会根据关联键的排序被规范化。
关于 @racket[try-order?] 的进一步说明以及在 @racket[hash-values] 期间
修改 @racket[hash] 的信息，请参见 @racket[hash-map]。@see-also-concurrency-caveat[]

@history[#:changed "8.3.0.11" @elem{添加了 @racket[_try-order?] 参数。}]}

@defproc[(hash->list [hash hash?] [try-order? any/c #f])
         (listof (cons/c any/c any/c))]{
以未指定的顺序返回 @racket[hash] 的键值对列表。

如果 @racket[try-order?] 为真，则键和值的顺序在某些情况下会被规范化。
关于 @racket[try-order?] 的进一步说明以及在 @racket[hash->list] 期间
修改 @racket[hash] 的信息，请参见 @racket[hash-map]。@see-also-concurrency-caveat[]

@history[#:changed "8.3.0.11" @elem{添加了 @racket[_try-order?] 参数。}]}

@defproc[(hash-keys-subset? [hash1 hash?] [hash2 hash?])
         boolean?]{
如果 @racket[hash1] 的键是 @racket[hash2] 的键的子集或相同则返回 @racket[#t]。两个 hash table 必须使用
相同的键比较函数（@racket[equal?]、
@racket[equal-always?]、@racket[eqv?] 或 @racket[eq?]），否则
@exnraise[exn:fail:contract]。

对不可变 hash table 使用 @racket[hash-keys-subset?] 可能比
遍历 @racket[hash1] 的键以确保每个键都在 @racket[hash2] 中快得多。

@history[#:added "6.5.0.8"]}

@defproc[(hash-for-each [hash hash?]
                        [proc (any/c any/c . -> . any)]
                        [try-order? any/c #f])
         void?]{

以未指定的顺序将 @racket[proc] 应用于 @racket[hash] 中的每个元素
（为了 @racket[proc] 的副作用）。过程 @racket[proc] 每次被调用时
接收一个键和它的值。

关于 @racket[try-order?] 以及在 @racket[proc] 中修改 @racket[hash] 的信息，
请参见 @racket[hash-map]。
@see-also-concurrency-caveat[]

@history[#:changed "6.3" @elem{添加了 @racket[try-order?] 参数。}
         #:changed "7.1.0.7" @elem{添加了对 @racket[try-order?] 的保证。}]}


@defproc[(hash-count [hash hash?])
         exact-nonnegative-integer?]{

返回 @racket[hash] 映射的键数。

对于 Racket 的 @tech{CS} 实现，结果始终在常数时间内原子地计算。对于 Racket 的 @tech{BC} 实现，
仅当 @racket[hash] 不以弱引用或类似 @tech{ephemeron} 的方式保留键时，
结果才在常数时间内原子地计算，
否则需要遍历来计算键数。}


@defproc[(hash-empty? [hash hash?]) boolean?]{

等价于 @racket[(zero? (hash-count hash))]。}


@defproc[(hash-iterate-first [hash hash?])
         (or/c #f exact-nonnegative-integer?)]{

如果 @racket[hash] 不包含元素则返回 @racket[#f]，否则
返回一个整数作为 hash table 中第一个元素的索引；"第一"指的是
表元素的未指定排序，索引值不一定是连续的
整数。

对于可变 @racket[hash]，只要没有项目被添加到 @racket[hash] 或从其中移除，
该索引就保证指向第一项。更一般地说，索引只有在来自
@racket[hash-iterate-first] 或 @racket[hash-iterate-next] 且 hash table 未被修改的情况下
才保证是给定 hash table 的 @deftech{valid hash index}。对于
以弱引用方式持有键或以类似 @tech{ephemerons} 方式持有键的 hash table，
当垃圾回收器发现键不可达时，hash table 可能会被隐式修改
（参见 @secref["gc-model"]）。}


@defproc[(hash-iterate-next [hash hash?]
                            [pos exact-nonnegative-integer?])
         (or/c #f exact-nonnegative-integer?)]{

返回一个整数作为 @racket[hash] 中由 @racket[pos] 索引的元素之后
的元素的索引（不一定比 @racket[pos] 大一），如果 @racket[pos]
指向 @racket[hash] 中的最后一个元素则返回 @racket[#f]。

如果 @racket[pos] 不是 @racket[hash] 的 @tech{valid hash index}，
则结果可能是 @racket[#f] 或者是仍然有效的下一个索引。
如果 hash table 仅通过删除键来修改，则保证为后一种结果。

@history[#:changed "7.0.0.10" @elem{处理无效索引时返回 @scheme[#f]
                                    而不是引发 @racket[exn:fail:contract]。}]}


@deftogether[(
@defproc[(hash-iterate-key [hash hash?]
                           [pos exact-nonnegative-integer?])
         any/c]
@defproc[#:link-target? #f
         (hash-iterate-key [hash hash?]
                           [pos exact-nonnegative-integer?]
                           [bad-index-v any/c])
         any/c]
)]{
         
返回 @racket[hash] 中索引 @racket[pos] 处元素的键。

如果 @racket[pos] 不是 @racket[hash] 的 @tech{valid hash index}，
则如果提供了 @racket[bad-index-v] 则返回该值，否则
@exnraise[exn:fail:contract]。

@history[#:changed "7.0.0.10" @elem{添加了可选参数 @racket[bad-index-v]。}]}


@deftogether[(
@defproc[(hash-iterate-value [hash hash?]
                             [pos exact-nonnegative-integer?])
         any]
@defproc[#:link-target? #f
         (hash-iterate-value [hash hash?]
                             [pos exact-nonnegative-integer?]
                             [bad-index-v any/c])
         any]
)]{

返回 @racket[hash] 中索引 @racket[pos] 处元素的值。

如果 @racket[pos] 不是 @racket[hash] 的 @tech{valid hash index}，
则如果提供了 @racket[bad-index-v] 则返回该值，否则
@exnraise[exn:fail:contract]。

@history[#:changed "7.0.0.10" @elem{添加了可选参数 @racket[bad-index-v]。}]}



@deftogether[(
@defproc[(hash-iterate-pair [hash hash?]
                            [pos exact-nonnegative-integer?])
         (cons any/c any/c)]
@defproc[#:link-target? #f
         (hash-iterate-pair [hash hash?]
                            [pos exact-nonnegative-integer?]
                            [bad-index-v any/c])
         (cons any/c any/c)]
)]{

返回包含 @racket[hash] 中索引 @racket[pos] 处元素的键和值的 pair。

如果 @racket[pos] 不是 @racket[hash] 的 @tech{valid hash index}，
则如果提供了 @racket[bad-index-v] 则返回 @racket[(cons bad-index-v bad-index-v)]，否则
@exnraise[exn:fail:contract]。

@history[#:added "6.4.0.5"
         #:changed "7.0.0.10" @elem{添加了可选参数 @racket[bad-index-v]。}]}


@deftogether[(
@defproc[(hash-iterate-key+value [hash hash?]
                                 [pos exact-nonnegative-integer?])
         (values any/c any/c)]
@defproc[#:link-target? #f
         (hash-iterate-key+value [hash hash?]
                                 [pos exact-nonnegative-integer?]
                                 [bad-index-v any/c])
         (values any/c any/c)]
)]{

返回 @racket[hash] 中索引 @racket[pos] 处元素的键和值。

如果 @racket[pos] 不是 @racket[hash] 的 @tech{valid hash index}，
则如果提供了 @racket[bad-index-v] 则返回 @racket[(values bad-index-v bad-index-v)]，否则
@exnraise[exn:fail:contract]。

@history[#:added "6.4.0.5"
         #:changed "7.0.0.10" @elem{添加了可选参数 @racket[bad-index-v]。}]}


@defproc[(hash-copy [hash hash?]) 
         (and/c hash? (not/c immutable?))]{

返回一个与 @racket[hash] 具有相同映射、相同键比较模式和相同键持有强度的可变 hash table。}

@;------------------------------------------------------------------------
@section{Additional Hash Table Functions}

@note-lib-only[racket/hash]

@(require (for-label racket/hash))

@(define the-eval (make-base-eval))
@(the-eval '(require racket/hash))

@defproc[(hash-union [h0 (and/c hash? immutable?)]
                     [h hash?] ...
                     [#:combine combine
                                (-> any/c any/c any/c)
                                (lambda _ (error 'hash-union ....))]
                     [#:combine/key combine/key
                                    (-> any/c any/c any/c any/c)
                                    (lambda (k a b) (combine a b))])
         (and/c hash? immutable?)]{

通过函数式更新计算 @racket[h0] 与每个 hash table @racket[h] 的并集，
依次将每个 @racket[h] 的每个元素添加到 @racket[h0]。对于每个
键 @racket[k] 和值 @racket[v]，如果从 @racket[k] 到某个值
@racket[v0] 的映射已经存在，则将其替换为从 @racket[k] 到
@racket[(combine/key k v0 v)] 的映射。

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

@defproc[(hash-union! [h0 (and/c hash? (not/c immutable?))]
                      [h hash?] ...
                      [#:combine combine
                                 (-> any/c any/c any/c)
                                 (lambda _ (error 'hash-union ....))]
                      [#:combine/key combine/key
                                     (-> any/c any/c any/c any/c)
                                     (lambda (k a b) (combine a b))])
         void?]{

通过可变更新计算 @racket[h0] 与每个 hash table @racket[h] 的并集，
依次将每个 @racket[h] 的每个元素添加到 @racket[h0]。对于每个
键 @racket[k] 和值 @racket[v]，如果从 @racket[k] 到某个值
@racket[v0] 的映射已经存在，则将其替换为从 @racket[k] 到
@racket[(combine/key k v0 v)] 的映射。

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

@defproc[(hash-intersect [h0 (and/c hash? immutable?)]
			 [h hash?] ...
                         [#:combine combine
                                    (-> any/c any/c any/c)
                                    (lambda _ (error 'hash-intersect ...))]
                         [#:combine/key combine/key
                                    	(-> any/c any/c any/c any/c)
                                    	(lambda (k a b) (combine a b))])
	 (and/c hash? immutable?)]{

构造 @racket[h0] 与每个 hash table @racket[h] 的交集 hash table。
在结果 hash table 中，键 @racket[k] 映射到
@racket[k] 在每个 hash table 中映射的值的组合。最终值
通过对每个 hash table 中出现的值进行逐步组合来计算，
方法是应用 @racket[(combine/key k v vi)] 或
@racket[(combine v vi)]，其中 @racket[vi] 是 @racket[k] 在第 i 个
hash table @racket[h] 中映射的值，@racket[v] 是前面步骤的累积值。
第一个参数的比较谓词（@racket[eq?]、
@racket[eqv?]、@racket[equal-always?]、@racket[equal?]）决定结果的比较谓词。

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

@(close-eval the-eval)
