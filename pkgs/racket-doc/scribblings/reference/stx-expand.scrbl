#lang scribble/doc
@(require "mz.rkt")

@title{展开顶层形式}


@defproc[(expand [top-level-form any/c]
                 [insp inspector? (current-code-inspector)])
         syntax?]{

展开 @racket[top-level-form] 中所有非原始语法，并返回一个只包含核心形式（符合 @secref["fully-expanded"] 指定的语法）的 syntax object 的展开结果。

在 @racket[top-level-form] 被展开之前，其词法上下文通过 @racket[namespace-syntax-introduce] 进行丰富，如同 @racket[eval] 中一样。使用 @racket[syntax->datum] 将返回的 syntax object 转换为可打印的 datum。

如果 @racket[insp] 不是原始的 @tech{code inspector}（即 Racket 启动时 @racket[(current-code-inspector)] 的值），则结果是 @tech{tainted} syntax object。

在模块上使用 @racket[expand] 的示例：

@racketblock[
(parameterize ([current-namespace (make-base-namespace)])
 (expand
  (datum->syntax
   #f
   '(module foo scheme
      (define a 3)
      (+ a 4)))))  ; 展开模块主体
]

在非顶层形式上使用 @racket[expand] 的示例：

@racketblock[
(define-namespace-anchor anchor)
(parameterize ([current-namespace
                (namespace-anchor->namespace anchor)])
 (expand
  (datum->syntax
   #f
   '(delay (+ 1 2)))))  ; 展开 delay 表达式
]

@history[#:changed "8.2.0.4" @elem{添加了 @racket[insp] 参数和 taint 支持。}]}


@defproc[(expand-syntax [stx syntax?]
                        [insp inspector? (current-code-inspector)])
         syntax?]{

类似于 @racket[(expand stx insp)]，但参数必须是 @tech{syntax object}，
且其词法上下文在展开前不被丰富。

@history[#:changed "8.2.0.4" @elem{添加了 @racket[insp] 参数和 taint 支持。}]}


@defproc[(expand-once [top-level-form any/c]
                      [insp inspector? (current-code-inspector)])
         syntax?]{

部分展开 @racket[top-level-form]，返回一个用于部分展开表达式的 syntax object。
由于展开机制的局限性，某些上下文信息可能会丢失。特别是对结果调
用 @racket[expand-once] 可能产生与通过 @racket[expand] 展开不同的结果。

在 @racket[top-level-form] 展开之前，其词法上下文通过 @racket[namespace-syntax-introduce]
丰富，如 @racket[eval] 中一样。

@racket[insp] 参数决定结果是否为 @tech{tainted}，与 @racket[expand] 相同。

@history[#:changed "8.2.0.4" @elem{添加了 @racket[insp] 参数和 taint 支持。}]}


@defproc[(expand-syntax-once [stx syntax?]
                             [insp inspector? (current-code-inspector)])
         syntax?]{

类似于 @racket[(expand-once stx)]，但参数必须是 @tech{syntax object}，
且其词法上下文在展开前不被丰富。

@history[#:changed "8.2.0.4" @elem{添加了 @racket[insp] 参数和 taint 支持。}]}


@defproc[(expand-to-top-form [top-level-form any/c]
                             [insp inspector? (current-code-inspector)])
         syntax?]{

部分展开 @racket[top-level-form] 以显露最外层的语法形式。这种
部分展开主要用于检测顶层 @racket[begin] 的使用。与 @racket[expand-once]
的结果不同，使用 @racket[expand] 展开 @racket[expand-to-top-form] 的结
果会产生与使用 @racket[expand] 展开原始语法相同的结果。

在 @racket[stx-or-sexpr] 展开之前，其词法上下文通过 @racket[namespace-syntax-introduce]
丰富，如 @racket[eval] 中一样。

@racket[insp] 参数决定结果是否为 @tech{tainted}，与 @racket[expand] 相同。

@history[#:changed "8.2.0.4" @elem{添加了 @racket[insp] 参数和 taint 支持。}]}


@defproc[(expand-syntax-to-top-form [stx syntax?]
                                    [insp inspector? (current-code-inspector)])
         syntax?]{

类似于 @racket[(expand-to-top-form stx)]，但参数必须是 @tech{syntax object}，
且其词法上下文在展开前不被丰富。

@history[#:changed "8.2.0.4" @elem{添加了 @racket[insp] 参数和 taint 支持。}]}

@;------------------------------------------------------------------------
@section[#:tag "modinfo"]{展开模块的信息}

展开的 @racket[module] 声明信息存储在附加到 syntax object 的一组
@tech{syntax properties} 中（参见 @secref["stxprops"]）：

@itemize[

 @item{@indexed-racket['module-body-context] --- 一个 syntax
 object，其 @tech{lexical information} 对应模块内部，因此包括
 展开的 @tech{outside-edge scope} 和 @tech{inside-edge scope}；
 也就是说，syntax object 模拟一个存在于原始模块主体中、宏无法
 访问的标识符，因此其词法信息包括模块导入和定义的绑定。

 @history[#:added "6.4.0.1"]}

 @item{@indexed-racket['module-body-inside-context] --- 一个
 syntax object，其 @tech{lexical information} 对应一个没有词法上下文
 就开始并被移入宏的标识符，因此它仅包括展开的 @tech{inside-edge scope}。

 @history[#:added "6.4.0.1"]}

 @item{@indexed-racket['module-body-context-simple?] --- 一个布尔，
 @racket[#t] 表示模块主体的绑定（如 @racket['module-body-inside-context]
 属性的值的 @tech{lexical information} 中所记录的）可以直接从直接导入模块的模块中重
 构，包括导入的 for-syntax、for-meta 和 for-template。

 @history[#:added "6.4.0.1"]}

]

@history[#:changed "7.0" @elem{移除了 @racket['module-variable-provides]、
                               @racket['module-syntax-provides]、
                               @racket['module-indirect-provides]
                               和 @racket['module-indirect-for-meta-provides]
                               属性。}]
