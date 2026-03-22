;;;; nomic-supervisor.asd

(asdf:defsystem #:cl-nomic-supervisor
  :description "CL-NOMIC-SUPERVISOR"
  :author "Patrick Stein <pat@nklein.com>"
  :license "UNLICENSE"
  :version "0.1.20260322"
  :depends-on ()
  :components
  ((:static-file "README.md")
   (:static-file "UNLICENSE.txt")
   (:module "src"
    :components ((:file "package")
                 (:file "start" :depends-on ("package"))))))
