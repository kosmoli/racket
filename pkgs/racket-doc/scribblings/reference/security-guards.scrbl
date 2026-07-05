#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "securityguards"]{Security Guards}

@defproc[(security-guard? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[make-security-guard] 创建的值，则返回 @racket[#t]，
否则返回 @racket[#f]。}


@deftech{security guard} 提供了一组访问检查过程，当 thread 通过 primitive procedure 发起对文件、
目录或网络连接的访问时调用这些过程。例如，
当 thread 调用 @racket[open-input-file] 时，将咨询 thread 的当前 security guard
以检查 thread 是否允许对该文件进行读访问。如果授予访问权限，
thread 将获得一个可以无限期使用的 port，无论 security guard 
如何更改（尽管 port 的 custodian 可以关闭 port；参见 @secref["custodians"]）。

thread 的当前 security guard 由 @racket[current-security-guard] parameter 确定。
每个 security guard 都有一个父级，每当调用子级的访问过程时，也会调用父级的访问过程。
因此，thread 不能通过安装新的 guard 随意增加自己的访问权限。
初始 security guard 除了主机平台执行的访问限制外，不执行其他访问限制。

@defproc[(make-security-guard [parent security-guard?]
                              [file-guard (symbol? 
                                           (or/c path? #f)
                                           (listof symbol?) 
                                           . -> . any)]
                              [network-guard (symbol?
                                              (or/c (and/c string? immutable?) #f)
                                              (or/c (integer-in 1 65535) #f)
                                              (or/c 'server 'client)
                                              . -> . any)]
                              [link-guard (or/c (symbol? path? path? . -> . any) #f)
                                          #f])
         security-guard?]{

创建一个作为 @racket[parent] 子级的新 security guard。

@racket[file-guard] 过程必须接受三个参数：

@itemize[

  @item{触发访问检查的 primitive procedure 符号，
        对于引发异常拒绝访问很有用。}

  @item{一个 path（参见 @secref["pathutils"]）或用于无路径查询的 @racket[#f]，
        例如 @racket[(current-directory)]、@racket[(filesystem-root-list)]
        和 @racket[(find-system-path _symbol)]。提供给 @racket[file-guard] 的 path
        在检查访问前不会展开或进行其他规范化；
        它可能是相对路径。}

  @item{一个列表，包含以下符号中的一个或多个：

    @itemize[

    @item{@indexed-racket['read] --- 读取文件或目录}

    @item{@indexed-racket['write] --- 修改或创建文件或目录}

    @item{@indexed-racket['execute] --- 执行文件}

    @item{@indexed-racket['delete] --- 删除文件或目录}

    @item{@indexed-racket['exists] --- 确定文件或目录是否存在，
             或路径字符串是否格式正确}

    ]

 @racket['exists] 符号在 @racket[file-guard] 的最后一个参数中永远不会与其他符号组合，
 但任何其他组合都是可能的。当 @racket[file-guard] 的第二个参数是 @racket[#f] 时，
 最后一个参数始终只包含 @racket['exists]。}

]

@racket[network-guard] 过程必须接受四个参数：

@itemize[

 @item{触发访问检查的 primitive operation 符号，
 对于引发异常拒绝访问很有用。}

 @item{表示客户端连接的目标主机名或监听服务器的接受主机名的不可变字符串；
 对于监听服务器或接受主机所有地址连接的 UDP socket 为 @racket[#f]；
 对于未绑定的 UDP socket 为 @racket[#f]。}

 @item{一个精确整数（在 @racket[1] 到 @racket[65535] 之间，含），
 表示端口号，或对于未绑定的 UDP socket 为 @racket[#f]。
 对于客户端连接，端口号是服务器上的目标端口。
 对于监听服务器，端口号是本地端口号。}

 @item{一个符号，是 @indexed-racket['client] 或 @indexed-racket['server]，
 指示检查是针对客户端连接的创建还是监听服务器的创建。
 打开未绑定的 UDP socket 被标识为 @racket['client] 连接；
 显式绑定 socket 被标识为 @racket['server] 操作。}

]

@racket[link-guard] 参数可以是 @racket[#f] 或者是三参数过程：

@itemize[

  @item{触发访问检查的 primitive procedure 符号，
        对于引发异常拒绝访问很有用。}

  @item{一个完整 path（参见 @secref["pathutils"]），表示要创建为 link 的文件。}

  @item{一个 path，表示 link 的内容，它可能是相对于第二个参数 path 的；
        此 path 在检查访问前不会展开或进行其他规范化。}

]

如果 @racket[link-guard] 是 @racket[#f]，则使用始终引发 @racket[exn:fail] 的默认过程。

@racket[file-guard]、@racket[network-guard] 或 @racket[link-guard] 的返回值被忽略。
要拒绝访问，过程必须引发异常或以其他方式从原始调用的上下文中逃逸。
如果过程返回，则对同一输入调用父级的相应过程，沿 security guard 链向上传播。

@racket[file-guard]、@racket[network-guard] 和 @racket[link-guard] 过程
在调用经过访问检查的 primitive 的线程中调用。Break 可能被启用也可能未被启用
（参见 @secref["breakhandler"]）。完全延续跳跃被阻止进入或退出 @racket[file-guard]
或 @racket[network-guard] 的调用（参见 @secref["prompt-model"]）。}


@defparam[current-security-guard guard security-guard?]{

确定控制对文件系统和网络访问的当前 security guard 的 @tech{parameter}。}
