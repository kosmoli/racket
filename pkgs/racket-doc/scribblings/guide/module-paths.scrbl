#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "module-paths"]{模块路径}

@deftech{模块路径} 是用于引用模块的表达式，可用于 @racket[require] 或
@racket[module] 形式中的 @racket[_initial-module-path]。可以是以下任意形式：

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[#:literals (quote) (#,(racket quote) id)]{

quoted identifier 形式的 @tech{module path} 使用标识符引用非文件 @racket[module]。
这种模块引用形式在 @tech{REPL} 中最常用。

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

string 形式的 @tech{module path} 是使用 Unix 风格惯例的相对路径：
@litchar{/} 是路径分隔符，@litchar{..} 指父目录，@litchar{.} 指当前目录。
@racket[rel-string] 不能以路径分隔符开头或结尾。

The path is relative to the enclosing file, if any, or it is relative
to the current directory. (More precisely, the path is relative to the
value of @racket[(current-load-relative-directory)], which is set
while loading a file.)

@secref["module-basics"] 展示使用相对路径的示例。

If a relative path ends with a @filepath{.ss} suffix, it is converted
to @filepath{.rkt}. If the file that implements the referenced module
actually ends in @filepath{.ss}, the suffix will be changed back when
attempting to load the file (but a @filepath{.rkt} suffix takes
precedence). This two-way conversion provides compatibility with older
versions of Racket.}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[id]{

unquoted identifier 形式的 @tech{module path} 引用已安装的库。
@racket[id] 只能包含 ASCII 字母、数字、@litchar{+}, @litchar{-}, @litchar{_},
和 @litchar{/}, 其中 @litchar{/} 分隔标识符内的路径元素。
这些元素引用 @tech{collection}s 和 sub-@tech{collections}，而非目录和子目录。

这种形式的例子是 @racket[racket/date]。它引用 @filepath{racket} collection 中
@filepath{date.rkt} 文件的模块，该 collection 作为 Racket 的一部分安装。
@filepath{.rkt} 后缀会自动添加。

另一种常见形式是 @racketmodname[racket]，常用于初始导入。
路径 @racketmodname[racket] 是 @racket[racket/main] 的缩写；
当 @racket[id] 中没有 @litchar{/} 时，@racket[/main] 会自动添加到末尾。
因此，@racketmodname[racket] 或 @racket[racket/main] 引用 @filepath{racket}
collection 中 @as-index{@filepath{main.rkt}} 文件的模块。

@examples[
(module m racket
  (require racket/date)

  (printf "Today is ~s\n"
          (date->string (seconds->date (current-seconds)))))
(require 'm)
]

When the full path of a module ends with @filepath{.rkt}, if no such
file exists but one does exist with the @filepath{.ss} suffix, then
the @filepath{.ss} suffix is substituted automatically. This
transformation provides compatibility with older versions of Racket.}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[#:literals (lib)
             (lib rel-string)]{

类似 unquoted identifier 路径，但使用 string 而非 identifier 表示。
此外，@racket[rel-string] 可以以文件后缀结尾，此情况下不自动添加 @filepath{.rkt}。

这种形式的例子包括 @racket[(lib "racket/date.rkt")] 和 @racket[(lib "racket/date")]，
等价于 @racket[racket/date]。其他例子如 @racket[(lib "racket")],
@racket[(lib "racket/main")], @racket[(lib "racket/main.rkt")],
均等价于 @racketmodname[racket]。

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

访问通过 @|PLaneT| 服务器分发的第三方库。首次需要时下载该库，之后使用本地副本。

@racket[id] 编码多个由 @litchar{/} 分隔的信息：包所有者、包名及可选的版本信息，
以及包内可选的特定库路径。类似于缩写 @racket[lib] 路径的 @racket[id]，
@filepath{.rkt} 后缀会自动添加，若未提供子路径元素，则使用 @racketidfont{/main} 作为路径。

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

与其他形式类似，若不存在以 @filepath{.rkt} 结尾的实现文件，可自动替换为以 @filepath{.ss} 结尾的文件。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[#:literals (planet)
             (planet package-string)]{

@racket[planet] 的 symbol 形式，但使用 string 而非 identifier。
此外，@racket[package-string] 可以以文件后缀结尾，此情况下不添加 @filepath{.rkt}。

与其他形式类似，@filepath{.ss} 扩展会被转换为 @filepath{.rkt}，
而若不存在以 @filepath{.rkt} 结尾的实现文件，可自动替换为以 @filepath{.ss} 结尾的文件。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform/subs[#:literals (planet = + -)
                  (planet rel-string (user-string pkg-string vers ...))
                  ([vers nat
                         (nat nat)
                         (= nat)
                         (+ nat)
                         (- nat)])]{

从 @|PLaneT| 服务器访问库的更通用形式。
在这种通用形式中，@|PLaneT| 引用以相对路径开始，如同 @racket[lib] 引用，
但路径之后是库的生产者、包和版本信息。指定的包按需下载并安装。

@racket[vers] 指定对包可接受版本的约束。版本号是非负整数序列，
约束决定序列中每个元素允许的值。如果特定元素没有约束，则任意版本都允许；
特别是，省略所有 @racket[vers] 意味着任何版本都可接受。
强烈建议至少指定一个 @racket[vers]。

For a version constraint, a plain @racket[nat] is the same as
@racket[(+ nat)], which matches @racket[nat] or higher for the
corresponding element of the version number.  A @racket[(_start-nat
_end-nat)] matches any number in the range @racket[_start-nat] to
@racket[_end-nat], inclusive. A @racket[(= nat)] matches only exactly
@racket[nat]. A @racket[(- nat)] matches @racket[nat] or lower.

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

@filepath{.ss} 和 @filepath{.rkt} 的自动转换与其他形式相同。}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform[#:literals (file)
             (file string)]{

Refers to a file, where @racket[string] is a relative or absolute path
using the current platform's conventions. This form is not portable,
and it should @italic{not} be used when a plain, portable
@racket[rel-string] suffices.

The automatic @filepath{.ss} and @filepath{.rkt} conversions apply as
with other forms.}

@; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
@specsubform/subs[#:literals (submod)
                  (@#,elemtag["submod"]{@racket[submod]} base element ...+)
                  ([base module-path
                         "."
                         ".."]
                   [element id
                            ".."])]{

引用 @racket[base] 的 submodule。@racket[submod] 中 @racket[element]s 的序列
指定到达最终 submodule 的 submodule 名称路径。 

@examples[
  (module zoo racket
    (module monkey-house racket
      (provide monkey)
      (define monkey "Curious George")))
  (require (submod 'zoo monkey-house))
  monkey
]

Using @racket["."] as @racket[base] within @racket[submod] stands for
the enclosing module. Using @racket[".."] as @racket[base] is
equivalent to using @racket["."] followed by an extra
@racket[".."]. When a path of the form @racket[(#,(racket quote) id)]
refers to a submodule, it is equivalent to @racket[(submod "."  id)].

使用 @racket[".."] 作为 @racket[element] 会回退一级 submodule，
实际上引用其封闭模块。例如，@racket[(submod "..")] 引用该路径所在 submodule 的封闭模块。

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
