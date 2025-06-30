#!/bin/bash

# ---------------------------
# 🔧 CONFIGURATION
# ---------------------------
AWS_REGION=""
GITHUB_USERNAME=""
GITHUB_ORG=""
GITHUB_PAT=""
TMP_DIR="/tmp/codecommit-mirror"

# ---------------------------
# ✅ DEPENDENCY CHECK
# ---------------------------
command -v git >/dev/null || { echo "❌ git is required."; exit 1; }
command -v aws >/dev/null || { echo "❌ aws cli is required."; exit 1; }
command -v curl >/dev/null || { echo "❌ curl is required."; exit 1; }
command -v jq >/dev/null || { echo "❌ jq is required. Install via 'sudo apt install jq' or 'brew install jq'."; exit 1; }

# ---------------------------
# 🧹 CLEANUP
# ---------------------------
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR" || exit 1

# ---------------------------
# 🔁 PROCESS ALL CODECOMMIT REPOS
# ---------------------------
REPOS=$(aws codecommit list-repositories --region "$AWS_REGION" --query 'repositories[*].repositoryName' --output text)

for REPO in $REPOS; do
    echo -e "\n📦 Found repository: $REPO"

    read -rp "❓ Clone CodeCommit repo '$REPO'? (yes/no): " CONFIRM_CLONE
    if [[ "$CONFIRM_CLONE" != "yes" ]]; then
        echo "⏭️ Skipping $REPO"
        continue
    fi

    # Clone from CodeCommit using SSH
    CODECOMMIT_SSH_URL="ssh://git-codecommit.${AWS_REGION}.amazonaws.com/v1/repos/${REPO}""
    echo "🔁 Cloning $REPO from CodeCommit..."
    GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=no" git clone --mirror "$CODECOMMIT_SSH_URL" "$REPO.git"
    if [ $? -ne 0 ]; then
        echo "❌ Failed to clone $REPO. Skipping."
        continue
    fi

    cd "$REPO.git" || continue

    # Check if GitHub repo already exists
    echo "🔎 Checking if GitHub repo '$REPO' exists in org '$GITHUB_ORG'..."
    REPO_EXISTS=$(curl -s -H "Authorization: token ${GITHUB_PAT}" \
      "https://api.github.com/repos/${GITHUB_ORG}/${REPO}" | jq -r '.id')

    if [[ "$REPO_EXISTS" == "null" ]]; then
        echo "🆕 GitHub repo does not exist. Creating..."
        CREATE_RESPONSE=$(curl -s -X POST -H "Authorization: token ${GITHUB_PAT}" \
          -H "Accept: application/vnd.github+json" \
          https://api.github.com/orgs/${GITHUB_ORG}/repos \
          -d "{\"name\":\"${REPO}\", \"private\":true}")

        if [[ $(echo "$CREATE_RESPONSE" | jq -r '.id') == "null" ]]; then
            echo "❌ Failed to create GitHub repo: $(echo "$CREATE_RESPONSE" | jq -r '.message')"
            cd "$TMP_DIR" || exit 1
            rm -rf "$REPO.git"
            continue
        else
            echo "✅ Created GitHub repository: ${GITHUB_ORG}/${REPO}"
        fi
    else
        echo "✅ GitHub repo already exists."
    fi

    # Add GitHub remote
    GITHUB_REPO_URL="https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/${GITHUB_ORG}/${REPO}.git"
    git remote add github "$GITHUB_REPO_URL"

    # Prompt before pushing
    read -rp "🚀 Push '$REPO' to GitHub? (yes/no): " CONFIRM_PUSH
    if [[ "$CONFIRM_PUSH" == "yes" ]]; then
        echo "📤 Pushing $REPO to GitHub..."
        git push --mirror github
        if [ $? -eq 0 ]; then
            echo "✅ Successfully pushed $REPO."
        else
            echo "❌ Push failed for $REPO."
        fi
    else
        echo "⏭️ Skipped pushing $REPO."
    fi

    cd "$TMP_DIR" || exit 1
    rm -rf "$REPO.git"
done

echo -e "\n🏁 Migration complete!"
