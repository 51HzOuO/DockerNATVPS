#!/bin/bash

clear
echo "#########################################################"
echo -e "#        帮你一键生出Docker NAT小鸡(Debian)          #"
echo -e "#                   Modified By 51HzOuO                 #"
echo "#########################################################"

# 语言选择
if [ $# -lt 5 ]; then
  echo "Language selection: Chinese(default):0, English:1"
  read -p "Enter choice (0 or 1): " LANG
  if [ -z "$LANG" ] || [ "$LANG" != "1" ]; then
    LANG=0
  fi
else
  LANG=0
fi

# 消息函数
msg() {
  if [ "$LANG" = "1" ]; then
    case "$1" in
      random_pass) echo "Random password: $2" ;;
      ssh_port_prompt) echo "Enter SSH port for the server: " ;;
      start_port_prompt) echo "Enter start forwarding port: " ;;
      end_port_prompt) echo "Enter end forwarding port: " ;;
      cpu_prompt) echo "CPU peak, converted to percentage (1-100) (default 50%): " ;;
      ram_prompt) echo "Allocate memory MB (default 256M): " ;;
      empty_input) echo "Input cannot be empty, please re-enter." ;;
      invalid_number) echo "Please enter a valid number." ;;
      default_end_port) echo "Using default end port: $2" ;;
      end_greater_start) echo "End port must be greater than start port, please re-enter." ;;
      cpu_range) echo "CPU percentage must be between 0-100." ;;
      default_cpu) echo "Using default CPU: $2%" ;;
      default_ram) echo "Using default memory: 256M" ;;
      ssh_in_range) echo "SSH port cannot be within the forwarding port range, please re-run the script." ;;
      checking_conflicts) echo "Checking port conflicts..." ;;
      ssh_occupied) echo "SSH port $2 is occupied." ;;
      port_occupied) echo "Forwarding port $2 is occupied." ;;
      no_conflicts) echo "Port check completed, no conflicts." ;;
      build_failed) echo "Docker image build failed." ;;
    esac
  else
    case "$1" in
      random_pass) echo "随机密码：$2" ;;
      ssh_port_prompt) echo "请输入小鸡SSH端口: " ;;
      start_port_prompt) echo "请输入开始转发端口: " ;;
      end_port_prompt) echo "请输入结束转发端口: " ;;
      cpu_prompt) echo "CPU峰值,已转换为百分值(1-100)(默认50%): " ;;
      ram_prompt) echo "分配内存MB(默认256M): " ;;
      empty_input) echo "输入不能为空，请重新输入。" ;;
      invalid_number) echo "请输入有效的数字。" ;;
      default_end_port) echo "使用默认结束端口: $2" ;;
      end_greater_start) echo "结束端口必须大于开始端口，请重新输入。" ;;
      cpu_range) echo "CPU百分值必须在0-100之间。" ;;
      default_cpu) echo "使用默认CPU: $2%" ;;
      default_ram) echo "使用默认内存: 256M" ;;
      ssh_in_range) echo "SSH端口不能在转发端口区间内，请重新运行脚本。" ;;
      checking_conflicts) echo "检测端口冲突..." ;;
      ssh_occupied) echo "SSH端口 $2 已被占用。" ;;
      port_occupied) echo "转发端口 $2 已被占用。" ;;
      no_conflicts) echo "端口检测完成，无冲突。" ;;
      build_failed) echo "Docker 镜像构建失败。" ;;
    esac
  fi
}

ssh_port=$1
tran_port_start=$2
tran_port_end=$3
cpu=$4
ram=$5

# 生成随机密码
GEN_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
msg random_pass "$GEN_PASS"

# 读取 配置
if [ -z "$ssh_port" ]; then
  while true; do
    ssh_prompt=$(msg ssh_port_prompt)
    read -e -p "$ssh_prompt" ssh_port
    if [ -z "$ssh_port" ]; then
      msg empty_input
      continue
    fi
    if ! [[ "$ssh_port" =~ ^[0-9]+$ ]]; then
      msg invalid_number
      continue
    fi
    # 检查SSH端口冲突
    if netstat -tuln 2>/dev/null | grep -q ":$ssh_port "; then
      msg ssh_occupied "$ssh_port"
      continue
    fi
    break
  done
fi

if [ -z "$tran_port_start" ] || [ -z "$tran_port_end" ]; then
  while true; do
    # 输入开始端口
    if [ -z "$tran_port_start" ]; then
      while true; do
        start_prompt=$(msg start_port_prompt)
        read -e -p "$start_prompt" tran_port_start
        if [ -z "$tran_port_start" ]; then
          msg empty_input
          continue
        fi
        if ! [[ "$tran_port_start" =~ ^[0-9]+$ ]]; then
          msg invalid_number
          continue
        fi
        break
      done
    fi

    # 输入结束端口
    if [ -z "$tran_port_end" ]; then
      while true; do
        end_prompt=$(msg end_port_prompt)
        read -e -p "$end_prompt" tran_port_end
        if [ -z "$tran_port_end" ]; then
          tran_port_end=$((tran_port_start + 10))
          msg default_end_port "$tran_port_end"
        fi
        if ! [[ "$tran_port_end" =~ ^[0-9]+$ ]]; then
          msg invalid_number
          continue
        fi
        if [ "$tran_port_end" -le "$tran_port_start" ]; then
          msg end_greater_start
          continue
        fi
        break
      done
    fi

    # 检查SSH端口是否在转发区间内
    if [ "$ssh_port" -ge "$tran_port_start" ] && [ "$ssh_port" -le "$tran_port_end" ]; then
      msg ssh_in_range
      # 重新输入开始和结束端口
      tran_port_start=""
      tran_port_end=""
      continue
    fi

    # 检查转发端口冲突
    conflict=false
    for port in $(seq $tran_port_start $tran_port_end); do
      if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        msg port_occupied "$port"
        conflict=true
        break
      fi
    done
    if $conflict; then
      # 重新输入开始和结束端口
      tran_port_start=""
      tran_port_end=""
      continue
    fi

    break
  done
fi

if [ -z "$cpu" ]; then
  while true; do
    cpu_prompt=$(msg cpu_prompt)
    read -e -p "$cpu_prompt" cpu
    if [ -z "$cpu" ]; then
      cpu=50
      msg default_cpu "50"
      break
    fi
    if ! [[ "$cpu" =~ ^[0-9]+$ ]]; then
      msg invalid_number
      continue
    fi
    if [ "$cpu" -lt 0 ] || [ "$cpu" -gt 100 ]; then
      msg cpu_range
      continue
    fi
    break
  done
fi

if [ -z "$ram" ]; then
  while true; do
    ram_prompt=$(msg ram_prompt)
    read -e -p "$ram_prompt" ram
    if [ -z "$ram" ]; then
      ram=256
      msg default_ram
      break
    fi
    if ! [[ "$ram" =~ ^[0-9]+$ ]]; then
      msg invalid_number
      continue
    fi
    break
  done
fi

# 端口检测已在输入时完成

# 替换 Dockerfile 中的密码
sed "s/{{ROOT_PASSWORD}}/$GEN_PASS/" Dockerfile > Dockerfile.tmp

# 构建 Docker 镜像
docker build -t debian$ssh_port -f Dockerfile.tmp .
if [ $? -ne 0 ]; then
  msg build_failed
  rm -f Dockerfile.tmp
  exit 1
fi

# 启动 Docker 容器
docker run --name debian$ssh_port -p $ssh_port:22 -p $tran_port_start-$tran_port_end:$tran_port_start-$tran_port_end -d --restart always --cpus 0.$cpu --memory "$ram"m debian$ssh_port

# 删除临时文件
rm -f Dockerfile.tmp

echo "SSH端口: $ssh_port 密码: $GEN_PASS 端口: $tran_port_start - $tran_port_end OS:Debian" >> output.log
