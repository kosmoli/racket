#lang scribble/doc
@(require "utils.rkt")

@cs-title[#:tag "cs-start"]{启动和声明初始模块}

如 @secref["cs-embedding"] 中概述，Racket CS 的嵌入式实例通过 @cppi{racket_boot} 启动。@cppi{racket_embedded_load_bytes} 等函数有助于用已编译的模块初始化 Racket 命名空间。

对于包含 @cpp{char*} 形式路径的函数和结构体字段，在 Windows 上将路径视为 UTF-8 编码。

@section[#:tag "cs-boot-arguments"]{启动和配置}

@function[(void racket_boot [racket_boot_arguments_t* boot_args])]{

初始化 Racket CS 实例。创建一个主线程，然后挂起等待通过 @cppi{racket_apply}、@cppi{racket_eval} 及类似函数进行后续求值。

@cpp{racket_boot_arguments_t} 结构体包含字段，用于指定 @cppi{racket_boot} 应如何初始化 Racket 实例。未来可能添加新字段，但在这种情况下，字段的 @cpp{0} 或 @cpp{NULL} 值将采用向后兼容的默认值。

@cppdef{racket_boot_arguments_t} 的字段：

@itemlist[

 @item{@cpp{const char *} @cppdef{boot1_path} --- 包含具有基础功能的 Chez Scheme 镜像文件的文件路径。通常，该文件名为 @filepath{petite.boot}。路径应包含目录分隔符，否则 Chez Scheme 将查询其自身的搜索路径。@cpp{racket_get_self_exe_path} 和/或 @cpp{racket_path_replace_filename} 函数可能有助于构建路径。}

 @item{@cpp{void *} @cppdef{boot1_data} --- @cpp{boot1_path} 的替代项，指向内存中 boot 文件内容的指针。使用此字段时，@cpp{boot1_len} 字段必须提供非零值。@cpp{boot1_path} 和 @cpp{boot1_data} 中只能有一个为非 @cpp{NULL}。

       @history[#:added "8.13.0.4"]}

 @item{@cpp{long} @cppdef{boot1_offset} --- 进入 @cpp{boot1_path} 或 @cpp{boot1_data} 读取第一个 boot image 的偏移量，允许将 boot image 与其他数据组合在单个文件中。按原样分发的 image 是自终止的，因此不需要大小或结束偏移量（除非通过 @cpp{boot1_data} 提供时，@cpp{boot1_len} 必须至少与 image 一样大）。}

 @item{@cpp{long} @cppdef{boot1_len} --- 第一个 boot image 的字节长度，可选；当通过 @cpp{boot1_path} 提供 boot image 时用作提示（如果非零）。如果提供了此长度，则必须至少为 boot image 的字节数，且不得大于文件大小或 boot image 偏移量后的可读内存。}

 @item{@cpp{const char *} @cppdef{boot2_path} --- 类似于 @cpp{boot1_path}，但用于包含编译器功能的 image，通常称为 @filepath{scheme.boot}。}

 @item{@cpp{void *} @cppdef{boot2_data} --- 类似于 @cpp{boot1_data}，但作为 @cpp{boot2_path} 的替代项。使用此字段时，必须提供非零的 @cpp{boot2_len} 字段。

       @history[#:added "8.13.0.4"]}

 @item{@cpp{long} @cppdef{boot2_offset} --- 类似于 @cpp{boot1_offset}，进入 @cpp{boot2_path} 或 @cpp{boot2_data} 读取第二个 boot image 的偏移量。}

 @item{@cpp{long} @cppdef{boot2_len} --- 类似于 @cpp{boot1_len}，第二个 boot image 的字节长度，当通过 @cpp{boot2_path} 提供时为可选。}

 @item{@cpp{const char *} @cppdef{boot3_path} --- 类似于 @cpp{boot1_path}，但用于包含 Racket 功能的 image，通常称为 @filepath{racket.boot}。}

 @item{@cpp{void *} @cppdef{boot3_data} --- 类似于 @cpp{boot1_data}，但作为 @cpp{boot3_path} 的替代项。使用此字段时，必须提供非零的 @cpp{boot3_len} 字段。

       @history[#:added "8.13.0.4"]}

 @item{@cpp{long} @cppdef{boot3_offset} --- 类似于 @cpp{boot1_offset}，进入 @cpp{boot2_path} 或 @cpp{boot3_path} 读取第三个 boot image 的偏移量。}

 @item{@cpp{long} @cppdef{boot3_len} --- 类似于 @cpp{boot1_len}，第三个 boot image 的字节长度，当通过 @cpp{boot3_path} 提供时为可选。}

 @item{@cpp{int} @cpp{argc} 和 @cpp{char **} @cpp{argv} --- 以与独立 @exec{racket} 调用相同方式处理的 command-line 参数。如果 @cpp{argv} 为 @cpp{NULL}，则使用命令行 @exec{-n}，这将加载 boot 文件而不执行任何进一步操作。}

  @item{@cpp{const char *} @cppdef{exec_file} --- 用于 @racket[(system-type 'exec-file)] 的路径，通常使用传递给程序 @cpp{main} 的 @cpp{argv[0]}。此字段不得为 @cpp{NULL}。}

  @item{@cpp{const char *} @cppdef{run_file} --- 用于 @racket[(system-type 'run-file)] 的路径。如果此字段为 @cpp{NULL}，则使用 @cppi{exec_file} 的值。}

  @item{@cpp{const char *} @cppdef{collects_dir} --- 用作主 @filepath{collects} 目录以定位 library collection 的路径。如果此字段保持 @cpp{NULL} 或 @cpp{""}，则 library-collection 搜索路径初始化为空。}

  @item{@cpp{const char *} @cppdef{config_dir} --- 用作 @filepath{etc} 目录的路径，包含配置信息，包括已安装的 package 信息。如果值为 @cpp{NULL}，则使用 @cpp{"etc"}。}

  @item{@cpp{wchar_t *} @cppdef{dll_dir} --- 用于查找 DLL（例如 @exec{iconv} 支持）的路径。注意，此路径使用宽字符，不是 UTF-8 字节编码。}

  @item{@cpp{int} @cppdef{cs_compiled_subdir} --- true 值表示应将 @racket[use-compiled-file-paths] 参数初始化为 @filepath{compiled} 的平台特定子目录，用于覆盖 Racket BC 安装的 Racket CS 安装。}

]}

@; ----------------------------------------------------------------------

@section[#:tag "cs-embedded-load"]{Loading Racket Modules}

@together[(
@function[(void racket_embedded_load_bytes [const-char* code] [uptr len] [int as_predefined])]
@function[(void racket_embedded_load_file [const-char* path] [int as_predefined])]
@function[(void racket_embedded_load_file_region [const-char* path] [uptr start] [uptr end] [int as_predefined])]
)]{

These functions evaluate Racket code, either in memory as @var{code}
or loaded from @var{path}, in the initial Racket thread. The intent is
that the code is already compiled. Normally, also, the contains module
declarations. The @seclink["c-mods" #:doc raco-doc]{@exec{raco ctool
--c-mods}} and @seclink["c-mods" #:doc raco-doc]{@exec{raco ctool
--mods}} commands generate code suitable for loading with these
functions, and @DFlag{c-mods} mode generates C code that calls
@cppi{racket_embedded_load_bytes}.

If @var{as_predefined} is true, then the code is loaded during the
creation of any new Racket @tech[#:doc reference-doc]{place} in the
new place, so that modules declared by the code are loaded in the new
place, too.

These functions are not meant to be called in C code that was called
from Racket. See also @secref["cs-procs"] for a discussion of
@emph{entry} points versus @emph{re-entry} points.}

@; ----------------------------------------------------------------------

@section[#:tag "cs-self-exe"]{Startup Path Helpers}

@function[(char* racket_get_self_exe_path [const-char* argv0])]{

Returns a path to the current process's executable. The @var{argv0}
argument should be the executable name delivered to @cpp{main}, which
may or may not be used depending on the operating system and
environment. The result is a string that is freshly allocated with
@cpp{malloc}, and it will be an absolute path unless all attempts to
find an absolute path fail.

On Windows, the @var{argv0} argument is always ignored, and the result
path is UTF-8 encoded.

@history[#:added "8.7.0.11"]}


@function[(char* racket_path_replace_filename [const-char* path] [const-char* new_filename])]{

Returns a path like @var{path}, but with the filename path replaced by
@var{new_filename}. The @var{new_filename} argument does not have to
be an immediate filename; it can be relative path that ends in a
filename. The result is a string that is freshly allocated with
@cpp{malloc}.

@history[#:added "8.7.0.11"]}
