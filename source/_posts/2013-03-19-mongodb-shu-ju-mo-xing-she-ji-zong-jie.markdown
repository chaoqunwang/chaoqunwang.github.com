---
layout: post
title: "mongodb数据模型设计总结"
date: 2013-03-19 15:01:33 +0800
comments: true
categories: tech mongodb
keywords: mongodb 数据模型 设计 总结
tags: mongodb
description: mongodb数据模型设计总结
---
mongoDb的表设计(Schema design)不同于关系型数据库如oracle，mysql，但基本的设计原则依然一致，因为其灵活性，所以可以快速的改善现有设计以适应新的需求  

设计需要权衡应用的需求，数据库各项性能指标，数据的获取模式；设计时一直要考虑应用如何使用数据如查询、更新、处理、索引、分片，还要考虑数据自身的内在结构

对照关系型数据库理解几个概念:  
表：table  vs  collection  
行：view/row(s)	vs json document  
索引：index	vs index  
关联：join vs	embedding & linking across documents  
分片：partition	vs shard  <!--more-->

最佳实践  
----
1、顶级对象，一般使用独立的collection，区别于嵌入  
2、线性明细对象如订单里的订单项，一般使用嵌入  
3、包含关系的对象通常使用嵌入  
4、多对多的关系通常采用引用，dbref  
5、只有少量数据的可以单独作为一个collection，这样可以快速缓存到应用服务器内存  
6、嵌入对象比顶级对象难引用，至少现在还不能对它使用dbref  
7、嵌入对象的获取有时候会比较难，例如各科分数嵌入到学生对象，从所有学生中获取前100个高分，不嵌入会更简单  
8、如果嵌入对象数量很多，可以限制其大小  
9、性能存在问题（应是查询的性能），使用嵌入  

标签：[mongodb](/blog/categories/mongodb)  

用例
----
####产品信息：  
如cd,dvd，shipping里有包装尺寸，pricing里有折扣，details有属性或标签之类使用数组（数量不定，也不会很多），尤其像尺寸和属性，mongodb的灵活的优势就显现出来了，rdbms要么加预留字段，tag_1,tag_2之类，要么就得分出个表使用关联  
```
{
sku: "00e8da9b",
type: "Audio Album",
title: "A Love Supreme",
description: "by John Coltrane",
asin: "B0000A118M",
shipping: {
	weight: 6,
	dimensions: {
		width: 10,
		height: 10,
		depth: 1
	}
},
pricing: {
	list: 1200,
	retail: 1100,
	savings: 100,
	pct_savings: 8
},
details: {
	title: "A Love Supreme [Original Recording Reissued]",
	artist: "John Coltrane",
	genre: [ "Jazz", "General" ],
	tracks: [
		"A Love Supreme Part I: Acknowledgement",
		"A Love Supreme Part II - Resolution",
		"A Love Supreme, Part III: Pursuance",
		"A Love Supreme, Part IV-Psalm"
	]
}
}
```

####内容管理系统  
页面内容（不经常变化的如联系我们，关于之类），新闻文章（标题，摘要，内容，作者，时间，栏目...），图片（相册或分类，标签，描述，时间，甚至图片文件）  

####Basic Page 
```
{
	_id: ObjectId(...),
	nonce: ObjectId(...),
	metadata: {
		type: ’basic-page’
		section: ’my-photos’,
		slug: ’about’,
		title: ’About Us’,
		created: ISODate(...),
		author: { _id: ObjectId(...), name: ’Rick’ },
		tags: [ ... ],
		detail: { 
			text: ’# About Us\n...’ 
		}
	}
}
```
 
####photo  
文件可以保存在数据库，使用BSON对象，但最大不能超过16MB，所以大的文件可以采用GridFS将数据存储在两个collection如这里是cms.assets.files保存基础数据，cms.assets.chunks保存文件数据；  
cms.assets.files：
```
{
	_id: ObjectId(...),
	length: 123...,
	chunkSize: 262144,
	uploadDate: ISODate(...),
	contentType: ’image/jpeg’,
	md5: ’ba49a...’,
	metadata: {
		nonce: ObjectId(...),
		slug: ’2012-03-invisible-bicycle’,
		type: ’photo’,
		section: ’my-album’,
		title: ’Kitteh’,
		created: ISODate(...),
		author: { 
			_id: ObjectId(...), 
			name: ’Jared’ 
		},
		tags: [ ... ],
		detail: {
			filename: ’kitteh_invisible_bike.jpg’,
			resolution: [ 1600, 1600 ], 
			... 
		}
	}
}
```
an example of the GridFS interface in Java  
```java
// returns default GridFS bucket (i.e. "fs" collection)
GridFS myFS = new GridFS(myDatabase);
// saves the file to "fs" GridFS bucket
myFS.createFile(new File("/tmp/largething.mpg"));
Optionally, interfaces may support other additional GridFS buckets as in the following example:
// returns GridFS bucket named "contracts"
GridFS myContracts = new GridFS(myDatabase, "contracts");
// retrieve GridFS object "smithco"
GridFSDBFile file = myContracts.findOne("smithco");
// saves the GridFS file to the file system
file.writeTo(new File("/tmp/smithco.pdf"));
```
标签：[技术](/blog/categories/tech) 
####用户评论  
有多种实现，平铺式？盖楼式？分页？选择哪种就要看具体需求了；如果未来想切换，成本很高  
1、独立collection  
2、嵌入，数量要限制  
3、不嵌入，桶式存储（每个文档存储N个comments数组，page,count）  

也要注意评论里的用户信息，考虑冗余用户id,昵称和头像还是使用dbref关联，区别在于前者性能好些但信息更新比如头像，之前的评论显示的头像就不一致了

资料  
----
官方手册  
http://docs.mongodb.org/manual/  

官方模式设计文档，有单独pdf，包含一对一，一对多，多对多，树状结构，原子操作，gridFS...
http://docs.mongodb.org/manual/data-modeling/  

Schema Design Basics - MongoSF Presentation (May 2011)
http://www.10gen.com/video/mongosf2011/schemabasics  

