FROM nginx:1.25-alpine

# 复制前端构建产物
COPY frontend/ /usr/share/nginx/html/fuintAdmin/

# 复制 Nginx 配置
COPY frontend/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
