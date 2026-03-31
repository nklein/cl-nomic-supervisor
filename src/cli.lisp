(in-package :cl-nomic-supervisor)

(defun cli-command (command &rest arguments)
  (uiop:run-program (list* command
                           arguments)
                    :output 'cl:string
                    :error-output 'cl:string
                    :ignore-error-status t
                    :force-shell nil))

(defmacro cli-chain (&body commands)
  (let ((output-accum (gensym "OUTPUT-ACCUM-"))
        (error-output-accum (gensym "ERROR-OUTPUT-ACCUM"))
        (output (gensym "OUTPUT-"))
        (error-output (gensym "ERROR-OUTPUT-"))
        (return-code (gensym "RETURN-CODE-")))
    (labels ((return-values (return-code cmd-form)
               `(values (nreverse ,output-accum)
                        (nreverse ,error-output-accum)
                        ,return-code
                        ',cmd-form))

             (verify-successful-command (cmd-form)
               `(multiple-value-bind (,output ,error-output ,return-code)
                    ,cmd-form
                  (push ,output ,output-accum)
                  (push ,error-output ,error-output-accum)
                  (unless (zerop ,return-code)
                    (return ,(return-values return-code
                                            cmd-form))))))
      `(let ((,output-accum)
             (,error-output-accum))
         (block nil
           ,@(mapcar #'verify-successful-command commands)
           ,(return-values 0 nil))))))

#+(or)
(cli-chain
  (cli-command "/bin/echo" "Hello world")
  (cli-command "/usr/bin/false")
  (cli-command "/bin/echo" "Done"))
