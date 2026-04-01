# CL-NOMIC-SUPERVISOR

## Use of Docker

### Preparing quicklisp bundles

    (ql:bundle-systems '(:alexandria :quri :local-time :yason :dexador) :to #P"./quicklisp")

### Building with Docker

    VERSION=0.1.20260322
    docker build -t cl-nomic-supervisor:${VERSION} -t cl-nomic-supervisor:latest .

### Running with Docker

    docker run --env-file .env cl-nomic-supervisor

### Loading .env file for local use

    set -o allexport; . ./.env; set +o allexport

## Development Notes

* **TODO:** Need to add information about commits so that the decision-maker
  can take into account comments that happened before the last commit.

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
  * fetch all info about those pull requests and their code reviews,
  * run the game in a sandbox,
  * send the game info about the pull requests,
  * get the response from the client,
  * kill the client,
  * act on the client response, and
  * then exit.

The responses from the client will be one of:

    {decision: "winner", name: "name-of-winner", message: "optional explanation"}
    {decision: "accept", pr: id, message: "optional explanation"}
    {decision: "reject", pr: id, message: "optional explanation"}
    {decision: "defer"}

When the supervisor receives a `"winner"` message, it will add an empty
commit to the `main` branch of the `cl-nomic-game` repository with
a message declaring that the game is over and including the name of the winner
and it will tag this commit as `game-over`.
**Note:** tag is probably insufficient as collaborators might be able to tag,
but as they won't be able to have the last commit message be declaring the
winner, so maybe that's not a big deal?

When the supervisor receives a `"accept"` message, it will fetch the
new branch into the `/game` working copy, merge commit it to `main`,
and push the new `main` back to the origin. The supervisor will also
comment on the pull-request that it was merged and close the pull-request.

When the supervisor receives a `"reject"` message, it will comment
on the pull-request that it is rejected and close the pull-request.

When the supervisor recevies a `"defer"` message, it will do nothing.

When the supervisor receives any other message (or no message at all),
it will revert the last merge request and then restart.
**Note:** if there's not a good way to make sure the error was
runtime rather than compile-time, then this might be too draconian
and possible to abuse? More thinking needed. Maybe only if it exited
with non-zero status?

### bwrap command-line

    bwrap --ro-bind /bin /bin \
          --ro-bind /lib /lib \
          --ro-bind /usr/bin /usr/bin \
          --ro-bind /usr/local /usr/local \
          --bind /game /game \
          --unshare-all \
          --unshare-user \
          --uid "${GAME_UID}" \
          --gid "${GAME_GID}" \
          --new-session \
          --hostname nomic-game \
          --chdir /game \
          --clearenv \
          --setenv HOME /game \
          --setenv PATH "/bin:/usr/bin:/usr/local/bin" \
          --die-with-parent
          /game/start.sh

**TODO:** Find out if I can create some pipes and use the `--sync-fd` option to give the
child process some `stdin`, `stdout`, and `stderr`? Or do I use `--file`?

    --mkdir /dev \
    --perm 0400 --bind-data ${STDIN_FD} /dev/stdin \
    --perm 0200 --bind-data ${STDOUT_FD} /dev/stdout \
    --perm 0200 --bind-data ${STDERR_FD} /dev/stderr

With something like this in `/game/start.sh`:

    #!/bin/sh
    exec /usr/local/bin/sbcl --noinform \
                             --eval '(setf *compile-verbose* nil)' \
                             --eval '(setf *load-verbose* nil)' \
                             --eval '(require "asdf")' \
                             --eval '(load "./game.asd")' \
                             --eval '(asdf:load-system :game)' \
                             --quit

But, a super simple game could instead have `/game/start.sh`:

    #!/bin/sh
    echo '{decision: "winner", name: "patrick"}' > /dev/stdout
