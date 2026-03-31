(in-package :cl-nomic-supervisor)

(defun handle-accept (augmented &optional message)
  (format t "ACCEPT: ~A ~A~%" #{augmented id} message)
  ;; TODO: merge the #{augmented pull_request id}
  )
