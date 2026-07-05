#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "conditionals"]{条件表达式}

大多数用于分支的 function（例如 @racket[<] 和 @racket[string?]）产生
@racket[#t] 或 @racket[#f]。然而，Racket 的分支形式将除 @racket[#f] 以外的
任何值都视为 true。我们用 @defterm{true value} 来表示除 @racket[#f] 以外的任何值。

这种 "true value" 的约定与 @racket[#f] 用于表示 failure 或指示可选值未被提供的
协议很好地配合使用。（请注意不要过度使用此技巧，并记住 exception 通常是报告 failure 的更好机制。）

例如，@racket[member] function 有双重用途；它可用于查找以特定项开头的 list 尾部，
或者简单地检查项是否存在于 list 中：

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
@section{简单分支：@racket[if]}

@refalso["if"]{@racket[if]}

在 @racket[if] 形式中，

@specform[(if test-expr then-expr else-expr)]

@racket[_test-expr] 始终被求值。如果它产生除 @racket[#f] 以外的任何值，
则 @racket[_then-expr] 被求值。否则，@racket[_else-expr] 被求值。

@racket[if] 形式必须同时具有 @racket[_then-expr] 和 @racket[_else-expr]；
后者不是可选的。要根据 @racket[_test-expr] 执行（或跳过）side effect，
请使用 @racket[when] 或 @racket[unless]，我们稍后会在 @secref["begin"] 中描述。

@;------------------------------------------------------------------------
@section[#:tag "and+or"]{组合测试：@racket[and] 和 @racket[or]}

@refalso["if"]{@racket[and] 和 @racket[or]}

Racket 的 @racket[and] 和 @racket[or] 是语法形式，而不是 function。
与 function 不同，如果早期表达式就能确定结果，
@racket[and] 和 @racket[or] 形式可以跳过对后续表达式的求值。

@specform[(and expr ...)]

如果 @racket[and] 形式的任一 @racket[_expr] 产生 @racket[#f]，
则产生 @racket[#f]。否则，它产生最后一个 @racket[_expr] 的值。
作为特殊情况，@racket[(and)] 产生 @racket[#t]。

@specform[(or expr ...)]

如果 @racket[or] 形式的所有 @racket[_expr] 都产生 @racket[#f]，
则产生 @racket[#f]。否则，它产生第一个非 @racket[#f] 的值。
作为特殊情况，@racket[(or)] 产生 @racket[#f]。

@examples[
(code:line
 (define (got-milk? lst)
   (and (not (null? lst))
        (or (eq? 'milk (car lst))
            (got-milk? (cdr lst))))) (code:comment @#,t{仅在需要时递归}))
(got-milk? '(apple banana))
(got-milk? '(apple milk banana))
]

如果求值到达 @racket[and] 或 @racket[or] 形式的最后一个 @racket[_expr]，
则 @racket[_expr] 的值直接决定 @racket[and] 或 @racket[or] 的结果。
因此，最后一个 @racket[_expr] 处于 tail position，
这意味着上述 @racket[got-milk?] function 以常量空间运行。

@guideother{@secref["tail-recursion"] 介绍了 tail call 和 tail position。}

@;------------------------------------------------------------------------
@section[#:tag "cond"]{链式测试：@racket[cond]}

@racket[cond] 形式将一系列测试链接起来以选择结果表达式。
@racket[cond] 的语法如下：

@refalso["if"]{@racket[cond]}

@specform[(cond [test-expr body ...+]
                ...)]

每个 @racket[_test-expr] 按顺序被求值。如果产生 @racket[#f]，
对应的 @racket[_body] 被忽略，继续求值下一个 @racket[_test-expr]。
一旦某个 @racket[_test-expr] 产生 true value，关联的 @racket[_body]
被求值以产生 @racket[cond] 形式的结果，不再进一步求值 @racket[_test-expr]。

@racket[cond] 中的最后一个 @racket[_test-expr] 可以用 @racket[else] 替换。
就求值而言，@racket[else] 是 @racket[#t] 的同义词，但它明确了最后一个子句
旨在捕获所有剩余情况。如果未使用 @racket[else]，则可能没有 @racket[_test-expr]
产生 true value；在这种情况下，@racket[cond] 表达式的结果是 @|void-const|。

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

@racket[cond] 的完整语法还包括两种额外的子句：

@specform/subs[#:literals (else =>)
               (cond cond-clause ...)
               ([cond-clause [test-expr then-body ...+]
                             [else then-body ...+]
                             [test-expr => proc-expr]
                             [test-expr]])]

@racket[=>] 变体捕获其 @racket[_test-expr] 的 true 结果，
并将其传递给 @racket[_proc-expr] 的结果，该结果必须是一个单参数 function。

@examples[
(define (after-groucho lst)
  (cond
    [(member "Groucho" lst) => cdr]
    [else (error "not there")]))

(after-groucho '("Harpo" "Groucho" "Zeppo"))
(after-groucho '("Harpo" "Zeppo"))
]

仅包含 @racket[_test-expr] 的子句很少使用。它捕获 @racket[_test-expr] 的 true 结果，
并简单地返回整个 @racket[cond] 表达式的结果。
