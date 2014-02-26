---
layout: post
title: "MongoDB常用命令和操作总结2"
date: 2013-05-10 10:09:23 +0800
comments: true
categories: tech mongodb
keywords: mongodb map-reduce 常用命令 spring-data aggregation
tags: mongodb mapreduce
description: mongodb map-reduce 常用命令 spring-data aggregation
---
做个总结，涉及到mongodb的常用命令、java driver查询、spring data mongodb的使用，group，map-reduce，aggregation framework等  
###group
topic : reply = one to many，按topic(或发布者)分组统计回复数
shell:
```
> db.reply.group({ "key" : { "topic" : 1} , "$reduce" : "function(doc, prev) {
 prev.total += 1; }" , "initial" : {"total" : 0}})
```
<!--more-->
spring-data-mongodb:
```
Criteria cri = Criteria.where("createtime").gt(1380000000000L);// 时间条件
GroupBy groupBy = GroupBy
    	.key("topic").initialDocument("{total: 0 }")
		.reduceFunction("function(doc, prev) { prev.total += 1; }");
String collection = mongoTemplate.getCollectionName(Reply.class);
GroupByResults<Reply> replys = mongoTemplate.group(cri, collection, groupBy, Reply.class);
```

另一个例子：统计提问的回复（有内容的和简单赞踩），按权重计算热度
```
String reduceFunction = "function(doc, out) { if (doc.content) { out.contentCount += 1;} "
		+ "else { out.simpleCount += 1; }; out.topic = doc.topic}";
String finalizeFunction = "function(out) { out.rankScore = out.simpleCount * " + ratio
		+ " + out.contentCount * (" + (10 - ratio) + ") } ";
GroupBy groupBy = GroupBy
		.keyFunction("function(doc) { return { topic: doc.topic }; }")
		.initialDocument("{contentCount: 0, simpleCount: 0 }")
		.reduceFunction(reduceFunction).finalizeFunction(finalizeFunction);
```
				
java driver:
```
public GroupCommand(DBCollection inputCollection, DBObject keys, DBObject condition, DBObject initial, String reduce, String finalize)
DBCollection collection = mongoTemplate.getCollection("reply");
collection.group(...);
```

###map-reduce

场景：展示发帖或回帖的时间趋势图，或者说按整点显示此小时内的发帖数和回帖数，展示成折线图
创建时间保存的是number long，即date.getTime()的值，key要转成小时，使用new Date(y,m,d,h,0,0,0)  
标签：[mongodb](/blog/categories/mongodb)  
spring-data-mongodb:
```
String mapFunction = "function () { var key=new Date(new Date(this.createtime).getFullYear(),"
		+ "new Date(this.createtime).getMonth(), new Date(this.createtime).getDate(),"
		+ "new Date(this.createtime).getHours(), 0, 0, 0).getTime(); "
		+ "emit( key, { hour:key, count:1 } ); }";
String reduceFunction = "function (key, values) { "
		+ "	var total = 0;" 
		+ "	for (var i=0; i<values.length; i++) { "
		+ "		total += values[i].count; "
		+ "	}" 
		+ "	return { hour:key, count:total }; "
		+ "}";
MapReduceResults<Reply> results = mongoTemplate.mapReduce(
		new Query(cri), collectionName, mapFunction,
		reduceFunction, Reply.class);
List<Reply> replys = Lists.newArrayList(results);
for (Replys reply : replys) {
	ReplyStat value = reply.getValue();
	System.out.println(value.getHour() + " : " + value.getCount());
}
```

需要注意的是：结果存在reply的value字段里，是为了后面构造map好处理；场景不一样的话，先使用shell看看结果
```
private ReplyStat value;
class ReplyStat {
	private Long hour;
	private Long count;
```


shell:
```
db.runCommand({ mapreduce: "reply", 
 map : function Map() {
	var key=new Date(new Date(this.createtime).getFullYear(), 
		new Date(this.createtime).getMonth(), 
		new Date(this.createtime).getDate(),
		new Date(this.createtime).getHours(), 0, 0, 0).getTime(); 
	emit( key, { hour:key, count:1 } );
},
 reduce : function Reduce(key, values) {
	var total = 0;	
	for (var i=0; i<values.length; i++) {
		total += values[i].count; 	
	}	
	return { hour:key, count:total };
},
 finalize : function Finalize(key, reduced) {
	return reduced;
},
 query : { "type" : 1, "$and" : [
	{ "createtime" : { "$gt" : NumberLong("1370000000000") } }, 
	{ "createtime" : { "$lt" : NumberLong("1380000000000") } }] 
},
 out : { inline : 1 }
});
```

======result======
```
{
        "results" : [
                {
                        "_id" : 1376881200000,
                        "value" : {
                                "hour" : 1376881200000,
                                "count" : 2
                        }
                },
                {
                        "_id" : 1376884800000,
                        "value" : {
                                "hour" : 1376884800000,
                                "count" : 5
                        }
                },
				...
                {
                        "_id" : 1379404800000,
                        "value" : {
                                "hour" : 1379404800000,
                                "count" : 27
                        }
                }
        ],
        "timeMillis" : 24,
        "counts" : {
                "input" : 263,
                "emit" : 263,
                "reduce" : 35,
                "output" : 43
        },
        "ok" : 1
}
```

如果emit修改成
```
emit( key, {count:1} );
```
reduce里
```
return {count:total};
```
结果就会是：
```
{
        "results" : [
                {
                        "_id" : 1376881200000,
                        "value" : {
                                "count" : 2
                        }
                },
                {
                        "_id" : 1376884800000,
                        "value" : {
                                "count" : 5
                        }
                },
                {
                        "_id" : 1376888400000,
                        "value" : {
                                "count" : 8
                        }
                }
        ],
        "timeMillis" : 22,
        "counts" : {
                "input" : 263,
                "emit" : 263,
                "reduce" : 35,
                "output" : 43
        },
        "ok" : 1
}
```

