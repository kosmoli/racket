#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "module-provide"]{Exports: @racket[provide]}

默认情况下，模块的所有定义对该模块都是私有的。@racket[provide] form 指定要在 @racket[require] 该模块的位置可用的定义。

@specform[(provide provide-spec ...)]{}

@racket[provide] form 只能出现在模块级别（即 @racket[module] 的直接体中）。在单个 @racket[provide] 中指定多个 @racket[_provide-spec] 与分别使用多个 @racket[provide]、每个带单个 @racket[_provide-spec] 完全相同。

在模块的所有 @racket[provide] 中，每个标识符最多只能导出一次。更准确地说，每个导出的外部名称必须不同；同一个内部绑定可以用不同的外部名称多次导出。

@racket[_provide-spec] 允许的形状递归定义如下：

@;------------------------------------------------------------------------

@specspecsubform[identifier]{

@racket[_provide-spec] 的最简单形式，指定模块内的一个绑定作为导出。该绑定可以来自局部定义或导入。

}

@;------------------------------------------------------------------------

@specspecsubform[#:literals(rename-out)
                 (rename-out [orig-id export-id] ...)]{

类似于直接指定标识符，但导出的绑定 @racket[orig-id] 被赋予不同的名称 @racket[export-id]，供导入模块使用。
}

@;------------------------------------------------------------------------

@specspecsubform[#:literals(struct-out)
                 (struct-out struct-id)]{

@racket[struct-out] 导出由 @racket[(struct struct-id ...)] 创建的绑定。

@guideother{关于 @racket[define-struct] 的信息请参见 @secref["define-struct"]。}
}

@;------------------------------------------------------------------------

@specspecsubform[#:literals(all-defined-out)
                 (all-defined-out)]{

@racket[all-defined-out] 简写导出模块内定义的所有绑定（而不是导入的）。

通常不鼓励使用 @racket[all-defined-out] 简写，因为这使得模块的实际导出不够清楚，也因为 Racket 程序员容易养成一种习惯 — 认为可以自由地向模块添加定义而不会影响其公共接口（在使用 @racket[all-defined-out] 时情况并非如此）。
}

@;------------------------------------------------------------------------

@specspecsubform[#:literals(all-from-out)
                 (all-from-out module-path)]{

@racket[all-from-out] 简写导出模块中所有使用基于 @racket[module-path] 的 @racket[_require-spec] 导入的绑定。

尽管不同的 @racket[module-path] 可能引用同一个基于文件的模块，但使用 @racket[all-from-out] 重新导出基于具体的 @racket[module-path] 引用，而非实际引用的模块。
}

@;------------------------------------------------------------------------

@specspecsubform[#:literals(except-out)
                 (except-out provide-spec ...)]{

类似于 @racket[provide-spec]，但省略指定的每个 @racket[id] 的导出，其中 @racket[id] 是要省略的导出的外部名称。
}

@;------------------------------------------------------------------------

@specspecsubform[#:literals(prefix-out)
                 (prefix-out prefix-id provide-spec)]{

类似于 @racket[provide-spec]，但在每个导出绑定的外部名称前添加 @racket[prefix-id]。
}
