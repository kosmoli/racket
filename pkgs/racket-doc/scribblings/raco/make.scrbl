#lang scribble/doc
@(require scribble/manual scribble/bnf scribble/eval "common.rkt"
          (for-label racket/base
                     racket/include
                     racket/contract
                     racket/promise
                     racket/file
                     racket/place
                     compiler/cm
                     compiler/cm-accomplice
                     setup/parallel-build
                     setup/cross-system
                     compiler/compilation-path
                     compiler/compile-file
                     syntax/modread
                     (only-in racket/match match)
                     (only-in racket/unit define-signature)
                     (only-in compiler/compiler compile-zos)))


@(define cm-eval (make-base-eval))
@(interaction-eval #:eval cm-eval (require compiler/cm))
@title[#:tag "make" #:style 'toc]{@exec{raco make}：将源代码编译为字节码}

@exec{raco make} 命令接受要编译为字节码格式的 Racket 模块文件名。
仅当源 Racket 文件比字节码文件新且具有不同的 SHA-1 哈希，
或者任何导入的模块被重新编译或其编译形式加依赖项具有不同的 SHA-1 哈希时，
模块才会被重新编译。

@local-table-of-contents[]

@; ------------------------------------------------------------------------
@section{运行 @exec{raco make}}

@exec{raco make} 命令接受几个标志：

@itemlist[

 @item{@Flag{l} @nonterm{path} --- 将 @nonterm{path} 作为基于集合的模块路径编译，
       类似于 @racket[require]。}

@item{@Flag{j} @nonterm{n} --- 并行编译参数模块，
       使用最多 @nonterm{n} 个并行任务。}

 @item{@DFlag{disable-inline} --- 编译时禁用函数内联
      （但不重新编译已是最新的文件）。此标志通常用于在反编译之前
      简化生成的代码，它对应于将
      @racket[compile-context-preservation-enabled] 设置为 @racket[#t]。}

 @item{@DFlag{disable-constant} --- 禁用将模块内定义推断为常量
      （但不重新编译已是最新的文件）。非常量定义关联的值
      永远不会被内联或常量传播，无论是在其自己的模块内
      还是在导入模块中。此标志对应于将
      @racket[compile-enforce-module-constants] 设置为 @racket[#f]。}

 @item{@DFlag{no-deps} --- 编译非模块文件（即通过 @racket[load]
       而非 @racket[require] 运行的文件）。参见
       @secref["zo"] 了解更多信息。}

 @item{@Flag{p} @nonterm{file} 或 @DFlag{prefix} @nonterm{file} ---
       与 @DFlag{no-deps} 一起使用；参见 @secref["zo"]。}

 @item{@Flag{no-prim} --- 与 @DFlag{no-deps} 一起使用；参见 @secref["zo"]。}

 @item{@Flag{v} --- 详细模式，显示哪些文件被编译。}

 @item{@DFlag{vv} --- 非常详细模式，隐含 @Flag{v} 并
       显示每个被检查的依赖项。}

]

@; ----------------------------------------------------------------------

@section{字节码文件}

文件 @filepath{@nonterm{name}.@nonterm{ext}} 被编译为字节码，
保存为相对于该文件的
@filepath{compiled/@nonterm{name}_@nonterm{ext}.zo}。因此，
当 @filepath{@nonterm{name}.@nonterm{ext}} 作为模块被 require 时，
字节码文件通常会自动使用，因为底层的
@racket[load/use-compiled] 操作会检测到这样的字节码文件。

例如，在包含以下文件的目录中：

@itemize[

 @item{@filepath{a.rkt}:

@racketmod[
racket
(require "b.rkt" "c.rkt")
(+ b c)
]}

 @item{@filepath{b.rkt}:

@racketmod[
racket
(provide b)
(define b 1)
]}

 @item{@filepath{c.rkt}:

@racketmod[
racket
(provide c)
(define c 1)
]}]

then

@commandline{raco make a.rkt}

触发创建 @filepath{compiled/a_rkt.zo}、
@filepath{compiled/b_rkt.zo} 和 @filepath{compiled/c_rkt.zo}。
随后的

@commandline{racket a.rkt}

从生成的 @filepath{.zo} 文件加载字节码，仅关注
@filepath{.rkt} 源文件以确认每个 @filepath{.zo} 文件
具有较晚的时间戳（除非 @envvar{PLT_COMPILED_FILE_CHECK}
环境变量设置为 @litchar{exists}，在这种情况下
使用编译文件而不进行时间戳检查）。

相比之下，

@commandline{raco make b.rkt c.rkt}

只会创建 @filepath{compiled/b_rkt.zo} 和
@filepath{compiled/c_rkt.zo}，因为 @filepath{b.rkt} 和
@filepath{c.rkt} 都没有导入 @filepath{a.rkt}。

@; ----------------------------------------------------------------------

@section[#:tag "依赖文件"]{依赖文件}

除了字节码文件之外，@exec{raco make} 还创建一个文件
@filepath{compiled/@nonterm{name}_@nonterm{ext}.dep}，记录
已编译模块对其他模块文件的依赖关系以及源文件的 SHA-1 哈希。
使用此依赖信息，通过 @exec{raco make} 的重新编译请求可以同时
查询源文件的时间戳/哈希以及导入模块字节码的
时间戳/哈希。此外，导入的模块也会根据需要自行编译，
包括更新导入模块的字节码和依赖文件，传递性地。

继续上一节的 @exec{raco make a.rkt} 示例，
@exec{raco make} 命令在创建 @filepath{.zo} 文件的同时
创建 @filepath{compiled/a_rkt.dep}、
@filepath{compiled/b_rkt.dep} 和 @filepath{compiled/c_rkt.dep}。
@filepath{compiled/a_rkt.dep} 文件记录了 @filepath{a.rkt}
对 @filepath{b.rkt}、@filepath{c.rkt} 和
@racketmodname[racket] 库的依赖。如果 @filepath{b.rkt} 文件
被修改（其 SHA-1 哈希发生变化），则运行

@commandline{raco make a.rkt}

将重新构建 @filepath{compiled/a_rkt.zo} 和
@filepath{compiled/b_rkt.zo}。

对于库集合中的模块文件，@exec{raco setup}
使用与 @exec{raco make} 相同的 @filepath{.zo} 和 @filepath{.dep}
约定和文件，因此这两个工具可以一起使用。

只要 @envvar{PLT_COMPILED_FILE_CHECK} 环境变量
未设置或设置为 @litchar{modify}，@exec{raco make}
就会更新已编译字节码文件的时间戳（如果它比源文件旧），
即使文件不需要重新编译。

@; ----------------------------------------------------------------------

@section{制作字节码的 API}

@defmodule[compiler/cm]{@racketmodname[compiler/cm] 模块实现了
@exec{raco make} 和 @exec{raco setup} 使用的编译和依赖管理。}

@defproc[(make-compilation-manager-load/use-compiled-handler 
          [delete-zos-when-rkt-file-does-not-exist? any/c #f]
          [#:security-guard security-guard (or/c security-guard? #f) #f])
         (path? (or/c symbol? #f) . -> . any)]{

返回一个适合作为 @racket[current-load/use-compiled] 参数值的过程。
返回的过程将其参数传递给调用
@racket[make-compilation-manager-load/use-compiled-handler] 时安装的
@racket[current-load/use-compiled] 过程，
但首先它会自动将源文件编译为 @filepath{.zo} 文件，如果满足以下条件：

@itemize[

 @item{文件预期包含一个模块（即处理程序的第二个参数是符号）；}

 @item{the value of each of @racket[(current-eval)],
 @racket[(current-load)], and @racket[(namespace-module-registry
 (current-namespace))] is the same as when
 @racket[make-compilation-manager-load/use-compiled-handler] was
 called;}

 @item{the value of @racket[use-compiled-file-paths] contains the
 first path that was present when
 @racket[make-compilation-manager-load/use-compiled-handler] was
 called;}

 @item{the value of @racket[current-load/use-compiled] is the result
 of this procedure; and}

 @item{one of the following holds:

 @itemize[

  @item{the source file is newer than the @filepath{.zo} file in the
        first sub-directory listed in @racket[use-compiled-file-paths]
        (at the time that
        @racket[make-compilation-manager-load/use-compiled-handler]
        was called), and either no @filepath{.dep} file exists or it
        records a source-file SHA-1 hash that differs from the current
        version and source-file SHA-1 hash;}

  @item{no @filepath{.dep} file exists next to the @filepath{.zo}
        file;}

  @item{the version recorded in the @filepath{.dep} file does not
        match the result of @racket[(version)];}

  @item{the target machine recorded in the @filepath{.dep} file does
        not match the result of @racket[(current-compile-target-machine)];}

  @item{the source hash recorded in the @filepath{.dep} file does not
        match the current source hash;}

  @item{one of the files listed in the @filepath{.dep} file has a
        @filepath{.zo} timestamp newer than the target @filepath{.zo}
        and @racket[use-compiled-file-check] is set to
        @racket['modify-seconds];}
        
  @item{the combined hashes of the dependencies recorded in the
        @filepath{.dep} file does not match the combined hash recorded
        in the @filepath{.dep} file.}

  ]}

]

如果 SHA-1 哈希覆盖了基于时间戳的重新编译决定，
则目标 @filepath{.zo} 文件的时间戳会更新为当前时间，
除非 @racket[use-compiled-file-check] 参数未设置为
@racket['modify-seconds]。

处理程序过程编译 @filepath{.zo} 文件后，会创建
相应的 @filepath{.dep} 文件，列出当前版本
以及编译文件中模块直接 @racket[require] 的每个文件的标识。
编译期间可以通过 @racketmodname[compiler/cm-accomplice] 安装额外的依赖项。 @filepath{.dep} 文件还记录模块源的 SHA-1 哈希，
并记录所有依赖项（包括递归依赖项）的组合 SHA-1 哈希。
如果字节码文件是通过重新编译以前作为机器无关编译的字节码文件生成的，
则 @filepath{.dep} 文件还记录机器无关形式的 SHA-1 哈希，
因为重新编译的模块行为应该完全相同。

@racket[(cross-installation?)] 或
@racket[(current-multi-compile-any)] 为 @racket[#t]、
@racket[(current-compile-target-machine)] 为 @racket[#f]
以及 @racket[(current-compiled-file-roots)] 有两个或更多元素的
特殊组合会触发特殊编译模式。特定于运行中 Racket 的字节码
写入由 @racket[(current-compiled-file-roots)] 第一个元素确定的目录。
特定于 @racket[(cross-installation?)] 的交叉编译目标
或（如果 @racket[(current-multi-compile-any)]）机器无关格式的字节码
写入由 @racket[(current-compiled-file-roots)] 第二个元素确定的目录。 通过配置 @racket[(current-compiled-file-roots)]，使第一个元素
在构建树之外而第二个元素在构建树之内，交叉编译可以
创建一个适合目标机器的构建树，同时构建和加载
当前机器上可用的字节码（用于宏展开等）。
此模式对于仅从源代码和机器无关字节码开始的构建目录
可以正常工作。

处理程序在检查 @filepath{.dep} 文件时缓存时间戳，
并且缓存在对同一处理程序的调用之间保持。
缓存不用于比较直接源文件与其 @filepath{.zo} 文件，
这意味着缓存行为与默认模块名称解析器的缓存一致
（参见 @racket[current-module-name-resolver]）。

如果在调用
@racket[make-compilation-manager-load/use-compiled-handler] 时
@racket[use-compiled-file-paths] 包含空列表，
则会引发 @racket[exn:fail:contract] 异常。

如果 @racket[delete-zos-when-rkt-file-does-not-exist?] 参数为真值，
则返回的处理程序将在没有相应的原始源文件时删除 @filepath{.zo} 文件。

如果提供了 @racket[security-guard] 参数，则在创建
@filepath{.zo} 文件、@filepath{.dep} 文件和 @filepath{compiled/}
目录时使用它，在调整现有文件的时间戳时也使用它。
如果为 @racket[#f]，则使用文件创建时
@racket[current-security-guard] 中的安全守卫
（而非调用 @racket[make-compilation-manager-load/use-compiled-handler]
时的安全守卫）。

模块编译的续延用 @racket[managed-compiled-context-key]
和模块的源路径标记。

@emph{不要} 在当前命名空间包含可能需要重新编译的
已加载模块版本时安装
@racket[make-compilation-manager-load/use-compiled-handler] 的结果---
除非已加载模块永远不会被尚未加载的模块引用。
对已加载模块的引用可能产生具有不一致时间戳的编译文件和/或
具有不正确信息的 @filepath{.dep} 文件。

处理程序以 @racket['info] 级别向主题 @racket['compiler/cm] 记录消息。
这些消息是 @racket[compile-event] 预构结构的实例：

@racketblock[
  (struct compile-event (timestamp path type) #:prefab)
]
The @racket[timestamp] field is the time at which the event occurred in
milliseconds since the epoch.  The @racket[path] field is the path of a file
being compiled for which the event is about. The @racket[type] field is a symbol
which describes the action the event corresponds to. The currently logged values
are @racket['locking], @racket['start-compile], @racket['finish-compile], and
@racket['already-done].

@history[#:changed "6.1.1.8" @elem{Added identification of the compilation
                                    context via @racket[managed-compiled-context-key].}
         #:changed "6.6.0.3" @elem{added check on a source's SHA1 hash to complement the
                                   timestamp check, where the latter can be disabled
                                   via @racket[use-compile-file-check].}]}


@defproc[(managed-compile-zo [file path-string?]
                             [read-src-syntax (any/c input-port? . -> . syntax?) read-syntax]
                             [#:security-guard security-guard (or/c security-guard? #f) #f]) 
         void?]{

将给定的模块源文件编译为 @filepath{.zo}，在文件编译期间安装
一个 compilation-manager 处理程序（以便所需的模块也被编译），
并创建一个 @filepath{.dep} 文件来记录用于编译源的直接文件的时间戳
（即在源中 @racket[require] 的文件）。

编译通过将模块加载到当前命名空间来触发，
因此如果 @racket[file] 的依赖模块已经加载到当前命名空间中，
则该模块不一定会被（重新）编译。用于触发编译的处理程序
由 @racket[make-compilation-manager-load/use-compiled-handler] 创建，
因此那里的所有规则和约束都适用。

如果 @racket[file] 从源代码编译，则
@racket[read-src-syntax] 以与 @racket[read-syntax] 相同的方式
用于读取源模块。然而，正常的 @racket[read-syntax]
用于任何依赖文件。

如果 @racket[security-guard] 不是 @racket[#f]，
则在创建 @filepath{compiled/} 目录、
@filepath{.dep} 和 @filepath{.zo} 文件时使用提供的安全守卫，
在调整现有文件的时间戳时也使用它。如果为 @racket[#f]，
则使用文件创建时 @racket[current-security-guard] 中的安全守卫
（而非调用 @racket[managed-compile-zo] 时的安全守卫）。

编译 @racket[file] 时，@racket[error-display-handler] 参数设置为
@racket[(make-compilation-context-error-display-handler
(error-display-handler))]，以便未捕获异常的错误
将报告编译上下文。

@history[#:changed "6.1.1.8" @elem{Added @racket[error-display-handler]
                                   configuration.}]}


@defthing[managed-compiled-context-key any/c]{

由 @racket[make-compilation-manager-load/use-compiled-handler]
用作模块编译续延的续延标记键。相关联的值是模块源的路径。

@history[#:added "6.1.1.8"]}


@defproc[(make-compilation-context-error-display-handler
          [orig-handlers (string? any/c . -> . void?)])
         (string? any/c . -> . void?)]{

给定一个现有的 @racket[error-display-handler] 值，
产生一个适合用作 @racket[error-display-handler] 值的处理程序。
当处理程序的第二个参数是一个异常，且其续延标记包含
@racket[managed-compiled-context-key] 键时，
生成的处理器显示有关编译上下文的信息。

@history[#:added "6.1.1.8"]}


@defboolparam[trust-existing-zos trust?]{

A parameter that is intended for use by @exec{raco setup} when
installing with pre-built @filepath{.zo} files. It causes a
compilation-manager @racket[load/use-compiled] handler to ``touch''
out-of-date @filepath{.zo} files instead of re-compiling from source.}


@defproc[(make-caching-managed-compile-zo
          [read-src-syntax (any/c input-port? . -> . syntax?) read-syntax]
          [#:security-guard security-guard (or/c security-guard? #f) #f])
         (path-string? . -> . void?)]{

返回一个行为类似于 @racket[managed-compile-zo] 的过程
（每次都提供相同的 @racket[read-src-syntax]），
但对过程的调用之间保持时间戳信息的缓存。

每次调用 @racket[make-caching-managed-compile-zo] 的结果时，
都会使用 @racket[make-compilation-manager-load/use-compiled-handler]
创建支持编译的处理程序，因此当前命名空间和其他参数值在
那时是相关的，而不是在调用
@racket[make-caching-managed-compile-zo] 时。}


@defparam[manager-compile-notify-handler notify (path? . -> . any)]{

一个参数，是一个接受一个参数的过程，每次编译开始时调用。
过程的参数是文件路径。}


@defparam[manager-trace-handler notify (string? . -> . any)]{

一个参数，是一个接受一个参数的过程，被调用来报告
 compilation-manager 操作，例如检查文件。过程的参数是一个字符串。
 
 参数的默认值将参数连同
 @racket[current-inexact-milliseconds] 一起以 @racket['debug] 级别
 记录到名为 @racket['compiler/cm] 的记录器。
 }

@defparam[manager-skip-file-handler proc (-> path? (or/c (cons/c number? promise?) #f))]{

一个参数，其值对每个加载且需要重新编译的文件调用。
 如果过程返回一个对，则跳过该文件（即不编译）；
 对中的数字用作文件字节码的时间戳，promise 可以被
 @racket[force]d 以获取用作编译文件及其依赖项哈希的字符串。
 如果过程返回 @racket[#f]，则文件照常编译。默认值为
 @racket[(lambda (x) #f)]。}


@defparam[current-path->mode path->mode
          (or/c #f (-> path? (and/c path? relative-path?)))
          #:value #f]{
 Used by @racket[make-compilation-manager-load/use-compiled-handler] and
 @racket[make-caching-managed-compile-zo] to override @racket[use-compiled-file-paths]
 for deciding where to write compiled @filepath{.zo} files. If it is @racket[#f],
 then the first element of @racket[use-compiled-file-paths] is used. If it isn't
 @racket[#f], then it is called with the original source file's location and its
 result is treated the same as if it had been the first element of
 @racket[use-compiled-file-paths].

 请注意，此参数不被 @racket[current-load/use-compiled] 使用。
 因此，如果该参数导致 @filepath{.zo} 文件放在不同的目录中，
 则正确的 @filepath{.zo} 文件仍必须通过
 @racket[use-compiled-file-paths] 传达，一种方法是在加载前
 覆盖 @racket[current-load/use-compiled] 以删除
 会导致选中错误文件的 @filepath{.zo} 文件。

 @history[#:added "6.4.0.14"]
}


@defproc[(file-stamp-in-collection [p path?]) (or/c (cons/c number? promise?) #f)]{
  Calls @racket[file-stamp-in-paths] with @racket[p] and
  @racket[(current-library-collection-paths)].}

@defproc[(file-stamp-in-paths [p path?] [paths (listof path?)]) (or/c (cons/c number? promise?) #f)]{

Returns the file-modification date and @racket[delay]ed hash of
 @racket[p] or its bytecode form (i.e., @filepath{.zo} file), whichever
 exists and is newer, if @racket[p] is an extension of any path in
 @racket[paths] (i.e., exists in the directory, a subdirectory,
 etc.). Otherwise, the result is @racket[#f].

 This function is intended for use with @racket[manager-skip-file-handler].}

@defproc[(get-file-sha1 [p path?]) (or/c string? #f)]{

Computes a SHA-1 hash for the file @racket[p]; the result is
@racket[#f] if @racket[p] cannot be opened.}


@defproc[(get-compiled-file-sha1 [p path?]) (or/c string? #f)]{

Computes a SHA-1 hash for the bytecode file @racket[p], appending any
dependency-describing hash available from a @filepath{.dep} file when
available (i.e., the suffix on @racket[p] is replaced by
@filepath{.dep} to locate dependency information). The result is
@racket[#f] if @racket[p] cannot be opened.}


@defproc[(with-compile-output [p path-string?] [proc ([port input-port?] [tmp-path path?]  . -> . any)]) any]{

A wrapper on @racket[call-with-atomic-output-file] that passes along
any security guard put in place by
@racket[make-compilation-manager-load/use-compiled-handler], etc.}


@defparam[parallel-lock-client proc 
                               (or/c #f
                                     (->i ([_command (or/c 'lock 'unlock)]
                                           [_file bytes?])
                                          [res (_command) (if (eq? _command 'lock)
                                                              boolean?
                                                              void?)]))]{

Creates a parallel compilation lock client, which
is used by the result of @racket[make-compilation-manager-load/use-compiled-handler] to
prevent compilation races between parallel builders.  

When @racket[proc] is @racket[#f] (the default), no checking for parallel
compilation is done (and thus multiple threads or places running compilations
via @racket[make-compilation-manager-load/use-compiled-handler] will potentially
corrupt each other's @filepath{.zo} files).

When @racket[proc] is a function, its first argument is a command
@racket['lock] pr @racket['unlock], which indicates whether the caller
wants to lock or unlock a target @racket[_zo-path], and the second
argument is the target @racket[_zo-path] (expressed as a byte string).

When @racket[proc] returns @racket[#t] for a @racket['lock] command, the current
builder has obtained the lock for @racket[_zo-path].
Once compilation of @racket[_zo-path] is complete, the builder process must
release the lock by calling @racket[proc] @racket['unlock] with the exact same
@racket[_zo-path].

When @racket[proc] returns @racket[#f] for a @racket['lock] command, another
parallel builder obtained the lock first and has already compiled the target.  The
parallel builder should continue without compiling @racket[_zo-path].
(In this case, @racket[make-compilation-manager-load/use-compiled-handler]'s
result will not call @racket[proc] with @racket['unlock].)

@examples[
  #:eval cm-eval
(let* ([lc (parallel-lock-client)]
       [zo-name  #"collects/racket/compiled/draw_rkt.zo"]
       [locked? (and lc (lc 'lock zo-name))]
       [ok-to-compile? (or (not lc) locked?)])
  (dynamic-wind
    (lambda () (void))
    (lambda ()
      (when ok-to-compile?
        (printf "Do compile here ...\n")))
    (lambda ()
      (when locked?
        (lc 'unlock zo-name)))))
]
}

@defproc[(compile-lock->parallel-lock-client [pc place-channel?]
                                             [cust (or/c #f custodian?) #f]
                                             [current-shutdown-evt (-> evt?) (lambda () never-evt)])
         (-> (or/c 'lock 'unlock) bytes? boolean?)]{

  Returns a function that follows the @racket[parallel-lock-client] protocol
  by communicating over @racket[pc], where @racket[pc] must
  be a result of @racket[make-compile-lock].
  
  This communication protocol implementation is not kill-safe when @racket[cust] is @racket[#f].
  Making the protocol kill-safe requires a sufficiently powerful custodian (i.e., one that is not subject to
  termination unless all of the participants in the compilation are also terminated)
  supplied as @racket[cust]. The given custodian is used to create a thread that monitors the threads that are
  perform the compilation. If one of the threads is terminated, the presence of the
  custodian lets another one continue. (The custodian is also used to create
  a thread that manages a thread-safe table.)

  Just checking for thread termination is not always sufficient to
  release a lock, because a thread created with
  @racket[thread/suspend-to-kill] is merely suspending by removing its
  ability to run. The @racket[current-shutdown-evt] argument returns
  an @tech[#:doc reference-doc]{synchronizable event} that the monitor
  thread waits on at the same time as it waits for a thread to
  terminate. If the event becomes ready, then the monitor releases a
  lock the same as if the thread was terminated. For example,
  @racket[current-shutdown-evt] might return a @tech[#:doc
  reference-doc]{custodian box} to detect a custodian shutdown.

@history[#:changed "8.1.0.7" @elem{Added the @racket[current-shutdown-evt] argument.}]}


@defproc[(make-compile-lock) place-channel?]{
  Creates a place-channel that can be used with
  @racket[compile-lock->parallel-lock-client] to avoid concurrent
  compilations of the same Racket source files in multiple places.
}

@defproc[(install-module-hashes! [bstr bytes?]
                                 [start exact-nonnegative-integer? 0]
                                 [end exact-nonnegative-integer? (bytes-length bstr)])
         void?]{

Adjusts the bytecode representation in @racket[bstr] (from bytes
@racket[start] to @racket[end]) to install a hash code, including any
submodules within the region. The existing representation should have
zero bytes in place of each hash string, which is what @racket[write]
produces for a compiled form.

@history[#:added "6.3"]}

@defboolparam[current-multi-compile-any on?]{

A parameter that enables compilation of both current-machine bytecode
and machine-independent bytecode by a handler created with
@racket[make-compilation-manager-load/use-compiled-handler].

@history[#:added "8.1.0.2"]}

@; ----------------------------------------------------------------------

@section[#:tag "api:parallel-build"]{并行构建的 API}

@defmodule[setup/parallel-build]{

@racketmodname[setup/parallel-build] 库提供
@exec{raco setup} 和 @exec{raco make} 的并行编译功能。}

@racket[parallel-compile-files] 和 @racket[parallel-compile] 都以
@racket['info] 级别向主题 @racket['setup/parallel-build] 记录消息。
这些消息是 @racket[parallel-compile-event] 预构结构的实例：

@racketblock[
  (struct parallel-compile-event (worker event) #:prefab)
]
worker 字段是创建事件的 worker 的索引。event 字段是
@racket[make-compilation-manager-load/use-compiled-handler] 中记录的
@racket[compile-event]。


@defproc[(parallel-compile-files [list-of-files (listof path-string?)]
                                 [#:worker-count worker-count exact-positive-integer? (processor-count)]
                                 [#:use-places? use-places? any/c #t]
                                 [#:handler handler (->i ([_worker-id exact-integer?]
                                                          [_handler-type symbol?]
                                                          [_path path-string?]
                                                          [_msg string?] 
                                                          [_out string?] 
                                                          [_err string?])
                                                         void?)
                                            void])
         (or/c void? #f)]{

@racket[parallel-compile-files] 工具函数被 @exec{raco make} 用于
并行编译路径列表。可选的 @racket[#:worker-count] 参数
指定并行编译期间生成的编译 worker 数量。
如果 @racket[use-places?] 为真，编译 worker 实现为 Racket places，
否则编译 worker 实现为单独的 Racket 进程。 回调 @racket[handler] 对每个成功编译的文件以符号 @racket['done]
作为 @racket[_handler-type] 参数调用，当成功编译产生
stdout/stderr 输出时以 @racket['output] 调用，
发生编译错误时以 @racket['error] 调用，
发生不可恢复错误时以 @racket['fatal-error] 调用。
其他参数为每个状态更新提供更多信息。
如果成功，返回值为 @racket[(void)]，如果有错误则返回 @racket[#f]。
 
  @racketblock[
    (parallel-compile-files 
      source-files 
      #:worker-count 4
      #:handler
      (lambda (type work msg out err)
        (match type
          ['done (when (verbose) (printf " Made ~a\n" work))]
          ['output (printf " Output from: ~a\n~a~a" work out err)]
          [_ (printf " Error compiling ~a\n~a\n~a~a"
                     work
                     msg
                     out
                     err)])))]

@history[#:changed "7.0.0.19" @elem{Added the @racket[#:use-places?] argument.}]}

@defproc[(parallel-compile 
  [worker-count non-negative-integer?] 
  [setup-fprintf (->i ([_stage string?] [_format string?]) 
                      () 
                      #:rest (listof any/c) void)]
  [append-error (->i ([_cc cc?]
                      [_prefix string?] 
                      [_exn (or/c exn? (cons/c string? string?) #f)]
                      [_out string?]
                      [_err string?]
                      [_message string?])
                     void?)]
  [collects-tree (listof any/c)]
  [#:use-places? use-places? any/c #t])
 (void)]{

@racket[parallel-compile] 函数被 @exec{raco setup} 用于并行编译集合。
@racket[worker-count] 参数指定并行编译期间生成的编译 worker 数量。
@racket[use-places?] 参数指定是否使用 places，
否则使用单独的进程。
@racket[setup-fprintf] 和 @racket[append-error] 函数
传达中间编译结果和错误。
@racket[collects-tree] 参数是一个复合数据结构，
包含 collects 目录的内存树表示。

当 @racket[append-error] 的 @racket[_exn] 参数是一对字符串时，
第一个字符串是错误消息的长形式，第二个字符串是短形式
（例如省略求值上下文信息）。

@history[#:changed "6.1.1.8" @elem{Changed @racket[append-error] to allow
                                   a pair of error strings.}
         #:changed "7.0.0.19" @elem{Added the @racket[#:use-places?] argument.}]}

@; ----------------------------------------------------------------------

@section[#:tag "cm-accomplice"]{语法变换器的编译管理器钩子}

@defmodule[compiler/cm-accomplice]

@defproc[(register-external-file [file (and path? complete-path?)]
                                 [#:indirect? indirect? any/c #f])
         void?]{

以 @racket['info] 级别向当前记录器记录一条消息
（参见 @racket[log-message]），主题为 @racket['cm-accomplice]。
消息数据是一个 @racketidfont{file-dependency} 预构结构类型，
有两个字段；第一个字段的值是 @racket[file]，
第二个字段的值是 @racket[#f]（表示非模块依赖）。
如果 @racket[indirect?] 参数为真，数据更具体地是
@racketidfont{file-dependency/options} 预构结构类型的实例，
该类型是 @racketidfont{file-dependency} 的子类型，
有一个额外字段：将 @racket['indirect] 映射到 @racket[#t] 的哈希表。

由 @racketmodname[compiler/cm] 实现的编译管理器
查找此类消息以注册外部依赖。作为响应，
编译管理器（在 @filepath{.dep} 文件中）将路径记录为
对当前正在编译的模块的实现有贡献。之后，
如果注册的文件被修改，编译管理器将知道重新编译该模块。
间接依赖对重新编译没有影响，但它可以向其他工具
（如包依赖检查器）发出信号，表明依赖是间接的
（不应暗示直接的包依赖）。

例如，@racket[include] 宏在展开 @racket[include] 形式时，
以包含文件的路径调用此过程。}

@defproc[(register-external-module [file (and path? complete-path?)]
                                   [#:indirect? indirect? any/c #f])
         void?]{

类似于 @racket[register-external-file]，但记录一条消息，
使用 @racketidfont{file-dependency} 预构结构类型，
其第二个字段为 @racket[#t]。

由 @racketmodname[compiler/cm] 实现的编译管理器
识别该消息以注册对模块的依赖
（这意味着对该模块的所有依赖项的依赖等）。}

@; ----------------------------------------

@section{简单字节码创建的 API}

@defmodule[compiler/compile-file]

@defproc[(compile-file [src path-string?]
                       [dest path-string? (let-values ([(base name dir?) (split-path src)])
                                            (build-path base "compiled"
                                                        (path-add-suffix name #".zo")))]
                       [filter (any/c . -> . any/c) values])
         path?]{

编译 Racket 文件 @racket[src] 并将编译后的代码保存到
@racket[dest]。如果未提供 @racket[dest] 且
@filepath{compiled} 子目录尚不存在，则创建
该子目录。@racket[compile-file] 的结果是目标文件的路径。

如果提供了 @racket[filter] 过程，则将其应用于每个
源表达式，并编译结果。 

请注意，@racket[compile-file] 使用当前的 reader
参数化来读取 @racket[src]。通常，
@racket[compile-file] 应该从传递给
@racket[with-module-reading-parameterization] 的 thunk 中调用，
以便以一致的方式解析源程序并允许 @hash-lang[]。

@racket[src] 中的每个表达式都独立编译。
如果 @racket[src] 不包含单个 @racket[module] 表达式，
则当直接加载 @racket[src] 时，较早的表达式可能影响
较晚表达式的编译。适当的 @racket[filter] 可以使编译
表现得像求值，但 @racket[compile-zos] 过程也（尽可能）
解决了这个问题。

另请参见 @racket[managed-compile-zo]。}

@; ----------------------------------------------------------------------

@section[#:tag "api:compile-path"]{字节码路径的 API}

@defmodule[compiler/compilation-path]

@history[#:added "6.0.1.10"]

@defproc[(get-compilation-dir+name [path path-string?]
                                   [#:modes modes (non-empty-listof (and/c path-string? relative-path?)) (use-compiled-file-paths)]
                                   [#:roots roots (non-empty-listof (or/c path-string? 'same)) (current-compiled-file-roots)]
                                   [#:default-root default-root (or/c path-string? 'same) (car roots)])
         (values path? path?)]{

确定保存 @racket[path] 的字节码形式的目录
以及 @racket[path] 的基本名称。

通过按顺序检查 @racket[roots]，并
对 @racket[roots] 的每个元素按顺序检查 @racket[modes] 来确定目录。
第一个包含名称与 @racket[path] 加上 @filepath{.zo} 匹配的文件的目录
（在 @racket[path-add-suffix] 的意义上）被报告为返回目录路径。
如果未找到此类文件，则结果对应于 @racket[modes] 的第一个元素
与 @racket[default-root] 的组合。

@history[#:changed "7.1.0.9" @elem{Added the @racket[#:default-root] argument.}]}

@defproc[(get-compilation-dir [path path-string?]
                              [#:modes modes (non-empty-listof (and/c path-string? relative-path?)) (use-compiled-file-paths)]
                              [#:roots roots (non-empty-listof (or/c path-string? 'same)) (current-compiled-file-roots)]
                              [#:default-root default-root (or/c path-string? 'same) (car roots)])
         path?]{

与 @racket[get-compilation-dir+name] 相同，但只返回第一个结果。

@history[#:changed "7.1.0.9" @elem{Added the @racket[#:default-root] argument.}]}

@defproc[(get-compilation-bytecode-file [path path-string?]
                                        [#:modes modes (non-empty-listof (and/c path-string? relative-path?)) (use-compiled-file-paths)]
                                        [#:roots roots (non-empty-listof (or/c path-string? 'same)) (current-compiled-file-roots)]
                                        [#:default-root default-root (or/c path-string? 'same) (car roots)])
         path?]{

与 @racket[get-compilation-dir+name] 相同，但组合结果
并添加 @filepath{.zo} 后缀以得到字节码文件路径。

@history[#:changed "7.1.0.9" @elem{Added the @racket[#:default-root] argument.}]}

@; ----------------------------------------------------------------------

@section[#:tag "zo"]{编译为原始字节码}

@exec{raco make} 的 @DFlag{no-deps} 模式是一种简化的
编译形式，因为它不跟踪导入依赖。但它确实支持
在最初导入 @racketmodname[scheme #:indirect] 的命名空间中编译非模块源。

在模块外部，顶层的 @racket[define-syntaxes]、
@racket[module]、@racket[#%require]、
@racket[define-values-for-syntax] 和 @racket[begin] 表达式
由 @exec{raco make --no-deps} 特殊处理：表达式的编译时
部分会被求值，因为它可能影响后面的表达式。

例如，当编译包含以下内容的文件时

@racketblock[
(require racket/class)
(define f (class object% (super-new)))
]

来自 @racketmodname[racket/class] 库的 @racket[class] 形式
必须在编译时在编译命名空间中绑定。因此，
@racket[require] 表达式既被编译（出现在输出代码中）
又被求值（用于进一步计算）。

许多定义形式展开为 @racket[define-syntaxes]。例如，
@racket[define-signature] 展开为 @racket[define-syntaxes]。
在 @DFlag{no-deps} 模式下，@exec{raco make --no-deps}
在展开后检测 @racket[define-syntaxes] 和其他表达式，
因此顶层的 @racket[define-signature] 表达式会影响后续表达式的编译，
正如程序员所期望的那样。

相比之下， a @racket[load] or @racket[eval] expression in a source
file is compiled---but @emph{not evaluated!}---as the source file is
compiled.  Even if the @racket[load] expression loads syntax or
signature definitions, these will not be loaded as the file is
compiled. The same is true of application expressions that affect the
reader, such as @racket[(read-case-sensitive #t)]. The @Flag{p} or
@DFlag{prefix} flag for @exec{raco make} takes a file and loads it before
compiling the source files specified on the command line.

默认情况下，编译的命名空间通过 require
@racketmodname[scheme #:indirect] 初始化。
如果指定了 @DFlag{no-prim} 标志，命名空间改用
@racket[namespace-require/copy] 初始化，这允许对所有
初始绑定进行修改和重定义
（在修改的情况下，除语法形式外）。

一般来说，更好的解决方案是将所有要编译的代码放入一个模块中，
并使用 @exec{raco make} 的默认模式。

@(close-eval cm-eval)

@; ----------------------------------------------------------------------

@include-section["api.scrbl"]

@; ----------------------------------------------------------------------

@section{读取编译依赖的 API}

@defmodule[compiler/depend]{@racketmodname[compiler/depend] 模块提供了一个函数，
用于检查和遍历由 @exec{raco make}、@exec{raco setup}
或 @racketmodname[compiler/cm] 生成的依赖信息。}

@history[#:added "6.90.0.13"]

@defproc[(module-recorded-dependencies [module-file path?])
         (listof (and path? (complete-path? path?)))]{

给定一个已使用 @exec{raco make}、@exec{raco setup}
或 @racketmodname[compiler/cm] 编译的文件的 @racket[module-file]，
通过读取和遍历编译留下的依赖信息文件，
返回 @racket[module-file] 的依赖项列表。}
