#lang scribble/doc
@(require "mz.rkt" 
          scribble/bnf scribble/core
	  scribblings/private/docname
          (for-label (only-in racket/require-transform
                              make-require-transformer
                              current-require-module-path)
                     racket/require-syntax
                     racket/require
                     (only-in racket/provide-transform
                              make-provide-transformer)
                     racket/keyword-transform
                     racket/provide-syntax
                     racket/provide
                     racket/package
                     racket/splicing
                     racket/case
                     racket/runtime-path
                     racket/lazy-require
                     (only-in compiler/cm-accomplice
                              register-external-module)
                     racket/performance-hint
                     racket/unsafe/ops
                     syntax/parse))

@(define require-eval (make-base-eval))
@(define syntax-eval
   (lambda ()
     (let ([the-eval (make-base-eval)])
       (the-eval '(require (for-syntax racket/base)))
       the-eval)))
@(define meta-in-eval (syntax-eval))

@(define cvt (racketfont "CVT"))
@(define unquote-id (racket unquote))
@(define unquote-splicing-id (racket unquote-splicing))

@(define-syntax-rule (equiv-to-block b)
    (tabular #:style (make-style #f (list (make-table-columns
                                           (list (make-style #f '(baseline))
                                                 (make-style #f '(baseline))))))
             (list (list (para (hspace 2) " is equivalent to" (hspace 1))
                         (racketblock0 b)))))

@(define-syntax-rule (subeqivs [a0 b0] [a b] ...)
   (tabular (map
             list
             (apply
              append
              (list (list (racketblock a0)
                          (equiv-to-block b0))
                    (list (para 'nbsp)
                          (racketblock a)
                          (equiv-to-block b))
                    ...)))))

@title[#:tag "syntax" #:style 'toc]{语法形式}

本节描述完整展开表达式中出现的核心语法形式，以及许多密切相关的非核心形式。
核心语法参见 @secref["fully-expanded"]。

@local-table-of-contents[]

@;------------------------------------------------------------------------
@section[#:tag "module"]{模块：@racket[module]、@racket[module*] 等}

@guideintro["module-syntax"]{@racket[module]}

@defform[(module id module-path form ...)]{

声明一个顶层模块或 @tech{submodule}。对于顶层模块，如果设置了 @racket[current-module-declare-name] 参数，则参数值用作模块名称，忽略 @racket[id]；否则 @racket[(#,(racket quote) id)] 是声明的模块名称。对于 @tech{submodule}，@racket[id] 是子模块名称，用作 @racket[submod] 模块路径中的元素。@racket[module] 形式不允许出现在 @tech{expression context} 或 @tech{internal-definition context} 中。

@margin-note/ref{对于在顶层或模块体以外的定义上下文中工作的类似 @racket[module] 的形式，有 @racket[define-package]，但使用单独的模块或 @tech{submodule} 通常更好。}

@racket[module-path] 形式必须与 @racket[require] 中的形式相同，它为 @racket[form] 体提供初始绑定。也就是说，它被视为 @racket[form] 之前的一个 @racket[(require module-path)] 前缀，区别在于 @racket[module-path] 引入的绑定可以被模块体 @racket[form] 中的定义和 @racket[require] 遮蔽。

如果只提供了一个 @racket[form]，则它在 @tech{module-begin context} 中进行部分展开。如果展开结果为 @racket[#%plain-module-begin]，则 @racket[#%plain-module-begin] 的体就是模块的体。如果部分展开得到任何其他原始形式，则使用模块体的词法上下文将该形式包装为 @racketidfont{#%module-begin}；此标识符必须由初始的 @racket[module-path] 导入绑定，并且其展开必须产生 @racket[#%plain-module-begin] 来提供模块体。如果部分展开产生了 @racket[compiled-module-expression?] 意义上的编译模块，则该编译模块用于外层模块（跳过所有其他展开和编译步骤），但这样的结果仅在 @racket[syntax-local-compiling-module?] 返回 true 且当前 @tech{code inspector} 是初始检查器时才允许。最后，如果提供了多个 @racket[form]，则它们被包装为 @racketidfont{#%module-begin}，与单个 @racket[form] 未展开为 @racket[#%plain-module-begin] 的情况相同。

在包装之后（如果有）且在展开之前，会将一个 @indexed-racket['enclosing-module-name] 属性附加到 @racketidfont{#%module-begin} syntax object 上（参见 @secref["stxprops"]）；该属性的值是一个对应 @racket[id] 的符号。

每个 @racket[form] 在 @tech{module context} 中进行部分展开（参见 @secref["partial-expansion"]）。后续操作取决于形式的结构：

@itemize[

 @item{如果是 @racket[begin] 形式，则子形式被展平到模块体中，并立即在原地替代 @racket[begin] 进行处理。}

 @item{如果是 @racket[define-syntaxes] 形式，则右侧在 @tech{phase} 1 中进行求值，并且绑定立即被安装以用于模块内的进一步部分展开。右侧的求值会 @racket[parameterize] 设置 @racket[current-namespace]，如同 @racket[let-syntax] 中的设置。}

 @item{如果是 @racket[begin-for-syntax] 形式，则体在 @tech{phase} 1 中展开并求值。@racket[begin-for-syntax] 形式内的展开与 @racket[module] 体采用相同的部分展开过程，但在更高的 @tech{phase} 中进行，并保存所有 phase 的 @racket[#%provide] 形式直到 @racket[module] 展开结束。体的求值会 @racket[parameterize] 设置 @racket[current-namespace]，如同 @racket[let-syntax] 中的设置。}

 @item{如果形式是 @racket[#%require] 形式，则立即引入绑定，并且导入的模块被适当地 @tech{instantiate} 或 @tech{visit}。}

 @item{如果形式是 @racket[#%provide] 形式，则记录它在其余体之后处理。}

 @item{如果形式是 @racket[define-values] 形式，则立即安装绑定，但右侧表达式不会被进一步展开。}

 @item{如果形式是 @racket[module] 形式，则立即展开并在当前顶层外层模块展开期间声明。}

 @item{如果形式是 @racket[module*] 形式，则不会被进一步展开。}

 @item{类似地，如果形式是一个表达式，也不会被进一步展开。}

]

所有 @racket[form] 以这种方式部分展开之后，剩余的表达式形式（包括定义右侧的那些）在表达式上下文中展开。所有表达式形式之后，@racket[#%provide] 形式按照它们在展开后的模块中出现的顺序（与 @tech{phase} 无关）进行处理。最后，所有 @racket[module*] 形式按顺序展开，使得每个后续 @racket[module*] 形式都可以使用前一个；外层模块本身也可供 @racket[module*] @tech{submodules} 使用。

所有导入标识符的作用域覆盖整个模块体，除了嵌套的 @racket[module] 和 @racket[module*] 形式（在后一种情况下假设为非 @racket[#f] 的 @racket[module-path]）。模块体内定义的任何标识符的作用域同样覆盖整个模块体，除了这样的嵌套 @racket[module] 和 @racket[module*] 形式。语法定义的顺序不影响语法名称的作用域；@racket[A] 的 transformer 可以产生包含 @racket[B] 的表达式，而 @racket[B] 的 transformer 产生包含 @racket[A] 的表达式，无论 @racket[A] 和 @racket[B] 的声明顺序如何。但是，产生语法定义的语法形式必须在其使用之前定义。

在单个模块内的任何 @tech{phase level} 上，没有标识符可以被导入或定义多次，除非通过 @racket[define-values] 或 @racket[define-syntaxes] 的定义可以遮蔽通过 @racket[#%require] 的导入---只要前面的 @racket[#%declare] 形式不包含 @racket[#:require=defined]。每个导出的标识符必须被导入或定义。没有表达式可以引用 @tech{top-level variable}。如果 @racket[module*] 形式中外层模块的绑定可见（即嵌套的 @racket[module*] 使用 @racket[#f] 而非 @racket[module-path]），则可以定义或导入 @tech{shadow} 外层模块绑定的绑定。

对 @racket[module] 形式的求值不求值模块体中的表达式（除了有时重新声明的情况；参见 @secref["module-redeclare"]）。求值仅仅声明一个模块，其完整名称取决于 @racket[id] 或 @racket[(current-module-declare-name)]。

模块体仅在通过 @racket[require] 或 @racket[dynamic-require] 显式地 @techlink{instantiate} 模块时才执行。调用时，导入的模块按照它们被 @racket[require] 到模块中的顺序进行 instantiate（尽管较早的实例化或传递性 @racket[require] 可能会在给定模块内的顺序之前触发模块的 instantiate）。然后，表达式和定义按它们在模块中出现的顺序求值。每个表达式或定义的求值都包装在一个 continuation prompt 中（参见 @racket[call-with-continuation-prompt]），使用默认的 @tech{prompt tag} 和一个将参数重新 abort 并传播到下一个外层 prompt 的 prompt handler。每次定义求值后，在 prompt 之外检查定义的每个变量是否都有值；如果安装值的 prompt-delimited continuation 部分被跳过，则 @exnraise[exn:fail:contract:variable?]。

模块体在更高 phase level 上的部分与运行时部分类似地被分隔。例如，@racket[begin-for-syntax] 内的模块部分在模块展开时和被 visit 时都由 continuation prompt 分隔。@racket[define-syntaxes] 形式的求值被分隔，但与 @racket[define-values] 不同，没有检查语法定义是否完成。

在定义之前访问 @tech{module-level variable} 会发出运行时错误，就像访问未定义的全局变量一样。如果模块（在其完全展开形式中）不包含对模块内定义的标识符的 @racket[set!]，则该标识符在定义后是一个 @defterm{constant}；其后值不能更改，即使通过反射机制也不行。但是，@racket[compile-enforce-module-constants] 参数可用于禁用常量强制。

当代表 @racket[module] 形式的 @tech{syntax object} 附带有 @indexed-racket['module-language] @tech{syntax property}，并且属性值是一个包含三个元素的 vector，其中第一个是模块路径（@racket[module-path?] 意义上的），第二个是 symbol 时，该属性值会被保留在相应的编译和/或声明的模块中。vector 的第三个组件应该是可打印和 @racket[read] 的，以便它可以保存在序列化的 bytecode 中。@racketmodname[racket/base] 和 @racketmodname[racket] 语言将 @racket['#(racket/language-info get-info #f)] 附加到 @racket[module] 形式。另见 @racket[module-compiled-language-info]、@racket[module->language-info] 和 @racketmodname[racket/language-info]。

另见 @secref["module-eval-model"]、@secref["mod-parse"] 和 @secref["modinfo"]。

@examples[#:eval (syntax-eval) #:once
(module duck racket/base
  (provide num-eggs quack)
  (define num-eggs 2)
  (define (quack n)
    (unless (zero? n)
      (printf "quack\n")
      (quack (sub1 n)))))
]

@history[#:changed "6.3" @elem{Changed @racket[define-syntaxes]
                               and @racket[define-values] to
                               shadow any preceding import, and
                               dropped the use of @racket['submodule]
                               @tech{syntax property} values on nested
                               @racket[module] or @racket[module*]
                               forms.}]}


@defform*[((module* id module-path form ...)
           (module* id #f form ...))]{

@guideintro["submodules"]{@racket[module*]}

类似于 @racket[module]，但仅用于在模块内声明 @tech{submodule}，以及用于可以 @racket[require] 外层模块的子模块。

在 @racket[id] 之后使用 @racket[#f] 而不是 @racket[module-path]，表示外层模块的所有绑定在子模块中可见。在这种情况下，包装 @racket[module*] 形式的 @racket[begin-for-syntax] 形式会相对于子模块移动外层模块绑定的 @tech{phase level}。宏展开器通过移动 @racket[module*] 形式的 @tech{phase level} 使其体从 @tech{phase level} 0 开始来处理这种嵌套，展开后再恢复 @tech{phase level} 移动；请注意，此过程可能导致 @racket['origin] @tech{syntax property} 值中的 @tech{syntax objects} 与展开后的模块不同步。

当 @racket[module*] 形式有 @racket[module-path] 时，子模块展开从移除外层模块的 @tech{scopes} 开始，与 @racket[module] 形式相同。没有任何移动来补偿可能包装子模块的 @racket[begin-for-syntax] 形式。}


@defform[(module+ id form ...)]{

@guideintro["main-and-test"]{@racket[module+]}

声明和/或添加到名为 @racket[id] 的 @tech{submodule}。

@racket[id] 的每个添加在外层模块末尾按顺序组合成使用 @racket[(module* id #f ....)] 的完整子模块。如果给定的 @racket[id] 只有一个 @racket[module+]，则 @racket[(module+ id form ...)] 等价于 @racket[(module* id #f form ...)]，但仍会被移动到外层模块的末尾。

@racket[module*] 形式上键为 @indexed-racket['origin-form-srcloc] 的 @tech{syntax property} 记录了每个贡献的 @racket[module+] 形式的 @racket[srcloc]。

当模块包含多个使用 @racket[module+] 声明的子模块时，每个子模块的初始 @racket[module+] 声明的相对顺序决定了外层模块末尾的 @racket[module*] 声明的相对顺序。

子模块不能同时使用 @racket[module+] @emph{和} @racket[module] 或 @racket[module*] 定义。也就是说，如果子模块由 @racket[module+] 片段组成，则必须 @emph{仅} 由 @racket[module+] 片段组成。 }

@history[#:changed "8.9.0.1"
         @elem{Added @racket['origin-form-srcloc] syntax property.}]


@defform[(#%module-begin form ...)]{

仅在 @tech{module begin context} 中合法，由 @racket[module] 和 @racket[module*] 形式处理。

@racketmodname[racket/base] 的 @racket[#%module-begin] 形式包装每个顶层表达式，使用 @racket[current-print] 确定的 @tech{print handler} 打印非 @|void-const| 结果，并在打印后返回值。此打印作为 @racket[#%module-begin] 展开的一部分添加，因此 @racket[module] 本身添加的 prompt 在打印包装之外---这潜在地使打印后返回的值变得相关，因为 continuation 可以被捕获然后在不同的上下文中调用。

@racketmodname[racket/base] 的 @racket[#%module-begin] 形式还会声明一个 @racket[configure-runtime] 子模块（在任何其他 @racket[form] 之前），除非某些 @racket[form] 是即时的 @racket[module] 或名为 @racket[configure-runtime] 的 @racket[module*] 形式。如果添加了 @racket[configure-runtime] 子模块，该子模块会调用 @racketmodname[racket/runtime-config] 的 @racket[configure] 函数。}


@defform[(#%printing-module-begin form ...)]{

仅在 @tech{module begin context} 中合法。

类似于 @racket[#%module-begin]，但不添加 @racket[configure-runtime] 子模块。}


@defform[(#%plain-module-begin form ...)]{

仅在 @tech{module begin context} 中合法，由 @racket[module] 和 @racket[module*] 形式处理。}

@defform[(#%declare declaration-keyword ...)
         #:grammar
         ([declaration-keyword #:cross-phase-persistent
                               #:empty-namespace
                               #:require=define
                               #:flatten-requires
                               #:unlimited-compile
                               #:unsafe
                               (code:line #:realm identifier)])]{

影响模块运行时或反射属性的声明：

@itemlist[

 @item{@indexed-racket[#:cross-phase-persistent] --- 声明模块为 @tech{cross-phase persistent}，如果模块不满足 @seclink["cross-phase persistent-grammar"]{cross-phase persistent 模块的约束}，则报告语法错误。}

@item{@indexed-racket[#:empty-namespace] --- 声明此模块的 @racket[module->namespace] 应产生一个没有绑定的 namespace；以这种方式限制 namespace 支持可以减少原本必须为模块保留的 @tech{lexical information}。}

@item{@indexed-racket[#:require=define] --- 声明不允许模块体内的任何后续定义遮蔽 @racket[#%require]（或 @racket[require]）绑定。此声明不影响模块初始导入（即模块的语言）的遮蔽。}

@item{@indexed-racket[#:flatten-requires] --- 声明一个性能提示，即模块的编译形式应将传递性导入收集到一个单一的展平列表中，这可以在模块被 @tech{instantiate} 或通过 @racket[namespace-attach-module] 或 @racket[namespace-attach-module-declaration] 附加时提高性能。然而，当展平导入被应用于多个被另一个模块使用且具有重叠的传递性导入子树的模块时，可能会适得其反。}

@item{@indexed-racket[#:unlimited-compile] --- 声明对于特别大的模块体，编译不应回退到解释模式。否则，根据模块体的大小（转换为 @tech{linklet} 后）和 @envvar{PLT_CS_COMPILE_LIMIT} 环境变量（参见 @secref["cs-compiler-modes"]）选择编译模式。}

@item{@indexed-racket[#:unsafe] --- 声明模块可以在无需可能触发 @racket[exn:fail:contract] 的检查的情况下编译，对于本应引发 @racket[exn:fail:contract] 的求值，结果行为未定义；另见 @secref["unsafe"]。例如，@racket[car] 的使用可以被编译为 @racket[unsafe-car] 的使用，如果将 @racket[unsafe-car] 应用于非 pair，行为未定义。@racket[#:unsafe] 声明关键字仅在当前 @tech{code inspector} 是初始检查器时才允许。宏可以根据展开上下文生成有条件的不安全代码，通过展开为 @racket[(variable-reference-from-unsafe?
       (#%variable-reference))] 的使用。}

@item{@racket[@#,indexed-racket[#:realm] identifier] --- 声明模块及其内部的任何过程被赋予一个 @tech{realm}，即 @racket[identifier] 的符号形式，有效地覆盖 @racket[current-compile-realm] 的值。}

]

@racket[#%declare] 形式必须出现在 @tech{module context} 或 @tech{module-begin context} 中。每个 @racket[declaration-keyword] 在 @racket[module] 体内最多只能声明一次。

@history[#:changed "6.3" @elem{Added @racket[#:empty-namespace].}
         #:changed "7.9.0.5" @elem{Added @racket[#:unsafe].}
         #:changed "8.4.0.2" @elem{Added @racket[#:realm].}
         #:changed "8.6.0.9" @elem{Added @racket[#:require=define].}
         #:changed "8.13.0.4" @elem{Added @racket[#:flatten-requires].}
         #:changed "8.13.0.9" @elem{Added @racket[#:unlimited-compile].}]}


@;------------------------------------------------------------------------
@section[#:tag '("require" "provide")]{导入和导出：@racket[require] 和 @racket[provide]}

@section-index["modules" "imports"]
@section-index["modules" "exports"]

@guideintro["module-require"]{@racket[require]}

@defform/subs[#:literals (only-in prefix-in except-in rename-in lib file planet submod + - =
                          for-syntax for-template for-label for-meta only-meta-in combine-in 
                          relative-in quote for-space only-space-in)
              (require require-spec ...)
              ([require-spec module-path
                             (only-in require-spec id-maybe-renamed ...)
                             (except-in require-spec id ...)
                             (prefix-in prefix-id require-spec)
                             (rename-in require-spec [orig-id bind-id] ...)
                             (combine-in require-spec ...)
                             (relative-in module-path require-spec ...)
                             (only-meta-in phase-level require-spec ...)
                             (only-space-in space require-spec ...)
                             (for-syntax require-spec ...)
                             (for-template require-spec ...)
                             (for-label require-spec ...)
                             (for-meta phase-level require-spec ...)
                             (for-space space require-spec ...)
                             derived-require-spec]
               [module-path root-module-path
                            (submod root-module-path submod-path-element ...)
                            (submod "." submod-path-element ...)
                            (submod ".." submod-path-element ...)]
               [root-module-path (#,(racket quote) id)
                            rel-string
                            (lib rel-string ...+)
                            id
                            (file string)
                            (planet id)
                            (planet string)
                            (planet rel-string
                                    (user-string pkg-string vers)
                                    rel-string ...)]
               [submod-path-element id
                                    ".."]
               [id-maybe-renamed id
                                 [orig-id bind-id]]
               [phase-level exact-integer #f]
               [space id #f]
               [vers code:blank
                     nat
                     (code:line nat minor-vers)]
               [minor-vers nat
                           (nat nat)
                           ((unsyntax (racketidfont "=")) nat)
                           ((unsyntax (racketidfont "+")) nat)
                           ((unsyntax (racketidfont "-")) nat)])]{

在 @tech{top-level context} 中，@racket[require] @tech{instantiates} 模块（参见 @secref["module-eval-model"]）。在 @tech{top-level context} 或 @tech{module context} 中，@racket[require] 的展开 @tech{visits} 模块（参见 @secref["mod-parse"]）。在这两种上下文以及求值和展开中，@racket[require] 将绑定引入 @tech{namespace} 或模块（参见 @secref["intro-binding"]）。在 @tech{expression context} 或 @tech{internal-definition context} 中使用 @racket[require] 形式是语法错误。

@racket[require-spec] 指定了一组在导入上下文中绑定的特定标识符。每个标识符映射到特定模块的特定导出；要绑定的标识符可能与原始导出标识符的符号名不同。每个标识符还在特定的 @tech{phase level} 和 @tech{binding space} 中绑定。

在给定的 @tech{phase level} 和 @tech{binding space} 组合中，没有标识符可以通过导入被绑定多次，除非所有绑定都引用同一模块中的同一个原始定义。在 @tech{module context} 中，对于给定的 @tech{phase level} 和 @tech{binding space}，标识符可以被导入或被定义，但不能两者都是。

@racket[require-spec] 的语法可以通过 @racket[define-require-syntax] 扩展，当 @racket[require] 中指定了多个 @racket[require-spec] 时，每个 @racket[require-spec] 的绑定对后续 @racket[require-spec] 的展开可见。预定义形式（由 @racketmodname[racket/base] 导出）如下：

 @specsubform[module-path]{ 从命名模块导入所有导出的绑定，使用导出名称作为本地标识符。（关于 @racket[module-path] 的信息见下文。）@racket[module-path] 形式的词法上下文决定了引入标识符的上下文，为特定 @tech{binding space} 中的导出以及在每个导出的 @tech{phase level} 添加 space scope。

  如果 @racket[module-path] 提供的任何标识符的符号形式是 @tech{uninterned} 的，则该标识符不会被导入（即无法导入 uninterned 符号的绑定）。此限制旨在避免因模块是否已保存到文件而导致的编译差异（参见 @secref["print-compiled"]）。}

 @defsubform[(only-in require-spec id-maybe-renamed ...)]{
  类似于 @racket[require-spec]，但仅限于那些要绑定的标识符与 @racket[id-maybe-renamed] 匹配的导出：作为 @racket[_id] 或作为 @racket[[_orig-id _bind-id]] 中的 @racket[_orig-id]。当 @racket[id-maybe-renamed] 有 @racket[_bind-id] 时，@racket[_bind-id] 的词法上下文用于绑定。如果任何 @racket[id-maybe-renamed] 的 @racket[_id] 或 @racket[_orig-id] 不在 @racket[require-spec] 描述的集合中，则报告语法错误。

  @examples[#:eval (syntax-eval) #:once
    (require (only-in racket/tcp
	              tcp-listen
                      [tcp-accept my-accept]))
    tcp-listen
    my-accept
    (eval:error tcp-accept)
  ]}

 @defsubform[(except-in require-spec id ...)]{ 类似于 @racket[require-spec]，但省略那些 @racket[id] 是要绑定的标识符的导入；如果任何 @racket[id] 不在 @racket[require-spec] 描述的集合中，则报告语法错误。

  @examples[#:eval (syntax-eval) #:once
    (require (except-in racket/tcp
	                tcp-listen))
    tcp-accept
    (eval:error tcp-listen)
  ]}

 @defsubform[(prefix-in prefix-id require-spec)]{ 类似于 @racket[require-spec]，但通过在标识符前面加上 @racket[prefix-id] 来调整每个要绑定的标识符。@racket[prefix-id] 的词法上下文被忽略，而是保留前缀之前的标识符的上下文。

  @examples[#:eval (syntax-eval) #:once
    (require (prefix-in tcp: racket/tcp))
    tcp:tcp-accept
    tcp:tcp-listen
  ]

  @racket[require] 展开形式中的本地标识符上添加了键为 @indexed-racket['import-or-export-prefix-ranges] 的 @tech{syntax property}。

  @history[#:changed "8.9.0.5" @elem{Added the @racket['import-or-export-prefix-ranges]
                                     syntax property.}]}

 @defsubform[(rename-in require-spec [orig-id bind-id] ...)]{
  类似于 @racket[require-spec]，但将要绑定的 @racket[orig-id] 替换为 @racket[bind-id]。@racket[bind-id] 的词法上下文用于绑定。如果任何 @racket[orig-id] 不在 @racket[require-spec] 描述的集合中，则报告语法错误。
  
  @examples[#:eval (syntax-eval) #:once
    (require (rename-in racket/tcp
                        (tcp-accept accept)
			(tcp-listen listen)))
    accept
    listen
  ]}

 @defsubform[(combine-in require-spec ...)]{
  @racket[require-spec] 的并集。如果两个或更多来自 @racket[require-spec] 的导入具有相同的标识符名称但它们不引用相同的原始绑定，则报告语法错误。
  
  @examples[#:eval (syntax-eval) #:once
    (require (combine-in (only-in racket/tcp tcp-accept)
                         (only-in racket/tcp tcp-listen)))
    tcp-accept
    tcp-listen
  ]}

 @defsubform[(relative-in module-path require-spec ...)]{
  类似于 @racket[require-spec] 的并集，但 @racket[require-spec] 中的每个相对模块路径被视为相对于 @racket[module-path] 而非外层上下文。

  实现 @racket[relative-in] 的 @tech{require transformer} 设置 @racket[current-require-module-path] 来调整 @racket[require-spec] 中的模块路径。}

 @defsubform[(only-meta-in phase-level require-spec ...)]{
  类似于 @racket[require-spec] 的组合，但删除任何不属于 @racket[phase-level] 的绑定，其中 @racket[phase-level] 的 @racket[#f] 对应 @tech{label phase level}。
  
  The following example imports bindings only at @tech{phase level} 1,
  the transform phase:

  @examples[#:label #f #:eval meta-in-eval
  (module nest racket
    (provide (for-syntax meta-eggs)
             (for-meta 1 meta-chicks)
             num-eggs)
    (define-for-syntax meta-eggs 2)
    (define-for-syntax meta-chicks 3)
    (define num-eggs 2))

  (require (only-meta-in 1 'nest))

  (define-syntax (desc stx)
    (printf "~s ~s\n" meta-eggs meta-chicks)
    #'(void))

   (desc)
   (eval:error num-eggs)
  ]

  The following example imports only bindings at @tech{phase level} 0, the
  normal phase.

  @examples[#:label #f #:eval meta-in-eval
   (require (only-meta-in 0 'nest))
   num-eggs
  ]}

 @defsubform[(only-space-in space require-spec ...)]{
  类似于 @racket[require-spec] 的组合，但删除任何不由 @racket[space] 为 @tech{binding space} 标识符提供的绑定---@racket[space] 通常是一个标识符，但 @racket[space] 的 @racket[#f] 对应 @tech{default binding space}。

  @history[#:added "8.2.0.3"]}
  
 @specsubform[#:literals (for-meta)
              (for-meta phase-level require-spec ...)]{类似于 @racket[require-spec] 的组合，但每个 @racket[require-spec] 指定的绑定按 @racket[phase-level] 移动。@tech{label phase level} 对应 @racket[#f]，涉及 @racket[#f] 的移动组合产生 @racket[#f]。
  
  @examples[#:eval (syntax-eval) #:once
  (module nest racket
    (provide num-eggs)
    (define num-eggs 2))
  (require (for-meta 0 'nest))
  num-eggs
  (require (for-meta 1 'nest))
  (define-syntax (roost stx)
    (datum->syntax stx num-eggs))
  (roost)
  ]}

 @specsubform[#:literals (for-syntax)
              (for-syntax require-spec ...)]{等同于 @racket[(for-meta 1 require-spec ...)]。}

 @specsubform[#:literals (for-template)
              (for-template require-spec ...)]{等同于 @racket[(for-meta -1 require-spec ...)]。}

 @specsubform[#:literals (for-label)
              (for-label require-spec ...)]{等同于 @racket[(for-meta #f require-spec ...)]。如果任何 @racket[require-spec] 中的标识符在多个 phase level 上绑定，则报告语法错误。}

 @specsubform[#:literals (for-space)
              (for-space space require-spec ...)]{类似于 @racket[require-spec] 的组合，但每个 @racket[require-spec] 指定的绑定被移动到 @racket[space] 指定的 @tech{binding space}---@racket[space] 通常是一个标识符，但 @racket[space] 的 @racket[#f] 对应 @tech{default binding space}。

  通过移除 @racket[require-spec] 最初暗示的 space 的 scope（如果有）并添加 @racket[space] 的 scope（如果有），将绑定移动到新 space。

  @history[#:added "8.2.0.3"]}

 @specsubform[derived-require-spec]{关于扩展 @racket[require-spec] 形式集合的信息，参见 @racket[define-require-syntax]。}

@guideintro["module-paths"]{module paths}

@racket[module-path] 标识一个模块，可以是根模块，也可以是在另一个模块中以词法方式声明的 @tech{submodule}。根模块可以通过标识符形式的具体的名称来标识，也可以通过可触发模块声明自动加载的间接名称来标识。除了下面的 @racket[(#,(racket quote) id)] 情况外，根模块路径的实际解析取决于当前的 @tech{module name resolver}（参见 @racket[current-module-name-resolver]），下面的描述对应默认的 @tech{module name resolver}。

 @specsubform[#:literals (quote)
              (#,(racket quote) id)]{
 引用之前以名称 @racket[id] 声明的子模块或之前以名称 @racket[id] 交互式声明的模块。当 @racket[id] 引用子模块时，@racket[(#,(racket quote) id)] 等价于 @racket[(submod "." id)]。

 @examples[
 (code:comment @#,t{a module declared interactively as @racketidfont{test}:})
 (eval:alts (require '@#,racketidfont{test}) (void))]}

 @specsubform[rel-string]{相对于包含源文件的路径（由 @racket[current-load-relative-directory] 或 @racket[current-directory] 确定）。无论当前平台是什么，@racket[rel-string] 总是被解析为 Unix 格式的相对路径：@litchar{/} 是路径分隔符（不允许多个相邻的 @litchar{/}），@litchar{..} 访问父目录，@litchar{.} 访问当前目录。路径不能为空，也不能包含前导或尾随斜杠，最后一个之前的路径元素不能包含文件后缀（即除了 @litchar{.} 或 @litchar{..} 之外的 @litchar{.}），只允许的字符是 ASCII 字母、ASCII 数字、@litchar{-}、@litchar{+}、@litchar{_}、@litchar{.}、@litchar{/} 和 @litchar{%}。此外，@litchar{%} 仅在后面跟着两个小写十六进制数字时才允许，且数字必须形成一个不是字母、数字、@litchar{-}、@litchar{+} 或 @litchar{_} 的 ASCII 值的数字。

 @margin-note{@litchar{%} 规则旨在支持将任意字符串一对一编码为路径元素（在 UTF-8 编码之后）。此类编码不会被解码为文件名，而是在文件访问中保留。}

 如果 @racket[rel-string] 以 @filepath{.ss} 后缀结尾，则转换为 @filepath{.rkt} 后缀。如果 @filepath{.rkt} 文件不存在而 @filepath{.ss} 存在，@tech{compiled-load handler} 可能会反转该转换。

 @examples[
 (code:comment @#,t{a module named @filepath{x.rkt} in the same})
 (code:comment @#,t{directory as the enclosing module's file:})
 (eval:alts (require "x.rkt") (void))
 (code:comment @#,t{a module named @filepath{x.rkt} in the parent directory})
 (code:comment @#,t{of the enclosing module file's directory:})
 (eval:alts (require "../x.rkt") (void))]}

 @defsubform[(lib rel-string ...+)]{指向安装到 @tech{collection} 中的模块的路径（参见 @secref["collects"]）。@racket[lib] 中的 @racket[rel-string] 受到与普通 @racket[rel-string] 类似的约束。
 此外，@racket[rel-string] 不能包含 @litchar{.} 或 @litchar{..} 目录指示符。

 路径的具体解释取决于 @racket[rel-string] 的数量和形式：

 @itemize[

    @item{如果只提供了一个 @racket[rel-string]，且它由单个元素组成（即没有 @litchar{/}）且没有文件后缀（即没有 @litchar{.}），则 @racket[rel-string] 命名一个 @tech{collection}，@filepath{main.rkt} 是库文件名。

    @examples[
    (code:comment @#,t{the main @racketmodname[swindle #:indirect] library:})
    (eval:alts (require (lib "swindle")) (void))
    (code:comment @#,t{the same:})
    (eval:alts (require (lib "swindle/main.rkt")) (void))]}

    @item{如果只提供了一个 @racket[rel-string]，且它由多个 @litchar{/} 分隔的元素组成，则直到最后一个元素之前的每个元素命名一个 @tech{collection}、子 collection 等，最后一个元素命名一个文件。如果最后一个元素没有文件后缀，则添加 @filepath{.rkt}，而 @filepath{.ss} 后缀则转换为 @filepath{.rkt}。

    @examples[
     (code:comment @#,t{@filepath{turbo.rkt} from the @filepath{swindle} collection:})
     (eval:alts (require (lib "swindle/turbo")) (void))
     (code:comment @#,t{the same:})
     (eval:alts (require (lib "swindle/turbo.rkt")) (void))
     (code:comment @#,t{the same:})
     (eval:alts (require (lib "swindle/turbo.ss")) (void))]}

    @item{如果只提供了一个 @racket[rel-string]，且它由带有文件后缀的单个元素组成（即有 @litchar{.}），则 @racket[rel-string] 命名 @filepath{mzlib} @tech{collection} 中的一个文件。@filepath{.ss} 后缀转换为 @filepath{.rkt}。（此约定是为了与旧版 Racket 兼容。）

    @examples[
    (code:comment @#,t{@filepath{tar.rkt} module from the @filepath{mzlib} collection:})
    (eval:alts (require (lib "tar.ss")) (void))]}

    @item{否则，当提供多个 @racket[rel-string] 时，第一个 @racket[rel-string] 实际上移到其他之后，所有 @racket[rel-string] 用 @litchar{/} 分隔符连接。结果路径命名一个 @tech{collection}、子 collection 等，以文件名结尾。不会自动添加后缀，但 @filepath{.ss} 后缀转换为 @filepath{.rkt}。（此约定是为了与旧版 Racket 兼容。）

    @examples[
    (code:comment @#,t{@filepath{tar.rkt} module from the @filepath{mzlib} collection:})
    (eval:alts (require (lib "tar.ss" "mzlib")) (void))]}
  ]}

 @specsubform[id]{具有单个 @racket[_rel-string] 的 @racket[lib] 形式的简写，该字符串的字符与 @racket[id] 的符号形式相同。除了 @racket[lib] @racket[_rel-string] 的约束外，@racket[id] 不能包含 @litchar{.}。

 @examples[#:eval require-eval
   (eval:alts (require racket/tcp) (void))]}

 @defsubform[(file string)]{类似于普通的 @racket[rel-string] 情况，但 @racket[string] 是使用当前平台路径约定和 @racket[expand-user-path] 的路径---可能是绝对路径。@filepath{.ss} 后缀转换为 @filepath{.rkt}。 

 @examples[(eval:alts (require (file "~/tmp/x.rkt")) (void))]}

 @defsubform*[((planet id)
               (planet string)
               (planet rel-string (user-string pkg-string vers)
                       rel-string ...))]{

 指定可通过 @PLaneT 服务器获取的库。

 The first form is a shorthand for the last one, where the @racket[id]'s
 character sequence must match the following @nonterm{spec} grammar:

 @BNF[
 (list @nonterm{spec}
       (BNF-seq @nonterm{owner} @litchar{/} @nonterm{pkg} @nonterm{lib}))
 (list @nonterm{owner} @nonterm{elem})
 (list @nonterm{pkg}
       (BNF-alt @nonterm{elem} (BNF-seq @nonterm{elem} @litchar{:} @nonterm{version})))
 (list @nonterm{version}
       (BNF-alt @nonterm{int} (BNF-seq @nonterm{int} @litchar{:} @nonterm{minor})))
 (list @nonterm{minor}
       (BNF-alt @nonterm{int}
                (BNF-seq @litchar{<=} @nonterm{int})
                (BNF-seq @litchar{>=} @nonterm{int})
                (BNF-seq @litchar{=} @nonterm{int}))
       (BNF-seq @nonterm{int} @litchar{-} @nonterm{int}))
 (list @nonterm{lib} (BNF-alt @nonterm{empty} (BNF-seq @litchar{/} @nonterm{path})))
 (list @nonterm{path} (BNF-alt @nonterm{elem} (BNF-seq @nonterm{elem} @litchar{/} @nonterm{path})))
 ]

 and where an @nonterm{elem} is a non-empty sequence of characters
 that are ASCII letters, ASCII digits, @litchar{-}, @litchar{+},
 @litchar{_}, or @litchar{%} followed by lowercase hexadecimal digits
 (that do not encode one of the other allowed characters), and an
 @nonterm{int} is a non-empty sequence of ASCII digits. As this
 shorthand is expended, a @filepath{.plt} extension is added to
 @nonterm{pkg}, and a @filepath{.rkt} extension is added to
 @nonterm{path}; if no @nonterm{path} is included, @filepath{main.rkt}
 is used in the expansion.

 A @racket[(planet string)] form is like a @racket[(planet id)] form
 with the identifier converted to a string, except that the
 @racket[string] can optionally end with a file extension (i.e., a
 @litchar{.}) for a @nonterm{path}. A @filepath{.ss} file extension is
 converted to @filepath{.rkt}.

 In the more general last form of a @racket[planet] module path, the
 @racket[rel-string]s are similar to the @racket[lib] form, except
 that the @racket[(user-string pkg-string vers)] names a
 @|PLaneT|-based package instead of a @tech{collection}. A version
 specification can include an optional major and minor version, where
 the minor version can be a specific number or a constraint:
 @racket[(_nat _nat)] specifies an inclusive range, @racket[((unsyntax
 (racketidfont "=")) _nat)] specifies an exact match,
 @racket[((unsyntax (racketidfont "+")) _nat)] specifies a minimum
 version and is equivalent to just @racket[_nat], and
 @racket[((unsyntax (racketidfont "-")) _nat)] specifies a maximum
 version. The @racketidfont{=}, @racketidfont{+}, and @racketidfont{-}
 identifiers in a minor-version constraint are recognized
 symbolically.

 @examples[
 (code:comment @#,t{@filepath{main.rkt} in package @filepath{farm} by @filepath{mcdonald}:})
 (eval:alts (require (planet mcdonald/farm)) (void))
 (code:comment @#,t{@filepath{main.rkt} in version >= 2.0 of @filepath{farm} by @filepath{mcdonald}:})
 (eval:alts (require (planet mcdonald/farm:2)) (void))
 (code:comment @#,t{@filepath{main.rkt} in version >= 2.5 of @filepath{farm} by @filepath{mcdonald}:})
 (eval:alts (require (planet mcdonald/farm:2:5)) (void))
 (code:comment @#,t{@filepath{duck.rkt} in version >= 2.5 of @filepath{farm} by @filepath{mcdonald}:})
 (eval:alts (require (planet mcdonald/farm:2:5/duck)) (void))
 ]}

 @defsubform*[((submod root-module-path submod-path-element ...)
               (submod "." submod-path-element ...)
               (submod ".." submod-path-element ...))]{
  标识 @racket[root-module-path] 指定模块内的 @tech{submodule}，或在 @racket[(submod "." ....)] 情况下相对于当前模块，其中 @racket[(submod ".." submod-path-element ...)] 等价于 @racket[(submod "." ".." submod-path-element ...)]。子模块具有符号名称，作为 @racket[submod-path-element] 的标识符序列确定了使用给定名称的连续嵌套子模块的路径。@racket[".."] 作为 @racket[submod-path-element] 命名子模块的外层模块，旨在用于 @racket[(submod "." ....)] 和 @racket[(submod ".." ....)] 形式。}

当 @racket[require] 准备处理一系列 @racket[require-spec] 时，它会在 @racket['info] 级别向 @tech{current logger} 记录一条''prefetch''消息，使用名称 @racket['module-prefetch]，并包含一个由两个元素组成的列表作为消息数据：一个看起来被导入的 @tech{module paths} 列表，以及用于相对模块路径的目录路径。记录的模块路径列表可能不完整，但编译管理器可以使用近似的 prefetch 信息并行启动编译。

@history[#:changed "6.0.1.10" @elem{Added prefetch logging.}]}


@defform[(local-require require-spec ...)]{

类似于 @racket[require]，但用于 @tech{internal-definition context} 中仅导入到局部上下文中。只导入 @tech{phase level} 0 的绑定。

@examples[
  (let ()
    (local-require racket/control)
    fcontrol)
  (eval:error fcontrol)
]}


@guideintro["module-provide"]{@racket[provide]}

@defform/subs[#:literals (protect-out all-defined-out all-from-out rename-out 
                          except-out prefix-out struct-out for-meta combine-out
                          for-syntax for-label for-template for-space)
              (provide provide-spec ...)
              ([provide-spec id
                             (all-defined-out)
                             (all-from-out module-path ...)
                             (rename-out [orig-id export-id] ...)
                             (except-out provide-spec provide-spec ...)
                             (prefix-out prefix-id provide-spec)
                             (struct-out id)
                             (combine-out provide-spec ...)
                             (protect-out provide-spec ...)
                             (for-meta phase-level provide-spec ...)
                             (for-syntax provide-spec ...)
                             (for-template provide-spec ...)
                             (for-label provide-spec ...)
                             (for-space space provide-spec ...)
                             derived-provide-spec]
               [phase-level exact-integer #f]
               [space id #f])]{

声明模块的导出。@racket[provide] 形式必须出现在 @tech{module context} 或 @tech{module-begin context} 中。

@racket[provide-spec] 指示要提供的一个或多个绑定。对于每个导出的绑定，外部名称是一个符号，可能与模块内绑定的标识符的符号形式不同。此外，每个导出取自特定的 @tech{phase level} 并在相同的 @tech{phase level} 导出；默认情况下，相关的 phase level 是包围 @racket[provide] 形式的 @racket[begin-for-syntax] 形式的数量。最后，每个导出取自一个 @tech{binding space} 并在相同的 @tech{binding space} 导出。

@racket[provide-spec] 的语法可以通过绑定到 @tech{provide transformers} 或 @tech{provide pre-transformers} 来扩展，例如通过 @racket[define-provide-syntax]，但预定义形式如下。

 @specsubform[id]{ 导出 @racket[id]，它必须在相关的 @tech{phase level} 和 @tech{binding space} 在模块内被 @tech{bound}（即定义或导入）。@racket[id] 的符号形式用作外部名称，且定义或导入的标识符的符号形式必须匹配（否则外部名称可能含糊不清）。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (provide num-eggs)
     (define num-eggs 2))
   (require 'nest)
   num-eggs
 ]

 如果 @racket[id] 有到 @tech{rename transformer} 的 transformer 绑定，则该 transformer 影响导出的绑定。更多信息参见 @racket[make-rename-transformer]。}

 @defsubform[(all-defined-out)]{ 导出导出模块内相关 @tech{phase level} 上定义的、且与 @racket[(all-defined-out)] 形式具有相同词法上下文的所有标识符，排除目标标识符具有 @racket['not-provide-all-defined] @tech{syntax property} 的 @tech{rename transformers} 绑定。每个标识符的外部名称是标识符的符号形式。只有从 @racket[(all-defined-out)] 形式的词法上下文可访问的标识符才被包含；也就是说，宏引入的导入不会被重新导出，除非 @racket[(all-defined-out)] 形式是同时引入的。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (provide (all-defined-out))
     (define num-eggs 2))
   (require 'nest)
   num-eggs
 ]}

 @defsubform[(all-from-out module-path ...)]{ 导出使用基于每个 @racket[module-path]（参见 @secref["require"]）构建的 @racket[require-spec] 导入到导出模块中的所有标识符，没有 @tech{phase-level} 移动。导出的符号名称源自模块内绑定的名称，而不是每个 @racket[module-path] 的导出的符号名称。只有从 @racket[module-path] 的词法上下文可访问的标识符才被包含；也就是说，宏引入的导入不会被重新导出，除非 @racket[module-path] 是同时引入的。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (provide num-eggs)
     (define num-eggs 2))
   (module hen-house racket
     (require 'nest)
     (provide (all-from-out 'nest)))
   (require 'hen-house)
   num-eggs
 ]}

 @defsubform[(rename-out [orig-id export-id] ...)]{ 导出每个 @racket[orig-id]，它必须在相关的 @tech{phase level} 和 @tech{binding space} 内在模块中被 @tech{bound}。每个导出的符号名称是 @racket[export-id] 而不是 @racket[orig-id]。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (provide (rename-out [count num-eggs]))
     (define count 2))
   (require 'nest)
   num-eggs
   (eval:error count)
 ]}

 @defsubform[(except-out provide-spec provide-spec ...)]{ 类似于第一个 @racket[provide-spec]，但省略每个后续 @racket[provide-spec] 中列出的绑定。如果后一个绑定没有包含在初始 @racket[provide-spec] 中，则报告语法错误。后一个 @racket[provide-spec] 中的符号导出名称信息被忽略；只使用绑定。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (provide (except-out (all-defined-out)
			  num-chicks))
     (define num-eggs 2)
     (define num-chicks 3))
   (require 'nest)
   num-eggs
   (eval:error num-chicks)
 ]}

 @defsubform[(prefix-out prefix-id provide-spec)]{
 类似于 @racket[provide-spec]，但 @racket[provide-spec] 中的每个符号导出名称都以 @racket[prefix-id] 为前缀。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (provide (prefix-out chicken: num-eggs))
     (define num-eggs 2))
   (require 'nest)
   chicken:num-eggs
 ]
 
  @racket[provide] 展开形式中的导出标识符上添加了键为 @indexed-racket['import-or-export-prefix-ranges] 的 @tech{syntax property}。

  @history[#:changed "8.9.0.5" @elem{Added the @racket['import-or-export-prefix-ranges]
                                     syntax property.}]}

 @defsubform[(struct-out id)]{导出与结构类型 @racket[id] 关联的绑定。通常，@racket[id] 用 @racket[(struct id ....)] 绑定；更一般地，@racket[id] 必须在相关的 @tech{phase level} 上具有结构类型信息的 @tech{transformer} 绑定；参见 @secref["structinfo"]。此外，对于结构类型信息中提到的每个标识符，外层模块必须定义或导入一个 @racket[free-identifier=?] 的标识符。如果结构类型信息包含超类型标识符，并且该标识符具有结构类型信息的 @tech{transformer} 绑定，则超类型的 accessor 和 mutator 绑定 @italic{不} 被 @racket[struct-out] 包含在导出中。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (provide (struct-out egg))
     (struct egg (color wt)))
   (require 'nest)
   (egg-color (egg 'blue 10))
 ]}

 @defsubform[(combine-out provide-spec ...)]{ @racket[provide-spec] 的并集。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (provide (combine-out num-eggs num-chicks))
     (define num-eggs 2)
     (define num-chicks 1))
   (require 'nest)
   num-eggs
   num-chicks
 ]}

 @defsubform[(protect-out provide-spec ...)]{ 类似于 @racket[provide-spec] 的并集，但导出是 @tech{protected} 的：requiring 模块可以引用这些绑定，但不能在没有访问权限的情况下从宏展开中提取这些绑定或通过 @racket[eval] 访问它们。更多细节参见 @secref["modprotect"]。@racket[provide-spec] 必须只指定在导出模块内定义的绑定。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (provide num-eggs (protect-out num-chicks))
     (define num-eggs 2)
     (define num-chicks 3))
   (define weak-inspector (make-inspector (current-code-inspector)))
   (define (weak-eval x)
     (parameterize ([current-code-inspector weak-inspector])
       (define weak-ns (make-base-namespace))
       (namespace-attach-module (current-namespace)
                                ''nest
                                weak-ns)
       (parameterize ([current-namespace weak-ns])
         (namespace-require ''nest)
         (eval x))))
   (require 'nest)
   (list num-eggs num-chicks)
   (weak-eval 'num-eggs)
   (eval:error (weak-eval 'num-chicks))
 ]

 See also @secref["code-inspectors+protect" #:doc '(lib "scribblings/guide/guide.scrbl")].}

 @specsubform[#:literals (for-meta) 
              (for-meta phase-level provide-spec ...)]{ 类似于 @racket[provide-spec] 的并集，但调整为应用于 @racket[phase-level] 指定的相对于当前 phase level 的 @tech{phase level}（其中 @racket[#f] 对应 @tech{label phase level}）。特别地，作为 @racket[provide-spec] 的 @racket[_id] 或 @racket[rename-out] 形式引用相对于当前 level 的 @racket[phase-level] 上的绑定，@racket[all-defined-out] 仅导出相对于当前 phase level 的 @racket[phase-level] 上的定义，@racket[all-from-out] 导出通过 @racket[phase-level] 移动导入的绑定。

 @examples[#:eval (syntax-eval) #:once
   (module nest racket
     (begin-for-syntax
      (define eggs 2))
     (define chickens 3)
     (provide (for-syntax eggs)
              chickens))
   (require 'nest)
   (define-syntax (test-eggs stx)
     (printf "Eggs are ~a\n" eggs)
     #'0)
   (test-eggs)
   chickens

   (eval:error
    (module broken-nest racket
      (define eggs 2)
      (define chickens 3)
      (provide (for-syntax eggs)
               chickens)))

   (module nest2 racket
     (begin-for-syntax
      (define eggs 2))
     (provide (for-syntax eggs)))
   (require (for-meta 2 racket/base)
            (for-syntax 'nest2))
   (define-syntax (test stx)
     (define-syntax (show-eggs stx)
       (printf "Eggs are ~a\n" eggs)
       #'0)
     (begin
       (show-eggs)
       #'0))
   (test)
 ]}

 @specsubform[#:literals (for-syntax) 
              (for-syntax provide-spec ...)]{Same as
 @racket[(for-meta 1 provide-spec ...)].}

 @specsubform[#:literals (for-template) 
              (for-template provide-spec ...)]{Same as
 @racket[(for-meta -1 provide-spec ...)].}

 @specsubform[#:literals (for-label) 
              (for-label provide-spec ...)]{Same as
 @racket[(for-meta #f provide-spec ...)].}

 @specsubform[#:literals (for-space) 
              (for-space space provide-spec ...)]{ 类似于 @racket[provide-spec] 的并集，但调整为应用于 @racket[space] 指定的 @tech{binding space}---其中 @racket[space] 是一个标识符或 @racket[#f] 表示 @tech{default binding space}。特别地，作为 @racket[provide-spec] 的 @racket[_id] 或 @racket[rename-out] 形式引用 @racket[space] 中的绑定，@racket[all-defined-out] 仅导出 @racket[space] 中的定义，@racket[all-from-out] 导出导入到 @racket[space] 中的绑定。

 When providing a binding for a non-default binding space, normally a
 module should also provide a binding for the default binding space,
 where the default-space binding represents the intended meaning of
 the identifier. When a module later imports the same name in
 different spaces from modules that adhere to this convention, then if
 the two modules also (re)export the same binding for the name in the
 default space, the imports are likely consistent. If the two modules
 export different bindings for the name in the default space, then
 attempting to import both modules will trigger an error about
 conflicting imports, and a programmer can explicitly resolve the
 mismatch.

 @history[#:added "8.2.0.3"]}

 @specsubform[derived-provide-spec]{关于扩展 @racket[provide-spec] 形式集合的信息，参见 @racket[define-provide-syntax]。}

模块内指定的每个导出必须具有不同的符号导出名称，尽管同一个绑定可以用多个符号名称指定。}


@defform[(for-meta phase-level require-spec ...)]{See @racket[require] and @racket[provide].}
@defform[(for-syntax require-spec ...)]{See @racket[require] and @racket[provide].} @defform[(for-template require-spec ...)]{See @racket[require] and @racket[provide].}
@defform[(for-label require-spec ...)]{See @racket[require] and @racket[provide].}
@defform[(for-space space require-spec ...)]{See @racket[require] and @racket[provide].}

@defform/subs[(#%require raw-require-spec ...)
              ([raw-require-spec phaseless-spec
                                 (#,(racketidfont "for-meta") phase-level raw-require-spec ...)
                                 (#,(racketidfont "for-syntax") raw-require-spec ...)
                                 (#,(racketidfont "for-template") raw-require-spec ...)
                                 (#,(racketidfont "for-label") raw-require-spec ...)
                                 (#,(racketidfont "just-meta") phase-level raw-require-spec ...)
                                 (#,(racketidfont "portal") portal-id content)]
               [phase-level exact-integer
                            #f]
               [phaseless-spec spaceless-spec
                               (#,(racketidfont "for-space") space phaseless-spec ...)
                               (#,(racketidfont "just-space") space spaceless-spec ...)]
               [space id
                      #f]
               [spaceless-spec raw-module-path
                               (#,(racketidfont "only") raw-module-path id ...)
                               (#,(racketidfont "prefix") prefix-id raw-module-path)
                               (#,(racketidfont "all-except") raw-module-path id ...)
                               (#,(racketidfont "prefix-all-except") prefix-id 
                                                                     raw-module-path id ...)
                               (#,(racketidfont "rename") raw-module-path local-id exported-id)]
               [raw-module-path raw-root-module-path
                                (#,(racketidfont "submod") raw-root-module-path id ...+)
                                (#,(racketidfont "submod") "." id ...+)]
               [raw-root-module-path (#,(racketidfont "quote") id)
                                    rel-string
                                    (#,(racketidfont "lib") rel-string ...)
                                    id
                                    (#,(racketidfont "file") string)
                                    (#,(racketidfont "planet") rel-string
                                                               (user-string pkg-string vers ...))
                                    literal-path])]{

原始导入形式，@racket[require] 展开为此形式。@racket[raw-require-spec] 类似于 @racket[require] 形式中的 @racket[_require-spec]，但语法更受限、不可组合且不可扩展。此外，子形式名称如 @racketidfont{for-syntax} 和 @racketidfont{lib} 以符号方式识别，而非通过绑定。一些嵌套约束未在上述语法中形式化：

@itemlist[

 @item{@racketidfont{just-meta} 形式不能出现在 @racketidfont{just-meta} 形式内；}

 @item{@racketidfont{for-meta}、@racketidfont{for-syntax}、@racketidfont{for-template} 或 @racketidfont{for-label} 形式不能出现在 @racketidfont{for-meta}、@racketidfont{for-syntax}、@racketidfont{for-template} 或 @racketidfont{for-label} 形式内；}

 @item{@racketidfont{for-space} 形式不能出现在 @racketidfont{for-space} 形式内。}

 @item{@racketidfont{portal} 形式不能出现在 @racketidfont{just-meta} 形式内。}

]

除了 @racketidfont{portal} 形式外，每个 @racket[raw-require-spec] 对应明显的 @racket[_require-spec]，但 @racketidfont{rename} 子形式中的标识符顺序与 @racket[rename-in] 相反。

对于大多数 @racket[raw-require-spec]，@racket[raw-require-spec] 的词法上下文决定了引入标识符的上下文。例外是 @racketidfont{rename} 子形式，其中 @racket[local-id] 的词法上下文被保留。

作为 @racket[raw-root-module-path] 的 @racket[literal-path] 对应 @racket[path?] 意义上的路径。由于路径值永远不由 @racket[read-syntax] 产生，它们只出现在程序化构造的表达式中。它们也自然地作为 @racket[namespace-require] 等函数的参数出现，这些函数以其他方式接受带引号的 @racket[raw-module-spec]。

@racketidfont{portal} 形式提供了一种在任何 phase level 定义 @tech{portal syntax} 的方式。@racket[(#,(racketidfont "portal") portal-id content)] 将 @racket[portal-id] 定义为 portal syntax，@racket[content] 被有效地引用以作为其内容。

@history[#:changed "8.2.0.3" @elem{Added @racketidfont{for-space}
                                   and @racketidfont{just-space}.}
         #:changed "8.3.0.8" @elem{Added @racketidfont{portal}.}]}


@defform/subs[(#%provide raw-provide-spec ...)
              ([raw-provide-spec phaseless-spec
                                 (#,(racketidfont "for-meta") phase-level phaseless-spec ...)
                                 (#,(racketidfont "for-syntax") phaseless-spec ...)
                                 (#,(racketidfont "for-label") phaseless-spec ...)
                                 (#,(racketidfont "protect") raw-provide-spec ...)]
               [phase-level exact-integer
                            #f]
               [phaseless-spec spaceless-spec
                               (#,(racketidfont "for-space") space spaceless-spec ...)
                               (#,(racketidfont "protect") phaseless-spec ...)]
               [space id
                      #f]
               [spaceless-spec id 
                               (#,(racketidfont "rename") local-id export-id) 
                               (#,(racketidfont "struct") struct-id (field-id ...))
                               (#,(racketidfont "all-from") raw-module-path)
                               (#,(racketidfont "all-from-except") raw-module-path id ...)
                               (#,(racketidfont "all-defined"))
                               (#,(racketidfont "all-defined-except") id ...)
                               (#,(racketidfont "prefix-all-defined") prefix-id) 
                               (#,(racketidfont "prefix-all-defined-except") prefix-id id ...)
                               (#,(racketidfont "protect") spaceless-spec ...)
                               (#,(racketidfont "expand") (id . datum))
                               (#,(racketidfont "expand") (id . datum) orig-form)])]{

原始导出形式，@racket[provide] 展开为此形式。@racket[_raw-module-path] 与 @racket[#%require] 相同。@racketidfont{protect} 子形式不能出现在 @racket[protect] 子形式内。

与 @racket[#%require] 类似，@racket[#%provide] 的子形式关键字以符号方式识别，几乎每个 @racket[raw-provide-spec] 通过 @racket[provide] 都有明显的 @racket[_provide-spec] 等价形式，除了 @racketidfont{struct} 和 @racketidfont{expand} 子形式。

@racket[(#,(racketidfont "struct") struct-id (field-id ...))] 子形式展开为 @racket[struct-id]、@racketidfont{make-}@racket[struct-id]、@racketidfont{struct:}@racket[struct-id]、@racket[struct-id]@racketidfont{?}、每个 @racket[field-id] 的 @racket[struct-id]@racketidfont{-}@racket[field-id]，以及每个 @racket[field-id] 的 @racketidfont{set-}@racket[struct-id]@racketidfont{-}@racket[field-id]@racketidfont{!}。@racket[struct-id] 的词法上下文用于所有生成的标识符。

与 @racket[#%require] 不同，@racket[#%provide] 形式通过显式的 @racketidfont{expand} 子形式可进行宏扩展；@racket[(id . datum)] 部分作为表达式进行局部展开（即使它实际上不是表达式），当产生 @racket[begin] 形式时停止；如果展开结果是 @racket[(begin raw-provide-spec ...)]，则它被拼接到 @racketidfont{expand} 形式的位置，否则报告语法错误。如果提供了 @racket[orig-form] 部分，则在引发语法错误时使用它而不是 @racket[#%provide] 形式，例如''provide identifier is not defined''错误。@racketidfont{expand} 子形式通常不直接使用；它为实现 @racket[provide] 和 @tech{provide transformers} 提供了钩子。

@racketidfont{all-from} 和 @racketidfont{all-from-except} 形式仅重新导出在 @racketidfont{all-from} 或 @racketidfont{all-from-except} 形式本身的词法上下文中可访问的标识符。也就是说，宏引入的导入不会被重新导出，除非 @racketidfont{all-from} 或 @racketidfont{all-from-except} 形式是同时引入的。类似地，@racketidfont{all-defined} 及其变体只导出从 @racket[spaceless-spec] 形式的词法上下文可访问的定义。

@history[#:changed "8.2.0.3" @elem{Added @racketidfont{for-space}.}
         #:changed "8.2.0.5" @elem{Added @racket[orig-form] support
                                   to @racketidfont{expand}.}]}

@; --------------------

@subsection{额外的 @racket[require] 形式}

@note-lib-only[racket/require]

以下形式支持对导入标识符集进行更复杂的选择和操作。

@defform[(matching-identifiers-in regexp require-spec)]{

类似于 @racket[require-spec]，但仅包含名称匹配 @racket[regexp] 的导入。@racket[regexp] 必须是字面正则表达式（参见 @secref["regexp"]）。

@examples[#:eval (syntax-eval) #:once
(module zoo racket/base
  (provide tunafish swordfish blowfish
           monkey lizard ant)
  (define tunafish 1)
  (define swordfish 2)
  (define blowfish 3)
  (define monkey 4)
  (define lizard 5)
  (define ant 6))
(require racket/require)
(require (matching-identifiers-in #rx"\\w*fish" 'zoo))
tunafish
swordfish
blowfish
(eval:error monkey)
]}

@defform[(subtract-in require-spec subtracted-spec ...)]{

类似于 @racket[require-spec]，但省略那些会被某个 @racket[subtracted-spec] 导入的导入。

@examples[#:eval (syntax-eval) #:once
(module earth racket
  (provide land sea air)
  (define land 1)
  (define sea 2)
  (define air 3))

(module mars racket
  (provide aliens)
  (define aliens 4))

(module solar-system racket
  (require 'earth 'mars)
  (provide (all-from-out 'earth)
           (all-from-out 'mars)))

(require racket/require)
(require (subtract-in 'solar-system 'earth))
(eval:error land)
aliens
]}

@defform[(filtered-in proc-expr require-spec)]{ 

  对 @racket[require-spec] 的导入名称（作为字符串）应用任意转换。@racket[proc-expr] 必须在展开时求值为一个单参数过程，该过程应用于 @racket[require-spec] 中的每个名称。对于每个名称，过程必须返回一个字符串作为导入的新名称，或返回 @racket[#f] 以排除该导入。

  @margin-note{
    @racket[filtered-in] 的第二部分是在外层模块作用域中求值的展开时代码。因此，如果 @racketmodname[racket/base] 尚未以 @racket[for-syntax] 方式导入，大多数用法需要 @racket[(require (for-syntax racket/base))]。例如，@racket[@#,(hash-lang) @#,racketmodname[racket]] 自动建立此导入，而 @racket[@#,(hash-lang) @#,racketmodname[racket/base]] 则不建立。
  }

  例如，
  @racketblock[
    (require (filtered-in
              (lambda (name)
                (and (regexp-match? #rx"^[a-z-]+$" name)
                     (regexp-replace #rx"-" (string-titlecase name) "")))
              racket/base))]
  仅导入 @racketmodname[racket/base] 中匹配模式 @racket[#rx"^[a-z-]+$"] 的绑定，并将名称转换为驼峰命名法。}

@defform[(path-up rel-string ...)]{

类似直接使用 @racket[rel-string] 指定模块路径，但如果在相对于外层源文件的位置找不到所需的模块文件，则会在父目录中搜索，然后在上上级目录中搜索，以此类推，一直到根目录。发现的相对于外层源文件的路径成为展开后形式的一部分。

此形式在设置项目环境时很有用。例如，在项目根目录中使用以下 @filepath{config.rkt} 文件：
@racketmod[
  racket/base
  (require racket/require-syntax 
           (for-syntax "utils/in-here.rkt"))
  ;; require form for my utilities
  (provide utils-in)
  (define-require-syntax utils-in in-here-transformer)
]
并在同一根目录下使用 @filepath{utils/in-here.rkt}：
@racketmod[
  racket/base
  (require racket/runtime-path)
  (provide in-here-transformer)
  (define-runtime-path here ".")
  (define (in-here-transformer stx)
    (syntax-case stx ()
      [(_ sym)
       (identifier? #'sym)
       (let ([path (build-path here (format "~a.rkt" (syntax-e #'sym)))])
         (datum->syntax stx `(file ,(path->string path)) stx))]))
]
则 @racket[path-up] 适用于项目目录下的任何其他模块来查找 @filepath{config.rkt}：
@racketblock[
  (require racket/require 
           (path-up "config.rkt")
           (utils-in foo))]
请注意，示例中 requires 的顺序很重要，因为前两个中的每一个都绑定了后续使用的标识符。

在这种情况下，另一种选择是直接使用 @racket[path-up] 来查找工具模块：
@racketblock[
  (require racket/require 
           (path-up "utils/foo.rkt"))]
但是，名为 @filepath{utils} 的子目录会覆盖项目根目录中的那个。换句话说，前一种方法只需要一个唯一的名称。}

@defform/subs[(multi-in subs ...+)
              ([subs sub-path
                     (sub-path ...)]
               [sub-path rel-string
                         id])]{

指定要从目录或 collection 层次结构中 require 的多个文件。所需的模块路径集计算为 @racket[subs] 组的笛卡尔积，其中每个 @racket[sub-path] 按顺序使用 @litchar{/} 分隔符与其他 @racket[sub-path] 组合。作为 @racket[subs] 的 @racket[sub-path] 等价于 @racket[(sub-path)]。给定 @racket[multi-in] 形式中的所有 @racket[sub-path] 必须是字符串或标识符。

示例：

@subeqivs[
[(require (multi-in racket (dict @#,racketidfont{list})))
 (require racket/dict racket/list)]
[(require (multi-in "math" "matrix" "utils.rkt"))
 (require "math/matrix/utils.rkt")]
[(require (multi-in "utils" ("math.rkt" "matrix.rkt")))
 (require "utils/math.rkt" "utils/matrix.rkt")]
[(require (multi-in ("math" "matrix") "utils.rkt"))
 (require "math/utils.rkt" "matrix/utils.rkt")]
[(require (multi-in ("math" "matrix") ("utils.rkt" "helpers.rkt")))
 (require "math/utils.rkt" "math/helpers.rkt"
          "matrix/utils.rkt" "matrix/helpers.rkt")]
]}

@; --------------------

@subsection{额外的 @racket[provide] 形式}

@note-lib-only[racket/provide]

@defform[(matching-identifiers-out regexp provide-spec)]{ 类似于 @racket[provide-spec]，但仅包含外部名称匹配 @racket[regexp] 的绑定导出。@racket[regexp] 必须是字面正则表达式（参见 @secref["regexp"]）。}

@defform[(filtered-out proc-expr provide-spec)]{

 类似于 @racket[filtered-in]，但用于过滤和重命名导出。

  @margin-note{关于与 @racket[@#,(hash-lang) @#,racketmodname[racket/base]] 一起使用，参见 @racket[filtered-in] 的文档。}

  例如，
  @racketblock[
    (provide (filtered-out
              (lambda (name)
                (and (regexp-match? #rx"^[a-z-]+$" name)
                     (regexp-replace
                      #rx"-" (string-titlecase name) "")))
              (all-defined-out)))]
  仅导出匹配模式 @racket[#rx"^[a-z-]+$"] 的绑定，并将名称转换为驼峰命名法。}

@;------------------------------------------------------------------------
@section[#:tag "quote"]{字面量：@racket[quote] 和 @racket[#%datum]}

许多形式被隐式地作为字面量引用（通过 @racket[#%datum]）。更多信息参见 @secref["expand-steps"]。

@guideintro["quote"]{@racket[quote]}

@defform[(quote datum)]{

产生一个对应 @racket[datum]（即程序片段的表示）的常量值，但不包含其 @tech{lexical information}、源位置等。引用的 pairs、vectors 和 boxes 是不可变的。

@mz-examples[
(eval:alts (#,(racketkeywordfont "quote") x) 'x)
(eval:alts (#,(racketkeywordfont "quote") (+ 1 2)) '(+ 1 2))
(+ 1 2)
]

}

@defform[(#%datum . datum)]{

展开为 @racket[(#,(racketkeywordfont "quote") datum)]，只要 @racket[datum] 不是 keyword。如果 @racket[datum] 是 keyword，则报告语法错误。

关于展开器如何引入 @racketidfont{#%datum} 标识符的信息，另见 @secref["expand-steps"]。

@mz-examples[
(#%datum . 10)
(#%datum . x)
(eval:error (#%datum . #:x))
]
}

@;------------------------------------------------------------------------
@section[#:tag "#%expression"]{表达式包装器：@racket[#%expression]}

@defform[(#%expression expr)]{

产生与 @racket[expr] 相同的结果。使用 @racket[#%expression] 强制将形式解析为表达式。

@mz-examples[
(#%expression (+ 1 2))
(eval:error (#%expression (define x 10)))
]

@racket[#%expression] 形式在递归定义上下文中很有用，其中展开后续定义可以为当前表达式提供编译时信息。例如，考虑一个 @racket[define-sym-case] 宏，它简单地在给定标识符中记录一些编译时的符号。
@examples[#:label #f #:no-prompt #:eval meta-in-eval
(define-syntax (define-sym-case stx)
  (syntax-case stx ()
    [(_ id sym ...)
     (andmap identifier? (syntax->list #'(sym ...)))
     #'(define-syntax id
         '(sym ...))]))]
然后是 @racket[case] 的一个变体，它检查确保表达式中使用的符号与早期定义中给出的符号匹配：
@examples[#:label #f #:no-prompt #:eval meta-in-eval
(define-syntax (sym-case stx)
  (syntax-case stx ()
    [(_ id val-expr [(sym) expr] ...)
     (let ()
       (define expected-ids 
         (syntax-local-value 
          #'id
          (λ () 
            (raise-syntax-error 
             'sym-case
             "expected an identifier bound via define-sym-case"
             stx
             #'id))))
       (define actual-ids (syntax->datum #'(sym ...)))
       (unless (equal? expected-ids actual-ids)
         (raise-syntax-error 
          'sym-case
          (format "expected the symbols ~s"
                  expected-ids)
          stx))
       #'(case val-expr [(sym) expr] ...))]))]

如果定义像这样在 use 之后，则 @racket[define-sym-case] 宏没有机会绑定 @racket[id]，@racket[sym-case] 宏会发出错误：
@examples[#:label #f #:eval meta-in-eval
(eval:error
 (let () 
   (sym-case land-creatures 'bear
             [(bear) 1]
             [(fox) 2])
   (define-sym-case land-creatures bear fox)))
]
但如果 @racket[sym-case] 包装在 @racket[#%expression] 中，则展开器不需要展开它就能知道它是一个表达式，并继续处理 @racket[define-sym-case] 表达式。
@examples[#:label #f #:eval meta-in-eval
(let ()
  (#%expression (sym-case sea-creatures 'whale 
                          [(whale) 1]
                          [(squid) 2]))
  (define-sym-case sea-creatures whale squid)
  'more...)
]
当然，像 @racket[sym-case] 这样的宏不应该要求其客户端添加 @racket[#%expression]；相反，它应该检查其参数的基本形状，然后展开为包装在调用 @racket[syntax-local-value] 并完成展开的辅助宏周围的 @racket[#%expression]。
}

@;------------------------------------------------------------------------
@section[#:tag "#%top"]{变量引用和 @racket[#%top]}

@defform/none[id]{

引用顶层、模块级或局部绑定，当 @racket[id] 未绑定为 transformer 时（参见 @secref["expansion"]）。在运行时，该引用求值为与该绑定关联的 @tech{location} 中的值。

当展开器遇到未由模块级或局部绑定绑定的 @racket[id] 时，它将表达式转换为 @racket[(@#,racketidfont{#%top} . id)]，赋予 @racketidfont{#%top} @racket[id] 的词法上下文；通常，该上下文引用 @racket[#%top]。另见 @secref["expand-steps"]。

@examples[
(define x 10)
x
(let ([x 5]) x)
((lambda (x) x) 2)
]}


@defform[(#%top . id)]{

当 @racket[id] 绑定到模块级或顶层变量时，等价于 @racket[id]。在顶层上下文中，@racket[(#%top . id)] 始终引用顶层变量，即使 @racket[id] 是 @tech{unbound} 的或绑定到语法，只要 @racket[id] 没有局部绑定。在所有上下文中，如果 @racket[id] 有局部绑定，则 @racket[(#%top . id)] 是语法错误。

在 @racket[module] 形式内，只要 @racket[id] 在模块内定义且在其上下文中没有局部绑定，@racket[(#%top . id)] 就展开为 @racket[id]。在 @tech{phase level} 0 上，如果 @racket[id] 未绑定，则 @racket[(#%top . id)] 是立即的语法错误。在 @tech{phase level} 1 及以上，如果 @racket[id] 在 @racket[module] 体的 @tech{partial expansion} 结束前未在对应 phase 上定义，则报告语法错误。

关于展开器如何引入 @racketidfont{#%top} 标识符的信息，另见 @secref["expand-steps"]。

@examples[
(define x 12)
(#%top . x)
]

@history[#:changed "6.3" @elem{Changed the introduction of
                               @racket[#%top] in a top-level context
                               to @tech{unbound} identifiers only.}
         #:changed "8.2.0.7" @elem{Changed treatment of locally bound @racket[id] to
                                   always report a syntax error, even outside of a module.}]}

@;------------------------------------------------------------------------
@section{位置：@racket[#%variable-reference]}

@defform*[#:literals (#%top)
          [(#%variable-reference id)
           (#%variable-reference (#%top . id))
           (#%variable-reference)]]{

产生一个不透明的 @deftech{variable reference} 值，表示 @racket[id] 的 @tech{location}，该 @racket[id] 必须绑定为变量。如果没有提供 @racket[id]，则结果值引用外层上下文中定义的匿名变量（即在外层模块内，或者如果形式不在模块内则在顶层）。

当使用 @racket[(#%top . id)] 时，variable reference 引用与 @racket[(#%top . id)] 相同的变量。注意，如果 @racket[id] 是局部绑定的，或者如果 @racket[id] 在模块内绑定为 transformer，则不允许使用 @racket[(#%top . id)]。

A @tech{variable reference} can be used with
@racket[variable-reference->empty-namespace],
@racket[variable-reference->resolved-module-path], and
@racket[variable-reference->namespace], but facilities like
@racket[define-namespace-anchor] and
@racket[namespace-anchor->namespace] wrap those to provide a clearer
interface. A @tech{variable reference} is also useful to low-level
extensions; see @other-manual['(lib
"scribblings/inside/inside.scrbl")].

@history[#:changed "8.2.0.7" @elem{Changed @racket[#%top] treatment to be
                                   consistent with @racket[#%top] by itself.}]}

@;------------------------------------------------------------------------
@section[#:tag "application"]{过程应用和 @racket[#%app]}

@section-index{evaluation order}

@guideintro["application"]{procedure applications}

@defform/none[(proc-expr arg ...)]{

应用一个过程，当 @racket[proc-expr] 不是具有 transformer 绑定的标识符时（参见 @secref["expansion"]）。

更准确地说，展开器将此形式转换为 @racket[(@#,racketidfont{#%app} proc-expr arg ...)]，赋予 @racketidfont{#%app} 与原始形式关联的词法上下文（即组合 @racket[proc-expr] 及其参数的 pair）。通常，该 pair 的词法上下文指示下面描述的过程应用 @racket[#%app]。另见 @secref["expand-steps"]。

@mz-examples[
(+ 1 2)
((lambda (x #:arg y) (list y x)) #:arg 2 1)
]}

@defform[(#%app proc-expr arg ...)]{

应用一个过程。每个 @racket[arg] 是以下之一：

 @specsubform[arg-expr]{结果值是非关键字参数。}

 @specsubform[(code:line keyword arg-expr)]{结果值是使用 @racket[keyword] 的关键字参数。应用中的每个 @racket[keyword] 必须不同。}

@racket[proc-expr] 和 @racket[_arg-expr] 从左到右按顺序求值。如果 @racket[proc-expr] 的结果是一个过程，它接受与非 @racket[_keyword] @racket[_arg-expr] 数量相同的参数，接受应用中所有 @racket[_keyword] 的参数，且所有必需的关键字参数都在应用中的 @racket[_keyword] 中表示，则使用 @racket[arg-expr] 的值调用该过程。否则，@exnraise[exn:fail:contract]。

过程调用的 continuation 与应用表达式的 continuation 相同，因此过程的结果就是应用表达式的结果。

基于 @racket[_keyword] 的参数的相对顺序仅影响 @racket[_arg-expr] 求值的顺序；参数基于 @racket[_keyword] 而不是位置与所应用过程中的参数变量关联。相反，其他 @racket[_arg-expr] 值根据它们在应用形式中的顺序与变量关联。

关于展开器如何引入 @racketidfont{#%app} 标识符的信息，另见 @secref["expand-steps"]。

@mz-examples[
(#%app + 1 2)
(#%app (lambda (x #:arg y) (list y x)) #:arg 2 1)
(eval:error (#%app cons))
]}

@defform*[[(#%plain-app proc-expr arg-expr ...)
           (#%plain-app)]]{

类似于 @racket[#%app]，但不支持关键字参数。作为特殊情况，@racket[(#%plain-app)] 产生 @racket['()]。}

@;------------------------------------------------------------------------
@section[#:tag "lambda"]{过程表达式：@racket[lambda] 和 @racket[case-lambda]}

@guideintro["lambda"]{procedure expressions}

@deftogether[(
@defform[(lambda kw-formals body ...+)]
@defform/subs[(λ kw-formals body ...+)
              ([kw-formals (arg ...)
                           (arg ...+ . rest-id)
                           rest-id]
               [arg id
                    [id default-expr]
                    (code:line keyword id)
                    (code:line keyword [id default-expr])])]
)]{

产生一个过程。@racket[kw-formals] 决定过程接受的参数数量和哪些关键字参数。

仅考虑第一个 @racket[arg] 情况，简单 @racket[kw-formals] 有以下三种形式之一：

@specsubform[(id ...)]{ 过程接受与 @racket[id] 数量相同的非关键字参数值。每个 @racket[id] 按位置与参数值关联。}

@specsubform[(id ...+ . rest-id)]{ 过程接受任何大于等于 @racket[id] 数量的非关键字参数。当过程被应用时，@racket[id] 按位置与参数值关联，所有剩余参数放入一个列表中并与 @racket[rest-id] 关联。}

@specsubform[rest-id]{ 过程接受任何数量的非关键字参数。所有参数放入一个列表中并与 @racket[rest-id] 关联。}

更一般地，@racket[arg] 可以包含关键字和/或默认值。因此，上述前两种情况更完整地指定如下：

@specsubform[(arg ...)]{ 每个 @racket[arg] 有以下四种形式：

        @specsubform[id]{为过程接受的非关键字参数的最小和最大数量各添加一个。@racket[id] 按位置与实际参数关联。}

        @specsubform[[id default-expr]]{为过程接受的非关键字参数的最大数量添加一个。@racket[id] 按位置与实际参数关联，如果没有提供这样的参数，则对 @racket[default-expr] 求值以产生与 @racket[id] 关联的值。任何具有 @racket[default-expr] 的 @racket[arg] 不能出现在没有 @racket[default-expr] 且没有 @racket[keyword] 的 @racket[id] 之前。}

       @specsubform[(code:line keyword id)]{过程要求使用 @racket[keyword] 的关键字参数。@racket[id] 与使用 @racket[keyword] 的关键字实际参数关联。}

       @specsubform[(code:line keyword [id default-expr])]{过程接受使用 @racket[keyword] 的关键字参数。如果在应用中提供，@racket[id] 与使用 @racket[keyword] 的关键字实际参数关联；否则，对 @racket[default-expr] 求值以获得与 @racket[id] 关联的值。}

      @racket[_keyword] @racket[arg] 在 @racket[kw-formals] 中的位置无关紧要，但每个指定的 @racket[keyword] 必须不同。}

@specsubform[(arg ...+ . rest-id)]{ 与前一种情况类似，但过程接受超出其最小参数数量的任何非关键字参数。当提供的参数多于 @racket[arg] 中的非 @racket[_keyword] 参数时，额外参数放入一个列表中并与 @racket[rest-id] 关联。}

@margin-note{换句话说，具有默认值表达式的参数绑定类似于 @racket[let*] 进行求值。}
@racket[kw-formals] 标识符在 @racket[body] 中绑定。当过程被应用时，为每个标识符创建一个新的 @tech{location}，并用关联的参数值填充该 location。@tech{locations} 按顺序创建和填充，根据需要求值 @racket[_default-expr] 来填充 locations。

如果 @racket[body] 中出现任何不是 @racket[kw-formals] 中标识符的标识符，则它引用与出现在 @racket[lambda] 表达式位置时相同的 location。（换句话说，变量引用是词法作用域的。）

当 @racket[kw-formals] 中出现多个标识符时，它们必须根据 @racket[bound-identifier=?] 是互不相同的。

如果 @racket[lambda] 产生的过程被应用于少于或多于其接受的按位置或按关键字参数、不接受的按关键字参数，或缺少必需的按关键字参数，则 @exnraise[exn:fail:contract]。

最后一个 @racket[body] 表达式相对于过程体处于尾位置。

@mz-examples[
((lambda (x) x) 10)
((lambda (x y) (list y x)) 1 2)
((lambda (x [y 5]) (list y x)) 1 2)
(let ([f (lambda (x #:arg y) (list y x))])
 (list (f 1 #:arg 2)
       (f #:arg 2 1)))
]

当编译 @racket[lambda] 或 @racket[case-lambda] 表达式时，Racket 查找附加到表达式上的 @indexed-racket['method-arity-error] 属性（参见 @secref["stxprops"]）。如果存在且值为 true，并且过程没有任何 case 接受零个参数，则该过程被标记，使得涉及该过程的 @racket[exn:fail:contract:arity] 异常会隐藏第一个参数（如果提供了的话）。（当过程实现一个方法时，隐藏第一个参数很有用，因为在原始源代码中第一个参数是隐式的。）该属性仅影响 @racket[exn:fail:contract:arity] 异常的格式，不影响 @racket[procedure-arity] 的结果。

类似地，Racket 在编译 @racket[lambda] 或 @racket[case-lambda] 表达式时查找 @indexed-racket['body-as-unsafe] 属性。如果存在且值为 true，则过程体可以以与 @racket[(#%declare #:unsafe)] 相同意义上的不安全模式编译。@indexed-racket['body-as-unsafe] 属性仅在编译时当前 @tech{code inspector} 是初始检查器时才允许。

当接受关键字参数的过程以某种方式绑定到标识符，并且该标识符用于应用形式的函数位置时，应用形式可能会以掩盖原始绑定作为应用目标的方式展开。为了帮助暴露函数应用和函数声明之间的联系，函数应用展开中的一个标识符被标记了可通过 @racket[syntax-procedure-alias-property] 访问的 @tech{syntax property}，如果它实际上是原始标识符的别名的话。展开中的一个标识符被标记了可通过 @racket[syntax-procedure-converted-arguments-property] 访问的 @tech{syntax property}，如果它类似于原始标识符，但参数被转换为展平形式：关键字参数、必需的按位置参数、按位置可选参数和 rest 参数---全部作为必需的按位置参数；关键字参数按关键字名称排序，每个可选关键字参数后跟一个布尔值以指示是否提供了值，@racket[#f] 用于值未提供的可选关键字参数；可选按位置参数为每个未提供的参数包含 @racket[#f]，然后可选参数值序列后跟并行的布尔值序列以指示每个可选参数值是否已提供。

@history[#:changed "8.13.0.5" @elem{
Adjusted binding so that @racket[(free-identifier=? #'λ #'lambda)] produces
@racket[#t].
}
         #:changed "8.15.0.12" @elem{Added the @racket['body-as-unsafe] property.}]
}


@deftogether[(
@defform[(case-lambda [formals body ...+] ...)]
@defform/subs[(case-λ [formals body ...+] ...)
              ([formals (id ...)
                        (id ...+ . rest-id)
                        rest-id])]
)]{

产生一个过程。每个 @racket[[formals body ...+]] 子句类似于单个 @racket[lambda] 过程；应用 @racket[case-lambda] 生成的过程与应用对应某个子句的过程相同---第一个接受给定参数数量的过程。如果没有相应的过程接受给定参数数量，则 @exnraise[exn:fail:contract]。

注意，@racket[case-lambda] 子句仅支持 @racket[formals]，不支持 @racket[lambda] 更通用的 @racket[_kw-formals]。也就是说，@racket[case-lambda] 不直接支持关键字参数和可选参数。

@mz-examples[
(let ([f (case-lambda
          [() 10]
          [(x) x]
          [(x y) (list y x)]
          [r r])])
  (list (f)
        (f 1)
        (f 1 2)
        (f 1 2 3)))
]

@history[#:changed "8.13.0.5" @elem{Added @racket[case-λ].}]
}

@defform[(#%plain-lambda formals body ...+)]{
类似于 @racket[lambda]，但不支持关键字参数或可选参数。
}

@;------------------------------------------------------------------------
@section[#:tag "let"]{局部绑定：@racket[let]、@racket[let*]、@racket[letrec] 等}

@guideintro["let"]{local binding}

@defform*[[(let ([id val-expr] ...) body ...+)
           (let proc-id ([id init-expr] ...) body ...+)]]{

第一种形式从左到右求值 @racket[val-expr]，为每个 @racket[id] 创建一个新的 @tech{location}，并将值放入 locations 中。然后求值 @racket[body]，其中 @racket[id] 被绑定。最后一个 @racket[body] 表达式相对于 @racket[let] 形式处于尾位置。@racket[id] 必须根据 @racket[bound-identifier=?] 互不相同。

@mz-examples[
(let ([x 5]) x)
(let ([x 5])
  (let ([x 2]
        [y x])
    (list y x)))
]

第二种形式通常称为 @deftech{named @racket[let]}，求值 @racket[init-expr]；结果值成为过程 @racket[(lambda (id ...) body ...+)] 应用中的参数，其中 @racket[proc-id] 在 @racket[body] 中绑定到过程本身。}

@mz-examples[
(let fac ([n 10])
  (if (zero? n)
      1
      (* n (fac (sub1 n)))))
]

@defform[(let* ([id val-expr] ...) body ...+)]{

类似于 @racket[let]，但逐个求值 @racket[val-expr]，一旦值可用就为每个 @racket[id] 创建 @tech{location}。@racket[id] 在剩余的 @racket[val-expr] 以及 @racket[body] 中绑定，@racket[id] 不需要互不相同；后面的绑定遮蔽前面的绑定。

@mz-examples[
(let* ([x 1]
       [y (+ x 1)])
  (list y x))
]}

@defform[(letrec ([id val-expr] ...) body ...+)]{

类似于 @racket[let]，包括从左到右求值 @racket[val-expr]，但所有 @racket[id] 的 @tech{locations} 首先被创建，所有 @racket[id] 在所有 @racket[val-expr] 以及 @racket[body] 中绑定，每个 @racket[id] 在相应的 @racket[val-expr] 求值后立即初始化。@racket[id] 必须根据 @racket[bound-identifier=?] 互不相同。

在初始化之前引用或赋值 @racket[id] 会引发 @racket[exn:fail:contract:variable]。如果 @racket[id]（即绑定实例或 @racket[id]）具有值为 symbol 的 @indexed-racket['undefined-error-name] @tech{syntax property}，则该 symbol 用作错误报告中的变量名称，而不是 @racket[id] 的符号形式。

@mz-examples[
(letrec ([is-even? (lambda (n)
                     (or (zero? n)
                         (is-odd? (sub1 n))))]
         [is-odd? (lambda (n)
                    (and (not (zero? n))
                         (is-even? (sub1 n))))])
  (is-odd? 11))
]

@history[#:changed "6.0.1.2" @elem{Changed reference or assignment of an uninitialized @racket[id] to an error.}]}

@defform[(let-values ([(id ...) val-expr] ...) body ...+)]{ 类似于 @racket[let]，但每个 @racket[val-expr] 必须产生与相应 @racket[id] 数量相同的值，否则 @exnraise[exn:fail:contract]。为每个 @racket[id] 创建单独的 @tech{location}，所有这些在 @racket[body] 中绑定。

@mz-examples[
(let-values ([(x y) (quotient/remainder 10 3)])
  (list y x))
]}

@defform[(let*-values ([(id ...) val-expr] ...) body ...+)]{ 类似于 @racket[let*]，但每个 @racket[val-expr] 必须产生与相应 @racket[id] 数量相同的值。为每个 @racket[id] 创建单独的 @tech{location}，所有这些在后面的 @racket[val-expr] 和 @racket[body] 中绑定。

@mz-examples[
(let*-values ([(x y) (quotient/remainder 10 3)]
              [(z) (list y x)])
  z)
]}

@defform[(letrec-values ([(id ...) val-expr] ...) body ...+)]{ 类似于 @racket[letrec]，但每个 @racket[val-expr] 必须产生与相应 @racket[id] 数量相同的值。为每个 @racket[id] 创建单独的 @tech{location}，所有这些在所有 @racket[val-expr] 和 @racket[body] 中绑定。

@mz-examples[
(letrec-values ([(is-even? is-odd?)
                 (values
                   (lambda (n)
                     (or (zero? n)
                         (is-odd? (sub1 n))))
                   (lambda (n)
                     (or (= n 1)
                         (is-even? (sub1 n)))))])
  (is-odd? 11))
]}

@defform[(let-syntax ([id trans-expr] ...) body ...+)]{

@margin-note/ref{See also @racket[splicing-let-syntax].}

为每个 @racket[id] 创建一个 @tech{transformer} 绑定（参见 @secref["transformer-model"]），其值为 @racket[trans-expr]，该表达式相对于外层上下文处于 @tech{phase level} 1。（关于 @tech{phase levels} 的信息，参见 @secref["id-model"]。）

每个 @racket[trans-expr] 的求值被 @racket[parameterize] 设置 @racket[current-namespace] 为一个 @tech{namespace}，该 namespace 与用于展开 @racket[let-syntax] 形式的 namespace 共享 @tech{bindings} 和 @tech{variables}，但其 @tech{base phase} 大一级。

每个 @racket[id] 在 @racket[body] 中绑定，而不在其他 @racket[trans-expr] 中绑定。}

@defform[(letrec-syntax ([id trans-expr] ...) body ...+)]{

@margin-note/ref{See also @racket[splicing-letrec-syntax].}

类似于 @racket[let-syntax]，但每个 @racket[id] 还在所有 @racket[trans-expr] 中绑定。}

@defform[(let-syntaxes ([(id ...) trans-expr] ...) body ...+)]{

@margin-note/ref{See also @racket[splicing-let-syntaxes].}

类似于 @racket[let-syntax]，但每个 @racket[trans-expr] 必须产生与相应 @racket[id] 数量相同的值，每个值绑定到相应的值。}

@defform[(letrec-syntaxes ([(id ...) trans-expr] ...) body ...+)]{

@margin-note/ref{See also @racket[splicing-letrec-syntaxes].}

类似于 @racket[let-syntax]，但每个 @racket[id] 还在所有 @racket[trans-expr] 中绑定。}

@defform[(letrec-syntaxes+values ([(trans-id ...) trans-expr] ...)
                                 ([(val-id ...) val-expr] ...)
            body ...+)]{

将 @racket[letrec-syntaxes] 与 @racket[letrec-values] 的变体结合：每个 @racket[trans-id] 和 @racket[val-id] 在所有 @racket[trans-expr] 和 @racket[val-expr] 中绑定。

@racket[letrec-syntaxes+values] 形式是局部编译时绑定的核心形式，因为像 @racket[letrec-syntax] 和 @tech{internal-definition contexts} 这样的形式展开为此形式。在完全展开的表达式（参见 @secref["fully-expanded"]）中，@racket[trans-id] 绑定被丢弃，形式归约为 @racket[letrec-values] 或 @racket[let-values] 的组合。

对于由 @racket[letrec-syntaxes+values] 绑定的变量，@tech{location} 创建规则与 @racket[letrec-values] 略有不同。@racket[[(val-id ...) val-expr]] 绑定子句被划分为满足以下规则的最小子句集合：如果一个子句有被前面子句的 @racket[val-expr]（在完全展开中）引用的 @racket[val-id] 绑定，则这两个子句及其之间的所有子句在同一集合中。如果一个集合由单个子句组成，其 @racket[val-expr] 不引用该子句的任何 @racket[val-id]，则 @racket[val-id] 的 @tech{locations} 在 @racket[val-expr] 求值 @emph{之后} 创建。否则，集合中所有 @racket[val-id] 的 @tech{locations} 在集合中第一个 @racket[val-expr] 求值之前创建。为了形成集合的目的，@racket[(quote-syntax _datum #:local)] 形式计为对 @racket[letrec-syntaxes+values] 形式中所有绑定的引用。

@tech{location} 创建规则的最终结果是，作用域和求值顺序与 @racket[letrec-values] 相同，但编译器有更多自由来优化掉 @tech{location} 创建。这些规则还对应于 @racket[let-values] 和 @racket[letrec-values] 的嵌套，这就是 @racket[letrec-syntaxes+values] 用于完全展开表达式时的方式。

另见 @racket[local]，它支持使用 @racket[define]、@racket[define-syntax] 等的局部绑定。}

@;------------------------------------------------------------------------
@section[#:tag "local"]{局部定义：@racket[local]}

@note-lib[racket/local]

@defform[(local [definition ...] body ...+)]{

类似于 @racket[letrec-syntaxes+values]，但绑定以与顶层或模块体中相同的方式表达：使用 @racket[define]、@racket[define-values]、@racket[define-syntax]、@racket[struct] 等。通过部分展开 @racket[definition] 形式来区分定义和非定义（参见 @secref["partial-expansion"]）。与在顶层或模块体中一样，@racket[begin] 包装的序列被拼接到 @racket[definition] 序列中。}

@;------------------------------------------------------------------------
@include-section["shared.scrbl"]

@;------------------------------------------------------------------------
@section[#:tag "if"]{条件语句：@racket[if]、@racket[cond]、@racket[and] 和 @racket[or]}

@guideintro["conditionals"]{conditionals}

@defform[(if test-expr then-expr else-expr)]{

求值 @racket[test-expr]。如果它产生除 @racket[#f] 之外的任何值，则求值 @racket[then-expr]，其结果即为 @racket[if] 形式的结果。否则，求值 @racket[else-expr]，其结果即为 @racket[if] 形式的结果。@racket[then-expr] 和 @racket[else-expr] 相对于 @racket[if] 形式处于尾位置。

@mz-examples[
(if (positive? -5) (error "doesn't get here") 2)
(if (positive? 5) 1 (error "doesn't get here"))
(if 'we-have-no-bananas "yes" "no")
]}

@defform/subs[#:literals (else =>)
              (cond cond-clause ...)
              ([cond-clause [test-expr then-body ...+]
                            [else then-body ...+]
                            [test-expr => proc-expr]
                            [test-expr]])]{

@guideintro["cond"]{@racket[cond]}

以 @racket[else] 开头的 @racket[cond-clause] 必须是最后一个 @racket[cond-clause]。

如果没有 @racket[cond-clause]，结果是 @|void-const|。

如果只有 @racket[[else then-body ...+]]，则求值 @racket[then-body]。除最后一个之外的所有 @racket[then-body] 的结果被忽略。最后一个 @racket[then-body] 的结果是整个 @racket[cond] 形式的结果，该 @racket[then-body] 相对于 @racket[cond] 形式处于尾位置。

否则，求值第一个 @racket[test-expr]。如果它产生 @racket[#f]，则结果与包含剩余 @racket[cond-clause] 的 @racket[cond] 形式相同，相对于原始 @racket[cond] 形式处于尾位置。否则，求值取决于 @racket[cond-clause] 的形式：

@specsubform[[test-expr then-body ...+]]{@racket[then-body] 按顺序求值，除最后一个之外的所有 @racket[then-body] 的结果被忽略。最后一个 @racket[then-body] 的结果提供整个 @racket[cond] 形式的结果，该 @racket[then-body] 相对于 @racket[cond] 形式处于尾位置。}

@specsubform[#:literals (=>) [test-expr => proc-expr]]{求值 @racket[proc-expr]，它必须产生一个接受一个参数的过程，否则 @exnraise[exn:fail:contract]。该过程以相对于 @racket[cond] 表达式处于尾位置的方式应用于 @racket[test-expr] 的结果。}

@specsubform[[test-expr]]{@racket[test-expr] 的结果作为 @racket[cond] 形式的结果返回。@racket[test-expr] 不处于尾位置。}

@mz-examples[
(cond)
(cond
  [else 5])
(cond
 [(positive? -5) (error "doesn't get here")]
 [(zero? -5) (error "doesn't get here, either")]
 [(positive? 5) 'here])
(cond
 [(member 2 '(1 2 3)) => (lambda (l) (map - l))])
(cond
 [(member 2 '(1 2 3))])
]}


@defidform[else]{

在像 @racket[cond] 这样的形式中被特别识别。作为表达式的 @racket[else] 形式是语法错误。}


@defidform[=>]{

在像 @racket[cond] 这样的形式中被特别识别。作为表达式的 @racket[=>] 形式是语法错误。}


@defform[(and expr ...)]{

@guideintro["and+or"]{@racket[and]}

如果没有提供 @racket[expr]，则结果为 @racket[#t]。

如果只提供了一个 @racket[expr]，则它处于尾位置，因此 @racket[and] 表达式的结果就是 @racket[expr] 的结果。

否则，求值第一个 @racket[expr]。如果它产生 @racket[#f]，则 @racket[and] 表达式的结果为 @racket[#f]。否则，结果与包含剩余 @racket[expr] 的 @racket[and] 表达式相同，相对于原始 @racket[and] 形式处于尾位置。

@mz-examples[
(and)
(and 1)
(and (values 1 2))
(and #f (error "doesn't get here"))
(and #t 5)
]}

@defform[(or expr ...)]{

@guideintro["and+or"]{@racket[or]}

如果没有提供 @racket[expr]，则结果为 @racket[#f]。

如果只提供了一个 @racket[expr]，则它处于尾位置，因此 @racket[or] 表达式的结果就是 @racket[expr] 的结果。

否则，求值第一个 @racket[expr]。如果它产生除 @racket[#f] 之外的值，则该结果即为 @racket[or] 表达式的结果。否则，结果与包含剩余 @racket[expr] 的 @racket[or] 表达式相同，相对于原始 @racket[or] 形式处于尾位置。

@mz-examples[
(or)
(or 1)
(or (values 1 2))
(or 5 (error "doesn't get here"))
(or #f 5)
]}

@;------------------------------------------------------------------------
@section[#:tag "case"]{分支调度：@racket[case]}

@defform/subs[#:literals (else)
              (case val-expr case-clause ...)
              ([case-clause [(datum ...) then-body ...+]
                            [else then-body ...+]])]{

求值 @racket[val-expr] 并使用结果选择 @racket[case-clause]。选中的子句是第一个 @racket[datum] 的 @racket[quote] 形式与 @racket[val-expr] 的结果 @racket[equal?] 的子句。如果没有这样的 @racket[datum]，则选择 @racket[else] @racket[case-clause]；如果也没有 @racket[else] @racket[case-clause]，则 @racket[case] 形式的结果为 @|void-const|。@margin-note{@racketmodname[racket] 的 @racket[case] 形式与 @R6RS{R6RS} 或 @R5RS{R5RS} 的不同之处在于基于 @racket[equal?] 而非 @racket[eqv?]（同时还允许内部定义）。}

对于选中的 @racket[case-clause]，最后一个 @racket[then-body] 的结果是整个 @racket[case] 形式的结果，该 @racket[then-body] 相对于 @racket[case] 形式处于尾位置。

以 @racket[else] 开头的 @racket[case-clause] 必须是最后一个 @racket[case-clause]。

对于 @math{N} 个 @racket[datum]，@racket[case] 形式可以在 @math{O(log N)} 时间内调度到匹配的 @racket[case-clause]。

@mz-examples[
(case (+ 7 5)
 [(1 2 3) 'small]
 [(10 11 12) 'big])
(case (- 7 5)
 [(1 2 3) 'small]
 [(10 11 12) 'big])
(case (string-append "do" "g")
 [("cat" "dog" "mouse") "animal"]
 [else "mineral or vegetable"])
(case (list 'y 'x)
 [((a b) (x y)) 'forwards]
 [((b a) (y x)) 'backwards])
(case 'x
 [(x) "ex"]
 [('x) "quoted ex"])
(case (list 'quote 'x)
 [(x) "ex"]
 [('x) "quoted ex"])

(eval:no-prompt
 (define (classify c)
   (case (char-general-category c)
    [(ll lu lt ln lo) "letter"]
    [(nd nl no) "number"]
    [else "other"])))

(classify #\A)
(classify #\1)
(classify #\!)
]}

@subsection[#:tag "case/equal"]{@racket[case] 的变体}

@note-lib-only[racket/case]

@history[#:added "8.11.1.8"]

@deftogether[(
@defform[(case/equal val-expr case-clause ...)]
@defform[(case/equal-always val-expr case-clause ...)]
@defform[(case/eq val-expr case-clause ...)]
@defform[(case/eqv val-expr case-clause ...)]
)]{

类似于 @racket[case]，但使用 @racket[equal?]、@racket[equal-always?]、@racket[eq?] 或 @racket[eqv?] 来比较 @racket[val-expr] 的结果与 @racket[case-clause] 中的字面量。@racket[case/equal] 形式等价于 @racket[case]。}

@;------------------------------------------------------------------------
@section[#:tag "define"]{定义：@racket[define]、@racket[define-syntax] 等}

@guideintro["define"]{definitions}

@defform*/subs[[(define id expr)
                (define (head args) body ...+)]
                ([head id
                       (head args)]
                 [args (code:line arg ...)
                       (code:line arg ... @#,racketparenfont{.} rest-id)]
                 [arg arg-id
                      [arg-id default-expr]
                      (code:line keyword arg-id)
                      (code:line keyword [arg-id default-expr])])]{

第一种形式将 @racket[id] @tech{bind} 到 @racket[expr] 的结果，第二种形式将 @racket[id] @tech{bind} 到一个过程。在第二种情况下，生成的过程为 @racket[(#,cvt (head args) body ...+)]，使用如下定义的 @|cvt| 元函数：

@racketblock[
(#,cvt (id . _kw-formals) . _datum)   = (lambda _kw-formals . _datum)
(#,cvt (head . _kw-formals) . _datum) = (lambda _kw-formals expr)
                                         @#,elem{if} (#,cvt head . _datum) = expr
]

在 @tech{internal-definition context} 中，@racket[define] 形式引入局部绑定；参见 @secref["intdef-body"]。在顶层，@racket[id] 的顶层绑定在求值 @racket[expr] 后创建（如果尚未存在），同时设置 @racket[id] 的顶层映射（在与编译定义关联的 @techlink{namespace} 中）。

在允许 @racket[define] 的 @tech{liberal expansion} 的上下文中，如果 @racket[expr] 是带有关键字参数的立即 @racket[lambda] 形式，或者 @racket[args] 包含关键字参数，则 @racket[id] 作为语法绑定。

@examples[
(eval:no-prompt (define x 10))
x

(eval:no-prompt
 (define (f x)
   (+ x 1)))

(f 10)

(eval:no-prompt
 (define ((f x) [y 20])
   (+ x y)))

((f 10) 30)
((f 10))
]
}

@defform[(define-values (id ...) expr)]{

求值 @racket[expr]，如果结果数量与 @racket[id] 数量匹配，则按顺序将结果 @tech{bind} 到 @racket[id]；如果 @racket[expr] 产生不同数量的结果，则 @exnraise[exn:fail:contract]。

在 @tech{internal-definition context} 中（参见 @secref["intdef-body"]），@racket[define-values] 形式引入局部绑定。在顶层，每个 @racket[id] 的顶层绑定在求值 @racket[expr] 后创建（如果尚未存在），同时设置每个 @racket[id] 的顶层映射（在与编译定义关联的 @techlink{namespace} 中）。

@examples[
(define-values () (values))
(define-values (x y z) (values 1 2 3))
z
]

如果模块体中函数定义的 @racket[define-values] 形式具有值为 true 的 @indexed-racket['compiler-hint:cross-module-inline] @tech{syntax property}，则 Racket 将该属性视为性能提示。更多信息参见 @|Guide| 中的 @guidesecref["func-call-performance"]，另见 @racket[begin-encourage-inline]。}


@defform*[[(define-syntax id expr)
           (define-syntax (head args) body ...+)]]{

第一种形式为 @racket[id] 创建一个 @tech{transformer} 绑定（参见 @secref["transformer-model"]），其值为 @racket[expr]，该表达式相对于外层上下文处于 @tech{phase level} 1。（关于 @tech{phase levels} 的信息，参见 @secref["id-model"]。）@racket[expr] 的求值被 @racket[parameterize] 设置 @racket[current-namespace]，如同 @racket[let-syntax] 中的设置。

第二种形式是与 @racket[define] 相同的简写；它展开为第一种形式的定义，其中 @racket[expr] 是 @racket[lambda] 形式。}

在 @tech{internal-definition context} 中（参见 @secref["intdef-body"]），@racket[define-syntax] 形式引入局部绑定。

@examples[#:eval (syntax-eval) #:once
(define-syntax foo
  (syntax-rules ()
    ((_ a ...)
     (printf "~a\n" (list a ...)))))

(foo 1 2 3 4)

(define-syntax (bar syntax-object)
  (syntax-case syntax-object ()
    ((_ a ...)
     #'(printf "~a\n" (list a ...)))))

(bar 1 2 3 4)
]

@defform[(define-syntaxes (id ...) expr)]{

类似于 @racket[define-syntax]，但为每个 @racket[id] 创建 @tech{transformer} 绑定。@racket[expr] 应产生与 @racket[id] 数量相同的值，每个值绑定到相应的 @racket[id]。

当 @racket[expr] 为顶层 @racket[define-syntaxes]（即不在模块或内部定义位置）产生零个值时，@racket[id] 被有效地声明而不绑定；参见 @secref["macro-introduced-bindings"]。

在 @tech{internal-definition context} 中（参见 @secref["intdef-body"]），@racket[define-syntaxes] 形式引入局部绑定。

@examples[#:eval (syntax-eval) #:once
(define-syntaxes (foo1 foo2 foo3)
  (let ([transformer1 (lambda (syntax-object)
			(syntax-case syntax-object ()
			  [(_) #'1]))]
	[transformer2 (lambda (syntax-object)
			(syntax-case syntax-object ()
			  [(_) #'2]))]
	[transformer3 (lambda (syntax-object)
			(syntax-case syntax-object ()
			  [(_) #'3]))])
    (values transformer1
	    transformer2
	    transformer3)))
(foo1)
(foo2)
(foo3)
]}

@defform*[[(define-for-syntax id expr)
           (define-for-syntax (head args) body ...+)]]{

类似于 @racket[define]，但绑定相对于其上下文处于 @tech{phase level} 1 而非 @tech{phase level} 0。绑定的表达式也处于 @tech{phase level} 1。（关于 @tech{phase levels} 的信息，参见 @secref["id-model"]。）此形式是 @racket[(begin-for-syntax (define id expr))] 或 @racket[(begin-for-syntax (define (head args) body ...+))] 的简写。

在模块内，@racket[define-for-syntax] 引入的绑定必须在其使用之前或出现在同一个 @racket[define-for-syntax] 形式中（即 @racket[define-for-syntax] 形式必须在使用被展开之前展开）。特别地，由 @racket[define-for-syntax] 绑定的相互递归函数必须由同一个 @racket[define-for-syntax] 形式定义。

@examples[#:eval (syntax-eval) #:once
(define-for-syntax helper 2)
(define-syntax (make-two syntax-object)
  (printf "helper is ~a\n" helper)
  #'2)
(make-two)
(code:comment @#,t{`helper' is not bound in the runtime phase})
(eval:error helper)

(define-for-syntax (filter-ids ids)
  (filter identifier? ids))
(define-syntax (show-variables syntax-object)
  (syntax-case syntax-object ()
    [(_ expr ...)
     (with-syntax ([(only-ids ...)
                    (filter-ids (syntax->list #'(expr ...)))])
       #'(list only-ids ...))]))
(let ([a 1] [b 2] [c 3])
  (show-variables a 5 2 b c))]

@defform[(define-values-for-syntax (id ...) expr)]{

类似于 @racket[define-for-syntax]，但 @racket[expr] 必须产生与提供的 @racket[id] 数量相同的值，所有 @racket[id] 被绑定（在 @tech{phase level} 1）。}

@examples[#:eval (syntax-eval) #:once
(define-values-for-syntax (foo1 foo2) (values 1 2))
(define-syntax (bar syntax-object)
  (printf "foo1 is ~a foo2 is ~a\n" foo1 foo2)
  #'2)
(bar) 
]}

@; ----------------------------------------------------------------------

@subsection[#:tag "require-syntax"]{@racket[require] Macros}

@note-lib-only[racket/require-syntax]

@defform*[[(define-require-syntax id proc-expr)
           (define-require-syntax (id args ...) body ...+)]]{

第一种形式类似于 @racket[define-syntax]，但用于 @racket[require] 子形式。@racket[proc-expr] 必须产生一个过程，该过程接受并返回表示 @racket[require] 子形式的 syntax object。

此形式展开为使用 @racket[make-require-transformer] 的 @racket[define-syntax]（更多信息参见 @secref["require-trans"]）。

第二种形式是与 @racket[define-syntax] 相同的简写；它展开为第一种形式的定义，其中 @racket[proc-expr] 是 @racket[lambda] 形式。}

@defproc[(syntax-local-require-introduce [stx syntax?]) syntax?]{

仅用于向后兼容；等价于 @racket[syntax-local-introduce]。

@history[#:changed "6.90.0.29" @elem{Made equivalent to @racket[syntax-local-introduce].}]}

@; ----------------------------------------------------------------------

@subsection[#:tag "provide-syntax"]{@racket[provide] Macros}

@note-lib-only[racket/provide-syntax]

@defform*[[(define-provide-syntax id proc-expr)
           (define-provide-syntax (id args ...) body ...+)]]{

第一种形式类似于 @racket[define-syntax]，但用于 @racket[provide] 子形式。@racket[proc-expr] 必须产生一个过程，该过程接受并返回表示 @racket[provide] 子形式的 syntax object。

此形式展开为使用 @racket[make-provide-transformer] 的 @racket[define-syntax]（更多信息参见 @secref["provide-trans"]）。

第二种形式是与 @racket[define-syntax] 相同的简写；它展开为第一种形式的定义，其中 @racket[expr] 是 @racket[lambda] 形式。}

@defproc[(syntax-local-provide-introduce [stx syntax?]) syntax?]{

仅用于向后兼容；等价于 @racket[syntax-local-introduce]。

@history[#:changed "6.90.0.29" @elem{Made equivalent to @racket[syntax-local-introduce].}]}

@;------------------------------------------------------------------------
@section[#:tag "begin"]{顺序执行：@racket[begin]、@racket[begin0] 和 @racket[begin-for-syntax]}

@guideintro["begin"]{@racket[begin] and @racket[begin0]}

@defform*[[(begin form ...)
           (begin expr ...+)]]{

第一种形式适用于 @racket[begin] 出现在顶层、模块级或内部定义位置时。在这种情况下，@racket[begin] 形式等价于将 @racket[form] 拼接到外层上下文中。

第二种形式适用于 @racket[begin] 在表达式位置时。在这种情况下，@racket[expr] 按顺序求值，除最后一个之外的所有结果被忽略。最后一个 @racket[expr] 相对于 @racket[begin] 形式处于尾位置。

@examples[
(begin
  (define x 10)
  x)
(+ 1 (begin
       (printf "hi\n")
       2))
(let-values ([(x y) (begin
                      (values 1 2 3)
                      (values 1 2))])
 (list x y))
]}

@defform[(begin0 expr ...+)]{

求值第一个 @racket[expr]，然后按顺序求值其他 @racket[exprs]，忽略其结果。第一个 @racket[expr] 的结果即为 @racket[begin0] 形式的结果；第一个 @racket[expr] 仅在没有其他 @racket[expr] 时才处于尾位置。

@mz-examples[
(begin0
  (values 1 2)
  (printf "hi\n"))
]}

@defform[(begin-for-syntax form ...)]{

仅在 @tech{top-level context} 或 @tech{module context} 中允许，将每个 @racket[form] 的 @tech{phase level} 增加一：

@itemize[

 @item{表达式引用比 @racket[begin-for-syntax] 形式上下文中的 @tech{phase level} 大一级的绑定；}

 @item{@racket[define]、@racket[define-values]、@racket[define-syntax] 和 @racket[define-syntaxes] 形式在比 @racket[begin-for-syntax] 形式上下文中的 @tech{phase level} 大一级的级别上绑定；}

 @item{在 @racket[require] 和 @racket[provide] 形式中，默认的 @tech{phase level} 更大，大致相当于用 @racket[for-syntax] 包装 @racket[require] 形式的内容；}

 @item{表达式形式 @racket[_expr]：转换为 @racket[(define-values-for-syntax () (begin _expr (values)))]，这在展开时有效地求值表达式，并且在 @tech{module context} 的情况下，为模块将来的 @tech{visit} 保留表达式。}

]

关于 @racket[begin-for-syntax] 在模块上下文中的展开顺序和部分展开的信息，另见 @racket[module]。@racket[begin-for-syntax] 内 @racket[expr] 的求值被 @racket[parameterize] 设置 @racket[current-namespace]，如同 @racket[let-syntax] 中的设置。

}

@;------------------------------------------------------------------------
@section[#:tag "when+unless"]{受保护求值：@racket[when] 和 @racket[unless]}

@guideintro["when+unless"]{@racket[when] and @racket[unless]}

@defform[(when test-expr body ...+)]{

求值 @racket[test-expr]。如果结果为 @racket[#f]，则 @racket[when] 表达式的结果为 @|void-const|。否则，求值 @racket[body]，最后一个 @racket[body] 相对于 @racket[when] 形式处于尾位置。

@mz-examples[
(when (positive? -5)
  (display "hi"))
(when (positive? 5)
  (display "hi")
  (display " there"))
]}

@defform[(unless test-expr body ...+)]{

等价于 @racket[(when (not test-expr) body ...+)]。

@mz-examples[
(unless (positive? 5)
  (display "hi"))
(unless (positive? -5)
  (display "hi")
  (display " there"))
]}

@;------------------------------------------------------------------------
@section[#:tag "set!"]{赋值：@racket[set!] 和 @racket[set!-values]}

@guideintro["set!"]{@racket[set!]}

@defform[(set! id expr)]{

如果 @racket[id] 有到 @tech{assignment transformer} 的 @tech{transformer} 绑定（如由 @racket[make-set!-transformer] 产生或作为具有 @racket[prop:set!-transformer] 属性的结构类型实例），则此形式通过使用完整表达式调用 assignment transformer 来展开。如果 @racket[id] 有到 @tech{rename transformer} 的 @tech{transformer} 绑定（如由 @racket[make-rename-transformer] 产生或作为具有 @racket[prop:rename-transformer] 属性的结构类型实例），则此形式通过用目标标识符（例如提供给 @racket[make-rename-transformer] 的那个）替换 @racket[id] 来展开。如果一个 transformer 绑定同时具有 @racket[prop:set!-transformer] 和 @racket[prop:rename-transformer] 属性，后者优先。

否则，求值 @racket[expr] 并将结果安装到 @racket[id] 的 location 中，该 @racket[id] 必须绑定为局部变量或定义为 @tech{top-level variable} 或 @tech{module-level variable}。如果 @racket[id] 引用导入的绑定，则报告语法错误。如果 @racket[id] 引用未定义的 @tech{top-level variable}，则 @exnraise[exn:fail:contract]。

另见 @racket[compile-allow-set!-undefined]。

@examples[
(define x 12)
(set! x (add1 x))
x
(let ([x 5])
  (set! x (add1 x))
  x)
(eval:error (set! i-am-not-defined 10))
]}

@defform[(set!-values (id ...) expr)]{

假设所有 @racket[id] 引用变量，此形式求值 @racket[expr]，它必须产生与提供的 @racket[id] 数量相同的值。每个 @racket[id] 的 location 以与 @racket[set!] 相同的方式用来自 @racket[expr] 的对应值填充。

@mz-examples[
(let ([a 1]
      [b 2])
  (set!-values (a b) (values b a))
  (list a b))
]

更一般地，@racket[set!-values] 形式展开为

@racketblock[
(let-values ([(_tmp-id ...) expr])
  (set! id _tmp-id) ...)
]

如果任何 @racket[id] 有到 @tech{assignment transformer} 的 transformer 绑定，则触发进一步展开。}

@;------------------------------------------------------------------------
@include-section["for.scrbl"]

@;------------------------------------------------------------------------
@section[#:tag "wcm"]{延续标记：@racket[with-continuation-mark]}

@defform[(with-continuation-mark key-expr val-expr result-expr)]{

@racket[key-expr]、@racket[val-expr] 和 @racket[result-expr] 表达式按顺序求值。在 @racket[key-expr] 求值获得 key 且 @racket[val-expr] 求值获得 value 后，key 被映射到 value，作为当前 continuation 的初始 @tech{continuation frame} 中的 @tech{continuation mark}。如果该 frame 已有该 key 的 mark，则替换该 mark。最后，求值 @racket[result-expr]；求值 @racket[result-expr] 的 continuation 是 @racket[with-continuation-mark] 表达式的 continuation（因此 @racket[result-expr] 的结果是 @racket[with-continuation-mark] 表达式的结果，且 @racket[result-expr] 对于 @racket[with-continuation-mark] 表达式处于尾位置）。

@moreref["contmarks"]{continuation marks}}

@;------------------------------------------------------------------------
@section[#:tag "quasiquote"]{准引用：@racket[quasiquote]、@racket[unquote] 和 @racket[unquote-splicing]}

@guideintro["qq"]{@racket[quasiquote]}

@defform[(quasiquote datum)]{

如果 @racket[datum] 不包含 @racket[(#,unquote-id _expr)] 或 @racket[(#,unquote-splicing-id _expr)]，则与 @racket[(quote datum)] 相同。然而，@racket[(#,unquote-id _expr)] 形式从引用中转义出来，@racket[_expr] 的结果在 @racket[quasiquote] 结果中取代 @racket[(#,unquote-id _expr)] 形式的位置。@racket[(#,unquote-splicing-id _expr)] 类似地转义，但 @racket[_expr] 产生一个列表，其元素作为多个值拼接到 @racket[(#,unquote-splicing-id _expr)] 的位置。

@|unquote-id| 或 @|unquote-splicing-id| 形式在 @racket[datum] 中的以下任何转义位置被识别：在 pair 中、在 vector 中、在 box 中、在名称位置之后的 @tech{prefab} 结构字段中，以及在哈希表值位置中（但不在哈希表键位置中）。这些转义位置可以嵌套到任意深度。

@|unquote-splicing-id| 形式必须作为引用 pair 的 @racket[car]、引用 vector 的元素或引用 @tech{prefab} 结构的元素出现。在 pair 的情况下，如果相关引用 pair 的 @racket[cdr] 为空，则 @racket[_expr] 不需要产生列表，其结果直接用于替代引用 pair（与 @racket[append] 接受非列表最后参数的方式相同）。

如果 @racket[unquote] 或 @racket[unquote-splicing] 在 @racket[quasiquote] 内的转义位置中出现，但不是以 @racket[(#,unquote-id _expr)] 或 @racket[(#,unquote-splicing-id _expr)] 的方式，则报告语法错误。

@mz-examples[
(eval:alts (#,(racket quasiquote) (0 1 2)) `(0 1 2))
(eval:alts (#,(racket quasiquote) (0 (#,unquote-id (+ 1 2)) 4)) `(0 ,(+ 1 2) 4))
(eval:alts (#,(racket quasiquote) (0 (#,unquote-splicing-id (list 1 2)) 4)) `(0 ,@(list 1 2) 4))
(eval:alts (#,(racket quasiquote) (0 (#,unquote-splicing-id 1) 4)) (eval:error `(0 ,@1 4)))
(eval:alts (#,(racket quasiquote) (0 (#,unquote-splicing-id 1))) `(0 ,@1))
]

@racket[quasiquote]、@racket[unquote] 或 @racket[unquote-splicing] 形式通常分别缩写为 @litchar{`}、@litchar{,} 或 @litchar[",@"]。另见 @secref["parse-quote"]。

@mz-examples[
`(0 1 2)
`(1 ,(+ 1 2) 4)
`#s(stuff 1 ,(+ 1 2) 4)
`#hash(("a" . ,(+ 1 2)))
`#hash((,(+ 1 2) . "a"))
`(1 ,@(list 1 2) 4)
`#(1 ,@(list 1 2) 4)
]

原始 @racket[datum] 中的 @racket[quasiquote] 形式会增加准引用级别：在 @racket[quasiquote] 形式内，每个 @racket[unquote] 或 @racket[unquote-splicing] 被保留，但进一步嵌套的 @racket[unquote] 或 @racket[unquote-splicing] 会转义。多层嵌套的 @racket[quasiquote] 需要多层嵌套的 @racket[unquote] 或 @racket[unquote-splicing] 来转义。

@mz-examples[
`(1 `,(+ 1 ,(+ 2 3)) 4)
`(1 ```,,@,,@(list (+ 1 2)) 4)
]

@racket[quasiquote] 形式只分配所需数量的新 cons cells、vectors 和 boxes，而无需分析 @racket[unquote] 和 @racket[unquote-splicing] 表达式。例如，在

@racketblock[
`(,1 2 3)
]

一个单独的尾部 @racket['(2 3)] 用于 @racket[quasiquote] 表达式的每次求值。当分配新数据时，@racket[quasiquote] 形式分配可变 vectors、可变 boxes 和不可变 hashes。

@mz-examples[
(immutable? `#(,0))
(immutable? `#hash((a . ,0)))
]

}

@defidform[unquote]{

参见 @racket[quasiquote]，其中 @racket[unquote] 被识别为转义。作为表达式的 @racket[unquote] 形式是语法错误。}

@defidform[unquote-splicing]{

参见 @racket[quasiquote]，其中 @racket[unquote-splicing] 被识别为转义。作为表达式的 @racket[unquote-splicing] 形式是语法错误。}

@;------------------------------------------------------------------------
@section{语法引用：@racket[quote-syntax]}

@defform*[[(quote-syntax datum)
           (quote-syntax datum #:local)]]{

类似于 @racket[quote]，但产生一个 @tech{syntax object}，它保留展开时附加到 @racket[datum] 上的 @tech{lexical information} 和源位置信息。

指定 @racket[#:local] 时，syntax object 的 @tech{lexical information} 中的所有 @tech{scopes} 被保留。省略 @racket[#:local] 时，@racket[datum] 中的 @tech{scope sets} 被修剪，以省略出现在 @racket[quote-syntax] 形式与外层顶层上下文、模块体或 @tech{phase level} 交叉之间（取最近者）的任何绑定形式的 @tech{scope}。

与 @racket[syntax]（@litchar{#'}）不同，@racket[quote-syntax] 不替换由 @racket[with-syntax]、@racket[syntax-parse] 或 @racket[syntax-case] 绑定的模式变量。

@mz-examples[
(syntax? (quote-syntax x))
(quote-syntax (1 2 3))
(with-syntax ([a #'5])
  (quote-syntax (a b c)))
(free-identifier=? (let ([x 1]) (quote-syntax x))
                   (quote-syntax x))
(free-identifier=? (let ([x 1]) (quote-syntax x #:local))
                   (quote-syntax x))
]

@history[#:changed "6.3" @elem{Added @tech{scope} pruning and support
                               for @racket[#:local].}]}

@;------------------------------------------------------------------------
@section[#:tag "#%top-interaction"]{交互包装器：@racket[#%top-interaction]}

@defform[(#%top-interaction . form)]{

简单地展开为 @racket[form]。@racket[#%top-interaction] 形式类似于 @racket[#%app] 和 @racket[#%module-begin]，它提供了一个钩子来控制通过 @racket[load]（更准确地说，是默认的 @tech{load handler}）或 @racket[read-eval-print-loop] 进行的交互式求值。}

@;------------------------------------------------------------------------
@include-section["block.scrbl"]

@;------------------------------------------------------------------------
@section[#:tag "stratified-body"]{内部定义限制：@racket[#%stratified-body]}

@defform[(#%stratified-body defn-or-expr ...)]{

对于 @tech{internal-definition context} 序列，类似于 @racket[(let () defn-or-expr ...)]，但不允许表达式在定义之前出现，且所有定义被视为引用所有其他定义（即变量的 @tech{locations} 都先分配，如同 @racket[letrec] 而非 @racket[letrec-syntaxes+values]）。

@racket[#%stratified-body] 形式对于实现提供更受限的 @tech{internal-definition context} 的语法形式或语言很有用。}

@close-eval[require-eval]
@close-eval[meta-in-eval]

@;------------------------------------------------------------------------
@section[#:tag "performance-hint"]{性能提示：@racket[begin-encourage-inline]}

@note-lib-only[racket/performance-hint]

@defform[(begin-encourage-inline form ...)]{

将 @racket['compiler-hint:cross-module-inline] @tech{syntax property} 附加到每个 @racket[form]，当 @racket[form] 是函数定义时很有用。参见 @racket[define-values]。

@racket[begin-encourage-inline] 形式也由 @racketmodname[(submod racket/performance-hint begin-encourage-inline)] 模块提供，其依赖项比 @racketmodname[racket/performance-hint] 少。

@history[#:changed "6.2" @elem{Added the @racketmodname[(submod racket/performance-hint begin-encourage-inline)] submodule.}]
}

@defform*/subs[[(define-inline id expr)
                (define-inline (head args) body ...+)]
                ([head id
                       (head args)]
                 [args (code:line arg ...)
                       (code:line arg ... @#,racketparenfont{.} rest-id)]
                 [arg arg-id
                      [arg-id default-expr]
                      (code:line keyword arg-id)
                      (code:line keyword [arg-id default-expr])])]{
类似于 @racket[define]，但确保定义在其调用处被内联。递归调用不被内联，以避免无限内联。支持高阶使用，但也不被内联。错误应用（提供错误数量的参数或不正确的关键字参数）也不被内联，并保留为运行时错误。

@racket[define-inline] 形式可能会干扰 Racket 编译器自身的内联启发式，应仅在其他内联尝试（如 @racket[begin-encourage-inline]）失败时使用。

@history[#:changed "8.1.0.5" @elem{Changed to treat misapplication as a run-time error.}]}


@;------------------------------------------------------------------------
@section[#:tag "lazy-require"]{延迟导入模块：@racket[lazy-require]}

@note-lib-only[racket/lazy-require]

@(define lazy-require-eval (make-base-eval))
@(lazy-require-eval '(require racket/lazy-require))

@defform[(lazy-require [module-path (fun-import ...)] ...)
         #:grammar
         ([fun-import fun-id
                      (orig-fun-id fun-id)])]{

将每个 @racket[fun-id] 定义为一个函数，当调用时，从 @racket[module-path] 指定的模块动态 require 名为 @racket[orig-fun-id] 的导出，并使用相同的参数调用它。如果未给出 @racket[orig-fun-id]，则默认为 @racket[fun-id]。

如果外层的相对 phase level 不是 0，则 @racket[module-path] 也被放入子模块中（在子模块内以 phase level 0 使用 @racket[define-runtime-module-path-index]）。引入的子模块名称为 @racket[lazy-require-aux]@racket[_n]@racketidfont{-}@racket[_m]，其中 @racket[_n] 是 phase-level 编号，@racket[_m] 是一个数字。

当使用延迟 require 的函数触发模块加载时，它也触发使用 @racket[register-external-module] 声明间接编译依赖（以防在编译模块过程中使用该函数）。

@examples[#:eval lazy-require-eval
(lazy-require
  [racket/list (partition)])
(partition even? '(1 2 3 4 5))
(module hello racket/base
  (provide hello)
  (printf "starting hello server\n")
  (define (hello) (printf "hello!\n")))
(lazy-require
  ['hello ([hello greet])])
(greet)
]
}

@defform[(lazy-require-syntax [module-path (macro-import ...)] ...)
         #:grammar
         ([macro-import macro-id
                        (orig-macro-id macro-id)])]{

类似于 @racket[lazy-require]，但用于宏。也就是说，它将每个 @racket[macro-id] 定义为一个宏，当使用时从给定的 @racket[module-path] 动态加载宏的实现。如果未给出 @racket[orig-macro-id]，则默认为 @racket[macro-id]。

在具有大型复杂宏的库的 @emph{实现} 中使用 @racket[lazy-require-syntax]，以避免库的客户端对宏编译器的依赖。请注意，只有具有特别大的编译时组件（如 Typed Racket，它包含类型检查器和优化器）的宏才能从 @racket[lazy-require-syntax] 中受益；典型的宏则不会。

@bold{警告：} @racket[lazy-require-syntax] 破坏了 Racket 模块加载器和链接器依赖的不变量；这些不变量通常确保宏生成的代码中的引用在代码运行之前被加载。安全使用 @racket[lazy-require-syntax] 需要在宏实现中具有特定结构。（特别地，@racket[lazy-require-syntax] 不能简单地在客户端代码中引入。）宏实现必须遵循以下规则：
@itemlist[#:style 'ordered
@item{接口模块必须 @racket[require] 运行时支持模块}
@item{编译器模块必须通过 @emph{绝对} 模块路径而不是 @emph{相对} 路径来 @racket[require] 运行时支持模块}
]

为了解释接口模块、编译器模块和运行时支持模块的概念，下面是一个导出宏的示例模块：
@racketblock[  ;; @examples[#:eval lazy-require-eval #:label #f
(module original racket/base
  (define (ntimes-proc n thunk)
    (for ([i (in-range n)]) (thunk)))
  (define-syntax-rule (ntimes n expr)
    (ntimes-proc n (lambda () expr)))
  (provide ntimes))
]
假设我们想使用 @racket[lazy-require-syntax] 延迟加载 @racket[ntimes] 宏 transformer 的实现。原始模块必须拆分为三个部分：
@racketblock[  ;; @examples[#:eval lazy-require-eval #:label #f
(module runtime-support racket/base
  (define (ntimes-proc n thunk)
    (for ([i (in-range n)]) (thunk)))
  (provide ntimes-proc))
(module compiler racket/base
  (require 'runtime-support)
  (define-syntax-rule (ntimes n expr)
    (ntimes-proc n (lambda () expr)))
  (provide ntimes))
(module interface racket/base
  (require racket/lazy-require)
  (require 'runtime-support)
  (lazy-require-syntax ['compiler (ntimes)])
  (provide ntimes))
]
运行时支持模块包含宏引用的函数和值定义。编译器模块包含宏定义本身---代码中在编译后消失的部分。接口模块延迟加载宏 transformer，但它通过正常 require 确保运行时支持模块在运行时被定义。在更大的例子中，当然，运行时支持和编译器可能都由多个模块组成。

下面是不将运行时支持分离到单独模块时发生的情况：
@examples[#:eval lazy-require-eval #:label #f
(module bad-no-runtime racket/base
  (define (ntimes-proc n thunk)
    (for ([i (in-range n)]) (thunk)))
  (define-syntax-rule (ntimes n expr)
    (ntimes-proc n (lambda () expr)))
  (provide ntimes))
(module bad-client racket/base
  (require racket/lazy-require)
  (lazy-require-syntax ['bad-no-runtime (ntimes)])
  (ntimes 3 (printf "hello?\n")))
(eval:error (require 'bad-client))
]
当接口模块未引入对运行时支持模块的依赖时，会发生类似的错误。
}

@(close-eval lazy-require-eval)

@;------------------------------------------------------------------------
@section[#:tag "foreign-inline"]{对核心编译器形式的不安全访问}


@defform[(#%foreign-inline datum maybe-mode)
         #:grammar
         ([maybe-mode code:blank
                      #:effect
                      #:pure
                      #:pure*
                      #:copy
                      #:copy*])]{

@racket[#%foreign-inline] 形式 @tech[#:key "unsafe"]{不安全地} 内联一个由 Racket 运行其上的核心编译器和运行时系统支持的表达式形式，在 Racket @tech{CS} 的情况下是 Chez Scheme。省略 @racket[maybe-mode] 等价于提供 @racket[#:effect]。

确保 @racket[datum] 受支持且具有适当的行为（与 @racket[maybe-mode] 一致）取决于此形式的用户：

@itemlist[

 @item{@racket[datum] 不能引用在外层作用域中绑定的任何变量。}

 @item{求值 @racket[datum] 不能引发异常或以其他方式检查当前 @tech{continuation}，并且必须返回单一值。}

 @item{如果指定了 @racket[#:pure] 或 @racket[#:copy]，则求值 @racket[datum] 不能有任何副作用或依赖先前的效果。}

 @item{如果指定了 @racket[#:pure*] 或 @racket[#:copy*]，则不仅求值 @racket[datum] 不能有副作用或依赖先前的效果，表达式还必须应用于没有副作用或依赖先前效果的参数。}

 @item{如果指定了 @racket[#:copy] 或 @racket[#:copy*]，则编译可能会复制整个 @racket[(#%foreign-inline datum maybe-mode)] 表达式一次或多次，以在其值的不同使用处内联其实现。}

]

@history[#:added "9.1.0.8"]

}
