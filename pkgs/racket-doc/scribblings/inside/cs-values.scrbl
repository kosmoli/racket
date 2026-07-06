#lang scribble/doc
@(require "utils.rkt"
          (for-label racket/unsafe/ops
                     ffi/unsafe))

@cs-title[#:tag "cs-values+types"]{值与类型}

Racket 值由指针大小的值表示。该值的低比特位指示其使用的编码方式。例如，在 32 位平台上两个（或在 64 位平台上三个）最低比特位表示 fixnum 编码，而一个最低位为 1 且次低位为 0 表示一个 pair，其内存地址由其余比特位指定。

Racket 值的 C 类型是 @tt{ptr}。对于大多数 Racket 类型，都提供了构造函数来创建该类型的值。例如，@cpp{Scons} 接受两个 @cpp{ptr} 值并返回这些值的 @racket[cons] 作为新的 @cpp{ptr} 值。除了提供构造函数外，Racket 还定义了几个全局常量 Racket 值，例如用于 @racket[#t] 的 @cppi{Strue}。

@; ----------------------------------------------------------------------

@section[#:tag "cs-constants"]{全局常量}

共有六个全局常量：

@itemize[

 @item{@cppdef{Strue} --- @racket[#t]}

 @item{@cppdef{Sfalse} --- @racket[#f]}

 @item{@cppdef{Snil} --- @racket[null]}

 @item{@cppdef{Seof_object} --- @racket[eof-object]}

 @item{@cppdef{Svoid} --- @racket[(void)]}

]

@; ----------------------------------------------------------------------

@section[#:tag "cs-value-funcs"]{值函数}

这些函数中的许多实际上是宏。

@(define-syntax-rule (predicates (name ...) desc ...)
   (together
     (@function[(int name [ptr v])] ...)
     desc ...))

@predicates[(Sfixnump
             Scharp
             Snullp
             Seof_objectp
             Sbooleanp
             Spairp
             Ssymbolp
             Sprocedurep
             Sflonump
             Svectorp
             Sfxvectorp
             Sbytevectorp
             Sstringp
             Sbignump
             Sboxp
             Sinexactnump
             Sexactnump
             Sratnump
             Srecordp)]{

用于识别不同种类 Racket 值的谓词，例如 fixnum、字符、空列表等。@cpp{Srecordp} 谓词识别结构体，但某些内置 Racket 数据类型也实现为 record。}

@function[(ptr Sfixnum [int i])]{

返回一个 Racket 整数值，其中 @var{i} 必须适合 fixnum。}

@together[(
@function[(ptr Sinteger [iptr i])]
@function[(ptr Sunsigned [uptr i])]
@function[(ptr Sinteger32 [int i])]
@function[(ptr Sunsigned32 [unsigned-int i])]
@function[(ptr Sinteger64 [long i])]
@function[(ptr Sunsigned64 [unsigned-long i])]
)]{

从 C 进行不同转换时返回整数值，结果在必要时分配为 bignum 以容纳该值。}

@function[(iptr Sfixnum_value [ptr v]){

将 Racket fixnum 转换为 C 整数。}

@together[(
@function[(iptr Sinteger_value [ptr v])]
@function[(uptr Sunsigned_value [ptr v])]
@function[(int Sinteger32_value [ptr v])]
@function[(long Sunsigned32_value [ptr v])]
@function[(long Sinteger64_value [ptr v])]
@function[(unsigned-long Sunsigned64_value [ptr v])]
)]{

将 Racket 整数（可能是 bignum）转换为 C 整数，假设整数适合返回类型。}

@function[(ptr Sflonum [double f]){

返回一个 Racket flonum 值。}

@function[(double Sflonum_value [ptr v]){

将 Racket flonum 值转换为 C 浮点数。}


@function[(ptr Schar [int ch]){

返回一个 Racket 字符值。@var{ch} 值必须是合法的 Unicode 码点（且不能是代理字符，例如）。所有字符都由常量值表示。}


@function[(ptr Schar_value [ptr ch]){

返回 Racket 字符 @var{ch} 的 Unicode 码点。}


@function[(ptr Sboolean [int bool]){

返回 @cppi{Strue} 或 @cppi{Sfalse}。}


@function[(ptr Scons [ptr car] [ptr cdr]){

创建一个 @racket[cons] pair。}

@together[(
@function[(ptr Scar [ptr pr])]
@function[(ptr Scdr [ptr pr])]
)]{

提取 pair 的 @racket[car] 或 @racket[cdr]。}

@function[(ptr Sstring_to_symbol [const-char* str]){

返回名称与 @var{str} 匹配的驻留符号。}

@function[(ptr Ssymbol_to_string [ptr sym]){

返回 Racket 符号 @var{sym} 的 Racket 不可变字符串值。}

@together[(
@function[(ptr Smake_string [iptr len] [int ch])]
@function[(ptr Smake_uninitialized_string [iptr len])]
)]{

分配一个包含 @var{len} 个字符的 Racket 可变字符串。字符串内容在提供 @var{ch} 时全为 @var{ch}，否则未指定。}

@together[(
@function[(ptr Sstring [const-char* str])]
@function[(ptr Sstring_of_length [const-char* str] [iptr len])]
@function[(ptr Sstring_utf8 [const-char* str] [iptr len])]
)]{

分配一个包含 @var{str} 内容的 Racket 可变字符串。如果未提供 @var{len}，则 @var{str} 必须以 nul 结尾。对于 @cppi{Sstring_utf8}，@var{str} 被解码为 UTF-8，否则被解码为 Latin-1。}


@function[(uptr Sstring_length [ptr str]){

返回字符串 @var{str} 的长度。}

@function[(ptr Sstring_ref [ptr str] [uptr i]){

返回字符串 @var{str} 的第 @var{i} 个 Racket 字符。}

@function[(int Sstring_set [ptr str] [uptr i] [ptr ch]){

将 @var{ch} 安装为字符串 @var{str} 的第 @var{i} 个 Racket 字符。}



@function[(ptr Smake_vector [iptr len] [ptr v]){

分配一个长度为 @var{len} 的 @tech[#:doc reference-doc]{vector}，每个槽位初始值为 @var{v}。}


@function[(uptr Svector_length [ptr vec]){

返回 vector @var{vec} 的长度。}


@function[(ptr Svector_ref [ptr vec] [uptr i]){

返回 vector @var{vec} 的第 @var{i} 个元素。}


@function[(void Svector_set [ptr vec] [uptr i] [ptr v]){

将 @var{v} 安装为 vector @var{vec} 的第 @var{i} 个元素。}


@function[(ptr Smake_fxvector [iptr len] [ptr v]){

分配一个长度为 @var{len} 的 @tech[#:doc reference-doc]{fxvector}，每个槽位初始值为 @var{v}。}


@function[(uptr Sfxvector_length [ptr vec]){

返回 fxvector @var{vec} 的长度。}


@function[(iptr Sfxvector_ref [ptr vec] [uptr i]){

返回 fxvector @var{vec} 的第 @var{i} 个 fixnum。}


@function[(void Sfxvector_set [ptr vec] [uptr i] [ptr v]){

将 fixnum @var{v} 安装为 fxvector @var{vec} 的第 @var{i} 个元素。}



@function[(ptr Smake_bytevector [iptr len] [int byte]){

分配一个长度为 @var{len} 的 @tech[#:doc reference-doc]{byte string}，每个槽位初始值为 @var{byte}。}

@function[(uptr Sbytevector_length [ptr bstr]){

返回 byte string @var{bstr} 的长度。}

@function[(int Sbytevector_u8_ref [ptr bstr] [uptr i]){

返回 byte string @var{bstr} 的第 @var{i} 个字节。}

@function[(int Sbytevector_u8_set [ptr bstr] [uptr i] [int byte]){

将 @var{byte} 安装为 byte string @var{bstr} 的第 @var{i} 个字节。}

@function[(char* Sbytevector_data [ptr vec]){

返回指向 byte string @var{bstr} 字节起始位置的指针。}


@function[(ptr Sbox [ptr v]){

分配一个包含 @var{v} 的 @tech[#:doc reference-doc]{box}。}

@function[(ptr Sunbox [ptr bx]){

提取 box @var{bx} 的内容。}

@function[(ptr Sset_box [ptr bx] [ptr v]){

将 @var{v} 安装为 box @var{bx} 的内容。}

@together[(
@function[(ptr Srecord_type [ptr rec])]
@function[(ptr Srecord_type_parent [ptr rtd])]
@function[(uptr Srecord_type_size [ptr rtd])]
@function[(int Srecord_type_uniformp [ptr rtd])]
@function[(ptr Srecord_uniform_ref [ptr rec][iptr i])]
)]{

访问 record 信息，其中 Racket 结构体实现为 record。@cpp{Srecord_type} 返回表示 record 类型（即结构体类型）的值。给定一个 record 类型，@cpp{Srecord_type_parent} 返回其超类型或 @cpp{Sfalse}，@cpp{Srecord_type_size} 返回 record 的分配大小（以字节为单位），@cpp{Srecord_type_uniformp} 指示 record 的所有字段是否都是 Scheme 值——对于 Racket 结构体始终为真。当 record 的所有字段都是 Scheme 值时，分配大小为字段数量加一乘以指针大小（以字节为单位）。

当 record 的所有字段都是 Scheme 值时（对于所有 Racket 结构体都是如此），@cpp{Srecord_uniform_ref} 以与 @racket[unsafe-struct*-ref] 相同的方式访问字段值。}

@together[(
@function[(void* racket_cpointer_address [ptr cptr])]
@function[(void* racket_cpointer_base_address [ptr cptr])]
@function[(iptr racket_cpointer_offset [ptr cptr])]
)]{

从 @racket[cpointer?] 意义上的 C-pointer 对象中提取地址和偏移量，但仅适用于使用预定义表示形式的值，即不是 byte string、@racket[#f] 或由带有 @racket[prop:cpointer] 的新结构体类型实现的值。

@cpp{racket_cpointer_address} 的结果等于 @cpp{racket_cpointer_base_address} 加上 @cpp{racket_cpointer_offset}，其中 @cpp{racket_cpointer_offset} 对于由 @racket[ptr-add] 创建的 C-pointer 值非零。}


@together[(
@function[(void Slock_object [ptr cptr])]
@function[(void Sunlock_object [ptr cptr])]
)]{

"锁定"或"解锁"一个对象，防止其被垃圾收集或移动到不同地址。

谨慎使用锁定对象，因为垃圾收集器并非为处理大量锁定对象而设计。要从 C 中保留多个值，一种好的方法可能是分配并锁定一个 vector，其中为每个其他（未锁定）要保留的对象设置一个槽位。}
