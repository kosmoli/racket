#lang scribble/doc
@(require scribble/bnf "mz.rkt")

@(define MzAdd (italic "Racket 特定："))

@(define (litchar~ s) (litchar (regexp-replace* "~" s " ")))

@title[#:tag "windowspaths"]{Windows Paths}

通常，Windows 路径名由可选的驱动器说明符和驱动器特定的路径组成。Windows 路径可以是 @defterm{absolute} 的，但仍相对于当前驱动器；此类路径以 @litchar{/} 或 @litchar{\} 分隔符开头，并且不是 UNC 路径或以 @litchar{\\\\?\\} 开头的路径。

以驱动器说明符开头的路径是 @defterm{complete} 的。大致上，驱动器说明符是拉丁字母后跟冒号、形式为 @litchar{\\\\}@nonterm{machine}@litchar{\\}@nonterm{volume} 的 UNC 路径，或后跟非 @litchar{REL\\}@nonterm{element} 或 @litchar{RED\\}@nonterm{element} 的 @litchar{\\\\?\\} 形式。（@litchar{\\\\?\\} 路径的变体在下面进一步描述。）

Racket 无法以一种方式实现通常的 Windows 路径语法。在 Racket 之外，路径名 @filepath{C:rant.txt} 可以是驱动器特定的相对路径。也就是说，它命名驱动器 @filepath{C:} 上的文件 @filepath{rant.txt}，但文件的完整路径由驱动器 @filepath{C:} 的当前工作目录确定。Racket 不支持驱动器特定的工作目录（仅支持跨所有驱动器的工作目录，如 @racket[current-directory] 参数所反映的）。因此，Racket 隐式地将类似 @filepath{C:rant.txt} 的路径转换为 @filepath["C:\\\\rant.txt"]。

@itemize[

 @item{@|MzAdd| 每当路径以驱动器说明符 @nonterm{letter}@litchar{:} 开头且后不跟 @litchar{/} 或 @litchar{\\} 时，在路径被 @tech{cleanse} 时会插入一个 @litchar{\\}。}

]

否则，Racket 遵循标准 Windows 路径约定，但还添加了 @litchar{\\\\?\\REL} 和 @litchar{\\\\?\\RED} 约定来处理在标准约定中无法表达的路径，以及处理 @litchar{\\\\?\\} 路径中过多 @litchar{\\} 的约定。

@nonterm{element} 代表任何不包含 @litchar{\\} 的字符序列。

@itemize[

  @item{路径元素中的尾随空格和 @litchar{.} 在该元素是路径中最后一个元素时被忽略，除非路径以 @litchar{\\} 开头或元素仅由空格和 @litchar{.} 组成。}

  @item{以下特殊"文件"（访问设备）在所有目录中以不区分大小写的方式存在，并且句号或冒号后可能有各种结尾，但以 @litchar{\\} 开头的路径名除外：@indexed-file{NUL}、@indexed-file{CON}、@indexed-file{PRN}、@indexed-file{AUX}、@indexed-file{COM1}、@indexed-file{COM2}、@indexed-file{COM3}、@indexed-file{COM4}、@indexed-file{COM5}、@indexed-file{COM6}、@indexed-file{COM7}、@indexed-file{COM8}、@indexed-file{COM9}、@indexed-file{LPT1}、@indexed-file{LPT2}、@indexed-file{LPT3}、@indexed-file{LPT4}、@indexed-file{LPT5}、@indexed-file{LPT6}、@indexed-file{LPT7}、@indexed-file{LPT8}、@indexed-file{LPT9}。}

  @item{除了 @litchar{\\\\?\\} 路径外，@litchar{/} 等同于 @litchar{\\}。除了 @litchar{\\\\?\\} 路径和 UNC 路径的开头外，多个相邻的 @litchar{/} 和 @litchar{\\} 计为单个 @litchar{\\}。在以 @litchar{\\\\?\\} 开头的路径中，元素可以由单个或双个 @litchar{\\} 分隔。}

  @item{目录可以在有或没有尾随分隔符的情况下访问。对于非 @litchar{\\\\?\\} 路径，尾随分隔符可以是任意数量的 @litchar{/} 和 @litchar{\\}；对于 @litchar{\\\\?\\} 路径，尾随分隔符必须是单个 @litchar{\\}，除非在 @litchar{\\\\?\\}@nonterm{letter}@litchar{:} 之后可以跟两个 @litchar{\\}。}

  @item{除了 @litchar{\\\\?\\} 路径外，作为路径元素的单个 @litchar{.} 表示"当前目录"，作为路径元素的 @litchar{..} 表示"父目录"。驱动器之后的向上目录路径元素（即 @litchar{..}）被忽略。}

  @item{以 @litchar{\\\\}@nonterm{machine}@litchar{\\}@nonterm{volume} 开头的路径名（其中 @litchar{/} 可以替换任何 @litchar{\\}）是 UNC 路径，开头的 @litchar{\\\\}@nonterm{machine}@litchar{\\}@nonterm{volume} 计为驱动器说明符。}

   @item{通常，路径元素不能包含 @racket[#\\x00] 到 @racket[#\\x1F] 范围内的字符，也不能包含以下任何字符：

         @centerline{@litchar{<} @litchar{>} @litchar{:} @litchar{"}
                     @litchar{/} @litchar{\\} @litchar{|} @litchar{?} @litchar{*}}

         除了 @litchar{\\} 外，包含这些字符的路径元素可以使用 @litchar{\\\\?\\} 路径访问（假设底层文件系统允许这些字符）。}

   @item{在以 @litchar{\\\\?\\}@nonterm{letter}@litchar{:\\} 开头的路径名中，@litchar{\\\\?\\}@nonterm{letter}@litchar{:\\} 前缀计为路径的驱动器，只要路径不同时包含非驱动器元素和结尾的两个连续 @litchar{\\}，并且路径不包含三个或更多 @litchar{\\} 的序列。两个 @litchar{\\} 可以出现在 @nonterm{letter} 前面的 @litchar{\\} 位置。@litchar{/} 不能用于替代 @litchar{\\}（但 @litchar{/} 可以用于元素名称，尽管结果通常不命名实际目录或文件）。}
       
   @item{在以 @litchar{\\\\?\\UNC\\}@nonterm{machine}@litchar{\\}@nonterm{volume} 开头的路径名中，@litchar{\\\\?\\UNC\\}@nonterm{machine}@litchar{\\}@nonterm{volume} 前缀计为路径的驱动器，只要路径不以两个连续 @litchar{\\} 结尾，并且路径不包含三个或更多 @litchar{\\} 的序列。两个 @litchar{\\} 可以出现在 @litchar{UNC} 之前的 @litchar{\\} 位置、@litchar{UNC} 之后的 @litchar{\\} 位置，和/或 @nonterm{machine} 之后的 @litchar{\\} 位置。@litchar{UNC} 部分中的字母可以是大写或小写，@litchar{/} 不能用于替代 @litchar{\\}（但 @litchar{/} 可以用于元素名称）。}

   @item{@|MzAdd| 以 @litchar{\\\\?\\REL\\}@nonterm{element} 或 @litchar{\\\\?\\REL\\\\}@nonterm{element} 开头的路径名是相对路径，只要路径不以两个连续 @litchar{\\} 结尾，并且路径不包含三个或更多 @litchar{\\} 的序列。此 Racket 特定路径形式支持包含在 Windows 路径中通常无法表达的元素（例如，以空格结尾的最终元素）的相对路径。@as-index{@litchar{REL}} 部分必须恰好是三个大写字母，@litchar{/} 不能用于替代 @litchar{\\}。如果路径以 @litchar{\\\\?\\REL\\..} 开头，则只要路径继续重复 @litchar{\\..}，每个元素计为向上目录元素；必须使用单个 @litchar{\\} 分隔向上目录元素。一旦使用第二个 @litchar{\\} 分隔元素，或一旦遇到非 @litchar{..} 元素，剩余元素都是字面量（从不是向上目录元素）。当 @litchar{\\\\?\\REL} 路径值转换为字符串（或当路径值被写入或显示）时，字符串不包含开头的 @litchar{\\\\?\\REL} 或紧随其后的 @litchar{\\}；将路径值转换为字节串保留 @litchar{\\\\?\\REL} 前缀。}

   @item{@|MzAdd| 以 @litchar{\\\\?\\RED\\}@nonterm{element} 或 @litchar{\\\\?\\RED\\\\}@nonterm{element} 开头的路径名是驱动器相对路径，只要路径不以两个连续 @litchar{\\} 结尾，并且路径不包含三个或更多 @litchar{\\} 的序列。此 Racket 特定路径形式支持包含在 Windows 路径中通常无法表达元素的驱动器相对路径（即给定驱动器的绝对路径）。@as-index{@litchar{RED}} 部分必须恰好是三个大写字母，@litchar{/} 不能用于替代 @litchar{\\}。与 @litchar{\\\\?\\REL} 路径不同，@litchar{..} 元素始终是字面路径元素。当 @litchar{\\\\?\\RED} 路径值转换为字符串（或当路径值被写入或显示）时，字符串不包含开头的 @litchar{\\\\?\\RED} 并包含单个开头的 @litchar{\\}；将路径值转换为字节串保留 @litchar{\\\\?\\RED} 前缀。}

 ]

 三个额外的 Racket 特定规则为否则作为 Windows 路径格式错误的字符序列提供含义：

 @itemize[

   @item{@|MzAdd| 在形式为 @litchar{\\\\?\\}@nonterm{any}@litchar{\\\\} 的路径名中，其中 @nonterm{any} 是除 @nonterm{letter}@litchar{:} 或 @litchar{\\}@nonterm{letter}@litchar{:} 之外的任何非空字符序列，整个路径计为路径的（不存在的）驱动器。}

   @item{@|MzAdd| 在形式为 @litchar{\\\\?\\}@nonterm{any}@litchar{\\\\\\}@nonterm{elements} 的路径名中，其中 @nonterm{any} 是任何非空字符序列，@nonterm{elements} 是不以 @litchar{\\} 开头、不以两个 @litchar{\\} 结尾且不包含三个 @litchar{\\} 序列的任何序列，@litchar{\\\\?\\}@nonterm{any}@litchar{\\\\} 计为路径的（不存在的）驱动器。}

   @item{@|MzAdd| 在以 @litchar{\\\\?\\} 开头且与前面项目符号中的任何模式都不匹配的路径名中，@litchar{\\\\?\\} 计为路径的（不存在的）驱动器。}

 ]

 在 Racket 之外，除了 @litchar{\\\\?\\} 路径外，路径名用作文件路径时通常限制为 259 个字符，用作目录路径时限制为 247 个字符。Racket 在内部将超过 247 个字符的路径名转换为 @litchar{\\\\?\\} 形式以避免限制；在这种情况下，路径首先进行语法简化（在 @racket[simplify-path] 的意义上）。操作系统无法通过超过 32,000 个字符的 @litchar{\\\\?\\} 路径访问文件。

 当上述描述说"字符"时，将"字节"替换为将字节串解释为路径。Windows 路径到字节的编码保留 ASCII 字符，且上述所有特殊字符都是 ASCII，因此所有规则都相同。

 请注意，@litchar{\\} 路径分隔符在 Racket 字符串中是转义字符。因此，路径 @litchar{\\\\?\\REL\\..\\\\..} 作为字符串必须写为 @racket["\\\\\\\\?\\\\REL\\\\..\\\\\\\\.."]。

 以目录分隔符结尾的路径在语法上引用目录。此外，如果路径的最后一个元素是相同目录或向上目录指示符（未被 @litchar{\\\\?\\} 形式引用），或者它引用根，则路径在语法上引用目录。

 即使在其支持符号链接的 Windows 变体上，路径中的向上目录 @litchar{..} 指示符也是语法解析的，对链接不敏感。例如，如果路径以 @litchar{d\\..\\f} 结尾且 @litchar{d} 引用引用具有与 @litchar{d} 不同父目录的目录的符号链接，则路径仍然引用与 @litchar{d} 同一目录中的 @litchar{f}。相对路径链接被解析为如同以 @litchar{\\\\?\\REL} 路径为前缀，但 @litchar{..} 和 @litchar{.} 元素允许在整个路径中，且允许任意数量的冗余 @litchar{\\} 分隔符。

 Windows 路径按如下方式 @techlink{cleanse}：在以 @litchar{\\\\?\\} 开头的路径中，移除冗余的 @litchar{\\}，如果尚未存在额外的 @litchar{\\} 来分隔向上目录指示符和字面路径元素，则在 @litchar{\\\\?\\REL} 中添加额外的 @litchar{\\}，类似地，如果尚未存在额外的 @litchar{\\}，则在 @litchar{\\\\?\\RED} 之后添加额外的 @litchar{\\}。
 @;{>> I don't know what was meant to go in place of "???", and I can't
 figure out an example that could trigger this case: <<
 When @litchar{\\\\?\\} acts as the drive and the path contains ???, two
 additional @litchar{\\}s (which might otherwise be redundant) are
 included after the root.}@;
 对于其他路径，多个 @litchar{/} 和 @litchar{\\} 转换为单个 @litchar{/} 或 @litchar{\\}（共享文件夹名称开头除外），如果缺少，则在驱动器说明符中的冒号后插入 @litchar{\\}。

 对于 @racket[(bytes->path-element _bstr)]，@litchar{/}、冒号、尾随点、尾随空白和特殊设备名称（例如"aux"）在 @racket[_bstr] 中通过使用 @litchar{\\\\?\\REL} 前缀编码为路径元素的一部分。@racket[bstr] 参数不得包含 @litchar{\\}，否则 @exnraise[exn:fail:contract]。

 对于 @racket[(path-element->bytes _path)] 或 @racket[(path-element->string _path)]，如果 @racket[_path] 的字节串形式以 @litchar{\\\\?\\REL} 开头，则前缀不包含在结果中。

 对于 @racket[(build-path _base-path _sub-path ...)]，尾随空格和句号从 @racket[_base-path] 的最后一个元素和除最后一个 @racket[_sub-path] 之外的所有元素中移除（除非元素仅由空格和句号组成），除了以 @litchar{\\\\?\\} 开头的元素。如果 @racket[_base-path] 以 @litchar{\\\\?\\} 开头，则在添加每个非 @litchar{\\\\?\\REL\\} 和非 @litchar{\\\\?\\RED\\} @racket[_sub-path] 后，添加中的 @litchar{/} 转换为 @litchar{\\}，多个连续 @litchar{\\} 转换为单个 @litchar{\\}，添加的 @litchar{.} 元素被移除，添加的 @litchar{..} 元素与前一个元素一起被移除；这些转换不适用于结果的原始 @racket[_base-path] 部分或任何 @litchar{\\\\?\\REL\\} 或 @litchar{\\\\?\\RED\\} 或 @racket[_sub-path]。如果 @litchar{\\\\?\\REL\\} 或 @litchar{\\\\?\\RED\\} @racket[_sub-path] 添加到非 @litchar{\\\\?\\} @racket[_base-path]，则 @racket[_base-path]（以及直到 @litchar{\\\\?\\REL\\} 或 @litchar{\\\\?\\RED\\} @racket[_base-path] 的任何添加）被简化并转换为 @litchar{\\\\?\\} 路径。在其他情况下，可以在组合路径之前添加或移除 @litchar{\\} 以避免更改路径的根含义（例如，组合 @litchar{//x} 和 @litchar{y} 产生 @litchar{/x/y}，因为 @litchar{//x/y} 将是 UNC 路径而不是驱动器相对路径）。

 对于 @racket[(simplify-path _path _use-filesystem?)]，@racket[_path] 被展开，如果 @racket[_path] 不以 @litchar{\\\\?\\} 开头，则移除尾随空格和句号，如果缺少，则在驱动器说明符中的冒号后插入 @litchar{/}，如果存在元素且没有额外的 @litchar{\\}，则在 @litchar{\\\\?\\} 后作为根插入 @litchar{\\}。否则，如果 @racket[_path] 中没有指示符或冗余分隔符，则返回 @racket[_path]。

 对于 @racket[(split-path _path)] 产生 @racket[_base]、@racket[_name] 和 @racket[_must-be-dir?]，拆分不以 @litchar{\\\\?\\} 开头的路径可能产生以 @litchar{\\\\?\\} 开头的部分。例如，拆分 @litchar~{C:/x~/aux/} 两次产生 @litchar~{\\\\?\\REL\\\\x~} 和 @litchar{\\\\?\\REL\\\\aux}；在这些情况下需要 @litchar{\\\\?\\} 以在 @litchar{x} 之后保留尾随空格并避免引用 AUX 设备而不是 @filepath{aux} 文件。

@section[#:tag "windowspathrep"]{Windows Path Representation}

Windows 上的路径原生是 UTF-16 码元序列，其中序列可以包含未配对的代理。此序列通过 UTF-8 的扩展编码为字节串，其中 UTF-16 码元序列中的未配对的代理如同非代理值一样转换。扩展编码在 Windows 上实现为 @racket[bytes-open-converter] 的 @racket["platform-UTF-16"] 和 @racket["platform-UTF-8"] 编码。

Racket 的 Windows 路径内部表示是字节串，因此 @racket[path->bytes] 和 @racket[bytes->path] 始终是互逆的。当将路径转换为原生 UTF-16 码元序列时，@racket[#\\tab] 用于替代 platform-UTF-8 解码错误（理由是 tab 通常不允许作为 Windows 路径中的字符，不像 @code{#\\uFFFD}）。

Windows 路径通过将 platform-UTF-8 编码视为 UTF-8 编码，以 @code{#\\uFFFD} 替代解码错误，转换为字符串。类似地，字符串通过 UTF-8 编码转换为路径（在这种情况下不可能出现错误）。
