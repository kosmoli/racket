#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt" "modfile.rkt"
          (for-label racket/date))

@title[#:tag "module-languages"]{Module 语言}

当使用长格式 @racket[module] 形式编写模块时，在新模块名称之后指定的模块路径为该模块提供初始导入。由于初始导入模块甚至决定了模块主体中最基本的绑定（如 @racket[require]），因此初始导入可以称为 @deftech{module language}。

最常见的 @tech{module language} 是 @racketmodname[racket] 或 @racketmodname[racket/base]，但你可以通过定义合适的模块来定义自己的 @tech{module language}。例如，使用 @racket[provide] 子形式如 @racket[all-from-out]、@racket[except-out] 和 @racket[rename-out]，你可以从 @racketmodname[racket] 添加、删除或重命名绑定，以产生一个 @racketmodname[racket] 的变体 @tech{module language}：

@guideother{@secref["module-syntax"] 介绍了长格式 @racket[module] 形式。}

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
@section[#:tag "implicit-forms"]{隐式形式绑定}

如果在定义自己的 @tech{module language} 时从 @racketmodname[racket] 删除了太多内容，则生成的模块将不再作为 @tech{module language} 正确工作：

@interaction[
(module just-lambda racket
  (provide lambda))
(module identity 'just-lambda
  (lambda (x) x))
]

@racket[#%module-begin] 形式是一种隐式形式，用于包装模块的主体。要用作 @tech{module language} 的模块必须提供它：

@interaction[
(module just-lambda racket
  (provide lambda #%module-begin))
(module identity 'just-lambda
  (lambda (x) x))
(require 'identity)
]

@racket[racket/base] 提供的其他隐式形式是：用于函数调用的 @racket[#%app]、用于字面量的 @racket[#%datum] 和用于无绑定的标识符的 @racket[#%top]：

@interaction[
(module just-lambda racket
  (provide lambda #%module-begin
           (code:comment @#,t{@racketidfont{ten} 也需要这些：})
           #%app #%datum))
(module ten 'just-lambda
  ((lambda (x) x) 10))
(require 'ten)
]

隐式形式如 @racket[#%app] 可以在模块中显式使用，但它们的存在主要是允许模块语言限制或更改隐式使用的含义。例如，@racket[lambda-calculus] @tech{module language} 可能限制函数为单参数、限制函数调用提供单个参数、限制模块主体为单个表达式、禁止字面量，并将未绑定标识符视为未解释的符号：

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

模块语言很少重新定义 @racket[#%app]、@racket[#%datum] 和 @racket[#%top]，但重新定义 @racket[#%module-begin] 更常用。例如，当使用模块构建 HTML 页面描述时，其中描述作为 @racketidfont{page} 从模块导出，替代的 @racket[#%module-begin] 可以帮助消除 @racket[provide] 和准引用的样板，如 @filepath{html.rkt} 中所示：

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
@section[#:tag "s-exp"]{使用 @racket[@#,hash-lang[] @#,racketmodname[s-exp]]}

在 @hash-lang[] 级别实现语言比声明单个模块更复杂，因为 @hash-lang[] 让程序员控制语言的多个不同方面。然而，@racketmodname[s-exp] 语言充当一种元语言，用于将 @tech{module language} 与 @hash-lang[] 简写一起使用：

@racketmod[
s-exp _module-name
_form ...]

等同于

@racketblock[
(module _name _module-name
  _form ...)]

其中 @racket[_name] 从包含 @hash-lang[] 程序的源文件派生。名称 @racketmodname[s-exp] 是 "@as-index{S-expression}" 的缩写，这是 Racket @tech{reader} 级词法约定的传统名称：括号、标识符、数字、带某些反斜杠转义的双引号字符串等。

使用 @racket[@#,hash-lang[] @#,racketmodname[s-exp]]，之前的 @racket[lady-with-the-spinning-head] 示例可以更紧凑地写为：

@racketmod[
s-exp "html.rkt"

(title "Queen of Diamonds")
(p "Updated: " ,(now))
]

在本指南的后面，@secref["hash-languages"] 解释了如何定义自己的 @hash-lang[] 语言，但首先我们解释如何编写 Racket 的 @tech{reader} 级扩展。
