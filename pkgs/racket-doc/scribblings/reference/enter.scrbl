#lang scribble/doc
@(require "mz.rkt"
          (for-label racket/enter
                     racket/rerequire))

@title[#:tag "enter"]{Entering Modules}

@note-init-lib[racket/enter]

@defform*/subs[[(enter! module-path)
                (enter! #f)
                (enter! module-path flag ...+)]
               ([flag #:quiet
                      #:verbose-reload
                      #:verbose
                      #:dont-re-require-enter])]{

适用于 @tech{REPL} 中，例如当 @exec{racket} 以交互模式启动时。
当提供 @racket[module-path]（与 @racket[require] 中的语义相同）时，
相应的模块会通过 @racket[dynamic-rerequire] 加载或调用，
并通过 @racket[module->namespace] 将当前 @tech{namespace} 更改为该模块体。
当提供 @racket[#f] 时，则将当前 @tech{namespace} 恢复为原始的。

额外的 @racket[flag] 可以自定义 @racket[enter!] 的方面：
@itemize[

 @item{@racket[#:verbose]、@racket[#:verbose-reload] 和
  @racket[#:quiet] 标志分别对应于 @racket[dynamic-rerequire] 的
  @racket['all]、@racket['reload] 和 @racket['none] 详细级别。
  默认值对应于 @racket[#:verbose-reload]。}

 @item{切换到指定模块的命名空间后，@racket[enter!] 会自动将 @racket[racket/enter]
  require 到该命名空间中，以便再次使用 @racket[enter!] 切换命名空间。
  在某些情况下，require @racket[racket/enter] 可能不是期望的行为
  （例如在用到 @racket[racket/enter] 的工具中）；使用
  @racket[#:dont-re-require-enter] 标志来禁用该 require。}]
}

@defproc[(dynamic-enter! [mod (or/c module-path? #f)]
                         [#:verbosity verbosity (or/c 'all 'reload 'none) 'reload]
                         [#:re-require-enter? re-require-enter? any/c #t])
         void?]{

@racket[enter!] 的过程变体，其中 @racket[verbosity] 被传递给
@racket[dynamic-rerequire]，而 @racket[re-require-enter?] 决定是否
@racket[dynamic-enter!] 在新进入的命名空间中 require @racket[racket/enter]。

@history[#:added "6.0.0.1"]}
