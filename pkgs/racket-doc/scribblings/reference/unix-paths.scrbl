#lang scribble/doc
@(require scribble/bnf "mz.rkt")

@title[#:tag "unixpaths"]{@|AllUnix| Paths}

在 @|AllUnix| 上的路径中，@litchar{/} 分隔路径的各个元素，@litchar{.} 作为路径元素
始终表示由前一个路径指示的目录，@litchar{..} 作为路径元素始终表示由前一个路径所
指示目录的父目录。路径中的前导 @litchar{~} 不会被特殊处理，但可使用
@racket[expand-user-path] 将前导 @litchar{~} 元素转换为用户特定的目录。
没有其他字符或字节在路径中具有特殊含义。多个相邻的 @litchar{/} 等价于一个
@litchar{/}（即它们充当单个路径分隔符）。

路径根始终是 @litchar{/}。以 @litchar{/} 开头的路径是绝对、完整的路径，
以任何其他字符开头的路径是相对路径。

任何以 @litchar{/} 结尾的路径名在语法上都指向目录，任何最后一个元素为 @litchar{.} 
或 @litchar{..} 的路径也是如此。

@|AllUnix| 路径通过将多个相邻的 @litchar{/} 替换为单个 @litchar{/} 进行 @techlink{cleanse}。

对于 @racket[(bytes->path-element _bstr)]，@racket[bstr] 不能包含任何 @litchar{/}，
否则会 @exnraise[exn:fail:contract]。@racket[(path-element->bytes _path)] 或
@racket[(path-element->string _path)] 的结果始终与 @racket[(path->bytes _path)] 和
@racket[(path->string _path)] 的结果相同。然而，这对于其他平台不适用，
因此在转换单个路径元素时应使用 @racket[path-element->bytes] 和 @racket[path-element->string]。

在 Mac OS 上，Finder 别名是零长度的文件。


@section[#:tag "unixpathrep"]{Unix Path Representation}

在 @|AllUnix| 上的路径原生是一个 byte string。为了向用户展示和进行其他基于 string 的操作，
路径使用当前 locale 的编码与 string 相互转换，使用 @litchar{?}（编码）或 @code{#\\uFFFD}
（解码）替换错误。请注意，编码不能容纳所有可能的路径作为不同的 string。