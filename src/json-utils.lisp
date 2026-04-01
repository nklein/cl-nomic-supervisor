(in-package :cl-nomic-supervisor)

(deftype json-object ()
  'hash-table)

(defun json-parse (string-or-stream)
  (let ((yason:*parse-object-as* :hash-table)
        (yason:*parse-json-booleans-as-symbols* t)
        (yason:*parse-json-null-as-keyword* t))
    (yason:parse string-or-stream)))

(defparameter *json-indent* 2)

(defun json-encode (json-object &optional (stream *error-output*))
  (yason:with-output (stream :indent *json-indent*)
    (yason:encode json-object)))

(defun json-encode* (json-object)
  (yason:with-output-to-string* (:indent *json-indent*)
    (yason:encode json-object)))

(defun json-attr (name json-object &optional default)
  (gethash name json-object default))

(defun json-object (alist)
  (alexandria:alist-hash-table alist
                               :test 'equal))
