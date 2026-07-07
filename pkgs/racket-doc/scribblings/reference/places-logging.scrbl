#lang scribble/doc 
@(require "mz.rkt" (for-label racket/place))

@title[#:tag "place-logging"]{Places Logging}

Place 事件被报告给名为 @racket['place] 的日志记录器。
除了字符串消息外，每个为 place 记录的事件都有一个数据值，它是 @racket[place-event] @tech{prefab} 结构的实例：

@racketblock[
(struct place-event (place-id action value time)
  #:prefab)
]

@racket[place-id] 字段是一个标识 place 的精确整数。

@racket[time] 字段是一个不精确数字，表示时间，表示方式与 @racket[current-inexact-milliseconds] 相同。

@racket[action] 字段是一个 symbol：

@itemlist[

 @item{@racket['create]: 已创建一个 place。此事件在创建者 place 中记录，
       事件的 @racket[value] 字段包含已创建 place 的 ID。}

 @item{@racket['reap]: 先前在当前 place 中创建的 place 已退出
       （并且该事实已被检测到，可能通过 @racket[place-wait]）。事件的
       @racket[value] 字段包含已退出 place 的 ID。}

 @item{@racket['enter]: 一个 place 已启动，在已启动的 place 内记录。事件的
       @racket[value] 字段为 @racket[#f]。}

 @item{@racket['exit]: 一个 place 正在退出，在正在退出的 place 内记录。事件的
       @racket[value] 字段为 @racket[#f]。}

 @item{@racket['put]: 已发送一个 place-channel 消息。事件的 @racket[value]
       字段是一个近似消息大小的正精确整数。}

 @item{@racket['get]: 已接收一个 place-channel 消息。事件的 @racket[value]
       字段是一个近似消息大小的正精确整数。}

]

@history[#:changed "6.0.0.2" @elem{通过 @racket['place] 和
         @racket[place-event] 添加了日志记录。}]
