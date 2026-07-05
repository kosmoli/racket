#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/pretty racket/gui/base setup/dirs))

@title{初始化库}

@defmodule*/no-declare[(racket/init)]{@racketmodname[racket/init] 库是
 Racket 的默认启动库。它重新导出 @racketmodname[racket]、
 @racketmodname[racket/enter] 和 @racketmodname[racket/help] 库，
 并将 @racket[current-print] 设置为使用 @racket[pretty-print]。}

@defmodule*/no-declare[(racket/interactive)]{
 @racketmodname[racket/interactive] 是 REPL 开始时的默认启动
 库。如果指定了 @Flag{q}/@DFlag{no-init-file} 则不会运行。交互
 文件可通过修改 @filepath{config.rktd} 文件中的 @racket['interactive-file] 来更改，
 该文件位于 @racket[(find-config-dir)] 中。或者，如果文件
 @filepath{interactive.rkt} 存在于 @racket[(find-system-path 'addon-dir)]
 中，则运行它而不是安装范围的全局交互模块。

 默认交互模块启动 @racketmodname[xrepl]，并运行用户主目录中的
 @racket[(find-system-path 'init-file)] 文件。不同的交互文件
 可通过 require @racketmodname[racket/interactive] 来保留此行为。
 
 @history[#:added "6.7"]}


@defmodule*/no-declare[(racket/language-info)]{@racketmodname[racket/language-info] 库
提供一个 @racketidfont{get-info} 函数，该函数接受任意值并返回
另一个函数；返回的函数接受一个键值和一个默认值，并在键为
 @racket['configure-runtime] 时返回 @racket['#(racket/runtime-config
 configure #f)]，否则返回默认值。}

@guidealso["module-runtime-config"]

矢量 @racket['#(racket/language-info get-info #f)] 适合
附加到模块作为其 language info，以获取与 @racket[racket/base]
语言相同的语言信息。

@defmodule*/no-declare[(racket/runtime-config)]{@racketmodname[racket/runtime-config] 库
提供一个 @racketidfont{configure} 函数，该函数接受任意值
并将 @racket[print-as-expression] 设置为 @racket[#t]。}

矢量 @racket[#(racket/runtime-config configure #f)] 适合
作为运行时配置规范列表中的一个成员（由模块的 language-information
函数为键 @racket['configure-runtime] 返回），以获得与
@racketmodname[racket/base] 语言相同的运行时配置。
