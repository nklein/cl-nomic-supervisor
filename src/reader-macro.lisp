;;; reader-macro.lisp

(in-package :cl-nomic-supervisor)

(defparameter *json-readtable* (copy-readtable))
(setf (readtable-case *json-readtable*) :preserve)
(set-macro-character #\} (get-macro-character #\) *readtable*) nil *json-readtable*)

(set-dispatch-macro-character #\# #\{
                              #'(lambda (stream subchar arg)
                                  (declare (ignore subchar arg))
                                  (labels ((build-attr-path-form (attrs arg)
                                             (cond
                                               (attrs
                                                (destructuring-bind (attr &rest attrs) attrs
                                                  (list 'json-attr
                                                        (symbol-name attr)
                                                        (build-attr-path-form attrs arg))))
                                               (t
                                                arg))))
                                    (let ((obj (read stream t nil t))
                                          (path (let ((*readtable* *json-readtable*))
                                                  (read-delimited-list #\} stream t))))
                                      (build-attr-path-form (reverse path) obj)))))

#+(or)
(let ((obj (json-parse "{abc: {def: {ghi: 3}}}")))
  #{obj abc def ghi})
