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

@title[#:style 'toc #:tag "sequences+streams"]{序列与流}

@tech{序列}和@tech{流}抽象了集合中元素的迭代。序列支持通过@racket[for]宏或诸如@racket[sequence-map]之类的序列操作进行迭代。
流是函数式序列，既可以通过通用方式使用，也可以通过特定于流的方式使用。@tech{生成器}是紧密相关的有状态对象，可以转换为序列，反之亦然。

@local-table-of-contents[]

@; ======================================================================
@section[#:tag "sequences"]{序列}

@(define sequence-evaluator
   (let ([evaluator (make-base-eval)])
     (evaluator '(require racket/generic racket/list racket/stream racket/sequence
                          racket/contract racket/dict))
     evaluator))

@guideintro["sequences"]{sequences}

@deftech{序列}封装了一个有序的值集合。序列的元素可以通过@racket[for]语法形式、
@racket[sequence-generate]返回的过程或通过将序列转换为@tech{流}来提取。

序列数据类型与许多其他数据类型有重叠。在内置数据类型中，序列数据类型包括以下内容：

@itemize[

 @item{exact nonnegative integers (see below)}

 @item{strings (see @secref["strings"])}

 @item{byte strings (see @secref["bytestrings"])}

 @item{lists (see @secref["pairs"])}

 @item{mutable lists (see @secref["mpairs"])}

 @item{vectors (see @secref["vectors"])}

 @item{flvectors (see @secref["flvectors"])}

 @item{fxvectors (see @secref["fxvectors"])}

 @item{hash tables (see @secref["hashtables"])}

 @item{dictionaries (see @secref["dicts"])}

 @item{sets (see @secref["sets"])}

 @item{input ports (see @secref["ports"])}

 @item{streams (see @secref["streams"])}

]

作为非负@tech{integer}的@tech{exact number} @racket[_k]充当类似于@racket[(in-range _k)]的序列，
不同之处在于@racket[_k]本身不是一个@tech{stream}。

可以使用结构类型属性定义自定义序列。定义自定义序列的最简单方法是使用@racket[gen:stream] @tech{generic interface}。
流是对可直接迭代的数据结构的一种合适的抽象。例如，列表可以通过@racket[first]和@racket[rest]直接迭代。
另一方面，向量不能直接迭代：迭代必须通过索引进行。对于不能直接迭代的数据结构，可以将数据结构的@deftech{iterator}定义为流
（例如，包含向量索引的结构）。

例如，展开的链表（表示为向量的列表）本身不符合流抽象，但具有可以表示为流的基于索引的迭代器：

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

@racket[prop:sequence]属性在指定迭代方面提供了更大的灵活性，例如当需要预处理步骤来准备迭代数据时。
@racket[make-do-sequence]函数根据给定的thunk（返回实现序列的过程）来创建序列，
而@racket[prop:sequence]属性可以与结构类型关联，以实现其隐式转换为序列。

对于大多数序列类型，从序列中提取元素不会对原始序列值产生副作用；例如，从列表中提取元素序列不会改变列表。
对于其他序列类型，每次提取都意味着副作用；例如，从端口提取字节序列会导致从端口读取字节。
@elemtag["sequence-state"]{序列}的状态可能跨越该序列的所有使用（如端口），也可能仅限于每次通过@racket[for]形式、
@racket[sequence->stream]、@racket[sequence-generate]或@racket[sequence-generate*] @deftech{initiate}该序列的独立时刻。
具体来说，传递给@racket[make-do-sequence]的thunk在每次使用序列时被调用来@tech{initiate}该序列。
因此，不同的序列在被多次@tech{initiate}时行为不同。

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

此外，序列中的后续元素可能仅通过调用@racket[sequence-generate]的第一个结果就被"消费"了，即使第二个结果从未被调用。

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

在此示例中，第一次调用@racket[sequence-generate]中嵌入的状态仅通过调用@racket[_more?.1]就"获取"了@racket[98]。

序列的单个元素通常对应单个值，但一个元素也可能对应多个值。例如，哈希表为序列中的每个元素生成两个值——一个键和它的值。

@; ----------------------------------------------------------------------
@subsection{序列谓词与构造函数}

@defproc[(sequence? [v any/c]) boolean?]{
  如果@racket[v]可以用作@tech{sequence}，则返回@racket[#t]，否则返回@racket[#f]。

@examples[#:eval sequence-evaluator
  (sequence? 42)
  (sequence? '(a b c))
  (sequence? "word")
  (sequence? #\x)]}

@defproc*[([(in-range [end real?]) stream?]
           [(in-range [start real?] [end real?] [step real? 1]) stream?])]{
  返回一个序列（也是@tech{stream}），其元素为数字。单参数情况@racket[(in-range end)]等效于@racket[(in-range 0 end 1)]。
序列中的第一个数字是@racket[start]，后续每个元素通过将@racket[step]加到前一个元素来生成。
如果@racket[step]为非负数，序列在遇到大于等于@racket[end]的元素之前停止；如果@racket[step]为负数，在遇到小于等于@racket[end]的元素之前停止。  @speed[in-range "number"]


  @examples[#:label "Example: gaussian sum" #:eval sequence-evaluator
    (for/sum ([x (in-range 10)]) x)]


  @examples[#:label "Example: sum of even numbers" #:eval sequence-evaluator
    (for/sum ([x (in-range 0 100 2)]) x)]

  当@racket[step]为零时，@racket[in-range]返回一个无限序列。当@racket[step]是一个非常小的数，并且@racket[step]或序列元素是浮点数时，它也可能返回无限序列。
}

@defproc[(in-inclusive-range [start real?] [end real?] [step real? 1]) stream?]{

  类似于@racket[in-range]，但序列停止条件改为允许最后一个元素等于@racket[end]。 @speed[in-inclusive-range "number"]

  @examples[#:eval sequence-evaluator
    (sequence->list (in-inclusive-range 7 11))
    (sequence->list (in-inclusive-range 7 11 2))
    (sequence->list (in-inclusive-range 7 10 2))
  ]

  @history[#:added "8.0.0.13"]
}


@defproc[(in-naturals [start exact-nonnegative-integer? 0]) stream?]{
  返回一个精确整数的无限序列（也是@tech{stream}），从@racket[start]开始，每个元素比前一个元素大1。  @speed[in-naturals "integer"]

  @examples[#:eval sequence-evaluator
    (for/list ([k (in-naturals)]
               [x (in-range 10)])
      (list k x))]
}


@defproc[(in-list [lst list?]) stream?]{
  返回一个序列（也是@tech{stream}），等效于直接将@racket[lst]用作序列。
  @info-on-seq["pairs" "lists"]
  @speed[in-list "list"]
  @for-element-reachability["list"]

  @examples[#:eval sequence-evaluator
    (for/list ([x (in-list '(3 1 4))])
      `(,x ,(* x x)))]

@history[#:changed "6.7.0.4" @elem{Improved element-reachability guarantee for lists in @racket[for].}]}


@defproc[(in-mlist [mlst mlist?]) sequence?]{
  返回一个等效于@racket[mlst]的序列。虽然期望@racket[mlst]是@tech{mutable list}，但@racket[in-mlist]
最初只检查@racket[mlst]是否为@tech{mutable pair}或@racket[null]，因为它可能在迭代期间发生变化。
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
  当未提供可选参数时，返回一个等效于@racket[vec]的序列。

@info-on-seq["vectors" "vectors"]

可选参数@racket[start]、@racket[stop]和@racket[step]类似于@racket[in-range]，不同之处在于@racket[stop]的@racket[#f]值等效于@racket[(vector-length vec)]。
也就是说，序列中的第一个元素是@racket[(vector-ref vec start)]，后续每个元素通过将@racket[step]加到前一个元素的索引来生成。
如果@racket[step]为非负数，序列在索引大于等于@racket[end]之前停止；如果@racket[step]为负数，在索引小于等于@racket[end]之前停止。

如果@racket[start]不是有效索引，则@exnraise[exn:fail:contract]，除非@racket[start]、@racket[stop]和@racket[(vector-length vec)]相等，此时结果为空序列。

  @examples[#:eval sequence-evaluator
            (for ([x (in-vector (vector 1) 1)]) x)
            (eval:error (for ([x (in-vector (vector 1) 2)]) x))
            (for ([x (in-vector (vector) 0 0)]) x)
            (for ([x (in-vector (vector 1) 1 1)]) x)]

  如果@racket[stop]不在[-1, @racket[(vector-length vec)]]范围内，则@exnraise[exn:fail:contract]。

如果@racket[start]小于@racket[stop]且@racket[step]为负数，则@exnraise[exn:fail:contract]。
类似地，如果@racket[start]大于@racket[stop]且@racket[step]为正数，则@exnraise[exn:fail:contract]。

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
  当未提供可选参数时，返回一个等效于@racket[str]的序列。

@info-on-seq["strings" "strings"]

可选参数@racket[start]、@racket[stop]和@racket[step]与@racket[in-vector]中的相同。

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
  当未提供可选参数时，返回一个等效于@racket[bstr]的序列。

@info-on-seq["bytestrings" "byte strings"]

可选参数@racket[start]、@racket[stop]和@racket[step]与@racket[in-vector]中的相同。

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
  返回一个序列，其元素通过调用@racket[r]处理@racket[in]来产生，直到产生@racket[eof]为止。}

@defproc[(in-input-port-bytes [in input-port?]) sequence?]{
  返回一个等效于@racket[(in-port read-byte in)]的序列。}

@defproc[(in-input-port-chars [in input-port?]) sequence?]{
  返回一个序列，其元素以字符形式从@racket[in]读取（等效于@racket[(in-port read-char in)]）。}

@defproc[(in-lines [in input-port? (current-input-port)]
                   [mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'any])
         sequence?]{
  返回一个等效于@racket[(in-port (lambda (p) (read-line p mode)) in)]的序列。
请注意，默认模式是@racket['any]，而@racket[read-line]的默认模式是@racket['linefeed]。}

@defproc[(in-bytes-lines [in input-port? (current-input-port)]
                         [mode (or/c 'linefeed 'return 'return-linefeed 'any 'any-one) 'any])
         sequence?]{
  返回一个等效于@racket[(in-port (lambda (p) (read-bytes-line p mode)) in)]的序列。
请注意，默认模式是@racket['any]，而@racket[read-bytes-line]的默认模式是@racket['linefeed]。}

@defproc*[([(in-hash [hash hash?]) sequence?]
           [(in-hash [hash hash?] [bad-index-v any/c]) sequence?])]{
  返回一个等效于@racket[hash]的序列，除非提供了@racket[bad-index-v]。

与@racket[hash-map]类似，通过@racket[in-hash]进行的迭代可以适应遍历进行中对可变哈希表的某些修改。
遍历线程删除或重映射的键不会产生即时的不良影响；如果该键已被遍历到，则修改不会影响遍历，否则遍历会跳过已删除的键或使用重映射键的新值。

其他并发修改，包括由不同线程删除键，可能导致条目被跳过，或者如果预期条目的键在其键或值可获取之前被删除，则引发异常。
如果提供了@racket[bad-index-v]，则在@racket[hash]被并发修改导致迭代没有@tech{valid hash index}的情况下，@racket[bad-index-v]将作为键和值返回。
当遍历具有弱引用键的哈希表时，提供@racket[bad-index-v]特别有用，因为条目可以被异步删除
（即在@racket[in-hash]已承诺进行下一次迭代之后，但在它可以访问下一次迭代的条目之前）。

  @examples[
    (define table (hash 'a 1 'b 2))
    (for ([(key value) (in-hash table)])
      (printf "key: ~a value: ~a\n" key value))]

  @info-on-seq["hashtables" "hash tables"]

  @history[#:changed "7.0.0.10" @elem{Added the optional @racket[bad-index-v] argument.}
           #:changed "8.18.0.11" @elem{Strengthened the guarantees about traversal with
                                       same-thread modifications to a mutable hash table.}]}

@defproc*[([(in-hash-keys [hash hash?]) sequence?]
           [(in-hash-keys [hash hash?] [bad-index-v any/c]) sequence?])]{
  返回一个序列，其元素是@racket[hash]的键，以与@racket[in-hash]相同的方式使用@racket[bad-index-v]，
并具有与@racket[in-hash]类似的并发修改保证。

  @examples[
    (define table (hash 'a 1 'b 2))
    (for ([key (in-hash-keys table)])
      (printf "key: ~a\n" key))]

  @history[#:changed "7.0.0.10" @elem{Added the optional @racket[bad-index-v] argument.}
           #:changed "8.18.0.11" @elem{Strengthened the guarantees about traversal with
                                       same-thread modifications to a mutable hash table.}]}

@defproc*[([(in-hash-values [hash hash?]) sequence?]
           [(in-hash-values [hash hash?] [bad-index-v any/c]) sequence?])]{
  返回一个序列，其元素是@racket[hash]的值，以与@racket[in-hash]相同的方式使用@racket[bad-index-v]，
并具有与@racket[in-hash]类似的并发修改保证。

  @examples[
    (define table (hash 'a 1 'b 2))
    (for ([value (in-hash-values table)])
      (printf "value: ~a\n" value))]

  @history[#:changed "7.0.0.10" @elem{Added the optional @racket[bad-index-v] argument.}
           #:changed "8.18.0.11" @elem{Strengthened the guarantees about traversal with
                                       same-thread modifications to a mutable hash table.}]}

@defproc*[([(in-hash-pairs [hash hash?]) sequence?]
           [(in-hash-pairs [hash hash?] [bad-index-v any/c]) sequence?])]{
  返回一个序列，其元素为pair，每个pair包含来自@racket[hash]的键及其值（而不是直接将@racket[hash]用作序列，
为每个元素分别获取键和值）。

如果提供了@racket[bad-index-v]参数，其使用方式与@racket[in-hash]相同。当遇到无效索引时，
序列中的pair将以@racket[bad-index-v]同时作为其@racket[car]和@racket[cdr]。
@racket[in-hash-pairs]的并发修改保证与@racket[in-hash]类似。

  @examples[
    (define table (hash 'a 1 'b 2))
    (for ([key+value (in-hash-pairs table)])
      (printf "key and value: ~a\n" key+value))]

  @history[#:changed "7.0.0.10" @elem{Added the optional @racket[bad-index-v] argument.}
           #:changed "8.18.0.11" @elem{Strengthened the guarantees about traversal with
                                       same-thread modifications to a mutable hash table.}]}

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
   针对特定类型哈希表的序列构造函数。这些可能比类似的@racket[in-hash]形式性能更好。

   @history[#:added "6.4.0.6"
            #:changed "7.0.0.10" @elem{Added the optional @racket[bad-index-v] argument.}
            #:changed "8.0.0.10" @elem{Added @schemeidfont{ephemeron} variants.}]
}


@defproc[(in-directory [dir (or/c #f path-string?) #f]
                       [use-dir? ((and/c path? complete-path?) . -> . any/c)
                                 (lambda (dir-path) #t)])
         (sequence/c path?)]{
  返回一个序列，生成@racket[dir]内所有文件、目录和链接的路径，但不包括@racket[use-dir?]返回@racket[#f]的任何目录的内容。
如果@racket[dir]不是@racket[#f]，则生成的每个路径都以@racket[dir]为前缀。
如果@racket[dir]是@racket[#f]，则生成当前目录内和相对于当前目录的路径。

@racket[in-directory]序列递归遍历嵌套子目录（通过@racket[use-dir?]过滤）。
要生成仅包含目录直接内容的序列，请将@racket[directory-list]的结果用作序列。

每个目录的直接内容按@racket[path<?]排序报告，子目录的内容在该目录内后续路径之前报告。

  @examples[
    (eval:alts (current-directory (path-only (collection-file-path "main.rkt" "info")))
               (void))
    (eval:alts (for/list ([f (in-directory)])
                  f)
               (map string->path '("compiled"
                                   "compiled/main_rkt.dep"
                                   "compiled/main_rkt.zo"
                                   "main.rkt")))
    (eval:alts (for/list ([f (in-directory "compiled")])
                 f)
               (map string->path '("compiled/main_rkt.dep"
                                   "compiled/main_rkt.zo")))
    (eval:alts (for/list ([f (in-directory #f (lambda (p)
                                                (not (regexp-match? #rx"compiled" p))))])
                  f)
               (map string->path '("compiled" "main.rkt")))
  ]

@history[#:changed "6.0.0.1" @elem{Added @racket[use-dir?] argument.}
         #:changed "6.6.0.4" @elem{Added guarantee of sorted results.}]}


@defproc*[([(in-producer [producer procedure?])
            sequence?]
           [(in-producer [producer procedure?] [stop any/c] [arg any/c] ...)
            sequence?])]{
  返回一个序列，包含对@racket[producer]的顺序调用所产生的值，该过程通常使用某些状态来完成其工作。

如果未给出@racket[stop]值，序列将无限进行，因此通常与有限序列或使用@racket[#:break]等一起使用。
如果给出@racket[stop]值，则用于标识标记序列结束的值（该@racket[stop]值不包含在序列中）；
@racket[stop]可以是一个谓词，应用于@racket[producer]的结果，或者可以是一个通过@racket[eq?]与结果比较的值。
（如果停止值本身是函数或@racket[producer]返回多个值，则@racket[stop]参数必须是一个谓词。）

如果指定了额外的@racket[arg]，它们会传递给每次对@racket[producer]的调用。

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
  返回一个产生单个值@racket[v]的序列。

此形式主要用于类似@racket[for*/list]等形式中的@racket[let]式绑定——但最近添加的@racket[#:do]子句形式涵盖了许多相同的用途。
}

@defproc[(in-indexed [seq sequence?]) sequence?]{
  返回一个序列，其中每个元素有两个值：由@racket[seq]产生的值，以及从@racket[0]开始的非负精确整数。
@racket[seq]的元素必须是单值的。
  
  @(examples
    #:eval sequence-evaluator
    (for ([(ch i) (in-indexed "hello")])
      (printf "The char at position ~a is: ~a\n" i ch)))
}

@defproc[(in-sequences [seq sequence?] ...) sequence?]{
  返回一个由所有输入序列依次组成的序列。每个@racket[seq]仅在前一个@racket[seq]耗尽后才被@tech{initiate}。
如果只提供一个@racket[seq]，则返回@racket[seq]；否则，每个@racket[seq]的元素必须具有相同数量的值。}

@defproc[(in-cycle [seq sequence?] ...) sequence?]{
  类似于@racket[in-sequences]，但序列以无限循环重复，其中每个@racket[seq]在每次迭代中都被重新@tech{initiate}。
注意，如果未提供@racket[seq]或所有@racket[seq]变为空，则@racket[in-cycle]生成的序列在要求元素时永远不会返回——
甚至在序列被@tech{initiate}时（如果所有@racket[seq]最初为空）也不会返回。}

@defproc[(in-parallel [seq sequence?] ...) sequence?]{
  返回一个序列，其中每个元素的值数量与提供的@racket[seq]数量相同；这些值依次是每个@racket[seq]的值。
每个@racket[seq]的元素必须是单值的。}

@defproc[(in-parallel-values [n exact-nonnegative-integer?] [seq sequence?] ... ...) sequence?]{
  返回一个序列，其中每个元素的值数量是提供的@racket[seq]产生的值数量的总和，
每个@racket[seq]前面都有其产生值的数量@racket[n]（因此结果值的数量是@racket[n]的总和）。
新序列的值依次是每个@racket[seq]的值。

  @history[#:added "9.0.0.2"]}

@defproc[(in-values-sequence [seq sequence?]) sequence?]{
  返回一个类似于@racket[seq]的序列，但它将@racket[seq]每个元素的多个值组合为元素列表。}

@defproc[(in-values*-sequence [seq sequence?]) sequence?]{
  返回一个类似于@racket[seq]的序列，但当@racket[seq]的元素有多个值或单个列表值时，这些值会被组合成列表。
换句话说，@racket[in-values*-sequence]类似于@racket[in-values-sequence]，
不同之处在于非列表的单值元素不会被包装在列表中。
}

@defproc[(stop-before [seq sequence?] [pred (any/c . -> . any)])
         sequence?]{
  返回一个包含@racket[seq]元素的序列（必须是单值的），但只到对元素应用@racket[pred]产生@racket[#t]的最后一个元素之前，此后序列结束。
}

@defproc[(stop-after [seq sequence?] [pred (any/c . -> . any)])
         sequence?]{
  返回一个包含@racket[seq]元素的序列（必须是单值的），但只到对元素应用@racket[pred]产生@racket[#t]的那个元素（含），此后序列结束。
}

@defproc[(make-do-sequence
          [thunk (or/c (-> (values (any/c . -> . any)
                                   (any/c . -> . any/c)
                                   any/c
                                   (or/c (any/c . -> . any/c) #f)
                                   (or/c (any/c ... . -> . any/c) #f)
                                   (or/c (any/c any/c ... . -> . any/c) #f)))
                       (-> (values (any/c . -> . any)
                                   (or/c (any/c . -> . any/c) #f)
                                   (any/c . -> . any/c)
                                   any/c
                                   (or/c (any/c . -> . any/c) #f)
                                   (or/c (any/c ... . -> . any/c) #f)
                                   (or/c (any/c any/c ... . -> . any/c) #f))))])
         sequence?]{
  返回一个序列，其元素根据@racket[thunk]生成。

当调用@racket[thunk]时，序列被@tech{initiate}。已初始化的序列定义为
@defterm{position}（初始化为@racket[_init-pos]）和@defterm{element}（可能包含多个值）。

@racket[thunk]过程必须返回6个或7个值。但是，请使用@racket[initiate-sequence]返回这些多值，
而不是直接列出值。

  如果@racket[thunk]返回6个值：
@itemize[
@item{第一个结果是一个@racket[_pos->element]过程，接受当前位置并返回当前元素的值。}
@item{第二个结果是一个@racket[_next-pos]过程，接受当前位置并返回下一个位置。}
@item{第三个结果是一个@racket[_init-pos]值，即初始位置。}
@item{第四个结果是一个@racket[_continue-with-pos?]函数，接受当前位置，如果序列包含当前位置的值则返回真值，
如果序列应该结束而不包含这些值则返回假值。或者，@racket[_continue-with-pos?]可以是@racket[#f]，
表示序列应始终包含当前值。在使用@racket[_pos->element]之前，对每个位置检查此函数。}
@item{第五个结果是一个@racket[_continue-with-val?]函数，类似于@racket[_continue-with-pos?]，
但它接受当前元素值作为参数而不是当前位置。或者，@racket[_continue-with-val?]可以是@racket[#f]，
表示序列应始终包含当前位置的值。}
@item{第六个结果是一个@racket[_continue-after-pos+val?]过程，同时接受当前位置和当前元素值，
确定序列在当前元素已包含后是否结束。或者，@racket[_continue-after-pos+val?]可以是@racket[#f]，
表示序列在包含当前值后可以始终继续。}]}

  如果@racket[thunk]返回7个值，第一个结果仍然是@racket[_pos->element]过程。
但是，第二个结果现在是一个@racket[_early-next-pos]过程，下文将进一步描述。
或者，@racket[_early-next-pos]可以是@racket[#f]，相当于恒等函数。
其他结果的位置向后偏移一位，因此第三个结果现在是@racket[_next-pos]，第四个结果现在是@racket[_init-pos]，依此类推。

@racket[_early-next-pos]过程接受当前位置并返回更新后的位置。此更新位置用于@racket[_next-pos]和@racket[_continue-after-pos+val?]，
但不用于@racket[_continue-with-pos?]（后者使用原始当前位置）。
@racket[_early-next-pos]的目的是支持这样一种序列：必须递增位置以避免在循环处理序列值时保持值可访问，
因此@racket[_early-next-pos]在@racket[_pos->element]之后立即应用。
@racket[_continue-after-pos+val?]函数需要为@racket[#f]以避免保留值来提供给该函数。

  上述列出的每个过程每个位置仅调用一次。在@racket[_continue-with-pos?]、@racket[_continue-with-val?]和@racket[_continue-after-pos+val?]三个过程中，
一旦其中一个返回@racket[#f]，序列就结束，并且不会再次调用其他过程。通常，其中一个函数确定结束条件，
其余两个函数的位置使用@racket[#f]。

@history[#:changed "6.7.0.4" @elem{Added support for the optional second result.}]


@defthing[prop:sequence struct-type-property?]{

  将一个过程关联到结构类型，该过程接受结构实例并返回一个序列。如果@racket[v]是具有此属性的结构类型实例，
则@racket[(sequence? v)]产生@racket[#t]。

使用预先存在的序列：

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

  使用@racket[make-do-sequence]：

  @let-syntax[([car (make-element-id-transformer
                     (lambda (id) #'@racketidfont{car}))])
    @examples[
      (require racket/sequence)
      (struct train (car next)
        #:property prop:sequence
        (lambda (t)
          (make-do-sequence
           (lambda ()
             (initiate-sequence
              #:pos->element train-car
              #:next-pos train-next
              #:init-pos t
              #:continue-with-pos? (lambda (t) t))))))
      (for/list ([c (train 'engine
                           (train 'boxcar
                                  (train 'caboose
                                         #f)))])
        c)]]}

@; ----------------------------------------------------------------------
@subsection{序列转换}

@defproc[(sequence->stream [seq sequence?]) stream?]{
  将序列转换为@tech{stream}，后者支持@racket[stream-first]和@racket[stream-rest]操作。
流的创建会急切地@tech{initiates}序列，但流会惰性地从序列中提取元素，缓存每个元素，
使得每次对流应用@racket[stream-first]时产生相同的结果。

如果从@racket[seq]提取元素涉及副作用，那么每次首次使用@racket[stream-first]或@racket[stream-rest]
来访问或跳过元素时，该副作用都会执行。

注意，@elemref["sequence-state"]{序列本身可以有状态}，因此对同一@racket[seq]多次调用@racket[sequence->stream]不一定是独立的。

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
  @tech{Initiates}一个序列并返回两个thunk用于从序列中提取元素。第一个在序列还有更多值可用时返回@racket[#t]。
第二个返回序列的下一个元素（可能是多个值）；如果没有更多元素可用，则@exnraise[exn:fail:contract]。

注意，@elemref["sequence-state"]{序列本身可以有状态}，因此对同一@racket[seq]多次调用@racket[sequence-generate]不一定是独立的。

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
  类似于@racket[sequence-generate]，但通过返回序列第一个元素的值列表——如果序列为空则返回@racket[#f]——以及一个继续序列的thunk来避免状态（除序列本身固有的状态外）；
thunk的结果与@racket[sequence-generate*]的结果相同，但是针对序列的第二个元素，依此类推。
如果在元素结果为@racket[#f]（表示序列中没有更多值）时调用thunk，则@exnraise[exn:fail:contract]。}

@; ----------------------------------------------------------------------
@subsection[#:tag "more-sequences"]{额外的序列操作}

@note-lib[racket/sequence]

@defthing[empty-sequence sequence?]{
  一个没有元素的序列。}

@defproc[(sequence->list [s sequence?]) list?]{
  返回一个列表，其元素是@s的元素，每个元素必须是单值。如果@s是无限的，此函数不会终止。}

@defproc[(sequence-length [s sequence?])
         exact-nonnegative-integer?]{
  通过提取并丢弃@s的所有元素来返回其元素数量。如果@s是无限的，此函数不会终止。}

@defproc[(sequence-ref [s sequence?] [i exact-nonnegative-integer?])
         any]{
  返回@s的第@racket[i]个元素（可能是多个值）。}

@defproc[(sequence-tail [s sequence?] [i exact-nonnegative-integer?])
         sequence?]{
  返回一个等效于@s的序列，但省略了前@racket[i]个元素。

  如果@tech[#:key "initiate"]{initiating} @racket[s]涉及副作用，则在结果序列被@tech{initiate}之前不会@tech{initiate} @racket[s]，
此时从序列中提取前@racket[i]个元素。
}

@defproc[(sequence-append [s sequence?] ...)
         sequence?]{
  返回一个序列，按原始序列中的顺序包含每个序列的所有元素。新序列是惰性构造的。

如果所有给定的@s都是@tech{streams}，则结果也是@tech{stream}。
}

@defproc[(sequence-map [f procedure?]
                       [s sequence?])
         sequence?]{
  返回一个序列，包含对@s的每个元素应用@racket[f]的结果。新序列是惰性构造的。

如果@s是@tech{stream}，则结果也是@tech{stream}。
}

@defproc[(sequence-andmap [f (-> any/c ... boolean?)]
                          [s sequence?])
         boolean?]{
  如果@racket[f]对@s的每个元素都返回真值结果，则返回@racket[#t]。如果@s是无限的且@racket[f]从未返回假值结果，则此函数不会终止。
}

@defproc[(sequence-ormap [f (-> any/c ... boolean?)]
                         [s sequence?])
         boolean?]{
  如果@racket[f]对@s的某个元素返回真值结果，则返回@racket[#t]。如果@s是无限的且@racket[f]从未返回真值结果，则此函数不会终止。
}

@defproc[(sequence-for-each [f (-> any/c ... any)]
                            [s sequence?])
         void?]{
  对@s的每个元素应用@racket[f]。如果@s是无限的，此函数不会终止。
}

@defproc[(sequence-fold [f (-> any/c any/c ... any/c)]
                        [i any/c]
                        [s sequence?])
         any/c]{
  以@racket[i]作为初始累加器，对@s的每个元素折叠@racket[f]。如果@s是无限的，此函数不会终止。
@racket[f]函数以累加器作为第一个参数，下一个序列元素作为第二个参数。
}

@defproc[(sequence-count [f procedure?] [s sequence?])
         exact-nonnegative-integer?]{
  返回@s中@racket[f]返回真值结果的元素数量。如果@s是无限的，此函数不会终止。
}

@defproc[(sequence-filter [f (-> any/c ... boolean?)]
                          [s sequence?])
         sequence?]{
  返回一个序列，其元素是@s中@racket[f]返回真值结果的元素。虽然新序列是惰性构造的，
但如果@s在@racket[f]返回真值结果的两个元素之间有无限多个@racket[f]返回假值结果的元素，
则在此无限子序列期间，对该序列的操作不会终止。

如果@s是@tech{stream}，则结果也是@tech{stream}。
}

@defproc[(sequence-add-between [s sequence?] [e any/c])
         sequence?]{
  返回一个序列，其元素是@s的元素，但在@s中每对元素之间有@racket[e]。新序列是惰性构造的。

如果@s是@tech{stream}，则结果也是@tech{stream}。

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

包装一个@tech{sequence}，要求其产生具有与@racket[elem/c]合约数量相同数量的值的元素，
并要求每个值满足相应的@racket[elem/c]。结果不保证与原始值是相同类型的序列；
例如，包装后的列表不保证满足@racket[list?]。

如果@racket[min-count]是一个数字，则要求流中至少有那么多元素。

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

@subsubsection{额外的序列构造函数与函数}

@defproc[(in-syntax [stx syntax?]) sequence?]{
  生成一个序列，其元素是@racket[stx]的连续子部分。等效于@racket[(stx->list lst)]。
  @speed[in-syntax "syntax"]

@examples[#:eval sequence-evaluator
(for/list ([x (in-syntax #'(1 2 3))])
  x)]

@history[#:added "6.3"]}

@defproc[(in-slice [length exact-positive-integer?] [seq sequence?])
         sequence?]{
  返回一个序列，其元素是包含@racket[seq]的前@racket[length]个元素、接下来@racket[length]个元素等依次排列的列表。

  @examples[#:eval sequence-evaluator
  (for/list ([e (in-slice 3 (in-range 8))]) e)
  ]
  @history[#:added "6.3"]
}

@defproc[(initiate-sequence
          [#:pos->element pos->element (any/c . -> . any)]
          [#:early-next-pos early-next-pos (or/c (any/c . -> . any) #f) #f]
          [#:next-pos next-pos (any/c . -> . any/c)]
          [#:init-pos init-pos any/c]
          [#:continue-with-pos? continue-with-pos? (or/c (any/c . -> . any/c) #f) #f]
          [#:continue-with-val? continue-with-val? (or/c (any/c ... . -> . any/c) #f) #f]
          [#:continue-after-pos+val? continue-after-pos+val? (or/c (any/c any/c ... . -> . any/c) #f) #f])
         (values (any/c . -> . any)
                 (or/c (any/c . -> . any) #f)
                 (any/c . -> . any/c)
                 any/c
                 (or/c (any/c . -> . any/c) #f)
                 (or/c (any/c ... . -> . any/c) #f)
                 (or/c (any/c any/c ... . -> . any/c) #f))]{
  返回适用于@racket[make-do-sequence]中thunk参数的值。每个参数的含义请参见@racket[make-do-sequence]。

  @examples[#:eval sequence-evaluator
    (define (in-alt-list xs)
      (make-do-sequence
       (λ ()
         (initiate-sequence
          #:pos->element car
          #:next-pos (λ (xs) (cdr (cdr xs)))
          #:init-pos xs
          #:continue-with-pos? pair?
          #:continue-after-pos+val? (λ (xs _) (pair? (cdr xs)))))))
    (sequence->list (in-alt-list '(1 2 3 4 5 6)))
    (sequence->list (in-alt-list '(1 2 3 4 5 6 7)))
  ]
  @history[#:added "8.10.0.5"]
}


@; ======================================================================
@section[#:tag "streams"]{流}

@deftech{stream}是一种@tech{sequence}，支持通过@racket[stream-first]和@racket[stream-rest]进行函数式迭代。
@racket[stream-cons]形式构造惰性流，但普通列表可以用作流，并且@racket[in-range]和@racket[in-naturals]等函数也可以创建流。

@note-lib[racket/stream]

@defproc[(stream? [v any/c]) boolean?]{
  如果@racket[v]可以用作@tech{stream}，则返回@racket[#t]，否则返回@racket[#f]。
}

@defproc[(stream-empty? [s stream?]) boolean?]{
  如果@s没有元素，则返回@racket[#t]，否则返回@racket[#f]。
}

@defproc[(stream-first [s (and/c stream? (not/c stream-empty?))]) any]{
  返回@s中第一个元素的值。
}

@defproc[(stream-rest [s (and/c stream? (not/c stream-empty?))]) stream?]{
  返回一个等效于@s但不含其第一个元素的流。
}

@defform*[[(stream-cons first-expr rest-expr)
           (stream-cons #:eager first-expr rest-expr)
           (stream-cons first-expr #:eager rest-expr)
           (stream-cons #:eager first-expr #:eager rest-expr)]]{

  生成一个流，其第一个元素由@racket[first-expr]确定，其余部分由@racket[rest-expr]确定。

如果@racket[first-expr]前面没有@racket[#:eager]，则@racket[first-expr]不会立即求值。
相反，对结果流使用@racket[stream-first]会强制对@racket[first-expr]求值（一次）以产生流的第一个元素。
如果对@racket[first-expr]求值引发异常或试图强制自身求值，则@exnraise[exn:fail:contract]，
并且后续尝试强制求值将触发另一个异常。

如果@racket[rest-expr]前面没有@racket[#:eager]，则@racket[rest-expr]不会立即求值。
相反，对结果流使用@racket[stream-rest]会产生另一个流，类似于@racket[(stream-lazy rest-expr)]产生的流。

由@racket[first-expr]产生的流的第一个元素可以是多个值。@racket[rest-expr]在求值时必须产生一个流，
否则@exnraise[exn:fail:contract?]。

  @history[#:changed "8.0.0.12" @elem{Added @racket[#:eager] options.}
           #:changed "8.8.0.7" @elem{Changed to allow multiple values.}]}

@defform*[[(stream-lazy stream-expr)
           (stream-lazy #:who who-expr stream-expr)]]{

 类似于@racket[(delay stream-expr)]，但结果是一个流而不是@tech{promise}，并且@racket[stream-expr]最终被强制求值时必须产生一个流。
@racket[stream-lazy]产生的流与@racket[stream-expr]产生的流具有相同的内容；
也就是说，对结果流执行@racket[stream-first]等操作将强制对@racket[stream-expr]求值并在其结果上重试。

如果对@racket[stream-expr]求值引发异常或试图强制自身求值，则@exnraise[exn:fail:contract]，
并且后续尝试强制求值将触发另一个异常。

如果提供了@racket[who-expr]，则在构造延迟流时对其求值。如果@racket[stream-expr]之后产生非流的值，
且@racket[who-expr]产生了符号值，则该符号用于错误消息。

 @history[#:added "8.0.0.12"]}

@defproc[(stream-force [s stream?]) stream?]{

 强制对来自@racket[stream-lazy]、@racket[stream-cons]的@racket[stream-rest]等的延迟流进行求值，返回强制后的流。
如果@s不是延迟流，则返回@s。

通常不需要@racket[stream-force]，因为@racket[stream-first]、@racket[stream-rest]和@racket[stream-empty?]等操作会根据需要强制延迟流。
在极少数情况下，@racket[stream-force]可以用于揭示流的底层实现
（例如，作为具有@racket[prop:stream]属性的结构类型实例的流）。

 @history[#:added "8.0.0.12"]}

@defform[#:literals (values)
         (stream elem-expr ...)
         #:grammar ([elem-expr (values single-expr ...)
                               single-expr])]{
  以@racket[empty-stream]结尾的嵌套@racket[stream-cons]es的简写。作为匹配模式，@racket[stream]
匹配具有与@racket[elem-expr]数量相同的元素的流，且每个元素必须匹配相应的@racket[elem-expr]模式。
@racket[elem-expr]模式可以是@racket[(values single-expr ...)]，用于匹配流中的多值元素。

  @history[#:changed "8.8.0.7" @elem{Changed to allow multiple values.}]
}

@defform[(stream* elem-expr ... tail-expr)]{
  嵌套@racket[stream-cons]es的简写，但@racket[tail-expr]在强制求值时必须产生一个流，
该流用作流的其余部分而不是@racket[empty-stream]。类似于@racket[list*]但用于流。
作为匹配模式，@racket[stream*]类似于@racket[stream]模式，
但@racket[tail-expr]模式匹配最后一个@racket[elem-expr]之后流的"其余"部分。

@history[#:added "6.3"
         #:changed "8.0.0.12"
         @elem{Changed to delay @racket[tail-expr] even if zero
               @racket[elem-expr]s are provided.}
         #:changed "8.8.0.7"
         @elem{Changed to allow multiple values.}]
}

@defproc[(in-stream [s stream?]) sequence?]{
  返回一个等效于@s的序列。
  @speed[in-stream "streams"]
  @for-element-reachability["stream"]

@history[#:changed "6.7.0.4" @elem{Improved element-reachability guarantee for streams in @racket[for].}]}

@defthing[empty-stream stream?]{
  一个没有元素的流。
}

@defproc[(stream->list [s stream?]) list?]{
  返回一个列表，其元素是@s的元素，每个元素必须是单值。如果@s是无限的，此函数不会终止。
}

@defproc[(stream-length [s stream?])
         exact-nonnegative-integer?]{
  返回@s的元素数量。如果@s是无限的，此函数不会终止。

对于惰性流，此函数仅强制对子流求值，而不对流的元素求值。
}

@defproc[(stream-ref [s stream?] [i exact-nonnegative-integer?])
         any]{
  返回@s的第@racket[i]个元素（可能是多个值）。
}

@defproc[(stream-tail [s stream?] [i exact-nonnegative-integer?])
         stream?]{
  返回一个等效于@s的流，但省略了前@racket[i]个元素。

如果从@s提取元素涉及副作用，则在从结果流中提取第一个元素之前不会提取它们。
}

@defproc[(stream-take [s stream?] [i exact-nonnegative-integer?])
         stream?]{
  返回包含@s的前@racket[i]个元素的流。
}

@defproc[(stream-append [s stream?] ...)
         stream?]{
  返回一个流，按原始流中的顺序包含每个流的所有元素。新流是惰性构造的，
而最后一个给定的流用作结果的尾部。
}

@defproc[(stream-map [f procedure?]
                     [s stream?])
         stream?]{
  返回一个流，包含对@s的每个元素应用@racket[f]的结果。新流是惰性构造的。
}

@defproc[(stream-andmap [f (-> any/c ... boolean?)]
                        [s stream?])
         boolean?]{
  如果@racket[f]对@s的每个元素都返回真值结果，则返回@racket[#t]。如果@s是无限的且@racket[f]从未返回假值结果，则此函数不会终止。
}

@defproc[(stream-ormap [f (-> any/c ... boolean?)]
                       [s stream?])
         boolean?]{
  如果@racket[f]对@s的某个元素返回真值结果，则返回@racket[#t]。如果@s是无限的且@racket[f]从未返回真值结果，则此函数不会终止。
}

@defproc[(stream-for-each [f (-> any/c ... any)]
                          [s stream?])
         void?]{
  对@s的每个元素应用@racket[f]。如果@s是无限的，此函数不会终止。
}

@defproc[(stream-fold [f (-> any/c any/c ... any/c)]
                      [i any/c]
                      [s stream?])
         any/c]{
  以@racket[i]作为初始累加器，对@s的每个元素折叠@racket[f]。如果@s是无限的，此函数不会终止。
@racket[f]函数以累加器作为第一个参数，下一个流的元素作为第二个参数。
}

@defproc[(stream-count [f procedure?] [s stream?])
         exact-nonnegative-integer?]{
  返回@s中@racket[f]返回真值结果的元素数量。如果@s是无限的，此函数不会终止。
}

@defproc[(stream-filter [f (-> any/c ... boolean?)]
                          [s stream?])
         stream?]{
  返回一个流，其元素是@s中@racket[f]返回真值结果的元素。虽然新流是惰性构造的，
但如果@s在@racket[f]返回假值结果的位置有无限多个元素，则在此无限子流期间对该流的操作不会终止。
}

@defproc[(stream-add-between [s stream?] [e any/c])
         stream?]{
  返回一个流，其元素是@s的元素，但在@s中每对元素之间有@racket[e]。新流是惰性构造的。
}

@deftogether[(@defform[(for/stream (for-clause ...) body-or-break ... body)]
              @defform[(for*/stream (for-clause ...) body-or-break ... body)])]{
  分别类似于@racket[for/list]和@racket[for*/list]进行迭代，但结果惰性地收集到@tech{stream}中而非列表中。

与大多数@racket[for]形式不同，这些形式是惰性求值的，因此每个@racket[body]在结果流被强制求值之前不会求值。
这使得@racket[for/stream]和@racket[for*/stream]可以迭代无限序列，而不像它们的有限对应版本。

  @examples[#:eval sequence-evaluator
    (for/stream ([i '(1 2 3)]) (* i i))
    (stream->list (for/stream ([i '(1 2 3)]) (* i i)))
    (stream-ref (for/stream ([i '(1 2 3)]) (displayln i) (* i i)) 1)
    (stream-ref (for/stream ([i (in-naturals)]) (* i i)) 25)
    (stream-ref (for/stream ([i (in-naturals)]) (values i (add1 i))) 10)
  ]

  @history[#:added "6.3.0.9"
           #:changed "8.8.0.7" @elem{Changed to allow multiple values.}]
}

@defthing[gen:stream any/c]{
  将三个方法关联到结构类型，以实现流的@tech{generic interface}（参见@secref["struct-generics"]）。

要提供方法实现，应在结构类型定义中使用@racket[#:methods]关键字。必须实现以下三个方法：

@itemize[
@item{@racket[_stream-empty?]：接受一个参数}
@item{@racket[_stream-first]：接受一个参数}
@item{@racket[_stream-rest]：接受一个参数}
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

  @history[#:changed "8.7.0.5"
           @elem{Added a check so that omitting any of
                 @racket[_stream-empty?], @racket[_stream-first], and @racket[_stream-rest]
                 is now a syntax error.}]

}

@defthing[prop:stream struct-type-property?]{
  一个结构类型属性，用于定义流API的自定义扩展。不鼓励使用@racket[prop:stream]属性；
请改用@racket[gen:stream] @tech{generic interface}。接受一个包含三个过程的向量，
这些过程接受与@racket[gen:stream]中方法相同的参数。
}

@defproc[(stream/c [c contract?]) contract?]{
返回一个识别流的合约。流中的所有元素必须匹配@racket[c]。

如果@racket[c]参数是平坦合约或监管合约，则结果将是监管合约。否则，结果将是模拟合约。

当@racket[stream/c]合约应用于流时，结果与输入不是@racket[eq?]关系。
结果将是输入的@tech{chaperone}或@tech{impersonator}，取决于合约类型。

流上的合约出于必要是惰性求值的（因为流可能是无限的）。直到从流中检索到违规值之前，不会引发合约违规。
作为此规则的例外，作为列表的流会立即检查，就像@racket[c]与@racket[listof]一起使用一样。

如果将合约应用于流，并且该流随后用作另一个流的尾部（作为@racket[stream-cons]的第二个参数），
则新元素不会用合约检查，但尾部的元素仍会被强制执行。

@history[#:added "6.1.1.8"]}

@close-eval[sequence-evaluator]

@; ======================================================================
@section{生成器}

@deftech{generator}是一个返回值序列的过程，每次调用生成器时递增序列。
特别地，@racket[generator]形式通过对调用@racket[yield]来从生成器返回值的体进行求值来实现生成器。

@defmodule[racket/generator]

@(define generator-eval
   (let ([the-eval (make-base-eval)])
     (the-eval '(require racket/generator))
     the-eval))

@defproc[(generator? [v any/c]) boolean?]{
  如果@racket[v]是@tech{generator}，则返回@racket[#t]，否则返回@racket[#f]。
}

@defform/subs[(generator formals body ...+)
              ([formals (id ...)
                        (id ...+ . rest-id)
                        rest-id])]{
  创建一个@tech{generator}，其中@racket[formals]指定参数。不支持关键字和可选参数。
这与单个@racket[case-lambda]子句的@racket[formals]相同。

第一次调用生成器时，参数绑定到@racket[formals]，并开始对@racket[body]求值。在@racket[body]的@tech{dynamic extent}期间，
生成器可以使用@racket[yield]函数立即返回。第二次调用生成器时，在@racket[yield]调用处恢复执行，
产生第二次调用的参数作为@racket[yield]的结果，依此类推。@racket[body]的最终结果提供给一个隐式的最终@racket[yield]；
在该最终@racket[yield]之后，再次调用生成器会返回相同的值，但所有此类调用必须向生成器提供0个参数。

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
  从生成器返回@racket[v]，保存生成器内部的执行点（即在@racket[generator]体的@tech{dynamic extent}内），
以便下次调用生成器时恢复执行。@racket[yield]的结果是提供给生成器下一次调用的参数。

当不在@racket[generator]、@racket[infinite-generator]或@racket[in-generator]体的@tech{dynamic extent}内时，
@racket[yield]引发@racket[exn:fail:contract]。

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
  类似于@racket[generator]，但当最后一个@racket[body]完成而没有隐式@racket[yield]时，重复对@racket[body]求值。

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
  生成一个封装了由@racket[(generator () body ...)]形成的@tech{generator}的@tech{sequence}。
生成器生成的值构成序列的元素，但生成器生成的最后一个值除外（即返回生成的值）。

  @examples[#:eval generator-eval
    (for/list ([i (in-generator
                    (let loop ([x '(a b c)])
                      (when (not (null? x))
                        (yield (car x))
                        (loop (cdr x)))))])
      i)]

  If @racket[in-generator] is used immediately with a @racket[for] (or
  @racket[for/list], etc.) binding's right-hand side, then its result
  arity (i.e., the number of values in each element of the sequence)
  can be inferred. Otherwise, if the generator produces multiple
  values for each element, its arity should be declared with an
  @racket[#:arity arity-k] clause; the @racket[arity-k] must be a
  literal, exact, non-negative integer.

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

  To use an existing generator as a sequence, use @racket[in-producer]
  with a stop-value known for the generator:

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
  返回一个描述生成器状态的符号。

  @itemize[
    @item{@racket['fresh]——生成器刚刚创建，尚未被调用。}
    @item{@racket['suspended]——生成器内的控制由于调用@racket[yield]而挂起。可以调用生成器。}
    @item{@racket['running]——生成器当前正在执行。}
    @item{@racket['done]——生成器已执行完其整个体，将继续产生与上次调用相同的结果。}]

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
  将@tech{sequence}转换为@tech{generator}。每次调用生成器时，生成器返回序列的下一个元素，
序列的每个元素必须是单值。当序列结束时，生成器返回@|void-const|作为最终结果。}

@defproc[(sequence->repeated-generator [s sequence?]) (-> any)]{
  类似于@racket[sequence->generator]，但当@s没有更多值时，生成器重新开始序列（因此生成器永远不会停止产生值）。}

@close-eval[generator-eval]
