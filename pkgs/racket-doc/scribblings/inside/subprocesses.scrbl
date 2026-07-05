#lang scribble/doc
@(require "utils.rkt"
          (for-label racket/system))

@bc-title[#:tag "Subprocesses"]{子进程}

在 Unix 和 Mac OS 上，子进程处理涉及 @as-index[@cpp{fork}]、@as-index[@cpp{waitpid}] 和 @as-index[@cpp{SIGCHLD}]，这会在嵌入应用程序中产生各种问题。在 Windows 上，由于不需要 @cpp{fork}，且 Windows 提供了一个与 Racket 子进程值密切匹配的抽象，因此子进程处理更为简单。

在 Racket 通过 @racket[subprocess]（或 @racket[system]、@racket[process] 等）创建子进程后，它会周期性地使用 @cpp{waitpid} 轮询进程状态。如果进程是作为自己的组创建的，则对 @cpp{waitpid} 的调用使用所创建子进程的进程 ID；对于所有其他子进程，轮询使用第一个参数为 @cpp{0} 的单个 @cpp{waitpid} 调用。特别是使用 @cpp{0} 会与嵌入上下文中的其他库产生干扰，因此 Racket 在没有未完成的子进程时不调用 @cpp{waitpid}。

Racket 可能依赖也可能不依赖 @cpp{SIGCHLD} handler，并且可能阻塞也可能不阻塞 @cpp{SIGCHLD}。目前，当 Racket 被编译为支持 @|tech-place|s 时，Racket 在启动时会阻塞 @cpp{SIGCHLD}，期望所有创建的线程都已阻塞 @cpp{SIGCHLD}。当 Racket 未编译为支持 @|tech-place|s 时，则安装一个 @cpp{SIGCHLD} handler。

在嵌入 Racket 的应用程序中使用 @cpp{fork} 是有问题的，原因如下：Racket 可能已安装 @cpp{SIGALRM} handler 并安排 alarm 以实现上下文切换，它可能已打开应在子进程中关闭的文件描述符，并且它可能已更改了 @cpp{SIGCHLD} 等信号的状态。因此，将 Racket 嵌入到 @cpp{fork} 的进程在技术上不受支持；未来 Racket 可能为此类应用程序提供更好的支持。
