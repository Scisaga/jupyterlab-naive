#!/bin/bash
set -e

echo "[INFO] 安装 Docker..."
curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
systemctl enable docker
systemctl start docker

echo "[INFO] 安装 Docker Compose（v2.29.7）..."
DOCKER_COMPOSE_VERSION=v2.29.7
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "[INFO] 初始化完成！你现在可以运行 CPU-only 版本的 JupyterLab 镜像了。"