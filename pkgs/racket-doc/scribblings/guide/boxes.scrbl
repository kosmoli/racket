#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "boxes"]{盒子}

@deftech{box} 类似于单元素向量。它可以打印为带引号的 @litchar{#&}
后跟 boxed 值的打印形式。@litchar{#&} 形式也可以用作表达式，
但由于生成的 box 是常量，因此实际上没有用处。

@; 那么盒子到底有什么用处呢？

@examples[
(define b (box "apple"))
b
(unbox b)
(set-box! b '(banana boat))
b
]

@refdetails["boxes"]{盒子和 box 过程}
