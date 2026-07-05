#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "stx-certs" #:style 'quiet]{带污染的语法}

模块通常包含仅用于同一模块内而不通过 @racket[provide] 导出的定义。然而，模块中定义的宏的使用可能展开为对未导出标识符的引用。通常，这样的标识符绝不能从展开后的表达式中提取出来并在不同的上下文中使用，因为在不同的上下文中使用该标识符可能会破坏该宏模块的不变量。

例如，以下模块导出一个宏 @racket[go]，其展开为对 @racket[unchecked-go] 的使用：

@racketmod[
#:file "m.rkt"
racket
(provide go)

(define (unchecked-go n x) 
  (code:comment @#,t{为了避免灾难，@racket[n] 必须是一个数})
  (+ n 17))

(define-syntax (go stx)
  (syntax-case stx ()
    [(_ x)
     #'(unchecked-go 8 x)])
]

如果从 @racket[(go 'a)] 的展开中引用 @racket[unchecked-go]，则它可能被插入到一个新的表达式 @racket[(unchecked-go #f 'a)] 中，从而导致灾难。类似地，@racket[datum->syntax] 过程可用于构造对未导出标识符的引用，即使没有任何宏展开包含对该标识符的引用时也如此。

最终，模块私有绑定的保护依赖于通过设置 @racket[current-code-inspector] 参数来更改当前的 @tech{code inspector}。@margin-note*{请参见 @secref["code-inspectors+protect"]。}这是因为 code inspector 控制着通过 @racket[module->namespace] 等函数对模块内部状态的访问。当前的 code inspector 也控制对如 @racketmodname[racket/unsafe/ops] 等不安全模块的 @tech{protected} 导出的访问。

由于宏展开的结果可能被滥用来获取对受保护的绑定的访问权限，@racket[local-expand] 等宏函数也是 @tech{protected}：只有在原始 code inspector 是当前 code inspector 时声明的模块内，@racket[local-expand] 等的引用才被允许。@racket[expand] 等函数，不是用于实现宏而是用于检查宏展开的结果，它们以不同的方式受到保护：展开结果是 @deftech{带污染的}，因此无法被编译或再次展开。更准确地说，@racket[expand] 等函数接受一个可选的 inspector 参数来确定结果是否被污染，但参数的默认值是 @racket[(current-code-inspector)]。

@margin-note{在 Racket 的早期版本中，宏负责使用 @racket[syntax-protect] 保护展开。@racket[syntax-protect] 的使用不再被要求也不推荐。}
