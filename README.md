# Skills

Firgrep's agentic skills playground.

## Quickstart

_Required. stow version 2.4.1. (previous versions likely work but have not been tested)._

```sh
   ./sync.sh
```

> [!IMPORTANT]
> `socratic-grill` writes specs to `.localdev/SPEC_<name>.yaml` — working files scoped to the current branch, not committed artifacts. The skill adds `.localdev/` to `.gitignore` on first run if it isn't there already. Change it if you need.

## Comments

The `socratic-grill` is heavily inspired by [Matt Pocock's](https://github.com/mattpocock/skills), but with a more defined, validated YAML spec output. This is still being tested, so expect changes!

## Script Usage

- `./sync.sh` (or `./sync.sh sync`): Links / restows all skills into `~/.config/opencode/skills/` and `~/.claude/skills/`.
- `./sync.sh --dry-run`: Simulates the symlink operations without making changes.
- `./sync.sh uninstall`: Unlinks/removes the symlinks from both locations.
