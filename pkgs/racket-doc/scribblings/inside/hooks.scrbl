#lang scribble/doc
@(require "utils.rkt")

@title{标志和 Hook}

以下标志和 hook 在嵌入 Racket 时可用：

@itemize[

 @item{@cppdef{scheme_exit} --- 此指针可以设置为一个函数，
 该函数接受整数参数并返回 @cpp{void}；该函数将用作默认的 exit handler。默认值为 @cpp{NULL}。}

 @item{@cppdef{scheme_make_stdin}, @cppdef{scheme_make_stdout},
 @cppdef{scheme_make_stderr}, --- 这些指针可以设置为一个函数，
 该函数无参数并返回一个 Racket port
 @cpp{Scheme_Object *}，用作初始标准输入、输出和/或错误 port。默认值为 @cpp{NULL}。
 设置初始错误 port 对于查看意外错误消息尤为重要，特别是当 @cpp{stderr} 输出无处可去时。}

 @item{@cppdef{scheme_console_output} --- 此指针可以设置为一个函数，
 该函数接受一个字符串和一个 @cpp{intptr_t} 字符串长度；
 该函数被调用以显示内部 Racket 警告和可能包含非终止 nul 的消息。默认值为
 @var{NULL}。}

 @item{@cppdef{scheme_check_for_break} --- 此指针指向一个函数，
 该函数无参数并返回整数。它被用作主线程中默认的 user-break 轮询过程。
 非零返回值表示 user break，每次函数返回非零值时都计为一个新的 break 信号
 （尽管前一个信号仍在处理中时可能会被忽略）。默认值为 @cpp{NULL}。}

 @item{@cppdef{scheme_case_sensitive} --- 如果此标志在调用 @cppi{scheme_basic_env} 前设置为非零值，则
 Racket 在 symbol 和全局变量名中不会忽略大小写。一旦设置，此标志的值不应更改。默认值为零。}

 @item{@cppdef{scheme_allow_set_undefined} --- 此标志确定
 @racket[compile-allow-set!-undefined] 的初始值。默认值为零。}

 @item{@cppdef{scheme_console_printf} --- 此函数指针为向后兼容而保留。
 默认值构建字符串并调用 @cppi{scheme_console_output}。}

]

@function[(void scheme_set_collects_path
           [Scheme_Object* path])]{

设置 @racket[(find-system-path 'collects-dir)] 返回的路径。}


@function[(void scheme_set_addon_path
           [Scheme_Object* path])]{

设置 @racket[(find-system-path 'addon-dir)] 返回的路径。}


@function[(void scheme_set_exec_cmd
                [const-char* path])]{

设置 @racket[(find-system-path 'exec-file)] 返回的路径。}


@function[(void scheme_init_collection_paths_post
           [Scheme_Env* env]
           [Scheme_Object* pre_extra_paths]
           [Scheme_Object* post_extra_paths])]{

使用 @racket[find-library-collection-paths] 初始化 @racket[current-library-collection-paths] parameter。
@var{pre_extra_paths} 和 @var{post_extra-paths} 参数被传递给 @racket[find-library-collection-paths]。

该函数自动调用 @cpp{scheme_seal_parameters}。}


@function[(void scheme_init_collection_paths
           [Scheme_Env* env]
           [Scheme_Object* pre_extra_paths])]{

类似于 @cpp{scheme_init_collection_paths_post}，但最后一个参数使用 @racket[null]。}


@function[(void scheme_set_dll_path
            [wchar_t* path])]{

仅 Windows 上有效，设置运行时系统查找可选 DLL 的路径：
@filepath{longdouble.dll} 和 @filepath{iconv.dll}、
@filepath{libiconv.dll} 或 @filepath{libiconv-2.dll} 之一。给定的 @var{path}
应为绝对路径。}


@function[(void scheme_seal_parameters)]{

获取当前内置 parameter 值的快照。这些值用于特权操作，如安装 @|PLaneT| 包。}
