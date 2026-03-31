(in-package :cl-nomic-supervisor)

(defparameter *game-directory* #P"/game/")

(defun invoke-game (list-of-augmented)
  (let ((encoded (with-output-to-string (*standard-output*)
                   (json-encode list-of-augmented *standard-output*))))
    (with-input-from-string (*standard-input* encoded)
      (uiop:run-program (list #P"/usr/bin/bwrap"
                              "--ro-bind" "/bin" "/bin"
                              "--ro-bind" "/lib" "/lib"
                              "--ro-bind" "/usr/bin" "/usr/bin"
                              "--ro-bind" "/usr/local" "/usr/local"
                              "--bind" "/game" "/game"
                              "--unshare-all"
                              "--unshare-user"
                              "--uid" "1001"
                              "--gid" "1001"
                              "--hostname" "nomic-game"
                              "--chdir" "/game"
                              "--clearenv"
                              "--setenv" "HOME" "/game"
                              "--setenv" "PATH" "/bin:/usr/bin:/usr/local/bin"
                              "--new-session"
                              "/game/start.sh")
                        :input *standard-input*
                        :output 'cl:string
                        :error-output 'cl:string
                        :ignore-error-status t
                        :force-shell nil))))

(defun %start ()
  (let ((list-of-augmented (or (with-open-file (*standard-input* #P"/tmp/sample.json")
                                 (json-parse *standard-input*))
                               (get-all-augmented-pull-requests))))
    (when list-of-augmented
      (cli-chain
        (git-clone-repo-branch)
        (invoke-game list-of-augmented)))))

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
