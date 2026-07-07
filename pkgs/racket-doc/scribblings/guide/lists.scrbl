#lang scribble/doc
@(require scribble/manual scribble/eval scribble/bnf racket/list
          "guide-utils.rkt"
          (for-label racket/list))

@(define step @elem{=})

@(define list-eval (make-base-eval))
@(interaction-eval #:eval list-eval (require racket/list))

@title{Lists, Iteration, and Recursion}

Racket 是 Lisp 语言的方言，其名称最初代表"LISt Processor"（列表处理器）。内置的列表数据类型仍然是该语言的显著特性。

@racket[list] 函数接受任意数量的值并返回包含这些值的列表：

@interaction[(list "red" "green" "blue")
             (list 1 2 3 4 5)]

@margin-note{列表通常以 @litchar{'} 打印，但列表的打印形式取决于其内容。更多信息参见 @secref["pairs"]。}

如你所见，列表结果在 @tech{REPL} 中以引号 @litchar{'} 和括号包围列表元素的打印形式来显示。这里可能会造成混淆，因为括号既用于表达式，如 @racket[(list "red" "green" "blue")]，也用于打印结果，如 @racketresult['("red" "green" "blue")]。除了引号之外，结果的括号在文档和 DrRacket 中以蓝色打印，而表达式的括号是棕色的。

许多预定义函数操作列表。以下是一些示例：

@interaction[
(code:line (length (list "hop" "skip" "jump"))        (code:comment @#,t{count the elements}))
(code:line (list-ref (list "hop" "skip" "jump") 0)    (code:comment @#,t{extract by position}))
(list-ref (list "hop" "skip" "jump") 1)
(code:line (append (list "hop" "skip") (list "jump")) (code:comment @#,t{combine lists}))
(code:line (reverse (list "hop" "skip" "jump"))       (code:comment @#,t{reverse order}))
(code:line (member "fall" (list "hop" "skip" "jump")) (code:comment @#,t{check for an element}))
]

@;------------------------------------------------------------------------
@section{Predefined List Loops}

除了像 @racket[append] 这样的简单操作，Racket 还包含对列表元素进行迭代的函数。这些迭代函数在 Racket 中扮演着类似于 Java 和其他语言中 @racket[for] 的角色。Racket 迭代的主体被封装为一个应用于每个元素的函数，因此 @racket[lambda] 形式在与迭代函数结合时特别方便。

不同的列表迭代函数以不同的方式组合迭代结果。@racket[map] 函数使用每个元素的结果创建新列表：

@interaction[
(map sqrt (list 1 4 9 16))
(map (lambda (i)
       (string-append i "!"))
     (list "peanuts" "popcorn" "crackerjack"))
]

@racket[andmap] 和 @racket[ormap] 函数通过 @racket[and] 或 @racket[or] 来组合结果：

@interaction[
(andmap string? (list "a" "b" "c"))
(andmap string? (list "a" "b" 6))
(ormap number? (list "a" "b" 6))
]

@racket[map]、@racket[andmap] 和 @racket[ormap] 函数都可以处理多个列表，而不仅仅是单个列表。所有列表必须具有相同的长度，并且给定的函数必须为每个列表接受一个参数：

@interaction[
(map (lambda (s n) (substring s 0 n))
     (list "peanuts" "popcorn" "crackerjack")
     (list 6 3 7))
]

@racket[filter] 函数保留主体结果为真的元素，丢弃结果为 @racket[#f] 的元素：

@interaction[
(filter string? (list "a" "b" 6))
(filter positive? (list 1 -2 6 7 0))
]

@racket[foldl] 函数泛化了一些迭代函数。它使用逐元素函数同时处理元素并将其与"当前"值组合，因此逐元素函数需要一个额外的第一个参数。此外，必须在列表之前提供一个起始的"当前"值：

@interaction[
(foldl (lambda (elem v)
         (+ v (* elem elem)))
       0
       '(1 2 3))
]

尽管 @racket[foldl] 很通用，但它不像其他函数那样流行。一个原因是 @racket[map]、@racket[ormap]、@racket[andmap] 和 @racket[filter] 涵盖了最常见的列表循环类型。

Racket 提供了一个通用的@defterm{列表推导}形式 @racket[for/list]，它通过遍历@defterm{序列}来构建列表。列表推导和相关迭代形式在 @secref["for"] 中描述。

@;------------------------------------------------------------------------
@section{List Iteration from Scratch}

虽然 @racket[map] 和其他迭代函数是预定义的，但在任何有意义的意义上它们都不是原始的。你可以使用少量列表原语来编写等价的迭代。

由于 Racket 列表是链表，对非空列表的两个核心操作是

@itemize[
 @item{@racket[first]：获取列表中的第一个元素；}
 @item{@racket[rest]：获取列表的其余部分。}
]

@examples[
#:eval list-eval
(first (list 1 2 3))
(rest (list 1 2 3))
]

要为链表创建新节点——即添加到列表的前面——请使用 @racket[cons] 函数，它是"construct"的缩写。要获得一个空列表作为开始，请使用 @racket[empty] 常量：

@interaction[
#:eval list-eval
empty
(cons "head" empty)
(cons "dead" (cons "head" empty))
]

要处理列表，你需要能够区分空列表和非空列表，因为 @racket[first] 和 @racket[rest] 仅对非空列表有效。@racket[empty?] 函数检测空列表，@racket[cons?] 检测非空列表：

@interaction[
#:eval list-eval
(empty? empty)
(empty? (cons "head" empty))
(cons? empty)
(cons? (cons "head" empty))
]

有了这些构件，你可以编写自己的 @racket[length] 函数、@racket[map] 函数等的版本。

@defexamples[
#:eval list-eval
(define (my-length lst)
  (cond
    [(empty? lst) 0]
    [else (+ 1 (my-length (rest lst)))]))
(my-length empty)
(my-length (list "a" "b" "c"))
]
@def+int[
#:eval list-eval
(define (my-map f lst)
  (cond
    [(empty? lst) empty]
    [else (cons (f (first lst))
                (my-map f (rest lst)))]))
(my-map string-upcase (list "ready" "set" "go"))
]

如果上述定义的推导对你来说很神秘，请考虑阅读 @|HtDP|。如果你只是对使用递归调用而不是循环构造感到疑惑，请继续阅读。

@;------------------------------------------------------------------------
@section[#:tag "tail-recursion"]{Tail Recursion}

@racket[my-length] 和 @racket[my-map] 函数对于长度为 @math{n} 的列表都使用 @math{O(n)} 空间。这很容易通过想象 @racket[(my-length (list "a" "b" "c"))] 如何求值来看出：

@racketblock[
#||# (my-length (list "a" "b" "c"))
#,step (+ 1 (my-length (list "b" "c")))
#,step (+ 1 (+ 1 (my-length (list "c"))))
#,step (+ 1 (+ 1 (+ 1 (my-length (list)))))
#,step (+ 1 (+ 1 (+ 1 0)))
#,step (+ 1 (+ 1 1))
#,step (+ 1 2)
#,step 3
]

对于有 @math{n} 个元素的列表，求值将堆积 @math{n} 个 @racket[(+ 1 ...)] 加法，然后在列表耗尽时最终将它们加起来。

你可以通过在过程中逐步累加来避免堆积加法。要以这种方式累积长度，我们需要一个同时接受列表和目前所见列表长度的函数；下面的代码使用一个局部函数 @racket[iter] 在参数 @racket[len] 中累积长度：

@racketblock[
(define (my-length lst)
  (code:comment @#,t{local function @racket[iter]:})
  (define (iter lst len)
    (cond
      [(empty? lst) len]
      [else (iter (rest lst) (+ len 1))]))
  (code:comment @#,t{body of @racket[my-length] calls @racket[iter]:})
  (iter lst 0))
]

现在求值看起来像这样：

@racketblock[
#||# (my-length (list "a" "b" "c"))
#,step (iter (list "a" "b" "c") 0)
#,step (iter (list "b" "c") 1)
#,step (iter (list "c") 2)
#,step (iter (list) 3)
3
]

修改后的 @racket[my-length] 在常量空间中运行，正如上面的求值步骤所表明的那样。也就是说，当一个函数调用的结果，如 @racket[(iter (list "b" "c") 1)]，恰好是另一个函数调用的结果时，如 @racket[(iter (list "c") 2)]，则第一个不需要等待第二个，因为那会毫无理由地占用空间。

这种求值行为有时被称为@idefterm{尾调用优化}，但在 Racket 中它不仅仅是一种"优化"；它是关于代码运行方式的保证。更准确地说，相对于另一个表达式处于@deftech{尾部位置}的表达式不会比另一个表达式占用额外的计算空间。

在 @racket[my-map] 的情况下，@math{O(n)} 空间复杂度是合理的，因为它必须生成大小为 @math{O(n)} 的结果。尽管如此，你可以通过累积结果列表来降低常数因子。唯一的问题是累积的列表会是反向的，所以你必须在最后反转它：

@margin-note{像这样尝试降低常数因子通常不值得，如下所述。}

@racketblock[
(define (my-map f lst)
  (define (iter lst backward-result)
    (cond
      [(empty? lst) (reverse backward-result)]
      [else (iter (rest lst)
                  (cons (f (first lst))
                        backward-result))]))
  (iter lst empty))
]

事实证明，如果你写

@racketblock[
(define (my-map f lst)
  (for/list ([i lst])
    (f i)))
]

那么函数中的 @racket[for/list] 形式会扩展为与 @racket[iter] 局部定义和使用基本相同的代码。区别仅仅是语法上的便利。

@;------------------------------------------------------------------------
@section{Recursion versus Iteration}

@racket[my-length] 和 @racket[my-map] 示例表明迭代只是递归的一种特殊情况。在许多语言中，尽可能将计算放入迭代形式是很重要的。否则，性能会很差，中等大小的输入可能导致栈溢出。类似地，在 Racket 中，有时确保使用尾递归以避免在计算可以轻松在常量空间中执行时消耗 @math{O(n)} 空间是很重要的。

同时，递归在 Racket 中不会导致特别糟糕的性能，也不存在栈溢出的问题；如果计算涉及太多上下文，你可以会耗尽内存，但耗尽内存通常需要比其他语言中触发栈溢出深几个数量级的递归。这些考虑，加上尾递归程序自动像循环一样运行的事实，使得 Racket 程序员拥抱递归形式而不是回避它们。

假设，例如，你想从列表中删除连续的重复元素。虽然这样的函数可以写成一个循环，为每次迭代记住前一个元素，但 Racket 程序员更可能直接写以下内容：

@def+int[
#:eval list-eval
(define (remove-dups l)
  (cond
    [(empty? l) empty]
    [(empty? (rest l)) l]
    [else
     (let ([i (first l)])
       (if (equal? i (first (rest l)))
           (remove-dups (rest l))
           (cons i (remove-dups (rest l)))))]))
(remove-dups (list "a" "b" "b" "b" "c" "c"))
]

一般来说，此函数对长度为 @math{n} 的输入列表消耗 @math{O(n)} 空间，但这没关系，因为它产生 @math{O(n)} 的结果。如果输入列表恰好大部分是连续重复的，那么结果列表可能远小于 @math{O(n)}——并且 @racket[remove-dups] 也会使用远小于 @math{O(n)} 的空间！原因是当函数丢弃重复项时，它直接返回 @racket[remove-dups] 调用的结果，因此尾调用"优化"就会生效：

@racketblock[
#||# (remove-dups (list "a" "b" "b" "b" "b" "b"))
#,step (cons "a" (remove-dups (list "b" "b" "b" "b" "b")))
#,step (cons "a" (remove-dups (list "b" "b" "b" "b")))
#,step (cons "a" (remove-dups (list "b" "b" "b")))
#,step (cons "a" (remove-dups (list "b" "b")))
#,step (cons "a" (remove-dups (list "b")))
#,step (cons "a" (list "b"))
#,step (list "a" "b")
]

@; ----------------------------------------------------------------------

@close-eval[list-eval]
