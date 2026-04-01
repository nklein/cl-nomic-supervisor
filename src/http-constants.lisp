(in-package :cl-nomic-supervisor)

(alexandria:define-constant +HTTP-SUCCESS+ 200)

(alexandria:define-constant +GET+ "GET" :test #'string=)
(alexandria:define-constant +POST+ "POST" :test #'string=)
(alexandria:define-constant +PUT+ "PUT" :test #'string=)
(alexandria:define-constant +PATCH+ "PATCH" :test #'string=)
(alexandria:define-constant +DELETE+ "DELETE" :test #'string=)
