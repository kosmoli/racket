#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "Structures"]{结构体}

一个新的 Racket structure type 通过
@cppi{scheme_make_struct_type} 创建。这会创建结构体类型，但不会生成
constructor 等 procedure。@cppi{scheme_make_struct_values} 函数接收一个
structure type 并创建这些 procedure。@cppi{scheme_make_struct_names} 函数
根据结构体名称生成标准的 structure procedure 名称。@cppi{scheme_make_struct_instance}
用于创建 structure type 的实例，@cppi{scheme_is_struct_instance} 函数
用于判断结构体的类型。@cppi{scheme_struct_ref} 和 @cppi{scheme_struct_set}
函数用于访问或修改结构体的字段。

由 @cpp{scheme_make_struct_values} 和 @cpp{scheme_make_struct_names} 生成的
procedure value 和名称可以通过传递以下 flag 组合来限制：

@itemize[

 @item{@cppi{SCHEME_STRUCT_NO_TYPE} --- 不返回 structure type 的
 value/name。}

 @item{@cppi{SCHEME_STRUCT_NO_CONSTR} --- 不返回 constructor procedure 的
 value/name。}

 @item{@cppi{SCHEME_STRUCT_NO_PRED} --- 不返回 predicate procedure 的
 value/name。}

 @item{@cppi{SCHEME_STRUCT_NO_GET} --- 不返回 selector procedure 的
 values/names。}

 @item{@cppi{SCHEME_STRUCT_NO_SET} --- 不返回 mutator procedure 的
 values/names。}

 @item{@cppi{SCHEME_STRUCT_GEN_GET} --- 返回字段无关的 selector procedure
 的 value/name。}

 @item{@cppi{SCHEME_STRUCT_GEN_SET} --- 返回字段无关的 mutator procedure
 的 value/name。}

 @item{@cppi{SCHEME_STRUCT_NO_MAKE_PREFIX} --- constructor 名称省略
 @racketidfont{make-} 前缀，类似 @racket[struct] 而不是
 @racket[define-struct]。}

]

当所有 values 或 names 都返回时，它们以数组形式返回，顺序为：
structure type、constructor、predicate、第一个 selector、第一个 mutator、
第二个 selector，依此类推，最后是字段无关的 selector 和字段无关的 mutator。
当省略某些 values/names 时，数组会相应压缩。

@; ----------------------------------------------------------------------

@function[(Scheme_Object* scheme_make_struct_type
           [Scheme_Object* base_name]
           [Scheme_Object* super_type]
           [Scheme_Object* inspector]
           [int num_init_fields]
           [int num_auto_fields]
           [Scheme_Object* auto_val]
           [Scheme_Object* properties]
           [Scheme_Object* guard])]{

创建并返回一个新的 structure type。@var{base_name} 参数用作新
structure type 的名称，必须是一个 symbol。@var{super_type} 参数应为
@cpp{NULL} 或一个用作父类型的已有 structure type。@var{inspector} 参数
应为 @cpp{NULL} 或用于管理该类型的 inspector。@var{num_init_fields} 参数
指定该 structure type 实例中具有对应 constructor 参数的字段数量。
（如果使用了父类型，这是额外字段的数量，而非总数。）
@var{num_auto_fields} 参数指定没有对应 constructor 参数的额外字段数量，
它们被初始化为 @var{auto_val}。@var{properties} 参数是一个 property-value
对列表。@var{guard} 参数为 @cpp{NULL} 或用作 constructor guard 的 procedure。}

@function[(Scheme_Object** scheme_make_struct_names
           [Scheme_Object* base_name]
           [Scheme_Object* field_names]
           [int flags]
           [int* count_out])]{

创建并返回一个包含标准 structure value 名称的 symbol 数组。
@var{base_name} 参数用作 structure type 的名称，应该是传递给关联
@cpp{scheme_make_struct_type} 调用的同一个 symbol。@var{field_names} 参数
是一个（Racket）字段名称 symbol 列表。@var{flags} 参数指定应生成哪些名称，
如果 @var{count_out} 不是 @cpp{NULL}，则 @var{count_out} 将被填充为数组中
返回的名称数量。}

@function[(Scheme_Object** scheme_make_struct_values
           [Scheme_Object* struct_type]
           [Scheme_Object** names]
           [int count]
           [int flags])]{

创建并返回一个包含 @var{struct_type} 的标准 structure value 和 procedure value
的数组。@var{struct_type} 参数必须是由 @cpp{scheme_make_struct_type} 创建的
structure type value。@var{names} 参数必须是一个名称 symbol 数组，通常是
@cpp{scheme_make_struct_names} 返回的数组。@var{count} 参数指定 @var{names}
数组的长度（即预期的返回值数量），@var{flags} 参数指定应生成哪些值。}

@function[(Scheme_Object* scheme_make_struct_instance
           [Scheme_Object* struct_type]
           [int argc]
           [Scheme_Object** argv])]{

创建 structure type @var{struct_type} 的一个实例。@var{argc} 和 @var{argv}
参数为新实例提供字段值。}

@function[(int scheme_is_struct_instance
           [Scheme_Object* struct_type]
           [Scheme_Object* v])]{

如果 @var{v} 是 @var{struct_type} 的实例则返回 1，否则返回 0。}

@function[(Scheme_Object* scheme_struct_ref
           [Scheme_Object* s]
           [int n])]{

返回结构体 @var{s} 的第 @var{n} 个字段（从 0 开始计数）。}

@function[(void scheme_struct_set
           [Scheme_Object* s]
           [int n]
           [Scheme_Object* v])]{

将结构体 @var{s} 的第 @var{n} 个字段（从 0 开始计数）设置为 @var{v}。}
