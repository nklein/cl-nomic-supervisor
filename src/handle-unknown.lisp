(in-package :cl-nomic-supervisor)

(defun handle-unknown (response)
  (format t "UNKNOWN: ~A~%" (json-encode* response))
  ;; TODO: revert last commit with some message?
  )
