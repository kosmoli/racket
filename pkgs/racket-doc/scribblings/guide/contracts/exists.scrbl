#lang scribble/doc
@(require scribble/manual scribble/eval "utils.rkt"
          (for-label racket/contract))

@title[#:tag "contracts-exists"]{使用 @racket[#:exists] 和 @racket[#:∃] 的抽象契约}

契约系统提供了存在契约，可用于保护抽象，
确保你模块的客户端无法依赖你数据结构表示的具体选择。

@; @ctc-section{Getting Started, with a Queue Example}

@margin-note{
  如果你不方便输入 unicode 字符，可以用 @racket[#:exists] 代替 @racket[#:∃]；
  在 DrRacket 中，输入 @litchar{\exists} 后按 alt-\ 或 control-\（取决于
  你的平台）可生成 @racket[∃]。}
@racket[contract-out] 形式允许你写
@racketblock[#:∃ _name-of-a-new-contract] 作为其一个子句。该声明
引入变量 @racket[_name-of-a-new-contract]，将其绑定到一个新的契约，
该契约隐藏其所保护值的信息。

例如，考虑这个简单的队列数据结构实现：
@racketmod[racket
           (define empty '())
           (define (enq top queue) (append queue (list top)))
           (define (next queue) (car queue))
           (define (deq queue) (cdr queue))
           (define (empty? queue) (null? queue))
           
           (provide
            (contract-out
             [empty (listof integer?)]
             [enq (-> integer? (listof integer?) (listof integer?))]
             [next (-> (listof integer?) integer?)]
             [deq (-> (listof integer?) (listof integer?))]
             [empty? (-> (listof integer?) boolean?)]))]
这段代码完全用列表实现队列，意味着该数据结构的客户端可能直接对数据结构使用 @racket[car] 和 @racket[cdr]
（也许是无意的），因此任何表示上的更改（例如改为支持均摊常数时间入队和出队操作的高效表示）都可能破坏客户端代码。

为确保队列表示是抽象的，可以在 @racket[contract-out] 表达式中使用 @racket[#:∃]，如下所示：
@racketblock[(provide
              (contract-out
               #:∃ queue
               [empty queue]
               [enq (-> integer? queue queue)]
               [next (-> queue integer?)]
               [deq (-> queue queue)]
               [empty? (-> queue boolean?)]))]

现在，如果数据结构的客户端尝试使用 @racket[car] 和 @racket[cdr]，
它们将收到错误，而不是随意操作队列的内部结构。

参见 @ctc-link["exists-gotcha"]。
