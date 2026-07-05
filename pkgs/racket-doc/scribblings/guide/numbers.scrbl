#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "numbers"]{数值}

一个 Racket @deftech{number}（数值）要么是精确的，要么是不精确的：

@itemize[

 @item{一个 @defterm{exact}（精确）数值是以下之一：

       @itemize[

       @item{一个任意大或小的整数，例如 @racket[5]、
             @racket[99999999999999999] 或 @racket[-17]；}

       @item{一个有理数，恰好是两个任意小或大整数的比，例如 @racket[1/2]、
             @racket[99999999999999999/2] 或 @racket[-3/4]；或}

       @item{一个实部和虚部均为精确数（虚部不为零）的复数，
             例如 @racket[1+2i] 或 @racket[1/2+3/4i]。}

       ]}

 @item{一个 @defterm{inexact}（不精确）数值是以下之一：

       @itemize[

        @item{一个数值的 IEEE 浮点表示，例如 @racket[2.0] 或 @racket[3.14e87]，
              其中 IEEE 无穷大和非数值写作
              @racket[+inf.0]、@racket[-inf.0] 和 @racket[+nan.0]
              （或 @racketvalfont{-nan.0}）；或}

        @item{一个实部和虚部均为 IEEE 浮点表示的复数，例如
              @racket[2.0+3.0i] 或 @racket[-inf.0+nan.0i]；作为特殊情况，
              不精确复数可以具有精确为零的实部以及不精确的虚部。}

        ]}
]

不精确数值打印时带有小数点或指数标记，而精确数值打印为整数和分数。
同样的约定适用于读取数值常量，但可以使用 @litchar{#e} 或 @litchar{#i}
前缀强制将其解析为精确或不精确数值。@litchar{#b}、@litchar{#o} 和 @litchar{#x}
前缀分别指定数字的二进制、八进制和十六进制解释。

@refdetails/gory["parse-number"]{数值语法}

@examples[
0.5
(eval:alts @#,racketvalfont{#e0.5} 1/2)
(eval:alts @#,racketvalfont{#x03BB} #x03BB)
]

涉及不精确数值的计算产生不精确结果，因此不精确性对数值起到类似"污染"的作用。
但需注意，Racket 不提供"不精确布尔值"，因此基于不精确数值比较的
分支计算仍可能产生精确结果。@racket[exact->inexact] 和
@racket[inexact->exact] 过程在两种数值类型之间进行转换。

@examples[
(/ 1 2)
(/ 1 2.0)
(if (= 3.0 2.999) 1 2)
(inexact->exact 0.1)
]

即使结果应为精确数值，当精确结果需要表示非有理实数时，@racket[sqrt]、
@racket[log] 和 @racket[sin] 等过程也产生不精确结果。Racket 只能表示
有理数和有理部分的复数。

@examples[
(code:line (sin 0)   (code:comment @#,t{有理...}))
(code:line (sin 1/2) (code:comment @#,t{非有理...}))
]

就性能而言，对小整数的计算通常是最快的，其中"小"表示数字能放入机器
有符号数值的 word-sized representation 少一位的空间中。对于非常大的精确整数
或非整数精确数的计算，可能比不精确数的计算慢得多。

@def+int[
(define (sigma f a b)
  (if (= a b)
      0
      (+ (f a) (sigma f (+ a 1) b))))

(time (round (sigma (lambda (x) (/ 1 x)) 1 2000)))
(time (round (sigma (lambda (x) (/ 1.0 x)) 1 2000)))
]

数值类别 @deftech{integer}（整数）、@deftech{rational}（有理数）、
@deftech{real}（实数，始终为有理数）和 @deftech{complex}（复数）
按常规定义，并由过程 @racket[integer?]、@racket[rational?]、@racket[real?]
和 @racket[complex?] 识别，此外还有一般的 @racket[number?]。
少数数学过程只接受实数，但大多数过程实现了对复数的标准扩展。

@examples[
(integer? 5)
(complex? 5)
(integer? 5.0)
(integer? 1+2i)
(complex? 1+2i)
(complex? 1.0+2.0i)
(abs -5)
(abs -5+2i)
(sin -5+2i)
]

@racket[=] 过程比较数值是否数值相等。如果同时给定不精确和精确数值进行比较，
它会在比较前本质上将不精确数值转换为精确值。相比之下，@racket[eqv?]
（因此也包括 @racket[equal?]）过程在比较数值时同时考虑精确性和数值相等性。

@examples[
(= 1 1.0)
(eqv? 1 1.0)
]

请注意涉及不精确数值的比较，它们本质上可能有令人惊讶的行为。
即使看似简单的不精确数值也可能不表示你所以为的含义；例如，
虽然二进制 IEEE 浮点数可以精确表示 @racket[1/2]，它只能近似表示 @racket[1/10]：

@examples[
(= 1/2 0.5)
(= 1/10 0.1)
(inexact->exact 0.1)
]

@refdetails["numbers"]{数值和数值过程}
