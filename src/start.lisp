(in-package :cl-nomic-supervisor)

(defun find-augmented-by-id (id list-of-augmented)
  (flet ((get-augmented-id (augmented)
           #{augmented id}))
    (find id list-of-augmented
          :key #'get-augmented-id)))

(defun fetch-list-of-augmented ()
  (or #+(or) (with-open-file (*standard-input* #P"/tmp/sample.json")
               (json-parse *standard-input*))
      (get-all-augmented-pull-requests)))

(defun %start ()
  (let ((list-of-augmented (fetch-list-of-augmented)))
    (unless list-of-augmented
      (format *standard-output* "No open pull requests.~%")
      (return-from %start))

    (cli-chain
      (git-clone-repo-branch))

    (let ((response-string (with-output-to-string (*standard-output*)
                             (cli-chain
                               (invoke-game list-of-augmented)))))
      (handler-case
          (let* ((response (json-parse response-string))
                 (decision (ignore-errors
                            (string-downcase #{response decision}))))
            (json-encode response *debug-io*)
            (fresh-line *debug-io*)
            (cond
              ((string= "winner" decision)
               (handle-winner #{response name}
                              (ignore-errors #{response message})))
              ((string= "accept" decision)
               (handle-accept (find-augmented-by-id #{response id} list-of-augmented)
                              (ignore-errors #{response message})))
              ((string= "reject" decision)
               (handle-reject (find-augmented-by-id #{response id} list-of-augmented)))
              (t
               (handle-unknown response))))
        (error (err)
          (let ((*print-escape* nil))
            (format *error-output* "GOT: ~A~%" err))
          (error 'simple-error :format-control "Error handling: ~S~%"
                               :format-arguments (list response-string)))))))

(defun start ()
  (handler-case
      (let ((*git-repo-url* (uiop:getenv "GIT_REPO_URL"))
            (*git-default-branch* "main")
            (*git-default-remote* "origin")
            (*git-working-copy-dir* *game-directory*)
            (*github-api-token* (uiop:getenv "GITHUB_SUPERVISOR_TOKEN"))
            (*github-repo-owner* (uiop:getenv "GITHUB_REPO_OWNER"))
            (*github-repo-name* (uiop:getenv "GITHUB_REPO_NAME")))

        (or
            #+(or) (handle-accept (first (fetch-list-of-augmented)) "Testing accept of request")
            #+(or) (handle-reject (first (fetch-list-of-augmented)) "Testing reject of request")
            #+(or) (handle-winner "Patrick Stein <nklein>" "Yay!")
            #+(or) (let ((unknown (json-object `(("decision" . "foo")))))
                     (json-encode unknown *debug-io*)
                     (fresh-line *debug-io*)
                     (handle-unknown unknown))
            (if (game-over-p)
                (format *standard-output* "GAME-OVER: Nothing to do.~%")
                (%start))))
    (error (err)
      (let ((*print-escape* nil))
        (format *error-output* "ERROR: ~A~%" err)
        #+sbcl (sb-ext:exit :code 2 :abort t)))))
