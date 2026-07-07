#lang scribble/doc
@(require "mz.rkt" (for-label syntax/parse))

@(define lit-ellipsis (racket ...))
@(define lit-_ (racket _))
@(define meta-dots @racketmetafont{...})

@(define syntax-eval
   (lambda ()
     (let ([the-eval (make-base-eval)])
       (the-eval '(require (for-syntax racket/base)))
       the-eval)))

@title[#:tag "stx-patterns"]{Pattern-Based Syntax Matching}

@defform/subs[#:literals (_)
              (syntax-case stx-expr (literal-id ...)
                clause ...)
              ([clause [pattern result-expr]
                       [pattern fender-expr result-expr]]
               [pattern np-pattern
                        (pattern ...)
                        (pattern ...+ . np-pattern)
                        (pattern ... pattern ellipsis pattern ... . np-pattern)]
               [np-pattern _
                          id
                          (code:line #,(tt "#")(pattern ...))
                          (code:line #,(tt "#")(pattern ... pattern ellipsis pattern ...))
                          (code:line #,(tt "#&")pattern)
                          (code:line #,(tt "#s")(key-datum pattern ...))
                          (code:line #,(tt "#s")(key-datum pattern ... pattern ellipsis pattern ...))
                          (ellipsis stat-pattern)
                          const]
               [stat-pattern id
                             (stat-pattern ...)
                             (stat-pattern ...+ . stat-pattern)
                             (code:line #,(tt "#")(stat-pattern ...))
                             (code:line #,(tt "#&")stat-pattern)
                             (code:line #,(tt "#s")(key-datum stat-pattern ...))
                             const]
               [ellipsis #,lit-ellipsis])]{

查找第一个与 @racket[stx-expr] 产生的 syntax object 匹配的 @racket[pattern]，
并且对应的 @racket[fender-expr]（如果存在）产生真值；结果来自对应的 @racket[result-expr]，
它位于 @racket[syntax-case] 形式的 tail position。如果没有 @racket[clause] 匹配，
则 @exnraise[exn:fail:syntax]；异常通过调用 @racket[raise-syntax-error] 产生，
其中 @racket[#f] 作为名称参数，一条通用错误消息字符串，
@racket[stx-expr] 的结果作为最后一个参数。

syntax object 按如下方式匹配 @racket[pattern]：

 @specsubform[_]{

 @lit-_ pattern（即与 @lit-_ 绑定相同且不在 @racket[literal-id] 中的标识符）
匹配任意 syntax object。}

 @specsubform[id]{

 An @racket[id] matches any syntax object when it is not bound to
 @racket[...] or @racket[_] and does not have the same binding as
 any @racket[literal-id]. The @racket[id] is further bound as
 @deftech{pattern variable} for the corresponding @racket[fender-expr]
 (if any) and @racket[result-expr]. A pattern-variable binding is a
 transformer binding; the pattern variable can be referenced only
 through forms like @racket[syntax]. The binding's value is the syntax
 object that matched the pattern with a @deftech{depth marker} of
 @math{0}.

 With a @racket[stat-pattern], @racket[...] is not treated specially.
 It either matches a @racket[literal-id] or is bound as a
 pattern variable.

 An @racket[id] that has the same binding as a @racket[literal-id]
 matches a syntax object that is an identifier with the same binding
 in the sense of @racket[free-identifier=?].  The match does not
 introduce any @tech{pattern variables}.}

 @specsubform[(pattern ...)]{

 @racket[(pattern @#,meta-dots)] pattern 匹配这样的 syntax object：
其 datum 形式（即不带词法信息）是一个列表，
列表元素个数与该 pattern 中子 @racket[pattern] 的个数相同，
且与列表的每个元素对应的 syntax object 匹配对应的子 @racket[pattern]。
子 @racket[pattern] 绑定的所有 @tech{pattern variable}
都由完整的 pattern 绑定；所有绑定必须互不相同。}

 @specsubform[(pattern ...+ . np-pattern)]{

 类似于上一种 pattern，但匹配不一定是列表的 syntax object；
对于最后一个 @racket[np-pattern] 之前的 @math{n} 个子 @racket[pattern]，
syntax object 的 datum 必须是一个 pair，使得取 @math{n-1} 次 @racket[cdr]
都能产生 pair。最终的 @racket[np-pattern] 与对应于第 @math{n} 次
@racket[cdr] 的 syntax object（或使用最近外层 syntax object 的词法上下文
和 source location 对 datum 进行 @racket[datum->syntax] 强制转换的结果）进行匹配。}

 @specsubform[(pattern ... pattern ellipsis pattern ...)]{

 类似于 @racket[(pattern @#,meta-dots)] 类型的 pattern，
但匹配一个包含任意数量（零个或多个）元素的 syntax object，
这些元素匹配相对于其他子 @racket[pattern] 位于对应位置的
子 @racket[pattern] 后跟 @racket[ellipsis] 的部分。

对于每个被子 @racket[pattern] 后跟 @racket[ellipsis] 所绑定的 pattern variable，
更大的 pattern 将同一个 pattern variable 绑定到一个值列表，
每个值对应于匹配到子 @racket[pattern] 的 syntax object 的每个元素，
其 @deftech{depth marker} 递增。（子 @racket[pattern] 本身可能包含
@racket[ellipsis]，导致 pattern variable 被绑定到 syntax object
的列表的列表，其 @deftech{depth marker} 为 @math{2}，依此类推。）

所有包含 @racket[ellipsis] 的 pattern 形式仅在 @racket[ellipsis]
不在 @racket[literal-id] 中时才适用。}

 @specsubform[(pattern ... pattern ellipsis pattern ... . np-pattern)]{

类似于上一种类型的 pattern，但带有最后一个 @racket[np-pattern]，
如 @racket[(pattern ...+ . np-pattern)] 中那样。
最后一个 @racket[np-pattern] 永不匹配 datum 为 pair 的 syntax object。}

 @specsubform[(code:line #,(tt "#")(pattern ...))]{

类似于 @racket[(pattern @#,meta-dots)] pattern，
但匹配一个 vector syntax object，其元素匹配对应的子 @racket[pattern]。}

 @specsubform[(code:line #,(tt "#")(pattern ... pattern ellipsis pattern ...))]{

类似于 @racket[(pattern ... pattern ellipsis pattern ...)] pattern，
但 matching 一个 vector syntax object，其元素匹配对应的子 @racket[pattern]。}

 @specsubform[(code:line #,(tt "#&")pattern)]{

匹配一个 box syntax object，其内容匹配 @racket[pattern]。}

 @specsubform[(code:line #,(tt "#s")(key-datum pattern ...))]{

类似于 @racket[(pattern @#,meta-dots)] pattern，
但匹配一个 @tech{prefab} structure syntax object，其字段匹配对应的
子 @racket[pattern]。@racket[key-datum] 必须对应于
@racket[make-prefab-struct] 的有效第一个参数。}

 @specsubform[(code:line #,(tt "#s")(key-datum pattern ... pattern ellipsis pattern ...))]{

类似于 @racket[(pattern @#,meta-dots pattern ellipsis pattern @#,meta-dots)] pattern，
但匹配一个 @tech{prefab} structure syntax object，
其元素匹配对应的子 @racket[pattern]。}

 @specsubform[(ellipsis stat-pattern)]{

与 @racket[stat-pattern] 匹配相同，
@racket[stat-pattern] 类似于 @racket[pattern]，
但绑定为 @racket[...] 的标识符与其他 @racket[id] 一样对待。}

 @specsubform[const]{

@racket[const] 是任何不匹配上述形式之一的 datum；
syntax object 在 datum 与 @racket[quote]d 的 @racket[const] @racket[equal?] 时
匹配 @racket[const] pattern。}

如果 @racket[stx-expr] 产生非 @tech{syntax object} 的值，
则结果会通过 @racket[datum->syntax] 转换为 syntax object，
并使用 @racket[stx-expr] 的词法上下文和 source location。

如果 @racket[stx-expr] 产生的是 @tech{tainted} 的 syntax object，
那么 @racket[pattern] 绑定的任何 syntax object 也是 @tech{tainted}。

@mz-examples[
(require (for-syntax racket/base))
(define-syntax (swap stx)
  (syntax-case stx ()
    [(_ a b) #'(let ([t a])
                 (set! a b)
                 (set! b t))]))

(let ([x 5] [y 10])
  (swap x y)
  (list x y))

(syntax-case #'(ops 1 2 3 => +) (=>)
  [(_ x ... => op) #'(op x ...)])

(syntax-case #'(let ([x 5] [y 9] [z 12])
                 (+ x y z))
             (let)
  [(let ([var expr] ...) body ...)
   (list #'(var ...)
         #'(expr ...))])
]}

@defform[(syntax-case* stx-expr (literal-id ...) id-compare-expr
           clause ...)]{

Like @racket[syntax-case], but @racket[id-compare-expr] must produce a
procedure that accepts two arguments. A @racket[literal-id] in a
@racket[_pattern] matches an identifier for which the procedure 
returns true when given the identifier to match (as the first argument)
and the identifier in the @racket[_pattern] (as the second argument).

In other words, @racket[syntax-case] is like @racket[syntax-case*] with
an @racket[id-compare-expr] that produces @racket[free-identifier=?].}


@defform[(with-syntax ([pattern stx-expr] ...)
           body ...+)]{

Similar to @racket[syntax-case], in that it matches a @racket[pattern]
to a syntax object. Unlike @racket[syntax-case], all @racket[pattern]s
are matched, each to the result of a corresponding @racket[stx-expr],
and the pattern variables from all matches (which must be distinct)
are bound with a single @racket[body] sequence. The result of the
@racket[with-syntax] form is the result of the last @racket[body],
which is in tail position with respect to the @racket[with-syntax]
form.

If any @racket[pattern] fails to match the corresponding
@racket[stx-expr], the @exnraise[exn:fail:syntax].

A @racket[with-syntax] form is roughly equivalent to the following
@racket[syntax-case] form:

@racketblock[
(syntax-case (list stx-expr ...) ()
  [(pattern ...) (let () body ...+)])
]

However, if any individual @racket[stx-expr] produces a
non-@tech{syntax object}, then it is converted to one using
@racket[datum->syntax] and the lexical context and source location of
the individual @racket[stx-expr].

@examples[#:eval (syntax-eval)
(define-syntax (hello stx)
  (syntax-case stx ()
    [(_ name place)
     (with-syntax ([print-name #'(printf "~a\n" 'name)]
                   [print-place #'(printf "~a\n" 'place)])
       #'(begin
           (define (name times)
             (printf "Hello\n")
             (for ([i (in-range 0 times)])
                  print-name))
           (define (place times)
             (printf "From\n")
             (for ([i (in-range 0 times)])
                  print-place))))]))

(hello jon utah)
(jon 2)
(utah 2)

(define-syntax (math stx)
  (define (make+1 expression)
    (with-syntax ([e expression])
      #'(+ e 1)))
  (syntax-case stx ()
    [(_ numbers ...)
     (with-syntax ([(added ...)
                    (map make+1
                         (syntax->list #'(numbers ...)))])
       #'(begin
           (printf "got ~a\n" added)
           ...))]))

(math 3 1 4 1 5 9)
]}

@defform[#:literals (~? ~@) (syntax template)
         #:grammar
         ([template id
                    (head-template ...)
                    (head-template ...+ . template)
                    (code:line #,(tt "#")(head-template ...))
                    (code:line #,(tt "#&")template)
                    (code:line #,(tt "#s")(key-datum head-template ...))
                    (~? template template)
                    (ellipsis stat-template)
                    const]
          [head-template template
                         (code:line head-template ellipsis ...+)
                         (~@ . template)
                         (~? head-template head-template)
                         (~? head-template)]
          [stat-template @#,elem{like @svar{template}, but without @|lit-ellipsis|,
                                 @racket[~?], and @racket[~@]}]
          [ellipsis #,lit-ellipsis])]{

Constructs a syntax object based on a @racket[template], which can
include @tech{pattern variables} bound by @racket[syntax-case] or
@racket[with-syntax].

A @svar[template] produces a single syntax object. A
@svar[head-template] produces a sequence of zero or more syntax
objects. A @svar[stat-template] is like a @svar[template], except that
@|lit-ellipsis|, @racket[~?], and @racket[~@] are interpreted as
constants instead of template forms.

A @svar[template] produces a syntax object as follows:

 @specsubform[id]{

 If @racket[id] is bound as a @tech{pattern variable}, then
 @racket[id] as a template produces the @tech{pattern variable}'s
 match result. Unless the @racket[id] is a sub-@racket[template] that is
 replicated by @racket[ellipsis] in a larger @racket[template], the
 @tech{pattern variable}'s value must be a syntax object with a
 @tech{depth marker} of @math{0} (as opposed to a list of
 matches).

 More generally, if the @tech{pattern variable}'s value has a depth
 marker @math{n}, then it can only appear within a template where it
 is replicated by at least @math{n} @racket[ellipsis]es. In that case,
 the template will be replicated enough times to use each match result
 at least once.

 If @racket[id] is not bound as a pattern variable, then @racket[id]
 as a template produces @racket[(quote-syntax id)].}

 @specsubform[(head-template ...)]{

 Produces a syntax object whose datum is a list, and where the
 elements of the list correspond to syntax objects produced by the
 @racket[head-template]s.}

 @specsubform[(head-template ... . template)]{

  Like the previous form, but the result is not necessarily a list;
  instead, the place of the empty list in the resulting syntax object's
  datum is taken by the syntax object produced by @racket[template].}

 @specsubform[(code:line #,(tt "#")(head-template ...))]{

   Like the @racket[(head-template ...)] form, but producing a syntax
   object whose datum is a vector instead of a list.}

 @specsubform[(code:line #,(tt "#&")template)]{

   Produces a syntax object whose datum is a box holding the
   syntax object produced by @racket[template].}

 @specsubform[(code:line #,(tt "#s")(key-datum head-template ...))]{

   Like the @racket[(head-template ...)] form, but producing a syntax
   object whose datum is a @tech{prefab} structure instead of a list.
   The @racket[key-datum] must correspond to a valid first argument of
   @racket[make-prefab-struct].}

 @specsubform[#:literals (~?) (~? template1 template2)]{

   Produces the result of @racket[template1] if @racket[template1] has no
   pattern variables with ``missing values''; otherwise, produces the result of
   @racket[template2].

   A pattern variable bound by @racket[syntax-case] never has a missing value, but
   pattern variables bound by @racket[syntax-parse] (for example, @racket[~or] or
   @racket[~optional] patterns) can.

   @examples[#:eval (let ([ev (syntax-eval)]) (ev '(require syntax/parse/pre)) ev)
   (syntax-parse #'(m 1 2 3)
     [(_ (~optional (~seq #:op op:expr)) arg:expr ...)
      #'((~? op +) arg ...)])
   (syntax-parse #'(m #:op max 1 2 3)
     [(_ (~optional (~seq #:op op:expr)) arg:expr ...)
      #'((~? op +) arg ...)])
   ]}

 @specsubform[(ellipsis stat-template)]{

  Produces the same result as @racket[stat-template], which is like a
  @racket[template], but @racket[...], @racket[~?], and @racket[~@]
  are treated like an @racket[id] (with no pattern binding).}

 @specsubform[const]{

  A @racket[const] template is any form that does not match the
  preceding cases, and it produces the result @racket[(quote-syntax
  const)].}

A @racket[head-template] produces a sequence of syntax objects; that sequence is
``inlined'' into the result of the enclosing @racket[template]. The result of a
@racket[head-template] is defined as follows:

 @specsubform[template]{

   Produces one syntax object, according to the rules for @svar[template]
   above.}

 @specsubform[(code:line head-template ellipsis ...+)]{

  Generates a sequence of syntax objects by ``@racket[map]ping'' the
  @racket[head-template] over the values of its pattern variables. The number of
  iterations depends on the values of the @tech{pattern variables} referenced
  within the sub-template.

  To be more precise: Let @racket[_outer] be @racket[_inner] followed by one
  ellipsis. A @tech{pattern variable} is an @deftech{iteration pattern variable}
  for @racket[_outer] if occurs at a depth equal to its @tech{depth
  marker}. There must be at least one; otherwise, an error is raised. If there
  are multiple iteration variables, then all of their values must be lists of
  the same length. The result for @racket[_outer] is produced by
  @racket[map]ping the @racket[_inner] template over the @tech{iteration pattern
  variable} values and decreasing their effective @tech{depth markers} by 1
  within @racket[_inner]. The @racket[_outer] result is formed by appending the
  @racket[_inner] results.

  Consequently, if a @tech{pattern variable} occurs at a depth greater than its
  @tech{depth marker}, it is used as an @tech{iteration pattern variable} for
  the innermost ellipses but not the outermost. A @tech{pattern variable} must
  not occur at a depth less than its @tech{depth marker}; otherwise, an error is
  raised.}

 @defsubform[(~@ . template)]{

   Produces the sequence of elements in the syntax list produced by
   @racket[template]. If @racket[template] does not produce a proper syntax list,
   an exception is raised.

   @examples[#:eval (syntax-eval)
   (with-syntax ([(key ...) #'('a 'b 'c)]
                 [(val ...) #'(1 2 3)])
     #'(hash (~@ key val) ...))
   (with-syntax ([xs #'(2 3 4)])
     #'(list 1 (~@ . xs) 5))
   ]}

 @defsubform[(~? head-template1 head-template2)]{

   Produces the result of @racket[head-template1] if none of its pattern
   variables have ``missing values''; otherwise produces the result of
   @racket[head-template2]. }

 @specsubform[#:literals (~?) (~? head-template)]{

   Produces the result of @racket[head-template] if none of its pattern
   variables have ``missing values''; otherwise produces nothing.

   Equivalent to @racket[(~? head-template (~@))]. }

A @racket[(#,(racketkeywordfont "syntax") template)] form is normally
abbreviated as @racket[#'template]; see also
@secref["parse-quote"]. If @racket[template] contains no pattern
variables, then @racket[#'template] is equivalent to
@racket[(quote-syntax template)].

@history[#:changed "6.90.0.25" @elem{Added @racket[~@] and @racket[~?].}]
}


@defform[(quasisyntax template)]{

Like @racket[syntax], but @racket[(@#,racket[unsyntax]
_expr)] and @racket[(@#,racket[unsyntax-splicing] _expr)]
escape to an expression within the @racket[template].

The @racket[_expr] must produce a syntax object (or syntax list) to be
substituted in place of the @racket[unsyntax] or
@racket[unsyntax-splicing] form within the quasiquoting template, just
like @racket[unquote] and @racket[unquote-splicing] within
@racket[quasiquote], except that a hash table value position is not
an escape position for @racket[quasisyntax]. (If the escaped expression does not generate a
syntax object, it is converted to one in the same way as for the
right-hand side of @racket[with-syntax].)  Nested
@racket[quasisyntax]es introduce quasiquoting layers in the same way
as nested @racket[quasiquote]s.

Also analogous to @racket[quasiquote], the reader converts @litchar{#`}
to @racket[quasisyntax], @litchar{#,} to @racket[unsyntax], and
@litchar["#,@"] to @racket[unsyntax-splicing]. See also
@secref["parse-quote"].}



@defform[(unsyntax expr)]{

Illegal as an expression form. The @racket[unsyntax] form is for use
only with a @racket[quasisyntax] template.}


@defform[(unsyntax-splicing expr)]{

Illegal as an expression form. The @racket[unsyntax-splicing] form is
for use only with a @racket[quasisyntax] template.}


@defform[(syntax/loc loc-expr template)
         #:contracts ([loc-expr (or/c #f srcloc? syntax?
                                      (list/c any/c
                                              (or/c exact-positive-integer? #f)
                                              (or/c exact-nonnegative-integer? #f)
                                              (or/c exact-positive-integer? #f)
                                              (or/c exact-nonnegative-integer? #f))
                                      (vector/c any/c
                                                (or/c exact-positive-integer? #f)
                                                (or/c exact-nonnegative-integer? #f)
                                                (or/c exact-positive-integer? #f)
                                                (or/c exact-nonnegative-integer? #f)))])]{

Like @racket[syntax], except that the immediate resulting syntax
object takes its source-location information from the result of
@racket[loc-expr].

Only the source location of the immediate result---the ``outermost''
syntax object---is adjusted. The source location is @emph{not}
adjusted if both the source and position of @racket[loc-expr] are
@racket[#f]. The source location is adjusted only if the resulting
syntax object comes from the template itself rather than the value of
a syntax pattern variable. For example, if @racket[_x] is a syntax
pattern variable, then @racket[(syntax/loc loc-expr _x)] does not use
the location of @racket[loc-expr].

@history[#:changed "6.90.0.25" @elem{Previously, @racket[syntax/loc]
did not enforce the contract on @racket[loc-expr] if @racket[template]
was just a pattern variable.}
         #:changed "8.2.0.6" @elem{Allows @racket[loc-expr] to be any
source location value that @racket[datum->syntax] accepts.}]}

@defform[(quasisyntax/loc loc-expr template)
         #:contracts ([loc-expr (or/c #f srcloc? syntax?
                                      (list/c any/c
                                              (or/c exact-positive-integer? #f)
                                              (or/c exact-nonnegative-integer? #f)
                                              (or/c exact-positive-integer? #f)
                                              (or/c exact-nonnegative-integer? #f))
                                      (vector/c any/c
                                                (or/c exact-positive-integer? #f)
                                                (or/c exact-nonnegative-integer? #f)
                                                (or/c exact-positive-integer? #f)
                                                (or/c exact-nonnegative-integer? #f)))])]{

Like @racket[quasisyntax], but with source-location assignment like
@racket[syntax/loc].

@history[#:changed "8.2.0.6" @elem{Allows @racket[loc-expr] to be any
source location value that @racket[datum->syntax] accepts.}]}

@defform[(quote-syntax/prune id)]{

Like @racket[quote-syntax], but the lexical context of @racket[id] is
pruned via @racket[identifier-prune-lexical-context] to including
binding only for the symbolic name of @racket[id] and for
@racket['#%top]. Use this form to quote an identifier when its lexical
information will not be transferred to other syntax objects (except
maybe to @racket['#%top] for a top-level binding).}


@defform[(syntax-rules (literal-id ...)
           [(id . pattern) template] ...)]{

Equivalent to

@racketblock/form[
(lambda (stx)
  (syntax-case stx (literal-id ...)
    [(_generated-id . pattern) (syntax-protect (syntax template))] ...))
]

where each @racket[_generated-id] binds no identifier in the
corresponding @racket[template].
This in particular means that the @racket[id] positions are ignored.
Conventionally, the @racket[id] positions should be the identifier @racket[_].

@mz-examples[
(define-syntax my-let*
  (syntax-rules ()
    [(_ () body ...) (let () body ...)]
    [(_ ([x v] binding ...) body ...)
     (let ([x v])
       (my-let* (binding ...) body ...))]))

(my-let* ([x 42]
          [x (+ x 1)])
  x)
]}


@defform[(syntax-id-rules (literal-id ...)
           [pattern template] ...)]{

Equivalent to

@racketblock[
(make-set!-transformer
 (lambda (stx)
   (syntax-case stx (literal-id ...)
     [pattern (syntax-protect (syntax template))] ...)))
]}


@defform[(define-syntax-rule (id . pattern) template)]{

Equivalent to

@racketblock/form[
(define-syntax id
  (syntax-rules ()
   [(id . pattern) template]))
]

but with syntax errors potentially phrased in terms of 
@racket[pattern].}


@defidform[...]{

The @racket[...] transformer binding prohibits @racket[...] from
being used as an expression. This binding is useful only in syntax
patterns and templates (or other unrelated expression forms
that treat it specially like @racket[->]), where it indicates repetitions
of a pattern or template. See @racket[syntax-case] and @racket[syntax].}

@defidform[_]{

The @racket[_] transformer binding prohibits @racket[_] from being
used as an expression. This binding is useful only in syntax patterns,
where it indicates a pattern that matches any syntax object. See
@racket[syntax-case].}

@deftogether[[
@defidform[#:link-target? #f ~?]
@defidform[#:link-target? #f ~@]
]]{

The @racket[~?] and @racket[~@] transformer bindings prohibit these forms from
being used as an expression. The bindings are useful only in syntax templates.
See @racket[syntax].

@history[#:added "6.90.0.25"]}

@defproc[(syntax-pattern-variable? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a value that, as a
transformer-binding value, makes the bound variable as pattern
variable in @racket[syntax] and other forms. To check whether an
identifier is a pattern variable, use @racket[syntax-local-value] to
get the identifier's transformer value, and then test the value with
@racket[syntax-pattern-variable?].

The @racket[syntax-pattern-variable?] procedure is provided
@racket[for-syntax] by @racketmodname[racket/base].}
