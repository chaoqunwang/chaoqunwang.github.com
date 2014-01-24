---
layout: post
title: "测试Hibernate动态添加实体类"
date: 2012-09-27 15:54:33 -0800
comments: true
categories: tech java hibernate
keywords: 
tags: hibernate sessionfactory spring-test
description: 
---
大家知道通过hibernate cfg或和spring集成的配置里，可用packagesToScan或mapping*之类声明实体类；但有需求可能要在某个项目中编码式加载实体类（例如某个不常用的或特定用户的实体类，并未事先配置），然后进行增删改查操作。下面代码配合spring test framework做了测试（注：hibernate升级到了4.3.final，与4.2有不同，spring3或4测试通过）：<!--more-->
```java
@RunWith(SpringJUnit4ClassRunner.class)
@ContextConfiguration(locations = { "/spring-hibernate.xml" })
public class ConfigurationTest extends AbstractJUnit4SpringContextTests {
    public static final String session_factory = "sessionFactory";
	// 值得注意: org.springframework.beans.factory.FactoryBean that creates a Hibernate org.hibernate.SessionFactory
	public static final String local_session_factory = "&sessionFactory";

	@Test
	public void sessionFactoryAndFactoryBean() throws ClassNotFoundException {
		SessionFactory sessionFactory = (SessionFactory) applicationContext.getBean(session_factory);
		Map<String, ClassMetadata> meta = sessionFactory.getAllClassMetadata();
		for (Entry<String, ClassMetadata> each : meta.entrySet()) {
			ClassMetadata value = each.getValue();
			System.out.println("entity name:" + value.getEntityName());
		}

		LocalSessionFactoryBean sessionFactoryBean = (LocalSessionFactoryBean) applicationContext.getBean(local_session_factory);

		Configuration config = sessionFactoryBean.getConfiguration();
		config.addAnnotatedClass(User.class);
		ServiceRegistry serviceRegistry = new StandardServiceRegistryBuilder().applySettings(config.getProperties()).build();
		SessionFactory newSessionFactory = config.buildSessionFactory(serviceRegistry);
		Session session = newSessionFactory.openSession();

		User user = new User();
		user.setName("username");
		session.save(user);
		session.flush();

		user = (User) session.get(User.class, user.getId());
		session.close();
		System.out.println("------" + user.getId());
		System.out.println("------" + user.getName());

		Iterator<Table> mappings = config.getTableMappings();
		while (mappings.hasNext()) {
			Table each = mappings.next();
			System.out.println("table name:" + each.getName());
		}

	}
}
```
