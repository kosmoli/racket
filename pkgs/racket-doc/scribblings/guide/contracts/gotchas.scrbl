#lang scribble/doc
@(require scribble/manual scribble/eval racket/sandbox
          "utils.rkt"
          (for-label racket/base racket/contract))

@title[#:tag "contracts-gotchas"]{陷阱与注意事项}

@ctc-section{Contracts 与 @racket[eq?]}

通常来说，给一个程序添加 contract 应该要么不改变程序的行为，要么引发 contract violation。Racket 的 contract 几乎满足这一原则，但有一个例外：@racket[eq?]。

@racket[eq?] 过程被设计为速度快，除了保证返回 true 意味着两个值在所有方面行为完全一致之外，没有提供太多保证。在内部，它在低层实现为指针相等，因此会暴露 Racket 实现方式（以及 contract 实现方式）的信息。

Contract 与 @racket[eq?] 交互不佳，因为 function contract 的检查在内部是通过 wrapper function 实现的。例如，考虑以下模块：
@racketmod[
racket

(define (make-adder x)
  (if (= 1 x)
      add1
      (lambda (y) (+ x y))))
(provide (contract-out 
          [make-adder (-> number? (-> number? number?))]))
]

该模块导出了 @racket[make-adder] function，这是常规的柯里化加法 function，但当输入为 @racket[1] 时返回 Racket 的 @racket[add1]。

你可能会以为
@racketblock[
(eq? (make-adder 1)
     (make-adder 1))
]

会返回 @racket[#t]，但不会。如果 contract 改为 @racket[any/c]（甚至是 @racket[(-> number? any/c)]），那么 @racket[eq?] 调用就会返回 @racket[#t]。

总结：不要对带有 contract 的值使用 @racket[eq?]。

@ctc-section[#:tag "gotcha-nested"]{Contract 边界与 @racket[define/contract]}

@racket[define/contract] 建立的 contract 边界（创建嵌套的 contract 边界）有时不符合直觉。当多个 function 或其他带有 contract 的值交互时尤其如此。例如，考虑下面这两个交互的 function：

@(define e2 (make-base-eval))
@(interaction-eval #:eval e2 (require racket/contract))
@interaction[#:eval e2
(define/contract (f x)
  (-> integer? integer?)
  x)
(define/contract (g)
  (-> string?)
  (f "not an integer"))
(g)
]

你可能会以为 @racket[g] function 会因为违反与 @racket[f] 的 contract 而被 blame。如果 @racket[f] 和 @racket[g] 直接建立 contract，blame @racket[g] 是正确的。但它们并没有。相反，@racket[f] 和 @racket[g] 之间的访问是通过外层模块的顶层来调解的。

更准确地说，@racket[f] 和模块顶层有 @racket[(-> integer? integer?)] contract 调解它们的交互；@racket[g] 和顶层有 @racket[(-> string?)] 调解，但 @racket[f] 和 @racket[g] 之间没有直接的 contract。这意味着 @racket[g] 的 body 中对 @racket[f] 的引用实际上是模块顶层的责任，而不是 @racket[g] 的。换句话说，function @racket[f] 是在 @racket[g] 与顶层之间没有 contract 的情况下被交给 @racket[g] 的，因此 blame 会被归于顶层。

如果我们想在 @racket[g] 和顶层之间添加 contract，可以使用 @racket[define/contract] 的 @racket[#:freevar] 声明，就能看到预期的 blame：

@interaction[#:eval e2
(define/contract (f x)
  (-> integer? integer?)
  x)
(define/contract (g)
  (-> string?)
  #:freevar f (-> integer? integer?)
  (f "not an integer"))
(g)
]
@(close-eval e2)

总结：如果带有 contract 的两个值应当交互，将它们放在单独的模块中并在模块边界处设置 contract，或者使用 @racket[#:freevar]。

@ctc-section[#:tag "exists-gotcha"]{Exists Contract 与谓词}

与上面 @racket[eq?] 的例子类似，@racket[#:∃] contract 可以改变程序的行为。

具体来说，@racket[null?] 谓词（以及许多其他谓词）对于 @racket[#:∃] contract 返回 @racket[#f]，而如果将这些 contract 之一改为 @racket[any/c]，则 @racket[null?] 可能改为返回 @racket[#t]，根据这个布尔值在程序中的流向，可能导致任意不同的行为。

总结：不要在 @racket[#:∃] contract 上使用谓词。

@ctc-section{定义递归 Contract}

当定义自引用的 contract 时，自然会想到使用 @racket[define]。例如，有人可能会尝试这样写一个 stream 上的 contract：

@(define e (make-base-eval))
@(interaction-eval #:eval e (require racket/contract))
@interaction[
  #:eval e
(define stream/c
  (promise/c
   (or/c null?
         (cons/c number? stream/c))))
]
@close-eval[e]

不幸的是，这样做不行，因为 @racket[stream/c] 的值在它定义之前就被需要了。换句话说，所有的 combinator 都会急切求值它们的参数，尽管它们接受的值不会这样做。

改为使用
@racketblock[
(define stream/c
  (promise/c
   (or/c
    null?
    (cons/c number? (recursive-contract stream/c)))))
]

使用 @racket[recursive-contract] 会延迟对 @racket[stream/c] identifier 的求值，直到 contract 被首次检查之后，这已足够确保 @racket[stream/c] 已被定义。

另见 @ctc-link["lazy-contracts"]。

@ctc-section{混合使用 @racket[set!] 与 @racket[contract-out]}

contract 库假设通过 @racket[contract-out] 导出的变量不会被赋值，但并未强制保证这一点。因此，如果你试图对这些变量使用 @racket[set!]，可能会感到意外。例如，考虑以下示例：

@interaction[
(module server racket
  (define (inc-x!) (set! x (+ x 1)))
  (define x 0)
  (provide (contract-out [inc-x! (-> void?)]
                         [x integer?])))

(module client racket
  (require 'server)

  (define (print-latest) (printf "x is ~s\n" x))

  (print-latest)
  (inc-x!)
  (print-latest))

(require 'client)
]

两次对 @racket[print-latest] 的调用都打印 @racket[0]，尽管 @racket[x] 的值已增加（且变化在模块 @racket[x] 内部可见）。

作为变通方法，导出 accessor function，而不是直接导出变量，像这样：

@racketmod[
racket

(define (get-x) x)
(define (inc-x!) (set! x (+ x 1)))
(define x 0)
(provide (contract-out [inc-x! (-> void?)]
                       [get-x (-> integer?)]))
]

总结：这是一个 bug，我们将在未来版本中修复。
