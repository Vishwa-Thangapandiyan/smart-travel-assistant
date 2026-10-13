# CLAUDE.md

The shared rules for every agent and contributor live in `AGENTS.md`,
imported below so Claude Code and Codex follow one set of rules that
can't drift apart. Edit `AGENTS.md`, not this file, when a rule changes.

@AGENTS.md

## Claude Code specifics

- **Attribution is off for everyone.** The checked-in
  `.claude/settings.json` sets `attribution` to empty strings and
  `sessionUrl` to `false`, so Claude Code adds no `Co-Authored-By`,
  `Claude-Session` or "Generated with" text. Don't override it in your
  local settings. Rule 8 in `AGENTS.md` still applies if a setting is ever
  missing.
- Claude Code may use skills, plugins, subagents, MCP, hooks and
  code-intelligence tooling where they help — this file doesn't restate
  what those do. Plan before substantial changes; skip the ceremony for
  small, obvious ones.
- Never silently override an architecture or ownership decision made
  outside the repo. If something looks wrong or undecided, flag it.
- Start a session from the repository root, so the whole repo is inside
  the working directory.
