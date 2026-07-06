#lang scribble/doc
@(require "mz.rkt" scribble/example)

@title[#:tag "pathutils" #:style 'toc]{路径}

当 Racket 过程接受文件系统路径作为参数时，该路径可以
以字符串或 @deftech{path} 数据类型的实例形式提供。如果提供的是字符串，则会通过
@racket[string->path] 将其转换为路径。请注意，某些路径可能无法
表示为字符串；更多信息请参见 @secref["unixpathrep"] 和
@secref["windowspathrep"]。
生成文件系统路径的 Racket 过程始终生成一个 @tech{path} 值。

默认情况下，路径是为当前平台创建和操作的，
但仅操作路径（而不使用文件系统）的过程可以使用其他
支持平台的约定来操作路径。@racket[bytes->path] 过程接受一个
可选参数，用于指定路径的平台，可以是
@racket['unix] 或 @racket['windows]。对于其他函数，例如
@racket[build-path] 或 @racket[simplify-path]，其行为
取决于所提供的路径类型。除非另有
说明，需要路径的过程仅接受当前平台的路径。

当两个 @tech{path} 值使用相同的约定类型且其字节字符串表示
@racket[equal?] 时，它们 @racket[equal?]。路径字符串（或字节字符串）不能为空，
且不能包含 nul 字符或字节。当空字符串或包含 nul 的
字符串作为路径提供给除
@racket[absolute-path?]、@racket[relative-path?] 或
@racket[complete-path?] 之外的任何过程时，会 @exnraise[exn:fail:contract]。

大多数接受路径的 Racket 原语在使用路径之前会先 @deftech{cleanse}（清理）
该路径。构建路径或仅检查路径形式的过程不会清理路径，
@racket[cleanse-path]、@racket[expand-user-path] 和
@racket[simplify-path] 除外。有关路径清理和
其他平台特定细节的更多信息，请参见 @secref["unixpaths"] 和
@secref["windowspaths"]。

@;------------------------------------------------------------------------
@section{路径操作}

@defproc[(path? [v any/c]) boolean?]{

如果 @racket[v] 是当前平台的路径值
（不是字符串，也不是其他平台的路径），则返回 @racket[#t]，
否则返回 @racket[#f]。}

@defproc[(path-string? [v any/c]) boolean?]{
 如果 @racket[v] 是 @deftech{path 或字符串}（path or string）：
  即当前平台的路径或不含 nul 字符的非空字符串，则返回 @racket[#t]。
 否则返回 @racket[#f]。
}

@defproc[(path-for-some-system? [v any/c]) boolean?]{

如果 @racket[v] 是某个平台的路径值
（不是字符串），则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(string->path [str string?]) path?]{

生成一个路径，其字节字符串编码在 @|AllUnix| 上为
@racket[(string->bytes/locale str (char->integer #\?))]，
在 Windows 上为 @racket[(string->bytes/utf-8 str)]。

请注意，当前语言环境可能无法编码每个字符串，在这种情况下
@racket[string->path] 可能为不同的 @racket[str] 生成相同的路径。
另请参见 @racket[string->path-element]，当字符串表示单个
@tech{path element} 时，应使用它来代替 @racket[string->path]。
有关字符串和字节字符串如何编码路径的信息，请参见 @secref["unixpathrep"] 和
@secref["windowspathrep"]。

另请参见 @racket[string->some-system-path]，以及
@secref["unixpathrep"] 和 @secref["windowspathrep"] 了解
字符串如何编码路径的信息。

@history[#:changed "6.1.1.1" @elem{Windows 转换改为始终使用 UTF-8。}]}


@defproc[(bytes->path [bstr bytes?]
                      [type (or/c 'unix 'windows) (system-path-convention-type)])
         path?]{

生成一个（某个平台的）路径，其字节字符串编码为
@racket[bstr]，其中 @racket[bstr] 不能包含 nul 字节。
可选的 @racket[type] 指定路径使用的约定。

对于从字面量转换相对 @tech{path elements}，请改用
@racket[bytes->path-element]，它为各个元素应用合适的编码。

有关字节字符串如何编码路径的信息，请参见
@secref["unixpathrep"] 和 @secref["windowspathrep"]。}


@defproc[(path->string [path path?]) string?]{

生成一个表示 @racket[path] 的字符串，在 @|AllUnix| 上
使用当前语言环境解码 @racket[path] 的字节字符串编码，
在 Windows 上使用 UTF-8。在前一种情况下，
编码失败时结果字符串中使用 @litchar{?}，如果
编码结果为空字符串，则结果为
@racket["?"]。

结果字符串适用于向用户显示、
字符串排序比较等，但不适用于
通过 @racket[string->path] 重新创建路径（可能经过修改），
因为解码和重新编码路径的字节字符串可能会丢失
信息。

此外，对于基于单个 @tech{path elements}
（如无路径文件名）的显示和排序，请使用 @racket[path-element->string]，
以避免用于表示某些相对路径的特殊编码。
有关 Windows 路径转换的具体信息，请参见 @secref["windowspaths"]。

另请参见 @racket[some-system-path->string]。

@history[#:changed "6.1.1.1" @elem{Windows 转换改为始终使用 UTF-8。}]}


@defproc[(path->bytes [path path-for-some-system?]) bytes?]{

生成 @racket[path] 的字节字符串表示。此转换中不会丢失
任何信息，因此 @racket[(bytes->path (path->bytes
path) (path-convention-type path))] 始终生成一个
与 @racket[path] @racket[equal?] 的路径。@racket[path] 参数可以是
任何平台的路径。

与字节值的相互转换对于编组和解组路径很有用，
但操作路径的字节形式通常是一个错误。
特别是，字节字符串可能以 Windows 路径的
@litchar{\\?\REL} 编码前缀开头。应使用
@racket[split-path] 和
@racket[path-element->bytes] 来操作单个 @tech{path elements}，而不是 @racket[path->bytes]。

有关字节字符串如何编码路径的信息，请参见
@secref["unixpathrep"] 和 @secref["windowspathrep"]。}


@defproc[(string->path-element [str string?]
                               [false-on-non-element? any/c #f])
         (or/c (and/c path? path-element?) #f)]{

类似于 @racket[string->path]，但 @racket[str] 对应于
路径中的单个相对元素，并在转换为路径时进行必要的编码。
有关路径转换的更多信息，请参见 @secref["unixpaths"] 和
@secref["windowspaths"]。

如果 @racket[str] 不对应任何 @tech{path element}
（例如，它是绝对路径，或可以分割），或者它
对应 @|AllUnix| 上的上级目录或同级目录指示符，
则返回 @racket[#f] 或 @exnraise[exn:fail:contract]。
仅当 @racket[false-on-non-element?] 为真时
才返回 @racket[#f]。

与 @racket[path->string] 一样，在特定语言环境的路径转换中，
@racket[str] 的信息可能会丢失。

@history[#:changed "8.1.0.6" @elem{添加了 @racket[false-on-non-element?] 参数。}]}


@defproc[(bytes->path-element [bstr bytes?]
                              [type (or/c 'unix 'windows) (system-path-convention-type)]
                              [false-on-non-element? any/c #f])
         (or/c path-element? #f)]{

类似于 @racket[bytes->path]，但 @racket[bstr] 对应于
路径中的单个相对元素。在转换、
对 @racket[bstr] 的限制以及对 @racket[false-on-non-element?] 的处理方面，
@racket[bytes->path-element] 与 @racket[string->path-element] 类似。

当需要对 @tech{path elements} 进行 ASCII 级别操作时，
@racket[bytes->path-element] 过程通常是根据另一个路径
（该路径通过 @racket[split-path] 和
@racket[path-element->bytes] 解构）重建路径的最佳选择。

@history[#:changed "8.1.0.6" @elem{添加了 @racket[false-on-non-element?] 参数。}]}


@defproc[(path-element->string [path path-element?]) string?]{

类似于 @racket[path->string]，但会移除尾部的路径分隔符
（如同 @racket[split-path]）。在 Windows 上，任何
@litchar{\\?\REL} 编码前缀也会被移除；更多信息请参见
@secref["windowspaths"]。

@racket[path] 参数必须满足：对 @racket[path] 应用 @racket[split-path]
会返回 @racket['relative] 作为第一个结果，
路径作为第二个结果，否则
@exnraise[exn:fail:contract]。

@racket[path-element->string] 过程通常是向用户呈现
无路径文件或目录名称的最佳选择。}


@defproc[(path-element->bytes [path path-element?]) bytes?]{

类似于 @racket[path->bytes]，但会移除任何编码前缀等，
如同 @racket[path-element->string]。

对于任何合理的语言环境，@racket[path] 打印形式中的连续 ASCII 字符
会映射到与每个字符的码点值匹配的连续字节值，
且前导或尾部的 ASCII 字符会分别映射到前导或尾部的字节。
@racket[path] 参数可以是任何平台的路径。

@racket[path-element->bytes] 过程通常是与 @racket[split-path] 结合
提取路径内容以在 ASCII 级别操作（然后
使用 @racket[bytes->path-element] 和
@racket[build-path] 重新组装结果）的正确选择。}


@defproc[(path<? [a-path path?] [b-path path?] ...) boolean?]{

如果参数已排序，则返回 @racket[#t]，其中每对路径的
比较等同于使用
@racket[path->bytes] 和 @racket[bytes<?]。

@history/arity[]}


@defproc[(path-convention-type [path path-for-some-system?])
         (or/c 'unix 'windows)]{

接受路径值（不是字符串）并返回其约定类型。}


@defproc[(system-path-convention-type)
         (or/c 'unix 'windows)]{

返回当前平台的路径约定类型：
@|AllUnix| 为 @indexed-racket['unix]，Windows 为
@indexed-racket['windows]。}


@defproc[(build-path [base (or/c path-string? path-for-some-system? 'up 'same)]
                     [sub (or/c (and/c (or/c path-string? path-for-some-system?)
                                       (not/c complete-path?))
                                (or/c 'up 'same))] ...)
         path-for-some-system?]{

给定一个基础路径和任意数量的子路径扩展来创建路径。
如果 @racket[base] 是绝对路径，则结果为
绝对路径，否则结果为相对路径。

@racket[base] 和每个 @racket[sub] 必须是相对
路径、符号 @indexed-racket['up]（表示相对父目录）
或符号 @indexed-racket['same]（表示
相对当前目录）。对于 Windows 路径，如果 @racket[base] 是
驱动器规范（带或不带尾部斜杠），第一个
@racket[sub] 可以是绝对（无驱动器）路径。对于所有平台，
最后一个 @racket[sub] 可以是文件名。

@racket[base] 和 @racket[sub] 参数可以是
任何平台的路径。结果路径的平台从
@racket[base] 和 @racket[sub] 参数推断，其中字符串参数表示
当前平台的路径。如果不同参数针对
不同平台，则 @exnraise[exn:fail:contract]。如果没有参数
指定平台（即所有参数都是 @racket['up] 或 @racket['same]），
生成的路径为当前平台。

每个 @racket[sub] 和 @racket[base] 可以选择以目录
分隔符结尾。如果最后一个 @racket[sub] 以分隔符结尾，它
会包含在结果路径中。

如果 @racket[base] 或 @racket[sub] 是非法的路径字符串（因为
为空或包含 nul 字符），则
@exnraise[exn:fail:contract]。

@racket[build-path] 过程构建路径时 @italic{不会}
检查路径的有效性或访问文件系统。

有关路径构造的更多信息，请参见 @secref["unixpaths"] 和
@secref["windowspaths"]。

以下示例假设当前目录对于 Unix 示例为
@filepath{/home/joeuser}，对于 Windows 示例为 @filepath{C:\Joe's Files}。

@racketblock[
(define p1 (build-path (current-directory) "src" "racket"))
 (code:comment @#,t{Unix: @racket[p1] is @racket["/home/joeuser/src/racket"]})
 (code:comment @#,t{Windows: @racket[p1] is @racket["C:\\Joe's Files\\src\\racket"]})
(define p2 (build-path 'up 'up "docs" "Racket"))
 (code:comment @#,t{Unix: @racket[p2] is @racket["../../docs/Racket"]})
 (code:comment @#,t{Windows: @racket[p2] is @racket["..\\..\\docs\\Racket"]})
(build-path p2 p1) 
 (code:comment @#,t{Unix and Windows: raises @racket[exn:fail:contract]; @racket[p1] is absolute})
(build-path p1 p2) 
 (code:comment @#,t{Unix: is @racket["/home/joeuser/src/racket/../../docs/Racket"]})
 (code:comment @#,t{Windows: is @racket["C:\\Joe's Files\\src\\racket\\..\\..\\docs\\Racket"]})
]}


@defproc[(build-path/convention-type
                     [type (or/c 'unix 'windows)]
                     [base (or/c path-string? path-for-some-system? 'up 'same)]
                     [sub (or/c (and/c (or/c path-string? path-for-some-system?)
                                       (not/c complete-path?))
                                (or/c 'up 'same))] ...)
         path-for-some-system?]{

类似于 @racket[build-path]，但显式指定了路径约定类型。

请注意，与 @racket[build-path] 一样，@racket[base] 或 @racket[sub] 的任何字符串参数
在与其他参数组合之前会被隐式转换为当前平台的路径。因此，
你不能使用此函数从字符串为非当前平台构建路径；
在这种情况下，@racket[type] 与字符串推断的约定类型不匹配，
会 @exnraise[exn:fail:contract]。
（要为其他平台创建路径，请参见 @racket[bytes->path]。）

@racket[build-path/convention-type] 相对于 @racket[build-path] 的
用途仅限于子路径包含 @racket['same] 或 @racket['up] 元素的情况。}


@defproc[(absolute-path? [path (or/c path? string? path-for-some-system?)]) boolean?]{

如果 @racket[path] 是绝对路径，则返回 @racket[#t]，否则返回 @racket[#f]。
@racket[path] 参数可以是任何平台的路径。
如果 @racket[path] 不是合法的路径字符串（例如，
包含 nul 字符），则返回 @racket[#f]。此过程
不访问文件系统。}


@defproc[(relative-path? [path (or/c path? string? path-for-some-system?)]) boolean?]{

如果 @racket[path] 是相对路径，则返回 @racket[#t]，否则返回 @racket[#f]。
@racket[path] 参数可以是任何平台的路径。
如果 @racket[path] 不是合法的路径字符串（例如，
包含 nul 字符），则返回 @racket[#f]。此过程
不访问文件系统。}


@defproc[(complete-path? [path (or/c path? string? path-for-some-system?)]) boolean?]{

如果 @racket[path] 是一个 @deftech{complete}（完整确定）的路径
（@italic{不}相对于目录或驱动器），则返回 @racket[#t]，
否则返回 @racket[#f]。@racket[path] 参数可以是任何平台的路径。
请注意，对于 Windows 路径，绝对路径可以省略
驱动器规范，在这种情况下，路径既不是相对的也不是
完整的。如果 @racket[path] 不是合法的路径字符串（例如，
包含 nul 字符），则返回 @racket[#f]。

此过程不访问文件系统。}


@defproc[(path->complete-path [path (or/c path-string? path-for-some-system?)]
                              [base (or/c path-string? path-for-some-system?) (current-directory)])
         path-for-some-system?]{

将 @racket[path] 作为完整路径返回。如果 @racket[path] 已经是
完整路径，则直接返回。否则，
相对于完整路径 @racket[base] 解析
@racket[path]。如果 @racket[base] 不是完整路径，则
@exnraise[exn:fail:contract]。

@racket[path] 和 @racket[base] 参数可以是任何平台的路径；
如果它们针对不同平台，则
@exnraise[exn:fail:contract]。

此过程不访问文件系统。}


@defproc[(path->directory-path [path (or/c path-string? path-for-some-system?)])
         path-for-some-system?]{

如果 @racket[path] 在语法上引用一个目录且以分隔符结尾，
则返回 @racket[path]，否则返回一个扩展后的
@racket[path] 版本，该版本指定目录并以
分隔符结尾。例如，在 @|AllUnix| 上，路径 @filepath{x/y/}
在语法上引用目录并以分隔符结尾，但
@filepath{x/y} 会被扩展为 @filepath{x/y/}，@filepath{x/..} 会被
扩展为 @filepath{x/../}。@racket[path] 参数可以是任何平台的路径，
结果将为同一平台。

此过程不访问文件系统。}


@defproc[(resolve-path [path path-string?]) path?]{

@tech{Cleanse}（清理）@racket[path] 并返回引用
与 @racket[path] 相同文件或目录的路径。如果
@racket[path] 是指向另一个路径的软链接，则返回引用的路径
（这可能是相对于拥有 @racket[path] 的目录的相对路径），
否则返回 @racket[path]（清理后）。

在 Windows 上，链接的路径应该在语法上简化，
使得上级目录指示符移除前一个路径元素，
而不管前一个元素本身是否引用
链接。对于相对路径链接，路径应该被特殊解析；
更多信息请参见 @secref["windowspaths"]。

@history[#:changed "6.0.1.12" @elem{添加了对 Windows 上链接的支持。}]}


@defproc[(cleanse-path [path (or/c path-string? path-for-some-system?)])
         path-for-some-system?]{

@techlink{Cleanse}（清理）@racket[path]（如本章开头所述），
不查询文件系统。

@examples[#:eval (make-base-eval '(require racket/path))
  (let ([p (string->some-system-path "tiny//dancer" 'unix)])
    (cleanse-path p))
]}


@defproc[(expand-user-path [path path-string?]) path?]{

@techlink{Cleanse}（清理）@racket[path]。此外，在 @|AllUnix| 上，
前导的 @litchar{~} 被视为用户的主目录并展开；
用户名跟在 @litchar{~} 之后（在 @litchar{/} 或路径末尾之前），
单独的 @litchar{~} 表示当前用户的主目录。}


@defproc[(simplify-path [path (or/c path-string? path-for-some-system?)]
                        [use-filesystem? boolean? #t])
         path-for-some-system?]{

消除 @racket[path] 中的冗余路径分隔符（除了单个尾部
分隔符）、上级目录 @litchar{..} 和同级目录 @litchar{.}
指示符，并在 Windows 路径中将 @litchar{/} 分隔符转换为
@litchar{\} 分隔符，使得结果
访问与 @racket[path] 相同的文件或目录（如果存在）。

通常，路径名会被尽可能规范化——如果 @racket[use-filesystem?] 为 @racket[#f]，
则不查询文件系统，且（在 Windows 上）不改变
路径中字母的大小写。如果 @racket[path] 在语法上引用目录，
结果以目录分隔符结尾。

当 @racket[path] 除了斜杠转反斜杠之外还需要简化，
且 @racket[use-filesystem?] 为真（默认值）时，
返回完整路径。如果 @racket[path] 是相对路径，
则相对于当前目录解析。
在 @|AllUnix| 上，上级目录指示符会被移除，同时考虑软链接（
使得结果路径引用与之前相同的目录）；
在 Windows 上，上级目录指示符通过删除
前一个 @tech{path element} 来移除。

当 @racket[use-filesystem?] 为 @racket[#f] 时，上级目录指示符
通过删除前一个 @tech{path element} 来移除，结果可以是
在路径开头保留上级目录指示符的相对路径；
当上级目录指示符引用根目录的父目录时，它们会被丢弃。
类似地，如果消除上级目录指示符后只剩下
同级目录指示符，结果可以与 @racket[(build-path 'same)] 相同
（但带有尾部分隔符）。

当 @racket[use-filesystem?] 为 @racket[#f] 时，
@racket[path] 参数可以是任何平台的路径，
结果路径为同一平台。

当 @racket[use-filesystem?] 为真时，
可能会访问文件系统，但源路径或简化后的路径可能是不存在的路径。
如果 @racket[path] 因链接循环而无法简化，
则 @exnraise[exn:fail:filesystem]（但成功简化的路径可能
仍然涉及链接循环，如果该循环没有阻碍
简化过程的话）。

有关简化路径的更多信息，请参见 @secref["unixpaths"] 和
@secref["windowspaths"]。

@examples[#:eval (make-base-eval '(require racket/path))
  (let ([p (string->some-system-path "tiny//in/my/head/../../../dancer" 'unix)])
    (simplify-path p #f))
]}
 

@defproc[(normal-case-path [path (or/c path-string? path-for-some-system?)])
         path-for-some-system?]{

返回带有"规范化"大小写字符的 @racket[path]。对于 @|AllUnix|
路径，此过程始终返回输入路径，因为
这些平台的文件系统可能区分大小写。对于 Windows
路径，如果 @racket[path] 不以 @litchar{\\?\} 开头，
结果字符串仅使用小写字母，基于当前
语言环境。此外，对于不以
@litchar{\\?\} 开头的 Windows 路径，所有 @litchar{/} 被转换为
@litchar{\}，尾部的空格和 @litchar{.} 被移除。

@racket[path] 参数可以是任何平台的路径，但请注意
路径的语言环境敏感解码和转换可能
在当前平台上与路径所属平台上不同。

此过程不访问文件系统。}


@defproc[(split-path [path (or/c path-string? path-for-some-system?)])
         (values (or/c path-for-some-system? 'relative #f)
                 (or/c path-for-some-system? 'up 'same)
                 boolean?)]{

将 @racket[path] 解构为更小的路径和直接的
目录或文件名。返回三个值：

@itemize[

 @item{@racket[base] 是以下之一：

  @itemize[
   @item{一个路径，}
   @item{如果 @racket[path] 是直接的相对目录或文件名，
    则为 @indexed-racket['relative]，或}
   @item{如果 @racket[path] 是根目录，则为 @racket[#f]。}
 ]}

 @item{@racket[name] 是以下之一：
  @itemize[
   @item{一个目录名路径，}
   @item{一个文件名，}
   @item{如果 @racket[path] 的最后部分指定前一个路径的
    父目录，则为 @racket['up]（例如 Unix 上的 @litchar{..}），或}
   @item{如果 @racket[path] 的最后部分指定与
     前一个路径相同的目录，则为 @racket['same]（例如 Unix 上的 @litchar{.}）。}
  ]}

 @item{如果 @racket[path] 显式指定目录（例如带有尾部分隔符），
则 @racket[must-be-dir?] 为 @racket[#t]，否则为 @racket[#f]。
请注意，@racket[must-be-dir?] 不指定
 @racket[name] 是否实际上是目录，而是 @racket[path]
 在语法上是否指定了目录。}

 ]

与 @racket[path] 相比，结果 @racket[base] 和 @racket[name] 中的
冗余分隔符（如果有）会被移除。如果 @racket[base] 为
@racket[#f]，则 @racket[name] 不能是 @racket['up] 或
@racket['same]。@racket[path] 参数可以是任何平台的路径，
结果路径为同一平台。

此过程不访问文件系统。

有关分割路径的更多信息，请参见 @secref["unixpaths"] 和
@secref["windowspaths"]。}


@defproc[(explode-path [path (or/c path-string? path-for-some-system?)])
         (listof (or/c path-for-some-system? 'up 'same))]{

返回构成 @racket[path] 的 @tech{path elements} 列表。如果
@racket[path] 在 @racket[simple-form-path] 的意义上被简化，
则结果始终是路径列表，且列表的第一个元素
是根。

@racket[explode-path] 函数在与 @racket[path] 长度
成正比的时间内计算结果（与使用
@racket[split-path] 的循环不同，后者必须分配中间路径）。}


@defproc[(path-replace-extension [path (or/c path-string? path-for-some-system?)]
                                 [ext (or/c string? bytes?)])
         path-for-some-system?]{

返回与 @racket[path] 相同的路径，但路径最后一个元素的
扩展名（包括扩展名分隔符）被更改为 @racket[ext]。如果
@racket[path] 的最后一个元素没有扩展名，则将 @racket[ext] 添加到
路径中。

扩展名定义为不在路径元素开头的 @litchar{.}，
后跟任意数量的非 @litchar{.} 字符/字节，
位于 @tech{path element} 的末尾，前提是
该路径元素不是像 @racket[".."] 这样的目录指示符。

@racket[path] 参数可以是任何平台的路径，
结果为同一平台。如果 @racket[path] 表示根，
则 @exnraise[exn:fail:contract]。给定的 @racket[ext] 通常
以 @litchar{.} 开头，但不要求以扩展名分隔符开头。

@examples[
(path-replace-extension "x/y.ss" #".rkt")
(path-replace-extension "x/y.ss" #"")
(path-replace-extension "x/y" #".rkt")
(path-replace-extension "x/y.tar.gz" #".rkt")
(path-replace-extension "x/.racketrc" #".rkt")
]

@history[#:added "6.5.0.3"]}


@defproc[(path-add-extension [path (or/c path-string? path-for-some-system?)]
                             [ext (or/c string? bytes?)]
                             [sep (or/c string? bytes?) #"_"])
         path-for-some-system?]{

类似于 @racket[path-replace-extension]，但 @racket[path] 上的任何现有扩展名
会被保留，方法是将扩展名前的 @litchar{.} 替换为
@racket[sep]，然后将 @racket[ext] 添加
到末尾。

@examples[
(path-add-extension "x/y.ss" #".rkt")
(path-add-extension "x/y" #".rkt")
(path-add-extension "x/y.tar.gz" #".rkt")
(path-add-extension "x/y.tar.gz" #".rkt" #".")
(path-add-extension "x/.racketrc" #".rkt")
]

@history[#:changed "6.8.0.2" @elem{添加了 @racket[sep] 可选参数。}
         #:added "6.5.0.3"]}


@defproc[(path-replace-suffix [path (or/c path-string? path-for-some-system?)]
                              [ext (or/c string? bytes?)])
         path-for-some-system?]{
@deprecated[#:what "function" @racket[path-replace-extension]]

类似于 @racket[path-replace-extension]，但将路径元素中前导的
@litchar{.} 视为扩展名分隔符。}

@defproc[(path-add-suffix [path (or/c path-string? path-for-some-system?)]
                          [ext (or/c string? bytes?)])
         path-for-some-system?]{

@deprecated[#:what "function" @racket[path-add-extension]]

类似于 @racket[path-add-extension]，但将路径元素中前导的
@litchar{.} 视为扩展名分隔符。}

@defproc[(reroot-path [path (or/c path-string? path-for-some-system?)]
                      [root-path (or/c path-string? path-for-some-system?)])
         path-for-some-system?]{

基于 @racket[path] 的完整形式生成一个扩展 @racket[root-path] 的路径。

如果 @racket[path] 尚未 @tech{complete}，则通过
@racket[path->complete-path] 使其完整，此时 @racket[path] 必须是
当前平台的路径。@racket[path] 参数还会被
@tech{cleanse}（清理）并通过 @racket[normal-case-path] 进行大小写规范化。
然后将路径追加到 @racket[root-path]；对于 Windows
路径，根字母驱动器变为字母路径元素，而根
UNC 路径以 @racket["UNC"] 作为路径元素前缀，
机器名和卷名变为路径元素。

@examples[
(reroot-path (bytes->path #"/home/caprica/baltar" 'unix)
             (bytes->path #"/earth" 'unix))
(reroot-path (bytes->path #"c:\\usr\\adama" 'windows)
             (bytes->path #"\\\\earth\\africa\\" 'windows))
(reroot-path (bytes->path #"\\\\galactica\\cac\\adama" 'windows)
             (bytes->path #"s:\\earth\\africa\\" 'windows))
]}

@;------------------------------------------------------------------------
@section{更多路径工具}

@(define path-eval (make-base-eval `(require racket/path)))

@note-lib[racket/path]

@defproc[(file-name-from-path [path (or/c path-string? path-for-some-system?)])
         (or/c path-for-some-system? #f)]{

返回 @racket[path] 的最后一个元素。如果 @racket[path]
在语法上是目录路径（参见 @racket[split-path]），则
结果为 @racket[#f]。}


@defproc[(path-get-extension [path (or/c path-string? path-for-some-system?)])
         (or/c bytes? #f)]{

返回一个字节字符串，即 @racket[path] 中文件名的
扩展名部分，包括 @litchar{.} 分隔符。如果路径没有
扩展名，则返回 @racket[#f]。

有关文件名扩展名的定义，请参见 @racket[path-replace-extension]。

@examples[#:eval path-eval
(path-get-extension "x/y.rkt")
(path-get-extension "x/y")
(path-get-extension "x/y.tar.gz")
(path-get-extension "x/.racketrc")
]

@history[#:added "6.5.0.3"]}


@defproc[(path-has-extension? [path (or/c path-string? path-for-some-system?)]
                              [ext (or/c bytes? string?)])
         boolean?]{

判断 @racket[path] 的最后一个元素是否以 @racket[ext] 结尾
但不完全相同于 @racket[ext]。

如果 @racket[ext] 是具有扩展名形状的 @tech{byte string}
（即以 @litchar{.} 开头且不包含另一个 @litchar{.}），此检查等同于
检查 @racket[(path-get-extension path)] 是否生成 @racket[ext]。

@examples[#:eval path-eval
(path-has-extension? "x/y.rkt" #".rkt")
(path-has-extension? "x/y.ss" #".rkt")
(path-has-extension? "x/y" #".rkt")
(path-has-extension? "x/.racketrc" #".racketrc")
(path-has-extension? "x/compiled/y_rkt.zo" #"_rkt.zo")
]

@history[#:added "6.5.0.3"]}


@defproc[(filename-extension [path (or/c path-string? path-for-some-system?)])
         (or/c bytes? #f)]{

@deprecated[#:what "function" @racket[path-get-extension]]

返回一个字节字符串，即 @racket[path] 中文件名的扩展名部分，
但不包含 @litchar{.} 分隔符。如果 @racket[path]
在语法上是目录（参见 @racket[split-path]）或路径没有
扩展名，则返回 @racket[#f]。}


@defproc[(find-relative-path [base (or/c path-string? path-for-some-system?)]
                             [path (or/c path-string?  path-for-some-system?)]
                             [#:more-than-root? more-than-root? any/c #f]
                             [#:more-than-same? more-than-same? any/c #t]
                             [#:normalize-case? normalize-case? any/c #t])
         (or/c path-for-some-system? path-string?)]{

找到相对于 @racket[base] 的相对路径名，该路径名引用
与 @racket[path] 相同的文件或目录。@racket[base] 和
@racket[path] 都必须在
@racket[simple-form-path] 的意义上被简化。如果 @racket[path] 与 @racket[base]
没有共同的子路径，则返回 @racket[path]。

如果 @racket[more-than-root?] 为真，且 @racket[base] 和
@racket[path] 只共享 Unix 根目录，且
@racket[base] 和 @racket[path] 都不是仅根路径，
则返回 @racket[path]。

如果 @racket[path] 与 @racket[base] 相同，则仅当
@racket[more-than-same?] 为 @racket[#f] 时返回
@racket[(build-path 'same)]。否则（默认情况），
当 @racket[path] 与 @racket[base] 相同时返回 @racket[path]。

如果 @racket[normalize-case?] 为真（默认值），则要比较的
路径元素对会先通过
@racket[normal-case-path] 转换，这意味着在 Windows 上
路径元素比较时不区分大小写。如果 @racket[normalize-case?] 为
@racket[#f]，则路径元素和路径根仅在
大小写相同时才匹配。

结果通常是 @racket[path?] 意义上的 @tech{path}。
只有当 @racket[path] 以字符串形式提供并作为结果返回时，
结果才是字符串。

@history[#:changed "6.8.0.3" @elem{默认情况下对路径元素进行大小写规范化以进行比较，并添加了 @racket[#:normalize-case?] 参数。}
         #:changed "6.90.0.21" @elem{添加了 @racket[#:more-than-same?] 参数。}]}


@defproc[(normalize-path [path path-string?]
                         [wrt (and/c path-string? complete-path?)
                              (current-directory)]) 
         path?]{

@margin-note{对于大多数用途，@racket[simple-form-path] 是
 规范化路径的首选机制，因为它适用于包含不存在目录组件的路径，
 并且避免不必要地展开软链接。}

返回 @racket[path] 的完整版本，通过使路径完整、
展开完整路径并解析所有软链接
（这需要查询文件系统）。如果 @racket[path] 是
相对路径，则使用 @racket[wrt] 作为基础路径。

@racket[normalize-path] @italic{不}规范化字母大小写。出于
这个原因和其他原因（例如路径在语法上是否为
目录），@racket[normalize-path] 的结果不适合用于
判断两个路径是否引用相同文件或目录的比较
（即，比较可能产生假阴性）。

如果输入路径包含对不存在目录的嵌入路径，
或检测到无限软链接循环，
@racket[normalize-path] 会发出错误信号。

@examples[#:eval (make-base-eval '(require racket/path))
  (equal? (current-directory) (normalize-path "."))
]}


@defproc[(path-element? [path any/c]) boolean?]{

如果 @racket[path] 是一个 @deftech{path element}（路径元素）：
即某个平台的路径值（参见 @racket[path-for-some-system?]），
使得对 @racket[path] 应用 @racket[split-path]
会返回 @racket['relative] 作为第一个结果、路径作为第二个
结果，则返回 @racket[#t]。否则，结果为 @racket[#f]。}


@defproc[(path-only [path (or/c path-string? path-for-some-system?)])
         (or/c #f path-for-some-system?)]{

在 @racket[path] 语法上不是目录的情况下，
返回不带最终路径元素的 @racket[path]；如果 @racket[path] 只有
一个非目录路径元素，则返回 @racket[#f]。如果
@racket[path] 语法上是目录，则
原样返回 @racket[path]（但如果原是字符串，则作为路径返回）。

@examples[#:eval path-eval
(path-only (build-path "a" "b"))
(path-only (build-path "a"))
(path-only (path->directory-path (build-path "a")))
(path-only (build-path 'up 'up))
]}


@defproc[(simple-form-path [path path-string?]) path?]{

返回 @racket[(simplify-path (path->complete-path path))]，
确保结果是包含无上级或同级目录指示符的完整路径。}

@defproc[(some-system-path->string [path path-for-some-system?])
         string?]{

使用路径字节的 UTF-8 编码将 @racket[path] 转换为字符串。

当处理不同系统的路径（其路径名编码可能与当前
语言环境编码无关）且以字符串开始和结束时，
使用此函数。}

@defproc[(string->some-system-path [str string?]
                                   [kind (or/c 'unix 'windows)])
         path-for-some-system?]{

使用路径字节的 UTF-8 编码将 @racket[str] 转换为 @racket[kind] 路径。

当处理不同系统的路径（其路径名编码可能与当前
语言环境编码无关）且以字符串开始和结束时，
使用此函数。}

@defproc[(shrink-path-wrt [pth path?] [other-pths (listof path?)]) (or/c #f path?)]{
  返回 @racket[pth] 的一个后缀，该后缀与 @racket[other-pths] 的后缀
  没有任何共同之处，如果不可能（例如当 @racket[other-pths]
  为空或仅包含与 @racket[pth] 具有相同元素的路径），则返回 @racket[pth]。
  
  @examples[#:eval path-eval
                   (shrink-path-wrt (build-path "racket" "list.rkt")
                                    (list (build-path "racket" "list.rkt")
                                          (build-path "racket" "base.rkt")))
                   
                   (shrink-path-wrt (build-path "racket" "list.rkt")
                                    (list (build-path "racket" "list.rkt")
                                          (build-path "racket" "private" "list.rkt")
                                          (build-path "racket" "base.rkt")))]

}

@close-eval[path-eval]

@;------------------------------------------------------------------------
@include-section["unix-paths.scrbl"]
@include-section["windows-paths.scrbl"]
