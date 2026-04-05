(in-package :cl-nomic-supervisor)

(named-readtables:in-readtable :json-reader-macro)

;;; How to rollback:
;;;   * tag HEAD as revert-{SHA-of-HEAD}
;;;   * create new commit with parent HEAD^ and tree same as HEAD^
;;;   * reset `heads/main` to point to new commit

(defun make-revert-name (original-sha)
  (format nil "revert-~A" (subseq original-sha 0 8)))

(defun rollback (response)
  (let* ((original-sha {(get-branch-reference) object sha})
         (tag-name (make-revert-name original-sha))
         (main-commit (get-commit original-sha))
         (main-commit-parent-sha {(first {main-commit parents}) sha})
         (tag-commit (create-commit-tag tag-name
                                        original-sha
                                        :message (format nil "Reverting: ~A (~A)~%~%~A~%----~%RESPONSE:~%~A~%~%----~%~A~%"
                                                         original-sha
                                                         tag-name
                                                         {main-commit message}
                                                         response
                                                         "Reverted by CL-NOMIC-SUPERVISOR"))))
    (create-tag-reference tag-name {tag-commit sha})
    (update-branch-reference *git-default-branch*
                             {(get-commit main-commit-parent-sha) sha})))

(defun handle-unknown (response)
  (format *error-output* "Unknown response: ~A~%Rolling back~%" response)
  (rollback response)
  :something-changed)
