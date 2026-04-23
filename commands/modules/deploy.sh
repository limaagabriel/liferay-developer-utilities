#!/bin/bash
# Usage: lp modules deploy [options] [module_path]
# Run gw deploy in a module or all changed modules.

source "$_LP_SCRIPTS_DIR/lib/output.sh"

usage() {
    echo "Run gw deploy in a module or all changed modules."
    echo ""
    echo "Usage: lp modules deploy [options] [module_path...]"
    echo ""
    echo "Options:"
    echo "  -c, --changed      Deploy all modules changed in the current branch"
    echo "  -u, --uncommitted  Deploy only modules with uncommitted work"
    echo "  -b, --base <branch> Base branch to compare against for --changed (default: master)"
    echo "  -n, --workers <n>  Number of parallel workers (default: 1)"
    echo "  -r, --restart      Run 'gw clean deploy' instead of just 'gw deploy'"
    echo "  -v, --verbose      Show full gradle output"
    echo "  -h, --help         Show this help"
    echo ""
    echo "Examples:"
    echo "  lp modules deploy                        # deploy current directory"
    echo "  lp modules deploy modules/apps/portal-workflow/portal-workflow-api"
    echo "  lp modules deploy --changed              # deploy all changed modules"
    echo "  lp modules deploy --uncommitted          # deploy uncommitted modules"
    echo "  lp modules deploy -n 4 -c                # deploy changed modules using 4 workers"
    echo "  lp modules deploy -r                     # run clean deploy in current directory"
}

CHANGED=0
UNCOMMITTED=0
BASE_BRANCH="master"
MODULES=()
VERBOSE=0
WORKERS=1
RESTART=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--changed)
            CHANGED=1
            shift
            ;;
        -u|--uncommitted)
            UNCOMMITTED=1
            shift
            ;;
        -b|--base)
            BASE_BRANCH="$2"
            shift 2
            ;;
        -n|--workers)
            WORKERS="$2"
            shift 2
            ;;
        -r|--restart)
            RESTART=1
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            usage
            return 0 2>/dev/null || exit 0
            ;;
        -*)
            lp_error "Error: Unknown option $1"
            usage
            exit 1
            ;;
        *)
            MODULES+=("$1")
            shift
            ;;
    esac
done

if [[ $CHANGED -eq 1 && $UNCOMMITTED -eq 1 ]]; then
    lp_error "Error: Options --changed and --uncommitted are mutually exclusive."
    exit 1
fi

export VERBOSE

GW_TASKS="deploy"
if [[ $RESTART -eq 1 ]]; then
    GW_TASKS="clean deploy"
fi

# If -c or -u is provided, we fetch the changed list
if [[ $CHANGED -eq 1 || $UNCOMMITTED -eq 1 ]]; then
    if [[ $UNCOMMITTED -eq 1 ]]; then
        lp_info "Identifying modules with uncommitted changes..."
        CHANGED_LIST=$("$_LP_SCRIPTS_DIR/commands/modules/changed.sh" --uncommitted)
    else
        lp_info "Identifying changed modules compared to '$BASE_BRANCH'..."
        CHANGED_LIST=$("$_LP_SCRIPTS_DIR/commands/modules/changed.sh" "$BASE_BRANCH")
    fi
    
    if [[ -z "$CHANGED_LIST" || "$CHANGED_LIST" == "No changed modules found"* || "$CHANGED_LIST" == "No changed files found"* ]]; then
        # If we have other positional modules, continue. Otherwise exit.
        if [[ ${#MODULES[@]} -eq 0 ]]; then
            lp_info "No changed modules to deploy."
            exit 0
        fi
    else
        # Append changed modules to the list
        GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
        
        while read -r mod; do
            [[ -z "$mod" ]] && continue
            MODULES+=("$GIT_ROOT/$mod")
        done <<< "$CHANGED_LIST"
    fi
fi

# If no modules provided, deploy current directory
if [[ ${#MODULES[@]} -eq 0 ]]; then
    MODULES+=(".")
fi

# Filter out modules ending with -theme
FINAL_MODULES=()
for module in "${MODULES[@]}"; do
    if [[ "$module" == *"-theme" ]]; then
        continue
    fi
    FINAL_MODULES+=("$module")
done
MODULES=("${FINAL_MODULES[@]}")

TOTAL=${#MODULES[@]}
if [[ $TOTAL -eq 0 ]]; then
    lp_info "No modules to deploy (filtered out themes or empty list)."
    exit 0
fi

ORIGINAL_PWD=$(pwd)
CURRENT=0

# Adjust workers to not exceed total modules
if [[ $WORKERS -gt $TOTAL ]]; then
    WORKERS=$TOTAL
fi

if [[ $WORKERS -le 1 ]]; then
    for module in "${MODULES[@]}"; do
        ((CURRENT++))
        
        if [[ ! -d "$module" ]]; then
            lp_error "Error: Directory '$module' does not exist."
            exit 1
        fi
        
        # Try to make a nice display name
        ABS_PATH=$(cd "$module" && pwd)
        GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
        DISPLAY_NAME="$module"
        
        if [[ -n "$GIT_ROOT" && "$ABS_PATH" == "$GIT_ROOT"* ]]; then
            DISPLAY_NAME="${ABS_PATH#$GIT_ROOT/}"
            [[ -z "$DISPLAY_NAME" ]] && DISPLAY_NAME="root"
        fi
        
        [[ "$module" == "." ]] && DISPLAY_NAME="current directory ($DISPLAY_NAME)"

        lp_step "$CURRENT" "$TOTAL" "Deploying $DISPLAY_NAME ($GW_TASKS)"
        
        cd "$module" || exit 1
        lp_run "$_LP_SCRIPTS_DIR/commands/portal/gw.sh" $GW_TASKS || exit 1
        cd "$ORIGINAL_PWD" || exit 1
    done
else
    lp_info "Deploying $TOTAL modules using $WORKERS workers ($GW_TASKS)..."
    
    FAILURE_FILE=$(mktemp)
    PIDS=()
    
    for module in "${MODULES[@]}"; do
        # Check if any job already failed
        if [[ -s "$FAILURE_FILE" ]]; then
            break
        fi

        ((CURRENT++))
        
        # Spawn job in background
        (
            if [[ ! -d "$module" ]]; then
                lp_error "Error: Directory '$module' does not exist."
                echo "1" > "$FAILURE_FILE"
                exit 1
            fi
            
            ABS_PATH=$(cd "$module" && pwd)
            GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
            DISPLAY_NAME="$module"
            if [[ -n "$GIT_ROOT" && "$ABS_PATH" == "$GIT_ROOT"* ]]; then
                DISPLAY_NAME="${ABS_PATH#$GIT_ROOT/}"
                [[ -z "$DISPLAY_NAME" ]] && DISPLAY_NAME="root"
            fi
            [[ "$module" == "." ]] && DISPLAY_NAME="current directory ($DISPLAY_NAME)"

            lp_step "$CURRENT" "$TOTAL" "Deploying $DISPLAY_NAME ($GW_TASKS)"
            
            cd "$module" || { echo "1" > "$FAILURE_FILE"; exit 1; }
            if ! lp_run "$_LP_SCRIPTS_DIR/commands/portal/gw.sh" $GW_TASKS; then
                echo "1" > "$FAILURE_FILE"
                exit 1
            fi
        ) &
        PIDS+=("$!")

        # Concurrency limit loop using PID tracking
        while true; do
            ACTIVE_PIDS=()
            ACTIVE_COUNT=0
            for pid in "${PIDS[@]}"; do
                if kill -0 "$pid" 2>/dev/null; then
                    ACTIVE_PIDS+=("$pid")
                    ((ACTIVE_COUNT++))
                else
                    # Process finished, harvest exit status
                    if ! wait "$pid"; then
                        echo "1" > "$FAILURE_FILE"
                    fi
                fi
            done
            PIDS=("${ACTIVE_PIDS[@]}")

            if [[ $ACTIVE_COUNT -lt $WORKERS ]] || [[ -s "$FAILURE_FILE" ]]; then
                break
            fi
            sleep 0.2
        done
    done

    # Wait for remaining jobs
    for pid in "${PIDS[@]}"; do
        if ! wait "$pid"; then
            echo "1" > "$FAILURE_FILE"
        fi
    done
    
    if [[ -s "$FAILURE_FILE" ]]; then
        rm -f "$FAILURE_FILE"
        lp_error "Error: Parallel deployment failed."
        exit 1
    fi
    rm -f "$FAILURE_FILE"
fi
