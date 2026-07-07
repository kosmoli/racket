#lang scribble/doc
@(require scribble/manual scribble/eval scribble/racket "guide-utils.rkt"
          (for-syntax racket/base))

@(define swap-eval (make-base-eval))

@title[#:tag "pattern-macros"]{Pattern-Based Macros}

@deftech{模式宏}将任何匹配模式的代码替换为使用原始语法中匹配模式部分的
展开式。

@; ----------------------------------------

@section{@racket[define-syntax-rule]}

创建宏的最简单方法是使用
@racket[define-syntax-rule]：

@specform[(define-syntax-rule pattern template)]

作为运行示例，考虑 @racket[swap] 宏，它交换
存储在两个变量中的值。它可以使用
@racket[define-syntax-rule] 实现如下：

@margin-note{该宏在某种意义上"不 Racket"，因为它涉及对
变量的副作用——但宏的目的是让你能够添加其他语言设计者可能不批准的句法形式。}

@racketblock[
(define-syntax-rule (swap x y)
  (let ([tmp x])
    (set! x y)
    (set! y tmp)))
]

@racket[define-syntax-rule] 形式绑定一个匹配单个模式的模式。
模式必须始终以左括号开头，后跟一个标识符，在本例中为 @racket[swap]。在
初始标识符之后，其他标识符是 @deftech{宏模式变量}，可以匹配宏使用中的任何内容。因此，该
宏匹配任何 @racket[_form1] 和 @racket[_form2] 的形式 @racket[(swap _form1 _form2)]。

@margin-note{宏模式变量类似于 @racket[match] 的模式变量。
 参见 @secref["match"]。}

@racket[define-syntax-rule] 中的模式之后是
@deftech{模板}。模板用于替代匹配模式的形式，
只是模板中模式变量的每个实例都被替换为
模式变量匹配的宏使用的部分。例如，在

@racketblock[(swap first last)]

中，模式变量 @racket[x] 匹配 @racket[first]，@racket[y]
匹配 @racket[last]，因此展开式为

@racketblock[
  (let ([tmp first])
    (set! first last)
    (set! last tmp))
]

@; ----------------------------------------

@section{Lexical Scope}

假设我们使用 @racket[swap] 宏来交换名为
@racket[tmp] 和 @racket[other] 的变量：

@racketblock[
(let ([tmp 5]
      [other 6])
  (swap tmp other)
  (list tmp other))
]

上述表达式结果应为 @racketresult[(6 5)]。然而，此 @racket[swap] 的
朴素展开式是

@racketblock[
(let ([tmp 5]
      [other 6])
  (let ([tmp tmp])
    (set! tmp other)
    (set! other tmp))
  (list tmp other))
]

其结果为 @racketresult[(5 6)]。问题在于朴素展开式
混淆了使用 @racket[swap] 的上下文中的 @racket[tmp]
与宏模板中的 @racket[tmp]。

Racket 不会对上述 @racket[swap] 的使用产生朴素展开式。相反，它产生

@racketblock[
(let ([tmp 5]
      [other 6])
  (let ([tmp_1 tmp])
    (set! tmp other)
    (set! other tmp_1))
  (list tmp other))
]

结果正确，为 @racketresult[(6 5)]。类似地，在示例中

@racketblock[
(let ([set! 5]
      [other 6])
  (swap set! other)
  (list set! other))
]

展开式为

@racketblock[
(let ([set!_1 5]
      [other 6])
  (let ([tmp set!_1])
    (set! set!_1 other)
    (set! other tmp))
  (list set!_1 other))
]

因此，本地 @racket[set!] 绑定不会干扰由宏模板引入的赋值。

换句话说，Racket 的模式宏自动维护词法作用域，
因此宏实现者可以像处理函数和函数调用一样推理宏和宏使用中的变量引用。

@; ----------------------------------------

@section{@racket[define-syntax] and @racket[syntax-rules]}

@racket[define-syntax-rule] 形式绑定一个匹配单个模式的模式，
但 Racket 的宏系统支持匹配以相同标识符开头的多个模式的转换器。要编写
这样的宏，程序员必须使用更通用的 @racket[define-syntax] 形式以及
@racket[syntax-rules] 转换器形式：

@specform[#:literals (syntax-rules)
          (define-syntax id
            (syntax-rules (literal-id ...)
              [pattern template]
              ...))]

@margin-note{@racket[define-syntax-rule] 形式本身是一个宏，
 它展开为包含仅有一个模式和模板的 @racket[syntax-rules] 形式的 @racket[define-syntax]。}

例如，假设我们想要一个 @racket[rotate] 宏，它推广了 @racket[swap] 以支持两个或三个标识符，
因此

@racketblock[
(let ([red 1] [green 2] [blue 3])
  (rotate red green)      (code:comment @#,t{交换})
  (rotate red green blue) (code:comment @#,t{向左旋转})
  (list red green blue))
]

会产生 @racketresult[(1 3 2)]。我们可以使用 @racket[syntax-rules] 实现 @racket[rotate]：

@racketblock[
(define-syntax rotate
  (syntax-rules ()
    [(rotate a b) (swap a b)]
    [(rotate a b c) (begin
                     (swap a b)
                     (swap b c))]))
]

表达式 @racket[(rotate red green)] 匹配 @racket[syntax-rules] 形式中的第一个模式，
因此它展开为 @racket[(swap red green)]。表达式 @racket[(rotate red green blue)] 匹配第二个模式，
因此它展开为 @racket[(begin (swap red green) (swap green blue))]。

@; ----------------------------------------

@section{Matching Sequences}

更好的 @racket[rotate] 宏应允许任何数量的标识符，
而不仅仅是两个或三个。要匹配具有任何数量标识符的 @racket[rotate] 使用，
我们需要一种类似 Kleene 星号的模式形式。在 Racket 宏模式中，星号写作
@racket[...]。

要使用 @racket[...] 实现 @racket[rotate]，我们需要一个基本情况来
处理单个标识符，以及一个归纳情况来处理多个标识符：

@racketblock[
(define-syntax rotate
  (syntax-rules ()
    [(rotate a) (void)]
    [(rotate a b c ...) (begin
                          (swap a b)
                          (rotate b c ...))]))
]

当模式变量（如 @racket[c]）在模式中后跟 @racket[...] 时，它
在模板中也必须后跟 @racket[...]。模式变量有效地匹配零个或多个形式的序列，
并且在模板中替换为相同的序列。

目前两个版本的 @racket[rotate] 都略显低效，因为
成对交换不断将值从第一个变量移动到序列中每个变量，直到到达最后一个。更高效的 @racket[rotate] 会将第一个值直接移动到最后一个变量。我们可以使用 @racket[...] 模式，通过一个辅助宏来实现更高效的变体：

@racketblock[
(define-syntax rotate
  (syntax-rules ()
    [(rotate a c ...)
     (shift-to (c ... a) (a c ...))]))

(define-syntax shift-to
  (syntax-rules ()
    [(shift-to (from0 from ...) (to0 to ...))
     (let ([tmp from0])
       (set! to from) ...
       (set! to0 tmp))]))
]

在 @racket[shift-to] 宏中，模板中的 @racket[...] 跟随
@racket[(set! to from)]，这导致 @racket[(set! to from)]
表达式根据需要被复制多次，以使用 @racket[to] 和 @racket[from]
序列中匹配的每个标识符。（@racket[to] 和 @racket[from] 匹配的数量必须
相同，否则宏展开报错。）

@; ----------------------------------------

@section{Identifier Macros}

根据我们上面的宏定义，@racket[swap] 或 @racket[rotate] 标识符必须在
左括号后使用，否则会报语法错误：

@interaction-eval[#:eval swap-eval (define-syntax swap (syntax-rules ()))]

@interaction[#:eval swap-eval (+ swap 3)]

@deftech{标识符宏}是一种在不带括号独立使用时也能工作的模式匹配宏。例如，我们可以将 @racket[val] 定义为一个展开为 @racket[(get-val)] 的标识符宏，因此 @racket[(+ val 3)] 将展开为 @racket[(+ (get-val) 3)]。

@interaction-eval[#:eval swap-eval (require (for-syntax racket/base))]
@(define-syntax (with-syntax-as-syntax stx)
   (syntax-case stx ()
     [(_ e)
      (with-syntax ([s (datum->syntax #'e 'syntax)])
        #'(let-syntax ([s (make-element-id-transformer
                           (lambda (stx)
                             #'@racket[syntax]))]) ;print as syntax not #'
            e))]))

@(with-syntax-as-syntax
  @interaction[#:eval swap-eval
               (define-syntax val
                 (lambda (stx)
                   (syntax-case stx ()
                     [val (identifier? (syntax val)) (syntax (get-val))])))
               (define-values (get-val put-val!)
                 (let ([private-val 0])
                   (values (lambda () private-val)
                           (lambda (v) (set! private-val v)))))
               val
               (+ val 3)])

@racket[val] 宏使用 @racket[syntax-case]，它允许定义更强大
的宏，这将在 @secref["syntax-case"] 部分中解释。
目前，了解以下内容就足够了：要定义宏，@racket[syntax-case] 在 @racket[lambda] 中使用，
其模板必须用显式的 @racket[syntax] 构造器包装。
最后，@racket[syntax-case] 子句可以在模式后指定额外的保护条件。

我们的 @racket[val] 宏使用 @racket[identifier?] 条件来确保
@racket[val] @emph{必须不}带括号使用。否则，宏会报语法错误：

@interaction[#:eval swap-eval
             (val)]

@; ----------------------------------------

@section{@racket[set!] Transformers}

通过上面的 @racket[val] 宏，我们仍然必须调用 @racket[put-val!] 来
存储的值。然而，直接在 @racket[val] 上使用 @racket[set!] 会更方便
要在 @racket[val] 与 @racket[set!] 一起使用时调用宏，我们使用 @racket[make-set!-transformer] 创建一个
@tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{赋值转换器}。
我们还必须在 @racket[syntax-case] 文字列表中声明 @racket[set!]。

@(with-syntax-as-syntax
  @interaction[#:eval swap-eval
               (define-syntax val2
                 (make-set!-transformer
                  (lambda (stx)
                    (syntax-case stx (set!)
                      [val2 (identifier? (syntax val2)) (syntax (get-val))]
                      [(set! val2 e) (syntax (put-val! e))]))))
               val2
               (+ val2 3)
               (set! val2 10)
               val2])


@; ----------------------------------------

@section{Macro-Generating Macros}

假设我们有许多像 @racket[val] 和 @racket[val2] 这样的标识符，我们希望将其重定向到
访问器和可变函数如
@racket[get-val] 和 @racket[put-val!]。我们希望能够只写：

@racketblock[
(define-get/put-id val get-val put-val!)
]

当然，我们可以将 @racket[define-get/put-id] 实现为宏：

@(with-syntax-as-syntax
  @interaction[#:eval swap-eval
 (define-syntax-rule (define-get/put-id id get put!)
   (define-syntax id
     (make-set!-transformer
      (lambda (stx)
        (syntax-case stx (set!)
          [id (identifier? (syntax id)) (syntax (get))]
          [(set! id e) (syntax (put! e))])))))
 (define-get/put-id val3 get-val put-val!)
 (set! val3 11)
 val3])

@racket[define-get/put-id] 宏是一个 @deftech{生成宏的宏}。

@; ----------------------------------------

@section[#:tag "pattern-macro-example"]{Extended Example: Call-by-Reference Functions}

我们可以使用模式匹配宏来向 Racket 添加一种形式，用于定义一阶 @deftech{按引用传递} 函数。当按引用传递的函数体修改其形式参数时，该修改将应用到调用函数时作为实际参数提供的变量。

例如，如果 @racket[define-cbr] 类似于 @racket[define]，
除了它定义一个按引用传递的函数，那么

@racketblock[
(define-cbr (f a b)
  (swap a b))

(let ([x 1] [y 2])
  (f x y)
  (list x y))
]

会产生 @racketresult[(2 1)]。

我们将通过让函数调用为参数提供访问器和可变函数，而不是直接提供参数值，来实现按引用传递的函数。特别是，对于上面的函数 @racket[f]，我们将生成

@racketblock[
(define (do-f get-a get-b put-a! put-b!)
  (define-get/put-id a get-a put-a!)
  (define-get/put-id b get-b put-b!)
  (swap a b))
]

并将函数调用 @racket[(f x y)] 重定向为

@racketblock[
(do-f (lambda () x)
      (lambda () y)
      (lambda (v) (set! x v))
      (lambda (v) (set! y v)))
]

那么，@racket[define-cbr] 显然是一个生成宏的宏，它
将 @racket[f] 绑定到一个宏，该宏展开为对 @racket[do-f] 的调用。
也就是说，@racket[(define-cbr (f a b) (swap a b))] 需要生成定义

@racketblock[
(define-syntax f
  (syntax-rules ()
    [(id actual ...)
     (do-f (lambda () actual)
           ...
           (lambda (v)
             (set! actual v))
           ...)]))
]

同时，@racket[define-cbr] 需要使用 @racket[f] 的函数体来定义 @racket[do-f]，
第二部分略为复杂，因此我们将大部分工作推迟到一个 @racket[define-for-cbr] 辅助模块，
这使我们能够相当容易地编写 @racket[define-cbr]：


@racketblock[
(define-syntax-rule (define-cbr (id arg ...) body)
  (begin
    (define-syntax id
      (syntax-rules ()
        [(id actual (... ...))
         (do-f (lambda () actual) 
               (... ...)
               (lambda (v) 
                 (set! actual v))
               (... ...))]))
    (define-for-cbr do-f (arg ...)
      () (code:comment @#,t{如下所述...})
      body)))
]

我们剩下的任务是定义 @racket[define-for-cbr]，使其将

@racketblock[
(define-for-cbr do-f (a b) () (swap a b))
]

转换为上面的函数定义 @racket[do-f]。大部分工作是为每个参数
（@racket[a] 和 @racket[b]）生成一个 @racket[define-get/put-id] 声明，并将它们放在函数体之前。通常，这是 @racket[...] 在模式中的简单任务，
但这次有个难点：我们需要合成名称 @racket[get-a] 和 @racket[put-a!]，
以及 @racket[get-b] 和 @racket[put-b!]，而模式语言无法基于现有标识符合成标识符。

事实证明，词法作用域为我们提供了绕过这个问题的方法。
技巧是为函数的每个参数迭代展开 @racket[define-for-cbr]，
这就是为什么 @racket[define-for-cbr] 在参数列表后以一个无用的 @racket[()] 开始。
我们需要跟踪到目前为止看到的所有参数以及为每个参数生成的 @racket[get] 和 @racket[put] 名称，
以及要处理的剩余参数。在我们处理了所有标识符之后，我们就有了一个所需的名称。

以下是 @racket[define-for-cbr] 的定义：

@racketblock[
(define-syntax define-for-cbr
  (syntax-rules ()
    [(define-for-cbr do-f (id0 id ...)
       (gens ...) body)
     (define-for-cbr do-f (id ...) 
       (gens ... (id0 get put)) body)]
    [(define-for-cbr do-f ()
       ((id get put) ...) body)
     (define (do-f get ... put ...)
       (define-get/put-id id get put) ...
      body)]))
]

逐步地，展开过程如下：

@racketblock[
(define-for-cbr do-f (a b)
  () (swap a b))
(unsyntax @tt{=>}) (define-for-cbr do-f (b)
     ([a get_1 put_1]) (swap a b))
(unsyntax @tt{=>}) (define-for-cbr do-f ()
     ([a get_1 put_1] [b get_2 put_2]) (swap a b))
(unsyntax @tt{=>}) (define (do-f get_1 get_2 put_1 put_2)
     (define-get/put-id a get_1 put_1)
     (define-get/put-id b get_2 put_2)
     (swap a b))
]

@racket[get_1]、@racket[get_2]、
@racket[put_1] 和 @racket[put_2] 上的"下标"是由宏展开器插入的，
以保持词法作用域，因为每次 @racket[define-for-cbr] 迭代生成的 @racket[get]
不应绑定另一次迭代生成的 @racket[get]。换句话说，
我们本质上是在欺骗宏展开器为我们生成新名称，
但该技术展示了具有自动词法作用域的模式宏的惊人力量。

最后一个表达式最终展开为

@racketblock[
(define (do-f get_1 get_2 put_1 put_2)
  (let ([tmp (get_1)])
    (put_1 (get_2))
    (put_2 tmp)))
]

它实现了按名称调用函数 @racket[f]。

总结一下，我们可以用三个小型模式宏向 Racket 添加按引用传递函数：
@racket[define-cbr]、@racket[define-for-cbr] 和
@racket[define-get/put-id]。

@; -----------------------------------------------------------------

@close-eval[swap-eval]
