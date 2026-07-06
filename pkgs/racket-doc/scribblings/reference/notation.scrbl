#lang scribble/doc
@(require scribble/struct scribble/racket "mz.rkt")

@title[#:tag "notation"]{文档符号约定}

本章介绍 Racket 文档中使用的核心术语和符号约定。

@; ----------------------------------------
@section{模块文档符号约定}

由于 Racket 程序按 @tech{module} 组织，文档在描述特定 module 提供的绑定的章节或子章节开头使用标注来反映这种组织方式。

例如，描述 @racketmodname[racket/list] 提供的功能的章节以

@nested[#:style 'inset
        (defmodule racket/list #:no-declare #:link-target? #f)]

开头。

有些 module 使用 @hash-lang[] 而非 @racket[require] 引入：

@nested[#:style 'inset
        (defmodule racket/base #:lang #:no-declare #:link-target? #f)]

使用 @hash-lang[] 表示该 module 通常用作整个 module 的语言——即由以 @hash-lang[] 后跟语言名称开头的 module 使用——而不是通过 @racket[require] 导入。不过，除非另有说明，使用 @hash-lang[] 记录的 module 名称也可以通过 @racket[require] 使用以获取该语言的绑定。

module 标注还在右侧显示该 module 所属的 @tech[#:doc '(lib "pkg/scribblings/pkg.scrbl")]{package}。关于 package 的更多详情，请参见 @(other-manual '(lib "pkg/scribblings/pkg.scrbl"))。

有时，module 说明出现在文档开头或包含多个子章节的 section 开头。文档的 section 或 section 的子章节旨在"继承"外层文档或 section 的 module 声明。因此，@other-doc['(lib "scribblings/reference/reference.scrbl")] 中记录的绑定可从 @racketmodname[racket] 和 @racket[racket/base] 获取，除非在 section 或子 section 中另有说明。

@; ----------------------------------------
@section{语法形式文档符号约定}

@guideintro["syntax-notation"]{此语法形式符号约定}

语法形式使用文法指定。通常，文法以左括号后跟语法形式的名称开头，如 @racket[if] 的文法所示：

@nested[#:style 'inset
@defform[#:link-target? #f
         (if test-expr then-expr else-expr)]
]

由于每个 @tech{form} 都使用 @tech{syntax object} 表达，文法中的括号表示包装列表的 @tech{syntax object}，而开头的 @racket[if] 是一个标识符，用于启动其 @tech{binding} 为所记录 module 的 @racket[if] 绑定的列表——这里指 @racketmodname[racket/base]。文法中的方括号与括号类似地表示 @tech{syntax object} 列表，但在程序源代码中方括号通常按约定使用。

文中的斜体 @tech{identifiers} 是对应其他文法生成的 @deftech{metavariables}。某些 metavariable 名称具有隐式文法生成：

@itemize[

 @item{以 @racket[_id] 结尾的 metavariable 表示 @tech{identifier}。}

 @item{以 @racket[_keyword] 结尾的 metavariable 表示 @tech{syntax-object} @tech{keyword}。}

 @item{以 @racket[_expr] 结尾的 metavariable 表示任意 @tech{form}，该形式将被解析为表达式。}

 @item{以 @racket[_body] 结尾的 metavariable 表示任意 @tech{form}；该形式将被解析为局部定义或表达式。只有当 @racket[_body] 前没有任何表达式时，它才能被解析为定义，并且最后一个 @racket[_body] 必须是表达式；另请参见 @secref["intdef-body"]。}

 @item{以 @racket[_datum] 结尾的 metavariable 表示任意 @tech{form}，该形式通常不被解释（例如，被 @racket[quote] 的）。}

 @item{以 @racket[_number] 或 @racket[_boolean] 结尾的 metavariable 表示任意 @tech{syntax-object}（即字面值）@tech{number} 或 @tech{boolean}。}

]

在文法中，@racket[_form ...] 表示匹配 @racket[_form] 的任意数量（可能为零）的形式，而 @racket[_form ...+] 表示匹配 @racket[_form] 的一个或多个形式。

没有隐式文法的 metavariable 在语法形式整体文法旁通过生成定义。例如，在

@nested[#:style 'inset
@defform[#:link-target? #f
         (lambda formals body ...+)
         #:grammar ([formals id
                             (id ...+ . rest-id)])]
]

中，@racket[_formals] metavariable 表示单个 @tech{identifier}、@tech{syntax-object} 列表中的零个或多个 @tech{identifiers}，或对应于以 @tech{identifier} 而非空列表结尾的一个或多个 pair 链的 @tech{syntax object}。

某些语法形式具有多个顶层文法，此时文档中展示多个文法。例如，

@nested[#:style 'inset
@defform*[#:link-target? #f
          ((init-rest id)
           (init-rest))]
]

表明 @racket[init-rest] 可以单独存在于其 @tech{syntax object} 列表中，也可以后跟单个 @tech{identifier}。

最后，包含 @racket[_expr]  metavariable 的文法规格可带有运行时的 @tech{contract} 来扩展，这些 contract 指示表达式结果在运行时必须满足的谓词。例如，

@nested[#:style 'inset
@defform[#:link-target? #f
         (parameterize ([parameter-expr value-expr] ...)
           body ...+)
         #:contracts
         ([parameter-expr parameter?])]
]

表明每个 @racket[_parameter-expr] 的结果必须是使 @racket[(parameter? _v)] 返回真的值 @racket[_v]。


@; ----------------------------------------
@section{函数文档符号约定}

过程和其他值使用基于 @tech{contract} 的符号约定来描述。本质上，这些 contract 使用 Racket 谓词和表达式描述所记录库的接口。

例如，以下是典型过程定义的头部：

@nested[#:style 'inset
@defproc[#:link-target? #f
         (char->integer [char char?]) exact-integer?]
]

被定义的函数 @racket[char->integer] 的排版方式如同正在被应用。函数名称后的 metavariable 代表参数。角落中的白色文本标识正在记录的值类型。

每个 metavariable 使用 contract 描述。在前面的示例中，metavariable @racket[_char] 具有 contract @racket[char?]。该 contract 指定任何对 @racket[char?] 谓词回答真的 @racket[_char] 参数都是有效的。被记录的函数可能实际检查也可能不实际检查此属性，但 contract 表明实现者的意图。

箭头右侧的 contract，此处为 @racket[exact-integer?]，指定函数产生的预期结果。

contract 规格可以比单纯谓词名称更具表现力。考虑 @racket[argmax] 的以下头部：

@nested[#:style 'inset
@defproc[#:link-target? #f
         (argmax [proc (-> any/c real?)]
                 [lst (and/c pair? list?)])
         any]
]

contract @racket[(-> any/c real?)] 表示指定 @racket[proc] 的参数可以是任意单个值且结果应为实数的函数 contract。@racket[_lst] 的 contract @racket[(and/c pair? list?)] 指定 @racket[_lst] 应同时通过 @racket[pair?] 和 @racket[list?]（即非空列表）。

@racket[->] 和 @racket[and/c] 都是 @tech{contract combinator} 的示例。@racket[or/c]、@racket[cons/c]、@racket[listof] 等 contract combinator 在整个文档中使用。点击超链接的 combinator 名称将提供关于其含义的更多信息。

Racket 函数可记录为具有一个或多个可选参数。@racket[read] 函数就是此类函数的示例：

@nested[#:style 'inset
@defproc[#:link-target? #f
         (read [in input-port? (current-input-port)])
         any]
]

应用语法中包围 @racket[_in] 参数的方括号表示它是可选参数。

@racket[read] 的头部像往常一样为参数 @racket[_in] 指定 contract。在 contract 右侧，还指定了当 @racket[read] 无参数调用时使用的默认值 @racket[(current-input-port)]。

函数也可记录为接受强制或可选的基于 keyword 的参数。例如，@racket[sort] 函数有两个可选的基于 keyword 的参数：

@nested[#:style 'inset
@defproc[#:link-target? #f
         (sort [lst list?] [less-than? (any/c any/c . -> . any/c)]
               [#:key extract-key (any/c . -> . any/c) (lambda (x) x)]
               [#:cache-keys? cache-keys? boolean? #f]) list?]
]

包围 @racket[_extract-key] 和 @racket[_cache-keys?] 参数的方括号表示它们像之前一样是可选的。头部的 contract 部分显示为这些 keyword 参数提供的默认值。

@; ----------------------------------------
@section{结构类型文档符号约定}

@tech{structure type} 也使用 contract 符号约定记录：

@nested[#:style 'inset
@defstruct*[#:link-target? #f
            color ([red (and/c natural-number/c (<=/c 255))]
                   [green (and/c natural-number/c (<=/c 255))]
                   [blue (and/c natural-number/c (<=/c 255))]
                   [alpha (and/c natural-number/c (<=/c 255))])]
]

结构类型的排版方式如同在程序源代码中使用 @racket[struct] 形式声明。结构的每个字段使用对应的 contract 记录，该 contract 指定该字段接受的值。

在上面的示例中，结构类型 @racket[_color] 有四个字段：@racket[_red]、@racket[_green]、@racket[_blue] 和 @racket[_alpha]。该结构类型的构造函数接受满足 @racket[(and/c natural-number/c (<=/c 255))] 的字段值，即最大到 255 的非负精确整数。

在结构类型的文档中，字段名称后可能出现额外的 keyword：

@nested[#:style 'inset
@defstruct*[#:link-target? #f
            data-source
              ([connector (or/c 'postgresql 'mysql 'sqlite3 'odbc)]
               [args list?]
               [extensions (listof (list/c symbol? any/c))])
            #:mutable]
]

此处，@racket[#:mutable] keyword 表明 @racket[_data-source] 结构类型实例的字段可以使用其对应的 setter 函数修改。

@; ----------------------------------------
@section{参数文档符号约定}

@tech{parameter} 的文档记录方式与函数相同：

@nested[#:style 'inset
@defparam*[#:link-target? #f
           current-command-line-arguments
           argv
           (vectorof (and/c string? immutable?))
           (vectorof string?)]
]

由于 @tech{parameters} 可以被引用或设置，上述头部有两个条目。以无参数调用 @racket[current-command-line-arguments] 访问参数值，该值必须是其元素同时通过 @racket[string?] 和 @racket[immutable?] 的 vector。以单个参数调用 @racket[current-command-line-arguments] 设置参数值，其中值必须是其元素通过 @racket[string?] 的 vector（@tech{parameter} 上的 guard 会在必要时将字符串强制转换为不可变形式）。

@; ----------------------------------------
@section{其他文档符号约定}

某些库提供常量值的绑定。这些值使用单独的头部记录：

@nested[#:style 'inset
@defthing[#:link-target? #f object% class?]
]

@racketmodname[racket/class] 库提供 @racket[object%] 值，它是 Racket 中 class 层次的根。其文档头部仅表明它是满足 @racket[class?] 谓词的值。

