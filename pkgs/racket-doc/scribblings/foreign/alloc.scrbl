#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/alloc ffi/unsafe/define ffi/unsafe/atomic))

@title{内存分配与终结}

@defmodule[ffi/unsafe/alloc]{@racketmodname[ffi/unsafe/alloc] 库提供了
用于确保通过 foreign 函数分配的内存被可靠地释放的工具。}

@defproc[((allocator [dealloc (any/c . -> . any)] [#:merely-uninterruptible? uninterruptible? any/c #f])
          [alloc (or/c procedure? #f)])
         (or/c procedure? #f)]{

产生一个 @deftech{allocator} procedure，其行为类似于 @racket[alloc]，
但每个结果 @racket[_v]（如果非 @racket[#f]）会被赋予一个 finalizer，
该 finalizer 对 @racket[_v] 调用 @racket[dealloc]——除非调用已通过
@tech{deallocator}（由 @racket[deallocator] 产生）应用于 @racket[_v] 而被取消。
任何已注册的现有 @racket[dealloc] 都会被取消。
当且仅当 @racket[alloc] 是 @racket[#f] 时，@racket[((allocator dealloc) alloc)]
产生 @racket[#f]。

产生的 @tech{allocator} 在 @tech{atomic mode} 下调用 @racket[alloc]
（参见 @racket[call-as-atomic]），除非 @racket[uninterruptible?] 为 true，
此时使用 @racket[call-as-uninterruptible] 中的 @tech{uninterruptible mode}。
来自 @racket[alloc] 的结果在 atomic 或 uninterruptible 模式下接收和注册，
以便结果可以被可靠地释放，前提是没有引发异常。

@racket[dealloc] procedure 将在 atomic mode 被调用，并且必须遵守与提供给
@racket[register-finalizer] 的 finalizer procedure 相同的约束。
@racket[dealloc] procedure 本身不需要特别是由 @racket[deallocator] 产生的
@tech{deallocator}。如果 @tech{deallocator} 被显式调用，它不需要等同于
@racket[dealloc]。

当非主 @tech[#:doc reference.scrbl]{place} 退出时，在所有 @tech[#:doc
reference.scrbl]{custodian}-shutdown 动作之后，每个仍然通过 @tech{allocator} 或
@tech{retainer}（来自 @racket[allocator] 或 @racket[retainer]）注册的
@racket[dealloc] 都将被视为立即不可达。此时，@racket[dealloc] 函数按照其注册的
相反顺序被调用。注意，@racket[dealloc] 函数闭包中的引用不会阻止任何其他值的
@racket[dealloc] 函数运行。如果释放需要以不同于分配相反顺序进行，请使用
@tech{retainer} 来插入较早运行的新的释放动作。

@history[#:changed "7.0.0.4" @elem{为 @racket[dealloc] 添加了 atomic mode，
                                  并在非主 place 退出时调用所有剩余的 @racket[dealloc]s。}
         #:changed "7.4.0.4" @elem{当 @racket[alloc] 为 @racket[#f] 时产生 @racket[#f]。}
         #:changed "8.17.0.7" @elem{添加了 @racket[#:merely-uninterruptible?] 可选参数。}]}

@deftogether[(
@defproc[((deallocator [get-arg (list? . -> . any/c) car]
                       [#:merely-uninterruptible? uninterruptible? any/c #f])
          [dealloc procedure?])
         procedure?]
@defproc[((releaser [get-arg (list? . -> . any/c) car]) [dealloc procedure?]) 
         procedure?]
)]{

产生一个 @deftech{deallocator} procedure，其行为类似于 @racket[dealloc]。
@tech{deallocator} 在 @tech{atomic mode}（参见 @racket[call-as-atomic]）或
@tech{uninterruptible mode}（参见 @racket[call-as-uninterruptible]）下调用
@racket[dealloc]，并且对于其一个参数，它会取消最近剩下的由 @tech{allocator} 或
@tech{retainer} 注册的 deallocator。

可选的 @racket[get-arg] procedure 确定 @racket[dealloc] 的哪个参数对应于
被释放的对象；@racket[get-arg] 接收传递给 @racket[dealloc] 的参数列表，
因此默认的 @racket[car] 选择第一个参数。注意，@racket[get-arg] 只能选择
@racket[dealloc] 的位置参数中的一个，但是 @tech{deallocator} 将要求并接受与
@racket[dealloc] 相同的关键字参数（如果有的话）。

@racket[releaser] procedure 是 @racket[deallocator] 的同义词。

@history[#:changed "8.17.0.7" @elem{添加了 @racket[#:merely-uninterruptible?] 可选参数。}]}


@defproc[((retainer [release (any/c . -> . any)]
                    [get-arg (list? . -> . any/c) car]
                    [#:merely-uninterruptible? uninterruptible? any/c #f])
          [retain procedure?]) 
         procedure?]{

产生一个 @deftech{retainer} procedure，其行为类似于 @racket[retain]。
@tech{retainer} 的作用与 @racket[allocator] 产生的 @tech{allocator} 相同，
但有以下例外：

@itemlist[

 @item{@tech{retainer} 在注册 @racket[release] 时不会取消任何现有的
       @racket[release] 或 @racket[_dealloc] 注册；且}

 @item{@racket[release] 是为作为 @tech{retainer} 参数的值 @racket[_v] 注册的，
       而不是为 @tech{allocator} 的结果注册的。}

]

可选的 @racket[get-arg] procedure 确定 @tech{retainer} 的哪个参数
（即 @racket[retain] 的哪个参数）对应于被保留的对象 @racket[_v]；
@racket[get-arg] 接收传递给 @racket[retain] 的参数列表，
因此默认的 @racket[car] 选择第一个参数。注意，@racket[get-arg] 只能选择
@racket[retain] 的位置参数中的一个，但是 @tech{retainer} 将要求并接受与
@racket[retain] 相同的关键字参数（如果有的话）。

@history[#:changed "7.0.0.4" @elem{为 @racket[release] 添加了 atomic mode，
                                  并在非主 place 退出时调用所有剩余的 @racket[release]s。}
         #:changed "8.17.0.7" @elem{添加了 @racket[#:merely-uninterruptible?] 可选参数。}]}
