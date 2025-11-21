#!/bin/bash

clear
echo "#########################################################"
echo -e "#        帮你一键批量生出Docker NAT小鸡(Debian)          #"
echo -e "#                   Modified By 51HzOuO                 #"
echo "#########################################################"

# 语言选择
echo "Language selection: Chinese(default):0, English:1"
read -p "Enter choice (0 or 1): " LANG
if [ -z "$LANG" ] || [ "$LANG" != "1" ]; then
  LANG=0
fi

# 消息函数
msg() {
  if [ "$LANG" = "1" ]; then
    case "$1" in
      count_prompt) echo "How many chickens do you want to create: " ;;
      ssh_port_prompt) echo "Enter the SSH port for the first chicken: " ;;
      port_num_prompt) echo "Enter the number of forwarding ports per chicken: " ;;
      cpu_prompt) echo "CPU percentage per chicken (1-100) (default 50%): " ;;
      ram_prompt) echo "Memory MB per chicken (default 256M): " ;;
      empty_input) echo "Input cannot be empty, please re-enter." ;;
      invalid_number) echo "Please enter a valid number." ;;
      cpu_range) echo "CPU percentage must be between 0-100." ;;
      default_cpu) echo "Using default CPU: $2%" ;;
      default_ram) echo "Using default memory: 256M" ;;
      creating_container) echo "Creating Debian$2 container, forwarding ports: $3-$4" ;;
      batch_complete) echo "Batch creation of Docker chickens completed." ;;
      checking_conflicts) echo "Checking port conflicts..." ;;
      ssh_occupied) echo "SSH port $2 is occupied." ;;
      port_occupied) echo "Forwarding port $2 is occupied." ;;
      no_conflicts) echo "Port check completed, no conflicts." ;;
    esac
  else
    case "$1" in
      count_prompt) echo "告诉我你想生多少只小鸡: " ;;
      ssh_port_prompt) echo "请输入第一只小鸡的SSH端口号: " ;;
      port_num_prompt) echo "请输入每只小鸡需要转发的端口数: " ;;
      cpu_prompt) echo "每只小鸡占用CPU百分比(1-100)(默认50%): " ;;
      ram_prompt) echo "每只小鸡内存MB(默认256M): " ;;
      empty_input) echo "输入不能为空，请重新输入。" ;;
      invalid_number) echo "请输入有效的数字。" ;;
      cpu_range) echo "CPU百分值必须在0-100之间。" ;;
      default_cpu) echo "使用默认CPU: $2%" ;;
      default_ram) echo "使用默认内存: 256M" ;;
      creating_container) echo "正在创建Debian$2容器，转发端口：$3-$4" ;;
      batch_complete) echo "批量创建Docker小鸡已完成。" ;;
      checking_conflicts) echo "检测端口冲突..." ;;
      ssh_occupied) echo "SSH端口 $2 已被占用。" ;;
      port_occupied) echo "转发端口 $2 已被占用。" ;;
      no_conflicts) echo "端口检测完成，无冲突。" ;;
    esac
  fi
}

# 输入配置
while true; do
  count_prompt=$(msg count_prompt)
  read -e -p "$count_prompt" count
  if [ -z "$count" ]; then
    msg empty_input
    continue
  fi
  if ! [[ "$count" =~ ^[0-9]+$ ]]; then
    msg invalid_number
    continue
  fi
  break
done

while true; do
  ssh_port_prompt=$(msg ssh_port_prompt)
  read -e -p "$ssh_port_prompt" ssh_port
  if [ -z "$ssh_port" ]; then
    msg empty_input
    continue
  fi
  if ! [[ "$ssh_port" =~ ^[0-9]+$ ]]; then
    msg invalid_number
    continue
  fi
  break
done

while true; do
  port_num_prompt=$(msg port_num_prompt)
  read -e -p "$port_num_prompt" port_num
  if [ -z "$port_num" ]; then
    msg empty_input
    continue
  fi
  if ! [[ "$port_num" =~ ^[0-9]+$ ]]; then
    msg invalid_number
    continue
  fi
  break
done

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

# 检查端口冲突
msg checking_conflicts
conflict=false
current_ssh=$ssh_port
for i in `seq 1 $count`; do
  # 检查SSH端口
  if netstat -tuln 2>/dev/null | grep -q ":$current_ssh "; then
    msg ssh_occupied "$current_ssh"
    conflict=true
    break
  fi
  # 检查转发端口
  nat_start=$((current_ssh + 1))
  nat_end=$((nat_start + port_num - 1))
  for port in $(seq $nat_start $nat_end); do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
      msg port_occupied "$port"
      conflict=true
      break
    fi
  done
  if $conflict; then
    break
  fi
  current_ssh=$((nat_end + 1))
done

if $conflict; then
  echo "Port conflicts detected, please re-run the script with different ports."
  exit 1
fi

msg no_conflicts

for i in `seq 1 $count`
do
  # 计算端口范围
  nat_start=$((ssh_port + 1))
  nat_end=$((nat_start + port_num - 1))

  msg creating_container "$ssh_port" "$nat_start" "$nat_end"

  ./Create.sh $ssh_port $nat_start $nat_end $cpu $ram

  # 递增下一个容器的 SSH 端口
  ssh_port=$((nat_end + 1))
done

msg batch_complete
