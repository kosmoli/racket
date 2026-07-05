#lang scribble/doc
@(require scribble/manual
          (for-label racket/base
                     ffi/unsafe/nsalloc
                     ffi/unsafe/nsstring))

@title[#:tag "ns"]{Cocoa Foundation}

@racketmodname[ffi/unsafe/nsalloc] 和
@racketmodname[ffi/unsafe/nsstring] 库提供了用于与 Cocoa 和/或 Mac OS Foundation 库交互的基本设施
（通常与 @racket[ffi/objc] 配合使用）。

@; ----------------------------------------

@section{字符串}

@defmodule[ffi/unsafe/nsstring]

@defthing[_NSString ctype?]{

一种在 Racket 字符串和 @tt{NSString*}（亦称 @tt{CFStringRef}）值之间转换的类型。
也就是说，可将 @tt{_NSString} 用作 foreign-function 的 @tt{NSString*} 参数或结果的类型。

@racket[_NSString] 转换维护一个从 Racket 字符串到已转换字符串的弱映射，
因此在多次转换同一字符串（在 @racket[equal?] 意义下）时，
可以避免分配多个 @tt{NSString} 对象。}


@; ----------------------------------------
@section{分配池}

@defmodule[ffi/unsafe/nsalloc]{任何分配内存的 Foundation API 调用都需要安装一个 @tt{NSAutoreleasePool}。
@racketmodname[ffi/unsafe/nsalloc] 库提供了一个函数和一个缩写语法形式，用于设置这样的上下文。
（不过，@racket[_NSString] 类型在 Racket 字符串转换时会隐式创建一个 autorelease pool。）}

@defproc[(call-with-autorelease [thunk (-> any)]) any]{

以 @tech{atomic mode} 调用 @racket[thunk]，并使用一个在 @racket[thunk] 返回后被 @tt{release} 的新 @tt{NSAutoreleasePool}。}


@defform[(with-autorelease expr)]{

@racket[(call-with-autorelease (lambda () expr))] 的缩写形式。}
