#lang scribble/doc 
@(require "mz.rkt" (for-label racket/future future-visualizer/trace)) 

@title[#:tag "future-logging"]{Future Performance Logging}

Racket traces 使用 logging（参见 @secref["logging"]）广泛地报告关于 futures 
如何被求值的信息。Logging 输出对调试使用 futures 的程序的性能很有用。

尽管文本日志输出可以直接查看（或通过代码中 @racket[trace-futures] 检索），
但使用 @racketmodname[future-visualizer #:indirect] 提供的图形化
profiler 工具更容易。

Future events 的日志主题是 @racket['future]。除了 string message 之外，
每个为 future 记录的事件都有一个数据值，该数据值是一个 @racket[future-event]
@tech{prefab} 结构体的实例：

@racketblock[
(struct future-event (future-id proc-id action time prim-name user-data)
  #:prefab)
]

@racket[future-id] 字段是一个用于标识 future 的精确整数，
或在 @racket[action] 是 @racket['missing] 时为 @racket[#f]。
@racket[future-id] 字段对关联记录的事件特别有用。

@racket[proc-id] 字段是一个用于标识 parallel process 的精确非负整数。
进程 0 是主 Racket 进程，除了 future thunks 之外的所有表达式都在
该进程中求值。

@racket[time] 字段是一个表示时间的 inexact 数，表示方式与
@racket[current-inexact-milliseconds] 相同。

@racket[action] 字段是一个 symbol：

@itemlist[

 @item{@racket['create]：创建了一个 future。}

 @item{@racket['complete]：future 的 thunk 成功完成，使得
       @racket[touch] 会立即为该 future 生成一个值。}

 @item{@racket['start-work] 和 @racket['end-work]：特定进程开始和停止处理
       特定 future。}

 @item{@racket['start-0-work]：类似于 @racket['start-work]，但用于因某种
       结构原因而无法在进程 0 以外的进程中开始的 future thunk（例如，thunk
       需要大量本地存储才能开始）。}

 @item{@racket['start-overflow-work]：类似于 @racket['start-work]，其中
       future thunk 的工作之前由于内部 stack overflow 而停止。}

 @item{@racket['sync]：阻塞（进程 0 除外）或发起交付（进程 0），用于
       future thunk 求值中的"不安全"操作；该操作必须在进程 0 中运行。}

 @item{@racket['block]：类似于 @racket['sync]，但用于必须延迟到 future
       被 @racket[touch] 时才能进行的求值部分，因为求值可能依赖于当前
       continuation。}

 @item{@racket['touch]（从不在进程 0 中）：类似于 @racket['sync] 或
       @racket['block]，但用于 future thunk 内的 @racket[touch] 操作。}

 @item{@racket['overflow]（从不在进程 0 中）：类似于 @racket['sync] 或
       @racket['block]，但用于进程在求值 future thunk 时遇到内部栈溢出的情况。}

 @item{@racket['result] 或 @racket['abort]：等待或处理 @racket['sync]、
       @racket['block] 或 @racket['touch]，以值或错误分别结束。}

 @item{@racket['suspend]（从不在进程 0 中）：@racket['sync]、@racket['block]
       或 @racket['touch] 阻塞的进程放弃对 future 的求值；某个其他进程可能
       稍后会接手该 future。}

 @item{@racket['touch-pause] 和 @racket['touch-resume]（仅在进程 0 中）：
       在 @racket[touch] 中等待一个 thunk 在另一个进程中被求值的 future。}

 @item{@racket['missing]：一个或多个进程的事件在可以报告之前由于内部 buffer
       限制而丢失，而 @racket[time-id] 字段报告丢失事件的时间的上限；这种
       类型的事件很少见。}

]

假设没有 @racket['missing] 事件，那么 @racket['start-work]、
@racket['start-0-work]、@racket['start-overflow-work] 总是与 @racket['end-work] 成对出现；
@racket['sync]、@racket['block] 和 @racket['touch] 总是与
@racket['result]、@racket['abort] 或 @racket['suspend] 成对出现；而
@racket['touch-pause] 总是与 @racket['touch-resume] 成对出现。

在进程 0 中，某些事件对可以嵌套在其他事件对内：
@racket['sync]、@racket['block] 或 @racket['touch] 与
@racket['result] 或 @racket['abort]；@racket['touch-pause] 与
@racket['touch-resume]；@racket['start-work] 与 @racket['end-work]。

在进程 0 中，当处理不安全操作时会生成 @racket['block]。这种类型的事件在
@racket[unsafe-op-name] 字段中包含一个 symbol，该 symbol 是操作的名称。
在所有其他情况下，此字段包含 @racket[#f]。

@racket[prim-name] 字段始终为 @racket[#f]，除非事件发生在进程 0 上，
且其 @racket[action] 是 @racket['block] 或 @racket['sync]。如果满足
这些条件，@racket[prim-name] 将包含一个 symbol，表示要求 future
与 runtime thread 同步的 Racket primitive 的名称。

@racket[user-data] 字段根据 @racket[action] 和 @racket[prim-name] 字段
的不同，可能采用多种不同的值：

@itemlist[
          
 @item{@racket['touch] 在进程 0 上：包含正在被 touch 的 future 的
       整数 ID。}
  
 @item{@racket['sync] 且 @racket[prim-name] 是 @racket['|allocate memory|]：
        所请求分配的字节大小。}
 
 @item{@racket['sync] 且 @racket[prim-name] 是 @racket['|jit_on_demand|]：
        runtime thread 正在为 future @racket[future-id] 执行 JIT 编译。
        该字段包含被 JIT 编译的函数的名称（作为 symbol）。}
 
 @item{@racket['create]：创建了一个新的 future。该字段包含新创建
       的 future 的整数 ID。}

 ]
