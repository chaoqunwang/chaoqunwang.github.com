---
layout: post
title: "[转]深入理解浏览器兼容性模式"
date: 2012-11-01 09:27:53 -0800
comments: true
categories: web
keywords: 
description: 
---
web开发人员遇到浏览器兼容简直就是噩梦，尤其各种ie内核的浏览器，还有搜狗、360等；这篇文章讲得比较详细，转了<a href="http://www.ituring.com.cn/article/15231" target="_blank">来自图灵社区</a>  
正文 ----  
关于各种浏览器模式，网上已经有许多文档和资料了，但是很少有能够完全将几个概念阐述清楚的。大部分的资料稍显过时，有些内容可能已经不再适用了。本文中笔者将尽可能将几个概念阐述清楚，并去掉一些过时的内容，仅保留必要的干货。<!--more-->

想必你一定知道浏览器有个标准（Standards）模式和一个怪异（Quirks）模式，或许你还听说过有个“准标准（Almost Standards）”模式。而当你打开 Internet Explorer 的时候，又看到了什么浏览器模式、文档模式，还有什么兼容性视图等等...

这些都是什么？啥是浏览器模式，啥是文档模式？标准模式和准标准的模式有什么区别？IE9兼容性视图和真正的IE9有什么区别？什么情况下会触发这些模式，又该怎样才能检测到浏览器当前处于哪种模式中呢？本文将详细为你解答这些疑问。

###三种模式

首先我们要知道，为什么会有这么多模式。其实这是个历史遗留问题，在浏览器大战时期，网景浏览器（Netscape Navigator）和微软的IE浏览器（Microsoft Internet Explorer）对网页分别有不同的实现方式，那个时候的网页要针对这两种浏览器分别开发不同的版本。而到了 W3C 制定标准之后，这些浏览器就不能继续使用这种页面了，因而会导致大部分现有站点都不能使用。基于这个原因，浏览器才引入两种模式来处理一些遗留的站点。

现在的浏览器排版引擎支持三种模式：怪异（Quirks）模式、准标准（Almost Standards）和标准（Standards）模式。在怪异模式中，排版引擎会模拟 网景4 和 Windows 中的 IE5 的行为；在完全标准的模式中，会尽量执行 HTML 和 CSS 规范所指定的行为；而在准标准模式中，则只包含很少的一部分怪异模式中的行为。

那么所谓标准模式，就一定都“标准”吗？答案当然是否定的，因为各个浏览器厂商实现标准的阶段不同，所以各个浏览器的“标准模式”之间也会有很大的不同。

Firefox、Safari、Chrome、Opera (自 7.5 以后)、 IE8 和 IE9 都有一个准标准模式。那么既然标准模式都不那么标准，准标准的模式肯定就更不标准了。最初的准标准模式只会影响表格中的图像，而后来各个浏览器又或多或少地进行了修改。那么什么情况下会触发准标准模式呢？是的，正如你所想到的，某些 DOCTYPE 会触发准标准模式，例如：
```
"-//W3C//DTD XHTML 1.0 Transitional//EN"
"-//W3C//DTD XHTML 1.0 Frameset//EN"
"-//W3C//DTD HTML 4.01 Transitional//EN"
"-//W3C//DTD HTML 4.01 Frameset//EN"
"http://www.ibm.com/data/dtd/v11/ibmxhtml1-transitional.dtd"  
```
一个完整的 DOCTYPE 例子如下：

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
                      "http://www.w3.org/TR/html4/loose.dtd">
如果在 Firefox 中插入这种 DOCTYPE，并在页面中插入一个空的 span 标签，那么在 Firebug 中查看元素的布局就会发现不同：

准标准模式中元素的 line-height 被忽略了，元素既没有宽度也没有高度：

Almost Standards

标准模式中元素仍然保留了 line-height，拥有 18px 的高度：

Standards

在 Firefox 浏览器中，使用鼠标右键 -> 查看页面信息 可以看到当前浏览器运行在何种模式（只能看到“混杂模式”和“标准规范模式”两种表示）：

mozilla-standard-mode

有位大神 Henri Sivonen 曾写过一篇文章叫做 Activating Browser Modes with Doctype，里面包含了一个完整的表格，展示了各种 DOCTYPE 设置将会使浏览器以何种方式渲染。这里还有一篇 秦歌 的译文 《用doctype激活浏览器模式》。

鉴于目前一些最新版本的浏览器已经放弃了准标准模式，所以关于准标准模式的细节这里就不再赘述了，感兴趣的同学可以详细阅读以下资料：

Gecko's "Almost Standards" Mode

Line Height Calculations in Almost Standards Mode

Images, Tables, and Mysterious Gaps

almost-standards test

DOCTYPE Switches support in Opera Presto 2.10

那么，既然这么多的 DOCTYPE 都会触发非标准的模式，那么如何才能触发标准模式呢？对了！要使用 HTML5 DOCTYPE，即：

<!DOCTYPE html>
注意：如果文档中没有包含 DOCTYPE 或者包含了一个无法识别的 DOCTYPE，则浏览器就会进入怪异模式。

下面简单说一下怪异模式。怪异模式有许多“怪异”的行为，主要是为了兼容那些遗留的古老页面而保留的模式。不同浏览器的怪异模式也不尽相同，它们都有自己的实现方式。怪异模式与标准模式的差异主要体现在 盒模型（box model）、表格单元格高度的处理等。例如 IE 的怪异模式中，元素的 width 包含了 padding 和 border，而标准模式中 padding 和 border 并不属于宽度的一部分。

若想详细了解浏览器在怪异模式下的行为，可以参看下面两篇文章。不过不建议在这上面花太多的精力，这是个历史遗留问题，而且我们也尽量保证新开发的页面不要进入到怪异模式：

Mozilla Quirks Mode Behavior

What happens in Quirks Mode?

Compatability Mode Test

_小结_： 至此我们需要了解，浏览器有三种运行模式，即标准模式、准标准模式和怪异模式，要使用 <!DOCTYPE html> 来正确地触发标准模式。千万不要丢掉 DOCTYPE 声明，因为这会导致浏览器进入怪异模式。

###IE的浏览器模式

IE8有4种模式：IE5.5怪异模式、IE7标准模式、IE8 准标准模式和IE8标准模式，而IE9有7种模式: IE5.5怪异模式、IE7标准模式、IE8准标准模式、IE8标准模式、IE9准标准模式、IE9标准模式、XML模式。

其中 XML模式 是针对 XML 文档的，这里不打算阐述，细节可以看这篇文章[Defining Document Compatibility](http://msdn.microsoft.com/en-us/library/cc288325(v=vs.85).aspx) 中有详细阐述。

在 IE8 及以后的的 IE 浏览器中，支持 X-UA-Compatible 头，可以通过在服务器端设置 HTTP 头，或者在页面中插入 <meta> 标签来实现：
```
HTTP:
Header set X-UA-Compatible "IE=8"

Meta:
<meta http-equiv="X-UA-Compatible" content="IE=EmulateIE7" />
```
这种方法主要是防止老的页面在较新的浏览器中显示不正常的情况的， 比如上面的代码可以强制 IE8 以上版本的浏览器以IE7的模式进行渲染。

注意，不要在新开发的网页中使用这种技术，这种技术只应该作为新老网页更替过程中的过渡方案。由于目前新开发的网页都是尽量支持最新版本的浏览器的，所以这种技术也会慢慢被淘汰，感兴趣的同学可以详细阅读 微软的这篇文档。

_小结_： 这里我们需要知道有这种方式可以强制浏览器以某种模式运行，但只应作为过渡方案，不应在新开发的网页中使用。

###IE9 兼容性视图 与 IE9 标准视图

如果你使用的是 IE9，那么按下 F12 键就会出现开发者工具，上面有两个下拉菜单：浏览器模式 和 文档模式。那么什么是浏览器模式？什么又是文档模式？二者有何区别？

浏览器模式用于切换IE针对该网页的默认文档模式、对不同版本浏览器的条件注释解析、以及发送给网站服务器的用户代理（User-Agent）字符串的值。网站可以根据浏览器返回的不同用户代理字符串判断浏览器的版本和及安装的功能，这样就可以根据不同的浏览器返回不同的页面内容了。

文档模式用于指定IE的页面排版引擎（Trident）以哪个版本的方式来解析并渲染网页代码。切换文档模式会导致网页被刷新，但不会更改用户代理字符串中的版本号，也不会从服务器重新下载网页。切换浏览器模式的同时，浏览器也会自动切换到相应的文档模式。

一言以蔽之，浏览器模式会影响服务器端对客户端浏览器版本的判断，对条件注释也有影响；而文档模式会影响IE的排版引擎，对网页渲染会有影响，对 CSS hack 也会产生影响。因此，通过条件注释可以判断浏览器模式，而使用 CSS hack 可以判断文档模式。

如果我们使用一句简单的 JavaScript 语句来查看用户代理（User-Agent）字符串的值，则可以看到 IE9 兼容性视图 与 IE9 的区别：
```
<script type="text/javascript">
    alert('UA:'+navigator.userAgent);
</script>
```
输出结果如下所示，注意其中的 MSIE 版本号已经不同。判断浏览器模式就是判断 User-Agent 中的版本号，即 MSIE 后面的数值：

// IE9
UA:Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Trident/5.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; .NET4.0C; .NET4.0E; Tablet PC 2.0)

// IE9 兼容性视图
UA:Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; Trident/5.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; .NET4.0C; .NET4.0E; Tablet PC 2.0)
话说 IE9 兼容性视图 是模拟IE7的行为，那么 IE9 兼容性视图 与 IE7 有没有区别呢？肯定是有区别的，即使是 IE9 中的 IE7标准模式，与原生的IE7在渲染上也是有区别的，具体我们暂不去深究。

那么既然 IE9 兼容性视图 的版本号跟 IE7 相同，如何才能判断当前是 IE9 兼容性视图，还是纯正的 IE7 呢？其实很简单，只需要判断浏览器的用户代理（User-Agent）字符串中是否包含 Trident 即可。首先检测 MSIE 的版本号是否为 7.0，然后再判断是否含有 Trident 字串，若包含则为 IE9 兼容性视图，否则则为纯正的 IE7。

_小结_： 至此，你应该了解了什么是浏览器模式、什么是文档模式以及它们之间的区别了，另外还了解了 IE9 兼容性视图 与 IE9 以及 IE7 的区别。

###控制默认的渲染方式

当 Internet Explorer 9 遇到未包含 X-UA-Compatible 标头的网页时，它将使用 <!DOCTYPE> 指令来确定如何显示该网页。 如果该指令丢失或未指定基于标准的文档类型，则 Internet Explorer 9 将以 IE5 模式（怪异模式）来显示该网页。

如果 <!DOCTYPE> 指令指定了基于标准的文档类型，则 Internet Explorer 9 将以 IE9 模式显示该网页，但出现以下情况时除外：

为该网页启用了兼容性视图。
该网页是在 Intranet 区域中加载的，并且已将 Internet Explorer 9 配置为使用兼容性视图来显示 Intranet 区域中的网页。
已将 Internet Explorer 9 配置为使用兼容性视图来显示所有网站。
已将 Internet Explorer 9 配置为使用兼容性视图列表（其实是个黑名单，其中指定了一组始终使用兼容性视图显示的网站）。
已使用开发人员工具覆盖在该网页中指定的设置。
该网页遇到了页面布局错误，并且已将 Internet Explorer 9 配置为，通过在兼容性视图中重新打开网页来自动从此类错误中恢复。
此外，可以使用下面的注册表项来控制 Internet Explorer 对未包含 X-UA-Compatible 标头的页面的处理方式。
```
HKEY_LOCAL_MACHINE (or HKEY_CURRENT_USER)
     SOFTWARE
          Microsoft
               Internet Explorer
                    Main
                         FeatureControl
                              FEATURE_BROWSER_EMULATION
                                   iexplore.exe = (DWORD)  
```
其中 DWORD 值必须等于下列值之一：

值    说明
7000	包含基于标准的 <!DOCTYPE> 指令的页面将以 IE7 模式显示。
8000	包含基于标准的 <!DOCTYPE> 指令的页面以 IE8 模式显示。
8888	页面始终以 IE8 模式显示，而不考虑 <!DOCTYPE> 指令。 （这可绕过前面列出的例外情况。）
关于IE浏览器确定文档模式的整个流程，可以参看这篇文章 How IE8 Determines Document Mode，文中详细阐述了整个流程与内部机制。

_小结_： 仍然坚持使用 <!DOCTYPE html>，可最大程度减小发生错误的几率。

###文档模式的检测

在 JavaScript 中可以通过 documentMode 来检测文档模式，在 IE6 和 IE7 中是使用 compatMode 来确定文档模式的，这个属性自 IE8 开始已经被 documentMode 所替代。

那么，如果需要兼容 IE6 和 IE7 的话（必须的 ...），则相应的检测代码大致如下：
```
engine = null;
if (window.navigator.appName == "Microsoft Internet Explorer")
{
   // This is an IE browser. What mode is the engine in?
   if (document.documentMode) // IE8 or later
      engine = document.documentMode;
   else // IE 5-7
   {
      engine = 5; // Assume quirks mode unless proven otherwise
      if (document.compatMode)
      {
         if (document.compatMode == "CSS1Compat")
            engine = 7; // standards mode
      }
      // There is no test for IE6 standards mode because that mode
      // was replaced by IE7 standards mode; there is no emulation.
   }
   // the engine variable now contains the document compatibility mode.
}
```
IE6 和 IE7 中的 compatMode 有两个可能的值“CSS1Compat”和“BackCompat ”，分别对应了 IE6 和 IE7 中的标准模式和怪异模式。上面的代码首先假定是怪异模式，然后再试图推翻假设。这里没有包含“IE6 标准模式”，因为它已经被 IE7标准模式 所替代，没有模拟的情况。

这里要注意，不同的文档模式对 JavaScript 也有一些影响，我们不必去深究不同文档模式对 JavaScript 有何种不同影响，只需要在编码时进行特定的 特性检测 即可。

_小结_： 一般情况下是没必要进行文档模式检测的，对于样式兼容我们可以写 CSS hack，而对于 JavaScript 来说，则更加推荐特性检测，而不是检测浏览器本身。

###浏览器模式与文档模式之间的关系

浏览器模式可以决定页面默认的文档模式，但文档模式可能会受其他因素影响而改变，如上文所述。如果浏览器模式与文档模式设置不同的话，会不会有什么影响呢？

我们已经知道浏览器模式主要用于标识浏览器本身，原则上不会对页面渲染产生影响。但是我们又知道，浏览器模式可以影响条件注释，所以如果你的页面中有条件注释的话，那么浏览器模式的变化就会影响到页面渲染。

服务器端只能通过浏览器模式所标识的版本来确定客户端浏览器的版本，如果你将浏览器模式标识为IE9，但文档模式选择为IE7标准的话，就可能会有问题。不过这还要看服务器端是否有针对不同浏览器的处理策略，如果服务器端并未对不同浏览器的输出做差异化处理的话，那么这两个模式选项不同就不会有问题。

_小结_： 如果服务器端对不同浏览器的输出做了差异化处理，那么浏览器模式和文档模式不一致就可能产生问题。
