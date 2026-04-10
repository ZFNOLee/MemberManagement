# fuint 会员管理系统 - Railway 部署指南

## 仓库地址

https://github.com/ZFNOLee/MemberManagement

---

## 部署步骤（图文指引）

### 第一步：创建 Railway 项目

1. 打开 https://railway.app ，登录（推荐用 GitHub 登录）
2. 点击 **New Project**
3. 选择 **Deploy from GitHub repo**
4. 授权并选择 `ZFNOLee/MemberManagement` 仓库
5. Railway 会自动创建第一个 Service，**先不要管它**，后面会配置

### 第二步：添加 MySQL 服务

1. 在项目中点击 **+ New Service**
2. 选择 **Database** → **Add MySQL**
3. Railway 会自动创建 MySQL 服务并分配变量

### 第三步：添加 Redis 服务

1. 在项目中点击 **+ New Service**
2. 选择 **Database** → **Add Redis**
3. Railway 会自动创建 Redis 服务

### 第四步：配置后端服务（第一个 Service）

1. 点击 Railway 自动创建的那个 Service（连接 GitHub 的那个）
2. 点击 **Settings** 标签
3. 找到 **Dockerfile Path** → 填入 `backend.dockerfile`
4. 点击 **Variables** 标签，添加以下环境变量：

| 变量名 | 值 | 说明 |
|--------|-----|------|
| `MYSQLHOST` | `${{MySQL.MYSQLHOST}}` | 引用 MySQL 服务变量 |
| `MYSQLPORT` | `${{MySQL.MYSQLPORT}}` | 引用 MySQL 端口 |
| `MYSQLUSER` | `${{MySQL.MYSQLUSER}}` | 引用 MySQL 用户名 |
| `MYSQLPASSWORD` | `${{MySQL.MYSQLPASSWORD}}` | 引用 MySQL 密码 |
| `MYSQLDATABASE` | `${{MySQL.MYSQLDATABASE}}` | 引用 MySQL 数据库名 |
| `REDISHOST` | `${{Redis.REDISHOST}}` | 引用 Redis 服务变量 |
| `REDISPORT` | `${{Redis.REDISPORT}}` | 引用 Redis 端口 |
| `REDISPASSWORD` | `${{Redis.REDISPASSWORD}}` | 引用 Redis 密码 |
| `PORT` | `8080` | 应用端口 |

> **注意**：`${{MySQL.MYSQLHOST}}` 这种写法是 Railway 的 Ref 变量语法，会自动引用 MySQL 服务的内部地址。你需要把 `MySQL` 和 `Redis` 替换为你实际的 Service 名称（在 Variables 页面有提示）。

5. 后端会自动重新部署，等待构建完成

### 第五步：配置前端服务

1. 在项目中点击 **+ New Service**
2. 选择 **GitHub Repo** → 再次选择 `ZFNOLee/MemberManagement`
3. 点击这个新 Service 的 **Settings**
4. 找到 **Dockerfile Path** → 填入 `frontend.dockerfile`
5. 点击 **Variables**，添加：

| 变量名 | 值 |
|--------|-----|
| `PORT` | `80` |

6. 等待构建完成

### 第六步：初始化数据库

1. 在 Railway 中点击 **MySQL** 服务
2. 点击 **Connect** → 开启 **TCP Proxy**（会显示连接地址和密码）
3. 使用 Navicat/DBeaver/MySQL CLI 连接到这个地址
4. 导入 `database/fuint-db.sql` 文件
5. 导入完成后可以关闭 TCP Proxy

> **SQL 文件获取**：从 GitHub 仓库的 `database/` 目录下载 `fuint-db.sql`（这是一个 Git LFS 文件）

### 第七步：配置前端 Nginx 反向代理（重要！）

为了让前端页面能调用后端 API，需要修改 nginx.conf：

1. 在 Railway 中查看后端 Service 的 **Private Networking** 地址（格式类似 `backend-svc-name.railway.internal:8080`）
2. 在前端 Service 的 **Variables** 中添加：
   - `BACKEND_INTERNAL_URL` = `http://你的后端服务名.railway.internal:8080`
3. 这需要修改 `frontend/nginx.conf` 中 `proxy_pass` 的值，然后提交推送

或者更简单的方式：在 Railway 前端 Service 的 **Settings** → **Raw Config** 中添加：
```json
{
  "BACKEND_INTERNAL_URL": "http://你的后端服务名.railway.internal:8080"
}
```

### 第八步：访问系统

- 前端地址：`https://你的前端服务名.up.railway.app/fuintAdmin/`
- 默认账号：`fuint`
- 默认密码：`fuint2023`

---

## 文件说明

```
MemberManagement/
├── backend.dockerfile        ← 后端 Docker 镜像定义（Railway 用这个）
├── frontend.dockerfile       ← 前端 Docker 镜像定义（Railway 用这个）
├── .dockerignore             ← Docker 构建忽略文件
├── RAILWAY-DEPLOY.md         ← 本文档
├── backend/
│   ├── Dockerfile            ← 原始 Dockerfile（备用）
│   ├── application.properties ← Spring Boot 配置
│   └── fuint-application-1.0.0.jar  ← 后端 JAR 包 (Git LFS)
├── frontend/
│   ├── Dockerfile            ← 原始 Dockerfile（备用）
│   ├── nginx.conf            ← Nginx 配置
│   ├── index.html            ← 前端入口
│   └── static/               ← 前端静态资源
└── database/
    └── fuint-db.sql          ← 完整数据库备份 (Git LFS)
```

---

## 常见问题

### 构建失败：Error creating build plan with Nixpacks
→ 检查 Settings → Dockerfile Path 是否填写了 `backend.dockerfile` 或 `frontend.dockerfile`

### 后端启动成功但前端无法访问 API
→ 需要修改 nginx.conf 中的 `proxy_pass` 指向后端的内部地址

### 数据库连接失败
→ 检查环境变量是否正确引用了 MySQL/Redis 服务变量（使用 `${{ServiceName.VAR}}` 语法）

### Git LFS 文件下载为指针文件
→ 本地需要安装 Git LFS：`git lfs install`，然后 `git pull`
