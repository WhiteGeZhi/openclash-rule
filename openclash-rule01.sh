#!/bin/bash

# 配置区
BASE_URL="https://raw.githubusercontent.com/Loyalsoldier/clash-rules/release/"
OUTPUT_DIR="/data/personal_project/openclash-rule/auto-update-rule/"
LOG_FILE="/var/log/my_script.log"
GIT_REPO_DIR="/data/personal_project/openclash-rule/"

# 初始化日志
> "$LOG_FILE"

# 日志记录函数
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 确保输出目录存在
mkdir -p "$OUTPUT_DIR" || { log "Failed to create output directory: $OUTPUT_DIR"; exit 1; }

# 文件下载函数，带有基本的错误处理
download_and_save() {
  local rule_name="$1"
  local full_url="${BASE_URL}${rule_name}.txt"
  local target_path="${OUTPUT_DIR}${rule_name}.txt"

  log "Attempting to download: ${full_url}"

  if wget --no-check-certificate -nv -O "$target_path" "$full_url"; then
    log "Downloaded ${rule_name}.txt successfully"
  else
    log "Failed to download ${rule_name}.txt"
    return 1 # 返回非零值表示失败
  fi
}

# 拉取最新代码
cd "$GIT_REPO_DIR" || { log "Failed to change directory to: $GIT_REPO_DIR"; exit 1; }
if git pull; then
  log "Git pull successful"
else
  log "Git pull failed"
  exit 1
fi

# 规则数组
rules=("direct" "proxy" "reject" "private" "apple" "icloud" "google" "gfw" "tld-not-cn" "telegramcidr" "lancidr" "cncidr" "applications")

# 并发下载规则
failed_downloads=()
for rule in "${rules[@]}"; do
  if ! download_and_save "$rule" &> /dev/null; then
    failed_downloads+=("$rule")
  fi
  sleep 5
done

# 检查是否有下载失败的规则
if [ ${#failed_downloads[@]} -gt 0 ]; then
  log "The following rules failed to download: ${failed_downloads[*]}"
else
  log "All rules have been successfully downloaded."

  # 添加更改到 Git
  if git add .; then
    log "Staged changes for commit"
  else
    log "Failed to stage changes for commit"
    exit 1
  fi

  # 提交更改
  commit_message="Updated rules on $(date '+%Y-%m-%d %H:%M:%S')"
  if git commit -m "$commit_message"; then
    log "Committed changes to Git with message: $commit_message"
  else
    log "Failed to commit changes to Git"
    exit 1
  fi

  # 推送更改
  if git push; then
    log "Pushed changes to remote repository"
  else
    log "Failed to push changes to remote repository"
    exit 1
  fi
fi

# 清理和结束
log "Script execution completed."

