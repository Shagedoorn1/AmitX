#!/bin/bash

# pushamitx.sh – Pushes AmitX to GitHub
REPO_URL="https://github.com/Shagedoorn1/AmitX.git"
FILE=AmitX/amitx_info.h

if [[ ! -f $FILE ]]; then
    echo "Error: $FILE not found!"
    exit 1
fi

VERSION=$(grep AMITX_VERSION $FILE | sed -E 's/.*"([^"]+)".*/\1/')
OVERSION=$(grep OWLY_VERSION $FILE | sed -E 's/.*"([^"]+)".*/\1/')
COMMIT_MSG=${1:-"Update on: AmitX version $VERSION; Owly version $OVERSION"}

if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "📂 Initializing git repo..."
    git init
fi

CURRENT_URL=$(git remote get-url origin 2>/dev/null)

if [[ "$CURRENT_URL" != "$REPO_URL" ]]; then
    echo "🔗 Setting correct remote URL for AmitX..."
    git remote remove origin 2>/dev/null
    git remote add origin "$REPO_URL"
fi

git add AmitX README.md pushamitx.sh
git commit -m "$COMMIT_MSG"
git pull --rebase origin main
git branch -M main
git push -u origin main

if git rev-parse "$VERSION" >/dev/null 2>&1; then
    if git tag --points-at HEAD | grep -q "$VERSION"; then
        echo "Tag '$VERSION' already exists on this commit."
    else
        echo "Tag '$VERSION' exists but on a different commit. Skipping."
    fi
else
    echo "🏷️ Tagging release version $VERSION"
    git tag -a "$VERSION" -m "Release version $VERSION"
    git push origin "$VERSION"
fi

echo "✅ AmitX push complete."