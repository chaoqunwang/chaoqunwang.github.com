---
layout: post
title: "本地搭建SVN服务器及配置"
date: 2008-10-22 20:50:35 -0800
comments: true
categories: tech web
keywords: svn 版本控制 服务器配置
tags: svn
description: svn 版本控制 服务器配置
---
####1. 创建SVN数据库  

```
svnadmin create D:\svn
```
说明：
 repository创建完毕后会在目录下生成若干个文件和文件夹，
 dav目录是提供给Apache与mod_dav_svn使用的目录，让它们存储内部数据；
 db目录就是所有版本控制的数据文件；
 hooks目录放置hook脚本文件的目录；
 locks用来放置Subversion文件库锁定数据的目录，用来追踪存取文件库的客户端；
 format文件是一个文本文件，里面只放了一个整数，表示当前文件库配置的版本号；<!--more-->

####2. 创建服务  

```
sc create svnservice binpath= "D:\Subversion\bin\svnserve.exe --service -r D:\svn" displayname= "SVNService" depend= Tcpip
```

####3. 删除服务  

```
sc delete svnservice
```  

####4. 启动服务/停止服务  

```
net start svnservice
```
```
net stop svnservice
```
也可以在运行里输入 services.msc 找到名称为“svnservice”的服务 手动启动或停止  

####5. 导入工程  

```
svn import E:\workspace\myproject\ svn://localhost/svn -m "initial import" --username admin --password mypassword
```  

####6. 导出工程  

```
svn co svn://localhost/server --username admin --password mypassword
```




