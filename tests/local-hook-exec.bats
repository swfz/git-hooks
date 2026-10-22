#!/usr/bin/env bats

HOOKS_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/../hooks" && pwd)"

setup() {
  REPO="$BATS_TEST_TMPDIR/repo"
  BIN="$BATS_TEST_TMPDIR/bin"
  LOG="$BATS_TEST_TMPDIR/called.log"
  mkdir -p "$REPO" "$BIN"
  git -C "$REPO" init -q

  # 呼び出された引数を記録するだけのダミー lefthook
  cat > "$BIN/lefthook" <<EOF
#!/bin/bash
echo "path-lefthook \$*" >> "$LOG"
exit \${FAKE_LEFTHOOK_RC:-0}
EOF
  chmod +x "$BIN/lefthook"
  PATH="$BIN:$PATH"
  unset NO_VERIFY_GLOBAL_HOOKS LOCAL_HOOK_FAILED LOCAL_HOOK_IS_CALLED
}

run_hook() {
  cd "$REPO"
  run "$HOOKS_DIR/$1" "${@:2}"
}

write_hook() {
  mkdir -p "$(dirname "$1")"
  printf '#!/bin/bash\n%s\n' "$2" > "$1"
  chmod +x "$1"
}

@test "runs 'lefthook run --no-auto-install <hook>' with args when lefthook.yml exists" {
  touch "$REPO/lefthook.yml"
  run_hook commit-msg .git/COMMIT_EDITMSG
  [ "$status" -eq 0 ]
  [ "$(cat "$LOG")" = "path-lefthook run --no-auto-install commit-msg .git/COMMIT_EDITMSG" ]
}

@test "detects every lefthook config file name" {
  for f in lefthook.yaml .lefthook.yml .config/lefthook.yml lefthook.toml lefthook.json lefthook.jsonc; do
    rm -rf "$REPO/lefthook."* "$REPO/.lefthook."* "$REPO/.config" "$LOG"
    mkdir -p "$(dirname "$REPO/$f")"
    touch "$REPO/$f"
    run_hook pre-push
    [ "$status" -eq 0 ]
    [ "$(cat "$LOG")" = "path-lefthook run --no-auto-install pre-push" ] || { echo "not detected: $f"; false; }
  done
}

@test "does not run lefthook without config" {
  run_hook commit-msg msg
  [ "$status" -eq 0 ]
  [ ! -e "$LOG" ]
}

@test "fails when lefthook fails" {
  touch "$REPO/lefthook.yml"
  FAKE_LEFTHOOK_RC=3 run_hook commit-msg msg
  [ "$status" -eq 3 ]
}

@test "prefers node_modules/.bin/lefthook over PATH" {
  touch "$REPO/lefthook.yml"
  write_hook "$REPO/node_modules/.bin/lefthook" "echo \"local-lefthook \$*\" >> \"$LOG\""
  run_hook commit-msg msg
  [ "$status" -eq 0 ]
  [ "$(cat "$LOG")" = "local-lefthook run --no-auto-install commit-msg msg" ]
}

@test "fails when config exists but lefthook is not installed" {
  touch "$REPO/lefthook.yml"
  rm "$BIN/lefthook"
  PATH="/usr/bin:/bin" run_hook commit-msg msg
  [ "$status" -ne 0 ]
  [[ "$output" == *"lefthook command is not installed"* ]]
}

@test "does not run lefthook twice when .git/hooks is installed by lefthook" {
  touch "$REPO/lefthook.yml"
  write_hook "$REPO/.git/hooks/commit-msg" "echo \"git-hooks lefthook \$*\" >> \"$LOG\""
  run_hook commit-msg msg
  [ "$status" -eq 0 ]
  [ "$(cat "$LOG")" = "git-hooks lefthook msg" ]
}

@test "runs both unrelated .git/hooks and lefthook" {
  touch "$REPO/lefthook.yml"
  write_hook "$REPO/.git/hooks/commit-msg" "echo \"local \$*\" >> \"$LOG\""
  run_hook commit-msg msg
  [ "$status" -eq 0 ]
  [ "$(cat "$LOG")" = "$(printf 'local msg\npath-lefthook run --no-auto-install commit-msg msg')" ]
}

@test "runs husky hook with args" {
  write_hook "$REPO/.husky/commit-msg" "echo \"husky \$*\" >> \"$LOG\""
  run_hook commit-msg msg
  [ "$status" -eq 0 ]
  [ "$(cat "$LOG")" = "husky msg" ]
}

@test "fails when husky hook fails" {
  write_hook "$REPO/.husky/commit-msg" "exit 2"
  run_hook commit-msg msg
  [ "$status" -eq 2 ]
}

@test "keeps earlier local hook failure even if later hooks succeed" {
  write_hook "$REPO/.git/hooks/commit-msg" "exit 4"
  write_hook "$REPO/.husky/commit-msg" "exit 0"
  touch "$REPO/lefthook.yml"
  run_hook commit-msg msg
  [ "$status" -eq 4 ]
}

@test "ignores local hook failure with NO_VERIFY_GLOBAL_HOOKS" {
  touch "$REPO/lefthook.yml"
  NO_VERIFY_GLOBAL_HOOKS=1 FAKE_LEFTHOOK_RC=1 run_hook commit-msg msg
  [ "$status" -eq 0 ]
}
