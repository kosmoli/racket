#lang scribble/doc
@(require scribble/bnf "mz.rkt"
          (for-label racket/fixnum
                     syntax/srcloc))

@title[#:tag "exns"]{Exceptions}

@guideintro["exns"]{exceptions}

See @secref["exn-model"] for information on the Racket exception
model. It is based on a proposal by Friedman, Haynes, and Dybvig
@cite["Friedman95"].

Whenever a primitive error occurs in Racket, an exception is
raised.  The value that is passed to the current @tech{exception
handler} for a primitive error is always an instance of the
@racket[exn] structure type. Every @racket[exn] structure value has a
@racket[message] field that is a string, the primitive error message.
The default exception handler recognizes exception values with the
@racket[exn?] predicate and passes the error message to the current
@tech{error display handler} (see @racket[error-display-handler]).

Primitive procedures that accept a procedure argument with a
particular required arity (e.g., @racket[call-with-input-file],
@racket[call/cc]) check the argument's arity immediately, raising
@racket[exn:fail:contract] if the arity is incorrect.

@;----------------------------------------------------------------------
@section[#:tag "err-msg-conventions"]{Error Message Conventions}

Racket's @deftech{error message convention} is to produce error
messages with the following shape:

@racketblock[
  @#,nonterm{srcloc}: @#,nonterm{name}: @#,nonterm{message}@#,tt{;}
   @#,nonterm{continued-message} ...
    @#,nonterm{field}: @#,nonterm{detail}
    ...
]

The message starts with an optional source location, @nonterm{srcloc},
which is followed by a colon and space when present. The message
continues with an optional @nonterm{name} that usually identifies the
complaining function, syntactic form, or other entity, but may also
refer to an entity being complained about; the @nonterm{name} is also
followed by a colon and space when present.

The @nonterm{message} should be relatively short, and it should be
largely independent of specific values that triggered the error. More
detailed explanation that requires multiple lines should continue with
each line indented by a single space, in which case @nonterm{message}
should end in a semi-colon (but the semi-colon should be omitted if
@nonterm{continued-message} is not present). Message text should be
lowercase---using semi-colons to separate sentences if needed,
although long explanations may be better deferred to extra fields.

Specific values that triggered the error or other helpful information
should appear in separate @nonterm{field} lines, each of which is
indented by two spaces. If a @nonterm{detail} is especially long or
takes multiple lines, it should start on its own line after the
@nonterm{field} label, and each of its lines should be indented by
three spaces. Field names should be all lowercase.

A @nonterm{field} name should end with @litchar{...} if the field
provides relatively detailed information that might be distracting in
common cases but useful in others. For example, when a contract
failure is reported for a particular argument of a function, other
arguments to the function might be shown in an ``other arguments...''
field. The intent is that fields whose names end in @litchar{...}
might be hidden by default in an environment such as DrRacket.

Make @nonterm{field} names as short as possible, relying on
@nonterm{message} or @nonterm{continued message} text to clarify the
meaning for a field. For example, prefer ``given'' to ``given turtle''
as a field name, where @nonterm{message} is something like ``given
turtle is too sleepy'' to clarify that ``given'' refers to a turtle.

@;------------------------------------------------------------------------
@section[#:tag "errorproc"]{Raising Exceptions}

@defproc[(raise [v any/c] [barrier? any/c #t]) any]{

Raises an exception, where @racket[v] represents the exception being
raised. The @racket[v] argument can be anything; it is passed to the
current @tech{exception handler}.

If @racket[barrier?] is true, then the call to the @tech{exception
handler} is protected by a @tech{continuation barrier}, so that
multiple returns/escapes are impossible. All exceptions raised by
@racketmodname[racket] functions effectively use @racket[raise] with a
@racket[#t] value for @racket[barrier?].

Breaks are disabled from the time the exception is raised until the
exception handler obtains control, and the handler itself is
@racket[parameterize-break]ed to disable breaks initially; see
@secref["breakhandler"] for more information on breaks.

@examples[
(with-handlers ([number? (lambda (n)
                           (+ n 5))])
  (raise 18 #t))
(struct my-exception exn:fail:user ())
(with-handlers ([my-exception? (lambda (e)
                                 #f)])
  (+ 5 (raise (my-exception
               "failed"
               (current-continuation-marks)))))
(eval:error (raise 'failed #t))
]}

@defproc*[([(error [message-sym symbol?]) any]
           [(error [message-str string?] [v any/c] ...) any]
           [(error [who-sym symbol?] [format-str string?] [v any/c] ...) any])]{


引发异常 @racket[exn:fail]，其中包含一个错误字符串。
不同形式以不同方式生成错误字符串：
@itemize[


 @item{@racket[(error message-sym)] 通过将 @racket["error: "]
  与 @racket[message-sym] 的字符串形式连接来创建消息字符串。谨慎使用此形式。}

 @item{@racket[(error message-str v ...)] 通过将 @racket[message-str]
  与 @racket[v] 的字符串版本 (由当前错误值转换处理器生成；参见
  @racket[error-value->string-handler]) 连接来创建消息字符串。
  每个 @racket[v] 前插入一个空格。
  谨慎使用此形式，因为它不太符合
  Racket 的 @tech{错误消息约定}；
  考虑使用 @racket[raise-arguments-error]。}

 @item{@racket[(error who-sym format-str v ...)] 创建一个
 消息字符串，等价于由以下代码创建的字符串：
  @racketblock[
  (format (string-append "~s: " format-str) who-sym v ...)
  ]


 如果可能，请改用 @racket[raise-argument-error] 等函数，
它们构造的消息遵循 Racket 的 @tech{错误消息约定}。}
]


在所有情况下，构造的消息字符串被传递给
@racket[make-exn:fail]，然后引发生成的异常。
@examples[
(eval:error (error 'failed))
(eval:error (error "failed" 23 'pizza (list 1 2 3)))
(eval:error (error 'method-a "failed because ~a" "no argument supplied"))
]}


@defproc*[([(raise-user-error [message-sym symbol?]) any]
           [(raise-user-error [message-str string?] [v any/c] ...) any]
           [(raise-user-error [who-sym symbol?] [format-str string?] [v any/c] ...) any])]{


类似于 @racket[error]，但使用
@racket[make-exn:fail:user] 而不是 @racket[make-exn:fail] 来构造异常。
默认 @tech{错误显示处理器} 不会为
@racket[exn:fail:user] 异常显示"堆栈跟踪" (参见 @secref["contmarks"])，因此
@racket[raise-user-error] 应用于面向最终用户的错误。}

@defproc*[([(raise-argument-error [name symbol?] [expected string?] [v any/c]) any]
           [(raise-argument-error [name symbol?] [expected string?] [bad-pos exact-nonnegative-integer?] [v any/c] ...) any])]{


创建一个 @racket[exn:fail:contract] 值并将其作为异常 @racket[raise]。
@racket[name] 参数用作错误消息中源过程的名称。
@racket[expected] 参数用作预期合约的描述 (即作为字符串，
但该字符串旨在包含合约表达式)。

在第一种形式中，@racket[v] 是过程接收到的、不具有预期类型的值。

在第二种形式中，坏参数由索引
@racket[bad-pos] 指示 (从 @math{0} 计数)，所有原始
参数 @racket[v] 都按顺序提供。生成的错误
消息会命名坏参数并列出其他参数。如果
@racket[bad-pos] 不小于 @racket[v] 的数量，则
@exnraise[exn:fail:contract]。

@racket[raise-argument-error] 生成的错误消息通过
@racket[error-contract->adjusted-string] 然后通过
@racket[error-message->adjusted-string] 进行调整，
使用默认的 @racket['racket] 领域。
@examples[
(define (feed-machine bits)
  (unless (integer? bits)
    (raise-argument-error 'feed-machine "integer?" bits))
  "fed the machine")
(eval:error (feed-machine 'turkey))
(define (feed-cow animal)
  (unless (eq? animal 'cow)
    (raise-argument-error 'feed-cow "'cow" animal))
  "fed the cow")
(eval:error (feed-cow 'turkey))
(define (feed-animals cow sheep goose cat)
  (unless (eq? goose 'goose)
    (raise-argument-error 'feed-animals "'goose" 2 cow sheep goose cat))
  "fed the animals")
(eval:error (feed-animals 'cow 'sheep 'dog 'cat))
]}


@defproc*[([(raise-argument-error* [name symbol?] [realm symbol?] [expected string?] [v any/c]) any]
           [(raise-argument-error* [name symbol?] [realm symbol?] [expected string?] [bad-pos exact-nonnegative-integer?] [v any/c] ...) any])]{


类似于 @racket[raise-argument-error]，但使用给定的 @racket[realm]
进行错误消息调整。
@history[#:added "8.4.0.2"]}


@defproc*[([(raise-result-error [name symbol?] [expected string?] [v any/c]) any]
           [(raise-result-error [name symbol?] [expected string?] [bad-pos exact-nonnegative-integer?] [v any/c] ...) any])]{

Like @racket[raise-argument-error], but the error message describe @racket[v]
as a ``result'' instead of an ``argument.''}

@defproc*[([(raise-result-error* [name symbol?] [realm symbol?] [expected string?] [v any/c]) any]
           [(raise-result-error* [name symbol?] [realm symbol?] [expected string?] [bad-pos exact-nonnegative-integer?] [v any/c] ...) any])]{


类似于 @racket[raise-result-error]，但使用给定的 @racket[realm]
进行错误消息调整。
@history[#:added "8.4.0.2"]}

@defproc[(raise-arguments-error [name symbol?] [message string?]
                                [field string?] [v any/c] 
                                ... ...) any]{


创建一个 @racket[exn:fail:contract] 值并将其作为异常 @racket[raise]。
@racket[name] 用作错误消息中源过程的名称。
@racket[message] 是错误消息；如果 @racket[message] 包含换行符，
每行额外内容应适当缩进 (每行开头额外一个空格)，但不应以换行符结尾。
每个 @racket[field] 必须有对应的 @racket[v]，
两者在错误消息中独占一行；每个 @racket[v] 使用错误值转换处理器格式化
(参见 @racket[error-value->string-handler])，除非 @racket[v] 是
@tech{unquoted-printing string}，在这种情况下字符串内容直接
@racket[display] 而不使用错误值转换处理器。
当错误值转换处理器生成的字符串或 unquoted-printing string 中包含换行符
但不以换行符开头时，该字符串将另起一行，
并在每行前添加额外空格来缩进字符串内容。
The error message generated by @racket[raise-arguments-error] is adjusted
via @racket[error-message->adjusted-string] using the default
@racket['racket] realm.

@examples[
 (eval:error
  (raise-arguments-error 'eat
                         "fish is smaller than its given meal"
                         "fish" 12
                         "meal" 13))
 (eval:error
  (raise-arguments-error 'eat
                         "not edible"
                         "candidate" (unquoted-printing-string
                                      "a banana made\nof wax")))
]

@history[#:changed "8.15.0.2" @elem{Added indentation for @racket[v] strings
                                    that contain newlines.}]}


@defproc[(raise-arguments-error* [name symbol?] [realm symbol?] [message string?]
                                 [field string?] [v any/c] 
                                 ... ...) any]{


类似于 @racket[raise-arguments-error]，但使用给定的 @racket[realm]
进行错误消息调整。
@history[#:added "8.4.0.2"
         #:changed "8.15.0.2" @elem{Added indentation for @racket[v] strings
                                    that contain newlines.}]}


@defproc[(raise-range-error [name symbol?] [type-description string?] [index-prefix string?]
                            [index exact-integer?] [in-value any/c]
                            [lower-bound exact-integer?] [upper-bound exact-integer?]
                            [alt-lower-bound (or/c #f exact-integer?) #f])
         any]{


创建一个 @racket[exn:fail:contract] 值并将其作为异常 @racket[raise]，
以报告越界错误。@racket[type-description]
字符串描述索引用于选择元素的值，
@racket[index-prefix] 是 ``index'' 一词的前缀。
@racket[index] 参数是被拒绝的索引。
@racket[in-value] 参数是索引所指的值。
@racket[lower-bound] 和 @racket[upper-bound]
参数指定有效的索引范围 (含边界)；如果 @racket[upper-bound]
低于 @racket[lower-bound]，则该值被描述为 ``empty''。
如果 @racket[alt-lower-bound]
不是 @racket[#f]，并且 @racket[index] 在 @racket[alt-lower-bound]
和 @racket[upper-bound] 之间，则错误报告为 @racket[index] 小于
``starting'' 索引 @racket[lower-bound]。

由于 @racket[upper-bound] 是包含性的，
典型值是集合大小的 @emph{减一}——
例如 @racket[(sub1 (vector-length _vec))]、
@racket[(sub1 (length _lst))] 等。

@racket[raise-range-error] 生成的错误消息通过
@racket[error-message->adjusted-string] 进行调整，
使用默认的 @racket['racket] 领域。
@examples[
(eval:error (raise-range-error 'vector-ref "vector" "starting " 5 #(1 2 3 4) 0 3))
(eval:error (raise-range-error 'vector-ref "vector" "ending " 5 #(1 2 3 4) 0 3))
(eval:error (raise-range-error 'vector-ref "vector" "" 3 #() 0 -1))
(eval:error (raise-range-error 'vector-ref "vector" "ending " 1 #(1 2 3 4) 2 3 0))
]}

@defproc[(raise-range-error* [name symbol?] [realm symbol?] [type-description string?] [index-prefix string?]
                             [index exact-integer?] [in-value any/c]
                             [lower-bound exact-integer?] [upper-bound exact-integer?]
                             [alt-lower-bound (or/c #f exact-integer?) #f])
         any]{


类似于 @racket[raise-range-error]，但使用给定的 @racket[realm]
进行错误消息调整。
@history[#:added "8.4.0.2"]}


@defproc*[([(raise-type-error [name symbol?] [expected string?] [v any/c]) any]
           [(raise-type-error [name symbol?] [expected string?] [bad-pos exact-nonnegative-integer?] [v any/c] ...) any])]{


类似于 @racket[raise-argument-error]，但使用 Racket 旧的格式约定，
其中 @racket[expected] 用作"类型"描述而不是合约表达式。
请改用 @racket[raise-argument-error] 或 @racket[raise-result-error]。

@racket[raise-type-error] 生成的错误消息通过
@racket[error-message->adjusted-string] 进行调整，
使用默认的 @racket['racket] 领域。}

@defproc[(raise-mismatch-error [name symbol?] [message string?] [v any/c] 
                               ...+ ...+) any]{


类似于 @racket[raise-arguments-error]，但使用 Racket 旧的格式约定，
在第一个 @racket[message] 字符串后紧跟一个必需的 @racket[v]，
后续的 @racket[message] 字符串被拼接到消息中，不带换行或空格。
请改用 @racket[raise-arguments-error]。

@racket[raise-mismatch-error] 生成的错误消息通过
@racket[error-message->adjusted-string] 进行调整，
使用默认的 @racket['racket] 领域。

@history[#:changed "8.15.0.2" @elem{Added indentation for @racket[v] strings
                                    that contain newlines.}]}


@defproc[(raise-arity-error [name (or/c symbol? procedure?)]
                            [arity-v (or/c exact-nonnegative-integer?
                                           arity-at-least?
                                           (listof
                                            (or/c exact-nonnegative-integer?
                                                  arity-at-least?)))]
                            [arg-v any/c] ...)
         any]{


创建一个 @racket[exn:fail:contract:arity] 值并将其作为异常 @racket[raise]。
@racket[name] 用于错误消息中源过程的名称。

@racket[arity-v] 值必须是 @racket[procedure-arity] 的可能结果，
但不一定需要规范化 (有关规范化元数的详细信息，请参见 @racket[procedure-arity?])；
@racket[raise-arity-error] 会规范化元数并在错误消息中使用规范化形式。
如果 @racket[name] 是一个过程，则其实际元数被忽略。

@racket[arg-v] 参数是实际提供的参数，
它们会显示在错误消息中
(使用错误值转换处理器；参见 @racket[error-value->string-handler])；
此外，提供的 @racket[arg-v] 的数量会在消息中明确提及。

@racket[raise-arity-error] 生成的错误消息通过
@racket[error-message->adjusted-string] 进行调整，
使用默认的 @racket['racket] 领域。
@examples[
(eval:error (raise-arity-error 'unite (arity-at-least 13) "Virginia" "Maryland"))
]}


@defproc[(raise-arity-error* [name (or/c symbol? procedure?)]
                             [realm symbol?]
                             [arity-v (or/c exact-nonnegative-integer?
                                            arity-at-least?
                                            (listof
                                             (or/c exact-nonnegative-integer?
                                                   arity-at-least?)))]
                             [arg-v any/c] ...)
         any]{



类似于 @racket[raise-arity-error]，但使用给定的 @racket[realm]
进行错误消息调整。

@history[#:added "8.4.0.2"]}

@defproc[(raise-arity-mask-error [name (or/c symbol? procedure?)]
                                 [mask exact-integer?]
                                 [arg-v any/c] ...)
         any]{


与 @racket[raise-arity-error] 相同，但使用
@racket[procedure-arity-mask] 描述的元数表示。
@history[#:added "7.0.0.11"]}

@defproc[(raise-arity-mask-error* [name (or/c symbol? procedure?)]
                                  [realm symbol?]
                                  [mask exact-integer?]
                                  [arg-v any/c] ...)
         any]{


类似于 @racket[raise-arity-mask-error]，但使用给定的 @racket[realm]
进行错误消息调整。

@history[#:added "8.4.0.2"]}

@defproc[(raise-result-arity-error [name (or/c symbol? #f)]
                                   [arity-v exact-nonnegative-integer?]
                                   [detail-str (or/c string? #f)]
                                   [result-v any/c] ...)
         any]{


类似于 @racket[raise-arity-error]，但报告"结果"不匹配而不是"参数"不匹配。
@racket[name] 参数可以是 @racket[#f] 以省略错误的初始来源。
@racket[detail-str] 参数如果非 @racket[#f]，应该是一个以换行符开头的字符串，
因为它被添加到生成的错误消息的末尾附近。

@racket[raise-result-arity-error] 生成的错误消息通过
@racket[error-message->adjusted-string] 进行调整，
使用默认的 @racket['racket] 领域。
@examples[
(eval:error (raise-result-arity-error 'let-values 2 "\n  in: example" 'a 2.0 "three"))
]

@history[#:added "6.90.0.26"]}


@defproc[(raise-result-arity-error* [name (or/c symbol? #f)]
                                    [realm symbol?]
                                    [arity-v exact-nonnegative-integer?]
                                    [detail-str (or/c string? #f)]
                                    [result-v any/c] ...)
         any]{


类似于 @racket[raise-result-arity-error]，但使用给定的 @racket[realm]
进行错误消息调整。

@history[#:added "8.4.0.2"]}

@defproc[(raise-syntax-error [name (or/c symbol? #f)]
                             [message string?]
                             [expr any/c #f]
                             [sub-expr any/c #f]
                             [extra-sources (listof syntax?) null]
                             [message-suffix string? ""]
                             [#:exn exn
                              (-> string?
                                  continuation-mark-set?
                                  (listof syntax?)
                                  exn:fail:syntax?)
                              exn:fail:syntax])
         any]{


创建一个 @racket[exn:fail:syntax?] 值并将其作为异常 @racket[raise]。
宏使用此过程来报告语法错误。

当提供了 @racket[expr] 时，@racket[name] 参数通常为 @racket[#f]；
下文有更详细的描述。
@racket[message] 用作错误消息的主体；如果
@racket[message] 包含换行符，每行新内容应适当缩进 (开头一个空格)，
且不应以换行符结尾。

可选的 @racket[expr] 参数是错误的源语法
对象或 S-expression (但表达式 @racket[#f] 不能
单独表示自身；它必须包装为 @tech{语法对象})。
可选的 @racket[sub-expr] 参数是
@racket[expr] 内的语法对象或 S-expression (同样，@racket[#f] 不能表示自身)，
用于更精确地定位错误。如果
@racket[error-print-source-location] 为 @racket[#t]，两者都可能出现在生成的错误消息文本中。
当至少有一个是语法对象且 @racket[error-print-source-location] 为 @racket[#t] 时，
错误消息文本中的源位置信息同样从
@racket[sub-expr] 或 @racket[expr] 中提取。

如果提供了 @racket[sub-expr] 且不是 @racket[#f]，则它 (以语法形式)
用于生成的异常记录的 @racket[exprs] 字段，
否则如果提供了 @racket[expr] 且不是 @racket[#f] 则使用 @racket[expr]。
无论哪种情况，语法对象都被 @racket[cons] 到
@racket[extra-sources] 上以产生 @racket[exprs] 字段，
或者如果 @racket[expr] 和 @racket[sub-expr] 都未提供且不是 @racket[#f]，
则直接使用 @racket[extra-sources] 作为 @racket[exprs]。
在 @racket[sub-expr] 或 @racket[expr] 将包含在 @racket[exprs] 中
但无法转换为语法对象 (因为它包含循环) 的特殊情况下，
@racket[extra-sources] 参数也直接用于 @racket[exprs]。

生成的错误消息中使用的形式名称是通过组合
@racket[name]、@racket[expr] 和
@racket[sub-expr] 参数来确定的：
@itemize[


  @item{当 @racket[name] 是 @racket[#f]，且 @racket[expr] 是
  一个标识符或是一个以标识符为其第一个元素的语法对时，
  错误消息中的形式名称就是该标识符的符号。}

 @item{当 @racket[name] 是 @racket[#f] 且 @racket[expr] 不是
  标识符也不是以标识符为其第一个元素的语法对时，
  错误消息中的形式名称为 @racket["?"]。}

 @item{当 @racket[name] 是一个符号时，该符号
  用作生成的错误消息中的形式名称。}
]


@racket[message-suffix] 字符串被追加到错误消息的末尾。
如果不是 @racket[""]，它通常应以换行符和两个空格开头，
以向消息添加额外字段 (参见 @secref["err-msg-conventions"])。

如果指定了 @racket[exn]，它应该是一个构造函数或函数，
其签名与 @racket[exn:fail:syntax] 构造函数相同。
@examples[
  (eval:error (raise-syntax-error #f "bad syntax" '(bad syntax)))
  (eval:error (raise-syntax-error #f "unbound identifier" 'unbound-id #:exn exn:fail:syntax:unbound))
]

@history[#:changed "6.90.0.18" @elem{Added the @racket[message-suffix] optional argument.}
         #:changed "8.4.0.6" @elem{Added the @racket[exn] optional argument.}]}


@deftogether[(
@defproc[(unquoted-printing-string? [v any/c]) boolean?]
@defproc[(unquoted-printing-string [s string?]) unquoted-printing-string?]
@defproc[(unquoted-printing-string-value [ups unquoted-printing-string?]) string?]
)]{


@deftech{unquoted-printing string} 包装一个字符串，
并以与该字符串 @racket[display] 相同的方式进行
@racket[print]、@racket[write] 和 @racket[display]。
@tech{unquoted-printing string} 特别适用于
@racket[raise-arguments-error]，作为字段"值"，
使字面文本作为字段内容打印。

@racket[unquoted-printing-string?] 过程返回 @racket[#t]
如果 @racket[v] 是 @tech{unquoted-printing string}，否则返回 @racket[#f]。
@racket[unquoted-printing-string] 创建一个
@tech{unquoted-printing string} 值来封装字符串 @racket[s]，
而 @racket[unquoted-printing-string-value] 返回
@tech{unquoted-printing string} 中的字符串。
@history[#:added "6.10.0.2"]}

@;------------------------------------------------------------------------

@section{处理异常}
@defproc[(call-with-exception-handler [f (any/c . -> . any)] [thunk (-> any)]) any]{

Installs @racket[f] as the @tech{exception handler} for the
@tech{dynamic extent} of the call to @racket[thunk]. If an exception
is raised during the evaluation of @racket[thunk] (in an extension of
the current continuation that does not have its own exception
handler), then @racket[f] is applied to the @racket[raise]d value in
the continuation of the @racket[raise] call (but the continuation is 
normally extended
with a @tech{continuation barrier}; see @secref["prompt-model"] and
@racket[raise]).

Any procedure that takes one argument can be an exception handler.
Normally, an exception handler escapes from the context of the
@racket[raise] call via @racket[abort-current-continuation] or some other escape
mechanism. To propagate an exception to the ``previous'' exception
handler---that is, the exception handler associated with the rest of
the continuation after the point where the called exception handler
was associated with the continuation---an exception handler can simply
return a result instead of escaping, in which case the @racket[raise] call
propagates the value to the previous exception handler (still in the
dynamic extent of the call to @racket[raise], and under the same
barrier, if any). If an exception handler returns a result and no
previous handler is available, the @tech{uncaught-exception handler}
is used.

A call to an exception handler is @racket[parameterize-break]ed to
disable breaks, and it is wrapped with
@racket[call-with-exception-handler] to install an exception handler
that reports both the original and newly raised exceptions via the
@tech{error display handler} and then escapes via the @tech{error
escape handler}.}


@defparam[uncaught-exception-handler f (any/c . -> . any)]{

A @tech{parameter} that determines an @deftech{uncaught-exception handler} used by
@racket[raise] when the relevant continuation has no exception handler
installed with @racket[call-with-exception-handler] or
@racket[with-handlers]. Unlike exception handlers installed with
@racket[call-with-exception-handler], the uncaught-exception
handler must not return a value when called by @racket[raise]; if
it returns, an exception is raised (to be handled by an exception
handler that reports both the original and newly raised exception).

The default uncaught-exception handler prints an error message using
the current @tech{error display handler} (see @racket[error-display-handler]),
unless the argument to the handler is an instance of @racket[exn:break:hang-up].
If the argument to the handler is an instance of @racket[exn:break:hang-up]
or @racket[exn:break:terminate], the default uncaught-exception handler
then calls the @tech{exit handler} with @racket[1], which normally exits
or escapes. For any argument, the default uncaught-exception handler
then escapes by calling the current @tech{error escape handler} (see
@racket[error-escape-handler]). The call to each handler is
@racket[parameterize]d to set @racket[error-display-handler] to the
default @tech{error display handler}, and it is @racket[parameterize-break]ed
to disable breaks. The call to the @tech{error escape handler} is further
parameterized to set @racket[error-escape-handler] to the default
@tech{error escape handler}; if the @tech{error escape handler} returns, then
the default @tech{error escape handler} is called.

When the current @tech{error display handler} is the default handler, then the
error-display call is parameterized to install an emergency error
display handler that logs an error (see @racket[log-error]) and never
fails.}


@defform[(with-handlers ([pred-expr handler-expr] ...)
           body ...+)]{


依次求值每个 @racket[pred-expr]，然后依次求值每个
@racket[handler-expr]，然后在其动态范围内使用新的异常处理器求值 @racket[body]。

新的异常处理器仅在某个 @racket[pred-expr] 过程应用于异常时返回真值时才处理该异常，
否则从 @racket[with-handlers] 表达式的续延中调用异常处理器
(通过再次引发异常)。
如果异常由某个 @racket[handler-expr] 过程处理，
则整个 @racket[with-handlers] 表达式的结果就是处理器的返回值。

当在 @racket[body] 的求值过程中引发异常时，
每个谓词过程 @racket[pred-expr] 被应用于异常值；
如果某个谓词返回真值，则调用相应的 @racket[handler-expr] 过程，
以异常作为参数。谓词按照指定的顺序进行尝试。

在调用任何谓词或处理器过程之前，整个 @racket[with-handlers] 表达式的续延被恢复，
但也被 @racket[parameterize-break] 以禁用中断。
因此，在谓词和处理器过程中默认禁用中断
(参见 @secref["breakhandler"])，
且异常处理器是来自 @racket[with-handlers] 表达式续延的那个。

@racket[exn:fail?] 过程作为处理器谓词用于捕获所有错误异常非常有用。
避免使用 @racket[(lambda (x) #t)] 作为谓词，
因为 @racket[exn:break] 异常通常不应被捕获
(除非它将被重新引发以协作式中断)。
同样要小心捕获并丢弃异常，因为丢弃错误消息会使调试不必要地困难；
与其丢弃错误消息，不如考虑通过 @racket[log-error] 或
@racket[define-logger] 创建的日志记录形式来记录它。
@examples[
  (with-handlers ([exn:fail:syntax?
                   (λ (e) (displayln "got a syntax error"))])
    (raise-syntax-error #f "a syntax error"))
  (with-handlers ([exn:fail:syntax?
                   (λ (e) (displayln "got a syntax error"))]
                  [exn:fail?
                   (λ (e) (displayln "fallback clause"))])
    (raise-syntax-error #f "a syntax error"))
]}

@defform[(with-handlers* ([pred-expr handler-expr] ...)
           body ...+)]{

Like @racket[with-handlers], but if a @racket[handler-expr] procedure
is called, breaks are not explicitly disabled, and the handler call is
in tail position with respect to the @racket[with-handlers*] form.}

@;------------------------------------------------------------------------

@section{配置默认处理}
@defparam[error-escape-handler proc (-> any)]{

A parameter for the @deftech{error escape handler}, which takes no
arguments and escapes from the dynamic context of an exception.  The
default error escape handler escapes using
@racket[(abort-current-continuation (default-continuation-prompt-tag)
void)].

The error escape handler is normally called directly by an exception
handler, in a @tech{parameterization} that sets the @tech{error
display handler} and @tech{error escape handler} to the default
handlers, and it is normally @racket[parameterize-break]ed to disable
breaks. To escape from a run-time error in a different context, use
@racket[raise] or @racket[error].

Due to a @tech{continuation barrier} around exception-handling calls,
an error escape handler cannot invoke a full continuation that was
created prior to the exception, but it can abort to a prompt (see
@racket[call-with-continuation-prompt]) or invoke an escape
continuation (see @racket[call-with-escape-continuation]).}

@defparam[error-display-handler proc (string? any/c . -> . any)]{

A parameter for the @deftech{error display handler}, which is called
by the default exception handler with an error message and the
exception value. More generally, the handler's first argument is a
string to print as an error message, and the second is a value
representing a raised exception. An error display handler can
print errors in different ways, but it should always print to the
current error port.

The default error display handler @racket[display]s its first argument
to the current error port (determined by the
@racket[current-error-port] parameter) and extracts a stack trace (see
@racket[continuation-mark-set->context]) to display from the second
argument if it is an @racket[exn] value but not an
@racket[exn:fail:user] value.

@margin-note{The default error display handler in DrRacket also uses
the second argument to highlight source locations.}

To report a run-time error, use @racket[raise] or procedures like
@racket[error], instead of calling the error display handler
directly.}

@defparam[error-print-width width (and/c exact-integer? (>=/c 3))]{

A parameter whose value is used as the maximum number of characters
used to print a Racket value that is embedded in a primitive error
message.}

@defparam[error-print-context-length cnt exact-nonnegative-integer?]{

A parameter whose value is used by the default @tech{error display handler}
as the maximum number of lines of context (or ``stack trace'') to
print; a single ``...'' line is printed if more lines are available
after the first @racket[cnt] lines. A @racket[0] value for
@racket[cnt] disables context printing entirely.}


@defboolparam[error-print-source-location include?]{

A @tech{parameter} that controls whether read and syntax error messages
include source information, such as the source line and column or the
expression.  This parameter also controls the error message when a
module-defined variable is accessed before its definition is executed;
the parameter determines whether the message includes a module
name. Only the message field of an @racket[exn:fail:read],
@racket[exn:fail:syntax], or @racket[exn:fail:contract:variable]
structure is affected by the parameter. The default is @racket[#t].}


@defparam[error-value->string-handler proc (any/c exact-nonnegative-integer?
                                                  . -> .
                                                  string?)]{


一个 @tech{参数}，确定 @deftech{错误值转换处理器}，
用于打印嵌入在原始错误消息中的 Racket 值。

传递给处理器的整数参数指定了在结果字符串中表示值时应该使用的最大字符数。
默认错误值转换处理器将值 @racket[print] 到一个字符串中
(使用当前的 @tech{全局端口打印处理器}；参见 @racket[global-port-print-handler])。
如果打印形式太长，打印形式会被截断，返回字符串的最后三个字符设置为 ``...''。

当由类似 @racket[error] 的函数调用时，如果错误值转换处理器返回的字符串比请求的长，
该字符串会被截断到请求的长度。如果返回的是字节字符串而不是字符串，
则使用 @racket[bytes->string/utf-8] 进行转换。
如果返回任何其他非字符串值，则使用字符串 @racket["..."]。
如果在处理器返回之前需要生成原始错误字符串，则使用默认错误值转换处理器。

对错误值转换处理器的调用被 @racket[parameterize] 以重新安装默认错误值转换处理器，
并启用不可读值的打印 (参见 @racket[print-unreadable])。

如果 @racket[error-value->string-handler] 生成的字符串包含换行符但
不以换行符开头，则使用该字符串的上下文将按需在每个换行符后添加空格或缩进。
例如，@racket[raise-argument-error] 在每行开头添加三个空格的缩进。
@history[#:changed "8.15.0.2" @elem{Added indentation convention for string
                                    results that contain newlines.}]}


@defparam[error-syntax->string-handler proc (any/c (or/c exact-nonnegative-integer? #f)
                                                  . -> .
                                                  string?)]{


一个 @tech{参数}，确定 @deftech{错误语法转换处理器}，
用于打印嵌入在错误消息中的语法形式，
例如当 @racket[error-print-source-location] 为 @racket[#t] 时来自
@racket[raise-syntax-error] 的消息。

传递给该处理器的参数类似于通过
@racket[error-value->string-handler] 配置的 @tech{错误值转换处理器} 的参数，
不同之处在于可以用 @racket[#f] 代替长度整数，
表示打印形式不应被截断。第一个参数通常是
@tech{语法对象}，但就像 @racket[raise-syntax-error] 接受其他 S-expression 一样，
错误语法转换处理器也必须处理不是语法对象的表示。
@history[#:added "8.2.0.8"]}


@defparam[error-syntax->name-handler proc (syntax? . -> . (or/c symbol? #f))]{


一个 @tech{参数}，确定 @deftech{错误语法名称处理器}，
当 @racket[raise-syntax-error] 以 @racket[#f] 作为第一个参数、
语法对象作为第三个参数被调用时，用于提取语法形式的名称。

传递给处理器的参数是提供给 @racket[raise-syntax-error] 作为其第三个参数的语法对象。
如果可以从语法对象中提取名称，则结果必须是符号，否则为 @racket[#f]。
@history[#:added "8.15.0.2"]}


@defparam[error-syntax->srcloc-handler proc (any/c . -> . (or/c srcloc? #f))]{


一个 @tech{参数}，确定 @deftech{错误语法源位置处理器}，
当 @racket[raise-syntax-error] 被调用时，用于提取语法形式的源位置。

传递给处理器的参数通常是语法对象，例如当它由
@racket[source-location->prefix] 调用时，
但它可以是表达式的其他表示，如 @racket[raise-syntax-error] 的第三或第四个参数。
结果应该是一个 @racket[srcloc] 实例或 @racket[#f]，
表示该参数没有可用的源位置。
@history[#:added "9.2.0.3"]}


@defparam[error-module-path->string-handler proc (any/c exact-nonnegative-integer?
                                                        . -> .
                                                        string?)]{


类似于 @racket[error-value->string-handler]，但用于模块路径。
默认将模块路径 @racket[write] 为字符串。
@history[#:added "8.16.0.3"]}

@;------------------------------------------------------------------------

@section{内置异常类型}
@defstruct[exn ([message string?]
                [continuation-marks continuation-mark-set?])
           #:inspector #f]{


异常的基 @tech{结构类型}。@racket[message]
字段包含错误消息，@racket[continuation-marks]
字段包含在异常被引发之前由 @racket[(current-continuation-marks)] 生成的值。

由 Racket 引发的异常在 @racket[exn] 下形成一个层次结构：
@racketblock[
exn
  exn:fail
    exn:fail:contract
      exn:fail:contract:arity
      exn:fail:contract:divide-by-zero
      exn:fail:contract:non-fixnum-result
      exn:fail:contract:continuation
      exn:fail:contract:variable
    exn:fail:syntax
      exn:fail:syntax:unbound
      exn:fail:syntax:missing-module
    exn:fail:read
      exn:fail:read:eof
      exn:fail:read:non-char
    exn:fail:filesystem
      exn:fail:filesystem:exists
      exn:fail:filesystem:version
      exn:fail:filesystem:errno
      exn:fail:filesystem:missing-module
    exn:fail:network
      exn:fail:network:errno
    exn:fail:out-of-memory
    exn:fail:unsupported
    exn:fail:user
  exn:break
    exn:break:hang-up
    exn:break:terminate
]}

@defstruct[(exn:fail exn) ()
           #:inspector #f]{

Raised for exceptions that represent errors, as opposed to
@racket[exn:break].}


@defstruct[(exn:fail:contract exn:fail) ()
           #:inspector #f]{

Raised for errors from the inappropriate run-time use of a function or
syntactic form.}

@defstruct[(exn:fail:contract:arity exn:fail:contract) ()
           #:inspector #f]{

Raised when a procedure is applied to the wrong number of arguments.}

@defstruct[(exn:fail:contract:divide-by-zero exn:fail:contract) ()
           #:inspector #f]{

Raised for division by exact zero.}

@defstruct[(exn:fail:contract:non-fixnum-result exn:fail:contract) ()
           #:inspector #f]{

Raised by functions like @racket[fx+] when the result would not be a fixnum.}

@defstruct[(exn:fail:contract:continuation exn:fail:contract) ()
           #:inspector #f]{

Raised when a continuation is applied where the jump would cross a
continuation barrier.}

@defstruct[(exn:fail:contract:variable exn:fail:contract) ([id symbol?])
           #:inspector #f]{

Raised for a reference to a not-yet-defined @tech{top-level variable}
or @tech{module-level variable}.}

@defstruct[(exn:fail:syntax exn:fail) ([exprs (listof syntax?)])
           #:inspector #f]{

Raised for a syntax error that is not a @racket[read] error. The
@racket[exprs] indicate the relevant source expressions,
least-specific to most-specific.

This structure type implements the @racket[prop:exn:srclocs] property.}

@defstruct[(exn:fail:syntax:unbound exn:fail:syntax) ()
           #:inspector #f]{

Raised by @racket[#%top] or @racket[set!] for an
unbound identifier within a module.}

@defstruct[(exn:fail:syntax:missing-module exn:fail:syntax) ([path module-path?])
           #:inspector #f]{

Raised by the default @tech{module name resolver} or default
@tech{load handler} to report a module path---a reported in the
@racket[path] field---whose implementation file cannot be
found.

The default @tech{module name resolver} raises this exception only
when it is given a syntax object as its second argument, and the
default @tech{load handler} raises this exception only when the value
of @racket[current-module-path-for-load] is a syntax object (in which
case both the @racket[exprs] field and the @racket[path] field
are determined by the syntax object).

This structure type implements the @racket[prop:exn:missing-module] property.}

@defstruct[(exn:fail:read exn:fail) ([srclocs (listof srcloc?)])
           #:inspector #f]{

Raised for a @racket[read] error. The @racket[srclocs] indicate the
relevant source expressions.}

@defstruct[(exn:fail:read:eof exn:fail:read) ()
           #:inspector #f]{

Raised for a @racket[read] error, specifically when the error is due
to an unexpected end-of-file.}

@defstruct[(exn:fail:read:non-char exn:fail:read) ()
           #:inspector #f]{

Raised for a @racket[read] error, specifically when the error is due
to an unexpected non-character (i.e., ``special'') element in the
input stream.}

@defstruct[(exn:fail:filesystem exn:fail) ()
           #:inspector #f]{

Raised for an error related to the filesystem (such as a file not
found).}

@defstruct[(exn:fail:filesystem:exists exn:fail:filesystem) ()
           #:inspector #f]{

Raised for an error when attempting to create a file that exists
already.}

@defstruct[(exn:fail:filesystem:version exn:fail:filesystem) ()
           #:inspector #f]{

Raised for a version-mismatch error when loading an extension.}

@defstruct[(exn:fail:filesystem:errno exn:fail:filesystem) ([errno (cons/c exact-integer? (or/c 'posix 'windows 'gai))])
           #:inspector #f]{

Raised for a filesystem error for which a system error code is
available. The symbol part of an @racket[errno] field indicates the
category of the error code: @racket['posix] indicates a C/Posix
@tt{errno} value, @racket['windows] indicates a Windows system error
code (under Windows, only), and @racket['gai] indicates a
@tt{getaddrinfo} error code (which shows up only in
@racket[exn:fail:network:errno] exceptions for operations that resolve
hostnames, but is allowed in @racket[exn:fail:filesystem:errno]
instances for consistency).

See also @racket[exn-classify-errno].}

@defstruct[(exn:fail:filesystem:missing-module exn:fail:filesystem) ([path module-path?])
           #:inspector #f]{

Raised by the default @tech{module name resolver} or default
@tech{load handler} to report a module path---a reported in the
@racket[path] field---whose implementation file cannot be
found.

The default @tech{module name resolver} raises this exception only
when it is @emph{not} given a syntax object as its second argument, and the
default @tech{load handler} raises this exception only when the value
of @racket[current-module-path-for-load] is @emph{not} a syntax object.

This structure type implements the @racket[prop:exn:missing-module] property.}

@defstruct[(exn:fail:network exn:fail) ()
           #:inspector #f]{

Raised for TCP and UDP errors.}

@defstruct[(exn:fail:network:errno exn:fail:network) ([errno (cons/c exact-integer? (or/c 'posix 'windows 'gai))])
           #:inspector #f]{

Raised for a TCP or UDP error for which a system error code is
available, where the @racket[errno] field is as for
@racket[exn:fail:filesystem:errno].

See also @racket[exn-classify-errno].}


@defstruct[(exn:fail:out-of-memory exn:fail) ()
           #:inspector #f]{

Raised for an error due to insufficient memory, in cases where sufficient
memory is at least available for raising the exception.}

@defstruct[(exn:fail:unsupported exn:fail) ()
           #:inspector #f]{

Raised for an error due to an unsupported feature on the current
platform or configuration.}

@defstruct[(exn:fail:user exn:fail) ()
           #:inspector #f]{

Raised for errors that are intended to be seen by end users. In
particular, the default error printer does not show the program
context when printing the error message.}

@defstruct[(exn:break exn) ([continuation continuation?])
           #:inspector #f]{

Raised asynchronously (when enabled) in response to a break request.
The @racket[continuation] field can be used to resume the interrupted
computation in the @tech{uncaught-exception handler} or
@racket[call-with-exception-handler] (but @emph{not}
@racket[with-handlers] because it escapes from the exception context
before evaluating any predicates or handlers).}

@defstruct[(exn:break:hang-up exn:break) ()
           #:inspector #f]{

Raised asynchronously for hang-up breaks. The default
 @tech{uncaught-exception handler} reacts to this exception type by
 calling the @tech{exit handler}.}

@defstruct[(exn:break:terminate exn:break) ()
           #:inspector #f]{

Raised asynchronously for termination-request breaks. The default
 @tech{uncaught-exception handler} reacts to this exception type by
 calling the @tech{exit handler}.}


@defthing[prop:exn:srclocs struct-type-property?]{

A property that identifies structure types that provide a list of
@racket[srcloc] values. The property is normally attached to structure
types used to represent exception information.

The property value must be a procedure that accepts a single
value---the structure type instance from which to extract source
locations---and returns a list of @racket[srcloc]s. Some @tech{error
display handlers} use only the first returned location.}

As an example,
@codeblock|{
#lang racket

;; We create a structure that supports the
;; prop:exn:srcloc protocol.  It carries
;; with it the location of the syntax that
;; is guilty.
(struct exn:fail:he-who-shall-not-be-named exn:fail
  (a-srcloc)
  #:property prop:exn:srclocs
  (lambda (a-struct)
    (match a-struct
      [(exn:fail:he-who-shall-not-be-named msg marks a-srcloc)
       (list a-srcloc)])))

;; We can play with this by creating a form that
;; looks at identifiers, and only flags specific ones.
(define-syntax (skeeterize stx)
  (syntax-case stx ()
    [(_ expr)
     (cond
       [(and (identifier? #'expr)
             (eq? (syntax-e #'expr) 'voldemort))
        (quasisyntax/loc stx
          (raise (exn:fail:he-who-shall-not-be-named
                  "oh dear don't say his name"
                  (current-continuation-marks)
                  (srcloc '#,(syntax-source #'expr)
                          '#,(syntax-line #'expr)
                          '#,(syntax-column #'expr)
                          '#,(syntax-position #'expr)
                          '#,(syntax-span #'expr)))))]
       [else
        ;; Otherwise, leave the expression alone.
        #'expr])]))

(define (f x)
  (* (skeeterize x) x))

(define (g voldemort)
  (* (skeeterize voldemort) voldemort))

;; Examples:
(f 7)
(g 7)  
;; The error should highlight the use
;; of voldemort in g.
}|

@defproc[(exn:srclocs? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] has the @racket[prop:exn:srclocs]
property, @racket[#f] otherwise.}


@defproc[(exn:srclocs-accessor [v exn:srclocs?])
         (exn:srclocs? . -> . (listof srcloc))]{

Returns the @racket[srcloc]-getting procedure associated with @racket[v].}


@defstruct[srcloc ([source any/c]
                   [line (or/c exact-positive-integer? #f)]
                   [column (or/c exact-nonnegative-integer? #f)]
                   [position (or/c exact-positive-integer? #f)]
                   [span (or/c exact-nonnegative-integer? #f)])
                  #:inspector #f]{


@deftech{源位置} 最常见的表示是 @racket[srcloc] 结构。
更一般地说，源位置具有与 @racket[srcloc] 结构相同的信息，但可能以不同方式表示或访问。
例如，源位置信息通过类似 @racket[syntax-source] 和 @racket[syntax-line] 的函数
从 @tech{语法对象} 中访问，而
@racket[datum->syntax] 接受列表、向量或另一个语法对象形式的源位置。
对于端口，@racket[object-name] 和 @racket[port-next-location] 的组合提供位置信息，
特别是在通过 @racket[port-count-lines!] 启用了计数的端口中。

@racket[srcloc] 实例的字段如下：
@itemize[


 @item{@racket[source] --- 一个标识源的任意值，通常是路径 (参见 @secref["pathutils"])。}

 @item{@racket[line] --- 行号 (从 1 开始计数) 或 @racket[#f] (未知)。}

 @item{@racket[column] --- 列号 (从 0 开始计数) 或 @racket[#f] (未知)。}

 @item{@racket[position] --- 起始位置 (从 1 开始计数) 或 @racket[#f] (未知)。}

 @item{@racket[span] --- 覆盖的位置数 (从 0 开始计数) 或 @racket[#f] (未知)。}
]

See @secref["print-compiled"] for information about the treatment of
@racket[srcloc] values that are embedded in compiled code.}


@defproc[(srcloc->string [srcloc srcloc?]) (or/c string? #f)]{

Formats @racket[srcloc] as a string suitable for error reporting.  A
path source in @racket[srcloc] is shown relative to the value of
@racket[current-directory-for-user]. The result is @racket[#f] if
@racket[srcloc] does not contain enough information to format a
string.}


@defthing[prop:exn:missing-module struct-type-property?]{

A property that identifies structure types that provide a module path
for a load that fails because a module is not found.

The property value must be a procedure that accepts a single
value---the structure type instance from which to extract source
locations---and returns a @tech{module path}.}

@defproc[(exn:missing-module? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] has the @racket[prop:exn:missing-module]
property, @racket[#f] otherwise.}


@defproc[(exn:missing-module-accessor [v exn:srclocs?])
         (exn:missing-module? . -> . module-path?)]{

Returns the @tech{module path}-getting procedure associated with @racket[v].}

@defproc[(exn-classify-errno [exn/errno (or/c exn? (cons/c exact-integer? (or/c 'posix 'windows 'gai)))])
         (or/c symbol? #f)]{


尝试将 @racket[exn/errno] 规范化为一个符号，
使不同平台上的同类错误转换为相同的符号。
如果规范化未知，则结果为 @racket[#f]。目前，除非 @racket[exn/errno] 是
@racket[exn:fail:filesystem:errno] 实例、
@racket[exn:fail:network:errno] 实例，
或可能由 @racket[exn:fail:filesystem:errno-errno] 或
@racket[exn:fail:network:errno-errno] 生成的值，否则结果将为 @racket[#false]。

当返回符号时，它使用类似 Posix 的约定。可能的结果符号包括
@racket['ENOENT] 表示"文件未找到"，
@racket['EEXIST] 表示"文件已存在"，
@racket['EACCESS] 表示"权限被拒绝"。
@history[#:added "9.0.0.7"]}

@;------------------------------------------------------------------------

@section{额外异常函数}
@note-lib-only[racket/exn]

@history[#:added "6.3"]

@defproc[(exn->string [exn (or/c exn? any/c)]) string?]{

Formats @racket[exn] as a string. If @racket[exn] is an @racket[exn?],
collects and returns the output from the current
@racket[(error-display-handler)]; otherwise, simply converts
@racket[exn] to a string using @racket[(format "~s\n" exn)].}

@;----------------------------------------------------------------------

@section[#:tag "err-realm"]{领域与错误消息调整器}

@deftech{领域} 标识命名函数和为函数参数和结果指定合约的约定。
领域旨在帮助改善基于 Racket 实现的语言之间的分层和互操作性。

领域主要使语言能够识别和重写由实现的较低层生成的错误消息。
例如，一个语言的 ``arrays'' 实现可能直接使用 Racket 向量，
但是当对象类型或原始边界检查对向量失败时，生成的错误消息会提到 ``vector''
和可能的合约如 @racket[vector?] 及函数名如
@racket[vector-ref]。由于这些错误消息被标识为来自 @racket['racket/primitive] 领域，
语言实现可以查找 @racket['racket/primitive] 来检测和重写错误消息，
同时最小化破坏来自应用程序其他部分
(可能用新语言实现) 恰好使用 ``vector'' 一词的错误消息的风险。

每个过程和每个模块也有一个领域。过程的领域是相关的，
例如，当它被应用于错误数量的参数时；在这种情况下，
元数错误消息本身来自 @racket['racket/primitive] 领域，
但错误消息还应包括过程的名称，这可能来自某个不同的领域。
类似地，@racket[continuation-mark-set->context]
可以报告与续延中每个帧 (的过程) 关联的领域，
这可能有助于识别边界跨越。

构造错误消息必须显式地与错误消息调整协作。最基本的协作方式是通过
@racket[error-message->adjusted-string] 和
@racket[error-contract->adjusted-string] 等函数，
它们通过 @racket[current-error-message-adjuster] 参数
以及使用 @racket[error-message-adjuster-key] 作为 @tech{续延标记} 键的
与当前续延关联的其他调整器来运行错误消息调整器。
像 @racket[raise-argument-error] 和
@racket[raise-arity-error] 这样的函数使用
@racket[error-message->adjusted-string]
和 @racket[error-contract->adjusted-string]，使用默认领域 @racket['racket]。
像 @racket[raise-argument-error*] 和
@racket[raise-arity-error*] 这样的函数接受显式的领域参数。

并非所有错误函数都自动与错误消息调整协作。
例如，@racket[raise-reader-error] 和
@racket[raise-syntax-error] 函数不调用调整器，
因为它们报告的是与语法密切相关的错误
(沿着这些思路，更具静态性质的错误)。
@defproc[(error-message->adjusted-string [name (or/c symbol? #f)]
                                         [name-realm symbol?]
                                         [message string?]
                                         [message-realm symbol?])
         string?]{


将 @racket[name] (如果它不是 @racket[#f]) 与 @racket[": "] 然后与
@racket[message] 组合以生成错误消息字符串，
但首先给错误消息调整器机会来调整 @racket[name] 和/或 @racket[message]。

任何通过 @racket[error-message-adjuster-key] 作为 @tech{续延标记}
与当前续延关联的调整器函数首先运行；调整器按从最浅到最深的顺序运行。
然后，使用 @racket[current-error-message-adjuster] 的调整器值。

每个调整器首先尝试 @racket['message] 协议。如果调整器对 @racket['message] 响应
@racket[#f]，则尝试 @racket['name] 协议。
有关协议的信息，请参见
@racket[current-error-message-adjuster]。
对两者都响应 @racket[#f] 的调整器被跳过，
使用 @racket[error-message-adjuster-key] 作为续延标记关联的任何值
如果该值不是接受一个参数的过程，也会被跳过。
此外，如果 (可能已被调整的) @racket[name] 是 @racket[#f]，则跳过 @racket['name] 协议。
@history[#:added "8.4.0.2"]}


@defproc[(error-contract->adjusted-string [contract-str string?]
                                          [contract-realm symbol?])
         string?]{


类似于 @racket[error-message->adjusted-string]，但仅适用于错误消息的合约部分。
结果字符串通常被并入一个更大的错误消息中，该消息随后可能会被进一步调整。

合约字符串的调整使用 @racket[current-error-message-adjuster]
中描述的 @racket['contract] 协议。
@history[#:added "8.4.0.2"]}


@defparam[current-error-message-adjuster proc (symbol? . -> . (or/c procedure? #f))]{


一个 @tech{参数}，确定一个错误消息调整器，
该调整器在通过 @racket[error-message-adjuster-key]
与当前续延关联的任何调整器之后应用。

调整器过程接收一个标识协议的符号，它必须返回 @racket[#f]
或一个通过该协议执行调整的过程。目前定义了以下协议，但未来可能会添加更多：
@itemlist[


 @item{@racket['name]: 该过程接收两个参数，一个名称符号和一个领域符号；
它返回调整后的名称符号和调整后的领域符号。}

 @item{@racket['message]: 该过程接收四个参数：一个名称符号或 @racket[#f]
(表示没有名称将被作为消息前缀)，一个名称-领域符号，一个消息字符串，和一个消息-领域符号；
它返回四个调整后的值。}

 @item{@racket['contract]: 该过程接收两个参数，一个合约字符串和一个领域符号；
它返回调整后的合约字符串和调整后的领域符号。}
]


新的库或语言也可以引入额外的模式符号。
为避免冲突，在模式符号前加上集合或库名，后跟 @litchar{/}。

如果调整器过程对某个协议返回 @racket[#f]，
这与返回一个不执行调整并返回其参数的函数相同。
此参数的默认值对除上述协议之外的任何符号参数返回 @racket[#f]，
对于这些协议，它返回一个过程来检查其参数并在不做调整的情况下返回它们。
@history[#:added "8.4.0.2"]}


@defthing[error-message-adjuster-key symbol?]{


一个 @tech{uninterned} 符号，旨在用作 @tech{续延标记} 键，
其值为错误调整器过程。与该键关联的错误调整器应遵循与
@racket[current-error-message-adjuster] 的值相同的协议。

有关使用此键的标记如何调整错误消息的说明，
请参见 @racket[error-message->adjusted-string]。

@history[#:added "8.4.0.2"]}
