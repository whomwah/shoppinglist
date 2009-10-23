require 'rubygems' 
require 'nokogiri'
require 'open-uri'

class ShoppingList

  def initialize(r)
    @doc = nil
    @output = [] 

    build_shopping_list(r)
  end

  def build_shopping_list(r)
    # fetch the html page
    fetch_recipe(r) 

    # turn the HTML into a usable string 
    build_output
  end

  def build_output 
    # I'm sure this could be done better, but it works
    d = @doc.css('div[class*="content-main"] > div.promo > p')[0].to_s
    d = d.gsub(/<strong>|<\/strong>/, '<br>')
    items = d.split('<br>').map! {|i| i.gsub(/<\/?[^>]*>/,'')}
    @output << items[1...items.length] 
  end

  def fetch_recipe(url) 
    @doc = Nokogiri::HTML(open(url))
  end

  def to_txt
    @output.join("\n")
  end

end

get('/shoppinglist') { 
  response["Cache-Control"] = "max-age=86400, public" 
  content_type 'text/plain', :charset => 'utf-8'
  if r = ShoppingList.new(params["r"])
    r.to_txt
  else
    "Oops, something went wrong"
  end
}

get('/') { 
  response["Cache-Control"] = "max-age=86400, public" 
  content_type 'text/plain', :charset => 'utf-8'
  <<EOF
Shopping List
-------------

Find tips for your garden any day of the year. You can subscribe to
with the complete planner, or with optional sections listed at the bottom:

http://#{request.env['HTTP_HOST']}/shoppinglist?r=

EOF
}
