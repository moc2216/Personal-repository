#!/bin/bash
echo "1、更新软件源"
sudo apt update && sudo apt upgrade -y
sudo apt install p7zip-full -y
sudo apt install htop -y
sudo apt install fontconfig

# 解决中文乱码
cd /usr/share/fonts/
sudo wget https://github.com/adobe-fonts/source-han-sans/releases/download/2.004R/SourceHanSansSC.zip
sudo 7z x SourceHanSansSC.zip
rm SourceHanSansSC.zip
sudo mv OTF/ SourceHanSans/
sudo fc-cache –fv
rm -rf ~/.cache/matplotlib

echo "2、开始安装 miniconda3..."
# 创建miniconda3存储的文件夹
mkdir -p ~/.miniconda3
# 下载 Anaconda 安装脚本，至上面刚创建的隐藏文件夹，保存为文件miniconda.sh
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/.miniconda3/miniconda.sh
#执行安装文件
bash ~/.miniconda3/miniconda.sh -b -u -p ~/.miniconda3
#安装完毕后删除miniconda.sh
rm -rf ~/.miniconda3/miniconda.sh

# 激活base环境
source ~/.miniconda3/bin/activate
# 初始化
conda init --all
# 配置channel
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main
conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r
# 验证 Anaconda 安装
conda --version

echo "3、安装pm2"
sudo apt install npm -y
sudo npm install pm2 -g -y
pm2 install pm2-logrotate
pm2 --version

# 创建Python环境
conda create -n py312pos python=3.12 -y
conda activate py312pos
python --version

# 安装谷歌
echo "安装谷歌..."
# 下载谷歌
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb -O ~/google-chrome-stable_current_amd64.deb
# 安装谷歌
sudo dpkg -i ~/google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y
# 删除安装包
rm ~/google-chrome-stable_current_amd64.deb
# 验证谷歌
google-chrome --version

echo "4、设置虚拟内存"
# 检查是否存在虚拟内存，Ubuntu 24.04.2 这个版本默认启用了 2G 的虚拟内存
if [ -f "/swap.img" ]; then
    # 停用旧的Swap
    sudo swapoff /swap.img
    # 删除原swap文件
    sudo rm /swap.img
fi
# 开始设置虚拟内存
sudo fallocate -l 10G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 启动新的交互式 shell，保持在虚拟环境中
exec $SHELL

#echo "设置默认环境为bwb"
#conda config --set auto_activate_base false
#echo "conda activate bwb" >> ~/.bashrc

#【重要提示】：设置的虚拟内存，貌似无法正常启用。若有问题需要重新设置内存。