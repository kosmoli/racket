#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "begin"]{Sequencing}

Racket 程序员倾向于编写尽可能少副作用的程序，因为纯函数式代码更容易测试，也更容易组合成更大的程序。然而，与外部环境的交互需要顺序执行，例如写入显示器、打开图形窗口或操作磁盘上的文件。

@;------------------------------------------------------------------------
@section{Effects Before: @racket[begin]}

@refalso["begin"]{@racket[begin]}

一个 @racket[begin] 表达式将多个表达式顺序排列：

@specform[(begin expr ...+)]{}

@racket[_expr] 按顺序求值，除最后一个 @racket[_expr] 之外的所有结果都被忽略。最后一个 @racket[_expr] 的结果就是 @racket[begin] 表达式的结果，并且它相对于 @racket[begin] 表达式处于尾部位置。

@defexamples[
(define (print-triangle height)
  (if (zero? height)
      (void)
      (begin
        (display (make-string height #\*))
        (newline)
        (print-triangle (sub1 height)))))
(print-triangle 4)
]

许多形式，如 @racket[lambda] 或 @racket[cond]，即使没有 @racket[begin] 也支持表达式序列。这样的位置有时被称为具有@deftech{隐式 begin}。

@defexamples[
(define (print-triangle height)
  (cond
    [(positive? height)
     (display (make-string height #\*))
     (newline)
     (print-triangle (sub1 height))]))
(print-triangle 4)
]

@racket[begin] 形式在顶层、模块级别或仅在内部定义之后作为 @racket[body] 时是特殊的。在这些位置，@racket[begin] 的内容不是构成一个表达式，而是被拼接到周围的上下文中。

@defexamples[
(let ([curly 0])
  (begin
    (define moe (+ 1 curly))
    (define larry (+ 1 moe)))
  (list larry curly moe))
]

这种拼接行为主要用于宏，我们将在 @secref["macros"] 中讨论。

@;------------------------------------------------------------------------
@section{Effects After: @racket[begin0]}

@refalso["begin"]{@racket[begin0]}

@racket[begin0] 表达式与 @racket[begin] 表达式具有相同的语法：

@specform[(begin0 expr ...+)]{}

区别在于 @racket[begin0] 返回第一个 @racket[expr] 的结果，而不是最后一个 @racket[expr] 的结果。@racket[begin0] 形式对于实现计算之后发生的副作用很有用，特别是在计算产生未知数量结果的情况下。

@defexamples[
(define (log-times thunk)
  (printf "Start: ~s\n" (current-inexact-milliseconds))
  (begin0
    (thunk)
    (printf "End..: ~s\n" (current-inexact-milliseconds))))
(log-times (lambda () (sleep 0.1) 0))
(log-times (lambda () (values 1 2)))
]

@;------------------------------------------------------------------------
@section[#:tag "when+unless"]{Effects If...: @racket[when] and @racket[unless]}

@refalso["when+unless"]{@racket[when] and @racket[unless]}

@racket[when] 形式将 @racket[if] 风格的条件判断与顺序执行结合在一起，只有 ``then'' 子句而没有 ``else'' 子句：

@specform[(when test-expr then-body ...+)]

如果 @racket[_test-expr] 产生一个真值，则所有 @racket[_then-body] 都会被求值。最后一个 @racket[_then-body] 的结果就是 @racket[when] 表达式的结果。否则，不求值任何 @racket[_then-body]，结果为 @|void-const|。

@racket[unless] 形式类似：

@specform[(unless test-expr then-body ...+)]

区别在于 @racket[_test-expr] 的结果被反转：仅当 @racket[_test-expr] 的结果为 @racket[#f] 时，才对 @racket[_then-body] 进行求值。

@defexamples[
(define (enumerate lst)
  (if (null? (cdr lst))
      (printf "~a.\n" (car lst))
      (begin
        (printf "~a, " (car lst))
        (when (null? (cdr (cdr lst)))
          (printf "and "))
        (enumerate (cdr lst)))))
(enumerate '("Larry" "Curly" "Moe"))
]

@def+int[
(define (print-triangle height)
  (unless (zero? height)
    (display (make-string height #\*))
    (newline)
    (print-triangle (sub1 height))))
(print-triangle 4)
]
