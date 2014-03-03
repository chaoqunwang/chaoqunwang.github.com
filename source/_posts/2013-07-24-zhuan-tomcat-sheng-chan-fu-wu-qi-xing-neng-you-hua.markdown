---
layout: post
title: "[转]Tomcat 生产服务器性能优化"
date: 2013-07-24 18:08:06 -0800
comments: true
categories: tech tomcat
keywords: Tomcat 生产 服务器 性能优化
tags: tomcat jvm
description: Tomcat生产服务器性能优化
---
tomcat优化+eclipse优化之类的文章网上有很多，这个收藏当作就手的工具。  
<a href="http://www.oschina.net/translate/tomcat-performance-tuning" target="_blank">来自oschina</a>  : 参与翻译(4人)：Garfielt, Lesus, MtrS, 大志darcy  

[正文]考虑一下这种场景，你开发了一个应用，它有十分优秀的布局设计，最新的特性以及其它的优秀特点。但是在性能这方面欠缺，不管这个应用如何都会遭到客户拒绝。客户总是期望它们的应用应该有更好的性能。如果你在产品中使用了Tomcat服务器，那么这篇文章就会给你几方面来提升Tomcat服务器的性能。<!--more-->  
感谢ITWorld article给本文提供资源。经过沉思我已经知道了和早期版本相比最新的Tomcat提供更好的性能和稳定性。所以一直使用最新的Tomcat版本。现在本文使用下面几步来提高Tomcat服务器的性能。
1. 增加JVM堆内存大小  
2. 修复JRE内存泄漏  
3. 线程池设置  
4. 压缩  
5. 数据库性能调优  
6. Tomcat本地库  
7. 其它选项    

####第一步  – 提高JVM栈内存Increase JVM heap memory
你使用过tomcat的话，简单的说就是“内存溢出”. 通常情况下，这种问题出现在实际的生产环境中.产生这种问题的原因是tomcat使用较少的内存给进程,通过配置TOmcat的配置文件(Windows 下的catalina.bat或Linux下的catalina.sh)可以解决这种问题.这种解决方法是通过增加JVM的栈内存实现的.也就是说，JVM通常不去调用垃圾回收器，所以服务器可以更多关注处理web请求，并要求尽快完成。要更改文件(catalina.sh) 位于"\tomcat server folder\bin\catalina.sh"，下面，给出这个文件的配置信息，  
```
JAVA_OPTS="-Djava.awt.headless=true -Dfile.encoding=UTF-8
-server -Xms1024m -Xmx1024m
-XX:NewSize=512m -XX:MaxNewSize=512m -XX:PermSize=512m
-XX:MaxPermSize=512m -XX:+DisableExplicitGC"
```  
-Xms – 指定初始化时化的栈内存  
-Xmx – 指定最大栈内存  
在重启你的Tomcat服务器之后，这些配置的更改才会有效。下面将介绍如何处理JRE内存泄漏.  

####第二步 – 解决JRE内存泄露
性能表现不佳的另一个主要原因是内存泄漏，正如我之前说过：始终使用最新的tomcat服务器以获得更好的性能和可伸缩性。现在，这句话变成真的。如果我们使用最新的tomcat版本6.0.26及以上就可以解决这个错误，因为它包含了一个监听器来处理JRE和PermGen的内存泄漏。使用的监听器是，  
```
<Listener className="org.apache.catalina.core.JreMemoryLeakPreventionListener" />
```

你可以在server.xml文件中找到这个监听器的配置，server.xml位置在“tomcat project folder/conf/server.xml”。接下来，我们将看看如何调整连接属性“maxThreads”。

####第三步 – 线程池设置
线程池指定Web请求负载的数量，因此，为获得更好的性能这部分应小心处理。可以通过调整连接器属性“maxThreads”完成设置。maxThreads的值应该根据流量的大小，如果值过低，将有没有足够的线程来处理所有的请求，请求将进入等待状态，只有当一个的处理线程释放后才被处理；如果设置的太大，Tomcat的启动将花费更多时间。因此它取决于我们给maxThreads设置一个正确的值。
```
<Connector port="8080" address="localhost"
maxThreads="250" maxHttpHeaderSize="8192"
emptySessionPath="true" protocol="HTTP/1.1"
enableLookups="false" redirectPort="8181" acceptCount="100"
connectionTimeout="20000" disableUploadTimeout="true" />
```

在上述配置中，maxThreads值设定为“250”，这指定可以由服务器处理的并发请求的最大数量。如果没有指定，这个属性的默认值为“200”。任何多出的并发请求将收到“拒绝连接”的错误提示，直到另一个处理请求进程被释放。错误看起来如下，
```
org.apache.tomcat.util.threads.ThreadPool logFull SEVERE: All threads (250) are
currently busy, waiting. Increase maxThreads (250) or check the servlet status
```
如果应用提示上述错误，务必检查上述错误是否是由于单个请求花费太长时间造成的，这个问题的原因是这样的，有时候如果数据库连接不释放的话，进程将不会处理其它请求。  
[注意]: 如果请求的数量超过了“750”，这将不是意味着将maxThreads属性值设置为“750”，它意外着最好使用“Tomcat集群”的多个实例。也就是说，如果有“1000”请求，两个Tomcat实例设置“maxThreads= 500”，而不在单Tomcat实例的情况下设置maxThreads=1000。   
根据我的经验，准确值的设定可以通过将应用在在各种环境中测试得出。接下来，我们来看看如何压缩的MIME类型。

####第4步- 压缩
Tomcat有一个通过在server.xml配置文件中设置压缩的选项。压缩可以在connector像如下设置中完成，
```
<Connector port="8080" protocol="HTTP/1.1"
connectionTimeout="20000"
redirectPort="8181" compression="500"
compressableMimeType="text/html,text/xml,text/plain,application/octet-stream" />
```
在前面的配置中，当文件的大小大于等于500bytes时才会压缩。如果当文件达到了大小但是却没有被压缩，那么设置属性compression="on"。否则Tomcat默认设置是“off”。接下来我们将看看如何调优数据库。

####第五步- 数据库性能调优
Tomcat性能在等待数据库查询被执行期间会降低。如今大多数应用程序都是使用可能包含“命名查询”的关系型数据库。如果是那样的话，Tomcat会在启动时默认加载命名查询，这个可能会提升性能。另一件重要事是确保所有数据库连接正确地关闭。给数据库连接池设置正确值也是十分重要的。我所说的值是指Resource要素的最大空闲数（maxIdle），最大连接数（maxActive）,最大建立连接等待时间（maxWait）属性的值。因为配置依赖与应用要求，我也不能在本文指定正确的值。你可以通过调用数据库性能测试来找到正确的值。  
####第6步 – Tomcat原生库
Tomcat的原生库基于Apache可移植运行时（Apache Portable Runtime简称APR），给程序员提供了超强的扩展性和性能，在产品运作中帮助融合原生的服务器技术以展现最佳的性能。想知道安装说明的朋友请参考Tomcat Native Library – (APR) Installation。
####第7步 – 其他选项
这些选项是：
开启浏览器的缓存，这样读取存放在webapps文件夹里的静态内容会更快，大大推动整体性能。
每当开机时，Tomcat服务器应当自动地重启。
一般情况下HTTPS请求会比HTTP请求慢。如果你想要更好的安全性，即使慢一点我们还是要选择HTTPS。  

就这么多啦。在这篇文章里，我教给了大家一些提高Tomcat服务器性能的方法。如果你觉得这篇文章有用，或者你对提高Tomcat服务器性能有别的看法，请不要忘记留下宝贵的评论。祝你今天编程愉快！
全文完  
另附资料 [转：Tomcat Server.xml配置文件](http://blog.csdn.net/itmagic_jack/article/details/6290239)  
