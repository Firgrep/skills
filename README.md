# Skills

Toolkit for more predictable and structured output from the LLM during planning and implementation.

## Quickstart

_Required. stow version 2.4.1. (previous versions likely work but have not been tested)._

```sh
   ./sync.sh
```

```sh
    just sync # requires just task runner installed
```

> [!IMPORTANT]
> `struct-spec` writes specs to `.localdev/SPEC_<name>.yaml` — working files scoped to the current branch, not committed artifacts. The skill adds `.localdev/` to `.gitignore` on first run if it isn't there already. Change it if you need.

## Comments

The `struct-spec` is heavily inspired by [Matt Pocock's](https://github.com/mattpocock/skills), but with a more defined, validated YAML spec output.

## Script Usage

- `./sync.sh` (or `./sync.sh sync`): Links / restows all skills into `~/.config/opencode/skills/` and `~/.claude/skills/`.
- `./sync.sh copy` (or `just install`): Copies the skills into the same locations as real files, without stow. Re-run it to update; it replaces earlier copies and stow symlinks of the same skills.
- `./sync.sh --dry-run`: Simulates the symlink operations without making changes.
- `./sync.sh uninstall`: Unlinks/removes the symlinks from both locations.
