---
layout: post
title: "安装git, 建立Octopress博客"
date: 2013-01-06 22:34:24 -0800
comments: true
categories: tech 其他
keywords: github git octopress ruby blog 博客 中文分类
tags: github git octopress ruby
description: github git octopress ruby blog 博客 中文分类
---
本文参考了若干网络日志（谢过~）, 配置个人博客后整理而成  
安装git  
----
```  
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
wget ftp://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.0.tar.gz  
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
```  
{% if site.duoshuo_show_comment_count==true and page.comments==true %}
<section id="comment">
<h1>发表评论</h1>
{% include post/duoshuo.html %}
</section>
{% endif %}  
```  

创建source/_includes/post/duoshuo.html文件，将从多说获得的代码放入其中。 
标签：[技术](/blog/categories/tech)   
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
将AddThis更换为JiaThis
----
打开source/_includes/post/sharing.html，注释掉```<div class="share">...</div>```中的AddThis相关语句,然后在```</div>```前加入从JiaThis获得的代码。

Octopress写作
----  
```  
cd octopress  
rake new_post["new blog"]  
```  
another pc
----  
```  
git clone -b source git@github.com:username/username.github.com.git octopress  
cd octopress  
git clone git@github.com:username/username.github.com.git _deploy  
```
增加category_list插件
----
保存以下代码到plugins/category_list_tag.rb：
```
module Jekyll
  class CategoryListTag < Liquid::Tag
    def render(context)
      html = ""
      categories = context.registers[:site].categories.keys
      categories.sort.each do |category|
        posts_in_category = context.registers[:site].categories[category].size
        category_dir = context.registers[:site].config['category_dir']
        category_url = File.join(category_dir, category.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase)
        html << "<li class='category'><a href='/#{category_url}/'>#{category} (#{posts_in_category})</a></li>\n"
      end
      html
    end
  end
end

Liquid::Template.register_tag('category_list', Jekyll::CategoryListTag)
```

将category加入到侧边导航栏，需要增加一个aside
复制以下代码到source/_includes/asides/category_list.html。
```
<section>
  <h1>文章分类</h1>
  <ul id="categories">
    {% category_list %}
  </ul>
</section>
```
配置侧边栏需要修改_config.yml文件，修改其default_asides项：
default_asides: [..., asides/category_list.html, ...]

中文分类支持
----
侧边栏添加了文章分类后，英文分类没有问题，点击打开是分类下的文章列表；但中文分类，如云计算、设计模式之类就不行了，网上有各种解决办法，复杂了点；而且我发现新建日志的文件名如果是中文则会转成拼音，文章分类也是，你可以看下public/blog/categories下的文件名；所以如果能把边栏的链接地址改成拼音就行了，rakefile里有```rake new_post```代码；查看分析发现和```plugins/category_list_tag.rb```的处理类似，  
```category.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase```是转换为单词‘-’分隔并且小写，rakefile里是```  mkdir_p  
"#{source_dir}/#{posts_dir}"  
filename = "#{source_dir}/#{posts_dir}/#{Time.now.strftime('%Y-%m-%d')}-#{title.to_url}.#{new_post_ext}"```  
  **注意:**title多了```.to_url```，原来如此，将```category_list_tag.rb```里改成  
  ```category.gsub(/_|\P{Word}/, '-').gsub(/-{2,}/, '-').downcase.to_url```，
然后rake generate  rake preview  
done！
