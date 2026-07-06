#lang scribble/doc
@(require "utils.rkt"
          scribble/bnf)

@(define cgc-v-3m "CGC versus 3m")

@bc-title[#:tag "embedding"]{嵌入到程序中}

@section-index["embedding Racket BC"]

Racket 运行时系统可以嵌入到更大的程序中。Racket CGC 与 Racket 3m(见 @secref[cgc-v-3m])的嵌入过程基本相同，但 Racket 3m 的过程最容易理解为 Racket CGC 过程的变体(尽管 Racket 3m 是 Racket 的标准变体)。

@section{CGC 嵌入}

要将 Racket CGC 嵌入到程序中，请按以下步骤操作：

@itemize[

 @item{找到或 @seclink["src-build"]{自己构建}
  Racket CGC 库。由于
  标准发行版仅提供 3m 库，你很可能
  需要 @seclink["src-build"]{从源代码构建}。

  在 Unix 上，库文件为 @as-index{@filepath{libracket.a}}、
  @as-index{@filepath{librktio.a}}
  和 @as-index{@filepath{libmzgc.a}}（或者
  @as-index{@filepath{libracket.so}}、
  @as-index{@filepath{librrktio.so}} 和
  @as-index{@filepath{libmzgc.so}} 用于动态库构建，配合
  @as-index{@filepath{libracket.la}}、
  @as-index{@filepath{librktio.la}} 和
  @as-index{@filepath{libmzgc.la}} 文件供
  @exec{libtool} 使用）。从源代码构建并安装会将
  库文件放入安装目录的 @filepath{lib} 子目录中。请确保
  构建的是 CGC 变体，因为默认为 3m。

  在 Windows 上，链接到 @filepath{libracket@italic{x}.dll} 和
  @filepath{libmzgc@italic{x}.dll}（其中 @italic{x} 表示
  版本号）。在运行时，要么将
  @filepath{libracket@italic{x}.dll} 和
  @filepath{libmzgc@italic{x}.dll} 移动到
  标准 DLL 搜索路径中的某个位置，要么你的嵌入应用程序必须
  对 DLL 进行 ``delayload'' 链接并在使用前显式加载它们。
  （@filepath{Racket.exe} 采用后一种策略。）另请参见
  @secref["link-dll"]。

  在 Mac OS 上，动态库由
  @filepath{Racket} framework 提供，通常安装在
  安装目录的 @filepath{lib} 子目录中。链接时向 @exec{gcc} 提供
  @exec{-framework Racket}，以及
  @exec{-F} 和指向 @filepath{lib} 目录的路径。请注意，
  CGC 和 3m 库在单个 framework 中作为不同版本安装，
  安装过程通过设置符号链接标记其中一个版本为默认；
  仅安装 CGC 可以简化在 framework 中访问 CGC 版本的过程。在
  运行时，要么将 @filepath{Racket.framework} 移动到
  标准 framework 搜索路径中的某个位置，要么你的嵌入
  可执行文件必须提供指向该 framework 的特定路径（可能
  是使用 Mach-O @tt["@executable_path"]
  前缀的可执行文件相对路径）。}

 @item{对于每个使用 Racket 库函数的 C 文件，
  在文件中 @cpp{#include} @as-index{@filepath{scheme.h}}。

  C 预处理器符号 @cppi{SCHEME_DIRECT_EMBEDDED} 在
  @cpp{#include} @filepath{scheme.h} 时被定义为
  @cpp{1}，而在 @cpp{#include} @filepath{escheme.h} 时
  被定义为 @cpp{0}。

  @filepath{scheme.h} 文件随 Racket 软件一起分发，位于
  安装目录的 @filepath{include} 子目录中。从源代码构建并
  安装也会将此文件放入安装目录的
  @filepath{include} 子目录中。}

 @item{通过 @cpp{scheme_main_setup}（或
  @cpp{scheme_main_stack_setup}）trampoline 启动你的主程序，并将所有对
  Racket 函数的使用放在传递给
  @cpp{scheme_main_setup} 的函数内部。@cpp{scheme_main_setup} 函数
  会将当前的 C 栈位置注册到内存管理器中。它
  还会通过调用 @cppi{scheme_basic_env}
  并将结果传递给提供给 @cpp{scheme_main_setup} 的函数来
  创建初始命名空间 @cpp{Scheme_Env*}。（
  @cpp{scheme_main_stack_setup} trampoline 会向
  内存管理器注册 C 栈而不创建命名空间。）

  在 Windows 上，当 Racket 构建中启用了并行支持时
  （这是默认设置），那么在调用
  @cpp{scheme_main_setup} 之前，你的嵌入应用程序必须先调用
  @cppi{scheme_register_tls_space}：

  @verbatim[#:indent 2]{
   scheme_register_tls_space(&tls_space, 0);
  }

  其中 @cpp{tls_space} 在主可执行文件（即，不在动态链接的 DLL 中）
  中声明为线程局部指针变量：

  @verbatim[#:indent 2]{
   static __declspec(thread) void *tls_space;
  }

  @history[#:changed "6.3" @elem{调用 @cpp{scheme_register_tls_space} 在
                                 所有 Windows 变体上都是必需的，尽管该调用
                                 可能是空操作，具体取决于 Racket 的构建
                                 方式。}]}

 @item{通过添加模块声明来配置命名空间。
  初始命名空间仅包含少数几个原始
  模块的声明，例如 @racket['#%kernel]，并且没有绑定被导入
  到顶层环境中。

  要嵌入像 @racketmodname[racket/base] 这样的模块（以及其
  所有依赖项），请使用
  @seclink["c-mods" #:doc raco-doc]{@exec{raco ctool --c-mods @nonterm{dest}}}，
  该命令生成一个 C 文件 @nonterm{dest}，
  其中包含以字节码形式封装在静态
  数组中的模块。生成的 C 文件定义了一个 @cppi{declare_modules}
  函数，该函数接受一个 @cpp{Scheme_Env*}，将模块安装到
  该环境中，并调整模块名称解析器以访问
  嵌入的声明。如果嵌入的模块引用了需要携带的运行时文件，
  请为 @exec{raco ctool --c-mods} 提供 @DFlag{runtime} 标志
  来将运行时文件收集到一个目录中；有关更多信息，
  请参见 @secref[#:doc raco-doc "c-mods"]。

  或者，使用 @cpp{scheme_set_collects_path} 和
  @cpp{scheme_init_collection_paths} 来配置和安装
  在运行时查找模块的路径。

  在 Windows 上，@exec{raco ctool --c-mods @nonterm{dest} --runtime
  @nonterm{dest-dir}} 会在 @nonterm{dest-dir} 中包含可选的 DLL，
  这些 DLL 被 Racket 库引用，用于支持 @tech[#:doc
  reference-doc]{extflonums} 和 @racket[bytes-open-converter]。调用
  @cpp{scheme_set_dll_path} 来注册 @nonterm{dest-dir}，以便
  这些 DLL 可以在运行时被找到。}

 @item{通过 @cppi{scheme_dynamic_require}、
  @cppi{scheme_load}、@cppi{scheme_eval} 和/或本手册中描述的
  其他函数来访问 Racket。

  如果嵌入程序以某种方式配置了内置参数，而这些配置
  应被视为默认配置的一部分，那么
  之后请调用 @cpp{scheme_seal_parameters}。由
  @cpp{scheme_seal_parameters} 获取的参数值快照将用于
  某些特权操作，例如安装 @|PLaneT|
  包。}

 @item{编译程序并将其与 Racket 库链接。}

]

@index['("allocation")]{在} Racket CGC 中，Racket 值通过保守垃圾回收器进行回收，因此指向 Racket 对象的指针可以保存在寄存器、栈变量或通过 @cppi{scheme_malloc} 分配的结构体中。在某些平台上的嵌入应用中，静态变量也会自动注册为垃圾回收的根（但请参见下文关于 Mac OS 和 Windows 的具体说明）。

例如，下面是一个简单的嵌入程序，它运行模块 @filepath{run.rkt}，假设 @filepath{run.c} 是通过以下命令创建的

@commandline{raco ctool --c-mods run.c "run.rkt"}

来生成 @filepath{run.c}，其中封装了 @filepath{run.rkt} 的编译形式及其所有传递导入（因此它们无需在运行时单独查找）。

@filebox["main.c"]{
@verbatim[#:indent 2]{
#include "scheme.h"
#include "run.c"

static int run(Scheme_Env *e, int argc, char *argv[])
{
  Scheme_Object *a[2];

  /* Declare embedded modules in "run.c": */
  declare_modules(e);

  a[0] = scheme_make_pair(scheme_intern_symbol("quote"),
                          scheme_make_pair(scheme_intern_symbol("run"),
                                           scheme_make_null()));
  a[1] = scheme_false;

  scheme_dynamic_require(2, a);
  
  return 0;
}

int main(int argc, char *argv[])
{
  return scheme_main_setup(1, run, argc, argv);
}
}}

另一个例子，下面是一个简单的嵌入程序，它评估命令行上提供的所有表达式并显示结果，然后运行一个 @racket[read]-@racket[eval]-@racket[print] 循环，全部使用 @racketmodname[racket/base]。运行

@commandline{raco ctool --c-mods base.c ++lib racket/base}

来生成 @filepath{base.c}，其中封装了 @racket[racket/base] 及其所有传递导入。

@filebox["main.c"]{
@verbatim[#:indent 2]{
#include "scheme.h"
#include "base.c"

static int run(Scheme_Env *e, int argc, char *argv[])
{
  Scheme_Object *curout;
  int i;
  Scheme_Thread *th;
  mz_jmp_buf * volatile save, fresh;

  /* Declare embedded modules in "base.c": */
  declare_modules(e);

  scheme_namespace_require(scheme_intern_symbol("racket/base"));

  curout = scheme_get_param(scheme_current_config(), 
                            MZCONFIG_OUTPUT_PORT);

  th = scheme_get_current_thread();

  for (i = 1; i < argc; i++) {
    save = th->error_buf;
    th->error_buf = &fresh;
    if (scheme_setjmp(*th->error_buf)) {
      th->error_buf = save;
      return -1; /* There was an error */
    } else {
      Scheme_Object *v, *a[2];
      v = scheme_eval_string(argv[i], e);
      scheme_display(v, curout);
      scheme_display(scheme_make_char('\n'), curout);
      /* read-eval-print loop, uses initial Scheme_Env: */
      a[0] = scheme_intern_symbol("racket/base");
      a[1] = scheme_intern_symbol("read-eval-print-loop");
      scheme_apply(scheme_dynamic_require(2, a), 0, NULL);
      th->error_buf = save;
    }
  }
  return 0;
}

int main(int argc, char *argv[])
{
  return scheme_main_setup(1, run, argc, argv);
}
}}

如果嵌入到可执行文件中的模块需要访问运行时代码文件（通过 @racketmodname[racket/runtime-path] form），请为 @seclink["ctool" #:doc raco-doc]{@exec{raco ctool}} 提供 @DFlag{runtime} 标志，指定一个目录来收集运行时文件。生成的 @filepath{.c} 文件中的模块将引用该目录中的文件；该目录通常相对于可执行文件指定，但嵌入应用程序在声明模块之前必须调用 @cppi{scheme_set_exec_cmd} 来设置可执行文件路径（通常是 @cpp{argv[0]}）。

在 Mac OS 上，或者当 Racket 在 Windows 上使用 Cygwin 编译为 DLL 时，垃圾回收器无法自动找到静态变量。在这种情况下，必须使用非零的第一个参数调用 @cppi{scheme_main_setup}。

在 Windows 上（对于任何其他构建模式），垃圾回收器通过检查所有内存页面来查找嵌入程序中的静态变量。如果程序包含多个 Windows 线程，此策略可能会失败；当回收器正在检查页面时，线程可能会取消映射该页面，导致回收器崩溃。为避免此问题，请使用非零的第一个参数调用 @cpp{scheme_main_setup}。

当嵌入应用程序使用非零的第一个参数调用 @cpp{scheme_main_setup} 时，如果该变量可能包含可 GC 的指针，则必须使用 @cppi{MZ_REGISTER_STATIC} 注册其每个静态变量。例如，如果上面的 @cpp{curout} 被设为 @cpp{static}，那么应该在调用 @cpp{scheme_get_param} 之前插入 @cpp{MZ_REGISTER_STATIC(curout)}。

当构建嵌入式 Racket CGC 以使用 SenoraGC (SGC) 而非默认回收器时，必须使用非零的第一个参数调用 @cpp{scheme_main_setup}。有关更多信息，请参见 @secref["im:memoryalloc"]。


@section{3m 嵌入}

Racket 3m 的嵌入方式与 Racket CGC 基本相同，只要嵌入程序按照 @secref["im:3m"] 中所述与精确垃圾回收器配合即可。

在源代码或编译器命令行中，在 include @filepath{scheme.h} 之前 @cpp{#define} @cpp{MZ_PRECISE_GC}。当使用 @|mzc| 并带有 @DFlag{cc} 和 @DFlag{3m} 标志时，@cpp{MZ_PRECISE_GC} 会被自动定义。

此外，一些库细节有所不同：

@itemize[

 @item{在 Unix 上，库文件仅为
  @as-index{@filepath{libracket3m.a}} 和 @as-index{@filepath{librrktio.a}}（或者
  @as-index{@filepath{libracket3m.so}} 和 @as-index{@filepath{librktio.so}} 用于动态库构建，
  配合 @as-index{@filepath{libracket3m.la}} 和 @as-index{@filepath{librktio.la}} 供
  @exec{libtool} 使用）。3m 没有类似于
  CGC 的 @filepath{libmzgc.a} 的单独库。}

 @item{在 Windows 上，链接到 @filepath{libracket3m@italic{x}.dll}。
  3m 没有类似于 CGC 的
  @filepath{libmzgc@italic{x}.lib} 的单独库。}

  @item{在 Mac OS 上，3m 动态库由
  @filepath{Racket} framework 提供，与 CGC 相同，但作为以
  @filepath{_3m} 后缀结尾的版本。}

]

对于 Racket 3m，嵌入应用程序必须使用非零的第一个参数调用 @cpp{scheme_main_setup}。

前一节的简单嵌入程序可以通过 @seclink["cc" #:doc raco-doc]{@exec{raco ctool --xform}} 处理，然后使用 Racket 3m 编译和链接。或者，源代码可以扩展为同时支持 CGC 或 3m，具体取决于编译器命令行上是否定义了 @cpp{MZ_PRECISE_GC}：

@filebox["main.c"]{
@verbatim[#:indent 2]{
#include "scheme.h"
#include "run.c"

static int run(Scheme_Env *e, int argc, char *argv[])
{
  Scheme_Object *l = NULL;
  Scheme_Object *a[2] = { NULL, NULL };

  MZ_GC_DECL_REG(5);
  MZ_GC_VAR_IN_REG(0, e);
  MZ_GC_VAR_IN_REG(1, l);
  MZ_GC_ARRAY_VAR_IN_REG(2, a, 2);

  MZ_GC_REG();

  declare_modules(e);

  l = scheme_make_null();
  l = scheme_make_pair(scheme_intern_symbol("run"), l);
  l = scheme_make_pair(scheme_intern_symbol("quote"), l);

  a[0] = l;
  a[1] = scheme_false;

  scheme_dynamic_require(2, a);

  MZ_GC_UNREG();

  return 0;
}

int main(int argc, char *argv[])
{
  return scheme_main_setup(1, run, argc, argv);
}
}
}

@filebox["main.c"]{
@verbatim[#:indent 2]{
#include "scheme.h"
#include "base.c"

static int run(Scheme_Env *e, int argc, char *argv[])
{
  Scheme_Object *curout = NULL, *v = NULL, *a[2] = {NULL, NULL};
  Scheme_Config *config = NULL;
  int i;
  Scheme_Thread *th = NULL;
  mz_jmp_buf * volatile save = NULL, fresh;

  MZ_GC_DECL_REG(9);
  MZ_GC_VAR_IN_REG(0, e);
  MZ_GC_VAR_IN_REG(1, curout);
  MZ_GC_VAR_IN_REG(2, save);
  MZ_GC_VAR_IN_REG(3, config);
  MZ_GC_VAR_IN_REG(4, v);
  MZ_GC_VAR_IN_REG(5, th);
  MZ_GC_ARRAY_VAR_IN_REG(6, a, 2);

  MZ_GC_REG();

  declare_modules(e);

  v = scheme_intern_symbol("racket/base");
  scheme_namespace_require(v);

  config = scheme_current_config();
  curout = scheme_get_param(config, MZCONFIG_OUTPUT_PORT);

  th = scheme_get_current_thread();

  for (i = 1; i < argc; i++) {
    save = th->error_buf;
    th->error_buf = &fresh;
    if (scheme_setjmp(*th->error_buf)) {
      th->error_buf = save;
      return -1; /* There was an error */
    } else {
      v = scheme_eval_string(argv[i], e);
      scheme_display(v, curout);
      v = scheme_make_char('\n');
      scheme_display(v, curout);
      /* read-eval-print loop, uses initial Scheme_Env: */
      a[0] = scheme_intern_symbol("racket/base");
      a[1] = scheme_intern_symbol("read-eval-print-loop");
      v = scheme_dynamic_require(2, a);
      scheme_apply(v, 0, NULL);
      th->error_buf = save;
    }
  }

  MZ_GC_UNREG();

  return 0;
}

int main(int argc, char *argv[])
{
  return scheme_main_setup(1, run, argc, argv);
}
}
}

严格来说，上面的 @cpp{config} 和 @cpp{v} 变量不需要向垃圾回收器注册，因为它们的值在会进行分配的函数调用之间并不需要保留。然而，当所有局部变量都已注册，并且所有临时值都放入变量中时，代码维护起来会容易得多。

@; ----------------------------------------
@include-section["hooks.scrbl"]
