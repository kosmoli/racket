#lang scribble/doc
@(require "mz.rkt" (for-label racket/struct))

@title{Printer Extension}

@defthing[gen:custom-write any/c]{

一个 @tech{generic interface}（参见 @secref["struct-generics"]），提供
一个 @racket[write-proc] 方法，供默认打印机用于 @racket[display]、
@racket[write] 或 @racket[print] 结构体类型的实例。

@racket[write-proc] 方法接收三个参数：要打印的结构体、目标 port 和一个
参数——在 @racket[write] 模式下为 @racket[#t]，在 @racket[display] 模式下
为 @racket[#f]，或在 @racket[print] 模式下为 @racket[0] 或 @racket[1] 以
表示当前的 @tech{quoting depth}。procedure 应使用 @racket[write]、
@racket[display]、@racket[print]、@racket[fprintf]、@racket[write-special]
等将值打印到给定的 port。

@tech{port write handler}、@tech{port display handler} 和
@tech{print handler} 是为传给 custom-write procedure 的 port 特别配置的。
通过 @racket[display]、@racket[write] 或 @racket[print] 向该 port 打印
会递归地打印 value 并带有 sharing 注解。为避免递归打印（即不考虑与当前正在打印的
value 的 sharing），改用字符串或 pipe 打印，然后使用 @racket[write-string]
或 @racket[write-special] 将结果传送到目标 port。要向 custom-write procedure
给定的 port 以外的 port 递归打印，请将给定 port 的 write handler、display handler
和 print handler 复制到其他 port。

传给 @racket[write-proc] 的 port 不一定是实际的目标 port。具体来说，为了检测
cycle、sharing 和引用模式（在 @racket[print] 模式下），打印机使用一个记录
递归打印信息的 port 调用 custom-write procedure，不会保留任何其他输出。这个
信息收集阶段需要打印相同的对象（在 @racket[eq?] 意义上），以便记录的
信息可以与打印的值相关联。

递归打印操作可能会触发从 @racket[write-proc] 调用中退出。例如，在 pretty-printing
过程中，当一次初步的打印尝试超出行宽时可能会退出；或者在受限宽度的错误输出打印时
也可能退出。

以下是一个 @racket[tuple] 类型的示例定义，它包含一个 @racket[write-proc] procedure，
在 @racket[write] 和 @racket[print] 模式下使用尖括号打印 tuple 的 list 内容，
在 @racket[display] 模式下不使用括号。tuple 的元素会被递归打印，以便能够
表示 graph 和 cycle 结构。

@examples[
 (eval:no-prompt
  (define (tuple-print tuple port mode)
    (when mode (write-string "<" port))
    (let ([l (tuple-ref tuple)]
          [recur (case mode
                   [(#t) write]
                   [(#f) display]
                   [else (lambda (p port) (print p port mode))])])
       (unless (zero? (vector-length l))
         (recur (vector-ref l 0) port)
         (for-each (lambda (e)
                     (write-string ", " port)
                     (recur e port))
                   (cdr (vector->list l)))))
    (when mode (write-string ">" port))))

(eval:no-prompt
 (struct tuple (ref)
         #:methods gen:custom-write
         [(define write-proc tuple-print)]))

(display (tuple #(1 2 "a")))

(print (tuple #(1 2 "a")))

(let ([t (tuple (vector 1 2 "a"))])
  (vector-set! (tuple-ref t) 0 t)
  (write t))
]

@racket[make-constructor-style-printer] 函数可以帮助实现 @racket[write-proc]，
如本例所示：

@examples[
 (eval:no-prompt (require racket/struct))
 (eval:no-prompt
  (struct point (x y)
    #:methods gen:custom-write
    [(define write-proc
       (make-constructor-style-printer
        (lambda (obj) 'point)
        (lambda (obj) (list (point-x obj) (point-y obj)))))]))

  (print (point 1 2))

  (write (point 1 2))]

@history[#:changed "8.7.0.5"
         @elem{添加了检查，使得省略
               @racket[_write-proc] 现在是语法错误。}]
}

@defthing[prop:custom-write struct-type-property?]{

一个 @tech{structure type property}（参见 @secref["structprops"]），提供一个
与 @racket[gen:custom-write] 的 @racket[write-proc] 对应的 procedure。
不鼓励使用 @racket[prop:custom-write] property；应改用
@racket[gen:custom-write] @tech{generic interface}。
}

@defproc[(custom-write? [v any/c]) boolean?]{

如果 @racket[v] 具有 @racket[prop:custom-write] property 则返回 @racket[#t]，
否则返回 @racket[#f]。}


@defproc[(custom-write-accessor [v custom-write?])
         (custom-write? output-port? (or/c #t #f 0 1) . -> . any)]{

返回与 @racket[v] 关联的 custom-write procedure。}

@deftogether[(
@defthing[prop:custom-print-quotable struct-type-property?]
@defthing[custom-print-quotable? struct-type-property?]
@defthing[custom-print-quotable-accessor struct-type-property?]
)]{

一个 property 以及关联的 predicate 和 accessor。该 property value 是
@racket['self]、@racket['never]、@racket['maybe] 或 @racket['always]
之一。当结构体除了 @racket[prop:custom-write] property value 之外还具有此 property 时，
该 property value 会影响 @racket[print] 模式下的打印；参见 @secref["printing"]。
当 value 不具有 @racket[prop:custom-print-quotable] 时，其效果等同于具有
@racket['self] property value，这既适用于自引用形式，也适用于不可读的
打印形式。
}
