(in-package :cl-nomic-supervisor)

(defvar *github-api-host* "api.github.com")
(defvar *github-api-version* "2026-03-10")
(defvar *github-http-version* 1.1)

(defvar *github-api-token* nil)
(defvar *github-repo-owner* nil)
(defvar *github-repo-name* nil)

(eval-when (:execute)
  (setf *github-api-token* (uiop:getenv "GITHUB_SUPERVISOR_TOKEN")
        *github-repo-owner* (uiop:getenv "GITHUB_REPO_OWNER")
        *github-repo-name* (uiop:getenv "GITHUB_REPO_NAME")))

(defun %github-api (method path-as-list
                    &key
                      (token *github-api-token*)
                      query
                      body
                      (api-host *github-api-host*)
                      (api-version *github-api-version*)
                      (http-version *github-http-version*)
                    &allow-other-keys)
  (check-type method string)
  (check-type path-as-list list)
  (check-type token string)
  (check-type body list)
  (check-type api-host string)
  (check-type api-version string)
  (check-type http-version float)
  (multiple-value-bind (response-body response-status)
      (dex:request (quri:make-uri-https :host api-host
                                        :path (%convert-path-as-list-to-encoded-path path-as-list)
                                        :query (quri:url-encode-params query))
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

(defmacro define-github-api (name (method (&rest required-args)
                                   &rest parameters)
                             (&rest path-list) &body body)
  (let ((rest (gensym "REST-")))
    `(defun ,name (,@required-args
                   &rest
                     ,rest
                   &key
                     ,@parameters
                   &allow-other-keys)
       (apply #'%github-api ,method (list ,@path-list)
              ,@body
              ,rest))))

(define-github-api list-pull-requests (+GET+ ()
                                             (state "open")
                                             (owner *github-repo-owner*)
                                             (repo *github-repo-name*))
    ("repos" owner repo "pulls")
  :query `(("state" . ,state)))

(define-github-api list-pull-request-reviews (+GET+ (pull-number)
                                                    (owner *github-repo-owner*)
                                                    (repo *github-repo-name*))
    ("repos" owner repo "pulls" pull-number "reviews"))

(define-github-api list-pull-request-comments (+GET+ (pull-number)
                                                     (owner *github-repo-owner*)
                                                     (repo *github-repo-name*))
    ("repos" owner repo "issues" pull-number "comments"))

#+(or)
(setf *github-api-token* "API-TOKEN-HERE"
      *github-repo-owner* "nklein"
      *github-repo-name* "cl-nomic-game-test")

#+(or)
(list-pull-requests :state "all")

#+(or)
(flet ((get-updated-at-timestamp (pr)
         (local-time:parse-rfc3339-timestring (attr "updated_at" pr))))
  (stable-sort (list-pull-requests :state "all")
               #'local-time:timestamp<
               :key #'get-updated-at-timestamp))

#+(or)
(list-pull-request-reviews 1)

#+(or)
(list-pull-request-comments 2)

#+(or)
(let (results)
  (dolist (pull (list-pull-requests :state "all") results)
    (let ((votes)
          (all-comments)
          (state (attr "state" pull))
          (number (attr "number" pull)))
      (dolist (comment
               (list-pull-request-comments number)
               (push (list number
                           state
                           (list* :votes (nreverse votes))
                           (list* :comments (nreverse all-comments)))
                     results))
        (let ((user (attr "login" (attr "user" comment)))
              (body (attr "body" comment)))
          (push (cons user body) all-comments)
          (when (member body '("APPROVED" "REJECTED") :test #'string=)
            (push (cons user body) votes)))))))
