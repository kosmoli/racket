#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "quote"]{引用：@racket[quote] 和 @racketvalfont{'}}

@refalso["quote"]{@racket[quote]}

@racket[quote] 形式产生一个常量：

@specform[(#,(racketkeywordfont "quote") datum)]

@racket[datum] 的语法在技术上被指定为 @racket[read] 函数解析为单个元素的任何内容。@racket[quote] 形式的值与 @racket[read] 在给定 @racket[_datum] 时产生的值相同。

@racket[_datum] 可以是一个符号、布尔值、数、（字符或字节）字符串、字符、关键字、空列表、包含更多此类值的对（或列表）、包含更多此类值的向量、包含更多此类值的哈希表，或包含另一个此类值的盒子。

@examples[
(eval:alts (#,(racketkeywordfont "quote") apple) 'apple)
(eval:alts (#,(racketkeywordfont "quote") #t) #t)
(eval:alts (#,(racketkeywordfont "quote") 42) 42)
(eval:alts (#,(racketkeywordfont "quote") "hello") "hello")
(eval:alts (#,(racketkeywordfont "quote") ()) '())
(eval:alts (#,(racketkeywordfont "quote") ((1 2 3) #2("z" x) . the-end)) '((1 2 3) #2("z" x) . the-end))
(eval:alts (#,(racketkeywordfont "quote") (1 2 #,(racketparenfont ".") (3))) '(1 2 . (3)))
]

如上最后一个示例所示，@racket[_datum] 不必与值的规范化打印形式匹配。@racket[_datum] 不能是以 @litchar{#<} 开头的打印表示，因此不能是 @|void-const|、@|undefined-const| 或过程。

@racket[quote] 形式很少用于本身是布尔值、数或字符串的 @racket[_datum]，因为这些值的打印形式已经可以用作常量。@racket[quote] 形式更典型地用于符号和列表，这些在未引用时具有其他含义（标识符、函数调用等）。

一个表达式

@specform[(quote @#,racketvarfont{datum})]

是

@racketblock[
(#,(racketkeywordfont "quote") #,(racket _datum))
]

的缩写，并且这个缩写几乎总是代替 @racket[quote] 使用。该缩写甚至在 @racket[_datum] 内部也适用，因此它可以产生一个包含 @racket[quote] 的列表。

@refdetails["parse-quote"]{@racketvalfont{@literal{'}}} 缩写

@examples[
'apple
'"hello"
'(1 2 3)
(display '(you can 'me))
]
