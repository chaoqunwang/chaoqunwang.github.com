---
layout: post
title: "安装git, 建立Octopress博客"
date: 2013-01-06 22:34:24 -0800
comments: true
categories: 
keywords: 
description: 
---
*本文是在参考若干网络日志（谢过~）,配置个人博客后整理而成*
安装git  
----
```sh  
yum -y install git
git --version
```  
<!--more-->
在本机使用git创建SSH Key  
```  
ssh-keygen -C "username" -t rsa  
ssh -v git@github.com  
```  
//if denied, use ``` ssh-add ~/.ssh/id_rsa ``` to fix this.  
备注: useremail为你注册github用户时的邮箱地址 这时，在系统目录下就会生成一个.ssh文件夹，里面为对应的SSH Key，其中id_rsa.pub是Gighub需要的SSH公钥文件。 将id_ras.pub文件里内容拷贝到Github的Account Settings里的key中。 这样你就可以直接使用Git和Github了.

安装ruby  
----
```  
wget ftp://ftp.ruby-lang.org//pub/ruby/2.1/ruby-2.1.0.tar.gz  
tar -zxvf ruby-2.1.0.tar.gz
cd ruby-2.1.0
./configure --prefix=/usr/local/ruby
make
make test
make install
```
安装OctoPress  
----  
通过Git从Github上克隆一份Octopress  
```  
git clone git://github.com/imathis/octopress.git octopress
cd octopress  
gem install bundler  
bundle install  
```
安装Octopress默认的Theme
```  
rake install  
```  
//if error: rake aborted!  
//You have already activated rake 10.1.0, but your Gemfile requires rake 0.9.2.2. 
delete your Gemfile.lock and edit the version of rake specified in your Gemfile to 10.1. Job done  
  
通过_config.yml来配置博客  
----

##创建一个博客 
```  
rake new_post["Hello World"]
```
##创建一个博客页面 
```  
rake new_page["blog"]
```

预览效果：  
```  
rake generate  
rake preview  
```  

然后在浏览器中打开http://localhost:4000

发布Octopress到Github
----
```
cd octopress  
rake setup_github_pages  
Repository url: git@github.com:username/username.github.com.git  
```
将博客发布到Github上，输入下面命令：
```  
rake deploy  
```
这样，生成的内容将会自动发布到master分支，并且可以使用 http://username.github.com 访问内容。


将source提交：  
```   
git add .  
git commit -m "blog init"  
git push origin source  
```
删除之前的添加信息 (配置文件在 ~/octopress/.git/config)
```  
git remote rm origin  
git remote add origin git@github.com:username/username.github.com.git  
```
添加多说评论  
----  
在_config.yml尾部添加如下行：  
```
# Duoshuo Comments  
duoshuo_show_comment_count: true  
```

在source/_layouts/post.html尾部添加如下代码：  
```sh  
{% if site.duoshuo_show_comment_count==true and page.comments==true %}
<section id="comment">
<h1>发表评论</h1>
{% include post/duoshuo.html %}
</section>
{% endif %}  
```  

创建source/_includes/post/duoshuo.html文件，将从多说获得的代码放入其中。  
```
<!-- Duoshuo Comment BEGIN -->
    <div class="ds-thread"></div>
<script type="text/javascript">
var duoshuoQuery = {short_name:"username"};
	(function() {
		var ds = document.createElement('script');
		ds.type = 'text/javascript';ds.async = true;
		ds.src = 'http://static.duoshuo.com/embed.js';
		ds.charset = 'UTF-8';
		(document.getElementsByTagName('head')[0] 
		|| document.getElementsByTagName('body')[0]).appendChild(ds);
	})();
	</script>
<!-- Duoshuo Comment END -->
```

Octopress写作
----  
```  
cd octopress  
rake new_post["new blog"]  
```

