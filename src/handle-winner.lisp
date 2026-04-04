(in-package :cl-nomic-supervisor)

(named-readtables:in-readtable :json-reader-macro)

(alexandria:define-constant +GAME-OVER-TAG+ "game-over"
  :test #'string=)

(defun handle-winner (name &optional message)
  (let* ((main-branch (get-branch-reference))
         (tag (create-commit-tag +GAME-OVER-TAG+
                                 {main-branch object sha}
                                 :message (format nil "Winner: ~A~%~%----~%~A~%~A~%"
                                                  name
                                                  (or message
                                                      "")
                                                  "Commited by CL-NOMIC-SUPERVISOR"))))
    (create-tag-reference +GAME-OVER-TAG+
                          {tag sha})
    :declared-winner))

(defun game-over-p ()
  "Try to retrieve for +GAME-OVER-TAG+ and return NIL if not found and non-NIL otherwise."
  (ignore-errors
   (get-tag-reference +GAME-OVER-TAG+)))
