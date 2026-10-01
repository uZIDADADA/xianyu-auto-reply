# 群晖集中目录部署

本方案将源代码、统一配置、数据库、上传文件、浏览器登录状态、日志和备份放在同一个项目文件夹。建议路径为 `/volume1/docker/xianyu-auto-reply`；如果使用其他存储卷，替换为对应路径即可。

需要群晖安装 Container Manager / Docker，并有足够可用内存和磁盘空间。建议至少 8GB 总内存；ARM 机型的浏览器依赖需另行验证。本方案尚未在真实群晖上启动验证。首次构建会下载基础镜像、Python/Node 依赖和浏览器，需要能访问相关下载源。

## 首次部署

在群晖 SSH 中执行：

```bash
mkdir -p /volume1/docker
cd /volume1/docker
git clone -b dev https://github.com/uZIDADADA/xianyu-auto-reply.git
cd xianyu-auto-reply
bash synology.sh init
sudo bash synology.sh start
sudo bash synology.sh status
```

如果群晖没有安装 `git`，可下载此仓库 `dev` 分支的 ZIP，通过 File Station 解压到上述目录，再执行 `init` 和 `start`。ZIP 安装的后续更新也需替换源码，保留 `.env.synology` 和 `runtime/`。

打开 `http://192.168.1.120:9000`（替换为群晖当前 IP）。项目原始默认后台账号为 `admin / admin123`，首次登录后修改密码。端口冲突时，在 `.env.synology` 修改 `FRONTEND_PORT` 后重新执行 `start`。

所有服务的环境配置在 `.env.synology`。首次初始化自动生成数据库密码与内部服务令牌，重复初始化不会覆盖。应用中的账号 Cookie、自动回复规则和系统设置存储在 MySQL，数据库文件位于 `runtime/mysql/`，因此也在同一文件夹。

```text
/volume1/docker/xianyu-auto-reply/
├── .env.synology                  # 统一配置与密码
├── docker-compose.synology.yml    # 群晖专用容器配置
├── synology.sh                    # 部署与卸载命令
├── runtime/
│   ├── mysql/                     # 账号、规则、设置、订单等数据库
│   ├── redis/                     # Redis 持久化文件
│   ├── config/                    # 更新等 JSON 配置
│   ├── browser_data/              # 浏览器登录状态
│   ├── static/                    # 上传图片、附件等
│   ├── logs/                      # 应用日志、轨迹记录
│   └── backups/                   # 数据库备份
└── …                              # 项目源码
```

本方案使用目录挂载，不创建 Docker 命名数据卷；只向局域网发布前端端口。三个后端服务、MySQL 和 Redis 通过 Docker 内部网络通信。`start/update/stop/uninstall` 都应使用 `synology.sh`，不要混用普通 `deploy.sh`、`update.sh` 或根目录默认 Compose 文件。已有其他方式部署的数据不会自动迁移到本目录。

镜像、构建缓存、容器临时文件和 Docker 自身的轮转日志由 Container Manager 管理，不是项目配置文件；它们不位于项目文件夹。容器临时文件在卸载容器时一并删除，镜像和构建缓存可按需单独清理。

## 更新与备份

Git 安装方式：

```bash
cd /volume1/docker/xianyu-auto-reply
git pull --ff-only origin dev
sudo bash synology.sh update
```

完整备份时先停止所有服务，再复制整个项目文件夹，避免复制到正在写入的数据库：

```bash
sudo bash synology.sh stop
# 此时通过 File Station 备份整个项目文件夹
sudo bash synology.sh start
```

运行目录和密码文件已从 Git 与 Docker 构建上下文排除，更新源码不会覆盖它们。数据目录由容器运行用户写入，备份时需要使用有权限的群晖账户。不要对项目或数据库目录执行 `chmod -R 777`。

## 卸载

先在项目目录执行：

```bash
sudo bash synology.sh uninstall
```

这会移除本项目容器与网络，但保留数据。确认不再需要或已经备份后，在 File Station 删除 `/volume1/docker/xianyu-auto-reply`，即可删除本项目源码、配置和持久化数据。删除该文件夹包含账号、Cookie、规则和订单数据库，无法通过重新克隆源码恢复。

如需回收镜像空间，在 Container Manager 中清理名称以 `xianyu-nas-` 开头的应用镜像。MySQL / Redis 基础镜像可能被其他项目共用，应确认没有其他容器使用后再清理。
