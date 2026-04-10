# fuint 会员营销系统 - Railway 部署指南

> 版本：1.0.0 | 日期：2026-04-10 | 平台：Railway (railway.app)

---

## 目录

- [一、架构说明](#一架构说明)
- [二、目录结构](#二目录结构)
- [三、Railway 部署步骤](#三railway-部署步骤)
- [四、数据库初始化](#四数据库初始化)
- [五、前端配置后端地址](#五前端配置后端地址)
- [六、访问验证](#六访问验证)
- [七、常见问题](#七常见问题)
- [八、默认账号](#八默认账号)

---

## 一、架构说明

Railway 上部署的架构由 **4 个 Service** 组成：

```
Railway Project: fuint
├── fuint-mysql     ← MySQL 8.0 数据库（Railway 托管）
├── fuint-redis     ← Redis 缓存（Railway 托管）
├── fuint-backend   ← Spring Boot 后端（Dockerfile 部署）
└── fuint-frontend  ← Nginx 前端（Dockerfile 部署）
```

> Railway 同一 Project 内的服务通过内部网络互联，无需配置 IP。

---

## 二、目录结构

```
fuint-railway/
├── RAILWAY-DEPLOY.md          ← 本文档
├── backend/
│   ├── Dockerfile             ← 后端容器定义（基于 JRE 11）
│   ├── railway.json           ← Railway 服务配置
│   ├── application.properties ← 生产配置（读取 Railway 环境变量）
│   └── fuint-application-1.0.0.jar  ← 后端可执行 JAR
├── frontend/
│   ├── Dockerfile             ← 前端 Nginx 容器定义
│   ├── railway.json           ← Railway 服务配置
│   ├── nginx.conf             ← Nginx 配置（含后端反代）
│   ├── index.html             ← 前端入口
│   └── static/                ← JS/CSS/图片资源
└── database/
    └── fuint-db.sql           ← 数据库完整备份（需手动导入）
```

---

## 三、Railway 部署步骤

### 步骤 1：注册并创建 Railway 项目

1. 访问 [https://railway.app](https://railway.app)，注册账号（支持 GitHub 登录）
2. 控制台点击 **New Project**

### 步骤 2：添加 MySQL 数据库服务

1. 在 Project 画布点击 **+ New** → **Database** → **Add MySQL**
2. 等待 MySQL 服务部署完成
3. 点击 MySQL 服务 → **Variables** 标签，记录以下变量（后续用于数据库连接）：
   - `MYSQLHOST`
   - `MYSQLPORT`
   - `MYSQLUSER`
   - `MYSQLPASSWORD`
   - `MYSQLDATABASE`

### 步骤 3：添加 Redis 服务

1. 在 Project 画布点击 **+ New** → **Database** → **Add Redis**
2. 等待 Redis 服务部署完成
3. 点击 Redis 服务 → **Variables** 标签，记录：
   - `REDISHOST`
   - `REDISPORT`
   - `REDISPASSWORD`

### 步骤 4：部署后端服务

#### 方式一：通过 GitHub（推荐）

1. 将 `backend/` 目录内所有文件推送到一个新的 GitHub 仓库
   ```bash
   cd backend/
   git init
   git add .
   git commit -m "fuint backend for Railway"
   git remote add origin https://github.com/YOUR_USER/fuint-backend.git
   git push -u origin main
   ```
2. Railway 画布点击 **+ New** → **GitHub Repo** → 选择 `fuint-backend`
3. Railway 会自动检测 `Dockerfile` 并构建

#### 方式二：通过 Railway CLI

```bash
# 安装 Railway CLI
npm install -g @railway/cli

# 登录
railway login

# 在 backend/ 目录执行
cd backend/
railway up
```

#### 配置后端环境变量（关键步骤）

部署后，点击后端服务 → **Variables** 标签，点击 **+ New Variable**，添加以下变量：

| 变量名 | 值（从 MySQL/Redis 服务的 Variables 标签复制） |
|--------|----------------------------------------------|
| `MYSQLHOST` | MySQL 服务的 `MYSQLHOST` 值 |
| `MYSQLPORT` | MySQL 服务的 `MYSQLPORT` 值 |
| `MYSQLUSER` | MySQL 服务的 `MYSQLUSER` 值 |
| `MYSQLPASSWORD` | MySQL 服务的 `MYSQLPASSWORD` 值 |
| `MYSQLDATABASE` | `fuint-db` |
| `REDISHOST` | Redis 服务的 `REDISHOST` 值 |
| `REDISPORT` | Redis 服务的 `REDISPORT` 值 |
| `REDISPASSWORD` | Redis 服务的 `REDISPASSWORD` 值 |

> **更简便的方式**：在 Railway 后端服务的 Variables 页面，点击 **Add Reference** 直接引用其他服务的变量，无需手动复制。

添加完变量后，Railway 会自动重新部署后端。

#### 生成后端公网域名

1. 点击后端服务 → **Settings** → **Networking**
2. 点击 **Generate Domain**，得到类似 `fuint-backend.up.railway.app` 的地址
3. **记录这个地址**，前端配置需要用到

### 步骤 5：部署前端服务

#### 修改前端 nginx.conf（重要！）

在上传前端之前，打开 `frontend/nginx.conf`，将 `BACKEND_INTERNAL_URL` 替换为后端服务的**内部地址**：

```nginx
# 将这行
proxy_pass BACKEND_INTERNAL_URL/;

# 修改为（使用后端服务的内部 Railway 地址）
proxy_pass http://fuint-backend.railway.internal:8080/;
```

> **说明**：Railway 内部服务地址格式为 `http://服务名.railway.internal:端口`，服务名在 Railway 控制台的服务设置中可查看。

修改后，将 `frontend/` 目录内所有文件推送到 GitHub 并在 Railway 部署（同后端步骤）。

---

## 四、数据库初始化

### 方法一：通过 Railway MySQL 连接器（推荐）

1. 在 Railway 控制台点击 MySQL 服务
2. 点击 **Connect** 标签，找到 **Public URL** 或开启 **TCP Proxy**
3. 使用本地 MySQL 客户端连接（Navicat / TablePlus / DBeaver）：
   - Host：Railway 提供的公网地址
   - Port：Railway 提供的端口（约 30000+）
   - User / Password：来自 Variables

4. 连接成功后，新建数据库 `fuint-db`，然后导入 `database/fuint-db.sql`

### 方法二：通过 MySQL CLI

```bash
# 使用 Railway 提供的 TCP Proxy 公网地址
mysql -h RAILWAY_MYSQL_PUBLIC_HOST -P RAILWAY_MYSQL_PORT \
      -u MYSQLUSER -pMYSQLPASSWORD

# 进入后执行
CREATE DATABASE `fuint-db` DEFAULT CHARACTER SET utf8mb4;
USE `fuint-db`;
SOURCE /path/to/fuint-db.sql;
```

> **注意**：数据库初始化只需执行一次。初始化完成后可关闭 MySQL TCP Proxy 以节省网络费用。

---

## 五、前端配置后端地址

前端 `nginx.conf` 中已通过 `proxy_pass` 将 `/fuint-application/` 路径代理到后端。

如果你希望通过 **后端公网域名** 直连（而不是 Nginx 代理），可将前端中的请求地址改为后端公网 URL，但这需要后端开启 CORS。

**当前推荐方案**：前端 Nginx 代理（同域通信，无需处理 CORS）。

---

## 六、访问验证

### 6.1 验证后端健康

访问后端公网地址：

```
https://fuint-backend.up.railway.app/backendApi/captcha/getCode
```

返回 JSON（`code: 200`）即后端正常。

### 6.2 访问管理后台

```
https://fuint-frontend.up.railway.app/fuintAdmin/
```

### 6.3 登录

| 项目 | 值 |
|------|------|
| 用户名 | `fuint` |
| 密码 | `fuint2023` |

> ⚠️ **首次登录后请立即修改密码！**

---

## 七、常见问题

### Q1: 后端日志提示 "Communications link failure"（数据库连接失败）

- 检查是否已在后端服务 Variables 中添加所有 MySQL 环境变量
- 检查 `MYSQLDATABASE` 值是否为 `fuint-db`（注意是连字符，不是下划线）
- 检查数据库是否已初始化（见步骤四）

### Q2: 后端日志提示 Redis 连接失败

- 检查 `REDISHOST`, `REDISPORT`, `REDISPASSWORD` 变量是否正确
- Railway Redis 默认有密码，`REDISPASSWORD` 不能为空

### Q3: 前端页面打开空白

- 检查 `nginx.conf` 中 `BACKEND_INTERNAL_URL` 是否已替换为真实地址
- 检查后端是否已成功启动（查看后端服务的 Logs）

### Q4: 数据库中文乱码

- `fuint-db.sql` 已设置 `utf8mb4` 字符集
- 导入时确保客户端字符集也为 `utf8mb4`

### Q5: Railway 免费额度说明

Railway 提供每月 $5 免费额度（约 500 小时运行时间）。
- 建议关闭不需要的 TCP Proxy 减少网络费用
- 可在 **Settings → Sleeping** 开启空闲休眠节省资源

### Q6: 后端上传文件无法持久化

Railway 容器文件系统是临时的，重新部署后文件会丢失。  
**解决方案**：将 `uploadFile.path` 配置改为对象存储（如阿里云 OSS、腾讯云 COS）。

---

## 八、默认账号

| 项目 | 值 |
|------|------|
| 管理后台 | `https://fuint-frontend.up.railway.app/fuintAdmin/` |
| 用户名 | `fuint` |
| 密码 | `fuint2023` |

---

*如有问题请在 Railway 控制台各服务的 **Logs** 标签查看实时日志。*
