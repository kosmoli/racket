#lang scribble/doc
@(require scribble/manual
          (except-in "guide-utils.rkt" log-message)
          scribble/eval
          scriblib/figure
          racket/port
          racket/contract
          (for-label racket/place/distributed
                     racket/match
                     racket/place/define-remote-server))

@(define (codeblockfromfile filename)
   (call-with-input-file
     filename
     (lambda (i)
       (codeblock0 (port->string i)))))

@title[#:tag "distributed-places"]{分布式 Places}

@racketmodname[racket/place/distributed] 库提供了对分布式编程的支持。

下面的示例演示了如何启动远程 racket 节点实例，
在新远程节点实例上启动远程 places，以及启动一个监控远程节点实例的事件循环。

示例代码也可见于
@filepath{racket/distributed/examples/named/master.rkt}。


@figure["named-example-master" "examples/named/master.rkt"]{
@codeblockfromfile[(path->string (collection-file-path "master.rkt" "racket/place/distributed/examples/named"))]
}



@racket[spawn-remote-racket-node] 原语连接到 @tt{"localhost"} 并在那里启动一个
racloud 节点，该节点监听 6344 端口以接收进一步指令。
新 racloud 节点的句柄被赋值给 @racket[remote-node] 变量。使用 localhost 是为了
该示例可以在单台机器上运行。但 localhost 可以被任何支持 ssh 公钥访问和 racket 的主机替代。
@racket[supervise-place-at] 在 @racket[remote-node] 上创建一个新 place。
新 place 将来会通过其名称符号 @racket['tuple-server] 来标识。
通过调用 @racket[dynamic-place] 并传入 @racket[tuple-path] 模块路径和
@racket['make-tuple-server] 符号，预期返回一个 place descriptor。

tuple-server place 的代码位于 @filepath{tuple.rkt} 文件中。
@filepath{tuple.rkt} 文件包含 @racket[define-named-remote-server] 形式的使用，
该形式定义了一个适合由 @racket[supervise-place-at] 调用的 RPC 服务器。



@figure["named-example" "examples/named/tuple.rkt"]{
@codeblockfromfile[(path->string (collection-file-path "tuple.rkt" "racket/place/distributed/examples/named"))]
}



@racket[define-named-remote-server] 形式接受一个标识符和自定义表达式列表作为其参数。
从标识符创建一个 place-thunk 函数，通过添加 @tt{make-} 前缀。
在本例中为 @racket[make-tuple-server]。@racket[make-tuple-server] 标识符是
上面传递给 @racket[supervise-named-dynamic-place-at] 形式的 @racket[place-function-name]。
@racket[define-state] 自定义形式翻译为一个简单的 @racket[define] 形式，
由 @racket[define-rpc] 形式闭包捕获。

@racket[define-rpc] 形式扩展为两部分。第一部分是客户端存根，
它们调用 RPC 函数。客户端函数名称由连接 @racket[define-named-remote-server] 标识符
@tt{tuple-server} 与 RPC 函数名称 @tt{set} 构成，形成 @racket[tuple-server-set]。RPC 客户端函数
接受一个目标参数，该参数是 @racket[remote-connection%] descriptor，然后是 RPC 函数参数。
RPC 客户端函数通过调用内部函数 @racket[named-place-channel-put]，将 RPC 函数名称 @racket[set]
和 RPC 参数发送到目的地。然后 RPC 客户端调用 @racket[named-place-channel-get] 等待 RPC 响应。

@racket[define-rpc] 的第二扩展部分是 RPC 调用的服务器实现。
服务器由 @racket[make-tuple-server] 函数内的 match 表达式实现。
@racket[tuple-server-set] 的 match 子句匹配以 @racket['set] 符号开始的消息。
服务器使用传递的参数执行 RPC 调用并将结果发送回 RPC 客户端。

@racket[define-cast] 形式类似于 @racket[define-rpc] 形式，
不同之处在于服务器到客户端没有回复消息。

@figure["define-named-remote-server-expansion" "define-named-remote-server 的扩展"]{
@codeblock0{
(module tuple racket/base
  (require racket/place
           racket/match)
  (define/provide
   (tuple-server-set dest k v)
   (named-place-channel-put dest (list 'set k v))
   (named-place-channel-get dest))
  (define/provide
   (tuple-server-get dest k)
   (named-place-channel-put dest (list 'get k))
   (named-place-channel-get dest))
  (define/provide
   (tuple-server-hello dest)
   (named-place-channel-put dest (list 'hello)))
  (define/provide
   (make-tuple-server ch)
    (let ()
      (define h (make-hash))
      (let loop ()
        (define msg (place-channel-get ch))
        (define (log-to-parent-real 
                  msg 
                  #:severity (severity 'info))
          (place-channel-put 
            ch 
            (log-message severity msg)))
        (syntax-parameterize
         ((log-to-parent (make-rename-transformer 
                           #'log-to-parent-real)))
         (match
          msg
          ((list (list 'set k v) src)
           (define result (let () (hash-set! h k v) v))
           (place-channel-put src result)
           (loop))
          ((list (list 'get k) src)
           (define result (let () (hash-ref h k #f)))
           (place-channel-put src result)
           (loop))
          ((list (list 'hello) src)
           (define result
             (let () 
               (printf "Hello from define-cast\n") 
               (flush-output)))
           (loop))))
        loop))))
}
}

