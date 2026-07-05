#lang scribble/doc
@(require "utils.rkt")

@cs-title[#:tag "cs-overview"]{概述}

Racket CS 运行时系统通过一个 Chez Scheme 内核的包装器实现。该包装器实现了额外的操作系统胶水代码（例如用于 I/O 和网络），以及到 Racket 层求值器的入口点。

@; ----------------------------------------------------------------------

@section{``S'' 与 ``Racket''}

在 Racket CS 的 C API 中，以 @cpp{S} 开头的名称来自 Chez Scheme 层，而以 @cpp{racket_} 开头的名称来自 Racket 包装器。

@; ----------------------------------------------------------------------

@section[#:tag "cs-memory"]{Racket CS 内存管理}

@index['("allocation")]{Racket} 值可能在任何使用 @cpp{racket_...} 函数运行 Racket 代码的时候被移动或垃圾回收。不要保留任何 Racket 值引用到此类调用之外。这一要求与 Racket 的 BC 实现不同，后者为 C 代码提供了更直接与内存管理器协作的方式。

以 @cpp{S} 开头的 API 函数在注明外不会收集或移动对象，因此将这些函数跨调用地保留对 Racket 值的引用是安全的。

@cpp{Slock_object} 函数可以防止对象被移动或垃圾回收，但应当谨慎使用。通过调用 Chez Scheme 函数 @tt{disable-interrupts} 可以完全禁用垃圾回收，然后再通过 @tt{enable-interrupts} 禁用调用重新启用；这些函数通过 @cpp{racket_primitive} 访问，并通过 @cpp{Scall0} 调用。请注意，禁用中断还会禁用 Racket 线程的上下文切换以及 break 信号处理。假设中断起始为启用状态，调用 @tt{disable-interrupts} 可能会在进一步收集被禁用之前触发一次垃圾回收。

@; ----------------------------------------------------------------------

@section[#:tag "cs-places"]{Racket CS 与 Places}

每个 Racket @|tech-place| 对应一个 Chez Scheme 线程，也对应一个操作系统实现的线程。Chez Scheme 线程共享一个全局分配空间，因此 GC 管理的对象可以从一个 place 安全地传递到另一个 place。但要注意的是，Chez Scheme 线程并不安全；任何跨 place 安全共享值所需的同步都必须显式实现。Racket 级别的 places 函数只会在两个 place 中都能安全使用时才跨 place 共享值。

在 @seclink["cs-embedding"]{嵌入应用程序} 中，最初调用 @cpp{racket_boot} 函数的 OS 线程即为原始 place 的 OS 线程。

@; ----------------------------------------------------------------------

@section{Racket CS 与线程}

Racket 在没有操作系统或 Chez Scheme 线程辅助的情况下为 Racket 程序实现线程，因此从 C 代码的视角来看，Racket 线程是合作式（cooperative）的。独立（Stand-alone）的 Racket 使用一些私有的 OS 实现线程来执行后台任务，但这些 OS 实现线程从未被 Racket API 暴露。

Racket 可以与其它 OS 实现线程共存，但在调用 @cpp{S} 函数时必须小心，且其它 OS 或 Chez Scheme 线程不得调用任何 @cpp{racket_} 函数。为了让其它 OS 调用 @cpp{S} 函数，该线程必须首先使用 @cppi{Sactivate_thread} 激活为一个 Chez Scheme 线程。


@; ----------------------------------------------------------------------

@section[#:tag "cs-intsize"]{Racket CS 整数}

C 类型 @cpp{iptr} 由 Racket CS 头文件定义为一个足够大的整数类型以容纳指针值。换言之，它是 @cpp{intptr_t} 的别名。@cpp{uptr} 类型是其无符号变体。
