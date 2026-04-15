#!/bin/bash
# Usage: lp git patch [-c] [-v] <url>

source "$_LP_SCRIPTS_DIR/lib/output.sh"

if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "Download a git patch from a URL and apply it to the current repository."
    echo ""
    echo "Usage: lp git patch [-c] [-v] <url>"
    echo ""
    echo "Options:"
    echo "  -c, --commit    Apply the patch as a commit (default: leave changes uncommitted)"
    echo "  -v, --verbose   Show full git output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Examples:"
    echo "  lp git patch https://example.com/fix.patch"
    echo "  lp git patch --commit https://example.com/fix.patch"
    exit 0
fi

VERBOSE=0
COMMIT=0
URL=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --verbose|-v) VERBOSE=1; shift ;;
        --commit|-c)  COMMIT=1; shift ;;
        --help|-h)    shift ;;
        -*)
            lp_error "Unknown option: $1"
            lp_error "Usage: lp git patch [-c] [-v] <url>"
            exit 1
            ;;
        *) URL="$1"; shift ;;
    esac
done

if [[ -z "$URL" ]]; then
    lp_error "Usage: lp git patch [-c] [-v] <url>"
    exit 1
fi

TMP_PATCH=$(mktemp /tmp/lp-patch-XXXXXXXX.patch)
trap "rm -f '$TMP_PATCH'" EXIT

lp_step 1 2 "Downloading patch from $URL"
if ! curl -fsSL "$URL" -o "$TMP_PATCH"; then
    lp_error "Failed to download patch from: $URL"
    exit 1
fi

lp_step 2 2 "Applying patch"
if [[ "$COMMIT" -eq 1 ]]; then
    lp_run git am "$TMP_PATCH" || { _lp_exit=$?; return $_lp_exit 2>/dev/null || exit $_lp_exit; }
else
    lp_run git apply "$TMP_PATCH" || { _lp_exit=$?; return $_lp_exit 2>/dev/null || exit $_lp_exit; }
fi

lp_success "Patch applied successfully."
