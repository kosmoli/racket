#lang scribble/doc
@(require "utils.rkt" (for-label ffi/file))

@title[#:tag "file-security-guard-checks"]{文件安全守卫检查}

@defmodule[ffi/file]

@defproc[(security-guard-check-file
           [who symbol?]
           [path path-string?]
           [perms (listof (or/c 'read 'write 'execute 'delete 'exists))])
         void?]{

检查 @racket[(current-security-guard)] 是否允许以 @racket[perms] 权限访问 @racket[path] 指定的文件。有关 @racket[perms] 的更多信息，请参见 @racket[make-security-guard]。

符号 @racket[who] 应该是为其执行安全检查的函数名称；它被传递给安全守卫，用于在访问被拒绝时显示错误消息。}


@defproc[(_file/guard [perms (listof (or/c 'read 'write 'execute 'delete 'exists))]
                      [who symbol? '_file/guard])
         ctype?]{

类似于 @racket[_file] 和 @racket[_path]，但从 Racket 到 C 的转换首先使用 @racket[path->complete-path] 完成路径，然后使用 @racket[cleanse-path] 清理它，然后检查当前的安全守卫是否在完成后的路径上授予具有 @racket[perms] 的访问权限。作为输出值，与 @racket[_path] 相同。}


@deftogether[[
@defthing[_file/r ctype?]
@defthing[_file/rw ctype?]]]{

分别等价于 @racket[(_file/guard '(read) '_file/r)] 和 @racket[(_file/guard '(read write) '_file/rw)]。}


@defproc[(security-guard-check-file-link
           [who symbol?]
           [path path-string?]
           [dest path-string?])
         void?]{

检查 @racket[(current-security-guard)] 是否允许将 @racket[path] 创建为链接 @racket[dest]。符号 @racket[who] 与 @racket[security-guard-check-file] 相同。

@history[#:added "6.9.0.5"]}


@defproc[(security-guard-check-network
           [who symbol?]
           [host (or/c string? #f)]
           [port (or/c (integer-in 1 65535) #f)]
           [mode (or/c 'client 'server)])
         void?]{

检查 @racket[(current-security-guard)] 是否允许在 @racket[host] 和 @racket[port] 上以 @racket[mode] 指定的服务器或客户端模式进行网络访问。符号 @racket[who] 与 @racket[security-guard-check-file] 相同。

@history[#:added "6.9.0.5"]}
