#!/bin/bash

# 定义颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 容器名
NAME='tm'

# 语言选择
LANGUAGE=""

# 函数：清屏
clear_screen() {
    clear
}

# 函数：彩色输出
print_color() {
    printf "${!1}%s${NC}\n" "$2"
}

# 函数：读取用户输入
reading() {
    local prompt="$1"
    local var_name="$2"
    printf "${GREEN}%s${NC}" "$prompt"
    read -r "$var_name"
}

# 函数：选择语言
select_language() {
    if [ -z "$LANGUAGE" ]; then
        clear_screen
        print_color CYAN "Please select your language / 请选择你的语言:"
        print_color YELLOW "1. English"
        print_color YELLOW "2. 中文"
        reading "Enter your choice (1 or 2): " "lang_choice"

        case $lang_choice in
            1) LANGUAGE="EN";;
            2) LANGUAGE="CN";;
            *) print_color RED "Invalid choice. Default to English."; LANGUAGE="EN";;
        esac
    fi
}

# 函数：根据选择的语言显示文本
display_text() {
    if [ "$LANGUAGE" = "CN" ]; then
        echo -n "$2"
    else
        echo -n "$1"
    fi
}

# 检查root权限
check_root() {
    if [[ $(id -u) != 0 ]]; then
        display_text "This script must be run as root." "此脚本必须以root身份运行。"
        exit 1
    fi
}

# 检查并安装必要的工具
install_required_packages() {
    local packages_to_install=""

    if ! command -v curl &> /dev/null; then
        packages_to_install+=" curl"
    fi

    if ! command -v wget &> /dev/null; then
        packages_to_install+=" wget"
    fi

    if [ -n "$packages_to_install" ]; then
        print_color YELLOW "$(display_text "Installing required packages:${packages_to_install}" "正在安装必要的包：${packages_to_install}")"
        if command -v apt-get &> /dev/null; then
            apt-get update && apt-get install -y $packages_to_install
        elif command -v yum &> /dev/null; then
            yum install -y $packages_to_install
        else
            print_color RED "$(display_text "Unable to install packages. Please install manually: ${packages_to_install}" "无法安装软件包。请手动安装：${packages_to_install}")"
            exit 1
        fi
    fi
}

# 检查系统和安装Docker
check_system_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        print_color YELLOW "$(display_text "Docker not found. Installing Docker..." "未找到Docker。正在安装Docker...")"

        # 检测操作系统
        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$ID
        else
            OS=$(uname -s)
        fi

        case $OS in
            debian|ubuntu)
                # 安装必要的包
                apt-get update
                apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

                # 添加Docker的官方GPG密钥
                curl -fsSL https://download.docker.com/linux/$OS/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

                # 设置稳定版仓库
                echo \
                "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS \
                $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

                # 安装Docker Engine
                apt-get update
                apt-get install -y docker-ce docker-ce-cli containerd.io
                ;;
            centos|fedora|rhel)
                # 安装必要的包
                yum install -y yum-utils

                # 设置稳定版仓库
                yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo

                # 安装Docker Engine
                yum install -y docker-ce docker-ce-cli containerd.io
                ;;
            *)
                print_color RED "$(display_text "Unsupported operating system. Please install Docker manually." "不支持的操作系统。请手动安装Docker。")"
                exit 1
                ;;
        esac

        # 启动Docker
        systemctl start docker
        systemctl enable docker
    else
        print_color GREEN "$(display_text "Docker is already installed." "Docker已经安装。")"
    fi

    if ! systemctl is-active --quiet docker; then
        print_color YELLOW "$(display_text "Docker is not running. Starting Docker..." "Docker未运行。正在启动Docker...")"
        systemctl start docker
    fi

    # 验证Docker是否正确安装和运行
    if docker info &>/dev/null; then
        print_color GREEN "$(display_text "Docker is installed and running." "Docker已安装并运行。")"
    else
        print_color RED "$(display_text "Failed to install or start Docker. Please check your system and try again." "安装或启动Docker失败。请检查您的系统并重试。")"
        exit 1
    fi
}

# 检查IPv4
check_ipv4() {
    if ! curl -s4m8 ifconfig.co | grep -q '\.'; then
        print_color RED "$(display_text "Error: The host must have IPv4." "错误：主机必须有IPv4。")"
        exit 1
    fi
}

# 检查CPU架构
check_architecture() {
    ARCHITECTURE=$(uname -m)
    case "$ARCHITECTURE" in
        aarch64 ) ARCH=arm64v8;;
        armv7l ) ARCH=arm32v7;;
        x64|x86_64|amd64 ) ARCH=latest;;
        * ) print_color RED "$(display_text "Error: Unsupported architecture: $ARCHITECTURE" "错误：不支持的架构：$ARCHITECTURE")"; exit 1;;
    esac
}

# 输入token
input_token() {
    if [ -z "$TMTOKEN" ]; then
        reading "$(display_text "Enter your Traffmonetizer token: " "输入你的Traffmonetizer令牌：")" "TMTOKEN"
        if [ -z "$TMTOKEN" ]; then
            print_color RED "$(display_text "Error: Token cannot be empty." "错误：令牌不能为空。")"
            input_token
        fi
    fi
}

# 输入设备名称
input_device_name() {
    reading "$(display_text "Enter device name (optional, press Enter to skip): " "输入设备名称（可选，按Enter跳过）：")" "DEVICE_NAME"
}

# 安装Traffmonetizer
install_traffmonetizer() {
    clear_screen
    if docker ps -a | grep -q "$NAME"; then
        print_color YELLOW "$(display_text "Traffmonetizer is already installed." "Traffmonetizer已经安装。")"
        return
    fi

    print_color YELLOW "$(display_text "Installing Traffmonetizer..." "正在安装Traffmonetizer...")"

    # 拉取镜像
    docker pull traffmonetizer/cli_v2:$ARCH

    # 创建容器
    if [ -n "$DEVICE_NAME" ]; then
        docker run -d --name $NAME --restart always traffmonetizer/cli_v2:$ARCH start accept --token "$TMTOKEN" --device-name "$DEVICE_NAME"
    else
        docker run -d --name $NAME --restart always traffmonetizer/cli_v2:$ARCH start accept --token "$TMTOKEN"
    fi

    if [ $? -eq 0 ]; then
        print_color GREEN "$(display_text "Traffmonetizer installed successfully." "Traffmonetizer安装成功。")"
    else
        print_color RED "$(display_text "Failed to install Traffmonetizer. Please check your token and try again." "安装Traffmonetizer失败。请检查您的令牌并重试。")"
    fi
}

# 卸载Traffmonetizer
uninstall_traffmonetizer() {
    clear_screen
    if ! docker ps -a | grep -q "$NAME"; then
        print_color YELLOW "$(display_text "Traffmonetizer is not installed." "Traffmonetizer未安装。")"
        return
    fi

    print_color YELLOW "$(display_text "Uninstalling Traffmonetizer..." "正在卸载Traffmonetizer...")"
    docker rm -f $(docker ps -a | grep -w "$NAME" | awk '{print $1}') 2>/dev/null
    docker rmi -f $(docker images | grep traffmonetizer/cli_v2 | awk '{print $3}') 2>/dev/null
    print_color GREEN "$(display_text "Traffmonetizer uninstalled." "Traffmonetizer已卸载。")"
}

# 显示状态
show_status() {
    clear_screen
    if docker ps | grep -q "$NAME"; then
        print_color CYAN "$(display_text "Traffmonetizer Status:" "Traffmonetizer状态：")"
        if ! docker exec $NAME /bin/sh -c "if [ -f /bin/cli_v2 ]; then /bin/cli_v2 status; elif [ -f /app/cli_v2 ]; then /app/cli_v2 status; else echo 'CLI not found'; fi"; then
            print_color RED "$(display_text "Failed to get status." "获取状态失败。")"
        fi

        print_color CYAN "$(display_text "Traffmonetizer Statistics:" "Traffmonetizer统计：")"
        if ! docker exec $NAME /bin/sh -c "if [ -f /bin/cli_v2 ]; then /bin/cli_v2 statistics; elif [ -f /app/cli_v2 ]; then /app/cli_v2 statistics; else echo 'CLI not found'; fi"; then
            print_color RED "$(display_text "Failed to get statistics." "获取统计信息失败。")"
        fi
    else
        print_color RED "$(display_text "Traffmonetizer is not running." "Traffmonetizer未运行。")"
    fi
}

# 卸载Docker、Watchtower和清理系统
uninstall_docker_and_cleanup() {
    clear_screen
    print_color YELLOW "$(display_text "Uninstalling Docker, Watchtower and cleaning up the system..." "正在卸载Docker、Watchtower并清理系统...")"

    # 检查Docker是否安装
    if command -v docker &> /dev/null; then
        # 停止并删除Watchtower容器（如果存在）
        if docker ps -a | grep -q 'watchtower'; then
            print_color YELLOW "$(display_text "Removing Watchtower..." "正在移除Watchtower...")"
            docker stop watchtower 2>/dev/null
            docker rm watchtower 2>/dev/null
            docker rmi containrrr/watchtower 2>/dev/null
        fi

        # 停止所有容器
        docker stop $(docker ps -aq) 2>/dev/null

        # 删除所有容器
        docker rm $(docker ps -aq) 2>/dev/null

        # 删除所有镜像
        docker rmi $(docker images -q) 2>/dev/null

        # 删除所有卷
        docker volume rm $(docker volume ls -q) 2>/dev/null

        # 删除所有网络
        docker network rm $(docker network ls -q) 2>/dev/null
    else
        print_color YELLOW "$(display_text "Docker is not installed or already removed." "Docker未安装或已被移除。")"
    fi

    # 卸载Docker
    if command -v apt-get &> /dev/null; then
        apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker.io
        apt-get autoremove -y
    elif command -v yum &> /dev/null; then
        yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker
        yum autoremove -y
    fi

    # 删除Docker数据目录
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd

    # 删除Docker配置文件
    rm -rf /etc/docker

    # 删除Docker系统服务文件
    rm -f /etc/systemd/system/docker.service
    rm -f /etc/systemd/system/docker.socket

    # 刷新系统服务
    systemctl daemon-reload

    # 检查iptables是否安装
    if command -v iptables &> /dev/null; then
        # 清理IPTables规则
        iptables -F
        iptables -X
        iptables -t nat -F
        iptables -t nat -X
        iptables -t mangle -F
        iptables -t mangle -X
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
    else
        print_color YELLOW "$(display_text "iptables is not installed or already removed." "iptables未安装或已被移除。")"
    fi

    print_color GREEN "$(display_text "Docker, Watchtower have been uninstalled and the system has been cleaned up." "Docker、Watchtower已卸载，系统已清理。")"
}

# 显示菜单
show_menu() {
    clear_screen
    print_color PURPLE "======================================="
    print_color CYAN "$(display_text "Traffmonetizer Management Script" "Traffmonetizer 管理脚本")"
    print_color PURPLE "======================================="
    print_color YELLOW "1. $(display_text "Install Traffmonetizer" "安装 Traffmonetizer")"
    print_color YELLOW "2. $(display_text "Uninstall Traffmonetizer" "卸载 Traffmonetizer")"
    print_color YELLOW "3. $(display_text "Show Status" "显示状态")"
    print_color YELLOW "4. $(display_text "Uninstall Docker, Watchtower and Cleanup" "卸载 Docker、Watchtower 并清理系统")"
    print_color YELLOW "5. $(display_text "Exit" "退出")"
    print_color PURPLE "======================================="
    reading "$(display_text "Enter your choice [1-5]: " "输入你的选择 [1-5]：")" "choice"
}

# 主程序
main() {
    check_root
    select_language
    install_required_packages
    check_system_and_install_docker
    check_ipv4
    check_architecture

    while true; do
        show_menu
        case $choice in
            1)
                input_token
                input_device_name
                install_traffmonetizer
                ;;
            2)
                uninstall_traffmonetizer
                ;;
            3)
                show_status
                ;;
            4)
                uninstall_docker_and_cleanup
                ;;
            5)
                clear_screen
                print_color GREEN "$(display_text "Exiting..." "正在退出...")"
                exit 0
                ;;
            *)
                print_color RED "$(display_text "Invalid option, please try again." "无效选项，请重试。")"
                ;;
        esac
        reading "$(display_text "Press Enter to continue..." "按Enter继续...")" "temp"
    done
}

# 处理命令行参数
while getopts "UuT:t:" OPTNAME; do
    case "$OPTNAME" in
        'U'|'u' ) uninstall_traffmonetizer; exit 0;;
        'T'|'t' ) TMTOKEN=$OPTARG;;
    esac
done

# 运行主程序
main
