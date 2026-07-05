#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "black-box"]{黑盒过程}

当 Racket 程序编译时（见 @secref["compiler"]），编译器可能重新排序甚至移除没有可见效果的 @defterm{pure} 计算。从编译的角度来看，计算所需时间不被视为可见效果。编译器确实考虑了计算使用的内存（包括计算保持可达的值），但其程度仅是为了不增加程序的渐近内存使用量，可能通过其他方式移除或重新排序计算以减少内存使用。
@racket[black-box] 函数在几乎没有额外开销的情况下抑制了其中许多优化。

@defproc[(black-box [v any/c]) any/c]{

返回 @racket[v]。

就 Racket 编译器而言，@racket[black-box] 返回一个未知值，并且它对 @racket[v] 有副作用，这意味着对 @racket[black-box] 或其参数的调用无法在编译时被消除，也无法在其他副作用之间重新排序其求值。

@mz-examples[     
(let ([to-power 100])
  (let loop ([i 1000])
    (unless (zero? i)
      (code:comment "调用 `expt` 被完全优化消除，因为")
      (code:comment "没有效果且结果未使用：")
      (expt 2 to-power)
      (loop (sub1 i)))))

(let ([to-power 100])
  (let loop ([i 1000])
    (unless (zero? i)
      (code:comment "调用 `expt` 被优化为仅返回折叠的")
      (code:comment "常量，而不是每次迭代都调用 `expt`：")
      (black-box (expt 2 to-power))
      (loop (sub1 i)))))

(let ([to-power (black-box 100)])
  (let loop ([i 1000])
    (unless (zero? i)
      (code:comment "在安全模式下，会调用 `expt`，因为 `to-power`")
      (code:comment "未知是否为数值；在非安全模式下优化消除：")
      (expt 2 to-power)
      (loop (sub1 i)))))

(let ([to-power (black-box 100)])
  (let loop ([i 1000])
    (unless (zero? i)
      (code:comment "每次迭代都真正执行算术运算，因为 `to-power`")
      (code:comment "值被假设为未知，且 `expt` 结果被假设")
      (code:comment "会被使用，即使在非安全模式下：")
      (black-box (expt 2 to-power))
      (loop (sub1 i)))))
]

@history[#:added "8.18.0.17"]}
