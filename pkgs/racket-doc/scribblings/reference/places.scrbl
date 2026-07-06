#lang scribble/doc

@title[#:tag "places"]{Places}

@; ----------------------------------------------------------------------

@(require scribble/manual scribble/urls scribble/struct "mz.rkt"
          (for-label racket
                     racket/base
                     racket/contract
                     racket/place
                     racket/future
                     racket/flonum
                     racket/fixnum
                     (only-in racket/place/distributed create-place-node)))

@; ----------------------------------------------------------------------

@guideintro["effective-places"]{places}

@note-lib[racket/place #:more-libs (racket/place/dynamic) #:use-sources(racket/place)]

@tech{Places} 使得开发并行程序成为可能，能够利用多处理器、多核或
硬件线程的机器。

@margin-note{当前，在所有支持 Racket @tech{CS}（Racket 的默认实现）的平台上，
  place 的并行支持都已启用。
  @tech{3m} 实现在 Windows、Linux x86/x86_64 和 Mac OS x86/x86_64 上
  也默认支持 place 的并行执行。要
  在 @tech{3m} 的其他平台上启用支持，请在构建 Racket 时使用 @DFlag{enable-places} 和
  @exec{configure}。@racket[place-enabled?] 函数报告 place 是否并行运行。

  实现和操作系统的约束可能会限制 place 的可扩展性。例如，尽管 place 可以在
  @tech{CS} 实现中并行执行垃圾回收，或在 @tech{3m} 实现中独立执行，
  但垃圾回收可能需要操纵一个在所有 place 之间共享的页表，
  当 place 数量足够多时（大约 8 或 16 个），该共享页表可能成为瓶颈。}

@deftech{place} 是一个并行任务，本质上是 Racket 虚拟机的一个独立实例，
尽管所有 place 都在单个操作系统进程内运行。Place 通过
@deftech{place channel} 进行通信，place channel 是双向缓冲通信的端点。

To a first approximation, place channels support only immutable,
transparent values as messages. In addition, place
channels themselves can be sent across channels to establish new
(possibly more direct) lines of communication in addition to any
existing lines. Finally, mutable values produced by
@racket[shared-flvector], @racket[make-shared-flvector],
@racket[shared-fxvector], @racket[make-shared-fxvector],
@racket[shared-bytes], and @racket[make-shared-bytes] can be sent
across place channels; mutation of such values is visible to all
places that share the value, because they are allowed in a
@deftech{shared memory space}. See @racket[place-message-allowed?].

@tech{place channel} 可用作 @tech{synchronizable event}
（参见 @secref["sync"]）来通过 channel 接收值。
当 channel 上有消息可用时，@tech{place channel} 处于 @tech{ready for synchronization} 状态，
其 @tech{synchronization result} 就是该消息（在同步时移除）。
Place 也可以用 @racket[place-channel-get] 接收消息，
用 @racket[place-channel-put] 发送消息。

当两个 @tech{place channel} 是同一底层 channel 的端点，
且两者都是或都不是 @tech{place descriptor} 时，它们 @racket[equal?]。
@tech{Place channel} 在通过 @tech{place channel} 传递消息后，
可以是 @racket[equal?] 但并非 @racket[eq?] 的。

对 place channel 上消息的约束——因而也是对 place 共享数据种类的约束——
使得 @racket[future] 无法实现同等程度的并行性，甚至包括各个 place 独立的
@tech{garbage collection}。同时，place 的设置和通信开销
可能比 @tech{future} 更高。

例如，以下表达式启动两个 place，向每个 place 发送消息，
然后等待 place 终止：

@racketblock[
(let ([pls (for/list ([i (in-range 2)])
              (dynamic-place "place-worker.rkt" 'place-main))])
   (for ([i (in-range 2)]
         [p pls])
      (place-channel-put p i)
      (printf "~a\n" (place-channel-get p)))
   (for-each place-wait pls))
]

@filepath{place-worker.rkt} 模块（位于与上述代码不同的文件中）
必须导出每个 place 执行的 @racket[place-main] 函数，
其中 @racket[place-main] 必须接受单个 @tech{place channel} 参数：

@racketmod[#:file "place-worker.rkt"
racket
(provide place-main)

(define (place-main pch)
  (place-channel-put pch (format "Hello from place ~a" 
                                  (place-channel-get pch))))
]

与其他 Racket 值一样，place channel 也会被 @tech{garbage collection} 处理；
如果 @tech{place channel} 的写入端变得不可达，
那么被阻塞在读取 @tech{place channel} 上的 @tech{thread} 也可以被垃圾回收。 @elemtag['(caveat
"place-channel-gc")]{However}, unlike normal @tech{channel} blocking,
if otherwise unreachable threads are mutually blocked on place
channels that are reachable only from the same threads, the threads
and place channels are all considered reachable, instead of
unreachable.

创建 place 时，其 @tech{parameter} 值通常设置为创建 place 中参数的
@emph{初始}值，但以下参数使用其 @emph{当前}值：
@racket[current-library-collection-paths]、
@racket[current-library-collection-links] 和
@racket[current-compiled-file-roots]。

新创建的 place 会注册到 @tech{current custodian}，
当 custodian 被关闭时，该 place 也会被终止。

@; ----------------------------------------

@section[#:tag "places-api"]{Using Places}

@defproc[(place-enabled?) boolean?]{

如果 Racket 配置为 @racket[dynamic-place] 和 @racket[place] 创建可以并行运行的 place，
则返回 @racket[#t]；如果 @racket[dynamic-place] 和 @racket[place] 使用 @racket[thread] 模拟，
则返回 @racket[#f]。}


@defproc[(place? [v any/c]) boolean?]{
  如果 @racket[v] 是 @deftech{place descriptor} 值，则返回 @racket[#t]，
  否则返回 @racket[#f]。每个 @tech{place descriptor} 同时也是 @tech{place channel}。
}

@defproc[(place-channel? [v any/c]) boolean?]{
  如果 @racket[v] 是 @tech{place channel}，则返回 @racket[#t]，
  否则返回 @racket[#f]。
}


@defproc[(dynamic-place [module-path (or/c module-path? path?)]
                        [start-name symbol?]
                        [#:at location (or/c #f place-location?) #f]
                        [#:named named any/c #f])
         place?]{

 创建一个 @tech{place} 来运行由 @racket[module-path] 和 @racket[start-name] 标识的过程。
 结果是一个 @tech{place descriptor} 值，代表新的并行任务；
 place descriptor 会立即返回。该 place descriptor 值同时也是一个 @tech{place channel}，
 允许与该 place 通信。

 @racket[module-path] 所指示的模块必须导出名为 @racket[start-name] 的函数。
 该函数必须接受单个参数，即一个 @tech{place channel}，
 对应于 @racket[place] 返回的 @tech{place descriptor} 的另一端通信。

如果提供了 @racket[location]，它必须是 @tech{place location}，
例如由 @racket[create-place-node] 产生的分布式 place 节点。

 创建 @tech{place} 时，初始 @tech{exit handler} 会终止该 place，
 使用 exit handler 的参数作为 place 的 @deftech{completion value}。
 使用 @racket[(exit _v)] 可以立即以 completion value @racket[_v] 终止 place。
 由于 completion value 限于 @racket[0] 到 @racket[255] 之间的精确整数，
 @racket[v] 的任何其他值都会被转换为 @racket[0]。

 如果 @racket[module-path] 和 @racket[start-name] 所指示的函数返回，
 则 place 以 @tech{completion value} @racket[0] 终止。

 在新创建的 place 中，@racket[current-input-port] 参数被设置为空输入端口，
 而 @racket[current-output-port] 和 @racket[current-error-port] 参数的值
 连接到创建 place 中的当前端口。如果创建 place 中的输出端口是 @tech{file-stream port}，
 则创建 place 中连接的端口共享底层流，
 否则创建 place 中的 @tech{thread} 会将字节从创建 place 的端口
 泵送到创建 place 的当前端口。

 新创建 place 中的大多数 @tech{parameter} 保留其原始初始值，
 但创建 place 会继承创建 place 中以下参数的值：
 @racket[current-directory]、@racket[current-library-collection-paths]、
 @racket[current-library-collection-links] 和 @racket[current-compiled-file-roots]。

 @racket[module-path] 参数不得是 @racket[(#,(racket quote) _sym)] 形式的模块路径，
 除非该模块是预定义的（参见 @racket[module-predefined?]）。

@racket[dynamic-place] 绑定受到 @racket[protect-out] 的保护，
 因此可以通过调整 code inspector 来防止访问此操作（参见 @secref["modprotect"]）。

@history[#:changed "8.2.0.7" @elem{Changed created place to inherit
                                   the creating place's @racket[current-directory]
                                   value.}]}


@defproc[(dynamic-place* [module-path (or/c module-path? path?)]
                         [start-name symbol?]
                         [#:in in (or/c input-port? #f) #f]
                         [#:out out (or/c output-port? #f) (current-output-port)]
                         [#:err err (or/c output-port? #f) (current-error-port)])
                         (values place? (or/c output-port? #f) (or/c input-port? #f) (or/c input-port? #f))]{

 类似于 @racket[dynamic-place]，但接受特定端口连接到新 place 的端口，
 当为某端口提供 @racket[#f] 时返回创建的端口。
 @racket[in]、@racket[out] 和 @racket[err] 端口分别连接到
 @racket[current-input-port]、@racket[current-output-port] 和
 @racket[current-error-port] 端口，用于 @tech{place}。
 任何端口都可以是 @racket[#f]，此时会创建一个 @tech{file-stream port}（用于操作系统管道）
 并由 @racket[dynamic-place*] 返回。@racket[err] 参数可以是 @racket['stdout]，
 此时用于标准输出的 @tech{file-stream port} 或提供的端口
 也用于标准错误。对于提供的每个端口或 @racket['stdout]，
 不会创建管道，对应的返回值为 @racket[#f]。

 @racket[dynamic-place*] 的调用者负责关闭所有返回的端口；
 不会自动关闭任何端口。

@racket[dynamic-place*] 过程返回四个值：

@itemize[

 @item{表示所创建 place 的 place descriptor 值；}

 @item{连接到 place 标准输入的输出端口，
 如果 @racket[in] 是端口则为 @racket[#f]；}

 @item{从 place 标准输出连接的输入端口，
 如果 @racket[out] 是端口则为 @racket[#f]；}

 @item{从 place 标准错误连接的输入端口，
 如果 @racket[err] 是端口或 @racket['stdout] 则为 @racket[#f]。}

]

@racket[dynamic-place*] 绑定受到与 @racket[dynamic-place] 相同的保护。}


@defproc[(place-wait [p place?]) exact-integer?]{
  返回 @racket[p] 所指示 place 的 @tech{completion value}，
  阻塞直到该 place 终止。

  如果创建了任何 pumping thread 以将非 @tech{file-stream port}
  连接到 @racket[p] 的 place 的端口（参见 @racket[dynamic-place]），
  则 @racket[place-wait] 仅在 pumping thread 完成后才返回。  }


@defproc[(place-dead-evt [p place?]) evt?]{

返回一个 @tech{synchronizable event}（参见 @secref["sync"]），
当且仅当 @racket[p] 已终止时处于 @tech{ready for synchronization} 状态。
@ResultItself{place-dead event}.

如果创建了任何 pumping thread 以将非 @tech{file-stream port}
  连接到 @racket[p] 的 place 的端口（参见 @racket[dynamic-place]），
  则即使 pumping thread 仍在运行，@racket[place-dead-evt] 返回的事件
  也可能变为 ready 状态。}


@defproc[(place-kill [p place?]) void?]{
  立即终止 place，如果 place 尚没有 completion value，
  则将其 @tech{completion value} 设置为 @racket[1]。}


@defproc[(place-break [p place?]
                      [kind (or/c #f 'hang-up 'terminate) #f])
         void?]{
  向 place @racket[p] 的主线程发送 break；参见 @secref["breakhandler"]。
}

@defproc[(place-channel) (values place-channel? place-channel?)]{

  返回两个 @tech{place channel}。通过第一个 channel 发送的数据
  可以通过第二个 channel 接收，通过第二个 channel 发送的数据
  可以通过第一个 channel 接收。

  通常，当前 @tech{place} 使用一个 place channel 向目标 @tech{place} 发送消息；
  另一个 place channel 被发送到目标 @tech{place}（通过已有的 @tech{place channel}）。
}

@defproc[(place-channel-put [pch place-channel?] [v place-message-allowed?]) void]{
  在 channel @racket[pch] 上发送消息 @racket[v]。
  由于 place channel 是异步的，@racket[place-channel-put] 调用是非阻塞的。

 See @racket[place-message-allowed?] form information on automatic
 coercions in @racket[v], such as converting a mutable string to an
 immutable string.

}

@defproc[(place-channel-get [pch place-channel?]) place-message-allowed?]{
  Returns a message received on channel @racket[pch], blocking until a 
 message is available.
}

@defproc[(place-channel-put/get [pch place-channel?] [v any/c]) any/c]{
  在 channel @racket[pch] 上发送不可变消息 @racket[v]，
  然后在同一 channel 上等待消息（可能是回复）。
}

@defproc[(place-message-allowed? [v any/c]) boolean?]{

如果 @racket[v] 允许作为 place channel 上的消息，则返回 @racket[#t]，
否则返回 @racket[#f]。

如果 @racket[(place-enabled?)] 返回 @racket[#f]，则结果始终为 @racket[#t]，
不会对 @racket[v] 作为消息执行任何转换。否则，以下类型的数据允许作为消息：

@itemlist[

 @item{@tech{number}、@tech{character}、@tech{boolean}、@tech{keyword} 和
       @|void-const|；}

 @item{@tech{symbol}，其中 @tech{uninterned} symbol 的 @racket[eq?] 性
       在单条消息内保留，但跨消息不保留；}
 
 @item{@tech{string} 和 @tech{byte string}，其中可变字符串和 byte string
       会自动替换为不可变变体；}

 @item{@tech{path}（适用于任何平台）；}

 @item{包含允许消息的值的 @tech{pair}、@tech{list}、@tech{box}、@tech{vector}
       和不可变 @tech{prefab} struct，其中可变 box 会自动替换为不可变 box，
       可变 vector 会自动替换为不可变 vector，
       box、vector 和 @tech{prefab} struct 的 @tech{impersonator} 会被复制；}

 @item{@tech{hash table}，其中可变 hash table 会自动替换为不可变变体，
       hash table 的 @tech{impersonator} 会被复制；}

 @item{@tech{place channel}，其中 @tech{place descriptor}
       会自动替换为普通 place channel；}

 @item{@tech{file-stream port} 和 @tech{TCP port}，其中底层表示
       （如文件描述符、套接字或句柄）在发送 place 中复制，
       并附加到接收 place 中的新端口；}

 @item{通过 @racketmodname[ffi/unsafe] 创建或访问的
       @tech[#:doc '(lib "scribblings/foreign/foreign.scrbl")]{C pointer}；以及}

 @item{由 @racket[shared-flvector]、@racket[make-shared-flvector]、
       @racket[shared-fxvector]、@racket[make-shared-fxvector]、
       @racket[shared-bytes] 和 @racket[make-shared-bytes] 产生的值。}]

@history[#:changed "8.4.0.7" @elem{Include boxes in allowed messages.}]}

@deftogether[(
@defthing[prop:place-location struct-type-property?]
@defproc[(place-location? [v any/c]) boolean?]
)]{

@deftech{place location} 的 @tech{structure type property} 和关联 predicate。
@racket[prop:place-location] 的值必须是一个接受四个参数的过程：
@tech{place location} 本身、模块路径、模块导出的 start function 的 symbol，
以及 place 名称（对于匿名 place 可以是 @racket[#f]）。

@tech{place location} 可以作为 @racket[#:at] 参数传递给 @racket[dynamic-place]，
后者只需调用 @tech{place location} 的 @racket[prop:place-location] 值。

使用 @racket[create-place-node] 创建的分布式 place 节点
是 @tech{place location} 的一个示例。}

 
@section[#:tag "places-syntax"]{Syntactic Support for Using Places}

@declare-exporting[racket/place]

本节中的绑定 @emph{不是} 由 @racketmodname[racket/place/dynamic] 提供的。
 
@defform[(place id body ...+)]{
  创建一个 place，在 @racket[id] 绑定到 place channel 的情况下
  求值 @racket[body] 表达式。@racket[body] 仅封闭 @racket[id]
  以及封闭模块的顶层绑定，因为 @racket[body] 被提升到子模块。
  @racket[place] 的结果是一个 place descriptor，
  类似于 @racket[dynamic-place] 的结果。

生成的子模块名为 @racketidfont{place-body-@racket[_n]}，
其中 @racket[_n] 是整数，子模块导出一个 @racket[main] 函数，
接受新 place 的 place channel。然而，该子模块不供直接使用，
仅由 @racket[place] 形式展开。

@racket[place] 绑定受到与 @racket[dynamic-place] 相同的保护。}

@defform/subs[(place* maybe-port ...
                      id 
                      body ...+)
              ([maybe-port code:blank
                           (code:line #:in in-expr)
                           (code:line #:out out-expr)
                           (code:line #:err err-expr)])]{
 类似于 @racket[place]，但支持可选的 @racket[#:in]、@racket[#:out]
 和 @racket[#:err] 表达式（每种最多一个），以与 @racket[dynamic-place*]
 相同的方式和默认值指定端口。@racket[place*] 形式的结果
 也与 @racket[dynamic-place*] 相同。

@racket[place*] 绑定受到与 @racket[dynamic-place] 相同的保护。}

@defform[(place/context id body ...+)]{
  类似于 @racket[place]，但 @racket[body ...] 可以包含自由词法变量，
  这些变量会自动发送到新创建的 place。
  注意，这些变量的值必须被 @racket[place-message-allowed?] 接受，
  否则会引发 @exnraise[exn:fail:contract]。
}

@defproc[(processor-count) exact-positive-integer?]{

  返回当前机器上可用的并行计算单元（例如处理器或核心）的数量。

  这与从 @racketmodname[racket/future] 可用的绑定相同。
}

@;------------------------------------------------------------------------

@include-section["places-logging.scrbl"]
