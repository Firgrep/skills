#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${REPO_DIR}/.agents"
PACKAGE_NAME="skills"

OPENCODE_BASE="${OPENCODE_BASE:-${HOME}/.config/opencode}"
OPENCODE_TARGET="${OPENCODE_BASE}/skills"

CLAUDE_BASE="${CLAUDE_BASE:-${HOME}/.claude}"
CLAUDE_TARGET="${CLAUDE_BASE}/skills"

if ! command -v stow >/dev/null 2>&1; then
  echo "Error: GNU stow is not installed or not in PATH." >&2
  exit 1
fi

if [[ ! -d "${PACKAGE_DIR}/${PACKAGE_NAME}" ]]; then
  echo "Error: Source package '${PACKAGE_DIR}/${PACKAGE_NAME}' does not exist." >&2
  exit 1
fi

show_help() {
  cat <<EOF
Usage: $(basename "$0") [command] [options]

Commands:
  sync, restow (default)   Link/re-link all skills to detected targets
  unstow, remove           Remove symlinks from detected targets
  help                     Show this help message

Options:
  -n, --dry-run            Simulate operations without making changes
  -v, --verbose            Increase verbosity
EOF
}

ACTION="sync"
STOW_FLAGS=("-v")

for arg in "$@"; do
  case "$arg" in
    sync|restow)
      ACTION="sync"
      ;;
    unstow|remove|delete)
      ACTION="unstow"
      ;;
    -n|--dry-run|--simulate)
      STOW_FLAGS+=("-n")
      ;;
    -v|--verbose)
      STOW_FLAGS+=("-v")
      ;;
    -h|--help|help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      show_help
      exit 1
      ;;
  esac
done

TARGETS=()

if [[ -d "$OPENCODE_BASE" ]]; then
  TARGETS+=("OpenCode:${OPENCODE_TARGET}")
else
  echo "[-] Skipping OpenCode (${OPENCODE_BASE} does not exist)"
fi

if [[ -d "$CLAUDE_BASE" ]]; then
  TARGETS+=("Claude:${CLAUDE_TARGET}")
else
  echo "[-] Skipping Claude (${CLAUDE_BASE} does not exist)"
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "WARNING: No supported environments found (neither ${OPENCODE_BASE} nor ${CLAUDE_BASE} exist). Nothing to sync." >&2
  exit 1
fi

if [[ "$ACTION" == "sync" ]]; then
  echo "==> Syncing skills..."
else
  echo "==> Removing skill symlinks..."
fi

for entry in "${TARGETS[@]}"; do
  NAME="${entry%%:*}"
  TARGET="${entry#*:}"

  echo "--- ${NAME} (${TARGET}) ---"
  if [[ "$ACTION" == "sync" ]]; then
    mkdir -p "$TARGET"
    stow "${STOW_FLAGS[@]}" -R -d "$PACKAGE_DIR" -t "$TARGET" "$PACKAGE_NAME"
  else
    if [[ -d "$TARGET" ]]; then
      stow "${STOW_FLAGS[@]}" -D -d "$PACKAGE_DIR" -t "$TARGET" "$PACKAGE_NAME"
    fi
  fi
done

echo "==> Done!"
