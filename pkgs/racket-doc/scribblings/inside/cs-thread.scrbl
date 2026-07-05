#lang scribble/doc
@(require "utils.rkt")

@cs-title[#:tag "cs-thread"]{管理操作系统级线程}

Chez Scheme 功能只能被 Chez Scheme 运行时系统所知的操作系统级线程访问。否则，此类访问与其他线程触发的垃圾收集之间会发生竞态条件。

非 Chez Scheme 创建的线程可以通过使用 @cppi{Sactivate_thread} 激活来让运行时系统知道。只要一个线程通过不运行 Chez Scheme 代码保持活跃，该线程就会阻止所有其他运行线程的垃圾收集。使用 @cppi{Sdeactivate_thread} 停用一个线程。

@function[(int Sactivate_thread)]{

激活当前操作系统级线程。已激活的线程可以再次激活，但每次激活必须与停用平衡。如果线程之前已激活，则结果为 @cpp{0}，否则为 @cpp{1}。}

@function[(void Sdeactivate_thread)]{

停用当前操作系统级线程---或者至少在激活上平衡，如果没有剩余的激活与停用平衡，则使线程不活跃。}

@function[(int Sdestroy_thread)]{

释放与当前操作系统线程关联的所有 Chez Scheme 资源，该线程必须先前已激活但必须不再激活。}
