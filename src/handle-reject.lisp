(in-package :cl-nomic-supervisor)

(named-readtables:in-readtable :json-reader-macro)

(defun handle-reject (augmented &optional message)
  (create-pull-request-comment {augmented pull_request number}
                               (or message
                                   "REJECTED"))
  (close-pull-request {augmented pull_request number})
  :something-changed)
