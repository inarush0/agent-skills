# Agent skills

- `skills/` — managed by `npx skills@latest`. Do not hand-edit; `skills update` reverts changes silently.
- `local-skills/` — hand-maintained. Invisible to the CLI. Symlinked into `~/.claude/skills` and `~/.codex/skills`.

Codex reads `~/.agents/skills` natively; `local-skills/` requires the symlinks.
