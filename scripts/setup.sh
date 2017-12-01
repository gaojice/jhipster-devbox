#!/bin/sh
set -ex
# update the system
sed -i "s|archive.ubuntu|mirrors.aliyun|g" /etc/apt/sources.list
sed -i "/^.*security/d" /etc/apt/sources.list

apt-get update
apt-get -y upgrade

################################################################################
# Install the mandatory tools
################################################################################

export LANGUAGE='zh_CN.UTF-8'
export LANG='zh_CN.UTF-8'
export LC_ALL='zh_CN.UTF-8'
locale-gen zh_CN.UTF-8
##dpkg-reconfigure locales

# install utilities
apt-get -y install vim git zip bzip2 fontconfig curl language-pack-zh-hans

# install Java 8
apt-get -y install openjdk-8-jdk

# install node.js

##su -c "curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.6/install.sh | bash" ubuntu

##su -c 'source ~/.bashrc && nvm install 6.9' ubuntu

apt-get install -y unzip python g++ build-essential


# install yarn
#npm install -g yarn
#su -c "yarn config set prefix /home/ubuntu/.yarn-global" ubuntu



################################################################################
# Install the graphical environment
################################################################################

# force encoding
echo 'LANG=zh_CN.UTF-8' >> /etc/environment
echo 'LANGUAGE=zh_CN.UTF-8' >> /etc/environment
echo 'LC_ALL=zh_CN.UTF-8' >> /etc/environment
echo 'LC_CTYPE=zh_CN.UTF-8' >> /etc/environment

# run GUI as non-privileged user
echo 'allowed_users=anybody' > /etc/X11/Xwrapper.config

# install Ubuntu desktop and VirtualBox guest tools
apt-get install -y xubuntu-desktop virtualbox-guest-dkms virtualbox-guest-utils virtualbox-guest-x11

# remove light-locker (see https://github.com/jhipster/jhipster-devbox/issues/54)
apt-get remove -y light-locker --purge


################################################################################
# Install the development tools
################################################################################

# install Ubuntu Make - see https://wiki.ubuntu.com/ubuntu-make

add-apt-repository -y ppa:ubuntu-desktop/ubuntu-make

apt-get update
apt-get -y upgrade

apt install -y ubuntu-make

# install Chromium Browser
apt-get install -y chromium-browser

# install MySQL Workbench
apt-get install -y mysql-workbench

# install Guake
apt-get install -y guake
cp /usr/share/applications/guake.desktop /etc/xdg/autostart/


# install zsh
apt-get install -y zsh

# install oh-my-zsh
git clone git://github.com/robbyrussell/oh-my-zsh.git /home/ubuntu/.oh-my-zsh
cp /home/ubuntu/.oh-my-zsh/templates/zshrc.zsh-template /home/ubuntu/.zshrc
chsh -s /bin/zsh ubuntu
echo 'SHELL=/bin/zsh' >> /etc/environment

# install jhipster-oh-my-zsh-plugin
git clone https://github.com/jhipster/jhipster-oh-my-zsh-plugin.git /home/ubuntu/.oh-my-zsh/custom/plugins/jhipster
sed -i -e "s/plugins=(git)/plugins=(git docker docker-compose jhipster)/g" /home/ubuntu/.zshrc
echo 'export PATH="$PATH:/usr/bin:/home/ubuntu/.yarn-global/bin:/home/ubuntu/.yarn/bin:/home/ubuntu/.config/yarn/global/node_modules/.bin"' >> /home/ubuntu/.zshrc

# change user to ubuntu
chown -R ubuntu:ubuntu /home/ubuntu/.zshrc /home/ubuntu/.oh-my-zsh

# install Visual Studio Code
su -c 'umake ide visual-studio-code /home/ubuntu/.local/share/umake/ide/visual-studio-code --accept-license' ubuntu

# fix links (see https://github.com/ubuntu/ubuntu-make/issues/343)
sed -i -e 's/visual-studio-code\/code/visual-studio-code\/bin\/code/' /home/ubuntu/.local/share/applications/visual-studio-code.desktop

# disable GPU (see https://code.visualstudio.com/docs/supporting/faq#_vs-code-main-window-is-blank)
sed -i -e 's/"$CLI" "$@"/"$CLI" "--disable-gpu" "$@"/' /home/ubuntu/.local/share/umake/ide/visual-studio-code/bin/code

#install IDEA community edition
#su -c 'umake ide idea /home/ubuntu/.local/share/umake/ide/idea' ubuntu

# increase Inotify limit (see https://confluence.jetbrains.com/display/IDEADEV/Inotify+Watches+Limit)
echo "fs.inotify.max_user_watches = 524288" > /etc/sysctl.d/60-inotify.conf
sysctl -p --system

# install latest Docker
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
# Step 3: 写入软件源信息
sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
# Step 4: 更新并安装 Docker-CE
sudo apt-get -y update
sudo apt-get -y install docker-ce
mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
"registry-mirrors": ["https://k3hybo1a.mirror.aliyuncs.com"]
}
EOF
systemctl daemon-reload
systemctl restart docker

# install latest docker-compose
curl -L "$(curl -s https://api.github.com/repos/docker/compose/releases | grep browser_download_url | head -n 4 | grep Linux | cut -d '"' -f 4)" > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# configure docker group (docker commands can be launched without sudo)
usermod -aG docker ubuntu

# fix ownership of home
chown -R ubuntu:ubuntu /home/ubuntu/

# ----------------------------------------------------------------
# Install Golang
# ----------------------------------------------------------------
GO_VER=1.7.5
GO_URL=https://storage.googleapis.com/golang/go${GO_VER}.linux-amd64.tar.gz

# Set Go environment variables needed by other scripts
export GOPATH="/opt/gopath"
export GOROOT="/opt/go"
PATH=$GOROOT/bin:$GOPATH/bin:$PATH

cat <<EOF >/etc/profile.d/goroot.sh
export GOROOT=$GOROOT
export GOPATH=$GOPATH
export PATH=\$PATH:$GOROOT/bin:$GOPATH/bin
EOF

mkdir -p $GOROOT
mkdir -p $GOPATH

curl -sL $GO_URL | (cd $GOROOT && tar --strip-components 1 -xz)
chown -R ubuntu:ubuntu $GOPATH

# clean the box
apt-get -y autoclean
apt-get -y clean
apt-get -y autoremove
dd if=/dev/zero of=/EMPTY bs=1M > /dev/null 2>&1
rm -f /EMPTY
