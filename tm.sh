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

# 使用关联数组存储多语言文本
declare -A TEXTS
TEXTS[install_en]="Installing"
TEXTS[install_cn]="正在安装"
TEXTS[uninstall_en]="Uninstalling"
TEXTS[uninstall_cn]="正在卸载"
TEXTS[docker_installed_en]="Docker is already installed."
TEXTS[docker_installed_cn]="Docker 已经安装。"
TEXTS[docker_not_found_en]="Docker not found. Installing Docker..."
TEXTS[docker_not_found_cn]="未找到 Docker。正在安装 Docker..."
TEXTS[low_memory_en]="Low memory system detected. Installing Docker for low-end devices."
TEXTS[low_memory_cn]="检测到低内存系统。正在为低配置设备安装 Docker。"
TEXTS[standard_docker_en]="Installing standard Docker version."
TEXTS[standard_docker_cn]="正在安装标准 Docker 版本。"
TEXTS[docker_success_en]="Docker is installed and running."
TEXTS[docker_success_cn]="Docker 已安装并正在运行。"
TEXTS[docker_fail_en]="Failed to install or start Docker. Please check your system and try again."
TEXTS[docker_fail_cn]="安装或启动 Docker 失败。请检查您的系统并重试。"
TEXTS[ipv4_error_en]="Error: The host must have IPv4."
TEXTS[ipv4_error_cn]="错误：主机必须有 IPv4。"
TEXTS[arch_error_en]="Error: Unsupported architecture:"
TEXTS[arch_error_cn]="错误：不支持的架构："
TEXTS[token_prompt_en]="Enter your Traffmonetizer token: "
TEXTS[token_prompt_cn]="输入你的 Traffmonetizer 令牌："
TEXTS[token_empty_en]="Error: Token cannot be empty."
TEXTS[token_empty_cn]="错误：令牌不能为空。"
TEXTS[device_name_prompt_en]="Enter device name (optional, press Enter to skip): "
TEXTS[device_name_prompt_cn]="输入设备名称（可选，按 Enter 跳过）："
TEXTS[tm_installed_en]="Traffmonetizer is already installed."
TEXTS[tm_installed_cn]="Traffmonetizer 已经安装。"
TEXTS[tm_installing_en]="Installing Traffmonetizer..."
TEXTS[tm_installing_cn]="正在安装 Traffmonetizer..."
TEXTS[tm_success_en]="Traffmonetizer installed successfully."
TEXTS[tm_success_cn]="Traffmonetizer 安装成功。"
TEXTS[tm_fail_en]="Failed to install Traffmonetizer. Please check your token and try again."
TEXTS[tm_fail_cn]="安装 Traffmonetizer 失败。请检查您的令牌并重试。"
TEXTS[tm_not_installed_en]="Traffmonetizer is not installed."
TEXTS[tm_not_installed_cn]="Traffmonetizer 未安装。"
TEXTS[tm_uninstalling_en]="Uninstalling Traffmonetizer..."
TEXTS[tm_uninstalling_cn]="正在卸载 Traffmonetizer..."
TEXTS[tm_uninstalled_en]="Traffmonetizer uninstalled."
TEXTS[tm_uninstalled_cn]="Traffmonetizer 已卸载。"
TEXTS[tm_not_running_en]="Traffmonetizer is not running."
TEXTS[tm_not_running_cn]="Traffmonetizer 未运行。"
TEXTS[tm_status_en]="Traffmonetizer Status:"
TEXTS[tm_status_cn]="Traffmonetizer 状态："
TEXTS[tm_statistics_en]="Traffmonetizer Statistics:"
TEXTS[tm_statistics_cn]="Traffmonetizer 统计："
TEXTS[cleanup_en]="Uninstalling Docker, Watchtower and cleaning up the system..."
TEXTS[cleanup_cn]="正在卸载 Docker、Watchtower 并清理系统..."
TEXTS[cleanup_done_en]="Docker, Watchtower have been uninstalled and the system has been cleaned up."
TEXTS[cleanup_done_cn]="Docker、Watchtower 已卸载，系统已清理。"
TEXTS[menu_title_en]="Traffmonetizer Management Script"
TEXTS[menu_title_cn]="Traffmonetizer 管理脚本"
TEXTS[menu_install_en]="Install Traffmonetizer"
TEXTS[menu_install_cn]="安装 Traffmonetizer"
TEXTS[menu_uninstall_en]="Uninstall Traffmonetizer"
TEXTS[menu_uninstall_cn]="卸载 Traffmonetizer"
TEXTS[menu_status_en]="Show Status"
TEXTS[menu_status_cn]="显示状态"
TEXTS[menu_cleanup_en]="Uninstall Docker, Watchtower and Cleanup"
TEXTS[menu_cleanup_cn]="卸载 Docker、Watchtower 并清理系统"
TEXTS[menu_exit_en]="Exit"
TEXTS[menu_exit_cn]="退出"
TEXTS[menu_prompt_en]="Enter your choice [1-5]: "
TEXTS[menu_prompt_cn]="输入你的选择 [1-5]："
TEXTS[invalid_option_en]="Invalid option, please try again."
TEXTS[invalid_option_cn]="无效选项，请重试。"
TEXTS[exiting_en]="Exiting..."
TEXTS[exiting_cn]="正在退出..."
TEXTS[continue_prompt_en]="Press Enter to continue..."
TEXTS[continue_prompt_cn]="按 Enter 继续..."
TEXTS[system_status_en]="System Status"
TEXTS[system_status_cn]="系统状态"
TEXTS[docker_running_en]="Docker is running"
TEXTS[docker_running_cn]="Docker 正在运行"
TEXTS[docker_not_running_en]="Docker is not running"
TEXTS[docker_not_running_cn]="Docker 未运行"
TEXTS[tm_running_en]="Traffmonetizer is running"
TEXTS[tm_running_cn]="Traffmonetizer 正在运行"
TEXTS[tm_not_running_en]="Traffmonetizer is not running"
TEXTS[tm_not_running_cn]="Traffmonetizer 未运行"
TEXTS[tm_uptime_en]="Running since:"
TEXTS[tm_uptime_cn]="运行时间："
TEXTS[tm_usage_en]="Resource usage:"
TEXTS[tm_usage_cn]="资源使用："
TEXTS[running_containers_en]="Running Docker Containers:"
TEXTS[running_containers_cn]="正在运行的 Docker 容器："
TEXTS[no_running_containers_en]="No running containers"
TEXTS[no_running_containers_cn]="没有正在运行的容器"


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
        read -r lang_choice
        LANGUAGE=$([[ $lang_choice == 2 ]] && echo "CN" || echo "EN")
    fi
}

# 函数：显示多语言文本
display_text() {
    local key="${1}_${LANGUAGE,,}"
    echo -n "${TEXTS[$key]:-$1}"
}

# 检查root权限
check_root() {
    if [[ $(id -u) != 0 ]]; then
        display_text "This script must be run as root." "此脚本必须以root身份运行。"
        exit 1
    fi
}

# 安装必要的包
install_required_packages() {
    local packages_to_install=""
    for pkg in curl wget; do
        command -v $pkg &>/dev/null || packages_to_install+=" $pkg"
    done

    if [ -n "$packages_to_install" ]; then
        print_color YELLOW "$(display_text "Installing required packages:${packages_to_install}")"
        if command -v apt-get &>/dev/null; then
            apt-get update && apt-get install -y $packages_to_install
        elif command -v yum &>/dev/null; then
            yum install -y $packages_to_install
        else
            print_color RED "$(display_text "Unable to install packages. Please install manually: ${packages_to_install}")"
            exit 1
        fi
    fi
}

# 检查系统内存
check_system_memory() {
    local total_mem=$(free -m | awk '/^Mem:/{print $2}')
    if [ $total_mem -lt 512 ]; then
        return 1  # 低内存系统
    else
        return 0  # 正常内存系统
    fi
}

# 安装Docker
install_docker() {
    local is_low_mem=$1

    if [ "$is_low_mem" = true ]; then
        print_color YELLOW "$(display_text "low_memory")"
        curl -fsSL https://get.docker.com/ | sh -s docker --mirror Aliyun
    else
        print_color YELLOW "$(display_text "standard_docker")"
        curl -fsSL https://get.docker.com/ | sh
    fi

    systemctl start docker
    systemctl enable docker

    if docker info &>/dev/null; then
        print_color GREEN "$(display_text "docker_success")"
    else
        print_color RED "$(display_text "docker_fail")"
        exit 1
    fi
}

# 检查系统并安装Docker
check_system_and_install_docker() {
    if command -v docker &>/dev/null; then
        print_color GREEN "$(display_text "docker_installed")"
        return
    fi

    print_color YELLOW "$(display_text "docker_not_found")"

    if check_system_memory; then
        install_docker false
    else
        install_docker true
    fi
}

# 检查IPv4
check_ipv4() {
    if ! curl -s4m8 ifconfig.co | grep -q '\.'; then
        print_color RED "$(display_text "ipv4_error")"
        exit 1
    fi
}

# 检查CPU架构
check_architecture() {
    case "$(uname -m)" in
        aarch64) ARCH=arm64v8 ;;
        armv7l)  ARCH=arm32v7 ;;
        x86_64|amd64) ARCH=latest ;;
        *) print_color RED "$(display_text "arch_error") $(uname -m)"; exit 1 ;;
    esac
}

# 输入token
input_token() {
    if [ -z "$TMTOKEN" ]; then
        reading "$(display_text "token_prompt")" "TMTOKEN"
        if [ -z "$TMTOKEN" ]; then
            print_color RED "$(display_text "token_empty")"
            input_token
        fi
    fi
}

# 输入设备名称
input_device_name() {
    reading "$(display_text "device_name_prompt")" "DEVICE_NAME"
}

# 安装Traffmonetizer
install_traffmonetizer() {
    clear_screen
    if docker ps -a | grep -q "$NAME"; then
        print_color YELLOW "$(display_text "tm_installed")"
        return
    fi

    print_color YELLOW "$(display_text "tm_installing")"
    docker pull traffmonetizer/cli_v2:$ARCH

    local run_cmd="docker run -d --name $NAME --restart always traffmonetizer/cli_v2:$ARCH start accept --token $TMTOKEN"
    [ -n "$DEVICE_NAME" ] && run_cmd+=" --device-name $DEVICE_NAME"

    if $run_cmd; then
        print_color GREEN "$(display_text "tm_success")"
    else
        print_color RED "$(display_text "tm_fail")"
    fi
}

# 卸载Traffmonetizer
uninstall_traffmonetizer() {
    clear_screen
    if ! docker ps -a | grep -q "$NAME"; then
        print_color YELLOW "$(display_text "tm_not_installed")"
        return
    fi

    print_color YELLOW "$(display_text "tm_uninstalling")"
    docker rm -f $NAME 2>/dev/null
    docker rmi -f $(docker images -q traffmonetizer/cli_v2) 2>/dev/null
    print_color GREEN "$(display_text "tm_uninstalled")"
}

# 显示状态
show_status() {
    clear_screen
    print_color CYAN "$(display_text "system_status")"

    # 检查 Docker 状态
    if systemctl is-active --quiet docker; then
        print_color GREEN "● $(display_text "docker_running")"
    else
        print_color RED "● $(display_text "docker_not_running")"
    fi

    # 检查 Traffmonetizer 状态
    if docker ps -q --filter "name=$NAME" | grep -q .; then
        print_color GREEN "● $(display_text "tm_running")"

        # 获取容器运行时间
        local uptime=$(docker inspect --format='{{.State.StartedAt}}' $NAME)
        uptime=$(date -d "$uptime" +'%Y-%m-%d %H:%M:%S')
        print_color BLUE "  $(display_text "tm_uptime") $uptime"

        # 获取容器的CPU和内存使用情况
        local usage=$(docker stats --no-stream --format "CPU: {{.CPUPerc}}  MEM: {{.MemUsage}}" $NAME)
        print_color YELLOW "  $(display_text "tm_usage") $usage"
    else
        print_color RED "● $(display_text "tm_not_running")"
    fi
}

# 卸载Docker、Watchtower和清理系统
uninstall_docker_and_cleanup() {
    clear_screen
    print_color YELLOW "$(display_text "cleanup")"

    if command -v docker &>/dev/null; then
        docker rm -f $(docker ps -aq) 2>/dev/null
        docker rmi -f $(docker images -q) 2>/dev/null
        docker volume rm $(docker volume ls -q) 2>/dev/null
        docker network rm $(docker network ls -q) 2>/dev/null
    fi

    if command -v apt-get &>/dev/null; then
        apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker.io
        apt-get autoremove -y
    elif command -v yum &>/dev/null; then
        yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker
        yum autoremove -y
    fi

    rm -rf /var/lib/docker /var/lib/containerd /etc/docker
    rm -f /etc/systemd/system/docker.service /etc/systemd/system/docker.socket

    systemctl daemon-reload

    if command -v iptables &>/dev/null; then
        iptables -F && iptables -X
        iptables -t nat -F && iptables -t nat -X
        iptables -t mangle -F && iptables -t mangle -X
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
    fi

    print_color GREEN "$(display_text "cleanup_done")"
}

# 显示菜单
show_menu() {
    clear_screen
    print_color PURPLE "======================================="
    print_color CYAN "$(display_text "menu_title")"
    print_color PURPLE "======================================="
    print_color YELLOW "1. $(display_text "menu_install")"
    print_color YELLOW "2. $(display_text "menu_uninstall")"
    print_color YELLOW "3. $(display_text "menu_status")"
    print_color YELLOW "4. $(display_text "menu_cleanup")"
    print_color YELLOW "5. $(display_text "menu_exit")"
    print_color PURPLE "======================================="
    reading "$(display_text "menu_prompt")" "choice"
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
                print_color GREEN "$(display_text "exiting")"
                exit 0
                ;;
            *)
                print_color RED "$(display_text "invalid_option")"
                ;;
        esac
        reading "$(display_text "continue_prompt")" "temp"
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
