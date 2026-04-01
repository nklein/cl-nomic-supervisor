(in-package :cl-nomic-supervisor)

(defun handle-accept (augmented &optional message)
  (merge-pull-request #{augmented pull_request number}
                      #{augmented pull_request title}
                      (format nil "~A~%~%----~%~A~%~A~%"
                              (let ((pr-body #{augmented pull_request body}))
                                (if (not (eql pr-body :null))
                                    pr-body
                                    ""))
                              (or message
                                  "")
                              "Commited by CL-NOMIC-SUPERVISOR")))
