#lang scribble/doc
@(require scribble/manual scribble/struct scribble/eval racket/system
          "guide-utils.rkt"
          (for-label racket/tcp racket/serialize racket/port
                     racket/string))

@(define io-eval (make-base-eval))

@(define (threecolumn a b c)
   (make-table #f
     (list (list (make-flow (list a))
                 (make-flow (list (make-paragraph (list (hspace 1)))))
                 (make-flow (list b))
                 (make-flow (list (make-paragraph (list (hspace 1)))))
                 (make-flow (list c))))))
@(interaction-eval #:eval io-eval (print-hash-table #t))

@title[#:tag "i/o" #:style 'toc]{Input and Output}


@margin-note{Racket port 对应于 Unix 的流概念（不要与 @racketmodname[racket/stream] 的流混淆）。}
Racket 的 @deftech{port} 表示数据的源或汇，如文件、终端、TCP 连接或内存中的字符串。port 提供顺序访问，数据可以一次读写一部分，而不需要一次性消费或产生所有数据。更具体地说，@defterm{input port} 表示程序可以从中读取数据的源，@defterm{output port} 表示程序可以向其写入数据的汇。


@local-table-of-contents[]

@;------------------------------------------------------------------------
@section[#:tag "ports"]{Varieties of Ports}

各种函数创建各种类型的 port。以下是一些示例：

@itemize[

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 @item{@bold{文件：}@racket[open-output-file] 函数打开一个文件用于写入，@racket[open-input-file] 打开一个文件用于读取。

@(interaction-eval #:eval io-eval (define old-dir (current-directory)))
@(interaction-eval #:eval io-eval (current-directory (find-system-path 'temp-dir)))
@(interaction-eval #:eval io-eval (when (file-exists? "data") (delete-file "data")))

@examples[
#:eval io-eval
(define out (open-output-file "data"))
(display "hello" out)
(close-output-port out)
(define in (open-input-file "data"))
(read-line in)
(close-input-port in)
]

如果文件已经存在，@racket[open-output-file] 默认会引发异常。提供像 @racket[#:exists 'truncate] 或 @racket[#:exists 'update] 这样的选项来重新写入或更新文件：

@examples[
#:eval io-eval
(define out (open-output-file "data" #:exists 'truncate))
(display "howdy" out)
(close-output-port out)
]

与其必须匹配打开调用和关闭调用，大多数 Racket 程序员会使用 @racket[call-with-input-file] 和 @racket[call-with-output-file] 函数，这些函数接受一个函数来执行所需的操作。该函数获得 port 作为其唯一参数，port 会为操作自动打开和关闭。

@examples[
        #:eval io-eval
(call-with-output-file "data"
                        #:exists 'truncate
                        (lambda (out)
                          (display "hello" out)))
(call-with-input-file "data"
                      (lambda (in)
                        (read-line in)))
]

@(interaction-eval #:eval io-eval (when (file-exists? "data") (delete-file "data")))
@(interaction-eval #:eval io-eval (current-directory old-dir))}

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 @item{@bold{字符串：}@racket[open-output-string] 函数创建一个将数据累积到字符串中的 port，@racket[get-output-string] 提取累积的字符串。@racket[open-input-string] 函数创建一个从字符串读取的 port。

  @examples[
  #:eval io-eval
  (define p (open-output-string))
  (display "hello" p)
  (get-output-string p)
  (read-line (open-input-string "goodbye\nfarewell"))
  ]}

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 @item{@bold{TCP 连接：}@racket[tcp-connect] 函数为 TCP 通信的客户端创建一个输入 port 和一个输出 port。@racket[tcp-listen] 函数创建一个服务器，通过 @racket[tcp-accept] 接受连接。

  @examples[
  #:eval io-eval
  (eval:alts (define server (tcp-listen 12345)) (void))
  (eval:alts (define-values (c-in c-out) (tcp-connect "localhost" 12345)) (void))
  (eval:alts (define-values (s-in s-out) (tcp-accept server))
             (begin (define-values (s-in c-out) (make-pipe))
                    (define-values (c-in s-out) (make-pipe))))
  (display "hello\n" c-out)
  (close-output-port c-out)
  (read-line s-in)
  (read-line s-in)
  ]}

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 @item{@bold{进程管道：}@racket[subprocess] 函数在操作系统级别运行一个新进程，并返回对应于子进程 stdin、stdout 和 stderr 的 port。（前三个参数可以是某些类型的现有 port，以直接连接到子进程，而不是创建新的 port。）

  @examples[
  #:eval io-eval
  (eval:alts
   (define-values (p stdout stdin stderr)
     (subprocess #f #f #f "/usr/bin/wc" "-w"))
   (define-values (p stdout stdin stderr)
     (values #f (open-input-string "       3") (open-output-string) (open-input-string ""))))
  (display "a b c\n" stdin)
  (close-output-port stdin)
  (read-line stdout)
  (close-input-port stdout)
  (close-input-port stderr)
  ]}

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 @item{@bold{内部管道：}@racket[make-pipe] 函数返回两个 port，它们是管道的两端。这种管道是 Racket 内部的，与操作系统级别用于不同进程间通信的管道无关。

 @examples[
  #:eval io-eval
  (define-values (in out) (make-pipe))
  (display "garbage" out)
  (close-output-port out)
  (read-line in)
 ]}

]

@;------------------------------------------------------------------------
@section[#:tag "default-ports"]{Default Ports}

对于大多数简单的 I/O 函数，目标 port 是可选参数，默认是@defterm{当前输入 port}或@defterm{当前输出 port}。此外，错误消息写入@defterm{当前错误 port}，它是一个输出 port。@racket[current-input-port]、@racket[current-output-port] 和 @racket[current-error-port] 函数返回相应的当前 port。

@examples[
#:eval io-eval
(display "Hi")
(code:line (display "Hi" (current-output-port)) (code:comment @#,t{the same}))
]

如果你在终端中启动 @exec{racket} 程序，当前输入、输出和错误 port 都连接到终端。更一般地说，它们连接到操作系统级别的 stdin、stdout 和 stderr。在本指南中，示例将写入 stdout 的输出显示为紫色，将写入 stderr 的输出显示为红色斜体。

@defexamples[
#:eval io-eval
(define (swing-hammer)
  (display "Ouch!" (current-error-port)))
(swing-hammer)
]

当前 port 函数实际上是@tech{参数}，这意味着它们的值可以用 @racket[parameterize] 设置。

@margin-note{参见 @secref["parameterize"] 了解参数的介绍。}

@examples[
#:eval io-eval
(let ([s (open-output-string)])
  (parameterize ([current-error-port s])
    (swing-hammer)
    (swing-hammer)
    (swing-hammer))
  (get-output-string s))
]

@; ----------------------------------------------------------------------
@section[#:tag "read-write"]{Reading and Writing Racket Data}

正如 @secref["datatypes"] 中所指出的，Racket 提供了三种打印内置值实例的方式：

@itemize[

 @item{@racket[print]，以与 @tech{REPL} 结果相同的方式打印值；}

 @item{@racket[write]，以一种使 @racket[read] 能从输出中取回值的方式打印值；}

 @item{@racket[display]，倾向于将值简化为其字符或字节内容——至少对于那些主要是关于字符或字节的数据类型，否则它回退到与 @racket[write] 相同的输出。}

]

以下是使用每种方式的一些示例：

@threecolumn[

@interaction[
(print 1/2)
(print #\x)
(print "hello")
(print #"goodbye")
(print '|pea pod|)
(print '("i" pod))
(print write)
]

@interaction[
(write 1/2)
(write #\x)
(write "hello")
(write #"goodbye")
(write '|pea pod|)
(write '("i" pod))
(write write)
]

@interaction[
(display 1/2)
(display #\x)
(display "hello")
(display #"goodbye")
(display '|pea pod|)
(display '("i" pod))
(display write)
]

]

总的来说，@racket[print] 对应于 Racket 语法的表达式层，@racket[write] 对应于读取器层，@racket[display] 大致对应于字符层。

@racket[printf] 函数支持数据和文本的简单格式化。在提供给 @racket[printf] 的格式字符串中，@litchar{~a} 对下一个参数进行 @racket[display]，@litchar{~s} 对下一个参数进行 @racket[write]，@litchar{~v} 对下一个参数进行 @racket[print]。

@defexamples[
#:eval io-eval
(define (deliver who when what)
  (printf "Items ~a for shopper ~s: ~v" who when what))
(deliver '("list") '("John") '("milk"))
]

使用 @racket[write] 之后（与 @racket[display] 或 @racket[print] 不同），许多形式的数据可以用 @racket[read] 读回。同样 @racket[print] 的值也可以被 @racket[read] 解析，但结果可能有额外的引用形式，因为 @racket[print] 的形式旨在像表达式一样被读取。

@examples[
#:eval io-eval
(define-values (in out) (make-pipe))
(write "hello" out)
(read in)
(write '("alphabet" soup) out)
(read in)
(write #hash((a . "apple") (b . "banana")) out)
(read in)
(print '("alphabet" soup) out)
(read in)
(display '("alphabet" soup) out)
(read in)
]

@; ----------------------------------------------------------------------
@section[#:tag "serialization"]{Datatypes and Serialization}

@tech{Prefab} 结构类型（参见 @secref["prefab-struct"]）自动支持@deftech{序列化}：它们可以写入输出流，并且可以从输入流中读回副本：

@interaction[
(define-values (in out) (make-pipe))
(write #s(sprout bean) out)
(read in)
]

由 @racket[struct] 创建的其他结构类型提供了比 @tech{prefab} 结构类型更多的抽象，通常使用 @racketresultfont{#<....>} 记法（对于不透明结构类型）或使用 @racketresultfont{#(....)} vector 记法（对于透明结构类型）进行 @racket[write]。在任何情况下，结果都不能作为结构类型的实例读回：

@interaction[
(struct posn (x y))
(write (posn 1 2))
(define-values (in out) (make-pipe))
(write (posn 1 2) out)
(read in)
]

@interaction[
(struct posn (x y) #:transparent)
(write (posn 1 2))
(define-values (in out) (make-pipe))
(write (posn 1 2) out)
(define v (read in))
v
(posn? v)
(vector? v)
]

@racket[serializable-struct] 形式定义了一个可以被 @racket[serialize] 为一个值的结构类型，该值可以用 @racket[write] 打印并通过 @racket[read] 恢复。@racket[serialize] 的结果可以被 @racket[deserialize] 以取回原始结构类型的实例。序列化形式和函数由 @racketmodname[racket/serialize] 库提供。

@examples[
(require racket/serialize)
(serializable-struct posn (x y) #:transparent)
(deserialize (serialize (posn 1 2)))
(write (serialize (posn 1 2)))
(define-values (in out) (make-pipe))
(write (serialize (posn 1 2)) out)
(deserialize (read in))
]

除了 @racket[struct] 绑定的名称外，@racket[serializable-struct] 还绑定了一个带有反序列化信息的标识符，并自动从模块上下文 @racket[provide] 反序列化标识符。当值被反序列化时，此反序列化标识符会被反射性地访问。

@; ----------------------------------------------------------------------
@section[#:tag "encodings"]{Bytes, Characters, and Encodings}

像 @racket[read-line]、@racket[read]、@racket[display] 和 @racket[write] 这样的函数都基于@tech{字符}（对应于 Unicode 标量值）工作。概念上，它们是用 @racket[read-char] 和 @racket[write-char] 实现的。

更原始地，port 读写@tech{字节}而不是@tech{字符}。函数 @racket[read-byte] 和 @racket[write-byte] 读写原始字节。其他函数，如 @racket[read-bytes-line]，建立在字节操作而非字符操作之上。

事实上，@racket[read-char] 和 @racket[write-char] 函数在概念上是用 @racket[read-byte] 和 @racket[write-byte] 实现的。当单个字节的值小于 128 时，它对应于一个 ASCII 字符。任何其他字节被视为 UTF-8 序列的一部分，其中 UTF-8 是一种将 Unicode 标量值编码为字节的特定标准方式（它具有 ASCII 字符被编码为自身的良好特性）。因此，单个 @racket[read-char] 可能多次调用 @racket[read-byte]，单个 @racket[write-char] 可能产生多个输出字节。

@racket[read-char] 和 @racket[write-char] 操作@emph{始终}使用 UTF-8 编码。如果你有一个使用不同编码的文本流，或者你想生成不同编码的文本流，请使用 @racket[reencode-input-port] 或 @racket[reencode-output-port]。@racket[reencode-input-port] 函数将输入流从你指定的编码转换为 UTF-8 流；这样，@racket[read-char] 看到的是 UTF-8 编码，即使原始使用的是不同的编码。但要注意，@racket[read-byte] 也会看到重新编码的数据，而不是原始字节流。

@; ----------------------------------------------------------------------
@section[#:tag "io-patterns"]{I/O Patterns}

@hash-lang-note[racket/port #:lang racket/base]

@(require (prefix-in ex: scribble/example))

@(begin
  (define port-eval (make-base-eval))
  (interaction-eval #:eval port-eval (require racket/port racket/string)))

对于这些示例，假设你在程序的同一目录下有两个文件：@filepath{oneline.txt} 和 @filepath{manylines.txt}。

@filebox["oneline.txt"]{
@verbatim[#:indent 1]{
I am one line, but there is an empty line after this one.

}}

@filebox["manylines.txt"]{
@verbatim[#:indent 1]{
I am
a message
split over a few lines.

}}

如果文件很小，你可以直接将文件作为字符串读入：

@ex:examples[
 #:eval port-eval
 #:hidden
 (define old-dir (current-directory))
 (current-directory (find-system-path 'temp-dir))
 (call-with-output-file
   "oneline.txt"
   #:exists 'truncate
   (lambda (out)
     (display "I am one line, but there is an empty line after this one.\n" out)))
 (call-with-output-file
   "manylines.txt"
   #:exists 'truncate
   (lambda (out)
     (display "I am\na message\nsplit over a few lines.\n" out)))]

@ex:examples[
 #:eval port-eval
 (define file-contents
   (port->string (open-input-file "oneline.txt") #:close? #t))
 (string-suffix? file-contents "after this one.")
 (string-suffix? file-contents "after this one.\n")
 (string-suffix? (string-trim file-contents) "after this one.")]

我们使用 @racketmodname[racket/port] 中的 @racket[port->string] 来将内容读取为字符串：@racket[#:close? #t] 关键字参数确保文件在读取后被关闭。

我们使用 @racketmodname[racket/string] 中的 @racket[string-trim] 来删除文件最开头和最末尾的多余空白。（许多格式化工具坚持文本文件应以单个空行结尾。）

如果你的文件只有一行文本，另请参见 @racket[read-line]。

如果你想要处理文件的单个行，可以使用 @racket[for] 配合 @racket[in-lines]：

@interaction[
(define (upcase-all in)
  (for ([l (in-lines in)])
    (display (string-upcase l))
    (newline)))
(upcase-all (open-input-string
             (string-append
              "Hello, World!\n"
              "Can you hear me, now?")))
]

你还可以组合每行的计算。所以如果你想知道有多少行包含 ``m''，你可以这样做：

@examples[
 #:eval port-eval
 (with-input-from-file "manylines.txt"
   (lambda ()
     (for/sum ([l (in-lines)]
                #:when (string-contains? l "m"))
       1)))]

@ex:examples[
 #:eval port-eval
 #:hidden
 (when (file-exists? "oneline.txt") (delete-file "oneline.txt"))
 (when (file-exists? "manylines.txt") (delete-file "manylines.txt"))
 (current-directory old-dir)]

这里，@racketmodname[racket/port] 中的 @racket[with-input-from-file] 在 thunk 内部将默认输入 port 设置为文件 @filepath{manylines.txt}。它还在计算完成后（以及少数其他情况下）关闭文件。

然而，如果你想确定 ``hello'' 是否出现在文件中，你可以搜索单独的行，但更简单的方法是直接对流应用正则表达式（参见 @secref["regexp"]）：

@interaction[
(define (has-hello? in)
  (regexp-match? #rx"hello" in))
(has-hello? (open-input-string "hello"))
(has-hello? (open-input-string "goodbye"))
]

如果你想将一个 port 复制到另一个 port，请使用 @racketmodname[racket/port] 中的 @racket[copy-port]，它在有大量数据可用时高效地传输大块数据，但如果只有少量数据可用也会立即传输小块数据：

@interaction[
#:eval port-eval
(define o (open-output-string))
(copy-port (open-input-string "broom") o)
(get-output-string o)
]

@close-eval[port-eval]

@; ----------------------------------------------------------------------

@close-eval[io-eval]
