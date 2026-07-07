#lang scribble/doc

@(require scribble/manual scribble/core scribble/eval
          "utils.rkt"
          (only-in racket/list argmax)
          (for-label racket/contract))

@;(require "shared.rkt" (only-in racket/list argmax))

@title[#:tag "contracts-first"]{Contracts: A Thorough Example}

本节针对同一个示例——Racket 的 @racket[argmax] 函数——开发几种不同风格的契约。根据其 Racket 文档，该函数接受一个过程 @racket[proc] 和一个非空值列表 @racket[lst]。它
@nested[#:style 'inset]{
返回列表 @racket[lst] 中使 @racket[proc] 结果最大的@emph{第一个}元素。}
我们对 @emph{first} 的强调是本节添加的。 

示例：
@interaction[#:eval ((make-eval-factory (list 'racket)))
(argmax add1 (list 1 2 3)) 
(argmax sqrt (list .4 .9 .16))
(argmax second '((a 2) (b 3) (c 4) (d 1) (e 4)))
]

这是该函数最简单的契约：
@racketmod[#:file @tt{version 1} 
racket

(define (argmax f lov) ...)

(provide
 (contract-out
  [argmax (-> (-> any/c real?) (and/c pair? list?) any/c)]))
]
该契约捕获了 @racket[argmax] 非正式描述的两个基本条件：
@itemlist[

@item{给定的函数必须产生可根据 @racket[<] 比较的数字。特别是，契约 @racket[(-> any/c number?)] 是不够的，因为 @racket[number?] 在 Racket 中还识别复数。}

@item{给定的列表必须至少包含一个元素。}
]
结合名称，该契约以与模块签名中 ML 函数类型相同的级别解释了 @racket[argmax] 的行为（除了非空列表方面）。

契约传达的信息可能比类型签名多得多。看看 @racket[argmax] 的第二个契约：
@racketmod[#:file @tt{version 2}
racket

(define (argmax f lov) ...)

(provide
 (contract-out
  [argmax
    (->i ([f (-> any/c real?)] [lov (and/c pair? list?)]) () 
         (r (f lov)
            (lambda (r)
              (define f@r (f r))
              (for/and ([v lov]) (>= f@r (f v))))))]))
]
这是一个@emph{依赖}契约，它命名了两个参数并使用这些名称对结果施加谓词。该谓词计算 @racket[(f r)]（其中 @racket[r] 是 @racket[argmax] 的结果），然后验证该值大于等于 @racket[lov] 中所有项的 @racket[f] 值。

@racket[argmax] 是否可能通过返回一个随机值来作弊，该值碰巧在 @racket[lov] 的所有元素上最大化 @racket[f]？
使用契约，可以排除这种可能性： 
@racketmod[#:file @tt{version 2 rev. a}
racket

(define (argmax f lov) ...)

(provide
 (contract-out
  [argmax
    (->i ([f (-> any/c real?)] [lov (and/c pair? list?)]) () 
         (r (f lov)
            (lambda (r)
              (define f@r (f r))
              (and (memq r lov)
                   (for/and ([v lov]) (>= f@r (f v)))))))]))
]
@racket[memq] 函数确保 @racket[r] 与 @racket[lov] 的某个成员是@emph{内涵相等}的
@margin-note*{也就是说，对于那些喜欢在硬件层面思考的人来说，就是"指针相等"。}。当然，稍加反思就可以看出，不可能构造出这样的值。函数在 Racket 中是 opaque 值，如果不应用函数，就不可能确定某个随机输入值是产生输出值还是触发异常。因此我们从这里开始忽略这种可能性。 

版本 2 阐述了 @racket[argmax] 文档的整体含义，但未能传达结果是给定列表中第一个最大化给定函数 @racket[f] 的元素。以下是传达非正式文档第二方面的版本： 
@racketmod[#:file @tt{version 3} 
racket

(define (argmax f lov) ...)

(provide
 (contract-out
  [argmax
    (->i ([f (-> any/c real?)] [lov (and/c pair? list?)]) ()
         (r (f lov)
            (lambda (r)
              (define f@r (f r))
              (and (for/and ([v lov]) (>= f@r (f v)))
                   (eq? (first (memf (lambda (v) (= (f v) f@r)) lov)) 
                        r)))))]))
]
也就是说，@racket[memf] 函数确定 @racket[lov] 中第一个在 @racket[f] 下值等于 @racket[r] 在 @racket[f] 下值的元素。如果该元素与 @racket[r] 内涵相等，则 @racket[argmax] 的结果是正确的。

第二个改进步骤引入了两个问题。首先，两个条件都重新计算了 @racket[lov] 中所有元素的 @racket[f] 值。其次，契约现在变得相当难以阅读。契约应该有一个简洁的表述，让客户能够通过简单扫描理解。让我们通过两个具有合理含义名称的辅助函数来消除可读性问题： 

@(define dominates1
  @multiarg-element['tt]{@list{
   @racket[f@r] is greater or equal to all @racket[(f v)] for @racket[v] in @racket[lov]}})

@(define first?1
  @multiarg-element['tt]{
   @list{@racket[r] is @racket[eq?] to the first element @racket[v] of @racket[lov] 
         for which @racket[(pred? v)]}})

@; ---------------------------------------------------------------------------------------------------
@racketmod[#:file @tt{version 3 rev. a} 
racket

(define (argmax f lov) ...)

(provide
 (contract-out
  [argmax
    (->i ([f (-> any/c real?)] [lov (and/c pair? list?)]) ()
         (r (f lov)
            (lambda (r)
              (define f@r (f r))
              (and (is-first-max? r f@r f lov)
                   (dominates-all f@r f lov)))))]))

@code:comment{where}

@code:comment{@#,dominates1}
(define (dominates-all f@r f lov)
  (for/and ([v lov]) (>= f@r (f v))))

@code:comment{@#,first?1}
(define (is-first-max? r f@r f lov)
  (eq? (first (memf (lambda (v) (= (f v) f@r)) lov)) r))
]
两个谓词的名称表达了它们的功能，原则上使得阅读它们的定义变得不必要。 

这一步给我们留下了新引入的低效问题。为了避免对 @racket[lov] 中所有 @racket[v] 重新计算 @racket[(f v)]，我们修改契约使其计算这些值并在需要时重用它们：

@(define dominates2
  @multiarg-element['tt]{@list{
   @racket[f@r] is greater or equal to all @racket[f@v] in @racket[flov]}})

@(define first?2
  @multiarg-element['tt]{
   @list{@racket[r] is @racket[(first x)] for the first
         @racket[x] in @racket[lov+flov] s.t. @racket[(= (second x) f@r)]}})

@racketmod[#:file @tt{version 3 rev. b} 
racket

(define (argmax f lov) ...)

(provide
 (contract-out
  [argmax
    (->i ([f (-> any/c real?)] [lov (and/c pair? list?)]) ()
         (r (f lov)
            (lambda (r)
              (define f@r (f r))
              (define flov (map f lov))
              (and (is-first-max? r f@r (map list lov flov))
                   (dominates-all f@r flov)))))]))

@code:comment{where}

@code:comment{@#,dominates2}
(define (dominates-all f@r flov)
  (for/and ([f@v flov]) (>= f@r f@v)))

@code:comment{@#,first?2}
(define (is-first-max? r f@r lov+flov)
  (define fst (first lov+flov))
  (if (= (second fst) f@r)
      (eq? (first fst) r)
      (is-first-max? r f@r (rest lov+flov))))
]
 现在结果谓词再次一次性计算 @racket[lov] 中所有元素的 @racket[f] 值。

@margin-note{"eager" 一词来自契约语言学的文献。}

当涉及调用 @racket[f] 时，版本 3 可能仍然过于 eager。虽然 Racket 的 @racket[argmax] 无论 @racket[lov] 包含多少项总是调用 @racket[f]，但为了说明目的，让我们假设我们自己的实现首先检查列表是否为单例。如果是，第一个元素将是 @racket[lov] 的唯一元素，在这种情况下无需计算 @racket[(f r)]。
@margin-note*{Racket 的 @racket[argmax] 隐式地论证了它不仅承诺在 @racket[lov] 上最大化 @racket[f] 的第一个值，而且还承诺 @racket[f] 为结果产生/产生了一个值。}
事实上，由于 @racket[f] 可能对某些输入发散或引发异常，@racket[argmax] 应在可能时避免调用 @racket[f]。

以下契约展示了如何调整高阶依赖契约以避免过于 eager： 

@racketmod[#:file @tt{version 4} 
racket

(define (argmax f lov) 
  (if (empty? (rest lov))
      (first lov)
      ...))

(provide
 (contract-out
  [argmax
    (->i ([f (-> any/c real?)] [lov (and/c pair? list?)]) ()
         (r (f lov)
            (lambda (r)
              (cond
                [(empty? (rest lov)) (eq? (first lov) r)]
                [else
                 (define f@r (f r))
                 (define flov (map f lov))
                 (and (is-first-max? r f@r (map list lov flov))
                      (dominates-all f@r flov))]))))]))

@code:comment{where}

@code:comment{@#,dominates2}
(define (dominates-all f@r lov) ...)

@code:comment{@#,first?2}
(define (is-first-max? r f@r lov+flov) ...)
]
 请注意，这种考虑不适用于一阶契约的世界。只有高阶（或惰性）语言才迫使程序员以这种精确度表达契约。

 发散或引发异常函数的问题应提醒读者注意具有副作用的函数这一更普遍的问题。如果给定的函数 @racket[f] 有可见的效果——比如它将调用记录到文件中——那么 @racket[argmax] 的客户端将能够观察到每次调用 @racket[argmax] 时的两组日志。准确地说，如果值列表包含多个元素，日志将包含 @racket[lov] 上每个值对 @racket[f] 的两次调用。如果 @racket[f] 计算成本高昂，加倍调用会带来高昂的成本。

 为了避免这种成本并标记过于 eager 契约的问题，契约系统可以记录已契约函数参数的 i/o，并在依赖规范中使用这些哈希表。这是 PLT 正在进行的研究主题。敬请期待。


@;{one could randomly check some element here, instead of all of them and
thus ensure 'correctness' at 1/(length a) probability}
