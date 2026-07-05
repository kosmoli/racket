#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "vectors"]{Vectors}

@deftech{vector} 是固定长度的任意值数组。与 list 不同，vector 支持对其元素的常量时间访问和更新。

vector 打印形式类似于 list——作为其元素在括号内的序列——但 vector 在 @litchar{'} 后前缀有 @litchar{#}，
或者如果其元素不能用 @racket[quote] 表达，则使用 @racketresult[vector]。

作为表达式的 vector 可以包含可选的长度。此外，作为表达式的 vector 会对其内容隐式 @racket[quote]，
这意味着 vector 常量中的 identifier 和带括号的形式代表 symbol 和 list。

@refdetails/gory["parse-vector"]{the syntax of vectors}

@examples[
(eval:alts @#,racketvalfont{#("a" "b" "c")} #("a" "b" "c"))
(eval:alts @#,racketvalfont{#(name (that tune))} #(name (that tune)))
(eval:alts @#,racketvalfont{#4(baldwin bruce)} #4(baldwin bruce))
(vector-ref #("a" "b" "c") 1)
(vector-ref #(name (that tune)) 1)
]

与 string 类似，vector 要么是可变的，要么是不可变的，直接作为表达式写入的 vector 是可变的。

vector 可以通过 @racket[vector->list] 和 @racket[list->vector] 与 list 相互转换；
这种转换在结合 list 上的预定义 procedure 时非常有用。
当分配额外的 list 似乎过于昂贵时，考虑使用像 @racket[for/fold] 这样的循环形式，
它们既识别 vector 也识别 list。

@examples[
(list->vector (map string-titlecase
                   (vector->list #("three" "blind" "mice"))))
]

@refdetails["vectors"]{vectors 和 vector procedure}