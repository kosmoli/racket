#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/syntax-srcloc
                     (only-in syntax/stx stx-list?)))

@(define stx-eval (make-base-eval))
@(stx-eval '(require (for-syntax racket/base)))

@(define racket-srcloc @racket[srcloc])

@title[#:tag "stxops"]{Syntax Object Content}


@defproc[(syntax? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{语法对象} 则返回 @racket[#t]，否则返回 @racket[#f]。
另请参见 @secref["stxobj-model"]。

@history[#:added "6.0"]}


@defproc[(identifier? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{语法对象} 且 @racket[(syntax-e stx)] 产生一个符号，则返回 @racket[#t]。

@examples[#:eval stx-eval
  (identifier? #'linguine)
  (identifier? #'(if wheat? udon soba))
  (identifier? 'ramen)
  (identifier? 15)
]}


@defproc[(syntax-source [stx syntax?]) any/c]{

返回 @tech{语法对象} @racket[stx] 的 @tech{源位置}的
源组件，如果未知则返回 @racket[#f]。源由任意值表示
（例如，传递给 @racket[read-syntax] 的值），但它通常是文件
路径字符串。

另请参见 @racketmodname[racket/syntax-srcloc] 中的 @racket[syntax-srcloc]。}


@defproc[(syntax-line [stx syntax?]) 
         (or/c exact-positive-integer? #f)]{

返回 @tech{语法对象} 的起始位置在源代码中的
行号（正精确整数），如果
行号或源未知则返回 @racket[#f]。另请参见 @secref["linecol"]。

@history[#:changed "7.0" @elem{删除了 @racket[syntax-line]
                               和 @racket[syntax-column] 同时产生
                               @racket[#f] 或同时产生整数的保证。}]}


@defproc[(syntax-column [stx syntax?])
         (or/c exact-nonnegative-integer? #f)]{

返回 @tech{语法对象} 的起始位置在源代码中的
列号（非负精确整数），如果源
列未知则返回 @racket[#f]。另请参见 @secref["linecol"]。

@history[#:changed "7.0" @elem{删除了 @racket[syntax-line]
                               和 @racket[syntax-column] 同时产生
                               @racket[#f] 或同时产生整数的保证。}]}


@defproc[(syntax-position [stx syntax?])
         (or/c exact-positive-integer? #f)]{

返回 @tech{语法对象} 的起始位置在源代码中的
位置（正精确整数），如果源
位置未知则返回 @racket[#f]。位置旨在作为字符位置，
但从启用行计数的端口读取时会产生
字节偏移位置。另请参见 @secref["linecol"]。}


@defproc[(syntax-span [stx syntax?])
         (or/c exact-nonnegative-integer? #f)]{

返回 @tech{语法对象} 在源代码中的跨度（非负精确整数），如果跨度未知则返回 @racket[#f]。跨度旨在按字符计数，
但从禁用行计数的端口读取时会产生以字节为单位的跨度。另请参见 @secref["linecol"] 。 }


@defproc[(syntax-original? [stx syntax?]) boolean?]{

如果 @racket[stx] 具有 @racket[read-syntax] 附加到其生成的 @tech{语法对象} 的属性（参见 @secref["stxprops"]），并且如果 @racket[stx] 的 @tech{词法信息}不包含任何宏引入范围（表示该对象由语法转换器引入；参见 @secref["stxobj-model"]）。否则返回 @racket[#f]。

此谓词可用于区分展开表达式中直接存在于原始表达式中的 @tech{语法对象}，
而不是由宏插入的 @tech{语法对象}。

如果语法对象作为编译代码的一部分被编组，则表示原始语法的（隐藏）属性将被删除；
另请参见 @racket[current-compile]。}


@defproc[(syntax-source-module [stx syntax?] [source? any/c #f])
         (or/c module-path-index? symbol? path? resolved-module-path? #f)]{

返回其源代码包含 @racket[stx] 的模块的指示，
如果无法从上下文中推断源代码模块则返回 @racket[#f]。如果
@racket[source?] 为 @racket[#f]，则结果是模块路径索引或符号（参见 @secref["modpathidx"]）或 @tech{已解析的模块路径}；
如果 @racket[source?] 为真，则结果是由 @racket[current-module-declare-source] 意义下对应于已加载模块源代码的路径或符号。

请注意，@racket[syntax-source-module] 不会查询 @racket[stx] 的源位置。结果基于 @racket[stx] 的 @tech{词法信息}。}


@defproc[(syntax-e [stx syntax?]) any/c]{

从 @tech{语法对象} 中解开立即的数据结构，
保留嵌套的语法结构（如果有的话）。@racket[(syntax-e stx)] 的结果是以下之一：

    @itemize[

       @item{符号}

       @item{@tech{语法对}（如下所述）}

       @item{空列表}

       @item{包含 @tech{语法对象} 的不可变向量}

       @item{包含 @tech{语法对象} 的不可变方框}

       @item{包含 @tech{语法对象} 值的不可变 @tech{哈希表}（但不一定是 @tech{语法对象} 键）}

       @item{包含 @tech{语法对象} 的不可变 @tech{prefab} 结构}

       @item{其他类型的数据——通常是数字、布尔值或字符串——当 @racket[datum-intern-literal] 会转换该值时}

    ]

@examples[#:eval stx-eval
  (syntax-e #'a)
  (syntax-e #'(x . y))
  (syntax-e #'#(1 2 (+ 3 4)))
  (syntax-e #'#&"hello world")
  (syntax-e #'#hash((imperial . "yellow") (festival . "green")))
  (syntax-e #'#(point 3 4))
  (syntax-e #'3)
  (syntax-e #'"three")
  (syntax-e #'#t)
]

@deftech{语法对} 是一个对，其第一个元素是 @tech{语法对象}，
其第二个元素是空列表、语法对或语法对象。

由 @racket[read-syntax] 生成的 @tech{语法对象} 将通过在输入中使用定界 @litchar{.} 来反映
由每对括号创建的定界语法对象，并且仅为源代码中的括号创建对值 @tech{语法对象}。更多信息参见 @secref["parse-pair"]。

如果 @racket[stx] 是 @tech{污损的}，那么 @racket[(syntax-e stx)] 结果中的任何语法对象都是 @tech{污损的}。多次调用 @racket[syntax-e] 对 @racket[stx] 的结果是 @racket[eq?]。}


@defproc[(syntax->list [stx syntax?]) (or/c list? #f)]{

返回语法对象的列表或 @racket[#f]。当 @racket[(syntax->datum stx)] 会产生列表时，
结果是一个语法对象列表。换句话说，@racket[(syntax-e stx)] 中的 @tech{语法对} 被展平。

如果 @racket[stx] 是 @tech{污损的}，那么 @racket[(syntax->list stx)] 结果中的任何语法对象都是 @tech{污损的}。

@examples[#:eval stx-eval
  (syntax->list #'())
  (syntax->list #'(1 (+ 3 4) 5 6))
  (syntax->list #'a)
]}


@defproc[(syntax->datum [stx syntax?]) any/c]{

通过从 @racket[stx] 中剥离词法信息、源位置信息、属性和篡改状态来返回一个数据。
在不可变对、不可变向量、不可变方框、不可变 @tech{哈希表} 值（非键）和不可变 @tech{prefab} 结构内，@tech{语法对象} 被递归地剥离。

剥离操作不会改变 @racket[stx]；它根据需要创建新的对、向量、方框、哈希表和 @tech{prefab} 结构，
以递归地剥离词法和源位置信息。

@examples[#:eval stx-eval
  (syntax->datum #'a)
  (syntax->datum #'(x . y))
  (syntax->datum #'#(1 2 (+ 3 4)))
  (syntax->datum #'#&"hello world")
  (syntax->datum #'#hash((imperial . "yellow") (festival . "green")))
  (syntax->datum #'#(point 3 4))
  (syntax->datum #'3)
  (syntax->datum #'"three")
  (syntax->datum #'#t)
]}

@defproc[(datum->syntax [ctxt (or/c syntax? #f)]
                        [v any/c]
                        [srcloc (or/c #f
                                      syntax?
                                      srcloc?
                                      (list/c any/c
                                              (or/c exact-positive-integer? #f)
                                              (or/c exact-nonnegative-integer? #f)
                                              (or/c exact-positive-integer? #f)
                                              (or/c exact-nonnegative-integer? #f))
                                      (vector/c any/c
                                               (or/c exact-positive-integer? #f)
                                               (or/c exact-nonnegative-integer? #f)
                                               (or/c exact-positive-integer? #f)
                                               (or/c exact-nonnegative-integer? #f)))
                                #f]
                        [prop (or/c syntax? #f) #f]
                        [ignored (or/c syntax? #f) #f])
          syntax?]{

将 @tech{数据} @racket[v] 转换为 @tech{语法对象}。
如果 @racket[v] 已经是 @tech{语法对象}，则不进行转换，
并且 @racket[v] 被原样返回。
对、向量、方框的内容、不可变哈希表的值以及不可变 @tech{prefab} 结构的字段被递归地转换。
@tech{prefab} 结构的键和不可变哈希表的键不被转换。可变向量和方框被不可变向量和方框替换。对于除对、向量、方框、不可变 @tech{哈希表}、不可变 @tech{prefab} 结构或 @tech{语法对象} 之外的任何值类型，转换意味着在值通过 @racket[datum-intern-literal] @tech{驻留} 之后，用词法信息、源位置信息和属性包装该值。

转换后的 @racket[v] 中的对象被赋予 @racket[ctxt] 的词法上下文信息和 @racket[srcloc] 的源位置信息。转换产生的立即 @tech{语法对象} 被赋予 @racket[prop] 的属性（参见 @secref["stxprops"]）（甚至是那些不会通过 @racket[syntax-property-symbol-keys] 可见的隐藏属性）；如果 @racket[v] 是对、向量、方框、不可变 @tech{哈希表} 或不可变 @tech{prefab} 结构，则递归转换的值不会被赋予属性。如果 @racket[ctxt] 是 @tech{污损的}，那么由 @racket[datum->syntax] 产生的结果语法对象是 @tech{污损的}。@racket[ctxt] 的 @tech{代码检查器}（如果有的话）与当前正在转换的宏的模块的代码检查器进行比较；如果两个检查器都可用且一个是相同或低于另一个的，则结果语法具有相同/较低检查器，否则它没有代码检查器。

@racket[ctxt]、@racket[srcloc] 或 @racket[prop] 都可以是 @racket[#f]，在这种情况下，结果语法没有词法上下文、源信息和/或新属性。

如果 @racket[srcloc] 不是 @racket[#f]、不是 @racket-srcloc 实例且不是 @tech{语法对象}，则它必须是一个五元素的列表或向量，对应于 @racket-srcloc 字段。

图结构不会通过将 @racket[v] 转换为 @tech{语法对象}来保留。相反，@racket[v] 本质上是展开为树。如果 @racket[v] 通过对、向量、方框、不可变 @tech{哈希表} 和不可变 @tech{prefab} 结构有循环，则引发 @exnraise[exn:fail:contract]。

@racket[ignored] 参数是为了向后兼容而允许的，对返回的语法对象没有影响。

@history[#:changed "8.2.0.5" @elem{允许 @racket-srcloc 值作为 @racket[srcloc] 参数。}]}

@deftogether[(
@defproc[(syntax-binding-set? [v any/c]) boolean?]
@defproc[(syntax-binding-set) syntax-binding-set?]
@defproc[(syntax-binding-set->syntax [binding-set syntax-binding-set?] [datum any/c]) syntax?]
@defproc[(syntax-binding-set-extend [binding-set syntax-binding-set?]
                                    [symbol symbol?]
                                    [phase (or/c exact-integer? #f)]
                                    [mpi module-path-index?]
                                    [#:source-symbol source-symbol symbol? symbol]
                                    [#:source-phase source-phase (or/c exact-integer? #f) phase]
                                    [#:nominal-module nominal-mpi module-path-index? mpi]
                                    [#:nominal-phase nominal-phase (or/c exact-integer? #f) source-phase]
                                    [#:nominal-symbol nominal-symbol symbol? source-symbol]
                                    [#:nominal-require-phase nominal-require-phase (or/c exact-integer? #f) 0]
                                    [#:inspector inspector (or/c inspector? #f) #f])
         syntax-binding-set?]
)]{

@deftech{语法绑定集}支持显式构建语法对象的绑定信息。首先使用 @racket[syntax-binding-set] 创建一个空的绑定集，使用 @racket[syntax-binding-set-extend] 添加绑定，然后使用 @racket[syntax-binding-set->syntax] 创建一个以绑定作为其 @tech{词法信息}的语法对象。

@racket[syntax-binding-set-extend] 的前三个参数建立 @racket[symbol] 在 @racket[phase] 到在 @racket[mpi] 引用的模块中定义的标识符的绑定。提供 @racket[source-symbol] 使 @racket[symbol] 的绑定引用来自 @racket[mpi] 的不同提供的变量，依此类推；可选参数对应于 @racket[identifier-binding] 的结果。

@history[#:added "7.0.0.12"]}


@defproc[(datum-intern-literal [v any/c]) any/c]{

转换一些值，以与在 @racket[read-syntax] 模式下默认读取器产生的 @tech{驻留} 结果保持一致。

如果 @racket[v] 是 @tech{数字}、@tech{字符}、@tech{字符串}、@tech{字节字符串} 或 @tech{正则表达式}，则结果是一个 @racket[equal?] 于 @racket[v] 且 @racket[eq?] 于默认读取器潜在结果的值。（请注意，可变字符串和字节字符串被 @tech{驻留} 为不可变字符串和字节字符串。）

如果 @racket[v] 是 @tech{未驻留的} 或 @tech{不可读的符号}，结果仍然是 @racket[v]，因为 @tech{驻留的} 符号不会 @racket[equal?] 于 @racket[v]。

转换过程不会遍历复合值。例如，如果 @racket[v] 是一个包含字符串的 @tech{对}，则 @racket[v] 内的字符串不会被 @tech{驻留}。

如果 @racket[_v1] 和 @racket[_v2] @racket[equal?] 但非 @racket[eq?]，那么 @racket[(datum-intern-literal _v1)] 可能返回 @racket[_v1] —— 并且在 @racket[_v1] 在垃圾收集器的判定下变为不可达（参见 @secref["gc-model"]）之后的某个时间 —— @racket[(datum-intern-literal _v2)] 仍可能返回 @racket[_v2]。换句话说，@racket[datum-intern-literal] 可能采用给定值作为 @tech{驻留} 代表，但如果之前的代表在其他方面变得不可达，那么 @racket[datum-intern-literal] 可能采用新的代表。}


@defproc[(syntax-shift-phase-level [stx syntax?]
                                   [shift (or/c exact-integer? #f)])
         syntax?]{

返回一个语法对象，它与 @racket[stx] 类似，但其所有顶层和模块绑定都移动了 @racket[shift] 个 @tech{阶段级别}。如果 @racket[shift] 是 @racket[#f]，则只有 @tech{阶段级别} 0 的绑定移动到 @tech{标签阶段级别}；移动整数 @racket[shift] 有效地移动了已经进入 @tech{标签阶段级别} 的阶段。如果 @racket[shift] 是 @racket[0]，则结果是 @racket[stx]。

@history[#:changed "9.0.0.1" @elem{按整数阶段级别移动调整了哪个原始阶段在 @tech{标签阶段级别} 中被看到。}]}


@defproc[(generate-temporaries [v stx-list?])
         (listof identifier?)]{

返回一个与所有其他标识符不同的标识符列表。列表中标识符的数量与 @racket[v] 中元素的数量一样多。@racket[v] 的元素可以是任何内容，但字符串、符号、关键字（可能包装为语法）和标识符元素将嵌入到生成的名称中，这对于调试很有用。

生成的标识符使用驻留符号构建（不是 @racket[gensym]）；另请参见 @secref["print-compiled"]。

@examples[#:eval stx-eval
  (generate-temporaries '(a b c d))
  (generate-temporaries #'(1 2 3 4))
  (define-syntax (set!-values stx)
    (syntax-case stx ()
      [(_ (id ...) expr)
       (with-syntax ([(temp ...) (generate-temporaries #'(id ...))])
         #'(let-values ([(temp ...) expr])
             (set! id temp) ... (void)))]))
]}


@defproc[(identifier-prune-lexical-context [id-stx identifier?]
                                           [syms (listof symbol?) (list (syntax-e id-stx))])
         identifier?]{

返回一个与 @racket[id-stx] 具有相同绑定的标识符，但不包括可能不适用于 @racket[syms] 中符号的 @racket[id-stx] 的词法信息，其中词法信息的进一步扩展会删除其他符号的信息。特别是，通过 @racket[datum->syntax] 从此函数的结果向除 @racket[syms] 中符号之外的其他符号传输词法上下文可能会产生无绑定的标识符。

目前，结果始终精准地是 @racket[id-stx]。剪枝主要旨在作为 Racket 先前版本的一种优化，但在当前宏扩展器中不太有用且难以高效实现。

另请参见 @racket[quote-syntax/prune]。

@history[#:changed "6.5" @elem{始终返回 @racket[id-stx]。}]}


@defproc[(identifier-prune-to-source-module [id-stx identifier?])
         identifier?]{

返回一个标识符，其词法上下文最小化为 @racket[syntax-source-module] 所需的部分。最小化的词法上下文不包含任何绑定。}


@defproc[(syntax-recertify [new-stx syntax?]
                           [old-stx syntax?]
                           [inspector inspector?]
                           [key any/c])
         syntax?]{

仅为向后兼容；返回 @racket[new-stx]。}


@defproc[(syntax-debug-info [stx syntax?]
                            [phase (or/c exact-integer? #f) (syntax-local-phase-level)]
                            [all-bindings? any/c #f])
         hash?]{

生成一个哈希表，描述 @racket[stx] 的 @tech{词法信息}（当 @racket[(syntax-e stx)] 会返回复合值时不计算组件）。结果可以包括但不限于以下键：

@itemlist[

 @item{@racket['name] --- 如果它是符号，则为 @racket[(syntax-e stx)] 的结果。}

 @item{@racket['context] --- 向量的列表，每个向量表示附加到
        @racket[stx] 的范围。
       
        每个向量以一个对该范围唯一的数字开头。
        之后的符号提供了范围来源的线索：@racket['module] 表示 @racket[module] 范围，@racket['macro] 表示宏引入范围，@racket['use-site] 表示宏使用范围，
        或 @racket['local] 表示局部绑定形式。
        在对应于内边缘的 @racket['module] 范围的情况下，
        显示模块的名称和阶段（因为为每个阶段生成的
        内边缘范围）。}

  @item{@racket['bindings] --- 绑定的列表，每个绑定由一个哈希表表示。绑定表可以包括但不限于以下键：

        @itemlist[

          @item{@racket['name] --- 绑定的符号名称。}

          @item{@racket['context] --- 绑定的范围，作为向量列表。}

          @item{@racket['local] --- 局部绑定的符号;当此键存在时，@racket['module] 不存在。}

          @item{@racket['module] --- 来自另一个模块的导入编码;当此键存在时，@racket['local] 不存在。}

          @item{@racket['free-identifier=?] --- 来自绑定作为别名的标识符的调试信息的哈希表。}

          ]}

   @item{@racket['fallbacks] --- 类似于 @racket[syntax-debug-info] 为跨命名空间绑定回退产生的哈希表。}

]
@history[#:added "6.3"]}


@section[#:tag "stx-ops-s1"]{Syntax Object Source Locations}

@note-lib-only[racket/syntax-srcloc]

@defproc[(syntax-srcloc [stx syntax?]) (or/c #f srcloc?)]{

返回 @tech{语法对象} @racket[stx] 的 @tech{源位置}，
如果未知则返回 @racket[#f]。

@history[#:added "8.2.0.5"]}

@; 结束文件
