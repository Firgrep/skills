# Skills

Toolkit for more predictable and structured output from the LLM during planning and implementation.

## Quickstart

Two skills, used in order:

- `/struct-spec`: interviews you about a plan and writes a validated spec to `.localdev/SPEC_<name>.yaml`.
- `/struct-impl`: implements that spec requirement by requirement and tracks progress in `.localdev/IMPL_<name>.yaml`.

Install them into `~/.claude/skills/` and `~/.config/opencode/skills/` (a tool whose directory doesn't exist is skipped):

```sh
just install   # copy as real files, no stow needed (re-run to update)
just sync      # or symlink with stow, so edits in this repo apply live (needs stow >= 2.4.1; older versions likely work but are untested)
```

Without [just](https://github.com/casey/just), use `./sync.sh copy` or `./sync.sh` directly.

> [!IMPORTANT]
> The `.localdev/` files are working files scoped to the current branch, not committed artifacts. `struct-spec` adds `.localdev/` to `.gitignore` on first run if it isn't there already. Change it if you need.

## Comments

The `struct-spec` is heavily inspired by [Matt Pocock's](https://github.com/mattpocock/skills), but with a more defined, validated YAML spec output.

## Script Usage

- `./sync.sh` (or `./sync.sh sync`): Links / restows all skills into `~/.config/opencode/skills/` and `~/.claude/skills/`.
- `./sync.sh copy` (or `just install`): Copies the skills into the same locations as real files, without stow. Re-run it to update; it replaces earlier copies and stow symlinks of the same skills.
- `./sync.sh --dry-run`: Simulates the symlink operations without making changes.
- `./sync.sh unstow`: Unlinks/removes the symlinks from both locations.
