#lang scribble/doc
@(require scribble/manual scheme/cmdline "guide-utils.rkt")

@title[#:tag "scripts"]{脚本}

Racket 文件可以在 Unix 和 Mac OS 上转换为可执行脚本。在 Windows 上，
像 Cygwin 这样的兼容层支持同类型的脚本，或者脚本可以实现为批处理文件。

@section{Unix 脚本}

在 Unix 环境（包括 Linux 和 Mac OS）中，可以使用 shell 的 @as-index{@tt{#!}} 约定
将 Racket 文件转换为可执行脚本。文件的前两个字符必须是 @litchar{#!}；
下一个字符必须是空格或 @litchar{/}，第一行的其余部分必须是执行脚本的命令。
对于某些平台，第一行的总长度限制为 32 个字符，有时要求有空格。

@margin-note{使用 @racketmodfont{#lang} @racketmodname[racket/base] 而不是
@racketmodfont{#lang} @racketmodname[racket] 来生成具有更快启动时间的脚本。}

最简单的脚本格式使用 @exec{racket} 可执行文件的绝对路径，后跟模块声明。
例如，如果 @exec{racket} 安装在 @filepath{/usr/local/bin}，则包含以下内容的文件
充当"hello world"脚本：

@verbatim[#:indent 2]{
  #! /usr/local/bin/racket
  #lang racket/base
  "Hello, world!"
}

特别是，如果将上述内容放入文件 @filepath{hello} 中并使该文件可执行
（例如，使用 @exec{chmod a+x hello}），则在 shell 提示符下键入 @exec{./hello}
会产生输出 @tt{"Hello, world!"}。

上述脚本有效是因为操作系统会自动将脚本路径作为参数传递给
由 @tt{#!} 行启动的进程，并且因为 @exec{racket} 将单个非标志参数
视为要运行的包含模块的文件。

不指定完整路径到 @exec{racket} 可执行文件，一种流行的替代方案是
要求 @exec{racket} 位于用户命令路径中，然后使用 @exec{/usr/bin/env}
来"蹦床"执行：

@verbatim[#:indent 2]{
  #! /usr/bin/env racket
  #lang racket/base
  "Hello, world!"
}

在任一种情况下，脚本的命令行参数通过 @racket[current-command-line-arguments]
可用：

@verbatim[#:indent 2]{
  #! /usr/bin/env racket
  #lang racket/base
  (printf "给定参数: ~s\n"
          (current-command-line-arguments))
}

如果需要脚本的名称，可以通过 @racket[(find-system-path 'run-file)] 获取，
而不是通过 @racket[(current-command-line-arguments)]。

通常，处理命令行参数的最佳方法是使用 @racketmodname[racket] 提供的
@racket[command-line] 形式进行解析。@racket[command-line] 形式默认从
@racket[(current-command-line-arguments)] 提取命令行参数：

@verbatim[#:indent 2]{
  #! /usr/bin/env racket
  #lang racket

  (define verbose? (make-parameter #f))

  (define greeting
    (command-line
     #:once-each
     [("-v") "Verbose mode" (verbose? #t)]
     #:args 
     (str) str))

  (printf "~a~a\n"
          greeting
          (if (verbose?) " to you, too!" ""))
}

尝试使用 @DFlag{help} 标志运行以上脚本，查看脚本允许哪些命令行参数。

一种更通用的蹦床使用 @exec{/bin/sh} 加上一些在一种语言中作为注释
在另一种语言中作为表达式的行。此蹦床更复杂，但它对传递给 @exec{racket}
的命令行参数提供了更多控制：

@verbatim[#:indent 2]|{
  #! /bin/sh
  #|
  exec racket -e 'printf "Running...\n"' -u "$0" ${1+"$@"}
  |#
  #lang racket/base
  (printf "上面的输出行通过\n")
  (printf "使用 `-e' 标志产生。\n")
  (printf "给定参数: ~s\n"
          (current-command-line-arguments))
}|

注意，@litchar{#!} 开始一个 Racket 行注释，且 @litchar{#|}...@litchar{|#}
形成一个块注释。同时，@litchar{#} 也开始一个 shell 脚本注释，
而 @exec{exec racket} 中止 shell 脚本以启动 @exec{racket}。这样，
脚本文件对 @exec{/bin/sh} 和 @exec{racket} 都产生有效输入。

@section{Windows 批处理文件}

类似的技巧可用于在 Windows @as-index{@tt{.bat}} 批处理文件中编写 Racket 代码：

@verbatim[#:indent 2]|{
  ; @echo off
  ; Racket.exe "%~f0" %*
  ; exit /b
  #lang racket/base
  "Hello, world!"
  }|

Windows 的新版本包括 PowerShell 脚本语言。通过 PowerShell 脚本使用 Racket
与使用批处理文件略有不同。PowerShell 脚本使用 @as-index{@tt{.ps1}} 扩展名：

@verbatim[#:indent 2]{
  ; Racket.exe (Resolve-Path $PSCommandPath) $args
  ; Exit
  #lang racket/base
  "Hello, world!"
}
