#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "portal" "gw" "$@"

find_gradlew() {
    local current_dir
    current_dir=$(pwd)
    local max_depth=10
    local depth=0

    while [[ "$depth" -le "$max_depth" ]]; do
        if [[ -e "$current_dir/gradlew" ]]; then
            echo "$current_dir/gradlew"
            return 0
        fi
        current_dir=$(dirname "$current_dir")
        ((depth++))
        
        if [[ "$current_dir" == "/" ]]; then
            break
        fi
    done

    return 1
}

run_gradle_task() {
    local gradlew_path
    gradlew_path=$(find_gradlew)

    if [[ -z "$gradlew_path" ]]; then
        lp_error "Error: Unable to locate Gradle wrapper (gradlew) in current or parent directories."
        return 1
    fi

    local tasks="${*//\//:}"
    lp_info "Running gradle tasks: $tasks (using $gradlew_path)"
    
    # Execute gradlew with the tasks, replacing slashes with colons for gradle subprojects
    # Wrap in lp_run to respect VERBOSE flag
    lp_run "$gradlew_path" ${@//\//:} --daemon
}

main() {
    if [[ $# -eq 0 ]]; then
        lp_error "No Gradle tasks specified."
        return 1
    fi

    run_gradle_task "$@"
}

main "$@"
