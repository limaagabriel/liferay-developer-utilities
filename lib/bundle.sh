#!/bin/bash

_LP_BUNDLE_CLONE_MODE_FILE="${BUNDLES_DIR}/.clone-mode"
_LP_BUNDLE_META_FILE=".lp-bundle-meta"
_LP_BUNDLE_OFFSET_FILE=".worktree-port-offset"

_LP_PORT_KINDS="http https shutdown ajp osgi es-http es-transport arquillian dataguard glowroot"

_lp_port_base() {
    case "$1" in
        http)         echo 8080 ;;
        https)        echo 8443 ;;
        shutdown)     echo 8005 ;;
        ajp)          echo 8009 ;;
        osgi)         echo 11311 ;;
        es-http)      echo 9201 ;;
        es-transport) echo 9301 ;;
        arquillian)   echo 32763 ;;
        dataguard)    echo 42763 ;;
        glowroot)     echo 4000 ;;
        *)            echo "" ;;
    esac
}

# lp_port_offset_enabled — returns 0 if ENABLE_PORT_OFFSET is truthy.
lp_port_offset_enabled() {
    local val
    val=$(printf '%s' "${ENABLE_PORT_OFFSET:-no}" | tr '[:upper:]' '[:lower:]')
    case "$val" in
        yes|true|1) return 0 ;;
        *)          return 1 ;;
    esac
}

# lp_bundle_offset <branch> — echo the offset for a bundle.
# Returns 0 for master, contents of .worktree-port-offset otherwise, 0 if missing.
lp_bundle_offset() {
    local branch="$1"
    [[ -z "$branch" ]] && { echo 0; return; }
    [[ "$branch" == "master" ]] && { echo 0; return; }

    local offset_file="$BUNDLES_DIR/$branch/$_LP_BUNDLE_OFFSET_FILE"
    if [[ -f "$offset_file" ]]; then
        cat "$offset_file"
    else
        echo 0
    fi
}

# lp_bundle_port <kind> <branch> — echo computed port for a kind.
lp_bundle_port() {
    local kind="$1"
    local branch="$2"
    local base offset
    base=$(_lp_port_base "$kind")
    [[ -z "$base" ]] && return 1
    offset=$(lp_bundle_offset "$branch")
    echo $((base + offset))
}

# lp_bundle_port_table <branch> — print "kind\tport" lines for every known kind.
lp_bundle_port_table() {
    local branch="$1"
    local kind
    for kind in $_LP_PORT_KINDS; do
        printf '%s\t%s\n' "$kind" "$(lp_bundle_port "$kind" "$branch")"
    done
}

_lp_bundle_probe_clone_mode() {
    if [[ -f "$_LP_BUNDLE_CLONE_MODE_FILE" ]]; then
        cat "$_LP_BUNDLE_CLONE_MODE_FILE"
        return 0
    fi

    mkdir -p "$BUNDLES_DIR" || return 1

    local probe_src probe_dst mode
    probe_src=$(mktemp -p "$BUNDLES_DIR" .clone-probe-src.XXXXXX) || return 1
    probe_dst="${probe_src}.dst"
    echo "probe" > "$probe_src"

    if cp --reflink=always "$probe_src" "$probe_dst" 2>/dev/null; then
        mode="reflink"
    else
        mode="copy"
    fi

    rm -f "$probe_src" "$probe_dst"
    echo "$mode" > "$_LP_BUNDLE_CLONE_MODE_FILE"
    echo "$mode"
}

_lp_bundle_clone() {
    local src="$1"
    local dst="$2"

    [[ -d "$src" ]] || { lp_error "Source bundle not found: $src"; return 1; }
    [[ -e "$dst" ]] && { lp_error "Destination already exists: $dst"; return 1; }

    local mode
    mode=$(_lp_bundle_probe_clone_mode)

    case "$mode" in
        reflink)
            lp_run cp --reflink=always -a "$src" "$dst"
            ;;
        copy)
            lp_run cp -a "$src" "$dst"
            ;;
        *)
            lp_error "Unknown clone mode: $mode"
            return 1
            ;;
    esac
}

_lp_bundle_init_mutable_state() {
    local bundle_dir="$1"
    [[ -d "$bundle_dir" ]] || { lp_error "Bundle dir not found: $bundle_dir"; return 1; }

    local dir
    for dir in data osgi/state work logs; do
        rm -rf "$bundle_dir/$dir"
        mkdir -p "$bundle_dir/$dir"
    done

    local tomcat_dir
    for tomcat_dir in "$bundle_dir"/tomcat-*/; do
        [[ -d "$tomcat_dir" ]] || continue
        for dir in temp work logs; do
            rm -rf "$tomcat_dir/$dir"
            mkdir -p "$tomcat_dir/$dir"
        done
    done
}

_lp_bundle_resolve_base() {
    local name="$1"
    local path="$BASE_BUNDLES_DIR/$name"

    [[ -z "$name" ]] && { lp_error "Base bundle name is required."; return 1; }
    [[ -d "$path" ]] || {
        lp_error "Base bundle '$name' not found at $path."
        lp_error "Run 'lp base build $name' first."
        return 1
    }

    echo "$path"
}

_lp_bundle_meta_get() {
    local bundle_dir="$1"
    local key="$2"
    local file="$bundle_dir/$_LP_BUNDLE_META_FILE"

    [[ -f "$file" ]] || { echo ""; return 0; }
    sed -n "s/^${key}=//p" "$file" | head -n 1
}

_lp_bundle_write_meta() {
    local bundle_dir="$1"
    local source_label="$2"
    local bundle_name="$3"
    local source_worktree="${4:-$WORKTREE_DIR}"

    [[ -d "$bundle_dir" ]] || { lp_error "Bundle dir not found: $bundle_dir"; return 1; }

    local commit="unknown" commit_short="unknown" branch="unknown"
    if [[ -d "$source_worktree/.git" || -f "$source_worktree/.git" ]]; then
        commit=$(git -C "$source_worktree" rev-parse HEAD 2>/dev/null || echo "unknown")
        commit_short=$(git -C "$source_worktree" rev-parse --short HEAD 2>/dev/null || echo "unknown")
        branch=$(git -C "$source_worktree" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    fi

    local built_at host
    built_at=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    host=$(hostname)

    local file="$bundle_dir/$_LP_BUNDLE_META_FILE"
    {
        echo "LP_BUNDLE_NAME=$bundle_name"
        echo "LP_BUNDLE_SOURCE=$source_label"
        echo "LP_BUNDLE_COMMIT=$commit"
        echo "LP_BUNDLE_COMMIT_SHORT=$commit_short"
        echo "LP_BUNDLE_BRANCH=$branch"
        echo "LP_BUNDLE_BUILT_AT=$built_at"
        local caller="${BASH_SOURCE[1]:-}"
        if [[ -n "$caller" ]]; then
            caller="$(basename "$(dirname "$caller")")/$(basename "$caller")"
        else
            caller="?"
        fi
        echo "LP_BUNDLE_BUILT_BY=lp/$caller"
        echo "LP_HOST=$host"
    } > "$file"

    if [[ "$source_label" == base:* ]]; then
        local base_name="${source_label#base:}"
        local base_path="$BASE_BUNDLES_DIR/$base_name"
        local base_commit
        base_commit=$(_lp_bundle_meta_get "$base_path" "LP_BUNDLE_COMMIT")
        [[ -z "$base_commit" ]] && base_commit="unknown"
        echo "LP_BASE_NAME=$base_name" >> "$file"
        echo "LP_BASE_COMMIT=$base_commit" >> "$file"
    fi
}

_lp_bundle_format_age() {
    local built_at="$1"
    [[ -z "$built_at" ]] && { echo "?"; return; }

    local built_epoch now_epoch diff
    built_epoch=$(date -u -d "$built_at" +%s 2>/dev/null) || { echo "?"; return; }
    now_epoch=$(date -u +%s)
    diff=$((now_epoch - built_epoch))

    if (( diff < 60 )); then
        echo "${diff}s"
    elif (( diff < 3600 )); then
        echo "$((diff/60))m"
    elif (( diff < 86400 )); then
        echo "$((diff/3600))h"
    else
        echo "$((diff/86400))d"
    fi
}
