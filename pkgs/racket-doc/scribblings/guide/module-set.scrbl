#lang scribble/doc
@(require scribble/manual scribble/eval "guide-utils.rkt")

@title[#:tag "module-set"]{Assignment and Redefinition}

对模块内部定义的 variable 使用 @racket[set!] 仅限于定义该模块的主体内。也就是说，模块可以修改自身定义的那些绑定的值，这些修改对导入模块而言是可见的。然而，不允许导入方修改被导入绑定的值。

@examples[
(module m racket
  (provide counter increment!)
  (define counter 0)
  (define (increment!)
    (set! counter (add1 counter))))
(require 'm)
(eval:alts counter (eval 'counter))
(eval:alts (increment!) (eval '(increment!)))
(eval:alts counter (eval 'counter))
(eval:alts (set! counter -1) (eval '(set! counter -1)))
]

如上述示例所示，模块可以通过提供一个 mutator 函数（例如 @racket[increment!]）来授权他人修改其导出变量的值。

禁止对导入的 variable 赋值有助于支持程序设计的模块化推理。例如在以下模块中：

@racketblock[
(module m racket
  (provide rx:fish fishy-string?)
  (define rx:fish #rx"fish")
  (define (fishy-string? s)
    (regexp-match? rx:fish s)))
]

无论其它模块如何使用 @racket[rx:fish] 绑定，函数 @racket[fishy-string?] 始终会匹配包含 ``fish'' 的字符串。由于同样的原因——既帮助了程序员，禁止对导入变量赋值也允许许多程序更高效地执行。

同理，当一个模块内部对其中定义的某个 identifier 从不 @racket[set!]，那么这个 identifier 即被视为 @defterm{常量}——不可修改，即使通过重新声明模块也不能。

因此，通常不允许对一个 module 进行重定义。对于文件式模块而言，简单地修改文件并不会导致重定义，因为文件式模块是按需加载的，已加载过的声明能满足后续请求。不过，借助 Racket 的反射机制仍然可以重定义一个模块；在这种情况下，如果重定义涉及对先前常量绑定的重新定义，便可能失败。

@interaction[
(module m racket
  (define pie 3.141597))
(require 'm)
(module m racket
  (define pie 3))
]

出于探索和调试目的，Racket 的反射层提供了 @racket[compile-enforce-module-constants] 参数来禁用常量强制。

@interaction[
(compile-enforce-module-constants #f)
(module m2 racket
  (provide pie)
  (define pie 3.141597))
(require 'm2)
(module m2 racket
  (provide pie)
  (define pie 3))
(compile-enforce-module-constants #t)
(eval:alts pie (eval 'pie))
]
