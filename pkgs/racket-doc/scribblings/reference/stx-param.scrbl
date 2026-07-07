#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/stxparam racket/stxparam-exptime racket/splicing))

@(define the-eval (make-base-eval))
@(the-eval '(require racket/stxparam
                     (only-in racket/control abort)
                     (for-syntax racket/base)))

@title[#:tag "stxparam"]{语法参数}

@note-lib-only[racket/stxparam]

@defform[(define-syntax-parameter id expr)]{

将 @racket[id] 绑定为 syntax 到一个 @tech{syntax parameter}。
@racket[expr] 是 @tech{transformer environment} 中的一个表达式，
作为 @tech{syntax parameter} 的默认值。该值通常由 transformer 使用
@racket[syntax-parameter-value] 获得。

@racket[id] 可以与 @racket[syntax-parameterize] 或
@racket[syntax-parameter-value]（在 transformer 中）使用。如果 @racket[expr]
产生一个单参数的 procedure 或 @racket[make-set!-transformer] 结果，
则 @racket[id] 可以用作 macro。如果 @racket[expr] 产生一个
@racket[make-rename-transformer] 结果，则 @racket[id] 可以用作 macro，
展开为对目标标识符的使用，但 @racket[syntax-local-value] 的 @racket[id]
不产生目标的值。}

@defform[(syntax-parameterize ([id expr] ...) body-expr ...+)]{

@margin-note/ref{另请参见 @racket[splicing-syntax-parameterize]。}

每个 @racket[id] 必须绑定到使用 @racket[define-syntax-parameter] 定义的
@tech{syntax parameter}。每个 @racket[expr] 是 @tech{transformer environment}
中的一个表达式。在展开 @racket[body-expr] 期间，每个 @racket[expr] 的值
绑定到相应的 @racket[id]。

如果 @racket[expr] 产生一个单参数的 procedure 或 @racket[make-set!-transformer] 结果，
则在展开 @racket[body-expr] 期间其 @racket[id] 可以用作 macro。
如果 @racket[expr] 产生一个 @racket[make-rename-transformer] 结果，
则 @racket[id] 可以用作 macro，展开为对目标标识符的使用，
但 @racket[syntax-local-value] 的 @racket[id] 不产生目标的值。

@examples[#:eval the-eval
(define-syntax-parameter abort (syntax-rules ()))

(define-syntax forever
  (syntax-rules ()
    [(forever body ...)
     (call/cc (lambda (abort-k)
       (syntax-parameterize
           ([abort (syntax-rules () [(_) (abort-k)])])
         (let loop () body ... (loop)))))]))

(define-syntax-parameter it (syntax-rules ()))

(define-syntax aif
  (syntax-rules ()
    [(aif test then else)
     (let ([t test])
       (syntax-parameterize ([it (syntax-id-rules () [_ t])])
         (if t then else)))]))
]}

@defform[(define-rename-transformer-parameter id expr)]{

将 @racket[id] 绑定为 syntax 到一个 @tech{syntax parameter}，
该参数必须绑定到 @racket[make-rename-transformer] 结果，并且与
@racket[define-syntax-parameter] 不同，@racket[id] 的
@racket[syntax-local-value] @emph{确实} 产生目标的值，包括在
@racket[syntax-parameterize] 内。

@examples[#:eval the-eval #:escape UNSYNTAX
 (define-syntax (test stx)
  (syntax-case stx ()
    [(_ t)
     #`#,(syntax-local-value #'t)]))
 (define-syntax one 1)
 (define-syntax two 2)
 (define-syntax-parameter not-num
   (make-rename-transformer #'one))
 (test not-num)

 (define-rename-transformer-parameter num
   (make-rename-transformer #'one))
 (test num)
 (syntax-parameterize ([num (make-rename-transformer #'two)])
   (test num))
]}

@history[#:added "6.3.0.14"]

@; ----------------------------------------------------------------------

@section{Syntax Parameter Inspection}

@defmodule*/no-declare[(racket/stxparam-exptime)]

@declare-exporting[racket/stxparam-exptime racket/stxparam]

@defproc[(syntax-parameter-value [id-stx syntax?]) any]{

此过程旨在用于 @tech{transformer environment}，其中 @racket[id-stx]
是在普通环境中绑定到 @tech{syntax parameter} 的标识符。
结果是 @tech{syntax parameter} 的当前值，经过 @racket[syntax-parameterize]
形式的调整。

此绑定由 @racketmodname[racket/stxparam] 提供 @racket[for-syntax]，
因为它通常在 transformer 中使用。由 @racketmodname[racket/stxparam-exptime]
正常提供。}


@defproc[(make-parameter-rename-transformer [id-stx syntax?]) any]{

此过程旨在用于 transformer 中，其中 @racket[id-stx]
是绑定到 @tech{syntax parameter} 的标识符。结果是一个 transformer，
其行为与 @racket[id-stx] 相同，但不能与 @racket[syntax-parameterize]
或 @racket[syntax-parameter-value] 一起使用。

使用 @racket[make-parameter-rename-transformer] 类似于调用一个调用 parameter 的过程。
这样的过程可以导出给他人以允许访问 parameter 值，但不改变它。类似地，
@racket[make-parameter-rename-transformer] 允许 @tech{syntax parameter}
用作 macro，但不能更改。

@racket[make-parameter-rename-transformer] 的结果不会被
@racket[syntax-local-value] 特殊处理，这与 @racket[make-rename-transformer]
的结果不同。

此绑定由 @racketmodname[racket/stxparam] 提供 @racket[for-syntax]，
因为它通常在 transformer 中使用。由 @racketmodname[racket/stxparam-exptime]
正常提供。}

@(close-eval the-eval)
