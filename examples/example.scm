;; 
;; %%HEADER%%
;; 

(use syslog)

;; please check your logs

(syslog prio/info "This is a test")
(syslog prio/info "A test with a format. ~A bottles of beer" 99)

(openlog "SYSLOG-EGG-TEST" opt/ndelay facility/local0)

(syslog prio/info "ANOTHER TEST")
(syslog prio/info "A test with a format. ~A bottles of beer" 100)
