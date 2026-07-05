#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "Writing Racket Extensions"]{编写 Racket 扩展}

@section-index["extending Racket"]

正如 @secref["embedding-and-extending"] 所述，编写 Racket 代码并使用
@seclink["top" #:doc '(lib
"scribblings/foreign/foreign.scrbl")]{foreign-function interface}
通常是比编写 Racket extension 更好的选择，但 Racket 也支持 C 实现的 extension，
可以直接与 runtime 系统更紧密地集成。
（Racket CS 没有类似的 extension 接口。）

为 Racket 3m 与 Racket CGC（参见 @secref["CGC versus 3m"]）
创建 extension 的过程本质上相同，但 3m 的过程最容易理解为 CGC 过程的变体。

@section{CGC Extensions}


要为 Racket CGC 编写基于 C/C++ 的 extension，请按以下步骤操作：

@itemize[

 @item{对于每个使用 Racket 库函数的 C/C++ 文件，
@cpp{#include} 文件 @as-index{@filepath{escheme.h}}。

此文件随 Racket 软件一同分发位于 @filepath{include} 目录中，
但如果用 @|mzc| 编译，此路径会被自动找到。}


 @item{定义 C 函数 @cppi{scheme_initialize}，它接受一个
@cpp{Scheme_Env*} namespace（参见 @secref["im:env"]），
返回 @cpp{Scheme_Object*} Racket 值。
 
此初始化函数可以向 namespace 中安装新的 global primitive procedure 或其它值，
或者只是返回一个 Racket 值。当 extension 在指定的 @|tech-place| 中首次
通过 @racket[load-extension] 加载时，会调用此初始化函数；
@cpp{scheme_initialize} 的返回值将作为 @racket[load-extension] 的返回值。
传给 @cpp{scheme_initialize} 的 namespace 是调用 @racket[load-extension]
时的当前 namespace。}


 @item{定义 C 函数 @cppi{scheme_reload}，它接受与
@cpp{scheme_initialize} 相同的参数和返回类型。

如果 extension 在指定的 @|tech-place| 中被第二次（或更多次）
通过 @racket[load-extension] 加载，则会调用此函数。
与 @cpp{scheme_initialize} 一样，此函数的返回值将作为
@racket[load-extension] 的返回值。}


 @item{定义 C 函数 @cppi{scheme_module_name}，它不接受参数，
返回 @cpp{Scheme_Object*}，其值为 symbol 或 @cpp{scheme_false}。

当调用 @cpp{scheme_initialize} 与 @cpp{scheme_reload} 的效果
只是声明一个 module 时（即返回名称对应的 symbol），此函数应返回一个 symbol。
当 extension 被加载以满足 @racket[require] 声明时会调用此函数。

根据 extension 被加载和重新加载的方式，@cpp{scheme_module_name}
函数可能在 @cpp{scheme_initialize} 和 @cpp{scheme_reload} 之前调用，
之后调用，或前后都会调用。}


 @item{编译 extension 的 C/C++ 文件以创建平台特定的 object 文件。

随 Racket 一同分发的 @as-index{@|mzc|} 编译器在指定 @as-index{@DFlag{cc}}
标志时会编译普通 C 文件。更确切地说，@|mzc| 本身不编译文件，
而是定位到系统上的 C 编译器并用适当的编译标志启动它。
如果平台是标准 Unix 系统、装有 Microsoft C 编译器
或在路径中有 @exec{gcc} 的 Windows 系统、
或安装了 Apple developer tools 的 Mac OS 系统，
那么使用 @|mzc| 通常比直接使用 C 编译器更容易。
使用 @as-index{@DFlag{cgc}} 标志表示该构建是用于 Racket CGC 的。}


 @item{将 extension 的 C/C++ 文件与
@as-index{@filepath{mzdyn.o}}（Unix, Mac OS）或
@as-index{@filepath{mzdyn.obj}}（Windows）链接，以创建 shared object。
生成的 shared object 应使用扩展名 @filepath{.so}（Unix）、
@filepath{.dll}（Windows）或 @filepath{.dylib}（Mac OS）。

@filepath{mzdyn} object 文件随安装包分发在 @filepath{lib} 目录中。
在 Windows 上，object 文件在 @filepath{racket\lib} 下与编译器相关的子目录中。

@|mzc| 编译器在指定 @as-index{@DFlag{ld}} 标志时会将 object files
链接为 extension，并自动定位 @filepath{mzdyn}。
同样，对 @|mzc| 使用 @DFlag{cgc} 标志。}

 @item{在 Racket 内使用 @racket[(load-extension _path)] 加载 shared object，
其中 @racket[_path] 是上一步生成的 extension 文件名。

或者，如果 extension 定义了 module（即 @cpp{scheme_module_name} 返回 symbol），
则将 shared object 放入一个具有特殊名称的特殊目录中，以便在使用
@racket[require] 时由 module loader 检测到它。该特殊目录是平台相关的路径，
可通过求值 @racket[(build-path "compiled" "native"
 (system-library-subpath))] 获得；参见 @racket[load/use-compiled]
获取更多信息。例如，如果 shared object 的名称为 @filepath{example_rkt.dll}，
那么当后者放在子目录 @racket[(build-path "compiled" "native"
 (system-library-subpath))] 中且 @filepath{example.rkt} 不存在或时间戳较早时，
@racket[(require "example.rkt")] 将被重定向到 @filepath{example_rkt.dll}。

注意，@racket[module] 内的 @racket[(load-extension _path)]
@italic{不会}将 extension 的 definitions 引入 module，
因为 @racket[load-extension] 是一个运行期操作。
要将 extension 的 bindings 引入 module，请确保 extension 定义了 module，
按上述方式将 extension 放在平台相关的位置，并使用 @racket[require]。}

]

@index['("allocation")]{@bold{重要：}} 在 Racket CGC 中，Racket
值通过 conservative garbage collector 进行垃圾回收，
因此指向 Racket 对象的指针可以保存在 registers、stack 变量
或用 @cppi{scheme_malloc} 分配的结构中。然而，包含指向可收集内存指针的
static 变量必须使用 @cppi{scheme_register_extension_global} 进行注册
（参见 @secref["im:memoryalloc"]）；即便如此，此类 static 变量
必须是 thread-local（OS 线程语义）才能在多个 @|tech-place| 中正常工作
（参见 @secref["places"]）。

例如，以下 C 代码定义了一个 extension，加载时返回 @racket["hello world"]：

@verbatim[#:indent 2]{
 #include "escheme.h"
 Scheme_Object *scheme_initialize(Scheme_Env *env) {
   return scheme_make_utf8_string("hello world");
 }
 Scheme_Object *scheme_reload(Scheme_Env *env) {
   return scheme_initialize(env); /* Nothing special for reload */
 }
 Scheme_Object *scheme_module_name() {
   return scheme_false;
 }
}

假设上述代码位于文件 @filepath{hw.c} 中，extension 在 Unix 上通过以下两条命令编译：

@commandline{raco ctool --cgc --cc hw.c}
@commandline{raco ctool --cgc --ld hw.so hw.o}

（注意：@DFlag{cgc}、@DFlag{cc} 和 @DFlag{ld} 标志各有两个连字符前缀，而不是一个。）

Racket 发行版中的 @filepath{collects/mzscheme/examples} 目录提供了更多示例。

@section{3m Extensions}

要构建与 Racket 3m 共同工作的 extension，必须按以下方式扩展 CGC 指令：

@itemize[

 @item{调整代码以与 garbage collector 配合，如 @secref["im:3m"] 所述。
如 @secref["im:3m:mzc"] 中所述，使用带 @as-index{@DFlag{xform}} 的 @|mzc|
可能会将您的代码转换为转换后的形式，以实现转换的部分内容。}

 @item{在您的源文件或编译器命令行中，在 @cpp{#include}
 @filepath{escheme.h} 之前 @cpp{#define} @cpp{MZ_PRECISE_GC}。
使用带 @DFlag{cc} 和 @as-index{@DFlag{3m}} 标志的 @|mzc| 时，
@cpp{MZ_PRECISE_GC} 会被自动定义。}

 @item{链接到 @as-index{@filepath{mzdyn3m.o}}（Unix, Mac OS）或
 @as-index{@filepath{mzdyn3m.obj}}（Windows）以创建 shared object。
 使用 @|mzc| 时，使用 @DFlag{ld} 和 @DFlag{3m} 标志来链接到这些库。}

]

对于相对简单的 extension @filepath{hw.c}，它在 Unix 上为 3m 编译时可使用以下三条命令：

@commandline{raco ctool --xform hw.c}
@commandline{raco ctool --3m --cc hw.3m.c}
@commandline{raco ctool --3m --ld hw.so hw_3m.o}

@filepath{collects/mzscheme/examples} 中的一些示例以这种方式与 Racket 3m 配合工作。少数示例是手动插桩的，这种情况下应跳过 @DFlag{xform} 步骤。

@section{Declaring a Module in an Extension}

要创建一个表现为 module 的 extension，请从 @cpp{scheme_module_name}
返回一个 symbol，并让 @cpp{scheme_initialize} 和 @cpp{scheme_reload}
使用 @cpp{scheme_primitive_module} 声明一个 module。

例如，以下 extension 实现了一个名为 @racket[hi] 的 module，
导出一个 binding @racket[greeting]：

@verbatim[#:indent 2]{
  #include "escheme.h"

  Scheme_Object *scheme_initialize(Scheme_Env *env) {
    Scheme_Env *mod_env;
    mod_env = scheme_primitive_module(scheme_intern_symbol("hi"), 
                                      env);
    scheme_add_global("greeting", 
                      scheme_make_utf8_string("hello"), 
                      mod_env);
    scheme_finish_primitive_module(mod_env);
    return scheme_void;
  }

  Scheme_Object *scheme_reload(Scheme_Env *env) {
    return scheme_initialize(env); /* Nothing special for reload */
  }

  Scheme_Object *scheme_module_name() {
    return scheme_intern_symbol("hi");
  }
}

例如，此 extension 可以通过以下 @exec{mzc} 命令序列
为 i386 Linux 上的 3m 编译：

@commandline{raco ctool --xform hi.c}
@commandline{raco ctool --3m --cc hi.3m.c}
@commandline{mkdir -p compiled/native/i386-linux/3m}
@commandline{raco ctool --3m --ld compiled/native/i386-linux/3m/hi_rkt.so hi_3m.o}

生成的 module 可以通过以下方式加载：

@racketblock[(require "hi.rkt")]

@; ----------------------------------------------------------------------

