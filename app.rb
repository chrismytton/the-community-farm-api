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

get '/' do
  url = 'http://www.thecommunityfarm.co.uk/boxes/box_display.php'
  response = morph("select * from 'data' order by date desc limit 10")
  rss = RSS::Maker.make('atom') do |maker|
    maker.channel.id = url
    maker.channel.author = 'Community Farm'
    maker.channel.updated = DateTime.parse(response.first['date']).iso8601
    maker.channel.title = 'Community Farm - Veg No Potatoes'
    response.each do |week|
      maker.items.new_item do |item|
        item.id = week['id']
        item.link = url
        item.title = "Veg No Potatoes #{week['date']}"
        item.content.content = week['contents'].gsub("\n", '<br>')
        item.updated = DateTime.parse(week['date']).iso8601
      end
    end
  end

  content_type 'application/xml'

  rss.to_s
end
