#lang scribble/doc
@(require "mz.rkt" scribble/scheme racket/generator racket/list
          (for-syntax racket/base)
          (for-label racket/list))

@(define (generate-c_r-example proc)
  (define (make-it start n)
    (generator ()
      (let loop ([start start]
                 [n n])
        (yield (list* n start))
        (yield (append start (list n)))
        (when (< (length (flatten start)) 8)
          (loop (list* n start) (add1 n))
          (loop (list start n) (add1 n))
          ))))
  (define (example proc)
    (define maker (make-it '() 1))
    (let loop ([value (maker)])
      (with-handlers ([exn? (lambda (e) (loop (maker)))])
        (proc value)
        value)))
  (example proc))

@(define-syntax (defc_r stx)
   (syntax-case stx ()
     [(_ x ... example-arg)
      (let ([xs (map syntax-e (syntax->list #'(x ...)))])
        (let ([name (string->symbol
                     (string-append
                      "c"
                      (apply string-append (map symbol->string xs))
                      "r"))]
              [contract (let loop ([l (reverse xs)])
                          (cond
                            [(null? (cdr l)) 'pair?]
                            [(eq? (car l) 'a) `(cons/c ,(loop (cdr l)) any/c)]
                            [(eq? (car l) 'd) `(cons/c any/c ,(loop (cdr l)))]))]
              [equiv (let loop ([l xs])
                       (cond
                         [(null? l) 'v]
                         [(eq? (car l) 'a) #`(car #,(loop (cdr l)))]
                         [(eq? (car l) 'd) #`(cdr #,(loop (cdr l)))]))])
          (with-syntax ([name name]
                        [contract (let loop ([c contract] [pos 0])
                                    (if (pair? c)
                                      (let* ([a (loop (car c) (add1 pos))]
                                             [b (loop (cdr c) (+ 1 pos (syntax-span a)))]
                                             [span (+ 1 (syntax-span a) (syntax-span b))])
                                        (datum->syntax #'here
                                                       (cons a b)
                                                       (list (syntax-source stx)
                                                             1
                                                             pos
                                                             (add1 pos)
                                                             span)))
                                      (datum->syntax #'here c
                                                     (list (syntax-source stx) 1 pos (add1 pos) 1))))]
                        [example (let ([ex #'example-arg])
                                   (datum->syntax #'here
                                                  (list
                                                   (datum->syntax #'here
                                                                  name
                                                                  (vector (syntax-source ex)
                                                                          (syntax-line ex)
                                                                          (- (syntax-column ex) 2)
                                                                          (- (syntax-position ex) 2)
                                                                          1))
                                                   ex)
                                                  (vector (syntax-source ex)
                                                          (syntax-line ex)
                                                          (- (syntax-column ex) 3)
                                                          (- (syntax-position ex) 3)
                                                          (+ (syntax-span ex) 4))))]
                        [equiv equiv])
            #'(defproc (name [v contract]) any/c
                "Returns " (racket equiv) "." (mz-examples example)))))]))


@title[#:tag "pairs"]{Pairs and Lists}

@guideintro["pairs"]{pairs and lists}

一个 @deftech{pair}（对）恰好组合了两个值。第一个值通过 @racket[car] 过程访问，第二个值通过 @racket[cdr] 过程访问。pair 是不可变的（但参见 @secref["mpairs"]）。

@deftech{list}（列表）是递归定义的：它要么是常量 @racket[null]，要么是一个第二个值为 list 的 pair。

list 可以用作单值序列（参见 @secref["sequences"]）。list 的元素作为序列的元素使用。另见 @racket[in-list]。

通过 @racket[read] 或 @racket[make-reader-graph]，可以仅使用不可变 pair 创建循环数据结构。如果从一个 pair 开始并使用若干 @racket[cdr] 后回到起始 pair，则该 pair 不是 list。

@see-read-print["pair" #:print "pairs"]{pairs and lists}


@; ----------------------------------------
@section{Pair Constructors and Selectors}

@defproc[(pair? [v any/c])
         boolean?]{

如果 @racket[v] 是 pair 则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[
  (pair? 1)
  (pair? (cons 1 2))
  (pair? (list 1 2))
  (pair? '(1 2))
  (pair? '())]}


@defproc[(null? [v any/c])
         boolean?]{

如果 @racket[v] 是空 list 则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[
  (null? 1)
  (null? '(1 2))
  (null? '())
  (null? (cdr (list 1)))]}


@defproc[(cons [a any/c] [d any/c])
         pair?]{

返回一个新分配的 pair，其第一个元素为 @racket[a]，第二个元素为 @racket[d]。

@mz-examples[
  (cons 1 2)
  (cons 1 '())]}


@defproc[(car [p pair?])
         any/c]{

返回 pair @racket[p] 的第一个元素。

@mz-examples[
  (car '(1 2))
  (car (cons 2 3))]}


@defproc[(cdr [p pair?])
         any/c]{

返回 pair @racket[p] 的第二个元素。

@mz-examples[
  (cdr '(1 2))
  (cdr '(1))]}


@defthing[null null?]{

  空 list。

  @mz-examples[
    null
    '()
    (eq? '() null)]}


@defproc[(list? [v any/c])
         boolean?]{

如果 @racket[v] 是 list 则返回 @racket[#t]：要么是空 list，要么是一个第二个元素是 list 的 pair。由于内部缓存，该过程实际上是常数时间的（因此任何必要的 pair 遍历原则上可以算作分配 pair 的额外开销）。

@mz-examples[
  (list? '(1 2))
  (list? (cons 1 (cons 2 '())))
  (list? (cons 1 2))]}


@defproc[(list [v any/c] ...)
         list?]{

返回一个新分配的 list，包含 @racket[v] 作为其元素。

@mz-examples[
  (list 1 2 3 4)
  (list (list 1 2) (list 3 4))]}


@defproc[(list* [v any/c] ... [tail any/c])
         any/c]{

类似于 @racket[list]，但最后一个参数用作结果的尾部，而不是最后一个元素。仅当最后一个参数是 list 时，结果才是 list。

@mz-examples[
 (list* 1 2)
 (list* 1 2 (list 3 4))]}


@defproc[(build-list [n exact-nonnegative-integer?]
                     [proc (exact-nonnegative-integer? . -> . any)])
         list?]{

通过按顺序对从 @racket[0] 到 @racket[(sub1 n)] 的整数应用 @racket[proc] 来创建一个包含 @racket[n] 个元素的 list。如果 @racket[_lst] 是结果 list，则 @racket[(list-ref _lst _i)] 是 @racket[(proc _i)] 产生的值。

@mz-examples[
  (build-list 10 values)
  (build-list 5 (lambda (x) (* x x)))]}


@; ----------------------------------------
@section{List Operations}

@defproc[(length [lst list?])
         exact-nonnegative-integer?]{

返回 @racket[lst] 中元素的数量。此函数的时间与该长度成正比。

@mz-examples[
  (length (list 1 2 3 4))
  (length '())]}


@defproc[(list-ref [lst pair?] [pos exact-nonnegative-integer?])
         any/c]{

返回 @racket[lst] 中位置 @racket[pos] 处的元素，其中 list 的第一个元素位于位置 @racket[0]。如果 list 的元素数量不超过 @racket[pos]，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是 list；@racket[lst] 只需以至少 @racket[(add1 pos)] 个 pair 的链开始。

此函数的时间与 @racket[pos] 成正比。

@mz-examples[
  (list-ref (list 'a 'b 'c) 0)
  (list-ref (list 'a 'b 'c) 1)
  (list-ref (list 'a 'b 'c) 2)
  (list-ref (cons 1 2) 0)
  (eval:error (list-ref (cons 1 2) 1))]}


@defproc[(list-tail [lst any/c] [pos exact-nonnegative-integer?])
         any/c]{

返回 @racket[lst] 中前 @racket[pos] 个元素之后的 list。如果 list 的元素少于 @racket[pos] 个，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是 list；@racket[lst] 只需以至少 @racket[pos] 个 pair 的链开始。

此函数的时间与 @racket[pos] 成正比。

@mz-examples[
  (list-tail (list 1 2 3 4 5) 2)
  (list-tail (cons 1 2) 1)
  (eval:error (list-tail (cons 1 2) 2))
  (list-tail 'not-a-pair 0)]}


@defproc*[([(append [lst list?] ...) list?]
           [(append [lst list?] ... [v any/c]) any/c])]{

当所有参数都是 list 时，结果是一个按顺序包含所有给定 list 中元素的 list。最后一个参数直接用于结果的尾部。

最后一个参数不必是 list，在这种情况下结果是“非正规 list”（improper list）。

此函数的时间与除最后一个参数外所有参数的长度总和成正比。

@mz-examples[
  (append (list 1 2) (list 3 4))
  (append (list 1 2) (list 3 4) (list 5 6) (list 7 8))]}


@defproc[(reverse [lst list?]) list?]{

返回一个与 @racket[lst] 具有相同元素但顺序相反的 list。

此函数的时间与 @racket[lst] 的长度成正比。

@mz-examples[
  (reverse (list 1 2 3 4))]}


@; ----------------------------------------
@section{List Iteration}

@defproc[(map [proc procedure?] [lst list?] ...+)
         list?]{

对 @racket[lst] 的元素从第一个到最后一个依次应用 @racket[proc]。@racket[proc] 参数必须接受与提供的 @racket[lst] 数量相同的参数，且所有 @racket[lst] 必须具有相同数量的元素。结果是一个按顺序包含 @racket[proc] 每个结果的 list。

@mz-examples[
  (map (lambda (number)
         (+ 1 number))
       '(1 2 3 4))
  (map (lambda (number1 number2)
         (+ number1 number2))
       '(1 2 3 4)
       '(10 100 1000 10000))]}


@defproc[(andmap [proc procedure?] [lst list?] ...+)
          any]{

类似于 @racket[map]，即 @racket[proc] 被应用于 @racket[lst] 的每个元素，但

@margin-note{@racket[andmap] 函数实际上更接近 @racket[foldl] 而非 @racket[map]，因为 @racket[andmap] 不产生 list。不过，@racket[(andmap f (list x y z))] 等价于 @racket[(and (f x) (f y) (f z))]，其方式与 @racket[(map f (list x y z))] 等价于 @racket[(list (f x) (f y) (f z))] 相同。}

@itemize[

 @item{如果 @racket[proc] 的任何一次应用产生 @racket[#f]，则结果为 @racket[#f]，在这种情况下 @racket[proc] 不会被应用于 @racket[lst] 的后续元素；并且}

 @item{结果是 @racket[proc] 应用于 @racket[lst] 最后一组元素的值；更具体地说，@racket[proc] 应用于 @racket[lst] 最后一组元素相对于 @racket[andmap] 调用处于尾部位置。}]

如果 @racket[lst] 为空，则返回 @racket[#t]。

@mz-examples[
  (andmap positive? '(1 2 3))
  (eval:error (andmap positive? '(1 2 a)))
  (andmap positive? '(1 -2 a))
  (andmap + '(1 2 3) '(4 5 6))]}


@defproc[(ormap [proc procedure?] [lst list?] ...+)
         any]{

类似于 @racket[map]，即 @racket[proc] 被应用于 @racket[lst] 的每个元素，但

@margin-note{继续上面 @racket[andmap] 的注释，@racket[(ormap f (list x y z))] 等价于 @racket[(or (f x) (f y) (f z))]。}

@itemize[

 @item{如果 @racket[proc] 的每次应用都产生 @racket[#f]，则结果为 @racket[#f]；并且}

 @item{结果是 @racket[proc] 第一次产生非 @racket[#f] 值的应用结果，在这种情况下 @racket[proc] 不会被应用于 @racket[lst] 的后续元素；@racket[proc] 应用于 @racket[lst] 最后一组元素相对于 @racket[ormap] 调用处于尾部位置。}]

如果 @racket[lst] 为空，则返回 @racket[#f]。

@mz-examples[
  (ormap eq? '(a b c) '(a b c))
  (ormap positive? '(1 2 a))
  (ormap + '(1 2 3) '(4 5 6))]}


@defproc[(for-each [proc procedure?] [lst list?] ...+)
         void?]{

类似于 @racket[map]，但 @racket[proc] 仅为其副作用而被调用，其结果（可以是任意数量的值）被忽略。

@mz-examples[
  (for-each (lambda (arg)
              (printf "Got ~a\n" arg)
              23)
            '(1 2 3 4))]}


@defproc[(foldl [proc procedure?] [init any/c] [lst list?] ...+)
         any/c]{

类似于 @racket[map]，@racket[foldl] 将一个过程应用于一个或多个 list 的元素。@racket[map] 将返回值组合成一个 list，而 @racket[foldl] 以 @racket[proc] 决定的任意方式组合返回值。

如果使用 @math{n} 个 list 调用 @racket[foldl]，则 @racket[proc] 必须接受 @math{n+1} 个参数。额外的参数是到目前为止的组合返回值。@racket[proc] 最初以每个 list 的第一个元素调用，最后一个参数为 @racket[init]。在后续调用中，最后一个参数是 @racket[proc] 前一次调用的返回值。输入 @racket[lst] 从左到右遍历，整个 @racket[foldl] 应用的结果是 @racket[proc] 最后一次应用的结果。如果 @racket[lst] 为空，结果为 @racket[init]。

与 @racket[foldr] 不同，@racket[foldl] 在常数空间内处理 @racket[lst]（加上每次调用 @racket[proc] 的空间）。

@mz-examples[
  (foldl cons '() '(1 2 3 4))
  (foldl + 0 '(1 2 3 4))
  (foldl (lambda (a b result)
           (* result (- a b)))
         1
         '(1 2 3)
         '(4 5 6))]}


@defproc[(foldr [proc procedure?] [init any/c] [lst list?] ...+)
         any/c]{

类似于 @racket[foldl]，但 list 从右到左遍历。与 @racket[foldl] 不同，@racket[foldr] 处理 @racket[lst] 的空间与 @racket[lst] 的长度成正比（加上每次调用 @racket[proc] 的空间）。

@mz-examples[
  (foldr cons '() '(1 2 3 4))
  (foldr (lambda (v l) (cons (add1 v) l)) '() '(1 2 3 4))]}


@; ----------------------------------------
@section{List Filtering}

@defproc[(filter [pred procedure?] [lst list?])
         list?]{

返回一个包含 @racket[lst] 中 @racket[pred] 产生真值的元素的 list。@racket[pred] 过程按从第一个到最后一个的顺序应用于每个元素。

@mz-examples[
  (filter positive? '(1 -2 3 4 -5))]}


@defproc[(remove [v any/c] [lst list?] [proc procedure? equal?])
         list?]{

返回一个类似于 @racket[lst] 的 list，使用比较过程 @racket[proc]（必须接受两个参数），以 @racket[v] 作为第一个参数，@racket[lst] 中的元素作为第二个参数，省略 @racket[lst] 中第一个与 @racket[v] 相等的元素。如果 @racket[lst] 中没有元素与 @racket[v] 相等（根据 @racket[proc]），则原样返回 @racket[lst]。

@mz-examples[
  (remove 2 (list 1 2 3 2 4))
  (remove '(2) (list '(1) '(2) '(3)))
  (remove "2" (list "1" "2" "3"))
  (remove #\c (list #\a #\b #\c))
  (remove "B" (list "a" "A" "b" "B") string-ci=?)
  (remove 5 (list 1 2 3 2 4))]

@history[#:changed "8.2.0.2"
         @elem{保证如果没有发生移除，输出与 @racket[lst] 是 @racket[eq?] 的。}]}


@defproc[(remq [v any/c] [lst list?])
         list?]{

返回 @racket[(remove v lst eq?)]。

@mz-examples[
  (remq 2 (list 1 2 3 4 5))
  (remq '(2) (list '(1) '(2) '(3)))
  (remq "2" (list "1" "2" "3"))
  (remq #\c (list #\a #\b #\c))]}


@defproc[(remv [v any/c] [lst list?])
         list?]{

返回 @racket[(remove v lst eqv?)]。

@mz-examples[
  (remv 2 (list 1 2 3 4 5))
  (remv '(2) (list '(1) '(2) '(3)))
  (remv "2" (list "1" "2" "3"))
  (remv #\c (list #\a #\b #\c))]}


@defproc[(remw [v any/c] [lst list?])
         list?]{

返回 @racket[(remove v lst equal-always?)]。

@mz-examples[
  (remw 2 (list 1 2 3 4 5))
  (remw '(2) (list '(1) '(2) '(3)))
  (remw "2" (list "1" "2" "3"))
  (remw #\c (list #\a #\b #\c))
  (define b1 (box 5))
  (define b2 (box 5))
  (remw b2 (list 0 b1 1 b2 2))]

@history[#:added "8.5.0.3"]}


@defproc[(remove* [v-lst list?] [lst list?] [proc procedure? equal?])
         list?]{

类似于 @racket[remove]，但从 @racket[lst] 中移除 @racket[v-lst] 每个元素的每个实例。

@mz-examples[
  (remove* (list 1 2) (list 1 2 3 2 4 5 2))]

@history[#:changed "8.2.0.2"
         @elem{Guaranteed that the output is @racket[eq?] to @racket[lst]
               if no removal occurs.}]}


@defproc[(remq* [v-lst list?] [lst list?])
         list?]{

返回 @racket[(remove* v-lst lst eq?)]。

@mz-examples[
  (remq* (list 1 2) (list 1 2 3 2 4 5 2))]}


@defproc[(remv* [v-lst list?] [lst list?])
         list?]{

返回 @racket[(remove* v-lst lst eqv?)]。

@mz-examples[
  (remv* (list 1 2) (list 1 2 3 2 4 5 2))]}


@defproc[(remw* [v-lst list?] [lst list?])
         list?]{

返回 @racket[(remove* v-lst lst equal-always?)]。

@mz-examples[
  (remw* (list 1 2) (list 1 2 3 2 4 5 2))
  (define b1 (box 5))
  (define b2 (box 5))
  (remw* (list b2) (list 0 b1 1 b2 2 b2 3))]

@history[#:added "8.5.0.3"]}


@defproc[(sort [lst list?] [less-than? (any/c any/c . -> . any/c)]
               [#:key extract-key (any/c . -> . any/c) (lambda (x) x)]
               [#:cache-keys? cache-keys? boolean? #f])
         list?]{

返回按 @racket[less-than?] 过程排序的 list，该过程接受 @racket[lst] 的两个元素，如果第一个小于第二个（即应该排在前面）则返回真值。

排序是稳定的；如果 @racket[lst] 的两个元素“相等”（即 @racket[less-than?] 以任一顺序给定该对时均不返回真值），则这些元素在输出 list 中保持其相对于 @racket[lst] 的相对顺序。为保持此保证，请将 @racket[sort] 与严格比较函数（例如 @racket[<] 或 @racket[string<?]；而非 @racket[<=] 或 @racket[string<=?]）一起使用。

@margin-note{由于 IEEE-754 数字系统规定 +nan.0 既不大于也不小于也不等于任何其他数字这一特殊事实，排序包含此值的 list 可能会产生令人惊讶的结果。}

@racket[#:key] 参数 @racket[extract-key] 用于从每个 list 元素中提取用于比较的键值。也就是说，完整的比较过程本质上是

@racketblock[
  (lambda (x y)
    (less-than? (extract-key x) (extract-key y)))]

默认情况下，每次比较时 @racket[extract-key] 被应用于两个 list 元素，但如果 @racket[cache-keys?] 为真，则 @racket[extract-key] 函数对每个 list 项恰好使用一次。当 @racket[extract-key] 是开销较大的操作时，为 @racket[cache-keys?] 提供真值；例如，如果使用 @racket[file-or-directory-modify-seconds] 为 list 中的每个文件提取时间戳，则 @racket[cache-keys?] 应为 @racket[#t] 以最小化文件系统调用，但如果 @racket[extract-key] 是 @racket[car]，则 @racket[cache-keys?] 应为 @racket[#f]。再举一个例子，提供 @racket[extract-key] 为 @racket[(lambda (x) (random))] 并将 @racket[#t] 用于 @racket[cache-keys?] 实际上会打乱 list。}

@mz-examples[
  (sort '(1 3 4 2) <)
  (sort '("aardvark" "dingo" "cow" "bear") string<?)
  (sort '(("aardvark") ("dingo") ("cow") ("bear"))
        #:key car string<?)]


@; ----------------------------------------
@section{List Searching}

@defproc[(member [v any/c] [lst (or/c list? any/c)]
                 [is-equal? (any/c any/c -> any/c) equal?])
         (or/c #f list? any/c)]{

定位 @racket[lst] 中第一个与 @racket[v] @racket[equal?] 的元素。如果该元素存在，则返回从该元素开始的 @racket[lst] 的尾部。否则，结果为 @racket[#f]。

@racket[lst] 参数实际上不必是 list；@racket[lst] 只需以 pair 链开始直到找到匹配元素。如果未找到匹配元素，则 @racket[lst] 必须是 list（且不是循环 list）。如果找到元素且返回的 @racket[lst] 尾部不是 list，则结果可以是非 list。

@mz-examples[
  (member 2 (list 1 2 3 4))
  (member 9 (list 1 2 3 4))
  (member #'x (list #'x #'y) free-identifier=?)
  (member #'a (list #'x #'y) free-identifier=?)
  (member 'b '(a b . etc))]}


@defproc[(memw [v any/c] [lst (or/c list? any/c)])
         (or/c #f list? any/c)]{

类似于 @racket[member]，但使用 @racket[equal-always?] 查找元素。

@mz-examples[
  (memw 2 (list 1 2 3 4))
  (memw 9 (list 1 2 3 4))
  (define b1 (box 5))
  (define b2 (box 5))
  (memw b2 (list 0 b1 1 b2 2))]

@history[#:added "8.5.0.3"]}


@defproc[(memv [v any/c] [lst (or/c list? any/c)])
         (or/c #f list? any/c)]{

类似于 @racket[member]，但使用 @racket[eqv?] 查找元素。

@mz-examples[
  (memv 2 (list 1 2 3 4))
  (memv 9 (list 1 2 3 4))]}


@defproc[(memq [v any/c] [lst (or/c list? any/c)])
         (or/c #f list? any/c)]{

类似于 @racket[member]，但使用 @racket[eq?] 查找元素。

@mz-examples[
  (memq 2 (list 1 2 3 4))
  (memq 9 (list 1 2 3 4))]}


@defproc[(memf [proc procedure?] [lst (or/c list? any/c)])
         (or/c #f list? any/c)]{

类似于 @racket[member]，但使用谓词 @racket[proc] 查找元素；当 @racket[proc] 应用于该元素时返回真值则找到该元素。

@mz-examples[
  (memf (lambda (arg)
          (> arg 9))
        '(7 8 9 10 11))]}


@defproc[(findf [proc procedure?] [lst list?])
         any/c]{

类似于 @racket[memf]，但返回元素或 @racket[#f]，而不是 @racket[lst] 的尾部或 @racket[#f]。

@mz-examples[
  (findf (lambda (arg)
           (> arg 9))
         '(7 8 9 10 11))]}


@defproc[(assoc [v any/c]
                [lst (or/c (listof pair?) any/c)]
                [is-equal? (any/c any/c -> any/c) equal?])
         (or/c pair? #f)]{

根据 @racket[is-equal?] 定位 @racket[lst] 中第一个 @racket[car] 与 @racket[v] 相等的元素。如果该元素存在，则返回该 pair（即 @racket[lst] 的一个元素）。否则，结果为 @racket[#f]。

@racket[lst] 参数实际上不必是 pair 的 list；@racket[lst] 只需以包含 pair 的 pair 链开始直到找到匹配元素。如果未找到匹配元素，则 @racket[lst] 必须是 pair 的 list（且不是循环 list）。

@mz-examples[
  (assoc 3 (list (list 1 2) (list 3 4) (list 5 6)))
  (assoc 9 (list (list 1 2) (list 3 4) (list 5 6)))
  (assoc 3.5
         (list (list 1 2) (list 3 4) (list 5 6))
         (lambda (a b) (< (abs (- a b)) 1)))]}


@defproc[(assw [v any/c] [lst (or/c (listof pair?) any/c)])
         (or/c pair? #f)]{

类似于 @racket[assoc]，但使用 @racket[equal-always?] 查找元素。

@mz-examples[
  (assw 3 (list (list 1 2) (list 3 4) (list 5 6)))
  (define b1 (box 0))
  (define b2 (box 0))
  (assw b2 (list (cons b1 1) (cons b2 2)))]

@history[#:added "8.5.0.3"]}


@defproc[(assv [v any/c] [lst (or/c (listof pair?) any/c)])
         (or/c pair? #f)]{

类似于 @racket[assoc]，但使用 @racket[eqv?] 查找元素。

@mz-examples[
  (assv 3 (list (list 1 2) (list 3 4) (list 5 6)))]}


@defproc[(assq [v any/c] [lst (or/c (listof pair?) any/c)])
         (or/c pair? #f)]{

类似于 @racket[assoc]，但使用 @racket[eq?] 查找元素。

@mz-examples[
  (assq 'c (list (list 'a 'b) (list 'c 'd) (list 'e 'f)))]}


@defproc[(assf [proc procedure?] [lst (or/c (listof pair?) any/c)])
         (or/c pair? #f)]{

类似于 @racket[assoc]，但使用谓词 @racket[proc] 查找元素；当 @racket[proc] 应用于 @racket[lst] 元素的 @racket[car] 时返回真值则找到该元素。

@mz-examples[
  (assf (lambda (arg)
          (> arg 2))
        (list (list 1 2) (list 3 4) (list 5 6)))]}


@; ----------------------------------------
@section{Pair Accessor Shorthands}

@defc_r[a a '((1 2) 3 4)]
@defc_r[a d '((1 2) 3 4)]
@defc_r[d a '((7 6 5 4 3 2 1) 8 9)]
@defc_r[d d '(2 1)]
@defc_r[a a a '(((6 5 4 3 2 1) 7) 8 9)]
@defc_r[a a d '(9 (7 6 5 4 3 2 1) 8)]
@defc_r[a d a '((7 6 5 4 3 2 1) 8 9)]
@defc_r[a d d '(3 2 1)]
@defc_r[d a a '(((6 5 4 3 2 1) 7) 8 9)]
@defc_r[d a d '(9 (7 6 5 4 3 2 1) 8)]
@defc_r[d d a '((7 6 5 4 3 2 1) 8 9)]
@defc_r[d d d '(3 2 1)]
@defc_r[a a a a '((((5 4 3 2 1) 6) 7) 8 9)]
@defc_r[a a a d '(9 ((6 5 4 3 2 1) 7) 8)]
@defc_r[a a d a '((7 (5 4 3 2 1) 6) 8 9)]
@defc_r[a a d d '(9 8 (6 5 4 3 2 1) 7)]
@defc_r[a d a a '(((6 5 4 3 2 1) 7) 8 9)]
@defc_r[a d a d '(9 (7 6 5 4 3 2 1) 8)]
@defc_r[a d d a '((7 6 5 4 3 2 1) 8 9)]
@defc_r[a d d d '(4 3 2 1)]
@defc_r[d a a a '((((5 4 3 2 1) 6) 7) 8 9)]
@defc_r[d a a d '(9 ((6 5 4 3 2 1) 7) 8)]
@defc_r[d a d a '((7 (5 4 3 2 1) 6) 8 9)]
@defc_r[d a d d '(9 8 (6 5 4 3 2 1) 7)]
@defc_r[d d a a '(((6 5 4 3 2 1) 7) 8 9)]
@defc_r[d d a d '(9 (7 6 5 4 3 2 1) 8)]
@defc_r[d d d a '((7 6 5 4 3 2 1) 8 9)]
@defc_r[d d d d '(4 3 2 1)]


@; ----------------------------------------
@section{Additional List Functions and Synonyms}

@note-lib[racket/list]
@(define list-eval (make-base-eval))
@examples[#:hidden #:eval list-eval
          (require racket/list (only-in racket/function negate))]


@defthing[empty null?]{

  空 list。

  @mz-examples[#:eval list-eval
    empty
    (eq? empty null)]}


@defproc[(cons? [v any/c])
         boolean?]{

与 @racket[(pair? v)] 相同。

@mz-examples[#:eval list-eval
  (cons? '(1 2))]}


@defproc[(empty? [v any/c])
         boolean?]{

与 @racket[(null? v)] 相同。

@mz-examples[#:eval list-eval
  (empty? '(1 2))
  (empty? '())]}


@defproc[(first [lst list?])
         any/c]{

与 @racket[(car lst)] 相同，但仅适用于非空 list。

@mz-examples[#:eval list-eval
  (first '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(rest [lst list?])
         list?]{

与 @racket[(cdr lst)] 相同，但仅适用于非空 list。

@mz-examples[#:eval list-eval
  (rest '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(second [lst list?])
         any]{

返回 list 的第二个元素。

@mz-examples[#:eval list-eval
  (second '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(third [lst list?])
         any]{

返回 list 的第三个元素。

@mz-examples[#:eval list-eval
  (third '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(fourth [lst list?])
         any]{

返回 list 的第四个元素。

@mz-examples[#:eval list-eval
  (fourth '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(fifth [lst list?])
         any]{

返回 list 的第五个元素。

@mz-examples[#:eval list-eval
  (fifth '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(sixth [lst list?])
         any]{

返回 list 的第六个元素。

@mz-examples[#:eval list-eval
  (sixth '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(seventh [lst list?])
         any]{

返回 list 的第七个元素。

@mz-examples[#:eval list-eval
  (seventh '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(eighth [lst list?])
         any]{

返回 list 的第八个元素。

@mz-examples[#:eval list-eval
  (eighth '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(ninth [lst list?]) any]{

返回 list 的第九个元素。

@mz-examples[#:eval list-eval
  (ninth '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(tenth [lst list?]) any]{

返回 list 的第十个元素。

@mz-examples[#:eval list-eval
  (tenth '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(last [lst list?]) any]{

返回 list 的最后一个元素。

此函数的时间与 @racket[lst] 的长度成正比。

@mz-examples[#:eval list-eval
  (last '(1 2 3 4 5 6 7 8 9 10))]}


@defproc[(last-pair [p pair?])
         pair?]{

返回（可能是非正规的）list 的最后一个 pair。

此函数的时间与 @racket[p] 的“长度”成正比。

@mz-examples[#:eval list-eval
  (last-pair '(1 2 3 4))]}


@defproc[(make-list [k exact-nonnegative-integer?] [v any/c])
         list?]{

返回一个新构造的长度为 @racket[k] 的 list，所有位置都包含 @racket[v]。

@mz-examples[#:eval list-eval
  (make-list 7 'foo)]}

@defproc[(list-update [lst list?]
                      [pos (and/c (>=/c 0) (</c (length lst)))]
                      [updater (-> any/c any/c)])
         list?]{

返回一个与 @racket[lst] 相同的 list，但在指定索引处不同。指定索引处的元素为 @racket[(updater (list-ref lst pos))]。

此函数的时间与 @racket[pos] 成正比。

@examples[#:eval list-eval
(list-update '(zero one two) 1 symbol->string)]
@history[#:added "6.3"]{}
}

@defproc[(list-set [lst list?]
                   [pos (and/c (>=/c 0) (</c (length lst)))]
                   [value any/c])
         list?]{

返回一个与 @racket[lst] 相同的 list，但在指定索引处不同。指定索引处的元素为 @racket[value]。

此函数的时间与 @racket[pos] 成正比。

@examples[#:eval list-eval
(list-set '(zero one two) 2 "two")]
@history[#:added "6.3"]{}
}

@defproc[(index-of [lst list?] [v any/c]
                   [is-equal? (any/c any/c . -> . any/c) equal?])
         (or/c exact-nonnegative-integer? #f)]{
类似于 @racket[member]，但返回找到的第一个元素的索引，而不是 list 的尾部。
                          
@mz-examples[#:eval list-eval
  (index-of '(1 2 3 4) 3)]

@history[#:added "6.7.0.3"]}

@defproc[(index-where [lst list?] [proc (any/c . -> . any/c)])
         (or/c exact-nonnegative-integer? #f)]{
类似于 @racket[index-of]，但具有 @racket[memf] 的谓词搜索行为。

@mz-examples[#:eval list-eval
  (index-where '(1 2 3 4) even?)]

@history[#:added "6.7.0.3"]}

@defproc[(indexes-of [lst list?] [v any/c]
                     [is-equal? (any/c any/c . -> . any/c) equal?])
         (listof exact-nonnegative-integer?)]{
类似于 @racket[index-of]，但返回元素在 list 中出现的所有索引的 list，而不仅仅是第一个。
                          
@mz-examples[#:eval list-eval
  (indexes-of '(1 2 1 2 1) 2)]

@history[#:added "6.7.0.3"]}

@defproc[(indexes-where [lst list?] [proc (any/c . -> . any/c)])
         (listof exact-nonnegative-integer?)]{
类似于 @racket[indexes-of]，但具有 @racket[index-where] 的谓词搜索行为。

@mz-examples[#:eval list-eval
  (indexes-where '(1 2 3 4) even?)]

@history[#:added "6.7.0.3"]}

@defproc[(take [lst any/c] [pos exact-nonnegative-integer?])
         list?]{

返回一个新 list，其元素为 @racket[lst] 的前 @racket[pos] 个元素。如果 @racket[lst] 的元素少于 @racket[pos] 个，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是 list；@racket[lst] 只需以至少 @racket[pos] 个 pair 的链开始。

此函数的时间与 @racket[pos] 成正比。

@mz-examples[#:eval list-eval
  (take '(1 2 3 4 5) 2)
  (take 'non-list 0)]}


@defproc[(drop [lst any/c] [pos exact-nonnegative-integer?])
         any/c]{

与 @racket[list-tail] 相同。}


@defproc[(split-at [lst any/c] [pos exact-nonnegative-integer?])
         (values list? any/c)]{

返回与以下相同的结果

@racketblock[(values (take lst pos) (drop lst pos))]

除了它可能更快，但它仍需要与 @racket[pos] 成正比的时间。}


@defproc[(takef [lst any/c] [pred procedure?])
         list?]{

返回一个新 list，其元素从 @racket[lst] 中依次取出，只要它们满足 @racket[pred]。返回的 list 包含直到（但不包括）@racket[lst] 中 @racket[pred] 返回 @racket[#f] 的第一个元素。

@racket[lst] 参数实际上不必是 list；@racket[lst] 中的 pair 链将被遍历直到遇到非 pair。

@mz-examples[#:eval list-eval
  (takef '(2 4 5 8) even?)
  (takef '(2 4 6 8) odd?)
  (takef '(2 4 . 6) even?)]}


@defproc[(dropf [lst any/c] [pred procedure?])
         any/c]{

从 @racket[lst] 的前端丢弃元素，只要它们满足 @racket[pred]。

@mz-examples[#:eval list-eval
  (dropf '(2 4 5 8) even?)
  (dropf '(2 4 6 8) odd?)]}


@defproc[(splitf-at [lst any/c] [pred procedure?])
         (values list? any/c)]{

返回与以下相同的结果

@racketblock[(values (takef lst pred) (dropf lst pred))]

除了它可能更快。}


@defproc[(take-right [lst any/c] [pos exact-nonnegative-integer?])
         any/c]{

返回 @racket[list] 的 @racket[pos] 长度尾部。如果 @racket[lst] 的元素少于 @racket[pos] 个，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是 list；@racket[lst] 只需以至少 @racket[pos] 个 pair 的链结束。

此函数的时间与 @racket[lst] 的长度成正比。

@mz-examples[#:eval list-eval
  (take-right '(1 2 3 4 5) 2)
  (take-right 'non-list 0)]}


@defproc[(drop-right [lst any/c] [pos exact-nonnegative-integer?])
         list?]{

返回一个新 list，其元素为 @racket[lst] 的前缀，丢弃其 @racket[pos] 长度尾部。如果 @racket[lst] 的元素少于 @racket[pos] 个，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是 list；@racket[lst] 只需以至少 @racket[pos] 个 pair 的链结束。

此函数的时间与 @racket[lst] 的长度成正比。

@mz-examples[#:eval list-eval
  (drop-right '(1 2 3 4 5) 2)
  (drop-right 'non-list 0)]}


@defproc[(split-at-right [lst any/c] [pos exact-nonnegative-integer?])
         (values list? any/c)]{

返回与以下相同的结果

@racketblock[(values (drop-right lst pos) (take-right lst pos))]

除了它可能更快，但它仍需要与 @racket[lst] 长度成正比的时间。

@mz-examples[#:eval list-eval
  (split-at-right '(1 2 3 4 5 6) 3)
  (split-at-right '(1 2 3 4 5 6) 4)]}


@deftogether[(
  @defproc[(takef-right [lst any/c] [pred procedure?]) any/c]
  @defproc[(dropf-right [lst any/c] [pred procedure?]) list?]
  @defproc[(splitf-at-right [lst any/c] [pred procedure?]) (values list? any/c)]
)]{

类似于 @racket[takef]、@racket[dropf] 和 @racket[splitf-at]，但结合了 @racket[take-right]、@racket[drop-right] 和 @racket[split-at-right] 的从右操作功能。}

@defproc[(list-prefix? [l list?]
                       [r list?]
                       [same? (any/c any/c . -> . any/c) equal?])
         boolean?]{
 如果 @racket[l] 是 @racket[r] 的前缀则返回 @racket[#t]。
@examples[#:eval list-eval
(list-prefix? '(1 2) '(1 2 3 4 5))
]
@history[#:added "6.3"]{}
}

@defproc[(take-common-prefix [l list?] [r list?]
                             [same? (any/c any/c . -> . any/c) equal?])
         list?]{

  返回 @racket[l] 和 @racket[r] 的最长公共前缀。

@examples[#:eval list-eval
(take-common-prefix '(a b c d) '(a b x y z))
]
@history[#:added "6.3"]{}
}

@defproc[(drop-common-prefix [l list?] [r list?]
                             [same? (any/c any/c . -> . any/c) equal?])
         (values list? list?)]{

  返回移除公共前缀后 @racket[l] 和 @racket[r] 的尾部。

@examples[#:eval list-eval
(drop-common-prefix '(a b c d) '(a b x y z))
]
@history[#:added "6.3"]{}
}

@defproc[(split-common-prefix [l list?] [r list?]
                              [same? (any/c any/c . -> . any/c) equal?])
         (values list? list? list?)]{

  返回最长公共前缀以及移除公共前缀后 @racket[l] 和 @racket[r] 的尾部。

@examples[#:eval list-eval
(split-common-prefix '(a b c d) '(a b x y z))
]
@history[#:added "6.3"]{}
}


@defproc[(add-between [lst list?] [v any/c]
                      [#:before-first before-first list? '()]
                      [#:before-last  before-last  any/c v]
                      [#:after-last   after-last   list? '()]
                      [#:splice? splice? any/c #f])
         list?]{

返回一个与 @racket[lst] 具有相同元素的 list，但在 @racket[lst] 的每对元素之间插入 @racket[v]；最后一对元素之间将使用 @racket[before-last] 而非 @racket[v]（但 @racket[before-last] 默认为 @racket[v]）。

如果 @racket[splice?] 为真，则 @racket[v] 和 @racket[before-last] 应为 list，且 list 元素被拼接到结果中。此外，当 @racket[splice?] 为真时，@racket[before-first] 和 @racket[after-last] 分别在第一个元素之前和最后一个元素之后插入。

@mz-examples[#:eval list-eval
  (add-between '(x y z) 'and)
  (add-between '(x) 'and)
  (add-between '("a" "b" "c" "d") "," #:before-last "and")
  (add-between '(x y z) '(-) #:before-last '(- -)
               #:before-first '(begin) #:after-last '(end LF)
               #:splice? #t)]}


@defproc*[([(append* [lst list?] ... [lsts (listof list?)]) list?]
           [(append* [lst list?] ... [lsts list?]) any/c])]{
@; Note: this is exactly the same description as the one for string-append*

类似于 @racket[append]，但最后一个参数用作 @racket[append] 的参数 list，因此 @racket[(append* lst ... lsts)] 与 @racket[(apply append lst ... lsts)] 相同。换句话说，@racket[append] 和 @racket[append*] 之间的关系类似于 @racket[list] 和 @racket[list*] 之间的关系。

@mz-examples[#:eval list-eval
  (append* '(a) '(b) '((c) (d)))
  (cdr (append* (map (lambda (x) (list ", " x))
                     '("Alpha" "Beta" "Gamma"))))]}


@defproc[(flatten [v any/c])
         list?]{

将任意 S-表达式的 pair 结构展平为 list。更准确地说，@racket[v] 被视为二叉树，其中 pair 是内部节点，结果 list 包含树中所有非 @racket[null] 的叶子，其顺序与中序遍历相同。

@mz-examples[#:eval list-eval
  (flatten '((a) b (c (d) . e) ()))
  (flatten 'a)]}


@defproc[(check-duplicates [lst list?]
                           [same? (any/c any/c . -> . any/c) equal?]
                           [#:key extract-key (-> any/c any/c) (lambda (x) x)]
                           [#:default failure-result failure-result/c (lambda () #f)])
         any]{

返回 @racket[lst] 中第一个重复项。更准确地说，它返回第一个 @racket[_x]，使得存在之前的 @racket[_y] 满足 @racket[(same? (extract-key _x) (extract-key _y))]。

如果未找到重复项，则由 @racket[failure-result] 决定结果：

@itemize[

 @item{如果 @racket[failure-result] 是过程，则通过尾调用不带参数地调用它来产生结果。}

 @item{否则，返回 @racket[failure-result] 作为结果。}

]

@racket[same?] 参数应是一个等价谓词，如 @racket[equal?] 或 @racket[eqv?]，或一个字典。过程 @racket[equal?]、@racket[eqv?] 和 @racket[eq?] 会自动使用字典以提高速度。

@examples[#:eval list-eval
(check-duplicates '(1 2 3 4))
(check-duplicates '(1 2 3 2 1))
(check-duplicates '((a 1) (b 2) (a 3)) #:key car)
(check-duplicates '(1 2 3 4 5 6)
                  (lambda (x y) (equal? (modulo x 3) (modulo y 3))))
(check-duplicates '(1 2 3 4) #:default "no duplicates")
]

@history[#:added "6.3"
         #:changed "6.11.0.2" @elem{添加了 @racket[#:default] 可选参数。}]}

@defproc[(remove-duplicates [lst list?]
                            [same? (any/c any/c . -> . any/c) equal?]
                            [#:key extract-key (any/c . -> . any/c)
                                   (lambda (x) x)])
         list?]{

返回一个包含 @racket[lst] 中所有项但没有重复项的 list，其中 @racket[same?] 决定 list 中两个元素是否等价。结果 list 的顺序与 @racket[lst] 相同，对于多次出现的项，保留第一个。

@racket[#:key] 参数 @racket[extract-key] 用于从每个 list 元素中提取键值，因此如果 @racket[(same? (extract-key x) (extract-key y))] 为真，则两个项被视为相等。

@mz-examples[#:eval list-eval
  (remove-duplicates '(a b b a))
  (remove-duplicates '(1 2 1.0 0))
  (remove-duplicates '(1 2 1.0 0) =)]}


@defproc[(filter-map [proc procedure?] [lst list?] ...+)
         list?]{

类似于 @racket[(map proc lst ...)]，但不同之处在于，如果 @racket[proc] 返回 @racket[#false]，则该元素从结果 list 中省略。换句话说，@racket[filter-map] 等价于 @racket[(filter (lambda (x) x) (map proc lst ...))]，但更高效，因为 @racket[filter-map] 避免了构建中间 list。

@mz-examples[#:eval list-eval
  (filter-map (lambda (x) (and (negative? x) (abs x))) '(1 2 -3 -4 8))]}


@defproc[(count [proc procedure?] [lst list?] ...+)
         exact-nonnegative-integer?]{

返回 @racket[(length (filter-map proc lst ...))]，但不构建中间 list。

@mz-examples[#:eval list-eval
  (count positive? '(1 -1 2 3 -2 5))]}


@defproc[(partition [pred procedure?] [lst list?])
         (values list? list?)]{

类似于 @racket[filter]，但返回两个值：@racket[pred] 返回真值的项，以及 @racket[pred] 返回 @racket[#f] 的项。

结果与以下相同

@racketblock[(values (filter pred lst) (filter (negate pred) lst))]

但 @racket[pred] 仅对 @racket[lst] 中的每项应用一次。

@mz-examples[#:eval list-eval
  (partition even? '(1 2 3 4 5 6))]}


@defproc*[([(range [end real?]) list?]
           [(range [start real?] [end real?] [step real? 1]) list?])]{

类似于 @racket[in-range]，但返回 list。

结果 list 包含从 @racket[start] 开始的数字，其后续元素通过将 @racket[step] 加到前一个元素来计算，直到达到 @racket[end]（不包含）。如果未提供起始点，则使用 @racket[0]。如果未提供 @racket[step] 参数，则使用 @racket[1]。

与 @racket[in-range] 类似，当 @racket[range] 应用直接出现在 @racket[for] 子句中时，可以提供更好的性能。

@mz-examples[#:eval list-eval
  (range 10)
  (range 10 20)
  (range 20 40 2)
  (range 20 10 -1)
  (range 10 15 1.5)]

@history[#:changed "6.7.0.4"
         @elem{调整为与 @racket[for] 配合使用，方式与 @racket[in-range] 相同。}]}


@defproc[(inclusive-range [start real?] [end real?] [step real? 1]) list?]{

类似于 @racket[in-inclusive-range]，但返回 list。

结果 list 包含从 @racket[start] 开始的数字，其后续元素通过将 @racket[step] 加到前一个元素来计算，直到达到 @racket[end]（包含）。如果未提供 @racket[step] 参数，则使用 @racket[1]。

与 @racket[in-inclusive-range] 类似，当 @racket[inclusive-range] 应用直接出现在 @racket[for] 子句中时，可以提供更好的性能。

@mz-examples[#:eval list-eval
  (inclusive-range 10 20)
  (inclusive-range 20 40 2)
  (inclusive-range 20 10 -1)
  (inclusive-range 10 15 1.5)]

@history[#:added "8.0.0.13"]

}


@defproc[(append-map [proc procedure?] [lst list?] ...+)
         list?]{

返回 @racket[(append* (map proc lst ...))]。

@mz-examples[#:eval list-eval
  (append-map vector->list '(#(1) #(2 3) #(4)))]}


@defproc[(filter-not [pred (any/c . -> . any/c)] [lst list?])
         list?]{

类似于 @racket[filter]，但 @racket[pred] 谓词的含义被反转：结果是 @racket[pred] 返回 @racket[#f] 的所有项的 list。

@mz-examples[#:eval list-eval
  (filter-not even? '(1 2 3 4 5 6))]}


@defproc[(shuffle [lst list?])
         list?]{

返回一个包含 @racket[lst] 中所有元素的 list，随机打乱顺序。

@mz-examples[#:eval list-eval
  (shuffle '(1 2 3 4 5 6))
  (shuffle '(1 2 3 4 5 6))
  (shuffle '(1 2 3 4 5 6))]}


@defproc*[([(combinations [lst list?]) list?]
           [(combinations [lst list?] [size exact-nonnegative-integer?]) list?])]{
@margin-note{Wikipedia @hyperlink["https://en.wikipedia.org/wiki/Combination"]{combinations}}
返回输入 list 中元素的所有组合的 list（即 @racket[lst] 的 @index["powerset"]{幂集}）。如果给定 @racket[size]，则将结果限制为 @racket[size] 个元素的组合。

@mz-examples[#:eval list-eval
  (combinations '(1 2 3))
  (combinations '(1 2 3) 2)]}


@defproc*[([(in-combinations [lst list?]) sequence?]
           [(in-combinations [lst list?] [size exact-nonnegative-integer?]) sequence?])]{
@index["in-powerset"]{返回}输入 list 中元素的所有组合的序列，如果给定 @racket[size]，则返回所有长度为 @racket[size] 的组合。逐个构建组合，而不是一次性全部构建。

@mz-examples[#:eval list-eval
  (time (begin (combinations (range 15)) (void)))
  (time (begin (in-combinations (range 15)) (void)))]}


@defproc[(permutations [lst list?])
         list?]{

@index["rearrangements"]{返回}输入 list 的所有排列的 list。请注意，此函数在不检查元素的情况下工作，因此它忽略重复元素（这将导致重复排列）。如果输入 list 包含超过 256 个元素，则引发错误。

@mz-examples[#:eval list-eval
  (permutations '(1 2 3))
  (permutations '(x x))]}


@defproc[(in-permutations [lst list?])
         sequence?]{

@index["in-rearrangements"]{返回}输入 list 的所有排列的序列。它等价于 @racket[(in-list (permutations l))]，但由于在每次迭代中逐个构建排列，因此速度要快得多。如果输入 list 包含超过 256 个元素，则引发错误。}


@defproc[(argmin [proc (-> any/c real?)] [lst (and/c pair? list?)])
         any/c]{

返回 list @racket[lst] 中使 @racket[proc] 结果最小化的第一个元素。对空 list 发出错误信号。另见 @racket[min]。

@mz-examples[#:eval list-eval
  (argmin car '((3 pears) (1 banana) (2 apples)))
  (argmin car '((1 banana) (1 orange)))]}


@defproc[(argmax [proc (-> any/c real?)] [lst (and/c pair? list?)])
         any/c]{

返回 list @racket[lst] 中使 @racket[proc] 结果最大化的第一个元素。对空 list 发出错误信号。另见 @racket[max]。

@mz-examples[#:eval list-eval
  (argmax car '((3 pears) (1 banana) (2 apples)))
  (argmax car '((3 pears) (3 oranges)))]}

@defproc[(group-by [key (-> any/c any/c)]
                   [lst list?]
                   [same? (any/c any/c . -> . any/c) equal?])
         (listof list?)]{

将给定 list 分组为等价类，等价性由 @racket[same?] 决定。在每个等价类中，@racket[group-by] 保持原始 list 的顺序。等价类本身按在输入中首次出现的顺序排列。

@examples[#:eval list-eval
(group-by (lambda (x) (modulo x 3)) '(1 2 1 2 54 2 5 43 7 2 643 1 2 0))
]
@history[#:added "6.3"]{}
}

@defproc[(cartesian-product [lst list?] ...)
         (listof list?)]{

计算给定 list 的 n 元笛卡尔积。

@examples[#:eval list-eval
(cartesian-product '(1 2 3) '(a b c))
(cartesian-product '(4 5 6) '(d e f) '(#t #f))
]
@history[#:added "6.3"]{}
}

@defproc[(remf [pred procedure?]
               [lst list?])
         list?]{
返回一个类似于 @racket[lst] 的 list，省略 @racket[lst] 中 @racket[pred] 产生真值的第一个元素。

@examples[
#:eval list-eval
(remf negative? '(1 -2 3 4 -5))
]
@history[#:added "6.3"]{}
}

@defproc[(remf* [pred procedure?]
                [lst list?])
         list?]{
类似于 @racket[remf]，但移除 @racket[pred] 产生真值的所有元素。

@examples[
#:eval list-eval
(remf* negative? '(1 -2 3 4 -5))
]
@history[#:added "6.3"]{}
}


@close-eval[list-eval]


@; ----------------------------------------
@section{Immutable Cyclic Data}

@defproc[(make-reader-graph [v any/c])
         any/c]{

返回一个类似于 @racket[v] 的值，其中由 @racket[make-placeholder] 创建的 @deftech{placeholder}（占位符）被它们包含的值替换，由 @racket[make-hash-placeholder] 创建的 @deftech{hash placeholder}（哈希占位符）被不可变哈希表替换。@racket[v] 的任何部分都不会被修改；相反，@racket[v] 的部分会根据需要复制以构造结果图，其中对于任何给定值最多创建一个副本。

由于复制的值可以是不可变的，并且副本也是不可变的，因此 @racket[make-reader-graph] 可以创建仅涉及不可变 pair、向量、盒子和哈希表的循环。

只有以下类型的值会被复制和遍历以检测 placeholder：

@itemize[

 @item{pair}

 @item{向量，包括可变和不可变的}

 @item{盒子，包括可变和不可变的}

 @item{哈希表，包括可变和不可变的}

 @item{@techlink{prefab} 结构类型的实例}

 @item{由 @racket[make-placeholder] 和 @racket[make-hash-placeholder] 创建的 placeholder}]

由于这些限制，@racket[make-reader-graph] 创建的循环值与 @racket[read] 完全相同。

@mz-examples[
  (let* ([ph (make-placeholder #f)]
         [x (cons 1 ph)])
    (placeholder-set! ph x)
    (make-reader-graph x))]}


@defproc[(placeholder? [v any/c])
         boolean?]{

如果 @racket[v] 是由 @racket[make-placeholder] 创建的 @tech{placeholder}，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-placeholder [v any/c])
         placeholder?]{

返回一个用于 @racket[placeholder-set!] 和 @racket[make-reader-graph] 的 @tech{placeholder}。@racket[v] 参数为 placeholder 提供初始值。}


@defproc[(placeholder-set! [ph placeholder?] [datum any/c])
         void?]{

将 @racket[ph] 的值更改为 @racket[v]。}


@defproc[(placeholder-get [ph placeholder?])
         any/c]{

返回 @racket[ph] 的值。}


@defproc[(hash-placeholder? [v any/c])
         boolean?]{

如果 @racket[v] 是由 @racket[make-hash-placeholder] 创建的 @tech{hash placeholder}，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-hash-placeholder [assocs (listof pair?)])
         hash-placeholder?]{

类似于 @racket[make-immutable-hash]，但产生用于 @racket[make-reader-graph] 的 @tech{hash placeholder}。}


@defproc[(make-hasheq-placeholder [assocs (listof pair?)])
         hash-placeholder?]{

类似于 @racket[make-immutable-hasheq]，但产生用于 @racket[make-reader-graph] 的 @tech{hash placeholder}。}


@defproc[(make-hasheqv-placeholder [assocs (listof pair?)])
         hash-placeholder?]{

类似于 @racket[make-immutable-hasheqv]，但产生用于 @racket[make-reader-graph] 的 @tech{hash placeholder}。}

@defproc[(make-hashalw-placeholder [assocs (listof pair?)])
         hash-placeholder?]{

类似于 @racket[make-immutable-hashalw]，但产生用于 @racket[make-reader-graph] 的 @tech{hash placeholder}。

@history[#:added "8.5.0.3"]}
