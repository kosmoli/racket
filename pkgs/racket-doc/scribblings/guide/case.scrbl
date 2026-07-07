#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label racket/match))

@title[#:tag "case"]{Simple Dispatch: @racket[case]}

@racket[case] 形式通过将表达式的结果与子句中的值进行匹配来分派到相应的子句：

@specform[(case expr
            [(datum ...+) body ...+]
            ...)]

每个 @racket[_datum] 将使用 @racket[equal?] 与 @racket[_expr] 的结果进行比较，然后对相应的 @racket[body] 求值。@racket[case] 形式可以在 @math{O(log N)} 时间内对 @math{N} 个 @racket[datum] 分派到正确的子句。

每个子句可以提供多个 @racket[_datum]，如果其中任何一个 @racket[_datum] 匹配，则对相应的 @racket[_body] 求值。

@examples[
(let ([v (random 6)])
  (printf "~a\n" v)
  (case v
    [(0) 'zero]
    [(1) 'one]
    [(2) 'two]
    [(3 4 5) 'many]))
]

@racket[case] 形式的最后一个子句可以使用 @racket[else]，就像 @racket[cond] 一样：

@examples[
(case (random 6)
  [(0) 'zero]
  [(1) 'one]
  [(2) 'two]
  [else 'many])
]

如需更通用的模式匹配（但不保证分派时间），请使用 @racket[match]，相关内容在 @secref["match"] 中介绍。
