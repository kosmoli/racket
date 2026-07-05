#lang scribble/doc
@(require scribble/manual "common.rkt"
          (for-label racket/base raco/all-tools raco/command-name racket/contract/base racket/cmdline))

@title[#:tag "command"]{添加一个 @exec{raco} 命令}

@exec{raco} 支持的命令集可以通过安装的包、@|PLaneT| 包以及其他集合来扩展。命令是通过在集合的 @filepath{info.rkt} 库中定义 @indexed-racket[raco-commands] 来添加的（参见 @secref["info.rkt"]），然后必须通过 @exec{raco setup}（作为直接调用或包安装或 @|PLaneT| 安装的一部分）来索引 @filepath{info.rkt} 文件。

绑定到 @racket[raco-commands] 的值必须是一个 @deftech{command specifications} 列表，其中每个 specification 是一个包含四个值的列表：

@racketblock[
   (list _command-string
         _implementation-module-path
         _description-string
         _prominence)
]

@racket[_command-string] 是命令名称。命令名称的任何非
模糊前缀都可以提供给 @exec{raco} 来调用该命令。

@racket[_implementation-module-path] 通过 module path（
在 @racket[module-path?] 的意义上）命名实现模块。该模块通过
@racket[dynamic-require] 加载和调用来运行命令。该模块可以
通过 @racket[current-command-line-arguments] parameters 访问 command-line 参数，
这些参数在加载命令模块之前被调整为只包含要传递给 command 的参数。
@racket[current-command-name] parameter 也被设置为用来加载命令的 command 名称。
当对命令使用 @exec{raco help} 时，命令会在 @racket[current-command-line-arguments]
中使用一个初始的 @DFlag{help} 参数来启动。

@racket[_description-string] 是一个短字符串，用于描述
@exec{raco help} 响应中的命令。描述不应大写也不应以句号结尾。

@racket[_prominence] 值应该是一个实数或 @racket[#f]。
@racket[#f] 值意味着该命令不应包含在"常用命令"的短列表中。
数字表示命令的相对突出程度；@exec{help} 命令的值为 @racket[110]，
可能没有命令应该比这更突出。@exec{pack} 工具目前被评为最低调的
常用命令，其值为 @racket[10]。

例如，@filepath{compiler} 集合的 @filepath{info.rkt} 可能包含

@racketblock[
 (define raco-commands
   '(("make" compiler/commands/make "compile source to bytecode" 100)
     ("decompile" compiler/commands/decompile "decompile bytecode" #f)))
]

以便 @exec{make} 被视为常用命令，而 @exec{decompile} 则作为不常用的命令可用。

@section{Command Argument Parsing}

@defmodule[raco/command-name]{@racketmodname[raco/command-name]
库提供函数来帮助 @exec{raco} 命令向用户标识自己。}

@defparam[current-command-name name (or/c string? #f)]{

当前通过 @racket[dynamic-require] 正在加载的命令的名称，
如果 @exec{raco} 未加载任何命令则为 @racket[#f]。

命令实现可以使用此参数来区分它是通过 @exec{raco} 调用
还是通过其他方式调用。}

@defproc[(short-program+command-name) string?]{

返回标识当前 command 的字符串。当 @racket[current-command-name]
是 string 时，结果是 @exec{raco} 可执行文件的短名称后跟一个空格
和命令名称。否则，它是当前可执行文件的短名称，
通过从 @racket[(find-system-path 'run-file)] 的结果中去除路径来确定。
在 Windows 上，@filepath{.exe} 扩展名从可执行文件名中移除。

此函数的结果适合与 @racket[command-line] 一起使用。例如，
@exec{decompile} 工具通过以下方式解析 command-line 参数：

@racketblock[
 (define source-files
   (command-line
    #:program (short-program+command-name)
    #:args source-or-bytecode-file
    source-or-bytecode-file))
]

以便 @exec{raco decompile --help} 打印

@verbatim[#:indent 2]{
usage: raco decompile [ <option> ... ] [<source-or-bytecode-file>] ...

<option> is one of

  --help, -h
     Show this help
  --
     Do not treat any remaining argument as a switch (at this level)

 Multiple single-letter switches can be combined after
 one `-`. For example, `-h-` is the same as `-h --`.
}}

@defproc[(program+command-name) string?]{

类似于 @racket[short-program+command-name]，但路径（如果有）
不会从当前可执行文件名中去除。}

@section{访问 @exec{raco} 命令}

@defmodule[raco/all-tools]{@racketmodname[raco/all-tools]
库为安装的包、@|PLaneT| 包和其他集合收集 @indexed-racket[racco-commands] specifications。}

@defproc[(all-tools) (hash/c string? (list/c string? module-path? string? (or/c real? #f)))]

返回一个以集合名称为 keys、@tech{command specifications} 为 values 的 hashtable。
例如，以下程序调用 @exec{racco make file.rkt}：

@racketblock[
  (require raco/all-tools)

  (define raco-make-spec (hash-ref (all-tools) "make"))

  (parameterize ([current-command-line-arguments (vector "file.rkt")])
    (dynamic-require (second raco-make-spec) #f))
]
