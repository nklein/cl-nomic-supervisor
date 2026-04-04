(in-package :cl-nomic-supervisor)

(named-readtables:in-readtable :json-reader-macro)

(defun handle-reject (augmented &optional message)
  (close-pull-request {augmented pull_request number}
                      :additional `(("title" . ,(format nil "REJECTED: ~A~%" {augmented pull_request title}))
                                    ("body" . ,(format nil "~A~%~%----~%~A~%~A~%"
                                                       (if (not (eql {augmented pull_request body} :null))
                                                           {augmented pull_request body}
                                                           "")
                                                       (or message
                                                           "")
                                                       "Commited by CL-NOMIC-SUPERVISOR"))))
  :something-changed)
