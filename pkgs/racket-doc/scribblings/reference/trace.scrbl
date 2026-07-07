#lang scribble/doc
@(require "mz.rkt" (for-label racket/trace))

@(begin (define ev (make-base-eval))
        (ev '(require racket/trace))
        (ev '(require (for-syntax racket/base))))

@(begin (define ev1 (make-base-eval))
        (ev1 '(require racket/trace))
        (ev1 '(require (for-syntax racket/base))))

@title{追踪}

@note-lib-only[racket/trace]

@racketmodname[racket/trace] 库模拟了 Chez Scheme 中可用的追踪工具。

@defform[(trace id ...)]{

每个 @racket[id] 必须绑定到 @racket[trace] 表达式环境中的 procedure，且不能从其他 module 导入。每个 @racket[id] 被 @racket[set!] 为一个新 procedure，通过 @racket[current-trace-notify] 打印调用的参数和返回值来追踪 procedure 调用和返回。如果返回多个值，每个值从单独一行开始显示。

当被追踪的 procedure 相互调用时，嵌套调用通过打印嵌套前缀来显示。如果嵌套深度增长到十层及以上，则打印数字显示实际嵌套深度。

@racket[trace] 形式可用于已被追踪的标识符。在这种情况下，假设变量的值未改变，@racket[trace] 无效果。如果变量已更改为不同的 procedure，则安装新的追踪。

追踪尊重 tail call 以保留循环，但其效果可能通过 continuation mark 可见。当被追踪 procedure 的调用相对于之前的被追踪调用处于 tail position 时，调用的 tailness 被保留（并且调用的结果不会为 tail call 打印，因为相同结果会为外层调用打印）。然而，除此之外，被追踪 procedure 的 body 不会相对于该 procedure 的调用在 tail position 求值。

@racket[trace] 表达式的结果为 @|void-const|。

@examples[#:eval ev
(define (f x) (if (zero? x) 0 (add1 (f (sub1 x)))))
(trace f)
(f 10)
]

@racket[trace] 也可用于调试 @tech{syntax transformer}。直接使用 @racket[trace] 这样做很繁琐；参见 @racket[trace-define-syntax] 了解更简单的方法。

@examples[#:eval ev
(require (for-syntax racket/trace))
(begin-for-syntax
  (define _let
    (syntax-rules ()
      [(_ ([x v]) e) ((lambda (x) e) v)]))
  (trace _let))
(define-syntax let _let)

(let ([x 120]) x)
]

追踪 syntax transformer 时，修改 @racket[current-trace-print-args] 和 @racket[current-trace-print-results] 可能有助于使追踪输出更易读；参见 @racket[current-trace-print-args] 了解扩展示例。

}

@defform*[((trace-define id expr)
           (trace-define (head args) body ...+))]{

@racket[trace-define] 形式是先定义函数再追踪的简写。此形式支持所有 @racket[define] 形式。

@examples[#:eval ev
(trace-define (f x) (if (zero? x) 0 (add1 (f (sub1 x)))))
(f 5)
]

@examples[#:eval ev
(trace-define ((+n n) x) (+ n x))
(map (+n 5) (list 1 3 4))
]}

@defform*[((trace-define-syntax id expr)
           (trace-define-syntax (head args) body ...+))]{

@racket[trace-define-syntax] 形式是先定义 syntax transformer 再追踪的简写。此形式支持所有 @racket[define-syntax] 形式。

例如：

@examples[#:eval ev
(trace-define-syntax fact
  (syntax-rules ()
    [(_ x) 120]))
(fact 5)
]

默认情况下，@racket[trace] 追踪 syntax transformer 时会打印 syntax object。如果不需要查看 source information 等，这可能导致过多输出。通过修改 @racket[current-trace-print-args] 和 @racket[current-trace-print-results]，将 syntax object 打印为 datum 可以获得更易读的输出。参见 @racket[current-trace-print-args] 了解扩展示例。

}
@defform[(trace-lambda [#:name id] args expr)]{

@racket[trace-lambda] 形式启用对匿名函数的追踪。此形式将尝试使用 @racket[syntax-local-infer-name] 推断名称，或使用可选的 @racket[#:name] 参数指定名称。如果未给出名称且无法推断名称，则引发 syntax error。

@examples[#:eval ev
  ((trace-lambda (x) 120) 5)]}

@defform[(trace-let id ([arg expr] ...+) body ...+)]{

@racket[trace-let] 形式启用对 named let 的追踪。

@examples[#:eval ev
  (trace-let f ([x 5])
    (if (zero? x)
        1
        (* x (f (sub1 x)))))]}

@defform[(untrace id ...)]{

撤销 @racket[trace] 形式对每个 @racket[id] 的效果，将每个 @racket[id] @racket[set!] 回未追踪的 procedure，但仅当 @racket[id] 的当前值是被追踪的 procedure 时。如果 @racket[id] 的当前值不是由 @racket[trace] 安装的 procedure，则变量不变。

@racket[untrace] 表达式的结果为 @|void-const|。}


@defparam[current-trace-notify proc (string? . -> . any)]{

@tech{parameter}，决定追踪输出的显示方式。给 @racket[proc] 的字符串是一个追踪；它不以尾随换行结束，但可能包含内部换行。每个调用或结果使用 @racket[pretty-print] 转换为字符串。参数的默认值打印给定字符串后跟一个换行到 @racket[(current-output-port)]。}

@defproc[(trace-call [id symbol?] [proc procedure?]
                     [#:<kw> kw-arg any/c] ...) any/c]{

使用 @racket[args] 中提供的参数（可能还包括 keyword argument）调用 @racket[proc]。还在调用期间打印追踪信息，如上文 @racket[trace] 文档中所述，使用 @racket[id] 作为 @racket[proc] 的名称。

}

@defparam[current-trace-print-args trace-print-args
          (-> symbol?
              list?
              (listof keyword?)
              list?
              number?
              void?)]{

此参数的值被调用以打印被追踪调用的参数。它接收函数名称、函数的普通参数、keyword、keyword 的值以及指示调用深度的数字。

修改此参数和 @racket[current-trace-print-results] 在追踪 syntax transformer 时有助于获得更易读或额外的输出。例如，我们可以使用 @racketmodname[debug-scopes #:indirect] 向追踪添加 scope 信息（参见 @racketmodname[debug-scopes #:indirect] 了解示例），或移除 source location 信息以仅显示 syntax object 的形状。

在此示例中，我们通过存储当前 printer（@racket[ctpa] 和 @racket[ctpr]）来更新 @racket[current-trace-print-args] 和 @racket[current-trace-print-results]，以使用 @racket[syntax->datum] 将 syntax object 转换为 datum，然后将转换后的参数和结果传递给之前的 printer。追踪时，syntax 参数将不带 source location 信息显示，从而缩短输出。

@examples[#:eval ev
  (require (for-syntax racket/trace))
  (begin-for-syntax
    (current-trace-print-args
      (let ([ctpa (current-trace-print-args)])
        (lambda (s l kw l2 n)
          (ctpa s (map syntax->datum l) kw l2 n))))
    (current-trace-print-results
      (let ([ctpr (current-trace-print-results)])
        (lambda (s r n)
         (ctpr s (map syntax->datum r) n)))))

  (trace-define-syntax fact
    (syntax-rules ()
      [(_ x) 120]))
  (fact 5)]


修改这些参数时必须小心，特别是当转换对追踪标识符的参数/结果的类型做出假设或更改其类型时。此 @racket[current-trace-print-args] 和 @racket[current-trace-print-results] 的修改是命令式更新，将影响所有被追踪的标识符。此示例假设 @emph{所有被追踪函数} 的所有参数和结果都是 syntax object，这仅在您只追踪 syntax transformer 时才成立。如果按原样使用，上述代码在同时追踪函数和 syntax transformer 时可能导致类型错误。最好仅在参数或结果实际是 syntax object 时使用 @racket[syntax->datum]，例如通过如下定义 @racket[maybe-syntax->datum]。

@examples[#:eval ev1
  (require (for-syntax racket/trace))
  (begin-for-syntax
    (define (maybe-syntax->datum syn?)
      (if (syntax? syn?)
          (syntax->datum syn?)
          syn?))
    (current-trace-print-args
      (let ([ctpa (current-trace-print-args)])
        (lambda (s l kw l2 n)
          (ctpa s (map maybe-syntax->datum l) kw l2 n))))
    (current-trace-print-results
      (let ([ctpr (current-trace-print-results)])
        (lambda (s l n)
         (ctpr s (map maybe-syntax->datum l) n))))

  (trace-define (precompute-fact syn n) (datum->syntax syn (apply * (build-list n add1)))))
  (trace-define (run-time-fact n) (apply * (build-list n add1)))

  (require (for-syntax syntax/parse))
  (trace-define-syntax (fact syn)
    (syntax-parse syn
      [(_ x:nat) (precompute-fact syn (syntax->datum #'x))]
      [(_ x) #'(run-time-fact x)]))
  (fact 5)
  (fact (+ 2 3))]
}


@defparam[current-trace-print-results trace-print-results
          (-> symbol?
              list?
              number?
              any)]{

此参数的值被调用以打印被追踪调用的结果。它接收函数名称、函数的结果以及指示调用深度的数字。

}

@defparam[current-prefix-in prefix string?]{
  此字符串由 @racket[current-trace-print-args] 的默认值使用，指示当前行显示对被追踪函数的调用。

  默认为 @racket[">"]。
}


@defparam[current-prefix-out prefix string?]{
  此字符串由 @racket[current-trace-print-results] 的默认值使用，指示当前行显示被追踪调用的结果。

  默认为 @racket["<"]。
}


@close-eval[ev]
