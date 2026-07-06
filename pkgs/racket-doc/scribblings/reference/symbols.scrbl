#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/symbol))

@title[#:tag "symbols"]{Symbols}

@guideintro["symbols"]{symbols}

@section-index["symbols" "生成"]
@section-index["symbols" "唯一"]

一个 @deftech{symbol} 就像一个不可变的 string，但 symbols 通常是
@tech{interned}，因此具有相同字符内容的两个 symbols 通常是 @racket[eq?]。
默认 reader（参见 @secref["parse-symbol"]）产生的所有 symbols 都是
@tech{interned}。

@racket[string->uninterned-symbol] 和 @racket[gensym] 这两个 procedures 生成
@deftech{uninterned} symbols，即不与任何其他 symbol @racket[eq?]、
@racket[eqv?] 或 @racket[equal?] 的 symbols，尽管它们可能与其他 symbols 
打印得相同。

@racket[string->unreadable-symbol] procedure 返回一个 @deftech{unreadable symbol}，
该 symbol 是部分 interned 的。默认 reader（参见 @secref["parse-symbol"]）从不
产生 unreadable symbol，但对 @racket[string->unreadable-symbol] 的两次调用
如果使用 @racket[equal?] 的 strings，会产生 @racket[eq?] 的结果。
一个 unreadable symbol 可能与 interned 或 uninterned symbol 打印得相同。
Unreadable symbols 在 expansion 和 compilation 中用于避免与源文件中
出现的 symbols 发生冲突；它们通常不会直接生成，但可能出现在
@racket[identifier-binding] 等函数的结果中。

Interned 和 unreadable symbols 仅由内部 symbol 表 weak 持有。这种弱性永远
不会影响 @racket[eq?]、@racket[eqv?] 或 @racket[equal?] 测试的结果，但当
一个 symbol 被放入 weak box 时（参见 @secref["weakbox"]），用作
weak @tech{hash table} 的 key 时（参见 @secref["hashtables"]），或用作
ephemeron key 时（参见 @secref["ephemerons"]），可能会消失。

@see-read-print["symbol"]{symbols}

@defproc[(symbol? [v any/c]) boolean?]{如果 @racket[v] 是一个
 symbol，则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(symbol? 'Apple) (symbol? 10)]}


@defproc[(symbol-interned? [sym symbol?]) boolean?]{如果 @racket[sym] 是
 @tech{interned}，则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(symbol-interned? 'Apple)
             (symbol-interned? (gensym))
             (symbol-interned? (string->unreadable-symbol "Apple"))]}

@defproc[(symbol-unreadable? [sym symbol?]) boolean?]{如果 @racket[sym] 是一个
 @tech{unreadable symbol}，则返回 @racket[#t]，否则返回 @racket[#f]。

@mz-examples[(symbol-unreadable? 'Apple)
             (symbol-unreadable? (gensym))
             (symbol-unreadable? (string->unreadable-symbol "Apple"))]}

@defproc[(symbol->string [sym symbol?]) string?]{返回一个新分配的
 mutable string，其字符与 @racket[sym] 中的字符相同。

另参见 @racketmodname[racket/symbol] 中的 @racket[symbol->immutable-string]。

@mz-examples[(symbol->string 'Apple)]}


@defproc[(string->symbol [str string?]) symbol?]{返回一个
 @tech{interned} symbol，其字符与 @racket[str] 中的字符相同。

@mz-examples[(string->symbol "Apple") (string->symbol "1")]}


@defproc[(string->uninterned-symbol [str string?]) symbol?]{类似于
 @racket[(string->symbol str)]，但结果是一个新的 @tech{uninterned} symbol。
 用相同的 @racket[str] 调用 @racket[string->uninterned-symbol] 两次会返回两个
 不同的 symbols。

@mz-examples[(string->uninterned-symbol "Apple")
             (eq? 'a (string->uninterned-symbol "a"))
             (eq? (string->uninterned-symbol "a")
                  (string->uninterned-symbol "a"))]}


@defproc[(string->unreadable-symbol [str string?]) symbol?]{类似于
 @racket[(string->symbol str)]，但结果是一个新的 @tech{unreadable symbol}。
 对等效的 @racket[str]s 调用 @racket[string->unreadable-symbol] 两次会返回
 相同的 symbol，但 @racket[read] 从不产生该 symbol。

@mz-examples[(string->unreadable-symbol "Apple")
             (eq? 'a (string->unreadable-symbol "a"))
             (eq? (string->unreadable-symbol "a")
                  (string->unreadable-symbol "a"))]}


@defproc[(gensym [base (or/c string? symbol?) "g"]) symbol?]{返回一个
 具有自动生成名称的新 @tech{uninterned} symbol。可选的 @racket[base] 参数
 是一个前缀 symbol 或 string。

@mz-examples[(gensym "apple")]}


@defproc[(symbol<? [a-sym symbol?] [b-sym symbol?] ...) boolean?]{

如果参数按顺序排序则返回 @racket[#t]，其中每对 symbols 的比较
使用 @racket[symbol->string] 与 @racket[string->bytes/utf-8]
和 @racket[bytes<?] 进行。

@history/arity[]}

@; ----------------------------------------
@section{Additional Symbol Functions}

@note-lib-only[racket/symbol]
@(define symbol-eval (make-base-eval))
@examples[#:hidden #:eval symbol-eval (require racket/symbol)]

@history[#:added "7.6"]

@defproc[(symbol->immutable-string [sym symbol?]) (and/c string? immutable?)]{

类似于 @racket[symbol->string]，但结果是一个 immutable string，
不一定是新分配的。

@examples[#:eval symbol-eval
          (symbol->immutable-string 'Apple)
          (immutable? (symbol->immutable-string 'Apple))]

@history[#:added "7.6"]}

@; ----------------------------------------
@close-eval[symbol-eval]
