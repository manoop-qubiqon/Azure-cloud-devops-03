# Git Practice Exercises

---

## How to use this workbook

1. Create a practice folder somewhere safe: `mkdir ~/git-practice && cd ~/git-practice`
2. Each exercise is **self-contained** — read the **Goal**, try it yourself, then peek at the **Hint** if stuck.
3. **Solutions are at the bottom** of this file. Don't scroll down until you've tried!
4. Check off each box as you complete it: `- [x]`
5. If something breaks badly, just `rm -rf` the practice repo and start over. That's the beauty of practice repos.

**Legend:** 🟢 Beginner · 🟡 Intermediate · 🔴 Advanced · ⚙️ DevOps scenario

---

## Level 1 — Setup & First Repo 🟢

### Exercise 1.1 — Configure your identity
- [ ] **Goal:** Set your global Git username and email, then verify them.
- **Hint:** `git config --global ...`
- **Expected:** `git config --list --global` shows both values.

### Exercise 1.2 — Set up useful aliases
- [ ] **Goal:** Create three global aliases: `st` for `status`, `co` for `checkout`, and `lg` for a pretty one-line log with graph.
- **Hint:** `git config --global alias.<name> "<command>"`
- **Verify:** `git st` works in any repo.

### Exercise 1.3 — Initialize your first repo
- [ ] **Goal:** Create a folder called `my-first-repo`, turn it into a Git repository, and confirm with `git status`.
- **Expected:** Output says *"On branch main"* (or `master`) and *"No commits yet"*.

### Exercise 1.4 — Make your first commit
- [ ] **Goal:** Inside `my-first-repo`, create a `README.md` with the line `# My First Repo`, stage it, and commit it with the message `"Initial commit"`.
- **Verify:** `git log` shows exactly one commit.

### Exercise 1.5 — Inspect repository state
- [ ] **Goal:** Add a second file `notes.txt` with any text. Without committing, use commands to answer:
  1. Which file is untracked?
  2. Which file is tracked and clean?
- **Hint:** `git status` and `git ls-files`.

---

## Level 2 — Staging, Diffs & History 🟢

### Exercise 2.1 — The staging area
- [ ] **Goal:** Modify `README.md` (add a new line). Use a single command to see what changed **before** staging, and another to see what changed **after** staging.
- **Hint:** `git diff` vs `git diff --staged`.

### Exercise 2.2 — Partial staging
- [ ] **Goal:** Make **two unrelated changes** in the same file (e.g. add two paragraphs at different places). Stage only **one** of them.
- **Hint:** `git add -p`

### Exercise 2.3 — Unstage a file
- [ ] **Goal:** Stage a file with `git add`, then unstage it without losing the changes.
- **Hint:** `git restore --staged <file>` (or `git reset HEAD <file>` on older Git).

### Exercise 2.4 — Amend the last commit
- [ ] **Goal:** You just committed `"Fix typo"` but forgot to include `notes.txt`. Add it and amend the previous commit so history still shows one commit.
- **Hint:** `git commit --amend --no-edit`

### Exercise 2.5 — Browse history
- [ ] **Goal:** Make 5 commits. Then use `git log` to display only:
  - The last 3 commits, one line each
  - All commits authored by you in the last week
  - All commits that changed `README.md`
- **Hint:** `--oneline`, `-n 3`, `--author`, `--since`, `-- <file>`.

### Exercise 2.6 — Who changed what
- [ ] **Goal:** Use `git blame` on `README.md` to see who last modified each line.

---

## Level 3 — Branching & Merging 🟡

### Exercise 3.1 — Create and switch
- [ ] **Goal:** Create a branch called `feature/login`, switch to it, and confirm with `git branch`.
- **Hint:** `git switch -c` (modern) or `git checkout -b` (classic).

### Exercise 3.2 — Diverge and merge
- [ ] **Goal:**
  1. On `main`, commit a change to `README.md`.
  2. Create `feature/about`, add an `ABOUT.md` file, commit it.
  3. Switch back to `main`, merge `feature/about` into `main`.
- **Verify:** `git log --oneline --graph --all` shows the merge.

### Exercise 3.3 — Fast-forward vs no-ff merge
- [ ] **Goal:** Repeat 3.2, but this time force a merge commit even when fast-forward would work. Compare the graphs.
- **Hint:** `git merge --no-ff <branch>`

### Exercise 3.4 — Resolve a merge conflict
- [ ] **Goal:** Deliberately create a conflict:
  1. On `main`, edit line 1 of `README.md` to say `Hello from main`.
  2. Create `feature/greet`, edit the same line 1 to say `Hello from feature`.
  3. Merge `feature/greet` into `main` and resolve the conflict so the final line reads `Hello from both`.
- **Hint:** Look for `<<<<<<<`, `=======`, `>>>>>>>` markers.

### Exercise 3.5 — Delete branches
- [ ] **Goal:** Delete `feature/login` (merged) and a never-merged branch you create called `experimental` (which needs the force flag).
- **Hint:** `git branch -d` vs `git branch -D`.

### Exercise 3.6 — List branches
- [ ] **Goal:** List all local branches, then all remote-tracking branches, then all branches everywhere.
- **Hint:** `git branch`, `git branch -r`, `git branch -a`.

---

## Level 4 — Remotes, Push & Pull 🟡

> For these exercises, create a **free empty repo** on GitHub/GitLab (no README), or use a local bare repo: `git init --bare ~/remotes/practice.git`

### Exercise 4.1 — Add a remote
- [ ] **Goal:** Add the remote URL to your existing local repo as `origin`. List remotes to confirm.
- **Hint:** `git remote add origin <url>` · `git remote -v`

### Exercise 4.2 — First push
- [ ] **Goal:** Push your `main` branch to `origin` and set upstream tracking so future `git push` works without arguments.
- **Hint:** `git push -u origin main`

### Exercise 4.3 — Clone elsewhere
- [ ] **Goal:** In a *different* directory, `git clone` the remote, make a commit, push it back.

### Exercise 4.4 — Fetch vs Pull
- [ ] **Goal:** In your original repo, run `git fetch` and observe — no files change in your working directory. Then run `git pull` and observe what's different.
- **Reflect:** Why is `fetch` safer than `pull` in shared repos?

### Exercise 4.5 — Pull with rebase
- [ ] **Goal:** Configure your repo so `git pull` always rebases instead of merging.
- **Hint:** `git config pull.rebase true`

### Exercise 4.6 — Safe force push
- [ ] **Goal:** Amend a pushed commit, then push it back **without overwriting a teammate's work**.
- **Hint:** `git push --force-with-lease` — never plain `--force` on shared branches.

---

## Level 5 — Stash, Tags & Cleanup 🟡

### Exercise 5.1 — Stash work in progress
- [ ] **Goal:** Start editing `README.md`, then realize you need to switch branches **without committing**. Stash, switch, do something, come back, restore your stash.
- **Hint:** `git stash` · `git stash pop`

### Exercise 5.2 — Multiple stashes
- [ ] **Goal:** Create three named stashes, list them, then apply the middle one specifically.
- **Hint:** `git stash push -m "message"` · `git stash list` · `git stash apply stash@{1}`

### Exercise 5.3 — Lightweight vs annotated tags
- [ ] **Goal:** Create a lightweight tag `v0.1.0-light` and an annotated tag `v0.1.0` with the message `"First release"`. Push tags to the remote.
- **Hint:** `git tag <name>` vs `git tag -a <name> -m "..."` · `git push --tags`

### Exercise 5.4 — Tag an older commit
- [ ] **Goal:** Tag a commit from 3 commits ago as `v0.0.9`.
- **Hint:** `git tag -a v0.0.9 <sha>`

### Exercise 5.5 — Clean untracked files
- [ ] **Goal:** Create some throwaway files (`temp.log`, `build/`), then preview what `git clean` would remove **before** removing them.
- **Hint:** `git clean -nd` (dry-run) then `git clean -fd`.

---

## Level 6 — Undoing Changes 🔴

### Exercise 6.1 — Discard working-tree changes
- [ ] **Goal:** Edit `README.md`, then revert it back to the last committed version without losing the file.
- **Hint:** `git restore <file>`

### Exercise 6.2 — Soft reset
- [ ] **Goal:** Make 3 commits. Then "undo" the last 2 commits **while keeping the changes staged**, so you can recombine them into one commit.
- **Hint:** `git reset --soft HEAD~2`

### Exercise 6.3 — Mixed vs hard reset
- [ ] **Goal:** Create a commit you regret. Reset it three different ways in three sandbox attempts and compare:
  - `--soft` — what state are changes in?
  - `--mixed` (default) — what state are changes in?
  - `--hard` — what happens to the changes?

### Exercise 6.4 — Safe revert on a public branch
- [ ] **Goal:** You pushed a bad commit to `main` and your teammates have pulled it. Undo it **without rewriting history**.
- **Hint:** `git revert <sha>` creates a new commit that inverts the change.

### Exercise 6.5 — Cherry-pick a commit
- [ ] **Goal:** From a feature branch, find a single commit and apply only that one onto `main`.
- **Hint:** `git cherry-pick <sha>`

### Exercise 6.6 — Recover a "lost" commit
- [ ] **Goal:** Hard-reset your branch backwards, losing 2 commits. Then recover them using the reflog.
- **Hint:** `git reflog` shows every HEAD move. Find the SHA and `git reset --hard <sha>`.

---

## Level 7 — Rebase & History Rewriting 🔴

### Exercise 7.1 — Rebase a feature branch
- [ ] **Goal:** Create a feature branch from an older `main`. Have `main` advance with new commits. Rebase your feature branch onto the latest `main`.
- **Hint:** `git switch feature` then `git rebase main`

### Exercise 7.2 — Squash with interactive rebase
- [ ] **Goal:** Make 5 small WIP commits on a feature branch. Squash them into **one clean commit** with a proper message before merging.
- **Hint:** `git rebase -i HEAD~5` — change `pick` to `squash` (or `s`) on all but the first.

### Exercise 7.3 — Reorder commits
- [ ] **Goal:** Make 3 commits, then use interactive rebase to swap the order of the last two.
- **Hint:** `git rebase -i HEAD~3` — just swap the lines.

### Exercise 7.4 — Edit an old commit message
- [ ] **Goal:** Change the message of a commit that is **not** the latest.
- **Hint:** `git rebase -i HEAD~N` — change `pick` to `reword`.

### Exercise 7.5 — Split a commit
- [ ] **Goal:** You have a commit that touches two unrelated files. Split it into two separate commits.
- **Hint:** Interactive rebase → mark `edit` → `git reset HEAD^` → stage and commit each piece separately → `git rebase --continue`.

### Exercise 7.6 — Abort a bad rebase
- [ ] **Goal:** Start a rebase, encounter a conflict, decide it's too messy, abort cleanly.
- **Hint:** `git rebase --abort`

---

## Level 8 — Real-World DevOps Scenarios ⚙️

### Exercise 8.1 — Hotfix workflow
- [ ] **Scenario:** Production is broken. You're on `develop` with half-finished work.
- **Goal:**
  1. Stash your work.
  2. Switch to `main`, branch off `hotfix/critical-bug`.
  3. Make a one-line fix, commit, tag it `v1.0.1`.
  4. Merge `hotfix/...` back into both `main` and `develop`.
  5. Restore your stash on `develop` and continue.

### Exercise 8.2 — Reviewing a teammate's PR locally
- [ ] **Scenario:** A colleague opened PR #42 from branch `feature/payments`. You want to test it locally before approving.
- **Goal:** Fetch and check out their branch, run tests, then return to `main`.
- **Hint:** `git fetch origin` then `git switch feature/payments` (or `git switch -c local-review origin/feature/payments`).

### Exercise 8.3 — `.gitignore` for a Terraform project
- [ ] **Goal:** Create a `.gitignore` that excludes:
  - `*.tfstate` and `*.tfstate.backup`
  - `.terraform/` directories
  - `.tfvars` files (except `*.example.tfvars`)
  - `crash.log`
- **Bonus:** A file already committed that should now be ignored — remove it from tracking **without deleting it locally**.
- **Hint:** `git rm --cached <file>`

### Exercise 8.4 — Stop tracking secrets you accidentally committed
- [ ] **Scenario:** You committed `.env` containing AWS keys.
- **Goal:**
  1. Remove `.env` from the repo (but keep your local copy).
  2. Add `.env` to `.gitignore`.
  3. Commit and push.
  4. **Then** rotate the keys (because they're now in history forever!).
- **Bonus thought:** What tool would you use to scrub the secret from *all* history? (`git filter-repo` or BFG).

### Exercise 8.5 — Tagging a release in CI
- [ ] **Scenario:** Your CI pipeline triggers on tag pushes matching `v*`.
- **Goal:**
  1. On `main`, create an annotated tag `v2.3.0` with a changelog message.
  2. Push the tag to trigger the pipeline.
  3. List all tags reachable from `main`.

### Exercise 8.6 — GitOps Kubernetes manifest update
- [ ] **Scenario:** Your team uses Argo CD to sync `k8s/` manifests from `main`. You need to bump the image tag from `v1.2.0` to `v1.2.1`.
- **Goal:**
  1. Branch from `main` as `release/v1.2.1`.
  2. Edit `k8s/deployment.yaml` to update the image tag.
  3. Commit with a conventional message: `chore(k8s): bump api image to v1.2.1`.
  4. Push and open a PR.
  5. After merge, verify with `git log -- k8s/deployment.yaml` that your change is the latest.

### Exercise 8.7 — Bisect to find a regression
- [ ] **Scenario:** Tests passed on `v1.0.0` but fail on `main`. Find the commit that broke them.
- **Goal:** Use `git bisect` to binary-search through history.
- **Hint:**
  ```
  git bisect start
  git bisect bad         # current is broken
  git bisect good v1.0.0
  # Git checks out a commit in the middle; test it
  git bisect good        # or 'bad' depending on result
  # repeat until Git names the culprit
  git bisect reset
  ```

### Exercise 8.8 — Recover from a force-pushed branch
- [ ] **Scenario:** A teammate force-pushed over your branch. Your local has commits that are no longer on the remote.
- **Goal:** Identify which of your local commits no longer exist on origin, and decide whether to rebase or cherry-pick them onto the new remote tip.
- **Hint:** `git fetch origin && git log origin/<branch>..HEAD` shows commits you have that remote doesn't.

### Exercise 8.9 — Submodule basics
- [ ] **Goal:** Add a public repo (e.g., a shared Helm chart repo) as a submodule, commit the submodule reference, then clone your repo elsewhere with `--recurse-submodules`.
- **Hint:** `git submodule add <url> path/to/sub`

### Exercise 8.10 — Worktrees for parallel work
- [ ] **Scenario:** You're mid-debug on `main`, but a P0 hotfix needs immediate attention. You don't want to stash or context-switch.
- **Goal:** Create a separate working tree for the hotfix branch in another folder, do the fix there, then remove the worktree.
- **Hint:** `git worktree add ../hotfix hotfix/p0` · `git worktree remove ../hotfix`

---

## Challenge problems 🔴🔴

### Challenge 1 — The split-history surgeon
You have a repo where two unrelated projects were committed mixed-together. Use `git filter-repo` (or `git filter-branch`) to extract just the commits affecting `projectA/` into a brand new repo with full history.

### Challenge 2 — The "merge from the future"
Two long-lived branches `release-1.x` and `release-2.x` have diverged for months. A bug-fix commit on `release-1.x` needs to land on `release-2.x` — but only that *one* commit, with no other changes. Do it cleanly without polluting either branch's history. *(Hint: `cherry-pick -x`).*

### Challenge 3 — Reproducible commit
Create a commit whose SHA is **exactly the same** when a teammate replays your steps. What inputs must be identical? *(Answer: tree contents, parent SHA, author name + email + timestamp, committer name + email + timestamp, and commit message — Git hashes are deterministic.)*

### Challenge 4 — The pre-commit guardian
Write a `.git/hooks/pre-commit` script (bash) that **blocks any commit** containing the string `AKIA` (an AWS access-key prefix) anywhere in staged changes. Test that it actually prevents the commit.

---

## Solutions

> 🛑 Don't peek until you've tried. Some have multiple valid answers — these are common ones.

### Level 1
```bash
# 1.1
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --list --global

# 1.2
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.lg "log --oneline --graph --decorate --all"

# 1.3
mkdir my-first-repo && cd my-first-repo
git init
git status

# 1.4
echo "# My First Repo" > README.md
git add README.md
git commit -m "Initial commit"
git log

# 1.5
echo "some notes" > notes.txt
git status        # shows notes.txt as untracked
git ls-files      # lists only README.md (tracked)
```

### Level 2
```bash
# 2.1
git diff              # unstaged changes
git diff --staged     # staged changes

# 2.2
git add -p            # interactive: y/n per hunk

# 2.3
git restore --staged file.txt

# 2.4
git add notes.txt
git commit --amend --no-edit

# 2.5
git log -3 --oneline
git log --author="Your Name" --since="1 week ago"
git log -- README.md

# 2.6
git blame README.md
```

### Level 3
```bash
# 3.1
git switch -c feature/login
git branch

# 3.2
# on main
echo "main change" >> README.md && git commit -am "main edit"
git switch -c feature/about
echo "# About" > ABOUT.md && git add . && git commit -m "add about"
git switch main
git merge feature/about

# 3.3
git merge --no-ff feature/about

# 3.4
# After conflict markers appear, manually edit README.md
# then:
git add README.md
git commit            # default merge-commit message is fine

# 3.5
git branch -d feature/login        # safe delete (must be merged)
git branch -D experimental         # force delete

# 3.6
git branch        # local
git branch -r     # remote
git branch -a     # all
```

### Level 4
```bash
# 4.1
git remote add origin git@github.com:you/repo.git
git remote -v

# 4.2
git push -u origin main

# 4.4
git fetch         # downloads, nothing changes locally
git pull          # fetch + merge into current branch

# 4.5
git config pull.rebase true

# 4.6
git commit --amend
git push --force-with-lease
```

### Level 5
```bash
# 5.1
git stash
git switch other-branch
# ...
git switch -
git stash pop

# 5.2
git stash push -m "wip auth"
git stash push -m "wip ui"
git stash push -m "wip tests"
git stash list
git stash apply stash@{1}

# 5.3
git tag v0.1.0-light
git tag -a v0.1.0 -m "First release"
git push --tags

# 5.4
git tag -a v0.0.9 <sha>

# 5.5
git clean -nd     # dry-run preview
git clean -fd     # actually remove
```

### Level 6
```bash
# 6.1
git restore README.md

# 6.2
git reset --soft HEAD~2

# 6.3
# --soft: changes stay staged
# --mixed: changes stay in working tree, unstaged
# --hard: changes gone, working tree matches commit

# 6.4
git revert <bad-sha>
git push

# 6.5
git cherry-pick <sha>

# 6.6
git reflog
git reset --hard HEAD@{2}    # whichever entry has your work
```

### Level 7
```bash
# 7.1
git switch feature
git rebase main

# 7.2
git rebase -i HEAD~5
# in editor: keep first as 'pick', change rest to 's' (squash)

# 7.3
git rebase -i HEAD~3
# swap two lines in editor

# 7.4
git rebase -i HEAD~N
# change 'pick' -> 'reword' on target line

# 7.5
git rebase -i HEAD~N
# mark target 'edit'
git reset HEAD^
git add fileA && git commit -m "part A"
git add fileB && git commit -m "part B"
git rebase --continue

# 7.6
git rebase --abort
```

### Level 8 (selected)
```bash
# 8.1 hotfix
git stash
git switch main
git switch -c hotfix/critical-bug
# edit, then:
git commit -am "fix: critical bug"
git tag -a v1.0.1 -m "Hotfix"
git switch main && git merge --no-ff hotfix/critical-bug
git switch develop && git merge --no-ff hotfix/critical-bug
git branch -d hotfix/critical-bug
git stash pop

# 8.3 .gitignore (Terraform)
cat > .gitignore <<'EOF'
*.tfstate
*.tfstate.backup
.terraform/
*.tfvars
!*.example.tfvars
crash.log
EOF

# 8.4 remove tracked secret
git rm --cached .env
echo ".env" >> .gitignore
git commit -am "stop tracking .env"
# ROTATE THE KEYS NOW.

# 8.7 bisect
git bisect start
git bisect bad
git bisect good v1.0.0
# test, then git bisect good/bad until done
git bisect reset

# 8.10 worktree
git worktree add ../hotfix -b hotfix/p0 main
cd ../hotfix
# fix, commit, push
cd -
git worktree remove ../hotfix
```

### Challenge 4 — pre-commit hook
```bash
cat > .git/hooks/pre-commit <<'EOF'
#!/usr/bin/env bash
if git diff --cached | grep -qE 'AKIA[0-9A-Z]{16}'; then
  echo "❌  AWS access key detected in staged changes. Commit blocked."
  exit 1
fi
EOF
chmod +x .git/hooks/pre-commit
```

---

## Quick reference card

| Need to...                         | Command                                  |
| ---------------------------------- | ---------------------------------------- |
| See what changed                   | `git diff` / `git diff --staged`         |
| Throw away unstaged changes        | `git restore <file>`                     |
| Unstage a file                     | `git restore --staged <file>`            |
| Undo last commit, keep changes     | `git reset --soft HEAD~1`                |
| Undo last commit, lose changes     | `git reset --hard HEAD~1`              |
| Undo a *pushed* commit safely      | `git revert <sha>`                       |
| Recover a "lost" commit            | `git reflog` → `git reset --hard <sha>`  |
| Switch branch with dirty WIP       | `git stash` → switch → `git stash pop`   |
| Sync without merge noise           | `git pull --rebase`                      |
| Push but don't clobber others      | `git push --force-with-lease`            |
| Pick one commit from another branch| `git cherry-pick <sha>`                  |
| Find the commit that broke things  | `git bisect start`                       |

---

**Good luck — and remember: every Git operation creates a recoverable reference. There's almost nothing you can't undo.**