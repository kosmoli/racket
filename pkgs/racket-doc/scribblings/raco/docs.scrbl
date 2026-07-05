#lang scribble/doc
@(require scribble/manual
          scribble/bnf
          "common.rkt")

@title[#:tag "docs"]{@exec{raco docs}: 文档搜索}

@exec{raco docs} 命令根据给定的标识符或搜索词搜索文档。

命令行标志：

@itemlist[
  @item{@Flag{f} @nonterm{name} 或 @DFlag{family}  @nonterm{name} --- 作为语言族 @nonterm{name} 导航文档，
        如果没有给出搜索词可能影响起点，可能影响搜索结果的顺序，
        并可能影响 ``top'' 和 ``up'' 导航。}
  @item{@Flag{h} 或 @DFlag{help} --- 显示此命令的帮助信息。}
  @item{@DFlag{} --- 不将剩余参数视为开关。}
]
