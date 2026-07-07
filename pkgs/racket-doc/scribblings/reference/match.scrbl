#lang scribble/doc
@(require "mz.rkt" "match-grammar.rkt" racket/match)

@(define match-eval (make-base-eval))
@(define (match-kw s) (index (list s) (racketidfont s)))
@examples[#:hidden #:eval match-eval (require racket/match racket/list)]
@examples[#:hidden #:eval match-eval (require (for-syntax racket/base))]

@title[#:tag "match"]{Pattern Matching}

@guideintro["match"]{模式匹配}

@racket[match] 形式及相关形式支持对 Racket 值的通用模式匹配。另请参见 @secref["regexp"] 了解字符串、字节和流的正则表达式匹配信息。

@note-lib[racket/match #:use-sources (racket/match)]

@defform/subs[(match val-expr clause ...)
              ([clause [pat option=> option ... body ...+]]
               [option=> (code:line)
                         (=> id)]
               [option (code:line #:when cond-expr)
                       (code:line #:do [do-body ...])])]{

查找第一个与 @racket[val-expr] 的结果匹配的 @racket[pat]，并使用 @racket[pat] 引入的绑定（如果有）求值相应的 @racket[body]。@racket[pat] 引入的绑定在 @racket[pat] 的其他部分不可用。匹配子句中最后一个 @racket[body] 在相对于 @racket[match] 表达式的尾位置求值。

为找到匹配，按顺序尝试各 @racket[clause]。如果没有 @racket[clause] 匹配，则 @exnraise[exn:misc:match?]。

可选的 @racket[#:when cond-expr] 指定模式仅在 @racket[cond-expr] 产生真值时才应匹配。@racket[cond-expr] 在 @racket[pat] 中绑定的所有变量的作用域内。@racket[cond-expr] 在调用失败过程之前不得修改正在匹配的对象，否则匹配行为不可预测。另请参见 @racket[failure-cont]，它是实现相同目标的更低层机制。

@examples[
#:eval match-eval
(define (m x)
  (match x
    [(list a b c)
     #:when (= 6 (+ a b c))
     'sum-is-six]
    [(list a b c) 'sum-is-not-six]))

(m '(1 2 3))
(m '(2 3 4))
]

可选的 @racket[#:do [do-body ...]] 执行 @racket[do-body] 形式。特别是，这些形式可以引入在其余选项和主子句主体中可见的定义。@racket[#:when] 和 @racket[#:do] 选项均可出现多次

@examples[
#:eval match-eval
(define (m x)
  (match x
    [(list a b c)
     #:do [(define sum (+ a b c))]
     #:when (> sum 6)
     (format "the sum, which is ~a, is greater than 6" sum)]
    [(list a b c) 'sum-is-not-greater-than-six]))

(m '(1 2 3))
(m '(2 3 4))
]

可选的 @racket[(=> id)] 必须紧接在 @racket[pat] 之后出现，它被绑定到一个零参数的 @deftech{失败过程}。@racket[id] 在所有子句选项和子句主体中可见。如果调用此过程，它会逃逸回模式匹配表达式，并恢复匹配过程，就像该模式匹配失败一样。@racket[body] 在调用失败过程之前不得修改正在匹配的对象，否则匹配行为不可预测。 

@examples[
#:eval match-eval
(define (m x)
  (match x
    [(list a b c)
     (=> exit)
     (f x exit)]
    [(list a b c) 'sum-is-not-six]))

(define (f x exit)
  (if (= 6 (apply + x))
      'sum-is-six
      (exit)))

(m '(1 2 3))
(m '(2 3 4))
]

@racket[pat] 的语法如下，其中非斜体标识符按符号识别（即不通过绑定）。

@|match-grammar|

更详细地说，各模式的匹配方式如下：

@itemize[

 @item{@racket[_id]（不包括保留名称 @racketidfont{_}、@racketidfont{...}、@racketidfont{___}、@racketidfont{..}@racket[_k] 以及针对非负整数 @racket[_k] 的 @racketidfont{__}@racket[_k]）@margin-note{与 @racket[cond] 和 @racket[case] 不同，@racket[else] 在 @racket[match] 中不是关键字。使用 @racketidfont{_} 模式作为"else"子句。} 或 @racket[(var _id)] --- 匹配任何内容，并将 @racket[_id] 绑定到匹配值。如果 @racket[_id] 在模式中多次使用，相应的匹配必须根据 @racket[(match-equality-test)] 相同，但不同 @racketidfont{or} 和 @racketidfont{not} 子模式中的 @racket[_id] 实例是独立的。@racket[_id] 的绑定在同一模式的其他部分不可用。

       如果 @racket[_id] 在不同的省略号深度上多次使用——即有些使用在 @racketidfont{...} 下而其他不在，或者它们在不同的 @racketidfont{...} 模式下——会引发语法错误。详见 @secref["match-nonlinear-ellipsis"]。

       @examples[
       #:eval match-eval
       (match '(1 2 3)
         [(list a b a) (list a b)]
         [(list a b c) (list c b a)])
       (match '(1 (x y z) 1)
         [(list a b a) (list a b)]
         [(list a b c) (list c b a)])
       (match #f
         [else
          (cond
            [#f 'not-evaluated]
            [else 'also-not-evaluated])])
       ]}

 @item{@match-kw{_} --- 匹配任何内容，不绑定任何标识符。

       @examples[
       #:eval match-eval
       (match '(1 2 3)
         [(list _ _ a) a])
       ]}

 @item{@racket[#t]、@racket[#f]、@racket[_string]、@racket[_bytes]、@racket[_number]、@racket[_char] 或 @racket[(#,(racketidfont
       "quote") _datum)] --- 匹配 @racket[equal?] 常量。

       @examples[
       #:eval match-eval
       (match "yes"
         ["no" #f]
         ["yes" #t])
       ]}

 @item{@racket[(#,(match-kw "list") _lvp ...)] --- 匹配元素列表。对于 @racket[(#,(racketidfont "list")
       _pat ...)] 的情况，该模式匹配具有与 @racket[_pat] 数量相同元素的列表，每个元素必须与相应的 @racket[_pat] 匹配。在更一般的情况下，每个 @racket[_lvp] 对应一个贪心匹配的"拼接"列表。

       对于拼接列表，@racketidfont{...} 和 @racketidfont{___} 是零个或多个匹配的别名。@racketidfont{..}@racket[_k] 和 @racketidfont{__}@racket[_k] 形式也是别名，指定 @racket[_k] 个或更多匹配。这些拼接运算符之前的模式变量被绑定到匹配形式的列表。

       @examples[
       #:eval match-eval
       (match '(1 2 3)
         [(list a b c) (list c b a)])
       (match '(1 2 3)
         [(list 1 a ...) a])
       (match '(1 2 3)
         [(list 1 a ..3) a]
         [_ 'else])
       (match '(1 2 3 4)
         [(list 1 a ..3) a]
         [_ 'else])
       (match '(1 2 3 4 5)
         [(list 1 a ..3 5) a]
         [_ 'else])
       (match '(1 (2) (2) (2) 5)
         [(list 1 (list a) ..3 5) a]
         [_ 'else])
       ]}

 @item{@racket[(#,(match-kw "list-rest") _lvp ... _pat)]
       或 @racket[(#,(match-kw "list*") _lvp ... _pat)] ---
       类似于 @racketidfont{list} 模式，但最后的 @racket[_pat] 匹配最后一个 @racket[_lvp] 之后列表的"剩余部分"。事实上，如果 @racket[_pat] 匹配非列表值，匹配的值可以是非列表的对链（即"不正规列表"）。

      @examples[
       #:eval match-eval
      (match '(1 2 3 . 4)
        [(list-rest a b c d) d])
      (match '(1 2 3 . 4)
        [(list-rest a ... d) (list a d)])
      ]}

 @item{@racket[(#,(match-kw "list-no-order") _pat ...)] ---
       similar to a @racketidfont{list} pattern, but the elements to
       match each @racket[_pat] can appear in the list in any order.

       @examples[
       #:eval match-eval
       (match '(1 2 3)
         [(list-no-order 3 2 x) x])
       ]

       @margin-note{
         Unlike other patterns, @racketidfont{list-no-order} doesn't
         allow duplicate identifiers between subpatterns. For example
         the patterns @racket[(list-no-order x 1 x)] and
         @racket[(list-no-order x 1 x ...)] both produce syntax errors.}}

 @item{@racket[(#,(racketidfont "list-no-order") _pat ... _lvp)] ---
       推广 @racketidfont{list-no-order}，允许模式以任意顺序与其他模式的匹配交错匹配多个列表元素。

       @examples[
       #:eval match-eval
       (match '(1 2 3 4 5 6)
         [(list-no-order 6 2 y ...) y])
       ]}

 @item{@racket[(#,(match-kw "vector") _lvp ...)] --- 类似 @racketidfont{list} 模式，但匹配 vector。

       @examples[
       #:eval match-eval
       (match #(1 (2) (2) (2) 5)
         [(vector 1 (list a) ..3 5) a])
       ]}

 @item{@racket[(#,(match-kw "hash") _expr _pat ... ... _ht-opt)] ---
       matches against a hash table where @racket[_expr] matches
       a key and @racket[_pat] matches a corresponding value.

       @examples[
       #:eval match-eval
       (match (hash "aa" 1 "b" 2)
         [(hash "b" b (string-append "a" "a") a)
          (list b a)])
       (match (hash "aa" 1 "b" 2)
         [(hash "b" _ "c" _) 'matched]
         [_ 'not-matched])
       ]

       The key matchings use the key comparator of the matching hash table.

       @examples[
       #:eval match-eval
       (let ([k (string-append "a" "b")])
         (match (hasheq "ab" 1)
           [(hash k v) 'matched]
           [_ 'not-matched]))
       (let ([k (string-append "a" "b")])
         (match (hasheq k 1)
           [(hash k v) 'matched]
           [_ 'not-matched]))
       ]

       The behavior of residue key-value entries in the hash table value depends on @racket[_ht-opt].

       When @racket[_ht-opt] is not provided or when it is @racket[#:closed],
       all of the keys in the hash table value must be matched.
       I.e., the matching is closed to extension.

       @examples[
       #:eval match-eval
       (match (hash "a" 1 "b" 2)
         [(hash "b" _) 'matched]
         [_ 'not-matched])
       ]

       When @racket[_ht-opt] is @racket[#:open],
       there can be keys in the hash table value that are not specified in the pattern.
       I.e., the matching is open to extension.

       @examples[
       #:eval match-eval
       (match (hash "a" 1 "b" 2)
         [(hash "b" _ #:open) 'matched]
         [_ 'not-matched])
       ]

       When @racket[_ht-opt] is @racket[#:rest _pat], @racket[_pat] is further
       matched against the residue hash table.
       If the matching hash table is immutable, this residue matching is efficient.
       Otherwise, the matching hash table will be copied, which could be expensive.

       @examples[
       #:eval match-eval
       (match (hash "a" 1 "b" 2)
         [(hash "b" _ #:rest (hash "a" a)) a]
         [_ #f])
       ]

       Many key @racket[_expr]s could evaluate to the same value.

       @examples[
       #:eval match-eval
       (match (hash "a" 1 "b" 2)
         [(hash "b" _ "b" 2 "a" _) 'matched]
         [_ 'not-matched])
       ]}

 @item{@racket[(#,(match-kw "hash*") [_expr _pat _kv-opt] ... _ht-opt)] ---
       类似于 @racketidfont{hash}，但有以下区别：

       @itemlist[
         @item{键值模式必须在语法上进行分组。}
         @item{如果未指定 @racket[_ht-opt]，其行为类似 @racket[#:open]（而非 @racket[#:closed]）。}
         @item{如果 @racket[_kv-opt] 以 @racket[#:default _def-expr] 指定，且键在哈希表值中不存在，则来自 @racket[_def-expr] 的默认值将与值模式匹配，而不是立即匹配失败。}
       ]

       @examples[
       #:eval match-eval
       (match (hash "a" 1 "b" 2)
         [(hash* ["b" b] ["a" a]) (list b a)])
       (match (hash "a" 1 "b" 2)
         [(hash* ["b" b]) 'matched]
         [_ 'not-matched])
       (match (hash "a" 1 "b" 2)
         [(hash* ["a" a #:default 42] ["c" c #:default 100]) (list a c)]
         [_ #f])
       ]}

 @item{@racket[(#,(match-kw "hash-table") (_pat _pat) ...)] ---
       @bold{此模式已弃用，因为它可能不正确。}但是，许多程序依赖这种不正确的行为，因此出于向后兼容的原因，我们仍然提供此模式。

       类似于 @racketidfont{list-no-order}，但针对哈希表的键值对进行匹配。

       @examples[
       #:eval match-eval
       (match #hash(("a" . 1) ("b" . 2))
         [(hash-table ("b" b) ("a" a)) (list b a)])
       ]}

 @item{@racket[(#,(racketidfont "hash-table") (_pat _pat) ...+ _ooo)] ---
       @bold{此模式已弃用，因为它可能不正确。}但是，许多程序依赖这种不正确的行为，因此出于向后兼容的原因，我们仍然提供此模式。

       推广 @racketidfont{hash-table} 以支持最后的重复模式。

       @examples[
       #:eval match-eval
       (match #hash(("a" . 1) ("b" . 2))
         [(hash-table (key val) ...) key])
       ]}

 @item{@racket[(#,(match-kw "cons") _pat1 _pat2)] --- 匹配 pair 值。

       @examples[
       #:eval match-eval
       (match (cons 1 2)
         [(cons a b) (+ a b)])
       ]}

 @item{@racket[(#,(match-kw "mcons") _pat1 _pat2)] --- 匹配可变 pair 值。

       @examples[
       #:eval match-eval
       (match (mcons 1 2)
         [(cons a b) 'immutable]
	 [(mcons a b) 'mutable])
       ]}

 @item{@racket[(#,(match-kw "box") _pat)] --- 匹配 box 值。

       @examples[
       #:eval match-eval
       (match #&1
         [(box a) a])
       ]}

 @item{@racket[(_struct-id _pat ...)] 或
       @racket[(#,(match-kw "struct") _struct-id (_pat ...))] ---
       匹配名为 @racket[_struct-id] 的结构类型的实例，其中实例中的每个字段匹配相应的 @racket[_pat]。另请参见 @racket[struct*]。

       通常，@racket[_struct-id] 使用 @racket[struct] 定义。更一般地说，@racket[_struct-id] 必须绑定到结构类型的展开时信息（参见 @secref["structinfo"]），其中信息至少包括与 @racket[_pat] 字段数量对应的谓词绑定和字段访问器绑定。特别是，模块导入或具有包含 @racket[struct] 声明的签名的 @racket[unit] 导入可以提供结构类型信息。

       @examples[
       #:eval match-eval
       (eval:no-prompt (struct tree (val left right)))
       (match (tree 0 (tree 1 #f #f) #f)
         [(tree a (tree b  _ _) _) (list a b)])
       ]}

 @item{@racket[(#,(racketidfont "struct") _struct-id _)] ---
       匹配 @racket[_struct-id] 的任何实例，不考虑实例字段的内容。
       }

 @item{@racket[(#,(match-kw "regexp") _rx-expr)] --- 匹配一个与 @racket[_rx-expr] 产生的正则表达式模式匹配的字符串，其中 @racket[_rx-expr] 可以是 @racket[regexp]、@racket[pregexp]、@racket[byte-regexp]、@racket[byte-pregexp]、字符串或字节串。字符串和字节串值分别使用 @racket[regexp] 和 @racket[byte-regexp] 转换为模式。有关正则表达式的更多信息，请参见 @secref["regexp"]。

       @examples[
       #:eval match-eval
       (match "apple"
         [(regexp #rx"p+") 'yes]
         [_ 'no])
       (match "banana"
         [(regexp #px"(na){2}") 'yes]
         [_ 'no])
       (match "banana"
         [(regexp "(na){2}") 'yes]
         [_ 'no])
       (match #"apple"
         [(regexp #rx#"p+") 'yes]
         [_ 'no])
       (match #"banana"
         [(regexp #px#"(na){2}") 'yes]
         [_ 'no])
       (match #"banana"
         [(regexp #"(na){2}") 'yes]
         [_ 'no])
       ]}

 @item{@racket[(#,(racketidfont "regexp") _rx-expr _pat)] --- 扩展 @racketidfont{regexp} 形式以进一步约束匹配，其中 @racket[regexp-match] 的结果与 @racket[_pat] 进行匹配。

       @examples[
       #:eval match-eval
       (match "apple"
         [(regexp #rx"p+(.)" (list _ "l")) 'yes]
         [_ 'no])
       (match "append"
         [(regexp #rx"p+(.)" (list _ "l")) 'yes]
         [_ 'no])
       ]}

 @item{@racket[(#,(match-kw "pregexp") _rx-expr)] 或
       @racket[(#,(racketidfont "pregexp") _rx-expr _pat)] --- 类似 @racketidfont{regexp} 模式，但 @racket[_rx-expr] 必须是 @racket[pregexp]、@racket[byte-pregexp]、字符串或字节串。字符串和字节串值分别使用 @racket[pregexp] 和 @racket[byte-pregexp] 转换为模式。}

 @item{@racket[(#,(match-kw "and") _pat ...)] --- 如果所有 @racket[_pat] 都匹配，则匹配。此模式通常用作 @racket[(#,(racketidfont "and") _id _pat)] 以将 @racket[_id] 绑定到匹配 @racket[pat] 的整个值。@racket[_pat] 按出现顺序进行匹配。

       @examples[
       #:eval match-eval
       (match '(1 (2 3) 4)
        [(list _ (and a (list _ ...)) _) a])
       ]}

 @item{@racket[(#,(match-kw "or") _pat ...)] --- 如果任一 @racket[_pat] 匹配，则匹配。每个 @racket[_pat] 必须绑定相同的标识符集合。

       @examples[
       #:eval match-eval
       (match '(1 2)
        [(or (list a 1) (list a 2)) a])
       ]}

 @item{@racket[(#,(match-kw "not") _pat ...)] --- 当所有 @racket[_pat] 都不匹配时匹配，不绑定任何标识符。

       @examples[
       #:eval match-eval
       (match '(1 2 3)
        [(list (not 4) ...) 'yes]
        [_ 'no])
       (match '(1 4 3)
        [(list (not 4) ...) 'yes]
        [_ 'no])
       ]}

 @item{@racket[(#,(match-kw "app") _expr _pats ...)] --- 将 @racket[_expr] 应用于要匹配的值；应用的每个结果分别与 @racket[_pats] 之一进行匹配。

       @examples[
       #:eval match-eval
       (match '(1 2)
        [(app length 2) 'yes])
       (match "3.14"
        [(app string->number (? number? pi))
         `(I got ,pi)])
       (match '(1 2)
        [(app (lambda (v) (split-at v 1)) '(1) '(2)) 'yes])
       (match '(1 2 3)
        [(app (λ (ls) (apply values ls)) x y (? odd? z))
         (list 'yes x y z)])
       ]}

 @item{@racket[(#,(match-kw "?") _expr _pat ...)] --- 将 @racket[_expr] 应用于要匹配的值，并检查结果是否为真值；附加的 @racket[_pat] 也必须匹配；即 @racketidfont{?} 结合了谓词应用和 @racketidfont{and} 模式。然而，@racketidfont{?} 与 @racketidfont{and} 不同，它保证 @racket[_expr] 在任何 @racket[_pat] 之前匹配。

       @margin-note{@racket[_expr] 过程可能在相同输入上被调用多次（虽然这种情况很少发生），且不应依赖 @racket[_expr] 调用的顺序。}

       @examples[
       #:eval match-eval
       (match '(1 3 5)
        [(list (? odd?) ...) 'yes])
       ]}

  @item{@racket[(#,(match-kw "quasiquote") _qp)] --- 引入准模式（quasipattern），其中标识符匹配符号。与 @racket[quasiquote] 表达式形式类似，@racketidfont{unquote} 和 @racketidfont{unquote-splicing} 逃逸回正常模式。

        @examples[
       #:eval match-eval
        (match '(1 2 3)
          [`(1 ,a ,(? odd? b)) (list a b)])
        ]}

 @item{@racket[_derived-pattern] --- 匹配通过 @racket[define-match-expander] 的宏扩展定义的模式。}

]

注意，匹配过程可能会多次解构输入，并可能以任意顺序或多次求值嵌入在模式中的表达式，如 @racket[(#,(racketidfont
"app") expr pat)]。因此，这些表达式必须是可安全多次调用的，或以不同于原始程序中出现的顺序调用。

@history[#:changed "8.9.0.5" @elem{添加了对 @racket[#:do] 的支持。}
         #:changed "8.11.1.10" @elem{添加了 @racket[#,(racketidfont "hash")] 和
                                     @racket[#,(racketidfont "hash*")] 模式。}]
}

@; ----------------------------------------------------------------------

@section[#:tag "match-s1"]{Additional Matching Forms}

@defform/subs[(match* (val-expr ...+) clause* ...)
              ([clause* [(pat ...+) option=> option ... body ...+]])]{
按顺序将值序列与每个子句进行匹配，仅当子句中所有模式都匹配时才匹配。每个子句必须具有与 @racket[val-expr] 数量相同的模式数。

@examples[#:eval match-eval
(match* (1 2 3)
  [(_ (? number?) x) (add1 x)])

(match* (15 17)
  [((? number? a) (? number? b))
   #:when (= (+ a 2) b)
   'diff-by-two])
]
}

@defform[(match/values expr clause* clause* ...)]{
如果 @racket[expr] 求值为 @racket[n] 个值，则将全部 @racket[n] 个值与 @racket[clause* ...] 中的模式进行匹配。每个子句必须恰好包含 @racket[n] 个模式。至少需要一个子句来确定期望从 @racket[expr] 获得多少个值。

@examples[#:eval match-eval
(match/values (values 1 2 3)
  [(a (? number? b) (? odd? c)) (+ a b c)])
]
}


@defform/subs[
  (define/match (head args)
    match*-clause ...)
  ([head id (head args)]
   [args (code:line arg ...)
         (code:line arg ... @#,racketparenfont{.} rest-id)]
   [arg arg-id
        [arg-id default-expr]
        (code:line keyword arg-id)
        (code:line keyword [arg-id default-expr])]
   [match*-clause [(pat ...+) option=> option ... body ...+]])
]{
  将 @racket[id] 绑定到通过使用 @racket[match*] 的模式匹配子句定义的过程。每个子句接受与函数头中参数对应的模式序列。参数的顺序与函数头中出现的顺序一致，用于匹配目的。

  @examples[#:eval match-eval
    (eval:no-prompt
     (define/match (fact n)
       [(0) 1]
       [(n) (* n (fact (sub1 n)))]))
    (fact 5)
  ]

  函数头还可以包含可选参数或关键字参数，可以有柯里化参数，也可以包含剩余参数。

  @examples[#:eval match-eval
    (eval:no-prompt
     (define/match ((f x) #:y [y '(1 2 3)])
       [((regexp #rx"p+") `(,a 2 3)) a]
       [(_ _) #f]))
    ((f "ape") #:y '(5 2 3))
    ((f "dog"))

    (eval:no-prompt
     (define/match (g x y . rst)
       [(0 0 '()) #t]
       [(5 5 '(5 5)) #t]
       [(_ _ _) #f]))
    (g 0 0)
    (g 5 5 5 5)
    (g 1 2)
  ]
}

@deftogether[(@defform[(match-lambda clause ...)]
              @defform[(match-λ clause ...)])]{

等价于 @racket[(lambda (id) (match id clause ...))]。

@history[#:changed "8.13.0.5" @elem{添加了 @racket[match-λ]。}]
}

@deftogether[(@defform[(match-lambda* clause ...)]
              @defform[(match-λ* clause ...)])]{

等价于 @racket[(lambda lst (match lst clause ...))]。

@history[#:changed "8.13.0.5" @elem{添加了 @racket[match-λ*]。}]
}

@deftogether[(@defform[(match-lambda** clause* ...)]
              @defform[(match-λ** clause* ...)])]{

等价于 @racket[(lambda (args ...) (match* (args ...) clause* ...))]，其中 @racket[args ...] 的数量根据每个 @racket[clause*] 中出现的模式数量计算得出。

@history[#:changed "8.13.0.5" @elem{添加了 @racket[match-λ**]。}]
}


@defform[(match-let ([pat expr] ...) body ...+)]{

推广 @racket[let] 以支持模式绑定。每个 @racket[expr] 与其对应的 @racket[pat] 进行匹配（匹配必须成功），@racket[pat] 引入的绑定在 @racket[body] 中可见。

@examples[
#:eval match-eval
(match-let ([(list a b) '(1 2)]
            [(vector x ...) #(1 2 3 4)])
  (list b a x))
]}

@defform[(match-let* ([pat expr] ...) body ...+)]{

类似 @racket[match-let]，但推广 @racket[let*]，使得每个 @racket[pat] 的绑定在每个后续 @racket[expr] 中可用。

@examples[
#:eval match-eval
(match-let* ([(list a b) '(#(1 2 3 4) 2)]
             [(vector x ...) a])
  x)
]}

@defform[(match-let-values ([(pat ...) expr] ...) body ...+)]{

类似 @racket[match-let]，但推广 @racket[let-values]。}

@defform[(match-let*-values ([(pat ...) expr] ...) body ...+)]{

类似 @racket[match-let*]，但推广 @racket[let*-values]。}

@defform[(match-letrec ([pat expr] ...) body ...+)]{

类似 @racket[match-let]，但推广 @racket[letrec]。}


@defform[(match-letrec-values ([(pat ...) expr] ...) body ...+)]{

类似 @racket[match-let]，但推广 @racket[letrec-values]。

@history[#:added "6.1.1.8"]
}
 
@defform[(match-define pat expr)]{

将由 @racket[pat] 绑定的名称定义为通过匹配 @racket[expr] 结果产生的值。

@examples[
#:eval match-eval
(match-define (list a b) '(1 2))
b
]}

@defform[(match-define-values (pat pats ...) expr)]{

类似 @racket[match-define]，但用于当 expr 产生多个值时。与 match/values 一样，它至少需要一个模式来确定期望的值数量。

@examples[
#:eval match-eval
(match-define-values (a b) (values 1 2))
b
]}

@; ----------------------------------------

@defproc[(exn:misc:match? [v any/c]) boolean?]{
用于匹配失败时引发的异常的谓词。
}

@defform[(failure-cont)]{
继续匹配，就好像当前模式失败了一样。注意，与使用 @racket[=>] 形式不同，这 @emph{不}会逃逸当前上下文，因此只应在相对于 @racket[match] 形式的尾位置使用。
}


@; ----------------------------------------

@section[#:tag "match-s2"]{Extending @racket[match]}

@defform*[((define-match-expander id proc-expr)
           (define-match-expander id proc-expr proc-expr))]{

将 @racket[id] 绑定到一个 @deftech{匹配展开器}（match expander）。

第一个 @racket[proc-expr] 子表达式必须求值为一个转换器，该转换器为 @racket[match] 产生一个 @racket[_pat]。每当 @racket[id] 作为模式的开头出现时，在展开时，此转换器会接收一个对应于整个模式（包括 @racket[id]）的语法对象。该模式被替换为转换器的结果。

当 @racket[id] 在表达式上下文中使用时，使用第二个 @racket[proc-expr] 子表达式产生的转换器。使用第二个 @racket[proc-expr]，@racket[id] 可以在模式内部和外部都具有含义。

除非 @racket[id] 出现在序列的第一个位置，否则不会调用匹配展开器。相反，当由 @racket[define-match-expander] 绑定的标识符出现在序列中除第一个位置之外的任何位置时，它们被用作绑定标识符（与其他任何标识符一样）。
 
例如，要扩展模式匹配器并解构语法列表，
@examples[#:label #f
  #:eval match-eval
  (eval:no-prompt
   (define (syntax-list? x)
     (and (syntax? x)
          (list? (syntax->list x))))
   (define-match-expander syntax-list 
     (lambda (stx)
       (syntax-case stx ()
         [(_ elts ...)
          #'(? syntax-list?
               (app syntax->list (list elts ...)))])))
   (define (make-keyword-predicate keyword)
     (lambda (stx)
       (and (identifier? stx)
            (free-identifier=? stx keyword))))
   (define or-keyword? (make-keyword-predicate #'or))
   (define and-keyword? (make-keyword-predicate #'and)))

  (match #'(or 3 4)
    [(syntax-list (? or-keyword?) b c)
     (list "OOORRR!" b c)]
    [(syntax-list (? and-keyword?) b c)
     (list "AAANND!" b c)])

  (match #'(and 5 6)
    [(syntax-list (? or-keyword?) b c)
     (list "OOORRR!" b c)]
    [(syntax-list (? and-keyword?) b c)
     (list "AAANND!" b c)])
 ]

以下示例展示了 @racket[define-match-expander] 绑定的标识符除非出现在模式序列的第一个位置，否则 @emph{不}会被特殊处理。考虑这个（错误的）长度函数定义：
@examples[#:label #f
  #:eval match-eval
  (eval:no-prompt
   (define-match-expander nil
     (λ (stx) #''())
     (λ (stx) #''()))
   (define (len l)
     (match l
       [nil 0]
       [(cons hd tl) (+ 1 (len tl))])))]

因为 @racket[nil] 周围没有括号，@racket[match] 将第一个 case 视为标识符（匹配任何内容），而不是匹配展开器的使用，因此 @racket[len] 总是返回 @racket[0]。

@examples[#:label #f #:eval match-eval
  (len nil)
  (len (cons 1 nil))
  (len (cons 1 (cons 2 nil)))]

匹配展开器接受任何其第一个元素是绑定到该展开器的 @racket[identifier?] 的语法对。以下示例展示了一个匹配展开器，它可以用 @racket[(expander a b . rest)] 形式的不正规语法列表调用。
@examples[#:label #f
  #:eval match-eval
  (eval:no-prompt
   (define-match-expander my-vector
     (λ (stx)
       (syntax-case stx ()
         [(_ pat ...)
          #'(vector pat ...)]
         [(_ pat ... . rest-pat)
          #'(app vector->list (list-rest pat ... rest-pat))]))))
  (match #(1 2 3 4 5)
   [(my-vector a b . rest)
     (list->vector (append rest (list a b)))])]

@history[
 #:changed "7.7.0.2"
 @elem{匹配展开器现在允许任何其第一个元素是绑定到该展开器的 @racket[identifier?] 的语法对。上述示例在以前的版本中不起作用。}]
}

@defthing[prop:match-expander struct-type-property?]{

一个 @tech{结构类型属性}，用于标识充当 @tech{匹配展开器}的结构类型，类似 @racket[define-match-expander] 创建的那些。

属性值必须是一个精确的非负整数或一个接受一个或两个参数的过程。在前一种情况下，该整数指定结构内应包含一个过程的字段；该整数必须在 @racket[0]（含）到结构类型中非自动字段的数量（不含，不计超类型字段）之间，且指定字段还必须被指定为不可变的。

如果属性值是一个接受一个参数的过程，则该过程充当匹配展开的转换器。如果属性值是一个接受两个参数的过程，则第一个参数是其类型具有 @racket[prop:match-expander] 属性的结构，第二个参数是如 @tech{匹配展开器}的语法对象。

如果属性值是一个 @tech{赋值转换器}，则在调用之前会使用 @racket[set!-transformer-procedure] 提取包装的过程。

此绑定以 @racket[for-syntax] 提供。
}

@defthing[prop:legacy-match-expander struct-type-property?]{
类似 @racket[prop:match-expander]，但用于旧版匹配语法。

此绑定以 @racket[for-syntax] 提供。
}

@deftogether[[
@defproc[(match-expander? [v any/c]) boolean?]
@defproc[(legacy-match-expander? [v any/c]) boolean?]]]{
用于实现相应匹配展开器属性的值的谓词。
}

@defproc[(syntax-local-match-introduce [stx syntax?]) syntax?]{
仅用于向后兼容；等价于 @racket[syntax-local-introduce]。

@history[#:changed "6.90.0.29" @elem{使其等价于 @racket[syntax-local-introduce]。}]}


@defparam[match-equality-test comp-proc (any/c any/c . -> . any)]{

一个 @tech{参数}，确定用于检查标识符的多次使用是否匹配"相同"值的比较过程。默认值为 @racket[equal?]。}

@deftogether[[@defform[(match/derived val-expr original-datum clause ...)]
              @defform[(match*/derived (val-expr ...) original-datum clause* ...)]]]{
分别类似 @racket[match] 和 @racket[match*]，但包含一个子表达式用作形式内所有语法错误的源。例如，@racket[match-lambda] 展开为 @racket[match/derived]，以便形式主体中的错误以 @racket[match-lambda] 而非 @racket[match] 报告。}

@; ----------------------------------------------------------------------

@section[#:tag "match-nonlinear-ellipsis"]{Non-linear Patterns and Ellipses}

当同一标识符在模式中多次使用时（@deftech{非线性模式}），每次出现必须在同一 @racketidfont{...} 内，否则会引发语法错误。为了使整个模式匹配，每次出现必须根据 @racket[(match-equality-test)] 匹配相同的值。

当标识符的两次出现都在同一 @racketidfont{...} 下时，模式的每次重复检查该重复内的出现之间的相等性，但标识符可以在不同重复中匹配不同的值。该标识符被绑定到一个匹配值的列表。

例如，@racket[(list (list a a) ...)] 成功匹配 @racket['((1 1) (2 2) (3 3))]，因为在每次重复中两个 @racket[a] 都相等，尽管 @racket[a] 在第一次重复中是 @racket[1]，在第二次中是 @racket[2]，在第三次中是 @racket[3]。在这种情况下，@racket[a] 在右侧被绑定到 @racket['(1 2 3)]。

@examples[
#:eval match-eval
(code:comment "each pair must have equal elements")
(match '((1 1) (2 2) (3 3))
  [(list (list a a) ...) a]
  [_ 'no])
(code:comment "second pair doesn't match: 2 != 3")
(match '((1 1) (2 3) (3 3))
  [(list (list a a) ...) a]
  [_ 'no])
]

如果标识符在不同的省略号深度上使用——例如，一次在 @racketidfont{...} 外一次在内，或在不同的 @racketidfont{...} 模式下——则会引发语法错误。

@examples[
#:eval match-eval
(eval:error (match '(1 1 1 1) [(cons t (list t ...)) t]))
(eval:error (match '(1 2 3 4) [(list a ... a) a]))
(eval:error (match '((1 2) 3) [(list (list a ...) a) a]))
]

@history[#:changed "9.1.0.9" @elem{为 @racketidfont{...} 下的非线性模式添加了相等性检查，并将具有不同省略号深度的非线性模式改为引发语法错误。}]

@; ----------------------------------------------------------------------

@section[#:tag "match-s3"]{Library Extensions}

@defform*[[(== val comparator) (== val)]]{
一个 @tech{匹配展开器}，检查匹配值在使用 @racket[comparator] 比较时是否与 @racket[val] 相同。如果未提供 @racket[comparator]，则默认为 @racket[equal?]。  

@examples[#:eval match-eval
(match (list 1 2 3)
  [(== (list 1 2 3)) 'yes]
  [_ 'no])
(match (list 1 2 3)
  [(== (list 1 2 3) eq?) 'yes]
  [_ 'no])
(match (list 1 2 3)
  [(list 1 2 (== 3 =)) 'yes]
  [_ 'no])
]
}


@defform[(struct* struct-id ([field pat] ...))]{
 一个 @racket[match] 模式形式，匹配名为 @racket[struct-id] 的结构类型的实例，其中实例中字段 @racket[field] 匹配相应的 @racket[pat]。这些字段不包括来自超类型的字段。

 @racket[struct-id] 的任何字段均可省略，且这些字段可以按任意顺序出现。

 @examples[
  #:eval match-eval
  (eval:no-prompt
   (struct tree (val left right))
   (struct tree* tree (val)))
  (match (tree 0 (tree 1 #f #f) #f)
    [(struct* tree ([val a]
                    [left (struct* tree ([right #f] [val b]))]))
     (list a b)])
  (match (tree* 0 #f #f 42)
    [(and (struct* tree* ([val a]))
          (struct* tree ([val b])))
     (list a b)])
 ]
 }

@; ----------------------------------------------------------------------

@close-eval[match-eval]
