#lang scribble/doc
@(require scribble/manual
          scribble/urls
          scribble/eval
          (only-in scribble/struct make-render-element)
          racket/class
          (only-in scribble/core link-element)
          (only-in xrepl/doc-utils [cmd xreplcmd])
	  scribblings/private/docname
          (for-label racket/base
                     racket/tcp
                     racket/enter
                     xrepl
                     readline
                     net/url
                     xml
                     racket/control))

@(begin

(define (keep-file file)
  (make-render-element
   #f
   null
   (lambda (r s i) (send r install-file file))))


(define guide @other-manual['(lib "guide.scrbl" "scribblings/guide")])

(define more-eval (make-base-eval))
(interaction-eval #:eval more-eval
                  (define (show-load re?)
                    (fprintf (current-error-port)
                             " [~aloading serve.rkt]\n" (if re? "re-" ""))))
(interaction-eval #:eval more-eval
                  (define (serve n) void))
(interaction-eval #:eval more-eval
                  (define (show-break)
                    (fprintf (current-error-port) "^Cuser break")))
(interaction-eval #:eval more-eval
                  (define (show-fail n)
                    (error 'tcp-listen
                           "listen on ~a failed (address already in use)"
                           n)))
(interaction-eval #:eval more-eval (require xml net/url))

(define (whole-prog which [last? #f])
  (let ([file (format "step~a.txt" which)])
    (margin-note (keep-file file)
                 "Here's the "
                 (if last?
                     "final program"
                     "whole program so far")
                 " in plain text: "
                 (link file "step " which) ".")))

(define-syntax-rule (REQ m) @racket[(require @#,racketmodname[m])])

)

@title{More: Systems Programming with Racket}

@author["Matthew Flatt"]

与 @Quick[Quick-title] 可能给人的印象不同，Racket 不仅仅是又一个漂亮的界面。在 DrRacket 图形化外观之下，隐藏着一个用于管理线程和进程的精密工具箱，这正是本教程的主题。

具体来说，我们将展示如何构建一个安全、多线程、可扩展 servlet、基于 continuation 的 web 服务器。我们将使用比 @Quick[Quick-title] 更多的语言特性，并且希望你点击不认识的语法或函数名（它们会带你到相关文档）。请注意，最后几节的内容通常被认为比较困难。如果你对 Racket 还不太熟悉，编程经验也相对较少，你可能想跳到 @|guide|。

为了进入本教程的氛围，我们建议你暂时放下 DrRacket，在终端中切换到原生的 @exec{racket}。
@;
@margin-note*{如果你已经习惯了 DrRacket，可以继续使用它。在这种情况下，跳过 @secref["ready"]，按照 @secref["set"] 中的描述在 DrRacket 的定义窗口中构建程序，而不是创建 @filepath{serve.rkt} 文件，然后点击 @onscreen{Run} 按钮，而不是像 @secref["go"] 中所示使用 @racket[enter!]。}
@;
你还需要一个文本编辑器，如 Emacs、vi 甚至 Notepad——任何编辑器都可以，但支持括号匹配的会更有帮助。最后，你还需要一个 web 客户端，比如 Lynx 或 Firefox。

@; ----------------------------------------------------------------------
@section[#:tag "ready"]{Ready...}

@link[url:download-drracket]{下载 Racket}，安装，然后不带命令行参数启动 @exec{racket}：

@verbatim[#:indent 2]{
  $ racket
  @(regexp-replace #rx"\n+$" (banner) "")
  > 
}

@margin-note{设置你的 @tt{PATH} 环境变量，以便使用 @exec{raco} 和其他 Racket 命令行功能。在 Mac OS 上：@tt{sudo sh -c @literal{'}echo "/Applications/Racket v@version{}/bin" 
 >> /etc/paths.d/racket@literal{'}}（假设你已将 Racket 安装在 @filepath{Applications} 文件夹中）。在 Windows 上：将 Racket 安装路径添加到 @onscreen{Environment Variables}（在 @onscreen{System Properties} 的 @onscreen{Advanced} 选项卡下）中的 @onscreen{Path}。}
 
假设你已安装 Editline，@margin-note*{要使用 GNU Readline 而不是 Editline，请设置 @envvar{PLT_READLINE_LIB} 环境变量或安装 @filepath{readline-gpl} 包。}
@exec{racket} 默认支持行编辑和以逗号为前缀的元命令，这些元命令支持探索和开发。更多信息请参见 @racketmodname[xrepl #:indirect]。

@; ----------------------------------------------------------------------
@section[#:tag "set"]{Set...}

在启动 @exec{racket} 的同一目录中，创建一个文本文件 @filepath{serve.rkt}，并按如下方式开始编写：

@racketmod[
racket

(define (go)
  'yep-it-works)
]

@whole-prog["0"]

@; ----------------------------------------------------------------------
@section[#:tag "go"]{Go!}

回到 @exec{racket} 中，尝试加载文件并运行 @racket[go]：

@margin-note{如果你使用 @racketmodname[xrepl]，可以使用 @xreplcmd["enter"]{serve.rkt}。}

@interaction[
#:eval more-eval
(eval:alts (enter! "serve.rkt") (show-load #f))
(eval:alts (go) 'yep-it-works)
]

尝试修改 @filepath{serve.rkt}，然后再次运行 @racket[(enter! "serve.rkt")] 重新加载模块，然后检查你的更改。

@; ----------------------------------------------------------------------
@section{``Hello World'' Server}

我们将通过一个 @racket[serve] 函数来实现 web 服务器，该函数接受一个用于客户端连接的 IP 端口号：

@racketblock[
(define (serve port-no)
  ...)
]

服务器通过一个 @defterm{listener} 接受 TCP 连接，我们使用 @racket[tcp-listen] 创建它。为了让交互式开发更方便，我们将 @racket[#t] 作为 @racket[tcp-listen] 的第三个参数，这样我们可以立即重用端口号，而无需等待 TCP 超时。

@racketblock[
(define (serve port-no)
  (define listener (tcp-listen port-no 5 #t))
  ...)
]

服务器必须循环以接受来自 listener 的连接：

@racketblock[
(define (serve port-no)
  (define listener (tcp-listen port-no 5 #t))
  (define (loop)
    (accept-and-handle listener)
    (loop))
  (loop))
]

我们的 @racket[accept-and-handle] 函数使用 @racket[tcp-accept] 接受连接，该函数返回两个值：一个用于从客户端输入的流，和一个用于向客户端输出的流。

@racketblock[
(define (accept-and-handle listener)
  (define-values (in out) (tcp-accept listener))
  (handle in out)
  (close-input-port in)
  (close-output-port out))
]

为了处理连接，目前我们将读取并丢弃请求头，然后写入一个 "Hello, world!" 网页作为结果：

@racketblock[
(define (handle in out)
  (code:comment @#,t{Discard the request header (up to blank line):})
  (regexp-match #rx"(\r\n|^)\r\n" in)
  (code:comment @#,t{Send reply:})
  (display "HTTP/1.0 200 Okay\r\n" out)
  (display "Server: k\r\nContent-Type: text/html\r\n\r\n" out)
  (display "<html><body>Hello, world!</body></html>" out))
]

注意，@racket[regexp-match] 直接在输入流上操作，这比逐行处理更方便。

@whole-prog["1"]

将上述三个定义——@racket[serve]、@racket[accept-and-handle] 和 @racket[handle]——复制到 @filepath{serve.rkt} 中并重新加载：

@interaction[
#:eval more-eval
(eval:alts (enter! "serve.rkt") (show-load #t))
(eval:alts (serve 8080) (void))
]

现在将你的浏览器指向 @tt{http://localhost:8080}（假设你使用 @racket[8080] 作为端口号，且浏览器在同一台机器上运行），即可收到来自你的 web 服务器的友好问候。

@; ----------------------------------------------------------------------
@section{Server Thread}

在让 web 服务器以更有趣的方式响应之前，我们需要恢复 Racket 提示符。在终端窗口中输入 Ctl-C 可以中断服务器循环：

@margin-note{在 DrRacket 中，无需输入 Ctl-C，只需点击一次 @onscreen{Stop} 按钮。}

@interaction[
#:eval more-eval
(eval:alts (serve 8080) (show-break))
(eval:alts code:blank (void))
]

不幸的是，我们现在无法使用相同的端口号重新启动服务器：

@interaction[
#:eval more-eval
(eval:alts (serve 8080) (show-fail 8080))
]

问题在于我们用 @racket[serve] 创建的 listener 仍在原始端口号上监听。

为了避免这个问题，让我们将 listener 循环放入自己的线程中，并让 @racket[serve] 立即返回。此外，我们让 @racket[serve] 返回一个函数，用于关闭服务器线程和 TCP listener：

@racketblock[
(define (serve port-no)
  (define listener (tcp-listen port-no 5 #t))
  (define (loop)
    (accept-and-handle listener)
    (loop))
  (define t (thread loop))
  (lambda ()
    (kill-thread t)
    (tcp-close listener)))
]

@whole-prog["2"]

试试新的版本：

@interaction[
#:eval more-eval
(eval:alts (enter! "serve.rkt") (show-load #t))
(define stop (serve 8081))
]

你的服务器现在应该能响应 @tt{http://localhost:8081}，而且你可以随意地在同一端口号上关闭和重启服务器：

@interaction[
#:eval more-eval
(stop)
(define stop (serve 8081))
(stop)
(define stop (serve 8081))
(stop)
]

@; ----------------------------------------------------------------------
@section{Connection Threads}

就像我们将主服务器循环放入后台线程一样，我们可以将每个单独的连接也放入自己的线程中：

@racketblock[
(define (accept-and-handle listener)
  (define-values (in out) (tcp-accept listener))
  (thread
   (lambda ()
     (handle in out)
     (close-input-port in)
     (close-output-port out))))
]

@whole-prog["3"]

通过这个改动，我们的服务器现在可以同时处理多个线程。然而，handler 速度太快，以至于很难察觉到这一点，因此尝试在上面的 @racket[handle] 调用之前插入 @racket[(sleep (random 10))]。如果你大致同时在 web 浏览器中发起多个连接，有些会很快返回，有些则最多需要 10 秒。随机延迟独立于你发起连接的顺序。

@; ----------------------------------------------------------------------
@section{Terminating Connections}

恶意客户端可能连接到我们的 web 服务器但不发送 HTTP 头，在这种情况下连接线程将永远空闲，等待头部的结束。为了避免这种可能性，我们希望为每个连接线程实现一个超时机制。

实现超时的一种方法是创建第二个线程，等待 10 秒，然后终止调用 @racket[handle] 的线程。在 Racket 中，线程足够轻量，这种观察者线程策略效果很好：

@racketblock[
(define (accept-and-handle listener)
  (define-values (in out) (tcp-accept listener))
  (define t (thread
              (lambda () 
                (handle in out)
                (close-input-port in)
                (close-output-port out))))
  (code:comment @#,t{Watcher thread:})
  (thread (lambda ()
            (sleep 10)
            (kill-thread t))))
]

第一次尝试并不完全正确，因为当线程被终止时，其 @racket[in] 和 @racket[out] 流仍然保持打开状态。我们可以在观察者线程中添加代码来关闭流并终止线程，但 Racket 提供了更通用的关闭机制：@defterm{custodians}。custodian 是一种包含除内存外所有资源的容器，它支持 @racket[custodian-shutdown-all] 操作，该操作可以终止并关闭容器内的所有资源，无论是线程、流还是其他类型的有限资源。

每当创建线程或流时，它会被放入由 @racket[current-custodian] parameter 确定的当前 custodian 中。为了将连接相关的所有内容放入一个 custodian 中，我们使用 @racket[parameterize] 将所有资源的创建导向一个新的 custodian：

@margin-note{关于 parameter 的介绍，参见 @secref[#:doc '(lib "scribblings/guide/guide.scrbl") "parameterize"]。}

@racketblock[
(define (accept-and-handle listener)
  (define cust (make-custodian))
  (parameterize ([current-custodian cust])
    (define-values (in out) (tcp-accept listener))
    (thread (lambda ()
              (handle in out)
              (close-input-port in)
              (close-output-port out))))
  (code:comment @#,t{Watcher thread:})
  (thread (lambda ()
            (sleep 10)
            (custodian-shutdown-all cust))))
]

通过这种实现，@racket[in]、@racket[out] 以及调用 @racket[handle] 的线程都属于 @racket[cust]。此外，如果以后我们修改 @racket[handle] 使其打开文件，那么文件句柄也将属于 @racket[cust]，因此当 @racket[cust] 被关闭时，它们会被可靠地关闭。

事实上，修改 @racket[serve] 使其也使用 custodian 是个好主意：

@racketblock[
(define (serve port-no)
  (define main-cust (make-custodian))
  (parameterize ([current-custodian main-cust])
    (define listener (tcp-listen port-no 5 #t))
    (define (loop)
      (accept-and-handle listener)
      (loop))
    (thread loop))
  (lambda ()
    (custodian-shutdown-all main-cust)))
]

这样，在 @racket[serve] 中创建的 @racket[main-cust] 不仅拥有 TCP listener 和主服务器线程，还拥有为每个连接创建的每个 custodian。因此，修改后的服务器关闭过程不仅会终止主服务器循环，还会立即终止所有活动连接。

@whole-prog["4"]

按照上述方式更新 @racket[serve] 和 @racket[accept-and-handle] 函数后，以下是模拟恶意客户端的方法：

@interaction[
#:eval more-eval
(eval:alts (enter! "serve.rkt") (show-load #t))
(define stop (serve 8081))
(eval:alts (define-values (cin cout) (tcp-connect "localhost" 8081)) (void))
]

现在等待 10 秒。如果你尝试从 @racket[cin] 读取数据——这是将数据从服务器发回客户端的流——你会发现服务器已经关闭了连接：

@interaction[
#:eval more-eval
(eval:alts (read-line cin) eof)
]

或者，如果你显式关闭服务器，就不必等待 10 秒：

@interaction[
#:eval more-eval
(eval:alts (define-values (cin2 cout2) (tcp-connect "localhost" 8081)) (void))
(stop)
(eval:alts (read-line cin2) eof)
]

@; ----------------------------------------------------------------------
@section{Dispatching}

终于到了将服务器的 "Hello, World!" 响应扩展为更有用内容的时候了。让我们调整服务器，使其可以接入 dispatch 函数来处理不同 URL 的请求。

为了解析传入的 URL 并更方便地格式化 HTML 输出，我们需要引入两个额外的库：

@racketblock[
(require xml net/url)
]

@racketmodname[xml] 库为我们提供了 @racket[xexpr->string]，它接受一个看起来像 HTML 的 Racket 值，并将其转换为实际的 HTML：

@interaction[
#:eval more-eval
(xexpr->string '(html (head (title "Hello")) (body "Hi!")))
]

我们假设新的 @racket[dispatch] 函数（待编写）接受一个请求的 URL，并生成一个适合与 @racket[xexpr->string] 一起使用的返回值，发送回客户端：

@racketblock[
(define (handle in out)
  (define req
    (code:comment @#,t{Match the first line to extract the request:})
    (regexp-match #rx"^GET (.+) HTTP/[0-9]+\\.[0-9]+"
                  (read-line in)))
  (when req
    (code:comment @#,t{Discard the rest of the header (up to blank line):})
    (regexp-match #rx"(\r\n|^)\r\n" in)
    (code:comment @#,t{Dispatch:})
    (let ([xexpr (dispatch (list-ref req 1))])
      (code:comment @#,t{Send reply:})
      (display "HTTP/1.0 200 Okay\r\n" out)
      (display "Server: k\r\nContent-Type: text/html\r\n\r\n" out)
      (display (xexpr->string xexpr) out))))
]

@racketmodname[net/url] 库为我们提供了 @racket[string->url]、@racket[url-path]、@racket[path/param-path] 和 @racket[url-query]，用于从字符串中提取其所代表的 URL 的各个部分：

@interaction[
#:eval more-eval
(define u (string->url "http://localhost:8080/foo/bar?x=bye"))
(url-path u)
(map path/param-path (url-path u))
(url-query u)
]

我们使用这些组件来实现 @racket[dispatch]。@racket[dispatch] 函数查询一个 hash table，该表将初始路径元素（如 @racket["foo"]）映射到 handler 函数：

@racketblock[
(define (dispatch str-path)
  (code:comment @#,t{Parse the request as a URL:})
  (define url (string->url str-path))
  (code:comment @#,t{Extract the path part:})
  (define path (map path/param-path (url-path url)))
  (code:comment @#,t{Find a handler based on the path's first element:})
  (define h (hash-ref dispatch-table (car path) #f))
  (if h
      (code:comment @#,t{Call a handler:})
      (h (url-query url))
      (code:comment @#,t{No handler found:})
      `(html (head (title "Error"))
            (body
             (font ((color "red"))
                   "Unknown page: " 
                   ,str-path)))))

(define dispatch-table (make-hash))
]

有了新的 @racket[require] import 和新的 @racket[handle]、@racket[dispatch] 和 @racket[dispatch-table] 定义，我们的 "Hello World!" 服务器变成了一个错误服务器。你无需停止服务器就能试用。用新的部分修改 @filepath{serve.rkt} 后，执行 @racket[(enter! "serve.rkt")]，然后再次尝试连接服务器。web 浏览器应该会以红色显示 "Unknown page" 错误。

我们可以像这样为 @racket["hello"] 路径注册一个 handler：

@racketblock[
(hash-set! dispatch-table "hello"
           (lambda (query) 
             `(html (body "Hello, World!"))))
]

@whole-prog["5"]

添加这些行并执行 @racket[(enter! "serve.rkt")] 后，打开 @tt{http://localhost:8081/hello} 应该会显示原来的问候语。

@; ----------------------------------------------------------------------
@section{Servlets and Sessions}

使用 @racket[dispatch] 传递给 handler 的 @racket[query] 参数，handler 可以响应用户通过表单提供的值。

以下辅助函数构造一个 HTML 表单。@racket[label] 参数是显示给用户的字符串。@racket[next-url] 参数是表单结果的目的地。@racket[hidden] 参数是一个通过表单作为隐藏字段传播的值。当用户响应时，表单中的 @racket["number"] 字段保存用户的值：

@racketblock[
(define (build-request-page label next-url hidden)
  `(html 
    (head (title "Enter a Number to Add"))
    (body ([bgcolor "white"])
          (form ([action ,next-url] [method "get"])
                ,label
                (input ([type "text"] [name "number"]
                                      [value ""]))
                (input ([type "hidden"] [name "hidden"]
                                        [value ,hidden]))
                (input ([type "submit"] [name "enter"] 
                                        [value "Enter"]))))))
]

使用这个辅助函数，我们可以创建一个 servlet，生成用户想要的任意多个 "hello"：

@margin-note{关于 @racket[for/list] 等形式（form）的介绍，参见 @secref[#:doc '(lib "scribblings/guide/guide.scrbl") "for"]。}

@racketblock[
(define (many query)
  (build-request-page "Number of greetings:" "/reply" ""))

(define (reply query)
  (define n (string->number (cdr (assq 'number query))))
  `(html (body ,@(for/list ([i (in-range n)])
                   " hello"))))

(hash-set! dispatch-table "many" many)
(hash-set! dispatch-table "reply" reply)
]

@whole-prog["6"]

像往常一样，将这些添加到你的程序中后，使用 @racket[(enter! "serve.rkt")] 更新，然后访问 @tt{http://localhost:8081/many}。提供一个数字，你将收到一个包含相应数量 "hello" 的新页面。

@; ----------------------------------------------------------------------
@section{Limiting Memory Use}

有了最新的 @racket["many"] servlet，我们似乎遇到了一个新问题：恶意客户端可能请求太多 "hello"，导致服务器耗尽内存。实际上，恶意客户端还可能会提供一个第一行任意长的 HTTP 请求。

解决这类问题的方法是限制连接的内存使用。在 @racket[accept-and-handle] 内部，在 @racket[cust] 的定义之后，添加以下行

@racketblock[(custodian-limit-memory cust (* 50 1024 1024))]

@whole-prog["7"]

我们假设 50MB 对于任何 servlet 来说都足够。垃圾回收器的开销意味着系统的实际内存使用量可能是 50MB 的某个小倍数。然而，一个重要的保证是，不同的连接不会为彼此的内存使用付费，因此一个行为不当的连接不会干扰另一个连接。

因此，有了上面的新行，并假设你有几百兆字节可供 @exec{racket} 进程使用，你应该无法通过请求荒谬数量级的 "hello" 来使 web 服务器崩溃。

有了 @racket["many"] 的例子，只需一小步就能构建一个接受任意 Racket 代码在服务器上执行的 web 服务器。在这种情况下，除了限制处理器时间和内存消耗之外，还有许多额外的安全问题。@racketmodname[racket/sandbox] 库提供了管理所有这些其他问题的支持。

@; ----------------------------------------------------------------------
@section{Continuations}

作为一个系统示例，实现 web 服务器的问题暴露了许多系统和安全问题，而编程语言可以在这方面提供帮助。这个 web 服务器示例还引出了一个经典的、高级的 Racket 主题：@defterm{continuations}。事实上，web 服务器的这一方面需要 @defterm{delimited continuations}，Racket 提供了这一特性。

continuation 解决的问题与 servlet 会话和用户输入有关，其中计算跨越多个客户端连接 @cite["Queinnec00"]。通常，客户端计算（如 AJAX）是解决该问题的正确方案，但许多问题最好通过混合技术来解决（例如，利用浏览器的"后退"按钮）。

随着多连接计算变得越来越复杂，通过 @racket[query] 传播参数变得越来越繁琐。例如，我们可以实现一个 servlet，通过使用表单中的隐藏字段来记住第一个数字，从而接受两个数字进行相加：

@racketblock[
(define (sum query)
  (build-request-page "First number:" "/one" ""))

(define (one query)
  (build-request-page "Second number:"
                      "/two"
                      (cdr (assq 'number query))))

(define (two query)
  (let ([n (string->number (cdr (assq 'hidden query)))]
        [m (string->number (cdr (assq 'number query)))])
    `(html (body "The sum is " ,(number->string (+ m n))))))

(hash-set! dispatch-table "sum" sum)
(hash-set! dispatch-table "one" one)
(hash-set! dispatch-table "two" two)
]

@whole-prog["8"]

虽然上述方法可行，但我们更希望以直接的风格编写这样的计算：

@racketblock[
(define (sum2 query)
  (define m (get-number "First number:"))
  (define n (get-number "Second number:"))
  `(html (body "The sum is " ,(number->string (+ m n)))))

(hash-set! dispatch-table "sum2" sum2)
]

问题在于 @racket[get-number] 需要为当前连接发回 HTML 响应，然后必须通过新的连接获取响应。也就是说，它需要以某种方式将 @racket[build-request-page] 生成的页面转换为 @racket[query] 结果：

@racketblock[
(define (get-number label)
  (define query
    ... (build-request-page label ...) ...)
  (number->string (cdr (assq 'number query))))
]

continuation 使我们能够实现一个 @racket[send/suspend] 操作来精确执行该操作。@racket[send/suspend] 过程生成一个 URL，该 URL 代表当前连接的计算，并将其捕获为一个 continuation。它将生成的 URL 传递给一个创建查询页面的过程；该查询页面被用作当前连接的结果，而周围的计算（即 continuation）被中止。最后，@racket[send/suspend] 安排对生成的 URL 的请求（在新的连接中）来恢复被中止的计算。

因此，@racket[get-number] 的实现如下：

@racketblock[
(define (get-number label)
  (define query
    (code:comment @#,t{Generate a URL for the current computation:})
    (send/suspend
      (code:comment @#,t{Receive the computation-as-URL here:})
      (lambda (k-url)
        (code:comment @#,t{Generate the query-page result for this connection.})
        (code:comment @#,t{Send the query result to the saved-computation URL:})
        (build-request-page label k-url ""))))
  (code:comment @#,t{We arrive here later, in a new connection})
  (string->number (cdr (assq 'number query))))
]

我们仍然需要实现 @racket[send/suspend]。为此，我们导入一个控制操作符库：

@racketblock[(require racket/control)]

具体来说，我们需要 @racketmodname[racket/control] 中的 @racket[prompt] 和 @racket[abort]。我们使用 @racket[prompt] 来标记 servlet 启动的位置，以便我们可以将计算中止到该点。通过在 @racket[dispatch] 调用周围包裹一个 @racket[prompt] 来修改 @racket[handle]：

@racketblock[
(define (handle in out)
  ....
    (let ([xexpr (prompt (dispatch (list-ref req 1)))])
      ....))
]

现在，我们可以实现 @racket[send/suspend]。我们以 @racket[let/cc] 的形式使用 @racket[call/cc]，它捕获到封闭的 @racket[prompt] 为止的当前计算，并将该计算绑定到一个标识符——在本例中是 @racket[k]：

@racketblock[
(define (send/suspend mk-page)
  (let/cc k
    ...))
]

接下来，我们生成一个新的 dispatch 标签，并记录从标签到 @racket[k] 的映射：

@racketblock[
(define (send/suspend mk-page)
  (let/cc k
    (define tag (format "k~a" (current-inexact-milliseconds)))
    (hash-set! dispatch-table tag k)
    ...))
]

最后，我们中止当前计算，转而提供通过将给定的 @racket[mk-page] 应用于生成标签的 URL 所构建的页面：
  
@racketblock[
(define (send/suspend mk-page)
  (let/cc k
    (define tag (format "k~a" (current-inexact-milliseconds)))
    (hash-set! dispatch-table tag k)
    (abort (mk-page (string-append "/" tag)))))
]

当用户提交表单时，与表单 URL 关联的 handler 是旧的计算，作为 continuation 存储在 dispatch table 中。调用 continuation（就像调用函数一样）会恢复旧的计算，将 @racket[query] 参数传递回该计算。

@whole-prog["9" #t]

总结一下，新增的部分有：@racket[(require racket/control)]、在 @racket[handle] 内添加 @racket[prompt]、@racket[send/suspend]、@racket[get-number] 和 @racket[sum2] 的定义，以及 @racket[(hash-set! dispatch-table "sum2" sum2)]。更新服务器后，访问 @tt{http://localhost:8081/sum2}。

@; ----------------------------------------------------------------------
@section{Where to Go From Here}

Racket 发行版包含一个生产质量的 web 服务器，它涵盖了这里提到的所有设计要点以及更多。要了解更多信息，请参见教程 @Continue[Continue-title]、@Web[] 或研究论文 @cite["Krishnamurthi07"]。

否则，如果你是通过 Racket 介绍来到这里，那么你的下一站可能是 @|guide|。

如果这里涵盖的主题是你感兴趣的类型，另请参见 @other-manual['(lib "scribblings/reference/reference.scrbl")] 中的 @secref["concurrency" #:doc '(lib
"scribblings/reference/reference.scrbl")] 和 @secref["security" #:doc
'(lib "scribblings/reference/reference.scrbl")]。

这些材料中的一部分基于相对较新的研究，更多信息可以在 Racket 作者撰写的论文中找到，包括关于 GRacket（以前称为 "MrEd"）的论文 @cite["Flatt99"]、内存记账 @cite["Wick04"]、kill-safe 抽象 @cite["Flatt04"] 和 delimited continuation @cite["Flatt07"]。

@; ----------------------------------------------------------------------

@(bibliography

  (bib-entry #:key "Flatt99"
             #:author "Matthew Flatt, Robert Bruce Findler, Shriram Krishnamurthi, and Matthias Felleisen"
             #:title @elem{Programming Languages as Operating Systems
                          (@emph{or} Revenge of the Son of the Lisp Machine)}
             #:location "International Conference on Functional Programming"
             #:date "1999"
             #:url "http://www.ccs.neu.edu/scheme/pubs/icfp99-ffkf.pdf")

  (bib-entry #:key "Flatt04"
             #:author "Matthew Flatt and Robert Bruce Findler"
             #:title "Kill-Safe Synchronization Abstractions"
             #:location "Programming Language Design and Implementation" 
             #:date "2004"
             #:url "http://www.cs.utah.edu/plt/publications/pldi04-ff.pdf")

  (bib-entry #:key "Flatt07"
             #:author "Matthew Flatt, Gang Yu, Robert Bruce Findler, and Matthias Felleisen"
             #:title "Adding Delimited and Composable Control to a Production Programming Environment"
             #:location "International Conference on Functional Programming"
             #:date "2007"
             #:url "http://www.cs.utah.edu/plt/publications/icfp07-fyff.pdf")

  (bib-entry #:key "Krishnamurthi07"
             #:author "Shriram Krishnamurthi, Peter Hopkins, Jay McCarthy, Paul T. Graunke, Greg Pettyjohn, and Matthias Felleisen"
             #:title "Implementation and Use of the PLT Scheme Web Server"
             #:location @italic{Higher-Order and Symbolic Computation}
             #:date "2007"
             #:url "http://www.cs.brown.edu/~sk/Publications/Papers/Published/khmgpf-impl-use-plt-web-server-journal/paper.pdf")

  (bib-entry #:key "Queinnec00"
             #:author "Christian Queinnec"
             #:title "The Influence of Browsers on Evaluators or, Continuations to Program Web Servers"
             #:location "International Conference on Functional Programming"
             #:date "2000"
             #:url "http://pagesperso-systeme.lip6.fr/Christian.Queinnec/PDF/webcont.pdf")

  (bib-entry #:key "Wick04"
             #:author "Adam Wick and Matthew Flatt"
             #:title "Memory Accounting without Partitions"
             #:location "International Symposium on Memory Management"
             #:date "2004"
             #:url "http://www.cs.utah.edu/plt/publications/ismm04-wf.pdf")

)




@close-eval[more-eval]
