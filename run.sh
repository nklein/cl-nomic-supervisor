#!/bin/sh
################################################################
#
# Return codes from the docker container:
#
#   0: done or declared winner
#   1: made changes
#   2: error
#
################################################################

################################################################
#
# Initialize globals from environment or defaults
#
################################################################

IMAGE=${IMAGE:-cl-nomic-supervisor}
got_IMAGE=0
VERSION=${VERSION:-latest}
got_VERSION=0
ENVFILE=${ENVFILE:-.env}
FORCE=0

SCRIPTFILE="$0"

################################################################
#
# Color variables for fancy printing
#
################################################################
color_red=""
color_green=""
color_yellow=""
color_green=""
color_blue=""
color_teal=""
color_off=""

setup_colors() {
    if [ -t 1 -a -t 2 ]; then
        color_red="$(tput setaf 1)"
        color_green="$(tput setaf 2)"
        color_yellow="$(tput setaf 3)"
        color_blue="$(tput setaf 4)"
        color_teal="$(tput setaf 6)"
        color_off="$(tput sgr0)"
    fi
}

################################################################
#
# messaging about this script's execution
#
################################################################
err() {
    echo "${color_red}""$@""${color_off}" 1>&2
}

usage() {
    echo "${color_yellow}Usage:${color_off} ${SCRIPTFILE}"
    echo "          [--image name-of-image]      ${color_teal}# default: cl-nomic-supervisor${color_off}"
    echo "          [--version version-of-image] ${color_teal}# default: latest${color_off}"
    echo "          [--env env-file-name]        ${color_teal}# default: .env${color_off}"
    echo "          [--force]                    ${color_teal}# run even if no open pull requests${color_off}"
    echo "          [--help]"
}

################################################################
#
# functions for simulating the docker container
#   including a multi-phase sequence of results
#
################################################################
sim_accept() {
    echo '{ "decision": "accept", "id": 2, "message": "Good Reasons" }'
    return 1
}

sim_reject() {
    echo '{ "decision": "reject", "id": 2, "message": "Nefarious Reasons" }'
    return 1
}

sim_winner() {
    echo '{ "decision": "winner", "name": "Patrick <nklein>", "message": "Questionable Reasons" }'
    return 0
}

sim_defer() {
    echo '{ "decision": "defer" }'
    return 0
}

STAGE=1
sim_docker() {
    echo "${color_yellow}docker" "$@""${color_off}"
    case "${STAGE}" in
        1)  STAGE=2
            sim_reject
            ;;
        2)  STAGE=3
            sim_accept
            ;;
        3)  STAGE=4
            sim_winner
            ;;
        4)  STAGE=1
            sim_defer
            ;;
    esac
}

################################################################
#
# functions for invoking the docker container
#
################################################################
do_single_pass() {
    docker run --env "FORCE=${FORCE}" --env-file "${ENVFILE}" "${IMAGE}:${VERSION}"
}

do_passes() {
    local done="no"
    while [ "${done}" = "no" ]; do
        do_single_pass
        case "$?" in
            0) done="yes"
               ;;
            1) FORCE=1
               ;;
            2) err "Something went wrong"
               return 1
               ;;
            *) err "Unexpected return code: $?"
               return $?
               ;;
        esac
    done
}

################################################################
#
# functions for parsing the command-line and
#   kicking off execution
#
################################################################
parse_args() {
    while [ -n "${1}" ]; do
        case "${1}" in
            --image)
                IMAGE="${2}";
                got_IMAGE=1;
                shift;
                ;;

            --version)
                VERSION="${2}";
                got_VERSION=1;
                shift;
                ;;

            --env|--envfile|--env-file)
                ENVFILE="${2}";
                shift;
                ;;

            --force)
                FORCE=1
                ;;

            --help|-\?)
                usage;
                exit 0;
                ;;

            *)
                err "Unrecognized argument: $1"
                usage 1>&2;
                exit 1;
                ;;
        esac
        shift;
    done
}

load_env() {
    if [ -f "${ENVFILE}" ]; then
        local old_IMAGE="${IMAGE}"
        local old_VERSION="${VERSION}"

        echo "${color_teal}Sourcing ${color_yellow}${ENVFILE}${color_off}"
        . "${ENVFILE}"

        #
        # If the ENVFILE overwrote anything
        # we had gotten from the command-line,
        # then we should keep the version from
        # the command-line
        #
        for var in "IMAGE" "VERSION"; do
            local got_var="got_${var}"
            local old_var="old_${var}"
            if [ "${!got_var}" = 1 ]; then
                eval "${var}=\"${!old_var}\""
            fi
        done
    fi
}

main() {
    setup_colors
    parse_args "$@"
    load_env "$@"

    do_passes
}

main "$@"
