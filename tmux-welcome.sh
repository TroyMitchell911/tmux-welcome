#!/bin/bash

clear

# 创建一个临时tmux会话
tmux new-session -d -s temp_session

# 定义保存文件路径
resurrect_file="$HOME/.tmux/resurrect/last"

# 检查保存文件是否存在
if [ ! -f "$resurrect_file" ]; then
  echo "Tmux resurrect save file not found!"
  exit 1
fi

# 初始化变量
check_restored=true

# 从保存文件中提取窗口信息
saved_windows=$(grep '^window' $resurrect_file | awk '{print $2}')
# echo $saved_windows

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

# 提示用户输入会话名称
read -p "Enter the name of the new tmux session: " session_name

# 创建新的 tmux 会话 或者附加
if tmux ls 2>/dev/null | grep -q "^$session_name:"; then
  echo "Attaching to existing tmux session '$session_name'."
  tmux attach -t "$session_name"
else
  echo "No existing session found. Creating new tmux session '$session_name'."
  tmux new -s "$session_name"
fi

