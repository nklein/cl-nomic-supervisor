;;; reader-macro.lisp

(in-package :cl-nomic-supervisor)

(defparameter *json-readtable* (copy-readtable))
(setf (readtable-case *json-readtable*) :preserve)
(set-macro-character #\} (get-macro-character #\) *readtable*) nil *json-readtable*)

(set-dispatch-macro-character #\# #\{
                              #'(lambda (stream subchar arg)
                                  (declare (ignore subchar arg))
                                  (labels ((read-a-string (&optional (stream *standard-input*))
                                             (coerce (loop
                                                       :for c := (peek-char nil stream nil nil)
                                                       :until (or (not c)
                                                                  (char= c #\Space)
                                                                  (char= c #\Tab)
                                                                  (char= c #\Newline)
                                                                  (char= c #\}))
                                                       :collecting (read-char stream t nil t))
                                                     'string))

                                           (split-symbol (sym parts)
                                              (let ((pos (position #\. sym)))
                                               (cond
                                                 ((not pos)
                                                  (nreverse (list* sym parts)))
                                                 (t
                                                  (split-symbol (subseq sym (1+ pos))
                                                                (list* (subseq sym 0 pos)
                                                                       parts))))))

                                           (build-attr-path-form (attrs arg)
                                             (cond
                                               (attrs
                                                (destructuring-bind (attr &rest attrs) attrs
                                                  (list 'json-attr
                                                        attr
                                                        (build-attr-path-form attrs arg))))
                                               (t
                                                arg))))
                                    (let ((path (split-symbol (read-a-string stream)
                                                              nil))
                                          (arg (let ((*readtable* *json-readtable*))
                                                 (read stream t nil t)))
                                          (closer (read-char stream t nil t)))
                                      (assert (char= closer #\}))
                                      (build-attr-path-form (reverse path) arg)))))

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
