# CodeCommit-to-Github-Migration
A Bash script to automate the migration of repositories from **AWS CodeCommit** to a **GitHub organization**.

This tool mirror-clones repositories using SSH from CodeCommit, creates private repos in GitHub via API if they don't exist, and pushes all branches, tags, and history to GitHub.

---

## 🚀 Features

- Interactive prompts before cloning or pushing
- Uses SSH to clone from CodeCommit (no password prompts)
- Automatically creates private GitHub repositories
- Pushes all branches, tags, and commit history using `--mirror`
- Cleans up after each repo
- Supports multiple repo migrations at once

---

## 🔧 Requirements

- `awscli`
- `git`
- `curl`
- `jq`

---

## 🔐 Authentication

- **AWS CLI**: Authenticated via `aws configure`
- **GitHub**: Requires a [Personal Access Token (PAT)](https://github.com/settings/tokens) with:
  - `repo` scope
  - `admin:org` scope (to create repos in your GitHub organization)

---

## ⚙️ Setup & Usage
  

   ```bash
# 1. Clone this repository
   git clone https://github.com/your-org/codecommit-to-github-migrator.git
   cd codecommit-to-github-migrator

# 2. Open the script and update the following variables:

AWS_REGION="us-east-1"
GITHUB_USERNAME="your-github-username"
GITHUB_ORG="your-org-name"
GITHUB_PAT="ghp_your_token_here"

# 3. Make the script executable:
chmod +x migrate-codecommit-to-github.sh

# 4. Run the script:
./migrate-codecommit-to-github.sh

