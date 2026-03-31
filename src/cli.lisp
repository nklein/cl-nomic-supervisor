(in-package :cl-nomic-supervisor)

(defun cli-command (command &rest arguments)
  (uiop:run-program (list* command
                           arguments)
                    :output 'cl:string
                    :error-output 'cl:string
                    :force-shell nil))

(defmacro relay-output (() &body cmd)
  (let ((output (gensym "OUTPUT-"))
        (error-output (gensym "ERROR-OUTPUT-"))
        (code (gensym "CODE-")))
    `(multiple-value-bind (,output ,error-output ,code) ,@cmd
       (let ((*print-pretty* t))
         (when ,error-output
           (princ ,error-output *error-output*)
           (fresh-line *error-output*))
         (when ,output
           (princ ,output *standard-output*)
           (fresh-line *standard-output*)))
       (unless (zerop ,code)
         (error 'simple-error
                :format-control "Exit code ~A for ~S"
                :format-arguments (list ,code ',@cmd)))
       t)))

(defmacro cli-chain (&body commands)
  (flet ((wrap-cli-chain-cmd (cmd)
           `(relay-output ()
              ,cmd)))
    `(and ,@(mapcar #'wrap-cli-chain-cmd commands))))

#+(or)
(cli-chain
  (cli-command "/bin/echo" "Hello world")
  (cli-command "/usr/bin/true")
  (cli-command "/bin/echo" "Done"))
