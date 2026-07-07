#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label racket/match))

@(begin
  (define match-eval (make-base-eval))
  (interaction-eval #:eval match-eval (require racket/match)))

@title[#:tag "match"]{Pattern Matching}

@hash-lang-note[racket/match #:lang racket/base]

@racket[match] 形式支持对任意 Racket 值进行模式匹配，这不同于像 @racket[regexp-match] 这样将正则表达式与字节和字符序列进行比较的函数（参见 @secref["regexp"]）。

@specform[
(match target-expr
  [pattern expr ...+] ...)
]

@racket[match] 形式获取 @racket[target-expr] 的结果，并按顺序尝试匹配每个 @racket[_pattern]。一旦找到匹配，就对相应的 @racket[_expr] 序列求值以获得 @racket[match] 表达式的结果。如果 @racket[_pattern] 包含@deftech{模式变量}，则它们被视为通配符，每个变量在 @racket[_expr] 中绑定到它所匹配的输入片段。

大多数 Racket 字面表达式可以用作模式：

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

像 @racket[cons]、@racket[list] 和 @racket[vector] 这样的构造器可以用来创建匹配 pair、list 和 vector 的模式：

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

用 @racket[struct] 绑定的构造器也可以用作模式构造器：

@interaction[
#:eval match-eval
(struct shoe (size color))
(struct hat (size style))
(match (hat 23 'bowler)
 [(shoe 10 'white) "bottom"]
 [(hat 23 'bowler) "top"])
]

模式中不带引号的、非构造器的标识符是@tech{模式变量}，它们在结果表达式中被绑定，但 @racket[_] 除外，它不进行绑定（因此通常用作通配符）：

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

请注意，标识符 @racket[else] @bold{不是}一个保留的通配符（像 @racket[_] 那样）。如果 @racket[else] 出现在模式中，那么它来自 @racketmodname[racket/base] 的绑定可能会被遮蔽，这会导致 @racket[cond] 和 @racket[case] 出现问题。

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

要匹配绑定到标识符的值，请使用 @racket[==]。

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
   (code:comment @#,t{without @racket[==], @racket[val] is a pattern variable})
   (format "match binds val to ~a" val)])
]

省略号写作 @litchar{...}，在 list 或 vector 模式中的作用类似于 Kleene 星号：前面的子模式可以用于匹配任意次数的连续元素。如果省略号后面的子模式包含模式变量，则该变量会匹配多次，并在结果表达式中绑定到一个匹配结果列表：

@interaction[
#:eval match-eval
(match '(1 1 1)
  [(list 1 ...) 'ones]
  [_ 'other])
(match '(1 1 2)
  [(list 1 ...) 'ones]
  [_ 'other])
(match '(1 2 3 4)
  [(list 1 x ... 4) x])
(match (list (hat 23 'bowler) (hat 22 'pork-pie))
  [(list (hat sz styl) ...) (apply + sz)])
]

省略号可以嵌套以匹配嵌套的重复，在这种情况下，模式变量可以绑定到匹配结果的嵌套列表：

@interaction[
#:eval match-eval
(match '((! 1) (! 2 2) (! 3 3 3))
  [(list (list '! x ...) ...) x])
]


@racket[quasiquote] 形式（有关更多信息请参见 @secref["qq"]）也可以用来构建模式。在普通的 quasiquote 形式中，不带引号的部分意味着正常的 Racket 求值，但在这里，不带引号的部分表示回到正常的模式匹配。

因此，在下面的示例中，with 表达式是模式，它被重写为应用表达式，第一个实例中使用 quasiquote 作为模式，第二个实例中使用 quasiquote 来构建表达式。

@interaction[
#:eval match-eval
(match `{with {x 1} {+ x 1}}
  [`{with {,id ,rhs} ,body}
   `{{lambda {,id} ,body} ,rhs}])
]

有关更多模式形式的信息，请参见 @racketmodname[racket/match]。

像 @racket[match-let] 和 @racket[match-lambda] 这样的形式在原本必须是标识符的位置支持模式。例如，@racket[match-let] 将 @racket[let] 推广为@as-index{解构绑定}：

@interaction[
#:eval match-eval
(match-let ([(list x y z) '(1 2 3)])
  (list z y x))
]

有关这些附加形式的信息，请参见 @racketmodname[racket/match]。

@refdetails["match"]{pattern matching}

@close-eval[match-eval]
