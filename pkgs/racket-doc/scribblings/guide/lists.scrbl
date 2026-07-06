#lang scribble/doc
@(require scribble/manual scribble/eval scribble/bnf racket/list
          "guide-utils.rkt"
          (for-label racket/list))

@(define step @elem{=})

@(define list-eval (make-base-eval))
@(interaction-eval #:eval list-eval (require racket/list))

@title{列表、迭代与递归}

Racket 是 Lisp 语言的一种方言，Lisp 最初代表"LISt Processor"。内建的 list 数据类型仍然是该语言的突出特性。

@racket[list] 函数接受任意数量的值并返回一个包含这些值的列表：

@interaction[(list "red" "green" "blue")
             (list 1 2 3 4 5)]

如你所见，list 结果在 @tech{REPL} 中以 quote @litchar{'} 加上一对括号包裹元素打印形式的方式显示。这里有一个容易混淆的地方，因为 parentheses 既用于表达式，如 @racket[(list "red" "green" "blue")]，也用于打印结果，如 @racketresult['("red" "green" "blue")]。除了 quote 之外，结果中的 parentheses 在文档和 DrRacket 中显示为蓝色，而表达式中的 parentheses 为棕色。

许多预定义的函数操作于 lists。以下是一些示例：

@interaction[
(code:line (length (list "hop" "skip" "jump"))        (code:comment @#,t{count the elements}))
(code:line (list-ref (list "hop" "skip" "jump") 0)    (code:comment @#,t{extract by position}))
(list-ref (list "hop" "skip" "jump") 1)
(code:line (append (list "hop" "skip") (list "jump")) (code:comment @#,t{combine lists}))
(code:line (reverse (list "hop" "skip" "jump"))       (code:comment @#,t{reverse order}))
(code:line (member "fall" (list "hop" "skip" "jump")) (code:comment @#,t{check for an element}))
]

@;------------------------------------------------------------------------
@section{预定义 List 循环}

除了 @racket[append] 等简单操作外，Racket 还包括遍历 list 元素的函数。这些迭代函数起着与 Java、Racket 及其他语言中 @racket[for] 相似的作用。Racket 迭代的 body 被打包成一个应用于每个元素的函数，因此 @racket[lambda] 形式与迭代函数结合使用时尤为方便。

不同 list 迭代函数以不同方式组合迭代结果。@racket[map] 函数使用各元素结果创建一个新列表：

@interaction[
(map sqrt (list 1 4 9 16))
(map (lambda (i)
       (string-append i "!"))
     (list "peanuts" "popcorn" "crackerjack"))
]

@racket[andmap] 和 @racket[ormap] 函数通过 @racket[and] 或 @racket[or] 组合结果：

@interaction[
(andmap string? (list "a" "b" "c"))
(andmap string? (list "a" "b" 6))
(ormap number? (list "a" "b" 6))
]

@racket[map]、@racket[andmap] 和 @racket[ormap] 函数都能处理多个 list，而不仅限于单个 list。所有 list 必须长度相同，且给定的函数必须为每个 list 接受一个参数：

@interaction[
(map (lambda (s n) (substring s 0 n))
     (list "peanuts" "popcorn" "crackerjack")
     (list 6 3 7))
]

@racket[filter] 函数保留 body 结果为 true 的元素，丢弃 @racket[#f]：

@interaction[
(filter string? (list "a" "b" 6))
(filter positive? (list 1 -2 6 7 0))
]

@racket[foldl] 函数泛化了一些迭代函数。它既处理单个元素又将其与"当前"值组合，因此 per-element 函数多接受第一个参数。此外，必须在 lists 之前提供起始的"当前"值：

@interaction[
(foldl (lambda (elem v)
         (+ v (* elem elem)))
       0
       '(1 2 3))
]

尽管具有通用性，@racket[foldl] 不如其他函数流行。一个原因是 @racket[map]、@racket[ormap]、@racket[andmap] 和 @racket[filter] 已涵盖大多数常见的 list 循环。

Racket 提供了一个通用的 @defterm{list comprehension} 形式
@racket[for/list]，它通过遍历 @defterm{sequences} 构建列表。
List comprehensions 和相关迭代形式在 @secref["for"] 中描述。

@;------------------------------------------------------------------------
@section{从零开始的 List 迭代}

尽管 @racket[map] 和其他迭代函数是预定义的，它们在任何有趣意义上都不是原语。你可以使用少量 list 原语编写等价的迭代。

由于 Racket list 是 linked list，对非空 list 的两个核心操作是

@itemize[
 @item{@racket[first]: get the first thing in the list; and}
 @item{@racket[rest]: get the rest of the list.}
]

@examples[
#:eval list-eval
(first (list 1 2 3))
(rest (list 1 2 3))
]

To create a new node for a linked list---that is, to add to the front
of the list---use the @racket[cons] function, which is short for
``construct.'' To get an empty list to start with, use the
@racket[empty] constant:

@interaction[
#:eval list-eval
empty
(cons "head" empty)
(cons "dead" (cons "head" empty))
]

To process a list, you need to be able to distinguish empty lists from
non-empty lists, because @racket[first] and @racket[rest] work only on
non-empty lists. The @racket[empty?] function detects empty lists,
and @racket[cons?] detects non-empty lists:

@interaction[
#:eval list-eval
(empty? empty)
(empty? (cons "head" empty))
(cons? empty)
(cons? (cons "head" empty))
]

With these pieces, you can write your own versions of the
@racket[length] function, @racket[map] function, and more.

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

If the derivation of the above definitions is mysterious to you,
consider reading @|HtDP|. If you are merely suspicious of the use
of recursive calls instead of a looping construct, then read on.

@;------------------------------------------------------------------------
@section[#:tag "tail-recursion"]{Tail Recursion}

Both the @racket[my-length] and @racket[my-map] functions run in
@math{O(n)} space for a list of length @math{n}. This is easy to see by
imagining how @racket[(my-length (list "a" "b" "c"))] must evaluate:

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

For a list with @math{n} elements, evaluation will stack up @math{n}
@racket[(+ 1 ...)] additions, and then finally add them up when the
list is exhausted.

You can avoid piling up additions by adding along the way. To
accumulate a length this way, we need a function that takes both a
list and the length of the list seen so far; the code below uses a
local function @racket[iter] that accumulates the length in an
argument @racket[len]:

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

Now evaluation looks like this:

@racketblock[
#||# (my-length (list "a" "b" "c"))
#,step (iter (list "a" "b" "c") 0)
#,step (iter (list "b" "c") 1)
#,step (iter (list "c") 2)
#,step (iter (list) 3)
3
]

The revised @racket[my-length] runs in constant space, just as the
evaluation steps above suggest. That is, when the result of a
function call, like @racket[(iter (list "b" "c") 1)], is exactly the
result of some other function call, like @racket[(iter (list "c")
2)], then the first one doesn't have to wait around for the second
one, because that takes up space for no good reason.

This evaluation behavior is sometimes called @idefterm{tail-call
optimization}, but it's not merely an ``optimization'' in Racket; it's
a guarantee about the way the code will run. More precisely, an
expression in @deftech{tail position} with respect to another
expression does not take extra computation space over the other
expression.

In the case of @racket[my-map], @math{O(n)} space complexity is
reasonable, since it has to generate a result of size
@math{O(n)}. Nevertheless, you can reduce the constant factor by
accumulating the result list. The only catch is that the accumulated
list will be backwards, so you'll have to reverse it at the very end:

@margin-note{Attempting to reduce a constant factor like this is
usually not worthwhile, as discussed below.}

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

It turns out that if you write

@racketblock[
(define (my-map f lst)
  (for/list ([i lst])
    (f i)))
]

then the @racket[for/list] form in the function is expanded to
essentially the same code as the @racket[iter] local definition and
use. The difference is merely syntactic convenience.

@;------------------------------------------------------------------------
@section{Recursion versus Iteration}

The @racket[my-length] and @racket[my-map] examples demonstrate that
iteration is just a special case of recursion. In many languages, it's
important to try to fit as many computations as possible into
iteration form. Otherwise, performance will be bad, and moderately
large inputs can lead to stack overflow.  Similarly, in Racket, it is
sometimes important to make sure that tail recursion is used to avoid
@math{O(n)} space consumption when the computation is easily performed
in constant space.

At the same time, recursion does not lead to particularly bad
performance in Racket, and there is no such thing as stack overflow;
you can run out of memory if a computation involves too much context,
but exhausting memory typically requires orders of magnitude deeper
recursion than would trigger a stack overflow in other
languages. These considerations, combined with the fact that
tail-recursive programs automatically run the same as a loop, lead
Racket programmers to embrace recursive forms rather than avoid them.

Suppose, for example, that you want to remove consecutive duplicates
from a list. While such a function can be written as a loop that
remembers the previous element for each iteration, a Racket programmer
would more likely just write the following:

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

In general, this function consumes @math{O(n)} space for an input
list of length @math{n}, but that's fine, since it produces an
@math{O(n)} result. If the input list happens to be mostly consecutive
duplicates, then the resulting list can be much smaller than
@math{O(n)}---and @racket[remove-dups] will also use much less than
@math{O(n)} space! The reason is that when the function discards
duplicates, it returns the result of a @racket[remove-dups] call
directly, so the tail-call ``optimization'' kicks in:

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
