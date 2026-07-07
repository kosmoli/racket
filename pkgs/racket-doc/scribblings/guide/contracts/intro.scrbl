#lang scribble/doc
@(require scribble/manual scribble/eval "utils.rkt"
          (for-label racket/base
                     racket/contract))

@title[#:tag "contract-boundaries"]{Contracts and Boundaries}

就像两个商业伙伴之间的合同一样，软件 contract 是双方之间的协议。该协议为从一方传递到另一方的每个"产品"（或值）规定了义务和保证。

Contract 因此在双方之间建立了一个边界。每当一个值跨越这个边界时，contract 监控系统就会执行 contract 检查，确保双方遵守既定的 contract。

本着这种精神，Racket 主张在模块边界处使用 contract。具体来说，程序员可以将 contract 附加到
@racket[provide] 子句上，从而对导出值的使用施加约束和承诺。例如，导出规范
@racketmod[
racket

(provide (contract-out [amount positive?]))

(define amount ...)
]

向上述模块的所有客户端承诺，@racket[amount] 的值将始终是一个正数。contract 系统会仔细监控模块的义务。每次客户端引用 @racket[amount] 时，监控器都会检查 @racket[amount] 的值是否确实是一个正数。

Contract 库内置于 Racket 语言中，但如果你希望使用 @racket[racket/base]，可以像这样显式地 require contract 库：

@racketmod[
racket/base
(require racket/contract) (code:comment "现在可以编写合约了")

(provide (contract-out [amount positive?]))

(define amount ...)
]

@ctc-section[#:tag "amount0"]{Contract Violation}

如果我们将 @racket[amount] 绑定到一个非正数，

@racketmod[
racket

(provide (contract-out [amount positive?]))

(define amount 0)]

那么当模块被 require 时，监控系统会发出 contract 违规信号，并指责模块违反了其承诺。

@; @ctc-section[#:tag "qamount"]{一个微妙的 Contract Violation}

一个更大的错误是将 @racket[amount] 绑定到一个非数字值：

@racketmod[
racket

(provide (contract-out [amount positive?]))

(define amount 'amount)
]

在这种情况下，监控系统会将 @racket[positive?] 应用于一个 symbol，但 @racket[positive?] 会报告错误，因为它的定义域仅限于数字。为了让 contract 对所有 Racket 值都能正确表达我们的意图，我们可以确保值既是数字又是正数，使用 @racket[and/c] 组合两个 contract：

@racketblock[
(provide (contract-out [amount (and/c number? positive?)]))
]

@; @;{

==================================================

The section below discusses assigning to variables that are
provide/contract'd. This is currently buggy so this
discussion is elided. Here's the expansion of
the requiring module, just to give an idea:

(module m racket
  (require mzlib/contract)
  (provide/contract [x x-ctc]))

(module n racket (require m) (define (f) ... x ...))
==>
(module n racket
  (require (rename m x x-real))
  (define x (apply-contract x-real x-ctc ...))
  (define (f) ... x ...))

The intention is to only do the work of applying the
contract once (per variable reference to a
provide/contract'd variable). This is a significant
practical savings for the contract checker (this
optimization is motivated by my use of contracts while I was
implementing one of the software construction projects
(scrabble, I think ...))

Of course, this breaks assignment to the provided variable.

==================================================

<question title="Example" tag="example">

<table src="simple.example">
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

the "server" module 
this allows us to write contracts 

export @racket[amount] with a contract 


export @racket[do-it] without contract 



set amount to 4, 
  which satisfies contract


the "client" module 
requires functionality from a


first reference to @racket[amount] (okay)
a call to @racket[do-it], 
second reference to @racket[amount] (fail)

</pre> </table>

<p><strong>注意：</strong>上面的例子基本上是不言自明的。然而，请看红色的几行。即使对 @racket[do-it] 的调用将 @racket[amount] 设置为 -4，这个动作<strong>不是</strong> contract violation。contract violation 仅在客户端模块（@racket[b]）再次引用 @racket[amount] 并且值第二次流经模块边界时才会发生。

</question>
@;}

@ctc-section{在模块中使用 Contract}

本章中的所有 contract 和模块（不包括紧随其后的内容）都使用标准的 @tt{#lang} 语法来描述模块。由于模块是 contract 中各方之间的边界，示例涉及多个模块。

要在单个模块内或 DrRacket 的 @tech{definitions area} 中试验多个模块，请使用 Racket 的子模块。例如，像这样尝试本节前面的示例：

@racketmod[
racket

(module+ server
  (provide (contract-out [amount (and/c number? positive?)]))
  (define amount 150))
 
(module+ main
  (require (submod ".." server))
  (+ amount 10))
]

每个模块及其 contract 都用括号括起来，前面是 @racket[module+] 关键字。@racket[module] 之后的第一个形式是要在后续 @racket[require] 语句中使用的模块名称（其中通过 @racket[require] 的每个引用都以 @racket[".."] 为前缀）。

@ctc-section[#:tag "intro-nested"]{使用嵌套 Contract 边界}

在许多情况下，在模块边界处附加 contract 是合理的。然而，通常希望能够以比模块更细的粒度使用 contract。@racket[define/contract] 形式支持这种用法：

@racketmod[
racket

(define/contract amount
  (and/c number? positive?)
  150)

(+ amount 10)
]

在此示例中，@racket[define/contract] 形式在 @racket[amount] 的定义与其周围上下文之间建立了一个 contract 边界。换句话说，这里的双方是定义和包含它的模块。

创建这些@emph{嵌套 contract 边界}的形式有时使用起来可能很微妙，因为它们可能具有意想不到的性能影响或指责一个看起来不直观的一方。这些微妙之处在 @secref["simple-nested"] 和 @ctc-link["gotcha-nested"] 中有解释。
