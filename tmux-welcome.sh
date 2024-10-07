#!/bin/bash

clear

# 定义颜色和样式
red=$(tput setaf 1)
green=$(tput setaf 2)
blue=$(tput setaf 4)
yellow=$(tput setaf 3)
bold=$(tput bold)
reset=$(tput sgr0)
clear=$(tput clear)

# 获取终端尺寸
rows=$(tput lines)
cols=$(tput cols)

# 居中显示文本的函数
center_text() {
  local text="$1"
  local col=$(( (cols - ${#text}) / 2 ))
  echo -e "$(printf '%*s' $col '' )$text"
}

# 清屏
echo -e "$clear"

# 显示banner
banner=(
  "██╗    ██╗███████╗██╗      ██████╗ ██████╗ ███╗   ███╗███████╗    ████████╗ ██████╗     ████████╗███╗   ███╗██╗   ██╗██╗  ██╗"
  "██║    ██║██╔════╝██║     ██╔════╝██╔═══██╗████╗ ████║██╔════╝    ╚══██╔══╝██╔═══██╗    ╚══██╔══╝████╗ ████║██║   ██║╚██╗██╔╝"
  "██║ █╗ ██║█████╗  ██║     ██║     ██║   ██║██╔████╔██║█████╗         ██║   ██║   ██║       ██║   ██╔████╔██║██║   ██║ ╚███╔╝ "
  "██║███╗██║██╔══╝  ██║     ██║     ██║   ██║██║╚██╔╝██║██╔══╝         ██║   ██║   ██║       ██║   ██║╚██╔╝██║██║   ██║ ██╔██╗ "
  "╚███╔███╔╝███████╗███████╗╚██████╗╚██████╔╝██║ ╚═╝ ██║███████╗       ██║   ╚██████╔╝       ██║   ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗"
  " ╚══╝╚══╝ ╚══════╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝       ╚═╝    ╚═════╝        ╚═╝   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
)

# 居中显示banner
for line in "${banner[@]}"; do
  echo -e "$(center_text "$line")"
done

# 定义保存文件路径
resurrect_file="$HOME/.tmux/resurrect/last"

# 检查保存文件是否存在
if [ -f "$resurrect_file" ]; then
  # 创建一个临时tmux会话
  tmux new-session -d -s temp_session

  # 初始化变量
  check_restored=true

  # 从保存文件中提取窗口信息
  saved_windows=$(grep '^window' $resurrect_file | awk '{print $2}')

  # 获取当前的 tmux 会话信息
  current_sessions=$(tmux ls | awk -F: '{print $1}')

  # 检查保存的窗口是否都恢复
  for window in $saved_windows; do
    if ! echo "$current_sessions" | grep -q "^$window$"; then
      # echo "Window $window has not been restored."
      check_restored=false
    fi
  done

  # 输出恢复状态
  if [ "$check_restored" = false ]; then
    # 发送恢复命令 (prefix + Ctrl + r)
    tmux send-keys -t temp_session C-b C-r
    # 等待恢复完成 (可调整等待时间，根据恢复速度)
    sleep 2
  fi

  # 杀掉临时的会话
  tmux kill-session -t temp_session
fi

# 获取终端尺寸
cols=$(tput cols)

# 输入提示
prompt="Please enter your session-name:"

# 计算提示的长度
prompt_length=${#prompt}

# 计算提示居中后的列位置
prompt_col=$(( (cols - prompt_length) / 2 ))

# 输出提示
echo -e "$(printf '%*s' $prompt_col '')$prompt"

# 计算光标居中的列位置（与提示对齐）
cursor_col=$(( prompt_col + prompt_length / 2 ))
cursor_row=9

# 将光标移动到提示词正下方，并居中
tput cup $cursor_row $cursor_col

# 读取用户输入的字符
session_name=""
tput civis
while IFS= read -r -s -n 1 char; do
    ascii_value=$(printf "%d" "'$char")
    if [[ $char == $'\x7f' ]]; then  # 处理退格键
	       session_name="${session_name%?}"  # 删除最后一个字符
        # 用空格填充删除的位置
        session_length=${#session_name}
        session_col=$(( (cols - session_length) / 2 ))
        tput cup $cursor_row 0
        echo -e "$(printf '%*s' $session_col '')$session_name"  # 重新输出
        # 清除被删除字符后的位置
        tput cup $cursor_row $((session_col + session_length))  # 移动光标到字符串末尾
        echo -n " "  # 输出空格以清除
        tput cup $cursor_row $session_col  # 移动光标回到正确位置
    elif [[ $ascii_value == 0 ]]; then  # 处理回车键，结束输入
        break
    else
        session_name+="$char"  # 添加输入字符到变量
    fi

    session_length=${#session_name}
    # 计算提示居中后的列位置
    session_col=$(( (cols - session_length) / 2 ))
    tput cup $cursor_row 0
    echo -e "$(printf '%*s' $session_col '')$session_name"
done
 tput cnorm

# 创建新的 tmux 会话 或者附加
if tmux ls 2>/dev/null | grep -q "^$session_name:"; then
  tmux attach -t "$session_name"
else
  tmux new -s "$session_name"
fi
