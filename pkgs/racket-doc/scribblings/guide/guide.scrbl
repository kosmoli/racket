#lang scribble/manual
@(require scribble/eval "guide-utils.rkt" scribblings/private/docname)

@title{Racket 指南}

@["Matthew Flatt" "Robert Bruce Findler" "PLT"]

本指南面向 Racket 新手或 Racket 的某个部分的新手程序员。已有编程经验的读者适合阅读本书，如果是编程新手请考虑阅读 @|HtDP|。如果你想快速了解 Racket，请从 @Quick[Quick-title] 开始。

@seclink["to-scheme"]{第 2 章} 提供了 Racket 的简要介绍。从 @seclink["datatypes"]{第 3 章} 开始，本指南深入细节——涵盖 Racket 工具箱的大部分内容，但精确细节请参考 @|Racket| 和其他参考手册。

@margin-note{@hyperlink["https://github.com/racket/racket/tree/master/pkgs/racket-doc/scribblings/guide"]{GitHub}。}

@table-of-contents[]

@include-section["welcome.scrbl"]

@include-section["to-scheme.scrbl"]

@include-section["data.scrbl"]

@include-section["forms.scrbl"]

@include-section["define-struct.scrbl"]

@include-section["modules.scrbl"]

@include-section["contracts.scrbl"]

@include-section["io.scrbl"]

@include-section["regexp.scrbl"]

@include-section["control.scrbl"]

@include-section["for.scrbl"]

@include-section["match.scrbl"]

@include-section["class.scrbl"]

@include-section["unit.scrbl"]

@include-section["namespaces.scrbl"]

@include-section["macros.scrbl"]

@include-section["languages.scrbl"]

@include-section["concurrency.scrbl"]

@include-section["performance.scrbl"]

@include-section["parallelism.scrbl"]

@include-section["running.scrbl"]

@include-section["other.scrbl"]

@include-section["dialects.scrbl"]

@include-section["other-editors.scrbl"]

@; ----------------------------------------------------------------------

@(bibliography 

  (bib-entry #:key "Goldberg04"
             #:author "David Goldberg, Robert Bruce Findler, and Matthew Flatt"
             #:title "Super and Inner---Together at Last!"
             #:location "Object-Oriented Programming, Languages, Systems, and Applications"
             #:date "2004"
             #:url "http://www.cs.utah.edu/plt/publications/oopsla04-gff.pdf")

  (bib-entry #:key "Flatt02"
             #:author "Matthew Flatt"
             #:title "Composable and Compilable Macros: You Want it When?"
             #:location "International Conference on Functional Programming"
             #:date "2002")
 
  (bib-entry #:key "Flatt06"
             #:author "Matthew Flatt, Robert Bruce Findler, and Matthias Felleisen"
             #:title "Scheme with Classes, Mixins, and Traits (invited tutorial)"
             #:location "Asian Symposium on Programming Languages and Systems"
             #:url "http://www.cs.utah.edu/plt/publications/aplas06-fff.pdf"
             #:date "2006")
 
 (bib-entry #:key "Mitchell02"
            #:author "Richard Mitchell and Jim McKim"
            #:title "Design by Contract, by Example"
            #:is-book? #t
            #:date "2002")

 (bib-entry #:key "Sitaram05"
            #:author "Dorai Sitaram"
            #:title "pregexp: Portable Regular Expressions for Scheme and Common Lisp"
            #:url "http://www.ccs.neu.edu/home/dorai/pregexp/"
            #:date "2002")

)

@index-section[]
