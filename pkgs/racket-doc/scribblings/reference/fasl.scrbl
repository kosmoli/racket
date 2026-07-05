#lang scribble/doc
@(require "mz.rkt" (for-label racket/fasl racket/serialize racket/fixnum racket/flonum))

@(define fasl-eval (make-base-eval))
@examples[#:hidden #:eval fasl-eval (require racket/fasl)]

@title[#:tag "fasl"]{Fast-Load Serialization}

@note-lib-only[racket/fasl]

@deftogether[(
@defproc[(s-exp->fasl [v any/c]
                      [out (or/c output-port? #f) #f]
                      [#:keep-mutable? keep-mutable? any/c #f]
                      [#:handle-fail handle-fail (or/c #f (any/c . -> . any/c)) #f]
                      [#:external-lift? external-lift? (or/c #f (any/c . -> . any/c)) #f]
                      [#:skip-prefix? skip-prefix? any/c #f])
         (or/c void? bytes?)]
@defproc[(fasl->s-exp [in (or/c input-port? bytes?)]
                      [#:datum-intern? datum-intern? any/c #t]
                      [#:external-lifts external-lifts vector? '#()]
                      [#:skip-prefix? skip-prefix? any/c #f])
         any/c]
)]{

@racket[s-exp->fasl] 函数将 @racket[v] 序列化为 byte string，当 @racket[out] 是 output port 时直接打印到 @racket[out]，否则返回 byte string。@racket[fasl->s-exp] 函数从 byte string（直接提供或作为 input port）解码由 @racket[s-exp->fasl] 编码的值。

@racket[v] 参数必须是一个可以作为字面量被 @racket[quote] 的值——即一个没有 syntax object 的值，@racket[(compile `(quote ,v))] 对其有效并且在 @racket[write] 后是可 @racket[read] 的——或者它可以包含与这些值混合的 @tech{correlated object}。但 @racket[s-exp->fasl] 产生的 byte string 不使用与编译代码相同的格式。

如果 @racket[v] 内的值不是有效的 @racket[quote] 字面量，并且 @racket[handle-fail] 不是 @racket[#f]，则 @racket[handle-fail] 在嵌套值上调用，@racket[handle-fail] 的结果写入该值的位置。@racket[handle-fail] procedure 可能引发异常而不是返回替换值。如果 @racket[handle-fail] 是 @racket[#f]，则在遇到无效值时 @exnraise[exn:fail:contract]。

如果 @racket[external-lift?] 不是 @racket[#f]，则它接收 @racket[s-exp->fasl] 在 @racket[v] 中遇到的每个值 @racket[_v-sub]。如果 @racket[external-lift?] 对 @racket[_v-sub] 的结果是真，则 @racket[_v-sub] 不在结果中编码，而是被当作 @deftech{externally lifted}。反序列化的 @racket[fasl->s-exp] 接收一个 @racket[external-lifts] vector，按序列化时传递给 @racket[external-lift?] 的顺序为每个外部提升的值提供一个值。

类似于 @racket[(compile `(quote ,v))]，@racket[s-exp->fasl] 不保留 graph 结构，不支持循环，也不处理非 @tech{prefab} structure。将 @racket[s-exp->fasl] 与 @racket[serialize] 组合以保留 graph 结构、处理循环数据以及编码可序列化的 structure。@racket[s-exp->fasl] 和 @racket[fasl->s-exp] 函数查询 @racket[current-write-relative-directory] 和 @racket[current-load-relative-directory]（fallback 到 @racket[current-directory]），与字节码保存和存储路径的方式相同（以相对形式），它们同样允许和转换带约束的 @racket[srcloc] 值（见 @secref["print-compiled"]）。

除非 @racket[keep-mutable?] 作为真提供给 @racket[s-exp->fasl]，否则 @racket[v] 中的可变值在 @racket[fasl->s-exp] 解码结果时被不可变值替换。除非 @racket[datum-intern?] 作为 @racket[#f] 提供，否则 @racket[fasl->s-exp] 产生的任何不可变值都通过 @racket[datum-intern-literal] 过滤。默认值使得 @racket[s-exp->fasl] 和 @racket[fasl->s-exp] 的组合表现类似于 @racket[write] 和 @racket[read] 的组合。

如果 @racket[skip-prefix?] 是 @racket[#f]，则标识流为序列化格式的前缀由 @racket[s-exp->fasl] 写入并由 @racket[fasl->s-exp] 读取。省略前缀可以节省少量空间（在序列化小值时有用），但会放弃对 @racket[fasl->s-exp] 通常有用的健全性检查。

@racket[s-exp->fasl] 产生的 byte string 编码与 Racket 版本无关，除非未来的 Racket 版本引入了当前不被识别的扩展。特别地，@racket[s-exp->fasl] 的结果将作为任何未来版本 @racket[fasl->s-exp] 的有效输入（只要 @racket[skip-prefix?] 参数一致）。

@mz-examples[
#:eval fasl-eval
(define fasl (s-exp->fasl (list #("speed") 'racer #\!)))
fasl
(fasl->s-exp fasl)
]

@history[#:changed "6.90.0.21" @elem{使 @racket[s-exp->fasl] 格式版本无关并添加了 @racket[#:keep-mutable?] 和 @racket[#:datum-intern?] 参数。}
         #:changed "7.3.0.7" @elem{添加了对 @tech{correlated object} 的支持。}
         #:changed "7.5.0.3" @elem{添加了 @racket[#:handle-fail] 参数。}
         #:changed "7.5.0.9" @elem{添加了 @racket[#:external-lift?] 和 @racket[#:external-lifts] 参数。}
         #:changed "8.9.0.4" @elem{添加了对 @tech{fxvector} 和 @tech{flvector} 的支持。}]}

@; ----------------------------------------------------------------------

@close-eval[fasl-eval]
