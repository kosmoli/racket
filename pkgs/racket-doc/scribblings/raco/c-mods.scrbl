#lang scribble/doc
@(require scribble/manual
          "common.rkt"
          scribble/bnf)

@title[#:tag "c-mods"]{通过 C 嵌入模块}

@margin-note{@exec{raco ctool} 由 @filepath{cext-lib} 包提供。}

@DFlag{c-mods} 模式用于 @exec{raco ctool}，接受一组 Racket
模块并生成一个 C 源文件，可作为嵌入 Racket 运行时的程序的一部分。
参见 @secref[#:doc inside-doc "embedding"]（位于 @other-manual[inside-doc] 中）了解嵌入程序的说明。
@DFlag{mods} 模式类似，但它生成已编译模块的原始字节，而不将字节编码在 C 声明中。

生成的源文件或编译文件嵌入指定的模块。生成的 C 源文件定义了一个 @tt{declare_modules} 函数，
将模块声明放入命名空间。因此，使用 @exec{raco ctool --c-mods} 的输出，
程序可以通过一组模块嵌入 Racket，从而不需要 @filepath{collects}
目录在运行时加载模块。

如果嵌入的模块引用运行时文件，可以通过向 @exec{raco ctool --c-mods} 提供 @DFlag{runtime}
参数来收集这些文件。指定一个目录 @nonterm{dir} 来存放文件。
通常，@nonterm{dir} 是一个相对路径，文件在运行时在可执行文件的相对位置 @nonterm{dir} 中找到，
但可以使用 @DFlag{runtime-access} 指定单独的运行时路径（通常是相对路径）。

通常，@exec{raco ctool --c-mods} 常与 @DPFlag{lib} 配合使用，以指定基于 collection 的模块路径。例如：

@commandline{raco ctool --c-mods base.c ++lib racket/base}

生成一个 @filepath{base.c}，其 @tt{declare_modules} 函数使得
@racketmodname[racket/base] 可通过嵌入应用程序内的
@tt{scheme_namespace_require} 或 @tt{scheme_dynamic_require} 函数使用。

当提供给 @exec{raco ctool --c-mods} 一个模块文件时，
@tt{declare_modules} 使用模块文件的符号名称声明一个模块。例如：

@commandline{raco ctool --c-mods base.c hello.rkt}

创建一个定义模块 @racket['hello] 的 @tt{declare_modules}，
可通过 @racket[(namespace-require ''hello)] 将其 require 到当前命名空间，
同样可在 C 层：

@verbatim[#:indent 2]{
  p = scheme_make_pair(scheme_intern_symbol("quote"),
                       scheme_make_pair(scheme_intern_symbol("hello"),
                                        scheme_make_null()));
  scheme_namespace_require(p);
}
