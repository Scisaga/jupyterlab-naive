#!/bin/bash
set -e

COMPOSE_FILE=${1:-py310-cuda121.yml}

echo "🚀 使用配置: docker-compose/${COMPOSE_FILE}"
docker compose --env-file .env -f docker-compose/${COMPOSE_FILE} up -d

echo "✅ 已部署，访问: http://localhost:${JUPYTER_PORT}/?token=${JUPYTER_TOKEN}"