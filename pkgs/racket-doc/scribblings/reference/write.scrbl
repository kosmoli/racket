#lang scribble/doc
@(require scribble/bnf "mz.rkt")

@(define (FmtMark . s) (apply litchar "~" s))

@title{Writing}

@defproc[(write [datum any/c] [out output-port? (current-output-port)])
         void?]{

将 @racket[datum] 写入 @racket[out]，通常以可以将 core datatypes 的实例读回的方式。如果 @racket[out] 有通过 @racket[port-write-handler] 关联到它的 handler，则调用该 handler。否则，使用 @seclink["printing"]{default printer}（以 @racket[write] 模式），由各种参数配置有关。

关于 default printer 的更多信息，参见 @secref["printing"]。特别地，注意 @racket[write] 可能需要与正在打印值的深度成比例的内存，因为需要进行初始循环检查。

@examples[
(write 'hi)
(write (lambda (n) n))
(define o (open-output-string))
(write "hello" o)
(get-output-string o)
]}

@defproc[(display [datum any/c] [out output-port? (current-output-port)])
         void?]{

将 @racket[datum] 显示到 @racket[out]，类似于 @racket[write]，但通常以 byte- 和 character-based datatypes 作为原始 bytes 或 characters 写入的方式。如果 @racket[out] 有通过 @racket[port-display-handler] 关联到它的 handler，则调用该 handler。否则，使用 @seclink["printing"]{default printer}（以 @racket[display] 模式），由各种参数配置。

关于 default printer 的更多信息，参见 @secref["printing"]。特别地，注意 @racket[display] 可能需要与正在打印值的深度成比例的内存，因为需要进行初始循环检查。}

@defproc[(print [datum any/c] [out output-port? (current-output-port)]
                [quote-depth (or/c 0 1) 0])
         void?]{

将 @racket[datum] 打印到 @racket[out]。如果 @racket[out] 有通过 @racket[port-print-handler] 关联到它的 handler，则调用该 handler。否则，调用由 @racket[global-port-print-handler] 指定的 handler；默认 handler 使用 @seclink["printing"]{default printer}（以 @racket[print] 模式）。

可选的 @racket[quote-depth] 参数在 @racket[print-as-expression] 参数设置为 @racket[#t] 时调整打印。在这种情况下，@racket[quote-depth] 指定打印 @racket[datum] 的起始 quote 深度。

提供 @racket[print] 的理由是 @racket[display] 和 @racket[write] 都有特定的输出约定，这些约定限制了环境改变 @racket[display] 和 @racket[write] 过程行为的方式。对于 @racket[print] 不应假设任何输出约定，以便环境可以自由地以任何方式修改 @racket[print] 生成的实际输出。}

@defproc[(writeln [datum any/c] [out output-port? (current-output-port)])
         void?]{

与 @racket[(write datum out)] 后跟 @racket[(newline out)] 相同。

@history[#:added "6.1.1.8"]}


@defproc[(displayln [datum any/c] [out output-port? (current-output-port)])
         void?]{

与 @racket[(display datum out)] 后跟 @racket[(newline out)] 相同，
这类似于 Pascal 或 Java 中的 @tt{println}。}


@defproc[(println [datum any/c] [out output-port? (current-output-port)]
                  [quote-depth (or/c 0 1) 0])
         void?]{

与 @racket[(print datum out quote-depth)] 后跟 @racket[(newline out)] 相同。

@racket[println] 函数与其他语言中的 @tt{println} 不等价，因为 @racket[println] 使用的打印约定更接近 @racket[write] 而不是 @racket[display]。对于其他语言中 @tt{println} 的更近似物，使用 @racket[displayln]。

@history[#:added "6.1.1.8"]}


@defproc[(fprintf [out output-port?] [form string?] [v any/c] ...) void?]{

将格式化输出打印到 @racket[out]，其中 @racket[form] 是直接打印的字符串，除了特殊格式化转义：

@itemize[

  @item{@FmtMark{n} 或 @FmtMark{%} 打印一个换行字符（等价于字面量格式字符串中的 @litchar{\n}）}

  @item{@FmtMark{a} 或 @FmtMark{A} @racket[display] @racket[v] 中的下一个参数}

  @item{@FmtMark{s} 或 @FmtMark{S} @racket[write] @racket[v] 中的下一个参数}

  @item{@FmtMark{v} 或 @FmtMark{V} @racket[print] @racket[v] 中的下一个参数}
 
  @item{@FmtMark{.}@nonterm{c} 其中 @nonterm{c} 是 @litchar{a}、@litchar{A}、@litchar{s}、@litchar{S}、@litchar{v} 或 @litchar{V}：将 default-handler @racket[display]、@racket[write] 或 @racket[print] 输出截断为 @racket[(error-print-width)] 个字符，如果未截断输出会更长，则最后三个字符使用 @litchar{...}}

  @item{@FmtMark{e} 或 @FmtMark{E} 使用当前 error value conversion handler（参见 @racket[error-value->string-handler]）和当前 error printing width 输出 @racket[v] 中的下一个参数}

  @item{@FmtMark{c} 或 @FmtMark{C} 将 @racket[v] 中的下一个参数作为字符 @racket[write-char]；如果下一个参数不是字符，则 @exnraise[exn:fail:contract]}

  @item{@FmtMark{b} 或 @FmtMark{B} 以二进制打印 @racket[v] 中的下一个参数；下一个参数不是精确数字，则 @exnraise[exn:fail:contract]}

  @item{@FmtMark{o} 或 @FmtMark{O} 以八进制打印 @racket[v] 中的下一个参数；下一个参数不是精确数字，则 @exnraise[exn:fail:contract]}

  @item{@FmtMark{x} 或 @FmtMark{X} 以十六进制打印 @racket[v] 中的下一个参数；下一个参数不是精确数字，则 @exnraise[exn:fail:contract]}

  @item{@FmtMark{~} 打印一个波浪号。}

  @item{@FmtMark{}@nonterm{w}，其中 @nonterm{w} 是空白字符（参见 @racket[char-whitespace?]），跳过 @racket[form] 中的字符直到遇到非空白字符或第二个换行符（以先发生的为准）。在所有平台上，换行符可以是 @racket[#\return]、@racket[#\newline] 或 @racket[#\return] 后紧跟 @racket[#\newline]。}

]

@racket[form] 字符串不得包含任何不属于上述转义的 @litchar{~}，否则 @exnraise[exn:fail:contract]。当格式字符串需要的 @racket[v] 多于提供的数量时，@exnraise[exn:fail:contract]。类似地，当提供的 @racket[v] 多于格式字符串使用的数量时，@exnraise[exn:fail:contract]。

@examples[
(fprintf (current-output-port)
         "~a as a string is ~s.\n"
         '(3 4) 
         "(3 4)")
]}

@defproc[(printf [form string?] [v any/c] ...) void?]{
与 @racket[(fprintf (current-output-port) form v ...)] 相同。}

@defproc[(eprintf [form string?] [v any/c] ...) void?]{
与 @racket[(fprintf (current-error-port) form v ...)] 相同。}

@defproc[(format [form string?] [v any/c] ...) string?]{
格式化为字符串。结果与以下相同：

@racketblock[
(let ([o (open-output-string)])
  (fprintf o form v ...)
  (get-output-string o))
]

@examples[
(format "~a as a string is ~s.\n" '(3 4) "(3 4)")
]}

@defboolparam[print-pair-curly-braces on?]{

一个控制 pair 打印的 @tech{parameter}。如果值为真，则 pair 使用 @litchar["{"] 和 @litchar["}"] 而不是 @litchar{(} 和 @litchar{)} 打印。默认值为 @racket[#f]。}


@defboolparam[print-mpair-curly-braces on?]{

一个控制 pair 打印的 @tech{parameter}。如果值为真，则 mutable pair 使用 @litchar["{"] 和 @litchar["}"] 而不是 @litchar{(} 和 @litchar{)} 打印。默认值为 @racket[#t]。}

@defboolparam[print-unreadable on?]{

一个 @tech{parameter}，启用或禁用没有 @racket[read]able 形式的值（使用默认 reader）的 @racket[print] 和 @racket[write]，包括具有 custom-write 过程的结构（参见 @racket[prop:custom-write]），但不包括 @tech{uninterned} symbols 和 @tech{unreadable symbols}（它们打印与 @tech{interned} symbols 相同）。如果参数值为 @racket[#f]，尝试打印不可读值会引发 @racket[exn:fail]。参数值默认为 @racket[#t]。更多信息参见 @secref["printing"]。}

@defboolparam[print-graph on?]{

一个控制带共享的数据打印的 @tech{parameter}；默认为 @racket[#f]。更多信息参见 @secref["printing"]。}

@defboolparam[print-struct on?]{

一个控制 vector 或 @tech{prefab} 形式的结构值打印的 @tech{parameter}；默认为 @racket[#t]。更多信息参见 @secref["printing"]。此参数对具有 custom-write 过程的结构打印没有影响（参见 @racket[prop:custom-write]）。}

@defboolparam[print-box on?]{

一个控制 box 值打印的 @tech{parameter}；默认为 @racket[#t]。更多信息参见 @secref["print-box"]。}

@defboolparam[print-vector-length on?]{

一个控制 vector 打印的 @tech{parameter}；默认为 @racket[#f]。更多信息参见 @secref["print-vectors"]。}

@defboolparam[print-hash-table on?]{

一个控制 hash table 打印的 @tech{parameter}；默认为 @racket[#t]。更多信息参见 @secref["print-hashtable"]。}


@defboolparam[print-boolean-long-form on?]{

一个控制布尔值打印的 @tech{parameter}。当参数值为真时，@racket[#t] 和 @racket[#f] 打印为 @litchar{#true} 和 @litchar{#false}，否则打印为 @litchar{#t} 和 @litchar{#f}。默认值为 @racket[#f]。}


@defboolparam[print-reader-abbreviations on?]{

一个控制以 @racket[quote]、@racket['quasiquote]、@racket['unquote]、@racket['unquote-splicing]、@racket['syntax]、@racket['quasisyntax]、@racket['unsyntax] 或 @racket['unsyntax-splicing] 开头的两元素列表打印的 @tech{parameter}；默认为 @racket[#f]。更多信息参见 @secref["print-pairs"]。}

@defboolparam[print-as-expression on?]{

一个控制 @racket[print] 模式（相对于 @racket[write] 或 @racket[display]）下打印的 @tech{parameter}；默认为 @racket[#t]。更多信息参见 @secref["printing"]。}


@defparam[print-syntax-width width (or/c +inf.0 0 (and/c exact-integer? (>/c 3)))]{

一个控制 @tech{syntax objects} 打印的 @tech{parameter}。最多使用 @racket[width] 个字符来显示 syntax object 的 datum 形式（在 @litchar{#<syntax}...@litchar{>} 内，在 @tech{syntax object} 的 source location 之后（如果有的话）），如果打印的格式会比 @racket[width] 个字符长，则最后三个字符使用 @litchar{...}。@racket[width] 值为 @racket[0] 表示 datum 完全不显示。}

@defparam[print-value-columns columns (or/c +inf.0 (and/c exact-integer? (>/c 5)))]{

一个 @tech{parameter}，包含关于通过 @racket[print] 打印值应使用的列数的建议。
可能被 @racket[print] 尊重也可能不尊重 - 当前 @racket[print] 的默认 handler 不尊重。预期使用某种形式的 pretty-printing 的 REPLs 会尊重此参数。

@history[#:added "8.0.0.13"]
}

@defparam*[current-write-relative-directory path 
                                            (or/c (and/c path-string? complete-path?) 
                                                  (cons/c (and/c path-string? complete-path?)
                                                          (and/c path-string? complete-path?))
                                                  #f)
                                            (or/c (and/c path? complete-path?) 
                                                  (cons/c (and/c path? complete-path?) 
                                                          (and/c path? complete-path?))
                                                  #f)]{

一个 @tech{parameter}，在写入包含 pathname 字面量的编译代码时使用（参见 @secref["print-compiled"]），包括过程名称的 source-location pathnames。当参数值为 @racket[_path] 时，语法上扩展 @racket[_path] 的路径被转换为相对路径；当读取生成的编译代码时，相对路径使用 @racket[current-load-relative-directory] 参数转换回完整路径（如果该参数不是 @racket[#f]；否则，路径保持相对）。当参数值为 @racket[(cons _rel-to-path _base-path)] 时，语法上扩展 @racket[_base-path] 的路径相对于 @racket[_rel-to-path] 转换；@racket[_rel-to-path] 必须扩展 @racket[_base-path]，在这种情况下，可以使用 @racket['up] 路径元素（在 @racket[build-path] 的意义上）使路径相对于 @racket[_rel-to-path]。}



@deftogether[(
@defproc*[([(port-write-handler [out output-port?]) (any/c output-port? . -> . any)]
           [(port-write-handler [out output-port?]
                                [proc (any/c output-port? . -> . any)])
            void?])]
@defproc*[([(port-display-handler [out output-port?]) (any/c output-port? . -> . any)]
           [(port-display-handler [out output-port?]
                                  [proc (any/c output-port? . -> . any)])
            void?])]
@defproc*[([(port-print-handler [out output-port?]) ((any/c output-port?) ((or/c 0 1)) . ->* . any)]
           [(port-print-handler [out output-port?]
                                [proc (any/c output-port? . -> . any)])
            void?])]
)]{

获取或设置 @racket[out] 的 @deftech{port write handler}、@deftech{port display handler} 或 @deftech{port print handler}。当 @racket[write]、@racket[display] 或 @racket[print]（分别）应用于 port 时，调用此 handler 来输出到 port。每个 handler 必须接受两个参数：要打印的值和目标 port。handler 的返回值被忽略。

@tech{port print handler} 可选地接受第三个参数，对应于 @racket[print] 的可选第三个参数；如果给 @racket[port-print-handler] 的过程不接受第三个参数，则将其包装在一个丢弃可选第三个参数的过程中。

默认的 port display 和 write handler 使用 Racket 的内置 printer 打印 Racket 表达式（参见 @secref["printing"]）。默认的 print handler 调用全局 port print handler（@racket[global-port-print-handler] 参数的值）；默认的全局 port print handler 与默认的 write handler 相同。

@defproc*[([(global-port-print-handler) (->* (any/c output-port?) ((or/c 0 1)) any)]
           [(global-port-print-handler [proc (or/c (->* (any/c output-port?) ((or/c 0 1)) any)
                                                   (any/c output-port? . -> . any))])
            void?])]{

一个 @tech{parameter}，确定 @deftech{global port print handler}，由默认的 port print handler 调用（参见 @racket[port-print-handler]）来将值 @racket[print] 到 port 中。默认值等价于 @racket[default-global-port-print-handler]。

@tech{global port print handler} 可选地接受第三个参数，对应于 @racket[print] 的可选第三个参数。如果给 @racket[global-port-print-handler] 的过程不接受第三个参数，则将其包装在一个丢弃可选第三个参数的过程中。}

@defproc[(default-global-port-print-handler [v any/c]
                                            [out output-port?]
                                            [print-depth (or/c 0 1) 0])
         void?]{

使用内置 printer（参见 @secref["printing"]）以 @racket[print] 模式将 @racket[v] 打印到 @racket[out]。

@history[#:added "8.8.0.6"]}
}
