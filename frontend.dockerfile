FROM nginx:1.25-alpine

# 安装 gettext（提供 envsubst）
RUN apk add --no-cache gettext

# 复制前端构建产物
COPY frontend/ /usr/share/nginx/html/fuintAdmin/

# 复制 Nginx 配置模板
COPY frontend/nginx.template.conf /etc/nginx/nginx.template

# 复制启动脚本
COPY frontend/start.sh /start.sh
RUN chmod +x /start.sh

# Railway 默认端口
ENV PORT=8080
ENV BACKEND_URL=http://127.0.0.1:8080

EXPOSE 8080

# 先渲染配置，再启动 nginx
CMD ["/start.sh"]
