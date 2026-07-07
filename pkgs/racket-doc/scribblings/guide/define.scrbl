#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define def-eval (make-base-eval))

@title[#:tag "define"]{Definitions: @racket[define]}

基本定义具有以下形式

@specform[(define id expr)]{}

在这种情况下，@racket[_id] 绑定到 @racket[_expr] 的结果。

@defexamples[
#:eval def-eval
(define salutation (list-ref '("Hi" "Hello") (random 2)))
salutation
]

@;------------------------------------------------------------------------
@section{Function Shorthand}

@racket[define] 形式还支持函数定义的简写：

@specform[(define (id arg ...) body ...+)]{}

这是以下形式的简写

@racketblock[
(define _id (lambda (_arg ...) _body ...+))
]

@defexamples[
#:eval def-eval
(define (greet name)
  (string-append salutation ", " name))
(greet "John")
]

@def+int[
#:eval def-eval
(define (greet first [surname "Smith"] #:hi [hi salutation])
  (string-append hi ", " first " " surname))
(greet "John")
(greet "John" #:hi "Hey")
(greet "John" "Doe")
]

通过 @racket[define] 的函数简写还支持@tech{rest 参数}（即收集额外参数到列表中的最后一个参数）：

@specform[(define (id arg ... . rest-id) body ...+)]{}

这是以下形式的简写

@racketblock[
(define _id (lambda (_arg ... . _rest-id) _body ...+))
]

@defexamples[
#:eval def-eval
(define (avg . l)
  (/ (apply + l) (length l)))
(avg 1 2 3)
]

@;------------------------------------------------------------------------
@section{Curried Function Shorthand}

考虑以下 @racket[make-add-suffix] 函数，它接受一个字符串并返回另一个接受字符串的函数：

@def+int[
#:eval def-eval
(define make-add-suffix
  (lambda (s2)
    (lambda (s) (string-append s s2))))
]

虽然不常见，但 @racket[make-add-suffix] 的结果可以直接调用，像这样：

@interaction[
#:eval def-eval
((make-add-suffix "!") "hello")
]

在某种意义上，@racket[make-add-suffix] 是一个接受两个参数的函数，但它一次接受一个。一个接受部分参数并返回一个函数来消耗更多参数的函数有时被称为@defterm{柯里化函数}。

使用 @racket[define] 的函数简写形式，@racket[make-add-suffix] 可以等价地写为

@racketblock[
(define (make-add-suffix s2)
  (lambda (s) (string-append s s2)))
]

此简写反映了函数调用 @racket[(make-add-suffix "!")] 的形状。@racket[define] 形式进一步支持定义柯里化函数的简写，反映嵌套的函数调用：

@def+int[
#:eval def-eval
(define ((make-add-suffix s2) s)
  (string-append s s2))
((make-add-suffix "!") "hello")
]
@defs+int[
#:eval def-eval
[(define louder (make-add-suffix "!"))
 (define less-sure (make-add-suffix "?"))]
(less-sure "really")
(louder "really")
]

@racket[define] 的函数简写的完整语法如下：

@specform/subs[(define (head args) body ...+)
               ([head id
                      (head args)]
                [args (code:line arg ...)
                      (code:line arg ... @#,racketparenfont{.} rest-id)])]{}

此简写的展开为定义中的每个 @racket[_head] 生成一个嵌套的 @racket[lambda] 形式，其中最内层的 @racket[_head] 对应最外层的 @racket[lambda]。


@;------------------------------------------------------------------------
@section[#:tag "multiple-values"]{Multiple Values and @racket[define-values]}

Racket 表达式通常产生单个结果，但某些表达式可以产生多个结果。例如，@racket[quotient] 和 @racket[remainder] 各产生一个值，但 @racket[quotient/remainder] 同时产生相同的两个值：

@interaction[
#:eval def-eval
(quotient 13 3)
(remainder 13 3)
(quotient/remainder 13 3)
]

如上所示，@tech{REPL} 将每个结果值打印在单独的行上。

多值函数可以用 @racket[values] 函数来实现，该函数接受任意数量的值并将其作为结果返回：

@interaction[
#:eval def-eval
(values 1 2 3)
]
@def+int[
#:eval def-eval
(define (split-name name)
  (let ([parts (regexp-split " " name)])
    (if (= (length parts) 2)
        (values (list-ref parts 0) (list-ref parts 1))
        (error "not a <first> <last> name"))))
(split-name "Adam Smith")
]

@racket[define-values] 形式将多个标识符同时绑定到单个表达式产生的多个结果：

@specform[(define-values (id ...) expr)]{}

@racket[_expr] 产生的结果数量必须与 @racket[_id] 的数量匹配。

@defexamples[
#:eval def-eval
(define-values (given surname) (split-name "Adam Smith"))
given
surname
]

@racket[define] 形式（非函数简写）等价于只有一个 @racket[_id] 的 @racket[define-values] 形式。

@refdetails["define"]{definitions}

@;------------------------------------------------------------------------
@section[#:tag "intdefs"]{Internal Definitions}

当语法形式的语法指定了 @racket[_body]，则相应的形式可以是定义或表达式。作为 @racket[_body] 的定义是@defterm{内部定义}。

表达式和内部定义可以在 @racket[_body] 序列中混合使用，只要最后一个 @racket[_body] 是表达式。

For example, the syntax of @racket[lambda] is

@specform[
(lambda gen-formals
  body ...+)
]

以下是语法的有效实例：

@racketblock[
(lambda (f)                (code:comment @#,elem{no definitions})
  (printf "running\n")
  (f 0))

(lambda (f)                (code:comment @#,elem{one definition})
  (define (log-it what)
    (printf "~a\n" what))
  (log-it "running")
  (f 0)
  (log-it "done"))

(lambda (f n)              (code:comment @#,elem{two definitions})
  (define (call n)
    (if (zero? n)
        (log-it "done")
        (begin
          (log-it "running")
          (f n)
          (call (- n 1)))))
  (define (log-it what)
    (printf "~a\n" what))
  (call n))
]

特定 @racket[_body] 序列中的内部定义是相互递归的；也就是说，任何定义都可以引用任何其他定义——只要引用不是在其定义生效之前被实际求值。如果定义被过早引用，就会发生错误。

@defexamples[
(define (weird)
  (define x x)
  x)
(weird)
]

仅使用 @racket[define] 的内部定义序列可以很容易地转换为等价的 @racket[letrec] 形式（如下一节所述）。然而，其他定义形式也可以作为 @racket[_body] 出现，包括 @racket[define-values]、@racket[struct]（参见 @secref["define-struct"]）或 @racket[define-syntax]（参见 @secref["macros"]）。

@refdetails/gory["intdef-body"]{internal definitions}

@; ----------------------------------------------------------------------

@close-eval[def-eval]
