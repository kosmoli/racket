#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define check-eval (make-base-eval))
@(interaction-eval #:eval check-eval (require (for-syntax racket/base)))

@(define-syntax-rule (racketblock/eval #:eval e body ...)
   (begin
     (interaction-eval #:eval e body) ...
     (racketblock body ...)))

@title[#:tag "proc-macros" #:style 'toc]{General Macro Transformers}

@racket[define-syntax] 形式为标识符创建一个 @deftech{transformer
binding}（变换器绑定），这是一种可以在编译时使用的绑定，
用于展开在运行时求值的表达式。与变换器绑定关联的编译时值
可以是任何东西；如果它是一个单参数过程，则该绑定
被用作宏，该过程就是 @deftech{macro transformer}（宏变换器）。

@local-table-of-contents[]

@; ----------------------------------------

@section[#:tag "stx-obj"]{Syntax Objects}

宏变换器的输入和输出（即源形式和替换形式）被表示为 @deftech{syntax objects}（语法对象）。
语法对象包含 symbol、列表和常量值（如数字），它们本质上对应于
表达式的 @racket[quote]d 形式。例如，表达式 @racket[(+ 1 2)]
的表示包含 symbol @racket['+] 和数字 @racket[1] 和 @racket[2]，
都在一个列表中。除了这些被引用的内容外，语法对象还将源位置
和词法绑定信息与形式的每个部分关联。源位置信息用于
报告语法错误（例如），词法绑定信息允许宏系统
维护词法作用域。为了容纳这些额外信息，
表达式 @racket[(+ 1 2)] 的表示不仅仅是 @racket['(+ 1 2)]，
而是将 @racket['(+ 1 2)] 封装到一个语法对象中。

要创建字面语法对象，请使用 @racket[syntax] 形式：

@interaction[
(eval:alts (#,(racket syntax) (+ 1 2)) (syntax (+ 1 2)))
]

就像 @litchar{'} 是 @racket[quote] 的缩写一样，
@litchar{#'} 是 @racket[syntax] 的缩写：

@interaction[
#'(+ 1 2)
]

只包含一个 symbol 的语法对象是 @deftech{identifier
syntax object}（标识符语法对象）。Racket 提供了一些专门针对
标识符语法对象的额外操作，包括用于检测标识符的
@racket[identifier?] 操作。最值得注意的是，
@racket[free-identifier=?] 判断两个标识符是否引用同一个绑定：

@interaction[
(identifier? #'car)
(identifier? #'(+ 1 2))
(free-identifier=? #'car #'cdr)
(free-identifier=? #'car #'car)
(require (only-in racket/base [car also-car]))
(free-identifier=? #'car #'also-car)
]

要查看语法对象中的列表、symbol、数字等，请使用
@racket[syntax->datum]：

@interaction[
(syntax->datum #'(+ 1 2))
]

@racket[syntax-e] 函数类似于 @racket[syntax->datum]，
但它只解包一层源位置和词法上下文信息，
让拥有自己信息的子形式保持语法对象的包装：

@interaction[
(syntax-e #'(+ 1 2))
]

@racket[syntax-e] 函数总是在通过 symbol、数字和其他字面值表示的
子形式周围保留语法对象包装。它唯一会解包子形式的时候是
解包一个对，此时对的 @racket[cdr] 可能会被递归解包，
这取决于语法对象的构造方式。

当然，@racket[syntax->datum] 的对立面是
@racket[datum->syntax]。除了像 @racket['(+ 1 2)] 这样的 datum 外，
@racket[datum->syntax] 还需要一个现有的语法对象来提供
其词法上下文，以及可选的另一个语法对象来提供其源位置：

@interaction[
(datum->syntax #'lex
               '(+ 1 2)
               #'srcloc)
]

在上面的示例中，@racket[#'lex] 的词法上下文被用于
新的语法对象，而 @racket[#'srcloc] 的源位置被使用。

当 @racket[datum->syntax] 的第二个参数（即 "datum"）包含语法对象时，
这些语法对象在结果中被完整保留。也就是说，用 @racket[syntax-e]
解构结果最终会产生给 @racket[datum->syntax] 的那些语法对象。


@; ----------------------------------------

@section[#:tag "macro-transformers"]{Macro Transformer Procedures}

任何单参数过程都可以是 @tech{macro transformer}。事实上，
@racket[syntax-rules] 形式是一个展开为过程形式的宏。
例如，如果您直接对 @racket[syntax-rules] 形式求值
（而不是将其放在 @racket[define-syntax] 形式的右侧），
结果是一个过程：

@interaction[
(syntax-rules () [(nothing) something])
]

除了使用 @racket[syntax-rules]，您还可以直接用 @racket[lambda] 编写
自己的宏变换器过程。过程的参数是表示源形式的 @tech{syntax object}，
过程的结果必须是表示替换形式的 @tech{syntax object}：

@interaction[
#:eval check-eval
(define-syntax self-as-string
  (lambda (stx)
    (datum->syntax stx 
                   (format "~s" (syntax->datum stx)))))

(self-as-string (+ 1 2))
]

传递给宏变换器的源形式表示一个表达式，其中其标识符在应用位置
（即在开始表达式的括号之后）使用，或者如果标识符在表达式位置
而非应用位置使用，则单独表示该标识符。@margin-note*{@racket[syntax-rules]
产生的过程在其参数对应于标识符单独使用时会引发语法错误，
这就是为什么 @racket[syntax-rules] 不实现 @tech{identifier macro} 的原因。}

@interaction[
#:eval check-eval
(self-as-string (+ 1 2))
self-as-string
]

@racket[define-syntax] 形式支持与 @racket[define] 相同的
函数简写语法，因此以下 @racket[self-as-string]
定义与使用显式 @racket[lambda] 的定义等价：

@interaction[
#:eval check-eval
(define-syntax (self-as-string stx)
  (datum->syntax stx 
                 (format "~s" (syntax->datum stx))))

(self-as-string (+ 1 2))
]

@; ----------------------------------------

@section[#:tag "syntax-case"]{Mixing Patterns and Expressions: @racket[syntax-case]}

@racket[syntax-rules] 生成的过程在内部使用
@racket[syntax-e] 来解构给定的语法对象，并使用
@racket[datum->syntax] 来构造结果。
@racket[syntax-rules] 形式不提供从模式匹配和模板构造模式
转义到任意 Racket 表达式的方法。

@racket[syntax-case] 形式允许您混合模式匹配、模板构造和任意表达式：

@specform[(syntax-case stx-expr (literal-id ...)
            [pattern expr]
            ...)]

与 @racket[syntax-rules] 不同，@racket[syntax-case] 形式不会
产生过程。相反，它以一个 @racket[_stx-expr] 表达式开始，
该表达式确定要与 @racket[_pattern] 匹配的语法对象。
此外，每个 @racket[syntax-case] 子句有 @racket[_pattern] 和
@racket[_expr]，而不是 @racket[_pattern] 和 @racket[_template]。
在 @racket[_expr] 中，@racket[syntax] 形式——通常缩写为
@litchar{#'}——切换到模板构造模式；如果子句的 @racket[_expr]
以 @litchar{#'} 开头，那么我们就有了类似 @racket[syntax-rules] 形式的东西：

@interaction[
(syntax->datum
 (syntax-case #'(+ 1 2) ()
  [(op n1 n2) #'(- n1 n2)]))
]

我们可以用 @racket[syntax-case] 而不是
@racket[define-syntax-rule] 或 @racket[syntax-rules] 来编写 @racket[swap] 宏：

@racketblock[
(define-syntax (swap stx)
  (syntax-case stx ()
    [(swap x y) #'(let ([tmp x])
                    (set! x y)
                    (set! y tmp))]))
]

使用 @racket[syntax-case] 的一个优点是我们可以为
@racket[swap] 提供更好的错误报告。例如，使用
@racket[define-syntax-rule] 定义的 @racket[swap]，
@racket[(swap x 2)] 会产生关于 @racket[set!] 的语法错误，
因为 @racket[2] 不是标识符。我们可以改进
@racket[syntax-case] 的 @racket[swap] 实现以显式检查子形式：

@racketblock[
(define-syntax (swap stx)
  (syntax-case stx ()
    [(swap x y) 
     (if (and (identifier? #'x)
              (identifier? #'y))
         #'(let ([tmp x])
             (set! x y)
             (set! y tmp))
         (raise-syntax-error #f
                             "not an identifier"
                             stx
                             (if (identifier? #'x) 
                                 #'y 
                                 #'x)))]))
]

有了这个定义，@racket[(swap x 2)] 提供的语法错误
来自 @racket[swap] 而不是 @racket[set!]。

在上面的 @racket[swap] 定义中，@racket[#'x] 和
@racket[#'y] 是模板，即使它们没有被用作宏变换器的结果。
这个示例说明了如何使用模板来访问输入语法的片段，
在此情况下用于检查片段的形式。此外，@racket[#'x] 或
@racket[#'y] 的匹配被用于调用 @racket[raise-syntax-error]，
以便语法错误消息可以直接指向非标识符的源位置。

@; ----------------------------------------

@section[#:tag "with-syntax"]{@racket[with-syntax] and @racket[generate-temporaries]}

由于 @racket[syntax-case] 允许我们用任意 Racket 表达式进行计算，
我们可以更简单地解决编写 @racket[define-for-cbr] 时遇到的一个问题
（参见 @secref["pattern-macro-example"]），在那里我们需要
根据序列 @racket[id ...] 生成一组名称：

@racketblock[
(define-syntax (define-for-cbr stx)
  (syntax-case stx ()
    [(_ do-f (id ...) body)
     ....
       #'(define (do-f get ... put ...)
           (define-get/put-id id get put) ... 
           body) ....]))
]

在上面的 @racket[....] 处，我们需要将 @racket[get ...]
和 @racket[put ...] 绑定到生成的标识符列表。我们不能使用
@racket[let] 来绑定 @racket[get] 和 @racket[put]，
因为我们需要的绑定要算作模式变量，而不是普通的局部变量。
@racket[with-syntax] 形式允许我们绑定模式变量：

@racketblock[
(define-syntax (define-for-cbr stx)
  (syntax-case stx ()
    [(_ do-f (id ...) body)
     (with-syntax ([(get ...) ....]
                   [(put ...) ....])
       #'(define (do-f get ... put ...)
           (define-get/put-id id get put) ... 
           body))]))
]

现在我们需要一个表达式来替代 @racket[....]，该表达式
生成与原始模式中 @racket[id] 匹配数量相同的标识符。
由于这是一项常见任务，Racket 提供了一个辅助函数
@racket[generate-temporaries]，它接受一个标识符序列
并返回一个生成的标识符序列：

@racketblock[
(define-syntax (define-for-cbr stx)
  (syntax-case stx ()
    [(_ do-f (id ...) body)
     (with-syntax ([(get ...) (generate-temporaries #'(id ...))]
                   [(put ...) (generate-temporaries #'(id ...))])
       #'(define (do-f get ... put ...)
           (define-get/put-id id get put) ... 
           body))]))
]

这种生成标识符的方式通常比通过纯基于模式的宏来欺骗
宏展开器生成名称更容易理解。

一般来说，@racket[with-syntax] 绑定的左侧是一个模式，
就像在 @racket[syntax-case] 中一样。事实上，
@racket[with-syntax] 形式只是 @racket[syntax-case] 形式
部分翻转的结果。

@; ----------------------------------------

@section[#:tag "stx-phases"]{Compile and Run-Time Phases}

随着宏集合变得更加复杂，您可能想要编写自己的辅助函数，
如 @racket[generate-temporaries]。例如，为了提供良好的
语法错误消息，@racket[swap]、@racket[rotate] 和
@racket[define-cbr] 都应该检查源形式中的某些子形式是否为标识符。
我们可以使用 @racket[check-ids] 函数在各处执行此检查：

@racketblock/eval[
#:eval check-eval
(define-syntax (swap stx)
  (syntax-case stx ()
    [(swap x y) (begin
                  (check-ids stx #'(x y))
                  #'(let ([tmp x])
                      (set! x y)
                      (set! y tmp)))]))

(define-syntax (rotate stx)
  (syntax-case stx ()
    [(rotate a c ...)
     (begin
       (check-ids stx #'(a c ...))
       #'(shift-to (c ... a) (a c ...)))]))
]

@racket[check-ids] 函数可以使用 @racket[syntax->list]
函数将包装列表的语法对象转换为语法对象的列表：

@racketblock[
(define (check-ids stx forms)
  (for-each
   (lambda (form)
     (unless (identifier? form)
       (raise-syntax-error #f
                           "not an identifier"
                           stx
                           form)))
   (syntax->list forms)))
]

然而，如果您以这种方式定义 @racket[swap] 和 @racket[check-ids]，
它不会工作：

@interaction[
#:eval check-eval
(let ([a 1] [b 2]) (swap a b))
]

问题在于 @racket[check-ids] 被定义为运行时表达式，
但 @racket[swap] 试图在编译时使用它。在交互模式下，
编译时和运行时是交错的，但它们在模块体内不是交错的，
在预先编译的模块之间也不是交错的。为了帮助
所有这些模式一致地处理代码，Racket 将不同阶段的绑定空间分开。

要定义一个可以在编译时引用的 @racket[check-ids] 函数，
请使用 @racket[begin-for-syntax]：

@racketblock/eval[
#:eval check-eval
(begin-for-syntax
  (define (check-ids stx forms)
    (for-each
     (lambda (form)
       (unless (identifier? form)
         (raise-syntax-error #f
                             "not an identifier"
                             stx
                             form)))
     (syntax->list forms))))
]

有了这个 for-syntax 定义，@racket[swap] 就能工作了：

@interaction[
#:eval check-eval
(let ([a 1] [b 2]) (swap a b) (list a b))
(swap a 1)
]

在将程序组织为模块时，您可能希望将辅助函数放在一个模块中，
供驻留在其他模块中的宏使用。在这种情况下，您可以使用
@racket[define] 编写辅助函数：

@racketmod[#:file
"utils.rkt"
racket

(provide check-ids)

(define (check-ids stx forms)
  (for-each
   (lambda (form)
     (unless (identifier? form)
       (raise-syntax-error #f
                           "not an identifier"
                           stx
                           form)))
   (syntax->list forms)))
]

然后，在实现宏的模块中，使用
@racket[(require (for-syntax "utils.rkt"))] 而不是
@racket[(require "utils.rkt")] 来导入辅助函数：

@racketmod[
racket

(require (for-syntax "utils.rkt"))

(define-syntax (swap stx)
  (syntax-case stx ()
    [(swap x y) (begin
                  (check-ids stx #'(x y))
                  #'(let ([tmp x])
                      (set! x y)
                      (set! y tmp)))]))
]

由于模块是分别编译的且不能有循环依赖，
@filepath["utils.rkt"] 模块的运行时体可以在编译实现
@racket[swap] 的模块之前被编译。因此，
@filepath["utils.rkt"] 中的运行时定义可以用于实现 @racket[swap]，
只要它们通过 @racket[(require (for-syntax ....))] 显式地转移到编译时。

@racketmodname[racket] 模块提供 @racket[syntax-case]、
@racket[generate-temporaries]、@racket[lambda]、@racket[if] 等，
可在运行时和编译时阶段使用。这就是为什么我们可以在
@exec{racket} @tech{REPL} 中直接使用 @racket[syntax-case]，
也可以在 @racket[define-syntax] 形式的右侧使用它。

相比之下，@racketmodname[racket/base] 模块仅在运行时阶段
导出这些绑定。如果您将上面定义 @racket[swap] 的模块改为
使用 @racketmodname[racket/base] 语言而不是
@racketmodname[racket]，那么它就不再工作了。添加
@racket[(require (for-syntax racket/base))] 将
@racket[syntax-case] 等导入到编译时阶段，从而使模块再次工作。

假设 @racket[define-syntax] 用于在 @racket[define-syntax] 形式的
右侧定义一个局部宏。在这种情况下，内部 @racket[define-syntax]
的右侧处于 @deftech{meta-compile phase level}（元编译阶段级别），
也称为 @deftech{phase level 2}。要将 @racket[syntax-case] 导入到
该阶段级别，您需要使用
@racket[(require (for-syntax (for-syntax racket/base)))]
或等价的 @racket[(require (for-meta 2 racket/base))]。例如，

@codeblock|{
#lang racket/base
(require  ;; This provides the bindings for the definition
          ;; of shell-game.
          (for-syntax racket/base)
 
          ;; And this for the definition of
          ;; swap.
          (for-syntax (for-syntax racket/base)))

(define-syntax (shell-game stx)

  (define-syntax (swap stx)
    (syntax-case stx ()
      [(_ a b)
       #'(let ([tmp a])
           (set! a b)
           (set! b tmp))]))
  
  (syntax-case stx ()
    [(_ a b c)
     (let ([a #'a] [b #'b] [c #'c])
       (when (= 0 (random 2)) (swap a b))
       (when (= 0 (random 2)) (swap b c))
       (when (= 0 (random 2)) (swap a c))
       #`(list #,a #,b #,c))]))

(shell-game 3 4 5)
(shell-game 3 4 5)
(shell-game 3 4 5)
}|

也存在负阶段级别。如果宏使用通过 @racket[for-syntax] 导入的辅助函数，
并且该辅助函数返回由 @racket[syntax] 生成的语法对象常量，
那么语法中的标识符将需要在 @deftech{phase level
-1}（也称为 @deftech{template phase level}）有绑定，
才能在相对于定义宏的模块的运行时阶段级别具有任何绑定。

例如，下面示例中的 @racket[swap-stx] 辅助函数
不是语法变换器——它只是一个普通函数——但它
产生的语法对象被拼接到 @racket[shell-game] 的结果中。
因此，它包含的 @racket[helper] 子模块需要通过
@racket[(require (for-syntax 'helper))] 在 @racket[shell-game] 的 phase 1 导入。

但从 @racket[swap-stx] 的角度来看，它的结果最终将在 phase level -1 被求值，
即当 @racket[shell-game] 返回的语法被求值时。换句话说，
负阶段级别是从相反方向看的正阶段级别：
@racket[shell-game] 的 phase 1 是 @racket[swap-stx] 的 phase 0，
所以 @racket[shell-game] 的 phase 0 是 @racket[swap-stx] 的 phase -1。
这就是为什么这个示例不会工作——@racket['helper] 子模块
在 phase -1 没有绑定。

@codeblock|{
#lang racket/base
(require (for-syntax racket/base))

(module helper racket/base
  (provide swap-stx)
  (define (swap-stx a-stx b-stx)
    #`(let ([tmp #,a-stx])
          (set! #,a-stx #,b-stx)
          (set! #,b-stx tmp))))

(require (for-syntax 'helper))

(define-syntax (shell-game stx)
  (syntax-case stx ()
    [(_ a b c)
     #`(begin
         #,(swap-stx #'a #'b)
         #,(swap-stx #'b #'c)
         #,(swap-stx #'a #'c)
         (list a b c))]))

(define x 3)
(define y 4)
(define z 5)
(shell-game x y z)
}|

为了修复这个示例，我们向 @racket['helper] 子模块添加
@racket[(require (for-template racket/base))]。

@codeblock|{
#lang racket/base
(require (for-syntax racket/base))

(module helper racket/base
  (require (for-template racket/base)) ; binds `let` and `set!` at phase -1
  (provide swap-stx)
  (define (swap-stx a-stx b-stx)
    #`(let ([tmp #,a-stx])
          (set! #,a-stx #,b-stx)
          (set! #,b-stx tmp))))

(require (for-syntax 'helper))

(define-syntax (shell-game stx)
  (syntax-case stx ()
    [(_ a b c)
     #`(begin
         #,(swap-stx #'a #'b)
         #,(swap-stx #'b #'c)
         #,(swap-stx #'a #'c)
         (list a b c))]))

(define x 3)
(define y 4)
(define z 5)
(shell-game x y z)
(shell-game x y z)
(shell-game x y z)}|



@; ----------------------------------------

@include-section["phases.scrbl"]

@; ----------------------------------------

@include-section["syntax-taints.scrbl"]

@close-eval[check-eval]
