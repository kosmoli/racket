#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "implementations" #:style 'quiet]{Implementations}

Racket 的定义旨在追求确定性和独立于实现。
不过，某些细节不可避免地随实现而异。Racket 目前有两个主要的实现：

@itemlist[

 @item{@deftech{CS} 实现是自 Racket 8.0 版本以来的首选实现。该变体称为"CS"，
       因为它使用 Chez Scheme 作为其核心编译器和运行时系统。

       CS 实现通常为 Racket 程序提供最佳性能。编译的 Racket CS 代码在
       @filepath{.zo} 文件中通常包含特定于操作系统和架构的机器代码。}

 @item{@deftech{BC} 实现是在 7.9 版本之前的首选实现。"BC"标签代表"before
       Chez"或"bytecode"。

       编译的 Racket BC 代码在 @filepath{.zo} 文件中通常包含平台无关的字节码，
       在代码加载时进一步"即时"编译为机器代码。

       Racket BC 有两个变体：@deftech{3m} 和 @deftech{CGC}。
       区别在于 @tech{garbage collection} 实现，其中 3m使用在内存中移动对象的垃圾回收器
       （此效果对外库可见），并精确跟踪已分配对象，而 CGC 使用"保守"回收器，
       要求嵌入的环境提供更少的合作。3m 子变体倾向于比 CGC 性能好得多，它在 370 版本
       （在当前版本控制约定中为 v3.7）成为默认变体。}

]

大多数 Racket 程序在所有实现变体中运行相同，但某些 Racket 功能仅在某些实现变体上可用，
并且 Racket 与 foreign function 的交互在不同变体之间差异显著。使用 @racket[system-type]
获取有关当前运行实现的信息。