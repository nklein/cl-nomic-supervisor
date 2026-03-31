(in-package :cl-nomic-supervisor)

(defun handle-unknown (response)
  (format t "UNKNOWN: ~A~%" (json-encode* response)))
