#lang scribble/doc
@(require scribble/manual 
          scribble/eval 
          "guide-utils.rkt"
          "module-hier.rkt"
          (for-label setup/dirs
                     setup/link
                     racket/date
                     (only-in scribble/manual
                              defmodule)))

@title[#:tag "module-basics"]{模块基础}

每个 Racket 模块通常位于其自己的文件中。例如，假设文件 @filepath{cake.rkt} 包含以下模块：

@racketmod[
#:file "cake.rkt"
racket

(provide print-cake)

(code:comment @#,t{draws a cake with @racket[n] candles})
(define (print-cake n)
  (show "   ~a   " n #\.)
  (show " .-~a-. " n #\|)
  (show " | ~a | " n #\space)
  (show "---~a---" n #\-))

(define (show fmt n ch)
  (printf fmt (make-string n ch))
  (newline))
]

然后，其他模块可以导入 @filepath{cake.rkt} 来使用 @racket[print-cake] 函数，因为 @filepath{cake.rkt} 中的 @racket[provide] 行显式导出了定义 @racket[print-cake]。@racket[show] 函数对 @filepath{cake.rkt} 是私有的（即不能从其他模块使用），因为 @racket[show] 未被导出。

以下 @filepath{random-cake.rkt} 模块导入 @filepath{cake.rkt}：

@racketmod[
#:file "random-cake.rkt"
racket

(require "cake.rkt")

(print-cake (random 30))
]

导入中的相对引用 @racket["cake.rkt"] 在 @filepath{cake.rkt} 和 @filepath{random-cake.rkt} 模块位于同一目录时有效。所有平台上都使用 Unix 风格的相对路径进行相对模块引用，类似于 HTML 页面中的相对 URL。

@; ----------------------------------------
@section[#:tag "module-org"]{组织模块}

@filepath{cake.rkt} 和 @filepath{random-cake.rkt} 示例演示了将程序组织成模块的最常见方式：将所有模块文件放在单个目录中（可能带有子目录），然后让模块通过相对路径相互引用。模块目录可以充当项目，因为它可以在文件系统上移动或复制到其他机器，并且相对路径保持模块之间的连接。

再举一个例子，如果你正在构建一个糖果分类程序，你可能有一个主 @filepath{sort.rkt} 模块，它使用其他模块来访问糖果数据库和控制分类机。如果糖果数据库模块本身组织成处理条形码和制造商信息的子模块，则数据库模块可以是 @filepath{db/lookup.rkt}，它使用辅助模块 @filepath{db/barcodes.rkt} 和 @filepath{db/makers.rkt}。类似地，分类机驱动程序 @filepath{machine/control.rkt} 可能使用辅助模块 @filepath{machine/sensors.rkt} 和 @filepath{machine/actuators.rkt}。

@centerline[module-hierarchy]

@filepath{sort.rkt} 模块使用相对路径 @filepath{db/lookup.rkt} 和 @filepath{machine/control.rkt} 从数据库和机器控制库导入：

@racketmod[
#:file "sort.rkt"
racket
(require "db/lookup.rkt" "machine/control.rkt")
....]

@filepath{db/lookup.rkt} 模块同样使用相对于其自身源的路径来访问 @filepath{db/barcodes.rkt} 和 @filepath{db/makers.rkt} 模块：


@racketmod[
#:file "db/lookup.rkt"
racket
(require "barcode.rkt" "makers.rkt")
....]

@filepath{machine/control.rkt} 也是如此：

@racketmod[
#:file "machine/control.rkt"
racket
(require "sensors.rkt" "actuators.rkt")
....]

Racket 工具都自动使用相对路径。例如，

@commandline{racket sort.rkt}

在命令行上运行 @filepath{sort.rkt} 程序并自动加载和编译所需的模块。对于足够大的程序，从源代码编译可能耗时太长，因此使用

@commandline{raco make sort.rkt}

@margin-note{参见 @secref[#:doc '(lib "scribblings/raco/raco.scrbl") "make"] 了解更多关于 @exec{raco make} 的信息。}

将 @filepath{sort.rkt} 及其所有依赖项编译为字节码文件。运行 @exec{racket sort.rkt} 将在字节码文件存在时自动使用它们。

@; ----------------------------------------
@section{库集合}

@deftech{集合}是已安装库模块的分层分组。@tech{集合}中的模块通过无引号、无后缀的路径引用。例如，以下模块引用 @filepath{racket} @tech{集合}中的 @filepath{date.rkt} 库：

@racketmod[
racket

(require racket/date)

(printf "Today is ~s\n"
        (date->string (seconds->date (current-seconds))))
]

当你搜索在线 Racket 文档时，搜索结果会指示提供每个绑定的模块。或者，如果你通过点击超链接到达某个绑定的文档，可以将鼠标悬停在绑定名称上以找出提供它的模块。

像 @racketmodname[racket/date] 这样的模块引用看起来像标识符，但其处理方式与 @racket[printf] 或 @racket[date->string] 不同。相反，当 @racket[require] 看到无引号的模块引用时，它会将引用转换为基于集合的模块路径：

@itemlist[

 @item{首先，如果无引号路径不包含 @litchar{/}，则 @racket[require] 会自动向引用添加 @filepath{/main}。例如，@racket[(require @#,racketmodname[slideshow #:indirect])] 等价于 @racket[(require slideshow/main)]。}

 @item{其次，@racket[require] 隐式地向路径添加 @filepath{.rkt} 后缀。}

 @item{最后，@racket[require] 通过搜索已安装的 @tech{集合} 来解析路径，而不是将路径视为相对于封闭模块的路径。}

]

作为初步近似，@tech{集合}被实现为文件系统目录。例如，@filepath{racket} 集合主要位于 Racket 安装的 @filepath{collects} 目录中的 @filepath{racket} 目录内，如

@racketmod[
racket

(require setup/dirs)

(build-path (find-collects-dir) (code:comment @#,t{main collection directory})
            "racket")
]

所报告的。

然而，Racket 安装的 @filepath{collects} 目录只是 @racket[require] 查找集合目录的一个位置。其他位置包括 @racket[(find-user-collects-dir)] 报告的特定于用户的目录，以及通过 @envvar{PLTCOLLECTS} 搜索路径配置的目录。最后，也是最常见的是，集合通过已安装的 @tech{包}找到。

@; ----------------------------------------
@section[#:tag "packages-and-collections"]{包与集合}

@deftech{包}是通过 Racket 包管理器安装的一组库（或作为预安装在 Racket 发行版中）。例如，@racketmodname[racket/gui] 库由 @filepath{gui} 包提供，而 @racketmodname[parser-tools/lex #:indirect] 由 @filepath{parser-tools} 库提供。@margin-note{更准确地说，@racketmodname[racket/gui #:indirect] 由 @filepath{gui-lib} 提供，@racketmodname[parser-tools/lex #:indirect] 由 @filepath{parser-tools-lib} 提供，@filepath{gui} 和 @filepath{parser-tools} 包用文档扩展了 @filepath{gui-lib} 和 @filepath{parser-tools-lib}。}

Racket 程序不直接引用 @tech{包}。相反，程序通过 @tech{集合}引用库，添加或删除 @tech{包}会更改可用的基于集合的库集合。单个包可以在多个集合中提供库，两个不同的包可以在同一集合中提供库（但不能是相同的库，包管理器确保已安装的包在该级别不冲突）。

有关包的更多信息，参见 @other-manual['(lib "pkg/scribblings/pkg.scrbl")]。

@; ----------------------------------------
@section[#:tag "link-collection"]{添加集合}

回顾 @secref["module-org"] 中的糖果分类示例，假设 @filepath{db/} 和 @filepath{machine/} 中的模块需要一组通用辅助函数。辅助函数可以放在 @filepath{utils/} 目录中，@filepath{db/} 或 @filepath{machine/} 中的模块可以使用以 @filepath{../utils/} 开头的相对路径访问实用程序模块。只要一组模块在单个项目中协同工作，最好坚持使用相对路径。程序员可以遵循相对路径引用，而无需了解你的 Racket 配置。

有些库旨在跨多个项目使用，因此将库源代码放在与其使用相同的目录中没有意义。在这种情况下，最佳选择是添加一个新的 @tech{集合}。库放入集合后，可以像 Racket 发行版中的库一样使用无引号路径引用。

你可以通过将文件放置在 Racket 安装目录或 @racket[(get-collects-search-dirs)] 报告的目录之一中来添加新集合。或者，你可以通过设置 @envvar{PLTCOLLECTS} 环境变量来添加到搜索目录列表中。@margin-note*{如果你设置 @envvar{PLTCOLLECTS}，请在值开头包含一个空路径（Unix 和 Mac OS 用冒号，Windows 用分号）以保留原始搜索路径。} 然而，最佳选择是添加 @tech{包}。

创建包 @emph{不}意味着你必须在包服务器上注册或执行将源代码复制到存档格式的打包步骤。创建包可以简单地意味着使用包管理器使你的库从当前源代码位置作为集合在本地可访问。

例如，假设你有一个目录 @filepath{/usr/molly/bakery}，其中包含 @filepath{cake.rkt} 模块（来自本节 @seclink["module-basics"]{开头}）和其他相关模块。要使这些模块作为 @filepath{bakery} 集合可用，可以

@itemlist[

 @item{使用 @exec{raco pkg} 命令行工具：

        @commandline{raco pkg install --link /usr/molly/bakery}

       其中当提供的路径包含目录分隔符时，@DFlag{link} 标志实际上不是必需的。}

 @item{使用 DrRacket 中 @onscreen{File} 菜单的 @onscreen{Package Manager} 项。在 @onscreen{Do What I Mean} 面板中，点击 @onscreen{Browse...}，选择 @filepath{/usr/molly/bakery} 目录，然后点击 @onscreen{Install}。}

]

之后，任何模块中的 @racket[(require bakery/cake)] 都会从 @filepath{/usr/molly/bakery/cake.rkt} 导入 @racket[print-cake] 函数。

默认情况下，你安装的目录名称既用作 @tech{包}名称，也用作包提供的 @tech{集合}名称。此外，包管理器通常默认为仅对当前用户安装，而不是对 Racket 安装的所有用户安装。更多信息参见 @other-manual['(lib "pkg/scribblings/pkg.scrbl")]。

如果你打算将库分发给他人，请仔细选择集合和包名称。集合命名空间是分层的，但顶级集合名称是全局的，包命名空间是平面的。考虑将一次性库放在像 @filepath{molly} 这样的顶级名称下，以标识生产者。在生产烘焙食品库的权威集合时使用 @filepath{bakery} 这样的集合名称。

将库放入 @tech{集合} 后，你仍然可以使用 @exec{raco make} 编译库源代码，但使用 @exec{raco setup} 更好更方便。@exec{raco setup} 命令接受集合名称（而不是文件名）并编译集合中的所有库。此外，@exec{raco setup} 可以为集合构建文档并将其添加到文档索引中，如集合中的 @filepath{info.rkt} 模块所指定的。更多信息参见 @other-manual['(lib "scribblings/raco/raco.scrbl")] 中的 @secref["setup"]。

@; ----------------------------------------
@section[#:tag "intracollection"]{集合内的模块引用}

当集合内的模块引用同一集合中的另一个模块时，相对路径或集合路径都可以工作。例如，引用同一集合中 @filepath{db/lookup.rkt} 和 @filepath{machine/control.rkt} 模块的 @filepath{sort.rkt} 模块可以像 @secref["module-org"] 中那样使用相对路径书写：

@racketmod[
#:file "sort.rkt"
racket
(require "db/lookup.rkt" "machine/control.rkt")
....]

或者，如果集合名为 @filepath{candy}，则 @filepath{sort.rkt} 可以使用集合路径导入两个模块：

@racketmod[
#:file "sort.rkt"
racket
(require candy/db/lookup candy/machine/control)
....]

对于大多数目的，这些选择的工作方式相同，但也有例外。使用 @seclink[#:doc '(lib "scribblings/scribble/scribble.scrbl") "top"]{Scribble} 编写文档时，必须对 @racket[defmodule] 和类似形式使用集合路径；这部分是因为文档旨在供客户端程序员阅读，因此应出现基于集合的名称。同时，对于 @racket[require]，在集合内使用相对路径进行引用往往是最灵活的方法，但也有注意事项。

相对路径引用的工作方式与相对 URL 引用非常相似：引用基于封闭模块的访问方式展开。如果封闭模块通过文件系统路径访问，则 @racket[require] 中的相对路径与该文件系统路径组合以形成新的文件系统路径。如果封闭模块通过集合路径访问，则 @racket[require] 中的相对路径与该集合路径组合以形成新的集合路径。集合路径又转换为文件系统路径，因此从文件系统路径还是集合路径开始通常没有区别。不幸的是，路径解析的固有复杂性在某些情况下可能造成差异：

@itemlist[

 @item{通过软链接、多个挂载点或不区分大小写的文件系统（在不隐式大小写规范化路径的操作系统上），可能存在多个引用同一模块文件的文件系统路径。

       例如，当当前目录是 @filepath{candy} 集合的目录时，@exec{racket} 在启动时接收的当前目录路径可能导致 @exec{racket sort.rkt} 使用与 @exec{racket -l candy/sort} 通过库集合搜索路径找到的不同的文件系统路径。在这种情况下，如果 @filepath{sort.rkt} 通过相对路径引用和基于集合的引用引导到某些模块，则这些可能解析到同一源模块的不同实例，通过多次实例化造成混淆。}

 @item{当使用 @seclink["exe" #:doc '(lib "scribblings/raco/raco.scrbl")]{@exec{raco exe}} 和 @seclink["exe-dist" #:doc '(lib "scribblings/raco/raco.scrbl")]{@exec{raco distribute}} 创建在不同机器上运行的可执行文件时，当前机器的路径可能与目标机器的路径无关。@exec{raco exe} 工具对通过文件系统路径引用的模块与通过集合路径引用的模块处理方式不同，因为只有后者在运行时通过反射操作访问才有意义。

       例如，如果 @exec{raco exe sort.rkt} 创建的可执行文件在运行时使用 @racket[(dynamic-require 'candy/db/lookup #f)]，那么当 @filepath{db/lookup.rkt} 在可执行文件创建时相对于文件系统路径 @racket{sort.rkt] 解析时，该 @racket[dynamic-require] 将失败。}

]

仅使用基于集合的路径（包括使用像 @exec{racket -l candy/sort} 这样的 shell 命令，而不是 @exec{racket sort.rkt}）可以避免所有问题，但这样你必须在已安装的集合内开发模块，这通常不方便。一致使用相对路径引用往往是最方便的，同时在大多数情况下仍然有效。
