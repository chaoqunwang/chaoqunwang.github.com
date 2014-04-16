---
layout: post
title: "多线程Synchronized同步总结"
date: 2011-03-17 11:03:31 +0800
comments: true
categories: tech java 多线程
keywords: java 多线程 代码
tags: 多线程
description: 多线程Synchronized同步总结
---
synchronized 关键字，代表这个方法加锁，相当于不管哪一个线程（例如线程A），运行到这个方法时，都要检查有没有其它线程B（或者C、 D等）正在用这个方法，有的话要等正在使用synchronized方法的线程B（或者C 、D）运行完这个方法后再运行此线程A；没有的话，直接运行。  
它可以用来同步方法，代码块；可以用在方法声明（静态方法、非静态方法），也可以传参；
对象锁需要注意是否会造成一个方法执行，其他方法也要等待的情况（将整个对象都上锁，而不允许其他线程短暂地使用对象中其他同步方法来访问共享资源），所以要注意锁的不同   <!--more-->

1、同步的静态方法，影响类内  
```java
public static synchronized void method() {
	...
} 
等同于 
public static void method() {
	synchronized(ThisClazz.class){
		...
	}
}
或者
private static final String lock = "";
public static void method() {
	synchronized(lock){
		...
	}
}
```

2、同步的非静态方法，影响实例内  
```java
public synchronized void method() {
	...
} 
等同于 
public void method() {
	synchronized(this){
		...
	}
}
或者
private String lock = new String("");
public void method() {
	synchronized(lock){
		...
	}
}
```
标签：[多线程](/blog/categories/duo-xian-cheng/)  
测试示例：  
```java
public class SynThreadTest extends Thread {
	public String methodName;
	private String sync1 = "111";// 不同于 new String("");
	private static String sync2 = "222";
	private String sync3 = "" + new Random().nextInt(1000);

	public static void method(String s) {
		System.out.println(s);
		while (true) {
			;
		}
	}

	public synchronized void method1() {
		method("syn非静态的method1方法，实例内非静态syn方法互斥");
	}

	public synchronized void method2() {
		method("syn非静态的method2方法，实例内非静态syn方法互斥");
	}

	public static synchronized void method3() {
		method("syn静态的method3方法，类级别静态syn方法互斥");
	}

	public static synchronized void method4() {
		method("syn静态的method4方法，类级别静态syn方法互斥");
	}

	public void method5() {
		method("---非静态的method5方法，非syn无锁");
	}

	public static void method6() {
		method("---静态的method6方法，非syn无锁");
	}

	public static void method7() {
		synchronized (sync2) {
			method("method7方法，类级别静态相同syn obj互斥");
		}
	}

	public void method8() {
		synchronized (this + "123") {
			method("method8方法，不同实例不同syn obj");
		}
	}

	public void method9() {
		synchronized (sync1) {
			method("非静态的method9方法，不同实例相同syn obj");
		}
	}

	public void method10() {
		synchronized (sync3) {
			method("method10方法，不同实例不同syn obj");
		}
	}

	public void run() {
		try {
			getClass().getMethod(methodName).invoke(this);
		} catch (Exception e) {}
	}

	public static void main(String[] args) throws Exception {
		SynThreadTest t1 = new SynThreadTest();
		for (int i = 1; i <= 10; i++) {
			t1.methodName = "method" + String.valueOf(i);
			new Thread(t1).start();
			sleep(100);
		}
		System.out.println();
		SynThreadTest t2 = new SynThreadTest();
		for (int i = 1; i <= 10; i++) {
			t2.methodName = "method" + String.valueOf(i);
			new Thread(t2).start();
			sleep(100);
		}
	}
}
```
