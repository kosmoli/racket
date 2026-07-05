#lang scribble/doc
@(require scribble/manual
          "common.rkt"
          (for-label racket/base
                     racket/contract
                     compiler/zo-parse
                     compiler/decompile
                     compiler/faslable-correlated
                     racket/set))

@(define-syntax-rule (defstruct+ id fields . rest)
   (defstruct id fields #:prefab . rest))

@title{解析字节码的 API}

@defmodule[compiler/zo-parse]

@racketmodname[compiler/zo-parse] 模块除了 @racket[zo-parse] 之外还重新导出 @racketmodname[compiler/zo-structs]。

@defproc[(zo-parse [in input-port? (current-input-port)]) (or/c linkl-directory? linkl-bundle?)]{
  解析包含字节码的端口（通常是打开 @filepath{.zo} 文件的结果）。注意，用于表示字节码的结构类型在不同 Racket 版本之间经常变化。

  解析后的字节码以 @racket[linkl-directory] 或 @racket[linkl-bundle] 结构返回——后者仅用于编译不包含子模块的 module。

  在 linklet 包或目录结构之外，@racket[zo-parse] 的结果包含依赖于字节码编译目标机器的 linklet：

  @itemlist[

    @item{对于机器无关的字节码文件，linklet 表示为 @racket[faslable-correlated-linklet]。}

    @item{对于 Racket @CS 字节码文件，linklet 是不透明的，因为它主要是机器码，但 @racket[decompile] 可以提取一些信息并可能反汇编机器码。}

    @item{对于 Racket @BC 字节码，字节码可以解析为如下所述的结构。}

   ]

  本节的其余部分专门针对 @BC 字节码。

  在 linklet 内，表达式的字节码表示更接近 S 表达式，而不是传统的、扁平的控制字符串。例如，@racket[if] 形式由具有三个字段的 @racket[branch] 结构表示：一个 test 表达式、一个 "then" 表达式和一个 "else" 表达式。类似地，函数调用由具有参数表达式列表的 @racket[application] 结构表示。

  局部变量或中间值的存储空间（如函数调用的参数）在栈上显式指定。例如，执行 @racket[application] 结构会在栈上为每个参数结果保留空间。同样，当执行 @racket[let-one] 结构（用于简单 @racket[let]）时，通过计算右侧表达式获得的值被压入栈中，然后计算 body。局部变量始终作为从当前位置的偏移量进行访问。调用函数时，其参数在栈上传递。闭包通过将值从栈传输到平面闭包记录来创建，当应用闭包时，保存的值在栈上恢复（尽管可能以不同的顺序，并且可能比捕获时更紧凑地布局）。

  当子表达式产生值时，栈指针将恢复到计算子表达式之前的位置。例如，计算 @racket[let-one] 结构的右侧可能暂时将值压入栈中，但在推送结果值并继续计算 body 之前，栈恢复到其 @racket[let-one] 之前的位置。此外，尾调用将栈指针重置到封闭函数参数之后的位置，然后尾调用通过将尾调用函数的参数压入栈来继续。

  全局变量和模块级变量的值不直接放在栈上，而是存储在 "bucket" 中，栈上保留可访问 bucket 的数组。当闭包主体需要访问全局变量时，闭包捕获并随后恢复 bucket 数组，就像捕获和恢复局部变量一样。可变局部变量类似于全局变量进行装箱，但单独的盒子从栈和闭包引用。

}

