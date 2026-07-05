#lang scribble/manual
@(require "common.rkt"
          (for-label racket/base
                     racket/contract
                     compiler/exe-dylib-path))

@title[#:tag "exe-dylib-path"]{Mac OS 动态库路径}

@defmodule[compiler/exe-dylib-path]{@racketmodname[compiler/exe-dylib-path] 库提供了在 Mac OS 可执行文件中读取和调整动态库引用的函数。}

@history[#:added "6.3"]

@defproc[(find-matching-library-path [exe-path path-string?]
                                     [library-str string?])
         (or/c #f string?)]{

在 @racket[exe-path] 中搜索动态链接信息，查找名称包含 @racket[library-str] 的库引用，并返回首个匹配的可执行文件对该库的路径。如果找不到匹配，则返回 @racket[#f]。}

@defproc[(update-matching-library-path [exe-path path-string?]
                                       [library-str string?]
                                       [library-path-str string?])
         void?]{

在 @racket[exe-path] 中搜索动态链接信息，查找每个名称包含 @racket[library-str] 的库引用，并将该库的可执行文件路径替换为 @racket[library-path-str]。

预期只有一个匹配，且更新假设新路径有足够的空间，可能是由于可执行文件与 @Flag{headerpad_max_install_names} 链接所致。}
