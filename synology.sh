#!/usr/bin/env bash
# 群晖部署：配置和持久化数据集中在本脚本所在目录。
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$PROJECT_DIR/docker-compose.synology.yml"
ENV_FILE="$PROJECT_DIR/.env.synology"

init_files() {
    umask 077
    if [ ! -f "$ENV_FILE" ]; then
        command -v openssl >/dev/null || { echo "需要 openssl 生成初始密码。" >&2; exit 1; }
        local root_password db_password redis_password internal_token
        root_password="$(openssl rand -hex 24)"
        db_password="$(openssl rand -hex 24)"
        redis_password="$(openssl rand -hex 24)"
        internal_token="$(openssl rand -hex 24)"
        cat > "$ENV_FILE" <<EOF
# 所有服务统一读取本文件。密码初始化后请保留，重复 init 不会覆盖。
COMPOSE_PROJECT_NAME=xianyu-nas
FRONTEND_PORT=9000
MYSQL_IMAGE=mysql:8.0
REDIS_IMAGE=redis:7-alpine
MYSQL_DATABASE=xianyu_data
MYSQL_USER=xianyu
MYSQL_ROOT_PASSWORD=$root_password
MYSQL_PASSWORD=$db_password
REDIS_PASSWORD=$redis_password
INTERNAL_API_TOKEN=$internal_token
MAX_CAPTCHA_CONCURRENT=1
REMOTE_OFFICIAL_BASE_URL=
ENABLE_REMOTE_ADS=false
ENABLE_REMOTE_ANNOUNCEMENTS=false
ENABLE_REMOTE_POPUP_ANNOUNCEMENTS=false
FRONTEND_PUBLIC_URL=
BACKEND_WEB_PUBLIC_URL=
EOF
        echo "已生成 .env.synology；没有输出密码。"
    fi
    mkdir -p "$PROJECT_DIR/runtime"/{mysql,redis,static/uploads,backups,browser_data,config,logs/backend-web,logs/websocket,logs/scheduler,logs/common}
    if [ ! -f "$PROJECT_DIR/runtime/config/update_config.json" ]; then
        printf '%s\n' '{"update_url": ""}' > "$PROJECT_DIR/runtime/config/update_config.json"
    fi
    echo "项目目录：$PROJECT_DIR"
}

setup_compose() {
    if docker compose version >/dev/null 2>&1; then
        DC=(docker compose)
    elif command -v docker-compose >/dev/null; then
        DC=(docker-compose)
    else
        echo "请先在群晖安装 Container Manager / Docker。" >&2
        exit 1
    fi
    [ -f "$ENV_FILE" ] || { echo "请先运行 bash synology.sh init。" >&2; exit 1; }
}

compose() {
    "${DC[@]}" --project-name xianyu-nas --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

case "${1:-help}" in
    init) init_files ;;
    start|update)
        init_files
        setup_compose
        compose config --quiet
        compose up -d --build
        echo "启动命令已完成，请通过 status / logs 检查服务状态。"
        echo "管理界面：http://群晖局域网IP:端口（默认 9000，见 .env.synology）"
        ;;
    stop)
        setup_compose
        compose stop
        ;;
    status)
        setup_compose
        compose ps
        ;;
    logs)
        setup_compose
        compose logs -f --tail=100
        ;;
    uninstall)
        setup_compose
        compose down --remove-orphans
        echo "已移除本项目容器和网络，配置和数据仍保留在 ${PROJECT_DIR}。"
        echo "需要彻底删除时，在 File Station 中删除这个项目文件夹。"
        echo "Docker 镜像和构建缓存可在 Container Manager 中另行清理。"
        ;;
    *)
        echo "用法：bash synology.sh [init|start|update|stop|status|logs|uninstall]"
        ;;
esac
