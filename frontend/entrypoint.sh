#!/bin/sh
# 将环境变量替换到 nginx 配置模板中
# 使用 __VAR__ 格式避免与 nginx 自身的 $variable 冲突

PORT="${PORT:-8080}"
BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:8080}"

envsubst '__PORT__ __BACKEND_URL__' \
  < /etc/nginx/nginx.template \
  > /etc/nginx/conf.d/default.conf

echo "Nginx config generated: PORT=$PORT, BACKEND_URL=$BACKEND_URL"
