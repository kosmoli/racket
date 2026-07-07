#lang scribble/doc
@(require "mz.rkt"
          scribble/scheme
          (for-syntax racket/base)
          (for-label racket/generator
                     racket/generic
                     compatibility/mlist
                     syntax/stx))

@(define (info-on-seq where what)
   @margin-note{See @secref[where] for information on using @|what| as
                sequences.})

@(define (for-element-reachability what)
   @elem{See @racket[for] for information on the reachability of @|what| elements
         during an iteration.})

@title[#:style 'toc #:tag "sequences+streams"]{Sequences and Streams}

@tech{Sequences} 和 @tech{streams} 对集合中元素的迭代进行了抽象。
Sequences 允许使用 @racket[for] 宏或 @racket[sequence-map] 等 sequence 操作进行迭代。
Streams 是函数式的 sequences，可以以通用方式或 stream 特定方式使用。@tech{Generators}
是密切相关的有状态对象，可以转换为 sequence，反之亦然。

@local-table-of-contents[]

@; ======================================================================
@section[#:tag "sequences"]{Sequences}

@(define sequence-evaluator
   (let ([evaluator (make-base-eval)])
     (evaluator '(require racket/generic racket/list racket/stream racket/sequence
                          racket/contract racket/dict))
     evaluator))

@guideintro["sequences"]{sequences}

@deftech{sequence} 封装了一个有序的值集合。
sequence 的元素可以通过 @racket[for] 语法形式之一、通过 @racket[sequence-generate]
返回的过程，或者通过将 sequence 转换为 @tech{stream} 来提取。

sequence 数据类型与许多其他数据类型重叠。在内置数据类型中，sequence 数据类型包括以下：

@itemize[

 @item{精确非负整数（见下文）}

 @item{字符串（见 @secref["strings"]）}

 @item{字节字符串（见 @secref["bytestrings"]）}

 @item{列表（见 @secref["pairs"]）}

 @item{可变列表（见 @secref["mpairs"]）}

 @item{向量（见 @secref["vectors"]）}

 @item{flvectors（见 @secref["flvectors"]）}

 @item{fxvectors（见 @secref["fxvectors"]）}

 @item{哈希表（见 @secref["hashtables"]）}

 @item{字典（见 @secref["dicts"]）}

 @item{集合（见 @secref["sets"]）}

 @item{输入端口（见 @secref["ports"]）}

 @item{streams（见 @secref["streams"]）}

]

一个非负 @tech{整数} 的 @tech{精确数} @racket[_k] 作为一个 sequence，
类似于 @racket[(in-range _k)]，但 @racket[_k] 本身不是一个 @tech{stream}。

可以使用结构体类型属性定义自定义 sequences。定义自定义 sequence 最简单的方法是使用
@racket[gen:stream] @tech{泛型接口}。Streams 适用于可直接迭代的数据结构。
例如，列表可以通过 @racket[first] 和 @racket[rest] 直接迭代。另一方面，向量不能直接迭代：
迭代必须通过索引进行。对于不能直接迭代的数据结构，该数据结构的 @deftech{iterator}
可以定义为一个 stream（例如，包含向量索引的结构体）。

例如，展开链表（表示为向量列表）本身不适合 stream 抽象，但具有可以表示为 streams 的基于索引的迭代器：

@examples[#:eval sequence-evaluator
  (struct unrolled-list-iterator (idx lst)
    #:methods gen:stream
    [(define (stream-empty? iter)
       (define lst (unrolled-list-iterator-lst iter))
       (or (null? lst)
           (and (>= (unrolled-list-iterator-idx iter)
                    (vector-length (first lst)))
                (null? (rest lst)))))
     (define (stream-first iter)
       (vector-ref (first (unrolled-list-iterator-lst iter))
                   (unrolled-list-iterator-idx iter)))
     (define (stream-rest iter)
       (define idx (unrolled-list-iterator-idx iter))
       (define lst (unrolled-list-iterator-lst iter))
       (if (>= idx (sub1 (vector-length (first lst))))
           (unrolled-list-iterator 0 (rest lst))
           (unrolled-list-iterator (add1 idx) lst)))])

  (define (make-unrolled-list-iterator ul)
    (unrolled-list-iterator 0 (unrolled-list-lov ul)))

  (struct unrolled-list (lov)
    #:property prop:sequence
    make-unrolled-list-iterator)

  (define ul1 (unrolled-list '(#(cracker biscuit) #(cookie scone))))
  (for/list ([x ul1]) x)
]

@racket[prop:sequence] 属性在指定迭代方面提供了更大的灵活性，例如当需要预处理步骤来准备数据以进行迭代时。
@racket[make-do-sequence] 函数创建一个 sequence，给定一个返回实现 sequence 的过程的 thunk，
而 @racket[prop:sequence] 属性可以与结构体类型关联以实现其到 sequence 的隐式转换。

对于大多数 sequence 类型，从 sequence 中提取元素不会对原始 sequence 值产生副作用；
例如，从列表中提取元素的 sequence 不会改变列表。对于其他 sequence 类型，
每次提取都意味着一个副作用；例如，从端口提取字节的 sequence 会导致从端口读取字节。
@elemtag["sequence-state"]{一个} sequence 的状态可以跨越该 sequence 的所有使用（如端口），
也可以限定在每次通过 @racket[for] 形式、@racket[sequence->stream]、
@racket[sequence-generate] 或 @racket[sequence-generate*] @deftech{initiate} 该 sequence 的不同时间。
具体来说，传递给 @racket[make-do-sequence] 的 thunk 在每次使用该 sequence 时被调用以 @tech{initiate} 该 sequence。
因此，不同的 sequences 在被多次 @tech{initiate} 时表现不同。

@examples[#:eval sequence-evaluator
          #:label #f
          (define (double-initiate s1)
            (code:comment "initiate the sequence twice")
            (define-values (more?.1 next.1) (sequence-generate s1))
            (define-values (more?.2 next.2) (sequence-generate s1))
            (code:comment "alternate fetching from sequence via the two initiations")
            (list (next.1) (next.2) (next.1) (next.2)))

          (double-initiate (open-input-string "abcdef"))
          (double-initiate (list 97 98 99 100))
          (double-initiate (in-naturals 97))]

此外，sequence 中的后续元素可能仅仅通过调用 @racket[sequence-generate] 的第一个结果就被"消耗"了，
即使第二个结果从未被调用。

@examples[#:eval sequence-evaluator
          #:label #f
          (define (double-initiate-and-use-more? s1)
            (code:comment "initiate the sequence twice")
            (define-values (more?.1 next.1) (sequence-generate s1))
            (define-values (more?.2 next.2) (sequence-generate s1))
            (code:comment "alternate fetching from sequence via the two initiations")
            (code:comment "but this time call `more?` in between")
            (list (next.1) (more?.1) (next.2) (more?.2)
                  (next.1) (more?.1) (next.2) (more?.2)))

          (double-initiate-and-use-more? (open-input-string "abcdef"))]

在此示例中，第一次调用 @racket[sequence-generate] 中嵌入的状态仅仅通过调用 @racket[_more?.1] 就"获取"了 @racket[98]。

sequence 的单个元素通常对应单个值，但一个元素也可能对应多个值。
例如，哈希表为 sequence 中的每个元素生成两个值——一个键及其值。

@; ----------------------------------------------------------------------
@subsection{Sequence 谓词和构造器}

@defproc[(sequence? [v any/c]) boolean?]{
  如果 @racket[v] 可以用作 @tech{sequence} 则返回 @racket[#t]，否则返回 @racket[#f]。

@examples[#:eval sequence-evaluator
  (sequence? 42)
  (sequence? '(a b c))
  (sequence? "word")
  (sequence? #\x)]}

@defproc*[([(in-range [end real?]) stream?]
           [(in-range [start real?] [end real?] [step real? 1]) stream?])]{
  返回一个元素为数字的 sequence（同时也是 @tech{stream}）。
  单参数形式 @racket[(in-range end)] 等价于 @racket[(in-range 0 end 1)]。
  sequence 中的第一个数字是 @racket[start]，每个后续元素通过将 @racket[step] 加到前一个元素来生成。
  如果 @racket[step] 非负，sequence 在元素大于或等于 @racket[end] 之前停止；
  如果 @racket[step] 为负，sequence 在元素小于或等于 @racket[end] 之前停止。
  @speed[in-range "number"]


  @examples[#:label "Example: gaussian sum" #:eval sequence-evaluator
    (for/sum ([x (in-range 10)]) x)]


  @examples[#:label "Example: sum of even numbers" #:eval sequence-evaluator
    (for/sum ([x (in-range 0 100 2)]) x)]

  当给定零作为 @racket[step] 时，@racket[in-range] 返回一个无限 sequence。
  当 @racket[step] 是一个非常小的数字，且 @racket[step] 或 sequence 元素是浮点数时，
  它也可能返回无限 sequences。
}

@defproc[(in-inclusive-range [start real?] [end real?] [step real? 1]) stream?]{

  类似于 @racket[in-range]，但 sequence 的停止条件已更改，使得最后一个元素允许等于 @racket[end]。
  @speed[in-inclusive-range "number"]

  @examples[#:eval sequence-evaluator
    (sequence->list (in-inclusive-range 7 11))
    (sequence->list (in-inclusive-range 7 11 2))
    (sequence->list (in-inclusive-range 7 10 2))
  ]

  @history[#:added "8.0.0.13"]
}


@defproc[(in-naturals [start exact-nonnegative-integer? 0]) stream?]{
  返回一个从 @racket[start] 开始的精确整数的无限 sequence（同时也是 @tech{stream}），
  其中每个元素比前一个元素大一。@speed[in-naturals "integer"]

  @examples[#:eval sequence-evaluator
    (for/list ([k (in-naturals)]
               [x (in-range 10)])
      (list k x))]
}


@defproc[(in-list [lst list?]) stream?]{
  返回一个 sequence（同时也是 @tech{stream}），等价于直接使用 @racket[lst] 作为 sequence。
  @info-on-seq["pairs" "lists"]
  @speed[in-list "list"]
  @for-element-reachability["list"]

  @examples[#:eval sequence-evaluator
    (for/list ([x (in-list '(3 1 4))])
      `(,x ,(* x x)))]

@history[#:changed "6.7.0.4" @elem{改进了 @racket[for] 中列表的元素可达性保证。}]}


@defproc[(in-mlist [mlst mlist?]) sequence?]{
  返回一个等价于 @racket[mlst] 的 sequence。虽然预期 @racket[mlst] 是 @tech{mutable list}，
  但 @racket[in-mlist] 最初只检查 @racket[mlst] 是否是 @tech{mutable pair} 或 @racket[null]，
  因为它可能在迭代期间发生变化。
  @info-on-seq["mpairs" "mutable lists"]
  @speed[in-mlist "mutable list"]

  @examples[#:eval sequence-evaluator
    (for/list ([x (in-mlist (mcons "RACKET" (mcons "LANG" '())))])
      (string-length x))]
}

@defproc[(in-vector [vec vector?]
                    [start exact-nonnegative-integer? 0]
                    [stop (or/c exact-integer? #f) #f]
                    [step (and/c exact-integer? (not/c zero?)) 1])
         sequence?]{
  当不提供可选参数时，返回一个等价于 @racket[vec] 的 sequence。

  @info-on-seq["vectors" "vectors"]

  可选参数 @racket[start]、@racket[stop] 和 @racket[step] 与 @racket[in-range] 类似，
  不同之处在于 @racket[stop] 的 @racket[#f] 值等价于 @racket[(vector-length vec)]。
  也就是说，sequence 中的第一个元素是 @racket[(vector-ref vec start)]，
  每个后续元素通过将 @racket[step] 加到前一个元素的索引来生成。
  如果 @racket[step] 非负，sequence 在索引大于或等于 @racket[end] 之前停止；
  如果 @racket[step] 为负，sequence 在索引小于或等于 @racket[end] 之前停止。

  如果 @racket[start] 不是有效索引，则 @exnraise[exn:fail:contract]，
  除非 @racket[start]、@racket[stop] 和 @racket[(vector-length vec)] 相等，
  此时结果为空 sequence。

  @examples[#:eval sequence-evaluator
            (for ([x (in-vector (vector 1) 1)]) x)
            (eval:error (for ([x (in-vector (vector 1) 2)]) x))
            (for ([x (in-vector (vector) 0 0)]) x)
            (for ([x (in-vector (vector 1) 1 1)]) x)]

  如果 @racket[stop] 不在 [-1, @racket[(vector-length vec)]] 范围内，则 @exnraise[exn:fail:contract]。

  如果 @racket[start] 小于 @racket[stop] 且 @racket[step] 为负，则 @exnraise[exn:fail:contract]。
  类似地，如果 @racket[start] 大于 @racket[stop] 且 @racket[step] 为正，则 @exnraise[exn:fail:contract]。

  @speed[in-vector "vector"]

  @examples[#:eval sequence-evaluator
    (define (histogram vector-of-words)
      (define a-hash (make-hash))
      (for ([word (in-vector vector-of-words)])
        (hash-set! a-hash word (add1 (hash-ref a-hash word 0))))
      a-hash)
    (histogram #("hello" "world" "hello" "sunshine"))]
}

@defproc[(in-string [str string?]
                    [start exact-nonnegative-integer? 0]
                    [stop (or/c exact-integer? #f) #f]
                    [step (and/c exact-integer? (not/c zero?)) 1])
         sequence?]{
  当不提供可选参数时，返回一个等价于 @racket[str] 的 sequence。

  @info-on-seq["strings" "strings"]

  可选参数 @racket[start]、@racket[stop] 和 @racket[step] 与 @racket[in-vector] 中相同。

  @speed[in-string "string"]

  @examples[#:eval sequence-evaluator
    (define (line-count str)
      (for/sum ([ch (in-string str)])
        (if (char=? #\newline ch) 1 0)))
    (line-count "this string\nhas\nthree \nnewlines")]
}

@defproc[(in-bytes [bstr bytes?]
                   [start exact-nonnegative-integer? 0]
                   [stop (or/c exact-integer? #f) #f]
                   [step (and/c exact-integer? (not/c zero?)) 1])
         sequence?]{
  当不提供可选参数时，返回一个等价于 @racket[bstr] 的 sequence。

  @info-on-seq["bytestrings" "byte strings"]

  可选参数 @racket[start]、@racket[stop] 和 @racket[step] 与 @racket[in-vector] 中相同。

  @speed[in-bytes "byte string"]

  @examples[#:eval sequence-evaluator
    (define (has-eof? bs)
      (for/or ([ch (in-bytes bs)])
        (= ch 0)))
    (has-eof? #"this byte string has an \0embedded zero byte")
    (has-eof? #"this byte string does not")]
}

@defproc[(in-port [r (input-port? . -> . any/c) read]
                  [in input-port? (current-input-port)])
         sequence?]{
  返回一个 sequence，其元素通过对 @racket[in] 调用 @racket[r] 产生，直到产生 @racket[eof]。}

@defproc[(in-input-port-bytes [in input-port?]) sequence?]{
  返回一个等价于 @racket[(in-port read-byte in)] 的 sequence。}

@defproc[(in-input-port-chars [in input-port?]) sequence?]{
  返回一个元素从 @racket[in] 读取为字符的 sequence（等价于 @racket[(in-port read-char in)]）。}

@defproc[(in-lines [in input-port? (current-input-port)]
                   [mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'any])
         sequence?]{
  返回一个等价于 @racket[(in-port (lambda (p) (read-line p mode)) in)] 的 sequence。
  注意默认模式是 @racket['any]，而 @racket[read-line] 的默认模式是 @racket['linefeed]。}

@defproc[(in-bytes-lines [in input-port? (current-input-port)]
                         [mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'any])
         sequence?]{
  返回一个等价于 @racket[(in-port (lambda (p) (read-bytes-line p mode)) in)] 的 sequence。
  注意默认模式是 @racket['any]，而 @racket[read-bytes-line] 的默认模式是 @racket['linefeed]。}

@defproc*[([(in-hash [hash hash?]) sequence?]
           [(in-hash [hash hash?] [bad-index-v any/c]) sequence?])]{
  返回一个等价于 @racket[hash] 的 sequence，除非提供了 @racket[bad-index-v]。

  如果提供了 @racket[bad-index-v]，则当 @racket[hash] 被并发修改使得迭代没有 @tech{valid hash index} 时，
  @racket[bad-index-v] 将同时作为键和值返回。提供 @racket[bad-index-v] 在遍历具有弱引用键的哈希表时特别有用，
  因为条目可以被异步移除（即在 @racket[in-hash] 已承诺进行另一次迭代之后，但在它能够访问下一次迭代的条目之前）。

  @examples[
    (define table (hash 'a 1 'b 2))
    (for ([(key value) (in-hash table)])
      (printf "key: ~a value: ~a\n" key value))]

  @info-on-seq["hashtables" "hash tables"]

  @history[#:changed "7.0.0.10" @elem{添加了可选的 @racket[bad-index-v] 参数。}]}

@defproc*[([(in-hash-keys [hash hash?]) sequence?]
           [(in-hash-keys [hash hash?] [bad-index-v any/c]) sequence?])]{
  返回一个元素为 @racket[hash] 的键的 sequence，使用 @racket[bad-index-v] 的方式与 @racket[in-hash] 相同。

  @examples[
    (define table (hash 'a 1 'b 2))
    (for ([key (in-hash-keys table)])
      (printf "key: ~a\n" key))]

  @history[#:changed "7.0.0.10" @elem{添加了可选的 @racket[bad-index-v] 参数。}]}

@defproc*[([(in-hash-values [hash hash?]) sequence?]
           [(in-hash-values [hash hash?] [bad-index-v any/c]) sequence?])]{
  返回一个元素为 @racket[hash] 的值的 sequence，使用 @racket[bad-index-v] 的方式与 @racket[in-hash] 相同。

  @examples[
    (define table (hash 'a 1 'b 2))
    (for ([value (in-hash-values table)])
      (printf "value: ~a\n" value))]

  @history[#:changed "7.0.0.10" @elem{添加了可选的 @racket[bad-index-v] 参数。}]}

@defproc*[([(in-hash-pairs [hash hash?]) sequence?]
           [(in-hash-pairs [hash hash?] [bad-index-v any/c]) sequence?])]{
  返回一个元素为 pairs 的 sequence，每个 pair 包含 @racket[hash] 中的一个键及其值
  （与直接使用 @racket[hash] 作为 sequence 来获取每个元素的键和值作为单独的值不同）。

  @racket[bad-index-v] 参数（如果提供）的使用方式与 @racket[in-hash] 相同。
  当遇到无效索引时，sequence 中的 pair 将以 @racket[bad-index-v] 作为其 @racket[car] 和 @racket[cdr]。

  @examples[
    (define table (hash 'a 1 'b 2))
    (for ([key+value (in-hash-pairs table)])
      (printf "key and value: ~a\n" key+value))]

  @history[#:changed "7.0.0.10" @elem{添加了可选的 @racket[bad-index-v] 参数。}]}

@deftogether[(
@defproc[(in-mutable-hash
          [hash (and/c hash? (not/c immutable?) hash-strong?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-mutable-hash
          [hash (and/c hash? (not/c immutable?) hash-strong?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-mutable-hash-keys
          [hash (and/c hash? (not/c immutable?) hash-strong?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-mutable-hash-keys
          [hash (and/c hash? (not/c immutable?) hash-strong?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-mutable-hash-values
          [hash (and/c hash? (not/c immutable?) hash-strong?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-mutable-hash-values
          [hash (and/c hash? (not/c immutable?) hash-strong?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-mutable-hash-pairs
          [hash (and/c hash? (not/c immutable?) hash-strong?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-mutable-hash-pairs
          [hash (and/c hash? (not/c immutable?) hash-strong?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-immutable-hash
          [hash (and/c hash? immutable?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-immutable-hash
          [hash (and/c hash? immutable?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-immutable-hash-keys
          [hash (and/c hash? immutable?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-immutable-hash-keys
          [hash (and/c hash? immutable?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-immutable-hash-values
          [hash (and/c hash? immutable?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-immutable-hash-values
          [hash (and/c hash? immutable?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-immutable-hash-pairs
          [hash (and/c hash? immutable?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-immutable-hash-pairs
          [hash (and/c hash? immutable?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-weak-hash
          [hash (and/c hash? hash-weak?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-weak-hash
          [hash (and/c hash? hash-weak?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-weak-hash-keys
          [hash (and/c hash? hash-weak?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-weak-hash-keys
          [hash (and/c hash? hash-weak?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-weak-hash-values
          [hash (and/c hash? hash-weak?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-weak-hash-keys
          [hash (and/c hash? hash-weak?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-weak-hash-pairs
          [hash (and/c hash? hash-weak?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-weak-hash-pairs
          [hash (and/c hash? hash-weak?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-ephemeron-hash
          [hash (and/c hash? hash-ephemeron?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-ephemeron-hash
          [hash (and/c hash? hash-ephemeron?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-ephemeron-hash-keys
          [hash (and/c hash? hash-ephemeron?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-ephemeron-hash-keys
          [hash (and/c hash? hash-ephemeron?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-ephemeron-hash-values
          [hash (and/c hash? hash-ephemeron?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-ephemeron-hash-keys
          [hash (and/c hash? hash-ephemeron?)] [bad-index-v any/c])
	  sequence?]
@defproc[(in-ephemeron-hash-pairs
          [hash (and/c hash? hash-ephemeron?)])
	  sequence?]
@defproc[#:link-target? #f
         (in-ephemeron-hash-pairs
          [hash (and/c hash? hash-ephemeron?)] [bad-index-v any/c])
	  sequence?]
)]{
   特定类型哈希表的 sequence 构造器。
   这些可能比类似的 @racket[in-hash] 形式性能更好。

   @history[#:added "6.4.0.6"
            #:changed "7.0.0.10" @elem{添加了可选的 @racket[bad-index-v] 参数。}
         #:changed "8.0.0.10" @elem{添加了 @schemeidfont{ephemeron} 变体。}]
}


@defproc[(in-directory [dir (or/c #f path-string?) #f]
                       [use-dir? ((and/c path? complete-path?) . -> . any/c)
                                 (lambda (dir-path) #t)])
         sequence?]{
  返回一个产生 @racket[dir] 内文件、目录和链接的所有路径的 sequence，
  但 @racket[use-dir?] 返回 @racket[#f] 的目录的内容除外。
  如果 @racket[dir] 不是 @racket[#f]，则每个产生的路径都以 @racket[dir] 作为前缀。
  如果 @racket[dir] 是 @racket[#f]，则产生当前目录中和相对于当前目录的路径。

  @racket[in-directory] sequence 递归遍历嵌套子目录（由 @racket[use-dir?] 过滤）。
  要生成仅包含目录的直接内容的 sequence，请使用 @racket[directory-list] 的结果作为 sequence。

  每个目录的直接内容按 @racket[path<?] 排序报告，并且子目录的内容在目录中后续路径之前报告。

  @examples[
    (eval:alts (current-directory (collection-path "info"))
               (void))
    (eval:alts (for/list ([f (in-directory)])
                  f)
               (map string->path '("compiled"
                                   "compiled/main_rkt.dep"
                                   "compiled/main_rkt.zo"
                                   "main.rkt")))
    (eval:alts (for/list ([f (in-directory "compiled")])
                 f)
               (map string->path '("main_rkt.dep"
                                   "main_rkt.zo")))
    (eval:alts (for/list ([f (in-directory "compiled")])
                 f)
               (map string->path '("compiled/main_rkt.dep"
                                   "compiled/main_rkt.zo")))
    (eval:alts (for/list ([f (in-directory #f (lambda (p)
                                                (not (regexp-match? #rx"compiled" p))))])
                  f)
               (map string->path '("main.rkt" "compiled")))
  ]

@history[#:changed "6.0.0.1" @elem{添加了 @racket[use-dir?] 参数。}
         #:changed "6.6.0.4" @elem{添加了排序结果的保证。}]}


@defproc*[([(in-producer [producer procedure?])
            sequence?]
           [(in-producer [producer procedure?] [stop any/c] [arg any/c] ...)
            sequence?])]{
  返回一个包含对 @racket[producer] 连续调用产生的值的 sequence，@racket[producer] 通常使用某些状态来完成其工作。

  如果未给定 @racket[stop] 值，sequence 将无限继续，因此通常将其与有限 sequence 一起使用或使用 @racket[#:break] 等。
  如果给定了 @racket[stop] 值，则用于标识标记 sequence 结束的值（且 @racket[stop] 值不包含在 sequence 中）；
  @racket[stop] 可以是应用于 @racket[producer] 结果的谓词，也可以是与结果用 @racket[eq?] 测试的值。
  （如果停止值本身是一个函数或 @racket[producer] 返回多个值，则 @racket[stop] 参数必须是谓词。）

  如果指定了额外的 @racket[arg]，它们会传递给每次对 @racket[producer] 的调用。

  @examples[
    (define (counter)
      (define n 0)
      (lambda ([d 1]) (set! n (+ d n)) n))
    (for/list ([x (in-producer (counter))] [y (in-range 4)]) x)
    (for/list ([x (in-producer (counter))] #:break (= x 5)) x)
    (for/list ([x (in-producer (counter) 5)]) x)
    (for/list ([x (in-producer (counter) 5 1/2)]) x)
    (for/list ([x (in-producer read eof (open-input-string "1 2 3"))]) x)]
}

@defproc[(in-value [v any/c]) sequence?]{
  返回一个产生单个值的 sequence：@racket[v]。

  此形式主要用于 @racket[for*/list] 等形式中的 @racket[let] 类绑定——但更近期添加的 @racket[#:do] 子句形式覆盖了许多相同的用途。
}

@defproc[(in-indexed [seq sequence?]) sequence?]{
  返回一个 sequence，其中每个元素有两个值：@racket[seq] 产生的值，以及从 @racket[0] 开始的非负精确整数。
  @racket[seq] 的元素必须是单值的。
  
  @(examples
    #:eval sequence-evaluator
    (for ([(ch i) (in-indexed "hello")])
      (printf "The char at position ~a is: ~a\n" i ch)))
}

@defproc[(in-sequences [seq sequence?] ...) sequence?]{
  返回一个由所有输入 sequences 组成的 sequence，一个接一个。
  每个 @racket[seq] 只在前一个 @racket[seq] 耗尽后才被 @tech{initiate}。
  如果只提供了一个 @racket[seq]，则返回 @racket[seq]；否则，每个 @racket[seq] 的元素必须都具有相同数量的值。}

@defproc[(in-cycle [seq sequence?] ...) sequence?]{
  类似于 @racket[in-sequences]，但 sequences 在无限循环中重复，其中每个 @racket[seq] 在每次迭代中都被重新 @tech{initiate}。
  注意，如果未提供 @racket[seq] 或所有 @racket[seq] 都变为空，则 @racket[in-cycle] 产生的 sequence 在需要元素时永远不会返回——
  或者如果所有 @racket[seq] 最初都为空，则在 sequence 被 @tech{initiate} 时也不会返回。}

@defproc[(in-parallel [seq sequence?] ...) sequence?]{
  返回一个 sequence，其中每个元素具有与提供的 @racket[seq] 数量相同的值；
  这些值按顺序是每个 @racket[seq] 的值。每个 @racket[seq] 的元素必须是单值的。}

@defproc[(in-values-sequence [seq sequence?]) sequence?]{
  返回一个类似于 @racket[seq] 的 sequence，但它将 @racket[seq] 每个元素的多个值组合为元素列表。}

@defproc[(in-values*-sequence [seq sequence?]) sequence?]{
  返回一个类似于 @racket[seq] 的 sequence，但当 @racket[seq] 的元素具有多个值或单个列表值时，
  这些值被组合在列表中。换句话说，@racket[in-values*-sequence] 类似于 @racket[in-values-sequence]，
  不同之处在于非列表的单值元素不会被包装在列表中。
}

@defproc[(stop-before [seq sequence?] [pred (any/c . -> . any)])
         sequence?]{
  返回一个包含 @racket[seq] 元素的 sequence（必须是单值的），
  但仅直到将 @racket[pred] 应用于元素产生 @racket[#t] 的最后一个元素为止，
  之后 sequence 结束。
}

@defproc[(stop-after [seq sequence?] [pred (any/c . -> . any)])
         sequence?]{
  返回一个包含 @racket[seq] 元素的 sequence（必须是单值的），
  但仅直到将 @racket[pred] 应用于元素产生 @racket[#t] 的元素（含），
  之后 sequence 结束。
}

@defproc[(make-do-sequence
          [thunk (or/c (-> (values (any/c . -> . any)
                                   (any/c . -> . any/c)
                                   any/c
                                   (or/c (any/c . -> . any/c) #f)
                                   (or/c (() () #:rest list? . ->* . any/c) #f)
                                   (or/c ((any/c) () #:rest list? . ->* . any/c) #f)))
                       (-> (values (any/c . -> . any)
                                   (or/c (any/c . -> . any/c) #f)
                                   (any/c . -> . any/c)
                                   any/c
                                   (or/c (any/c . -> . any/c) #f)
                                   (or/c (() () #:rest list? . ->* . any/c) #f)
                                   (or/c ((any/c) () #:rest list? . ->* . any/c) #f))))])
         sequence?]{
  返回一个 sequence，其元素由 thunk 返回的过程和初始值生成，thunk 被调用以 @tech{initiate} 该 sequence。
  已启动的 sequence 由 @defterm{position} 定义，它被初始化为 thunk 的第三个结果，
  以及 @defterm{element}，它可能由多个值组成。

  @racket[thunk] 结果定义生成的元素如下：
  @itemize[
    @item{第一个结果是 @racket[_pos->element] 过程，它接受当前位置并返回当前元素的值。}
    @item{可选的第二个结果是 @racket[_early-next-pos] 过程，进一步描述如下。
      或者，可选的第二个结果可以是 @racket[#f]，等价于恒等函数。}
    @item{第三个（或第二个）结果是 @racket[_next-pos] 过程，它接受当前位置并返回下一个位置。}
    @item{第四个（或第三个）结果是初始位置。}
    @item{第五个（或第四个）结果是 @racket[_continue-with-pos?] 函数，它接受当前位置，
      如果 sequence 包含当前位置的值则返回真结果，如果 sequence 应该结束而不是包含值则返回假。
      或者，第五个（或第四个）结果可以是 @racket[#f] 表示 sequence 应该始终包含当前值。
      此函数在使用 @racket[_pos->element] 之前对每个位置进行检查。}
    @item{第六个（或第五个）结果是 @racket[_continue-with-val?] 函数，类似于第五个（或第四个）结果，
      但它接受当前元素值而不是当前位置。或者，第六个（或第五个）结果可以是 @racket[#f]
      表示 sequence 应该始终包含当前位置的值。}
    @item{第七个（或第六个）结果是 @racket[_continue-after-pos+val?] 过程，
      它同时接受当前位置和当前元素值，并确定在当前元素已包含在 sequence 中后 sequence 是否结束。
      或者，第七个（或第六个）结果可以是 @racket[#f] 表示 sequence 在当前元素后总是可以继续。}]

  @racket[_early-next-pos] 过程（可选的第二个结果）接受当前位置并返回更新后的位置。
  此更新后的位置用于 @racket[_next-pos] 和 @racket[_continue-after-pos+val?]，
  但不用于 @racket[_continue-with-pos?]（它使用原始当前位置）。
  @racket[_early-next-pos] 的意图是支持一种 sequence，其中位置必须递增以避免在循环处理 sequence 值时
  保持值可达，因此 @racket[_early-next-pos] 在 @racket[_pos->element] 之后立即应用。

  上面列出的每个过程每个位置只调用一次。在最后三个过程中，一旦其中一个过程返回 @racket[#f]，
  sequence 就结束，且不再调用任何过程。通常，其中一个函数确定结束条件，
  而 @racket[#f] 用于代替其他两个函数。

@history[#:changed "6.7.0.4" @elem{添加了对可选第二个结果的支持。}]}


@defthing[prop:sequence struct-type-property?]{

  将一个过程关联到结构体类型，该过程接受结构体的实例并返回一个 sequence。
  如果 @racket[v] 是具有此属性的结构体类型的实例，则 @racket[(sequence? v)] 产生 @racket[#t]。

  使用预先存在的 sequence：

  @examples[
    (struct my-set (table)
      #:property prop:sequence
      (lambda (s)
        (in-hash-keys (my-set-table s))))
    (define (make-set . xs)
      (my-set (for/hash ([x (in-list xs)])
                (values x #t))))
    (for/list ([c (make-set 'celeriac 'carrot 'potato)])
      c)]

  使用 @racket[make-do-sequence]：

  @let-syntax[([car (make-element-id-transformer
                     (lambda (id) #'@racketidfont{car}))])
    @examples[
      (struct train (car next)
        #:property prop:sequence
        (lambda (t)
          (make-do-sequence
           (lambda ()
             (values train-car train-next t
                     (lambda (t) t)
                     (lambda (v) #t)
                     (lambda (t v) #t))))))
      (for/list ([c (train 'engine
                           (train 'boxcar
                                  (train 'caboose
                                         #f)))])
        c)]]}

@; ----------------------------------------------------------------------
@subsection{Sequence 转换}

@defproc[(sequence->stream [seq sequence?]) stream?]{
  将 sequence 转换为 @tech{stream}，支持 @racket[stream-first] 和 @racket[stream-rest] 操作。
  创建 stream 会立即 @tech{initiate} 该 sequence，但 stream 延迟地从 sequence 中提取元素，
  缓存每个元素使得 @racket[stream-first] 每次应用于 stream 时产生相同的结果。

  如果从 @racket[seq] 提取元素涉及副作用，则每次首次使用 @racket[stream-first] 或
  @racket[stream-rest] 访问或跳过元素时都会执行该副作用。

  注意 @elemref["sequence-state"]{sequence 本身可以有状态}，因此对同一个 @racket[seq]
  的多次 @racket[sequence->stream] 调用不一定独立。

  @examples[
  #:eval sequence-evaluator
  (define inport (open-input-bytes (bytes 1 2 3 4 5)))
  (define strm (sequence->stream inport))
  (stream-first strm)
  (stream-first (stream-rest strm))
  (stream-first strm)

  (define strm2 (sequence->stream inport))
  (stream-first strm2)
  (stream-first (stream-rest strm2))
 ]}

@defproc[(sequence-generate [seq sequence?])
         (values (-> boolean?) (-> any))]{
  @tech{Initiate} 一个 sequence 并返回两个 thunk 以从 sequence 中提取元素。
  如果 sequence 有更多可用值，第一个返回 @racket[#t]。
  第二个返回 sequence 的下一个元素（可能是多个值）；如果没有更多可用元素，
  则 @exnraise[exn:fail:contract]。

  注意 @elemref["sequence-state"]{sequence 本身可以有状态}，因此对同一个 @racket[seq]
  的多次 @racket[sequence-generate] 调用不一定独立。

  @examples[
  #:eval sequence-evaluator
  (define inport (open-input-bytes (bytes 1 2 3 4 5)))
  (define-values (more? get) (sequence-generate inport))
  (more?)
  (get)
  (get)

  (define-values (more2? get2) (sequence-generate inport))
  (list (get2) (get2) (get2))
  (more2?)
 ]}

@defproc[(sequence-generate* [seq sequence?])
         (values (or/c list? #f)
                 (-> (values (or/c list? #f) procedure?)))]{
  类似于 @racket[sequence-generate]，但通过返回 sequence 第一个元素的值列表
  （如果 sequence 为空则返回 @racket[#f]）以及继续该 sequence 的 thunk 来避免状态
  （除了 sequence 中固有的任何状态）；thunk 的结果与 @racket[sequence-generate*] 的结果相同，
  但针对 sequence 的第二个元素，依此类推。如果在元素结果为 @racket[#f]（表示 sequence 中没有更多值）
  时调用 thunk，则 @exnraise[exn:fail:contract]。}

@; ----------------------------------------------------------------------
@subsection[#:tag "more-sequences"]{其他 Sequence 操作}

@note-lib[racket/sequence]

@defthing[empty-sequence sequence?]{
  一个没有元素的 sequence。}

@defproc[(sequence->list [s sequence?]) list?]{
  返回一个列表，其元素是 @racket[s] 的元素，每个元素必须是单个值。
  如果 @racket[s] 是无限的，此函数不会终止。}

@defproc[(sequence-length [s sequence?])
         exact-nonnegative-integer?]{
  通过提取并丢弃所有元素来返回 @racket[s] 的元素数量。
  如果 @racket[s] 是无限的，此函数不会终止。}

@defproc[(sequence-ref [s sequence?] [i exact-nonnegative-integer?])
         any]{
  返回 @racket[s] 的第 @racket[i] 个元素（可能是多个值）。}

@defproc[(sequence-tail [s sequence?] [i exact-nonnegative-integer?])
         sequence?]{
  返回一个等价于 @racket[s] 的 sequence，但省略了前 @racket[i] 个元素。

  如果 @tech[#:key "initiate"]{initiating} @racket[s] 涉及副作用，
  则 sequence @racket[s] 直到结果 sequence 被 @tech{initiate} 时才被 @tech{initiate}，
  此时前 @racket[i] 个元素从 sequence 中提取。
}

@defproc[(sequence-append [s sequence?] ...)
         sequence?]{
  返回一个包含每个 sequence 的所有元素的 sequence，按原始 sequence 中出现的顺序排列。
  新的 sequence 是延迟构造的。

  如果所有给定的 @racket[s] 都是 @tech{streams}，则结果也是一个 @tech{stream}。
}

@defproc[(sequence-map [f procedure?]
                       [s sequence?])
         sequence?]{
  返回一个包含将 @racket[f] 应用于 @racket[s] 每个元素的结果的 sequence。
  新的 sequence 是延迟构造的。

  如果 @racket[s] 是 @tech{stream}，则结果也是一个 @tech{stream}。
}

@defproc[(sequence-andmap [f (-> any/c ... boolean?)]
                          [s sequence?])
         boolean?]{
  如果 @racket[f] 对 @racket[s] 的每个元素都返回真结果，则返回 @racket[#t]。
  如果 @racket[s] 是无限的且 @racket[f] 从不返回假结果，此函数不会终止。
}

@defproc[(sequence-ormap [f (-> any/c ... boolean?)]
                         [s sequence?])
         boolean?]{
  如果 @racket[f] 对 @racket[s] 的某个元素返回真结果，则返回 @racket[#t]。
  如果 @racket[s] 是无限的且 @racket[f] 从不返回真结果，此函数不会终止。
}

@defproc[(sequence-for-each [f (-> any/c ... any)]
                            [s sequence?])
         void?]{
  将 @racket[f] 应用于 @racket[s] 的每个元素。如果 @racket[s] 是无限的，此函数不会终止。
}

@defproc[(sequence-fold [f (-> any/c any/c ... any/c)]
                        [i any/c]
                        [s sequence?])
         any/c]{
  以 @racket[i] 作为初始累加器，将 @racket[f] 折叠到 @racket[s] 的每个元素上。
  如果 @racket[s] 是无限的，此函数不会终止。@racket[f] 函数以累加器作为第一个参数，
  以下一个 sequence 元素作为第二个参数。
}

@defproc[(sequence-count [f procedure?] [s sequence?])
         exact-nonnegative-integer?]{
  返回 @racket[s] 中 @racket[f] 返回真结果的元素数量。
  如果 @racket[s] 是无限的，此函数不会终止。
}

@defproc[(sequence-filter [f (-> any/c ... boolean?)]
                          [s sequence?])
         sequence?]{
  返回一个元素为 @racket[s] 中 @racket[f] 返回真结果的元素的 sequence。
  虽然新的 sequence 是延迟构造的，但如果 @racket[s] 有无限多个元素，
  其中 @racket[f] 在两个返回真结果的元素之间返回假结果，则对这个 sequence 的操作
  在无限子 sequence 期间不会终止。

  如果 @racket[s] 是 @tech{stream}，则结果也是一个 @tech{stream}。
}

@defproc[(sequence-add-between [s sequence?] [e any/c])
         sequence?]{
  返回一个元素为 @racket[s] 的元素的 sequence，但在 @racket[s] 的每对元素之间插入 @racket[e]。
  新的 sequence 是延迟构造的。

  如果 @racket[s] 是 @tech{stream}，则结果也是一个 @tech{stream}。

  @examples[#:eval sequence-evaluator
    (let* ([all-reds (in-cycle '("red"))]
           [red-and-blues (sequence-add-between all-reds "blue")])
      (for/list ([n (in-range 10)]
                 [elt red-and-blues])
        elt))

    (for ([text (sequence-add-between '("veni" "vidi" "duci") ", ")])
      (display text))
    ]
}

@defproc[(sequence/c [#:min-count min-count (or/c #f exact-nonnegative-integer?) #f]
                     [elem/c contract?] ...)
         contract?]{

包装一个 @tech{sequence}，要求它产生与 @racket[elem/c] contracts 数量相同的值的元素，
并要求每个值满足对应的 @racket[elem/c]。结果不保证与原始值是同一种 sequence；
例如，包装的列表不保证满足 @racket[list?]。

如果 @racket[min-count] 是数字，则要求 stream 至少包含那么多元素。

@examples[
#:eval sequence-evaluator
(define/contract predicates
  (sequence/c (-> any/c boolean?))
  (in-list (list integer?
                 string->symbol)))
(eval:error
 (for ([P predicates])
   (printf "~s\n" (P "cat"))))
(define/contract numbers&strings
  (sequence/c number? string?)
  (in-dict (list (cons 1 "one")
                 (cons 2 "two")
                 (cons 3 'three))))
(eval:error
 (for ([(N S) numbers&strings])
   (printf "~s: ~a\n" N S)))
(define/contract a-sequence
  (sequence/c #:min-count 2 char?)
  "x")
(eval:error
 (for ([x a-sequence]
       [i (in-naturals)])
   (printf "~a is ~a\n" i x)))
]

}

@subsubsection{其他 Sequence 构造器}

@defproc[(in-syntax [stx syntax?]) sequence?]{
  产生一个元素为 @racket[stx] 的连续子部分的 sequence。
  等价于 @racket[(stx->list lst)]。
  @speed[in-syntax "syntax"]

@examples[#:eval sequence-evaluator
(for/list ([x (in-syntax #'(1 2 3))])
  x)]

@history[#:added "6.3"]}

@defproc[(in-slice [length exact-positive-integer?] [seq sequence?])
         sequence?]{
  返回一个元素为列表的 sequence，每个列表包含 @racket[seq] 的前 @racket[length] 个元素，
  然后是接下来的 @racket[length] 个元素，依此类推。

  @examples[#:eval sequence-evaluator
  (for/list ([e (in-slice 3 (in-range 8))]) e)
  ]
  @history[#:added "6.3"]
}


@; ======================================================================
@section[#:tag "streams"]{Streams}

@deftech{stream} 是一种 @tech{sequence}，通过 @racket[stream-first] 和 @racket[stream-rest]
支持函数式迭代。@racket[stream-cons] 形式构造一个惰性 stream，但普通列表可以用作 streams，
而 @racket[in-range] 和 @racket[in-naturals] 等函数也创建 streams。

@note-lib[racket/stream]

@defproc[(stream? [v any/c]) boolean?]{
  如果 @racket[v] 可以用作 @tech{stream} 则返回 @racket[#t]，否则返回 @racket[#f]。
}

@defproc[(stream-empty? [s stream?]) boolean?]{
  如果 @racket[s] 没有元素则返回 @racket[#t]，否则返回 @racket[#f]。
}

@defproc[(stream-first [s (and/c stream? (not/c stream-empty?))]) any]{
  返回 @racket[s] 中第一个元素的值。}

@defproc[(stream-rest [s (and/c stream? (not/c stream-empty?))]) stream?]{
  返回一个等价于 @racket[s] 但不包含第一个元素的 stream。}

@defform*[[(stream-cons first-expr rest-expr)
           (stream-cons #:eager first-expr rest-expr)
           (stream-cons first-expr #:eager rest-expr)
           (stream-cons #:eager first-expr #:eager rest-expr)]]{

  产生一个 stream，其第一个元素由 @racket[first-expr] 确定，其余部分由 @racket[rest-expr] 确定。

  如果 @racket[first-expr] 前面没有 @racket[#:eager]，则 @racket[first-expr] 不会立即求值。
  相反，对结果 stream 的 @racket[stream-first] 会强制对 @racket[first-expr] 求值（一次）
  以产生 stream 的第一个元素。如果求值 @racket[first-expr] 引发异常或尝试强制自身，
  则 @exnraise[exn:fail:contract]，并且未来的强制求值尝试将触发另一个异常。

  如果 @racket[rest-expr] 前面没有 @racket[#:eager]，则 @racket[rest-expr] 不会立即求值。
  相反，对结果 stream 的 @racket[stream-rest] 产生另一个 stream，
  类似于 @racket[(stream-lazy rest-expr)] 产生的 stream。

  由 @racket[first-expr] 产生的 stream 的第一个元素必须是单个值。
  @racket[rest-expr] 在求值时必须产生一个 stream，否则 @exnraise[exn:fail:contract?]。

  @history[#:changed "8.0.0.12" @elem{添加了 @racket[#:eager] 选项。}]}

@defform*[[(stream-lazy stream-expr)
           (stream-lazy #:who who-expr stream-expr)]]{

 类似于 @racket[(delay stream-expr)]，但结果是 stream 而不是 @tech{promise}，
 并且 @racket[stream-expr] 在最终被强制时必须产生一个 stream。
 @racket[stream-lazy] 产生的 stream 与 @racket[stream-expr] 产生的 stream 具有相同的内容；
 也就是说，对结果 stream 的 @racket[stream-first] 等操作将强制 @racket[stream-expr] 并对其结果重试。

 如果求值 @racket[stream-expr] 引发异常或尝试强制自身，则 @exnraise[exn:fail:contract]，
 并且未来的强制求值尝试将触发另一个异常。

 如果提供了 @racket[who-expr]，它在构造延迟 stream 时被求值。
 如果 @racket[stream-expr] 后来产生了一个不是 stream 的值，并且 @racket[who-expr] 产生了符号值，
 则该符号用于错误消息。

 @history[#:added "8.0.0.12"]}

@defproc[(stream-force [s stream?]) stream?]{

 强制求值来自 @racket[stream-lazy]、@racket[stream-cons] 的 @racket[stream-rest] 等的延迟 stream，
 返回强制后的 stream。如果 @racket[s] 不是延迟 stream，则返回 @racket[s]。

 通常不需要 @racket[stream-force]，因为 @racket[stream-first]、@racket[stream-rest]
 和 @racket[stream-empty?] 等操作会根据需要强制延迟 stream。
 在少数情况下，@racket[stream-force] 可用于揭示 stream 的底层实现
 （例如，作为具有 @racket[prop:stream] 属性的结构体类型的实例的 stream）。

 @history[#:added "8.0.0.12"]}

@defform[(stream e ...)]{
  嵌套 @racket[stream-cons] 并以 @racket[empty-stream] 结尾的简写。
  作为匹配模式，@racket[stream] 匹配具有与 @racket[e] 数量相同元素的 stream，
  每个元素必须匹配对应的 @racket[e] 模式。}

@defform[(stream* e ... tail)]{
  嵌套 @racket[stream-cons] 的简写，但 @racket[tail] 在被强制时必须产生一个 stream，
  该 stream 用作 stream 的其余部分而不是 @racket[empty-stream]。
  类似于 @racket[list*] 但用于 streams。
  作为匹配模式，@racket[stream*] 类似于 @racket[stream] 模式，
  但 @racket[tail] 模式匹配最后一个 @racket[e] 之后 stream 的"其余部分"。

@history[#:added "6.3"
         #:changed "8.0.0.12" @elem{即使未提供 @racket[expr]，也更改为延迟 @racket[rest-expr]。}]}

@defproc[(in-stream [s stream?]) sequence?]{
  返回一个等价于 @racket[s] 的 sequence。
  @speed[in-stream "streams"]
  @for-element-reachability["stream"]

@history[#:changed "6.7.0.4" @elem{改进了 @racket[for] 中 streams 的元素可达性保证。}]}

@defthing[empty-stream stream?]{
  一个没有元素的 stream。
}

@defproc[(stream->list [s stream?]) list?]{
  返回一个列表，其元素是 @racket[s] 的元素，每个元素必须是单个值。
  如果 @racket[s] 是无限的，此函数不会终止。}

@defproc[(stream-length [s stream?])
         exact-nonnegative-integer?]{
  返回 @racket[s] 的元素数量。如果 @racket[s] 是无限的，此函数不会终止。

  对于惰性 streams，此函数仅强制求值子 streams，而不强制求值 stream 的元素。
}

@defproc[(stream-ref [s stream?] [i exact-nonnegative-integer?])
         any]{
  返回 @racket[s] 的第 @racket[i] 个元素（可能是多个值）。}

@defproc[(stream-tail [s stream?] [i exact-nonnegative-integer?])
         stream?]{
  返回一个等价于 @racket[s] 的 stream，但省略了前 @racket[i] 个元素。

  如果从 @racket[s] 提取元素涉及副作用，则直到从结果 stream 提取第一个元素时才会提取它们。
}

@defproc[(stream-take [s stream?] [i exact-nonnegative-integer?])
         stream?]{
  返回 @racket[s] 的前 @racket[i] 个元素的 stream。}

@defproc[(stream-append [s stream?] ...)
         stream?]{
  返回一个包含每个 stream 的所有元素的 stream，按原始 stream 中出现的顺序排列。
  新的 stream 是延迟构造的，同时最后一个给定的 stream 用于结果的尾部。
}

@defproc[(stream-map [f procedure?]
                     [s stream?])
         stream?]{
  返回一个包含将 @racket[f] 应用于 @racket[s] 每个元素的结果的 stream。
  新的 stream 是延迟构造的。}

@defproc[(stream-andmap [f (-> any/c ... boolean?)]
                        [s stream?])
         boolean?]{
  如果 @racket[f] 对 @racket[s] 的每个元素都返回真结果，则返回 @racket[#t]。
  如果 @racket[s] 是无限的且 @racket[f] 从不返回假结果，此函数不会终止。
}

@defproc[(stream-ormap [f (-> any/c ... boolean?)]
                       [s stream?])
         boolean?]{
  如果 @racket[f] 对 @racket[s] 的某个元素返回真结果，则返回 @racket[#t]。
  如果 @racket[s] 是无限的且 @racket[f] 从不返回真结果，此函数不会终止。
}

@defproc[(stream-for-each [f (-> any/c ... any)]
                          [s stream?])
         void?]{
  将 @racket[f] 应用于 @racket[s] 的每个元素。如果 @racket[s] 是无限的，此函数不会终止。
}

@defproc[(stream-fold [f (-> any/c any/c ... any/c)]
                      [i any/c]
                      [s stream?])
         any/c]{
  以 @racket[i] 作为初始累加器，将 @racket[f] 折叠到 @racket[s] 的每个元素上。
  如果 @racket[s] 是无限的，此函数不会终止。@racket[f] 函数以累加器作为第一个参数，
  以下一个 stream 元素作为第二个参数。}

@defproc[(stream-count [f procedure?] [s stream?])
         exact-nonnegative-integer?]{
  返回 @racket[s] 中 @racket[f] 返回真结果的元素数量。
  如果 @racket[s] 是无限的，此函数不会终止。}

@defproc[(stream-filter [f (-> any/c ... boolean?)]
                          [s stream?])
         stream?]{
  返回一个元素为 @racket[s] 中 @racket[f] 返回真结果的元素的 stream。
  虽然新的 stream 是延迟构造的，但如果 @racket[s] 有无限多个元素，
  其中 @racket[f] 在两个返回真结果的元素之间返回假结果，则对这个 stream 的操作
  在无限子 stream 期间不会终止。}

@defproc[(stream-add-between [s stream?] [e any/c])
         stream?]{
  返回一个元素为 @racket[s] 的元素的 stream，但在 @racket[s] 的每对元素之间插入 @racket[e]。
  新的 stream 是延迟构造的。}

@deftogether[(@defform[(for/stream (for-clause ...) body-or-break ... body)]
              @defform[(for*/stream (for-clause ...) body-or-break ... body)])]{
  分别类似于 @racket[for/list] 和 @racket[for*/list] 进行迭代，但结果被延迟收集为 @tech{stream} 而不是列表。

  与大多数 @racket[for] 形式不同，这些形式是延迟求值的，因此每个 @racket[body] 直到结果 stream 被强制时才会求值。
  这允许 @racket[for/stream] 和 @racket[for*/stream] 遍历无限 sequences，与它们的有限对应物不同。

  请注意，这些形式不支持返回 @tech{multiple values}。

  @examples[#:eval sequence-evaluator
    (for/stream ([i '(1 2 3)]) (* i i))
    (stream->list (for/stream ([i '(1 2 3)]) (* i i)))
    (stream-ref (for/stream ([i '(1 2 3)]) (displayln i) (* i i)) 1)
    (stream-ref (for/stream ([i (in-naturals)]) (* i i)) 25)
  ]

  @history[#:added "6.3.0.9"]
}

@defthing[gen:stream any/c]{
  将三个方法关联到结构体类型以实现 streams 的 @tech{泛型接口}（见 @secref["struct-generics"]）。

  要提供方法实现，应在结构体类型定义中使用 @racket[#:methods] 关键字。
  应实现以下三个方法：

  @itemize[
    @item{@racket[stream-empty?]：接受一个参数}
    @item{@racket[stream-first]：接受一个参数}
    @item{@racket[stream-rest]：接受一个参数}
  ]

  @examples[#:eval sequence-evaluator
    (struct list-stream (v)
      #:methods gen:stream
      [(define (stream-empty? stream)
         (empty? (list-stream-v stream)))
       (define (stream-first stream)
         (first (list-stream-v stream)))
       (define (stream-rest stream)
         (list-stream (rest (list-stream-v stream))))])

    (define l1 (list-stream '(1 2)))
    (stream? l1)
    (stream-first l1)
  ]
}

@defthing[prop:stream struct-type-property?]{
  用于定义 stream API 的自定义扩展的结构体类型属性。
  不建议使用 @racket[prop:stream] 属性；请改用 @racket[gen:stream] @tech{泛型接口}。
  接受一个包含三个过程的向量，这些过程接受与 @racket[gen:stream] 中方法相同的参数。}

@defproc[(stream/c [c contract?]) contract?]{
返回一个识别 streams 的 contract。stream 的所有元素必须匹配 @racket[c]。

如果 @racket[c] 参数是 flat contract 或 chaperone contract，则结果将是 chaperone contract。
否则，结果将是 impersonator contract。

当 @racket[stream/c] contract 应用于 stream 时，结果不与输入 @racket[eq?]。
根据 contract 类型，结果将是输入的 @tech{chaperone} 或 @tech{impersonator}。

对 streams 的 contracts 必须延迟求值（因为 streams 可能是无限的）。
contract 违规直到从 stream 中检索到违规值时才会引发。
作为此规则的例外，作为列表的 streams 会立即检查，就像 @racket[c] 已与 @racket[listof] 一起使用。

如果 contract 应用于 stream，并且该 stream 随后用作另一个 stream 的尾部
（作为 @racket[stream-cons] 的第二个参数），则新元素不会用 contract 检查，
但尾部的元素仍会被强制执行。

@history[#:added "6.1.1.8"]}

@close-eval[sequence-evaluator]

@; ======================================================================
@section{Generators}

@deftech{generator} 是一个返回值序列的过程，每次调用 generator 时递增序列。
具体来说，@racket[generator] 形式通过求值调用 @racket[yield] 以从 generator 返回值的主体来实现 generator。

@defmodule[racket/generator]

@(define generator-eval
   (let ([the-eval (make-base-eval)])
     (the-eval '(require racket/generator))
     the-eval))

@defproc[(generator? [v any/c]) boolean?]{
  如果 @racket[v] 是 @tech{generator} 则返回 @racket[#t]，否则返回 @racket[#f]。}

@defform/subs[(generator formals body ...+)
              ([formals (id ...)
                        (id ...+ . rest-id)
                        rest-id])]{
  创建一个 @tech{generator}，其中 @racket[formals] 指定参数。
  不支持关键字和可选参数。这与单个 @racket[case-lambda] 子句的 @racket[formals] 相同。

  对于 generator 的第一次调用，参数绑定到 @racket[formals] 并开始求值 @racket[body]。
  在 @racket[body] 的 @tech{dynamic extent} 期间，generator 可以使用 @racket[yield] 函数立即返回。
  对 generator 的第二次调用在 @racket[yield] 调用处恢复，将第二次调用的参数作为 @racket[yield] 的结果，
  依此类推。@racket[body] 的最终结果提供给隐式的最终 @racket[yield]；在该最终 @racket[yield] 之后，
  再次调用 generator 返回相同的值，但所有此类调用必须向 generator 提供 0 个参数。

  @examples[#:eval generator-eval
    (define g (generator ()
                (let loop ([x '(a b c)])
                  (if (null? x)
                      0
                      (begin
                        (yield (car x))
                        (loop (cdr x)))))))
    (g)
    (g)
    (g)
    (g)
    (g)]}

@defproc[(yield [v any/c] ...) any]{
  从 generator 返回 @racket[v]，保存 generator 内部的执行点
  （即在 @racket[generator] 主体的 @tech{dynamic extent} 内）以便下次调用 generator 时恢复。
  @racket[yield] 的结果是提供给 generator 下次调用的参数。

  当不在 @racket[generator]、@racket[infinite-generator] 或 @racket[in-generator] 主体的
  @tech{dynamic extent} 内时，@racket[yield] 在求值其 @racket[expr] 后引发 @racket[exn:fail]。

  @examples[#:eval generator-eval
    (define my-generator (generator () (yield 1) (yield 2 3 4)))
    (my-generator)
    (my-generator)]

  @examples[#:eval generator-eval
    (define pass-values-generator
      (generator ()
        (let* ([from-user (yield 2)]
               [from-user-again (yield (add1 from-user))])
          (yield from-user-again))))

    (pass-values-generator)
    (pass-values-generator 5)
    (pass-values-generator 12)]}

@defform[(infinite-generator body ...+)]{
  类似于 @racket[generator]，但当最后一个 @racket[body] 完成而未隐式 @racket[yield] 时，
  重复求值 @racket[body]。

  @examples[#:eval generator-eval
    (define welcome
      (infinite-generator
        (yield 'hello)
        (yield 'goodbye)))
    (welcome)
    (welcome)
    (welcome)
    (welcome)]}

@defform/subs[(in-generator maybe-arity body ...+)
              ([maybe-arity code:blank
                            (code:line #:arity arity-k)])]{
  产生一个封装了由 @racket[(generator () body ...+)] 形成的 @tech{generator} 的 @tech{sequence}。
  generator 产生的值构成 sequence 的元素，但 generator 产生的最后一个值（即返回产生的值）除外。

  @examples[#:eval generator-eval
    (for/list ([i (in-generator
                    (let loop ([x '(a b c)])
                      (when (not (null? x))
                        (yield (car x))
                        (loop (cdr x)))))])
      i)]

  如果 @racket[in-generator] 立即与 @racket[for]（或 @racket[for/list] 等）绑定的右侧一起使用，
  则其结果 arity（即 sequence 每个元素中的值数量）可以被推断。
  否则，如果 generator 为每个元素产生多个值，应使用 @racket[#:arity arity-k] 子句声明其 arity；
  @racket[arity-k] 必须是字面量、精确、非负整数。

  @examples[#:eval generator-eval
    (eval:error
     (let ([g (in-generator
               (let loop ([n 3])
                 (unless (zero? n) (yield n (add1 n)) (loop (sub1 n)))))])
       (let-values ([(not-empty? next) (sequence-generate g)])
         (let loop () (when (not-empty?) (next) (loop))) 'done)))
    (let ([g (in-generator #:arity 2
              (let loop ([n 3])
                (unless (zero? n) (yield n (add1 n)) (loop (sub1 n)))))])
      (let-values ([(not-empty? next) (sequence-generate g)])
        (let loop () (when (not-empty?) (next) (loop))) 'done))]

  要使用现有的 generator 作为 sequence，请使用 @racket[in-producer] 并为 generator 已知的停止值：

  @examples[#:label #f #:eval generator-eval
    (define abc-generator (generator ()
                           (for ([x '(a b c)])
                              (yield x))))
    (for/list ([i (in-producer abc-generator (void))])
      i)
    (define my-stop-value (gensym))
    (define my-generator (generator ()
                           (let loop ([x (list 'a (void) 'c)])
                             (if (null? x)
                                 my-stop-value
                                 (begin
                                   (yield (car x))
                                   (loop (cdr x)))))))
    (for/list ([i (in-producer my-generator my-stop-value)])
      i)]
}


@defproc[(generator-state [g generator?]) symbol?]{
  返回描述 generator 状态的符号。

  @itemize[
    @item{@racket['fresh] --- generator 刚刚创建，尚未被调用。}
    @item{@racket['suspended] --- generator 内部的控制由于调用 @racket[yield] 而被挂起。
          generator 可以被调用。}
    @item{@racket['running] --- generator 当前正在执行。}
    @item{@racket['done] --- generator 已执行其整个主体，并将继续产生与上次调用相同的结果。}]

  @examples[#:eval generator-eval
    (define my-generator (generator () (yield 1) (yield 2)))
    (generator-state my-generator)
    (my-generator)
    (generator-state my-generator)
    (my-generator)
    (generator-state my-generator)
    (my-generator)
    (generator-state my-generator)

    (define introspective-generator (generator () ((yield 1))))
    (introspective-generator)
    (introspective-generator
     (lambda () (generator-state introspective-generator)))
    (generator-state introspective-generator)
    (introspective-generator)]}

@defproc[(sequence->generator [s sequence?]) (-> any)]{
  将 @tech{sequence} 转换为 @tech{generator}。generator 每次被调用时返回 sequence 的下一个元素，
  其中 sequence 的每个元素必须是单个值。当 sequence 结束时，generator 返回 @|void-const| 作为其最终结果。}

@defproc[(sequence->repeated-generator [s sequence?]) (-> any)]{
  类似于 @racket[sequence->generator]，但当 @racket[s] 没有更多值时，
  generator 重新开始该 sequence（因此 generator 永远不会停止产生值）。}

@close-eval[generator-eval]
