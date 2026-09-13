---
name: implement
description: "Implement a piece of work based on a spec or set of tickets, from branch to pull request."
disable-model-invocation: true
---

# Implement

Take a piece of work from a spec, issue, or set of tickets all the way to an open
pull request. The user does no git housekeeping; you do all of it.

## 1. Get on the right branch

Before writing any code, call the Skill tool with "git-workflow" and follow
section A (starting new work) or B (resuming). That covers: pulling the latest
default branch, naming the branch after the issue, and detecting when this
session is continuing work that already has a branch.

Do not skip this because the change looks small. A one-line fix still lands
through a PR.

## 2. Implement

Implement the work described in the spec or tickets.

Use `/tdd` where possible, at pre-agreed seams.

Run typechecking regularly and single test files regularly. Run the full test
suite once at the end.

## 3. Commit as you go

Commit each logical unit as you complete it — a passing red→green cycle, a
finished module, a refactor — not everything at once at the end. A reviewer
should be able to read the branch commit by commit.

- Stage the files you actually changed. Never `git add -A` blindly.
- Conventional-commit subjects: `feat: add token refresh`, `fix: handle null user`.
- Don't commit knowingly broken code unless you say so in the message (`wip:`).

## 4. Review

Once the work is done, use `/code-review` to review it. Fix what it finds, and
commit the fixes.

## 5. Open the PR

Call the Skill tool with "git-workflow" and follow section D: push to origin and
open a PR targeting the default branch, with `Closes #<N>` and a test plan.
Report the PR URL.

Do not merge the PR.

## If you get blocked

Stop and ask rather than improvising, especially around git state — a dirty
tree, a diverged base, a rejected push. The `git-workflow` skill says when to
ask.
