#lang scribble/doc
@(require "mz.rkt" scribble/bnf)

@title[#:tag "pretty-print"]{美化打印}

@note-lib[racket/pretty]

@defproc[(pretty-print [v any/c] [port output-port? (current-output-port)]
                       [quote-depth (or/c 0 1) 0]
                       [#:newline? newline? boolean? #t])
         void?]{

使用与默认 @racket[print] 模式相同的打印形式来美化打印值 @racket[v]，但会插入换行和空白以避免行长度超过 @racket[(pretty-print-columns)]，具体由 @racket[(pretty-print-current-style-table)] 控制。打印形式默认以换行结尾，除非 @racket[newline?] 参数为 false 或 @racket[pretty-print-columns] 参数设为 @racket['infinity]。当 @racket[port] 启用了行计数时（参见 @secref["linecol"]），打印会对起始列敏感——既用于确定初始换行，也用于缩进后续行。

除了本节中定义的参数外，@racket[pretty-print] 还遵循 @racket[print-graph]、@racket[print-struct]、@racket[print-hash-table]、@racket[print-vector-length]、@racket[print-box] 和 @racket[print-as-expression] 参数。

美化打印器会检测具有 @racket[prop:custom-write] property 的 struct，并调用相应的 custom-write 过程。custom-write 过程可以检查 @racket[pretty-printing] 参数来与美化打印器协作。到 port 的递归打印自动使用美化打印，但如果 struct 有多个递归打印的子表达式，custom-write 过程可能需要更深入地协作以插入显式换行。使用 @racket[port-next-location] 确定当前输出列，使用 @racket[pretty-print-columns] 确定目标打印宽度，使用 @racket[pretty-print-newline] 插入换行（以便正确调用 @racket[pretty-print-print-line] 参数中的函数）。使用 @racket[make-tentative-pretty-print-output-port] 获取用于试探性递归打印的 port（例如检查输出长度）。

如果省略 @racket[newline?] 参数或其为 true，则在打印完值的最后一个换行后，@racket[pretty-print-print-line] 回调会以 false 作为第一个参数被调用。如果 @racket[newline?] 为 false，则在打印完值后不调用 @racket[pretty-print-print-line] 回调。

@history[#:changed "6.6.0.3" @elem{Added @racket[newline?] argument.}]
}

@defproc[(pretty-write [v any/c] [port output-port? (current-output-port)]
                       [#:newline? newline? boolean? #t])
         void?]{

与 @racket[pretty-print] 相同，但 @racket[v] 的打印方式类似于 @racket[write] 而非 @racket[print]。

@history[#:changed "6.6.0.3" @elem{Added @racket[newline?] argument.}]
}

@defproc[(pretty-display [v any/c] [port output-port? (current-output-port)]
                         [#:newline? newline? boolean? #t])
         void?]{

与 @racket[pretty-print] 相同，但 @racket[v] 的打印方式类似于 @racket[display] 而非 @racket[print]。

@history[#:changed "6.6.0.3" @elem{Added @racket[newline?] argument.}]
}


@defproc[(pretty-format [v any/c] [columns exact-nonnegative-integer? (pretty-print-columns)]
                        [#:mode mode (or/c 'print 'write 'display) 'print])
         string?]{

类似于 @racket[pretty-print]，但返回包含美化打印值的字符串，而不是将输出发送到 port。

可选参数 @racket[columns] 用于参数化 @racket[pretty-print-columns]。

关键字参数 @racket[mode] 控制打印方式：@racket[pretty-print]（默认）、@racket[pretty-write] 或 @racket[pretty-display]。

@history[#:changed "6.3" @elem{Added a @racket[mode] argument.}]}


@defproc[(pretty-print-handler [v any/c]) void?]{

如果 @racket[v] 不是 @|void-const|，则美化打印 @racket[v]；如果 @racket[v] 是 @|void-const|，则不打印任何内容。将此过程传递给 @racket[current-print] 以将美化打印器安装到由 @racket[read-eval-print-loop] 运行的 REPL 中。}


@; ----------------------------------------------------------------------

基本美化打印选项

@defparam[pretty-print-columns width (or/c exact-positive-integer? 'infinity)]{

决定美化打印默认宽度的 @tech{parameter}。

如果显示宽度为 @racket['infinity]，则美化打印输出不会断行，也不会在末尾添加换行。}


@defparam[pretty-print-depth depth (or/c exact-nonnegative-integer? #f)]{

控制递归美化打印默认深度的参数。打印到 @racket[depth] 深度意味着嵌套超过 @racket[depth] 的元素被替换为“...”；特别地，@racket[0] 表示只打印简单值。@racket[#f]（默认值）允许打印任意深度。}


@defboolparam[pretty-print-exact-as-decimal as-decimal?]{

决定如何打印精确非整数的 @tech{parameter}。如果参数值为 @racket[#t]，则具有小数表示的精确非整数将打印为小数而不是分数。初始值为 @racket[#f]。}

@defboolparam[pretty-print-.-symbol-without-bars on?]{

控制打印 symbol 名称仅为句点的 @tech{parameter}。如果设为真值，则该 symbol 仅打印为句点。如果设为假值，则打印为带竖线包围的句点。}


@defboolparam[pretty-print-show-inexactness show?]{

决定如何打印不精确数的 @tech{parameter}。如果参数值为 @racket[#t]，则不精确数总是打印为带前导 @litchar{#i} 的形式。初始值为 @racket[#f]。}

@; ----------------------------------------------------------------------

按 Symbol 特殊打印


@defboolparam[pretty-print-abbreviate-read-macros abbrev?]{

A @tech{parameter} that controls whether or not @racketidfont{quote},
@racketidfont{unquote}, @racketidfont{unquote-splicing}, @|etc|, are
abbreviated with @litchar{'}, @litchar{,}, @litchar[",@"], etc. 
By default, the abbreviations are enabled.

See also @racket[pretty-print-remap-stylable].
}


@defproc[(pretty-print-style-table? [v any/c]) boolean?]{

如果 @racket[v] 是用于 @racket[pretty-print-current-style-table] 的 style table，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defparam[pretty-print-current-style-table style-table pretty-print-style-table?]{

保存 style 映射表的 @tech{parameter}。参见 @racket[pretty-print-extend-style-table]。}


@defproc[(pretty-print-extend-style-table [style-table pretty-print-style-table?]
                                          [symbol-list (listof symbol?)]
                                          [like-symbol-list (listof symbol?)])
         pretty-print-style-table?]{

通过扩展现有的 @racket[style-table] 创建新的 style table，使原始表中 @racket[like-symbol-list] 每个 symbol 的 style 映射用于新表中对应的 @racket[symbol-list] symbol。@racket[symbol-list] 和 @racket[like-symbol-list] 必须具有相同长度。@racket[style-table] 参数可以为 @racket[#f]，此时使用原始表的默认映射（见下文）。

symbol 的 style 映射控制打印以该 symbol 开头的 list 时插入空白的方式。在没有任何映射的情况下，当 list 跨多行断开时，list 的每个元素打印在单独一行，每行具有相同的缩进。

默认 style 映射包括以下 symbol 的映射，使输出遵循流行的代码格式化规则：

@racketblock[
'lambda 'λ 'case-lambda
'define 'define-macro 'define-syntax
'let 'letrec 'let*
'let-syntax 'letrec-syntax
'let-values 'letrec-values 'let*-values
'let-syntaxes 'letrec-syntaxes
'begin 'begin0 'do
'if 'set! 'set!-values
'unless 'when
'cond 'case 'and 'or
'module
'syntax-rules 'syntax-case 'letrec-syntaxes+values
'import 'export 'link
'require 'require-for-syntax 'require-for-template 'provide
'public 'private 'override 'rename 'inherit 'field 'init
'shared 'send 'class 'instantiate 'make-object
]}


@defparam[pretty-print-remap-stylable
          proc 
          (any/c . -> . (or/c symbol? #f))]{

控制 style 重映射和 reader 缩写确定的 @tech{parameter}。

此过程以序列中作为第一个元素出现的每个子表达式调用。如果返回 symbol，则使用 style table，如同该 symbol 位于序列头部。如果返回 @racket[#f]，则正常处理 style table。同样，在确定是否缩写 reader macro 时，会参考此参数。
}


@; ----------------------------------------------------------------------

行输出 Hook

@defproc[(pretty-print-newline [port output-port?] [width exact-nonnegative-integer?]) void?]{

如果 @racket[port] 是重定向到原始输出端口的输出端口，则调用与 @racket[pretty-print-print-line] 参数关联的过程向 @racket[port] 打印换行，否则向 @racket[port] 打印普通换行。@racket[width] 参数应为目标列宽，通常从 @racket[pretty-print-columns] 获取。}


@defparam[pretty-print-print-line proc
          ((or/c exact-nonnegative-integer? #f)
           output-port?
           exact-nonnegative-integer?
           (or/c exact-nonnegative-integer? 'infinity)
           . -> .
           exact-nonnegative-integer?)]{

确定美化打印值行间换行分隔符打印过程的 @tech{parameter}。该过程以四个参数调用：新行号、输出端口、旧行长度和目标列数。@racket[proc] 的返回值是它在行首打印的额外字符数。

在打印任何字符之前，先以 @racket[0] 作为行号和旧行长度调用 @racket[proc] 过程。每当美化打印器开始新行时，以新的行号（第一行新行编号为 @racket[1]）和刚完成的行长度调用 @racket[proc]。@racket[proc] 的 destination-columns 参数始终是目标打印区域的总宽度，或者如果美化打印值不断行，则为 @racket['infinity]。

如果省略 @racket[#:newline?] 参数或提供了真值，则在值的最后一个字符打印完成后，以 @racket[#f] 作为行号和最后一行的长度调用 @racket[proc]。

默认的 @racket[proc] 过程在行号不是 @racket[0] 且列数不是 @racket['infinity] 时打印换行，始终返回 @racket[0]。自定义 @racket[proc] 过程可用于在每行美化打印输出前打印额外文本；@racket[proc] 应返回每行前打印的字符数，以便正确选择下一行断行。

提供给 @racket[proc] 的目标端口通常不是提供给 @racket[pretty-print] 或 @racket[pretty-display] 的端口（或当前输出端口），但对此端口的输出最终会重定向到提供给 @racket[pretty-print] 或 @racket[pretty-display] 的端口。}


@; ----------------------------------------------------------------------

值输出 Hook


@defparam[pretty-print-size-hook proc
          (any/c boolean? output-port?
           . -> . 
           (or/c #f exact-nonnegative-integer?))]{

确定美化打印 sizing hook 的 @tech{parameter}。

sizing hook 应用于每个要打印的值。如果 hook 返回 @racket[#f]，则由美化打印器内部处理打印。否则，该值应为指定打印值字符长度的整数；将调用 print hook 来实际打印倸（参见 @racket[pretty-print-print-hook]）。

sizing hook 接收三个参数。第一个参数是要打印的值。第二个参数是布尔值：@racket[#t] 表示类似 @racket[display] 的打印，@racket[#f] 表示类似 @racket[write] 的打印。第三个参数是目标端口；该端口是提供给 @racket[pretty-print] 或 @racket[pretty-display] 的端口（或当前输出端口）。sizing hook 可能在美化打印期间多次应用于单个值。}


@defparam[pretty-print-print-hook proc
          (any/c boolean? output-port? . -> . void?)]{

确定美化打印 print hook 的 @tech{parameter}。当 sizing hook（参见 @racket[pretty-print-size-hook]）为值返回整数大小时，print-hook 过程应用于要打印的值。

print hook 接收三个参数。第一个参数是要打印的值。第二个参数是布尔值：@racket[#t] 表示类似 @racket[display] 的打印，@racket[#f] 表示类似 @racket[write] 的打印。第三个参数是目标端口；此端口通常不是提供给 @racket[pretty-print] 或 @racket[pretty-display] 的端口（或当前输出端口），但对此端口的输出最终会重定向到提供给 @racket[pretty-print] 或 @racket[pretty-display] 的端口。}


@defparam[pretty-print-pre-print-hook proc
          (any/c output-port? . -> . void)]{

确定在对象即将打印前调用的 hook 过程的 @tech{parameter}。hook 接收两个参数：对象和输出端口。该端口是提供给 @racket[pretty-print] 或 @racket[pretty-display] 的端口（或当前输出端口）。}


@defparam[pretty-print-post-print-hook proc
          (any/c output-port? . -> . void)]{

确定在对象打印完成后调用的 hook 过程的 @tech{parameter}。hook 接收两个参数：对象和输出端口。该端口是提供给 @racket[pretty-print] 或 @racket[pretty-display] 的端口（或当前输出端口）。}

@; ----------------------------------------------------------------------

附加自定义输出支持

@defboolparam[pretty-printing on?]{

当美化打印器以支持换行的模式调用 custom-write 过程（参见 @racket[prop:custom-write]）进行输出时，此 @tech{parameter} 设为 @racket[#t]。当美化打印器仅为了检测循环或尝试在单行上打印而调用 custom-write 过程时，将此参数设为 @racket[#f]。}


@defproc[(make-tentative-pretty-print-output-port 
          [out output-port?]
          [width exact-nonnegative-integer?]
          [overflow-thunk (-> any)])
         output-port?]{

生成适用于递归美化打印但不实际产生输出的端口。当正确的输出取决于递归打印的大小时，使用此类端口进行试探性打印。打印后，使用 @racket[file-position] 确定试探性输出的大小。

@racket[out] 参数应为美化打印端口，例如当 @racket[pretty-printing] 设为 true 时提供给 custom-write 过程的端口，或另一个试探性输出端口。@racket[width] 参数应为目标列宽，通常从 @racket[pretty-print-columns] 获取，可能递减以为终止符留出空间。如果向端口打印了超过 @racket[width] 个项，或如果通过 @racket[pretty-print-newline] 向端口打印了换行，则调用 @racket[overflow-thunk] 过程；它可以通过 continuation 作为快捷方式从递归打印中逃逸，但 @racket[overflow-thunk] 也可以返回，在这种情况下，每次后续向端口写入额外输出时都会调用它。

试探性打印后，使用 @racket[tentative-pretty-print-port-transfer] 接受结果或使用 @racket[tentative-pretty-print-port-cancel] 拒绝结果。未能正确接受或取消会干扰 graph 结构打印、hook 过程调用等。即使 @racket[overflow-thunk] 从递归打印中逃逸，也要显式取消试探性打印。}

 
@defproc[(tentative-pretty-print-port-transfer 
          [tentative-out output-port?] [orig-out output-port?])
         void?]{

使写入 @racket[tentative-out] 的数据如同写入 @racket[orig-out] 一样被传输。@racket[tentative-out] 参数应为 @racket[make-tentative-pretty-print-output-port] 生成的端口，@racket[orig-out] 应为美化打印端口（提供给 custom-write 过程）或另一个试探性输出端口。}


@defproc[(tentative-pretty-print-port-cancel [tentative-out output-port?]) void?]{

取消 @racket[tentative-out] 的内容，该内容由 @racket[make-tentative-pretty-print-output-port] 生成。取消的主要效果是撤销 graph-reference 定义，使得将来打印 graph-referenced 对象时包含定义 @litchar{#}@nonterm{n}@litchar{=}。}
