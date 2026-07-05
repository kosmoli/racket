#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/collect-callback))

@title{GC 回调}

@defmodule[ffi/unsafe/collect-callback]{@racketmodname[ffi/unsafe/collect-callback] 库提供了注册约束回调的函数，这些回调在 GC 之前和之后运行。}

@history[#:added "7.0.0.9"]


@defproc[(unsafe-add-collect-callbacks [pre (vectorof vector?)]
                                       [post (vectorof vector?)])
         any/c]{

注册要在 GC 之前和之后调用的 foreign function 的描述。foreign function 不能分配 GC 内存，并且它们的调用方式也不分配，这就是为什么 @var{pre_desc} 和 @var{post_desc} 是函数描述而不是 thunk。

描述是向量的向量，其中每个内部向量描述单个调用，调用按顺序执行。每个调用向量以表示要调用的 foreign function 的协议符号开头。支持以下协议：
@margin-note*{看起来任意且异想天开的受支持协议集足以允许 DrRacket 显示 GC 图标。}

@itemlist[

 @item{@racket['int->void] 对应于 @cpp{void (*)(int)}。}

 @item{@racket['ptr_ptr_ptr->void] 对应于 @cpp{void (*)(void*, void*, void*)}。}

 @item{@racket['ptr_ptr->save] 对应于 @cpp{void* (*)(void*, void*)}，但结果记录为当前"save"值。当前"save"值最初为 @cpp{NULL}。}

 @item{@racket['save!_ptr->void] 对应于 @cpp{void (*)(void*, void*)}，但仅在当前"save"值不是 @cpp{NULL} 指针时调用，并将该指针作为函数的第一个参数传递（因此描述向量中只需一个额外参数）。}

 @item{@racket['ptr_ptr_ptr_int->void] 对应于 @cpp{void (*)(void*, void*, void*, int)}。}

 @item{@racket['ptr_ptr_float->void] 对应于 @cpp{void (*)(void*, void*, float)}。}

 @item{@racket['ptr_ptr_double->void] 对应于 @cpp{void (*)(void*, void*, double)}。}

 @item{@racket['ptr_ptr_ptr_int_int_int_int_int_int_int_int_int->void] 对应于 @cpp{void (*)(void*, void*, void*, int, int, int, int, int, int, int, int, int)}。}

 @item{@racket['osapi_ptr_int->void] 对应于 @cpp{void (*)(void*, int)}，但在 Windows 上使用 stdcall 调用约定。}

 @item{@racket['osapi_ptr_ptr->void] 对应于 @cpp{void (*)(void*, void*)}，但在 Windows 上使用 stdcall 调用约定。}

 @item{@racket['osapi_ptr_int_int_int_int_ptr_int_int_long->void] 对应于 @cpp{void (*)(void*, int, int, int, int, void*, int, int, long)}，但在 Windows 上使用 stdcall 调用约定。}

]

协议符号之后，向量应包含指向 foreign function 的指针，然后是该函数的每个参数的一个元素。指针值按照 @racketmodname[ffi/unsafe] 中 @racket[_pointer] 表示相同方式表示。

结果是一个与 @racket[unsafe-remove-collect-callbacks] 一起使用的 key。如果 key 变得不可访问，则回调将自动删除（但请注意 pre-callback 将已执行而 post-callback 不会执行）。

}

@defproc[(unsafe-remove-collect-callbacks [key any/c]) void?]{

取消注册先前由调用 @racket[unsafe-add-collect-callbacks] 注册的 pre-和 post-回调，该调用返回了 @racket[v]。}
