#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "overview"]{概述}

Racket BC 运行时系统用 C 实现，提供了从源码到 bytecode 格式的编译器、
从 bytecode 到 machine code 的 JIT 编译器、I/O 功能、thread 和内存管理。

@section{"Scheme" 与 "Racket"}

Racket 的旧称是"PLT Scheme"，核心编译器和运行时系统过去被称为"MzScheme"。
这些旧名称在 Racket 内部根深蒂固，以至于本手册中定义的大多数 C binding 以 @cpp{scheme_}
开头。原则上，它们都应该重命名以 @cpp{racket_} 开头。

@; ----------------------------------------------------------------------

@section[#:tag "CGC versus 3m"]{CGC 与 3m}

在将任何 C 代码与 Racket BC 混合之前，首先决定是使用 @bold{3m} 变体、
@bold{CGC} 变体，还是两者都用：

@itemize[

@item{@bold{@as-index{3m}} : Racket BC 的主要变体，使用
  @defterm{precise} 垃圾收集，并要求显式注册 pointer roots 和分配形状。
  precise 垃圾收集器可能在收集期间在内存中移动其对象。}

@item{@bold{@as-index{CGC}} : Racket BC 的原始变体，内存管理依赖于
  @defterm{conservative} 垃圾收集器。conservative 垃圾收集器可以自动
  从 C 局部变量和（在某些平台上）静态变量中找到对被管理值的引用，
  并且它不会移动已分配的对象。}

]

在 C 级别工作时，使用 CGC 可能比使用 3m 容易得多，
但使用 3m 通常能获得更好的整体系统性能。

@; ----------------------------------------------------------------------

@section[#:tag "embedding-and-extending"]{嵌入和扩展 Racket}

Racket 运行时系统可以嵌入到更大的程序中；参见 @secref["embedding"]
了解更多信息。作为嵌入的替代方案，@exec{racket} 可执行文件
也可以在 subprocess 中运行，对于许多目的来说这可能是更好的选择。
在 Windows 上，@seclink["top" #:doc '(lib "mzcom/mzcom.scrbl") #:indirect?
#t]{MzCom} 提供了另一种选择。

Racket 运行时系统 @seclink["Writing Racket Extensions"]{可以扩展}
以添加新的 C 实现函数。从历史上看，相对于编写纯 Racket 代码，编写扩展
可以获得性能优势，但 Racket 性能已提高到这样的程度：
编写 C 代码（如果有的话）的性能优势通常太小而不值得维护努力。
与此同时，要调用 C 实现库提供的函数，使用 Racket 内的
@seclink["top" #:doc '(lib
"scribblings/foreign/foreign.scrbl")]{foreign-function interface}
比编写扩展来调用库是更好的选择。

@; ----------------------------------------------------------------------

@section[#:tag "places"]{Racket BC 和 Places}

每个 Racket @|tech-place| 对应于一个单独的 OS 实现的 thread。
每个 place 都有自己的内存管理器。指向 GC 管理内存的指针无法在多个
place 之间通信，因为一个 place 中的此类指针对另一个 place 的内存管理器
是不可见的。

当启用 @|tech-place| 支持时，C 级别的静态变量通常不能保存指向
GC 管理内存的指针，因为该静态变量可能用于多个 place。
对于某些 OS，静态变量可以制成 thread-local，在这种情况下，
它在每个 OS thread 中具有不同的地址，且每个不同的地址都可以
针对给定 place 向 GC 注册。

在 @seclink["embedding"]{embedding 应用}中，最初调用 @cpp{scheme_basic_env}
的 OS thread 是原始 place 的 OS thread。当第二次调用 @cpp{scheme_basic_env}
来重置解释器时，可以在与原始调用 @cpp{scheme_basic_env} 不同的 OS thread 中调用它。
此后，新 thread 是原始 place 的 OS thread。

@; ----------------------------------------------------------------------

@section{Racket BC 和 Threads}

Racket 在不借助操作系统的情况下为 Racket 程序实现 thread，
因此从 C 代码的角度看，Racket 的 thread 是协作式的。
独立运行的 Racket 可能使用少数私有的 OS 实现线程来执行后台任务，
但这些 OS 实现的线程永远不会通过 Racket API 公开。

Racket 可以与额外的 OS 实现线程共存，但额外的 OS thread 不能调用任何
@cpp{scheme_} 函数。只有代表特定 @|tech-place| 的 OS thread 才能调用
@cpp{scheme_} 函数。（此限制比说给定 place 的所有跨线程调用必须序列化更强。
Racket 依赖特定 thread 的属性来避免栈溢出和垃圾回收。）
在 @seclink["embedding"]{embedding 应用}中，对于原始 place，
只有用于调用 @cpp{scheme_basic_env} 的 OS thread 才能调用 @cpp{scheme_} 函数。
对于任何其他 place，只有 Racket 为该 place 创建的 OS thread才能用于调用
@cpp{scheme_} 函数。

参见 @secref["threads"] 了解更多关于 thread 的信息，包括 Racket 的 thread 实现
可能对扩展和嵌入 C 代码产生的影响。

@; ----------------------------------------------------------------------

@section[#:tag "im:unicode"]{Racket BC、Unicode、字符和字符串}

Racket 中的字符是一个 Unicode 码点。在 C 中，字符值具有类型 @cppi{mzchar}，
它是 @cpp{unsigned} 的别名 —— 对于正确编译的 Racket，该类型又为 4 字节。
因此，@cpp{mzchar*} 字符串实际上是一个 UCS-4 字符串。

只有少数 Racket 函数使用 @cpp{mzchar*}。相反，大多数函数接受 @cpp{char*}
字符串。当这些 byte strings 用作字符字符串时，它们被解释为 UTF-8 编码。
纯 ASCII 字符串在这种情况下始终是可接受的，因为 ASCII 字符串的 UTF-8 编码
就是其本身。

另请参见 @secref["im:strings"] 和 @secref["im:encodings"]。

@; ----------------------------------------------------------------------

@section[#:tag "im:intsize"]{Racket BC 整数}

Racket 期望在以下模式编译：@cppi{short} 是 16 位整数，@cppi{int}
是 32 位整数，且 @cppi{intptr_t} 与 @cpp{void*} 具有相同的位数。
@cppi{long} 类型根据平台不同可以匹配 @cpp{int} 或 @cpp{intptr_t}。
@cppi{mzlonglong} 类型在支持 64 位整数类型的编译器中具有 64 位，
否则与 @cpp{intptr_t} 相同；因此，@cpp{mzlonglong} 往往匹配 @cpp{long long}。
@cppi{umzlonglong} 类型是 @cpp{mzlonglong} 的无符号版本。
