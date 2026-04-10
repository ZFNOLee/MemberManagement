#!/bin/sh
# 渲染 nginx 配置模板，替换环境变量
PORT="${PORT:-8080}"
BACKEND_URL="${BACKEND_URL:-http://127.0.0.1:8080}"

envsubst '__PORT__ __BACKEND_URL__' \
  < /etc/nginx/nginx.template \
  > /etc/nginx/conf.d/default.conf

echo "Nginx config generated: PORT=$PORT, BACKEND_URL=$BACKEND_URL"

# 删除默认的 nginx 配置，避免冲突
rm -f /etc/nginx/conf.d/default.conf.bak

# 启动 nginx
exec nginx -g 'daemon off;'
