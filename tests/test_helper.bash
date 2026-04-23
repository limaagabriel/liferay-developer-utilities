#!/usr/bin/env bash

# Set _LP_SCRIPTS_DIR to the root of the repo
_LP_SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
export _LP_SCRIPTS_DIR

# Common setup for all tests
setup() {
    # If using bats-support or bats-assert, they can be loaded here.
    # For now, let's keep it simple.
    :
}
