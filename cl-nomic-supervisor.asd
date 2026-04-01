;;;; nomic-supervisor.asd

#-asdf
(require "asdf")
(cl:load "./quicklisp/bundle.lisp")

(asdf:defsystem #:cl-nomic-supervisor
  :description "CL-NOMIC-SUPERVISOR"
  :author "Patrick Stein <pat@nklein.com>"
  :license "UNLICENSE"
  :version "0.1.20260322"
  :depends-on (:alexandria :quri :local-time :yason :dexador)
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
                                                  "json-utils"
                                                  "git-cli"))
                 (:file "game" :depends-on ("package"))
                 (:file "handle-winner" :depends-on ("package"
                                                     "github-api"))
                 (:file "handle-accept" :depends-on ("package"
                                                     "github-api"))
                 (:file "handle-reject" :depends-on ("package"
                                                     "github-api"))
                 (:file "handle-defer" :depends-on ("package"))
                 (:file "handle-unknown" :depends-on ("package"
                                                      "github-api"))
                 (:file "start" :depends-on ("package"
                                             "cli"
                                             "github-api"
                                             "handle-winner"
                                             "handle-accept"
                                             "handle-reject"
                                             "handle-defer"
                                             "handle-unknown"
                                             "game"))))))
