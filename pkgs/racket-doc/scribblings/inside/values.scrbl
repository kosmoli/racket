#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "im:values+types"]{值(Values)与类型(Types)}

Racket 值由一个指针大小的值表示。低 bit 是一个标记 bit：低 bit 为 1 表示一个立即数（immediate integer），为 0 表示一个（字对齐的）指针。

一个指针类型的 Racket 值引用一个以 @cppi{Scheme_Object} 子结构开头的结构体，该子结构又以一个 C 类型为 @cppi{Scheme_Type} 的 tag 开头。结构体的其余部分（紧随 @cppi{Scheme_Object} 头部之后）依赖于具体类型。Racket 的 C 接口将 Racket 值的类型定为 @cpp{Scheme_Object*}。（这里的 ``object'' 不是指 @racketmodname[racket/class] 库意义上的对象。）

@cpp{Scheme_Type} 值的示例包括 @cpp{scheme_pair_type} 和 @cpp{scheme_symbol_type}。其中一些类型被实现为 @cppi{Scheme_Simple_Object} 的实例（该类型定义在 @filepath{scheme.h} 中），但扩展或嵌入代码绝不应直接访问此结构体。相反，代码应使用宏——如 @cpp{SCHEME_CAR}——来访问常见 Racket 类型的数据。

对于大多数 Racket 类型，都提供了用于创建该类型值的构造函数。例如，@cpp{scheme_make_pair} 接受两个 @cpp{Scheme_Object*} 值并返回这些值的 @racket[cons]。

宏 @cppdef{SCHEME_TYPE} 接受一个 @cpp{Scheme_Object *} 并返回该对象的类型。此宏执行标记 bit 检查，当值为立即数整数时返回 @cppi{scheme_integer_type}；否则，@cpp{SCHEME_TYPE} 跟随指针获取类型 tag。系统提供了用于测试常见 Racket 类型的宏；例如，@cpp{SCHEME_PAIRP} 在值为 cons 单元时返回 @cpp{1}，否则返回 @cpp{0}。

除了提供构造函数之外，Racket 还定义了六个全局常量 Racket 值：@cppi{scheme_true}、@cppi{scheme_false}、@cppi{scheme_null}、@cppi{scheme_eof}、@cppi{scheme_void} 和 @cppi{scheme_undefined}。每个值都有一个类型 tag，但通常通过其常量地址来识别。

@index['("types" "creating")]{扩展}或嵌入应用程序可以通过调用 @cppi{scheme_make_type} 来创建新的原始数据类型，该函数返回一个新的 @cpp{Scheme_Type} 值。要创建此类型的可回收实例，请使用 @cpp{scheme_malloc_atomic} 为该实例分配内存。从 Racket 的角度看，此类实例的数据格式的主要约束是：前 @cpp{sizeof(Scheme_Object)} 个字节必须对应一个 @cpp{Scheme_Object} 记录；此外，前 @cpp{sizeof(Scheme_Type)} 个字节必须包含 @cpp{scheme_make_type} 返回的值。需求较简单的扩展可以使用 @cppi{scheme_make_cptr}，而不必创建全新的类型。

Racket 值绝不应在栈上分配，也绝不应包含指向栈上值的指针。除了将值的生命周期限制在栈帧内的问题外，在栈上分配值还会给 continuation 和线程带来问题，因为两者都会在栈中复制数据。

@; ----------------------------------------------------------------------

@section[#:tag "im:stdtypes"]{Standard Types}

以下是标准类型的 @cpp{Scheme_Type} 值：

@itemize[

 @item{@cppdef{scheme_bool_type} —— 常量 @cpp{scheme_true} 和 @cpp{scheme_false} 是此类型的唯二值；使用 @cpp{SCHEME_FALSEP} 识别 @cpp{scheme_false}，使用 @cpp{SCHEME_TRUEP} 识别除 @cpp{scheme_false} 之外的任何值；使用 @cppdef{SCHEME_BOOLP} 测试此类型}

 @item{@cppdef{scheme_char_type} —— @cppdef{SCHEME_CHAR_VAL} 提取字符（类型为 @cppi{mzchar}）；使用 @cppdef{SCHEME_CHARP} 测试此类型}

 @item{@cppdef{scheme_integer_type} —— fixnum 整数，通过标记 bit 识别而非跟随指针到此 @cpp{Scheme_Type} 值；@cppdef{SCHEME_INT_VAL} 将整数提取到 @cpp{intptr_t}；使用 @cppdef{SCHEME_INTP} 测试此类型}

 @item{@cppdef{scheme_double_type} —— flonum 非精确数；@cppdef{SCHEME_FLOAT_VAL} 或 @cppdef{SCHEME_DBL_VAL} 提取浮点值；使用 @cppdef{SCHEME_DBLP} 测试此类型}

 @item{@cppdef{scheme_float_type} —— 单精度 flonum 非精确数（仅在编译 Racket 时显式启用）；@cppi{SCHEME_FLOAT_VAL} 或 @cppdef{SCHEME_FLT_VAL} 提取浮点值；使用 @cppdef{SCHEME_FLTP} 测试此类型}

 @item{@cppdef{scheme_bignum_type} —— 使用 @cppdef{SCHEME_BIGNUMP} 测试此类型}
 
 @item{@cppdef{scheme_rational_type} —— 使用 @cppdef{SCHEME_RATIONALP} 测试此类型}

 @item{@cppdef{scheme_complex_type} —— 使用 @cppdef{SCHEME_COMPLEXP} 测试此类型}

 @item{@cppdef{scheme_char_string_type} —— @index['("strings" "conversion to C")]{@cppdef{SCHEME_CHAR_STR_VAL}} 将字符串提取为 @cpp{mzchar*}；字符串始终以 nul 结尾，但也可能包含嵌入的 nul 字符，且修改此字符串会修改 Racket 字符串；@cppdef{SCHEME_CHAR_STRLEN_VAL} 提取字符串长度（以字符为单位，不包括 nul 终止符）；使用 @cppdef{SCHEME_CHAR_STRINGP} 测试此类型}

 @item{@cppdef{scheme_byte_string_type} —— @cppdef{SCHEME_BYTE_STR_VAL} 将字符串提取为 @cpp{char*}；字符串始终以 nul 结尾，但也可能包含嵌入的 nul 字符，且修改此字符串会修改 Racket 字符串；@cppdef{SCHEME_BYTE_STRLEN_VAL} 提取字符串长度（以字节为单位，不包括 nul 终止符）；使用 @cppdef{SCHEME_BYTE_STRINGP} 测试此类型}

 @item{@cppdef{scheme_path_type} —— @index['("strings" "conversion to C")] @cppdef{SCHEME_PATH_VAL} 将路径提取为 @cpp{char*}；字符串始终以 nul 结尾；@cppdef{SCHEME_PATH_LEN} 提取路径长度（以字节为单位，不包括 nul 终止符）；使用 @cppdef{SCHEME_PATHP} 测试此类型}

 @item{@cppdef{scheme_symbol_type} —— @cppdef{SCHEME_SYM_VAL} 将符号的字符串提取为 @cpp{char*} UTF-8 编码（请勿修改此字符串）；@cppdef{SCHEME_SYM_LEN} 提取符号名中的字节数（不包括 nul 终止符）；使用 @cppdef{SCHEME_SYMBOLP} 测试此类型；3m：有关 @cppi{SCHEME_SYM_VAL} 的注意事项，请参见 @secref["im:3m"]}

 @item{@cppdef{scheme_keyword_type} —— @cppdef{SCHEME_KEYWORD_VAL} 将关键字字符串（不含前导井号冒号）提取为 @cpp{char*} UTF-8 编码（请勿修改此字符串）；@cppdef{SCHEME_KEYWORD_LEN} 提取关键字名中的字节数（不包括 nul 终止符）；使用 @cppdef{SCHEME_KEYWORDP} 测试此类型；3m：有关 @cppi{SCHEME_KEYWORD_VAL} 的注意事项，请参见 @secref["im:3m"]}

 @item{@cppdef{scheme_box_type} —— @cppdef{SCHEME_BOX_VAL} 提取/设置装箱值；使用 @cppdef{SCHEME_BOXP} 测试此类型}

 @item{@cppdef{scheme_pair_type} —— @cppdef{SCHEME_CAR} 提取/设置 @racket[car]，@cppdef{SCHEME_CDR} 提取/设置 @racket[cdr]；使用 @cppdef{SCHEME_PAIRP} 测试此类型}

 @item{@cppdef{scheme_mutable_pair_type} —— @cppdef{SCHEME_MCAR} 提取/设置 @racket[mcar]，@cppdef{SCHEME_MCDR} 提取/设置 @racket[mcdr]；使用 @cppdef{SCHEME_MPAIRP} 测试此类型}

 @item{@cppdef{scheme_vector_type} —— @cppdef{SCHEME_VEC_SIZE} 提取长度，@cppdef{SCHEME_VEC_ELS} 提取 Racket 值数组（修改此数组会修改 Racket vector）；使用 @cppdef{SCHEME_VECTORP} 测试此类型；3m：有关 @cppi{SCHEME_VEC_ELS} 的注意事项，请参见 @secref["im:3m"]}

 @item{@cppdef{scheme_flvector_type} —— @cppdef{SCHEME_FLVEC_SIZE} 提取长度，@cppdef{SCHEME_FLVEC_ELS} 提取 @cpp{double} 数组；使用 @cppdef{SCHEME_FLVECTORP} 测试此类型；3m：有关 @cppi{SCHEME_FLVEC_ELS} 的注意事项，请参见 @secref["im:3m"]}

 @item{@cppdef{scheme_fxvector_type} —— 使用与 @cpp{scheme_vector_type} 相同的表示形式，因此用 @cpp{SCHEME_VEC_SIZE} 获取长度，用 @cpp{SCHEME_VEC_ELS} 获取 Racket fixnum 值数组；使用 @cppdef{SCHEME_FXVECTORP} 测试此类型；3m：有关 @cppi{SCHEME_VEC_ELS} 的注意事项，请参见 @secref["im:3m"]}

 @item{@cppdef{scheme_structure_type} —— struct 实例；使用 @cppdef{SCHEME_STRUCTP} 测试此类型}

 @item{@cppdef{scheme_struct_type_type} —— struct 类型；使用 @cppdef{SCHEME_STRUCT_TYPEP} 测试此类型}

 @item{@cppdef{scheme_struct_property_type} —— struct 类型属性}

 @item{@cppdef{scheme_input_port_type} —— @cppdef{SCHEME_INPORT_VAL} 提取/设置用户数据指针；使用 @cppdef{SCHEME_INPORTP} 仅测试此类型，但使用 @cppdef{SCHEME_INPUT_PORTP} 识别所有输入端口（包括具有 @racket[prop:input-port] 属性的 struct），并使用 @cppi{scheme_input_port_record} 从通用输入端口中提取 @cppi{scheme_input_port_type} 值}

 @item{@cppdef{scheme_output_port_type} —— @cppdef{SCHEME_OUTPORT_VAL} 提取/设置用户数据指针；使用 @cppdef{SCHEME_OUTPORTP} 仅测试此类型，但使用 @cppdef{SCHEME_OUTPUT_PORTP} 识别所有输出端口（包括具有 @racket[prop:output-port] 属性的 struct），并使用 @cppi{scheme_output_port_record} 从通用输入端口中提取 @cppi{scheme_output_port_type} 值}

 @item{@cppdef{scheme_thread_type} —— 线程描述符；使用 @cppdef{SCHEME_THREADP} 测试此类型}

 @item{@cppdef{scheme_sema_type} —— 信号量；使用 @cppdef{SCHEME_SEMAP} 测试此类型}

 @item{@cppdef{scheme_hash_table_type} —— 使用 @cppdef{SCHEME_HASHTP} 测试此类型}

 @item{@cppdef{scheme_hash_tree_type} —— 使用 @cppdef{SCHEME_HASHTRP} 测试此类型}

 @item{@cppdef{scheme_bucket_table_type} —— 使用 @cppdef{SCHEME_BUCKTP} 测试此类型}

 @item{@cppdef{scheme_weak_box_type} —— 使用 @cppdef{SCHEME_WEAKP} 测试此类型；@cppdef{SCHEME_WEAK_PTR} 提取包含的对象，或在内容被回收后返回 @cpp{NULL}；不要设置 weak box 的内容}

 @item{@cppdef{scheme_namespace_type} —— namespace；使用 @cppdef{SCHEME_NAMESPACEP} 测试此类型}

 @item{@cppdef{scheme_cpointer_type} —— 带有类型描述 @cpp{Scheme_Object} 的 @|void-const| 指针；@cppdef{SCHEME_CPTR_VAL} 提取指针，@cppdef{SCHEME_CPTR_TYPE} 提取类型 tag 对象；使用 @cppdef{SCHEME_CPTRP} 测试此类型。当 tag 为 symbol、byte string、string 或 car 中持有其中之一的 pair 时，打印此类对象会使用该 tag。}

]

以下是 procedure 类型：

@itemize[

 @item{@cppdef{scheme_prim_type} —— 原始 procedure，可能带有数据元素}

 @item{@cppdef{scheme_closed_prim_type} —— 旧式原始 procedure，带有一个数据指针}

 @item{@cppdef{scheme_compiled_closure_type} —— Racket procedure}

 @item{@cppdef{scheme_cont_type} —— continuation}

 @item{@cppdef{scheme_escaping_cont_type} —— escape continuation}

 @item{@cppdef{scheme_case_closure_type} —— @racket[case-lambda] procedure}

 @item{@cppdef{scheme_native_closure_type} —— 带有 JIT 编译器生成的本地代码的 procedure}

]

谓词 @cppdef{SCHEME_PROCP} 对所有 procedure 类型返回 1，对其他任何类型返回 0。

以下是额外的数字谓词：

@itemize[

 @item{@cppdef{SCHEME_NUMBERP} —— 所有数值类型}

 @item{@cppdef{SCHEME_REALP} —— 所有非复数数值类型}

 @item{@cppdef{SCHEME_EXACT_INTEGERP} —— fixnum 和 bignum}

 @item{@cppdef{SCHEME_EXACT_REALP} —— fixnum、bignum 和有理数}

 @item{@cppdef{SCHEME_FLOATP} —— 单精度（启用时）和双精度 flonum}

]

@; ----------------------------------------------------------------------

@section{Global Constants}

共有六个全局常量：

@itemize[

 @item{@cppdef{scheme_null} —— 使用 @cppdef{SCHEME_NULLP} 测试此值}

 @item{@cppdef{scheme_eof} —— 使用 @cppdef{SCHEME_EOFP} 测试此值}

 @item{@cppdef{scheme_true}}

 @item{@cppdef{scheme_false} —— 使用 @cppdef{SCHEME_FALSEP} 测试此值；使用 @cppdef{SCHEME_TRUEP} 测试 @italic{非}此值}

 @item{@cppdef{scheme_void} —— 使用 @cppdef{SCHEME_VOIDP} 测试此值}

 @item{@cppdef{scheme_undefined}}

]

在某些嵌入上下文中，必须改用函数形式 @cppi{scheme_make_null} 等。

@; ----------------------------------------------------------------------

@section[#:tag "im:strings"]{Strings}

如 @secref["im:unicode"] 所述，Racket 字符是一个 Unicode 码点，由 @cpp{mzchar} 值表示，字符字符串是 @cpp{mzchar} 数组。Racket 还提供 byte string，它们是 @cpp{char} 数组。

对于字符字符串 @var{s}，@cpp{@cpp{SCHEME_CHAR_STR_VAL}(@var{s})} 产生指向 @cpp{mzchar} 的指针，而非 @cpp{char}。使用 @cpp{scheme_char_string_to_byte_string} 将字符字符串转换为其 UTF-8 编码的 byte string。对于 byte string @var{bs}，@cpp{@cpp{SCHEME_BYTE_STR_VAL}(@var{bs})} 产生指向 @cpp{char} 的指针。函数 @cpp{scheme_byte_string_to_char_string} 将 byte string 解码为 UTF-8 并产生字符字符串。函数 @cpp{scheme_char_string_to_byte_string_locale} 和 @cpp{scheme_byte_string_to_char_string_locale} 类似，但使用当前 locale 的编码而非 UTF-8。

如需对 UTF-8 编码进行更细粒度的控制，请使用 @cpp{scheme_utf8_decode} 和 @cpp{scheme_utf8_encode} 函数，它们将在 @secref["im:encodings"] 中描述。

@; ----------------------------------------------------------------------

@section{Value Functions}

@function[(Scheme_Object* scheme_make_null)]{

返回 @cppi{scheme_null}。
}

@function[(Scheme_Object* scheme_make_eof)]{

返回 @cppi{scheme_eof}。
}

@function[(Scheme_Object* scheme_make_true)]{

返回 @cppi{scheme_true}。
}

@function[(Scheme_Object* scheme_make_false)]{

返回 @cppi{scheme_false}。
}

@function[(Scheme_Object* scheme_make_void)]{

返回 @cppi{scheme_void}。
}

@function[(Scheme_Object* scheme_make_char
           [mzchar ch])]{

返回字符值。@var{ch} 值必须是合法的 Unicode 码点（例如，不能是代理对）。前 256 个字符由常量 Racket 值表示，其他字符则动态分配。}

@function[(Scheme_Object* scheme_make_char_or_null
           [mzchar ch])]{

类似于 @cpp{scheme_make_char}，但如果 @var{ch} 不是合法的 Unicode 码点，则结果为 @cpp{NULL}。}

@function[(Scheme_Object* scheme_make_character
           [mzchar ch])]{

返回字符值。这是一个宏，当 @var{ch} 小于 256 时直接访问常量字符数组。}

@function[(Scheme_Object* scheme_make_ascii_character
           [mzchar ch])]{

返回字符值，假设 @var{ch} 小于 256。（这是一个宏。）}

@function[(Scheme_Object* scheme_make_integer
           [intptr_t i])]{

返回整数值；@var{i} 必须能放入 fixnum。（这是一个宏。）}

@function[(Scheme_Object* scheme_make_integer_value
           [intptr_t i])]{

返回整数值。如果 @var{i} 不能放入 fixnum，则返回 bignum。}

@function[(Scheme_Object* scheme_make_integer_value_from_unsigned
           [uintptr_t i])]{

类似于 @cpp{scheme_make_integer_value}，但用于无符号整数。}

@function[(Scheme_Object* scheme_make_integer_value_from_long_long
           [mzlonglong i])]{

类似于 @cpp{scheme_make_integer_value}，但用于 @cpp{mzlonglong} 值（参见 @secref["im:intsize"]）。}

@function[(Scheme_Object* scheme_make_integer_value_from_unsigned_long_long
           [umzlonglong i])]{

类似于 @cpp{scheme_make_integer_value_from_long_long}，但用于无符号整数。}

@function[(Scheme_Object* scheme_make_integer_value_from_long_halves
           [uintptr_t hi]
           [uintptr_t lo])]{

给定有符号整数的高位和低位 @cpp{intptr_t}，创建一个大整数。注意，在 64 位平台上，当 @cpp{long long} 与 @cpp{intptr_t} 相同时，结果整数为 128 bit。（另见 @secref["im:intsize"]。）}

@function[(Scheme_Object* scheme_make_integer_value_from_unsigned_long_halves
           [uintptr_t hi]
           [uintptr_t lo])]{

给定无符号整数的高位和低位 @cpp{intptr_t}，创建一个大整数。注意，在 64 位平台上，当 @cpp{long long} 与 @cpp{intptr_t} 相同时，结果整数为 128 bit。}

@function[(int scheme_get_int_val
           [Scheme_Object* o]
           [intptr_t* i])]{

提取整数值。与 @cppi{SCHEME_INT_VAL} 宏不同，此过程会从 Racket bignum 中提取能放入 @cpp{intptr_t} 的整数。如果 @var{o} 能放入 @cpp{intptr_t}，则提取的整数放入 @var{*i} 并返回 1；否则返回 0，且 @var{*i} 保持不变。}

@function[(int scheme_get_unsigned_int_val
           [Scheme_Object* o]
           [uintptr_t* i])]{

类似于 @cpp{scheme_get_int_val}，但用于无符号整数。}

@function[(int scheme_get_long_long_val
           [Scheme_Object* o]
           [mzlonglong* i])]{

类似于 @cpp{scheme_get_int_val}，但用于 @cpp{mzlonglong} 值（参见 @secref["im:intsize"]）。}

@function[(int scheme_get_unsigned_long_long_val
           [Scheme_Object* o]
           [umzlonglong* i])]{

类似于 @cpp{scheme_get_int_val}，但用于无符号 @cpp{mzlonglong} 值（参见 @secref["im:intsize"]）。}

@function[(Scheme_Object* scheme_make_double
           [double d])]{

创建一个新的浮点值。}

@function[(Scheme_Object* scheme_make_float
           [float d])]{

创建一个新的单精度浮点值。此过程仅在 Racket 编译时启用单精度数字支持时才可用。}

@function[(double scheme_real_to_double
           [Scheme_Object* o])]{

将 Racket 实数转换为双精度浮点值。}

@function[(Scheme_Object* scheme_make_pair
           [Scheme_Object* carv]
           [Scheme_Object* cdrv])]{

创建一个 @racket[cons] pair。}

@function[(Scheme_Object* scheme_make_byte_string
           [char* bytes])]{

从以 nul 结尾的 C 字符串创建 Racket byte string。@var{bytes} 字符串会被复制。}

@function[(Scheme_Object* scheme_make_byte_string_without_copying
           [char* bytes])]{

类似于 @cpp{scheme_make_byte_string}，但字符串不会被复制。}

@function[(Scheme_Object* scheme_make_sized_byte_string
           [char* bytes]
           [intptr_t len]
           [int copy])]{

创建大小为 @var{len} 的 byte string 值。如果 @var{copy} 不为 0，则会复制 @var{bytes}。字符串 @var{bytes} 应包含 @var{len} 个字节；@var{bytes} 可以在任意位置包含 nul 字节，且如果 @var{copy} 非零，则无需以 nul 结尾。但是，如果 @var{len} 为负数，则使用 @var{bytes} 的 nul 结尾长度作为长度；如果 @var{copy} 为零，则 @var{bytes} 必须以 nul 结尾。}

@function[(Scheme_Object* scheme_make_sized_offset_byte_string
           [char* bytes]
           [intptr_t d]
           [intptr_t len]
           [int copy])]{

类似于 @cpp{scheme_make_sized_byte_string}，但 @var{len} 个字符从 @var{bytes} 中的位置 @var{d} 开始。如果 @var{d} 非零，则 @var{copy} 必须非零。}

@function[(Scheme_Object* scheme_alloc_byte_string
           [intptr_t size]
           [char fill])]{

分配一个新的 Racket byte string。}

@function[(Scheme_Object* scheme_append_byte_string
           [Scheme_Object* a]
           [Scheme_Object* b])]{

通过拼接两个给定的 byte string 来创建新的 byte string。}

@function[(Scheme_Object* scheme_make_locale_string
           [char* bytes])]{

从以 nul 结尾的 byte string（字符字符串的 locale 特定编码）创建 Racket 字符串；解码过程中会分配新字符串。此函数名称中的 ``locale'' 一词指的是 @var{bytes}，而非结果字符串（后者内部以 UCS-4 存储）。}

@function[(Scheme_Object* scheme_make_utf8_string
           [char* bytes])]{

从以 nul 结尾的 UTF-8 编码的 byte string 创建 Racket 字符串。解码过程中会分配新字符串。此函数名称中的 ``utf8'' 一词指的是 @var{bytes}，而非结果字符串（后者内部以 UCS-4 存储）。}

@function[(Scheme_Object* scheme_make_sized_utf8_string
           [char* bytes]
           [intptr_t len])]{

基于 @var{len} 个 UTF-8 编码字节创建字符串值（因此结果字符串最多为 @var{len} 个字符）。字符串 @var{bytes} 应至少包含 @var{len} 个字节；@var{bytes} 可以在任意位置包含 nul 字节，且无需以 null 结尾。但是，如果 @var{len} 为负数，则使用 @var{bytes} 的 nul 结尾长度作为长度。}

@function[(Scheme_Object* scheme_make_sized_offset_utf8_string
           [char* bytes]
           [intptr_t d]
           [intptr_t len])]{

类似于 @cpp{scheme_make_sized_char_string}，但 @var{len} 个字符从 @var{bytes} 中的位置 @var{d} 开始。}


@function[(Scheme_Object* scheme_make_char_string
           [mzchar* chars])]{

从以 nul 结尾的 UCS-4 字符串创建 Racket 字符串。@var{chars} 字符串会被复制。}

@function[(Scheme_Object* scheme_make_char_string_without_copying
           [mzchar* chars])]{

类似于 @cpp{scheme_make_char_string}，但字符串不会被复制。}

@function[(Scheme_Object* scheme_make_sized_char_string
           [mzchar* chars]
           [intptr_t len]
           [int copy])]{

创建大小为 @var{len} 的字符串值。如果 @var{copy} 不为 0，则会复制 @var{chars}。字符串 @var{chars} 应包含 @var{len} 个字符；@var{chars} 可以在任意位置包含 nul 字符，且如果 @var{copy} 非零，则无需以 nul 结尾。但是，如果 @var{len} 为负数，则使用 @var{chars} 的 nul 结尾长度作为长度；如果 @var{copy} 为零，则 @var{chars} 必须以 nul 结尾。}

@function[(Scheme_Object* scheme_make_sized_offset_char_string
           [mzchar* chars]
           [intptr_t d]
           [intptr_t len]
           [int copy])]{

类似于 @cpp{scheme_make_sized_char_string}，但 @var{len} 个字符从 @var{chars} 中的位置 @var{d} 开始。如果 @var{d} 非零，则 @var{copy} 必须非零。}

@function[(Scheme_Object* scheme_alloc_char_string
           [intptr_t size]
           [mzchar fill])]{

分配一个新的 Racket 字符串。}

@function[(Scheme_Object* scheme_append_char_string
           [Scheme_Object* a]
           [Scheme_Object* b])]{

通过拼接两个给定的字符串来创建新字符串。}

@function[(Scheme_Object* scheme_char_string_to_byte_string
           [Scheme_Object* s])]{

通过 UTF-8 将 Racket 字符字符串转换为 Racket byte string。}

@function[(Scheme_Object* scheme_byte_string_to_char_string
           [Scheme_Object* s])]{

通过 UTF-8 将 Racket byte string 转换为 Racket 字符字符串。}

@function[(Scheme_Object* scheme_char_string_to_byte_string_locale
           [Scheme_Object* s])]{

通过 locale 编码将 Racket 字符字符串转换为 Racket byte string。}

@function[(Scheme_Object* scheme_byte_string_to_char_string_locale
           [Scheme_Object* s])]{

通过 locale 编码将 Racket byte string 转换为 Racket 字符字符串。}

@function[(Scheme_Object* scheme_intern_symbol
           [char* name])]{

查找（或创建）与给定的以 nul 结尾的 ASCII 字符串（非 UTF-8）匹配的 symbol。如果 @cppi{scheme_case_sensitive} 为 0，则在 intern 之前会（非破坏性地）规范化 @var{name} 的大小写。}

@function[(Scheme_Object* scheme_intern_exact_symbol
           [char* name]
           [int len])]{

给定以 UTF-8 编码字节表示的 symbol 长度，创建或查找一个 symbol。@var{name} 的大小写不会被规范化。}

@function[(Scheme_Object* scheme_intern_exact_char_symbol
           [mzchar* name]
           [int len])]{

类似于 @cpp{scheme_intern_exact_symbol}，但接受字符数组而非 UTF-8 编码的字节数组。}

@function[(Scheme_Object* scheme_make_symbol
           [char* name])]{

从以 nul 结尾的 UTF-8 编码字符串创建未 intern 的 symbol。大小写不会被规范化。}

@function[(Scheme_Object* scheme_make_exact_symbol
           [char* name]
           [int len])]{

给定以 UTF-8 编码字节表示的 symbol 长度，创建未 intern 的 symbol。}

@function[(Scheme_Object* scheme_intern_exact_keyword
           [char* name]
           [int len])]{

给定以 UTF-8 编码字节表示的 keyword 长度，创建或查找一个 keyword。@var{name} 的大小写不会被规范化，且不应包含 keyword 打印形式中的前导井号和冒号。}

@function[(Scheme_Object* scheme_intern_exact_char_keyword
           [mzchar* name]
           [int len])]{

类似于 @cpp{scheme_intern_exact_keyword}，但接受字符数组而非 UTF-8 编码的字节数组。}

@function[(Scheme_Object* scheme_make_vector
           [intptr_t size]
           [Scheme_Object* fill])]{

分配一个新的 vector。}

@function[(Scheme_Double_Vector* scheme_alloc_flvector
           [intptr_t size])]{

分配一个未初始化的 flvector。结果类型实际上是 @cpp{Scheme_Object*} 的别名。}

@function[(Scheme_Vector* scheme_alloc_fxvector
           [intptr_t size])]{

分配一个未初始化的 fxvector。结果类型实际上是 @cpp{Scheme_Object*} 的别名。}

@function[(Scheme_Object* scheme_box
           [Scheme_Object* v])]{

创建一个包含值 @var{v} 的新 box。}

@function[(Scheme_Object* scheme_make_weak_box
           [Scheme_Object* v])]{

创建一个包含值 @var{v} 的新 weak box。}

@function[(Scheme_Type scheme_make_type
           [char* name])]{

创建一个新类型（不是 Racket 值）。该类型 tag 在所有 @|tech-place| 中都是有效的。}

@function[(Scheme_Object* scheme_make_cptr
           [void* ptr]
           [const-Scheme_Object* typetag])]{

创建一个 C 指针对象，封装 @var{ptr} 并使用 @var{typetag} 标识指针的类型。@cppi{SCHEME_CPTRP} 宏能识别由 @cpp{scheme_make_cptr} 创建的对象。@cppi{SCHEME_CPTR_VAL} 宏从 Racket 对象中提取原始的 @var{ptr}，@cppi{SCHEME_CPTR_TYPE} 提取类型 tag。@cppi{SCHEME_CPTR_OFFSETVAL} 宏对结果 Racket 对象返回 @cpp{0}。

@var{ptr} 可以指向由垃圾回收器管理的内存，也可以指向由其他内存管理器管理的内存。但要注意，不要保留一个指向已被另一个内存管理器释放的内存的 @var{ptr}，因为该内存范围稍后可能被垃圾回收器管理（此时 @var{ptr} 可能变成无效指针，导致垃圾回收器崩溃）。}

@function[(Scheme_Object* scheme_make_external_cptr
           [void* ptr]
           [const-Scheme_Object* typetag])]{

类似于 @cpp{scheme_make_cptr}，但 @var{ptr} 永远不会被视为引用垃圾回收器管理的内存。}

@function[(Scheme_Object* scheme_make_offset_cptr
           [void* ptr]
           [intptr_t offset]
           [const-Scheme_Object* typetag])]{

创建一个 C 指针对象，同时封装 @var{ptr} 和 @var{offset}。@cppi{SCHEME_CPTR_OFFSETVAL} 宏对结果 Racket 对象返回 @var{offset}（该宏也可用于更改 offset，因为它同样适用于没有 offset 的对象）。

@var{ptr} 可以指向由垃圾回收器管理的内存，也可以指向由其他内存管理器管理的内存；另见 @cpp{scheme_make_cptr}。}

@function[(Scheme_Object* scheme_make_offset_external_cptr
           [void* ptr]
           [intptr_t offset]
           [const-Scheme_Object* typetag])]{

类似于 @cpp{scheme_make_offset_cptr}，但 @var{ptr} 永远不会被视为引用垃圾回收器管理的内存。}


@function[(void scheme_set_type_printer
           [Scheme_Type type]
           [Scheme_Type_Printer printer])]{

安装一个 printer，用于打印（或 write 或 display）具有类型 tag @var{type} 的值。

@var{printer} 的类型定义如下：

@verbatim[#:indent 2]{
 typedef void (*Scheme_Type_Printer)(Scheme_Object *v, int dis,
                                     Scheme_Print_Params *pp);
}

这样的 printer 必须使用 @cppi{scheme_print_bytes} 和 @cppi{scheme_print_string} 打印值的表示形式。printer 的第一个参数 @var{v} 是要打印的值。第二个参数指示 @var{v} 是通过 @racket[write] 还是 @racket[display] 打印。最后一个参数将被传递给 @cppi{scheme_print_bytes} 或 @cppi{scheme_print_string} 以标识打印上下文。}

@function[(void scheme_print_bytes
           [Scheme_Print_Params* pp]
           [const-char* str]
           [int offset]
           [int len])]{

将 @var{str} 的内容——从 @var{offset} 开始，持续 @var{len} 个字节——写入由 @var{pp} 确定的打印上下文中。此函数供通过 @cpp{scheme_set_type_printer} 安装的 printer 使用。}

@function[(void scheme_print_string
           [Scheme_Print_Params* pp]
           [const-mzchar* str]
           [int offset]
           [int len])]{

将 @var{str} 的内容——从 @var{offset} 开始，持续 @var{len} 个字符——写入由 @var{pp} 确定的打印上下文中。此函数供通过 @cpp{scheme_set_type_printer} 安装的 printer 使用。}

@function[(void scheme_set_type_equality
           [Scheme_Type type]
           [Scheme_Equal_Proc equalp]
           [Scheme_Primary_Hash_Proc hash1]
           [Scheme_Secondary_Hash_Proc hash2])]{

为具有类型 tag @var{type} 的值安装相等谓词及关联的哈希函数。@var{equalp} 谓词仅应用于两者都具有 tag @var{type} 的值。

@var{equalp}、@var{hash1} 和 @var{hash2} 的类型定义如下：

@verbatim[#:indent 2]{
 typedef int (*Scheme_Equal_Proc)(Scheme_Object* obj1,
                                  Scheme_Object* obj2,
                                  void* cycle_data);
 typedef intptr_t (*Scheme_Primary_Hash_Proc)(Scheme_Object* obj, 
                                          intptr_t base,
                                          void* cycle_data);
 typedef intptr_t (*Scheme_Secondary_Hash_Proc)(Scheme_Object* obj,
                                           void* cycle_data);
}

这两个哈希函数用于为基于 @racket[equal?] 的 hash table 生成 double hashing 的主键和次键。主键函数的结果应同时依赖于 @var{obj} 和 @var{base}。

每种情况下的 @var{cycle_data} 参数允许对循环值进行检查和哈希。它旨在通过 @cpp{scheme_recur_equal}、@cpp{scheme_recur_equal_hash_key} 和 @cpp{scheme_recur_equal_hash_key} 进行递归检查或哈希。也就是说，不要对给定值的子元素调用普通的 @cpp{scheme_equal}、@cpp{scheme_equal_hash_key} 或 @cpp{scheme_equal_hash_key} 来进行递归检查或哈希。}


