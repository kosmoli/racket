#lang scribble/doc
@(require "utils.rkt" (for-label scheme/tcp))

@bc-title[#:tag "threads"]{线程}

初始化函数 @cppi{scheme_basic_env} 创建主 Racket 线程；所有其他线程均通过调用 @cppi{scheme_thread} 来创建。

每个内部 Racket 线程的相关信息保存在一个 @cppi{Scheme_Thread} 结构体中。当前线程的结构体指针可通过 @cppdef{scheme_current_thread} 获取，也可通过 @cppi{scheme_get_current_thread} 获取。@cpp{Scheme_Thread} 结构体包含以下字段：

@itemize[

 @item{@cppi{error_buf} --- 用于跳出错误的 @cppi{mz_jmp_buf} 值。当前线程的 @cpp{error_buf} 值可通过 @cppi{scheme_error_buf} 获取。}

 @item{@cppi{cjs.jumping_to_continuation} --- 用于区分转义 continuation 调用与错误转义的标志。当前线程的 @cpp{cjs.jumping_to_continuation} 值可通过 @cppi{scheme_jumping_to_continuation} 获取。}

 @item{@cppi{init_config} --- 线程的初始参数化。另见 @secref["config"]。}

 @item{@cppi{cell_values} --- 线程的 thread cell 值（另见 @secref["config"]）。}

 @item{@cppi{next} --- 线程链表中的下一个线程；对于主线程，此值为 @cpp{NULL}。}

]

所有已调度的线程保存在一个链表中；@cppi{scheme_first_thread} 指向链表中的第一个线程。链表中的最后一个线程始终是主线程。

@; ----------------------------------------------------------------------

@section[#:tag "integration"]{与线程的集成}

Racket 的线程在两种情况下可能破坏外部 C 代码：

@itemize[

 @item{@italic{指向栈上值的指针可能在线程之间传递。} 例如，如果线程 A 将一个指向栈上变量的指针存储到全局变量中，当线程 B 使用该全局变量中的指针时，它可能指向当前不在栈上的数据。}

 @item{@italic{可以调用 Racket（也可以被 Racket 调用）的 C 函数依赖于严格的函数调用嵌套。} 例如，假设函数 F 使用一个内部栈，在入口时将项目压入栈中，在退出时弹出相同的项目。再假设 F 调用 Racket 来计算一个表达式。如果该表达式的计算在新线程中再次调用 F，但在完成第二个 F 之前返回到第一个线程，那么 F 的内部栈将被破坏。}

]

如果发生上述任一情况，Racket 可能会崩溃。


@; ----------------------------------------------------------------------

@section[#:tag "usefuel"]{允许线程切换}

执行大量或无限工作的 C 代码应偶尔调用 @cppi{SCHEME_USE_FUEL}——实际上是一个宏——它允许 Racket 换入另一个 Racket 线程来运行，并检查当前线程上的 break。特别地，如果启用了 break，@cpp{SCHEME_USE_FUEL} 可能触发一个异常。

该宏接受一个整数参数。在大多数平台上，线程调度基于定时器中断，此时该参数被忽略。但在某些平台上，该整数表示自上次调用 @cpp{SCHEME_USE_FUEL} 以来消耗的「燃料量」。例如，@racket[vector->list] 的实现为每个创建的 cons cell 消耗一个燃料单位：

@verbatim[#:indent 2]{
  Scheme_Object *scheme_vector_to_list(Scheme_Object *vec)
  {
    int i;
    Scheme_Object *pair = scheme_null;

    i = SCHEME_VEC_SIZE(vec);

    for (; i--; ) {
      SCHEME_USE_FUEL(1);
      pair = scheme_make_pair(SCHEME_VEC_ELS(vec)[i], pair);
    }

    return pair;
  }
}

@cpp{SCHEME_USE_FUEL} 宏展开为一个 C 代码块，而不是表达式。

@; ----------------------------------------------------------------------

@section[#:tag "threadblock"]{阻塞当前线程}

嵌入或扩展代码有时需要阻塞，但阻塞应当允许其他 Racket 线程执行。要允许其他线程运行，请用 @cppi{scheme_block_until} 阻塞。此过程接受两个函数：一个轮询函数用于测试阻塞操作是否可以完成，以及一个「准备睡眠」函数，当其决定在 @cpp{fd_set} 中设置位时使用（因为所有 Racket 线程都被阻塞了）。在 Windows 上，@cpp{fd_set} 还可以容纳 OS 级别信号量或其他句柄，通过 @cpp{scheme_add_fd_handle}。

由于传递给 @cppi{scheme_block_until} 的函数会被 Racket 线程调度器调用，它们永远不得抛出异常、调用 @cpp{scheme_apply} 或以任何方式触发 Racket 代码的执行。@cpp{scheme_block_until} 函数本身可能调用当前异常处理器，以响应 break（如果启用了 break）。

当阻塞操作与对象关联时，该对象可能对 @indexed-racket[sync] 参数有意义。要扩展 @racket[sync] 接受的对象集，要么用 @cppi{scheme_add_evt} 注册轮询和睡眠函数，要么用 @cppi{scheme_add_evt_through_sema} 注册信号量访问器。

@cppi{scheme_signal_received} 函数可用于唤醒 Racket，当它在睡眠时。特别是，调用 @cppi{scheme_signal_received} 确保 Racket 很快会轮询所有阻塞同步。此外，@cpp{scheme_signal_received} 可从任何 OS 级线程调用。因此，当无法用文件描述符或 Windows 句柄实现 @cpp{scheme_block_until} 的 prepare-to-sleep 函数时，当轮询结果发生变化时调用 @cpp{scheme_signal_received} 将确保发出轮询。

@; ----------------------------------------------------------------------

@section[#:tag "threadtime"]{嵌入式 Racket 中带有事件循环的线程}

当 Racket 被嵌入到基于事件模型的应用程序中时（即在主线程中的 Racket 代码执行由外部事件重复触发，直到应用程序退出），必须设置特殊钩子以确保非主线程正确执行。例如，在主线程执行过程中，可能会创建一个新线程；当主线程返回到事件循环时，新线程可能仍在运行，并且主线程可能要过任意长时间才能继续从事件循环执行。在这种情况下，嵌入程序必须明确允许 Racket 执行非主线程；这可以通过定期调用函数 @cppi{scheme_check_threads} 来完成。

仅当存在非主线程时（或有活动的回调触发器时），才需要进行线程检查。嵌入应用程序可以设置全局函数指针 @cppi{scheme_notify_multithread}，指向一个接受整数参数并返回 @cpp{void} 的函数。当线程检查变得必要时，此函数被调用且参数为 1；当线程检查不再必要时，此函数被调用且参数为 0。嵌入程序可使用此信息防止不必要的 @cpp{scheme_check_threads} 轮询。

下面的代码展示了 GRacket 过去如何使用 wxWindows 的 @cpp{wxTimer} 类来设置 @cpp{scheme_check_threads} 轮询。（任何常规的基于事件循环的回调都适用。）@cpp{scheme_notify_multithread} 指针被设置为 @cpp{MrEdInstallThreadTimer}。（GRacket 已不再以这种方式工作。）

@verbatim[#:indent 2]{
  class MrEdThreadTimer : public wxTimer
  {
   public:
    void Notify(void); /* timer 到期时的回调 */;
  };

  static int threads_go;
  static MrEdThreadTimer *theThreadTimer;
  #define THREAD_WAIT_TIME 40

  void MrEdThreadTimer::Notify()
  {
    if (threads_go)
      Start(THREAD_WAIT_TIME, TRUE);

    scheme_check_threads();
  }

  static void MrEdInstallThreadTimer(int on)
  {
    if (!theThreadTimer)
      theThreadTimer = new MrEdThreadTimer;

    if (on)
      theThreadTimer->Start(THREAD_WAIT_TIME, TRUE);
    else
      theThreadTimer->Stop();

    threads_go = on;
    if (on)
      do_this_time = 1;
  }
}

一种替代架构（也是 GRacket 现在使用的）是：让主线程进入一个循环，阻塞直到准备好处理某个事件。Racket 会自动运行所有线程，并且这样做是有效的，因为主线程阻塞在一个文件描述符上，如 @secref["threadblock"] 中所述。

@subsection[#:tag "blockednonmainel"]{被阻塞线程的回调}

Racket 线程有时会阻塞在文件描述符上，例如输入文件或 X 事件 socket。被阻塞的非主线程不会阻塞主线程，因此不影响事件循环，所以 @cppi{scheme_check_threads} 足以正确实现这种情况。然而，当应用程序没有其他事情发生时，以及在文件描述符上可以安装更低级别的轮询时，用 @cpp{scheme_check_threads} 轮询这些描述符是浪费的。如果设置了全局函数指针 @cppi{scheme_wakeup_on_input}，那么这种情况可以通过关闭线程检查并在阻塞文件描述符上通过 @cpp{scheme_wakeup_on_input} 发出「唤醒」请求来更高效地处理。

一个 @cpp{scheme_wakeup_on_input} 过程接受一个指向三个 @cpp{fd_set} 数组的指针（使用 @cpp{MZ_FD_SET} 代替 @cpp{FD_SET} 等），并返回 @cpp{void}。@cpp{scheme_wakeup_on_input} 函数不会立即睡眠；它只是在指定的文件描述符上设置回调。当这些文件描述符中有任何一个准备好输入时，回调被移除，并调用 @cpp{scheme_wake_up}。

例如，X Windows 版本的 GRacket 过去将 @cpp{scheme_wakeup_on_input} 设置为这个 @cpp{MrEdNeedWakeup}：

@verbatim[#:indent 2]{
  static XtInputId *scheme_cb_ids = NULL;
  static int num_cbs;

  static void MrEdNeedWakeup(void *fds)
  {
    int limit, count, i, p;
    fd_set *rd, *wr, *ex;

    rd = (fd_set *)fds;
    wr = ((fd_set *)fds) + 1;
    ex = ((fd_set *)fds) + 2;

    limit = getdtablesize();

    /* 检查是否真的需要做工作 */
    count = 0;
    for (i = 0; i < limit; i++) {
      if (MZ_FD_ISSET(i, rd))
        count++;
      if (MZ_FD_ISSET(i, wr))
        count++;
      if (MZ_FD_ISSET(i, ex))
        count++;
    }

    if (!count)
      return;

    /* 移除旧回调 */
    if (scheme_cb_ids)
      for (i = 0; i < num_cbs; i++)
        notify_set_input_func((Notify_client)NULL, (Notify_func)NULL,
                              scheme_cb_ids[i]);

    num_cbs = count;
    scheme_cb_ids = new int[num_cbs];

    /* 安装回调 */
    p = 0;
    for (i = 0; i < limit; i++) {
      if (MZ_FD_ISSET(i, rd))
        scheme_cb_ids[p++] = XtAppAddInput(wxAPP_CONTEXT, i,
                                           (XtPointer *)XtInputReadMask,
                                           (XtInputCallbackProc)MrEdWakeUp, NULL);
      if (MZ_FD_ISSET(i, wr))
        scheme_cb_ids[p++] = XtAppAddInput(wxAPP_CONTEXT, i,
                                           (XtPointer *)XtInputWriteMask,
                                           (XtInputCallbackProc)MrEdWakeUp, NULL);
      if (MZ_FD_ISSET(i, ex))
        scheme_cb_ids[p++] = XtAppAddInput(wxAPP_CONTEXT, i,
                                           (XtPointer *)XtInputExceptMask,
                                           (XtInputCallbackProc)MrEdWakeUp,
                                           NULL);
    }
    }

    /* 当检测到输入/异常时的回调函数 */
    Bool MrEdWakeUp(XtPointer, int *, XtInputId *)
    {
    int i;

    if (scheme_cb_ids) {
      /* 移除所有回调 */
      for (i = 0; i < num_cbs; i++)
       XtRemoveInput(scheme_cb_ids[i]);

      scheme_cb_ids = NULL;

      /* 唤醒 */
      scheme_wake_up();
    }

    return FALSE;
    }
}

@; ----------------------------------------------------------------------

@section[#:tag "sleeping"]{嵌入式 Racket 的睡眠}

当所有 Racket 线程都被阻塞时，Racket 必须在若干秒内或直到某些文件描述符上出现外部输入时「睡眠」。通常，睡眠应该阻塞整个应用程序的主事件循环。然而，执行睡眠的方式可能因嵌入应用程序而异。嵌入应用程序可以设置全局函数指针 @cppi{scheme_sleep} 来实现阻塞睡眠，虽然 Racket 默认实现了此函数。

一个 @cpp{scheme_sleep} 函数接受两个参数：一个 @cpp{float} 和一个 @cpp{void*}。后者实际上指向一个包含三个 @cpp{fd_set} 记录的数组（一个用于读，一个用于写，一个用于异常）；这些记录在下面进一步描述。如果 @cpp{float} 参数非零，则 @cpp{scheme_sleep} 函数最多阻塞指定秒数。@cpp{scheme_sleep} 函数应阻塞直到 @cpp{fd_set} 中指定的文件描述符上有输入，如果 @cpp{float} 参数为零，则无限期阻塞。

传递给 @cpp{scheme_sleep} 的第二个参数在概念上是三个 @cpp{fd_set} 记录的数组，但总是使用 @cpp{scheme_get_fdset} 获取除第零个元素之外的任何元素，并使用 @cpp{MZ_FD_SET}、@cpp{MZ_FD_CLR} 等（而非 @cpp{FD_SET}、@cpp{FD_CLR} 等）来操作每个 @cpp{fd_set}。

以下函数 @cpp{mzsleep} 是适用于大多数 Unix 或 Windows 应用程序的一个合适的 @cpp{scheme_sleep} 函数。（这是 Racket 内置的睡眠函数的近似实现。）

@verbatim[#:indent 2]{
  void mzsleep(float v, void *fds)
  {
    if (v) {
      sleep(v);
    } else {
      int limit;
      fd_set *rd, *wr, *ex;

  # ifdef WIN32
      limit = 0;
  # else
      limit = getdtablesize();
  # endif

      rd = (fd_set *)fds;
      wr = (fd_set *)scheme_get_fdset(fds, 1);
      ex = (fd_set *)scheme_get_fdset(fds, 2);

      select(limit, rd, wr, ex, NULL);
    }
  }
}


@; ----------------------------------------------------------------------

@section{Thread Functions}

@function[(Scheme_Thread* scheme_get_current_thread)]{

Returns the currently executing thread. The result is equivalent to
@cppi{scheme_current_thread}, but the function form must be used in
some embedding contexts.}

@function[(Scheme_Object* scheme_thread
           [Scheme_Object* thunk])]{

Creates a new thread, just like @racket[thread].}

@function[(Scheme_Object* scheme_thread_w_details
           [Scheme_Object* thunk]
           [Scheme_Config* config]
           [Scheme_Thread_Cell_Table* cells]
           [Scheme_Custodian* cust]
           [int suspend_to_kill])]{

Like @cpp{scheme_thread}, except that the created thread belongs to
@var{cust} instead of the current custodian, it uses the given
@var{config} for its initial configuration, it uses @var{cells} for
its thread-cell table, and if @var{suspend_to_kill} is non-zero, then
the thread is merely suspended when it would otherwise be killed
(through either @racket[kill-thread] or
@racket[custodian-shutdown-all]).

The @var{config} argument is typically obtained through
@cpp{scheme_current_config} or @cpp{scheme_extend_config}. A
@var{config} is immutable, so different threads can safely use the
same value. The @var{cells} argument should be obtained from
@cpp{scheme_inherit_cells}; it is mutable, and a particular cell table
should be used by only one thread.}

@function[(Scheme_Object* scheme_make_sema
           [intptr_t v])]{

Creates a new semaphore.}

@function[(void scheme_post_sema
           [Scheme_Object* sema])]{

Posts to @var{sema}.}

@function[(int scheme_wait_sema
           [Scheme_Object* sema]
           [int try])]{

Waits on @var{sema}. If @var{try} is not 0, the wait can fail and 0 is
returned for failure, otherwise 1 is returned.}

@function[(void scheme_thread_block
           [float sleep_time])]{

Allows the current thread to be swapped out in favor of other
threads. If @var{sleep_time} positive, then the current thread will
sleep for at least @var{sleep_time} seconds.

After calling this function, a program should almost always call
@cppi{scheme_making_progress} next. The exception is when
@cpp{scheme_thread_block} is called in a polling loop that performs no
work that affects the progress of other threads. In that case,
@cpp{scheme_making_progress} should be called immediately after
exiting the loop.

See also @cpp{scheme_block_until}, and see also the
@cpp{SCHEME_USE_FUEL} macro in @secref["usefuel"].}

@function[(void scheme_thread_block_enable_break
           [float sleep_time]
           [int break_on])]{

Like @cpp{scheme_thread_block}, but breaks are enabled while blocking if
 @var{break_on} is true.}

@function[(void scheme_swap_thread
           [Scheme_Thread* thread])]{

Swaps out the current thread in favor of @var{thread}.}

@function[(void scheme_break_thread
           [Scheme_Thread* thread])]{

Sends a break signal to the given thread.}

@function[(int scheme_break_waiting
           [Scheme_Thread* thread])]{

Returns @cpp{1} if a break from @racket[break-thread] or @cpp{scheme_break_thread}
 has occurred in the specified thread but has not yet been handled.}

@function[(int scheme_block_until
           [Scheme_Ready_Fun f]
           [Scheme_Needs_Wakeup_Fun fdf]
           [Scheme_Object* data]
           [float sleep])]{

@class{Scheme_Ready_Fun} 和 @cpp{Scheme_Needs_Wakeup_Fun} 类型定义如下：

@verbatim[#:indent 2]{
   typedef int (*Scheme_Ready_Fun)(Scheme_Object *data);
   typedef void (*Scheme_Needs_Wakeup_Fun)(Scheme_Object *data,
                                           void *fds);
}

阻塞当前线程，直到 @var{f} 与 @var{data} 返回真值。@var{f} 函数会被定期调用——至少每次潜在换入被阻塞的线程时调用一次——即使在它返回真值之后也可能被多次调用。如果 @var{f} 与 @var{data} 曾返回真值，则它必须在 @cpp{scheme_block_until} 返回之前继续返回真值。传递给 @var{f} 的参数与传递给 @cpp{scheme_block_until} 的 @var{data} 参数相同，否则 @var{data} 会被忽略。（实际上 @var{data} 参数不一定是 @cpp{Scheme_Object*} 值，因为它仅由 @var{f} 和 @var{fdf} 使用。）

如果 Racket 决定睡眠，则调用 @var{fdf} 函数在 @var{fds} 中设置位，该参数在概念上是一个包含三个 @cpp{fd_set} 的数组：一个用于读，一个用于写，一个用于异常。使用 @cpp{scheme_get_fdset} 获取此数组的元素，使用 @cpp{MZ_FD_SET}（而非 @cpp{FD_SET} 等）操作 @cpp{fd_set}。在 Windows 上，@cpp{fd_set} 还可通过 @cpp{scheme_add_fd_handle} 容纳 OS 级信号量或其他句柄。

@var{fdf} 参数可以为 @cpp{NULL}，这意味着线程仅在通过 Racket 操作变为非阻塞（即 @var{ready} 将结果更改为真值），而绝不能通过外部进程（例如，通过 socket 或 OS 级信号量）——除了可能调用 @cpp{scheme_signal_received} 来表示外部变化。

如果 @var{sleep} 是正数，则 @cpp{scheme_block_until} 至少每隔 @var{sleep} 秒轮询一次 @var{f}，但直到 @var{f} 返回真值时 @cpp{scheme_block_until} 才返回。如果 @var{f} 返回真值，则调用 @cpp{scheme_block_until} 可能比 @var{sleep} 秒更短。

@cpp{scheme_block_until} 的返回值是其最近一次调用 @var{f} 的返回值，这使得 @var{f} 可以向 @cpp{scheme_block_until} 的调用者返回一些信息。

关于 @var{f} 和 @var{fdf} 函数限制的信息，请参见 @secref["threadblock"]。}

@function[(int scheme_block_until_enable_break
           [Scheme_Ready_Fun f]
           [Scheme_Needs_Wakeup_Fun fdf]
           [Scheme_Object* data]
           [float sleep]
           [int break_on])]{

与 @cpp{scheme_block_until} 类似，但在阻塞时启用 break，当 @var{break_on} 为真。}

@function[(int scheme_block_until_unless
           [Scheme_Ready_Fun f]
           [Scheme_Needs_Wakeup_Fun fdf]
           [Scheme_Object* data]
           [float sleep]
           [Scheme_Object* unless_evt]
           [int break_on])]{

与 @cpp{scheme_block_until_enable_break} 类似，但如果 @var{unless_evt} 准备就绪，函数则返回，其中 @var{unless_evt} 是一个端口进度事件，由 @cpp{scheme_progress_evt_via_get} 实现。更多信息请参见 @cpp{scheme_make_input_port}。}

@function[(void scheme_signal_received)]{
表示外部事件可能导致同步轮询的结果不同。与其他大多数 Racket 函数不同，此函数可从任何 OS 级线程调用，并在 Racket 线程睡眠时唤醒它。}

@function[(void scheme_check_threads)]{
此函数由嵌入程序定期调用，以给后台进程执行时间。更多信息请参见 @secref["threadtime"]。
只要有些线程准备好，此函数至少在一个线程时间片后才返回。}

@function[(void scheme_wake_up)]{
当外部文件描述符上有输入时，嵌入程序调用此函数。更多信息请参见 @secref["sleeping"]。}

@function[(void* scheme_get_fdset
           [void* fds]
           [int pos])]{
从传递给 @cpp{scheme_sleep}、@cpp{scheme_block_until} 的回调或 @cpp{scheme_make_input_port} 的输入端口回调中提取 @cpp{fd_set}。}

@function[(void scheme_add_fd_handle
           [void* h]
           [void* fds]
           [int repost])]{
将 OS 级信号量（Windows）或其他可等待句柄（Windows）添加到 @cpp{fd_set} @var{fds}。当 Racket 执行 @cpp{select} 以在 @var{fds} 上睡眠时，也会等待给定的信号量或句柄。此功能使 Racket 能够睡眠直到被外部进程唤醒。

Racket 不会尝试释放给定的信号量或句柄，并且使用 @var{fds} 的 @cpp{select} 调用可能由于 @var{fds} 中的其他文件描述符或句柄而解除阻塞。如果 @var{repost} 为真值，则 @var{h} 必须是 OS 级信号量，并且如果 @cpp{select} 因 @var{h} 上的 post 而解除阻塞，@var{h} 会被重新 post；这允许客户端将安装在 @var{fds} 上的信号量统一处理，无论该信号量的 post 是否被 @cpp{select} 消费。

@cpp{scheme_add_fd_handle} 函数对实现传递给 @cpp{scheme_wait_until} 的第二个过程，或实现自定义输入端口非常有用。

在 Unix 和 Mac OS 上，此函数无效。}

@function[(void scheme_add_fd_eventmask
           [void* fds]
           [int mask])]{
将 OS 级事件类型（Windows）添加到 @cpp{fd_set} @var{fds} 中的类型集合。当 Racket 执行 @cpp{select} 以在 @var{fds} 上睡眠时，也会等待指定类型的事件。此功能使 Racket 能够睡眠直到被外部进程唤醒。

事件掩码仅在某个句柄通过 @cpp{scheme_add_fd_handle} 安装时使用。这个笨拙的限制可能迫使你创建一个从不 post 的虚拟信号量。
在 Unix 和 Mac OS 上，此函数无效。}

@function[(void scheme_add_evt
           [Scheme_Type type]
           [Scheme_Ready_Fun ready]
           [Scheme_Needs_Wakeup_Fun wakeup]
           [Scheme_Wait_Filter_Fun filter]
           [int can_redirect])]{
参数类型定义如下：

@verbatim[#:indent 2]{
   typedef int (*Scheme_Ready_Fun)(Scheme_Object *data);
   typedef void (*Scheme_Needs_Wakeup_Fun)(Scheme_Object *data,
                                           void *fds);
   typedef int (*Scheme_Wait_Filter_Fun)(Scheme_Object *data);
}

将 @racket[sync] 的可等待对象集合扩展到具有类型标记 @var{type} 的对象。如果 @var{filter} 不为 @cpp{NULL}，则它将新的可等待集合限制为那些 @var{filter} 返回非零值的对象。

@var{ready} 和 @var{wakeup} 函数的使用方式与传递给 @cpp{scheme_block_until} 的参数相同。

@var{can_redirect} 参数应为 @cpp{0}。}

@function[(void scheme_add_evt_through_sema
           [Scheme_Type type]
           [Scheme_Wait_Sema_Fun getsema]
           [Scheme_Wait_Filter_Fun filter])]{
与 @cpp{scheme_add_evt} 类似，但用于等待基于信号量的对象。不使用 @var{ready} 和 @var{wakeup} 函数，@var{getsema} 函数为给定对象提取信号量：

@verbatim[#:indent 2]{
   typedef
   Scheme_Object *(*Scheme_Wait_Sema_Fun)(Scheme_Object *data,
                                          int *repost);
}

如果成功等待应将信号量保持在等待状态，则 @var{getsema} 应将 @var{*repost} 设置为 @cpp{0}。否则，给定的信号量将在成功等待后重新 post。@var{getsema} 函数几乎总是应将 @var{*repost} 设置为 @cpp{1}。}

@function[(void scheme_making_progress)]{
通知调度器当前线程不只是在循环中调用 @cppi{scheme_thread_block}，而是在实际取得进展。}

@function[(int scheme_tls_allocate)]{
分配一个用于 @cpp{scheme_tls_set} 和 @cpp{scheme_tls_get} 的线程本地存储索引。}

@function[(void scheme_tls_set
           [int index]
           [void* v]){
使用通过 @cpp{scheme_tls_allocate} 分配的索引存储线程特定值。}

@function[(void* scheme_tls_get
           [int index])]{
检索通过 @cpp{scheme_tls_set} 安装的线程特定值。如果给定索引没有可用的线程特定值，则返回 @cpp{NULL}。}

@function[(Scheme_Object* scheme_call_enable_break
           [Scheme_Prim* prim]
           [int argc]
           [Scheme_Object** argv])]{
使用给定的 @var{argc} 和 @var{argv} 调用 @var{prim}，启用 break。@var{prim} 函数可以阻塞，在这种情况下可能被 break 中断。@var{prim} 函数在其成功后不应阻塞、yield 或检查 break，其中「成功」取决于操作。例如，@racket[tcp-accept/enable-break] 通过将此函数包裹在 @racket[tcp-accept] 的实现周围来实现；@racket[tcp-accept] 实现在其接受连接后不会阻塞或 yield。}

@function[(Scheme_Object* scheme_make_thread_cell
           [Scheme_Object* def_val]
           [int preserved]
           [Scheme_Object* cell]
           [Scheme_Thread_Cell_Table* cells]
           [Scheme_Object* cell]
           [Scheme_Thread_Cell_Table* cells]
           [Scheme_Object* v])]{
防止 Racket 线程交换，直到调用 @cpp{scheme_end_atomic} 或 @cpp{scheme_end_atomic_no_swap}。start-atomic 和 end-atomic 对可以嵌套。}

@function[(void scheme_end_atomic)]{
结束与 Racket 线程相关的原子区域。当前线程可能立即被交换出去（即，@cpp{scheme_end_atomic} 的调用被认为是线程交换的安全点）。}

@function[(void scheme_end_atomic_no_swap)]{
结束与 Racket 线程相关的原子区域，并也防止立即线程交换。（换句话说，直到未来的安全点之前，不会发生 Racket 线程交换。）}

@function[(void scheme_add_swap_callback
                [Scheme_Closure_Func f]
                [Scheme_Object* data])]{
注册一个回调，刚好在 Racket 线程被换入之后调用。当调用 @var{f} 时，@var{data} 会被提供回给 @var{f}，其中 @cpp{Closure_Func} 定义如下：

@verbatim[#:indent 2]{
  typedef Scheme_Object *(*Scheme_Closure_Func)(Scheme_Object *);
}}

@function[(void scheme_add_swap_out_callback
                [Scheme_Closure_Func f]
                [Scheme_Object* data])]{
与 @cpp{scheme_add_swap_callback} 类似，但注册一个回调，刚好在 Racket 线程被换出之前调用。}
