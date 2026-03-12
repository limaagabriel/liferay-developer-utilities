#!/bin/bash
# Usage: source lp portal gw [tasks...]
# Runs gradle tasks in the current directory.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Run gradle tasks in the current directory."
    echo ""
    echo "Usage: lp portal gw [tasks...]"
    echo ""
    echo "Options:"
    echo "  -h, --help   Show this help"
    echo ""
    echo "Examples:"
    echo "  lp portal gw clean deploy"
    return 0 2>/dev/null || exit 0
fi

source "$_LP_SCRIPTS_DIR/config.sh" || return 1 2>/dev/null || exit 1

# Logic copied from original gw/execute_gradlew functions
execute_gradlew() {
    if [ -e gradlew ]
    then
        ./gradlew "${@}"
    elif [ -e ../gradlew ]
    then
        ../gradlew "${@}"
    elif [ -e ../../gradlew ]
    then
        ../../gradlew "${@}"
    elif [ -e ../../../gradlew ]
    then
        ../../../gradlew "${@}"
    elif [ -e ../../../../gradlew ]
    then
        ../../../../gradlew "${@}"
    elif [ -e ../../../../../gradlew ]
    then
        ../../../../../gradlew "${@}"
    elif [ -e ../../../../../../gradlew ]
    then
        ../../../../../../gradlew "${@}"
    elif [ -e ../../../../../../../gradlew ]
    then
        ../../../../../../../gradlew "${@}"
    elif [ -e ../../../../../../../../gradlew ]
    then
        ../../../../../../../../gradlew "${@}"
    elif [ -e ../../../../../../../../../gradlew ]
    then
        ../../../../../../../../../gradlew "${@}"
    else
        lp_error "Error: Unable to locate Gradle wrapper."
        return 1
    fi
}

lp_info "Running gw in $(pwd) with tasks: ${*//\//:}"
execute_gradlew "${@//\//:}" --daemon
