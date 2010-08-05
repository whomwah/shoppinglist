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
    # do we have shopping-list at the end otherwise add it
    unless r.include? 'shopping-list'
      r = File.join(r,'shopping-list')
    end

    # fetch the html page
    fetch_recipe(r) 

    # turn the HTML into a usable string 
    build_output
  end

  def build_output 
    items = []

    @title = (@doc/"#header h2").first.inner_html.strip

    ignore_next_p = false 

    # first fetch all the section names
    (@doc/'dl#shopping-list > dt[@class="ingredient-type"]').each do |el|
      items << [ el.inner_html.strip ]
    end

    # now fetch all the ingredients 
    (@doc/'dl#shopping-list > dd * ul').each_with_index do |el,i|
      ingr = []

      (el/'li[@class="ingredient"]').each do |li|
        ingr << li.inner_html.strip.split(',').first 
      end

      if items[i].nil?
        items[i] = ['Other', ingr]
      else
        items[i] << ingr
      end
    end

    puts items.inspect

    @data = items 
  end

  def fetch_recipe(url) 
    @doc = Hpricot(open(url))
  end

  def for_html
    @data 
  end
end

get('/iphone') { 
  #response["Cache-Control"] = "max-age=300, public" 
  content_type 'text/html', :charset => 'utf-8'
  unless params["r"] =~ /http:\/\/www.bbc.co.uk\/food\/recipes\/.*_\d/ 
    halt "Oops! You must use a BBC Recipe url"
  end

  begin
    @data = ShoppingList.new(params["r"])
    erb :iphone
  rescue OpenURI::HTTPError => e
    halt "Oo-la-la! there was something wrong with the URL you provided" 
  end
}

get('/list') { 
  #response["Cache-Control"] = "max-age=300, public" 
  content_type 'text/html', :charset => 'utf-8'
  unless params["r"] =~ /http:\/\/www.bbc.co.uk\/food\/recipes\/.*_\d/ 
    halt "Oops! You must use a BBC Recipe url"
  end

  begin
    @data = ShoppingList.new(params["r"])
    erb :html
  rescue OpenURI::HTTPError => e
    halt "Oo-la-la! there was something wrong with the URL you provided" 
  end
}

get('/') { 
  #content_type 'text/html', :charset => 'utf-8'
  if iphone_request?
    erb :index_iphone
  else
    erb :index
  end 
}
