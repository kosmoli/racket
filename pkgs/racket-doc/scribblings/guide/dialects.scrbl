#lang scribble/base
@(require scribble/manual (except-in scribblings/private/docname Quick)
          "guide-utils.rkt")

@title[#:tag "dialects" #:style 'toc]{Dialects of Racket and Scheme}

我们用 "Racket" 这个名称来指代 Lisp 语言的一种特定方言，
它是基于 Lisp 家族的 Scheme 分支。尽管 Racket 与 Scheme 非常相似，
但模块前的 @hash-lang[] 前缀是 Racket 的一个特定特性，以 @hash-lang[]
开头的程序不太可能在其他 Scheme 实现中运行。同时，不以 @hash-lang[]
开头的程序也无法在大多数 Racket 工具的默认模式下使用。

但是 "Racket" 并不仅仅是由 Racket 工具支持的唯一 Lisp 方言。
相反，Racket 工具被设计为支持多种 Lisp 方言甚至多种语言，
这使得 Racket 工具套件能够为多个社区服务。Racket 还为程序员和研究人员
提供了他们创建和探索新语言所需的工具。

@local-table-of-contents[]

#; --------------------------------------------------

@section[#:tag "more-hash-lang"]{More Rackets}

"Racket" 与其说是一门语言，不如说是一种编程语言的思想。Macros 可以
扩展一门基础语言（如 @secref["macros"] 中所述），而 alternate parsers
可以从头开始构建一门全新的语言（如 @secref["languages"] 中所述）。

启动 Racket 模块的 @hash-lang[] 行声明了模块的基础语言。
当我们说 "Racket" 时，通常指的是 @hash-lang[] 后面跟一个基础语言
@racketmodname[racket] 或 @racketmodname[racket/base]（其中
@racketmodname[racket] 是其扩展）。Racket 发行版提供了其他语言，
包括以下几种：

@itemize[

 @item{@racketmodname[typed/racket #:indirect] --- 类似于
       @racketmodname[racket]，但具有静态类型；参见 @TR-guide[]。}

 @item{@racketmodname[lazy #:indirect] --- 类似于
       @racketmodname[racket/base]，但避免对表达式求值直到它的
       值被需要；参见 @seclink["top" #:doc
       '(lib "lazy/lazy.scrbl") #:indirect? #t]{Lazy Racket 文档}。}

 @item{@racketmodname[frtime #:indirect] --- 以更加激进的方式改变求值
       以支持 reactive programming；参见 @seclink["top" #:doc
       '(lib "frtime/scribblings/frtime.scrbl")
       #:indirect? #t]{FrTime 文档}。}

 @item{@racketmodname[scribble/base] --- 一门更像 Latex 而不是 Racket
       的语言，用于撰写文档；参见
       @other-manual['(lib "scribblings/scribble/scribble.scrbl")]}

]

每个这样的语言通过在 @hash-lang[] 后面跟随语言名称来启动模块。
例如，本文档的源文件以 @racket[@#,hash-lang[] scribble/base] 开头。

此外，Racket 用户可以定义自己的语言，如 @secref["languages"] 中所述。
通常，语言名称通过添加 @racketidfont{/lang/reader} 来映射到它的实现；
例如，语言名称 @racketmodname[scribble/base] 被扩展为
@racket[scribble/base/lang/reader]，这是实现 surface-syntax parser 的
模块。某些语言名称充当 language loaders；例如，
@racket[@#,hash-lang[] @#,racketmodname[planet] _planet-path] 通过
@seclink["top" #:doc '(lib
"planet/planet.scrbl")]{@|PLaneT|} 下载、安装和使用一门语言。

#; --------------------------------------------------

@section[#:tag "standards"]{Standards}

标准方言包括那些由 @|r5rs| 和 @|r6rs| 定义的 Scheme 方言。

@subsection[#:tag "r5rs"]{@|r5rs|}

"@|r5rs|" 代表 @link["../r5rs/r5rs-std/index.html"]{The
Revised@superscript{5} Report on the Algorithmic Language Scheme}，它是目前
实现最广泛的 Scheme 标准。

默认模式下的 Racket 工具不符合 @|r5rs| 标准，主要是因为 Racket 工具通常期望模块，
而 @|r5rs| 没有定义 module 系统。典型的单文件 @|r5rs| 程序可以通过在前面加上
@racket[@#,hash-lang[] @#,racketmodname[r5rs #:indirect]] 转换为 Racket 程序，
但其他 Scheme 系统不认识 @racket[@#,hash-lang[] @#,racketmodname[r5rs #:indirect]]。
与 @|r5rs| 标准更直接符合的是 @exec{plt-r5rs} 可执行文件（参见 
@R5RS[#:section "plt-r5rs"]{@exec{plt-r5rs}}）。

除了 module 系统之外，@|r5rs| 和 Racket 的语法形式和函数也有所不同。
只有简单的 @|r5rs| 程序在前面加上 @racket[@#,hash-lang[] racket] 时才会变为
Racket 程序，而相对较少的 Racket 程序在移除 @hash-lang[] 行时会变为 
@|r5rs| 程序。还有，当将 "@|r5rs| modules" 与 Racket modules 混合时，
请注意 @|r5rs| pairs 对应于 Racket mutable pairs（通过 @racket[mcons] 构造）。

更多关于使用 Racket 运行 @|r5rs| 程序的信息，参见 @R5RS[]。

@subsection{@|r6rs|}

"@|r6rs|" 代表 @link["../r6rs/r6rs-std/index.html"]{The
Revised@superscript{6} Report on the Algorithmic Language Scheme}，它对 
@|r5rs| 进行了扩展，提供了一个类似于 Racket module 系统的 module 系统。

当一个 @|r6rs| 库或顶级程序在前面加上
@racketmetafont{#!}@racketmodname[r6rs #:indirect]（这是有效的 @|r6rs| 语法）时，
它也可以用作 Racket 程序。这可行是因为在 Racket 中，
@racketmetafont{#!} 被视为 @hash-lang[] 后跟一个空格的简写，因此 
@racketmetafont{#!}@racketmodname[r6rs #:indirect] 选择了 
@racketmodname[r6rs #:indirect] module 语言。然而，与 @|r5rs| 一样，请注意
@|r6rs| 的语法形式和函数与 Racket 有所不同，并且 @|r6rs| pairs 是 mutable pairs。

更多关于使用 Racket 运行 @|r6rs| 程序的信息，参见 @R6RS[]。

@; --------------------------------------------------

@section[#:tag "teaching-langs"]{Teaching}

@|HtDP| 教材依赖于 pedagogic variants of Racket，它们平滑地为 
programmers 引入了编程概念。参见 @HtDP-doc[]。
