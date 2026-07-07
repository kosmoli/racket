#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define qq (racket quasiquote))
@(define uq (racket unquote))

@title[#:tag "qq"]{Quasiquoting: @racket[quasiquote] and @racketvalfont{`}}

@refalso["quasiquote"]{@racket[quasiquote]}

@racket[quasiquote] 形式类似于 @racket[quote]：

@specform[(#,qq datum)]

然而，对于出现在 @racket[_datum] 中的每个 @racket[(#,uq _expr)]，@racket[_expr] 会被求值以产生一个值来替代 @racket[unquote] 子形式。

@examples[
(eval:alts (#,qq (1 2 (#,uq (+ 1 2)) (#,uq (- 5 1))))
           `(1 2 ,(+ 1 2), (- 5 1)))
]

此形式可用于编写按照特定模式构建列表的函数。

@examples[
(eval:alts (define (deep n)
             (cond
               [(zero? n) 0]
               [else
                (#,qq ((#,uq n) (#,uq (deep (- n 1)))))]))
           (define (deep n)
             (cond
               [(zero? n) 0]
               [else
                (quasiquote ((unquote n) (unquote (deep (- n 1)))))])))
(deep 8)
]

甚至可以廉价地以编程方式构造表达式。（当然，十次中有九次，你应该使用@seclink["macros"]{宏}来做这件事，第十次是在你学习像 @hyperlink["https://www.cs.brown.edu/~sk/Publications/Books/ProgLangs/"]{PLAI} 这样的教科书时。）

@examples[(define (build-exp n)
            (add-lets n (make-sum n)))
          
          (eval:alts
           (define (add-lets n body)
             (cond
               [(zero? n) body]
               [else
                (#,qq 
                 (let ([(#,uq (n->var n)) (#,uq n)])
                   (#,uq (add-lets (- n 1) body))))]))
           (define (add-lets n body)
             (cond
               [(zero? n) body]
               [else
                (quasiquote 
                 (let ([(unquote (n->var n)) (unquote n)])
                   (unquote (add-lets (- n 1) body))))])))
          
          (eval:alts
           (define (make-sum n)
             (cond
               [(= n 1) (n->var 1)]
               [else
                (#,qq (+ (#,uq (n->var n))
                         (#,uq (make-sum (- n 1)))))]))
           (define (make-sum n)
             (cond
               [(= n 1) (n->var 1)]
               [else
                (quasiquote (+ (unquote (n->var n))
                               (unquote (make-sum (- n 1)))))])))
          (define (n->var n) (string->symbol (format "x~a" n)))
          (build-exp 3)]

@racket[unquote-splicing] 形式类似于 @racket[unquote]，但它的 @racket[_expr] 必须产生一个列表，并且 @racket[unquote-splicing] 形式必须出现在产生列表或 vector 的上下文中。顾名思义，结果列表被拼接到使用它的上下文中。

@examples[
(eval:alts (#,qq (1 2 (#,(racket unquote-splicing) (list (+ 1 2) (- 5 1))) 5))
           `(1 2 ,@(list (+ 1 2) (- 5 1)) 5))
]

使用拼接，我们可以修改上面示例表达式的构造，使其只有一个 @racket[let] 表达式和一个 @racket[+] 表达式。

@examples[(eval:alts
           (define (build-exp n)
             (add-lets 
              n
              (#,qq (+ (#,(racket unquote-splicing) 
                        (build-list
                         n
                         (λ (x) (n->var (+ x 1)))))))))
           (define (build-exp n)
             (add-lets
              n
              (quasiquote (+ (unquote-splicing 
                              (build-list 
                               n
                               (λ (x) (n->var (+ x 1))))))))))
          (eval:alts
           (define (add-lets n body)
             (#,qq
              (let (#,uq
                    (build-list
                     n
                     (λ (n)
                       (#,qq 
                        [(#,uq (n->var (+ n 1))) (#,uq (+ n 1))]))))
                (#,uq body))))
           (define (add-lets n body)
             (quasiquote
              (let (unquote
                    (build-list 
                     n
                     (λ (n) 
                       (quasiquote
                        [(unquote (n->var (+ n 1))) (unquote (+ n 1))]))))
                (unquote body)))))
          (define (n->var n) (string->symbol (format "x~a" n)))
          (build-exp 3)]

如果 @racket[quasiquote] 形式出现在外层 @racket[quasiquote] 形式内部，则内层 @racket[quasiquote] 会有效地取消一层 @racket[unquote] 和 @racket[unquote-splicing] 形式，因此需要第二个 @racket[unquote] 或 @racket[unquote-splicing]。

@examples[
(eval:alts (#,qq (1 2 (#,qq (#,uq (+ 1 2)))))
           `(1 2 (,(string->uninterned-symbol "quasiquote")
                  (,(string->uninterned-symbol "unquote") (+ 1 2)))))
(eval:alts (#,qq (1 2 (#,qq (#,uq (#,uq (+ 1 2))))))
           `(1 2 (,(string->uninterned-symbol "quasiquote")
                  (,(string->uninterned-symbol "unquote") 3))))
(eval:alts (#,qq (1 2 (#,qq ((#,uq (+ 1 2)) (#,uq (#,uq (- 5 1)))))))
           `(1 2 (,(string->uninterned-symbol "quasiquote")
                  ((,(string->uninterned-symbol "unquote") (+ 1 2))
                   (,(string->uninterned-symbol "unquote") 4)))))
]

上面的求值实际上不会如所示那样打印。相反，会使用 @racket[quasiquote] 和 @racket[unquote] 的简写形式：@litchar{`}（即反引号）和 @litchar{,}（即逗号）。相同的简写可以在表达式中使用：

@examples[
`(1 2 `(,(+ 1 2) ,,(- 5 1)))
]

@racket[unquote-splicing] 的简写形式是 @litchar[",@"]：

@examples[
`(1 2 ,@(list (+ 1 2) (- 5 1)))
]
