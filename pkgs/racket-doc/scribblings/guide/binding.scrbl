#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "binding"]{Identifiers and Binding}

表达式的上下文决定了表达式中出现的 identifier 的含义。特别地，以语言 @racketmodname[racket] 开始一个模块时，例如

@racketmod[racket]

意味着在模块内部，本指南中描述的 identifier 从这里开始具有这里描述的含义：@racket[cons] 指的是创建 pair 的 function，@racket[car] 指的是提取 pair 第一个元素的 function，等等。

@guideother{@secref["symbols"] 介绍了 identifier 的 syntax。}

像 @racket[define]、@racket[lambda] 和 @racket[let] 这样的形式将一个含义与一个或多个 identifier 关联起来；也就是说，它们 @defterm{bind} 了标识符。绑定适用的程序部分称为该绑定的 @defterm{scope}。在给定表达式中有效的一组绑定称为表达式的 @defterm{环境}。

例如，在

@racketmod[racket

(define f (lambda (x)
               (let ([y 5])
                    (+ x y))))

(f 10)
]

中，@racket[define] 绑定了 @racket[f]，@racket[lambda]
绑定了 @racket[x]，而 @racket[let] 绑定了 @racket[y]。@racket[f] 的绑定 scope 是整个模块；@racket[x] 的绑定 scope 是 @racket[(let ([y 5]) (+ x y))]；@racket[y] 的绑定 scope 则是 @racket[(+ x y)]。@racket[(+ x y)] 的环境包括 @racket[y]、@racket[x] 和 @racket[f] 的绑定，以及 @racketmodname[racket] 中的所有内容。

模块级 @racket[define] 仅能绑定模块内未定义过的 identifier 或未 @racket[require] 过的 identifier。然而，局部 @racket[define] 或其它绑定形式可以为已有绑定的 identifier 赋予新的局部绑定；这样的绑定会 @deftech{遮蔽}（shadow）掉已有的绑定。

@defexamples[
(define f
  (lambda (append)
    (define cons (append "ugly" "confusing"))
    (let ([append 'this-was])
      (list append cons))))
(f list)
]

同样地，模块级 @racket[define] 可以 @deftech{遮蔽}从模块语言中导入的绑定。例如，@racketmodname[racket] 模块中的 @racket[(define cons 1)] 会遮蔽 @racketmodname[racket] 提供的 @racket[cons]。故意遮蔽语言绑定通常并不是一个好主意——特别是像 @racket[cons] 这类广泛使用的绑定——但遮蔽让程序员可以无需避免语言所提供的每一个冷僻绑定。

即便是 @racket[define] 和 @racket[lambda] 这类标识符，它们的含义也来自于绑定，不过它们拥有 @defterm{transformer} 绑定（即表示某种语法形式），而非值绑定。由于 @racket[define] 有 transformer 绑定，identifier @racketidfont{define} 不能直接用于获取一个值。不过 @racketidfont{define} 的常规绑定是可以被遮蔽的。

@examples[
define
(eval:alts (let ([@#,racketidfont{define} 5]) @#,racketidfont{define}) (let ([define 5]) define))
]

同样地，像这样遮蔽标准语言绑定通常不是好主意，而这一可能性是 Racket 灵活性的固有部分。
