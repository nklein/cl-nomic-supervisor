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

#+(or)
(setf *github-api-token* "API-TOKEN-HERE"
      *github-repo-owner* "nklein"
      *github-repo-name* "cl-nomic-game-test"
      *github-default-branch* "main")

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
                              (json-encode body)))

    (values (json-parse response-body)
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

(defun expand-pull-request (pull-request)
  (let* ((pull-number (json-attr "number" pull-request))
         (comments (list-pull-request-comments pull-number))
         (reviews (list-pull-request-reviews pull-number)))
    (json-object `(("number" . ,pull-number)
                   ("pull-request" . ,pull-request)
                   ("comments" . ,comments)
                   ("reviews" . ,reviews)))))

(defun get-all-expanded-pull-requests (&rest
                                         rest
                                       &key
                                         (state "open")
                                         (owner *github-repo-owner*)
                                         (repo *github-repo-name*)
                                       &allow-other-keys)
  (declare (ignore state owner repo))
  (mapcar #'expand-pull-request
          (apply #'list-pull-requests rest)))

#+(or)
(progn
  (json-encode (get-all-expanded-pull-requests)
               *debug-io*)
  (values))

#+(or)
(flet ((get-updated-at-timestamp (pr)
         (local-time:parse-rfc3339-timestring (json-attr "updated_at" pr))))
  (stable-sort (list-pull-requests :state "all")
               #'local-time:timestamp<
               :key #'get-updated-at-timestamp))
