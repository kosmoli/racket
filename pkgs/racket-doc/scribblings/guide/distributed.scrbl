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

@title[#:tag "distributed-places"]{Distributed Places}

@racketmodname[racket/place/distributed] 库提供分布式编程支持。

下面的示例演示了如何启动一个远程 Racket 节点实例、
在新的远程节点实例上启动远程 place，以及启动一个
监视远程节点实例的 event loop。

示例代码也可以在
@filepath{racket/distributed/examples/named/master.rkt} 中找到。



@figure["named-example-master" "examples/named/master.rkt"]{
@codeblockfromfile[(path->string (collection-file-path "master.rkt" "racket/place/distributed/examples/named"))]
}



@racket[spawn-remote-racket-node] 原语连接到
@tt{"localhost"} 并在那里启动一个 racloud 节点，该节点监听端口
6344 以接收进一步的指令。新 racloud 节点的句柄被
赋值给 @racket[remote-node] 变量。使用 localhost 是为了
使示例可以在单台机器上运行。不过，localhost
可以替换为任何具有 ssh publickey 访问权限和 Racket 的主机。
@racket[supervise-place-at] 在 @racket[remote-node] 上创建一个新 place。
新 place 将在以后通过其名称 symbol @racket['tuple-server] 来标识。
调用 @racket[dynamic-place] 时，期望通过
@racket[tuple-path] 模块路径和 @racket['make-tuple-server]
symbol 返回一个 place 描述符。

tuple-server place 的代码存在于文件
@filepath{tuple.rkt} 中。@filepath{tuple.rkt} 文件包含了
@racket[define-named-remote-server] 形式的使用，它定义了一个
适合由 @racket[supervise-place-at] 调用的 RPC server。



@figure["named-example" "examples/named/tuple.rkt"]{
@codeblockfromfile[(path->string (collection-file-path "tuple.rkt" "racket/place/distributed/examples/named"))]
}



@racket[define-named-remote-server] 形式接受一个标识符和一个
自定义表达式列表作为参数。通过在标识符前添加 @tt{make-} 前缀来创建
place-thunk 函数。在本例中为 @racket[make-tuple-server]。
@racket[make-tuple-server] 标识符是传递给
上面 @racket[supervise-named-dynamic-place-at] 形式的
@racket[place-function-name]。@racket[define-state] 自定义形式
被翻译为一个简单的 @racket[define] 形式，该形式被 @racket[define-rpc]
形式所封闭。

@racket[define-rpc] 形式被展开为两个部分。第一部分
是调用 rpc 函数的客户端 stub。客户端
函数名通过连接
@racket[define-named-remote-server] 标识符 @tt{tuple-server}
和 RPC 函数名 @tt{set} 形成 @racket[tuple-server-set]。
RPC 客户端函数接受一个目标参数（即
@racket[remote-connection%] 描述符），然后是 RPC 函数
参数。RPC 客户端函数通过调用内部函数
@racket[named-place-channel-put] 将 RPC 函数名 @racket[set]
和 RPC 参数发送到目标。然后 RPC 客户端
调用 @racket[named-place-channel-get] 等待 RPC 响应。

@racket[define-rpc] 的第二个展开部分是 RPC 调用的服务器端
实现。服务器通过 @racket[make-tuple-server] 函数内部的 match
表达式来实现。@racket[tuple-server-set] 的 match
子句匹配以 @racket['set] symbol 开头的消息。服务器使用
传递的参数执行 RPC 调用并将结果发送回 RPC 客户端。

@racket[define-cast] 形式类似于 @racket[define-rpc] 形式，
区别在于服务器不会向客户端发送回复消息

@figure["define-named-remote-server-expansion" "define-named-remote-server 的展开"]{
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





