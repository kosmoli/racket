#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "protect-out"]{Protected Exports}

有时，module 需要向与导出 module 处于相同信任级别的其他 module 导出绑定，同时阻止不受信任的 module 访问。此类导出应在 @racket[provide] 中使用 @racket[protect-out] 形式。例如，@racketmodname[ffi/unsafe] 以这种方式将其所有不安全绑定导出为 @deftech{protected}。

信任级别通过 @tech{code inspectors} 实现（见 @secref["code-inspectors+protect"]）。只有使用与导出 module 同等强度的 code inspector 加载的 module 才能使用导出 module 的受保护绑定。像 @racket[dynamic-require] 这样的操作根据 @racket[current-code-inspector] 确定的当前 code inspector 来授予访问权限。

当 module 重新导出受保护绑定时，不需要再次使用 @racket[protect-out]。访问权限始终由最初定义受保护绑定的 module 的 code inspector 决定。在 module 内使用受保护绑定时，请注意要么从 module 使用 @racket[protect-out] 提供新绑定，要么确保没有提供暴露本应受保护功能的绑定。
