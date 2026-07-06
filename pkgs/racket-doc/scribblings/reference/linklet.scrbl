#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/linklet
                     racket/unsafe/ops))

@title[#:tag "linklets"]{Linklet 与核心编译器}

@defmodule[racket/linklet]

@deftech{linklet} 是编译、字节码封送和求值的基本元素。 Racket 的 module、宏和顶层求值的实现都建立在 linklet 之上。 Racket 程序员通常不会直接遇到 linklet，但 @racketmodname[racket/linklet] 库提供了对 linklet 功能的访问。

单个 Racket module（或顶层形式的集合）通常由多个 linklet 实现。 例如，module 中存在的每个求值阶段都在一个单独的 linklet 中实现。 linklet 还用于元数据，例如 module 的 @racket[require] 的 @tech{module path index}。 这些 linklet 与其他一些元数据组合形成一个 @deftech{linklet bundle}。
@tech{linklet bundle} 中的信息以 symbol 或 @tech{fixnum} 为键。 包含 @tech{linklet} 的 @tech{linklet bundle} 可以通过 @racket[write] 和 @racket[read]（在启用 @racket[read-accept-compiled] 的情况下）与字节流相互封送处理。 @racket[compiled-expression?] 意义上的编译形式（例如 @racket[compile] 的结果）可能是 linklet bundle。

当 Racket module 有 submodule 时，module 及其 submodule 的 @tech{linklet bundles} 组合在一个 @deftech{linklet directory} 中。 @tech{linklet directory} 可以有嵌套的 linklet directory。 linklet directory 中的信息由 @racket[#f] 或 symbol 索引；
@racket[#f] 必须映射到 @tech{linklet bundle}（如果有的话），
每个 symbol 必须映射到 @tech{linklet directory}。 @tech{linklet directory} 可以等价地视为从 symbol 列表到 @tech{linklet bundle} 的映射。 与 @tech{linklet bundles} 类似，@tech{linklet directory} 可以通过 @racket[write] 和 @racket[read] 与字节流相互封送处理；
封送处理形式允许独立加载单个 @tech{linklet bundles}。
@racket[compiled-expression?] 意义上的编译形式（例如 @racket[compile] 的结果）可能是 linklet directory。

linklet 由一组变量定义和表达式组成，
包括已定义变量名称的导出子集、尽管没有对应定义但仍要从 linklet 导出的变量，以及为 linklet 提供其他变量的导入集。 要运行 linklet，需要将其实例化为 @deftech{linklet instance}
（或简称为 @defterm{instance}）。 当 linklet 被实例化时，它接收用于导入的其他 @tech{linklet instances}，
并从每个给定实例中提取一组指定的变量。 新创建的 @tech{linklet instance} 提供其导出变量供其他 linklet 使用，
或通过 @racket[instance-variable-value] 直接访问。 @tech{linklet instance} 可以用 @racket[make-instance] 直接合成。

linklet 通过编译其源代码的丰富 S-expression 表示来创建。 由于 linklet 存在于宏和 syntax object 层之下，linklet 编译不使用 @tech{syntax objects}。 相反，linklet 编译使用 @deftech{correlated objects}，
它类似于 @tech{syntax objects}，但没有词法上下文信息，也没有内容被强制转换为 correlated object 的约束。 使用 S-expression 或 @tech{correlated object}，linklet 的语法（如 @racket[compile-linklet] 所识别的）如下

@specform[(linklet [[imported-id/renamed ...] ...]
                   [exported-id/renamed ...]
            defn-or-expr ...)
          #:grammar
          ([imported-id/renamed imported-id
                                (external-imported-id internal-imported-id)]
           [exported-id/renamed exported-id
                                (internal-exported-id external-exported-id)])]

每个导入集 @racket[[_imported-id/renamed ...]] 引用单个导入的实例，
每个 @racket[_import-id/renamed] 对应于该实例中的一个变量。 If separate
@racket[_external-imported-id] and @racket[_internal-imported-id] are
specified, then @racket[_external-imported-id] is the name of the
variable as exported by the instance, and
@racket[_internal-imported-id] is the name used to refer to the
variable in the @racket[_defn-or-expr]s. For exports, separate
@racket[_internal-exported-id] and @racket[_external-exported-id]
names corresponds to the variable name as exported as referenced 
in the @racket[_defn-or-expr]s, respectively.

The grammar of an @racket[_defn-or-expr] is similar to the expander's
grammar of fully expanded expressions (see @secref["fully-expanded"])
with some exceptions: @racket[quote-syntax] and @racket[#%top] are not allowed;
@racket[#%plain-lambda] is spelled @racket[lambda];
@racket[#%plain-app] is omitted (i.e., application is implicit);
@racket[lambda], @racket[case-lambda], @racket[let-values], and
@racket[letrec-values] can have only a single body expression;
@racket[begin-unsafe] is like @racket[begin] in an expression position,
but its body is compiled in @tech{unsafe mode}; @racket[#%foreign-inline]
uses a symbol instead of a keyword for its mode; and
numbers, booleans, strings, and byte strings are self-quoting.
Primitives are accessed directly by name, and shadowing is not allowed
within a @racketidfont{linklet} form for primitive names (see
@racket[linklet-body-reserved-symbol?]), imported variables, defined
variables, or local variables.

When an @racket[_exported-id/renamed] has no corresponding definition
among the @racket[_defn-or-expr]s, then the variable is effectively
defined as uninitialized; referencing the variable will trigger
@racket[exn:fail:contract:variable], the same as referencing a
variable before it is defined. When a target instance is provided to
@racket[instantiate-linklet], any existing variable with the same name
will be left as-is, instead of set to undefined. This treatment of
uninitialized variables provides core support for top-level evaluation
where variables may be referenced and then defined in a separate
element of compilation.

@history[#:added "6.90.0.1"]

@; --------------------------------------------------

@defproc[(linklet? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{linklet}, @racket[#f]
otherwise.}

@defproc*[([(compile-linklet [form (or/c correlated? any/c)]
                             [info (or/c hash? any/c) #f]
                             [import-keys #f #f]
                             [get-import #f #f]
                             [options (listof (or/c 'serializable 'unsafe 'static 'quick
                                                     'use-prompt 'unlimited-compile
                                                     'uninterned-literal))
                                      '(serializable)])
            linklet?]
           [(compile-linklet [form (or/c correlated? any/c)]
                             [info (or/c hash? any/c)]
                             [import-keys vector?]
                             [get-import (or/c #f (any/c . -> . (values (or/c linklet? instance? #f)
                                                                        (or/c vector? #f))))
                                         #f]
                             [options (listof (or/c 'serializable 'unsafe 'static 'quick
                                                    'use-prompt 'unlimited-compile
                                                    'uninterned-literal))
                                      '(serializable)])
            (values linklet? vector?)])]{

接受 @schemeidfont{linklet} 形式的 S-expression 或 @tech{correlated object}，并产生 @tech{linklet}。
只要 @racket[options] 中包含 @racket['serializable]，
生成的 linklet 就可以作为 @tech{linklet bundle}（可能在 @tech{linklet directory} 中）的一部分与字节流相互封送处理。

The optional @racket[info] hash provides various debugging details
about the linklet, such as the module name the linklet is part of,
the linklet name, and the phase for body linklets. If a @racket['name]
value is present in the hash, it is associated to the linklet for
debugging purposes and as the default name of the linklet's instance.
If @racket[info] is not a hash, it is assumed to be a name value
directly for backward compatibility.

可选的 @racket[import-keys] 和 @racket[get-import] 参数支持跨 linklet 优化。 If @racket[import-keys] is a
vector, it must have as many elements as sets of imports in
@racket[form]. If the compiler becomes interested in optimizing a
reference to an imported variable, it passes back to
@racket[get-import] (if non-@racket[#f]) the element of @racket[import-keys] that
corresponds to the variable's import set. The @racket[get-import]
function can then return a linklet or instance that represents an instance to be
provided to the compiled linklet when it is eventually instantiated;
ensuring consistency between reported linklet or instance and the eventual
instance is up to the caller of @racket[compile-linklet], but see also
@racket[linklet-add-target-machine-info]. If
@racket[get-import] returns @racket[#f] as its first value, the
compiler will be prevented from making any assumptions about the
imported instance. The second result from @racket[get-import] is an
optional vector of keys to provide transitive information on a
returned linklet's imports (and is not allowed for a returned instance);
the returned vector must have the same
number of elements as the linklet has imports. When vector elements
are @racket[eq?] and non-@racket[#f], the compiler can assume that
they correspond to the same run-time instance. A @racket[#f]
value for @racket[get-import] is equivalent to a function that
always returns two @racket[#f] results.

When @racket[import-keys] is not @racket[#f], then the compiler is
allowed to grow or shrink the set of imported instances for the
linklet. The result vector specifies the keys of the imports for the
returned linklet. Any key that is @racket[#f] or a @tech{linklet instance}
must be preserved intact, however.

If @racket['unsafe] is included in @racket[options], then the linklet
is compiled in @deftech{unsafe mode}: uses of safe operations within
the linklet can be converted to unsafe operations on the assumption
that the relevant contracts are satisfied. For example, @racket[car]
is converted to @racket[unsafe-car]. Some substituted unsafe
operations may not have directly accessible names, such as the unsafe
variant of @racket[in-list] that can be substituted in @tech{unsafe
mode}. An unsafe operation is substituted only if its (unchecked)
contract is subsumed by the safe operation's contract. The fact that
the linklet is compiled in @tech{unsafe mode} can be exposed through
@racket[variable-reference-from-unsafe?] using a variable reference
produced by a @racket[#%variable-reference] form within the module
body. Within a linklet an individual expression can be compiled in
unsafe mode by wrapping it in @racket[begin-unsafe]; when a whole
linklet is compiled in unsafe mode, @racket[begin-unsafe] is redundant
and ignored.

如果 @racket['static] 包含在 @racket[options] 中，则 linklet 只能被实例化一次；
如果 linklet 被序列化，则从序列化形式读取的每个单独实例也必须至多实例化一次。 使用 @racket['static] 进行编译旨在提高 linklet
内部对已定义和导入变量的引用的性能。

如果 @racket['quick] 包含在 @racket[options] 中，
则 linklet 编译可能用运行时性能换取编译时性能——即，花费更少的时间编译 linklet，
但生成的 linklet 可能运行得更慢。

If @racket['use-prompt] is included in @racket[options], then
instantiating resulting linklet always wraps a prompt around each
definition and immediate expression in the linklet. Otherwise,
supplying @racket[#t] as the @racket[_use-prompt?] argument to
@racket[instantiate-linklet] may only wrap a prompt around the entire
instantiation.

如果 @racket['unlimited-compile] 包含在 @racket[options] 中，
则编译不会因为 linklet 特别大而回退到解释模式。 See also @secref["cs-compiler-modes"].

If @racket['uninterned-literal] is included in @racket[options], then
literals in @racket[form] will not necessarily be interned via
@racket[datum-intern-literal] when compiling or loading the linklet.
Disabling the use of @racket[datum-intern-literal] can be especially
useful of the linklet includes a large string or byte string constant
that is not meant to be shared.

The symbols in @racket[options] must be distinct, otherwise
@exnraise[exn:fail:contract].

@history[#:changed "7.1.0.8" @elem{Added the @racket['use-prompt] option.}
         #:changed "7.1.0.10" @elem{Added the @racket['uninterned-literal] option.}
         #:changed "7.5.0.14" @elem{Added the @racket['quick] option.}
         #:changed "8.11.1.2" @elem{Changed @racket[info] to a hash.}
         #:changed "8.13.0.9" @elem{Added the @racket['unlimited-compile] option.}]}


@defproc*[([(recompile-linklet [linklet linklet?]
                               [info (or/c hash? any/c) #f]
                               [import-keys #f #f]
                               [get-import #f #f]
                               [options (listof (or/c 'serializable 'unsafe 'static 'quick
                                                      'use-prompt 'uninterned-literal))
                                        '(serializable)])
            linklet?]
           [(recompile-linklet [linklet linklet?]
                               [info (or/c hash? any/c)]
                               [import-keys vector?]
                               [get-import (or/c (any/c . -> . (values (or/c linklet? #f)
                                                                       (or/c vector? #f)))
                                                 #f)
                                           (lambda (import-key) (values #f #f))]
                               [options (listof (or/c 'serializable 'unsafe 'static 'quick
                                                      'use-prompt 'uninterned-literal))
                                        '(serializable)])
             (values linklet? vector?)])]{

类似于 @racket[compile-linklet]，但接受一个已编译的 linklet 并可能进一步优化。

@history[#:changed "7.1.0.6" @elem{Added the @racket[options] argument.}
         #:changed "7.1.0.8" @elem{Added the @racket['use-prompt] option.}
         #:changed "7.1.0.10" @elem{Added the @racket['uninterned-literal] option.}
         #:changed "7.5.0.14" @elem{Added the @racket['quick] option.}
         #:changed "8.11.1.2" @elem{Changed @racket[info] to a hash.}]}


@defproc[(eval-linklet [linklet linklet?]) linklet?]{

返回一个准备好的用于 JIT 编译的 @racket[linklet] 变体，
以便在 @racket[instantiate-linklet] 中之后每次使用结果 linklet 时都能共享 JIT 生成的代码。 However,
the result of @racket[eval-linklet] cannot be marshaled to a byte
stream as part of a @tech{linklet bundle}, and it cannot be used with
@racket[recompile-linklet].}



@defproc*[([(instantiate-linklet [linklet linklet?]
                                 [import-instances (listof instance?)]
                                 [target-instance? #f #f]
                                 [use-prompt? any/c #t])
            instance?]
           [(instantiate-linklet [linklet linklet?]
                                 [import-instances (listof instance?)]
                                 [target-instance instance?]
                                 [use-prompt? any/c #t])
            any])]{

Instantiates @racket[linklet] by running its definitions and
expressions, using the given @racket[import-instances] for its
imports. @racket[import-instances] 中的实例数量必须与 @racket[linklet] 中的导入集数量匹配。

如果 @racket[target-instance] 是 @racket[#f] 或未提供，
结果为 linklet 的新实例。 If @racket[target-instance] is an
instance, then the instance is used and modified for the linklet
definitions and expressions, and the result is the value of the last
expression in the linklet.

The linklet's exported variables are accessible in the result instance
or in @racket[target-instance] using the linklet's external name for
each export. If @racket[target-instance] is provided as
non-@racket[#f], its existing variables remain intact if they are not
modified by a linklet definition.

If @racket[use-prompt?] is true, then a a @tech{prompt} is wrapped
around the linklet instantiation in same ways as an expression in a
module body. If the linklet contains multiple definitions or immediate
expressions, then a prompt may or may not be wrapped around each
definition or expression; supply @racket['use-prompt] to
@racket[compile-linklet] to ensure that a prompt is used around each
definition and expression.}


@defproc[(linklet-import-variables [linklet linklet?])
         (listof (listof symbol?))]{

返回 linklet 导入的描述。 Each element of the
result list corresponds to an import set as satisfied by a single
instance on instantiation, and each member of the set is a variable
name that is used from the corresponding imported instance.}

@defproc[(linklet-export-variables [linklet linklet?])
         (listof symbol?)]{

返回 linklet 导出的描述。 Each element of the list
corresponds to a variable that is made available by the linklet in its
instance.}

@defproc[(linklet-add-target-machine-info [linklet linklet?]
                                          [from-linklet (or linklet? hash?)])
         linklet?]{

When @racket[compile-linklet] or @racket[recompile-linklet] requests a
linklet via @racket[_get-import] for cross-module information, the
linklet is expected to have information compatible with the current
compilation target as determined by
@racket[current-compile-target-machine]. To simplify the management of
linklets to both run and use for cross-compilation, a linklet
implementation may support information for multiple target machines
within a linklet, in which case
@racket[linklet-add-target-machine-info] returns a linklet like
@racket[linklet] but with target-specific information added from
@racket[from-linklet]. The two linklets must be from compatible
sources, but @racket[linklet-add-target-machine-info] might perform
only a sanity check for compatibility.

The @racket[from-linklet] can be a linklet or a summary of a linklet's
information as produced by @racket[linklet-summarize-target-machine-info].

@history[#:added "8.12.0.3"
         #:changed "8.17.0.3" @elem{Added support for @racket[from-linklet]
                                    as a summary.}]}


@defproc[(linklet-summarize-target-machine-info [from-linklet linklet?])
         hash?]{

Returns a value that has the same information as @racket[from-linklet]
for @racket[linklet-add-target-machine-info], but in a form that can be
portably serialized via @racketmodname[racket/fasl].

@history[#:added "8.17.0.3"]}


@defproc[(decompile-linklet [linklet linklet?]) (or/c #f correlated? any/c)]{

Attempts to recompile a linklet back into the S-expression form that
@racket[compile-linklet] expects. If the linklet cannot be decompiled,
the result is @racket[#f]. A linklet that is generated via
@racket[compile] with @racket[current-compile-target-machine] set to
@racket[#f] (for machine-independent bytecode) always can be
decompiled.

@history[#:added "8.18.0.19"]}


@defproc[(linklet-directory? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{linklet directory},
@racket[#f] otherwise.}


@defproc[(hash->linklet-directory [content (and/c hash? hash-eq? immutable? (not/c impersonator?))])
         linklet-directory?]{

根据 @tech{hash table} 形式的映射构造 @tech{linklet directory}。 Each key of @racket[content] must be either a
symbol or @racket[#f], each symbol must be mapped to a @tech{linklet
directory}, and @racket[#f] must be mapped to a @tech{linklet bundle}
or not mapped.}


@defproc[(linklet-directory->hash [linklet-directory linklet-directory?])
         (and/c hash? hash-eq? immutable? (not/c impersonator?))]{

将 @tech{linklet directory} 的内容提取到 @tech{hash table} 中。}

         
@defproc[(linklet-bundle? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{linklet bundle},
@racket[#f] otherwise.}


@defproc[(hash->linklet-bundle [content (and/c hash? hash-eq? immutable? (not/c impersonator?))])
         linklet-bundle?]{

根据 @tech{hash table} 形式的映射构造 @tech{linklet bundle}。 Each key of @racket[content] must be either a
symbol or a @tech{fixnum}. Values in the hash table are unconstrained,
but the intent is that they are all @tech{linklets} or values that can
be recovered from @racket[write] output by @racket[read].}


@defproc[(linklet-bundle->hash [linklet-bundle linklet-bundle?])
         (and/c hash? hash-eq? immutable? (not/c impersonator?))]{

将 @tech{linklet bundle} 的内容提取到 @tech{hash table} 中。}


@defproc[(linklet-body-reserved-symbol? [sym symbol?]) boolean?]{

Return @racket[#t] if @racket[sym] is a primitive name or other
identifier that is not allowed as a binding within a linklet,
@racket[#f] otherwise.

@history[#:added "8.2.0.1"]}
         

@defproc[(instance? [v any/c]) boolean?]{

Returns @racket[#t] if @racket[v] is a @tech{linklet instance},
@racket[#f] otherwise.}


@defproc[(make-instance [name any/c]
                        [data any/c #f]
                        [mode (or/c #f 'constant 'consistent) #f]
                        [variable-name symbol?]
                        [variable-value any/c] ... ...)
         instance?]{

直接构造 @tech{linklet instance}。 Besides associating an
arbitrary @racket[name] and @racket[data] value to the instance, the
instance is populated with variables as specified by
@racket[variable-name] and @racket[variable-value].

The optional @racket[data] and @racket[mode] arguments must be
provided if any @racket[variable-name] and @racket[variable-value]
arguments are provided. The @racket[mode] argument is used as in
@racket[instance-set-variable-value!] for every
@racket[variable-name].}


@defproc[(instance-name [instance instance?]) any/c]{

Returns the value associated to @racket[instance] as its name---either
the first value provided to @racket[make-instance] or the name of a
linklet that was instantiated to create the instance.}


@defproc[(instance-data [instance instance?]) any/c]{

Returns the value associated to @racket[instance] as its data---either
the second value provided to @racket[make-instance] or the default
@racket[#f].}


@defproc[(instance-variable-names [instance instance?]) (list symbol?)]{

Returns a list of all names for all variables accessible from
@racket[instance].}


@defproc[(instance-variable-value [instance instance?]
                                  [name symbol?]
                                  [fail-k any/c (lambda () (error ....))])
         any]{

Returns the value of the variable exported as @racket[name] from
@racket[instance]. If no such variable is exported, then
@racket[fail-k] is used in the same way as by @racket[hash-ref].}


@defproc[(instance-set-variable-value! [instance instance?]
                                       [name symbol?]
                                       [v any/c]
                                       [mode (or/c #f 'constant 'consistent) #f])
          void?]{

Sets or creates the variable exported as @racket[name] in
@racket[instance] so that its value is @racket[v], as long as the
variable does not exist already as constant. If a variable for
@racket[name] exists as constant, the @exnraise[exn:fail:contract].

If @racket[mode] is @racket['constant] or @racket['consistent], then
the variable is created or changed to be constant. Furthermore, when
the instance is reported for a linklet's import though a
@racket[_get-import] callback to @racket[compile-linklet], the
compiler can assume that the variable will be constant in all future
instances that are used to satisfy a linklet's imports.

If @racket[mode] is @racket['consistent], when the instance is
reported though a callback to @racket[compile-linklet], the compiler
can further assume that the variable's value will be the same for
future instances. For compilation purposes, ``the same'' can mean that
a procedure value will have the same arity and implementation details,
a @tech{structure type} value will have the same configuration, a
marshalable constant will be @racket[equal?] to the current value, and
so on.}


@defproc[(instance-unset-variable! [instance instance?]
                                   [name symbol?])
          void?]{

Changes @racket[instance] so that it does not export a variable as
@racket[name], as long as @racket[name] does not exist as a constant
variable. If a variable for @racket[name] exists as constant, the
@exnraise[exn:fail:contract].}


@defproc[(instance-describe-variable! [instance instance?]
                                      [name symbol?]
                                      [desc-v any/c])
          void?]{

Registers information about @racket[name] in @racket[instance] that
may be useful for compiling linklets where the instance is returned via
the @racket[_get-import] callback to @racket[compile-linklet]. The
@racket[desc-v] description can be any value; the recognized
descriptions depend on virtual machine, but may include the following:

@itemlist[

 @item{@racket[`(procedure ,arity-mask)] --- the value is always a
       procedure that is not impersonated and not a structure, and its
       arity in the style of @racket[procedure-arity-mask] is
       @racket[arity-mask].}

 @item{@racket[`(procedure/succeeds ,arity-mask)] --- like
       @racket[`(procedure ,arity-mask)], but for a procedure that
       never raises an exception of otherwise captures or escapes the
       calling context.}

 @item{@racket[`(procedure/pure ,arity-mask)] --- like
       @racket[`(procedure/succeeds ,arity-mask)], but with no
       observable side effects, so a call to the procedure can be
       reordered.}

]

@history[#:added "7.1.0.8"]}

@defproc[(variable-reference->instance [varref variable-reference?]
                                       [ref-site? any/c #f])
         (if ref-site? (or/c instance? #f symbol?) instance?)]{

Extracts the instance where the variable of @racket[varref] is defined
if @var[ref-site?] is @racket[#f], and returns the instance where
@racket[varref] itself resides if @racket[ref-site?] is true. This
notion of @tech{variable reference} is the same as at the module level
and can reflect the linklet instance that implements a particular
phase of a module instance.

When @var[ref-site?] is @racket[#f], the result is @racket[#f] when
@racket[varref] is from @racket[(#%variable-reference)] with no
identifier. The result is a symbol if @racket[varref] refers to a
primitive.}

@deftogether[(
@defproc[(correlated? [v any/c]) boolean?]
@defproc[(correlated-source [crlt correlated?]) any]
@defproc[(correlated-line [crlt correlated?])
         (or/c exact-positive-integer? #f)]
@defproc[(correlated-column [crlt correlated?])
         (or/c exact-nonnegative-integer? #f)]
@defproc[(correlated-position [crlt correlated?])
         (or/c exact-positive-integer? #f)]
@defproc[(correlated-span [crlt correlated?])
         (or/c exact-nonnegative-integer? #f)]
@defproc[(correlated-e [crlt correlated?]) any]
@defproc[(correlated->datum [crlt (or/c correlated? any/c)]) any]
@defproc[(datum->correlated [v any/c]
                        [srcloc (or/c correlated? #f
                                      (list/c any/c
                                              (or/c exact-positive-integer? #f)
                                              (or/c exact-nonnegative-integer? #f)
                                              (or/c exact-positive-integer? #f)
                                              (or/c exact-nonnegative-integer? #f))
                                      (vector/c any/c
                                               (or/c exact-positive-integer? #f)
                                               (or/c exact-nonnegative-integer? #f)
                                               (or/c exact-positive-integer? #f)
                                               (or/c exact-nonnegative-integer? #f)))
                                #f]
                         [prop (or/c correlated? #f) #f])
          correlated?]
@defproc*[([(correlated-property [crlt correlated?]
                                 [key any/c]
                                 [val any/c])
             correlated?]
           [(correlated-property [crlt correlated?] [key any/c]) any/c])]
@defproc[(correlated-property-symbol-keys [crlt correlated?]) list?]
)]{

Like @racket[syntax?], @racket[syntax-source], @racket[syntax-line],
@racket[syntax-column], @racket[syntax-position],
@racket[syntax-span], @racket[syntax-e], @racket[syntax->datum],
@racket[datum->syntax], @racket[syntax-property], and
@racket[syntax-property-symbol-keys], but for @tech{correlated
objects}.

与 @racket[datum->syntax] 不同，@racket[datum->correlated] 不会递归遍历给定的 S-expression 并将其各部分转换为 @tech{correlated objects}。 Instead, a @tech{correlated object} is
simply wrapped around the immediate value. In contrast,
@racket[correlated->datum] recurs through its argument (which is not
necessarily a @tech{correlated object}) to discover any
@tech{correlated objects} and convert them to plain S-expressions.

@history[#:changed "7.6.0.6" @elem{Added the @racket[prop] argument
                                   to @racket[datum->correlated].}]}
