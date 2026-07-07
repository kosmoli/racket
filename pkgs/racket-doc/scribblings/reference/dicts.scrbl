#lang scribble/doc
@(require "mz.rkt" (for-label racket/generic))

@(define dict-eval (make-base-eval))
@examples[#:hidden #:eval dict-eval
          (require racket/dict racket/generic racket/contract racket/string)]

@title[#:tag "dicts"]{Dictionaries}

@deftech{dictionary}（字典）是一种将键映射到值的数据类型的实例。以下数据类型都是字典：

@itemize[

 @item{@techlink{hash tables};}

 @item{@techlink{vectors} (using only exact integers as keys);}

 @item{@techlink{lists} of @techlink{pairs} 作为 @deftech{association
       list}（关联列表），使用 @racket[equal?] 比较键，键必须互不相同；以及}

 @item{实现了 @racket[gen:dict] @tech{generic interface} 的 @techlink{structures}。}

]

当 pair 的列表用作 @tech{association list} 但键不互不相同时（因此它不是真正的 association list），@racket[dict-ref] 和 @racket[dict-remove] 等操作作用于键的第一个实例，而 @racket[dict-map] 和 @racket[dict-keys] 等操作则为键的每个实例产生一个元素。

@note-lib[racket/dict]

@section[#:tag "dicts-s1"]{Dictionary Predicates and Contracts}

@defproc[(dict? [v any/c]) boolean?]{

如果 @racket[v] 是一个 @tech{dictionary}，返回 @racket[#t]，否则返回 @racket[#f]。

注意，@racket[dict?] 对 pair 不是常数时间的测试，因为检查 @racket[v] 是否是 @tech{association list} 可能需要遍历整个列表。

@examples[
#:eval dict-eval
(dict? #hash((a . "apple")))
(dict? '#("apple" "banana"))
(dict? '("apple" "banana"))
(dict? '((a . "apple") (b . "banana")))
]}

@defproc[(dict-implements? [d dict?] [sym symbol?] ...) boolean?]{

如果 @racket[d] 实现了 @racket[gen:dict] 中由 @racket[sym] 命名的所有方法，返回 @racket[#t]；否则返回 @racket[#f]。回退实现不影响结果；@racket[d] 可能通过回退实现支持给定方法但仍返回 @racket[#f]。

@examples[
#:eval dict-eval
(dict-implements? (hash 'a "apple") 'dict-set!)
(dict-implements? (make-hash '((a . "apple") (b . "banana"))) 'dict-set!)
(dict-implements? (make-hash '((b . "banana") (a . "apple"))) 'dict-remove!)
(dict-implements? (vector "apple" "banana") 'dict-set!)
(dict-implements? (vector 'a 'b) 'dict-remove!)
(dict-implements? (vector 'a "apple") 'dict-set! 'dict-remove!)
]

}

@defproc[(dict-implements/c [sym symbol?] ...) flat-contract?]{

识别支持 @racket[gen:dict] 中由 @racket[sym] 命名的所有方法的字典。注意，生成的 contract 与 @racket[hash/c] 不同，而更接近 @racket[dict-implements?]。
@examples[
 #:eval dict-eval
 (struct deformed-dict ()
   #:methods gen:dict [])
 (define/contract good-dict
   (dict-implements/c)
   (deformed-dict))
 (eval:error
  (define/contract bad-dict
    (dict-implements/c 'dict-ref)
    (deformed-dict)))]

}


@defproc[(dict-mutable? [d dict?]) boolean?]{

如果 @racket[d] 可通过 @racket[dict-set!] 修改，返回 @racket[#t]，否则返回 @racket[#f]。

等价于 @racket[(dict-implements? d 'dict-set!)]。

@examples[
#:eval dict-eval
(dict-mutable? #hash((a . "apple")))
(dict-mutable? (make-hash))
(dict-mutable? '#("apple" "banana"))
(dict-mutable? (vector "apple" "banana"))
(dict-mutable? '((a . "apple") (b . "banana")))
]}



@defproc[(dict-can-remove-keys? [d dict?]) boolean?]{

如果 @racket[d] 支持通过 @racket[dict-remove!] 和/或 @racket[dict-remove] 删除映射，返回 @racket[#t]，否则返回 @racket[#f]。

等价于
@racket[(or (dict-implements? d 'dict-remove!) (dict-implements? d 'dict-remove))]。

@examples[
#:eval dict-eval
(dict-can-remove-keys? #hash((a . "apple")))
(dict-can-remove-keys? '#("apple" "banana"))
(dict-can-remove-keys? '((a . "apple") (b . "banana")))
]}


@defproc[(dict-can-functional-set? [d dict?]) boolean?]{

如果 @racket[d] 支持通过 @racket[dict-set] 进行函数式更新，返回 @racket[#t]，否则返回 @racket[#f]。

等价于 @racket[(dict-implements? d 'dict-set)]。

@examples[
#:eval dict-eval
(dict-can-functional-set? #hash((a . "apple")))
(dict-can-functional-set? (make-hash))
(dict-can-functional-set? '#("apple" "banana"))
(dict-can-functional-set? '((a . "apple") (b . "banana")))
]}

@section[#:tag "dicts-s2"]{Generic Dictionary Interface}

@defidform[gen:dict]{

一个 @tech{generic interface}（参见 @secref["struct-generics"]），通过 @racket[struct] 定义的 @racket[#:methods] 选项为结构类型提供字典方法实现。此接口可用于实现 @secref["primitive-dict-methods"] 和 @secref["derived-dict-methods"] 中记录的任何方法。

@examples[#:eval dict-eval
(struct alist (v)
  #:methods gen:dict
  [(define (dict-ref dict key
                     [default (lambda () (error "key not found" key))])
     (cond [(assoc key (alist-v dict)) => cdr]
           [else (if (procedure? default) (default) default)]))
   (define (dict-set dict key val)
     (alist (cons (cons key val) (alist-v dict))))
   (define (dict-remove dict key)
     (define al (alist-v dict))
     (alist (remove* (filter (λ (p) (equal? (car p) key)) al) al)))
   (define (dict-count dict)
     (length (remove-duplicates (alist-v dict) #:key car)))]) (code:comment "etc. other methods")

  (define d1 (alist '((1 . a) (2 . b))))
  (dict? d1)
  (dict-ref d1 1)
  (dict-remove d1 1)
]

}

@defthing[prop:dict struct-type-property?]{
  一个结构类型属性，用于定义字典 API 的自定义扩展。不建议使用 @racket[prop:dict] 属性；请改用 @racket[gen:dict] @tech{generic interface}。接受一个包含 10 个方法实现的向量：

  @itemize[
           @item{@racket[dict-ref]}
           @item{@racket[dict-set!], or @racket[#f] if unsupported}
           @item{@racket[dict-set], or @racket[#f] if unsupported}
           @item{@racket[dict-remove!], or @racket[#f] if unsupported}
           @item{@racket[dict-remove], or @racket[#f] if unsupported}
           @item{@racket[dict-count]}
           @item{@racket[dict-iterate-first]}
           @item{@racket[dict-iterate-next]}
           @item{@racket[dict-iterate-key]}
           @item{@racket[dict-iterate-value]}
           ]
}

@subsection[#:tag "primitive-dict-methods"]{Primitive Dictionary Methods}

这些 @racket[gen:dict] 方法没有回退实现；仅支持直接实现它们的字典类型。

@defproc[(dict-ref [dict dict?]
                   [key any/c]
                   [failure-result failure-result/c
                                   (lambda () (raise (make-exn:fail ....)))])
         any]{

返回 @racket[dict] 中 @racket[key] 对应的值。如果未找到 @racket[key] 的值，则 @racket[failure-result] 决定结果：

@itemize[

 @item{如果 @racket[failure-result] 是一个过程，则通过尾调用以无参数方式调用它来产生结果。}

 @item{否则，@racket[failure-result] 作为结果返回。}

]

@examples[
#:eval dict-eval
(dict-ref #hash((a . "apple") (b . "beer")) 'a)
(eval:error (dict-ref #hash((a . "apple") (b . "beer")) 'c))
(dict-ref #hash((a . "apple") (b . "beer")) 'c #f)
(dict-ref '((a . "apple") (b . "banana")) 'b)
(dict-ref #("apple" "banana") 1)
(dict-ref #("apple" "banana") 3 #f)
(eval:error (dict-ref #("apple" "banana") -3 #f))
]}

@defproc[(dict-set! [dict (and/c dict? (not/c immutable?))]
                    [key any/c]
                    [v any/c]) void?]{

在 @racket[dict] 中将 @racket[key] 映射到 @racket[v]，覆盖 @racket[key] 的任何现有映射。如果 @racket[dict] 不可变或 @racket[key] 不是该字典允许的键（例如，当 @racket[dict] 是 @tech{vector} 时不是适当范围内的精确整数），更新可能抛出 @racket[exn:fail:contract] 异常而失败。

@examples[
#:eval dict-eval
(define h (make-hash))
(dict-set! h 'a "apple")
h
(define v (vector #f #f #f))
(dict-set! v 0 "apple")
v
]}

@defproc[(dict-set [dict (and/c dict? immutable?)]
                   [key any/c]
                   [v any/c])
          (and/c dict? immutable?)]{

通过将 @racket[key] 映射到 @racket[v] 来函数式扩展 @racket[dict]，覆盖 @racket[key] 的任何现有映射，并返回扩展后的字典。如果 @racket[dict] 不支持函数式扩展或 @racket[key] 不是该字典允许的键，更新可能抛出 @racket[exn:fail:contract] 异常而失败。

@examples[
#:eval dict-eval
(dict-set #hash() 'a "apple")
(dict-set #hash((a . "apple") (b . "beer")) 'b "banana")
(dict-set '() 'a "apple")
(dict-set '((a . "apple") (b . "beer")) 'b "banana")
]}


@defproc[(dict-remove! [dict (and/c dict? (not/c immutable?))]
                       [key any/c])
         void?]{

删除 @racket[dict] 中 @racket[key] 的任何现有映射。如果 @racket[dict] 不可变或不支持删除键（例如 @tech{vectors} 的情况），更新可能失败。

@examples[
#:eval dict-eval
(define h (make-hash))
(dict-set! h 'a "apple")
h
(dict-remove! h 'a)
h]}


@defproc[(dict-remove [dict (and/c dict? immutable?)]
                      [key any/c])
         (and/c dict? immutable?)]{

函数式删除 @racket[dict] 中 @racket[key] 的任何现有映射，返回新的字典。如果 @racket[dict] 不支持函数式更新或不支持删除键，更新可能失败。

@examples[
#:eval dict-eval
(define h #hash())
(define h (dict-set h 'a "apple"))
h
(dict-remove h 'a)
h
(dict-remove h 'z)
(dict-remove '((a . "apple") (b . "banana")) 'a)
]}


@defproc[(dict-iterate-first [dict dict?]) any/c]{

如果 @racket[dict] 不包含元素，返回 @racket[#f]，否则返回一个非 @racket[#f] 的值作为字典表中第一个元素的索引；``first'' 指字典元素的未指定排序。对于可变的 @racket[dict]，只要没有向 @racket[dict] 添加或删除映射，此索引保证指向第一个元素。

@examples[
#:eval dict-eval
(dict-iterate-first #hash((a . "apple") (b . "banana")))
(dict-iterate-first #hash())
(dict-iterate-first #("apple" "banana"))
(dict-iterate-first '((a . "apple") (b . "banana")))
]}


@defproc[(dict-iterate-next [dict dict?]
                            [pos any/c])
         any/c]{

返回 @racket[dict] 中 @racket[pos] 索引之后的元素的索引（非 @racket[#f]），如果 @racket[pos] 指向 @racket[dict] 的最后一个元素则返回 @racket[#f]。如果 @racket[pos] 不是有效索引，则抛出 @exnraise[exn:fail:contract] 异常。对于可变的 @racket[dict]，只要没有添加或删除元素，结果索引保证指向其元素。@racket[dict-iterate-next] 操作应为常数时间。

@examples[
#:eval dict-eval
(define h #hash((a . "apple") (b . "banana")))
(define i (dict-iterate-first h))
i
(dict-iterate-next h i)
(dict-iterate-next h (dict-iterate-next h i))
]}


@defproc[(dict-iterate-key [dict dict?]
                           [pos any/c])
         any]{

返回 @racket[dict] 中索引 @racket[pos] 处元素的键。如果 @racket[pos] 不是 @racket[dict] 的有效索引，则抛出 @exnraise[exn:fail:contract] 异常。@racket[dict-iterate-key] 操作应为常数时间。

@examples[
#:eval dict-eval
(define h '((a . "apple") (b . "banana")))
(define i (dict-iterate-first h))
(dict-iterate-key h i)
(dict-iterate-key h (dict-iterate-next h i))
]}



@defproc[(dict-iterate-value [dict dict?]
                             [pos any/c])
         any]{

返回 @racket[dict] 中索引 @racket[pos] 处元素的值。如果 @racket[pos] 不是 @racket[dict] 的有效索引，则抛出 @exnraise[exn:fail:contract] 异常。@racket[dict-iterate-key] 操作应为常数时间。

@examples[
#:eval dict-eval
(define h '((a . "apple") (b . "banana")))
(define i (dict-iterate-first h))
(dict-iterate-value h i)
(dict-iterate-value h (dict-iterate-next h i))
]}

@subsection[#:tag "derived-dict-methods"]{Derived Dictionary Methods}

这些 @racket[gen:dict] 方法基于其他方法有回退实现；即使未直接实现它们的字典类型也可能支持这些方法。

@defproc[(dict-has-key? [dict dict?] [key any/c])
         boolean?]{

如果 @racket[dict] 包含给定 @racket[key] 的值，返回 @racket[#t]，否则返回 @racket[#f]。

任何实现了 @racket[dict-ref] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(dict-has-key? #hash((a . "apple") (b . "beer")) 'a)
(dict-has-key? #hash((a . "apple") (b . "beer")) 'c)
(dict-has-key? '((a . "apple") (b . "banana")) 'b)
(dict-has-key? #("apple" "banana") 1)
(dict-has-key? #("apple" "banana") 3)
(dict-has-key? #("apple" "banana") -3)
]}

@defproc[(dict-set*! [dict (and/c dict? (not/c immutable?))]
                     [key any/c]
                     [v any/c]
                     ...
                     ...) void?]{

在 @racket[dict] 中将每个 @racket[key] 映射到对应的 @racket[v]，覆盖每个 @racket[key] 的任何现有映射。如果 @racket[dict] 不可变或任何 @racket[key] 不是该字典允许的键（例如，当 @racket[dict] 是 @tech{vector} 时不是适当范围内的精确整数），更新可能抛出 @racket[exn:fail:contract] 异常而失败。更新从左到右进行，因此后面的映射覆盖前面的映射。

任何实现了 @racket[dict-set!] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define h (make-hash))
(dict-set*! h 'a "apple" 'b "banana")
h
(define v1 (vector #f #f #f))
(dict-set*! v1 0 "apple" 1 "banana")
v1
(define v2 (vector #f #f #f))
(dict-set*! v2 0 "apple" 0 "banana")
v2
]}

@defproc[(dict-set* [dict (and/c dict? immutable?)]
                    [key any/c]
                    [v any/c]
                    ...
                    ...)
          (and/c dict? immutable?)]{

通过将每个 @racket[key] 映射到对应的 @racket[v] 来函数式扩展 @racket[dict]，覆盖每个 @racket[key] 的任何现有映射，并返回扩展后的字典。如果 @racket[dict] 不支持函数式扩展或任何 @racket[key] 不是该字典允许的键，更新可能抛出 @racket[exn:fail:contract] 异常而失败。更新从左到右进行，因此后面的映射覆盖前面的映射。

任何实现了 @racket[dict-set] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(dict-set* #hash() 'a "apple" 'b "beer")
(dict-set* #hash((a . "apple") (b . "beer")) 'b "banana" 'a "anchor")
(dict-set* '() 'a "apple" 'b "beer")
(dict-set* '((a . "apple") (b . "beer")) 'b "banana" 'a "anchor")
(dict-set* '((a . "apple") (b . "beer")) 'b "banana" 'b "ballistic")
]}

@defproc[(dict-ref! [dict dict?]
                    [key any/c]
                    [to-set any/c])
         any]{

返回 @racket[dict] 中 @racket[key] 对应的值。如果未找到 @racket[key] 的值，则 @racket[to-set] 如 @racket[dict-ref] 中一样决定结果（即它可以是计算值的 thunk 或普通值），并且此结果被存储在 @racket[dict] 中对应的 @racket[key]。（注意，如果 @racket[to-set] 是 thunk，它不在尾位置被调用。）

任何实现了 @racket[dict-ref] 和 @racket[dict-set!] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(dict-ref! (make-hasheq '((a . "apple") (b . "beer"))) 'a #f)
(dict-ref! (make-hasheq '((a . "apple") (b . "beer"))) 'c 'cabbage)
(define h (make-hasheq '((a . "apple") (b . "beer"))))
(eval:error (dict-ref h 'c))
(dict-ref! h 'c (λ () 'cabbage))
(dict-ref h 'c)
]}

@defproc[(dict-update! [dict (and/c dict? (not/c immutable?))]
                       [key any/c]
                       [updater (any/c . -> . any/c)]
                       [failure-result failure-result/c
                                       (lambda () (raise (make-exn:fail ....)))]) void?]{

组合 @racket[dict-ref] 和 @racket[dict-set!] 来更新 @racket[dict] 中的现有映射，当 @racket[key] 的映射不存在时，可选的 @racket[failure-result] 参数如 @racket[dict-ref] 中一样使用。

任何实现了 @racket[dict-ref] 和 @racket[dict-set!] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define h (make-hash))
(eval:error (dict-update! h 'a add1))
(dict-update! h 'a add1 0)
h
(define v (vector #f #f #f))
(dict-update! v 0 not)
v
]}


@defproc[(dict-update [dict dict?]
                      [key any/c]
                      [updater (any/c . -> . any/c)]
                      [failure-result failure-result/c
                                      (lambda () (raise (make-exn:fail ....)))])
          (and/c dict? immutable?)]{

组合 @racket[dict-ref] 和 @racket[dict-set] 来函数式更新 @racket[dict] 中的现有映射，当 @racket[key] 的映射不存在时，可选的 @racket[failure-result] 参数如 @racket[dict-ref] 中一样使用。

任何实现了 @racket[dict-ref] 和 @racket[dict-set] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(eval:error (dict-update #hash() 'a add1))
(dict-update #hash() 'a add1 0)
(dict-update #hash((a . "apple") (b . "beer")) 'b string-length)
]}


@defproc[(dict-map [dict dict?]
                   [proc (any/c any/c . -> . any/c)])
         (listof any/c)]{

以未指定的顺序对 @racket[dict] 中的每个元素应用过程 @racket[proc]，将结果累积到列表中。过程 @racket[proc] 每次被调用时接收一个键及其值。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next]、@racket[dict-iterate-key] 和 @racket[dict-iterate-value] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(dict-map #hash((a . "apple") (b . "banana")) vector)
]}


@defproc[(dict-map/copy [dict dict?]
                        [proc (any/c any/c . -> . (values any/c any/c))])
         dict?]{

以未指定的顺序对 @racket[dict] 中的每个元素应用过程 @racket[proc]，将结果累积到同类型的字典中。过程 @racket[proc] 每次被调用时接收一个键及其值，必须返回对应的键和值。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next]、@racket[dict-iterate-key] 和 @racket[dict-iterate-value]，以及 @racket[dict-set] 和 @racket[dict-clear]，或 @racket[dict-set!]、@racket[dict-copy] 和 @racket[dict-clear!] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(dict-map/copy #hash((a . "apple") (b . "banana")) (lambda (k v) (values k (string-upcase v))))
]

@history[#:added "8.5.0.2"]}


@defproc[(dict-for-each [dict dict?]
                        [proc (any/c any/c . -> . any)])
         void?]{

以未指定的顺序对 @racket[dict] 中的每个元素应用 @racket[proc]（为了 @racket[proc] 的副作用）。过程 @racket[proc] 每次被调用时接收一个键及其值。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next]、@racket[dict-iterate-key] 和 @racket[dict-iterate-value] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(dict-for-each #hash((a . "apple") (b . "banana"))
               (lambda (k v)
                 (printf "~a = ~s\n" k v)))
]}


@defproc[(dict-empty? [dict dict?]) boolean?]{

报告 @racket[dict] 是否为空。

任何实现了 @racket[dict-iterate-first] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(dict-empty? #hash((a . "apple") (b . "banana")))
(dict-empty? (vector))
]

}

@defproc[(dict-count [dict dict?])
         exact-nonnegative-integer?]{

返回 @racket[dict] 映射的键数量，通常为常数时间。

任何实现了 @racket[dict-iterate-first] 和 @racket[dict-iterate-next] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(dict-count #hash((a . "apple") (b . "banana")))
(dict-count #("apple" "banana"))
]}

@defproc[(dict-copy [dict dict?]) dict?]{

产生一个新的、可变的字典，与 @racket[dict] 类型相同且具有相同的键/值关联。

任何实现了 @racket[dict-clear]、@racket[dict-set!]、@racket[dict-iterate-first]、@racket[dict-iterate-next]、@racket[dict-iterate-key] 和 @racket[dict-iterate-value] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define original (vector "apple" "banana"))
(define copy (dict-copy original))
original
copy
(dict-set! copy 1 "carrot")
original
copy
]

}

@defproc[(dict-clear [dict dict?]) dict?]{

产生一个与 @racket[dict] 类型相同的空字典。如果 @racket[dict] 是可变的，结果必须是一个新字典。

任何支持 @racket[dict-remove]、@racket[dict-iterate-first]、@racket[dict-iterate-next] 和 @racket[dict-iterate-key] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(dict-clear #hash((a . "apple") ("banana" . b)))
(dict-clear '((1 . two) (three . "four")))
]

}

@defproc[(dict-clear! [dict dict?]) void?]{

删除 @racket[dict] 中所有的键/值关联。

任何支持 @racket[dict-remove!]、@racket[dict-iterate-first] 和 @racket[dict-iterate-key] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define table (make-hash))
(dict-set! table 'a "apple")
(dict-set! table "banana" 'b)
table
(dict-clear! table)
table
]

}

@defproc[(dict-keys [dict dict?]) list?]{
以未指定的顺序返回 @racket[dict] 中键的列表。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next] 和 @racket[dict-iterate-key] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define h #hash((a . "apple") (b . "banana")))
(dict-keys h)
]}

@defproc[(dict-values [dict dict?]) list?]{
以未指定的顺序返回 @racket[dict] 中值的列表。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next] 和 @racket[dict-iterate-value] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define h #hash((a . "apple") (b . "banana")))
(dict-values h)
]}

@defproc[(dict->list [dict dict?]) list?]{
以未指定的顺序返回 @racket[dict] 中关联的列表。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next]、@racket[dict-iterate-key] 和 @racket[dict-iterate-value] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define h #hash((a . "apple") (b . "banana")))
(dict->list h)
]}
@section[#:tag "dicts-s3"]{Dictionary Sequences}

@defproc[(in-dict [dict dict?]) sequence?]{ 返回一个 @tech{sequence}，其中每个元素是两个值：@racket[dict] 中的一个键和对应的值。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next]、@racket[dict-iterate-key] 和 @racket[dict-iterate-value] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define h #hash((a . "apple") (b . "banana")))
(for/list ([(k v) (in-dict h)])
  (format "~a = ~s" k v))
]}


@defproc[(in-dict-keys [dict dict?]) sequence?]{
返回一个序列，其元素为 @racket[dict] 的键。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next] 和 @racket[dict-iterate-key] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define h #hash((a . "apple") (b . "banana")))
(for/list ([k (in-dict-keys h)])
  k)
]}

@defproc[(in-dict-values [dict dict?]) sequence?]{
返回一个序列，其元素为 @racket[dict] 的值。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next] 和 @racket[dict-iterate-value] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define h #hash((a . "apple") (b . "banana")))
(for/list ([v (in-dict-values h)])
  v)
]}

@defproc[(in-dict-pairs [dict dict?]) sequence?]{ 返回一个序列，其元素为 pair，每个包含 @racket[dict] 中的一个键及其值（与使用 @racket[in-dict] 不同，后者将每个元素的键和值作为单独的值获取）。

任何实现了 @racket[dict-iterate-first]、@racket[dict-iterate-next]、@racket[dict-iterate-key] 和 @racket[dict-iterate-value] 的 @racket[dict] 都支持此方法。

@examples[
#:eval dict-eval
(define h #hash((a . "apple") (b . "banana")))
(for/list ([p (in-dict-pairs h)])
  p)
]}

@section[#:tag "dicts-s4"]{Contracted Dictionaries}

@defthing[prop:dict/contract struct-type-property?]{

一个结构类型属性，用于定义带有 contract 的字典。与 @racket[prop:dict/contract] 关联的值必须是两个不可变向量的列表：

@racketblock[
(list _dict-vector
      (vector _type-key-contract
              _type-value-contract
              _type-iter-contract
              _instance-key-contract
              _instance-value-contract
              _instance-iter-contract))
]

第一个向量必须是包含 10 个过程的向量，匹配 @racket[gen:dict] @tech{generic interface}（此外，它必须是不可变向量）。第二个向量必须包含六个元素；前三个分别是字典类型的键、值和位置的 contract。后三个是 @racket[#f] 或用于从字典实例中提取 contract 的过程。
}

@deftogether[[
@defproc[(dict-key-contract [d dict?]) contract?]
@defproc[(dict-value-contract [d dict?]) contract?]
@defproc[(dict-iter-contract [d dict?]) contract?]]]{

如果 @racket[d] 实现了 @racket[prop:dict/contract] 接口，分别返回 @racket[d] 对其键、值或迭代器施加的 contract。
}

@section[#:tag "dicts-s5"]{Custom Hash Tables}

@defform[(define-custom-hash-types name
                                   optional-predicate
                                   comparison-expr
                                   optional-hash-functions)
         #:grammar ([optional-predicate
                     (code:line)
                     (code:line #:key? predicate-expr)]
                    [optional-hash-functions
                     (code:line)
                     (code:line hash1-expr)
                     (code:line hash1-expr hash2-expr)])]{

基于给定的比较 @racket[comparison-expr]、hash 函数 @racket[hash1-expr] 和 @racket[hash2-expr]，以及键谓词 @racket[predicate-expr] 创建新的字典类型；这些函数的接口与 @racket[make-custom-hash-types] 中的相同。新字典类型有三种变体：不可变、键强引用的可变和键弱引用的可变。

定义七个名称：

@itemize[
@item{@racket[name]@racketidfont{?} 识别新类型的实例，}
@item{@racketidfont{immutable-}@racket[name]@racketidfont{?} 识别新类型的不可变实例，}
@item{@racketidfont{mutable-}@racket[name]@racketidfont{?} 识别新类型的键强引用可变实例，}
@item{@racketidfont{weak-}@racket[name]@racketidfont{?} 识别新类型的键弱引用可变实例，}
@item{@racketidfont{make-immutable-}@racket[name] 构造新类型的不可变实例，}
@item{@racketidfont{make-mutable-}@racket[name] 构造新类型的键强引用可变实例，以及}
@item{@racketidfont{make-weak-}@racket[name] 构造新类型的键弱引用可变实例。}
]

所有构造函数都接受一个字典作为可选参数，提供初始键/值对。

@examples[
#:eval dict-eval
(define-custom-hash-types string-hash
                          #:key? string?
                          string=?
                          string-length)
(define imm
  (make-immutable-string-hash
   '(("apple" . a) ("banana" . b))))
(define mut
  (make-mutable-string-hash
   '(("apple" . a) ("banana" . b))))
(dict? imm)
(dict? mut)
(string-hash? imm)
(string-hash? mut)
(immutable-string-hash? imm)
(immutable-string-hash? mut)
(dict-ref imm "apple")
(dict-ref mut "banana")
(dict-set! mut "banana" 'berry)
(dict-ref mut "banana")
(equal? imm mut)
(equal? (dict-remove (dict-remove imm "apple") "banana")
        (make-immutable-string-hash))
]

}

@defproc[(make-custom-hash-types
          [eql?
           (or/c (any/c any/c . -> . any/c)
                 (any/c any/c (any/c any/c . -> . any/c) . -> . any/c))]
          [hash1
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [hash2
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [#:key? key? (any/c . -> . boolean?) (const #true)]
          [#:name name symbol? 'custom-hash]
          [#:for who symbol? 'make-custom-hash-types])
         (values (any/c . -> . boolean?)
                 (any/c . -> . boolean?)
                 (any/c . -> . boolean?)
                 (any/c . -> . boolean?)
                 (->* [] [dict?] dict?)
                 (->* [] [dict?] dict?)
                 (->* [] [dict?] dict?))]{

基于给定的比较函数 @racket[eql?]、hash 函数 @racket[hash1] 和 @racket[hash2]，以及谓词 @racket[key?] 创建新的字典类型。新字典类型有不可变、键强引用可变和键弱引用可变的变体。给定的 @racket[name] 用于打印新字典类型的实例，符号 @racket[who] 用于报告错误。

比较函数 @racket[eql?] 可以接受 2 或 3 个参数。如果接受 2 个参数，则给定两个键来比较它们。如果接受 3 个参数且不接受 2 个参数，则还给定一个递归比较函数，用于在比较键的子部分时处理数据循环。

hash 函数 @racket[hash1] 和 @racket[hash2] 可以接受 1 或 2 个参数。如果任一 hash 函数接受 1 个参数，则将其应用于键来计算对应的 hash 值。如果任一 hash 函数接受 2 个参数且不接受 1 个参数，则还给定一个递归 hash 函数，用于在计算键的子部分的 hash 值时处理数据循环。

谓词 @racket[key?] 必须接受 1 个参数，用于识别新字典类型的有效键。

产生七个值：

@itemize[
@item{识别新字典类型所有实例的谓词，}
@item{识别不可变实例的谓词，}
@item{识别可变实例的谓词，}
@item{识别弱引用实例的谓词，}
@item{不可变实例的构造函数，}
@item{可变实例的构造函数，以及}
@item{弱引用实例的构造函数。}
]

参见 @racket[define-custom-hash-types] 获取示例。

}

@deftogether[(
@defproc[(make-custom-hash
          [eql?
           (or/c (any/c any/c . -> . any/c)
                 (any/c any/c (any/c any/c . -> . any/c) . -> . any/c))]
          [hash1
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [hash2
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [#:key? key? (any/c . -> . boolean?) (λ (x) #true)])
         dict?]
@defproc[(make-weak-custom-hash
          [eql?
           (or/c (any/c any/c . -> . any/c)
                 (any/c any/c (any/c any/c . -> . any/c) . -> . any/c))]
          [hash1
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [hash2
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [#:key? key? (any/c . -> . boolean?) (λ (x) #true)])
         dict?]
@defproc[(make-immutable-custom-hash
          [eql?
           (or/c (any/c any/c . -> . any/c)
                 (any/c any/c (any/c any/c . -> . any/c) . -> . any/c))]
          [hash1
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [hash2
           (or/c (any/c . -> . exact-integer?)
                 (any/c (any/c . -> . exact-integer?) . -> . exact-integer?))
           (const 1)]
          [#:key? key? (any/c . -> . boolean?) (λ (x) #true)])
         dict?]
)]{

 创建新字典类型的实例，基于 hash 表实现，其中键使用 @racket[eql?] 比较，使用 @racket[hash1] 和 @racket[hash2] 进行 hash，键谓词为 @racket[key?]。参见 @racket[gen:equal] 和 @racket[gen:equal+hash] 了解合适的相等和 hash 函数。

@racket[make-custom-hash] 和 @racket[make-weak-custom-hash] 函数创建不支持函数式更新的可变字典，而 @racket[make-immutable-custom-hash] 创建支持函数式更新的不可变字典。@racket[make-weak-custom-hash] 创建的字典弱引用其键，类似 @racket[make-weak-hash] 的结果。

当具有相同的可变性和键引用强度、关联的过程是 @racket[equal?] 的、且当键和值使用 @racket[equal?] 比较时键值映射相同时，@racket[make-custom-hash] 等创建的字典是 @racket[equal?] 的。

另见 @racket[define-custom-hash-types]。

@examples[
#:eval dict-eval
(define h (make-custom-hash (lambda (a b)
                              (string=? (format "~a" a)
                                        (format "~a" b)))
                            (lambda (a)
                              (equal-hash-code
                               (format "~a" a)))))
(dict-set! h 1 'one)
(dict-ref h "1")
]


}

@section[#:tag "dicts-s6"]{Passing Keyword Arguments in Dictionaries}

@defproc[
 (keyword-apply/dict [proc procedure?]
                     [kw-dict dict?] ; (dict/c keyword? any/c)
                     [pos-arg any/c] ...
                     [pos-args (listof any/c)]
                     [#:<kw> kw-arg any/c] ...)
 any]{
使用来自 @racket[(list* pos-arg ... pos-args)] 的位置参数，以及来自 @racket[kw-dict] 的关键字参数加上 @racket[#:<kw> kw-arg] 序列中直接提供的关键字参数来应用 @racket[proc]。

@racket[kw-dict] 中的所有键必须是关键字。@racket[kw-dict] 中的关键字不必排序。但是，@racket[kw-dict] 中的关键字与直接提供的 @racket[#:<kw>] 关键字不得重叠。给定的 @racket[proc] 必须接受 @racket[kw-dict] 中的所有关键字加上 @racket[#:<kw>]。

@examples[
#:eval dict-eval
(define (sundae #:ice-cream [ice-cream '("vanilla")]
                #:toppings [toppings '("brownie-bits")]
                #:sprinkles [sprinkles "chocolate"]
                #:syrup [syrup "caramel"])
  (format "A sundae with ~a ice cream, ~a, ~a sprinkles, and ~a syrup."
          (string-join ice-cream #:before-last " and ")
          (string-join toppings #:before-last " and ")
          sprinkles
          syrup))
(keyword-apply/dict sundae '((#:ice-cream . ("chocolate"))) '())
(keyword-apply/dict sundae
                    (hash '#:toppings '("cookie-dough")
                          '#:sprinkles "rainbow"
                          '#:syrup "chocolate")
                    '())
(keyword-apply/dict sundae
                    #:sprinkles "rainbow"
                    (hash '#:toppings '("cookie-dough")
                          '#:syrup "chocolate")
                    '())
]
@history[#:added "7.9"]}


@close-eval[dict-eval]
