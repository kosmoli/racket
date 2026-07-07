#lang scribble/doc
@(require "mz.rkt"
          (for-label setup/cross-system))

@(define (bc-only cs)
    @elem{(@tech{BC} only; @cs for @tech{CS})})
 
@title[#:tag "runtime"]{Environment and Runtime Information}

@defproc[(system-type [mode (or/c 'os 'os* 'arch 'word 'so-find 'platform
                                  'vm 'gc 'link 'machine 'target-machine
                                  'so-suffix 'so-mode 'fs-change 'cross)
                            'os])
         (or/c symbol? string? bytes? exact-positive-integer? vector? #f)]{

返回有关操作系统、构建模式或运行 Racket 的机器的信息。（安装工具应使用 @racket[cross-system-type] 以支持交叉安装。）

In @indexed-racket['os] mode,
 the possible symbol results are:

@itemize[
@item{@indexed-racket['unix]}
@item{@indexed-racket['windows]}
@item{@indexed-racket['macosx]}
]

@margin-note{在引入 @racket['os*] 和 @racket['arch] 模式之前，@racket[(system-library-subpath #f)] 可用于间接获取此信息。}

在 @indexed-racket['os*] 模式下，结果类似于 @racket['os] 模式，但细化到特定的操作系统，如 @racket['linux] 或 @racket['freebsd]，而不是通用的 @racket['unix] 分类。

在 @indexed-racket['arch] 模式下，结果是表示架构的 symbol。可能的结果包括 @racket['x86_64]、@racket['i386]、@racket['aarch64]、@racket['arm]（32 位）和 @racket['ppc]（32 位）。

在 @indexed-racket['word] 模式下，结果为 @racket[32] 或 @racket[64]，以指示 Racket 是作为 32 位程序还是 64 位程序运行。

在 @indexed-racket['so-find] 模式下，结果是标识用于查找和管理平台特定共享对象（即动态库）的约定的 symbol。可能的结果包括 @racket['natipkg]（表示原生库通常通过 Racket 包提供）和 @racket['system]（表示它们通常通过操作系统管理）。旨在与其他包管理器一起使用的 Racket 构建可以报告 @racket['natipkg] 或 @racket['system] 以外的 symbol。

在 @indexed-racket['platform] 模式下，结果是一个字符串，包含 @racket['os*]、@racket['arch] 和 @racket['so-find] 的组合信息以表示平台。如果 @racket['so-find] 是 @racket['os*] 的默认值，则省略该模式：Windows 和 Mac OS 为 @racket['natipkg]，否则为 @racket['system]。相同字符串的 @tech{path} 形式由 @racket[(system-library-subpath #f)] 返回。

@margin-note{See @guidesecref["virtual-machines"] for more information
 about the @racket['vm] and @racket['gc] mode results.}

在 @indexed-racket['vm] 模式下，可能的 symbol 结果为（另见 @secref["implementations"]）：

@itemize[
@item{@indexed-racket['racket]}
@item{@indexed-racket['chez-scheme]}
]

在 @indexed-racket['gc] 模式下，可能的 symbol 结果为（另见 @secref["implementations"]）：

@itemize[
@item{@indexed-racket['cgc] --- when @racket[(system-type 'vm)] is @racket['racket]}
@item{@indexed-racket['3m] --- when @racket[(system-type 'vm)] is @racket['racket]}
@item{@indexed-racket['cs] --- when @racket[(system-type 'vm)] is @racket['chez-scheme]}
]

在 @indexed-racket['link] 模式下，可能的 symbol 结果为：

@itemize[
@item{@indexed-racket['static] (Unix)}
@item{@indexed-racket['shared] (Unix)}
@item{@indexed-racket['dll] (Windows)}
@item{@indexed-racket['framework] (Mac OS)}
]

Racket 的未来移植版本可能会扩展 @racket['os]、@racket['os*]、@racket['arch]、@racket['vm]、@racket['gc] 和 @racket['link] 的结果列表。

在 @indexed-racket['machine] 模式下，结果是一个字符串，包含有关当前机器的更多详细信息，采用平台特定的格式。

在 @indexed-racket['target-machine] 模式下，结果是运行 Racket 的本机字节码格式的 symbol，如果除机器无关格式外没有本机格式，则为 @racket[#f]。如果结果是 symbol，则 @racket[compile-target-machine?] 在应用于该 symbol 时返回 @racket[#t]；另见 @racket[current-compile-target-machine]。

在 @indexed-racket['so-suffix] 模式下，结果是一个不可变的字节字符串，表示当前平台上用于共享对象的文件扩展名。字节字符串以句点开头，因此适合作为 @racket[path-replace-suffix] 的第二个参数。

在 @indexed-racket['so-mode] 模式下，如果默认情况下应以 ``local'' 模式打开外部库（如大多数平台上），则结果为 @racket['local]；如果应以 ``global'' 模式打开外部库，则结果为 @racket['global]。

在 @indexed-racket['fs-change] 模式下，结果是一个包含四个元素的不可变向量。每个元素要么是 @racket[#f]，要么是 symbol，其中 symbol 表示存在某属性，@racket[#f] 表示不存在该属性。可能的 symbol 按顺序为：

@itemize[
@item{@indexed-racket['supported] --- @racket[filesystem-change-evt]
 can produce a @tech{filesystem change event} to monitor filesystem changes;
 if this symbol is not first in the vector, all other vector elements
 are @racket[#f]}
@item{@indexed-racket['scalable] --- resources consumed by a
 @tech{filesystem change event} are effectively limited only by
 available memory, as opposed to file-descriptor limits; this property
 is @racket[#f] on Mac OS and BSD variants of Unix}
@item{@indexed-racket['low-latency] --- creation and checking of a
 @tech{filesystem change event} is practically instantaneous; this
 property is @racket[#f] on Linux}
@item{@indexed-racket['file-level] --- a @tech{filesystem change
 event} can track changes at the level of a file, as opposed to the
 file's directory; this property is @racket[#f] on Windows}
]

在 @indexed-racket['cross] 模式下，结果报告是否已选择跨平台构建模式（通过 @exec{racket} 的 @Flag{C} 或 @DFlag{cross} 参数；参见 @secref["mz-cmdline"]）。可能的 symbol 为：

@itemize[
@item{@indexed-racket['infer] --- infer cross-platform mode based on
 whether @racket[(system-type)] and @racket[(cross-system-type)] report
 the same symbol}
@item{@indexed-racket['force] --- use cross-platform mode, even if the
 current and target system types are the same, because the current and target
 executables can be different}
]

@history[#:changed "6.8.0.2" @elem{Added @racket['vm] mode.}
         #:changed "6.9.0.1" @elem{Added @racket['cross] mode.}
         #:changed "7.1.0.6" @elem{Added @racket['target-machine] mode.}
         #:changed "7.9.0.6" @elem{Added @racket['os*] and @racket['arch] modes.}
         #:changed "9.0.0.8" @elem{Added @racket['so-find] and @racket['platform] modes.}]}


@defproc[(system-language+country) string?]{

返回一个字符串以标识当前用户的语言和国家/地区。

在 Unix 和 Mac OS 上，字符串为五个字符：两个小写 ASCII 字母表示语言，一个下划线，两个大写 ASCII 字母表示国家/地区。在 Windows 上，字符串可以任意长，但语言和国家/地区用英语（所有 ASCII 字母或空格）表示，用下划线分隔。

On Unix, the result is determined by checking the
@indexed-envvar{LC_ALL}, @indexed-envvar{LC_TYPE}, and
@indexed-envvar{LANG} environment variables, in that order (and the
result is used if the environment variable's value starts with two
lowercase ASCII letters, an underscore, and two uppercase ASCII
letters, followed by either nothing or a period). On Windows and
Mac OS, the result is determined by system calls.}


@defproc[(system-library-subpath [mode (or/c 'cgc '3m 'cs #f)
                                       (system-type 'gc)])
         path?]{

返回一个相对目录路径。此字符串可用于构建指向系统特定文件的路径。例如，当 Racket 在 Sparc 架构的 Solaris 上运行时，子路径以 @racket["sparc-solaris"] 开头，而在 i386 架构的 Windows 上，子路径以 @racket["win32\\i386"] 开头。

可选的 @racket[mode] 参数指定相关的垃圾回收变体，即 @racket[(system-type 'gc)] 的可能结果之一：@racket['cgc]、@racket['3m] 或 @racket['cs]。它也可以是 @racket[#f]，在这种情况下，结果与垃圾回收变体无关，其字符串形式与 @racket[(system-type 'platform)] 的结果相同。

安装工具应使用 @racket[cross-system-library-subpath] 以支持交叉安装。

@history[#:changed "7.0" @elem{Added @racket['cs] mode.}]}


@defproc[(version) (and/c string? immutable?)]{

返回一个不可变的字符串，指示当前执行的 Racket 版本。}


@defproc[(banner) (and/c string? immutable?)]{

返回一个不可变的字符串，用于 Racket 的启动横幅文本（或嵌入程序（如 GRacket）的横幅文本）。横幅字符串以换行符结尾。}


@defparam*[current-command-line-arguments argv
                                          (vectorof string?)
                                          (vectorof (and/c string? immutable?))]{

@tech{parameter}，在 Racket 启动时使用命令行参数初始化（不包括任何被视为系统标志的命令行参数）。

在 Unix 和 Mac OS 上，命令行参数作为 @tech{byte strings} 提供给 Racket 进程。参数使用 @racket[bytes->string/locale] 转换为 @tech{strings}，使用 @racketvalfont{#\uFFFD} 作为编码错误字符。}


@defparam[current-thread-initial-stack-size size exact-positive-integer?]{

@tech{parameter}，提供有关为新建线程的局部变量保留多少空间的提示。计算实际使用的空间受 @tech{JIT} 编译影响，但在其他方面与平台无关。}


@defproc[(vector-set-performance-stats! [results (and/c vector?
                                                        (not/c immutable?))]
                                        [thd (or/c thread? #f) #f])
         void?]{

设置 @racket[results] 中的元素以报告当前性能统计信息。如果 @racket[thd] 不是 @racket[#f]，则报告一组特定的线程相关统计信息，否则报告一组不同的全局（在当前 @tech{place} 内）统计信息。

对于全局统计信息，最多在向量中设置 @math{12} 个元素，从开头开始。如果 @racket[results] 有 @math{n} 个元素，其中 @math{n < 12}，则前 @math{n} 个元素被设置为前 @math{n} 个性能统计值。报告的统计值按在 @racket[results] 中设置的顺序如下：

 @itemize[

  @item{@racket[0]: The same value as returned by
  @racket[current-process-milliseconds].}

  @item{@racket[1]: The same value as returned
  by @racket[current-milliseconds].}

  @item{@racket[2]: The same value as returned
  by @racket[current-gc-milliseconds].}

  @item{@racket[3]: The number of garbage collections performed since
  start-up within the current @tech{place}.}

  @item{@racket[4]: The number of thread context switches performed since
  start-up.}

  @item{@racket[5]: The number of internal stack overflows handled since
  start-up @bc-only{0}.}

  @item{@racket[6]: The number of threads currently scheduled for
  execution (i.e., threads that are running, not suspended, and not
  unscheduled due to a synchronization).}

  @item{@racket[7]: The number of syntax objects read from compiled code
  since start-up @bc-only{0}.}

  @item{@racket[8]: The number of hash-table searches performed @bc-only{0}. When
  this counter reaches the maximum value of a @tech{fixnum}, it
  overflows to the most negative @tech{fixnum}.}

  @item{@racket[9]: The number of additional hash slots searched to
  complete hash searches using double hashing @bc-only{0}.  When this counter
  reaches the maximum value of a @tech{fixnum}, it overflows to the
  most negative @tech{fixnum}.}

  @item{@racket[10]: The number of bytes allocated for machine code
  that is not reported by @racket[current-memory-use] @bc-only{0}.}

  @item{@racket[11]: The peak number of allocated bytes just
  before a garbage collection.}

 ]

对于线程特定的统计信息，最多在向量中设置 @math{4} 个元素：

 @itemize[

  @item{@racket[0]: @racket[#t] if the thread is running, @racket[#f]
  otherwise (same result as @racket[thread-running?]).}

  @item{@racket[1]: @racket[#t] if the thread has terminated,
  @racket[#f] otherwise (same result as @racket[thread-dead?]).}

  @item{@racket[2]: @racket[#t] if the thread is currently blocked on a
  synchronizable event (or sleeping for some number of milliseconds),
  @racket[#f] otherwise.}

  @item{@racket[3]: The number of bytes currently in use for the
  thread's continuation @bc-only{0}.}

 ]

@history[#:changed "6.1.1.8" @elem{Added vector position @racket[11] for global statistics.}]}
