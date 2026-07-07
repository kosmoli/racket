#lang scribble/doc
@(require "mz.rkt" (for-label racket/port))

@title[#:tag "encodings"]{Encodings and Locales}

当端口提供给基于字符的操作（如 @racket[read-char] 或 @racket[read]）时，端口的字节被读取并解释为字符的 UTF-8 编码。因此，读取单个字符可能需要读取多个字节，而 @racket[char-ready?] 等 procedure 可能需要窥视流中的多个字节来确定字符是否可用。在字节流不对应有效 UTF-8 编码的情况下，@racket[read-char] 等函数可能需要向前窥视一个字节以发现流不是有效编码。

当输入端口产生不是有效 UTF-8 编码的字节序列时，在字符读取上下文中，构成无效序列的字节将转换为字符 @racketvalfont{#\\uFFFD}。具体而言，字节 255 和 254 始终转换为 @racketvalfont{#\\uFFFD}，范围 192 到 253 的字节在后面不跟随形成有效 UTF-8 编码的字节时产生 @racketvalfont{#\\uFFFD}，范围 128 到 191 的字节在它们不是有效编码的一部分时（由前面的 192 到 253 范围内的字节开始）转换为 @racketvalfont{#\\uFFFD}。换句话说，当将字节序列作为字符读取时，最少数量的字节被更改为 @racketvalfont{#\\uFFFD} 的编码，以使整个字节序列成为有效的 UTF-8 编码。

See @secref["bytestrings"] 获取有关使用 UTF-8 或其他编码进行转换的过程。也参见 @racket[reencode-input-port] 和 @racket[reencode-output-port] 以从使用不同字符编码的端口获取基于 UTF-8 的端口。

@deftech{locale} 捕获有关用户特定语言解释字符序列的信息。特别是，locale 确定字符串如何"字母排序"，小写字符如何转换为大写字符，以及字符串如何不区分大小写进行比较。@racket[string-ci=?] 等字符串操作对当前 @italic{不} 敏感，但 @racket[string-locale-ci=?]（见 @secref["strings"]）等操作产生与当前 locale 一致的结果。

locale 还指定代码点序列到字节序列的特定编码。Racket 通常忽略 locale 的这一方面，只有几个明显的例外：作为字节字符串传递给 Racket 的命令行参数使用 locale 的编码转换为字符字符串；以字节字符串形式传递给其他进程的命令行字符串（通过 @racket[subprocess]）使用 locale 的编码转换为字节字符串；环境变量使用 locale 的编码进行字符串转换；文件系统路径使用 locale 的编码进行字符串转换（用于显示目的）；最后，Racket 提供了诸如 @racket[string->bytes/locale] 等函数来专门调用特定 locale 的编码。

Unix 用户通过设置环境变量（如 @envvar{LC_ALL}）来选择 locale。在 Windows 和 Mac OS 上，操作系统提供了其他设置 locale 的机制。在 Racket 内，可以通过设置 @racket[current-locale] 参数来更改当前 locale。Racket 内的 locale 名称是一个字符串，可用的 locale 名称取决于其平台及其配置，但 @racket[""] locale 表示当前用户的默认 locale；在 Windows 和 Mac OS 上，@racket[""] 的编码始终是 UTF-8，而 locale 敏感操作使用操作系统的本机接口。（具体而言，在 Mac OS 上设置 @envvar{LC_ALL} 和 @envvar{LC_CTYPE} 环境变量不会影响 locale @racket[""]。如果需要，使用 @racket[getenv] 和 @racket[current-locale] 显式安装环境指定的 locale。）将当前 locale 设置为 @racket[#f] 使 locale 敏感操作变为 locale 不敏感，这意味着对 case 操作使用 Unicode 映射，对编码使用 UTF-8。

@defparam[current-locale locale (or/c string? #f)]{

一个 @tech{parameter}，用于确定 @racket[string-locale-ci=?] 等过程的当前 @tech{locale}。

当通过将参数设置为 @racket[#f] 来禁用 locale 敏感性时，字符串等以完全可移植的方式比较，这与标准过程相同。否则，字符串根据 C 库的 @tt{setlocale} 的 locale 设置进行解释。@racket[""] locale 始终是当前机器默认 locale 的别名，并且是默认值。@racket["C"] locale 也始终可用；将 locale 设置为 @racket["C"] 与仅使用 @racket[#f] 禁用 locale 敏感性相同，但仅限于字符串操作限制在前 128 个字符时。其他特定于平台的 locale 名称。

使用 @racket[write] 进行的字符串或字符打印不受参数影响，symbol 的正则表达式也不受影响（参见 @secref["regexp"]）。}
