---
name: git-workflow
description: "Branch, commit, push, and PR conventions for GitHub work. Use at the START of any coding task (to get on the right branch), when RESUMING a session, and when work is COMPLETE (to push and open a PR). Also use when asked to 'open a PR', 'push this', 'start work on issue N', or when unsure which branch to be on."
---

# Git workflow

Andrew delegates all git housekeeping to agents. The goal: he merges a PR, then
immediately starts the next task without touching git himself. Never leave the
repo in a state that requires manual cleanup.

## Invariants

1. Never commit to the default branch (`main`, or whatever `origin/HEAD` points at).
2. Never create a branch from a stale base. Always fetch/pull first.
3. One unit of work = one branch = one PR.
4. Never force-push a branch that has an open PR unless explicitly asked.
5. Never merge a PR. That is Andrew's call.

## A. Starting new work

Run this before writing any code.

```bash
git rev-parse --abbrev-ref HEAD          # where am I?
git status --porcelain                   # uncommitted work?
```

**Decision:**

- On a feature branch with commits related to the task → this is resumed work. Go to section B.
- On a feature branch unrelated to the task → start fresh (below).
- On the default branch → start fresh (below).
- Uncommitted changes present → stop and ask before switching branches. Do not stash silently.

**Start fresh:**

```bash
DEFAULT=$(git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
DEFAULT=${DEFAULT:-main}
git checkout "$DEFAULT"
git pull --ff-only origin "$DEFAULT"
git checkout -b <branch-name>
```

If `git pull --ff-only` fails, the local default branch has diverged. Report it
and ask — do not merge or reset without permission.

If `refs/remotes/origin/HEAD` is missing, repair it once with
`git remote set-head origin --auto`.

### Branch naming

Format: `<type>/<issue-number>-<slug>`. Omit the issue number when there is no issue.

- Types: `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`.
- Slug: 2-5 words, lowercase, hyphenated, from the issue title or the task.
- Examples: `feat/412-oauth-token-refresh`, `fix/88-null-user-crash`, `chore/bump-deps`.

If the task references an issue, read it first to get the title and acceptance
criteria: `gh issue view <N>`.

If the task is a bare description with no issue number, check whether one
already exists before inventing a branch:
`gh issue list --search "<keywords>" --state open`.

### Base branch

Default to the repo's default branch. Branch from a long-lived branch instead
when there is evidence for it: the issue is assigned to a milestone/epic branch,
the task says so, or open PRs in the repo target that branch
(`gh pr list --json baseRefName`). When you pick a non-default base, say so
explicitly in your first message about the branch.

## B. Resuming work

When picking up a session that already has a branch:

```bash
git log --oneline -10
git status --porcelain
gh pr view --json number,state,baseRefName,isDraft 2>/dev/null
```

- Keep using the existing branch. Do not create a parallel branch for the same work.
- If a PR is already open, keep pushing to the same branch; the PR updates itself.
- If the branch is far behind its base and that matters,
  `git fetch origin && git rebase origin/<base>` (only if no one else is on the
  branch), or ask.

## C. Committing

- Commit in logical units as you go, not one giant commit at the end.
- Conventional-commit subjects: `feat: add token refresh`, `fix: handle null user`.
- Never `git add -A` blindly. Stage the files you actually changed.
- Never commit secrets, `.env` files, or large build artifacts.

## D. Completing work

```bash
git push -u origin HEAD
gh pr create --base "$DEFAULT" --title "<title>" --body "<body>"
```

PR body must include:

- A short summary of what changed and why.
- `Closes #<N>` when there's an issue (use `Refs #<N>` if it shouldn't auto-close).
- Test plan: what you ran, what passed.

Open the PR ready for review, not draft. After creating it, report the URL.

Before pushing: run the repo's tests/typecheck/lint if they exist. Do not open
a PR on knowingly broken code — if something fails and you can't fix it, say so
and ask before opening the PR.

If a PR for the branch already exists, update its body instead of opening a
second one: `gh pr edit <N> --body "<body>"`.

## E. When blocked

Ask, don't improvise, when: the working tree is dirty and you'd need to stash;
the base branch has diverged; a push is rejected; there are merge conflicts (use
the `resolving-merge-conflicts` skill); or the repo has an unfamiliar convention
that contradicts this skill. Repo-level `CLAUDE.md`/`AGENTS.md` conventions win
over this skill.
