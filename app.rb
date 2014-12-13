require 'sinatra'
require 'rss'
require 'open-uri'
require 'json'
require 'date'
require 'uri'

def morph(sql, scraper = ENV['MORPH_SCRAPER'], api_key = ENV['MORPH_API_KEY'])
  url = URI::HTTPS.build(
    host: 'api.morph.io',
    path: "/#{scraper}/data.json",
    query: URI.encode_www_form(query: sql, key: api_key)
  )
  JSON.parse(url.open.read)
end

def add_urls_to_box(box)
  title = URI.encode_www_form_component(box['title'])
  box['html_url'] = url("/boxes/#{title}")
  box['xml_url'] = url("/boxes/#{title}.xml")
  box['json_url'] = url("/boxes/#{title}.json")
  box
end

def get_box_type(type)
  box_type = URI.decode_www_form_component(type)
  query = "select * from 'data' where title = '#{box_type}'" \
    ' order by date desc limit 10'
  boxes = morph(query)
  boxes.map do |box|
    box['items'] = JSON.parse(box['items'])
    box
  end.map(&method(:add_urls_to_box))
end

def get_all_boxes
  boxes = morph('select distinct title from data')
  boxes.map(&method(:add_urls_to_box))
end

before do
  cache_control :public, :must_revalidate, max_age: 60
end

get '/' do
  redirect '/boxes'
end

get '/boxes' do
  @boxes = get_all_boxes
  erb :index
end

get '/boxes.json' do
  content_type :json
  JSON.pretty_generate(get_all_boxes)
end

get '/boxes/:box_type.xml' do
  boxes_url = 'http://www.thecommunityfarm.co.uk/boxes/box_display.php'
  box = get_box_type(params[:box_type])
  rss = RSS::Maker.make('atom') do |maker|
    maker.channel.id = boxes_url
    maker.channel.author = 'Community Farm'
    maker.channel.updated = DateTime.parse(box.first['date']).iso8601
    maker.channel.title = box.first['title']
    box.each do |week|
      maker.items.new_item do |item|
        item.id = week['id']
        item.link = week['html_url']
        item.title = "#{week['title']} #{week['date']}"
        item.content.content = week['items'].join('<br>')
        item.updated = DateTime.parse(week['date']).iso8601
      end
    end
  end

  content_type :xml

  rss.to_s
end

get '/boxes/:box_type.json' do
  content_type :json
  box = get_box_type(params[:box_type])
  JSON.pretty_generate(box)
end

get '/boxes/:box_type' do
  @box = get_box_type(params[:box_type])
  erb :box
end
