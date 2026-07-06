#lang scribble/doc
@(require scribble/manual scribble/eval
          scribble/core racket/list 
          scribble/racket
          "../guide-utils.rkt" "utils.rkt"
          (for-label racket/contract))

@title[#:tag "contract-func"]{函数上的简单契约}

数学函数有 @deftech{domain}（定义域）和 @deftech{range}（值域）。
domain 表示函数接受什么类型的参数，range 表示函数产生什么类型的值。
domain 和 range 的传统表示法为

@racketblock[
f : A -> B
]

其中 @racket[A] 是函数的 domain，@racket[B] 是 range。

编程语言中的函数也有 domain 和 range，contract 可以确保函数只接收
其 domain 中的值并只产生其 range 中的值。@racket[->] 为函数创建这样的
contract。@racket[->] 后面的 form 依次指定 domain 的 contract 和最终的
range 的 contract。

这里是一个可能代表银行账户的 module：

@racketmod[
racket

(provide (contract-out
          [deposit (-> number? any)]
          [balance (-> number?)]))

(define amount 0)
(define (deposit a) (set! amount (+ amount a)))
(define (balance) amount)
]

该 module 导出两个函数： 

@itemize[

@item{@racket[deposit]，接受一个 number 并返回 contract 中未指定类型的值，以及}

@item{@racket[balance]，返回一个 number 表示账户的当前余额。}

]

当 module 导出一个函数时，它在自己（作为 "server"）和导入该函数的\n"client" module 之间建立了两条通信通道。如果 client module 调用该函数，\n它就向 server module 发送值。反之，如果函数调用结束并且函数\n返回值，server module 就向 client module 发送值。client--server 区分\n很重要，因为一旦出错，责任方只能是其中一方。

如果 client module 将 @racket[deposit] 应用于 @racket['millions]，
这违反了 contract。Contract-monitoring 系统会捕获这个违反并 blame client
破坏了与上面模块的 contract。相反，如果 @racket[balance] 函数返回
@racket['broke]，contract-monitoring 系统会 blame server module。

@racket[->] 本身不是 contract；它是 @deftech{contract combinator}，
将其他 contract 组合成一个新的 contract。

@; ------------------------------------------------------------------------

@section{@racket[->] 的风格}

如果你习惯于数学函数，你可能更希望 contract 箭头出现在函数的
domain 和 range 之间，而不是在前面。如果你读过 @|HtDP|，你已经
多次见过这种形式。事实上，你可能在其他人的代码中见过这样的 contract：

@racketblock[
(provide (contract-out
          [deposit (number? . -> . any)]))
]

如果 Racket S-expression 包含两个 dot 且中间有一个 symbol，
该 reader 会重新排列 S-expression，把 symbol 放到前面，
如 @secref["lists-and-syntax"] 所述。因此， 

@racketblock[
(number? . -> . any)
]

只是另一种写法

@racketblock[
(-> number? any)
]

@; ------------------------------------------------------------------------

@section[#:tag "simple-nested"]{使用 @racket[define/contract] 和 @racket[->]}

在 @ctc-link["intro-nested"] 中介绍的 @racket[define/contract] 形式
也可以用于定义带有 contract 的函数。例如，

@racketblock[
(define/contract (deposit amount)
  (-> number? any)
  (code:comment "implementation goes here")
  ....)
]

定义了 @racket[deposit] 函数并附带之前的 contract。
注意这对于 @racket[deposit] 的使用有两个潜在的重要影响：

@itemlist[#:style 'ordered
  @item{contract 会在任何 @racket[deposit] 的调用处被检查，
        包括在其定义 module 内部的调用——只要调用位于定义外部。
        因为 module 内部可能有很多次调用，这种检查可能导致
        contract 被检查过于频繁，从而造成性能下降。
        如果函数在循环中被重复调用，这点尤其突出。}
  @item{在某些情况下，函数可能被设计为在同 module 内其他代码
        调用时接受更宽松的输入集合。对于这种使用场景，
        @racket[define/contract] 建立的 contract 边界过于严格。}
]

@; ----------------------------------------------------------------------
@section{@racket[any] 和 @racket[any/c]}

用于 @racket[deposit] 的 @racket[any] contract 匹配任何类型的结果，
而且只能用于函数 contract 的 range 位置。我们可以用更具体的
@racket[void?] contract 来代替上面的 @racket[any]，它说明函数
始终返回 @racket[(void)] 值。但 @racket[void?] contract 会要求
contract monitoring 系统在每次调用时都检查返回值，即使 "client"
module 无法对该值做多少处理。相比之下，@racket[any] 告诉 monitoring
系统 @italic{不要}检查返回值，它告诉潜在 client 该 "server" module
对函数的返回值 @italic{不做任何承诺}，甚至不承诺是单个值还是多个值。

@racket[any/c] contract 与 @racket[any] 类似，因为都不对值提出
任何要求。不同之处在于，@racket[any/c] 表示单个值，因此适合
用作 argument contract。将 @racket[any/c] 用作 range contract 会
强制检查函数产生单个值。也就是说，

@racketblock[(-> integer? any)]

描述了一个接受 integer 并返回任意数量值的函数，而

@racketblock[(-> integer? any/c)]

描述了一个接受 integer 并产生单一结果的函数（但对结果不再做
更多描述）。函数

@racketblock[
(define (f x) (values (+ x 1) (- x 1)))
]

匹配 @racket[(-> integer? any)]，但不匹配 @racket[(-> integer? any/c)]。

当你需要特别保证函数返回单一结果时使用 @racket[any/c] 作为
result contract。当你想对函数结果做出尽可能少的承诺（并产生尽可能
少的检查）时使用 @racket[any]。

@; ------------------------------------------------------------------------

@ctc-section[#:tag "own"]{自定义 Contract}

@racket[deposit] 函数将给定的数字加到 @racket[amount] 的值上。
虽然函数的 contract 阻止 client 将其应用于非数字，但仍然允许
将其应用于 complex number、negative number 或 inexact number，
它们都不是合理的金额表示。

Contract 系统允许程序员以函数形式定义自己的 contract：

@racketmod[
racket
  
(define (amount? a)
  (and (number? a) (integer? a) (exact? a) (>= a 0)))

(provide (contract-out
          (code:comment "an amount is a natural number of cents")
          (code:comment "is the given number an amount?")
          [deposit (-> amount? any)]
          [amount? (-> any/c boolean?)]
          [balance (-> amount?)]))
  
(define amount 0)
(define (deposit a) (set! amount (+ amount a)))
(define (balance) amount)
]

该 module 定义了一个 @racket[amount?] 函数并将其作为 @racket[->] contract 内的 contract。当 client 调用以 @racket[(-> amount? any)]
contract 导出的 @racket[deposit] 函数时，它必须提供一个 exact 的
nonnegative integer，否则将 @racket[amount?] 函数应用于参数将返回
@racket[#f]，这将导致 contract-monitoring 系统 blame client。
类似地，server module 必须提供 exact 的 nonnegative integer 作为
@racket[balance] 的结果以维持无责状态。

当然，将通信通道限制为 client 不理解的值是没有意义的。因此
该 module 也导出了 @racket[amount?] predicate 本身，附带一个说明它
接受任意值并返回 boolean 的 contract。

在这种情况下，我们也可以用 @racket[natural-number/c] 来代替
@racket[amount?]，因为它表示完全相同的检查：

@racketblock[
(provide (contract-out
          [deposit (-> natural-number/c any)]
          [balance (-> natural-number/c)]))
]

每个接受一个参数的函数都可以被当作 predicate，因此可以作为
contract 使用。然而，要将现有检查组合成新的检查，@racket[and/c]
和 @racket[or/c] 等 contract combinator 通常很有用。例如，
这是编写上述 contract 的另一种方法：

@racketblock[
(define amount/c 
  (and/c number? integer? exact? (or/c positive? zero?)))

(provide (contract-out
          [deposit (-> amount/c any)]
          [balance (-> amount/c)]))
]

其他值也可以兼作 contract。例如，如果函数接受 number 或
@racket[#f]，@racket[(or/c number? #f)] 就足够了。类似地，
@racket[amount/c] contract 也可以用 @racket[0] 来代替
@racket[zero?]。如果你使用 regular expression 作为 contract，
该 contract 接受与该 regular expression 匹配的 string 和 byte
string。

自然，你可以将自己实现的 contract-implementing 函数与
@racket[and/c] 等 combinator 混合使用。这里是一个从
bank 记录创建 string 的 module：

@racketmod[
racket

(define (has-decimal? str)
  (define L (string-length str))
  (and (>= L 3)
       (char=? #\. (string-ref str (- L 3)))))

(provide (contract-out
          (code:comment "convert a random number to a string")
          [format-number (-> number? string?)]

          (code:comment "convert an amount into a string with a decimal")
          (code:comment "point, as in an amount of US currency")
          [format-nat (-> natural-number/c
                          (and/c string? has-decimal?))]))
]
导出函数 @racket[format-number] 的 contract 规定该函数
消费 number 并产生 string。导出函数 @racket[format-nat] 的 contract
比 @racket[format-number] 的更有趣。它只消费 natural number。
它的 range contract 承诺一个从右数第三位有 @litchar{.} 的 string。

如果我们想加强 @racket[format-nat] 的 range contract 的承诺，
使其只接受 digit 和单个 dot 组成的 string，可以这样写：

@racketmod[
racket

(define (digit-char? x) 
  (member x '(#\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9 #\0)))

(define (has-decimal? str)
  (define L (string-length str))
  (and (>= L 3)
       (char=? #\. (string-ref str (- L 3)))))

(define (is-decimal-string? str)
  (define L (string-length str))
  (and (has-decimal? str)
       (andmap digit-char?
               (string->list (substring str 0 (- L 3))))
       (andmap digit-char?
               (string->list (substring str (- L 2) L)))))

....

(provide (contract-out
          ....
          (code:comment "convert an  amount (natural number) of cents")
          (code:comment "into a dollar-based string")
          [format-nat (-> natural-number/c 
                          (and/c string? 
                                 is-decimal-string?))]))
]

另外，在这种情况下，我们可以用 regular expression
作为 contract：

@racketmod[
racket

(provide 
 (contract-out
  ....
  (code:comment "convert an  amount (natural number) of cents")
  (code:comment "into a dollar-based string")
  [format-nat (-> natural-number/c
                  (and/c string? #rx"[0-9]*\\.[0-9][0-9]"))]))
]

@; ------------------------------------------------------------------------

@ctc-section{高阶函数上的 Contract}

函数 contract 不只限于在 domain 或 range 上使用简单的 predicate。
这里讨论的任何 contract combinator，包括函数 contract 本身，
都可以用作函数参数和结果的 contract。

例如，

@racketblock[(-> integer? (-> integer? integer?))]

是描述 curried function 的 contract。它匹配接受一个参数、然后返回
另一个接受第二个参数的函数、最后返回 integer 的函数。如果 server
导出一个带此 contract 的函数 @racket[make-adder]，而 @racket[make-adder]
返回的值不是函数，则 server 被 blame。如果 @racket[make-adder]
确实返回函数，但结果函数的调用参数不是 integer，则 client
被 blame。

类似地，contract

@racketblock[(-> (-> integer? integer?) integer?)]

描述接受其他函数作为输入的函数。如果 server 导出一个带此 contract
的函数 @racket[twice]，而 @racket[twice] 的调用参数不是单参数函数，
则 client 被 blame。如果 @racket[twice] 应用于单参数函数且
@racket[twice] 在 non-integer 值上调用给定函数，则 server 被
blame。

@; ----------------------------------------------------------------------

@ctc-section[#:tag "flat-named-contracts"]{包含 ``???'' 的 Contract 消息}

你编写了自己的 module。你添加了 contract。你将其放入接口，
使得 client programmer 能从接口获得所有信息。这是一件艺术品： 
@interaction[#:eval 
             contract-eval
             (module bank-server racket
               (provide
                (contract-out
                 [deposit (-> (λ (x)
                                (and (number? x) (integer? x) (>= x 0)))
                              any)]))
               
               (define total 0)
               (define (deposit a) (set! total (+ a total))))]

几个 client 使用了你的 module。其他人又使用了他们的 module。
然后突然其中一个看到了这条错误消息：

@interaction[#:eval 
             contract-eval
             (require 'bank-server)
             (deposit -10)]

@racketerror{???} 在那里做什么？如果我们能为这类数据起一个名字，
就像 string、number 等一样，是不是很好？

对于这种情况，Racket 提供 @deftech{flat named contract}。这里
"contract" 一词表明 contract 是 first-class value。"flat" 意味着
数据集合是内置 atomic 数据类的子集；它们通过消费所有
Racket 值并产生 boolean 的 predicate 来描述。"named"
部分表示我们想做的事情：为 contract 命名，使 error 消息变得
可读：

@interaction[#:eval 
             contract-eval
             (module improved-bank-server racket
               (provide
                (contract-out
                 [deposit (-> (flat-named-contract
                               'amount
                               (λ (x)
                                 (and (number? x) (integer? x) (>= x 0))))
                              any)]))

               (define total 0)
               (define (deposit a) (set! total (+ a total))))]

经过这个小改动，error 消息变得相当可读：

@interaction[#:eval 
             contract-eval
             (require 'improved-bank-server)
             (deposit -10)]

@; not sure why, but if I define str directly to be the
@; expression below, then it gets evaluated before the 
@; expressions above it.
@(define str "huh?")

@(begin
   (set! str
         (with-handlers ((exn:fail? exn-message))
           (contract-eval '(deposit -10))))
   "")

@ctc-section[#:tag "dissecting-contract-errors"]{剖析 contract 错误消息}

@(define (lines a b)
   (define lines (regexp-split #rx"\n" str))
   (table (style #f '())
          (map (λ (x) (list (paragraph error-color x)))
               (take (drop lines a) b))))

通常，每个 contract 错误消息包含六个部分：
@itemize[@item{与 contract 关联的函数或方法的名称，以及根据
              contract 是被 client 还是 server 违反的，显示 "contract
              violation" 或 "broke its contract" 短语；例如在上面的
              例子中：@lines[0 1]}
          @item{对 contract 被违反的精确方面的描述，@lines[1 2]}
          @item{完整 contract 及其内部路径，显示违反的具体方面，
               @lines[3 2]}
          @item{contract 所在的 module（或更一般的说，contract 所
               调解的 boundary），@lines[5 1]}
          @item{被 blame 的一方，@lines[6 2]}
          @item{以及 contract 所在源代码位置。@lines[8 1]}]
