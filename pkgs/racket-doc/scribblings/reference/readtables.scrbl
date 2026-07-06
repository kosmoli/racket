#lang scribble/doc
@(require scribble/bnf "mz.rkt")

@title[#:style 'toc]{读取器扩展}

Racket 的读取器可以通过三种方式扩展：通过 @tech{readtable} 中的 reader-macro
过程（参见 @secref["readtables"]）、通过 @litchar{#reader} 形式（参见 @secref["parse-reader"]），
或通过返回"special"结果过程的 custom-port byte reader（参见 @secref["customport"]）。
所有这三种 @deftech{reader extension procedures} 接受类似的参数，并且它们的结果
由 @racket[read] 和 @racket[read-syntax]（或更准确地说，由默认的 read handler；
参见 @racket[port-read-handler]）以相同方式处理。

@local-table-of-contents[]

@;------------------------------------------------------------------------
@section[#:tag "readtables"]{读取表}

@secref["default-readtable-dispatch"] 中的调度表对应于默认的 @deftech{readtable}。
通过创建新的 readtable 并通过 @racket[current-readtable] 参数安装它，可以扩展读取器的行为。

读取器在特定时间查阅 readtable：

@itemize[

 @item{查找 datum 的起始位置时；}

 @item{确定如何解析以 @litchar{#} 开头的 datum 时；}

 @item{查找分隔符以终止 symbol 或 number 时；}

 @item{在解析为 pair、list、vector 或 hash table 的序列的第一个字符之后，
 查找 opener（如 @litchar{(}）、closer（如 @litchar{)}）或 @litchar{.} 时；或}

 @item{在指定长度 @nonterm{n} 的 vector 中，@litchar{#}@nonterm{n} 之后查找 opener 时。}

]

The readtable is ignored at other times.  In particular, after parsing
a character that is mapped to the default behavior of @litchar{;}, the
readtable 直到发现注释的终止换行符时才被忽略。类似地，直到找到闭合双引号之前，
readtable 不影响 string 解析。同时，如果一个字符被映射到 @litchar{(} 的默认行为，
那么它启动一个序列，该序列由任何映射到闭合括号 @litchar{)} 的字符关闭。
一个明显的例外是，@litchar{|} 的默认解析引用一个 symbol 直到找到匹配字符，
但解析器只是使用启动引用的字符；它不查阅 readtable。

对于许多上下文，@racket[#f] 标识默认的 readtable。特别是，@racket[#f] 是
@racket[current-readtable] 参数的初始值，使读取器表现为 @secref["reader"] 中描述的行为。

@defproc[(readtable? [v any/c]) boolean?]{
如果 @racket[v] 是 readtable，则返回 @racket[#t]，否则返回 @racket[#f]。}

@defproc[(make-readtable [readtable (or/c readtable? #f)]
                         [key (or/c char? #f)]
                         [mode (or/c 'terminating-macro
                                     'non-terminating-macro
                                     'dispatch-macro
                                     char?)]
                         [action (or/c procedure?
                                       readtable?
                                       #f)]
                        ...)
           readtable?]{

创建一个类似于 @racket[readtable]（可以是 @racket[#f] 表示默认 readtable）的新 readtable，
但读取器对每个 @racket[key] 的行为根据给定的 @racket[mode] 和 @racket[action] 进行修改。
@racket[make-readtable] 的 @racket[...] 适用于 @racket[key]、@racket[mode] 和 @racket[action] 全部三个；
换句话说，@racket[make-readtable] 的参数总数必须为 @math{1} 对 @math{3} 取模。

@racket[key]、@racket[mode] 和 @racket[action] 的可能组合如下：

@itemize[

 @item{@racket[(code:line _char (unsyntax @indexed-racket['terminating-macro]) _proc)] ---
 使 @racket[_char] 被解析为分隔符，并且输入字符串中未引用/未注释的 @racket[_char]
 触发对 @deftech{reader macro} @racket[_proc] 的调用；@racket[_proc] 的活动将在下面进一步描述。
 从概念上讲，像 @litchar{;}、@litchar{(} 和 @litchar{)} 这样的字符在默认 readtable 中
 被映射到 terminating reader macro。}

 @item{@racket[(code:line _char (unsyntax @indexed-racket['non-terminating-macro]) _proc)] ---
 类似于 @racket['terminating-macro] 变体，但 @racket[_char] 不被视为分隔符，
 因此它可以在 identifier 或 number 的中间使用。从概念上讲，@litchar{#} 在默认 readtable 中
 被映射到 non-terminating macro。}

 @item{@racket[(code:line _char (unsyntax @indexed-racket['dispatch-macro]) _proc)] ---
 类似于 @racket['non-terminating-macro] 变体，但仅当 @racket[_char] 跟随在 @litchar{#} 之后时
 （或者更准确地说，当字符跟随在已映射到默认 readtable 中 @litchar{#} 行为的字符之后时）。}

 @item{@racket[(code:line _char _like-char _readtable)] ---
 使 @racket[_char] 的解析方式与 @racket[_like-char] 在 @racket[_readtable] 中的解析方式相同，
 其中 @racket[_readtable] 可以是 @racket[#f] 表示默认 readtable。（@racket[_char] 的映射
 不适用于 @litchar{#} 之后，@litchar{#} 通过 @racket['dispatch-macro] 单独配置。）
 将字符映射到与默认读取器中 @litchar{|} 相同的操作意味着该字符开始引用 symbol，
 并且相同的字符终止引用；相反，将字符映射到与 @litchar{"} 相同的操作意味着
 该字符开始一个 string，但 string 仍然以闭合的 @litchar{"} 终止。最后，
 将字符映射到默认 readtable 中的操作意味着该字符的行为对影响原始字符的参数敏感；
 例如，将字符映射到与默认 readtable 中花括号 @litchar["{"] 相同的操作意味着
 当 @racket[read-curly-brace-as-paren] 参数设置为 @racket[#f] 时，该字符被禁止。}

 @item{@racket[(code:line #f (unsyntax @indexed-racket['non-terminating-macro]) _proc)] ---
 替换用于解析没有特定映射的字符的 macro：即，可以使用默认 readtable 启动 symbol 或 number 的字符
 （@litchar{#} 或 @litchar{|} 除外）。}

]

如果为单个 @racket[_char] 提供了多个 @racket['dispatch-macro] 映射，除最后一个外其余都被忽略。
类似地，如果为单个 @racket[_char] 提供了多个非 @racket['dispatch-macro] 映射，
除最后一个外其余都被忽略。

Reader macro @racket[_proc] 必须接受六个参数，并且可以可选地接受两个参数。
前两个参数始终是触发 reader macro 的字符和用于读取的输入端口。
当 reader macro 由 @racket[read-syntax]（或 @racket[read-syntax/recursive]）触发时，
过程会收到四个额外参数，表示已消耗字符的源位置：source name、line number 或 @racket[#f]、
column number 或 @racket[#f] 以及 position 或 @racket[#f]。当 reader macro 由 @racket[read]
（或 @racket[read/recursive]）触发时，如果过程接受两个参数，则只传递两个参数，
否则传递六个参数，其中第三个始终是 @racket[#f]。有关过程结果的信息，请参见 @secref["reader-procs"]。

Reader macro 通常从给定的输入端口读取字符，以产生用作消耗字符的 "reader-macroid-expansion" 的值。
Reader macro 可能产生 special-comment 值（参见 @secref["special-comments"]），使消耗的字符被视为 whitespace，
并且可能使用 @racket[read/recursive] 或 @racket[read-syntax/recursive]。}

@defproc[(readtable-mapping [readtable readtable?] [char char?])
         (values (or/c char?
                       'terminating-macro
                       'non-terminating-macro)
                 (or/c #f procedure?)
                 (or/c #f procedure?))]{

产生关于 @racket[readtable] 中 @racket[char] 的映射信息。结果是三个值：

@itemize[

 @item{either a character (mapping to the same behavior as the
 character in the default readtable), @racket['terminating-macro], or
 @racket['non-terminating-macro]; this result reports the main (i.e.,
 non-@racket['dispatch-macro]) mapping for @racket[char]. When the result
 is a character, then @racket[char] is mapped to the same behavior as the
 returned character in the default readtable.}

 @item{either @racket[#f] or a reader-macro procedure; the result is a
 procedure when the first result is @racket['terminating-macro] or
 @racket['non-terminating-macro].}

 @item{either @racket[#f] or a reader-macro procedure; the result is a
 procedure when the character has a @racket['dispatch-macro] mapping in
 @racket[readtable] to override the default dispatch behavior.}

]

Note that reader-macro procedures for the default readtable are not
directly accessible. To invoke default behaviors, use
@racket[read/recursive] or @racket[read-syntax/recursive] with a
character and the @racket[#f] readtable.}

@(begin
#readerscribble/comment-reader
[examples
;; Provides @racket[raise-read-error] and @racket[raise-read-eof-error]
(require syntax/readerr)

(define (skip-whitespace port)
  ;; Skips whitespace characters, sensitive to the current
  ;; readtable's definition of whitespace
  (let ([ch (peek-char port)])
    (unless (eof-object? ch)
      ;; Consult current readtable:
      (let-values ([(like-ch/sym proc dispatch-proc) 
                    (readtable-mapping (current-readtable) ch)])
        ;; If like-ch/sym is whitespace, then ch is whitespace
        (when (and (char? like-ch/sym)
                   (char-whitespace? like-ch/sym))
          (read-char port)
          (skip-whitespace port))))))

(define (skip-comments read-one port src)
  ;; Recursive read, but skip comments and detect EOF
  (let loop ()
    (let ([v (read-one)])
      (cond
       [(special-comment? v) (loop)]
       [(eof-object? v)
        (let-values ([(l c p) (port-next-location port)])
          (raise-read-eof-error 
           "unexpected EOF in tuple" src l c p 1))]
       [else v]))))

(define (parse port read-one src)
  ;; First, check for empty tuple
  (skip-whitespace port)
  (if (eq? #\> (peek-char port))
      null
      (let ([elem (read-one)])
        (if (special-comment? elem)
            ;; Found a comment, so look for > again
            (parse port read-one src)
            ;; Non-empty tuple:
            (cons elem
                  (parse-nonempty port read-one src))))))

(define (parse-nonempty port read-one src)
  ;; Need a comma or closer
  (skip-whitespace port)
  (case (peek-char port)
    [(#\>) (read-char port)
     ;; Done
     null]
    [(#\,) (read-char port)
     ;; Read next element and recur
     (cons (skip-comments read-one port src)
           (parse-nonempty port read-one src))]
    [else
     ;; Either a comment or an error; grab location (in case
     ;; of error) and read recursively to detect comments
     (let-values ([(l c p) (port-next-location port)]
                  [(v) (read-one)])
       (cond
        [(special-comment? v)
         ;; It was a comment, so try again
         (parse-nonempty port read-one src)]
        [else
         ;; Wasn't a comment, comma, or closer; error
         ((if (eof-object? v) 
              raise-read-eof-error 
              raise-read-error)
          "expected `,` or `>`" src l c p 1)]))]))

(define (make-delims-table)
  ;; Table to use for recursive reads to disallow delimiters
  ;;  (except those in sub-expressions)
  (letrec ([misplaced-delimiter 
            (case-lambda
             [(ch port) (misplaced-delimiter ch port #f #f #f #f)]
             [(ch port src line col pos)
              (raise-read-error 
               (format "misplaced `~a` in tuple" ch)
               src line col pos 1)])])
    (make-readtable (current-readtable)
                    #\, 'terminating-macro misplaced-delimiter
                    #\> 'terminating-macro misplaced-delimiter)))

(define (wrap l) 
  `(make-tuple (list ,@l)))

(define parse-open-tuple
  (case-lambda
   [(ch port) 
    ;; `read` mode
    (wrap (parse port 
                 (lambda () 
                   (read/recursive port #f 
                                   (make-delims-table)))
                 (object-name port)))]
   [(ch port src line col pos)
    ;; `read-syntax` mode
    (datum->syntax
     #f
     (wrap (parse port 
                  (lambda () 
                    (read-syntax/recursive src port #f 
                                           (make-delims-table)))
                  src))
     (let-values ([(l c p) (port-next-location port)])
       (list src line col pos (and pos (- p pos)))))]))
    

(define tuple-readtable
  (make-readtable #f #\< 'terminating-macro parse-open-tuple))

(parameterize ([current-readtable tuple-readtable])
  (read (open-input-string "<1 , 2 , \"a\">")))

(parameterize ([current-readtable tuple-readtable])
  (read (open-input-string 
         "< #||# 1 #||# , #||# 2 #||# , #||# \"a\" #||# >")))

(define tuple-readtable+
  (make-readtable tuple-readtable
                  #\* 'terminating-macro (lambda a 
                                           (make-special-comment #f))
                  #\_ #\space #f))
(parameterize ([current-readtable tuple-readtable+])
  (read (open-input-string "< * 1 __,__  2 __,__ * \"a\" * >")))
])

@;------------------------------------------------------------------------
@section[#:tag "reader-procs"]{Reader-Extension Procedures}

Calls to @techlink{reader extension procedures} can be triggered
through @racket[read], @racket[read/recursive], or @racket[read-syntax].
In addition, a special-read procedure
can be triggered by calls to @racket[read-char-or-special], or
by the context of @racket[read-bytes-avail!],
@racket[peek-bytes-avail!*], @racket[read-bytes-avail!], and
@racket[peek-bytes-avail!*].

Optional arities for reader-macro and special-result procedures allow
them to distinguish reads via @racket[read], @|etc|, from reads via
@racket[read-syntax], @|etc| (where the source value is @racket[#f] and
no other location information is available).

When a reader-extension procedure is called in syntax-reading mode
(via @racket[read-syntax], @|etc|), it should generally return a syntax
object that has no lexical context (e.g., a syntax object created
using @racket[datum->syntax] with @racket[#f] as the first
argument and with the given location information as the third
argument). Another possible result is a special-comment value (see
@secref["special-comments"]). If the procedure's result is not a
syntax object and not a special-comment value, it is converted to one
using @racket[datum->syntax].

When a reader-extension procedure is called in non-syntax-reading
modes, it should generally not return a syntax object. If a syntax
object is returned, it is converted to a plain value using
@racket[syntax->datum].

In either context, when the result from a reader-extension procedure
is a special-comment value (see @secref["special-comments"]), then
@racket[read], @racket[read-syntax], @|etc| treat the value as a
delimiting comment and otherwise ignore it.

Also, in either context, the result may be copied to prevent mutation
to vectors or boxes before the read result is completed, and to
support the construction of graphs with cycles. Mutable boxes,
vectors, and @tech{prefab} structures are copied, along with any
pairs, boxes, vectors, prefab structures that lead to such mutable
values, to placeholders produced by a recursive read (see
@racket[read/recursive]), or to references of a shared value. Graph
structure (including cycles) is preserved in the copy.

@;------------------------------------------------------------------------
@section[#:tag "special-comments"]{Special Comments}

@defproc[(make-special-comment [v any/c]) special-comment?]{

Creates a special-comment value that encapsulates @racket[v]. The
@racket[read], @racket[read-syntax], @|etc|, procedures treat values
constructed with @racket[make-special-comment] as delimiting
whitespace when returned by a reader-extension procedure (see
@secref["reader-procs"]).}

@defproc[(special-comment? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is the result of
@racket[make-special-comment], @racket[#f] otherwise.}

@defproc[(special-comment-value [sc special-comment?]) any]{

Returns the value encapsulated by the special-comment value
@racket[sc]. This value is never used directly by a reader, but it
might be used by the context of a @racket[read-char-or-special], @|etc|,
call that detects a special comment.}
