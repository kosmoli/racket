#lang scribble/doc
@(require scribble/manual "common.rkt")

@title{@exec{raco}: Racket 命令行工具}

@exec{raco} 程序支持从命令行执行各种 Racket 任务。传递给 @exec{raco} 的第一个参数始终是具体的命令名称。例如，@exec{raco make} 启动一个将 Racket 源模块编译为 bytecode 格式的命令。

@exec{raco} 中可用的命令集是可扩展的。使用 @exec{raco help} 可获取您安装中可用命令的完整列表。本手册涵盖典型 Racket 安装中的可用命令。

@table-of-contents[]

@include-section["make.scrbl"]
@include-section["exe.scrbl"]
@include-section["dist.scrbl"]
@include-section["planet.scrbl"]
@include-section["pkg.scrbl"]
@include-section["setup.scrbl"]
@include-section["decompile.scrbl"]
@include-section["demod.scrbl"]
@include-section["link.scrbl"]
@include-section["plt.scrbl"]
@include-section["unpack.scrbl"]
@include-section["ctool.scrbl"]
@include-section["test.scrbl"]
@include-section["docs.scrbl"]
@include-section["expand.scrbl"]
@include-section["read.scrbl"]
@include-section["scribble.scrbl"]
@include-section["command.scrbl"]
@include-section["config.scrbl"]
