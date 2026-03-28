(in-package :cl-nomic-supervisor)

(defun %convert-path-as-list-to-encoded-path (path-as-list)
  (labels ((ensure-string (maybe-s)
             (if (typep maybe-s 'string)
                 maybe-s
                 (with-output-to-string (s)
                   (let ((*print-pretty* t))
                     (prin1 maybe-s s)))))
           (encode-segment (segment)
             (quri:url-encode (ensure-string segment))))
    (format nil "~:[/~;~0@*~{/~A~}~]" (mapcar #'encode-segment path-as-list))))
