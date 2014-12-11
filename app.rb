require 'sinatra'
require 'rss'
require 'open-uri'
require 'json'
require 'date'
require 'uri'

def morph(sql, api_key=ENV['MORPH_API_KEY'])
  url = URI::HTTPS.build(
    host: 'api.morph.io',
    path: "/hecticjeff/the-community-farm-scraper/data.json",
    query: URI.encode_www_form(query: sql, key: api_key)
  )
  JSON.parse(open(url).read)
end

def get_box_type(type)
  box_type = URI.decode_www_form_component(type)
  query = "select * from 'data' where title = '#{box_type}'" +
    " order by date desc limit 10"
  morph(query)
end

def get_box(id)
  query = "select * from data where id = '#{id}'"
  morph(query).first
end

before do
  cache_control :public, :must_revalidate, :max_age => 60
end

get '/' do
  erb :index
end

get '/boxes' do
  content_type :json
  boxes = morph("select distinct title from data")
  boxes_with_urls = boxes.map do |box|
    box['xml_url'] = url("/boxes/#{URI.encode_www_form_component(box['title'])}.xml")
    box['json_url'] = url("/boxes/#{URI.encode_www_form_component(box['title'])}.json")
    box
  end
  boxes_with_urls.to_json
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
        item.link = url("/box/#{week['id']}")
        item.title = "#{week['title']} #{week['date']}"
        item.content.content = JSON.parse(week['items']).join('<br>')
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
  box = box.map do |b|
    b['items'] = JSON.parse(b['items'])
    b
  end
  box.to_json
end

get '/box/:id' do
  @box = get_box(params[:id])
  erb :box
end

__END__

@@ index
<a href="/boxes">List of box urls</a>

@@ box
<h1><%= @box['title'] %></h1>
<h2><%= @box['date'] %></h2>
<ul>
  <% @box['items'].split("\n").each do |item| %>
    <li><%= item %></li>
  <% end %>
</ul>
