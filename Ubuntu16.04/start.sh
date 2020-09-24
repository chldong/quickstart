#!/bin/bash
set -e
log=chl.log
ip=`/sbin/ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"`

#判断当前用户是否为Root用户
if [ `whoami` != "root" ];then
 clear
 echo 
 echo "注意：当前不是Root用户，请使用Root用户操作"
 echo "请使用 sudo -i 登录root用户"
 echo
 exit 0
else
 echo 
 clear
fi

ssh-root(){
#开启root用户ssh登录
echo "开启root用户远程登录" >> $log
echo "正在开启root用户远程登录"
echo
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
/etc/init.d/ssh restart >> $log
}

host-name(){
#设置主机名
read  -p "请输入需要设置的主机名:" name
hostnamectl set-hostname $name
echo
echo 主机名修改成功，当前主机名为：`hostname`
echo
}

apt-aliyun(){
#修改apt源为阿里云apt源
echo "正在修改apt源为阿里云apt源"
echo "修改apt源为阿里云apt源" >> $log
mv /etc/apt/sources.list /etc/apt/sources.list.bak
echo "deb http://mirrors.aliyun.com/ubuntu/ xenial main" >> /etc/apt/sources.list
echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial main" >> /etc/apt/sources.list
echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main" >> /etc/apt/sources.list
echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates main" >> /etc/apt/sources.list
echo "deb http://mirrors.aliyun.com/ubuntu/ xenial universe" >> /etc/apt/sources.list
echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial universe" >> /etc/apt/sources.list
echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-updates universe" >> /etc/apt/sources.list
echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-updates universe" >> /etc/apt/sources.list
echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-security main" >> /etc/apt/sources.list
echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security main" >> /etc/apt/sources.list
echo "deb http://mirrors.aliyun.com/ubuntu/ xenial-security universe" >> /etc/apt/sources.list
echo "deb-src http://mirrors.aliyun.com/ubuntu/ xenial-security universe" >> /etc/apt/sources.list
apt-get update >> $log
echo
}

apt-get-install(){
#安装常用软件
echo "正在安装unzip wget curl git"
echo "安装常用软件" >> $log
apt-get install -y unzip wget curl git >> $log
echo
}

nfs-server-install(){
#安装nfs-server
echo "正在安装nfs-server"
echo "安装nfs-server" >> $log
apt-get install -y nfs-server >> $log
systemctl enable nfs-kernel-server >> $log
systemctl restart  nfs-kernel-server >> $log
cp /etc/exports /etc/exports.bak
echo
read  -p "请输入需要设置nfs的目录(注意：如果目录存在此操作会删除您输入目录中的数据):" nfsname
rm -rf "/"$nfsname >> $log
mkdir "/"$nfsname >> $log
chmod 777 "/"$nfsname  
echo  "/"$nfsname "*(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports
exportfs -a >> $log
systemctl restart  nfs-kernel-server >> $log 
showmount -e 127.0.0.1
echo
}

nfs-common-install(){
#安装nfs-客户端
echo "正在安装nfs客户端"
echo "安装nfs客户端" >> $log
apt-get install -y nfs-common >> $log
echo
}

jdk8-install(){
#安装jdk8
echo "正在安装jdk8"
echo "安装jdk8" >> $log
apt-get install -y openjdk-8-jdk-headless  >> $log
echo
}

docker-install(){
echo "正在安装docker-版本:19.03.6"
echo "正在安装docker-版本:19.03.6" >> $log
apt-get install -y apt-transport-https ca-certificates curl software-properties-common >> $log
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add - >> $log
sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" >> $log
apt-get update >> $log
apt-cache madison docker-ce >> $log
apt-get install -y  docker-ce=5:19.03.6~3-0~ubuntu-xenial >> $log
systemctl enable docker >> $log
systemctl restart docker
cp docker-compose /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
echo
echo
docker info | grep "Server Version"
docker-compose  -version
echo
}

master(){
rm -rf ./chl.log
host-name
ssh-root
apt-aliyun
apt-get-install
nfs-server-install
nfs-common-install
jdk8-install
docker-install
echo "安装完成"
}

node(){
rm -rf ./chl.log
host-name
ssh-root
apt-aliyun
apt-get-install
nfs-common-install
jdk8-install
docker-install
echo "安装完成"
}

nodocker(){
rm -rf ./chl.log
host-name
ssh-root
apt-aliyun
apt-get-install
echo "安装完成"
}

#Shell菜单
function menu ()
{
 cat << EOF
----------------------------------------
|*************系统初始化脚本**************|
----------------------------------------
当前IP地址：
$ip
----------------------------------------
`echo -e "\033[35m 1)中心节点环境安装\033[0m"`
`echo -e "\033[35m 2)边缘节点环境安装\033[0m"`
`echo -e "\033[35m 2)非容器化交付安装\033[0m"`
`echo -e "\033[35m 3)退出\033[0m"`
EOF
read -p "请输入对应产品的数字：" num1
case $num1 in
 1)
  master
  ;;
 2)
  node
  ;;
 3)
  nodocker
  ;;
 4)
  exit 0
esac
}
menu
