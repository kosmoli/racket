#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "hash-tables"]{哈希表}

@deftech{hash table} 实现从键到值的映射，其中键和值可以是任意 Racket 值，访问和更新表通常是常数时间操作。键使用 @racket[equal?]、@racket[eqv?] 或 @racket[eq?] 进行比较，具体取决于哈希表是使用 @racket[make-hash]、@racket[make-hasheqv] 还是 @racket[make-hasheq] 创建的。

@examples[
(define ht (make-hash))
(hash-set! ht "apple" '(red round))
(hash-set! ht "banana" '(yellow long))
(hash-ref ht "apple")

(hash-ref ht "coconut")
(hash-ref ht "coconut" "not there")
]

@racket[hash]、@racket[hasheqv] 和 @racket[hasheq] 函数从一组初始键和值创建不可变哈希表，其中每个值在键之后作为参数提供。不可变哈希表可以使用 @racket[hash-set] 扩展，该操作在常数时间内生成一个新的不可变哈希表。

@examples[
(define ht (hash "apple" 'red "banana" 'yellow))
(hash-ref ht "apple")
(define ht2 (hash-set ht "coconut" 'brown))
(hash-ref ht "coconut")
(hash-ref ht2 "coconut")
]

通过使用 @litchar{#hash}（用于 @racket[equal?]-based 表）、@litchar{#hasheqv}（用于 @racket[eqv?]-based 表）或 @litchar{#hasheq}（用于 @racket[eq?]-based 表）作为表达式编写字面不可变哈希表。括号序列必须紧接在 @litchar{#hash}、@litchar{#hasheq} 或 @litchar{#hasheqv} 之后，其中每个元素都是点对的键值对。@litchar{#hash} 等形式隐式地 @racket[quote] 它们的键和值子形式。

@examples[
(define ht #hash((\"apple\" . red)
                 (\"banana\" . yellow)))
(hash-ref ht "apple")
]

@refdetails/gory["parse-hashtable"]{哈希表字面语法}

可变和不可变哈希表打印为不可变哈希表，使用带引号的 @litchar{#hash}、@litchar{#hasheqv} 或 @litchar{#hasheq} 形式（如果所有键和值都可以使用 @racket[quote] 表示），或者使用 @racketresult[hash]、@racketresult[hasheq] 或 @racketresult[hasheqv] 表示：

@examples[
#hash((\"apple\" . red)
      (\"banana\" . yellow))
(hash 1 (srcloc \"file.rkt\" 1 0 1 (+ 4 4)))
]

可变哈希表可以可选地保留其键 @defterm{weakly}，因此每个映射仅在其他地方保留键时才保留。

@examples[
(define ht (make-weak-hasheq))
(hash-set! ht (gensym) \"can you see me?\")
(collect-garbage)
(eval:alts (hash-count ht) 0)
]

需要注意：即使弱哈希表也会强保留其值，只要相应的键可访问。这在值引用其键时创建了循环依赖，导致映射永久保留。要打破循环，请将键映射到 @defterm{ephemeron}，该值与其键相关联（除了哈希表之外）。

@refdetails/gory["ephemerons"]{使用 ephemeron}

@examples[
(define ht (make-weak-hasheq))
(let ([g (gensym)])
  (hash-set! ht g (list g)))
(collect-garbage)

(eval:alts (hash-count ht) 1)
]

@interaction[
(define ht (make-weak-hasheq))
(let ([g (gensym)])
  (hash-set! ht g (make-ephemeron g (list g))))
(collect-garbage)
(eval:alts (hash-count ht) 0)
]

@refdetails["hashtables"]{hash tables 和 hash table procedure}
