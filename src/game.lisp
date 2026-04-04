(in-package :cl-nomic-supervisor)

(defparameter *game-directory* #P"/game/")

(defun invoke-game (list-of-augmented)
  (let ((encoded (json-encode* list-of-augmented)))
    (with-input-from-string (*standard-input* encoded)
      (uiop:run-program (list #P"/usr/bin/bwrap"
                              "--ro-bind" "/bin" "/bin"
                              "--ro-bind" "/lib" "/lib"
                              "--ro-bind" "/usr/bin" "/usr/bin"
                              "--ro-bind" "/usr/lib" "/usr/lib"
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
