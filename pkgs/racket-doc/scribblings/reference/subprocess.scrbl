#lang scribble/doc
@(require "mz.rkt" (for-label racket/system))

@(define microsoft-argument-doc-src
  @hyperlink["https://github.com/MicrosoftDocs/cpp-docs/blob/e5bdbb71e7b09a58e70ca8758caec68bb9a6cc9c/docs/c-language/parsing-c-command-line-arguments.md"
             "Microsoft's documentation source"])

@title[#:tag "subprocess"]{Processes}

@defproc*[([(subprocess [stdout (or/c (and/c output-port? file-stream-port?) #f)]
                        [stdin (or/c (and/c input-port? file-stream-port?) #f)]
                        [stderr (or/c (and/c output-port? file-stream-port?) #f 'stdout)]
                        [group (or/c #f 'new subprocess) (and (subprocess-group-enabled) 'new)]
                        [command path-string?]
                        [arg (or/c path? string-no-nuls? bytes-no-nuls?)] ...)
            (values subprocess?
                    (or/c (and/c input-port? file-stream-port?) #f)
                    (or/c (and/c output-port? file-stream-port?) #f)
                    (or/c (and/c input-port? file-stream-port?) #f))]
           [(subprocess [stdout (or/c (and/c output-port? file-stream-port?) #f)]
                        [stdin (or/c (and/c input-port? file-stream-port?) #f)]
                        [stderr (or/c (and/c output-port? file-stream-port?) #f)]
                        [group (or/c #f 'new subprocess) (and (subprocess-group-enabled) 'new)]
                        [command path-string?]
                        [exact 'exact]
                        [arg string?])
            (values subprocess?
                    (or/c (and/c input-port? file-stream-port?) #f)
                    (or/c (and/c output-port? file-stream-port?) #f)
                    (or/c (and/c input-port? file-stream-port?) #f))])]{

在底层操作系统中创建一个新进程以异步执行 @racket[command], 为新进程提供环境变量 @racket[current-environment-variables]. 另请参见 @racketmodname[racket/system] 中的 @racket[system] 和 @racket[process]。

@margin-note{在 Unix 和 Mac OS 上，子进程创建与 @racket[command] 所指示程序的启动是分开的。
特别是，如果 @racket[command] 引用了不存在或不可执行的文件，
错误会报告（通过标准错误和非 0 退出码）在子进程中，而不是在创建
进程中。}

@racket[command] 参数是程序可执行文件的路径，@racket[arg]s 是程序的命令行参数。 请参阅 @racket[find-executable-path]，了解如何基于 @envvar{PATH} 环境变量定位可执行文件。 在
Unix 和 Mac OS 上，命令行参数作为 byte string 传递，
string @racket[arg]s 使用当前 locale 的编码进行转换
（参见 @secref["encodings"]）。 在 Windows 上，命令行参数作为 string 传递，byte string 使用 UTF-8 进行转换。

在 Windows 上，进程在本地接收单个命令行参数字符串，
不像 Unix 和 Mac OS 进程那样在本地接收参数数组。 Windows 命令行字符串按照 Windows 约定从 @racket[command] 和 @racket[arg]s 构建，
使得典型应用程序可以将其解析回参数数组，
@margin-note*{For information on the Windows command-line conventions,
see @microsoft-argument-doc-src or search for ``command line parsing'' at
@tt{http://msdn.microsoft.com/}.} 但请注意，应用程序可能以不同的方式解析命令行。 特别是，@emph{提供引用 @filepath{.bat} 或 @filepath{.cmd} 文件的 @racket[command] 时要格外小心}，
因为传递给进程的命令行字符串将被解析为 @exec{cmd.exe} 的
命令, which is effectively a different syntax than the convention
that @racket[subprocess] uses to encode command-line arguments;
提供未经清理的 @racket[arg]s 可能会导致将参数解析为命令。 为了对所传递的命令行字符串有更多控制，可以使用 @indexed-racket['exact] 替换第一个 @racket[arg], which triggers a Windows-specific behavior:
唯一的 @racket[arg] 将直接作为子进程的命令行使用。 如果在非 Windows 平台上提供 @racket['exact]，则 @exnraise[exn:fail:contract]。

当作为 port 提供时，@racket[stdout] 用作启动进程的标准输出，
@racket[stdin] 用作进程的标准输入，@racket[stderr] 用作进程的标准错误。  所有提供的 port 必须是 file-stream port。 其中任一 port 都可以是 @racket[#f]，在这种情况下，系统管道被创建并由 @racket[subprocess] 返回。 The @racket[stderr] argument can be 
@racket['stdout], in which case the same file-stream port or system pipe
that is supplied as standard output is also used for standard error.
For each port or @racket['stdout] that is provided, no
pipe is created and the corresponding returned value is @racket[#f].
If @racket[stdout] or @racket[stderr] is a port for which
@racket[port-waiting-peer?] returns true, then @racket[subprocess]
waits for the port to become ready for writing before proceeding with
the subprocess creation.

If @racket[group] is @racket['new], then the new process is created as
a new OS-level process group. In that case, @racket[subprocess-kill]
attempts to terminate all processes within the group, which may
include additional processes created by the subprocess.
@margin-note*{Beware that creating a group may interfere with the job
control in an interactive shell, since job control is based on process
groups.} See @racket[subprocess-kill] for details. If @racket[group]
is a subprocess, then that subprocess must have been created with
@racket['new], and the new subprocess will be added to the group;
adding to the group will succeed only on Unix and Mac OS, and only in
the same cases that @racket[subprocess-kill] would have an effect
(i.e., the subprocess is not known to have terminated), otherwise it
will fail silently.

@racket[subprocess] 过程返回四个值：

@itemize[

 @item{a @deftech{subprocess} value representing the created process;}

 @item{an input port piped from the process's standard output, or
 @racket[#f] if @racket[stdout] was a port;}

 @item{an output port piped to the process's standard input, or
 @racket[#f] if @racket[stdin] was a port;}

 @item{an input port piped from the process's standard error, or
 @racket[#f] if @racket[stderr] was a port or @racket['stdout].}

]

@bold{Important:} All ports returned from @racket[subprocess] must be
explicitly closed, usually with @racket[close-input-port] or
@racket[close-output-port].

@margin-note{用于与子进程通信的 @tech{file-stream port} 通常是容量有限的管道。
注意避免因对子进程写入序列化后接着读而创建死锁，
而子进程做同样的操作，导致两个进程都因另一端必须首先读取以在管道中腾出空间
而阻塞在写入上。还要注意等待子进程完成而不读取其输出，
因为子进程可能因试图写入已满的管道而被阻塞。}

返回的 port 是 @tech{file-stream ports}（参见
@secref["file-ports"]），它们被纳入当前 custodian 的管理中（参见 @secref["custodians"]）。  The
@exnraise[exn:fail] when a low-level error prevents the spawning of a
process or the creation of operating system pipes for process
communication.

@racket[current-subprocess-custodian-mode] 参数确定子进程本身
是否注册到当前 @tech{custodian} 上，以便 custodian 关闭时调用
@racket[subprocess-kill] 终止子进程。

The @racket[current-subprocess-keep-file-descriptors] parameter
determines how file descriptors and handles in the current process are
shared with the subprocess. File descriptors (on Unix and Mac OS) or
handles (on Windows) represented by @racket[stdin], @racket[stdout],
and @racket[stderr] are always shared with the subprocess. File
descriptors and handles that are replaced by newly created pipes (when
the corresponding @racket[stdin], @racket[stdout], and @racket[stderr]
argument is @racket[#f]) are not shared. Sharing for other file
descriptors and handles depends on the parameter value:
@;
@itemlist[

 @item{@racket['inherited] (the default) --- other handles that are
   inherited on Windows are shared with the subprocess; file
   descriptors that lack the @tt{FD_CLOEXEC} flag on Unix and Mac OS
   variants that support the flag are also shared; and no other file
   descriptors are shared on variants of Unix and Mac OS that do not
   support @tt{FD_CLOEXEC}.}

 @item{@racket['all] --- like @racket['inherited], except on
   variants of Unix and Mac OS that do not support @tt{FD_CLOEXEC}, in
   which case all file descriptors are shared.}

 @item{@racket['()] --- no additional file descriptors are shared, not
   even ones that are inherited on Windows or lacking the
   @tt{FD_CLOEXEC} flag.}

]

A subprocess can be used as a @tech{synchronizable event} (see @secref["sync"]).
子进程值的 @tech{ready for synchronization}（准备同步）时机
是当 @racket[subprocess-wait] 不会阻塞时；@resultItself{subprocess value}。

Example:

@racketblock[
(define-values (sp out in err)
  (subprocess #f #f #f "/bin/ls" "-l"))
(printf "stdout:\n~a" (port->string out))
(printf "stderr:\n~a" (port->string err))
(close-input-port out)
(close-output-port in)
(close-input-port err)
(subprocess-wait sp)
]

@history[#:changed "6.11.0.1" @elem{Added the @racket[group] argument.}
         #:changed "7.4.0.5" @elem{Added waiting for a fifo without a reader
                                   as @racket[stdout] and/or @racket[stderr].}
         #:changed "8.3.0.4" @elem{Added @racket[current-subprocess-custodian-mode] support.}
         #:changed "8.11.1.6" @elem{Changed the treatment of file-descriptor sharing
                                    on variants of Unix and Mac OS that support
                                    @tt{FD_CLOEXEC}.}]}


@defproc[(subprocess-wait [subproc subprocess?]) void?]{

Blocks until the process represented by @racket[subproc]
terminates. The @racket[subproc] value also can be used with
@racket[sync] and @racket[sync/timeout].}


@defproc[(subprocess-status [subproc subprocess?]) 
         (or/c 'running
               exact-nonnegative-integer?)]{

如果 @racket[subproc] 表示的进程仍在运行，返回 @indexed-racket['running]，
否则返回其退出码。 退出码是精确整数，@racket[0] 通常表示成功。
如果进程因故障或信号而终止，退出码为非零。}


@defproc[(subprocess-kill [subproc subprocess?] [force? any/c]) void?]{

Terminates the subprocess represented by @racket[subproc]. 具体操作取决于 @racket[force?] 是否为真、该进程是否在其自己的进程组中创建
（通过将 @racket[subprocess-group-enabled] 参数设置为真值）以及当前平台：

@itemlist[

 @item{@racket[force?] is true, not a group, all platforms: Terminates
       the process if the process still running.}

 @item{@racket[force?] is false, not a group, on Unix or Mac OS:
       Sends the process an interrupt signal instead of a kill
       signal.}

 @item{@racket[force?] is false, not a group, on Windows: No action
       is taken.}

 @item{@racket[force?] is true, a group, on Unix or Mac OS:
       Terminates all processes in the group, but only if
       @racket[subprocess-status] has never produced a
       non-@racket['running] result for the subprocess and only if
       functions like @racket[subprocess-wait] and @racket[sync] have
       not detected the subprocess's completion. Otherwise, no action
       is taken (because the immediate process is known to have
       terminated while the continued existence of the group is
       unknown).}

 @item{@racket[force?] is true, a group, on Windows: Terminates
       the process if the process still running.}

 @item{@racket[force?] is false, a group, on Unix or Mac OS: The
       same as when @racket[force?] is @racket[#t], but when the group
       is sent a signal, it is an interrupt signal instead of a kill
       signal.}

 @item{@racket[force?] is false, a group, on Windows: All processes
       in the group receive a CTRL-BREAK signal (independent of
       whether the immediate subprocess has terminated).}

]

If an error occurs during termination, the @exnraise[exn:fail].}


@defproc[(subprocess-pid [subproc subprocess?]) exact-nonnegative-integer?]{

返回 @racket[subproc] 表示的进程的操作系统数字 ID（如果有）。 The result is valid only as long as
the process is running.}


@defproc[(subprocess? [v any/c]) boolean?]{

如果 @racket[v] 是子进程值，则返回 @racket[#t]，否则返回 @racket[#f]。}


@defparam[current-subprocess-custodian-mode mode (or/c #f 'kill 'interrupt)]{

A @tech{parameter} that determines whether a subprocess (as created by
@racket[subprocess] or wrappers like @racket[process]) is registered
with the current @tech{custodian}. If the parameter value is
@racket[#f], then the subprocess is not registered with the
custodian---although any created ports are registered. If the
parameter value is @racket['kill] or @racket['interrupt], then the
subprocess is shut down through @racket[subprocess-kill], where
@racket['kill] supplies a @racket[#t] value for the @racket[_force?]
argument and @racket['interrupt] supplies a @racket[#f] value. The
shutdown may occur either before or after ports created for the
subprocess are closed.

Custodian-triggered shutdown is limited by details of process handling
in the host system. For example, @racket[process] and @racket[system]
may create an intermediate shell process to run a program, in which
case custodian-based termination shuts down the shell process and
probably not the process started by the shell. See also
@racket[subprocess-kill]. Process groups (see
@racket[subprocess-group-enabled]) can address some limitations, but
not all of them.}


@defboolparam[subprocess-group-enabled on?]{

A @tech{parameter} that determines whether a subprocess is created as
a new process group by default. See @racket[subprocess] and
@racket[subprocess-kill] for more information.}


@defparam[current-subprocess-keep-file-descriptors keeps (or/c 'inherited 'all '())]{

A @tech{parameter} that determines how file descriptors (on Unix and
Mac OS) and handles (on Windows) are shared in a subprocess as created
by @racket[subprocess] or wrappers like @racket[process]. See
@racket[subprocess] for more information.

@history[#:added "8.3.0.4"]}


@defproc[(shell-execute [verb (or/c string? #f)]
                        [target string?]
                        [parameters string?]
                        [dir path-string?]
                        [show-mode symbol?])
         #f]{

@index['("ShellExecute")]{Performs} the action specified by @racket[verb]
on @racket[target] in Windows. For platforms other than Windows, the
@exnraise[exn:fail:unsupported].

For example,

@racketblock[
(shell-execute #f "http://racket-lang.org" ""
               (current-directory) 'sw_shownormal)
]

Opens the Racket home page in a browser window.

The @racket[verb] can be @racket[#f], in which case the operating
system will use a default verb. Common verbs include @racket["open"],
@racket["edit"], @racket["find"], @racket["explore"], and
@racket["print"].

The @racket[target] is the target for the action, usually a filename
path. The file could be executable, or it could be a file with a
recognized extension that can be handled by an installed application.

The @racket[parameters] argument is passed on to the system to perform
the action. For example, in the case of opening an executable, the
@racket[parameters] is used as the command line (after the executable
name).

The @racket[dir] is used as the current directory when performing the
action.

The @racket[show-mode] sets the display mode for a Window affected by
the action. It must be one of the following symbols; the description
of each symbol's meaning is taken from the Windows API documentation.

@itemize[

 @item{@indexed-racket['sw_hide] or @indexed-racket['SW_HIDE] ---
 Hides the window and activates another window.}

 @item{@indexed-racket['sw_maximize] or @indexed-racket['SW_MAXIMIZE]
 --- Maximizes the window.}

 @item{@indexed-racket['sw_minimize] or @indexed-racket['SW_MINIMIZE]
 --- Minimizes the window and activates the next top-level window in
 the z-order.}

 @item{@indexed-racket['sw_restore] or @indexed-racket['SW_RESTORE]
 --- Activates and displays the window. If the window is minimized or
 maximized, Windows restores it to its original size and position.}

 @item{@indexed-racket['sw_show] or @indexed-racket['SW_SHOW] ---
 Activates the window and displays it in its current size and
 position.}

 @item{@indexed-racket['sw_showdefault] or
 @indexed-racket['SW_SHOWDEFAULT] --- Uses a default.}

 @item{@indexed-racket['sw_showmaximized] or
 @indexed-racket['SW_SHOWMAXIMIZED] --- Activates the window and
 displays it as a maximized window.}

 @item{@indexed-racket['sw_showminimized] or
 @indexed-racket['SW_SHOWMINIMIZED] --- Activates the window and
 displays it as a minimized window.}

 @item{@indexed-racket['sw_showminnoactive] or
 @indexed-racket['SW_SHOWMINNOACTIVE] --- Displays the window as a
 minimized window. The active window remains active.}

 @item{@indexed-racket['sw_showna] or @indexed-racket['SW_SHOWNA] ---
 Displays the window in its current state. The active window remains
 active.}

 @item{@indexed-racket['sw_shownoactivate] or
 @indexed-racket['SW_SHOWNOACTIVATE] --- Displays a window in its most
 recent size and position. The active window remains active.}

 @item{@indexed-racket['sw_shownormal] or
 @indexed-racket['SW_SHOWNORMAL] --- Activates and displays a
 window. If the window is minimized or maximized, Windows restores it
 to its original size and position.}

 ]

If the action fails, the @exnraise[exn:fail]. If the action succeeds,
the result is @racket[#f].

In future versions of Racket, the result may be a subprocess value if
the operating system did returns a process handle (but if a subprocess
value is returned, its process ID will be @racket[0] instead of the
real process ID).}

@; ----------------------------------------------------------------------

@section{Simple Subprocesses}

@note-lib[racket/system]

@defproc[(system [command (or/c string-no-nuls? bytes-no-nuls?)]
                 [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
         boolean?]{

同步执行 shell 命令（即，对 @racket[system] 的调用直到子进程结束后才返回）。 在 Unix 和 Mac OS 上，@exec{/bin/sh} 用作 shell，
而在 Windows 上则使用 @exec{cmd.exe} 或 @exec{command.com} （如果找不到 @exec{cmd.exe}）。 @racket[command] 参数是一个不含 nul 字符的 string 或 byte string。
如果命令成功，返回值为 @racket[#t]，否则为 @racket[#f]。

@margin-note{See also @racket[subprocess] for notes about error
handling and the limited buffer capacity of subprocess pipes.}

如果 @racket[set-pwd?] 为真，则 @envvar{PWD} 环境变量将设置为
启动 shell 进程时 @racket[(current-directory)] 的值。

另请参见 @racket[current-subprocess-custodian-mode] 和
@racket[subprocess-group-enabled]，它们影响用于实现 @racket[system] 的子进程。

生成的进程写入 @racket[(current-output-port)]，
从 @racket[(current-input-port)] 读取，并将错误记录到 @racket[(current-error-port)]。 例如，要将进程的非错误输出收集为 string，请使用 @racket[with-output-to-string]，
它在调用给定函数时配置 @racket[current-output-port]：

@racketblock[
(with-output-to-string (lambda () (system "date")))
]}


@defproc*[([(system* [command path-string?]
                     [arg (or/c path? string-no-nuls? bytes-no-nuls?)] ...
                     [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
            boolean?]
           [(system* [command path-string?] [exact 'exact] [arg string?]
                     [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
            boolean?])]{

Like @racket[system], except that @racket[command] is a filename that
is executed directly (instead of through a shell command; see
@racket[find-executable-path] for locating an executable based on
the @envvar{PATH} environment variable), and the
@racket[arg]s are the arguments. The executed file is passed the
specified string arguments (which must contain no nul
characters).

On Windows, the first argument after @racket[command] can be
@racket['exact], and the final @racket[arg] is a complete command
line. See @racket[subprocess] for details and for a specific warning
about using a @racket[command] that refers to a @filepath{.bat} or
@filepath{.cmd} file.}


@defproc[(system/exit-code [command (or/c string-no-nuls? bytes-no-nuls?)]
                           [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
         byte?]{

Like @racket[system], except that the result is the exit code returned
by the subprocess. A @racket[0] result normally indicates success.}


@defproc*[([(system*/exit-code [command path-string?]
                               [arg (or/c path? string-no-nuls? bytes-no-nuls?)] ...
                               [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
            byte?]
           [(system*/exit-code [command path-string?]
                               [exact 'exact] [arg string?]
                               [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
            byte?])]{

类似于 @racket[system*]，但像 @racket[system/exit-code] 那样返回退出码。}


@defproc[(process [command (or/c string-no-nuls? bytes-no-nuls?)]
                  [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
         (list input-port?
               output-port?
               exact-nonnegative-integer?
               input-port?
               ((or/c 'status 'wait 'interrupt 'kill) . -> . any))]{

Executes a shell command asynchronously (using @exec{/bin/sh} on Unix
and Mac OS, @exec{cmd.exe} or @exec{command.com} on Windows). The result is a list of five
values:

@margin-note{See also @racket[subprocess] for notes about error
handling and the limited buffer capacity of subprocess pipes.}

@itemize[

 @item{an input port piped from the subprocess's standard output,}

 @item{an output port piped to the subprocess's standard input,} 

 @item{the system process id of the subprocess,}

 @item{an input port piped from the subprocess's standard
       error, and}

 @item{a procedure of one argument, either @racket['status], @racket['wait],
 @racket['interrupt], @racket['exit-code] or @racket['kill]:

   @itemize[

   @item{@racket['status] returns the status of the subprocess as one
    of @racket['running], @racket['done-ok], or
    @racket['done-error].}

   @item{@racket['exit-code] returns the integer exit code of the
    subprocess or @racket[#f] if it is still running.}

   @item{@racket['wait] blocks execution in the current thread until
    the subprocess has completed.}

   @item{@racket['interrupt] sends the subprocess an interrupt signal
    on @|AllUnix|, and takes no action on Windows. The result is
    @|void-const|.

     @margin-note{On Unix and Mac OS, if @racket[command] runs a
     single program, then @exec{/bin/sh} typically runs the program in
     such a way that it replaces @exec{/bin/sh} in the same process. For
     reliable and precise control over process creation, however, use
     @racket[process*].}}

   @item{@racket['kill] terminates the subprocess and returns
     @|void-const|.  Note that the immediate process created by
     @racket[process] is a shell process that may run another program;
     terminating the shell process may not terminate processes that
     the shell starts, particularly on Windows.}

   ]}

]

@bold{Important:} All three ports returned from @racket[process] must
be explicitly closed with @racket[close-input-port] or
@racket[close-output-port].

If @racket[set-pwd?] is true, then @envvar{PWD} is set in the same way
as @racket[system].

See also @racket[current-subprocess-custodian-mode] and
@racket[subprocess-group-enabled], which affect the subprocess used to
implement @racket[process]. In particular, the @racket['interrupt] and
@racket['kill] process-control messages are implemented via
@racket[subprocess-kill], so they can affect a process group instead
of a single process.}


@defproc*[([(process* [command path-string?]
                      [arg (or/c path? string-no-nuls? bytes-no-nuls?)] ...
                      [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
            list?]
           [(process* [command path-string?] [exact 'exact] [arg string?]
                      [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
            list?])]{

Like @racket[process], except that @racket[command] is a filename that
is executed directly like @racket[system*], and the @racket[arg]s are the arguments.

On Windows, as for @racket[system*], the first @racket[arg] can be
replaced with @racket['exact]. See also @racket[subprocess] for a
specific warning about using a @racket[command] that refers to a
@filepath{.bat} or @filepath{.cmd} file.}


@defproc[(process/ports [out (or/c #f output-port?)]
                        [in (or/c #f input-port?)]
                        [error-out (or/c #f output-port? 'stdout)]
                        [command (or/c path? string-no-nuls? bytes-no-nuls?)]
                        [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
         list?]{

Like @racket[process], except that @racket[out] is used for the
process's standard output, @racket[in] is used for the process's
standard input, and @racket[error-out] is used for the process's
standard error.  Any of the ports can be @racket[#f], in which case a
system pipe is created and returned, as in @racket[process]. If
@racket[error-out] is @racket['stdout], then standard error is
redirected to standard output.  For each port or @racket['stdout] that
is provided, no pipe is created, and the corresponding value in the
returned list is @racket[#f].}

@defproc*[([(process*/ports [out (or/c #f output-port?)]
                            [in (or/c #f input-port?)]
                            [error-out (or/c #f output-port? 'stdout)]
                            [command path-string?]
                            [arg (or/c path? string-no-nuls? bytes-no-nuls?)]
                            ...
                            [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
            list?]
           [(process*/ports [out (or/c #f output-port?)]
                            [in (or/c #f input-port?)]
                            [error-out (or/c #f output-port? 'stdout)]
                            [command path-string?]
                            [exact 'exact]
                            [arg string?]
                            [#:set-pwd? set-pwd? any/c (member (system-type) '(unix macosx))])
            list?])]{

Like @racket[process*], but with the port handling of
@racket[process/ports].}

@; ----------------------------------------------------------------------

@;section{Contract Auxiliaries}

@;note-lib[racket/system]

The contracts of @racket[system] and related functions may signal a
contract error with references to the following functions.

@defproc[(string-no-nuls? [x any/c]) boolean?]{
Ensures that @racket[x] is a string and does not contain @racket["\0"].}

@defproc[(bytes-no-nuls? [x any/c]) boolean?]{
Ensures that @racket[x] is a byte-string and does not contain @racket[#"\0"].}
