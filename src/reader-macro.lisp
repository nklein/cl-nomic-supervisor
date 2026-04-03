;;; reader-macro.lisp

(in-package :cl-nomic-supervisor)

(named-readtables:defreadtable :json-readtable
  (:merge :current)
  (:case :preserve)

  (:macro-char #\} (get-macro-character #\))))

(named-readtables:defreadtable :json-reader-macro
  (:merge :current)
  (:macro-char #\{
               #'(lambda (stream char)
                   (declare (ignore char))
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
                           (path (let ((*readtable* (named-readtables:find-readtable :json-readtable)))
                                   (read-delimited-list #\} stream t))))
                       (build-attr-path-form (reverse path) obj))))))
