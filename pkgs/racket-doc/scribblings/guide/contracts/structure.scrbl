#lang scribble/doc
@(require scribble/manual scribble/eval "../guide-utils.rkt" "utils.rkt"
          (for-label racket/contract))

@title[#:tag "contracts-struct"]{Contracts on Structures}

模块以两种方式处理结构。首先，它们导出
@racket[struct] 定义，即创建某种类型的 struct、访问其字段、修改字段，以及将该类型的 struct 与世界上所有其他类型的值区分开来的能力。其次，有时模块会导出一个特定的 struct，并承诺其字段包含某种类型的值。本节解释如何为这两种用途用契约保护 struct。

@; ----------------------------------------------------------------------
@ctc-section[#:tag "single-struct"]{对特定值的保证}

如果你的模块定义一个变量为结构值，那么你可以使用 @racket[struct/c] 来指定该结构的形状。

@racketmod[
racket

(struct posn [x y])

(define origin (posn 0 0))

(provide
  (contract-out
    [origin (struct/c posn zero? zero?)]))
]

在这个例子中，模块定义了一个用于表示二维位置的结构形状，然后创建了一个特定的实例：@racket[origin]。该实例的导出保证其字段为 @racket[0]，即它们表示笛卡尔网格上的 @tt{(0,0)}。 

@margin-note{另见 @racket[vector/c] 以及类似的契约组合子，用于（flat）复合数据。}

@; ----------------------------------------------------------------------
@ctc-section[#:tag "contracts-define-struct"]{对所有值的保证}

@|HtDP| 一书教导我们，@racket[posn] 的两个字段应该只包含数字。使用契约时，我们可以如下强制执行这个非正式的数据定义：

@racketmod[
racket
(struct posn (x y))
  
(provide
  (contract-out
    [struct posn ((x number?) (y number?))]
    [p-okay posn?]
    [p-sick posn?]))

(define p-okay (posn 10 20))
(define p-sick (posn 'a 'b))
]

该模块导出整个结构定义：@racket[posn]、@racket[posn?]、@racket[posn-x]、@racket[posn-y]、@racket[set-posn-x!] 和 @racket[set-posn-y!]。每个函数在值跨越模块边界时强制执行或承诺 @racket[posn] 结构的两个字段是数字。因此，如果客户端用 @racket[10] 和 @racket['a] 调用 @racket[posn]，契约系统会发出契约违规信号。

然而，在 @racket[posn] 模块内部创建 @racket[p-sick] 并不违反契约。函数 @racket[posn] 在内部使用，所以 @racket['a] 和 @racket['b] 不会跨越模块边界。类似地，当 @racket[p-sick] 跨越 @racket[posn] 的边界时，契约承诺它是 @racket[posn?] 而已，不承诺其他。特别地，这个检查@italic{不}要求 @racket[p-sick] 的字段是数字。

契约检查与模块边界的关联意味着，从客户端的角度看，@racket[p-okay] 和 @racket[p-sick] 看起来是一样的，直到客户端提取其中的字段：

@racketmod[
racket
(require lang/posn)
  
... (posn-x p-sick) ...
]

使用 @racket[posn-x] 是客户端能够找出 @racket[posn] 的 @racket[x] 字段中包含什么的唯一方法。@racket[posn-x] 的应用将 @racket[p-sick] 发送回 @racket[posn] 模块，并将结果值（这里是 @racket['a]）再次跨越模块边界发送回客户端。就在这一点上，契约系统发现一个承诺被打破了。具体来说，@racket[posn-x] 返回的不是数字而是 symbol，因此被归责。 

这个具体的例子表明，对契约违规的解释并不总能 pinpoint 错误源。好消息是错误位于 @racket[posn] 模块中。坏消息是解释具有误导性。虽然 @racket[posn-x] 确实产生了 symbol 而不是数字，但这是从 symbol 创建 @racket[posn] 的程序员的错，即添加了

@racketblock[
(define p-sick (posn 'a 'b))
]

到模块的程序员。所以，当你基于契约违规寻找 bug 时，请记住这个例子。

如果我们想修复 @racket[p-sick] 的契约，以便在导出 @racket[sick] 时捕获错误，只需一个更改即可：

@racketblock[
(provide
 (contract-out
  ...
  [p-sick (struct/c posn number? number?)]))
]

也就是说，我们不是将 @racket[p-sick] 作为普通的 @racket[posn?] 导出，而是使用 @racket[struct/c] 契约来强制执行对其组件的约束。

@; ----------------------------------------------------------------------
@ctc-section[#:tag "lazy-contracts"]{检查数据结构的属性}

使用 @racket[struct/c] 编写的契约会立即检查数据结构的字段，但有时这会对不检查整个数据结构的程序的性能产生灾难性影响。

作为例子，考虑二叉搜索树搜索算法。二叉搜索树类似于二叉树，不同之处在于数字在树中被组织起来使搜索树变得快速。具体来说，对于树中的每个内部节点，左子树中的所有数字都小于节点中的数字，而右子树中的所有数字都大于节点中的数字。

我们可以实现一个搜索函数 @racket[in?]，它利用二叉搜索树的结构。
@racketmod[
racket

(struct node (val left right))
  
(code:comment "determines if `n' is in the binary search tree `b',")
(code:comment "exploiting the binary search tree invariant")
(define (in? n b)
  (cond
    [(null? b) #f]
    [else (cond
            [(= n (node-val b))
             #t]
            [(< n (node-val b))
             (in? n (node-left b))]
            [(> n (node-val b))
             (in? n (node-right b))])]))

(code:comment "a predicate that identifies binary search trees")
(define (bst-between? b low high)
  (or (null? b)
      (and (<= low (node-val b) high)
           (bst-between? (node-left b) low (node-val b))
           (bst-between? (node-right b) (node-val b) high))))

(define (bst? b) (bst-between? b -inf.0 +inf.0))
  
(provide (struct-out node))
(provide
  (contract-out
    [bst? (any/c . -> . boolean?)]
    [in? (number? bst? . -> . boolean?)]))
]

在一个完整的二叉搜索树中，这意味着 @racket[in?] 函数只需要探索对数数量的节点。

@racket[in?] 上的契约保证其输入是一个二叉搜索树。但仔细思考就会发现，这个契约实际上破坏了二叉搜索树算法的初衷。具体来看 @racket[in?] 函数中的内部 @racket[cond]。这是 @racket[in?] 函数获得速度的地方：它在每次递归调用时避免搜索整个子树。现在将其与 @racket[bst-between?] 函数进行比较。在它返回 @racket[#t] 的情况下，它会遍历整棵树，这意味着 @racket[in?] 的加速效果丧失了。

为了修复这个问题，我们可以采用一种新策略来检查二叉搜索树契约。具体来说，如果我们只在 @racket[in?] 查看的节点上检查契约，我们仍然可以保证树至少是部分良构的，但不改变复杂度。

为此，我们需要使用 @racket[struct/dc] 来定义 @racket[bst-between?]。与 @racket[struct/c] 一样，@racket[struct/dc] 定义一个结构的契约。与 @racket[struct/c] 不同的是，它允许字段被标记为 lazy，以便契约只在调用相应的 selector 时才被检查。此外，它不允许 mutable 字段被标记为 lazy。

@racket[struct/dc] 形式接受 struct 每个字段的契约并返回该 struct 上的契约。更有趣的是，@racket[struct/dc] 允许我们编写 dependent 契约，即某些字段的契约依赖于其他字段的值的契约。我们可以用这个来定义二叉搜索树契约：

@racketmod[
racket

(struct node (val left right))

(code:comment "determines if `n' is in the binary search tree `b'")
(define (in? n b) ... as before ...)

(code:comment "bst-between : number number -> contract")
(code:comment "builds a contract for binary search trees")
(code:comment "whose values are between low and high")
(define (bst-between/c low high)
  (or/c null?
        (struct/dc node [val (between/c low high)]
                        [left (val) #:lazy (bst-between/c low val)]
                        [right (val) #:lazy (bst-between/c val high)])))

(define bst/c (bst-between/c -inf.0 +inf.0))

(provide (struct-out node))
(provide
  (contract-out
    [bst/c contract?]
    [in? (number? bst/c . -> . boolean?)]))
]

通常，每次使用 @racket[struct/dc] 必须命名字段，然后为每个字段指定契约。在上面的例子中，@racket[val] 字段是一个接受 @racket[low] 和 @racket[high] 之间值的契约。@racket[left] 和 @racket[right] 字段依赖于 @racket[val] 字段的值，由它们的第二个子表达式表示。它们还标记有 @racket[#:lazy] 关键字，表示它们应该只在 struct 实例上调用相应的 accessor 时才被检查。它们的契约通过递归调用 @racket[bst-between/c] 函数构建。综合起来，这个契约确保了与原始例子中 @racket[bst-between?] 函数检查的相同内容，但这里的检查只在 @racket[in?] 探索树时发生。

虽然这个契约改善了 @racket[in?] 的性能，将其恢复到无契约版本所具有的对数行为，但它仍然施加了相当大的常数开销。因此，契约库还提供 @racket[define-opt/c]，通过优化其主体来降低该常数因子。它的形状就像上面的 @racket[define]。它期望其主体是一个契约，然后优化该契约。

@racketblock[
(define-opt/c (bst-between/c low high)
  (or/c null?
        (struct/dc node [val (between/c low high)]
                        [left (val) #:lazy (bst-between/c low val)]
                        [right (val) #:lazy (bst-between/c val high)])))
]

