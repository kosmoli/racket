#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/custodian))

@title[#:tag "foreign:pointer-funcs"]{指针函数}

@defproc[(cpointer? [v any/c]) boolean?]{

如果 @racket[v] 是一个 C 指针或可用作指针的值，则返回 @racket[#t]：@racket[#f](用作 @cpp{NULL} 指针)、字节串(用作内存块)，或具有 @racket[prop:cpointer] @tech[#:doc reference.scrbl]{structure type property} 的 structure 实例。对其他值返回 @racket[#f]。}

@defproc[(ptr-equal? [cptr1 cpointer?] [cptr2 cpointer?]) boolean?]{

比较两个指针的值。两个不同的 Racket 指针对象可能包含相同的指针。

如果两个值都是不由 @racket[#f] 表示的指针、字节串、callback、基于 @racket[_fpointer] 的指针，或具有 @racket[prop:cpointer] 属性的 structure，则 @racket[ptr-equal?] 的比较结果与使用 @racket[equal?] 相同。}


@defproc[(ptr-add [cptr cpointer?] [offset exact-integer?] [type ctype? _byte]) 
         cpointer?]{

返回一个类似于 @racket[cptr] 的 cpointer，但按 @racket[offset] 个 @racket[ctype] 实例进行偏移。

生成的 cpointer 将基指针和偏移量分开保存。这两部分在指针上执行任何操作之前的最后一刻才合并，例如将指针提供给 foreign 函数。特别地，指针和偏移量直到 foreign 函数调用之前的所有分配完成之后才合并；如果被调用的函数本身不会调用任何可能触发垃圾回收的操作，那么它可以安全地使用偏移到 GCable 对象中间的指针。}


@defproc[(offset-ptr? [cptr cpointer?]) boolean?]{

用于判断 cpointer 是否具有偏移量的谓词，例如使用 @racket[ptr-add] 创建的指针。即使偏移量为 0 也返回 @racket[#t]。对其他 cpointer 和非 cpointer 返回 @racket[#f]。}


@defproc[(ptr-offset [cptr cpointer?]) exact-integer?]{

返回具有偏移量的指针的偏移量。结果偏移量始终以字节为单位。}


@defproc[(cpointer-gcable? [cptr cpointer?]) boolean?]{

如果 @racket[cptr] 被视为对(假定由)垃圾回收器管理的内存的引用，则返回 @racket[#t]，否则返回 @racket[#f]。

对于以 @racket[_gcpointer] 为结果类型的指针，@racket[cpointer-gcable?] 返回 @racket[#t]。对于以 @racket[_pointer] 为结果类型的指针，@racket[cpointer-gcable?] 返回 @racket[#f]。}


@; ----------------------------------------------------------------------

@section{指针解引用}

@defproc[(set-ptr-offset! [cptr cpointer?] [offset exact-integer?] [ctype ctype? _byte]) 
         void?]{

设置偏移指针的偏移量分量。参数的使用方式与 @racket[ptr-add] 相同。如果 @racket[cptr] 没有偏移量，则引发 @racket[exn:fail:contract] 异常。}


@defproc[(ptr-add! [cptr cpointer?] [offset exact-integer?] [ctype ctype? _byte]) 
         void?]{

类似于 @racket[ptr-add]，但会破坏性地修改指针中包含的偏移量。同样的操作可以通过 @racket[ptr-offset] 和 @racket[set-ptr-offset!] 来完成。}


@defproc*[([(ptr-ref [cptr cpointer?]
                     [type ctype?]
                     [offset exact-nonnegative-integer? 0])
            any]
           [(ptr-ref [cptr cpointer?]
                     [type ctype?]
                     [abs-tag 'abs]
                     [offset exact-nonnegative-integer?])
            any]
           [(ptr-set! [cptr cpointer?]
                      [type ctype?]
                      [val any/c])
            void?]
           [(ptr-set! [cptr cpointer?]
                      [type ctype?]
                      [offset exact-nonnegative-integer?]
                      [val any/c])
            void?]
           [(ptr-set! [cptr cpointer?]
                      [type ctype?]
                      [abs-tag 'abs]
                      [offset exact-nonnegative-integer?]
                      [val any/c])
            void?])]{

@racket[ptr-ref] 过程返回 @racket[cptr] 引用的对象，使用给定的 @racket[type]。@racket[ptr-set!] 过程将 @racket[val] 存储到 @racket[cptr] 指向的内存中，使用给定的 @racket[type] 进行转换。

在每种情况下，@racket[offset] 默认为 @racket[0](这是用于 @racket[ffi-obj] 对象的唯一值，见 @secref["foreign:c-only"])。如果 @racket[offset] 索引非 @racket[0]，则在该位置读取或存储值，此时将指针视为 @racket[type] 的向量——因此实际地址是指针加上 @racket[type] 的大小乘以 @racket[offset]。此外，可以使用 @racket['abs] 标志来将 @racket[offset] 作为字节计数而非指定 @racket[type] 的增量。

注意 @racket[ptr-ref] 和 @racket[ptr-set!] 过程不会保留任何关于指针使用方式的元信息。程序员有责任仅在适当时使用此功能。例如，在小端机器上：

@racketblock[
> (define block (malloc _int 5))
> (ptr-set! block _int 0 196353)
> (map (lambda (i) (ptr-ref block _byte i)) '(0 1 2 3))
@#,(racketresultfont "(1 255 2 0)")
]

此外，@racket[ptr-ref] 和 @racket[ptr-set!] 无法检测偏移量是否超出对象的内存边界；超界访问很容易导致段错误或内存损坏。}


@defproc*[([(memmove [cptr cpointer?]
                     [offset exact-integer? 0]
                     [src-cptr cpointer?]
                     [src-offset exact-integer? 0]
                     [count exact-nonnegative-integer?]
                     [type ctype? _byte])
            void?])]{

从 @racket[src-cptr] 复制到 @racket[cptr]。目标指针可以通过可选的 @racket[offset] 进行偏移，以 @racket[type] 实例为单位。源指针同样可以通过 @racket[src-offset] 进行偏移。从源复制到目标的字节数由 @racket[count] 确定，当提供时以 @racket[type] 实例为单位。}

@defproc*[([(memcpy [cptr cpointer?]
                    [offset exact-integer? 0]
                    [src-cptr cpointer?]
                    [src-offset exact-integer? 0]
                    [count exact-nonnegative-integer?]
                    [type ctype? _byte])
            void?])]{

类似于 @racket[memmove]，但如果目标和源重叠，则结果未定义。}

@defproc*[([(memset [cptr cpointer?]
                    [offset exact-integer? 0]
                    [byte byte?]
                    [count exact-nonnegative-integer?]
                    [type ctype? _byte])
            void?])]{

类似于 @racket[memmove]，但目标被统一填充为 @racket[byte](即 0 到 255 之间的精确整数)。当提供 @racket[type] 参数时，结果相当于调用无 @racket[type] 参数的 memset，且 @racket[count] 乘以与 @racket[type] 关联的大小。}

@defproc[(cpointer-tag [cptr cpointer?]) any]{

返回作为给定 @racket[cptr] 指针 tag 的 Racket 对象。}


@defproc[(set-cpointer-tag! [cptr cpointer?] [tag any/c]) void?]{

设置给定 @racket[cptr] 的 tag。@racket[tag] 参数可以是任意值；其他指针操作会忽略它。当打印 cpointer 值时，如果 tag 是 symbol、字节串或字符串，则会显示该 tag。此外，如果 tag 是 pair 且其 @racket[car] 包含上述之一，则显示 @racket[car](以便 tag 可以包含其他信息)。}


@; ------------------------------------------------------------

@section{内存管理}

有关 Racket 中 C 级内存管理的常规信息，见 @|InsideRacket|。

@defproc[(malloc [bytes-or-type (or/c (and/c exact-nonnegative-integer? fixnum?) 
                                      ctype?)]
                 [type-or-bytes (or/c (and/c exact-nonnegative-integer? fixnum?) 
                                      ctype?) 
                                @#,elem{absent}]
                 [cptr cpointer? @#,elem{absent}]
                 [mode (or/c 'raw 'atomic 'nonatomic 'tagged
                             'atomic-interior 'interior
                             'zeroed-atomic 'zeroed-atomic-interior
                             'stubborn 'uncollectable 'eternal)
                       @#,elem{absent}]
                 [fail-mode (or/c 'fail-ok 'failok) @#,elem{absent}])
         cpointer?]{

使用指定的分配方式分配指定大小的内存块。结果是指向分配内存的 C 指针，如果请求的大小为零则为 @racket[#f]。虽然上面未体现，但四个参数可以按任意顺序出现，因为它们都是不同类型的 Racket 对象；至少需要指定大小：

@itemize[

 @item{If a C type @racket[bytes-or-type] is given, its size is used
       to determine the block allocation size.}

 @item{If an integer @racket[bytes-or-type] is given, it specifies the
       required size in bytes.}

 @item{If both @racket[bytes-or-type] and @racket[type-or-bytes] are given,
       then the allocated size is for a vector of values (the multiplication of
       the size of the C type and the integer).}

 @item{If a @racket[cptr] pointer is given, its content is copied to
       the new block.}

  @item{A symbol @racket[mode] argument can be given, which specifies
  what allocation function to use.  It should be one of the following:

   @itemlist[

     @item{@indexed-racket['raw] --- 分配在垃圾回收器空间之外的内存，
       不被垃圾回收器追踪(即视为不包含指向可回收内存的指针)。
       此内存必须使用 @racket[free] 释放。内存的初始内容未指定。}

     @item{@indexed-racket['atomic] --- 分配可被垃圾回收器回收但不被垃圾回收器追踪的内存。
       内存的初始内容未指定。

       对于 @BC[] Racket 实现，此分配模式对应 C API 中的 @cpp{scheme_malloc_atomic}。}

     @item{@indexed-racket['nonatomic] --- 分配可被垃圾回收器回收的内存，
       被垃圾回收器视为仅包含指针，且初始填充为零。内存允许包含对垃圾回收器管理对象的引用
       和垃圾回收器空间之外的地址的混合。

       对于 @BC[] Racket 实现，此分配模式对应 C API 中的 @cpp{scheme_malloc}。}

     @item{@indexed-racket['atomic-interior] --- 类似于
       @racket['atomic]，但只要分配的对象被保留，垃圾回收器就不会移动它。

       此分配模式的更好名称是
       @racket['atomic-immobile]，但出于历史原因使用了 @racket['atomic-interior]。

       对于 @BC[] Racket 实现，引用可以指向对象的内部而非起始地址。
       此分配模式对应 C API 中的 @cpp{scheme_malloc_atomic_allow_interior}。}

     @item{@indexed-racket['interior] --- 类似于
       @racket['nonatomic]，但只要分配的对象被保留，垃圾回收器就不会移动它。

       此分配模式的更好名称是
       @racket['nonatomic-immobile]，但出于历史原因使用了 @racket['interior]。

       对于 @BC[] Racket 实现，引用可以指向对象的内部而非起始地址。
       此分配模式对应 C API 中的 @cpp{scheme_malloc_allow_interior}。}

     @item{@indexed-racket['zeroed-atomic] --- 类似于 @racket['atomic]，
       但分配的对象填充为零，而非具有未指定的初始内容。}

     @item{@indexed-racket['zeroed-atomic-interior] --- 类似于
       @racket['atomic-interior]，但分配的对象填充为零，而非具有未指定的初始内容。}

     @item{@indexed-racket['tagged] --- 分配必须以 @tt{short} 值开头的内存，
       该值作为 tag 向垃圾回收器注册。

       此模式仅受 @BC[] Racket 实现支持，
       对应 C API 中的 @cpp{scheme_malloc_tagged}。}

     @item{@indexed-racket['stubborn] --- 类似于 @racket['nonatomic]，
       但在对对象的所有更改完成后通过 @racket[end-stubborn-change] 向 GC 提供提示。

       此模式仅受 @BC[] Racket 实现支持，
       对应 C API 中的 @cpp{scheme_malloc_stubborn}。}

     @item{@indexed-racket['eternal] --- Like @racket['raw], except the
       allocated memory cannot be freed.

       This mode is supported only for the @CGC[] Racket variant, and
       it corresponds to @cpp{scheme_malloc_uncollectable} in the C API.}

     @item{@indexed-racket['uncollectable] --- 分配永不被回收、无法释放且可能包含指向可回收内存的指针的内存。

       此模式仅受 @CGC[] Racket 变体支持，
       对应 C API 中的 @cpp{scheme_malloc_uncollectable}。}

   ]}

  @item{如果额外提供了 @indexed-racket['failok] 或 @indexed-racket['fail-ok] 标志，
        则会尝试检测分配失败并引发 @racket[exn:fail:out-of-memory] 而非崩溃。}

]

如果未指定 mode，则当类型是基于 @racket[_gcpointer] 或 @racket[_scheme] 的类型时使用
@racket['nonatomic] 分配，否则使用 @racket['atomic] 分配。

@history[#:changed "6.4.0.10" @elem{Added the @racket['tagged] allocation mode.}
         #:changed "8.0.0.13" @elem{Changed CS to support the @racket['interior] allocation mode.}
         #:changed "8.1.0.6" @elem{Changed CS to remove constraints on the use of memory allocated
                                   with the @racket['nonatomic] and @racket['interior] allocation
                                   modes.}
         #:changed "8.14.0.4" @elem{Added the @racket['zeroed-atomic]
                                    @racket['zeroed-atomic-interior] allocation modes.}
         #:changed "9.2.0.2" @elem{Added support for both @racket['failok] and
                                    @racket['fail-ok] to accomodate an earlier mismatch
                                    between CS and BC implementations.}]}


@defproc[(free [cptr cpointer?]) void]{

对 @racket['raw] 分配的指针以及由 foreign 库分配且我们应该释放的指针使用操作系统的 @cpp{free} 函数。
注意，这作为 finalizer 过程钩子的一部分很有用(例如，在 Racket 指针对象上，当指针对象被回收时释放内存，但要注意别名问题)。

使用 @racket[malloc] 和除 @racket['raw] 以外的模式分配的内存不得被 @racket[free]，因为这些模式分配的是由垃圾回收器管理的内存。}


@defproc[(end-stubborn-change [cptr cpointer?]) void?]{

在给定的 stubborn 分配的指针上使用 @cpp{scheme_end_stubborn_change}。}


@defproc[(malloc-immobile-cell [v any/c]) cpointer?]{

分配足大以容纳一个任意(可回收的)Racket 值的内存，但其本身不可回收也不会被内存管理器移动。
cell 用 @racket[v] 初始化；使用 @racket[_scheme] 类型配合 @racket[ptr-ref] 和 @racket[ptr-set!]
来获取或设置 cell 的值。cell 必须使用 @racket[free-immobile-cell] 显式释放。}


@defproc[(free-immobile-cell [cptr cpointer?]) void?]{

释放由 @racket[malloc-immobile-cell] 创建的 immobile cell。}


@defproc[(register-finalizer [obj any/c] [finalizer (any/c . -> . any)]) void?]{

为给定的 @racket[obj] 注册 finalizer 过程 @racket[finalizer]，@racket[obj] 可以是任意 Racket(可 GC)对象。
finalizer 注册到一个“late” @tech[#:doc reference.scrbl]{will executor}，该 executor 仅在值的所有弱引用
(如在 @tech[#:doc reference.scrbl]{weak box} 中)都被清除后才会使遗嘱准备就绪，
这意味着该值已不可达且没有正常的 @tech[#:doc reference.scrbl]{will executor} 有准备好的遗嘱。
当 @racket[obj] 的遗嘱在“late” will executor 中准备就绪时调用 finalizer，
这意味着该值对安全代码不可达(即使从遗嘱，生自身)。

finalizer 在负责触发 @racket[register-finalizer] 的 will executor 的线程中调用。
给定的 @racket[finalizer] 过程通常不应依赖触发线程的环境，
且不得使用任何 parameter 或调用任何 parameter 函数，但依赖默认 logger 和/或调用 @racket[current-logger] 是允许的。

finalizer 主要用于 cpointer 对象(用于释放不受 GC 控制的未使用内存)，但可用于任何 Racket 对象——
生自与 foreign 代码无关的对象。但请注意，finalizer 是为表示指针的 @italic{Racket} 对象注册的。
如果要释放指针对象，则必须小心不要为两个指向相同地址的 cpointer 注册 finalizer。
还要小心不要让 finalizer 成为持有该对象的 closure。
最后，注意当 place 退出时不保证 finalizer 会被运行；
见 @racketmodname[ffi/unsafe/alloc] 和 @racket[register-finalizer-and-custodian-shutdown] 获取更完整的解决方案。

作为 @racket[register-finalizer] 的示例，
假设你正在处理一个返回 C 指针的 foreign 函数，你应该释放该指针，但主要想使用偏移 16 字节的内存。
以下是创建合适类型的尝试：

@racketblock[
(define @#,racketidfont{_pointer-at-sixteen/free}
  (make-ctype _pointer
              #f (code:comment @#,t{i.e., just @racket[_pointer] as an argument type})
              (lambda (x)
                (let ([p (ptr-add x 16)])
                  (register-finalizer x free)
                  p))))
]

上面的代码是错误的：finalizer 是为 @racket[x] 注册的，在创建新指针 @racket[p] 后不再需要 @racket[x]。
将示例改为为 @racket[p] 注册 finalizer 可以修正问题，但随后 @racket[free] 会在 @racket[p] 上调用而非在 @racket[x] 上。
在修复此问题的过程中，我们可能会小心地记录一条消息用于调试：

@racketblock[
(define @#,racketidfont{_pointer-at-sixteen/free}
  (make-ctype _pointer
              #f
              (lambda (x)
                (let ([p (ptr-add x 16)])
                  (register-finalizer p
                    (lambda (ignored)
                      (log-debug (format "Releasing ~s\n" p))
                      (free x)))
                  p))))
]

现在，我们永远看不到任何记录的事件。问题是 finalizer 是一个保持对 @racket[p] 引用的 closure。
应使用 finalizer 的输入参数而非引用被 final 化的值；只需将上面的 @racket[ignored] 改为 @racket[p] 即可解决问题。
(移除调试消息也可以避免此问题，因为此时 finalization 过程不会在 @racket[p] 上闭包。)}


@deftogether[(
@defproc[(make-late-weak-box [v any/c]) weak-box?]
@defproc[(make-late-weak-hasheq [v any/c]) (and/c hash? hash-eq? hash-weak?)]
)]{

类似于 @racket[make-weak-box] 和 @racket[make-weak-hasheq]，但使用“late”弱引用，
比 @racket[make-weak-box] 或 @racket[make-weak-hasheq] 结果中的引用持续时间更长。
具体而言，如果值已不可达但尚未被使用 @racket[register-finalizer] 安装的 finalizer 处理，
则“late”弱引用保持完整。“late”弱引用旨供此类 finalizer 使用。}


@defproc[(make-sized-byte-string [cptr cpointer?] [length exact-nonnegative-integer?]) 
         bytes?]{

在 Racket 的 @BC[] 实现中返回由给定指针和给定长度构成的字节串；不执行复制。
在 @CS[] 实现中，引发 @racket[exn:fail:unsupported] 异常。

注意，Racket 字节串的表示通常需要在字节串末導(@racket[length] 字节之后)有一个 nul 终止符，
但某些函数使用没有此类终止符的字节串表示——特别是 @racket[bytes-copy]。

如果 @racket[cptr] 是由 @racket[ptr-add] 创建的偏移指针，则偏移量会立即加到指针上。
因此，此函数不能与 @racket[ptr-add] 一起使用来创建 Racket 字节串的子串，
因为偏移指针会指向可回收对象的中间(这是不允许的)。}


@defproc[(void/reference-sink [v any/c] ...) void?]{

返回 @|void-const|，但与调用 @racket[void] 函数不同——编译器可能会优化掉调用并用 @|void-const| 结果替换——
调用 @racket[void/reference-sink] 确保参数在调用返回之前被垃圾回收器视为可达。

@history[#:added "6.10.1.2"]}

@; ----------------------------------------------------------------------

@section{指针结构属性}

@defthing[prop:cpointer struct-type-property?]{

一个 @tech[#:doc reference.scrbl]{structure type property}，使 structure 类型的实例能够作为 C 指针值使用。
属性值必须是一个表示 structure 中不可变字段的精确非负整数(该字段又必须初始化为 C 指针值)，
一个接受 structure 实例并返回 C 指针值的过程，或者一个 C 指针值。

@racket[prop:cpointer] 属性允许 structure 实例透明地用作 C 指针值，
或者允许 C 指针值被可能具有额外值或属性的 structure 透明地包装。}
