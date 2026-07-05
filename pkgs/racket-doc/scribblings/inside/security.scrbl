#lang scribble/doc
@(require "utils.rkt")

@bc-title[#:tag "security"]{Security Guards}

在原始过程访问文件系统或创建网络连接之前，
它应首先咨询当前 security guard，以确定此类访问是否被允许用于当前线程。

文件访问之前通常调用 @cppi{scheme_expand_filename}，
它接受标志以指示所需的文件系统访问类型，从而自动咨询 security guard。

可以通过调用 @cpp{scheme_security_check_file} 进行显式的文件系统访问检查。
类似地，通过调用 @cpp{scheme_security_check_network} 进行显式的网络访问检查。

@; ----------------------------------------------------------------------


@function[(void scheme_security_check_file
           [const-char* who]
           [char* filename]
           [int guards])]{

咨询当前安全管理器以确定是否允许访问 @var{filename}。@var{guards} 参数应为以下各项的按位组合：

@itemize[

 @item{@cppi{SCHEME_GUARD_FILE_READ}}
 @item{@cppi{SCHEME_GUARD_FILE_WRITE}}
 @item{@cppi{SCHEME_GUARD_FILE_EXECUTE}}
 @item{@cppi{SCHEME_GUARD_FILE_DELETE}}
 @item{@cppi{SCHEME_GUARD_FILE_EXISTS}（请勿与其他值组合）}

]

@var{filename} 参数可以是 @cpp{NULL}（此时 @racket[#f] 被发送给安全管理器的过程），
在这种情况下 @var{guards} 应为 @cppi{SCHEME_GUARD_FILE_EXISTS}。

如果访问被拒绝，将引发异常。}


@function[(void scheme_security_check_network
           [const-char* who]
           [char* host]
           [int portno])]{

咨询当前安全管理器以确定是否允许创建到 @var{host} 端口号
 @var{portno} 的客户端连接。如果 @var{host} 是 @cpp{NULL}，
 则咨询安全管理器是否允许在端口号 @var{portno} 上创建服务器。

如果访问被拒绝，将引发异常。}
