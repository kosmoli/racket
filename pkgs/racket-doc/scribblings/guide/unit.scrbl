#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label racket/unit racket/class))

@(define toy-eval (make-base-eval))

@(interaction-eval #:eval toy-eval (require racket/unit))

@(define-syntax-rule (racketmod/eval [pre ...] form more ...)
   (begin
     (racketmod pre ... form more ...)
     (interaction-eval #:eval toy-eval form)))

@title[#:tag "units" #:style 'toc]{单元@aux-elem{(组件)}}

@hash-lang-note[racket/unit #:lang racket/base]

@deftech{Unit} 将程序组织为可单独编译和可重用的 @deftech{component}。unit 类似于 procedure，两者都是用于抽象的一等值。虽然 procedure 对表达式中的值进行抽象，但 unit 对定义集合中的名称进行抽象。正如 procedure 被调用时会给定实际参数来求值其表达式一样，unit 被 @deftech{invoke} 时会给定实际引用来求值其定义。然而，与 procedure 不同的是，unit 的导入变量可以在 @italic{调用之前} 与另一个 unit 的导出变量进行部分链接。链接将多个 unit 合并为一个单一的 compound unit。compound unit 本身导入的变量会被传播到被链接 unit 中尚未解析的导入变量，并且会重新导出被链接单元中的某些变量以供进一步链接。

@local-table-of-contents[]

@; ----------------------------------------

@section{签名与 Unit}

unit 的接口通过 @deftech{signature} 来描述。每个签名（通常在 @racket[module] 内）使用 @racket[define-signature] 定义。例如，以下放在 @filepath{toy-factory-sig.rkt} 文件中的签名描述了一个实现玩具工厂的组件的导出：

@margin-note{按照约定，签名名称以 @litchar{^} 结尾。}

@racketmod/eval[[#:file
"toy-factory-sig.rkt"
racket]

(define-signature toy-factory^
  (build-toys  (code:comment #, @tt{(integer? -> (listof toy?))})
   repaint     (code:comment #, @tt{(toy? symbol? -> toy?)})
   toy?        (code:comment #, @tt{(any/c -> boolean?)})
   toy-color)) (code:comment #, @tt{(toy? -> symbol?)})

(provide toy-factory^)
]

@racket[toy-factory^] 签名的实现使用 @racket[define-unit] 编写，并通过 @racket[export] 子句指定 @racket[toy-factory^]：

@margin-note{按照约定，unit 名称以 @litchar["@"] 结尾。}

@racketmod/eval[[#:file
"simple-factory-unit.rkt"
racket

(require "toy-factory-sig.rkt")]

(define-unit simple-factory@
  (import)
  (export toy-factory^)

  (printf "Factory started.\n")

  (struct toy (color) #:transparent)

  (define (build-toys n)
    (for/list ([i (in-range n)])
      (toy 'blue)))

  (define (repaint t col)
    (toy col)))

(provide simple-factory@)
]

@racket[toy-factory^] 签名也可能被需要玩具工厂来实现其他功能的 unit 引用。这时，@racket[toy-factory^] 会在 @racket[import] 子句中命名。例如，一个玩具商店会从玩具工厂获取玩具。（为了使示例具有更有趣的特性，假设商店只愿意出售特定颜色的玩具。）

@racketmod/eval[[#:file
"toy-store-sig.rkt"
racket]

(define-signature toy-store^
  (store-color     (code:comment #, @tt{(-> symbol?)})
   stock!          (code:comment #, @tt{(integer? -> void?)})
   get-inventory)) (code:comment #, @tt{(-> (listof toy?))})

(provide toy-store^)
]

@racketmod/eval[[#:file
"toy-store-unit.rkt"
racket

(require "toy-store-sig.rkt"
         "toy-factory-sig.rkt")]

(define-unit toy-store@
  (import toy-factory^)
  (export toy-store^)

  (define inventory null)

  (define (store-color) 'green)

  (define (maybe-repaint t)
    (if (eq? (toy-color t) (store-color))
        t
        (repaint t (store-color))))

  (define (stock! n)
    (set! inventory 
          (append inventory
                  (map maybe-repaint
                       (build-toys n)))))

  (define (get-inventory) inventory))

(provide toy-store@)
]

请注意，@filepath{toy-store-unit.rkt} 导入 @filepath{toy-factory-sig.rkt}，但不导入 @filepath{simple-factory-unit.rkt}。因此，@racket[toy-store@] unit 仅依赖于玩具工厂的规范，而非特定实现。

@; ----------------------------------------

@section{调用 Unit}

@racket[simple-factory@] unit 没有导入，因此可以使用 @racket[invoke-unit] 直接 @tech{invoke}：

@interaction[
#:eval toy-eval
(eval:alts (require "simple-factory-unit.rkt") (void))
(invoke-unit simple-factory@)
]

然而，@racket[invoke-unit] 形式不会使实体中的定义可用，因此我们无法用这个工厂构建任何玩具。@racket[define-values/invoke-unit] 形式将签名的标识符绑定到由实现该签名的 unit（被 @tech{invoke}）提供的值：

@interaction[
#:eval toy-eval
(define-values/invoke-unit/infer simple-factory@)
(build-toys 3)
]

由于 @racket[simple-factory@] 导出 @racket[toy-factory^] 签名，@racket[toy-factory^] 中的每个标识符均由 @racket[define-values/invoke-unit/infer] 形式定义。形式名称中的 @racketidfont{/infer} 部分表示声明绑定的标识符是从 @racket[simple-factory@] 推断出来的。

既然 @racket[toy-factory^] 中的标识符已定义，我们也可以调用导入了 @racket[toy-factory^] 以产生 @racket[toy-store^] 的 @racket[toy-store@]：

@interaction[
#:eval toy-eval
(eval:alts (require "toy-store-unit.rkt") (void))
(define-values/invoke-unit/infer toy-store@)
(get-inventory)
(stock! 2)
(get-inventory)
]

同样，@racket[define-values/invoke-unit/infer] 的 @racketidfont{/infer} 部分确定 @racket[toy-store@] 导入了 @racket[toy-factory^]，因此它将顶层绑定（与 @racket[toy-factory^] 中的名称匹配）提供给 @racket[toy-store@] 作为其导入。

@; ----------------------------------------

@section{链接 Unit}

我们可以通过让玩具工厂与商店合作来提高玩具经济的效率，从而创建不需要重新上色的玩具。相反，玩具始终使用商店的颜色创建，这是工厂通过导入 @racket[toy-store^] 获得的：

@racketmod/eval[[#:file
"store-specific-factory-unit.rkt"
racket

(require "toy-store-sig.rkt"
         "toy-factory-sig.rkt")]

(define-unit store-specific-factory@
  (import toy-store^)
  (export toy-factory^)

  (struct toy () #:transparent)

  (define (toy-color t) (store-color))

  (define (build-toys n)
    (for/list ([i (in-range n)])
      (toy)))

  (define (repaint t col)
    (error "cannot repaint")))

(provide store-specific-factory@)
]

要调用 @racket[store-specific-factory@]，我们需要向该 unit 提供 @racket[toy-store^] 绑定。但是要通过调用 @racket[toy-store@] 获取 @racket[toy-store^] 绑定，我们需要一个玩具工厂！这两个 unit 实现是相互依赖的，我们无法在调用其中一个之前调用另一个。

解决方案是将这些 unit 一起 @deftech{link}，然后我们可以调用组合后的 unit。@racket[define-compound-unit/infer] 形式可以将任意数量的 unit 链接成组合 unit。它可以从被链接 unit 传播导入和导出，并且可以使用其他被链接 unit 的导出满足每个单元的导入。

@interaction[
#:eval toy-eval
(eval:alts (require "toy-factory-sig.rkt") (void))
(eval:alts (require "toy-store-sig.rkt") (void))
(eval:alts (require "toy-store-unit.rkt") (void))
(eval:alts (require "store-specific-factory-unit.rkt") (void))
(define-compound-unit/infer toy-store+factory@
  (import)
  (export toy-factory^ toy-store^)
  (link store-specific-factory@
        toy-store@))
]

上面的整体结果是一个导出 @racket[toy-factory^] 和 @racket[toy-store^] 的 unit @racket[toy-store+factory@]。@racket[store-specific-factory@] 和 @racket[toy-store@] 之间的连接是从各自导入和导出的签名推断出来的。

这个 unit 没有导入，因此我们始终可以调用它：

@interaction[
#:eval toy-eval
(define-values/invoke-unit/infer toy-store+factory@)
(stock! 2)
(get-inventory)
(map toy-color (get-inventory))
]

@; ----------------------------------------

@section[#:tag "firstclassunits"]{一等 Unit}

@racket[define-unit] 形式将 @racket[define] 和 @racket[unit] 形式组合起来，类似于 @racket[(define (f x) ....)] 将 @racket[define] 与一个标识符以及一个隐式 @racket[lambda] 组合的方式。

展开这个简写形式，@racket[toy-store@] 的定义几乎可以写成

@racketblock[
(define toy-store@
  (unit
   (import toy-factory^)
   (export toy-store^)

   (define inventory null)

   (define (store-color) 'green)
   ....))
]

这种展开与 @racket[define-unit] 的区别在于 @racket[toy-store@] 的导入和导出无法被推断。也就是说，除了组合 @racket[define] 和 @racket[unit] 之外，@racket[define-unit] 还将静态信息附加到被定义的标识符上，以便其签名信息可以静态地供 @racket[define-values/invoke-unit/infer] 和其他形式使用。

尽管会丢失静态签名信息，@racket[unit] 仍然可以与其他处理一等值的形式结合使用。例如，我们可以将创建玩具商店的 @racket[unit] 包装在 @racket[lambda] 中以提供商店的颜色：

@racketmod/eval[[#:file
"toy-store-maker.rkt"
racket

(require "toy-store-sig.rkt"
         "toy-factory-sig.rkt")]

(define toy-store@-maker
  (lambda (the-color)
    (unit
     (import toy-factory^)
     (export toy-store^)

     (define inventory null)

     (define (store-color) the-color)

     (code:comment @#,t{the rest is the same as before})

     (define (maybe-repaint t)
       (if (eq? (toy-color t) (store-color))
           t
           (repaint t (store-color))))

     (define (stock! n)
       (set! inventory
             (append inventory
                     (map maybe-repaint
                          (build-toys n)))))

     (define (get-inventory) inventory))))

(provide toy-store@-maker)
]

要调用由 @racket[toy-store@-maker] 创建的 unit，我们必须使用 @racket[define-values/invoke-unit]，而不是带 @racketidfont{/infer} 的变体：

@interaction[
#:eval toy-eval
(eval:alts (require "simple-factory-unit.rkt") (void))
(define-values/invoke-unit/infer simple-factory@)
(eval:alts (require "toy-store-maker.rkt") (void))
(define-values/invoke-unit (toy-store@-maker 'purple)
  (import toy-factory^)
  (export toy-store^))
(stock! 2)
(get-inventory)
]

在 @racket[define-values/invoke-unit] 形式中，@racket[(import toy-factory^)] 行从当前上下文中获取与 @racket[toy-factory^] 中名称匹配的绑定（即我们通过调用 @racket[simple-factory@] 创建的绑定），并将它们作为导入提供给 @racket[toy-store@]。@racket[(export toy-store^)] 子句表明 @racket[toy-store@-maker] 产生的 unit 将导出 @racket[toy-store^]，该签名中的名称在调用 unit 之后被定义。

要链接来自 @racket[toy-store@-maker] 的 unit，我们可以使用 @racket[compound-unit] 形式：

@interaction[
#:eval toy-eval
(eval:alts (require "store-specific-factory-unit.rkt") (void))
(define toy-store+factory@
  (compound-unit
   (import)
   (export TF TS)
   (link [((TF : toy-factory^)) store-specific-factory@ TS]
         [((TS : toy-store^)) toy-store@ TF])))
]

这个 @racket[compound-unit] 形式将大量信息打包到一个位置。@racket[link] 子句中左侧的 @racket[TF] 和 @racket[TS] 是绑定标识符。标识符 @racket[TF] 本质上绑定到 @racket[toy-factory^] 的元素，这些元素由 @racket[store-specific-factory@] 实现。标识符 @racket[TS] 同样绑定到 @racket[toy-store^] 的元素，这些元素由 @racket[toy-store@] 实现。同时，绑定到 @racket[TS] 的元素被作为导入提供给 @racket[store-specific-factory@]，因为 @racket[TS] 位于 @racket[store-specific-factory@] 之后。绑定到 @racket[TF] 的元素同样被提供给 @racket[toy-store@]。最后，@racket[(export TF TS)] 表明绑定到 @racket[TF] 和 @racket[TS] 的元素将从该 compound unit 导出。

上面的 @racket[compound-unit] 形式将 @racket[store-specific-factory@] 作为一等 unit 使用，即使其信息可以被推断。除了用于推断上下文之外，每个 unit 都可以作为一等 unit 使用。此外，各种形式让程序员能够在推断世界和一等世界之间架起桥梁。例如，@racket[define-unit-binding] 将一个新标识符绑定到任意表达式产生的 unit；它在静态上关联签名信息，并在动态上针对该一等 unit 检查签名。

@; ----------------------------------------

@section{整体 @racket[module] 签名和 Unit}

在使用 unit 的程序中，@filepath{toy-factory-sig.rkt} 和 @filepath{simple-factory-unit.rkt} 这样的 module 很常见。@racket[racket/signature] 和 @racket[racket/unit] module 名称可用作语言，以避免大量样板式的 module、签名和 unit 声明文本。

例如，@filepath{toy-factory-sig.rkt} 可以写成

@racketmod[
racket/signature

build-toys  (code:comment #, @tt{(integer? -> (listof toy?))})
repaint     (code:comment #, @tt{(toy? symbol? -> toy?)})
toy?        (code:comment #, @tt{(any/c -> boolean?)})
toy-color   (code:comment #, @tt{(toy? -> symbol?)})
]

签名 @racket[toy-factory^] 会自动从 module 提供，通过将文件名 @filepath{toy-factory-sig.rkt} 中的 @filepath{-sig.rkt} 后缀替换为 @racketidfont{^} 推断而来。

同样，@filepath{simple-factory-unit.rkt} module 可以写成

@racketmod[
racket/unit

(require "toy-factory-sig.rkt")

(import)
(export toy-factory^)

(printf "Factory started.\n")

(struct toy (color) #:transparent)

(define (build-toys n)
  (for/list ([i (in-range n)])
    (toy 'blue)))

(define (repaint t col)
  (toy col))
]

单元 @racket[simple-factory@] 会自动从 module 提供，通过将文件名 @filepath{simple-factory-unit.rkt} 中的 @filepath{-unit.rkt} 后缀替换为 @racketidfont["@"] 推断而来。

@; ----------------------------------------

@(interaction-eval #:eval toy-eval (require racket/contract))

@section{为 Unit 添加 Contract}

有几种方法可以用 contract 来保护 unit。一种方法在编写新签名时很有用，另一种则处理 unit 必须符合已有签名的情况。

@subsection{为签名添加 Contract}

当向签名添加 contract 时，实现该签名的所有 unit 都会受到这些 contract 的保护。以下 @racket[toy-factory^] 签名版本添加了之前写在注释中的 contract：

@racketmod/eval[[#:file
"contracted-toy-factory-sig.rkt"
racket]

(define-signature contracted-toy-factory^
  ((contracted
    [build-toys (-> integer? (listof toy?))]
    [repaint    (-> toy? symbol? toy?)]
    [toy?       (-> any/c boolean?)]
    [toy-color  (-> toy? symbol?)])))

(provide contracted-toy-factory^)]

现在我们将之前的 @racket[simple-factory@] 实现改为实现这个版本的 @racket[toy-factory^]：

@racketmod/eval[[#:file
"contracted-simple-factory-unit.rkt"
racket

(require "contracted-toy-factory-sig.rkt")]

(define-unit contracted-simple-factory@
  (import)
  (export contracted-toy-factory^)

  (printf "Factory started.\n")

  (struct toy (color) #:transparent)

  (define (build-toys n)
    (for/list ([i (in-range n)])
      (toy 'blue)))

  (define (repaint t col)
    (toy col)))

(provide contracted-simple-factory@)
]

和之前一样，我们可以调用新的 unit 并绑定导出以供使用。但这次，误用导出会导致相应的 contract 错误。

@interaction[
#:eval toy-eval
(eval:alts (require "contracted-simple-factory-unit.rkt") (void))
(define-values/invoke-unit/infer contracted-simple-factory@)
(build-toys 3)
(build-toys #f)
(repaint 3 'blue)
]

@subsection{为 Unit 添加 Contract}

然而，有时我们可能有一个 unit 必须符合一个尚未 contract 的已有签名。在这种情况下，我们可以使用 @racket[unit/c] 创建 unit contract，或者使用 @racket[define-unit/contract] 形式，它定义了一个被包装在 unit contract 中的 unit。

例如，这里有一个 @racket[toy-factory@] 版本，它仍然实现常规的 @racket[toy-factory^]，但其导出已被适当的 unit contract 保护。

@racketmod/eval[[#:file
"wrapped-simple-factory-unit.rkt"
racket

(require "toy-factory-sig.rkt")]

(define-unit/contract wrapped-simple-factory@
  (import)
  (export (toy-factory^
           [build-toys (-> integer? (listof toy?))]
           [repaint    (-> toy? symbol? toy?)]
           [toy?       (-> any/c boolean?)]
           [toy-color  (-> toy? symbol?)]))

  (printf "Factory started.\n")

  (struct toy (color) #:transparent)

  (define (build-toys n)
    (for/list ([i (in-range n)])
      (toy 'blue)))

  (define (repaint t col)
    (toy col)))

(provide wrapped-simple-factory@)
]

@interaction[
#:eval toy-eval
(eval:alts (require "wrapped-simple-factory-unit.rkt") (void))
(define-values/invoke-unit/infer wrapped-simple-factory@)
(build-toys 3)
(build-toys #f)
(repaint 3 'blue)
]


@; ----------------------------------------

@section{@racket[unit] 与 @racket[module]}

作为模块化的形式，@racket[unit] 补充了 @racket[module]：

@itemize[

 @item{@racket[module] 形式主要用于管理通用 namespace。例如，它允许代码片段专门引用 @racketmodname[racket/base] 中的 @racket[car] 操作——即提取内置 pair 数据类型实例的第一个元素的操作——而不是其他任何同名的 @racket[car] 函数。换句话说，@racket[module] 构造让你引用 @emph{那个} 你想要的绑定。}

 @item{@racket[unit] 形式用于根据几乎任何类型的运行时值对代码片段进行参数化。例如，它允许代码片段与一个接受单个参数的 @racket[car] 函数一起工作，其中具体的函数稍后通过将该片段链接到另一个片段来确定。换句话说，@racket[unit] 构造让你引用 @emph{某个} 满足某种规范的绑定。}

]

@racket[lambda] 和 @racket[class] 等形式也允许根据后续选择的值对代码进行参数化。原则上，其中任何一个都可以用其他任何一个来实现。在实践中，每种形式都提供了某些便利——例如允许方法重写或对值进行特别简单的应用——使其适用于不同的用途。

@racket[module] 形式在某种意义上比其他形式更基础。毕竟，如果没有 @racket[module] 提供的 namespace 管理，程序片段就无法可靠地引用 @racket[lambda]、@racket[class] 或 @racket[unit] 形式。同时，由于 namespace 管理密切相关于独立的展开和编译，@racket[module] 边界最终成为独立编译边界，从而禁止片段之间的相互依赖。出于类似的原因，@racket[module] 不区分接口和实现。

当 @racket[module] 单独使用几乎可行，但独立编译的片段必须相互引用时，或者当你想在 @defterm{interface}（即需要在展开和编译时知道的部分）与 @defterm{implementation}（即运行时部分）之间实现更强的分离时使用 @racket[unit]。更一般地说，当需要根据函数、datatype 和 class 对代码进行参数化，并且参数化代码本身提供了待与其他参数化代码链接的定义时使用 @racket[unit]。

@; ----------------------------------------------------------------------

@close-eval[toy-eval]
