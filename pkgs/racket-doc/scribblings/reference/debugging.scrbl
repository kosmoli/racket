#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "debugging"]{调试}

Racket 的内置调试支持局限于随异常打印的上下文（即 ``栈追踪''）信息。
在某些情况下，对于 Racket 的 @tech{BC} 实现，禁用 @tech{JIT} 编译器可能影响上下文信息。
对于 Racket 的 @tech{CS} 实现，设置 @envvar-indexed{PLT_CS_DEBUG} 环境变量
使编译记录表达式级上下文信息，而不仅仅是函数级信息。

@racketmodname[errortrace] 库支持更一致（独立于编译器）和精确的上下文信息。
@racketmodname[racket/trace] 库提供简单的追踪支持。最后，
@seclink[#:doc '(lib "scribblings/drracket/drracket.scrbl") "top" #:indirect? #t]{DrRacket}
编程环境提供更多的调试支持。

@include-section["trace.scrbl"]
