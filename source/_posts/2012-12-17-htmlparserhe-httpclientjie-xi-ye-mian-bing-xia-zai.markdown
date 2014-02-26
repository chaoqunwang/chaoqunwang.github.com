---
layout: post
title: "htmlparser,jsoup和httpclient解析页面并下载"
date: 2012-12-17 11:05:41 -0800
comments: true
categories: tech java 代码
keywords: htmlparser jsoup httpclient
tags: htmlparser jsoup httpclient
description: htmlparser,jsoup和httpclient解析页面并下载
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
标签：[java](/blog/categories/java/)

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

###【更新】使用jsoup和4.3的httpclient（用的fluent的jar）  
``` java
	private static void initHttpClient() {
		int timeoutSeconds = 10;
		int poolSize = 20;
		RequestConfig config = RequestConfig.custom()
				.setSocketTimeout(timeoutSeconds * 1000)
				.setConnectTimeout(timeoutSeconds * 1000).build();
		httpClient = HttpClientBuilder.create().setMaxConnTotal(poolSize)
				.setMaxConnPerRoute(poolSize).setDefaultRequestConfig(config)
				.build();
	}
	
	/**
	 * 根据URL获得所有的html信息
	 */
	public static String getContent(String url) {
		String content = "";
		Executor executor = Executor.newInstance(httpClient);
		try {
			HttpResponse response = executor.execute(Request.Get(url))
					.returnResponse();
			int status = response.getStatusLine().getStatusCode();
			if (status >= HttpStatus.SC_BAD_REQUEST) {
				logger.error("error:" + status + ":" + url);
			} else {
				HttpEntity entity = response.getEntity();
				content = EntityUtils.toString(entity);
				logger.info("ok   :" + status + ":" + url);
			}
		} catch (Exception e) {
			logger.error(e.getMessage() + "\n" + url);
		}
		return content;
	}
```
jsoup获取[本博客](/)文章标题和链接  

``` java
		String html = getContent("http://wangchaoqun.com/blog/archives/");
		html = new String(html.getBytes("ISO-8859-1"), "UTF-8");
		if (StringUtils.isNotBlank(html)) {
			Document doc = Jsoup.parse(html);
			Elements hrefs = doc.select("div#blog-archives>article>h1>a");
			for (Element each : hrefs) {
				titles.add(each.text());
				links.add(each.attr("href"));
			}
		}
```



