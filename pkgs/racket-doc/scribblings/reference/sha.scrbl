#lang scribble/doc
@(require "mz.rkt" (for-label file/sha1))

@(define sha-eval (make-base-eval))
@examples[#:hidden #:eval sha-eval (require file/sha1)]

@title[#:tag "sha"]{Cryptographic Hashing}

@deftogether[(
@defproc[(sha1-bytes [in (or/c bytes? input-port?)]
                     [start exact-nonnegative-integer? 0]
                     [end (or/c #f exact-nonnegative-integer?) #f])
         bytes?]
@defproc[(sha224-bytes [in (or/c bytes? input-port?)]
                       [start exact-nonnegative-integer? 0]
                       [end (or/c #f exact-nonnegative-integer?) #f])
         bytes?]
@defproc[(sha256-bytes [in (or/c bytes? input-port?)]
                       [start exact-nonnegative-integer? 0]
                       [end (or/c #f exact-nonnegative-integer?) #f])
         bytes?]
)]{

计算字节序列的 SHA-1、SHA-224 或 SHA-256 哈希，
并返回哈希字节串，分别为 20 字节、28 字节或 32 字节。

@racket[start] 和 @racket[end] 参数决定用于计算哈希的输入字节范围。
@racket[end] 值为 @racket[#f] 表示字节串末尾或输入端口的文件末尾位置。
当 @racket[in] 为字节串时，@racket[start] 和 @racket[end] 值（当非
@racket[#f] 时）不得超过字节串长度，且 @racket[start] 不得大于 @racket[end]。
当 @racket[in] 为输入端口时，@racket[start] 不得大于 @racket[end]；
如果 @racket[in] 在文件末尾前提供的字节少于 @racket[start] 或 @racket[end]，
则 @racket[start] 和/或 @racket[end] 将实际更改为已提供的字节数量
（因此空或截断的字节序列也进行哈希计算）。当 @racket[in] 为输入端口
且 @racket[end] 为数字时，从输入端口最多读取 @racket[end] 字节。

出于安全目的，建议在 @racket[sha1-bytes] 之上使用
@racket[sha224-bytes] 和 @racket[sha256-bytes]（属于 SHA-2 系列）。

使用 @racketmodname[file/sha1] 中的 @racket[bytes->hex-string]
将字节串哈希转换为可读的字符串。

@mz-examples[
#:eval sha-eval
(sha1-bytes #"abc")
(require file/sha1)
(bytes->hex-string (sha1-bytes #"abc"))
(bytes->hex-string (sha224-bytes #"abc"))
(bytes->hex-string (sha224-bytes (open-input-string "xabcy") 1 4))
]

@history[#:added "7.0.0.5"]}

@; ----------------------------------------------------------------------

@close-eval[sha-eval]
