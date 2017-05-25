<!DOCTYPE html>
<!--[if IEMobile 7 ]><html class="no-js iem7"><![endif]-->
<!--[if lt IE 9]><html class="no-js lte-ie8"><![endif]-->
<!--[if (gt IE 8)|(gt IEMobile 7)|!(IEMobile)|!(IE)]><!--><html class="no-js" lang="en"><!--<![endif]-->
<head>
  <meta charset="utf-8">
  <title>超群的博客</title>
  <meta name="author" content="wang chaoqun">
  <meta name="description" content="超群的博客, 生活记录, 技术博客, wang chaoqun, colalife.com, wangchaoqun.com, wangchaoqun.cn">
  <meta name="keywords" content="超群的博客, 生活记录, 技术博客, 开源技术, 大数据, 云计算, 移动互联网以及java, web, mobile, android, ios, linux, tomcat, httpd, browser, internet, media, sql, news">

  <!-- http://t.co/dKP3o1e -->
  <meta name="HandheldFriendly" content="True">
  <meta name="MobileOptimized" content="320">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  
  <link id="currentUrl" rel="canonical" href="http://wangchaoqun.com/index.html">
  <link href="/favicon.png" rel="icon">
  <link href="/stylesheets/screen.css" media="screen, projection" rel="stylesheet" type="text/css">
  <!--<link href="http://bcs.duapp.com/colalife2000/stylesheets/screen.css" media="screen, projection" rel="stylesheet" type="text/css">-->
  
  <!--Fonts from Google"s Web font directory at http://google.com/webfonts -->
  <!--<link href="http://fonts.googleapis.com/css?family=PT+Serif:regular,italic,bold,bolditalic" rel="stylesheet" type="text/css">
  <link href="http://fonts.googleapis.com/css?family=PT+Sans:regular,italic,bold,bolditalic" rel="stylesheet" type="text/css">-->
  <!--
  <link href="http://bcs.duapp.com/colalife2000/stylesheets/PTSans.css" rel="stylesheet" type="text/css">
  <link href="http://bcs.duapp.com/colalife2000/stylesheets/PTSerif.css" rel="stylesheet" type="text/css">  
  -->
  <link href="/stylesheets/PTSans.css" rel="stylesheet" type="text/css">
  <link href="/stylesheets/PTSerif.css" rel="stylesheet" type="text/css">
  
  <link href="/atom.xml" rel="alternate" title="超群的博客" type="application/atom+xml">
  
  <script src="/javascripts/modernizr-2.0.js"></script>
  <!--<script src="http://bcs.duapp.com/colalife2000/javascripts/modernizr-2.0.js"></script>-->
  
  <!--<script src="//ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>-->
  <!--<script src="//code.jquery.com/jquery-1.9.1.min.js"></script>-->
  <!--<script src="//ajax.aspnetcdn.com/ajax/jquery/jquery-1.9.1.min.js"></script>-->
  <!--<script src="//libs.baidu.com/jquery/1.9.1/jquery.min.js"></script>-->
  <script src="http://cdn.bootcss.com/jquery/1.9.1/jquery.min.js"></script>
  <script>!window.jQuery && document.write(unescape('%3Cscript src="./javascripts/libs/jquery.min.js"%3E%3C/script%3E'))</script>
  
  <script src="/javascripts/octopress.js" type="text/javascript"></script>
  <!--<script src="http://bcs.duapp.com/colalife2000/javascripts/octopress.js" type="text/javascript"></script>-->
  
  <style>html{display:none;}</style>
<script>
	if (self == top) {
		document.documentElement.style.display = 'block';
	} else {
		top.location = self.location;
	}
</script>
<script language="javascript" type="text/javascript">
$(document).ready(function(){
	changeBg();
	//window.setInterval("changeBg()", 30*1000);
	
	var error404=$("#currentUrl").attr("href");
	if(error404.indexOf("/404.html")!=-1){
		window.setTimeout("document.location='/';", 5*1000);
	}
	
	$(document).bind('DOMNodeInserted', function(event) {
		addBlankTargetForLinks();
	});
/*
	var wangchaoqun_com="wangchaoqun.com";
	var wangchaoqun_cn="wangchaoqun.cn";
	var colalife_com="colalife.com";
	if(ref.indexOf(colalife_com)!=-1){
	  ref=ref.replace(colalife_com, wangchaoqun_com);
	  window.location.replace(ref);
	} else if(ref.indexOf(wangchaoqun_cn)!=-1){
	  ref=ref.replace(wangchaoqun_cn, wangchaoqun_com);
	  window.location.replace(ref);
	}
*/
});
function changeBg() {
	var dir = "/images/"
	var image = "url("+dir+"yh"+Math.floor(Math.random()*5+1)+".jpg)";
	$("#myheader").css({"background-image":image});
}
function addBlankTargetForLinks () {
  $('a[href^="http"]').each(function(){
      $(this).attr('target', '_blank');
  });
}
</script>

<script type="text/javascript" src="http://tajs.qq.com/stats?sId=58901991" charset="UTF-8"></script>

</head>

<body>
<script>
var _hmt = _hmt || [];
(function() {
  var hm = document.createElement("script");
  hm.src = "https://hm.baidu.com/hm.js?797329c568be20db359cbd9ec9c534b7";
  var s = document.getElementsByTagName("script")[0]; 
  s.parentNode.insertBefore(hm, s);
})();
</script>
</body>
</html>
