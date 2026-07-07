#lang scribble/doc
@(require "mz.rkt" racket/file)

@(begin
  ;; ignore expressions at the top-level so that they don't print #<void>
  (define-syntax ignore
    (syntax-rules ()
      [(_ expr) (define x expr)]))

  ;; hacky?
  (define file-eval
    (lambda ()
      (let ([the-eval (make-base-eval)])
        (the-eval '(require (for-syntax racket/base)
                            racket/file))
        (the-eval '(define some-file (make-temporary-file)))
        (the-eval '(define some-other-file (make-temporary-file)))
        the-eval)))

  (define-syntax file-examples
    (syntax-rules ()
      [(_ expr ...)
       (let [(my-eval (file-eval))]
         (define (clean)
           (my-eval '(for [(i (list some-file some-other-file))]
                          (when (file-exists? i)
                            (delete-file i)))))
         (clean)
         (begin0
           (examples #:eval my-eval
                     expr ...)
           (clean)))]))

  "")

@(define default-permissions @racketvalfont{#o666})

@title[#:tag "file-ports"]{File Ports}

由 @racket[open-input-file]、@racket[open-output-file]、@racket[subprocess] 及相关函数创建的 port 是 @deftech{file-stream port}。@exec{racket} 中的初始输入、输出和错误端口也都是 file-stream port。@racket[file-stream-port?] 谓词用于识别 file-stream port。

当创建输入或输出的 file-stream port 时，它会被交由当前 custodian 管理（参见 @secref["custodians"]）。对于 output port，还会向 @tech{current plumber} 注册一个 @tech{flush callback} 以刷新该 port。

@defproc[(open-input-file [path path-string?]
                          [#:mode mode-flag (or/c 'binary 'text) 'binary]
                          [#:for-module? for-module? any/c #f])
         input-port?]{

打开 @racket[path] 指定的文件用于输入。@racket[mode-flag] 参数指定文件字节在输入时的转换方式：

@itemize[

 @item{@indexed-racket['binary] --- 字节按从文件读取时的原样返回。}

 @item{@indexed-racket['text] --- 文件中读取的 return 和 linefeed 字节（10 和 13）由 port 按平台特定方式过滤：

  @itemize[

  @item{@|AllUnix|: 不进行过滤。}

  @item{Windows: 文件中的 return-linefeed 组合由 port 作为单个 linefeed 返回；未后跟 linefeed 的 return 字节或未前跟 return 的 linefeed 不过滤。}
  ]}
]

在 Windows 上，@racket['text] 模式仅适用于常规文件；尝试将 @racket['text] 用于其他类型的文件会引发 @racket[exn:fail:filesystem] 异常。

否则，@racket[path] 指定的文件不必是常规文件。它可能是通过文件系统连接的设备，例如 Windows 上的 @filepath{aux} 或 Unix 上的 @filepath{/dev/null}。所有情况下，port 默认都是带缓冲的。

@racket[open-input-file] 产生的 port 应显式关闭，无论是通过 @racket[close-input-port] 还是间接通过 @racket[custodian-shutdown-all]，以释放 OS 级别的 file handle。即使 input port 可供垃圾回收，它也不会自动关闭（参见 @secref["gc-model"]）；可以将 @tech{will} 与 input port 关联以更自动地关闭它（参见 @secref["willexecutor"]）。

用作已打开端口名称的 @tech{path} 值是 @racket[path] 的 @tech{cleanse}d 版本。

在支持 @tt{O_CLOEXEC} 的 Unix 和 MacOS 变体上，文件以 @tt{O_CLOEXEC} 标志打开，使得底层 file descriptor 不会与 @racket[subprocess] 创建的子进程共享。在 Windows 上，文件作为非继承 handle 打开。

如果因文件系统错误导致文件打开失败，则引发 @exnraise[exn:fail:filesystem:errno]——前提为：@racket[for-module?] 是 @racket[#f]，或 @racket[current-module-path-for-load] 具有非 @racket[#f] 的值，或该文件系统错误不被识别为文件未找到错误。否则，当 @racket[for-module?] 为真，@racket[current-module-path-for-load] 具有非 @racket[#f] 的值，且文件系统错误被识别为文件未找到错误时，引发的异常是 @racket[exn:fail:syntax:missing-module]（当 @racket[current-module-path-for-load] 的值是 @tech{syntax object} 时）或 @racket[exn:fail:filesystem:missing-module]（其它情况）。

@history[#:changed "6.0.1.6" @elem{Added @racket[#:for-module?].}
         #:changed "8.11.1.6" @elem{Changed to use @tt{O_CLOEXEC}
                                    where supported by the operating system.}]

@file-examples[
;; put some text in a file
(with-output-to-file some-file
  (lambda () (printf "hello world")))
(define in (open-input-file some-file))
(read-string 11 in)
(close-input-port in)
]}

@defproc[(open-output-file [path path-string?]
                           [#:mode mode-flag (or/c 'binary 'text) 'binary]
                           [#:exists exists-flag (or/c 'error 'append 'update 'can-update
                                                       'replace 'truncate 
                                                       'must-truncate 'truncate/replace) 'error]
                           [#:permissions permissions (integer-in 0 65535) @#,default-permissions]
                           [#:replace-permissions? replace-permissions? any/c #f])
          output-port?]{

打开 @racket[path] 指定的文件用于输出。@racket[mode-flag] 参数指定写入 port 的字节在写入文件时的转换方式：

@itemize[

 @item{@racket['binary] --- 字节按写入 port 时的原样写入文件。}

 @item{@racket['text] --- 在 Windows 上，写入 port 的 linefeed 字节（10）被转换为文件中的 return-linefeed 组合；return 不进行过滤。}

]

在 Windows 上，@racket['text] 模式仅适用于常规文件；尝试将 @racket['text] 用于其他类型的文件会引发 @racket[exn:fail:filesystem] 异常。

@racket[exists-flag] 参数指定如何处理/要求已存在的文件：

@itemize[

 @item{@indexed-racket['error] --- 如果文件存在，则引发 @racket[exn:fail:filesystem]。}

 @item{@indexed-racket['replace] --- 如果旧文件存在，则删除它并写入新文件。}

 @item{@indexed-racket['truncate] --- 如果文件存在，则删除所有旧数据。}

 @item{@indexed-racket['must-truncate] --- 删除现有文件中的所有旧数据；如果文件不存在，则引发 @exnraise[exn:fail:filesystem]。}

 @item{@indexed-racket['truncate/replace] --- 尝试 @racket['truncate]；如果失败（可能由于文件权限），则尝试 @racket['replace]。}

 @item{@indexed-racket['update] --- 打开现有文件而不截断它；如果文件不存在，则引发 @exnraise[exn:fail:filesystem]。使用 @racket[file-position] 改变当前读/写位置。}

 @item{@indexed-racket['can-update] --- 打开现有文件而不截断它，或者如果文件不存在则创建它。}

 @item{@indexed-racket['append] --- 追加到文件末尾，无论文件是否已存在；在 Windows 上，@racket['append] 等同于 @racket['update]，只是文件不必存在，且文件位置在打开后立即设置为文件末尾。}

]

当创建 @racket[path] 指定的文件时，@racket[permissions] 指定所创建文件的权限，其中权限的整数表示与 @racket[file-or-directory-permissions] 中的处理方式相同。在 Unix 和 Mac OS 上，这些权限位与进程的 umask 组合。在 Windows 上，@racket[permissions] 唯一相关的属性是是否设置了 @racketvalfont{#o2} 位用于写权限。注意，可以使用 @racket[open-output-file] 创建只读文件，此时写操作仅禁止后续尝试打开该文件。如果 @racket[replace-permissions?] 为真值，则无论打开的文件是否新创建，@racket[permissions] 的值都会应用于打开的文件，并且在 Unix 和 Mac OS 上独立于进程的 umask 应用。

@racket[path] 指定的文件不必是常规文件。它可能是通过文件系统连接的设备，例如 Windows 上的 @filepath{aux} 或 Unix 上的 @filepath{/dev/null}。output port 默认是块缓冲的，除非文件对应于终端，此时默认是行缓冲的。在 Unix 和 Mac OS 上，如果文件是 fifo，则 port 将阻塞写入直到 fifo 的读取者可用；另请参见 @racket[port-waiting-peer?]。

@racket[open-output-file] 产生的 port 应显式关闭，无论是通过 @racket[close-output-port] 还是间接通过 @racket[custodian-shutdown-all]，以释放 OS 级别的 file handle。即使 output port 可供垃圾回收，它也不会自动关闭（参见 @secref["gc-model"]）；可以将 @tech{will} 与 output port 关联以更自动地关闭它（参见 @secref["willexecutor"]）。

用作已打开端口名称的 @tech{path} 值是 @racket[path] 的 @tech{cleanse}d 版本。

在支持 @tt{O_CLOEXEC} 的 Unix 和 MacOS 变体上，文件以 @tt{O_CLOEXEC} 标志打开，使得底层 file descriptor 不会与 @racket[subprocess] 创建的子进程共享。在 Windows 上，文件作为非继承 handle 打开。

如果因底层文件系统错误导致文件打开失败，则引发 @exnraise[exn:fail:filesystem:errno]。

@file-examples[
(define out (open-output-file some-file))
(write "hello world" out)
(close-output-port out)
]

@history[#:changed "6.9.0.6" @elem{On Unix and Mac OS, make @racket['truncate/replace]
                                   replace on a permission error. On Windows, make
                                   @racket['replace] always replace instead truncating
                                   like @racket['truncate/replace].}
         #:changed "7.4.0.5" @elem{Changed handling of a fifo on Unix and Mac OS to
                                   make the port block for output until the fifo has a
                                   reader.}
         #:changed "8.1.0.3" @elem{Added the @racket[#:permissions] argument.}
         #:changed "8.7.0.10" @elem{Added the @racket[#:replace-permissions?] argument.}
         #:changed "8.11.1.6" @elem{Changed to use @tt{O_CLOEXEC}
                                    where supported by the operating system.}]}

@defproc[(open-input-output-file [path path-string?]
                           [#:mode mode-flag (or/c 'binary 'text) 'binary]
                           [#:exists exists-flag (or/c 'error 'append 'update 'can-update
                                                       'replace 'truncate 
                                                       'must-truncate 'truncate/replace) 'error]
                           [#:permissions permissions (integer-in 0 65535) @#,default-permissions]
                           [#:replace-permissions? replace-permissions? any/c #f])
          (values input-port? output-port?)]{

类似于 @racket[open-output-file]，但产生两个值：一个 input port 和一个 output port。两个 port 共享底层 file descriptor。此过程旨在用于只能由一个进程打开的特殊设备，例如 Windows 上的 @filepath{COM1}。对于常规文件，共享 file descriptor 可能会造成混乱。例如，使用一个 port 不会自动刷新另一个 port 的缓冲区，并且在一个 port 中读取或写入会移动另一个 port 的文件位置（如果有）。对于常规文件，请使用单独的 @racket[open-input-file] 和 @racket[open-output-file] 调用来避免混淆。

@history[#:changed "8.1.0.3" @elem{Added the @racket[#:permissions] argument.}
         #:changed "8.7.0.10" @elem{Added the @racket[#:replace-permissions?] argument.}]}

@defproc[(call-with-input-file [path path-string?]
                               [proc (input-port? . -> . any)]
                               [#:mode mode-flag (or/c 'binary 'text) 'binary])
         any]{
使用 @racket[path] 和 @racket[mode-flag] 参数调用 @racket[open-input-file]，并将产生的 port 传递给 @racket[proc]。@racket[proc] 的结果即为 @racket[call-with-input-file] 调用的结果，但新打开的 port 会在 @racket[proc] 返回时关闭。

@file-examples[
(with-output-to-file some-file
  (lambda () (printf "text in a file")))
(call-with-input-file some-file
  (lambda (in) (read-string 14 in)))
]}

@defproc[(call-with-output-file [path path-string?]
                                [proc (output-port? . -> . any)]
                                [#:mode mode-flag (or/c 'binary 'text) 'binary]
                                [#:exists exists-flag (or/c 'error 'append 'update 'can-update
                                                            'replace 'truncate 
                                                            'must-truncate 'truncate/replace) 'error]
                                [#:permissions permissions (integer-in 0 65535) @#,default-permissions]
                                [#:replace-permissions? replace-permissions? any/c #f])
         any]{
类似于 @racket[call-with-input-file]，但将 @racket[path]、@racket[mode-flag]、@racket[exists-flag]、@racket[permissions] 和 @racket[replace-permissions?] 传递给 @racket[open-output-file]。

@file-examples[
(call-with-output-file some-file
  (lambda (out)
    (write 'hello out)))
(call-with-input-file some-file
  (lambda (in)
    (read-string 5 in)))
]

@history[#:changed "8.1.0.3" @elem{Added the @racket[#:permissions] argument.}
         #:changed "8.7.0.10" @elem{Added the @racket[#:replace-permissions?] argument.}]}

@defproc[(call-with-input-file* [path path-string?]
                                [proc (input-port? . -> . any)]
                                [#:mode mode-flag (or/c 'binary 'text) 'binary])
         any]{
类似于 @racket[call-with-input-file]，但新打开的 port 在控制逃离 @racket[call-with-input-file*] 调用的动态范围时关闭，无论是通过 @racket[proc] 的返回、continuation 应用还是基于 prompt 的中止。}

@defproc[(call-with-output-file* [path path-string?]
                                 [proc (output-port? . -> . any)]
                                 [#:mode mode-flag (or/c 'binary 'text) 'binary]
                                 [#:exists exists-flag (or/c 'error 'append 'update 'can-update
                                                             'replace 'truncate
                                                             'must-truncate 'truncate/replace) 'error]
                                 [#:permissions permissions (integer-in 0 65535) @#,default-permissions]
                                 [#:replace-permissions? replace-permissions? any/c #f])
         any]{
类似于 @racket[call-with-output-file]，但新打开的 port 在控制逃离 @racket[call-with-output-file*] 调用的动态范围时关闭，无论是通过 @racket[proc] 的返回、continuation 应用还是基于 prompt 的中止。

@history[#:changed "8.1.0.3" @elem{Added the @racket[#:permissions] argument.}
         #:changed "8.7.0.10" @elem{Added the @racket[#:replace-permissions?] argument.}]}

@defproc[(with-input-from-file [path path-string?]
                               [thunk (-> any)]
                               [#:mode mode-flag (or/c 'binary 'text) 'binary])
         any]{
类似于 @racket[call-with-input-file*]，但不是将新打开的 port 传递给给定的过程参数，而是将该 port 作为当前 input port 安装（参见 @racket[current-input-port]），使用 @racket[parameterize] 包裹对 @racket[thunk] 的调用。

@file-examples[
(with-output-to-file some-file
  (lambda () (printf "hello")))
(with-input-from-file some-file
  (lambda () (read-string 5)))
]}

@defproc[(with-output-to-file [path path-string?]
                              [thunk (-> any)]
                              [#:mode mode-flag (or/c 'binary 'text) 'binary]
                              [#:exists exists-flag (or/c 'error 'append 'update 'can-update
                                                          'replace 'truncate 
                                                          'must-truncate 'truncate/replace) 'error]
                              [#:permissions permissions (integer-in 0 65535) @#,default-permissions]
                              [#:replace-permissions? replace-permissions? any/c #f])
         any]{
类似于 @racket[call-with-output-file*]，但不是将新打开的 port 传递给给定的过程参数，而是将该 port 作为当前 output port 安装（参见 @racket[current-output-port]），使用 @racket[parameterize] 包裹对 @racket[thunk] 的调用。

@file-examples[
(with-output-to-file some-file
  (lambda () (printf "hello")))
(with-input-from-file some-file
  (lambda () (read-string 5)))
]

@history[#:changed "8.1.0.3" @elem{Added the @racket[#:permissions] argument.}
         #:changed "8.7.0.10" @elem{Added the @racket[#:replace-permissions?] argument.}]}


@defproc[(port-try-file-lock? [port file-stream-port?]
                              [mode (or/c 'shared 'exclusive)])
         boolean?]{

尝试使用当前平台的文件锁定设施获取文件上的锁。多个进程可以获取文件上的 @racket['shared] 锁，但最多只有一个进程可以持有 @racket['exclusive] 锁，且 @racket['shared] 和 @racket['exclusive] 锁互斥。当 @racket[mode] 为 @racket['shared] 时，@racket[port] 必须是 input port；当 @racket[mode] 为 @racket['exclusive] 时，@racket[port] 必须是 output port。

如果获取了请求的锁，结果为 @racket[#t]，否则为 @racket[#f]。获取锁后，锁会一直保持，直到通过 @racket[port-file-unlock] 释放或 port 关闭（可能因为进程终止）。

取决于平台，锁可能仅是建议性的（即锁仅影响进程获取锁的能力），或者可能对应于阻止对锁定文件进行读写的强制锁。具体而言，Windows 上的锁是强制性的，其他平台上是建议性的。对单个 port 的 @racket['shared] 锁的多次尝试可以成功；在 Unix 和 Mac OS 上，一次 @racket[port-file-unlock] 释放锁，而在 Windows 上，每次成功的 @racket[port-try-file-lock?] 都需要一个 @racket[port-file-unlock]。在 Unix 和 Mac OS 上，对 @racket['exclusive] 锁的多次尝试可以成功，且一次 @racket[port-file-unlock] 释放锁，而在 Windows 上，如果 port 已持有锁，则对 @racket['exclusive] 锁的尝试失败。

从 @racket[open-input-output-file] 为 input port 获取的锁可以通过相应 output port 上的 @racket[port-file-unlock] 释放，反之亦然。如果 @racket[open-input-output-file] 的 output port 持有 @racket['exclusive] 锁，相应的 input port 仍然可以获取 @racket['shared] 锁，甚至可以多次；在 Windows 上，每次成功的锁尝试都需要一个 @racket[port-file-unlock]，而在 Unix 和 Mac OS 上，一次 @racket[port-file-unlock] 平衡锁尝试。在 Unix 和 Mac OS 上，input port 上的 @racket['shared] 锁可以通过相应的 output port 升级为 @racket['exclusive] 锁，此时一次 @racket[port-file-unlock]（在任一 port 上）释放锁，而在 Windows 上不允许此类升级。

锁定通常仅对 file port 支持，尝试使用其他类型的 file-stream port 获取锁会引发 @racket[exn:fail:filesystem] 异常。}


@defproc[(port-file-unlock [port file-stream-port?])
         void?]{

释放当前进程对 @racket[port] 文件持有的锁。}


@defproc[(port-file-identity [port file-stream-port?]) exact-positive-integer?]{

@index['("inode")]{返回} 一个表示 @racket[port] 读取或写入的设备和文件身份的数字。如果两个端口开放时间重叠，当且仅当两个端口访问相同的设备和文件时，@racket[port-file-identity] 的结果相同。对于开放时间不重叠的端口，无法提供端口身份的保证（即使端口实际访问同一文件）——除非可以通过与其他端口的关系推断。如果 @racket[port] 已关闭，则引发 @exnraise[exn:fail]。在 Windows 95、98 和 Me 上，如果 @racket[port] 连接的是 pipe 而非文件，则引发 @exnraise[exn:fail:filesystem]。

@file-examples[
(define file1 (open-output-file some-file))
(define file2 (open-output-file some-other-file))
(port-file-identity file1)
(port-file-identity file2)
(close-output-port file1)
(close-output-port file2)
]}

@defproc[(port-file-stat [port file-stream-port?]) (and/c (hash/c symbol? any/c) hash-eq?)]{

类似于 @racket[file-or-directory-stat]，但返回由 port 表示的打开文件的信息，而不是使用文件的路径。

@history[#:added "8.15.0.6"]}
