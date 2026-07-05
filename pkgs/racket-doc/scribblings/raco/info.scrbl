#lang scribble/doc
@(require scribble/manual
          (for-label (except-in racket require)
                     setup/getinfo
                     (only-in info require)))

@(begin
   (define-syntax-rule (define-racket-require id)
     (begin
       (require (for-label (only-in racket require)))
       (define id @racket[require])))
   (define-racket-require racket:require))

@title[#:tag "info.rkt"]{@filepath{info.rkt} 文件格式}

@defmodulelang*[(info setup/infotab)]

在每个集合中，一个特殊的模块文件 @filepath{info.rkt} 提供各种工具使用的集合的常规信息。例如，@filepath{info.rkt} 文件指定如何构建集合的文档，并列出 DrRacket 的插件工具或集合提供的 @exec{raco} 命令。

@margin-note{
  在 @filepath{info.rkt} 文件中指定的字段在包的 @secref["metadata" #:doc '(lib "pkg/scribblings/pkg.scrbl")] 和集合的 @secref["setup-info" #:doc '(lib "scribblings/raco/raco.scrbl")] 中记录。}

虽然 @filepath{info.rkt} 文件包含模块声明，但声明具有高度受限的形式。它必须与以下 @racket[_info-module] 语法匹配：

@racketgrammar*[
#:literals (info lib setup/infotab module define quote quasiquote if
                 cons car cdr list list* reverse append
                 string-append path->string build-path
                 equal?
                 make-immutable-hash hash hash-set hash-set* hash-remove hash-clear hash-update
                 collection-path
                 system-library-subpath
                 getenv)
[info-module (module info info-mod-path
               decl
               ...)]
[info-mod-path info
               setup/infotab
               (lib "info/main.rkt")
               (lib "setup/infotab.ss")
               (lib "setup/infotab.rkt")
               (lib "main.rkt" "info")
               (lib "infotab.rkt" "setup")
               (lib "infotab.ss" "setup")]
[decl (define id info-expr)]
[info-expr (@#,racket[quote] datum)
           (@#,racket[quasiquote] datum)
           (if info-expr info-expr info-expr)
           (info-primitive info-expr ...)
           id
           string
           number
           boolean]
[info-primitive cons car cdr list
                list* reverse append
                equal?
                string-append
                make-immutable-hash hash hash-set hash-set* hash-remove hash-clear hash-update
                path->string build-path collection-path
                system-library-subpath
                getenv]
]

例如，以下声明可以是 @filepath{games} 集合的 @filepath{info.rkt} 库。它包含三个 info 标签的定义，@racket[name]，@racket[gracket-launcher-libraries]，和 @racket[gracket-launcher-names]。

@racketmod[
info
(define name "Games")
(define gracket-launcher-libraries '("main.rkt"))

(define gracket-launcher-names     '("PLT Games"))
]

如本例所示，@filepath{info.rkt} 文件可以使用 @hash-lang[] 符号，但只能与 @racketmodname[info]（或 @racketmodname[setup/infotab]）语言使用。

虽然在 @racketmodname[info] 模块中允许使用 @racket[getenv]，但 @racket[get-info] 函数在加载模块时会修剪未在 @indexed-envvar{PLT_INFO_ALLOW_VARS} 环境变量中列出的任何变量，该环境变量包含以 @litchar{;} 分隔的变量名列表。默认情况下，允许的环境变量集为空。

也参见 @racketmodname[setup/getinfo] 中的 @racket[get-info]。

@history[#:changed "6.5.0.2" @elem{添加 @racket[if]，@racket[equal?]，和 @racket[getenv]。}]
