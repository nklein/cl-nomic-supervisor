# CL-NOMIC-SUPERVISOR

## Use of Docker

### Building with Docker

    VERSION=0.1.20260322
    docker build -t cl-nomic-supervisor:${VERSION} -t cl-nomic-supervisor:latest .

### Creating some persistent storage

    docker volume create cl-nomic-supervisor-cache

### Running with Docker

    docker run --mount source=cl-nomic-supervisor-cache,target=/root/.cache cl-nomic-supervisor

## Development Notes

Need to figure out GitHub webhooks that will notify me when there is
a new code-review on an open pull-request for a given repo.

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
