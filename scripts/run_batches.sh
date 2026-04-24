#!/usr/bin/env bash
set -euo pipefail

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=false
BATCHES=()

usage() {
  echo "Usage: $0 [--list] [--batch <nums>] [--dry-run]"
  echo ""
  echo "  --list           List available batch numbers"
  echo "  --batch 2,3,10   Comma-separated batch numbers to run"
  echo "  --dry-run        Pass dry-run mode to underlying scripts"
  exit 0
}

list_batches() {
  echo "Available batches:"
  for f in "$SCRIPTS_DIR"/create_batch_*_issues.sh; do
    num=$(basename "$f" | grep -o '[0-9]\+')
    echo "  batch $num  ->  $(basename "$f")"
  done
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --list)    list_batches; exit 0 ;;
    --dry-run) DRY_RUN=true ;;
    --batch)   IFS=',' read -ra BATCHES <<< "$2"; shift ;;
    --help|-h) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
  shift
done

if [[ ${#BATCHES[@]} -eq 0 ]]; then
  echo "Error: no batches specified. Use --batch <nums> or --list to see options."
  exit 1
fi

EXIT_CODE=0

for num in "${BATCHES[@]}"; do
  script="$SCRIPTS_DIR/create_batch_${num}_issues.sh"
  if [[ ! -f "$script" ]]; then
    echo "✗ Batch $num not found: $script"
    EXIT_CODE=1
    continue
  fi

  echo "→ Running batch $num..."
  if $DRY_RUN; then
    DRY_RUN=true bash "$script" && echo "✓ Batch $num done (dry-run)" || { echo "✗ Batch $num failed"; EXIT_CODE=1; }
  else
    bash "$script" && echo "✓ Batch $num done" || { echo "✗ Batch $num failed"; EXIT_CODE=1; }
  fi
done

exit $EXIT_CODE
