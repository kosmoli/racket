#lang scribble/doc
@(require "mz.rkt"
          (for-label compiler/embed
                     syntax/modresolve
                     racket/phase+space))

@title{Module Names and Loading}

@(define mod-eval (make-base-eval))

@;------------------------------------------------------------------------
@section[#:tag "modnameresolver"]{解析模块名称}

@margin-note{‘@racketmodname[syntax/modresolve]’ 库提供了用于解析和操作模块名称的额外操作。}

声明的模块的名称由 @deftech{resolved module path} 表示，它封装了一个 symbol 或完整的文件系统路径（参见 @secref["pathutils"]）。symbol 通常指向一个预定义的模块或通过反射评估（例如 @racket[eval]）声明的模块。文件系统路径通常指向通过 @racket[require] 或其他形式按需加载的模块声明。

@deftech{module path} 是一个匹配 @racket[require] 的 @racket[_module-path] 语法的数据值。module path 相对于另一个模块。

@defproc[(resolved-module-path? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{resolved module path}，则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(make-resolved-module-path [path (or/c symbol? 
                                                (and/c path? complete-path?)
                                                (cons/c (or/c symbol?
                                                              (and/c path? complete-path?))
                                                        (non-empty-listof symbol?)))])
         resolved-module-path?]{

返回一个封装了 @racket[path] 的 @tech{resolved module path}，其中列表 @racket[path] 对应于 @tech{submodule} 路径。如果 @racket[path] 是路径或以路径开头，通常应对其进行 @tech{cleanse}（参见 @racket[cleanse-path]）和简化（参见 @racket[simplify-path]，包括查询文件系统）。

@tech{resolved module path} 是 interned 的。也就是说，如果两个 @tech{resolved module path} 值封装的路径是 @racket[equal?] 的，那么这些 @tech{resolved module path} 值就是 @racket[eq?] 的。}

@defproc[(resolved-module-path-name [module-path resolved-module-path?])
         (or/c symbol? 
               (and/c path? complete-path?)
               (cons/c (or/c symbol?
                             (and/c path? complete-path?))
                       (non-empty-listof symbol?)))]{

返回 @tech{resolved module path} 封装的路径或 symbol。列表结果对应于 @tech{submodule} 路径。}


@defproc[(module-path? [v any/c]) boolean?]{

如果 @racket[v] 对应于一个匹配 @racket[require] 的 @racket[_module-path] 语法的数据值，则返回 @racket[#t]，否则返回 @racket[#f]。请注意，路径（即 @racket[path?] 意义上的）是一个 module path。}


@defparam[current-module-name-resolver proc
           (case->
            (resolved-module-path? (or/c #f namespace?) . -> . any)
            (module-path?
             (or/c #f resolved-module-path?)
             (or/c #f syntax?)
             boolean?
             . -> .
             resolved-module-path?))]{

一个 @tech{parameter}，定义当前的 @deftech{module name resolver}，它管理从其他类型的模块引用到 @tech{resolved module path} 的转换。例如，当展开器遇到 @racket[(require _module-path)]（其中 @racket[_module-path] 不是标识符）时，展开器会将 @racket['@#,racket[_module-path]] 传递给 module name resolver 以获取一个 symbol 或 resolved module path。当这样的 @racket[require] 出现在模块内部时，@deftech{module path resolver} 还会接收到外围模块的名称，以便将相对引用转换为绝对 symbol 或 @tech{resolved module path}。 

默认的 @tech{module name resolver} 使用 @racket[collection-file-path] 将 @racket[lib] 和 symbolic-shorthand 模块路径转换为文件系统路径。@racket[collection-file-path] 函数则使用 @racket[current-library-collection-links] 和 @racket[current-library-collection-paths] parameter。

@tech{module name resolver} 接受两个和四个参数：
@itemize[

  @item{当传递两个参数时，第一个是当前在 current namespace 中声明的模块名称，第二个是可选的，表示声明所复制自的 namespace。在这种情况下，module name resolver 的结果被忽略。

  当前的 module name resolver 由 @racket[namespace-attach-module] 或 @racket[namespace-attach-module-declaration] 以两个参数调用，用于通知 resolver 已将 module declaration 附加到当前 namespace（并且今后不应为该 namespace 的 @tech{module registry} 加载）。对 module declaration 的求值也会以两个参数调用当前的 module name resolver，其中第一个参数是声明的模块，第二个是 @racket[#f]。没有其他 Racket 操作会以两个参数调用 module name resolver，但其他工具（如 DrRacket）可能会在此模式下调用此 resolver 以避免冗余的模块加载。}
 
  @item{当传递四个参数时，第一个是 module path，相当于 @racket[require] 的引用形式 @racket[_module-path]。第二个是源模块的名称（如果有的话），路径相对于它；如果第二个参数是 @racket[#f]，则 module path 相对于 @racket[(or (current-load-relative-directory) (current-directory))]。第三个参数是一个 @tech{syntax object}，可用于错误报告（如果不是 @racket[#f]）。如果最后一个参数是 @racket[#t]，则应加载 module declaration（如果尚未加载），否则应单纯将 module path 解析为名称。结果是解析后的名称。}

]

对于第二种情况，标准的 module name resolver 为每个 @tech{module registry} 维护一个包含已加载模块名称的表。如果 resolved module path 不在表中，且向 @tech{module name resolver} 提供的第四个参数不是 @racket[#f]，则将名称放入表中，并使用 @racket[load/use-compiled] 的一个 variant 加载相应文件，该 variant 将期望的模块名称传递给 @tech{compiled-load handler}。

在加载文件时，默认的 @tech{module name resolver} 将 @racket[current-module-declare-name] parameter 设置为解析后的模块名称（而 @tech{compiled-load handler} 设置 @racket[current-module-declare-source]）。此外，默认的 @tech{module name resolver} 在 private @tech{continuation mark} 中记录正在加载的模块，并检查是否已存在这样的 mark；如果当前 continuation 中已存在这样的 continuation mark，则 @exnraise[exn:fail] 并发出有关依赖循环的消息。

默认的 module name resolver 与默认的 @tech{compiled-load handler} 协作：在 module-attach 通知时，@tech{compiled-load handler} 为源 namespace 的 @tech{module registry} 记录的 bytecode-file 信息会被转移到目标 namespace 的 @tech{module registry}。

默认的 module name resolver 还维护一个小型的、与 @tech{module registry} 特定的缓存，将 @racket[lib] 和 symbolic module path 映射到它们的解析结果。在检查 @racket[current-library-collection-links] 和 @racket[current-library-collection-paths] 等 parameter 之前先查询此缓存，因此即使这些 parameter 值发生变化，结果可能会``保持不变''。一个条目仅在向 module name resolver 传递的第四个参数为 true（表明应加载模块）且加载成功时才会被添加到缓存中。

最后，默认的 module name resolver 可能会特殊处理 @racket[submod] 路径。如果 @racket[submod] 形式中作为第一个元素的 module path 引用了不存在的 collection，那么默认的 module name resolver 将为所得的 @tech{resolved module path} 合成一个 uninterned symbol 模块名称，而不是抛出异常。这种对 submodule path 的特殊处理与 @tech{compiled-load handler} 对不存在的 submodule 的特殊处理一致，以便可以更方便地使用 @racket[module-declared?] 来检查 submodule 是否存在。

在 @tech{syntax objects}（参见 @secref["stxobj-model"]）中解析模块路径时，模块加载被抑制（即向 module name resolver 提供 @racket[#f] 作为第四个参数）。当对 @tech{syntax object} 进行操作时，当前 namespace 可能与 syntax object 的原始 namespace 不匹配，因此模块不一定需要在当前 namespace 中加载。

出于历史原因，默认的 module name resolver 目前还接受三个参数，除了两个和四个之外。三个参数被视为与第四个参数为 @racket[#t] 的四个参数相同，不同之处在于还会记录一个错误。对三个参数的支持将在将来版本中被移除。

@racket[current-module-name-resolver] 绑定是以 @racket[protect-out] 意义上的 @tech{protected} 提供的。

@history[#:changed "6.0.1.12" 
         @elem{增加了对默认 module name resolver 在以三个参数调用时的错误日志记录。}
         #:changed "7.0.0.17"
         @elem{增加了默认 module name resolver 对引用不存在 collection 的 @racket[submod] 形式的特殊处理。}
         #:changed "8.2.0.4" @elem{将绑定改为 @tech{protected}。}]}


@defparam[current-module-declare-name name (or/c resolved-module-path? #f)]{

一个 @tech{parameter}，定义在求值 @racket[module] 声明时使用的模块名称（当 parameter 值不是 @racket[#f] 时）。在这种情况下，@racket[module] 声明中的 @racket[_id] 被忽略，parameter 的值被用作所声明模块的名称。

在声明 @tech{submodules} 时，@racket[current-module-declare-name] 决定了用于 submodule 根模块的名称，而 submodule 相对于根模块的路径不受影响。}


@defparam[current-module-declare-source src (or/c symbol? (and/c path? complete-path?) #f)]{

一个 @tech{parameter}，定义在求值 @racket[module] 声明时与模块关联的源信息。源信息用于错误消息中，并由 @racket[variable-reference->module-source] 反射。当 parameter 值为 @racket[#f] 时，模块的名称（由 @racket[current-module-declare-name] 决定）将代替 parameter 值用作源名称。}


@defparam[current-module-path-for-load path (or/c #f module-path? 
                                                  (and/c syntax? 
                                                         (lambda (stx)
                                                           (module-path? (syntax->datum s)))))]{

一个 @tech{parameter}，定义由默认的 @tech{load handler} 抛出的 @racket[exn:fail:syntax:missing-module] 和 @racket[exn:fail:filesystem:missing-module] 异常中使用的 module path。该 parameter 通常由 @tech{module name resolver} 设置。}

@;------------------------------------------------------------------------
@section[#:tag "modpathidx"]{编译后的模块和引用}

在展开 @racket[module] 声明时，展开器会解析导入的 module path，以便在必要时加载模块声明并确定导入的绑定，但 @racket[module] 声明的编译形式保留了原始的 module path。因此，编译后的模块可以被移动到另一个文件系统，在那里 module name resolver 可以解析编译代码之间的模块间引用。

当从编译形式（参见 @racket[module-compiled-imports]）或 macro expansion 中的 syntax object（参见 @secref["stxops"]）提取模块引用时，该模块引用以 @deftech{module path index} 的形式报告。@tech{module path index} 是一个 semi-interned（多个对相同相对模块的引用通常使用相同的 @tech{module path index} 值，但并非总是如此）的不透明值，它编码了 module path（参见 @racket[module-path?]）以及一个 @tech{resolved module path} 或其所相对的另一个 @tech{module path index}。

一个对其 path 和 base @tech{module path index} 都使用 @racket[#f] 的 @tech{module path index} 表示``self''——即作为 @tech{module path index} 来源的 module declaration——并且这样的 @tech{module path index} 可以在编译时用作 @tech{module path index} 链的根节点。例如，在提取模块内标识符绑定的信息时，如果该标识符是由同一模块内的定义绑定的，则该标识符的源模块使用``self'' @tech{module path index} 来报告。如果该标识符是通过 module path（而非字面的模块名称）导入的模块中定义的，则该标识符的源模块将使用包含 @racket[require] 的 module path 和``self'' @tech{module path index} 的 @tech{module path index} 来报告。当``self'' @tech{module path index} 所指的模块是 @tech{submodule} 时，它拥有一个 submodule path。

@tech{module path index} 有状态。当它被 @deftech{resolved} 为一个 @tech{resolved module path} 时，@tech{resolved module path} 会被存储在 @tech{module path index} 中。特别地，当一个模块被加载时，其 root @tech{module path index} 会被 resolved 为与该模块的声明时名称匹配。然而，在该模块贡献给其他模块的编译和 marshaled 形式的标识符中，这个 resolved path 会被遗忘。resolved name 的暂态性质允许模块代码以与编译时不同的 resolved name 加载。

当两个 @tech{module path index} 值具有 @racket[equal?] 的 path 和 base 值时，它们是 @racket[equal?] 的（即使它们的 @tech{resolved} 值不同）。

@defproc[(module-path-index? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{module path index}，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(module-path-index-resolve [mpi module-path-index?]
                                    [load? any/c #f]
                                    [src-stx (or/c syntax? #f) #f])
         resolved-module-path?]{

返回 resolved module name 的 @tech{resolved module path}，如果 resolved name 之前未被计算过，则计算它（并存储在 @racket[mpi] 中）。

解析 @tech{module path index} 使用当前的 @tech{module name resolver}（参见 @racket[current-module-name-resolver]）。根据 @racket[mpi] 封装的 module path 类型，计算出的 resolved name 可能取决于 @racket[current-load-relative-directory] 或 @racket[current-directory] 的值。@racket[load?] 参数作为最后一个参数传递给 @tech{module name resolver}，而 @racket[src-stx] 参数作为倒数第二个参数传递。

请注意，在共享 module registry 的 namespace 中进行并发解析可能会在加载模块时产生 race condition。另见 @racket[namespace-call-with-registry-lock]。

如果 @racket[mpi] 表示一个非展开器创建的、尚未 resolved 的``self''(参见上文) module path，则 @racket[module-path-index-resolve] 在不调用 module name resolver 的情况下抛出 @racket[exn:fail:contract]。

另见 @racket[resolve-module-path-index]。

@history[#:changed "6.90.0.16" @elem{增加了 @racket[load?] 可选参数。}
         #:changed "8.2" @elem{增加了 @racket[src-stx] 可选参数。}]}


@defproc[(module-path-index-split [mpi module-path-index?])
         (values (or/c module-path? #f)
                 (or/c module-path-index? resolved-module-path? #f))]{

返回两个值：一个 module path，以及一个 base path——即 @tech{module path index}、@tech{resolved module path} 或 @racket[#f]——第一个路径相对于它。

第二个结果为 @racket[#f] 表示路径相对于一个未指定的目录（即其解析取决于 @racket[current-load-relative-directory] 和/或 @racket[current-directory] 的值）。

第一个结果为 @racket[#f] 意味着第二个结果也是 @racket[#f]，并且表示 @racket[mpi] 代表``self''(参见上文)。这样的 @tech{module path index} 可能拥有一个非 @racket[#f] 的 submodule path，如 @racket[module-path-index-submodule] 所报告的那样。}


@defproc[(module-path-index-submodule [mpi module-path-index?])
         (or/c #f (non-empty-listof symbol?))]{

如果 @racket[mpi] 是一个引用 @tech{submodule} 的``self''(参见上文) @tech{module path index}，则返回一个非空的 symbol 列表。如果 @racket[(module-path-index-split mpi)] 的任一结果是非 @racket[#f] 的，则结果总是 @racket[#f]。}


@defproc[(module-path-index-join [path (or/c module-path? #f)]
                                 [base (or/c module-path-index? resolved-module-path? #f)]
                                 [submod (or/c #f (non-empty-listof symbol?)) #f])
         module-path-index?]{

将 @racket[path]、@racket[base] 和 @racket[submod] 组合为一个新的 @tech{module path index}。@racket[path] 参数仅在 @racket[base] 也是 @racket[#f] 时才能为 @racket[#f]。@racket[submod] 参数仅在 @racket[path] 和 @racket[base] 都是 @racket[#f] 时才能是列表。}

@defproc[(compiled-module-expression? [v any/c]) boolean?]{

如果 @racket[v] 是编译后的 @racket[module] 声明，则返回 @racket[#t]，否则返回 @racket[#f]。另见 @racket[current-compile]。}


@defproc*[([(module-compiled-name [compiled-module-code compiled-module-expression?])
            (or/c symbol? (cons/c symbol? (non-empty-listof symbol?)))]
           [(module-compiled-name [compiled-module-code compiled-module-expression?]
                                  [name (or/c symbol? (cons/c symbol? (non-empty-listof symbol?)))])
            compiled-module-expression?])]{

接受编译形式的 module declaration，获取编译后模块的声明名称（当未提供 @racket[name] 时），或返回带有给定 @racket[name] 的修改后的 module declaration。

名称是一个 symbol（对于顶层模块），或者是一个 symbol 与一个 symbol 列表配对，其中该列表反映了从顶层模块的声明名称开始的到该模块的 @tech{submodule} 路径。}


@defproc*[([(module-compiled-submodules [compiled-module-code compiled-module-expression?]
                                        [non-star? any/c])
            (listof compiled-module-expression?)]
           [(module-compiled-submodules [compiled-module-code compiled-module-expression?]
                                        [non-star? any/c]
                                        [submodules (listof compiled-module-expression?)])
            compiled-module-expression?])]{

接受编译形式的 module declaration，获取模块的 @tech{submodules}（当未提供 @racket[submodules] 时），或返回带有给定 @racket[submodules] 的修改后的 module declaration。@racket[non-star?] 参数决定结果或新的 submodule 列表是对应于 @racket[module] 声明（@racket[non-star?] 为 true 时）还是 @racket[module*] 声明（@racket[non-star?] 为 @racket[#f] 时）。}


@defproc[(module-compiled-imports [compiled-module-code compiled-module-expression?])
         (listof (cons/c (or/c exact-integer? #f) 
                         (listof module-path-index?)))]{

接受编译形式的 module declaration，返回一个 association list，将 @tech{phase level} 变换（其中 @racket[#f] 对应于进入 @tech{label phase level} 的变换）映射到该模块显式导入的模块引用。}


@defproc[(module-compiled-exports [compiled-module-code compiled-module-expression?]
                                  [verbosity (or/c #f 'defined-names) #f])
         (values (listof (cons/c phase+space? list?))
                 (listof (cons/c phase+space? list?)))]{

返回两个 association list，将 @tech{phase level} 和 @tech{binding space} 的组合映射到相应 phase 和 space 中的导出。第一个 association list 对应于导出的变量，第二个对应于导出的 syntax。但请注意，通过 @tech{rename transformer} 重新导出的值绑定将出现在 syntax 列表中，而非值列表中。有关 phase-and-space 表示的信息，请参阅 @racket[phase+space?]。

每个 associated list，在上述结果 contract 中由 @racket[list?] 表示，更精确地匹配以下 contract：

@racketblock[
(listof (list/c symbol?
                (listof 
                 (or/c module-path-index?
                       (list/c module-path-index?
                               phase+space?
                               symbol?
                               phase+space?)))
                (code:comment @#,elem{only if @racket[verbosity] is @racket['defined-names]:})
                symbol?))
]

对于列表中的每个元素，开头的 symbol 是导出的名称。

第二部分——即 @tech{module path index} 值的列表等——描述了所导出标识符的来源。如果来源列表为 @racket[null]，则所导出的标识符在该模块中定义。如果所导出的标识符是被重新导出的，则来源列表提供了有关被重新导出的导入的信息。如果绑定被从（可能的）不同来源多次导入，则来源列表可能有多个元素。

最后一部分，即一个 symbol，仅在 @racket[verbosity] 为 @racket['defined-names] 时才包含。在这种情况下，所包含的 symbol 是该定义在其定义模块内的名称（可能与导出的名称不同）。

对于每个 origin，@tech{module path index} 单独出现表示该绑定是以 @tech{phase level} 变换 @racket[0]（即没有 @racket[for-meta]、@racket[for-syntax] 等的普通 @racket[require]）导入到默认的 @tech{binding space}（即没有 @racket[for-space]），并且导入的标识符与重新导出的名称相同。用列表表示的 origin 显式指示了导入项、导入的标识符所绑定在的 @tech{phase level} 和 @tech{binding space}（有关表示的更多信息，请参阅 @racket[phase+space?]）、导入的标识符在导入模块中的 symbolic name，以及导出模块中标识符的 @tech{phase level} 和 @tech{binding space}。

@examples[#:eval mod-eval
          (module-compiled-exports
           (compile
            '(module banana racket/base
               (require (only-in racket/math pi)
                        (for-syntax racket/base))
               (provide pi
                        (rename-out [peel wrapper])
                        bush
                        cond
                        (for-syntax compile-time))
               (define peel pi)
               (define bush (* 2 pi))
               (begin-for-syntax
                 (define compile-time (current-seconds)))))
           'defined-names)]

@history[#:changed "7.5.0.6" @elem{增加了 @racket[verbosity] 参数。}
         #:changed "8.2.0.3" @elem{将结果泛化为 phase--space 组合。}]}



@defproc[(module-compiled-indirect-exports [compiled-module-code compiled-module-expression?])
         (listof (cons/c exact-integer? (listof symbol?)))]{

返回一个 association list，将 @tech{phase level} 值映射到表示模块内变量的 symbol。这些定义不能从源代码直接访问，但可以从 bytecode 访问，且每个列表中 symbol 的顺序对应于 bytecode 访问的顺序。

@history[#:added "6.5.0.5"]}


@defproc[(module-compiled-language-info [compiled-module-code compiled-module-expression?])
         (or/c #f (vector/c module-path? symbol? any/c))]{

@guidealso["module-runtime-config"]

返回旨在反映模块实现``语言''的信息，该信息最初通过 @indexed-racket['module-language] @tech{syntax property} 附加到模块声明的 syntax 上。另见 @racket[module]。

如果模块没有可用的信息，结果为 @racket[#f]。否则，结果为 @racket[(vector _mp _name _val)]，使得 @racket[((dynamic-require _mp _name) _val)] 应返回一个接受两个参数的函数。该函数的参数是一个用于反射信息的 key 和一个默认值。可接受的 key 和对结果的解释由外部工具（如 DrRacket）决定。如果对于给定 key 没有可用的信息，结果应为给定的默认值。

另见 @racket[module->language-info] 和 @racketmodname[racket/language-info]。}

@defproc[(module-compiled-cross-phase-persistent?
          [compiled-module-code compiled-module-expression?])
         boolean?]{

如果 @racket[compiled-module-code] 表示一个 @tech{cross-phase persistent} 模块，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(module-compiled-realm [compiled-module-code compiled-module-expression?])
         symbol?]{

返回 @racket[compiled-module-code] 所表示模块的 @tech{realm}。

@history[#:added "8.4.0.2"]}

@;------------------------------------------------------------------------
@section[#:tag "dynreq"]{动态模块访问}

@defproc[(dynamic-require [mod (or/c module-path?
                                     resolved-module-path?
                                     module-path-index?)]
                          [provided (or/c symbol? #f 0 void?)]
                          [fail-thunk (or/c 'error (-> any)) 'error]
                          [syntax-thunk (or/c 'eval (-> any)) 'eval])
         (or/c void? any/c)]{

@margin-note{因为 @racket[dynamic-require] 是一个 procedure，像 @racket[require] 表达式那样传递普通的 S-expression 给 @racket[mod] 可能不会得到预期的结果。你需要的是一个能求值为 S-expression 的东西；使用 @racket[quote] 是其中一种方法。}

在当前 namespace registry 中，在该 namespace 的 @tech{base phase} 上动态 @tech{instantiates} @racket[mod] 所指定的模块（如果尚未 @tech{instantiate}）。当前的 @tech{module name resolver} 可能会加载 module declaration 来解析 @racket[mod]（参见 @racket[current-module-name-resolver]）；路径相对于 @racket[current-load-relative-directory] 和/或 @racket[current-directory] 进行解析。请注意，在共享 @tech{module registry} 的 namespace 中并发执行 @racket[dynamic-require] 可能会产生 race condition；另见 @racket[namespace-call-with-registry-lock]。

如果 @racket[provided] 为 @racket[#f]，则结果为 @|void-const|，并且模块不会被 @tech{visit}（参见 @secref["mod-parse"]），也不会在 @tech{base phase} 之上的更高 phase 中变得 @tech{available}（用于按需 @tech{visits}）。

@examples[#:eval mod-eval
  (module a racket/base (displayln "hello"))
  (dynamic-require ''a #f)
]

@margin-note{双引号的 @racket[''a] 求值为 @racket[_root-module-path] @racket['a]（参见 @racket[require] 的语法）。使用 @racket['a] 作为 @racket[mod] 是不行的，因为它求值为 @racket[_root-module-path] @racket[a]，而例子中的模块并非安装在 collection 中。使用 @racket[a] 也不行，因为 @racket[a] 是一个未定义的变量。

在另一个模块内部声明 @racket[(module a ....)]（而非在 @racket[read-eval-print] 循环中）将创建一个 submodule。在这种情况下，@racket[(dynamic-require ''a #f)] 不会访问该模块，因为 @racket[''a] 不引用 submodule。}

当 @racket[provided] 是一个 symbol 时，模块中具有该给定名称的导出的值将被返回，且模块仍然不会在更高的 phase 中被 @tech{visit} 或变得 @tech{available}。

@examples[#:eval mod-eval
  (module b racket/base
    (provide dessert)
    (define dessert "gulab jamun"))
  (dynamic-require ''b 'dessert)
]

如果模块以 syntax 形式导出 @racket[provided]，则如果 @racket[syntax-thunk] 是一个 procedure，将调用它，其结果即为 @racket[dynamic-require] 调用的结果。如果 @racket[syntax-thunk] 为 @racket['eval]，则在一个全新的 namespace 中展开并求值该绑定的使用，该 namespace 附加了该模块，这意味着该模块在这个全新的 namespace 中被 @tech{visit}。展开后的 syntax 必须返回单一值。

@examples[#:eval mod-eval
  (module c racket/base
    (require (for-syntax racket/base))
    (provide dessert2)
    (define dessert "nanaimo bar")
    (define-syntax dessert2
      (make-rename-transformer #'dessert)))
  (dynamic-require ''c 'dessert2)
]

如果模块没有这样的导出变量或 syntax，则调用 @racket[fail-thunk]，或者如果 @racket[fail-thunk] 为 @racket['error]，则 @exnraise[exn:fail:contract]。如果 @racket[provided] 所命名的变量是 protected 导出的（参见 @secref["modprotect"]），则 @exnraise[exn:fail:contract]。

如果 @racket[provided] 为 @racket[0]，则模块被 @tech{instantiate} 但不被 @tech{visit}，与 @racket[provided] 为 @racket[#f] 时相同。但对于 @racket[0]，模块在更高的 phase 中变得 @tech{available}。

如果 @racket[provided] 为 @|void-const|，则模块被 @tech{visit} 但不被 @tech{instantiate}（参见 @secref["mod-parse"]），结果为 @|void-const|。

以下是使用不同的 @racket[module-path] 语法表达式的更多示例：

@examples[#:eval mod-eval
  (dynamic-require 'racket/base #f)
]

@examples[#:eval mod-eval
  (dynamic-require (list 'lib "racket/base") #f)
]

@examples[#:eval mod-eval
  (module a racket/base
    (module b racket/base
      (provide inner-dessert)
      (define inner-dessert "tiramisu")))
  (dynamic-require '(submod 'a b) 'inner-dessert)
]

上述示例中的最后一行也可以写成

@examples[#:eval mod-eval
  (dynamic-require ((lambda () (list 'submod ''a 'b))) 'inner-dessert)
]

它们是等价的。

@history[#:changed "8.16.0.3" @elem{增加了 @racket[syntax-thunk] 参数，并改为允许 @racket['error] 作为 @racket[fail-thunk]。}]}


@defproc[(dynamic-require-for-syntax [mod module-path?]
                                     [provided (or/c symbol? #f)]
                                     [fail-thunk (or/c 'error (-> any)) 'error]
                                     [syntax-thunk (or/c 'eval (-> any)) 'eval])
         any]{

与 @racket[dynamic-require] 类似，但在比 namespace 的 @tech{base phase} 高 @math{1} 的 @tech{phase} 中。

@history[#:changed "8.16.0.3" @elem{增加了 @racket[syntax-thunk] 参数，并改为允许 @racket['error] 作为 @racket[fail-thunk]。}]}


@defproc[(module-declared?
          [mod (or/c module-path? module-path-index? 
                     resolved-module-path?)]
          [load? any/c #f])
         boolean?]{

如果 @racket[mod] 所指示的模块在当前 namespace 中已 @tech{declare}（但不一定 @tech{instantiate} 或 @tech{visit}），则返回 @racket[#t]，否则返回 @racket[#f]。

如果 @racket[load?] 为 @racket[#t] 且 @racket[mod] 不是 @tech{resolved module path}，则在解析 @racket[mod] 的过程中加载模块（与 @racket[dynamic-require] 和其他函数类似）。检查 @tech{submodule} 的声明时，如果 submodule 因为不存在而无法加载（无论是在一个存在的 root module 内部，还是因为 root module 不存在），不会触发异常。}


@defproc[(module->language-info
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)]
          [load? any/c #f])
         (or/c #f (vector/c module-path? symbol? any/c))]{

返回旨在反映 @racket[mod] 实现``语言''的信息。如果 @racket[mod] 是 @tech{resolved module path} 或 @racket[load?] 为 @racket[#f]，则 @racket[mod] 所命名的模块必须在当前 namespace 中已 @tech{declare}（但不一定 @tech{instantiate} 或 @tech{visit}）；否则，@racket[mod] 可能被加载（与 @racket[dynamic-require] 和其他函数类似）。@racket[module->language-info] 返回的信息与将 @racket[module-compiled-language-info] 应用于模块作为编译代码的实现时所返回的信息相同。

可以通过使用 @racket[dynamic-require] 来 @tech{declare} 一个模块。

@examples[#:eval mod-eval
          (dynamic-require 'racket/dict (void))
          (module->language-info 'racket/dict)]}

@defproc[(module->imports
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)])
         (listof (cons/c (or/c exact-integer? #f) 
                         (listof module-path-index?)))]{

 与 @racket[module-compiled-imports] 类似，但产生 @racket[mod] 的导入，后者必须在当前 namespace 中已 @tech{declare}（但不一定 @tech{instantiate} 或 @tech{visit}）。有关声明已存在模块的示例，请参阅 @racket[module->language-info]。
 
@examples[#:eval mod-eval
          (module banana racket/base
            (require (only-in racket/math pi))
            (provide peel)
            (define peel pi)
            (define bush (* 2 pi)))
          (module->imports ''banana)]}


@defproc[(module->exports
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)]
          [verbosity (or/c #f 'defined-names) #f])
         (values (listof (cons/c phase+space? list?))
                 (listof (cons/c phase+space? list?)))]{

 与 @racket[module-compiled-exports] 类似，但产生 @racket[mod] 的导出，后者必须在当前 namespace 中已 @tech{declare}（但不一定 @tech{instantiate} 或 @tech{visit}）。有关声明已存在模块的示例，请参阅 @racket[module->language-info]。
 
@examples[#:eval mod-eval
          (module banana racket/base
            (require (only-in racket/math pi))
            (provide (rename-out [peel wrapper]))
            (define peel pi)
            (define bush (* 2 pi)))
          (module->exports ''banana)]

@history[#:changed "7.5.0.6" @elem{增加了 @racket[verbosity] 参数。}
         #:changed "8.2.0.3" @elem{将结果泛化为 phase--space 组合。}]}


@defproc[(module->indirect-exports
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)])
         (listof (cons/c exact-integer? (listof symbol?)))]{

 与 @racket[module-compiled-indirect-exports] 类似，但产生 @racket[mod] 的间接导出，后者必须在当前 namespace 中已 @tech{declare}（但不一定 @tech{instantiate} 或 @tech{visit}）。有关声明已存在模块的示例，请参阅 @racket[module->language-info]。

@examples[#:eval mod-eval
          (module banana racket/base
            (require (only-in racket/math pi))
            (provide peel)
            (define peel pi)
            (define bush (* 2 pi)))
          (module->indirect-exports ''banana)]

@history[#:added "6.5.0.5"]}


@defproc[(module->realm 
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)])
         symbol?]{

 与 @racket[module-compiled-realm] 类似，但产生 @racket[mod] 的 @tech{realm}，后者必须在当前 namespace 中已 @tech{declare}（但不一定 @tech{instantiate} 或 @tech{visit}）。

@history[#:added "8.4.0.2"]}


@defproc[(module-predefined?
          [mod (or/c module-path? module-path-index?
                     resolved-module-path?)])
         boolean?]{

报告 @racket[mod] 是否引用了一个为当前运行的 Racket 实例预定义的模块。预定义的模块总是拥有 symbolic resolved module path，它们可能是永远预定义的，也可能是特定于某个可执行文件的（例如通过 @exec{raco exe} 或 @racket[create-embedding-executable] 创建的）。}

@(close-eval mod-eval)

@;------------------------------------------------------------------------
@section[#:tag "modcache"]{模块缓存}

展开器维护一个 place-local module cache，以便在加载先前已声明的模块时节省时间。

@defproc[(module-cache-clear!) void?]{
  清除 place-local module cache。

  @history[#:added "8.4.0.5"]
}
