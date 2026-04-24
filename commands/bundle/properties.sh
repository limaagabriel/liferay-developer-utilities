#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "properties" "$@"

BRANCH=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) shift ;;
        -*)
            lp_error "Unknown option: $1"
            return 1 2>/dev/null || exit 1
            ;;
        *) BRANCH="$1"; shift ;;
    esac
done

BRANCH="${BRANCH:-$LP_WORKTREE_REFERENCE_BRANCH}"
BRANCH="${BRANCH:-master}"

lp_branch_vars "$BRANCH"

if [[ ! -d "$WORKTREE_DIR" ]]; then
    lp_error "Worktree '$WORKTREE_DIR' does not exist."
    return 1 2>/dev/null || exit 1
fi

BUNDLE_DIR=$(grep 'app.server.parent.dir' "$WORKTREE_DIR/app.server.${LIFERAY_USER}.properties" | cut -d'=' -f2)

if [[ -z "$BUNDLE_DIR" ]]; then
    lp_error "Could not find bundle directory for worktree '$WORKTREE_DIR'."
    return 1 2>/dev/null || exit 1
fi

properties_file="$BUNDLE_DIR/portal-ext.properties"
use_mysql=0

if [[ -f "$properties_file" ]]; then
    if grep -q "^jdbc.default.driverClassName" "$properties_file"; then
        use_mysql=1
    fi
fi

if [[ -f "$_LP_SCRIPTS_DIR/assets/portal-ext.properties" ]]; then
    lp_info "Copying portal-ext.properties to $BUNDLE_DIR"
    mkdir -p "$BUNDLE_DIR"
    cp "$_LP_SCRIPTS_DIR/assets/portal-ext.properties" "$properties_file"
    
    # Replace default database name with branch name
    sed -i "s|localhost:3307/lportal|localhost:3307/$BRANCH|" "$properties_file"

    if [[ $use_mysql -eq 1 ]]; then
        lp_info "Restoring MySQL state"
        sed -i "s/^[[:space:]]*#[[:space:]]*jdbc.default.driverClassName=/jdbc.default.driverClassName=/" "$properties_file"
        sed -i "s/^[[:space:]]*#[[:space:]]*jdbc.default.url=/jdbc.default.url=/" "$properties_file"
        sed -i "s/^[[:space:]]*#[[:space:]]*jdbc.default.username=/jdbc.default.username=/" "$properties_file"
        sed -i "s/^[[:space:]]*#[[:space:]]*jdbc.default.password=/jdbc.default.password=/" "$properties_file"
    fi

    lp_success "Copied portal-ext.properties and set database to $BRANCH"
else
    lp_error "Base portal-ext.properties not found in assets."
    return 1 2>/dev/null || exit 1
fi
