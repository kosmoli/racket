#lang scribble/base

@(require "shared.rkt" scribble/eval)

@title{选择正确的构造}

Racket 为相同或相似的目的提供了一系列构造。
尽管 Racket 的设计者并不认为所有事情都只有一种正确的方式，
但为了保持一致性，我们在某些情况下更倾向于使用某些构造，
以提高可读性。

@; -----------------------------------------------------------------------------
@section{注释}

遵循 Lisp 和 Scheme 的传统，我们使用单个分号进行行内注释
（到行尾），使用两个分号开始一行注释。将第二个分号视为
强调一个观点。

@;{This request does not contradict the programs in this
document. They use two semicolons for full-line comments in source but
scribble renders only one.}

经验丰富的 Schemer（不一定是 Racketeer）也使用三个和
四个分号。这被认为是一种礼貌，用于区分文件头
和章节标题。

除了 @litchar{;} 之外，我们还有两种其他注释代码的机制：
 @litchar{#|}...@litchar{|#} 用于块注释，@litchar{#;} 用于注释掉一个表达式。
 @defterm{块注释}适用于那些罕见的需要一次性注释掉整个
 定义和/或表达式块的情况。
 @defterm{表达式注释}——@litchar{#;}——应用于紧随其后的
 S-表达式。这使得它们成为调试的有用工具。它们甚至可以
 以有趣的方式与其他注释组合，例如 @litchar{#;#;}
 将注释掉两个表达式，而仅包含 @litchar{;#;} 的行则为您提供一个
 用于下一行开始的表达式的单字符"切换"。

@;{But on the flip side, many tools don't process them
properly---treating them instead as a @litchar{#} followed by a commented line.
 For example, in DrRacket S-expression comments are ignored when it comes
 to syntax coloring, which makes it easy to miss them. In Emacs, the
 commented text is colored like a comment and treated as text, which makes
 it difficult to edit as code.  The bottom line here is that @litchar{#;}
 comments are useful for debugging, but try to avoid leaving them in
 committed code.  If you really want to use @litchar{#;}, clarify their use with
 a line comment (@litchar{;}).}

下面的截图说明了 @litchar{#;} 的使用以及 DrRacket 和
Emacs（Racket 模式）如何默认着色此类注释。

@nested[#:style 'inset]{
@tabular[ #:sep @hspace[5]
@list[
 @list[
@image[#:scale .29]{dr-sexp-comment.png}
@; -----------------------------------------------------------------------------
@image[#:scale .25]{emacs-sexp-comment.png}
]]]}


@; -----------------------------------------------------------------------------
@section{定义}

Racket 提供了相当多的定义构造，包括
@scheme[let]、@scheme[let*]、@scheme[letrec] 和 @scheme[define]。除了
最后一个之外，定义构造都会增加缩进级别。
因此，在可行的情况下优先使用 @scheme[define]。

@compare0[
@racketmod0[
racket

(define (swap x y)
  (define t (unbox x))
  (set-box! x (unbox y))
  (set-box! y t))
]
@; -----------------------------------------------------------------------------
@racketmod0[
racket

(define (swap x y)
  (let ([t (unbox x)])
    (set-box! x (unbox y))
    (set-box! y t)))
]
]

@bold{警告} @racket[let*] 绑定块不容易替换为一系列
@scheme[define]，因为前者具有 @emph{sequential} 作用域，
而后者具有 @emph{mutually recursive} 作用域。
@compare0[#:left "works" #:right (list "does " @bold{not})
@racketmod0[
racket

(define (print-two f)
  (let* ([_ (print (first f))]
         [f (rest f)]
         [_ (print (first f))]
         [f (rest f)])
    (code:comment2 "IN")
    f))
]
@; -----------------------------------------------------------------------------
@racketmod0[
racket

(define (print-two f)
  (print (first f))
  (define f (rest f))
  (print (first f))
  (define f (rest f))
  (code:comment2 "IN")
  f)
]
]

@; -----------------------------------------------------------------------------
@section{条件表达式}

与定义构造一样，条件表达式也有多种变体。
因为 @scheme[cond] 及其相关形式（@scheme[case]、
@scheme[match] 等）现在允许局部使用 @scheme[define]，所以你应该
优先使用它们而不是 @scheme[if]。

@compare0[
@racketmod0[
racket

(cond
  [(empty? l) #false]
  [else
   (define f (first l))
   (define r (rest l))
   (if (discounted? f)
       (rate f)
       (curved (g r)))])
]
@racketmod0[
racket

(if (empty? l)
    #false
    (let ([f (first l)]
          [r (rest l)])
      (if (discounted? f)
          (rate f)
          (curved (g r)))))
]
]

此外，使用 @racket[cond] 代替 @racket[if] 来消除显式的
 @racket[begin]。

上面"好"的例子使用 @racket[match] 会更好。一般来说，
使用 @racket[match] 来解构复杂的数据。

你还应该优先使用 @scheme[cond]（及其相关形式）而不是 @scheme[if] 来
匹配数据定义的形状。特别是，上面的例子
可以用 @racket[and] 和 @racket[or] 来表述，但这样做不会
像递归那样清晰地表达递归。

@; -----------------------------------------------------------------------------
@section{表达式}

不要将表达式嵌套得太深。相反，为中间结果命名。
通过精心选择的名称，你的表达式变得易于阅读。

@compare0[
@racketmod0[
racket

(define (next-month d)
  (define day (first d))
  (define month (second d))
  (if (= month 12)
      `(,(+ day 1) 1)
      `(,day ,(+ month 1))))
]
@; -----------------------------------------------------------------------------
@racketmod0[
racket

(define (next-month d)
  (if (= (second d) 12)
      `(,(+ (first d) 1)
        1)
      `(,(first d)
        ,(+ (second d) 1))))
]
]
 显然，"太深"是主观的。有时，使表达式不可读的
 不是嵌套本身，而是子表达式的绝对数量。对于这种情况，
 也考虑使用局部定义。

@; -----------------------------------------------------------------------------
@section{结构体与列表}

当你表示少量且固定数量的值的组合时，使用 @racket[struct]。
对于固定长度的（长）列表，添加注释甚至合约来
说明约束条件。

如果一个函数通过 @racket[values] 返回多个结果，当你处理四个或更多值时，
考虑使用 @racket[struct] 或列表。

@; -----------------------------------------------------------------------------
@section{Lambda 与 Define}

虽然没有人否认 @racket[lambda] 很可爱，但 @racket[define]d
函数有名称，可以告诉你它们计算什么，并有助于
加速阅读。

@compare0[
@racketmod0[
racket

(define (process f)
  (define (complex-step x)
    ... 10 lines ...)
  (map complex-step
       (to-list f)))
]
@; -----------------------------------------------------------------------------
@racketmod0[
racket

(define (process f)
  (map (lambda (x)
         ... 10 lines ...)
       (to-list f)))
]
]

甚至柯里化函数也不需要 @racket[lambda]。
@compare0[#:right "acceptable"
@racketmod0[
racket

(define ((cut fx-image) image2)
  ...)
]
@; -----------------------------------------------------------------------------
@racketmod0[
racket

(define (cut fx-image)
  (lambda (image2)
    ...))
]
]
 左侧在函数的第一行就表示柯里化，
而读者必须阅读右侧版本的两行才能理解。

当然，许多构造（例如 @racket[call-with-values]）或高阶函数
（例如 @racket[filter]）是为短 @racket[lambda] 设计的；不要犹豫，
在这种情况下使用 @racket[lambda]。


@; -----------------------------------------------------------------------------
@section{恒等函数}

恒等函数是 @racket[values]：

 @examples[
 (map values '(a b c))
 (values 1 2 3)
 ]

@; -----------------------------------------------------------------------------
@section{遍历}

随着 @racket[for/fold]、@racket[for/list]、
 @racket[for/vector] 及其相关形式的出现，使用 @racket[for] 循环编程
 已经与使用 @racket[map] 和 @racket[foldr] 编程一样具有函数式风格。
 通过 @racket[for*] 循环、过滤器和迭代规范中的终止子句，
 这些循环也比显式的遍历组合子简洁得多。而且通过 @racket[for] 循环，
 你可以将遍历与列表解耦。

@margin-note*{另请参见 Racket 中的 @racket[for/sum] 和 @racket[for/product]。}
@compare0[
@;%
(racketmod0
racket

(code:comment2 #, @elem{[Sequence X] -> Number})
(define (sum-up s)
  (for/fold ([sum 0]) ([x s])
    (+ sum x)))

(code:comment2 #, @elem{examples:})
(sum-up '(1 2 3))
(sum-up #(1 2 3))
(sum-up
  (open-input-string
    "1 2 3")))
@; -----------------------------------------------------------------------------
@;%
(racketmod0
racket

(code:comment2 #, @elem{[Listof X] -> Number})
(define (sum-up alist)
  (foldr (lambda (x sum)
           (+ sum x))
          0
          alist))

(code:comment2 #, @elem{example:})
(sum-up '(1 2 3)))
]
 在这个例子中，左侧的 @racket[for] 循环有两个
 优势。首先，读者不需要理解中间的
 @racket[lambda]。其次，@racket[for] 循环自然地推广到
 其他类型的序列。当然，这里的权衡是效率的损失；
 使用 @racket[in-list] 将 @tt{good} 示例限制为与 @tt{bad} 相同的数据范围
 可以加快前者的速度。

 @bold{注意} @racket[for] 遍历用户定义的序列往往
 很慢。如果这些情况下性能很重要，你可能希望回退到
 自己的遍历函数。

@; -----------------------------------------------------------------------------
@section{函数与宏}

尽可能定义函数。或者，不要在函数可以完成时引入宏。

@compare0[
@racketmod0[
racket
...
(code:comment2 #, @elem{Message -> String})
(define (name msg)
  (first (second msg)))
]
@; -----------------------------------------------------------------------------
(racketmod0
racket
...
(code:comment2 #, @elem{Message -> String})
(define-syntax-rule (name msg)
  (first (second msg))))
]
 函数在上下文中立即可用。对于宏，
 实现相同目标需要更多工作。


@; -----------------------------------------------------------------------------
@section{异常}

处理异常时，尽可能精确地指定异常。

@compare0[
@racketmod0[
racket
...
(code:comment2 #, @t{FN [X -> Y] FN -> Void})
(define (convert in f out)
  (with-handlers
      ([exn:fail:read? X])
    (with-output-to out
      (writer f))))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((writer f))
  (with-input-from in
    (reader f)))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((reader f))
  ... f ...)
]
@; -----------------------------------------------------------------------------
@racketmod0[
racket
...
(code:comment2 #, @t{FN [X -> Y] FN -> Void})
(define (convert in f out)
  (with-handlers
      ([(code:hilite (lambda _ #t)) X])
    (with-output-to out
      (writer f))))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((writer f))
  (with-input-from in
    (reader f)))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((reader f))
  ... f ...)
]
]
 使用 @racket[(lambda _ #t)] 作为异常谓词向读者表明
 你希望捕获每个可能的异常，包括失败
 和 break 异常。更糟糕的是，读者可能认为你根本没有
 考虑过应该捕获哪些异常。

同样糟糕的是使用 @racket[exn?] 作为异常谓词，即使
 你的意思是捕获所有类型的失败。这样做也会捕获 break
 异常。要捕获所有失败，请使用 @racket[exn:fail?]，如左侧所示：
@compare0[
@racketmod0[
racket
...
(code:comment2 #, @t{FN [X -> Y] FN -> Void})
(define (convert in f out)
  (with-handlers
      ([exn:fail? X])
    (with-output-to out
      (writer f))))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((writer f))
  (with-input-from in
    (reader f)))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((reader f))
 ... f ...)
]
@racketmod0[
racket
...
(code:comment2 #, @t{FN [X -> Y] FN -> Void})
(define (convert in f out)
  (with-handlers
      ([(code:hilite exn?) X])
    (with-output-to out
      (writer f))))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((writer f))
  (with-input-from in
    (reader f)))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((reader f))
 ... f ...)
]
]

最后，@racket[exn:fail?] 子句的处理程序永远不应该
对所有可能的失败都成功，因为它会抑制所有类型的
异常，而你很可能希望看到这些异常：
@codebox0[#:label "bad"
@racketmod0[
racket
...
(code:comment2 #, @t{FN [X -> Y] FN -> Void})
(define (convert in f out)
  (with-handlers ([exn:fail? handler])
    (with-output-to out
      (writer f))))

(code:comment2 #, @t{Exn -> Void})
(define (handler e)
  (cond
    [(exn:fail:read? e)
     (displayln "drracket is special")]
    [else (void)]))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((writer f))
  (with-input-from in
    (reader f)))

(code:comment2 #, @t{may raise @racket[exn:fail:read]})
(define ((reader f))
  ... f ...)
]
]
 如果你想处理几种不同类型的失败，比如
 @racket[exn:fail:read?] 和 @racket[exn:fail:network?]，请使用 @racket[with-handlers] 中的不同
 子句来做到这一点，并将条件分支分布到这些
 子句上。

@; -----------------------------------------------------------------------------
@section{参数}

如果需要设置参数，请使用 @racket[parameterize]：

@compare0[
@racketmod0[
racket
...
(define cop
  current-output-port)

(code:comment2 #, @t{String OPort -> Void})
(define (send msg op)
  (parameterize ([cop op])
    (display msg))
  (record msg))
]
@; -----------------------------------------------------------------------------
@racketmod0[
racket
...
(define cop
  current-output-port)

(code:comment2 #, @t{String OPort -> Void})
(define (send msg op)
  (define cp (cop))
  (cop op)
  (display msg)
  (cop cp)
  (record msg))
]
]
 正如比较所展示的，@racket[parameterize] 清楚地界定了
 更改的范围，这对读者来说是一个重要的概念。此外，
 @racket[parameterize] 确保你的代码更可能
 与 continuation 和线程正常工作，这对 Racket
 程序员来说是一个重要的概念。


@; -----------------------------------------------------------------------------
@section{复数形式}

命名集合和库时避免使用复数形式。使用 @racketmodname[racket/contract]
和 @racketmodname[data/heap #:indirect]，而不是 @tt{racket/contracts} 或 @tt{data/heaps}。
