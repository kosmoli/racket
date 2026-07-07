#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title{Named @racket[let]}

命名 @racket[let] 是一种迭代和递归形式。它使用与局部绑定相同的语法关键字 @racket[let]，但在 @racket[let] 之后跟一个标识符（而不是紧跟一个左括号）会触发不同的解析方式。

@specform[
(let proc-id ([arg-id init-expr] ...)
  body ...+)
]

命名 @racket[let] 形式等价于

@racketblock[
((letrec ([_proc-id (lambda (_arg-id ...)
                      _body ...+)])
   _proc-id)
 _init-expr ...)
]

也就是说，命名 @racket[let] 绑定一个仅在函数体内可见的函数标识符，并使用一些初始表达式的值隐式调用该函数。

@defexamples[
(define (duplicate pos lst)
  (let dup ([i 0]
            [lst lst])
   (cond
     [(= i pos) (cons (car lst) lst)]
     [else (cons (car lst) (dup (+ i 1) (cdr lst)))])))
(duplicate 1 (list "apple" "cheese burger!" "banana"))
]

