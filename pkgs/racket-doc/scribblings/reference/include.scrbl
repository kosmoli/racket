#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "include"]{文件包含}

@note-lib[racket/include]

@defform/subs[#:literals (file lib)
              (include path-spec)
              ([path-spec string
                          (file string)
                          (lib string ...+)])]{

将 @racket[path-spec] 指定的文件中的语法内联到 @racket[include] 表达式的位置。

@racket[path-spec] 类似于用于 @racket[require] 的 @racket[_mod-path] 形式的子集，但它指定一个其内容不必是模块的文件。也就是说，@racket[string] 使用平台无关的相对路径引用一个文件，@racket[(file string)] 使用平台相关的表示法引用一个文件，而 @racket[(lib string ...)] 引用一个集合中的文件。

如果 @racket[path-spec] 指定了一个相对路径，则该路径相对于 @racket[include] 表达式的源解析（如果该源是完整的路径字符串）。如果源不是完整的路径字符串，则 @racket[path-spec] 相对于 @racket[(current-load-relative-directory)] 解析（如果它不是 @racket[#f]），否则相对于 @racket[(current-directory)] 解析。

被包含的语法被赋予 @racket[include] 表达式的词法上下文，而被包含的语法的源位置引用其实际源。}


@defform[(include-at/relative-to context source path-spec)]{

类似于 @racket[include]，但使用 @racket[context] 的词法上下文作为被包含语法的上下文，并且相对 @racket[path-spec] 相对于 @racket[source] 的源解析。@racket[context] 和 @racket[source] 元素在展开时被丢弃。}


@defform[(include/reader path-spec reader-expr)]{

类似于 @racket[include]，但使用由表达式 @racket[reader-expr] 产生的过程来读取被包含的文件，而不是 @racket[read-syntax]。

@racket[reader-expr] 在展开时在 @tech{转换器环境}中求值。由于它作为 @racket[read-syntax] 的替代，表达式的值应该是一个消耗两个输入（一个表示源的字符串和一个输入端口）并产生一个 syntax object 或 @racket[eof] 的过程。该过程将被反复调用，直到它产生 @racket[eof]。

该过程返回的 syntax object 应该具有源位置信息，但通常没有词法上下文；syntax object 中的任何词法上下文都将被忽略。}


@defform[(include-at/relative-to/reader context source path-spec reader-expr)]{

组合 @racket[include-at/relative-to] 和 @racket[include/reader]。}
