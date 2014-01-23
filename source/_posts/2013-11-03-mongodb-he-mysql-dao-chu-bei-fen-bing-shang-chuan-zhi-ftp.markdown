---
layout: post
title: "mongodb, mysql导出备份至ftp"
date: 2013-11-03 17:10:32 +0800
comments: true
categories: linux mongodb mysql vsftp
keywords: linux mongodb mysql vsftp 导出 备份 上传
tags: linux mongodb mysql vsftp
description: linux mongodb mysql vsftp 导出 备份 上传
---
前提是mongodb和mysql已经安装使用，先安装vsftp，配置完成后，在编写shell脚本，使用计划任务执行  
1. 安装vsftp  
```
rpm -q vsftpd
yum -y install vsftpd
```
<!--more-->
设置开机启动  
```
chkconfig vsftpd on
```
启动vsftpd服务   
```
service vsftpd start
```
增加新用户ftpuser，设置权限和密码  
```
useradd -d /home/ftpuser -s /sbin/nologin ftpuser
chown -R ftpuser /home/ftpuser
chmod 777 -R /home/ftpuser
passwd ftpuser
```
配置vsftp
```
vi /etc/vsftpd/vsftpd.conf
```
内容删掉换成以下
```
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
chroot_list_enable=YES
chroot_list_file=/etc/vsftpd/chroot_list
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
pasv_min_port=10000 
pasv_max_port=10030
```
添加chroot_list文件
```
vi /etc/vsftpd/chroot_list
```
内容```ftpuser```  
重启服务```service vsftpd restart```  
防火墙开放21端口
```
service iptables stop
vi /etc/sysconfig/iptables
```
添加
```
-A INPUT -m state --state NEW -m tcp -p tcp --dport 21 -j ACCEPT
```  
重启防火墙服务
```
service iptables start
```  
解决用户无法进入目录问题，终端执行：  
```
setsebool -P ftp_home_dir 1
```  
然后重启FTP服务：
```
service vsftpd restart
```
2. mongodb导出、压缩、上传脚本，删除过期文件  
----
先定义好服务器、数据库、各目录、用户名、密码  

```  
#!/bin/bash
MONGO_HOST="127.0.0.1:27017"
MONGO_DB="mydbname"
MONGO_DUMP="/usr/local/mongo/bin/mongodump"
MONGO_BACKUP="/usr/local/mongo/backup"
NEW_TIMESTAMP=$(date +%F-%H%M)
OLD_TIMESTAMP=$(date -d '-5 days' "+%F-%H%M")
NEW_BACKUP_FILE="$MONGO_DB.$NEW_TIMESTAMP.tar.gz"
OLD_BACKUP_FILE="$MONGO_DB.$OLD_TIMESTAMP.tar.gz"

# 0.temp dir
if [ ! -d $MONGO_BACKUP/$MONGO_DB.$NEW_TIMESTAMP ]
then
 mkdir $MONGO_BACKUP/$MONGO_DB.$NEW_TIMESTAMP
fi

# 1.mongodump then delete old dir and file
$MONGO_DUMP -h $MONGO_HOST -d $MONGO_DB -o $MONGO_BACKUP/$MONGO_DB.$NEW_TIMESTAMP
cd $MONGO_BACKUP/$MONGO_DB.$NEW_TIMESTAMP && tar -zcf $MONGO_BACKUP/$NEW_BACKUP_FILE */
rm -rf $MONGO_BACKUP/$MONGO_DB.$NEW_TIMESTAMP
rm -rf $MONGO_BACKUP/$OLD_BACKUP_FILE

# 2.upload new and delte old files
#!/bin/sh
FTP_HOST="192.168.100.119"
FTP_PORT="21"
FTP_USER="ftpuser"
FTP_PSWD="123456"
FTP_DIR="mongo-backup"

ftp -nv <<!
open $FTP_HOST $FTP_PORT
user $FTP_USER $FTP_PSWD
binary
prompt
cd $FTP_DIR
mdelete $OLD_BACKUP_FILE
lcd $MONGO_BACKUP
mput $NEW_BACKUP_FILE
close
bye
!
echo "============== $MONGO_DB backup ends at $NEW_TIMESTAMP =============="
```  

3. mysql导出、压缩、上传脚本  
----
```
#! /bin/bash
MYSQL_HOST="192.168.100.119"
MYSQL_PORT='3306'
MYSQL_USER='myuser'
MYSQL_PSWD='mypass'
MYSQL_DB='mydbname'
MYSQL_DUMP="/usr/bin/mysqldump"
MYSQL_BACKUP="/usr/local/mysql/backup"
NEW_TIMESTAMP=$(date +%F-%H%M)
OLD_TIMESTAMP=$(date -d '-5 days' "+%F-%H%M")
GZIP="$(which gzip)"

# 1.mysql dump and delete old files
$MYSQL_DUMP -h $MYSQL_HOST -P $MYSQL_PORT -u $MYSQL_USER -p$MYSQL_PSWD $MYSQL_DB | $GZIP -9 > $MYSQL_BACKUP/$MYSQL_DB.$NEW_TIMESTAMP.gz
rm -rf $MYSQL_BACKUP/$MYSQL_DB.$OLD_TIMESTAMP.gz
echo "============== mysqldump ends at $NEW_TIMESTAMP =============="

# 2.upload new and delete old files
FTP_HOST="192.168.100.119"
FTP_PORT="21"
FTP_USER="ftpuser"
FTP_PSWD="123456"
FTP_DIR="mysql-backup"

ftp -nv <<!
open $FTP_HOST $FTP_PORT
user $FTP_USER $FTP_PSWD
binary
prompt
cd $FTP_DIR
lcd $MYSQL_BACKUP
mput $MYSQL_DB.$NEW_TIMESTAMP.gz
mdelete $MYSQL_DB.$OLD_TIMESTAMP.gz
close
bye
!
echo "============== mysql upload ends at $NEW_TIMESTAMP =============="
```
