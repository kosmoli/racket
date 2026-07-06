#lang scribble/doc
@(require scribble/struct scribble/racket "mz.rkt")

@(define (cont n)
   (make-element variable-color
                 (list "C" (make-element 'subscript (list (format "~a" n))))))

@title[#:tag "contmarks"]{Continuation Marks}

参见 @secref["mark-model"] 和 @secref["prompt-model"] 了解 continuation marks 的一般信息。

对于 key @racket[_k] 和扩展 @cont[0] 的 continuation @racket[_C]，其 continuation marks 列表定义如下：

@itemize[

 @item{如果 @racket[_C] 是空 continuation，则 mark 列表为 @racket[null]。}

 @item{如果 @racket[_C] 的第一帧包含 key 为 @racket[_k] 的 mark @racket[_m]，
 则 @racket[_C] 的 mark 列表为 @racket[(cons _m _lst)]，
 其中 @racket[_lst] 是 @racket[_k] 在 @cont[0] 中的 mark 列表。}

 @item{如果 @racket[_C] 的第一帧不包含 key 为 @racket[_k] 的 mark，
 则 @racket[_C] 的 mark 列表与 @cont[0] 的 mark 列表相同。}

]

@racket[with-continuation-mark] 形式在当前 continuation 的第一帧上安装一个 mark（参见 @secref["wcm"]）。
@racket[current-continuation-marks] 等过程允许检查 mark。

每当 Racket 为 primitive exception 创建异常记录时，
它会用 @racket[(current-continuation-marks)] 的值填充 @racket[continuation-marks] 字段，
从而提供异常发生时 continuation marks 的快照。

当调用 @racket[call-with-current-continuation] 或
@racket[call-with-composable-continuation] 返回的 continuation procedure 时，
它会恢复捕获的 continuation，同时恢复 continuation 帧中的 mark
到调用 @racket[call-with-current-continuation] 或
@racket[call-with-composable-continuation] 时存在的 mark。

@defproc[(continuation-marks [cont (or/c continuation? thread? #f)]
                             [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)])
         continuation-mark-set?]{

返回一个不透明值，包含 continuation @racket[cont] 中所有 key 的 continuation marks 集合（如果 @racket[cont] 是线程，则为其当前 continuation），直到 @racket[prompt-tag] 标记的 prompt。如果 @racket[cont] 为 @racket[#f]，则返回空的 continuation marks 集合。如果 @racket[cont] 是 escape continuation（参见 @secref["prompt-model"]），则当前 continuation 必须扩展 @racket[cont]，否则 @exnraise[exn:fail:contract]。如果 @racket[cont] 不是相对于 @racket[prompt-tag] 捕获的，并且不包含 @racket[prompt-tag] 的 prompt，则 @exnraise[exn:fail:contract]。如果 @racket[cont] 是死线程，则返回空的 continuation marks 集合。}

@defproc[(current-continuation-marks [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)])
         continuation-mark-set?]{

返回一个不透明值，包含当前 continuation 中直到 @racket[prompt-tag] 的所有 key 的 continuation marks 集合。换句话说，它产生与以下代码相同的值：

@racketblock[
(call-with-current-continuation
  (lambda (k) 
    (continuation-marks k prompt-tag))
  prompt-tag)
]}

@defproc[(continuation-mark-set->list
          [mark-set (or/c continuation-mark-set? #f)]
          [key-v any/c]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)])
         list?]{
返回一个新创建的列表，包含 @racket[mark-set] 中 @racket[key-v] 的 mark，该 mark 集合由 @racket[current-continuation-marks] 返回，或使用 @racket[#f] 作为 @racket[(current-continuation-marks prompt-tag)] 的简写。结果列表在第一个点（如果存在）被截断，该点处的 continuation 帧最初由 @racket[prompt-tag] 标记的 prompt 分隔。生成结果所需的时间与 @racket[mark-set] 反映的 continuation 大小成正比。

@history[#:changed "8.0.0.1" @elem{更改为允许 @racket[mark-set] 为 @racket[#f]。}]}


@defproc[(continuation-mark-set->list*
          [mark-set (or/c continuation-mark-set? #f)]
          [key-list (listof any/c)]
          [none-v any/c #f]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)])
         (listof vector?)]{
返回一个新创建的列表，包含 @racket[mark-set] 中 @racket[key-list] 各 key 对应的 mark 向量，直到 @racket[prompt-tag]，其中 @racket[mark-set] 的 @racket[#f] 值等同于 @racket[(current-continuation-marks prompt-tag)]。结果列表中每个向量的长度与 @racket[key-list] 的长度相同，特定位置的值是 @racket[key-list] 中对应 key 的值。仅当 @racket[mark-set] 中的 mark 用于同一 continuation 帧时，多个 key 的值才会出现在单个向量中。@racket[none-v] 参数用于向量元素表示值的缺失。生成结果所需的时间与 @racket[mark-set] 反映的 continuation 大小乘以 @racket[key-list] 的长度成正比。

@history[#:changed "8.0.0.1" @elem{更改为允许 @racket[mark-set] 为 @racket[#f]。}]


@defproc[(continuation-mark-set->iterator
          [mark-set (or/c continuation-mark-set? #f)]
          [key-list (listof any/c)]
          [none-v any/c #f]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)])
         (-> (values (or/c vector? #f) procedure?))]{

类似于 @racket[continuation-mark-set->list*]，但不返回值列表，而是返回一个函数式迭代器，形式为一个过程，返回预期列表的一个元素以及剩余部分的新迭代器函数。当没有更多元素时，迭代器过程返回 @racket[#f] 而不是向量；在这种情况下，返回的迭代器函数与调用的那个相同，不再产生值。每一步所需的时间与 @racket[key-list] 的长度乘以 @racket[mark-set] 反映的 continuation 中各帧之间（包含 @racket[key-list] 中 key 的帧）的大小成正比。

@history[#:added "7.5.0.7"
         #:changed "8.0.0.1" @elem{更改为允许 @racket[mark-set] 为 @racket[#f]。}]


@defproc[(continuation-mark-set-first 
          [mark-set (or/c continuation-mark-set? #f)]
          [key-v any/c]
          [none-v any/c #f]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)])
         any]{
返回 @racket[(continuation-mark-set->list (or mark-set (current-continuation-marks prompt-tag)) key-v prompt-tag)] 将返回的列表的第一个元素，如果结果将是空列表，则返回 @racket[none-v]。

结果以（摊销）常数时间产生。通常，使用 @racket[continuation-mark-set-first] 可以比使用 @racket[continuation-mark-set->list] 或使用 @racket[continuation-mark-set->iterator] 仅迭代一次更快地计算此结果。

虽然 @racket[#f] 和 @racket[(current-continuation-marks prompt-tag)] 对于 @racket[mark-set] 是等价的，但提供 @racket[#f] 作为 @racket[mark-set] 可以启用使其更快的快捷方式。


@defproc[(call-with-immediate-continuation-mark
          [key-v any/c]
          [proc (any/c . -> . any)]
          [default-v any/c #f])
         any]{

使用当前 continuation 第一帧中与 @racket[key-v] 关联的值调用 @racket[proc]（即，如果将 @racket[call-with-immediate-continuation-mark] 的调用替换为使用 @racket[key-v] 作为 key 表达式的 @racket[with-continuation-mark] 形式，该值将被替换的值）。如果第一帧中不存在这样的值，则将 @racket[default-v] 传递给 @racket[proc]。@racket[proc] 在 @racket[call-with-immediate-continuation-mark] 调用的 tail position 中被调用。

此函数可以结合 @racket[with-continuation-mark]、@racket[current-continuation-marks] 和 @racket[continuation-mark-set->list*] 实现，如下所示，但 @racket[call-with-immediate-continuation-mark] 的实现更高效；它仅检查当前 continuation 的第一帧。

@racketblock[
(code:comment "Equivalent, but inefficient:")
(define (call-with-immediate-continuation-mark key-v proc [default-v #f])
  (define private-key (gensym))
  (with-continuation-mark
   private-key #t
   (let ([vecs (continuation-mark-set->list* (current-continuation-marks)
                                             (list key-v private-key)
                                             default-v)])
     (proc (vector-ref (car vecs) 0)))))
]}


@defproc*[([(make-continuation-mark-key) continuation-mark-key?]
           [(make-continuation-mark-key [sym symbol?]) continuation-mark-key?])]{
创建一个 continuation mark key，该 key 与任何其他值（包括先前和将来的 @racket[make-continuation-mark-key] 的结果）都不是 @racket[equal?] 的。continuation mark key 可用作 @racket[with-continuation-mark] 或访问器过程（如 @racket[continuation-mark-set-first]）的 key 参数。与用作 mark key 的其他值不同，mark key 可以被 chaperone 或 impersonate。

可选的 @racket[sym] 参数（如果提供）在打印 continuation mark 时使用。}


@defproc[(continuation-mark-key? [v any/c]) boolean?]{
如果 @racket[v] 是由 @racket[make-continuation-mark-key] 创建的 mark key，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(continuation-mark-set? [v any/c]) boolean?]{
如果 @racket[v] 是由 @racket[continuation-marks] 或 @racket[current-continuation-marks] 创建的 mark set，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(continuation-mark-set->context [mark-set continuation-mark-set?]
                                         [realms? any/c #f])
          list?]{

Returns a list representing an approximate ``@index["stack
dump"]{@as-index{stack trace}}'' for @racket[mark-set]'s continuation.
The list contains pairs if @racket[realms?] is @racket[#f], where the
@racket[car] of each pair contains either @racket[#f] or a symbol for
a procedure name, and the @racket[cdr] of each pair contains either
@racket[#f] or a @racket[srcloc] value for the procedure's source
location (see @secref["linecol"]); the @racket[car] and @racket[cdr]
are never both @racket[#f]. If @racket[realms?] is true, the list
contains 3-element vectors, where the first two elements are like the
values for a pair, and the third element is a realm symbol.

Conceptually, the stack-trace list is the result of
@racket[continuation-mark-set->list] with @racket[mark-set] and
Racket's private key for procedure-call marks. The implementation may
be different, however, and the results may merely approximate the
correct answer. Thus, while the result may contain useful hints to
humans about the context of an expression, it is not reliable enough
for programmatic use.

A stack trace is extracted from an exception and displayed by the
default error display handler (see
@racket[error-display-handler]) for exceptions other than
@racket[exn:fail:user] (see @racket[raise-user-error] in
@secref["errorproc"]).

@examples[
(define (extract-current-continuation-marks key)
  (continuation-mark-set->list
   (current-continuation-marks)
   key))

(with-continuation-mark 'key 'mark
  (extract-current-continuation-marks 'key))

(with-continuation-mark 'key1 'mark1
  (with-continuation-mark 'key2 'mark2
    (list
     (extract-current-continuation-marks 'key1)
     (extract-current-continuation-marks 'key2))))

(with-continuation-mark 'key 'mark1 
  (with-continuation-mark 'key 'mark2 (code:comment @#,t{replaces previous mark})
    (extract-current-continuation-marks 'key)))

(with-continuation-mark 'key 'mark1 
  (list (code:comment @#,t{continuation extended to evaluate the argument})
   (with-continuation-mark 'key 'mark2 
      (extract-current-continuation-marks 'key))))

(let loop ([n 1000])
  (if (zero? n) 
      (extract-current-continuation-marks 'key) 
      (with-continuation-mark 'key n
        (loop (sub1 n)))))
]

@history[#:changed "8.4.0.2" @elem{Added the @racket[realms?] argument.}]}
