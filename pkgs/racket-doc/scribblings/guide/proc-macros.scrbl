#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@(define check-eval (make-base-eval))
@(interaction-eval #:eval check-eval (require (for-syntax racket/base)))

@(define-syntax-rule (racketblock/eval #:eval e body ...)
   (begin
     (interaction-eval #:eval e body) ...
     (racketblock body ...)))

@title[#:tag "proc-macros" #:style 'toc]{通用宏转换器}

The @racket[define-syntax] form creates a @deftech{transformer
binding} for an identifier, which is a binding that can be used at
compile time while expanding expressions to be evaluated at run time.
The compile-time value associated with a transformer binding can be
anything; if it is a procedure of one argument, then the binding is
used as a macro, and the procedure is the @deftech{macro transformer}.

@local-table-of-contents[]

@; ----------------------------------------

@section[#:tag "stx-obj"]{Syntax Objects}

宏转换器的输入和输出（即源形式和替换形式）被表示为 @deftech{syntax object}。
syntax object 包含 symbol、list 和常量值（如数字），它们在本质上对应于
表达式的 @racket[quote] 形式。例如，表达式 @racket[(+ 1 2)] 的表示包含
symbol @racket['+] 以及数字 @racket[1] 和 @racket[2]，都在一个 list
中。除了这些被引用的内容外，syntax object 还会将 source-location 和
lexical-binding 信息与形式的各个部分关联起来。source-location 信息
在报告 syntax error 时使用（例如），而 lexical-binding 信息使得宏系统
能够维护词法作用域。为了适应这些额外信息，表达式 @racket[(+ 1 2)]
的表示不仅仅是 @racket['(+ 1 2)]，而是将 @racket['(+ 1 2)] 包装成一个
syntax object。

要创建字面的 syntax object，请使用 @racket[syntax] 形式：

@interaction[
(eval:alts (#,(racket syntax) (+ 1 2)) (syntax (+ 1 2)))
]

与 @litchar{'} 缩写 @racket[quote] 的方式相同，
@litchar{#'} 缩写 @racket[syntax]：

@interaction[
#'(+ 1 2)
]

只包含 symbol 的 syntax object 就是 @deftech{identifier syntax object}。
Racket 为 identifier syntax object 提供了一些额外操作，包括用于检测 identifier
的 @racket[identifier?] 操作。最值得注意的
是，@racket[free-identifier=?] 用于判断两个 identifier 是否引用
同一个 binding：

@interaction[
(identifier? #'car)
(identifier? #'(+ 1 2))
(free-identifier=? #'car #'cdr)
(free-identifier=? #'car #'car)
(require (only-in racket/base [car also-car]))
(free-identifier=? #'car #'also-car)
]

要在 syntax object 中查看 list、symbol、number 等（@|etc|），请使用
@racket[syntax->datum]：

@interaction[
(syntax->datum #'(+ 1 2))
]

@racket[syntax-e] 函数类似于 @racket[syntax->datum]，但它会解开一层
source-location 和 lexical-context 信息，将具有自身信息的子形式保留为
syntax object：

@interaction[
(syntax-e #'(+ 1 2))
]

@racket[syntax-e] 函数始终会为通过 symbol、number 和其他字面值的子形式
保留 syntax object 包装。只有在解开 pair 时，它才会额外解开子形式，
在这种情况下，pair 的 @racket[cdr] 可能会根据 syntax object 的构造方式
被递归解开。

@racket[syntax->datum] 的反操作当然就是 @racket[datum->syntax]。
除了像 @racket['(+ 1 2)] 这样的 datum 之外，@racket[datum->syntax]
还需要一个已有的 syntax object 来捐赠其 lexical context，并且可以选择
另一个 syntax object 来捐赠其 source location：

@interaction[
(datum->syntax #'lex
               '(+ 1 2)
               #'srcloc)
]

在上面的例子中，@racket[#'lex] 的 lexical context 被用于新的
syntax object，而 @racket[#'srcloc] 的 source location 被使用。

当 @racket[datum->syntax] 的第二个（即 ``datum''）参数包含 syntax object 时，
这些 syntax object 会在结果中完好无损地被保留。也就是说，用
@racket[syntax-e] 解构结果最终会产生传递给 @racket[datum->syntax]
的那些 syntax object。


@; ----------------------------------------

@section[#:tag "macro-transformers"]{Macro Transformer Procedures}

任何单参数的 procedure 都可以是 @tech{macro transformer}。实际上，
@racket[syntax-rules] 形式是一个宏，它会展开为 procedure 形式。例如，
如果你直接求值一个 @racket[syntax-rules] 形式（而不是放在 @racket[define-syntax]
形式的右边），结果就是一个 procedure：

@interaction[
(syntax-rules () [(nothing) something])
]

除了使用 @racket[syntax-rules]，你也可以直接使用 @racket[lambda]
编写自己的 macro transformer procedure。该 procedure 的参数是一个代表
源形式的 @tech{syntax object}，procedure 的结果也必须是一个代表
替换形式的 @tech{syntax object}：

@interaction[
#:eval check-eval
(define-syntax self-as-string
  (lambda (stx)
    (datum->syntax stx 
                   (format "~s" (syntax->datum stx)))))

(self-as-string (+ 1 2))
]

传递给 macro transformer 的源形式表示一个表达式，其中 identifier 被用在
application 位置（即在开启表达式的左括号之后），或者如果它被用在
expression 位置但不在 application 位置中，则它单独表示该 identifier。@margin-note*{The procedure produced by
@racket[syntax-rules] raises a syntax error if its argument
corresponds to a use of the identifier by itself, which is why
@racket[syntax-rules] does not implement an @tech{identifier macro}.}

@interaction[
#:eval check-eval
(self-as-string (+ 1 2))
self-as-string
]

@racket[define-syntax] 形式支持与 @racket[define] 相同的函数快捷语法，
因此下面这个 @racket[self-as-string] 定义与使用 @racket[lambda]
显式写法等价：

@interaction[
#:eval check-eval
(define-syntax (self-as-string stx)
  (datum->syntax stx 
                 (format "~s" (syntax->datum stx))))

(self-as-string (+ 1 2))
]

@; ----------------------------------------

@section[#:tag "syntax-case"]{Mixing Patterns and Expressions: @racket[syntax-case]}

@racket[syntax-rules] 生成的 procedure 在内部使用 @racket[syntax-e]
来解构给定的 syntax object，并使用 @racket[datum->syntax] 来构造结果。
@racket[syntax-rules] 形式无法从 pattern-matching 和 template-construction
模式跳出到任意的 Racket 表达式。

@racket[syntax-case] 形式让你可以混合 pattern matching、template
construction 和任意表达式：

@specform[(syntax-case stx-expr (literal-id ...)
            [pattern expr]
            ...)]

与 @racket[syntax-rules] 不同，@racket[syntax-case] 形式不产生 procedure。
相反，它以一个 @racket[_stx-expr] 表达式开始，该表达式确定要与 @racket[_pattern]
匹配的 syntax object。此外，每个 @racket[syntax-case] 子句有一个 @racket[_pattern]
和一个 @racket[_expr]，而不是 @racket[_pattern] 和 @racket[_template]。
在 @racket[_expr] 内部，@racket[syntax] 形式（通常缩写为 @litchar{#'}）
会切换到 template-construction 模式；如果子句的 @racket[_expr] 以
@litchar{#'} 开始，那么我们得到的就是类似 @racket[syntax-rules] 的形式：

@interaction[
(syntax->datum
 (syntax-case #'(+ 1 2) ()
  [(op n1 n2) #'(- n1 n2)]))
]

We could write the @racket[swap] macro using @racket[syntax-case]
instead of @racket[define-syntax-rule] or @racket[syntax-rules]:

@racketblock[
(define-syntax (swap stx)
  (syntax-case stx ()
    [(swap x y) #'(let ([tmp x])
                    (set! x y)
                    (set! y tmp))]))
]

使用 @racket[syntax-case] 的一个优势是我们可以为 @racket[swap] 提供
更好的错误报告。例如，使用 @racket[define-syntax-rule] 定义的 @racket[swap]，
那么 @racket[(swap x 2)] 会产生 @racket[set!] 相关的 syntax error，
因为 @racket[2] 不是 identifier。我们可以改进 @racket[syntax-case]
实现的 @racket[swap] 来显式检查子形式：

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

使用此定义，@racket[(swap x 2)] 产生的 syntax error 来自 @racket[swap]
而不是 @racket[set!]。

在上面 @racket[swap] 的定义中，@racket[#'x] 和 @racket[#'y] 是 template，
即使它们没有被用作 macro transformer 的结果。这个例子说明了 template
如何用于访问输入 syntax 的各个部分，在这里用于检查这些部分的形式。
此外，@racket[#'x] 或 @racket[#'y] 的匹配结果被用于调用
@racket[raise-syntax-error]，使得 syntax-error 消息可以直接指向
非 identifier 的 source location。

@; ----------------------------------------

@section[#:tag "with-syntax"]{@racket[with-syntax] and @racket[generate-temporaries]}

由于 @racket[syntax-case] 允许我们使用任意 Racket 表达式进行计算，
我们可以更简单地解决在编写 @racket[define-for-cbr] 时遇到的问题
（参见 @secref["pattern-macro-example"]），在那里我们需要基于一个
@racket[id ...] 序列生成一组名称：

@racketblock[
(define-syntax (define-for-cbr stx)
  (syntax-case stx ()
    [(_ do-f (id ...) body)
     ....
       #'(define (do-f get ... put ...)
           (define-get/put-id id get put) ... 
           body) ....]))
]

我们需要将 @racket[get ...] 和 @racket[put ...] 绑定到生成的 identifier
的 list，以替代上面的 @racket[....]。我们不能使用 @racket[let] 来绑定
@racket[get] 和 @racket[put]，因为我们需要的是算作 pattern variable
的 binding，而不是普通的局部变量。@racket[with-syntax] 形式让我们
可以绑定 pattern variable：

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

现在我们需要一个替代 @racket[....] 的表达式，它生成的 identifier
数量与原始 pattern 中 @racket[id] 的匹配数量相同。由于这是一个
常见任务，Racket 提供了辅助函数 @racket[generate-temporaries]，
它接受一个 identifier 序列并返回一个生成的 identifier 序列：

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

这种生成 identifier 的方式通常比用纯 pattern-based 宏欺骗 macro expander
生成名称更容易理解。

通常，@racket[with-syntax] binding 的左侧就是一个 pattern，
就像在 @racket[syntax-case] 中一样。事实上，@racket[with-syntax]
形式只是一个部分由内而外的 @racket[syntax-case] 形式。

@; ----------------------------------------

@section[#:tag "stx-phases"]{Compile and Run-Time Phases}

随着宏集合变得越来越复杂，你可能希望编写自己的辅助函数，
例如 @racket[generate-temporaries]。例如，为了提供良好的
syntax error 消息，@racket[swap]、@racket[rotate] 和 @racket[define-cbr]
都应该检查源形式中的某些子形式是否为 identifier。我们可以在各处
使用 @racket[check-ids] 函数来执行此检查：

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

@racket[check-ids] 函数可以使用 @racket[syntax->list] 函数将包装 list
的 syntax object 转换为 syntax object 的 list：

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

然而，如果你以这种方式定义 @racket[swap] 和 @racket[check-ids]，
它是不会工作的：

@interaction[
#:eval check-eval
(let ([a 1] [b 2]) (swap a b))
]

问题在于 @racket[check-ids] 被定义为 run-time 表达式，但 @racket[swap]
试图在 compile time 使用它。在交互模式下，compile time 和 run time
是交错的，但它们在 module 体内不会交错，也不会在提前编译的
module 之间交错。为了帮助所有这些模式一致地对待代码，Racket
为不同的 phase 分离了 binding space。

要定义一个可以在 compile time 引用的 @racket[check-ids] 函数，
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

有了这个 for-syntax 定义，@racket[swap] 就可以工作了：

@interaction[
#:eval check-eval
(let ([a 1] [b 2]) (swap a b) (list a b))
(swap a 1)
]

当将程序组织为 module 时，你可能希望将辅助函数放在一个 module 中，
供其他 module 中的宏使用。在这种情况下，你可以使用 @racket[define]
编写辅助函数：

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

然后，在实现宏的 module 中，使用
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

由于 module 是单独编译的，且不能有循环依赖，@filepath["utils.rkt"]
module 的 run-time 主体可以在编译实现 @racket[swap] 的 module 之前
被编译。因此，@filepath["utils.rkt"] 中的 run-time 定义可以用于
实现 @racket[swap]，只要它们通过 @racket[(require (for-syntax ....))]
被显式地转移到 compile time。

@racketmodname[racket] module 提供了 @racket[syntax-case]、
@racket[generate-temporaries]、@racket[lambda]、@racket[if] 等，
供 run-time 和 compile-time phase 使用。这就是为什么我们可以在
@exec{racket} @tech{REPL} 中直接使用 @racket[syntax-case]，也可以在
@racket[define-syntax] 形式的右边使用它。

相比之下，@racketmodname[racket/base] module 只在 run-time phase
导出这些 binding。如果你将上面定义 @racket[swap] 的 module 改为使用
@racketmodname[racket/base] 语言而不是 @racketmodname[racket]，
那么它就不再工作了。添加 @racket[(require (for-syntax racket/base))]
会将 @racket[syntax-case] 等导入到 compile-time phase，使 module
再次工作。

假设 @racket[define-syntax] 用于在 @racket[define-syntax] 形式的右边
定义一个局部宏。在这种情况下，内部 @racket[define-syntax] 的右边
处于 @deftech{meta-compile phase level}，也称为 @deftech{phase level 2}。
要将 @racket[syntax-case] 导入该 phase level，你必须使用
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

负的 phase level 也存在。如果一个宏使用了一个被 @racket[for-syntax]
导入的辅助函数，并且该辅助函数返回由 @racket[syntax] 生成的
syntax-object 常量，那么 syntax 中的 identifier 就需要在
@deftech{phase level -1}（也称为 @deftech{template phase level}）
有 binding，相对于定义该宏的 module 的 run-time phase level 而言。

例如，下面例子中的 @racket[swap-stx] 辅助函数不是一个
syntax transformer——它只是一个普通函数——但它产生的 syntax object
会被拼接到 @racket[shell-game] 的结果中。因此，它所在的
@racket[helper] 子 module 需要在 @racket[shell-game] 的 phase 1
通过 @racket[(require (for-syntax 'helper))] 导入。

但从 @racket[swap-stx] 的角度来看，它的结果最终会在 phase level -1
被求值，即当 @racket[shell-game] 返回的 syntax 被求值时。
换句话说，负的 phase level 是从相反方向看的正的 phase level：
@racket[shell-game] 的 phase 1 是 @racket[swap-stx] 的 phase 0，
所以 @racket[shell-game] 的 phase 0 是 @racket[swap-stx] 的 phase -1。
这就是为什么这个例子不会工作——@racket['helper] 子 module
在 phase -1 没有任何 binding。

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

为了修复这个例子，我们向 @racket['helper] 子 module 添加
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
