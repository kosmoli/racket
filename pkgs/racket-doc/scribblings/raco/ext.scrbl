#lang scribble/doc
@(require scribble/manual "common.rkt")

@title[#:tag "ext"]{通过 C 编译为本地代码}

@DFlag{extension}/@Flag{e} 模式用于 @exec{raco ctool} 时类似于 @exec{raco make --zo}（参见 @secref["zo"]），区别在于模块的编译形式是本地代码共享库而不是 bytecode。本地代码在宿主机系统 C 编译器的帮助下生成。此模式很少有用，因为 Racket 内置的 JIT（just-in-time）编译器在支持的平台上以更低的开销提供更好的性能（参见 @secref[#:doc '(lib "scribblings/guide/guide.scrbl") "performance"]）。

与 @DFlag{zo} 模式一样，默认情况下生成的共享库与源文件放在同一目录——而在加载源文件时这并非其自动被找到的位置。使用 @as-index{@DFlag{auto-dir}} 标志将输出重定向到 @racket[(build-path "compiled" "native" (system-library-subpath))] 子目录，在那里加载源文件时会自动找到它。

@DFlag{c-source}/@Flag{c} 模式用于 @exec{raco ctool} 时类似于 @DFlag{extension}/@Flag{e} 模式，区别在于编译在生成 C 代码后停止。

适用于 @DFlag{cc} 和 @DFlag{ld} 模式的所有 C 编译器和链接器标志也适用于 @DFlag{extension} 模式；参见 @secref["cc"]。此外，一些标志提供了对 Racket 到 C 编译器的控制：@as-index{@DFlag{no-prop}}、@as-index{@DFlag{inline}}、@as-index{@DFlag{no-prim}}、@as-index{@DFlag{stupid}}、@as-index{@DFlag{unsafe-disable-interrupts}}、@as-index{@DFlag{unsafe-skip-tests}} 和 @as-index{@DFlag{unsafe-fixnum-arithmetic}}。使用 @exec{mzc --help} 可查看每个标志的说明。

