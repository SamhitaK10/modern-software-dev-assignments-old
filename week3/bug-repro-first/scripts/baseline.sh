#!/usr/bin/env bash
# Record and compare the set of failing tests so pre-existing failures are never blamed on a fix.
#   baseline.sh save    -- <test command...>   run and store failing test lines
#   baseline.sh compare -- <test command...>   run again and show only NEW and FIXED failures
# Works with any runner whose failures appear as FAIL / ✕ / FAILED / "not ok" lines
# (jest, pytest, go test, tap). State lives in $BASELINE_DIR, by default a temp directory
# outside the repo, so nothing stray is left in the working tree.
set -u
mode="${1:-}"; shift || true
[ "${1:-}" = "--" ] && shift
if [ -z "$mode" ] || [ $# -eq 0 ]; then
  echo "usage: baseline.sh save|compare -- <test command...>" >&2; exit 2
fi
dir="${BASELINE_DIR:-${TMPDIR:-/tmp}/bug-repro-baseline-$(basename "$PWD")}"
mkdir -p "$dir"

run() {
  # Strip timings and ANSI colour so reruns compare equal.
  "$@" 2>&1 | tee "$dir/$1.last.log" \
    | sed -E 's/\x1b\[[0-9;]*m//g; s/ \([0-9.]+ ?m?s\)//' \
    | grep -E '^\s*(FAIL|✕|FAILED|not ok|--- FAIL)' | sed -E 's/^\s+//' | sort -u
}

case "$mode" in
  save)
    run "$@" > "$dir/failing.before" || true
    echo "baseline saved: $(wc -l < "$dir/failing.before" | tr -d ' ') failing entries in $dir/failing.before"
    ;;
  compare)
    [ -f "$dir/failing.before" ] || { echo "no baseline; run 'save' first" >&2; exit 2; }
    run "$@" > "$dir/failing.after" || true
    new=$(comm -13 "$dir/failing.before" "$dir/failing.after")
    fixed=$(comm -23 "$dir/failing.before" "$dir/failing.after")
    echo "NEW failures:";   [ -n "$new" ]   && echo "$new"   || echo "  (none)"
    echo "FIXED failures:"; [ -n "$fixed" ] && echo "$fixed" || echo "  (none)"
    [ -z "$new" ]
    ;;
  *) echo "unknown mode: $mode" >&2; exit 2 ;;
esac
