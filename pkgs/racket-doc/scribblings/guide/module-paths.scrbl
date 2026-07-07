#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "module-paths"]{Module Paths}

@deftech{module path}（模块路径）是对模块的引用，用于 @racket[require] 或作为 @racket[module] 形式中的 @racket[_initial-module-path]。它可以是以下几种形式之一：

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[#:literals (quote) (#,(racket quote) id)]{

一个带引号标识符的 @tech{module path} 使用标识符引用一个非文件的 @racket[module] 声明。这种模块引用形式在 @tech{REPL} 中最有意义。

@examples[
(module m racket
  (provide color)
  (define color "blue"))
(module n racket
  (require 'm)
  (printf "my favorite color is ~a\n" color))
(require 'n)
]}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[rel-string]{

字符串形式的 @tech{module path} 是使用 Unix 风格约定的相对路径：@litchar{/} 是路径分隔符，@litchar{..} 指父目录，@litchar{.} 指同一目录。@racket[rel-string] 不能以路径分隔符开头或结尾。

路径相对于外部文件（如果有的话），或相对于当前目录。（更准确地说，路径相对于 @racket[(current-load-relative-directory)] 的值，该值在加载文件时设置。）

@secref["module-basics"] 展示了使用相对路径的示例。

如果相对路径以 @filepath{.ss} 后缀结尾，它会被转换为 @filepath{.rkt}。如果实现所引用模块的文件实际以 @filepath{.ss} 结尾，则在尝试加载文件时后缀会被改回来（但 @filepath{.rkt} 后缀优先）。这种双向转换提供了与旧版本 Racket 的兼容性。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[id]{

不带引号标识符的 @tech{module path} 引用已安装的库。@racket[id] 被限制为仅包含 ASCII 字母、ASCII 数字、@litchar{+}、@litchar{-}、@litchar{_} 和 @litchar{/}，其中 @litchar{/} 分隔标识符内的路径元素。这些元素引用 @tech{collection}（集合）和子 @tech{collection}，而非目录和子目录。

此形式的一个示例是 @racket[racket/date]。它引用源文件为 @filepath{racket} 集合中 @filepath{date.rkt} 文件的模块，该集合是作为 Racket 的一部分安装的。@filepath{.rkt} 后缀会自动添加。

此形式的另一个示例是 @racketmodname[racket]，它通常在初始导入时使用。路径 @racketmodname[racket] 是 @racket[racket/main] 的简写；当 @racket[id] 没有 @litchar{/} 时，@racket[/main] 会自动添加到末尾。因此，@racketmodname[racket] 或 @racket[racket/main] 引用源文件为 @filepath{racket} 集合中 @as-index{@filepath{main.rkt}} 文件的模块。

@examples[
(module m racket
  (require racket/date)

  (printf "Today is ~s\n"
          (date->string (seconds->date (current-seconds)))))
(require 'm)
]

当模块的完整路径以 @filepath{.rkt} 结尾时，如果该文件不存在但存在一个 @filepath{.ss} 后缀的文件，则会自动替换为 @filepath{.ss} 后缀。这种转换提供了与旧版本 Racket 的兼容性。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[#:literals (lib)
             (lib rel-string)]{

类似于不带引号标识符的路径，但以字符串而非标识符表示。此外，@racket[rel-string] 可以以文件后缀结尾，在这种情况下不会自动添加 @filepath{.rkt}。

此形式的示例包括 @racket[(lib "racket/date.rkt")] 和 @racket[(lib "racket/date")]，它们等价于 @racket[racket/date]。其他示例包括 @racket[(lib "racket")]、@racket[(lib "racket/main")] 和 @racket[(lib "racket/main.rkt")]，它们都等价于 @racketmodname[racket]。

@examples[
(module m (lib "racket")
  (require (lib "racket/date.rkt"))

  (printf "Today is ~s\n"
          (date->string (seconds->date (current-seconds)))))
(require 'm)
]}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[#:literals (planet)
             (planet id)]{

访问通过 @|PLaneT| 服务器分发的第三方库。该库在首次需要时下载，之后使用本地副本。

@racket[id] 编码了由 @litchar{/} 分隔的多条信息：包的所有者，然后是带有可选版本信息的包名，以及包内特定库的可选路径。与 @racket[id] 作为 @racket[lib] 路径的简写一样，@filepath{.rkt} 后缀会自动添加，如果未提供子路径元素，则使用 @racketidfont{/main} 作为路径。

@examples[
(eval:alts
 (module m (lib "racket")
   (code:comment @#,t{Use @filepath{schematics}'s @filepath{random.plt} 1.0, file @filepath{random.rkt}:})
   (require (planet schematics/random:1/random))
   (display (random-gaussian)))
 (void))
(eval:alts
 (require 'm)
 (display 0.9050686838895684))
]

与其他形式一样，如果不存在以 @filepath{.rkt} 结尾的实现文件，则可以自动替换以 @filepath{.ss} 结尾的实现文件。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[#:literals (planet)
             (planet package-string)]{

类似于 @racket[planet] 的符号形式，但使用字符串而非标识符。此外，@racket[package-string] 可以以文件后缀结尾，在这种情况下不会添加 @filepath{.rkt}。

与其他形式一样，@filepath{.ss} 扩展名会被转换为 @filepath{.rkt}，而如果不存在以 @filepath{.rkt} 结尾的实现文件，则可以自动替换以 @filepath{.ss} 结尾的实现文件。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform/subs[#:literals (planet = + -)
                  (planet rel-string (user-string pkg-string vers ...))
                  ([vers nat
                         (nat nat)
                         (= nat)
                         (+ nat)
                         (- nat)])]{

从 @|PLaneT| 服务器访问库的更通用形式。在此通用形式中，@|PLaneT| 引用以类似 @racket[lib] 引用的相对路径开始，但路径之后是关于库的生产者、包和版本的信息。指定的包按需下载和安装。

@racket[vers] 指定了对包可接受版本的约束，其中版本号是非负整数的序列，约束决定了序列中每个元素的允许值。如果未对特定元素提供约束，则允许任何版本；特别是，省略所有 @racket[vers] 意味着任何版本都可接受。强烈建议至少指定一个 @racket[vers]。

对于版本约束，普通的 @racket[nat] 与 @racket[(+ nat)] 相同，匹配版本号对应元素的 @racket[nat] 或更高值。@racket[(_start-nat _end-nat)] 匹配 @racket[_start-nat] 到 @racket[_end-nat] 范围内的任何数字（含两端）。@racket[(= nat)] 仅精确匹配 @racket[nat]。@racket[(- nat)] 匹配 @racket[nat] 或更低值。

@examples[
(eval:alts
 (module m (lib "racket")
   (require (planet "random.rkt" ("schematics" "random.plt" 1 0)))
   (display (random-gaussian)))
 (void))
(eval:alts
 (require 'm)
 (display 0.9050686838895684))
]

自动的 @filepath{.ss} 和 @filepath{.rkt} 转换与其他形式相同。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[#:literals (file)
             (file string)]{

引用一个文件，其中 @racket[string] 是使用当前平台约定的相对或绝对路径。此形式不可移植，当普通的、可移植的 @racket[rel-string] 足够时，@italic{不}应该使用它。

自动的 @filepath{.ss} 和 @filepath{.rkt} 转换与其他形式相同。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform/subs[#:literals (submod)
                  (@#,elemtag["submod"]{@racket[submod]} base element ...+)
                  ([base module-path
                         "."
                         ".."]
                   [element id
                            ".."])]{

引用 @racket[base] 的子模块。@racket[submod] 内的 @racket[element] 序列指定了到达最终子模块的子模块名称路径。

@examples[
  (module zoo racket
    (module monkey-house racket
      (provide monkey)
      (define monkey "Curious George")))
  (require (submod 'zoo monkey-house))
  monkey
]

在 @racket[submod] 中使用 @racket["."] 作为 @racket[base] 代表外部模块。使用 @racket[".."] 作为 @racket[base] 等同于使用 @racket["."] 后跟一个额外的 @racket[".."]。当形式为 @racket[(#,(racket quote) id)] 的路径引用子模块时，它等价于 @racket[(submod "." id)]。

使用 @racket[".."] 作为 @racket[element] 会取消一个子模块步骤，实际上引用外部模块。例如，@racket[(submod "..")] 引用路径所在子模块的外部模块。

@examples[
  (module zoo racket
    (module monkey-house racket
      (provide monkey)
      (define monkey "Curious George"))
    (module crocodile-house racket
      (require (submod ".." monkey-house))
      (provide dinner)
      (define dinner monkey)))
  (require (submod 'zoo crocodile-house))
  dinner
]}
