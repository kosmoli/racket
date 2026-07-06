#lang scribble/doc
@(require "mz.rkt" 
          scribble/bnf
          (for-label racket/cmdline))

@title[#:tag "logging"]{日志}

一个 @deftech{logger} 接受包含待记录信息的事件，供感兴趣的各方使用。
一个 @deftech{log receiver} 代表一个异步接收已记录事件的感兴趣方。
每个事件都有一个主题和详细级别，@tech{log receiver} 会订阅特定主题或所有主题
在某个详细级别（及更低级别）的日志事件。按详细级别递增的顺序，级别包括
@racket['none]、@racket['fatal]、@racket['error]、@racket['warning]、
@racket['info] 和 @racket['debug]。@racket['none] 级别用于指定 receiver，
在该级别记录的消息永远不会发送给订阅者。

为了帮助组织已记录的事件，@tech{logger} 可以有一个默认主题和/或父 logger。
报告给 logger 的每个事件都会传播到其父 logger（如果有），并且如果消息没有主题，
则事件消息会加上 logger 的主题作为前缀（如果有的话）。此外，从 logger 传播到
其父 logger 的事件可以按级别和主题进行过滤。

在启动时，Racket 创建一个初始 logger，用于记录核心运行时系统的事件。
例如，每次垃圾回收都会报告一个 @racket['debug] 事件（参见
@secref["gc-model"]）。对于这个初始 logger，还会创建两个 log receiver：
一个将事件写入进程的原始错误输出端口，另一个将事件写入系统日志。
每种情况下写入事件的级别是系统特定的，默认值可以通过命令行标志
（参见 @secref["mz-cmdline"]）或通过环境变量来更改：

@itemize[

 @item{如果 @indexed-envvar{PLTSTDERR} 环境变量已定义且未被命令行标志覆盖，
       它决定了将事件传播到原始错误端口的 @tech{log receiver} 的级别。

       环境变量的值可以是一个 @nonterm{level}：
       @litchar{none}、@litchar{fatal}、@litchar{error}、
       @litchar{warning}、@litchar{info} 或 @litchar{debug}（从低详细
       到高详细）；所有在相应详细级别或更低级别的事件都会被打印。在初始
       @nonterm{level} 之后，值可以包含以空白分隔的
       @nonterm{level}@litchar["@"]@nonterm{topic} 形式的规范，
       它仅打印在给定 @nonterm{level} 或更高（其中 @nonterm{topic} 包含除
       空白或 @litchar["@"] 之外的任何字符）与 @nonterm{topic} 匹配的主题事件。
       前导和尾随空白会被忽略。例如，值 @racket["error debug@GC"] 会打印
       @racket['error] 级别及以上的所有事件，但会打印 @racket['GC] 主题
       在 @racket['debug] 级别及更高（包括所有级别）的事件。

       默认值是 @racket["error"]。}

 @item{如果 @indexed-envvar{PLTSTDOUT} 环境变量已定义且未被命令行标志覆盖，
       它决定了将事件传播到原始输出端口的 @tech{log receiver} 的级别。
       可能的值与 @envvar{PLTSTDERR} 相同。

       默认值是 @racket["none"]。}

 @item{如果 @indexed-envvar{PLTSYSLOG} 环境变量已定义且未被命令行标志覆盖，
       它决定了将事件传播到系统日志的 @tech{log receiver} 的级别。
       可能的值与 @envvar{PLTSTDERR} 相同。

       对于 Unix，默认值是 @racket["none"]；对于 Windows 和 Mac OS，
       默认值是 @racket["error"]。}

]

@racket[current-logger] @tech{parameter} 决定了 @racket[log-warning]
等形式使用的 @deftech{current logger}。在启动时，该参数的初始值是初始 logger。
运行时系统有时会使用当前 logger 来报告事件。例如，字节码编译器在检测到
求值时会产生运行时错误的表达式时，有时会报告 @racket['warning] 事件。

@history[#:changed "6.6.0.2" @elem{Prior to version 6.6.0.2, parsing
    of @envvar{PLTSTDERR} and @envvar{PLTSYSLOG} was very strict.
    Leading and trailing whitespace was forbidden, and anything other
    than exactly one space character separating two specifications was
    rejected.}
        #:changed "6.90.0.17" @elem{Added @envvar{PLTSTDOUT}.}]

@; ----------------------------------------
@section{Creating Loggers}

@defproc[(logger? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{logger}，返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(make-logger [topic (or/c symbol? #f) #f]
                      [parent (or/c logger? #f) #f]
                      [propagate-level log-level/c 'debug]
                      [propagate-topic (or/c #f symbol?) #f]
                      ... ...)
         logger?]{

创建一个新的 @tech{logger}，带有可选的主题和父 logger。

可选的 @racket[propagate-level] 和 @racket[propagate-topic] 参数限制了
从新 logger 传播到 @racket[parent]（当 @racket[parent] 不是 @racket[#f] 时）
的事件，其方式与 @racket[make-log-receiver] 中描述 log receiver 事件的方式相同。
默认情况下，所有事件都会传播到 @racket[parent]。

@history[#:changed "6.1.1.3" @elem{Removed an optional argument to
                                   specify a notification callback,
                                   and added @racket[propagate-level] and
                                   @racket[propagate-topic] constraints for
                                   events to propagate.}]}


@defproc[(logger-name [logger logger?]) (or/c symbol? #f)]{

报告 @racket[logger] 的默认主题（如果有的话）。}


@defparam[current-logger logger logger?]{

一个决定 @tech{current logger} 的 @tech{parameter}。}


@defform[(define-logger id maybe-parent)
         #:grammar ([maybe-parent (code:line) (code:line #:parent parent-expr)])
         #:contracts ([parent-expr (or/c logger? #f)])]{

定义 @racketkeywordfont{log-}@racket[id]@racketkeywordfont{-fatal}、
@racketkeywordfont{log-}@racket[id]@racketkeywordfont{-error}、
@racketkeywordfont{log-}@racket[id]@racketkeywordfont{-warning}、
@racketkeywordfont{log-}@racket[id]@racketkeywordfont{-info} 和
@racketkeywordfont{log-}@racket[id]@racketkeywordfont{-debug} 为类似
@racket[log-fatal]、@racket[log-error]、@racket[log-warning]、
@racket[log-info] 和 @racket[log-debug] 的形式。@racket[define-logger]
形式还定义了 @racket[id]@racketidfont{-logger}，它是一个默认主题为
@racket[#,@racket[id]] 的 logger，是 @racket[parent-expr] 结果的子 logger
（如果 @racket[parent-expr] 不产生 @racket[#f]），或者如果未提供
@racket[parent-expr]，则是 @racket[(current-logger)] 的子 logger；
@racketkeywordfont{log-}@racket[id]@racketkeywordfont{-fatal} 等形式
使用这个新的 logger。新的 logger 在 @racket[define-logger] 被求值时创建。

@history[#:changed "7.1.0.9" @elem{Added the @racket[#:parent] option.}]}

@; ----------------------------------------
@section{Logging Events}

@defproc[(log-message [logger logger?]
                      [level log-level/c]
                      [topic (or/c symbol? #f) (logger-name logger)]
                      [message string?]
                      [data any/c #f]
                      [prefix-message? any/c #t])
          void?]{

向 @racket[logger] 报告一个事件，后者又将信息分发给附加到 @racket[logger]
或其祖先的任何对 @racket[level] 或更高的事件感兴趣的 @tech{log receivers}。
如果 @racket[level] 是 @racket['none]，则记录的消息不会发送给任何 receiver。

@tech{Log receivers} 可以基于 @racket[topic] 过滤事件。此外，如果
@racket[topic] 和 @racket[prefix-message?] 都不是 @racket[#f]，
则 @racket[message] 在发送给 receiver 之前会加上主题前缀，后跟 @racket[": "]。

@history[#:changed "6.0.1.10" @elem{Added the @racket[prefix-message?] argument.}
         #:changed "7.2.0.7" @elem{Made the @racket[data] argument optional.}
         #:changed "8.10.0.5" @elem{Changed @racket['none] handling to consistently suppress the message.}]}


@defproc[(log-level? [logger logger?]
                     [level log-level/c]
                     [topic (or/c symbol? #f) #f])
         boolean?]{

报告附加到 @racket[logger] 或其任何祖先的任何 @tech{log receiver}
是否对 @racket[topic] 的 @racket[level] 事件（或可能更低）感兴趣。
如果 @racket[topic] 是 @racket[#f]，则结果表示是否有 @tech{log receiver}
对任何主题的 @racket[level] 事件感兴趣。如果 @racket[level] 是 @racket['none]，
结果总是 @racket[#f]。

使用此函数可以避免在没有 receiver 对信息感兴趣时为 @racket[log-message]
生成事件的工作；然而，此快捷方式已内置到 @racket[log-fatal]、
@racket[log-error]、@racket[log-warning]、@racket[log-info]、
@racket[log-debug] 以及由 @racket[define-logger] 绑定的形式中，
因此不应与这些形式一起使用。

如果垃圾回收确定 log receiver 不再可访问（因此它接收的任何事件信息
将永远无法访问），此函数的结果可能会改变。

@history[#:changed "6.1.1.3" @elem{Added the @racket[topic] argument.}
         #:changed "8.10.0.5" @elem{Changed the result for @racket['none] to be consistently @racket[#f].}]}

@defproc[(log-max-level [logger logger?]
                        [topic (or/c symbol? #f) #f])
         (or/c log-level/c #f)]{

类似于 @racket[log-level?]，但报告 @racket[log-level?] 在 @racket[logger]
和 @racket[topic] 上返回 @racket[#t] 的最高详细级别的日志。如果
@racket[log-level?] 在 @racket[logger] 和 @racket[topic] 上当前对所有级别
都返回 @racket[#f]，则结果为 @racket[#f]。

@history[#:changed "6.1.1.3" @elem{Added the @racket[topic] argument.}]}


@defproc[(log-all-levels [logger logger?])
         (list/c (or/c #f log-level/c)
                 (or/c #f symbol?)
                 ... ...)]{

总结 @racket[log-max-level] 在所有可能的 @tech{interned} 符号上的可能结果。
结果列表包含一个符号和 @racket[#f] 的序列，其中第一、第三等列表元素对应一个级别，
第二、第四等列表元素指示相应的主题。级别是 @racket[log-max-level] 会为该主题
产生的结果，其中 @racket[#f] 主题（始终存在于结果列表中的）的级别指示
任何未出现在列表中的 @tech{interned}-symbol 主题的结果。

结果适合用作 @racket[make-log-receiver] 的参数序列（在 @tech{logger}
参数之后），以创建一个新的 receiver 用于当前在 @racket[logger] 中有 receiver 的事件。

@history[#:added "6.1.1.4"]}


@defproc[(log-level-evt [logger logger?]) evt?]{

创建一个 @tech{synchronizable event}，当 @racket[log-level?]、
@racket[log-max-level] 或 @racket[log-all-levels] 的结果可能不同于
@racket[log-level-evt] 被调用之前时，该事件 @tech{ready for synchronization}。
事件的 @tech{synchronization result} 是事件本身。

事件报告的条件是一个保守近似：即使 @racket[log-level?]、
@racket[log-max-level] 和 @racket[log-all-levels] 的结果未改变，
事件也可能变为 @tech{ready for synchronization}。然而，预期
@racket[log-level-evt] 产生的事件很少会变为就绪状态，因为它们是由
log receiver 的创建触发的。

@history[#:added "6.1.1.4"]}


@deftogether[(
@defform*[[(log-fatal string-expr)
           (log-fatal format-string-expr v ...)]]
@defform*[[(log-error string-expr)
           (log-error format-string-expr v ...)]]
@defform*[[(log-warning string-expr)
           (log-warning format-string-expr v ...)]]
@defform*[[(log-info string-expr)
           (log-info format-string-expr v ...)]]
@defform*[[(log-debug string-expr)
           (log-debug format-string-expr v ...)]]
)]{

使用 @tech{current logger} 记录一个事件，仅当 logger 有对事件感兴趣的 receiver 时
才求值 @racket[string-expr] 或 @racket[(format format-string-expr v ...)]。
此外，当前 continuation 的 @tech{continuation marks} 会与消息字符串一起
发送给 logger。

这些形式便于使用当前 logger，但库通常应使用特定主题的 logger——
通常通过 @racket[define-logger] 生成的类似便捷形式。

对于每个 @racketkeywordfont{log-}@racket[_level]，

@racketblock[
(@#,racketkeywordfont{log-}_level string-expr)
]

等价于

@racketblock[
(let ([l (current-logger)])
  (when (log-level? l '@#,racket[_level])
    (log-message l '@#,racket[_level] string-expr 
                 (current-continuation-marks))))
]

而

@racketblock[
(@#,racketkeywordfont{log-}_level format-string-expr v ...)
]

等价于

@racketblock[
(@#,racketkeywordfont{log-}_level (format format-string-expr v ...))
]}

@; ----------------------------------------
@section[#:tag "receiving-logged-events"]{Receiving Logged Events}

@defproc[(log-receiver? [v any/c]) boolean?]{

如果 @racket[v] 是 @tech{log receiver}，返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(make-log-receiver [logger logger?]
                            [level log-level/c]
                            [topic (or/c #f symbol?) #f]
                            ... ...)
         log-receiver?]{

创建一个 @tech{log receiver} 来接收报告给 @racket[logger] 及其后代的
@racket[level] 及更低详细级别的事件，只要 @racket[topic] 是 @racket[#f]
或事件的主题与 @racket[topic] 匹配。

@tech{log receiver} 是一个 @tech{synchronizable事件}。当接收到日志事件时，
它变为 @tech{ready for synchronization}，因此使用 @racket[sync] 来接收已记录的事件。
@tech{log receiver} 的 @tech{synchronization result} 是一个包含四个值的不可变向量：
事件级别（符号）、事件消息（不可变字符串）、作为最后一个参数传递给
@racket[log-message] 的任意值（当事件被记录时），以及事件主题（符号或 @racket[#f]）。

可以提供多对 @racket[level] 和 @racket[topic] 来指示不同 @racket[topic]
的不同特定 @racket[level]（其中 @racket[topic] 仅对最后一个给定的
@racket[level] 默认为 @racket[#f]）。@racket[#f] @racket[topic] 的 @racket[level]
仅适用于主题与任何其他提供的 @racket[topic] 都不匹配的事件。如果多次提供
相同的 @racket[topic]，则参数列表中最后一个实例提供的 @racket[level] 优先。}


@; ----------------------------------------
@section{Additional Logging Functions}

@note-lib-only[racket/logging]
@(require (for-label racket/logging))
@(define log-eval (make-base-eval))
@examples[#:hidden #:eval log-eval
          (require racket/logging)]

@defproc[(log-level/c [v any/c])
         boolean?]{
如果 @racket[v] 是有效的日志级别（@racket['none]、@racket['fatal]、
@racket['error]、@racket['warning]、@racket['info] 或 @racket['debug]），
返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "6.3"]{}
}

@defproc[(with-intercepted-logging
           [interceptor (-> (vector/c
                              log-level/c
                              string?
                              any/c
                              (or/c symbol? #f))
                             any)]
           [proc (-> any)]
           [#:logger logger logger? #f]
           [level log-level/c]
           [topic (or/c #f symbol?) #f]
           ... ...)
         any]{

运行 @racket[proc]，对 @racket[proc] 执行期间向 @racket[current-logger]
在指定级别和主题发出的任何日志事件调用 @racket[interceptor]。
如果指定了 @racket[#:logger]，则拦截发送给该 logger 的事件，
否则使用当前 logger 的一个新子 logger。
返回 @racket[proc] 返回的任何值。

@examples[
#:eval log-eval
(let ([warning-counter 0])
  (with-intercepted-logging
    (lambda (l)
      (when (eq? (vector-ref l 0) ; actual level
                 'warning)
        (set! warning-counter (add1 warning-counter))))
    (lambda ()
      (log-warning "Warning!")
      (log-warning "Warning again!")
      (+ 2 2))
    'warning)
  warning-counter)]

@history[#:added "6.3" #:changed "6.7.0.1" @elem{Added @racket[#:logger] argument.}]{}}

@defproc[(with-logging-to-port
           [port output-port?] [proc (-> any)]
           [#:logger logger logger? #f]
           [level log-level/c]
           [topic (or/c #f symbol?) #f]
           ... ...)
         any]{

运行 @racket[proc]，输出 @racket[proc] 执行期间向 @racket[current-logger]
在指定级别和主题发出的任何日志。如果指定了 @racket[#:logger]，
则拦截发送给该 logger 的事件，否则使用当前 logger 的一个新子 logger。
返回 @racket[proc] 返回的任何值。

@examples[
#:eval log-eval
(let ([my-log (open-output-string)])
  (with-logging-to-port my-log
    (lambda ()
      (log-warning "Warning World!")
      (+ 2 2))
    'warning)
  (get-output-string my-log))]

@history[#:added "6.3" #:changed "6.7.0.1" @elem{Added @racket[#:logger] argument.}]{}}
