require 'rubygems' 
require 'nokogiri'
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

    @title = @doc.css('title').first.content.split(':').last

    ignore_next_p = false 
    @doc.css('div[class*="content-main"] > div.promo > *').each do |el|
      break if el.node_name == 'div'

      if el.node_name == 'h2'
        if el.content =~ /description|method/i
          ignore_next_p = true
          next
        elsif el.content =~ /ingredients/i
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
    @doc = Nokogiri::HTML(open(url))
  end

  def to_txt
    results = @data 

    results.map! do |el|
      if el.node_name == 'h2'
        "#{el.content.strip}<br/><br/>"
      else
        el
      end
    end

    results = results.to_s.gsub(/<strong>|<\/strong>/, '<br/>')
    results = results.split(/<br\/*>/).map! {|i| i.strip.gsub(/<\/?[^>]*>/,'')}
    results.join("\n").strip
  end

  def for_iphone
    d = @data 
    results = []

    d.map! do |el|
      if el.node_name == 'h2'
        "#{el.content.strip}<br/><br/>"
      else
        el
      end
    end

    d = d.to_s.gsub(/<strong>/, '<br/>')
    d = d.split(/<br\/*>/).map! {|i| i.strip.gsub(/<\/?[^>]*>/,'')}

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

get('/shoppinglist') { 
  #response["Cache-Control"] = "max-age=86400, public" 
  begin
    @data = ShoppingList.new(params["r"])
    if iphone_request?
      content_type 'text/html', :charset => 'utf-8'
      erb :iphone
    else
      content_type 'text/plain', :charset => 'utf-8'
      @data.to_txt
    end 
  rescue OpenURI::HTTPError => e
    halt "Oo-la-la! there was something wrong with the URL you provided" 
  end
}

get('/') { 
  #response["Cache-Control"] = "max-age=86400, public" 
  content_type 'text/plain', :charset => 'utf-8'
  <<EOF
Shopping List
-------------

This app attempts to take a BBC Recipe url from http://XXX and convert it
into a list of ingedients that can be viewed on your phone, specifically
the iPhone because that's what I've got.

http://#{request.env['HTTP_HOST']}/shoppinglist?r=

EOF
}
