#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define def-eval (make-base-eval))

@title[#:tag "define"]{定义：@racket[define]}

基本定义形式为

@specform[(define id expr)]{}

其中 @racket[_id] 绑定到 @racket[_expr] 的结果。

@defexamples[
#:eval def-eval
(define salutation (list-ref '("Hi" "Hello") (random 2)))
salutation
]

@;------------------------------------------------------------------------
@section{函数简写形式}

@racket[define] 形式也支持函数定义的简写：

@specform[(define (id arg ...) body ...+)]{}

这是以下形式的简写：

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

The function shorthand via @racket[define] also supports a
@tech{rest argument} (i.e., a final argument to collect extra
arguments in a list):

@specform[(define (id arg ... . rest-id) body ...+)]{}

这是以下形式的简写：

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
@section{Curried 函数简写形式}

考虑以下 @racket[make-add-suffix] 函数，它接受一个 string 并返回另一个接受 string 的函数：

@def+int[
#:eval def-eval
(define make-add-suffix
  (lambda (s2)
    (lambda (s) (string-append s s2))))
]

虽然不常见，@racket[make-add-suffix] 的结果可以直接调用，例如：

@interaction[
#:eval def-eval
((make-add-suffix "!") "hello")
]

从某种意义上说，@racket[make-add-suffix] 是一个接受两个参数的函数，但它一次接受一个参数。接受部分参数并返回一个函数来消费更多参数的函数有时称为 @defterm{curried function}。

使用 @racket[define] 的函数简写形式，@racket[make-add-suffix] 可以等价地写成

@racketblock[
(define (make-add-suffix s2)
  (lambda (s) (string-append s s2)))
]

这种简写形式反映了函数调用 @racket[(make-add-suffix "!")] 的形状。@racket[define] 进一步支持定义反映嵌套函数调用的 curried 函数的简写形式：

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

@racket[define] 的函数简写形式的完整语法如下：

@specform/subs[(define (head args) body ...+)
               ([head id
                      (head args)]
                [args (code:line arg ...)
                      (code:line arg ... @#,racketparenfont{.} rest-id)])]{}

这种简写形式对定义中的每个 @racket[_head] 都有一个嵌套的 @racket[lambda]，其中最内层的 @racket[_head] 对应最外层的 @racket[lambda]。


@;------------------------------------------------------------------------
@section[#:tag "multiple-values"]{多值与 @racket[define-values]}

Racket 表达式通常产生单个结果，但有些表达式可产生多个结果。例如，
@racket[quotient] 和 @racket[remainder] 各产生单个值，而 @racket[quotient/remainder] 同时产生相同的两个值：

@interaction[
#:eval def-eval
(quotient 13 3)
(remainder 13 3)
(quotient/remainder 13 3)
]

如上所示，@tech{REPL} 在每个单独的行上打印每个结果值。

Multiple-valued functions can be implemented in terms of the
@racket[values] function, which takes any number of values and
returns them as the results:

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

@racket[define-values] 形式同时绑定多个标识符到单个表达式产生的多个结果：

@specform[(define-values (id ...) expr)]{}

@racket[_expr] 产生的结果数量必须与 @racket[_id] 的数量匹配。

@defexamples[
#:eval def-eval
(define-values (given surname) (split-name "Adam Smith"))
given
surname
]

A @racket[define] form (that is not a function shorthand) is
equivalent to a @racket[define-values] form with a single @racket[_id].

@refdetails["define"]{定义}

@;------------------------------------------------------------------------
@section[#:tag "intdefs"]{内部定义}

当语法形式指定 @racket[_body] 时，相应的形式可以是定义或表达式。
@racket[_body] 中的定义称为 @defterm{internal definition}。

@racket[_body] 序列中的表达式和内部定义可以混合，只要最后一个 @racket[_body] 是表达式。

例如，@racket[lambda] 的语法是

@specform[
(lambda gen-formals
  body ...+)
]

因此以下是语法有效的实例：

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

特定 @racket[_body] 序列中的内部定义是相互递归的；即任何定义都可以引用其他任何定义——只要在引用实际求值之前定义已经发生。如果引用过早，将会发生错误。

@defexamples[
(define (weird)
  (define x x)
  x)
(weird)
]

A sequence of internal definitions using just @racket[define] is
easily translated to an equivalent @racket[letrec] form (as introduced
in the next section). However, other definition forms can appear as a
@racket[_body], including @racket[define-values], @racket[struct] (see
@secref["define-struct"]) or @racket[define-syntax] (see
@secref["macros"]).

@refdetails/gory["intdef-body"]{内部定义}

@; ----------------------------------------------------------------------

@close-eval[def-eval]
