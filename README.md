# 📝 Git & GitHub Cheatsheet

## 🔧 Setup

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
git config --list
```

## 📂 Starting a Project

```bash
git init                  # start a new repo
git clone <url>           # clone a repo
```

## 💾 Saving Changes

```bash
git status                # show status
git add file.txt          # stage one file
git add .                 # stage all files
git commit -m "message"   # commit changes
git commit -am "msg"      # add + commit tracked files
```

## 📜 Viewing History

```bash
git log                   # full history
git log --oneline --graph # compact view
git diff                  # unstaged changes
git diff --staged         # staged changes
```

## 🔄 Branching

```bash
git branch                # list branches
git branch new-feature    # create branch
git checkout new-feature  # switch branch
git checkout -b hotfix    # create + switch
git merge main            # merge into current branch
git branch -d branch-name # delete branch
```

## Branch Management / Inspection

```bash
git branch                        # List local branches
git branch -r                     # List remote branches
git branch -a                     # List all branches (local + remote)
git branch <branch-name>          # Create a new branch
git branch -d <branch-name>       # Delete a branch
git checkout <branch-name>        # switch branch
git checkout -b <new-branch-name  # crate new branch
```

## ☁️ Remote Repos

```bash
git remote -v                   # list remotes
git remote add origin <url>
git remote set-url origin <url> # change the remote origin
git pull -u origin main
git push -u origin main         # push first time
git push                        # push changes
git pull                        # pull latest changes
git fetch                       # fetch without merge
```

## 🔄 Using multipole computers

```shell
git clone https://github.com/supercoolfire/compounding1 # Computer B first time
cd compounding1
git add . # Computer A
git commit -m "Your message here"
git push
git pull # Computer B
git add .
git commit -m "Your message"
git push
git pull # Computer A
# History repeats itself
```

## 🛠 Undo & Fix

```bash
git restore file.txt      # undo unstaged changes
git checkout -- file.txt  # (older Git) undo unstaged changes
git reset HEAD file.txt   # unstage file
git reset --soft HEAD~1   # undo commit, keep changes staged
git reset --hard HEAD~1   # undo commit, discard changes
git reflog                # show all HEAD moves (recover lost commits)
```

## pull only `workflow.md` without overwriting your new files

```bash
git init # Initialize Git in fresh Laravel
git remote add origin https://github.com/<your-username>/<your-repo>.git # Reconnect to your GitHub repo
git fetch origin main # Make sure Git knows the default branch (usually main)
git sparse-checkout init --cone # Enable sparse-checkout
git sparse-checkout set workflow.md # Tell Git to only fetch workflow.md
git checkout main # Pull it
```

## 📦 Stash

```bash
git stash push -m "msg"   # stash all
git stash push file.txt   # stash single file
git stash list            # list stashes
git stash apply stash@{0} # apply
git stash pop             # apply + drop
```

## 🧹 Cleanup

```bash
git clean -fd             # remove untracked files/folders
```

***

# 🛡️ Recovery (Accidental Loss)

### 🔹 Lost Commits (but `.git` still exists)

```bash
git 
git reflog                # show HEAD history (commits, checkouts, resets)
git log --all
git checkout <commit>     # return to a commit
git branch recovered <commit>  # save it on a branch
```

## 🔹 Recover Deleted Branch (and preserve working directory)

1. Make a backup of current working directory

```bash
cp -r my-project my-project-backup
```

1. Reinitialize Git

```bash
cd my-project
git init                          # must recreate .git  
git remote add origin <url>       # reattach to remote  
git pull origin main 
git fetch origin                  # fetch history from GitHub
```

1. Inspect commits

```bash
git log --all                     # find last commit of deleted branch
```

1. Restore branch

```bash
git checkout -b new-branch-name <SHA>  
git switch -                      # undo the git checkout -b branch-name <SHA> 
git branch -D new-branch-name     # Planing to use different SHA
git branch -a                     # verify deletion
```

1. Reapply local changes (if any) from backup

```bash
cp -r ../my-project-backup/* .    # carefully copy files back  
git add .  
git commit -m "Recovered lost work"
```

## 🔹 Best Practice for Safety

Before doing:

```bash
git checkout -b branch-name <commit>
```

Always:

```bash
git stash push -m "backup before checkout"   # stash changes  
# or manually copy files to ../backup
```

Then, after switching branch:

```bash
git stash pop
```

<hr/>

## 🛠️ Patching leaks (commit must never happened)

## 🛠️ Fixing Leaked / Bad Commits (Flow Guide)

### 1. Identify your situation

- **A. Last commit only (not pushed)** → GOTO 2
- **B. Specific commit (not latest)** → GOTO 3
- **C. Sensitive file across history** → GOTO 4
- **D. Last commit was pushed with `.env`, preserve working directory** → GOTO 5

***

```text
:2 Remove last commit
  git reset --hard HEAD~1
  GOTO 7

:3 Remove specific commit
  git rebase -i <commit-before-bad>
  REM Change pick -> drop
  GOTO 7

:4 Remove sensitive file everywhere
  git filter-repo --path .env --invert-paths
  GOTO 7

:5 Last pushed commit has .env, preserve working directory
  git stash push -u -m "backup before fixing leaked .env"
  git reset --soft HEAD~1
  git rm --cached .env
  echo ".env" >> .gitignore
  git add .gitignore
  git commit -m "Redo commit without .env"
  git push origin main --force-with-lease
  git stash pop
  GOTO END

:6 Recovery, only if something went wrong
  git reflog
  REM Find the commit before you started editing history
  git reset --hard <commit_hash>
  git push origin main --force-with-lease
  GOTO END

:7 Push rewritten history
  git push origin main --force-with-lease
  GOTO END

:8 Reset broken working state, optional
  git reset --hard
  GOTO END

:END
```

⚠️ Rotate the leaked secret too. Removing it from Git history does not make the old value safe again.

***

## 🧠 Key Idea (for future me)

- Steps **2–4 = action**
- Step **5 = protect current work, then fix the pushed leak**
- Step **6 = panic button**
- Step **7 = finalize**

<hr/>

### 🔹 Find Dangling Commits

```bash
git fsck --lost-found     # show unreachable commits
```

### 🔹 If `.git` Folder is Deleted

- **Reflog will NOT work** (it’s stored in `.git`).
- Options:
  1. **Clone again** from GitHub/remote:
     ```bash
     git clone <url>
     ```
  2. If not pushed, try file recovery to restore the `.git` directory.
  3. If any `.git` survived and `git log --all` still works, you can at least view commit history.

⚠️ **Lesson:** Always push important work, and never delete `.git`.

***

# 🛠️ Safe Experiment Workflow

To avoid losing work during risky operations (reset, rebase, history rewrite):

### 1. Clone a Fresh Copy for Testing

```bash
git clone <url> sandbox-repo  # creates a new folder sandbox-repo
cd sandbox-repo
```

```bash
git clone <url> # clone directly into the current directory (without creating a subfolder),
```

### 2. Branch Before Risky Work

```bash
git checkout -b backup-before-rebase
```

### 3. Use Tags as Anchors

```bash
git tag safety-2025-09-01
```

You can always `git checkout safety-2025-09-01` later.

### 4. Push Early, Push Often

```bash
git push origin main
git push origin backup-before-rebase
```

### 5. Backup `.git` Folder Manually

```bash
cp -r .git ../git-backup/
```

If `.git` is lost, copy it back.

# Errors

> \[!WARNING] fatal: detected dubious ownership in repository
> When you copy a `.git` folder from another place, Git checks whether the directory’s ownership matches the current user.
>
> - `git config --global --add safe.directory $(pwd)`\
>   or specify the absolute path:
> - `git config --global --add safe.directory /path/to/your/project`\
>   This tells Git:
> - "Yes, I trust this repository even if ownership looks unusual."
