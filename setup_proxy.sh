#!/bin/bash
set -e

### === 🧩 全局代理配置区域（建议根据环境修改） === ###
PROXY_HOST=127.0.0.1
PROXY_PORT=7890
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
NO_PROXY="localhost,127.0.0.1,::1"

ENV_FILE="/etc/environment"
DOCKER_PROXY_FILE="/etc/systemd/system/docker.service.d/http-proxy.conf"

### === ✅ 启用代理函数 === ###
function enable_proxy() {
  echo "[INFO] 启用 HTTP/HTTPS 代理：$PROXY_URL"

  # shell 环境变量
  export http_proxy=$PROXY_URL
  export https_proxy=$PROXY_URL
  export HTTP_PROXY=$PROXY_URL
  export HTTPS_PROXY=$PROXY_URL
  export NO_PROXY=$NO_PROXY

  # 写入 /etc/environment
  echo "[INFO] 设置系统代理（$ENV_FILE）..."
  sudo tee $ENV_FILE > /dev/null <<EOF
http_proxy="$PROXY_URL"
https_proxy="$PROXY_URL"
HTTP_PROXY="$PROXY_URL"
HTTPS_PROXY="$PROXY_URL"
NO_PROXY="$NO_PROXY"
EOF

  # 设置 Docker 守护进程代理
  echo "[INFO] 配置 Docker 镜像拉取代理 ..."
  sudo mkdir -p $(dirname "$DOCKER_PROXY_FILE")
  sudo tee $DOCKER_PROXY_FILE > /dev/null <<EOF
[Service]
Environment="HTTP_PROXY=$PROXY_URL"
Environment="HTTPS_PROXY=$PROXY_URL"
Environment="NO_PROXY=$NO_PROXY"
EOF

  # 重启 Docker
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl restart docker

  echo "[DONE] ✅ 代理设置完成。"
}

### === ❌ 关闭代理函数 === ###
function disable_proxy() {
  echo "[INFO] 关闭代理配置..."

  # 清除当前 shell 环境变量
  unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY

  # 清除系统环境代理
  sudo sed -i '/_proxy/dI' $ENV_FILE

  # 删除 Docker 代理配置
  sudo rm -f $DOCKER_PROXY_FILE
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl restart docker

  echo "[DONE] 🚫 所有代理已关闭。"
}

### === 🧭 参数控制 === ###
case "$1" in
  on)
    enable_proxy
    ;;
  off)
    disable_proxy
    ;;
  *)
    echo "❗ 用法: $0 [on|off]"
    exit 1
    ;;
esac