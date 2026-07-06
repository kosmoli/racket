#lang scribble/doc
@(require "utils.rkt"
          scribble/bnf)

@cs-title[#:tag "cs-embedding"]{嵌入到程序中}

@section-index["embedding Racket CS"]

要将 Racket CS 嵌入到程序中，请按照以下步骤操作：

@itemize[

@item{定位或 @seclink["src-build"]{构建} Racket CS 库。

 在 Unix 上，库是 @as-index{@filepath{libracketcs.a}}。从源码构建和安装会将库放到安装的 @filepath{lib} 目录下。

 在 Windows 上，链接到 @filepath{libracketcs@italic{x}.dll}（其中 @italic{x} 表示版本号）。运行时，libracketcs@italic{x}.dll 必须移到标准 DLL 搜索路径中，或者嵌入程序必须“delayload”链接 DLL 并在使用前显式加载。（@filepath{Racket.exe} 采用后一种策略。）另见 @secref["link-dll"]。

 在 Mac OS 上，除了用于静态链接的 @as-index{@filepath{libracketcs.a}}，@filepath{Racket} framework 也提供了动态库。链接时给 @exec{gcc} 传 @exec{-framework Racket} 以及 @exec{-F} 和 @filepath{lib} 目录路径。运行时需确保 framework 可被找到；面向 Hardened Runtime 时必须启用“Allow Unsigned Executable Memory”授权，否则调用 @cppi{racket_boot} 时会报“out of memory”错误。}

 @item{对于每个使用 Racket 库函数的 C 文件，
  @cpp{#include} 文件 @as-index{@filepath{chezscheme.h}}
  和 @as-index{@filepath{racketcs.h}}。

  @filepath{chezscheme.h} 和 @filepath{racketcs.h} 文件随 Racket 软件
  一起分发在安装的 @filepath{include} 目录中。从源码构建和安装也会将
  这些文件放入安装的 @filepath{include} 目录。}

 @item{在你的程序中，调用 @cppi{racket_boot}。
  @cppi{racket_boot} 函数接受一个指向
  @cpp{racket_boot_arguments_t} 的指针，用于配置 Racket 实例。
  将 @cpp{racket_boot_arguments_t} 值清零后
  （通常使用 @cpp{memset}），只需设置以下字段：

  @itemlist[

     @item{@cpp{exec_file} --- 由 @racket[(find-system-path 'exec-file)] 报告的路径，
           通常是程序 @cpp{main} 收到的 @cpp{argv} 中的 @cpp{argv[0]}。}

     @item{@cpp{boot1_path} 或 @cpp{boot1_data} 和 @cpp{boot1_len}
           --- 到 @filepath{petite.boot} 的路径，或 @filepath{petite.boot} 的内容及其字节长度。
           在前一种情况下，使用包含至少一个目录分隔符的路径。}

     @item{@cpp{boot2_path} or @cpp{boot2_data} and @cpp{boot2_len}
           --- either a path to @filepath{scheme.boot} (with a
           separator) or the content of @filepath{scheme.boot} and its
           length.}

     @item{@cpp{boot3_path} or @cpp{boot3_data} and @cpp{boot3_len}
           --- either a path to @filepath{racket.boot} (with a
           separator) or the content of @filepath{racket.boot} and its
           length.}

  ]

  @filepath{petite.boot}、@filepath{scheme.boot} 和
  @filepath{racket.boot} 文件随 Racket 软件一起分发在 Windows 上安装的
  @filepath{lib} 目录中，在 Mac OS X 上分发在 @filepath{Racket} framework 中；
  在 Unix 上必须从源码 @seclink["src-build"]{构建}。
  这些文件可以合并为一个文件——甚至可以嵌入到可执行文件中——
  只要在 @cpp{racket_boot_arguments_t} 中设置 @cpp{boot1_offset}、
  @cpp{boot2_offset} 和 @cpp{boot3_offset} 字段来标识文件中每个 boot 镜像的起始偏移量。

  See @secref["segment-ideas"] for advice on embedding files like
  @filepath{petite.boot} in an executable, or consider using
  @cpp{racket_get_self_exe_path} and @cpp{racket_path_replace_filename}
  to build paths that are relative to the executable.}

 @item{Configure the main thread's namespace by adding module
  declarations. The initial namespace contains declarations only for a
  few primitive modules, such as @racket['#%kernel], and no bindings
  are imported into the top-level environment.

  To embed a module like @racketmodname[racket/base] (along with all
  its dependencies), use
  @seclink["c-mods" #:doc raco-doc]{@exec{raco ctool --c-mods @nonterm{dest}}},
  which generates a C file @nonterm{dest}
  that contains modules in compiled form as encapsulated in a static
  array. The generated C file defines a @cppi{declare_modules}
  function that takes no arguments and installs the modules into
  the environment, and it adjusts the module name resolver to access the
  embedded declarations. If embedded modules refer to runtime files
  that need to be carried along, supply @DFlag{runtime} to
  @exec{raco ctool --c-mods} to collect the runtime files into a
  directory; see @secref[#:doc raco-doc "c-mods"] for more information.

  Alternatively, set fields like @cpp{collects_dir}, @cpp{config_dir},
  and/or @cpp{argv} in the @cpp{racket_boot_arguments_t} passed to
  @cppi{racket_boot} to locate collections/packages and initialize the
  namespace the same way as when running the @exec{racket} executable.

  On Windows, @exec{raco ctool --c-mods @nonterm{dest} --runtime
  @nonterm{dest-dir}} includes in @nonterm{dest-dir} optional DLLs
  that are referenced by the Racket library to support
  @racket[bytes-open-converter]. Set @cpp{dll_dir} in
  @cpp{racket_boot_arguments_t} to register @nonterm{dest-dir} so that
  those DLLs can be found at run time.

  Instead of using @DFlag{c-mods} with @exec{raco ctool}, you can use
  @DFlag{mods}, embed the file content (see @secref["segment-ideas"])
  and load the content with @cppi{racket_embedded_load_file_region}.}

 @item{通过 @cppi{racket_dynamic_require}、
  @cppi{racket_eval} 和/或本手册中描述的其他函数访问 Racket。

  如果嵌入程序以某种方式配置 built-in parameter，
  且该方式应被视为默认配置的一部分，
  则随后调用 primitive @racketidfont{#%boot} module 提供的
  @racketidfont{seal} 函数。@racketidfont{seal} 获取的参数值快照
  用于某些特权操作，例如安装 @|PLaneT| package。}

 @item{编译程序并将其与 Racket 库链接。}

]

@index['("allocation")]{Racket} 值在使用 @cpp{racket_...} 函数运行
Racket 代码的任何时候都可能被移动或垃圾回收。
不要在这样的调用之间保留对任何 Racket 值的引用。

For example, the following is a simple embedding program that runs a
module @filepath{run.rkt}, assuming that @filepath{run.c} is created
as

@commandline{raco ctool --c-mods run.c "run.rkt"}

to generate @filepath{run.c}, which encapsulates the compiled form of
@filepath{run.rkt} and all of its transitive imports (so that they
need not be found separately a run time). Copies of
@filepath{petite.boot}, @filepath{scheme.boot}, and
@filepath{racket.boot} must be in the current directory on startup.

@filebox["main.c"]{
@verbatim[#:indent 2]{
#include <string.h>
#include "chezscheme.h"
#include "racketcs.h"

#include "run.c"

int main(int argc, char *argv[])
{
  racket_boot_arguments_t ba;

  memset(&ba, 0, sizeof(ba));

  ba.boot1_path = "./petite.boot";
  ba.boot2_path = "./scheme.boot";
  ba.boot3_path = "./racket.boot";
  
  ba.exec_file = argv[0];

  racket_boot(&ba);

  declare_modules();

  ptr mod = Scons(Sstring_to_symbol("quote"),
                  Scons(Sstring_to_symbol("run"),
                        Snil));

  racket_dynamic_require(mod, Sfalse);

  return 0;
}
}}

作为另一个例子，下面是一个简单的嵌入程序，
它评估命令行上提供的所有表达式并显示结果，
然后运行一个 @racket[read]-@racket[eval]-@racket[print] 循环，
全部使用 @racketmodname[racket/base]。运行

@commandline{raco ctool --c-mods base.c ++lib racket/base}

生成 @filepath{base.c}，它封装了 @racket[racket/base]
及其所有传递导入。

@filebox["main.c"]{
@verbatim[#:indent 2]{
#include <string.h>
#include "chezscheme.h"
#include "racketcs.h"

#include "base.c"

static ptr to_bytevector(char *s);

int main(int argc, char *argv[])
{
  racket_boot_arguments_t ba;

  memset(&ba, 0, sizeof(ba));

  ba.boot1_path = "./petite.boot";
  ba.boot2_path = "./scheme.boot";
  ba.boot3_path = "./racket.boot";
  
  ba.exec_file = argv[0];

  racket_boot(&ba);

  declare_modules();

  racket_namespace_require(Sstring_to_symbol("racket/base"));

  {
    int i;
    for (i = 1; i < argc; i++) {
      ptr e = to_bytevector(argv[i]);
      e = Scons(Sstring_to_symbol("open-input-bytes"),
                Scons(e, Snil));
      e = Scons(Sstring_to_symbol("read"), Scons(e, Snil));
      e = Scons(Sstring_to_symbol("eval"), Scons(e, Snil));
      e = Scons(Sstring_to_symbol("println"), Scons(e, Snil));

      racket_eval(e);
    }
  }

  {
    ptr rbase_sym = Sstring_to_symbol("racket/base");
    ptr repl_sym = Sstring_to_symbol("read-eval-print-loop");
  
    racket_apply(Scar(racket_dynamic_require(rbase_sym,
                                             repl_sym)),
                 Snil);
  }

  return 0;
}

static ptr to_bytevector(char *s)
{
  iptr len = strlen(s);
  ptr bv = Smake_bytevector(len, 0);
  memcpy(Sbytevector_data(bv), s, len);
  return bv;
}
}}

If modules embedded in the executable need to access runtime files
(via @racketmodname[racket/runtime-path] forms), supply the
@DFlag{runtime} flag to @seclink["ctool" #:doc raco-doc]{@exec{raco ctool}}, specifying a directory
where the runtime files are to be gathered. The modules in the
generated @filepath{.c} file will then refer to the files in that
directory.
