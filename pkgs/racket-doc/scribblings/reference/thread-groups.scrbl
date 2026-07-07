#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "threadgroups"]{Thread Groups}

一个 @deftech{thread group} 是一个包含线程及其他线程组的集合，它们对 CPU 拥有同等的占用权。通过嵌套线程组以及在线程组中创建特定的线程，程序员可以控制一组线程所分配到的 CPU 数量。每个线程都属于一个线程组，该线程组由创建时的 @racket[current-thread-group] 参数决定。线程组和 custodian（见 @secref["custodians"]）是相互独立的。

根线程组接收操作系统分配给 Racket的全部 CPU。某个线程组中的每个线程或嵌套的组以平均方式获得组内 CPU 的分配（即该组所占 CPU 的一部分），不过线程可能通过睡眠或与其他进程同步而放弃其部分分配。

@defproc[(make-thread-group [group thread-group? (current-thread-group)]) 
         thread-group?]{

创建一个新的线程组，它属于 @racket[group]。}


@defproc[(thread-group? [v any/c]) boolean?]{

如果 @racket[v] 是一个线程组值，返回 @racket[#t]，否则返回 @racket[#f]。}


@defparam[current-thread-group group thread-group?]{

一个确定新创建线程所属线程组的 @tech{parameter}。}
