#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "ports"]{输入和输出端口}

@deftech{port} 封装了一个 I/O 流，通常只用于一个方向。@deftech{input port} 从流中读取，@deftech{output port} 写入字符串。

对于许多接受 port 参数的 procedure，该参数是可选的，默认为 @defterm{current input port} 或 @defterm{current output port}。对于 @exec{mzscheme}，当前端口被初始化为进程的 stdin 和 stdout。@racket[current-input-port] 和 @racket[current-output-port] procedure 在无参数调用时，分别返回当前输出和输入端口。

@examples[
(display "hello world\n")
(display "hello world\n" (current-output-port))
]

端口由特定于不同流类型的各种 procedure 创建。例如，@racket[open-input-file] 创建用于从文件读取的输入端口。像 @racket[with-input-from-file] 这样的 procedure 既创建端口，又在调用给定 body procedure 时将其安装为当前端口。

关于使用端口的信息，见 @secref["io"]。
