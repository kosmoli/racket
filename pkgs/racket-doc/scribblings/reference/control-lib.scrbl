#lang scribble/doc
@(require (except-in "mz.rkt" set) (for-label racket/control))

@title{Additional Control Operators}

@note-lib-only[racket/control]

@(define control-eval
         (let ([the-eval (make-base-eval)])
          (the-eval '(require racket/control))
          the-eval))

The @racket[racket/control] library provides various control operators
from the research literature on higher-order control operators, plus a
few extra convenience forms. These control operators are implemented
in terms of @racket[call-with-continuation-prompt],
@racket[call-with-composable-continuation], @|etc|, and they generally
work sensibly together. Many are redundant; for example,
@racket[reset] and @racket[prompt] are aliases.

@; ----------------------------------------------------------------------

@defproc[(call/prompt
          [proc procedure?]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)]
          [handler (or/c procedure? #f) #f]
          [arg any/c] ...)
         any]{
@racket[call/prompt] 是 @racket[call-with-continuation-prompt] 的别名。
}

@defproc[(abort/cc
          [prompt-tag any/c]
          [v any/c] ...)
         any]{
@racket[abort/cc] 是 @racket[abort-current-continuation] 的别名。
}

@defproc[(call/comp
          [proc (continuation? . -> . any)]
          [prompt-tag continuation-prompt-tag? (default-continuation-prompt-tag)])
         any]{
@racket[call/comp] 是 @racket[call-with-composable-continuation] 的别名。
}

@; ----------------------------------------------------------------------

@defproc[(abort [v any/c] ...) any]{

使用默认的 continuation prompt tag 和默认的 abort handler，将 @racket[v] 返回到 prompt。

即 @racket[(abort v ...)] 等价于

@racketblock[
(abort-current-continuation
 (default-continuation-prompt-tag)
 (lambda () (values v ...)))
]

@examples[#:eval control-eval
(prompt
  (printf "start here\n")
  (printf "answer is ~a\n" (+ 2 (abort 3))))
]}

@; ----------------------------------------------------------------------

@deftogether[(
@defform*[[(% expr)
           (% expr handler-expr)
           (% expr handler-expr #:tag tag-expr)]]
@defproc[(fcontrol
          [v any/c]
          [#:tag prompt-tag (default-continuation-prompt-tag)])
         any]
)]{


Sitaram 的算子 @cite["Sitaram93"]。

基本归约规则为：

@racketblock[
(% _val proc) => _val
(% _E[(fcontrol _val)] _proc) => (_proc _val (lambda (_x) _E[_x]))
  (code:comment @#,t{其中 @racket[_E] 不含 @racket[%]})
]

当省略 @racket[handler-expr] 时，@racket[%] 与 @racket[prompt] 相同。如果提供了 @racket[prompt-tag]，则 @racket[%] 使用特定的 prompt tag，类似于 @racket[prompt-at]。

@examples[#:eval control-eval
(% (+ 2 (fcontrol 5))
   (lambda (v k)
     (k v)))
(% (+ 2 (fcontrol 5))
   (lambda (v k)
     v))
]}

@; ----------------------------------------------------------------------

@deftogether[(
@defform[(prompt expr ...+)]
@defform[(control id expr ...+)]
)]{

高阶 control 最早期的算子之一 @cite["Felleisen88a" "Felleisen88" "Sitaram90"]。

基本归约规则为：
@racketblock[
(prompt _val) => _val
(prompt _E[(control _k _expr)]) => (prompt ((lambda (_k) _expr)
                                            (lambda (_v) _E[_v])))
  (code:comment @#,t{其中 @racket[_E] 不含 @racket[prompt]})
]

@examples[#:eval control-eval
(prompt
  (+ 2 (control k (k 5))))
(prompt
  (+ 2 (control k 5)))
(prompt
  (+ 2 (control k (+ 1 (control k1 (k1 6))))))
(prompt
  (+ 2 (control k (+ 1 (control k1 (k 6))))))
(prompt
  (+ 2 (control k (control k1 (control k2 (k2 6))))))
]}

@; ----------------------------------------------------------------------

@deftogether[(
@defform[(prompt-at prompt-tag-expr expr ...+)]
@defform[(control-at prompt-tag-expr id expr ...+)]
)]{

类似于 @racket[prompt] 和 @racket[control]，但使用特定的 prompt tag：

@racketblock[
(prompt-at _tag _val) => _val
(prompt-at _tag _E[(control-at _tag _k _expr)]) => (prompt-at _tag 
                                                    ((lambda (_k) _expr)
                                                     (lambda (_v) _E[_v])))
  (code:comment @#,t{其中 @racket[_E] 不含对应 @racket[_tag] 的 @racket[prompt-at]})
]}

@; ----------------------------------------------------------------------

@deftogether[(
@defform[(reset expr ...+)]
@defform[(shift id expr ...+)]
)]{

Danvy 和 Filinski 的算子 @cite["Danvy90"]。

基本归约规则为：

@racketblock[
(reset _val) => _val
(reset _E[(shift _k _expr)]) => (reset ((lambda (_k) _expr) 
                                        (lambda (_v) (reset _E[_v]))))
  (code:comment @#,t{其中 @racket[_E] 不含 @racket[reset]})
]

@racket[reset] 和 @racket[prompt] 可以互换使用。}


@; ----------------------------------------------------------------------

@deftogether[(
@defform[(reset-at prompt-tag-expr expr ...+)]
@defform[(shift-at prompt-tag-expr identifier expr ...+)]
)]{

类似于 @racket[reset] 和 @racket[shift]，但使用指定的 prompt tag。}

@; ----------------------------------------------------------------------

@deftogether[(
@defform[(prompt0 expr ...+)]
@defform[(reset0 expr ...+)]
@defform[(control0 id expr ...+)]
@defform[(shift0 id expr ...+)]
)]{

@racket[prompt] 等算子的推广形式 @cite["Shan04"]。

基本归约规则为：

@racketblock[
(prompt0 _val) => _val
(prompt0 _E[(control0 _k _expr)]) => ((lambda (_k) _expr)
                                      (lambda (_v) _E[_v]))
(reset0 _val) => _val
(reset0 _E[(shift0 _k _expr)]) => ((lambda (_k) _expr)
                                   (lambda (_v) (reset0 _E[_v])))
]

@racket[reset0] 和 @racket[prompt0] 可以互换使用。
此外，以下归约规则也适用：

@racketblock[
(prompt _E[(control0 _k _expr)]) => (prompt ((lambda (_k) _expr)
                                             (lambda (_v) _E[_v])))
(reset _E[(shift0 _k _expr)]) => (reset ((lambda (_k) _expr)
                                         (lambda (_v) (reset0 _E[_v]))))
(prompt0 _E[(control _k _expr)]) => (prompt0 ((lambda (_k) expr)
                                              (lambda (_v) _E[_v])))
(reset0 _E[(shift _k _expr)]) => (reset0 ((lambda (_k) expr)
                                          (lambda (_v) (reset _E[_v]))))
]

即 @racket[prompt]/@racket[reset] 和 @racket[control]/@racket[shift] 两处都必须一致才会产生 @racket[0] 变体的行为，否则采用非 @racket[0] 的行为。}

@; ----------------------------------------------------------------------

@deftogether[(
@defform[(prompt0-at prompt-tag-expr expr ...+)]
@defform[(reset0-at prompt-tag-expr expr ...+)]
@defform[(control0-at prompt-tag-expr id expr ...+)]
@defform[(shift0-at prompt-tag-expr id expr ...+)]
)]{

@racket[prompt0] 等的变体，接受一个 prompt tag 参数。}

@; ----------------------------------------------------------------------

@defproc[(spawn [proc ((any/c . -> . any) . -> . any)]) any]{

Hieb 和 Dybvig 的算子 @cite["Hieb90"]。

基本归约规则为：

@racketblock[
(prompt-at _tag _obj) => _obj
(spawn _proc) => (prompt _tag (_proc (lambda (_x) (abort _tag _x))))
(prompt-at _tag _E[(abort _tag _proc)])
  => (_proc (lambda (_x) (prompt-at _tag _E[_x])))
  (code:comment @#,t{其中 @racket[_E] 不含对应 @racket[_tag] 的 @racket[prompt-at]})
]}

@; ----------------------------------------------------------------------

@defproc[(splitter [proc (((-> any) . -> . any) 
                          ((continuation? . -> . any) . -> . any) 
                          . -> . any)])
         any]{

Queinnec 和 Serpette 的算子 @cite["Queinnec91"]。

基本归约规则为：
@racketblock[
(splitter _proc) => (prompt-at _tag
                     (_proc (lambda (_thunk) 
                              (abort _tag _thunk))
                            (lambda (_proc)
                              (control0-at _tag _k (_proc _k)))))
(prompt-at _tag _E[(abort _tag _thunk)]) => (_thunk)
  (code:comment @#,t{其中 @racket[_E] 不含对应 @racket[_tag] 的 @racket[prompt-at]})
(prompt-at _tag _E[(control0-at _tag _k _expr)]) => ((lambda (_k) _expr)
                                                     (lambda (_x) _E[_x]))
  (code:comment @#,t{其中 @racket[_E] 不含对应 @racket[_tag] 的 @racket[prompt-at]})
]}

@; ----------------------------------------------------------------------

@deftogether[(
@defproc[(new-prompt) any]
@defform[(set prompt-expr expr ...+)]
@defform[(cupto prompt-expr id expr ...+)]
)]{

Gunter 等人的算子 @cite["Gunter95"]。

在此库中，@racket[new-prompt] 是 @racket[make-continuation-prompt-tag] 的别名，@racket[set] 是 @racket[prompt0-at] 的别名，@racket[cupto] 是 @racket[control0-at] 的别名。

}

@close-eval[control-eval]
