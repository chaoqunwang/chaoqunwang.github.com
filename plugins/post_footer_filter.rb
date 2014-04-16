# encoding: utf-8
#
# post_footer_filter.rb
# Append every post some footer infomation like original url 
# Kevin Lynx
# 7.26.2012
#
require './plugins/post_filters'

module AppendFooterFilter
  def append(post)
     author = post.site.config['author']
     url = post.site.config['url']
     pre = post.site.config['original_url_pre']
#     post.content + %Q[<p class='post-footer'>
#            #{pre or 'original link:'}
#            <a href='#{post.full_url}'>#{post.full_url}</a><br/>
#            &nbsp;written by &nbsp;<a href='#{url}'>#{author}</a> &nbsp;posted at &nbsp;<a href='#{url}'>#{url}</a>
#            </p>]
	post.content.gsub(/<!--\s*more\s*-->/i, "<!--more--><a href='#{url}' style='color:white;text-decoration:none;'>#{author}</a>  ") + %Q[<p class='post-footer' style='background:none repeat scroll 0pt 0pt #eee;padding: 5px;margin-top:10px;color:gray;font-size:90%;'>
			&nbsp;#{pre or 'original link:'}
			<a href='#{post.full_url}'>#{post.full_url}</a><br/>
			&nbsp;written by &nbsp;<a href='#{url}'>#{author}</a> &nbsp;posted at &nbsp;<a href='#{url}'>#{url}</a><br/>
			&nbsp;版权声明：自由转载-非商用-非衍生-保持署名 | <a href='http://creativecommons.org/licenses/by-nc-nd/3.0/deed.zh'>Creative Commons BY-NC-ND 3.0</a></p>]
  end 
end

module Jekyll
  class AppendFooter < PostFilter
    include AppendFooterFilter
    def pre_render(post)
      post.content = append(post) if post.is_post?
    end
  end
end

Liquid::Template.register_filter AppendFooterFilter