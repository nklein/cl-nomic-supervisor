(in-package :cl-nomic-supervisor)

(named-readtables:in-readtable :json-reader-macro)

(alexandria:define-constant +MAXIMUM-GAME-RUNTIME-IN-SECONDS+ 60)

(defun force-mode-p ()
  (let ((force (uiop:getenv "FORCE")))
    (and force
         (string/= force "")
         (string/= force "0"))))

(defun should-run-p (list-of-augmented)
  (cond
    ((game-over-p)
     (format *standard-output* "GAME-OVER: Nothing to do.~%")
     nil)

    ((and (force-mode-p)
          (null list-of-augmented))
     (format *standard-output* "Running anyway even though there are no pull-requests~%")
     t)

    ((null list-of-augmented)
     (format *standard-output* "No open pull requests.~%")
     nil)

    (t
     t)))

(defun find-augmented-by-id (id list-of-augmented)
  (flet ((get-augmented-id (augmented)
           {augmented id}))
    (find id list-of-augmented
          :key #'get-augmented-id)))

(defun fetch-list-of-augmented ()
  (or #+(or) (with-open-file (*standard-input* #P"/tmp/sample.json")
               (json-parse *standard-input*))
      (get-all-augmented-pull-requests)))

(defun freshly-fetch-game-code ()
  (cli-chain
    (cli-command "/bin/rm" "-rf" (namestring *git-working-copy-dir*))
    (cli-command "/bin/mkdir" "-p" (namestring *git-working-copy-dir*))
    (git-clone-repo-branch)))

(defun do-pass ()
  (let ((list-of-augmented (fetch-list-of-augmented)))
    (unless (should-run-p list-of-augmented)
      (return-from do-pass :nothing-changed))

    (freshly-fetch-game-code)

    (let* ((response-string (invoke-game-with-timelimit list-of-augmented
                                                        +MAXIMUM-GAME-RUNTIME-IN-SECONDS+))
           (response (ignore-errors
                      (json-parse response-string)))
           (decision (ignore-errors
                      (string-downcase {response decision}))))
      (when response
        (json-encode response *debug-io*)
        (fresh-line *debug-io*))
      (cond
        ((string= "winner" decision)
         (handle-winner {response name}
                        (ignore-errors {response message})))
        ((string= "accept" decision)
         (handle-accept (find-augmented-by-id {response id} list-of-augmented)
                        (ignore-errors {response message})))
        ((string= "reject" decision)
         (handle-reject (find-augmented-by-id {response id} list-of-augmented)))
        ((string= "defer" decision)
         (handle-defer))
        (t
         (handle-unknown response-string))))))

(defun safely-do-pass ()
  (handler-case
      (or
       #+(or) (handle-accept (first (fetch-list-of-augmented)) "Testing accept of request")
       #+(or) (handle-reject (first (fetch-list-of-augmented)) "Testing reject of request")
       #+(or) (handle-winner "Patrick Stein <nklein>" "Yay!")
       #+(or) (let ((unknown (json-object `(("decision" . "foo")))))
                (json-encode unknown *debug-io*)
                (fresh-line *debug-io*)
                (handle-unknown unknown))
       (do-pass))
    (error (err)
      (handle-unknown (let ((*print-escape* nil))
                        (format nil "ERROR: ~A~%" err)))
      :something-errored)))

(defun start ()
  (let ((*git-working-copy-dir* *game-directory*)
        (*github-api-token* (uiop:getenv "GITHUB_SUPERVISOR_TOKEN"))
        (*github-repo-owner* (uiop:getenv "GITHUB_REPO_OWNER"))
        (*github-repo-name* (uiop:getenv "GITHUB_REPO_NAME")))
    (let ((*git-repo-url* (or (uiop:getenvp "GITHUB_REPO_URL")
                              (format nil "https://github.com/~A/~A.git"
                                      *github-repo-owner*
                                      *github-repo-name*)))
          (*git-default-branch* (or (uiop:getenvp "GITHUB_REPO_BRANCH")
                                    "main"))
          (*git-default-remote* "origin"))
      (uiop:quit (case (safely-do-pass)
                   (:nothing-changed   0)
                   (:declared-winner   0)
                   (:something-changed 1)
                   (otherwise          2))))))
