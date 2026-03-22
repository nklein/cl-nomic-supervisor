# CL-NOMIC-SUPERVISOR

## Building with Docker

    VERSION=0.1.20260322
    docker build -t cl-nomic-supervisor:${VERSION} -t cl-nomic-supervisor:latest .

## Creating some persistent storage

    docker volume create cl-nomic-supervisor-cache

## Running with Docker

    docker run --mount source=cl-nomic-supervisor-cache,target=/root/.cache cl-nomic-supervisor
