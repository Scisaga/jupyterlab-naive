#!/bin/bash
set -e

# Docker Hub 命名空间（替换为你自己的用户名）
DOCKER_NAMESPACE=scisaga
CONFIG_DIR=config
GENERATED_DIR=generated

# 登录 Docker（可手动提前登录：docker login）
echo "🔐 确保你已登录 Docker Hub，否则请运行：docker login"

# 遍历所有 YAML 配置
for config in $CONFIG_DIR/*.yaml; do
  name=$(basename "$config" .yaml)
  image_tag="$DOCKER_NAMESPACE/jupyterlab:$name"

  echo "📦 渲染构建配置: $config"
  python build.py "$config"

  echo "🔨 构建镜像: $image_tag"
  docker buildx build \
    -f "$GENERATED_DIR/$name/Dockerfile" \
    -t "$image_tag" \
    "$GENERATED_DIR/$name" \
    --push

  echo "✅ 已推送镜像: $image_tag"
done