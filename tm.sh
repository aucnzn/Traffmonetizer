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

# 检查系统和安装Docker
check_system_and_install_docker() {
    if ! command -v docker &> /dev/null; then
        print_color YELLOW "$(display_text "Docker not found. Installing Docker..." "未找到Docker。正在安装Docker...")"
        curl -fsSL https://get.docker.com | sh
        systemctl enable docker
        systemctl start docker
    fi
    print_color GREEN "$(display_text "Docker is installed and running." "Docker已安装并运行。")"
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
    print_color YELLOW "$(display_text "Installing Traffmonetizer..." "正在安装Traffmonetizer...")"

    # 删除旧容器（如果存在）
    docker ps -a | awk '{print $NF}' | grep -qw "$NAME" && docker rm -f "$NAME" >/dev/null 2>&1

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

    # 安装Watchtower
    if ! docker ps -a | grep -q 'watchtower'; then
        docker run -d --name watchtower --restart always -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --cleanup >/dev/null 2>&1
        print_color GREEN "$(display_text "Watchtower installed for automatic updates." "已安装Watchtower以进行自动更新。")"
    fi
}

# 卸载Traffmonetizer
uninstall_traffmonetizer() {
    clear_screen
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

# 设置多IP
setup_multi_ip() {
    clear_screen
    print_color YELLOW "$(display_text "Setting up Multi-IP Configuration..." "正在设置多IP配置...")"
    reading "$(display_text "Enter the number of networks: " "输入网络数量：")" "network_count"
    for ((i=1; i<=$network_count; i++)); do
        reading "$(display_text "Enter subnet for network $i (e.g., 192.168.33.0/24): " "输入网络 $i 的子网（例如，192.168.33.0/24）：")" "subnet"
        reading "$(display_text "Enter public IP for network $i: " "输入网络 $i 的公网IP：")" "public_ip"
        docker network create my_network_$i --driver bridge --subnet $subnet
        iptables -t nat -I POSTROUTING -s $subnet -j SNAT --to-source $public_ip
        reading "$(display_text "Enter token for instance $i: " "输入实例 $i 的令牌：")" "token"
        reading "$(display_text "Enter device name for instance $i (optional): " "输入实例 $i 的设备名称（可选）：")" "device_name"
        if [ -n "$device_name" ]; then
            docker run -d --network my_network_$i --name tm_$i --restart always traffmonetizer/cli_v2:$ARCH start accept --token $token --device-name "$device_name"
        else
            docker run -d --network my_network_$i --name tm_$i --restart always traffmonetizer/cli_v2:$ARCH start accept --token $token
        fi
    done
    print_color GREEN "$(display_text "Multi-IP setup complete." "多IP设置完成。")"
}

# 卸载Docker
uninstall_docker() {
    clear_screen
    print_color YELLOW "$(display_text "Uninstalling Docker..." "正在卸载Docker...")"

    # 停止所有容器
    docker stop $(docker ps -aq)

    # 删除所有容器
    docker rm $(docker ps -aq)

    # 删除所有镜像
    docker rmi $(docker images -q)

    # 删除所有卷
    docker volume rm $(docker volume ls -q)

    # 删除所有网络
    docker network rm $(docker network ls -q)

    # 卸载Docker
    if command -v apt-get &> /dev/null; then
        apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        apt-get autoremove -y
    elif command -v yum &> /dev/null; then
        yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        yum autoremove -y
    fi

    # 删除Docker数据目录
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd

    print_color GREEN "$(display_text "Docker has been uninstalled." "Docker已卸载。")"
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
    print_color YELLOW "4. $(display_text "Setup Multi-IP" "设置多IP")"
    print_color YELLOW "5. $(display_text "Uninstall Docker" "卸载 Docker")"
    print_color YELLOW "6. $(display_text "Exit" "退出")"
    print_color PURPLE "======================================="
    reading "$(display_text "Enter your choice [1-6]: " "输入你的选择 [1-6]：")" "choice"
}

# 主程序
main() {
    check_root
    select_language
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
                setup_multi_ip
                ;;
            5)
                uninstall_docker
                ;;
            6)
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
