#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label racket/undefined
                     racket/shared))

@title[#:tag "void+undefined"]{Void 和 Undefined}

某些过程或表达式形式不需要返回值。例如，@racket[display] 过程仅为了写入输出的副作用而被调用。在这种情况下，结果值通常是一个打印为 @|void-const| 的特殊常量。当表达式的结果仅为 @|void-const| 时，@tech{REPL} 不会打印任何内容。

@racket[void] 过程接受任意数量的参数并返回 @|void-const|。（也就是说，标识符 @racketidfont{void} 绑定到返回 @|void-const| 的过程，而非直接绑定到 @|void-const|。）

@examples[
(void)
(void 1 2 3)
(list (void))
]

@racket[undefined] 常量（打印为 @|undefined-const|）有时被用作值尚不存在的引用的结果。在 Racket 的旧版本中（6.1 版本之前），过早引用局部绑定会产生 @|undefined-const|；而现在的过早引用会抛出异常。

@margin-note{在某些情况下，@racket[undefined] 结果仍可由 @racket[shared] 形式产生。}

@def+int[
(define (fails)
  (define x x)
  x)
(fails)
]
