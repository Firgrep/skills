# Skills

Firgrep's agentic skills playground.

The `socratic-grill` is heavily inspired by [Matt Pocock's](https://github.com/mattpocock/skills), but with some additions to ground it in business expectations and product mindset as well as a more defined spec output. This is still being tested, so expect changes!

## Layout

`.agents/skills/` is the source of truth. `.claude/skills/` holds relative symlinks back to it, so Claude Code picks them up without duplicating content.

Adding a skill:

```sh
mkdir -p .agents/skills/<name>          # write SKILL.md here
ln -s ../../.agents/skills/<name> .claude/skills/<name>
```

Skills can also live outside this repo — symlink them into `~/.claude/skills/` to use them everywhere, or into another project's `.claude/skills/` to scope them there.

`socratic-grill` writes specs to `.dev/SPEC_<name>.md` — working files scoped to the current branch, not committed artifacts. The skill adds `.dev/` to `.gitignore` on first run if it isn't there already. Change it if you need.
