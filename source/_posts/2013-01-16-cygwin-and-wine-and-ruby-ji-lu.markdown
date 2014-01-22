---
layout: post
title: "Cygwin & Wine & Ruby 记录"
date: 2013-01-16 16:03:36 +0800
comments: true
categories: linux
keywords: linux octopress Cygwin Wine Ruby
tags: linux octopress cygwin wine ruby
description: linux octopress cygwin wine ruby
---
cygwin是一个在windows平台上运行的unix模拟环境, wine则可以安装在Linux，再对应到Windows相应的函数来调用DLL以运行Windows程序。这两个就是利器，windows下不想用虚拟机（占用资源还挺多）或双系统，就可以用用cygwin；服务器上想搞点exe的东西就安装个wine。至于ruby，是因为octopress要用，开个虚拟机写博客很不爽，windows下折腾安装配置，却中文编码没解决，还是cygwin搞定。<!--more-->
cygwin的安装
----
官网下载setup-x86_64.exe，运行，下一步，到download site选第一个163的镜像，速度快些；下一步到select packages页面，不选不点，直接下一步，会下载安装默认配置的相关包；安装完默认，重新运行setup，选择要用的包，比如下面这些基本需要：
[摘录自blog.developwithpassion.com](http://blog.developwithpassion.com/2012/03/30/installing-rvm-with-cygwin-on-windows/)  
```
Archive  
    unzip – Unzipping zip files  
Net  
    openssl – bin and sources
    openssh – Only if you are not going to compile openssh yourself
    curl – download internet resources
Devl
    colorgcc
    gcc
    gcc-core – compiler
    git
    git-completion
    git-gui
    git-svn
    gitk
    libtool – Shared library generation tool. You’ll need it when trying to compile rubies
    libncurses-devel – Used when compiling several other tools I use
    make
    mercurial
    openssl-devel – Required for compiling openssh (not necessarily required for rvm, but I always install it to compile openssh myself)
    readline
    Libs
    zlib
    zlib-devel
Utils
    ncurses – Enabling better handling of terminal
    patch – Apply a diff file to an original.
```
wine的安装，centos6.x
----
```
wget http://mirrors.sohu.com/fedora-epel/6/i386/epel-release-6-8.noarch.rpm
rpm -ivh epel-release-6-8.noarch.rpm
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
yum makecache
yum install wine
```
安装完成后，应用程序（application）->wine->wine configure稍作配置，也可能会提示download gecko，install 完成即可
把windows/system32下的MFC42.dll   msxml.dll    msvcp60.dll   riched20.dll    riched32.dll 这几个文件复制到 ~/.wine/drive_c/windows/system32里，再输入命令：winecfg  
安装exe，英文系统会有中文乱码情况
```
wine whatever.exe
```
安装Ruby
----
我虚拟了两个centos，一个用make install安装并配置octopress环境，另一个同样方法却不成功，后来用rvm可行，不用yum install ruby 是因为版本过低。
####RVM安装：  
```
curl -L https://get.rvm.io | bash -s stable --ruby
```
```
ruby --version
```显示版本即成功
####make install：  
```
wget ftp://ftp.ruby-lang.org//pub/ruby/2.1/ruby-2.1.0.tar.gz
tar -zxvf ruby-2.1.0.tar.gz
cd ruby-2.1.0
./configure --prefix=/usr/local/ruby
make
make test
make install  
```
####windows7下简直是个悲剧：  
下载rubyinstaller安装，devkit解压，然后cmd下
cdd到DevKit path  
```
ruby dk.rb init
ruby dk.rb review
ruby dk.rb install
```
出现utf-8错误，使用chcp 1252，再进行上三句，done  
然后配置octopress环境，英文下rake成功，有中文（比如文章分类、标签带中文的）不成;  
[摘录自txgcwm.github.io](http://txgcwm.github.io/)
>在实际使用（rake generate/rake preview）的时候，若blog整体采用了非ascii码的编码格式（比如utf-8）就会出现类似这样的错误：  
>Liquid error: incompatible encoding regexp match (ascii-8bit regexp with utf-8 string)  
>其实是由于插件文件plugins/category_list_tag.rb本身是ascii编码所致:
```
$ chardet category_list_tag.rb
category_list_tag.rb: ascii (confidence: 1.00)
```
category_list_tag.rb中很多地方用到了ruby的正则表达式，而ruby的正则表达式在匹配的时候，默认是按照“代码源文件”的编码格式(在这里是ascii)进行匹配的，而如果blog是utf-8编码的话就会出现上述错误。有两种解决办法：
1. 将category_list_tag.rb转成utf-8格式。  
2. 更改category_list_tag.rb中所有的正则表达式声明，加上u选项（u的意思就是以utf-8编码格式来进行匹配）。例如，若原正则表达式是/regexp/, 则改成/regexp/u。
