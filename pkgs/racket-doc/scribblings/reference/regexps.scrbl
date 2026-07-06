#lang scribble/doc
@(require scribble/bnf 
          "mz.rkt" 
          "rx.rkt"
          (for-syntax racket/base))

@title[#:tag "regexp"]{Regular Expressions}

@section-index{regexps}
@section-index{pattern matching}
@section-index["strings" "pattern matching"]
@section-index["input ports" "pattern matching"]

@(define-syntax (rx-examples stx)
  (syntax-case stx ()
   [(_ [num rx input] ...)
    (with-syntax ([(ex ...)
                   (map (lambda (num rx input)
                          `(eval:alts #,(racket 
                                         (code:line 
                                          (regexp-match ,rx ,input) 
                                          (code:comment @#,t["ex"
                                                             (let ([s (number->string ,num)])
                                                               (elemtag `(rxex ,s) 
                                                                        (racketcommentfont s)))
                                                             ,(if (pregexp? (syntax-e rx))
                                                                  `(list ", uses " (racketmetafont "#px"))
                                                                  "")])))
                                      (regexp-match ,rx ,input)))
                        (syntax->list #'(num ...))
                        (syntax->list #'(rx ...))
                        (syntax->list #'(input ...)))])
      #`(examples ex ...))]))

@guideintro["regexp"]{regular expressions}

@deftech{正则表达式}以字符串或字节字符串的形式指定，
使用的模式语言与 Unix 工具 @exec{egrep} 或 Perl 相同。
字符串指定的模式产生字符 regexp 匹配器，字节字符串模式产生
字节 regexp 匹配器。如果字符 regexp 用于字节字符串或输入端口，
它匹配匹配字符流的 UTF-8 编码（参见 @secref["encodings"]）；
如果字节 regexp 用于字符串，它匹配该字符串 UTF-8 编码中的字节。

以字符串或字节字符串形式表示的正则表达式可以编译为
@deftech{regexp 值}，与字符串或字节字符串形式相比，
@racket[regexp-match] 等函数可以更高效地使用它。
@racket[regexp] 和 @racket[byte-regexp] 过程分别将字符串
或字节字符串转换为 regexp 值，使用与 @exec{egrep} 最兼容的
正则表达式语法。@racket[pregexp] 和 @racket[byte-pregexp] 过程
使用与 Perl 更兼容的稍有不同的正则表达式语法生成 regexp 值。

两个 @tech{regexp 值}如果具有相同的源、使用相同的模式语言、
且都是字符 regexp 或都是字节 regexp，则是 @racket[equal?] 的。

字面量或打印的 @tech{regexp 值}以 @litchar{#rx} 或
@litchar{#px} 开头。@see-read-print["regexp"]{正则表达式}
默认 reader 生成的 Regexp 值在 @racket[read-syntax] 模式下
是 @tech{interned} 的。

在 Racket 的 @tech[#:doc '(lib "scribblings/guide/guide.scrbl")]{BC} 变体上，
@tech{regexp 值}的内部大小限制为 32 KB；此限制大致对应
于包含 32,000 个文字字符或 5,000 个运算符的源字符串。

@;------------------------------------------------------------------------
@section[#:tag "regexp-syntax"]{Regexp Syntax}

以下语法规范描述了表示正则表达式的字符串的内容。
相应字符串的语法可能涉及额外的转义字符。例如，正则表达式
@litchar{(.*)\1} 可以用字符串
@racket["(.*)\\1"] 或 regexp 常量 @racket[#rx"(.*)\\1"]
表示；正则表达式中的 @litchar{\} 必须转义才能包含
在字符串或 regexp 常量中。

@racket[regexp] 和 @racket[pregexp] 语法共享一个共同的核心：

@common-table

以下完成了 @racket[regexp] 的语法，它将
@litchar["{"] 和 @litchar["}"] 视为字面量，在
范围内将 @litchar{\} 视为字面量，在范围外将
@litchar{\} 视为字面量生成器。

@rx-table

以下完成了 @racket[pregexp] 的语法，它使用
@litchar["{"] 和 @litchar["}"] 进行有界重复，
并在范围内外都使用 @litchar{\} 表示元字符。

@px-table

在大小写不敏感模式下，形式为
@litchar{\}@nonterm{n} 的反向引用仅在 ASCII 字符方面
进行大小写不敏感匹配。

Unicode 类别如下。

@category-table

当带有 @litchar{.} 的字符 regexp 与字节字符串或输入端口
一起使用时，@litchar{.} 仅匹配输入中的有效 UTF-8 编码。
字节 regexp 中的 @litchar{.} 匹配任何字节（multi 模式下
的换行符除外）。用 @litchar{\P} 或 @litchar{\p} 指定的
属性仅匹配有效的 UTF-8 编码，无论它是写在字符 regexp 还是
字节 regexp 中。类似地，@litchar{\X} 仅匹配有效的 UTF-8
编码序列，并且不会匹配序列的前缀（即使只匹配前缀可以让模式
的其余部分匹配剩余的输入），但 grapheme-cluster 序列可以
被无效的 UTF-8 编码终止。

@rx-examples[
[1 #rx"a|b" "cat"]
[2 #rx"[at]" "cat"]
[3 #rx"ca*[at]" "caaat"]
[4 #rx"ca+[at]" "caaat"]
[5 #rx"ca?t?" "ct"]
[6 #rx"ca*?[at]" "caaat"]
[7 #px"ca{2}" "caaat"]
[8 #px"ca{2,}t" "catcaat"]
[9 #px"ca{,2}t" "caaatcat"]
[10 #px"ca{1,2}t" "caaatcat"]
[11 #rx"(c<*)(a*)" "caat"]
[12 #rx"[^ca]" "caat"]
[13 #rx".(.)." "cat"]
[14 #rx"^a|^c" "cat"]
[15 #rx"a$|t$" "cat"]
[16 #px"c(.)\\1t" "caat"]
[17 #px".\\b." "cat in hat"]
[18 #px".\\B." "cat in hat"]
[19 #px"\\p{Ll}" "Cat"]
[20 #px"\\P{Ll}" "cat!"]
[21 #rx"\\|" "c|t"]
[22 #rx"[a-f]*" "cat"]
[23 #px"[a-f\\d]*" "1cat"]
[24 #px" [\\w]" "cat hat"]
[25 #px"t[\\s]" "cat\nhat"]
[26 #px"[[:lower:]]+" "Cat"]
[27 #rx"[]]" "c]t"]
[28 #rx"[-]" "c-t"]
[29 #rx"[]a[]+" "c[a]t"]
[30 #rx"[a^]+" "ca^t"]
[31 #rx".a(?=p)" "cat nap"]
[32 #rx".a(?!t)" "cat nap"]
[33 #rx"(?<=n)a." "cat nap"]
[34 #rx"(?<!c)a." "cat nap"]
[35 #rx"(?i:a)[tp]" "cAT nAp"]
[36 #rx"(?(?<=c)a|b)+" "cabal"]
[37 #rx"[^^]+" "^cat^"]
]

@history[#:changed "8.15.0.8" @elem{Added @litchar{\X} grapheme cluster pattern.}]

@;------------------------------------------------------------------------
@section{Additional Syntactic Constraints}

除了匹配语法之外，正则表达式还必须满足两个语法限制：

@itemize[

 @item{在除 @nonterm{atom}@litchar{?} 之外的 @nonterm{repeat} 中，
       @nonterm{atom} 不得匹配空序列。}

 @item{在 @litchar{(?<=}@nonterm{regexp}@litchar{)} 或
       @litchar{(?<!}@nonterm{regexp}@litchar{)} 中，
       @nonterm{regexp} 只能匹配有界序列。}

]

这些约束通过以下类型系统在语法上进行检查。类型
[@math{n}, @math{m}] 对应于匹配 @math{n} 到 @math{m} 个
字符的表达式。在 @litchar{(}@nonterm{regexp}@litchar{)} 的
规则中，@nonterm{n} 表示使得左括号是用于收集匹配报告的第
@nonterm{n} 个左括号的数字。对于反向引用模式
@litchar{\}@nonterm{n}，会推断非空性，以便反向引用可以
用于重复模式；在反向引用之间存在相互依赖的情况下，推断会选择
最大化非空性的不动点。对反向引用不推断有限性（即假设反向引用
匹配任意大的序列）。没有语法约束禁止在反向引用所引用的组内
使用反向引用，尽管这种自引用可能会创建没有可能匹配的模式
（如 @litchar{(.\1)} 的情况，尽管
@litchar{(^.|\1){2}} 匹配以相同两个字符开头的输入）。

@type-table

@;------------------------------------------------------------------------
@section{Regexp Constructors}

@defproc[(regexp? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[regexp] 或 @racket[pregexp]
创建的 @tech{regexp 值}则返回 @racket[#t]，否则返回
@racket[#f]。}


@defproc[(pregexp? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[pregexp]（而不是
@racket[regexp]）创建的 @tech{regexp 值}则返回
@racket[#t]，否则返回 @racket[#f]。}


@defproc[(byte-regexp? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[byte-regexp] 或
@racket[byte-pregexp] 创建的 @tech{regexp 值}则返回
@racket[#t]，否则返回 @racket[#f]。}


@defproc[(byte-pregexp? [v any/c]) boolean?]{

如果 @racket[v] 是由 @racket[byte-pregexp]（而不是
@racket[byte-regexp]）创建的 @tech{regexp 值}则返回
@racket[#t]，否则返回 @racket[#f]。}


@defproc*[([(regexp [str string?]) regexp?]
           [(regexp [str string?]
                    [handler (or/c #f (string? . -> . any))])
            any])]{

接受正则表达式的字符串表示（使用
@secref["regexp-syntax"] 中的语法）并将其编译为
@tech{regexp 值}。其他正则表达式过程接受字符串或
@tech{regexp 值}作为匹配模式。如果正则表达式字符串被多次
使用，将字符串编译为 @tech{regexp 值}一次并用于重复匹配
比每次使用字符串更快。

如果提供了 @racket[handler] 且不为 @racket[#f]，则当
@racket[str] 不是正则表达式的有效表示时调用它并返回其结果；
@racket[handler] 的参数是描述 @racket[str] 问题的字符串。
如果 @racket[handler] 是 @racket[#f] 或未提供，则
@exnraise[exn:fail:contract]。

@racket[object-name] 过程返回 @tech{regexp 值}的源字符串。

@examples[
(regexp "ap*le")
(object-name #rx"ap*le")
(regexp "+" (λ (s) (list s)))
]

@history[#:changed "6.5.0.1" @elem{Added the @racket[handler] argument.}]}

@defproc*[([(pregexp [str string?]) pregexp?]
           [(pregexp [str string?]
                     [handler (or/c #f (string? . -> . any))])
            any])]{

类似于 @racket[regexp]，但使用稍有不同的语法
（参见 @secref["regexp-syntax"]）。结果可以与
@racket[regexp-match] 等一起使用，就像 @racket[regexp]
的结果一样。

@examples[
(pregexp "ap*le")
(regexp? #px"ap*le")
(pregexp "+" (λ (s) (vector s)))
]

@history[#:changed "6.5.0.1" @elem{Added the @racket[handler] argument.}]}

@defproc*[([(byte-regexp [bstr bytes?]) byte-regexp?]
           [(byte-regexp [bstr bytes?]
                         [handler (or/c #f (bytes? . -> . any))])
            any])]{

接受正则表达式的字节字符串表示（使用
@secref["regexp-syntax"] 中的语法）并将其编译为
byte-@tech{regexp 值}。

如果提供了 @racket[handler]，则当 @racket[bstr] 不是正则
表达式的有效表示时调用它并返回其结果。

@racket[object-name] 过程返回 @tech{regexp 值}的源字节字符串。

@examples[
(byte-regexp #"ap*le")
(object-name #rx#"ap*le")
(eval:error (byte-regexp "ap*le"))
(byte-regexp #"+" (λ (s) (list s)))
]

@history[#:changed "6.5.0.1" @elem{Added the @racket[handler] argument.}]}

@defproc*[([(byte-pregexp [bstr bytes?]) byte-pregexp?]
           [(byte-pregexp [bstr bytes?]
                          [handler (or/c #f (bytes? . -> . any))])
            any])]{

类似于 @racket[byte-regexp]，但使用稍有不同的语法
（参见 @secref["regexp-syntax"]）。结果可以与
@racket[regexp-match] 等一起使用，就像
@racket[byte-regexp] 的结果一样。

@examples[
(byte-pregexp #"ap*le")
(byte-pregexp #"+" (λ (s) (vector s)))
]

@history[#:changed "6.5.0.1" @elem{Added the @racket[handler] argument.}]}

@defproc*[([(regexp-quote [str string?] [case-sensitive? any/c #t]) string?]
           [(regexp-quote [bstr bytes?] [case-sensitive? any/c #t]) bytes?])]{

生成适合与 @racket[regexp] 一起使用的字符串或字节字符串，
用于匹配 @racket[str] 中的字面字符序列或 @racket[bstr]
中的字节序列。如果 @racket[case-sensitive?] 为 true（默认），
则生成的 regexp 以大小写敏感方式匹配 @racket[str] 或
@racket[bstr] 中的字母，否则以大小写不敏感方式匹配。

@examples[
(regexp-match "." "apple.scm")
(regexp-match (regexp-quote ".") "apple.scm")
]}

@defproc*[([(pregexp-quote [str string?] [case-sensitive? any/c #t]) string?]
           [(pregexp-quote [bstr bytes?] [case-sensitive? any/c #t]) bytes?])]{

类似于 @racket[regexp-quote]，但旨在与 @racket[pregexp]
一起使用。转义输入中所有非字母数字、非下划线字符。

@history[#:added "8.11.1.9"]
}

@defproc[(regexp-max-lookbehind [pattern (or/c regexp? byte-regexp?)])
         exact-nonnegative-integer?]{

返回 @racket[pattern] 在匹配起始位置之前可能需要参考的
最大字节数，用于确定匹配。例如，模式
@litchar{(?<=abc)d} 参考匹配的 @litchar{d} 之前的三个字节，
而 @litchar{e(?<=a..)d} 参考匹配的 @litchar{ed} 之前的
两个字节。@litchar{^} 模式可能参考前一个字节来确定当前位置
是否是输入或行的起始。

@examples[
(regexp-max-lookbehind #rx#"(?<=abc)d")
(regexp-max-lookbehind #rx#"e(?<=a..)d")
(regexp-max-lookbehind #rx"^")
]}


@defproc[(regexp-capture-group-count [pattern (or/c regexp? byte-regexp?)])
         exact-nonnegative-integer?]{

返回 @racket[pattern] 中捕获组的数量，这对应于对
@racket[pattern] 成功匹配时 @racket[regexp-match] 返回的
列表长度减一。

@examples[
(regexp-capture-group-count #rx"abcd")
(regexp-capture-group-count #rx"a(b*c)(d*)")
(regexp-capture-group-count #rx"a(?:bc)*d")
]

@history[#:added "8.15.0.8"]}


@;------------------------------------------------------------------------
@section{Regexp Matching}

@defproc[(regexp-match [pattern (or/c regexp? byte-regexp? string? bytes?)]
                       [input (or/c string? bytes? path? input-port?)]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos (or/c exact-nonnegative-integer? #f) #f]
                       [output-port (or/c output-port? #f) #f]
                       [input-prefix bytes? #""])
         (if (and (or (string? pattern) (regexp? pattern))
                  (or (string? input) (path? input)))
             (or/c #f (cons/c string? (listof (or/c string? #f))))
             (or/c #f (cons/c bytes?  (listof (or/c bytes?  #f)))))]{

尝试将 @racket[pattern]（字符串、字节字符串、@tech{regexp 值}
或 byte-@tech{regexp 值}）与 @racket[input] 的一部分进行一次
匹配。匹配器找到 @racket[input] 中匹配且最接近输入开头
（在 @racket[start-pos] 之后）的部分。

如果 @racket[input] 是一个 path，且 @racket[pattern] 是
字节字符串或基于字节的 regexp，则使用
@racket[path->bytes] 将其转换为字节字符串。否则，使用
@racket[path->string] 将 @racket[input] 转换为字符串。

可选的 @racket[start-pos] 和 @racket[end-pos] 参数选择
@racket[input] 的一部分进行匹配；默认为整个字符串或直到
文件结尾的流。当 @racket[input] 是字符串时，
@racket[start-pos] 是字符位置；当 @racket[input] 是字节
字符串时，@racket[start-pos] 是字节位置；当
@racket[input] 是输入端口时，@racket[start-pos] 是开始匹配
前要跳过的字节数。@racket[end-pos] 参数可以是
@racket[#f]，对应字符串的末尾或流中的文件结尾；否则，它像
@racket[start-pos] 一样是字符或字节位置。如果
@racket[input] 是输入端口，并且在跳过
@racket[start-pos] 字节之前到达文件结尾，则匹配失败。

在 @racket[pattern] 中，字符串开头的 @litchar{^} 指的是
@racket[input] 在 @racket[start-pos] 之后的第一个位置，
假设 @racket[input-prefix] 是 @racket[#""]。输入末尾的
@litchar{$} 指的是第 @racket[end-pos] 个位置或（在输入
端口的情况下）文件结尾，以先到者为准。

@racket[input-prefix] 指定有效地在 @racket[input] 之前的
字节，用于 @litchar{^} 和其他 look-behind 匹配。例如，
@racket[#""] 前缀意味着 @litchar{^} 在流的开头匹配，
而 @racket[#"\n"] @racket[input-prefix] 意味着行首
@litchar{^} 可以匹配输入的开头，而文件开头 @litchar{^}
则不能。

如果匹配失败，返回 @racket[#f]。如果匹配成功，返回一个
包含字符串或字节字符串（可能还有 @racket[#f]）的列表。
仅当 @racket[input] 是字符串且 @racket[pattern] 不是字节
regexp 时，列表才包含字符串。否则，列表包含字节字符串
（如果 @racket[input] 是字符串，则为 @racket[input] 的
UTF-8 编码的子串）。

结果列表中的第一个（字节）字符串是 @racket[input] 中匹配
@racket[pattern] 的部分。如果 @racket[input] 的两个部分
可以匹配 @racket[pattern]，则找到最早开始的那个匹配。

如果 @racket[pattern] 包含带括号的子表达式（但左括号后跟
@litchar{?}时除外），则列表中返回额外的（字节）字符串。
子表达式的匹配按 @racket[pattern] 中左括号的顺序提供。
当子表达式出现在 @litchar{|} “或”模式的分支中、
@litchar{*} “零次或多次”模式中，或者其他整体模式
可以成功而子表达式不匹配的地方时，如果子表达式没有贡献
最终匹配，则返回 @racket[#f]。当单个子表达式出现在
@litchar{*} “零次或多次”模式或其他多次匹配位置中时，
列表中返回与该子表达式关联的最右匹配。

如果提供了可选的 @racket[output-port] 作为输出端口，则
@racket[input] 中从开头（不是 @racket[start-pos]）到匹配
之前的部分会被写入端口。如果没有找到匹配，则将
@racket[input] 到 @racket[end-pos] 的全部内容写入端口。
当 @racket[input] 是输入端口时，此功能最有用。

当匹配输入端口时，匹配失败会读取最多 @racket[end-pos] 字节
（或文件结尾），即使 @racket[pattern] 以字符串开头
@litchar{^} 开始；另请参见 @racket[regexp-try-match]。
成功时，最终会从端口读取直到并包括匹配的所有字节，但匹配
过程是先 peek 端口的字节（使用 @racket[peek-bytes-avail!]），
然后在匹配结果确定后（重新）读取匹配的字节以丢弃它们。
不匹配的字节可能在匹配确定之前被读取和丢弃。匹配器仅在
必要时以阻塞模式 peek 以确定匹配，但如果立即可用（即无需
阻塞），它可能 peek 额外的字节来填充内部缓冲区。
@racket[pattern] 中的贪婪重复运算符，如 @litchar{*} 或
@litchar{+}，往往会强制读取端口的全部内容（直到
@racket[end-pos]）以确定匹配。

如果输入端口同时被另一个线程读取，或者端口是具有不一致的
读取和 peek 过程的自定义端口（参见 @secref["customport"]），
则 peeked 并用于匹配的字节可能与匹配完成后读取并丢弃的
字节不同；匹配器仅检查 peek 的字节。为避免这种交错，
使用 @racket[regexp-match-peek]（带 @racket[_progress]
参数）后跟 @racket[port-commit-peeked]。

@examples[
(regexp-match #rx"x." "12x4x6")
(regexp-match #rx"y." "12x4x6")
(regexp-match #rx"x." "12x4x6" 3)
(regexp-match #rx"x." "12x4x6" 3 4)
(regexp-match #rx#"x." "12x4x6")
(regexp-match #rx"x." "12x4x6" 0 #f (current-output-port))
(regexp-match #rx"(-[0-9]*)+" "a-12--345b")
]}


@defproc[(regexp-match* [pattern (or/c regexp? byte-regexp? string? bytes?)]
                        [input (or/c string? bytes? path? input-port?)]
                        [start-pos exact-nonnegative-integer? 0]
                        [end-pos (or/c exact-nonnegative-integer? #f) #f]
                        [input-prefix bytes? #""]
                        [#:match-select match-select
                         (or/c (list? . -> . (or/c any/c list?))
                               #f)
                         car]
                        [#:gap-select? gap-select any/c #f])
         (if (and (or (string? pattern) (regexp? pattern))
                  (or (string? input) (path? input)))
             (listof (or/c string? (listof (or/c #f string?))))
             (listof (or/c bytes? (listof (or/c #f bytes?)))))]{

类似于 @racket[regexp-match]，但结果是一个字符串或字节
字符串的列表，对应 @racket[input] 中 @racket[pattern] 的
一系列匹配。

@racket[pattern] 按顺序用于查找匹配，每次匹配尝试从上次
匹配的末尾开始，@litchar{^} 仅对第一次匹配允许匹配输入的
开头（如果 @racket[input-prefix] 是 @racket[#""]）。
空匹配像其他匹配一样处理，返回零长度的字符串或字节序列
（它们在使其成为 @racket[regexp-split] 的补充方面更有用），
但 @racket[pattern] 被限制不能在空匹配之后立即匹配空序列。

如果 @racket[input]（在 @racket[start-pos] 到
@racket[end-pos] 范围内）不包含匹配，则返回
@racket[null]。否则，结果列表中的每个项目是来自
@racket[input] 的匹配 @racket[pattern] 的不同子字符串或
字节序列。@racket[end-pos] 参数可以是 @racket[#f]，
以匹配到 @racket[input] 的末尾（如果 @racket[input] 是
输入端口，则对应文件结尾）。

@examples[
(regexp-match* #rx"x." "12x4x6")
(regexp-match* #rx"x*" "12x4x6")
]

@racket[match-select] 函数指定收集的结果。默认的
@racket[car] 意味着结果是匹配列表，不返回带括号的子模式。
它可以作为“选择器”函数给出，该函数从列表中选择一个项目，
或者可以选择一个项目列表。例如，你可以使用 @racket[cdr]
获取带括号的子模式匹配的列表的列表，或使用 @racket[values]
（作为恒等函数）同时获取完整匹配。（注意，选择器必须选择
其输入列表的一个元素或一个元素列表，但不能检查其输入，
因为它们可以是字符串列表或位置对列表。此外，选择器在其
选择中必须一致。）

@examples[
(regexp-match* #rx"x(.)" "12x4x6" #:match-select cadr)
(regexp-match* #rx"x(.)" "12x4x6" #:match-select values)
]

此外，将 @racket[gap-select] 指定为非 @racket[#f] 值会使
结果成为一个交错列表，包含匹配以及匹配之间的分隔符，
以分隔符开始和结束。在这种情况下，可以将
@racket[match-select] 设置为 @racket[#f] 以仅返回分隔符，
使这种用法等同于 @racket[regexp-split]。

@examples[
(regexp-match* #rx"x(.)" "12x4x6" #:match-select cadr #:gap-select? #t)
(regexp-match* #rx"x(.)" "12x4x6" #:match-select #f #:gap-select? #t)
]}


@defproc[(regexp-try-match [pattern (or/c regexp? byte-regexp? string? bytes?)]
                           [input input-port?]
                           [start-pos exact-nonnegative-integer? 0]
                           [end-pos (or/c exact-nonnegative-integer? #f) #f]
                           [output-port (or/c output-port? #f) #f]
                           [input-prefix bytes? #""])
         (or/c #f (cons/c bytes? (listof (or/c bytes? #f))))]{

类似于输入端口上的 @racket[regexp-match]，但如果匹配失败，
不会从 @racket[in] 读取和丢弃任何字符。

此过程特别适用于以字符串开头 @litchar{^} 开始或带有非
@racket[#f] @racket[end-pos] 的 @racket[pattern]，因为
每个都限制了 peek 端口的数量。否则，请注意在匹配成功或
失败之前，流的大部分可能被 peek（因此被拉入内存）。}


@defproc[(regexp-match-positions [pattern (or/c regexp? byte-regexp? string? bytes?)]
                                 [input (or/c string? bytes? path? input-port?)]
                                 [start-pos exact-nonnegative-integer? 0]
                                 [end-pos (or/c exact-nonnegative-integer? #f) #f]
                                 [output-port (or/c output-port? #f) #f]
                                 [input-prefix bytes? #""])
          (or/c (cons/c (cons/c exact-nonnegative-integer?
                                exact-nonnegative-integer?)
                        (listof (or/c (cons/c exact-integer?
                                              exact-integer?)
                                      #f)))
                #f)]{

类似于 @racket[regexp-match]，但返回数字对（和
@racket[#f]）列表而不是字符串列表。每对数字指的是
@racket[input] 中的字符或字节范围。如果对相同参数使用
@racket[regexp-match] 的结果将是字节字符串列表，则结果
范围对应字节范围；在这种情况下，如果 @racket[input] 是
字符串，字节范围对应字符串 UTF-8 编码中的字节。

范围结果以 @racket[substring] 和 @racket[subbytes] 兼容
的方式返回，独立于 @racket[start-pos]。在输入端口的情况下，
返回的位置表示在第一个匹配字节之前读取的字节数（包括
@racket[start-pos]）。

@examples[
(regexp-match-positions #rx"x." "12x4x6")
(regexp-match-positions #rx"x." "12x4x6" 3)
(regexp-match-positions #rx"(-[0-9]*)+" "a-12--345b")
]

如果 @racket[input-prefix] 非空且 @racket[pattern] 包含
lookbehind 模式，则第一个之后的范围结果可能包含负数。
这些范围从 @racket[input-prefix] 而不是 @racket[input]
开始。更一般地，当 @racket[start-pos] 为正时，小于
@racket[start-pos] 的范围结果从 @racket[input-prefix] 开始。

@examples[
(regexp-match-positions #rx"(?<=(.))." "a" 0 #f #f #"x")
(regexp-match-positions #rx"(?<=(..))." "a" 0 #f #f #"x")
(regexp-match-positions #rx"(?<=(..))." "_a" 1 #f #f #"x")
]

虽然 @racket[input-prefix] 总是字节字符串，但当返回的
位置是字符串索引并且它们引用 @racket[input-prefix] 的
一部分时，它们对应 @racket[input-prefix] 尾部的 UTF-8 解码。

@examples[
(bytes-length (string->bytes/utf-8 "\u3BB"))
(regexp-match-positions #rx"(?<=(.))." "a" 0 #f #f (string->bytes/utf-8 "\u3BB"))
]}

@defproc[(regexp-match-positions* [pattern (or/c regexp? byte-regexp? string? bytes?)]
                                  [input (or/c string? bytes? path? input-port?)]
                                  [start-pos exact-nonnegative-integer? 0]
                                  [end-pos (or/c exact-nonnegative-integer? #f) #f]
                                  [input-prefix bytes? #""]
                                  [#:match-select match-select
                                   (list? . -> . (or/c any/c list?))
                                   car])
         (or/c (listof (cons/c exact-nonnegative-integer?
                               exact-nonnegative-integer?))
               (listof (listof (or/c #f (cons/c exact-nonnegative-integer?
                                                exact-nonnegative-integer?)))))]{

类似于 @racket[regexp-match-positions]，但像
@racket[regexp-match*] 一样返回多个匹配。

@examples[
(regexp-match-positions* #rx"x." "12x4x6")
(regexp-match-positions* #rx"x(.)" "12x4x6" #:match-select cadr)
]

请注意，与 @racket[regexp-match*] 不同，没有
@racket[#:gap-select?] 输入关键字，因为此信息可以很容易
地从结果匹配中推断出来。
}


@defproc[(regexp-match? [pattern (or/c regexp? byte-regexp? string? bytes?)]
                        [input (or/c string? bytes? path? input-port?)]
                        [start-pos exact-nonnegative-integer? 0]
                        [end-pos (or/c exact-nonnegative-integer? #f) #f]
                        [output-port (or/c output-port? #f) #f]
                        [input-prefix bytes? #""])
           boolean?]{

类似于 @racket[regexp-match]，但匹配成功时仅返回
@racket[#t]，否则返回 @racket[#f]。

@examples[
(regexp-match? #rx"x." "12x4x6")
(regexp-match? #rx"y." "12x4x6")
]}


@defproc[(regexp-match-exact? [pattern (or/c regexp? byte-regexp? string? bytes?)]
                              [input (or/c string? bytes? path?)])
          boolean?]{

类似于 @racket[regexp-match?]，但仅当找到的第一个匹配
是整个 @racket[input] 的内容时才返回 @racket[#t]。

@examples[
(regexp-match-exact? #rx"x." "12x4x6")
(regexp-match-exact? #rx"1.*x." "12x4x6")
]

请注意，如果 @racket[pattern] 先生成了对 @racket[input]
的部分匹配，则 @racket[regexp-match-exact?] 可能返回
@racket[#f]，即使 @racket[pattern] 也可以生成完整匹配。
要检查是否存在覆盖整个 @racket[input] 的任何匹配，
请使用带有 @elem{@litchar{^(?:}@racket[pattern]@litchar{)$}}
的 @racket[regexp-match?]。

@examples[
(regexp-match-exact? #rx"a|ab" "ab")
(regexp-match? #rx"^(?:a|ab)$" "ab")
]

@litchar{(?:)} 分组是必要的，因为连接运算符的优先级低于
选择运算符；没有它的正则表达式 @litchar{^a|ab$} 匹配
任何以 @litchar{a} 开头或以 @litchar{ab} 结尾的输入。

@examples[
(regexp-match? #rx"^a|ab$" "123ab")
]}


@defproc[(regexp-match-peek [pattern (or/c regexp? byte-regexp? string? bytes?)]
                            [input input-port?]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos (or/c exact-nonnegative-integer? #f) #f]
                            [progress (or/c progress-evt? #f) #f]
                            [input-prefix bytes? #""])
          (or/c (cons/c bytes? (listof (or/c bytes? #f)))
                #f)]{

类似于输入端口上的 @racket[regexp-match]，但只从
@racket[input] peek 字节而不读取它们。此外，可选的
@racket[progress] 参数（而不是 output port）是
@racket[input] 的进度事件（参见
@racket[port-progress-evt]）。如果 @racket[progress] 就绪，
则匹配停止从 @racket[input] peek 并返回 @racket[#f]。
@racket[progress] 参数可以是 @racket[#f]，在这种情况下，
如果另一个进程同时从 @racket[input] 读取，peek 可能会以
不一致的信息继续。

@examples[
(define p (open-input-string "a abcd"))
(regexp-match-peek ".*bc" p)
(regexp-match-peek ".*bc" p 2)
(regexp-match ".*bc" p 2)
(peek-char p)
(regexp-match ".*bc" p)
(peek-char p)
]}


@defproc[(regexp-match-peek-positions [pattern (or/c regexp? byte-regexp? string? bytes?)]
                            [input input-port?]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos (or/c exact-nonnegative-integer? #f) #f]
                            [progress (or/c progress-evt? #f) #f]
                            [input-prefix bytes? #""])
          (or/c (cons/c (cons/c exact-nonnegative-integer?
                                exact-nonnegative-integer?)
                        (listof (or/c (cons/c exact-nonnegative-integer?
                                              exact-nonnegative-integer?)
                                      #f)))
                #f)]{

类似于输入端口上的 @racket[regexp-match-positions]，但只
从 @racket[input] peek 字节而不读取它们，并带有与
@racket[regexp-match-peek] 类似的 @racket[progress] 参数。}


@defproc[(regexp-match-peek-immediate [pattern (or/c regexp? byte-regexp? string? bytes?)]
                            [input input-port?]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos (or/c exact-nonnegative-integer? #f) #f]
                            [progress (or/c progress-evt? #f) #f]
                            [input-prefix bytes? #""])
          (or/c (cons/c bytes? (listof (or/c bytes? #f)))
                #f)]{

类似于 @racket[regexp-match-peek]，但仅尝试匹配无需阻塞
即可从 @racket[input] 获取的字节。如果尚未可用的字符
可能用于匹配 @racket[pattern]，则匹配失败。}


@defproc[(regexp-match-peek-positions-immediate [pattern (or/c regexp? byte-regexp? string? bytes?)]
                            [input input-port?]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos (or/c exact-nonnegative-integer? #f) #f]
                            [progress (or/c progress-evt? #f) #f]
                            [input-prefix bytes? #""])
          (or/c (cons/c (cons/c exact-nonnegative-integer?
                                exact-nonnegative-integer?)
                        (listof (or/c (cons/c exact-nonnegative-integer?
                                              exact-nonnegative-integer?)
                                      #f)))
                #f)]{

类似于 @racket[regexp-match-peek-positions]，但仅尝试匹配
无需阻塞即可从 @racket[input] 获取的字节。如果尚未
可用的字符可能用于匹配 @racket[pattern]，则匹配失败。}


@defproc[(regexp-match-peek-positions*
                            [pattern (or/c regexp? byte-regexp? string? bytes?)]
                            [input input-port?]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos (or/c exact-nonnegative-integer? #f) #f]
                            [input-prefix bytes? #""]
                            [#:match-select match-select
                             (list? . -> . (or/c any/c list?))
                             car])
         (or/c (listof (cons/c exact-nonnegative-integer?
                               exact-nonnegative-integer?))
               (listof (listof (or/c #f (cons/c exact-nonnegative-integer?
                                                exact-nonnegative-integer?)))))]{

类似于 @racket[regexp-match-peek-positions]，但像
@racket[regexp-match-positions*] 一样返回多个匹配。}

@defproc[(regexp-match/end [pattern (or/c regexp? byte-regexp? string? bytes?)]
                       [input (or/c string? bytes? path? input-port?)]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos (or/c exact-nonnegative-integer? #f) #f]
                       [output-port (or/c output-port? #f) #f]
                       [input-prefix bytes? #""]
                       [count exact-nonnegative-integer? 1])
         (values
          (if (and (or (string? pattern) (regexp? pattern))
                   (or/c (string? input) (path? input)))
              (or/c #f (cons/c string? (listof (or/c string? #f))))
              (or/c #f (cons/c bytes?  (listof (or/c bytes?  #f)))))
          (or/c #f bytes?))]{

类似于 @racket[regexp-match]，但有第二个结果：一个最多
@racket[count] 字节的字节字符串，对应于通向匹配末尾的输入
（可能包括 @racket[input-prefix]）；如果未找到匹配，
第二个结果为 @racket[#f]。

第二个结果可用作 @racket[input-prefix]，用于从第一个匹配
的末尾开始在 @racket[input] 上尝试第二次匹配。在这种情况下，
使用 @racket[regexp-max-lookbehind] 确定 @racket[count]
的适当值。}

@deftogether[(
@defproc[(regexp-match-positions/end [pattern (or/c regexp? byte-regexp? string? bytes?)]
                                  [input (or/c string? bytes? path? input-port?)]
                                  [start-pos exact-nonnegative-integer? 0]
                                  [end-pos (or/c exact-nonnegative-integer? #f) #f]
                                  [input-prefix bytes? #""]
                                  [count exact-nonnegative-integer? 1])
         (values (listof (cons/c exact-nonnegative-integer?
                                 exact-nonnegative-integer?))
                 (or/c #f bytes?))]
@defproc[(regexp-match-peek-positions/end [pattern (or/c regexp? byte-regexp? string? bytes?)]
                            [input input-port?]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos (or/c exact-nonnegative-integer? #f) #f]
                            [progress (or/c progress-evt? #f) #f]
                            [input-prefix bytes? #""]
                            [count exact-nonnegative-integer? 1])
         (values
          (or/c (cons/c (cons/c exact-nonnegative-integer?
                                exact-nonnegative-integer?)
                        (listof (or/c (cons/c exact-nonnegative-integer?
                                              exact-nonnegative-integer?)
                                      #f)))
                #f)
          (or/c #f bytes?))]
@defproc[(regexp-match-peek-positions-immediate/end [pattern (or/c regexp? byte-regexp? string? bytes?)]
                            [input input-port?]
                            [start-pos exact-nonnegative-integer? 0]
                            [end-pos (or/c exact-nonnegative-integer? #f) #f]
                            [progress (or/c progress-evt? #f) #f]
                            [input-prefix bytes? #""]
                            [count exact-nonnegative-integer? 1])
         (values
          (or/c (cons/c (cons/c exact-nonnegative-integer?
                                exact-nonnegative-integer?)
                        (listof (or/c (cons/c exact-nonnegative-integer?
                                              exact-nonnegative-integer?)
                                      #f)))
                #f)
          (or/c #f bytes?))]
)]{

类似于 @racket[regexp-match-positions] 等，但带有与
@racket[regexp-match/end] 一样的第二个结果。}

@;------------------------------------------------------------------------
@section{Regexp Splitting}

@defproc[(regexp-split [pattern (or/c regexp? byte-regexp? string? bytes?)]
                       [input (or/c string? bytes? input-port?)]
                       [start-pos exact-nonnegative-integer? 0]
                       [end-pos (or/c exact-nonnegative-integer? #f) #f]
                       [input-prefix bytes? #""])
         (if (and (or (string? pattern) (regexp? pattern))
                  (string? input))
             (cons/c string? (listof string?))
             (cons/c bytes? (listof bytes?)))]{

@racket[regexp-match*] 的补集：结果是一个来自
@racket[input] 的字符串列表（如果 @racket[pattern] 是
字符串或字符 regexp 且 @racket[input] 是字符串）或字节
字符串列表（否则），它们由对 @racket[pattern] 的匹配分隔。
相邻匹配之间用 @racket[""] 或 @racket[#""] 分隔。
零长度匹配的处理方式与 @racket[regexp-match*] 相同。

如果 @racket[input]（在 @racket[start-pos] 到
@racket[end-pos] 范围内）不包含匹配，则结果是一个包含
@racket[input] 内容（从 @racket[start-pos] 到
@racket[end-pos]）作为单个元素的列表。如果匹配发生在
@racket[input] 的开头（在 @racket[start-pos] 处），则
结果列表将以空字符串或字节字符串开头；如果匹配发生在末尾
（在 @racket[end-pos] 处），则列表将以空字符串或字节
字符串结尾。@racket[end-pos] 参数可以是 @racket[#f]，
在这种情况下，分割进行到 @racket[input] 的末尾（如果
@racket[input] 是输入端口，则对应文件结尾）。

@examples[
(regexp-split #rx" +" "12  34")
(regexp-split #rx"." "12  34")
(regexp-split #rx"" "12  34")
(regexp-split #rx" *" "12  34")
(regexp-split #px"\\b" "12, 13 and 14.")
(regexp-split #rx" +" "")
]}

@;------------------------------------------------------------------------
@section{Regexp Substitution}

@defproc[(regexp-replace [pattern (or/c regexp? byte-regexp? string? bytes?)]
                         [input (or/c string? bytes?)]
                         [insert (or/c string? bytes?
                                       (string? string? ... . -> . string?)
                                       (bytes? bytes? ... . -> . bytes?))]
                         [input-prefix bytes? #""])
         (if (and (or (string? pattern) (regexp? pattern))
                  (string? input))
             string?
             bytes?)]{

使用 @racket[pattern] 对 @racket[input] 执行匹配，然后
返回一个字符串或字节字符串，其中 @racket[input] 的匹配部分
被替换为 @racket[insert]。如果 @racket[pattern] 不匹配
@racket[input] 的任何部分，则原样返回 @racket[input]。

@racket[insert] 参数可以是（字节）字符串，也可以是返回
（字节）字符串的函数。在后一种情况下，函数应用于
@racket[regexp-match] 将返回的值列表（即第一个参数是
完整匹配，然后每个带括号的子表达式一个参数）以获取替换的
（字节）字符串。

If @racket[pattern] is a string or character regexp and @racket[input]
is a string, then @racket[insert] must be a string or a procedure that
accept strings, and the result is a string. If @racket[pattern] is a
byte string or byte regexp, or if @racket[input] is a byte string,
then @racket[insert] as a string is converted to a byte string,
@racket[insert] as a procedure is called with a byte string, and the
result is a byte string.

如果 @racket[insert] 包含 @litchar{&}，则在代入匹配位置
之前，@litchar{&} 被替换为 @racket[input] 的匹配部分。
如果 @racket[insert] 包含某个整数 @nonterm{n} 的
@litchar{\}@nonterm{n}，则它被替换为 @racket[input] 中的
第 @nonterm{n} 个匹配子表达式。@litchar{&} 和
@litchar{\0} 是别名。如果第 @nonterm{n} 个子表达式未
在匹配中使用，或者 @nonterm{n} 大于 @racket[pattern]
中子表达式的数量，则 @litchar{\}@nonterm{n} 被替换为
空字符串。

要替换字面的 @litchar{&} 或 @litchar{\}，分别在
@racket[insert] 中使用 @litchar{\&} 和
@litchar{\\}。@racket[insert] 中的 @litchar{\$}
等同于空序列；这可以用来终止 @litchar{\} 后面的数字
@nonterm{n}。如果 @racket[insert] 中的 @litchar{\}
后跟数字、@litchar{&}、@litchar{\} 或 @litchar{$}
以外的任何内容，则 @litchar{\} 本身被视为
@litchar{\0}。

请注意，前面段落中描述的 @litchar{\} 是
@racket[insert] 的字符或字节。要将这样的
@racket[insert] 写成 Racket 字符串字面量，需要在
@litchar{\} 之前使用转义 @litchar{\}。例如，Racket
常量 @racket["\\1"] 是 @litchar{\1}。

@examples[
(regexp-replace #rx"mi" "mi casa" "su")
(regexp-replace #rx"mi" "mi casa" string-upcase)
(regexp-replace #rx"([Mm])i ([a-zA-Z]*)" "Mi Casa" "\\1y \\2")
(regexp-replace #rx"([Mm])i ([a-zA-Z]*)" "mi cerveza Mi Mi Mi"
                "\\1y \\2")
(regexp-replace #rx"x" "12x4x6" "\\\\")
(display (regexp-replace #rx"x" "12x4x6" "\\\\"))
]}

@defproc[(regexp-replace* [pattern (or/c regexp? byte-regexp? string? bytes?)]
                          [input (or/c string? bytes?)]
                          [insert (or/c string? bytes?
                                        (string? string? ... . -> . string?)
                                        (bytes? bytes? ... . -> . bytes?))]
                          [start-pos exact-nonnegative-integer? 0]
                          [end-pos (or/c exact-nonnegative-integer? #f) #f]
                          [input-prefix bytes? #""])
         (or/c string? bytes?)]{

类似于 @racket[regexp-replace]，但将 @racket[input] 中
@racket[pattern] 的每个实例替换为 @racket[insert]，
而不仅仅是第一个匹配。仅当没有匹配、
@racket[start-pos] 为 @racket[0]、且
@racket[end-pos] 为 @racket[#f] 或 @racket[input] 的长度
时，结果才是 @racket[input]。只替换 @racket[input] 中
@racket[pattern] 的非重叠实例，因此插入字符串中的
@racket[pattern] 实例 @italic{不会}被递归替换。
零长度匹配的处理方式与 @racket[regexp-match*] 相同。

可选的 @racket[start-pos] 和 @racket[end-pos] 参数选择
@racket[input] 的一部分进行匹配；默认为整个字符串或直到
文件结尾的流。

@examples[
(regexp-replace* #rx"([Mm])i ([a-zA-Z]*)" "mi cerveza Mi Mi Mi"
                 "\\1y \\2")
(regexp-replace* #rx"([Mm])i ([a-zA-Z]*)" "mi cerveza Mi Mi Mi"
                 (lambda (all one two)
                   (string-append (string-downcase one) "y"
                                  (string-upcase two))))
(regexp-replace* #px"\\w" "hello world" string-upcase 0 5)
(display (regexp-replace* #rx"x" "12x4x6" "\\\\"))
]

@history[#:changed "8.1.0.7" @elem{Changed to return @racket[input] when no
                                   replacements are performed.}]}

@defproc[(regexp-replaces [input (or/c string? bytes?)]
                          [replacements
                           (listof
                            (list/c (or/c regexp? byte-regexp? string? bytes?)
                                    (or/c string? bytes?
                                          (string? string? ... . -> . string?)
                                          (bytes? bytes? ... . -> . bytes?))))])
         (or/c string? bytes?)]{

执行一系列 @racket[regexp-replace*] 操作，其中
@racket[replacements] 中的每个元素指定一个替换，格式为
@racket[(list _pattern _insert)]。替换按顺序进行，因此
后面的替换可以应用于前面的插入。

@examples[
(regexp-replaces "zero-or-more?"
                 '([#rx"-" "_"] [#rx"(.*)\\?$" "is_\\1"]))
(regexp-replaces "zero-or-more?"
                 '([#rx"e" "o"] [#rx"o" "oo"]))
]}

@defproc*[([(regexp-replace-quote [str string?]) string?]
           [(regexp-replace-quote [bstr bytes?]) bytes?])]{

生成适合作为 @racket[regexp-replace] 的第三个参数的字符串，
用于将 @racket[str] 中的字面字符序列或 @racket[bstr] 中
的字节作为替换插入。具体来说，@racket[str] 或
@racket[bstr] 中的每个 @litchar{\} 和 @litchar{&} 都由
引号 @litchar{\} 保护。

@examples[
(regexp-replace #rx"UT" "Go UT!" "A&M")
(regexp-replace #rx"UT" "Go UT!" (regexp-replace-quote "A&M"))
]}
