(in-package :cl-nomic-supervisor)

(defun handle-accept (augmented &optional message)
  (format t "ACCEPT: ~A ~A~%" #{augmented id} message))
