#lang scribble/doc
@(require "mz.rkt")

@title{退出}

@defproc[(exit [v any/c #t]) any]{

将 @racket[v] 传递给当前的 @tech{exit handler}。如果 exit handler 没有逃逸或终止线程，则返回 @|void-const|。}


@defparam[exit-handler proc (any/c . -> . any)]{

一个确定当前 @deftech{exit handler} 的 @tech{parameter}。@racket[exit] 会调用该 @tech{exit handler}。

Racket 可执行文件中的默认 @tech{exit handler} 接受任意参数，对原始 plumber 调用 @racket[plumber-flush-all]，并关闭 OS 级别的 Racket 进程。如果该参数是 @racket[1] 到 @racket[255] 之间的确切整数（通常表示“失败”），则将其用作 OS 级别的退出码；否则退出码为 @racket[0]（通常表示“成功”）。}


@defparam[executable-yield-handler proc (byte? . -> . any)]{

一个确定一个在 Racket 进程正常退出时将被调用的过程的 @tech{parameter}。当 @racket[exit]（或更准确地说，默认的 @tech{exit handler}）被用于提前退出时，与此 parameter 关联的过程不会被调用。传递给 handler 的参数是退出时返回给系统的状态码。默认的 executable-yield handler 仅返回 @|void-const|。

@racketmodname[racket/gui/base] 库将此 parameter 设置为等待直到所有 frame 关闭、timer 停止以及主 eventspace 中的排队事件被处理。更多信息请参见 @racketmodname[racket/gui/base]。}
