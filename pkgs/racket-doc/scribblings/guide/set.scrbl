#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "set!"]{赋值：@racket[set!]}

@refalso["set!"]{@racket[set!]}

使用 @racket[set!] 赋值给 variable：

@specform[(set! id expr)]

@racket[set!] 表达式对 @racket[_expr] 求值，并将 @racket[_id]（必须绑定在封闭 environment 中）更改为结果值。@racket[set!] 表达式本身的结果是 @|void-const|。

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
@section[#:tag "using-set!"]{赋值使用指南}

尽管有时使用 @racket[set!] 是适当的，但 Racket 风格通常不鼓励使用 @racket[set!]。以下准则可能有助于解释何时使用 @racket[set!] 是适当的。

@itemize[

 @item{与任何现代语言一样，赋值给共享 identifier 并不是向 procedure 传递参数或获取其结果的替代品。

       @as-examples[@t{@bold{@italic{真正糟糕}} 的示例：}
       @defs+int[
       [(define name "unknown")
        (define result "unknown")
        (define (greet)
          (set! result (string-append "Hello, " name)))]
        (set! name "John")
        (greet)
        result
       ]]

      @as-examples[@t{好的示例：}
      @def+int[
        (define (greet name)
          (string-append "Hello, " name))
        (greet "John")
        (greet "Anna")
      ]]}

 @item{对本地 variable 的一系列赋值远不如嵌套绑定。

       @as-examples[@t{@bold{糟糕} 的示例：}
       @interaction[
       (let ([tree 0])
         (set! tree (list tree 1 tree))
         (set! tree (list tree 2 tree))
         (set! tree (list tree 3 tree))
         tree)]]

       @as-examples[@t{好的示例：}
       @interaction[
       (let* ([tree 0]
              [tree (list tree 1 tree)]
              [tree (list tree 2 tree)]
              [tree (list tree 3 tree)])
         tree)]]}

 @item{使用赋值从 iteration 累积结果是不好的 style。通过 loop argument 累积更好。

       @as-examples[@t{有点糟糕的示例：}
       @def+int[
       (define (sum lst)
         (let ([s 0])
           (for-each (lambda (i) (set! s (+ i s)))
                     lst)
           s))
       (sum '(1 2 3))
       ]]

       @as-examples[@t{好的示例：}
       @def+int[
       (define (sum lst)
         (let loop ([lst lst] [s 0])
           (if (null? lst)
               s
               (loop (cdr lst) (+ s (car lst))))))
       (sum '(1 2 3))
       ]]

       @as-examples[@t{更好（使用现有函数）的示例：}
       @def+int[
       (define (sum lst)
         (apply + lst))
       (sum '(1 2 3))
       ]]

       @as-examples[@t{好（通用方法）的示例：}
       @def+int[
       (define (sum lst)
         (for/fold ([s 0])
                   ([i (in-list lst)])
           (+ s i)))
       (sum '(1 2 3))
       ]]  }

 @item{对于 stateful 对象是必要或适当的情况，使用 @racket[set!] 来实现对象的状态是好的。

       @as-examples[@t{好的示例：}
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

在所有其他条件相同的情况下，不使用赋值或 mutation 的程序总是优于使用赋值或 mutation 的程序。但是，如果结果代码具有显著更好的可读性或者实现了显著更好的算法，则应该使用 side effect。

使用可变值（如 vector 和 hash table）比直接使用 @racket[set!] 引起的 style 怀疑更少。不过，简单地将程序中的 @racket[set!] 替换为 @racket[vector-set!] 显然不会改善程序的 style。

@;------------------------------------------------------------------------
@section{多值：@racket[set!-values]}

@refalso["set!"]{@racket[set!-values]}

@racket[set!-values] 形式一次赋值给多个 variable，给定一个产生适当数量值的 expression：

@specform[(set!-values (id ...) expr)]

此形式等同于使用 @racket[let-values] 接收来自 @racket[_expr] 的多个结果，然后使用 @racket[set!] 将结果分别赋值给 @racket[_id]。

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
        (code:comment @#,t{交换方...})
        (set!-values (w l) (values l w))))))
(game #t)
(game #t)
(game #f)]
