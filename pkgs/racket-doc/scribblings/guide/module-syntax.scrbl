#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt"
          (for-label rackunit))

@(define cake-eval (make-base-eval))

@title{模块语法}

@litchar{#lang} 位于模块文件开头，是 @racket[module] 形式的简写，就像 @litchar{'} 是 @racket[quote] 形式的简写一样。与 @litchar{'} 不同，@litchar{#lang} 简写在 @tech{REPL} 中效果不佳，部分原因在于它必须由文件结束符终止，但更根本的原因是 @litchar{#lang} 的展开形式依赖于外围文件的名称。

@;------------------------------------------------------------------------
@section[#:tag "module-syntax"]{@racket[module] 形式}

模块声明的完整形式在 @tech{REPL} 和文件中都有效：

@specform[
(module name-id initial-module-path
  decl ...)
]

其中 @racket[_name-id] 是模块的名称，@racket[_initial-module-path] 是初始导入，每个 @racket[_decl] 是导入、导出、定义或表达式。对于文件的情况，@racket[_name-id] 通常与包含文件的名称匹配（减去目录路径或文件扩展名），但当模块通过其文件路径被 @racket[require] 时，@racket[_name-id] 被忽略。

@racket[_initial-module-path] 是必需的，因为即使是 @racket[require] 形式也必须先在模块体中导入才能使用。换句话说，@racket[_initial-module-path] 导入引导了体中可用的语法。最常用的 @racket[_initial-module-path] 是 @racketmodname[racket]，它提供了本指南中描述的大部分绑定，包括 @racket[require]、@racket[define] 和 @racket[provide]。另一个常用的 @racket[_initial-module-path] 是 @racketmodname[racket/base]，它提供的功能较少，但仍包含大多数最常用的函数和语法。

例如，@seclink["module-basics"]{前一节}中的 @filepath{cake.rkt} 示例可以写成：

@racketblock+eval[
#:eval cake-eval
(module cake racket
  (provide print-cake)

  (define (print-cake n)
    (show "   ~a   " n #\.)
    (show " .-~a-. " n #\|)
    (show " | ~a | " n #\space)
    (show "---~a---" n #\-))

  (define (show fmt n ch)
    (printf fmt (make-string n ch))
    (newline)))
]

此外，此 @racket[module] 形式可以在 @tech{REPL} 中求值，以声明一个不与任何文件关联的 @racket[cake] 模块。要引用此类未关联的模块，需引用模块名称：

@examples[
#:eval cake-eval
(require 'cake)
(eval:alts (print-cake 3) (eval '(print-cake 3)))
]

声明模块不会立即求值模块体的定义和表达式。模块必须在顶层显式 @racket[require] 才能触发求值。求值被触发一次后，后续的 @racket[require] 不会重新求值模块体。

@examples[
(module hi racket
  (printf "Hello\n"))
(require 'hi)
(require 'hi)
]

@;------------------------------------------------------------------------
@section[#:tag "hash-lang"]{@racketmodfont{#lang} 简写}

@racketmodfont{#lang} 简写的体没有特定语法，因为语法由 @racketmodfont{#lang} 后面的语言名称决定。

对于 @racketmodfont{#lang} @racketmodname[racket]，语法为

@racketmod[
racket
_decl ...]

@seclink["hash-lang reader"]{读取}方式与

@racketblock[
(module _name racket
  _decl ...)
]

相同，其中 @racket[_name] 由包含 @racketmodfont{#lang} 形式的文件名称派生。

@racketmodfont{#lang} @racketmodname[racket/base] 形式与 @racketmodfont{#lang} @racketmodname[racket] 语法相同，只是完整展开使用 @racketmodname[racket/base] 而不是 @racketmodname[racket]。相比之下，@racketmodfont{#lang} @racketmodname[scribble/manual] 形式具有完全不同的语法，甚至看起来不像 Racket，本指南中我们不做描述。

除非另有说明，使用 @racketmodfont{#lang} 表示法记录为"语言"的模块将以与 @racketmodfont{#lang} @racketmodname[racket] 相同的方式展开为 @racket[module]。记录的语言名称也可以直接与 @racket[module] 或 @racket[require] 一起使用。

@; ----------------------------------------------------------------------
@section[#:tag "submodules"]{子模块}

@racket[module] 形式可以嵌套在模块内部，此情况下嵌套的 @racket[module] 形式声明一个 @deftech{子模块}。子模块可由外围模块使用引用名称直接引用。以下示例通过从 @racket[zoo] 子模块导入 @racket[tiger] 来打印 @racket["Tony"]：

@racketmod[
  #:file "park.rkt"
  racket

  (module zoo racket
    (provide tiger)
    (define tiger "Tony"))

  (require 'zoo)

  tiger
]

运行模块不一定会运行其子模块。在上述示例中，运行 @filepath{park.rkt} 仅当其 @racket[require] 了 @racket[zoo] 子模块时才运行该子模块。否则，模块和每个子模块可以独立运行。此外，如果 @filepath{park.rkt} 被编译为 bytecode 文件（通过 @exec{raco make}），则 @filepath{park.rkt} 或 @racket[zoo] 的代码可以独立加载。

子模块可以嵌套在子模块内部，子模块也可以由外围模块以外的模块通过 @elemref["submod"]{子模块路径}直接引用。

@racket[module*] 形式类似于嵌套的 @racket[module] 形式：

@specform[
(module* name-id initial-module-path-or-#f
  decl ...)
]

@racket[module*] 形式与 @racket[module] 的区别在于它反转了子模块与外围模块之间的引用可能性：

@itemlist[

 @item{用 @racket[module] 声明的子模块可被其外围模块 @racket[require]，但子模块不能 @racket[require] 外围模块，也不能词法引用外围模块的绑定。}

 @item{用 @racket[module*] 声明的子模块可以 @racket[require] 其外围模块，但外围模块不能 @racket[require] 该子模块。}

]

此外，@racket[module*] 形式可以用 @racket[#f] 代替 @racket[_initial-module-path]，此情况下子模块可以看到外围模块的所有绑定——包括未通过 @racket[provide] 导出的绑定。

使用 @racket[module*] 和 @racket[#f] 声明子模块的一个用途是通过子模块导出通常不从模块导出的附加绑定：

@racketmod[
#:file "cake.rkt"
racket

(provide print-cake)

(define (print-cake n)
  (show "   ~a   " n #\.)
  (show " .-~a-. " n #\|)
  (show " | ~a | " n #\space)
  (show "---~a---" n #\-))

(define (show fmt n ch)
  (printf fmt (make-string n ch))
  (newline))

(module* extras #f
  (provide show))
]

在此修改后的 @filepath{cake.rkt} 模块中，使用 @racket[(require "cake.rkt")] 的模块不会导入 @racket[show]，因为大多数 @filepath{cake.rkt} 的客户端不需要额外的函数。模块可以使用 @racket[(require (submod "cake.rkt" extras))] 来 require @racket[extra] @tech{子模块}，以访问原本隐藏的 @racket[show] 函数。@margin-note*{参见 @elemref["submod"]{子模块路径}了解 @racket[submod] 的更多信息。}

@; ----------------------------------------------------------------------
@section[#:tag "main-and-test"]{主模块和测试子模块}

以下 @filepath{cake.rkt} 变体包含一个调用 @racket[print-cake] 的 @racket[main] 子模块：

@racketmod[
#:file "cake.rkt"
racket

(define (print-cake n)
  (show "   ~a   " n #\.)
  (show " .-~a-. " n #\|)
  (show " | ~a | " n #\space)
  (show "---~a---" n #\-))

(define (show fmt n ch)
  (printf fmt (make-string n ch))
  (newline))

(module* main #f
  (print-cake 10))
]

运行模块不会运行其 @racket[module*] 定义的子模块。然而，通过 @exec{racket} 或 DrRacket 运行上述模块会打印一个有 10 根蜡烛的蛋糕，因为 @racket[main] @tech{子模块}是特殊情况。

当模块作为程序名提供给 @exec{racket} 可执行文件或在 DrRacket 中直接运行时，如果模块有 @as-index{@racket[main] 子模块}，则 @racket[main] 子模块在其外围模块之后运行。因此，声明 @racket[main] 子模块指定了模块直接运行时（而不是作为库在更大程序中 @racket[require] 时）要执行的额外操作。

@racket[main] 子模块不必用 @racket[module*] 声明。如果 @racket[main] 模块不需要使用外围模块的绑定，可以用 @racket[module] 声明。更常见的是，@racket[main] 使用 @racket[module+] 声明：

@specform[
(module+ name-id
  decl ...)
]

用 @racket[module+] 声明的子模块类似于使用 @racket[#f] 作为 @racket[_initial-module-path] 的 @racket[module*] 声明。此外，多个 @racket[module+] 形式可以指定相同的子模块名称，此情况下 @racket[module+] 形式的体被组合以创建单个子模块。

@racket[module+] 的组合行为对于定义 @racket[test] 子模块特别有用，可以方便地使用 @exec{raco test} 运行，类似于 @racket[main] 可以方便地用 @exec{racket} 运行。例如，以下 @filepath{physics.rkt} 模块导出 @racket[drop] 和 @racket[to-energy] 函数，并定义了一个 @racket[test] 模块来保存单元测试：

@racketmod[
#:file "physics.rkt"
racket
(module+ test
  (require rackunit)
  (define ε 1e-10))

(provide drop
         to-energy)

(define (drop t)
  (* 1/2 9.8 t t))

(module+ test
  (check-= (drop 0) 0 ε)
  (check-= (drop 10) 490 ε))

(define (to-energy m)
  (* m (expt 299792458.0 2)))

(module+ test
  (check-= (to-energy 0) 0 ε)
  (check-= (to-energy 1) 9e+16 1e+15))
]

将 @filepath{physics.rkt} 导入更大的程序不会运行 @racket[drop] 和 @racket[to-energy] 测试——如果模块已编译，甚至不会触发测试代码的加载——但在命令行运行 @exec{raco test physics.rkt} 会运行测试。

上述 @filepath{physics.rkt} 模块等价于使用 @racket[module*]：

@racketmod[
#:file "physics.rkt"
racket

(provide drop
         to-energy)

(define (drop t)
  (* 1/2 #e9.8 t t))

(define (to-energy m)
  (* m (expt 299792458 2)))

(module* test #f
  (require rackunit)
  (define ε 1e-10)
  (check-= (drop 0) 0 ε)
  (check-= (drop 10) 490 ε)
  (check-= (to-energy 0) 0 ε)
  (check-= (to-energy 1) 9e+16 1e+15))
]

使用 @racket[module+] 而不是 @racket[module*] 允许测试与函数定义交错排列。

@racket[module+] 的组合行为对于 @racket[main] 模块有时也有帮助。即使不需要组合，@racket[(module+ main ....)] 也更受青睐，因为它比 @racket[(module* main #f ....)] 更具可读性。

@; ----------------------------------------------------------------------

@close-eval[cake-eval]
