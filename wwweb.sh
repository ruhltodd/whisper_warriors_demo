#!/bin/bash

# Prompt for commit message
echo "Enter commit message:"
read commit_message

# Check if commit message is empty
if [ -z "$commit_message" ]; then
    echo "Error: Commit message cannot be empty"
    exit 1
fi

# Execute build and deploy commands
echo "🧹 Cleaning..."
flutter clean

echo "🏗️ Building web..."
flutter build web --release

echo "📁 Updating docs folder..."
rm -rf docs
mv build/web docs

echo "🚀 Committing and pushing..."
git add .
git commit -m "$commit_message"
git push origin main

echo "✅ Done! Deployed to GitHub Pages"
