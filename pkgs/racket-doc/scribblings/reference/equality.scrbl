#lang scribble/manual
@(require (only-in scribblings/style/shared compare0)
          "mz.rkt"
          (for-label racket/hash-code))


@title{相等性}


相等性是关于两个值是否"相同"的概念。Racket 默认支持几种不同的相等性，尽管 @racket[equal?] 在大多数情况下是首选。

@defproc[(equal? [v1 any/c] [v2 any/c]) boolean?]{

 两个值 @racket[equal?] 当且仅当它们是 @racket[eqv?]，除非特定数据类型另有规定。

 对 @racket[equal?] 有进一步规范的数据类型包括字符串、字节串、对、可变对、向量、box、hash table 和可检查的结构。在后六种情况下，相等性是递归定义的；如果 @racket[v1] 和 @racket[v2] 都包含引用循环，则当值的无限展开相等时它们相等。另见 @racket[gen:equal+hash] 和 @racket[prop:impersonator-of]。

 @(examples
   (equal? 'yes 'yes)
   (equal? 'yes 'no)
   (equal? (* 6 7) 42)
   (equal? (expt 2 100) (expt 2 100))
   (equal? 2 2.0)
   (let ([v (mcons 1 2)]) (equal? v v))
   (equal? (mcons 1 2) (mcons 1 2))
   (equal? (integer->char 955) (integer->char 955))
   (equal? (make-string 3 #\z) (make-string 3 #\z))
   (equal? #t #t))}


对于用户定义结构类型的相等性，参见 @secref["trans-struct" #:doc '(lib "scribblings/guide/guide.scrbl")]。


@defproc[(equal-always? [v1 any/c] [v2 any/c]) boolean?]{

 指示 @racket[v1] 和 @racket[v2] 是否相等并且将始终独立于@emph{修改}而保持相等。通常，要使两个值 equal-always，@racket[v1] 和 @racket[v2] 中对应的不可变值必须是 @racket[equal?]，而其中对应的可变值必须是 @racket[eq?]。
 @margin-note*{此运算符在其他语言中的先例包括 @tt{egal} @cite["Baker93"]。}

 两个值 @racket[v1] 和 @racket[v2] @racket[equal-always?] 当且仅当存在第三个值 @racket[_v3] 使得 @racket[v1] 和 @racket[v2] 都是 @racket[_v3] 的 chaperone，即 @racket[(chaperone-of? v1 _v3)] 和 @racket[(chaperone-of? v2 _v3)] 都为真。

 对于不包含 chaperone 或其他 impersonator 的值，@racket[v1] 和 @racket[v2] 如果 @racket[equal?] 则可被视为 equal-always，除了 @racket[v1] 和 @racket[v2] 中对应的可变向量、box、hash table、字符串、字节串、@tech{mutable pairs} 和可变结构必须是 @racket[eq?]，并且结构上的相等性可以通过 @racket[gen:equal-mode+hash] 为 @racket[equal-always?] 进行特化。

 @(examples
   (equal-always? 'yes 'yes)
   (equal-always? 'yes 'no)
   (equal-always? (* 6 7) 42)
   (equal-always? (expt 2 100) (expt 2 100))
   (equal-always? 2 2.0)
   (equal-always? (list 1 2) (list 1 2))
   (let ([v (mcons 1 2)]) (equal-always? v v))
   (equal-always? (mcons 1 2) (mcons 1 2))
   (equal-always? (integer->char 955) (integer->char 955))
   (equal-always? (make-string 3 #\z) (make-string 3 #\z))
   (equal-always? (string->immutable-string (make-string 3 #\z))
                  (string->immutable-string (make-string 3 #\z)))
   (equal-always? #t #t))

@history[#:added "8.5.0.3"]}


@defproc[(eqv? [v1 any/c] [v2 any/c]) boolean?]{

 两个值 @racket[eqv?] 当且仅当它们是 @racket[eq?]，除非特定数据类型另有规定。

 @tech{number} 数据类型是唯一 @racket[eqv?] 与 @racket[eq?] 不同的类型。两个数字 @racket[eqv?] 当它们具有相同的精确度、精度，并且都相等且非零，都是 @racketvalfont{+0.0}，都是 @racketvalfont{+0.0f0}，都是 @racketvalfont{-0.0}，都是 @racketvalfont{-0.0f0}，都是 @racketvalfont{+nan.0}，或都是 @racketvalfont{+nan.f}——在 @tech{complex numbers} 的情况下分别考虑实部和虚部。

 通常，@racket[eqv?] 与 @racket[equal?] 相同，除了前者不能递归地比较复合数据类型（如列表和 struct）的内容，也不能由用户定义的数据类型自定义。不太推荐使用 @racket[eqv?]，建议使用 @racket[equal?]。

 @(examples
   (eqv? 'yes 'yes)
   (eqv? 'yes 'no)
   (eqv? (* 6 7) 42)
   (eqv? (expt 2 100) (expt 2 100))
   (eqv? 2 2.0)
   (let ([v (mcons 1 2)]) (eqv? v v))
   (eqv? (mcons 1 2) (mcons 1 2))
   (eqv? (integer->char 955) (integer->char 955))
   (eqv? (make-string 3 #\z) (make-string 3 #\z))
   (eqv? #t #t))

@history[#:changed "9.0.0.10" @elem{For characters,
                                    @racket[equal?] implies @racket[eq?],
                                    not just @racket[eqv?].}]}


@defproc[(eq? [v1 any/c] [v2 any/c]) boolean?]{

 如果 @racket[v1] 和 @racket[v2] 引用相同的对象则返回 @racket[#t]，否则返回 @racket[#f]。作为 @tech{numbers} 中的特殊情况，两个 @racket[=] 的 @tech{fixnums} 根据 @racket[eq?] 也是相同的。另见 @secref["model-eq"]。

 @(examples
   (eq? 'yes 'yes)
   (eq? 'yes 'no)
   (eq? (* 6 7) 42)
   (eq? (expt 2 100) (expt 2 100))
   (eq? 2 2.0)
   (let ([v (mcons 1 2)]) (eq? v v))
   (eq? (mcons 1 2) (mcons 1 2))
   (eq? (integer->char 955) (integer->char 955))
   (eq? (make-string 3 #\z) (make-string 3 #\z))
   (eq? #t #t))}


@defproc[
 (equal?/recur [v1 any/c] [v2 any/c] [recur-proc (any/c any/c . -> . any/c)])
 boolean?]{

 类似于 @racket[equal?]，但使用 @racket[recur-proc] 进行递归比较（这意味着引用循环不会自动处理）。来自 @racket[recur-proc] 的非 @racket[#f] 结果在由 @racket[equal?/recur] 返回之前被转换为 @racket[#t]。

 @(examples
   (equal?/recur 1 1 (lambda (a b) #f))
   (equal?/recur '(1) '(1) (lambda (a b) #f))
   (equal?/recur '#(1 1 1) '#(1 1.2 3/4)
                 (lambda (a b) (<= (abs (- a b)) 0.25))))}


@defproc[
 (equal-always?/recur [v1 any/c] [v2 any/c] [recur-proc (any/c any/c . -> . any/c)])
 boolean?]{

 类似于 @racket[equal-always?]，但使用 @racket[recur-proc] 进行递归比较（这意味着引用循环不会自动处理）。来自 @racket[recur-proc] 的非 @racket[#f] 结果在由 @racket[equal-always?/recur] 返回之前被转换为 @racket[#t]。

 @(examples
   (equal-always?/recur 1 1 (lambda (a b) #f))
   (equal-always?/recur '(1) '(1) (lambda (a b) #f))
   (equal-always?/recur (vector-immutable 1 1 1) (vector-immutable 1 1.2 3/4)
                        (lambda (a b) (<= (abs (- a b)) 0.25))))}


@section[#:tag "model-eq"]{对象标识与比较}


@racket[eq?] 运算符比较两个 @tech{values}，当值引用相同的 @tech{object} 时返回 @racket[#t]。这种相等性形式适用于比较支持命令式更新的对象（例如，确定通过一个引用修改对象的效果通过另一个引用可见）。此外，@racket[eq?] 测试求值很快，在 hash table 中基于 @racket[eq?] 的哈希比基于 @racket[equal?] 的哈希更轻量。

然而，在某些情况下，@racket[eq?] 不适合作为比较运算符，因为 @tech{objects} 的生成没有明确定义。特别是，对相同的两个精确整数应用两次 @racket[+] 可能产生也可能不产生 @racket[eq?] 的结果，尽管结果始终是 @racket[equal?]。类似地，对 @racket[lambda] 形式的求值通常生成新的过程 @tech{object}，但它可能重用先前由相同源码 @racket[lambda] 形式生成的过程 @tech{object}。

数据类型关于 @racket[eq?] 的行为通常随该数据类型及其关联过程一起指定。


@section{相等性与哈希}


所有可比较的值至少有一个 @deftech{hash code}——一个通过对值应用哈希函数计算出的任意整数（更具体地说是 @tech{fixnum}）。这些哈希码的定义属性是@bold{相等的值具有相等的哈希码}。注意反过来并不成立：两个不相等的值仍然可以有相等的哈希码。哈希码对各种索引和比较操作很有用，特别是在 @tech{hash tables} 的实现中。更多信息参见 @secref["hashtables"]。


@defproc[(equal-hash-code [v any/c]) fixnum?]{

 返回与 @racket[equal?] 一致的 @tech{hash code}。对于任意两次使用 @racket[equal?] 值的调用，返回的数字相同。即使 @racket[v] 包含通过对、向量、box 和/或可检查结构字段的循环，也能计算哈希码。此外，用户定义的数据类型可以通过实现 @racket[gen:equal+hash] 或 @racket[gen:equal-mode+hash] 来自定义如何计算此哈希码。

 对于任何可能由 @racket[read] 产生的 @racket[v]，如果 @racket[v2] 是由 @racket[read] 对相同输入字符产生的，则 @racket[(equal-hash-code v)] 与 @racket[(equal-hash-code v2)] 相同——即使 @racket[v] 和 @racket[v2] 不同时存在（因此无法通过调用 @racket[equal?] 进行比较）。

 @history[
 #:changed "6.4.0.12"
 @elem{Strengthened guarantee for @racket[read]able values.}]}

@defproc[(equal-hash-code/recur [v any/c] [recur-proc (-> any/c exact-integer?)])
         fixnum?]{
 类似于 @racket[equal-hash-code]，但使用 @racket[recur-proc] 对 @racket[v] 内部进行递归哈希。

 @examples[
   (define (rational-hash x)
     (cond
       [(rational? x) (equal-hash-code (inexact->exact x))]
       [else (equal-hash-code/recur x rational-hash)]))
   (= (rational-hash 0.0) (rational-hash -0.0))
   (= (rational-hash 1.0) (rational-hash -1.0))
   (= (rational-hash (list (list (list 4.0 0.0) 9.0) 6.0))
      (rational-hash (list (list (list 4 0) 9) 6)))
 ]

 @history[#:added "8.8.0.9"]}

@defproc[(equal-secondary-hash-code [v any/c]) fixnum?]{

 类似于 @racket[equal-hash-code]，但计算适用于双重哈希的辅助 @tech{hash code}。}


@defproc[(equal-always-hash-code [v any/c]) fixnum?]{

 返回与 @racket[equal-always?] 一致的 @tech{hash code}。对于任意两次使用 @racket[equal-always?] 值的调用，返回的数字相同。

 当 @racket[equal-always-hash-code] 遍历 @racket[v] 时，@racket[v] 中的不可变值使用 @racket[equal-hash-code] 哈希，而 @racket[v] 中的可变值使用 @racket[eq-hash-code] 哈希。}


@defproc[(equal-always-hash-code/recur [v any/c]
                                       [recur-proc (-> any/c exact-integer?)])
         fixnum?]{
 类似于 @racket[equal-always-hash-code]，但使用 @racket[recur-proc] 对 @racket[v] 内部进行递归哈希。

 @history[#:added "8.8.0.9"]}

@defproc[(equal-always-secondary-hash-code [v any/c]) fixnum?]{

 类似于 @racket[equal-always-hash-code]，但计算适用于双重哈希的辅助 @tech{hash code}。}


@defproc[(eq-hash-code [v any/c]) fixnum?]{

 返回与 @racket[eq?] 一致的 @tech{hash code}。对于任意两次使用 @racket[eq?] 值的调用，返回的数字相同。

 @margin-note{相等的 @tech{fixnums} 始终是 @racket[eq?]。}}


@defproc[(eqv-hash-code [v any/c]) fixnum?]{

 返回与 @racket[eqv?] 一致的 @tech{hash code}。对于任意两次使用 @racket[eqv?] 值的调用，返回的数字相同。}


@section{为自定义类型实现相等性}


@defthing[gen:equal+hash any/c]{
 一个 @tech{generic interface}（参见 @secref["struct-generics"]），用于可以使用 @racket[equal?] 进行相等性比较的类型。必须实现以下方法：

 @itemize[

 @item{@racket[_equal-proc :
               (any/c any/c (any/c any/c . -> . boolean?)  . -> . any/c)] ——
   测试前两个参数是否相等，其中两个值都是与此 generic interface 关联的结构类型（或该结构类型的子类型）的实例。

   第三个参数是用于递归相等性检查的 @racket[equal?] 谓词；使用给定的谓词而不是 @racket[equal?] 以确保正确处理数据循环并与 @racket[equal?/recur] 配合工作（但要注意，可以向 @racket[equal?/recur] 提供任意函数进行递归检查，这意味着提供给谓词的参数可能暴露给任意代码）。

   @racket[_equal-proc] 仅在一对结构不是 @racket[eq?] 时，并且仅当它们都具有从相同结构类型继承的 @racket[gen:equal+hash] 值时才会被调用。通过此策略，@racket[equal?] 接收两个结构的顺序无关紧要。这也意味着，默认情况下，结构子类型继承其父类型的相等性谓词（如果有的话）。}

 @item{@racket[_hash-proc :
               (any/c (any/c . -> . exact-integer?) . -> . exact-integer?)] ——
   为给定结构计算哈希码，类似于 @racket[equal-hash-code]。
   第一个参数是与 generic interface 关联的结构类型（或其子类型之一）的实例。

   第二个参数是一个类似 @racket[equal-hash-code] 的过程，用于递归哈希码计算；使用给定的过程而不是 @racket[equal-hash-code] 以确保正确处理数据循环。

   虽然 @racket[_hash-proc] 的结果可以是任何精确整数，但在大多数情况下它会被截断为 @tech{fixnum}（例如，对于 @racket[equal-hash-code] 的结果）。大致上，截断使用 @racket[bitwise-and] 取数字的低位。因此，哈希码计算中的变化应反映在 @racket[_hash-proc] 结果的 fixnum 兼容位中。哈希码的消费者应在 fixnum 范围内适当地使用变化，而生产者@emph{不}负责在适合 fixnum 的完整位范围内反映哈希码的变化。}

 @item{@racket[_hash2-proc :
               (any/c (any/c . -> . exact-integer?) . -> . exact-integer?)] ——
   为给定结构计算辅助哈希码。此过程类似于 @racket[_hash-proc]，但类比于 @racket[equal-secondary-hash-code]。}]

 注意确保 @racket[_hash-proc] 和 @racket[_hash2-proc] 与 @racket[_equal-proc] 一致。具体来说，对于 @racket[_equal-proc] 产生真值的任意两个结构，@racket[_hash-proc] 和 @racket[_hash2-proc] 应该产生相同的值。

 @racket[_equal-proc] 不仅用于 @racket[equal?]，还用于 @racket[equal?/recur] 和 @racket[impersonator-of?]。此外，如果结构类型没有可变字段，@racket[_equal-proc] 也用于 @racket[equal-always?] 和 @racket[chaperone-of?]。同样，当结构类型没有可变字段时，@racket[_hash-proc] 和 @racket[_hash2-proc] 分别用于 @racket[equal-always-hash-code] 和 @racket[equal-always-secondary-hash-code]。这些方法的实例应遵循 @secref["Honest_Custom_Equality"] 中的指南，以合理地实现所有这些操作。特别是，除非 struct 被声明为可变的，否则这些方法不应访问可变数据。

 当结构类型没有 @racket[gen:equal+hash] 或 @racket[gen:equal-mode+hash] 实现时，透明结构（即具有受当前 @tech{inspector} 控制的 @tech{inspector} 的结构）当它们是相同结构类型（不计入子类型）的实例且具有 @racket[equal?] 的字段值时是 @racket[equal?]。对于透明结构，@racket[equal-hash-code] 和 @racket[equal-secondary-hash-code]（在没有可变字段的情况下）使用字段值推导哈希码。对于至少有一个可变字段的透明结构类型，@racket[equal-always?] 与 @racket[eq?] 相同，@racket[equal-secondary-hash-code] 结果仅基于 @racket[eq-hash-code]。对于不透明结构类型，@racket[equal?] 与 @racket[eq?] 相同，@racket[equal-hash-code] 和 @racket[equal-secondary-hash-code] 结果仅基于 @racket[eq-hash-code]。如果结构具有 @racket[prop:impersonator-of] 属性，则当将该属性值的过程应用于结构时返回非 @racket[#f] 值，则 @racket[prop:impersonator-of] 属性优先于 @racket[gen:equal+hash]。

 @(examples
   (eval:no-prompt
    (define (farm=? farm1 farm2 recursive-equal?)
      (and (= (farm-apples farm1)
              (farm-apples farm2))
           (= (farm-oranges farm1)
              (farm-oranges farm2))
           (= (farm-sheep farm1)
              (farm-sheep farm2))))

    (define (farm-hash-code farm recursive-equal-hash)
      (+ (* 10000 (farm-apples farm))
         (* 100 (farm-oranges farm))
         (* 1 (farm-sheep farm))))

    (define (farm-secondary-hash-code farm recursive-equal-hash)
      (+ (* 10000 (farm-sheep farm))
         (* 100 (farm-apples farm))
         (* 1 (farm-oranges farm))))

    (struct farm (apples oranges sheep)
      #:methods gen:equal+hash
      [(define equal-proc farm=?)
       (define hash-proc  farm-hash-code)
       (define hash2-proc farm-secondary-hash-code)])

    (define eastern-farm (farm 5 2 20))
    (define western-farm (farm 18 6 14))
    (define northern-farm (farm 5 20 20))
    (define southern-farm (farm 18 6 14)))

   (equal? eastern-farm western-farm)
   (equal? eastern-farm northern-farm)
   (equal? western-farm southern-farm))

 @history[#:changed "8.7.0.5"
          @elem{Added a check so that omitting any of
                @racket[_equal-proc], @racket[_hash-proc], and @racket[_hash2-proc]
                is now a syntax error.}]}


@defthing[gen:equal-mode+hash any/c]{
 一个 @tech{generic interface}（参见 @secref["struct-generics"]），用于可能指定 @racket[equal?] 和 @racket[equal-always?] 之间差异的类型。必须实现以下方法：

 @itemlist[

 @item{@racket[_equal-mode-proc :
               (any/c any/c (any/c any/c . -> . boolean?) boolean? . -> . any/c)] ——
   前两个参数是要比较的值，第三个参数是用于递归比较的相等性函数，最后一个参数是模式：@racket[#t] 表示 @racket[equal?] 或 @racket[impersonator-of?] 比较，@racket[#f] 表示 @racket[equal-always?] 或 @racket[chaperone-of?] 比较。}

 @item{@racket[_hash-mode-proc :
               (any/c (any/c . -> . exact-integer?) boolean? . -> . exact-integer?)] ——
   第一个参数是要计算哈希码的值，第二个参数是用于递归哈希的哈希函数，最后一个参数是模式：@racket[#t] 表示 @racket[equal?] 哈希，@racket[#f] 表示 @racket[equal-always?] 哈希。}]

 @racket[_hash-mode-proc] 实现同时用于主哈希码和辅助哈希码。

 实现这些方法时，请遵循 @secref["Honest_Custom_Equality"] 中的指南。特别是，仅当 "mode" 参数为真以指示 @racket[equal?] 或 @racket[impersonator-of?] 时，这些方法才应访问可变数据。

 实现 @racket[gen:equal-mode+hash] 对于指定 @racket[equal?] 和 @racket[equal-always?] 之间差异的类型最有用，例如使用 getter 和 setter 过程包装可变数据的结构类型：
 @(examples
   (define (get gs) ((getset-getter gs)))
   (define (set gs new) ((getset-setter gs) new))
   (struct getset (getter setter)
      #:methods gen:equal-mode+hash
      [(define (equal-mode-proc self other rec mode)
         (and mode (rec (get self) (get other))))
       (define (hash-mode-proc self rec mode)
         (if mode (rec (get self)) (eq-hash-code self)))])

   (define x 1)
   (define y 2)
   (define gsx (getset (lambda () x) (lambda (new) (set! x new))))
   (define gsy (getset (lambda () y) (lambda (new) (set! y new))))
   (eval:check (equal? gsx gsy) #f)
   (eval:check (equal-always? gsx gsy) #f)
   (set gsx 3)
   (set gsy 3)
   (eval:check (equal? gsx gsy) #t)
   (eval:check (equal-always? gsx gsy) #f)
   (eval:check (equal-always? gsx gsx) #t))

@history[#:added "8.5.0.3"
         #:changed "8.7.0.5"
         @elem{Added a check so that omitting either
               @racket[_equal-mode-proc] or @racket[_hash-mode-proc]
               is now a syntax error.}]}


@defthing[prop:equal+hash struct-type-property?]{

 一个 @tech{structure type property}（参见 @secref["structprops"]），为结构类型提供相等性谓词和哈希函数。使用 @racket[prop:equal+hash] 属性是使用 @racket[gen:equal+hash] 或 @racket[gen:equal-mode+hash] @tech{generic interface} 的替代方案。

 @racket[prop:equal+hash] 属性值是一个列表，包含三个过程 @racket[(list _equal-proc _hash-proc _hash2-proc)] 或两个过程 @racket[(list _equal-mode-proc _hash-mode-proc)]：

 @itemlist[

  @item{三过程情况对应于 @racket[gen:equal+hash] 的过程：

         @itemlist[
           @item{@racket[_equal-proc : (any/c any/c (any/c any/c . -> . boolean?)  . -> . any/c)]}

           @item{@racket[_hash-proc : (any/c (any/c . -> . exact-integer?) . -> . exact-integer?)]}

           @item{@racket[_hash2-proc : (any/c (any/c . -> . exact-integer?) . -> . exact-integer?)]}
        ]}

  @item{两过程情况对应于 @racket[gen:equal-mode+hash] 的过程：

       @itemlist[
         @item{@racket[_equal-mode-proc : (any/c any/c (any/c any/c . -> . boolean?) boolean? . -> . any/c)]}

          @item{@racket[_hash-mode-proc : (any/c (any/c . -> . exact-integer?) boolean? . -> . exact-integer?)]}

        ]}

]

实现这些方法时，请遵循 @secref["Honest_Custom_Equality"] 中的指南。特别是，仅当 struct 被声明为可变或 mode 为真时，这些方法才应访问可变数据。

@history[#:changed "8.5.0.3" @elem{Added support for two-procedure values to customize @racket[equal-always?].}]}

@section[#:tag "Honest_Custom_Equality"]{诚实的自定义相等性}

由于 @racket[_equal-proc] 或 @racket[_equal-mode-proc] 不仅仅用于 @racket[equal?]，它们的实例应遵循某些指南以确保它们对 @racket[equal-always?]、@racket[chaperone-of?] 和 @racket[impersonator-of?] 正确工作。

由于这些操作之间的差异，应避免在其中调用 @racket[equal?]。而是使用第三个参数对各个部分进行"递归"，这允许 @racket[equal?/recur] 正常工作，让其他操作以各自独特的方式处理各个部分，并启用某些循环检测。

@compare0[
@racketblock0[
  (define (equal-proc self other rec)
    (rec (fish-size self) (fish-size other)))
]

@racketblock0[
  (define (equal-proc self other rec)
    (equal? (fish-size self) (fish-size other)))
]
]

不要使用第三个参数对元素计数进行"递归"。当数据结构关心离散数字时，可以使用 @racket[=] 处理这些数字，而不是 @racket[equal?] 或"递归"。当来自 @racket[equal?/recur] 的"recur"参数对在彼此某个范围内的数字过于宽容时，在计数上使用"recur"是不好的。

@compare0[
@racketblock0[
  (define (equal-proc self other rec)
    (and (= (tuple-length self) (tuple-length other))
         (for/and ([i (in-range (tuple-length self))])
           (rec ((tuple-getter self) i)
                ((tuple-getter other) i)))))
]

@racketblock0[
  (define (equal-proc self other rec)
    (and (rec (tuple-length self) (tuple-length other))
         (for/and ([i (in-range (tuple-length self))])
           (rec ((tuple-getter self) i)
                ((tuple-getter other) i)))))
]
]

@racket[equal?] 和 @racket[equal-always?] 操作应该是对称的，因此 @racket[_equal-proc] 实例在参数交换时不应改变其答案：

@compare0[
@racketblock0[
  (define (equal-proc self other rec)
    (rec (fish-size self) (fish-size other)))
]

@racketblock0[
  (define (equal-proc self other rec)
    (<= (fish-size self) (fish-size other)))
]
]

然而，@racket[chaperone-of?] 和 @racket[impersonator-of?] 操作@emph{不}是对称的，因此在对各个部分调用第三个参数进行"递归"时，应按它们传入的顺序传递各个部分：

@compare0[
@racketblock0[
  (define (equal-proc self other rec)
    (rec (fish-size self) (fish-size other)))
]

@racketblock0[
  (define (equal-proc self other rec)
    (rec (fish-size other) (fish-size self)))
]
]

@racket[equal-always?] 和 @racket[chaperone-of?] 操作不应因修改而改变，因此 @racket[_equal-proc] 实例不应访问可能可变的数据。这包括避免使用 @racket[string=?]，因为字符串可以是可变的。不可变类型的类型特定相等性函数，如 @racket[symbol=?]，是可以的。

@compare0[#:left "fine" #:right "bad"
@racketblock0[
  (define (equal-proc self other rec)
    (code:comment "symbols are immutable: no problem")
    (symbol=? (thing-name self) (thing-name other)))
]

@racketblock0[
  (define (equal-proc self other rec)
    (code:comment "strings can be mutable: accesses mutable data")
    (string=? (thing-name self) (thing-name other)))
]
]

将 struct 声明为可变会使 @racket[equal-always?] 和 @racket[chaperone-of?] 避免使用 @racket[_equal-proc]，因此如果 struct 被声明为可变，@racket[_equal-proc] 实例可以自由访问可变数据：

@compare0[
@racketblock0[
  (struct mcell (value) #:mutable
    #:methods gen:equal+hash
    [(define (equal-proc self other rec)
       (rec (mcell-value self)
            (mcell-value other)))
     (define (hash-proc self rec)
       (+ (eq-hash-code struct:mcell)
          (rec (mcell-value self))))
     (define (hash2-proc self rec)
       (+ (eq-hash-code struct:mcell)
          (rec (mcell-value self))))])
]

@racketblock0[
  (struct mcell (box)
    (code:comment "not declared mutable,")
    (code:comment "but represents mutable data anyway")
    #:methods gen:equal+hash
    [(define (equal-proc self other rec)
       (rec (unbox (mcell-box self))
            (unbox (mcell-box other))))
     (define (hash-proc self rec)
       (+ (eq-hash-code struct:mcell)
          (rec (unbox (mcell-value self)))))
     (define (hash2-proc self rec)
       (+ (eq-hash-code struct:mcell)
          (rec (unbox (mcell-value self)))))])
]
]

struct 控制可变数据访问的另一种方式是实现 @racket[gen:equal-mode+hash] 而不是 @racket[gen:equal+hash]。当 mode 为真时，@racket[_equal-mode-proc] 实例可以自由访问可变数据，当 mode 为假时，它们不应这样做：

@compare0[#:left "also good" #:right "still bad"
@racketblock0[
  (struct mcell (value) #:mutable
    (code:comment "only accesses mutable data when mode is true")
    #:methods gen:equal-mode+hash
    [(define (equal-mode-proc self other rec mode)
       (and mode
            (rec (mcell-value self)
                 (mcell-value other))))
     (define (hash-mode-proc self rec mode)
       (if mode
           (+ (eq-hash-code struct:mcell)
              (rec (mcell-value self)))
           (eq-hash-code self)))])
]

@racketblock0[
  (struct mcell (value) #:mutable
    (code:comment "accesses mutable data ignoring mode")
    #:methods gen:equal-mode+hash
    [(define (equal-mode-proc self other rec mode)
       (rec (mcell-value self)
            (mcell-value other)))
     (define (hash-mode-proc self rec mode)
       (+ (eq-hash-code struct:mcell)
          (rec (mcell-value self))))])
]
]

@section{组合哈希码}

@note-lib-only[racket/hash-code]

@history[#:added "8.8.0.5"]

@defproc[(hash-code-combine [hc exact-integer?] ...) fixnum?]{
  将 @racket[hc] 组合成一个依赖于输入顺序的 @tech{hash code}。
  适用于组合结构中不同字段的哈希码。

  @examples[
    (require racket/hash-code)
    (struct ordered-triple (fst snd thd)
      #:methods gen:equal+hash
      [(define (equal-proc self other rec)
         (and (rec (ordered-triple-fst self) (ordered-triple-fst other))
              (rec (ordered-triple-snd self) (ordered-triple-snd other))
              (rec (ordered-triple-thd self) (ordered-triple-thd other))))
       (define (hash-proc self rec)
         (hash-code-combine (eq-hash-code struct:ordered-triple)
                            (rec (ordered-triple-fst self))
                            (rec (ordered-triple-snd self))
                            (rec (ordered-triple-thd self))))
       (define (hash2-proc self rec)
         (hash-code-combine (eq-hash-code struct:ordered-triple)
                            (rec (ordered-triple-fst self))
                            (rec (ordered-triple-snd self))
                            (rec (ordered-triple-thd self))))])
    (equal? (ordered-triple 'A 'B 'C) (ordered-triple 'A 'B 'C))
    (= (equal-hash-code (ordered-triple 'A 'B 'C))
       (equal-hash-code (ordered-triple 'A 'B 'C)))
    (equal? (ordered-triple 'A 'B 'C) (ordered-triple 'C 'B 'A))
    (= (equal-hash-code (ordered-triple 'A 'B 'C))
       (equal-hash-code (ordered-triple 'C 'B 'A)))
    (equal? (ordered-triple 'A 'B 'C) (ordered-triple 'C 'A 'B))
    (= (equal-hash-code (ordered-triple 'A 'B 'C))
       (equal-hash-code (ordered-triple 'C 'A 'B)))
  ]

  使用一个参数时，@racket[(hash-code-combine hc)] 会混合哈希码，使其不仅仅是 @racket[hc]。

  @examples[
    (require racket/hash-code)
    (struct wrap (value)
      #:methods gen:equal+hash
      [(define (equal-proc self other rec)
         (rec (wrap-value self) (wrap-value other)))
       (define (hash-proc self rec)
         (code:comment "demonstrates `hash-code-combine` with only one argument")
         (code:comment "but it's good to combine `(eq-hash-code struct:wrap)` too")
         (hash-code-combine (rec (wrap-value self))))
       (define (hash2-proc self rec)
         (hash-code-combine (rec (wrap-value self))))])
    (equal? (wrap 'A) (wrap 'A))
    (= (equal-hash-code (wrap 'A))
       (equal-hash-code (wrap 'A)))
    (equal? (wrap 'A) 'A)
    (= (equal-hash-code (wrap 'A))
       (equal-hash-code 'A))
  ]
}

@defproc[(hash-code-combine-unordered [hc exact-integer?] ...) fixnum?]{
  将 @racket[hc] 组合成一个@emph{不}依赖于输入顺序的 @tech{hash code}。
  适用于组合无序集合元素的哈希码。

  @examples[
    (require racket/hash-code)
    (struct flip-triple (left mid right)
      #:methods gen:equal+hash
      [(define (equal-proc self other rec)
         (and (rec (flip-triple-mid self) (flip-triple-mid other))
              (or
               (and (rec (flip-triple-left self) (flip-triple-left other))
                    (rec (flip-triple-right self) (flip-triple-right other)))
               (and (rec (flip-triple-left self) (flip-triple-right other))
                    (rec (flip-triple-right self) (flip-triple-left other))))))
       (define (hash-proc self rec)
         (hash-code-combine (eq-hash-code struct:flip-triple)
                            (rec (flip-triple-mid self))
                            (hash-code-combine-unordered
                             (rec (flip-triple-left self))
                             (rec (flip-triple-right self)))))
       (define (hash2-proc self rec)
         (hash-code-combine (eq-hash-code struct:flip-triple)
                            (rec (flip-triple-mid self))
                            (hash-code-combine-unordered
                             (rec (flip-triple-left self))
                             (rec (flip-triple-right self)))))])
    (equal? (flip-triple 'A 'B 'C) (flip-triple 'A 'B 'C))
    (= (equal-hash-code (flip-triple 'A 'B 'C))
       (equal-hash-code (flip-triple 'A 'B 'C)))
    (equal? (flip-triple 'A 'B 'C) (flip-triple 'C 'B 'A))
    (= (equal-hash-code (flip-triple 'A 'B 'C))
       (equal-hash-code (flip-triple 'C 'B 'A)))
    (equal? (flip-triple 'A 'B 'C) (flip-triple 'C 'A 'B))
    (= (equal-hash-code (flip-triple 'A 'B 'C))
       (equal-hash-code (flip-triple 'C 'A 'B)))
    (struct rotate-triple (rock paper scissors)
      #:methods gen:equal+hash
      [(define (equal-proc self other rec)
         (or
          (and (rec (rotate-triple-rock self) (rotate-triple-rock other))
               (rec (rotate-triple-paper self) (rotate-triple-paper other))
               (rec (rotate-triple-scissors self) (rotate-triple-scissors other)))
          (and (rec (rotate-triple-rock self) (rotate-triple-paper other))
               (rec (rotate-triple-paper self) (rotate-triple-scissors other))
               (rec (rotate-triple-scissors self) (rotate-triple-rock other)))
          (and (rec (rotate-triple-rock self) (rotate-triple-scissors other))
               (rec (rotate-triple-paper self) (rotate-triple-rock other))
               (rec (rotate-triple-scissors self) (rotate-triple-paper other)))))
       (define (hash-proc self rec)
         (define r (rec (rotate-triple-rock self)))
         (define p (rec (rotate-triple-paper self)))
         (define s (rec (rotate-triple-scissors self)))
         (hash-code-combine
          (eq-hash-code struct:rotate-triple)
          (hash-code-combine-unordered
           (hash-code-combine r p)
           (hash-code-combine p s)
           (hash-code-combine s r))))
       (define (hash2-proc self rec)
         (define r (rec (rotate-triple-rock self)))
         (define p (rec (rotate-triple-paper self)))
         (define s (rec (rotate-triple-scissors self)))
         (hash-code-combine
          (eq-hash-code struct:rotate-triple)
          (hash-code-combine-unordered
           (hash-code-combine r p)
           (hash-code-combine p s)
           (hash-code-combine s r))))])
    (equal? (rotate-triple 'A 'B 'C) (rotate-triple 'A 'B 'C))
    (= (equal-hash-code (rotate-triple 'A 'B 'C))
       (equal-hash-code (rotate-triple 'A 'B 'C)))
    (equal? (rotate-triple 'A 'B 'C) (rotate-triple 'C 'B 'A))
    (= (equal-hash-code (rotate-triple 'A 'B 'C))
       (equal-hash-code (rotate-triple 'C 'B 'A)))
    (equal? (rotate-triple 'A 'B 'C) (rotate-triple 'C 'A 'B))
    (= (equal-hash-code (rotate-triple 'A 'B 'C))
       (equal-hash-code (rotate-triple 'C 'A 'B)))
  ]
}

@defproc[(hash-code-combine* [hc exact-integer?] ...
                             [hcs (listof exact-integer?)])
         fixnum?]{
  @; Note: this is exactly the same description as append* and string-append*

  类似于 @racket[hash-code-combine]，但最后一个参数用作 @racket[hash-code-combine] 的参数列表，
  因此 @racket[(hash-code-combine* hc ... hcs)] 等同于 @racket[(apply hash-code-combine hc ... hcs)]。
  换句话说，@racket[hash-code-combine] 和 @racket[hash-code-combine*] 之间的关系类似于 @racket[list] 和 @racket[list*] 之间的关系。
}

@defproc[(hash-code-combine-unordered* [hc exact-integer?] ...
                                       [hcs (listof exact-integer?)])
         fixnum?]{
  @; Note: this is exactly the same description as append* and string-append*

  类似于 @racket[hash-code-combine-unordered]，但最后一个参数用作 @racket[hash-code-combine-unordered] 的参数列表，
  因此 @racket[(hash-code-combine-unordered* hc ... hcs)] 等同于 @racket[(apply hash-code-combine-unordered hc ... hcs)]。
  换句话说，@racket[hash-code-combine-unordered] 和 @racket[hash-code-combine-unordered*] 之间的关系类似于 @racket[list] 和 @racket[list*] 之间的关系。
}
