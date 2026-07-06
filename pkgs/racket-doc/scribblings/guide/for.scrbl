#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "for"]{迭代与推导式}

@racket[for] 系列 syntactic form 支持对 @defterm{sequence} 的迭代。
List、vector、string、byte string、input port 和 hash table 都可用作 sequence，
而 @racket[in-range] 等构造器提供了更多种类的 sequence。

@racket[for] 的变体以不同方式累积迭代结果，但具有相同的语法形状。
为简化起见，@racket[for] 的语法是

@specform[
(for ([id sequence-expr] ...)
  body ...+)
]{}

@racket[for] 循环遍历 @racket[_sequence-expr] 产生的 sequence。
对于 sequence 的每个元素，@racket[for] 将元素绑定到 @racket[_id]，
然后求值 @racket[_body] 以产生副作用。

@examples[
(for ([i '(1 2 3)])
  (display i))
(for ([i "abc"])
  (printf "~a..." i))
(for ([i 4])
  (display i))
]

@racket[for] 的 @racket[for/list] 变体更具 Racket 风格。
它将 @racket[_body] 结果累积到 list 中，而不是仅对 @racket[_body]
求值以产生副作用。更技术化地说，@racket[for/list] 实现了 @defterm{list
comprehension}。

@examples[
(for/list ([i '(1 2 3)])
  (* i i))
(for/list ([i "abc"])
  i)
(for/list ([i 4])
  i)
]

@racket[for] 的完整语法支持多个 sequence 的并行迭代，
而 @racket[for*] 变体嵌套迭代而不是并行运行它们。
@racket[for] 和 @racket[for*] 的更多变体以不同方式累积 @racket[_body] 结果。
在所有这些变体中，可用于剪枝迭代的谓词可以与绑定一起包含。

不过，在介绍 @racket[for] 变体的细节之前，最好先了解
能使示例更有趣的各类 sequence 生成器。

@section[#:tag "sequences"]{Sequence 构造器}

@racket[in-range] 函数生成一个数字 sequence，给定可选的起始数字
(默认为 @racket[0])、sequence 结束前的数字，以及可选的步长
(默认为 @racket[1])。直接将非负整数 @racket[_k] 用作 sequence
是 @racket[(in-range _k)] 的简写。

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

@racket[in-naturals] 函数类似，但起始数字必须是非负整数
(默认为 @racket[0])，步长始终为 @racket[1]，且没有上限。
仅使用 @racket[in-naturals] 的 @racket[for] 循环永远不会终止，
除非 body 表达式引发异常或以其他方式逃逸。

@examples[
(for ([i (in-naturals)])
  (if (= i 10)
      (error "too much!")
      (display i)))
]

@racket[stop-before] 和 @racket[stop-after] 函数根据给定 sequence
和谓词构造新 sequence。新 sequence 类似于给定 sequence，但在谓词返回真值的
第一个元素之前或之后立即截断。

@examples[
(for ([i (stop-before "abc def"
                      char-whitespace?)])
  (display i))
]

@racket[in-list]、@racket[in-vector] 和 @racket[in-string]
等 sequence 构造器只是显式地将 list、vector 或 string 用作 sequence。
与 @racket[in-range] 一样，这些构造器在给定错误类型的值时会引发异常，
并且由于它们避免了运行时派发来确定 sequence 类型，因此能生成更高效的代码；
更多信息参见 @secref["for-performance"]。

@examples[
(for ([i (in-string "abc")])
  (display i))
(for ([i (in-string '(1 2 3))])
  (display i))
]

@refdetails["sequences"]{sequences}

@section{@racket[for] 和 @racket[for*]}

@racket[for] 更完整的语法是

@specform/subs[
(for (clause ...)
  body ...+)
([clause [id sequence-expr]
         (code:line #:when boolean-expr)
         (code:line #:unless boolean-expr)])
]{}

当在 @racket[for] 形式中提供多个 @racket[[_id _sequence-expr]] 子句时，
对应的 sequence 会被并行遍历：

@interaction[
(for ([i (in-range 1 4)]
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "Chapter ~a. ~a\n" i chapter))
]

对于 parallel sequence，@racket[for] 表达式在任一 sequence 结束时
停止迭代。此行为允许 @racket[in-naturals](创建无限的数字 sequence)
用于索引：

@interaction[
(for ([i (in-naturals 1)]
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "Chapter ~a. ~a\n" i chapter))
]

@racket[for*] 形式与 @racket[for] 语法相同，但嵌套多个 sequence
而不是并行运行它们：

@interaction[
(for* ([book '("Guide" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
]

因此，@racket[for*] 是嵌套 @racket[for] 的简写，
正如 @racket[let*] 是嵌套 @racket[let] 的简写。

@racket[_clause] 的 @racket[#:when _boolean-expr] 形式是另一种简写。
它允许 @racket[_body] 仅在 @racket[_boolean-expr] 产生真值时求值：

@interaction[
(for* ([book '("Guide" "Reference")]
       [chapter '("Intro" "Details" "Conclusion")]
       #:when (not (equal? chapter "Details")))
  (printf "~a ~a\n" book chapter))
]

@racket[#:when] 中的 @racket[_boolean-expr] 可以引用任何先前的迭代绑定。
在 @racket[for] 形式中，此作用域仅在测试嵌套在先前绑定的迭代中时才有意义；
因此，被 @racket[#:when] 分隔的绑定是相互嵌套的，而不是并行的，
即使在 @racket[for] 中也是如此。

@interaction[
(for ([book '("Guide" "Reference" "Notes")]
      #:when (not (equal? book "Notes"))
      [i (in-naturals 1)]
      [chapter '("Intro" "Details" "Conclusion" "Index")]
      #:when (not (equal? chapter "Index")))
  (printf "~a Chapter ~a. ~a\n" book i chapter))
]

@racket[#:unless] 子句类似于 @racket[#:when] 子句，
但 @racket[_body] 仅在 @racket[_boolean-expr] 产生假值时求值。

@section{@racket[for/list] 和 @racket[for*/list]}

@racket[for/list] 形式与 @racket[for] 语法相同，
求值 @racket[_body] 以获取放入新构造 list 中的值：

@interaction[
(for/list ([i (in-naturals 1)]
           [chapter '("Intro" "Details" "Conclusion")])
  (string-append (number->string i) ". " chapter))
]

@racket[for-list] 形式中的 @racket[#:when] 子句在求值 @racket[_body]
的同时对结果 list 进行剪枝：

@interaction[
(for/list ([i (in-naturals 1)]
           [chapter '("Intro" "Details" "Conclusion")]
           #:when (odd? i))
  chapter)
]

@racket[#:when] 的剪枝行为在 @racket[for/list] 中比在 @racket[for]
中更有用。在 @racket[for] 中，普通的 @racket[when] 形式通常已足够，
而在 @racket[for/list] 中，@racket[when] 表达式形式会导致结果 list
包含 @|void-const| 而不是省略 list 元素。

@racket[for*/list] 形式类似于 @racket[for*]，嵌套多次迭代：

@interaction[
(for*/list ([book '("Guide" "Ref.")]
            [chapter '("Intro" "Details")])
  (string-append book " " chapter))
]

@racket[for*/list] 形式与嵌套 @racket[for/list] 形式不完全相同。
嵌套 @racket[for/list] 会产生 list 的 list，而不是一个扁平的 list。
因此，与 @racket[#:when] 一样，@racket[for*/list] 的嵌套比 @racket[for*]
的嵌套更有用。

@section{@racket[for/vector] 和 @racket[for*/vector]}

@racket[for/vector] 形式可与 @racket[for/list] 形式相同的语法使用，
但求值后的 @racket[_body] 进入新构造的 vector 而不是 list：

@interaction[
(for/vector ([i (in-naturals 1)]
             [chapter '("Intro" "Details" "Conclusion")])
  (string-append (number->string i) ". " chapter))
]

@racket[for*/vector] 形式行为类似，但迭代如 @racket[for*] 中那样嵌套。

@racket[for/vector] 和 @racket[for*/vector] 形式还允许预先提供
要构造的 vector 的长度。结果迭代可以比普通的 @racket[for/vector]
或 @racket[for*/vector] 更高效地执行：

@interaction[
(let ([chapters '("Intro" "Details" "Conclusion")])
  (for/vector #:length (length chapters) ([i (in-naturals 1)]
                                          [chapter chapters])
    (string-append (number->string i) ". " chapter)))
]

如果提供了长度，迭代在 vector 已满或请求的迭代完成时停止，
以先发生者为准。如果提供的长度超过请求的迭代次数，
则 vector 中剩余的槽位被初始化为 @racket[make-vector] 的默认参数。

@section{@racket[for/and] 和 @racket[for/or]}

@racket[for/and] 形式通过 @racket[and] 组合迭代结果，
在遇到 @racket[#f] 时立即停止：

@interaction[
(for/and ([chapter '("Intro" "Details" "Conclusion")])
  (equal? chapter "Intro"))
]

@racket[for/or] 形式通过 @racket[or] 组合迭代结果，
在遇到真值时立即停止：

@interaction[
(for/or ([chapter '("Intro" "Details" "Conclusion")])
  (equal? chapter "Intro"))
]

与往常一样，@racket[for*/and] 和 @racket[for*/or] 形式以嵌套迭代
提供相同的功能。

@section{@racket[for/first] 和 @racket[for/last]}

@racket[for/first] 形式返回 @racket[_body] 第一次求值的结果，
跳过后续迭代。此形式在配合 @racket[#:when] 子句时最为有用。

@interaction[
(for/first ([chapter '("Intro" "Details" "Conclusion" "Index")]
            #:when (not (equal? chapter "Intro")))
  chapter)
]

如果 @racket[_body] 被求值零次，则结果为 @racket[#f]。

@racket[for/last] 形式运行所有迭代，返回最后一次迭代的值
(如果没有运行迭代，则返回 @racket[#f])：

@interaction[
(for/last ([chapter '("Intro" "Details" "Conclusion" "Index")]
            #:when (not (equal? chapter "Index")))
  chapter)
]

与往常一样，@racket[for*/first] 和 @racket[for*/last] 形式以嵌套迭代
提供相同的功能：

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

@section[#:tag "for/fold"]{@racket[for/fold] 和 @racket[for*/fold]}

@racket[for/fold] 形式是组合迭代结果的非常通用的方式。
其语法与 @racket[for] 略有不同，因为累积变量必须在开头声明：

@racketblock[
(for/fold ([_accum-id _init-expr] ...)
          (_clause ...)
  _body ...+)
]

在简单情况下，只提供一个 @racket[[_accum-id _init-expr]]，
@racket[for/fold] 的结果是 @racket[_accum-id] 的最终值，
它从 @racket[_init-expr] 的值开始。在 @racket[_clause] 和 @racket[_body]
中，可以引用 @racket[_accum-id] 以获取其当前值，
最后一个 @racket[_body] 提供 @racket[_accum-id] 在下一次迭代中的值。

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

当指定多个 @racket[_accum-id] 时，最后一个 @racket[_body]
必须为每个 @racket[_accum-id] 产生多个值。
@racket[for/fold] 表达式本身为结果产生多个值。

@examples[
(for/fold ([prev #f]
           [counter 1])
          ([chapter '("Intro" "Details" "Details" "Conclusion")]
           #:when (not (equal? chapter prev)))
  (printf "~a. ~a\n" counter chapter)
  (values chapter
          (add1 counter)))
]

@section{多值 Sequence}

与 function 或表达式可以产生多个值的方式相同，
sequence 的单独迭代可以产生多个元素。例如，
hash table 作为 sequence 每次迭代产生两个值：一个 key 和一个 value。

与 @racket[let-values] 将多个结果绑定到多个标识符的方式相同，
@racket[for] 可以将多个 sequence 元素绑定到多个迭代标识符：

@margin-note{虽然 @racket[let] 必须改为 @racket[let-values]
             才能绑定多个标识符，但 @racket[for] 只需在任何子句中
             使用标识符的括号列表即可代替单个标识符。}

@interaction[
(for ([(k v) #hash(("apple" . 1) ("banana" . 3))])
  (printf "~a count: ~a\n" k v))
]

此多值绑定扩展适用于所有 @racket[for] 变体。
例如，@racket[for*/list] 嵌套迭代、构建 list，
并且也适用于多值 sequence：

@interaction[
(for*/list ([(k v) #hash(("apple" . 1) ("banana" . 3))]
            [(i) (in-range v)])
  k)
]


@section{中断迭代}

@racket[for] 更完整的语法是

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

也就是说，@racket[#:break] 或 @racket[#:final] 子句可以包含在迭代的
绑定子句和 body 之中。在绑定子句中，@racket[#:break] 类似于 @racket[#:unless]，
但当其 @racket[_boolean-expr] 为真时，@racket[for] 中的所有 sequence 都会停止。
在 @racket[_body] 中，@racket[#:break] 在其 @racket[_boolean-expr] 为真时
对 sequence 有相同的效果，并且它还阻止当前迭代中后续 @racket[_body] 的求值。

例如，虽然在子句之间使用 @racket[#:unless] 有效地跳过了后续 sequence
以及 body，

@interaction[
(for ([book '("Guide" "Story" "Reference")]
      #:unless (equal? book "Story")
      [chapter '("Intro" "Details" "Conclusion")])
  (printf "~a ~a\n" book chapter))
]

使用 @racket[#:break] 会导致整个 @racket[for] 迭代终止：

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

@racket[#:final] 子句类似于 @racket[#:break]，
但它不会立即终止迭代。相反，它允许每个 sequence 最多再抽取一个元素，
@racket[_body] 最多再求值一次。


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

@section[#:tag "for-performance"]{迭代性能}

理想情况下，@racket[for] 迭代应该与你手写为 recursive function 调用的
循环一样快。然而，手写循环通常针对特定类型的数据，如 list。
在这种情况下，手写循环直接使用 @racket[car] 和 @racket[cdr]
等选择器，而不是处理所有形式的 sequence 并派发给适当的迭代器。

当关于要迭代的 sequence 有足够明显的信息时，
@racket[for] 形式可以提供手写循环的性能，
特别是当子句具有以下 @racket[_fast-clause] 形式之一时：

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

上述语法并不完整，因为提供良好性能的 syntactic pattern 集合是可扩展的，
正如 sequence 值的集合一样。Sequence 构造器的文档应指出
在 @racket[for] @racket[_clause] 中直接使用它的性能优势。

@refdetails["for"]{iterations and comprehensions}
