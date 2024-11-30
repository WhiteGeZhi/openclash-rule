#!/bin/bash
OUTPUT_DIR="/root/Personal-project/openclash-special-rule/openclash-rule/auto-special-rule/"
LOG_FILE="/var/log/my_script.log"
GIT_REPO_DIR="/root/Personal-project/openclash-special-rule/openclash-rule"

# 初始化日志
> "$LOG_FILE"

# 日志记录函数
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

cd "$GIT_REPO_DIR" || { log "Failed to change directory to: $GIT_REPO_DIR"; exit 1; }
if git pull; then
  log "Git pull successful"
else
  log "Git pull failed"
  exit 1
fi

rule=(
'https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/YouTube/YouTube.yaml',
'https://cdn.jsdelivr.net/gh/blackmatrix7/ios_rule_script@master/rule/Clash/Google/Google.yaml')


# 遍历数组并下载规则文件
for rule_name in "${rule[@]}"; do
  wget "$rule_name" 2>&1 | tee -a "$LOG_FILE"
  if [ $? -eq 0 ]; then
    log "Successfully downloaded: $rule_name"
  else
    log "Failed to download: $rule_name"
  fi
done