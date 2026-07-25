# Using this repo with the git course

This repository is a **teaching fixture**. `sensor-logger` is a small, real C program — it builds, it has tests, they pass — but its git history was constructed on purpose so that the examples in the git course are things you can actually run instead of read.

Clone it, break it, and re-clone whenever you want a clean slate. Nothing here matters.

```bash
git clone <this repo's URL> sensor-logger
cd sensor-logger
```

## Do this first

Two settings the course assumes. Neither one travels with a clone, so you have to set them yourself:

```bash
git config --global user.name  "Your Name"
git config --global user.email "you@example.com"
git config --global merge.conflictStyle zdiff3
```

The third one matters more than it looks. By default git shows you a conflict as two versions — yours and theirs. `zdiff3` adds a third section showing the **common ancestor**, which is what turns "pick a side" into "see what each side was trying to do." The course's conflict walkthrough shows the three-section form.

## What's in the history

```
* refactor: clamp against the configured minimum   (main)
* docs: update calibration table
| * chore: add local config                        (tracked-config-oops)
|/
| * feat: log rejected readings to sensor.log      (issue-17)
|/
| * fix: clamp negative sensor readings            (fix-42)
|/
* chore: release v1.2                              <- tag v1.2, the fork point
* docs: add README with build instructions
* chore: ignore build output and local config
* test: add range checks for the clamp helper
* feat: validate readings against the configured range
* feat: initial sensor skeleton
```

Everything forks from `chore: release v1.2`. That commit is the **merge base** for every exercise below, which is the single most useful thing to understand about this layout.

The commit hashes you see will not match the ones printed in the course docs — hashes cover content, author, and date, so they are unique to this repo. The *shape* matches.

| Branch | Exists so you can |
|---|---|
| `main` | Be the branch you merge into |
| `fix-42` | Produce a **real merge conflict** — it edits the same line `main` did, differently |
| `issue-17` | Produce a **clean three-way merge** — it adds a new file and touches nothing `main` touched |
| `tracked-config-oops` | Meet the `.gitignore` gotcha: `config.env` is listed in `.gitignore` *and* committed anyway |

## Exercises

Each one maps to a page of the course. Do them in this order; every one is undoable.

**Git from First Principles.** Look at the database directly. Follow a commit to its tree and the tree to its blobs, then confirm that a branch really is a small text file:

```bash
git cat-file -p HEAD          # commit: tree hash, parent, author, committer
git cat-file -p HEAD^{tree}   # the directory listing that commit points at
cat .git/refs/heads/main      # 41 bytes: forty hex characters and a newline
cat .git/HEAD                 # a pointer to a pointer
```

**Merging, Rebasing, and Reading History.** Read the graph, then cause the conflict on purpose:

```bash
git log --oneline --graph --all
git merge fix-42              # CONFLICT in sensor.c — this is supposed to happen
git status                    # the worklist of unresolved files
```

Open `sensor.c` and look at the three sections between the markers: `main` clamped to a named constant, `fix-42` decided a negative reading should be an error instead, and the middle section shows what both started from. Resolve it however you like, then `git add sensor.c && git merge --continue` — or back out completely with `git merge --abort` and do it again.

Then try the merge that *doesn't* fight, and review a branch the way you'd review a colleague's:

```bash
git diff main...issue-17      # three dots: what this branch changed since the fork
git merge issue-17            # clean three-way merge
```

**Undoing Things in Git.** Everything above is reversible; prove it to yourself:

```bash
git reset --soft HEAD~1       # un-commit, keep the changes staged
git reflog                    # every pointer move, including the ones you regret
git reset --hard <hash>       # put the branch back where it was
```

**Ignoring Files in Git.** Build the project and watch the artifacts not show up:

```bash
make                          # writes build/sensor
git status                    # build/ is not mentioned — that is .gitignore working
git status --ignored          # now it is
git check-ignore -v build/sensor
```

Then meet the gotcha, which is the whole reason that branch exists:

```bash
git switch tracked-config-oops
git status                    # config.env shows up as tracked, despite .gitignore
git check-ignore -v config.env   # prints nothing: the file is tracked
git check-ignore -v --no-index config.env   # the pattern was fine all along
git rm --cached config.env    # the actual fix
```

**Git Worktrees and Parallel Agents.** Two checkouts of one database, at once:

```bash
git worktree add ../sensor-logger-fix42 fix-42
git worktree list
git worktree remove ../sensor-logger-fix42
```

**Pull, Commit, Push and Using git stash Safely** need a remote you can write to. Fork this repo, or `git remote set-url origin <your own>`, and the loop in those pages works as written.

## Building it

```bash
make          # -> build/sensor
make test     # runs tests/test_sensor.sh
make clean
```

Any C99 compiler works; there are no dependencies. Verified with `cc -Wall -Wextra -std=c99`. On Windows, build under WSL or Git Bash with a compiler installed — the git exercises themselves need no compiler at all, so skip `make` if you don't have one.

## Where this came from

The history is synthetic. Every commit before this one is attributed to a fictional `A. Developer <adev@example.com>` because it is course material, not anyone's real work.

The whole repository is generated by [`tools/build-fixture.sh`](tools/build-fixture.sh) — run it against an empty directory and you get this repo back, byte for byte apart from commit hashes. If an exercise needs changing, change the script and regenerate rather than patching history by hand.

Generated by CASE (Claude Code) on 2026-07-25.
