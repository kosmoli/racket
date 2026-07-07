#lang scribble/doc
@(require scribble/manual scribble/eval racket/class "guide-utils.rkt")

@title[#:tag "reflection" #:style 'toc]{Reflection and Dynamic Evaluation}

Racket 是 @italic{dynamic} 语言。它提供了大量设施用于在运行时加载、
编译乃至构造新代码。

@local-table-of-contents[]

@; ----------------------------------------------------------------------

@section[#:tag "eval"]{@racket[eval]}

@margin-note{此示例在模块内或 DrRacket 的定义窗口中无法运行，
             但可以在交互窗口中运行，原因将在 @secref["namespaces"] 末尾解释。}

@racket[eval] 函数接受表达式或定义的表示("quoted" 形式或
@tech{syntax object})并对其进行求值：

@interaction[
(eval '(+ 1 2))
]

@racket[eval] 的强大之处在于可以动态构造表达式：

@interaction[
(define (eval-formula formula)
  (eval `(let ([x 2]
               [y 3])
           ,formula)))
(eval-formula '(+ x y))
(eval-formula '(+ (* x y) y))
]

当然，如果我们只是想对 @racket[x] 和 @racket[y] 给定值来求值表达式，
并不需要 @racket[eval]。更直接的方式是使用 first-class function：

@interaction[
(define (apply-formula formula-proc)
  (formula-proc 2 3))
(apply-formula (lambda (x y) (+ x y)))
(apply-formula (lambda (x y) (+ (* x y) y)))
]

然而，如果 @racket[(+ x y)] 和 @racket[(+ (* x y) y)] 等表达式
来自用户提供的文件，则 @racket[eval] 可能是合适的。类似地，@tech{REPL}
读取用户输入的表达式并使用 @racket[eval] 对其进行求值。

此外，@racket[eval] 常常直接或间接作用于整个 module。例如，
程序可以使用 @racket[dynamic-require] 按需加载一个 module，
它本质上是对 @racket[eval] 的包装，用于动态加载 module 代码。

@; ----------------------------------------

@subsection{Local Scopes}

@racket[eval] 函数无法看到其调用上下文中的局部绑定。例如，
在未 quoted 的 @racket[let] 形式内调用 @racket[eval] 来求值公式时，
@racket[x] 和 @racket[y] 的值并不可见：

@interaction[
(define (broken-eval-formula formula)
  (let ([x 2]
        [y 3])
    (eval formula)))
(broken-eval-formula '(+ x y))
]

@racket[eval] 无法看到 @racket[x] 和 @racket[y] 的绑定，
恰恰因为它是一个 function，而 Racket 是词法作用域语言。
假设 @racket[eval] 实现如下

@racketblock[
(define (eval x)
  (eval-expanded (macro-expand x)))
]

则在调用 @racket[eval-expanded] 时，@racket[x] 最近的绑定是待求值的表达式，
而不是 @racket[broken-eval-formula] 中的 @racket[let] 绑定。词法作用域防止了
这种混乱脆弱的行为，因此也阻止了 @racket[eval] 看到其调用上下文中的局部绑定。

你可能会想，即使 @racket[eval] 看不到 @racket[broken-eval-formula] 中的局部绑定，
实际上必然存在将 @racket[x] 映射到 @racket[2] 且将 @racket[y] 映射到 @racket[3]
的数据结构，并希望获取该数据结构。实际上，该数据结构并不存在；
编译器可以在编译时自由地将所有 @racket[x] 替换为 @racket[2]，
因此 @racket[x] 的局部绑定在运行时并不以任何具体形式存在。
即使变量无法通过 constant-folding 被消除，通常变量名也可以被消除，
保存局部值的数据结构并不像从名字到值的映射。

@; ----------------------------------------

@subsection[#:tag "namespaces"]{Namespaces}

由于 @racket[eval] 无法看到其调用上下文中的绑定，需要另一种机制来
确定动态可用的绑定。@deftech{namespace} 是一个 first-class value，
封装了可用于动态求值的绑定。

@margin-note{非正式地，@defterm{namespace} 有时可与 @defterm{environment}
 或 @defterm{scope} 互换使用。在 Racket 中，@defterm{namespace} 具有更具体的、
 上述的动态含义，不应与静态词法概念混淆。}

某些函数(如 @racket[eval])接受可选的 namespace 参数。更常见的是，
动态操作使用的 namespace 是由 @racket[current-namespace] @tech{parameter}
确定的 @deftech{current namespace}。

在 @tech{REPL} 中使用 @racket[eval] 时，current namespace 是 @tech{REPL}
用于求值表达式的 namespace。这就是为什么以下交互能通过 @racket[eval]
成功访问 @racket[x]：

@interaction[
(define x 3)
(eval 'x)
]

相反，尝试以下简单 module，直接在 DrRacket 中运行它，
或将文件作为命令行参数传给 @exec{racket}：

@racketmod[
racket

(eval '(cons 1 2))
]

这会失败，因为初始 current namespace 是空的。当你以交互模式运行
@exec{racket}(参见 @secref["start-interactive-mode"])时，初始 namespace
用 @racket[racket] module 的导出项初始化，但当你直接运行 module 时，
初始 namespace 从零开始。

一般来说，使用当前已安装的 namespace 来调用 @racket[eval] 不是好做法。
相反，应显式创建 namespace 并为 eval 调用安装它：

@racketmod[
racket

(define ns (make-base-namespace))
(eval '(cons 1 2) ns) (code:comment @#,t{works})
]

@racket[make-base-namespace] 函数创建一个 namespace，用 @racket[racket/base]
的导出项进行初始化。后面的 @secref["mk-namespace"] 一节提供了更多关于
创建和配置 namespace 的信息。

@; ----------------------------------------

@subsection{Namespaces and Modules}

与 @racket[let] 绑定一样，词法作用域意味着 @racket[eval] 无法自动看到
其调用的 @racket[module] 中的定义。但与 @racket[let] 绑定不同的是，
Racket 提供了将 module 反射到 @tech{namespace} 的方法。

@racket[module->namespace] 函数接受 quoted 的 @tech{module path}，
并产生一个 namespace，用于求值表达式和定义，就像它们出现在
@racket[module] 主体中一样：

@interaction[
(module m racket/base
  (define x 11))
(require 'm)
(define ns (module->namespace ''m))
(eval 'x ns)
]

@margin-note{@racket[''m] 中的双重 quoting 是因为 @racket['m] 是指向
交互式声明 module 的 module path，所以 @racket[''m] 是该 path 的 quoted 形式。}

@racket[module->namespace] 主要在 module 外部使用，此时 module 的全名已知。
然而在 @racket[module] 形式内部，module 的全名可能未知，
因为它可能取决于 module 源文件加载时的位置。

在 @racket[module] 内部，使用 @racket[define-namespace-anchor]
在 module 上声明反射钩子，并使用 @racket[namespace-anchor->namespace]
获取 module 的 namespace：

@racketmod[
racket

(define-namespace-anchor a)
(define ns (namespace-anchor->namespace a))

(define x 1)
(define y 2)

(eval '(cons x y) ns) (code:comment @#,t{produces @racketresult[(1 . 2)]})
]


@; ----------------------------------------------------------------------

@section[#:tag "mk-namespace"]{Manipulating Namespaces}

@tech{namespace} 封装了两部分信息：

@itemize[

 @item{标识符到 binding 的映射。例如，namespace 可能将标识符
       @racketidfont{lambda} 映射到 @racket[lambda] 形式。"空"namespace
       将每个标识符映射到未初始化的 top-level variable。}

 @item{module name 到 module 声明和实例的映射。
       (声明和实例之间的区别在 @secref["macro-module"] 中讨论。)}

]

第一种映射用于在 top-level 上下文中求值表达式，如
@racket[(eval '(lambda (x) (+ x 1)))]。第二种映射被用于，例如，
@racket[dynamic-require] 定位 module。调用 @racket[(eval '(require racket/base))]
通常使用两部分：标识符映射确定 @racketidfont{require} 的 binding；
如果它的含义是 @racket[require]，则使用 module 映射定位
@racketmodname[racket/base] module。

从核心 Racket 运行时系统的角度来看，所有求值都是反射式的。
执行从一个包含少数 primitive module 的初始 namespace 开始，
并通过按命令行指定的或 @tech{REPL} 中加载文件和 module 来进一步填充。
Top-level @racket[require] 和 @racket[define] 形式调整标识符映射，
而 module 声明(通常因 @racket[require] 形式而按需加载)调整 module 映射。

@; ----------------------------------------

@subsection{Creating and Installing Namespaces}

@racket[make-empty-namespace] 函数创建一个新的空 @tech{namespace}。
由于该 namespace 是真正的空，起初无法用于求值任何 top-level 表达式——
甚至不能求值 @racket[(require racket)]。特别是，

@racketblock[
(parameterize ([current-namespace (make-empty-namespace)])
  (namespace-require 'racket))
]

会失败，因为该 namespace 不包含构建 @racket[racket] 所依赖的 primitive module。

为使 namespace 可用，必须从现有 namespace 中 @deftech{attach} 一些 module。
Attach module 会通过从现有 namespace 的映射中转态复制条目(module 及其所有导入项)，
来调整 module name 到实例的映射。通常，attach 的不是 primitive module
(其名称和组织随时可能改变)，而是更高级别的 module，
如 @racketmodname[racket] 或 @racketmodname[racket/base]。

@racket[make-base-empty-namespace] 函数提供一个 namespace，它是空的，
但 attach 了 @racketmodname[racket/base]。结果 namespace 仍然"空"，
即 namespace 的标识符到 binding 部分没有映射；只有 module 映射已被填充。
然而，有了初始 module 映射后，可以加载更多 module。

用 @racket[make-base-empty-namespace] 创建的 namespace 适用于许多基本动态任务。
例如，假设 @racketmodfont{my-dsl} 库实现了一种领域特定语言，你希望执行
来自用户指定文件的命令。用 @racket[make-base-empty-namespace] 创建的
namespace 足以开始：

@racketblock[
(define (run-dsl file)
  (parameterize ([current-namespace (make-base-empty-namespace)])
    (namespace-require 'my-dsl)
    (load file)))
]

注意 @racket[current-namespace] 的 @racket[parameterize] 不影响标识符
(如 @racket[namespace-require])在 @racket[parameterize] 主体内的含义。
这些标识符从其封闭上下文(很可能是 module)获得含义。
只有相对于此代码是动态的表达式(如 @racket[load] 的文件内容)
才受 @racket[parameterize] 影响。

上述示例中另一个细微之处在于使用了 @racket[(namespace-require 'my-dsl)]
而不是 @racket[(eval '(require my-dsl))]。后者不会生效，因为 @racket[eval]
需要在 namespace 中获取 @racket[require] 的含义，而 namespace 的
标识符映射起初是空的。@racket[namespace-require] 函数则直接将给定 module
导入 current namespace。从 @racket[(namespace-require 'racket/base)] 开始
会引入 @racketidfont{require} 的绑定，使得后续 @racket[(eval
'(require my-dsl))] 可以工作。上述做法更好，不仅因为它更紧凑，
还因为它避免了引入不属于领域特定语言的绑定。

@; ----------------------------------------

@subsection{Sharing Data and Code Across Namespaces}

未 attach 到新 namespace 的 module 在求值需要时会被重新加载和实例化。
例如，@racketmodname[racket/base] 不包含 @racketmodname[racket/class]，
再次加载 @racketmodname[racket/class] 会创建不同的 class 数据类型：

@interaction[
(require racket/class)
(class? object%)
(class?
 (parameterize ([current-namespace (make-base-empty-namespace)])
   (namespace-require 'racket/class) (code:comment @#,t{loads again})
   (eval 'object%)))
]

当动态加载的代码需要与其上下文共享更多代码和数据时，使用
@racket[namespace-attach-module] 函数。@racket[namespace-attach-module]
的第一个参数是从中获取 module 实例的源 namespace；在某些情况下，
(current namespace 已知包含需要共享的 module：

@interaction[
(require racket/class)
(class?
 (let ([ns (make-base-empty-namespace)])
   (namespace-attach-module (current-namespace)
                            'racket/class
                            ns)
   (parameterize ([current-namespace ns])
     (namespace-require 'racket/class) (code:comment @#,t{uses attached})
     (eval 'object%))))
]

然而在 module 内部，结合使用 @racket[define-namespace-anchor] 和
@racket[namespace-anchor->empty-namespace] 提供了获取源 namespace 的更可靠方法：

@racketmod[
racket/base

(require racket/class)

(define-namespace-anchor a)

(define (load-plug-in file)
  (let ([ns (make-base-empty-namespace)])
    (namespace-attach-module (namespace-anchor->empty-namespace a)
                             'racket/class
                              ns)
    (parameterize ([current-namespace ns])
      (dynamic-require file 'plug-in%))))
]

@racket[namespace-attach-module] 绑定的锚将 module 的运行时
与加载 module 的 namespace(可能与 current namespace)连接起来。
在上述示例中，由于外层 module 需要 @racketmodname[racket/class]，
@racket[namespace-anchor->empty-namespace] 产生的 namespace 必然包含
@racketmodname[racket/class] 的实例。而且，该实例与导入 module 的实例相同，
因此 class 数据类型是共享的。

@; ----------------------------------------------------------------------

@section[#:tag "load"]{Scripting Evaluation and Using @racket[load]}

历史上，Lisp 实现并不提供 module 系统。相反，大型程序本质上是通过脚本化
@tech{REPL} 来按特定顺序求值程序片段构建的。虽然 @tech{REPL} 脚本化
被发现是组织程序和库的糟糕方式，但它有时仍然是有用的能力。

@margin-note{通过 @racket[load] 描述程序与 macro 定义的语言扩展
交互尤其糟糕 @cite["Flatt02"]。}

@racket[load] 函数通过从文件中逐个 @racket[read] S-expression
并传给 @racket[eval] 来运行 @tech{REPL} 脚本。如果文件 @filepath{place.rkts} 包含

@racketblock[
(define city "Salt Lake City")
(define state "Utah")
(printf "~a, ~a\n" city state)
]

则可以在 @tech{REPL} 中加载：

@interaction[
(eval:alts (load "place.rkts") (begin (define city "Salt Lake City")
                                     (printf "~a, Utah\n" city)))
city
]

然而，由于 @racket[load] 使用 @racket[eval]，类似下面的 module
通常不会生效——原因与 @secref["namespaces"] 中描述的相同：

@racketmod[
racket

(define there "Utopia")

(load "here.rkts")
]

用于求值 @filepath{here.rkts} 内容的 current namespace 很可能是空的；
无论如何，无法从 @filepath{here.rkts} 获取 @racket[there]。此外，
@filepath{here.rkts} 中的任何定义不会在 module 内部可见以供使用；
毕竟 @racket[load] 是动态发生的，而 module 内对标识符的引用是词法解析的，
因此是静态的。

与 @racket[eval] 不同，@racket[load] 不接受 namespace 参数。
要为 @racket[load] 提供 namespace，设置 @racket[current-namespace] @tech{parameter}。
以下示例使用 @racketmodname[racket/base] module 的绑定求值
@filepath{here.rkts} 中的表达式：

@racketmod[
racket

(parameterize ([current-namespace (make-base-namespace)])
  (load "here.rkts"))
]

你甚至可以使用 @racket[namespace-anchor->namespace]
使外层 module 的绑定可访问以供动态求值。在以下示例中，
当 @filepath{here.rkts} 被 @racket[load] 时，它可以引用 @racket[there]
以及 @racketmodname[racket] 的绑定：

@racketmod[
racket

(define there "Utopia")

(define-namespace-anchor a)
(parameterize ([current-namespace (namespace-anchor->namespace a)])
  (load "here.rkts"))
]

不过，如果 @filepath{here.rkts} 定义了任何标识符，
外层 module 无法直接(即静态地)引用这些定义。

@racketmodname[racket/load] module 语言不同于 @racketmodname[racket]
或 @racketmodname[racket/base]。使用 @racketmodname[racket/load] 的 module
将其所有内容视为动态的，将 module 主体中的每个形式传给 @racket[eval]
(使用以 @racketmodname[racket] 初始化的 namespace)。因此，
module 主体中使用 @racket[eval] 和 @racket[load] 的地方
看到与直接主体形式相同的动态 namespace。例如，如果 @filepath{here.rkts} 包含

@racketblock[
(define here "Morporkia")
(define (go!) (set! here there))
]

则运行

@racketmod[
racket/load

(define there "Utopia")

(load "here.rkts")

(go!)
(printf "~a\n" here)
]

prints ``Utopia''.

使用 @racketmodname[racket/load] 的缺点包括错误检查减少、
工具支持不足和性能降低。例如，对于如下程序

@racketmod[
racket/load

(define good 5)
(printf "running\n")
good
bad
]

DrRacket 的 @onscreen{Check Syntax} 工具无法判断第二个
@racket[good] 是指向第一个的引用，而对 @racket[bad] 的未绑定引用
仅在运行时被报告，而非在语法层面被拒绝。

@;------------------------------------------------------------------------
@section[#:tag "code-inspectors+protect"]{Code Inspectors for Trusted and Untrusted Code}

@deftech{Code inspector} 提供机制来判断哪些 module 被信任以使用
@racket[module->namespace] 等函数或 @racket[ffi/unsafe] 等不安全 module。
当 module 被声明时，@racket[current-code-inspector] 的值与 module 声明关联。
当 module 被实例化(即声明主体实际执行时)，会创建一个 sub-inspector
来保护 module 的导出项。访问 module 的 @tech{protected} 导出项需要比 module
的 instantiation inspector 更强的 code inspector(即在 inspector 层级中更高)；
注意 module 的 declaration inspector 始终强于其 instantiation inspector，
因此以相同 code inspector 声明的 module 可以互相访问导出项。

为区分可信和不可信代码，先加载可信代码，然后将
@racket[current-code-inspector] 设置为 @racket[(make-inspector
(current-code-inspector))] 的结果，安装更弱的 inspector，
最后使用该更弱的 inspector 加载不可信代码。运行任何不可信代码时，
较弱的 inspector 应保持在位。如果必要，可信代码可以在可信代码的
动态期间临时恢复原始 inspector(只要它不回调到不可信代码)。

Module 内的 syntax-object 常量(如模板中的字面标识符)保留其源 module 的 inspector。
如此，来自可信 module 的 macro 可用于不可信 module 内，
且 macro 展开中的 @tech{protected} 标识符仍然有效，即使它们最终出现在不可信 module 中。
为防止通过从展开代码提取标识符来滥用标识符，@racket[local-expand] 等函数
是 @tech{protected} 的，而 @racket[expand] 等函数在未获得足够强大的 inspector
时会返回 @tech{tainted} syntax。

不幸的是，来自 @filepath{.zo} 文件的编译代码本质上不可信，
因为它可能通过除 @racket[compile] 之外的其他方式合成。
当编译代码写入 @filepath{.zo} 文件时，编译代码内的 syntax-object 常量
失去其 inspector。加载代码时，编译代码中的所有 syntax-object 常量
会获取外层 module 的 declaration-time inspector。
