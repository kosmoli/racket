#lang scribble/manual
@(require "mz.rkt"
          scribble/bnf)

@title[#:tag "memory" #:style 'toc]{内存管理}

@local-table-of-contents[]

@section[#:tag "weakbox"]{弱盒子（Weak Boxes）}

一个 @deftech{弱盒子} 类似于普通盒子（参见 @secref["boxes"]），但当垃圾回收器（参见 @secref["gc-model"]）能够证明弱盒子的内容值仅通过弱引用可达时，弱盒子的内容将被替换为 @racket[#f]。一个 @defterm{@tech{weak reference}} 是指通过弱盒子的引用，通过弱哈希表中的键引用（参见 @secref["hashtables"]）、通过 @tech{ephemeron} 的值（该值可被替换为 @racket[#f]）（参见 @secref["ephemerons"]），或通过 custodian（参见 @secref["custodians"]）的引用。

@defproc[(make-weak-box [v any/c]) weak-box?]{

返回一个初始包含 @racket[v] 的新弱盒子。}


@defproc[(weak-box-value [weak-box weak-box?] [gced-v any/c #f]) any/c]{

返回 @racket[weak-box] 中包含的值。若垃圾回收器已证明 @racket[weak-box] 之前的内容值仅通过弱引用可达，则返回 @racket[gced-v]（默认为 @racket[#f]）。}

@defproc[(weak-box? [v any/c]) boolean?]{

若 @racket[v] 是弱盒子则返回 @racket[#t]，否则返回 @racket[#f]。}

@;------------------------------------------------------------------------
@section[#:tag "ephemerons"]{Ephemerons}

一个 @deftech{ephemeron} @cite{Hayes97} 是 @tech{weak box}（参见 @secref["weakbox"]）的泛化。与仅包含一个值不同，ephemeron 持有两个值：一个被视为 ephemeron 的值，另一个则是 ephemeron 的键。与弱盒子中的值一样，ephemeron 中的值可能被替换为 @racket[#f]，但当 @emph{键} 不再可达时（除通过弱引用外），而不是值不再可达时。

只要 ephemeron 的值被保留，该引用就被视为非弱引用。然而，通过值对键的引用被特殊处理，即该引用不一定计入键的可达性。一个 @tech{weak box} 可以看作 ephemeron 的特例，即键和值相同。

ephemeron 的一个特别常见的用途是将它们与弱哈希表（参见 @secref["hashtables"]）组合，以生成即使在值引用键时内存管理器也能回收键值对的映射；参见 @racket[make-ephemeron-hash]。相关用途是只要任何值为可达的 @tech{impersonator} 存在，就保留对该值的引用；参见 @racket[impersonator-ephemeron]。

更精确地，
@itemize[

 @item{当自动内存管理器能够证明 ephemeron 的键或 ephemeron 本身仅通过弱引用可达时（参见 @secref["weakbox"]），ephemeron 中的值被替换为 @racket[#f]；且}

 @item{从 ephemeron 的值出发不可达的任何内容都不计入 ephemeron 键的可达性（无论是同一个 ephemeron 还是另一个），除非相同值通过非弱引用可达，或该值的 ephemeron 键通过非弱引用可达（有关弱引用的信息参见 @secref["weakbox"]）。}

]


@defproc[(make-ephemeron [key any/c] [v any/c]) ephemeron?]{

返回一个键为 @racket[key]、初始值为 @racket[v] 的新 @tech{ephemeron}。}


@defproc[(ephemeron-value [ephemeron ephemeron?] [gced-v any/c #f] [retain-v any/c #f]) any/c]{

返回 @racket[ephemeron] 中包含的值。若垃圾回收器已证明 @racket[ephemeron] 的键仅弱可达，则结果为 @racket[gced-v]（默认为 @racket[#f]）。

@racket[retain-v] 参数被保留为可达，直到提取出 ephemeron 的值。例如，当 @racket[_ephemeron] 是通过弱 @racket[eq?] 基映射从 @racket[_key] 获得，且 @racket[_ephemeron] 以 @racket[_key] 为键创建时，此参数很有用；在这种情况下，将 @racket[_key] 作为 @racket[retain-v] 提供可确保 @racket[_ephemeron] 保留其值足够长时间以便被提取，即使 @racket[_key] 在其他方面不可达。

@history[#:changed "7.1.0.10" @elem{添加了 @racket[retain-v] 参数。}]}


@defproc[(ephemeron? [v any/c]) boolean?]{

若 @racket[v] 是 @tech{ephemeron} 则返回 @racket[#t]，否则返回 @racket[#f]。}

@;------------------------------------------------------------------------
@section[#:tag "willexecutor"]{意愿与执行器（Wills and Executors）}

一个 @deftech{will executor} 管理一组值和一组关联的 @deftech{will} 过程
（亦称 @deftech{finalizers}）。每个值的 @tech{will} 过程在该值被（垃圾回收器）证明为不可达时即可被执行，除非通过弱引用（参见 @secref["weakbox"]）或作为其他 will executor 的注册者可达。@tech{will} 对触发与不可达值关联的数据的操作很有用，例如当包含端口的对象不再使用时关闭嵌入在对象中的端口。

调用 @racket[will-execute] 或 @racket[will-try-execute] 过程会执行指定 will executor 中已就绪的 will。will executor 也是一个 @tech{synchronizable event}，因此可使用 @racket[sync] 或 @racket[sync/timeout] 来检测 will executor 何时有就绪的 will。will 不会自动执行，因为某些程序需要控制以避免竞争条件。然而，程序可以创建一个线程，其唯一任务是为特定执行器执行 will。

若一个值在单个或多个 executor 中注册了多个 will，则 will 按注册的反向顺序被就绪。由于使 will 就绪会使值再次可达，因此必须执行 will 并再次证明值仅通过弱引用可达，才能就绪或执行另一个 will。然而，不同不可达值的 will 会同时就绪，无论这些值是否彼此可达。

will executor 的注册者被强引用保存，直到相应的 will 过程被执行。因此，若弱盒子（参见 @secref["weakbox"]）的内容值注册了 will executor，弱盒子的内容不会更改为 @racket[#f]，直到为该值执行了所有 will 且值再次被证明仅通过弱引用可达。

will executor 可用作 @tech{synchronizable event}（参见 @secref["sync"]）。
当 @racket[will-execute] 不会阻塞时，will executor 就是 @tech{ready for synchronization}，即 @resultItself{will executor}。


以下示例展示了如何在不需要同步时运行清理操作。它只是作为另一个线程中注册的执行器就绪时运行它们。
@mz-examples[(define an-executor (make-will-executor))
             (eval:alts (void
                         (thread
                          (λ ()
                            (let loop ()
                              (will-execute an-executor)
                              (loop)))))
                        (void))
             (define (executor-proc v) (printf "a-box is now garbage\n"))
             (define a-box-to-track (box #f))
             (will-register an-executor a-box-to-track executor-proc)
             (eval:alts (collect-garbage) (void))
             (set! a-box-to-track #f)
             (eval:alts (collect-garbage) (executor-proc 'random-junk))]


@defproc[(make-will-executor) will-executor?]{

返回一个没有管理值的新 will executor。}


@defproc[(will-executor? [v any/c]) boolean?]{

若 @racket[v] 是 will executor 则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(will-register [executor will-executor?] [v any/c] [proc (any/c . -> . any)])
         void?]{

将值 @racket[v] 注册到 will executor @racket[executor] 中的 will 过程 @racket[proc]。当 @racket[v] 被证明为不可达时，过程 @racket[proc] 即可通过 @racket[will-execute] 或 @racket[will-try-execute] 以 @racket[v] 作为其参数被调用。@racket[proc] 参数被强引用保存，直到 will 过程被执行。}


@defproc[(will-execute [executor will-executor?]) any]{

调用注册到执行器 @racket[executor] 的单个 "不可达" 值的 will 过程。will 过程返回的值是 @racket[will-execute] 调用的结果。如果没有 will 立即可供执行，@racket[will-execute] 会阻塞直到有就绪的 will。}


@defproc[(will-try-execute [executor any/c] [v any/c #f])
          any]{

如果 will 立即可供执行，则类似 @racket[will-execute]。否则返回 @racket[v]。

@history[#:changed "6.90.0.4" @elem{添加了 @racket[v] 参数。}]}

@;------------------------------------------------------------------------
@section[#:tag "garbagecollection"]{垃圾回收}

在 Racket 启动前设置 @as-index{@envvar{PLTDISABLEGC}} 环境变量（为任意值）可禁用 @tech{garbage collection}。设置 @as-index{@envvar{PLT_INCREMENTAL_GC}} 环境变量为以 @litchar{1}、@litchar{y} 或 @litchar{Y} 开头的值以请求 Racket 的 @tech{3m} 实现始终使用增量模式，但在带有定期任务的程序中调用 @racket[(collect-garbage 'incremental)] 通常是请求增量模式的更好机制。设置 @envvar{PLT_INCREMENTAL_GC} 环境变量为以 @litchar{0}、@litchar{n} 或 @litchar{N} 开头的值可禁用增量模式请求（在所有 Racket 实现中）。

每次垃圾回收都会在 @racket['debug] 级别、以 @racket['GC] 为主题记录一条消息（参见 @secref["logging"]）。在 Racket 的 @tech{CS} 和 @tech{3m} 实现中，"主要" 回收也会在 @racket['debug] 级别、以 @racket['GC:major] 为主题记录。在 Racket 的 @tech{CS} 和 @tech{3m} 实现中，消息的数据部分是一个 @indexed-racket[gc-info] @tech{prefab} 结构体实例，包含以下 10 个字段，但 Racket 的未来版本可能使用带有额外字段的 @racket[gc-info] @tech{prefab} 结构体：

@racketblock[
(struct gc-info (mode pre-amount pre-admin-amount code-amount
                      post-amount post-admin-amount
                      start-process-time end-process-time
                      start-time end-time)
  #:prefab)
]

@itemlist[

 @item{@racket[mode] 字段是符号 @racket['major]、
       @racket['minor] 或 @racket['incremental]；@racket['major]
       表示检查所有内存的回收，
       @racket['minor] 表示主要只检查最近分配的回收，
       @racket['incremental] 表示执行额外工作以推进下一次主要回收的次要回收。

       @history[#:changed "6.3.0.7" @elem{将第一个字段从布尔值
                                          （@racket[#t] 表示
                                          @racket['major]，@racket[#f]
                                          表示 @racket['minor]）
                                          更改为模式符号。}]}

 @item{@racket[pre-amount] 字段报告开始 @tech{garbage collection} 时
       （即不包括子 place 的内存使用量）以字节为单位的位置本地内存使用量。
       通过 @racket[make-phantom-bytes] 注册的额外字节也被包含在内。}

 @item{@racket[pre-admin-amount] 是包含垃圾回收器开销的更大数字，
       例如已映射但未使用的内存页面空间。}

 @item{@racket[code-amount] 字段报告生成的原生代码的额外内存使用量
       （垃圾回收前后相同，因为它通过 finalization 释放）。}

 @item{@racket[post-amount] 和 @racket[post-admin-amount] 字段
       对应于 @racket[pre-amount] 和
       @racket[pre-admin-amount]，但它们在垃圾回收之后。在典型配置中，
       @racket[post-amount] 与 @racket[pre-amount] 之间的差异
       贡献于 @racket[post-admin-amount]，因为被回收的页面倾向于保留储备，
       以备预期将被再次需要（但如果多次回收都未需要这些页面，则它们会被释放）。}

 @item{@racket[start-process-time] 和 @racket[end-process-time]
       字段报告垃圾回收开始和结束时（在
       @racket[current-process-milliseconds] 意义上）的处理器时间。时间差是回收消耗的处理器时间。}

 @item{@racket[start-time] 和 @racket[end-time] 字段报告
       垃圾回收开始和结束时的实际时间（在
       @racket[current-inexact-milliseconds] 意义上）。时间差是垃圾回收消耗的实际时间。}

]

所记录消息的文本格式可能会改变。
目前，在指示 @tech{place} 和回收模式的前缀之后，文本格式为

@nested[#:style 'inset]{
 @tt{@nonterm{used}(@nonterm{admin})[@nonterm{code}]; @;
     free @nonterm{reclaimed}(@nonterm{adjust}) @nonterm{elapsed} \@ @nonterm{timestamp}}

@tabular[
  #:sep (hspace 1)
  (list (list @nonterm{used}
              @elem{垃圾回收前正在使用的可回收内存})
        (list @nonterm{admin}
              @elem{用于管理可回收内存的额外内存})
        (list @nonterm{code}
              @elem{生成的机器代码使用的额外内存})
        (list @nonterm{reclaimed}
              @elem{垃圾回收回收的可回收内存})
        (list @nonterm{adjust}
              @elem{行政内存变化减去 @nonterm{reclaimed} 的相反数})
        (list @nonterm{elapsed}
              @elem{执行垃圾回收所用处理器时间})
        (list @nonterm{timestamp}
              @elem{垃圾回收启动以来的处理器时间}))
]

@history[#:changed "6.3.0.7" @elem{添加了 @envvar{PLT_INCREMENTAL_GC}。}
         #:changed "7.6.0.9" @elem{为主题 @racket['GC:major] 添加了主要回收日志记录。}]


@defproc[(collect-garbage [request (or/c 'major 'minor 'incremental) 'major]) void?]{

请求一次即时 @tech{garbage collection} 或请求一个垃圾回收模式，取决于 @racket[request]：

@itemlist[

 @item{@racket['major] —— 强制进行 "主要" 回收，
       检查所有内存。某些实际上不可达的数据可能
       不会被收集，因为回收器无法证明它
       不可达。

       @racket[collect-garbage] 此模式提供了对回收时机的一些控制，但
       显然即使从不调用此过程，垃圾也会被收集——除非通过设置
       @envvar{PLTDISABLEGC} 禁用了垃圾回收。}

 @item{@racket['minor] —— 请求 "次要" 回收，主要只检查最近的分配。如果
       次要回收不被支持（例如 @racket[(system-type 'gc)] 返回
       @racket['cgc]）或如果下一次回收必须是主要回收，则不执行任何回收。更一般地，
       由 @racket[(collect-garbage 'minor)] 触发的次要回收不会导致
       主要回收比原本发生时更早。}

 @item{@racket['incremental] —— 不请求即时回收，但请求未来额外努力以避免
       主要回收，即使这需要每次次要回收做更多工作以增量执行主要回收的工作。此增量模式请求在下一次主要回收时过期。

       增量模式的意图是显著减少主要回收导致的暂停时间，但增量模式可能意味着
       更长的次要回收时间和更高的内存使用。目前，
       增量模式仅对 Racket 的 @tech{CS} 和 @tech{3m}
       实现有意义；它在其他 Racket 实现中无效。

       如果 @envvar{PLT_INCREMENTAL_GC} 环境变量的值在启动时以 @litchar{0}、@litchar{n} 或 @litchar{N} 开头，则增量模式请求将被忽略。}

]

@history[#:changed "6.3" @elem{添加了 @racket[request] 参数。}
         #:changed "6.3.0.2" @elem{添加了 @racket['incremental] 模式。}
         #:changed "7.7.0.4" @elem{为 Racket @tech{CS} 添加了 @racket['incremental] 效果。}]}


@defproc[(current-memory-use [mode (or/c #f 'cumulative 'peak custodian?) #f])
         exact-nonnegative-integer?]{

返回内存使用信息：

@itemlist[

 @item{若 @racket[mode] 为 @racket[#f]（默认值），结果为从任意 custodian 可达的字节数的估计值。}

 @item{若 @racket[mode] 为 @racket['cumulative]，返回自启动以来分配的字节总数的估计值，
       包括已被垃圾回收回收的字节。}

 @item{若 @racket[mode] 为 @racket['peak]，返回 Racket 进程启动以来在任何垃圾回收之前已分配字节数的最大值。}

 @item{若 @racket[mode] 是 custodian，返回从 @racket[mode] 可达数据占用的内存字节数的估计值。
       此估计值由最后一次垃圾回收计算，如果未发生回收（或自给定 custodian 创建以来未发生回收），则可能为 0。
       @racket[current-memory-use] 函数本身 @italic{不} 执行回收；在调用前执行回收通常会减小结果（或如果尚未发生回收则从 0 增加）。

       当 Racket 编译时未启用内存记账支持，对于任何单个 custodian，估计值与 @racket[mode] 为 @racket[#f] 时相同（即所有内存）。另请参见
       @racket[custodian-memory-accounting-available?]。}

]

另请参见 @racket[vector-set-performance-stats!]。

@history[#:changed "6.6.0.3" @elem{添加了 @racket['cumulative] 模式。}
         #:changed "8.10.0.3" @elem{添加了 @racket['peak] 模式。}]}


@defproc[(dump-memory-stats [v any/c] ...) any]{

将内存使用信息转储到低级错误端口或控制台。

@racket[v] 参数的各种组合可以控制转储中的信息。可用的信息取决于你的 Racket 构建；检查特定构建的转储末尾以查看是否提供额外信息；否则所有 @racket[v] 都会被忽略。}

@;------------------------------------------------------------------------
@section[#:tag "phantom-bytes"]{幻字节串（Phantom Byte Strings）}

一个 @deftech{phantom byte string} 是一个小的 Racket 值，被 Racket 内存管理器视为具有任意大小，该大小在创建 @tech{phantom byte string} 时或通过 @racket[set-phantom-bytes!] 更改时指定。

@tech{phantom byte string} 作为对 Racket 内存管理器的提示，表示内存是在进程内分配的，但通过单独的分配器，例如通过 @racketmodname[ffi/unsafe] 访问的外部库。此提示用于触发 @tech{garbage collections} 或计算 @racket[current-memory-use] 的结果。

@defproc[(phantom-bytes? [v any/c]) boolean?]{

若 @racket[v] 是 @tech{phantom byte string} 则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-phantom-bytes [k exact-nonnegative-integer?])
         phantom-bytes?]{

创建一个 @tech{phantom byte string}，被 Racket 内存管理器视为大小为 @racket[k] 字节。对于足够大的 @racket[k]，会引发 @exnraise[exn:fail:out-of-memory]——要么因为大小大得离谱，要么因为已通过 @racket[custodian-limit-memory] 安装了内存限制。}


@defproc[(set-phantom-bytes! [phantom-bstr phantom-bytes?]
                             [k exact-nonnegative-integer?])
         phantom-bytes?]{

调整 @tech{phantom byte string} 被 Racket 内存管理器视为的大小。

例如，若 @racket[phantom-bstr] 表示的内存通过外部库释放，则 @racket[(set-phantom-bytes!
phantom-bstr 0)] 可以反映内存使用的变化。

当 @racket[k] 大于 @racket[phantom-bstr] 的当前大小时，此函数可能引发 @racket[exn:fail:out-of-memory]，类似于 @racket[make-phantom-bytes]。}
