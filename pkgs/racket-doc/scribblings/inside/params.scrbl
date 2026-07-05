#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "config"]{Parameterization}

一个 @defterm{parameterization} 是一组 parameter 值。每个 thread 有自己的初始 parameterization，它被附加在特定 continuation mark 上的 parameterization 功能性地扩展和替代。

Parameterization 信息存储在 @cppi{Scheme_Config} 记录中。对于当前执行的 thread，@cppi{scheme_current_config} 返回当前的 parameterization。

为了获取 parameter 值，@cpp{Scheme_Config} 会与当前 thread 的 @cpp{Scheme_Thread_Cell_Table} 结合，该表存储在 thread 记录的 @cpp{cell_values} 字段中。

内置 parameter 值的获取和修改（对当前 thread）使用 @cppi{scheme_get_param} 和 @cppi{scheme_set_param}。每个 parameter 存储为 @cpp{Scheme_Object *} 值，内置 parameter 通过以下索引访问：

@itemize[
@item{@cppdef{MZCONFIG_ENV} --- @racket[current-namespace]（使用 @cpp{scheme_get_env}）}
@item{@cppdef{MZCONFIG_INPUT_PORT} --- @racket[current-input-port]}
@item{@cppdef{MZCONFIG_OUTPUT_PORT} ---  @racket[current-output-port]}
@item{@cppdef{MZCONFIG_ERROR_PORT} ---  @racket[current-error-port]}

@item{@cppdef{MZCONFIG_ERROR_DISPLAY_HANDLER} --- @racket[error-display-handler]}
@item{@cppdef{MZCONFIG_ERROR_PRINT_VALUE_HANDLER} --- @racket[error-value->string-handler]}

@item{@cppdef{MZCONFIG_EXIT_HANDLER} --- @racket[exit-handler]}

@item{@cppdef{MZCONFIG_INIT_EXN_HANDLER} ---  @racket[uncaught-exception-handler]}

@item{@cppdef{MZCONFIG_EVAL_HANDLER} --- @racket[current-eval]}
@item{@cppdef{MZCONFIG_LOAD_HANDLER} --- @racket[current-load]}

@item{@cppdef{MZCONFIG_PRINT_HANDLER} --- @racket[current-print]}
@item{@cppdef{MZCONFIG_PROMPT_READ_HANDLER} --- @racket[current-prompt-read]}

@item{@cppdef{MZCONFIG_CAN_READ_PIPE_QUOTE} --- @racket[read-accept-bar-quote]}

@item{@cppdef{MZCONFIG_PRINT_GRAPH} --- @racket[print-graph]}
@item{@cppdef{MZCONFIG_PRINT_STRUCT} --- @racket[print-struct]}
@item{@cppdef{MZCONFIG_PRINT_BOX} --- @racket[print-box]}

@item{@cppdef{MZCONFIG_CASE_SENS} --- @racket[read-case-sensitive]}
@item{@cppdef{MZCONFIG_SQUARE_BRACKETS_ARE_PARENS} --- @racket[read-square-brackets-as-parens]}
@item{@cppdef{MZCONFIG_CURLY_BRACES_ARE_PARENS} --- @racket[read-curly-braces-as-parens]}
@item{@cppdef{MZCONFIG_SQUARE_BRACKETS_ARE_TAGGED} --- @racket[read-square-brackets-with-tag]}
@item{@cppdef{MZCONFIG_CURLY_BRACES_ARE_TAGGED} --- @racket[read-curly-braces-with-tag]}

@item{@cppdef{MZCONFIG_ERROR_PRINT_WIDTH} --- @racket[error-print-width]}

@item{@cppdef{MZCONFIG_ALLOW_SET_UNDEFINED} --- @racket[allow-compile-set!-undefined]}

@item{@cppdef{MZCONFIG_CUSTODIAN} --- @racket[current-custodian]}

@item{@cppdef{MZCONFIG_USE_COMPILED_KIND} --- @racket[use-compiled-file-paths]}

@item{@cppdef{MZCONFIG_LOAD_DIRECTORY} --- @racket[current-load-relative-directory]}

@item{@cppdef{MZCONFIG_COLLECTION_PATHS} --- @racket[current-library-collection-paths]}

@item{@cppdef{MZCONFIG_PORT_PRINT_HANDLER} --- @racket[global-port-print-handler]}

@item{@cppdef{MZCONFIG_LOAD_EXTENSION_HANDLER} --- @racket[current-load-extension]}

]

要获取或设置当前 thread 以外的 parameter 值，使用 @cppi{scheme_get_thread_param} 和 @cppi{scheme_set_thread_param}，它们各自接受一个 @cpp{Scheme_Thread_Cell_Table} 用于解析或设置 parameter 值。

当使用 @cpp{scheme_set_param} 安装新 parameter 时，不会检查所提供的值是否为该 parameter 的合法值；这是 @cpp{scheme_set_param} 调用者的责任。注意，Boolean parameter 只能设置为 @racket[#t] 和 @racket[#f] 值。

新的 primitive parameter 索引使用 @cppi{scheme_new_param} 创建，并使用 @cppi{scheme_make_parameter} 和 @cppi{scheme_param_config} 实现。

@; ----------------------------------------------------------------------

@function[(Scheme_Object* scheme_get_param
           [Scheme_Config* config]
           [int param_id])]{

获取由 @var{param_id} 指定的 parameter 的当前值（对当前 thread）。}

@function[(Scheme_Object* scheme_set_param
           [Scheme_Config* config]
           [int param_id]
           [Scheme_Object* v])]{

设置由 @var{param_id} 指定的 parameter 的当前值（对当前 thread）。}

@function[(Scheme_Object* scheme_get_thread_param
           [Scheme_Config* config]
           [Scheme_Thread_Cell_Table* cells]
           [int param_id])]{

类似 @cpp{scheme_get_param}，但使用任意 thread 的 cell-value 表。}

@function[(Scheme_Object* scheme_set_thread_param
           [Scheme_Config* config]
           [Scheme_Thread_Cell_Table* cells]
           [int param_id]
           [Scheme_Object* v])]{

类似 @cpp{scheme_set_param}，但使用任意 thread 的 cell-value 表。}

@function[(Scheme_Object* scheme_extend_config
           [Scheme_Config* base]
           [int param_id]
           [Scheme_Object* v])]{

创建并返回一个 parameterization，为 @var{base} 添加新值 @var[v]（在所有 thread 中）用于 parameter @var[param_id]。使用 @cpp{scheme_install_config} 使此配置在当前 thread 中生效。}

@function[(void scheme_install_config
           [Scheme_Config* config])]{

调整当前 thread 的 continuation marks 以使 @var{config} 成为当前 parameterization。通常在 @cpp{scheme_push_continuation_frame} 之后调用此 function 以建立新的 continuation frame，之后调用 @cpp{scheme_pop_continuation_frame} 来移除 frame（以及 parameterization）。}

@function[(Scheme_Thread_Cell_Table* scheme_inherit_cells
           [Scheme_Thread_Cell_Table* cells])]{

创建一个新的 thread-cell-value 表，从 @var{cells} 复制保留的 thread cell 的值。}

@function[(int scheme_new_param)]{

分配一个新的 primitive parameter 索引。此 function 必须在 @cppi{scheme_basic_env} 之前调用，因此仅可用于 embedding 应用（即不用于 extension）。}

@function[(Scheme_Object* scheme_register_parameter
           [Scheme_Prim* function]
           [char* name]
           [int exnid])]{

使用此 function 而非其他 primitive-constructing function（如 @cpp{scheme_make_prim}）来创建 primitive parameter 过程。另见下面的 @cpp{scheme_param_config}。此 function 仅可用于 embedding 应用（即不用于 extension）。}

@function[(Scheme_Object* scheme_param_config
           [char* name]
           [Scheme_Object* param]
           [int argc]
           [Scheme_Object** argv]
           [int arity]
           [Scheme_Prim* check]
           [char* expected]
           [int isbool])]{

在 primitive parameter 过程中调用此过程来实现获取或设置 parameter 的工作。@var{name} 参数应为 parameter 过程名称；用于报告错误。@param 参数是一个对应于 @cpp{scheme_new_param} 返回的 primitive parameter 索引的 fixnum。@var{argc} 和 @var{argv} 参数应为传递给 primitive parameter 的未经处理和未经测试的参数。使用 @var{arity}、@var{check}、@var{expected} 和 @var{isbool} 在 @cpp{scheme_param_config} 内部执行参数检查：

@itemize[

 @item{如果 @var{arity} 非负，则潜在 parameter 值必须能接受指定数量的参数。@var{check} 和 @var{expected} 参数应为 @cpp{NULL}。}

 @item{如果 @var{check} 不是 @cpp{NULL}，则调用它来检查潜在 parameter 值。传递给 @var{check} 的参数始终是 @cpp{1} 和包含潜在 parameter 值的数组。如果 @var{isbool} 为 @cpp{0} 且 @var{check} 返回 @cpp{scheme_false}，则使用 @var{name} 和 @var{expected} 作为类型描述报告类型错误。如果 @var{isbool} 为 @cpp{1}，则仅在 @var{check} 返回 @cpp{NULL} 时报告类型错误，并且返回的任何非 @cpp{NULL} 值被用做实际存储的值。}

 @item{否则，@var{isbool} 应为 1。潜在过程参数被当做 Boolean 值对待。}

]

此 function 仅可用于 embedding 应用（即不用于 extension）。}

@function[(Scheme_Object* scheme_param_config2
           [char* name]
           [Scheme_Object* param]
           [int argc]
           [Scheme_Object** argv]
           [int arity]
           [Scheme_Prim* check]
           [char* expected_contract]
           [int isbool])]{

与 @cpp{scheme_param_config} 相同，但使用 @var{expected_contract} 作为 contract 而非类型描述。}
