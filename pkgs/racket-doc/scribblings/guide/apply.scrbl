#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "application"]{Function Calls@aux-elem{ (Procedure Applications)}}

形式为

@specsubform[
(proc-expr arg-expr ...)
]

的表达式是一个（function call）函数调用——也称为 @defterm{procedure
application}（过程应用）——当 @racket[_proc-expr] 不是绑定为 syntax transformer
的标识符（如 @racket[if] 或 @racket[define]）。

@section{Evaluation Order and Arity}

函数调用的求值过程是：首先按从左到右的顺序对 @racket[_proc-expr]
和所有 @racket[_arg-expr] 求值。然后，如果 @racket[_proc-expr] 产生的函数
接受与所提供的 @racket[_arg-expr] 数量相同的参数，则调用该函数。
否则，将引发异常。

@examples[
(cons 1 null)
(+ 1 2 3)
(cons 1 2 3)
(1 2 3)
]

某些函数（如 @racket[cons]）接受固定数量的参数。某些函数（如 @racket[+]
或 @racket[list]）接受任意数量的参数。某些函数接受一定范围的参数数量；
例如 @racket[substring] 接受两个或三个参数。函数的 @idefterm{arity}（元数）
是其接受的参数数量。

@;------------------------------------------------------------------------
@section[#:tag "keyword-args"]{Keyword Arguments}

除了按位置参数外，某些函数还接受 @defterm{keyword arguments}（关键字参数）。
在这种情况下，@racket[_arg] 可以是 @racket[_arg-keyword _arg-expr] 序列，
而不仅仅是 @racket[_arg-expr]：

@guideother{@secref["keywords"] 介绍了关键字。}

@specform/subs[
(_proc-expr arg ...)
([arg arg-expr
      (code:line arg-keyword arg-expr)])
]

例如，

@racketblock[(go "super.rkt" #:mode 'fast)]

调用绑定到 @racket[go] 的函数，其中 @racket["super.rkt"] 作为按位置参数，
@racket['fast] 作为与 @racket[#:mode] 关键字关联的参数。关键字隐式地与
其后的表达式配对。

由于单独的关键字不是表达式，因此

@racketblock[(go "super.rkt" #:mode #:fast)]

是语法错误。@racket[#:mode] 关键字后必须跟随一个表达式以产生一个参数值，
而 @racket[#:fast] 不是表达式。

关键字 @racket[_arg] 的顺序决定了 @racket[_arg-expr] 的求值顺序，
但函数接受关键字参数与它们在参数列表中的位置无关。
上述对 @racket[go] 的调用也可以等效地写作

@racketblock[(go #:mode 'fast "super.rkt")]

@refdetails["application"]{过程应用}

@;------------------------------------------------------------------------
@section[#:tag "apply"]{The @racket[apply] Function}

函数调用的语法支持任意数量的参数，但每次具体调用始终指定固定数量的参数。
因此，接受参数列表的函数不能直接将类似 @racket[+] 的函数应用于列表中的所有项：

@def+int[
(define (avg lst) (code:comment @#,elem{无法工作...})
  (/ (+ lst) (length lst)))
(avg '(1 2 3))
]

@def+int[
(define (avg lst) (code:comment @#,elem{无法总是工作...})
  (/ (+ (list-ref lst 0) (list-ref lst 1) (list-ref lst 2))
     (length lst)))
(avg '(1 2 3))
(avg '(1 2))
]

@racket[apply] 函数提供了一种绕过此限制的方法。它接受一个函数和一个
@italic{list} 参数，并将函数应用于列表中的值：

@def+int[
(define (avg lst)
  (/ (apply + lst) (length lst)))
(avg '(1 2 3))
(avg '(1 2))
(avg '(1 2 3 4))
]

便利的是，@racket[apply] 函数接受函数与列表之间的额外参数。
这些额外参数会被有效地 @racket[cons] 到参数列表上：

@def+int[
(define (anti-sum lst)
  (apply - 0 lst))
(anti-sum '(1 2 3))
]

@racket[apply] 函数也接受关键字参数，并将其传递给被调用的函数：

@racketblock[
(apply go #:mode 'fast '("super.rkt"))
(apply go '("super.rkt") #:mode 'fast)
]

包含在 @racket[apply] 列表参数中的关键字不计入被调用函数的关键字参数；
相反，此列表中的所有参数都被视为按位置参数。要将关键字参数列表传递给函数，
请使 @racket[keyword-apply] 函数，该函数接受要应用的函数和三个列表。
前两个列表是并行的，其中第一个列表包含关键字（按 @racket[keyword<?] 排序），
第二个列表包含每个关键字对应的参数。第三个列表包含按位置函数参数，
与 @racket[apply] 中相同。

@racketblock[
(keyword-apply go
               '(#:mode)
               '(fast)
               '("super.rkt"))
]
