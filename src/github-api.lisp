(in-package :cl-nomic-supervisor)

(defvar *github-api-url* "https://api.github.com")
(defvar *github-api-version* "2026-03-10")
(defvar *github-http-version* 1.1)

(defvar *github-api-token* nil)
(defvar *github-repo-owner* nil)
(defvar *github-repo-name* nil)

(eval-when (:execute)
  (setf *github-api-token* (uiop:getenv "GITHUB_SUPERVISOR_TOKEN")
        *github-repo-owner* (uiop:getenv "GITHUB_REPO_OWNER")
        *github-repo-name* (uiop:getenv "GITHUB_REPO_NAME")))

(defun attr (name json-object)
  (cdr (assoc name json-object
              :test #'string=)))

(defun %github-api (method path
                    &key
                      (token *github-api-token*)
                      body
                      (api-url *github-api-url*)
                      (api-version *github-api-version*)
                      (http-version *github-http-version*))
  (check-type token string)
  (check-type body list)
  (check-type api-url string)
  (check-type api-version string)
  (check-type http-version float)
  (multiple-value-bind (response-body response-status)
      (dex:request (format nil "~A~A" api-url path)
                   :method method
                   :version http-version
                   :headers `(("Authorization" . ,(format nil "Bearer ~A" token))
                              ("Accept" . "application/vnd.github+json")
                              ("X-GitHub-Api-Version" . ,api-version))
                   :content (when body
                              (yason:with-output-to-string* ()
                                body)))

    (values (let ((yason:*parse-object-as* :alist))
              (yason:parse response-body))
            response-status)))

(defun list-pull-requests (&key
                             (owner *github-repo-owner*)
                             (repo *github-repo-name*))
  (check-type owner string)
  (check-type repo string)
  (%github-api +GET+ (format nil "/repos/~A/~A/pulls"
                             owner
                             repo)))

(defun list-pull-request-reviews (pull-number
                                  &key
                                    (owner *github-repo-owner*)
                                    (repo *github-repo-name*))
  (check-type pull-number (integer 1 *))
  (check-type owner string)
  (check-type repo string)
  (%github-api +GET+ (format nil "/repos/~A/~A/pulls/~A/reviews"
                             owner
                             repo
                             pull-number)))

(defmacro string-case (keyform &body clauses)
  (let ((key (gensym "KEY-")))
    (labels ((compare (value)
               `(string= ,value ,key))
             (expand-clause (clause)
               (destructuring-bind (value &rest body) clause
                 `(,(etypecase value
                      (string (compare value))
                      (list `(or ,@(mapcar #'compare value)))
                      ((member otherwise t) value))
                   ,@body)
)))
      `(let ((,key ,keyform))
         (cond
           ,@(mapcar #'expand-clause clauses))))))

#+(or)
(setf *github-api-token* "API-TOKEN-HERE"
      *github-repo-owner* "nklein"
      *github-repo-name* "cl-nomic-game-test")

#+(or)
(list-pull-requests)

#+(or)
(let ((votes (make-hash-table :test 'equalp))
      (all-comments))
  (dolist (pull (list-pull-requests) (list (list* :votes
                                                  (alexandria:hash-table-alist votes))
                                           (list* :all-comments all-comments)))
    (let ((state (attr "state" pull))
          (number (attr "number" pull)))
      (string-case state
        ("open"
         (dolist (review (list-pull-request-reviews number))
           (let ((state (attr "state" review))
                 (user (attr "login" (attr "user" review))))
             (string-case state
               ("COMMENTED"
                (let ((body (attr "body" review)))
                  (push (cons user body) all-comments)
                  (string-case body
                    (("APPROVED" "REJECTED")
                     (setf (gethash user votes) body)))))))))))))
