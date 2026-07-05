#lang scribble/doc
@(require "mz.rkt")

@(define sp-eval (make-base-eval))
@examples[#:hidden #:eval sp-eval (require racket/list)]

@title[#:tag "stringport"]{String Port}

@deftech{string port} 从一个 @tech{byte string} 读取或向其写入。
输入 @tech{string port} 可以从 @tech{byte string} 或 @tech{string} 创建；
在后一种情况下，@tech{string} 会有效地使用 @racket[string->bytes/utf-8] 
被转换为 @tech{byte string}。输出 @tech{string port} 将输出累积到 @tech{byte string} 中，
但 @racket[get-output-string] 方便地将累积的 bytes 转换为 @tech{string}。

输入和输出 @tech{string port} 不需要被显式关闭。@racket[file-position] 过程
在位置设置模式下适用于 @tech{string port}。

@refalso["bytestrings"]{bytestrings}

@defproc[(string-port? [p port?]) boolean?]{

如果 @racket[p] 是 @tech{string port} 则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.0.1.6"]}

@defproc[(open-input-bytes [bstr bytes?] [name any/c 'string])
         (and/c input-port? string-port?)]{

创建一个输入 @tech{string port}，从 @racket[bstr] 读取字符
（参见 @secref["bytestrings"]）。之后修改 @racket[bstr] 不会影响
端口产生的 byte stream。可选的 @racket[name] 参数用作返回端口的名称。

@examples[#:eval sp-eval
  (define sp (open-input-bytes #"(apples 42 day)"))
  (define sexp1 (read sp))
  (first sexp1)
  (rest sexp1)
  (read-line (open-input-bytes
              #"the cow jumped over the moon\nthe little dog\n"))
]

@refalso["strings"]{strings}

@defproc[(open-input-string [str string?] [name any/c 'string])
         (and/c input-port? string-port?)]{

创建一个输入 @tech{string port}，从 @racket[str] 的 UTF-8 编码读取 bytes
（参见 @secref["encodings"]）。可选的 @racket[name] 参数用作返回端口的名称。}

@examples[#:eval sp-eval
  (define sp (open-input-string "(λ (x) x)"))
  (read sp)
  (define names (open-input-string "Günter Harder\nFrédéric Paulin\n"))
  (read-line names)
  (read-line names)]

@defproc[(open-output-bytes [name any/c 'string])
         (and/c output-port? string-port?)]

创建一个输出 @tech{string port}，将输出累积到 byte string 中。
可选的 @racket[name] 参数用作返回端口的名称。

@examples[ #:eval sp-eval
  (define op1 (open-output-bytes))
  (write '((1 2 3) ("Tom" "Dick") ('a 'b 'c)) op1)
  (get-output-bytes op1)
  (define op2 (open-output-bytes))
  (write "Hi " op2)
  (write "there" op2)
  (get-output-bytes op2)
  (define op3 (open-output-bytes))
  (write-bytes #"Hi " op3)
  (write-bytes #"there" op3)
  (get-output-bytes op3)
]

@defproc[(open-output-string [name any/c 'string])
         (and/c output-port? string-port?)]

与 @racket[open-output-bytes] 相同。

@examples[ #:eval sp-eval
  (define op1 (open-output-string))
  (write '((1 2 3) ("Tom" "Dick") ('a 'b 'c)) op1)
  (get-output-string op1)
  (define op2 (open-output-string))
  (write "Hi " op2)
  (write "there" op2)
  (get-output-string op2)
  (define op3 (open-output-string))
  (write-string "Hi " op3)
  (write-string "there" op3)
  (get-output-string op3)
]

@defproc[(get-output-bytes [out (and/c output-port? string-port?)]
                           [reset? any/c #f]
                           [start-pos exact-nonnegative-integer? 0]
                           [end-pos exact-nonnegative-integer? #f])
         bytes?]{

在新分配的 @tech{byte string} 中返回迄今为止在 @tech{string port} @racket[out] 中累积的 bytes
（包括端口当前位置之后写入的任何 bytes）。@racket[out] 端口必须是 @racket[open-output-bytes]
（或 @racket[open-output-string]）产生的输出 @tech{string port}，或者
是其 @racket[prop:output-port] 属性引用此类输出端口的结构（可传递地）。

如果 @racket[reset?] 为真，则端口中的所有 bytes 将被移除，端口的位置将重置为
@racket[0]；如果 @racket[reset?] 为 @racket[#f]，则所有 bytes 保留在端口中
供进一步累积（因此它们会在后续对 @racket[get-output-bytes] 或 @racket[get-output-string]
的调用中返回），端口的位置不变。

@racket[start-pos] 和 @racket[end-pos] 参数指定要返回的端口中 bytes 的范围；
提供 @racket[start-pos] 和 @racket[end-pos] 与使用 @racket[subbytes] 于
@racket[get-output-bytes] 的结果相同，但将它们提供给 @racket[get-output-bytes]
可以避免分配。@racket[end-pos] 参数可以是 @racket[#f]，对应于不向
@racket[subbytes] 传递第二个参数。}

@examples[ #:eval sp-eval
  (define op (open-output-bytes))
  (write '((1 2 3) ("Tom" "Dick") ('a 'b 'c)) op)
  (get-output-bytes op)
  (get-output-bytes op #f 3 16)
  (get-output-bytes op #t)
  (get-output-bytes op)]

@defproc[(get-output-string [out (and/c output-port? string-port?)]) string?]

返回 @racket[(bytes->string/utf-8 (get-output-bytes out) @#,racketvalfont{#\uFFFD})]。}

@examples[
(define i (open-input-string "hello world"))
(define o (open-output-string))
(write (read i) o)
(get-output-string o)
]

@close-eval[sp-eval]
