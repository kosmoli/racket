#lang scribble/manual
@(require "mz.rkt"
          scribble/core scribble/html-properties scribble/latex-properties
          racket/list)

@(define (racket-extra-libs)
   (make-delayed-element
    (lambda (renderer p ri)
      (let ([mods (append-map
                   (lambda (k) (list ", " (resolve-get p ri k)))
                   (sort (resolve-get-keys
                          p ri (lambda (v) (eq? (car v) 'racket-extra-lib)))
                         string<?
                         #:key (lambda (k) (symbol->string (cadr k)))
                         #:cache-keys? #t))])
        `(,@(drop-right mods 2) ", and " ,(last mods))))
    (lambda () "...")
    (lambda () "...")))

@(define (extras)
   (make-style #f (list
                   (make-css-addition "extras.css")
                   (make-tex-addition "extras.tex"))))

@title[#:style (extras)]{The Racket Reference}

@author["Matthew Flatt" "PLT"]

本手册定义了 Racket 核心语言并描述了其最突出的配套库。
配套手册 @|Guide| 提供了对语言更友好（尽管不够精确和完整）的概述。

@margin-note{本手册的源码可在
@hyperlink["https://github.com/racket/racket/tree/master/pkgs/racket-doc/scribblings/reference"]{GitHub} 上获取。}

@defmodulelang*[(racket/base racket)
                ;; Use sources for overlap with `scheme' and `mzscheme':
                #:use-sources ('#%kernel
                               racket/private/more-scheme
                               racket/private/misc
                               racket/private/qqstx
                               racket/private/stxcase-scheme
                               racket/private/letstx-scheme
                               racket/private/core-syntax
                               racket/private/stx
                               racket/private/map
                               racket/private/list
                               racket/private/base)]{

除非另有说明，本手册中定义的绑定由 @racketmodname[racket/base] 和 @racketmodname[racket] 语言导出。}


@margin-note{@racketmodname[racket/base] 库比 @racketmodname[racket] 库小得多，通常加载更快。

@racketmodname[racket] 库将 @racketmodname[racket/base]@racket-extra-libs[] 组合在一起。
此外，它从 @racketmodname[racket/base] 重新导出 @racket[for-syntax] 的所有内容。}

@table-of-contents[]

@include-section["model.scrbl"]
@include-section["notation.scrbl"]
@include-section["syntax.scrbl"]
@include-section["data.scrbl"]
@include-section["struct.scrbl"]
@include-section["class.scrbl"]
@include-section["units.scrbl"]
@include-section["contracts.scrbl"]
@include-section["match.scrbl"]
@include-section["control.scrbl"]
@include-section["concurrency.scrbl"]
@include-section["macros.scrbl"]
@include-section["io.scrbl"]
@include-section["security.scrbl"]
@include-section["os.scrbl"]
@include-section["memory.scrbl"]
@include-section["unsafe.scrbl"]
@include-section["running.scrbl"]

@;------------------------------------------------------------------------

@(bibliography

  (bib-entry #:key "Baker93"
             #:author "Henry G. Baker"
             #:title "函数对象的平等权利，或，事物变化越多，越是相同"
             #:date "1993"
             #:location "SIGPLAN OOPS Messenger"
             #:url "https://doi.org/10.1145/165593.165596")

  (bib-entry #:key "C99"
             #:author "ISO/IEC"
             #:title "ISO/IEC 9899:1999 Cor. 3:2007(E)"
             #:date "2007")

  (bib-entry #:key "Culpepper07"
             #:author "Ryan Culpepper, Sam Tobin-Hochstadt, and Matthew Flatt"
             #:title "高级宏学与Typed Scheme的实现"
             #:location "Scheme与函数式编程研讨会"
             #:url "https://www2.ccs.neu.edu/racket/pubs/scheme2007-ctf.pdf"
             #:date "2007")

  (bib-entry #:key "Danvy90"
             #:author "Olivier Danvy and Andre Filinski"
             #:title "抽象控制"
             #:location "LISP与函数式编程"
             #:url "https://doi.org/10.1145/91556.91622"
             #:date "1990")

  (bib-entry #:key "Felleisen88a"
             #:author "Matthias Felleisen"
             #:title "first-class prompt的理论与实践"
             #:location "编程语言原理"
             #:url "https://www.cs.tufts.edu/~nr/cs257/archive/matthias-felleisen/prompts.pdf"
             #:date "1988")

  (bib-entry #:key "Felleisen88"
             #:author "Matthias Felleisen, Mitch Wand, Dan Friedman, and Bruce Duba"
             #:title "抽象延续：处理全函数跳转的数学语义"
             #:location "LISP与函数式编程"
             #:url "https://help.luddy.indiana.edu/techreports/TRNNN.cgi?trnum=TR248"
             #:date "1988")

  (bib-entry #:key "Feltey18"
             #:author "Daniel Feltey, Ben Greenman, Christophe Scholliers, Robert Bruce Findler, and Vincent St-Amour"
             #:title "可折叠契约：修复渐进类型化的病理"
             #:location "面向对象编程、系统和语言（OOPSLA）"
             #:url "https://www.ccis.northeastern.edu/~types/publications/collapsible/fgsfs-oopsla-2018.pdf"
             #:date "2018")

  (bib-entry #:key "Flatt02"
             #:author "Matthew Flatt"
             #:title "可组合和可编译的宏：你什么时候想要它？"
             #:location "函数式编程国际会议（ICFP）"
             #:url "https://www.cs.utah.edu/plt/publications/macromod.pdf"
             #:date "2002")

  (bib-entry #:key "Flatt07"
             #:author "Matthew Flatt, Gang Yu, Robert Bruce Findler, and Matthias Felleisen"
             #:title "为生产编程环境添加有界和可组合的控制"
             #:location "函数式编程国际会议（ICFP）"
             #:url "http://www.cs.utah.edu/plt/publications/icfp07-fyff.pdf"
             #:date "2007")

  (bib-entry #:key "Flatt13"
             #:author "Matthew Flatt"
             #:title "Racket中的子模块：你什么时候想要它，再一次？"
             #:location "生成式编程：概念与经验国际会议（GPCE'13）"
             #:url "https://www.cs.utah.edu/plt/publications/gpce13-f-color.pdf"
             #:date "2013")

  (bib-entry #:key "Friedman95"
             #:title "异常系统提案"
             #:author "Daniel P. Friedman, C. T. Haynes, and R. Kent Dybvig"
             #:location "网页"
             #:url "https://web.archive.org/web/20161012054505/http://www.cs.indiana.edu/scheme-repository/doc.proposals.exceptions.html"
             #:date "1995")

  (bib-entry #:key "Gasbichler02"
             #:title "Scsh中的进程与用户级线程"
             #:author "Martin Gasbichler and Michael Sperber"
             #:date "2002"
             #:url "http://www.ccs.neu.edu/home/shivers/papers/scheme02/article/threads.pdf"
             #:location "Scheme与函数式编程研讨会")

  (bib-entry #:key "Greenberg15"
             #:author "Michael Greenberg"
             #:title "空间高效的Manifest契约"
             #:location "编程语言原理（POPL）"
             #:url "https://cs.pomona.edu/~michael/papers/popl2015_space.pdf"
             #:date "2015")

 (bib-entry #:key "Gunter95"
            #:author "Carl Gunter, Didier Remy, and Jon Rieke"
            #:title "类ML语言中异常与控制的一般化"
            #:location "函数式编程语言与计算机体系结构"
            #:url "http://gallium.inria.fr/~remy/ftp/prompt.pdf"
            #:date "1995")

 (bib-entry #:key "Haynes84"
            #:author "Christopher T. Haynes and Daniel P. Friedman"
            #:title "引擎构建进程抽象"
            #:location "LISP与函数式编程研讨会"
            #:url "https://legacy.cs.indiana.edu/ftp/techreports/TR159.pdf"
            #:date "1984")

 (bib-entry #:key "Hayes97"
            #:author "Barry Hayes"
            #:title "Ephemerons：一种新的终结机制"
            #:location "面向对象语言、编程、系统和应用"
            #:url "https://static.aminer.org/pdf/PDF/000/522/273/ephemerons_a_new_finalization_mechanism.pdf"
            #:date "1997")

 (bib-entry #:key "Hieb90"
            #:author "Robert Hieb and R. Kent Dybvig"
            #:title "延续与并发"
            #:location "并行编程原理与实践"
            #:url "https://legacy.cs.indiana.edu/ftp/techreports/TR256.pdf"
            #:date "1990")

  (bib-entry #:key "Lamport79"
             #:title "如何制造能正确执行多进程程序的多处理器计算机"
             #:author "Leslie Lamport"
             #:location "IEEE计算机汇刊"
             #:url "https://www.microsoft.com/en-us/research/uploads/prod/2016/12/How-to-Make-a-Multiprocessor-Computer-That-Correctly-Executes-Multiprocess-Programs.pdf"
             #:date "179")

  (bib-entry #:key "L'Ecuyer02"
            #:author "Pierre L'Ecuyer, Richard Simard, E. Jack Chen, and W. David Kelton"
            #:title "具有许多长流和子流的面向对象随机数包"
            #:location "运筹学，50(6)"
            #:url "https://www.iro.umontreal.ca/~lecuyer/myftp/papers/streams00.pdf"
            #:date "2002")

  (bib-entry #:key "Queinnec91"
             #:author "Queinnec and Serpette"
             #:title "用于部分延续的动态范围控制操作符"
             #:location "编程语言原理"
             #:url "https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.40.9946&rep=rep1&type=pdf"
             #:date "1991")

  (bib-entry #:key "Reppy99"
             #:author "John H. Reppy"
             #:title "ML中的并发编程"
             #:is-book? #t
             #:location "剑桥大学出版社"
             #:url "https://doi.org/10.1017/CBO9780511574962"
             #:date "1999")

  (bib-entry #:key "Roux14"
             #:author "Pierre Roux"
             #:title "基本算术运算的无害双重舍入"
             #:location @elem{@italic{形式化推理期刊}, 7(1)}
             #:date "2014")

  (bib-entry #:key "Sapin18"
             #:author "Simon Sapin"
             #:title "WTF-8编码"
             #:url "https://wtf-8.codeberg.page"
             #:date "2018")

  (bib-entry #:key "Shan04"
             #:author "Ken Shan"
             #:title "转向控制"
             #:location "Scheme与函数式编程研讨会"
             #:url "http://homes.sice.indiana.edu/ccshan/recur/recur.pdf"
             #:date "2004")

 (bib-entry #:key "Sperber07"
            #:author "Michael Sperber, R. Kent Dybvig, Matthew Flatt, and Anton van Straaten (editors)"
            #:title @elem{算法语言Scheme的修订@superscript{6}报告}
            #:date "2007"
            #:url "http://www.r6rs.org/")

  (bib-entry #:key "Sitaram90"
             #:author "Dorai Sitaram and Matthias Felleisen"
             #:title "控制定界符及其层次"
             #:location @italic{Lisp与符号计算}
             #:url "https://www2.ccs.neu.edu/racket/pubs/lasc1990-sf.pdf"
             #:date "1990")

  (bib-entry #:key "Sitaram93"
             #:title "处理控制"
             #:author "Dorai Sitaram"
             #:location "编程语言设计与实现"
             #:url "http://citeseerx.ist.psu.edu/viewdoc/summary?doi=10.1.1.22.7256"
             #:date "1993")

  (bib-entry #:key "SRFI-42"
             #:title "SRFI-42：急切推导式"
             #:author "Sebastian Egner"
             #:location "SRFI"
             #:url "http://srfi.schemers.org/srfi-42/"
             #:date "2003")

  (bib-entry #:key "Strickland12"
             #:title "Chaperone与Impersonator：合理介入的运行时支持"
             #:author "T. Stephen Strickland, Sam Tobin-Hochstadt, Matthew Flatt, and Robert Bruce Findler"
             #:location "面向对象编程、系统和语言（OOPSLA）"
             #:url "http://www.eecs.northwestern.edu/~robby/pubs/papers/oopsla2012-stff.pdf"
             #:date "2012")

  (bib-entry #:key "Stucki15"
             #:title "RRB Vector：实用的通用不可变序列"
             #:author "Nicolas Stucki, Tiark Rompf, Vlad Ureche, and Phil Bagwell"
             #:location "函数式编程国际会议"
             #:url "https://dl.acm.org/doi/abs/10.1145/2784731.2784739"
             #:date "2015")

  (bib-entry #:key "Torosyan21"
             #:title "HAMT的运行时和编译器支持"
             #:author "Son Torosyan, Jon Zeppieri, and Matthew Flatt"
             #:location "动态语言研讨会（DLS）"
             #:url "https://www.cs.utah.edu/plt/publications/dls21-tzf.pdf"
             #:date "2021")
  )

@;------------------------------------------------------------------------

@index-section[]
