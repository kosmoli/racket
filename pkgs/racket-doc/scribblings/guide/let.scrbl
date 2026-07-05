#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "let"]{本地绑定}

尽管内部 @racket[define] 可用于本地绑定，Racket 提供了三种为程序员提供更多绑定控制的 form：@racket[let]、@racket[let*] 和 @racket[letrec]。

@;------------------------------------------------------------------------
@section{并行绑定：@racket[let]}

@refalso["let"]{@racket[let]}

@racket[let] form 绑定一组 identifier，每个都绑定到某个表达式的结果，供 @racket[let] body 使用：

@specform[(let ([id expr] ...) body ...+)]{}

@racket[_id] 是"并行"绑定的。也就是说，任何 @racket[_id] 都不在任何 @racket[_id] 的右侧 @racket[_expr] 中绑定，但所有 @racket[_id] 都在 @racket[_body] 中可用。@racket[_id] 必须彼此不同。

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

@racket[_id] 的 @racket[_expr] 看不到其自身绑定这一事实对于必须引用旧值的 wrapper 通常很有用：

@interaction[
(let ([+ (lambda (x y)
           (if (string? x)
               (string-append x y)
               (+ x y)))]) (code:comment @#,t{使用原始 @racket[+]})
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

将 @racket[let] 绑定描述为"并行"并不意味着并发求值。@racket[_expr] 按顺序求值，尽管在所有 @racket[_expr] 求值之前绑定被延迟。

@;------------------------------------------------------------------------
@section{顺序绑定：@racket[let*]}

@refalso["let"]{@racket[let*]}

@racket[let*] 的语法与 @racket[let] 相同：

@specform[(let* ([id expr] ...) body ...+)]{}

区别在于每个 @racket[_id] 可在后续 @racket[_expr] 中使用，也可在 @racket[_body] 中使用。此外，@racket[_id] 不必不同，最近的绑定是可见的。

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

换句话说，@racket[let*] form 等同于嵌套的 @racket[let] form，每个都只有一个绑定：

@interaction[
(let ([name (list "Burroughs")])
  (let ([name (cons "Rice" name)])
    (let ([name (cons "Edgar" name)])
      name)))
]

@;------------------------------------------------------------------------
@section{递归绑定：@racket[letrec]}

@refalso["let"]{@racket[letrec]}

@racket[letrec] 的语法也与 @racket[let] 相同：

@specform[(letrec ([id expr] ...) body ...+)]{}

虽然 @racket[let] 仅在 @racket[_body] 中使其绑定可用，@racket[let*] 使其绑定可用于任何后续绑定 @racket[_expr]，但 @racket[letrec] 使所有其他 @racket[_expr] 都可使用其绑定——即使是较早的那些。换句话说，@racket[letrec] 绑定是递归的。

@racket[letrec] form 中的 @racket[_expr] 最常是递归和互递归函数的 @racket[lambda] form：

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

尽管 @racket[letrec] form 中的 @racket[_expr] 通常是 @racket[lambda] expression，但它们可以是任何 expression。表达式按顺序求值，获得每个值后，立即将其与对应的 @racket[_id] 关联。如果在值就绪之前引用了 @racket[_id]，将引发错误，就像内部定义一样。

@interaction[
(letrec ([quicksand quicksand])
  quicksand)
]

@; ----------------------------------------
@include-section["named-let.scrbl"]

@; ----------------------------------------
@section{多值：@racket[let-values]、@racket[let*-values]、@racket[letrec-values]}

@refalso["let"]{多值绑定 form}

以与 @racket[define-values] 在定义中绑定多个结果相同的方式（参见 @secref["multiple-values"]），@racket[let-values]、@racket[let*-values] 和 @racket[letrec-values] 在本地绑定多个结果。

@specform[(let-values ([(id ...) expr] ...)
            body ...+)]
@specform[(let*-values ([(id ...) expr] ...)
            body ...+)]
@specform[(letrec-values ([(id ...) expr] ...)
            body ...+)]

每个 @racket[_expr] 必须产生与对应 @racket[_id] 相同数量的值。绑定规则与非 @racketkeywordfont{-values} 形式相同：@racket[let-values] 的 @racket[_id] 仅在 @racket[_body] 中绑定，@racket[let*-values] 的 @racket[_id] 在后续子句的 @racket[_expr] 中绑定，@racket[letrec-values] 的 @racket[_id] 对所有 @racket[_expr] 都绑定。

@examples[
(let-values ([(q r) (quotient/remainder 14 3)])
  (list q r))
]
