#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "Namespaces"]{Namespaces}

参见 @secref["namespace-model"] 了解 @tech{namespace} 模型的基本信息。

@tech{namespace} 通过 @racket[make-empty-namespace] 和 @racket[make-base-namespace]
等过程创建，它们返回 first-class namespace 值。Namespace 可通过设置
@racket[current-namespace] 参数值，或将 namespace 传给 @racket[eval] 和
@racket[eval-syntax] 等过程来使用。

@defproc[(namespace? [v any/c]) boolean?]{

如果 @racket[v] 是 namespace 值则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-empty-namespace) namespace?]{

创建一个为空的 @tech{namespace}，其 @tech{module registry} 仅包含
某些内部预定义 module(如 @racket['#%kernel])的映射。该 namespace 的
@tech{base phase} 与 @tech{current namespace} 的 @tech{base phase} 相同。
使用 @racket[namespace-attach-module] 从现有 namespace 向新 namespace
attach module。

新 namespace 与一个新的 @deftech{root namespace} 关联，
它具有与返回 namespace 相同的 @tech{module registry}，且 @tech{base phase} 为 0。
如果新 @tech{root namespace} 和返回 namespace 的 @tech{base phase} 均为 0，
则两者相同。}


@defproc[(make-base-empty-namespace) namespace?]{

创建一个像 @racket[make-empty-namespace] 一样的新空 @tech{namespace}，
但 attach 了 @racketmodname[racket/base]。该 namespace 的 @tech{base phase}
与创建 @racket[make-base-empty-namespace] 函数时的 @tech{phase} 相同。}


@defproc[(make-base-namespace) namespace?]{

创建一个像 @racket[make-empty-namespace] 一样的新 @tech{namespace}，
但 attach 了 @racketmodname[racket/base] 并 @racket[require] 到 top-level 环境。
该 namespace 的 @tech{base phase} 与创建 @racket[make-base-namespace]
函数时的 @tech{phase} 相同。}


@defform[(define-namespace-anchor id)]{

将 @racket[id] 绑定到 namespace anchor，可与
@racket[namespace-anchor->empty-namespace] 和
@racket[namespace-anchor->namespace] 一起使用。

此形式只能用于 @tech{top-level context} 或 @tech{module-context}。}


@defproc[(namespace-anchor? [v any/c]) boolean?]{

如果 @racket[v] 是 namespace-anchor 值则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(namespace-anchor->empty-namespace [a namespace-anchor?]) namespace?]{

返回一个空 namespace，与锚的源共享 @tech{module registry}
和 @tech{root namespace}，其 @tech{base phase} 是创建锚时的 @tech{phase}。

如果锚来自 module 上下文中的 @racket[define-namespace-anchor] 形式，
则源是实例化外层 module 的 namespace。如果锚来自 top-level 内容中的
@racket[define-namespace-anchor] 形式，则源是求值锚定义的 namespace。}


@defproc[(namespace-anchor->namespace [a namespace-anchor?]) namespace?]{

返回与锚的源对应的 namespace。

如果锚来自 module 上下文中的 @racket[define-namespace-anchor] 形式，
则结果是锚的 phase 中 module 主体的 namespace。结果与通过
@racket[module->namespace] 获得的 namespace 相同，module 同样被
@tech{available}(如果尚未可用)。

如果锚来自 top-level 内容中的 @racket[define-namespace-anchor] 形式，
则结果是求值锚定义的 namespace。}


@defparam[current-namespace n namespace?]{

确定 @techlink{current namespace} 的 @tech{parameter}。}


@defproc[(namespace-symbol->identifier [sym symbol?]) identifier?]{

类似于限制为 symbol 的 @racket[datum->syntax]。结果标识符的
@tech{lexical information} 对应于当前 namespace 的 top-level 环境；
该标识符没有 source location 或 property。}


@defproc[(namespace-base-phase [namespace namespace? (current-namespace)]) exact-integer?]{

返回 @racket[namespace] 的 @tech{base phase}。}


@defproc[(namespace-module-identifier [where (or/c namespace? exact-integer? #f)
                                             (current-namespace)])
         identifier?]{

返回一个标识符，其 binding 在 @racket[where] 的 @tech{base phase}
(如果是 namespace)中为 @racket[module]，否则在 @racket[where] 的
@tech{phase level} 中。

标识符的 @tech{lexical information} 包含完全展开代码中出现的
所有 syntactic form 的 binding(在同一 @tech{phase level} 中)，
但使用 @racket[identifier-binding] 第二个元素报告的 binding 名称；
@tech{lexical information} 也可能包含其他 binding。}


@defproc[(namespace-variable-value [sym symbol?]
                                   [use-mapping? any/c #t]
                                   [failure-thunk (or/c (-> any) #f) #f]
                                   [namespace namespace? (current-namespace)])
         any]{

返回 @racket[namespace] 中 @racket[sym] 的值，使用 @racket[namespace]
的 @tech{base phase}。返回值取决于 @racket[use-mapping?]：

 @itemize[

   @item{如果 @racket[use-mapping?] 为真(默认值)，且
   @racket[sym] 映射到 top-level variable 或 imported variable
   (参见 @secref["namespace-model"])，则结果与将 @racket[sym]
   作为表达式求值相同。如果 @racket[sym] 映射到 syntax 或 imported syntax，
   则调用 @racket[failure-thunk] 或 @exnraise[exn:fail:syntax]。
   如果 @racket[sym] 映射到 undefined variable 或未初始化的 module variable，
   则调用 @racket[failure-thunk] 或 @exnraise[exn:fail:contract:variable]。}

   @item{如果 @racket[use-mapping?] 为 @racket[#f]，则忽略 namespace
   的 syntax 和 import 映射。相反，返回 namespace 中名为 @racket[sym]
   的 top-level variable 的值。如果该 variable 未定义，则调用
   @racket[failure-thunk] 或 @exnraise[exn:fail:contract:variable]。}

 ]

如果 @racket[failure-thunk] 不是 @racket[#f]，
@racket[namespace-variable-value] 调用 @racket[failure-thunk]
来产生返回值，而不是引发 @racket[exn:fail:contract:variable] 或
@racket[exn:fail:syntax] 异常。}
 

@defproc[(namespace-set-variable-value! [sym symbol?]
                                        [v any/c]
                                        [map? any/c #f]
                                        [namespace namespace? (current-namespace)]
                                        [as-constant? any/c #f])
         void?]{

在 @racket[namespace] 的 @tech{base phase} 的 top-level 环境中设置
@racket[sym] 的值，如果尚未定义则定义 @racket[sym]。

如果 @racket[map?] 为真，则 namespace 的 @tech{identifier} 映射
也会在对应于 @tech{base phase} 的 @tech{phase level} 中调整
(参见 @secref["namespace-model"])，使 @racket[sym] 映射到该 variable。

如果 @racket[as-constant?] 为真，则在 @racket[v] 被安装为值后，
该 variable 成为 constant(因此后续赋值会被拒绝)。

@history[#:changed "6.90.0.14" @elem{Added the @racket[as-constant?] argument.}]}


@defproc[(namespace-undefine-variable! [sym symbol?]
                                       [namespace namespace? (current-namespace)])
         void?]{

移除 @racket[namespace] 在其 @tech{base phase} 的 top-level 环境中
的 @racket[sym] variable(如果存在)。Namespace 的 @tech{identifier} 映射
(参见 @secref["namespace-model"])不受影响。}

 
@defproc[(namespace-mapped-symbols [namespace namespace? (current-namespace)])
         (listof symbol?)]{

返回所有映射到 @racket[namespace] 中 variable、syntax 和 import
的 symbol 的 list，对应于 @tech{namespace} 的 @tech{base phase} 的 @tech{phase level}。}



@defproc[(namespace-require [quoted-raw-require-spec any/c]
                            [namespace namespace? (current-namespace)])
         void?]{

在 @racket[namespace] 的 top-level 环境中执行对应于
@racket[quoted-raw-require-spec] 的 import，类似于 top-level 的
@racket[#%require]。@racket[quoted-raw-require-spec] 参数必须是对应于
@racket[#%require] 的 quoted @racket[_raw-require-spec] 的数据
(包括 module path)，也可以是 @tech{resolved module path}。

@racket[quoted-raw-require-spec] 中的 module path 是相对于
@racket[current-load-relative-directory] 或 @racket[current-directory]
(如果前者是 @racket[#f])解析的，即使当前 namespace 对应于 module 主体。

@history[#:changed "6.90.0.16" @elem{Added the @racket[namespace] optional argument.}]}



@defproc[(namespace-require/copy [quoted-raw-require-spec any/c]
                                 [namespace namespace? (current-namespace)])
         void?]{

类似于 @racket[namespace-require]，用于 module 导出的 syntax，
但对 namespace 的 @tech{base phase} 的导出 variable 处理不同：
导出项的当前值被复制到 @racket[namespace] 中的 top-level variable。

@history[#:changed "6.90.0.16" @elem{Added the @racket[namespace] optional argument.}]}


@defproc[(namespace-require/constant [quoted-raw-require-spec any/c]
                                     [namespace namespace? (current-namespace)])
         void?]{

类似于 @racket[namespace-require]，但对于 @tech{namespace} 的
@tech{base phase} 的每个导出 variable，导出项的值被复制到对应的
top-level variable 并被设为 immutable。尽管设置了 top-level variable，
对应的标识符仍作为 imported 绑定。

@history[#:changed "6.90.0.16" @elem{Added the @racket[namespace] optional argument.}]}


@defproc[(namespace-require/expansion-time [quoted-raw-require-spec any/c]
                                           [namespace namespace? (current-namespace)])
         void?]{

类似于 @racket[namespace-require]，但仅相对于 @racket[namespace] 的
@tech{base phase} 执行 module 的 transformer 部分；即 module 仅被
@tech{visit}，而未被 @tech{instantiate}(参见 @secref["mod-parse"])。
如果所需 module 之前未被实例化，则 module 的 variable 保持未定义状态。

@history[#:changed "6.90.0.16" @elem{Added the @racket[namespace] optional argument.}]}


@defproc[(namespace-attach-module [src-namespace namespace?]
                                  [modname (or module-path? resolved-module-path?)]
                                  [dest-namespace namespace? (current-namespace)])
         void?]{

 将 @racket[src-namespace] 中由 @racket[modname] 命名的已实例化 module
 (在其 @tech{base phase})attach 到 @racket[dest-namespace] 的
 @tech{module registry}。

 除 @racket[modname] 外，它导入的每个 module(直接或间接)
 也会被记录在当前 namespace 的 @tech{module registry} 中，
 且相同 @tech{phase} 的实例也会被 attach 到 @racket[dest-namespace]
 (而 module 的 phase 上的 @tech{visit} 以及更高或更低 phase 上的实例
 不会被 attach，甚至不会为按需 @tech{visit} 而 @tech{available})。
 @racket[dest-namespace] 中 module 调用的 inspector 与
 @racket[src-namespace] 中调用的 inspector 相同。

 如果 @racket[modname] 不是 symbol，则调用当前 module name resolver
 来解析路径，但不加载 module；@racket[modname] 的解析形式用作
 @racket[dest-namespace] 中的 module name。

 如果 @racket[modname] 引用 submodule 或带 submodule 的 module，
 除非 module 是从字节码(即 @filepath{.zo} 文件)加载的，
 独立于同一 top-level module 内的 submodule，
 则 module 的 top-level module 内所有 submodule 的声明也会被
 attach 到 @racket[dest-namespace]。

 如果 @racket[modname] 不引用 @racket[src-namespace] 中
 @tech{instantiate} 的 module，或任何要 attach 的 module 的名称
 在 @racket[dest-namespace] 中已有不同的声明或相同 @tech{phase} 的实例，
 则 @exnraise[exn:fail:contract]。

 如果 @racket[src-namespace] 和 @racket[dest-namespace]
 没有相同的 @tech{base phase}，则 @exnraise[exn:fail:contract]。

 与 @racket[namespace-require] 不同，
 @racket[namespace-attach-module] 不会 @tech{instantiate} module，
 而是将 module 实例从源 namespace 复制到目标 namespace。

@examples[
 (module food racket/base
   (provide apple)
   (define apple (list "pie")))
 (namespace-require ''food)
 (define ns (current-namespace))
 (eval:error
  (parameterize ([current-namespace (make-base-namespace)])
    (namespace-require ''food)))
 (parameterize ([current-namespace (make-base-namespace)])
   (namespace-attach-module ns ''food)
   (namespace-require ''food)
   (eq? (eval 'apple) apple))
 (parameterize ([current-namespace (make-base-namespace)])
   (namespace-attach-module-declaration ns ''food)
   (namespace-require ''food)
   (eq? (eval 'apple) apple))]}

@defproc[(namespace-attach-module-declaration [src-namespace namespace?]
                                              [modname module-path?]
                                              [dest-namespace namespace? (current-namespace)])
         void?]{

类似于 @racket[namespace-attach-module]，但 @racket[modname]
指定的 module 只需在 @racket[src-namespace] 中声明(不必 @tech{instantiate})，
且 module 仅在 @racket[dest-namespace] 中声明。}


@defproc[(namespace-unprotect-module [inspector inspector?]
                                     [modname module-path?]
                                     [namespace namespace? (current-namespace)])
         void?]{

更改 @racket[namespace] 的 @tech{module registry} 中 @racket[modname]
引用的 module 实例的 inspector，使其由当前 code inspector 控制。
给定的 @racket[inspector] 必须当前控制 @racket[namespace] 的
@tech{module registry} 中 module 的调用，否则 inspector 不会更改。
另参见 @secref["modprotect"]。}


@defproc[(namespace-module-registry [namespace namespace?])
         any]{

返回给定 namespace 的 @tech{module registry}。此值仅对通过
@racket[eq?] 进行标识有用。}


@defproc[(namespace-call-with-registry-lock [namespace namespace?]
                                            [thunk (-> any)])
         any]{

在持有 namespace 的 @tech{module registry} 的可重入锁时调用 @racket[thunk]。

Namespace 函数不会自动使用 registry lock，但可以通过
@racket[namespace-call-with-registry-lock] 在加载和实例化 module 的
线程之间使用以避免内部竞态条件。@tech{available} module 的按需
@tech{instantiation} 也会获取该锁；参见 @secref["mod-parse"]。

@history[#:added "8.1.0.5"]}

@defproc[(module->namespace [mod (or/c module-path? 
                                       resolved-module-path? 
                                       module-path-index?)]
                            [src-namespace namespace? (current-namespace)])
         namespace?]{

返回一个 namespace，对应于 @racket[src-namespace] 的 @tech{module registry}
中已实例化 module 的主体，且在 @racket[src-namespace] 的 @tech{base phase} 中，
使 module 在 @racket[src-namespace] 的 @tech{base phase} 上可用于按需
@tech{visit}。返回的 namespace 与 @racket[src-namespace] 具有相同的
@tech{module registry}。修改结果 namespace 中的 binding 会改变需要
该 namespace 的 module 所看到的 binding。

Top-level @racket[require] 表达式中的 module path 是相对于 namespace
的 module 解析的。不允许新的 @racket[provide] 声明。

If the current code inspector does not control the invocation of the
module in @racket[src-namespace]'s @tech{module registry}, the
@exnraise[exn:fail:contract]; see also @secref["modprotect"].

如果 module 声明时 @racket[compile-enforce-module-constants] 参数为真，
则结果 namespace 中的 binding 不可修改，除非 module 声明本身通过
@racket[set!] 包含对该 binding 的赋值。

@history[#:changed "6.90.0.16" @elem{Added the @racket[src-namespace] optional argument.}]}


@defproc[(namespace-syntax-introduce [stx syntax?]
                                     [namespace namespace? (current-namespace)])
         syntax?]{

返回类似于 @racket[stx] 的 syntax object，但 @racket[namespace]
的 binding 被包含在 @tech{syntax object} 的 @tech{lexical information} 中
(参见 @secref["stxobj-model"])。额外的上下文会被 @tech{syntax object}
的 @tech{lexical information} 中任何现有的 @tech{top-level binding} 覆盖，
或被 @tech{lexical information} 中任何现有的或未来的 @tech{module binding} 覆盖。

@history[#:changed "6.90.0.16" @elem{Added the @racket[namespace] optional argument.}]}


@defproc[(module-provide-protected? [module-path-index (or/c symbol? module-path-index?)]
                                    [sym symbol?])
         boolean?]{

如果 @racket[module-path-index] 的 module 声明定义了 @racket[sym]
并以 unprotected 方式导出，则返回 @racket[#f]，否则返回 @racket[#t]
(这可能意味着该 symbol 对应于未导出的定义、受保护的导出，
或根本未在 module 内定义的标识符)。

@racket[module-path-index] 参数可以是 symbol；参见
@secref["modpathidx"] 了解 module path index 的更多信息。

通常，@racket[module-provide-protected?] 的参数对应于
@racket[identifier-binding] 产生的 list 的前两个元素。}


@defproc[(variable-reference? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[#%variable-reference] 产生的
@tech{variable reference}，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(variable-reference-constant? [varref variable-reference?]) boolean?]{

如果 @racket[varref] 表示的 variable 将保留其当前值
(即 @racket[varref] 引用的是无法通过 @racket[set!] 或 @racket[define]
进一步修改的 variable)，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(variable-reference->empty-namespace [varref variable-reference?])
         namespace?]{

返回一个空 namespace，与 @racket[varref] 实例化的 namespace
共享 module 声明和实例，且 phase 与 @racket[varref] 相同。}


@defproc[(variable-reference->namespace [varref variable-reference?])
         namespace?]{

如果 @racket[varref] 引用 @tech{module-level variable}，
则结果是引用 variable 的 @tech{phase} 中 module 主体的 namespace；
结果与通过 @racket[module->namespace] 获得的 namespace 相同，
module 同样被 @tech{available}(如果尚未可用)。

如果 @racket[varref] 引用 @tech{top-level variable}，
则结果是定义引用 variable 的 namespace。}


@defproc[(variable-reference->resolved-module-path [varref variable-reference?])
         (or/c resolved-module-path? #f)]{

如果 @racket[varref] 引用 @tech{module-level variable}，
则结果是命名 module 的 @tech{resolved module path}。

如果 @racket[varref] 引用 @tech{top-level variable}，
则结果是 @racket[#f]。}


@defproc[(variable-reference->module-path-index [varref variable-reference?])
         (or/c module-path-index? #f)]{

如果 @racket[varref] 引用 @tech{module-level variable}，
则结果是命名 module 的 @tech{module path index}。

如果 @racket[varref] 引用 @tech{top-level variable}，
则结果是 @racket[#f]。}


@defproc[(variable-reference->module-source [varref variable-reference?])
         (or/c symbol? (and/c path? complete-path?) #f)]{

如果 @racket[varref] 引用 @tech{module-level variable}，
则结果是命名 module 源文件的 path 或 symbol(通常但不总是与
@tech{resolved module path} 中相同)。如果相关 module 是 @tech{submodule}，
则结果对应于外层 top-level module 的源文件。

如果 @racket[varref] 引用 @tech{top-level variable}，
则结果是 @racket[#f]。}


@defproc[(variable-reference->phase [varref variable-reference?])
         exact-nonnegative-integer?]{

返回 @racket[varref] 引用的 variable 的 @tech{phase}。}


@defproc[(variable-reference->module-base-phase [varref variable-reference?])
         exact-integer?]{

返回 @racket[varref] 引用的 variable 所在 module 被实例化时的
@tech{phase}，如果 @racket[varref] 的 variable 不在 module 内，则返回 @racket[0]。

对于有 module 的 variable，当 variable 绑定在 module 内的
@tech{phase level} @math{n} 时，结果比 @racket[(variable-reference->phase varref)]
的结果小 @math{n}。}


@defproc[(variable-reference->module-declaration-inspector [varref variable-reference?])
         inspector?]{

返回 @racket[varref] 所在 module 的声明 @tech{inspector}
(参见 @secref["modprotect"])，其中 @racket[varref] 必须引用由
@racket[(#%variable-reference)] 产生的匿名 module variable。}


@defproc[(variable-reference-from-unsafe? [varref variable-reference?]) boolean?]{

如果 variable reference 本身的 module(不一定是引用的 variable)
以 unsafe 模式编译，则返回 @racket[#t]，否则返回 @racket[#f]。
@tech{Unsafe mode} 可通过 @tech{linklet} 接口或通过
@racket[(#%declare #:unsafe)] 为 module 启用。

@racket[variable-reference-from-unsafe?] 过程旨在用作

@racketblock[
(variable-reference-from-unsafe? (#%variable-reference))
]

编译器可将其优化为字面量 @racket[#t] 或 @racket[#f]
(因为外层 module 正以 @tech{unsafe mode} 编译或不是)。

@history[#:added "6.12.0.4"]}
