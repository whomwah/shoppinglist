require 'rubygems' 
require 'nokogiri'
require 'open-uri'
require 'sinatra'

SL_URI = "http://localhost/~duncan/sl1.shtml"

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
    items = []

    # The pages are so badly marked up this is really
    # hoping for the best. Hopefully it exposes the
    # need for these pages to be fixed 

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

    # now attempt to clean up whats left
    items.map! do |el|
      if el.node_name == 'h2'
        "#{el.content.strip}<br/><br/>"
      else
        el
      end
    end

    # now convert into a string and replace the br's with \n's
    results = items.to_s.gsub(/<strong>|<\/strong>/, '<br/>')
    results = results.split(/<br\/*>/).map! {|i| i.strip.gsub(/<\/?[^>]*>/,'')}

    @output << results 
  end

  def fetch_recipe(url) 
    @doc = Nokogiri::HTML(open(url))
  end

  def to_txt
    @output.join("\n").strip
  end

end

get('/shoppinglist') { 
  #response["Cache-Control"] = "max-age=86400, public" 
  content_type 'text/plain', :charset => 'utf-8'
  if r = ShoppingList.new(params["r"])
    r.to_txt
  else
    "Oops, something went wrong"
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
