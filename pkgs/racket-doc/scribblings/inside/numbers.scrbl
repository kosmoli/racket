#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "Bignums, Rationals, and Complex Numbers"]{大整数、有理数和复数}

Racket 支持任意大小的整数；当整数无法表示为 fixnum（即 30 或 62 位加符号位）时，则由 Racket 类型 @cppi{scheme_bignum_type} 表示。由 fixnum 和 bignum 表示的整数值没有重叠。

有理数由类型 @cppi{scheme_rational_type} 实现，由分子和分母组成。分子和分母将是 fixnum 或 bignum（可能混合）。

复数由类型 @cppi{scheme_complex_type} 实现，由实部和虚部组成。实部和虚部要么都是 flonum、要么都是精确数字（fixnum、bignum 和有理数可以任意混合），要么实部为精确 0 且虚部为单精度（如果启用）或双精度 flonum。


@function[(int scheme_is_exact
           [Scheme_Object* n])]{

如果 @var{n} 是精确数字，则返回 @cpp{1}，否则返回 @racket[0]（@var{n} 不必是数字）。}

@function[(int scheme_is_inexact
           [Scheme_Object* n])]{

如果 @var{n} 是不精确数字，则返回 @cpp{1}，否则返回 @racket[0]（@var{n} 不必是数字）。}

@function[(Scheme_Object* scheme_make_bignum
           [intptr_t v])]{

创建一个表示整数 @var{v} 的 bignum。这可以创建一个本可放入 fixnum 的 bignum。这只能用于创建与 @cpp{bignum} 函数一起使用的临时值。最终结果可以用 @cpp{scheme_bignum_normalize} 规范化。只有规范化的数字才能用于不特定于 bignum 的过程。}

@function[(Scheme_Object* scheme_make_bignum_from_unsigned
           [uintptr_t v])]{

类似于 @cpp{scheme_make_bignum}，但作用于无符号整数。}

@function[(double scheme_bignum_to_double
           [Scheme_Object* n])]{

将 bignum 转换为浮点数，精度合理但未明确指定。}

@function[(float scheme_bignum_to_float
           [Scheme_Object* n])]{

如果 Racket 未使用单精度浮点数编译，则此过程实际上是 @cpp{scheme_bignum_to_double} 的宏别名。}

@function[(Scheme_Object* scheme_bignum_from_double
           [double d])]{

创建一个大小接近浮点数 @var{d} 的 bignum。转换精度合理但未明确指定。}

@function[(Scheme_Object* scheme_bignum_from_float
           [float f])]{

如果 Racket 未使用单精度浮点数编译，则此过程实际上是 @cpp{scheme_bignum_from_double} 的宏别名。}

@function[(char* scheme_bignum_to_string
           [Scheme_Object* n]
           [int radix])]{

将 bignum 写入新分配的字节字符串。}

@function[(Scheme_Object* scheme_read_bignum
           [mzchar* str]
           [int offset]
           [int radix])]{

从 @cpp{mzchar} 字符串读取 bignum，从 @var{str} 中的位置 @var{offset} 开始。如果字符串不表示整数，则将返回 @cpp{NULL}。如果字符串表示适合 fixnum 的数字，则将返回 @cpp{scheme_integer_type} 对象。}

@function[(Scheme_Object* scheme_read_bignum_bytes
           [char* str]
           [int offset]
           [int radix])]{

类似于 @cpp{scheme_read_bignum}，但从 UTF-8 编码字节字符串读取。}

@function[(Scheme_Object* scheme_bignum_normalize
           [Scheme_Object* n])]{

如果 @var{n} 适合 fixnum，则将返回 @cpp{scheme_integer_type} 对象。否则返回 @var{n}。}

@function[(Scheme_Object* scheme_make_rational
           [Scheme_Object* n]
           [Scheme_Object* d])]{

从分子和分母创建有理数。@var{n} 和 @var{d} 参数必须是 fixnum 或 bignum（可能混合）。结果将被规范（因此可能返回 bignum 或 fixnum）。}

@function[(double scheme_rational_to_double
           [Scheme_Object* n])]{

将有理数 @var{n} 转换为 @cpp{double}。}

@function[(float scheme_rational_to_float
           [Scheme_Object* n])]{

如果 Racket 未使用单精度浮点数编译，则此过程实际上是 @cpp{scheme_rational_to_double} 的宏别名。}

@function[(Scheme_Object* scheme_rational_numerator
           [Scheme_Object* n])]{

返回有理数 @var{n} 的分子。}

@function[(Scheme_Object* scheme_rational_denominator
           [Scheme_Object* n])]{

返回有理数 @var{n} 的分母。}

@function[(Scheme_Object* scheme_rational_from_double
           [double d])]{

将给定的 @cpp{double} 转换为最高精度的有理数。}

@function[(Scheme_Object* scheme_rational_from_float
           [float d])]{

如果 Racket 未使用单精度浮点数编译，则此过程实际上是 @cpp{scheme_rational_from_double} 的宏别名。}

@function[(Scheme_Object* scheme_make_complex
           [Scheme_Object* r]
           [Scheme_Object* i])]{

从实部和虚部创建复数。@var{r} 和 @var{i} 参数必须是 fixnum、bignum、flonum 或有理数（可能混合）。结果将被规范化（因此可能返回实数）。}

@function[(Scheme_Object* scheme_complex_real_part
           [Scheme_Object* n])]{

返回复数 @var{n} 的实部。}

@function[(Scheme_Object* scheme_complex_imaginary_part
           [Scheme_Object* n])]{

返回复数 @var{n} 的虚部。}
