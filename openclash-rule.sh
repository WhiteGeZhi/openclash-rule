#!/bin/bash

# 配置区
BASE_URL="https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/"
OUTPUT_DIR="/root/Personal-project/openclash-rule/auto-update-rule/"
LOG_FILE="/var/log/my_script.log"
GIT_REPO_DIR="/root/Personal-project/openclash-rule/"

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
    return 0
  else
    log "Failed to download ${rule_name}.txt"
    return 1 # 返回非零值表示失败
  fi
}

# 规则数组
rules=("direct" "proxy" "reject" "private" "apple" "icloud" "google" "gfw" "tld-not-cn" "telegramcidr" "lancidr" "cncidr" "applications")

# 并发下载规则
failed_downloads=()
for rule in "${rules[@]}"; do
  if ! download_and_save "$rule" &> /dev/null; then
    failed_downloads+=("$rule")
  fi
done

# 检查是否有下载失败的规则
if [ ${#failed_downloads[@]} -gt 0 ]; then
  log "The following rules failed to download: ${failed_downloads[*]}"
else
  log "All rules have been successfully downloaded."

  # 进入 Git 仓库目录
  cd "$GIT_REPO_DIR" || { log "Failed to change directory to $GIT_REPO_DIR"; exit 1; }

  # 配置 http.postBuffer
  git config http.postBuffer 157286400

  # 分批次添加、提交和推送
  batch1=("auto-update-rule/apple.txt" "auto-update-rule/applications.txt" "auto-update-rule/cncidr.txt" "auto-update-rule/direct.txt" "auto-update-rule/gfw.txt" "auto-update-rule/google.txt")
  batch2=("auto-update-rule/icloud.txt" "auto-update-rule/lancidr.txt" "auto-update-rule/private.txt" "auto-update-rule/proxy.txt" "auto-update-rule/reject.txt" "auto-update-rule/telegramcidr.txt" "auto-update-rule/tld-not-cn.txt")

  # 提交并推送第一批次
  if [ ${#batch1[@]} -gt 0 ]; then
    git add "${batch1[@]}" || { log "Failed to add batch1 changes to Git"; exit 1; }
    commit_message="Updated rules (batch1) on $(date '+%Y-%m-%d %H:%M:%S')"
    if git commit -m "$commit_message"; then
      log "Committed batch1 changes to Git with message: $commit_message"
      if git push; then
        log "Pushed batch1 changes to remote repository"
      else
        log "Failed to push batch1 changes to remote repository"
        exit 1
      fi
    else
      log "Failed to commit batch1 changes to Git"
      exit 1
    fi
  fi

  # 提交并推送第二批次
  if [ ${#batch2[@]} -gt 0 ]; then
    git add "${batch2[@]}" || { log "Failed to add batch2 changes to Git"; exit 1; }
    commit_message="Updated rules (batch2) on $(date '+%Y-%m-%d %H:%M:%S')"
    if git commit -m "$commit_message"; then
      log "Committed batch2 changes to Git with message: $commit_message"
      if git push; then
        log "Pushed batch2 changes to remote repository"
      else
        log "Failed to push batch2 changes to remote repository"
        exit 1
      fi
    else
      log "Failed to commit batch2 changes to Git"
      exit 1
    fi
  fi
fi

# 清理和结束
log "Script execution completed."
