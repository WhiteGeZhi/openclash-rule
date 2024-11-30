#!/bin/bash
OUTPUT_DIR="/root/Personal-project/openclash-special-rule/openclash-rule/auto-special-rule/"
GIT_REPO_DIR="/root/Personal-project/openclash-special-rule/openclash-rule"

cd "$GIT_REPO_DIR" || { log "Failed to change directory to: $GIT_REPO_DIR"; exit 1; }
if git pull; then
  log "Git pull successful"
else
  log "Git pull failed"
  exit 1
fi
