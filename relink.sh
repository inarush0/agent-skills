#!/usr/bin/env bash
# Rebuild symlinks for every skill in local-skills/ into Claude Code and Codex.
# Idempotent: safe to re-run. Only ever touches links that point into local-skills/.
#
#   ./relink.sh            rebuild links
#   ./relink.sh --check    report problems, change nothing (exit 1 if any)
set -euo pipefail

AGENTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="$AGENTS_DIR/local-skills"
TOOL_DIRS=("$HOME/.claude/skills" "$HOME/.codex/skills")
REL_TARGET="../../.agents/local-skills"

check_only=false
[[ "${1:-}" == "--check" ]] && check_only=true

problems=0
note() { printf '  %s\n' "$1"; }
fail() { printf '  ✗ %s\n' "$1"; problems=$((problems + 1)); }
# Prints with a trailing newline so it can be called directly; the newline is
# stripped when used inside $(...).
tilde() { printf '%s\n' "${1/#$HOME/~}"; }

[[ -d "$LOCAL_DIR" ]] || { echo "no local-skills/ at $LOCAL_DIR"; exit 1; }

shopt -s nullglob
skills=("$LOCAL_DIR"/*/)
shopt -u nullglob
[[ ${#skills[@]} -gt 0 ]] || { echo "local-skills/ is empty; nothing to link"; exit 0; }

# Validate each skill before linking anything.
echo "Validating ${#skills[@]} skill(s) in local-skills/"
for path in "${skills[@]}"; do
  name="$(basename "$path")"

  if [[ ! -f "$path/SKILL.md" ]]; then
    fail "$name: no SKILL.md"
    continue
  fi

  # Frontmatter name must match the directory name, or the tools register a
  # second skill under a different name and the two collide.
  # One awk process, no pipeline: under `set -o pipefail` a `| head -1` can
  # SIGPIPE its upstream, fail the assignment, and abort the script silently.
  # \042 and \047 are double and single quote.
  declared="$(awk '
    /^---[[:space:]]*$/ { fm++; if (fm == 2) exit; next }
    fm == 1 && /^name:/ {
      sub(/^name:[[:space:]]*/, "")
      gsub(/^[\042\047]|[\042\047]$/, "")
      gsub(/[[:space:]]+$/, "")
      print; exit
    }
  ' "$path/SKILL.md")"
  if [[ -z "$declared" ]]; then
    fail "$name: SKILL.md has no 'name:' in frontmatter"
  elif [[ "$declared" != "$name" ]]; then
    fail "$name: frontmatter says name '$declared' — rename the folder or the field"
  fi

  # Codex reads this for display name and implicit-invocation policy.
  [[ -f "$path/agents/openai.yaml" ]] ||
    note "⚠ $name: no agents/openai.yaml — Codex will use defaults"

  # A name that also exists in the CLI-managed tree resolves unpredictably.
  [[ -e "$AGENTS_DIR/skills/$name" ]] &&
    fail "$name: also exists in CLI-managed skills/ — pick one"
done

if [[ $problems -gt 0 ]]; then
  echo
  echo "$problems problem(s); not linking."
  exit 1
fi

if $check_only; then
  echo
  echo "Link status:"
  for tool in "${TOOL_DIRS[@]}"; do
    for path in "${skills[@]}"; do
      name="$(basename "$path")"
      link="$tool/$name"
      if [[ ! -L "$link" ]]; then
        fail "missing: $(tilde "$link")"
      elif [[ "$(readlink "$link")" != "$REL_TARGET/$name" ]]; then
        fail "wrong target: $(tilde "$link") -> $(readlink "$link")"
      fi
    done
  done
  [[ $problems -eq 0 ]] && echo "  ✓ all links correct"
  exit $((problems > 0))
fi

echo
for tool in "${TOOL_DIRS[@]}"; do
  if [[ ! -d "$tool" ]]; then
    note "skipping $(tilde "$tool") (not installed)"
    continue
  fi
  tilde "$tool"
  for path in "${skills[@]}"; do
    name="$(basename "$path")"
    link="$tool/$name"

    # Refuse to clobber anything that isn't ours: a real directory here is
    # either a hand-placed skill or another tool's content.
    if [[ -e "$link" && ! -L "$link" ]]; then
      fail "$name: real directory in the way, leaving alone"
      continue
    fi
    if [[ -L "$link" ]]; then
      current="$(readlink "$link")"
      if [[ "$current" == "$REL_TARGET/$name" ]]; then
        note "= $name"
        continue
      fi
      [[ "$current" == *"local-skills"* ]] || {
        fail "$name: link points outside local-skills ($current), leaving alone"
        continue
      }
      rm "$link"
    fi
    ln -s "$REL_TARGET/$name" "$link"
    note "+ $name"
  done
done

echo
if [[ $problems -gt 0 ]]; then
  echo "Done, with $problems problem(s)."
  exit 1
fi
echo "Done. Restart Claude Code to pick up changes; Codex reloads on next run."
