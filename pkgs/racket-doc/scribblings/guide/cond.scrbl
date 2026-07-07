#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "conditionals"]{Conditionals}

大多数用于分支的函数，如 @racket[<] 和 @racket[string?]，产生 @racket[#t] 或 @racket[#f]。然而，Racket 的分支形式将 @racket[#f] 以外的任何值都视为真。我们说一个@defterm{真值}是指 @racket[#f] 以外的任何值。

这种关于"真值"的约定与 @racket[#f] 可以表示失败或指示可选值未提供的协议很好地配合。（注意不要过度使用这个技巧，并且记住异常通常是报告失败的更好机制。）

例如，@racket[member] 函数具有双重功能：它可以用来查找以特定项开头的列表的尾部，也可以简单地用来检查某个项是否存在于列表中：

@interaction[
(member "Groucho" '("Harpo" "Zeppo"))
(member "Groucho" '("Harpo" "Groucho" "Zeppo"))
(if (member "Groucho" '("Harpo" "Zeppo"))
    'yep
    'nope)
(if (member "Groucho" '("Harpo" "Groucho" "Zeppo"))
    'yep
    'nope)
]

@;------------------------------------------------------------------------
@section{Simple Branching: @racket[if]}

@refalso["if"]{@racket[if]}

在 @racket[if] 形式中，

@specform[(if test-expr then-expr else-expr)]

@racket[_test-expr] 总是被求值。如果它产生 @racket[#f] 以外的任何值，则对 @racket[_then-expr] 进行求值。否则，对 @racket[_else-expr] 进行求值。

@racket[if] 形式必须同时有 @racket[_then-expr] 和 @racket[_else-expr]；后者不是可选的。要根据 @racket[_test-expr] 执行（或跳过）副作用，请使用 @racket[when] 或 @racket[unless]，我们将在 @secref["begin"] 中描述它们。

@;------------------------------------------------------------------------
@section[#:tag "and+or"]{Combining Tests: @racket[and] and @racket[or]}

@refalso["if"]{@racket[and] and @racket[or]}

Racket 的 @racket[and] 和 @racket[or] 是语法形式，而不是函数。与函数不同，@racket[and] 和 @racket[or] 形式可以在前面的表达式确定答案时跳过后续表达式的求值。

@specform[(and expr ...)]

如果任何 @racket[_expr] 产生 @racket[#f]，则 @racket[and] 形式产生 @racket[#f]。否则，它产生最后一个 @racket[_expr] 的值。作为特例，@racket[(and)] 产生 @racket[#t]。

@specform[(or expr ...)]

如果所有 @racket[_expr] 都产生 @racket[#f]，则 @racket[or] 形式产生 @racket[#f]。否则，它产生其 @racket[expr] 中第一个非 @racket[#f] 的值。作为特例，@racket[(or)] 产生 @racket[#f]。

@examples[
(code:line
 (define (got-milk? lst)
   (and (not (null? lst))
        (or (eq? 'milk (car lst))
            (got-milk? (cdr lst))))) (code:comment @#,t{recurs only if needed}))
(got-milk? '(apple banana))
(got-milk? '(apple milk banana))
]

如果求值到达 @racket[and] 或 @racket[or] 形式的最后一个 @racket[_expr]，那么该 @racket[_expr] 的值直接决定 @racket[and] 或 @racket[or] 的结果。因此，最后一个 @racket[_expr] 处于尾部位置，这意味着上面的 @racket[got-milk?] 函数在常量空间中运行。

@guideother{@secref["tail-recursion"] introduces tail calls and tail positions.}

@;------------------------------------------------------------------------
@section[#:tag "cond"]{Chaining Tests: @racket[cond]}

@racket[cond] 形式将一系列测试链接起来以选择结果表达式。粗略地说，@racket[cond] 的语法如下：

@refalso["if"]{@racket[cond]}

@specform[(cond [test-expr body ...+]
                ...)]

每个 @racket[_test-expr] 按顺序求值。如果它产生 @racket[#f]，则忽略相应的 @racket[_body]，继续对下一个 @racket[_test-expr] 求值。一旦某个 @racket[_test-expr] 产生真值，就对关联的 @racket[_body] 求值以产生 @racket[cond] 表达式的结果，并且不再对后续的 @racket[_test-expr] 求值。

@racket[cond] 中最后一个 @racket[_test-expr] 可以用 @racket[else] 替代。就求值而言，@racket[else] 是 @racket[#t] 的同义词，但它表明最后一个子句旨在捕获所有剩余情况。如果不使用 @racket[else]，则可能没有任何 @racket[_test-expr] 产生真值；在这种情况下，@racket[cond] 表达式的结果为 @|void-const|。

@examples[
(cond
 [(= 2 3) (error "wrong!")]
 [(= 2 2) 'ok])
(cond
 [(= 2 3) (error "wrong!")])
(cond
 [(= 2 3) (error "wrong!")]
 [else 'ok])
]

@def+int[
(define (got-milk? lst)
  (cond
    [(null? lst) #f]
    [(eq? 'milk (car lst)) #t]
    [else (got-milk? (cdr lst))]))
(got-milk? '(apple banana))
(got-milk? '(apple milk banana))
]

@racket[cond] 的完整语法还包括另外两种子句：

@specform/subs[#:literals (else =>)
               (cond cond-clause ...)
               ([cond-clause [test-expr then-body ...+]
                             [else then-body ...+]
                             [test-expr => proc-expr]
                             [test-expr]])]

@racket[=>] 变体捕获其 @racket[_test-expr] 的真值结果，并将其传递给 @racket[_proc-expr] 的结果，后者必须是一个单参数函数。

@examples[
(define (after-groucho lst)
  (cond
    [(member "Groucho" lst) => cdr]
    [else (error "not there")]))

(after-groucho '("Harpo" "Groucho" "Zeppo"))
(after-groucho '("Harpo" "Zeppo"))
]

仅包含 @racket[_test-expr] 的子句很少使用。它捕获 @racket[_test-expr] 的真值结果，并直接返回整个 @racket[cond] 表达式的结果。
