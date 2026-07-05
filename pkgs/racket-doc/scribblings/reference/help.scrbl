#lang scribble/doc
@(require "mz.rkt" scribble/core scribble/html-properties
          (for-label racket/help net/url racket/gui/base))

@; 注意这个到主文档页面的硬编码链接：
@(define main-doc-page
   (hyperlink "../index.html"
              #:style (make-style
                       "plainlink" 
                       (list
                        (make-attributes 
                         `((onclick . ,(format "return GotoPLTRoot(\"~a\");" (version)))))))
              "主文档页面"))

@title{交互式帮助}

@note-init-lib[racket/help]

@defform*[#:id help
          [help
           (help string ...)
           (help id)
           (help id #:from module-path)
           (help #:search datum ...)]]{

@emph{如需常规帮助，请参见 @|main-doc-page|。}

@racket[help] 形式搜索文档并打开用户的浏览器以显示结果。

@margin-note{参见 @racketmodname[net/sendurl] 了解如何启动用户的浏览器以显示帮助信息。}

简单的 @racket[help] 或 @racket[(help)] 形式会打开主文档页面。

@racket[(help string ...)] 形式——使用字面字符串，而不是产生字符串的表达式——执行字符串匹配搜索。例如，

@racketblock[
(help "web browser" "firefox")
]

在文档索引中搜索包含短语 "web browser" 或 "firefox" 的引用。

@racket[(help id)] 形式查找特定于当前 @racket[id] 绑定的文档。例如，

@racketblock[
(require net/url)
(help url->string)
]

打开 Web 浏览器以显示 @racketmodname[net/url] 库中 @racket[url->string] 的文档。

对于 @racket[help] 而言，@racket[for-label] require 引入一个绑定，但不实际执行 @racketmodname[net/url] 库——用于当您想检查文档但无法或不想运行提供模块的情况。

@racketblock[
(require racket/gui) (code:comment @#,t{在 @exec{racket} 中不起作用})
(require (for-label racket/gui)) (code:comment @#,t{在 @exec{racket} 中可以})
(help frame%)
]

如果 @racket[id] 没有 for-label 和正常绑定，则 @racket[help] 列出所有已知导出 @racket[id] 绑定的库。

@racket[(help id #:from module-path)] 变体类似于 @racket[(help id)]，但仅使用 @racket[module-path] 的导出。（@racket[module-path] module 在一个临时命名空间中被 require for-label。）

@racketblock[
(help frame% #:from racket/gui) (code:comment @#,t{与上面的等价})
]

@racket[(help #:search datum ...)] 形式类似于 @racket[(help string ...)]，其中 @racket[datum] 的任何非字符串形式使用 @racket[display] 转换为字符串。没有 @racket[datum] 被当作表达式求值。

例如，

@racketblock[
(help #:search "web browser" firefox)
]

也在文档索引中搜索包含短语 "web browser" 或 "firefox" 的引用。

}
