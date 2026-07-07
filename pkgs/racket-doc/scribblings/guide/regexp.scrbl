#lang scribble/doc
@(require scribble/manual scribble/eval scribble/core "guide-utils.rkt")

@(define rx-eval (make-base-eval))

@title[#:tag "regexp" #:style 'toc]{Regular Expressions}

@margin-note{本章是 @cite["Sitaram05"] 的修改版本。}

@deftech{regexp} 值封装了一个由字符串或 @tech{byte string} 描述的
模式。当调用 @racket[regexp-match] 等函数时，regexp 匹配器尝试将此
模式与另一个字符串或字节串（我们称其为 @deftech{文本字符串}）的（部分）
内容进行匹配。文本字符串被视为原始文本，而非模式。

@local-table-of-contents[]

@refdetails["regexp"]{regexps}

@; ----------------------------------------

@section[#:tag "regexp-intro"]{Writing Regexp Patterns}

字符串或 @tech{byte string} 可以直接用作 @tech{regexp}
模式，也可以在前面加上 @litchar{#rx} 来形成字面的
@tech{regexp} 值。 例如，@racket[#rx"abc"] 是一个基于字符串的
@tech{regexp} 值，@racket[#rx#"abc"] 是一个基于 @tech{byte
string} 的 @tech{regexp} 值。或者，字符串或字节串可以加上
@litchar{#px} 前缀，如 @racket[#px"abc"]，
使用稍作扩展的模式语法。

@tech{regexp} 模式中的大多数字符用于匹配
它们在 @tech{文本字符串} 中的出现。因此，模式
@racket[#rx"abc"] 匹配一个包含连续字符
@litchar{a}、@litchar{b} 和 @litchar{c} 的字符串。其他
字符充当 @deftech{元字符}，某些字符
序列充当 @deftech{元序列}。也就是说，它们指定了
非字面含义的内容。  例如，在模式
@racket[#rx"a.c"] 中，字符 @litchar{a} 和 @litchar{c}
代表它们自身，但 @tech{元字符} @litchar{.} 可以
匹配 @emph{任意} 字符。因此，模式 @racket[#rx"a.c"]
依次匹配 @litchar{a}、任意字符和 @litchar{c}。

@margin-note{当我们需要在 Racket 字符串或 regexp 字面量中使用字面的
@litchar{\} 时，必须对其进行转义，使其最终出现在字符串中。
Racket 字符串使用 @litchar{\} 作为转义字符，因此我们
最终会得到两个 @litchar{\}：一个 Racket 字符串的 @litchar{\} 用于转义
regexp 的 @litchar{\}，后者再转义 @litchar{.}。另外
在 Racket 字符串中需要转义的字符是
@litchar{"}。}

如果我们需要匹配字符 @litchar{.} 本身，可以在其前面加上
@litchar{\\} 来转义它。字符序列
@litchar{\\.} 因此是一个 @tech{元序列}，因为它不匹配自身，
而只匹配 @litchar{.}。因此，要依次匹配 @litchar{a}、
@litchar{.} 和 @litchar{c}，我们使用 regexp 模式
@racket[#rx"a\\\\.c"]；双 @litchar{\} 是 Racket 字符串造成的，
而非 @tech{regexp} 模式本身。

@racket[regexp] 函数接受一个字符串或字节串，并
生成一个 @tech{regexp} 值。当您构建一个要
匹配多个字符串的模式时，请使用 @racket[regexp]，因为模式在
用于匹配之前需要编译为 @tech{regexp} 值。
@racket[pregexp] 函数类似于 @racket[regexp]，但使用
扩展语法。使用 @litchar{#rx} 或
@litchar{#px} 的字面 regexp 值在读取时一次性编译。


@racket[regexp-quote] 函数接受任意字符串，
返回一个字符串，该字符串构成的模式精确匹配原始
字符串。特别地，输入字符串中可能作为
regexp 元字符的字符会用反斜杠转义，使其
安全地仅匹配自身。

@interaction[
#:eval rx-eval
(regexp-quote "cons")
(regexp-quote "list?")
]

当从 @tech{regexp} 字符串和字面字符串的混合中构建复合
@tech{regexp} 时，@racket[regexp-quote] 函数非常有用。


@; ----------------------------------------

@section[#:tag "regexp-match"]{Matching Regexp Patterns}

@racket[regexp-match-positions] 函数接受一个 @tech{regexp}
模式和一个 @tech{文本字符串}，如果 regexp
匹配了 @tech{文本字符串}（的某部分），则返回一个匹配结果；如果 regexp
未能匹配该字符串，则返回 @racket[#f]。成功的匹配会生成一个
@deftech{索引对} 的列表。

@examples[
#:eval rx-eval
(regexp-match-positions #rx"brain" "bird")
(regexp-match-positions #rx"needle" "hay needle stack")
]

在第二个示例中，整数 @racket[4] 和 @racket[10]
标识了匹配的子字符串。@racket[4] 是
匹配子字符串的起始（含）索引，@racket[10] 是结束（不含）索引：

@interaction[
#:eval rx-eval
(substring "hay needle stack" 4 10)
]

在第一个示例中，@racket[regexp-match-positions] 的返回列表
只包含一个索引对，该对表示 regexp 匹配的整个
子字符串。稍后讨论 @tech{子模式} 时，
我们将看到单次匹配操作如何产生一个
@tech{子匹配} 列表。

@racket[regexp-match-positions] 函数接受可选的第三和
第四个参数，用于指定 @tech{文本字符串} 中进行匹配的索引范围。

@interaction[
#:eval rx-eval
(regexp-match-positions 
 #rx"needle" 
 "his needle stack -- my needle stack -- her needle stack"
 20 39)
]

请注意，返回的索引仍然是相对于完整的 @tech{文本字符串} 计算的。

@racket[regexp-match] 函数类似于
@racket[regexp-match-positions]，但它不返回索引对，
而是返回匹配的子字符串：

@interaction[
#:eval rx-eval
(regexp-match #rx"brain" "bird")
(regexp-match #rx"needle" "hay needle stack")
]

当 @racket[regexp-match] 与字节串 regexp 一起使用时，结果
是一个匹配的字节子串：

@interaction[
#:eval rx-eval
(regexp-match #rx#"needle" #"hay needle stack")
]

@margin-note{字节串 regexp 可以应用于字符串，
             字符串 regexp 也可以应用于字节串。在两种
             情况下，结果都是字节串。在内部，所有
             regexp 匹配都是以字节为单位的，字符串 regexp
             会被展开为匹配字符 UTF-8 编码的 regexp。
             为了获得最高效率，请使用字节串匹配而不是字符串匹配，
             因为直接匹配字节避免了 UTF-8 编码。}

如果数据在端口（port）中，无需先将其读入字符串。
像 @racket[regexp-match] 这样的函数可以直接在
端口上进行匹配：

@interaction[
(define-values (i o) (make-pipe))
(write "hay needle stack" o)
(close-output-port o)
(regexp-match #rx#"needle" i)
]

@racket[regexp-match?] 函数类似于
@racket[regexp-match-positions]，但只返回一个布尔值，
表示匹配是否成功：

@interaction[
#:eval rx-eval
(regexp-match? #rx"brain" "bird")
(regexp-match? #rx"needle" "hay needle stack")
]

@racket[regexp-split] 函数接受两个参数：一个
@tech{regexp} 模式和一个文本字符串，返回文本字符串的
子字符串列表；模式标识了分隔子字符串的定界符。

@interaction[
#:eval rx-eval
(regexp-split #rx":" "/bin:/usr/bin:/usr/bin/X11:/usr/local/bin")
(regexp-split #rx" " "pea soup")
]

如果第一个参数匹配空字符串，则返回所有
单字符子字符串的列表。

@interaction[
#:eval rx-eval
(regexp-split #rx"" "smithereens")
]

因此，要将一个或多个空格标识为定界符，请使用
regexp @racket[#rx"\u20+"] 而非 @racket[#rx"\u20*"]。

@interaction[
#:eval rx-eval
(regexp-split #rx" +" "split pea     soup")
(regexp-split #rx" *" "split pea     soup")
]

@racket[regexp-replace] 函数用另一个字符串替换
文本字符串中匹配的部分。第一个参数是模式，
第二个是文本字符串，第三个是要插入的字符串
或一个将匹配转换为插入字符串的过程。

@interaction[
#:eval rx-eval
(regexp-replace #rx"te" "liberte" "ty") 
(regexp-replace #rx"." "racket" string-upcase)
]

如果模式未出现在文本字符串中，返回的字符串
与文本字符串完全一致。

@racket[regexp-replace*] 函数用插入字符串替换
文本字符串中的 @emph{所有} 匹配：

@interaction[
#:eval rx-eval
(regexp-replace* #rx"te" "liberte egalite fraternite" "ty")
(regexp-replace* #rx"[ds]" "drracket" string-upcase)
]

@; ----------------------------------------

@section[#:tag "regexp-assert"]{Basic Assertions}

@deftech{断言} @litchar{^} 和 @litchar{$} 分别标识
文本字符串的开始和结束。它们确保
其相邻的 regexp 匹配文本字符串的一端或另一端：

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"^contact" "first contact")
]

上面的 @tech{regexp} 匹配失败，因为 @litchar{contact}
没有出现在文本字符串的开头。在

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"laugh$" "laugh laugh laugh laugh")
]

regexp 匹配 @emph{最后一个} @litchar{laugh}。

元序列 @litchar{\b} 断言存在单词边界，但
此元序列仅适用于 @litchar{#px} 语法。在

@interaction[
#:eval rx-eval
(regexp-match-positions #px"yack\\b" "yackety yack")
]

@litchar{yackety} 中的 @litchar{yack} 没有在单词边界处结束，
因此不被匹配。第二个 @litchar{yack} 在单词边界处结束，因此被匹配。

元序列 @litchar{\B}（同样仅限 @litchar{#px}）具有
与 @litchar{\b} 相反的效果；它断言不存在单词边界。在

@interaction[
#:eval rx-eval
(regexp-match-positions #px"an\\B" "an analysis")
]

没有在单词边界处结束的那个 @litchar{an} 被匹配了。

@; ----------------------------------------

@section[#:tag "regexp-chars"]{Characters and Character Classes}

通常，regexp 中的字符匹配文本字符串中相同的
字符。有时使用 regexp
@tech{元序列} 来指代单个字符是必要或方便的。例如，
元序列 @litchar{\.} 匹配句点字符。

@tech{元字符} @litchar{.} 匹配 @emph{任意} 字符
（在 @tech{多行模式} 下不匹配换行符；参见
@secref["regexp-cloister"]）：

@interaction[
#:eval rx-eval
(regexp-match #rx"p.t" "pet")
]

以上模式也匹配 @litchar{pat}、@litchar{pit}、
@litchar{pot}、@litchar{put} 和 @litchar{p8t}，但不匹配
@litchar{peat} 或 @litchar{pfffft}。

@deftech{字符类} 匹配一组字符中的任意一个
字符。一种典型的格式是 @deftech{方括号
字符类} @litchar{[}...@litchar{]}，它匹配方括号内
非空字符序列中的任意一个字符。
因此，@racket[#rx"p[aeiou]t"] 匹配 @litchar{pat}、
@litchar{pet}、@litchar{pit}、@litchar{pot}、@litchar{put}，
仅此而已。

在方括号内部，两个字符之间的 @litchar{-}
指定了这两个字符之间的 Unicode 范围。例如，
@racket[#rx"ta[b-dgn-p]"] 匹配 @litchar{tab}、@litchar{tac}、
@litchar{tad}、@litchar{tag}、@litchar{tan}、@litchar{tao} 和
@litchar{tap}。

左括号后的初始 @litchar{^} 反转由其余内容指定的
集合；也就是说，它指定了在方括号中标识的字符
@emph{之外} 的字符集合。例如，
@racket[#rx"do[^g]"] 匹配所有以 @litchar{do} 开头的三字符序列，
但不包括 @litchar{dog}。

请注意，方括号内的 @tech{元字符} @litchar{^} 的含义与
在方括号外截然不同。大多数其他
@tech{元字符}（@litchar{.}、@litchar{*}、@litchar{+}、
@litchar{?} 等）在方括号内不再是 @tech{元字符}，
不过你仍然可以转义它们以求心安。@litchar{-} 只有
在方括号内且既不是方括号内的第一个也不是最后一个字符时
才是 @tech{元字符}。

方括号字符类不能包含其他方括号字符类
（尽管它们可以包含某些其他类型的字符类；见下文）。
因此，方括号字符类内的 @litchar{[} 不必是元字符；
它可以表示自身。例如，@racket[#rx"[a[b]"] 匹配
@litchar{a}、@litchar{[} 和 @litchar{b}。

此外，由于不允许空方括号字符类，
紧跟在左方括号之后的 @litchar{]} 也不必是元字符。
例如，@racket[#rx"[]ab]"] 匹配
@litchar{]}、@litchar{a} 和 @litchar{b}。

@subsection{Some Frequently Used Character Classes}

在 @litchar{#px} 语法中，一些标准字符类可以方便地
表示为元序列而非显式的方括号表达式：
@litchar{\d} 匹配一个数字（等同于 @litchar{[0-9]}）；
@litchar{\s} 匹配一个 ASCII 空白字符；
@litchar{\w} 匹配一个可以作为
``单词''一部分的字符。

@margin-note{按照 regexp 惯例，我们将 ``单词'' 字符定义为
@litchar{[A-Za-z0-9_]}，尽管这对于 Racketeer 所认为的
``单词''来说过于严格了。}

这些元序列的大写版本表示相应字符类的
反转：@litchar{\D} 匹配非数字，@litchar{\S} 匹配
非空白字符，@litchar{\W} 匹配非 ``单词'' 字符。

请记住，在 Racket 字符串中使用这些
元序列时要使用双反斜杠：

@interaction[
#:eval rx-eval
(regexp-match #px"\\d\\d" 
 "0 dear, 1 have 2 read catch 22 before 9")
]

这些字符类可以在方括号表达式中使用。例如，
@racket[#px"[a-z\\d]"] 匹配一个小写字母或一个
数字。

@subsection{POSIX character classes}

@deftech{POSIX 字符类} 是一种特殊的 @tech{元序列}，
形式为 @litchar{[:}...@litchar{:]}，只能在
@litchar{#px} 语法的方括号表达式中使用。支持的
POSIX 类有

@itemize[#:style (make-style "compact" null)

 @item{@litchar{[:alnum:]} --- ASCII 字母和数字}

 @item{@litchar{[:alpha:]} --- ASCII 字母}

 @item{@litchar{[:ascii:]} --- ASCII 字符}

 @item{@litchar{[:blank:]} --- ASCII 等宽空白：空格和制表符}

 @item{@litchar{[:cntrl:]} --- ``控制''字符: ASCII 0 至 31}

 @item{@litchar{[:digit:]} --- ASCII 数字，等同于 @litchar{\d}}

 @item{@litchar{[:graph:]} --- 占用墨迹的 ASCII 字符}

 @item{@litchar{[:lower:]} --- ASCII 小写字母}

 @item{@litchar{[:print:]} --- ASCII 占用墨迹的字符加上等宽空白}

 @item{@litchar{[:space:]} --- ASCII 空白，等同于 @litchar{\s}}

 @item{@litchar{[:upper:]} --- ASCII 大写字母}

 @item{@litchar{[:word:]} --- ASCII 字母和 @litchar{_}，等同于 @litchar{\w}}

 @item{@litchar{[:xdigit:]} --- ASCII 十六进制数字}

]

例如，@racket[#px"[[:alpha:]_]"] 匹配字母或
下划线。

@interaction[
#:eval rx-eval
(regexp-match #px"[[:alpha:]_]" "--x--")
(regexp-match #px"[[:alpha:]_]" "--_--")
(regexp-match #px"[[:alpha:]_]" "--:--")
]

POSIX 类表示法 @emph{仅} 在方括号
表达式内部有效。例如，@litchar{[:alpha:]} 不在
方括号表达式中时，不会被读取为字母类。
相反，它（根据前述原理）是一个包含
字符 @litchar{:}、@litchar{a}、@litchar{l}、@litchar{p}、
@litchar{h} 的字符类。

@interaction[
#:eval rx-eval
(regexp-match #px"[:alpha:]" "--a--")
(regexp-match #px"[:alpha:]" "--x--")
]

@; ----------------------------------------

@section[#:tag "regexp-quant"]{Quantifiers}

@deftech{量词} @litchar{*}、@litchar{+} 和 @litchar{?}
分别匹配：前一个子模式的零个或多个、一个或多个、零个或一个
实例。

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"c[ad]*r" "cadaddadddr")
(regexp-match-positions #rx"c[ad]*r" "cr")

(regexp-match-positions #rx"c[ad]+r" "cadaddadddr")
(regexp-match-positions #rx"c[ad]+r" "cr")

(regexp-match-positions #rx"c[ad]?r" "cadaddadddr")
(regexp-match-positions #rx"c[ad]?r" "cr")
(regexp-match-positions #rx"c[ad]?r" "car")
]

在 @litchar{#px} 语法中，可以使用花括号来指定比
@litchar{*}、@litchar{+}、@litchar{?} 更精细的量词：

@itemize[

 @item{量词 @litchar["{"]@math{m}@litchar["}"] 匹配
       @emph{正好} @math{m} 个前一个
       @tech{子模式} 的实例；@math{m} 必须是非负整数。}

 @item{量词
       @litchar["{"]@math{m}@litchar{,}@math{n}@litchar["}"] 匹配
       至少 @math{m} 个、最多 @math{n} 个实例。@litchar{m}
       和 @litchar{n} 是非负整数，且 @math{m} 小于或
       等于 @math{n}。可以省略其中一个或两个数字，
       此时 @math{m} 默认为 @math{0}，@math{n} 默认为
       无穷大。}

]

显然，@litchar{+} 和 @litchar{?} 分别是
@litchar{{1,}} 和 @litchar{{0,1}} 的简写，而 @litchar{*}
是 @litchar{{,}} 的简写，后者等同于 @litchar{{0,}}。

@interaction[
#:eval rx-eval
(regexp-match #px"[aeiou]{3}" "vacuous")
(regexp-match #px"[aeiou]{3}" "evolve")
(regexp-match #px"[aeiou]{2,3}" "evolve")
(regexp-match #px"[aeiou]{2,3}" "zeugma")
]

目前为止描述的量词都是 @deftech{贪婪} 的：它们匹配
仍然能导致整个模式整体匹配的
最大数量实例。

@interaction[
#:eval rx-eval
(regexp-match #rx"<.*>" "<tag1> <tag2> <tag3>")
]

要使这些量词变为 @deftech{非贪婪}，在它们后面
添加一个 @litchar{?}。非贪婪量词匹配确保
整体匹配所需的最少实例数。

@interaction[
#:eval rx-eval
(regexp-match #rx"<.*?>" "<tag1> <tag2> <tag3>")
]

非贪婪量词有 @litchar{*?}、@litchar{+?}、
@litchar{??}、@litchar["{"]@math{m}@litchar["}?"] 和
@litchar["{"]@math{m}@litchar{,}@math{n}@litchar["}?"]，虽然
@litchar["{"]@math{m}@litchar["}?"] 总是等同于
@litchar["{"]@math{m}@litchar["}"]。请注意，元字符
@litchar{?} 有两种不同的用途，这两种用途都体现在
@litchar{??} 中。

@; ----------------------------------------

@section[#:tag "regexp-clusters"]{Clusters}

@deftech{分组}---用括号包围
@litchar{(}...@litchar{)}---将封闭的
@deftech{子模式} 标识为单个实体。它导致匹配器在
整体匹配之外，还捕获 @deftech{子匹配}，即匹配
子模式的字符串部分：

@interaction[
#:eval rx-eval
(regexp-match #rx"([a-z]+) ([0-9]+), ([0-9]+)" "jan 1, 1970")
]

分组还会使后面的量词将整个封闭的
子模式视为一个实体：

@interaction[
#:eval rx-eval
(regexp-match #rx"(pu )*" "pu pu platter")
]

返回的子匹配数量始终等于
regexp 中指定的子模式数量，即使某个子模式
恰好匹配了多个子字符串或完全没有匹配。

@interaction[
#:eval rx-eval
(regexp-match #rx"([a-z ]+;)*" "lather; rinse; repeat;")
]

这里，被 @litchar{*} 量化的子模式匹配了三次，但
返回的是最后一个子匹配。

即使整体模式匹配，量化的子模式也有可能
匹配失败。在这种情况下，失败的子匹配
由 @racket[#f] 表示

@interaction[
#:eval rx-eval
(define date-re
  (code:comment @#,t{match `month year' or `month day, year';})
  (code:comment @#,t{subpattern matches day, if present})
  #rx"([a-z]+) +([0-9]+,)? *([0-9]+)")
(regexp-match date-re "jan 1, 1970")
(regexp-match date-re "jan 1970")
]


@subsection{Backreferences}

@tech{子匹配} 可以在过程
@racket[regexp-replace] 和 @racket[regexp-replace*] 的插入字符串参数中使用。
插入字符串可以使用 @litchar{\}@math{n} 作为 @deftech{反向引用}，
引用第 @math{n} 个子匹配，即匹配第 @math{n} 个
子模式的子字符串。@litchar{\0} 引用
整个匹配，也可以指定为 @litchar{\&}。

@interaction[
#:eval rx-eval
(regexp-replace #rx"_(.+?)_" 
  "the _nina_, the _pinta_, and the _santa maria_"
  "*\\1*")
(regexp-replace* #rx"_(.+?)_" 
  "the _nina_, the _pinta_, and the _santa maria_"
  "*\\1*")

(regexp-replace #px"(\\S+) (\\S+) (\\S+)"
  "eat to live"
  "\\3 \\2 \\1")
]

在插入字符串中使用 @litchar{\\} 来指定字面反斜杠。
此外，@litchar{\$} 表示空字符串，用于将
反向引用 @litchar{\}@math{n} 与紧随其后的数字分隔开，非常有用。

反向引用也可以在 @litchar{#px} 模式中使用，以引用
模式中已经匹配的子模式。@litchar{\}@math{n} 表示
第 @math{n} 个子匹配的精确重复。请注意，@litchar{\0}
在插入字符串中很有用，但在 regexp 模式中没有意义，
因为整个 regexp 尚未匹配完毕，因此无法引用它。}

@interaction[
#:eval rx-eval
(regexp-match #px"([a-z]+) and \\1"
              "billions and billions")
]

请注意，@tech{反向引用} 并非简单重复
之前的子模式。相反，它是重复子模式
已经匹配的特定子字符串。

在上面的示例中，@tech{反向引用} 只能匹配
@litchar{billions}。它不会匹配 @litchar{millions}，即使
它回溯的子模式---@litchar{([a-z]+)}---本来可以
毫无问题地做到这一点：

@interaction[
#:eval rx-eval
(regexp-match #px"([a-z]+) and \\1"
              "billions and millions")
]

以下示例标记数字字符串中所有立即重复的模式：

@interaction[
#:eval rx-eval
(regexp-replace* #px"(\\d+)\\1"
  "123340983242432420980980234"
  "{\\1,\\1}")
]

以下示例修正重复的单词：

@interaction[
#:eval rx-eval
(regexp-replace* #px"\\b(\\S+) \\1\\b"
  (string-append "now is the the time for all good men to "
                 "to come to the aid of of the party")
  "\\1")
]

@subsection{Non-capturing Clusters}

经常需要指定一个分组（通常用于
量化），但不触发 @tech{子匹配}
信息的捕获。这样的分组称为 @deftech{非捕获} 分组。要
创建非捕获分组，使用 @litchar{(?:} 而非
@litchar{(} 作为分组的开头。

在以下示例中，一个非捕获分组消除了给定
Unix 路径名的 ``目录'' 部分，而一个捕获分组
则识别出基础文件名。

@margin-note{但不要用 regexp 解析路径。请使用像
 @racket[split-path] 这样的函数。}

@interaction[
#:eval rx-eval
(regexp-match #rx"^(?:[a-z]*/)*([a-z]+)$" 
              "/usr/local/bin/racket")
]

@subsection[#:tag "regexp-cloister"]{Cloisters}

非捕获分组中 @litchar{?} 和 @litchar{:} 之间的位置
称为 @deftech{修饰区}。可以在其中放置修饰符，
使被包围的 @tech{子模式} 得到特殊处理。
修饰符 @litchar{i} 使子模式不区分大小写匹配：

@margin-note{@defterm{cloister} 一词是一个有用的术语，尽管有些过于
俏皮，源自 Perl 大师们的创造。}

@interaction[
#:eval rx-eval
(regexp-match #rx"(?i:hearth)" "HeartH")
]

修饰符 @litchar{m} 使 @tech{子模式} 在
@deftech{多行模式} 下匹配，此模式下 @litchar{.} 不匹配换行符，
@litchar{^} 可以匹配换行符之后的位置，@litchar{$}
可以匹配换行符之前的位置。

@interaction[
#:eval rx-eval
(regexp-match #rx"." "\na\n")
(regexp-match #rx"(?m:.)" "\na\n")
(regexp-match #rx"^A plan$" "A man\nA plan\nA canal")
(regexp-match #rx"(?m:^A plan$)" "A man\nA plan\nA canal")
]

可以在修饰区中放置多个修饰符：

@interaction[
#:eval rx-eval
(regexp-match #rx"(?mi:^A Plan$)" "a man\na plan\na canal")
]

修饰符前的减号反转其含义。因此，可以在
@deftech{子分组} 中使用 @litchar{-i} 来撤销
外层分组造成的不区分大小写效果。

@interaction[
#:eval rx-eval
(regexp-match #rx"(?i:the (?-i:TeX)book)"
              "The TeXbook")
]

上面的 regexp 允许 @litchar{the} 和 @litchar{book}
的任意大小写，但坚持 @litchar{TeX}
必须保持相同的大小写。

@; ----------------------------------------

@section[#:tag "regexp-alternation"]{Alternation}

可以通过用 @litchar{|} 分隔来指定一列
@emph{候选} @tech{子模式}。@litchar{|} 在最近的外层
分组中分隔 @tech{子模式}（如果没有外层括号，则在
整个模式字符串中分隔）。

@interaction[
#:eval rx-eval
(regexp-match #rx"f(ee|i|o|um)" "a small, final fee")
(regexp-replace* #rx"([yi])s(e[sdr]?|ing|ation)"
                 (string-append
                  "analyse an energising organisation"
                  " pulsing with noisy organisms")
                 "\\1z\\2")
]
 
再次注意，如果您只想使用分组来指定候选子模式的
列表但不想要子匹配，请使用
@litchar{(?:} 而非 @litchar{(}。

@interaction[
#:eval rx-eval
(regexp-match #rx"f(?:ee|i|o|um)" "fun for all")
]

关于选择的一个重要注意事项是，最左边的
匹配候选项会被选取，无论其长度如何。因此，如果某个
候选项是后面某个候选项的前缀，则后者可能
没有机会被匹配。

@interaction[
#:eval rx-eval
(regexp-match #rx"call|call-with-current-continuation" 
              "call-with-current-continuation")
]

为了让更长的候选项有机会被匹配，将其
放在较短的候选项之前：

@interaction[
#:eval rx-eval
(regexp-match #rx"call-with-current-continuation|call"
              "call-with-current-continuation")
]

无论如何，整个 regexp 的整体匹配总是
优于整体不匹配。在下例中，更长的
候选项仍然胜出，因为其首选的较短前缀未能
产生整体匹配。

@interaction[
#:eval rx-eval
(regexp-match
 #rx"(?:call|call-with-current-continuation) constrained"
 "call-with-current-continuation constrained")
]

@; ----------------------------------------

@section{Backtracking}

我们已经看到贪婪量词会匹配最大次数，
但最高优先原则是确保整体匹配成功。
考虑以下情况：

@interaction[
#:eval rx-eval
(regexp-match #rx"a*a" "aaaa")
]

regexp 由两个子 regexp 组成：@litchar{a*} 后跟
@litchar{a}。子 regexp @litchar{a*} 不能匹配
文本字符串 @racket[aaaa] 中所有的四个 @litchar{a}，即使
@litchar{*} 是贪婪量词。它只能匹配前
三个，将最后一个留给第二个子 regexp。这确保了
整个 regexp 成功匹配。

regexp 匹配器通过一个称为 @deftech{回溯} 的过程
来实现这一点。匹配器暂时允许贪婪
量词匹配所有四个 @litchar{a}，但当明确
整体匹配面临危险时，它会 @emph{回溯} 到较少的
三个 @litchar{a} 的匹配。如果这仍然失败，如
以下调用中

@interaction[
#:eval rx-eval
(regexp-match #rx"a*aa" "aaaa")
]

匹配器进一步回溯。只有当所有可能的回溯
都已尝试且未成功时，才会承认整体失败。

回溯不仅限于贪婪量词。非贪婪量词匹配尽可能少的
实例，并逐步回溯到更多实例，
以实现整体匹配。选择也有回溯，
当局部成功的左侧选项无法产生整体匹配时，
会尝试更右侧的选项。

有时禁用回溯是高效的。例如，我们
可能希望提交一个选择，或者我们知道尝试替代方案是
徒劳的。非回溯 regexp 用
@litchar{(?>}...@litchar{)} 包围。

@interaction[
#:eval rx-eval
(regexp-match #rx"(?>a+)." "aaaa")
]

在此调用中，子 regexp @litchar{?>a+} 贪婪地匹配所有四个
@litchar{a}，并且被剥夺了回溯的机会。因此，
整体匹配被拒绝。该 regexp 的效果是
匹配一个或多个 @litchar{a}，后跟
绝对非 @litchar{a} 的某个字符。

@; ----------------------------------------

@section{Looking Ahead and Behind}

你可以在模式中使用断言来向前或向后查看，
以确保子模式出现或不出现。这些 ``环视''
断言由将待检查的子模式放入一个分组中来指定，
分组的前导字符为：@litchar{?=}（正向前瞻）、
@litchar{?!}（负向前瞻）、@litchar{?<=}（正向后顾）、
@litchar{?<!}（负向后顾）。请注意，断言中的子模式
不会在最终结果中产生匹配；它仅仅允许或禁止
其余部分的匹配。

@subsection{Lookahead}

使用 @litchar{?=} 的正向前瞻向前查看，确保
其子模式 @emph{可能} 匹配。  

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"grey(?=hound)" 
  "i left my grey socks at the greyhound") 
]

regexp @racket[#rx"grey(?=hound)"] 匹配 @litchar{grey}，但
@emph{仅当} 它后跟 @litchar{hound} 时。因此，
文本字符串中第一个 @litchar{grey} 不被匹配。

使用 @litchar{?!} 的负向前瞻向前查看，确保其
子模式 @emph{不可能} 匹配。

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"grey(?!hound)"
  "the gray greyhound ate the grey socks") 
]

regexp @racket[#rx"grey(?!hound)"] 匹配 @litchar{grey}，但
仅当它后面 @emph{不是} @litchar{hound} 时。因此
@litchar{socks} 前面的 @litchar{grey} 被匹配。

@subsection{Lookbehind}

使用 @litchar{?<=} 的正向后顾检查其子模式
@emph{可能} 在文本字符串当前位置的紧左侧匹配。

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"(?<=grey)hound"
  "the hound in the picture is not a greyhound") 
]

regexp @racket[#rx"(?<=grey)hound"] 匹配 @litchar{hound}，但
仅当它前面是 @litchar{grey} 时。

使用 @litchar{?<!} 的负向后顾检查其子模式
不可能在紧左侧匹配。

@interaction[
#:eval rx-eval
(regexp-match-positions #rx"(?<!grey)hound"
  "the greyhound in the picture is not a hound")
]

regexp @racket[#rx"(?<!grey)hound"] 匹配 @litchar{hound}，但
仅当它前面 @emph{不是} @litchar{grey} 时。

前瞻和后顾在不令人困惑时可以很方便。

@; ----------------------------------------

@section{An Extended Example}

@(define ex-eval (make-base-eval))

以下是来自 Friedl 所著《@italic{精通正则表达式}》第 189 页的一个扩展示例，
涵盖了本章中描述的许多特性。问题是设计一个 regexp，
使之仅匹配 IP 地址或 @emph{点分四段}：
用三个点分隔的四个数字，每个数字在 0 到 255 之间。

首先，我们定义一个子 regexp @racket[n0-255]，它匹配从 0 到
255 的数字：

@interaction[
#:eval ex-eval
(define n0-255
  (string-append
   "(?:"
   "\\d|"        (code:comment @#,t{  0 through   9})
   "\\d\\d|"     (code:comment @#,t{ 00 through  99})
   "[01]\\d\\d|" (code:comment @#,t{000 through 199})
   "2[0-4]\\d|"  (code:comment @#,t{200 through 249})
   "25[0-5]"     (code:comment @#,t{250 through 255})
   ")"))
]

@margin-note{请注意，@racket[n0-255] 将前缀列为优先
候选项，这是我们在 @secref["regexp-alternation"] 中
警告过的做法。但是，由于我们打算显式地锚定
此子 regexp 以强制整体匹配，候选项的顺序无关紧要。}

前两个候选项简单地获取所有一位和
两位数字。由于允许 0 填充，我们
需要同时匹配 1 和 01。在处理
三位数字时需要小心，因为必须排除大于 255 的
数字。因此我们构造候选项来获取 000
到 199，然后是 200 到 249，最后是 250
到 255。

IP 地址是由四个 @racket[n0-255] 组成的字符串，
中间有三个点分隔。

@interaction[
#:eval ex-eval
(define ip-re1
  (string-append
   "^"        (code:comment @#,t{nothing before})
   n0-255     (code:comment @#,t{the first @racket[n0-255],})
   "(?:"      (code:comment @#,t{then the subpattern of})
   "\\."      (code:comment @#,t{a dot followed by})
   n0-255     (code:comment @#,t{an @racket[n0-255],})
   ")"        (code:comment @#,t{which is})
   "{3}"      (code:comment @#,t{repeated exactly 3 times})
   "$"))      (code:comment @#,t{with nothing following})
]

让我们试试看：

@interaction[
#:eval ex-eval
(regexp-match (pregexp ip-re1) "1.2.3.4")
(regexp-match (pregexp ip-re1) "55.155.255.265")
]

这很好，除了我们还有

@interaction[
#:eval ex-eval
(regexp-match (pregexp ip-re1) "0.00.000.00")
]

全零序列不是有效的 IP 地址！前瞻来救援了。在
开始匹配 @racket[ip-re1] 之前，我们向前查看以确保
不是全零。我们可以使用正向前瞻来确保
@emph{存在} 一个非零的数字。

@interaction[
#:eval ex-eval
(define ip-re
  (pregexp
   (string-append
     "(?=.*[1-9])" (code:comment @#,t{ensure there's a non-0 digit})
     ip-re1)))
]

或者我们可以使用负向前瞻来确保前面的内容
不是 @emph{仅} 由零和点组成的。

@interaction[
#:eval ex-eval
(define ip-re
  (pregexp
   (string-append
     "(?![0.]*$)" (code:comment @#,t{not just zeros and dots})
                  (code:comment @#,t{(note: @litchar{.} is not metachar inside @litchar{[}...@litchar{]})})
     ip-re1)))
]

regexp @racket[ip-re] 将匹配所有且仅匹配有效的 IP 地址。

@interaction[
#:eval ex-eval
(regexp-match ip-re "1.2.3.4")
(regexp-match ip-re "0.0.0.0")
]

@close-eval[ex-eval]
@close-eval[rx-eval]
