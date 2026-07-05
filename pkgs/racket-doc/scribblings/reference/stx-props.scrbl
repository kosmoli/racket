#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "stxprops"]{语法对象属性}

每个 syntax object 都关联一个 @deftech{syntax property} 列表，
可通过 @racket[syntax-property] 查询或扩展。属性可以设为
@deftech[#:key "stx-prop-preserved"]{preserved}（保留）或不保留；
保留的属性在 syntax object 被编译并 marshal 为字节串或
@filepath{.zo} 文件时仍被保留，而其他属性在 marshal 时被丢弃。

在 @racket[read-syntax] 中，reader 会为解析过程中生成的 pair 或 vector syntax object
附加一个保留的 @racket['paren-shape] 属性：当解析 @litchar{[} 和 @litchar{]} 这一对时，
属性值为 @racket[#\[]；当解析 @litchar["{"] 和 @litchar["}"] 这一对时，
属性值为 @racket[#\{]。@racket[syntax] 形式会将源 template 上的任意 @racket['paren-shape]
属性复制到对应生成的 syntax 上。

一个 transformer 接受的 syntax input 以及它产生的 syntax result 都可以带有属性。
这两组属性由 syntax expander 合并：原始 input 中存在但 result 中没有的属性会被复制到 result；
两者都存在的属性值会通过 @racket[cons] 合并（result 的值在前，原始值在后），
合并后的值在任意一方原值为保留时也被 @tech[#:key "stx-prop-preserved"]{preserved}。

但在执行合并之前，syntax expander 会使用 key @indexed-racket['origin]
自动为原始 syntax object 添加一个属性。如果源 syntax 没有
@racket['origin] 属性，则将其初始化为空列表。然后，在合并之前，
触发 macro expansion 的 identifier（作为 syntax）被 @racket[cons]
到目前的 @racket['origin] 属性上。因此，@racket['origin] 属性按逆序记录了
生成最终展开式的 macro expansion 序列。通常 @racket['origin] 的值是 identifier 列表，
但 transformer 可能返回已经被展开的 syntax，此时合并后的 @racket['origin] 列表可以包含其他列表。
@racket[syntax-track-origin] 过程实现了此跟踪功能。
@racket['origin] 属性以非 @tech[#:key "stx-prop-preserved"]{preserved} 方式添加。

除了通用 macro expansion 的 @racket['origin] 跟踪之外，
Racket 还会通过展开后的 syntax 添加属性（通常借助 @racket[syntax-track-origin]），
以记录更多展开细节：

@itemize[

 @item{当 @racket[begin] 形式被拼接进包含 internal definitions 的序列中时
（参见 @secref["intdef-body"]），
对 @racket[begin] 体中的每个拼接元素应用 @racket[syntax-track-origin]。
其第二个参数是 @racket[begin] 形式，第三个参数是该 @racket[begin] keyword
（从拼接的形式中提取）。}

 @item{当内部的 @racket[define-values] 或 @racket[define-syntaxes] 被转换为
 @racket[letrec-syntaxes+values] 形式时（参见 @secref["intdef-body"]），
对每个生成的 binding clause 应用 @racket[syntax-track-origin]。
其第二个参数是被转换的形式，第三个参数是该 @racket[define-values] 或
@racket[define-syntaxes] keyword。}

 @item{当 @racket[letrec-syntaxes+values] 表达式被完全展开时，syntax bindings 消失，
结果可能是 @racket[letrec-values] 形式（如果未展开形式中包括非 syntax bindings），
也可能只是 @racket[letrec-syntaxes+values] 形式的 body（如果 body 包含多个表达式则用 @racket[begin] 包裹）。
为了记录消失的 syntax bindings，会在展开结果中附加一个属性：用来自消失 bindings 的 identifier 构成的
immutable list 作为 @indexed-racket['disappeared-binding] 属性的值。}

 @item{当 subtyping @racket[struct] 形式被展开时，用于引用基类的 identifier
不会出现在展开结果中。因此，@racket[struct] transformer 会把这个 identifier
添加到展开结果中，作为 @indexed-racket['disappeared-use] 属性。}

 @item{当使用 @tech{rename transformer} 替换 @racket[set!] 的目标时，
会对其目标 identifier 使用 @racket[syntax-track-origin]
（与该 identifier 用作 expression 时的处理方式相同）。}

 @item{当发现对 module 中未导出或受保护的 identifier 的引用时，
会向该 identifier 添加 @indexed-racket['protected] 属性，值为 @racket[#t]。}

 @item{当 @racket[read-syntax] 生成 syntax object 时，它会在该对象上附加一个属性
（使用一个私有 key），用以标记该对象来自读取操作。@racket[syntax-original?]
 谓词查找此属性以识别这类 syntax object。（参见 @secref["stxops"] 获取更多信息。
此属性不会在 expander 从 macro transformer input 转移到 output 时被传递，
也不会被 @racket[syntax-track-origin] 传递。）}

]

另请参见关于 @racket['disappeared-use] 和 @racket['disappeared-binding] 属性
的一个典型消费者@seclink["Syntax_Properties_that_Check_Syntax_Looks_For"
                  #:doc '(lib "scribblings/tools/tools.scrbl")
                  #:indirect? #t]{Check Syntax}。

参见 @secref["modinfo"] 了解 module 声明展开所生成属性的信息。
参见 @racket[lambda] 和 @secref["infernames"] 了解 procedure 编译时所识别属性的信息。
参见 @racket[current-compile] 了解属性与字节码的信息。

@;------------------------------------------------------------------------

@defproc*[([(syntax-property [stx syntax?]
                             [key (if preserved? (and/c symbol? symbol-interned?) any/c)]
                             [v any/c]
                             [preserved? any/c (eq? key 'paren-shape)])
             syntax?]
           [(syntax-property [stx syntax?] [key any/c]) any])]{

The three- or four-argument form extends @racket[stx] by associating
an arbitrary property value @racket[v] with the key @racket[key]; the
result is a new syntax object with the association (while @racket[stx]
itself is unchanged). The property is added as
@tech[#:key "stx-prop-preserved"]{preserved} if @racket[preserved?] is true, in
此时 @racket[key] 必须是 @tech{interned} symbol，且 @racket[v] 应为下文所述的可以存入 marshal 后字节码的值。


两参数形式返回与 @racket[stx] 的 @racket[key] 关联的任意属性值，
如果 @racket[stx] 没有与 @racket[key] 关联的值则返回 @racket[#f]。
如果 @racket[stx] 是 @tech{tainted} 的，则包含结果值的 syntax object 也被 tainted。

为了支持 marshal 到字节码，preserved syntax property 的值必须是满足以下任一条件的非循环值：

@itemlist[

 @item{包含允许的 preserved-property 值的 @tech{pair}；}
 
 @item{包含允许的 preserved-property 值的 @tech{vector}（marshal 为 immutable）；}

 @item{包含允许的 preserved-property 值的 @tech{box}（marshal 为 immutable）；}

 @item{包含允许的 preserved-property 值的 immutable @tech{prefab} structure；}

 @item{key 和 value 均为允许的 preserved-property 值的 immutable @tech{hash table}；}

 @item{@tech{syntax object}；或}

 @item{空 list、@tech{symbol}、@tech{number}、@tech{character}、
       @tech{string}、@tech{byte string} 或 @tech{regexp 值}。}

]

对于 preserved property，任何其它值会在尝试将所属 syntax object marshal 为字节码形式时触发异常。

@history[#:changed "6.4.0.14" @elem{Added the @racket[preserved?] argument.}]}


@defproc[(syntax-property-remove [stx syntax?]
                                 [key any/c])
         syntax?]{

返回一个与 @racket[stx] 相同的 syntax object，但不含与 @racket[key] 关联的属性（如果有的话）。

@history[#:added "6.90.0.20"]}


@defproc[(syntax-property-preserved? [stx syntax?] [key (and/c symbol? symbol-interned?)])
         boolean?]{

如果 @racket[stx] 在 @racket[key] 上有一个
@tech[#:key "stx-prop-preserved"]{preserved} 属性值则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.4.0.14"]}


@defproc[(syntax-property-symbol-keys [stx syntax?]) list?]{

返回所有在 @racket[stx] 中关联了属性的 symbol 列表。
@tech{Uninterned} symbol（参见 @secref["symbols"]）不包含在结果列表中。}


@defproc[(syntax-track-origin [new-stx syntax?] [orig-stx syntax?] [id-stx identifier?])
         any]{

以 macro expansion 向 transformer result 添加属性的相同方式，
向 @racket[new-stx] 添加属性。具体而言，它会将 @racket[orig-stx] 的属性合并到 @racket[new-stx]，
先将 @racket[id-stx] 作为一个 @racket['origin] 属性添加，并移除 @racket[syntax-original?] 识别的属性，
然后返回该扩展了属性的 syntax object。
在丢弃 syntax（对应 @racket[orig-stx]）并以 keyword @racket[id-stx]
留下另外 syntax（对应 @racket[new-stx]）的 macro transformer 中使用 @racket[syntax-track-origin] 过程。

例如，表达式

@racketblock[
(or x y)
]

展开为

@racketblock[
(let ([or-part x]) (if or-part or-part (or y)))
]

which, in turn, 展开为

@racketblock[
(let-values ([(or-part) x]) (if or-part or-part y))
]

最终表达式的 syntax object 将带有一个 @racket['origin] 属性，其值为
@racket[(list (quote-syntax let) (quote-syntax or))]。

@history[#:changed "7.0" @elem{Included the @racket[syntax-original?]
                               property among the ones transferred to
                               @racket[new-stx].}
         #:changed "8.2.0.7" @elem{Corrected back to removing the @racket[syntax-original?]
                                   property from the set transferred to
                                   @racket[new-stx].}]}
