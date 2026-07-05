#lang scribble/doc
@(require "utils.rkt" (for-label setup/dirs) (for-syntax setup/dirs))

@title{Loading Foreign Libraries}

FFI 通常用于从 @as-index{shared objects}（又称 @defterm{@as-index{shared
libraries}} 或 @defterm{@as-index{dynamically loaded libraries}}）中提取函数和其他对象。@racket[ffi-lib] 函数装载 shared object。

@defproc[(ffi-lib? [v any/c]) boolean?]{

若 @racket[v] 是 @deftech{foreign-library value}，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(ffi-lib [path (or/c path-string? #f)]
                  [version (or/c string? (listof (or/c string? #f)) #f) #f]
		  [#:get-lib-dirs get-lib-dirs (-> (listof path?)) get-lib-search-dirs]
		  [#:fail fail (or/c #f (-> any)) #f]
                  [#:global? global? any/c (eq? 'global (system-type 'so-mode))]
                  [#:custodian custodian (or/c 'place custodian? #f) #f])
         any]{

返回 @tech{foreign-library value} 或 @racket[fail] 的结果。通常，

@itemlist[

 @item{@racket[path] 是不带版本或后缀的路径（即不带 @filepath{.dll}、@filepath{.so} 或 @filepath{.dylib}）；且}

 @item{@racket[version] 是按顺序尝试的版本列表，最后一个元素为 @racket[#f]（即无版本）；例如，@racket['("2" #f)] 表示带版本 2 的回退到无版本库。

      当 @racket[(system-type 'so-suffix)] 报告的库后缀为 @filepath{.dylib} 时，@racket[path] 在 @filepath{.} 之后和 @filepath{.dylib} 后缀之前添加版本号。当库后缀为 @filepath{.dll} 时，@racket[path] 在 @filepath{-} 之后和 @filepath{.dll} 后缀之前添加版本号。对于任何其他后缀，版本号在后缀后添加 @filepath{.}。

]

}

字符串或 @racket[#f] 类型的 @racket[version] 等价于只包含该字符串或 @racket[#f] 的列表，空字符串（单独或列表中）等价于 @racket[#f]。

警告依赖无版本的库名。某些平台上无版本库名仅由开发包提供。同时，其他平台可能需要无版本回退。通常 @racket[version] 最好使用版本字符串列表后跟 @racket[#f]。

假设 @racket[path] 不是 @racket[#f]，@racket[ffi-lib] 返回的搜索过程如下：

@itemlist[

 @item{若 @racket[path] 不是绝对路径，查看 @racket[get-lib-dirs] 报告的每个目录；默认列表为 @racket[(get-lib-search-dirs)] 的结果。在每个目录中，尝试 @racket[path] 与 @racket[version] 中的第一个版本组合，如果 @racket[path] 不以该后缀结尾则添加适当后缀，然后尝试第二个版本，以此类推。（若 @racket[version] 为空，此步骤不尝试任何路径。）}

 @item{再次尝试相同的文件名，但不将路径转换为绝对路径，让操作系统使用自己的搜索路径。（若 @racket[version] 为空，此步骤不尝试任何路径。）}

 @item{尝试不添加任何版本或后缀的 @racket[path]，也不转换为绝对路径。}

 @item{再次尝试版本调整后的文件名，但相对于当前目录。（若 @racket[version] 为空，此步骤不尝试任何路径。）}

 @item{尝试不添加任何版本或后缀但转换为当前目录绝对路径的 @racket[path]。}

]

若没有路径成功且 @racket[fail] 是函数，则以尾调用方式调用 @racket[fail]。若 @racket[fail] 为 @racket[#f]，则报告错误，尝试上面第二个项目符号的第一个路径（或若 @racket[version] 为空列表，则尝试第三个项目符号的第一个路径）。库文件可能由于某种原因加载失败；最终的错误消息将遗憾地命名来自第二或第三个项目符号的回退路径，因为某些操作系统无法提供确定给定库路径失败的方法。

若 @racket[path] 为 @racket[#f]，则得到的 foreign-library value 表示当前进程中加载的所有库，包括之前已通过 @racket[ffi-lib] 打开的库。特别是对用于访问运行时段系统导出的 C 级功能的 @racket[#f]（见 @|InsideRacket|）。当 @racket[path] 为 @racket[#f] 时，@racket[version] 参数被忽略。

若 @racket[path] 不为 @racket[#f]，@racket[global?] 为真，且操作系统支持以 "global" 模式打开库（以将库的符号用于之后加载的库的引用解析），则使用全局模式打开库。否则以 "local" 模式打开库，此模式不将库的符号用于未来的解析。本地与全局的选择不影响库的符号是否通过 @racket[(ffi-lib #f)] 可用。

若 @racket[custodian] 为 @racket['place] 或一个 custodian，则库在 custodian 关闭时被卸载——即给定的 custodian 或如果 @racket[custodian] 为 @racket['place] 则为主要 place custodian。库被卸载时，对库的所有引用将失效。为 @racket[custodian] 提供 @racket['place] 与通过 @racketmodname[ffi/unsafe/alloc] 进行终结化一致，但例如在 DrRacket 中点击 @onscreen{Run} 按钮时不会卸载库。为 @racket[custodian] 提供 @racket[(current-custodian)] 倾向于立即卸载库，但需要更小心以确保在库被卸载后不访问库引用。

若 @racket[custodian] 为 @racket[#f]，则加载的库关联到 Racket（或 DrRacket）全程进程的生命周期。再次通过 @racket[ffi-lib] 加载不会强制重新加载对应的库。

当 @racket[ffi-lib] 返回对当前 place 中先前加载的库的引用时，它增加已加载库的引用计数而不是重新加载它。卸载库引用递减引用计数，并且仅在引用计数为零时请求操作系统级卸载。

@racket[ffi-lib] 过程在主题 @racket['ffi-lib] 上记录日志（见 @secref["logging" #:doc '(lib
"scribblings/reference/reference.scrbl")]）。特别地，失败时它根据上述规则记录尝试的路径，但不能报告由于操作系统库搜索路径而尝试的路径。

@history[#:changed "6.1.0.5" @elem{Changed the way a version number is
                                   added with a @filepath{.dll} suffix
                                   to place it before the suffix,
                                   instead of after.}
         #:changed "7.3.0.3" @elem{Added logging.}
         #:changed "7.4.0.7" @elem{Added the @racket[#:custodian] argument.}]}

@defproc[(get-ffi-obj [objname (or/c string? bytes? symbol?)]
                      [lib (or/c ffi-lib? path-string? #f)]
                      [type ctype?]
                      [failure-thunk (or/c (-> any) #f) #f]) 
         any]{

在 @racket[lib] 库中查找 @racket[objname]。若 @racket[lib] 不是 @tech{foreign-library value}，则通过调用 @racket[ffi-lib] 将其转换为 one。若在 @racket[lib] 中找到 @racket[objname]，则使用给定的 @racket[type] 将其转换为 Racket。类型在 @secref["types"] 中描述；特别地，@racket[get-ffi-obj] 最常与 @racket[_fun] 创建的功能类型一起使用。

需注意 @racket[get-ffi-obj] 是不安全的过程；详见 @secref["intro"]。

若名称未提供，且提供了 @racket[failure-thunk]，则用于产生返回值。例如，可以提供失败 thunk 以在名称未找到时报告特定错误：

@racketblock[
(define foo
  (get-ffi-obj "foo" foolib (_fun _int -> _int)
    (lambda ()
      (error 'foolib
             "installed foolib does not provide \"foo\""))))
]

默认值（或当 @racket[failure-thunk] 作为 @racket[#f] 提供时）是抛出异常。}


@defproc[(set-ffi-obj! [objname (or/c string? bytes? symbol?)]
                       [lib (or/c ffi-lib? path-string? #f)]
                       [type ctype?]
                       [new any/c])
         void?]{

类似 @racket[get-ffi-obj] 在 @racket[lib] 中查找 @racket[objname]，但随后将给定的 @racket[new] 值存入库中，将其转换为 C 值。这可用于设置库接口的一部分，包括 Racket 回调的库定制变量。}


@defproc[(make-c-parameter [objname (or/c string? bytes? symbol?)]
                           [lib (or/c ffi-lib? path-string? #f)]
                           [type ctype?]
                           [failure-thunk (or/c (-> any) #f) #f])
         (case-> (-> any)
                 (any/c . -> . void?))]{

返回一个参数类过程可以引用指定的 foreign value 或设置它。参数处理与 @racket[get-ffi-obj] 相同。

若 Racket 代码和库代码通过库值交互，则参数类过程很有用。虽然 @racket[make-c-parameter] 可用于任何类型，但不建议将其用于 foreign functions，因为在实际调用之前每次引用都会构造底层接口。

@history[#:changed "8.4.0.5" @elem{Added @racket[failure-thunk] argument.}]}


@defform[(define-c id lib-expr type-expr)]{

将 @racket[id] 定义为类似 Racket 绑定，但实际上 @racket[id] 被重定向到由 @racket[make-c-parameter] 创建的参数类过程。@racket[id] 同时用于 Racket 绑定和 foreign 名称。}

@defproc[(ffi-obj-ref [objname (or/c string? bytes? symbol?)]
                      [lib (or/c ffi-lib? path-string? #f)]
                      [failure-thunk (or/c (-> any) #f) #f]) 
         any]{

返回指定 foreign 名称的指针，若名称未找到则调用 @racket[failure-thunk]；若 @racket[failure-thunk] 为 @racket[#f]，则抛出异常。

通常应使用 @racket[get-ffi-obj]，而非此过程。}
