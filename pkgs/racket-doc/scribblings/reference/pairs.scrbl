#lang scribble/doc
@(require "mz.rkt" scribble/scheme racket/generator racket/list
          (for-syntax racket/base)
          (for-label racket/list racket/list/iteration racket/list/grouping))

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
              [equiv (let loop ([l xs])]
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
                "返回 " (racket equiv) "。" (mz-examples example)))))]))

@title[#:tag "pairs"]{序对与列表}

@guideintro["pairs"]{序对与列表}

一个 @deftech{序对}（pair）将恰好两个值组合在一起。第一个值通过 @racket[car] 过程访问，
第二个值通过 @racket[cdr] 过程访问。序对是不可变的（但参见 @secref["mpairs"]）。

一个 @deftech{列表}（list）是递归定义的：它要么是常量 @racket[null]，要么是一个序对，
其第二个值是一个列表。

列表可以用作单值序列（参见 @secref["sequences"]）。列表的元素作为序列的元素。
另参见 @racket[in-list]。

可以使用仅不可变序对通过 @racket[read] 或 @racket[make-reader-graph] 创建循环数据结构。
如果从一个序对开始，使用若干次 @racket[cdr] 后返回到起始序对，那么该序对就不是一个列表。

@see-read-print["pair" #:print "pairs"]{序对与列表}


@; ----------------------------------------
@section{序对构造器与选择器}

@defproc[(pair? [v any/c])
         boolean?]{

如果 @racket[v] 是序对则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[
  (pair? 1)
  (pair? (cons 1 2))
  (pair? (list 1 2))
  (pair? '(1 2))
  (pair? '())]}


@defproc[(null? [v any/c])
         boolean?]{

如果 @racket[v] 是空列表则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[
  (null? 1)
  (null? '(1 2))
  (null? '())
  (null? (cdr (list 1)))]}


@defproc*[([(cons [a any/c] [d list?]) list?]
           [(cons [a any/c] [d any/c]) pair?])]{

返回一个新分配的序对，其第一个元素是 @racket[a]，第二个元素是 @racket[d]。
当 @racket[d] 是列表时，分配的序对也是一个列表。

@mz-examples[
  (cons 1 2)
  (cons 1 '())]}


@defproc[(car [p pair?])
         any/c]{

返回序对 @racket[p] 的第一个元素。

@mz-examples[
  (car '(1 2))
  (car '(2 . 3))]}


@defproc[(cdr [p pair?])
         any/c]{

返回序对 @racket[p] 的第二个元素。

@mz-examples[
  (cdr '(1 2))
  (cdr '(2 . 3))]}


@defthing[null null?]{

  空列表。

  @mz-examples[
    null
    '()
    (eq? '() null)]}


@defproc[(list? [v any/c])
         boolean?]{

如果 @racket[v] 是列表则返回 @racket[#t]：要么是空列表，要么是第二个元素为列表的序对。
由于内部缓存，该过程实际上花费恒定时间（因此任何必要的序对遍历在原则上都可以算作分配序对的额外成本）。

@mz-examples[
  (list? '(1 2))
  (list? (cons 1 (cons 2 '())))
  (list? (cons 1 2))]}


@defproc[(list [v any/c] ...)
         list?]{

返回一个新分配的列表，包含 @racket[v] 作为其元素。

@mz-examples[
  (list 1 2 3 4)
  (list (list 1 2) (list 3 4))]}


@defproc*[([(list* [v any/c] ... [tail list?]) list?]
           [(list* [v any/c] ... [tail any/c]) any/c])]{

类似 @racket[list]，但最后一个参数用作结果的尾部，而不是最后一个元素。
仅当最后一个参数是列表时，结果才是列表。

@mz-examples[
 (list* 1 2 3)
 (list* 1 2 (list 3 4))]}


@defproc[(build-list [n exact-nonnegative-integer?]
                     [proc (exact-nonnegative-integer? . -> . any/c)])
         list?]{

通过将 @racket[proc] 依次应用于从 @racket[0] 到 @racket[(sub1 n)] 的整数来创建包含 @racket[n] 个元素的列表。
如果 @racket[_lst] 是结果列表，那么 @racket[(list-ref _lst _i)] 就是 @racket[(proc _i)] 产生的值。

@mz-examples[
  (build-list 10 values)
  (build-list 5 (lambda (x) (* x x)))]}


@; ----------------------------------------
@section{列表操作}

@defproc[(length [lst list?])
         exact-nonnegative-integer?]{

返回 @racket[lst] 中的元素数量。此函数花费的时间与该长度成正比。

@mz-examples[
  (length (list 1 2 3 4))
  (length '())]}


@defproc*[([(list-ref [lst list?] [pos exact-nonnegative-integer?]) any/c]
           [(list-ref [lst pair?] [pos exact-nonnegative-integer?]) any/c]{

返回 @racket[lst] 中位置 @racket[pos] 处的元素，其中列表的第一个元素位于位置 @racket[0]。
如果列表有 @racket[pos] 个或更少的元素，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是列表；@racket[lst] 必须至少以 @racket[(add1 pos)] 个序对组成的链开头。

此函数花费的时间与 @racket[pos] 成正比。

@mz-examples[
  (list-ref (list 'a 'b 'c) 0)
  (list-ref (list 'a 'b 'c) 1)
  (list-ref (list 'a 'b 'c) 2)
  (list-ref (cons 1 2) 0)
  (eval:error (list-ref (cons 1 2) 1))]}


@defproc*[([(list-tail [lst list?] [pos exact-nonnegative-integer?]) list?]
           [(list-tail [lst any/c] [pos exact-nonnegative-integer?]) any/c]{

返回 @racket[lst] 在第一个 @racket[pos] 个元素之后的列表。
如果列表少于 @racket[pos] 个元素，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是列表；@racket[lst] 必须至少以 @racket[pos] 个序对组成的链开头。

此函数花费的时间与 @racket[pos] 成正比。

@mz-examples[
  (list-tail (list 1 2 3 4 5) 2)
  (list-tail (cons 1 2) 1)
  (eval:error (list-tail (cons 1 2) 2))
  (list-tail 'not-a-pair 0)]}


@defproc*[([(append [lst list?] ...) list?]
           [(append [lst list?] ... [v any/c]) any/c])]{

当所有参数都是列表时，结果是按顺序包含所有给定列表元素的列表。
最后一个参数直接用作结果的尾部。

最后一个参数不必是列表，在这种情况下结果是一个``非正常列表''（improper list）。

此函数花费的时间与所有参数（除最后一个外）的长度之和成正比。

@mz-examples[
  (append (list 1 2) (list 3 4))
  (append (list 1 2) (list 3 4) (list 5 6) (list 7 8))]}


@defproc[(reverse [lst list?]) list?]{

返回一个与 @racket[lst] 具有相同元素但顺序相反的列表。

此函数花费的时间与 @racket[lst] 的长度成正比。

@mz-examples[
  (reverse (list 1 2 3 4))]}


@; ----------------------------------------
@section{列表迭代}

@defproc[(map [proc procedure?] [lst list?] ...+)
         list?]{

将 @racket[proc] 应用于 @racket[lst] 的元素，从第一个元素到最后一个元素。
@racket[proc] 参数必须接受与提供的 @racket[lst] 数量相同的参数，
并且所有 @racket[lst] 必须具有相同数量的元素。结果是一个按顺序包含 @racket[proc] 每个结果的列表。

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

类似于 @racket[map]，因为 @racket[proc] 被应用于 @racket[lst] 的每个元素，但

@margin-note{@racket[andmap] 函数实际上更接近 @racket[foldl] 而不是 @racket[map]，
  因为 @racket[andmap] 不产生列表。尽管如此，@racket[(andmap f (list x y z))] 等价于
  @racket[(and (f x) (f y) (f z))]，正如 @racket[(map f (list x y z))] 等价于
  @racket[(list (f x) (f y) (f z))]。}

@itemize[

 @item{如果 @racket[proc] 的任何应用产生 @racket[#f]，则结果为 @racket[#f]，
       在这种情况下 @racket[proc] 不会应用于 @racket[lst] 的后续元素；并且}

 @item{结果是 @racket[proc] 应用于 @racket[lst] 的最后一个元素的结果；
       更具体地说，@racket[proc] 在最后一个元素上的应用处于 @racket[andmap] 调用的尾部位置。}]

如果 @racket[lst] 为空，则返回 @racket[#t]。

@mz-examples[
  (andmap positive? '(1 2 3))
  (eval:error (andmap positive? '(1 2 a)))
  (andmap positive? '(1 -2 a))
  (andmap + '(1 2 3) '(4 5 6))]}


@defproc[(ormap [proc procedure?] [lst list?] ...+)
         any]{

类似于 @racket[map]，因为 @racket[proc] 被应用于 @racket[lst] 的每个元素，但

@margin-note{继续上面的 @racket[andmap] 说明，
  @racket[(ormap f (list x y z))] 等价于
  @racket[(or (f x) (f y) (f z))]。}

@itemize[

 @item{如果 @racket[proc] 的每次应用都产生 @racket[#f]，则结果为 @racket[#f]；并且}

 @item{结果是 @racket[proc] 第一次产生非 @racket[#f] 值的应用结果，
       在这种情况下 @racket[proc] 不会应用于 @racket[lst] 的后续元素；
       @racket[proc] 在最后一个元素上的应用处于 @racket[ormap] 调用的尾部位置。}]

如果 @racket[lst] 为空，则返回 @racket[#f]。

@mz-examples[
  (ormap eq? '(a b c) '(a b c))
  (ormap positive? '(1 2 a))
  (ormap + '(1 2 3) '(4 5 6))]}


@defproc[(for-each [proc procedure?] [lst list?] ...+)
         void?]{

类似于 @racket[map]，但 @racket[proc] 仅为了其副作用而被调用，
其结果（可以是任意数量的值）被忽略。

@mz-examples[
  (for-each (lambda (arg)
              (printf "Got ~a\n" arg)
              23)
            '(1 2 3 4))]}


@defproc[(foldl [proc procedure?] [init any/c] [lst list?] ...+)
         any/c]{

像 @racket[map] 一样，@racket[foldl] 将一个过程应用于一个或多个列表的元素。
而 @racket[map] 将返回值组合成一个列表，@racket[foldl] 以 @racket[proc] 确定的任意方式组合返回值。

如果 @racket[foldl] 以 @math{n} 个列表调用，那么 @racket[proc] 必须接受 @math{n+1} 个参数。
额外的参数是到目前为止组合的返回值。@racket[proc] 最初以每个列表的第一项调用，
最终参数是 @racket[init]。在后续调用中，最后一个参数是 @racket[proc] 前一次调用的返回值。
输入 @racket[lst] 从左到右遍历，整个 @racket[foldl] 应用的结果是 @racket[proc] 最后一次应用的结果。
如果 @racket[lst] 为空，结果是 @racket[init]。

与 @racket[foldr] 不同，@racket[foldl] 在恒定空间（加上每次调用 @racket[proc] 的空间）中处理 @racket[lst]。

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

像 @racket[foldl]，但列表从右到左遍历。
与 @racket[foldl] 不同，@racket[foldr] 在 @racket[lst] 长度成正比的空间（加上每次调用 @racket[proc] 的空间）中处理 @racket[lst]。

@mz-examples[
  (foldr cons '() '(1 2 3 4))
  (foldr (lambda (v l) (cons (add1 v) l)) '() '(1 2 3 4))]}


@(define list-eval (make-base-eval))
@examples[#:hidden #:eval list-eval
          (require racket/list (only-in racket/function negate))
          (require racket/list/grouping)
          (require racket/list/iteration)]


@; ----------------------------------------
@section{更多列表迭代}

@note-lib-only[racket/list/iteration]

本节中的绑定由 @racket[sequence-tools-lib] 包提供，
它作为基本序列库的扩展。

@defproc[(running-foldl [proc procedure?] [init any/c] [lst list?] ...+)
         list?]{

像 @racket[foldl]，但产生一个包含应用 @racket[proc] 的所有结果以及初始累加器的列表。

@examples[#:eval list-eval
  (running-foldl + 0 '(1 2 3))
  (running-foldl + 0 '())
  (running-foldl (lambda (a b acc) 
                     (* acc (+ a b))) 
                 1 
                 '(1 2)
                 '(3 4))]}


@defproc[(running-foldr [proc procedure?] [init any/c] [lst list?] ...+)
         list?]{

像 @racket[running-foldl]，但从右侧产生中间结果，像 @racket[foldr]。

@examples[#:eval list-eval
  (running-foldr + 0 '(1 2 3))
  (running-foldr + 0 '())
  (running-foldr (lambda (a b acc) 
                     (* acc (+ a b))) 
                 1 
                 '(1 2)
                 '(3 4))]}


@; ----------------------------------------
@section{列表过滤}

@defproc[(filter [pred procedure?] [lst list?])
         list?]{

返回一个列表，包含 @racket[lst] 中 @racket[pred] 产生真值的元素。
@racket[pred] 过程应用于从第一个到最后一个的每个元素。

@mz-examples[
  (filter positive? '(1 -2 3 4 -5))]}


@defproc[(remove [v any/c] [lst list?] [proc procedure? equal?])
         list?]{

返回一个类似 @racket[lst] 的列表，省略 @racket[lst] 中第一个使用比较过程 @racket[proc]
（必须接受两个参数）等于 @racket[v] 的元素，其中 @racket[v] 作为第一个参数，
@racket[lst] 中的元素作为第二个参数。
如果 @racket[lst] 中没有元素等于 @racket[v]（根据 @racket[proc]），
则 @racket[lst] 原样返回。

@mz-examples[
  (remove 2 (list 1 2 3 2 4))
  (remove '(2) (list '(1) '(2) '(3)))
  (remove "2" (list "1" "2" "3"))
  (remove #\c (list #\a #\b #\c))
  (remove "B" (list "a" "A" "b" "B") string-ci=?)
  (remove 5 (list 1 2 3 2 4))]

@history[#:changed "8.2.0.2"
         @elem{保证如果没有发生移除，输出在 @racket[eq?] 意义上等于 @racket[lst]。}]}


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

像 @racket[remove]，但从 @racket[lst] 中移除 @racket[v-lst] 中每个元素的所有实例。

@mz-examples[
  (remove* (list 1 2) (list 1 2 3 2 4 5 2))]

@history[#:changed "8.2.0.2"
         @elem{保证如果没有发生移除，输出在 @racket[eq?] 意义上等于 @racket[lst]。}]}


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
               [#:key extract-key (or/c #f (any/c . -> . any/c)) #f]
               [#:cache-keys? cache-keys? boolean? #f])
         list?]{

返回一个根据 @racket[less-than?] 过程排序的列表，
该过程接受 @racket[lst] 的两个元素，如果第一个小于第二个（即应该排在前面）则返回真值。

排序是稳定的；如果 @racket[lst] 的两个元素``相等''
（即无论以何种顺序给出该对，@racket[less-than?] 都不返回真值），
则这些元素在输出列表中保持其在 @racket[lst] 中的相对顺序。
要保持此保证，请使用严格比较函数（例如 @racket[<] 或 @racket[string<?]；
而不是 @racket[<=] 或 @racket[string<=?]）调用 @racket[sort]。

@margin-note{由于 IEEE-754 数系的特殊事实，即 +nan.0 既不大于、也不小于、也不等于任何其他数字，
包含此值的列表排序可能产生令人惊讶的结果。}

@racket[#:key] 参数 @racket[extract-key] 用于从每个列表元素中提取用于比较的键值，
其中 @racket[#f] 被替换为 @racket[(lambda (x) x)]。也就是说，完整的比较过程本质上是

@racketblock[
  (lambda (x y)
    (less-than? (extract-key x) (extract-key y)))]

默认情况下，@racket[extract-key] 应用于每次比较的两个列表元素，
但如果 @racket[cache-keys?] 为真，则 @racket[extract-key] 函数对每个列表项仅使用一次。
当 @racket[extract-key] 是昂贵操作时，应为 @racket[cache-keys?] 提供真值；
例如，如果使用 @racket[file-or-directory-modify-seconds] 来提取列表中每个文件的时间戳，
那么 @racket[cache-keys?] 应为 @racket[#t] 以最小化文件系统调用，
但如果 @racket[extract-key] 是 @racket[car]，那么 @racket[cache-keys?] 应为 @racket[#f]。
再举一例，将 @racket[extract-key] 提供为 @racket[(lambda (x) (random))] 且 @racket[cache-keys?] 为 @racket[#t]，
实际上会对列表进行洗牌。

@mz-examples[
  (sort '(1 3 4 2) <)
  (sort '("aardvark" "dingo" "cow" "bear") string<?)
  (sort '(("aardvark") ("dingo") ("cow") ("bear"))
        #:key car string<?)]


@; ----------------------------------------
@section{列表搜索}

@defproc*[([(member [v any/c] [lst list?]
                    [is-equal? (any/c any/c . -> . any/c) equal?])
            (or/c #f list?)]
           [(member [v any/c] [lst any/c]
                    [is-equal? (any/c any/c . -> . any/c) equal?])
            any/c])]{

定位 @racket[lst] 中第一个根据 @racket[is-equal?] 等于 @racket[v] 的元素。
如果存在这样的元素，则返回从该元素开始的 @racket[lst] 尾部。
否则，结果为 @racket[#f]。

@racket[lst] 参数实际上不必是列表；@racket[lst] 必须仅以序对链开头，直到找到匹配元素。
如果未找到匹配元素，则 @racket[lst] 必须是列表（而不是循环列表）。
在找到匹配元素且返回的 @racket[lst] 尾部是非列表的情况下，结果可以是非列表。

@mz-examples[
  (member 2 (list 1 2 3 4))
  (member 9 (list 1 2 3 4))
  (member #'x (list #'x #'y) free-identifier=?)
  (member #'a (list #'x #'y) free-identifier=?)
  (member 'b '(a b . etc))
  (eval:error (member 'c '(a b . etc)))]}


@defproc*[([(memw [v any/c] [lst list?]) (or/c #f list?)]
           [(memw [v any/c] [lst any/c]) any/c])]{

像 @racket[member]，但使用 @racket[equal-always?] 查找元素。

@mz-examples[
  (memw 2 (list 1 2 3 4))
  (memw 9 (list 1 2 3 4))
  (define b1 (box 5))
  (define b2 (box 5))
  (memw b2 (list 0 b1 1 b2 2))]

@history[#:added "8.5.0.3"]}


@defproc*[([(memv [v any/c] [lst list?]) (or/c #f list?)]
           [(memv [v any/c] [lst any/c]) any/c])]{

像 @racket[member]，但使用 @racket[eqv?] 查找元素。

@mz-examples[
  (memv 2 (list 1 2 3 4))
  (memv 9 (list 1 2 3 4))]}


@defproc*[([(memq [v any/c] [lst list?]) (or/c #f list?)]
           [(memq [v any/c] [lst any/c]) any/c])]{

像 @racket[member]，但使用 @racket[eq?] 查找元素。

@mz-examples[
  (memq 2 (list 1 2 3 4))
  (memq 9 (list 1 2 3 4))]}


@defproc*[([(memf [proc procedure?] [lst list?]) (or/c #f list?)]
           [(memf [proc procedure?] [lst any/c]) any/c])]{

像 @racket[member]，但使用谓词 @racket[proc] 查找元素；
当 @racket[proc] 应用于元素返回真值时找到元素。

@mz-examples[
  (memf (lambda (arg)
          (> arg 9))
        '(7 8 9 10 11))]}


@defproc*[([(findf [proc procedure?] [lst list?]) (or/c #f any/c)]
           [(findf [proc procedure?] [lst any/c]) any/c])]{

像 @racket[memf]，但返回元素或 @racket[#f]，而不是 @racket[lst] 的尾部或 @racket[#f]。

值得注意的是，如果 @racket[#f] 是 @racket[lst] 的元素，
那么 @racket[#f] 的结果是模糊的：
它可能表示没有元素满足 @racket[proc]，
或者可能表示元素 @racket[#f] 满足 @racket[proc]。

@mz-examples[
  (findf (lambda (arg)
           (> arg 9))
         '(7 8 9 10 11))]}


@defproc*[([(assoc [v any/c]
                   [lst (listof pair?)]
                   [is-equal? (any/c any/c . -> . any/c) equal?])
            (or/c pair? #f)]
           [(assoc [v any/c]
                   [lst (list*of pair? (not/c '()))]
                   [is-equal? (any/c any/c . -> . any/c) equal?])
            pair?])]{

定位 @racket[lst] 中第一个 @racket[car] 根据 @racket[is-equal?] 等于 @racket[v] 的元素。
如果存在这样的元素，则返回该序对（即 @racket[lst] 的元素）。
否则，结果为 @racket[#f]。

@racket[lst] 参数实际上不必是序对列表；@racket[lst] 必须仅以包含序对的序对链开头，
直到找到匹配元素。如果未找到匹配元素，则 @racket[lst] 必须是序对列表（而不是循环列表）。

@mz-examples[
  (assoc 3 (list (list 1 2) (list 3 4) (list 5 6)))
  (assoc 9 (list (list 1 2) (list 3 4) (list 5 6)))
  (assoc 3.5
         (list (list 1 2) (list 3 4) (list 5 6))
         (lambda (a b) (< (abs (- a b)) 1)))]}


@defproc*[([(assw [v any/c] [lst (listof pair?)]) (or/c pair? #f)]
           [(assw [v any/c] [lst (list*of pair? (not/c '()))]) pair?])]{

像 @racket[assoc]，但使用 @racket[equal-always?] 查找元素。

@mz-examples[
  (assw 3 (list (list 1 2) (list 3 4) (list 5 6)))
  (define b1 (box 0))
  (define b2 (box 0))
  (assw b2 (list (cons b1 1) (cons b2 2)))]

@history[#:added "8.5.0.3"]}


@defproc*[([(assv [v any/c] [lst (listof pair?)]) (or/c pair? #f)]
           [(assv [v any/c] [lst (list*of pair? (not/c '()))]) pair?])]{

像 @racket[assoc]，但使用 @racket[eqv?] 查找元素。

@mz-examples[
  (assv 3 (list (list 1 2) (list 3 4) (list 5 6)))]}


@defproc*[([(assq [v any/c] [lst (listof pair?)]) (or/c pair? #f)]
           [(assq [v any/c] [lst (list*of pair? (not/c '()))]) pair?])]{

像 @racket[assoc]，但使用 @racket[eq?] 查找元素。

@mz-examples[
  (assq 'c (list (list 'a 'b) (list 'c 'd) (list 'e 'f)))]}


@defproc*[([(assf [proc procedure?] [lst (listof pair?)]) (or/c pair? #f)]
           [(assf [proc procedure?] [lst (list*of pair? (not/c '()))]) pair?])]{

像 @racket[assoc]，但使用谓词 @racket[proc] 查找元素；
当 @racket[proc] 应用于 @racket[lst] 元素的 @racket[car] 返回真值时找到元素。

@mz-examples[
  (assf (lambda (arg)
          (> arg 2))
        (list (list 1 2) (list 3 4) (list 5 6)))]}


@; ----------------------------------------
@section{序对访问器简写}

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
@defc_r[d a d '(9 (7 6 5 4 3 2 1) 8)]
@defc_r[d d d a '((7 6 5 4 3 2 1) 8 9)]
@defc_r[d d d d '(4 3 2 1)]


@; ----------------------------------------
@section{附加列表函数与同义词}

@note-lib[racket/list]


@defthing[empty null?]{

  空列表。

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

与 @racket[(car lst)] 相同，但仅用于列表（非空）。

@mz-examples[#:eval list-eval
  (first '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(rest [lst list?])
         list?]{

与 @racket[(cdr lst)] 相同，但仅用于列表（非空）。

@mz-examples[#:eval list-eval
  (rest '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(second [lst list?]) any/c]{

返回列表的第二个元素。

@mz-examples[#:eval list-eval
  (second '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(third [lst list?]) any/c]{

返回列表的第三个元素。

@mz-examples[#:eval list-eval
  (third '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(fourth [lst list?]) any/c]{

返回列表的第四个元素。

@mz-examples[#:eval list-eval
  (fourth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(fifth [lst list?]) any/c]{

返回列表的第五个元素。

@mz-examples[#:eval list-eval
  (fifth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(sixth [lst list?]) any/c]{

返回列表的第六个元素。

@mz-examples[#:eval list-eval
  (sixth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(seventh [lst list?]) any/c]{

返回列表的第七个元素。

@mz-examples[#:eval list-eval
  (seventh '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(eighth [lst list?]) any/c]{

返回列表的第八个元素。

@mz-examples[#:eval list-eval
  (eighth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(ninth [lst list?]) any/c]{

返回列表的第九个元素。

@mz-examples[#:eval list-eval
  (ninth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(tenth [lst list?]) any/c]{

返回列表的第十个元素。

@mz-examples[#:eval list-eval
  (tenth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(eleventh [lst list?]) any/c]{

返回列表的第十一个元素。

@mz-examples[#:eval list-eval
  (eleventh '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]

@history[#:added "8.15.0.3"]}


@defproc[(twelfth [lst list?]) any/c]{

返回列表的第十二个元素。

@mz-examples[#:eval list-eval
  (twelfth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]

@history[#:added "8.15.0.3"]}


@defproc[(thirteenth [lst list?]) any/c]{

返回列表的第十三个元素。

@mz-examples[#:eval list-eval
  (thirteenth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]

@history[#:added "8.15.0.3"]}


@defproc[(fourteenth [lst list?]) any/c]{

返回列表的第十四个元素。

@mz-examples[#:eval list-eval
  (fourteenth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]

@history[#:added "8.15.0.3"]}


@defproc[(fifteenth [lst list?]) any/c]{

返回列表的第十五个元素。

@mz-examples[#:eval list-eval
  (fifteenth '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]

@history[#:added "8.15.0.3"]}


@defproc[(last [lst list?]) any/c]{

返回列表的最后一个元素。

此函数花费的时间与 @racket[lst] 的长度成正比。

@mz-examples[#:eval list-eval
  (last '(1 2 3 4 5 6 7 8 9 10 11 12 13 14 15))]}


@defproc[(last-pair [p pair?])
         pair?]{

返回（可能非正常）列表的最后一个序对。

此函数花费的时间与 @racket[p] 的``长度''成正比。

@mz-examples[#:eval list-eval
  (last-pair '(1 2 3 4))]}


@defproc[(make-list [k exact-nonnegative-integer?] [v any/c])
         list?]{

返回一个长度为 @racket[k] 的新构造列表，所有位置都保存 @racket[v]。

@mz-examples[#:eval list-eval
  (make-list 7 'foo)]}

@defproc[(list-update [lst list?]
                      [pos (and/c (>=/c 0) (</c (length lst)))]
                      [updater (-> any/c any/c)])
         list?]{

返回一个与 @racket[lst] 相同的列表，除了指定索引处。
指定索引处的元素是 @racket[(updater (list-ref lst pos))]。

此函数花费的时间与 @racket[pos] 成正比。

@examples[#:eval list-eval
(list-update '(zero one two) 1 symbol->string)]
@history[#:added "6.3"]{}}

@defproc[(list-set [lst list?]
                   [pos (and/c (>=/c 0) (</c (length lst)))]
                   [value any/c])
         list?]{

返回一个与 @racket[lst] 相同的列表，除了指定索引处。
指定索引处的元素是 @racket[value]。

此函数花费的时间与 @racket[pos] 成正比。

@examples[#:eval list-eval
(list-set '(zero one two) 2 "two")]
@history[#:added "6.3"]{}}

@defproc[(index-of [lst list?] [v any/c]
                   [is-equal? (any/c any/c . -> . any/c) equal?])
         (or/c exact-nonnegative-integer? #f)]{

像 @racket[member]，但返回找到的第一个元素的索引，而不是列表的尾部。
                          
@mz-examples[#:eval list-eval
  (index-of '(1 2 3 4) 3)]

@history[#:added "6.7.0.3"]}

@defproc[(index-where [lst list?] [proc (any/c . -> . any/c)])
         (or/c exact-nonnegative-integer? #f)]{

像 @racket[index-of]，但具有 @racket[memf] 的谓词搜索行为。

@mz-examples[#:eval list-eval
  (index-where '(1 2 3 4) even?)]

@history[#:added "6.7.0.3"]}

@defproc[(indexes-of [lst list?] [v any/c]
                     [is-equal? (any/c any/c . -> . any/c) equal?])
         (listof exact-nonnegative-integer?)]{

像 @racket[index-of]，但返回元素在列表中出现的所有索引的列表，而不仅仅是第一个。
                          
@mz-examples[#:eval list-eval
  (indexes-of '(1 2 1 2 1) 2)]

@history[#:added "6.7.0.3"]}

@defproc[(indexes-where [lst list?] [proc (any/c . -> . any/c)])
         (listof exact-nonnegative-integer?)]{

像 @racket[indexes-of]，但具有 @racket[index-where] 的谓词搜索行为。

@mz-examples[#:eval list-eval
  (indexes-where '(1 2 3 4) even?)]

@history[#:added "6.7.0.3"]}

@defproc*[([(take [lst list?] [pos exact-nonnegative-integer?]) list?]
           [(take [lst any/c] [pos exact-nonnegative-integer?]) list?])]{

返回一个新列表，其元素是 @racket[lst] 的前 @racket[pos] 个元素。
如果 @racket[lst] 少于 @racket[pos] 个元素，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是列表；@racket[lst] 必须至少以 @racket[pos] 个序对组成的链开头。

此函数花费的时间与 @racket[pos] 成正比。

@mz-examples[#:eval list-eval
  (take '(1 2 3 4 5) 2)
  (take 'non-list 0)]}


@defproc*[([(drop [lst list?] [pos exact-nonnegative-integer?]) list?]
           [(drop [lst any/c] [pos exact-nonnegative-integer?]) any/c])]{

与 @racket[list-tail] 完全相同。}


@defproc*[([(split-at [lst list?] [pos exact-nonnegative-integer?])
            (values list? list?)]
           [(split-at [lst any/c] [pos exact-nonnegative-integer?])
            (values list? any/c)])]{

返回与

@racketblock[(values (take lst pos) (drop lst pos))]

相同的结果，但可能更快，不过仍然花费与 @racket[pos] 成正比的时间。}


@defproc*[([(takef [lst list?] [pred procedure?]) list?]
           [(takef [lst any/c] [pred procedure?]) list?])]{

返回一个新列表，其元素从 @racket[lst] 中依次取出，只要它们满足 @racket[pred]。
返回的列表包括直到（但不包括）@racket[lst] 中第一个 @racket[pred] 返回 @racket[#f] 的元素。

@racket[lst] 参数实际上不必是列表；@racket[lst] 中的序对链将被遍历，直到遇到非序对。

@mz-examples[#:eval list-eval
  (takef '(2 4 5 8) even?)
  (takef '(2 4 6 8) odd?)
  (takef '(2 4 . 6) even?)]}


@defproc*[([(dropf [lst list?] [pred procedure?]) list?]
           [(dropf [lst any/c] [pred procedure?]) any/c])]{

从 @racket[lst] 的前端丢弃元素，只要它们满足 @racket[pred]。

@mz-examples[#:eval list-eval
  (dropf '(2 4 5 8) even?)
  (dropf '(2 4 6 8) odd?)]}


@defproc*[([(splitf-at [lst list?] [pred procedure?])
            (values list? list?)]
           [(splitf-at [lst any/c] [pred procedure?])
            (values list? any/c)])]{

返回与

@racketblock[(values (takef lst pred) (dropf lst pred))]

相同的结果，但可能更快。}


@defproc*[([(take-right [lst list?] [pos exact-nonnegative-integer?]) list?]
           [(take-right [lst any/c] [pos exact-nonnegative-integer?]) any/c])]{

返回 @racket[list] 的 @racket[pos] 长度的尾部。如果 @racket[lst]
少于 @racket[pos] 个元素，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是列表；@racket[lst]
必须至少以 @racket[pos] 个序对组成的链结尾。

此函数花费的时间与 @racket[lst] 的长度成正比。

@mz-examples[#:eval list-eval
  (take-right '(1 2 3 4 5) 2)
  (take-right 'non-list 0)]}


@defproc*[([(drop-right [lst list?] [pos exact-nonnegative-integer?]) list?]
           [(drop-right [lst any/c] [pos exact-nonnegative-integer?]) list?])]{

返回一个新列表，其元素是 @racket[lst] 的前缀，丢弃其 @racket[pos] 长度的尾部。
如果 @racket[lst] 少于 @racket[pos] 个元素，则 @exnraise[exn:fail:contract]。

@racket[lst] 参数实际上不必是列表；@racket[lst] 必须至少以 @racket[pos] 个序对组成的链结尾。

此函数花费的时间与 @racket[lst] 的长度成正比。

@mz-examples[#:eval list-eval
  (drop-right '(1 2 3 4 5) 2)
  (drop-right 'non-list 0)]}


@defproc*[([(split-at-right [lst list?] [pos exact-nonnegative-integer?])
            (values list? list?)]
           [(split-at-right [lst any/c] [pos exact-nonnegative-integer?])
            (values list? any/c)])]{

返回与

@racketblock[(values (drop-right lst pos) (take-right lst pos))]

相同的结果，但可能更快，不过仍然花费与 @racket[lst] 长度成正比的时间。

@mz-examples[#:eval list-eval
  (split-at-right '(1 2 3 4 5 . 6) 4)
  (split-at-right '(1 2 3 4 5 6) 4)]}


@deftogether[(
  @defproc*[([(takef-right [lst list?] [pred procedure?]) list?]
             [(takef-right [lst any/c] [pred procedure?]) any/c])]
  @defproc*[([(dropf-right [lst list?] [pred procedure?]) list?]
             [(dropf-right [lst any/c] [pred procedure?]) list?])]
  @defproc*[([(splitf-at-right [lst list?] [pred procedure?]) (values list? list?)]
             [(splitf-at-right [lst any/c] [pred procedure?]) (values list? any/c)])]
)]{

像 @racket[takef]、@racket[dropf] 和 @racket[splitf-at]，但
与 @racket[take-right]、@racket[drop-right] 和 @racket[split-at-right] 的从右功能结合。}

@defproc[(list-prefix? [l list?]
                       [r list?]
                       [same? (any/c any/c . -> . any/c) equal?])
         boolean?]{
 如果 @racket[l] 是 @racket[r] 的前缀则返回真。
@examples[#:eval list-eval
(list-prefix? '(1 2) '(1 2 3 4 5))
]
@history[#:added "6.3"]{}}

@defproc[(take-common-prefix [l list?] [r list?]
                             [same? (any/c any/c . -> . any/c) equal?])
         list?]{

  返回 @racket[l] 和 @racket[r] 的最长公共前缀。

@examples[#:eval list-eval
(take-common-prefix '(a b c d) '(a b x y z))
]
@history[#:added "6.3"]{}}

@defproc[(drop-common-prefix [l list?] [r list?]
                             [same? (any/c any/c . -> . any/c) equal?])
         (values list? list?)]{

  返回 @racket[l] 和 @racket[r] 的尾部，公共前缀已移除。

@examples[#:eval list-eval
(drop-common-prefix '(a b c d) '(a b x y z))
]
@history[#:added "6.3"]{}}

@defproc[(split-common-prefix [l list?] [r list?]
                              [same? (any/c any/c . -> . any/c) equal?])
         (values list? list? list?)]{

  返回最长公共前缀以及 @racket[l] 和 @racket[r] 的尾部（公共前缀已移除）。

@examples[#:eval list-eval
(split-common-prefix '(a b c d) '(a b x y z))
]
@history[#:added "6.3"]{}}


@defproc[(add-between [lst list?] [v any/c]
                      [#:before-first before-first list? '()]
                      [#:before-last  before-last  any/c v]
                      [#:after-last   after-last   list? '()]
                      [#:splice? splice? any/c #f])
         list?]{

返回一个与 @racket[lst] 具有相同元素的列表，但在 @racket[lst] 的每对元素之间插入 @racket[v]；
最后一对元素之间将插入 @racket[before-last]，而不是 @racket[v]（但 @racket[before-last] 默认为 @racket[v]）。

如果 @racket[splice?] 为真，则 @racket[v] 和 @racket[before-last] 应该是列表，
并且列表元素被拼接到结果中。此外，当 @racket[splice?] 为真时，
@racket[before-first] 和 @racket[after-last] 分别插入到第一个元素之前和最后一个元素之后。

@mz-examples[#:eval list-eval
  (add-between '(x y z) 'and)
  (add-between '(x) 'and)
  (add-between '("a" "b" "c" "d") "," #:before-last "and")
  (add-between '(x y z) '(-) #:before-last '(- -)
               #:before-first '(begin) #:after-last '(end LF)
               #:splice? #t)]}


@defproc*[([(append* [lst list?] ... [lsts (listof list?)]) list?]
           [(append* [lst list?] ... [lsts list?]) any/c])]{

像 @racket[append]，但最后一个参数用作 @racket[append] 的参数列表，
所以 @racket[(append* lst ... lsts)] 与 @racket[(apply append lst ... lsts)] 相同。
换句话说，@racket[append] 和 @racket[append*] 之间的关系类似于
@racket[list] 和 @racket[list*] 之间的关系。

@mz-examples[#:eval list-eval
  (append* '(a) '(b) '((c) (d)))
  (cdr (append* (map (lambda (x) (list ", " x))
                     '("Alpha" "Beta" "Gamma"))))]}


@defproc[(flatten [v any/c])
         list?]{

将任意序对结构的 S-表达式展平为列表。
更准确地说，@racket[v] 被视为二叉树，其中序对是内部节点，
结果列表包含树的所有非 @racket[null] 叶子，顺序与中序遍历相同。

@mz-examples[#:eval list-eval
  (flatten '((a) b (c (d) . e) ()))
  (flatten 'a)]}


@defproc[(check-duplicates [lst list?]
                           [same? (any/c any/c . -> . any/c) equal?]
                           [#:key extract-key (-> any/c any/c) (lambda (x) x)]
                           [#:default failure-result failure-result/c (lambda () #f)])
         any]{

返回 @racket[lst] 中的第一个重复项。更准确地说，
返回第一个 @racket[_x]，使得存在前一个 @racket[_y]，其中 @racket[(same? (extract-key _x) (extract-key _y))]。

如果未找到重复项，则 @racket[failure-result] 决定结果：

@itemize[

 @item{如果 @racket[failure-result] 是过程，则调用它（通过尾部调用）不带参数以产生结果。}

 @item{否则，@racket[failure-result] 作为结果返回。}

]

@racket[same?] 参数应该是等价谓词，如 @racket[equal?] 或 @racket[eqv?]。
过程 @racket[equal?]、@racket[eqv?]、@racket[eq?] 和 @racket[equal-always?] 自动使用字典来提高速度。

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

返回一个包含 @racket[lst] 中所有项但没有重复项的列表，
其中 @racket[same?] 确定两个列表元素是否等价。
结果列表与 @racket[lst] 顺序相同，对于多次出现的项，保留第一个。

@racket[#:key] 参数 @racket[extract-key] 用于从每个列表元素中提取键值，
因此如果 @racket[(same? (extract-key x) (extract-key y))] 为真，则两项被视为相等。

像 @racket[check-duplicates]，如果 @racket[same?] 参数是
@racket[equal?]、@racket[eqv?]、@racket[eq?] 和 @racket[equal-always?] 之一，
操作可以专门化以提高性能。

@mz-examples[#:eval list-eval
  (remove-duplicates '(a b b a))
  (remove-duplicates '(1 2 1.0 0))
  (remove-duplicates '(1 2 1.0 0) =)]}


@defproc[(filter-map [proc procedure?] [lst list?] ...+)
         list?]{

像 @racket[(map proc lst ...)]，但如果 @racket[proc]
返回 @racket[#false]，则该元素从结果列表中省略。
换句话说，@racket[filter-map] 等价于
@racket[(filter (lambda (x) x) (map proc lst ...))]，但更高效，
因为 @racket[filter-map] 避免构建中间列表。

@mz-examples[#:eval list-eval
  (filter-map (lambda (x) (and (negative? x) (abs x))) '(1 2 -3 -4 8))]}


@defproc[(count [proc procedure?] [lst list?] ...+)
         exact-nonnegative-integer?]{

返回 @racket[(length (filter-map proc lst ...))]，但不构建中间列表。

@mz-examples[#:eval list-eval
  (count positive? '(1 -1 2 3 -2 5))]}


@defproc[(partition [pred procedure?] [lst list?])
         (values list? list?)]{

类似于 @racket[filter]，但返回两个值：
@racket[pred] 返回真值的项，以及 @racket[pred] 返回 @racket[#f] 的项。

结果与

@racketblock[(values (filter pred lst) (filter (negate pred) lst))]

相同，但 @racket[pred] 仅应用于 @racket[lst] 中的每个项一次。

@mz-examples[#:eval list-eval
  (partition even? '(1 2 3 4 5 6))]}


@defproc*[([(range [end real?]) list?]
           [(range [start real?] [end real?] [step real? 1]) list?])]{

类似于 @racket[in-range]，但返回列表。

结果列表保存从 @racket[start] 开始的数字，
其连续元素通过在前一个元素上加 @racket[step] 计算，
直到达到 @racket[end]（不包括）。如果未提供起始点，使用 @racket[0]。
如果未提供 @racket[step] 参数，使用 @racket[1]。

像 @racket[in-range]，当 @racket[range] 直接出现在 @racket[for] 子句中时可以提供更好的性能。

@mz-examples[#:eval list-eval
  (range 10)
  (range 10 20)
  (range 20 40 2)
  (range 20 10 -1)
  (range 10 15 1.5)]

@history[#:changed "6.7.0.4"
         @elem{调整为与 @racket[for] 协作，方式与 @racket[in-range] 相同。}]}


@defproc[(inclusive-range [start real?] [end real?] [step real? 1]) list?]{

类似于 @racket[in-inclusive-range]，但返回列表。

结果列表保存从 @racket[start] 开始的数字，
其连续元素通过在前一个元素上加 @racket[step] 计算，
直到达到 @racket[end]（包括）。如果未提供 @racket[step] 参数，使用 @racket[1]。

像 @racket[in-inclusive-range]，当 @racket[inclusive-range] 直接出现在 @racket[for] 子句中时可以提供更好的性能。

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

像 @racket[filter]，但 @racket[pred] 谓词的含义反转：
结果是 @racket[pred] 返回 @racket[#f] 的所有项的列表。

@mz-examples[#:eval list-eval
  (filter-not even? '(1 2 3 4 5 6))]}


@defproc[(shuffle [lst list?])
         list?]{

返回一个包含 @racket[lst] 中所有元素的列表，随机洗牌。

@mz-examples[#:eval list-eval
  (shuffle '(1 2 3 4 5 6))
  (shuffle '(1 2 3 4 5 6))
  (shuffle '(1 2 3 4 5 6))]}


@defproc*[([(combinations [lst list?]) list?]
           [(combinations [lst list?] [size exact-nonnegative-integer?]) list?])]{
@margin-note{Wikipedia @hyperlink["https://en.wikipedia.org/wiki/Combination"]{combinations}}
返回输入列表中元素的所有组合的列表
（也称为 @racket[lst] 的 @index["powerset"]{幂集}）。
如果给定 @racket[size]，则将结果限制为 @racket[size] 个元素的组合。

@mz-examples[#:eval list-eval
  (combinations '(1 2 3))
  (combinations '(1 2 3) 2)]}


@defproc*[([(in-combinations [lst list?]) sequence?]
           [(in-combinations [lst list?] [size exact-nonnegative-integer?]) sequence?])]{
@index["in-powerset"]{返回}输入列表中元素的所有组合的序列，
或者如果给定 @racket[size]，则返回长度为 @racket[size] 的所有组合。
逐个构建组合，而不是一次性构建。

@mz-examples[#:eval list-eval
  (time (begin (combinations (range 15)) (void)))
  (time (begin (in-combinations (range 15)) (void)))]}


@defproc[(permutations [lst list?])
         list?]{

@index["rearrangements"]{返回}输入列表的所有排列的列表。
请注意，此函数工作时不检查元素，因此忽略重复元素（这将导致重复排列）。
如果输入列表包含超过 256 个元素则引发错误。

@mz-examples[#:eval list-eval
  (permutations '(1 2 3))
  (permutations '(x x))]}


@defproc[(in-permutations [lst list?])
         sequence?]{

@index["in-rearrangements"]{返回}输入列表的所有排列的序列。
它等价于 @racket[(in-list (permutations l))]，但由于在每次迭代中逐个构建排列，因此速度更快。
如果输入列表包含超过 256 个元素则引发错误。}


@defproc[(argmin [proc (-> any/c real?)] [lst (and/c pair? list?)])
         any/c]{

返回列表 @racket[lst] 中使 @racket[proc] 结果最小的第一个元素。
在空列表上引发错误。另参见 @racket[min]。

@mz-examples[#:eval list-eval
  (argmin car '((3 pears) (1 banana) (2 apples)))
  (argmin car '((1 banana) (1 orange)))]}


@defproc[(argmax [proc (-> any/c real?)] [lst (and/c pair? list?)])
         any/c]{

返回列表 @racket[lst] 中使 @racket[proc] 结果最大的第一个元素。
在空列表上引发错误。另参见 @racket[max]。

@mz-examples[#:eval list-eval
  (argmax car '((3 pears) (1 banana) (2 apples)))
  (argmax car '((3 pears) (3 oranges)))]}


@defproc[(group-by [key (-> any/c any/c)]
                   [lst list?]
                   [same? (any/c any/c . -> . any/c) equal?])
         (listof list?)]{

将给定列表分组为等价类，等价性由 @racket[same?] 确定。
在每个等价类内，@racket[group-by] 保持原始列表的顺序。
等价类本身按照在输入中首次出现的顺序排列。

@examples[#:eval list-eval
(group-by (lambda (x) (modulo x 3)) '(1 2 1 2 54 2 5 43 7 2 643 1 2 0))
]
@history[#:added "6.3"]{}}

@defproc[(cartesian-product [lst list?] ...)
         (listof list?)]{

计算给定列表的 n 元笛卡尔积。

@examples[#:eval list-eval
(cartesian-product '(1 2 3) '(a b c))
(cartesian-product '(4 5 6) '(d e f) '(#t #f))
]
@history[#:added "6.3"]{}}

@defproc[(remf [pred procedure?]
               [lst list?])
         list?]{

返回一个类似 @racket[lst] 的列表，省略 @racket[lst] 中第一个 @racket[pred] 产生真值的元素。

@examples[
#:eval list-eval
(remf negative? '(1 -2 3 4 -5))
]
@history[#:added "6.3"]{}}

@defproc[(remf* [pred procedure?]
                [lst list?])
         list?]{

像 @racket[remf]，但移除 @racket[pred] 产生真值的所有元素。

@examples[
#:eval list-eval
(remf* negative? '(1 -2 3 4 -5))
]
@history[#:added "6.3"]{}}


@; ----------------------------------------
@section{更多列表分组}

@note-lib-only[racket/list/grouping]

本节中的绑定由 @racket[sequence-tools-lib] 包提供，
它作为基本序列库的扩展。

@defproc[(windows [size exact-positive-integer?] [step exact-positive-integer?] [lst list?]) 
         (listof list?)]{

返回一个滑动窗口列表，使得每个窗口包含 @racket[size] 个元素，窗口每次滑动 @racket[step] 个位置。
如果剩余元素数量少于 @racket[size]，则这些元素被丢弃。

@examples[#:eval list-eval
  (windows 3 1 '(1 2 3 4))
  (windows 2 3 '(1 2 3))
  (windows 1 2 '(1 2 3 4))]}


@defproc[(slice-by [proc (-> any/c any/c any/c)] [lst list?])
         (listof list?)]{

返回一个列表，其中每个元素是一个子列表（切片），通过比较每对相邻元素构建。
所有满足 @racket[proc] 的元素对将被分组到一个切片中，
否则该元素将开始一个新的切片。

@examples[#:eval list-eval
  (slice-by eq? '(1 1 2 1 3 3))
  (slice-by < '(1 2 3 3 4))]}


@close-eval[list-eval]


@; ----------------------------------------
@section{不可变循环数据}

@defproc[(make-reader-graph [v any/c])
         any/c]{

返回一个类似 @racket[v] 的值，其中由 @racket[make-placeholder] 创建的 @deftech{占位符}
被替换为它们包含的值，由 @racket[make-hash-placeholder] 创建的 @deftech{哈希占位符}
被替换为不可变哈希表。@racket[v] 的任何部分都不会被修改；
相反，@racket[v] 的部分在必要时被复制以构建结果图，
对于任何给定值最多创建一个副本。

由于复制的值可以是不可变的，并且副本也是不可变的，
@racket[make-reader-graph] 可以创建仅涉及不可变序对、向量、盒子和哈希表的循环。

只有以下类型的值会被复制和遍历以检测占位符：

@itemize[

 @item{序对}

 @item{向量，可变和不可变的}

 @item{盒子，可变和不可变的}

 @item{哈希表，可变和不可变的}

 @item{@techlink{prefab} 结构类型的实例}

 @item{由 @racket[make-placeholder] 和 @racket[make-hash-placeholder] 创建的占位符}]

由于这些限制，@racket[make-reader-graph] 创建与 @racket[read] 完全相同的循环值。

@mz-examples[
  (let* ([ph (make-placeholder #f)]
         [x (cons 1 ph)])
    (placeholder-set! ph x)
    (make-reader-graph x))]}


@defproc[(placeholder? [v any/c])
         boolean?]{

如果 @racket[v] 是由 @racket[make-placeholder] 创建的 @tech{占位符}则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-placeholder [v any/c])
         placeholder?]{

返回一个用于 @racket[placeholder-set!] 和 @racket[make-reader-graph] 的 @tech{占位符}。
@racket[v] 参数提供占位符的初始值。}


@defproc[(placeholder-set! [ph placeholder?] [datum any/c])
         void?]{

将 @racket[ph] 的值更改为 @racket[v]。}


@defproc[(placeholder-get [ph placeholder?])
         any/c]{

返回 @racket[ph] 的值。}


@defproc[(hash-placeholder? [v any/c])
         boolean?]{

如果 @racket[v] 是由 @racket[make-hash-placeholder] 创建的 @tech{哈希占位符}则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-hash-placeholder [assocs (listof pair?)])
         hash-placeholder?]{

像 @racket[make-immutable-hash]，但产生一个用于 @racket[make-reader-graph] 的 @tech{哈希占位符}。}


@defproc[(make-hasheq-placeholder [assocs (listof pair?)])
         hash-placeholder?]{

像 @racket[make-immutable-hasheq]，但产生一个用于 @racket[make-reader-graph] 的 @tech{哈希占位符}。}


@defproc[(make-hasheqv-placeholder [assocs (listof pair?)])
         hash-placeholder?]{

像 @racket[make-immutable-hasheqv]，但产生一个用于 @racket[make-reader-graph] 的 @tech{哈希占位符}。}


@defproc[(make-hashalw-placeholder [assocs (listof pair?)])
         hash-placeholder?]{

像 @racket[make-immutable-hashalw]，但产生一个用于 @racket[make-reader-graph] 的 @tech{哈希占位符}。

@history[#:added "8.5.0.3"]}
