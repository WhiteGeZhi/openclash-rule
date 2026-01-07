#!/bin/bash

################################
# 配置区
################################
BASE_URL="https://raw.githubusercontent.com/Loyalsoldier/clash-rules/release/"
OUTPUT_DIR="/data/personal_project/openclash-rule/auto-update-rule/"
LOG_FILE="/var/log/my_script.log"
GIT_REPO_DIR="/data/personal_project/openclash-rule/"

MAX_RETRIES=3        # 单个规则最大重试次数
RETRY_INTERVAL=10    # 每次重试间隔（秒）

################################
# 初始化日志
################################
> "$LOG_FILE"

log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

################################
# 环境检查
################################
mkdir -p "$OUTPUT_DIR" || {
  log "【严重】创建输出目录失败：$OUTPUT_DIR"
  exit 1
}

################################
# 下载函数（带重试机制）
################################
download_and_save() {
  local rule_name="$1"
  local full_url="${BASE_URL}${rule_name}.txt"
  local target_path="${OUTPUT_DIR}${rule_name}.txt"
  local attempt=1

  while [ $attempt -le $MAX_RETRIES ]; do
    log "开始下载规则 ${rule_name}.txt（第 ${attempt}/${MAX_RETRIES} 次）"

    if wget --no-check-certificate -nv -O "$target_path" "$full_url"; then
      log "规则 ${rule_name}.txt 下载成功"
      return 0
    else
      log "【告警】规则 ${rule_name}.txt 下载失败（第 ${attempt} 次）"
      attempt=$((attempt + 1))

      if [ $attempt -le $MAX_RETRIES ]; then
        log "将在 ${RETRY_INTERVAL} 秒后重试下载 ${rule_name}.txt"
        sleep "$RETRY_INTERVAL"
      fi
    fi
  done

  log "【严重告警】规则 ${rule_name}.txt 已超过最大重试次数（${MAX_RETRIES} 次），放弃下载"
  return 1
}

################################
# Git 拉取最新代码
################################
cd "$GIT_REPO_DIR" || {
  log "【严重】无法切换到 Git 目录：$GIT_REPO_DIR"
  exit 1
}

if git pull; then
  log "Git 仓库拉取最新代码成功"
else
  log "【严重】Git 仓库拉取失败"
  exit 1
fi

################################
# 规则列表
################################
rules=(
  "direct"
  "proxy"
  "reject"
  "private"
  "apple"
  "icloud"
  "google"
  "gfw"
  "tld-not-cn"
  "telegramcidr"
  "lancidr"
  "cncidr"
  "applications"
)

################################
# 下载规则
################################
failed_downloads=()

for rule in "${rules[@]}"; do
  if ! download_and_save "$rule" &> /dev/null; then
    failed_downloads+=("$rule")
  fi
  sleep 5
done

################################
# 失败处理 & Git 提交
################################
if [ ${#failed_downloads[@]} -gt 0 ]; then
  log "【最终告警】以下规则下载失败：${failed_downloads[*]}"
else
  log "所有规则均已成功下载，准备提交至 Git"

  if git add .; then
    log "Git 变更已暂存"
  else
    log "【严重】Git 暂存失败"
    exit 1
  fi

  commit_message="规则自动更新：$(date '+%Y-%m-%d %H:%M:%S')"
  if git commit -m "$commit_message"; then
    log "Git 提交成功：$commit_message"
  else
    log "未检测到规则变更或 Git 提交失败"
    exit 1
  fi

  if git push; then
    log "Git 推送远程仓库成功"
  else
    log "【严重】Git 推送失败"
    exit 1
  fi
fi

################################
# 结束
################################
log "脚本执行完成"
