#lang scribble/doc
@(require scribble/manual 
          scribble/bnf
          "common.rkt" 
          (for-label racket/runtime-path
                     racket/base
                     racket/contract
                     launcher/launcher
                     raco/testing
                     compiler/module-suffix
                     compiler/cm))

@title[#:tag "test"]{@exec{raco test}: 运行测试}

@; For `history` to connect to the "compiler-lib" package:
@declare-exporting[compiler/commands/test]

@exec{raco test} 命令要求并运行与命令行上给定的每个路径关联的（默认情况下）
@racket[test] 子模块。命令行标志可以控制运行哪个子模块、当未找到子模块时
是否运行主模块，以及是直接运行测试、在单独进程中运行（默认）还是在单独的地方运行。
当前目录在运行文件之前设置为测试文件的目录。

当参数路径指向目录时，@exec{raco test} 会递归发现并运行目录内所有
以模块后缀结尾的文件（参见 @racket[get-module-suffixes]，但后缀始终包括
@filepath{.rkt}、@filepath{.scrbl}、@filepath{.ss} 和 @filepath{.scm}），
或者具有由 @filepath{info.rkt} 文件中的 @racket[test-command-line-arguments]
提供的（可能为空的）命令行参数列表，或者由 @filepath{info.rkt} 文件中的
@racket[test-include-paths] 指定的文件。同时，@exec{raco test} 会按照
@filepath{info.rkt} 文件中的 @racket[test-omit-paths] 的指示省略目录中的文件和子目录。

如果测试通过 @racket[test-log!] 记录了失败的测试代码、导致 Racket 以非零退出码退出，
或者（当指定了 @Flag{e} 或 @DFlag{check-stderr} 时）在错误端口上产生输出，
则该测试被视为失败。

@exec{raco test} 命令接受多个标志：

@itemize[

 @item{@Flag{c} 或 @DFlag{collection}
       --- 将参数解释为要测试其内容的集合（与目录内容的方式相同），
       并将 @DFlag{process} 设为默认测试模式。}

 @item{@Flag{p} 或 @DFlag{package}
       --- 将参数解释为要测试其内容的包（与目录内容的方式相同）。
       搜索所有包作用域以找到第一个最具体的 @tech[#:doc
       '(lib "pkg/scribblings/pkg.scrbl")]{package scope}。此标志也将
       @DFlag{process} 设为默认测试模式。}
 
 @item{@Flag{l} 或 @DFlag{lib}
       --- 将参数解释为要测试的库。每个参数 @nonterm{arg}
       被视为模块路径 @racket[(lib "@nonterm{arg}")]。
       如果指定了单个模块，默认测试模式为 @DFlag{direct}，
       如果指定了多个模块，则为 @DFlag{process}。}

 @item{@Flag{m} 或 @DFlag{modules}
       --- 不仅将参数解释为路径（这是默认模式），而且将它们视为与目录中
       发现的路径相同，这意味着忽略没有模块扩展名或未通过
       @racket[test-command-line-arguments] 或 @racket[test-include-paths]
       在 @filepath{info.rkt} 文件中显式启用的文件参数；同时，
       可以通过 @filepath{info.rkt} 文件中的 @racket[test-omit-paths]
       禁用原本启用的路径。如果指定了单个路径，默认测试模式为 @DFlag{direct}，
       如果指定了多个路径，则为 @DFlag{process}。}

 @item{@DFlag{drdr}
       --- 配置默认值以模仿 DrDr 持续测试系统：忽略非模块，
       在单独进程中运行测试（除非指定了 @DFlag{thread} 或 @DFlag{direct}），
       使用与可用处理器一样多的作业（除非指定了 @DFlag{jobs}），
       将默认超时设置为 90 秒（除非指定了 @DFlag{timeout}），
       为每个测试创建新的 @envvar{PLTUSERHOME} 和 @envvar{TMPDIR}，
       将 stderr 输出计为测试失败，静默程序输出，提供空的程序输入，
       并打印结果表格。}

 @item{@Flag{s} @nonterm{name} 或 @DFlag{submodule} @nonterm{name}
       --- 要求使用子模块 @nonterm{name} 而不是 @racket[test]。
       提供 @Flag{s} 或 @DFlag{submodule} 以运行多个子模块，
       或将多个子模块与 @DFlag{first-avail} 结合使用以运行列表中第一个可用的模块。
       请注意，如果多次使用 @Flag{s} 但提供单个模块文件作为参数，
       默认模式仍然是 @DFlag{direct}（这可能意味着比 @DFlag{process}
       或 @DFlag{place} 模式更少的新模块实例化）。}

 @item{@Flag{r} 或 @DFlag{run-if-absent}
       --- 如果相关子模块不存在，则要求运行文件的顶层模块。这是默认模式。}

 @item{@Flag{x} 或 @DFlag{no-run-if-absent}
       --- 如果相关子模块不存在，则忽略该文件。}

 @item{@DFlag{first-avail}
       --- 当通过 @Flag{s} 或 @DFlag{submodule} 提供多个子模块名称时，
       仅运行第一个可用的子模块。}

@item{@DFlag{configure-runtime}
       --- 在运行模块或子模块之前，运行每个指定模块的
       @racketidfont{configure-runtime} 子模块（如果有的话）。
       当仅提供单个模块或指定了 @DFlag{process} 或 @DFlag{place} 模式时，
       此模式是默认的，除非通过 @Flag{s} 或 @DFlag{submodule} 提供了子模块名称。}

 @item{@DFlag{direct}
      --- 在单个线程中运行每个测试，使用单个命名空间的模块注册表加载所有测试。
      如果指定了单个文件，此模式是默认的。多个测试可能通过退出、使用会阻塞的
      unsafe 操作（从而阻止超时）等方式相互干扰并影响整体测试运行。}

 @item{@DFlag{process}
      --- 在单独的操作系统进程中运行每个测试。如果指定了多个文件、
      目录、集合或包，此模式是默认的。}

 @item{@DFlag{place}
      --- 在 @tech[#:doc '(lib
      "scribblings/reference/reference.scrbl")]{place} 中运行每个测试，
      而不是在操作系统进程中。}

 @item{@Flag{j} @nonterm{n} 或 @DFlag{jobs} @nonterm{n}
      --- 并行运行最多 @nonterm{n} 个测试文件。}

 @item{@DFlag{timeout} @nonterm{seconds}
      --- 将默认超时（之后测试被视为失败）设置为 @nonterm{seconds}。
      使用 @exec{+inf.0} 允许测试无限运行，但允许 @racket[timeout] 子子模块配置。
      如果任何测试因超时失败，@exec{raco test} 的退出状态为 2
      （而非仅非超时失败的 1 或成功的 0）。如果未通过 @DFlag{timeout}
      或 @DFlag{drdr} 指定，默认超时对应于 @exec{+inf.0}。}

 @item{@DFlag{fresh-user}
      --- 在单独进程中运行测试时，创建一个新目录并设置
      @envvar{PLTUSERHOME} 和 @envvar{TMPDIR}。还设置了
      @envvar{PLTADDONDIR} 环境变量，以便附加目录（即安装包的地方，
      例如）在每个测试进程中@emph{不}改变。}

 @item{@DFlag{empty-stdin}
       --- 为每个测试程序提供空的 stdin。}

 @item{@Flag{Q} 或 @DFlag{quiet-program}
       --- 抑制每个测试程序的输出。}

 @item{@Flag{e} 或 @DFlag{check-stderr}
       --- 将任何 stderr 输出计为测试失败。}

 @item{@DFlag{deps}
       --- 如果将参数视为包，还会检查包依赖关系。}

 @item{@DPFlag{ignore-stderr} @nonterm{pattern}
       --- 如果 stderr 输出与 @nonterm{pattern} 匹配，则不将其计为测试失败。
       此标志可以多次使用，只要 stderr 输出匹配任何一个 @nonterm{pattern}，
       就会被视为成功。}

 @item{@DFlag{errortrace}
       --- 在运行测试之前动态加载 @racketmodname[errortrace #:indirect]。
       注意，已编译的文件将不包含跟踪信息。}
 @item{@Flag{y} 或 @DFlag{make}
       --- 启用自动
        生成和更新编译后的 @filepath{.zo} 文件。
        具体来说，
        @racket[(make-compilation-manager-load/use-compiled-handler)]
        的结果被安装为 @racket[current-load/use-compiled] 的值
        在模块加载操作之前。}

 @item{@Flag{q} 或 @DFlag{quiet}
       --- 抑制进度信息、责任方和变化输出的输出（参见 @secref["test-responsible"]）。}

 @item{@DFlag{heartbeat}
       --- 定期报告测试在运行至少 5 秒后仍在运行。}

 @item{@DFlag{table} 或 @Flag{t}
       --- 在所有测试之后打印摘要表格。如果测试使用 @racketmodname[rackunit]，
       或者测试至少使用 @racket[test-log!] 从 @racketmodname[raco/testing]
       记录成功和失败，表格会根据日志报告测试和失败计数。}

 @item{@DPFlag{arg} @nonterm{argument}
       --- 将 @nonterm{argument} 添加到被调用测试模块的参数列表中，
       以便被调用模块在其 @racket[current-command-line-arguments] 中看到
       @nonterm{argument}。这些参数与 @filepath{info.rkt} 中由
       @racket[test-command-line-arguments] 指定的任何参数合并。}

 @item{@DPFlag{args} @nonterm{arguments}
        --- 与 @DPFlag{arg} 相同，但 @nonterm{arguments} 被视为要添加的
        以空白分隔的参数列表。要在典型 shell 中使用此标志指定多个参数，
        @nonterm{arguments} 必须用引号括起来。}

 @item{@DFlag{output} 或 @Flag{o} @nonterm{file}
       --- 将所有 stdout 和 stderr 输出保存到 @nonterm{file}。
       如果目标 @nonterm{file} 已存在，则会被覆盖。
 }
]

@history[#:changed "1.1" @elem{Added @DFlag{heartbeat}.}
         #:changed "1.4" @elem{Changed recognition of module suffixes to use @racket[get-module-suffixes],
                               which implies recognizing @filepath{.ss} and @filepath{.rkt}.}
         #:changed "1.5" @elem{Added @DPFlag{ignore-stderr}.}
         #:changed "1.6" @elem{Added @DPFlag{arg} and @DPFlag{args}.}
         #:changed "1.8" @elem{Added @DFlag{output} and @Flag{o}.}
         #:changed "1.11" @elem{Added @DFlag{make}/@Flag{y}.}
         #:changed "1.12" @elem{Added @DFlag{errortrace}.}]

@section[#:tag "test-config"]{Test Configuration by Submodule}

当 @exec{raco test} 在子模块中运行测试时，@racket[config] 子子模块可以为
运行测试提供额外配置。@racket[config] 子子模块应使用 @racketmodname[info]
模块语言来定义以下标识符：

@itemlist[

 @item{@indexed-racket[timeout] --- 以秒为单位的实数，用于覆盖测试的默认超时，
       仅在启用超时时适用。}

 @item{@indexed-racket[responsible] --- 字符串、符号或符号和字符串的列表，
       标识测试失败时应通知的责任方。参见 @secref["test-responsible"]。}

 @item{@indexed-racket[lock-name] --- 命名用于序列化测试的锁文件的字符串
       （即具有相同锁名称的测试不会并发运行）。锁文件的位置由
       @envvar{PLTLOCKDIR} 环境变量确定，或默认为
       @racket[(find-system-path 'temp-dir)]。等待锁文件的最长时间由
       @envvar{PLTLOCKTIME} 环境变量确定，或默认为 4 小时。}

 @item{@indexed-racket[ignore-stderr] --- 字符串、字节字符串或
       @tech[#:doc reference-doc]{regexp value}，作为导致错误输出在匹配
       模式时不被视为失败的模式。}

 @item{@indexed-racket[random?] --- 如果为真，表示测试的输出预期会变化。
       参见 @secref["test-responsible"]。}

]

为了防止文件被求值用于测试，创建一个不执行任何测试且不触发封闭模块求值的
子模块就足够了。因此，例如，文件可能如下所示：

@#reader scribble/comment-reader
 (racketmod
  racket

  (/ 1 0)

  ;; 不要运行此文件进行测试：
  (module test racket/base)
 )

@history[#:changed "1.5" @elem{Added @racket[ignore-stderr] support.}]

@section[#:tag "test-config-info"]{Test Configuration by @filepath{info.rkt}}

基于子模块的测试配置是首选（参见 @secref["test-config"]）。特别是，
为了防止 @exec{raco test} 运行特定文件，通常文件应包含一个不执行任何操作的子模块。

然而，在某些情况下，添加子模块不方便或不可能（例如，因为文件不会总是编译）。
因此，@exec{raco test} 还会查阅候选测试文件目录中的任何 @filepath{info.rkt} 文件。
对于集合内的文件，还会查阅任何封闭集合目录中的 @filepath{info.rkt} 文件以获取
@racket[test-omit-paths] 和 @racket[test-include-paths]。最后，对于包内的文件，
会查阅包的 @filepath{info.rkt} 以获取 @racket[pkg-authors] 来设置包中所有文件的
默认责任方（参见 @secref["test-responsible"]）。

以下 @filepath{info.rkt} 字段被识别：

@itemlist[

 @item{@indexed-racket[test-omit-paths] --- 路径字符串列表（相对于封闭目录）
       和 regexp 值（以省略封闭目录内匹配表达式的所有文件），
       或 @racket['all] 以省略封闭目录内的所有文件。当路径字符串指向目录时，
       目录内的所有文件都会被省略。}

 @item{@indexed-racket[test-include-paths] --- 路径字符串列表（相对于封闭目录）
       和 regexp 值（以包含封闭目录内匹配表达式的所有文件），
       或 @racket['all] 以包含封闭目录内的所有文件。当路径字符串指向目录时，
       目录内的所有文件都会被包含。}
      
 @item{@indexed-racket[test-command-line-arguments] ---
       @racket[(list _module-path-string (list _argument-path-string
       ...))] 的列表，其中 @racket[current-command-line-arguments] 被设置为
       包含 @racket[_argument-path-string] 的向量当运行 @racket[_module-path-string] 时。}

 @item{@indexed-racket[test-timeouts] --- @racket[(list
       _module-path-string _real-number)] 的列表，用于覆盖
       @racket[_module-path-string] 的默认超时（秒）。}

 @item{@indexed-racket[test-responsibles] --- @racket[(list
       _module-path-string _party)] 或 @racket[(list 'all _party)] 的列表，
       用于覆盖 @racket[_module-path-string] 或目录内所有文件的默认责任方
       （除非被覆盖）。每个 @racket[_party] 是字符串、符号或符号和字符串的列表。
       参见 @secref["test-responsible"]。}

 @item{@indexed-racket[test-lock-names] --- @racket[(list
       _module-path-string _lock-string)] 的列表，用于为
       @racket[_module-path-string] 声明锁文件名。参见 @secref["test-config"]
       中的 @racket[lock-name]。}

 @item{@indexed-racket[test-ignore-stderrs] --- @racket[(list
       _module-path-string _pattern)] 或 @racket[(list 'all _pattern)] 的列表，
       用于声明允许 @racket[_module-path-string] 或目录内所有文件的
       标准错误输出模式为非失败。每个 @racket[_pattern] 必须是字符串、
       字节字符串或 @tech[#:doc reference-doc]{regexp value}。参见
       @secref["test-config"] 中的 @racket[ignore-stderr]。}

 @item{@indexed-racket[test-randoms] --- 路径字符串列表（相对于封闭目录），
       用于输出变化的模块。参见 @secref["test-responsible"]。}

 @item{@racket[module-suffixes] 和 @racket[doc-module-suffixes] ---
       通过 @racket[get-module-suffixes] 间接使用。}

]

@history[#:changed "1.5" @elem{Added @racket[test-ignore-stderrs] support.}]

@section[#:tag "test-responsible"]{Responsible-Party and Varying-Output Logging}

当测试有声明责任方时，测试的输出会加上前缀：

@verbatim[#:indent 2]{raco test:@nonterm{which} @"@"(test-responsible '@nonterm{responsible})}

行，其中 @nonterm{which} 是一个空格后跟一个精确的非负数，
表示启用并行时的并行任务（否则为空），@nonterm{responsible} 是字符串、
符号或列表数据。

当测试的输出（写入 stdout 的）预期在不同运行之间变化时——除了与 @racket[time]
产生的形式相同的输出外——应将其声明为变化。在这种情况下，测试的输出会加上前缀：

@verbatim[#:indent 2]{raco test:@nonterm{which} @"@"(test-random #t)}

line.

@section{Logging Test Results}
@defmodule[raco/testing]

此模块提供了一个用于跟踪测试结果和显示摘要消息的通用库。
@exec{raco test} 命令使用此库来显示测试结果。因此，任何想要与
@exec{raco test} 集成的测试框架也应使用此库来记录测试结果。

@history[#:added "1.13"]

@defproc[(test-log! [result any/c]) void?]{
 Adds a test result to the running log. If @racket[result] is false,
 then the test is considered a failure.}

@defproc[(test-report [#:display? display? any/c #f]
                      [#:exit? exit? any/c #f])
         (cons/c exact-nonnegative-integer?
                 exact-nonnegative-integer?)]{
 Processes the running test log. The first integer is the failed tests, the
 second is the total tests. If @racket[display?] is true, then a message is
 displayed. If there were failures, the message is printed on
 @racket[(current-error-port)]. If @racket[exit?] is true, then if there were
 failures, calls @racket[(exit 1)].}

@defboolparam[test-log-enabled? enabled? #:value #t]{
 When set to @racket[#f], @racket[test-log!] is a no-op. This is useful to
 dynamically disable certain tests whose failures are expected and shouldn't be
 counted in the test log, such as when testing a custom check's failure
 behavior.}

@defparam*[current-test-invocation-directory
            path
            (or/c #f path-string?)
            (or/c #f path?)
            #:value #f]{
包含测试被调用的目录，@emph{例如}，@exec{raco test}。当测试运行器
在调用特定测试文件之前更改目录时，这可能与 @racket[current-directory] 不同，
应由测试运行器设置以反映它们最初被调用的目录。

测试报告应使用此来显示适当的路径名。

@history[#:added "1.14"]
}

