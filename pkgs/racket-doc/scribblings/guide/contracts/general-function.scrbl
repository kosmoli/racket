#lang scribble/doc
@(require scribble/manual scribble/eval "utils.rkt"
          (for-label framework/framework racket/contract racket/gui))

@title[#:tag "contracts-general-functions"]{Contracts on Functions in General}

@racket[->] 契约构造器适用于接受固定数量参数且结果契约不依赖于输入参数的函数。为了支持其他类型的函数，Racket 提供了额外的契约构造器，尤其是 @racket[->*] 和
@racket[->i]。

@ctc-section[#:tag "optional"]{Optional Arguments}

以下是字符串处理模块的一个片段：

@racketmod[
racket

(provide
 (contract-out
  (code:comment @#,t{pad the given str left and right with})
  (code:comment @#,t{the (optional) char so that it is centered})
  [string-pad-center (->* (string? natural-number/c)
                          (char?) 
                          string?)]))

(define (string-pad-center str width [pad #\space])
  (define field-width (min width (string-length str)))
  (define rmargin (ceiling (/ (- width field-width) 2)))
  (define lmargin (floor (/ (- width field-width) 2)))
  (string-append (build-string lmargin (λ (x) pad))
                 str
                 (build-string rmargin (λ (x) pad))))
]

 该模块导出了 @racket[string-pad-center]，一个创建给定 @racket[width] 宽度、
 将给定字符串居中的函数。默认填充字符是
 @racket[#\space]；如果客户端模块希望使用
 不同的字符，可以用第三个参数 @racket[char] 调用 @racket[string-pad-center]，
 覆盖默认值。

函数定义使用了可选参数，这对于这种功能来说很合适。这里有趣的是 @racket[string-pad-center] 的契约描述方式。


契约组合子 @racket[->*] 要求几组契约： 

@itemize[
@item{第一组是所有必需参数的括号包裹的契约。在此示例中，我们看到两个：@racket[string?] 和
@racket[natural-number/c]。}

@item{第二组是所有可选参数的括号包裹的契约：@racket[char?]。}

@item{最后一组是一个单独的契约：函数的结果。}
]

 注意，如果默认值不满足契约，你不会在此接口上获得 contract 错误。如果你不确定自己能正确设置初始值，则需要跨边界传递初始值。

@ctc-section[#:tag "contracts-rest-args"]{剩余参数}

@racket[max] 操作符至少消耗一个实数，但接受任意数量的附加参数。你可以使用 @tech{rest argument} 来编写其他类似的函数，例如 @racket[max-abs]：

@margin-note{参见 @secref["rest-args"] 了解 rest 参数的介绍。}

@racketblock[
(define (max-abs n . rst)
  (foldr (lambda (n m) (max (abs n) m)) (abs n) rst))
]

要通过契约描述这个函数，可以使用 @racket[->] 的 @racket[...] 特性。

@racketblock[
(provide
 (contract-out
  [max-abs (-> real? real? ... real?)]))
]

或者，你可以使用 @racket[->*] 配合 @racket[#:rest] 关键字，它指定一个对必选和可选参数之后的参数列表的契约：

@racketblock[
(provide
 (contract-out
  [max-abs (->* (real?) () #:rest (listof real?) real?)]))
]

与 @racket[->*] 一贯的用法一样，必选参数的契约被包围在第一对括号中，在这个例子中是一个单独的实数。
空的括号表示没有可选参数（不计剩余参数）。剩余参数的契约跟在 @racket[#:rest] 之后；
因为所有附加参数必须是实数，所以剩余参数的列表必须满足 @racket[(listof real?)]。


@ctc-section[#:tag "contracts-keywords"]{关键字参数}

事实上，@racket[->] 契约构造器也支持关键字参数。例如，考虑这个创建一个简单 GUI 并向用户提出是/否问题的函数：

@margin-note{参见 @secref["lambda-keywords"] 了解关键字参数的介绍。}

@racketmod[
racket/gui

(define (ask-yes-or-no-question question 
                                #:default answer
                                #:title title
                                #:width w
                                #:height h)
  (define d (new dialog% [label title] [width w] [height h]))
  (define msg (new message% [label question] [parent d]))
  (define (yes) (set! answer #t) (send d show #f))
  (define (no) (set! answer #f) (send d show #f))
  (define yes-b (new button% 
                     [label "Yes"] [parent d] 
                     [callback (λ (x y) (yes))]
                     [style (if answer '(border) '())]))
  (define no-b (new button% 
                    [label "No"] [parent d] 
                    [callback (λ (x y) (no))]
                    [style (if answer '() '(border))]))
  (send d show #t)
  answer)

(provide (contract-out
          [ask-yes-or-no-question
           (-> string?
               #:default boolean?
               #:title string?
               #:width exact-integer?
               #:height exact-integer?
               boolean?)]))
]

@margin-note{如果你确实想通过 GUI 提出是/否问题，应使用 @racket[message-box/custom]。实际上，通常最好提供比"是"和"否"更具体答案的按钮。}

@racket[ask-yes-or-no-question] 的契约使用 @racket[->]，就像 @racket[lambda]（或基于 @racket[define] 的函数）允许关键字出现在函数形式参数之前一样，@racket[->] 允许关键字出现在函数契约的参数契约之前。在此情况下，契约规定 @racket[ask-yes-or-no-question] 必须接收四个关键字参数，分别对应关键字 @racket[#:default]、@racket[#:title]、@racket[#:width] 和 @racket[#:height]。与函数定义一样，@racket[->] 中关键字之间的相对顺序对函数的客户端无关紧要；只有不带关键字的参数契约的相对顺序才重要。

@ctc-section[#:tag "optional-keywords"]{Optional 关键字参数}

当然，@racket[ask-yes-or-no-question] 中的许多参数（源自前面的示例）
有合理的默认值，应该设为可选：

@racketblock[
(define (ask-yes-or-no-question question 
                                #:default answer
                                #:title [title "Yes or No?"]
                                #:width [w 400]
                                #:height [h 200])
  ...)
]

为了指定此函数的契约，我们需要再次使用 @racket[->*]。它在可选和必需参数部分都支持关键字，正如你所预期的那样。在此情况下，我们有必需关键字 @racket[#:default] 以及可选关键字 @racket[#:title]、@racket[#:width] 和 @racket[#:height]。因此，我们这样编写契约：

@racketblock[
(provide (contract-out
          [ask-yes-or-no-question
           (->* (string?
                 #:default boolean?)
                (#:title string?
                 #:width exact-integer?
                 #:height exact-integer?)

                boolean?)]))
]

也就是说，我们把必选关键字放在第一部分，可选的关键字放在第二部分。


@ctc-section[#:tag "contracts-case-lambda"]{@racket[case-lambda] 的契约}

用 @racket[case-lambda] 定义的函数可能会根据提供的参数数量对其参数施加不同的约束。
例如，一个 @racket[report-cost] 函数可能将一对数字或一个字符串转换为一个新字符串：

@margin-note{参见 @secref["case-lambda"] 了解 @racket[case-lambda] 的介绍。}

@def+int[
(define report-cost
  (case-lambda
    [(lo hi) (format "between $~a and $~a" lo hi)]
    [(desc) (format "~a of dollars" desc)]))
(report-cost 5 8)
(report-cost "millions")
]

这类函数的契约由 @racket[case->] 组合子形成，它将尽可能多的函数契约组合在一起： 
@racketblock[
(provide (contract-out
          [report-cost
           (case->
            (integer? integer? . -> . string?)
            (string? . -> . string?))]))
]
如你所见，@racket[report-cost] 的契约组合了两个函数契约的数量，恰好满足对其功能描述所需的子句数量。

@;{
This isn't supported anymore (yet...?). -robby

In the case of @racket[substring1], we also know that the indices
  that it consumes ought to be natural numbers less than the length of the
  given string. Since @racket[case->] just combines arrow contracts,
  adding such constraints is just a matter of strengthening the individual
  contracts: 
<racket>
(provide
 (contract-out
  [substring1 (case->
               (string? . -> . string?)
               (->r ([s string?]
                     [_ (and/c natural-number/c (</c (string-length s)))])
                 string?)
               (->r ([s string?]
                     [a (and/c natural-number/c (</c (string-length s)))]
                     [o (and/c natural-number/c
                               (>=/c a)
                               (</c (string-length s)))])
                  string?))]))
</racket>
  Here we used @racket[->r] to name the parameters and express the
  numeric constraints on them. 
}

@ctc-section[#:tag "arrow-d"]{参数与结果之间的依赖关系}

下面是一个虚构的数值模块的片段：

@racketblock[
(provide
 (contract-out
  [real-sqrt (->i ([argument (>=/c 1)])
                  [result (argument) (<=/c argument)])]))
]
 
@margin-note{"indy" 一词意在暗示 blame 可能归于契约本身，因为契约必须被视为一个独立的组件。该名称是为回应研究文献中函数契约不同语义的两个现有标签——"lax" 和 "picky"——而选定的。}
导出函数 @racket[real-sqrt] 的契约使用 @racket[->i] 而非 @racket[->*] 函数契约。"i" 代表 @italic{indy dependent}（独立依赖）契约，意味着函数值域的契约依赖于参数的值。@racket[result] 行中 @racket[argument] 的出现意味着结果依赖于参数。在此特定情况下，@racket[real-sqrt] 的参数大于等于 1，因此一个非常基本的正确性检查是结果小于参数。

一般而言，一个依赖函数契约看起来与更通用的 @racket[->*] 契约类似，
但添加了可在契约其他位置使用的名称。

@;{
Yes, there are many other contract combinators such as @racket[<=/c]
and @racket[>=/c], and it pays off to look them up in the contract
section of the reference manual. They simplify contracts tremendously
and make them more accessible to potential clients. 
}

回到银行账户的例子，假设我们将模块泛化以支持多个账户，并且包含一个取款操作。
改进后的银行账户模块包含一个 @racket[account] 结构类型和以下函数：

@racketblock[
(provide (contract-out
          [balance (-> account? amount/c)]
          [withdraw (-> account? amount/c account?)]
          [deposit (-> account? amount/c account?)]))
]

除了要求客户端为取款提供一个有效金额外，金额还应小于或等于指定账户的余额，
且生成的账户将比开始时钱更少。类似地，模块可能承诺存款会产生一个金额增加的账户。
以下实现通过契约强制实施这些约束和保证：

@racketmod[
racket

(code:comment "section 1: the contract definitions")
(struct account (balance))
(define amount/c natural-number/c)

(code:comment "section 2: the exports")
(provide
 (contract-out
  [create   (amount/c . -> . account?)]
  [balance  (account? . -> . amount/c)]
  [withdraw (->i ([acc account?]
                  [amt (acc) (and/c amount/c (<=/c (balance acc)))])
                 [result (acc amt)
                         (and/c account? 
                                (lambda (res)
                                  (>= (balance res) 
                                      (- (balance acc) amt))))])]
  [deposit  (->i ([acc account?]
                  [amt amount/c])
                 [result (acc amt)
                         (and/c account? 
                                (lambda (res)
                                  (>= (balance res) 
                                      (+ (balance acc) amt))))])]))

(code:comment "section 3: the function definitions")
(define balance account-balance)

(define (create amt) (account amt))

(define (withdraw a amt)
  (account (- (account-balance a) amt)))

(define (deposit a amt)
  (account (+ (account-balance a) amt)))
]

section 2 中的契约为 @racket[create] 和 @racket[balance] 提供了典型的类型式保证。
但对于 @racket[withdraw] 和 @racket[deposit]，契约检查并保证对 @racket[balance] 和 @racket[deposit] 的更复杂约束。
@racket[withdraw] 第二个参数的契约使用 @racket[(balance acc)] 来检查提供的取款金额是否足够小，
其中 @racket[acc] 是在 @racket[->i] 内给函数第一个参数的名称。
@racket[withdraw] 结果的契约同时使用 @racket[acc] 和 @racket[amt] 来保证取出的钱不超过请求的金额。
@racket[deposit] 的契约类似地在结果契约中使用 @racket[acc] 和 @racket[amount] 来保证至少存入了所提供金额的钱到账户中。

如上所述，当契约检查失败时，错误消息不够友好。
下面的修订版在辅助函数 @racket[mk-account-contract] 中使用 @racket[flat-named-contract] 来提供更好的错误消息。

@racketmod[
racket

(code:comment "section 1: the contract definitions")
(struct account (balance))
(define amount/c natural-number/c)

(define msg> "account a with balance larger than ~a expected")
(define msg< "account a with balance less than ~a expected")

(define (mk-account-contract acc amt op msg)
  (define balance0 (balance acc))
  (define (ctr a)
    (and (account? a) (op balance0 (balance a))))
  (flat-named-contract (format msg balance0) ctr))

(code:comment "section 2: the exports")
(provide
 (contract-out
  [create   (amount/c . -> . account?)]
  [balance  (account? . -> . amount/c)]
  [withdraw (->i ([acc account?]
                  [amt (acc) (and/c amount/c (<=/c (balance acc)))])
                 [result (acc amt) (mk-account-contract acc amt >= msg>)])]
  [deposit  (->i ([acc account?]
                  [amt amount/c])
                 [result (acc amt) 
                         (mk-account-contract acc amt <= msg<)])]))

(code:comment "section 3: the function definitions")
(define balance account-balance)

(define (create amt) (account amt))

(define (withdraw a amt)
  (account (- (account-balance a) amt)))

(define (deposit a amt)
  (account (+ (account-balance a) amt)))
]

@ctc-section[#:tag "arrow-d-eval-order"]{检查状态变更}

@racket[->i] 契约组合子还可以确保函数仅根据特定约束修改状态。
例如，考虑这个契约（它是来自 framework 中 @racket[preferences:add-panel] 函数的略微简化版本）：
@racketblock[
(->i ([parent (is-a?/c area-container-window<%>)])
      [_ (parent)
       (let ([old-children (send parent get-children)])
         (λ (child)
           (andmap eq?
                   (append old-children (list child))
                   (send parent get-children))))])
]
它表明函数接受一个名为 @racket[parent] 的参数，且 @racket[parent] 必须是一个匹配 @racket[area-container-window<%>] 接口的对象。

值域契约确保函数仅通过向列表前面添加新子元素来修改 @racket[parent] 的子元素。
它通过使用 @racket[_] 而非普通标识符来实现这一点，
这告诉契约库值域契约不依赖于任何结果的值，
因此契约库在函数被调用时计算 @racket[_] 后面的表达式，而非在函数返回时调用 @racket[get-children]。
因此对 @racket[get-children] 方法的调用发生在被契约包裹的函数被调用之前。
当被契约包裹的函数返回时，其结果作为 @racket[child] 传入，
契约确保函数返回后的子元素与函数调用前的子元素相同，只是在列表前面多了一个子元素。

为了在一个聚焦于此要点的简单示例中看到区别，考虑这个程序
@racketmod[
racket
(define x '())
(define (get-x) x)
(define (f) (set! x (cons 'f x)))
(provide
 (contract-out
  [f (->i () [_ () (begin (set! x (cons 'ctc x)) any/c)])]
  [get-x (-> (listof symbol?))]))
]
如果你 require 这个模块、调用 @racket[f]，那么 @racket[get-x] 的结果将是 @racket['(f ctc)]。
相反，如果 @racket[f] 的契约是
@racketblock[(->i () [res () (begin (set! x (cons 'ctc x)) any/c)])]
（仅将下划线改为 @racket[res]），那么 @racket[get-x] 的结果将是 @racket['(ctc f)]。

@ctc-section[#:tag "multiple"]{多返回值}

函数 @racket[split] 消耗一个 @racket[char] 列表，返回 @racket[#\newline] 第一次出现位置之前的字符串（如果有的话）以及列表的剩余部分： 
@racketblock[
(define (split l)
  (define (split l w)
    (cond
      [(null? l) (values (list->string (reverse w)) '())]
      [(char=? #\newline (car l))
       (values (list->string (reverse w)) (cdr l))]
      [else (split (cdr l) (cons (car l) w))]))
  (split l '()))
]
 它是一个典型的多返回值函数，通过遍历单个列表返回两个值。

此类函数的契约可以使用普通的函数箭头 @racket[->]，因为 @racket[->] 在 @racket[values] 作为最后一个结果时对其做特殊处理：
@racketblock[
(provide (contract-out
          [split (-> (listof char?)
                     (values string? (listof char?)))]))
]

此类函数的契约也可以用 @racket[->*] 来写：
@racketblock[
(provide (contract-out
          [split (->* ((listof char?))
                      ()
                      (values string? (listof char?)))]))
]
和前一样，@racket[->*] 中参数的契约被包裹在一对额外的括号中（并且必须始终这样包裹），
空括号表示没有可选参数。结果的契约在 @racket[values] 内：一个字符串和一个字符列表。

现在，假设我们还想确保 @racket[split] 的第一个结果是给定列表格式单词的前缀。
在这种情况下，我们需要使用 @racket[->i] 契约组合子：
@racketblock[
(define (substring-of? s)
  (flat-named-contract
    (format "substring of ~s" s)
    (lambda (s2)
      (and (string? s2)
           (<= (string-length s2) (string-length s))
           (equal? (substring s 0 (string-length s2)) s2)))))

(provide
 (contract-out
  [split (->i ([fl (listof char?)])
              (values [s (fl) (substring-of? (list->string fl))]
                      [c (listof char?)]))]))
]
与 @racket[->*] 类似，@racket[->i] 组合子使用参数上的函数来创建值域契约。
是的，它不只返回一个契约，而是函数产生多少个值就返回多少个契约：每个值一个契约。
在此例中，第二个契约与之前一样，确保第二个结果是一个 @racket[char] 列表。
相反，第一个契约强化了旧契约，使得结果是给定单词的前缀。 

当然，这个契约检查起来很昂贵。这里是更便宜但限制更宽松的版本： 
@racketblock[
(provide
 (contract-out
  [split (->i ([fl (listof char?)])
              (values [s (fl) (string-len/c (+ 1 (length fl)))]
                      [c (listof char?)]))]))
]
等等！为什么我们在 @racket[fl] 的长度上加了 @racket[1]？

@;{
Running @racket[(split '())] would reveal this documentation bug.
}

@ctc-section[#:tag "no-domain"]{固定但静态未知的元数}

想象你正在为一个函数写契约，该函数接受另一个函数和一个数字列表，
最终将前者应用于后者。除非给定函数的元数与给定列表的长度匹配，否则你的过程就会陷入困境。 

考虑这个 @racket[n-step] 函数：
@racketblock[
(code:comment "(number ... -> (union #f number?)) (listof number) -> void")
(define (n-step proc inits)
  (let ([inc (apply proc inits)])
    (when inc
      (n-step proc (map (λ (x) (+ x inc)) inits)))))
]

@racket[n-step] 的参数是 @racket[proc]（一个结果为数字或 false 的函数）和一个列表。
然后它将 @racket[proc] 应用于列表 @racket[inits]。只要 @racket[proc] 返回一个数字，
@racket[n-step] 将该数字视为 @racket[inits] 中每个数字的增量并递归。
当 @racket[proc] 返回 @racket[false] 时，循环停止。
  
以下是两个使用示例： 
@racketblock[
(code:comment "nat -> nat") 
(define (f x)
  (printf "~s\n" x)
  (if (= x 0) #f -1))
(n-step f '(2))

(code:comment "nat nat -> nat") 
(define (g x y)
  (define z (+ x y))
  (printf "~s\n" (list x y z))
  (if (= z 0) #f -1))
  
(n-step g '(1 1))
]

@racket[n-step] 的契约必须指定 @racket[proc] 行为的两个方面：
其元数必须包含 @racket[inits] 中的元素数量，并且它必须返回数字或 @racket[#f]。
后者很容易，前者很困难。乍看之下，这似乎表明应给 @racket[proc] 分配一个 @italic{variable-arity}（可变元数）契约： 
@racketblock[
(->* () 
     #:rest (listof any/c)
     (or/c number? #f))
]
然而，这个契约表示函数必须接受 @emph{任意}数量的参数，
而不是 @emph{特定}但 @emph{未确定}的数量。
因此，将 @racket[n-step] 应用于 @racket[(lambda (x) x)] 和 @racket[(list 1 2)] 会违反契约，
因为给定的函数只接受一个参数。 

正确的契约使用 @racket[unconstrained-domain->] 组合子，它仅指定函数的值域而非定义域。
然后可以将此契约与元数检查结合，以指定 @racket[n-step] 的正确契约：
@racketblock[
(provide
 (contract-out
  [n-step
   (->i ([proc (inits)
          (and/c (unconstrained-domain-> 
                  (or/c #f number?))
                 (λ (f) (procedure-arity-includes? 
                         f 
                         (length inits))))]
         [inits (listof number?)])
        ()
        any)]))
]

