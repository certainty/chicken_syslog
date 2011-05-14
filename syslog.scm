;;; syslog.scm --- 
;; 
;; Filename: syslog.scm
;; Description: 
;; Author: David Krentzlin <david@lisp-unleashed.de>
;; Maintainer: 
;; Created: Do Sep  3 20:40:28 2009 (CEST)
;; Version: $Id$
;; Version: 
;; Last-Updated: Sa Sep  5 23:13:45 2009 (CEST)
;;           By: David Krentzlin <david@lisp-unleashed.de>
;;     Update #: 140
;; URL: 
;; Keywords: 
;; Compatibility: 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Commentary: 
;; 
;; 
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Change log:
;; 
;; 
;; RCS $Log$
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; Copyright (c) <2009> David Krentzlin <david@lisp-unleashed.de>
;; 
;;   Permission is hereby granted, free of charge, to any person
;;   obtaining a copy of this software and associated documentation
;;   files (the "Software"), to deal in the Software without
;;   restriction, including without limitation the rights to use,
;;   copy, modify, merge, publish, distribute, sublicense, and/or sell
;;   copies of the Software, and to permit persons to whom the
;;   Software is furnished to do so, subject to the following
;;   conditions:
;; 
;;   The above copyright notice and this permission notice shall be
;;   included in all copies or substantial portions of the Software.
;; 
;;   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;   EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
;;   OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;   NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;   HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;   WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;;   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;;   OTHER DEALINGS IN THE SOFTWARE.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Code:


(module syslog
  (syslog openlog setlogmask closelog log-up-to log-mask
          
   prio/info prio/emerg prio/alert prio/crit
   prio/err prio/warning prio/notice prio/debug
   
   opt/ndelay opt/cons opt/perror opt/pid
   
   facility/auth facility/authpriv facility/cron
   facility/daemon facility/ftp facility/kern
   facility/mail facility/news facility/syslog
   facility/lpr
  
   facility/user facility/uucp facility/local0
   facility/local1 facility/local2 facility/local3
   facility/local4 facility/local5 facility/local6
   facility/local7)
  
  (import chicken scheme foreign)
  (require-library extras)
  (import (only extras sprintf))

  (foreign-declare #<<EOC
#include <syslog.h>

 #ifndef LOG_FTP
  #define LOG_FTP LOG_DAEMON
 #endif

 #ifndef LOG_AUTHPRIV
  #define LOG_AUTHPRIV LOG_AUTH
 #endif

 #ifndef LOG_SYSLOG
   #define LOG_SYSLOG LOG_DAEMON
 #endif

EOC
)


  (define-syntax define-log-constant
    (lambda (exp rename compare)
      (let* ((ident (cadr exp))
             (foreign-name (caddr exp))
             (internal-ident (string->symbol (conc "_" (symbol->string ident))))
             (%define-foreign-variable (rename 'define-foreign-variable))
             (%begin (rename 'begin))
             (%define (rename 'define)))
        `(,%begin
          (,%define-foreign-variable ,internal-ident int ,foreign-name)
          (,%define ,ident ,internal-ident)))))

  ;;log levels 
  (define-log-constant prio/info         "LOG_INFO")  
  (define-log-constant prio/emerg        "LOG_EMERG")
  (define-log-constant prio/alert        "LOG_ALERT")
  (define-log-constant prio/crit         "LOG_CRIT")
  (define-log-constant prio/err          "LOG_ERR")
  (define-log-constant prio/warning      "LOG_WARNING")
  (define-log-constant prio/notice       "LOG_NOTICE")
  (define-log-constant prio/debug        "LOG_DEBUG")

  ;;options for openlog
  ;;combinations are or'ed together
  ;;unportable options are left out
  (define-log-constant opt/cons           "LOG_CONS")
  (define-log-constant opt/ndelay         "LOG_NDELAY")
  (define-log-constant opt/perror         "LOG_PERROR")
  (define-log-constant opt/pid            "LOG_PID")

  ;;facility-constants
  (define-log-constant facility/auth      "LOG_AUTH")  
  (define-log-constant facility/cron      "LOG_CRON")
  (define-log-constant facility/daemon    "LOG_DAEMON")
  (define-log-constant facility/kern      "LOG_KERN")
  (define-log-constant facility/lpr       "LOG_LPR")
  (define-log-constant facility/mail      "LOG_MAIL")
  (define-log-constant facility/news      "LOG_NEWS")
  (define-log-constant facility/user      "LOG_USER")
  (define-log-constant facility/uucp      "LOG_UUCP")
  (define-log-constant facility/local0    "LOG_LOCAL0")
  (define-log-constant facility/local1    "LOG_LOCAL1")
  (define-log-constant facility/local2    "LOG_LOCAL2")
  (define-log-constant facility/local3    "LOG_LOCAL3")
  (define-log-constant facility/local4    "LOG_LOCAL4")
  (define-log-constant facility/local5    "LOG_LOCAL5")
  (define-log-constant facility/local6    "LOG_LOCAL6")
  (define-log-constant facility/local7    "LOG_LOCAL7")

  ; solaris lacks this
  ; mapped to auth
  (define-log-constant facility/authpriv  "LOG_AUTHPRIV")
  
 
  ; syslog-internal facility
  ; not portable
  ; mapped to daemon on solaris
  (define-log-constant facility/syslog    "LOG_SYSLOG")
  
  ;not portable only freebsd and mac os
  ;(define-log-constant facility/security  "LOG_SECURITY")

  ; solaris doesn't have this
  ; mapped to daemon here
  (define-log-constant facility/ftp       "LOG_FTP")
  
  ;not portable
  ;(define-log-constant facility/console   "LOG_CONSOLE")

  (define openlog
    (foreign-lambda void "openlog" c-string int int))

  (define closelog
    (foreign-lambda void "closelog"))
  
  (define (syslog priority fmt . args)
    ((foreign-lambda* void ((int prio) (c-string msg)) "syslog(prio,\"%s\",msg);") priority (apply sprintf fmt args)))

  (define setlogmask
    (foreign-lambda int "setlogmask" int))


  ;;LOG_UPTO is only some bitshifting but
  ;;it may be implemented differently
  ;;that's why  i don't implement it in scheme but wrap it
  ;;into a function instead
  (define log-up-to
    (foreign-lambda* int ((int topprio)) "C_return(LOG_UPTO(topprio));"))
  
  (define (log-mask priority)
    (foreign-lambda* int ((int priority)) "C_return(LOG_MASK(priority));"))

)




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; syslog.scm ends here
