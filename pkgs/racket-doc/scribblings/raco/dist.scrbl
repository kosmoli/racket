#lang scribble/doc
@(require scribble/manual "common.rkt" (for-label racket/runtime-path))

@title[#:tag "exe-dist"]{@exec{raco distribute} 分发独立可执行文件}

@exec{raco distribute} 命令将由 @seclink["exe"]{@exec{raco exe}} 创建的独立可执行文件与所有必需的共享库以及通过 @racket[define-runtime-path] 声明的任何运行时文件组合在一起。生成的包可以移动到运行相同操作系统的其他机器。

@margin-note{在 Windows 和 Mac OS 上，本机库倾向于包含在 @exec{raco distribute} 的输出中。在 Unix 平台上，本机库倾向于不包含在内，因此将在主机上使用系统库。差异在于 Racket 安装本身是否包含捆绑的本机库或依赖于系统安装的库。在 Racket 的 @filepath{lib} 目录中添加指向系统安装的库的符号链接会导致该库包含在由 @exec{raco distribute} 创建的发行目录中；另见 @racket[define-runtime-path]。}

执行 @exec{raco distribute} 命令后，提供一个目录来包含用于分发的组合文件。每个命令行参数是要包含在分发中的可执行文件，因此可以打包多个可执行文件。例如，在 Windows 上，

@commandline{raco distribute greetings hello.exe goodbye.exe}

创建目录 @filepath{greetings}（如果目录不存在），并将可执行文件 @filepath{hello.exe} 和 @filepath{goodbye.exe} 复制到 @filepath{greetings} 中。它还会创建一个 @filepath{lib} 子目录（如果需要），在这种情况下，它会调整复制的 @filepath{hello.exe} 和 @filepath{goodbye.exe} 以使用 @filepath{lib} 中的 DLL。

所需支持文件的部分取决于为分发创建可执行文件的方式。向 @exec{raco exe} 提供 @DFlag{embed-dlls} 或 @DFlag{orig-exe} 会减少对支持文件的需求，但代价是如果分发包含多个可执行文件，则分发会更大。

分发目录内的文件布局是特定于平台的：

@itemize[

@item{在 Windows 上，可执行文件直接放入分发目录中，DLL 和其他运行时文件放入 @filepath{lib} 子目录。}

@item{在 Mac OS 上，GUI 可执行文件放入分发目录，其他可执行文件放入 @filepath{bin} 子目录，框架（即共享库）与其他运行时文件一起放入 @filepath{lib} 子目录。作为特殊情况，如果分发具有单个 @DFlag{gui-exe} 可执行文件，则 @filepath{lib} 目录隐藏在应用程序包内。}

@item{在 Unix 上，可执行文件放入 @filepath{bin} 子目录，共享库（如果有）与其他运行时文件一起放入 @filepath{lib} 子目录，并且打包的可执行文件放入具有版本特定名称的 @filepath{lib/plt} 子目录。此布局符合 Unix 安装约定；共享库和打包可执行文件的版本特定名称意味着分发可以安全地解包到目标机器上的标准位置，而不会与现有的 Racket 安装或由 @exec{raco exe} 创建的其他可执行文件冲突。}

]

分发还有一个 @filepath{collects} 目录，用作打包可执行文件的主库集合目录。默认情况下，该目录为空。使用 @as-index{@DPFlag{collects-copy}} 标志的 @exec{raco distribute} 提供要复制到分发的 @filepath{collects} 目录的目录。@DPFlag{collects-copy} 标志可以多次使用以提供多个目录。

当多个可执行文件一起分发时，使用 @exec{raco exe} 单独创建可执行文件可能会生成多个由多个可执行文件使用的基于集合的库的副本。要共享库代码，请使用 @as-index{@DFlag{collects-dest}} 标志与 @exec{raco exe} 指定库副本的目标目录，并为每个可执行文件指定相同的目录（以便所有可执行文件使用的库集合汇集在一起）。最后，在使用 @exec{raco distribute} 打包分发时，使用 @DPFlag{collects-copy} 标志在分发中包含复制的库。

@; ----------------------------------------------------------------------

@include-section["dist-api.scrbl"]
@include-section["bundle-api.scrbl"]
