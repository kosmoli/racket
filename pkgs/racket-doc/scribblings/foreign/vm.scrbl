#lang scribble/doc
@(require "utils.rkt" (for-label ffi/unsafe/vm
                                 racket/linklet))

@title[#:tag "vm"]{Virtual Machine 原语}

@defmodule[ffi/unsafe/vm]{@racketmodname[ffi/unsafe/vm] 库提供了对底层 virtual machine 功能的访问，该 virtual machine 用于实现 Racket。}

@history[#:added "7.6.0.7"]

@defproc[(vm-primitive [name symbol?]) any/c]{

访问运行中 Racket virtual machine 层面的 primitive 值，如果 @racket[name] 不是 primitive 的名称则返回 @racket[#f]。

Virtual-machine primitive 是那些可以在 @tech[#:doc reference.scrbl]{linklet} 体内引用的 primitive。具体的 primitive 集合取决于 virtual machine。许多 @racketmodname[racket/base] 层面甚至是 @racket['#%kernel] 层面的 "primitive" 并不是 virtual-machine 层面的 primitive。例如，如果 @racket['eval] 作为 primitive 可用，它并非 @racketmodname[racket/base] 中的 @racket[eval]。

一般来说，primitive 是不安全的，只有在充分了解 Racket 实现的情况下才能使用。以下是一些针对当前可用 virtual machine 的建议：

@itemlist[

 @item{@racket[(system-type 'vm)] 为 @racket['racket] --- 该 virtual machine 中的 primitive 大多与 @racketmodname[racket/base] 和 @racketmodname[racket/unsafe/ops] 等库中可用的 primitive 相同。因此，使用 @racket[vm-primitive] 访问 virtual machine primitive 通常没有什么用处。}

 @item{@racket[(system-type 'vm)] 为 @racket['chez-scheme] --- 该 virtual machine 中的 primitive 是 Chez Scheme 的 primitive，除了被 Racket 兼容性层替换的部分。@racket['eval] primitive 是 Chez Scheme 的 @racketidfont{eval}。

       注意不要直接调用内部使用 Chez Scheme parameter 或 @racketidfont{dynamic-wind} 的 Chez Scheme primitive。特别注意，@racketidfont{eval} 就是这样的一类 primitive。问题在于 Chez Scheme 的 @racketidfont{dynamic-wind} 不会自动与 Racket 的 continuation 或 thread 协作。要调用这类 primitive，请使用 @racketidfont{call-with-system-wind} primitive，它接受一个无参数的 procedure，在桥接 Chez Scheme 的 @racketidfont{dynamic-wind} 与 Racket continuation 和 thread 的上下文中运行。例如，

       @racketblock[
         (define primitive-eval (vm-primitive 'eval))
         (define call-with-system-wind (vm-primitive 'call-with-system-wind))
         (define (vm-eval s)
           (call-with-system-wind
            (lambda ()
             (primitive-eval s))))
       ]

       这就是在 Chez Scheme 上实现 @racket[vm-struct] 的方式。

       Symbol、number、boolean、pair、vector、box、string、byte string（即 bytevector）和 structure（即 record）在 Racket 与 Chez Scheme 之间是可互换的。Chez Scheme procedure 是 Racket procedure，但并非所有 Racket procedure 都是 Chez Scheme procedure。要在 Chez Scheme 中调用 Racket procedure，请使用在 Chez Scheme 环境中定义的 @racketidfont{#%app} form，该环境在承载 Racket 时定义。

       注意，你可以通过 Chez Scheme 的 @racketidfont{$primitive} form 访问 Chez Scheme primitive，包括那些被 Racket primitive 遮蔽的 primitive。例如，@racket[(vm-eval '($primitive call-with-current-continuation))] 访问的是 Chez Scheme 的 @racketidfont{call-with-current-continuation} primitive，而非 Racket 的替代品（该替代品在 Racket continuation 和 thread 中工作）。}

]}

@defproc[(vm-eval [s-expr any/c]) any/c]{

使用最原始的求值器来求值 @racket[s-expr]：

@itemlist[

 @item{@racket[(system-type 'vm)] 为 @racket['racket] --- 使用 @racket[compile-linklet] 和 @racket[instantiate-linklet]。}

 @item{@racket[(system-type 'vm)] 为 @racket['chez-scheme] --- 使用 Chez Scheme 的 @racketidfont{eval}。}

]

关于 virtual-machine primitive 如何与 Racket 交互，请参见 @racket[vm-primitive]。}
