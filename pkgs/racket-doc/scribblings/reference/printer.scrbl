#lang scribble/doc
@(require scribble/bnf "mz.rkt")

@title[#:tag "printing" #:style 'quiet]{The Printer}

Racket printer 支持三种模式：

@itemlist[

 @item{@racket[write] mode prints core datatypes in such a way that
       using @racket[read] on the output produces a value that is
       @racket[equal?] to the printed value;}

 @item{@racket[display] mode prints core datatypes in a more
       ``end-user'' style rather than ``programmer'' style; for
       example, a string @racket[display]s as its content characters
       without surrounding @litchar{"}s or escapes;}

 @item{@racket[print] mode by default---when
       @racket[print-as-expression] is @racket[#t]---prints most
       datatypes in such a way that evaluating the output as an
       expression produces a value that is @racket[equal?] to the
       printed value; when @racket[print-as-expression] is set to
       @racket[#f], then @racket[print] mode is like @racket[write]
       mode.}

]

在 @racket[print] mode 且 @racket[print-as-expression] 为 @racket[#t] 时（默认情况），
值以 @deftech{quoting depth}（引用深度）@racket[0]（无引号）或 @racket[1]（带引号）打印。 初始引用深度由 @racket[print] 接受为可选参数，
某些复合数据类型的打印会为组件值调整打印深度。 例如，当列表以引用深度 @racket[0] 打印且其所有元素均为 @deftech{quotable}（可引用）时，
列表以 @litchar{'} 为前缀打印，其元素以引用深度 @racket[1] 打印。

当 @racket[print-graph] 参数设为 @racket[#t] 时，printer 首先扫描对象以检测循环。 扫描遍历 pair、mutable pair、vector、box（当 @racket[print-box] 为 @racket[#t] 时）、
hash table（当 @racket[print-hash-table] 为 @racket[#t] 且 key 被强持有时）、
由 @racket[struct->vector] 暴露的 structure 字段（当 @racket[print-struct] 为 @racket[#t] 时），
以及通过打印暴露的结构字段（当结构类型具有 @racket[prop:custom-write] 属性时）。 如果 @racket[print-graph] 为 @racket[#t]，则此信息用于通过 graph definition 和 reference 打印共享结构
（参见 @secref["parse-graph"]）。 如果在初始扫描中检测到循环，则 @racket[print-graph] 实际上会自动设为 @racket[#t]。

除了显示 @tech{byte strings} 之外，打印以 Unicode 字符定义；
关于字符流如何写入 port 的底层字节流的信息，参见 @secref["ports"]。


@section[#:tag "print-symbol"]{打印符号}

@tech{Symbols} containing spaces or special characters @racket[write] using
escaping @litchar{\} and quoting @litchar{|}s. When the
@racket[read-case-sensitive] parameter is set to @racket[#f], then
symbols containing uppercase characters also use escaping
@litchar{\} and quoting @litchar{|}s. In addition, symbols are
quoted with @litchar{|}s or leading @litchar{\} when they would
otherwise print the same as a numerical constant or as a delimited
@litchar{.} (when @racket[read-accept-dot] is @racket[#t]).

当 @racket[read-accept-bar-quote] 为 @racket[#t] 时，
如果开头一个 @litchar{|} 和结尾一个 @litchar{|} 足以正确打印符号，
则打印时使用 @litchar{|}。 Otherwise, @litchar{\}s are always used to escape special
characters, instead of quoting them with @litchar{|}s.

当 @racket[read-accept-bar-quote] 为 @racket[#f] 时，
@litchar{|} 不被视为特殊字符。以下是始终被视为特殊字符的字符：

@t{
  @hspace[2] @litchar{(} @litchar{)} @litchar{[} @litchar{]}
  @litchar["{"] @litchar["}"]
  @litchar{"} @litchar{,} @litchar{'} @litchar{`}
  @litchar{;} @litchar{\}
}

此外，当 @litchar{#} 出现在符号开头且后面未跟 @litchar{%} 时，它是特殊字符。

Symbols @racket[display] 时不转义也不引用特殊字符。
也就是说，符号的 display 形式与对其应用 @racket[symbol->string] 的 display 形式相同。

Symbols @racket[print] the same as they @racket[write], unless
@racket[print-as-expression] is set to @racket[#t] (as is the default) and the current
@tech{quoting depth} is @racket[0]. 在这种情况下，符号的 @racket[print] 形式前会加上 @litchar{'} 前缀。
就打印外围数据类型而言，symbol 是 @tech{quotable} 的。

@section[#:tag "print-number"]{打印数值}

@tech{number} 在 @racket[write]、@racket[display] 和 @racket[print] 模式中的打印方式相同。 就打印外围数据类型而言，number 是 @tech{quotable} 的。

A @tech{complex number} that is not a @tech{real number} always prints
as @nonterm{m}@litchar{+}@nonterm{n}@litchar{i} or
@nonterm{m}@litchar{-}@nonterm{n}@litchar{i}, where @nonterm{m} and
@nonterm{n} (for a non-negative imaginary part) or
@litchar{-}@nonterm{n} (for a negative imaginary part) are the printed
forms of its real and imaginary parts, respectively.

精确的 @racket[0] 打印为 @litchar{0}。 正的精确 @tech{integer} 打印为不以 @litchar{0} 开头的数字序列。 A positive, exact, real, non-integer number prints as
@nonterm{m}@litchar{/}@nonterm{n}, where @nonterm{m} and @nonterm{n}
are the printed forms of the number's numerator and denominator (as
determined by @racket[numerator] and @racket[denominator]). 负的 @tech{exact number} 打印时在数字精确否定的形式前加上 @litchar{-} 前缀。 When printing a number as
hexadecimal (e.g., via @racket[number->string]), digits @litchar{a}
though @litchar{f} are printed in lowercase. A @litchar{#e} or radix
marker such as @litchar{#d} @emph{does not} prefix the number.

作为 @tech{rational number} 的双精度 @tech{inexact number}（即 @tech{flonum}）
以 @litchar{.} 小数点、@litchar{e} 指数标记和非零指数或两者结合的形式打印。
所选形式旨在保持输出简短，约束条件是读回打印形式会产生一个 @racket[equal?] 的数字。 A @litchar{#i} @emph{does not} prefix the
number, and @litchar{#} is never used in place of a digit. A
@litchar{+} does not prefix a positive number, but a @litchar{+} or
@litchar{-} is printed before the exponent if @litchar{e} is present.
正无穷打印为 @litchar{+inf.0}，负无穷打印为 @litchar{-inf.0}，
非数字打印为 @litchar{+nan.0}。

A single-precision @tech{inexact number} that is a @tech{rational
number} prints like a double-precision number, but always with an
exponent, using @litchar{f} in place of @litchar{e} to indicate the
number's precision; if the number would otherwise print without an
exponent, @litchar{0} (with no @litchar{+}) is printed as the exponent
part. 单精度正无穷打印为 @litchar{+inf.f}，负无穷打印为 @litchar{-inf.f}，
非数字打印为 @litchar{+nan.f}。

@section[#:tag "print-extflonum"]{打印 Extflonum}

@tech{extflonum} 在 @racket[write]、@racket[display] 和 @racket[print] 模式中的打印方式相同。 就打印外围数据类型而言，extflonum 是 @tech{quotable} 的。

An extflonum prints in the same way a single-precision inexact number
(see @secref["print-number"]), but always with a @litchar{t} or
@litchar{T} exponent marker or as a suffix for @litchar{+inf.t}, @litchar{-inf.t},
or @litchar{+nan.t}. When
extflonum operations are supported, printing always uses lowercase
@litchar{t}; when extflonum operations are not supported, an
extflonum prints the same as its reader (see @secref["reader"])
source, since reading is the only way to produce an extflonum.

@section[#:tag "print-booleans"]{打印布尔值}

The @tech{boolean} constant @racket[#t] prints as @litchar{#true} or @litchar{#t} in
all modes (@racket[display], @racket[write], and @racket[print]),
depending on the value of @racket[print-boolean-long-form], and the
constant @racket[#f] prints as @litchar{#false} or @litchar{#f}. For
the purposes of printing enclosing datatypes, a symbol is
@tech{quotable}.

@section[#:tag "print-pairs"]{打印 Pair 和 List}

在 @racket[write] 和 @racket[display] 模式中，空的 @tech{list} 打印为 @litchar{()}。 @tech{pair} 通常以 @litchar{(} 开始，后跟其 @racket[car] 的打印形式。 其余打印形式取决于 @racket[cdr]：

@itemize[

 @item{If the @racket[cdr] is a pair or the empty list, then the
       printed form of the pair completes with the printed form of the
       @racket[cdr], except that the leading @litchar{(} in the
       @racket[cdr]'s printed form is omitted.}

 @item{Otherwise, the printed for of the pair continues with a space,
       @litchar{.}, another space, the printed form of the
       @racket[cdr], and a @litchar{)}.}

]

If @racket[print-reader-abbreviations] is set to @racket[#t], then
pair printing in @racket[write] mode is adjusted in the case of a pair
that starts a two-element list whose first element is @racket['quote],
@racket['quasiquote], @racket['unquote], @racket['unquote-splicing],
@racket['syntax], @racket['quasisyntax], @racket['unsyntax], or
@racket['unsyntax-splicing]. In that case, the pair is printed with
the corresponding reader syntax: @litchar{'}, @litchar{`},
@litchar{,}, @litchar[",@"], @litchar{#'}, @litchar{#`}, @litchar{#,},
or @litchar["#,@"], respectively. After the reader syntax, the second
element of the list is printed. When the list is a tail of an
enclosing list, the tail is printed after a @litchar{.} in the
enclosing list (after which the reader abbreviations work), instead of
including the tail as two elements of the enclosing list. If the
reader syntax @litchar{,} or @litchar{#,} is followed by a symbol
that prints with a leading @litchar["@"], then the printer adds an
extra space before the @litchar["@"].

The printed form of a pair is the same in both @racket[write] and
@racket[display] modes, except as the printed form of the pair's
@racket[car] and @racket[cdr] vary with the mode. The @racket[print]
form is also the same if @racket[print-as-expression] is @racket[#f]
or the quoting depth is @racket[1].

对于 @racket[print] mode 且 @racket[print-as-expression] 为
@racket[#t] 且 @tech{quoting depth} 为 @racket[0] 时，空列表打印为 @litchar{'()}。 For a pair whose @racket[car] and
@racket[cdr] are @tech{quotable}, the pair prints in @racket[write]
mode but with a @litchar{'} prefix; the pair's content is printed with
@tech{quoting depth} @racket[1]. Otherwise, when the @racket[car] or
@racket[cdr] is not @tech{quotable}, then pair prints with either
@litchar{cons} (when the @racket[cdr] is not a pair), @litchar{list}
(when the pair is a list), or @litchar{list*} (otherwise) after the
opening @litchar{(}, any @litchar{.} that would otherwise be printed
is suppressed, and the pair content is printed at @tech{quoting depth}
@racket[0]. In all cases, when @racket[print-as-expression] is
@racket[#t] for @racket[print] mode, then the value of
@racket[print-reader-abbreviations] is ignored and reader
abbreviations are always used for lists printed at @tech{quoting
depth} @racket[1].

By default, mutable pairs (as created with @racket[mcons]) print the
same as pairs for @racket[write] and @racket[display], except that
@litchar["{"] and @litchar["}"] are used instead of @litchar{(} and
@litchar{)}. Note that the reader treats @litchar["{"]...@litchar["}"]
and @litchar{(}...@litchar{)} equivalently on input, creating
immutable pairs in both cases. Mutable pairs in @racket[print] mode with
@racket[print-as-expression] as @racket[#f] or a @tech{quoting depth}
of @racket[1] also use @litchar["{"] and @litchar["}"]. In
@racket[print] mode with @racket[print-as-expression] as @racket[#t]
and a @tech{quoting depth} of @racket[0], a mutable pair prints as
@litchar{(mcons }, the @racket[mcar] and @racket[mcdr] printed at
@tech{quoting depth} @racket[0] and separated by a space, and a
closing @litchar{)}.

If the @racket[print-pair-curly-braces] parameter is set to
@racket[#t], then pairs print using @litchar["{"] and @litchar["}"]
when not using @racket[print] mode with @racket[print-as-expression] as
@racket[#t] and a @tech{quoting depth} of @racket[0].  If the
@racket[print-mpair-curly-braces] parameter is set to @racket[#f],
then mutable pairs print using @litchar{(} and @litchar{)} in that
mode.

For the purposes of printing enclosing datatypes, an empty list is
always @tech{quotable}, a pair is @tech{quotable} when its
@racket[car] and @racket[cdr] are @tech{quotable}, and a mutable list
is never @tech{quotable}.

@history[#:changed "6.9.0.6" @elem{Added a space when printing @litchar{,}
                                   or @litchar{#,} followed by a symbol
                                   that prints with a leading @litchar["@"].}]

@section[#:tag "print-string"]{打印字符串}

所有 @tech{strings} @racket[display] 为其字面的字符序列。

The @racket[write] or @racket[print] form of a string starts with @litchar{"} and ends
with another @litchar{"}. Between the @litchar{"}s, each character is
represented. Each graphic or blank character (according to @racket[char-graphic?] and
@racket[char-blank?]) is represented as itself,
with two exceptions: @litchar{"} is printed as @litchar{\"}, and
@litchar{\} is printed as @litchar{\\}. A non-graphic, non-blank character
that is part of a grapheme sequence that starts with a graphic character
is also represented as itself. Each other non-graphic, non-blank
character is printed using the escape sequences described
in @secref["parse-string"], using @litchar{\a}, @litchar{\b},
@litchar{\t}, @litchar{\n}, @litchar{\v}, @litchar{\f}, @litchar{\r},
or @litchar{\e} if possible, otherwise using @litchar{\u} with four
hexadecimal digits or @litchar{\U} with eight hexadecimal digits
(using the latter only if the character value does not fit into four
digits).

All byte strings @racket[display] as their literal byte sequence; this
byte sequence may not be a valid UTF-8 encoding, so it may not
correspond to a sequence of characters.

The @racket[write] or @racket[print] form of a byte string starts with @litchar{#"} and
ends with a @litchar{"}. Between the @litchar{"}s, each byte is
written using the corresponding ASCII decoding if the byte is between
0 and 127 and the character is graphic or blank (according to
@racket[char-graphic?] and @racket[char-blank?]). Otherwise, the byte
is written using @litchar{\a}, @litchar{\b}, @litchar{\t},
@litchar{\n}, @litchar{\v}, @litchar{\f}, @litchar{\r}, or
@litchar{\e} if possible, otherwise using @litchar{\} followed by one
to three octal digits (only as many as necessary).

For the purposes of printing enclosing datatypes, a string or a byte
string is @tech{quotable}.


@section[#:tag "print-vectors"]{打印向量}

In @racket[display] mode, the printed form of a @tech{vector} is @litchar{#}
followed by the printed form of @racket[vector->list] applied to the
vector. In @racket[write] mode, the printed form is the same, except
that when the @racket[print-vector-length] parameter is @racket[#t], a
decimal integer is printed after the @litchar{#}, and a repeated last
element is printed only once.

Vectors @racket[print] the same as they @racket[write], unless
@racket[print-as-expression] is set to @racket[#t] and the current
@tech{quoting depth} is @racket[0]. In that case, if all of the
vector's elements are @tech{quotable}, then the vector's
@racket[print]ed form is prefixed with @litchar{'} and its elements
printed with @tech{quoting depth} @racket[1]. If its elements are not
all @tech{quotable}, then the vector @racket[print]s as
@litchar["(vector "], the elements at @tech{quoting depth} @racket[0],
and a closing @litchar{)}. A vector is @tech{quotable} when all of
its elements are @tech{quotable}.

In @racket[write] or @racket[display] mode, a @tech{flvector} prints
like a @tech{vector}, but with a @litchar{#fl} prefix instead of
@litchar{#}. A @tech{fxvector} similarly prints with a @litchar{#fx}
prefix instead of @litchar{#}. The @racket[print-vector-length]
parameter affects @tech{flvector} and @tech{fxvector} printing the
same as @tech{vector} printing. In @racket[print] mode,
@tech{flvectors} and @tech{fxvectors} are not @tech{quotable}, and
they print like a @tech{vector} at @tech{quoting depth} 0 using a
@litchar["(flvector "] or @litchar["(fxvector "] prefix, respectively.


@section[#:tag "print-structure"]{打印结构体}

When the @racket[print-struct] parameter is set to @racket[#t], then
the way that @tech{structures} print depends on details of the structure type
for which the structure is an instance:

@itemize[

 @item{If the structure type is a @tech{prefab} structure type,
       then it prints in @racket[write] or @racket[display] mode using
       @litchar{#s(} followed by the @tech{prefab} structure type key,
       then the printed form of each field in the structure, and then
       @litchar{)}.

       In @racket[print] mode when @racket[print-as-expression] is set
       to @racket[#t] and the current @tech{quoting depth} is
       @racket[0], if the structure's content is all @tech{quotable},
       then the structure's @racket[print]ed form is prefixed with
       @litchar{'} and its content is printed with @tech{quoting
       depth} @racket[1]. If any of its content is not quotable, then
       the structure type prints the same as a non-@tech{prefab}
       structure type.

       An instance of a @tech{prefab} structure type is @tech{quotable}
       when all of its content is @tech{quotable}.}

 @item{If the structure has a @racket[prop:custom-write] property
       value, then the associated procedure is used to print the
       structure, unless the @racket[print-unreadable] parameter is
       set to @racket[#f].

       For @racket[print] mode, an instance of a structure type with a
       @racket[prop:custom-write] property is treated as
       @tech{quotable} if it has the
       @racket[prop:custom-print-quotable] property with a value of
       @racket['always]. If it has @racket['maybe] as the property
       value, then the structure is treated as @tech{quotable} if its
       content is @tech{quotable}, where the content is determined by
       the values recursively printed by the structure's
       @racket[prop:custom-write] procedure. Finally, if the structure
       has @racket['self] as the property value, then it is treated as
       @tech{quotable}.

       In @racket[print] mode when @racket[print-as-expression] is
       @racket[#t], the structure's @racket[prop:custom-write]
       procedure is called with either @racket[0] or @racket[1] as the
       @tech{quoting depth}, normally depending on the structure's
       @racket[prop:custom-print-quotable] property value. If the
       property value is @racket['always], the @tech{quoting depth} is
       normally @racket[1]. If the property value is @racket['maybe],
       then the @tech{quoting depth} is @racket[1] if the structure is
       @tech{quotable}, or normally @racket[0] otherwise. If the
       property value is @racket['self], then the quoting depth may be
       @racket[0] or @racket[1]; it is normally @racket[0] if the
       structure is not printed as a part of an enclosing
       @tech{quotable} value, even though the structure is treated as
       @tech{quotable}. Finally, if the property value is
       @racket['never], then the @tech{quoting depth} is normally
       @racket[0]. The @tech{quoting depth} can vary from its normal
       value if the structure is printed with an explicit quoting
       depth of @racket[1].}

 @item{If the structure's type is transparent or if any ancestor is
       transparent (i.e., @racket[struct?] on the instance produces
       @racket[#t]), then the structure prints as the vector produced
       by @racket[struct->vector] in @racket[display] mode, in
       @racket[write] mode, or in @racket[print] mode when
       @racket[print-as-expression] is set to @racket[#f] or when the
       @tech{quoting depth} is @racket[0].

       In @racket[print] mode with @racket[print-as-expression] as
       @racket[#t] and a @tech{quoting depth} of @racket[0], the
       structure content is printed with a @litchar{(} followed by
       the structure's type name (as determined by
       @racket[object-name]) in @racket[write] mode; the remaining
       elements are @racket[print]ed at @tech{quoting depth}
       @racket[0] and separated by a space, and finally a closing
       @litchar{)}.

       A transparent structure type that is not a @tech{prefab}
       structure type is never @tech{quotable}.}

 @item{For any other structure type, the structure prints as an
       unreadable value; see @secref["print-unreadable"] for more
       information.}
]

If the @racket[print-struct] parameter is set to @racket[#f], then all
structures without a @racket[prop:custom-write] property print as
unreadable values (see @secref["print-unreadable"]) and count as
@tech{quotable}.


@section[#:tag "print-hashtable"]{打印哈希表}

When the @racket[print-hash-table] parameter is set to @racket[#t], in
@racket[write] and @racket[display] modes, a @tech{hash table} prints
starting with @litchar{#hash(}, @litchar{#hasheqv(}, or
@litchar{#hasheq(} for a table using @racket[equal?], @racket[eqv?],
or @racket[eq?] key comparisons, respectively, as long as the hash table
retains keys strongly. After the prefix, each
key--value mapping is shown as @litchar{(}, the printed form of a key,
a space, @litchar{.}, a space, the printed form the corresponding
value, and @litchar{)}, with an additional space if the key--value
pair is not the last to be printed.  After all key--value pairs, the
printed form completes with @litchar{)}.

In @racket[print] mode when @racket[print-as-expression] is
@racket[#f] or the @tech{quoting depth} is @racket[1], the printed form
is the same as for @racket[write]. Otherwise, if the hash table's keys
and values are all @tech{quotable}, the table prints with a
@litchar{'} prefix, and the table's key and values are @racket[print]ed
at @tech{quoting depth} @racket[1]. If some key or value is not
@tech{quotable}, the hash table prints as @litchar["(hash "],
@litchar["(hasheqv "], or @litchar["(hasheq "] followed by alternating
keys and values @racket[print]ed at @tech{quoting depth} @racket[1] and
separated by spaces, and finally a closing @litchar{)}. A hash table
is @tech{quotable} when all of its keys and values are
@tech{quotable}.

当 @racket[print-hash-table] 参数设为 @racket[#f] 或 hash table 弱持有其 key 时，
hash table 打印为 @litchar{#<hash>} 并算作 @tech{quotable}。


@section[#:tag "print-box"]{打印 Box}

When the @racket[print-box] parameter is set to @racket[#t], a @tech{box}
prints as @litchar{#&} followed by the printed form of its content in
@racket[write], @racket[display], or @racket[print] mode when
@racket[print-as-expression] is @racket[#f] or the @tech{quoting
depth} is @racket[1].

In @racket[print] mode when @racket[print-as-expression] is
@racket[#t] and the @tech{quoting depth} is @racket[0], a box prints
with a @litchar{'} prefix and its value is printed at @tech{quoting
depth} @racket[1] when its content is @tech{quotable}, otherwise the
box prints a @litchar["(box "] followed by the content at
@tech{quoting depth} @racket[0] and a closing @litchar{)}. A box is
@tech{quotable} when its content is @tech{quotable}.

When the @racket[print-box] parameter is set to @racket[#f], a box
prints as @litchar{#<box>} and counts as @tech{quotable}.


@section[#:tag "print-character"]{打印字符}

@tech{Characters} with the special names described in
@secref["parse-character"] @racket[write] and @racket[print] using the
same name.  (Some characters have multiple names; the
@racket[#\newline] and @racket[#\nul] names are used instead of
@racketvalfont{#\linefeed} and @racketvalfont{#\null}.)  Other graphic characters
(according to @racket[char-graphic?]) @racket[write] as @litchar{#\}
followed by the single character, and all others characters are
written in @racket[#\u] notation with four digits or @racket[#\U]
notation with eight digits (using the latter only if the character
value does not fit in four digits).

All characters @racket[display] directly as themselves (i.e., a single
character).

就打印外围数据类型而言，字符是 @tech{quotable} 的。


@section[#:tag "print-keyword"]{打印关键字}

@tech{Keywords} @racket[write], @racket[print], and @racket[display] the same
as symbols (see @secref["print-symbol"]) except with a leading
@litchar{#:} (after any @litchar{'} prefix added in @racket[print]
mode), and without special handling for an initial @litchar{#} or when
the printed form would match a number or a delimited @litchar{.}
(since @litchar{#:} distinguishes the keyword).

For the purposes of printing enclosing datatypes, a keyword is
@tech{quotable}.


@section[#:tag "print-regexp"]{打印正则表达式}

@tech{Regexp values} @racket[write], @racket[display], and @racket[print]
starting with @litchar{#px} (for @racket[pregexp]-based regexps) or
@litchar{#rx} (for @racket[regexp]-based regexps) followed by the
@racket[write] form of the regexp's source string or byte string.

就打印外围数据类型而言，regexp 值是 @tech{quotable} 的。


@section[#:tag "print-path"]{打印路径}

@tech{Paths} 以 @litchar{#<path:....>} 的形式进行 @racket[write] 和 @racket[print]。 A
path @racket[display]s the same as the string produced by
@racket[path->string]. 就打印外围数据类型而言，path 算作 @tech{quotable}。

Although a path can be converted to a string with
@racket[path->string] or to a byte string with @racket[path->bytes],
neither is clearly the right choice for printing a path and reading it
back. If the path value is meant to be moved among platforms, then a
string is probably the right choice, despite the potential for losing
information when converting a path to a string. For a path that is
intended to be re-read on the same platform, a byte string is probably
the right choice, since it preserves information in an unportable
way. Paths do not print in a readable way so that programmers are not
misled into thinking that either choice is always appropriate.


@section[#:tag "print-unreadable"]{打印不可读的值}

For any value with no other printing specification, assuming that the
@racket[print-unreadable] parameter is set to @racket[#t], the output
form is @litchar{#<}@nonterm{something}@litchar{>}, where
@nonterm{something} is specific to the type of the value and sometimes
to the value itself. 如果 @racket[print-unreadable] 设为 @racket[#f]，那么尝试打印不可读的值会引发 @racket[exn:fail]。

就打印外围数据类型而言，不可读打印的值仍然算作 @tech{quotable}。


@section[#:tag "print-compiled"]{打印编译后的代码}

由 @racket[compile] 产生的编译后代码使用 @as-index{@litchar{#~}} 进行打印。 Compiled code printed with @litchar{#~} is
essentially assembly code for Racket, and reading such a form produces
a compiled form when the @racket[read-accept-compiled] parameter is
set to @racket[#t].

Compiled code parsed from @litchar{#~} is marked as non-runnable if
the current code inspector (see @racket[current-code-inspector]) is
not the original code inspector; on attempting to evaluate or reoptimize
non-runnable bytecode, @exnraise[exn:fail]. Otherwise, compiled
code parsed from @litchar{#~} may contain references to unexported or
protected bindings from a module. Conceptually, the references in
bytecode are associated with the current code inspector, where the
code will only execute if that inspector controls the relevant module
invocation (see @secref["modprotect"])---but the original code
inspector controls all other inspectors, anyway.

A compiled-form object may contain @tech{uninterned} symbols (see
@secref["symbols"]) that were created by @racket[gensym] or
@racket[string->uninterned-symbol]. When the compiled object is read
via @litchar{#~}, each uninterned symbol in the original form is
mapped to a new uninterned symbol, where multiple instances of a
single symbol are consistently mapped to the same new symbol. The
original and new symbols have the same printed
representation. @tech{Unreadable symbols}, which are typically
generated indirectly during expansion and compilation, are saved and
restored consistently through @litchar{#~}.

The dynamic nature of @tech{uninterned} symbols and their localization
within @litchar{#~} can cause problems when @racket[gensym] or
@racket[string->uninterned-symbol] is used to construct an identifier
for a top-level or module binding (depending on how the identifier and
its references are compiled). To avoid problems, generate distinct
identifiers either with @racket[generate-temporaries] or by applying
the result of @racket[make-syntax-introducer] to an existing
identifier; those functions lead to top-level and module variables
with @tech{unreadable symbol}ic names, and the names are deterministic
as long as expansion is otherwise deterministic.

When a compiled-form object has string and byte string literals, they
are @tech{interned} using @racket[datum-intern-literal] when the
compiled-object for is read back in. Numbers and other values that
@racket[read-syntax] would intern, however, are not interned when read
back as quoted literals in a compiled object.

A compiled form may contain path literals. Although paths are
not normally printed in a way that can be read back in, path literals
can be written and read as part of compiled code. The
@racket[current-write-relative-directory] parameter is used to convert
the path to a relative path as is it written, and then
@racket[current-load-relative-directory] parameter (falling back to
@racket[current-directory]) is used to convert
any relative path back as it is read.

For a path in a syntax object's source, if the
@racket[current-write-relative-directory] parameter is not set or the
path is not relative to the value of the
@racket[current-write-relative-directory] parameter, then the path is
coerced to a string that preserves only part of the path (an in effort
to make it less tied to the build-time filesystem, which can be
different than the run-time filesystem).

Finally, a compiled form may contain @racket[srcloc] structures if the
source field of the structure is a path for some system, a string, a
byte string, a symbol, or @racket[#f]. For a path value (matching the
current platform's convention), if the path cannot be recorded as a
relative path based on @racket[current-write-relative-directory], then
it is converted to a string with at most two path elements; if the
path contains more than two elements, then the string contains
@litchar{.../}, the next-to-last element, @litchar{/} and the last
element. The intent of the constraints on @racket[srcloc] values and
the conversion of the source field is to preserve some source
information but not expose or record a path that makes no sense on
a different filesystem or platform.

For internal testing purposes in the @tech{BC} implementation of Racket, when the
@as-index{@envvar{PLT_VALIDATE_LOAD}} environment variable is set, the
reader runs a validator on bytecode parsed from @litchar{#~}. The
validator may catch miscompilations or bytecode-file corruption. The
validator may run lazily, such as checking a procedure only when the
procedure is called.

@history[#:changed "6.90.0.21" @elem{Adjusted the effect of changing
                                    the code inspector on parsed
                                    bytecode, causing the reader to
                                    mark the loaded code as generally
                                    unrunnable instead of rejecting at
                                    read time references to unsafe
                                    operations.}
        #:changed "7.0" @elem{Allowed some @racket[srcloc] values
                              embedded in compiled code.}]
