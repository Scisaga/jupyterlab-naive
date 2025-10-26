#!/bin/bash
set -e

# ---------------- Docker 安装（使用阿里云镜像） ----------------
echo "[INFO] Installing Docker..."
. /etc/os-release && echo "$VERSION_CODENAME"
# 替换为官方源（amd64；若是 arm64 把 amd64 改为 arm64）
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $VERSION_CODENAME stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list

sudo apt-get update

sudo apt-get install -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras

sudo systemctl enable --now docker

# ---------------- NVIDIA 驱动（可选指定版本） ----------------
echo "[INFO] Installing NVIDIA Driver..."
add-apt-repository -y ppa:graphics-drivers/ppa
apt update
apt install -y nvidia-driver-580
modprobe nvidia || true
nvidia-smi

# ---------------- NVIDIA Container Toolkit 安装 ----------------
echo "[INFO] Installing NVIDIA Container Toolkit..."
# 自动获取系统版本并适配
distribution=$(. /etc/os-release; echo ${ID}${VERSION_ID})
if [[ "$distribution" == "ubuntu24.04" ]]; then
    echo "[WARN] Ubuntu 24.04 暂未正式支持，回退使用 ubuntu22.04 的镜像源"
    distribution="ubuntu22.04"
fi

# 安装 GPG key
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | \
  gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg


# 写入源列表
curl -s -L https://nvidia.github.io/libnvidia-container/stable/${distribution}/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

apt update
apt install -y nvidia-container-toolkit

# 配置 Docker 使用 NVIDIA runtime
nvidia-ctk runtime configure --runtime=docker
systemctl restart docker

# ---------------- Python 工具安装（nvitop） ----------------
echo "[INFO] Installing nvitop..."
apt install nvtop

# ---------------- 验证 NVIDIA Docker 正常工作 ----------------
echo "[INFO] Running test container..."
docker run --rm --runtime=nvidia --gpus all nvidia/cuda:12.1.0-cudnn8-runtime-ubuntu22.04 nvidia-smi
