;;;; nomic-supervisor.asd

#-asdf
(require "asdf")
(cl:load "./quicklisp/bundle.lisp")

(asdf:defsystem #:cl-nomic-supervisor
  :description "CL-NOMIC-SUPERVISOR"
  :author "Patrick Stein <pat@nklein.com>"
  :license "UNLICENSE"
  :version "0.1.20260322"
  :depends-on (:yason #+(or) :dexador)
  :components
  ((:static-file "README.md")
   (:static-file "UNLICENSE.txt")
   (:module "src"
    :components ((:file "package")
                 (:file "cli" :depends-on ("package"))
                 (:file "git-cli" :depends-on ("package"
                                               "cli"))
                 (:file "start" :depends-on ("package"))))))
