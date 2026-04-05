(in-package :cl-nomic-supervisor)

(named-readtables:in-readtable :json-reader-macro)

;;; How to rollback:
;;;   * tag HEAD as revert-{SHA-of-HEAD}
;;;   * create new commit with parent HEAD^ and tree same as HEAD^
;;;   * reset `heads/main` to point to new commit

(defun make-revert-name (original-sha)
  (format nil "revert-~A" (subseq original-sha 0 8)))

(defun rollback (response)
  (let* ((main-branch (get-branch-reference))
         (original-sha {main-branch object sha})
         (tag-name (make-revert-name original-sha))
         (tag (create-tag-reference tag-name original-sha))
         (main-commit (get-commit original-sha))
         (main-commit-parent-sha {(first {main-commit parents}) sha})
         (parent-commit (get-commit main-commit-parent-sha))
         (new-commit (create-commit (format nil "Reverting: ~A (~A)~%~%~A~%----~%RESPONSE:~%~A~%~%----~%~A~%"
                                            original-sha
                                            tag-name
                                            {main-commit message}
                                            response
                                            "Reverted by CL-NOMIC-SUPERVISOR")
                                    {parent-commit sha}
                                    {parent-commit tree sha})))
    (declare (ignore tag))
    (update-branch-reference *git-default-branch* {new-commit sha})))

(defun handle-unknown (response)
  (format *error-output* "Unknown response: ~A~%Rolling back~%" response)
  (rollback response)
  :something-changed)
