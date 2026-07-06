#lang scribble/doc
@(require "utils.rkt"
          scribble/racket
          (for-syntax racket/base)
          (for-label ffi/unsafe/define
                     ffi/unsafe/alloc))

@(define-syntax _MEVENT (make-element-id-transformer
                         (lambda (stx) #'@schemeidfont{_MEVENT})))
@(define-syntax _MEVENT-pointer (make-element-id-transformer
                                 (lambda (stx) #'@schemeidfont{_MEVENT-pointer})))
@(define-syntax _WINDOW-pointer (make-element-id-transformer
                                 (lambda (stx) #'@schemeidfont{_WINDOW-pointer})))
@(define-syntax _mmask_t (make-element-id-transformer
                          (lambda (stx) #'@schemeidfont{_mmask_t})))
@(define-syntax _string/immobile (make-element-id-transformer
                                  (lambda (stx) #'@schemeidfont{_string/immobile})))
   

@title[#:tag "intro"]{Overview}

尽管使用 FFI 不需要编写新的 C 代码，但它几乎没有为 C 程序员所面临的
安全和内存管理问题提供任何隔离。FFI 程序员必须特别留意跨越 Racket--C
边界的数据的内存管理问题。因此，本手册在许多方面依赖于 @|InsideRacket|
中的信息，后者定义了 Racket 如何与 C API 进行交互。

由于使用 FFI 涉及许多 Racket 程序员通常可以忽略的安全问题，因此库名称中包含
@racketidfont{unsafe}。导入该库宏应被视为一个声明，即你的代码本身是不安全的，
因此在出现 bug 时可能导致严重问题：你有责任提供一个安全的接口。如果你的库
提供了一个不安全的接口，那么它的名称中也应该包含 @racketidfont{unsafe}。

有关 Racket FFI 的动机和设计的更多信息，参见 @cite["Barzilay04"]。

@; --------------------------------------------------

@section{库、C 类型和对象}

要使用 FFI，你必须明确

@itemlist[

 @item{你想从中访问函数或值的特定库，}

 @item{文件导出的特定 symbol，以及}

 @item{导出 symbol 的 C 级类型（通常是函数类型）。}

]

该库对应于一个后缀为 @filepath{.dll}、@filepath{.so} 或 @filepath{.dylib}
的文件（也可能是 @filepath{.framework} 目录中的库，这取决于平台）。

知道库名称和/或路径通常是使用 FFI 最棘手的部分。有时，在使用没有路径前缀
或文件后缀的库名称时，可以自动定位库文件，尤其是在 Unix 上。参见
@racket[ffi-lib] 获取建议。

@racket[ffi-lib] 函数获取库的句柄。要从库中提取导出，最简单的方法是使用
@racketmodname[ffi/unsafe/define] 库中的 @racket[define-ffi-definer]：

@racketmod[
racket/base
(require ffi/unsafe
         ffi/unsafe/define)

(define-ffi-definer define-curses (ffi-lib "libcurses"))
]

这个 @racket[define-ffi-definer] 声明引入了一个 @racket[define-curses]
形式，用于将 Racket 名称绑定到从 @filepath{libcurses} 提取的值——具体位置
取决于平台，可能在 @filepath{/usr/lib/libcurses.so}。

要使用 @racket[define-curses]，我们需要 @filepath{libcurses} 中
函数的名称和 C 类型。我们将从使用以下函数开始：

@verbatim[#:indent 2]{
  WINDOW* initscr(void);
  int waddstr(WINDOW *win, char *str);
  int wrefresh(WINDOW *win);
  int endwin(void);
}

我们按如下方式使这些函数可从 Racket 调用：

@margin-note{By convention, an underscore prefix
indicates a representation of a C type (such as @racket[_int]) or a
constructor of such representations (such as @racket[_cpointer]).} 

@racketblock[
(define _WINDOW-pointer (_cpointer 'WINDOW))

(define-curses initscr (_fun -> _WINDOW-pointer))
(define-curses waddstr (_fun _WINDOW-pointer _string -> _int))
(define-curses wrefresh (_fun _WINDOW-pointer -> _int))
(define-curses endwin (_fun -> _int))
]

@racket[_WINDOW-pointer] 的定义创建了一个通过 @racket[_cpointer] 反映
C 类型的 Racket 值，这为 pointer 类型创建了一个类型表示——通常是 opaque 的。
@racket['WINDOW] 参数可以是任何值，但按照惯例，我们使用与 C 基础类型匹配
的 symbol。

每个 @racket[define-curses] 形式都将给定的 identifier 用作库导出
的名称和要绑定的 Racket identifier。@margin-note*{@racket[define-curses] 的可选
@racket[#:c-id] 子句可以为库导出指定一个与要绑定的 Racket identifier
不同的名称。} 每个定义的 @racket[(_fun ... -> ...)] 部分描述了导出函数的
C 类型，因为库文件不会为其导出编码该信息。@racket[->] 左侧列出的是
argument types，而 @racket[->] 右侧的是 result type。预定义的 @racket[_int]
类型自然对应于 @tt{int} C 类型，而 @racket[_string] 在意图作为字符串读取时
对应于 @tt{char*} 类型。

此时，@racket[initscr]、@racket[waddstr]、@racket[wrefresh] 和
@racket[endwin] 是普通的 Racket function 的 Racket bindings
（恰好调用 C 函数），因此它们可以从定义的 module 中导出或直接调用：

@racketblock[
(define win (initscr))
(void (waddstr win "Hello"))
(void (wrefresh win))
(sleep 1)
(void (endwin))
]

@; --------------------------------------------------

@section{函数类型的修饰}

我们最初使用 @racket[waddstr] 等函数的方式很草率，因为我们忽略了返回码。
C 函数经常返回错误码，而检查它们是一件痛苦的事情。更好的方法是将检查
构建到 @racket[waddstr] binding 中，并在代码非零时引发异常。

@racket[_fun] 函数类型构造函数包含许多选项，有助于将 C 函数转换为
更友好的 Racket 函数。我们可以使用其中的一些特性将返回码转换为
@|void-const| 或异常：

@racketblock[
(define (check v who)
  (unless (zero? v)
    (error who "failed: ~a" v)))

(define-curses initscr (_fun -> _WINDOW-pointer))
(define-curses waddstr (_fun _WINDOW-pointer _string -> (r : _int)
                             -> (check r 'waddstr)))
(define-curses wrefresh (_fun _WINDOW-pointer -> (r : _int)
                              -> (check r 'wrefresh)))
(define-curses endwin (_fun -> (r : _int)
                            -> (check r 'endwin)))                            
]

使用 @racket[(r : _int)] 作为结果类型会给 C 函数的返回值赋予局部名称
@racket[r]。然后在 @racket[_fun] 形式中第二个 @racket[->] 之后的
result post-processing 表达式中使用该名称。

@; --------------------------------------------------

@section{按引用传递的参数}

要从 @filepath{libcurses} 获取鼠标事件，我们必须通过 @racket[mousemask]
函数显式地启用它们：

@verbatim[#:indent 2]{
typedef unsigned long mmask_t;
#define BUTTON1_CLICKED 004L

mmask_t mousemask(mmask_t newmask, mmask_t *oldmask);
}

在掩码中设置 @racket[BUTTON1_CLICKED] 会启用按钮点击事件。同时，
@racket[mousemask] 通过将其安装到作为第二个参数提供的指针中，返回当前掩码。

由于这类 call-by-reference 接口在 C 中很常见，@racket[_fun] 会配合
@racket[_ptr] 形式来自动为 by-reference 参数分配空间，并提取 C 函数
放入那里的值。为提取的值命名，以便在 post-processing 表达式中使用。
post-processing 表达式可以将 by-reference 结果与函数的直接结果
（在这种情况下，报告给定掩码中实际支持的子集）结合起来。

@racketblock[
(define _mmask_t _ulong)
(define-curses mousemask (_fun _mmask_t (o : (_ptr o _mmask_t)) 
                               -> (r : _mmask_t)
                               -> (values o r)))
(define BUTTON1_CLICKED #o004)

(define-values (old supported) (mousemask BUTTON1_CLICKED))
]

@; --------------------------------------------------

@section{C 结构体}

假设支持鼠标事件，@filepath{libcurses} 库通过 @racket[getmouse]
报告它们，该函数接受一个指向 @cpp{MEVENT} struct 的指针，
用于填充鼠标事件信息：

@verbatim[#:indent 2]{
 typedef struct {
    short id;
    int x, y, z;
    mmask_t bstate;
 } MEVENT;

 int getmouse(MEVENT *event);
}

To work with @cpp{MEVENT} values, we use @racket[define-cstruct]:

@racketblock[
(define-cstruct _MEVENT ([id _short]
                         [x _int]
                         [y _int]
                         [z _int]
                         [bstate _mmask_t]))
]

此定义绑定了许多名称，方式与 @racket[define-struct] 绑定多个名称相同：
@racket[_MEVENT] 是表示 struct 类型的 C 类型，@racket[_MEVENT-pointer]
是表示指向 @racket[_MEVENT] 的指针的 C 类型，@racket[make-MEVENT]
构造一个 @racket[_MEVENT] 值，@racket[MEVENT-x] 从 @racket[_MEVENT] 值中
提取 @racket[x] 字段，等等。

有了这个 C struct 声明，我们可以定义 @racket[getmouse] 的函数类型。
最简单的方法是定义 @racket[getmouse] 接受一个 @racket[_MEVENT-pointer]，
然后在调用 @racket[getmouse] 之前显式分配 @racket[_MEVENT] 值：

@racketblock[
(define-curses getmouse (_fun _MEVENT-pointer -> _int))

(define m (make-MEVENT 0 0 0 0 0))
(when (zero? (getmouse m))
  (code:comment @#,t{use @racket[m]...})
  ....)
]

为了更类似 Racket 的函数，使用 @racket[(_ptr o _MEVENT)] 和
一个 post-processing 表达式：

@racketblock[
(define-curses getmouse (_fun (m : (_ptr o _MEVENT))
                              -> (r : _int)
                              -> (and (zero? r) m)))

(waddstr win (format "click me fast..."))
(wrefresh win)
(sleep 1)

(define m (getmouse))
(when m
  (waddstr win (format "at ~a,~a"
                       (MEVENT-x m)
                       (MEVENT-y m)))
  (wrefresh win)
  (sleep 1))

(endwin)               
]

@racket[_MEVENT-pointer] 和 @racket[_MEVENT] 之间的区别至关重要。
使用 @racket[(_ptr o _MEVENT-pointer)] 只会分配足够容纳指向
@cpp{MEVENT} struct 的指针的空间，这对于 @cpp{MEVENT} struct 来说是不够的。

@; --------------------------------------------------

@section{指针和手动内存分配}

为了从用户获取文本而不是鼠标点击，@filepath{libcurses} 提供了
@racket[wgetnstr]：

@verbatim[#:indent 2]{
int wgetnstr(WINDOW *win, char *str, int n);
}

虽然传递给 @racket[waddstr] 的 @cpp{char*} 参数被视为 nul-terminated string，
但传递给 @racket[wgetnstr] 的 @cpp{char*} 参数被视为一个缓冲区，
其大小由最终的 @cpp{int} 参数指示。C 类型 @racket[_string]
不适用于此类缓冲区。

在 Racket 中处理此函数的一种方式是以最原始的形式描述参数，
将第二个参数使用普通的 @racket[_pointer]：

@racket[
(define-curses wgetnstr (_fun _WINDOW-pointer _pointer _int
                              -> _int))
]

要调用这个原始版本的 @racket[wgetnstr]，需要分配内存，将其清零，
并将大小减一（以留出 nul terminator 的空间）传递给 @racket[wgetnstr]：

@racketblock[
(define SIZE 256)
(define buffer (malloc 'raw SIZE))
(memset buffer 0 SIZE)

(void (wgetnstr win buffer (sub1 SIZE)))
]

当 @racket[wgetnstr] 返回时，它已将字节写入 @racket[buffer]。此时，
我们可以使用 @racket[cast] 将值从原始指针转换为字符串：

@racketblock[
(cast buffer _pointer _string)
]

通过 @racket[_string] 类型进行转换会导致原始指针引用的数据被复制
（并进行 UTF-8 解码），因此 @racket[buffer] 引用的内存不再需要。
使用 @racket[(malloc 'raw ...)] 分配的内存必须使用 @racket[free] 释放：

@racketblock[
(free buffer)
]

@; --------------------------------------------------

@section{指针和 GC 管理的内存分配}

Instead of allocating @racket[buffer] with @racket[(malloc 'raw ...)],
we could have allocated it with @racket[(malloc 'atomic ...)]:

@racketblock[
(define buffer (malloc 'atomic SIZE))
]

使用 @racket['atomic] 分配的内存由 garbage collector 管理，因此
当 @racket[buffer] 引用的内存不再需要时，@racket[free] 既不需要也
不被允许。相反，当 @racket[buffer] 变得不可访问时，分配的内存将
自动被回收。

让 garbage collector (GC) 管理内存通常是更可取的。人们很容易忘记
调用 @racket[free]，而异常或线程终止很容易跳过一个 @racket[free]。

与此同时，使用 GC 管理的内存给程序员带来了不同的负担：当 GC
压缩已分配的对象以避免碎片化时，由 GC 管理的数据可能会被移动到新地址。
而 C 函数期望接收指向会留在原地的对象的指针。

幸运的是，除非一个 C 函数回调到 Racket 运行时系统（也许通过
作为参数提供的函数），否则在 C 被调用到函数返回之间不会发生
garbage collection。

让我们来看看与分配和指针相关的几种可能性：

@itemlist[

 @item{Ok:

  @racketblock[
    (define p (malloc 'atomic SIZE))
    (wgetnstr win p (sub1 SIZE))
  ]

 尽管 @racket[malloc] 分配的数据可以移动，@racket[p] 将始终
 指向它，并且在从 @racket[p] 提取地址传递给 @racket[wgetnstr]
 到 @racket[wgetnstr] 返回之间不会发生 garbage collection。}

 @item{Bad: 

  @racketblock[
   (define p (malloc 'atomic SIZE))
   (define i (cast p _pointer _intptr))
   (wgetnstr win (cast i _intptr _pointer) (sub1 SIZE))
  ]

  @racket[p] 引用的数据可能在地址被转换为整数后移动，
  在这种情况下，@racket[i] 转回 pointer 将是错误的地址。

  显然，将 pointer 转换为整数通常是一个坏主意，但该 cast
  模拟了另一种可能性：将 pointer 传递给一个 C 函数，该函数
  将 pointer 保留在其自己的私有存储中以供后续使用。
  这种私有存储对 Racket GC 是不可见的，因此它与将 pointer
  转换为整数具有相同的效果。}

 @item{Ok:

  @racketblock[
   (define p (malloc 'atomic SIZE))
   (define p2 (ptr-add p 4))
   (wgetnstr win p2 (- SIZE 5))
  ]  

 指针 @racket[p2] 保留原始引用，仅在调用 @racket[wgetnstr]
 前的最后一刻添加 @racket[4]（即，在允许 garbage collection 的节点之后）。}

 @item{Ok:

  @racketblock[
   (define p (malloc 'atomic-interior SIZE))
   (define i (cast p _pointer _intptr))
   (wgetnstr win (cast i _intptr _pointer) (sub1 SIZE))
  ]

 这是可以的，假设 @racket[p] 本身保持可访问，因此它引用的
 数据不会被回收。使用 @racket['atomic-interior] 分配会将数据
 放置在特定地址并使其保留在那里。garbage collection 不会改变
 @racket[p] 中的地址，因此 @racket[i] （转回 pointer）将
 始终引用该数据。}

]

请记住，像 @racket[make-MEVENT] 这样的 C struct 构造函数在效果上
等同于 @racket[(malloc 'atomic ...)]；结果值可以在 garbage collection
期间在内存中移动。使用 @racket[make-bytes] 分配的 byte string
也是如此，它们（为了方便）可以直接用作 pointer 值（不像 character
string，后者总是为了 UTF-8 编码或解码而被复制）。

有关内存管理和 garbage collection 的更多信息，参见
@|InsideRacket| 中的 @secref[#:doc InsideRacket-doc "cs-memory"]
和 @secref[#:doc InsideRacket-doc "im:memoryalloc"]。

@; --------------------------------------------------

@section{可靠释放资源}

使用 GC 管理的内存使你不必手动对普通内存块调用 @racket[free]，
但 C 库通常会分配资源并要求对释放资源的函数进行匹配调用。
例如，@filepath{libcurses} 支持屏幕上的窗口，
这些窗口用 @racket[newwin] 创建，用 @racket[delwin] 释放：

@verbatim[#:indent 2]{
WINDOW *newwin(int lines, int ncols, int y, int x);
int delwin(WINDOW *win);
}

在足够复杂的程序中，确保每个 @racket[newwin] 都与 @racket[delwin]
配对可能具有挑战性，特别是如果这些函数被来自库的
所谓的安全函数包裹。例如，一个旨在安全用于沙箱的库，
必须在沙箱程序行为异常或被终止时防止整个 Racket 进程内的
资源泄漏。

@racketmodname[ffi/unsafe/alloc] 库提供了用于连接资源分配函数
和资源释放函数的函数。然后，该库会安排 finalization，以便在资源
根据 GC 变得不可访问时（在显式释放之前）释放它。同时，
该库处理棘手的 atomicity 要求，以确保 finalization 被正确注册
且从不多次运行。

使用 @racketmodname[ffi/unsafe/alloc]，可以分别用
@racket[allocator] 和 @racket[deallocator] 包装器导入
@racket[newwin] 和 @racket[delwin] 函数：

@racketblock[
(require ffi/unsafe/alloc)

(define-curses delwin (_fun _WINDOW-pointer -> _int)
  #:wrap (deallocator))

(define-curses newwin (_fun _int _int _int _int 
                            -> _WINDOW-pointer)
  #:wrap (allocator delwin))
]

@racket[deallocator] 包装器会使一个函数取消该函数参数的
任何现有 finalizer。@racket[allocator] 包装器引用 deallocator，
以便在必要时可以由 finalizer 运行 deallocator。

如果资源稀缺或对最终用户可见，那么 @tech[#:doc
reference.scrbl]{custodian} 管理比 @racket[allocator] 实现的单纯
finalization 更合适。参见 @racketmodname[ffi/unsafe/custodian] 库。

@; --------------------------------------------------

@section{线程和 Place}

尽管旧版本的 @filepath{libcurses} 不是 thread-safe，Racket
线程并不对应于 OS 级别的线程，因此使用 Racket 线程调用
@filepath{libcurses} 函数不会产生特别的问题。

然而，Racket @tech-place[] 对应于 OS 级别的线程。当库
是 thread-safe 时，从多个 place 使用外部库是可行的。从多个 place
调用非 thread-safe 的库则需要更加小心。

从多个 place 使用非 thread-safe 库的最简单方法是指定 @racket[_fun]
的 @racket[#:in-original-place? #t] 选项，该选项将对函数的每次调用
路由通过原始 Racket place 而不是调用 place。我们最初从
@filepath{libcurses} 使用的大多数函数都可以简单地变为 thread-safe：

@racketblock[
(define-curses initscr
  (_fun #:in-original-place? #t -> _WINDOW-pointer))
(define-curses wrefresh
  (_fun #:in-original-place? #t _WINDOW-pointer -> _int))
(define-curses endwin
  (_fun #:in-original-place? #t -> _int))
]

@racket[waddstr] 函数并不那么简单。下面这个定义的
问题在于，传递给 @racket[waddstr] 的 string 参数在原始 place
完成 @racket[waddstr] 调用之前，可能在调用 place 中移动。
为了安全地调用 @racket[waddstr]，我们可以使用 @racket[_string/immobile]
类型，它使用 @racket['atomic-interior] 为 string 参数分配字节：

@racketblock[
(define _string/immobile
  (make-ctype _pointer
              (lambda (s)
                (define bstr (cast s _string _bytes))
                (define len (bytes-length bstr))
                (define p (malloc 'atomic-interior len))
                (memcpy p bstr len)
                p)
              (lambda (p)
                (cast p _pointer _string))))
 
(define-curses waddstr
  (_fun #:in-original-place? #t _WINDOW-pointer _string/immobile -> _int))
]

请注意，传递使用 @racket['interior]（而不是 @racket['atomic-interior]）
分配的内存仅对读取内存而不写入的函数是安全的。外部函数绝不能从
分配内存的 place 以外的 place 向 @racket['interior] 分配的内存
写入，这是因为写入的 place-specific 处理用于实现分代 garbage collection。

@; ------------------------------------------------------------

@section{更多示例}

有关常见 FFI 模式的更多示例，参见 @filepath{ffi/examples} 集合中
已定义的接口。另请参见 @cite["Barzilay04"]。


