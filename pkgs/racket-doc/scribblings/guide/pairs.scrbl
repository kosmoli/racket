#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "pairs"]{Pair 和 List}

@deftech{pair} 将两个任意值组合在一起。@racket[cons] procedure 构造 pair，@racket[car] 和 @racket[cdr] procedure 提取 pair 的第一个和第二个元素。@racket[pair?] predicate 识别 pair。

一些 pair 打印时将两个 pair 元素用括号包裹，开头加 @litchar{'}，元素间加 @litchar{.}。

@examples[
(cons 1 2)
(cons (cons 1 2) 3)
(car (cons 1 2))
(cdr (cons 1 2))
(pair? (cons 1 2))
]

@deftech{list} 是创建 linked list 的 pair 组合。更准确地说，list 要么是空 list @racket[null]，要么是一个 pair，其第一个元素是 list 元素，第二个元素是 list。@racket[list?] predicate 识别 list。@racket[null?] predicate 识别空 list。

list 通常打印为 @litchar{'} 后跟一对括号，括号内是 list 元素。

@examples[
null
(cons 0 (cons 1 (cons 2 null)))
(list? null)
(list? (cons 1 (cons 2 null)))
(list? (cons 1 2))
]

当 list 或 pair 的元素之一不能作为 @racket[quote] 值打印时，list 或 pair 会使用 @racketresult[list] 或 @racketresult[cons] 打印。例如，用 @racket[srcloc] 构造的值不能使用 @racket[quote] 打印，它使用 @racketresult[srcloc]：

@interaction[
(srcloc "file.rkt" 1 0 1 (+ 4 4))
(list 'here (srcloc "file.rkt" 1 0 1 8) 'there)
(cons 1 (srcloc "file.rkt" 1 0 1 8))
(cons 1 (cons 2 (srcloc "file.rkt" 1 0 1 8)))
]

@margin-note{另见 @racket[list*]。}

如最后一个示例所示，@racketresult[list*] 用于缩写了不能用 @racketresult[list] 缩写的一系列 @racketresult[cons]。

@racket[write] 和 @racket[display] function 打印 pair 或 list 时不带前导 @litchar{'}、@racketresult[cons]、@racketresult[list] 或 @racketresult[list*]。对于 pair 或 list，@racket[write] 和 @racket[display] 之间没有区别，除了它们应用于 list 元素时：

@examples[
(write (cons 1 2))
(display (cons 1 2))
(write null)
(display null)
(write (list 1 2 "3"))
(display (list 1 2 "3"))
]

在 list 上最重要的预定义 procedure 是那些遍历 list 元素的 procedure：

@interaction[
(map (lambda (i) (/ 1 i))
     '(1 2 3))
(andmap (lambda (i) (i . < . 3))
       '(1 2 3))
(ormap (lambda (i) (i . < . 3))
       '(1 2 3))
(filter (lambda (i) (i . < . 3))
        '(1 2 3))
(foldl (lambda (v i) (+ v i))
       10
       '(1 2 3))
(for-each (lambda (i) (display i))
          '(1 2 3))
(member "Keys"
        '("Florida" "Keys" "U.S.A."))
(assoc 'where
       '((when "3:30") (where "Florida") (who "Mickey")))
]

@refdetails["pairs"]{pair 和 list}

Pair 是 immutable 的（与 Lisp 传统相反），@racket[pair?] 和 @racket[list?] 只识别 immutable pair 和 list。@racket[mcons] procedure 创建 @deftech{mutable pair}，它配合 @racket[set-mcar!]、@racket[set-mcdr!]、@racket[mcar] 和 @racket[mcdr] 使用。Mutable pair 打印使用 @racketresult[mcons]，而 @racket[write] 和 @racket[display] 使用 @litchar["{"] 和 @litchar["}"] 打印 mutable pair：

@examples[
(define p (mcons 1 2))
p
(pair? p)
(mpair? p)
(set-mcar! p 0)
p
(write p)
]

@refdetails["mpairs"]{mutable pair}
