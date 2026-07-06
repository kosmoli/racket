#lang scribble/doc
@(require "mz.rkt" (for-label racket/unit-exptime))

@(define-syntax defkeywords
   (syntax-rules (*)
     [(_ [* (form ...) as see])
      (defform* [form ...]
        "Allowed only in a " (racket as) "; see " (racket see) ".")]
     [(_ [* (form ...) see-eg])
      (defform* [form ...]
        "Allowed only in certain forms; see, for example, " (racket see-eg) ".")]
     [(_ [form as see])
      (defkeywords [* (form) as see])]
     [(_ [form see-eg])
      (defkeywords [* (form) see-eg])]
     [(_ f ...)
      (begin (defkeywords f) ...)]))

@title[#:tag "mzlib:unit" #:style 'toc]{单元}

@guideintro["units"]{units}

@deftech{单元} organize a program into separately compilable and
reusable components. The imports and exports of a unit are grouped
into a @deftech{signature}, which can include ``static'' information
(such as macros) in addition to placeholders for run-time values.
单元 with suitably matching signatures can be @deftech{linked}
together to form a larger unit, and a unit with no imports can be
@deftech{invoked} to execute its body.

@note-lib[racket/unit #:use-sources (racket/unit)]{ The
@racketmodname[racket/unit] module name can be used as a language name
with @hash-lang[]; see @secref["single-unit"].}

@local-table-of-contents[]

@; ------------------------------------------------------------------------

@section[#:tag "creatingunits"]{创建单元}

@defform/subs[
#:literals (import export prefix rename only except tag init-depend tag)
(unit
  (import tagged-sig-spec ...)
  (export tagged-sig-spec ...)
  init-depends-decl
  unit-body-expr-or-defn
  ...)

([tagged-sig-spec
  sig-spec
  (tag id sig-spec)]

 [sig-spec
  sig-id
  (prefix id sig-spec)
  (rename sig-spec (id id) ...)
  (only sig-spec id ...)
  (except sig-spec id ...)]

 [init-depends-decl
  code:blank
  (init-depend tagged-sig-id ...)]

 [tagged-sig-id
  sig-id
  (tag id sig-id)])]{

生成一个单元，封装其
@racket[unit-body-expr-or-defn] 表达式。@racket[unit]
主体中的表达式可以引用 @racket[import] 子句的
@racket[sig-spec] 绑定的标识符，主体必须为 @racket[export] 子句中
每个 @racket[sig-spec] 的标识符包含一个定义。
导出的标识符不能在定义单元或导入单元中被 @racket[set!]，
尽管初始化变量的隐式赋值可能被视为一种变更。

每个导入或导出 @racket[sig-spec] 最终引用一个
@racket[sig-id]，该标识符由 @racket[define-signature] 绑定到签名。
通过 @racket[sig-id] 导入的每个标识符的 @tech{词法信息}
以 @racket[sig-id] 的词法信息为基础；
参见 @racket[define-signature] 形式了解更多信息。

在特定的导入或导出位置，某个 @racket[sig-id]
绑定或要求的标识符集合可以通过以下几种方式调整：

@itemize[

 @item{@racket[(prefix id sig-spec)] 作为导入时，绑定与
 @racket[sig-spec] 相同，但每个绑定都加上 @racket[id] 前缀。
 作为导出时，此形式使使用 @racket[id] 前缀的定义
 满足 @racket[sig-spec] 所需的导出。}

 @item{@racket[(rename sig-spec (id id) ...)] 作为导入时，绑定
 与 @racket[sig-spec] 相同，但使用第一个 @racket[id] 作为绑定，
 而非第二个 @racket[id]（其中 @racket[sig-spec]
 本身必须隐含一个与第二个 @racket[id]
 @racket[bound-identifier=?] 的绑定）。作为导出时，
 此形式使对第一个 @racket[id] 的定义满足
 @racket[sig-spec] 中由第二个 @racket[id] 命名的导出。}

 @item{@racket[(only sig-spec id ...)] 作为导入时，绑定与
 @racket[sig-spec] 相同，但仅限于列出的 @racket[id]
（其中 @racket[sig-spec] 本身必须隐含与每个 @racket[id]
 @racket[bound-identifier=?] 的绑定）。此形式不允许用于导出。}

 @item{@racket[(except sig-spec id ...)] 作为导入时，绑定
 与 @racket[sig-spec] 相同，但排除所有列出的 @racket[id]
（其中 @racket[sig-spec] 本身必须隐含与每个 @racket[id]
 @racket[bound-identifier=?] 的绑定）。此形式不允许用于导出。}

]

正如语法所示，这些对签名的调整可以任意嵌套。

单元声明的导入按签名与实际提供的导入匹配。
也就是说，链接时向单元提供导入的顺序无关紧要；
重要的是每个提供的导入所实现的签名。
每个声明的导入必须提供一个实际的导入。同样，
当一个单元实现多个签名时，导出签名的顺序也无关紧要。

为了支持同一签名的多个导入或导出，
导入或导出可以使用 @racket[(tag
  id sig-spec)] 形式进行标记。当单元的导入声明被标记时，
链接该单元时必须为实际导入提供相同的标记（及相同的签名）。
类似地，当单元的导出声明被标记时，对该特定导出的引用
必须显式使用该标记。

语法上禁止一个单元导入两个不 @defterm{distinct} 的签名，
除非它们具有不同的标记；两个签名只有在
通过 @racket[extends] 没有共同祖先时才是 @defterm{distinct}。
同样的语法约束适用于导出签名。此外，语法上禁止一个单元
两次导入同一标识符（经过 @racket[sig-spec] 上的重命名等变换后）、
两次导出同一标识符（同样，在重命名后），
或导出已导入的标识符。

当单元被链接时，链接单元的主体按链接位置指定的顺序
执行。可选的 @racket[(init-depend tagged-sig-id ...)]
声明通过指定当前单元必须在提供相应导入的单元之后
初始化来约束允许的链接顺序。
@racket[init-depend] 声明中的每个 @racket[tagged-sig-id]
必须在 @racket[import] 子句中有对应的导入。}

@defform/subs[
#:literals (define-syntaxes define-values define-values-for-export
            open extends contracted struct)
(define-signature sig-id extension-decl
  (sig-elem ...))

([extension-decl
  code:blank
  (code:line extends sig-id)]

 [sig-elem
  id
  (define-syntaxes (id ...) expr)
  (define-values (id ...) expr)
  (define-values-for-export (id ...) expr)
  (contracted [id contract] ...)
  (open sig-spec)
  (struct id (field ...) struct-option ...)
  (sig-form-id . datum)]

 [field id
        [id #:mutable]]
 [struct-option #:mutable
                (code:line #:constructor-name constructor-id)
                (code:line #:extra-constructor-name constructor-id)
                #:omit-constructor
                #:omit-define-syntaxes
                #:omit-define-values])]{

将标识符 @racket[sig-id] 绑定到指定一组用于导入或导出的绑定的签名：

@itemize[

 @item{签名声明中的每个 @racket[id] 表示实现该签名的单元
 必须为 @racket[id] 提供变量定义。也就是说，
 @racket[id] 可在导入该签名的单元中使用，并且
 @racket[id] 必须由导出该签名的单元定义。}

 @item{签名声明中的每个 @racket[define-syntaxes] 形式
 引入一个宏，该宏可在任何导入该签名的单元中使用。
 定义中 @racket[expr] 的自由变量首先引用签名中的其他标识符，
 如果签名不包含该标识符，则引用
 @racket[define-signature] 形式的上下文。}

 @item{签名声明中的每个 @racket[define-values] 形式
 引入的代码有效地放在每个导入该签名的单元前面。
 定义中 @racket[expr] 的自由变量处理方式
 与 @racket[define-syntaxes] 相同。}

 @item{签名声明中的每个 @racket[define-values-for-export] 形式
 引入的代码有效地放在每个导出该签名的单元后面。
 定义中 @racket[expr] 的自由变量处理方式
 与 @racket[define-syntaxes] 相同。}

 @item{签名声明中的每个 @racket[contracted] 形式表示
 导出该签名的单元必须为该形式中的每个 @racket[id]
 提供变量定义。如果签名被导入，则单元内部对
 @racket[id] 的使用由相应的合约保护，
 以该单元作为负面责任方。如果签名被
 导出，则导出的值由相应的合约保护，
 以该单元作为正面责任方，但导出标识符的内部使用不受保护。
 @racket[contract] 表达式中的变量处理方式与
 @racket[define-syntaxes] 相同。}

 @item{Each @racket[(open sig-spec)] adds to the signature everything
 specified by @racket[sig-spec].}

 @item{每个 @racket[(struct id (field ...) struct-option ...)] 添加
 @racket[struct] 形式会绑定的所有标识符，
 其中额外选项 @racket[#:omit-constructor]
 省略构造函数标识符。}

 @item{每个 @racket[(sig-form-id . datum)] 以
 @racket[sig-form-id] 定义的方式扩展签名，
 @racket[sig-form-id] 必须由 @racket[define-signature-form] 绑定。
 其中一个绑定是 @racket[struct/ctc]。}

]

当 @racket[define-signature] 形式包含 @racket[extends]
子句时，定义的签名自动包含扩展签名中的所有内容。
此外，新签名的任何实现都可以用作扩展签名的实现。

签名中每个 @racket[id] 的 @tech{词法信息}
与 @racket[sig-id] 的词法信息进行比较。@racket[id]
相对于 @racket[sig-id] 的额外作用域被记录下来。
当 @racket[sig-id] 被用作引用时（例如在
@racket[unit] 的 @racket[import] 子句中），
通过从引用 @racket[sig-id] 的词法信息开始，
然后添加 @racket[id] 的额外作用域，
为引用上下文创建 @racket[id] 的变体。}

@defkeywords[[(open sig-spec) _sig-elem define-signature]
             [(define-values-for-export (id ...) expr) _sig-elem define-signature]
             [(contracted [id contract] ...) _sig-elem define-signature]
             [(only sig-spec id ...) _sig-spec unit]
             [(except sig-spec id ...) _sig-spec unit]
             [(rename sig-spec (id id) ...) _sig-spec unit]
             [(prefix id sig-spec) _sig-spec unit]
             [(import tagged-sig-spec ...) unit]
             [(export tagged-sig-spec ...) unit]
             [(link linkage-decl ...) compound-unit]
             [* [(tag id sig-spec)
                 (tag id sig-id)] unit]
             [(init-depend tagged-sig-id ...) _init-depend-decl unit]]

@defidform[extends]{

Allowed only within @racket[define-signature].}

@; ------------------------------------------------------------------------

@section[#:tag "invokingunits"]{调用单元}

@defform*[#:literals (import)
          [(invoke-unit unit-expr)
           (invoke-unit unit-expr (import tagged-sig-spec ...))]]{

调用 @racket[unit-expr] 产生的单元。对于单元的每个导入，
@racket[invoke-unit] 表达式必须在 @racket[import] 子句中包含
一个 @racket[tagged-sig-spec]；
参见 @racket[unit] 了解 @racket[tagged-sig-spec] 的语法。如果单元
没有导入，则可以省略 @racket[import] 子句。

当未提供 @racket[tagged-sig-spec] 时，@racket[unit-expr]
必须产生一个不期望任何导入的单元。要调用该单元，
所有绑定首先初始化为 @|undefined-const| 值。然后，
单元的主体定义和表达式按顺序求值；
对于定义，求值设置相应变量的值。
最后，单元中最后一个表达式的结果就是
@racket[invoke-unit] 表达式的结果。

每个提供的 @racket[tagged-sig-spec] 从周围上下文中获取绑定，
并将其转换为被调用单元的导入。单元不需要为
每个提供的 @racket[tagged-sig-spec] 声明导入，
但必须为单元的每个声明导入提供一个 @racket[tagged-sig-spec]。
对于每个提供的 @racket[tagged-sig-spec] 中的每个变量标识符，
该标识符在周围上下文中的绑定值用于被调用单元中
相应的导入。}

@defform[
#:literals (import export values)
(define-values/invoke-unit unit-expr
  (import tagged-sig-spec ...)
  (export tagged-sig-spec ...)
  maybe-results-clause)
 #:grammar
 ([maybe-results-clause (code:line)
                        (values result-id ...)
                        (values result-id ... . rest-results-id)])]{

类似于 @racket[invoke-unit]，但单元导出的值被复制到新的绑定中。

@racket[unit-expr] 产生的单元与 @racket[invoke-unit] 一样
进行链接和调用。此外，@racket[export] 子句被视为
对局部定义上下文的一种导入。也就是说，对于在
使用 @racket[export] 子句的 @racket[tagged-sig-spec] 作为导入的单元中
可用的每个绑定，会为
@racket[define-values/invoke-unit] 形式的上下文生成一个定义。

如果未提供 @racket[maybe-results-clause]，单元主体可以返回
任意数量的值，所有值都会被忽略。否则，从单元主体返回的值
按顺序绑定到给定的 @racket[result-id]。如果未提供
@racket[rest-results-id]，主体必须返回恰好与
@racket[result-id] 数量一样多的值，但如果提供了，
主体可以返回任意多的额外值，@racket[rest-results-id]
被绑定到包含额外结果的列表。

@history[#:changed "8.8.0.7" @elem{Added @racket[maybe-results-clause].}]}

@; ------------------------------------------------------------------------

@section[#:tag "compoundunits"]{链接单元与创建复合单元}

@defform/subs[
#:literals (: import export link tag)
(compound-unit
  (import link-binding ...)
  (export tagged-link-id ...)
  (link linkage-decl ...))

([link-binding
  (link-id : tagged-sig-id)]

 [tagged-link-id
  (tag id link-id)
  link-id]

 [linkage-decl
  ((link-binding ...) unit-expr tagged-link-id ...)])]{

将多个单元链接为一个新的复合单元，而不立即
调用任何被链接的单元。@racket[link] 子句中的
@racket[unit-expr] 确定在创建复合单元时要链接的单元。
@racket[unit-expr] 在 @racket[compound-unit] 形式
求值时进行求值。

@racket[import] 子句确定复合单元的导入。
在复合单元外部，这些导入的行为与普通单元相同；
在复合单元内部，它们被传播到某些被链接的单元。
@racket[export] 子句确定复合单元的导出。
同样，在复合单元外部，这些导出与普通单元的处理方式相同；
在复合单元内部，它们从被链接单元的导出中获取。
最后，@racket[link] 子句中每个声明的左侧和右侧部分
指定了复合单元的导入和导出如何传播到
被链接的单元。

导入或导出签名的各个元素在复合单元内部不可用。
相反，导入和导出在完整签名的级别上连接。
每个特定的导入或导出（即某个签名的实例，可能带有标记）
被赋予一个 @racket[link-id] 名称。具体来说，
@racket[link-id] 由 @racket[import] 子句或
@racket[link] 子句中声明的左侧部分绑定。绑定的
@racket[link-id] 在 @racket[link] 子句中声明的右侧部分
或 @racket[export] 子句中引用。

@racket[link] 声明的左侧为相应 @racket[unit-expr] 产生的单元的
每个预期导出命名。实际单元可能导出额外的签名，
并且可能导出特定签名的扩展，而不仅仅是
指定的签名。如果单元未导出指定的某个签名
（带指定的标记，如有），则在 @racket[compound-unit] 形式求值时
@exnraise[exn:fail:contract]。

@racket[link] 声明的右侧指定要提供给相应
@racket[unit-expr] 产生的单元的导入。实际单元可能导入
更少的签名，并且可能导入由指定签名扩展的签名。
如果单元导入了一个（带有特定标记的）签名，但该签名
未包含在提供的导入中，则在 @racket[compound-unit] 形式
求值时 @exnraise[exn:fail:contract]。每个作为导入提供的
@racket[link-id] 必须在 @racket[import] 子句或
@racket[link] 子句中的某个声明中绑定。

@racket[link] 子句中声明的顺序决定了被链接单元的调用顺序。
当复合单元被调用时，第一个 @racket[unit-expr] 产生的单元首先被调用，
然后是第二个，依此类推。如果 @racket[link] 子句中指定的顺序与
实际单元的 @racket[init-depend] 声明不一致，则在
@racket[compound-unit] 形式求值时
@exnraise[exn:fail:contract]。}

@; ------------------------------------------------------------------------

@section[#:tag "linkinference"]{推断链接}

@defform[
#:literals (import export)
(define-unit unit-id
  (import tagged-sig-spec ...)
  (export tagged-sig-spec ...)
  init-depends-decl
  unit-body-expr-or-defn
  ...)
]{

将 @racket[unit-id] 绑定到一个单元以及关于该单元的静态信息。

对由 @racket[define-unit] 绑定的 @racket[unit-id] 的引用进行求值
会产生一个单元，就像对由
@racket[(define _id (unit ...))] 绑定的 @racket[_id] 求值一样。然而，
@racket[unit-id] 还可以在 @racket[compound-unit/infer] 中使用。
关于 @racket[tagged-sig-spec]、@racket[init-depends-decl]
和 @racket[unit-body-expr-or-defn] 的信息，请参见 @racket[unit]。}

@defform/subs[
#:literals (import export link tag :)
(compound-unit/infer
  (import tagged-infer-link-import ...)
  (export tagged-infer-link-export ...)
  (link infer-linkage-decl ...))

([tagged-infer-link-import
  tagged-sig-id
  (link-id : tagged-sig-id)]

 [tagged-infer-link-export
  (tag id infer-link-export)
  infer-link-export]

 [infer-link-export
  link-id
  sig-id]

 [infer-linkage-decl
  ((link-binding ...) unit-id
                      tagged-link-id ...)
  unit-id])]{

类似于 @racket[compound-unit]。语法上，
@racket[compound-unit] 和 @racket[compound-unit/infer] 的区别在于
被链接单元的 @racket[_unit-expr] 被替换为
@racket[unit-id]，其中 @racket[unit-id] 由
@racket[define-unit]（或本节后面介绍的其他单元绑定形式）绑定。
此外，导入可以仅命名一个 @racket[sig-id] 而无需局部绑定
@racket[link-id]，导出可以基于 @racket[sig-id] 而非
@racket[link-id]，@racket[link] 子句中的声明可以仅仅是
一个 @racket[unit-id]，不指定导出或导入。

@racket[compound-unit/infer] 形式通过根据需要向
@racket[import] 子句添加 @racket[sig-id]、
将 @racket[export] 子句中的 @racket[sig-id] 替换为 @racket[link-id]、
以及完善 @racket[link] 子句的声明，展开为
@racket[compound-unit]。此完善基于与每个 @racket[unit-id] 关联的
静态信息。当被链接单元导出的所有签名彼此不同且与所有
导入的签名不同，并且所有导入的签名都不同时，
可以推断链接和导出。两个签名仅在
通过 @racket[extends] 没有共同祖先时才是 @defterm{distinct}。

@racket[link] 声明的长形式可用于解决歧义，
通过为单元的某些导出命名并为单元的某些导入提供特定绑定。
如果剩余部分可以推断，长形式无需命名单元的所有导出或
提供单元的所有导入。

当单元声明初始化依赖时，
@racket[compound-unit/infer] 检查 @racket[link] 声明是否
与这些依赖一致，如果不一致则报告语法错误。

与 @racket[compound-unit] 一样，@racket[compound-unit/infer] 形式
产生一个 (compound) 单元，而不静态绑定关于结果单元的导入和导出的信息。
也就是说，@racket[compound-unit/infer] 消费静态信息，但
不生成静态信息。另外两种形式
@racket[define-compound-unit] 和
@racket[define-compound-unit/infer] 生成静态信息
（前者不消费静态信息）。

@history[#:changed "6.1.1.8" @elem{Added static checking of the @racket[link]
                                   clause with respect to declared
                                   initialization dependencies.}]}


@defform[
#:literals (import export link)
(define-compound-unit id
  (import link-binding ...)
  (export tagged-link-id ...)
  (link linkage-decl ...))
]{

类似于 @racket[compound-unit]，但像 @racket[define-unit] 一样
绑定关于复合单元的静态信息，包括从被链接单元传播
初始化依赖信息（关于剩余导入）。}


@defform[
#:literals (import export link)
(define-compound-unit/infer id
  (import link-binding ...)
  (export tagged-infer-link-export ...)
  (link infer-linkage-decl ...))
]{

类似于 @racket[compound-unit/infer]，但像
@racket[define-compound-unit] 一样绑定关于复合单元的静态信息。}

@defform[
#:literals (import export)
(define-unit-binding unit-id
  unit-expr
  (import tagged-sig-spec ...+)
  (export tagged-sig-spec ...+)
  init-depends-decl)
]{

类似于 @racket[define-unit]，但单元实现由
@racket[unit-expr] 产生的现有单元确定。
@racket[unit-expr] 产生的单元的导入和导出必须与
声明的导入和导出一致，否则在
@racket[define-unit-binding] 形式求值时
@exnraise[exn:fail:contract]。}

@defform/subs[
#:literals (link)
(invoke-unit/infer unit-spec)
[(unit-spec unit-id (link link-unit-id ...))]]{

类似于 @racket[invoke-unit]，但使用与 @racket[unit-id] 关联的
静态信息来推断必须从当前上下文组装哪些导入。
如果给出了包含多个 @racket[link-unit-id] 的 link 形式，
则首先通过 @racket[define-compound-unit/infer] 链接这些单元。

当从当前上下文组装导入时，@racket[unit-id] 的
@tech{词法信息} 用于构造单元导入签名的词法信息
（即通常从签名引用派生的词法信息）。
参见 @racket[define-signature] 了解更多信息。}

@defform*[
 #:literals (export link values)
 [(define-values/invoke-unit/infer
    unit-spec
    maybe-exports
    maybe-results-clause)
  (define-values/invoke-unit/infer
    (export tagged-sig-spec ...)
    unit-spec)]
 #:grammar
 ([unit-spec unit-id (link link-unit-id ...)]
  [maybe-exports code:blank (export tagged-sig-spec ...)]
  [maybe-results-clause (code:line)
                        (values result-id ...)
                        (values result-id ... . rest-results-id)])]{

类似于 @racket[define-values/invoke-unit]，但使用与
@racket[unit-id] 关联的静态信息来推断必须从当前上下文组装
哪些导入，以及如果没有 @racket[export] 子句，
哪些导出应由定义绑定。如果给出了包含多个
@racket[link-unit-id] 的 link 形式，则首先通过
@racket[define-compound-unit/infer] 链接这些单元。

与 @racket[invoke-unit/infer] 类似，@racket[unit-id] 的
@tech{词法信息} 用于构造单元推断导入和推断导出的签名的
词法信息（即通常从签名引用派生的词法信息）。
参见 @racket[define-signature] 了解更多信息。

如果提供了 @racket[maybe-results-clause]，
单元主体返回的值以与 @racket[define-values/invoke-unit] 相同的方式绑定。

为了向后兼容，允许 @racket[export] 子句出现在
@racket[unit-spec] 之前（在这种情况下不能提供
@racket[maybe-results-clause]）。新程序应首先提供 @racket[unit-spec]
（这与 @racket[define-values/invoke-unit] 一致）。

@history[
 #:changed "8.8.0.7" @elem{Allowed @racket[unit-spec] to appear before
   @racket[maybe-exports] for consistency with @racket[define-values/invoke-unit]
   and added @racket[maybe-results-clause].}]}

@; ------------------------------------------------------------------------

@section{从上下文生成单元}

@defform[
(unit-from-context tagged-sig-spec)
]{

创建一个单元，使用外围环境中的绑定来实现接口。
生成的单元本质上等同于

@racketblock[
(unit
  (import)
  (export tagged-sig-spec)
  (define _id _expr) ...)
]

对于每个为满足导出而必须定义的 @racket[_id]，
每个相应的 @racket[_expr] 产生 @racket[_id] 在
@racket[unit-from-context] 表达式环境中的值。（然而，
不能按上述方式编写单元，因为单元内部的每个 @racket[_id] 定义
会遮蔽 @racket[unit] 形式外部的绑定。）

参见 @racket[unit] 了解 @racket[tagged-sig-spec] 的语法。}

@defform[
(define-unit-from-context id tagged-sig-spec)
]{

类似于 @racket[unit-from-context]，单元从外围环境构造，
类似于 @racket[define-unit]，@racket[id] 被绑定到
稍后用于推断的静态信息。}

@; ------------------------------------------------------------------------

@section{结构匹配}

@defform[
#:literals (import export)
(unit/new-import-export
  (import tagged-sig-spec ...)
  (export tagged-sig-spec ...)
  init-depends-decl
  ((tagged-sig-spec ...) unit-expr tagged-sig-spec))
]{

类似于 @racket[unit]，但单元的主体由
@racket[unit-expr] 产生的现有单元确定。结果是一个
实现为 @racket[unit-expr] 的单元，但其导入、
导出和初始化依赖如
@racket[unit/new-import-export] 形式中所示（而非
@racket[unit-expr] 产生的单元中所示）。

@racket[unit/new-import-export] 形式的最后一个子句
确定新旧导入和导出之间的连接。
这种连接类似于 @racket[compound-unit] 传播导入和导出的方式；
区别在于 @racket[import] 与 link 子句右侧之间的连接
基于签名中元素的名称，而非签名的名称。
也就是说，link 子句右侧的 @racket[tagged-sig-spec]
不需要作为 @racket[tagged-sig-spec] 出现在 @racket[import] 子句中，
但链接 @racket[tagged-sig-spec] 隐含的每个绑定必须由
@racket[import] 子句中的某个 @racket[tagged-sig-spec] 隐含。
类似地，@racket[export] @racket[tagged-sig-spec] 隐含的
每个绑定必须由链接子句中某个左侧
@racket[tagged-sig-spec] 隐含。}

@defform[
#:literals (import export)
(define-unit/new-import-export unit-id
  (import tagged-sig-spec ...)
  (export tagged-sig-spec ...)
  init-depends-decl
  ((tagged-sig-spec ...) unit-expr tagged-sig-spec))
]{

类似于 @racket[unit/new-import-export]，但像
@racket[define-unit] 一样将静态信息绑定到 @racket[unit-id]。}

@defform[
#:literals (import export)
(unit/s
  (import tagged-sig-spec ...)
  (export tagged-sig-spec ...)
  init-depends-decl
  unit-id)]{

类似于 @racket[unit/new-import-export]，但链接子句是推断的，
因此 @racket[unit-id] 必须具有适当的静态信息。}
@defform[
#:literals (import export)
(define-unit/s name-id
  (import tagged-sig-spec ...)
  (export tagged-sig-spec ...)
  init-depends-decl
  unit-id)]{

类似于 @racket[unit/s]，但像 @racket[define-unit] 一样
将静态信息绑定到 @racket[name-id]。}

@; ------------------------------------------------------------------------

@section[#:tag "define-sig-form"]{扩展签名的语法}

@defform*[
[(define-signature-form sig-form-id expr)
 (define-signature-form (sig-form-id id) body ...+)
 (define-signature-form (sig-form-id id intro-id) body ...+)]
]{

绑定 @racket[sig-form-id] 以便在 @racket[define-signature] 形式中使用。

在第一种形式中，@racket[expr] 的结果必须是一个接受一个参数的
变换器过程。在第二种形式中，@racket[sig-form-id] 被绑定到一个
变换器过程，其参数是 @racket[id]，主体是 @racket[body]。
第三种形式类似于第二种，但 @racket[intro-id] 被绑定到一个过程，
该过程类似于用于签名形式展开的
@racket[syntax-local-introduce]。

变换器过程的结果必须是一个语法对象列表，
这些对象会替换 @racket[define-signature] 展开中
@racket[sig-form-id] 的使用。（结果是列表，以便
变换器可以产生多个声明；
@racket[define-signature] 没有拼接用的 @racket[begin] 形式。）

@history[#:changed "8.1.0.7" @elem{Added support for the form with a transformer
                                   @racket[expr].}]}

@defform/subs[
(struct/ctc id ([field contract-expr] ...) struct-option ...)

([field id
        [id #:mutable]]
 [struct-option #:mutable
                #:omit-constructor
                #:omit-define-syntaxes
                #:omit-define-values])]{

与 @racket[define-signature] 一起使用。
@racket[struct/ctc] 形式的工作方式类似于 @racket[struct]，
但构造函数、谓词、字段访问器和字段修改器都有适当的合约。}

@; ------------------------------------------------------------------------

@section{单元工具}

@defproc[(unit? [v any/c]) boolean?]{

如果 @racket[v] 是单元则返回 @racket[#t]，否则返回 @racket[#f]。}


@defform[(provide-signature-elements sig-spec ...)]{

展开为 @racket[sig-spec] 隐含的所有标识符的 @racket[provide]。
参见 @racket[unit] 了解 @racket[sig-spec] 的语法。}

@; ------------------------------------------------------------------------

@section[#:tag "unitcontracts"]{单元合约}

@defform/subs[#:literals (import export values init-depend)
              (unit/c
	        (import sig-spec-block ...)
	        (export sig-spec-block ...)
		init-depends-decl
		optional-body-ctc)
              ([sig-spec-block (tagged-sig-spec [id contract] ...)
                               tagged-sig-spec]
	       [init-depends-decl
	         code:blank
		 (init-depend tagged-sig-id ...)]
	       [optional-body-ctc
	         code:blank
		 contract
		 (values contract ...)])]{

@deftech{单元合约} 包装一个单元并检查其导入和
导出的标识符，确保它们匹配适当的合约。
这允许程序员向单个单元值添加合约检查，
而无需向导入和导出的签名添加合约。

单元值必须导入单元合约中列出的导入签名的子集，
并导出列出的导出签名的超集。此外，单元值必须声明
初始化依赖，这些依赖是单元合约中指定的依赖的子集。
未在给定签名中列出的任何标识符保持不变。给定
@racket[contract] 表达式中使用的变量首先引用任何列出签名中的
其他变量，然后引用 @racket[unit/c] 表达式的上下文。
如果指定了主体合约，则调用单元值的结果用给定合约包装，
否则值按原样返回。

@history[
 #:changed "8.8.0.7" @elem{Changed @racket[sig-spec-block] to allow arbitrary
   @racket[tagged-sig-spec]s instead of only allowing @racket[tagged-sig-id]s.
   Made bindings from @emph{all} signatures visible in the scope of each
   @racket[contract] expression instead of only the bindings from the same
   signature. Additionally, contracts on signature bindings are enforced
   within @racket[contract] expressions.}]}

@defform/subs[#:literals (import export values)
              (define-unit/contract unit-id
                (import sig-spec-block ...)
                (export sig-spec-block ...)
                init-depends-decl
		optional-body-ctc
                unit-body-expr-or-defn
                ...)
              ([sig-spec-block (tagged-sig-spec [id contract] ...)
                               tagged-sig-spec]
	       [optional-body-ctc
	         code:blank
		 (code:line #:invoke/contract contract)
		 (code:line #:invoke/contract (values contract ...))])]{
@racket[define-unit/contract] 形式定义一个与链接推断兼容的单元，
其导入和导出通过单元合约进行合约化。
单元名称用于合约的正面责任方。

@history[
 #:changed "8.8.0.7" @elem{Made bindings from @emph{all} signatures visible in
   the scope of each @racket[contract] expression instead of only the bindings
   from the same signature. Additionally, contracts on signature bindings are
   enforced within @racket[contract] expressions.}]}


@; ------------------------------------------------------------------------

@section[#:tag "single-unit"]{单单元模块}

作为与 @hash-lang[] 一起使用的语言名，
@racketmodname[racket/unit] 提供 @racketmodname[racket/unit] 和
@racketmodname[racket/base] 的所有绑定，
除了 @racket[%#module-begin]，并且 @racketmodname[racket/unit] 模块主体
被视为单元主体。 The body must match the following @racket[_module-body]
grammar:

@racketgrammar*[
#:literals (import export require begin)
[module-body (code:line
              require-decl ...
              (import tagged-sig-expr ...)
              (export tagged-sig-expr ...)
              init-depends-decl
              unit-body-expr-or-defn
              ...)]
[require-decl (require require-spec ...)
              (begin require-decl ...)
              derived-require-form]]

在任意数量的 @racket[_require-decl] 之后，模块的内容
与 @racket[unit] 主体相同，可以访问 @racketmodname[racket/base]。

生成的单元导出为 @racket[_base]@racketidfont["@"],
其中 @racket[_base] 从外围模块的名称派生
（即其符号名，或去掉目录和文件后缀的路径）。
如果模块名以 @racketidfont{-unit} 结尾，则
@racket[_base] 对应于 @racketidfont{-unit} 之前的模块名。
否则，模块名用作 @racket[_base]。

@; ------------------------------------------------------------------------

@section{单签名模块}

@defmodulelang[racket/signature]{@racketmodname[racket/signature] 语言以与
@racketmodname[racket/unit] 将 @seclink["single-unit"]{模块主体视为单元主体}
相同的方式将模块主体视为单元签名：
它提供 @racketmodname[racket/signature] 和
@racketmodname[racket/base] 的所有绑定，除了 @racket[%#module-begin]。}

The body must match the following @racket[_module-body] grammar:

@racketgrammar*[
#:literals (require)
[module-body (code:line (require require-spec ...) ... sig-elem ...)]
]

参见 @racket[define-signature] 了解 @racket[_sig-elem] 的语法。
与 @racketmodname[racket/unit] 模块的主体不同，
@racketmodname[racket/signature] 模块中的 @racket[require]
必须是 @racket[require] 的字面使用。

生成的签名导出为 @racket[_base]@racketidfont["^"],
其中 @racket[_base] 从外围模块的名称派生
（即其符号名，或去掉目录和文件后缀的路径）。
如果模块名以 @racketidfont{-sig} 结尾，则
@racket[_base] 对应于 @racketidfont{-sig} 之前的模块名。
否则，模块名用作 @racket[_base]。

作为 @racket[_sig-elem] 的 @racket[struct] 形式与
@racket[define-struct] 引入的定义一致，而非
@racket[struct] 引入的定义。
(That behavior was originally a bug, but it is preserved for compatibility.)

@; ----------------------------------------------------------------------

@section{变换器辅助工具}

@defmodule[racket/unit-exptime #:use-sources (racket/unit-exptime)]

@racketmodname[racket/unit-exptime] 库提供了
供宏变换器使用的过程。特别是，该库通常
使用 @racket[for-syntax] 导入到用 @racket[define-syntax] 定义宏的模块中。

@defproc[(unit-static-signatures [unit-identifier identifier?]
                                 [err-syntax syntax?])
         (values (list/c (cons/c (or/c symbol? #f)
                                 identifier?))
                 (list/c (cons/c (or/c symbol? #f)
                                 identifier?)))]{

如果 @racket[unit-identifier] 通过 @racket[define-unit]
（或其他类似形式）绑定到静态单元信息，则结果是两个
值。第一个值用于单元的导入，第二个用于单元的导出。
每个结果值是一个列表，其中每个列表元素将符号或
@racket[#f] 与标识符配对。符号或 @racket[#f] 指示导入或
导出的标记（其中 @racket[#f] 表示无标记），标识符指示
相应签名的绑定。

如果 @racket[unit-identifier] 未绑定到静态单元信息，
则 @exnraise[exn:fail:syntax]。在这种情况下，给定的
@racket[err-syntax] 参数用作错误的来源，
@racket[unit-identifier] 用作详细来源位置。}


@defproc[(signature-members [sig-identifier identifier?]
                            [err-syntax syntax?])
         (values (or/c identifier? #f)
                 (listof identifier?)
                 (listof identifier?)
                 (listof identifier?))]{

如果 @racket[sig-identifier] 通过 @racket[define-signature]
（或其他类似形式）绑定到静态单元信息，则结果是四个值：

@itemize[

  @item{一个标识符或 @racket[#f]，指示被
        @racket[sig-identifier] 绑定扩展的签名（如有）；}

  @item{一个标识符列表，表示签名提供/要求的变量；}

  @item{一个标识符列表，表示签名中的变量定义
        （即在导入时提供，但不由实现签名的单元定义的
        变量绑定）；以及}

  @item{一个标识符列表，表示签名中的语法定义。}

]

每个结果标识符都被赋予基于 @racket[sig-identifier] 的词法信息，
因此这些名称适合在 @racket[sig-identifier] 的上下文中
引用或绑定。参见 @racket[define-signature] 了解更多信息。

如果 @racket[sig-identifier] 未绑定到签名，则
@exnraise[exn:fail:syntax]。在这种情况下，给定的
@racket[err-syntax] 参数用作错误的来源，
@racket[sig-identifier] 用作详细来源位置。}


@defproc[(unit-static-init-dependencies [unit-identifier identifier?]
                                        [err-syntax syntax?])
         (list/c (cons/c (or/c symbol? #f)
                         identifier?))]{

如果 @racket[unit-identifier] 通过 @racket[define-unit]
（或其他类似形式）绑定到静态单元信息，则结果是一个对的列表。
每个对组合了一个标记（或无标记的 @racket[#f]）和一个签名名，
指示单元对指定导入的初始化依赖
（即同一标记和签名包含在 @racket[unit-static-signatures] 的第一个结果中）。

如果 @racket[unit-identifier] 未绑定到静态单元信息，
则 @exnraise[exn:fail:syntax]。在这种情况下，给定的
@racket[err-syntax] 参数用作错误的来源，
@racket[unit-identifier] 用作详细来源位置。

@history[#:added "6.1.1.8"]}
