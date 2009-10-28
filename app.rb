require 'rubygems' 
require 'hpricot'
require 'open-uri'
require 'sinatra'
require 'erb'

helpers do
  def iphone_request?
    (agent = request.env["HTTP_USER_AGENT"]) &&
    agent[/(Mobile\/.+Safari)/]
  end
end

class ShoppingList
  attr_reader :title

  def initialize(r)
    @doc = nil
    @data = [] 
    @title = nil 

    build_shopping_list(r)
  end

  def build_shopping_list(r)
    # fetch the html page
    fetch_recipe(r) 

    # turn the HTML into a usable string 
    build_output
  end

  def build_output 
    items = []

    # The pages are so badly marked up this is really
    # hoping for the best. Hopefully it exposes the
    # need for these pages to be fixed. Here I'm just storing
    # a loose data structure 

    @title = (@doc/'title').inner_html.split(':').last.strip

    ignore_next_p = false 
    (@doc/'div.content-main > div.promo > *').each do |el|
      next if el.inner_text.strip == ''
      break if el.name == 'div' || el.comment?

      if el.name == 'h2'
        if el.inner_text =~ /description|method/i
          ignore_next_p = true
          next
        elsif el.inner_text =~ /ingredients/i
          next
        end
      end

      if ignore_next_p
        ignore_next_p = false
        next
      else
        items <<  el
      end
    end

    @data = items 
  end

  def fetch_recipe(url) 
    @doc = Hpricot(open(url))
  end

  def for_html
    d = @data 
    results = []

    d.map! do |el|
      if el.name == 'h2'
        "#{el.strip}<br/><br/>"
      else
        el
      end
    end


    d = d.to_s.gsub(/<strong>/, '<br/>')
    d = d.split(/<br\s*\/*>/).map! {|i| i.strip.gsub(/<\/?[^>]*>/,'')}

    has_blank = false 
    d.each do |item|
      if item == ''
        has_blank = true 
        next
      end

      if has_blank
        has_blank = false
        results << {
          :is_heading => true,
          :content => item.gsub(':','').strip
        } 
      else
        results << {
          :content => item.strip
        } 
      end
    end

    results
  end

end

get('/list') { 
  #response["Cache-Control"] = "max-age=86400, public" 
  content_type 'text/html', :charset => 'utf-8'
  begin
    @data = ShoppingList.new(params["r"])
    if iphone_request?
      erb :iphone
    else
      erb :html
    end 
  rescue OpenURI::HTTPError => e
    halt "Oo-la-la! there was something wrong with the URL you provided" 
  end
}

get('/') { 
  #response["Cache-Control"] = "max-age=86400, public" 
  content_type 'text/html', :charset => 'utf-8'
  erb :index
}
