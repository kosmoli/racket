#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "for"]{Iterations and Comprehensions}

@racket[for] 系列语法形式支持对 @defterm{sequence}（序列）进行迭代。列表、vector、字符串、字节字符串、输入 port 和 hash table 都可以用作序列，而像 @racket[in-range] 这样的构造器还提供了更多种类的序列。

@racket[for] 的变体以不同方式累积迭代结果，但它们都具有相同的语法形状。简化的 @racket[for] 语法为

@specform[
(for ([id sequence-expr] ...)
  body ...+)
]{}

@racket[for] 循环遍历 @racket[_sequence-expr] 产生的序列。对于序列中的每个元素，@racket[for] 将元素绑定到 @racket[_id]，然后对 @racket[_body] 求值以获取副作用。

@examples[
(for ([i '(1 2 3)])
  (display i))
(for ([i "abc"])
  (printf "~a..." i))
(for ([i 4])
  (display i))
]

@racket[for] 的 @racket[for/list] 变体更符合 Racket 风格。它将 @racket[_body] 结果累积到列表中，而不是仅为副作用而对 @racket[_body] 求值。用更技术性的术语来说，@racket[for/list] 实现了一个 @defterm{list comprehension}（列表推导）。

@examples[
(for/list ([i '(1 2 3)])
  (* i i))
(for/list ([i "abc"])
  i)
(for/list ([i 4])
  i)
]

@racket[for] 的完整语法支持多个序列并行迭代，而 @racket[for*] 变体将迭代嵌套而非并行运行。@racket[for] 和 @racket[for*] 的更多变体以不同方式累积 @racket[_body] 结果。在所有这些变体中，可以在绑定中包含修剪迭代的谓词。

不过，在详细介绍 @racket[for] 的各种变体之前，最好先看看能产生有趣示例的序列生成器。

@section[#:tag "sequences"]{Sequence Constructors}

@racket[in-range] 函数生成一个数字序列，接受一个可选的起始数（默认为 @racket[0]）、一个序列结束的数（不含该数）和一个可选的步长（默认为 @racket[1]）。直接使用非负整数 @racket[_k] 作为序列是 @racket[(in-range _k)] 的简写。

@examples[
(for ([i 3])
  (display i))
(for ([i (in-range 3)])
  (display i))
(for ([i (in-range 1 4)])
  (display i))
(for ([i (in-range 1 4 2)])
  (display i))
(for ([i (in-range 4 1 -1)])
  (display i))
(for ([i (in-range 1 4 1/2)])
  (printf " ~a " i))
]

@racket[in-naturals] 函数类似，但起始数必须是精确非负整数（默认为 @racket[0]），步长始终为 @racket[1]，且没有上限。仅使用 @racket[in-naturals] 的 @racket[for] 循环将永远不会终止，除非主体表达式引发异常或以其他方式逃逸。

@examples[
(for ([i (in-naturals)])
  (if (= i 10)
      (error "too much!")
      (display i)))
]

@racket[stop-before] 和 @racket[stop-after] 函数给定一个序列和一个谓词，构造一个新序列。新序列类似于给定序列，但在谓词返回 true 的第一个元素之前或之后截断。

@examples[
(for ([i (stop-before "abc def"
                      char-whitespace?)])
  (display i))
]

像 @racket[in-list]、@racket[in-vector] 和 @racket[in-string] 这样的序列构造器只是显式地将列表、vector 或字符串用作序列。与 @racket[in-range] 一起，这些构造器在给定错误类型的值时会引发异常，并且由于它们避免了运行时分派来确定序列类型，因此能实现更高效的代码生成；更多信息请参见 @secref["for-performance"]。

@examples[
(for ([i (in-string "abc")])
  (display i))
(for ([i (in-string '(1 2 3))])
  (display i))
]

@refdetails["sequences"]{sequences}

@section{@racket[for] and @racket[for*]}

@racket[for] 的更完整语法为

@specform/subs[
(for (clause ...)
  body ...+)
([clause [id sequence-expr]
         (code:line #:when boolean-expr)
         (code:line #:unless boolean-expr)])
]{}

当在 @racket[for] 形式中提供多个 @racket[[_id _sequence-expr]] 子句时，对应的序列将并行遍历：

@interaction[
(for ([i (in-range 1 4)]
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "Chapter ~a. ~a\n" i chapter))
]

使用并行序列时，@racket[for] 表达式在任何序列结束时停止迭代。这种行为允许创建无限数字序列的 @racket[in-naturals] 用于索引：

@interaction[
(for ([i (in-naturals 1)]
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "Chapter ~a. ~a\n" i chapter))
]

@racket[for*] 形式与 @racket[for] 语法相同，但将多个序列嵌套而非并行运行：

@interaction[
(for* ([book '("Guide" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
]

因此，@racket[for*] 是嵌套 @racket[for] 的简写，就像 @racket[let*] 是嵌套 @racket[let] 的简写一样。

@racket[_clause] 的 @racket[#:when _boolean-expr] 形式是另一种简写。它仅在 @racket[_boolean-expr] 产生 true 值时才允许对 @racket[_body] 求值：

@interaction[
(for* ([book '("Guide" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")]
       #:when (not (equal? chapter "Details")))
  (printf "~a ~a\n" book chapter))
]

带有 @racket[#:when] 的 @racket[_boolean-expr] 可以引用前面的任何迭代绑定。在 @racket[for] 形式中，这种作用域只有在测试嵌套在前面绑定的迭代中时才有意义；因此，被 @racket[#:when] 分隔的绑定是相互嵌套的，即使在 @racket[for] 中也不是并行的。

@interaction[
(for ([book '("Guide" "Reference" "Notes")]
      #:when (not (equal? book "Notes"))
      [i (in-naturals 1)]
      [chapter '("Intro" "Details" "Conclusion" "Index")]
      #:when (not (equal? chapter "Index")))
  (printf "~a Chapter ~a. ~a\n" book i chapter))
]

@racket[#:unless] 子句类似于 @racket[#:when] 子句，但 @racket[_body] 仅在 @racket[_boolean-expr] 产生 false 值时才求值。

@section{@racket[for/list] and @racket[for*/list]}

@racket[for/list] 形式与 @racket[for] 语法相同，对 @racket[_body] 求值以获得的值放入新构造的列表中：

@interaction[
(for/list ([i (in-naturals 1)]
           [chapter '("Intro" "Details" "Conclusion")])
  (string-append (number->string i) ". " chapter))
]

@racket[for-list] 形式中的 @racket[#:when] 子句在对 @racket[_body] 求值的同时修剪结果列表：

@interaction[
(for/list ([i (in-naturals 1)]
           [chapter '("Intro" "Details" "Conclusion")]
           #:when (odd? i))
  chapter)
]

@racket[#:when] 的这种修剪行为在 @racket[for/list] 中比在 @racket[for] 中更有用。虽然普通的 @racket[when] 形式在 @racket[for] 中通常就够了，但 @racket[for/list] 中的 @racket[when] 表达式形式会导致结果列表包含 @|void-const| 而非省略列表元素。

@racket[for*/list] 形式类似于 @racket[for*]，将多个迭代嵌套：

@interaction[
(for*/list ([book '("Guide" "Ref.")]
            [chapter '("Intro" "Details")])
  (string-append book " " chapter))
]

@racket[for*/list] 形式与嵌套的 @racket[for/list] 形式不完全相同。嵌套的 @racket[for/list] 会产生列表的列表，而非一个扁平化的列表。因此，与 @racket[#:when] 类似，@racket[for*/list] 的嵌套比 @racket[for*] 的嵌套更有用。

@section{@racket[for/vector] and @racket[for*/vector]}

@racket[for/vector] 形式可以使用与 @racket[for/list] 形式相同的语法，但求值后的 @racket[_body] 进入新构造的 vector 而非列表：

@interaction[
(for/vector ([i (in-naturals 1)]
             [chapter '("Intro" "Details" "Conclusion")])
  (string-append (number->string i) ". " chapter))
]

@racket[for*/vector] 形式的行为类似，但迭代像 @racket[for*] 一样嵌套。

@racket[for/vector] 和 @racket[for*/vector] 形式还允许预先提供要构造的 vector 长度。由此产生的迭代可以比普通的 @racket[for/vector] 或 @racket[for*/vector] 更高效地执行：

@interaction[
(let ([chapters '("Intro" "Details" "Conclusion")])
  (for/vector #:length (length chapters) ([i (in-naturals 1)]
                                          [chapter chapters])
    (string-append (number->string i) ". " chapter)))
]

如果提供了长度，迭代在 vector 填满或请求的迭代完成时停止（以先到者为准）。如果提供的长度超过了请求的迭代次数，则 vector 中的剩余槽位将初始化为 @racket[make-vector] 的默认参数。

@section{@racket[for/and] and @racket[for/or]}

@racket[for/and] 形式使用 @racket[and] 组合迭代结果，遇到 @racket[#f] 时立即停止：

@interaction[
(for/and ([chapter '("Intro" "Details" "Conclusion")])
  (equal? chapter "Intro"))
]

@racket[for/or] 形式使用 @racket[or] 组合迭代结果，遇到 true 值时立即停止：

@interaction[
(for/or ([chapter '("Intro" "Details" "Conclusion")])
  (equal? chapter "Intro"))
]

通常，@racket[for*/and] 和 @racket[for*/or] 形式在嵌套迭代中提供相同的功能。

@section{@racket[for/first] and @racket[for/last]}

@racket[for/first] 形式返回 @racket[_body] 首次求值的结果，跳过后续迭代。此形式与 @racket[#:when] 子句配合使用最为有用。

@interaction[
(for/first ([chapter '("Intro" "Details" "Conclusion" "Index")]
            #:when (not (equal? chapter "Intro")))
  chapter)
]

如果 @racket[_body] 被求值零次，则结果为 @racket[#f]。

@racket[for/last] 形式运行所有迭代，返回最后一次迭代的值（如果没有迭代运行则返回 @racket[#f]）：

@interaction[
(for/last ([chapter '("Intro" "Details" "Conclusion" "Index")]
            #:when (not (equal? chapter "Index")))
  chapter)
]

通常，@racket[for*/first] 和 @racket[for*/last] 形式在嵌套迭代中提供相同的功能：

@interaction[
(for*/first ([book '("Guide" "Reference")]
             [chapter '("Intro" "Details" "Conclusion" "Index")]
             #:when (not (equal? chapter "Intro")))
  (list book chapter))

(for*/last ([book '("Guide" "Reference")]
            [chapter '("Intro" "Details" "Conclusion" "Index")]
            #:when (not (equal? chapter "Index")))
  (list book chapter))
]

@section[#:tag "for/fold"]{@racket[for/fold] and @racket[for*/fold]}

@racket[for/fold] 形式是组合迭代结果的非常通用的方式。它的语法与 @racket[for] 略有不同，因为累积变量必须在开头声明：

@racketblock[
(for/fold ([_accum-id _init-expr] ...)
          (_clause ...)
  _body ...+)
]

在简单情况下，只提供一个 @racket[[_accum-id _init-expr]]，@racket[for/fold] 的结果是 @racket[_accum-id] 的最终值，它以 @racket[_init-expr] 的值开始。在 @racket[_clause] 和 @racket[_body] 中，可以引用 @racket[_accum-id] 来获取其当前值，最后一个 @racket[_body] 为下一次迭代提供 @racket[_accum-id] 的值。

@examples[
(for/fold ([len 0])
          ([chapter '("Intro" "Conclusion")])
  (+ len (string-length chapter)))
(for/fold ([prev #f])
          ([i (in-naturals 1)]
           [chapter '("Intro" "Details" "Details" "Conclusion")]
           #:when (not (equal? chapter prev)))
  (printf "~a. ~a\n" i chapter)
  chapter)
]

当指定多个 @racket[_accum-id] 时，最后一个 @racket[_body] 必须产生多个值，每个 @racket[_accum-id] 一个。@racket[for/fold] 表达式本身产生多个结果值。

@examples[
(for/fold ([prev #f]
           [counter 1])
          ([chapter '("Intro" "Details" "Details" "Conclusion")]
           #:when (not (equal? chapter prev)))
  (printf "~a. ~a\n" counter chapter)
  (values chapter
          (add1 counter)))
]

@section{Multiple-Valued Sequences}

正如函数或表达式可以产生多个值一样，序列的单次迭代也可以产生多个元素。例如，hash table 作为序列每次迭代产生两个值：一个键和一个值。

正如 @racket[let-values] 将多个结果绑定到多个标识符，@racket[for] 可以将多个序列元素绑定到多个迭代标识符：

@margin-note{虽然 @racket[let] 必须更改为 @racket[let-values] 才能绑定多个标识符，但 @racket[for] 只需在任何子句中允许使用括号括起来的标识符列表而非单个标识符。}

@interaction[
(for ([(k v) #hash(("apple" . 1) ("banana" . 3))])
  (printf "~a count: ~a\n" k v))
]

这种对多值绑定的扩展适用于所有 @racket[for] 变体。例如，@racket[for*/list] 嵌套迭代、构建列表，并且也适用于多值序列：

@interaction[
(for*/list ([(k v) #hash(("apple" . 1) ("banana" . 3))]
            [(i) (in-range v)])
  k)
]


@section{Breaking an Iteration}

@racket[for] 的更完整语法为

@specform/subs[
(for (clause ...)
  body-or-break ... body)
([clause [id sequence-expr]
         (code:line #:when boolean-expr)
         (code:line #:unless boolean-expr)
         break]
 [body-or-break body break]
 [break  (code:line #:break boolean-expr)
         (code:line #:final boolean-expr)])
]{}

也就是说，@racket[#:break] 或 @racket[#:final] 子句可以包含在迭代的绑定子句和主体中。在绑定子句中，@racket[#:break] 类似于 @racket[#:unless]，但当其 @racket[_boolean-expr] 为 true 时，@racket[for] 内的所有序列都会停止。在 @racket[_body] 中，@racket[#:break] 在其 @racket[_boolean-expr] 为 true 时对序列有同样的效果，并且它还会阻止当前迭代中后续 @racket[_body] 的求值。

例如，虽然在子句之间使用 @racket[#:unless] 可以有效地跳过后续序列和主体，

@interaction[
(for ([book '("Guide" "Story" "Reference")]
      #:unless (equal? book "Story")
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
]

但使用 @racket[#:break] 会导致整个 @racket[for] 迭代终止：

@interaction[
(for ([book '("Guide" "Story" "Reference")]
      #:break (equal? book "Story")
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
(for* ([book '("Guide" "Story" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")])
  #:break (and (equal? book "Story")
               (equal? chapter "Conclusion"))
  (printf "~a ~a\n" book chapter))
]

@racket[#:final] 子句类似于 @racket[#:break]，但它不会立即终止迭代。相反，它允许每个序列最多再抽取一个元素，并且最多再对 @racket[_body] 进行一次求值。


@interaction[
(for* ([book '("Guide" "Story" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")])
  #:final (and (equal? book "Story")
               (equal? chapter "Conclusion"))
  (printf "~a ~a\n" book chapter))
(for ([book '("Guide" "Story" "Reference")]
      #:final (equal? book "Story")
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
]

@section[#:tag "for-performance"]{Iteration Performance}

理想情况下，@racket[for] 迭代应该与手写的递归函数调用循环一样快。然而，手写循环通常针对特定类型的数据（如列表）。在这种情况下，手写循环直接使用像 @racket[car] 和 @racket[cdr] 这样的选择器，而不是处理所有形式的序列并分派到适当的迭代器。

当关于要迭代的序列有足够明显的信息时，@racket[for] 形式可以提供手写循环的性能，特别是当子句具有以下 @racket[_fast-clause] 形式之一时：

@racketgrammar[
fast-clause [id fast-seq]
            [(id) fast-seq]
            [(id id) fast-indexed-seq]
            [(id ...) fast-parallel-seq]
]

@racketgrammar[
#:literals [in-range in-inclusive-range in-naturals in-list in-mlist in-vector in-string in-bytes in-value stop-before stop-after]
fast-seq literal
         (in-range expr)
         (in-range expr expr)
         (in-range expr expr expr)
         (in-inclusive-range expr expr)
         (in-inclusive-range expr expr expr)
         (in-naturals)
         (in-naturals expr)
         (in-list expr)
         (in-mlist expr)
         (in-vector expr)
         (in-string expr)
         (in-bytes expr)
         (in-value expr)
         (stop-before fast-seq predicate-expr)
         (stop-after fast-seq predicate-expr)
]

@racketgrammar[
#:literals [in-indexed stop-before stop-after]
fast-indexed-seq (in-indexed fast-seq)
                  (stop-before fast-indexed-seq predicate-expr)
                  (stop-after fast-indexed-seq predicate-expr)
]

@racketgrammar[
#:literals [in-parallel stop-before stop-after]
fast-parallel-seq (in-parallel fast-seq ...)
                  (stop-before fast-parallel-seq predicate-expr)
                  (stop-after fast-parallel-seq predicate-expr)
]

@examples[
(define lst '(a b c d e f g h))
(time (for ([i (in-range 100000)])
        (for ([elem (in-list lst)])         (code:comment @#,elem{fast})
          (void))))
(time (for ([i (in-range 100000)])
        (for ([elem '(a b c d e f g h)])    (code:comment @#,elem{also fast})
          (void))))
(time (for ([i (in-range 100000)])
        (for ([elem lst])                   (code:comment @#,elem{slower})
          (void))))
(time (let ([seq (in-list lst)])
        (for ([i (in-range 100000)])
          (for ([elem seq])                 (code:comment @#,elem{also slower})
            (void)))))
]

上述语法并不完整，因为提供良好性能的语法模式集合是可扩展的，就像序列值的集合一样。序列构造器的文档应说明直接在 @racket[for] @racket[_clause] 中使用它的性能优势。

@refdetails["for"]{iterations and comprehensions}
