#lang scribble/doc
@(require "mz.rkt" (for-label racket/syntax))

@title[#:tag "syntax-util"]{语法工具}

@(define the-eval (make-base-eval))
@(the-eval '(require racket/syntax))
@(the-eval '(require (for-syntax racket/base racket/syntax)))

@note-lib-only[racket/syntax]


@;{----}

@section{创建格式化标识符}

@defproc[(format-id [lctx (or/c syntax? #f)]
                    [fmt string?]
                    [v (or/c string? symbol? keyword? char? number?
                             (syntax/c (or/c string? symbol? keyword? char? number?)))] ...
                    [#:source src (or/c syntax? #f) #f]
                    [#:props props (or/c syntax? #f) #f]
                    [#:cert ignored (or/c syntax? #f) #f]
                    [#:subs? subs? boolean? #f]
                    [#:subs-intro subs-introducer
                                  (-> syntax? syntax?)
                                  (if (syntax-transforming?) syntax-local-introduce values)])
         identifier?]{

类似于 @racket[format]，但生成一个标识符，使用 @racket[lctx] 作为词法上下文，@racket[src] 作为源位置，@racket[props] 作为属性。使用 @racket[#:cert] 提供的参数将被忽略。（参见 @racket[datum->syntax]。）

格式字符串只能使用 @litchar{~a} 占位符。参数列表中的 syntax object 会自动解包（例如，标识符会自动转换为 symbol）。

@examples[#:eval the-eval
(define-syntax (make-pred stx)
  (syntax-case stx ()
    [(make-pred name)
     (format-id #'name "~a?" (syntax-e #'name))]))
(make-pred pair)
(eval:error (make-pred none-such))
(define-syntax (better-make-pred stx)
  (syntax-case stx ()
    [(better-make-pred name)
     (format-id #'name #:source #'name
                "~a?" (syntax-e #'name))]))
(eval:error (better-make-pred none-such))
]

（Scribble 不显示这一点，但 DrRacket 精确定位了第二个错误的位置，而不是第一个。）

如果 @racket[subs?] 为 @racket[#t]，则会为结果添加一个 @racket['sub-range-binders] syntax property，记录每个标识符在 @racket[v] 中的位置。@racket[subs-intro] 过程应用于每个标识符，其结果包含在 sub-range binder 记录中。此属性值会覆盖从 @racket[props] 复制的 @racket['sub-range-binders] 属性。

@examples[#:eval the-eval
(syntax-property (format-id #'here "~a/~a-~a" #'point 2 #'y #:subs? #t)
                 'sub-range-binders)
]

@history[#:changed "7.4.0.5" @elem{添加了 @racket[#:subs?] 和
@racket[#:subs-intro] 参数。}
         #:changed "8.7.0.7" @elem{允许 @racket[v] 为包装 string、keyword、character 或 number 的 syntax object。}]
}

@defproc[(format-symbol [fmt string?]
                        [v (or/c string? symbol? keyword? char? number?
                                 (syntax/c (or/c string? symbol? keyword? char? number?)))] ...)
         symbol?]{

类似于 @racket[format]，但生成一个 symbol。格式字符串只能使用 @litchar{~a} 占位符。参数列表中的 syntax object 会自动解包（例如，标识符会自动转换为 symbol）。

@examples[#:eval the-eval
  (format-symbol "make-~a" 'triple)
]

@history[#:changed "8.7.0.7" @elem{允许 @racket[v] 为包装 string、keyword、character 或 number 的 syntax object。}]
}


@;{----}

@section{模式变量}

@defform[(define/with-syntax pattern stx-expr)
         #:contracts ([stx-expr syntax?])]{

@racket[with-syntax] 的定义形式。它将 @racket[stx-expr] 的 syntax object 结果与 @racket[pattern] 进行匹配，并为 @racket[pattern] 中的模式变量创建定义。

@examples[#:eval the-eval
(define/with-syntax (px ...) #'(a b c))
(define/with-syntax (tmp ...) (generate-temporaries #'(px ...)))
#'([tmp px] ...)
(define/with-syntax name #'Alice)
#'(hello name)
]
}


@;{----}

@section{错误报告}

@defparam[current-syntax-context stx (or/c syntax? #f)]{

当前的上下文 syntax object，默认为 @racket[#f]。它决定了 @racket[wrong-syntax] 创建的语法错误所使用的前缀特殊形式名称。
}

@defproc[(wrong-syntax [stx syntax?] [format-string string?] [v any/c] ...)
         any]{

使用 @racket[(current-syntax-context)] 的结果作为"主要" syntax object，使用提供的 @racket[stx] 作为具体的语法对象来引发语法错误。（后者 @racket[stx] 通常是 DrRacket 高亮显示的那个。）错误消息使用格式字符串和参数构造，并以 @racket[current-syntax-context] 下描述的特殊形式名称作为前缀。

@examples[#:eval the-eval
(eval:error (wrong-syntax #'here "expected ~s" 'there))
(eval:error
 (parameterize ([current-syntax-context #'(look over here)])
   (wrong-syntax #'here "expected ~s" 'there)))
]

使用 @racket[wrong-syntax] 的 macro 可能在其转换开始时设置语法上下文，如下所示：
@RACKETBLOCK[
(define-syntax (my-macro stx)
  (parameterize ([current-syntax-context stx])
    (syntax-case stx ()
      ___)))
]
然后在 macro 转换期间对 @racket[wrong-syntax] 的任何调用都将引用 @racket[my-macro]（更准确地说，是引用 @racket[my-macro] 被使用时所绑定的名称，该名称可能因重命名、前缀等不同而不同）。

}


@;{----}

@section{记录消失的 use}

@defparam[current-recorded-disappeared-uses ids
          (or/c (listof identifier?) #f)]{

用于跟踪消失的 use 的参数。当参数具有非假值时，跟踪被"启用"。这由 @racket[with-disappeared-uses] 等形式自动完成。
}

@defform[(with-disappeared-uses body-expr ... stx-expr)
         #:contracts ([stx-expr syntax?])]{

对 @racket[body-expr] 和 @racket[stx-expr] 求值，捕获通过 @racket[syntax-local-value/record] 查找的标识符。将捕获的标识符添加到 @racket[stx-expr] 产生的 syntax object 的 @racket['disappeared-use] syntax property 中。

@history[#:changed "6.5.0.7" @elem{添加了包含 @racket[body-expr] 的选项。}]
}

@defproc[(syntax-local-value/record [id identifier?] [predicate (-> any/c boolean?)])
         any/c]{

在语法环境中查找 @racket[id]（通过 @racket[syntax-local-value]）。如果查找成功并返回满足谓词的值，则返回该值，并通过调用 @racket[record-disappeared-uses] 将 @racket[id] 记录为消失的 use。如果查找失败或值不满足谓词，则返回 @racket[#f]，标识符不会被记录为消失的 use。
}

@defproc[(record-disappeared-uses [id (or/c identifier? (listof identifier?))]
                                  [intro? boolean? (syntax-transforming?)])
         void?]{

将 @racket[id] 添加到 @racket[(current-recorded-disappeared-uses)]。如果 @racket[id] 是列表，则对所有标识符执行相同的操作。如果 @racket[intro?] 为真，则先对标识符调用 @racket[syntax-local-introduce]。

如果不用于 @racket[with-disappeared-uses] 之类的形式范围内，则没有效果。

@history[#:changed "6.5.0.7" @elem{添加了传入单个标识符而非要求列表的选项。}
         #:changed "7.2.0.11" @elem{添加了 @racket[intro?] 参数。}]
}


@;{----}

@section{其他工具}

@defproc[(generate-temporary [name-base any/c 'g]) identifier?]{

生成一个新鲜标识符。@racket[generate-temporaries] 的单数形式。如果提供了 @racket[name-base]，它将用作标识符名称的基础。
}

@defproc[(internal-definition-context-apply [intdef-ctx internal-definition-context?]
                                            [stx syntax?])
         syntax?]{

等同于 @racket[(internal-definition-context-introduce intdef-ctx stx 'add)]。提供 @racket[internal-definition-context-apply] 函数是为了向后兼容；推荐使用 @racket[internal-definition-context-add-scopes] 函数。
}

@defproc[(syntax-local-eval [stx any/c]
                            [intdef-ctx (or/c internal-definition-context?
                                              #f
                                              (listof internal-definition-context?))
                             '()])
         any]{

将 @racket[stx] 作为表达式在当前 @tech{transformer environment}（即 @tech{phase level} 1）中求值。如果 @racket[intdef-ctx] 不为 @racket[#f]，则使用 @racket[intdef-ctx] 提供的值来丰富 @racket[stx] 的 @tech{lexical information} 并扩展 @tech{local binding context}，方式与 @racket[local-expand] 的第四个参数相同。

@examples[#:eval the-eval
(define-syntax (show-me stx)
  (syntax-case stx ()
    [(show-me expr)
     (begin
       (printf "at compile time produces ~s\n"
               (syntax-local-eval #'expr))
       #'(printf "at run time produces ~s\n"
                 expr))]))
(show-me (+ 2 5))
(define-for-syntax fruit 'apple)
(define fruit 'pear)
(show-me fruit)
]

@history[#:changed "6.90.0.27" @elem{将 @racket[intdef-ctx] 更改为除了接受单个 internal-definition context 或 @racket[#f] 外，还可以接受 internal-definition context 的列表。}]
}

@defform[(with-syntax* ([pattern stx-expr] ...)
           body ...+)
         #:contracts ([stx-expr syntax?])]{

类似于 @racket[with-syntax]，但每个 @racket[pattern] 的模式变量在后续子句的 @racket[stx-expr] 以及 @racket[body] 中都被绑定，并且 @racket[pattern] 不需要绑定不同的模式变量；后面的绑定会遮蔽前面的绑定。

@examples[#:eval the-eval
(with-syntax* ([(x y) (list #'val1 #'val2)]
               [nest #'((x) (y))])
  #'nest)
]
}

@close-eval[the-eval]
