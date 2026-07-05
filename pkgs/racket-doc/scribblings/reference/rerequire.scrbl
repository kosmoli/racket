#lang scribble/doc
@(require "mz.rkt" (for-label racket/rerequire))

@title[#:tag "rerequire"]{加载和重新加载模块}

@note-lib-only[racket/rerequire]

@defproc[(dynamic-rerequire [module-path module-path?]
                            [#:verbosity verbosity (or/c 'all 'reload 'none) 'reload])
	 (listof path?)]{

类似 @racket[(dynamic-require module-path 0)]，但支持重新加载。@racket[dynamic-rerequire] function 旨在用于交互式环境，特别是通过 @racket[enter!]。

如果调用 @racket[module-path] 需要加载任何文件，则记录文件的修改日期。如果文件被修改，则后续 @racket[dynamic-rerequire] 会重新从源码加载 module；另见 @secref["module-redeclare"]。类似地，如果后续 @racket[dynamic-rerequire] 传递性 @racket[require] 了已修改的 module，则重新加载所需的模块。重新加载支持仅对首次通过 @racket[dynamic-rerequire]（直接或间接通过传递性 @racket[require]s）加载的 module 有效。

返回的列表包含在此调用 @racket[dynamic-rerequire] 时重新加载的 module 的绝对路径。如果返回的列表为空，则没有模块被更改或加载。

当 @racket[enter!] 从文件加载或重新加载 module 时，它可以向 @racket[(current-error-port)] 打印消息，具体取决于 @racket[verbosity]：@racket['all] 为所有加载和重新加载打印消息，@racket['reload] 仅为重新加载的 module 打印消息，@racket['none] 禁止打印。}
