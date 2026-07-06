#lang scribble/doc
@(require scribble/bnf "mz.rkt"
          (for-label racket/fixnum
                     syntax/srcloc))

@title[#:tag "exns"]{Exceptions}

@guideintro["exns"]{exceptions}

关于 Racket 异常模型的信息，请参见 @secref["exn-model"]。它基于 Friedman、Haynes 和 Dybvig 的提议 @cite["Friedman95"]。

每当 Racket 中发生原始错误时，就会引发异常。传递给当前 @tech{exception handler} 的原始错误值始终是 @racket[exn] 结构类型的实例。每个 @racket[exn] 结构值都有一个 @racket[message] 字段，该字段是一个字符串，即原始错误消息。
默认异常处理器通过 @racket[exn?] 谓词识别异常值，并将错误消息传递给当前的 @tech{error display handler}（参见 @racket[error-display-handler]）。

接受具有特定必需元数的过程参数的原始过程（例如 @racket[call-with-input-file]、@racket[call/cc]）会立即检查参数的元数，如果元数不正确则引发 @racket[exn:fail:contract]。

@;----------------------------------------------------------------------
@section[#:tag "err-msg-conventions"]{Error Message Conventions}

Racket 的 @deftech{error message convention} 是生成形状如下的错误消息：

@racketblock[
  @#,nonterm{srcloc}: @#,nonterm{name}: @#,nonterm{message}@#,tt{;}
   @#,nonterm{continued-message} ...
    @#,nonterm{field}: @#,nonterm{detail}
    ...
]

消息以可选的源位置 @nonterm{srcloc} 开头，当存在时后面跟冒号和空格。消息接着是可选的 @nonterm{name}，它通常标识投诉的函数、语法形式或其他实体，但也可能指代被投诉的实体；@nonterm{name} 存在时后面也跟冒号和空格。

@nonterm{message} 应该相对简短，并且应该很大程度上独立于触发错误的特定值。需要多行的更详细解释应该继续，每行缩进一个空格，在这种情况下 @nonterm{message} 应以分号结尾（但如果 @nonterm{continued-message} 不存在，则应省略分号）。消息文本应为小写——如果需要，使用分号分隔句子，尽管长解释可能更好地推迟到额外字段。

触发错误的特定值或其他有帮助的信息应出现在单独的 @nonterm{field} 行中，每行缩进两个空格。如果 @nonterm{detail} 特别长或跨越多行，它应在 @nonterm{field} 标签后的独立行上开始，并且其每行应缩进三个空格。字段名称应全部小写。

如果字段提供相对详细的信息，在常见情况下可能分散注意力但在其他情况下有用，则 @nonterm{field} 名称应以 @litchar{...} 结尾。例如，当报告函数特定参数的 contract 失败时，函数的其他参数可能显示在 ``other arguments...'' 字段中。意图是名称以 @litchar{...} 结尾的字段在 DrRacket 等环境中可能默认隐藏。

尽可能使 @nonterm{field} 名称简短，依赖 @nonterm{message} 或 @nonterm{continued message} 文本来阐明字段的含义。例如，优先使用 ``given'' 而不是 ``given turtle'' 作为字段名称，其中 @nonterm{message} 类似于 ``given turtle is too sleepy'' 来阐明 ``given'' 指代 turtle。

@;------------------------------------------------------------------------
@section[#:tag "errorproc"]{Raising Exceptions}

@defproc[(raise [v any/c] [barrier? any/c #t]) any]{

引发异常，其中 @racket[v] 表示正在引发的异常。@racket[v] 参数可以是任何值；它被传递给当前的 @tech{exception handler}。

如果 @racket[barrier?] 为 true，则对 @tech{exception handler} 的调用受到 @tech{continuation barrier} 的保护，因此多次返回/转义是不可能的。@racketmodname[racket] 函数引发的所有异常都有效地使用 @racket[raise]，且 @racket[barrier?] 值为 @racket[#t]。

从异常引发到异常处理器获得控制权期间，break 被禁用，并且处理器本身被 @racket[parameterize-break] 以初始禁用 break；有关 break 的更多信息，请参见 @secref["breakhandler"]。

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
@racket[raise-arguments-error] 生成的错误消息通过 @racket[error-message->adjusted-string] 进行调整，使用默认的 @racket['racket] realm。

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

将 @racket[f] 安装为 @racket[thunk] 调用的 @tech{dynamic extent} 的 @tech{exception handler}。如果在 @racket[thunk] 求值过程中引发异常（在当前 continuation 的扩展中，该扩展没有自己的异常处理器），则 @racket[f] 在 @racket[raise] 调用的 continuation 中被应用于 @racket[raise] 的值（但 continuation 通常通过 @tech{continuation barrier} 扩展；参见 @secref["prompt-model"] 和 @racket[raise]）。

任何接受一个参数的 procedure 都可以作为异常处理器。
通常，异常处理器通过 @racket[abort-current-continuation] 或其他 escape 机制
逃离 @racket[raise] 调用的上下文。要将异常传播到"前一个"
异常处理器——即在被调用的异常处理器与该 continuation 关联之后、
与该 continuation 其余部分关联的异常处理器——异常处理器可以简单地
返回一个值而不是 escape，此时 @racket[raise] 调用
将值传播到前一个异常处理器（仍在 @racket[raise] 调用的
dynamic extent 内，并在相同的 barrier 下，如果有的话）。如果异常处理器
返回一个值但没有前一个处理器可用，则使用 @tech{uncaught-exception handler}。

对异常处理器的调用被 @racket[parameterize-break] 以禁用 break，并且它被 @racket[call-with-exception-handler] 包装以安装一个异常处理器，该处理器通过 @tech{error display handler} 报告原始和新引发的异常，然后通过 @tech{error escape handler} 转义。}


@defparam[uncaught-exception-handler f (any/c . -> . any)]{

一个 @tech{parameter}，确定 @racket[raise] 在相关 continuation 没有通过 @racket[call-with-exception-handler] 或 @racket[with-handlers] 安装异常处理器时使用的 @deftech{uncaught-exception handler}。与通过 @racket[call-with-exception-handler] 安装的异常处理器不同，uncaught-exception handler 在被 @racket[raise] 调用时不得返回值；如果它返回，则引发异常（由报告原始和新引发异常的异常处理器处理）。

默认 uncaught-exception handler 使用当前 @tech{error display handler}（参见 @racket[error-display-handler]）打印错误消息，除非处理器的参数是 @racket[exn:break:hang-up] 的实例。如果处理器的参数是 @racket[exn:break:hang-up] 或 @racket[exn:break:terminate] 的实例，则默认 uncaught-exception handler 然后以 @racket[1] 调用 @tech{exit handler}，通常会退出或转义。对于任何参数，默认 uncaught-exception handler 然后通过调用当前 @tech{error escape handler}（参见 @racket[error-escape-handler]）转义。对每个处理器的调用被 @racket[parameterize] 以将 @racket[error-display-handler] 设置为默认 @tech{error display handler}，并且被 @racket[parameterize-break] 以禁用 break。对 @tech{error escape handler} 的调用进一步被 parameterize 以将 @racket[error-escape-handler] 设置为默认 @tech{error escape handler}；如果 @tech{error escape handler} 返回，则调用默认 @tech{error escape handler}。

当当前 @tech{error display handler} 是默认处理器时，错误显示调用被 parameterize 以安装一个紧急错误显示处理器，该处理器记录错误（参见 @racket[log-error]）且永不失败。}


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

类似于 @racket[with-handlers]，但如果调用了 @racket[handler-expr] 过程，break 不会被显式禁用，且处理器调用相对于 @racket[with-handlers*] 形式处于尾位置。}

@;------------------------------------------------------------------------

@section{配置默认处理}
@defparam[error-escape-handler proc (-> any)]{

@deftech{error escape handler} 的参数，它不接受参数并从异常的动态上下文中转义。默认 error escape handler 使用 @racket[(abort-current-continuation (default-continuation-prompt-tag) void)] 转义。

error escape handler 通常由异常处理器直接调用，在一个 @tech{parameterization} 中，该参数化将 @tech{error display handler} 和 @tech{error escape handler} 设置为默认处理器，并且通常被 @racket[parameterize-break] 以禁用 break。要在不同上下文中从运行时错误中转义，请使用 @racket[raise] 或 @racket[error]。

由于异常处理调用周围的 @tech{continuation barrier}，error escape handler 无法调用在异常之前创建的完整 continuation，但它可以 abort 到一个 prompt（参见 @racket[call-with-continuation-prompt]）或调用 escape continuation（参见 @racket[call-with-escape-continuation]）。}

@defparam[error-display-handler proc (string? any/c . -> . any)]{

@deftech{error display handler} 的参数，由默认异常处理器以错误消息和异常值调用。更一般地，处理器的第一个参数是要打印为错误消息的字符串，第二个是表示引发的异常的值。error display handler 可以以不同方式打印错误，但应始终打印到当前错误端口。

默认 error display handler 将其第一个参数 @racket[display] 到当前错误端口（由 @racket[current-error-port] 参数确定），并从第二个参数中提取堆栈跟踪（参见 @racket[continuation-mark-set->context]）以显示，如果它是 @racket[exn] 值但不是 @racket[exn:fail:user] 值。

@margin-note{DrRacket 中的默认 error display handler 也使用第二个参数来高亮源位置。}

要报告运行时错误，请使用 @racket[raise] 或 @racket[error] 等过程，而不是直接调用 error display handler。}

@defparam[error-print-width width (and/c exact-integer? (>=/c 3))]{

一个参数，其值用作打印嵌入在原始错误消息中的 Racket 值所用的最大字符数。}

@defparam[error-print-context-length cnt exact-nonnegative-integer?]{

一个参数，其值被默认的 @tech{error display handler} 用作
打印上下文（或"stack trace"）的最大行数；
如果在第一个 @racket[cnt] 行之后还有更多行可用，则打印一行 ``...''。
@racket[cnt] 值为 @racket[0] 则完全禁用上下文打印。}


@defboolparam[error-print-source-location include?]{

一个 @tech{parameter}，控制读取和语法错误消息是否包含源信息，如源行号、列号或表达式。此参数还控制当模块定义的变量在其定义执行前被访问时的错误消息；该参数确定消息是否包含模块名称。只有 @racket[exn:fail:read]、@racket[exn:fail:syntax] 或 @racket[exn:fail:contract:variable] 结构的 message 字段受此参数影响。默认值为 @racket[#t]。}


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

针对表示错误的异常（相对于 @racket[exn:break]）而引发。}


@defstruct[(exn:fail:contract exn:fail) ()
           #:inspector #f]{

针对函数或语法形式的不当运行时使用导致的错误而引发。}

@defstruct[(exn:fail:contract:arity exn:fail:contract) ()
           #:inspector #f]{

当过程应用于错误数量的参数时引发。}

@defstruct[(exn:fail:contract:divide-by-zero exn:fail:contract) ()
           #:inspector #f]{

针对除以精确零而引发。}

@defstruct[(exn:fail:contract:non-fixnum-result exn:fail:contract) ()
           #:inspector #f]{

当结果不是 fixnum 时，由 @racket[fx+] 等函数引发。}

@defstruct[(exn:fail:contract:continuation exn:fail:contract) ()
           #:inspector #f]{

当 continuation 被应用但跳转会跨越 continuation barrier 时引发。}

@defstruct[(exn:fail:contract:variable exn:fail:contract) ([id symbol?])
           #:inspector #f]{

针对引用尚未定义的 @tech{top-level variable} 或 @tech{module-level variable} 而引发。}

@defstruct[(exn:fail:syntax exn:fail) ([exprs (listof syntax?)])
           #:inspector #f]{

针对不是 @racket[read] 错误的语法错误而引发。@racket[exprs] 指示相关的源表达式，从最不具体到最具体。

此结构类型实现了 @racket[prop:exn:srclocs] 属性。}

@defstruct[(exn:fail:syntax:unbound exn:fail:syntax) ()
           #:inspector #f]{

针对模块内未绑定的标识符，由 @racket[#%top] 或 @racket[set!] 引发。}

@defstruct[(exn:fail:syntax:missing-module exn:fail:syntax) ([path module-path?])
           #:inspector #f]{

由默认 @tech{module name resolver} 或默认 @tech{load handler} 引发，以报告一个模块路径——在 @racket[path] 字段中报告——其实现文件无法找到。

默认 @tech{module name resolver} 仅在给定语法对象作为其第二个参数时引发此异常，默认 @tech{load handler} 仅在 @racket[current-module-path-for-load] 的值是语法对象时引发此异常（在这种情况下，@racket[exprs] 字段和 @racket[path] 字段都由语法对象确定）。

此结构类型实现了 @racket[prop:exn:missing-module] 属性。}

@defstruct[(exn:fail:read exn:fail) ([srclocs (listof srcloc?)])
           #:inspector #f]{

针对 @racket[read] 错误而引发。@racket[srclocs] 指示相关的源表达式。}

@defstruct[(exn:fail:read:eof exn:fail:read) ()
           #:inspector #f]{

针对 @racket[read] 错误而引发，特别是当错误是由于意外的文件结束时。}

@defstruct[(exn:fail:read:non-char exn:fail:read) ()
           #:inspector #f]{

Raised for a @racket[read] error, specifically when the error is due
to an unexpected non-character (i.e., ``special'') element in the
input stream.}

@defstruct[(exn:fail:filesystem exn:fail) ()
           #:inspector #f]{

针对与文件系统相关的错误（如文件未找到）而引发。}

@defstruct[(exn:fail:filesystem:exists exn:fail:filesystem) ()
           #:inspector #f]{

针对尝试创建已存在文件时的错误而引发。}

@defstruct[(exn:fail:filesystem:version exn:fail:filesystem) ()
           #:inspector #f]{

针对加载扩展时的版本不匹配错误而引发。}

@defstruct[(exn:fail:filesystem:errno exn:fail:filesystem) ([errno (cons/c exact-integer? (or/c 'posix 'windows 'gai))])
           #:inspector #f]{

针对有系统错误码可用的文件系统错误而引发。@racket[errno] 字段的符号部分指示错误码的类别：@racket['posix] 表示 C/Posix @tt{errno} 值，@racket['windows] 表示 Windows 系统错误码（仅在 Windows 下），@racket['gai] 表示 @tt{getaddrinfo} 错误码（仅出现在解析主机名的操作的 @racket[exn:fail:network:errno] 异常中，但为了一致性也允许在 @racket[exn:fail:filesystem:errno] 实例中出现）。

另请参见 @racket[exn-classify-errno]。}

@defstruct[(exn:fail:filesystem:missing-module exn:fail:filesystem) ([path module-path?])
           #:inspector #f]{

由默认 @tech{module name resolver} 或默认 @tech{load handler} 引发，以报告一个模块路径——在 @racket[path] 字段中报告——其实现文件无法找到。默认 @tech{module name resolver} 仅在 @emph{未} 给定语法对象作为其第二个参数时引发此异常，默认 @tech{load handler} 仅在 @racket[current-module-path-for-load] 的值 @emph{不是} 语法对象时引发此异常。此结构类型实现了 @racket[prop:exn:missing-module] 属性。}

@defstruct[(exn:fail:network exn:fail) ()
           #:inspector #f]{

针对 TCP 和 UDP 错误而引发。}

@defstruct[(exn:fail:network:errno exn:fail:network) ([errno (cons/c exact-integer? (or/c 'posix 'windows 'gai))])
           #:inspector #f]{

针对有系统错误码可用的 TCP 或 UDP 错误而引发，其中 @racket[errno] 字段与 @racket[exn:fail:filesystem:errno] 相同。

另请参见 @racket[exn-classify-errno]。}


@defstruct[(exn:fail:out-of-memory exn:fail) ()
           #:inspector #f]{

针对因内存不足导致的错误而引发，在这种情况下至少有足够的内存用于引发异常。}

@defstruct[(exn:fail:unsupported exn:fail) ()
           #:inspector #f]{

针对因当前平台或配置上不支持的功能导致的错误而引发。}

@defstruct[(exn:fail:user exn:fail) ()
           #:inspector #f]{

针对预期给最终用户查看的错误而引发。特别是，默认错误打印机在打印错误消息时不显示程序上下文。}

@defstruct[(exn:break exn) ([continuation continuation?])
           #:inspector #f]{

异步引发（当启用时）以响应 break 请求。@racket[continuation] 字段可用于在 @tech{uncaught-exception handler} 或 @racket[call-with-exception-handler] 中恢复被中断的计算（但 @emph{不是} @racket[with-handlers]，因为它在求值任何谓词或处理器之前从异常上下文中转义）。}

@defstruct[(exn:break:hang-up exn:break) ()
           #:inspector #f]{

针对挂断 break 异步引发。默认 @tech{uncaught-exception handler} 通过调用 @tech{exit handler} 来响应此异常类型。}

@defstruct[(exn:break:terminate exn:break) ()
           #:inspector #f]{

针对终止请求 break 异步引发。默认 @tech{uncaught-exception handler} 通过调用 @tech{exit handler} 来响应此异常类型。}


@defthing[prop:exn:srclocs struct-type-property?]{

一个属性，标识提供 @racket[srcloc] 值列表的结构类型。该属性通常附加到用于表示异常信息的结构类型上。

属性值必须是一个过程，该过程接受单个值——从中提取源位置的结构类型实例——并返回 @racket[srcloc] 的列表。一些 @tech{error display handlers} 只使用第一个返回的位置。}

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

如果 @racket[v] 具有 @racket[prop:exn:srclocs] 属性则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(exn:srclocs-accessor [v exn:srclocs?])
         (exn:srclocs? . -> . (listof srcloc))]{

返回与 @racket[v] 关联的 @racket[srcloc] 获取过程。}


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

关于嵌入在编译代码中的 @racket[srcloc] 值的处理，请参见 @secref["print-compiled"]。}


@defproc[(srcloc->string [srcloc srcloc?]) (or/c string? #f)]{

将 @racket[srcloc] 格式化为适合错误报告的字符串。@racket[srcloc] 中的路径源相对于 @racket[current-directory-for-user] 的值显示。如果 @racket[srcloc] 没有包含足够的信息来格式化字符串，则结果为 @racket[#f]。}


@defthing[prop:exn:missing-module struct-type-property?]{

一个属性，标识为因模块未找到而失败的加载提供模块路径的结构类型。

属性值必须是一个过程，该过程接受单个值——从中提取源位置的结构类型实例——并返回一个 @tech{module path}。}

@defproc[(exn:missing-module? [v any/c]) boolean?]{

如果 @racket[v] 具有 @racket[prop:exn:missing-module] 属性则返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(exn:missing-module-accessor [v exn:srclocs?])
         (exn:missing-module? . -> . module-path?)]{

返回与 @racket[v] 关联的 @tech{module path} 获取过程。}

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

将 @racket[exn] 格式化为字符串。如果 @racket[exn] 是 @racket[exn?]，则收集并返回当前 @racket[(error-display-handler)] 的输出；否则，使用 @racket[(format "~s\n" exn)] 将 @racket[exn] 简单地转换为字符串。}

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
