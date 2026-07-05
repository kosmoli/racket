#lang scribble/doc
@(require scribble/manual
          scribble/bnf
          "common.rkt"
          (for-label racket/base))

@title[#:tag "expand"]{@exec{raco expand}: Macro 展开}

@exec{raco expand} 命令对给定源文件的内容进行 macro 展开并美化打印。
另见 @racket[expand]。

命令行标志：

@itemlist[
  @item{@Flag{n} @nonterm{n} 或 @DFlag{columns} @nonterm{n}  --- 格式化输出以在 @nonterm{n} 列的显示器上显示}
  @item{@Flag{h} 或 @DFlag{help} --- 显示此命令的帮助信息}
  @item{@DFlag{} --- 不将剩余参数视为开关}
]
