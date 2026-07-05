#lang scribble/doc
@(require "mz.rkt" scribble/struct racket/shared (for-label racket/shared racket/undefined))


@(define shared-eval (make-base-eval))
@examples[#:hidden #:eval shared-eval (require racket/shared)]

@(define maker
   (make-element #f (list
                     (racketvarfont "prefix:")
                     (racketidfont "make-")
                     (racketvarfont "id"))))
@(define typedef
   (make-element #f (list
                     (racketvarfont "prefix:")
                     (racketvarfont "id"))))

@title[#:tag "shared"]{构建图：@racket[shared]}

@note-lib[racket/shared]

@defform[(shared ([id expr] ...) body ...+)]{

根据 @racket[expr]s 绑定具有共享结构的 @racket[id]s，然后求值 @racket[body]s，返回最后一个 expression 的结果。

@racket[shared] form 类似于 @racket[letrec]，区别在于 @racket[expr] 的某些特殊形式（在部分 macro 展开之后）被识别出来，用于构建 graph 结构的数据；而对应的 @racket[letrec] 则会抛出一个 use-before-initialization 错误。

每个 @racket[expr]（在部分展开后）匹配下面的 @racket[_shared-expr] 语法，一个 production 中较早的变体优先于较晚的变体：

@racketgrammar*[
#:literals (cons list list* append vector-immutable box-immutable mcons vector box)
[shared-expr shell-expr
             plain-expr]
[shell-expr (cons in-immutable-expr in-immutable-expr)
            (list in-immutable-expr ...)
            (list* in-immutable-expr ...)
            (append early-expr ... in-immutable-expr)
            (vector-immutable in-immutable-expr ...)
            (box-immutable in-immutable-expr)
            (mcons patchable-expr patchable-expr)
            (vector patchable-expr ...)
            (box patchable-expr)
            (@#,|maker| patchable-expr ...)]
[in-immutable-expr shell-id
                   shell-expr
                   early-expr]
[shell-id id]
[patchable-expr expr]
[early-expr expr]
[plain-expr expr]
]

上述 @|maker| 标识符匹配三种引用。第一种是名称中含有 @racketidfont{make-} 的绑定，且 @|typedef| 具有指向 structure 信息的 @tech{transformer} 绑定，该 structure 信息包含完整的 mutator 绑定集合；参见 @secref["structinfo"]。第二种是自身具有指向 structure 信息的 @tech{transformer} 绑定的标识符。第三种是具有值为某个标识符的 @racket['constructor-for] @tech{syntax property} 的标识符，而该标识符又具有指向 structure 信息的 @tech{transformer} 绑定。@racket[_shell-id] 则必须是由 @racket[shared] form 绑定到 @racket[_shell-expr] 之一的某个 @racket[id]。

当 @racket[expr]s 被解析为 @racket[_shared-expr] 时（在解析时考虑变体的顺序以确定优先级），经由 @racket[_early-expr] 解析的子表达式将在 @racket[shared] form 求值时最先被求值。在这些表达式中，它们按照在 @racket[shared] form 中出现的顺序求值。然而，对由 @racket[shared] 绑定的 @racket[id] 的任何引用都会产生 use-before-initialization 错误，即使该 @racket[id] 的绑定出现在对应的 @racket[_early-expr] 之前。

接下来有效地求值 @racket[_shell-id]s 和 @racket[_shell-expr]s（不计入 @racket[_patchable-expr] 和 @racket[_early-expr] 子表达式）：

@itemlist[

@item{@racket[_shell-id] 引用产生与对应 @racket[_id] 在 @racket[body]s 中将产生的相同值，前提是 @racket[_id] 从未被 @racket[set!] 修改。@racket[_shell-id] 引用的这种特殊处理方式是 @racket[shared] 支持创建循环数据（包括不可变循环数据）的一种方式。}

 @item{形式为 @racket[(mcons
        _patchable-expr _patchable-expr)], @racket[(vector _patchable-expr
        ...)], @racket[(box _patchable-expr)], 或 @racket[(@#,|maker|
        _patchable-expr ...)] 的 @racket[_shell-expr] 产生一个可变值，其内容位置初始化为 @racket[undefined]。每个内容位置在对应的 @racket[_patchable-expr] 表达式稍后求值后被 @deftech{修补}（即更新）。}

]

接下来，@racket[_plain-expr]s 按照 @racket[letrec] 的方式求值，如果 @racket[id] 的引用在其绑定右侧之前被求值，则抛出 @racket[exn:fail:contract:variable]。

最后，@racket[_patchable-expr]s 被求值，它们的值替换 @racket[_shell-expr]s 结果中的 @racket[undefined]。此时所有 @racket[id]s 都已绑定，因此 @racket[_patchable-expr]s 可以创建数据循环（但只能通过 mutation 创建的循环）。

@examples[
#:eval shared-eval
(shared ([a (cons 1 a)])
  a)
(shared ([a (cons 1 b)]
         [b (cons 2 a)])
  a)
(shared ([a (cons 1 b)]
         [b 7])
  a)
(eval:error (shared ([a a]) (code:comment @#,t{没有间接引用……})
              a))
(eval:error (shared ([a (cons 1 b)] (code:comment @#,t{@racket[b] 是 early……})
                     [b a])
              a))
(shared ([a (mcons 1 b)] (code:comment @#,t{@racket[b] 是 patchable……})
        [b a])
  a)
(shared ([a (vector b b b)]
         [b (box 1)])
  (set-box! b 5)
  a)
(shared ([a (box b)]
         [b (vector (unbox a)   (code:comment @#,t{@racket[unbox] 在 @racket[a] 被修补后})
                    (unbox c))] (code:comment @#,t{@racket[unbox] 在 @racket[c] 被修补前})
         [c (box b)])
  b)
]}


@; ----------------------------------------------------------------------

@close-eval[shared-eval]
