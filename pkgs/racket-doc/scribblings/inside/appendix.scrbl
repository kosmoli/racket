#lang scribble/base
@(require "utils.rkt"
          scribble/bnf)

@title[#:style '(grouper toc) #:tag "appendix"]{附录}

@local-table-of-contents[]

@; ----------------------------------------

@section[#:tag "src-build"]{从源码构建 Racket}

正常的 Racket 发行版包含基于 collection 的库的 @filepath{.rkt} 源码。
修改库文件后，运行 @exec{raco setup}（参见 @secref[#:doc '(lib
"scribblings/raco/raco.scrbl") "setup"]）来重建已安装的库。

正常的 Racket 发行版不包含 Racket 运行时系统的 C 源码。
要从头构建 Racket，请从 @url{http://download.racket-lang.org} 下载源码发行版。
详细的构建说明位于顶层 @filepath{src} 目录中的 @filepath{README.txt} 文件中。
你也可以从 @url{https://github.com/racket/racket} 的 @tt{git} 仓库获取最新源码，
但请注意，该仓库与正常的源码发行版略有不同，
它提供了更适合开发 Racket 本身的构建模式；
更多信息请参见 @tt{git} 仓库中的 @filepath{build.md}。

@; ----------------------------------------

@section[#:tag "ios-cross-compilation"]{为 iOS 交叉编译 Racket 源码}

关于在交叉构建模式下使用 Racket 的一般信息，
参见 @secref[#:doc raco-doc "cross-system"]。
本节中的所有内容都可以适配到其他交叉编译目标，
但为了使示例更具体，这里使用 iOS。

按照源码发行版的 @filepath{src/README.txt} 文件为 iOS 交叉编译 Racket CS 后，
你可以将该构建 @nonterm{ios-racket-dir} 与编译它的主机构建结合使用，
通过向主机可执行文件传递以下标志集来为 iOS 交叉编译 Racket 模块：

@verbatim[#:indent 2]{
racket  \
  --compile-any  \
  --compiled @nonterm{ios-racket-dir}/src/build/cs/c/compiled:  \
  --cross  \
  --cross-compiler tarm64osx @nonterm{ios-racket-dir}/src/build/cs/c  \
  --config @nonterm{ios-racket-dir}/etc  \
  --collects @nonterm{ios-racket-dir}/collects
}

上述命令运行主机 Racket REPL，支持同时为主机机器和 @tt{tarm64osx} 目标
编写编译后的代码。@DFlag{compiled} 的第一个路径（在 @litchar{:} 之前）
可以是任何绝对路径，主平台的 @filepath{.zo} 文件将写入该处；
指定路径 @filepath{@nonterm{ios-racket-dir}/src/build/cs/c/compiled}
旨在重用交叉编译安装期间创建的目录。
@DFlag{compiled} 的第二个路径（在 @litchar{:} 之后）为空，
这会导致目标平台的 @filepath{.zo} 文件写入通常的 @filepath{compiled} 子目录。

通过传递 @Flag{l} 标志指示主机 Racket 运行库代码。
例如，你可以使用以下命令设置目标 Racket 的安装：

@verbatim[#:indent 2]{
racket  \
  --compile-any  \
  --compiled @nonterm{ios-racket-dir}/src/build/cs/c/compiled:  \
  --cross  \
  --cross-compiler tarm64osx @nonterm{ios-racket-dir}/lib  \
  --config @nonterm{ios-racket-dir}/etc  \
  --collects @nonterm{ios-racket-dir}/collects  \
  -l-  \
  raco setup
}

最后，你可以将 Racket 模块及其依赖打包，供 @cppi{racket_embedded_load_file} 使用
（在为目标 Racket 安装 @filepath{compiler-lib} 和 @filepath{cext-lib} 之后），
命令如下：

@verbatim[#:indent 2]{
racket  \
  --compile-any  \
  --compiled @nonterm{ios-racket-dir}/src/build/cs/c/compiled:  \
  --cross  \
  --cross-compiler tarm64osx @nonterm{ios-racket-dir}/lib  \
  --config @nonterm{ios-racket-dir}/etc  \
  --collects @nonterm{ios-racket-dir}/collects  \
  -l-  \
  raco ctool --mods application.zo src/application.rkt
}

@; ----------------------------------------

@section[#:tag "link-dll"]{在 Windows 上链接到 DLL}

某些 Windows 链接工具（如 MinGW-w64）接受 @filepath{.dll} 进行链接，
生成引用该 @filepath{.dll} 的可执行文件。其他工具（如 Microsoft Visual Studio）
需要 @filepath{.lib} 桩库（stub library）来描述将使用的 @filepath{.dll}。
Racket 发行版不包含 @filepath{.lib} 桩库，
但存在各种工具可以从 @filepath{.dll} 和 @filepath{.def} 文件
（包含在 Racket 发行版中）生成 @filepath{.lib} 文件。

要使用 Microsoft Visual Studio 工具创建 @filepath{@italic{x}.lib}
（用于与 @filepath{@italic{x}.dll} 链接）：

@itemlist[

 @item{使用与 @filepath{@italic{x}.dll} 中相同的基本名称 @italic{x}
       定位文件 @filepath{@italic{x}.def}。}

  @item{使用此命令生成 @filepath{@italic{x}.lib}：

        @commandline{lib /def:@italic{x}.def /out:@italic{x}.lib /machine:@italic{mach}}

        Use a suitable platform description in place of @italic{mach},
        such as @litchar{x64} for 64-bit Windows on x86_64.}

]

@; ----------------------------------------

@section[#:tag "segment-ideas"]{将文件嵌入可执行文件段}

在启动时定位外部文件（如 Racket CS 所需的引导文件）可能很麻烦。
替代方案是将文件作为数据段嵌入 ELF 或 Mach-O 可执行文件中，
或作为资源嵌入 Windows 可执行文件中。以这种方式嵌入文件
需要使用操作系统特定的链接步骤和运行时库。

@; ============================================================

@subsection{在 Linux 上访问 ELF 段}

在 Linux 和其他基于 ELF 的系统上，你可以使用 @exec{objcopy}
向可执行文件添加段。例如，以下命令将 @filepath{pre_run} 复制到 @cpp{run}，
同时将引导文件添加为段：

@verbatim[#:indent 2]{
objcopy --add-section .csboot1=petite.boot \
        --set-section-flags .csboot1=noload,readonly \
        --add-section .csboot2=scheme.boot \
        --set-section-flags .csboot2=noload,readonly \
        --add-section .csboot3=racket.boot \
        --set-section-flags .csboot3=noload,readonly \
        ./pre_run ./run
}

以下是 @filepath{pre_run} 的实现，类似于 @secref["cs-embedding"] 中的版本，
但引导文件从段加载：

@filebox["main.c"]{
@verbatim[#:indent 2]{
#include <string.h>
#include <stdlib.h>
#include <sys/types.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <elf.h>
#include <fcntl.h>

#include "chezscheme.h"
#include "racketcs.h"

#include "run.c"

static long find_section(const char *exe, const char *sectname)
{
  int fd, i;
  Elf64_Ehdr e;
  Elf64_Shdr s;
  char *strs;

  fd = open(exe, O_RDONLY, 0);
  if (fd != -1) {
    if (read(fd, &e, sizeof(e)) == sizeof(e)) {
      lseek(fd, e.e_shoff + (e.e_shstrndx * e.e_shentsize), SEEK_SET);
      if (read(fd, &s, sizeof(s)) == sizeof(s)) {
	strs = (char *)malloc(s.sh_size);
	lseek(fd, s.sh_offset, SEEK_SET);
	if (read(fd, strs, s.sh_size) == s.sh_size) {
	  for (i = 0; i < e.e_shnum; i++) {
	    lseek(fd, e.e_shoff + (i * e.e_shentsize), SEEK_SET);
	    if (read(fd, &s, sizeof(s)) != sizeof(s))
	      break;
	    if (!strcmp(strs + s.sh_name, sectname)) {
	      close(fd);
	      return s.sh_offset;
	    }
	  }
	}
      }
    }
    close(fd);
  }

  fprintf(stderr, "could not find section %s\n", sectname);
  return -1;
}

int main(int argc, char *argv[])
{
  racket_boot_arguments_t ba;

  memset(&ba, 0, sizeof(ba));

  ba.boot1_path = racket_get_self_exe_path(argv[0]);
  ba.boot2_path = ba.boot1_path;
  ba.boot3_path = ba.boot1_path;

  ba.boot1_offset = find_section(ba.boot1_path, ".csboot1");
  ba.boot2_offset = find_section(ba.boot2_path, ".csboot2");
  ba.boot3_offset = find_section(ba.boot3_path, ".csboot3");

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

@; ============================================================

@subsection{访问 Mac OS 段}

On Mac OS, sections can be added to a Mach-O executable using the
@Flag{sectcreate} compiler flag. If @filepath{main.c} is compiled and
linked with

@verbatim[#:indent 2]{
  gcc main.c libracketcs.a -Ipath/to/racket/include \
      -liconv -lncurses -framework CoreFoundation \
      -sectcreate __DATA __rktboot1 petite.boot \
      -sectcreate __DATA __rktboot2 scheme.boot \
      -sectcreate __DATA __rktboot2 racket.boot
}

then the executable can access is own path using
@cpp{_NSGetExecutablePath}, and it can locate sections using
@cpp{getsectbyname}. Here's an example like the one in
@secref["cs-embedding"]:

@filebox["main.c"]{
@verbatim[#:indent 2]{
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#include "chezscheme.h"
#include "racketcs.h"

#include "run.c"

#include <mach-o/dyld.h>
#include <mach-o/getsect.h>

static long find_section(char *segname, char *sectname)
{
  const struct section_64 *s = getsectbyname(segname, sectname);
  if (s)
    return s->offset;

  fprintf(stderr, "could not find segment %s section %s\n",
          segname, sectname);
  exit(1);
}

#endif

int main(int argc, char **argv)
{
  racket_boot_arguments_t ba;

  memset(&ba, 0, sizeof(ba));

  ba.boot1_path = racket_get_self_exe_path(argv[0]);
  ba.boot2_path = ba.boot1_path;
  ba.boot3_path = ba.boot1_path;

  ba.boot1_offset = find_section("__DATA", "__rktboot1");
  ba.boot2_offset = find_section("__DATA", "__rktboot2");
  ba.boot3_offset = find_section("__DATA", "__rktboot3");

  ba.exec_file = argv[0];
  ba.run_file = argv[0];

  racket_boot(&ba);

  declare_modules(); /* defined by "run.c" */

  ptr mod = Scons(Sstring_to_symbol("quote"),
                  Scons(Sstring_to_symbol("run"),
                        Snil));

  racket_dynamic_require(mod, Sfalse);

  return 0;
}
}}

@; ============================================================

@subsection{访问 Windows 资源}

On Windows, data is most readily added to an executable as a resource.
The following code demonstrates how to find the path to the current
executable and how to find a resource in the executable by identifying
number, type (usually @cpp{1}) and encoding (usual @cpp{1033}):

@filebox["main.c"]{
@verbatim[#:indent 2]{
/* forward declaration for internal helper */
static DWORD find_by_id(HANDLE fd, DWORD rsrcs, DWORD pos, int id);

static wchar_t *get_self_executable_path()
{
  wchar_t *path;
  DWORD r, sz = 1024;

  while (1) {
    path = (wchar_t *)malloc(sz * sizeof(wchar_t));
    r = GetModuleFileNameW(NULL, path, sz);
    if ((r == sz)
        && (GetLastError() == ERROR_INSUFFICIENT_BUFFER)) {
      free(path);
      sz = 2 * sz;
    } else
      break;
  }

  return path;
}

static long find_resource_offset(wchar_t *path, int id, int type, int encoding)
{
  /* Find the resource of type `id` */
  HANDLE fd;

  fd = CreateFileW(path, GENERIC_READ,
                   FILE_SHARE_READ | FILE_SHARE_WRITE,
                   NULL,
                   OPEN_EXISTING,
                   0,
                   NULL);

  if (fd == INVALID_HANDLE_VALUE)
    return 0;
  else {
    DWORD val, got, sec_pos, virtual_addr, rsrcs, pos;
    WORD num_sections, head_size;
    char name[8];

    SetFilePointer(fd, 60, 0, FILE_BEGIN);
    ReadFile(fd, &val, 4, &got, NULL);
    SetFilePointer(fd, val+4+2, 0, FILE_BEGIN); /* Skip "PE\0\0" tag and machine */
    ReadFile(fd, &num_sections, 2, &got, NULL);
    SetFilePointer(fd, 12, 0, FILE_CURRENT); /* time stamp + symbol table */
    ReadFile(fd, &head_size, 2, &got, NULL);

    sec_pos = val+4+20+head_size;
    while (num_sections--) {
      SetFilePointer(fd, sec_pos, 0, FILE_BEGIN);
      ReadFile(fd, &name, 8, &got, NULL);
      if ((name[0] == '.')
          && (name[1] == 'r')
          && (name[2] == 's')
          && (name[3] == 'r')
          && (name[4] == 'c')
          && (name[5] == 0)) {
        SetFilePointer(fd, 4, 0, FILE_CURRENT); /* skip virtual size */
        ReadFile(fd, &virtual_addr, 4, &got, NULL);
        SetFilePointer(fd, 4, 0, FILE_CURRENT); /* skip file size */
        ReadFile(fd, &rsrcs, 4, &got, NULL);
        SetFilePointer(fd, rsrcs, 0, FILE_BEGIN);

        /* We're at the resource table; step through 3 layers */
        pos = find_by_id(fd, rsrcs, rsrcs, id);
	if (pos) {
	  pos = find_by_id(fd, rsrcs, pos, type);
	  if (pos) {
	    pos = find_by_id(fd, rsrcs, pos, encoding);

	    if (pos) {
	      /* pos is the reource data entry */
	      SetFilePointer(fd, pos, 0, FILE_BEGIN);
	      ReadFile(fd, &val, 4, &got, NULL);
	      pos = val - virtual_addr + rsrcs;

	      CloseHandle(fd);

	      return pos;
	    }
	  }
	}

	break;
      }
      sec_pos += 40;
    }

    /* something went wrong */
    CloseHandle(fd);
    return -1;
  }
}

/* internal helper function */
static DWORD find_by_id(HANDLE fd, DWORD rsrcs, DWORD pos, int id)
{
  DWORD got, val;
  WORD name_count, id_count;

  SetFilePointer(fd, pos + 12, 0, FILE_BEGIN);
  ReadFile(fd, &name_count, 2, &got, NULL);
  ReadFile(fd, &id_count, 2, &got, NULL);

  pos += 16 + (name_count * 8);
  while (id_count--) {
    ReadFile(fd, &val, 4, &got, NULL);
    if (val == id) {
      ReadFile(fd, &val, 4, &got, NULL);
      return rsrcs + (val & 0x7FFFFFF);
    } else {
      ReadFile(fd, &val, 4, &got, NULL);
    }
  }

  return 0;
}
}}
