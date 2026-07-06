#lang scribble/doc
@(require "mz.rkt" (for-label racket/date))

@title[#:tag "time"]{Time}

@defproc[(current-seconds) exact-integer?]{

返回自 @deftech{纪元} 以来的当前时间（秒）：
1970年1月1日 UTC 午夜。}


@defproc[(current-inexact-milliseconds) real?]{

返回自 @tech{纪元} 以来的当前时间（毫秒）。
结果可能包含毫秒的小数部分。

@examples[(eval:alts
(current-inexact-milliseconds)
1289513737015.418
)]

在此示例中，@racket[1289513737015] 是毫秒，@racket[418] 是微秒。}


@defproc[(current-inexact-monotonic-milliseconds) real?]{

返回自未指定起始时间以来的毫秒数。
与 @racket[current-inexact-milliseconds] 不同（它对系统时钟敏感，
如果系统时钟被调整，可能比真实时间更快地前进或后退），
@racket[current-inexact-monotonic-milliseconds] 的结果在 Racket 进程内
始终与真实时间同步前进，但跨进程的结果不可比较。

@examples[(eval:alts
(current-inexact-monotonic-milliseconds)
12772.418
)]

@history[#:added "8.1.0.4"]}


@defproc[(seconds->date [secs-n real?]
                        [local-time? any/c #t])
         date*?]{

接受 @racket[secs-n]（自 @tech{纪元} 以来的时间，以秒为单位，类似于 @racket[(current-seconds)]、
@racket[(file-or-directory-modify-seconds _path)] 或
@racket[(/ (current-inexact-milliseconds) 1000)] 的值），并返回
@racket[date*] 结构类型的实例。注意 @racket[secs-n] 可以包含秒的小数部分。
如果 @racket[secs-n] 太小或太大，则 @exnraise[exn:fail]。

如果 @racket[local-time?] 是 @racket[#t]，则生成的 @racket[date*] 反映本地时区的时间，
否则它反映 UTC 的日期。}

@defstruct[date ([second (integer-in 0 60)]
                 [minute (integer-in 0 59)]
                 [hour (integer-in 0 23)]
                 [day (integer-in 1 31)]
                 [month (integer-in 1 12)]
                 [year exact-integer?]
                 [week-day (integer-in 0 6)]
                 [year-day (integer-in 0 365)]
                 [dst? boolean?]
                 [time-zone-offset exact-integer?])
                #:inspector #f]{

表示日期。@racket[_second] 字段仅在闰秒时达到 @racket[60]。
@racket[week-day] 字段中 @racket[0] 表示星期日，@racket[1] 表示星期一，以此类推。
@racket[year-day] 字段中 @racket[0] 表示1月1日，@racket[1] 表示1月2日，@|etc|；
@racket[year-day] 字段仅在闰年达到 @racket[365]。

@racket[dst?] 字段在日期反映夏令时调整时为 @racket[#t]。
@racket[time-zone-offset] 字段报告当前时区相对于 UTC（GMT）的秒数
（例如，太平洋标准时间是 @racket[-28800]），包括任何夏令时调整
（例如，太平洋夏令时是 @racket[-25200]）。当 @racket[date] 记录由
@racket[seconds->date] 以 @racket[#f] 作为第二个参数生成时，
@racket[dst?] 和 @racket[time-zone-offset] 字段分别为 @racket[#f] 和 @racket[0]。

@racket[date] 构造函数接受 @racket[dst?] 的任何值，并将任何非 @racket[#f] 值转换为 @racket[#t]。

@racket[time-zone-offset] 字段生成的值往往对 @envvar{TZ} 环境变量的值敏感，
尤其是在 Unix 平台上；详细信息请查阅系统文档（通常在 @tt{tzset} 下）。

另请参见 @racketmodname[racket/date] 库。}


@defstruct[(date* date) ([nanosecond (integer-in 0 999999999)]
                         [time-zone-name (and/c string? immutable?)])]{

用纳秒和时区名称扩展 @racket[date]，例如 @racket["MDT"]、@racket["Mountain Daylight Time"] 或 @racket["UTC"]。

当 @racket[date*] 记录由 @racket[seconds->date] 以 @racket[#f] 作为第二个参数生成时，
@racket[time-zone-name] 字段为 @racket["UTC"]。

@racket[date*] 构造函数接受可变字符串作为 @racket[time-zone-name] 并将其转换为不可变字符串。}


@defproc[(current-milliseconds) exact-integer?]{

类似于 @racket[current-inexact-milliseconds]，但强制转换为 @tech{fixnum}（可能为负数）。
由于结果是 @tech{fixnum}，在32位平台上该值仅在有限（尽管相当长）的时间内递增。}


@defproc[(current-process-milliseconds [scope (or/c #f thread? 'subprocesses) #f]) 
         exact-integer?]{

返回底层操作系统消耗的处理器时间量，以 @tech{fixnum} 毫秒为单位，
包括用户时间和系统时间。

@itemlist[

 @item{如果 @racket[scope] 是 @racket[#f]，报告的时间是针对所有 Racket 线程和 @tech{place} 的。}

 @item{如果 @racket[scope] 是一个线程，结果是特定于线程运行时间的，
   但可能包括其他 @tech{place} 的时间。线程与其他线程同步越多，
   每线程处理器时间的记录就越不精确。}

 @item{如果 @racket[scope] 是 @racket['subprocesses]，结果是已知已完成子进程的
   进程时间总和（参见 @secref["subprocess"]）——以及子进程的已知已完成子进程等，
   在 @|AllUnix| 上——跨所有 @tech{place}。}

]

结果的精度是平台相关的，并且由于结果是 @tech{fixnum}，
在32位平台上该值仅在有限（尽管相当长）的时间内递增。

@history[#:changed "6.1.1.4" @elem{添加了 @racket['subprocesses] 模式。}]}


@defproc[(current-gc-milliseconds) exact-integer?]{

返回 Racket 垃圾收集到目前为止消耗的处理器时间量，以 @tech{fixnum} 毫秒为单位。
该时间是 @racket[(current-process-milliseconds)] 报告的时间的一部分，
并且同样受到限制。}


@defproc[(time-apply [proc procedure?]
                     [lst list?])
         (values list?
                 exact-integer?
                 exact-integer?
                 exact-integer?)]{

Collects timing information for a procedure application.

Four values are returned: a list containing the result(s) of applying
@racket[proc] to the arguments in @racket[lst], the number of milliseconds of
CPU time required to obtain this result, the number of ``real'' milliseconds
required for the result, and the number of milliseconds of CPU time (included
in the first result) spent on garbage collection.

The reliability of the timing numbers depends on the platform. If
multiple Racket threads are running, then the reported time may
include work performed by other threads.}

@defform[(time body ...+)]{

Reports @racket[time-apply]-style timing information for the
evaluation of @racket[expr] directly to the current output port.  The
result is the result of  the last @racket[body].}

@; ----------------------------------------------------------------------

@section[#:tag "date-string"]{Date Utilities}
@margin-note{For more date & time operations, see
  @other-doc['(lib "gregor/scribblings/gregor.scrbl") #:indirect "Gregor: Date and Time"]
  or @link["../srfi/srfi-19.html"]{srfi/19}}

@note-lib-only[racket/date]

@defproc[(current-date) date*?]{

An abbreviation for @racket[(seconds->date (* 0.001 (current-inexact-milliseconds)))].}

@defproc[(date->string [date date?] [time? any/c #f]) string?]{

Converts a date to a string. The returned string contains the time of
day only if @racket[time?]. See also @racket[date-display-format].}


@defparam[date-display-format format (or/c 'american
                                           'chinese
                                           'german
                                           'indian
                                           'irish
                                           'iso-8601
                                           'rfc2822
                                           'julian)]{

Parameter that determines the date string format. The initial format
is @racket['american].}

@defproc[(date->seconds [date date?] [local-time? any/c #t]) exact-integer?]{
Finds the representation of a date in platform-specific seconds.
If the platform cannot represent the specified date,
@exnraise[exn:fail].

The @racket[week-day], @racket[year-day] fields of @racket[date] are
ignored.  The @racket[dst?] and @racket[time-zone-offset] fields of
@racket[date] are also ignored; the date is assumed to be in local
time by default or in UTC if @racket[local-time?] is @racket[#f].}

@defproc[(date*->seconds [date date?] [local-time? any/c #t]) real?]{
Like @racket[date->seconds], but returns an exact number that can
include a fraction of a second based on @racket[(date*-nanosecond
date)] if @racket[date] is a @racket[date*] instance.}

@defproc[(find-seconds [second (integer-in 0 61)]
                       [minute (integer-in 0 59)]
                       [hour (integer-in 0 23)]
                       [day (integer-in 1 31)]
                       [month (integer-in 1 12)]
                       [year exact-integer?]
                       [local-time? any/c #t])
         exact-integer?]{

Finds the representation of a date in platform-specific seconds. The
arguments correspond to the fields of the @racket[date] structure---in
local time by default or UTC if @racket[local-time?] is
@racket[#f]. If the platform cannot represent the specified date, an
error is signaled, otherwise an integer is returned.

@history[#:changed "9.0.0.4" @elem{Allow negative numbers for @racket[year].}]}


@defproc[(date->julian/scaliger [date date?]) exact-integer?]{

Converts a date structure (up to 2099 BCE Gregorian) into a Julian
date number. The returned value is not a strict Julian number, but
rather Scaliger's version, which is off by one for easier
calculations.}


@defproc[(julian/scaliger->string [date-number exact-integer?])
         string?]{

Converts a Julian number (Scaliger's off-by-one version) into a
string.}


@deftogether[(
@defproc[(date->julian/scalinger [date date?]) exact-integer?]
@defproc[(julian/scalinger->string [date-number exact-integer?])
         string?]
)]{

The same as @racket[date->julian/scaliger] and
@racket[julian/scaliger->string], but misspelled.}
