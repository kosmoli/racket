#lang scribble/doc
@(require (except-in "utils.rkt" _fun)
          (for-label scheme/match
                     (only-in ffi/unsafe/static _fun))
          (for-syntax racket/base)
          scribble/eval
          scribble/racket)

@(begin
   (define-syntax-rule (define-dynamic_fun id)
      (begin
       (require (for-label ffi/unsafe))
       (define id @racket[_fun])))
    (define-dynamic_fun dynamic_fun))

@title[#:tag "static-fun"]{静态 Callout 和 Callback 核心}

@defmodule[ffi/unsafe/static]{@racketmodname[ffi/unsafe/static] 库
提供与 @racketmodname[ffi/unsafe] 相同的 binding，但替换 @racket[_fun]
形式。}

@history[#:added "8.11.0.2"]

@defform[#:literals (->> :: :)
         (_fun fun-option ... maybe-args type-spec ... ->> type-spec
               maybe-wrapper)]{

与 @racketmodname[ffi/unsafe] 中的 @dynamic_fun 类似，但在无法为结果 C 类型推断
足够信息以静态生成 @tech{callout} 和 @tech{callback} 使用类型的代码时，
会在编译时触发 @CS[] 实现中的错误。

@racket[_fun] 内的 @racket[type-spec] 形式和某些 @racket[fun-option] 形式是任意表达式，
可以在运行时计算 C 类型和选项。如果优化器可以静态推断底层表示，则可以
静态生成 @tech{callout} 或 @tech{callback} 所需的代码，
而不是将代码生成延迟到运行时优化。即使用 @racketmodname[ffi/unsafe] 
中的 @dynamic_fun 也应用此优化，但 @racketmodname[ffi/unsafe/static] 中的
@racket[_fun] 坚持优化必须应用。

目前，@tech{callout} 和 @tech{callback} 代码的静态生成的益处有限，
因为运行时代码生成速度快且具有缓存。长远来看，静态生成可能会带来更多益处。}