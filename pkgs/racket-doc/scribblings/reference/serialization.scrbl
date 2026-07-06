#lang scribble/doc
@(require "mz.rkt" racket/serialize (for-label racket/serialize racket/fasl))

@(define ser-eval (make-base-eval))
@examples[#:hidden #:eval ser-eval (require racket/serialize)]

@title[#:tag "serialization"]{Serialization}

@note-lib-only[racket/serialize #:use-sources (racket/private/serialize)]

@defproc[(serializable? [v any/c]) boolean?]{

 如果 @racket[v] 看起来是可序列化的（不检查复合值的内容）则返回 @racket[#t]，否则返回 @racket[#f]。参见 @racket[serialize] 了解可序列化值的枚举。}

@; ----------------------------------------------------------------------

@defproc[(serialize [v serializable?]
                    [#:relative-directory relative-to
                     (or/c (and/c path? complete-path?)
                           (cons/c (and/c path? complete-path?)
                                   (and/c path? complete-path?))
                           #f)
                     #f]
                    [#:deserialize-relative-directory deserialize-relative-to
                     (or/c (and/c path? complete-path?)
                           (cons/c (and/c path? complete-path?)
                                   (and/c path? complete-path?))
                           #f)
                     relative-to])
         any]{

 返回封装 @racket[v] 值的一个值。该值仅包含可读值，因此可以使用 @racket[write] 或 @racket[s-exp->fasl] 写入流，然后在之后使用 @racket[read] 或 @racket[fasl->s-exp] 从流中读取，再使用 @racket[deserialize] 转换为类似的值。序列化后反序列化产生的值与原值具有相同的图结构和可变性，但序列化的值是普通树（即无共享）。

 以下类型的值是 @deftech{可序列化} 的：

@itemize[

 @item{通过 @racket[serializable-struct] 或 @racket[serializable-struct/versions] 创建的结构，或更一般性地，具有 @racket[prop:serializable] 属性的结构（参见 @racket[prop:serializable] 了解更多信息）；}

 @item{@techlink{prefab} 结构；}

 @item{使用 @racket[define-serializable-class] 或 @racket[define-serializable-class*] 定义的类的实例；}

 @item{@tech{booleans}、@tech{numbers}、@tech{characters}、@tech{interned} symbols、@tech{unreadable symbols}、@tech{keywords}、@tech{strings}、@tech{byte strings}、@tech{paths}（对于特定约定）、@tech{regexp values}、@|void-const| 和空列表；}

 @item{@tech{pairs}、@tech{mutable pairs}、@tech{vectors}、@tech{flvectors}、@tech{fxvectors}、@tech{box}es、@tech{hash tables}、@tech{sets} 和 @tech{treelists}；}

 @item{@racket[date]、@racket[date*]、@racket[arity-at-least] 和 @racket[srcloc] 结构；和}

 @item{@tech{module path index} 值。}

]

 对于复合值（如 pair），仅当值的所有内容都可序列化时，序列化才能成功。如果完全序列化 @racket[serialize] 的值不完全可序列化，将引发 @exnraise[exn:fail:contract]。

 如果 @racket[v] 包含循环（即彼此可达的对象集合），则只有在循环包含可变值时，@racket[v] 才能被序列化，其中 @tech{prefab} 结构仅在其所有字段都可变时才被视为可变。

 如果 @racket[relative-to] 不为 @racket[#f]，则将扩展 @racket[relative-to] 中路径的路径序列化为相对且平台独立的形式。@racket[relative-to] 的可能值和对待方式与 @racket[current-write-relative-directory] 相同。

 如果 @racket[deserialize-relative-to] 不为 @racket[#f]，则通过 @racket[prop:serializable] 提取的任何反序列化器路径均以相对形式记录。注意，@racket[relative-to] 和 @racket[deserialize-relative-to] 是独立的，但 @racket[deserialize-relative-to] 默认为 @racket[relative-to]。

@margin-note{@racket[serialize] 和 @racket[deserialize] 函数目前不处理 @racket[read] 和 @racket[write] 可以处理的某些循环值，例如 @racket['@#,read[(open-input-string "#0=(#0#)")]]。}

 参见 @racket[deserialize] 了解序列化数据的格式。

@history[#:changed "6.5.0.4" @elem{添加 keywords 和 regexp values 作为可序列化。}
         #:changed "7.0.0.6" @elem{添加了 @racket[#:relative-directory] 和 @racket[#:deserialize-relative-directory] 参数。}]}

@; ----------------------------------------------------------------------

@defproc[(deserialize [v any/c]) any]{

 给定 @racket[serialize] 生成的值 @racket[v]，产生类似于传递给 @racket[serialize] 的值，包括相同的图结构和可变性。

 序列化表示 @racket[v] 是包含六或七个元素的列表：

@itemize[

 @item{可选列表 @racket['(1)]、@racket['(2)]、@racket['(3)] 或 @racket['(4)]，表示序列化格式的版本。如果表示的第一个元素不是列表，则版本为 @racket[0]。版本 1 添加对可变对的支持，版本 2 添加对 @tech{unreadable symbols} 的支持，版本 3 添加对 @racket[date*] 结构的支持，版本 4 添加对相对于反序列化目录的路径的支持。}

 @item{一个表示序列化数据结构中表示的不同结构类型数量的非负精确整数 @racket[_s-count]。}

 @item{一个 @racket[_count] 长度的列表 @racket[_s-types]，其中每个元素表示一个结构类型。每个结构类型编码为一个 pair。该 pair 的 @racket[car] 是 @racket[#f]（如果结构的反序列化信息在顶层定义），否则为引用的 @tech{module path}、字节串（将使用 @racket[bytes->path] 转换为平台相关路径）用于导出结构反序列化信息的模块，或相对路径元素列表用于相对于 @racket[current-load-relative-directory] 或（作为备选）@racket[current-directory] 解析的模块；list-of-relative-elements 形式由 @racket[serialize] 在 @racket[#:deserialize-relative-directory] 参数不为 @racket[#f] 时生成。该 pair 的 @racket[cdr] 是用于反序列化信息的绑定名称（在顶层或从模块导出），可以是表示 @tech{unreadable symbol} 的符号或字符串。这两者与 @racket[namespace-variable-binding] 或 @racket[dynamic-require] 一起使用以获得反序列化信息。参见 @racket[make-deserialize-info] 了解绑定值的更多信息。另参见 @racket[deserialize-module-guard]。}

 @item{列表中包含的图点数量的非负精确整数 @racket[_g-count]。}

 @item{一个长度 @racket[_g-count] 的列表 @racket[_graph]，其中每个元素表示序列化值，在构建其他序列化值时引用。每个列表元素要么是 box，要么不是：

      @itemize[

       @item{box 表示作为循环一部分的值，对于反序列化，其字段必须用 @racket[#f] 分配。box 的内容指示值的形状：

            @itemize[

            @item{一个非负精确整数 @racket[_i]，表示由 @racket[_s-types] 列表的第 @racket[_i] 个元素表示的结构类型的实例；}

            @item{@racket['c] 对 pair，反序列化时将失败（因为 pair 不可变此情况不会出现在 @racket[serialize] 的输出中）；}

            @item{@racket['m] 对可变 pair；}

            @item{@racket['b] 对 box；}

            @item{@racket[car] 为 @racket['v]、@racket[cdr] 为非负精确整数 @racket[_s] 的 pair，表示长度为 @racket[_s] 的向量；}

            @item{第一个元素为 @racket['h]、其余元素为确定 hash table 类型的符号的列表：

                  @itemize[
                    @item{@racket['equal] --- @racket[(make-hash)]}
                    @item{@racket['equal 'weak] --- @racket[(make-weak-hash)]}
                    @item{@racket['weak] --- @racket[(make-weak-hasheq)]}
                    @item{no symbols --- @racket[(make-hasheq)]}
                  ]}

            @item{@racket['date*] 对 @racket[date*] 结构，反序列化时将失败（因为 dates 不可变此情况不会出现在 @racket[serialize] 的输出中）；}

            @item{@racket['date] 对 @racket[date] 结构，反序列化时将失败（因为 dates 不可变此情况不会出现在 @racket[serialize] 的输出中）；}

            @item{@racket['arity-at-least] 对 @racket[arity-at-least] 结构，反序列化时将失败（因为 arity-at-least 不可变此情况不会出现在 @racket[serialize] 的输出中）；或}

            @item{@racket['mpi] 对 @tech{module path index}，反序列化时将失败（因为 module path index 不可变此情况不会出现在 @racket[serialize] 的输出中）。}

            @item{@racket['srcloc] 对 @racket[srcloc] 结构，反序列化时将失败（因为 srclocs 不可变此情况不会出现在 @racket[serialize] 的输出中）。}
            ]

            使用 @racket[#f] 填充的值将由序列化列表 @racket[v] 的第五个元素指定的内容更新。}

       @item{非 box 表示立即构建的 @defterm{serial} 值，它是以下之一：

            @itemize[

            @item{boolean、number、character、interned symbol 或空列表，表示自身。}

            @item{string，表示不可变字符串。}

            @item{byte string，表示不可变字节串。}

            @item{@racket[car] 为 @racket['?]、@racket[cdr] 为非负精确整数 @racket[_i] 的 pair；表示 @racket[_graph] 的第 @racket[_i] 个元素构建的值，其中 @racket[_i] 小于该元素在 @racket[_graph] 中的位置。}

            @item{@racket[car] 为数字 @racket[_i] 的 pair；表示由 @racket[_s-types] 列表的第 @racket[_i] 个元素描述的结构类型实例。该 pair 的 @racket[cdr] 是 serial 列表，表示提供给结构类型反序列化器的参数。}

            @item{@racket[car] 为 @racket['q]、@racket[cdr] 为不可变值的 pair；表示引用的值。}

            @item{@racket[car] 为 @racket['f] 的 pair；表示 @tech{prefab} 结构类型的实例。该 pair 的 @racket[cadr] 是 @tech{prefab} 结构类型键，@racket[cddr] 是 serial 列表，表示字段值。}

            @item{@racket[car] 为 @racket['void] 的 pair，表示 @|void-const|。}

            @item{@racket[car] 为 @racket['su]、@racket[cdr] 为字符 string 的 pair；表示 @tech{unreadable symbol}。}

            @item{@racket[car] 为 @racket['u]、@racket[cdr] 为 byte string 或字符 string 的 pair；表示可变 byte 或 character string。}

            @item{@racket[car] 为 @racket['p]、@racket[cdr] 为 byte string 的 pair；表示使用序列化器路径约定的路径（已弃用，推荐使用 @racket['p+]）。}

            @item{@racket[car] 为 @racket['p+]、@racket[cadr] 为 byte string、@racket[cddr] 为 @racket[system-path-convention-type] 的可能符号结果之一的 pair；表示使用指定约定的路径。}

            @item{@racket[car] 为 @racket['p*]、@racket[cdr] 为 byte string 列表的 pair 表示相对路径；它将由反序列化基于 @racket[current-load-relative-directory] 转换，备选使用 @racket[current-directory]。}

            @item{@racket[car] 为 @racket['c]、@racket[cdr] 为 serial 对的 pair；表示不可变 pair。}

            @item{@racket[car] 为 @racket['c!]、@racket[cdr] 为 serial 对的 pair；表示 pair（但原先表示可变 pair），不出现在 @racket[serialize] 生成的输出中。}

            @item{@racket[car] 为 @racket['m]、@racket[cdr] 为 serial 对的 pair；表示可变 pair。}

            @item{@racket[car] 为 @racket['v]、@racket[cdr] 为 serial 列表的 pair；表示不可变向量。}

            @item{@racket[car] 为 @racket['v!]、@racket[cdr] 为 serial 列表的 pair；表示可变向量。}

            @item{@racket[car] 为 @racket['vl]、@racket[cdr] 为 serial 列表的 pair；表示 @tech{flvector}。}

            @item{@racket[car] 为 @racket['vx]、@racket[cdr] 为 serial 列表的 pair；表示 @tech{fxvector}。}

            @item{@racket[car] 为 @racket['b]、@racket[cdr] 为 serial 的 pair；表示不可变 box。}

            @item{@racket[car] 为 @racket['b!]、@racket[cdr] 为 serial 的 pair；表示可变 box。}

            @item{@racket[car] 为 @racket['h]、@racket[cadr] 为 @racket['!] 或 @racket['-]（分别表示可变或不可变）、@racket[caddr] 为符号列表（包含 @racket['equal]、@racket['weak]、两者或都不含）以确定 hash table 类型、@racket[cddr] 为 pair 列表的 pair，其中每个 pair 的 @racket[car] 是 hash-table key 的 serial，@racket[cdr] 是对应 value 的 serial。}

            @item{@racket[car] 为 @racket['date*]、@racket[cdr] 为 serial 列表的 pair；表示 @racket[date*] 结构。}

            @item{@racket[car] 为 @racket['date]、@racket[cdr] 为 serial 列表的 pair；表示 @racket[date] 结构。}

            @item{@racket[car] 为 @racket['arity-at-least]、@racket[cdr] 为 serial 的 pair；表示 @racket[arity-at-least] 结构。}

            @item{@racket[car] 为 @racket['mpi]、@racket[cdr] 为 pair 的 pair；表示加入配对值的 @tech{module path index}。}

            @item{@racket[car] 为 @racket['srcloc]、@racket[cdr] 为 serial 列表的 pair；表示 @racket[srcloc] 结构。}
            ]}
       ]}

 @item{pair 列表，其中每个 pair 的 @racket[car] 是非负精确整数 @racket[_i]，@racket[cdr] 是 serial（如前一项所定义）。每个元素表示对指定为 box 的 @racket[_graph] 的第 @racket[_i] 个元素的更新，serial 描述了如何构建与 box 指定形状相同的新值。此新值的内容必须转移到 @racket[_graph] 中为 box 创建的值中。}

 @item{最后的 serial（如两项前定义），表示 @racket[deserialize] 的结果。}

]

 @racket[deserialize] 的结果与 @racket[deserialize] 的参数不共享任何可变值。

 如果提供给 @racket[serialize] 的值是简单树（即无共享），则序列化表示的第四和第五个元素将为空。}

@; ----------------------------------------------------------------------

@defproc[(serialized=? [v1 any/c] [v2 any/c]) boolean?]{

 如果 @racket[v1] 和 @racket[v2] 表示相同的序列化信息则返回 @racket[#t]。

 更精确地，如果满足以下条件，则返回与 @racket[(equal? (deserialize v1) (deserialize v2))] 相同的值：

@itemize[

 @item{所有反序列化器使用不同 module paths 访问的结构类型实际上是不同类型；}

 @item{所有结构类型都是透明的；和}

 @item{所有结构实例仅包含 @racket[v1] 和 @racket[v2] 中每个记录的构成值。}

]}

@; ----------------------------------------------------------------------

@defparam[deserialize-module-guard guard (-> module-path? symbol?
                                             (or/c void? (cons/c module-path? symbol?)))]{

@racket[deserialize] 在通过 @racket[dynamic-require] 动态加载模块之前调用的参数过程值。提供给过程的两个参数与要传递给 @racket[dynamic-require] 的参数相同。该过程可以引发异常以禁止 @racket[dynamic-require]。

 该过程可以选择性地返回包含 @tech{module-path} 和 @tech{symbol} 的 pair。如果返回，@racket[deserialize] 将使用它们作为 @racket[dynamic-require] 的参数。

@history[#:changed "6.90.0.30" "Adds optional return values for bindings."]}

@; ----------------------------------------------------------------------

@defform[(serializable-struct id maybe-super (field ...)
                              struct-option ...)]{

 类似于 @racket[struct]，但结构类型的实例可通过 @racket[serialize] 序列化。此形式仅允许在顶层或模块顶层（以便之后找到反序列化信息）。

 仅在将所有字段都可变（或可通过其他可变值打破循环）时才支持涉及创建结构类型的循环。

 除了 @racket[struct] 生成的绑定外，@racket[serializable-struct] 还绑定 @racketidfont{deserialize-info:}@racket[_id]@racketidfont{-v0} 到反序列化信息。此外，在模块上下文中，它使用 @racket[module+] 自动在 @racket[deserialize-info] 子模块中 @racket[provide] 此绑定。

 @racket[serializable-struct] 形式使得能够在 @racket[id] 不可用的地方构建结构实例，因为反序列化必须构建实例。此外，@racket[serializable-struct] 提供对字段修改的有限访问，但仅针对通过反序列化信息生成的实例，该信息绑定到 @racketidfont{deserialize-info:}@racket[_id]@racketidfont{-v0}。参见 @racket[make-deserialize-info] 了解更多信息。

 请注意，前一段意味着如果可序列化结构体通过 @racket[contract-out] 导出，则在反序列化期间不会检查合约。请考虑使用 @racket[struct-guard/c]。

反序列化上的 @racket[-v0] 后缀使得将来可以通过 @racket[serializable-struct/versions] 对结构类型进行版本控制。

 当提供超类型作为 @racket[maybe-super] 时，绑定到超类型标识符的编译时信息必须包含超类型所有字段的访问器。如果缺少任何字段变更器，则该结构类型在编组（marshaling）方面将被视为不可变（因此反序列化器无法处理仅涉及该结构类型实例的循环）。

@examples[
#:eval ser-eval
(serializable-struct point (x y))
(point-x (deserialize (serialize (point 1 2))))
]}

@; ----------------------------------------------------------------------

@defform[(define-serializable-struct id-maybe-super (field ...)
                                      struct-option ...)]{

 类似于 @racket[serializable-struct]，但具有 @racket[define-struct] 的超类型语法和默认构造函数名。}

@; ----------------------------------------------------------------------

@defform/subs[(serializable-struct/versions id maybe-super vers (field ...)
                                            (other-version-clause ...)
                                            struct-option ...)
              ([other-version-clause (other-vers make-proc-expr 
                                                 cycle-make-proc-expr)])]{

 类似于 @racket[serializable-struct]，但生成的反序列化器绑定是 @racketidfont{deserialize-info:}@racket[_id]@racketidfont{-v}@racket[vers]。此外，@racketidfont{deserialize-info:}@racket[_id]@racketidfont{-v}@racket[other-vers] 为每个 @racket[other-vers] 绑定。@racket[vers] 和每个 @racket[other-vers] 必须是字面精确非负整数。

 每个 @racket[make-proc-expr] 应生成一个过程，该过程接受与对应版本结构类型字段数量相同的参数，并生成 @racket[id] 的实例。每个 @racket[cycle-make-proc-expr] 应生成一个无参数过程；此过程应返回两个值：@racket[id] 的实例 @racket[x]（通常字段为 @racket[#f]）和一个接受另一个 @racket[id] 实例并将其字段值复制到 @racket[x] 的过程。

@examples[
#:eval ser-eval
(serializable-struct point (x y) #:mutable #:transparent)
(define ps (serialize (point 1 2)))
(deserialize ps)

(define x (point 1 10))
(set-point-x! x x)
(define xs (serialize x))
(deserialize xs)

(serializable-struct/versions point 1 (x y z)
   ([0 
     (code:comment @#,t{Constructor for simple v0 instances:})
     (lambda (x y) (point x y 0))
     (code:comment @#,t{Constructor for v0 instance in a cycle:})
     (lambda ()
       (let ([p0 (point #f #f 0)])
         (values
           p0
           (lambda (p)
             (set-point-x! p0 (point-x p))
             (set-point-y! p0 (point-y p))))))])
   #:mutable #:transparent)
(deserialize (serialize (point 4 5 6)))
(deserialize ps)
(deserialize xs)
]}

@; ----------------------------------------------------------------------

@defform[(define-serializable-struct/versions id-maybe-super vers (field ...)
                                              (other-version-clause ...)
                                              struct-option ...)]{

 类似于 @racket[serializable-struct/versions]，但具有 @racket[define-struct] 的超类型语法和默认构造函数名。}

@; ----------------------------------------------------------------------

@defproc[(make-deserialize-info [make procedure?]
                                [cycle-make (-> (values any/c procedure?))])
         any]{

 生成由 @racket[deserialize] 使用的反序列化信息记录。此信息通常绑定到特定结构，因为结构具有 @racket[prop:serializable] 属性值，该值指向顶层变量或模块导出变量，该变量绑定到反序列化信息。

 @racket[make] 过程应接受与结构序列化器放入向量中一样多的参数；通常，这是结构中的字段数。它应返回结构的实例。

 @racket[cycle-make] 过程应不接受参数，并返回两个值：结构实例 @racket[x]（字段值为虚拟值）和更新过程。更新过程接受由 @racket[make] 生成的另一个结构实例，并将其字段值转移到 @racket[x] 中。}

@; ----------------------------------------------------------------------

@defthing[prop:serializable struct-type-property?]{

 此属性标识可 @tech{序列化} 的结构和结构类型。属性值应使用 @racket[make-serialize-info] 构造。}

@; ----------------------------------------------------------------------

@defproc[(make-serialize-info [to-vector (any/c . -> . vector?)]
                              [deserialize-id (or identifier?
                                                  symbol?
                                                  (cons/c symbol?
                                                          module-path-index?)
                                                  (-> any/c))]
                              [can-cycle? any/c]
                              [dir path-string?])
         any]{

 生成通过 @racket[prop:serializable] 属性与结构类型关联的值。此值由 @racket[serialize] 使用。

 @racket[to-vector] 过程应接受结构实例并生成实例内容的向量。

 @racket[deserialize-id] 值指示反序列化信息的绑定，指向模块导出或顶层定义。它必须是以下之一：

@itemize[

 @item{如果 @racket[deserialize-id] 是标识符，且 @racket[(identifier-binding deserialize-id)] 生成列表，则第三个元素用于导出模块，否则假定为顶层。在直接尝试导出模块之前，会尝试其 @racket[deserialize-info] 子模块；如果没有可用的 @racket[deserialize-info] 子模块或未找到导出项，则尝试模块本身。无论哪种情况，都使用 @racket[syntax-e] 获取导出标识符或顶层定义的名称。}

 @item{如果 @racket[deserialize-id] 是符号，它指示由符号命名的顶层变量。}

 @item{如果 @racket[deserialize-id] 是 pair，@racket[car] 必须是命名导出标识符的符号，@racket[cdr] 必须是指定导出模块的 module path index。}

 @item{如果 @racket[deserialize-id] 是过程，则在序列化期间应用它并将其结果用于 @racket[deserialize-id]。}
                                                      
]

 参见 @racket[make-deserialize-info] 和 @racket[deserialize] 了解更多信息。

 如果实例不应序列化（反序列化需要创建具有虚拟字段值的结构实例，然后稍后更新实例），则 @racket[can-cycle?] 参数应为 false。

 @racket[dir] 参数应为用于解析 @racket[deserialize-id] 绑定的模块引用的目录路径。当 @racket[deserialize-id] 指示通过相对于顶层的相对路径加载的模块时，此目录路径被用作最后手段。通常，应为 @racket[(or (current-load-relative-directory) (current-directory))]。

@history[#:changed "7.0.0.6" @elem{Allow @racket[deserialize-id] to be a procedure.}]}

@examples[
 #:eval ser-eval
 (struct pie (type)
   #:mutable
   #:property prop:serializable
   (make-serialize-info
    (λ (this)
      (vector (pie-type this)))
    'pie-beam
    #t
    (or (current-load-relative-directory) (current-directory))))
 (define pie-beam
   (make-deserialize-info
    (λ (type)
      (pie type))
    (λ ()
      (define pie-pattern (pie 'transporter-error))
      (values pie-pattern
              (λ (type)
                (set-pie-type! pie-pattern type))))))
 (define original-pie
   (pie 'apple))
 original-pie
 (define pie-in-transit
   (serialize original-pie))
 pie-in-transit
 (define beamed-up-pie
   (deserialize pie-in-transit))
 beamed-up-pie
 (pie-type beamed-up-pie)
 (equal? beamed-up-pie original-pie)]

@; ----------------------------------------------------------------------

@section{Serialization Structures}

@defmodule[racket/serialize-structs]{@racketmodname[racket/serialize-structs] 模块仅提供 @racket[prop:serializable]、@racket[make-serialize-info]、@racket[make-deserialize-info]，这对最小化支持序列化的依赖有用。}

@history[#:added "8.15.0.3"]

@; ----------------------------------------------------------------------

@close-eval[ser-eval]
