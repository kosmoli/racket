#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/cmdline)
          (only-in scribble/core element))

@title{命令行解析}

@note-lib[racket/cmdline]

@defform/subs[#:literals (multi once-each once-any final args help-labels =>)
              (command-line optional-name-expr optional-argv-expr
                            flag-clause ...
                            finish-clause)
              ([optional-name-expr code:blank
                                   (code:line #:program name-expr)]
               [optional-argv-expr code:blank
                                   (code:line #:argv argv-expr)]
               [flag-clause (code:line #:multi flag-spec ...)
                            (code:line #:once-each flag-spec ...)
                            (code:line #:once-any flag-spec ...)
                            (code:line #:final flag-spec ...)
                            (code:line #:usage-help string ...)
                            (code:line #:help-labels string ...)
                            (code:line #:ps string ...)]
                [flag-spec (flags id ... help-spec body ...)
                           (flags => handler-expr help-expr)]
                [flags flag-string
                       (flag-string ...+)]
                [help-spec string
                           (string-expr ...+)]
                [finish-clause code:blank
                               (code:line #:args arg-formals body ...)
                               (code:line #:handlers handlers-exprs)]
                [arg-formals rest-id
                             (arg ...)
                             (arg ...+ . rest-id)]
                [arg id
                     [id default-expr]]
                [handlers-exprs (code:line finish-expr arg-strings-expr)
                                (code:line finish-expr arg-strings-expr help-expr)
                                (code:line finish-expr arg-strings-expr help-expr
                                           unknown-expr)])]{

根据 @racket[flag-clause] 中的规范解析命令行。

如果提供了 @racket[name-expr]，它应生成一个路径或字符串，用于在命令行格式错误时作为程序名称报告错误。它默认为 @racket[(find-system-path 'run-file)]。当提供路径时，仅使用路径的最后一个元素来报告错误。

如果提供了 @racket[argv-expr]，它必须评估为字符串列表或向量。它默认为 @racket[(current-command-line-arguments)]。

命令行被拆解为标志（每个标志可能有标志特定参数）后跟（非标志）参数。以 @litchar{-} 或 @litchar{+} 开头的命令行字符串被解析为标志，但标志的参数永远不会被解析为标志，以 @litchar{-} 或 @litchar{+} 开头的整数和十进制数字不被视为标志。命令行中的非标志参数必须出现在所有标志及其参数之后。第一个非标志参数之后的任何命令行字符串都不会被解析为标志。内置的 @Flag{-} 标志表示命令行标志的结束；@Flag{-} 标志之后的任何命令行字符串都被解析为非标志参数。

@racket[#:multi]、@racket[#:once-each]、@racket[#:once-any] 或 @racket[#:final] 子句引入一组命令行标志规范。子句标签指示标志可以在命令行上出现的次数：

@itemize[

 @item{@racket[#:multi] --- 集合中指定的每个标志可以在命令行上出现任意次数；即集合中的标志是独立的，每个标志可以使用多次。}

 @item{@racket[#:once-each] --- 集合中指定的每个标志可以在命令行上出现一次；即集合中的标志是独立的，但每个标志最多应指定一次。如果标志规范在命令行中出现多次，则 @exnraise[exn:fail]。}

 @item{@racket[#:once-any] --- 集合中指定的只有一个标志可以在命令行上出现；即集合中的标志是互斥的。如果集合在命令行中出现多次，则 @exnraise[exn:fail]。}

 @item{@racket[#:final] --- 类似于 @racket[#:multi]，但标志之后的任何参数都不被视为标志。注意，如果 @racket[#:final] 标志有短名称，则可以指定多个；例如，如果 @Flag{a} 是 @racket[#:final] 标志，则 @Flag{aa} 在单个命令行参数中组合了两个 @Flag{a} 实例。}

]

正常的标志规范有四个部分：

@itemize[

 @item{@racket[flags] --- 标志字符串或标志字符串集合。如果提供了一组标志，则所有标志都是等效的。每个标志字符串必须为 @racketvalfont{"-}@racketvarfont{x}@racketvalfont{"} 或 @racketvalfont{"+}@racketvarfont{x}@racketvalfont{"} 形式，其中字符为 @racketvarfont{x}，或为 @racketvarfont[@element[#f]{"--}]@racketvarfont{x}@racketvalfont{"} 或 @racketvarfont{"++}@racketvarfont{x}@racketvalfont{"} 形式，其中字符序列为 @racketvarfont{x}。@racketvarfont{x} 不能仅包含数字或数字加单个小数点，因为简单（有符号）数字不被视为标志。此外，标志 @racket["--"]、@racket["-h"] 和 @racket["--help"] 是预定义的，不能更改。}

 @item{@racket[id]s --- 绑定到标志参数的标识符。标识符的数量确定可以在命令行上为该标志提供的参数数量，这些标识符的名称将出现在描述标志的帮助消息中。@racket[id]s 在用于处理标志的 @racket[body]s 中绑定到字符串值。}

 @item{@racket[help-spec] --- 描述标志的字符串或字符串序列。此字符串由内置 @Flag{h}（或 @DFlag{help}）标志的处理程序生成的帮助消息中使用。可以提供单个字面字符串，或任意数量的生成字符串的表达式；在后一种情况下，第一个字符串之后的字符串显示在后续行上。}

 @item{@racket[body]s --- 当 @racket[flags] 之一出现在命令行上时评估的表达式。标志从左到右解析，每个 @racket[body]s 序列在遇到相应标志时评估。当评估 @racket[body]s 时，前面的 @racket[id]s 绑定到命令行上为该标志提供的参数。}

]

使用 @racket[=>] 的标志规范转义到更通用的指定处理程序和帮助字符串的方法。在这种情况下，@racket[handler-expr] 和 @racket[help-expr] 返回的处理程序过程和帮助字符串列表用作 @racket[parse-command-line] 的 @racket[_table] 参数。

@racket[#:usage-help] 子句在用例行之后立即插入文本行。子句中的每个字符串提供单独一行文本。

@racket[#:help-labels] 子句将文本行插入命令行标志的帮助表中。子句中的每个字符串提供单独一行文本。

@racket[#:ps] 子句在帮助输出末尾插入文本行。子句中的每个字符串提供单独一行文本。

在标志子句之后，最终子句处理未解析为标志的命令行参数：

@itemize[

 @item{不提供最终子句等同于提供 @racket[#:args () (void)]。}

 @item{对于 @racket[#:args] 最终子句，@racket[arg-formals] 中的标识符绑定到剩余的命令行字符串，方式与 @racket[lambda] 表达式中标识符的绑定方式相同。因此，指定单个 @racket[id]（不带括号）将所有剩余参数收集到列表中。@racket[arg-formals] 规范的有效 arity 确定用户可以提供的额外命令行参数数量，@racket[arg-formals] 中标识符的名称用于帮助字符串。当解析命令行时，如果提供的参数数量无法匹配 @racket[arg-formals] 中的标识符，则 @exnraise[exn:fail]。否则，@racket[args] 子句的 @racket[body]s 被评估以处理剩余参数，最后一个 @racket[body] 的结果是 @racket[command-line] 表达式的结果。}

 @item{@racket[#:handlers] 最终子句转义到更通用的处理剩余参数的方法。在这种情况下，表达式的值用作 @racket[parse-command-line] 的最后两到四个参数。}

]

示例：

@racketblock[
(define verbose-mode (make-parameter #f))
(define profiling-on (make-parameter #f))
(define optimize-level (make-parameter 0))
(define link-flags (make-parameter null))

(define file-to-compile
  (command-line
   #:program "compiler"
   #:once-each
   [("-v" "--verbose") "Compile with verbose messages"
                       (verbose-mode #t)]
   [("-p" "--profile") "Compile with profiling"
                       (profiling-on #t)]
   #:once-any
   [("-o" "--optimize-1") "Compile with optimization level 1"
                          (optimize-level 1)]
   ["--optimize-2"        ((code:comment @#,t{show help on separate lines})
                           "Compile with optimization level 2,"
                           "which includes all of level 1")
                          (optimize-level 2)]
   #:multi
   [("-l" "--link-flags") lf (code:comment @#,t{flag takes one argument})
                          "Add a flag <lf> for the linker"
                          (link-flags (cons lf (link-flags)))]
   #:args (filename) (code:comment @#,t{expect one command-line argument: <filename>})
   (code:comment @#,t{return the argument as a filename to compile})
   filename))
]}

@; ----------------------------------------------------------------------

@defproc[(parse-command-line [name (or/c string? path?)]
                             [argv (or/c (listof string?) (vectorof string?))]
                             [table (listof (cons/c symbol? list?))]
                             [finish-proc (list? any/c ... . -> . any)]
                             [arg-help-strs (listof string?)]
                             [help-proc (string? . -> . any) (lambda (str) ....)]
                             [unknown-proc (string? . -> . any) (lambda (str) ...)])
         any]{

使用 @racket[table] 中的规范解析命令行。有关命令行解析的概述，参见 @racket[command-line] 形式，它为大多数目的提供了更方便的表示法。

此过程形式的 @racket[table] 参数编码 @racket[command-line] 子句中的信息，除了 @racket[args] 子句。相反，参数由 @racket[finish-proc] 过程处理，非标志参数的帮助信息在 @racket[arg-help-strs] 中提供。此外，@racket[finish-proc] 过程接收解析标志时累积的信息。@racket[help-proc] 和 @racket[unknown-proc] 参数允许无法通过 @racket[command-line] 实现的自定义。

当没有更多标志时，@racket[finish-proc] 调用时接收为命令行标志累积的信息列表（见下文）和命令行中剩余的非标志参数。@racket[finish-proc] 的 arity 确定接受和要求的非标志参数数量。例如，如果 @racket[finish-proc] 接受两或三个参数，则命令行上必须提供一或两个非标志参数。@racket[finish-proc] 过程可以有任何 arity（参见 @racket[procedure-arity]），除了 @racket[0] 或 @racket[0] 的列表（即过程必须至少接受一个或多个参数）。

@racket[arg-help-strs] 参数是标识预期（非标志）命令行参数的字符串列表，每个参数一个。如果允许任意数量的参数，@racket[arg-help-strs] 中的最后一个字符串代表所有这些参数。

@racket[help-proc] 过程在命令行包含 @Flag{h} 或 @DFlag{help} 标志时调用帮助字符串。如果遇到未知标志，则 @racket[unknown-proc] 过程调用，就像标志处理过程一样（如下所述）；它必须至少接受一个参数（未知标志），但也可以接受更多参数。默认 @racket[help-proc] 显示字符串并退出，默认 @racket[unknown-proc] 引发 @racket[exn:fail] 异常。

@racket[table] 是标志规范集合的列表。每个集合表示为两个项目的对：模式符号和帮助字符串列表或标志规格列表。模式符号是 @racket['once-each]、@racket['once-any]、@racket['multi]、@racket['final]、@racket['help-labels]、@racket['usage-help] 或 @racket['ps] 之一，与 @racket[command-line] 中的相应子句标签含义相同。对于 @racket['help-labels]、@racket['usage-help] 或 @racket['ps] 模式，提供帮助字符串列表。对于其他模式，提供标志规格列表，其中每个规格将多个标志映射到单个处理程序过程。规格是三个项目的列表：

@itemize[

 @item{规格定义的标志字符串列表。参见 @racket[command-line] 了解标志字符串的格式信息。}

 @item{当在命令行上找到标志时处理标志及其参数的过程。此处理程序过程的 arity 确定标志消耗的参数数量：处理程序过程调用时传入标志字符串加上命令行中接下来的几个参数，以匹配处理程序过程的 arity。处理程序过程必须至少接受一个参数以接收标志。如果处理程序接受任意多个参数，则所有剩余参数传递给处理程序。处理程序过程的 arity 必须是数字或 @racket[arity-at-least] 值。

 处理程序的返回值添加到最终传递给 @racket[finish-proc] 的列表中。如果处理程序返回 @|void-const|，则不向此列表添加任何值。对于处理程序返回的所有非 @|void-const| 值，列表中值的顺序与命令行上参数的顺序相同。}

 @item{用于为规格构造帮助信息的非空列表。列表的第一个元素描述标志；它可以是字符串或非空字符串列表，在后一种情况下，每个字符串显示在单独一行上。主列表的其他元素必须是命名标志预期参数的字符串。规格提供的额外帮助字符串数量必须与规格处理程序过程接受的参数数量匹配。}

]

以下示例是与 @racket[command-line] 的核心示例相同，转换为过程形式：

@racketblock[
(parse-command-line "compile" (current-command-line-arguments)
  `((once-each
     [("-v" "--verbose")
      ,(lambda (flag) (verbose-mode #t))
      ("Compile with verbose messages")]
     [("-p" "--profile")
      ,(lambda (flag) (profiling-on #t))
      ("Compile with profiling")])
    (once-any
     [("-o" "--optimize-1")
      ,(lambda (flag) (optimize-level 1))
      ("Compile with optimization level 1")]
     [("--optimize-2")
      ,(lambda (flag) (optimize-level 2))
      (("Compile with optimization level 2,"
        "which implies all optimizations of level 1"))])
    (multi
     [("-l" "--link-flags")
      ,(lambda (flag lf) (link-flags (cons lf (link-flags))))
      ("Add a flag <lf> for the linker" "lf")]))
   (lambda (flag-accum file) file)
   '("filename"))
]}
