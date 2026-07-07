#lang scribble/doc
@(require "mz.rkt")

@title[#:tag "vectors"]{Vectors}

@guideintro["vectors"]{vectors}

一个 @deftech{vector} 是固定长度的数组，支持对 vector 槽位的常数时间
访问和更新，槽位编号从 @racket[0] 到 vector 槽数减一。

当两个 vector 长度相同且对应槽位的值 @racket[equal?] 时，
它们 @racket[equal?]。

Vector 可以是 @defterm{mutable} 或 @defterm{immutable}。当将 immutable vector
传给 @racket[vector-set!] 等过程时，会 @exnraise[exn:fail:contract]。默认 reader
生成的 vector(参见 @secref["parse-string"])是 immutable 的。使用
@racket[immutable?] 检查 vector 是否为 immutable。

Vector 可用作单值序列(参见 @secref["sequences"])。Vector 的元素
作为序列的元素。另参见 @racket[in-vector]。

字面量或打印的 vector 以 @litchar{#(} 开头，可选地在 @litchar{#} 和
@litchar{(} 之间加一个数字。@see-read-print["vector" #:print "vectors"]{vectors}

@defproc[(vector? [v any/c]) boolean?]{

如果 @racket[v] 是 vector 则返回 @racket[#t]，否则返回 @racket[#f]。

另参见 @racket[immutable-vector?] 和 @racket[mutable-vector?]。}

@defproc[(make-vector [size exact-nonnegative-integer?]
                      [v any/c 0]) vector?]{

返回一个有 @racket[size] 个槽位的 mutable vector，所有槽位初始化为
@racket[v]。注意 @racket[v] 被所有元素共享，因此对于 mutable 数据，
修改一个元素会影响其他元素。
@examples[
  (make-vector 3 2)
  (define v (make-vector 5 (box 3)))
  v
  (set-box! (vector-ref v 0) 7)
  v
]

该函数耗时与 @racket[size] 成正比。

常见错误是用 @racket[make-vector] 创建嵌套 vector。由于 @racket[v] 被所有元素共享，
因此 @racket[(make-vector 3 (make-vector 4))] 不是表示 mutable 3x4 矩阵的好方法，
因为只有一个 mutable vector 被共享了三次。如下使用 @racket[for/vector]
更可能产生预期结果，因为每次迭代都会单独求值 @racket[(make-vector 4)]：

@examples[
(for/vector ([i (in-range 3)])
  (make-vector 4))
]
}


@defproc[(vector [v any/c] ...) vector?]{

返回一个新分配的 mutable vector，槽位数量与提供的 @racket[v] 相同，
槽位按顺序初始化为给定的 @racket[v]。}


@defproc[(vector-immutable [v any/c] ...) (and/c vector?
                                                 immutable?)]{

返回一个新分配的 immutable vector，槽位数量与提供的 @racket[v] 相同，
槽位按顺序包含给定的 @racket[v]。}



@defproc[(vector-length [vec vector?]) exact-nonnegative-integer?]{

返回 @racket[vec] 的长度(即 vector 中的槽位数)。

该函数耗时恒定。}


@defproc[(vector-ref [vec vector?] [pos exact-nonnegative-integer?]) any/c]{

返回 @racket[vec] 中槽位 @racket[pos] 处的元素。第一个槽位是位置
@racket[0]，最后一个槽位是 @racket[(vector-length vec)] 减一。

该函数耗时恒定。}

@defproc[(vector-set! [vec (and/c vector? (not/c immutable?))]
                      [pos exact-nonnegative-integer?]
                      [v any/c])
         void?]{

更新 @racket[vec] 中槽位 @racket[pos] 以包含 @racket[v]。

该函数耗时恒定。}


@deftogether[(
@defproc[(vector*-length [vec (and/c vector? (not/c impersonator?))]) exact-nonnegative-integer?]
@defproc[(vector*-ref [vec (and/c vector? (not/c impersonator?))] [pos exact-nonnegative-integer?]) any/c]
@defproc[(vector*-set! [vec (and/c vector? (not/c immutable?)  (not/c impersonator?))]
                       [pos exact-nonnegative-integer?]
                       [v any/c])
         void?]
)]{

类似于 @racket[vector-length]、@racket[vector-ref] 和
@racket[vector-set!]，但仅限于操作非 @tech{impersonators} 的 vector。

@history[#:added "6.90.0.15"]}


@defproc[(vector-cas! [vec (and/c vector? (not/c immutable?) (not/c impersonator?))]
                      [pos exact-nonnegative-integer?]
                      [old-v any/c]
                      [new-v any/c])
         boolean?]{

Vector 的比较并交换操作。参见 @racket[box-cas!]。

@history[#:added "6.11.0.2"]
}

@defproc[(vector->list [vec vector?]) list?]{

返回一个与 @racket[vec] 长度和元素相同的 list。

该函数耗时与 @racket[vec] 的大小成正比。}


@defproc[(list->vector [lst list?]) vector?]{

返回一个与 @racket[lst] 长度和元素相同的 mutable vector。

该函数耗时与 @racket[lst] 的长度成正比。}


@defproc[(vector->immutable-vector [vec vector?])
         (and/c vector? immutable?)]{

返回一个与 @racket[vec] 长度和元素相同的 immutable vector。
如果 @racket[vec] 本身是 immutable 的，则直接返回它。

当 @racket[vec] 是 mutable 时，该函数耗时与 @racket[vec] 的大小成正比。}


@defproc[(vector-fill! [vec (and/c vector? (not/c immutable?))]
                       [v any/c])
         void?]{

将 @racket[vec] 的所有槽位改为包含 @racket[v]。

该函数耗时与 @racket[vec] 的大小成正比。}


@defproc[(vector-copy! [dest (and/c vector? (not/c immutable?))]
                       [dest-start exact-nonnegative-integer?]
                       [src vector?]
                       [src-start exact-nonnegative-integer? 0]
                       [src-end exact-nonnegative-integer? (vector-length src)])
         void?]{

 将 @racket[dest] 中从位置 @racket[dest-start] 开始的元素改为
 匹配 @racket[src] 中从 @racket[src-start](含)到 @racket[src-end](不含)
 的元素。@racket[dest] 和 @racket[src] 可以是同一个 vector，此时目标区域
 可能与源区域重叠；复制后目标元素匹配复制前的源元素。如果 @racket[dest-start]、
 @racket[src-start] 或 @racket[src-end] 超出范围(考虑 vector 的大小以及
 源和目标区域)，则 @exnraise[exn:fail:contract]。

该函数耗时与 @racket[(- src-end src-start)] 成正比。

@examples[(define v (vector 'A 'p 'p 'l 'e))
          (vector-copy! v 4 #(y))
          (vector-copy! v 0 v 3 4)
          v]}


@defproc[(vector->values [vec vector?]
                         [start-pos exact-nonnegative-integer? 0]
                         [end-pos exact-nonnegative-integer? (vector-length vec)])
         any]{

返回 @math{@racket[end-pos] - @racket[start-pos]} 个值，即 @racket[vec]
中从 @racket[start-pos](含)到 @racket[end-pos](不含)的元素。如果
@racket[start-pos] 或 @racket[end-pos] 大于 @racket[(vector-length vec)]，
或 @racket[end-pos] 小于 @racket[start-pos]，则 @exnraise[exn:fail:contract]。

该函数耗时与 @racket[vec] 的大小成正比。}

@defproc[(build-vector [n exact-nonnegative-integer?]
                       [proc (exact-nonnegative-integer? . -> . any/c)])
         vector?]{

创建一个有 @racket[n] 个元素的 vector，依次将 @racket[proc] 应用于
从 @racket[0] 到 @racket[(sub1 n)] 的整数。如果 @racket[_vec] 是结果 vector，
则 @racket[(vector-ref _vec _i)] 是 @racket[(proc _i)] 产生的值。

@examples[
(build-vector 5 add1)
]}

@; ----------------------------------------
@section[#:tag "vectors-s1"]{Additional Vector Functions}

@note-lib[racket/vector]
@(define vec-eval (make-base-eval))
@examples[#:hidden #:eval vec-eval
          (require racket/vector)]

@defproc[(vector-empty? [v vector?]) boolean?]{

如果 @racket[v] 为空(即长度为 0)则返回 @racket[#t]，否则返回 @racket[#f]。

@history[#:added "7.4.0.4"]}

@defproc[(vector-set*! [vec (and/c vector? (not/c immutable?))]
                       [pos exact-nonnegative-integer?]
                       [v any/c]
                       ...
                       ...)
         void?]{

更新 @racket[vec] 中每个槽位 @racket[pos] 以包含每个 @racket[v]。
更新从左到右进行，因此后面的更新会覆盖前面的更新。}

@defproc[(vector-map [proc procedure?] [vec vector?] ...+)
         vector?]{

将 @racket[proc] 应用于 @racket[vec] 的元素，从第一个到最后一个。
@racket[proc] 参数必须接受与提供的 @racket[vec] 数量相同的参数，
且所有 @racket[vec] 必须具有相同数量的元素。结果是一个新 vector，
按顺序包含 @racket[proc] 的每个结果。

@mz-examples[#:eval vec-eval
(vector-map + #(1 2) #(3 4))]
}

@defproc[(vector-map! [proc procedure?] [vec (and/c vector? (not/c immutable?))] ...+)
         vector?]{

类似于 @racket[vector-map]，但 @racket[proc] 的结果被插入到第一个
@racket[vec] 中参数来源的索引处。结果是第一个 @racket[vec]。

@mz-examples[#:eval vec-eval
(define v (vector 1 2 3 4))
(vector-map! add1 v)
v
]}

@defproc[(vector-append [vec vector?] ...) vector?]{

创建一个新 vector，按顺序包含所有给定 vector 的元素。

@mz-examples[#:eval vec-eval
(vector-append #(1 2) #(3 4))]
}


@defproc[(vector-take [vec vector?] [pos exact-nonnegative-integer?]) vector?]{
返回一个新 vector，其元素是 @racket[vec] 的前 @racket[pos] 个元素。
如果 @racket[vec] 的元素少于 @racket[pos] 个，则 @exnraise[exn:fail:contract]。

@mz-examples[#:eval vec-eval
 (vector-take #(1 2 3 4) 2)
]}

@defproc[(vector-take-right [vec vector?] [pos exact-nonnegative-integer?]) vector?]{
返回一个新 vector，其元素是 @racket[vec] 的最后 @racket[pos] 个元素。
如果 @racket[vec] 的元素少于 @racket[pos] 个，则 @exnraise[exn:fail:contract]。

@mz-examples[#:eval vec-eval
 (vector-take-right #(1 2 3 4) 2)
]}

@defproc[(vector-drop [vec vector?] [pos exact-nonnegative-integer?]) vector?]{
返回一个新 vector，其元素是 @racket[vec] 中前 @racket[pos] 个元素
之后的元素。如果 @racket[vec] 的元素少于 @racket[pos] 个，
则 @exnraise[exn:fail:contract]。

@mz-examples[#:eval vec-eval
 (vector-drop #(1 2 3 4) 2)
]}

@defproc[(vector-drop-right [vec vector?] [pos exact-nonnegative-integer?]) vector?]{
返回一个新 vector，其元素是 @racket[vec] 的前缀，去掉长度为
@racket[pos] 的后缀。如果 @racket[vec] 的元素少于 @racket[pos] 个，
则 @exnraise[exn:fail:contract]。

@mz-examples[#:eval vec-eval
 (vector-drop-right #(1 2 3 4) 1)
 (vector-drop-right #(1 2 3 4) 3)
]}

@defproc[(vector-split-at [vec vector?] [pos exact-nonnegative-integer?])
         (values vector? vector?)]{
返回与

@racketblock[(values (vector-take vec pos) (vector-drop vec pos))]

相同的结果，但可能更快。

@mz-examples[#:eval vec-eval
 (vector-split-at #(1 2 3 4 5) 2)
]}

@defproc[(vector-split-at-right [vec vector?] [pos exact-nonnegative-integer?])
         (values vector? vector?)]{
返回与

@racketblock[(values (vector-take-right vec pos) (vector-drop-right vec pos))]

相同的结果，但可能更快。

@mz-examples[#:eval vec-eval
 (vector-split-at-right #(1 2 3 4 5) 2)
]}


@defproc[(vector-copy [vec vector?]
                      [start exact-nonnegative-integer? 0]
                      [end exact-nonnegative-integer? (vector-length v)])
         vector?]{

创建一个大小为 @racket[(- end start)] 的新 vector，包含 @racket[vec]
中从 @racket[start](含)到 @racket[end](不含)的所有元素。

@mz-examples[#:eval vec-eval
 (vector-copy #(1 2 3 4))
 (vector-copy #(1 2 3 4) 3)
 (vector-copy #(1 2 3 4) 2 3)
]
}

@defproc[(vector-set/copy [vec vector?]
                          [pos exact-nonnegative-integer?]
                          [val any/c])
         vector?]{

创建一个内容与 @racket[vec] 相同的新 vector，但索引 @racket[pos]
处的元素为 @racket[val]。

@mz-examples[#:eval vec-eval
 (vector-set/copy #(1 2 3) 0 'x)
 (vector-set/copy #(1 2 3) 2 'x)
]

@history[#:added "8.11.1.10"]}

@defproc[(vector-extend [vec vector?]
                        [new-size (and/c exact-nonnegative-integer? (>=/c (vector-length vec)))]
                        [val any/c 0])
         vector?]{

创建一个长度为 @racket[new-size] 的新 vector，前缀由 @racket[vec]
的元素填充，其余部分由 @racket[val] 填充。 

@mz-examples[#:eval vec-eval
 (vector-extend #(1 2 3) 10)
 (vector-extend #(1 2 3) 10 #f)
 (vector-extend #(1 2 3) 3 #f)
]

@history[#:added "8.12.0.10"]}


@defproc[(vector-filter [pred procedure?] [vec vector?]) vector?]{
返回一个新 vector，包含 @racket[vec] 中 @racket[pred] 产生真值的元素。
@racket[pred] 过程应用于每个元素，从第一个到最后一个。

@mz-examples[#:eval vec-eval
  (vector-filter even? #(1 2 3 4 5 6))
]}

@defproc[(vector-filter-not [pred procedure?] [vec vector?]) vector?]{

类似于 @racket[vector-filter]，但 @racket[pred] 谓词的含义反转：
结果是 @racket[pred] 返回 @racket[#f] 的所有项的 vector。

@mz-examples[#:eval vec-eval
  (vector-filter-not even? #(1 2 3 4 5 6))
]}


@defproc[(vector-count [proc procedure?] [vec vector?] ...+)
         exact-nonnegative-integer?]{

返回 @racket[vec ...](并行取值)中 @racket[proc] 不求值为 @racket[#f]
的元素数量。

@mz-examples[#:eval vec-eval
(vector-count even? #(1 2 3 4 5))
(vector-count = #(1 2 3 4 5) #(5 4 3 2 1))]
}


@defproc[(vector-argmin [proc (-> any/c real?)] [vec vector?]) any/c]{

返回非空 vector @racket[vec] 中使 @racket[proc] 结果最小的第一个元素。

@mz-examples[#:eval vec-eval
(vector-argmin car #((3 pears) (1 banana) (2 apples)))
(vector-argmin car #((1 banana) (1 orange)))
]
}

@defproc[(vector-argmax [proc (-> any/c real?)] [vec vector?]) any/c]{

返回非空 vector @racket[vec] 中使 @racket[proc] 结果最大的第一个元素。

@mz-examples[#:eval vec-eval
(vector-argmax car #((3 pears) (1 banana) (2 apples)))
(vector-argmax car #((3 pears) (3 oranges)))
]
}


@defproc[(vector-member [v any/c] [vec vector?] [is-equal? (-> any/c any/c any/c) equal?])
         (or/c natural-number/c #f)]{

定位 @racket[vec] 中按 @racket[is-equal?] 等于 @racket[v] 的第一个元素。
如果存在这样的元素，返回其在 @racket[vec] 中的索引。否则结果为 @racket[#f]。

@mz-examples[#:eval vec-eval
(vector-member 2 (vector 1 2 3 4))
(vector-member 9 (vector 1 2 3 4))
(vector-member 1.0 (vector 1 2 3 4) =)
]

@history[#:changed "8.15.0.1" @elem{Added the @racket[is-equal?] argument.}]}


@defproc[(vector-memv [v any/c] [vec vector?])
         (or/c natural-number/c #f)]{

类似于 @racket[vector-member]，但使用 @racket[eqv?] 查找元素。
@mz-examples[#:eval vec-eval
(vector-memv 2 (vector 1 2 3 4))
(vector-memv 9 (vector 1 2 3 4))
]}


@defproc[(vector-memq [v any/c] [vec vector?])
         (or/c natural-number/c #f)]{

类似于 @racket[vector-member]，但使用 @racket[eq?] 查找元素。

@mz-examples[#:eval vec-eval
(vector-memq 2 (vector 1 2 3 4))
(vector-memq 9 (vector 1 2 3 4))
]}

@defproc[(vector-sort [vec vector?]
                      [less-than? (any/c any/c . -> . any/c)]
                      [start exact-nonnegative-integer? 0]
                      [end (or/c #f exact-nonnegative-integer?) #f]
                      [#:key key (or/c #f (any/c . -> . any/c)) #f]
                      [#:cache-keys? cache-keys? boolean? #f])
         vector?]{

 类似于 @racket[sort]，但操作于 vector；返回一个长度为
 @racket[(- end start)] 的 @emph{新} vector，包含 @racket[vec] 中从索引
 @racket[start](含)到 @racket[end](不含)的元素，但按排序顺序
 (即 @racket[vec] 不被修改)。此排序是稳定的(即"相等"元素的
 顺序被保留)。

 如果 @racket[end] 是 @racket[#f]，则替换为
 @racket[(vector-length vec)]。

@mz-examples[#:eval vec-eval
(define v1 (vector 4 3 2 1))
v1
(vector-sort v1 <)
v1
(vector-sort v1 < 2 #f #:key #f)
v1
(define v2 (vector '(4) '(3) '(2) '(1)))
v2
(vector-sort v2 < 1 3 #:key car)
v2
]

@history[#:added "6.6.0.5"]{}
}

@defproc[(vector-sort! [vec (and/c vector? (not/c immutable?))]
                       [less-than? (any/c any/c . -> . any/c)]
                       [start exact-nonnegative-integer? 0]
                       [end (or/c #f exact-nonnegative-integer?) #f]
                       [#:key key (or/c #f (any/c . -> . any/c)) #f]
                       [#:cache-keys? cache-keys? boolean? #f])
         void?]{

 类似于 @racket[vector-sort]，但通过按 @racket[less-than?]
 过程排序来 @emph{更新} @racket[vec] 中从 @racket[start](含)到
 @racket[end](不含)的索引。

@mz-examples[#:eval vec-eval
(define v1 (vector 4 3 2 1))
v1
(vector-sort! v1 <)
v1
(define v2 (vector 4 3 2 1))
v2
(vector-sort! v2 < 2 #f #:key #f)
v2
(define v3 (vector '(4) '(3) '(2) '(1)))
v3
(vector-sort! v3 < 1 3 #:key car)
v3
]

@history[#:added "6.6.0.5"]{}
}


@deftogether[(
@defproc[(vector*-copy [vec (and/c vector? (not/c impersonator?))]
                       [start exact-nonnegative-integer? 0]
                       [end exact-nonnegative-integer? (vector-length v)])
          vector?]
@defproc[(vector*-append [vec (and/c vector? (not/c impersonator?))] ...) vector?]
@defproc[(vector*-set/copy [vec (and/c vector? (not/c impersonator?))]
                           [pos exact-nonnegative-integer?]
                           [val any/c])
         vector?]
@defproc[(vector*-extend [vec (and/c vector? (not/c impersonator?))]
                         [pos exact-nonnegative-integer?]
                         [val any/c 0])
         vector?]
)]{

类似于 @racket[vector-copy]、@racket[vector-append]、
@racket[vector-set/copy] 和 @racket[vector-extend]，但仅限于操作
非 @tech{impersonators} 的 vector。

@history[#:added "8.11.1.10"
         #:changed "8.12.0.10" @elem{Added @racket[vector*-extend].}]}


@close-eval[vec-eval]
