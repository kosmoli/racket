#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "linecol"]{Counting Positions, Lines, and Columns}

@section-index["line numbers"]
@section-index["column numbers"]
@section-index["port positions"]

默认情况下，Racket 会跟踪 port 中的 @deftech{position}，作为从任何 port 读取或写入的字节数（独立于读/写位置，该位置通过 @racket[file-position] 访问或更改）。作为选项，Racket 可以将位置跟踪为字符（UTF-8 解码后）而不是字节，还可以跟踪 @deftech{line location} 和 @deftech{column location}；可选的跟踪必须通过 @racket[port-count-lines!] 或 @racket[port-count-lines-enabled] parameter 专门启用。Port 的位置、行和列位置由 @racket[read-syntax] 使用。位置和行位置从 @math{1} 开始编号；列位置从 @math{0} 开始编号。

当计数行时，Racket 将换行符、回车符和回车-换行符组合视为行终止符和单个位置（在所有平台上）。每个 tab 将列数推进到下一个 8 的倍数之前的一个位置。当 128 到 253 范围内的字节序列形成 UTF-8 字符编码时，每个字节位置/列递增，然后在发现完整编码序列时适当递减。有关 port 上 UTF-8 解码的更多信息请参见 @secref["ports"]。

任何 port 的位置都是已知的，只要能表示为 fixnum（对于诸如 syntax-error 报告等实际应用已远远足够）。如果 port 的位置超过最大 fixnum 值，则 port 位置变为未知，行和列跟踪被禁用。仅当启用行和列计数时，回车-换行符组合才被视为单个字符位置。

@tech{Custom port} 可以定义自己的计数函数，这些函数不受上述规则约束，除非计数函数仅在使用 @racket[port-count-lines!] 专门启用跟踪时才被调用。

@;------------------------------------------------------------------------

@defproc[(port-count-lines! [port port?]) void?]{

打开 port 的 @tech{line location} 和 @tech{column location} 计数。可以在任何时候打开计数，但通常在从 port 读取或写入任何数据之前打开。在打开行计数的那一刻，@racket[port-next-location] 通常报告（打开行计数以来读取的字符数的最后一个结果），而不是（port 打开以来读取的字节数）。

当 port 创建时，如果 @racket[port-count-lines-enabled] parameter 的值为真，则会自动打开行计数。打开后无法禁用行计数。}

@defproc[(port-counts-lines? [port port?]) boolean?]{

如果 @racket[port] 已启用 @tech{line location} 和 @tech{column location} 计数则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(port-next-location [port port?]) 
         (values (or/c exact-positive-integer? #f)
                 (or/c exact-nonnegative-integer? #f)
                 (or/c exact-positive-integer? #f))]{

返回三个值：下一个读取/写入项的行号整数或 @racket[#f]，下一个项的列整数或 @racket[#f]，以及下一个项的位置整数或 @racket[#f]。当从 port 读取或写入字节时，下一个列和位置通常递增，但如果为 @racket[port] 启用了行/字符计数，则列和位置结果在读取或写入结束 UTF-8 编码序列的字节后可能递减。

如果 port 未启用行计数，则前两个结果为 @racket[#f]，最后一个结果是到目前为止读取的字节数。在启用行计数的那一刻，前两个结果通常变为非 @racket[#f]，最后一个结果开始报告字符而不是字节，通常从行计数启用时开始。

即使启用了行计数，port 也可能返回 @racket[#f] 值，如果它以某种方式无法跟踪行、列或位置。}

@defproc[(set-port-next-location! [port port?]
                                  [line (or/c exact-positive-integer? #f)]
                                  [column (or/c exact-nonnegative-integer? #f)]
                                  [position (or/c exact-positive-integer? #f)])
         void?]{

设置 @racket[port] 的下一个行、列和位置。如果 @racket[port] 的行计数未启用，或如果 @racket[port] 是定义自己计数函数的 @tech{custom port}，则 @racket[set-port-next-location!] 无效。}

@defboolparam[port-count-lines-enabled on?]{

一个 @tech{parameter}，用于确定是否对新创建的 port 自动启用行计数。默认值为 @racket[#f]。}
