#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "envvars"]{Environment Variables}

一个 @deftech{environment variable set} 封装了一个从 byte strings 到 byte strings
的部分映射。一个 Racket 进程的 initial @tech{environment variable set} 连接到
操作系统的环境变量：对该 set 的访问或修改会读取或改变 Racket 进程的操作系统
环境变量。

由于 Windows 环境变量不区分大小写，Windows 上的 @tech{environment variable set}
的 key byte strings 会被 case-folded。更精确地说，key byte strings 会被强制转换为
一个 UTF-8 encoding 的字符序列，该序列通过 @racket[string-locale-downcase] 转换
为小写。

当前的 @tech{environment variable set}（由 @racket[current-environment-variables]
parameter 确定）在创建 @tech{subprocess} 时会被传播给它。


@defproc[(environment-variables? [v any/c]) boolean?]{

如果 @racket[v] 是一个 @tech{environment variable set}，则返回 @racket[#t]，
否则返回 @racket[#f]。}


@defparam[current-environment-variables env environment-variables?]{

一个 @tech{parameter}，它确定传播到 @tech{subprocess} 的
@tech{environment variable set}，并且作为 @racket[getenv] 和 @racket[putenv]
的默认 set 使用。}


@defproc[(bytes-environment-variable-name? [v any/c]) boolean?]{

如果 @racket[v] 是一个 byte string 并且它是有效的环境变量名，则返回 @racket[#t]。
环境变量名不得包含值为 @racket[0] 或 @racket[61]（其中 @racket[61] 是
@racket[(char->integer #\=)]）的 bytes。在 Windows 上，环境变量名的长度
也必须为非零。}


@defproc[(make-environment-variables [name bytes-environment-variable-name?]
                                     [val bytes-no-nuls?]
                                     ... ...)
         environment-variables?]{

创建一个新的 @tech{environment variable set}，用给定的 @racket[name] 到
@racket[val] 映射进行初始化。}


@defproc[(environment-variables-ref [env environment-variables?]
                                    [name bytes-environment-variable-name?])
         (or/c #f (and/c bytes-no-nuls? immutable?))]{

返回 @racket[env] 中 @racket[name] 的映射，如果 @racket[name] 没有映射则
返回 @racket[#f]。

通常，@racket[name] 应该是使用当前 @tech{locale} 的默认编码的 byte-string。
在 Windows 上，@racket[name] 会被强制转换为 UTF-8 encoding 并进行大小写标准化。}


@defproc[(environment-variables-set! [env environment-variables?]
                                     [name bytes-environment-variable-name?]
                                     [maybe-bstr (or/c bytes-no-nuls? #f)]
                                     [fail (-> any)
                                           (lambda ()
                                             (raise (make-exn:fail ....)))])
         any]{

将 @racket[env] 中 @racket[name] 的映射更改为 @racket[maybe-bstr]。
如果 @racket[maybe-bstr] 是 @racket[#f] 并且 @racket[env] 是 Racket 进程的
initial @tech{environment variable set}，则操作系统环境变量映射中对应
@racket[name] 的映射将被移除。

通常，@racket[name] 和 @racket[maybe-bstr] 应该是使用当前 @tech{locale} 的
默认编码的 byte-string。在 Windows 上，@racket[name] 会被强制转换为 UTF-8 
encoding 并进行大小写标准化，@racket[maybe-bstr] 会被强制转换为 UTF-8 
encoding（当 @racket[env] 是 Racket 进程的 initial @tech{environment variable
set} 时）。

成功时，@racket[environment-variables-set!] 的结果是 @|void-const|。
如果 @racket[env] 是 Racket 进程的 initial @tech{environment variable set}，
则调整操作系统环境变量映射可能会因某些原因而失败，此时 @racket[fail] 会在
tail position 中被调用。默认的 @racket[fail] 会引发异常。}


@defproc[(environment-variables-names [env environment-variables?])
         (listof (and/c bytes-environment-variable-name? immutable?))]{

返回一个 byte strings 列表，对应于 @racket[env] 映射的 names。}


@defproc[(environment-variables-copy [env environment-variables?])
         environment-variables?]{

返回一个用 @racket[env] 的相同映射初始化的 @tech{environment variable set}。}


@deftogether[(
@defproc[(getenv [name string-environment-variable-name?])
                 (or/c string-no-nuls? #f)]
@defproc[(putenv [name string-environment-variable-name?]
                 [value string-no-nuls?]) boolean?]
)]{

@racket[environment-variables-ref] 和 @racket[environment-variables-set!] 的
便利包装器，它们使用当前 @tech{locale} 的默认编码（在编码错误时使用 @racket[#\?]
作为替换字符）在 strings 和 byte strings 之间进行转换，并且总是使用
@racket[current-environment-variables] 提供的当前 @tech{environment variable set}。
@racket[putenv] 函数成功时返回 @racket[#t]，失败时返回 @racket[#f]。}


@defproc[(string-environment-variable-name? [v any/c]) boolean?]{

如果 @racket[v] 是一个 string 并且它使用当前 @tech{locale} 的编码是有效的
环境变量名（根据 @racket[bytes-environment-variable-name?] 判定），则返回
@racket[#t]，否则返回 @racket[#f]。}
