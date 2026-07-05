#lang scribble/doc

@(require scribble/manual
          scribble/bnf
          (for-label racket/gui
                     compiler/bundle-dist))

@title{用于打包分发的 API}

@defmodule[compiler/bundle-dist]{

@racketmodname[compiler/bundle-dist] 库提供了一个函数，
用于将目录（通常是由 @racket[assemble-distribution] 组装的）包装成分发文件。
在 Windows 上，结果是 @filepath{.zip} 归档；在 Mac OS 上，是
@filepath{.dmg} 磁盘映像；在 Unix 上，是 @filepath{.tgz} 归档。}


@defproc[(bundle-directory [dist-file file-path?] 
                           [dir file-path?]
                           [for-exe? any/c #f])
         void?]{

将 @racket[dir] 打包到 @racket[dist-file] 中。如果 @racket[dist-file]
没有扩展名，会自动添加文件扩展名（使用
@racket[bundle-put-file-extension+style+filters] 的第一个结果）。

创建的归档包含名称与 @racket[dir] 相同的目录——除非在 Mac OS 上，当
@racket[for-exe?] 为真且 @racket[dir] 包含一个单独文件或目录，
在这种情况下，创建的磁盘映像只包含该文件或目录。
@racket[for-exe?] 的默认值为 @racket[#f]。

如果 @racket[dist-file] 存在，归档创建将失败。}


@defproc[(bundle-put-file-extension+style+filters)
         (values (or/c string? #f)
                 (listof (or/c 'packages 'enter-packages))
                 (listof (list/c string? string?) ))]{

返回三个值，适合用作 @racket[put-file] 的 @racket[extension]、
@racket[style] 和 @racket[filters] 参数，以分别选择分发文件名。}