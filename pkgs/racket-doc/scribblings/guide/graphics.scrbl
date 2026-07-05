#lang scribble/doc
@(require scribble/manual "guide-utils.rkt" scribblings/private/docname)

@title[#:tag "graphics"]{图形和 GUI}

Racket 提供了许多用于图形和图形用户界面（GUI）的库：

@itemlist[

 @item{@racketmodname[racket/draw #:indirect] 库提供基本的绘图工具，
       包括绘图上下文（如 bitmap）和 PostScript 文件。

       参见 @Draw[] 了解更多信息。}

 @item{@racketmodname[racket/gui #:indirect] 库提供 GUI widget，
       如窗口、按钮、复选框和文本字段。该库还包括一个复杂且可扩展的文本编辑器。

       参见 @GUI[] 了解更多信息。}

 @item{@racketmodname[pict #:indirect] 库提供比 @racketmodname[racket/draw] 更具
       函数式的抽象层。该层在使用 @Slideshow{Slideshow} 创建幻灯片时特别有用，但也
       可用于为 @seclink[#:doc '(lib "scribblings/scribble/scribble.scrbl") "top"]{Scribble} 文档绘图或其他绘图任务。使用
       @racketmodname[pict #:indirect] 库创建的图片可以渲染到任何绘图上下文中。

       参见 @Slideshow[] 了解更多信息。}

 @item{@racketmodname[2htdp/image #:indirect] 库与
       @racketmodname[pict #:indirect] 类似。它经过精简更适合教学用途，
       但也稍微更特定于屏幕和 bitmap 绘图。

       参见 @racketmodname[2htdp/image #:indirect] 了解更多信息。}

 @item{@racketmodname[sgl #:indirect] 库提供用于 3D 图形的 OpenGL。
       渲染 OpenGL 的上下文可以是使用 @racketmodname[racket/gui #:indirect] 创建的窗口或 bitmap。

       参见 @other-doc['(lib "sgl/scribblings/sgl.scrbl") #:indirect "SGL"] 了解更多
       信息。}

]