---
layout: post
title: "htmlparser和httpclient解析页面并下载"
date: 2012-12-17 11:05:41 -0800
comments: true
categories: java 代码
keywords: htmlparser jsoup httpclient
tags: htmlparser jsoup httpclient
description: 
---
如果你想抓取某个网页（如新浪、csdn之类）获取最新资讯列表，或者到某个站点下载文件、图片之类，就需要html解析例如htmlparser,jsoup之类的jar包，下载可用httpclient。如果想更高效率可以搞线程池，抓取解析线程和下载线程，类似消费者和生产者模型（此处不涉及，仅演示使用），代码如下：  
<!--more-->
```java
    public static Set<String> digLinks(String address) throws Exception {
		Set<String> result = new HashSet<String>();
		URL url = new URL(address);
		Parser parser = new Parser((HttpURLConnection) url.openConnection());
		NodeFilter filter = new HasAttributeFilter("id", "someid");
		NodeList nodes = parser.extractAllNodesThatMatch(filter);
		Node root = nodes.elementAt(0);
		String html = root.getChildren().toHtml();
		parser = Parser.createParser(html, "utf-8");
		nodes = parser.extractAllNodesThatMatch(new TagNameFilter("li"));
		parser = Parser.createParser(html, "utf-8");
		nodes = parser.extractAllNodesThatMatch(new TagNameFilter("a"));
		add(result, nodes);
		return result;
	}

	private static void add(Set<String> result, NodeList nodes) {
		for (int i = 0; i < nodes.size(); i++) {
			Node child = nodes.elementAt(i);
			if (child instanceof LinkTag) {
				LinkTag linknode = (LinkTag) child;
				String href = linknode.getLink();
				result.add(href);
			}
		}
	}

```
httpclient 下载  
----
```java
    /**
	 * 读出文件中的url，连接下载保存
	 * @param file
	 */
	public static void doSave(String file) {
		List<String> files = FileUtil.readLines(file);
		for (String url : files) {
			String fileName = StringUtils.substringAfterLast(url, "/");
			download(url, fileName);
		}
	}

	private static void download(String url, String fileName) {
		OutputStream out = null;
		InputStream in = null;
		HttpURLConnection connection = null;
		URL server = null;
		try {
			server = new URL(url);
			connection = (HttpURLConnection) server.openConnection();
			connection.connect();
			in = connection.getInputStream();

			File file = new File(dir + fileName);
			if (file.exists()) {
				return;
			}
			out = new FileOutputStream(file);
			int b = in.read();
			while (b != -1) {
				out.write(b);
				b = in.read();
			}
			in.close();
			out.close();
		} catch (Exception e) {
		}
	}

```

