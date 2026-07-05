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

 @item{@cpp{const char *} @cppdef{boot1_path} --- a path to a file
       containing a Chez Scheme image file with base functionality.
       Normally, the file is called @filepath{petite.boot}. The path
       should contain a directory separator, otherwise Chez Scheme
       will consult its own search path. The
       @cpp{racket_get_self_exe_path} and/or
       @cpp{racket_path_replace_filename} functions may be helpful to
       construct the path.}

 @item{@cpp{void *} @cppdef{boot1_data} --- an alternative to
       @cpp{boot1_path}, a pointer to the boot file's content in
       memory. When using this field, the @cpp{boot1_len} field
       must be supplied as non-zero. Only one of @cpp{boot1_path} and
       @cpp{boot1_data} can be non-@cpp{NULL}.

       @history[#:added "8.13.0.4"]}

 @item{@cpp{long} @cppdef{boot1_offset} --- an offset into
       @cpp{boot1_path} or @cpp{boot1_data} to read for the first boot
       image, which allows boot images to be combined with other data
       in a single file. The image as distributed is self-terminating,
       so no size or ending offset is needed (except that
       @cpp{boot1_len} must be at least as large as the image when
       supplied via @cpp{boot1_data}).}

 @item{@cpp{long} @cppdef{boot1_len} --- an length in bytes for the
       first boot image, which is optional and used as a hint if
       non-zero when the boot image is supplied via @cpp{boot1_path}.
       If this length is provided, it must be at least as large as the
       boot image in bytes, and it must be no larger than the file
       size or readable memory after the boot image offset.}

 @item{@cpp{const char *} @cppdef{boot2_path} --- like
       @cpp{boot1_path}, but for the image that contains compiler
       functionality, normally called @filepath{scheme.boot}.}

 @item{@cpp{void *} @cppdef{boot2_data} --- like @cpp{boot1_data}, but
       an alternative to @cpp{boot2_path}. When using this field, the
       @cpp{boot2_len} field must be supplied as non-zero.

       @history[#:added "8.13.0.4"]}

 @item{@cpp{long} @cppdef{boot2_offset} --- like @cpp{boot1_offset},
       an offset into @cpp{boot2_path} or @cpp{boot2_data} to read for
       the second boot image.}

 @item{@cpp{long} @cppdef{boot2_len} --- like @cpp{boot1_len}, a
       length in bytes for the second boot image, optional when
       the boot image is supplied via @cpp{boot2_path}.}

 @item{@cpp{const char *} @cppdef{boot3_path} --- like
       @cpp{boot1_path}, but for the image that contains Racket
       functionality, normally called @filepath{racket.boot}.}

 @item{@cpp{void *} @cppdef{boot3_data} --- like @cpp{boot1_data}, but
       an alternative to @cpp{boot3_path}. When using this field, the
       @cpp{boot3_len} field must be supplied as non-zero.

       @history[#:added "8.13.0.4"]}

 @item{@cpp{long} @cppdef{boot3_offset} --- like @cpp{boot1_offset},
       an offset into @cpp{boot2_path} or @cpp{boot3_path} to read for
       the third boot image.}

 @item{@cpp{long} @cppdef{boot3_len} --- like @cpp{boot1_len}, a
       length in bytes for the third boot image, optional when
       the boot image is supplied via @cpp{boot3_path}.}

 @item{@cpp{int} @cpp{argc} and @cpp{char **} @cpp{argv} ---
       command-line arguments to be processed the same as for a
       stand-alone @exec{racket} invocation. If @var{argv} is
       @cpp{NULL}, the command line @exec{-n} is used, which loads
       boot files without taking any further action.}

  @item{@cpp{const char *} @cppdef{exec_file} --- a path to use for
       @racket[(system-type 'exec-file)], usually @cpp{argv[0]} using
       the @cpp{argv} delivered to a program's @cpp{main}. This
       field must not be @cpp{NULL}.}

  @item{@cpp{const char *} @cppdef{run_file} --- a path to use for
       @racket[(system-type 'run-file)]. If the field is @cpp{NULL},
       the value of @cppi{exec_file} is used.}

  @item{@cpp{const char *} @cppdef{collects_dir} --- a path to use as
       the main @filepath{collects} directory for locating library
       collections. If this field holds @cpp{NULL} or @cpp{""}, then
       the library-collection search path is initialized as empty.}

  @item{@cpp{const char *} @cppdef{config_dir} --- a path to used as an
       @filepath{etc} directory that holds configuration information,
       including information about installed packages. If the value if
       @cpp{NULL}, @cpp{"etc"} is used.}

  @item{@cpp{wchar_t *} @cppdef{dll_dir} --- a path used to find DLLs,
       such as @exec{iconv} support. Note that this path uses wide
       characters, not a UTF-8 byte encoding.}

  @item{@cpp{int} @cppdef{cs_compiled_subdir} --- A true value indicates
       that the @racket[use-compiled-file-paths] parameter should be
       initialized to have a platform-specific subdirectory of
       @filepath{compiled}, which is used for a Racket CS installation
       that overlays a Racket BC installation.}

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
