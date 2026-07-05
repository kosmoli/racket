#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "contmarks"]{Continuation 标记}

可以使用 @cppi{scheme_set_cont_mark} 将标记附加到当前 continuation 帧。要强制创建新帧（例如，在你的 function 内部嵌套 function 调用期间），使用 @cppi{scheme_push_continuation_frame}，然后使用 @cppi{scheme_pop_continuation_frame} 移除该帧。

@function[(void scheme_set_cont_mark
           [Scheme_Object* key]
           [Scheme_Object* val])]{

添加/设置当前 continuation 中的标记。}

@function[(void scheme_push_continuation_frame
           [Scheme_Cont_Frame_Data* data])]{

创建新的 continuation 帧。@var{data} 记录不需要初始化，可以在 C 栈上分配。将 @var{data} 提供给 @cpp{scheme_pop_continuation_frame} 以移除 continuation 帧。}

@function[(void scheme_pop_continuation_frame
           [Scheme_Cont_Frame_Data* data])]{

移除由 @cpp{scheme_pop_continuation_frame} 创建的 continuation 帧。}
