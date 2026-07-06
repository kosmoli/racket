#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/global))

@bc-title[#:tag "Miscellaneous Utilities"]{杂项工具}

@cppi{MZSCHEME_VERSION} 预处理器宏被定义为描述 Racket 版本的字符串。@cppi{MZSCHEME_VERSION_MAJOR} 和 @cppi{MZSCHEME_VERSION_MINOR} 宏分别定义为主版本号和次版本号。

@function[(int scheme_eq
           [Scheme_Object* obj1]
           [Scheme_Object* obj2])]{

如果 Scheme 值是 @racket[eq?]，则返回 1。}

@function[(int scheme_eqv
           [Scheme_Object* obj1]
           [Scheme_Object* obj2])]{

如果 Scheme 值是 @racket[eqv?]，则返回 1。}

@function[(int scheme_equal
           [Scheme_Object* obj1]
           [Scheme_Object* obj2])]{

如果 Scheme 值是 @racket[equal?]，则返回 1。}

@function[(int scheme_recur_equal
           [Scheme_Object* obj1]
           [Scheme_Object* obj2]
           [void* cycle_data])]{

类似于 @cpp{scheme_equal}，但接受额外的值用于 cycle tracking。此过程应由使用 @cpp{scheme_set_type_equality} 安装的过程调用。}

@function[(intptr_t scheme_equal_hash_key
           [Scheme_Object* obj])]{

返回 @var{obj} 的主 @racket[equal?]-hash key。}

@function[(intptr_t scheme_equal_hash_key2
           [Scheme_Object* obj])]{

返回 @var{obj} 的次 @racket[equal?]-hash key。}

@function[(intptr_t scheme_recur_equal_hash_key
           [Scheme_Object* obj]
           [void* cycle_data])]{

类似于 @cpp{scheme_equal_hash_key}，但接受额外的值用于 cycle tracking。此过程应由使用 @cpp{scheme_set_type_equality} 安装的哈希过程调用。}

@function[(intptr_t scheme_recur_equal_hash_key2
           [Scheme_Object* obj]
           [void* cycle_data])]{

类似于 @cpp{scheme_equal_hash_key2}，但接受额外的值用于 cycle tracking。此过程应由使用 @cpp{scheme_set_type_equality} 安装的次哈希过程调用。}

@function[(Scheme_Object* scheme_build_list
           [int c]
           [Scheme_Object** elems])]{

创建并返回长度为 @var{c} 的 list，元素为 @var{elems}。}

@function[(int scheme_list_length
           [Scheme_Object* list])]{

返回 list 的长度。如果 @var{list} 不是 proper list，则最后一个 @racket[cdr] 计为一项。如果 @var{list} 中存在循环（仅涉及 @racket[cdr]），此过程将不会终止。}

@function[(int scheme_proper_list_length
           [Scheme_Object* list])]{

返回 list 的长度，如果不是 proper list 则返回 -1。如果 @var{list} 中存在循环（仅涉及 @racket[cdr]），此过程返回 -1。}

@function[(Scheme_Object* scheme_car
           [Scheme_Object* pair])]{

返回 pair 的 @racket[car]。}

@function[(Scheme_Object* scheme_cdr
           [Scheme_Object* pair])]{

返回 pair 的 @racket[cdr]。}

@function[(Scheme_Object* scheme_cadr
           [Scheme_Object* pair])]{

返回 pair 的 @racket[cadr]。}

@function[(Scheme_Object* scheme_caddr
           [Scheme_Object* pair])]{

返回 pair 的 @racket[caddr]。}

@function[(Scheme_Object* scheme_vector_to_list
           [Scheme_Object* vec])]{

创建与给定 vector 具有相同元素的 list。}

@function[(Scheme_Object* scheme_list_to_vector
           [Scheme_Object* list])]{

创建与给定 list 具有相同元素的 vector。}

@function[(Scheme_Object* scheme_append
           [Scheme_Object* lstx]
           [Scheme_Object* lsty])]{

非破坏性地追加给定的 list。}

@function[(Scheme_Object* scheme_unbox
           [Scheme_Object* obj])]{

返回给定 box 的内容。}

@function[(void scheme_set_box
           [Scheme_Object* b]
           [Scheme_Object* v])]{

设置给定 box 的内容。}

@function[(Scheme_Object* scheme_dynamic_require
           [int argc]
           [Scheme_Object** argv])]{

与 @racket[dynamic-require] 相同。@var{argc} 参数必须为 @racket[2]，@var{argv} 包含参数。}

@function[(Scheme_Object* scheme_namespace_require
           [Scheme_Object* prim_req_spec])]{

与 @racket[namespace-require] 相同。}


@function[(Scheme_Object* scheme_load
           [char* file])]{

加载指定的 Racket 文件，返回最后一个加载表达式的值，如果加载失败则返回 @cpp{NULL}。}

@function[(Scheme_Object* scheme_load_extension
           [char* filename])]{

加载指定的 Racket 扩展文件，返回扩展初始化函数提供的值。}

@function[(Scheme_Hash_Table* scheme_make_hash_table
           [int type])]{

创建 hash table。@var{type} 参数必须为 @cppi{SCHEME_hash_ptr} 或 @cppi{SCHEME_hash_string}，决定 key 的比较方式（除非在 hash table record 中修改了 hash 和 compare 函数；见下文）。@cpp{SCHEME_hash_ptr} table 基于 key 的 pointer 地址进行哈希，而 @cpp{SCHEME_hash_string} 将 key 用作 @cpp{char*} 并基于 null 终止的字符串内容进行哈希。由于使用 @cpp{SCHEME_hash_string}（而非 @cpp{SCHEME_hash_ptr}）创建的 hash table 不使用 key 作为 Racket 值，因此不能从 Racket 代码中使用。

尽管 hash table interface 对 key 和 value 都使用 @cpp{Scheme_Object*} 类型，但 table 函数从不检查 value，仅对 @cpp{SCHEME_hash_string} 哈希检查 key。因此，value（以及 @cpp{SCHEME_hash_ptr} table 的 key）的实际类型可以是任意类型。

The public portion of the @cppi{Scheme_Hash_Table} type is defined
roughly as follows:

@verbatim[#:indent 2]{
  typedef struct Scheme_Hash_Table {
    Scheme_Object so; /* so.type == scheme_hash_table_type */
    /* ... */
    int size;  /* size of keys and vals arrays */
    int count; /* number of mapped keys */
    Scheme_Object **keys;
    Scheme_Object **vals;
    void (*make_hash_indices)(void *v, intptr_t *h1, intptr_t *h2);
    int (*compare)(void *v1, void *v2);
    /* ... */
  } Scheme_Hash_Table;
}

@cpp{make_hash_indices} 和 @cpp{compare} 函数指针可以设置为任意哈希和比较函数（在 table 中安装任何映射之前）。哈希函数应将 @var{h1} 填充为主哈希值，@var{h2} 填充为次哈希值；这些值用于 double-hashing，调用者取适当的模数。如果不需要相应的哈希码，@var{h1} 或 @var{h2} 可以为 @cpp{NULL}。

要遍历 hash table 内容，从 @cpp{0} 到 @cpp{size-1} 并行迭代 @var{keys} 和 @var{vals}，并忽略对应 @var{vals} 条目为 @cpp{NULL} 的 @var{keys}。@cpp{count} 字段指示将遇到的非 @cpp{NULL} 值的数量。}

@function[(Scheme_Hash_Table* scheme_make_hash_table_equal)]{

类似于 @cpp{scheme_make_hash_table}，但 key 被视为 Racket 值，基于 @racket[equal?] 而非 @racket[eq?] 进行哈希。}

@function[(void scheme_hash_set
           [Scheme_Hash_Table* table]
           [Scheme_Object* key]
           [Scheme_Object* val])]{

将 @var{table} 中 @var{key} 的当前值设置为 @var{val}。如果 @var{val} 为 @cpp{NULL}，则 @var{key} 在 @var{table} 中取消映射。}

@function[(Scheme_Object* scheme_hash_get
           [Scheme_Hash_Table* table]
           [Scheme_Object* key])]{

返回 @var{table} 中 @var{key} 的当前值，如果 @var{key} 没有值则返回 @cpp{NULL}。}


@function[(Scheme_Bucket_Table* scheme_make_bucket_table
           [int size_hint]
           [int type])]{

类似于 @cpp{make_hash_table}，但 bucket table 更灵活，因为 hash bucket 可访问且支持 weak key。（它们也比 hash table 消耗更多空间。）

@var{type} 参数必须为 @cppi{SCHEME_hash_ptr}、@cppi{SCHEME_hash_string} 或 @cppi{SCHEME_hash_weak_ptr}。前两个与 hash table 相同。最后一个类似于 @cpp{SCHEME_hash_ptr}，但 key 是弱引用的。

The public portion of the @cppi{Scheme_Bucket_Table} type is defined
roughly as follows:

@verbatim[#:indent 2]{
  typedef struct Scheme_Bucket_Table {
    Scheme_Object so; /* so.type == scheme_variable_type */
    /* ... */
    int size;  /* size of buckets array */
    int count; /* number of buckets, >= number of mapped keys */
    Scheme_Bucket **buckets;
    void (*make_hash_indices)(void *v, intptr_t *h1, intptr_t *h2);
    int (*compare)(void *v1, void *v2);
    /* ... */
  } Scheme_Bucket_Table;
}

@cpp{make_hash_indices} 和 @cpp{compare} 函数的使用方式与 hash table 相同。注意，即使更改了哈希和比较函数，作为初始类型提供的 @cppi{SCHEME_hash_weak_ptr} 也会使 key 保持弱引用。

有关 bucket 的信息，请参见 @cpp{scheme_bucket_from_table}。}

@function[(void scheme_add_to_table
           [Scheme_Bucket_Table* table]
           [const-char* key]
           [void* val]
           [int const])]{

将 @var{table} 中 @var{key} 的当前值设置为 @var{val}。如果 @var{const} 非零，则 @var{key} 的值绝不能更改。}

@function[(void scheme_change_in_table
           [Scheme_Bucket_Table* table]
           [const-char* key]
           [void* val])]{

将 @var{table} 中 @var{key} 的当前值设置为 @var{val}，但仅在 @var{key} 已在 table 中映射时。}

@function[(void* scheme_lookup_in_table
           [Scheme_Bucket_Table* table]
           [const-char* key])]{

Returns the current value for @var{key} in @var{table}, or @cpp{NULL}
 if @var{key} has no value.}

@function[(Scheme_Bucket* scheme_bucket_from_table
           [Scheme_Bucket_Table* table]
           [const-char* key])]{

返回 @var{table} 中 @var{key} 的 bucket。@cppi{Scheme_Bucket} 结构定义如下：

@verbatim[#:indent 2]{
  typedef struct Scheme_Bucket {
    Scheme_Object so; /* so.type == scheme_bucket_type */
    /* ... */
    void *key;
    void *val;
  } Scheme_Bucket;
}

将 @var{val} 设置为 @cpp{NULL} 会取消映射 bucket 的 key，此时 @var{key} 也可以为 @cpp{NULL}。如果 table 弱持有 key，则 @var{key} 指向实际 key 的（弱）指针，弱指针的值可以为 @cpp{NULL}。}

@function[(Scheme_Hash_Tree* scheme_make_hash_tree
                             [int type])]{
 Similar to @cpp{scheme_make_hash_table}, but creates a hash
 tree. A hash tree is equivalent to an immutable hash table
 created by @racket[hash]. The @var{type} argument must be
 either @cpp{SCHEME_hashtr_eq}, @cpp{SCHEME_hashtr_equal}, or @cpp{SCHEME_hashtr_eqv},
 which determines how keys are compared.}

@function[(void scheme_hash_tree_set
                [Scheme_Hash_Tree* table]
                [Scheme_Object* key]
                [Scheme_Object* val])]{
类似于 @cpp{scheme_hash_set}，但操作 @cpp{Scheme_Hash_Tree}。
}

@function[(Scheme_Object* scheme_hash_tree_get
                          [Scheme_Hash_Tree* table]
                          [Scheme_Object* key])]{
类似于 @cpp{scheme_hash_get}，但操作 @cpp{Scheme_Hash_Tree}。
}

@function[(intptr_t scheme_double_to_int
           [char* where]
           [double d])]{

返回给定浮点数 @var{d} 的 fixnum 值。如果 @var{d} 不是整数或太大，则报告错误消息；@var{name} 用于错误报告。}

@function[(intptr_t scheme_get_milliseconds)]{

Returns the current ``time'' in milliseconds, just like
@racket[current-milliseconds].}

@function[(intptr_t scheme_get_process_milliseconds)]{

Returns the current process ``time'' in milliseconds, just like
@racket[(current-process-milliseconds)].}

@function[(intptr_t scheme_get_process_children_milliseconds)]{
Returns the current process group ``time'' in milliseconds just like
@racket[(current-process-milliseconds 'subprocesses)].}

@function[(char* scheme_banner)]{

返回用作 Racket startup banner 的字符串。}

@function[(char* scheme_version)]{

返回正在执行的 Racket 版本的字符串。}

@function[(Scheme_Hash_Table* scheme_get_place_table)]{

返回当前 @|tech-place| 全局的基于 @racket[eq?] 的 hash table。

由 @cpp{scheme_malloc_key} 生成的 key 可用作多个 @|tech-place| 之间的通用 key。}

@function[(Scheme_Object* scheme_malloc_key)]{

生成可在 place 间使用的不可回收 Racket 值。使用 @cpp{scheme_free_key} 释放该值。}

@function[(void scheme_free_key [Scheme_Object* key])]{

释放由 @cpp{scheme_malloc_key} 分配的 key。释放 key 后，它不能从任何 place 中的任何 GC 遍历引用访问。}

@function[(void* scheme_register_process_global 
                 [const-char* key]
                 [void* val])]{

获取或设置 process-global table（即跨多个 place 共享，如果有）中的值。如果 @var{val} 为 @cpp{NULL}，则返回 @var{key} 的当前映射。如果 @var{val} 不为 @cpp{NULL} 且尚未为该 @var{key} 安装值，则安装该值并返回 @cpp{NULL}。如果已安装值，则不安装新值并返回旧值。给定的 @var{val} 不能引用垃圾回收内存。

此函数适用于少量 key 的不频繁使用。

另见 @racketmodname[ffi/unsafe/global] 中的 @racket[register-process-global]。}

@function[(void* scheme_jit_find_code_end
                 [void* p])]{

给定 Racket 编译器生成的机器代码的地址，尝试推断并返回生成代码末尾之后的地址（通常用于单个源函数）。如果无法推断地址，则结果为 @racket[#f]，这可能是因为给定的 @var{p} 不引用生成的机器代码。

@history[#:added "6.0.1.9"]}

@function[(void scheme_jit_now
                [Scheme_Object* val])]{

如果 @var{val} 是可以 JIT 编译的过程，则如果尚未强制 JIT 编译（通常通过调用函数），则立即强制进行。

@history[#:added "6.0.1.10"]}
