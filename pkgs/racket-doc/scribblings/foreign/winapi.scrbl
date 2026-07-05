#lang scribble/doc
@(require "utils.rkt" (for-label ffi/winapi))

@title[#:tag "winapi"]{Windows API 帮助}

@defmodule[ffi/winapi]

@defthing[win64? boolean?]{

指示当前平台是否为 64 位 Windows：是则 @racket[#t]，否则 @racket[#f]。}


@defthing[winapi (or/c 'stdcall 'default)]{

适合作为 Windows API 函数的 ABI 规范：32 位 Windows 用 @racket['stdcall]，
64 位 Windows 或其他平台用 @racket['default]。}
