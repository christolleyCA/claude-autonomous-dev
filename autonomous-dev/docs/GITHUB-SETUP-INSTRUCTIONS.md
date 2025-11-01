# GitHub Setup Instructions

Your autonomous development system is now Git-enabled! Follow these steps to connect it to GitHub.

## Step 1: Create GitHub Repository

1. Go to: https://github.com/new

2. Fill in repository details:
   - **Repository name**: `claude-autonomous-dev` (or your preferred name)
   - **Description**: "Autonomous development system with Claude Code"
   - **Visibility**: ✅ Private (recommended - contains your scripts)
   - **Initialize**: ❌ Do NOT check "Add a README file"
   - **Initialize**: ❌ Do NOT check "Add .gitignore"
   - **Initialize**: ❌ Do NOT check "Choose a license"

3. Click **"Create repository"**

## Step 2: Connect Local Repository to GitHub

After creating the repository, GitHub will show you commands. Run these in your terminal:

```bash
# Add GitHub as remote origin
git remote add origin https://github.com/YOUR_USERNAME/claude-autonomous-dev.git

# Rename branch to main (if needed)
git branch -M main

# Push your code to GitHub
git push -u origin main
```

**Replace `YOUR_USERNAME`** with your actual GitHub username!

### Example:
```bash
git remote add origin https://github.com/johndoe/claude-autonomous-dev.git
git branch -M main
git push -u origin main
```

## Step 3: Verify Everything Worked

```bash
# Check remote configuration
git remote -v

# Should show:
# origin  https://github.com/YOUR_USERNAME/claude-autonomous-dev.git (fetch)
# origin  https://github.com/YOUR_USERNAME/claude-autonomous-dev.git (push)
```

## Step 4: Configure Git (If Not Already Done)

Set your Git identity (shows who made commits):

```bash
# Set your name
git config --global user.name "Your Name"

# Set your email
git config --global user.email "your.email@example.com"
```

## Step 5: Test the Integration

Build a test feature to verify Git integration works:

```bash
export ANTHROPIC_API_KEY="your-key-here"

./build-feature.sh test-git "Test Git integration"
```

After it completes, check GitHub - you should see a new commit!

## What Happens Automatically

From now on, every time you run `build-feature.sh`:

1. ✅ Feature is built
2. ✅ Feature is tested
3. ✅ Feature is committed to Git
4. ✅ Commit is pushed to GitHub
5. ✅ Everything is backed up in the cloud!

## Optional: Using SSH Instead of HTTPS

For easier authentication (no password every time):

1. Generate SSH key:
```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

2. Add key to GitHub:
   - Go to: https://github.com/settings/keys
   - Click "New SSH key"
   - Paste contents of: `cat ~/.ssh/id_ed25519.pub`

3. Change remote to SSH:
```bash
git remote set-url origin git@github.com:YOUR_USERNAME/claude-autonomous-dev.git
```

Now pushes won't ask for password!

## Troubleshooting

### "fatal: remote origin already exists"
```bash
# Remove existing remote and add again
git remote remove origin
git remote add origin https://github.com/YOUR_USERNAME/claude-autonomous-dev.git
```

### "rejected (fetch first)"
```bash
# Pull first, then push
git pull origin main --rebase
git push origin main
```

### "Permission denied (publickey)"
If using SSH and getting this error:
- Make sure you added your SSH key to GitHub
- Or switch to HTTPS: `git remote set-url origin https://github.com/YOUR_USERNAME/claude-autonomous-dev.git`

## What's in Your Repository

After pushing, your GitHub repository will contain:

```
claude-autonomous-dev/
├── .gitignore                          # What files to ignore
├── git-helpers.sh                      # Git utility functions
├── build-feature.sh                    # Autonomous feature builder
├── fix-feature.sh                      # Feature fixer
├── smart-fix.sh                        # Smart troubleshooter
├── list-features.sh                    # Feature registry
├── sentry-integration-template.ts       # Monitoring template
├── [All other scripts...]
└── [All documentation...]
```

## Your Workflow Now

```
1. You (from Slack): "/cc build-feature payment-processor"

2. Claude Code:
   ├─ Builds feature
   ├─ Tests it
   ├─ Commits to Git
   ├─ Pushes to GitHub ✅
   └─ Notifies you in Slack

3. GitHub:
   ├─ Shows commit history
   ├─ Backs up all code
   └─ Allows viewing changes
```

## Benefits

✅ **Automatic Backups**: Every feature is saved to GitHub
✅ **Full History**: See all changes over time
✅ **Easy Rollback**: Undo changes if needed
✅ **Collaboration Ready**: Share with team when needed
✅ **Professional**: Git is industry standard

## Next Steps

After setup:
1. ✅ Verify GitHub remote is configured
2. ✅ Test with a feature build
3. ✅ View your commits on GitHub
4. ✅ Enjoy automatic backups!

Your autonomous development system is now Git-enabled! 🎉
