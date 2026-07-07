#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt" "modfile.rkt"
          (for-label racket/date))

@title[#:tag "module-languages"]{Module Languages}

当使用详细形式的 @racket[module] 来编写模块时，新模块名称之后指定的模块路径为该模块提供初始导入。由于初始导入模块甚至决定了模块主体中可用的最基本的绑定（如 @racket[require]），因此初始导入可以称为 @deftech{module language}（模块语言）。

最常见的 @tech{module language} 是 @racketmodname[racket] 或 @racketmodname[racket/base]，但你可以通过定义一个适当的模块来定义自己的 @tech{module language}。例如，使用 @racket[provide] 子形式如 @racket[all-from-out]、@racket[except-out] 和 @racket[rename-out]，你可以从 @racketmodname[racket] 中添加、删除或重命名绑定，以产生一个 @racketmodname[racket] 变体的 @tech{module language}：

@guideother{@secref["module-syntax"] 介绍了详细形式的 @racket[module]。}

@interaction[
(module raquet racket
  (provide (except-out (all-from-out racket) lambda)
           (rename-out [lambda function])))
(module score 'raquet
  (map (function (points) (case points
                           [(0) "love"] [(1) "fifteen"]
                           [(2) "thirty"] [(3) "forty"]))
       (list 0 2)))
(require 'score)
]

@; ----------------------------------------
@section[#:tag "implicit-forms"]{Implicit Form Bindings}

如果你在定义自己的 @tech{module language} 时尝试从 @racketmodname[racket] 中删除太多内容，则生成的模块将不再能正常作为 @tech{module language} 工作：

@interaction[
(module just-lambda racket
  (provide lambda))
(module identity 'just-lambda
  (lambda (x) x))
]

@racket[#%module-begin] 形式是一个隐式形式，它包装模块的主体。要作为 @tech{module language} 使用的模块必须提供它：

@interaction[
(module just-lambda racket
  (provide lambda #%module-begin))
(module identity 'just-lambda
  (lambda (x) x))
(require 'identity)
]

@racket[racket/base] 提供的其他隐式形式包括用于函数调用的 @racket[#%app]、用于字面量的 @racket[#%datum] 和用于没有绑定的标识符的 @racket[#%top]：

@interaction[
(module just-lambda racket
  (provide lambda #%module-begin
           (code:comment @#,t{@racketidfont{ten} needs these, too:})
           #%app #%datum))
(module ten 'just-lambda
  ((lambda (x) x) 10))
(require 'ten)
]

隐式形式如 @racket[#%app] 可以在模块中显式使用，但它们的存在主要是为了让模块语言能够限制或更改隐式使用的含义。例如，一个 @racket[lambda-calculus] @tech{module language} 可能会将函数限制为单个参数，将函数调用限制为提供单个参数，将模块主体限制为单个表达式，禁止字面量，并将未绑定的标识符视为未解释的符号：

@interaction[
(module lambda-calculus racket
  (provide (rename-out [1-arg-lambda lambda]
                       [1-arg-app #%app]
                       [1-form-module-begin #%module-begin]
                       [no-literals #%datum]
                       [unbound-as-quoted #%top]))
  (define-syntax-rule (1-arg-lambda (x) expr)
    (lambda (x) expr))
  (define-syntax-rule (1-arg-app e1 e2)
    (#%app e1 e2))
  (define-syntax-rule (1-form-module-begin e)
    (#%module-begin e))
  (define-syntax (no-literals stx)
    (raise-syntax-error #f "no" stx))
  (define-syntax-rule (unbound-as-quoted . id)
    'id))
(module ok 'lambda-calculus
  ((lambda (x) (x z))
   (lambda (y) y)))
(require 'ok)
(module not-ok 'lambda-calculus
  (lambda (x y) x))
(module not-ok 'lambda-calculus
  (lambda (x) x)
  (lambda (y) (y y)))
(module not-ok 'lambda-calculus
  (lambda (x) (x x x)))
(module not-ok 'lambda-calculus
  10)
]

模块语言很少重新定义 @racket[#%app]、@racket[#%datum] 和 @racket[#%top]，但重新定义 @racket[#%module-begin] 更为常用。例如，当使用模块来构造 HTML 页面描述（其中描述从模块中以 @racketidfont{page} 名称导出）时，替代的 @racket[#%module-begin] 可以帮助消除 @racket[provide] 和 quasiquote 样板代码，如 @filepath{html.rkt} 中所示：

@racketmodfile["html.rkt"]

使用 @filepath{html.rkt} @tech{module language}，可以描述一个简单的网页，而无需显式定义或导出 @racketidfont{page}，并且以 @racket[quasiquote] 模式而非表达式模式开始：

@interaction[
(module lady-with-the-spinning-head "html.rkt"
  (title "Queen of Diamonds")
  (p "Updated: " ,(now)))
(require 'lady-with-the-spinning-head)
page
]

@; ----------------------------------------
@section[#:tag "s-exp"]{Using @racket[@#,hash-lang[] @#,racketmodname[s-exp]]}

在 @hash-lang[] 层面实现一种语言比声明单个模块更复杂，因为 @hash-lang[] 允许程序员控制语言的多个不同方面。然而，@racketmodname[s-exp] 语言充当一种元语言，用于通过 @hash-lang[] 简写形式使用 @tech{module language}：

@racketmod[
s-exp _module-name
_form ...]

等同于

@racketblock[
(module _name _module-name
  _form ...)
]

其中 @racket[_name] 源自包含 @hash-lang[] 程序的源文件。名称 @racketmodname[s-exp] 是 "@as-index{S-expression}" 的缩写，这是 Racket 的 @tech{reader} 层词法约定的传统名称：括号、标识符、数字、带特定反斜杠转义的双引号字符串等等。

使用 @racket[@#,hash-lang[] @#,racketmodname[s-exp]]，之前的 @racket[lady-with-the-spinning-head] 示例可以更简洁地写成：

@racketmod[
s-exp "html.rkt"

(title "Queen of Diamonds")
(p "Updated: " ,(now))
]

在本指南后面的 @secref["hash-languages"] 中介绍了如何定义自己的 @hash-lang[] 语言，但首先我们解释如何编写 Racket 的 @tech{reader} 层扩展。
