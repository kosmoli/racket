#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "im:env"]{Namespaces 和 Modules}

Racket 的 namespace（顶层环境）由一个 @cppi{Scheme_Env*} 类型的值表示——
这也是一个 Racket value，可强制转换为 @cpp{Scheme_Object*}。调用
@cppi{scheme_basic_env} 会返回一个包含 Racket 所有标准全局 procedure
和 syntax 的 namespace。

@cpp{scheme_basic_env} 函数必须在嵌入程序中、在任何其他 Racket 函数调用之前
调用一次（@cpp{scheme_make_param} 除外），但 @cpp{scheme_main_setup}
会自动调用 @cpp{scheme_basic_env}。返回的 namespace 是主 Racket 线程的
初始当前 namespace。Racket 扩展不能调用 @cpp{scheme_basic_env}。

当前线程的当前 namespace 可从 @cppi{scheme_get_env} 获取，传入当前
parameterization（参见 @secref["config"]）：
@cpp{scheme_get_env(scheme_config)}。

新值可以作为 @as-index{namespace 中的 globals} 使用 @cppi{scheme_add_global}
添加。@cppi{scheme_lookup_global} 函数接收一个 Racket symbol 并返回该名称的
全局值，如果 symbol 未定义则返回 @cpp{NULL}。

@as-index{module} 的顶层 binding 集合使用与 namespace 相同的机制实现。
使用 @cppi{scheme_primitive_module} 创建一个代表 primitive module 的
新 @cpp{Scheme_Env*}。传给 @cppi{scheme_primitive_module} 的名称受
@racket[current-module-declare-name] parameter 的影响（当自动加载 module 文件时，
该 parameter 通常由 module name resolver 设置）。在用 @cppi{scheme_add_global}
等将变量安装到 module 中后，对 @cpp{Scheme_Env*} 值调用
@cppi{scheme_finish_primitive_module} 以使 module 声明可用。所有已定义的
变量都会从 primitive module 中导出。

Racket 的 @indexed-racket[#%variable-reference] 形式产生一个对 Racket code
不透明的值。对 @racket[#%variable-reference] 的结果使用 @cpp{SCHEME_PTR_VAL}
可获得与 @cpp{scheme_global_bucket} 返回的相同类型的值（即包含变量值的
bucket，如果变量尚未定义则为 @cpp{NULL}）。

@; ----------------------------------------------------------------------

@function[(void scheme_add_global
           [char* name]
           [Scheme_Object* val]
           [Scheme_Env* env])]{

向 namespace @var{env} 的 globals 表中添加一个值，其中 @var{name} 是一个
null-terminated 字符串。（字符串的大小写将以规范化 symbol 时相同的方式被规范化。）}

@function[(void scheme_add_global_symbol
           [Scheme_Object* name]
           [Scheme_Object* val]
           [Scheme_Env* env])]{

通过 symbol name 而非 string name 向 globals 表中添加一个值。}

@function[(Scheme_Object* scheme_lookup_global
           [Scheme_Object* symbol]
           [Scheme_Env* env])]{

给定 @var{sym} 中的全局变量名称（作为 symbol），返回当前值。}

@function[(Scheme_Bucket* scheme_global_bucket
           [Scheme_Object* symbol]
           [Scheme_Env* env])]{

给定 @var{sym} 中的全局变量名称（作为 symbol），返回存储该值的 bucket。
当此 bucket 中的值为 @cpp{NULL} 时，全局变量是未定义的。

@cppi{Scheme_Bucket} 结构体定义为：

@verbatim[#:indent 2]{
  typedef struct Scheme_Bucket {
    Scheme_Object so; /* so.type = scheme_variable_type */
    void *key;
    void *val;
  } Scheme_Bucket;
}}

@function[(Scheme_Bucket* scheme_module_bucket
           [Scheme_Object* mod]
           [Scheme_Object* symbol]
           [int pos]
           [Scheme_Env* env])]{

类似于 @cpp{scheme_global_bucket}，但在 module 中查找变量。@var{mod} 和
@var{symbol} 参数与 Racket 中的 @racket[dynamic-require] 相同。@var{pos}
参数应始终为 @cpp{-1}。@var{env} 参数表示 module 在其中声明的 namespace。}

@function[(void scheme_set_global_bucket
           [char* procname]
           [Scheme_Bucket* var]
           [Scheme_Object* val]
           [int set_undef])]{

改变全局变量的值。@var{procname} 参数用于报告错误（如果全局变量是常量、
尚未绑定或绑定为 syntax）。如果 @var{set_undef} 不是 1，则全局变量必须
已有绑定。（例如，@racket[set!] 不能设置未绑定的变量，而 @racket[define] 可以。）}

@function[(Scheme_Object* scheme_builtin_value
           [const-char* name])]{

获取一个名称在初始 namespace 中定义时所具有的 binding。}

@function[(Scheme_Env* scheme_get_env
           [Scheme_Config* config])]{

返回给定 parameterization 的当前 namespace（参见 @secref["config"]）。
当前线程的当前 parameterization 可作为 @cppi{scheme_config} 使用。}

@function[(Scheme_Env* scheme_primitive_module
           [Scheme_Object* name]
           [Scheme_Env* for_env])]{

准备一个新的 primitive module，其名称为 symbol @var{name}（或当前通过
@racket[current-module-declare-name] 活动的替代名称）。该 module 将在
namespace @var{for_env} 中声明。结果是一个 @cpp{Scheme_Env*} value，
可与 @cpp{scheme_add_global} 等一起使用，但它代表一个 module 而非 namespace。
在调用 @cpp{scheme_finish_primitive_module} 之前，module 不会被完全声明，
此时 module 中定义的所有变量都会变为导出。}

@function[(void scheme_finish_primitive_module
           [Scheme_Env* env])]{

完成一个 primitive module 并使其可在 module 的 namespace 中使用。}
