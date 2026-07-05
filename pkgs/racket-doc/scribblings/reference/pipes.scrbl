#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "pipeports"]{Pipes}

Racket @deftech{pipe} 是 Racket 内部的，与 OS 级 pipe 无关，后者用于不同进程
之间的通信。@margin-note*{OS 级 pipe 可以通过 @racket[subprocess] 创建，
在 Unix 文件系统上打开现有命名文件，或者使用 pipe 作为其原始输入、输出或错误端口
来启动 Racket。这样的 pipe 是 @tech{file-stream ports}，与 @racket[make-pipe] 产生的
pipe 不同。}

@defproc[(pipe-port? [p port?]) boolean?]{

如果 @racket[p] 是由 @racket[make-pipe] 创建的 pipe 的任一端，返回 @racket[#t]，
否则返回 @racket[#f]。

@history[#:added "8.15.0.9"]}

@defproc[(make-pipe [limit exact-positive-integer? #f]
                    [input-name any/c 'pipe]
                    [output-name any/c 'pipe])
         (values (and/c input-port? pipe-port?) (and/c output-port? pipe-port?))]{

返回两个端口值：第一个是 input port，第二个是 output port。写入 output port 的数据
从 input port 读出，没有中间缓冲。与其他类型的端口不同，pipe port 不需要显式关闭
就可以被 @seclink["gc-model"]{garbage collection} 回收。

如果 @racket[limit] 为 @racket[#f]，则新 pipe 持有无限数量的未读字节
（即，仅受限于可用内存）。如果 @racket[limit] 是正数，则 pipe 将最多持有
@racket[limit] 个未读/未 peek 字节；之后写入 pipe 的 output port 将阻塞，
直到从 input port 读取或 peek 以释放更多空间。（Peek 等效地扩展端口的容量，
直到被 peek 的字节被读取。）

可选的 @racket[input-name] 和 @racket[output-name] 分别用作
返回的 input port 和 output port 的名称。}

@defproc[(pipe-content-length [pipe-port pipe-port?]) exact-nonnegative-integer?]{

返回 pipe 中包含的字节数，其中 @racket[pipe-port] 是 @racket[make-pipe] 
产生的 pipe 的两个端口中的任意一个。Pipe 的内容长度统计已写入 pipe 但尚未读取（可能已 peek）的所有字节。}