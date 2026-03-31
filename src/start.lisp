(in-package :cl-nomic-supervisor)

(defun find-augmented-by-id (id list-of-augmented)
  (flet ((get-augmented-id (augmented)
           #{augmented id}))
    (find id list-of-augmented
          :key #'get-augmented-id)))

(defun %start ()
  (let ((list-of-augmented (or (with-open-file (*standard-input* #P"/tmp/sample.json")
                                 (json-parse *standard-input*))
                               (get-all-augmented-pull-requests))))
    (when list-of-augmented
      (cli-chain
        (git-clone-repo-branch))
      (let ((response-string (with-output-to-string (*standard-output*)
                               (cli-chain
                                 (invoke-game list-of-augmented)))))
        (handler-case
            (let* ((response (json-parse response-string))
                   (decision (string-downcase #{response decision})))
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
                                 :format-arguments (list response-string))))))))

(defun start ()
  (handler-case
      (let ((*git-repo-url* (uiop:getenv "GIT_REPO_URL"))
            (*git-default-branch* "main")
            (*git-default-remote* "origin")
            (*git-working-copy-dir* *game-directory*)
            (*github-api-token* (uiop:getenv "GITHUB_SUPERVISOR_TOKEN"))
            (*github-repo-owner* (uiop:getenv "GITHUB_REPO_OWNER"))
            (*github-repo-name* (uiop:getenv "GITHUB_REPO_NAME")))
        (%start))
    (error (err)
      (let ((*print-escape* nil))
        (format *error-output* "ERROR: ~A~%" err)
        #+sbcl (sb-ext:exit :code 2 :abort t)))))
