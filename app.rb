require 'sinatra'
require 'rss'
require 'open-uri'
require 'json'
require 'date'
require 'uri'

def morph(sql, api_key=ENV['MORPH_API_KEY'])
  url = URI::HTTPS.build(
    host: 'api.morph.io',
    path: '/hecticjeff/community-farm/data.json',
    query: URI.encode_www_form(query: sql, key: api_key)
  )
  JSON.parse(open(url).read)
end

def get_box(type)
  box_type = URI.decode_www_form_component(type)
  query = "select * from 'data' where title = '#{box_type}'" +
    " order by date desc limit 10"
  morph(query)
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
  url = 'http://www.thecommunityfarm.co.uk/boxes/box_display.php'
  box = get_box(params[:box_type])
  rss = RSS::Maker.make('atom') do |maker|
    maker.channel.id = url
    maker.channel.author = 'Community Farm'
    maker.channel.updated = DateTime.parse(box.first['date']).iso8601
    maker.channel.title = box.first['title']
    box.each do |week|
      maker.items.new_item do |item|
        item.id = week['id']
        item.link = url
        item.title = "#{week['title']} #{week['date']}"
        item.content.content = week['items'].gsub("\n", '<br>')
        item.updated = DateTime.parse(week['date']).iso8601
      end
    end
  end

  content_type :xml

  rss.to_s
end

get '/boxes/:box_type.json' do
  content_type :json
  box = get_box(params[:box_type])
  box = box.map do |b|
    b['items'] = b['items'].split("\n")
    b
  end
  box.to_json
end

__END__

@@ index
<a href="/boxes">List of box urls</a>
