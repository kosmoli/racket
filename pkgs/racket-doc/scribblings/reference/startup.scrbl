#lang scribble/doc
@(require "mz.rkt"
          scribble/bnf
          (for-label racket/pretty
                     racket/gui/base
                     setup/dirs
                     racket/interaction-info
                     compiler/cm))

@(define (FlagFirst n) (as-index (Flag n)))
@(define (DFlagFirst n) (as-index (DFlag n)))
@(define (PFlagFirst n) (as-index (PFlag n)))

@(define (nontermstr s)
   @elem{@racketvalfont{"}@nonterm[s]@racketvalfont{"}})

@(define eventspace
   @tech[#:doc '(lib "scribblings/gui/gui.scrbl")]{eventspace})

@title[#:tag "running-sa"]{Running Racket or GRacket}

核心的 Racket 运行时系统有两种主要变体：

@itemize[

 @item{Racket，它提供了实现 @racketmodname[racket/base] 所依赖的基础库。在 Unix 和 Mac OS 上，可执行文件名为
       @as-index{@exec{racket}}. On Windows, the executable is
       called @as-index{@exec{Racket.exe}}.}

 @item{GRacket，它是 @exec{racket} 的一个 GUI 变体，其程度取决于系统对它们的区分。在 Unix 上，可执行文件名为 @as-index{@exec{gracket}}， 和 single-instance 标志
       和 X11 相关标志专门处理并传递给
       the @racket[racket/gui/base] library. On Windows, the
       executable is called @as-index{@exec{GRacket.exe}}, and it is a
       GUI application (as opposed to a console application) that
       implements single-instance support. On Mac OS, the
       @exec{gracket} script launches @as-index{@exec{GRacket.app}}.}

]

@; ----------------------------------------------------------------------

@section[#:tag "init-actions"]{Initialization}

在启动时，顶级环境不包含任何 binding——甚至连
@racket[#%app] for function application. 名称以 @racketidfont{#%} 开头的原始 module 已被定义，但它们不用于直接使用，且此类 module 的集合可能会变化。  For example,
the @indexed-racket['#%kernel] module is eventually used to bootstrap
the implementation of @racketmodname[racket/base].

Racket 或 GRacket 的第一个动作是
@racket[current-library-collection-paths] 设置为
@racket[(find-library-collection-paths _pre-extras _extras)] 的结果，其中
@racket[_pre-extras] 通常为 @racket[null]，@racket[_extras]
是命令行通过 @Flag{S}/@DFlag{search} 指定的额外目录路径。 由 Racket 或 GRacket 可执行文件生成的独立执行文件
可以嵌入将作为 @racket[_pre-extras] 使用的路径。

Racket 和 GRacket 接着 @racket[require] @racketmodname[racket/init]
and @racketmodname[racket/gui/init], respectively, but only if the
command line does not specify a @racket[require] flag
(@Flag{t}/@DFlag{require}, @Flag{l}/@DFlag{lib}, or
@Flag{u}/@DFlag{require-script}) before any @racket[eval],
@racket[load], or read-eval-print-loop flag (@Flag{e}/@DFlag{eval},
@Flag{f}/@DFlag{load}, @Flag{r}/@DFlag{script}, @Flag{m}/@DFlag{main},
or @Flag{i}/@DFlag{repl}). The initialization library can be changed
with the @Flag{I} @tech{configuration option}. The
初始化库的 @racket[configure-runtime] submodule 或初始化库语言的 @racket['configure-runtime] property 在库被实例化之前使用；参见 @secref["configure-runtime"]。

在可能加载初始化模块之后, @racket[eval]、@racket[load] 和 @racket[require] 按命令行提供的顺序执行。如果其中任何一个引发了未捕获的异常，则跳过剩余的 @racket[eval]、@racket[load] 和 @racket[require]。如果第一个 @racket[require] 先于任何 @racket[eval] 或 @racket[load]，从而使初始化库被跳过，则被 require 的 module 的 @racket[configure-runtime] submodule 或
被 require 的 module 的库语言的 @racket['configure-runtime] property 在 module 被实例化之前使用；参见 @secref["configure-runtime"]。

在运行所有命令行 expression、, 和 module 之后，如果没有提供除 @tech{configuration option} 之外的命令行标志，Racket 或 GRacket 会启动一个 read-eval-print loop 进行交互式求值。对于 Racket，read-eval-print loop 通过调用 @racketmodname[racket/repl] 中的 @racket[read-eval-print-loop] 来运行。对于 GRacket，read-eval-print loop 通过调用 @racketmodname[racket/gui/base] 中的 @racket[graphical-read-eval-print-loop] 来运行。如果提供了不是 @tech{configuration option} 的任何命令行参数，则不会启动 read-eval-print-loop，除非在命令行上提供了 @Flag{i}/@DFlag{repl} 标志来专门重新启用它。

此外，在 read-eval-print loop 即将启动之前
之前，Racket 运行 @racketmodname[racket/interactive]，GRacket 运行 @racketmodname[racket/gui/interactive]，除非在 @racket[(find-config-dir)] 中找到的安装的 @filepath{config.rktd} 文件中指定了不同的交互文件，或者在 @racket[(find-system-path 'addon-dir)] 中找到了 @filepath{interactive.rkt} 文件。如果在命令行上指定了 @Flag{q}/@DFlag{no-init-file} 标志，则不运行任何交互文件。

最后，在 Racket 或 GRacket 退出之前, 它会调用主线程中 @racket[executable-yield-handler] 当前值的 procedure，除非指定了 @Flag{V}/@DFlag{no-yield} 命令行标志。require @racketmodname[racket/gui/base] 会设置此 parameter 调用 @racket[(racket 'yield)]。

@history[#:changed "6.7" @elem{Run @racketmodname[racket/interactive] file
         rather than directly running @racket[(find-system-path 'init-file)].}
         #:changed "6.90.0.30" @elem{Run a read-eval-print loop by
         using @racketmodname[racket/repl] or @racketmodname[racket/gui/base]
         instead of @racketmodname[racket/base] or @racketmodname[racket/gui/init].}]

@; ----------------------------------------------------------------------

@section[#:tag "exit-status"]{Exit Status}

如果在命令行期间发生错误，则 Racket 或 GRacket 进程 if
如果在命令行 @racket[eval]（通过 @Flag{e} 等）、@racket[load]（通过 @Flag{f}、@Flag{r} 等）或 @racket[require]（通过 @Flag{l}、@Flag{t} 等）期间发生错误——或者更一般地，如果围绕这些求值的 @tech{prompt} 的 abort handler 被调用——但仅当没有启动 read-eval-print loop 时才会。否则，默认退出状态为 @racket[0]。

在所有情况下，对 @racket[exit] (when the default @tech{exit
handler} is in place) can end the process with a specific status
value.

@; ----------------------------------------------------------------------

@include-section["init.scrbl"]

@; ----------------------------------------------------------------------

@section[#:tag "mz-cmdline"]{Command Line}

Racket 和 GRacket 可执行文件识别以下 command-line
flags:

@itemize[

 @item{文件和 expression 选项：

 @itemize[

  @item{@FlagFirst{e} @nonterm{expr} or @DFlagFirst{eval}
        @nonterm{expr} : @racket[eval] @nonterm{expr}。求值结果通过 @racket[current-print] 打印。}

  @item{@FlagFirst{f} @nonterm{file} or @DFlagFirst{load}
        @nonterm{file} : @racket[load] @nonterm{file}；如果 @nonterm{file} 是 @filepath{-}，则从标准输入读取并求值 expression。}

  @item{@FlagFirst{t} @nonterm{file} or @DFlagFirst{require}
        @nonterm{file} : @racket[require] @nonterm{file}，如果可用，然后 @racket[require] @racket[(submod (file @#,nontermstr{file}) main)]。}

  @item{@FlagFirst{l} @nonterm{path} or @DFlagFirst{lib}
       @nonterm{path} : @racket[require] @racket[(lib @#,nontermstr{path})]，如果可用，然后 @racket[require] @racket[(submod (lib @#,nontermstr{path}) main)]。}

  @item{@FlagFirst{p} @nonterm{package} :
       @racket[require] @racket[(planet @#,nontermstr{package})]，如果可用，然后 @racket[require] @racket[(submod (planet @#,nontermstr{package}) main)]。}

  @item{@FlagFirst{r} @nonterm{file} or @DFlagFirst{script}
        @nonterm{file} : @racket[load] @nonterm{file}
       @margin-note*{尽管名为 @DFlag{script}，它通常不用于 Unix 脚本。有关脚本的更多信息，参见 @guidesecref["scripts"]。}
        作为脚本。此标志类似于 @Flag{f} @nonterm{file} 加上 @Flag{N} @nonterm{file} 来设置程序名和 @Flag{-} 来使所有后续命令行元素被视为非标志参数。}

  @item{@FlagFirst{u} @nonterm{file} or @DFlagFirst{require-script}
       @nonterm{file} : @racket[require]s @nonterm{file} as a script;
       此标志类似于 @Flag{t} @nonterm{file} plus @Flag{N}
       @nonterm{file} 来设置程序名和 @Flag{-} to cause
       all further command-line elements to be treated as non-flag
       arguments.}

  @item{@FlagFirst{k} @nonterm{n} @nonterm{m} @nonterm{p} : 从可执行文件中的文件位置 @nonterm{n} 到 @nonterm{m} 以及从 @nonterm{m} 到 @nonterm{p} 加载嵌入的代码。（在 Mac OS 上，@nonterm{n}、@nonterm{m} 和 @nonterm{p} 相对于可执行文件中的 @tt{__PLTSCHEME} 段。在 Windows 上，它们相对于类型 257、ID 1 的资源。在使用 ELF 的 Unix 上，它们相对于可执行文件中的 @tt{.rackprog} 段。）第一个范围在每个新的 @tech{place} 中加载，在该范围中声明的任何 module 在 @racket[module-predefined?] 的意义上被认为是预定义的。此选项通常嵌入在也嵌入了 Racket 代码的独立二进制文件中。}

  @item{@FlagFirst{Y} @nonterm{file} @nonterm{n} @nonterm{m} @nonterm{p} :
        类似于 @Flag{k} @nonterm{n} @nonterm{m} @nonterm{p}，但从 @nonterm{file} 读取（不需要对段或资源偏移进行调整）。}

  @item{@FlagFirst{m} or @DFlagFirst{main} : 求值对在顶层环境中绑定的 @racketidfont{main} 的调用。所有未被作为选项处理的命令行参数（即放入 @racket[current-command-line-arguments] 的参数）作为参数传递给 @racketidfont{main}。调用结果通过 @racket[current-print] 打印。

        对 @racketidfont{main} 的调用被构造为 expression @racket[((unsyntax @racketidfont{main}) _arg-str ...)]，其中 expression 的词法上下文将 @racketidfont{#%app} 和 @racketidfont{#%datum} 绑定为 @racket[#%plain-app] 和 @racket[#%datum]，但 @racketidfont{main} 的词法上下文是顶层环境。}

 ]}

 @item{交互选项：

 @itemize[

  @item{@FlagFirst{i} or @DFlagFirst{repl} : 运行交互式 read-eval-print loop，在显示 @racket[(banner)] 并加载 @racket[(find-system-path 'init-file)] 之后，使用 @racket[read-eval-print-loop]（Racket）或 @racket[graphical-read-eval-print-loop]（GRacket）。对于 Racket，@racket[(read-eval-print-loop)] 之后跟随 @racket[(newline)]。对于 GRacket，提供 @Flag{z}/@DFlag{text-repl} configuration option 以使用 @racket[read-eval-print-loop]（和 @racket[newline]）代替 @racket[graphical-read-eval-print-loop]。}

  @item{@FlagFirst{n} or @DFlagFirst{no-lib} : 在未被其他方式禁用时，跳过 require 初始化库（即 @racketmodname[racket/init] 或 @racketmodname[racket/gui/init]，除非通过 @Flag{I} 标志更改）。}

  @item{@FlagFirst{v} or @DFlagFirst{version} : 显示 @racket[(banner)]。}

  @item{@FlagFirst{K} or @DFlagFirst{back} : 仅限 Mac OS 上的 GRacket；让应用程序保持在后台。}

  @item{@FlagFirst{V} @DFlagFirst{no-yield} : 跳过最终的 @racket[executable-yield-handler] 操作，该操作通常在使用 @racketmodname[racket/gui/base] 的程序退出之前等待主 @|eventspace| 中的所有帧关闭等。出于历史原因，此标志也隐含 @Flag{v}，
        这使得它不太有用，但意味着 @Flag{V} by itself
        behaves like @Flag{v} by iself.}

 ]}

 @item{@deftech{Configuration option}：

 @itemize[

  @item{@FlagFirst{y} or @DFlagFirst{make} : 启用在初始 namespace 中加载的 module 的已编译 @filepath{.zo} 文件的自动生成和更新。具体来说，@racket[(make-compilation-manager-load/use-compiled-handler)] 的结果在其他 module 加载操作之前被安装为 @tech{compiled-load handler}。@bold{注意：}此标志用于交互式环境；在脚本中使用它可能是个坏主意，因为脚本的并发调用可能会在尝试更新已编译文件时冲突，或者可能存在文件系统权限问题。使用 @FlagFirst{c}/@DFlagFirst{no-compiled} 取消 @FlagFirst{y}/@DFlagFirst{make} 的效果。}

  @item{@FlagFirst{c} or @DFlagFirst{no-compiled} : 通过将 @racket[use-compiled-file-paths] 初始化为 @racket[null] 来禁用加载已编译的 @filepath{.zo} 文件。请谨慎使用：这实际上忽略了所有 @filepath{compiled} 子目录的内容，使得任何使用的 module 都会即时编译——包括 @racketmodname[racket/base] 及其依赖——这会导致极其昂贵的运行时间。}

  @item{@FlagFirst{q} or @DFlagFirst{no-init-file} : 对于 @Flag{i}/@DFlag{repl}，跳过加载 @racket[(find-system-path 'init-file)]。}

  @item{@FlagFirst{z} or @DFlagFirst{text-repl} : 仅限 GRacket；将 @Flag{i}/@DFlag{repl} 改为使用 @racket[textual-read-eval-print-loop] 代替 @racket[graphical-read-eval-print-loop]。}

  @item{@FlagFirst{I} @nonterm{path} : 将 @racket[(lib @#,nontermstr{path})] 设置为用于初始化 namespace 的 @racket[require] 路径，除非 namespace 初始化被禁用。使用此标志可以有效设置 read-eval-print loop 和其他顶层求值的语言。}

  @item{@FlagFirst{X} @nonterm{dir} or @DFlagFirst{collects}
        @nonterm{dir} : 通过使 @racket[(find-system-path 'collects-dir)] 产生 @nonterm{dir}，将 @nonterm{dir} 设置为主要库集合的路径。如果 @nonterm{dir} 是空字符串，则 @racket[(find-system-path 'collects-dir)] 返回 @filepath{.}，但 @racket[current-library-collection-paths] 被初始化为空列表，@racket[use-collection-link-paths] 被初始化为 @racket[#f]。}

  @item{@FlagFirst{S} @nonterm{dir} or @DFlagFirst{search}
        @nonterm{dir} : 将 @nonterm{dir} 添加到主集合目录之后的默认库集合搜索路径中。如果多次提供 @Flag{S}/@DFlag{dir} 标志，搜索顺序按提供顺序排列。}

  @item{@FlagFirst{G} @nonterm{dir} or @DFlagFirst{config}
        @nonterm{dir} : 设置 @racket[(find-system-path 'config-dir)] 返回的目录。}

  @item{@FlagFirst{A} @nonterm{dir} or @DFlagFirst{addon}
        @nonterm{dir} : 设置 @racket[(find-system-path 'addon-dir)] 返回的目录。}

  @item{@FlagFirst{U} or @DFlagFirst{no-user-path} : 通过将 @racket[use-user-specific-search-paths] parameter 初始化为 @racket[#f]，在搜索集合、C 库等时省略用户特定路径。}

  @item{@FlagFirst{A} @nonterm{dir} or @DFlagFirst{addon}
        @nonterm{dir} : 设置 @racket[(find-system-path 'addon-dir)] 返回的目录。}

  @item{@FlagFirst{R} @nonterm{paths} or @DFlagFirst{compiled}
        @nonterm{paths} : 设置 @racket[current-compiled-file-roots] parameter 的初始值，覆盖任何 @envvar{PLTCOMPILEDROOTS} 设置。@nonterm{paths} 参数的解析方式与 @envvar{PLTCOMPILEDROOTS} 相同（参见 @racket[current-compiled-file-roots]）。}

  @item{@FlagFirst{C} or @DFlagFirst{cross} : 选择跨平台构建模式，使 @racket[(system-type 'cross)] 报告 @racket['force]，并将 @racket[(find-system-path 'config-dir)]、@racket[(find-system-path 'collects-dir)] 和 @racket[(find-system-path 'addon-dir)] 的当前配置分别设置为 @racket[(find-system-path 'host-config-dir)]、@racket[(find-system-path 'host-collects-dir)] 和 @racket[(find-system-path 'host-addon-dir)] 的结果。如果多次提供 @FlagFirst{C} 或 @DFlagFirst{cross}，只有第一个实例生效。}
  
  @item{@FlagFirst{N} @nonterm{file} or @DFlagFirst{name}
        @nonterm{file} : 将 @racket[(find-system-path 'run-file)] 报告的可执行文件名称设置为 @nonterm{file}。}

  @item{@FlagFirst{E} @nonterm{file} or @DFlagFirst{exe}
        @nonterm{file} : 将 @racket[(find-system-path 'exec-file)] 报告的可执行文件名称设置为 @nonterm{file}。}

  @item{@FlagFirst{J} @nonterm{name} or @DFlagFirst{wm-class}
        @nonterm{name} : 仅限 Unix 上的 GRacket；将 @tt{WM_CLASS} 程序类设置为 @nonterm{name}（而 @tt{WM_CLASS} 程序名从可执行文件名称或 @Flag{N}/@DFlag{name} 参数派生）。}

  @item{@FlagFirst{j} or @DFlagFirst{no-jit} : 通过将 @racket[eval-jit-enabled] parameter 设置为 @racket[#f] 来禁用本地代码即时编译器。}

  @item{@FlagFirst{M} or @DFlagFirst{compile-any} : 通过将 @racket[current-compile-target-machine] parameter 设置为 @racket[#f] 来启用与机器无关的字节码。}

  @item{@FlagFirst{d} or @DFlagFirst{no-delay} : 通过将 @racket[read-on-demand-source] parameter 设置为 @racket[#f] 来禁用已编译代码和 syntax object 的按需解析。}

  @item{@FlagFirst{b} or @DFlagFirst{binary} : 为进程的输入、输出和错误端口请求二进制模式而非文本模式。此标志目前没有效果，因为始终使用二进制模式。}

  @item{@FlagFirst{W} @nonterm{levels} or @DFlagFirst{warn}
        @nonterm{levels} : 设置将事件写入原始错误端口的日志级别。可能的 @nonterm{level} 值与 @envvar{PLTSTDERR} 环境变量相同。更多信息参见 @secref["logging"]。}

  @item{@FlagFirst{O} @nonterm{levels} or @DFlagFirst{stdout}
        @nonterm{levels} : 设置将事件写入原始输出端口的日志级别。可能的 @nonterm{level} 值与 @envvar{PLTSTDOUT} 环境变量相同。更多信息参见 @secref["logging"]。}

  @item{@FlagFirst{L} @nonterm{levels} or @DFlagFirst{syslog}
        @nonterm{levels} : 设置将事件写入系统日志的日志级别。可能的 @nonterm{level} 值与 @envvar{PLTSYSLOG} 环境变量相同。更多信息参见 @secref["logging"]。}

 ]}

 @item{元选项：

 @itemize[

  @item{@FlagFirst{Z} : 此标志之后的参数被忽略。此标志在某些简陋的脚本环境中可以方便地替换或取消另一个命令行参数。}
 
  @item{@FlagFirst{-} : 此标志之后的任何参数本身不被用作标志。}
 
  @item{@FlagFirst{h} or @DFlagFirst{help} : 显示关于命令行标志和启动过程的信息并退出，忽略所有其他标志。}
 
 ]}

]

如果至少提供了一个命令行参数, 并且如果任何 @tech{configuration option} 之后的第一个参数不是标志，则在第一个非标志参数之前隐式添加 @Flag{u}/@DFlag{require-script} 标志。

除了配置选项外没有提供其他命令行参数
@tech{configuration options}, then the @Flag{i}/@DFlag{repl} flag is
effectively added.

对于 Unix 上的 GRacket, 以下标志在出现在命令行开头时被识别，并且被视为 configuration option（即它们不会禁用 read-eval-print loop 或阻止插入 @Flag{u}/@DFlag{require-script}）：

@itemize[

  @item{@FlagFirst{display} @nonterm{display} : 设置要使用的 X11 display。}

  @item{@FlagFirst{geometry} @nonterm{arg}, @FlagFirst{bg}
        @nonterm{arg}, @FlagFirst{background} @nonterm{arg},
        @FlagFirst{fg} @nonterm{arg}, @FlagFirst{foreground}
        @nonterm{arg}, @FlagFirst{fn} @nonterm{arg}, @FlagFirst{font}
        @nonterm{arg}, @FlagFirst{iconic}, @FlagFirst{name}
        @nonterm{arg}, @FlagFirst{rv}, @FlagFirst{reverse},
        @PFlagFirst{rv}, @FlagFirst{selectionTimeout} @nonterm{arg},
        @FlagFirst{synchronous}, @FlagFirst{title} @nonterm{arg},
        @FlagFirst{xnllanguage} @nonterm{arg}, or @FlagFirst{xrm}
        @nonterm{arg} : 标准 X11 参数，大多数被忽略，但为了与其他 X11 程序兼容而被接受。@Flag{synchronous} 标志以通常的方式运行。}

  @item{@FlagFirst{singleInstance} : 如果已有一个现有的 GRacket 在同一 X11 display 上运行，且是在具有相同主机名的机器上启动的，并且启动时使用的名称与 @racket[(find-system-path 'run-file)] 报告的名称相同——可能通过 @Flag{N}/@DFlag{name} 命令行参数设置——则所有非选项命令行参数被视为文件名，并通过 application file handler 发送给现有的 GRacket 实例（参见 @racket[application-file-handler]）。}

]

类似地，在 Mac OS 上, 开头为 @FlagFirst{psn_} 的开关被视为特殊配置选项。
它表示 Finder 启动了该应用，因此当前输入、输出和错误输出
被重定向到 GUI 窗口。

多个单字母开关 （前面只有一个 @litchar{-} 的那些）可以通过连接字母合并为一个开关，只要第一个开关不是 @Flag{-}。每个开关的参数放在合并后的开关之后（按开关的顺序）。例如，

@commandline{-ifve @nonterm{file} @nonterm{expr}}

and

@commandline{-i -f @nonterm{file} -v -e @nonterm{expr}}

是等价的。如果合并的 @Flag{-} 出现在同一合并集中的其他合并开关之前，则隐式地移至合并集的末尾。

最后一个选项之后的额外参数 可从 @indexed-racket[current-command-line-arguments] parameter 获取。

@history[#:changed "6.90.0.17" @elem{Added @Flag{O}/@DFlag{stdout}.}
         #:changed "7.1.0.5" @elem{Added @Flag{M}/@DFlag{compile-any}.}
         #:changed "7.8.0.6" @elem{Added @Flag{Z}.}
         #:changed "8.0.0.10" @elem{Added @Flag{E}.}
         #:changed "8.0.0.11" @elem{Added @Flag{Y}.}
         #:changed "8.4.0.1" @elem{Added @Flag{y}/@DFlag{make}.}]

@; ----------------------------------------------------------------------

@section[#:tag "configure-runtime"]{Language Run-Time Configuration}

@guidealso["module-runtime-config"]

一个 module 可以有一个 @as-index[@racket[configure-runtime]] submodule，当 module 是程序的主 module 时，在该 module 本身之前被 @racket[dynamic-require]。通常，@racket[configure-runtime] submodule 由 module 的语言（即 module 初始绑定中的 @racket[#%module-begin] form）添加到 module 中。@racket[configure-runtime] submodule 的主体通常设置 parameter，可能包括 @racket[current-interaction-info]。

另外或此外，还有一个旧协议存在。当使用 @hash-lang{} 实现 module 时，@hash-lang{} 后的语言可以指定当使用该语言的 module 成为程序主 module 时所配置的操作。语言通过以下方式指定运行时配置：

@itemlist[

 @item{将从其源读取的 module 附加一个 @racket['module-language] @tech{syntax property}（参见 @racket[module] 和 @racket[module-compiled-language-info]）；}

 @item{让 @racket['module-language] @tech{syntax property} 指示的函数识别 @indexed-racket['configure-runtime] key，并为其返回一个 vector 列表；每个 vector 必须具有 @racket[(vector _mp _name _val)] 的形式，其中 @racket[_mp] 是 @tech{module path}，@racket[_name] 是 symbol，@racket[_val] 是任意值；以及}

 @item{让每个函数以 @racket[((dynamic-require _mp _name) _val)] 的形式被调用，以配置运行时环境，通常是通过设置诸如 @racket[current-print] 之类的 parameter。}

]

@racket['configure-runtime] 查询返回一个 vector 列表，而不是直接配置环境，以便在创建独立可执行文件时将指定的 module 与程序捆绑在一起；参见 @other-manual[raco-doc] 中的 @secref[#:doc raco-doc "exe"]。

有关定义新的 @hash-lang[] 语言，参见 @racketmodname[syntax/module-reader]。

@; ----------------------------------------------------------------------

@section[#:tag "configure-expand"]{Language Expand Configuration}

@racket[_lang] module 可以有一个 @as-index[@racket[configure-expand]] submodule
当另一个 module 被实现为 @racket[(module _name _lang ....)] 时，该 submodule 在其展开之前被 @racket[dynamic-require]。
子模块在 @tech{root namespace} 中加载，与 reader module 相同。submodule 应提供 @racketidfont{enter-parameterization} 和 @racketidfont{exit-parameterization} 作为 procedure，每个接受零个参数并返回一个 @tech{parameterization}：

@itemlist[

 @item{对于 @racket[_lang] 的 @racketidfont{enter-parameterization} 在 module @racket[(module _name _lang ....)] 的展开开始时被调用，该 parameterization 通过 @racket[call-with-parameterization] 包装 module 展开。}

 @item{对于 @racket[_lang] 的 @racketidfont{exit-parameterization} 在 @racket[(module _name _lang ....)] 的展开触发了其他 module 的展开时被调用，通常是因为它们被正在展开的 module @racket[require]。在这种情况下，调用 @racketidfont{exit-parameterization} 获取一个 parameterization，该 parameterization 被置于对新展开 module 的语言的 @racketidfont{enter-parameterization} 调用的周围。}

]

@racket[current-parameterization] procedure 同时作为 @racketidfont{enter-parameterization} 和 @racketidfont{exit-parameterization} 的默认值。

@racketidfont{enter-parameterization} 产生的 parameterization 通常设置影响展开期间错误报告的 parameter，如 @racket[error-syntax->string-handler]。@racketidfont{exit-parameterization} 产生的 parameterization 通常应恢复 @racketidfont{enter-parameterization} 所做的更改，同时保留其他 parameter 值不变（如 @racket[current-load-relative-directory]）。要从 @racketidfont{enter-parameterization} 的使用向嵌套的 @racketidfont{exit-parameterization} 使用通信，请使用私有的 @tech{parameter}。

@racketidfont{enter-parameterization} 和 @racketidfont{exit-parameterization} procedure 预期基于当前 parameterization 构建，但通常不应修改当前 parameter，因为这种修改会超出返回的 parameterization 的使用范围。相反，使用 @racket[parameterize] 创建包含更新后 parameter 值的新 parameterization。@racketidfont{enter-parameterization} 和 @racketidfont{exit-parameterization} 也不应操作当前 @tech{namespace}，因为这会干扰 module 展开。

@history[#:added "8.8.0.6"]
