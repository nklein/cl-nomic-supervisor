(in-package :cl-nomic-supervisor)

(defun handle-unknown (response)
  (error 'simple-error
         :format-control "UNKNOWN-MESSAGE: ~A~%"
         :format-arguments (list response)))
