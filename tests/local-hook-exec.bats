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
  run_hook commit-msg msg
  [ "$status" -eq 4 ]
}

@test "ignores local hook failure with NO_VERIFY_GLOBAL_HOOKS" {
  write_hook "$REPO/.husky/commit-msg" "exit 1"
  NO_VERIFY_GLOBAL_HOOKS=1 run_hook commit-msg msg
  [ "$status" -eq 0 ]
}
