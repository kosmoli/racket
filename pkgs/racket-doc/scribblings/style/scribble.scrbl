#lang scribble/doc
@(require scribble/eval
          "shared.rkt"
          (for-label (except-in scribble/manual link)
                     scribble/eval))

@title[#:tag "reference-style"]{Scribbling Documentation}

This section describes good style for Racket documentation writing.

@section{Prose and Terminology}

在 @racket[defform]、@racket[defproc] 等描述性正文中，不要以 "This ..." 开头。相反，以被描述的形式或值为主语开始句子（但仅第一句如此）。首字母大写。因此，描述通常以 "Returns" 或 "Produces." 开头。通过名称引用参数和子形式。

在描述语法形式中的子形式时，不要使用 "argument" 一词；请使用 "sub-form" 一词，将 "argument" 留给函数调用中的值或表达式。将库和语言称为 "libraries" 和 "languages"，而非 "modules"（即使用于显示库或语言名称的形式称为 @racket[racketmodname]）。不要将标识符（即语法元素）称为 "variable" 或 "symbol"。不要用 "expression" 一词指代可能是定义的形式；请使用 "form" 一词。"function" 优先于 "procedure"。

仅当指由空列表和 cons 单元组成的运行时段时，才使用 "list" 一词。如有必要，在其他情况下使用 "sequence"。例如，不要写 @racket[begin] 有一个 "list of sub-forms"；而是写 "sequence of sub-forms"。类似地，不要提及函数调用中的 "list of arguments"；如可能只写 "arguments"，或写 "sequence of argument expressions"。（遗憾的是，@tech[#:doc '(lib
"scribblings/reference/reference.scrbl")]{sequence} 也获得了具体的运行时段含义，但这种冲突不如 Lisp 中列表与其他实体之间历史混淆那么严重。）

避免描述性文本的复制粘贴。如果两个函数相似，考虑使用 @racket[deftogether] 一起记录。要抽象描述，考虑使用显式散文抽象，例如 "@racket[x] 类似 @racket[y]，除了 ..."，而非抽象源码并多次实例化；通常对读者而言，散文抽象比文档实现中的隐藏抽象更清晰。

"sub-form" 和 "sub-expression" 要加连字符。

对于三个 "平台"（而非 "系统"），请使用 "Windows"、"Mac OS" 和 "Unix"——这些是 Racket 运行的平台。将 "Unix" 用作类 Unix 操作系统的通用词——显著包括 Linux——而不是 Mac OS。即使 "Gtk" 或 "the X11 windowing system" 会更准确，也应使用 "Unix"。有需要时可将 "X11" 用作形容词，如 "X11 display"。Racket 运行 "于"（"on"）平台之上，而非 "under" 平台。

将 Racket 编程环境称为 "DrRacket"，而非 "Dr. Racket。"

 Avoid using a predicate as a noun that stands for a value
satisfying the predicate. Instead, use @racket[tech] and
@racket[deftech] to establish a connection between an
English word or phrase that describes the class of values
and the predicate (or
@tech[#:doc '(lib "scribblings/reference/reference.scrbl"){
 contract}). For example, avoid "supply a
@racket[path-string?]"; prefer "supply a
@tech[#:doc '(lib "scribblings/reference/reference.scrbl"){
 path or string}."


@section{Typesetting Code}

在 @racket[defform] 中使用 @racketidfont{id} 或以 @racketidfont{-id} 结尾的名称表示标识符，而非 @racketidfont{identifier}、@racketidfont{variable}、@racketidfont{name} 或 @racketidfont{symbol}。类似地，在语法形式中用于表达式位置使用 @racketidfont{expr} 或以 @racketidfont{-expr} 结尾的。在内定义位置用于形式（定义或表达式）使用 @racketidfont{body}——在语法描述中总是后跟 @racket[...+]。对非表达式不要使用 @racketidfont{expr}，对非标识符不要使用 @racketidfont[id]，等等；相反使用 @racket[defform/subs] 定义新的非终端。

使用 @racket[deftogether] 定义语法形式或过程的多个变体时要小心，因为每个 @racket[defform] 或 @racket[defproc] 创建一个定义点，但每个形式或过程应只有一个定义点。（Scribble 在绑定有多个定义点时会发出问题警告。）相反，应使用 @racket[defproc*] 或 @racket[defform*]。

函数参数使用 @racket[v] 作为 "any value" 的元变量。@racket[x] 仅用于数值的元变量。其他约定包括 @racket[lst] 对应列表、@racket[proc] 对应过程。

使用 @racket[racket] 时注意标识符和元变量之间的区别，在 @racket[defproc] 或 @racket[defform] 之外尤其如此。前缀元变量使用 @litchar{_}；例如，

@verbatim[#:indent 2]|{@racket[(rator-expr rand-expr ...)]}|

会是引用函数调用语法的错误方式，因为它生成 @racket[(rator-expr rand-expr ...)]，其中 @racketidfont{rator-expr} 和 @racketidfont{rand-expr} 被排印为变量。正确描述为

@verbatim[#:indent 2]|{@racket[(_rator-expr _rand-expr ...)]}|

它生成 @racket[(_rator-expr _rand-expr ...)]，其中 @racketidfont{rator-expr} 和 @racketidfont{rand-expr} 被排印为元变量。@racket[defproc]、@racket[defform] 等
形式大大减轻了描述中的这种负担，因为它们为非文字标识符自动设置元变量排印。在
@racket[defform] 中，务必在 @racket[#:literals] 子句中包含文字标识符（即非变量的标识符，除了正在定义的形式名称）。

无特定解释地排印标识符——语法、变量、元变量等——使用 @racket[racketidfont]（例如上述 @racketidfont{rand-expr}）。否则使用 @racket[litchar]，而非仅 @racket[racketfont] 或 @racket[verbatim]，以引用特定字符序列。

语法形式从给定标识符合成标识符时，使用 @racket[racketidfont] 和 @racket[racket] 组合来描述标识符。例如，如果 @racket[_id] 与 @racketidfont{is-} 和 @racketidfont{?} 组合形成 @racketidfont{is-}@racket[_id]@racketidfont{?}，则将该标识符实现为
@code[#:lang "at-exp racket"]|{@racketidfont{is-}@racket[id]@racketidfont{?}}|。

使用 @racket[defform] 描述语法形式时，不要混淆 @racket[#:contracts] 子句和语法规范。仅在表达式内表单中使用 @racket[#:contracts]，且合约是运行时间约束——而非语法约束，例如要求子表单为标识符。使用 @racket[defform/subs] 进行语法约束。

展示求值示例时，请使用 REPL-snapshot 样式：
@verbatim[#:indent 2]|{
  @examples[
   (+ 1 2)
  ]
}|

参见 @racketmodname[scribble/example] 库和 @secref["examples-style"]。

用四个点 @litchar{....} 代替省略的代码，因为 @litchar{...} 表示重复。


@section{Typesetting Prose}

Avoid referring to documentation ``above'' or ``below,'' and
instead have a hyperlink point to the right place.

In prose, use @litchar{``} and @litchar{''} quotation marks instead of
@litchar{"}. Use @litchar{---} for an em dash, and do not include
spaces on either side. Use American style for quotation marks and punctuation
@; [Eli] BTW, I've asked several people about this, and the general
@;   agreement that I've seen is that this is a rather arbitrary rule
@;   and there's no harm in doing the more logical thing of putting
@;   the punctuations outside quotations and parens.  Just like you
@;   did at the end of this sentence...
@; [Matthew] See intro of this section.
at the end of quotation marks (i.e., a sentence-terminating period
goes inside the quotation marks). Of course, this rule does not apply
for quotation marks that are part of code.

Do not use a citation reference (as created by @racket[cite]) as a
noun; use it as an annotation.

Do not start a sentence with a Racket variable name, since it is
normally lowercase. For example, use ``The @racket[_thing] argument
is...'' instead of ``@racket[_thing] is...''

Use @racket[etc] for ``@|etc|'' when it does not end a sentence, and
include a comma after ``@|etc|'' unless it ends a sentence that is
followed by other punctuation (such as a parenthesis).

Do not italicize common Latin phrases and abbreviations, such as ``e.g.'' and
``i.e.''.

@section{Section Titles}

Capitalize all words except articles (``the,'' ``a,'' etc.),
prepositions, and conjunctions that are not at the start of the title.

手册标题通常以适当的关键词或关键短语开头（例如本手册中的 "Scribble"），加粗显示。如果关键词主要是可执行文件名称，使用 @racket[exec] 而非 @racket[bold]。可选在冒号后的标题中添加进一步的描述性文本，其中冒号开始的文本不加粗。

@section{Indexing}

Document and section titles, identifiers that are documented with
@racket[defproc], @racket[defform], etc. are automatically indexed, as
are terms defined with @racket[deftech].

Symbols are not indexed automatically.  Use @racket[indexed-racket]
instead of @racket[racket] for the instance of a symbol that roughly
defines the use. For an example, try searching for ``truncate'' to
find @racket['truncate] as used with @racket[open-output-file]. Do not
use something like @racket[(index "'truncate")] to index a symbol,
because it will not typeset correctly (i.e., in a fixed-width font
with the color of a literal).

Use @racket[index], @racket[as-index], and @racket[section-index] as a
last resort. Create index entries for terms that are completely
different from terms otherwise indexed. Do not try to index minor
variations of a term or phrase in an attempt to improve search
results; if search fails to find a word or phrase due to a minor
variation, then the search algorithm should be fixed, not the index
entry.

@section[#:tag "examples-style"]{Examples}

力求为每个函数和语法形式的文档包含示例（使用 @racket[examples]）。写示例时，避免使用 "foo" 和 "bar" 等无意义词。例如，记录 @racket[member] 时，抗拒写下

@interaction[
(member "foo" '("bar" "foo" "baz"))
]

而要写像

@interaction[
(member "Groucho" '("Harpo" "Groucho" "Zeppo"))
]

这样的内容。
