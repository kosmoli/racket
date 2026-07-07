#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "stxcerts"]{Syntax Taints}

@guideintro["stx-certs"]{syntax 污点}

一个 @deftech{受污}（tainted）的 identifier 如果用作绑定或表达式，会被 macro expander 拒绝。如果一个 syntax 对象 @racket[_stx] 是 @deftech{受污}的，那么 @racket[(syntax-e _stx)] 结果中 syntaxe 对象都是受污的；而且，以 @racket[_stx] 为第一个参数的 @racket[datum->syntax] 会产生一个受污的 syntax 对象。@racket[(syntax-property _stx _key)] 结果中的任何 syntax 对象如果处于值中会被 @racket[datum->syntax] 转化到达的位置，则也会受污。污点无法被移除。

Syntax 对象在以下情况下会被受污：当它被 macro expander 纳入异常时，或者当它像 @racket[expand] 这样的函数通过使用一个不是原始 @tech{code inspector} 的 @tech{code inspector} 来产生结果时。@racket[syntax-taint] 函数也返回受污的 syntax 对象。

在 Racket 的早期版本中，有一个概念叫做 syntax 的 @defterm{武装}（arming）和 @defterm{解除武装}（disarming），用于触发污点或避免污点。这种间接方式已不再受支持，相应的操作 @racket[syntax-arm]、@racket[syntax-disarm]、@racket[syntax-rearm] 和 @racket[syntax-protect] 现在对它们的参数没有影响。同样，syntax 属性（见 @secref["stxprops"]）@indexed-racket['taint-mode] 和 @indexed-racket['certify-mode] 曾被用于控制 syntax arming，而不再被 macro expander 专门识别。

@defproc[(syntax-tainted? [stx syntax?]) boolean?]{

如果 @racket[stx] 是 @deftech{受污}的，返回 @racket[#t]，否则返回 @racket[#f]。}


@defproc[(syntax-arm [stx syntax?]
                     [inspector (or/c inspector? #f) #f]
                     [use-mode? any/c #f])
         syntax?]{

返回 @racket[stx]。

@history[#:changed "8.2.0.4" @elem{更改为直接返回 @racket[stx]，而不再返回``armed'' syntax。}]}


@defproc[(syntax-protect [stx syntax?]) syntax?]{

返回 @racket[stx]。

@history[#:changed "8.2.0.4" @elem{更改为直接返回 @racket[stx]，而不再返回``armed'' syntax。}]}


@defproc[(syntax-disarm [stx syntax?]
                        [inspector (or/c inspector? #f)])
         syntax?]{

返回 @racket[stx]。

@history[#:changed "8.2.0.4" @elem{更改为直接返回 @racket[stx]，而不再``disarm'' syntax。}]}


@defproc[(syntax-rearm [stx syntax?]
                       [from-stx syntax?]
                       [use-mode? any/c #f])
         syntax?]{

返回 @racket[stx]。

@history[#:changed "8.2.0.4" @elem{更改为直接返回 @racket[stx]，而不再``arm'' syntax。}]}


@defproc[(syntax-taint [stx syntax?]) syntax?]{

返回 @racket[stx] 的 @deftech{受污}版本；如果它已经受污，则直接返回 @racket[stx]。}
