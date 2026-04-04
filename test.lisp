
(ql:quickload '(:bordeaux-threads))

(defvar *game-lock*      (bt2:make-lock :name "GAME-LOCK"))
(defvar *game-condition* (bt2:make-condition-variable :name "GAME-COND"))

(defun invoke-game-test (data)
  (with-input-from-string (*standard-input* data)
    (values data
            ""
            0)))

(defun invoke-game (data)
  (with-input-from-string (*standard-input* data)
    (uiop:run-program (list #P"/bin/cat")
                      :input *standard-input*
                      :output 'cl:string
                      :error-output 'cl:string
                      :ignore-error-status t
                      :force-shell nil)))

(defun invoke-game-in-thread (game-fn data)
  (flet ((call-game ()
           (prog1
               (ignore-errors
                (funcall game-fn data))
             (format t "GAME-FN Done~%")
             (bt2:with-lock-held (*game-lock*)
               (format t "LOCK obtained~%")
               (bt2:condition-notify *game-condition*))
             (format t "NOTIFY sent~%"))))
    (bt2:make-thread #'call-game :name "GAME-THREAD")))

(defun invoke-game-with-timelimit (game-fn data wait-time-in-seconds)
  (bt2:with-lock-held (*game-lock*)
    (let ((thread (invoke-game-in-thread game-fn data)))
      (if (bt2:condition-wait *game-condition* *game-lock* :timeout wait-time-in-seconds)
          (bt2:join-thread thread)
          (error 'simple-error :format-control "TIMEOUT: ~A"
                               :format-arguments (list wait-time-in-seconds))))))


#+(or)
(invoke-game-test "abc")

#+(or)
(invoke-game "abc")

#+(or)
(invoke-game-with-timelimit #'invoke-game-test "abc" 3)

#+(or)
(invoke-game-with-timelimit #'invoke-game "abc" 3)
