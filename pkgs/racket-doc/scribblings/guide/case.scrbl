#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label racket/match))

@title[#:tag "case"]{简单分发：@racket[case]}

@racket[case] 形式通过将表达式的结果与子句的值匹配来分发到子句：

@specform[(case expr
            [(datum ...+) body ...+]
            ...)]

每个 @racket[_datum] 将使用 @racket[equal?] 与 @racket[_expr] 的结果进行比较，
然后评估对应的 @racket[body]。@racket[case] 形式可以在 @math{O(log N)} 时间内
分配到正确的子句，其中 N 为 @racket[_datum] 的数量。

每个子句可以提供多个 @racket[_datum]，如果任何 @racket[_datum] 匹配，
则评估对应的 @racket[_body]。

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

对于更通用的模式匹配（但没有分发时间保证），使用 @racket[match]，在
@secref["match"] 中介绍。