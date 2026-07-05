#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/phase+space))

@title[#:tag "phase+space"]{Phase 和 Space 工具}

@note-lib-only[racket/phase+space]

@racketmodname[racket/phase+space] 库提供了操作 @tech{phase level} 和 @tech{binding space} 组合表示的函数，特别是用于 @tech{require transformer} 和 @tech{provide transformer}。

当 @racket[identifier-binding]（以及类似函数如 @racket[identifier-transformer-binding]）、@racket[syntax-local-module-exports]、@racket[syntax-local-module-required-identifiers]、@racket[module-compiled-exports] 或 @racket[module->exports] 产生 phase-space 组合（或 phase-space 偏移组合）时，两个 @racket[equal?] 的值也将是 @racket[eqv?] 的。

@history[#:added "8.2.0.3"]

@defproc[(phase? [v any/c]) boolean?]{

如果 @racket[v] 是有效的 @tech{phase level} 表示则返回 @racket[#t]，否则返回 @racket[#f]。有效的表示要么是表示编号 phase level 的精确整数，要么是表示 @tech{label phase level} 的 @racket[#f]。}

@defproc[(space? [v any/c]) boolean?]{

如果 @racket[v] 是有效的 @tech{binding space} 表示则返回 @racket[#t]，否则返回 @racket[#f]。有效的表示要么是通过 @racket[make-interned-syntax-introducer] 访问作用域的 @tech{interned} symbol，要么是表示默认 binding space 的 @racket[#f]。}

@defproc[(phase+space? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{phase level} 和 @tech{binding space} 组合的有效表示则返回 @racket[#t]，否则返回 @racket[#f]。可能的表示如下：

@itemlist[

 @item{一个 phase（在 @racket[phase?] 意义下）本身，表示该 phase 加上默认的 binding space}

 @item{一个 pair，其 @racket[car] 是 phase，@racket[cdr] 是非 @racket[#f] 的 space（在 @racket[space?] 意义下）}

]}

@defproc[(phase+space [phase phase?] [space space?]) phase+space?]{

返回表示 @racket[phase] 和 @racket[space] 组合的值。}

@deftogether[(
@defproc[(phase+space-phase [p+s phase+space?]) phase?]
@defproc[(phase+space-space [p+s phase+space?]) phase?]
)]{

从组合中提取 @tech{phase level} 或 @tech{binding space} 组件。}

@defproc[(phase+space-shift? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{phase level} 偏移和 @tech{binding space} 偏移组合的有效表示则返回 @racket[#t]，否则返回 @racket[#f]。偏移可以通过 @racket[phase+shift+] 应用于 phase level 和 binding space 的组合。偏移的可能表示如下：

@itemlist[

 @item{精确整数 --- 表示 phase level 的偏移量，binding space 不变}

 @item{@racket[#f] --- 表示偏移到 @tech{label phase level}，binding space 不变}

 @item{一个 pair，其 @racket[car] 是精确整数或 @racket[#f]，@racket[cdr] 是 space（在 @racket[space?] 意义下） --- 表示 @racket[car] 中的 phase level 偏移和 @racket[cdr] 中 binding space 的变化}

]}

@defproc[(phase+space+ [p+s phase+space?] [shift phase+space-shift?])
         phase+space?]{

将 @racket[shift] 应用于 @racket[p+s] 以产生新的 @tech{phase level} 和 @tech{binding space} 组合。}

@defproc[(phase+space-shift+ [shift phase+space?] [additional-shift phase+space-shift?])
         phase+space-shift?]{

组合 @racket[shift] 和 @racket[additional-shift] 以产生一个新偏移，其行为等同于依次应用 @racket[shift] 和 @racket[additional-shift]。}
