#!/bin/bash
source "$_LP_SCRIPTS_DIR/lib/init.sh"
lp_init_command "database" "switch" "$@"

exec "$_LP_SCRIPTS_DIR/commands/bundle/db.sh" "$@"
