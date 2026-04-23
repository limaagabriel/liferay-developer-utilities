#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "modules" "deploy" "$@"

parse_arguments() {
    CHANGED=0
    UNCOMMITTED=0
    BASE_BRANCH="master"
    RAW_MODULES=()
    WORKERS=1
    RESTART=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--changed)
                CHANGED=1; shift ;;
            -u|--uncommitted)
                UNCOMMITTED=1; shift ;;
            -b|--base)
                BASE_BRANCH="$2"; shift 2 ;;
            -n|--workers)
                WORKERS="$2"; shift 2 ;;
            -r|--restart)
                RESTART=1; shift ;;
            --verbose|-v)
                shift ;;
            -*)
                lp_error "Error: Unknown option $1"
                echo "Usage: lp modules deploy [options] [module_path...]"
                return 1 2>/dev/null || exit 1
                ;;
            *)
                RAW_MODULES+=("$1"); shift ;;
        esac
    done

    export VERBOSE
}

validate_arguments() {
    if [[ $CHANGED -eq 1 && $UNCOMMITTED -eq 1 ]]; then
        lp_error "Error: Options --changed and --uncommitted are mutually exclusive."
        return 1 2>/dev/null || exit 1
    fi
}

get_gradle_tasks() {
    if [[ $RESTART -eq 1 ]]; then
        echo "clean deploy"
    else
        echo "deploy"
    fi
}

resolve_modules() {
    local modules=("${RAW_MODULES[@]}")

    if [[ $CHANGED -eq 1 || $UNCOMMITTED -eq 1 ]]; then
        local changed_list
        if [[ $UNCOMMITTED -eq 1 ]]; then
            lp_info "Identifying modules with uncommitted changes..."
            changed_list=$("$_LP_SCRIPTS_DIR/commands/modules/changed.sh" --uncommitted)
        else
            lp_info "Identifying changed modules compared to '$BASE_BRANCH'..."
            changed_list=$("$_LP_SCRIPTS_DIR/commands/modules/changed.sh" "$BASE_BRANCH")
        fi
        
        if [[ -n "$changed_list" && "$changed_list" != "No changed modules found"* && "$changed_list" != "No changed files found"* ]]; then
            local git_root
            git_root=$(git rev-parse --show-toplevel 2>/dev/null)
            
            while read -r mod; do
                [[ -z "$mod" ]] && continue
                modules+=("$git_root/$mod")
            done <<< "$changed_list"
        fi
    fi

    if [[ ${#modules[@]} -eq 0 ]]; then
        modules+=(".")
    fi

    FINAL_MODULES=()
    for module in "${modules[@]}"; do
        if [[ "$module" == *"-theme" ]]; then
            continue
        fi
        FINAL_MODULES+=("$module")
    done
}

get_display_name() {
    local module="$1"
    local abs_path
    abs_path=$(cd "$module" && pwd)
    local git_root
    git_root=$(git rev-parse --show-toplevel 2>/dev/null)
    local display_name="$module"
    
    if [[ -n "$git_root" && "$abs_path" == "$git_root"* ]]; then
        display_name="${abs_path#$git_root/}"
        [[ -z "$display_name" ]] && display_name="root"
    fi
    
    if [[ "$module" == "." ]]; then
        echo "current directory ($display_name)"
    else
        echo "$display_name"
    fi
}

deploy_module() {
    local module="$1"
    local current_step="$2"
    local total_steps="$3"
    local tasks="$4"
    local display_name

    if [[ ! -d "$module" ]]; then
        lp_error "Error: Directory '$module' does not exist."
        return 1
    fi

    display_name=$(get_display_name "$module")
    lp_step "$current_step" "$total_steps" "Deploying $display_name ($tasks)"
    
    (
        cd "$module" || { return 1 2>/dev/null || exit 1; }
        "$_LP_SCRIPTS_DIR/commands/portal/gw.sh" $tasks
    )
}

run_sequential_deployment() {
    local tasks
    tasks=$(get_gradle_tasks)
    local total=${#FINAL_MODULES[@]}
    local current=0

    for module in "${FINAL_MODULES[@]}"; do
        ((current++))
        deploy_module "$module" "$current" "$total" "$tasks" || { return 1 2>/dev/null || exit 1; }
    done
}

run_parallel_deployment() {
    local tasks
    tasks=$(get_gradle_tasks)
    local total=${#FINAL_MODULES[@]}
    local current=0
    local failure_file
    failure_file=$(mktemp)
    local pids=()

    lp_info "Deploying $total modules using $WORKERS workers ($tasks)..."
    
    for module in "${FINAL_MODULES[@]}"; do
        if [[ -s "$failure_file" ]]; then
            break
        fi

        ((current++))
        
        (
            deploy_module "$module" "$current" "$total" "$tasks" || { echo "1" > "$failure_file"; return 1 2>/dev/null || exit 1; }
        ) &
        pids+=("$!")

        while true; do
            local active_pids=()
            local active_count=0
            for pid in "${pids[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    active_pids+=("$pid")
                    ((active_count++))
                else
                    if ! wait "$pid"; then
                        echo "1" > "$failure_file"
                    fi
                fi
            done
            pids=("${active_pids[@]}")

            if [[ $active_count -lt $WORKERS ]] || [[ -s "$failure_file" ]]; then
                break
            fi
            sleep 0.2
        done
    done

    for pid in "${pids[@]}"; do
        if ! wait "$pid"; then
            echo "1" > "$failure_file"
        fi
    done
    
    if [[ -s "$failure_file" ]]; then
        rm -f "$failure_file"
        lp_error "Error: Parallel deployment failed."
        return 1 2>/dev/null || exit 1
    fi
    rm -f "$failure_file"
}

main() {
    parse_arguments "$@"
    validate_arguments
    resolve_modules

    if [[ ${#FINAL_MODULES[@]} -eq 0 ]]; then
        lp_info "No modules to deploy."
        return 0
    fi

    if [[ $WORKERS -le 1 ]]; then
        run_sequential_deployment
    else
        run_parallel_deployment
    fi
}

main "$@"
