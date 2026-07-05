#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "symbols"]{Symbols}

@deftech{Symbol} 是一个原子值，其打印形式类似于一个带有 @litchar{'} 前缀的 identifier。一个以 @litchar{'} 开头并继续具有 identifier 的表达式会生成一个 symbol 值。

@examples[
'a
(symbol? 'a)
]

对于任何字符序列，恰好有一个对应的 symbol 是 @defterm{interned}；调用 @racket[string->symbol] procedure，或者 @racket[read] 一个来自语法的 identifier，会生成一个 interned symbol。由于 interned symbol 之间可以用 @racket[eq?] 廉价比较（从而也可以用 @racket[eqv?] 或 @racket[equal?] 比较），它们是有用作标签和枚举的便捷值。

Symbol 是大小写敏感的。通过使用 @racketfont{#ci} 前缀或其它方式，reader 可以被配置成将字符序列大小写折叠到 symbol，但 reader 默认保留大小写。

@examples[
(eq? 'a 'a)
(eq? 'a (string->symbol "a"))
(eq? 'a 'b)
(eq? 'a 'A)
(eval:alts @#,elem{@racketfont{#ci}@racketvalfont{@literal{'A}}} #ci'A)
]

任何字符串（即任何字符序列）都可以传给 @racket[string->symbol] 以获得对应的 symbol。对于 reader 输入，任何字符都可以直接出现在 identifier 中，空白字符和以下特殊字符除外：

@t{
  @hspace[2] @litchar{(} @litchar{)} @litchar{[} @litchar{]}
  @litchar["{"] @litchar["}"]
  @litchar{"} @litchar{,} @litchar{'} @litchar{`}
  @litchar{;} @litchar{#} @litchar{|} @litchar{\}
}

实际上，@litchar{#} 仅在出现在 symbol 的开头时才被禁止，并且只有在其后未跟 @litchar{%} 时才被禁止；否则 @litchar{#} 也是被允许的。此外，单独的 @litchar{.} 并不是 symbol。

空白字符或特殊字符可以通过 @litchar{|} 或 @litchar{\} 引用而包含在 identifier 中。这些引用机制用于打印那些包含特殊字符或可能看起来像数字的 identifier。

@examples[
(string->symbol "one, two")
(string->symbol "6")
]

@refdetails/gory["parse-symbol"]{symbol 的 syntax}

@racket[write] 函数打印 symbol 时不带 @litchar{'} 前缀。symbol 的 @racket[display] 形式则与对应的字符串相同。

@examples[
(write 'Apple)
(display 'Apple)
(write '|6|)
(display '|6|)
]

@racket[gensym] 和 @racket[string->uninterned-symbol] procedure 生成新鲜的 @defterm{未驻留}（uninterned）symbol，它们不等于（根据 @racket[eq?]）任何此前已驻留或未驻留的 symbol。未驻留 symbol 适合作为有别于其它任何值的新鲜标签。

@examples[
(define s (gensym))
(eval:alts s 'g42)
(eval:alts (eq? s 'g42) #f)
(eq? 'a (string->uninterned-symbol "a"))
]

@refdetails["symbols"]{symbols}
