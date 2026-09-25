#!/usr/bin/env bats

load "../command_helper"

setup() {
    lp_command_setup
}

teardown() {
    lp_command_teardown
}

@test "remove refuses to touch the master branch" {
    lp_stub git 0
    lp_stub tmux 1

    run "$_LP_SCRIPTS_DIR/commands/worktree/remove.sh" -y master

    [ "$status" -eq 1 ]
    ! grep -q "worktree remove" "$CALLS_LOG"
}

@test "remove stops a branch's own steps on a failed git worktree remove, but keeps other branches going" {
    mkdir -p "$HOME/dev/bundles/A" "$HOME/dev/bundles/B"
    lp_stub git '[[ "$*" == *"worktree remove"*"-A"* ]] && exit 1; exit 0'
    lp_stub tmux 1

    run "$_LP_SCRIPTS_DIR/commands/worktree/remove.sh" -y -b A B

    [ "$status" -eq 1 ]
    [ -d "$HOME/dev/bundles/A" ]
    ! grep -q "branch -D A" "$CALLS_LOG"
    grep -q "worktree remove.*-B" "$CALLS_LOG"
    grep -q "branch -D B" "$CALLS_LOG"
    [[ "$output" == *"A"* ]]
}

@test "remove stops a branch's steps when killing its session fails" {
    lp_stub tmux '[[ "$*" == *"kill-session"* ]] && exit 1; exit 0'
    lp_stub git 0

    run "$_LP_SCRIPTS_DIR/commands/worktree/remove.sh" -y A

    [ "$status" -eq 1 ]
    ! grep -q "worktree remove" "$CALLS_LOG"
}

@test "add (sourced) stops before copying .serena when git worktree add fails" {
    mkdir -p "$HOME/dev/projects/liferay-portal/.serena"
    lp_stub git '[[ "$*" == *"worktree add"* ]] && exit 1; exit 0'

    run lp_source_run bash "$_LP_SCRIPTS_DIR/commands/worktree/add.sh" newbranch

    [ "$status" -ne 0 ]
    [ ! -e "$HOME/dev/projects/liferay-portal-newbranch/.serena" ]
}

@test "clean restores preserved files and fails when git clean fails" {
    local repo="$HOME/dev/projects/liferay-portal-feat"
    mkdir -p "$repo"
    git init -q "$repo"
    mkdir -p "$repo/.idea"
    echo "marker" > "$repo/.idea/marker.txt"

    local real_git
    real_git=$(command -v git)

    lp_stub ant 0
    lp_stub git "$(cat <<EOF
if [[ "\$*" == *"clean -fdX"* ]]; then
    rm -rf .idea
    exit 1
fi
exec "$real_git" "\$@"
EOF
)"

    cd "$repo"
    run "$_LP_SCRIPTS_DIR/commands/worktree/clean.sh" -y feat

    [ "$status" -ne 0 ]
    [ -d "$repo/.idea" ]
    [ -f "$repo/.idea/marker.txt" ]
}

@test "clean runs inside the target worktree regardless of the caller's cwd" {
    local repo="$HOME/dev/projects/liferay-portal-feat"
    mkdir -p "$repo"
    git init -q "$repo"
    echo "ignored.txt" > "$repo/.gitignore"

    local elsewhere="$TEST_HOME/elsewhere"
    mkdir -p "$elsewhere"
    git init -q "$elsewhere"
    echo "ignored.txt" > "$elsewhere/.gitignore"
    echo "marker" > "$elsewhere/ignored.txt"

    local real_git
    real_git=$(command -v git)

    lp_stub ant 'echo "$PWD" >> '"$CALLS_LOG"
    lp_stub git "$(cat <<EOF
if [[ "\$*" == *"clean -fdX"* ]]; then
    echo "\$PWD" >> "$CALLS_LOG"
fi
exec "$real_git" "\$@"
EOF
)"

    cd "$elsewhere"
    run "$_LP_SCRIPTS_DIR/commands/worktree/clean.sh" -y feat

    [ "$status" -eq 0 ]
    [ -f "$elsewhere/ignored.txt" ]
    grep -qF "$repo" "$CALLS_LOG"
    ! grep -qF "$elsewhere" "$CALLS_LOG"
}

@test "clean does not attempt git clean when ant fails" {
    local repo="$HOME/dev/projects/liferay-portal-feat"
    mkdir -p "$repo"
    git init -q "$repo"

    lp_stub ant 1
    lp_stub git 0

    cd "$repo"
    run "$_LP_SCRIPTS_DIR/commands/worktree/clean.sh" -y feat

    ! grep -q "clean -fdX" "$CALLS_LOG"
}
