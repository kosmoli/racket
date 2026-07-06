#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "parameters"]{Parameters}

@guideintro["parameterize"]{parameters}

参见 @secref["parameter-model"] 了解 parameter 模型的基本信息。Parameters 对应于 Scsh @cite["Gasbichler02"] 中的 @defterm{preserved thread fluids}。

要以线程和 continuation 友好的方式参数化代码，请使用 @racket[parameterize]。@racket[parameterize] form 为其 body 表达式的 dynamic extent 引入一个新的 @tech{thread cell}。

创建新线程时，新线程的初始 continuation 的 @tech{parameterization} 是创建者线程的 @tech{parameterization}。由于每个 parameter 的 @tech{thread cell} 是 @tech{preserved} 的，新线程"继承"其创建线程的 parameter 值。当 continuation 从一个线程移动到另一个线程时，使用 @racket[parameterize] 引入的设置会有效地随 continuation 一起移动。

相反，直接赋值给 parameter（通过调用 parameter 过程并传入一个值）会更改 thread cell 中的值，因此仅更改当前线程的设置。因此，就内存管理器而言，只要 continuation 可达，通过 @racket[parameterize] 与 parameter 关联的原始值仍然保持可达，即使该 parameter 被 mutate。

@defproc[(make-parameter [v any/c]
                         [guard (or/c (any/c . -> . any) #f) #f]
                         [name symbol? 'parameter-procedure]
                         [realm symbol? 'racket])
         parameter?]{

返回一个新的 parameter 过程。该 parameter 的值在所有线程中初始化为 @racket[v]。

如果 @racket[guard] 不是 @racket[#f]，则它用作 parameter 的 guard 过程。guard 过程接受一个 argument。每当 parameter 过程应用于一个 argument 时，该 argument 被传递给 guard 过程。guard 过程返回的结果用作新的 parameter 值。guard 过程可以引发异常以拒绝 parameter 值的更改。@racket[guard] 不应用于初始 @racket[v]。

@racket[name] 参数用作 @racket[object-name] 报告的 parameter 过程名称，@racket[realm] 用作 @racket[procedure-realm] 报告的 parameter 过程 realm。

@history[#:changed "7.4.0.6" @elem{添加了 @racket[name] 参数。}
         #:changed "8.4.0.2" @elem{添加了 @racket[realm] 参数。}]}

@defform[(parameterize ([parameter-expr value-expr] ...)
           body ...+)
         #:contracts
         ([parameter-expr parameter?])]{

@guideintro["parameterize"]{@racket[parameterize]}

@racket[parameterize] 表达式的结果是最后一个 @racket[body] 的结果。@racket[parameter-expr] 确定要设置的 parameters，@racket[value-expr] 确定在求值 @racket[body] 时要安装的相应值。@racket[parameter-expr] 和 @racket[value-expr] 从左到右（交错）求值，然后在 continuation 中将 parameter 绑定到包含 @racket[value-expr] 值的 preserved thread cells；每个 @racket[parameter-expr] 的结果在绑定前用 @racket[parameter?] 检查。最后一个 @racket[body] 相对于整个 @racket[parameterize] form 处于 tail 位置。

在 @racket[parameterize] 表达式的 dynamic extent 之外，parameters 保持绑定到其他 thread cells。因此，当控制退出 @racket[parameterize] 表达式时，旧的 parameter 设置会被恢复。

如果在 @racket[parameterize] 求值期间捕获了 continuation，调用 continuation 会有效地重新引入 @tech{parameterization}，因为 parameterization 通过 continuation mark（参见 @secref["contmarks"]）使用私有 key 与 continuation 关联。

@examples[
(parameterize ([exit-handler (lambda (x) 'no-exit)])
  (exit))

(define p1 (make-parameter 1))
(define p2 (make-parameter 2))
(parameterize ([p1 3]
               [p2 (p1)])
  (cons (p1) (p2)))

(let ([k (let/cc out
           (parameterize ([p1 2])
             (p1 3)
             (cons (let/cc k
                     (out k))
                   (p1))))])
  (if (procedure? k)
      (k (p1))
      k))

(define ch (make-channel))
(parameterize ([p1 0])
  (thread (lambda ()
            (channel-put ch (cons (p1) (p2))))))
(channel-get ch)

(define k-ch (make-channel))
(define (send-k)
  (parameterize ([p1 0])
    (thread (lambda ()
              (let/ec esc
                (channel-put ch
                             ((let/cc k
                                (channel-put k-ch k)
                                (esc)))))))))
(send-k)
(thread (lambda () ((channel-get k-ch)
                    (let ([v (p1)])
                      (lambda () v)))))
(channel-get ch)
(send-k)
(thread (lambda () ((channel-get k-ch) p1)))
(channel-get ch)
]}


@defform[(parameterize* ((parameter-expr value-expr) ...)
           body ...+)]{

类似于 @racket[let*] 相比于 @racket[let]，@racket[parameterize*] 等同于嵌套的单 parameter @racket[parameterize] form。

}


@defproc[(make-derived-parameter [parameter parameter?]
                                 [guard (any/c . -> . any)]
                                 [wrap (any/c . -> . any)]
                                 [name symbol? (object-name parameter)]
                                 [realm symbol? (procedure-realm parameter)])
         parameter?]{

返回一个 parameter 过程，设置或检索与 @racket[parameter] 相同的值，但带有：

@itemize[

 @item{设置 parameter 时应用 @racket[guard]（在 @racket[parameter] 关联的任何 guard 之前），以及}

 @item{获取 parameter 值时应用 @racket[wrap]。}

]

@racket[name] 参数用作 @racket[object-name] 报告的 parameter 过程名称，@racket[realm] 用作 @racket[procedure-realm] 报告的 parameter 过程 realm。如果目标是仅替换 @racket[parameter] 的名称或 realm，则为 @racket[guard] 和 @racket[wrap] 提供 @racket[values]。

另请参见 @racket[chaperone-procedure]，它也可用于保护 parameter 过程。

@history[#:changed "8.15.0.4" @elem{添加了 @racket[name] 和 @racket[realm] 参数。}]}


@defproc[(parameter? [v any/c]) boolean?]{

如果 @racket[v] 是 parameter 过程，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(parameter-procedure=? [a parameter?] [b parameter?]) boolean?]{

如果 parameter 过程 @racket[a] 和 @racket[b] 始终使用相同的 guard 修改相同的 parameter（尽管可能使用不同的 @tech{chaperones}），则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(current-parameterization) parameterization?]{返回当前 continuation 的 @tech{parameterization}。}

@defproc[(call-with-parameterization [parameterization parameterization?]
                                     [thunk (-> any)])
         any]{

以 @racket[parameterization] 作为当前 @tech{parameterization}（通过 tail 调用）调用 @racket[thunk]。}

@defproc[(parameterization? [v any/c]) boolean?]{

如果 @racket[v] 是 @racket[current-parameterization] 返回的 @tech{parameterization}，则返回 @racket[#t]，否则返回 @racket[#f]。}
