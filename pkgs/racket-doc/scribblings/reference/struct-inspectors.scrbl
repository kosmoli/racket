#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "inspectors"]{Structure Inspectors}

一个 @deftech{检查器} 提供对 structure 字段和 structure type 信息的访问，无需使用普通的 field accessor 和 mutator。（Inspectors 还用于控制对 module bindings 的访问；见 @secref["modprotect"]。）Inspectors 主要用于调试器。

创建 structure type 时，可以提供一个 inspector。所提供的 inspector 不会直接控制新的 structure type；相反，所提供的 inspector 的父级将控制该 type。通过使用给定 inspector 的父级，structure type 对无法访问父 inspector 的同级代码是不透明的。

@racket[current-inspector] @tech{parameter} 为新的 structure types 确定默认的 inspector 参数。可以通过 @racket[struct] 形式的 @racket[#:inspector] 选项（见 @secref["define-struct"]），或通过 @racket[make-struct-type] 的可选 @racket[inspector] 参数来提供另一个 inspector。


@defproc[(inspector? [v any/c]) boolean?]{如果 @racket[v] 是 inspector，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-inspector [inspector inspector? (current-inspector)])
         inspector?]{

返回一个新的 inspector，它是 @racket[inspector] 的子 inspector。由新的 inspector 控制的任何 structure type 也由其祖先 inspectors 控制，但不包括其他 inspectors。}


@defproc[(make-sibling-inspector [inspector inspector? (current-inspector)])
         inspector?]{

返回一个新的 inspector，它是 @racket[inspector] 同一 inspector 的子 inspector。也就是说，@racket[inspector] 和返回的 inspector 控制着互不相交的 structure types 集合。}


@defproc[(inspector-superior? [inspector inspector?]
                              [maybe-subinspector inspector?])
         boolean?]{
如果 @racket[inspector] 是 @racket[maybe-subinspector] 的祖先（且不等于 @racket[maybe-subinspector]），则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.5.0.6"]}

@defparam[current-inspector insp inspector?]{

一个 @tech{parameter}，确定新创建的 structure types 的默认 inspector。}


@defproc[(struct-info [v any/c])
         (values (or/c struct-type? #f)
                 boolean?)]{

返回两个值：

@itemize[

  @item{@racket[_struct-type]: 一个 structure type 描述符或 @racket[#f]；如果当前 inspector 对最具体的 type（@racket[v] 是该 type 的实例）有控制权，则结果是为最具体的 type 的 structure type 描述符，否则返回 @racket[#f]。}

  @item{@racket[_skipped?]: 如果第一个结果对应于 @racket[v] 的最具体的 structure type，则为 @racket[#f]，否则为 @racket[#t]。}

]}

@defproc[(struct-type-info [struct-type struct-type?])
         (values symbol?
                 exact-nonnegative-integer?
                 exact-nonnegative-integer?
                 struct-accessor-procedure?
                 struct-mutator-procedure?
                 (listof exact-nonnegative-integer?)
                 (or/c struct-type? #f)
                 boolean?)]{

返回八个值，提供关于 structure type 描述符 @racket[struct-type] 的信息，
 假设该 type 由当前 inspector 控制：

 @itemize[

  @item{@racket[_name]: structure type 的名称（作为 symbol）；}

  @item{@racket[_init-field-cnt]: 由传给 constructor procedure 的 structure type 定义的字段数量（不计算其祖先 types 创建的字段）；}

  @item{@racket[_auto-field-cnt]: 由 structure type 定义的、在 constructor procedure 中没有对应物的字段数量（不计算其祖先 types 创建的字段）；}

  @item{@racket[_accessor-proc]: 该 structure type 的 accessor procedure，类似 @racket[make-struct-type] 返回的那个；}

  @item{@racket[_mutator-proc]: 该 structure type 的 mutator procedure，类似 @racket[make-struct-type] 返回的那个；}

  @item{@racket[_immutable-k-list]: 一个不可变的、由精确非负整数组成的列表，对应于该 structure type 的 immutable fields；}

  @item{@racket[_super-type]: 该 type 的最具体的、由当前 inspector 控制的祖先的 structure type 描述符，如果没有祖先被当前 inspector 控制，则为 @racket[#f]；}

  @item{@racket[_skipped?]: 如果第七个结果是最具体的祖先 type 或该 type 没有 supertype，则为 @racket[#f]，否则为 @racket[#t]。}

]

如果 @racket[struct-type] 的 type 不被当前 inspector 控制，则会 @exnraise[exn:fail:contract]。}


@defproc[(struct-type-sealed? [struct-type struct-type?]) boolean?]{

报告 @racket[struct-type] 是否具有 @racket[prop:sealed] structure type 属性。

@history[#:added "8.0.0.7"]}


@defproc[(struct-type-authentic? [struct-type struct-type?]) boolean?]{

报告 @racket[struct-type] 是否具有 @racket[prop:authentic] structure type 属性。

@history[#:added "8.0.0.7"]}


@defproc[(struct-type-make-constructor [struct-type struct-type?]
                                       [constructor-name (or/c symbol? #f) #f])
         struct-constructor-procedure?]{

返回一个 @tech{constructor} procedure，用于为 @racket[struct-type] 的 type 创建实例。如果 @racket[constructor-name] 不是 @racket[#f]，则将其用作生成的 @tech{constructor} procedure 的名称。如果 @racket[struct-type] 的 type 不被当前 inspector 控制，则会 @exnraise[exn:fail:contract]。}

@defproc[(struct-type-make-predicate [struct-type any/c]) any]{

返回一个 @tech{predicate} procedure，用于识别 @racket[struct-type] 的 type 的实例。如果 @racket[struct-type] 的 type 不被当前 inspector 控制，则会 @exnraise[exn:fail:contract]。}



@defproc[(object-name [v any/c]) any]{

如果 @racket[v] 有名称，则返回该名称，否则返回 @racket[#f]。参数 @racket[v] 可以是任意值，但只有（某些）procedures、@tech{structures}、@tech{structure types}、@tech{structure type properties}、@tech{regexp values}、@tech{ports}、@tech{loggers} 和 @tech{prompt tags} 有名称。另见 @secref["infernames"]。

如果一个 @tech{structure} 的 type 实现了 @racket[prop:object-name] 属性，且 @racket[prop:object-name] 属性的值是整数，则该 structure 的对应字段就是该结构的名称。否则，该属性值必须是一个 procedure，将 structure 作为参数调用它，结果就是该结构的名称。
如果一个 @tech{structure} 是通过其某个字段实现的 procedure（即该 structure 的 type 的 @racket[prop:procedure] 属性值是整数），则它的名称是实现 procedure 的名称。否则，它的名称与它所实例化的 @tech{structure type} 的名称相匹配。

procedure 的名称（如果有）是一个 symbol，除非该 procedure 也是一个 type 具有 @racket[prop:object-name] 属性的 structure，在这种情况下 @racket[prop:object-name] 优先。@racket[procedure-rename] 函数创建一个具有特定名称的 procedure。

@tech{regexp value} 的名称是一个字符串或字节字符串。将该字符串或字节字符串传递给 @racket[regexp]、@racket[byte-regexp]、@racket[pregexp] 或 @racket[byte-pregexp]（取决于提取名称的 regexp 类型）会生成一个匹配相同输入的值。

port 的名称可以是任意值，但许多工具使用路径或字符串名称作为 port 的名称（例如，用于报告源代码位置）。

@tech{logger} 的名称是 symbol 或 @racket[#f]。

@tech{prompt tag} 的名称是传给 @racket[make-continuation-prompt-tag] 的可选 symbol 或 @racket[#f]。

 @history[#:changed "7.9.0.13" @elem{识别 continuation 提示标签的名称。}]
}

@defthing[prop:object-name struct-type-property?]{

一个 @tech{structure type 属性}，允许 structure types 自定义对其实例调用 @racket[object-name] 的结果。属性值可以是以下之一：

@itemize[
 @item{一个单参数 procedure @racket[_proc]：在这种情况下，procedure @racket[_proc] 接收 structure 作为参数，其结果是该 structure 的 @racket[object-name]。}

 @item{@racket[0] 到 structure type 的非自动字段数量之间的精确非负整数（含下限，不含上限，不计算 supertype 字段）：该整数标识 structure 中的一个字段，该字段必须被指定为 immutable。该字段的值用作该 structure 的 @racket[object-name]。}
]

@history[#:added "6.2"]}
