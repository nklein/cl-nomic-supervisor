;;;; nomic-supervisor.asd

#-asdf
(require "asdf")
(cl:load "./quicklisp/bundle.lisp")

(asdf:defsystem #:cl-nomic-supervisor
  :description "CL-NOMIC-SUPERVISOR"
  :author "Patrick Stein <pat@nklein.com>"
  :license "UNLICENSE"
  :version "0.1.20260322"
  :depends-on (:alexandria :quri :local-time :yason :dexador :toot)
  :components
  ((:static-file "README.md")
   (:static-file "UNLICENSE.txt")
   (:module "src"
    :components ((:file "package")
                 (:file "cli" :depends-on ("package"))
                 (:file "git-cli" :depends-on ("package"
                                               "cli"))
                 (:file "http-constants" :depends-on ("package"))
                 (:file "http-utils" :depends-on ("package"))
                 (:file "json-utils" :depends-on ("package"))
                 (:file "reader-macro" :depends-on ("package"
                                                    "json-utils"))
                 (:file "github-api" :depends-on ("package"
                                                  "http-constants"
                                                  "http-utils"
                                                  "json-utils"))
                 (:file "start" :depends-on ("package"
                                             "github-api"))))))
