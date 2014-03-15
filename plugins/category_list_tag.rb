module Jekyll 
  class CategoryListTag < Liquid::Tag 
    def render(context) 
      html = "" 
      categories = context.registers[:site].categories.keys 
      categories.sort.each_with_index do |category, i| 
		tag_before, tag_after = '', ''
		tag_before = "<li>" if i%3 == 0
		tag_after = "</li>" if i%3 == 2
        posts_in_category = context.registers[:site].categories[category].size 
        category_dir = context.registers[:site].config['category_dir']
        category_url = File.join(category_dir, category.gsub(/_|\P{Word}/u, '-').gsub(/-{2,}/u, '-').downcase.to_url) 
        html << "#{tag_before}<a style=\"padding: 3px;\" href='/#{category_url}/'>#{category} (#{posts_in_category})</a>#{tag_after}\n" 
      end 
      html 
    end 
  end 
end

Liquid::Template.register_tag('category_list', Jekyll::CategoryListTag)
