# Git Workflow for Gautama

This guide explains how to work with branches, particularly the `claude/research-*` branches created during development sessions, and how to merge them into `main`.

## 📋 Table of Contents

- [Understanding the Branch Structure](#understanding-the-branch-structure)
- [Working with Research Branches](#working-with-research-branches)
- [Merging to Main Branch](#merging-to-main-branch)
- [Common Workflows](#common-workflows)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## 🌳 Understanding the Branch Structure

### Branch Naming Convention

**Main Branches:**
- `main` - Production-ready, stable configuration
- `develop` - Integration branch for features (optional)

**Feature Branches:**
- `feature/service-name` - New service additions
- `feature/description` - New features
- `fix/issue-description` - Bug fixes
- `docs/description` - Documentation updates

**Claude Research Branches:**
- `claude/research-g-*` - Branches created during Claude Code sessions
- Format: `claude/research-g-<session-id>`
- These contain improvements, features, or experiments

## 🔄 Working with Research Branches

### Step 1: View Available Branches

First, see what branches exist on the remote:

```bash
# List all remote branches
git branch -r

# List Claude research branches specifically
git branch -r | grep claude/research
```

**Example output:**
```
origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
origin/claude/research-g-abc123def456
```

### Step 2: Fetch the Latest Changes

Ensure you have the latest information from the remote:

```bash
# Fetch all branches from remote
git fetch origin

# Or fetch a specific branch
git fetch origin claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
```

### Step 3: Copy Branch Locally

There are several ways to work with the research branch:

#### Option A: Checkout the Branch Directly

```bash
# Checkout the remote branch (creates local tracking branch)
git checkout claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# This creates a local branch that tracks the remote
# Equivalent to:
# git checkout -b claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
```

#### Option B: Create a Local Copy with Different Name

```bash
# Create a local branch from the remote branch
git checkout -b my-local-branch origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# Or if you want to review it first:
git checkout -b review-changes origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
```

#### Option C: Fetch and Inspect Without Checking Out

```bash
# View the branch without checking it out
git fetch origin claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# See what's different from your current branch
git log main..origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# See the actual changes
git diff main...origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
```

### Step 4: Review the Changes

Before merging, always review what changed:

```bash
# View commit history
git log --oneline main..claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# View detailed commits
git log --stat main..claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# View file changes
git diff main...claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# View specific file changes
git diff main...claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX -- README.md
```

### Step 5: Test the Changes

**Important: Always test before merging to main!**

```bash
# Checkout the research branch
git checkout claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# Test the configuration builds
sudo nixos-rebuild build --flake .#vulcan

# Test in a VM (recommended)
nixos-rebuild build-vm --flake .#vulcan
./result/bin/run-vulcan-vm

# Check for any issues
nix flake check
```

## 🔀 Merging to Main Branch

### Preparation

Before merging, ensure:
- [ ] You've reviewed all changes
- [ ] You've tested the configuration
- [ ] The build succeeds
- [ ] No secrets were accidentally committed
- [ ] All tests pass

### Method 1: Direct Merge (Fast-Forward if Possible)

This is the cleanest approach when main hasn't diverged:

```bash
# Switch to main branch
git checkout main

# Ensure main is up to date
git pull origin main

# Merge the research branch
git merge claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# If there are no conflicts, this will succeed
# Push to remote
git push origin main
```

### Method 2: Merge with Commit Message

If you want to preserve a merge commit:

```bash
# Switch to main
git checkout main
git pull origin main

# Merge with a merge commit (no fast-forward)
git merge --no-ff claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX -m "Merge research branch: comprehensive documentation improvements

Includes:
- QUICKSTART, TROUBLESHOOTING, and FAQ guides
- Helper scripts for health checks
- GitHub Actions and issue templates
- Network topology diagram
- Contributing guide
- README improvements"

# Push to remote
git push origin main
```

### Method 3: Squash Merge (Clean History)

If the research branch has many small commits and you want a clean history:

```bash
# Switch to main
git checkout main
git pull origin main

# Squash merge (combines all commits into one)
git merge --squash claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# This stages all changes but doesn't commit
# Now commit with a meaningful message
git commit -m "feat: Add comprehensive documentation and tooling

- Add QUICKSTART, TROUBLESHOOTING, and FAQ guides
- Create health-check and service-status scripts
- Add GitHub Actions CI/CD workflow
- Create issue and PR templates
- Add network topology D2 diagram
- Add Contributing guide
- Enhance README with badges and new sections"

# Push to remote
git push origin main
```

### Method 4: Rebase (Advanced)

If you want to replay the commits on top of main:

```bash
# Switch to the research branch
git checkout claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# Rebase onto main
git rebase main

# If conflicts occur, resolve them and continue:
# git add <resolved-files>
# git rebase --continue

# Switch to main and fast-forward merge
git checkout main
git merge claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# Push to remote
git push origin main
```

### Handling Merge Conflicts

If you encounter conflicts during merge:

```bash
# Merge will pause and show conflicts
git merge claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# View conflicting files
git status

# Edit files to resolve conflicts
# Look for conflict markers:
# <<<<<<< HEAD
# (your changes)
# =======
# (incoming changes)
# >>>>>>> claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# After resolving, stage the files
git add <resolved-files>

# Complete the merge
git commit

# Push to remote
git push origin main
```

## 🔄 Common Workflows

### Workflow A: Simple Review and Merge

**Use case**: You trust the changes and want to merge quickly

```bash
# 1. Fetch latest
git fetch origin

# 2. Checkout research branch
git checkout claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# 3. Quick test
sudo nixos-rebuild build --flake .#vulcan

# 4. Switch to main and merge
git checkout main
git pull origin main
git merge claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# 5. Push
git push origin main
```

### Workflow B: Careful Review and Squash Merge

**Use case**: You want to review thoroughly and have a clean commit

```bash
# 1. Fetch latest
git fetch origin

# 2. Create review branch
git checkout -b review-research origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# 3. Review changes
git log main..review-research
git diff main...review-research

# 4. Test thoroughly
sudo nixos-rebuild build --flake .#vulcan
nixos-rebuild build-vm --flake .#vulcan
# Test in VM...

# 5. Squash merge to main
git checkout main
git pull origin main
git merge --squash review-research

# 6. Commit with detailed message
git commit -m "feat: comprehensive documentation improvements

<detailed description>"

# 7. Push
git push origin main

# 8. Clean up review branch
git branch -d review-research
```

### Workflow C: Cherry-Pick Specific Commits

**Use case**: You only want specific changes from the research branch

```bash
# 1. View commits in research branch
git log main..claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# 2. Note the commit hashes you want
# Example: a9624c7, 131ceb1, 4c7cfc4

# 3. Switch to main
git checkout main
git pull origin main

# 4. Cherry-pick specific commits
git cherry-pick a9624c7
git cherry-pick 131ceb1
git cherry-pick 4c7cfc4

# 5. Push
git push origin main
```

## 📝 Best Practices

### Before Merging

1. **Always review changes**:
   ```bash
   git diff main...claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
   ```

2. **Test the build**:
   ```bash
   sudo nixos-rebuild build --flake .#vulcan
   ```

3. **Check for secrets**:
   ```bash
   git diff main...claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX | grep -i "password\|secret\|key"
   ```

4. **Verify formatting**:
   ```bash
   nix fmt
   git diff  # Should show no changes if already formatted
   ```

### After Merging

1. **Verify main still builds**:
   ```bash
   git checkout main
   sudo nixos-rebuild build --flake .#vulcan
   ```

2. **Tag important merges**:
   ```bash
   git tag -a v1.1.0 -m "Release 1.1.0: Documentation improvements"
   git push origin v1.1.0
   ```

3. **Clean up merged branches** (optional):
   ```bash
   # Delete local branch
   git branch -d claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

   # Delete remote branch (only if you're sure!)
   git push origin --delete claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
   ```

4. **Update documentation** if needed

### Commit Message Guidelines

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**: feat, fix, docs, style, refactor, perf, test, chore

**Example**:
```
feat(docs): add comprehensive documentation suite

- Add QUICKSTART guide with installation steps
- Add TROUBLESHOOTING guide with common issues
- Add FAQ with 50+ questions
- Create helper scripts for health checks
- Add GitHub Actions CI/CD workflow

Closes #123
```

## 🔍 Troubleshooting

### Problem: "Already up to date" but you see changes

**Solution**: Fetch the latest changes first:
```bash
git fetch origin
git merge origin/claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
```

### Problem: Merge conflicts

**Solution**: See [Handling Merge Conflicts](#handling-merge-conflicts) section above.

To abort a merge in progress:
```bash
git merge --abort
```

### Problem: Accidentally merged to wrong branch

**Solution**: Reset to before the merge:
```bash
# Find the commit before merge
git log --oneline

# Reset to that commit (replace abc123 with actual hash)
git reset --hard abc123

# If already pushed, you'll need to force push (dangerous!)
git push origin main --force
```

### Problem: Want to undo a merge after pushing

**Solution**: Use revert instead of reset (safer):
```bash
# Revert the merge commit
git revert -m 1 HEAD

# Push the revert
git push origin main
```

### Problem: Branch has diverged from main

**Solution**: Rebase or merge main into branch first:
```bash
git checkout claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
git pull origin claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
git merge main
# Or: git rebase main

# Resolve any conflicts, then merge to main
```

## 🎯 Quick Reference

### Essential Commands

```bash
# Fetch all branches
git fetch origin

# List all branches
git branch -a

# Checkout remote branch locally
git checkout claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# View differences
git diff main...claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# Merge to main
git checkout main
git merge claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# Push changes
git push origin main

# Delete local branch
git branch -d claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX

# Delete remote branch
git push origin --delete claude/research-g-011CV3njMd5LSnPCQ3Ha1pGX
```

## 📚 Additional Resources

- [Git Documentation](https://git-scm.com/doc)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Git Branching Model](https://nvie.com/posts/a-successful-git-branching-model/)
- [Resolving Merge Conflicts](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/addressing-merge-conflicts)

---

**Pro Tip**: Always create a backup branch before doing risky operations:
```bash
git checkout main
git branch backup-$(date +%Y%m%d)
# Now you can safely experiment
```
