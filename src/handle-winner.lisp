(in-package :cl-nomic-supervisor)

(defun handle-winner (name &optional message)
  (format t "WINNER: ~A ~A~%" name message))
