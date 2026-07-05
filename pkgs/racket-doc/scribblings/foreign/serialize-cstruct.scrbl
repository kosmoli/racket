#lang scribble/doc
@(require "utils.rkt" 
          (for-label racket/serialize
                     ffi/serialize-cstruct
                     (except-in ffi/unsafe ->))
          scribble/racket
          scribble/example)

@(define serialize-eval (make-base-eval))
@examples[#:eval serialize-eval #:hidden (require ffi/serialize-cstruct
                                                  ffi/unsafe
                                                  racket/serialize)]

@title[#:tag "serialize-struct"]{可序列化 C 结构体类型}

@defmodule[ffi/serialize-cstruct]

@defform/subs[(define-serializable-cstruct _id ([field-id type-expr] ...)
                                           property ...)
              [(property (code:line #:alignment alignment-expr)
                         (code:line #:malloc-mode malloc-mode-expr)
                         (code:line #:serialize-inplace)
                         (code:line #:deserialize-inplace)
                         (code:line #:version vers)
                         (code:line #:other-versions ([other-vers deserialize-chain-expr
                                                                  convert-proc-expr
                                                                  unconvert-proc-expr
                                                                  cycle-convert-proc-expr]
                                                       ...))
                         (code:line #:property prop-expr val-expr))]]{

Like @racket[define-cstruct], but defines a serializable type, with
several changed additional bindings:

@itemize[

 @item{@racketidfont{make-@racketvarfont{id}} --- always uses
       @racket['atomic] allocation, even if @racket[#:malloc-mode] is
       specified (for historical reasons).}

 @item{@racketidfont{make-@racketvarfont{id}/mode} --- like behaves
       like @racketidfont{make-@racketvarfont{id}} but uses the mode
       or allocator specified via @racket[malloc-mode-expr] (for
       historical reasons).}

 @item{@racketidfont{deserialize:cstruct:@racketvarfont{id}} (for a
       @racket[vers] of @racket[0]) or
       @racketidfont{deserialize:cstruct:@racketvarfont{id}-v@racketvarfont{vers}}
       (for a @racket[vers] of @racket[1] or more) --- deserialization information that is
       automatically exported from a @racket[deserialize-info] submodule.}

 @item{@racketidfont{deserialize-chain:cstruct:@racketvarfont{id}}
       (for a @racket[vers] of @racket[0]) or
       @racketidfont{deserialize-chain:cstruct:@racketvarfont{id}-v@racketvarfont{vers}}
       (for a @racket[vers] of @racket[1] or more) --- deserialization
       information for use via @racket[#:other-versions] in other
       @racket[define-serializable-cstruct] forms.}

 @item{@racketidfont{deserialize:cstruct:@racketvarfont{id}} (for an
       @racket[other-vers] of @racket[0]) or
       @racketidfont{deserialize:cstruct:@racketvarfont{id}-v@racketvarfont{other-vers}}
       (for an @racket[other-vers] of @racket[1] or more) ---
       deserialization information that is automatically exported from
       a @racket[deserialize-info] submodule.}

]

新的类型实例满足 @racket[serializable?] 谓词，可用于 @racket[serialize] 和 @racket[deserialize]。如果某个字段包含任意指针、内嵌的不可序列化 C 结构体或指向不可序列化 C 结构体的指针，序列化可能失败。只要不包含上述类型，array-type 即受支持。

默认 @racket[vers] 为 @racket[0]，@racket[vers] 必须是字面量、精确、非负整数。@racket[#:other-versions] 子句为名为 @racketvarfont{id} 的先前版本结构体提供反序列化器，以便在对 @racketvarfont[id] 的声明进行更改后仍能反序列化先前序列化的数据。对于每个 @racket[other-vers]，@racket[deserialize-chain-expr] 应为一个由 @racket[define-serializable-cstruct] 声明的其他 @racket[other-id] 的 @racketidfont{deserialize:cstruct:@racketvarfont{other-id}} 绑定值，该 @racket[other-id] 具有与 @racketvarfont[id] 前一个版本相同的形状；由 @racket[convert-proc-expr] 产生的函数应将 @racket[_other-id] 实例转换为 @racketvarfont{id} 实例。由 @racket[unconvert-proc-expr] 和 @racket[cycle-convert-proc-expr] 产生的函数在涉及循环时使用；来自 @racket[unconvert-proc-expr] 的函数将 @racket[convert-proc-expr]'s 函数产生的 @racketvarfont{id} 实例转换回 @racket[_other-id]，而 @racket[cycle-convert-proc-expr] 返回两个值：一个 @racketidfont{id} 的壳实例和一个接受填充后的 @racket[_other-id] 并将其内容移动到壳实例中的函数。

@racket[malloc-mode-expr] 参数控制此类型在反序列化期间和 @racketidfont{make-@racketvarfont{id}/mode} 期间的内存分配。可以是 @racket[malloc] 的 mode 参数之一，或一个过程 @racket[(-> exact-positive-integer? cpointer?)] 用于分配给定大小的内存。默认值是使用 @racket['atomic] 的 @racket[malloc]。

指定 @racket[#:serialize-inplace] 时，序列化表示形式与 C struct 对象共享内存。虽然效率更高（尤其对于大对象），序列化后对对象的修改可能导致序列化表示形式的改变。

@racket[#:deserialize-inplace] 选项尽可能重用序列化表示形式的内存。此选项对大对象更高效，但对于循环结构可能回退到通过 @racket[malloc-mode-expr] 进行分配。由于序列化表示形式的 allocation mode 默认为 @racket['atomic]，或者如果指定了 @racket[#:serialize-inplace] 则可能是任意的，因此在对象包含指针时应谨慎使用 inplace 反序列化。

当 C struct 包含指针时，建议使用 custom allocator。它应基于非移动内存分配（如 @racket['raw]），可能需要手动释放以避免 garbage collection 后的内存泄漏。

@history[#:changed "1.1" @elem{Added @racket[#:version] and @racket[#:other-versions].}}

@examples[
#:eval serialize-eval
(define-serializable-cstruct _fish ([color _int]))
(define f0/s (serialize (make-fish 1)))
(fish-color (deserialize f0/s))

(define-serializable-cstruct _aq ([a (_gcable _fish-pointer)]
                                  [d (_gcable _aq-pointer/null)])
  #:malloc-mode 'nonatomic)
(define aq1 (make-aq/mode (make-fish 6) #f))
(code:line (set-aq-d! aq1 aq1) (code:comment "create a cycle"))
(define aq0/s (serialize aq1))
(aq-a (aq-d (aq-d (deserialize aq0/s))))
(code:comment @#,elem{Same shape as original @racket[aq]:})
(define-serializable-cstruct _old-aq ([a (_gcable _fish-pointer)]
                                      [d (_gcable _pointer)])
        #:malloc-mode 'nonatomic)
(code:comment @#,elem{Replace the original @racket[aq]:})
(define-serializable-cstruct _aq ([a (_gcable _fish-pointer)]
                                  [b (_gcable _fish-pointer)]
                                  [d (_gcable _aq-pointer/null)])
  #:malloc-mode 'nonatomic
  #:version 1
  #:other-versions ([0 deserialize-chain:cstruct:old-aq
                       (lambda (oa)
                         (make-aq/mode (old-aq-a oa)
                                       (old-aq-a oa)
                                       (cast (old-aq-d oa) _pointer _aq-pointer)))
                       (lambda (a)
                         (make-old-aq/mode (aq-a a)
                                           (aq-d a)))
                       (lambda ()
                         (define tmp-fish (make-fish 0))
                         (define a (make-aq/mode tmp-fish tmp-fish #f))
                         (values a
                                 (lambda (oa)
                                   (set-aq-a! a (old-aq-a oa))
                                   (set-aq-b! a (old-aq-a oa))
                                   (set-aq-d! a (cast (old-aq-d oa) _pointer _aq-pointer)))))]))
(code:comment "Deserialize old instance to new cstruct:")
(fish-color (aq-a (aq-d (aq-d (deserialize aq0/s)))))

(define aq1/s (serialize (make-aq/mode (make-fish 1) (make-fish 2) #f))
(code:comment @#,elem{New version of @racket[fish]:})
(define-serializable-cstruct _old-fish ([color _int]))
(define-serializable-cstruct _fish ([weight _float]
                                    [color _int])
  #:version 1
  #:other-versions ([0 deserialize-chain:cstruct:old-fish
                       (lambda (of)
                         (make-fish 10.0 (old-fish-color of)))
                       (lambda (a) (error "cycles not possible!"))
                       (lambda () (error "cycles not possible!"))]))
(code:comment @#,elem{Deserialized content upgraded to new @racket[fish]:})
(fish-color (aq-b (deserialize aq1/s)))
(fish-weight (aq-b (deserialize aq1/s)))
]}

@close-eval[serialize-eval]
