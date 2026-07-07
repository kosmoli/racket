#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "let"]{Local Binding}

虽然内部 @racket[define] 可以用于局部绑定，但 Racket 提供了三种形式让程序员对绑定有更多控制：@racket[let]、@racket[let*] 和 @racket[letrec]。

@;------------------------------------------------------------------------
@section{Parallel Binding: @racket[let]}

@refalso["let"]{@racket[let]}

@racket[let] 形式绑定一组标识符，每个标识符绑定到某个表达式的结果，以供 @racket[let] 主体使用：

@specform[(let ([id expr] ...) body ...+)]{}

@racket[_id] 被"并行"绑定。也就是说，任何 @racket[_id] 的右侧 @racket[_expr] 中都没有绑定该 @racket[_id]，但所有 @racket[_id] 在 @racket[_body] 中都可用。@racket[_id] 必须互不相同。

@examples[
(let ([me "Bob"])
  me)
(let ([me "Bob"]
      [myself "Robert"]
      [I "Bobby"])
  (list me myself I))
(let ([me "Bob"]
      [me "Robert"])
  me)
]

@racket[_id] 的 @racket[_expr] 无法看到自身绑定这一事实通常对必须引用旧值的包装器很有用：

@interaction[
(let ([+ (lambda (x y)
           (if (string? x)
               (string-append x y)
               (+ x y)))]) (code:comment @#,t{use original @racket[+]})
  (list (+ 1 2)
        (+ "see" "saw")))
]

偶尔，@racket[let] 绑定的并行性质对于交换或重新排列一组绑定很方便：

@interaction[
(let ([me "Tarzan"]
      [you "Jane"])
  (let ([me you]
        [you me])
    (list me you)))
]

将 @racket[let] 绑定描述为"并行"并不意味着并发求值。@racket[_expr] 按顺序求值，即使绑定被延迟到所有 @racket[_expr] 求值完毕。

@;------------------------------------------------------------------------
@section{Sequential Binding: @racket[let*]}

@refalso["let"]{@racket[let*]}

@racket[let*] 的语法与 @racket[let] 相同：

@specform[(let* ([id expr] ...) body ...+)]{}

区别在于每个 @racket[_id] 都可以在后续的 @racket[_expr] 以及 @racket[_body] 中使用。此外，@racket[_id] 不需要互不相同，最近的绑定是可见的。

@examples[
(let* ([x (list "Burroughs")]
       [y (cons "Rice" x)]
       [z (cons "Edgar" y)])
  (list x y z))
(let* ([name (list "Burroughs")]
       [name (cons "Rice" name)]
       [name (cons "Edgar" name)])
  name)
]

换句话说，@racket[let*] 形式等价于嵌套的 @racket[let] 形式，每个只有一个绑定：

@interaction[
(let ([name (list "Burroughs")])
  (let ([name (cons "Rice" name)])
    (let ([name (cons "Edgar" name)])
      name)))
]

@;------------------------------------------------------------------------
@section{Recursive Binding: @racket[letrec]}

@refalso["let"]{@racket[letrec]}

@racket[letrec] 的语法也与 @racket[let] 相同：

@specform[(letrec ([id expr] ...) body ...+)]{}

@racket[let] 仅在 @racket[_body] 中使绑定可用，@racket[let*] 使绑定可用于任何后续的绑定 @racket[_expr]，而 @racket[letrec] 使绑定可用于所有其他 @racket[_expr]——甚至包括更早的。换句话说，@racket[letrec] 绑定是递归的。

@racket[letrec] 形式中的 @racket[_expr] 最常是用于递归和相互递归函数的 @racket[lambda] 形式：

@interaction[
(letrec ([swing
          (lambda (t)
            (if (eq? (car t) 'tarzan)
                (cons 'vine
                      (cons 'tarzan (cddr t)))
                (cons (car t)
                      (swing (cdr t)))))])
  (swing '(vine tarzan vine vine)))
]

@interaction[
(letrec ([tarzan-near-top-of-tree?
          (lambda (name path depth)
            (or (equal? name "tarzan")
                (and (directory-exists? path)
                     (tarzan-in-directory? path depth))))]
         [tarzan-in-directory?
          (lambda (dir depth)
            (cond
              [(zero? depth) #f]
              [else
               (ormap
                (λ (elem)
                  (tarzan-near-top-of-tree? (path-element->string elem)
                                            (build-path dir elem)
                                            (- depth 1)))
                (directory-list dir))]))])
  (tarzan-near-top-of-tree? "tmp" 
                            (find-system-path 'temp-dir)
                            4))
]

虽然 @racket[letrec] 形式的 @racket[_expr] 通常是 @racket[lambda] 表达式，但它们可以是任何表达式。表达式按顺序求值，获得每个值后立即与对应的 @racket[_id] 关联。如果在值准备好之前引用了 @racket[_id]，则会引发错误，就像内部定义一样。

@interaction[
(letrec ([quicksand quicksand])
  quicksand)
]

@; ----------------------------------------
@include-section["named-let.scrbl"]

@; ----------------------------------------
@section{Multiple Values: @racket[let-values], @racket[let*-values], @racket[letrec-values]}

@refalso["let"]{multiple-value binding forms}

正如 @racket[define-values] 在定义中绑定多个结果（参见 @secref["multiple-values"]），@racket[let-values]、@racket[let*-values] 和 @racket[letrec-values] 在局部绑定多个结果。

@specform[(let-values ([(id ...) expr] ...)
            body ...+)]
@specform[(let*-values ([(id ...) expr] ...)
            body ...+)]
@specform[(letrec-values ([(id ...) expr] ...)
            body ...+)]

每个 @racket[_expr] 必须产生与对应 @racket[_id] 数量相同的值。绑定规则与不带 @racketkeywordfont{-values} 的形式相同：@racket[let-values] 的 @racket[_id] 仅在 @racket[_body] 中绑定，@racket[let*-values] 的 @racket[_id] 在后续子句的 @racket[_expr] 中绑定，@racket[letrec-value] 的 @racket[_id] 在所有 @racket[_expr] 中绑定。

@examples[
(let-values ([(q r) (quotient/remainder 14 3)])
  (list q r))
]
