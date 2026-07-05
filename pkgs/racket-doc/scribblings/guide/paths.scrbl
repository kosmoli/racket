#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "paths"]{路径}

@deftech{path} 封装了一个文件系统路径，它（潜在地）命名一个文件或目录。
尽管路径可以在字符串和字节串之间相互转换，但字符串和字节串都不适合表示一般路径。
问题在于路径在文件系统中表示为字节序列或 UTF-16 序列（取决于操作系统）；
这些序列并不总是人类可读的，且并非所有序列都能解码为 Unicode 标量值。

尽管偶尔存在编码问题，大多数路径仍可在字符串之间来回转换。
因此，接受路径参数的过程总是接受字符串，路径的打印形式使用
@litchar{#<path:} 和 @litchar{>} 内部的字符串解码。
路径的 @racket[display] 形式与其字符串编码的 @racket[display] 形式相同。

@examples[
(string->path "my-data.txt")
(file-exists? "my-data.txt")
(file-exists? (string->path "my-data.txt"))
(display (string->path "my-data.txt"))
]

产生文件系统引用的过程总是产生路径值，而非字符串。

@examples[
(path-replace-suffix "foo.scm" #".rkt")
]

尽管有时倾向于直接操作表示文件系统路径的字符串，
但正确操作一条路径可能出奇地困难。Windows 路径操作尤其棘手，
因为 @filepath{aux} 等路径元素可能具有特殊含义。

@refdetails/gory["windows-path"]{Windows 文件系统路径}

使用 @racket[split-path] 和 @racket[build-path] 等过程来分解和构造路径。
当你必须操作特定路径元素（即路径中的文件或目录组件）的名称时，
使用 @racket[path-element->bytes] 和 @racket[bytes->path-element] 等过程。

@examples[
(build-path "easy" "file.rkt")
(split-path (build-path "easy" "file.rkt"))
]
