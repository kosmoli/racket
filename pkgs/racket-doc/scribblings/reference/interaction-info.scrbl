#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "interaction-info"]{交互配置}

@note-lib-only[racket/interaction-info]

@racketmodname[racket/interaction-info] 库提供了一种为 @racket[read]-@racket[eval]-@racket[print] loop 和编辑器注册 langauge 配置的方法。

@defparam[current-interaction-info info (or/c #f (vector/c module-path? symbol? any/c))]{

一个为语言提供配置供交互式开发工具使用的 @tech{parameter}，例如支持语法着色和缩进支持的命令行求值提示符。此 parameter 通常由 @racketidfont{configure-runtime} module 设置；另见 @secref["configure-runtime"]。

@racket[current-interaction-info] parameter 不直接提供配置信息，而是指定要加载的 module、要调用的导出 function 以及要作为参数传递给导出 function 的数据。该 function 的结果应该是另一个接受两个参数的 function：一个符号表示请求的信息类型（由外部工具定义），以及一个默认值，如果符号未被识别，通常应返回该默认值。

关于定义新 @hash-lang[] 语言的信息，见 @racketmodname[syntax/module-reader]。

@history[#:added "8.3.0.2"]}
