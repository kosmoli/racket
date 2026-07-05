#lang scribble/doc
@(require scribble/manual
          scribble/bnf
          "common.rkt"
          (for-label racket/base))

@title[#:tag "read"]{@exec{raco read}: 读取和美化打印}

@; 将 `history` 关联到正确的包：
@(declare-exporting compiler/commands/read)

@exec{raco read} 命令 @racket[read] 并美化打印给定文件的内容。
此命令对于显示 @tt{#reader} 或 @hash-lang[] 的 reader 扩展
如何将输入转换为 S-expression 很有用。对于美化打印已经是
S-expression 形式的项也很有用。

命令行标志：

@itemlist[
  @item{@Flag{n} @nonterm{n} 或 @DFlag{columns} @nonterm{n}  --- 格式化输出以在 @nonterm{n} 列的显示器上显示}
  @item{@Flag{h} 或 @DFlag{help} --- 显示此命令的帮助信息}
  @item{@DFlag{} --- 不将剩余参数视为开关}
]

@history[#:added "1.3"]
