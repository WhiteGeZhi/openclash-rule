#!/bin/bash

# 配置区
BASE_URL="https://cdn.jsdelivr.net/gh/Loyalsoldier/clash-rules@release/"
OUTPUT_DIR="/root/Personal-project/openclash-rule/auto-update-rule/"
LOG_FILE="/var/log/my_script.log"

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
fi

# 清理和结束
log "Script execution completed."
