#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "端口与文件系统"]{端口与文件系统}

端口表示为具有以下类型的 Racket 值
@cppi{scheme_input_port_type} and @cppi{scheme_output_port_type}.  The
function @cppi{scheme_read} 接受一个输入端口值并返回端口中的下一个 S-expression。  The function @cppi{scheme_write}
接受一个输出端口和一个值，并将该值写入端口。 还提供了其他标准低级端口函数，例如
as @cppi{scheme_getc}.

文件端口通过以下函数创建 @cppi{scheme_make_file_input_port} and
@cppi{scheme_make_file_output_port}; these functions take a @cpp{FILE
*} 文件指针并返回一个 Scheme 端口. 字符串的读取或写入使用
with @cppi{scheme_make_byte_string_input_port}, 该函数接受一个以 nul 结尾的字节字符串，而
@cppi{scheme_make_byte_string_output_port}, 该函数不接受任何参数.
字符串输出端口的内容通过以下方式获取
@cppi{scheme_get_byte_string_output}.

通过以下函数创建具有任意读/写处理程序的自定义端口
@cppi{scheme_make_input_port} and @cppi{scheme_make_output_port}.

当出于任何原因使用 Racket 提供的名称打开文件时，使用 @cppi{scheme_expand_filename} 来规范化文件名并解析相对路径。

@function[(Scheme_Object* scheme_read
           [Scheme_Object* port])]{

@racket[read]s the next S-expression from the given input port.}

@function[(void scheme_write
           [Scheme_Object* obj]
           [Scheme_Object* port])]{

@racket[write]s the Scheme value @var{obj} to the given output port.}

@function[(void scheme_write_w_max
           [Scheme_Object* obj]
           [Scheme_Object* port]
           [int n])]{

类似于 @cpp{scheme_write}，但打印被截断为 @var{n} bytes.
(如果打印被截断，最后几个字节打印为 ``.''.)}

@function[(void scheme_display
           [Scheme_Object* obj]
           [Scheme_Object* port])]{

@racket[display]s the Racket value @var{obj} to the given output
port.}

@function[(void scheme_display_w_max
           [Scheme_Object* obj]
           [Scheme_Object* port]
           [int n])]{

类似于 @cpp{scheme_display}，但打印被截断为 @var{n} bytes.
(If printing is truncated, the last three bytes are printed as ``.''.)}


@function[(void scheme_write_byte_string
           [char* str]
           [intptr_t len]
           [Scheme_Object* port])]{

将 @var{str} 的 @var{len} 个字节写入给定的输出端口。}

@function[(void scheme_write_char_string
           [mzchar* str]
           [intptr_t len]
           [Scheme_Object* port])]{

将 @var{str} 的 @var{len} 个字符写入给定的输出端口。}


@function[(intptr_t scheme_put_byte_string
           [const-char* who]
           [Scheme_Object* port]
           [char* str]
           [intptr_t d]
           [intptr_t len]
           [int rarely_block])]{

从第 @var{d} 个字符开始，写入 @var{str} 的 @var{len} 个字节。字节被写入给定的输出端口，错误以 @var{who} 的名义报告。

如果 @var{rarely_block} 为 @cpp{0}，则写入会阻塞直到所有 @var{len} 个字节被写入（可能写入内部缓冲区）。如果 @var{rarely_block} 为 @cpp{2}，则写入永不阻塞，且写入的字节不会被缓冲。如果 @var{rarely_block} 为 @cpp{1}，则写入仅阻塞到至少写入一个字节（无缓冲）或直到内部缓冲区的部分内容被刷新。

为 @var{len} 提供 @cpp{0} 对应于缓冲区刷新请求。如果 @var{rarely_block} 为 @cpp{2}，则刷新请求是非阻塞的；如果 @var{rarely_block} 为 @cpp{0}，则是阻塞的。（在这种情况下，@var{rarely_block} 为 @cpp{1} 等同于 @cpp{0}。）

如果没有从 @var{str} 写入任何字节且内部缓冲区中仍有未刷新的字节，则结果为 @cpp{-1}。否则，返回值是已写入的字符数。}

@function[(intptr_t scheme_put_char_string
           [const-char* who]
           [Scheme_Object* port]
           [char* str]
           [intptr_t d]
           [intptr_t len])]{

类似于 @cpp{scheme_put_byte_string}，但用于 @cpp{mzchar} 字符串，且没有非阻塞选项。}

@function[(char* scheme_write_to_string
           [Scheme_Object* obj]
           [intptr_t* len])]{

使用 @racket[write] 将 Racket 值 @var{obj} 打印到新分配的字符串中。如果 @var{len} 不为 @cpp{NULL}，则 @cpp{*@var{len}} 被设置为字节字符串的长度。}

@function[(void scheme_write_to_string_w_max
           [Scheme_Object* obj]
           [intptr_t* len]
           [int n])]{

类似于 @cpp{scheme_write_to_string}，但字符串被截断为
@var{n} bytes.  (如果字符串被截断，最后三个字节是
``.''.)}

@function[(char* scheme_display_to_string
           [Scheme_Object* obj]
           [intptr_t* len])]{

使用 @racket[display] 将 Racket 值 @var{obj} 打印到新分配的字符串中。如果 @var{len} 不为 @cpp{NULL}，则 @cpp{*@var{len}} 被设置为字符串的长度。}


@function[(void scheme_display_to_string_w_max
           [Scheme_Object* obj]
           [intptr_t* len]
           [int n])]{

类似于 @cpp{scheme_display_to_string}，但字符串被截断为
@var{n} bytes.  (如果字符串被截断，最后三个字节是
``.''.)}


@function[(void scheme_debug_print
           [Scheme_Object* obj])]{

使用 @racket[write] 将 Racket 值 @var{obj} 打印到主线程的输出端口。}

@function[(void scheme_flush_output
           [Scheme_Object* port])]{

如果 @var{port} 是文件端口，则缓冲的数据被写入文件。否则，无任何效果。@var{port} 必须是输出端口。}

@function[(int scheme_get_byte
           [Scheme_Object* port])]{

从给定的输入端口获取下一个字节。结果可以是 @cpp{EOF}。}

@function[(int scheme_getc
           [Scheme_Object* port])]{

从给定的输入端口获取下一个字符（通过将字节解码为 UTF-8）。结果可以是 @cpp{EOF}。}

@function[(int scheme_peek_byte
           [Scheme_Object* port])]{

窥视给定输入端口的下一个字节。结果可以是 @cpp{EOF}。}

@function[(int scheme_peekc
           [Scheme_Object* port])]{

窥视给定输入端口的下一个字符（通过将字节解码为 UTF-8）。结果可以是 @cpp{EOF}。}

@function[(int scheme_peek_byte_skip
           [Scheme_Object* port]
           [Scheme_Object* skip])]{

类似于 @cpp{scheme_peek_byte}，但带有跳过计数。结果可以是 @cpp{EOF}。}

@function[(int scheme_peekc_skip
           [Scheme_Object* port]
           [Scheme_Object* skip])]{

类似于 @cpp{scheme_peekc}，但带有跳过计数。结果可以是 @cpp{EOF}。}


@function[(intptr_t scheme_get_byte_string
           [const-char* who]
           [Scheme_Object* port]
           [char* buffer]
           [int offset]
           [intptr_t size]
           [int only_avail]
           [int peek]
           [Scheme_Object* peek_skip])]{

一次性从端口获取多个字节，以 @var{who} 的名义报告错误。 The @var{size} argument indicates the number of
requested bytes, to be put into the @var{buffer} array starting at
@var{offset}.  The return value is the number of bytes actually read,
or @cpp{EOF} if an end-of-file is encountered without reading any
bytes.

如果 @var{only_avail} 为 @cpp{0}，则函数阻塞直到读取 @var{size} 个字节或到达文件结尾。如果 @var{only_avail} 为 @cpp{1}，则函数仅阻塞到至少读取一个字节。如果 @var{only_avail} 为 @cpp{2}，则函数永不阻塞。如果 @var{only_avail} 为 @cpp{-1}，则函数仅阻塞到至少读取一个字节，但同时也允许中断（保证要么读取字节要么引发中断，但不会两者都发生）。

如果 @var{peek} 非零，则对端口执行窥视而非读取。 The @var{peek_skip} argument indicates a portion of the input
stream to skip as a non-negative, exact integer (fixnum or bignum). In
this case, an @var{only_avail} value of @cpp{1} means to continue the
skip until at least one byte can be returned, even if it means
multiple blocking reads to skip bytes.

If @var{peek} is zero, then @var{peek_skip} should be either
@cpp{NULL} (which means zero) or the fixnum zero.}

@function[(intptr_t scheme_get_char_string
           [const-char* who]
           [Scheme_Object* port]
           [char* buffer]
           [int offset]
           [intptr_t size]
           [int peek]
           [Scheme_Object* peek_skip])]{

类似于 @cpp{scheme_get_byte_string}，但用于字符（通过将字节解码为 UTF-8），且没有非阻塞选项。}


@function[(intptr_t scheme_get_bytes
           [Scheme_Object* port]
           [intptr_t size]
           [char* buffer]
           [int offset])]{

用于向后兼容：调用 @cpp{scheme_get_byte_string} in
essentially the obvious way with @var{only_avail} as @cpp{0}; if
@var{size} is negative, then it reads @var{-size} bytes with
@var{only_avail} as @cpp{1}.}

@function[(void scheme_ungetc
           [int ch]
           [Scheme_Object* port])]{

将字节 @var{ch} 放回作为下一个要从给定输入端口读取的字符。 The character need not have been read from
@var{port}, and @cpp{scheme_ungetc} can be called to insert up to five
characters at the start of @var{port}.

Use @cpp{scheme_get_byte} followed by @cpp{scheme_ungetc} only when
your program will certainly call @cpp{scheme_get_byte} again to
consume the byte. Otherwise, use @cpp{scheme_peek_byte}, because some
a port may implement peeking and getting differently.}

@function[(int scheme_byte_ready
           [Scheme_Object* port])]{

如果对 @cpp{scheme_get_byte} 的调用保证不会在给定输入端口上阻塞，则返回 1。}

@function[(int scheme_char_ready
           [Scheme_Object* port])]{

如果对 @cpp{scheme_getc} 的调用保证不会在给定输入端口上阻塞，则返回 1。}

@function[(void scheme_need_wakeup
           [Scheme_Object* port]
           [void* fds])]{

请求在 @var{fds} 中设置适当的位，以指定给定输入端口从哪些文件描述符读取。 (@var{fds} is
sortof a pointer to an @cppi{fd_set} struct; see
@secref["blockednonmainel"].)}

@function[(intptr_t scheme_tell
           [Scheme_Object* port])]{

返回给定输入端口的当前读取位置，或给定输出端口的当前文件位置。}

@function[(intptr_t scheme_tell_line
           [Scheme_Object* port])]{

返回给定输入端口的当前读取行。如果未计数行数，则返回 -1。}

@function[(void scheme_count_lines
           [Scheme_Object* port])]{

为给定输入端口启用行计数。要获得准确的行计数，请在创建端口后立即调用此函数。}

@function[(intptr_t scheme_set_file_position
           [Scheme_Object* port]
           [intptr_t pos])]{

设置给定输入或输出端口的文件位置（从文件开头算起）。如果端口不支持位置设置，则引发异常。}

@function[(void scheme_close_input_port
           [Scheme_Object* port])]{

关闭给定的输入端口。}

@function[(void scheme_close_output_port
           [Scheme_Object* port])]{

关闭给定的输出端口。}

@function[(int scheme_get_port_file_descriptor
           [Scheme_Object* port]
           [intptr_t* fd])]{

Fills @cpp{*@var{fd}} with a file-descriptor value for @var{port} if
one is available (i.e., the port is a file-stream port and it is not
closed). The result is non-zero if the file-descriptor value is
available, zero otherwise. On Windows, a ``file descriptor'' is a
file @cpp{HANDLE}.}

@function[(intptr_t scheme_get_port_fd
           [Scheme_Object* port])]{

类似于 @cpp{scheme_get_port_file_descriptor}，但直接返回文件描述符或 @cpp{HANDLE}，如果没有可用的文件描述符或 @cpp{HANDLE} 则结果为 @cpp{-1}。}

@function[(intptr_t scheme_get_port_socket
           [Scheme_Object* port]
           [intptr_t* s])]{

Fills @cpp{*@var{s}} with a socket value for @var{port} if one is
available (i.e., the port is a TCP port and it is not closed). The
result is non-zero if the socket value is available, zero
otherwise. On Windows, a socket value has type @cpp{SOCKET}.}

@function[(Scheme_Object* scheme_make_port_type
           [char* name])]{

创建一个新的端口子类型。}

@function[(Scheme_Input_Port* scheme_make_input_port
           [Scheme_Object* subtype]
           [void* data]
           [Scheme_Object* name]
           [Scheme_Get_String_Fun get_bytes_fun]
           [Scheme_Peek_String_Fun peek_bytes_fun]
           [Scheme_Progress_Evt_Fun progress_evt_fun]
           [Scheme_Peeked_Read_Fun peeked_read_fun]
           [Scheme_In_Ready_Fun char_ready_fun]
           [Scheme_Close_Input_Fun close_fun]
           [Scheme_Need_Wakeup_Input_Fun need_wakeup_fun]
           [int must_close])]{

使用任意控制函数创建一个新的输入端口。 The
@var{subtype} is an arbitrary value to distinguish the port's class.
指针 @var{data} 将被安装为端口的用户数据，可以通过 @cppi{SCHEME_INPORT_VAL} 宏提取/设置。
@var{name} 对象用作端口的名称（用于 @racket[object-name] 和作为 @racket[read-syntax] 的默认源名称）。

如果 @var{must_close} 非零，则新端口将注册到当前 custodian，并且保证在端口被垃圾回收之前调用 @var{close_fun}。

虽然 @cpp{scheme_make_input_port} 的返回类型是 @cppi{Scheme_Input_Port*}，但可以转换为 @cpp{Scheme_Object*}。

The functions are as follows.

 @subfunction[(intptr_t get_bytes_fun
               [Scheme_Input_Port* port]
               [char* buffer]
               [intptr_t offset]
               [intptr_t size]
               [int nonblock]
               [Scheme_Object* unless])]{
 
    Reads bytes into @var{buffer}, starting from @var{offset}, up to
    @var{size} bytes (i.e., @var{buffer} is at least
    @var{offset} plus @var{size} long). If @var{nonblock} is @cpp{0},
    then the function can block indefinitely, but it should return
    when at least one byte of data is available. If @var{nonblock} is
    @cpp{1}, the function should never block. If @var{nonblock} is
    @cpp{2}, a port in unbuffered mode should return only bytes
    previously forced to be buffered; other ports should treat a
    @var{nonblock} of @cpp{2} like @cpp{1}. If @var{nonblock} is
    @cpp{-1}, the function can block, but should enable breaks while
    blocking. The function should return @cpp{0} if no bytes are ready
    in non-blocking mode. It should return @cpp{EOF} if an end-of-file
    is reached (and no bytes were read into @var{buffer}). Otherwise,
    the function should return the number of read bytes. The function
    can raise an exception to report an error.

    The @var{unless} argument will be non-@cpp{NULL} only when
    @var{nonblocking} is non-zero (except as noted below), and only if
    the port supports progress events. If @var{unless} is
    non-@cpp{NULL} and @cpp{SCHEME_CDR(@var{unless})} is
    non-@cpp{NULL}, the latter is a progress event specific to the
    port. The @var{get_bytes_fun} function should return
    @cppi{SCHEME_UNLESS_READY} instead of reading bytes if the event
    in @var{unless} becomes ready before bytes can be read. In
    particular, @var{get_bytes_fun} should check the event in
    @var{unless} before taking any action, and it should check the
    event in @var{unless} after any operation that may allow Racket
    thread swaps. If the read must block, then it should unblock if
    the event in @var{unless} becomes ready.

    If @cpp{scheme_progress_evt_via_get} is used for
    @var{progress_evt_fun}, then @var{unless} can be non-@cpp{NULL}
    even when @var{nonblocking} is @cpp{0}. In all modes,
    @var{get_bytes_fun} must call @cpp{scheme_unless_ready} to check
    @var{unless_evt}.  Furthermore, after any potentially
    thread-swapping operation, @var{get_bytes_fun} must call
    @cpp{scheme_wait_input_allowed}, because another thread may be
    attempting to commit, and @var{unless_evt} must be checked after
    @cpp{scheme_wait_input_allowed} returns. To block, the port should
    use @cpp{scheme_block_until_unless} instead of
    @cpp{scheme_block_until}.  Finally, in blocking mode,
    @var{get_bytes_fun} must return after immediately reading data,
    without allowing a Racket thread swap.}

 @subfunction[(intptr_t peek_bytes_fun
               [Scheme_Input_Port* port]
               [char* buffer]
               [intptr_t offset]
               [intptr_t size]
               [Scheme_Object* skip]
               [int nonblock]
               [Scheme_Object* unless_evt])]{

    Can be @cpp{NULL} to use a default implementation of peeking that
    uses @var{get_bytes_fun}. Otherwise, the protocol is the same as
    for @var{get_bytes_fun}, except that an extra @var{skip} argument
    indicates the number of input elements to skip (but @var{skip}
    does not apply to @var{buffer}). The @var{skip} value will be a
    non-negative exact integer, either a fixnum or a bignum.}

 @subfunction[(Scheme_Object* progress_evt_fun
               [Scheme_Input_Port* port])]{

    Called to obtain a progress event for the port, such as for
    @racket[port-progress-evt]. This function can be @cpp{NULL} if the
    port does not support progress events. Use
    @cpp{scheme_progress_evt_via_get} to obtain a default implementation, in
    which case @var{peeked_read_fun} should be
    @cpp{scheme_peeked_read_via_get}, and @var{get_bytes_fun} and
    @var{peek_bytes_fun} should handle @var{unless} as described
    above.}

 @subfunction[(int peeked_read_fun
               [Scheme_Input_Port* port]
               [intptr_t amount]
               [Scheme_Object* unless_evt]
               [Scheme_Object* target_ch])]{

    Called to commit previously peeked bytes, just like the sixth
    argument to @racket[make-input-port]. Use
    @cpp{scheme_peeked_read_via_get} for the default implementation of
    commits when @var{progress_evt_fun} is
    @cpp{scheme_progress_evt_via_get}.

    The @var{peeked_read_fun} function must call
    @cpp{scheme_port_count_lines} on a successful commit to adjust the
    port's position. If line counting is enabled for the port and if
    line counting uses the default implementation,
    @var{peeked_read_fun} should supply a non-@cpp{NULL} byte-string
    argument to @cpp{scheme_port_count_lines}, so that character and
    line counts can be tracked correctly.}

 @subfunction[(int char_ready_fun
               [Scheme_Input_Port* port])]{

    Returns @cpp{1} when a non-blocking @var{get_bytes_fun} will
    return bytes or an @cpp{EOF}.}

 @subfunction[(void close_fun
               [Scheme_Input_Port* port])]{

    Called to close the port. The port is not considered closed until
    the function returns.}

 @subfunction[(void need_wakeup_fun
               [Scheme_Input_Port* port]
               [void* fds])]{

    Called when the port is blocked on a read; @var{need_wakeup_fun}
    should set appropriate bits in @var{fds} to specify which file
    descriptor(s) it is blocked on. The @var{fds} argument is
    conceptually an array of three @cppi{fd_set} structs (one for
    read, one for write, one for exceptions), but manipulate this
    array using @cppi{scheme_get_fdset} to get a particular element of
    the array, and use @cppi{MZ_FD_XXX} instead of @cpp{FD_XXX} to
    manipulate a single ``@cpp{fd_set}''. On Windows, the first
    ``@cpp{fd_set}'' can also contain OS-level semaphores or other
    handles via @cpp{scheme_add_fd_handle}.}
}

@function[(Scheme_Output_Port* scheme_make_output_port
           [Scheme_Object* subtype]
           [void* data]
           [Scheme_Object* name]
           [Scheme_Write_String_Evt_Fun write_bytes_evt_fun]
           [Scheme_Write_String_Fun write_bytes_fun]
           [Scheme_Out_Ready_Fun char_ready_fun]
           [Scheme_Close_Output_Fun close_fun]
           [Scheme_Need_Wakeup_Output_Fun need_wakeup_fun]
           [Scheme_Write_Special_Evt_Fun write_special_evt_fun]
           [Scheme_Write_Special_Fun write_special_fun]
           [int must_close])]{

使用任意控制函数创建一个新的输出端口。  The
@var{subtype} is an arbitrary value to distinguish the port's class.
The pointer @var{data} will be installed as the port's user data,
which can be extracted/set with the @cppi{SCHEME_OUTPORT_VAL}
macro. The @var{name} object is used as the port's name.

如果 @var{must_close} 非零，则新端口将注册到当前 custodian，并且保证在端口被垃圾回收之前调用 @var{close_fun}。

虽然 @cpp{scheme_make_output_port} 的返回类型是 @cppi{Scheme_Output_Port*}，但可以转换为 @cpp{Scheme_Object*}。

The functions are as follows.

 @subfunction[(intptr_t write_bytes_evt_fun
               [Scheme_Output_Port* port]
               [const-char* buffer]
               [intptr_t offset]
               [intptr_t size])]{

    Returns an event that writes up to @var{size} bytes atomically
    when event is chosen in a synchronization. Supply @cpp{NULL} if
    bytes cannot be written atomically, or supply
    @cppi{scheme_write_evt_via_write} to use the default
    implementation in terms of @cpp{write_bytes_fun} (with
    @var{rarely_block} as @cpp{2}).}

 @subfunction[(intptr_t write_bytes_fun
               [Scheme_Output_Port* port]
               [const-char* buffer]
               [intptr_t offset]
               [intptr_t size]
               [int rarely_block]
               [int enable_break])]{

    Write bytes from @var{buffer}, starting from @var{offset}, up to
    @var{size} bytes (i.e., @var{buffer} is at least
    @var{offset} plus @var{size} long). If @var{rarely_block} is @cpp{0},
    then the function can block indefinitely, and it can buffer
    output. If @var{rarely_block} is @cpp{2}, the function should
    never block, and it should not buffer output. If
    @var{rarely_block} is @cpp{1}, the function should not buffer
    data, and it should block only until writing at least one byte,
    either from @var{buffer} or an internal buffer. The function
    should return the number of bytes from @var{buffer} that were
    written; when @var{rarely_block} is non-zero and bytes remain in
    an internal buffer, it should return @cpp{-1}. The @var{size}
    argument can be @cpp{0} when @var{rarely_block} is @cpp{0} for a
    blocking flush, and it can be @cpp{0} if @var{rarely_block} is
    @cpp{2} for a non-blocking flush.  If @var{enable_break} is true,
    then it should enable breaks while blocking. The function can
    raise an exception to report an error.}

 @subfunction[(int char_ready_fun
               [Scheme_Output_Port* port])]{

    Returns @cpp{1} when a non-blocking @var{write_bytes_fun} will
    write at least one byte or flush at least one byte from
    the port's internal buffer.}

  @subfunction[(void close_fun
                [Scheme_Output_Port* port])]{
 
    Called to close the port. The port is not considered closed until
    the function returns. This function is allowed to block (usually
    to flush a buffer) unless
    @cpp{scheme_close_should_force_port_closed} returns a non-zero
    result, in which case the function must return without blocking.}

 @subfunction[(void need_wakeup_fun
               [Scheme_Output_Port* port]
               [void* fds])]{

    Called when the port is blocked on a write; @var{need_wakeup_fun}
    should set appropriate bits in @var{fds} to specify which file
    descriptor(s) it is blocked on. The @var{fds} argument is
    conceptually an array of three @cppi{fd_set} structs (one for
    read, one for write, one for exceptions), but manipulate this
    array using @cppi{scheme_get_fdset} to get a particular element of
    the array, and use @cppi{MZ_FD_XXX} instead of @cpp{FD_XXX} to
    manipulate a single ``@cpp{fd_set}''. On Windows, the first
    ``@cpp{fd_set}'' can also contain OS-level semaphores or other
    handles via @cpp{scheme_add_fd_handle}.}

 @subfunction[(int write_special_evt_fun
               [Scheme_Output_Port* port]
               [Scheme_Object* v])]{

    Returns an event that writes @var{v} atomically when event is
    chosen in a synchronization. Supply @cpp{NULL} if specials cannot
    be written atomically (or at all), or supply
    @cppi{scheme_write_special_evt_via_write_special} to use the
    default implementation in terms of @cpp{write_special_fun} (with
    @var{non_block} as @cpp{1}).}

 @subfunction[(int write_special_fun
               [Scheme_Output_Port* port]
               [Scheme_Object* v]
               [int non_block])]{

    Called to write the special value @var{v} for
    @racket[write-special] (when @var{non_block} is @cpp{0}) or
    @racket[write-special-avail*] (when @var{non_block} is
    @cpp{1}). If @cpp{NULL} is supplied instead of a function pointer,
    then @racket[write-special] and @racket[write-special-avail*]
    produce an error for this port.}

}

@function[(void scheme_set_port_location_fun [Scheme_Port* port]
					     [Scheme_Location_Fun location_fun])]{

设置 @var{port} 的 @racket[port-next-location] 的实现，当为 @var{port} 启用行计数时使用。

 @subfunction[(Scheme_Object* location_fun
               [Scheme_Port* port])]{
   Returns three values: a positive exact integer or @racket[#f] for a line number,
   a non-negative exact integer or @racket[#f] for a column (which must be @racket[#f]
   if and only if the line number is @racket[#f]), and
   a positive exact integer or @racket[#f] for a character position.
 }
}

@function[(void scheme_set_port_count_lines_fun [Scheme_Port* port]
					        [Scheme_Count_Lines_Fun count_lines_fun])]{

安装一个通知回调，如果随后为 @var{port} 启用了行计数，则调用该回调。

 @subfunction[(void count_lines_fun
               [Scheme_Port* port])]
}

@function[(void scheme_port_count_lines [Scheme_Port* port]
                                        [const-char* buffer]
                                        [intptr_t offset]
                                        [intptr_t got])]{

更新 @var{port} 的位置（由 @racket[file-position] 报告）以及位置（由 @racket[port-next-location] 报告），当使用默认的字符和行计数实现时。此函数旨在供输入端口中的 peek-commit 实现使用。

The @var{got} argument indicates the number of bytes read from or
written to @var{port}. The @var{buffer} argument is used only when
line counting is enabled, and it represents specific bytes read or
written for the purposes of character and line coutning. The
@var{buffer} argument can be @cpp{NULL}, in which case @var{got}
non-newline characters are assumed. The @var{offset} argument
indicates a starting offset into @var{buffer}, so @racket{buffer} must
be at least @var{offset} plus @var{got} bytes long.}


@function[(Scheme_Object* scheme_make_file_input_port
           [FILE* fp])]{

从 ANSI C 文件指针创建一个 Scheme 输入文件端口。该文件在读取时绝不能阻塞。}

@function[(Scheme_Object* scheme_open_input_file
           [const-char* filename]
           [const-char* who])]{

打开 @var{filename} 进行读取。如果引发异常，异常消息使用 @var{who} 作为引发异常的过程名称。}

@function[(Scheme_Object* scheme_make_named_file_input_port
           [FILE* fp]
           [Scheme_Object* name])]{

从 ANSI C 文件指针创建一个 Racket 输入文件端口。该文件在读取时绝不能阻塞。@var{name} 参数用作端口的名称。}

@function[(Scheme_Object* scheme_open_output_file
           [const-char* filename]
           [const-char* who])]{

以 @racket['truncate/replace] 模式打开 @var{filename} 进行写入。如果引发异常，异常消息使用 @var{who} 作为引发异常的过程名称。}

@function[(Scheme_Object* scheme_make_file_output_port
           [FILE* fp])]{

从 ANSI C 文件指针创建一个 Racket 输出文件端口。该文件在写入时绝不能阻塞。}

@function[(Scheme_Object* scheme_make_fd_input_port
           [int fd]
           [Scheme_Object* name]
           [int regfile]
           [int win_textmode])]{

为文件描述符创建 Racket 输入端口 @var{fd}. On
 Windows, @var{fd} can be a @cpp{HANDLE} for a stream, and it should
 never be a file descriptor from the C library or a WinSock socket.

The @var{name} object is used for the port's name. Specify a non-zero
 value for @var{regfile} only if the file descriptor corresponds to a
 regular file (which implies that reading never blocks, for example).

On Windows, @var{win_textmode} can be non-zero to make trigger
 auto-conversion (at the byte level) of CRLF combinations to LF.

Closing the resulting port closes the file descriptor.

Instead of calling both @cpp{scheme_make_fd_input_port} and
 @cpp{scheme_make_fd_output_port} on the same file descriptor, call
 @cpp{scheme_make_fd_output_port} with a non-zero last
 argument. Otherwise, closing one of the ports causes the file
 descriptor used by the other to be closed as well.}

@function[(Scheme_Object* scheme_make_fd_output_port
           [int fd]
           [Scheme_Object* name]
           [int regfile]
           [int win_textmode]
           [int read_too])]{

为文件描述符创建 Racket 输出端口 @var{fd}. On
 Windows, @var{fd} can be a @cpp{HANDLE} for a stream, and it should
 never be a file descriptor from the C library or a WinSock socket.

The @var{name} object is used for the port's name. Specify a non-zero
 value for @var{regfile} only if the file descriptor corresponds to a
 regular file (which implies that reading never blocks, for example).

On Windows, @var{win_textmode} can be non-zero to make trigger
 auto-conversion (at the byte level) of CRLF combinations to LF.

Closing the resulting port closes the file descriptor.

If @var{read_too} is non-zero, the function produces multiple values
 (see @secref["multiple"]) instead of a single port. The first result is
 an input port for @var{fd}, and the second is an output port for
 @var{fd}. These ports are connected in that the file descriptor is
 closed only when both of the ports are closed.}


@function[(void scheme_socket_to_ports
           [intptr_t s]
           [const-char* name]
           [int close]
           [Scheme_Object** inp]
           [Scheme_Object** outp])]{

为 TCP socket 创建 Racket 输入和输出端口 @var{s}. The
 @var{name} argument supplies the name for the ports. If @var{close}
 is non-zero, then the ports assume responsibility for closing the
 socket. The resulting ports are written to @var{inp} and @var{outp}.

Whether @var{close} is zero or not, closing the resulting ports
 unregisters the file descriptor with @cpp{scheme_fd_to_semaphore}.
 So, passing zero for @var{close} and also using the file descriptor
 with other ports or with @cpp{scheme_fd_to_semaphore} will not work right.

@history[#:changed "6.9.0.6" @elem{Changed ports to always unregister
                                   with @cpp{scheme_fd_to_semaphore},
                                   since it's not safe to skip that
                                   step.}]}


@function[(Scheme_Object* scheme_fd_to_semaphore
           [intptr_t fd]
           [int mode]
           [int is_socket])]{

创建或查找一个 Racket 信号量，当 @var{fd} 就绪时该信号量变为就绪状态。 The semaphore reflects a registration with the operating
system's underlying mechanisms for efficient polling. When a semaphore
is created, it remains findable via @cpp{scheme_fd_to_semaphore} for a
particular read/write mode as long as @var{fd} has not become ready in
the read/write mode since the creation of the semaphore, or unless
@cpp{MZFD_REMOVE} has been used to remove the registered semaphore.
The @var{is_socket} argument indicates whether @var{fd} is a socket or
a filesystem descriptor; the difference matters for Windows, and it
matters for BSD-based platforms where sockets are always supported and
other file descriptors are tested for whether they correspond to a
directory or regular file.

The @var{mode} argument is one of the following:

@itemlist[

 @item{@cpp{MZFD_CREATE_READ} (= @cpp{1}) --- creates or finds
       a semaphore to reflect whether @var{fd} is ready for reading.}

 @item{@cpp{MZFD_CREATE_WRITE} (= @cpp{2}) --- creates or finds
       a semaphore to reflect whether @var{fd} is ready for writing.}

 @item{@cpp{MZFD_CHECK_READ} (= @cpp{3}) --- finds a semaphore to
       reflect whether @var{fd} is ready for reading; the result is
       @cpp{NULL} if no semaphore was previously created for @var{fd} in
       read mode or if such a semaphore has been posted or removed.}

 @item{@cpp{MZFD_CHECK_WRITE} (= @cpp{4}) --- like
       @cpp{MZFD_CREATE_READ}, but for write mode.}

 @item{@cpp{MZFD_REMOVE} (= @cpp{5}) --- removes all recorded
       semaphores for @var{fd} (unregistering a poll with the
       operating system) and returns @cpp{NULL}.}

 @item{@cpp{MZFD_CREATE_VNODE} (= @cpp{6}) --- creates or finds a
       semaphore to reflect whether @var{fd} changes; on some
       platforms, @cpp{MZFD_CREATE_VNODE} is the same as
       @cpp{MZFD_CREATE_READ}; on other platforms, only one or the
       other can be used on a given file descriptor.}

 @item{@cpp{MZFD_CHECK_VNODE} (= @cpp{7}) --- like @cpp{MZFD_CHECK_READ},
       but to find a semaphore recorded via @cpp{MZFD_CREATE_VNODE}.}

 @item{@cpp{MZFD_REMOVE_VNODE} (= @cpp{8}) --- like @cpp{MZFD_REMOVE},
       but to remove a semaphore recorded via @cpp{MZFD_CREATE_VNODE}.}

]}


@function[(Scheme_Object* scheme_make_byte_string_input_port
           [char* str])]{

从字节字符串创建一个 Racket 输入端口；端口上连续的 @racket[read-char] 返回字符串中的连续字节。}

@function[(Scheme_Object* scheme_make_byte_string_output_port)]{

创建一个 Racket 输出端口；所有对端口的写入都保存在一个字节字符串中，该字符串可以通过 @cpp{scheme_get_byte_string_output} 获取。}

@function[(char* scheme_get_byte_string_output
           [Scheme_Object* port])]{

返回（在新分配的字节字符串中）迄今为止写入给定字符串输出端口的所有数据。（返回的字符串以 nul 结尾。）}

@function[(char* scheme_get_sized_byte_string_output
           [Scheme_Object* port]
           [intptr_t* len])]{

Returns (in a newly allocated byte string) all data that has been
 written to the given string output port so far and fills in
 @cpp{*len} with the length of the string in bytes (not including the
 nul terminator).}

@function[(void scheme_pipe
           [Scheme_Object** read]
           [Scheme_Object** write])]{

创建一对端口，设置 @cpp{*@var{read}} 和 @cpp{*@var{write}}；写入 @cpp{*@var{write}} 的数据可以从 @cpp{*@var{read}} 读回。管道可以存储任意数量的未读字符，}

@function[(void scheme_pipe_with_limit
           [Scheme_Object** read]
           [Scheme_Object** write]
           [int limit])]{

如果 @var{limit} 为 @cpp{0}，则类似于 @cpp{scheme_pipe}。如果 @var{limit} 为正，则创建一个最多存储 @var{limit} 个未读字符的管道，当管道满时阻塞写入。}

@function[(Scheme_Input_Port* scheme_input_port_record
           [Scheme_Object* port])]{

Returns the input-port record for @var{port}, which may be either a
raw-port object with type @cpp{scheme_input_port_type} or a structure
with the @racket[prop:input-port] property.}

@function[(Scheme_Output_Port* scheme_output_port_record
           [Scheme_Object* port])]{

Returns the output-port record for @var{port}, which may be either a
raw-port object with type @cpp{scheme_output_port_type} or a structure
with the @racket[prop:output-port] property.}

@function[(int scheme_file_exists
           [char* name])]{

如果具有给定名称的文件存在则返回 1，否则返回 0。如果 @var{name} 指定一个目录，则返回 FALSE。@var{name} 应该已经展开。}

@function[(int scheme_directory_exists
           [char* name])]{

如果具有给定名称的目录存在则返回 1，否则返回 0。@var{name} 应该已经展开。}

@function[(char* scheme_expand_filename
           [const-char* name]
           [int len]
           [const-char* where]
           [int* expanded]
           [int checks])]{

清理路径名 @var{name} (see @racket[cleanse-path]) and
相对于当前目录 parameter 解析相对路径。 The @var{len} argument is the length of the input string;
if it is -1, the string is assumed to be null-terminated.  The
@var{where} argument is used to raise an exception if there is an
error in the filename; if this is @cpp{NULL}, an error is not reported
and @cpp{NULL} is returned instead.  If @var{expanded} is not
@cpp{NULL}, *@var{expanded} is set to 1 if some expansion takes place,
or 0 if the input name is simply returned.

If @var{guards} is not @cpp{0}, then @cpp{scheme_security_check_file}
(see @secref["security"]) is called with @var{name}, @var{where}, and
@var{checks} (which implies that @var{where} should never be
@cpp{NULL} unless @var{guards} is @cpp{0}). Normally, @var{guards}
should be @cpp{SCHEME_GUARD_FILE_EXISTS} at a minimum. Note that a
failed access check will result in an exception.}

@function[(char* scheme_expand_string_filename
           [Scheme_Object* name]
           [const-char* where]
           [int* expanded]
           [int checks])]{

类似于 @cpp{scheme_expand_string}，但给定一个可以是字符串或路径值的 @var{name}。}

@function[(Scheme_Object* scheme_char_string_to_path
           [Scheme_Object* s])]{

将 Racket 字符串转换为 Racket 路径值。}

@function[(Scheme_Object* scheme_path_to_char_string
           [Scheme_Object* s])]{

将 Racket 路径值转换为 Racket 字符串。}

@function[(Scheme_Object* scheme_make_path
           [char* bytes])]{

给定一个字节字符串，创建一个路径值。@var{bytes} 字符串被复制。}

@function[(Scheme_Object* scheme_make_path_without_copying
           [char* bytes])]{

类似于 @cpp{scheme_make_path}，但字符串不被复制。}

@function[(Scheme_Object* scheme_make_sized_path
           [char* bytes]
           [intptr_t len]
           [int copy])]{

Makes a path whose byte form has size @var{len}. A copy of @var{bytes}
is made if @var{copy} is not 0. The string @var{bytes} should contain
@var{len} bytes, and if @var{copy} is zero, @var{bytes} must have a
nul terminator in addition. If @var{len} is negative, then the
nul-terminated length of @var{bytes} is used for the length.}

@function[(Scheme_Object* scheme_make_sized_offset_path
           [char* bytes]
           [intptr_t d]
           [intptr_t len]
           [int copy])]{

Like @cpp{scheme_make_sized_path}, except the @var{len} bytes start
from position @var{d} in @var{bytes}. If @var{d} is non-zero, then
@var{copy} must be non-zero.}

@function[(char* scheme_build_mac_filename
           [FSSpec* spec]
           [int isdir])]{

仅 Mac OS：将 an @cppi{FSSpec} record (defined by Mac OS)
into a pathname string. If @var{spec} contains only directory
information (via the @cpp{vRefNum} and @cpp{parID} fields),
@var{isdir} should be @cpp{1}, otherwise it should be @cpp{0}.}

@function[(int scheme_mac_path_to_spec
           [const-char* filename]
           [FSSpec* spec]
           [intptr_t* type])]{

仅 Mac OS：将 a pathname into an @cppi{FSSpec} record
(defined by Mac OS), returning @cpp{1} if successful and @cpp{0}
otherwise. If @var{type} is not @cpp{NULL} and @var{filename} is a
file that exists, @var{type} is filled with the file's four-character
Mac OS type. If @var{type} is not @cpp{NULL} and @var{filename} is
not a file that exists, @var{type} is filled with @cpp{0}.}

@function[(char* scheme_os_getcwd
           [char* buf]
           [int buflen]
           [int* actlen]
           [int noexn])]{

根据操作系统获取当前工作目录。这与 Racket 的当前目录 parameter 是分开的。

The directory path is written into @var{buf}, of length @var{buflen},
if it fits. Otherwise, a new (collectable) string is allocated for the
directory path. If @var{actlen} is not @cpp{NULL}, *@var{actlen} is
set to the length of the current directory path. If @var{noexn} is
no 0, then an exception is raised if the operation fails.}

@function[(int scheme_os_setcwd
           [char* buf]
           [int noexn])]{

根据操作系统设置当前工作目录。这与 Racket 的当前目录 parameter 是分开的。

If @var{noexn} is not 0, then an exception is raised if the operation
fails.}

@function[(char* scheme_format
           [mzchar* format]
           [int flen]
           [int argc]
           [Scheme_Object** argv]
           [intptr_t* rlen])]{

类似于 Racket 的 @racket[format] 过程创建一个字符串，使用格式字符串 @var{format}（长度为 @var{flen}）以及 @var{argc} 和 @var{argv} 中指定的额外参数。 If @var{rlen} is not
@cpp{NULL}, @cpp{*@var{rlen}} is filled with the length of the
resulting string.}

@function[(void scheme_printf
           [char* format]
           [int flen]
           [int argc]
           [Scheme_Object** argv])]{

类似于 Racket 的 @racket[printf] 过程写入当前输出端口，使用格式字符串 @var{format}（长度为 @var{flen}）以及 @var{argc} 和 @var{argv} 中指定的额外参数。}

@function[(char* scheme_format_utf8
           [char* format]
           [int flen]
           [int argc]
           [Scheme_Object** argv]
           [intptr_t* rlen])]{

类似于 @cpp{scheme_format}，但接受一个 UTF-8 编码的字节字符串。}

@function[(void scheme_printf_utf8
           [char* format]
           [int flen]
           [int argc]
           [Scheme_Object** argv])]{

类似于 @cpp{scheme_printf}，但接受一个 UTF-8 编码的字节字符串。}

@function[(int scheme_close_should_force_port_closed)]{

此函数必须由通过 @cpp{scheme_make_output_port} 创建的端口的关闭函数调用。}
