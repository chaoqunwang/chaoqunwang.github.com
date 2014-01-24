---
layout: post
title: "MongoDB replSet集群和shard分片"
date: 2013-11-17 16:11:35 +0800
comments: true
categories: tech mongodb
keywords: mongodb 集群 replSet 分片 shard
tags: mongodb 集群 分片
description: mongodb 集群 replSet 分片 shard
---

mongodb的集群有两种：1.主从(master, slave)  2.副本集(Replica Set)  
区别是副本集没有固定的"主节点", 有一个活跃节点(primary)和  一个或多个备份节点(secondary), 而且可以在活跃节点有问题时自动切换（仲裁\选举方式）  
本文内容的结果是：建立2个分片，每个分片3个备份节点（端口1000x,2000x），2个选举节点（端口10000,20000），1个路由(端口7701，想选7000被占了)，3个config节点(端口660x，想选6000也被占了)，总共12个<!--more-->
####1. MongoDB集群
将mongodb的zip解压到不同的文件夹（本文是windows下，linux类似），建立3个节点（1000X是myshard1分片的），注意端口号，启动：
```
c:\mongo10001\bin\mongod -f c:\mongo10001\config
c:\mongo10002\bin\mongod -f c:\mongo10002\config
c:\mongo10003\bin\mongod -f c:\mongo10003\config
```
使用config文件配置，mongo10001节点的内容如下，其他相应修改即可：
```
port=10001
dbpath=C:\mongo10001\data\
logpath=C:\mongo10001\log\mongo.log
replSet=myshard1/127.0.0.1:10002,127.0.0.1:10003
shardsvr=true
logappend=true
rest=true
```
仲裁节点（可选，要的话后面还有要addArb）  
```
c:\mongo10000\bin\mongod -f c:\mongo10000\config
or
c:\mongo10000\bin\mongod --dbpath=c:\mongo10000\data --port 10000 --replSet myshard1/127.0.0.1:10001  
```

将各节点启动后，cmd下连接并执行初始化命令：  
```
mongo 127.0.0.1:10001/admin
db.runCommand({"replSetInitiate":{ "_id":"myshard1", "members":[{ "_id":1, "host":"127.0.0.1:10001"}, { "_id":2, "host":"127.0.0.1:10002"}, { "_id":3, "host":"127.0.0.1:10003"}] }})
```
这个2000X是myshard2分片的3个节点，需要像前面一样配好、启动、执行，不分片可忽略
```
mongo 127.0.0.1:20001/admin
db.runCommand({"replSetInitiate":{ "_id":"myshard2", "members":[{ "_id":1, "host":"127.0.0.1:20001"}, { "_id":2, "host":"127.0.0.1:20002"}, { "_id":3, "host":"127.0.0.1:20003"}] }})
```
查看状态
```
rs.status()
```
仲裁节点（可选，前面没配置就不要add了）  
```
rs.addArb("127.0.0.1:10000")
```  

**测试**在一个节点导入数据后，查看其他节点数据也有了
```
mongorestore -h 127.0.0.1:10001 --directoryperdb b:\mongo\dump
```  
**注意**：关于节点的读写操作
在primary节点中添加数据: db.xxxx.insert
如果在secondary备份节点查询，会出现错误:
```
error: { "$err" : "not master and slaveok=false", "code" : 13435 }
```
执行如下语句:
```
db.getMongo().setSlaveOk();
```
这是因为对于replica set中的secondary节点默认是不可读的，由Secondary来分担读的压力，Primary只承担写操作，通过在连接时指定或者在主库指定slaveOk即可

####spring data mongodb的集群配置（未分片）
原来使用单一mongo的，现在要用集群，就把spring xml配置和properties做相应修改：
```
<mongo:mongo replica-set="${mongo.replica.set}"/>

mongo.replica.set=127.0.0.1:10001,127.0.0.1:10002,127.0.0.1:10003
```

####2. MongoDB分片
[摘录]基本思想就是将集合切分成小块，这些块分散到若干片里面，每个片只负责总数据的一部分；应用程序不必知道
哪片对应哪些数据，甚至不需要知道数据已经被拆分了，所以在分片之前要运行一个路由进程，进程名mongos，这个路由器知道
所有数据的存放位置，所以应用可以连接它来正常发送请求；对应用来说，它仅知道连接了一个普通的mongod；路由器知道和片的
对应关系，能够转发请求到正确的片上；如果请求有了回应，路由器将其收集起来回送给应用。  

所以，**在下面的分片完成后**，上面spring data mongodb的集群配置就要**改回单一mongo的，注意要连接的是mongos，不是原来那个**

好了，这里要有路由节点和config节点  
开启**config服务器**（我配了3个，为了测试有节点挂掉的情况，这只是第1个），使用参数或config文件启动
```
c:\mongo6001\bin\mongod --dbpath=c:\mongo6001\data --port 6001 --configsvr
c:\mongo6001\bin\mongod -f c:\mongo6001\config
```

config文件：
```
port=6001
dbpath=C:\mongo6001\data\
logpath=C:\mongo6001\log\mongo.log
configsvr=true
logappend=true
rest=true
```

开启**mongos服务器**，使用参数或config文件启动
```
c:\mongo7701\bin\mongos --port 7701 --configdb=127.0.0.1:6001
c:\mongo7701\bin\mongos -f c:\mongo7701\config  
```
config文件：
```
port=7701
logpath=C:\mongo7701\log\mongo.log
#configdb说明：一个就写一个，多个就写多个，这里是3个
configdb=127.0.0.1:6001,127.0.0.1:6002,127.0.0.1:6003 
logappend=true
```

**启动mongod服务器，上面集群配了3个，启动即可（2000X是myshard2分片的，也启动）**
```
c:\mongo10001\bin\mongod -f c:\mongo10001\config
c:\mongo10002\bin\mongod -f c:\mongo10002\config
c:\mongo10003\bin\mongod -f c:\mongo10003\config
c:\mongo20001\bin\mongod -f c:\mongo20001\config
c:\mongo20002\bin\mongod -f c:\mongo20002\config
c:\mongo20003\bin\mongod -f c:\mongo20003\config
```
**连接mongos服务器**
```
C:\Users\wangchaoqun>mongo 127.0.0.1:7701/admin
MongoDB shell version: 2.4.8
connecting to: 127.0.0.1:7701/admin
```
然后将10001，10002，10003的mongod交给mongos,添加分片也就是addshard()  
**两个分片的集群，每个分片3个备份节点**
```
db.runCommand({addshard:"myshard1/127.0.0.1:10001,127.0.0.1:10002,127.0.0.1:10003",allowlocal:true})
db.runCommand({addshard:"myshard2/127.0.0.1:20001,127.0.0.1:20002,127.0.0.1:20003",allowlocal:true})
```

片已经集群了，但是mongos不知道该如何切分数据，要在mongos设置片键：  
1. 开启数据库分片功能
```
mongos> db.runCommand({"enablesharding":"mytestdb"})
{ "ok" : 1 }
```  
2. 指定集合中分片的片键，这里使用users里的name
```
mongos> db.runCommand({shardcollection:"mytestdb.users",key:{name:1}})
{ "collectionsharded" : "mytestdb.users", "ok" : 1 }
```  

####3. 测试
通过mongos向mongodb插入10w记录
```
use mytestdb
for(var i=0;i<100000;i++){
	var x="poiuytrewqasdfghjklmnbvcxz";
	var c=x.charAt(Math.ceil(Math.random() * 25));
	var t=Math.ceil(Math.random() * 100000);
	var content=c+t;
	var time=new Date().getTime()-Math.ceil(Math.random() * 100)*t;
	db.users.insert({"content":content,"creatorId":""+i%7,"createtime":time});
}
```  
通过printShardingStatus命令查看mongodb的数据分片情况  
```
db.printShardingStatus();
```
每个节点都看看，是不是数据都有了

####4. 参考
http://blog.sina.com.cn/s/blog_498e79cc0101115v.html
http://www.cnblogs.com/huangxincheng/archive/2012/03/04/2379755.html
http://www.cnblogs.com/refactor/archive/2012/08/13/2600140.html
