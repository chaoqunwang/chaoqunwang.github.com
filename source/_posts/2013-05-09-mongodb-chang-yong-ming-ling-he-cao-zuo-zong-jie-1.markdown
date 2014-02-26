---
layout: post
title: "MongoDB常用命令和操作总结1"
date: 2013-05-09 16:29:59 +0800
comments: true
categories: tech mongodb
keywords: mongodb map-reduce 常用命令 spring-data aggregation
tags: mongodb mapreduce
description: mongodb map-reduce 常用命令 spring-data aggregation
---
做个总结，涉及到mongodb的常用命令、java driver查询、spring data mongodb的使用，group，map-reduce，aggregation framework等
###关闭服务
```
use admin
db.shutdownServer()
```
###加锁
```
use admin
db.runCommand({"fsync":1,"lock":1})
```<!--more-->
###解锁
```
use admin
db.$cmd.sys.unlock.findOne()
db.currentOp()    
{"inprog":[]}
```
###导出和导入
```
mongodump -h 192.168.0.100:27017 -d mydb -o B:\mongo\dump
mongorestore -h 127.0.0.1:27017 --directoryperdb B:\mongo\dump
```
###用户
```
use admin
db.addUser('name','pwd')
db.system.users.find()
db.auth('name','pwd')
db.removeUser('name')
```
###数据库
```
db.copyDatabase('projectDB1', 'projectDB2')
db.projectDB1.drop()
db.dropDatabase()
```
###增删改
```
db.mycollection.inser,save,update...
```
###索引
```
db.user.ensureIndex({firstname: 1, lastname: 1}, {unique: true});
db.user.dropIndex('address.post_1')
```
###查询
```
db.mycollection.find,findOne,distinct.sort({'createTime',-1}).skip(3).limit(10)
db.user.insert({"name":"cq","age":28,"address":{"province":100,"city":101}})
db.user.find({"_id":ObjectId("52f830f3aab82981150db455")})
db.user.find({"address":{"province":100,"city":101}})  # one record
db.user.find({"address":{"city":101,"province":100}})  # nothing
db.user.find({"address.city":101,"address.province":100})  # one record
```
注意：key的顺序,因为MongoDB使用BSON的二进制数据格式  
注意：limit的值例如为-5的话等同于5，为0则返回全部，汗  
标签：[技术](/blog/categories/tech)  
```
db.user.find({creationTime:{$gt:1300000000000, $lte:1310000000000}); 
```
使用where可做运算  
```
db.reply.find({$where: "this.upCount+this.downCount<1"}); 
db.reply.find("this.upCount+this.downCount<1");
```
###返回和排除字段
```
db.user.find({"name":"cq"}, {age:1, address:0}); 
count
db.topic.find().skip(10).limit(5).count(); # 所有的记录数量
```  
要返回限制的记录数量，要使用count(true)或count(非0) 
```
db.topic.find().skip(10).limit(5).count(true);
```
###dbref关联  
多查一  
```
> db.reply.findOne({creator:"wy"}, {creator:1,topic:1})
{
        "_id" : ObjectId("52d3ae720b6316a72bb31c45"),
        "creator" : "wy",
        "topic" : DBRef("topic", ObjectId("52cf620a0b6307f6a0d44450"))
}
> db.reply.findOne({creator:"wy"}).topic
DBRef("topic", ObjectId("52cf620a0b6307f6a0d44450"))
> db.reply.findOne({creator:"wy"}).topic.fetch()
{
        "_id" : ObjectId("52cf620a0b6307f6a0d44450"),
        "content" : "xxx",
        "createtime" : NumberLong("1389322762932"),
        "creator" : "zzz"
    	...
}
```  

一查多  
```
> topic=db.reply.findOne({creator:"wy"}).topic
DBRef("topic", ObjectId("52cf620a0b6307f6a0d44450"))
> db.reply.find({"topic":topic}).count()
2
> topic=db.reply.findOne({creator:"wy"}).topic
DBRef("topic", ObjectId("52cf620a0b6307f6a0d44450"))
> db.reply.find({"topic.$id":topic.$id}).count()
2
> topic=db.reply.findOne({creator:"wy"}).topic.fetch()
{
        "_id" : ObjectId("52cf620a0b6307f6a0d44450"),
        "content" : "xxx",
        "createtime" : NumberLong("1389322762932"),
        "creator" : "zzz"
		...
}
> db.reply.find({"topic.$id":topic._id}).count()
2
```
####spring data mongodb
```
Criteria cri = Criteria.where("topic.$id").is(new ObjectId("52d8f8950b6316a72bb31c7c"));
Reply reply = mongoTemplate.findOne(Query.query(cri), Reply.class);

cri.andOperator(Criteria.where("passedtime").gt(fromTime), Criteria.where("passedtime").lt(toTime));
// 错误的：Criteria.where("passedtime").gt(fromTime).and("passedtime").lt(toTime)
```

####java driver 可以这样：  
```
String total = "this.upCount+this.downCount < " + minCount;
BasicDBObject query = new BasicDBObject("$where", total);
query.append("passedtime", new BasicDBObject("$gt", fromTime).append("$lt", toTime));
// TODO query.append(other conditions);

// 返回字段
BasicDBObject keys = new BasicDBObject();
keys.put("_id", 1);
keys.put("creator", 1);

MongoClient mongoClient = new MongoClient(new ServerAddress("localhost", 27017));
DB db = mongo.getDB("mydb");
DBCollection collection = db.getCollection("test");

long count = collection.count(query);
DBCursor cursor = collection.find(query, keys).limit(size);
for (int i = 0; i < size; i++) {
	DBObject e = cursor.next();
	String topicId = e.get("_id").toString();
	// TODO
}
```

