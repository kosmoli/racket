#lang scribble/doc
@(require scribble/manual scribble/eval racket/class "guide-utils.rkt"
          (for-label racket/class racket/trait racket/contract))

@(define class-eval
   (let ([e (make-base-eval)])
     (e '(require racket/class))
     e))

@; FIXME: at some point, discuss classes vs. units vs. modules


@title[#:tag "classes"]{Classes and Objects}

@margin-note{This chapter is based on a paper @cite["Flatt06"].}
@hash-lang-note[racket/class #:lang racket/base]

@racket[class] 表达式表示一个一等值，
就像 @racket[lambda] 表达式一样：

@specform[(class superclass-expr decl-or-expr ...)]

@racket[_superclass-expr] 决定新类的超类。每个
@racket[_decl-or-expr] 要么是与方法、字段和初始化参数相关的声明，
要么是每次实例化类时求值的表达式。换句话说，类没有像方法一样的
构造函数，而是将初始化表达式与字段和方法声明交错排列。

按照惯例，类名以 @racketidfont{%} 结尾。内置根类是
@racket[object%]。以下表达式创建一个具有公共方法
@racket[get-size]、@racket[grow] 和 @racket[eat] 的类：

@racketblock[
(class object%
  (init size)                (code:comment #,(t "initialization argument"))

  (define current-size size) (code:comment #,(t "field"))

  (super-new)                (code:comment #,(t "superclass initialization"))

  (define/public (get-size)
    current-size)

  (define/public (grow amt)
    (set! current-size (+ amt current-size)))

  (define/public (eat other-fish)
    (grow (send other-fish get-size))))
]

@(interaction-eval
#:eval class-eval
(define fish%
  (class object%
    (init size)
    (define current-size size)
    (super-new)
    (define/public (get-size)
      current-size)
    (define/public (grow amt)
      (set! current-size (+ amt current-size)))
    (define/public (eat other-fish)
      (grow (send other-fish get-size))))))

通过 @racket[new] 形式实例化类时，必须通过命名参数
提供 @racket[size] 初始化参数：

@racketblock[
(new (class object% (init size) ....) [size 10])
]

当然，我们也可以为类及其实例命名：

@racketblock[
(define fish% (class object% (init size) ....))
(define charlie (new fish% [size 10]))
]

@(interaction-eval
#:eval class-eval
(define charlie (new fish% [size 10])))

在 @racket[fish%] 的定义中，@racket[current-size] 是一个
私有字段，初始值为 @racket[size] 初始化参数的值。像
@racket[size] 这样的初始化参数仅在类实例化期间可用，
因此不能从方法中直接引用它们。相比之下，
@racket[current-size] 字段对方法是可用的。

@racket[fish%] 中的 @racket[(super-new)] 表达式调用超类的
初始化。在这种情况下，超类是 @racket[object%]，它不接受
初始化参数且不执行任何工作；无论如何必须使用
@racket[super-new]，因为类总是必须调用其超类的初始化。

初始化参数、字段声明和像 @racket[(super-new)] 这样的表达式
可以在 @racket[class] 中以任意顺序出现，并且可以与方法声明
交错排列。类中表达式的相对顺序决定了实例化期间的求值顺序。
例如，如果字段的初始值需要调用仅在超类初始化之后才能工作的
方法，则字段声明必须放在 @racket[super-new] 调用之后。
以这种方式排列字段和初始化声明有助于避免命令式赋值。
方法声明的相对顺序对求值没有影响，因为方法在类实例化之前
就已经完全定义了。

@section[#:tag "methods"]{Methods}

@racket[fish%] 中的三个 @racket[define/public] 声明各引入一个
新方法。声明使用与 Racket 函数相同的语法，但方法不能作为独立
函数访问。调用 @racket[fish%] 对象的 @racket[grow] 方法需要
使用 @racket[send] 形式：

@interaction[
#:eval class-eval
(send charlie grow 6)
(send charlie get-size)
]

在 @racket[fish%] 内部，self 方法可以像函数一样调用，
因为方法名在作用域内。例如，@racket[fish%] 中的
@racket[eat] 方法直接调用 @racket[grow] 方法。在类内部，
尝试以方法调用之外的任何方式使用方法名都会导致语法错误。

在某些情况下，类必须调用由超类提供但未被覆盖的方法。
在这种情况下，类可以使用 @racket[send] 配合 @racket[this]
来访问该方法：

@def+int[
#:eval class-eval
(define hungry-fish% (class fish% (super-new)
                       (define/public (eat-more fish1 fish2)
                         (send this eat fish1)
                         (send this eat fish2))))
]

或者，类可以使用 @racket[inherit] 声明方法的存在，
这将方法名带入直接调用的作用域：

@def+int[
#:eval class-eval
(define hungry-fish% (class fish% (super-new)
                       (inherit eat)
                       (define/public (eat-more fish1 fish2)
                         (eat fish1) (eat fish2))))
]

使用 @racket[inherit] 声明，如果 @racket[fish%] 没有提供
@racket[eat] 方法，则在求值 @racket[hungry-fish%] 的
@racket[class] 形式时会发出错误信号。相比之下，使用
@racket[(send this ....)]，直到调用 @racket[eat-more] 方法
并求值 @racket[send] 形式时才会发出错误信号。因此，
@racket[inherit] 更受欢迎。

@racket[send] 的另一个缺点是它比 @racket[inherit] 效率更低。
通过 @racket[send] 调用方法涉及在运行时在目标对象的类中查找
方法，使得 @racket[send] 类似于 Java 中基于接口的方法调用。
相比之下，基于 @racket[inherit] 的方法调用使用类的方法表中
的偏移量，该偏移量在类创建时计算。

为了在从方法所属类的外部调用方法时获得与基于
@racket[inherit] 的方法调用类似的性能，程序员必须使用
@racket[generic] 形式，它产生特定于类和方法的
@defterm{泛型方法}，用 @racket[send-generic] 调用：

@def+int[
#:eval class-eval
(define get-fish-size (generic fish% get-size))
(send-generic charlie get-fish-size)
(send-generic (new hungry-fish% [size 32]) get-fish-size)
(send-generic (new object%) get-fish-size)
]

粗略地说，该形式将类和外部方法名转换为类方法表中的位置。
如最后一个示例所示，通过泛型方法发送会检查其参数是否为
泛型方法所在类的实例。

无论是在 @racket[class] 内部直接调用方法，
通过泛型方法，还是通过 @racket[send]，
方法覆盖都按通常的方式工作：

@defs+int[
#:eval class-eval
[
(define picky-fish% (class fish% (super-new)
                      (define/override (grow amt)
                        ;; Doesn't eat all of its food
                        (super grow (* 3/4 amt)))))
(define daisy (new picky-fish% [size 20]))
]
(send daisy eat charlie)
(send daisy get-size)
]

@racket[picky-fish%] 中的 @racket[grow] 方法使用
@racket[define/override] 而不是 @racket[define/public] 声明，
因为 @racket[grow] 是一个覆盖声明。如果 @racket[grow] 用
@racket[define/public] 声明，则在求值 @racket[class] 表达式
时会发出错误信号，因为 @racket[fish%] 已经提供了
@racket[grow]。

使用 @racket[define/override] 还允许通过 @racket[super] 调用
被覆盖的方法。例如，@racket[picky-fish%] 中的
@racket[grow] 实现使用 @racket[super] 委托给超类的实现。

@section[#:tag "initargs"]{Initialization Arguments}

由于 @racket[picky-fish%] 不声明任何初始化参数，
@racket[(new picky-fish% ....)] 中提供的任何初始化值
都会传播到超类初始化，即 @racket[fish%]。子类可以在
@racket[super-new] 调用中为其超类提供额外的初始化参数，
这些初始化参数优先于提供给 @racket[new] 的参数。例如，
下面的 @racket[size-10-fish%] 类总是生成大小为 10 的鱼：

@def+int[
#:eval class-eval
(define size-10-fish% (class fish% (super-new [size 10])))
(send (new size-10-fish%) get-size)
]

对于 @racket[size-10-fish%]，使用 @racket[new] 提供
@racket[size] 初始化参数会导致初始化错误；因为
@racket[super-new] 中的 @racket[size] 优先，提供给
@racket[new] 的 @racket[size] 将没有目标声明。

如果 @racket[class] 形式声明了默认值，则初始化参数是可选的。
例如，下面的 @racket[default-10-fish%] 类接受一个
@racket[size] 初始化参数，但如果在实例化时未提供值，
则其值默认为 10：

@def+int[
#:eval class-eval
(define default-10-fish% (class fish%
                           (init [size 10])
                           (super-new [size size])))
(new default-10-fish%)
(new default-10-fish% [size 20])
]

在此示例中，@racket[super-new] 调用将其自身的
@racket[size] 值作为 @racket[size] 初始化参数传播到超类。

@section[#:tag "intnames"]{Internal and External Names}

@racket[default-10-fish%] 中 @racket[size] 的两种用法揭示
了类成员标识符的双重身份。当 @racket[size] 是 @racket[new]
或 @racket[super-new] 中括号对的第一个标识符时，
@racket[size] 是一个 @defterm{外部名称}，以符号方式匹配到
类中的初始化参数。当 @racket[size] 作为
@racket[default-10-fish%] 中的表达式出现时，
@racket[size] 是一个词法作用域的 @defterm{内部名称}。
类似地，对继承的 @racket[eat] 方法的调用将 @racket[eat]
作为内部名称使用，而 @racket[eat] 的 @racket[send] 将
@racket[eat] 作为外部名称使用。

@racket[class] 形式的完整语法允许程序员为类成员指定不同的
内部和外部名称。由于内部名称是局部的，可以重命名它们以避免
遮蔽或冲突。这种重命名并不经常需要，但在没有重命名的情况
下，变通方案可能特别繁琐。

@section{Interfaces}

接口对于检查对象或类是否实现了具有特定（隐含）行为的方法集
很有用。即使没有静态类型系统（这是 Java 有接口的主要原因），
接口的这种使用也是有帮助的。

Racket 中的接口使用 @racket[interface] 形式创建，它仅声明
实现接口所需的方法名称。接口可以扩展其他接口，这意味着接口
的实现自动实现被扩展的接口。

@specform[(interface (superinterface-expr ...) id ...)]

要声明一个类实现了某个接口，必须使用
@racket[class*] 形式而不是 @racket[class]：

@specform[(class* superclass-expr (interface-expr ...) decl-or-expr ...)]

例如，与其强制所有鱼类别都派生自 @racket[fish%]，
我们可以定义 @racket[fish-interface] 并将
@racket[fish%] 类改为声明它实现了
@racket[fish-interface]：

@racketblock[
(define fish-interface (interface () get-size grow eat))
(define fish% (class* object% (fish-interface) ....))
]

如果 @racket[fish%] 的定义不包括
@racket[get-size]、@racket[grow] 和 @racket[eat] 方法，
则在求值 @racket[class*] 形式时会发出错误信号，因为实现
@racket[fish-interface] 接口需要这些方法。

@racket[is-a?] 谓词接受一个对象作为第一个参数，一个类或接口
作为第二个参数。当给定一个类时，@racket[is-a?] 检查对象是否
是该类或派生类的实例。当给定一个接口时，@racket[is-a?]
检查对象的类是否实现了该接口。此外，
@racket[implementation?] 谓词检查给定类是否实现了给定接口。

@section[#:tag "inner"]{Final, Augment, and Inner}

与 Java 一样，@racket[class] 形式中的方法可以指定为
@defterm{final}，这意味着子类不能覆盖该方法。final 方法
使用 @racket[public-final] 或 @racket[override-final] 声明，
取决于声明是针对新方法还是覆盖实现。

在允许任意覆盖和完全禁止覆盖两个极端之间，类系统还支持
Beta 风格的 @defterm{可增强}方法 @cite["Goldberg04"]。
使用 @racket[pubment] 声明的方法类似于 @racket[public]，
但该方法不能在子类中被覆盖；只能被增强。
@racket[pubment] 方法必须使用 @racket[inner] 显式调用
增强（如果有的话）；子类使用 @racket[augment] 而不是
@racket[override] 来增强该方法。

一般来说，在类派生中，方法可以在增强和覆盖模式之间切换。
@racket[augride] 方法规范表示对方法的增强，其中增强本身
在子类中是可覆盖的（尽管超类的实现不能被覆盖）。类似地，
@racket[overment] 覆盖一个方法并使覆盖实现成为可增强的。

@section[#:tag "extnames"]{Controlling the Scope of External Names}

@margin-note{
  Java's access modifiers (like @index["protected method"]{@tt{protected}})
  play a role similar to @racket[define-member-name], but
  unlike in Java, Racket's mechanism for controlling access
  is based on lexical scope, not the inheritance hierarchy.
}

如 @secref["intnames"] 所述，类成员同时具有内部和外部名称。
成员定义在局部绑定一个内部名称，此绑定可以局部重命名。
相比之下，外部名称默认具有全局作用域，成员定义不绑定外部名称。
相反，成员定义引用外部名称的现有绑定，其中成员名称绑定到
@defterm{成员键}；类最终将成员键映射到方法、字段和
初始化参数。

回顾 @racket[hungry-fish%] @racket[class] 表达式：

@racketblock[
(define hungry-fish% (class fish% ....
                       (inherit eat)
                       (define/public (eat-more fish1 fish2)
                         (eat fish1) (eat fish2))))
]

在求值过程中，@racket[hungry-fish%] 和 @racket[fish%] 类
引用 @racket[eat] 的相同全局绑定。在运行时，
@racket[hungry-fish%] 中对 @racket[eat] 的调用通过绑定到
@racket[eat] 的共享方法键与 @racket[fish%] 中的
@racket[eat] 方法匹配。

外部名称的默认绑定是全局的，但程序员可以使用
@racket[define-member-name] 形式引入外部名称绑定。

@specform[(define-member-name id member-key-expr)]

特别是，通过使用 @racket[(generate-member-key)] 作为
@racket[member-key-expr]，外部名称可以局部化到特定作用域，
因为生成的成员键在作用域外不可访问。换句话说，
@racket[define-member-name] 赋予外部名称一种
package-private 作用域，但从包推广到了 Racket 中的任意
绑定作用域。

例如，下面的 @racket[fish%] 和 @racket[pond%] 类通过一个
@racket[get-depth] 方法协作，该方法只对协作的类可访问：

@racketblock[
(define-values (fish% pond%) (code:comment #,(t "two mutually recursive classes"))
  (let () ; create a local definition scope
    (define-member-name get-depth (generate-member-key))
    (define fish%
      (class ....
        (define my-depth ....)
	(define my-pond ....)
	(define/public (dive amt)
        (set! my-depth
              (min (+ my-depth amt)
                   (send my-pond get-depth))))))
    (define pond%
      (class ....
        (define current-depth ....)
        (define/public (get-depth) current-depth)))
    (values fish% pond%)))
]

外部名称位于一个与其他 Racket 名称分开的命名空间中。这个
独立的命名空间隐式地用于 @racket[send] 中的方法名、
@racket[new] 中的初始化参数名，或成员定义中的外部名称。
特殊形式 @racket[member-name-key] 提供了在任意表达式位置
访问外部名称绑定的能力：@racket[(member-name-key id)]
生成当前作用域中 @racket[id] 的 member-key 绑定。

member-key 值主要与 @racket[define-member-name] 形式一起使用。
通常，@racket[(member-name-key id)] 捕获 @racket[id] 的方法键，
以便可以将其传递给不同作用域中的
@racket[define-member-name] 使用。这种能力对于泛化 mixin
非常有用，如下所述。

@; ----------------------------------------------------------------------

@section{Mixins}

由于 @racket[class] 是一个表达式形式，而不是像 Smalltalk
和 Java 中的顶层声明，@racket[class] 形式可以嵌套在任何
词法作用域内，包括 @racket[lambda]。结果是一个
@deftech{mixin}，即一个相对于其超类参数化的类扩展。

例如，我们可以将 @racket[picky-fish%] 类相对于其超类
参数化来定义 @racket[picky-mixin]：

@racketblock[
(define (picky-mixin %)
  (class % (super-new)
    (define/override (grow amt) (super grow (* 3/4 amt)))))
(define picky-fish% (picky-mixin fish%))
]

Smalltalk 风格的类和 Racket 类之间的许多细微差异有助于
mixin 的有效使用。特别是，使用 @racket[define/override]
明确表示 @racket[picky-mixin] 期望一个具有 @racket[grow]
方法的类。如果将 @racket[picky-mixin] 应用于没有
@racket[grow] 方法的类，则在应用 @racket[picky-mixin] 时
立即发出错误信号。

类似地，使用 @racket[inherit] 在应用 mixin 时强制执行
“方法存在”要求：

@racketblock[
(define (hungry-mixin %)
  (class % (super-new)
    (inherit eat)
    (define/public (eat-more fish1 fish2) 
      (eat fish1) 
      (eat fish2))))
]

mixin 的优点是我们可以轻松地组合它们来创建新类，
这些类的实现共享不适合单继承层次结构——没有多重继承
带来的歧义。有了 @racket[picky-mixin] 和
@racket[hungry-mixin]，创建一个饥饿但挑剔的鱼就很简单了：

@racketblock[
(define picky-hungry-fish% 
  (hungry-mixin (picky-mixin fish%)))
]

关键字初始化参数的使用对于 mixin 的易用性至关重要。例如，
@racket[picky-mixin] 和 @racket[hungry-mixin] 可以用合适的
@racket[eat] 和 @racket[grow] 方法增强任何类，因为它们
不指定初始化参数，也不在 @racket[super-new] 表达式中添加
任何参数：

@racketblock[
(define person% 
  (class object%
    (init name age)
    ....
    (define/public (eat food) ....)
    (define/public (grow amt) ....)))
(define child% (hungry-mixin (picky-mixin person%)))
(define oliver (new child% [name "Oliver"] [age 6]))
]

最后，对类成员使用外部名称（而不是词法作用域的标识符）使
mixin 使用变得方便。将 @racket[picky-mixin] 应用于
@racket[person%] 可以正常工作，因为名称
@racket[eat] 和 @racket[grow] 匹配，无需任何关于
@racket[eat] 和 @racket[grow] 在 @racket[fish%] 和
@racket[person%] 中应该是相同方法的先验声明。当成员名称
意外冲突时，此功能是一个潜在的缺点；一些意外冲突可以通过
限制外部名称的作用域来纠正，如 @secref["extnames"] 所述。

@subsection{Mixins and Interfaces}

使用 @racket[implementation?]，@racket[picky-mixin] 可以要求
其基类实现 @racket[grower-interface]，该接口可以由
@racket[fish%] 和 @racket[person%] 共同实现：

@racketblock[
(define grower-interface (interface () grow))
(define (picky-mixin %)
  (unless (implementation? % grower-interface)
    (error "picky-mixin: not a grower-interface class"))
  (class % ....))
]

接口与 mixin 的另一种用法是为 mixin 生成的类打标签，
以便识别 mixin 的实例。换句话说，@racket[is-a?] 无法用于
表示为函数的 mixin，但它可以识别由 mixin 一致实现的接口
（有点像 @defterm{特化接口}）。例如，
@racket[picky-mixin] 生成的类可以用
@racket[picky-interface] 打标签，从而启用
@racket[is-picky?] 谓词：

@racketblock[
(define picky-interface (interface ()))
(define (picky-mixin %)
  (unless (implementation? % grower-interface)
    (error "picky-mixin: not a grower-interface class"))
  (class* % (picky-interface) ....))
(define (is-picky? o)
  (is-a? o picky-interface))
]

@subsection{The @racket[mixin] Form}

为了将实现 mixin 的 @racket[lambda] 加 @racket[class] 模式
规范化，包括使用接口指定 mixin 的域和范围，类系统提供了一个
@racket[mixin] 宏：

@specform[
(mixin (interface-expr ...) (interface-expr ...)
  decl-or-expr ...)
]

第一组 @racket[interface-expr] 确定 mixin 的域，第二组确定
范围。也就是说，展开结果是一个函数，它测试给定的基类是否
实现了第一组 @racket[interface-expr]，并生成一个实现了第二组
@racket[interface-expr] 的类。其他要求，如超类中存在
@racket[inherit] 的方法，则在 @racket[mixin] 形式的
@racket[class] 展开中进行检查。例如：

@interaction[
#:eval class-eval

(define choosy-interface (interface () choose?))
(define hungry-interface (interface () eat))
(define choosy-eater-mixin
  (mixin (choosy-interface) (hungry-interface)
    (inherit choose?)
    (super-new)
    (define/public (eat x)
      (cond
        [(choose? x)
         (printf "chomp chomp chomp on ~a.\n" x)]
        [else
         (printf "I'm not crazy about ~a.\n" x)]))))

(define herring-lover% 
  (class* object% (choosy-interface)
    (super-new)
    (define/public (choose? x)
      (regexp-match #px"^herring" x))))

(define herring-eater% (choosy-eater-mixin herring-lover%))
(define eater (new herring-eater%))
(send eater eat "elderberry")
(send eater eat "herring")
(send eater eat "herring ice cream")
]


mixin 不仅可以覆盖方法和引入公共方法，还可以增强方法、
引入仅增强方法、添加可覆盖的增强以及添加可增强的覆盖——
类可以做的所有事情（参见 @secref["inner"]）。


@subsection[#:tag "parammixins"]{Parameterized Mixins}

如 @secref["extnames"] 所述，外部名称可以用
@racket[define-member-name] 绑定。这种机制允许 mixin 相对于
它定义和使用的方法进行泛化。例如，我们可以将
@racket[hungry-mixin] 相对于 @racket[eat] 的外部成员键
进行参数化：

@racketblock[
(define (make-hungry-mixin eat-method-key)
  (define-member-name eat eat-method-key)
  (mixin () () (super-new)
    (inherit eat)
    (define/public (eat-more x y) (eat x) (eat y))))
]

要获得一个特定的 hungry-mixin，我们必须将此函数应用于引用
合适的 @racket[eat] 方法的成员键，我们可以使用
@racket[member-name-key] 获取该成员键： 

@racketblock[
((make-hungry-mixin (member-name-key eat))
 (class object% .... (define/public (eat x) 'yum)))
]

上面，我们将 @racket[hungry-mixin] 应用于一个提供
@racket[eat] 的匿名类，但我们也可以将其与提供
@racket[chomp] 的类组合：

@racketblock[
((make-hungry-mixin (member-name-key chomp))
 (class object% .... (define/public (chomp x) 'yum)))
]

@; ----------------------------------------------------------------------

@section{Traits}

@defterm{trait} 类似于 mixin，它封装了一组要添加到类中的方法。
trait 与 mixin 的不同之处在于，它的各个方法可以使用 trait
操作符进行操作，如 @racket[trait-sum]（合并两个 trait 的方法）、
@racket[trait-exclude]（从 trait 中移除一个方法）和
@racket[trait-alias]（添加方法的副本并使用新名称；不重定向
对旧名称的任何调用）。

mixin 和 trait 之间的实际区别在于，两个 trait 可以组合，
即使它们包含共同的方法，即使任何方法都不能合理地覆盖另一个。
在这种情况下，程序员必须显式解决冲突，通常通过别名方法、
排除方法以及合并使用别名的新 trait。

假设我们的 @racket[fish%] 程序员想要定义两个类扩展，
@racket[spots] 和 @racket[stripes]，每个都包含一个
@racket[get-color] 方法。鱼的斑点颜色不应该覆盖条纹颜色，
反之亦然；相反，@racket[spots+stripes-fish%] 应该结合
两种颜色，这在 @racket[spots] 和 @racket[stripes] 被实现
为普通 mixin 时是不可能的。然而，如果 @racket[spots] 和
@racket[stripes] 被实现为 trait，它们可以组合。首先，
我们将每个 trait 中的 @racket[get-color] 别名为不冲突的名称。
其次，从两者中移除 @racket[get-color] 方法，合并仅包含别名
的 trait。最后，使用新 trait 创建一个类，该类基于两个别名
引入自己的 @racket[get-color] 方法，从而得到所需的
@racket[spots+stripes] 扩展。

@subsection{Traits as Sets of Mixins}

在 Racket 中实现 trait 的一种自然方法是作为一组 mixin，
每个 trait 方法一个 mixin。例如，我们可以尝试按以下方式定义
spots 和 stripes trait，使用关联列表表示集合：

@racketblock[
(define spots-trait
  (list (cons 'get-color 
               (lambda (%) (class % (super-new)
                             (define/public (get-color) 
                               'black))))))
(define stripes-trait
  (list (cons 'get-color 
              (lambda (%) (class % (super-new)
                            (define/public (get-color) 
                              'red))))))
]

像上面这样的集合表示允许 @racket[trait-sum] 和
@racket[trait-exclude] 作为简单的操作；不幸的是，它不支持
@racket[trait-alias] 操作符。虽然可以在关联列表中复制一个
mixin，但 mixin 具有固定的方法名，例如 @racket[get-color]，
mixin 不支持方法重命名操作。为了支持
@racket[trait-alias]，我们必须以与 @secref["parammixins"]
中参数化 @racket[eat] 相同的方式参数化 mixin 的外部方法名。

为了支持 @racket[trait-alias] 操作，@racket[spots-trait]
应该表示为：

@racketblock[
(define spots-trait
  (list (cons (member-name-key get-color)
              (lambda (get-color-key %) 
                (define-member-name get-color get-color-key)
                (class % (super-new)
                  (define/public (get-color) 'black))))))
]

当 @racket[spots-trait] 中的 @racket[get-color] 方法被别名
为 @racket[get-trait-color] 并且 @racket[get-color] 方法被移除时，
生成的 trait 等同于

@racketblock[
(list (cons (member-name-key get-trait-color)
            (lambda (get-color-key %)
              (define-member-name get-color get-color-key)
              (class % (super-new)
                (define/public (get-color) 'black)))))
]

要将 trait @racket[_T] 应用于类 @racket[_C] 并获得派生类，
我们使用 @racket[((trait->mixin _T) _C)]。
@racket[trait->mixin] 函数为 @racket[_T] 的每个 mixin
提供 mixin 方法的键和 @racket[_C] 的部分扩展：

@racketblock[
(define ((trait->mixin T) C)
  (foldr (lambda (m %) ((cdr m) (car m) %)) C T))
]

因此，当上面的 trait 与其他 trait 组合然后应用于一个类时，
@racket[get-color] 的使用变成了对外部名称
@racket[get-trait-color] 的引用。

@subsection{Inherit and Super in Traits}

trait 的第一个实现支持 @racket[trait-alias]，并且支持调用
自身的 trait 方法，但不支持相互调用的 trait 方法。特别是，
假设斑点鱼的市场价值取决于其斑点的颜色：

@racketblock[
(define spots-trait
  (list (cons (member-name-key get-color) ....)
        (cons (member-name-key get-price)
              (lambda (get-price %) ....
                (class % ....
                  (define/public (get-price) 
                    .... (get-color) ....))))))
]

在这种情况下，@racket[spots-trait] 的定义失败，因为
@racket[get-color] 不在 @racket[get-price] mixin 的作用域
内。实际上，取决于 trait 应用于类时 mixin 的应用顺序，
当 @racket[get-price] mixin 应用于类时，
@racket[get-color] 方法可能还不可用。因此，在
@racket[get-price] mixin 中添加
@racket[(inherit get-color)] 声明并不能解决问题。

一种解决方案是要求在 @racket[get-price] 等方法中使用
@racket[(send this get-color)]。这个改变有效，因为
@racket[send] 总是延迟方法查找，直到方法调用被求值。
然而，延迟查找比直接调用更昂贵。更糟的是，它还延迟了
检查 @racket[get-color] 方法是否存在的检查。

第二种有效且高效的解决方案是改变 trait 的编码方式。具体来说，
我们将每个方法表示为一对 mixin：一个引入方法，一个实现方法。
当 trait 应用于类时，所有引入方法的 mixin 首先被应用。
然后，实现方法的 mixin 可以使用 @racket[inherit] 直接访问
任何已引入的方法。

@racketblock[
(define spots-trait
  (list (list (local-member-name-key get-color)
              (lambda (get-color get-price %) ....
                (class % ....
                  (define/public (get-color) (void))))
              (lambda (get-color get-price %) ....
                (class % ....
                  (define/override (get-color) 'black))))
        (list (local-member-name-key get-price)
              (lambda (get-color get-price %) ....
                (class % ....
                  (define/public (get-price) (void))))
              (lambda (get-color get-price %) ....
                (class % ....
                  (inherit get-color)
                  (define/override (get-price)
                    .... (get-color) ....))))))
]

通过这种 trait 编码，@racket[trait-alias] 使用新名称添加
一个新方法，但不改变对旧方法的任何引用。

@subsection{The @racket[trait] Form}

@hash-lang-note[racket/trait]

通用 trait 模式显然太复杂，不适合程序员直接使用，
但可以很容易地用 @racket[trait] 宏编码：

@specform[
(trait trait-clause ...)
]

可选 @racket[inherit] 子句中的 @racket[id] 可以在方法
@racket[expr] 中直接引用，它们必须由其他 trait 或最终
应用 trait 的基类提供。

将此形式与 @racket[trait-sum]、@racket[trait-exclude]、
@racket[trait-alias] 和 @racket[trait->mixin] 等 trait
操作符一起使用，我们可以按需实现 @racket[spots-trait] 和
@racket[stripes-trait]。

@racketblock[
(define spots-trait
  (trait
    (define/public (get-color) 'black)
    (define/public (get-price) ... (get-color) ...)))

(define stripes-trait
  (trait 
    (define/public (get-color) 'red)))

(define spots+stripes-trait
  (trait-sum
   (trait-exclude (trait-alias spots-trait
                               get-color get-spots-color)
                  get-color)
   (trait-exclude (trait-alias stripes-trait
                               get-color get-stripes-color)
                  get-color)
   (trait
     (inherit get-spots-color get-stripes-color)
     (define/public (get-color)
       .... (get-spots-color) .... (get-stripes-color) ....))))
]

@; ----------------------------------------------------------------------

@; Set up uses of contract forms below
@(class-eval '(require racket/contract))

@section{Class Contracts}

由于类是值，它们可以跨越 contract 边界流动，我们可能希望
用 contract 保护给定类的某些部分。为此，使用
@racket[class/c] 形式。@racket[class/c] 形式有许多子形式，
描述了两种类型的字段和方法 contract：影响通过实例化对象
使用的 contract 和影响子类的 contract。

@subsection{External Class Contracts}

在其最简单的形式中，@racket[class/c] 保护从受 contract 约束
的类实例化的对象的公共字段和方法。还有一个
@racket[object/c] 形式，可以用来类似地保护特定对象的
公共字段和方法。以 @racket[animal%] 的以下定义为例，
它为其 @racket[size] 属性使用了一个公共字段：

@racketblock[
(define animal%
  (class object% 
    (super-new)
    (field [size 10])
    (define/public (eat food)
      (set! size (+ size (get-field size food))))))]

对于任何实例化的 @racket[animal%]，访问 @racket[size] 字段
应该返回一个正数。此外，如果设置了 @racket[size] 字段，
应该赋予它一个正数。最后，@racket[eat] 方法应该接收一个
参数，该参数是一个具有包含正数的 @racket[size] 字段的对象。
为确保这些条件，我们将使用适当的 contract 定义
@racket[animal%] 类：

@racketblock[
(define positive/c (and/c number? positive?))
(define edible/c (object/c (field [size positive/c])))
(define/contract animal%
  (class/c (field [size positive/c])
           [eat (->m edible/c void?)])
  (class object% 
    (super-new)
    (field [size 10])
    (define/public (eat food)
      (set! size (+ size (get-field size food))))))]

@interaction-eval[
#:eval class-eval
(begin
  (define positive/c
    (flat-named-contract 'positive/c (and/c number? positive?)))
  (define edible/c (object/c (field [size positive/c])))
  (define/contract animal%
    (class/c (field [size positive/c])
             [eat (->m edible/c void?)])
    (class object% 
      (super-new)
      (field [size 10])
      (define/public (eat food)
        (set! size (+ size (get-field size food)))))))]

这里我们使用 @racket[->m] 来描述 @racket[eat] 的行为，
因为我们不需要描述 @racket[this] 参数的任何要求。
现在有了受 contract 约束的类，我们可以看到
@racket[size] 和 @racket[eat] 上的 contract 都得到了执行：

@interaction[
#:eval class-eval
(define bob (new animal%))
(set-field! size bob 3)
(get-field size bob)
(set-field! size bob 'large)
(define richie (new animal%))
(send bob eat richie)
(get-field size bob)
(define rock (new object%))
(send bob eat rock)
(define giant (new (class object% (super-new) (field [size 'large]))))
(send bob eat giant)]

外部类 contract 有两个重要的注意事项。首先，外部方法
contract 仅在动态分派的目标是受 contract 约束的类的
方法实现时才执行，该实现位于 contract 边界内。覆盖该实现，
从而改变动态分派的目标，将意味着 contract 不再对客户端
执行，因为访问方法不再跨越 contract 边界。与外部方法
contract 不同，外部字段 contract 始终对子类的客户端执行，
因为字段不能被覆盖或遮蔽。

其次，这些 contract 不以任何方式限制 @racket[animal%] 的
子类。被继承和被子类使用的字段和方法不受这些 contract
检查，通过 @racket[super] 使用超类的方法也不受检查。
下面的示例说明了这两种情况：

@def+int[
#:eval class-eval
(define large-animal%
  (class animal%
    (super-new)
    (inherit-field size)
    (set! size 'large)
    (define/override (eat food)
      (display "Nom nom nom") (newline))))
(define elephant (new large-animal%))
(send elephant eat (new object%))
(get-field size elephant)]

@subsection{Internal Class Contracts}

请注意，从对象 @racket[elephant] 检索 @racket[size] 字段
将 contract 违规归咎于 @racket[animal%]。这种归咎是
正确的，但对 @racket[animal%] 类是不公平的，因为我们还没
有为它提供保护自己免受子类影响的方法。为此，我们添加内部
类 contract，它们为子类提供了如何访问和覆盖超类特性的指令。
外部和内部类 contract 之间的这种区别允许在类层次结构内部
使用较弱的 contract，其中不变量可以在内部被子类破坏，但对
通过实例化对象的外部使用应该强制执行。

作为可用保护类型的一个简单示例，我们提供了一个针对
@racket[animal%] 类的示例，使用了所有适用的形式：

@racketblock[
(class/c (field [size positive/c])
         (inherit-field [size positive/c])
         [eat (->m edible/c void?)]
         (inherit [eat (->m edible/c void?)])
         (super [eat (->m edible/c void?)])
         (override [eat (->m edible/c void?)]))]

这个类 contract 不仅确保 @racket[animal%] 类的对象像之前
一样受到保护，还确保 @racket[animal%] 的子类只在
@racket[size] 字段中存储适当的值，并适当地使用
@racket[animal%] 中 @racket[size] 的实现。这些 contract
形式只影响类层次结构内部的使用，且仅影响跨越 contract
边界的方法调用。

这意味着 @racket[inherit] 只会影响子类对方法的使用，直到
子类覆盖该方法，而 @racket[override] 只影响从超类到子类的
覆盖实现的方法调用。由于这些只影响内部使用，当使用这些类
的对象时，@racket[override] 形式不会自动将子类置于义务中。
此外，@racket[override] 的使用只在没有发生 Beta 风格增强
的方法上才有意义，因此也只能用于这些方法。下面的示例显示
了这种区别：

@racketblock[
(define/contract glutton%
  (class/c (override [eat (->m edible/c void?)]))
  (class animal%
    (super-new)
    (inherit eat)
    (define/public (gulp food-list)
      (for ([f food-list])
        (eat f)))))
(define/contract sloppy-eater%
  (class/c [eat (->m edible/c edible/c)])
  (class glutton%
    (super-new)
    (inherit-field size)
    (define/override (eat f)
      (let ([food-size (get-field size f)])
        (set! size (/ food-size 2))
        (set-field! size f (/ food-size 2))
        f))))]

@interaction-eval[
#:eval class-eval
(define/contract glutton%
  (class/c (override [eat (->m edible/c void?)]))
  (class animal%
    (super-new)
    (inherit eat)
    (define/public (gulp food-list)
      (for ([f food-list])
        (eat f)))))
(define/contract sloppy-eater%
  (class/c [eat (->m edible/c edible/c)])
  (class glutton%
    (super-new)
    (inherit-field size)
    (define/override (eat f)
      (let ([food-size (get-field size f)])
        (set! size (/ food-size 2))
        (set-field! size f (/ food-size 2))
        f))))]

@interaction[
#:eval class-eval
(define pig (new sloppy-eater%))
(define slop1 (new animal%))
(define slop2 (new animal%))
(define slop3 (new animal%))
(send pig eat slop1)
(get-field size slop1)
(send pig gulp (list slop1 slop2 slop3))]

除了这里展示的内部类 contract 形式之外，还有用于 Beta
风格可增强方法的类似形式。@racket[inner] 形式描述了子类
对给定方法的增强应该提供什么。@racket[augment] 和
@racket[augride] 都告诉子类，给定方法是一个已被增强的
方法，子类中对该方法的任何调用都将动态分派到超类中的适当
实现。这样的调用将根据给定的 contract 进行检查。这两种形式
的区别在于，使用 @racket[augment] 表示子类可以增强给定
方法，而使用 @racket[augride] 表示子类必须覆盖当前的增强。

这意味着并非所有形式都可以同时使用。对于给定方法，只能使用
@racket[override]、@racket[augment] 和 @racket[augride]
中的一种形式，如果给定方法已被 finalized，则不能使用这些
形式中的任何一种。此外，只有在可以指定
@racket[augride] 或 @racket[override] 时，才能为给定方法
指定 @racket[super]。类似地，只有在可以指定
@racket[augment] 或 @racket[augride] 时，才能指定
@racket[inner]。

@; ----------------------------------------------------------------------

@close-eval[class-eval]
