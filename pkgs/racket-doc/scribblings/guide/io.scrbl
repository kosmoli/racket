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


@margin-note{Racket 的端口对应于 Unix 的 stream 概念
（不要与 @racketmodname[racket/stream] 的 stream 混淆）。}
Racket @deftech{port} 表示数据的源或接收端，例如文件、终端、TCP 连接或内字符串。
端口提供顺序访问，数据可以一块一块地读取或写入，
而不是必须在一次操作中全部消耗或生产。
更具体地说，@defterm{input port} 表示程序可以读取数据的源，
@defterm{output port} 表示程序可以写入数据的接收端。


@local-table-of-contents[]

@;------------------------------------------------------------------------
@section[#:tag "ports"]{Varieties of Ports}

不同的函数创建不同类型的端口。以下是一些例子：

@itemize[

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 @item{@bold{Files:} The @racket[open-output-file] function opens a
  file for writing, and @racket[open-input-file] opens a file for
  reading.

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

如果文件已存在，则 @racket[open-output-file] 默认会引发异常。 Supply an option like @racket[#:exists
'truncate] or @racket[#:exists 'update] to re-write or update the
file:

@examples[
#:eval io-eval
(define out (open-output-file "data" #:exists 'truncate))
(display "howdy" out)
(close-output-port out)
]

不必将打开调用与关闭调用配对，大多数 Racket
程序员使用 @racket[call-with-input-file] 和
@racket[call-with-output-file] 函数，它们接受一个函数来执行所需
操作。 This function gets as its only argument the port,
which is automatically opened and closed for the operation.

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
 @item{@bold{Strings:} The @racket[open-output-string] function creates
 a port that accumulates data into a string, and @racket[get-output-string]
 extracts the accumulated string. The @racket[open-input-string] function
 创建一个从字符串读取的端口。

  @examples[
  #:eval io-eval
  (define p (open-output-string))
  (display "hello" p)
  (get-output-string p)
  (read-line (open-input-string "goodbye\nfarewell"))
  ]}

@;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

 @item{@bold{TCP Connections:} The @racket[tcp-connect] function
 creates both an input port and an output port for the client side of
 a TCP communication. The @racket[tcp-listen] function creates a
 server, which accepts connections via @racket[tcp-accept].

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

 @item{@bold{Process Pipes:} The @racket[subprocess] function runs a new
  process at the OS level and returns ports that correspond to the
  subprocess's stdin, stdout, and stderr. (The first three arguments
  can be certain kinds of existing ports to connect directly to the
  subprocess, instead of creating new ports.)

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

 @item{@bold{Internal Pipes:} The @racket[make-pipe] function returns
 two ports that are ends of a pipe. This kind of pipe is internal to
 Racket, and not related to OS-level pipes for communicating between
 different processes.

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

对于大多数简单的 I/O 函数，目标端口是可选参数，
默认为 @defterm{current input port} 或 @defterm{current output port}。 另外，错误消息被写入 @defterm{current error port}，它是一个 output port。 The
@racket[current-input-port], @racket[current-output-port], and
@racket[current-error-port] 函数返回对应的当前端口。

@examples[
#:eval io-eval
(display "Hi")
(code:line (display "Hi" (current-output-port)) (code:comment @#,t{the same}))
]

如果你在终端中启动 @exec{racket} 程序，
则当前的 input、output 和 error 端口都连接到终端。 更通地说，它们连接到 OS 级别的 stdin、stdout 和 stderr。
在本指南中，示例中写入 stdout 的输出是紫色的，
写入 stderr 的输出是红色斜体的。

@defexamples[
#:eval io-eval
(define (swing-hammer)
  (display "Ouch!" (current-error-port)))
(swing-hammer)
]

这些 current-port 函数实际上是 @tech{parameters}，
这意味着它们的值可以通过 @racket[parameterize] 设置。

@margin-note{See @secref["parameterize"] for an introduction to parameters.}

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

正如 @secref["datatypes"] 中所述，Racket 提供三种打印内置值实例的方式：

@itemize[

 @item{@racket[print], which prints a value in the same way that is it
       printed for a @tech{REPL} result; and }

 @item{@racket[write], which prints a value in such a way that
       @racket[read] on the output produces the value back; and }

 @item{@racket[display], which tends to reduce a value to just its
       character or byte content---at least for those datatypes that
       are primarily about characters or bytes, otherwise it falls
       back to the same output as @racket[write].}

]

以下是使用每种方式的例子：

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

总而言之，@racket[print] 对应于 Racket 语法的表达式层，
@racket[write] 对应于读取层，@racket[display] 大致对应于字符字节层。

@racket[printf] 函数支持数据和文本的简单格式化。 In the format string supplied to @racket[printf], @litchar{~a}
@racket[display]s the next argument, @litchar{~s}
@racket[write]s the next argument, 且 @litchar{~v} @racket[print]s 下一个参数。

@defexamples[
#:eval io-eval
(define (deliver who when what)
  (printf "Items ~a for shopper ~s: ~v" who when what))
(deliver '("list") '("John") '("milk"))
]

使用 @racket[write] 而非 @racket[display] 或 @racket[print] 后，
可通过 @racket[read] 读回多种形式的数据。 @racket[print] 打印的值也可通过 @racket[read] 解析，
但结果可能有额外的引号形式，因为 @racket[print] 形式
是作为表达式阅读的。

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

@tech{Prefab} structure types (see @secref["prefab-struct"])
automatically support @deftech{serialization}: they can be written to
an output stream, and a copy can be read back in from an input stream:

@interaction[
(define-values (in out) (make-pipe))
(write #s(sprout bean) out)
(read in)
]

@racket[struct] 创建的其他结构类型比 @tech{prefab} 结构类型
更抽象，通常使用 @racketresultfont{#<....>} 记法或
@racketresultfont{#(....)} vector 记法进行 @racket[write]。 在两种情况下结果都无法作为结构类型实例读回：

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

@racket[serializable-struct] 形式定义一个结构类型，
可被 @racket[serialize] 到可用 @racket[write] 打印、通过 @racket[read] 恢复的值。
该 @racket[serialize]d 结果可以被 @racket[deserialize] 恢复为原结构类型的实例。 The serialization form and functions are
由 @racketmodname[racket/serialize] 库提供。

@examples[
(require racket/serialize)
(serializable-struct posn (x y) #:transparent)
(deserialize (serialize (posn 1 2)))
(write (serialize (posn 1 2)))
(define-values (in out) (make-pipe))
(write (serialize (posn 1 2)) out)
(deserialize (read in))
]

除 @racket[struct] 绑定的名称外，
@racket[serializable-struct] 还绑定一个包含反序列化信息
的标识符，并自动从模块上下文中 @racket[provide] 该反序列化标识符。 在反序列化值时会反射访问这个反序列化标识符。

@; ----------------------------------------------------------------------
@section[#:tag "encodings"]{Bytes, Characters, and Encodings}

@racket[read-line]、@racket[read]、@racket[display] 和 @racket[write] 等函数
按 @tech{characters} 工作（对应 Unicode 标量值）。 从概念上的实现基于 @racket[read-char] 和 @racket[write-char]。

更原始地，端口读写 @tech{bytes} 而非 @tech{characters}。
@racket[read-byte] 和 @racket[write-byte] 读写原始字节。 其他函数，如 @racket[read-bytes-line]，构建在字节操作而
非字符操作之上。

事实上，@racket[read-char] 和 @racket[write-char] 的实现基于
@racket[read-byte] 和 @racket[write-byte]。 单个字节值小于 128 时对应于 ASCII 字符。
其他字节被视为 UTF-8 序列的一部分，
UTF-8 是将 Unicode 标量值编码为字节的特定标准方式
（具有 ASCII 字符自身作为自身编码的好属性）。 因此，单个 @racket[read-char] 可能多次调用 @racket[read-byte]，且
单个 @racket[write-char] 可能生成多个输出字节。

The @racket[read-char] and @racket[write-char] operations
@emph{始终} 使用 UTF-8 编码。 如果你有不同编码的文本流，或者想用不同编码
生成文本流，请使用 @racket[reencode-input-port] 或 @racket[reencode-output-port]。 @racket[reencode-input-port] 函数将你指定的输入流从其原始编码
转换为 UTF-8 流；这样，@racket[read-char] 就会看到 UTF-8 编码，
即使原始流使用了不同的编码。但请注意，
@racket[read-byte] 也会看到重新编码后的数据，而非原始字节流。

@; ----------------------------------------------------------------------
@section[#:tag "io-patterns"]{I/O Patterns}

@hash-lang-note[racket/port #:lang racket/base]

@(require (prefix-in ex: scribble/example))

@(begin
  (define port-eval (make-base-eval))
  (interaction-eval #:eval port-eval (require racket/port racket/string)))

对于这些示例，假设你有两个与程序在同一目录下的文件：
@filepath{oneline.txt} 和 @filepath{manylines.txt}。

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

如果文件较小，你可以将其作为字符串读取：

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

我们使用 @racketmodname[racket/port] 中的 @racket[port->string] 把文件读入字符串：
@racket[#:close? #t] 关键字参数确保读取后文件被关闭。

我们使用 @racketmodname[racket/string] 中的 @racket[string-trim] 来
去除文件开头和结尾的多余空白。
(Lots of formatters out there insist that text files end with a single
blank line).

如果你的文件只有一行文本，也可使用 @racket[read-line]。

如果你想处理文件的每一行，则可使用 @racket[for]
与 @racket[in-lines]：

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

你也可以练习每行的计算。 So if you want to
知道有多少行包含 ``m'', you could do:

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

在这里，@racketmodname[racket/port] 中的 @racket[with-input-from-file]
将默认输入端口设置为 @filepath{manylines.txt}。 它还在计算完成后结束文件（以及一些其他情况）。

如果你想确定是否有单词出现在文件中， ``hello'' appears in a file,
then you could search separate lines, but it's even easier to simply
apply a regular expression (see @secref["regexp"]) to the stream:

@interaction[
(define (has-hello? in)
  (regexp-match? #rx"hello" in))
(has-hello? (open-input-string "hello"))
(has-hello? (open-input-string "goodbye"))
]

如果要复制一个端口到另一个，请使用
@racketmodname[racket/port] 中的 @racket[copy-port]，它在有大量数据
时高效转移大块，但也会在无法提供更多时
立即转移小块：

@interaction[
#:eval port-eval
(define o (open-output-string))
(copy-port (open-input-string "broom") o)
(get-output-string o)
]

@close-eval[port-eval]

@; ----------------------------------------------------------------------

@close-eval[io-eval]
