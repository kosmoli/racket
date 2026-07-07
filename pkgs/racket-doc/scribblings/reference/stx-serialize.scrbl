#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/fasl
                     racket/serialize))

@title{Serializing Syntax}

@defproc[(syntax-serialize [stx syntax?]
                           [#:preserve-property-keys preserve-property-keys (listof symbol?)]
                           [#:provides-namespace provides-namespace (or/c namespace? #f) (current-namespace)]
                           [#:base-module-path-index base-module-path-index (or/c module-path-index? #f) #f])
         any/c]{

将 @racket[stx] 转换为适合与 @racket[s-exp->fasl] 或 @racket[serialize] 一起使用的序列化形式。虽然 @racket[stx] 可以先用 @racket[(compile `(quote-syntax ,stx))] 编译后再写入编译形式，但 @racket[syntax-serialize] 对序列化提供了更多控制：

@itemlist[

 @item{@racket[preserve-property-keys] 列出要在序列化时保留其值的 syntax-property key，即使该属性值没有通过 @racket[syntax-property] 添加为保留属性（从而在编译形式中被丢弃）。与这些要保留的属性关联的值必须是可序列化的——满足 @racket[syntax-property] 对保留属性的要求。}

 @item{@racket[provides-namespace] 参数约束序列化的 syntax 对象在多大程度上能够依赖 @deftech{批量绑定}（bulk bindings），即由导出模块提供的共享绑定表。如果 @racket[provides-namespace] 是 @racket[#f]，则将完整的绑定信息记录在 syntax 对象的序列化形式中，反序列化时不再需要 namespace 提供任何批量绑定。反之，批量绑定的使用仅限于 @racket[provides-namespace] 中声明的模块（即反序列化时的 namespace 与 @racket[provides-namespace] 具有相同的模块声明）；值得注意的是，提供一个不含 module bindings 的 namespace 等同于提供 @racket[#f]。}

 @item{@racket[base-module-path-index] 参数指定一个 @tech{module path index}，@racket[stx] 中的绑定信息将相对于它。例如，如果一个 syntax 对象来自模块主体内的 @racket[quote-syntax]，那么 @racket[base-module-path-index] 可以取为外围 module 的 module path index，正如在模块内调用 @racket[(variable-reference->module-path-index (#%variable-reference))] 所得的结果。反序列化时，可以提供不同的 module path index 来替代 @racket[base-module-path-index]，从而将所有相对于序列化时 module 身份的绑定，转变为相对于反序列化时提供的 module 身份。如果 @racket[base-module-path-index] 是 @racket[#f]，则反序列化时不支持任何替代，此时提供的任何 @racket[base-module-path-index] 都会被忽略。}

]

序列化的 syntax 对象在其他方面与编译代码类似：它是版本相关的，反序列化时需要足够强大的 @tech{code inspector}。

@history[#:added "8.0.0.13"]}

@defproc[(syntax-deserialize [v any/c]
                             [#:base-module-path-index base-module-path-index (or/c module-path-index? #f) #f])
         syntax?]{

将 @racket[syntax-serialize] 的结果转换回一个 syntax 对象。参见 @racket[syntax-serialize] 了解更多信息。

@history[#:added "8.0.0.13"]}
