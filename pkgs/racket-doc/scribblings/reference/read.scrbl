#lang scribble/doc
@(require "mz.rkt")

@title{读取}

@defproc[(read [in input-port? (current-input-port)]) any]{

Reads and returns a single @tech{datum} from @racket[in]. If
@racket[in] has a handler associated to it via
@racket[port-read-handler], then the handler is called. Otherwise, the
default reader is used, as parameterized by the
@racket[current-readtable] parameter, as well as many other
parameters.

See @secref["reader"] for information on the default reader and
@secref["parse-reader"] for the protocol of @racket[read].}

@defproc[(read-syntax [source-name any/c (object-name (current-input-port))]
                      [in input-port? (current-input-port)])
         (or/c syntax? eof-object?)]{

类似于 @racket[read]，但产生带有源位置信息的 @tech{syntax object}。@racket[source-name] 用作 syntax object 的源字段，可以是任意值，但通常应为源文件的路径。

参见 @secref["reader"] 了解 @racket[read-syntax] 模式下默认读取器的信息，参见 @secref["parse-reader"] 了解 @racket[read-syntax] 的协议。

通常，应启用 @racket[in] 的行计数，以使 syntax object 中的源位置按字符而非字节计算。另请参见 @secref["linecol"]。}

@guidealso["stx-obj"]

@defproc[(read/recursive [in input-port? (current-input-port)]
                         [start (or/c char? #f) #f]
                         [readtable (or/c readtable? #f) (current-readtable)]
                         [graph? any/c #t])
          any]{

Similar to calling @racket[read], but normally used during the dynamic
extent of @racket[read] within a reader-extension procedure (see
@secref["reader-procs"]). The main effect of using
@racket[read/recursive] instead of @racket[read] is that
graph-structure annotations (see @secref["parse-graph"]) in the
nested read are considered part of the overall read, at least when the
@racket[graph?] argument is true; since the result is wrapped in a
placeholder, however, it is not directly inspectable.

If @racket[start] is provided and not @racket[#f], it is effectively
prefixed to the beginning of @racket[in]'s stream for the read. (To
prefix multiple characters, use @racket[input-port-append].)

The @racket[readtable] argument is used for top-level parsing to
satisfy the read request, including various delimiters of a built-in
top-level form (such as parentheses and @litchar{.} for reading a hash
table); recursive parsing within the read (e.g., to
read the elements of a list) instead uses the current readtable as
determined by the @racket[current-readtable] parameter.  A reader
macro might call @racket[read/recursive] with a character and
readtable to effectively invoke the readtable's behavior for the
character.  If @racket[readtable] is @racket[#f], the default
readtable is used for top-level parsing.

When @racket[graph?] is @racket[#f], graph structure annotations in
the read datum are local to the datum.

When called within the dynamic extent of @racket[read], the
@racket[read/recursive] procedure can produce a special-comment value
(see @secref["special-comments"]) when the input stream's first
non-whitespace content parses as a comment.

See @secref["readtables"] for an extended example that uses
@racket[read/recursive].

@history[#:changed "6.2" @elem{Adjusted use of @racket[readtable] to
                               more consistently apply to the delimiters of
                               a built-in form.}]}


@defproc[(read-syntax/recursive [source-name any/c (object-name in)]
                                [in input-port? (current-input-port)]
                                [start (or/c char? #f) #f]
                                [readtable (or/c readtable? #f) (current-readtable)]
                                [graph? any/c #t])
          any]{

Analogous to calling @racket[read/recursive], but the resulting value
encapsulates S-expression structure with source-location
information. As with @racket[read/recursive], when
@racket[read-syntax/recursive] is used within the dynamic extent of
@racket[read-syntax], the result from
@racket[read-syntax/recursive] is either a special-comment value,
end-of-file, or opaque graph-structure placeholder (not a syntax
object). The placeholder can be embedded in an S-expression or syntax
object returned by a reader macro, etc., and it will be replaced with
the actual syntax object before the outermost @racket[read-syntax]
returns.

Using @racket[read/recursive] within the dynamic extent of
@racket[read-syntax] does not allow graph structure for reading to be
included in the outer @racket[read-syntax] parsing, and neither does
using @racket[read-syntax/recursive] within the dynamic extent of
@racket[read]. In those cases, @racket[read/recursive] and
@racket[read-syntax/recursive] produce results like @racket[read] and
@racket[read-syntax], except that a special-comment value is returned
when the input stream starts with a comment (after whitespace).

See @secref["readtables"] for an extended example that uses
@racket[read-syntax/recursive].

@history[#:changed "6.2" @elem{Adjusted use of @racket[readtable]
                               in the same way as for
                               @racket[read/recursive].}]}


@defproc[(read-language [in input-port? (current-input-port)]
                        [fail-thunk (-> any) (lambda () (error ...))])
         (or/c (any/c any/c . -> . any) #f)]{

从 @racket[in] 读取的方式类似于 @racket[read]，但在确定 @tech{reader language}（或其缺失）后立即停止。

@deftech{reader language} 由输入开头的 @litchar{#lang} 或 @litchar{#!} 指定（参见 @secref["parse-reader"]），但可能在 comment 形式之后。@racket[read-language] 使用默认的 @tech{readtable}（而非 @racket[current-readtable] 的值），并且不允许在 @litchar{#lang} 或 @litchar{#!} 之前出现 @litchar{#reader} 形式（可能产生注释）。

@guidealso["language-get-info"]

当找到 @litchar{#lang} 或 @litchar{#!} 规范时，@racket[read-language] 不会如 @racket[read] 和 @racket[read-syntax] 那样分派到 @racketidfont{read} 或 @racketidfont{read-syntax} 函数，而是分派到同一模块导出的 @racketidfont{get-info} 函数（如果有）。 @racketidfont{get-info} 的参数与 @secref["parse-reader"] 中描述的 @racketidfont{read} 相同。如果结果是双参数函数，则该函数即为 @racket[read-language] 的结果；如果 @racketidfont{get-info} 产生其他类型的结果，则 @exnraise[exn:fail:contract]。如果未导出 @racketidfont{get-info} 函数，@racket[read-language] 返回 @racket[#f]。

@racketidfont{get-info} 返回的函数反映了关于输入流预期语法的信息；其第一个参数用作此类信息的可接受键。结果的解释由外部工具（如 DrRacket；参见 @seclink["lang-languages-customization" #:doc '(lib "scribblings/tools/tools.scrbl")]）决定。Languages）决定。如果给定键不可用，结果应为第二个参数。
@mz-examples[
(define scribble-manual-info
  (read-language (open-input-string "#lang scribble/manual")))
(scribble-manual-info 'color-lexer #f)
(scribble-manual-info 'something-else #f)
]

@racketidfont{get-info} 函数本身接受五个参数：正在读取的输入端口、提取 @racketidfont{get-info} 函数的模块路径、源行号（正实数或 @racket[#f]）、列号（非负实数或 @racket[#f]）以及 @litchar{#lang} 或 @litchar{#!} 形式的起始位置（正实数或 @racket[#f]）。@racketidfont{get-info} 函数可能进一步从给定输入端口读取以确定结果，但不应读取超出必要范围。

If @racket[in] starts with a @tech{reader language} specification but
the relevant module does not export @racketidfont{get-info} (but
perhaps does export @racketidfont{read} and
@racketidfont{read-syntax}), then the result of @racket[read-language]
is @racket[#f].

If @racket[in] has a @litchar{#lang} or @litchar{#!} specification,
but parsing and resolving the specification raises an exception, the
exception is propagated by @racket[read-language]. Having at least
@litchar{#l} or @litchar{#!} (after comments and whitespace) counts as
starting a @litchar{#lang} or @litchar{#!} specification.

If @racket[in] does not specify a @tech{reader language} with
@litchar{#lang} or @litchar{#!}, then @racket[fail-thunk] is
called. The default @racket[fail-thunk] raises
@racket[exn:fail:read] or @racket[exn:fail:read:eof].}


@defboolparam[read-case-sensitive on?]{

A @tech{parameter} that controls parsing and printing of symbols. When this
parameter's value is @racket[#f], the reader case-folds symbols (e.g.,
producing @racket['hi] when the input is any one of @litchar{hi},
@litchar{Hi}, @litchar{HI}, or @litchar{hI}). The parameter also
affects the way that @racket[write] prints symbols containing
uppercase characters; if the parameter's value is @racket[#f], then
symbols are printed with uppercase characters quoted by a
@litchar{\} or @litchar{|}. The parameter's value is overridden by
quoting @litchar{\} or @litchar{|} vertical-bar quotes and the
@litchar{#cs} and @litchar{#ci} prefixes; see
@secref["parse-symbol"] for more information. While a module is
loaded, the parameter is set to @racket[#t] (see
@racket[current-load]).}

@defboolparam[read-square-bracket-as-paren on?]{

控制 @litchar{[} 和 @litchar{]} 是否被视为括号。参见 @secref["parse-pair"] 了解更多信息。}

@defboolparam[read-curly-brace-as-paren on?]{

控制 @litchar["{"] 和 @litchar["}"] 是否被视为括号。参见 @secref["parse-pair"] 了解更多信息。}

@defboolparam[read-square-bracket-with-tag on?]{

控制 @litchar{[} 和 @litchar{]} 是否被视为括号，结果列表标记为 @racket[#%brackets]。参见 @secref["parse-pair"] 了解更多信息。

@history[#:added "6.3.0.5"]}

@defboolparam[read-curly-brace-with-tag on?]{

控制 @litchar["{"] 和 @litchar["}"] 是否被视为括号，结果列表标记为 @racket[#%braces]。参见 @secref["parse-pair"] 了解更多信息。

@history[#:added "6.3.0.5"]}

@defboolparam[read-accept-box on?]{

控制是否解析 @litchar{#&} 输入。参见 @secref["parse-box"] 了解更多信息。}

@defboolparam[read-accept-compiled on?]{

A @tech{parameter} that controls parsing @litchar{#~} compiled input. See
@secref["reader"] and @racket[current-compile] for more
information.}

@defboolparam[read-accept-bar-quote on?]{

控制是否解析和打印 symbol 中的 @litchar{|}。参见 @secref["parse-symbol"] 和 @secref["printing"] 了解更多信息。}

@defboolparam[read-accept-graph on?]{

控制是否在 @racket[read] 模式下解析带共享的输入。参见 @secref["parse-graph"] 了解更多信息。}

@defboolparam[read-syntax-accept-graph on?]{

A parameter value that controls parsing input with sharing in
@racket[read-syntax] mode. See @secref["parse-graph"] for more information.

@history[#:added "8.4.0.8"]}

@defboolparam[read-decimal-as-inexact on?]{

控制是否解析带小数点或指数（但无显式精确性标签）的输入数字。参见 @secref["parse-number"] 了解更多信息。}

@defboolparam[read-single-flonum on?]{

控制是否解析带有 @litchar{f}、@litchar{F}、@litchar{s} 或 @litchar{S} 精度字符的输入数字。参见 @secref["parse-number"] 了解更多信息。

@history[#:added "7.3.0.5"]}

@defboolparam[read-accept-dot on?]{

控制是否解析带有点的输入，点通常用于字面 cons cells。参见 @secref["parse-pair"] 了解更多信息。}

@defboolparam[read-accept-infix-dot on?]{

控制是否解析带有两个点的输入以触发中缀转换。参见 @secref["parse-pair"] 了解更多信息。}

@defboolparam[read-cdot on?]{

控制是否以 C 结构体访问器风格解析带有点的输入。参见 @secref["parse-cdot"] 了解更多信息。

@history[#:added "6.3.0.5"]}

@defboolparam[read-accept-quasiquote on?]{

A @tech{parameter} that controls parsing input with @litchar{`} or
@litchar{,} which is normally used for @racket[quasiquote],
@racket[unquote], and @racket[unquote-splicing] abbreviations. See
@secref["parse-quote"] for more information.}

@defboolparam[read-accept-reader on?]{

控制是否允许 @litchar{#reader}、@litchar{#lang} 或 @litchar{#!} 来选择解析器。参见 @secref["parse-reader"] 了解更多信息。}

@defboolparam[read-accept-lang on?]{

A @tech{parameter} that (along with @racket[read-accept-reader]) controls
whether @litchar{#lang} and @litchar{#!} are allowed for selecting a
parser. See @secref["parse-reader"] for more information.}


@defparam[current-readtable readtable (or/c readtable? #f)]{

一个参数，其值决定一个调整 S-expression 输入解析方式的 readtable，其中 @racket[#f] 表示默认行为。参见 @secref["readtables"] 了解更多信息。}


@defproc[(call-with-default-reading-parameterization [thunk (-> any)])
         any]{

Calls @racket[thunk] in @tech{tail position} of a @racket[parameterize]
to set all reader @tech{parameters} above to their default values.

Using the default parameter values ensures consistency, and it also
provides safety when reading from untrusted sources, since the default
values disable evaluation of arbitrary code via @hash-lang[] or
@litchar{#reader}.}


@defparam[current-reader-guard proc (any/c . -> . any)]{

A parameter whose value converts or rejects (by raising an exception)
a module-path datum following @litchar{#reader}. See
@secref["parse-reader"] for more information.}

@defparam[read-on-demand-source mode (or/c #f #t (and/c path? complete-path?))]{

A @tech{parameter} that enables lazy parsing of compiled code, so that
closure bodies and syntax objects are extracted (and validated) from
marshaled compiled code on demand. Normally, this parameter is set by
the default @tech{load handler} when @racket[load-on-demand-enabled]
is @racket[#t].

A @racket[#f] value for @racket[read-on-demand-source] disables lazy
parsing of compiled code. A @racket[#t] value enables lazy parsing.  A
@tech{path} value furthers enable lazy retrieval from disk---instead
of keeping unparsed compiled code in memory---when the
@as-index{@envvar{PLT_DELAY_FROM_ZO}} environment variable is set (to
any value) on start-up.

If the file at @racket[mode] as a @tech{path} changes before the
delayed code is parsed when lazy retrieval from disk is enabled, then
the on-demand parse most likely will encounter garbage, leading to an
exception.}


@defproc*[([(port-read-handler [in input-port?]) (case->
                                                  (input-port? . -> . any)
                                                  (input-port?  any/c . -> . any))]
           [(port-read-handler [in input-port?]
                               [proc (case->
                                      (input-port? . -> . any)
                                      (input-port? any/c . -> . any))]) 
            void?])]{

Gets or sets the @deftech{port read handler} for @racket[in]. The
handler called to read from the port when the built-in @racket[read]
or @racket[read-syntax] procedure is applied to the port. (The
port read handler is not used for @racket[read/recursive] or
@racket[read-syntax/recursive].)

A port read handler is applied to either one argument or two
arguments:

@itemize[

 @item{A single argument is supplied when the port is used
 with @racket[read]; the argument is the port being read. The return
 value is the value that was read from the port (or end-of-file).}

 @item{Two arguments are supplied when the port is used with
 @racket[read-syntax]; the first argument is the port being read, and
 the second argument is a value indicating the source. The return
 value is a syntax object that was read from the port (or end-of-file).}

]

The default port read handler reads standard Racket expressions with
Racket's built-in parser (see @secref["reader"]). It handles a
special result from a custom input port (see
@racket[make-input-port]) by treating it as a single expression,
except that special-comment values (see
@secref["special-comments"]) are treated as whitespace.

The default port read handler itself can be customized through a
readtable; see @secref["readtables"] for more information.}
