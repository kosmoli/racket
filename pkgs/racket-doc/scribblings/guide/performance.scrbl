#lang scribble/doc
@(require scribble/manual "guide-utils.rkt"
          (for-label racket/flonum
                     racket/unsafe/ops
                     racket/performance-hint
                     ffi/unsafe))

@title[#:tag "performance"]{性能}

@section-index["benchmarking"]
@section-index["speed"]

Alan Perlis 曾有名言："Lisp 程序员知道一切的价值，却不知道任何东西的代价。"而 Racket 程序员知道，例如，程序中任何位置的 @racket[lambda] 都会产生一个封闭在其词法环境上的值——但分配这个值的代价是多少？虽然大多数程序员对机器层面各种操作和数据结构的代价有合理的把握，但 Racket 语言模型与底层计算引擎之间的鸿沟可能相当大。

在本章中，我们通过解释 Racket 编译器与运行时系统的细节，以及它们如何影响 Racket 代码的运行时性能与内存性能，来弥合这一鸿沟。

@; ----------------------------------------------------------------------

@section[#:tag "DrRacket-perf"]{DrRacket 中的性能}

默认情况下，DrRacket 会对程序进行调试插桩，而调试插桩（由
@other-doc['(lib "errortrace/scribblings/errortrace.scrbl")]
库提供）可能会显著降低某些程序的性能。即使在
@onscreen{Choose Language...} 对话框的 @onscreen{Show Details} 面板中禁用了调试，
@onscreen{Preserve stacktrace} 复选框默认也是勾选的，这也会影响性能。禁用调试和堆栈跟踪
保留可以使性能结果与在纯 @exec{racket} 中运行时更加一致。

即便如此，DrRacket 和在 DrRacket 中开发的程序使用相同的
Racket 虚拟机，因此垃圾回收时间（参见
@secref["gc-perf"]）在 DrRacket 中可能比程序单独运行时更长，而且 DrRacket 线程可能会阻碍程序线程的执行。
@bold{要获得程序最可靠的计时结果，请在纯 @exec{racket} 中运行，而不是在 DrRacket 开发环境中。}
应使用非交互模式而非 @tech["REPL"] 来受益于模块系统。详见
@secref["modules-performance"]。

@; ----------------------------------------------------------------------

@section[#:tag "virtual-machines"]{Racket 虚拟机实现}

Racket 提供两种实现，@deftech{CS} 和
@deftech{BC}：

@itemlist[

 @item{@tech{CS} 是当前的默认实现。它是
       基于 @hyperlink["https://www.scheme.com/"]{Chez Scheme} 作为核心
       虚拟机构建的较新实现。对于大多数程序，此实现的性能优于
       @tech{BC} 实现。

       对于此实现，@racket[(system-type 'vm)] 报告
       @racket['chez-scheme]，@racket[(system-type 'gc)] 报告
       @racket['cs]。}

 @item{@tech{BC} 是较旧的实现，在 8.0 版本之前一直是默认实现。
       该实现具有用 C 编写的编译器和运行时，
       在大多数平台上配备精确垃圾回收器和即时编译器（JIT）。

       对于此实现，@racket[(system-type 'vm)] 报告
       @racket['racket]。

       BC 实现本身有两个变体，@deftech{3m} 和
       @deftech{CGC}：

       @itemlist[

        @item{@tech{3m} 是正常的 BC 变体，具有精确的
             垃圾回收器。

             对于此变体，@racket[(system-type 'gc)] 报告
            @racket['3m]。}


        @item{@tech{CGC} 是最古老的变体。它与 @tech{3m} 具有相同的基本
              实现（即相同的虚拟机），但编译为依赖"保守式"
              垃圾回收器，这会影响 Racket 与 C 代码交互的方式。详见
              @other-manual[inside-doc] 中的 @secref["CGC versus 3m"
              #:doc inside-doc]。

              对于此变体，@racket[(system-type 'gc)] 报告
              @racket['cgc]。}

       ]}

]

一般而言，Racket 程序在所有变体中的运行行为应该相同。
此外，Racket 程序的性能特征在 @tech{CS} 和 @tech{BC} 实现中应该
相似。程序可能依赖于实现的情况通常
涉及与外部库的交互；特别是，
@other-doc[inside-doc] 中描述的 Racket C API 在
@tech{CS} 实现与 @tech{BC} 实现中是不同的。

@; ----------------------------------------------------------------------

@section[#:tag "JIT"]{字节码、机器码和即时 (JIT) 编译器}

Racket 要计算的每个定义或表达式都会被编译
为内部字节码格式，尽管"字节码"实际上可能是
本机机器码。在交互模式下，此编译会
自动即时进行。@exec{raco make} 和
@exec{raco setup} 等工具将编译后的字节码编组到文件中，这样您每次运行程序时
就不必从源代码重新编译。
有关生成字节码文件的更多信息，请参见 @secref["compile"]。

字节码编译器应用所有标准优化，如
常量传播、常量折叠、内联和死代码
消除。例如，在 @racket[+] 具有其常规绑定的环境中，
表达式 @racket[(let ([x 1] [y (lambda () 4)]) (+ 1 (y)))] 被编译为与常量 @racket[5] 相同。

对于 Racket 的 @tech{CS} 实现，主要的字节码格式
是不可移植的机器码。对于 Racket 的 @tech{BC} 实现，
字节码在机器无关的意义上是可移植的。
将 @racket[current-compile-target-machine] 设置为
@racket[#f] 可在所有 Racket 实现上选择独立的机器无关且
变体无关的格式，但以该格式运行代码需要额外的内部转换步骤来转换为
实现的主要字节码格式。

@tech{BC} 实现的机器无关字节码进一步
通过 @deftech{即时}或 @deftech{JIT} 编译器编译为本机代码。
@tech{JIT} 编译器显著加速执行紧密循环、小整数算术以及
非精确实数算术的程序。目前，@tech{JIT} 编译支持
x86、x86_64（即 AMD64）、32 位 ARM 和 32 位 PowerPC 处理器。
@tech{JIT} 编译器可以通过
@racket[eval-jit-enabled] 参数或 @exec{racket} 的 @DFlag{no-jit}/@Flag{j}
命令行标志来禁用。将 @racket[eval-jit-enabled]
设置为 @racket[#f] 对 Racket 的 @tech{CS} 实现没有影响。

@tech{JIT} 编译器在函数被应用时增量工作，
但 @tech{JIT} 编译器在编译过程时仅有限地使用运行时
信息，因为给定模块体或 @racket[lambda] 抽象体的代码只编译一次。
@tech{JIT} 的编译粒度是单个过程体，
不包括任何词法嵌套过程的过程体。
@tech{JIT} 编译的开销通常非常小，以至于难以察觉。

有关查看 Racket 中间代码表示的信息，特别是
@tech{CS} 实现的，请参见
@refsecref["compiler-inspect"]。

@; ----------------------------------------------------------------------

@section[#:tag "modules-performance"]{模块与性能}

模块系统通过帮助确保标识符具有常规绑定来辅助优化。
也就是说，@racketmodname[racket/base] 提供的 @racket[+] 可以被编译器识别并
内联。相比之下，在传统的交互式 Scheme 系统中，顶层
@racket[+] 绑定可能被重新定义，因此编译器无法假定固定的
@racket[+] 绑定（除非使用特殊标志或声明
来弥补模块系统的缺失）。

即使在顶层环境中，使用 @racket[require] 导入
也能启用一些内联优化。尽管顶层的 @racket[+] 定义
可能会遮蔽导入的 @racket[+]，但遮蔽
定义仅适用于之后计算的表达式。

在模块内部，内联和常量传播优化还额外利用了模块内部的定义
在编译时没有可见的 @racket[set!] 时不可变的事实。
此类优化在顶层环境中不可用。
尽管模块内部的这种优化对性能很重要，但它会阻碍某些形式的交互式开发和探索。
当交互式探索更重要时，@racket[compile-enforce-module-constants] 参数
会禁用编译器对模块定义的假设。详见
@secref["module-set"]。

编译器可以跨模块边界内联函数或传播常量。
为了避免在函数内联的情况下生成过多代码，编译器在选择跨模块内联候选时
是保守的；有关向编译器提供内联提示的信息，请参见
@secref["func-call-performance"]。

后面的 @secref["letrec-performance"] 节提供了有关模块绑定内联的
一些额外注意事项。

@; ----------------------------------------------------------------------

@section[#:tag "func-call-performance"]{函数调用优化}

当编译器检测到对立即可见函数的函数调用时，
它会生成比泛型调用更高效的代码，特别是对于尾调用。例如，给定程序

@racketblock[
(letrec ([odd (lambda (x) 
                (if (zero? x) 
                    #f 
                    (even (sub1 x))))] 
         [even (lambda (x) 
                 (if (zero? x) 
                     #t 
                     (odd (sub1 x))))]) 
  (odd 40000000))
]

编译器可以检测到 @racket[odd]--@racket[even] 循环，并
通过循环展开和相关优化生成运行速度显著更快的代码。

在模块形式内部，@racket[define] 定义的变量像 @racket[letrec] 绑定一样是词法作用域的，
因此模块内部的定义允许调用优化，所以

@racketblock[
(define (odd x) ....)
(define (even x) ....)
]

在模块内部的性能与 @racket[letrec] 版本相同。

对于带关键字参数的函数的直接调用，编译器通常可以静态检查关键字参数，
并生成对函数非关键字变体的直接调用，从而减少
关键字检查的运行时开销。此优化仅适用于
使用 @racket[define] 绑定的接受关键字的过程。

对于足够小的函数的立即调用，编译器
可以通过用函数体替换调用来内联函数调用。
除了目标函数体的大小之外，编译器的启发式算法还考虑
调用点已经执行的内联量，以及被调用函数
本身是否调用了除简单原始操作之外的函数。当
模块被编译时，在模块级别定义的一些函数被
确定为可内联到其他模块的候选；通常，
只有平凡函数才被视为跨模块内联的候选，
但程序员可以使用
@racket[begin-encourage-inline] 包装函数定义来鼓励函数内联。

诸如 @racket[pair?]、@racket[car] 和
@racket[cdr] 之类的原始操作由字节码或 @tech{JIT}
编译器在机器码级别内联。另请参见后面的 @secref["fixnums+flonums"] 节了解
有关内联算术运算的信息。

@; ----------------------------------------------------------------------

@section{变更与性能}

使用 @racket[set!] 修改变量可能导致性能不佳。例如，以下微基准测试

@racketmod[
racket/base

(define (subtract-one x)
  (set! x (sub1 x))
  x)

(time
  (let loop ([n 4000000])
    (if (zero? n)
        'done
        (loop (subtract-one n)))))
]

运行速度比等效的以下代码慢得多

@racketmod[
racket/base

(define (subtract-one x)
  (sub1 x))

(time
  (let loop ([n 4000000])
    (if (zero? n)
        'done
        (loop (subtract-one n)))))
]

在第一种变体中，每次迭代都会为 @racket[x] 分配一个新位置，
导致性能不佳。更智能的编译器可以解开第一个例子中 @racket[set!] 的用法，但由于
不鼓励使用 mutation（参见 @secref["using-set!"]），编译器的
精力花在了其他地方。

更重要的是，mutation 可能遮蔽绑定，使内联和常量传播
无法应用。例如，在

@racketblock[
(let ([minus1 #f])
  (set! minus1 sub1)
  (let loop ([n 4000000])
    (if (zero? n)
        'done
        (loop (minus1 n)))))
]

@racket[set!] 遮蔽了 @racket[minus1] 只是内置 @racket[sub1] 的另一个名称这一事实。

@; ----------------------------------------------------------------------

@section[#:tag "letrec-performance"]{@racket[letrec] 性能}

当 @racket[letrec] 仅用于绑定过程和字面量时，
编译器可以以最优方式处理这些绑定，
高效地编译对绑定的使用。当其他类型的
绑定与过程混合时，编译器可能较难确定控制流。

For example,

@racketblock[
(letrec ([loop (lambda (x) 
                (if (zero? x) 
                    'done
                    (loop (next x))))] 
         [junk (display loop)]
         [next (lambda (x) (sub1 x))])
  (loop 40000000))
]

编译出的代码效率可能低于

@racketblock[
(letrec ([loop (lambda (x) 
                (if (zero? x) 
                    'done
                    (loop (next x))))] 
         [next (lambda (x) (sub1 x))])
  (loop 40000000))
]

在第一种情况下，编译器可能不知道
@racket[display] 不会调用 @racket[loop]。如果它调用了，那么
@racket[loop] 可能在绑定可用之前就引用了 @racket[next]。

关于 @racket[letrec] 的此注意事项也适用于作为内部定义或模块中
函数和常量的定义。模块体中的
定义序列类似于一系列
@racket[letrec] 绑定，模块体中的非常量表达式
可能干扰对后续绑定引用的优化。

@; ----------------------------------------------------------------------

@section[#:tag "fixnums+flonums"]{Fixnum 和 Flonum 优化}

@deftech{fixnum} 是一个小的精确整数。这里的"小"
取决于平台。对于 32 位机器，可以用
29-30 位加一个符号位表示的数字被表示为 fixnum。在
64 位机器上，可用 60-62 位加一个符号位。

@deftech{flonum} 用于表示任何非精确实数。它们在所有平台上
对应 64 位 IEEE 浮点数。

内联的 fixnum 和 flonum 算术运算是编译器最重要的优势之一。
例如，当 @racket[+] 应用于两个参数时，生成的机器码
会测试两个参数是否都是 fixnum，如果是，则使用
机器的指令相加（并检查溢出）。如果
两个数不是 fixnum，则检查
是否都是 flonum；在这种情况下，直接使用机器的浮点
运算。对于接受任意数量参数的函数，
如 @racket[+]，内联适用于两个或更多
参数（除了 @racket[-]，其单参数情况也会
内联），前提是参数要么全是 fixnum 要么全是 flonum。

Flonum 通常是 @defterm{装箱}的，这意味着需要分配内存
来保存 flonum 计算的每个结果。幸运的是，
分代垃圾回收器（稍后在
@secref["gc-perf"] 中描述）使短期结果的分配
相对廉价。相比之下，Fixnum 从不装箱，因此使用成本通常很低。

@margin-note{参见 @secref["effective-futures"] 了解使用
@tech{flonum} 特定操作的示例。}

@racketmodname[racket/flonum] 库提供了 flonum 特定的
操作，flonum 操作的组合允许编译器
生成避免对中间结果装箱和拆箱的代码。
除了立即组合中的结果之外，
使用 @racket[let] 绑定并由后续 flonum 特定操作消费的
flonum 特定结果会在临时存储中拆箱。
@margin-note*{拆箱最可靠地适用于带有两个参数的 flonum 特定操作。}
最后，编译器可以检测一些 flonum 值的循环
累加器，并避免对累加器装箱。
@margin-note*{@tech{BC} 实现的 PowerPC JIT 不支持对局部绑定和累加器的拆箱。}

对于某些循环模式，编译器可能需要提示来启用拆箱。例如：

@racketblock[
(define (flvector-sum vec init)
  (let loop ([i 0] [sum init])
    (if (fx= i (flvector-length vec))
        sum
        (loop (fx+ i 1) (fl+ sum (flvector-ref vec i))))))
]

在此示例中，编译器可能无法对 @racket[sum] 拆箱，原因有两个：
它无法在局部确定来自 @racket[init] 的初始值将是 flonum，
并且无法在局部判断结果 @racket[sum] 的 @racket[eq?] 同一性无关紧要。
将对 @racket[init] 的引用改为 @racket[(fl+ init)] 并
将结果 @racket[sum] 改为 @racket[(fl+ sum)] 为编译器提供了对 @racket[sum] 拆箱的提示和许可。

@tech{BC} 实现的字节码反编译器（参见 @secref[#:doc '(lib
"scribblings/raco/raco.scrbl") "decompile"]）
用 @racketidfont{#%flonum}、@racketidfont{#%as-flonum} 和
@racketidfont{#%from-flonum} 标注 JIT 可以避免装箱的组合。
对于 @tech{CS} 变体，"字节码"反编译器显示机器码，但安装
@filepath{disassemble} 包可能可以看到作为机器特定汇编代码的机器码。
另请参见 @refsecref["compiler-inspect"]。

@racketmodname[racket/unsafe/ops] 库提供了未经检查的
fixnum 和 flonum 特定操作。未经检查的 flonum 特定
操作允许拆箱，有时还允许编译器
重新排序表达式以提高性能。另请参见
@secref["unchecked-unsafe"]，特别是有关不安全的警告。

@; ----------------------------------------------------------------------

@section[#:tag "unchecked-unsafe"]{未经检查的不安全操作}

@racketmodname[racket/unsafe/ops] 库提供的函数类似于
@racketmodname[racket/base] 中的其他函数，但它们假定
（而非检查）提供的参数是正确的类型。例如，
@racket[unsafe-vector-ref] 访问向量中的元素时
不检查其第一个参数是否确实是向量，
也不检查给定的索引是否在边界内。对于使用这些函数的紧密循环，
避免检查有时可以加速计算，尽管不同的未经检查函数和不同的上下文
带来的好处各不相同。

请注意，正如库名和函数名中的"unsafe"所暗示的那样，
滥用 @racketmodname[racket/unsafe/ops] 的导出可能导致
崩溃或内存损坏。

@; ----------------------------------------------------------------------

@section[#:tag "ffi-pointer-access"]{外部指针}

@racketmodname[ffi/unsafe] 库提供了不安全地
读写任意指针值的函数。编译器识别
@racket[ptr-ref] 和 @racket[ptr-set!] 的用法，其中第二个参数是
对以下内置 C 类型之一的直接引用：
@racket[_int8]、@racket[_int16]、@racket[_int32]、@racket[_int64]、
@racket[_double]、@racket[_float] 和 @racket[_pointer]。然后，如果
@racket[ptr-ref] 或 @racket[ptr-set!] 的第一个参数是 C 指针
（而非字节字符串），则指针的读取或写入在生成的代码中
内联执行。

字节码编译器会将整数缩写（如 @racket[_int]）优化为 C 类型（如
@racket[_int32]）——这些类型在各平台上的表示大小是恒定的
——因此编译器可以使用这些 C 类型进行特化访问。
C 类型如 @racket[_long] 或 @racket[_intptr] 在各平台上不是恒定的，
因此其使用不会得到一致的特化。

使用 @racket[_float] 或 @racket[_double] 的指针读写
目前不受拆箱优化的影响。

@; ----------------------------------------------------------------------

@section[#:tag "regexp-perf"]{正则表达式性能}

当字符串或字节字符串被提供给诸如
@racket[regexp-match] 之类的函数时，该字符串会在内部编译为
@tech{regexp} 值。与其多次提供字符串或字节字符串
作为匹配模式，不如使用 @racket[regexp]、@racket[byte-regexp]、
@racket[pregexp] 或 @racket[byte-pregexp] 将模式编译一次为
@tech{regexp} 值。在常量字符串或字节字符串的位置，
使用 @litchar{#rx} 或 @litchar{#px} 前缀编写常量 @tech{regexp}。

@racketblock[
(define (slow-matcher str)
  (regexp-match? "[0-9]+" str))

(define (fast-matcher str)
  (regexp-match? #rx"[0-9]+" str))

(define (make-slow-matcher pattern-str)
  (lambda (str)
    (regexp-match? pattern-str str)))

(define (make-fast-matcher pattern-str)
  (define pattern-rx (regexp pattern-str))
  (lambda (str)
    (regexp-match? pattern-rx str)))
]

@; ----------------------------------------------------------------------

@section[#:tag "gc-perf"]{内存管理}

@tech{CS}（默认）和 @tech{BC} Racket
@seclink["virtual-machines"]{虚拟机}各自使用现代的
@deftech{分代垃圾回收器}，使得短生命周期对象的分配
相对廉价。@tech{BC} 的 @tech{CGC} 变体使用
@deftech{保守垃圾回收器}，它便于
与 C 代码交互，但以 Racket 内存管理的精度和速度为代价。

尽管内存分配相对廉价，但完全避免分配通常更快。
有时可以避免分配的一个特定场景是 @deftech{闭包}，
即包含自由变量的函数的运行时表示。
例如，

@racketblock[
(let loop ([n 40000000] [prev-thunk (lambda () #f)])
  (if (zero? n)
      (prev-thunk)
      (loop (sub1 n)
            (lambda () n))))
]

每次迭代都会分配一个闭包，因为 @racket[(lambda () n)]
实际上保存了 @racket[n]。

编译器可以自动消除许多闭包。例如，
在

@racketblock[
(let loop ([n 40000000] [prev-val #f])
  (let ([prev-thunk (lambda () n)])
    (if (zero? n)
        prev-val
        (loop (sub1 n) (prev-thunk)))))
]

@racket[prev-thunk] 永远不会分配闭包，因为其唯一
应用是可见的，因此被内联了。类似地，在

@racketblock[
(let n-loop ([n 400000])
  (if (zero? n)
      'done
      (let m-loop ([m 100])
        (if (zero? m)
            (n-loop (sub1 n))
            (m-loop (sub1 m))))))
]

扩展开 @racket[let] 形式来实现
@racket[m-loop] 涉及对 @racket[n] 的闭包，但编译器
会自动将闭包转换为将 @racket[n] 作为参数传递给自身。

@section[#:tag "Reachability and Garbage Collection"]{可达性与垃圾回收}

一般来说，当垃圾回收器能够证明某个对象从任何其他（可达的）值
都不可达时，Racket 会重用一个值的存储空间。可达性是一个底层的、
打破抽象的概念，因此需要详细了解运行时系统
才能准确预测值之间何时相互可达。但
一般来说，当存在某种操作可以从第二个值恢复原始值时，一个值就从
第二个值可达。

为了帮助程序员理解对象何时不再可达以及其
存储何时可以被重用，
Racket 提供了 @racket[make-weak-box] 和 @racket[weak-box-value]，
这是垃圾回收器特殊对待的单记录结构体的创建器和访问器。
弱盒子内的对象不计为可达，因此 @racket[weak-box-value] 可能返回
盒子内的对象，但也可能返回 @racket[#f] 以表示
该对象在其他方面已不可达并被垃圾回收。
请注意，除非实际发生了垃圾回收，否则即使
该值不可达，它也将保留在弱盒子内。

例如，考虑以下程序：
@racketmod[racket
           (struct fish (weight color) #:transparent)
           (define f (fish 7 'blue))
           (define b (make-weak-box f))
           (printf "b has ~s\n" (weak-box-value b))
           (collect-garbage)
           (printf "b has ~s\n" (weak-box-value b))]
它会打印两次 @litchar{b has #(struct:fish 7 blue)}，因为
@racket[f] 的定义仍然持有那条鱼。然而，如果程序是这样：
@racketmod[racket
           (struct fish (weight color) #:transparent)
           (define f (fish 7 'blue))
           (define b (make-weak-box f))
           (printf "b has ~s\n" (weak-box-value b))
           (set! f #f)
           (collect-garbage)
           (printf "b has ~s\n" (weak-box-value b))]
第二次打印将是 @litchar{b has #f}，因为
不存在对鱼的引用（除了盒子中的那个）。

作为第一近似，Racket 中的所有值都必须分配，并且将表现出
类似于上述鱼的行为。然而，有一些例外：
@itemlist[@item{小整数（可通过 @racket[fixnum?] 识别）
                始终可用，无需显式分配。从垃圾回收器
                和弱盒子的角度来看，它们的存储永远不会被回收。（然而，由于
                巧妙的表示技术，它们的存储
                不计入 Racket 使用的空间。
                也就是说，它们实际上是免费的。）}
         @item{编译器能够看到所有调用点的过程可能永远不会
               被分配（如上所述）。
               类似的优化也可能消除
               其他类型值的分配。}
         @item{驻留符号（interned symbols）只分配一次（每个 place）。Racket 内部的
               表跟踪此分配，因此符号可能不会成为垃圾，
               因为该表持有它。}
         @item{对于 @tech{CGC} 收集器，可达性只是近似的（即，
               一个值可能在该收集器看来是可达的，而实际上
               已经无法再访问它了）。}]

@section{弱盒子与测试}

弱盒子的一个重要用途是测试某个抽象是否正确
释放了不再需要的数据的存储空间，但有一个陷阱
很容易导致此类测试用例错误地通过。

假设你正在设计一个数据结构，它需要
暂时持有某个值，但之后应该清除一个字段或
以某种方式断开链接以避免引用该值，从而使其能够被回收。
弱盒子是测试你的数据结构是否正确清除值的好方法。
也就是说，你可能会编写一个测试用例，
它构建一个值，从中提取另一个值
（你希望该值变得不可达），将提取的值放入弱盒子，
然后检查该值是否从盒子中消失。

以下代码是遵循该模式的一次尝试，但它有一个微妙的 bug：
@racketmod[racket
           (let* ([fishes (list (fish 8 'red)
                                (fish 7 'blue))]
                  [wb (make-weak-box (list-ref fishes 0))])
             (collect-garbage)
             (printf "still there? ~s\n" (weak-box-value wb)))]
具体来说，它会显示弱盒子为空，但并不是
因为 @racket[_fishes] 不再持有该值，而是
因为 @racket[_fishes] 本身不再可达了！

将程序改为以下版本：
@racketmod[racket
           (let* ([fishes (list (fish 8 'red)
                                (fish 7 'blue))]
                  [wb (make-weak-box (list-ref fishes 0))])
             (collect-garbage)
             (printf "still there? ~s\n" (weak-box-value wb))
             (printf "fishes is ~s\n" fishes))]
现在我们看到了预期的结果。区别在于变量 @racket[_fishes]
的最后一次出现。这构成了对列表的引用，确保列表本身
不会被垃圾回收，因此红色的鱼也不会。


@section{减少垃圾回收暂停}

默认情况下，Racket 的 @tech{分代垃圾回收器}会为频繁的
@deftech{小型回收}（仅检查最近分配的对象）产生短暂的暂停，
以及为不频繁的 @deftech{大型回收}（重新检查所有内存）产生长时间的暂停。

对于某些应用，如动画和游戏，
由于大型回收导致的长时间暂停可能会
不可接受地干扰程序的运行。为了减少大型回收的暂停，
@tech{3m} 垃圾回收器支持 @deftech{增量垃圾回收}模式，
而 @tech{CS} 垃圾回收器支持一个有用的近似方案：

@itemlist[

@item{在 @tech{3m} 的增量模式下，小型回收会产生更长的
      （但仍然相对较短的）暂停，因为它会为下一次大型回收
      执行额外的工作。如果一切顺利，到需要大型回收时，
      大部分大型回收的工作已经由小型回收完成了，
      因此大型回收的暂停与小型回收的暂停一样短。
      增量模式总体上往往运行得更慢，但它可以提供
      更加一致的实时行为。}

@item{在 @tech{CS} 的增量模式下，对象永远不会被提升出
      "最近分配"的类别，尽管有不同程度的"最近"，
      使得大多数小型回收仍然可以跳过
      最近但不太近的对象。在常见情况下，
      动画或游戏的大多数内存使用在启动时分配
      （包括其代码和 Racket 运行时系统的代码），
      可能永远不需要大型回收。}

]

如果在 Racket 启动时将 @envvar{PLT_INCREMENTAL_GC} 环境变量设置为
以 @litchar{0}、@litchar{n} 或 @litchar{N} 开头的值，则增量模式
将被永久禁用。对于 @tech{3m}，如果在 Racket 启动时将
@envvar{PLT_INCREMENTAL_GC} 环境变量设置为以 @litchar{1}、@litchar{y} 或
@litchar{Y} 开头的值，则增量模式将永久启用。
然而，由于增量模式只对某些程序的某些部分有用，
并且由于是否需要增量模式是程序的属性而非其环境的属性，
启用增量模式的首选方式是使用 @racket[(collect-garbage 'incremental)]。

调用 @racket[(collect-garbage 'incremental)] 不会执行
立即的垃圾回收，而是请求每个小型回收
执行增量工作直到下一次大型回收
（除非增量模式被永久禁用）。该请求
在下一次大型回收时过期。在应用程序中
任何需要实时响应的重复任务中调用
@racket[(collect-garbage 'incremental)]。在初始
@racket[(collect-garbage 'incremental)] 之前使用
@racket[(collect-garbage)] 强制执行一次完整回收，
以从最优状态启动增量模式。

要检查增量模式是否在使用中以及它如何影响暂停时间，
请为 @racketidfont{GC} 主题启用 @tt{debug} 级别的日志输出。例如，

@commandline{racket -W "debug@"@"GC error" main.rkt}

运行 @filepath{main.rkt} 并将垃圾回收日志输出到 stderr
（同时保留所有主题的 @tt{error} 级别日志）。小型
回收由 @litchar{min} 行报告，@tech{3m} 上的增量模式小型
回收由 @litchar{mIn} 行报告，大型
回收由 @litchar{MAJ} 行报告。
