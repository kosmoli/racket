#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "begin"]{序列化}

Racket 程序员倾向于编写尽可能少副作用的程序，因为纯 functional 代码
更易于测试和组合成更大的程序。然而，与外部环境的交互需要序列化，
例如在显示器上显示内容、打开图形窗口或在磁盘上操作文件时。

@;------------------------------------------------------------------------
@section{效果之前：@racket[begin]}

@refalso["begin"]{@racket[begin]}

一个 @racket[begin] 表达式序列化表达式：

@specform[(begin expr ...+)]{}

@racket[_expr] 按顺序求值，除最后一个 @racket[_expr] 外其余所有 @racket[_expr] 
的结果均被忽略。最后一个 @racket[_expr] 的结果即为 @racket[begin] 形式的结果，
并且相对于 @racket[begin] 形式，它处于 tail position。

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

诸如 @racket[lambda] 或 @racket[cond] 等许多形式，即使没有显式使用 @racket[begin]，
也支持表达式序列。这些位置有时被称为 @deftech{implicit begin}。

@defexamples[
(define (print-triangle height)
  (cond
    [(positive? height)
     (display (make-string height #\*))
     (newline)
     (print-triangle (sub1 height))]))
(print-triangle 4)
]

@racket[begin] 形式在顶层、module level 或作为仅跟随 internal 
definitions 的 @racket[body] 中是特殊的。在这些位置上，
@racket[begin] 的内容会被嵌入周围的上下文中，而不是形成一个表达式。

@defexamples[
(let ([curly 0])
  (begin
    (define moe (+ 1 curly))
    (define larry (+ 1 moe)))
  (list larry curly moe))
]

这种嵌入行为主要用于宏，我们将在 @secref["macros"] 中稍后讨论。

@;------------------------------------------------------------------------
@section{效果之后：@racket[begin0]}

@refalso["begin"]{@racket[begin0]}

@racket[begin0] 表达式的语法与 @racket[begin] 相同：

@specform[(begin0 expr ...+)]{}

不同之处在于 @racket[begin0] 返回第一个 @racket[_expr] 的结果，
而不是最后一个 @racket[_expr] 的结果。@racket[begin0] 形式适用于
在计算产生未知数量结果时实现 side-effects。

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
@section[#:tag "when+unless"]{效果如果……：@racket[when] 和 @racket[unless]}

@refalso["when+unless"]{@racket[when] 和 @racket[unless]}

@racket[when] 形式将 @racket[if] 风格的条件与"then"序列（没有"else"）组合在一起：

@specform[(when test-expr then-body ...+)]

如果 @racket[_test-expr] 产生真值，则所有 @racket[_then-body] 都会被求值。
最后一个 @racket[_then-body] 的结果就是 @racket[when] 形式的结果。
否则，不 @racket[_then-body] 被求值，结果为 @|void-const|。

@racket[unless] 形式类似：

@specform[(unless test-expr then-body ...+)]

不同之处在于 @racket[_test-expr] 的结果被反转：只有当 @racket[_test-expr]
结果为 @racket[#f] 时，@racket[_then-body] 才被求值。

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
