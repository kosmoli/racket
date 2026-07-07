#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define greet-eval (make-base-eval))

@title[#:tag "lambda"]{Functions@aux-elem{ (Procedures)}: @racket[lambda]}

@racket[lambda] 表达式创建一个函数。最简单的情况下，@racket[lambda] 表达式具有以下形式

@specform[
(lambda (arg-id ...)
  body ...+)
]

带有 @math{n} 个 @racket[_arg-id] 的 @racket[lambda] 形式接受 @math{n} 个参数：

@interaction[
((lambda (x) x)
 1)
((lambda (x y) (+ x y))
 1 2)
((lambda (x y) (+ x y))
 1)
]

@;------------------------------------------------------------------------
@section[#:tag "rest-args"]{Declaring a Rest Argument}

@racket[lambda] 表达式还可以具有以下形式

@specform[
(lambda rest-id
  body ...+)
]

也就是说，@racket[lambda] 表达式可以有一个不被括号包围的 @racket[_rest-id]。生成的函数接受任意数量的参数，参数被放入绑定到 @racket[_rest-id] 的列表中。

@examples[
((lambda x x)
 1 2 3)
((lambda x x))
((lambda x (car x))
 1 2 3)
]

带有 @racket[_rest-id] 的函数通常使用 @racket[apply] 来调用另一个接受任意数量参数的函数。

@guideother{@secref["apply"] describes @racket[apply].}

@defexamples[
(define max-mag
  (lambda nums
    (apply max (map magnitude nums))))

(max 1 -2 0)
(max-mag 1 -2 0)
]

@racket[lambda] 形式还支持必需参数与 @racket[_rest-id] 的组合：

@specform[
(lambda (arg-id ...+ . rest-id)
  body ...+)
]

此形式的结果是一个函数，它至少需要与 @racket[_arg-id] 一样多的参数，同时也接受任意数量的额外参数。

@defexamples[
(define max-mag
  (lambda (num . nums)
    (apply max (map magnitude (cons num nums)))))

(max-mag 1 -2 0)
(max-mag)
]

@racket[_rest-id] 变量有时被称为@deftech{rest 参数}，因为它接受函数参数的"剩余"部分。带有 rest 参数的函数有时被称为@deftech{可变参数}函数，rest 参数中的元素称为可变参数。

@;------------------------------------------------------------------------
@section{Declaring Optional Arguments}

除了仅使用标识符之外，@racket[lambda] 形式中的参数（rest 参数除外）可以用标识符和默认值来指定：

@specform/subs[
(lambda gen-formals
  body ...+)
([gen-formals (arg ...)
              rest-id
              (arg ...+ . rest-id)]
 [arg arg-id
      [arg-id default-expr]])
]{}

形式为 @racket[[arg-id default-expr]] 的参数是可选的。当在应用中未提供该参数时，@racket[_default-expr] 产生默认值。@racket[_default-expr] 可以引用任何前面的 @racket[_arg-id]，并且之后的每个 @racket[_arg-id] 也必须有默认值。

@defexamples[
(define greet
  (lambda (given [surname "Smith"])
    (string-append "Hello, " given " " surname)))

(greet "John")
(greet "John" "Doe")
]

@def+int[
(define greet
  (lambda (given [surname (if (equal? given "John")
                              "Doe"
                              "Smith")])
    (string-append "Hello, " given " " surname)))

(greet "John")
(greet "Adam")
]

@section[#:tag "lambda-keywords"]{Declaring Keyword Arguments}

@racket[lambda] 形式可以声明通过关键字传递的参数，而不是通过位置传递。关键字参数可以与位置参数混合使用，并且两种参数都可以提供默认值表达式：

@guideother{@secref["keyword-args"] introduces function
calls with keywords.}

@specform/subs[
(lambda gen-formals
  body ...+)
([gen-formals (arg ...)
              rest-id
              (arg ...+ . rest-id)]
 [arg arg-id
      [arg-id default-expr]
      (code:line arg-keyword arg-id)
      (code:line arg-keyword [arg-id default-expr])])
]{}

指定为 @racket[(code:line _arg-keyword _arg-id)] 的参数在应用中使用相同的 @racket[_arg-keyword] 来提供。关键字--标识符对在参数列表中的位置对于应用中的参数匹配无关紧要，因为它将通过关键字而非位置来匹配参数值。

@def+int[
(define greet
  (lambda (given #:last surname)
    (string-append "Hello, " given " " surname)))

(greet "John" #:last "Smith")
(greet #:last "Doe" "John")
]

@racket[(code:line _arg-keyword [_arg-id _default-expr])] 参数指定了一个带有默认值的基于关键字的参数。

@defexamples[
#:eval greet-eval
(define greet
  (lambda (#:hi [hi "Hello"] given #:last [surname "Smith"])
    (string-append hi ", " given " " surname)))

(greet "John")
(greet "Karl" #:last "Marx")
(greet "John" #:hi "Howdy")
(greet "Karl" #:last "Marx" #:hi "Guten Tag")
]

@racket[lambda] 形式不直接支持创建接受"rest"关键字的函数。要构造接受所有关键字参数的函数，请使用 @racket[make-keyword-procedure]。提供给 @racket[make-keyword-procedure] 的函数通过前两个（位置）参数中的并行列表接收关键字参数，然后将应用中的所有位置参数作为剩余的位置参数。

@guideother{@secref["apply"] introduces @racket[keyword-apply].}

@defexamples[
#:eval greet-eval
(define (trace-wrap f)
  (make-keyword-procedure
   (lambda (kws kw-args . rest)
     (printf "Called with ~s ~s ~s\n" kws kw-args rest)
     (keyword-apply f kws kw-args rest))))
((trace-wrap greet) "John" #:hi "Howdy")
]

@refdetails["lambda"]{function expressions}

@;------------------------------------------------------------------------
@section[#:tag "case-lambda"]{Arity-Sensitive Functions: @racket[case-lambda]}

@racket[case-lambda] 形式创建一个根据提供的参数数量可以有完全不同行为的函数。case-lambda 表达式具有以下形式

@specform/subs[
(case-lambda
  [formals body ...+]
  ...)
([formals (arg-id ...)
          rest-id
          (arg-id ...+ . rest-id)])
]

其中每个 @racket[[_formals _body ...+]] 类似于 @racket[(lambda _formals _body ...+)]。应用由 @racket[case-lambda] 产生的函数类似于应用与给定参数数量匹配的第一种情况的 @racket[lambda]。

@defexamples[
(define greet
  (case-lambda
    [(name) (string-append "Hello, " name)]
    [(given surname) (string-append "Hello, " given " " surname)]))

(greet "John")
(greet "John" "Smith")
(greet)
]

@racket[case-lambda] 函数不能直接支持可选参数或关键字参数。

@; ----------------------------------------------------------------------

@close-eval[greet-eval]
