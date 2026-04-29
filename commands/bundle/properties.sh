#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "bundle" "properties" "$@"
source "$_LP_SCRIPTS_DIR/lib/bundle.sh"

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

BRANCH="${BRANCH:-$(lp_get_reference_branch)}"

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

if [[ ! -f "$_LP_SCRIPTS_DIR/assets/portal-ext.properties" ]]; then
    lp_error "Base portal-ext.properties not found in assets."
    return 1 2>/dev/null || exit 1
fi

TOTAL_STEPS=2
[[ "$DB_TYPE" == "mysql" ]] && TOTAL_STEPS=3
STEP=1

lp_step "$STEP" "$TOTAL_STEPS" "Copying portal-ext.properties to $BUNDLE_DIR"
mkdir -p "$BUNDLE_DIR"
cp "$_LP_SCRIPTS_DIR/assets/portal-ext.properties" "$properties_file"
sed -i "s|localhost:3307/lportal|localhost:3307/$BRANCH|" "$properties_file"
STEP=$((STEP + 1))

lp_section "$STEP" "$TOTAL_STEPS" "Configuring database ($DB_TYPE)" \
    "$_LP_SCRIPTS_DIR/commands/bundle/db.sh" "$DB_TYPE" "$BRANCH"
STEP=$((STEP + 1))

if [[ "$DB_TYPE" == "mysql" ]]; then
    lp_section "$STEP" "$TOTAL_STEPS" "Starting MySQL" \
        "$_LP_SCRIPTS_DIR/commands/mysql/start.sh" "$BRANCH"
fi

if lp_port_offset_enabled; then
    "$_LP_SCRIPTS_DIR/commands/bundle/ports.sh" "$BRANCH"
fi
