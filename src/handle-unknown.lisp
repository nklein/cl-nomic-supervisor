(in-package :cl-nomic-supervisor)

(defun handle-unknown (response)
  (format *error-output* "UNKNOWN-MESSAGE: ~A~%" response)
  nil)
