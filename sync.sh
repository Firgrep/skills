#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGE_DIR="${REPO_DIR}/.agents"
PACKAGE_NAME="skills"

OPENCODE_BASE="${OPENCODE_BASE:-${HOME}/.config/opencode}"
OPENCODE_TARGET="${OPENCODE_BASE}/skills"

CLAUDE_BASE="${CLAUDE_BASE:-${HOME}/.claude}"
CLAUDE_TARGET="${CLAUDE_BASE}/skills"

if [[ ! -d "${PACKAGE_DIR}/${PACKAGE_NAME}" ]]; then
  echo "Error: Source package '${PACKAGE_DIR}/${PACKAGE_NAME}' does not exist." >&2
  exit 1
fi

show_help() {
  cat <<EOF
Usage: $(basename "$0") [command] [options]

Commands:
  sync, restow (default)   Link/re-link all skills to detected targets (uses stow)
  copy, install            Copy all skills into detected targets as real files (no stow)
  unstow, remove           Remove symlinks from detected targets
  help                     Show this help message

Options:
  -n, --dry-run            Simulate operations without making changes
  -v, --verbose            Increase verbosity
EOF
}

ACTION="sync"
STOW_FLAGS=("-v")
DRY_RUN=0

for arg in "$@"; do
  case "$arg" in
    sync|restow)
      ACTION="sync"
      ;;
    copy|install)
      ACTION="copy"
      ;;
    unstow|remove|delete)
      ACTION="unstow"
      ;;
    -n|--dry-run|--simulate)
      STOW_FLAGS+=("-n")
      DRY_RUN=1
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

if [[ "$ACTION" != "copy" ]] && ! command -v stow >/dev/null 2>&1; then
  echo "Error: GNU stow is not installed or not in PATH. Use '$(basename "$0") copy' to install without it." >&2
  exit 1
fi

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
elif [[ "$ACTION" == "copy" ]]; then
  echo "==> Copying skills..."
else
  echo "==> Removing skill symlinks..."
fi

for entry in "${TARGETS[@]}"; do
  NAME="${entry%%:*}"
  TARGET="${entry#*:}"

  echo "--- ${NAME} (${TARGET}) ---"
  if [[ "$ACTION" == "copy" ]]; then
    if [[ -L "$TARGET" ]]; then
      echo "ERROR: ${TARGET} is a symlink, not a real directory. Remove it and re-run." >&2
      exit 1
    fi
    if [[ "$DRY_RUN" -eq 0 ]]; then mkdir -p "$TARGET"; fi
    for src in "${PACKAGE_DIR}/${PACKAGE_NAME}"/*/; do
      skill="$(basename "$src")"
      dest="${TARGET}/${skill}"
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "COPY: ${skill} => ${dest}"
        continue
      fi
      # Replace any previous copy or stow symlink; never write through a symlink into the repo.
      if [[ -L "$dest" ]]; then rm "$dest"; else rm -rf "$dest"; fi
      cp -R "$src" "$dest"
      echo "COPIED: ${skill} => ${dest}"
    done
  elif [[ "$ACTION" == "sync" ]]; then
    # The target must be a real directory before stowing. If it is a symlink
    # (e.g. an earlier stow folded it into this repo), or missing, stow would
    # link the whole directory and later installs would write into the repo.
    if [[ -L "$TARGET" ]]; then
      echo "ERROR: ${TARGET} is a symlink, not a real directory. Remove it and re-run." >&2
      exit 1
    fi
    if [[ ! -d "$TARGET" ]]; then
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "WOULD CREATE: ${TARGET}"
        continue
      fi
      mkdir -p "$TARGET"
    fi
    stow "${STOW_FLAGS[@]}" -R -d "$PACKAGE_DIR" -t "$TARGET" "$PACKAGE_NAME"
  else
    if [[ -d "$TARGET" ]]; then
      stow "${STOW_FLAGS[@]}" -D -d "$PACKAGE_DIR" -t "$TARGET" "$PACKAGE_NAME"
    fi
  fi
done

echo "==> Done!"
