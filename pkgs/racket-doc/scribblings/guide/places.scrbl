#lang scribble/doc
@(require scribble/manual "guide-utils.rkt"
          (for-label racket/flonum racket/place))

@title[#:tag "effective-places"]{Parallelism with Places}

@racketmodname[racket/place] 库提供了通过 @racket[place] 形式进行并行性提高性能的支持。@racket[place] 形式创建一个 @deftech{place}，有效地成为可以与其他 place（包括初始 place）并行运行的新 Racket 实例。Racket 语言的完整功能在每个 place 都可用，但 place 只能通过消息传递进行通信——在有限的一组值上使用 @racket[place-channel-put] 和 @racket[place-channel-get] 函数——这有助于确保并行计算的安全性和独立性。

作为初始示例，下面的 Racket 程序使用 place 来确定列表中是否有数字的double也在列表中：

@codeblock{
#lang racket

(provide main)

(define (any-double? l)
  (for/or ([i (in-list l)])
    (for/or ([i2 (in-list l)])
      (= i2 (* 2 i)))))

(define (main)
  (define p 
    (place ch
      (define l (place-channel-get ch))
      (define l-double? (any-double? l))
      (place-channel-put ch l-double?)))

  (place-channel-put p (list 1 2 4 8))
  
  (place-channel-get p))
}

@racket[place] 后的标识符 @racket[ch] 绑定到 @deftech{place channel}。@racket[place] form 中其余的 body 表达式在新 place 中求值，body 表达式使用 @racket[ch] 与产生新 place 的 place 进行通信。

在上述 @racket[place] form 的 body 中，新 place 通过 @racket[ch] 接收数字列表并将列表绑定到 @racket[l]。然后它调用 @racket[any-double?] 处理列表并将结果绑定到 @racket[l-double?]。最后的 body 表达式将 @racket[l-double?] 结果通过 @racket[ch] 发送回原始 place。

在 DrRacket 中，保存并运行上述程序后，在交互窗口中求值 @racket[(main)] 以创建新 place。@margin-note*{在 DrRacket 内使用 @tech{places} 时，包含 place 代码的 module 必须在执行前保存到文件中。} 或者，将程序另存为 @filepath{double.rkt} 并使用命令行运行

@commandline{racket -tm double.rkt}

其中 @Flag{t} 标志告诉 @exec{racket} 加载 @tt{double.rkt} module，@Flag{m} 标志调用导出的 @racket[main] 函数，@Flag{tm} 将两个标志组合起来。

@racket[place] 形式有两个微妙的特性。首先，它将 @racket[place] body 提升为匿名的模块级函数。这种提升意味着 @racket[place] body 引用的任何绑定必须在模块的顶级可用。其次，@racket[place] 形式在新建的 place 中 @racket[dynamic-require] 封闭的 module。作为 @racket[dynamic-require] 的一部分，当前 module body 在新 place 中求值。第二个特性的结果是 @racket[place] 不应直接出现在 module 中或在模块顶级调用的函数中；否则，调用模块将在新 place 中调用同一模块，依此类推，触发一系列 place 创建，很快耗尽内存。

@codeblock{
#lang racket

(provide main)

; 不要这样做！
(define p (place ch (place-channel-get ch)))

(define (indirect-place-invocation)
  (define p2 (place ch (place-channel-get ch))))

; 也不要这样做！
(indirect-place-invocation)
}
