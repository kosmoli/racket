#lang scribble/doc
@(require scribble/manual scribble/eval "utils.rkt"
          (for-label racket/base
                     racket/contract))

@title[#:tag "contract-boundaries"]{Contracts and Boundaries}

如同两个商业伙伴之间的合同，软件 contract 是双方之间的协议。该协议为从一方传递到另一方的每个"产品"（或值）指定了义务和保证。

contract 由此在双方之间建立了一个边界。每当一个值跨越此边界时，contract 监控系统就会执行 contract 检查，确保双方遵守已建立的 contract。

基于这一理念，Racket 主要在 module 边界处鼓励使用 contract。具体而言，程序员可以将 contract 附加到 @racket[provide] 子句上，从而对导出值的使用施加约束和承诺。例如，导出声明 
@racketmod[
racket

(provide (contract-out [amount positive?]))

(define amount ...)
]

向上述 module 的所有使用者承诺 @racket[amount] 的值将始终是一个正数。contract 系统会仔细监控 module 的义务。每次使用者引用 @racket[amount] 时，监控器都会检查 @racket[amount] 的值是否确实是一个正数。

contract 库已内置于 Racket 语言中，但如果你希望使用 @racket[racket/base]，可以显式地 require contract 库，如下所示：

@racketmod[
racket/base
(require racket/contract) (code:comment "now we can write contracts")

(provide (contract-out [amount positive?]))

(define amount ...)
]

@ctc-section[#:tag "amount0"]{Contract Violations}

如果我们将 @racket[amount] 绑定到一个非正数，

@racketmod[
racket

(provide (contract-out [amount positive?]))

(define amount 0)]

那么，当 module 被 require 时，监控系统会发出 contract violation 信号，并 blame 该 module 违背了其承诺。

@; @ctc-section[#:tag "qamount"]{A Subtle Contract Violation}

一个更严重的错误是将 @racket[amount] 绑定到一个非数字值：

@racketmod[
racket

(provide (contract-out [amount positive?]))

(define amount 'amount)
]

在这种情况下，监控系统会将 @racket[positive?] 应用于一个 symbol，但 @racket[positive?] 会报告错误，因为它的定义域仅限于数字。为了让 contract 在所有 Racket 值上都能捕获我们的意图，我们可以使用 @racket[and/c] 将两个 contract 组合起来，确保值既是一个数字又是正数：

@racketblock[
(provide (contract-out [amount (and/c number? positive?)]))
]

@;{

==================================================

下面的小节讨论对使用 provide/contract 的变量进行赋值。这目前存在 bug，因此该讨论被省略。以下是 requiring module 的展开形式，仅作示意：

(module m racket
  (require mzlib/contract)
  (provide/contract [x x-ctc]))

(module n racket (require m) (define (f) ... x ...))
==>
(module n racket
  (require (rename m x x-real))
  (define x (apply-contract x-real x-ctc ...))
  (define (f) ... x ...))

其意图是仅对 contract 应用的工作执行一次（每次引用 provide/contract 变量时）。这对 contract 检查器而言是一个显著的实际节省（这一优化的动机来自我在实现某个软件构建项目（大概是 scrabble……）时使用 contract 的经验）

当然，这会破坏对 provided 变量的赋值。

==================================================

<question title="Example" tag="example">

<table src="simple.rkt">
<tr><td bgcolor="e0e0fa">
<racket>
;; Language: Pretty Big
(module a racket
  (require mzlib/contract)

  (provide/contract
   [amount positive?])

  (provide
   ;; -> Void
   ;; effect: sets variable a
   do-it)
  
  (define amount 4)
  
  (define (do-it) <font color="red">(set! amount -4)</font>))

(module b racket 
  (require a)
  
  (printf "~s\n" amount)
  <font color="red">(do-it)</font>
  (printf "~s\n" amount))

(require b)
</racket>
<td bgcolor="beige" valign="top">
<pre>

"server" module 
这使我们能够编写 contract 

带 contract 导出 @racket[amount]


不带 contract 导出 @racket[do-it]



将 amount 设为 4， 
  满足 contract


"client" module 
从 a require 功能

对 @racket[amount] 的第一次引用（正常）
调用 @racket[do-it]， 
对 @racket[amount] 的第二次引用（失败）

</pre> </table>

<p><strong>注意：</strong>上述示例基本上是自解释的。但请注意红色行。即使 @racket[do-it] 的调用将 @racket[amount] 设为 -4，该操作也<strong>不是</strong> contract violation。contract violation 仅在使用者 module（@racket[b]）再次引用 @racket[amount] 且值第二次跨越 module 边界时才会发生。

</question>
}

@ctc-section{Experimenting with Contracts and Modules}

本章中的所有 contract 和 module（紧随其后的除外）均使用描述 module 的标准 @tt{#lang} 语法编写。由于 module 作为 contract 中双方的边界，示例涉及多个 module。

要在单个 module 或 DrRacket 的 @tech{definitions area} 中实验多个 module，请使用 Racket 的子 module。例如，可以这样尝试本节前面的示例：

@racketmod[
racket

(module+ server
  (provide (contract-out [amount (and/c number? positive?)]))
  (define amount 150))
 
(module+ main
  (require (submod ".." server))
  (+ amount 10))
]

每个 module 及其 contract 都被括号包裹，前面是 @racket[module+] 关键字。@racket[module] 之后的第一个形式是 module 的名称，用于后续的 @racket[require] 语句中（通过 @racket[require] 引用时，名称前会加上 @racket[".."] 前缀）。

@ctc-section[#:tag "intro-nested"]{Experimenting with Nested Contract Boundaries}

在许多情况下，在 module 边界处附加 contract 是合理的。然而，能够以比 module 更细粒度地使用 contract 通常更为方便。@racket[define/contract] 形式支持这种用法：

@racketmod[
racket

(define/contract amount
  (and/c number? positive?)
  150)

(+ amount 10)
]

在此示例中，@racket[define/contract] 形式在 @racket[amount] 的定义与其周围上下文之间建立了一个 contract 边界。换句话说，这里的双方是定义本身和包含它的 module。

创建这些 @emph{嵌套 contract 边界} 的形式有时使用起来可能很微妙，因为它们可能产生意外的性能影响，或者 blame 一个看似不太直观的一方。这些微妙之处在 @secref["simple-nested"] 和 @ctc-link["gotcha-nested"] 中有解释。
