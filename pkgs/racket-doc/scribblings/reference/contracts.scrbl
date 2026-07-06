#lang scribble/doc
@(require "mz.rkt")
@(require (for-label syntax/modcollapse
                     racket/stxparam
                     racket/serialize
                     racket/treelist))

@(define contract-eval
   (lambda ()
     (let ([the-eval (make-base-eval)])
       (the-eval '(require racket/contract racket/treelist racket/contract/parametric racket/list racket/math racket/mutable-treelist))
       the-eval)))

@(define blame-object @tech{blame object})
@(define blame-objects @tech{blame objects})

@title[#:tag "contracts" #:style 'toc]{Contracts}

@guideintro["contracts"]{contracts}

契约系统保护程序的各个部分免受彼此的影响。
程序员通过 @racket[(provide (contract-out ....))] 或 @racket[(require (contract-in ...))]
来指定模块导出行为，契约系统会强制执行这些约束。

@(define-syntax-rule
   (add-use-sources (x y ...))
   (x y ...
      #:use-sources
      (racket/contract/private/base
       racket/contract/private/misc
       racket/contract/private/provide
       racket/contract/private/guts
       racket/contract/private/prop
       racket/contract/private/blame
       racket/contract/collapsible
       racket/contract/private/ds
       racket/contract/private/opt
       racket/contract/private/basic-opters

       racket/contract/private/box
       racket/contract/private/hash
       racket/contract/private/vector
       racket/contract/private/struct-dc)))

@(define-syntax-rule
   (declare-exporting-ctc mod)
   (add-use-sources (declare-exporting mod racket/contract racket)))

@(add-use-sources @note-lib[racket/contract])

@deftech{契约}有两种形式：通过本手册本节列出的各种操作构造的契约，
以及各种同时充当契约的普通 Racket 值，包括
@itemize[
@item{@tech{符号}、@tech{布尔值}、@tech{关键字}和
@racket[null]，它们被视为使用 @racket[eq?] 识别自身的契约，}

@item{@tech{字符串}、@tech{字节字符串}、@tech{字符}、
      @racket[+nan.0] 和 @racketvalfont{+nan.f}，
      它们被视为使用 @racket[equal?] 识别自身的契约，}

@item{@tech{数字}（@racket[+nan.0] 和 @racketvalfont{+nan.f} 除外），
它们被视为使用 @racket[=] 识别自身的契约，}

@item{@tech{正则表达式}，它们被视为用于识别匹配该正则表达式的
       @tech{字节字符串}和 @tech{字符串}的契约，以及}

@item{谓词：任何一元过程都被视为谓词。在契约检查期间，
它被应用于出现的值，应返回 @racket[#f] 表示契约失败，
返回其他任何值表示契约通过。}

]

@deftech{契约组合子}是像 @racket[->] 和 @racket[listof] 这样的函数，
它们接受契约并产生其他契约。

Racket 中的契约分为三种不同的类别：
@;
@itemlist[@item{@deftech{Flat @tech{契约}}可以立即对给定值进行完全检查。
                 这类 @tech{契约}本质上是谓词函数。
                 使用 @racket[flat-contract-predicate]，
                 可以从任意 flat contract 中提取谓词；
                 一些 flat contracts 可以像函数一样应用，
                 在这种情况下它们接受单个参数并返回 @racket[#t] 或 @racket[#f]
                 来指示给定值是否会被该契约接受。
                 本库中函数返回的所有 flat contracts 都可以直接用作谓词，
                 但同时充当 flat contracts 的普通 Racket 值（如数字或符号）则不能。

                 函数 @racket[flat-contract?] 识别 flat contract。}
          @item{@deftech{Chaperone @tech{契约}}可能会以这样的方式包装一个值，
                 使其在后续使用中发出契约违规信号，
                 但保证不会改变其他行为。
                 例如，函数契约包装一个函数值并稍后检查输入和输出；
                 函数值在被契约包装之前拥有的任何属性
                 都会被契约包装器保留。

                 所有 @tech{flat contracts} 都可以在需要 @tech{chaperone contracts} 的地方使用
                 （但反之则不行）。函数 @racket[chaperone-contract?]
                 识别 chaperone contract。}
         @item{@deftech{Impersonator @tech{契约}}可以包装值，不提供任何保证。
                Impersonator contracts 可能会隐藏值的属性，
                甚至使其完全不透明（例如 @racket[new-∀/c]）。

                所有 @tech{契约}都可以在需要 impersonator contracts 的地方使用。
                函数 @racket[impersonator-contract?] 识别
                impersonator contract。}]

关于此层次结构的更多信息，请参见 ``@secref["chaperones"]'' 一节
以及关于 chaperones、impersonators 及其如何用于实现契约的研究论文 @cite{Strickland12}。

@history[#:changed "6.1.1.8" @list{Changed @racket[+nan.0] and @racketvalfont{+nan.f} to
                                           be @racket[equal?]-based contracts.}]

@local-table-of-contents[]

@; ----------------------------------------

@section[#:tag "data-structure-contracts"]{Data-structure Contracts}
@declare-exporting-ctc[racket/contract/base]

@defproc[(flat-contract-with-explanation [get-explanation (-> any/c (or/c boolean? (-> blame? any)))]
                                         [#:name name any/c (object-name get-explanation)])
         flat-contract?]{
  提供一种使用 flat contracts 的方式，当契约失败时，
  能提供关于失败的更多信息。

  如果 @racket[get-explanation] 返回布尔值，则该布尔值被视为
  @tech{flat contract} 中的谓词。如果它返回一个过程，
  则其处理方式与返回 @racket[#f] 类似，
  但结果过程会被调用来实际发出契约违规信号。

  @racket[name] 参数用作契约的名称；它默认为
  @racket[get-explanation] 函数的名称。

 @racketblock[(flat-contract-with-explanation
               (λ (val)
                 (cond
                   [(even? val) #t]
                   [else
                    (λ (blame)
                      (define more-information ...do-some-complex-computation-here...)
                      (raise-blame-error blame val
                                         '(expected: "an even number" given: "~e"
                                                     "and, here is more help: ~s")
                                         val more-information))])))]
}

@defproc[(flat-named-contract [name any/c]
                              [flat-contract flat-contract?]
                              [generator (or/c #f (-> exact-nonnegative-integer? (-> any/c))) #f])
         flat-contract?]{
生成一个类似于 @racket[flat-contract] 的 @tech{flat contract}，
但名称为 @racket[name]。

例如，
@racketblock[(define/contract i
               (flat-named-contract
                'odd-integer
                (lambda (x) (and (integer? x) (odd? x))))
               2)]

generator 参数为该 flat-named-contract 添加生成器。
参见 @racket[contract-random-generate] 了解更多信息。
}

@defthing[any/c flat-contract?]{

一个接受任意值的 @tech{flat contract}。

当将此契约用作函数契约的结果部分时，
请考虑使用 @racket[any]；使用 @racket[any] 可获得更好的内存性能，
但它也允许多个返回值。}


@defthing[none/c flat-contract?]{

一个不接受任何值的 @tech{flat contract}。}


@defproc[(or/c [contract contract?] ...)
         contract?]{

接受任意数量的 @tech{契约}，返回一个 @tech{契约}，
该契约接受任何一个单独契约所接受的值。

@racket[or/c] 的结果按从左到右的顺序依次应用契约来测试值，
但它总是将非 @tech{flat contracts}（如果有）移到末尾，最后检查。
因此，像 @racket[(or/c (not/c real?) positive?)] 这样的契约
保证只在实数上调用 @racket[positive?] 谓词。

如果所有参数都是过程或 @tech{flat contracts}，则结果是一个 @tech{flat contract}。
如果只有一个参数是高阶契约，则结果是一个先检查 flat contracts，
如果不通过再应用高阶契约的契约。

如果有多个高阶契约，@racket[or/c] 使用 @racket[contract-first-order-passes?]
来区分它们。更准确地说，当检查 @racket[or/c] 时，它首先检查所有
@tech{flat contracts}。如果都不通过，它对每个高阶契约调用
@racket[contract-first-order-passes?]。如果只有一个返回 true，
@racket[or/c] 使用该契约。如果都不返回 true，则发出契约违规信号。
如果多个返回 true，也会发出契约违规信号。
例如，此契约
@racketblock[
(or/c (-> number? number?)
      (-> string? string? string?))
]
不接受像这样的函数：@racket[(lambda args ...)]
因为它无法判断应该对函数使用两个 arrow 契约中的哪一个。

如果其所有参数都是 @racket[list-contract?]，则 @racket[or/c]
返回一个 @racket[list-contract?]。
}

@defproc[(first-or/c [contract contract?] ...)
         contract?]{

 接受任意数量的 @tech{契约}，返回一个 @tech{契约}，
 该契约接受任何一个单独契约所接受的值。

 @racket[first-or/c] 的结果按从左到右的顺序应用契约来测试值。
 因此，像 @racket[(first-or/c (not/c real?) positive?)] 这样的契约
 保证只在实数上调用 @racket[positive?] 谓词。

 如果所有参数都是过程或 @tech{flat contracts}，
 则结果是一个 @tech{flat contract}；
 类似地，如果所有参数都是 @tech{chaperone contracts}，结果也是。
 否则，结果是一个 @tech{impersonator contract}。

 如果有多个高阶契约，@racket[first-or/c] 使用
 @racket[contract-first-order-passes?] 来区分它们。
 更准确地说，当检查 @racket[first-or/c] 时，
 它检查第一个契约对值的一阶通过性。如果成功，
 则只使用该契约。如果失败，则移动到第二个契约，
 继续直到找到一阶检查成功的契约。如果都不成功，
 则发出契约违规信号。

 例如，此契约
 @racketblock[
 (first-or/c (-> number? number?)
        (-> string? string? string?))]
 接受函数 @racket[(λ args 0)]，
 将 @racket[(-> number? number?)] 契约应用于该函数，
 因为它排在前面，即使 @racket[(-> string? string? string?)] 也适用。

 如果其所有参数都是 @racket[list-contract?]，则 @racket[first-or/c]
 返回一个 @racket[list-contract?]。
}

@defproc[(and/c [contract contract?] ...) contract?]{

接受任意数量的 @tech{契约}，返回一个 @tech{契约}，
该契约接受同时满足所有契约的值。

如果所有参数都是过程或 @tech{flat contracts}，
则结果是一个 @tech{flat contract}。

@racket[and/c] 生成的契约按从左到右的顺序应用契约来测试值。

这意味着 @racket[and/c] 可以用来守卫契约中的非全谓词。
例如，此契约行为正确，正确地指责 @racket[whoops-not-a-number]
的定义不是数字：

 @examples[#:eval (contract-eval) #:once
           (eval:error
            (define/contract whoops-not-a-number
              (and/c real? even?)
              "four"))]
 但如果 @racket[and/c] 的参数顺序颠倒了，那么契约本身会引发错误：
 @examples[#:eval (contract-eval) #:once
           (eval:error
            (define/contract whoops-not-a-number
              (and/c even? real?)
              "four"))]

 如果多个契约不是 @tech{flat contracts}，
 那么契约的高阶部分被测试的顺序可能与直觉相反。
 例如，考虑这个函数，它以高阶方式使用 @racket[and/c]，
 契约总是成功但被调用时会打印，以便我们看到它们被调用的顺序。

 @examples[#:eval (contract-eval) #:once
           (define ((show-me n) x)
             (printf "show-me ~a\n" n)
             #t)

           (define/contract identity-with-complex-printing-contract
             (and/c (-> (show-me 4) (show-me 5))
                    (-> (show-me 3) (show-me 6))
                    (-> (show-me 2) (show-me 7))
                    (-> (show-me 1) (show-me 8)))
             (λ (x) x))

           (identity-with-complex-printing-contract 101)]

 检查顺序与契约被双重包装时的通常顺序相同。
 首先被添加的契约其 domain 被第二个检查，但其 range 被第一个检查，
 我们在此示例中看到了类似的模式，
 因为 @racket[and/c] 只是按顺序应用契约。

}


@defproc[(not/c [flat-contract flat-contract?]) flat-contract?]{

接受一个 @tech{flat contract} 或谓词，返回一个检查参数逆否的
@tech{flat contract}。}


@defproc[(=/c [z real?]) flat-contract?]{

返回一个 @tech{flat contract}，要求输入是一个数字且 @racket[=] 于 @racket[z]。}


@defproc[(</c [n real?]) flat-contract?]{

返回一个 @tech{flat contract}，要求输入是一个数字且 @racket[<] 于 @racket[n]。}


@defproc[(>/c [n real?]) flat-contract?]{
类似于 @racket[</c]，但用于 @racket[>]。}


@defproc[(<=/c [n real?]) flat-contract?]{
类似于 @racket[</c]，但用于 @racket[<=]。}


@defproc[(>=/c [n real?]) flat-contract?]{
类似于 @racket[</c]，但用于 @racket[>=]。}

@defproc[(between/c [n real?] [m real?])
flat-contract?]{ 返回一个 @tech{flat contract}，要求
输入是一个介于 @racket[n] 和 @racket[m] 之间或等于其中之一的实数。}

@defproc[(real-in [n real?] [m real?]) flat-contract?]{
@racket[between/c] 的别名。}

@defproc[(integer-in [j (or/c exact-integer? #f)] [k (or/c exact-integer? #f)]) flat-contract?]{

返回一个 @tech{flat contract}，要求输入是一个精确整数，
介于 @racket[j] 和 @racket[k] 之间（含边界）。
如果 @racket[j] 或 @racket[k] 为 @racket[#f]，则在该端无界。

@examples[#:eval (contract-eval) #:once
          (define/contract two-digit-number
            (integer-in 10 99)
            23)

          (eval:error
           (define/contract not-a-two-digit-number
             (integer-in 10 99)
             124))

          (define/contract negative-number
            (integer-in #f -1)
            -4)

          (eval:error
           (define/contract not-a-negative-number
             (integer-in #f -1)
             4))]

@history[#:changed "6.8.0.2" @elem{Allow @racket[j] and @racket[k] to be @racket[#f]}]

}

@defproc[(complex/c [real flat-contract?] [imag flat-contract?]) flat-contract?]{

返回一个 @tech{flat contract}，接受实部匹配 @racket[real]
且虚部匹配 @racket[imag] 的复数。

@examples[#:eval (contract-eval) #:once
          (eval:error
           (define/contract can-be-converted-to-exact
             (complex/c rational? rational?)
             +inf.0))

          (define/contract complex-integer
            (complex/c integer? integer?)
           1+2i)]

@history[#:added "8.11.1.10"]

}

@defproc[(char-in [a char?] [b char?]) flat-contract?]{

返回一个 @tech{flat contract}，要求输入是一个字符，
其码点编号介于 @racket[a] 和 @racket[b] 的码点编号之间（含边界）。}


@defthing[natural-number/c flat-contract?]{

一个 @tech{flat contract}，要求输入是一个精确的非负整数。}


@defproc[(string-len/c [len real?]) flat-contract?]{

返回一个 @tech{flat contract}，识别少于 @racket[len] 个字符的字符串。}


@defthing[false/c flat-contract?]{

@racket[#f] 的别名，用于向后兼容。}


@defthing[printable/c flat-contract?]{

一个 @tech{flat contract}，识别可以用 @racket[write] 写出
并用 @racket[read] 读回的值。}


@defproc[(one-of/c [v any/c] ...+) flat-contract?]{

接受任意数量的原子值，返回一个 @tech{flat contract}，
使用 @racket[eqv?] 作为比较谓词来识别这些值。
对于 @racket[one-of/c] 而言，原子值定义为：
@tech{字符}、@tech{符号}、@tech{布尔值}、
@racket[null]、@tech{关键字}、@tech{数字}、
@|void-const| 和 @|undefined-const|。

这是一个向后兼容的契约构造函数。
如果参数中既没有 @|void-const| 也没有 @|undefined-const|，
它只是将其参数传递给 @racket[or/c]。
}


@defproc[(symbols [sym symbol?] ...+) flat-contract?]{

接受任意数量的符号，返回一个 @tech{flat contract}，
识别这些符号。

这是一个向后兼容的构造函数；
它只是将其参数传递给 @racket[or/c]。
}

@defproc[(vectorof [c contract?]
                   [#:immutable immutable (or/c #t #f 'dont-care) 'dont-care]
                   [#:flat? flat? boolean? #f]
                   [#:eager eager (or/c #t #f exact-nonnegative-integer?) #t])
         contract?]{
返回一个 @tech{契约}，识别向量。向量的元素必须匹配 @racket[c]。

如果 @racket[flat?] 参数为 @racket[#t]，则结果契约是一个 @tech{flat contract}，
且 @racket[c] 参数也必须是 @tech{flat contract}。
这种 @tech{flat contracts} 如果应用于可变向量将是不可靠的，
因为它们不会检查对向量的后续操作。

如果 @racket[immutable] 参数为 @racket[#t] 且 @racket[c] 参数是 @tech{flat contract}
且 @racket[eager] 参数为 @racket[#t]，则结果将是一个 @tech{flat contract}。
如果 @racket[c] 参数是 @tech{chaperone contract}，
则结果将是一个 @tech{chaperone contract}。

如果 @racket[eager] 参数为 @racket[#t]，
则在 @racket[c] 是 @tech{flat contract} 时立即检查不可变向量。
如果 @racket[eager] 参数是一个数字 @racket[n]，
则在 @racket[c] 是 @tech{flat contract} 且向量长度小于等于 @racket[n] 时立即检查不可变向量。

当高阶 @racket[vectorof] 契约应用于向量时，结果与输入不是 @racket[eq?] 的。
对于不可变向量，结果将是一个副本；
对于可变向量，结果将是输入的 @tech{chaperone} 或 @tech{impersonator}，
除非 @racket[c] 参数是 @tech{flat contract} 且向量是不可变的，
在这种情况下结果是原始向量。

@history[#:changed "6.3.0.5" @list{Changed flat vector contracts to not copy
           immutable vectors.}
         #:changed "6.7.0.3" @list{Added the @racket[#:eager] option.}]
}

@defproc[(vector-immutableof [c contract?]) contract?]{

返回与 @racket[(vectorof c #:immutable #t)] 相同的 @tech{契约}。
此形式用于向后兼容。}

@defproc[(vector/c [c contract?] ...
                   [#:immutable immutable (or/c #t #f 'dont-care) 'dont-care]
                   [#:flat? flat? boolean? #f])
         contract?]{
返回一个 @tech{契约}，识别长度与给定契约数量匹配的向量。
向量的每个元素必须匹配其对应的契约。

如果 @racket[flat?] 参数为 @racket[#t]，则结果契约是一个 @tech{flat contract}，
且 @racket[c] 参数也必须是 @tech{flat contracts}。
这种 @tech{flat contracts} 如果应用于可变向量将是不可靠的，
因为它们不会检查对向量的后续操作。

如果 @racket[immutable] 参数为 @racket[#t] 且 @racket[c] 参数是
@tech{flat contracts}，则结果将是一个 @tech{flat contract}。
如果 @racket[c] 参数是 @tech{chaperone contracts}，
则结果将是一个 @tech{chaperone contract}。

当高阶 @racket[vector/c] 契约应用于向量时，结果与输入不是 @racket[eq?] 的。
对于不可变向量，结果将是一个副本；
对于可变向量，结果将是输入的 @tech{chaperone} 或 @tech{impersonator}。}


@defproc[(vector-immutable/c [c contract?] ...) contract?]{

返回与 @racket[(vector/c c ... #:immutable #t)] 相同的契约。
此形式用于向后兼容。}


@defproc[(box/c [in-c contract?]
                [c contract? in-c]
                [#:immutable immutable (or/c #t #f 'dont-care) 'dont-care]
                [#:flat? flat? boolean? #f])
         contract?]{
返回一个识别 box 的契约。box 的内容必须匹配 @racket[c]，
对可变 box 的修改必须匹配 @racket[in-c]。

如果 @racket[flat?] 参数为 @racket[#t]，则结果契约是一个 @tech{flat contract}，
且 @racket[out] 参数也必须是 @tech{flat contract}。
这种 @tech{flat contracts} 如果应用于可变 box 将是不可靠的，
因为它们不会检查对 box 的后续操作。

如果 @racket[immutable] 参数为 @racket[#t] 且 @racket[c] 参数是
@tech{flat contract}，则结果将是一个 @tech{flat contract}。
如果 @racket[c] 参数是 @tech{chaperone contract}，
则结果将是一个 @tech{chaperone contract}。

当高阶 @racket[box/c] 契约应用于 box 时，结果与输入不是 @racket[eq?] 的。
对于不可变 box，结果将是一个副本；
对于可变 box，结果将是输入的 @tech{chaperone} 或 @tech{impersonator}。}


@defproc[(box-immutable/c [c contract?]) contract?]{

返回与 @racket[(box/c c #:immutable #t)] 相同的契约。
此形式用于向后兼容。}


@defproc[(listof [c contract?]) list-contract?]{

返回一个契约，识别每个元素都匹配 @racket[c] 契约的列表。
注意，当此契约应用于一个值时，结果不一定与输入 @racket[eq?]。

@examples[#:eval (contract-eval) #:once
                 (define/contract some-numbers
                   (listof number?)
                   (list 1 2 3))
                 (eval:error
                  (define/contract just-one-number
                    (listof number?)
                    11))]

}


@defproc[(non-empty-listof [c contract?]) list-contract?]{

返回一个契约，识别非空列表，其每个元素都匹配 @racket[c] 契约。
注意，当此契约应用于一个值时，结果不一定与输入 @racket[eq?]。

@examples[#:eval (contract-eval) #:once
                 (define/contract some-numbers
                   (non-empty-listof number?)
                   (list 1 2 3))

                 (eval:error
                  (define/contract not-enough-numbers
                    (non-empty-listof number?)
                    (list)))]
}

@defproc[(list*of [ele-c contract?] [last-c contract? ele-c]) contract?]{

返回一个契约，识别非正规列表，其元素匹配 @racket[ele-c] 契约，
末尾位置匹配 @racket[last-c]。
如果非正规列表是用 @racket[cons] 创建的，
则其 @racket[car] 位置应匹配 @racket[ele-c]，
其 @racket[cdr] 位置应为 @racket[(list*of ele-c list-c)]。
否则，它应匹配 @racket[last-c]。
注意，当此契约应用于一个值时，结果不一定与输入 @racket[eq?]。

@examples[#:eval (contract-eval) #:once
                 (define/contract improper-numbers
                   (list*of number?)
                   (cons 1 (cons 2 3)))

                 (eval:error
                  (define/contract not-improper-numbers
                    (list*of number?)
                    (list 1 2 3)))]

@history[#:added "6.1.1.1"
         #:changed "6.4.0.4" @list{Added the @racket[last-c] argument.}]
}


@defproc[(cons/c [car-c contract?] [cdr-c contract?]) contract?]{

生成一个契约，识别第一和第二个元素分别匹配
@racket[car-c] 和 @racket[cdr-c] 的 pair。
注意，当此契约应用于一个值时，结果不一定与输入 @racket[eq?]。

如果 @racket[cdr-c] 契约是 @racket[list-contract?]，
则 @racket[cons/c] 返回一个 @racket[list-contract?]。

@examples[#:eval (contract-eval) #:once
                 (define/contract a-pair-of-numbers
                   (cons/c number? number?)
                   (cons 1 2))

                 (eval:error
                  (define/contract not-a-pair-of-numbers
                    (cons/c number? number?)
                    (cons #f #t)))]

@history[#:changed "6.0.1.13" @list{Added the @racket[list-contract?] propagating behavior.}]
}

@defform*[[(cons/dc [car-id contract-expr] [cdr-id (car-id) contract-expr] cons/dc-option)
           (cons/dc [car-id (cdr-id) contract-expr] [cdr-id contract-expr] cons/dc-option)]
          #:grammar ([cons/dc-option (code:line)
                                     #:flat
                                     #:chaperone
                                     #:impersonator])]{

生成一个契约，识别第一和第二个元素分别匹配
@racket[car-id] 和 @racket[cdr-id] 后面表达式的 pair。

在第一种情况下，@racket[cdr-id] 部分的契约
可能依赖于 pair 的 @racket[car-id] 部分的值；
在第二种情况下，反之亦然。

@examples[#:eval (contract-eval) #:once
                 (define/contract an-ordered-pair-of-reals
                   (cons/dc [hd real?] [tl (hd) (>=/c hd)])
                   (cons 1 2))

                 (eval:error
                  (define/contract not-an-ordered-pair-of-reals
                    (cons/dc [hd real?] [tl (hd) (>=/c hd)])
                    (cons 2 1)))]

@history[#:added "6.1.1.6"]
}

@defproc[(list/c [c contract?] ...) list-contract?]{

生成一个列表的契约。列表中元素的数量必须匹配
提供给 @racket[list/c] 的参数数量，
且每个列表元素必须匹配相应的契约。
注意，当此契约应用于一个值时，结果不一定与输入 @racket[eq?]。}

@defproc[(*list/c [prefix contract?] [suffix contract?] ...) list-contract?]{

生成一个列表的契约。列表中元素的数量必须至少与
@racket[suffix] 契约的数量一样多，
列表的尾部必须匹配这些契约，每个元素对应一个。
列表的前面部分可以任意长，每个元素必须匹配 @racket[prefix]。

注意，当此契约应用于一个值时，结果不一定与输入 @racket[eq?]。

 @examples[#:eval (contract-eval) #:once
           (define/contract a-list-of-numbers-ending-with-two-integers
             (*list/c number? integer? integer?)
             (list 1/2 4/5 +1i -11 322))

           (eval:error
            (define/contract not-enough-integers-at-the-end
              (*list/c number? integer? integer? integer?)
              (list 1/2 4/5 1/2 321 322)))]

}

@defproc[(treelist/c [ctc contract?]
                     [#:flat? flat? any/c (flat-contract? ctc)]
                     [#:lazy? lazy? any/c #f])
         contract?]{

 生成一个 @tech{treelists} 的契约，其元素
 匹配 @racket[ctc]。

 如果 @racket[flat?] 为真值，则 @racket[ctc] 必须是
 @tech{flat contract}。在这种情况下，
 @racket[treelist/c] 的结果也将是 flat contract。

 如果 @racket[lazy?] 为真值，则 @racket[ctc] 必须是
 @tech{chaperone contract}，结果契约将是 chaperone contract。
 在这种情况下，treelist 元素的契约直到访问值时才会被检查。

 如果 @racket[flat?] 和 @racket[lazy?] 都是 @racket[#f]，
 则契约将在检查过程中复制 treelist，
 如果 @racket[ctc] 是 chaperone contract，
 结果将是 @tech{chaperone contract}。

 @racket[flat?] 和 @racket[lazy?] 中至少有一个必须是 @racket[#f]。

 @examples[#:eval (contract-eval) #:once
           (define/contract natural-treelist
             (treelist/c natural?)
             (treelist 1 2 3))

           (eval:error
            (define/contract unnatural-treelist
              (treelist/c natural?)
              (treelist -1 -2 -3)))]

@history[#:added "8.12.0.7"
         #:changed "8.15.0.2" @elem{Changed the default value of @racket[lazy?]
           from @racket[(and (chaperone-contract? ctc) (not (flat-contract? ctc)))]
           to @racket[#f].}]
}

@defproc[(mutable-treelist/c [ctc contract?])
         contract?]{

 生成一个 @tech{可变 treelist} 的契约，其元素匹配 @racket[ctc]。

 @examples[#:eval (contract-eval) #:once
           (define/contract natural-treelist
             (mutable-treelist/c natural?)
             (mutable-treelist 0 1 2 3))
           (mutable-treelist-ref natural-treelist 1)

           (define/contract unnatural-treelist
             (mutable-treelist/c natural?)
             (mutable-treelist -1 2 3))

           (eval:error
            (mutable-treelist-ref unnatural-treelist 0))
           (eval:error
            (mutable-treelist-set! unnatural-treelist 2 -3))]

@history[#:added "8.12.0.11"]
}

@defproc[(syntax/c [c flat-contract?]) flat-contract?]{

生成一个 @tech{flat contract}，识别其 @racket[syntax-e] 内容
匹配 @racket[c] 的语法对象。}


@defform[(struct/c struct-id contract-expr ...)]{
生成一个契约，识别由 @racket[struct-id] 命名的结构体类型的实例，
其字段值匹配 @racket[contract-expr] 生成的契约。

不可变字段的契约必须是 flat 或 @tech{chaperone contracts}。
可变字段的契约可以是 impersonator contracts。
如果所有字段都是不可变的且 @racket[contract-expr] 求值为
@tech{flat contracts}，则生成 @tech{flat contract}。
如果所有 @racket[contract-expr] 都是 @tech{chaperone contracts}，
则生成 @tech{chaperone contract}。
否则，生成 impersonator contract。
}


@defform/subs[(struct/dc struct-id field-spec ... maybe-inv)
              ([field-spec [field-name maybe-lazy contract-expr]
                           [field-name (dep-field-name ...)
                                       maybe-lazy
                                       maybe-contract-type
                                       maybe-dep-state
                                       contract-expr]]
               [field-name field-id
                           (#:selector selector-id)
                           (field-id #:parent struct-id)]
               [maybe-lazy (code:line) #:lazy]
               [maybe-contract-type (code:line) #:flat #:chaperone #:impersonator]
               [maybe-dep-state (code:line) #:depends-on-state]
               [maybe-inv (code:line)
                          (code:line #:inv (dep-field-name ...) invariant-expr)])]{
生成一个契约，识别由 @racket[struct-id] 命名的结构体类型的实例，
其字段值匹配 @racket[field-spec] 生成的契约。

如果 @racket[field-spec] 列出了其他字段的名称，
则契约依赖于这些字段中的值，
每次应用选择器时都会求值 @racket[contract-expr] 表达式，
基于 @racket[dep-field-name] 字段的值构建字段的新契约
（@racket[dep-field-name] 语法与 @racket[field-name] 语法相同）。
如果字段是依赖字段且没有出现 @racket[contract-type] 注解，
则假定该契约是 chaperone，但不总是 @tech{flat contract}
（因此整个 @racket[struct/dc] 契约不是 @tech{flat contract}）。
如果不是这种情况，且契约总是 flat，
则该字段必须用 @racket[#:flat] 注解，
或者该字段必须用 @racket[#:impersonator] 注解
（在这种情况下，它必须是可变字段）。

@racket[field-name] 在第一种情况下是命名字段的标识符，
在第二种情况下是由 @racket[#:selector] 关键字指示的命名选择器的标识符，
或者是 @racket[struct-id] 的父结构体的字段 id，
由 @racket[#:parent] 关键字指示。

如果出现 @racket[#:lazy] 关键字，则字段上的契约被延迟检查
（仅在选择器被应用时）；
@racket[#:lazy] 契约不能放在可变字段上。

如果依赖契约依赖于某些可变状态，则使用
@racket[#:depends-on-state] 关键字参数
（如果字段的依赖契约依赖于可变字段，则自动推断此关键字）。
此关键字的存在意味着每次访问（或修改，如果是可变字段）
相应字段时都会求值契约表达式。
否则，依赖字段契约的表达式在契约应用于值时才求值。

如果出现 @racket[#:inv] 子句，则在契约应用于结构体时
求值不变式表达式（且必须返回非 @racket[#f] 值）。

不可变字段的契约必须是 flat 或 @tech{chaperone contracts}。
可变字段的契约可以是 impersonator contracts。
如果所有字段都是不可变的且 @racket[contract-expr] 求值为
@tech{flat contracts}，则生成 @tech{flat contract}。
如果所有 @racket[contract-expr] 都是 @tech{chaperone contracts}，
则生成 @tech{chaperone contract}。
否则，生成 impersonator contract。

例如，下面的函数 @racket[bst/c]
返回二叉搜索树的契约，其值都在 @racket[lo] 和 @racket[hi] 之间。
lazy 注解确保此契约不会改变
不检查整棵树的操作的运行时间。

 @examples[#:eval (contract-eval) #:once
           (struct bt (val left right))
           (define (bst/c lo hi)
             (or/c #f
                   (struct/dc bt
                              [val (between/c lo hi)]
                              [left (val) #:lazy (bst/c lo val)]
                              [right (val) #:lazy (bst/c val hi)])))

           (define/contract not-really-a-bst
             (bst/c -inf.0 +inf.0)
             (bt 5
                 (bt 4
                     (bt 2 #f #f)
                     (bt 6 #f #f))
                 #f))

           (bt-right not-really-a-bst)
           (bt-val (bt-left (bt-left not-really-a-bst)))
           (eval:error (bt-right (bt-left not-really-a-bst)))]

@history[#:changed "6.0.1.6" @elem{Added @racket[#:inv].}]
}

@defproc[(parameter/c [in contract?]
                      [out contract? in]
                      [#:impersonator? impersonator? any/c #t])
         contract?]{

生成一个参数上的契约，其值必须匹配 @racket[_out]。
当受契约约束的参数被设置时，它必须匹配 @racket[_in]。

 如果 @racket[impersonator?] 为真值，则 @racket[parameter/c]
 总是返回 @tech{impersonator contract}。
 如果它是 @racket[#f]，则当 @racket[in] 和 @racket[out] 都是
 @tech{chaperone contracts} 时，结果将是 @tech{chaperone contract}，
 否则为 @tech{impersonator contract}。

@examples[#:eval (contract-eval) #:once
(define/contract current-snack
  (parameter/c string?)
  (make-parameter "potato-chip"))
(define baked/c
  (flat-named-contract 'baked/c (λ (s) (regexp-match #rx"baked" s))))
(define/contract current-dinner
  (parameter/c string? baked/c)
  (make-parameter "turkey" (λ (s) (string-append "roasted " s))))

(eval:error (current-snack 'not-a-snack))
(eval:error
 (parameterize ([current-dinner "tofurkey"])
   (current-dinner)))
]}


@defproc[(procedure-arity-includes/c [n exact-nonnegative-integer?]) flat-contract?]{

生成一个过程的契约，该过程接受 @racket[n] 个参数
（即隐含了 @racket[procedure?] 契约）。}


@defproc[(hash/c [key chaperone-contract?]
                 [val contract?]
                 [#:immutable immutable (or/c #t #f 'dont-care) 'dont-care]
                 [#:flat? flat? boolean? #f])
         contract?]{
生成一个契约，识别具有由 @racket[key] 和 @racket[val] 参数
指定的键和值的 @racket[hash] 表。

@examples[#:eval (contract-eval) #:once
          (define/contract good-hash
            (hash/c integer? boolean?)
            (hash 1 #t
                  2 #f
                  3 #t))
          (eval:error
           (define/contract bad-hash
             (hash/c integer? boolean?)
             (hash 1 "elephant"
                   2 "monkey"
                   3 "manatee")))]

有许多技术细节控制 @racket[hash/c] 契约的行为方式。
@itemlist[@item{
 如果 @racket[flat?] 参数为 @racket[#t]，则结果契约是一个
 @tech{flat contract}，且 @racket[key] 和 @racket[val] 参数也必须是
 @tech{flat contracts}。

@examples[#:eval (contract-eval) #:once
          (flat-contract? (hash/c integer? boolean?))
          (flat-contract? (hash/c integer? boolean? #:flat? #t))
          (eval:error (hash/c integer? (-> integer? integer?) #:flat? #t))]

 这种 @tech{flat contracts} 如果应用于可变哈希表将是不可靠的，
 因为它们不会检查对哈希表的后续修改。

@examples[#:eval (contract-eval) #:once
          (define original-h (make-hasheq))
          (define/contract ctc-h
            (hash/c integer? boolean? #:flat? #t)
            original-h)
          (hash-set! original-h 1 "not a boolean")
          (hash-ref ctc-h 1)]}
           @item{
如果 @racket[immutable] 参数为 @racket[#t] 且 @racket[key] 和
@racket[val] 参数是 @racket[flat-contract?]，则结果将是
@racket[flat-contract?]。

@examples[#:eval (contract-eval) #:once
          (flat-contract? (hash/c integer? boolean? #:immutable #t))]

如果 domain 或 range 是 @racket[chaperone-contract?]，
则结果将是 @racket[chaperone-contract?]。

@examples[#:eval (contract-eval) #:once
          (flat-contract? (hash/c (-> integer? integer?) boolean?
                                  #:immutable #t))
          (chaperone-contract? (hash/c (-> integer? integer?) boolean?
                                       #:immutable #t))]
}

           @item{
如果 @racket[key] 参数是 @racket[chaperone-contract?] 但不是
@racket[flat-contract?]，则结果契约
只能应用于基于 @racket[equal?] 的哈希表。
@examples[#:eval (contract-eval) #:once
          (eval:error
           (define/contract h
             (hash/c (-> integer? integer?) any/c)
             (make-hasheq)))]
此外，当这样的 @racket[hash/c] 契约应用于哈希表时，结果与输入不是
@racket[eq?] 的。应用契约的结果对于不可变哈希表将是一个副本，
对于可变哈希表，将是原始哈希表的 @tech{chaperone} 或 @tech{impersonator}。
}]}

@defform[(hash/dc [key-id key-contract-expr] [value-id (key-id) value-contract-expr]
                  hash/dc-option)
         #:grammar ([hash/dc-option (code:line)
                                    (code:line #:immutable immutable?-expr hash/dc-option)
                                    (code:line #:kind kind-expr hash/dc-option)])]{
 创建一个 @racket[hash?] 表的契约，键匹配 @racket[key-contract-expr]，
 其中值的契约可以依赖于键本身，因为 @racket[key-id] 在求值
 @racket[values-contract-expr] 之前会绑定到相应的键。

 如果 @racket[immutable?-expr] 为 @racket[#t]，则只接受 @racket[immutable?] 哈希。
 如果它是 @racket[#f]，则始终拒绝 @racket[immutable?] 哈希。
 默认为 @racket['dont-care]，这种情况下同时接受可变和不可变哈希。

 如果 @racket[kind-expr] 求值为 @racket['flat]，
 则 @racket[key-contract-expr] 和 @racket[value-contract-expr]
 应求值为 @racket[flat-contract?]。
 如果是 @racket['chaperone]，则它们应为 @racket[chaperone-contract?]，
 也可以是 @racket['impersonator]，此时它们可以是任意 @racket[contract?]。
 默认为 @racket['chaperone]。

 @examples[#:eval (contract-eval) #:once
            (define/contract h
              (hash/dc [k real?] [v (k) (>=/c k)])
              (hash 1 3
                    2 4))
            (eval:error
             (define/contract h
               (hash/dc [k real?] [v (k) (>=/c k)])
               (hash 3 1
                     4 2)))]


}

@defproc[(channel/c [val contract?])
          contract?]{
生成一个契约，识别按 @racket[val] 参数指定的值
进行通信的 @tech{channel}。

如果 @racket[val] 参数是 @tech{chaperone contract}，
则结果契约是 @tech{chaperone contract}。
否则，结果契约是 impersonator contract。
当 channel 契约应用于 channel 时，结果 channel
与输入不是 @racket[eq?] 的。

@examples[#:eval (contract-eval) #:once
  (define/contract chan
    (channel/c string?)
    (make-channel))
  (thread (λ () (channel-get chan)))
  (eval:error (channel-put chan 'not-a-string))
]}


@defform/subs[#:literals (values)
  (prompt-tag/c contract ... maybe-call/cc)
  ([maybe-call/cc (code:line)
                  (code:line #:call/cc contract)
                  (code:line #:call/cc (values contract ...))])
   #:contracts ([contract contract?])]{
接受任意数量的契约，返回一个识别 continuation prompt tags 的契约，
并检查使用该受约束 prompt tag 的任何 abort 或 prompt handler。

每个 @racket[contract] 将检查传递给 @racket[abort-current-continuation]
并由 @racket[call-with-continuation-prompt] 调用的 handler
处理的相应值。

如果所有 @racket[contract] 都是 @tech{chaperone contracts}，
则结果契约也将是 @tech{chaperone} contract。
否则，契约是 @tech{impersonator} contract。

如果提供了 @racket[maybe-call/cc]，
则使用提供的契约来检查通过 @racket[call-with-current-continuation]
捕获的 continuation 的返回值。

@examples[#:eval (contract-eval) #:once
  (define/contract tag
    (prompt-tag/c (-> number? string?))
    (make-continuation-prompt-tag))

  (eval:error
   (call-with-continuation-prompt
     (lambda ()
       (number->string
         (call-with-composable-continuation
           (lambda (k)
             (abort-current-continuation tag k)))))
     tag
     (lambda (k) (k "not a number"))))
]
}


@defproc[(continuation-mark-key/c [contract contract?]) contract?]{
接受一个契约，返回一个识别 continuation marks 的契约，
并检查 marks 到值的任何映射或对 mark 值的任何访问。

如果参数 @racket[contract] 是 @tech{chaperone contract}，
则结果契约也将是 @tech{chaperone} contract。
否则，契约是 @tech{impersonator} contract。

@examples[#:eval (contract-eval) #:once
  (define/contract mark-key
    (continuation-mark-key/c (-> symbol? (listof symbol?)))
    (make-continuation-mark-key))

  (eval:error
   (with-continuation-mark
     mark-key
     (lambda (s) (append s '(truffle fudge ganache)))
     (let ([mark-value (continuation-mark-set-first
                        (current-continuation-marks) mark-key)])
       (mark-value "chocolate-bar"))))
]
}

@defproc[(evt/c [contract chaperone-contract?] ...) chaperone-contract?]{
返回一个契约，识别 @tech{可同步事件}，其
@tech{同步结果}由给定的 @racket[contract] 检查。

结果契约始终是 @tech{chaperone} contract，
其参数必须都是 @tech{chaperone contracts}。

@examples[#:eval (contract-eval) #:once
  (define/contract my-evt
    (evt/c evt?)
    always-evt)
  (define/contract failing-evt
    (evt/c number? number?)
    (alarm-evt (+ (current-inexact-milliseconds) 50)))
  (sync my-evt)
  (eval:error (sync failing-evt))
]
}


@defform[(flat-rec-contract id flat-contract-expr ...)]{

构造一个递归的 @tech{flat contract}。
@racket[flat-contract-expr] 可以引用 @racket[id] 来递归地
引用生成的契约。

例如，契约

@racketblock[
   (flat-rec-contract sexp
     (cons/c sexp sexp)
     number?
     symbol?)
]

是一个 @tech{flat contract}，检查（有限形式的）
S-表达式。它表明 @racket[_sexp] 要么是两个
用 @racket[cons] 组合的 @racket[_sexp]，要么是一个数字，要么是一个符号。

注意，如果契约应用于循环值，契约检查将不会终止。}


@defform[(flat-murec-contract ([id flat-contract-expr ...] ...) body ...+)]{

@racket[flat-rec-contract] 的泛化，用于同时定义多个
相互递归的 @tech{flat contracts}。每个 @racket[id] 在整个
@racket[flat-murec-contract] 形式中都可见，
最终 @racket[body] 的结果是整个形式的结果。}


@defidform[any]{

表示一个始终满足的契约。特别地，它可以接受多个值。
它只能用在像 @racket[->] 这样的契约的结果位置。
在其他地方使用 @racket[any] 是语法错误。}

@defproc[(promise/c [c contract?]) contract?]{

构造一个 promise 上的契约。该契约不会强制求值 promise，
但当 promise 被强制求值时，契约检查结果值是否满足 @racket[c] 契约。}

@defproc[(flat-contract [predicate (-> any/c any/c)]) flat-contract?]{

从 @racket[predicate] 构造一个 @tech{flat contract}。
如果谓词返回真值，则值满足契约。

此函数是谓词可以直接用作 @tech{flat contracts} 之前的遗留。
它今天的存在是为了向后兼容。
}


@defproc[(flat-contract-predicate [v flat-contract?])
         (-> any/c any/c)]{

从 @tech{flat contract} 中提取谓词。

注意，大多数 @tech{flat contracts} 可以直接用作谓词，但不是全部。
此函数可用于为同时充当契约的普通 Racket 值（如数字和符号）构建谓词。
当构建需要显式将普通 Racket 值转换为 flat contracts 的
@tech{contract combinator} 时，请考虑使用 @racket[coerce-flat-contract]
而不是 @racket[flat-contract-predicate]，
以便组合子可以在错误消息中使用组合子的名称来引发错误。
}

@defproc[(property/c [accessor (-> any/c any/c)]
                     [ctc flat-contract?]
                     [#:name name any/c (object-name accessor)])
         flat-contract?]{

构造一个 @tech{flat contract}，检查由 @racket[accessor] 访问的一阶属性
是否满足 @racket[ctc]。结果契约等价于

@racketblock[(lambda (v) (ctc (accessor v)))]

不同之处在于，契约违规产生的错误消息中包含更多信息。
@racket[name] 参数用于在错误消息中描述正在检查的属性。

@examples[#:eval (contract-eval) #:once
  (define/contract (sum-triple lst)
    (-> (and/c (listof number?)
               (property/c length (=/c 3)))
        number?)
    (+ (first lst) (second lst) (third lst)))
  (eval:check (sum-triple '(1 2 3)) 6)
  (eval:error (sum-triple '(1 2)))]

@history[#:added "7.3.0.11"]
}

@defproc[(suggest/c [c contract?]
                    [field string?]
                    [message string?]) contract?]{
 返回一个行为类似于 @racket[c] 的契约，除了
 在契约违规时向错误消息添加额外一行。

 @racket[field] 和 @racket[message] 字符串按照
 @secref["err-msg-conventions"] 中的指南添加。

 @examples[#:eval (contract-eval) #:once
           (define allow-calls? #f)
           (define/contract (f)
             (suggest/c (->* () #:pre allow-calls? any)
                        "suggestion" "maybe you should set! allow-calls? to #t")
             5)
           (eval:error (f))]
}

@; ------------------------------------------------------------------------

@section[#:tag "function-contracts"]{Function Contracts}
@declare-exporting-ctc[racket/contract/base]

@deftech{函数契约}包装一个过程以延迟对其参数和结果的检查。
有三种主要的函数契约组合子，它们具有递增的表达能力和递增的额外开销。
第一个 @racket[->] 是最便宜的。
它生成可以直接调用原始函数的包装函数。
使用 @racket[->*] 构建的契约需要
在包装函数中将参数打包为列表，
然后使用 @racket[keyword-apply] 或 @racket[apply]。
最后，@racket[->i]（以及 @racket[->d]）是最昂贵的，
因为它需要延迟对 domain 和 range 的契约表达式的求值，
直到函数本身被调用或返回。

@racket[case->] 契约是专门的契约，
设计用于匹配 @racket[case-lambda]，
@racket[unconstrained-domain->] 允许 range 检查
而不要求 domain 具有任何特定形态
（用法示例见下文）。

@(define lit-ellipsis (racket ...))

@defform*/subs[#:literals (any values)
               [(-> dom ... range)
                (-> dom ... ellipsis dom-expr ... range)]
               ([dom dom-expr (code:line keyword dom-expr)]
                [range range-expr (values range-expr ...) any]
                [ellipsis #,lit-ellipsis])]{

生成一个函数契约，该函数接受由 @racket[dom-expr] 契约指定的参数，
并返回固定数量的结果或完全未指定的结果
（后者在指定 @racket[any] 时）。

每个 @racket[dom-expr] 是函数参数上的契约，
每个 @racket[range-expr] 是函数结果上的契约。

如果 domain 包含 @racket[...]，
则函数接受 domain 部分中其余契约指定的参数，
以及任意更多的匹配 @racket[...] 前契约的参数。
否则，契约精确接受指定的参数。

@margin-note{在两个空格分隔的 @racketparenfont{.} 之间使用 @racket[->]
等同于将 @racket[->] 紧跟在包围的左括号之后。
参见 @guidesecref["lists-and-syntax"] 或 @secref["parse-pair"]
了解更多信息。}

例如，
@racketblock[(integer? boolean? . -> . integer?)]
生成一个二元函数的契约。第一个参数必须是整数，
第二个参数必须是布尔值。该函数必须产生一个整数。

@examples[#:eval (contract-eval) #:once
          (define/contract (maybe-invert i b)
            (-> integer? boolean? integer?)
            (if b (- i) i))

          (maybe-invert 1 #t)
          (eval:error (maybe-invert #f 1))]

domain 规格可以包含关键字。如果是这样，函数必须接受相应的
（必需的）关键字参数，且关键字参数的值必须匹配相应的契约。
例如：
@racketblock[(integer? #:invert? boolean? . -> . integer?)]
是一个函数契约，该函数接受一个按位置传递的整数参数
和一个 @racket[#:invert?] 布尔值参数。

@examples[#:eval (contract-eval) #:once
          (define/contract (maybe-invert i #:invert? b)
            (-> integer? #:invert? boolean? integer?)
            (if b (- i) i))

          (maybe-invert 1 #:invert? #t)
          (eval:error (maybe-invert 1 #f))]

作为使用 @racket[...] 的示例，此契约：
@racketblock[(integer? string? ... integer? . -> . any)]
对于一个函数，要求该函数的第一个和最后一个参数必须是整数
（并且必须至少有两个参数），其他任何参数必须是字符串。

@examples[#:eval (contract-eval) #:once
          (define/contract (string-length/between? lower-bound s1 . more-args)
            (-> integer? string? ... integer? boolean?)

            (define all-but-first-arg-backwards (reverse (cons s1 more-args)))
            (define upper-bound (first all-but-first-arg-backwards))
            (define strings (rest all-but-first-arg-backwards))
            (define strings-length
              (for/sum ([str (in-list strings)])
                (string-length str)))
            (<= lower-bound strings-length upper-bound))

          (string-length/between? 4 "farmer" "john" 40)
          (eval:error (string-length/between? 4 "farmer" 'john 40))
          (eval:error (string-length/between? 4 "farmer" "john" "fourty"))]

如果 @racket[any] 用作 @racket[->] 的最后一个子形式，
则不对函数的结果执行契约检查，因此任意数量的值都是合法的
（甚至在不同调用中可以有不同数量的值）。

@examples[#:eval (contract-eval) #:once
          (define/contract (multiple-xs n x)
            (-> natural? any/c any)
            (apply
             values
             (for/list ([_ (in-range n)])
               n)))

          (multiple-xs 4 "four")]

如果 @racket[(values range-expr ...)] 用作 @racket[->] 的最后一个子形式，
则函数必须为每个契约产生一个结果，每个值必须匹配其对应的契约。


@examples[#:eval (contract-eval) #:once
          (define/contract (multiple-xs n x)
            (-> natural? any/c (values any/c any/c any/c))
            (apply
             values
             (for/list ([_ (in-range n)])
               n)))

          (multiple-xs 3 "three")
          (eval:error (multiple-xs 4 "four"))]

@history[#:changed "6.4.0.5" @list{Added support for ellipses}]
}


@defform*/subs[#:literals (any values)
          [(->* (mandatory-dom ...) optional-doms rest pre range post)]
          ([mandatory-dom dom-expr (code:line keyword dom-expr)]
           [optional-doms (code:line) (optional-dom ...)]
           [optional-dom dom-expr (code:line keyword dom-expr)]
           [rest (code:line) (code:line #:rest rest-expr)]
           [pre (code:line)
                (code:line #:pre pre-cond-expr)
                (code:line #:pre/desc pre-cond-expr)]
           [range range-expr (values range-expr ...) any]
           [post (code:line)
                 (code:line #:post post-cond-expr)
                 (code:line #:post/desc post-cond-expr)])]{

@racket[->*] 契约组合子为接受可选参数（关键字或位置参数）
和/或任意数量参数的函数生成契约。
@racket[->*] 契约的第一个子句描述必需参数，
类似于 @racket[->] 契约的参数描述。
第二个子句描述可选参数。
range 的描述可以是 @racket[any] 或一系列契约，
指示函数必须返回多个值。

如果存在，@racket[rest-expr] 契约约束 rest 参数中的参数。
注意，@racket[rest-expr] 契约只约束 rest 参数中的参数，
不约束必需参数中的参数。
例如，此契约：
@racketblock[(->* () #:rest (cons/c integer? (listof integer?)) any)]
不匹配函数
@racketblock[(λ (x . rest) x)]
因为契约坚持函数接受零个参数
（因为契约中没有列出必需参数）。
@racket[->*] 契约不知道 rest 参数上的契约
最终会禁止空参数列表。

@racket[pre-cond-expr] 和 @racket[post-cond-expr]
表达式分别在函数被调用和返回时检查，
允许在无需显式关联参数（或结果）的情况下检查环境。
如果使用 @racket[#:pre] 或 @racket[#:post] 关键字，
则 @racket[#f] 结果被视为失败，任何其他结果被视为成功。
如果使用 @racket[#:pre/desc] 或 @racket[#:post/desc] 关键字，
表达式的结果必须是布尔值、字符串或字符串列表，
其中 @racket[#t] 表示成功，其他任何结果表示失败。
如果结果是字符串或字符串列表，
字符串应在每个换行符后恰好有一个空格，
多个字符串用作错误消息中的行；
在这种情况下，契约本身为每个字符串添加一个空格的缩进。
格式要求不会被检查，但它们匹配
@secref["err-msg-conventions"] 中的建议。

例如，契约
@racketblock[(->* () (boolean? #:x integer?) #:rest (listof symbol?) symbol?)]
匹配可选接受一个布尔值、一个整数关键字参数 @racket[#:x]
和任意更多符号，并返回一个符号的函数。
}

@defform*/subs[#:literals (any values)
[(->i maybe-chaperone
      (mandatory-dependent-dom ...)
      dependent-rest
      pre-condition
      param-value
      dependent-range
      post-condition)
 (->i maybe-chaperone
      (mandatory-dependent-dom ...)
      (optional-dependent-dom ...)
      dependent-rest
      pre-condition
      param-value
      dependent-range
      post-condition)]
([maybe-chaperone #:chaperone (code:line)]
 [mandatory-dependent-dom id+ctc
                          (code:line keyword id+ctc)]
 [optional-dependent-dom id+ctc
                         (code:line keyword id+ctc)]
 [dependent-rest (code:line) (code:line #:rest id+ctc)]
 [pre-condition (code:line)
                (code:line #:pre (id ...)
                           boolean-expr pre-condition)
                (code:line #:pre/desc (id ...)
                           expr pre-condition)
                (code:line #:pre/name (id ...)
                           string boolean-expr pre-condition)]
 [param-value (code:line)
              (code:line #:param (id ...)
                         param-expr val-expr param-value)]
 [dependent-range any
                  id+ctc
                  un+ctc
                  (values id+ctc ...)
                  (values un+ctc ...)]
 [post-condition (code:line)
                 (code:line #:post (id ...)
                            boolean-expr post-condition)
                 (code:line #:post/desc (id ...)
                            expr post-condition)
                 (code:line #:post/name (id ...)
                            string boolean-expr post-condition)]
 [id+ctc [id contract-expr]
         [id (id ...) contract-expr]]
 [un+ctc [_ contract-expr]
         [_ (id ...) contract-expr]]
)]{

@racket[->i] 契约组合子与 @racket[->*] 组合子的不同之处在于，
每个参数和结果都被命名，这些名称可以在子契约和前置/后置条件子句中使用。
换句话说，@racket[->i] 表达了参数和结果之间的依赖关系。

@racket[->i] 的可选第一个关键字参数指示结果契约是否为 chaperone。
如果是 @racket[#:chaperone]，则所有参数和结果的契约必须是
@tech{chaperone contracts}，@racket[->i] 的结果将是 @tech{chaperone contract}。
如果未提供，则结果契约将不是 @tech{chaperone contract}。

@racket[->i] 契约的第一个子形式涵盖必需参数，
第二个子形式涵盖可选参数。
之后是一个可选的 rest-args 契约和一个可选的前置条件。
前置条件由 @racket[#:pre] 关键字引入，
后跟它所依赖的名称列表。
如果使用 @racket[#:pre/name] 关键字，提供的字符串将用作错误消息的一部分；
@racket[#:post/name] 同理。
如果使用 @racket[#:pre/desc] 或 @racket[#:post/desc]，
表达式的结果以与 @racket[->*] 相同的方式处理。

前置条件之后是可选的 @racket[param-value] 非终结符，
指定在函数的动态范围内要赋值的参数。
每个赋值由 @racket[#:param] 关键字引入，
后跟它所依赖的名称列表、确定要设置的参数的 @racket[param-expr]
以及将与参数关联的 @racket[val-expr]。

@racket[dependent-range] 非终结符指定可能的结果契约。
如果是 @racket[any]，则允许任何值。
否则，结果契约将名称和契约配对，
或者多值返回带有名称和契约。
在后两种情况下，range 契约可以可选地后跟后置条件；
如果 range 契约是 @racket[any]，则不允许后置条件表达式。
与前置条件一样，后置条件必须指定它所依赖的变量。

考虑此示例契约：
@racketblock[(->i ([x number?]
                   [y (x) (>=/c x)])
                  [result (x y) (and/c number? (>=/c (+ x y)))])]
它指定了一个二元函数，两个参数都是数字。
第二个参数 (@racket[y]) 上的契约要求它大于第一个参数。
结果契约承诺一个大于两个参数之和的数字。
@racket[y] 的依赖规范表明参数契约依赖于第一个参数的值，
而 @racket[result] 的依赖序列表明契约依赖于两个参数的值。
@margin-note*{通常，空序列（几乎）等同于完全不添加序列，
只是前者比后者更昂贵。}
由于 @racket[x] 的契约不依赖于任何其他内容，
它不带任何依赖序列，甚至不包括 @racket[()]。

此示例与前一个类似，但 @racket[x] 和 @racket[y] 参数现在是
可选关键字参数，而不是必需的位置参数：
@racketblock[(->i ()
                  (#:x [x number?]
                   #:y [y (x) (>=/c x)])
                  [result (x y)
                   (and/c number?
                          (if (and (number? x) (number? y))
                              (>=/c (+ x y))
                              any/c))])]
range 中测试 @racket[_x] 和 @racket[_y] 的条件
对于覆盖 @racket[_x] 或 @racket[_y] 未被调用上下文提供的情况
是必要的（意味着它们可能绑定到 @racket[the-unsupplied-arg]）。

契约表达式并不总是按顺序求值。
首先，如果给定契约表达式没有依赖关系，
该契约表达式在 @racket[->i] 表达式求值时求值，
而不是在函数被调用或返回时。
这些无依赖的契约表达式按列出顺序求值。
@;
其次，依赖的契约子表达式在受约束函数被调用或返回时
以满足依赖关系的顺序求值。
也就是说，如果参数的契约依赖于某个其他契约的值，
则前者先求值（以便参数经过契约检查后可用于另一个）。
当两个参数之间（或结果与参数之间）没有依赖关系时，
在源文本中出现在前面的契约先求值。

 如果带有依赖关系的 range 契约的所有标识符位置都是
 @racket[_]（下划线），则 range 契约表达式在函数被调用时求值，
 而不是在返回时求值。
 否则，依赖的 range 表达式在函数返回时求值。

 如果有未提供的可选参数，则相应变量将绑定到
 一个称为 @racket[the-unsupplied-arg] 的特殊值。
 例如，在此契约中：
 @racketblock[(->i ([x (y) (if (unsupplied-arg? y)
                               real?
                               (>=/c y))])
                   ([y real?])
                   any)]
 @racket[x] 上的契约依赖于 @racket[_y]，
 但 @racket[_y] 可能在调用点未提供。
 在这种情况下，@racket[x] 的契约中 @racket[_y] 的值
 是 @racket[the-unsupplied-arg]，
 @racket[->i] 契约必须检查它并调整 @racket[_x] 上的契约
 以考虑 @racket[_y] 未提供的情况。

当未提供参数的契约表达式是依赖的，
且参数在调用点未提供时，契约表达式根本不会被求值。
例如，在此契约中，@racket[_y] 的契约表达式仅在提供 @racket[_y] 时才求值：
@racketblock[(->i ()
                  ([x real?]
                   [y (x) (>=/c x)])
                  any)]
相比之下，@racket[_x] 的表达式始终被求值
（实际上，它在 @racket[->i] 表达式求值时即求值，
因为它没有任何依赖关系）。

@history[#:changed "8.7.0.1" @list{Added @racket[#:param].}]
}

@defform*/subs[#:literals (any values)
[(->d (mandatory-dependent-dom ...)
      dependent-rest
      pre-condition
      dependent-range
      post-condition)
 (->d (mandatory-dependent-dom ...)
      (optional-dependent-dom ...)
      dependent-rest
      pre-condition
      dependent-range
      post-condition)]
([mandatory-dependent-dom [id dom-expr] (code:line keyword [id dom-expr])]
 [optional-dependent-dom [id dom-expr] (code:line keyword [id dom-expr])]
 [dependent-rest (code:line) (code:line #:rest id rest-expr)]
 [pre-condition (code:line) (code:line #:pre boolean-expr) (code:line #:pre-cond boolean-expr)]
 [dependent-range any
                  [_ range-expr]
                  (values [_ range-expr] ...)
                  [id range-expr]
                  (values [id range-expr] ...)]
 [post-condition (code:line) (code:line #:post-cond boolean-expr)]
)]{

此契约保留用于向后兼容；任何新代码应改用 @racket[->i]。

此契约类似于 @racket[->i]，但是 ``宽松的''，
意味着它不在内部强制执行契约。例如，使用此契约
@racketblock[(->d ([f (-> integer? integer?)])
                  #:pre
                  (zero? (f #f))
                  any)]
将允许以 @racket[#f] 调用 @racket[f]，
触发 @racket[f] 的作者通过坚持 @racket[f] 的契约只接受整数
而试图禁止的任何不良行为。

@racket[#:pre-cond] 和 @racket[#:post-cond] 关键字是
@racket[#:pre] 和 @racket[#:post] 的别名，提供用于向后兼容。

}

@defform*/subs[#:literals (any values ->)
                          [(case-> (-> dom-expr ... rest range) ...)]
                          ([rest (code:line) (code:line #:rest rest-expr)]
                           [range range-expr (values range-expr ...) any])]{
  此契约形式设计用于匹配 @racket[case-lambda]。
  @racket[case->] 的每个参数是一个契约，
  约束 @racket[case-lambda] 中的一个子句。
  如果存在 @racket[#:rest] 关键字，
  相应子句必须接受任意数量的参数。
  @racket[range] 规格与 @racket[->] 和 @racket[->*] 的相同。

  例如，此契约匹配一个具有两种情况的函数，
  一种接受整数并返回 void，
  另一种不接受参数并返回一个整数。
  @racketblock[(case-> (-> integer? void?)
                       (-> integer?))]
  这样的契约可用于守卫控制对单个共享整数的访问的函数。
}

@defproc[(dynamic->*
          [#:mandatory-domain-contracts mandatory-domain-contracts (listof contract?) '()]
          [#:optional-domain-contracts optional-domain-contracts (listof contract?) '()]
          [#:mandatory-keywords mandatory-keywords (listof keyword?) '()]
          [#:mandatory-keyword-contracts mandatory-keyword-contracts (listof contract?) '()]
          [#:optional-keywords optional-keywords (listof keyword?) '()]
          [#:optional-keyword-contracts optional-keyword-contracts (listof contract?) '()]
          [#:rest-contract rest-contract (or/c #f contract?) #f]
          [#:range-contracts range-contracts (or/c #f (listof contract?))])
         contract?]{
  类似于 @racket[->*]，但参数和结果的数量可以在运行时计算，
  而不是在编译时固定。传递 @racket[#f] 作为
  @racket[#:range-contracts] 参数生成的契约类似于
  在 @racket[->] 或 @racket[->*] 中使用 @racket[any] 的契约。

  对于许多用途，@racket[dynamic->*] 的结果比 @racket[->*]（或 @racket[->]）慢，
  但对于某些用途它具有相当的速度。
  @racket[dynamic->*] 返回的契约的名称使用 @racket[->] 或 @racket[->*] 语法。
}

@defform[(unconstrained-domain-> range-expr ...)]{

构造一个接受函数的契约，但对函数的 domain 不做任何约束。
@racket[range-expr] 确定结果的数量和每个结果的契约。

通常，此契约必须与另一个契约组合，
以确保 domain 实际上是已知的，能够安全地调用函数本身。

例如，契约

@racketblock[
(provide
 (contract-out
  [f (->d ([size natural-number/c]
           [proc (and/c (unconstrained-domain-> number?)
                        (lambda (p)
                          (procedure-arity-includes? p size)))])
          ()
          [_ number?])]))
]

表示函数 @racket[f] 接受一个自然数和一个函数。
@racket[f] 接受的函数的 domain 必须包含
一个适用于 @racket[size] 个参数的情况，
这意味着 @racket[f] 可以安全地向其输入提供 @racket[size] 个参数。

例如，以下是使用上述契约不会被指责的 @racket[f] 的定义：

@racketblock[
(define (f i g)
  (apply g (build-list i add1)))
]}

@defthing[predicate/c contract?]{
 等价于 @racket[(-> any/c boolean?)]。此前，此契约是必要的，
 因为它包含了一个 @racket[->] 中没有的额外优化。
 但现在 @racket[->] 执行相同的优化，因此不应再使用此契约。
 该契约仍然提供用于向后兼容。
}

@defthing[the-unsupplied-arg unsupplied-arg?]{
  由 @racket[->i]（和 @racket[->d]）用于绑定
  调用点未提供的可选参数。
}

@defproc[(unsupplied-arg? [v any/c]) boolean?]{
  一个用于确定 @racket[v] 是否为 @racket[the-unsupplied-arg] 的谓词。
}


@section[#:tag "parametric-contracts"]{Parametric Contracts}
@defmodule*/no-declare[(racket/contract/parametric)]
@declare-exporting-ctc[racket/contract/parametric]

使用 parametric contract 最方便的方式是使用
@racket[contract-out] 的 @racket[#:∃]、@racket[#:exists]、@racket[#:∀] 和 @racket[#:forall] 关键字。
@racketmodname[racket/contract/parametric] 库提供了一些更多的
通用 parametric contracts。

@defform[(parametric->/c (x ...) c)]{

为参数化多态函数创建契约。每个函数由 @racket[c] 保护，
其中每个 @racket[x] 在 @racket[c] 中绑定，
引用一个多态类型，该类型在每次应用函数时实例化。

在每次应用函数时，@racket[parametric->/c] 契约
为每个 @racket[x] 构造一个新的不透明包装器；
流入多态函数的值
（即在相对于 @racket[parametric->/c] 的负位置中由某个 @racket[x] 保护的值）
被包装在相应的不透明包装器中。
从多态函数流出的值
（即在相对于 @racket[parametric->/c] 的正位置中由某个 @racket[x] 保护的值）
会被检查适当的包装器。
如果有，则解包；如果没有，则发出契约违规信号。

@examples[#:eval (contract-eval) #:once
(define swap-ctc (parametric->/c [A B] (-> A B (values B A))))

(define/contract (good-swap a b)
  swap-ctc
  (values b a))

(good-swap 1 2)


(define/contract (bad-swap a b)
  swap-ctc
  (values a b))

(eval:error (bad-swap 1 2))


(define/contract (copy-first a _b)
  swap-ctc
  (values a a))

(eval:error (let ((v 'same-symbol)) (copy-first v v)))

(define/contract (inspect-first a b)
  swap-ctc
  (if (integer? a)
    (+ a b)
    (raise-user-error "an opaque wrapped value is not an integer")))

(eval:error (inspect-first 1 2))
]
}

@defproc[(new-∀/c [name (or/c symbol? #f) #f]) contract?]{
  构造一个新的 universal contract。

  Universal contracts 在负位置（例如函数输入）
  接受所有值并将其包装在不透明结构体中，隐藏精确值。
  在正位置（例如函数返回），
  universal contract 只接受先前在负位置中接受的值
  （通过检查包装器）。

  名称用于在错误消息中标识契约，
  默认为基于 @racket[new-∀/c] 的词法上下文的名称。

  例如，此契约：
  @racketblock[(let ([a (new-∀/c 'a)])
                 (-> a a))]
  描述了恒等函数（或非终止函数）。
  也就是说，@racket[a] 的第一次使用出现在负位置，
  因此该函数的输入被包装在不透明结构体中。
  然后，当函数返回时，检查结果是否被包装，
  因为第二个 @racket[a] 出现在正位置。

  @racket[new-∀/c] 契约构造函数是 @racket[new-∃/c] 的对偶。
}

@defproc[(new-∃/c [name (or/c symbol? #f) #f]) contract?]{
  构造一个新的 existential contract。

  Existential contracts 在正位置（例如函数返回）
  接受所有值并将其包装在不透明结构体中，隐藏精确值。
  在负位置（例如函数输入），
  它们只接受先前在正位置中接受的值
  （通过检查包装器）。

  名称用于在错误消息中标识契约，
  默认为基于 @racket[new-∀/c] 的词法上下文的名称。

  例如，此契约：
  @racketblock[(let ([a (new-∃/c 'a)])
                 (-> (-> a a)
                     any/c))]
  描述了一个接受恒等函数（或非终止函数）
  并返回任意值的函数。
  也就是说，@racket[a] 的第一次使用出现在正位置，
  因此该函数的输入被包装在不透明结构体中。
  然后，当函数返回时，检查结果是否被包装，
  因为第二个 @racket[a] 出现在负位置。

  @racket[new-∃/c] 契约构造函数是 @racket[new-∀/c] 的对偶。
}




@; ------------------------------------------------------------------------

@section{Lazy Data-structure Contracts}

@defform[(contract-struct id (field-id ...))]{

  @deprecated[@racket[struct]]{Lazy struct contracts no longer require a separate
              struct declaration; instead @racket[struct/dc]
              and @racket[struct/c] work directly with
              @racket[struct] and @racket[define-struct].
  }

类似于 @racket[struct]，但有两个区别：
它们不定义字段修改器，而是定义两个契约构造函数：
@racket[id]@racketidfont{/c} 和 @racket[id]@racketidfont{/dc}。
第一个是一个过程，接受与字段数量相同的参数，
返回字段匹配参数的结构体值的契约。
第二个是一个语法形式，也生成结构体上的契约，
但后面字段的契约可能依赖于前面字段的值。

生成的契约组合子是 @italic{惰性的}：
它们只在实际检查的某部分数据结构上验证契约是否成立。
更准确地说，惰性数据结构契约直到选择器提取结构体的字段时才被检查。

@specsubform/subs[
(#,(elem (racket id) (racketidfont "/dc")) field-spec ...)

([field-spec
  [field-id contract-expr]
  [field-id (field-id ...) contract-expr]])
]{

在每个 @racket[field-spec] 情况下，第一个 @racket[field-id]
指定契约应用于哪个字段；字段必须按照原始
@racket[contract-struct] 的相同顺序指定。
第一种情况适用于字段上的契约不依赖于任何其他字段值的情况。
第二种情况适用于字段上的契约确实依赖于其他一些字段的情况，
括号内的 @racket[field-id] 指示它依赖于哪些字段；
这些依赖关系只能是前面的字段。}}

@defform[(define-contract-struct id (field-id ...))]{
  @deprecated[@racket[struct]]{Lazy struct contracts no longer require a separate
              struct declaration; instead @racket[struct/dc]
              and @racket[struct/c] work directly with
              @racket[struct] and @racket[define-struct].
  }

  类似于 @racket[contract-struct]，但构造函数的名称是
  @racketidfont["make-"]@racket[id]，很像 @racket[define-struct]。
}

@; ------------------------------------------------------------------------

@include-section["contracts-struct-prop.scrbl"]

@; ------------------------------------------------------------------------

@section[#:tag "attaching-contracts-to-values"]{Attaching Contracts to Values}
@declare-exporting-ctc[racket/contract/base]

@deftogether[(@defform[
 #:literals (struct rename)
 (contract-in module-path in-out-item ...)]
              @defform[
 #:literals (struct rename)
 (contract-out unprotected-submodule in-out-item ...)
 #:grammar
 ([in-out-item
   [id contract-expr]
   (rename internal-id external-id contract-expr)
   (struct id/ignored ([id contract-expr] ...)
     struct-option)
   (code:line #:∃ poly-variables)
   (code:line #:exists poly-variables)
   (code:line #:∀ poly-variables)
   (code:line #:forall poly-variables)]
  [unprotected-submodule
   (code:line)
   (code:line #:unprotected-submodule submodule-name)]
  [poly-variables id (id ...)]
  [id/ignored id
   (id ignored-id)]
  [struct-option (code:line)
   #:omit-constructor])])]{

 在 @racket[require] 中使用 @racket[contract-in]，
 在 @racket[provide] 中使用 @racket[contract-out]
 （目前仅限于与 @racket[provide] 形式相同的 @tech{阶段级别}；
 例如，@racket[contract-out] 不能嵌套在 @racket[for-syntax] 中）。
 @racket[contract-out] 中的每个标识符从封闭模块提供，
 @racket[contract-in] 中的每个标识符从命名模块引入。
 此外，标识符的使用必须满足由 @racket[contract-expr]
 为每个导出指定的契约。

 @racket[contract-out] 和 @racket[contract-in] 形式
 将模块视为责任单元。提供每个标识符的模块需要满足契约的
 正（协变）位置。每个导入所提供变量的模块必须遵守契约的
 负（逆变）位置。只有提供它们的模块外部的受约束变量的使用
 才会被检查。在提供模块内部，不进行契约检查。

 在 @racket[contract-out] 形式中，每个 @racket[contract-expr]
 实际上被移动到封闭模块的末尾，
 因此 @racket[contract-expr] 可以引用在同一模块中稍后定义的变量。

 @racket[rename] 形式导出第一个变量（内部名称），
 使用第二个变量指定的名称（外部名称）。

 @racket[struct] 形式为结构体类型定义 @racket[id] 提供契约，
 每个字段有一个规定字段内容的契约。
 然而，与 @racket[struct] 定义不同，
 所有字段（及其契约）必须列出。
 子结构体与其父结构体共享的字段的契约
 仅用于子结构体构造函数的契约中，
 父结构体的选择器或修改器不会被提供。
 导出的结构体类型名称始终充当构造函数，
 即使原始结构体类型名称不作为构造函数。
 如果存在 @racket[#:omit-constructor] 选项，则构造函数不被提供。
 @racket[id/ignored] 的第二种形式（同时具有 @racket[id] 和 @racket[ignored-id]）
 已弃用，仅在语法中允许用于向后兼容，
 其中 @racket[ignored-id] 被忽略。应使用第一种形式。

注意，如果结构体是用 @racket[serializable-struct]
或 @racket[define-serializable-struct] 创建的，
@racket[contract-out] 不保护通过 @racket[deserialize] 创建的结构体实例。
请考虑使用 @racket[struct-guard/c] 代替。

@racket[#:∃]、@racket[#:exists]、@racket[#:∀] 和 @racket[#:forall]
子句定义新的抽象契约。变量在 @racket[contract-out] 形式的剩余部分中
绑定到新的契约，这些契约隐藏它们接受的值，
并确保导出的函数被参数化地处理。
有关子句如何隐藏值的详细信息，请参见 @racket[new-∃/c] 和 @racket[new-∀/c]。

如果出现了 @racket[#:unprotected-submodule]，
其后的标识符用作 @racket[contract-out] 生成的子模块的名称。
该子模块导出 @racket[contract-out] 中的所有名称，但没有契约。
特别地，每个 @racket[struct] 形式导出原始结构体类型名称，
这意味着 @racket[#:omit-constructor] 只省略额外的构造函数（如果有的话）。

@racket[contract-out] 的实现使用 @racket[syntax-property]
将属性附加到其生成的代码上，
记录完全展开的程序中契约的语法。
具体来说，符号 @indexed-racket['provide/contract-original-contract]
绑定到两个元素的向量，即导出的标识符
和生成控制导出的契约的表达式的语法对象。

@examples[#:eval (contract-eval) #:once
          (module math-example racket/base
            (require racket/contract)
            (code:comment "Compute the reciprocal of a real number")
            (define (recip x) (/ 1 x))
            (provide
             (contract-out
              [recip (-> (and/c real? (not/c zero?)) real?)])))

          (require 'math-example)
          (recip 3)
          (eval:error (recip 1+2i))]

@history[#:changed "7.3.0.3" @list{Added @racket[#:unprotected-submodule].}
         #:changed "7.7.0.9" @list{Started ignoring @racket[ignored-id].}
         #:changed "8.12.0.13" @list{Added @racket[contract-in]}
         #:changed "8.13.0.1" @list{Added @racket[rename] and @racket[struct] to @racket[contract-in]}]
}

@defform[(recontract-out id ...)]{
   一个在 @racket[provide] 中使用的 @racket[_provide-spec]
   （目前，与 @racket[contract-out] 一样，仅限于
   与 @racket[provide] 形式相同的 @tech{阶段级别}）。

   它重新导出 @racket[id]，但正 blame 关联到
   包含 @racket[recontract-out] 的模块，
   而不是 @racket[id] 的原始位置。

   这在公共模块想要从私有模块导出标识符但任何契约违规
   应以公共模块而非私有模块的名义报告时很有用。

   @examples[#:eval (contract-eval) #:once
             (module private-implementation racket/base
               (require racket/contract)
               (define (recip x) (/ 1 x))
               (define (non-zero? x) (not (= x 0)))
               (provide/contract [recip (-> (and/c real? non-zero?)
                                            (between/c -1 1))]))
             (module public racket/base
               (require racket/contract
                        'private-implementation)
               (provide (recontract-out recip)))

             (require 'public)
             (eval:error (recip +nan.0))]

   将 @racket[recontract-out] 的使用替换为
   仅 @racket[recip] 将导致契约违规指责私有模块。
}

@defform[(provide/contract unprotected-submodule in-out-item ...)]{

@racket[(provide (contract-out unprotected-submodule in-out-item ...))] 的遗留简写，
不同之处在于 @racket[provide/contract] 中的 @racket[_contract-expr]
在 @racket[provide/contract] 形式的位置求值，
而不是在封闭模块的末尾。}

@defform[(struct-guard/c contract-expr ...)]{
  返回一个适合作为 @racket[#:guard] 参数传递给
  @racket[struct]、@racket[serializable-struct]（及相关形式）的过程。
  该 guard 过程确保每个契约保护相应的字段值，
  只要结构体未被修改。修改不受保护。

 @examples[#:eval (contract-eval) #:once
           (struct snake (weight hungry?)
             #:guard (struct-guard/c real? boolean?))
           (eval:error (snake 1.5 "yep"))]
}

@subsection{Nested Contract Boundaries}
@defmodule*/no-declare[(racket/contract/region)]
@declare-exporting-ctc[racket/contract/region]

@defform*/subs[
 [(with-contract blame-id (wc-export ...) free-var-list ... body ...+)
  (with-contract blame-id results-spec free-var-list ... body ...+)]
 ([wc-export
   (id contract-expr)]
  [result-spec
   (code:line #:result contract-expr)
   (code:line #:results (contract-expr ...))]
  [free-var-list
   (code:line)
   (code:line #:freevar id contract-expr)
   (code:line #:freevars ([id contract-expr] ...))])]{
生成一个局部契约边界。

第一种 @racket[with-contract] 形式不能出现在表达式位置。
在第一种 @racket[with-contract] 形式中定义的所有名称在外部可见，
但在 @racket[wc-export] 列表中列出的那些名称
受相应契约的保护。
该形式的 @racket[body] 允许定义/表达式交错（如果其上下文允许）。

第二种 @racket[with-contract] 形式必须出现在表达式位置。
最终的 @racket[body] 表达式应返回与 @racket[result-spec] 中列出的
契约数量相同的值，每个返回值受其相应契约约束。
@racket[body] 形式的序列按 @racket[let] 的方式处理。

@racket[blame-id] 用于与导出 @racket[id] 配对的契约的正位置。
在 @racket[with-contract] @racket[body] 中违反的契约
将使用 @racket[blame-id] 作为其负位置。

如果给出了 @racket[free-var-list]，
则 @racket[body] 中自由变量的任何使用
都将受到契约的保护，这些契约将 @racket[with-contract] 形式的上下文
归咎于正位置，将 @racket[with-contract] 形式归咎于负位置。}

@(define furlongs->feet-eval (contract-eval))
@defform*[[(define/contract id contract-expr free-var-list init-value-expr)
 (define/contract (head args) contract-expr free-var-list body ...+)]]{
类似于 @racket[define]，但契约 @racket[contract-expr]
附加到绑定的值上。关于 @racket[head] 和 @racket[args] 的定义，
参见 @racket[define]。
关于 @racket[free-var-list] 的定义，参见 @racket[with-contract]。

@examples[#:eval furlongs->feet-eval
  (define/contract distance (>=/c 0) 43.52)
  (define/contract (furlongs->feet fr)
    (-> real? real?)
    (* 660 fr))
  (code:comment "a contract violation expected here:")
  (eval:error (furlongs->feet "not a furlong"))
]

@racket[define/contract] 形式将单个定义视为契约区域。
定义本身负责契约的正（协变）位置，
定义外对 @racket[id] 的引用必须满足契约的负位置。
由于契约边界位于定义和周围上下文之间，
@racket[define/contract] 形式内部的 @racket[id] 引用不会被检查。

@examples[#:eval (contract-eval) #:once
  (code:comment "an unsual predicate that prints when called")
  (define (printing-int? x)
    (displayln "I was called")
    (exact-integer? x))
  (define/contract (fact n)
    (-> printing-int? printing-int?)
    (if (zero? n)
        1
        (* n (fact (sub1 n)))))
  (code:line (fact 5) (code:comment "only prints twice, not for each recursive call"))
]

如果给出了 free-var-list，则 @racket[body] 中自由变量的任何使用
都将受到契约的保护，这些契约将
@racket[define/contract] 形式的上下文归咎于正位置，
将 @racket[define/contract] 形式归咎于负位置。

@examples[#:eval (contract-eval) #:once
  (define (integer->binary-string n)
    (number->string n 2))
  (define/contract (numbers->strings lst)
    (-> (listof number?) (listof string?))
    #:freevar integer->binary-string (-> exact-integer? string?)
    (code:comment "mistake, lst might contain inexact numbers")
    (map integer->binary-string lst))
  (eval:error (numbers->strings '(4.0 3.3 5.8)))
]}

@defform*[[(struct/contract struct-id ([field contract-expr] ...)
                                   struct-option ...)
           (struct/contract struct-id super-struct-id
                                   ([field contract-expr] ...)
                                   struct-option ...)]]{
类似于 @racket[struct]，但构造函数的参数、
访问器和修改器受契约保护。
关于 @racket[field] 和 @racket[struct-option] 的定义，参见 @racket[struct]。

@racket[struct/contract] 形式只允许 @racket[struct-option] 关键字的子集：
@racket[#:mutable]、@racket[#:transparent]、
@racket[#:auto-value]、@racket[#:omit-define-syntaxes] 和 @racket[#:property]。

@examples[#:eval (contract-eval) #:once
(struct/contract fruit ([seeds number?]))
(fruit 60)
(eval:error (fruit #f))

(struct/contract apple fruit ([type string?]))
(apple 14 "golden delicious")
(eval:error (apple 5 30))
(eval:error (apple #f "granny smith"))
]}

@defform*[[(define-struct/contract struct-id ([field contract-expr] ...)
                                   struct-option ...)
           (define-struct/contract (struct-id super-struct-id)
                                   ([field contract-expr] ...)
                                   struct-option ...)]]{
类似于 @racket[struct/contract]，但提供 @racket[super-struct-id] 的语法不同，
并且隐式提供了一个带有 @racketidfont{make-} 前缀的 @racket[_constructor-id]。
关于 @racket[field] 和 @racket[struct-option] 的定义，参见 @racket[define-struct]。
与 @racket[struct] 对比 @racket[define-struct] 一样，
通常优先使用 @racket[struct/contract] 而非 @racket[define-struct/contract]。

@racket[define-struct/contract] 形式只允许 @racket[struct-option] 关键字的子集：
@racket[#:mutable]、@racket[#:transparent]、
@racket[#:auto-value]、@racket[#:omit-define-syntaxes] 和 @racket[#:property]。

@examples[#:eval (contract-eval) #:once
(define-struct/contract fish ([color number?]))
(make-fish 5)
(eval:error (make-fish #f))

(define-struct/contract (salmon fish) ([ocean symbol?]))
(make-salmon 5 'atlantic)
(eval:error (make-salmon 5 #f))
(eval:error (make-salmon #f 'pacific))
]}

@defform[(invariant-assertion invariant-expr expr)]{
  建立一个由 @racket[invariant-expr] 确定的 @racket[expr] 的不变式。

  与契约的规范不同，@racket[invariant-assertion]
  不在两方之间建立边界。相反，它简单地将一个逻辑断言附加到值上。
  由于该形式使用契约机制来检查断言，
  包围模块被视为对断言的任何违规负责的一方。

  这意味着，例如，当不变式用于定义的右侧时，
  在递归调用中也会检查断言：

  @examples[#:eval
            furlongs->feet-eval
            (define furlongss->feets
              (invariant-assertion
               (-> (listof real?) (listof real?))
               (λ (l)
                 (cond
                   [(empty? l) empty]
                   [else
                    (if (= 327 (car l))
                        (furlongss->feets (list "wha?"))
                        (cons (furlongs->feet (first l))
                              (furlongss->feets (rest l))))]))))

            (furlongss->feets (list 1 2 3))

            (eval:error (furlongss->feets (list 1 327 3)))]

  @history[#:added "6.0.1.11"]

}

@defidform[current-contract-region]{
  由 @racket[define-syntax-parameter] 绑定，包含有关
  当前契约区域的信息，上述形式使用它来确定
  blame 分配的候选项。
}

@subsection{Low-level Contract Boundaries}
@declare-exporting-ctc[racket/contract/base]

@defform[(define-module-boundary-contract id
           orig-id
           contract-expr
           d-m-b-c-kwd-arg ...)
         #:grammar ([d-m-b-c-kwd-arg
                     (code:line #:name-for-contract name-for-contract-id)
                     (code:line #:name-for-blame blame-id)
                     (code:line #:srcloc srcloc-expr)
                     (code:line #:pos-source pos-source-expr)
                     (code:line #:context-limit limit-expr)
                     (code:line #:lift-to-end? boolean)
                     (code:line #:start-swapped? boolean)])]{
  将 @racket[id] 定义为 @racket[orig-id]，但带有契约 @racket[contract-expr]。

  标识符 @racket[id] 被定义为一个宏转换器，
  它查询其使用上下文以确定负 blame 分配的名称
  （将引用出现的整个模块作为负方）。

  错误消息中使用的名称将是 @racket[orig-id]，
  除非提供了 @racket[#:name-for-blame]，
  在这种情况下，其后的标识符用作错误消息中的名称。

  契约表达式被包装在 @racket[let] 中以赋予其名称，
  该名称将在某些情况下传递给包装值的名称
  （例如，如果契约是函数契约）。
  如果提供了 @racket[name-for-contract-id]，
  其后的标识符用于命名契约；否则使用 @racket[orig-id]。

  用于 blame 错误消息中契约附加位置源位置的默认值是
  @racket[define-module-boundary-contract] 使用的源位置，
  但可以通过 @racket[#:srcloc] 参数指定，
  在这种情况下它可以是 @racket[datum->syntax] 的第三个参数
  可以接受的任何内容。

  正方默认为包含 @racket[define-module-boundary-contract] 使用的模块，
  但可以通过 @racket[#:pos-source] 关键字显式指定。

  如果提供了 @racket[#:context-limit]，其行为与
  提供给 @racket[contract] 时的行为相同。

  如果 @racket[lift-to-end?] 是 @racket[#t] 或未提供，
  则契约表达式放置在封闭模块的末尾
  （使用 @racket[syntax-local-lift-module-end-declaration]）。
  如果提供且为 @racket[#f]，
  则契约表达式放置在 @racket[define-module-boundary-contract] 的位置。

  如果 @racket[start-swapped?] 为 @racket[#t]，
  则初始 blame 对象以 ``已交换'' 状态创建，
  @racket[pos-source] 用作负源。
  这有助于在某些情况下使契约违规中的 ``contract from:'' 行正确。
  如果未提供 @racket[#:start-swapped?]，
  则按提供为 @racket[#f] 处理。

  @examples[#:eval (contract-eval) #:once
            (module server racket/base
              (require racket/contract/base)
              (define (f x) #f)
              (define-module-boundary-contract g f (-> integer? integer?))
              (provide g))
            (module client racket/base
              (require 'server)
              (define (clients-fault) (g #f))
              (define (servers-fault) (g 1))
              (provide servers-fault clients-fault))
            (require 'client)
            (eval:error (clients-fault))
            (eval:error (servers-fault))]

  @history[#:changed "6.7.0.4" @elem{Added the @racket[#:name-for-blame] argument.}
           #:changed "6.90.0.29" @elem{Added the @racket[#:context-limit] argument.}
           #:changed "8.13.0.1" @elem{Added the @racket[#:name-for-contract] and @racket[#:start-swapped] arguments.}]

}

@defform*[[(contract contract-expr to-protect-expr
                     positive-blame-expr negative-blame-expr)
           (contract contract-expr to-protect-expr
                     positive-blame-expr negative-blame-expr
                     #:context-limit limit-expr)
           (contract contract-expr to-protect-expr
                     positive-blame-expr negative-blame-expr
                     value-name-expr source-location-expr)]]{

将契约附加到值上的原始机制。
@racket[contract] 的目的是作为某些高级契约指定形式展开的目标。

@racket[contract] 表达式将由 @racket[contract-expr] 指定的契约
添加到由 @racket[to-protect-expr] 产生的值上。
@racket[contract] 表达式的结果是 @racket[to-protect-expr] 表达式的结果，
但 @racket[contract-expr] 指定的契约在 @racket[to-protect-expr] 上强制执行。

@racket[positive-blame-expr] 和 @racket[negative-blame-expr] 的值
指示如何为 @racket[contract-expr] 指定的契约
的正位置和负位置分配 blame。它们可以是任何值，
并按照 @racket[display] 的方式格式化以用于契约违规错误消息。

如果指定，@racket[value-name-expr] 指示要在错误消息中使用的
受保护值的名称。如果未提供，或如果 @racket[value-name-expr]
产生 @racket[#f]，则不打印名称。否则，它也按 @racket[display] 格式化。
更准确地说，@racket[value-name-expr] 最终出现在 blame 记录的
@racket[blame-value] 字段中，该字段用作错误消息的第一部分。
@examples[#:eval (contract-eval) #:once
          (eval:error (contract integer? #f 'pos 'neg 'timothy #f))
          (eval:error (contract integer? #f 'pos 'neg #f #f))]

如果指定，@racket[source-location-expr] 指示契约违规
报告的源位置。表达式必须产生 @racket[srcloc] 结构体、
@tech{语法对象}、@racket[#f] 或
@racket[datum->syntax] 的第三个参数接受的格式的列表或向量。

 如果提供了 @racket[#:context-limit]，其后的表达式
 必须求值为 @racket[#f] 或自然数。
 如果表达式求值为自然数，
 上下文信息的层数最多限制为该数量。
 例如，如果数字是 @racket[0]，则不记录上下文信息，
 错误消息中不包含以 @litchar{in:} 开头的部分。

}

@; ------------------------------------------------------------------------

@section{Building New Contract Combinators}

@defmodule*/no-declare[(racket/contract/combinator)]
@declare-exporting-ctc[racket/contract/combinator]


@deftogether[(
@defproc[(make-contract
          [#:name name any/c 'anonymous-contract]
          [#:first-order first-order (-> any/c any/c) (λ (x) #t)]
          [#:late-neg-projection
           late-neg-proj
           (or/c #f (-> blame? (-> any/c any/c any/c)))
           #f]
          [#:collapsible-late-neg-projection
           collapsible-late-neg-proj
           (or/c #f (-> blame? (values (-> any/c any/c any/c) collapsible-contract?)))
           #f]
          [#:val-first-projection
           val-first-proj
           (or/c #f (-> blame? (-> any/c (-> any/c any/c))))
           #f]
          [#:projection proj (-> blame? (-> any/c any/c))
           (λ (b)
             (λ (x)
               (if (first-order x)
                 x
                 (raise-blame-error
                  b x
                  '(expected: "~a" given: "~e")
                  name x))))]
          [#:stronger stronger
                      (or/c #f (-> contract? contract? boolean?))
                      #f]
          [#:equivalent equivalent
           (or/c #f (-> contract? contract? boolean?))
           #f]
          [#:list-contract? is-list-contract? boolean? #f])
         contract?]
@defproc[(make-chaperone-contract
          [#:name name any/c 'anonymous-chaperone-contract]
          [#:first-order first-order (-> any/c any/c) (λ (x) #t)]
          [#:late-neg-projection
           late-neg-proj
           (or/c #f (-> blame? (-> any/c any/c any/c)))
           #f]
          [#:collapsible-late-neg-projection
           collapsible-late-neg-proj
           (or/c #f (-> blame? (values (-> any/c any/c any/c) collapsible-contract?)))
           #f]
          [#:val-first-projection
           val-first-proj
           (or/c #f (-> blame? (-> any/c (-> any/c any/c))))
           #f]
          [#:projection proj (-> blame? (-> any/c any/c))
           (λ (b)
             (λ (x)
               (if (first-order x)
                 x
                 (raise-blame-error
                  b x
                  '(expected: "~a" given: "~e")
                  name x))))]
          [#:stronger stronger
                      (or/c #f (-> contract? contract? boolean?))
                      #f]
          [#:equivalent equivalent
           (or/c #f (-> contract? contract? boolean?))
           #f]
          [#:list-contract? is-list-contract? boolean? #f])
         chaperone-contract?]
@defproc[(make-flat-contract
          [#:name name any/c 'anonymous-flat-contract]
          [#:first-order first-order (-> any/c any/c) (λ (x) #t)]
          [#:late-neg-projection
           late-neg-proj
           (or/c #f (-> blame? (-> any/c any/c any/c)))
           #f]
          [#:collapsible-late-neg-projection
           collapsible-late-neg-proj
           (or/c #f (-> blame? (values (-> any/c any/c any/c) collapsible-contract?)))
           #f]
          [#:val-first-projection
           val-first-proj
           (or/c #f (-> blame? (-> any/c (-> any/c any/c))))
           #f]
          [#:projection proj (-> blame? (-> any/c any/c))
           (λ (b)
             (λ (x)
               (if (first-order x)
                 x
                 (raise-blame-error
                  b x
                  '(expected: "~a" given: "~e")
                  name x))))]
          [#:stronger stronger
                      (or/c #f (-> contract? contract? boolean?))
                      #f]
          [#:equivalent equivalent
           (or/c #f (-> contract? contract? boolean?))
           #f]
          [#:list-contract? is-list-contract? boolean? #f])
         flat-contract?]
)]{

这些函数分别构建简单的高阶契约、@tech{chaperone contracts}
和 @tech{flat contracts}。它们都接受相同的三个可选参数：
名称、一阶谓词和 blame 跟踪投影。
对于 @racket[make-flat-contract]，另请参见 @racket[flat-contract-with-explanation]。

@racket[name] 参数是任何值，使用 @racket[display] 渲染以描述
违规发生时的契约。简单高阶契约的默认名称是
@racketresult[anonymous-contract]，
@tech{chaperone contracts} 的是 @racketresult[anonymous-chaperone-contract]，
@tech{flat contracts} 的是 @racketresult[anonymous-flat-contract]。

一阶谓词 @racket[first-order] 用于确定契约适用于哪些值。
此测试由 @racket[contract-first-order-passes?] 使用，
并间接由 @racket[or/c] 和 @racket[first-or/c] 使用，
以在存在多个高阶契约可供选择时
确定用哪个高阶契约包装值。
默认值接受任何值，但必须匹配投影参数的行为
（如何操作见下文）。谓词应受
@racket[(contract-first-order-okay-to-give-up?)] 的值影响
（更多解释见其文档）。

@racket[late-neg-proj] 参数定义通过 @deftech{late neg projection}
 应用契约的行为。如果提供，此参数接受一个缺少一方的
 @tech{blame 对象}（另请参见 @racket[blame-missing-party?]）。
 然后它必须返回一个函数，该函数按顺序接受
 获得契约的值和缺失 blame 方的名称。
 结果必须要么是值（可能适当地用 @tech{chaperone}
 或 @tech{impersonator} 包装以强制执行契约），
 要么使用 @racket[raise-blame-error] 发出契约违规信号。
 默认值为 @racket[#f]。

 @racket[collapsible-late-neg-proj] 参数取代支持折叠的契约的
 @racket[late-neg-proj] 参数。如果提供，此参数接受一个缺少一方的
 @tech{blame 对象}。它必须返回两个值。
 第一个值必须是一个函数，按顺序接受
 获得契约的值和缺失 blame 方的名称。
 第二个值应该是契约的 @tech[#:key "collapsible contract"]{可折叠}表示。

投影 @racket[proj] 和 @racket[val-first-proj] 是定义
 应用契约行为的较旧机制。@racket[proj] 参数
是一个二元柯里化函数：第一次应用接受 blame 对象，
第二次接受要用契约保护的值。
投影必须要么产生值（适当地包装以强制执行契约的任何高阶方面），
要么使用 @racket[raise-blame-error] 发出契约违规信号。
默认投影在一阶测试失败时产生错误，
否则产生不变的值。
@racket[val-first-proj] 类似于 @racket[late-neg-proj]，
但多了一层柯里化。

@racket[late-neg-proj]、@racket[proj]、
 @racket[val-first-proj] 或 @racket[first-order] 中至少有一个必须非 @racket[#f]。

投影参数（@racket[late-neg-proj]、@racket[proj] 和
 @racket[val-first-proj]）必须与 @racket[first-order] 参数同步。
 特别地，如果 @racket[first-order] 参数对某个值返回 @racket[#f]，
 则投影必须为该值引发 blame 错误；
 如果 @racket[first-order] 参数对某个值返回 @racket[#t]，
 则投影不得为此值发出任何 blame，
 除非后续有高阶交互。
 换句话说，对于 @tech{flat contracts}，
 @racket[first-order] 和 @racket[projection] 参数必须检查相同的谓词。
 为了方便，默认投影使用 @racket[first-order] 参数，
 在它返回 @racket[#f] 时发出错误信号，否则从不发出。

@tech{chaperone contracts} 的投影必须产生一个与原始未约束值
比较时通过 @racket[chaperone-of?] 的值。
@tech{flat contracts} 的投影必须在 @racket[first-order] 失败时精确失败，
否则必须不变地产生输入值。
应用 @tech{flat contract} 可能导致应用谓词或投影，或两者都有；
因此，两者必须一致。
单独投影的存在仅用于提供更具体的错误消息。
大多数 @tech{flat contracts} 不需要提供显式投影。

@racket[stronger] 参数用于实现 @racket[contract-stronger?]。
第一个参数始终是契约本身，
第二个参数是传递给 @racket[contract-stronger?] 的第二个参数。
如果未提供 @racket[stronger] 参数，
则对 @tech{flat contracts} 和 @tech{chaperone contracts}
使用通过 @racket[equal?] 比较参数的默认值。
对于使用 @racket[make-contract] 构造的未提供 @racket[stronger] 参数的
@tech{impersonator contracts}，
@racket[contract-stronger?] 返回 @racket[#f]。

类似地，@racket[equivalent] 参数用于实现 @racket[contract-equivalent?]。
如果未提供或提供 @racket[#false]，则对 chaperone 和 flat contracts
使用 @racket[equal?]，否则使用 @racket[(λ (x y) #f)]。

@racket[is-list-contract?] 参数由 @racket[list-contract?] 谓词使用
以确定这是否是一个只接受 @racket[list?] 值的契约。

@examples[#:eval (contract-eval) #:once
(define int/c
  (make-flat-contract #:name 'int/c #:first-order integer?))
(contract int/c 1 'positive 'negative)
(eval:error (contract int/c "not one" 'positive 'negative))
(int/c 1)
(int/c "not one")
(define int->int/c
  (make-contract
   #:name 'int->int/c
   #:first-order
   (λ (x) (and (procedure? x) (procedure-arity-includes? x 1)))
   #:projection
   (λ (b)
     (let ([domain ((contract-projection int/c) (blame-swap b))]
           [range ((contract-projection int/c) b)])
       (λ (f)
         (if (and (procedure? f) (procedure-arity-includes? f 1))
           (λ (x) (range (f (domain x))))
           (raise-blame-error
            b f
            '(expected "a function of one argument" given: "~e")
            f)))))))
(eval:error (contract int->int/c "not fun" 'positive 'negative))
(define halve
  (contract int->int/c (λ (x) (/ x 2)) 'positive 'negative))
(halve 2)
(eval:error (halve 1/2))
(eval:error (halve 1))
]

@history[#:changed "6.0.1.13" @list{Added the @racket[#:list-contract?] argument.}
         #:changed "6.90.0.30" @list{Added the @racket[#:equivalent] argument.}
         #:changed "7.1.0.10" @list{Added the @racket[#:collapsible-late-neg-projection] argument.}]
}

@defproc[(build-compound-type-name [c/s any/c] ...) any]{

生成一个用作契约名称的 S-表达式。
参数应该是契约或符号。
它在其参数周围包裹括号，
并从提供的任何契约中提取名称。}

@defproc[(coerce-contract [id symbol?] [v any/c]) contract?]{

将普通 Racket 值转换为 contract 结构体的实例，
根据 @tech{契约} 的描述进行转换。

如果 @racket[v] 不是可强制转换的值之一，
@racket[coerce-contract] 发出错误信号，
在错误消息中使用第一个参数。}

@defproc[(coerce-contracts [id symbol?] [vs (listof any/c)]) (listof contract?)]{

将 @racket[vs] 中的所有参数强制转换为契约
（通过 @racket[coerce-contract/f]），
如果其中任何一个不是契约则发出错误信号。
错误消息假定由 @racket[id] 命名的函数将 @racket[vs]
作为其完整参数列表。
}

@defproc[(coerce-chaperone-contract [id symbol?] [v any/c]) chaperone-contract?]{
  类似于 @racket[coerce-contract]，但要求结果
  是 @tech{chaperone contract}，而不是任意契约。
}

@defproc[(coerce-chaperone-contracts [id symbol?] [vs (listof any/c)])
         (listof chaperone-contract?)]{
  类似于 @racket[coerce-contracts]，但要求结果
  是 @tech{chaperone contracts}，而不是任意契约。
}

@defproc[(coerce-flat-contract [id symbol?] [v any/c]) flat-contract?]{
  类似于 @racket[coerce-contract]，但要求结果
  是 @tech{flat contract}，而不是任意契约。
}

@defproc[(coerce-flat-contracts [id symbol?] [v (listof any/c)]) (listof flat-contract?)]{
  类似于 @racket[coerce-contracts]，但要求结果
  是 @tech{flat contracts}，而不是任意契约。
}

@defproc[(coerce-contract/f [v any/c]) (or/c contract? #f)]{
  类似于 @racket[coerce-contract]，但如果值无法
  强制转换为契约，则返回 @racket[#f]。
}

@defparam[skip-projection-wrapper? wrap? boolean? #:value #f]{
 函数 @racket[make-chaperone-contract] 和
 @racket[build-chaperone-contract-property] 包装其参数
 以确保投影的结果是输入的 chaperones。
 这种包装层在某些情况下可能会引入不必要的
 契约检查开销。如果在调用这两个函数之一的
 动态范围内此参数的值为 @racket[#t]，
 则包装（以及因此的检查）会被跳过。
}

@defform*[[(with-contract-continuation-mark blame body ...)
          (with-contract-continuation-mark blame+neg-party body ...)]]{
插入一个 continuation mark，通知契约分析器（参见
@other-doc['(lib "contract-profile/scribblings/contract-profile.scrbl")
           #:indirect "contract profiling"]）
正在进行契约检查。
要包含检查新组合子的成本，应使用此形式包装
任何延迟的高阶检查。
一阶检查自动识别，不需要此形式。

如果组合子的投影操作于完整的 @tech{blame 对象}
（即没有缺失的 blame 方），
@tech{blame 对象}应该是此形式的第一个参数。
否则（例如，在 @racket[_late-neg] 投影的情况下），
应使用 @tech{blame 对象}和缺失方的一对。

@history[#:added "6.4.0.4"]
}

@defform[(contract-pos/neg-doubling e1 e2)]{

 一些契约组合子需要为其子契约构建投影，
 同时使用常规和 @racket[blame-swap] 版本的 blame，
 以便检查访问和修改（例如 @racket[vector/c] 和 @racket[vectorof]）。
 在这种组合子彼此深度嵌套的情况下，
 可能会发生嵌套投影的指数爆炸。

 为避免这种爆炸，将对组合子中接受 blame 部分的每次调用
 包装在 @racket[contract-pos/neg-doubling] 中。
 它返回三个值。第一个是布尔值，指示如何解释其他两个结果。
 如果布尔值是 @racket[#t]，则其他两个结果是 @racket[e1] 和
 @racket[e2] 的值，我们还没有嵌套得太深。
 如果布尔值是 @racket[#f]，则我们已经超过了阈值，
 此时求值 @racket[e1] 和 @racket[e2] 还不安全，
 因为我们有遇到指数级减速的危险。
 在这种情况下，最后两个结果是 thunk，
 在调用时计算 @racket[e1] 和 @racket[e2] 的值。

 例如，@racket[vectorof] 使用 @racket[contract-pos/neg-doubling]
 包装对其子契约的投影的接受 blame 部分的两次调用。
 当它接收到第一个布尔值为 @racket[#f] 时，
 它不会立即调用 thunk，而是等待直到附加到
 chaperoned 向量的插入过程被调用。
 然后它调用它们（并缓存结果）。
 这将投影的构造延迟到实际需要时，避免了指数爆炸。

 @history[#:added "6.90.0.27"]
}

@subsection{Blame Objects}

本节描述了 @deftech{blame 对象}及其操作。

@defproc[(blame? [v any/c]) boolean?]{
 此谓词识别 @|blame-objects|。
}

@defproc[(raise-blame-error [b blame?]
                            [#:missing-party missing-party #f]
                            [v any/c]
                            [fmt (or/c string?
                                       (listof (or/c string?
                                                     'given 'given:
                                                     'expected 'expected:)))]
                            [v-fmt any/c] ...)
         none/c]{

发出契约违规信号。第一个参数 @racket[b] 记录当前 blame 信息，
包括正负方、契约名称、值的名称和契约应用的源位置。
@racket[#:missing-party] 参数提供 blame 方之一。
当 @racket[b] 对象在创建时未提供负方时，它应是非 @racket[#f] 的。
参见 @racket[blame-add-missing-party] 和 @racket[make-contract] 的
@racket[_late-neg-proj] 参数的描述。

第二个位置参数 @racket[v] 是未能满足契约的值。

其余参数是一个格式字符串 @racket[fmt] 及其参数 @racket[v-fmt ...]，
指定针对具体违规的错误消息。

如果 @racket[fmt] 是一个列表，则元素在连接之前先替换符号：
要么替换为对应的字符串，
要么将 @racket['given] 替换为 @racket["produced"]，
将 @racket['expected] 替换为 @racket["promised"]，
取决于 @racket[b] 参数是否已被交换（参见 @racket[blame-swap]）。
（会添加空格，除非字符串末尾已有空格）。

如果 @racket[fmt] 包含符号 @racket['given:] 或 @racket['expected:]，
它们的替换方式与 @racket['given] 和 @racket['expected] 相同，
但替换项以字符串 @racket["\n  "] 为前缀，
以符合 @secref["err-msg-conventions"] 中的错误消息指南。

}

@defproc[(blame-add-context [blame blame?]
                            [context (or/c string? #f)]
                            [#:important important (or/c string? #f) #f]
                            [#:swap? swap? boolean? #f])
         blame?]{
  向 blame 错误消息添加一些上下文信息，
  说明契约的哪个部分失败
  （并由 @racket[raise-blame-error] 渲染）。

  @racket[context] 参数描述契约部分的一层，
  通常形式为 @racket["the 1st argument of"]
  （在函数契约的情况下）
  或 @racket["a conjunct of"]（在 @racket[and/c] 契约的情况下）。

  例如，考虑此契约违规：
  @examples[#:label #f #:eval (contract-eval) #:once
(define/contract f
  (list/c (-> integer? integer?))
  (list (λ (x) x)))

(eval:error ((car f) #f))
]
它显示被违反的契约部分
是 @racket[integer?] 的第一次出现，因为 @racket[->] 和
@racket[list/c] 组合子各自在内部调用了
@racket[blame-add-context] 来添加错误消息中
``in'' 后面的两行。

@racket[important] 参数用于构建契约违规的开头部分。
添加到 @|blame-object| 的最后一个 @racket[important] 参数被使用。
@racket[class/c] 契约添加 important 参数，
@racket[->] 契约也是如此（当 @racket[->] 知道获得契约的函数的名称时）。

@racket[swap?] 参数的效果是在添加上下文层的同时
调用 @racket[blame-swap]，但不会创建额外的 @|blame-object|。


传递 @racket[#f] 作为上下文字符串参数不再相关。
为了向后兼容，当 @racket[context] 是 @racket[#f] 时，
@racket[blame-add-context] 返回 @racket[b]。

@history[#:changed "6.90.0.29" @elem{The @racket[context] argument being
           @racket[#f] is no longer relevant.}]
}

@defproc[(blame-context [blame blame?]) (listof string?)]{
  返回如果 @racket[blame] 传递给 @racket[raise-blame-error]
  将在错误消息中提供的上下文信息。
}

@deftogether[(
@defproc[(blame-positive [b blame?]) any/c]
@defproc[(blame-negative [b blame?]) any/c]
)]{
这些函数产生 @|blame-object| 的当前正负方的可打印描述。
}

@defproc[(blame-contract [b blame?]) any/c]{
此函数产生与 blame 对象关联的契约的描述
（@racket[contract-name] 的结果）。
}

@defproc[(blame-value [b blame?]) any/c]{
此函数产生契约所应用的值的名称，
如果没有提供名称则返回 @racket[#f]。
}

@defproc[(blame-source [b blame?]) srcloc?]{
此函数产生与契约关联的源位置。
如果没有提供源位置，结构体的所有字段将包含 @racket[#f]。
}

@defproc[(blame-swap [b blame?]) blame?]{
此函数交换 @|blame-object| 的正负方。
（另请参见 @racket[blame-add-context]。）
}

@deftogether[(
@defproc[(blame-original? [b blame?]) boolean?]
@defproc[(blame-swapped? [b blame?]) boolean?]
)]{

这些函数报告给定 @|blame-object| 的当前 blame
是否与原始契约调用中的相同（可能是一个包含当前契约的复合契约），
或分别被交换。每个都是另一个的否定；
两者都提供以方便和清晰。

}

@defproc[(blame-replace-negative [b blame?] [neg any/c]) blame?]{
  生成一个类似 @racket[b] 的 @racket[blame?] 对象，
  但使用 @racket[neg] 代替 @racket[b] 的负位置。
}

@defproc[(blame-replaced-negative? [b blame?]) boolean?]{
 如果 @racket[b] 是调用 @racket[blame-replace-negative] 的结果
 （或其输入是 @racket[blame-replace-negative] 的结果的
 其他某个函数的结果），则返回 @racket[#t]。
}

@defproc[(blame-update [b blame?] [pos any/c] [neg any/c]) blame?]{
  生成一个类似 @racket[b] 的 @racket[blame?] 对象，
  但分别将 @racket[pos] 和 @racket[neg] 添加到
  @racket[b] 的正方和负方。
}

@defproc[(blame-missing-party? [b blame?]) boolean?]{
 当 @racket[b] 没有双方时返回 @racket[#t]。
}

@defproc[(blame-add-missing-party [b (and/c blame? blame-missing-party?)]
                                  [missing-party any/c])
         (and/c blame? (not/c blame-missing-party?))]{
 生成一个类似 @racket[b] 的新 @tech{blame 对象}，
 但缺失方被替换为 @racket[missing-party]。
}


@defstruct[(exn:fail:contract:blame exn:fail:contract) ([object blame?])]{
  此异常被引发以发出契约错误信号。@racket[object]
  字段包含与契约违规关联的 @|blame-object|。
}

@defparam[current-blame-format
          proc
          (-> blame? any/c string? string?)]{

一个 @tech{参数}，在构造契约违规错误时使用。
其值是一个接受三个参数的过程：
@itemize[
@item{违规的 @|blame-object|，}
@item{契约所应用的值，以及}
@item{指示违规类型的消息。}]
然后该过程返回一个字符串，该字符串被放入契约错误消息中。
注意，值通常已包含在指示违规的消息中。

@examples[#:eval (contract-eval) #:once
(define (show-blame-error blame value message)
  (string-append
   "Contract Violation!\n"
   (format "Guilty Party: ~a\n" (blame-positive blame))
   (format "Innocent Party: ~a\n" (blame-negative blame))
   (format "Contracted Value Name: ~a\n" (blame-value blame))
   (format "Contract Location: ~s\n" (blame-source blame))
   (format "Contract Name: ~a\n" (blame-contract blame))
   (format "Offending Value: ~s\n" value)
   (format "Offense: ~a\n" message)))
(current-blame-format show-blame-error)
(define/contract (f x)
  (-> integer? integer?)
  (/ x 2))
(f 2)
(eval:error (f 1))
(eval:error (f 1/2))
]

}

@subsection{Contracts as structs}

@para{
属性 @racket[prop:contract] 允许任意结构体充当契约。
属性 @racket[prop:chaperone-contract] 允许任意结构体充当
@tech{chaperone contracts}；@racket[prop:chaperone-contract]
继承 @racket[prop:contract]，因此 @tech{chaperone contract}
结构体也可以充当通用契约。
属性 @racket[prop:flat-contract] 允许任意结构体充当
@tech{flat contracts}；@racket[prop:flat-contract] 继承
@racket[prop:chaperone-contract] 和 @racket[prop:procedure]，
因此 @tech{flat contract} 结构体也可以充当
@tech{chaperone contracts}、通用契约和谓词过程。
}

@deftogether[(
@defthing[prop:contract struct-type-property?]
@defthing[prop:chaperone-contract struct-type-property?]
@defthing[prop:flat-contract struct-type-property?]
)]{
这些属性分别将结构体声明为契约或 @tech{flat contracts}。
@racket[prop:contract] 的值必须是由
@racket[build-contract-property] 构造的 @tech{contract property}；
同样，@racket[prop:chaperone-contract] 的值必须是由
@racket[build-chaperone-contract-property] 构造的
@tech{chaperone contract property}，
@racket[prop:flat-contract] 的值必须是由
@racket[build-flat-contract-property] 构造的
@tech{flat contract property}。
}

@deftogether[(
@defthing[prop:contracted struct-type-property?]
@defthing[impersonator-prop:contracted impersonator-property?]
)]{
这些属性将契约值附加到受保护的结构体、
chaperone 或 impersonator 值上。
对于具有这些属性之一的值，@racket[has-contract?] 返回 @racket[#t]，
@racket[value-contract] 从属性中提取值
（预期是该值上的契约）。
}

@deftogether[(
@defthing[prop:blame struct-type-property?]
@defthing[impersonator-prop:blame impersonator-property?]
)]{
这些属性将 blame 信息附加到受保护的结构体、
chaperone 或 impersonator 值上。
对于具有这些属性之一的值，@racket[has-blame?] 返回 @racket[#t]，
@racket[value-blame] 从属性中提取值。

该值预期是值上的契约的 blame 记录，
或者是带有缺失方的 blame 记录与缺失方的 @racket[cons]-pair。
@racket[value-blame] 函数使用 @racket[blame-add-missing-party]
将 pair 的参数重组为完整的 blame 记录。
如果值具有这些属性之一，但值不是 @tech{blame 对象}
或其 @racket[car] 位置不是 @tech{blame 对象}的 pair，
则 @racket[has-blame?] 返回 @racket[#f]，
但 @racket[value-blame] 返回 @racket[#f]。
}

@deftogether[(
@defproc[(build-flat-contract-property
          [#:name
           get-name
           (or/c #f (-> contract? any/c))
           (λ (c) 'anonymous-flat-contract)]
          [#:first-order
           get-first-order
           (-> contract? (-> any/c boolean?))
           (λ (c) (λ (x) #t))]
          [#:late-neg-projection
           late-neg-proj
           (or/c #f (-> contract? (-> blame? (-> any/c any/c any/c))))
           #f]
          [#:collapsible-late-neg-projection
           collapsible-late-neg-proj
           (or/c #f (-> contract? (-> blame? (values (-> any/c any/c any/c) collapsible-contract?))))
           #f]
          [#:val-first-projection
           val-first-proj
           (or/c #f (-> contract? blame? (-> any/c (-> any/c any/c))))
           #f]
          [#:projection
           get-projection
           (-> contract? (-> blame? (-> any/c any/c)))
           (λ (c)
             (λ (b)
               (λ (x)
                 (if ((get-first-order c) x)
                     x
                     (raise-blame-error
                      b x '(expected: "~a" given: "~e")
                      (get-name c) x)))))]
          [#:stronger
           stronger
           (or/c (-> contract? contract? boolean?) #f)
           #f]
          [#:equivalent equivalent
           (or/c #f (-> contract? contract? boolean?))
           #f]
          [#:generate
           generate
           (->i ([c contract?])
                [generator
                 (c)
                 (-> exact-nonnegative-integer?
                     (or/c (-> (or/c contract-random-generate-fail? c))
                           #f))])
           (λ (c) (λ (fuel) #f))]
          [#:list-contract? is-list-contract? (-> contract? boolean?) (λ (c) #f)])
         flat-contract-property?]
@defproc[(build-chaperone-contract-property
          [#:name
           get-name
           (or/c #f (-> contract? any/c))
           (λ (c) 'anonymous-chaperone-contract)]
          [#:first-order
           get-first-order
           (-> contract? (-> any/c boolean?))
           (λ (c) (λ (x) #t))]
          [#:late-neg-projection
           late-neg-proj
           (or/c #f (-> contract? (-> blame? (-> any/c any/c any/c))))
           #f]
          [#:collapsible-late-neg-projection
           collapsible-late-neg-proj
           (or/c #f (-> contract? (-> blame? (values (-> any/c any/c any/c) collapsible-contract?))))
           #f]
          [#:val-first-projection
           val-first-proj
           (or/c #f (-> contract? blame? (-> any/c (-> any/c any/c))))
           #f]
          [#:projection
           get-projection
           (-> contract? (-> blame? (-> any/c any/c)))
           (λ (c)
             (λ (b)
               (λ (x)
                 (if ((get-first-order c) x)
                     x
                     (raise-blame-error
                      b x '(expected: "~a" given: "~e")
                      (get-name c) x)))))]
          [#:stronger
           stronger
           (or/c (-> contract? contract? boolean?) #f)
           #f]
          [#:equivalent equivalent
           (or/c #f (-> contract? contract? boolean?))
           #f]
          [#:generate
           generate
           (->i ([c contract?])
                [generator
                 (c)
                 (-> exact-nonnegative-integer?
                     (or/c (-> (or/c contract-random-generate-fail? c))
                           #f))])
           (λ (c) (λ (fuel) #f))]
          [#:exercise
           exercise
           (->i ([c contract?])
                [result
                 (c)
                 (-> exact-nonnegative-integer?
                     (values
                      (-> c void?)
                      (listof contract?)))])
           (λ (c) (λ (fuel) (values void '())))]
          [#:list-contract? is-list-contract? (-> contract? boolean?) (λ (c) #f)])
         chaperone-contract-property?]
@defproc[(build-contract-property
          [#:name
           get-name
           (or/c #f (-> contract? any/c))
           (λ (c) 'anonymous-contract)]
          [#:first-order
           get-first-order
           (-> contract? (-> any/c boolean?))
           (λ (c) (λ (x) #t))]
          [#:late-neg-projection
           late-neg-proj
           (or/c #f (-> contract? (-> blame? (-> any/c any/c any/c))))
           #f]
          [#:collapsible-late-neg-projection
           collapsible-late-neg-proj
           (or/c #f (-> contract? (-> blame? (values (-> any/c any/c any/c) collapsible-contract?))))
           #f]
          [#:val-first-projection
           val-first-proj
           (or/c #f (-> contract? blame? (-> any/c (-> any/c any/c))))
           #f]
          [#:projection
           get-projection
           (-> contract? (-> blame? (-> any/c any/c)))
           (λ (c)
             (λ (b)
               (λ (x)
                 (if ((get-first-order c) x)
                     x
                     (raise-blame-error
                      b x '(expected: "~a" given: "~e")
                      (get-name c) x)))))]
          [#:stronger
           stronger
           (or/c (-> contract? contract? boolean?) #f)
           #f]
          [#:equivalent equivalent
           (or/c #f (-> contract? contract? boolean?))
           #f]
          [#:generate
           generate
           (->i ([c contract?])
                [generator
                 (c)
                 (-> exact-nonnegative-integer?
                     (or/c (-> (or/c contract-random-generate-fail? c))
                           #f))])
           (λ (c) (λ (fuel) #f))]
          [#:exercise
           exercise
           (->i ([c contract?])
                [result
                 (c)
                 (-> exact-nonnegative-integer?
                     (values
                      (-> c void?)
                      (listof contract?)))])
           (λ (c) (λ (fuel) (values void '())))]
          [#:list-contract? is-list-contract? (-> contract? boolean?) (λ (c) #f)])
         contract-property?])]{

这些函数分别构建 @racket[prop:contract]、
@racket[prop:chaperone-contract] 和 @racket[prop:flat-contract] 的参数。

@deftech{contract property} 指定了结构体用作契约时的行为。
它通过七个属性来指定：
@itemlist[
  @item{@racket[get-name]，产生一个描述以 @racket[write] 作为契约违规的一部分，
   默认为始终产生 @racket['anonymous-contract]、
   @racket['anonymous-chaperone-contract] 或 @racket['anonymous-flat-contract] 的函数；}
  @item{@racket[get-first-order]，产生一个一阶谓词，
   供 @racket[contract-first-order-passes?] 使用；}
  @item{@racket[late-neg-proj]，产生一个 blame 跟踪投影，
   定义契约的行为（@racket[get-projection] 和 @racket[val-first-proj] 参数
   也指定投影，但使用不同的签名。它们保留用于向后兼容）；}
  @item{@racket[collapsible-late-neg-proj]，类似于 @racket[late-neg-proj]，
   产生一个 blame 跟踪投影来定义契约的行为，
   此函数还指定了契约的 @tech[#:key "collapsible contract"]{可折叠}行为；}
  @item{@racket[stronger]，一个谓词，确定此契约（作为第一个参数传递）
   是否比某个其他契约（作为第二个参数传递）更强，
   其默认值始终返回 @racket[#f]；}
  @item{@racket[equivalent]，一个谓词，确定此契约（作为第一个参数传递）
   是否等价于某个其他契约（作为第二个参数传递）；
   flat 和 chaperone contracts 的默认值是 @racket[equal?]，
   impersonator contracts 返回 @racket[#f]；}
  @item{@racket[generate]，返回一个生成匹配契约的随机值的 thunk
   （使用 @racket[contract-random-generate-fail] 指示失败）
   或返回 @racket[#f] 指示此契约不支持随机生成；}
  @item{@racket[exercise]，返回一个函数，执行匹配契约的值
   （例如，如果它是函数契约，它可能会调用该函数）
   以及一个契约列表，其值将通过此过程生成；}
  @item{以及 @racket[is-list-contract?]，由 @racket[flat-contract?] 使用
   以确定此契约是否只接受 @racket[list?]。}
]

@racket[late-neg-proj]、@racket[collapsible-late-neg-proj]、
@racket[get-projection]、@racket[val-first-proj] 或 @racket[get-first-order]
中至少有一个必须非 @racket[#f]。

这些访问器作为（可选）关键字参数传递给
@racket[build-contract-property]，
并由契约系统应用于适当结构体类型的实例。
它们的结果以类似于 @racket[make-contract] 的参数的方式使用。

@deftech{chaperone contract property} 指定了结构体
作为 chaperone contract 使用时的行为。
它使用 @racket[build-chaperone-contract-property] 指定，
接受与 @racket[build-contract-property] 完全相同的参数集。
唯一的区别是投影访问器必须返回一个与原始未约束值
比较时通过 @racket[chaperone-of?] 的值。

@deftech{flat contract property} 指定了结构体
作为 @tech{flat contract} 使用时的行为。
它使用 @racket[build-flat-contract-property] 指定，
接受与 @racket[build-contract-property] 类似的参数。
不同之处在于：
@itemlist[
@item{投影访问器不应以高阶方式包装其参数，
      类似于 @racket[make-flat-contract] 中对投影的约束；}
@item{省略了 @racket[#:exercise] 关键字参数，
      因为它与 flat contracts 无关。}]

@history[#:changed "6.0.1.13" @list{Added the @racket[#:list-contract?] argument.}
         #:changed "6.1.1.4"
         @list{Allow @racket[generate] to return @racket[contract-random-generate-fail].}
         #:changed "6.90.0.30"
         @list{Added the @racket[#:equivalent] argument.}
         #:changed "7.1.0.10" @list{Added the @racket[#:collapsible-late-neg-projection] argument.}]
}

@deftogether[(
@defproc[(contract-property? [v any/c]) boolean?]
@defproc[(chaperone-contract-property? [v any/c]) boolean?]
@defproc[(flat-contract-property? [v any/c]) boolean?]
)]{
这些谓词分别检测一个值是否是 @tech{contract property}、
@tech{chaperone contract property} 或
@tech{flat contract property}。
}

@subsection{Obligation Information in Check Syntax}

DrRacket 中的 @seclink[#:doc '(lib "scribblings/drracket/drracket.scrbl")
"buttons" #:indirect? #:t]{Check Syntax} 根据契约组合子在程序展开形式中
留下的 @racket[syntax-property]
显示契约的义务信息。这些属性指示契约在源代码中出现的位置
以及契约的正负位置出现的位置。

要使 Check Syntax 为您的新契约组合子显示义务信息，
请使用以下属性（一些辅助宏和函数如下）：

@itemize[@item{@index["racket/contract:contract"]
 @racketblock0['racket/contract:contract : (vector/c symbol? (listof syntax?) (listof syntax?))]
                此属性应附加到实现契约组合子的转换器的结果上。
                它向 Check Syntax 发出信号，表明这是契约开始的位置。

                向量中的第一个元素应该是一个唯一的（在 @racket[eq?] 意义上）值，
                Check Syntax 可以使用标签将此契约与其子部分匹配
                （由以下两个语法属性指定）。

                向量的第二和第三个元素是来自契约各部分的语法对象，
                Check Syntax 将为其着色。
                第一个列表应包含提供契约实现的各方（通常是模块）
                负责的子部分。
                第二个列表应包含客户端负责的子部分。

                例如，在 @racket[(->* () #:pre #t any/c #:post #t)] 中，
                @racket[->*] 和 @racket[#:post] 应在第一个列表中，
                @racket[#:pre] 在第二个列表中。}

          @item{@index["racket/contract:negative-position"]
                @racketblock0['racket/contract:negative-position : symbol?]
                 此属性应附加到契约组合子中被预期为其他契约的子表达式上。
                 属性的值应该是键（来自 @racket['racket/contract:contract] 属性的
                 向量的第一个元素），指示这是哪个契约。

                 当表达式的值是一个客户端负责的契约时，
                 应使用此属性。}

          @item{@index["racket/contract:positive-position"]
                @racketblock0['racket/contract:positive-position : symbol?]
                 此形式类似于 @racket['racket/contract:negative-position]，
                 但当表达式的值是原始方应负责的契约时，应使用此形式。
                 }

          @item{@index["racket/contract:contract-on-boundary"]
                @racketblock0['racket/contract:contract-on-boundary : symbol?]
                 此属性的存在告诉 Check Syntax 应从该点开始着色。
                 它期望表达式是一个契约
                 （因此具有 @racket['racket/contract:contract] 属性）；
                 此属性指示此契约位于（模块）边界上。

                 （属性的值不被使用。）
                 }

          @item{@index["racket/contract:internal-contract"]
                @racketblock0['racket/contract:internal-contract : symbol?]
                类似于 @racket['racket/contract:contract-on-boundary]，
                 此属性的存在触发着色，但这用于包含契约的方（模块）
                 （无论此模块是否导出任何匹配该契约的内容）
                 可能因违反契约而被指责的情况。
                 这在 @racket[->i] 契约中发挥作用，
                 因为契约本身通过依赖关系可以访问受约束的值。
                 }
         ]

@defform/subs[(define/final-prop header body ...)
              ([header main-id
                       (main-id id ...)
                       (main-id id ... . id)])]{
  与 @racket[(define header body ...)] 相同，但 header 中 @racket[main-id] 的使用
  被标注了 @racket['racket/contract:contract] 属性
  （如上所述）。
}

@defform/subs[(define/subexpression-pos-prop header body ...)
              ([header main-id
                       (main-id id ...)
                       (main-id id ... . id)])]{
  与 @racket[(define header body ...)] 相同，但 header 中 @racket[main-id] 的使用
  被标注了 @racket['racket/contract:contract] 属性
  （如上所述），参数被标注了
  @racket['racket/contract:positive-position] 属性。
}


@; ------------------------------------------------------------------------

@subsection{Utilities for Building New Combinators}

@defproc[(contract-stronger? [c1 contract?] [c2 contract?]) boolean?]{
  如果契约 @racket[c1] 接受的值集是 @racket[c2] 的子集或相同，
  则返回 @racket[#t]。

  相同的 @tech{Chaperone contracts} 和 @tech{flat contracts}
  （即 @racket[c1] 与 @racket[c2] 是 @racket[equal?] 的）
  被认为始终比彼此更强。

  此函数是保守的，因此当 @racket[c1] 实际上确实接受更少的值时，
  它可能返回 @racket[#f]。

@examples[#:eval (contract-eval) #:once
                 (contract-stronger? integer? integer?)
                 (contract-stronger? (between/c 25 75) (between/c 0 100))
                 (contract-stronger? (between/c 0 100) (between/c 25 75))
                 (contract-stronger? (between/c -10 0) (between/c 0 10))

                 (contract-stronger? (λ (x) (and (real? x) (<= x 0)))
                                     (λ (x) (and (real? x) (<= x 100))))]


}

@defproc[(contract-equivalent? [c1 contract?] [c2 contract?]) boolean?]{
  如果契约 @racket[c1] 接受的值集与 @racket[c2] 相同，
  则返回 @racket[#t]。

  相同的 @tech{Chaperone contracts} 和 @tech{flat contracts}
  （即 @racket[c1] 与 @racket[c2] 是 @racket[equal?] 的）
  被认为始终彼此等价。

  此函数是保守的，因此当 @racket[c1] 实际上确实接受与 @racket[c2]
  相同的值集时，它可能返回 @racket[#f]。

@examples[#:eval (contract-eval) #:once
                 (contract-equivalent? integer? integer?)
                 (contract-equivalent? (non-empty-listof integer?)
                                       (cons/c integer? (listof integer?)))

                 (contract-equivalent? (λ (x) (and (real? x) (and (number? x) (>= (sqr x) 0))))
                                       (λ (x) (and (real? x) (real? x))))]


  @history[#:added "6.90.0.30"]
}

@defproc[(contract-first-order-passes? [contract contract?]
                                       [v any/c])
         boolean?]{

返回一个布尔值，指示 @racket[contract] 的一阶测试
对于 @racket[v] 是否通过。

如果它返回 @racket[#f]，契约保证对该值不成立；
如果它返回 @racket[#t]，契约可能成立也可能不成立。
如果契约是一阶契约，则 @racket[#t] 的结果保证契约成立。

另请参见 @racket[contract-first-order-okay-to-give-up?] 和
@racket[contract-first-order-try-less-hard]。
}

@defproc[(contract-first-order [c contract?]) (-> any/c boolean?)]{
产生 @racket[or/c] 使用的一阶测试，用于将值匹配到高阶契约。
}

@section[#:tag "contract-utilities"]{Contract Utilities}

@declare-exporting-ctc[racket/contract/base]

@defproc[(contract? [v any/c]) boolean?]{

如果其参数是 @tech{契约}（即用本节描述的某个组合子构造的，
或是可以用作契约的值）则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(chaperone-contract? [v any/c]) boolean?]{

如果其参数是 @tech{chaperone contract}（即保证返回一个
与原始未约束值比较时通过 @racket[chaperone-of?] 的值），
则返回 @racket[#t]。}

@defproc[(impersonator-contract? [v any/c]) boolean?]{

如果其参数是 @tech{impersonator contract}
（即既不是 @tech{chaperone contract} 也不是 @tech{flat contract}
的 @tech{契约}），则返回 @racket[#t]。}

@defproc[(flat-contract? [v any/c]) boolean?]{

当其参数是一个可以立即检查的契约时返回 @racket[#t]
（不同于函数契约等）。

例如，@racket[flat-contract] 从谓词构造 @tech{flat contracts}，
符号、布尔值、数字和其他普通 Racket 值
（被定义为 @tech{契约}）也是 @tech{flat contracts}。}

@defproc[(list-contract? [v any/c]) boolean?]{
  识别某些接受 @racket[list?] 的 @racket[contract?] 值。

  list contract 是一种坚持其参数是 @racket[list?] 的契约，
  这意味着值不能是循环的，
  必须是空列表或使用 @racket[cons] 和另一个列表构造的 pair。

  @history[#:added "6.0.1.13"]
}

@defproc[(contract-name [c contract?]) any/c]{
产生用于在错误消息中描述契约的名称。
}

@defproc[(value-contract [v has-contract?]) (or/c contract? #f)]{
  返回附加到 @racket[v] 的契约（如果有记录）。
  否则返回 @racket[#f]。

  要在您自己的契约组合子中支持 @racket[value-contract]
  和 @racket[value-contract]，请使用 @racket[prop:contracted]
  或 @racket[impersonator-prop:contracted]。
}

@defproc[(has-contract? [v any/c]) boolean?]{
  如果 @racket[v] 是一个有记录契约附加的值，则返回 @racket[#t]。
}

@defproc[(value-blame [v has-blame?]) (or/c blame? #f)]{
  返回附加到 @racket[v] 的契约的 @|blame-object|（如果有记录）。
  否则返回 @racket[#f]。

  要在您自己的契约组合子中支持 @racket[value-contract]
  和 @racket[value-blame]，请使用 @racket[prop:blame]
  或 @racket[impersonator-prop:blame]。

  @history[#:added "6.0.1.12"]
}

@defproc[(has-blame? [v any/c]) boolean?]{
  如果 @racket[v] 是一个有附带 blame 信息的契约的值，
  则返回 @racket[#t]。

  @history[#:added "6.0.1.12"]
}

@defproc[(contract-late-neg-projection [c contract?]) (-> blame? (-> any/c (or/c #f any/c) any/c))]{
  产生定义契约行为的投影。

  第一个参数 @racket[blame?] 对象封装了关于契约检查的信息，
  主要用于在检测到契约违规时创建有意义的错误消息。
  结果函数的第一个参数是应该具有该契约的值，
  第二个参数是 @tech{blame 对象}的缺失方，
  传递给 @racket[raise-contract-error]。

  如果可能，请使用此函数而非 @racket[contract-val-first-projection]
  或 @racket[contract-projection]。
}


@defproc[(contract-projection [c contract?]) (-> blame? (-> any/c any/c))]{
  产生定义契约行为的投影。
  此投影是一个二元柯里化函数：第一次应用接受 blame 对象，
  第二次接受要用契约保护的值。

  如果可能，请改用 @racket[contract-late-neg-projection]。
}

@defproc[(contract-val-first-projection [c contract?]) (-> blame? (-> any/c (-> any/c any/c)))]{
  产生定义契约行为的投影。
  此投影类似于 @racket[contract-late-neg-projection] 的结果，
  但多了一层柯里化。

  如果可能，请改用 @racket[contract-late-neg-projection]。
}

@defproc[(make-none/c [sexp-name any/c]) contract?]{

创建一个不接受任何值的契约，在发出契约违规信号时
报告名称 @racket[sexp-name]。}

@defform*[[(recursive-contract contract-expr recursive-contract-option ...)
           (recursive-contract contract-expr type recursive-contract-option ...)]
          #:grammar ([recursive-contract-option
                      #:list-contract?
                      #:extra-delay]
                     [type
                      #:impersonator
                      #:chaperone
                      #:flat])]{

延迟其参数的求值直到契约被检查，使递归契约成为可能。
如果未给出 @racket[type]，则创建 impersonator contract。

如果给出了 @racket[recursive-contract-option]
@racket[#:list-contract?]，则结果是一个 @racket[list-contract?]，
且 @racket[contract-expr] 必须求值为 @racket[list-contract?]。

如果给出了 @racket[recursive-contract-option] @racket[#:extra-delay]，
则 @racket[contract-expr] 表达式仅在第一个要检查的值
提供给契约时才求值。
没有它，@racket[contract-expr] 会更早求值。
此选项仅在 @racket[type] 为 @racket[#:flat] 时支持。

@examples[#:eval (contract-eval)
  (define even-length-list/c
    (or/c null?
          (cons/c any/c
                  (cons/c any/c
                          (recursive-contract even-length-list/c #:flat)))))

  (even-length-list/c '(A B))
  (even-length-list/c '(1 2 3))
]

 @history[#:changed "6.0.1.13" @list{Added the @racket[#:list-contract?] option.}
          #:changed "6.7.0.3" @list{Added the @racket[#:extra-delay] option.}]
}


@defform/subs[(opt/c contract-expr maybe-name)
              ([maybe-name (code:line)
                           (code:line #:error-name id)])]{

此函数通过遍历其语法来优化其参数契约表达式，
对于已知的契约组合子，将它们融合为单个契约组合子，
尽可能地避免分配开销。结果是一个行为应与参数完全相同
但更快的契约。

如果存在 @racket[#:error-name] 参数，
且 @racket[contract-expr] 求值为非契约表达式，
则 @racket[opt/c] 使用 @racket[id] 作为原语的名称引发错误，
而不是使用名称 @racket[opt/c]。

@examples[#:eval (contract-eval) #:once
                 (eval:error
                  (define/contract (f x)
                    (opt/c '(not-a-contract))
                    x))
                 (eval:error
                  (define/contract (f x)
                    (opt/c '(not-a-contract) #:error-name define/contract)
                    x))]
}


@defform[(define-opt/c (id id ...) expr)]{

这定义了一个递归契约并同时优化它。
只要定义的函数终止，@racket[define-opt/c] 的行为就如同
@racket[-opt/c] 不存在一样，定义了一个契约上的函数
（但 body 表达式必须返回一个契约）。
但是，它也优化了该契约定义，避免额外分配，
很像 @racket[opt/c] 所做的。

例如，

@racketblock[
(define-contract-struct bt (val left right))

(define-opt/c (bst-between/c lo hi)
  (or/c null?
        (bt/c [val (real-in lo hi)]
              [left (val) (bst-between/c lo val)]
              [right (val) (bst-between/c val hi)])))

(define bst/c (bst-between/c -inf.0 +inf.0))
]

定义了检查二叉搜索树不变式的 @racket[bst/c] 契约。
去掉 @racket[-opt/c] 也会创建一个二叉搜索树契约，
但速度（大约）慢 20 倍。

注意，在某些情况下，由 @racket[define-opt/c] 定义的函数的调用可能终止，
即使相应的基于 @racket[define] 的函数不会终止。
这是 @racket[define-opt/c] 的一个缺点，
我们希望在未来某个时候理解并修复它，但目前没有具体计划。

}

@defthing[contract-continuation-mark-key continuation-mark-key?]{
在契约检查期间存在的 continuation marks 所使用的键。
这些 marks 的值是与当前正在检查的契约对应的 @|blame-objects|。

@history[#:added "6.4.0.4"]
}

@defproc[(contract-custom-write-property-proc [c contract?]
                                              [p output-port?]
                                              [mode (or/c #f #t 0 1)])
         void?]{
  使用契约的名称将 @racket[c] 打印到 @racket[p]。

  @history[#:added "6.1.1.5"]
}

@defproc[(rename-contract [contract contract?]
                          [name any/c])
         contract?]{
  生成一个行为类似 @racket[contract] 但名称为 @racket[name] 的契约。

  如果 @racket[contract] 是 @tech{flat contract}，
  则结果契约也是 @tech{flat contract}。

  @history[#:added "6.3"]
}

@defform[(contract-first-order-okay-to-give-up?)]{
 此形式返回一个布尔值，控制一阶契约检查的结果。
 更具体地说，如果它返回 @racket[#t]，
 则一阶检查可能返回 @racket[#t]，
 即使完整的一阶检查尚未发生。
 如果它返回 @racket[#f]，
 则一阶检查必须继续，直到返回确定的答案。

 这仅在 @racket[or/c] 或 @racket[first-or/c]
 的检查以确定使用哪个分支的动态范围内返回 @racket[#t]。

 @history[#:added "6.3.0.9"]
}
@defform[(contract-first-order-try-less-hard e)]{
 鼓励在 @racket[e] 的动态范围内发生的一阶检查
 更有可能放弃。也就是说，使
 @racket[contract-first-order-okay-to-give-up?]
 更有可能返回 @racket[#t]。

 如果不在 @racket[or/c] 或 @racket[first-or/c]
 的检查以确定分支的动态范围内，则此形式无效。

 @history[#:added "6.3.0.9"]
}

@defproc[(if/c [predicate (-> any/c any/c)]
               [then-contract contract?]
               [else-contract contract?])
         contract?]{
  生成一个契约，当应用于值时，首先用 @racket[predicate] 测试值；
  如果 @racket[predicate] 返回 true，则应用 @racket[then-contract]；
  否则，应用 @racket[else-contract]。
  如果 @racket[then-contract] 和 @racket[else-contract]
  都是 @tech{flat contracts}，则结果契约是 @tech{flat contract}。

  例如，以下契约强制要求：如果一个值是过程，
  它必须是一个 thunk；否则它可以是任何（非过程）值：
    @racketblock[(if/c procedure? (-> any) any/c)]
  注意以下契约是 @bold{不}等价的：
    @racketblock[(or/c (-> any) any/c) (code:comment "wrong!")]
  最后一个契约等同于 @racket[any/c]，
  因为 @racket[or/c] 在高阶契约之前先尝试 @tech{flat contracts}。

  @history[#:added "6.3"]
}

@defthing[failure-result/c contract?]{
  一个描述像 @racket[hash-ref] 这样的过程
  的失败结果参数的契约。

  等价于 @racket[(if/c procedure? (-> any) any/c)]。

  @history[#:added "6.3"]
}

@defproc[(get/build-val-first-projection [c contract?])
         (-> blame? (-> any/c (-> any/c any/c)))]{
  返回 @racket[c] 的 @racket[_val-first] 投影。

  有关更多详细信息，请参见 @racket[make-contract]。

  @history[#:added "6.1.1.5"]
}

@defproc[(get/build-late-neg-projection [c contract?])
         (-> blame? (-> any/c any/c any/c))]{
 返回 @racket[c] 的 @racket[_late-neg] 投影。

 如果 @racket[c] 没有 @racket[_late-neg] 契约，
 则此函数为其使用原始投影，
 并向 @racket['racket/contract] 日志记录器记录警告。

 有关更多详细信息，请参见 @racket[make-contract]。

 @history[#:added "6.2.900.11"]
}

@section{@racketmodname[racket/contract/base]}

@defmodule[racket/contract/base]

@racketmodname[racket/contract/base] 模块提供了
@racketmodname[racket/contract] 模块导出项的一个子集。
特别地，它包含以下各节中的所有内容：
@itemize[@item{@secref["data-structure-contracts"]}
         @item{@secref["function-contracts"]}
         @item{@secref["attaching-contracts-to-values"] 以及}
         @item{@secref["contract-utilities"] 节。}]

不幸的是，使用 @racketmodname[racket/contract/base]
并不会比 @racketmodname[racket/contract] 占用显著更少的内存，
但它仍然可以用于向某些库添加契约，这些库是
@racketmodname[racket/contract] 用于实现
契约系统中一些更复杂部分的。

@; ------------------------------------------------------------------------

@section[#:tag "collapsible"]{Collapsible Contracts}
@defmodule*/no-declare[(racket/contract/collapsible)]
@declare-exporting-ctc[racket/contract/collapsible]
@history[#:added "7.1.0.10"]

@deftech{可折叠契约}是契约系统中的一种优化，
旨在避免高阶值上契约包装器的特定病态堆积。
@racket[vectorof]、@racket[vector/c] 和 @racket[->]
契约组合子支持向量契约和返回单个值的函数契约的折叠。

直观地说，可折叠契约是一个树结构。
@racketlink[collapsible-ho/c]{树节点}代表高阶契约
（例如 @racket[->]），
@racketlink[collapsible-leaf/c]{树叶}代表 flat contracts 的序列。
两棵树可以通过 @racket[merge] 过程折叠为一棵树，
该过程从叶子中移除不必要的 flat contracts。

有关可折叠契约的动机和设计的更多信息，
请参见 @cite["Feltey18"]。
有关理论基础，请参见 @cite["Greenberg15"]。

@bold{警告}：本节描述的功能是实验性的，
可能不足以实现新的可折叠契约。实现新的可折叠契约
需要使用不安全的 chaperones 和 impersonators，
这仅支持向量和过程值。本文档主要用于允许
@racket[racket/contract/collapsible] 库的后续维护。
@bold{警告结束}

@defproc[(get/build-collapsible-late-neg-projection [c contract?])
         (-> blame? (values (-> any/c any/c any/c) collapsible-contract?))]{
 返回 @racket[c] 的 @racket[_collapsible-late-neg] 投影。

 如果 @racket[c] 没有 @racket[_collapsible-late-neg] 投影，
 则此函数为其使用原始投影，
 并构造一个叶节点作为其可折叠表示。
}

@defthing[collapsible-contract-continuation-mark-key continuation-mark-key?]{
在可折叠契约检查期间存在的 continuation marks 所使用的键。
如果当前契约是可折叠的，这些 marks 的值为 @racket[#t]。
}

@defform[(with-collapsible-contract-continuation-mark body ...)]{
插入一个 continuation mark，通知契约分析器当前契约是可折叠的。
}

@defthing[prop:collapsible-contract struct-type-property?]{
 实现此属性的结构体可用作可折叠契约。
 与此属性关联的值应通过调用
 @racket[build-collapsible-contract-property] 来构造。
}

@defproc[(collapsible-contract? [v any/c]) boolean?]{
一个识别具有 @racket[prop:collapsible-contract] 属性的结构体的谓词。}

@defproc[(merge [new-cc collapsible-contract?]
                [new-neg any/c]
                [old-cc collapsible-contract?]
                [old-neg any/c])
         collapsible-contract?]{
 将两个可折叠契约合并为单个可折叠契约。
 @racket[new-neg] 和 @racket[old-neg] 参数预期是
 类似于传递给 @tech{late neg projection} 的 blame 方。
}

@defproc[(collapsible-guard [cc collapsible-contract?]
                            [val any/c]
                            [neg-party any/c])
         any/c]{
 类似于 @tech{late neg projection}，此函数用可折叠契约 @racket[cc]
 守卫值 @racket[val]。
}

@defproc[(collapsible-contract-property? [v any/c]) boolean?]{
 此谓词指示一个值可以用作 @racket[prop:collapsible-contract] 的属性。
}

@defproc[(build-collapsible-contract-property
          [#:try-merge try-merge
           (or/c #f
                 (-> collapsible-contract?
                     any/c
                     collapsible-contract?
                     any/c
                     (or/c #f collapsible-contract?)))
           #f]
          [#:collapsible-guard collapsible-guard
           (-> collapsible-contract? any/c any/c any/c)
           (λ (cc v neg)
             (error
              "internal error: contract does not support `collapsible-guard`" cc))])
         collapsible-contract-property?]{
 从一个合并函数和一个 guard 构造 @deftech{可折叠契约属性}。
 @racket[try-merge] 参数类似于 @racket[merge]，
 但可能返回 @racket[#f] 而不是可折叠契约，
 并且可以特化到特定的可折叠契约。
 @racket[collapsible-guard] 参数应特化到
 正在实现的特定可折叠契约。
}

@defstruct*[collapsible-ho/c
            ([latest-blame blame?]
             [missing-party any/c]
             [latest-ctc contract?])]{
 高阶值的可折叠契约的通用父结构体。
 @racket[latest-blame] 字段保存最近附加的契约的 blame 对象。
 类似地，@racket[missing-party] 字段保存传递给契约的最新缺失方。
 @racket[latest-contract] 字段存储附加到值上的最近契约。
}

@defstruct*[collapsible-leaf/c
            ([proj-list (listof (-> any/c any/c any/c))]
             [contract-list (listof contract?)]
             [blame-list (listof blame?)]
             [missing-party-list (listof any/c)])]{
 一个表示可折叠契约叶节点的结构体。
 @racket[proj-list] 字段保存部分应用的 @tech{late neg projections} 的列表。
 @racket[contract-list]、@racket[blame-list] 和
 @racket[missing-party-list] 字段分别保存契约列表、
 blame 对象列表和 blame 缺失方列表。
}

@deftogether[(@defthing[impersonator-prop:collapsible impersonator-property?]
              @defproc[(has-impersonator-prop:collapsible? [v any/c]) boolean?]
              @defproc[(get-impersonator-prop:collapsible [v any/c]) collapsible-property?])]{
 一个 impersonator 属性（及其访问器），应附加到
 使用可折叠契约守卫的 chaperoned 或 impersonated 值上。
}

@defstruct*[collapsible-property ([c-c collapsible-contract?]
                                  [neg-party any/c]
                                  [ref (or/c #f impersonator?)])]{
 应附加到使用可折叠契约保护的值
 的 chaperones 或 impersonators 上的属性的父结构体。
 @racket[c-c] 字段存储已附加或将附加到值上的可折叠契约。
 @racket[neg-party] 字段存储传递给值上契约的最新缺失 blame 方。
 @racket[ref] 字段是可变的，存储对此属性所附加的
 chaperone 或 impersonator 的引用。
 这对于确定在值被可折叠契约保护之后
 是否有未知 chaperone 附加到值上是必要的。
}
@defstruct*[(collapsible-count-property collapsible-property)
            ([count natural-number/c]
             [prev (or/c collapsible-count-property? any/c)])]{
 在值完全进入可折叠模式之前，此属性与
 @racket[impersonator-prop:collapsible] 属性关联。
 这些属性在 @racket[_count] 字段中跟踪值上契约的数量，
 并在 @racket[prev] 字段中保存对前一个
 @deftech{计数属性}的引用或没有契约的原始值。
 这允许契约系统遍历附加契约链并将其合并为
 单个可折叠契约以保护原始值。
}
@defstruct*[(collapsible-wrapper-property collapsible-property)
            ([checking-wrapper impersonator?])]{
 当值由可折叠契约守卫时使用此属性。
 @racket[checking-wrapper] 字段保存一个 chaperone 或 impersonator，
 它分派到存储在此属性中的可折叠契约以执行任何必要的契约检查。
 当值接收另一个契约并发生合并时，
 checking wrapper 将保持不变，
 即使附加到值上的特定可折叠契约可能改变。
}

@; ------------------------------------------------------------------------


@section{Legacy Contracts}

@defproc[(make-proj-contract [name any/c]
                             [proj
                              (or/c (-> any/c
                                        any/c
                                        (list/c any/c any/c)
                                        contact?
                                        (-> any/c any/c))
                                    (-> any/c
                                        any/c
                                        (list/c any/c any/c)
                                        contact?
                                        boolean?
                                        (-> any/c any/c)))]
                             [first-order (-> any/c boolean?)])
         contract?]{
  使用旧接口构建契约。

  忽略错误，它等价于：
  @racketblock[(make-contract
                #:name name
                #:first-order first-order
                #:projection
                (cond
                  [(procedure-arity-includes? proj 5)
                   (lambda (blame)
                     (proj (blame-positive blame)
                           (blame-negative blame)
                           (list (blame-source blame) (blame-value blame))
                           (blame-contract blame)
                           (not (blame-swapped? blame))))]
                  [(procedure-arity-includes? proj 4)
                   (lambda (blame)
                     (proj (blame-positive blame)
                           (blame-negative blame)
                           (list (blame-source blame) (blame-value blame))
                           (blame-contract blame)))]))]
}

@defproc[(raise-contract-error [val any/c] [src any/c]
                               [pos any/c] [name any/c]
                               [fmt string?] [arg any/c] ...)
         any/c]{
  在从 @racket[val]、@racket[src]、@racket[pos] 和
  @racket[name] 参数构建 @racket[blame] 结构体后
  调用 @racket[raise-blame-error]。
  @racket[fmt] 字符串和后续参数传递给 @racket[format]，
  并用作错误消息中的字符串。
}

@defproc[(contract-proc [c contract?])
         (->* (symbol? symbol? (or/c syntax? (list/c any/c any/c)))
              (boolean?)
              (-> any/c any))]{
  从契约构造一个旧式投影。

  结果函数接受 @racket[blame] 结构体中的信息，
  并返回一个检查契约的投影函数。

}
@section{Random generation}

@defproc[(contract-random-generate [ctc contract?]
                                   [fuel 5 exact-nonnegative-integer?]
                                   [fail (or/c #f (-> any) (-> boolean? any)) #f])
         any/c]{
尝试随机生成一个匹配契约的值。
@racket[_fuel] 参数限制生成器尝试生成匹配契约的值的努力程度，
是结果值大小的粗略限制。

生成器可能无法生成值，要么因为某些契约没有相应的生成器
（例如，并非所有谓词都有生成器），
要么因为 fuel 不足。在任何情况下，函数 @racket[fail] 都会被调用。
如果 @racket[fail] 接受一个参数，
当 @racket[ctc] 没有生成器时用 @racket[#t] 调用它，
当有生成器但生成器最终返回 @racket[contract-random-generate-fail]
时用 @racket[#f] 调用它。

 @examples[#:eval (contract-eval) #:once
           (for/list ([i (in-range 10)])
             (contract-random-generate (or/c integer? #f)))]

@history[#:changed "6.1.1.5" @list{Allow @racket[fail] to accept a boolean.}]

}

@defproc[(contract-exercise [#:fuel fuel exact-nonnegative-integer? 10]
                            [#:shuffle? shuffle? any/c #f]
                            [val any/c] ...+) void?]{
  尝试让 @racket[val] 违反其契约（如果有的话）。

  使用 @racket[value-contract] 确定任何 @racket[val] 是否有契约，
  对于有契约的值，使用契约形态的信息来戳探该值。
  例如，如果值是函数，它将使用契约告诉它向值提供什么参数。

  参数 @racket[_fuel] 决定 @racket[contract-exercise]
  尝试打破值的力度。它控制练习迭代的次数
  和练习期间生成的中间值的大小。

  参数 @racket[_shuffle?] 控制 @racket[contract-exercise]
  是否随机化练习顺序。如果 @racket[_shuffle?] 不是 @racket[#f]，
  @racket[contract-exercise] 会在每次练习迭代中
  随机打乱契约的顺序。

 @examples[#:eval (contract-eval) #:once
           (define/contract (returns-false x)
             (-> integer? integer?)
             (code:comment "does not obey its contract")
             #f)
           (eval:error (contract-exercise returns-false))

           (define/contract (calls-its-argument-with-eleven f)
             (-> (-> integer? integer?) boolean?)
             (code:comment "f returns an integer, but")
             (code:comment "we're supposed to return a boolean")
             (f 11))
           (eval:error (contract-exercise calls-its-argument-with-eleven))]

 @history[#:changed "7.0.0.18" @elem{Added the @racket[shuffle?] optional argument.}]
}

@defproc[(contract-random-generate/choose [c contract?] [fuel exact-nonnegative-integer?])
         (or/c #f (-> c))]{
  此函数类似于 @racket[contract-random-generate]，
  但它旨在与基于其子契约生成值的组合子一起使用。
  它必须在 @racket[contract-random-generate]
  （和 @racket[contract-exercise]）创建生成器时调用。
  更准确地说，@racket[contract-random-generate/choose]
  仅可用于 @racket[build-contract-property]、
  @racket[build-chaperone-contract-property]
  或 @racket[build-flat-contract-property] 中的
  @racket[_generate] 和 @racket[_exercise] 参数，
  且仅在调用 @racket[_generate]（和 @racket[_exercise]）的动态范围内。
  即在其接收 @racket[_c] 和 @racket[_fuel] 参数之后
  并在返回 thunk（或练习器）之前。

  @racket[contract-random-generate/choose] 永远不会失败，
  但它可能逃逸回包围的调用
  或对 @racket[contract-random-generate] 的原始调用。

  它从几种可能的生成策略中选择一种，
  因此它可能并不实际使用与 @racket[c] 关联的生成器，
  而是使用通过 @racket[contract-random-generate-stash]
  知道的匹配 @racket[c] 的已存储值。

@history[#:added "6.1.1.5"]
}

@defthing[contract-random-generate-fail contract-random-generate-fail?]{
  一个用于指示生成器未能生成值的原子值。

@history[#:added "6.1.1.5"]
}

@defproc[(contract-random-generate-fail? [v any/c]) boolean?]{
  一个识别 @racket[contract-random-generate-fail] 的谓词。

@history[#:added "6.1.1.5"]
}

@defproc[(contract-random-generate-env? [v any/c]) boolean?]{
  识别契约生成环境。

@history[#:added "6.1.1.5"]
}

@defproc[(contract-random-generate-stash [env contract-random-generate-env?]
                                         [c contract?]
                                         [v c]) void?]{
  应使用被测程序在契约生成期间提供的值来调用此函数。
  例如，当生成 @racket[(-> (-> integer? integer?) integer?)] 时，
  它可能会调用其参数函数。该参数函数可能返回一个整数，
  如果是这样，应通过调用 @racket[contract-random-generate-stash]
  保存该整数，以便其他整数生成器可以使用它。

@history[#:added "6.1.1.5"]
}

@defproc[(contract-random-generate-get-current-environment) contract-random-generate-env?]{
  返回当前用于生成的环境。此函数只能在契约生成的动态范围内调用。
  它旨在在构建契约生成器期间获取，
  然后在生成发生时与 @racket[contract-random-generate-stash] 一起使用。

@history[#:added "6.1.1.5"]
}
