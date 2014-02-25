---
layout: post
title: "mongodb aggregation framework总结"
date: 2013-05-18 12:56:21 +0800
comments: true
categories: tech mongodb
keywords: mongodb map-reduce spring-data aggregation
tags: mongodb aggregation
description: mongodb map-reduce  spring-data aggregation
---
2.2版本新特性，比group, map-reduce好，reference里有很多操作和[运算]可用  
pipeline operators:  
• $project (page 285)  
• $match (page 281)  
• $limit (page 280)  
• $skip (page 287)  
• $unwind (page 290)// 用于嵌套文档，可对数组拆解  
• $group (page 278)  
• $sort (page 287)  
• $geoNear (page 276)    
<!--more-->

和SQL的对应关系：  
WHERE $match (page 281)  
GROUP BY $group (page 278)  
HAVING $match (page 281)  
SELECT $project (page 285)  
ORDER BY $sort (page 287)  
LIMIT $limit (page 280)  
SUM() $sum  
COUNT() $sum  
join No direct corresponding operator; however, the $unwind (page 290) operator allows for
somewhat similar functionality, but with fields embedded within the document.    

场景: 比如按省份城市统计发帖数目，比如按人统计发帖排名：  
```
db.topic.aggregate(
{ $match: { createtime : { $gt:1370000000000 } } },
{ $group : {
	_id : { id:"$creatorId", name:"$creator" },
	upCount : {$sum : "$upCount"},
	downCount : {$sum : "$downCount"}
	}},
{ $project : {
	_id : 0,
	name : "$_id.name",
	total : { $add : ["$upCount", "$downCount"]}
	}},
{ $sort: { total : -1 } },
{ $skip: 0 },
{ $limit: 3 }
);
{
	"result" : [
		{
				"name" : "俞章数",
				"total" : 108
		},
		{
				"name" : "马晴",
				"total" : 87
		},
		{
				"name" : "苏妙玲",
				"total" : 58
		}
	],
	"ok" : 1
}
```

java driver 官方示例：  
```
// create our pipeline operations, first with the $match
DBObject match = new BasicDBObject("$match", new BasicDBObject("type", "airfare") );

// build the $projection operation
DBObject fields = new BasicDBObject("department", 1);
fields.put("amount", 1);
fields.put("_id", 0);
DBObject project = new BasicDBObject("$project", fields );

// Now the $group operation
DBObject groupFields = new BasicDBObject( "_id", "$department");
groupFields.put("average", new BasicDBObject( "$avg", "$amount"));
DBObject group = new BasicDBObject("$group", groupFields);

// run aggregation
AggregationOutput output = collection.aggregate( match, project, group );
```

spring data mongodb，@since 1.3，注意升级  
官方例子是对城市人口做统计，group两次（对第一次group的结果再group）  
好处在于对结果进行了封装，返回List，注意ZipInfoStats嵌套City，使用nested和bind:  
```  
class ZipInfo {
	String id;
	String city;
	String state;
	@Field("pop") int population;
	@Field("loc") double[] location;
}
class City {
	String name;
	int population;
}
class ZipInfoStats {
	String id;
	String state;
	City biggestCity;
	City smallestCity;
}

import static org.springframework.data.mongodb.core.aggregation.Aggregation.*;
TypedAggregation<ZipInfo> aggregation = newAggregation(ZipInfo.class,
	group("state", "city")
		.sum("population").as("pop"),
	sort(ASC, "pop", "state", "city"),
	group("state")
		.last("city").as("biggestCity")
		.last("pop").as("biggestPop")
		.first("city").as("smallestCity")
		.first("pop").as("smallestPop"),
	project()
		.and("state").previousOperation()
		.and("biggestCity")
		.nested(bind("name", "biggestCity").and("population", "biggestPop"))
		.and("smallestCity")
		.nested(bind("name", "smallestCity").and("population", "smallestPop")),
	sort(ASC, "state")
);
AggregationResults<ZipInfoStats> result = mongoTemplate.aggregate(aggregation, ZipInfoStats.class);
ZipInfoStats firstZipInfoStats = result.getMappedResults().get(0);
```

对应的shell即是：  
```
db.zipcodes.aggregate( 
{ $group:
	{	_id: { state: "$state", city: "$city" },
		pop: { $sum: "$pop" } } 
},
{ $sort: { pop: 1 } },
{ $group:
	{	_id : "$_id.state",
		biggestCity: { $last: "$_id.city" },
		biggestPop: { $last: "$pop" },
		smallestCity: { $first: "$_id.city" },
		smallestPop: { $first: "$pop" } } 
},
// the following $project is optional, and
// modifies the output format.
{ $project:
	{	_id: 0,
		state: "$_id",
		biggestCity: { name: "$biggestCity", pop: "$biggestPop" },
		smallestCity: { name: "$smallestCity", pop: "$smallestPop" } } 
} )
```

