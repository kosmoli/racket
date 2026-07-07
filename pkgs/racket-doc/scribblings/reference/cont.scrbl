#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "cont"]{Continuations}

@guideintro["conts"]{continuations}

关于 continuation 的一般信息，参见 @secref["cont-model"] 和
@secref["prompt-model"]。Racket 对 prompt 和可组合 continuation 的支持
@cite["Flatt07"] 与 Sitaram 的 @racket[%] 和 @racket[fcontrol] 操作符
@cite["Sitaram93"] 非常相似。


Racket 在以下上下文中围绕求值安装 @tech{continuation barrier}，
阻止 full-continuation 跳转到受 barrier 保护的求值上下文中：

@itemize[

 @item{应用 exception handler、error escape handler 或 error display handler
 （参见 @secref["exns"]）；}

 @item{应用 macro transformer（参见 @secref["stxtrans"]）、求值 compile-time 表达式，
 或应用 module name resolver（参见 @secref["modnameresolver"]）；}

 @item{应用 custom-port procedure（参见 @secref["customport"]）、
 event guard procedure（参见 @secref["sync"]）或 parameter guard
 procedure（参见 @secref["parameters"]）；}

 @item{应用 security-guard procedure（参见 @secref["securityguards"]）；}

 @item{应用 will procedure（参见 @secref["willexecutor"]）；或}

 @item{从独立 Racket 命令行求值或加载代码（参见 @secref["running-sa"]）。}

]

此外，Racket 的扩展可能在其他上下文中安装 barrier。最后，
@racket[call-with-continuation-barrier] 在应用与当前 continuation 之间
安装一个 thunk barrier。


@defproc[(call-with-continuation-prompt 
          [proc procedure?]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)]
          [handler (or/c procedure? #f) #f]
          [arg any/c] ...)
         any]{

将 @racket[proc] 应用于给定的 @racket[arg]，并将当前 continuation 扩展一个 prompt。
该 prompt 由 @racket[prompt-tag] 标记，它必须是 @racket[default-continuation-prompt-tag]
（默认值）或 @racket[make-continuation-prompt-tag] 的结果。对
@racket[call-with-continuation-prompt] 的调用返回 @racket[proc] 的结果。

@racket[handler] 参数指定一个 handler procedure，当安装的 prompt 是
@racket[abort-current-continuation] 调用（使用 @racket[prompt-tag]）的目标时，
该 procedure 在 @racket[call-with-continuation-prompt] 调用的 tail position 被调用；
@racket[abort-current-continuation] 的剩余参数被提供给 handler procedure。
如果 @racket[handler] 是 @racket[#f]，默认 handler 接受单个 @racket[_abort-thunk]
参数并调用 @racket[(call-with-continuation-prompt _abort-thunk prompt-tag #f)]；
也就是说，默认 handler 重新安装 prompt 并继续执行给定的 thunk。}

@defproc[(abort-current-continuation
          [prompt-tag any/c]
          [v any/c] ...)
         any]{

将当前 continuation 重置为当前 continuation 中由 @racket[prompt-tag] 标记的最近 prompt；
如果不存在这样的 prompt，则 @exnraise[exn:fail:contract:continuation]。@racket[v] 作为参数
传递给目标 prompt 的 handler procedure。

传递给 abort 的 @racket[v] 的协议是特定于 @racket[prompt-tag] 的。当
@racket[abort-current-continuation] 与 @racket[(default-continuation-prompt-tag)]
一起使用时，通常应提供单个 thunk，适合与默认 prompt handler 一起使用。类似地，
当 @racket[call-with-continuation-prompt] 与 @racket[(default-continuation-prompt-tag)]
一起使用时，关联的 handler 通常应接受单个 thunk 参数。

每个 @tech{thread} 的 continuation 都以 @racket[(default-continuation-prompt-tag)]
的 prompt 开始，该 prompt 使用默认 handler，接受单个 thunk 来应用（保持 prompt 不变）。}

@defproc*[([(make-continuation-prompt-tag) continuation-prompt-tag?]
           [(make-continuation-prompt-tag [name symbol?]) continuation-prompt-tag?])]{

创建一个 prompt tag，它不 @racket[equal?] 于任何其他值（包括先前或未来的
@racket[make-continuation-prompt-tag] 结果）。可选的 @racket[name] 参数（如果提供）
指定 prompt tag 的名称，用于打印或 @racket[object-name]。

@history[#:changed "7.9.0.13" @elem{The @racket[name] argument
          gives the name of the prompt tag.}]
}

@defproc[(default-continuation-prompt-tag) continuation-prompt-tag?]{

返回一个常量 prompt tag，在每个线程的 continuation 起始处安装一个 prompt；
每个线程的初始 prompt 的 handler 接受任意数量的值并返回。
@racket[default-continuation-prompt-tag] 的结果是任何接受 prompt tag 的过程的默认 tag。}

@defproc[(call-with-current-continuation 
          [proc (continuation? . -> . any)]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)]) 
         any]{

捕获当前 continuation 直到由 @racket[prompt-tag] 标记的最近 prompt；
如果不存在这样的 prompt，则 @exnraise[exn:fail:contract:continuation]。
被截断的 continuation 只包含自 prompt 以来安装的 continuation marks 和
@racket[dynamic-wind] frame。

捕获的 continuation 被传递给 @racket[proc]，该 procedure 在
@racket[call-with-current-continuation] 调用的 tail position 被调用。

如果传递给 @racket[proc] 的 continuation 参数被应用，则它会移除当前 continuation
到由 @racket[prompt-tag] 标记的最近 prompt 的部分（不包括 prompt；如果不存在这样的 prompt，
则 @exnraise[exn:fail:contract:continuation]），或到当前 continuation 与捕获的
continuation 共享的最近 continuation frame（如果有的话）— 以先发生的那个为准。
在移除 continuation frame 时，@racket[dynamic-wind] 的 @racket[_post-thunk] 被执行。
最后，捕获的 continuation（未共享的部分）被追加到剩余的 continuation，并应用
@racket[dynamic-wind] 的 @racket[_pre-thunk]。

传递给被应用过程的参数成为恢复后的 continuation 的结果值。特别是，如果传递了多个参数，
则 continuation 接收多个结果。

如果在应用时间，用替换当前 continuation 的 continuation 会引入 @tech{continuation barrier}，
则 @exnraise[exn:fail:contract:continuation]。

Continuation 可以从捕获它的线程（参见 @secref["threads"]）以外的线程调用。}

@defproc[(call/cc
          [proc (continuation? . -> . any)]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)]) 
         any]{

@racket[call/cc] 绑定是 @racket[call-with-current-continuation] 的别名。
}

@defproc[(call-with-composable-continuation 
          [proc (continuation? . -> . any)]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)]) 
         any]{

类似于 @racket[call-with-current-continuation]，但应用生成的 continuation procedure
不会移除当前 continuation 的任何部分。相反，应用总是用捕获的 continuation
扩展当前 continuation（不安装除捕获的 continuation 中那些以外的任何 prompt）。

当调用 @racket[call-with-composable-continuation] 时，如果在 continuation 中
@racket[prompt-tag] 标记的最近 prompt 之前出现 continuation barrier，
则 @exnraise[exn:fail:contract:continuation]（因为尝试应用 continuation 总会失败）。}

@defproc[(call-with-escape-continuation 
          [proc (continuation? . -> . any)]) 
         any]{

类似于 @racket[call-with-current-continuation]，但 @racket[proc] 不在 tail position 被调用，
并且提供给 @racket[proc] 的 continuation procedure 只能在 @racket[call-with-escape-continuation]
调用的 dynamic extent 内调用。

从 @racket[call-with-escape-continuation] 获得的 continuation 实际上是一种 prompt。
Escape continuation 主要为了向后兼容而提供，因为它们早于 Racket 中的通用 prompt。
在 Racket 的 @tech{BC} 实现中，@racket[call-with-escape-continuation] 比
@racket[call-with-current-continuation] 更高效地实现，因此 @racket[call-with-escape-continuation]
有时可以替换 @racket[call-with-current-continuation] 以在那些较旧的 Racket 变体中提高性能。}

@defproc[(call/ec
          [proc (continuation? . -> . any)]) 
         any]{

@racket[call/ec] 绑定是 @racket[call-with-escape-continuation] 的别名。
}

@defproc[(call-in-continuation [k continuation?]
                               [proc (-> any)])
         any]{

类似于应用 continuation @racket[k]，但不是向 continuation 传递值，
而是用 @racket[k] 作为调用的 continuation 来调用 @racket[proc]（因此
@racket[proc] 的结果被返回到 continuation）。如果 @racket[k] 是
composable continuation，则对 @racket[proc] 的调用的 continuation
是用 @racket[k] 扩展的当前 continuation。

@mz-examples[
(+ 1
   (call/cc (lambda (k)
              (call-in-continuation k (lambda () 4)))))
(+ 1
   (call/cc (lambda (k)
              (let ([n 0])
                (dynamic-wind
                 void
                 (lambda ()
                   (code:comment @#,elem{@racket[n] accessed after post thunk})
                   (call-in-continuation k (lambda () n)))
                 (lambda ()
                   (set! n 4)))))))
(+ 1
   (with-continuation-mark
    'n 4
     (call/cc (lambda (k)
                (with-continuation-mark
                 'n 0
                 (call-in-continuation
                  k
                  (lambda ()
                    (code:comment @#,elem{@racket['n] mark accessed in continuation})
                    (continuation-mark-set-first #f 'n))))))))
]

@history[#:added "7.6.0.17"]}

@defform[(let/cc k body ...+)]{
等价于 @racket[(call/cc (lambda (k) body ...))]。
}

@defform[(let/ec k body ...+)]{
等价于 @racket[(call/ec (lambda (k) body ...))]。
}

@defproc[(call-with-continuation-barrier [thunk (-> any)]) any]{

在应用与当前 continuation 之间以 @tech{continuation barrier} 调用 @racket[thunk]。
@racket[thunk] 的结果是 @racket[call-with-continuation-barrier] 调用的结果。}


@defproc[(continuation-prompt-available?
          [prompt-tag continuation-prompt-tag?]
          [cont continuation? (call/cc values)]) 
         any]{

如果 @racket[cont]（必须是 continuation）包含由 @racket[prompt-tag] 标记的 prompt，
则返回 @racket[#t]，否则返回 @racket[#f]。
}

@defproc[(continuation? [v any/c]) boolean?]{
如果 @racket[v] 是由 @racket[call-with-current-continuation]、
@racket[call-with-composable-continuation] 或 @racket[call-with-escape-continuation]
产生的 continuation，则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(continuation-prompt-tag? [v any/c]) boolean?]{
如果 @racket[v] 是由 @racket[default-continuation-prompt-tag] 或
@racket[make-continuation-prompt-tag] 产生的 continuation prompt tag，
则返回 @racket[#t]。}

@defproc[(dynamic-wind [pre-thunk (-> any)]
                       [value-thunk (-> any)]
                       [post-thunk (-> any)]) 
          any]{

按顺序应用其三个 thunk 参数。@racket[dynamic-wind] 表达式的值是 @racket[value-thunk] 返回的值。
@racket[pre-thunk] 过程在调用 @racket[value-thunk] 之前调用，@racket[post-thunk] 在
@racket[value-thunk] 返回之后调用。@racket[dynamic-wind] 的特殊性质在控制跳入或跳出
@racket[value-thunk] 应用时显现（无论是由于 prompt abort 还是 continuation 调用）：
每次控制跳入 @racket[value-thunk] 应用时，@racket[pre-thunk] 被调用；每次控制跳出
@racket[value-thunk] 时，@racket[post-thunk] 被调用。（对于跳入或跳出 @racket[pre-thunk]
和 @racket[post-thunk] 应用不执行特殊处理。）

当 @racket[dynamic-wind] 为正常求值 @racket[value-thunk] 而调用 @racket[pre-thunk] 时，
@racket[pre-thunk] 应用的 continuation 调用 @racket[value-thunk]（使用 @racket[dynamic-wind]
的特殊跳转处理），然后调用 @racket[post-thunk]。类似地，@racket[post-thunk] 应用的
continuation 将前一个 @racket[value-thunk] 应用的值返回给整个 @racket[dynamic-wind]
应用的 continuation。

当由于 continuation 跳转而调用 @racket[pre-thunk] 时，对 @racket[pre-thunk] 调用的
continuation

@itemize[

 @item{跳转到更深层嵌套的 @racket[pre-thunk]（如果有的话），或跳转到目标 continuation；然后}

 @item{在目标 continuation 中与外层 @racket[dynamic-wind] 调用相同地继续
 （即，匹配原始 @racket[dynamic-wind] 调用的 continuation 直到界定捕获的外层 prompt）。}

]

通常，由于第一部分的跳转，这个 continuation 的第二部分永远不会到达。然而，第二部分是相关的，
因为它使得跳转能够逃逸包含在目标 continuation 中 @racket[dynamic-wind] 调用的
continuation 中的 continuation。此外，这意味着 @racket[pre-thunk] 的 continuation marks
（参见 @secref["contmarks"]）和 parameterization（参见 @secref["parameters"]）对应于
外层 @racket[dynamic-wind] 调用的那些。然而，@racket[pre-thunk] 调用被
@racket[parameterize-break]ed 以禁用 breaks（参见 @secref["breakhandler"]）。

类似地，当由于 continuation 跳转而调用 @racket[post-thunk] 时，调用 @racket[post-thunk]
的 continuation 跳转到较不深层嵌套的 @racket[post-thunk]（如果有的话），或跳转到保护目标的
@racket[pre-thunk]（如果有的话），或跳转到目标 continuation，然后在跳转的源 continuation
中与外层 @racket[dynamic-wind] 调用相同地继续。对于 @racket[pre-thunk]，@racket[dynamic-wind]
调用的 continuation marks 和 parameterization 对 @racket[post-thunk] 都适用，
只是该调用进一步被 @racket[parameterize-break]ed 以禁用 breaks。

在这两种情况下，跳转的目标在每次 @racket[pre-thunk] 或 @racket[post-thunk] 完成后重新计算。
当 prompt-delimited continuation（参见 @secref["prompt-model"]）在 @racket[post-thunk] 中被捕获时，
它可能被界定和实例化，使得当 continuation 被应用时，跳转的目标与捕获 continuation 时的目标不同。
甚至可能没有适当的目标，如果在恢复后相关的 prompt 或 escape continuation 不在 continuation 中；
在这种情况下，@racket[pre-thunk] 或 @racket[post-thunk] 的 continuation 的第一步可能引发异常。

@examples[
(let ([v (let/ec out 
           (dynamic-wind
            (lambda () (display "in ")) 
            (lambda () 
              (display "pre ") 
              (display (call/cc out))
              #f) 
            (lambda () (display "out "))))])  
  (when v (v "post "))) 

(let/ec k0
  (let/ec k1
    (dynamic-wind
     void
     (lambda () (k0 'cancel))
     (lambda () (k1 'cancel-canceled)))))

(let* ([x (make-parameter 0)]
       [l null]
       [add (lambda (a b)
              (set! l (append l (list (cons a b)))))])
  (let ([k (parameterize ([x 5])
             (dynamic-wind
                 (lambda () (add 1 (x)))
                 (lambda () (parameterize ([x 6])
                              (let ([k+e (let/cc k (cons k void))])
                                (add 2 (x))
                                ((cdr k+e))
                                (car k+e))))
                 (lambda () (add 3 (x)))))])
    (parameterize ([x 7])
      (let/cc esc
        (k (cons void esc)))))
  l)
]}

@; ----------------------------------------------------------------------

@include-section["control-lib.scrbl"]
