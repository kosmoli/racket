#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "set!"]{Assignment: @racket[set!]}

@refalso["set!"]{@racket[set!]}

使用 @racket[set!] 给变量赋值：

@specform[(set! id expr)]

@racket[set!] 表达式对 @racket[_expr] 求值，并将 @racket[_id]（必须在外部环境中已绑定）更改为结果值。@racket[set!] 表达式本身的结果是 @|void-const|。

@defexamples[
(define greeted null)
(define (greet name)
  (set! greeted (cons name greeted))
  (string-append "Hello, " name))

(greet "Athos")
(greet "Porthos")
(greet "Aramis")
greeted
]

@defs+int[
[(define (make-running-total)
   (let ([n 0])
     (lambda ()
       (set! n (+ n 1))
       n)))
 (define win (make-running-total))
 (define lose (make-running-total))]
(win)
(win)
(lose)
(win)
]

@;------------------------------------------------------------------------
@section[#:tag "using-set!"]{Guidelines for Using Assignment}

虽然使用 @racket[set!] 有时是合适的，但 Racket 风格通常不鼓励使用 @racket[set!]。以下准则可能有助于解释何时使用 @racket[set!] 是合适的。

@itemize[

 @item{与任何现代语言一样，对共享标识符赋值不能替代向过程传递参数或获取其结果。

       @as-examples[@t{@bold{@italic{Really awful}} example:}
       @defs+int[
       [(define name "unknown")
        (define result "unknown")
        (define (greet)
          (set! result (string-append "Hello, " name)))]
        (set! name "John")
        (greet)
        result
       ]]

      @as-examples[@t{Ok example:}
      @def+int[
        (define (greet name)
          (string-append "Hello, " name))
        (greet "John")
        (greet "Anna")
      ]]}

@;-- FIXME: explain more _why_ it's inferior
 @item{对局部变量进行一系列赋值远不如嵌套绑定。

       @as-examples[@t{@bold{Bad} example:}
       @interaction[
       (let ([tree 0])
         (set! tree (list tree 1 tree))
         (set! tree (list tree 2 tree))
         (set! tree (list tree 3 tree))
         tree)]]

       @as-examples[@t{Ok example:}
       @interaction[
       (let* ([tree 0]
              [tree (list tree 1 tree)]
              [tree (list tree 2 tree)]
              [tree (list tree 3 tree)])
         tree)]]}

 @item{使用赋值来累积迭代结果是一种不良风格。通过循环参数累积更好。

       @as-examples[@t{Somewhat bad example:}
       @def+int[
       (define (sum lst)
         (let ([s 0])
           (for-each (lambda (i) (set! s (+ i s)))
                     lst)
           s))
       (sum '(1 2 3))
       ]]

       @as-examples[@t{Ok example:}
       @def+int[
       (define (sum lst)
         (let loop ([lst lst] [s 0])
           (if (null? lst)
               s
               (loop (cdr lst) (+ s (car lst))))))
       (sum '(1 2 3))
       ]]

       @as-examples[@t{Better (use an existing function) example:}
       @def+int[
       (define (sum lst)
         (apply + lst))
       (sum '(1 2 3))
       ]]

       @as-examples[@t{Good (a general approach) example:}
       @def+int[
       (define (sum lst)
         (for/fold ([s 0])
                   ([i (in-list lst)])
           (+ s i)))
       (sum '(1 2 3))
       ]]  }

 @item{对于有状态对象是必要或合适的情况，使用 @racket[set!] 实现对象的状态是可以的。

       @as-examples[@t{Ok example:}
       @def+int[
       (define next-number!
         (let ([n 0])
           (lambda ()
             (set! n (add1 n))
             n)))
       (next-number!)
       (next-number!)
       (next-number!)]]}

]

在其他条件相同的情况下，不使用赋值或可变操作的程序总是优于使用赋值或可变操作的程序。然而，虽然应避免副作用，但如果结果代码可读性显著提高或实现了显著更好的算法，则应该使用它们。

使用可变值（如 vector 和 hash table）比直接使用 @racket[set!] 更少引起程序风格方面的质疑。然而，简单地将程序中的 @racket[set!] 替换为 @racket[vector-set!] 显然不会改善程序的风格。

@;------------------------------------------------------------------------
@section{Multiple Values: @racket[set!-values]}

@refalso["set!"]{@racket[set!-values]}

@racket[set!-values] 形式一次性给多个变量赋值，给定一个产生适当数量值的表达式：

@specform[(set!-values (id ...) expr)]

此形式等价于使用 @racket[let-values] 从 @racket[_expr] 接收多个结果，然后使用 @racket[set!] 将结果分别赋给各个 @racket[_id]。

@defexamples[
(define game
  (let ([w 0]
        [l 0])
    (lambda (win?)
      (if win?
          (set! w (+ w 1))
          (set! l (+ l 1)))
      (begin0
        (values w l)
        (code:comment @#,t{swap sides...})
        (set!-values (w l) (values l w))))))
(game #t)
(game #t)
(game #f)]
