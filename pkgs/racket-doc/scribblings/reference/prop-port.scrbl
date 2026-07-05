#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "portstructs"]{作为端口的结构}

@defthing[prop:input-port struct-type-property?]
@defthing[prop:output-port struct-type-property?]

@racket[prop:input-port] 和 @racket[prop:output-port] structure type 属性标识其实例可分别作为输入和输出端口的 structure types。

每个属性值可以是以下之一：

@itemize[
 
 @item{输入端口（对于 @racket[prop:input-port]）或输出端口（对于 @racket[prop:output-port]）：在这种情况下，将结构用作端口等同于使用给定的输入或输出端口。}

 @item{@racket[0]（含）到 structure type 中非自动字段数量（不含，不包含 supertype 字段）之间的精确非负整数：该整数标识 structure 中的一个字段，该字段必须指定为 immutable。如果该字段包含输入端口（对于 @racket[prop:input-port]）或输出端口（对于 @racket[prop:output-port]），则使用该端口。否则，使用空字符串输入端口作为 @racket[prop:input-port]，使用丢弃所有数据的端口作为 @racket[prop:output-port]。}

]

一些 procedure，如 @racket[file-position]，同时适用于输入和输出端口。当给定同时具有 @racket[prop:input-port] 和 @racket[prop:output-port] 属性的 structure type 的实例时，该实例用作输入端口。
