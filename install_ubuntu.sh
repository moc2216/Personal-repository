#!/bin/bash
# ============================================================
# Ubuntu 服务器初始化脚本
#
# 已确认的选择：
#   1) 保留 apt 全量升级
#   2) conda：接受 ToS（新版必需）+ profile.d 激活 + ~/.bashrc 自动进入 py312pos
#   3) Python：python=3.12（任意补丁版），不预装 pip 包（底部留可选块）
#   4) pm2：普通用户运行 + pm2-logrotate 上限 5M
#   5) Chrome：dpkg 两次；字体安装
#   6) swap：4G，幂等（清理旧 /swap.img 与 /swapfile，fstab 先去重再写）
#   7) 保留 set -e；结尾不 exec $SHELL，靠 ~/.bashrc 生效
#
# 用法：bash install_ubuntu_server.sh   （用普通用户执行，需要 sudo 权限）
# ============================================================
set -e

export DEBIAN_FRONTEND=noninteractive

# 往文件追加一行，已存在则跳过（可重复执行）
add_line() {
  local line="$1" file="$2"
  touch "$file"
  grep -qxF "$line" "$file" || echo "$line" >> "$file"
}

echo "1、更新软件源"
sudo apt update
sudo apt upgrade -y
sudo apt install -y p7zip-full htop fontconfig

echo "2、安装中文字体（Source Han Sans SC）"
cd /usr/share/fonts/
sudo wget -q https://github.com/adobe-fonts/source-han-sans/releases/download/2.004R/SourceHanSansSC.zip -O SourceHanSansSC.zip
sudo 7z x -y SourceHanSansSC.zip > /dev/null
sudo rm -f SourceHanSansSC.zip
sudo rm -rf SourceHanSans
sudo mv OTF/ SourceHanSans/
sudo fc-cache -fv
rm -rf ~/.cache/matplotlib

echo "3、安装 Miniconda3 ..."
mkdir -p ~/.miniconda3
wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/.miniconda3/miniconda.sh
bash ~/.miniconda3/miniconda.sh -b -u -p ~/.miniconda3
rm -rf ~/.miniconda3/miniconda.sh

# 激活并写入 ~/.bashrc（不用 conda init --all，不改其他 shell 配置）
source ~/.miniconda3/etc/profile.d/conda.sh
add_line '. ~/.miniconda3/etc/profile.d/conda.sh' ~/.bashrc

# 新版 conda 必须先接受 ToS，否则 conda create 会失败
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
conda --version

echo "4、创建 Python 环境 py312pos ..."
conda create -n py312pos python=3.12 -y
conda activate py312pos
python --version
add_line 'conda activate py312pos' ~/.bashrc

# 可选：delist 相关依赖（本地版原本会装，本次按选择默认不装）
# pip install xbx-py11 pycryptodome

echo "5、安装 pm2（普通用户运行）..."
sudo apt install -y npm
sudo npm install -g pm2

# pm2 以普通用户身份运行；若本脚本用 sudo 执行，则切换到 SUDO_USER
PM2_USER="${SUDO_USER:-$(id -un)}"
if [ "$PM2_USER" = "root" ]; then
  echo "警告：没有非 root 用户可用，pm2 将以 root 运行，Chrome 需加 --no-sandbox。"
fi
as_pm2_user() {
  if [ "$(id -un)" = "$PM2_USER" ]; then
    "$@"
  else
    sudo -u "$PM2_USER" -H "$@"
  fi
}
as_pm2_user pm2 --version
as_pm2_user pm2 update || echo "（无旧 daemon，跳过 pm2 update）"
as_pm2_user pm2 install pm2-logrotate
as_pm2_user pm2 set pm2-logrotate:max_size 5M

# 开机自启（可重复执行）
sudo env "PATH=$PATH" pm2 startup systemd -u "$PM2_USER" --hp "$(eval echo "~$PM2_USER")" > /dev/null
as_pm2_user pm2 save

echo "6、安装 Chrome ..."
wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O ~/google-chrome-stable_current_amd64.deb
sudo dpkg -i ~/google-chrome-stable_current_amd64.deb || sudo apt --fix-broken install -y
sudo dpkg -i ~/google-chrome-stable_current_amd64.deb
google-chrome --version
rm -f ~/google-chrome-stable_current_amd64.deb

echo "7、设置 4G 虚拟内存 ..."
current_swaps() {
  if swapon --show=NAME --noheadings > /dev/null 2>&1; then
    swapon --show=NAME --noheadings
  else
    awk 'NR>1 {print $1}' /proc/swaps
  fi
}
for f in /swap.img /swapfile; do
  if current_swaps | grep -qx "$f"; then
    sudo swapoff "$f"
  fi
  if [ -e "$f" ]; then
    sudo rm -f "$f"
  fi
done
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# fstab 去重：先备份，再删掉旧的 /swapfile、/swap.img 行，最后写一行
sudo cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d%H%M%S)"
sudo sed -i -E '/\/swap(file|\.img)[[:space:]]/d' /etc/fstab
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
sudo swapon --show

echo "8、收尾"
sudo apt clean

echo "完成。新开终端或执行：source ~/.bashrc"
