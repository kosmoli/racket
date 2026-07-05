#lang scribble/doc
@(require scribble/manual
          "com-common.rkt"
          (for-label racket/base
                     ffi/unsafe/com
                     xml))

@title[#:tag "active-x"]{ActiveX 控件}

ActiveX 控件是一个需要容器来管理其图形表示的 COM 对象。虽然 @racketmodname[ffi/com] 不直接提供对 ActiveX 控件的支持，但你可以用它驱动 Internet Explorer 来充当 ActiveX 容器。

以下代码演示了如何使用 Internet Explorer 来实例化 Windows 自带的 ``Sysmon'' ActiveX 控件。

@codeblock{
#lang racket
(require ffi/com
	 xml)

;; 我们要运行的控件：
(define control-progid "Sysmon")

;; 启动 IE：
(define ie (com-create-instance "InternetExplorer.Application.1"))

;; 设置一个事件回调，以便知道 initial document 何时就绪：
(define ex (com-make-event-executor))
(void (thread (lambda () (let loop () ((sync ex)) (loop)))))
(define ready (make-semaphore))
(com-register-event-callback ie "DocumentComplete"
                             (lambda (doc url) (semaphore-post ready))
                             ex)

;; Navigate 获取初始 document：
(com-invoke ie "Navigate" "about:blank")
(define READYSTATE_COMPLETE 4)
(unless (= (com-get-property ie "READYSTATE") READYSTATE_COMPLETE)
  (semaphore-wait ready))
(define doc (com-get-property ie "Document"))

;; 安装用于显示 ActiveX 控件的 HTML：
(com-invoke doc "write"
            (xexpr->string
             `(html
               (head (title "Demo"))
               (body
                (object ((class "object")
                         (CLASSID ,(format
                                    "CLSID:~a"
                                    (let ([s (guid->string
                                              (progid->clsid
                                               control-progid))])
                                      ;; 必须移除花括号：
                                      (define len
                                        (string-length s))
                                      (substring s 1 (sub1 len)))))))))))

;; 配置 IE 窗口并将其显示：
(com-set-property! ie "MenuBar" #f)
(com-set-property! ie "ToolBar" 0)
(com-set-property! ie "StatusBar" #f)
(com-set-property! ie "Visible" #t)

;; 从 IE document 中提取 ActiveX 控件：
(define ctl (com-get-property
	     (com-invoke (com-invoke doc "getElementsByTagName" "object")
                         "item"
                         0)
	     "object"))

;; 到此为止，`ctl` 就是 ActiveX 控件，
;; 演示：获取它的 method 名称列表：
(com-methods ctl)
}
