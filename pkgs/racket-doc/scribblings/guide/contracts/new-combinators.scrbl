#lang scribble/doc
@(require scribble/manual scribble/eval "utils.rkt"
          (for-label racket/contract racket/gui))

@(define ex-eval (make-base-eval))
@(ex-eval '(require racket/contract))

@title{Building New Contracts}

Contract 在内部被表示为函数，这些函数接受关于 contract 的信息（谁负责、源位置、@|etc|）并产生投影（在精神上符合 Dana Scott 的概念）来强制执行 contract。

在一般意义上，投影是一个接受任意值并返回一个满足对应 contract 的值的函数。例如，一个只接受整数的投影对应于 contract @racket[(flat-contract integer?)]，可以这样写：

@racketblock[
(define int-proj
  (λ (x)
    (if (integer? x)
        x
        (signal-contract-violation))))
]

作为第二个例子，一个接受整数上一元函数的投影看起来如下：

@racketblock[
(define int->int-proj
  (λ (f)
    (if (and (procedure? f)
             (procedure-arity-includes? f 1))
        (λ (x) (int-proj (f (int-proj x))))
        (signal-contract-violation))))
]

虽然这些投影具有正确的错误行为，但它们并未完全准好作为 contract 使用，因为它们不处理 blame 也不提供良好的错误消息。为了处理这些问题，contract 不仅使用简单的投影，而是使用接受一个 @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{blame object} 的函数，该对象将作为 blame 候选的两个方的名称以及 contract 建立的源位置和 contract 名称的记录封装在内。然后它们可以将这些信息传递给 @racket[raise-blame-error] 以产生良好的错误消息。

这里是这两个投影中的第一个，重新写进了 contract 系统：
@racketblock[
(define (int-proj blame)
  (λ (x)
    (if (integer? x)
        x
        (raise-blame-error
         blame
         x
         '(expected: "<integer>" given: "~e")
         x))))
]
新的参数指定了对正面和负面 contract 违反负责的人。

在这个系统中，contract 总是在两个方之间建立。一个方称为 server，按照 contract 提供某些值，另一个方称为 client，也按照 contract 消耗这些值。Server 被称为正面位置，client 被称为负面位置。因此，在仅仅是整数 contract 的情况下，唯一可能出错的是提供的值不是整数。因此，只有正面方（server）才会积累 blame。@racket[raise-blame-error] 函数总是将 blame 归于正面方。

将这与我们的函数 contract 的投影进行比较：

@racketblock[
(define (int->int-proj blame)
  (define dom (int-proj (blame-swap blame)))
  (define rng (int-proj blame))
  (λ (f)
    (if (and (procedure? f)
             (procedure-arity-includes? f 1))
        (λ (x) (rng (f (dom x))))
        (raise-blame-error
         blame
         f
         '(expected "a procedure of one argument" given: "~e")
         f))))
]

在这种情况下，唯一明确的 blame 覆盖了这样的情况：向 contract 提供了非过程值，或者该过程不接受一个参数。与整数投影一样，这里的 blame 也在于值的生产者，这就是为什么 @racket[raise-blame-error] 接受的 @racket[blame] 未变。

对域和值域的检查委托给了 @racket[int-proj] 函数，它在 @racket[int->int-proj] 函数的前两行接受参数。这里的工大在于，即使 @racket[int->int-proj] 函数总是将其视为正面的值归于 blame，我们也可以通过在给定的 @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{blame object} 上调用 @racket[blame-swap] 来交换 blame 的两个方，将正面方替换为负面方，反之亦然。

然而，这个技术并不仅仅是让例子运作的便宜诈巧。正面和负面的反转是函数行为方式的自然结果。也就是说，想象一个程序中两个模块之间的值流动。首先，一个模块（server）定义一个函数，然后该模块被另一个模块（client）require。到目前为止，函数本身必须从原始提供模块转移到需要它的模块。现在，想象需要它的模块调用了这个函数，向它提供一个参数。在这个时刻，值的流动反转了。参数正在从需要它的模块返回到提供它的模块！Client 在将参数“提供”给 server，而 server 在作为 client 接收该值。最后，当函数产生结果时，该结果按照从 server 到 client 的原始方向流动。因此，域上的 contract 反转了正面和负面的 blame 方，正如值的流动反转一样。

我们可以利用这个观察来泛化函数 contract，构建一个接受任意两个 contract 并返回它们之间函数的 contract 的函数。

这个投影还进一步使用 @racket[blame-add-context] 来在检测到 contract 违反时改善错误消息。

@racketblock[
(define (make-simple-function-contract dom-proj range-proj)
  (λ (blame)
    (define dom (dom-proj (blame-add-context blame
                                             "the argument of"
                                             #:swap? #t)))
    (define rng (range-proj (blame-add-context blame
                                               "the range of")))
    (λ (f)
      (if (and (procedure? f)
               (procedure-arity-includes? f 1))
          (λ (x) (rng (f (dom x))))
          (raise-blame-error
           blame
           f
           '(expected "a procedure of one argument" given: "~e")
           f)))))
]

虽然这些投影被 contract 库支持并可用于构建新的 contract，但 contract 库还支持一种不同的 API，可能更高效。具体而言，@tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{late neg projection} 接受一个不含负面 blame 信息的 blame object，然后返回一个函数，该函数接受要应用 contract 的值和负面方的名称（按此顺序）。返回的函数再次返回应用了 contract 的值。将 @racket[int->int-proj] 重写为使用这个 API 呈现如下：
@interaction/no-prompt[#:eval ex-eval
(define (int->int-proj blame)
  (define dom-blame (blame-add-context blame
                                       "the argument of"
                                       #:swap? #t))
  (define rng-blame (blame-add-context blame "the range of"))
  (define (check-int v to-blame neg-party)
    (unless (integer? v)
      (raise-blame-error
       to-blame #:missing-party neg-party
       v
       '(expected "an integer" given: "~e")
       v)))
  (λ (f neg-party)
    (if (and (procedure? f)
             (procedure-arity-includes? f 1))
        (λ (x)
          (check-int x dom-blame neg-party)
          (define ans (f x))
          (check-int ans rng-blame neg-party)
          ans)
        (raise-blame-error
         blame #:missing-party neg-party
         f
         '(expected "a procedure of one argument" given: "~e")
         f))))]
这种风格的 contract 的优点在于 @racket[_blame] 参数可以在 contract 边界的 server 侧提供，结果可用于每个不同的 client。在较简单的情况下，必须为每个 client 创建新的 blame object。

在这个 contract 能够与 contract 系统的其余部分一起使用之前，还剩一个最终问题。在上述函数中，contract 通过为 @racket[f] 创建一个包装函数来实现，但这个包装函数与 @racket[equal?] 不协作，也与运行时系统没有关联结果函数与输入函数 @racket[f] 之间的关系。

为了修复这两个问题，我们应使用 @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{chaperones} 而不仅仅使用 @racket[λ] 来创建包装函数。这里是重写为使用 @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{chaperone} 的 @racket[int->int-proj] 函数：

@interaction/no-prompt[#:eval ex-eval
(define (int->int-proj blame)
  (define dom-blame (blame-add-context blame
                                       "the argument of"
                                       #:swap? #t))
  (define rng-blame (blame-add-context blame "the range of"))
  (define (check-int v to-blame neg-party)
    (unless (integer? v)
      (raise-blame-error
       to-blame #:missing-party neg-party
       v
       '(expected "an integer" given: "~e")
       v)))
  (λ (f neg-party)
    (if (and (procedure? f)
             (procedure-arity-includes? f 1))
        (chaperone-procedure
         f
         (λ (x)
           (check-int x dom-blame neg-party)
           (values (λ (ans)
                     (check-int ans rng-blame neg-party)
                     ans)
                   x)))
        (raise-blame-error
         blame #:missing-party neg-party
         f
         '(expected "a procedure of one argument" given: "~e")
         f))))]

类似于上述投影的投影，但适用于你可能制作的其他新类型的值，可以与 contract 库原语言一起使用。具体而言，我们可以使用 @racket[make-chaperone-contract] 来构建它：
@interaction/no-prompt[#:eval ex-eval
 (define int->int-contract
   (make-contract
    #:name 'int->int
    #:late-neg-projection int->int-proj))]
然后将其与一个值组合并获得一些 contract 检查。
@def+int[#:eval 
         ex-eval
         (define/contract (f x)
           int->int-contract
           "not an int")
         (f #f)
         (f 1)]

@section{Contract Struct Properties}

@racket[make-chaperone-contract] 函数适用于一次性的 contract，但往往你想要制作许多仅在某些部分有差异的不同 contract。做到这一点的最佳方式是使用带有 @racket[prop:contract]、@racket[prop:chaperone-contract] 或 @racket[prop:flat-contract] 的 @racket[struct]。

例如，假设我们想要制作一种简单形式的 @racket[->] contract，它接受一个用于值域的 contract 和一个用于域的 contract。我们应定义一个带有两个字段的 struct，并使用 @racket[build-chaperone-contract-property] 来构造我们需要的 chaperone contract 属性。
@interaction/no-prompt[#:eval ex-eval
                              (struct simple-arrow (dom rng)
                                #:property prop:chaperone-contract
                                (build-chaperone-contract-property
                                 #:name
                                 (λ (arr) (simple-arrow-name arr))
                                 #:late-neg-projection
                                 (λ (arr) (simple-arrow-late-neg-proj arr))))]

为了将 @racket[integer?] 和 @racket[#f] 等值自动强制转换为 contract，我们需要调用 @racket[coerce-chaperone-contract]
（请注意，这会拒绝 impersonator contract 并不强谈 flat contract；要执行这些操作，请改用 @racket[coerce-contract] 或 @racket[coerce-flat-contract]）。
@interaction/no-prompt[#:eval ex-eval
                              (define (simple-arrow-contract dom rng)
                                (simple-arrow (coerce-contract 'simple-arrow-contract dom)
                                              (coerce-contract 'simple-arrow-contract rng)))]

定义 @racket[_simple-arrow-name] 是直接的；它需要返回一个表示 contract 的 s-expression：
@interaction/no-prompt[#:eval ex-eval
                              (define (simple-arrow-name arr)
                                `(-> ,(contract-name (simple-arrow-dom arr))
                                     ,(contract-name (simple-arrow-rng arr))))]
并且我们可以使用我们早先定义的投影的泛化版本来定义投影，这次使用 @tech[#:doc '(lib "scribblings/reference/reference.scrbl")]{chaperones}：
@interaction/no-prompt[#:eval
                       ex-eval
                       (define (simple-arrow-late-neg-proj arr)
                         (define dom-ctc (get/build-late-neg-projection (simple-arrow-dom arr)))
                         (define rng-ctc (get/build-late-neg-projection (simple-arrow-rng arr)))
                         (λ (blame)
                           (define dom+blame (dom-ctc (blame-add-context blame
                                                                         "the argument of"
                                                                         #:swap? #t)))
                           (define rng+blame (rng-ctc (blame-add-context blame "the range of")))
                           (λ (f neg-party)
                             (if (and (procedure? f)
                                      (procedure-arity-includes? f 1))
                                 (chaperone-procedure
                                  f
                                  (λ (arg) 
                                    (values 
                                     (λ (result) (rng+blame result neg-party))
                                     (dom+blame arg neg-party))))
                                 (raise-blame-error
                                  blame #:missing-party neg-party
                                  f
                                  '(expected "a procedure of one argument" given: "~e")
                                  f)))))]

@def+int[#:eval 
         ex-eval
         (define/contract (f x)
           (simple-arrow-contract integer? boolean?)
           "not a boolean")
         (f #f)
         (f 1)]

@section[#:tag "new-combinators-s1"]{With all the Bells and Whistles}

Contract 有许多 @racket[simple-arrow-contract] 未添加的可选部分。在这一节中，我们逐一介绍所有这些部分，展示它们可以如何实现。

第一个是一阶检查。这用于 @racket[or/c] 在看到一个值时确定使用哪个高阶参数 contract。这里是我们简单箭头 contract 的函数。
@interaction/no-prompt[#:eval ex-eval
                              (define (simple-arrow-first-order ctc)
                                (λ (v) (and (procedure? v) 
                                            (procedure-arity-includes? v 1))))]
它接受一个值，如果该值肯定不满足 contract 则返回 @racket[#f]，如果按照我们所能判断的，该值通过检查一阶属性满足 contract，则返回 @racket[#t]。

下一个是随机生成。Contract 库中的随机生成包含两部分：随机生成满足 contract 的值的能力，以及针对已给定的匹配 contract 的值进行针对性测试的能力，以寻找其中的 bug（并尝试让它们产生有趣的值供生成过程中其他地时使用）。

为了执行契约的针对性测试，我们需要实现一个函数，该函数接受一个 @racket[arrow-contract] struct 和一些 fuel。它应该返回两个值：一个接受 contract 值并对其进行针对性测试的函数，以及针对性测试过程将始终产生的值列表。在我们的简单 contract 的情况下，只要我们能生成定义域的值（因为我们只需调用该函数），就知道我们总是可以生成值域的值。因此，这里是匹配 @racket[build-chaperone-contract-property] 的 @racket[_exercise] 参数的函数：
@interaction/no-prompt[#:eval
                       ex-eval
                       (define (simple-arrow-contract-exercise arr)
                         (define env (contract-random-generate-get-current-environment))
                         (λ (fuel)
                           (define dom-generate 
                             (contract-random-generate/choose (simple-arrow-dom arr) fuel))
                           (cond
                             [dom-generate
                              (values 
                               (λ (f) (contract-random-generate-stash
                                       env
                                       (simple-arrow-rng arr)
                                       (f (dom-generate))))
                               (list (simple-arrow-rng arr)))]
                             [else
                              (values void '())])))]
如果域 contract 可以被生成，那么我们知道可以通过针对性测试做一些有益的事情。在这种情况下，我们返回一个过程，它使用我们从域生成的内容来调用 @racket[_f]（匹配 contract 的函数），并且我们将结果值保存到环境中。我们还返回 @racket[(simple-arrow-rng arr)] 条目来表示针对性测试将始终产生该 contract 的值。

如果我们不能，那么我们只返回一个不进行针对性测试的函数（@racket[void]）和空列表（表示我们不会生成任何值）。

然后，为了生成匹配 contract 的值，我们定义一个函数，当给定 contract 和一些 fuel 时，它会编造一个随机函数。为了使其成为更有效的测试函数，我们可以对其接收到的任何参数进行针对性测试，并将它们保存到生成环境中，但前提是我们能够生成值域 contract 的值。
@interaction/no-prompt[#:eval
                       ex-eval
                       (define (simple-arrow-contract-generate arr)
                         (λ (fuel)
                           (define env (contract-random-generate-get-current-environment))
                           (define rng-generate 
                             (contract-random-generate/choose (simple-arrow-rng arr) fuel))
                           (cond
                             [rng-generate
                              (λ ()
                                (λ (arg)
                                  (contract-random-generate-stash env (simple-arrow-dom arr) arg)
                                  (rng-generate)))]
                             [else
                              #f])))]

当随机生成从环境中取出某个值时，它需要能够判断传递给 @racket[contract-random-generate-stash] 的值是否是它试图生成的 contract 的候选。当然，如果传递给 @racket[contract-random-generate-stash] 的 contract 是精确匹配的，那么它可以使用它。但如果 contract 更强（在接受更少值的意义上），它也可以使用该值。

为了提供该功能，我们实现这个函数：
@interaction/no-prompt[#:eval ex-eval
                              (define (simple-arrow-first-stronger? this that)
                                (and (simple-arrow? that)
                                     (contract-stronger? (simple-arrow-dom that)
                                                         (simple-arrow-dom this))
                                     (contract-stronger? (simple-arrow-rng this)
                                                         (simple-arrow-rng that))))]
这个函数接受 @racket[_this] 和 @racket[_that]，两个 contract。它保证 @racket[_this] 将是我们简单箭头 contract 中的一个，因为我们将这个函数与简单箭头实现一起提供。但 @racket[_that] 参数可能是任何 contract。这个函数检查 @racket[_that] 是否也是简单箭头 contract，如果是则比较域和值域。当然，还有其他我们可以检查的 contract（例如，使用 @racket[->] 或 @racket[->*] 构建的 contract），但我们不需要。更强函数允许在不知道答案时返回 @racket[#f]，但如果它返回 @racket[#t]，那么该 contract 必须真的更强。

现在我们已经实现了所有部分，需要将它们传递给 @racket[build-chaperone-contract-property] 以使 contract 系统开始使用它们：
@interaction/no-prompt[#:eval ex-eval
                              (struct simple-arrow (dom rng)
                                #:property prop:custom-write contract-custom-write-property-proc
                                #:property prop:chaperone-contract
                                (build-chaperone-contract-property
                                 #:name
                                 (λ (arr) (simple-arrow-name arr))
                                 #:late-neg-projection
                                 (λ (arr) (simple-arrow-late-neg-proj arr))
                                 #:first-order simple-arrow-first-order
                                 #:stronger simple-arrow-first-stronger?
                                 #:generate simple-arrow-contract-generate
                                 #:exercise simple-arrow-contract-exercise))
                              
                              (define (simple-arrow-contract dom rng)
                                (simple-arrow (coerce-contract 'simple-arrow-contract dom)
                                              (coerce-contract 'simple-arrow-contract rng)))]
我们还添加了 @racket[prop:custom-write] 属性以使 contract 正确打印，例如：
@interaction[#:eval ex-eval (simple-arrow-contract integer? integer?)]
（我们使用 @racket[prop:custom-write] 是因为 contract 库不能依赖于 @racketmod[racket/generic]，但仍想提供一些帮助使用正确的打印器。）

现在已经完成，我们可以使用新的功能。这里是一个由 contract 库使用我们的 @racket[simple-arrow-contract-generate] 函数生成的随机函数：
@def+int[#:eval 
         ex-eval
         (define a-random-function
           (contract-random-generate 
            (simple-arrow-contract integer? integer?)))
         (a-random-function 0)
         (a-random-function 1)]

这里是 contract 系统现在如何自动发现消耗简单箭头 contract 的函数中的 bug：
@def+int[#:eval 
         ex-eval
         (define/contract (misbehaved-f f)
           (-> (simple-arrow-contract integer? boolean?) any)
           (f "not an integer"))
         (contract-exercise misbehaved-f)]

如果我们没有实现 @racket[simple-arrow-first-order]，那么 @racket[or/c] 就无法知道在这个程序中使用 @racket[or/c] 的哪个分支：
@def+int[#:eval
         ex-eval
         (define/contract (maybe-accepts-a-function f)
           (or/c (simple-arrow-contract real? real?)
                 (-> real? real? real?)
                 real?)
           (if (procedure? f)
               (if (procedure-arity-includes f 1)
                   (f 1132)
                   (f 11 2))
               f))
         (maybe-accepts-a-function sqrt)
         (maybe-accepts-a-function 123)]

@(close-eval ex-eval)
