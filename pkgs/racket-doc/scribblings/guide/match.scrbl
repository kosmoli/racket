#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label racket/match))

@(begin
  (define match-eval (make-base-eval))
  (interaction-eval #:eval match-eval (require racket/match)))

@title[#:tag "match"]{Mode Matching}

@hash-lang-note[racket/match #:lang racket/base]

@racket[match] form 支持对任意 Racket 值进行 mode matching，而 @racket[regexp-match] 等函数则比较正则表达式与字节和字符序列（参见 @secref["regexp"]）。

@specform[
(match target-expr
  [pattern expr ...+] ...)
]

@racket[match] form 获取 @racket[target-expr] 的结果，并尝试按顺序匹配每个 @racket[_pattern]。一旦找到匹配，它就求值对应的 @racket[_expr] 序列以获得 @racket[match] form 的结果。如果 @racket[_pattern] 包含 @deftech{mode variable}，它们将被视为通配符，并且每个 variable 都绑定到它所匹配的输入片段。

大多数 Racket 字面量表达式都可以用作 mode：

@interaction[
#:eval match-eval
(match 2
  [1 'one]
  [2 'two]
  [3 'three])
(match #f
  [#t 'yes]
  [#f 'no])
(match "apple"
  ['apple 'symbol]
  ["apple" 'string]
  [#f 'boolean])
]

Constructor（如 @racket[cons]、@racket[list] 和 @racket[vector]）可用于创建匹配 pair、list 和 vector 的 mode：

@interaction[
#:eval match-eval
(match '(1 2)
  [(list 0 1) 'one]
  [(list 1 2) 'two])
(match '(1 . 2)
  [(list 1 2) 'list]
  [(cons 1 2) 'pair])
(match #(1 2)
  [(list 1 2) 'list]
  [(vector 1 2) 'vector])
]

用 @racket[struct] 绑定的 constructor 也可以用作 mode constructor：

@interaction[
#:eval match-eval
(struct shoe (size color))
(struct hat (size style))
(match (hat 23 'bowler)
 [(shoe 10 'white) "bottom"]
 [(hat 23 'bowler) "top"])
]

模式中未加引号的、非 constructor 的 identifier 是 @tech{mode variable}，它们在结果表达式中绑定，但 @racket[_] 除外，它不绑定（因此通常用作 catch-all）：

@interaction[
#:eval match-eval
(match '(1)
  [(list x) (+ x 1)]
  [(list x y) (+ x y)])
(match '(1 2)
  [(list x) (+ x 1)]
  [(list x y) (+ x y)])
(match (hat 23 'bowler)
  [(shoe sz col) sz]
  [(hat sz stl) sz])
(match (hat 11 'cowboy)
  [(shoe sz 'black) 'a-good-shoe]
  [(hat sz 'bowler) 'a-good-hat]
  [_ 'something-else])
]

注意，identifier @racket[else] @bold{不是} catch-all 保留字（像 @racket[_] 那样）。如果 @racket[else] 出现在模式中，则它来自 @racketmodname[racket/base] 的绑定可能会被遮蔽，这可能导致 @racket[cond] 和 @racket[case] 出现问题。

@interaction[
#:eval match-eval
(match 1
  [else
   (case 2
     [(a 1 b) 3]
     [else 4])])
(match #f
  [else
   (cond
     [#f 'not-evaluated]
     [else 'also-not-evaluated])])
]

要与绑定到 identifier 的值进行匹配，请使用 @racket[==]。

@interaction[
#:eval match-eval
(define val 42)
(match (list 42)
  [(list (== val)) 'matched])
(match (list 43)
  [(list (== val)) 'not-matched]
  [_ 'this-branch-is-evaluated])
(match (list 43)
  [(list val)
   (code:comment @#,t{没有 @racket[==]，@racket[val] 是 mode variable})
   (format "match binds val to ~a" val)])
]

省略号（ellipsis），写作 @litchar{...}，在 list 或 vector mode 中充当 Kleene 星号：前面的子模式可用于匹配任意次数以匹配 list 或 vector 中任意数量的连续元素。如果省略号前的子模式包含 mode variable，则 variable 匹配多次，并在结果表达式中绑定到匹配列表：

@interaction[
#:eval match-eval
(match '(1 1 1)
  [(list 1 ...) 'ones]
  [_ 'other])
(match '(1 1 2)
  [(list 1 ...) 'ones]
  [_ 'other])
(match '(1 2 3 4)
  [(list 1 x ...) x])
(match (list (hat 23 'bowler) (hat 22 'pork-pie))
  [(list (hat sz styl) ...) (apply + sz)])
]

省略号可以嵌套以匹配嵌套重复，在这种情况下，mode variable 可以绑定到匹配列表的列表：

@interaction[
#:eval match-eval
(match '((! 1) (! 2 2) (! 3 3 3))
  [(list (list '! x ...) ...) x])
]


@racket[quasiquote] form（参见 @secref["qq"] 了解更多信息）也可用于构建 mode。虽然普通 quasiquote form 中未引用的部分表示常规 racket 求值，但在这里，未引用的部分表示返回到常规 mode 匹配。

因此，在下面的示例中，with expression 是 mode，它被重写为 application expression，在第一个实例中用作模式，在第二个实例中用于构建 expression。

@interaction[
#:eval match-eval
(match `{with {x 1} {+ x 1}}
  [`{with {,id ,rhs} ,body}
   `{{lambda {,id} ,body} ,rhs}])
]

有关许多其他 mode form 的信息，请参见 @racketmodname[racket/match]。

@racket[match-let] 和 @racket[match-lambda] 等 form 支持在原本必须是 identifier 的位置使用 mode。例如，@racket[match-let] 将 @racket[let] 泛化为 @as-index{destructing bind}：

@interaction[
#:eval match-eval
(match-let ([(list x y z) '(1 2 3)])
  (list z y x))
]

有关这些附加 form 的信息，请参见 @racketmodname[racket/match]。

@refdetails["match"]{mode matching}

@close-eval[match-eval]
