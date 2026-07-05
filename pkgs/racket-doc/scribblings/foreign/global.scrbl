#lang scribble/doc
@(require "utils.rkt"
          (for-label ffi/unsafe/global))

@title[#:tag "unsafe-global"]{进程范围和地点范围的注册}

@defmodule[ffi/unsafe/global]{@racketmodname[ffi/unsafe/global] 库提供了一个注册信息的工具，该信息对一个地点局部有效或跨越 Racket进程中的所有地点有效。}

@history[#:added "6.9.0.5"]

@defproc[(register-process-global [key bytes?]
                                  [val cpointer?])
         cpointer?]{

在进程全局表（即跨越多个地点共享，如果存在的话）中获取或设置一个值。

如果 @racket[val] 是 @racket[#f]，则报告 @racket[key] 当前的映射。

如果 @racket[val] 不是 @racket[#f]，且 @racket[key] 尚未安装值，则安装该值并返回 @racket[#f]。如果已安装了一个值，则不安装新值并返回旧值。传入的 @racket[val] 不能引用垃圾回收内存。

此预期在小数量 key 的偶尔情况下使用。}


@defproc[(get-place-table) hash?]{

返回一个特定于地点的、可变的、基于 @racket[eq?] 的 hash table。
对于特定地点，结果始终是相同的。

@history[#:added "6.11.0.6"]}
