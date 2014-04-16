---
layout: post
title: "Spring Cache之Ehcache和Memcached"
date: 2014-04-15 14:52:05 +0800
comments: true
categories: tech spring-cache
keywords: Spring Cache Ehcache Memcached LinkedHashMap
tags: Spring Ehcache Memcached LinkedHashMap
description: Spring Cache Ehcache Memcached LinkedHashMap
---
spring框架从3.1版本开始提供了缓存支持：在spring-context.jar里的org.springframework.cache包，以及spring-context-support.jar里的org.springframework.cache包；而且提供了基于ConcurrentHashMap、JCacheCache、EhCache、GuavaCache的实现。这里我们先看下基于EhCache的使用，然后考虑集成Memcached；版本：spring3.2和spring4，EhCache2.7，spyMemcached2.8；内容还涉及HashMap、LinkedHashMap、synchronizedMap、ConcurrentHashMap、ReentrantLock……  
[查阅spring 4.0.x reference](http://docs.spring.io/spring/docs/4.0.x/spring-framework-reference/html/cache.html)  
<!--more-->
一、EhCache配置  
----
###1. 添加相关jar，添加ehcache.xml  

```xml  
<?xml version="1.0" encoding="UTF-8"?>
<ehcache xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="ehcache.xsd" updateCheck="true"
	monitoring="autodetect" dynamicConfig="true">
	<diskStore path="java.io.tmpdir" />
	<defaultCache maxElementsInMemory="10000" maxElementsOnDisk="100000"
		eternal="false" timeToIdleSeconds="120" timeToLiveSeconds="120" overflowToDisk="true" 
		diskPersistent="false" diskExpiryThreadIntervalSeconds="120" memoryStoreEvictionPolicy="LRU" />
	<cache name="notice_cache" maxElementsInMemory="10000" maxElementsOnDisk="100000"
		eternal="true" overflowToDisk="true" diskSpoolBufferSizeMB="50" />
</ehcache>
```
属性意义基本明确，这里我配置了一个名称是notice_cache的cache节点，其他的可以按此添加。

###2. spring-cache.xml 
配置cacheManager和cacheManagerFactory，并将ehcache.xml配入即可  

```xml  
<?xml version="1.0" encoding="UTF-8"?>
<beans xmlns="http://www.springframework.org/schema/beans"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:cache="http://www.springframework.org/schema/cache"
	xmlns:p="http://www.springframework.org/schema/p"
	xsi:schemaLocation="http://www.springframework.org/schema/beans http://www.springframework.org/schema/beans/spring-beans-3.2.xsd
		http://www.springframework.org/schema/cache http://www.springframework.org/schema/cache/spring-cache-3.2.xsd">

	<cache:annotation-driven cache-manager="cacheManager" />
	
	<bean id="cacheManager" class="org.springframework.cache.ehcache.EhCacheCacheManager"
		p:cacheManager-ref="cacheManagerFactory" />
		
	<bean id="cacheManagerFactory" class="org.springframework.cache.ehcache.EhCacheManagerFactoryBean"
		p:configLocation="classpath:ehcache.xml" p:shared="false" />
</beans>
```

###3. @Cacheable\@CacheEvict\@CachePut\@Caching...  
注解加在相应方法上，支持spel，详细参见文档[查阅spring 4.0.x reference](http://docs.spring.io/spring/docs/4.0.x/spring-framework-reference/html/cache.html)  

```java  
	@Cacheable(value = "notice_cache", key = "'notice'+#id")
	public Notice get(String id) {
		return noticeDao.get(id);
	}
	
	@Cacheable(value = "notice_cache")
	public List<Notice> search(String keywords, Date fromTime, Date toTime, Integer[] status, Page page) {
		//...
	}
```
至此配置完了，run一下，报错：没有序列化，好吧  
```java  
public class Notice implements Serializable {
```

标签：[技术](/blog/categories/tech)  

这样ehcache集成完了，get方法对同一条记录只从数据库查询一次，cache是成功的，但search方法却一直读库，这里没有设置cache的key，设置的话如果是固定的，那么每次结果集都一样，不会更新；文档说不设key，将使用默认key生成器DefaultKeyGenerator：  
```java  
public class DefaultKeyGenerator implements KeyGenerator {
	public static final int NO_PARAM_KEY = 0;
	public static final int NULL_PARAM_KEY = 53;

	public Object generate(Object target, Method method, Object... params) {
		if (params.length == 1) {
			return (params[0] == null ? NULL_PARAM_KEY : params[0]);
		}
		if (params.length == 0) {
			return NO_PARAM_KEY;
		}
		int hashCode = 17;
		for (Object object : params) {
			hashCode = 31 * hashCode + (object == null ? NULL_PARAM_KEY : object.hashCode());
		}
		return Integer.valueOf(hashCode);
	}
}
```
####问题####  
就在于object.hashCode()，看方法的参数string没问题，date没问题，Integer数组使用的就是Object类的hashCode是个内存地址，每次执行都变，要改用Arrays.hashCode(array)才不会变；当然，分页类page也要重写hashCode；顺便说下，apache的commons-lang.jar提供了EqualsBuilder、HashCodeBuilder、ToStringBuilder可用于重写各方法。
####4. 自定义key生成器  
解决上面问题：重写生成器（继承DefaultKeyGenerator，需要注意的是对于param是list,set,map取hashcode，其泛型类也要重写hashCode方法）并配置:  
```
	<cache:annotation-driven cache-manager="cacheManager" key-generator="keyGenerator"/>
	<bean id="keyGenerator" class="......CustomKeyGenerator" />
```
```java  
public class CustomKeyGenerator extends DefaultKeyGenerator {
	public Object generate(Object target, Method method, Object... params) {
		StringBuffer buffer = new StringBuffer();
		buffer.append(target.getClass().getName());
		buffer.append(".");
		buffer.append(method.getName());
		buffer.append(".");
		if (params.length > 0) {
			for (Object each : params) {
				if (each != null) {
					if (each instanceof AtomicInteger || each instanceof AtomicLong || each instanceof BigDecimal
							|| each instanceof BigInteger || each instanceof Byte || each instanceof Double
							|| each instanceof Float || each instanceof Integer || each instanceof Long
							|| each instanceof Short) {
						buffer.append(each);
					} else if (each instanceof Object[]) {
						buffer.append(Arrays.hashCode((Object[]) each));
					} else {
						buffer.append(each.hashCode());
					}
				} else {
					buffer.append(NO_PARAM_KEY);
				}
			}
		} else {
			buffer.append(NO_PARAM_KEY);
		}
		return buffer.toString().hashCode();
	}
}
```
####5. 添加、更新、删除  

显然@Cacheable是缓存，@CacheEvict是擦除，@CachePut相当于擦除后再缓存，对于key是确定的很好，比如getById(id)，update(obj)，其key可以用id，obj.id；update时也可以用@CachePut，要注意update方法要返回更新后的obj，void不行。  

问题又出现了：不明确的key如何更新？例如search，当新添加一条记录后，就不能使用@CacheEvict(value="notice_cache", key="?")，因为取不到key，也不能模糊匹配；这种情况下只能使用@CacheEvict(value = "notice_cache", allEntries = true)，将notice_cache所有的缓存擦除，多少有点粗糙（在后面使用memcached我实现了一种方法能够精细擦除）  

还有一个**注意事项**：因其使用aop的动态代理，对于内部调用无效，例如publish方法没加cache注解，内部调用update方法（加了@CachePut）更新状态值，但cache不会更新；controller调用service方法可以，controller方法也可以加，但如果参数有request，每次都变，所以没用，一般加在service方法上。

二、集成Memcached  
----
背景：现在的项目使用memcached做缓存，基本上是编码式的，在需要的时候，生成key，将value转为json再set到缓存，因此打算使用注解式更优雅的处理，就需要实现spring cache的相关接口和自定义一些方法  
####1. spring集成Memcached，使用spyMemcached  

```xml
	<bean id="memcachedClient" class="net.spy.memcached.spring.MemcachedClientFactoryBean">
		<property name="servers" value="${memcached.servers}" />
		<property name="protocol" value="BINARY" />
		<property name="transcoder">
			<bean class="net.spy.memcached.transcoders.SerializingTranscoder">
				<property name="compressionThreshold" value="${memcached.transcoder.compressionThreshold}" />
			</bean>
		</property>
		<property name="opTimeout" value="${memcached.opTimeout}" />
		<property name="timeoutExceptionThreshold" value="1998" />
	    <property name="hashAlg">
	            <value type="net.spy.memcached.DefaultHashAlgorithm">${memcached.hashAlg}</value>
		</property>
		<property name="locatorType" value="${memcached.locatorType}" />
		<property name="failureMode" value="${memcached.failureMode}" />
		<property name="useNagleAlgorithm" value="${memcached.useNagleAlgorithm}" />
	</bean>
```
properties:
```
####memcached config
memcached.servers=ip:port
memcached.protocol=BINARY
memcached.transcoder.compressionThreshold=1024
memcached.opTimeout=1000
memcached.timeoutExceptionThreshold=1998
memcached.hashAlg=KETAMA_HASH
memcached.locatorType=CONSISTENT
memcached.failureMode=Redistribute
memcached.useNagleAlgorithm=false
```

标签：[技术](/blog/categories/tech)  
####2. 实现MemcachedCacheManager和MemcachedCache
参考ehcache的源码（org.springframework.cache.ehcache包里）：EhCacheCache和EhCacheCacheManager，manager用来获取cache，重写了getCache和loadCaches方法，这样配置在ehcache.xml里的cache name都会实例化成每个EhCacheCache，当执行到@Cacheable的方法上，就会调用getCache(name)获取cache，再根据key取得value；  

未完待续





































