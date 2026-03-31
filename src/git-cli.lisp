(in-package :cl-nomic-supervisor)

(defparameter *git-repo-url* nil)
(defparameter *git-default-branch* "main")
(defparameter *git-default-remote* "origin")
(defparameter *git-working-copy-dir* nil)
(defparameter *git-merge-branch* nil)

(defun %git-command (command &rest args)
  (apply #'cli-command `(,#P"/usr/bin/git"
                         ,@(when *git-working-copy-dir*
                             (list "-C" (namestring *git-working-copy-dir*)))
                         ,command
                         ,@args)))

(defun git-clone-repo-branch (&key
                                (repo-url *git-repo-url*)
                                (branch-name *git-default-branch*)
                                (destination *git-working-copy-dir*))
  (check-type repo-url string)
  (check-type branch-name string)
  (check-type destination (or pathname string))

  (let ((*git-working-copy-dir* nil))
    (%git-command "clone"
                  "--single-branch"
                  "--tags"
                  "--branch" branch-name
                  repo-url
                  (namestring destination))))

(defun git-fetch-branch (&key
                           (remote-name *git-default-remote*)
                           (branch-name *git-merge-branch*))
  (check-type remote-name string)
  (check-type branch-name string)

  (%git-command "fetch"
                remote-name
                branch-name))

(defun git-branch-from-ref-spec (&key
                                   (branch-name *git-merge-branch*)
                                   (ref-spec "FETCH_HEAD"))
  (check-type branch-name string)
  (check-type ref-spec string)

  (%git-command "branch"
                branch-name
                ref-spec))

(defun git-merge (&key
                    (branch-name *git-merge-branch*))
  (check-type branch-name string)

  (%git-command "merge"
                "--no-ff"
                "--no-edit"
                branch-name))

(defun git-push-merged-to-remote (&key
                                    (remote-name *git-default-remote*)
                                    (branch-name *git-default-branch*))
  (check-type remote-name string)
  (check-type branch-name string)

  (%git-command "push"
                remote-name
                branch-name))

(defun git-delete-branch (&key
                            (branch-name *git-merge-branch*))
  (check-type branch-name string)

  (%git-command "branch"
                "-d"
                branch-name))

(defun git-delete-branch-from-remote (&key
                                        (remote-name *git-default-remote*)
                                        (branch-name *git-merge-branch*))
  (check-type remote-name string)
  (check-type branch-name string)

  (%git-command "push"
                remote-name
                "--delete"
                branch-name))

#+(or)
(let ((*git-repo-url* "/Users/pat/src/cl-nomic/test-repo-clone")
      (*git-default-branch* "develop")
      (*git-working-copy-dir* "/tmp/nt/")
      (*git-merge-branch* "check-winner-in-start"))
  (progn
    (uiop:delete-directory-tree (pathname *git-working-copy-dir*)
                                :validate t
                                :if-does-not-exist :ignore)
    (cli-chain
      (git-clone-repo-branch)
      (git-fetch-branch)
      (git-branch-from-ref-spec)
      (git-merge)
      (git-delete-branch)
      (git-push-merged-to-remote)
      (git-delete-branch-from-remote)
      (cli-command "/usr/local/bin/sbcl"
                   "--noinform"
                   "--load" (namestring (merge-pathnames "cl-nomic-test.asd"
                                                         *git-working-copy-dir*))
                   "--eval" "(asdf:compile-system :cl-nomic-test)"
                   "--quit")
      (cli-command "/usr/local/bin/sbcl"
                   "--noinform"
                   "--load" (namestring (merge-pathnames "cl-nomic-test.asd"
                                                         *git-working-copy-dir*))
                   "--eval" "(asdf:load-system :cl-nomic-test)"
                   "--quit"))))
