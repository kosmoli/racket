#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label racket/unit racket/class))

@(define toy-eval (make-base-eval))

@(interaction-eval #:eval toy-eval (require racket/unit))

@(define-syntax-rule (racketmod/eval [pre ...] form more ...)
   (begin
     (racketmod pre ... form more ...)
     (interaction-eval #:eval toy-eval form)))

@title[#:tag "units" #:style 'toc]{Units@aux-elem{ (Components)}}

@hash-lang-note[racket/unit #:lang racket/base]

@deftech{Unit} 将程序组织为可单独编译和可重用的@deftech{组件}。unit 类似于过程，因为两者都是用于抽象的一等值。过程对表达式中的值进行抽象，而 unit 对定义集合中的名称进行抽象。正如过程被调用以在给定实际参数的情况下对其表达式求值一样，unit 被@deftech{调用}以在给定导入变量的实际引用的情况下对其定义求值。然而，与过程不同的是，unit 的导入变量可以在@italic{调用之前}与另一个 unit 的导出变量部分链接。链接将多个 unit 合并为一个复合 unit。复合 unit 本身导入将传播到链接 unit 中未解析的导入变量的变量，并从链接 unit 重新导出一些变量以供进一步链接。

@local-table-of-contents[]

@; ----------------------------------------

@section{Signatures and Units}

unit 的接口用@deftech{签名}来描述。每个签名使用 @racket[define-signature] 定义（通常在 @racket[module] 内）。例如，以下签名放在 @filepath{toy-factory-sig.rkt} 文件中，描述了实现玩具工厂的组件的导出：

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

@racket[toy-factory^] 签名的实现使用 @racket[define-unit] 编写，带有一个命名 @racket[toy-factory^] 的 @racket[export] 子句：

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

@racket[toy-factory^] 签名也可以被需要玩具工厂来实现其他功能的 unit 引用。在这种情况下，@racket[toy-factory^] 会在 @racket[import] 子句中被命名。例如，玩具商店会从玩具工厂获取玩具。（为了示例的趣味性，假设商店只愿意销售特定颜色的玩具。）

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

请注意，@filepath{toy-store-unit.rkt} 导入了 @filepath{toy-factory-sig.rkt}，但没有导入 @filepath{simple-factory-unit.rkt}。因此，@racket[toy-store@] unit 仅依赖于玩具工厂的规范，而不是特定的实现。

@; ----------------------------------------

@section{Invoking Units}

@racket[simple-factory@] unit 没有导入，因此可以直接使用 @racket[invoke-unit]@tech{调用}：

@interaction[
#:eval toy-eval
(eval:alts (require "simple-factory-unit.rkt") (void))
(invoke-unit simple-factory@)
]

然而，@racket[invoke-unit] 形式不会使主体定义可用，因此我们无法用这个工厂制造任何玩具。@racket[define-values/invoke-unit] 形式将签名的标识符绑定到实现该签名的 unit（将被@tech{调用}）提供的值：

@interaction[
#:eval toy-eval
(define-values/invoke-unit/infer simple-factory@)
(build-toys 3)
]

由于 @racket[simple-factory@] 导出了 @racket[toy-factory^] 签名，@racket[toy-factory^] 中的每个标识符都由 @racket[define-values/invoke-unit/infer] 形式定义。形式名称中的 @racketidfont{/infer} 部分表示声明绑定的标识符是从 @racket[simple-factory@] 推断的。

既然 @racket[toy-factory^] 中的标识符已经定义，我们也可以调用导入 @racket[toy-factory^] 以产生 @racket[toy-store^] 的 @racket[toy-store@]：

@interaction[
#:eval toy-eval
(eval:alts (require "toy-store-unit.rkt") (void))
(define-values/invoke-unit/infer toy-store@)
(get-inventory)
(stock! 2)
(get-inventory)
]

同样，@racket[define-values/invoke-unit/infer] 的 @racketidfont{/infer} 部分确定 @racket[toy-store@] 导入了 @racket[toy-factory^]，因此它将匹配 @racket[toy-factory^] 中名称的顶级绑定作为 @racket[toy-store@] 的导入提供。

@; ----------------------------------------

@section{Linking Units}

我们可以通过让玩具工厂与商店合作来提高玩具经济的效率，创建不需要重新涂漆的玩具。相反，玩具总是使用商店的颜色创建，工厂通过导入 @racket[toy-store^] 获取颜色：

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

要调用 @racket[store-specific-factory@]，我们需要 @racket[toy-store^] 绑定来提供给 unit。但要通过调用 @racket[toy-store@] 获取 @racket[toy-store^] 绑定，我们需要一个玩具工厂！unit 实现是相互依赖的，我们无法在另一个之前调用任何一个。

解决方案是将 unit@deftech{链接}在一起，然后我们可以调用组合的 unit。@racket[define-compound-unit/infer] 形式链接任意数量的 unit 以形成组合 unit。它可以传播链接 unit 的导入和导出，并且可以使用其他链接 unit 的导出来满足每个 unit 的导入。

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

上面的总体结果是一个导出 @racket[toy-factory^] 和 @racket[toy-store^] 的 unit @racket[toy-store+factory@]。@racket[store-specific-factory@] 和 @racket[toy-store@] 之间的连接是从各自导入和导出的签名推断出来的。

这个 unit 没有导入，因此我们始终可以调用它：

@interaction[
#:eval toy-eval
(define-values/invoke-unit/infer toy-store+factory@)
(stock! 2)
(get-inventory)
(map toy-color (get-inventory))
]

@; ----------------------------------------

@section[#:tag "firstclassunits"]{First-Class Units}

@racket[define-unit] 形式将 @racket[define] 与 @racket[unit] 形式结合在一起，类似于 @racket[(define (f x) ....)] 将 @racket[define] 后跟标识符与隐式 @racket[lambda] 结合的方式。

展开简写，@racket[toy-store@] 的定义几乎可以写成

@racketblock[
(define toy-store@
  (unit
   (import toy-factory^)
   (export toy-store^)

   (define inventory null)

   (define (store-color) 'green)
   ....))
]

此展开与 @racket[define-unit] 的一个区别是 @racket[toy-store@] 的导入和导出无法被推断。也就是说，除了结合 @racket[define] 和 @racket[unit] 之外，@racket[define-unit] 还将静态信息附加到定义的标识符，以便其签名信息可以静态地供 @racket[define-values/invoke-unit/infer] 和其他形式使用。

尽管有丢失静态签名信息的缺点，@racket[unit] 与处理一等值的其他形式结合使用可能很有用。例如，我们可以将创建玩具商店的 @racket[unit] 包装在 @racket[lambda] 中以提供商店的颜色：

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

要调用由 @racket[toy-store@-maker] 创建的 unit，我们必须使用 @racket[define-values/invoke-unit]，而不是 @racketidfont{/infer} 变体：

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

在 @racket[define-values/invoke-unit] 形式中，@racket[(import toy-factory^)] 行从当前上下文中获取匹配 @racket[toy-factory^] 名称的绑定（我们通过调用 @racket[simple-factory@] 创建的），并将它们作为 @racket[toy-store@] 的导入提供。@racket[(export toy-store^)] 子句表示 @racket[toy-store@-maker] 产生的 unit 将导出 @racket[toy-store^]，该签名的名称在调用 unit 后被定义。

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

这个 @racket[compound-unit] 形式在一个地方打包了大量信息。@racket[link] 子句左侧的 @racket[TF] 和 @racket[TS] 是绑定标识符。标识符 @racket[TF] 本质上绑定到由 @racket[store-specific-factory@] 实现的 @racket[toy-factory^] 的元素。标识符 @racket[TS] 类似地绑定到由 @racket[toy-store@] 实现的 @racket[toy-store^] 的元素。同时，绑定到 @racket[TS] 的元素作为 @racket[store-specific-factory@] 的导入提供，因为 @racket[TS] 跟在 @racket[store-specific-factory@] 后面。绑定到 @racket[TF] 的元素类似地提供给 @racket[toy-store@]。最后，@racket[(export TF TS)] 表示绑定到 @racket[TF] 和 @racket[TS] 的元素从复合 unit 导出。

上面的 @racket[compound-unit] 形式将 @racket[store-specific-factory@] 作为一等 unit 使用，即使其信息可以被推断。每个 unit 都可以作为一等 unit 使用，此外还可以在推断上下文中使用。此外，各种形式让程序员可以弥合推断世界和一等世界之间的差距。例如，@racket[define-unit-binding] 将新标识符绑定到由任意表达式产生的 unit；它将签名信息静态关联到标识符，并动态检查签名是否与表达式产生的一等 unit 匹配。

@; ----------------------------------------

@section{Whole-@racket[module] Signatures and Units}

在使用 unit 的程序中，像 @filepath{toy-factory-sig.rkt} 和 @filepath{simple-factory-unit.rkt} 这样的模块很常见。@racket[racket/signature] 和 @racket[racket/unit] 模块名称可以用作语言，以避免大量的样板模块、签名和 unit 声明文本。

例如，@filepath{toy-factory-sig.rkt} 可以写成

@racketmod[
racket/signature

build-toys  (code:comment #, @tt{(integer? -> (listof toy?))})
repaint     (code:comment #, @tt{(toy? symbol? -> toy?)})
toy?        (code:comment #, @tt{(any/c -> boolean?)})
toy-color   (code:comment #, @tt{(toy? -> symbol?)})
]

签名 @racket[toy-factory^] 从模块自动提供，通过将文件名 @filepath{toy-factory-sig.rkt} 的 @filepath{-sig.rkt} 后缀替换为 @racketidfont{^} 来推断。

类似地，@filepath{simple-factory-unit.rkt} 模块可以写成

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

unit @racket[simple-factory@] 从模块自动提供，通过将文件名 @filepath{simple-factory-unit.rkt} 的 @filepath{-unit.rkt} 后缀替换为 @racketidfont["@"] 来推断。

@; ----------------------------------------

@(interaction-eval #:eval toy-eval (require racket/contract))

@section{Contracts for Units}

有几种方法可以用契约保护 unit。一种方法在编写新签名时很有用，另一种处理 unit 必须符合已有签名的情况。

@subsection{Adding Contracts to Signatures}

当契约被添加到签名时，所有实现该签名的 unit 都受到这些契约的保护。以下版本的 @racket[toy-factory^] 签名添加了之前在注释中编写的契约：

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

现在我们使用 @racket[simple-factory@] 的先前实现，改为实现此版本的 @racket[toy-factory^]：

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

和以前一样，我们可以调用新 unit 并绑定导出以便使用。然而，这次误用导出会导致相应的契约错误。

@interaction[
#:eval toy-eval
(eval:alts (require "contracted-simple-factory-unit.rkt") (void))
(define-values/invoke-unit/infer contracted-simple-factory@)
(build-toys 3)
(build-toys #f)
(repaint 3 'blue)
]

@subsection{Adding Contracts to Units}

然而，有时我们可能有一个必须符合未签约名的已有签名的 unit。在这种情况下，我们可以用 @racket[unit/c] 创建 unit 契约，或使用 @racket[define-unit/contract] 形式，它定义了一个被 unit 契约包装的 unit。

例如，这是 @racket[toy-factory@] 的一个版本，它仍然实现常规的 @racket[toy-factory^]，但其导出已用适当的 unit 契约保护。

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

@section{@racket[unit] versus @racket[module]}

作为模块化的形式，@racket[unit] 补充了 @racket[module]：

@itemize[

 @item{@racket[module] 形式主要用于管理通用命名空间。例如，它允许代码片段专门引用 @racketmodname[racket/base] 中的 @racket[car] 操作——即从内置 pair 数据类型的实例中提取第一个元素的那个——而不是任何数量的其他名为 @racket[car] 的函数。换句话说，@racket[module] 构造让你引用@emph{你想要的}绑定。}

 @item{@racket[unit] 形式用于对代码片段进行参数化，使其相对于几乎任何类型的运行时值。例如，它允许代码片段与接受单个参数的 @racket[car] 函数一起工作，其中具体的函数稍后通过将片段链接到另一个来确定。换句话说，@racket[unit] 构造让你引用满足某个规范的@emph{某个}绑定。}

]

@racket[lambda] 和 @racket[class] 等形式也允许代码相对于稍后选择的值进行参数化。原则上，这些形式中的任何一个都可以用其他任何一个来实现。在实践中，每种形式都提供了某些便利——比如允许方法重载或特别简单的值应用——使它们适合不同的用途。

@racket[module] 形式在某种意义上比其他形式更基本。毕竟，没有 @racket[module] 提供的命名空间管理，程序片段无法可靠地引用 @racket[lambda]、@racket[class] 或 @racket[unit] 形式。同时，由于命名空间管理与单独的展开和编译密切相关，@racket[module] 边界最终成为单独编译边界，禁止片段之间的相互依赖。出于类似原因，@racket[module] 不分离接口和实现。

当 @racket[module] 本身几乎可行，但单独编译的部分必须相互引用时，或者当你想要在@defterm{接口}（即展开和编译时需要知道的部分）和@defterm{实现}（即运行时部分）之间有更强的分离时，使用 @racket[unit]。更一般地说，当你需要对函数、数据类型和类进行代码参数化，并且参数化的代码本身提供要与其他参数化代码链接的定义时，使用 @racket[unit]。

@; ----------------------------------------------------------------------

@close-eval[toy-eval]
