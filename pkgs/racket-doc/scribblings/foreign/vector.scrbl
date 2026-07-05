#lang scribble/doc
@(require "utils.rkt" 
          (only-in scribble/decode make-splice)
          scribble/racket
          (for-label racket/extflonum))

@title[#:tag "homogeneous-vectors"]{安全的同质 Vector}

@defmodule[ffi/vector]

同质 vector 类似于 C vector（见 @secref["foreign:cvector"]），除了它们定义不同类型的 vector，每种类型有固定的元素类型。例外的是 @racketidfont{u8} 绑定族，它们只是 byte-string 绑定的别名；例如，@racket[make-u8vector] 是 @racket[make-bytes] 的别名。

@(begin
   (require (for-syntax scheme/base))
   (define-syntax (srfi-4-vector stx)
     (syntax-case stx ()
       [(_ id elem number?)
        #'(srfi-4-vector/desc id elem number? make-splice
            "Like " (racket make-vector) ", etc., but for " (racket elem) " elements.")]))
   (define-syntax (srfi-4-vector/desc stx)
     (syntax-case stx ()
       [(_ id elem as-number? extra desc ...)
        (let ([mk
               (lambda l
                 (datum->syntax
                  #'id
                  (string->symbol
                   (apply string-append
                          (map (lambda (i)
                                 (if (identifier? i)
                                     (symbol->string (syntax-e i))
                                     i))
                               l)))
                  #'id))])
          (with-syntax ([make (mk "make-" #'id "vector")]
                        [vecr (mk #'id "vector")]
                        [? (mk #'id "vector?")]
                        [length (mk #'id "vector-length")]
                        [ref (mk #'id "vector-ref")]
                        [! (mk #'id "vector-set!")]
                        [list-> (mk "list->" #'id "vector")]
                        [->list (mk #'id "vector->list")]
                        [->cpointer (mk #'id "vector->cpointer")]
                        [_vec (mk "_" #'id "vector")])
            #`(let-syntax ([number? (make-element-id-transformer
                                     (lambda (stx)
                                       #'(racket as-number?)))])
              (list
               (defproc* ([(make [len exact-nonnegative-integer?]) ?]
                          [(vecr [val number?] (... ...)) ?]
                          [(? [v any/c]) boolean?]
                          [(length [vec ?]) exact-nonnegative-integer?]
                          [(ref [vec ?] [k exact-nonnegative-integer?]) number?]
                          [(! [vec ?] [k exact-nonnegative-integer?] [val number?]) void?]
                          [(list-> [lst (listof number?)]) ?]
                          [(->list [vec ?]) (listof number?)]
                          [(->cpointer [vec ?]) cpointer?])
                 desc ...
                 (extra
                  (list
                   " The " (racket ->cpointer)
                   " function extracts a plain pointer to the underlying array.")))
               ;; 大麻烦：为 _vec 定义中的部分构建相对正确的源位置
               (defform* [#,(datum->syntax
                             #'_vec
                             (cons #'_vec
                                   (let loop ([l '(mode maybe-len)]
                                              [col (+ (syntax-column #'_vec)
                                                      (syntax-span #'_vec)
                                                      1)]
                                              [pos (+ (syntax-position #'_vec)
                                                      (syntax-span #'_vec)
                                                      1)])
                                     (if (null? l)
                                         null
                                         (let ([span (string-length (symbol->string (car l)))])
                                           (cons (datum->syntax
                                                  #'_vec
                                                  (car l)
                                                  (list (syntax-source #'_vec)
                                                        (syntax-line #'_vec)
                                                        col
                                                        pos
                                                        span))
                                                 (loop (cdr l)
                                                       (+ col 1 span)
                                                       (+ pos 1 span))))))
                             (list (syntax-source #'_vec)
                                   (syntax-line #'_vec)
                                   (sub1 (syntax-column #'vec))
                                   (sub1 (syntax-position #'vec))
                                   10))
                           _vec]
                 "Like " (racket _cvector) ", but for vectors of "
                 (racket elem) " elements.")))))))


@srfi-4-vector/desc[u8 _uint8 byte? (lambda (x) (make-spline null))]{

类似于 @racket[_cvector]，但用于 @racket[_uint8] 元素的 vector。这些是 @racketidfont{byte} 操作的别名，其中 @racket[u8vector->cpointer]
是恒等函数。}

@srfi-4-vector[s8 _int8 (integer-in -128 127)]
@srfi-4-vector[s16 _int16 (integer-in -32768 32767)]
@srfi-4-vector[u16 _uint16 (integer-in 0 65535)]
@srfi-4-vector[s32 _int32 (integer-in -2147483648 2147483647)]
@srfi-4-vector[u32 _uint32 (integer-in 0 4294967295)]
@srfi-4-vector[s64 _int64 (integer-in -9223372036854775808 9223372036854775807)]
@srfi-4-vector[u64 _uint64 (integer-in 0 18446744073709551615)]
@srfi-4-vector[f32 _float real?]
@srfi-4-vector[f64 _double* real?]
@srfi-4-vector[f80 _longdouble extflonum?]
