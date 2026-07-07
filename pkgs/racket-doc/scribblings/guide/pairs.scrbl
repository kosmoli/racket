#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "pairs"]{Pairs and Lists}

@deftech{pair}（对）将两个任意值连接在一起。@racket[cons]
过程构造对，@racket[car] 和 @racket[cdr]
过程分别提取对的第一个和第二个元素。@racket[pair?] predicate 识别对。

某些对的打印方式是在两个对元素的打印形式周围加上括号，
在开头放一个 @litchar{'}，在元素之间放一个 @litchar{.}。

@examples[
(cons 1 2)
(cons (cons 1 2) 3)
(car (cons 1 2))
(cdr (cons 1 2))
(pair? (cons 1 2))
]

@deftech{list}（列表）是一种由对组合而成的链表。
更准确地说，列表要么是空列表 @racket[null]，
要么是一个对，其第一个元素是列表元素，第二个元素是列表。
@racket[list?] predicate 识别列表。@racket[null?] predicate 识别空列表。

列表通常打印为 @litchar{'} 后面跟着一对括号，括号中包裹着列表元素。

@examples[
null
(cons 0 (cons 1 (cons 2 null)))
(list? null)
(list? (cons 1 (cons 2 null)))
(list? (cons 1 2))
]

当列表或对的某个元素无法用 @racket[quote] 书写形式表示时，
它会使用 @racketresult[list] 或 @racketresult[cons] 打印。
例如，用 @racket[srcloc] 构造的值无法用 @racket[quote] 书写，
它使用 @racketresult[srcloc] 打印：

@interaction[
(srcloc "file.rkt" 1 0 1 (+ 4 4))
(list 'here (srcloc "file.rkt" 1 0 1 8) 'there)
(cons 1 (srcloc "file.rkt" 1 0 1 8))
(cons 1 (cons 2 (srcloc "file.rkt" 1 0 1 8)))
]

@margin-note{另见 @racket[list*]。}

如最后一个示例所示，@racketresult[list*] 用于
缩写一系列无法用 @racketresult[list] 缩写的 @racketresult[cons]。

@racket[write] 和 @racket[display] 函数打印对或列表时
不带前导 @litchar{'}、@racketresult[cons]、
@racketresult[list] 或 @racketresult[list*]。对于对或列表，
@racket[write] 和 @racket[display] 没有区别，
区别仅在于它们对列表元素的处理方式：

@examples[
(write (cons 1 2))
(display (cons 1 2))
(write null)
(display null)
(write (list 1 2 "3"))
(display (list 1 2 "3"))
]

列表上最重要的预定义过程是那些遍历列表元素的过程：

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

@refdetails["pairs"]{对与列表}

对是不可变的（与 Lisp 传统不同），@racket[pair?]
和 @racket[list?] 仅识别不可变的对和列表。
@racket[mcons] 过程创建 @deftech{mutable pair}（可变对），它与
@racket[set-mcar!] 和 @racket[set-mcdr!] 以及
@racket[mcar] 和 @racket[mcdr] 一起使用。可变对使用
@racketresult[mcons] 打印，而 @racket[write] 和 @racket[display] 使用
@litchar["{"] 和 @litchar["}"] 打印可变对：

@examples[
(define p (mcons 1 2))
p
(pair? p)
(mpair? p)
(set-mcar! p 0)
p
(write p)
]

@refdetails["mpairs"]{可变对}
