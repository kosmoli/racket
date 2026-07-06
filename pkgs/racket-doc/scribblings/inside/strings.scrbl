#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "im:encodings"]{字符串编码}

@cpp{scheme_utf8_decode} 函数将 @cpp{char} 数组按 UTF-8 解码为 UCS-4 @cpp{mzchar} 数组或 UTF-16 @cpp{short} 数组。@cpp{scheme_utf8_encode} 函数将 UCS-4 @cpp{mzchar} 数组或 UTF-16 @cpp{short} 数组编码为 UTF-8 @cpp{char} 数组。

这些函数可用于检查或测量编码或解码，而无需实际生成解码或编码结果，函数的变体提供对解码错误处理的控制。

@function[(int scheme_utf8_decode
           [const-unsigned-char* s]
           [int start]
           [int end]
           [mzchar* us]
           [int dstart]
           [int dend]
           [intptr_t* ipos]
           [char utf16]
           [int permissive])]{

将字节数组按 UTF-8 解码，生成 Unicode code point 到 @var{us} 中（当 @var{utf16} 为零时），或生成 UTF-16 code unit 到强制转换为 @cpp{short*} 的 @var{us} 中（当 @var{utf16} 为非零时）。不会向 @var{us} 添加 nul 终止符。

当所有给定字节都被解码时，结果为非负数，结果为解码的长度（以 @cpp{mzchar} 或 @cpp{short} 为单位）。结果为 @cpp{-2} 表示给定字节中存在无效编码序列（可能因为解码范围在编码中间结束），结果为 @cpp{-3} 表示解码因结果字符串空间不足而停止。

@var{start} 和 @var{end} 参数指定要解码的 @var{s} 的范围。如果 @var{end} 为负数，则使用 @cpp{strlen(@var{s})} 作为结束位置。

如果 @var{us} 为 @cpp{NULL}，则不生成解码字节，但结果与写入解码字节时一样有效。@var{dstart} 和 @var{dend} 参数指定 @var{us} 中解码的目标范围（以 @cpp{mzchar} 或 @cpp{short} 为单位）；@var{dend} 为负数表示可以向 @var{us} 写入任意数量的字节，这通常仅在 @var{us} 为 @cpp{NULL} 以测量解码长度时才有意义。

如果 @var{ipos} 非 @cpp{NULL}，则用 @var{s} 中第一个未解码的索引填充。如果函数结果为非负数，则 @cpp{*@var{ipos}} 被设置为结束索引（如果 @var{end} 非负则为 @var{end}，否则为 @cpp{strlen(@var{s})}）。如果结果为 @cpp{-1} 或 @cpp{-2}，则 @cpp{*@var{ipos}} 有效指示解码停止前解码了多少字节。

如果 @var{permissive} 非零，则用作不属于有效 UTF-8 编码的字节或输入在编码中间结束时的解码。因此，仅当 @var{permissive} 为 @cpp{0} 时，函数结果才可能为 @cpp{-1} 或 @cpp{-2}。

在 Windows 上，当 @var{utf16} 非零时，解码支持 UTF-8 的自然扩展，可以在结果中生成未配对的 UTF-16 surrogate。

此函数不分配内存或触发 garbage collection。}

@function[(int scheme_utf8_decode_offset_prefix
           [const-unsigned-char* s]
           [int start]
           [int end]
           [mzchar* us]
           [int dstart]
           [int dend]
           [intptr_t* ipos]
           [char utf16]
           [int permissive])]{

类似于 @cpp{scheme_utf8_decode}，但如果输入在 UTF-8 编码中间结束，即使 @var{permissive} 非零也返回 @cpp{-1}。

@history[#:added "6.0.1.13"]}


@function[(int scheme_utf8_decode_as_prefix
           [const-unsigned-char* s]
           [int start]
           [int end]
           [mzchar* us]
           [int dstart]
           [int dend]
           [intptr_t* ipos]
           [char utf16]
           [int permissive])]{

类似于 @cpp{scheme_utf8_decode}，但结果始终为解码的 @cpp{mzchar} 或 @cpp{short} 的数量。如果遇到解码错误，结果仍为错误前解码的大小。}

@function[(int scheme_utf8_decode_all
           [const-unsigned-char* s]
           [int len]
           [mzchar* us]
           [int permissive])]{

类似于 @cpp{scheme_utf8_decode}，但参数更少。解码生成 UCS-4 @cpp{mzchar}。如果缓冲区 @var{us} 非 @cpp{NULL}，则假定其足够长以容纳解码结果（不会比输入长，但可能更短）。如果 @var{len} 为负数，则使用 @cpp{strlen(@var{s})} 作为输入长度。}


@function[(int scheme_utf8_decode_prefix
           [const-unsigned-char* s]
           [int len]
           [mzchar* us]
           [int permissive])]{

类似于 @cpp{scheme_utf8_decode}，但参数更少。解码生成 UCS-4 @cpp{mzchar}。缓冲区 @var{us} @bold{必须}非 @cpp{NULL}，假定其足够长以容纳解码结果（不会比输入长，但可能更短）。如果 @var{len} 为负数，则使用 @cpp{strlen(@var{s})} 作为输入长度。

除了 @cpp{scheme_utf8_decode} 的结果外，结果可能为 @cpp{-1} 表示输入以部分（有效）编码结束。即使 @var{permissive} 非零，也可能出现 @cpp{-1} 结果。}

@function[(mzchar* scheme_utf8_decode_to_buffer
           [const-unsigned-char* s]
           [int len]
           [mzchar* buf]
           [int blen])]{

类似于 @cpp{scheme_utf8_decode_all}，@var{permissive} 为 @cpp{0}，但如果 @var{buf} 不够大（由 @var{blen} 指示）以容纳结果，则分配新缓冲区。与其他函数不同，此函数向解码结果添加 nul 终止符。函数结果为 @var{buf}（如果足够大）或用 @cpp{scheme_malloc_atomic} 分配的缓冲区。}

@function[(mzchar* scheme_utf8_decode_to_buffer_len
           [const-unsigned-char* s]
           [int len]
           [mzchar* buf]
           [int blen]
           [intptr_t* ulen])]{

类似于 @cpp{scheme_utf8_decode_to_buffer}，但如果 @var{ulen} 非 @cpp{NULL}，则将结果长度（不含终止符）放入 @var{ulen}。}

@function[(int scheme_utf8_decode_count
           [const-unsigned-char* s]
           [int start]
           [int end]
           [int* state]
           [int might_continue]
           [int permissive])]{

类似于 @cpp{scheme_utf8_decode}，但不生成解码的 @cpp{mzchar}，始终返回解码错误前（如有）解码的 @cpp{mzchar} 数量。如果 @var{might_continue} 非零，当 @var{permissive} 也非零时，输入末尾的部分有效编码不被解码。

如果 @var{state} 非 @cpp{NULL}，则保存关于部分编码的信息；初始调用时应设为零，然后与扩展给定输入的字节一起传回 @cpp{scheme_utf8_decode}（即不带任何未使用的部分编码）。通常，此模式仅在 @var{might_continue} 和 @var{permissive} 都非零时才有意义。}


@function[(int scheme_utf8_encode
           [const-mzchar* us]
           [int start]
           [int end]
           [unsigned-char* s]
           [int dstart]
           [char utf16])]{

将给定的 @cpp{mzchar} 的 UCS-4 数组（如果 @var{utf16} 为零）或 @cpp{short} 的 UTF-16 数组（如果 @var{utf16} 非零）编码到 @var{s} 中。@var{end} 参数必须不小于 @var{start}。

假定数组 @var{s} 足够长以包含编码，但如果 @var{s} 为 @cpp{NULL} 则不写入编码。@var{dstart} 参数指示 @var{s} 中保存编码的起始位置。不会向 @var{s} 添加 nul 终止符。

结果为编码产生的字节数（或如果 @var{s} 非 @cpp{NULL} 将产生的字节数）。编码永远不会失败。

在 Windows 上，当 @var{utf16} 非零时，编码支持输入 UTF-16 code-unit 序列中的未配对 surrogate，此时编码生成编码未配对 surrogate 的 UTF-8 自然扩展。

此函数不分配内存或触发 garbage collection。}

@function[(int scheme_utf8_encode_all
           [const-mzchar* us]
           [int len]
           [unsigned-char* s])]{

类似于 @cpp{scheme_utf8_encode}，@var{start} 为 @cpp{0}，@var{end} 为 @var{len}，@var{dstart} 为 @cpp{0}，@var{utf16} 为 @cpp{0}。}

@function[(char* scheme_utf8_encode_to_buffer
           [const-mzchar* s]
           [int len]
           [char* buf]
           [int blen])]{

类似于 @cpp{scheme_utf8_encode_all}，但给定 @var{buf} 的长度，如果不够长以容纳编码，则分配缓冲区。向编码数组添加 nul 终止符。结果为 @var{buf} 或用 @cpp{scheme_malloc_atomic} 分配的数组。}

@function[(char* scheme_utf8_encode_to_buffer_len
           [const-mzchar* s]
           [int len]
           [char* buf]
           [int blen]
           [intptr_t* rlen])]{

类似于 @cpp{scheme_utf8_encode_to_buffer}，但如果 @var{rlen} 非 @cpp{NULL}，则报告结果编码的长度（不含 nul 终止符）。}


@function[(unsigned-short* scheme_ucs4_to_utf16
           [const-mzchar* text]
           [int start]
           [int end]
           [unsigned-short* buf]
           [int bufsize]
           [intptr_t* ulen]
           [int term_size])]{

将 UCS-4 编码（@var{text} 的指定范围）转换为 UTF-16 编码。@var{end} 参数必须不小于 @var{start}。

如果 @var{buf} 不够长（由 @var{bufsize} 指示），则分配结果缓冲区。如果 @var{ulen} 非 @cpp{NULL}，则用 UTF-16 编码的长度填充。@var{term_size} 参数指示在结果缓冲区末尾保留的 @cpp{short} 数量用于终止符（但实际上不写入终止符）。}

@function[(mzchar* scheme_utf16_to_ucs4
           [const-unsigned-short* text]
           [int start]
           [int end]
           [mzchar* buf]
           [int bufsize]
           [intptr_t* ulen]
           [int term_size])]{

将 UTF-16 编码（@var{text} 的指定范围）转换为 UCS-4 编码。@var{end} 参数必须不小于 @var{start}。

如果 @var{buf} 不够长（由 @var{bufsize} 指示），则分配结果缓冲区。如果 @var{ulen} 非 @cpp{NULL}，则用 UCS-4 编码的长度填充。@var{term_size} 参数指示在结果缓冲区末尾保留的 @cpp{mzchar} 数量用于终止符（但实际上不写入终止符）。}
