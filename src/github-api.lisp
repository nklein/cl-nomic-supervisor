(in-package :cl-nomic-supervisor)

(defvar *github-api-host* "api.github.com")
(defvar *github-api-version* "2026-03-10")
(defvar *github-http-version* 1.1)

(defvar *github-api-token* nil)
(defvar *github-repo-owner* nil)
(defvar *github-repo-name* nil)

#+(or)
(setf *github-api-token* "API-TOKEN-HERE"
      *github-repo-owner* "nklein"
      *github-repo-name* "cl-nomic-game-test")

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
  (check-type body (or json-object null))
  (check-type api-host string)
  (check-type api-version string)
  (check-type http-version float)
  (multiple-value-bind (response-body response-status)
      (dex:request (quri:make-uri-https :host api-host
                                        :path (%convert-path-as-list-to-encoded-path path-as-list)
                                        :query (when query
                                                 (quri:url-encode-params query)))
                   :method method
                   :version http-version
                   :headers `(("Accept" . "application/vnd.github+json")
                              ("Authorization" . ,(format nil "Bearer ~A" token))
                              ("X-GitHub-Api-Version" . ,api-version)
                              ,@(when body
                                  `(("Content-Type" . "application/x-www-form-urlencoded"))))
                   :content (when body
                              (json-encode* body)))
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

(define-github-api repository-events (+GET+ ()
                                            (owner *github-repo-owner*)
                                            (repo *github-repo-name*))
    ("repos" owner repo "events"))

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

(define-github-api list-pull-request-commits (+GET+ (pull-number)
                                                    (owner *github-repo-owner*)
                                                    (repo *github-repo-name*))
    ("repos" owner repo "pulls" pull-number "commits"))

(define-github-api get-tag-reference (+GET+ (tag)
                                            (owner *github-repo-owner*)
                                            (repo *github-repo-name*))
    ("repos" owner repo "git" "ref" "tags" tag))

(define-github-api get-branch-reference (+GET+ ()
                                            (branch *git-default-branch*)
                                            (owner *github-repo-owner*)
                                            (repo *github-repo-name*))
    ("repos" owner repo "git" "ref" "heads" branch))

(define-github-api create-commit-tag (+POST+ (tag sha)
                                      (message)
                                      (owner *github-repo-owner*)
                                      (repo *github-repo-name*))
    ("repos" owner repo "git" "tags")
  :body (json-object `(("tag" . ,tag)
                       ,@(when message
                           `(("message" . ,message)))
                       ("object" . ,sha)
                       ("type" . "commit")
                       ("tagger" . ,(json-object `(("name" . "cl-nomic-supervisor")
                                                   ("email" . "pat@nklein.com")
                                                   ("date" .  ,(local-time:format-rfc3339-timestring
                                                                nil
                                                                (local-time:now)
                                                                 :timezone local-time:+utc-zone+))))))))

(define-github-api create-tag-reference (+POST+ (tag sha)
                                                (owner *github-repo-owner*)
                                                (repo *github-repo-name*))
    ("repos" owner repo "git" "refs")
  :body (json-object `(("ref" . ,(format nil "refs/tags/~A" tag))
                       ("sha" . ,sha))))

(define-github-api merge-pull-request (+PUT+ (pull-number title message)
                                             (owner *github-repo-owner*)
                                             (repo *github-repo-name*))
    ("repos" owner repo "pulls" pull-number "merge")
  :body (json-object `(("commit_title" . ,title)
                       ("commit_message" . ,message))))

(define-github-api close-pull-request (+PATCH+ (pull-number)
                                               (additional)
                                               (owner *github-repo-owner*)
                                               (repo *github-repo-name*))
    ("repos" owner repo "pulls" pull-number)
  :body (json-object `(("state" . "closed")
                       ,@additional)))

(defun augment-pull-request (pull-request &optional id)
  (let* ((pull-number (json-attr "number" pull-request))
         (comments (list-pull-request-comments pull-number))
         (reviews (list-pull-request-reviews pull-number))
         (commits (list-pull-request-commits pull-number)))
    (json-object `(("id" . ,(or id
                                pull-number))
                   ("pull_request" . ,pull-request)
                   ("reviews" . ,reviews)
                   ("comments" . ,comments)
                   ("commits" . ,commits)))))

(defun get-all-augmented-pull-requests (&rest
                                          rest
                                        &key
                                          (state "open")
                                          (owner *github-repo-owner*)
                                          (repo *github-repo-name*)
                                        &allow-other-keys)
  (declare (ignore state owner repo))
  (loop :for pull-request :in (apply #'list-pull-requests rest)
        :for id :from 1
        :collecting (augment-pull-request pull-request id)))

#+(or)
(progn
  (json-encode (get-all-augmented-pull-requests)
               *debug-io*)
  (values))
