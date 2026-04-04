#!/bin/bash

VERSION=$(grep ':version' cl-nomic-supervisor.asd | sed -e 's/ *:version *"\([^"]*\)"/\1/')

echo "VERSION=$VERSION"

color_yellow=""
color_off=""
setup_colors() {
    if [ -t 1 -a -t 2 ]; then
        color_yellow="$(tput setaf 3)"
        color_off="$(tput sgr0)"
    fi
}


build_image() {
    local dockerfile="$1"
    local image="$2"

    echo "${color_yellow}Building:${color_off} ${image}" 1>&2

    docker build \
           -q \
           -t "${image}:${VERSION}" \
           -t "${image}:latest" \
           -f "${dockerfile}" \
           .
}

setup_colors
build_image ./Dockerfile.cl cl-nomic-supervisor \
            && build_image ./Dockerfile.js js-nomic-supervisor \
            && build_image ./Dockerfile.py py-nomic-supervisor
