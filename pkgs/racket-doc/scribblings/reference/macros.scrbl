#lang scribble/doc
@(require "mz.rkt")

@title[#:style 'toc]{Macros}

@guideintro["macros"]{Macros}

关于程序如何解析的一般信息，见 @secref["syntax-model"]。特别地，@secref["expand-steps"] 子节描述了解析如何触发 macros，@secref["transformer-model"] 描述了如何调用 macro transformers。


@local-table-of-contents[]

@include-section["stx-patterns.scrbl"]
@include-section["stx-ops.scrbl"]
@include-section["stx-comp.scrbl"]
@include-section["stx-trans.scrbl"]
@include-section["stx-param.scrbl"]
@include-section["splicing.scrbl"]
@include-section["stx-props.scrbl"]
@include-section["stx-taints.scrbl"]
@include-section["stx-expand.scrbl"]
@include-section["stx-serialize.scrbl"]
@include-section["include.scrbl"]
@include-section["syntax-util.scrbl"]
@include-section["phase+space.scrbl"]
