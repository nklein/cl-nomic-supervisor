(in-package :cl-nomic-supervisor)

(defun handle-reject (augmented &optional message)
  (format t "REJECT: ~A ~A~%" #{augmented id} message))
