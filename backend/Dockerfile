FROM eclipse-temurin:11-jre-jammy

WORKDIR /app

# 复制 JAR 包
COPY fuint-application-1.0.0.jar app.jar

# 复制生产配置
COPY application.properties /app/configure/prod/application.properties

# 创建上传目录
RUN mkdir -p /app/upload /app/logs

# 暴露端口（Railway 会自动读取 PORT 环境变量，Spring Boot 通过 SERVER_PORT 接收）
EXPOSE 8080

# 启动命令
ENTRYPOINT ["java", \
  "-Xms256m", "-Xmx512m", \
  "-Djava.security.egd=file:/dev/./urandom", \
  "-jar", "app.jar", \
  "--env.properties.path=/app/configure/prod/", \
  "--env.profile=prod"]
