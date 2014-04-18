---
layout: post
title: "Spring Cache之Ehcache和Memcached"
date: 2014-04-15 14:52:05 +0800
comments: true
categories: tech spring memcached
keywords: Spring Cache Ehcache Memcached HashMap LinkedHashMap synchronizedMap ConcurrentHashMap
tags: Spring Ehcache Memcached HashMap
description: Spring Cache Ehcache Memcached HashMap LinkedHashMap synchronizedMap ConcurrentHashMap
---
spring框架从3.1版本开始提供了缓存支持：在spring-context.jar里的org.springframework.cache包，以及spring-context-support.jar里的org.springframework.cache包；而且提供了基于ConcurrentHashMap、JCacheCache、EhCache、GuavaCache的实现。  
这里我们先看下基于EhCache的使用，然后考虑<a target=_self href="/blog/2014/04/spring-cache-zhi-ehcache-he-memcached.html/#memcached">集成Memcached</a>；版本：spring3.2和spring4，EhCache2.7，spyMemcached2.8；  
内容还涉及HashMap、LinkedHashMap、synchronizedMap、ConcurrentHashMap、ReentrantLock……    
[参考资料：spring framework 4.0.x reference](http://docs.spring.io/spring/docs/4.0.x/spring-framework-reference/html/cache.html)<!--more-->  

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
至此配置完了，run一下，报错：没有序列化，将vo实现Serializable接口  
```java  
public class Notice implements Serializable {
```

标签：[spring](/blog/categories/spring)  

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
**问题**就在于object.hashCode()，看方法的参数string没问题，date没问题，Integer数组使用的就是Object类的hashCode是个内存地址，每次执行都变，要改用Arrays.hashCode(array)才不会变；  
当然，分页类page也要重写hashCode；顺便说下，apache的commons-lang.jar提供了EqualsBuilder、HashCodeBuilder、ToStringBuilder可用于重写各方法。还要**注意**：分页列表不仅要缓存list，还要缓存分页信息，这样到前端才会分页，否则是不知道这个list是多少页的，故方法的返回值（上面search方法只返回list是不行的）可采用类似```org.springframework.data.domain.Page```内部包含结果集  
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
		buffer.append(target.getClass().getName()).append(".");
		buffer.append(method.getName()).append(".");
		if (params.length > 0) {
			for (Object each : params) {
				if (each != null) {
					if (each instanceof Boolean || each instanceof Character || each instanceof Void
							|| each instanceof Short || each instanceof Byte || each instanceof Double
							|| each instanceof Float || each instanceof Integer || each instanceof Long) {
						buffer.append(each);
					} else if (each instanceof Object[]) {
						buffer.append(Arrays.hashCode((Object[]) each)); // 后面会说到可替换Arrays.deepHashCode
					} else if (each instanceof HttpServletRequest || each instanceof HttpServletResponse) {
						continue;
					} else {
						buffer.append(each.hashCode()); // list,map,set其内的元素类型一直才好
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

**问题**又出现了：不明确的key如何更新？例如search，当新添加一条记录后，就不能使用@CacheEvict(value="notice_cache", key="?")，因为取不到key，也不能模糊匹配；这种情况下只能使用@CacheEvict(value = "notice_cache", allEntries = true)，将notice_cache所有的缓存擦除，多少有点粗糙，而memcached甚至没有某个cache的removeAll，这就要自己写个MemcachedCache  

通常注解使用在service方法上，还有一个**注意事项**：因其使用aop的动态代理，对于内部调用无效，例如publish方法没加注解，内部调用update方法（加了@CachePut）更新状态值，但cache不会更新；controller方法（不加注解）调用service方法（加了注解）是可以；当然controller方法也可以加，需要单独处理，因为参数若有request、response之类，每次请求都变，就要在keyGenerator里做过滤了。  

二、<a name="memcached">集成Memcached</a>  
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

**MemcachedCacheManager**：   
```java 
public class MemcachedCacheManager extends AbstractCacheManager {
	// 注入memcachedClient（后面会有配置）
	private MemcachedClient client;

	public MemcachedCacheManager() {}

	public MemcachedCacheManager(MemcachedClient client) {
		this.client = client;
	}

	public void setClient(MemcachedClient client) {
		this.client = client;
	}
	
	// AbstractCacheManager.afterPropertiesSet不允许loadCaches返回空，所以覆盖掉
	public void afterPropertiesSet() {
	}

	protected Collection<? extends Cache> loadCaches() {
		return null;
	}

	// 根据名称获取cache，对应注解里的value如notice_cache，没有就创建并加入cache管理
	public Cache getCache(String name) {
		Cache cache = super.getCache(name);
		if (cache == null) {
			cache = new MemcachedCache(name, client);
			super.addCache(cache);
		}
		return cache;
	}
}
```
这样应用启动时实例化manager，在执行加缓存注解的的方法时，会调用getCache(获取或新建cache)，根据缓存的key从cache中取值（没有就读库，然后将结果加入cache，下次相同的key就能取到缓存的值了）  
要写MemcachedCache实现```org.springframework.cache.Cache```接口，先来分析**EhCacheCache**： 
```java
public class EhCacheCache implements Cache {
	// 使用Ehcache的cache，来做get,put,evict...，集成memcached就要使用memcachedClient
	private final Ehcache cache;

	/**
	 * Create an {@link EhCacheCache} instance.
	 * @param ehcache backing Ehcache instance
	 */
	public EhCacheCache(Ehcache ehcache) {
		Assert.notNull(ehcache, "Ehcache must not be null");
		Status status = ehcache.getStatus();
		Assert.isTrue(Status.STATUS_ALIVE.equals(status),
				"An 'alive' Ehcache is required - current cache is " + status.toString());
		this.cache = ehcache;
	}
	// 也就是ehcache.xml里配置的
	public String getName() {
		return this.cache.getName();
	}
	// 底层使用的cache，要改用memcachedClient
	public Ehcache getNativeCache() {
		return this.cache;
	}
	// 从cache取值，改用memcachedClient取值
	public ValueWrapper get(Object key) {
		Element element = this.cache.get(key);
		return (element != null ? new SimpleValueWrapper(element.getObjectValue()) : null);
	}
	// 改用memcachedClient存值
	public void put(Object key, Object value) {
		this.cache.put(new Element(key, value));
	}
	// 擦除delete
	public void evict(Object key) {
		this.cache.remove(key);
	}
	// 清空cache，这个是例如@CacheEvict(value = "notice_cache", allEntries = true)时调用的
	public void clear() {
		this.cache.removeAll();
	}
}
```
好了，来写memcachedCache，**问题来了**：  
1.clear方法，spy的client没有removeAll，clear之类的方法，有个flush是全部清空，服务器N多个cache都会擦掉  
2.@CacheEvict(value = "notice_cache", allEntries = true)就是用的clear，“添加个notice都要清掉其他非notice_cache缓存”就很可怕，能不能根据cache名称清除呢？  
3.上面两个实际是一个问题，memcached是key-value存储，所以要对key进行分组，采用一个集合保存key，然后将实际的key-value存入；如果想**模糊匹配**也是可行的，需要在此基础上做修改：key就得用字符串而不是字符串的hashCode了，或者自定义注解  

常用的集合数据类型如list，map，set它也支持，考虑到key的字符限制和单个value不超过1MB，使用一个set存储一个cache里所有的key能达到2万以上(看key的字节数)，使用压缩存储的更多，同时使用LRU（如LinkedHashMap，将过期的或长期不用的移除），基本满足使用  
标签：[memcached](/blog/categories/memcached)  

**MemcachedCache**：
```java
public class MemcachedCache implements Cache {
	private static final String PRESENT = new String();
	// 单个cache存储的key最大数量
	private static final int maxElements = 10000;
	// 默认过期时间10天
	private static final int expire = 10 * 24 * 60 * 60;
	private String name;
	private MemcachedClient client;
	// 存储key的集合，使用LinkedHashMap实现
	private KeySet keys;

	public MemcachedCache() {}

	public MemcachedCache(String name, MemcachedClient client) {
		this.name = name;
		this.client = client;
		this.keys = new KeySet(maxElements);
	}

	public String getName() {
		return this.name;
	}

	public Object getNativeCache() {
		return this.client;
	}
	// ckey是key+cacheName作为前缀，也是最终存入缓存的key
	public ValueWrapper get(Object key) {
		String ckey = toStringWithCacheName(key);
		if (keys.containsKey(ckey)) {
			Object value = client.get(ckey);
			return value != null ? new SimpleValueWrapper(value) : null;
		} else {
			return null;
		}
	}
	// 将ckey加入key集合并将ckey-value存入缓存
	public void put(Object key, Object value) {
		String ckey = toStringWithCacheName(key);
		keys.put(ckey, PRESENT);
		client.set(ckey, expire, value);
	}
	// 从keys集合清除ckey，并从缓存清除
	public void evict(Object key) {
		String ckey = toStringWithCacheName(key);
		keys.remove(ckey);
		client.delete(ckey);
	}

	private String toStringWithCacheName(Object obj) {
		return name + "." + String.valueOf(obj);
	}
	// 遍历清除
	public void clear() {
		for (String ckey : keys.keySet()) {
			client.delete(ckey);
		}
		keys.clear();
	}

	public MemcachedClient getClient() {
		return this.client;
	}

	public void setClient(MemcachedClient client) {
		this.client = client;
	}
	
	public KeySet getKeys() {
		return this.keys;
	}
}
```
这里keys也可以使用cacheName作为key存入缓存，就需要在put,evict,clear方法里使用```client.replace(name, expire, keys);```保持更新  

**KeySet**继承LinkedHashMap，为了使用removeEldestEntry，满了移除最旧元素，保持initSize:
```java
/**
 * 用于存储keys，容量到达上限移除最旧的，缓存也移除
 */
class KeySet extends LinkedHashMap<String, String> {
	private static final long serialVersionUID = 1L;
	private int maxSize;

	public KeySet(int initSize) {
		super(initSize, 0.75F, true);
		this.maxSize = initSize;
	}

	public boolean removeEldestEntry(Map.Entry<String, String> eldest) {
		boolean overflow = size() > this.maxSize;
		if (overflow) {
			MemcachedCache.this.client.delete(eldest.getKey());
		}
		return overflow;
	}
}
```

####3. 线程安全  
因为要存储keys，所以考虑使用哪种集合：HashSet\HashMap都不是线程安全的，例如[Java HashMap的死循环](http://coolshell.cn/articles/9606.html);  
安全的如Collections.synchronizedMap和ConcurrentHashMap（不允许value为null）；  
两者的区别是锁不同：synchronizedMap使用对象锁，相当于在方法上声明synchronized；ConcurrentHashMap比较复杂，在segment上加锁，将范围控制的很小，因而并发性能就高；  
这里使用LinkedHashMap，ConcurrentHashMap不好包装，synchronizedMap效率低，不如加个ReentrantLock，或者使用读写锁ReentrantReadWriteLock(但这篇文章介绍了读写锁可能存在问题：[小心LinkedHashMap的get()方法](http://skydream.iteye.com/blog/1562880))：  
```java
	lock.lock();
	try {
		client.set(...);
	} finally {
		lock.unlock();
	} 
```
下面是HashMap占用cpu 100% bug的代码：
```java
public class MapTest {
	public static void main(String[] args) throws InterruptedException {
		Map<String, String> temp = new HashMap<>(2);
		final Map<String, String> map = temp;
		//		final Map<String, String> map = new LinkedHashMap<>(temp);
		//		final Map<String, String> map = new ConcurrentHashMap<>(temp);
		//		final Map<String, String> map = Collections.synchronizedMap(temp);

		Thread t = new Thread(new Runnable() {
			public void run() {
				for (int i = 0; i < 10000; i++) {
					new Thread(new Runnable() {
						public void run() {
							map.put(UUID.randomUUID().toString(), "");
						}
					}).start();
				}
			}
		});
		t.start();
		t.join();
	}
}
```

####4. Spring 4.0.x Cache  
以上3.2.x使用正常，4.0版本改动了key生成器，源码也很简单：SimpleKeyGenerator和SimpleKey，toString方法将参数转为字符串，嫌长就改用hashCode  
```java
public class SimpleKeyGenerator implements KeyGenerator {
	@Override
	public Object generate(Object target, Method method, Object... params) {
		if (params.length == 0) {
			return SimpleKey.EMPTY;
		}
		if (params.length == 1 && params[0] != null) {
			return params[0];
		}
		return new SimpleKey(params);
	}
}
public final class SimpleKey implements Serializable {
	public static final SimpleKey EMPTY = new SimpleKey();
	private final Object[] params;

	/**
	 * Create a new {@link SimpleKey} instance.
	 * @param elements the elements of the key
	 */
	public SimpleKey(Object... elements) {
		Assert.notNull(elements, "Elements must not be null");
		this.params = new Object[elements.length];
		System.arraycopy(elements, 0, this.params, 0, elements.length);
	}

	public boolean equals(Object obj) {
		return (this == obj || (obj instanceof SimpleKey && Arrays.equals(this.params, ((SimpleKey) obj).params)));
	}

	public int hashCode() {
		return Arrays.hashCode(this.params);
	}

	public String toString() {
		return "SimpleKey [" + StringUtils.arrayToCommaDelimitedString(this.params) + "]";
	}
}
```

**事实上**，对于复杂的，类似Object数组（下面会有），那么无论是上面自定义keyGenerator还是spring4.0的都会有问题（hashCode和toString，不一致就取不到cache，会每次都读库），测试简单数组如下：
```java
	Integer[] array = new Integer[] { 1, 2, 3 };
	
	System.out.println(array); // [Ljava.lang.Integer;@5f4fcc96
	System.out.println(ObjectUtils.nullSafeToString(array)); // {1, 2, 3} 
	System.out.println(Arrays.toString(array)); // [1, 2, 3]
	System.out.println(Arrays.deepToString(array)); // [1, 2, 3]

	System.out.println(array.hashCode()); // 1599065238
	System.out.println(Arrays.hashCode(array)); // 30817 
	System.out.println(Arrays.deepHashCode(array)); // 30817
	System.out.println(Arrays.toString(array).hashCode()); // -412129978
	
	// StringUtils是spring的：org.springframework.util.StringUtils
	System.out.println(StringUtils.arrayToCommaDelimitedString(array)); // 1,2,3
	System.out.println(StringUtils.arrayToCommaDelimitedString(array).hashCode()); //46612798
```
这个测试Arrays.hashCode(array)和SimpleKey.toString()多次运行是一致的，也就是自定义keyGenerator和SimpleKeyGenerator正确  

**复杂的**：```Object[] mixed = new Object[] { 1, "11", array, list };```  
```java
	List<Integer> list = Lists.newArrayList(array);
	Object[] mixed = new Object[] { 1, "11", array, list };
	System.out.println(mixed); // [Ljava.lang.Object;@549f9afb
	System.out.println(ObjectUtils.nullSafeToString(mixed)); // {1, 11, [Ljava.lang.Integer;@5f4fcc96, [1, 2, 3]}
	System.out.println(Arrays.toString(mixed)); // [1, 11, [Ljava.lang.Integer;@5f4fcc96, [1, 2, 3]]
	System.out.println(Arrays.deepToString(mixed)); // [1, 11, [1, 2, 3], [1, 2, 3]]

	System.out.println(mixed.hashCode()); // 1419746043
	System.out.println(Arrays.hashCode(mixed)); // -1966094197
	System.out.println(Arrays.deepHashCode(mixed)); // 3446304
	System.out.println(Arrays.toString(mixed).hashCode()); // -691776533

	System.out.println(StringUtils.arrayToCommaDelimitedString(mixed)); // 1,11,[Ljava.lang.Integer;@5f4fcc96,[1, 2, 3]
	System.out.println(StringUtils.arrayToCommaDelimitedString(mixed).hashCode()); // 572153479
```
**结论**：多次运行发现只有Arrays.deepToString和Arrays.deepHashCode是一致的，也就是对每个元素，如果是数组再递归;同理，如果是集合list,set,map之类，最好使用泛型，类型一致，不要混合

三、总结  
----
spring cache用好要注意很多：  
1、搞清各注解意义和使用时机，逻辑正确，更新一致  
2、缓存key的使用很重要，自定义key要考虑参数重写hashCode和toString  
3、返回结果如分页结果集，不仅要有list还要有page  
4、可虑清楚并测试加了Cacheable确实生效？  
5、效益最大化：使用多注解多缓存的情景，一次方法执行缓存多个信息（要更新时也得多个更新，才能保持一致）  

