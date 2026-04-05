(in-package :cl-nomic-supervisor)

(named-readtables:in-readtable :json-reader-macro)

(defun handle-accept (augmented &optional message)
  (handler-case
      (progn
        (merge-pull-request {augmented pull_request number}
                            {augmented pull_request title}
                            (format nil "~A~%~%----~%~A~%~A~%"
                                    (let ((pr-body {augmented pull_request body}))
                                      (if (not (eql pr-body :null))
                                          pr-body
                                          ""))
                                    (or message
                                        "")
                                    "Commited by CL-NOMIC-SUPERVISOR"))
        :something-changed)
    (error (err)
      (let ((*print-escape* nil))
        (format *error-output* "FAILED MERGE: ~A~%" err)
        (handle-reject augmented (format nil "FAILED MERGE: ~A~%" err))))))
