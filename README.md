# CL-NOMIC-SUPERVISOR

## Use of Docker

### Preparing quicklisp bundles

    (ql:bundle-systems '(:alexandria :sqlite :ironclad :yason :dexador :toot) :to #P"./quicklisp")

### Building with Docker

    VERSION=0.1.20260322
    docker build -t cl-nomic-supervisor:${VERSION} -t cl-nomic-supervisor:latest .

### Running with Docker

    docker run cl-nomic-supervisor

### Loading .env file

    set -o allexport; . ./.env; set +o allexport

## Development Notes

Need to figure out GitHub webhooks that will notify me when there is
a new code-review on an open pull-request for a given repo.
It looks like I can have a webhook call me back any time there is
a change to a `pull_request_review`. It is unclear to me how I can
see from the `pull_request` in the `pull_request_review` what branch
is trying to merge to where, but I will figure it out.

Supervisor will, on startup:
* clone the `main` branch and tags of the `cl-nomic-game` repository to `/game`,
* if there is a `game-over` tag, the supervisor will exit,
* otherwise it will:
  * fetch the latest code reviews results,
  * fetch all info about that pull request and its code reviews,
  * run the game in a sandbox,
  * send the game info about the pull request and its code reviews,
  * get the response from the client,
  * kill the client,
  * act on the client response, and
  * then exit.

The responses from the client will be one of:

    (:winner "name-of-winner")
    (:merge)
    (:reject)
    (:not-yet)

When the supervisor receives a `:winner` message, it will add an empty
commit to the `main` branch of the `cl-nomic-game` repository with
a message declaring that the game is over and including the name of the winner
and it will tag this commit as `game-over`.

When the supervisor receives a `:merge` message, it will fetch the
new branch into the `/game` working copy, merge commit it to `main`,
and push the new `main` back to the origin. The supervisor will also
comment on the pull-request that it was merged and close the pull-request.

When the supervisor receives a `:reject` message, it will comment
on the pull-request that it is rejected and close the pull-request.

When the supervisor recevies a `:not-yet` message, it will do nothing.

When the supervisor receives any other message (or no message at all),
it will revert the last merge request and then restart.

### bwrap command-line

    echo '(asdf:defsystem :game :components ((:file "game")))' > /game/game.asd
    echo '(with-standard-io-syntax (print (list :winner "pat")) (terpri))' > /game/game.lisp
    bwrap --ro-bind /lib /lib \
          --ro-bind /usr/local /usr/local \
          --bind /game /game \
          --unshare-all \
          /usr/local/bin/sbcl --noinform \
                              --eval '(setf *compile-verbose* nil)' \
                              --eval '(setf *load-verbose* nil)' \
                              --eval '(require "asdf")' \
                              --load '/game/game.asd' \
                              --eval '(asdf:load-system :game)' \
                              --quit
