(in-package :cl-nomic-supervisor)

(defvar *game-directory* #P"/game/")

(defparameter *game-lock* (bt2:make-lock :name "GAME-LOCK"))
(defparameter *game-condition* (bt2:make-condition-variable :name "GAME-COND"))

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

(defun invoke-game-test (list-of-augmented)
  list-of-augmented)

(defun invoke-game-in-thread (list-of-augmented)
  (flet ((call-game ()
           (prog1
               (ignore-errors
                (with-output-to-string (*standard-output*)
                  (cli-chain
                    (invoke-game list-of-augmented))))
             (bt2:with-lock-held (*game-lock*)
               (bt2:condition-notify *game-condition*)))))
    (bt2:make-thread #'call-game :name "GAME-THREAD")))

(defun invoke-game-with-timelimit (list-of-augmented wait-time-in-seconds)
  (bt2:with-lock-held (*game-lock*)
    (let ((thread (invoke-game-in-thread list-of-augmented)))
      (sleep 2) ; this is a hack to keep SBCL from deadlocking on me
       (if (bt2:condition-wait *game-condition* *game-lock* :timeout wait-time-in-seconds)
          (bt2:join-thread thread)
          (progn
            (ignore-errors
             (bt2:destroy-thread thread))
            (error 'simple-error :format-control "TIMEOUT: ~A"
                                 :format-arguments (list wait-time-in-seconds)))))))

#+(or)
(invoke-game-with-timelimit '(:a :b :c) 3)
