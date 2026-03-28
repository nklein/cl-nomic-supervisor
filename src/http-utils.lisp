(in-package :cl-nomic-supervisor)

(defun attr (name json-object)
  (cdr (assoc name json-object
              :test #'string=)))

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

(%convert-path-as-list-to-encoded-path '())
(%convert-path-as-list-to-encoded-path '("foo"))
(%convert-path-as-list-to-encoded-path '("foo" "bar" "baz"))
(%convert-path-as-list-to-encoded-path '("foo" "this has spaces" "and punctuation, no?"))
(%convert-path-as-list-to-encoded-path '("foo" 3 5))
