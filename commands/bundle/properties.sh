#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "properties" "$@"

BRANCH=""
DB_TYPE="$DEFAULT_DATABASE"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --db|-d)
            if [[ -n "$2" && "$2" != -* ]]; then
                DB_TYPE="$2"
                shift 2
            else
                lp_error "Option $1 requires a value (hypersonic|mysql)."
                return 1 2>/dev/null || exit 1
            fi
            ;;
        --verbose|-v) shift ;;
        --help|-h) shift ;;
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

if [[ -f "$_LP_SCRIPTS_DIR/assets/portal-ext.properties" ]]; then
    lp_info "Copying portal-ext.properties to $BUNDLE_DIR"
    mkdir -p "$BUNDLE_DIR"
    cp "$_LP_SCRIPTS_DIR/assets/portal-ext.properties" "$properties_file"
    
    # Replace default database name with branch name
    sed -i "s|localhost:3307/lportal|localhost:3307/$BRANCH|" "$properties_file"

    lp_success "Copied portal-ext.properties"

    # Configure database
    if [[ "$DB_TYPE" == "mysql" ]]; then
        "$_LP_SCRIPTS_DIR/commands/mysql/start.sh" "$BRANCH"
    fi

    "$_LP_SCRIPTS_DIR/commands/bundle/db.sh" "$DB_TYPE" "$BRANCH"

    # Configure ports (disabled temporarily)
    # "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" "$BRANCH"
else
    lp_error "Base portal-ext.properties not found in assets."
    return 1 2>/dev/null || exit 1
fi
