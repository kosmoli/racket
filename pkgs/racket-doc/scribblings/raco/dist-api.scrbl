#lang scribble/doc

@(require scribble/manual
          scribble/bnf
          (for-label racket/gui
                     compiler/distribute
                     launcher/launcher))

@title{用于分发可执行文件的 API}

@defmodule[compiler/distribute]{

@racketmodname[compiler/distribute] 库提供了一个函数，
执行与 @exec{raco distribute} 相同的工作。}


@defproc[(assemble-distribution [dest-dir path-string?]
                                [exec-files (listof path-string?)]
                                [#:executables? executables? any/c #t]
                                [#:relative-base relative-base (or/c path-string? #f) #f]
                                [#:collects-path path (or/c #f (and/c path-string? relative-path?)) #f]
                                [#:copy-collects dirs (listof path-string?) null])
         void?]{

将 @racket[exec-files] 中的可执行文件复制到目录 @racket[dest-dir]，
以及可执行文件运行在不同机器上所需的 DLL、framework、共享库和/或运行时文件。
如果 @racket[executables?] 为 @racket[#f]，则 @racket[exec-files] 被视为普通数据文件，
而不是可执行文件，并且它们会被就地修改。

@racket[dest-dir] 中可执行文件和支持文件的排列取决于平台。通常，
@racket[assemble-distribution] 会尝试做正确的事，但非 @racket[#f] 的
@racket[relative-base] 值指定了运行时相对于可执行文件到达组装内容的路径。
当 @racket[executables?] 为 @racket[#f] 时，默认访问路径是 @racket[dest-dir]，
保留其相对性。

如果提供了 @racket[#:collects-path] 参数，它会覆盖打包可执行文件的主
@filepath{collects} 目录的默认位置。它应该相对于 @racket[dest-dir] 目录
（通常在内部）。

@racket[#:copy-collects] 参数中每个目录的内容被复制到打包可执行文件的主
@filepath{collects} 目录中。

@history[#:changed "6.3" @elem{添加了 @racket[#:executables?]
                                      和 @racket[#:relative-base] 参数。}]}